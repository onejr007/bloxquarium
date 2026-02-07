--[[
    ServerInit.server.luau (v2.3 - Handshake Fix)

    - Implements the server-side part of the client-server handshake, fixing the stuck loading screen.
    - REMOVES the old, unreliable `PlayerAdded` logic that caused the race condition.
    - The server now waits for a "ClientReady" event from each client before sending back the "WorldReady" signal.
    - This guarantees that the client is always ready to receive the signal.
]]

print("🚀 [Server] Starting Bloxquarium Professional Game Engine...")

-- Import the ServiceLoader
local ServerScriptService = game:GetService("ServerScriptService")
local ServiceLoader = require(ServerScriptService:WaitForChild("ServiceLoader"))

-- =======================================================================
-- INITIALIZATION
-- =======================================================================

-- The ServiceLoader handles the entire initialization process.
ServiceLoader:Init()

-- =======================================================================
-- WORLD READY HANDSHAKE
-- =======================================================================

local RemoteService = ServiceLoader:GetService("RemoteService")

-- **HANDSHAKE STEP 3:** Wait for a client to tell us it's ready.
RemoteService:Register("ClientReady", function(player)
    print(string.format("🤝 [Server] Received 'ClientReady' from %s. Responding with 'WorldReady'.", player.Name))
    
    -- **HANDSHAKE STEP 4:** Respond to that specific client.
    if RemoteService then
        RemoteService:SendToClient(player, "WorldReady", {})
    else
        warn("[Server] RemoteService not available to notify player.")
    end
end)


-- =======================================================================
-- SERVER READY
-- =======================================================================

print("✅ [Server] All server systems initialized successfully!")
print("🎮 [Server] Bloxquarium is now ready for players and awaiting client handshakes.")
