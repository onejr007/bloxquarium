--[[
	AssetRegistry.luau
	
	Sistem registry untuk mendeteksi dan mapping semua asset yang ada di folder assets/models
	Menyediakan interface untuk mengakses asset dengan mudah
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AssetRegistry = {}
AssetRegistry.__index = AssetRegistry

-- Cache untuk menyimpan semua asset yang sudah di-load
local assetCache = {}
local assetPaths = {}
local isInitialized = false

-- Event untuk notifikasi ketika asset selesai di-load
local assetLoadedEvent = Instance.new("BindableEvent")
AssetRegistry.AssetLoaded = assetLoadedEvent.Event

-- Fungsi untuk scan semua asset di folder Models
local function scanAssets(folder, path)
	path = path or ""
	
	for _, child in pairs(folder:GetChildren()) do
		local currentPath = path == "" and child.Name or path .. "/" .. child.Name
		
		if child:IsA("Model") or child:IsA("Part") or child:IsA("MeshPart") then
			-- Register asset ke cache
			assetCache[child.Name] = child
			assetPaths[child.Name] = currentPath
			
			-- Clone asset untuk backup (agar original tidak ter-modify)
			local clonedAsset = child:Clone()
			clonedAsset.Parent = nil
			assetCache[child.Name .. "_template"] = clonedAsset
			
			print("[AssetRegistry] Registered asset:", child.Name, "at path:", currentPath)
			
		elseif child:IsA("Folder") then
			-- Recursive scan untuk folder
			scanAssets(child, currentPath)
		end
	end
end

-- Fungsi untuk initialize asset registry
function AssetRegistry.Initialize()
	if isInitialized then
		warn("⚠️ [AssetRegistry] Already initialized!")
		return
	end
	
	print("🔍 [AssetRegistry] Initializing comprehensive asset registry...")
	print("📂 [AssetRegistry] Scanning for available assets...")
	
	-- Tunggu sampai Assets folder tersedia
	local assetsFolder = ReplicatedStorage:WaitForChild("Assets", 10)
	if not assetsFolder then
		error("[AssetRegistry] Assets folder not found in ReplicatedStorage!")
	end
	
	local modelsFolder = assetsFolder:WaitForChild("Models", 10)
	if not modelsFolder then
		error("[AssetRegistry] Models folder not found in Assets!")
	end
	
	-- Scan semua asset yang ada
	local startTime = tick()
	scanAssets(modelsFolder)
	local scanTime = tick() - startTime
	
	-- Count actual assets (exclude templates)
	local assetCount = 0
	for name, _ in pairs(assetCache) do
		if not string.find(name, "_template") then
			assetCount = assetCount + 1
		end
	end
	
	-- Setup listener untuk asset baru yang ditambahkan
	modelsFolder.ChildAdded:Connect(function(child)
		wait(0.1) -- Tunggu sebentar untuk memastikan asset fully loaded
		print("🆕 [AssetRegistry] New asset detected:", child.Name)
		scanAssets(modelsFolder)
		assetLoadedEvent:Fire(child.Name)
	end)
	
	isInitialized = true
	
	-- Print comprehensive initialization report
	print("╔" .. string.rep("═", 50) .. "╗")
	print("║" .. string.rep(" ", 10) .. "🔍 ASSET REGISTRY INITIALIZED 🔍" .. string.rep(" ", 7) .. "║")
	print("║" .. string.rep(" ", 50) .. "║")
	print(string.format("║  📦 Assets discovered: %d" .. string.rep(" ", 50 - 23 - string.len(tostring(assetCount))) .. "║", assetCount))
	print(string.format("║  ⏱️  Scan time: %.3f seconds" .. string.rep(" ", 50 - 22 - string.len(string.format("%.3f", scanTime))) .. "║", scanTime))
	print("║  🔄 Hot-reload monitoring: ACTIVE" .. string.rep(" ", 15) .. "║")
	print("╚" .. string.rep("═", 50) .. "╝")
end

-- Fungsi untuk mendapatkan asset berdasarkan nama
function AssetRegistry.GetAsset(assetName)
	if not isInitialized then
		AssetRegistry.Initialize()
	end
	
	local asset = assetCache[assetName]
	if not asset then
		warn("[AssetRegistry] Asset not found:", assetName)
		return nil
	end
	
	return asset
end

-- Fungsi untuk mendapatkan clone dari asset (untuk digunakan di game)
function AssetRegistry.GetAssetClone(assetName)
	if not isInitialized then
		AssetRegistry.Initialize()
	end
	
	local template = assetCache[assetName .. "_template"]
	if not template then
		warn("[AssetRegistry] Asset template not found:", assetName)
		return nil
	end
	
	return template:Clone()
end

-- Fungsi untuk mendapatkan semua asset yang tersedia
function AssetRegistry.GetAllAssets()
	if not isInitialized then
		AssetRegistry.Initialize()
	end
	
	local assets = {}
	for name, asset in pairs(assetCache) do
		if not string.find(name, "_template") then
			assets[name] = asset
		end
	end
	
	return assets
end

-- Fungsi untuk mendapatkan path dari asset
function AssetRegistry.GetAssetPath(assetName)
	if not isInitialized then
		AssetRegistry.Initialize()
	end
	
	return assetPaths[assetName]
end

-- Fungsi untuk check apakah asset exists
function AssetRegistry.HasAsset(assetName)
	if not isInitialized then
		AssetRegistry.Initialize()
	end
	
	return assetCache[assetName] ~= nil
end

-- Fungsi untuk pre-load semua asset (untuk performance)
function AssetRegistry.PreloadAllAssets()
	if not isInitialized then
		AssetRegistry.Initialize()
	end
	
	print("[AssetRegistry] Pre-loading all assets...")
	
	local loadedCount = 0
	for name, asset in pairs(assetCache) do
		if not string.find(name, "_template") then
			-- Pre-load asset dengan membuat clone dan destroy
			local clone = AssetRegistry.GetAssetClone(name)
			if clone then
				clone:Destroy()
				loadedCount = loadedCount + 1
			end
		end
	end
	
	print("[AssetRegistry] Pre-loaded", loadedCount, "assets")
end

-- Auto-initialize jika di server atau client
if RunService:IsServer() or RunService:IsClient() then
	AssetRegistry.Initialize()
end

return AssetRegistry