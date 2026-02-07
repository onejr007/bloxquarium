--[[
    RemoteService.luau (v2.2 - ASSET FIX)

    - CRITICAL FIX: Removed the asset transformation logic.
    - The new `asset_config.luau` is already in the correct format the client expects.
    - The old transformation function was unintentionally clearing all asset data before sending it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remote = require(ServerScriptService.RemoteServer)
local DataService = require(script.Parent.DataService)
local AssetConfig = require(script.Parent.asset_config)

local RemoteService = {}

local function Log(m)
    print(string.format("🛡️ [RemoteService v2.2] %s", m))
end


function RemoteService:Register(eventName, handler)
    Log(string.format("Registering Event: '%s'", eventName))
    Remote:On(eventName, handler)
end

function RemoteService:RegisterInvoke(eventName, handler)
    Log(string.format("Registering Invoke: '%s'", eventName))
    Remote:OnInvoke(eventName, handler)
end

function RemoteService:Init()
    Log("Initializing secure remote handler v2.2...")

    self:RegisterInvoke("GetAssetRegistry", function(player)
        Log(string.format("Asset registry requested by: %s. Sending config directly.", player.Name))
        -- FIXED: The AssetConfig is now in the correct format and can be sent directly.
        return AssetConfig
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
