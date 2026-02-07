--[[
    RemoteService.luau (v1.1 - With SendToClient)

    Central, secure handler for all client-to-server and server-to-client traffic.
    Implements a nonce system to prevent replay attacks.
]]

--=================[ SERVICES ]=================--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--=================[ MODULES ]=================--
-- none

--=================[ CONFIGURATION ]=================--
local RemoteService = {}

local registeredEvents = {}
local playerNonceCounters = {}

-- Channels (lazy loaded)
local toClientChannel = nil
local fromClientChannel = nil

--///////////////////////////////////////////////////////////////////////////
--// PUBLIC API
--///////////////////////////////////////////////////////////////////////////

-- Mendaftarkan sebuah event dengan callback-nya.
function RemoteService:Register(eventName, callback)
    if registeredEvents[eventName] then
        warn(string.format("🔌 [RemoteService] Overwriting event '%s'.", eventName))
    end
    registeredEvents[eventName] = callback
end

-- Mengirim event dan data ke SATU klien tertentu.
function RemoteService:SendToClient(player, eventName, ...)
    -- Lazy load the channel if it doesn't exist
    if not toClientChannel then
        print("🔌 [RemoteService] Finding 'ClientStateChannel'...")
        toClientChannel = ReplicatedStorage:WaitForChild("ClientStateChannel")
        print("✅ [RemoteService] Server->Client channel cached.")
    end
    
    local payload = {
        eventName = eventName,
        args = {...}
    }
    
    toClientChannel:FireClient(player, payload)
end

--///////////////////////////////////////////////////////////////////////////
--// INTERNAL LOGIC & SECURITY
--///////////////////////////////////////////////////////////////////////////

-- Handler utama untuk semua permintaan yang masuk dari klien
local function onClientRequest(player, payload)
    if typeof(payload) ~= "table" then
        player:Kick("[RS-01] Invalid request.")
        return
    end

    local eventName, nonce = payload.eventName, payload.nonce
    if not eventName or not nonce or typeof(nonce) ~= "number" then
        player:Kick("[RS-02] Incomplete payload.")
        return
    end

    local lastNonce = playerNonceCounters[player.UserId]
    if not lastNonce or nonce <= lastNonce then
        player:Kick(string.format("[RS-03] Invalid request sequence. N: %d, S: %d", nonce, lastNonce or -1))
        return
    end

    local callback = registeredEvents[eventName]
    if not callback then
        player:Kick(string.format("[RS-04] Unknown event: %s", tostring(eventName)))
        return
    end

    playerNonceCounters[player.UserId] = nonce
    
    local success, result = pcall(callback, player, table.unpack(payload.args or {}))
    if not success then
        warn(string.format("🔌 [RemoteService] Error during callback for event '%s': %s", eventName, tostring(result)))
    end
end

--///////////////////////////////////////////////////////////////////////////
--// INITIALIZATION
--///////////////////////////////////////////////////////////////////////////

function RemoteService:Init()
    print("🔌 [RemoteService] Initializing secure remote handler...")

    fromClientChannel = Instance.new("RemoteEvent")
    fromClientChannel.Name = "ClientToServerChannel"
    fromClientChannel.Parent = ReplicatedStorage
    fromClientChannel.OnServerEvent:Connect(onClientRequest)

    -- Create the channel for server-to-client communication
    toClientChannel = Instance.new("RemoteEvent")
    toClientChannel.Name = "ClientStateChannel"
    toClientChannel.Parent = ReplicatedStorage

    Players.PlayerAdded:Connect(function(player)
        playerNonceCounters[player.UserId] = 0
    end)

    Players.PlayerRemoving:Connect(function(player)
        playerNonceCounters[player.UserId] = nil
    end)

    print("✅ [RemoteService] Secure handler is ready.")
end

return RemoteService
