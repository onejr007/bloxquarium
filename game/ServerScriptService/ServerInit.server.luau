--[[
	init.server.luau (v1.5 - Service Initialization Fix)
	
	- Delegates remote event registration to the respective services.
	- Calls the new AdminService:Init() function.
	- Simplifies the main init file.
]]

print("🚀 [Server] Starting Bloxquarium Professional Game Engine...")

-- Import modul utama
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameBootstrapper = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameBootstrapper"))

-- Import Layanan Inti Server
local DataService = require(ServerScriptService:WaitForChild("DataService"))
local RemoteService = require(ServerScriptService:WaitForChild("RemoteService"))
local GameActions = require(ServerScriptService:WaitForChild("GameActions"))
local LeaderboardService = require(ServerScriptService:WaitForChild("LeaderboardService"))
local AdminService = require(ServerScriptService:WaitForChild("AdminService"))

-- =======================================================================
-- URUTAN INISIALISASI KRITIS
-- =======================================================================

-- Langkah 1: Inisialisasi RemoteService untuk komunikasi aman client-server.
RemoteService:Init()

-- Langkah 2: Inisialisasi layanan lain dan daftarkan event remote mereka.
-- AdminService sekarang menangani pendaftarannya sendiri.
AdminService:Init()

-- Daftarkan Aksi Game lainnya.
print("🛡️ [Server] Mendaftarkan Aksi Game yang Aman...")
RemoteService:Register("GameAction_BuyItem", function(player, itemId)
    return GameActions:BuyItem(player, itemId)
end)
print("   -> 'GameAction_BuyItem' terdaftar.")

RemoteService:Register("KickPlayer", function(player, playerName)
    return GameActions:KickPlayer(player, playerName)
end)
print("   -> 'KickPlayer' terdaftar. ")

-- Langkah 3: Pastikan ClientStateChannel ada (RemoteService harusnya sudah membuatnya).
if not ReplicatedStorage:FindFirstChild("ClientStateChannel") then
    print("🎨 [Server] Membuat ClientStateChannel...")
    local clientStateChannel = Instance.new("RemoteEvent")
    clientStateChannel.Name = "ClientStateChannel"
    clientStateChannel.Parent = ReplicatedStorage
end

-- Langkah 4: Inisialisasi DataService.
DataService:Init()

-- =======================================================================
-- INISIALISASI GAME UMUM
-- =======================================================================

GameBootstrapper.StartBootstrapAsync(function(success, state)
	if success then
		print("✅ [Server] Game bootstrap completed successfully!")
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
