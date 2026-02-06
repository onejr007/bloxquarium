--[[
	AssetClient.client.luau
	
	Client-side script untuk asset management dan preloading
	Menangani preloading asset untuk performance optimization
	NOTE: Fungsionalitas preloading dinonaktifkan sementara karena API belum lengkap.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Import asset system modules
local AssetManager = require(ReplicatedStorage.Shared.AssetManager)

local player = Players.LocalPlayer

print("[AssetClient] Asset Client started for player:", player.Name)

-- Fungsi untuk setup client-side asset management
local function setupClientAssets()
	print("[AssetClient] Setting up client asset management (Limited Functionality Mode).")
	
	--[[ NONAKTIF SEMENTARA: Fungsionalitas berikut bergantung pada API AssetManager yang belum lengkap

	-- Auto-preload semua asset ketika client ready
	spawn(function()
		wait(3) -- Tunggu client fully loaded
		
		print("[AssetClient] Starting automatic asset preloading...")
		AssetManager.PreloadAll() -- MENYEBABKAN ERROR
	end)
	
	-- Event listener untuk preload complete
	AssetManager.PreloadComplete:Connect(function(loaded, total) -- MENYEBABKAN ERROR
		print(string.format("[AssetClient] Client preload completed: %d/%d assets loaded", loaded, total))
		
		-- Tampilkan debug info setelah preload selesai
		AssetManager.Debug()
	end)
	
	-- Event listener untuk asset baru
	AssetManager.AssetAdded:Connect(function(assetName)
		print("[AssetClient] New asset detected on client:", assetName)
		
		-- Auto-preload asset baru
		spawn(function()
			wait(1)
			if AssetManager.Exists(assetName) then
				AssetManager.Preload(assetName)
				print("[AssetClient] Auto-preloaded new asset:", assetName)
			end
		end)
	end)
	
	-- Periodic status check setiap 60 detik
	spawn(function()
		while true do
			wait(60)
			
			local status = AssetManager.GetLoadingStatus()
			if status.total > 0 then
				print(string.format("[AssetClient] Status Check - Assets: %d, Preloaded: %d (%.1f%%)", 
					status.total, status.preloaded, status.percentage))
				
				-- Auto-preload jika ada asset yang belum di-preload
				if status.percentage < 100 and not status.isPreloading then
					print("[AssetClient] Auto-preloading remaining assets...")
					AssetManager.PreloadAll()
				end
			end
		end
	end)
	]]
end

-- Setup client assets ketika ready
spawn(function()
	wait(1) -- Tunggu client initialization
	setupClientAssets()
end)

-- Expose AssetManager ke global untuk debugging di console
_G.AssetManager = AssetManager

print("[AssetClient] Asset system ready! Use _G.AssetManager for debugging.")
