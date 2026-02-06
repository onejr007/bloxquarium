--[[
    LeaderboardService.server.luau (v1.1 - DataService v5.1 Fix)

    Mengelola leaderboard bawaan Roblox untuk menampilkan statistik pemain,
    seperti Koin. Terintegrasi dengan DataService untuk memastikan
    data yang ditampilkan selalu akurat dan terkini.

    Perbaikan (v1.1): 
    - Mengganti GetStatePromise -> GetPlayerData agar kompatibel dengan DataService v5+.
    - Terhubung ke sinyal DataService.StateUpdated untuk sinkronisasi real-time.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Impor DataService untuk mendapatkan akses ke data state pemain.
local DataService = require(ServerScriptService:WaitForChild("DataService"))

local LeaderboardService = {}

-- Fungsi ini dipanggil setiap kali seorang pemain bergabung ke dalam game.
local function onPlayerAdded(player)
    print(string.format("🏆 [Leaderboard] Menyiapkan leaderboard untuk %s...", player.Name))

    -- Buat folder 'leaderstats'. Ini adalah nama khusus yang dikenali Roblox
    -- untuk secara otomatis membuat dan menampilkan leaderboard UI.
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    -- Buat nilai untuk Koin. Nama objek ini akan menjadi nama kolom di leaderboard.
    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0 -- Nilai awal sebelum data dimuat
    coins.Parent = leaderstats

    -- --- Sinkronisasi dengan DataService ---

    -- 1. Dapatkan data awal saat pemain pertama kali dimuat.
    -- FIX: Menggunakan GetPlayerData, bukan GetStatePromise
    DataService:GetPlayerData(player):andThen(function(initialState)
        if initialState and initialState.coins then
            coins.Value = initialState.coins
            print(string.format("🏆 [Leaderboard] Nilai awal Koin untuk %s diatur ke: %d", player.Name, initialState.coins))
        end
    end):catch(function(err) 
        warn(string.format("Gagal mendapatkan data awal leaderboard untuk %s: %s", player.Name, tostring(err)))
    end)

    -- 2. Dengarkan pembaruan data secara real-time.
    -- FIX: Terhubung ke sinyal StateUpdated yang baru di DataService v5.1+
    DataService.StateUpdated:Connect(function(updatedPlayer, newState)
        -- Pastikan kita hanya memperbarui untuk pemain yang benar.
        if updatedPlayer == player and newState.coins ~= nil then -- Cek nil, bukan hanya falsy
            if coins.Value ~= newState.coins then
                coins.Value = newState.coins
                -- print(string.format("🏆 [Leaderboard] Koin untuk %s diperbarui: %d", player.Name, newState.coins)) -- Opsional: bisa jadi spammy
            end
        end
    end)
end

-- Fungsi ini dipanggil saat pemain keluar.
local function onPlayerRemoving(player)
    print(string.format("👋 [Leaderboard] Membersihkan data untuk %s.", player.Name))
    -- Roblox secara otomatis menangani pembersihan leaderstats saat pemain keluar,
    -- jadi tidak ada tindakan manual yang diperlukan di sini.
end

-- Hubungkan fungsi onPlayerAdded ke event Players.PlayerAdded.
-- Ini memastikan skrip kita berjalan untuk setiap pemain yang masuk.
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("✅ [LeaderboardService v1.1] Layanan leaderboard aktif dan siap.")

return LeaderboardService
