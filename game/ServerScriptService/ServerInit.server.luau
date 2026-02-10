--[[
    ServerInit.server.luau (v3.0 - Simplified ServerReady Broadcast)

    - The server no longer needs to wait for individual clients.
    - ServiceLoader now broadcasts a "ServerReady" signal to all clients once all systems are initialized.
    - This simplifies the logic and removes the old handshake.
]]

print("🚀 [Server] Starting Bloxquarium Professional Game Engine...")

-- Import the ServiceLoader
local ServerScriptService = game:GetService("ServerScriptService")
local ServiceLoader = require(ServerScriptService:WaitForChild("ServiceLoader"))

-- =======================================================================
-- INITIALIZATION
-- =======================================================================

-- The ServiceLoader handles the entire initialization process, 
-- including broadcasting "ServerReady" to all clients.
ServiceLoader:Init()

-- =======================================================================
-- SERVER READY
-- =======================================================================

print("✅ [Server] All server systems initialized successfully!")
print("📡 [Server] The 'ServerReady' signal has been broadcast to all connecting clients.")
print("🎮 [Server] Bloxquarium is now ready for players.")
