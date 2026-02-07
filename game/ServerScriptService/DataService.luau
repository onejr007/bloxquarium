--[[
    DataService.luau (v5.3 - Generic Set Function)

    Adds a generic :Set(path, data) function to write any data to Firebase.
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

-- Sinyal untuk memberitahu modul server lain tentang pembaruan state
DataService.StateUpdated = {}
function DataService.StateUpdated:Connect(callback)
    table.insert(self, callback)
end
function DataService.StateUpdated:Fire(...)
    for _, callback in ipairs(self) do
        task.spawn(callback, ...)
    end
end

local playerSessionData = {}

--///////////////////////////////////////////////////////////////////////////
--// FUNGSI INTERNAL & KEAMANAN
--///////////////////////////////////////////////////////////////////////////

local function getFirebaseSecrets()
    if RunService:IsStudio() then
        local studioConfig = Config.Studio
        if not studioConfig or not studioConfig.FIREBASE_URL or not studioConfig.FIREBASE_SECRET then
            return Promise.reject("Config.luau tidak dikonfigurasi dengan benar untuk Studio. Pastikan FIREBASE_URL dan FIREBASE_SECRET sudah benar.")
        end
        return Promise.resolve({studioConfig.FIREBASE_URL, studioConfig.FIREBASE_SECRET})
    else
        return Promise.new(function(resolve, reject)
            local success, secrets = pcall(function()
                local SecretService = game:GetService("SecretService")
                return {SecretService:GetSecret(Config.Production.FIREBASE_URL_SECRET_NAME), SecretService:GetSecret(Config.Production.FIREBASE_SECRET_NAME)}
            end)
            if success and secrets[1] and secrets[2] then resolve(secrets) else reject("Gagal mengambil rahasia Firebase.") end
        end)
    end
end

local function _requestFirebase(method, path, data)
    return Promise.new(function(resolve, reject)
        getFirebaseSecrets():andThen(function(secrets)
            local FIREBASE_URL, FIREBASE_AUTH_KEY = table.unpack(secrets)
            local url = string.format("%s%s.json?auth=%s", FIREBASE_URL, path, FIREBASE_AUTH_KEY)
            
            local requestOptions = { Url = url, Method = method, Headers = {["Content-Type"] = "application/json"} }
            if data and method ~= "GET" and method ~= "HEAD" then
                requestOptions.Body = HttpService:JSONEncode(data)
            end

            task.spawn(function()
                local success, response = pcall(function() 
                    return HttpService:RequestAsync(requestOptions) 
                end)

                if not success then
                    reject(string.format("RequestAsync pcall failed: %s", tostring(response)))
                elseif not response.Success then
                    reject(string.format("HTTP Error %d: %s", response.StatusCode, response.Body))
                elseif response.Body == "null" or response.Body == "" then
                    resolve(nil) -- Resolve with nil for empty data
                else
                    local decodeSuccess, result = pcall(HttpService.JSONDecode, HttpService, response.Body)
                    if decodeSuccess then
                        resolve(result)
                    else
                        reject("JSONDecode failed: " .. tostring(result))
                    end
                end
            end)
        end):catch(function(err)
            reject("Gagal mendapatkan rahasia Firebase: " .. tostring(err))
        end)
    end)
end

local function getInitialData(player)
    return { userId = player.UserId, name = player.Name, joinDate = os.time(), lastSeen = os.time(), coins = 100, gems = 5, level = 1, xp = 0, inventory = {} }
end

local function createMergedData(liveData, template)
    local mergedData = {}
    for key, defaultValue in pairs(template) do
        local liveValue = (type(liveData) == 'table' and liveData[key] or nil)
        if liveValue == nil then
            mergedData[key] = defaultValue
        elseif type(liveValue) == 'table' and type(defaultValue) == 'table' then
            mergedData[key] = createMergedData(liveValue, defaultValue) 
        else
            mergedData[key] = liveValue
        end
    end
    if type(liveData) == 'table' then
        for key, liveValue in pairs(liveData) do
            if mergedData[key] == nil then
                mergedData[key] = liveValue
            end
        end
    end
    return mergedData
end

--///////////////////////////////////////////////////////////////////////////
--// FUNGSI API (DATASTORE & FIREBASE)
--///////////////////////////////////////////////////////////////////////////

-- BARU (v5.3): Fungsi generik untuk menulis data ke jalur Firebase
function DataService:Set(path, data)
    print(string.format("   -> Menulis data generik ke jalur Firebase: %s...", path))
    return _requestFirebase("PUT", path, data)
end

function DataService:Get(path)
    print(string.format("   -> Meminta data generik dari jalur Firebase: %s...", path))
    return _requestFirebase("GET", path)
end

function DataService:GetSessionData(player)
    return playerSessionData[player.UserId]
end

function DataService:SetState(player, key, value)
    local userId = player.UserId
    local data = playerSessionData[userId]
    if not data then
        warn(string.format("Peringatan: Mencoba mengatur state untuk pemain %s yang datanya belum dimuat.", player.Name))
        return
    end
    
    data[key] = value
    self.StateUpdated:Fire(player, data)
    self:UpdateClientState(player)
end

function DataService:SaveToFirebase(player)
    local userId = player.UserId
    local dataToSave = playerSessionData[userId]
    if not dataToSave then return Promise.reject("Tidak ada data sesi untuk disimpan ke Firebase.") end
    dataToSave.lastSeen = os.time()
    print(string.format("   -> Mengirim data utama ke Firebase untuk %s...", player.Name))
    return _requestFirebase("PUT", "player_data/" .. userId, dataToSave)
end

function DataService:BackupToFirebase(player, eventName)
    local userId = player.UserId
    local dataToBackup = playerSessionData[userId] or {}
    local timestamp = os.time()
    local path = string.format("player_backups/%d/%d_%s", userId, timestamp, eventName)
    print(string.format("   -> Membuat backup historis di Firebase: %s...", eventName))
    return _requestFirebase("POST", path, dataToBackup)
end

function DataService:_LoadFromFirebase(player)
    print(string.format("   -> Mencoba memuat data dari Firebase untuk %s...", player.Name))
    return _requestFirebase("GET", "player_data/" .. player.UserId)
end

function DataService:SaveToDataStore(player, reason)
    return Promise.new(function(resolve, reject)
        local userId = player.UserId
        local dataToSave = playerSessionData[userId]
        if not dataToSave then reject("Tidak ada data sesi untuk disimpan.") return end
        dataToSave.lastSeen = os.time()
        task.spawn(function()
            print(string.format("   -> Menyimpan data ke DataStore untuk %s (Alasan: %s)...", player.Name, reason))
            local s, e = pcall(function() playerDataStore:SetAsync(tostring(userId), dataToSave) end)
            if s then resolve() else reject(string.format("Gagal menyimpan ke DataStore: %s", tostring(e))) end
        end)
    end)
end

function DataService:ClearFromDataStore(player)
    return Promise.new(function(resolve, reject)
        print(string.format("   -> Membersihkan DataStore untuk pemain %s...", player.Name))
        local s, e = pcall(function() playerDataStore:RemoveAsync(tostring(player.UserId)) end)
        if s then resolve() else reject(string.format("Gagal membersihkan DataStore: %s", tostring(e))) end
    end)
end

function DataService:GetPlayerData(player)
    local userId = player.UserId
    if playerSessionData[userId] then return Promise.resolve(playerSessionData[userId]) end

    return Promise.new(function(resolve, reject)
        self:_LoadFromFirebase(player):andThen(function(firebaseData)
            local template = getInitialData(player)
            local finalData

            if firebaseData then
                print("   -> Data ditemukan di Firebase.")
                finalData = createMergedData(firebaseData, template)
            else
                print("   -> Data tidak ditemukan di Firebase, mencoba dari DataStore...")
                local success, dataOrError = pcall(function() return playerDataStore:GetAsync(tostring(userId)) end)
                if success then
                    if dataOrError then
                        print("   -> Data ditemukan di DataStore.")
                        finalData = createMergedData(dataOrError, template)
                    else
                        print("   -> Data baru dibuat untuk pemain.")
                        finalData = template
                    end
                else
                    reject("Gagal memuat dari DataStore: " .. tostring(dataOrError))
                    return
                end
            end
            
            playerSessionData[userId] = finalData
            resolve(finalData)

        end):catch(function(err)
            warn("Error saat memuat dari Firebase: " .. tostring(err) .. ". Mencoba fallback ke DataStore.")
            local success, dataOrError = pcall(function() return playerDataStore:GetAsync(tostring(userId)) end)
            if success and dataOrError then
                 print("   -> Fallback ke DataStore berhasil.")
                 local template = getInitialData(player)
                 local finalData = createMergedData(dataOrError, template)
                 playerSessionData[userId] = finalData
                 resolve(finalData)
            else
                 reject("Gagal memuat dari Firebase dan DataStore. Tidak dapat memuat data pemain.")
            end
        end)
    end)
end

function DataService:UpdateClientState(player)
    local data = self:GetSessionData(player)
    if data then
        local clientStateChannel = ReplicatedStorage:WaitForChild("ClientStateChannel", 30)
        if clientStateChannel then
            clientStateChannel:FireClient(player, data)
        else
            warn("[DataService] Tidak dapat menemukan ClientStateChannel untuk memperbarui klien.")
        end
    end
end

--///////////////////////////////////////////////////////////////////////////
--// INISIALISASI & KONEKSI EVENT
--///////////////////////////////////////////////////////////////////////////

function DataService:Init()
    print("💾 [DataService] Inisialisasi Layanan Data v5.3 (Generic Set)...")
    local clientStateChannel = ReplicatedStorage:FindFirstChild("ClientStateChannel") or Instance.new("RemoteEvent", ReplicatedStorage)
    clientStateChannel.Name = "ClientStateChannel"

    Players.PlayerAdded:Connect(function(player)
        self:GetPlayerData(player):andThen(function(playerData)
            if not playerData then warn("Data pemain tidak valid saat bergabung.") return end
            print(string.format("🎨 [DataService] Mengirim state awal ke klien %s.", player.Name))
            self:UpdateClientState(player)
            return self:BackupToFirebase(player, "PlayerJoined")
        end):catch(function(err)
            warn(string.format("❌ [ERROR ON JOIN] %s: %s", player.Name, tostring(err)))
            player:Kick("Gagal memuat data Anda. Silakan coba lagi.")
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if not playerSessionData[player.UserId] then return end
        print(string.format("➡️ [DataService] Memulai proses logout untuk %s...", player.Name))

        self:SaveToDataStore(player, "Player Leaving")
            :andThen(function() return self:SaveToFirebase(player) end)
            :andThen(function() return self:ClearFromDataStore(player) end)
            :andThen(function()
                playerSessionData[player.UserId] = nil
                print("   -> Cache sesi berhasil dibersihkan.")
            end)
            :catch(function(err)
                warn(string.format("❌ [ERROR ON LEAVE] %s: %s", player.Name, tostring(err)))
                playerSessionData[player.UserId] = nil
            end)
    end)

    task.spawn(function()
        while task.wait(300) do
            for _, p in ipairs(Players:GetPlayers()) do
                if playerSessionData[p.UserId] then
                    self:SaveToDataStore(p, "Auto-Save"):catch(warn)
                end
            end
        end
    end)

    game:BindToClose(function()
        if RunService:IsStudio() then return end
        print("🚨 [DataService] Server akan ditutup. Menyimpan data semua pemain...")
        local promises = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if playerSessionData[p.UserId] then
                table.insert(promises, self:SaveToDataStore(p, "Server Shutdown")
                    :andThen(function() return self:SaveToFirebase(p) end)
                )
            end
        end
        Promise.all(promises):andThen(function() print("✅ Semua data pemain berhasil disimpan.") end):catch(warn)
        task.wait(5)
    end)

    print("✅ [DataService] Layanan Data berhasil diinisialisasi.")
end

return DataService
