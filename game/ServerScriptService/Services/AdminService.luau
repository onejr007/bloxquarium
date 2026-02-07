--[[
    AdminService.luau (v6.0 - Admin Management)

    - Added functionality for listing, adding, and removing admins.
    - Implemented server-side validation and Firebase synchronization for admin list.
    - Refactored to accept both RemoteService and DataService via the Init method.
    - Removed all hardcoded `require` paths.
]]

--=================[ SERVICES ]=================--
-- Services are injected via the Init method
local InjectedRemoteService
local InjectedDataService

local Players = game:GetService("Players")

--=================[ CONFIGURATION ]=================--
local AdminService = {}

local adminIdCache = {} -- {[userIdString] = true}
local ADMIN_PATH = "/admins"

-- Queue system to solve the race condition
local isCacheReady = false
local pendingAdminChecks = {} -- Queue of players waiting for a check

--///////////////////////////////////////////////////////////////////////////
--// INTERNAL FUNCTIONS
--///////////////////////////////////////////////////////////////////////////

-- Saves the current adminIdCache to Firebase
local function saveAdminsToDatabase()
    local adminsArray = {}
    for userIdString, _ in pairs(adminIdCache) do
        table.insert(adminsArray, tonumber(userIdString))
    end
    InjectedDataService:Set(ADMIN_PATH, adminsArray):catch(function(err)
        warn("👑 [AdminService] Failed to save admin data to Firebase: " .. tostring(err))
    end)
end

-- Process pending admin check requests in the queue
local function processPendingChecks()
    if isCacheReady then return end
    isCacheReady = true
    
    print(string.format("👑 [AdminService] Cache is ready. Processing %d queued requests...", #pendingAdminChecks))

    for _, player in ipairs(pendingAdminChecks) do
        if player and player.Parent then
            local isPlayerAdmin = AdminService.isAdmin(player)
            print(string.format("👑 [AdminService] Responding (from queue) to %s. Status: %s", player.Name, tostring(isPlayerAdmin)))
            if InjectedRemoteService then
                InjectedRemoteService:SendToClient(player, "AdminCheckResponse", isPlayerAdmin)
            else
                warn("👑 [AdminService] RemoteService not injected. Cannot respond to queued player.")
            end
        end
    end
    
    pendingAdminChecks = {}
    print("👑 [AdminService] Admin request queue processing complete.")
end

-- Validate, initialize, and load the admin cache
local function validateAndCacheAdmins()
    print("👑 [AdminService] Validating and caching admin data from Firebase...")
    
    -- Using the injected DataService to get admin data
    InjectedDataService:Get(ADMIN_PATH):andThen(function(adminData)
        if adminData == nil or (typeof(adminData) == "table" and next(adminData) == nil) then -- Check for nil or empty table
            print("👑 [AdminService] '/admins' path does not exist or is empty. Creating initial structure...")
            local initialAdmins = {90101532} -- Default admin ID
            InjectedDataService:Set(ADMIN_PATH, initialAdmins):andThen(function()
                adminIdCache = {[tostring(initialAdmins[1])] = true}
                print("👑 [AdminService] Admin cache initialized with default data.")
                processPendingChecks()
            end)
        elseif typeof(adminData) == "table" then
            print("👑 [AdminService] Valid admin data found. Loading into cache...")
            local newCache = {}
            for _, adminId in ipairs(adminData) do
                if typeof(adminId) == "number" then
                    newCache[tostring(adminId)] = true
                else
                    warn("👑 [AdminService] Non-numeric adminId found in Firebase data: ", adminId)
                end
            end
            adminIdCache = newCache
            print("👑 [AdminService] Admin cache updated successfully from Firebase.")
            processPendingChecks()
        else
            warn("👑 [AdminService] Data structure at '/admins' is corrupt or invalid type. Admin service may not function correctly.")
            -- Attempt to reset if corrupted, but for now just process queue
            processPendingChecks() 
        end
    end):catch(function(err)
        warn("👑 [AdminService] Failed to retrieve admin data from Firebase: " .. tostring(err))
        processPendingChecks() -- Still process the queue on failure
    end)
end

--///////////////////////////////////////////////////////////////////////////
--// REMOTE EVENT HANDLERS
--///////////////////////////////////////////////////////////////////////////

local function handleRequestAdminCheck(player)
    if isCacheReady then
        local isPlayerAdmin = AdminService.isAdmin(player)
        print(string.format("👑 [AdminService] Responding to direct request for %s. Status: %s", player.Name, tostring(isPlayerAdmin)))
        if InjectedRemoteService then
            InjectedRemoteService:SendToClient(player, "AdminCheckResponse", isPlayerAdmin)
        end
    else
        print(string.format("👑 [AdminService] Received request from %s. Adding to queue...", player.Name))
        table.insert(pendingAdminChecks, player)
    end
end

local function handleRequestAdminList(player)
    if not AdminService.isAdmin(player) then return {} end

    local adminList = {}
    for userIdString, _ in pairs(adminIdCache) do
        local userId = tonumber(userIdString)
        local adminPlayer = Players:GetPlayerByUserId(userId)
        table.insert(adminList, {
            userId = userId,
            name = adminPlayer and adminPlayer.Name or "[OFFLINE]"
        })
    end
    return adminList
end

local function handleAddAdmin(player, targetIdentifier)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end

    local targetUserId = tonumber(targetIdentifier) -- Try as ID first
    local targetName = targetIdentifier

    if not targetUserId then -- If not a number, try to resolve as name
        local foundPlayer = Players:FindFirstChild(targetName)
        if foundPlayer and foundPlayer:IsA("Player") then
            targetUserId = foundPlayer.UserId
        else
            return false, "Player not found or invalid ID/Name."
        end
    end

    if adminIdCache[tostring(targetUserId)] then
        return false, "Player is already an admin."
    end
    
    adminIdCache[tostring(targetUserId)] = true
    saveAdminsToDatabase()
    return true, "Admin added successfully!"
end

local function handleRemoveAdmin(player, targetUserId)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    
    targetUserId = tonumber(targetUserId)
    if not targetUserId then return false, "Invalid User ID" end

    if not adminIdCache[tostring(targetUserId)] then
        return false, "Player is not an admin."
    end

    adminIdCache[tostring(targetUserId)] = nil
    saveAdminsToDatabase()
    return true, "Admin removed successfully!"
end

--///////////////////////////////////////////////////////////////////////////
--// PUBLIC API
--///////////////////////////////////////////////////////////////////////////

function AdminService.isAdmin(player)
    if not player then return false end
    local userIdString = tostring(player.UserId)
    return adminIdCache[userIdString] == true
end

--///////////////////////////////////////////////////////////////////////////
--// INITIALIZATION
--///////////////////////////////////////////////////////////////////////////

function AdminService:Init(RemoteService, DataService)
    InjectedRemoteService = RemoteService -- Dependency Injection
    InjectedDataService = DataService     -- Dependency Injection
    
    if not InjectedRemoteService or not InjectedDataService then
        warn("🔥 [AdminService] A required service was not provided. Admin checks may not work.")
        return
    end
    
    validateAndCacheAdmins()
    
    InjectedRemoteService:Register("RequestAdminCheck", handleRequestAdminCheck)
    InjectedRemoteService:RegisterInvoke("RequestAdminList", handleRequestAdminList)
    InjectedRemoteService:RegisterInvoke("AddAdmin", handleAddAdmin)
    InjectedRemoteService:RegisterInvoke("RemoveAdmin", handleRemoveAdmin)
    
    print("👑 [AdminService] Successfully registered admin management handlers.")
end

return AdminService
