--[[
    ServerInit.server.luau (v1.7 - ARCHITECTURE CORRECTION)

    - CRITICAL FIX: Removed the execution of the client-side `GameBootstrapper` script.
    - The server no longer attempts to run client-only code, which was the root cause of the `OnClientEvent` crash and asset loading failures.
    - This restores the fundamental client-server architecture.
]]

print("🚀 [Server] Starting Bloxquarium Professional Game Engine...")

-- Import core modules
local ServerScriptService = game:GetService("ServerScriptService")

-- Import Core Server Services
local DataService = require(ServerScriptService:WaitForChild("DataService"))
local RemoteService = require(ServerScriptService:WaitForChild("RemoteService"))
local GameActions = require(ServerScriptService:WaitForChild("GameActions"))
local LeaderboardService = require(ServerScriptService:WaitForChild("LeaderboardService"))
local AdminService = require(ServerScriptService:WaitForChild("AdminService"))

-- =======================================================================
-- CRITICAL INITIALIZATION SEQUENCE
-- =======================================================================

-- Step 1: Initialize the core remote service to enable client-server communication.
RemoteService:Init()

-- Step 2: Initialize other services.
LeaderboardService:Init()

-- Step 3: Register Game Actions with the correct remote handlers.
print("🛡️ [Server] Registering Secure Game Actions...")

RemoteService:RegisterInvoke("GameAction_BuyItem", function(player, itemId)
    return GameActions:BuyItem(player, itemId)
end)
print("   -> 'GameAction_BuyItem' registered for invocation.")

RemoteService:RegisterInvoke("KickPlayer", function(player, targetPlayerName)
    return GameActions:KickPlayer(player, targetPlayerName)
end)
print("   -> 'KickPlayer' registered for invocation.")

-- Step 4: Initialize the DataService. This comes last as it might depend on other systems.
DataService:Init()

-- =======================================================================
-- SERVER READY
-- =======================================================================

print("✅ [Server] All server systems initialized successfully!")
print("🎮 [Server] Bloxquarium is now ready for players!")
