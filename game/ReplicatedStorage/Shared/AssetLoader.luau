--[[
	AssetLoader.luau
	
	Sistem loader untuk pre-loading dan caching asset dengan performance optimization
	Menyediakan interface yang mudah untuk developer mengakses asset
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local AssetRegistry = require(script.Parent.AssetRegistry)

local AssetLoader = {}
AssetLoader.__index = AssetLoader

-- Cache untuk asset yang sudah di-preload
local preloadedAssets = {}
local loadingQueue = {}
local isPreloading = false

-- Events
local preloadCompleteEvent = Instance.new("BindableEvent")
AssetLoader.PreloadComplete = preloadCompleteEvent.Event

-- Fungsi untuk preload asset menggunakan ContentProvider
local function preloadAsset(asset)
	if not asset then return false end
	
	local success, err = pcall(function()
		-- Preload semua descendants yang memiliki texture/mesh
		local assetsToPreload = {}
		
		-- Tambahkan asset utama
		table.insert(assetsToPreload, asset)
		
		-- Scan descendants untuk texture dan mesh
		for _, descendant in pairs(asset:GetDescendants()) do
			if descendant:IsA("MeshPart") and descendant.MeshId ~= "" then
				table.insert(assetsToPreload, descendant.MeshId)
			elseif descendant:IsA("SpecialMesh") and descendant.MeshId ~= "" then
				table.insert(assetsToPreload, descendant.MeshId)
			elseif descendant:IsA("Decal") and descendant.Texture ~= "" then
				table.insert(assetsToPreload, descendant.Texture)
			elseif descendant:IsA("Texture") and descendant.Texture ~= "" then
				table.insert(assetsToPreload, descendant.Texture)
			elseif descendant:IsA("SurfaceGui") then
				for _, child in pairs(descendant:GetDescendants()) do
					if child:IsA("ImageLabel") and child.Image ~= "" then
						table.insert(assetsToPreload, child.Image)
					elseif child:IsA("ImageButton") and child.Image ~= "" then
						table.insert(assetsToPreload, child.Image)
					end
				end
			end
		end
		
		-- Preload semua asset yang ditemukan
		if #assetsToPreload > 0 then
			ContentProvider:PreloadAsync(assetsToPreload)
		end
	end)
	
	if not success then
		warn("[AssetLoader] Failed to preload asset:", asset.Name, "Error:", err)
		return false
	end
	
	return true
end

-- Fungsi untuk preload semua asset secara batch
function AssetLoader.PreloadAllAssets()
	if isPreloading then
		warn("⚠️ [AssetLoader] Already preloading assets!")
		return
	end
	
	isPreloading = true
	print("📦 [AssetLoader] Starting comprehensive asset preloading...")
	
	spawn(function()
		local startTime = tick()
		local allAssets = AssetRegistry.GetAllAssets()
		local totalAssets = 0
		local loadedAssets = 0
		local failedAssets = 0
		
		-- Hitung total asset
		for _ in pairs(allAssets) do
			totalAssets = totalAssets + 1
		end
		
		print(string.format("📊 [AssetLoader] Found %d assets to preload", totalAssets))
		
		if totalAssets == 0 then
			print("⚠️ [AssetLoader] No assets found to preload!")
			isPreloading = false
			preloadCompleteEvent:Fire(0, 0)
			return
		end
		
		-- Preload setiap asset
		for name, asset in pairs(allAssets) do
			local success = preloadAsset(asset)
			if success then
				preloadedAssets[name] = true
				loadedAssets = loadedAssets + 1
				local percentage = math.floor((loadedAssets / totalAssets) * 100)
				print(string.format("✅ [AssetLoader] Preloaded '%s' (%d/%d - %d%%)", 
					name, loadedAssets, totalAssets, percentage))
			else
				failedAssets = failedAssets + 1
				warn(string.format("❌ [AssetLoader] Failed to preload '%s' (%d/%d)", 
					name, loadedAssets + failedAssets, totalAssets))
			end
			
			-- Yield setiap beberapa asset untuk tidak block thread
			if (loadedAssets + failedAssets) % 3 == 0 then
				wait()
			end
		end
		
		local endTime = tick()
		local totalTime = endTime - startTime
		isPreloading = false
		
		-- Print comprehensive completion report
		print("╔" .. string.rep("═", 50) .. "╗")
		print("║" .. string.rep(" ", 12) .. "📦 ASSET PRELOADING COMPLETE 📦" .. string.rep(" ", 5) .. "║")
		print("║" .. string.rep(" ", 50) .. "║")
		print(string.format("║  ✅ Successfully loaded: %d/%d assets" .. string.rep(" ", 50 - 32 - string.len(tostring(loadedAssets)) - string.len(tostring(totalAssets))) .. "║", loadedAssets, totalAssets))
		if failedAssets > 0 then
			print(string.format("║  ❌ Failed to load: %d assets" .. string.rep(" ", 50 - 23 - string.len(tostring(failedAssets))) .. "║", failedAssets))
		end
		print(string.format("║  ⏱️  Total time: %.3f seconds" .. string.rep(" ", 50 - 22 - string.len(string.format("%.3f", totalTime))) .. "║", totalTime))
		local percentage = totalAssets > 0 and math.floor((loadedAssets / totalAssets) * 100) or 0
		print(string.format("║  📊 Success rate: %d%%" .. string.rep(" ", 50 - 18 - string.len(tostring(percentage))) .. "║", percentage))
		print("╚" .. string.rep("═", 50) .. "╝")
		
		preloadCompleteEvent:Fire(loadedAssets, totalAssets)
	end)
end

-- Fungsi untuk preload asset tertentu
function AssetLoader.PreloadAsset(assetName)
	local asset = AssetRegistry.GetAsset(assetName)
	if not asset then
		warn("[AssetLoader] Cannot preload asset - not found:", assetName)
		return false
	end
	
	if preloadedAssets[assetName] then
		print("[AssetLoader] Asset already preloaded:", assetName)
		return true
	end
	
	local success = preloadAsset(asset)
	if success then
		preloadedAssets[assetName] = true
		print("[AssetLoader] Successfully preloaded asset:", assetName)
	end
	
	return success
end

-- Fungsi untuk mendapatkan asset dengan auto-preload jika belum
function AssetLoader.GetAsset(assetName, autoPreload)
	autoPreload = autoPreload ~= false -- Default true
	
	local asset = AssetRegistry.GetAsset(assetName)
	if not asset then
		return nil
	end
	
	-- Auto-preload jika belum di-preload dan autoPreload enabled
	if autoPreload and not preloadedAssets[assetName] then
		AssetLoader.PreloadAsset(assetName)
	end
	
	return asset
end

-- Fungsi untuk mendapatkan clone asset dengan auto-preload
function AssetLoader.GetAssetClone(assetName, autoPreload)
	autoPreload = autoPreload ~= false -- Default true
	
	-- Preload dulu jika belum
	if autoPreload and not preloadedAssets[assetName] then
		AssetLoader.PreloadAsset(assetName)
	end
	
	return AssetRegistry.GetAssetClone(assetName)
end

-- Fungsi untuk spawn asset ke workspace dengan positioning
function AssetLoader.SpawnAsset(assetName, position, parent)
	local clone = AssetLoader.GetAssetClone(assetName)
	if not clone then
		warn("[AssetLoader] Cannot spawn asset - not found:", assetName)
		return nil
	end
	
	-- Set parent (default ke workspace)
	parent = parent or workspace
	clone.Parent = parent
	
	-- Set position jika diberikan
	if position and clone.PrimaryPart then
		clone:SetPrimaryPartCFrame(CFrame.new(position))
	elseif position and clone:IsA("Part") then
		clone.Position = position
	end
	
	print("[AssetLoader] Spawned asset:", assetName, "at position:", tostring(position))
	return clone
end

-- Fungsi untuk check apakah asset sudah di-preload
function AssetLoader.IsPreloaded(assetName)
	return preloadedAssets[assetName] == true
end

-- Fungsi untuk mendapatkan status preloading
function AssetLoader.GetPreloadStatus()
	local totalAssets = 0
	local preloadedCount = 0
	
	for _ in pairs(AssetRegistry.GetAllAssets()) do
		totalAssets = totalAssets + 1
	end
	
	for _ in pairs(preloadedAssets) do
		preloadedCount = preloadedCount + 1
	end
	
	return {
		total = totalAssets,
		preloaded = preloadedCount,
		percentage = totalAssets > 0 and (preloadedCount / totalAssets * 100) or 0,
		isPreloading = isPreloading
	}
end

-- Fungsi untuk clear cache (untuk debugging)
function AssetLoader.ClearCache()
	preloadedAssets = {}
	print("[AssetLoader] Cache cleared")
end

-- Auto-preload jika di client (untuk performance)
if RunService:IsClient() then
	-- Tunggu sebentar setelah game start untuk preload
	spawn(function()
		wait(2) -- Tunggu 2 detik untuk memastikan semua asset sudah loaded
		AssetLoader.PreloadAllAssets()
	end)
end

return AssetLoader