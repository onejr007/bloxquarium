--[[
    DataService.luau (v4.1 - Fix Promise Import & Unused Var)

    - FIXED: Added missing Promise module requirement.
    - FIXED: Removed unused RunService.
    - MAINTAINED: DataStore backup and Firebase validation logic.
]]
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Shared.Promise)

-- Services will be injected by ServiceLoader
local FirebaseService: any
local DataStoreManager: any

local DataService = {}

--======================================================================
--=                              INTERNAL                              =
--======================================================================

local sessionCache = {}
local stateUpdatedEvent = Instance.new("BindableEvent")

local function Log(m)
	print(string.format("💾 [DataService v4.1] %s", m))
end

local function getDefaultPlayerData()
    return {
        Coins = 100,
        Gems = 0,
        Level = 1,
        XP = 0,
        Inventory = {},
        AquariumLevel = 1,
        LastSave = os.time()
    }
end

--======================================================================
--=                         PLAYER DATA LOGIC                          =
--======================================================================

local function loadPlayerData(player: Player)
    local userId = tostring(player.UserId)
    Log(string.format("Memulai pemuatan data untuk %s...", player.Name))

    return Promise.new(function(resolve, reject)
        -- 1. Coba ambil dari Firebase
        FirebaseService:GetAsync("/players/" .. userId):andThen(function(firebaseData: any)
            -- 2. Ambil dari DataStore sebagai pembanding/backup
            local dsSuccess, dsData = DataStoreManager.Read(userId)
            
            local finalData = nil

            if firebaseData then
                Log(string.format("Data Firebase ditemukan untuk %s.", player.Name))
                finalData = firebaseData
                
                -- Validasi: Jika DataStore memiliki timestamp lebih baru
                if dsSuccess and dsData and dsData.LastSave and firebaseData.LastSave then
                    if dsData.LastSave > firebaseData.LastSave then
                        warn(string.format("⚠️ DataStore lebih baru dari Firebase untuk %s. Menggunakan data Firebase (Master).", player.Name))
                    end
                end
            elseif dsSuccess and dsData then
                Log(string.format("Data Firebase nihil, menggunakan backup DataStore untuk %s.", player.Name))
                finalData = dsData
            else
                Log(string.format("Pemain baru terdeteksi: %s. Menggunakan data default.", player.Name))
                finalData = getDefaultPlayerData()
            end

            sessionCache[userId] = finalData
            resolve(finalData)
        end):catch(function(err)
            -- Jika Firebase error, coba paksa gunakan DataStore
            Log(string.format("CRITICAL: Gagal akses Firebase untuk %s. Mencoba DataStore...", player.Name))
            local dsSuccess, dsData = DataStoreManager.Read(userId)
            if dsSuccess and dsData then
                sessionCache[userId] = dsData
                resolve(dsData)
            else
                reject("Gagal memuat data dari Firebase maupun DataStore.")
            end
        end)
    end)
end

local function savePlayerData(userId: string, data: any, _isLeaving: boolean)
    if not data then return end
    data.LastSave = os.time()

    -- Simpan ke Firebase (Utama)
    FirebaseService:SetAsync("/players/" .. userId, data):andThen(function()
        Log(string.format("Data %s berhasil disimpan ke Firebase.", userId))
    end):catch(function(err: any)
        warn(string.format("❌ Gagal simpan ke Firebase untuk %s: %s", userId, tostring(err)))
    end)

    -- Simpan ke DataStore (Backup)
    local dsSuccess, dsErr = DataStoreManager.Update(userId, data)
    if dsSuccess then
        Log(string.format("Data %s berhasil dibackup ke DataStore.", userId))
    else
        warn(string.format("❌ Gagal backup ke DataStore untuk %s: %s", userId, tostring(dsErr)))
    end
end

--======================================================================
--=                         PLAYER CONNECTION                        =
--======================================================================

local function onPlayerAdded(player: Player)
    loadPlayerData(player):andThen(function(_data)
        stateUpdatedEvent:Fire(player)
        Log(string.format("Pemuatan data selesai untuk %s.", player.Name))
    end):catch(function(err)
        warn(string.format("Gagal memproses login untuk %s: %s", player.Name, tostring(err)))
    end)
end

local function onPlayerRemoving(player: Player)
    local userId = tostring(player.UserId)
    if sessionCache[userId] then
        savePlayerData(userId, sessionCache[userId], true)
        sessionCache[userId] = nil
    end
end

--======================================================================
--=                              PUBLIC API                            =
--======================================================================

DataService.StateUpdated = stateUpdatedEvent.Event

function DataService:Get(argument: any)
    if typeof(argument) == "Instance" and argument:IsA("Player") then
        return sessionCache[tostring(argument.UserId)]
    elseif typeof(argument) == "string" then
        return FirebaseService:GetAsync(argument)
    else
        warn("DataService:Get() invalid argument: " .. typeof(argument))
        return nil
    end
end

function DataService:Set(path: string, data: any)
    return FirebaseService:SetAsync(path, data)
end

function DataService:UpdateGlobal(path: string, data: any)
    return FirebaseService:UpdateAsync(path, data)
end

function DataService:Update(argument: any, data: any)
    if typeof(argument) == "Instance" and argument:IsA("Player") then
        local userId = tostring(argument.UserId)
        if sessionCache[userId] then
            sessionCache[userId] = data
            stateUpdatedEvent:Fire(argument)
            DataStoreManager.Update(userId, data)
            return true
        end
        return false
    elseif typeof(argument) == "string" then
        return FirebaseService:UpdateAsync(argument, data)
    else
        warn("DataService:Update() invalid argument: " .. typeof(argument))
        return nil
    end
end

function DataService:Delete(path: string)
    return FirebaseService:SetAsync(path, nil)
end

function DataService:UpdatePlayerData(userId: string|number, partialData: any)
    local strUserId = tostring(userId)
    if sessionCache[strUserId] then
        for key, value in pairs(partialData) do
            sessionCache[strUserId][key] = value
        end
        local player = Players:GetPlayerByUserId(tonumber(userId) :: number)
        if player then
            stateUpdatedEvent:Fire(player)
        end
        return true
    end
    return false
end

function DataService:GetAllPlayerData()
    return sessionCache
end

--======================================================================
--=                         INITIALIZATION                           =
--======================================================================

function DataService:Init(injectedFirebase: any, injectedDatastore: any)
    FirebaseService = injectedFirebase
    DataStoreManager = injectedDatastore
    
    Log("DataService v4.1 Initialized with Hybrid Storage.")
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    -- Autosave loop (setiap 5 menit)
    task.spawn(function()
        while true do
            task.wait(300)
            Log("Menjalankan siklus autosave berkala...")
            for userId, data in pairs(sessionCache) do
                savePlayerData(userId, data, false)
            end
        end
    end)
end

return DataService
