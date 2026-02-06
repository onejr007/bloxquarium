--[[
    DataService.luau (v3.2 - Firebase Priority)

    Layanan data terpusat, di-refactor dengan 5 pilar modern scripting:
    1. Optimasi: Menggunakan pustaka `task` untuk penjadwalan.
    2. Advanced Scripting: Arsitektur berbasis Promise untuk operasi async.
    3. Memory Management: Pembersihan cache yang jelas saat pemain keluar.
    4. Security: Mengambil kunci API dari SecretService di server live, 
       dan dari Config.luau lokal di Studio (Hybrid Approach).
    5. Network Efficiency: Menggunakan cache sesi, memprioritaskan Firebase
       untuk awal/akhir sesi dan DataStore untuk auto-save.
]]

--=================[ SERVICES ]=================--
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--=================[ MODULES ]=================--
local Promise = require(ReplicatedStorage.Shared.Promise)
local Config = require(script.Parent.Config)

--=================[ CONFIGURATION ]=================--
local playerDataStore = DataStoreService:GetDataStore("PlayerDataV1")
local DataService = {}

local playerSessionData = {}

--///////////////////////////////////////////////////////////////////////////
--// FUNGSI INTERNAL & KEAMANAN
--///////////////////////////////////////////////////////////////////////////

local function getFirebaseSecrets()
    if RunService:IsStudio() then
        local studioConfig = Config.Studio
        if not studioConfig or not studioConfig.FIREBASE_URL or not studioConfig.FIREBASE_SECRET then
            return Promise.reject("Config.luau tidak dikonfigurasi dengan benar untuk Studio.")
        end
        return Promise.resolve({studioConfig.FIREBASE_URL, studioConfig.FIREBASE_SECRET})
    else
        return Promise.new(function(resolve, reject)
            local success, secrets = pcall(function()
                local SecretService = game:GetService("SecretService")
                local urlName = Config.Production.FIREBASE_URL_SECRET_NAME
                local secretName = Config.Production.FIREBASE_SECRET_NAME
                return {SecretService:GetSecret(urlName), SecretService:GetSecret(secretName)}
            end)

            if success and secrets[1] and secrets[2] then
                resolve(secrets)
            else
                reject("Gagal mengambil rahasia Firebase dari SecretService.")
            end
        end)
    end
end

-- Fungsi umum untuk permintaan Firebase
local function _requestFirebase(method, path, data)
    return getFirebaseSecrets():andThen(function(secrets)
        local FIREBASE_URL, FIREBASE_SECRET = table.unpack(secrets)
        local url = string.format("%s%s.json?auth=%s", FIREBASE_URL, path, FIREBASE_SECRET)
        local body = data and HttpService:JSONEncode(data) or ""

        return Promise.new(function(resolve, reject)
            task.spawn(function()
                local success, result = pcall(function() 
                    return HttpService:RequestAsync({
                        Url = url,
                        Method = method,
                        Headers = {["Content-Type"] = "application/json"},
                        Body = body
                    })
                end)

                if not success then
                    return reject(string.format("Permintaan Firebase gagal: %s", tostring(result)))
                end

                if not result.Success then
                     return reject(string.format("HTTP Error %d: %s", result.StatusCode, result.Body))
                end

                resolve(HttpService:JSONDecode(result.Body))
            end)
        end)
    end)
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

-- Menyimpan data utama ke path yang tetap
function DataService:SaveToFirebase(player)
    local userId = player.UserId
    local dataToSave = playerSessionData[userId]
    if not dataToSave then
        return Promise.reject(string.format("Tidak ada data sesi untuk disimpan ke Firebase bagi pemain %d", userId))
    end
    dataToSave.lastSeen = os.time()

    print(string.format("   -> Menyimpan data utama ke Firebase untuk %s...", player.Name))
    return _requestFirebase("PUT", "player_data/" .. userId, dataToSave)
end

-- Menyimpan backup historis dengan timestamp
function DataService:BackupToFirebase(player, eventName)
    local userId = player.UserId
    local dataToBackup = playerSessionData[userId]
    if not dataToBackup then
        return Promise.reject(string.format("Tidak ada data sesi untuk di-backup bagi pemain %d", userId))
    end

    local timestamp = os.time()
    local path = string.format("player_backups/%d/%d_%s", userId, timestamp, eventName)
    
    print(string.format("   -> Membuat backup historis di Firebase: %s...", eventName))
    return _requestFirebase("POST", path, dataToBackup)
end

