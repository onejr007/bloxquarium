--[[
	init.server.luau (v1.4 - Final Fix)
	
	Fixes the final startup crash by calling the correct AssetManager function
	(`preloadInitialAsync` instead of the old `preloadAll`).
]]

print("🚀 [Server] Starting Bloxquarium Professional Game Engine...")

-- Import modul utama
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameBootstrapper = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameBootstrapper"))

-- Import Layanan Inti Server
local DataService = require(ServerScriptService:WaitForChild("DataService"))
local RemoteService = require(ServerScriptService:WaitForChild("RemoteService"))
local AssetManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AssetManager"))

-- Inisialisasi Saluran Komunikasi PENTING di Awal
-- 1. Inisialisasi RemoteService untuk komunikasi aman client-server.
RemoteService:Init()

-- 2. Buat RemoteEvent untuk sinkronisasi state klien.
print("🎨 [Server] Membuat ClientStateChannel...")
local clientStateChannel = Instance.new("RemoteEvent")
clientStateChannel.Name = "ClientStateChannel"
clientStateChannel.Parent = ReplicatedStorage

-- Start professional bootstrap sequence
GameBootstrapper.StartBootstrapAsync(function(success, state)
	if success then
		print("✅ [Server] Game bootstrap completed successfully!")
		
		-- Inisialisasi layanan inti di dalam bootstrap.
        DataService:Init()

        -- Mulai preloading aset Kritis setelah layanan inti siap.
        print("📦 [Server] Starting critical asset preloading...")
        AssetManager.preloadInitialAsync() -- FIX: Changed from preloadAll to preloadInitialAsync

		print("🎮 [Server] Bloxquarium is now ready for players!")
		
	else
		warn("❌ [Server] Game bootstrap failed!")
		warn("🔧 [Server] Check the bootstrap report for details:")
		GameBootstrapper.PrintReport()
	end
end)

-- Global access untuk debugging (optional)
_G.GameBootstrapper = GameBootstrapper
_G.BootstrapReport = function()
	GameBootstrapper.PrintReport()
end

print("📊 [Server] Bootstrap sequence initiated - check loading screen for progress")
