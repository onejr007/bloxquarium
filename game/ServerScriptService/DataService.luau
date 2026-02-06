--[[
    DataService.luau (v3 - Hybrid Secrets)

    Layanan data terpusat, di-refactor dengan 5 pilar modern scripting:
    1. Optimasi: Menggunakan pustaka `task` untuk penjadwalan.
    2. Advanced Scripting: Arsitektur berbasis Promise untuk operasi async.
    3. Memory Management: Pembersihan cache yang jelas saat pemain keluar.
    4. Security: Mengambil kunci API dari SecretService di server live, 
       dan dari Config.luau lokal di Studio (Hybrid Approach).
    5. Network Efficiency: Menggunakan cache sesi untuk meminimalkan panggilan API.
]]

--=================[ SERVICES ]=================--
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--=================[ MODULES ]=================--
local Promise = require(ReplicatedStorage.Shared.Promise)
-- SECURITY: Mengimpor modul konfigurasi yang berisi rahasia untuk mode Studio
local Config = require(script.Parent.Config)

--=================[ CONFIGURATION ]=================--
local playerDataStore = DataStoreService:GetDataStore("PlayerDataV1")
local DataService = {}

-- MEMORY MANAGEMENT: Cache sesi untuk data pemain yang aktif.
local playerSessionData = {}

--///////////////////////////////////////////////////////////////////////////
--// FUNGSI INTERNAL & KEAMANAN
--///////////////////////////////////////////////////////////////////////////

-- SECURITY (HYBRID): Fungsi ini secara cerdas mendapatkan rahasia Firebase.
-- - Di Studio, ia menggunakan file Config.luau lokal.
-- - Di server live, ia menggunakan SecretService yang aman.
local function getFirebaseSecrets()
    if RunService:IsStudio() then
        print("🔍 [SECURITY] Berjalan di Studio. Menggunakan konfigurasi lokal dari Config.luau.")
        local studioConfig = Config.Studio
        if not studioConfig or not studioConfig.FIREBASE_URL or not studioConfig.FIREBASE_API_KEY then
            return Promise.reject("Config.luau tidak dikonfigurasi dengan benar untuk Studio.")
        end
        return Promise.resolve({studioConfig.FIREBASE_URL, studioConfig.FIREBASE_API_KEY})
    else
        print("🔐 [SECURITY] Berjalan di server live. Menggunakan SecretService.")
        return Promise.new(function(resolve, reject)
            local success, secrets = pcall(function()
                local SecretService = game:GetService("SecretService")
                local urlName = Config.Production.FIREBASE_URL_SECRET_NAME
                local keyName = Config.Production.FIREBASE_API_KEY_SECRET_NAME
                return {SecretService:GetSecret(urlName), SecretService:GetSecret(keyName)}
            end)

            if success and secrets[1] and secrets[2] then
                resolve(secrets)
            else
                reject("Gagal mengambil rahasia Firebase dari SecretService. Pastikan sudah diatur di Creator Dashboard.")
            end
        end)
    end
end

local function getInitialData(player)
    return {
        userId = player.UserId,
        name = player.Name,
        joinDate = os.time(),
        lastSeen = os.time(),
        coins = 100, gems = 5, level = 1, xp = 0, inventory = {}
    }
end

function DataService:_BackupToFirebase(player, eventName)
    -- Panggil fungsi hybrid untuk mendapatkan rahasia
    return getFirebaseSecrets()
    :andThen(function(secrets)
        local FIREBASE_URL, FIREBASE_API_KEY = table.unpack(secrets)
        local userId = player.UserId
        local dataToBackup = playerSessionData[userId]

        if not dataToBackup then
            return Promise.reject(string.format("Tidak ada data sesi untuk di-backup bagi pemain %d", userId))
        end

        local timestamp = os.time()
        local backupPath = string.format("player_backups/%d/%d_%s.json?auth=%s", userId, timestamp, eventName, FIREBASE_API_KEY)
        local url = FIREBASE_URL .. backupPath

        return Promise.new(function(resolve, reject)
            task.spawn(function()
                local success, result = pcall(function() HttpService:PostAsync(url, HttpService:JSONEncode(dataToBackup)) end)
                if success then
                    print(string.format("🔥 [FIREBASE BACKUP] Berhasil mencatat event '%s' untuk %s.", eventName, player.Name))
                    resolve()
                else
                    reject(string.format("Gagal mengirim backup Firebase: %s", tostring(result)))
                end
            end)
        end)
    end)
