--[[
	init.server.luau (v1.4 - Race Condition Fix)
	
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
local GameActions = require(ServerScriptService:WaitForChild("GameActions")) -- Import modul aksi
local LeaderboardService = require(ServerScriptService:WaitForChild("LeaderboardService")) -- Memuat layanan leaderboard

-- =======================================================================
-- URUTAN INISIALISASI KRITIS
-- =======================================================================

-- Langkah 1: Inisialisasi RemoteService untuk komunikasi aman client-server.
RemoteService:Init()

-- Langkah 2: Daftarkan semua Aksi Game. Ini harus terjadi sebelum DataService diinisialisasi
-- jika ada aksi yang perlu dipanggil saat pemain bergabung.
print("🛡️ [Server] Mendaftarkan Aksi Game yang Aman...")
RemoteService:Register("GameAction_BuyItem", function(player, itemId)
    return GameActions:BuyItem(player, itemId)
end)
print("   -> 'GameAction_BuyItem' terdaftar.")


-- Langkah 3: Buat RemoteEvent untuk sinkronisasi state klien.
print("🎨 [Server] Membuat ClientStateChannel...")
local clientStateChannel = Instance.new("RemoteEvent")
clientStateChannel.Name = "ClientStateChannel"
clientStateChannel.Parent = ReplicatedStorage

-- Langkah 4 (FIX): Inisialisasi DataService SEKARANG. Ini sangat penting.
-- Dengan menginisialisasi DataService di sini, kita memastikan bahwa listener 'PlayerAdded'
-- sudah aktif dan siap untuk menangani pemain yang bergabung, bahkan saat sisa
-- dari permainan (seperti aset dan sistem lainnya) masih dimuat oleh GameBootstrapper.
-- Ini menyelesaikan race condition di mana pemain bergabung sebelum DataService siap.
DataService:Init()

-- =======================================================================
-- INISIALISASI GAME UMUM
-- =======================================================================

-- Sekarang kita dapat dengan aman memulai sisa urutan bootstrap game.
GameBootstrapper.StartBootstrapAsync(function(success, state)
	if success then
		print("✅ [Server] Game bootstrap completed successfully!")
        -- DataService:Init() telah dipindahkan ke atas.
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
