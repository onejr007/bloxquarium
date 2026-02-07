--[[
    AdminService.luau (v5.2 - Full Dependency Injection)

    - Refactored to accept both RemoteService and DataService via the Init method.
    - Removed all hardcoded `require` paths.
]]

--=================[ SERVICES ]=================--
-- Services are injected via the Init method
local InjectedRemoteService
local InjectedDataService

--=================[ CONFIGURATION ]=================--
local AdminService = {}

local adminIdCache = {}
local ADMIN_PATH = "/admins"

-- Queue system to solve the race condition
local isCacheReady = false
local pendingAdminChecks = {} -- Queue of players waiting for a check

--///////////////////////////////////////////////////////////////////////////
--// INTERNAL FUNCTIONS
--///////////////////////////////////////////////////////////////////////////

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
        if adminData == nil then
            print("👑 [AdminService] '/admins' path does not exist. Creating initial structure...")
            local initialAdmins = {90101532} -- Default admin ID
            InjectedDataService:Set(ADMIN_PATH, initialAdmins):andThen(function()
                adminIdCache = {[tostring(initialAdmins[1])] = true}
                print("👑 [AdminService] Admin cache initialized with default data.")
                processPendingChecks()
            end)
        elseif typeof(adminData) == "table" and (next(adminData) ~= nil and adminData[1] ~= nil) then
            print("👑 [AdminService] Valid admin data found. Loading into cache...")
            local newCache = {}
            for _, adminId in ipairs(adminData) do
                newCache[tostring(adminId)] = true
            end
            adminIdCache = newCache
            print("👑 [AdminService] Admin cache updated successfully from Firebase.")
            processPendingChecks()
        else
            warn("👑 [AdminService] Data structure at '/admins' is corrupt. Admin service may not function correctly.")
            processPendingChecks() -- Process queue anyway (all will be denied)
        end
    end):catch(function(err)
        warn("👑 [AdminService] Failed to retrieve admin data from Firebase: " .. tostring(err))
        processPendingChecks() -- Still process the queue on failure
    end)
end

--///////////////////////////////////////////////////////////////////////////
--// REMOTE EVENT HANDLER
--///////////////////////////////////////////////////////////////////////////

local function handleAdminCheckRequest(player)
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
    InjectedRemoteService:Register("RequestAdminCheck", handleAdminCheckRequest)
    print("👑 [AdminService] Successfully registered 'RequestAdminCheck' handler with queue system.")
end

return AdminService
