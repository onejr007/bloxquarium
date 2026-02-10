--[[
    GameActions.luau (v3.1 - Added IsClientAdmin Check)
    - Acts as the central hub for all client-invoked actions.
    - Injects other services (AdminService, ShopService) to delegate tasks.
    - Added a specific 'IsClientAdmin' invoke for the client to check its own admin status efficiently.
]]

--=================[ CONFIGURATION ]=================--
local GameActions = {}

--=================[ INJECTED SERVICES ]=================--
local RemoteService
local AdminService
local ShopService
local PlotService

--///////////////////////////////////////////////////////////////////////////
--// ACTION HANDLERS
--///////////////////////////////////////////////////////////////////////////

local function onTeleport(player, target)
    local char = player.Character
    if not char then return end

    if target == "Shop" then
        local boat = workspace:FindFirstChild("PerahuShopInstance")
        if boat and boat.PrimaryPart then
            char:PivotTo(boat.PrimaryPart.CFrame * CFrame.new(0, 5, 10))
            return true
        end
    elseif target == "Plot" then
        local plot = PlotService.playerPlots[player]
        if plot then
            PlotService:TeleportCharacterToPlot(char, plot)
            return true
        end
    end
    return false, "Target teleport tidak ditemukan"
end

-- Example of a simple game action
local function onKickPlayer(player, targetPlayerName)
    if not AdminService.isAdmin(player) then
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

--///////////////////////////////////////////////////////////////////////////
--// INITIALIZATION
--///////////////////////////////////////////////////////////////////////////

function GameActions:Init(pRemoteService, pAdminService, pShopService, pPlotService)
    print("🎮 [GameActions] Initializing Centralized Game Actions...")

    RemoteService = pRemoteService
    AdminService = pAdminService
    ShopService = pShopService
    PlotService = pPlotService

    if not (RemoteService and AdminService and ShopService and PlotService) then
        warn("🔥 [GameActions] A required service is nil. Cannot register actions.")
        return
    end

    -- Register generic game actions
    RemoteService:RegisterInvoke("KickPlayer", onKickPlayer)
    print("   -> 'KickPlayer' registered.")

    RemoteService:RegisterInvoke("GameAction_Teleport", onTeleport)
    RemoteService:RegisterInvoke("GameAction_BuyItem", function(player, ...) return ShopService:ProcessPurchase(player, ...) end)
    print("   -> Player game actions registered (Teleport, BuyItem).")

    -- NEW: Register a dedicated check for the client's own admin status
    RemoteService:RegisterInvoke("IsClientAdmin", function(player) 
        return AdminService.isAdmin(player)
    end)
    print("   -> 'IsClientAdmin' registered for client-side UI checks.")

    -- Register all ADMIN actions, delegating to AdminService
    RemoteService:RegisterInvoke("RequestAdminList", function(player) return AdminService.GetAdminList(player) end)
    RemoteService:RegisterInvoke("AddAdmin", function(player, target) return AdminService.AddAdmin(player, target) end)
    RemoteService:RegisterInvoke("RemoveAdmin", function(player, targetId) return AdminService.RemoveAdmin(player, targetId) end)
    print("   -> Admin management actions registered.")

    -- Register all SHOP-ADMIN actions, delegating to AdminService/ShopService
    RemoteService:RegisterInvoke("GetShopAdminData", function(player) return AdminService.GetShopAdminData(player) end)
    
    RemoteService:RegisterInvoke("UpdateItemData", function(player, ...) 
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        return ShopService:UpdateItemData(...) 
    end)
    RemoteService:RegisterInvoke("AddItemData", function(player, ...) 
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        return ShopService:AddItemData(...) 
    end)
    RemoteService:RegisterInvoke("DeleteItemData", function(player, ...) 
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        return ShopService:DeleteItemData(...) 
    end)
    
    RemoteService:RegisterInvoke("UpdateShopStock", function(player, ...) 
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        return ShopService:UpdateShopStock(...) 
    end)
    RemoteService:RegisterInvoke("AddItemToShop", function(player, ...) 
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        return ShopService:AddItemToShop(...) 
    end)
    RemoteService:RegisterInvoke("RemoveItemFromShop", function(player, ...) 
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        return ShopService:RemoveItemFromShop(...) 
    end)
    RemoteService:RegisterInvoke("ResetShopCooldown", function(player) 
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        return ShopService:ForceRegenerateShop() 
    end)
    RemoteService:RegisterInvoke("UpdateChanceData", function(player, ...) 
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        return ShopService:UpdateChanceData(...) 
    end)
    RemoteService:RegisterInvoke("AddItemToChance", function(player, ...) 
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        return ShopService:AddItemToChance(...) 
    end)
    RemoteService:RegisterInvoke("RemoveItemFromChance", function(player, ...) 
        if not AdminService.isAdmin(player) then return false, "Unauthorized" end
        return ShopService:RemoveItemFromChance(...) 
    end)
    print("   -> Shop administration actions registered.")

    print("✅ [GameActions] All actions initialized and registered successfully.")
end

return GameActions
