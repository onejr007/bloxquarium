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

    RemoteService:Register("RequestDropFood", function(player: Player, itemId: string, position: Vector3, ownerId: number)
        self:HandleDropFood(player, itemId, position, ownerId)
    end)

    RemoteService:RegisterInvoke("RequestHatchEgg", function(player: Player, eggId: string)
        return self:HandleHatchEgg(player, eggId)
    end)
end

function InventoryService:HandleHatchEgg(player: Player, eggId: string)
    print(string.format("🥚 [InventoryService] RequestHatchEgg from %s: %s", player.Name, eggId))
    
    -- 1. Security Check: Player has the egg
    local playerData = DataService:Get(player)
    if not playerData or not playerData.Inventory or not playerData.Inventory.Egg then
        return false, "Data tidak ditemukan"
    end

    local stock = playerData.Inventory.Egg[eggId]
    if not stock or stock <= 0 then
        warn(string.format("🛡️ [InventoryService] %s attempted to hatch egg they don't have: %s", player.Name, eggId))
        return false, "Anda tidak memiliki telur ini"
    end

    -- 2. Get Egg Data
    local itemsData = DataService:Get("/items"):await()
    if not itemsData or not itemsData.Egg or not itemsData.Egg[eggId] then
        return false, "Data telur tidak valid"
    end

    local eggData = itemsData.Egg[eggId]
    local rewards = eggData.eggReward
    if not rewards then
        return false, "Telur ini tidak memiliki hadiah"
    end

    -- 3. Gacha Logic (Weighted Random)
    local totalChance = 0
    for _, reward in pairs(rewards) do
        totalChance += (reward.chance or 0)
    end

    local roll = math.random() * totalChance
    local currentSum = 0
    local wonFishId = nil

    -- Sort rewards by key to ensure deterministic roll order
    local rewardKeys = {}
    for k in pairs(rewards) do table.insert(rewardKeys, k) end
    table.sort(rewardKeys)

    for _, k in ipairs(rewardKeys) do
        local reward = rewards[k]
        currentSum += (reward.chance or 0)
        if roll <= currentSum then
            wonFishId = reward.fishId
            break
        end
    end

    if not wonFishId then
        -- Fallback to first reward if something goes wrong
        wonFishId = rewards[rewardKeys[1]].fishId
    end

    -- 4. Update Inventory
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

    -- Deduct Egg
    if not newInventory.Egg then newInventory.Egg = {} end
    newInventory.Egg[eggId] = (newInventory.Egg[eggId] or 1) - 1
    if newInventory.Egg[eggId] <= 0 then
        newInventory.Egg[eggId] = nil
    end

    -- Add Fish
    if not newInventory.Fish then newInventory.Fish = {} end
    newInventory.Fish[wonFishId] = (newInventory.Fish[wonFishId] or 0) + 1

    playerData.Inventory = newInventory
    DataService:Update(player, playerData)

    -- Save to DataStore/Firebase immediately
    if DataService.savePlayerData then
        DataService.savePlayerData(tostring(player.UserId), playerData, false)
    end

    print(string.format("🥚 [InventoryService] %s hatched %s and got %s", player.Name, eggId, wonFishId))

    -- 5. Return success and the won fish ID for client animation
    print(string.format("🥚 [InventoryService] Returning to client: true, %s", wonFishId))
    
    -- 🔧 BACKUP PLAN: Also fire a direct RemoteEvent to ensure the client gets the ID
    RemoteService:SendToClient(player, "EggHatched", wonFishId, eggId)
    
    return true, wonFishId
end

function InventoryService:HandleDropFood(player: Player, itemId: string, position: Vector3, ownerId: number)
    print(string.format("📦 [InventoryService] RequestDropFood from %s: %s at %s (Owner: %s)", player.Name, itemId, tostring(position), tostring(ownerId)))
    
    -- Default ownerId to player if missing
    ownerId = ownerId or player.UserId
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
    -- We send (playerUserId, itemId, position, ownerId)
    RemoteService:FireAllClients("FoodDropped", player.UserId, itemId, position, ownerId)
end

return InventoryService