end

--///////////////////////////////////////////////////////////////////////////
--// FUNGSI API (ROBLOX DATASTORE)
--///////////////////////////////////////////////////////////////////////////

function DataService:GetPlayerData(player)
    return Promise.new(function(resolve, reject)
        local userId = player.UserId
        print(string.format("💾 [ROBLOX DATASTORE] Memuat data untuk pemain: %s (ID: %d)", player.Name, userId))

        if playerSessionData[userId] then
            print("   -> Data ditemukan di cache sesi.")
            return resolve(playerSessionData[userId])
        end

        task.spawn(function()
            local success, dataOrError = pcall(function() return playerDataStore:GetAsync(tostring(userId)) end)

            if not success then
                return reject(string.format("Gagal memuat dari DataStore: %s", tostring(dataOrError)))
            end
            
            if dataOrError then
                print("   -> Data berhasil dimuat dari Roblox DataStore.")
                playerSessionData[userId] = dataOrError
            else
                print("   -> Pemain baru terdeteksi. Membuat data awal.")
                playerSessionData[userId] = getInitialData(player)
                self:SavePlayerData(player, "New Player Join"):catch(warn)
            end
            
            resolve(playerSessionData[userId])
        end)
    end)
end

function DataService:SavePlayerData(player, reason)
    return Promise.new(function(resolve, reject)
        local userId = player.UserId
        local dataToSave = playerSessionData[userId]

        if not dataToSave then
            return reject(string.format("Tidak ada data sesi untuk disimpan bagi pemain %d", userId))
        end

        dataToSave.lastSeen = os.time()
        print(string.format("💾 [ROBLOX DATASTORE] Menyimpan data untuk %s | Alasan: %s", player.Name, reason or "Tidak diketahui"))

        task.spawn(function()
            local success, err = pcall(function() playerDataStore:SetAsync(tostring(userId), dataToSave) end)
            if success then
                print("   -> Data berhasil disimpan ke Roblox DataStore.")
                resolve()
            else
                reject(string.format("Gagal menyimpan ke DataStore: %s", tostring(err)))
            end
        end)
    end)
end

--///////////////////////////////////////////////////////////////////////////
--// INISIALISASI & KONEKSI EVENT
--///////////////////////////////////////////////////////////////////////////

function DataService:Init()
    print("💾 [DataService] Inisialisasi Layanan Data dengan skrip hybrid...")

    Players.PlayerAdded:Connect(function(player)
        self:GetPlayerData(player)
            :andThen(function(playerData)
                print(string.format("   -> Data untuk %s siap. Memulai backup ke Firebase.", player.Name))
                return self:_BackupToFirebase(player, "PlayerJoined")
            end)
            :catch(function(err)
                warn(string.format("❌ [ERROR ON JOIN] Gagal memproses pemain %s: %s", player.Name, tostring(err)))
            end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:_BackupToFirebase(player, "PlayerLeft")
            :andThen(function() return self:SavePlayerData(player, "Player Leaving") end)
            :andThen(function()
                playerSessionData[player.UserId] = nil
                print(string.format("   -> Cache sesi untuk pemain %s berhasil dibersihkan.", player.Name))
            end)
            :catch(function(err)
                warn(string.format("❌ [ERROR ON LEAVE] Gagal memproses data saat keluar untuk %s: %s", player.Name, tostring(err)))
            end)
    end)

    task.spawn(function()
        while true do
            task.wait(300) -- Interval auto-save
            print("💾 [ROBLOX DATASTORE] Memulai auto-save periodik...")
            for _, p in ipairs(Players:GetPlayers()) do
                self:SavePlayerData(p, "Auto-Save"):catch(warn)
            end
        end
    end)

    game:BindToClose(function()
        if not RunService:IsStudio() then
            print("💾 [ROBLOX DATASTORE] Server akan ditutup. Menyimpan semua data...")
            local savePromises = {}
            for _, p in ipairs(Players:GetPlayers()) do
                table.insert(savePromises, self:SavePlayerData(p, "Server Shutdown"))
            end
            Promise.all(savePromises):andThen(function() print("✅ Semua data pemain berhasil disimpan.") end):catch(warn)
            task.wait(5)
        end
    end)

    print("✅ [DataService] Layanan Data berhasil diinisialisasi.")
end

return DataService
