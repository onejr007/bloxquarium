--[[
	init.server.luau
	
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

-- PERBAIKAN: Inisialisasi RemoteService SEGERA untuk menghindari race condition.
-- Ini membuat channel komunikasi sebelum klien mencoba terhubung.
RemoteService:Init()

-- Start professional bootstrap sequence
GameBootstrapper.StartBootstrapAsync(function(success, state)
	if success then
		print("✅ [Server] Game bootstrap completed successfully!")
		
		-- Inisialisasi sisa layanan inti di dalam bootstrap
        DataService:Init()

        -- Daftarkan event yang aman setelah sistem siap
        RemoteService:Register("PlayerReady", function(player)
            print(string.format("🔌 [RemoteService] Menerima sinyal 'PlayerReady' yang aman dari %s!", player.Name))
            -- Di sini Anda bisa memicu logika game lanjutan untuk pemain tersebut
        end)

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
