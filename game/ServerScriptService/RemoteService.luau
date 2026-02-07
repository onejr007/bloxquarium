--[[
    RemoteService.luau (v2.4 - Multi-Phase Loading)

    - The `GetAssetRegistry` invoke now returns both the asset config and the new loading phase config.
    - This provides the client with all the necessary information for a structured, multi-phase load.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Core Dependencies
local Remote = require(ServerScriptService.RemoteServer)
local DataService = require(script.Parent.DataService)

-- Configuration
local AssetConfig = require(script.Parent.asset_config)
local LoadingConfig = require(script.Parent.loading_config) -- Added Loading Config

local RemoteService = {}

local function Log(m)
    print(string.format("🛡️ [RemoteService v2.4] %s", m))
end

function RemoteService:Register(eventName, handler)
    Log(string.format("Registering Event: '%s'", eventName))
    Remote:On(eventName, handler)
end

function RemoteService:RegisterInvoke(eventName, handler)
    Log(string.format("Registering Invoke: '%s'", eventName))
    Remote:OnInvoke(eventName, handler)
end

function RemoteService:FireClient(player, eventName, args)
    Log(string.format("Firing client event '%s' for player %s", eventName, player.Name))
    Remote:FireClient(player, {eventName = eventName, args = args or {}})
end

function RemoteService:Init()
    Log("Initializing secure remote handler v2.4...")

    -- MODIFIED: Now returns a dictionary containing both configs
    self:RegisterInvoke("GetAssetRegistry", function(player)
        Log(string.format("Asset & Loading configs requested by: %s. Sending.", player.Name))
        return {
            AssetConfig = AssetConfig,
            LoadingConfig = LoadingConfig
        }
    end)

    self:RegisterInvoke("RequestAllPlayerData", function(player)
        if not player or not player:IsA("Player") then return nil end
        Log(string.format("Admin panel request for all data from: %s", player.Name))
        return DataService:GetAllPlayerData()
    end)

    self:Register("UpdatePlayerData", function(player, userId, newData)
        if not player or not player:IsA("Player") or not userId or not newData then return end
        Log(string.format("Admin panel update for user %s from: %s", tostring(userId), player.Name))
        DataService:UpdatePlayerData(userId, newData)
    end)

    self:Register("RequestAdminCheck", function(player)
        Log(string.format("Admin check request from: %s. Granting access.", player.Name))
        Remote:FireClient(player, {eventName = "AdminCheckResponse", args = {true}})
    end)

    Log("Secure handler is ready.")
end

return RemoteService