-- Memuat data utama dari Firebase
function DataService:_LoadFromFirebase(player)
    print(string.format("   -> Mencoba memuat data dari Firebase untuk %s...", player.Name))
    return _requestFirebase("GET", "player_data/" .. player.UserId)
end

--///////////////////////////////////////////////////////////////////////////
--// FUNGSI API (DATASTORE & FIREBASE)
--///////////////////////////////////////////////////////////////////////////

function DataService:GetPlayerData(player)
    local userId = player.UserId

    if playerSessionData[userId] then
        return Promise.resolve(playerSessionData[userId])
    end

    return self:_LoadFromFirebase(player)
        :andThen(function(firebaseData)
            if firebaseData then
                print("   -> Data ditemukan di Firebase.")
                playerSessionData[userId] = firebaseData
                return playerSessionData[userId]
            end
            
            -- Fallback ke DataStore jika di Firebase tidak ada
            print("   -> Data tidak ditemukan di Firebase, mencoba dari DataStore...")
            return Promise.new(function(resolve, reject)
                task.spawn(function()
                    local success, dataOrError = pcall(function() return playerDataStore:GetAsync(tostring(userId)) end)
                    if not success then
                        return reject(string.format("Gagal memuat dari DataStore: %s", tostring(dataOrError)))
                    end

                    if dataOrError then
                        print("   -> Data ditemukan di DataStore.")
                        playerSessionData[userId] = dataOrError
                    else
                        print("   -> Data baru dibuat untuk pemain.")
                        playerSessionData[userId] = getInitialData(player)
                        -- Simpan data awal ini ke kedua sistem
                        self:SavePlayerData(player, "New Player Join"):catch(warn)
                        self:SaveToFirebase(player):catch(warn)
                    end
                    resolve(playerSessionData[userId])
                end)
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

        task.spawn(function()
            print(string.format("   -> Menyimpan data ke DataStore untuk %s (Alasan: %s)...", player.Name, reason))
            local success, err = pcall(function() playerDataStore:SetAsync(tostring(userId), dataToSave) end)
            if success then
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
    print("💾 [DataService] Inisialisasi Layanan Data dengan skrip hybrid (Firebase Priority)...")
    local clientStateChannel = ReplicatedStorage:WaitForChild("ClientStateChannel")

    Players.PlayerAdded:Connect(function(player)
        self:GetPlayerData(player)
            :andThen(function(playerData)
                print(string.format("🎨 [DataService] Mengirim state awal ke klien %s.", player.Name))
                clientStateChannel:FireClient(player, playerData)

                print(string.format("   -> Data untuk %s siap. Membuat backup join log.", player.Name))
                return self:BackupToFirebase(player, "PlayerJoined")
            end)
            :catch(function(err)
                warn(string.format("❌ [ERROR ON JOIN] Gagal memproses pemain %s: %s", player.Name, tostring(err)))
            end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        -- Pertama, simpan data sesi terakhir ke DataStore dan Firebase secara bersamaan
        self:SavePlayerData(player, "Player Leaving")
            :andThen(function() return self:SaveToFirebase(player) end)
            :andThen(function() return self:BackupToFirebase(player, "PlayerLeft") end) -- Buat juga backup log
            :andThen(function()
                playerSessionData[player.UserId] = nil
                print(string.format("   -> Cache sesi untuk pemain %s berhasil dibersihkan.", player.Name))
            end)
            :catch(function(err)
                warn(string.format("❌ [ERROR ON LEAVE] Gagal memproses data saat keluar untuk %s: %s", player.Name, tostring(err)))
            end)
    end)

    -- Auto-save hanya ke DataStore untuk efisiensi jaringan
    task.spawn(function()
        while true do
            task.wait(300) -- Interval auto-save
            for _, p in ipairs(Players:GetPlayers()) do
                self:SavePlayerData(p, "Auto-Save"):catch(warn)
            end
        end
    end)

    game:BindToClose(function()
        if not RunService:IsStudio() then
            print("🚨 [DataService] Server akan ditutup. Menyimpan data semua pemain...")
            local savePromises = {}
            for _, p in ipairs(Players:GetPlayers()) do
                -- Simpan ke kedua sistem saat server shutdown
                table.insert(savePromises, self:SavePlayerData(p, "Server Shutdown"))
                table.insert(savePromises, self:SaveToFirebase(p))
            end
            Promise.all(savePromises):andThen(function() print("✅ Semua data pemain berhasil disimpan.") end):catch(warn)
            task.wait(5)
        end
    end)

    print("✅ [DataService] Layanan Data berhasil diinisialisasi.")
end

return DataService