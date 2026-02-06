--[[
	AssetWatcher.server.luau
	
	Server-side script untuk monitoring dan automatic asset detection
	Mendeteksi asset baru yang ditambahkan dan memastikan sistem tetap sinkron
	NOTE: Sebagian besar fungsionalitas dinonaktifkan sementara untuk fokus pada perbaikan error utama.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import asset system modules
-- local AssetManager = require(ReplicatedStorage.Shared.AssetManager)

print("[AssetWatcher] Asset Watcher Server started (Limited Functionality Mode)")

-- Fungsi untuk setup monitoring
local function setupAssetMonitoring()
	-- Menggunakan FindFirstChild agar tidak error jika folder tidak ada
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if not assetsFolder then
		print("[AssetWatcher] 'Assets' folder not found. Hot-reloading for models is disabled.")
		return -- Keluar dari fungsi jika folder utama tidak ada
	end
	
	local modelsFolder = assetsFolder:FindFirstChild("models") -- Menggunakan lowercase untuk konsistensi
	if not modelsFolder then
		print("[AssetWatcher] 'models' folder not found inside 'Assets'. Hot-reloading for models is disabled.")
		return -- Keluar dari fungsi jika subfolder models tidak ada
	end
	
	print("[AssetWatcher] Monitoring assets folder:", modelsFolder:GetFullName())
	
	--[[ NONAKTIF SEMENTARA: Fungsionalitas berikut bergantung pada API AssetManager yang belum lengkap

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
	]]
end

-- Setup monitoring ketika server ready
spawn(function()
	wait(2) -- Tunggu server fully initialized
	setupAssetMonitoring()
end)

--[[ NONAKTIF SEMENTARA
-- Event listener untuk preload complete
AssetManager.PreloadComplete:Connect(function(loaded, total)
	print(string.format("[AssetWatcher] Preload completed: %d/%d assets loaded", loaded, total))
end)

-- Event listener untuk asset baru
AssetManager.AssetAdded:Connect(function(assetName)
	print("[AssetWatcher] Asset added event:", assetName)
end)
]]
