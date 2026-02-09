--!strict
--[[
    AdminService.luau (v3.0 - Event Fix)
    - FIX: Replaced SendToClient with FireClient for proper event handling.
]]

local Players = game:GetService("Players")

-- Framework
local _Promise = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Promise"))

-- Injected Services
local InjectedDataService: any
local InjectedRemoteService: any
local _InjectedShopService: any

-- Constants & Private State
local ADMIN_DATA_KEY = "admins"
local SUPER_ADMIN_USERNAMES = {["pamanlua"] = true}
local adminIdCache: {[string]: boolean} = {}
local isCacheReady = false
local requestQueue = {}

local AdminService = {}
AdminService.Name = "AdminService"

-- Private Functions

local function convertCacheToArray(): {number}
    local adminArray = {}
    for id, _ in pairs(adminIdCache) do
        local numId = tonumber(id)
        if numId then
            table.insert(adminArray, numId)
        end
    end
    return adminArray
end

local function saveAdminsToDatabase()
    if InjectedDataService and isCacheReady then
        local adminArray = convertCacheToArray()
        InjectedDataService:Set(ADMIN_DATA_KEY, adminArray)
    else
        warn("WAR: [AdminService] Cannot save admins, DataService not ready.")
    end
end

-- MODIFIED: This now processes responses for all players
local function processRequestQueue()
    if not isCacheReady then return end
    
    for _, req in ipairs(requestQueue) do
        local player = req.player
        if player and player.Parent then
            local isAdmin = AdminService.isAdmin(player)
            InjectedRemoteService:FireClient(player, "AdminStatusResponse", {isAdmin = isAdmin})
        end
    end
    requestQueue = {}
end

local function syncAdminDataFromFirebase()
    print("👑 [AdminService] Syncing admin data from Firebase...")
    if not InjectedDataService then return end
    
    InjectedDataService:Get(ADMIN_DATA_KEY):andThen(function(data)
        if data and type(data) == "table" then
            for _, id in ipairs(data) do
                adminIdCache[tostring(id)] = true
            end
        end
        isCacheReady = true
        print("   -> [AdminService] Admin data synced.")
        processRequestQueue()
    end):catch(function(err)
        warn("CRITICAL: [AdminService] Failed to get admin data! Error: " .. tostring(err))
        isCacheReady = true -- Still ready, just with an empty/incomplete list
        processRequestQueue()
    end)
end

-- Service Methods

function AdminService.isAdmin(player: Player): boolean
    if not player then return false end
    -- Also check for super admin names, just in case cache isn't ready but they are in-game
    return adminIdCache[tostring(player.UserId)] == true or SUPER_ADMIN_USERNAMES[player.Name] == true
end

function AdminService:Init(RemoteService: any, DataService: any, ShopService: any)
    InjectedRemoteService = RemoteService
    InjectedDataService = DataService
    _InjectedShopService = ShopService
    
    syncAdminDataFromFirebase()
    
    -- Bootstrap super admins
    local function bootstrapAdmin(player)
        if SUPER_ADMIN_USERNAMES[player.Name] then
            task.spawn(function()
                while not isCacheReady do task.wait(0.1) end
                
                if not adminIdCache[tostring(player.UserId)] then
                    print(string.format("👑 [AdminService] Bootstrapping super admin: %s", player.Name))
                    adminIdCache[tostring(player.UserId)] = true
                    saveAdminsToDatabase()
                end
                -- No longer need the race-condition fix here, as handleAdminCheck now handles all cases
            end)
        end
    end

    Players.PlayerAdded:Connect(bootstrapAdmin)
    for _, player in ipairs(Players:GetPlayers()) do
        bootstrapAdmin(player)
    end

    -- MODIFIED: Always responds to the client
    local function handleAdminCheck(player)
        if not isCacheReady then
            table.insert(requestQueue, {player = player})
        else
            local isAdmin = AdminService.isAdmin(player)
            InjectedRemoteService:FireClient(player, "AdminStatusResponse", {isAdmin = isAdmin})
        end
    end
    
    -- MODIFIED: Returns a client-friendly list
    local function handleGetAdminList(player: Player): ({any} | nil, string)
        if not AdminService.isAdmin(player) then return nil, "Unauthorized" end
        
        local adminList = {}
        for id, _ in pairs(adminIdCache) do
            local userId = tonumber(id)
            if userId then
                -- Attempt to get the player's current name, fallback to ID if offline
                local p = Players:GetPlayerByUserId(userId)
                table.insert(adminList, {
                    userId = userId,
                    name = p and p.Name or ("ID: " .. id)
                })
            end
        end
        
        return adminList, ""
    end
    
    -- MODIFIED: Correctly handles adding an admin by name or ID
    local function handleAddAdmin(player: Player, target: string): (boolean, string)
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        if not target or target == "" then return false, "Invalid target specified" end
        
        local targetUserId: number?
        -- LINTER FIX: Prefix unused variable with _
        local success, _result = pcall(function() 
            if tonumber(target) then
                targetUserId = tonumber(target)
            else
                targetUserId = Players:GetUserIdFromNameAsync(target)
            end
        end)

        if not success or not targetUserId then
            return false, "Failed to find user ID for '" .. target .. "'. They may not exist." 
        end
        
        adminIdCache[tostring(targetUserId)] = true
        saveAdminsToDatabase()
        -- LINTER FIX: Use tostring() for the user ID
        print(string.format("👑 [AdminService] %s added %s as an admin.", player.Name, tostring(targetUserId)))
        return true, "Success"
    end
    
    -- Unchanged, but verified correct
    local function handleRemoveAdmin(player, targetUserId)
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        if not targetUserId then return false, "Invalid user ID" end
        
        adminIdCache[tostring(targetUserId)] = nil
        saveAdminsToDatabase()
        print(string.format("👑 [AdminService] %s removed admin rights for %s.", player.Name, tostring(targetUserId)))
        return true, "Success"
    end

    -- Register Remotes
    InjectedRemoteService:Register("RequestAdminCheck", handleAdminCheck)
    InjectedRemoteService:RegisterInvoke("RequestAdminList", handleGetAdminList)
    InjectedRemoteService:RegisterInvoke("AddAdmin", handleAddAdmin)
    InjectedRemoteService:RegisterInvoke("RemoveAdmin", handleRemoveAdmin)
    
    print("👑 [AdminService v2.9] Initialized.")
end

return AdminService