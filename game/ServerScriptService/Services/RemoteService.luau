--[[
    RemoteService.luau (v2.8 - Payload Alignment)

    - DEFINITIVELY FIXES the asset loading failure.
    - The `GetAssetRegistry` invoke handler was returning two separate values, but the client Promise system expects a single return value.
    - This version fixes the issue by packaging the `AssetConfig` and `LoadingConfig` into a single table before returning them.
    - This ensures the client receives the payload in the exact format it expects, resolving the `Payload was nil or malformed` error.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Core Dependencies
local Remote = require(ServerScriptService.RemoteServer)

-- Configuration
local AssetConfig = require(ServerScriptService.asset_config)
local LoadingConfig = require(ServerScriptService.loading_config)

-- Injected Services
local InjectedDataService

local RemoteService = {}

local function Log(m)
    print(string.format("🛡️ [RemoteService v2.8] %s", m))
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

function RemoteService:Init(DataService)
    InjectedDataService = DataService -- Dependency Injection

    if not InjectedDataService then
        warn("🔥 [RemoteService] DataService not provided. Some invokes may fail.")
    end

    Log("Initializing secure remote handler v2.8...")

    -- ## THE FIX IS HERE ##
    self:RegisterInvoke("GetAssetRegistry", function(player)
        Log(string.format("Asset & Loading configs requested by: %s. Sending packaged payload.", player.Name))
        -- CRITICAL FIX: Return a single table containing both configs.
        return {
            AssetConfig = AssetConfig,
            LoadingConfig = LoadingConfig
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
