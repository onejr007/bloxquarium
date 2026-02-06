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

-- PERBAIKAN: Me-require DataService yang baru
local DataService = require(ServerScriptService:WaitForChild("DataService"))

-- Start professional bootstrap sequence
GameBootstrapper.StartBootstrapAsync(function(success, state)
	if success then
		print("✅ [Server] Game bootstrap completed successfully!")
		
		-- PERBAIKAN: Menginisialisasi DataService setelah bootstrap berhasil
		DataService:Init()

		print("🎮 [Server] Bloxquarium is now ready for players!")
		
		-- Optional: Run demo setelah bootstrap selesai
		-- local ExampleUsage = require(game.ReplicatedStorage.Shared.ExampleUsage)
		-- spawn(function()
		--     wait(2) -- Tunggu sebentar setelah bootstrap
		--     ExampleUsage.RunDemo()
		-- end)
		
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
