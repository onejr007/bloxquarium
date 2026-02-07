--[[
    DataService.luau (v3.5 - Polymorphic Get/Set & Bug Fix)

    - Re-introduces polymorphic behavior for the Get() and Set() methods.
    - Get() can now handle both player objects (for cached data) and string paths (for Firebase data).
    - Set() is reintroduced to allow writing arbitrary data to a Firebase path.
    - This resolves the `attempt to index nil with 'andThen'` crash in AdminService.
]]

local Players = game:GetService("Players")

-- Services will be injected by ServiceLoader
local FirebaseService
local DataStoreManager

local DataService = {}

--======================================================================
--=                              INTERNAL                              =
--======================================================================

local sessionCache = {}
local stateUpdatedEvent = Instance.new("BindableEvent")

local function Log(m)
	print(string.format("💾 [DataService v3.5] %s", m))
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
    -- We use the path-based Get to fetch the initial player data
    return FirebaseService:GetAsync("/players/" .. userId):andThen(function(data)
        if data then
            Log(string.format("Success! Loaded data for user %s from Firebase.", userId))
            sessionCache[userId] = data
            return true
        else
            Log(string.format("No data for user %s in Firebase. They may be a new player.", userId))
            return false
        end
    end)
end

local function loadFromDataStore(userId)
    Log(string.format("Attempting to load data for user %s from DataStore as a backup...", userId))
    local success, data = DataStoreManager.Read(tostring(userId))
    if success and data then
        Log(string.format("Success! Loaded backup data for user %s from DataStore.", userId))
        sessionCache[userId] = data
        return true
    end
    Log(string.format("DataStore backup also failed for user %s.", userId))
    return false
end

local function createNewPlayer(userId)
    Log(string.format("Creating new default data for user %s.", userId))
    local newData = getDefaultPlayerData()
    sessionCache[userId] = newData
    Log(string.format("Performing initial save for new user %s...", userId))
    return FirebaseService:SetAsync("/players/" .. userId, newData)
end

local function saveToFirebaseOnLeave(userId, data)
    Log(string.format("Player %s is leaving. Saving final data to Firebase...", userId))
    return FirebaseService:SetAsync("/players/" .. userId, data):catch(function(err)
        Log(string.format("CRITICAL ERROR: Failed to save data for user %s! Error: %s", userId, tostring(err)))
    end)
end

--======================================================================
--=                         PLAYER CONNECTION                        =
--======================================================================

local function onPlayerAdded(player)
    local userId = tostring(player.UserId)
    
    coroutine.wrap(function()
        loadFromFirebase(userId):andThen(function(firebaseSuccess)
            if not firebaseSuccess then
                if not loadFromDataStore(userId) then
                    return createNewPlayer(userId)
                end
            end
            return true -- Indicate success
        end):andThen(function()
            if sessionCache[userId] then
                Log(string.format("Updating DataStore backup for user %s for this session.", userId))
                DataStoreManager.Update(userId, sessionCache[userId])
                stateUpdatedEvent:Fire(player)
            end
        end)
    end)()
end

local function onPlayerRemoving(player)
    local userId = tostring(player.UserId)
    if sessionCache[userId] then
        saveToFirebaseOnLeave(userId, sessionCache[userId])
        sessionCache[userId] = nil
    end
end

--======================================================================
--=                              PUBLIC API                            =
--======================================================================

DataService.StateUpdated = stateUpdatedEvent.Event

-- POLYMORPHIC: Handles player objects or Firebase paths
function DataService:Get(argument)
    if typeof(argument) == "Instance" and argument:IsA("Player") then
        return sessionCache[tostring(argument.UserId)]
    elseif typeof(argument) == "string" then
        return FirebaseService:GetAsync(argument)
    else
        warn("DataService:Get() called with invalid argument type: " .. typeof(argument))
        return nil
    end
end

-- RE-ADDED: Sets data at a specific Firebase path
function DataService:Set(path, data)
    if typeof(path) == "string" then
        return FirebaseService:SetAsync(path, data)
    else
        warn("DataService:Set() called with invalid path type: " .. typeof(path))
    end
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

function DataService:UpdatePlayerData(userId, partialData)
    local strUserId = tostring(userId)
    if sessionCache[strUserId] then
        Log(string.format("Merging admin edits for user %s.", strUserId))
        for key, value in pairs(partialData) do
            sessionCache[strUserId][key] = value
        end
        local player = Players:GetPlayerByUserId(tonumber(userId))
        if player then
            stateUpdatedEvent:Fire(player)
        end
        return true
    else
        Log(string.format("Cannot update data for user %s. Not in cache.", strUserId))
        return false
    end
end

function DataService:GetAllPlayerData()
    return sessionCache
end

--======================================================================
--=                         INITIALIZATION                           =
--======================================================================

function DataService:Init(injectedFirebase, injectedDatastore)
    FirebaseService = injectedFirebase
    DataStoreManager = injectedDatastore
    
    Log("Service initialized. Full Firebase data architecture is now active.")
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return DataService
