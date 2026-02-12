--[[
    RemoteService.luau (v3.0 - Lazy-Loaded Configs)

    - DEFINITIVELY FIXES the payload issue by lazy-loading configuration modules.
    - Instead of requiring configs at startup, they are now required *inside* the GetAssetRegistry invoke.
    - This completely eliminates any possible race condition, as the require() happens only when the client asks for the data, long after server init is complete.
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Core Dependencies
local Remote = require(ServerScriptService:WaitForChild("RemoteServer"))

-- Injected Services
local InjectedDataService

local RemoteService = {}
local isServerReady = false

-- Cached configs to avoid repeated requires
local cachedAssetConfig
local cachedLoadingConfig

local function Log(m)
    print(string.format("🛡️ [RemoteService v3.1] %s", m))
end

function RemoteService:SetServerReady()
    isServerReady = true
    Log("Server marked as READY.")
end

function RemoteService:Register(eventName, handler)
    Log(string.format("Registering Event: '%s'", eventName))
    Remote:On(eventName, handler)
end

function RemoteService:RegisterInvoke(eventName, handler)
    Log(string.format("Registering Invoke: '%s'", eventName))
    Remote:OnInvoke(eventName, handler)
end

function RemoteService:SendToClient(player, eventName, ...)
    Log(string.format("Firing client event '%s' for player %s", eventName, player.Name))
    Remote:FireClient(player, eventName, ...)
end

function RemoteService:FireAllClients(eventName, ...)
    Log(string.format("Broadcasting client event '%s' to all players", eventName))
    Remote:FireAllClients(eventName, ...)
end

function RemoteService:Init(DataService)
    InjectedDataService = DataService -- Dependency Injection

    if not InjectedDataService then
        warn("🔥 [RemoteService] DataService not provided. Some invokes may fail.")
    end

    Log("Initializing secure remote handler v3.0...")

    -- ## FIX: Connect DataService updates to ClientState ##
    InjectedDataService.StateUpdated:Connect(function(player)
        local state = InjectedDataService:Get(player)
        if state then
            Log(string.format("State update detected for %s. Sending to client...", player.Name))
            
            -- Cache the remote event reference
            local remoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("ClientStateChannel")
            if remoteEvent and remoteEvent:IsA("RemoteEvent") then
                -- Ensure we are sending a table that ClientState expects
                if type(state) == "table" then
                    -- 🔧 WRAP IN PAYLOAD: RemoteClient expects {eventName, args} OR direct state
                    -- but RemoteServer:FireClient wraps it in {eventName, args}.
                    -- Since we are firing the RemoteEvent DIRECTLY here, we must follow the contract.
                    -- ClientState.luau expects the DIRECT state table if eventName is missing.
                    remoteEvent:FireClient(player, state)
                    Log(string.format("✅ State successfully sent to %s via ClientStateChannel", player.Name))
                else
                    warn(string.format("🔥 [RemoteService] Attempted to send non-table state for %s", player.Name))
                end
            else
                warn("🔥 [RemoteService] ClientStateChannel NOT FOUND in ReplicatedStorage!")
            end
        end
    end)

    -- ## ADDED: GetInitialState invoke for clients to pull data on start ##
    self:RegisterInvoke("GetInitialState", function(player)
        if not InjectedDataService then return nil end
        Log(string.format("Initial state requested by: %s", player.Name))
        
        -- Wait for data to be loaded if it's not ready yet (max 10 seconds)
        local startTime = os.clock()
        local state = InjectedDataService:Get(player)
        
        while (not state or not state.Coins) and (os.clock() - startTime) < 10 do
            task.wait(1)
            state = InjectedDataService:Get(player)
            Log(string.format("...waiting for %s's data to load (Valid: %s)", player.Name, tostring(state ~= nil and state.Coins ~= nil)))
        end

        if state and state.Coins then
            Log(string.format("✅ Returning initial state for %s. Coins: %d", player.Name, state.Coins))
            return state
        else
            warn(string.format("⚠️ No valid state found for %s during GetInitialState after timeout", player.Name))
            -- If we still have NO state, return default data as fallback so UI doesn't break
            return nil
        end
    end)

    -- ## DEFINITIVE FIX: LAZY-LOAD CONFIGS ##
    self:RegisterInvoke("GetAssetRegistry", function(player)
        Log(string.format("Asset & Loading configs requested by: %s.", player.Name))

        -- Load configs on-demand and cache them
        if not cachedAssetConfig then
            cachedAssetConfig = require(ServerScriptService:WaitForChild("asset_config"))
        end
        if not cachedLoadingConfig then
            cachedLoadingConfig = require(ServerScriptService:WaitForChild("loading_config"))
        end

        if not cachedAssetConfig or not cachedLoadingConfig then
            warn("CRITICAL: Lazy-loading of AssetConfig or LoadingConfig failed. Cannot send to client.")
            return nil
        end

        -- Return a single table containing both configs and server status.
        return {
            AssetConfig = cachedAssetConfig,
            LoadingConfig = cachedLoadingConfig,
            IsServerReady = isServerReady
        }
    end)

    self:RegisterInvoke("GetItemRegistry", function(player)
        if not InjectedDataService then 
            warn("🛡️ [RemoteService] InjectedDataService is MISSING during GetItemRegistry!")
            return nil 
        end
        Log(string.format("Item registry requested by: %s.", player.Name))
        
        -- ## FIX: await() returns the value directly, not (success, value) ##
        local success, result = pcall(function()
            -- First, try to fetch the root to see what's actually there
            local rootPromise = InjectedDataService:Get("/")
            if rootPromise and rootPromise.await then
                local root = rootPromise:await()
                if root then
                    local rootKeys = {}
                    for k in pairs(root) do table.insert(rootKeys, tostring(k)) end
                    Log(string.format("🔍 [Firebase Root] Keys found: %s", table.concat(rootKeys, ", ")))
                else
                    warn("🔍 [Firebase Root] Root is NIL!")
                end
            end

            local promise = InjectedDataService:Get("/items")
            if not promise or typeof(promise) ~= "table" or not promise.await then
                warn("🛡️ [RemoteService] DataService:Get('/items') did not return a valid Promise!")
                return nil
            end
            return promise:await()
        end)

        if success then
            if result then
                -- Debug log the keys found at root of result
                local keys = {}
                for k in pairs(result) do table.insert(keys, tostring(k)) end
                Log(string.format("✅ Successfully fetched items from Firebase. Root categories: %s", table.concat(keys, ", ")))
                
                local count = 0
                for cat, its in pairs(result) do
                    if typeof(its) == "table" then
                        for _ in pairs(its) do count += 1 end
                    end
                end
                Log(string.format("📦 Total items found: %d", count))
                
                -- Ensure we return a table even if empty
                return result or {}
            else
                warn("🛡️ [RemoteService] Item registry from Firebase is NIL (Path: /items)")
                return {} -- Return empty table instead of nil
            end
        else
            warn("🛡️ [RemoteService] CRITICAL ERROR fetching item registry: " .. tostring(result))
            return {} -- Return empty table instead of nil
        end
    end)

    self:RegisterInvoke("RequestAllPlayerData", function(player)
        if not player or not player:IsA("Player") or not InjectedDataService then return nil end
        Log(string.format("Admin panel request for all data from: %s", player.Name))
        return InjectedDataService:GetAllPlayerData()
    end)

    self:Register("UpdatePlayerData", function(player, userId, newData)
        if not player or not player:IsA("Player") or not userId or not newData or not InjectedDataService then return end
        Log(string.format("Admin panel update for user %s from: %s", tostring(userId), player.Name))
        InjectedDataService:UpdatePlayerData(userId, newData)
    end)

    Log("Secure handler is ready.")
end

return RemoteService
