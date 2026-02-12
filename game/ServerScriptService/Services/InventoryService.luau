--!strict
local InventoryService = {}
InventoryService.Name = "InventoryService"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteService: any
local DataService: any
local UnderwaterService: any

-- Aquarium bounds will be synced from UnderwaterService
local UNDERWATER_POS = Vector3.new(5000, -82.5, 5000)
local AQUARIUM_SIZE = Vector3.new(60, 35, 8)

function InventoryService:Init(dataService: any, remoteService: any, underwaterService: any)
    print("📦 [InventoryService] Initializing...")
    DataService = dataService
    RemoteService = remoteService
    UnderwaterService = underwaterService

    -- Sync bounds from UnderwaterService if available
    if UnderwaterService and UnderwaterService.GetAquariumBounds then
        local pos, size = UnderwaterService:GetAquariumBounds()
        UNDERWATER_POS = pos
        AQUARIUM_SIZE = size
    end

    RemoteService:Register("RequestDropFood", function(player: Player, itemId: string, position: Vector3)
        self:HandleDropFood(player, itemId, position)
    end)
end

function InventoryService:HandleDropFood(player: Player, itemId: string, position: Vector3)
    print(string.format("📦 [InventoryService] RequestDropFood from %s: %s at %s", player.Name, itemId, tostring(position)))
    -- 1. Security Check: Position within aquarium bounds
    local halfSize = AQUARIUM_SIZE / 2
    local minBound = UNDERWATER_POS - halfSize
    local maxBound = UNDERWATER_POS + halfSize

    if position.X < minBound.X or position.X > maxBound.X or
       position.Y < minBound.Y or position.Y > maxBound.Y or
       position.Z < minBound.Z or position.Z > maxBound.Z then
        warn(string.format("🛡️ [InventoryService] %s attempted to drop food outside bounds!", player.Name))
        return
    end

    -- 2. Security Check: Player has the item
    local playerData = DataService:Get(player)
    if not playerData or not playerData.Inventory or not playerData.Inventory.Food then
        return
    end

    local stock = playerData.Inventory.Food[itemId]
    if not stock or stock <= 0 then
        warn(string.format("🛡️ [InventoryService] %s attempted to drop food they don't have!", player.Name))
        return
    end

    -- 3. Update Inventory
    -- Create a deep copy to ensure DataService:Update detects a change and fires the event
    local newInventory = {}
    for k, v in pairs(playerData.Inventory) do
        if type(v) == "table" then
            newInventory[k] = {}
            for k2, v2 in pairs(v) do
                newInventory[k][k2] = v2
            end
        else
            newInventory[k] = v
        end
    end

    -- Ensure Food table exists in the new copy
    if not newInventory.Food then
        newInventory.Food = {}
    end

    newInventory.Food[itemId] -= 1
    local newStock = newInventory.Food[itemId]

    if newStock <= 0 then
        newInventory.Food[itemId] = nil
    end

    playerData.Inventory = newInventory
    DataService:Update(player, playerData)
    print(string.format("📦 [InventoryService] %s dropped food %s. New stock: %d", player.Name, itemId, newStock or 0))

    -- 4. Broadcast the drop to all clients in the area
    -- In this game, it seems everyone sees the same aquarium area when they enter.
    RemoteService:FireAllClients("FoodDropped", player.UserId, itemId, position)
end

return InventoryService
