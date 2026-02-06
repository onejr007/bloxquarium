--[[
	AssetWatcher.server.luau
	
	Server-side script untuk monitoring dan automatic asset detection
	Mendeteksi asset baru yang ditambahkan dan memastikan sistem tetap sinkron
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import asset system modules
local AssetManager = require(ReplicatedStorage.Shared.AssetManager)

print("[AssetWatcher] Asset Watcher Server started")

-- Fungsi untuk setup monitoring
local function setupAssetMonitoring()
	-- Tunggu sampai Assets folder tersedia
	local assetsFolder = ReplicatedStorage:WaitForChild("Assets", 30)
	if not assetsFolder then
		error("[AssetWatcher] Assets folder not found!")
	end
	
	local modelsFolder = assetsFolder:WaitForChild("Models", 30)
	if not modelsFolder then
		error("[AssetWatcher] Models folder not found!")
	end
	
	print("[AssetWatcher] Monitoring assets folder:", modelsFolder:GetFullName())
	
	-- Monitor untuk asset baru yang ditambahkan
	modelsFolder.ChildAdded:Connect(function(child)
		wait(0.5) -- Tunggu sebentar untuk memastikan asset fully loaded
		
		if child:IsA("Model") or child:IsA("Part") or child:IsA("MeshPart") then
			print("[AssetWatcher] New asset detected:", child.Name)
			
			-- Trigger re-scan asset registry
			spawn(function()
				wait(1) -- Tunggu lebih lama untuk memastikan asset benar-benar ready
				
				-- Debug info
				AssetManager.Debug()
				
				-- Preload asset baru
				if AssetManager.Exists(child.Name) then
					AssetManager.Preload(child.Name)
					print("[AssetWatcher] Auto-preloaded new asset:", child.Name)
				end
			end)
		elseif child:IsA("Folder") then
			print("[AssetWatcher] New folder detected:", child.Name)
			
			-- Monitor folder untuk asset di dalamnya
			child.ChildAdded:Connect(function(subChild)
				wait(0.5)
				if subChild:IsA("Model") or subChild:IsA("Part") or subChild:IsA("MeshPart") then
					print("[AssetWatcher] New asset in folder detected:", subChild.Name, "in", child.Name)
					
					spawn(function()
						wait(1)
						if AssetManager.Exists(subChild.Name) then
							AssetManager.Preload(subChild.Name)
							print("[AssetWatcher] Auto-preloaded new asset:", subChild.Name)
						end
					end)
				end
			end)
		end
	end)
	
	-- Monitor untuk asset yang dihapus
	modelsFolder.ChildRemoved:Connect(function(child)
		print("[AssetWatcher] Asset removed:", child.Name)
		-- Note: Asset akan otomatis hilang dari cache ketika di-destroy
	end)
	
	-- Periodic health check setiap 30 detik
	spawn(function()
		while true do
			wait(30)
			
			local status = AssetManager.GetLoadingStatus()
			print(string.format("[AssetWatcher] Health Check - Assets: %d, Preloaded: %d (%.1f%%)", 
				status.total, status.preloaded, status.percentage))
			
			-- Auto-preload asset yang belum di-preload
			if status.percentage < 100 and not status.isPreloading then
				print("[AssetWatcher] Auto-preloading remaining assets...")
				AssetManager.PreloadAll()
			end
		end
	end)
end

-- Setup monitoring ketika server ready
spawn(function()
	wait(2) -- Tunggu server fully initialized
	setupAssetMonitoring()
end)

-- Event listener untuk preload complete
AssetManager.PreloadComplete:Connect(function(loaded, total)
	print(string.format("[AssetWatcher] Preload completed: %d/%d assets loaded", loaded, total))
end)

-- Event listener untuk asset baru
AssetManager.AssetAdded:Connect(function(assetName)
	print("[AssetWatcher] Asset added event:", assetName)
end)