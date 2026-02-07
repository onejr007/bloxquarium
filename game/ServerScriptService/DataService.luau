--[[
    DataService.luau (v3.3 - ADMIN PANEL FIX)

    - Added the missing `UpdatePlayerData` function required by the Admin Panel's edit feature.
    - This new function safely merges partial data into the session cache for a given user ID.
    - This resolves the `missing method` crash on the server when updating a player.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Services
local FirebaseService = require(ServerScriptService.FirebaseService)
local DataStoreManager = require(ServerScriptService.DatabaseService)

local DataService = {}

--======================================================================
--=                              INTERNAL                              =
--======================================================================

local sessionCache = {}

local stateUpdatedEvent = Instance.new("BindableEvent")

local function Log(m)
	print(string.format("💾 [DataService v3.3] %s", m))
end

local function getDefaultPlayerData()
    return {
        Coins = 100,
        Gems = 0,
        Level = 1,
        XP = 0,
        Inventory = {}
    }
end

--======================================================================
--=                         PLAYER DATA LOGIC                          =
--======================================================================

local function loadFromFirebase(userId)
    Log(string.format("Attempting to load data for user %s from Firebase...", userId))
    local success, data = FirebaseService.GetPlayerDataAsync(userId)
    if success and data then
        Log(string.format("Success! Loaded data for user %s from Firebase.", userId))
        sessionCache[userId] = data
        return true
    end
    Log(string.format("Could not load data for user %s from Firebase. Success: %s. This might be a new player or a one-time error.", userId, tostring(success)))
    return false
end

local function loadFromDataStore(userId)
    Log(string.format("Firebase failed. Attempting to load data for user %s from DataStore as a backup...", userId))
    local success, data = DataStoreManager.Read(tostring(userId))
    if success and data then
        Log(string.format("Success! Loaded backup data for user %s from DataStore.", userId))
        sessionCache[userId] = data
        return true
    end
    Log(string.format("DataStore backup also failed for user %s. They are likely a new player.", userId))
    return false
end

local function createNewPlayer(userId)
    Log(string.format("Creating new default data for user %s.", userId))
    local newData = getDefaultPlayerData()
    sessionCache[userId] = newData
    Log(string.format("Performing initial DataStore backup for new user %s...", userId))
    DataStoreManager.Update(tostring(userId), newData)
end

local function saveToFirebaseOnLeave(userId, data)
    Log(string.format("Player %s is leaving. Saving final data from cache to Firebase...", userId))
    local success, err = FirebaseService.SavePlayerDataAsync(userId, data)
    if not success then
        Log(string.format("CRITICAL ERROR: Failed to save data for user %s to Firebase! Error: %s", userId, tostring(err)))
    else
        Log(string.format("Successfully saved final data for user %s to Firebase.", userId))
    end
end

--======================================================================
--=                         PLAYER CONNECTION                        =
--======================================================================

local function onPlayerAdded(player)
    local userId = tostring(player.UserId)
    
    coroutine.wrap(function()
        if not loadFromFirebase(userId) then
            if not loadFromDataStore(userId) then
                createNewPlayer(userId)
            end
        end
        
        if sessionCache[userId] then
            Log(string.format("Updating DataStore backup for user %s for this session.", userId))
            DataStoreManager.Update(userId, sessionCache[userId])
            stateUpdatedEvent:Fire(player)
        end
    end)()
end

local function onPlayerRemoving(player)
    local userId = tostring(player.UserId)
    local dataToSave = sessionCache[userId]

    if dataToSave then
        coroutine.wrap(saveToFirebaseOnLeave)(userId, dataToSave)
        sessionCache[userId] = nil
    else
        Log(string.format("No data found in cache for leaving player %s. Cannot save to Firebase.", userId))
    end
end

--======================================================================
--=                              PUBLIC API                            =
--======================================================================

DataService.StateUpdated = stateUpdatedEvent.Event

function DataService:Get(player)
    local userId = tostring(player.UserId)
    return sessionCache[userId]
end

function DataService:Update(player, newData)
    local userId = tostring(player.UserId)
    if sessionCache[userId] then
        sessionCache[userId] = newData
        stateUpdatedEvent:Fire(player)
        return true
    end
    return false
end

-- FIXED: Added the missing function for the admin panel
function DataService:UpdatePlayerData(userId, partialData)
    local strUserId = tostring(userId)
    if sessionCache[strUserId] then
        Log(string.format("Merging admin edits for user %s.", strUserId))
        for key, value in pairs(partialData) do
            sessionCache[strUserId][key] = value
        end

        -- If the player is online, fire the event so their UI updates live
        local player = Players:GetPlayerByUserId(tonumber(userId))
        if player then
            stateUpdatedEvent:Fire(player)
        end
        return true
    else
        Log(string.format("Cannot update data for user %s. Not found in session cache.", strUserId))
        return false
    end
end

function DataService:GetAllPlayerData()
    return sessionCache
end

--======================================================================
--=                         INITIALIZATION                           =
--======================================================================

function DataService:Init()
    Log("Service initialized. Full Firebase data architecture is now active.")
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return DataService
