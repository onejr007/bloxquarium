--[[
    GameActions.luau (v2.2 - Refactored for Dependency Injection)

    - Handles server-side logic for remote events.
    - Receives RemoteService via dependency injection for improved decoupling.
]]

--=================[ MODULES ]=================--
local ServerScriptService = game:GetService("ServerScriptService")
-- No longer requires RemoteService directly, it will be injected.
local AdminService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("AdminService"))

--=================[ CONFIGURATION ]=================--
local GameActions = {}

--///////////////////////////////////////////////////////////////////////////
--// INITIALIZATION
--///////////////////////////////////////////////////////////////////////////

function GameActions:Init(RemoteService)
    print("🎮 [GameActions] Initializing Game Actions...")

    if not RemoteService then
        warn("🔥 [GameActions] RemoteService is nil. Cannot register actions.")
        return
    end

    local function onKickPlayer(player, targetPlayerName)
        if not AdminService.isAdmin(player) then
            -- Note: Kicking a player for a failed admin check might be too aggressive.
            -- A simple return or a notification might be better.
            return false, "Permission Denied"
        end

        local targetPlayer = game:GetService("Players"):FindFirstChild(targetPlayerName)
        if targetPlayer then
            targetPlayer:Kick(string.format("You were kicked by an admin (%s).", player.Name))
            return true
        else
            return false, string.format("Player '%s' not found.", targetPlayerName)
        end
    end
    
    local function onBuyItem(player, itemId)
        -- The core logic for buying an item should be in another service (e.g., ShopService or DataService)
        -- GameActions should only validate and route the request.
        print(string.format("Player %s attempting to buy item %s", player.Name, tostring(itemId)))
        
        -- Example: Deferring to a hypothetical service
        -- local success, message = ShopService:PurchaseItem(player, itemId)
        -- return success, message
        
        -- Placeholder logic:
        return true, "Item purchased successfully (Placeholder)"
    end

    -- Register these actions as secure server-side invocations
    RemoteService:RegisterInvoke("GameAction_BuyItem", onBuyItem)
    print("   -> 'GameAction_BuyItem' registered for invocation.")

    RemoteService:RegisterInvoke("KickPlayer", onKickPlayer)
    print("   -> 'KickPlayer' registered for invocation.")
    
    print("✅ [GameActions] Game Actions initialized successfully.")
end

return GameActions
