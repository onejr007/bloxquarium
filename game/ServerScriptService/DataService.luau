--[[
    DataService.luau

    Layanan terpusat untuk semua operasi data pemain.
    Mengelola interaksi dengan Roblox DataStore (penyimpanan utama) dan 
    Firebase (validator/backup).
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Mendapatkan DataStore utama untuk data pemain
local playerDataStore = DataStoreService:GetDataStore("PlayerDataV1")

-- Konfigurasi Firebase (DIKONFIGURASI)
local FIREBASE_URL = "https://bloxaquarium-default-rtdb.asia-southeast1.firebasedatabase.app/"
local FIREBASE_API_KEY = "OVIURisf0NwJpGjooxUEVos4tcYyLiFHCjAwziGS"

local DataService = {}

-- Cache untuk data pemain yang sedang online untuk mengurangi panggilan DataStore
local playerSessionData = {}

-- /////////////////////////////////////////////////////////////////////////////
-- // FUNGSI INTERNAL
-- /////////////////////////////////////////////////////////////////////////////

-- Mendapatkan data default untuk pemain baru
local function getInitialData(player)
    return {
        userId = player.UserId,
        name = player.Name,
        joinDate = os.time(),
        lastSeen = os.time(),
        coins = 100,
        gems = 5,
        level = 1,
        xp = 0,
        inventory = {}
    }
end

-- FUNGSI BARU: Mengirim snapshot data ke Firebase sebagai backup/validator
function DataService:_BackupToFirebase(player, eventName)
    local userId = player.UserId
    local dataToBackup = playerSessionData[userId]

    if not dataToBackup then
        warn(string.format("🔥 [FIREBASE BACKUP] Tidak ada data sesi untuk di-backup bagi pemain %d.", userId))
        return
    end

    -- Buat path yang lebih deskriptif untuk log backup
    local timestamp = os.time()
    local backupPath = string.format("player_backups/%d/%d_%s.json?auth=%s", userId, timestamp, eventName, FIREBASE_API_KEY)
    local url = FIREBASE_URL .. backupPath

    -- Kirim data secara async
    spawn(function()
        local success, result = pcall(function()
            HttpService:PostAsync(url, HttpService:JSONEncode(dataToBackup))
        end)

        if success then
            print(string.format("🔥 [FIREBASE BACKUP] Berhasil mencatat event '%s' untuk %s.", eventName, player.Name))
        else
            warn(string.format("   -> ❌ Gagal mengirim backup Firebase untuk %s: %s", player.Name, tostring(result)))
        end
    end)
end

-- /////////////////////////////////////////////////////////////////////////////
-- // FUNGSI API (ROBLOX DATASTORE)
-- /////////////////////////////////////////////////////////////////////////////

-- Memuat data pemain dari DataStore
function DataService:GetPlayerData(player)
    local userId = player.UserId
    print(string.format("💾 [ROBLOX DATASTORE] Memuat data untuk pemain: %s (ID: %d)", player.Name, userId))

    if playerSessionData[userId] then
        print("   -> Data ditemukan di cache sesi.")
        return playerSessionData[userId]
    end

    local success, data = pcall(function()
        return playerDataStore:GetAsync(tostring(userId))
    end)

    if success then
        if data then
            print("   -> Data berhasil dimuat dari Roblox DataStore.")
            playerSessionData[userId] = data
        else
            print("   -> Pemain baru terdeteksi. Membuat data awal.")
            local initialData = getInitialData(player)
            playerSessionData[userId] = initialData
            -- Langsung simpan data awal untuk pemain baru
            self:SavePlayerData(player, "New Player Join")
        end
        
        -- VALIDATOR/BACKUP SAAT MASUK: Kirim data yang dimuat ke Firebase
        self:_BackupToFirebase(player, "PlayerJoined")
        
        return playerSessionData[userId]
    else
        warn(string.format("   -> ❌ Gagal memuat data dari Roblox DataStore untuk pemain %d: %s", userId, tostring(data)))
        return nil -- Kembalikan nil jika gagal memuat
    end
end

-- Menyimpan data pemain ke DataStore dengan alasan yang jelas
function DataService:SavePlayerData(player, reason)
    local userId = player.UserId
    local dataToSave = playerSessionData[userId]

    if not dataToSave then
        warn(string.format("💾 [ROBLOX DATASTORE] Tidak ada data sesi untuk disimpan bagi pemain %d.", userId))
        return
    end

    dataToSave.lastSeen = os.time()

    print(string.format("💾 [ROBLOX DATASTORE] Menyimpan data untuk %s | Alasan: %s", player.Name, reason or "Tidak diketahui"))

    local success, err = pcall(function()
        playerDataStore:SetAsync(tostring(userId), dataToSave)
    end)

    if success then
        print("   -> Data berhasil disimpan ke Roblox DataStore.")
    else
        warn(string.format("   -> ❌ Gagal menyimpan data ke Roblox DataStore untuk %s: %s", player.Name, tostring(err)))
    end
end

-- /////////////////////////////////////////////////////////////////////////////
-- // INISIALISASI & KONEKSI EVENT
-- /////////////////////////////////////////////////////////////////////////////

function DataService:Init()
    print("💾 [DataService] Inisialisasi Layanan Data...")

    Players.PlayerAdded:Connect(function(player)
        -- Memuat data utama dari DataStore. Fungsi ini sekarang juga menangani backup Firebase saat masuk.
        self:GetPlayerData(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        -- VALIDATOR/BACKUP SAAT KELUAR: Kirim data terakhir ke Firebase
        self:_BackupToFirebase(player, "PlayerLeft")
        
        -- Simpan data terakhir ke DataStore
        self:SavePlayerData(player, "Player Leaving")
        
        -- Hapus cache
        playerSessionData[player.UserId] = nil
        print(string.format("   -> Cache sesi untuk pemain %s dibersihkan.", player.Name))
    end)

    spawn(function()
        while true do
            wait(300) -- Interval auto-save (5 menit)
            print("💾 [ROBLOX DATASTORE] Memulai auto-save periodik...")
            for _, player in ipairs(Players:GetPlayers()) do
                self:SavePlayerData(player, "Auto-Save")
            end
        end
    end)

    game:BindToClose(function()
        if not RunService:IsStudio() then
            print("💾 [ROBLOX DATASTORE] Server akan ditutup. Menyimpan data semua pemain...")
            for _, player in ipairs(Players:GetPlayers()) do
                -- Simpan data semua pemain yang online saat server mati
                self:SavePlayerData(player, "Server Shutdown")
            end
            wait(5) -- Beri waktu untuk operasi penyimpanan
        end
    end)

    print("✅ [DataService] Layanan Data berhasil diinisialisasi.")
end

return DataService
