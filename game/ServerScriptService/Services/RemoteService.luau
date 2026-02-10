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

-- Cached configs to avoid repeated requires
local cachedAssetConfig
local cachedLoadingConfig

local function Log(m)
    print(string.format("🛡️ [RemoteService v3.0] %s", m))
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

        -- Return a single table containing both configs.
        return {
            AssetConfig = cachedAssetConfig,
            LoadingConfig = cachedLoadingConfig
        }
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
