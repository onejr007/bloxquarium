--[[
	init.server.luau (v1.2 - Simplified Init Flow)
	
	🎮 BLOXQUARIUM SERVER ENTRY POINT 🎮
	
	Entry point utama server yang menggunakan GameBootstrapper
	sebagai otak penjalan utama untuk startup sequence profesional
]]

print("🚀 [Server] Starting Bloxquarium Professional Game Engine...")

-- Import modul utama
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameBootstrapper = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameBootstrapper"))

-- Import Layanan Inti Server
local DataService = require(ServerScriptService:WaitForChild("DataService"))
local RemoteService = require(ServerScriptService:WaitForChild("RemoteService"))

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
        -- Init harus dipanggil SETELAH semua channel komunikasi dibuat.
        DataService:Init()

        -- Event 'PlayerReady' tidak diperlukan lagi. Alur data sekarang ditangani
        -- secara otomatis oleh DataService -> ClientStateChannel.

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
