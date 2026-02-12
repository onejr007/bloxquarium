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

    RemoteService:RegisterInvoke("RequestPlaceDecoration", function(player: Player, itemId: string, cframe: CFrame)
        return self:HandlePlaceDecoration(player, itemId, cframe)
    end)

    RemoteService:RegisterInvoke("RequestRemoveDecoration", function(player: Player, decorId: string)
        return self:HandleRemoveDecoration(player, decorId)
    end)

    -- Load decorations when player data is ready
    DataService.StateUpdated:Connect(function(player: Player)
        self:LoadDecorations(player)
    end)
end

function InventoryService:LoadDecorations(player: Player)
    local playerData = DataService:Get(player)
    if not playerData or not playerData.PlacedDecorations then return end

    print(string.format("🌿 [InventoryService] Loading %d decorations for %s", #playerData.PlacedDecorations, player.Name))

    -- Clear existing decorations for this player to avoid duplicates on reload
    local world = workspace:FindFirstChild("UnderwaterWorld")
    local decorFolder = world and world:FindFirstChild("Decorations")
    if decorFolder then
        for _, decor in ipairs(decorFolder:GetChildren()) do
            if decor:GetAttribute("OwnerId") == player.UserId then
                decor:Destroy()
            end
        end
    end

    for _, data in ipairs(playerData.PlacedDecorations) do
        local itemId = data.itemId
        local cfComponents = data.cframe
        if itemId and cfComponents then
            local cframe = CFrame.new(unpack(cfComponents))
            self:SpawnDecorationInstance(player, itemId, cframe)
        end
    end
end

function InventoryService:SpawnDecorationInstance(player: Player, itemId: string, cframe: CFrame)
    -- 1. Get Item Data
    local itemsData = DataService:Get("/items")
    if itemsData and itemsData.await then
        itemsData = itemsData:await()
    end
    
    local decorationData = itemsData and (itemsData.Decoration or itemsData.decoration) and (itemsData.Decoration or itemsData.decoration)[itemId]
    if not decorationData then
        print(string.format("❌ [InventoryService] No decoration data found for %s", itemId))
        return nil
    end

    -- 2. Spawning Model
    local modelName = decorationData.mDropName
    print(string.format("🔍 [InventoryService] Searching for model: %s", tostring(modelName)))
    local dropScale = decorationData.mDropScale or 1
    local dropRotateStr = decorationData.mDropRotate or "0,0,0"
    
    -- Parse rotation string "x,y,z"
    local rx, ry, rz = 0, 0, 0
    local parts = dropRotateStr:split(",")
    if #parts == 3 then
        rx, ry, rz = tonumber(parts[1]) or 0, tonumber(parts[2]) or 0, tonumber(parts[3]) or 0
    end
    local baseRotation = CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))

    local assets = ReplicatedStorage:FindFirstChild("assets")
    local models = assets and assets:FindFirstChild("models")
    
    print(string.format("📂 [InventoryService] Assets folder: %s, Models folder: %s", tostring(assets), tostring(models)))

    local foundModel = nil
    if models then
        for _, category in ipairs(models:GetChildren()) do
            if category:IsA("Folder") then
                -- print(string.format("📁 [InventoryService] Checking category: %s", category.Name))
                foundModel = category:FindFirstChild(modelName, true)
                if foundModel then 
                    print(string.format("✅ [InventoryService] Found model %s in %s", modelName, category.Name))
                    break 
                end
            end
        end
    end

    if not foundModel then
        warn(string.format("⚠️ [InventoryService] Model '%s' not found for decoration!", tostring(modelName)))
        return nil
    end

    -- 3. Create Decoration Instance
    local world = workspace:FindFirstChild("UnderwaterWorld")
    if not world then
        world = Instance.new("Folder", workspace)
        world.Name = "UnderwaterWorld"
    end
    
    local decorFolder = world:FindFirstChild("Decorations")
    if not decorFolder then
        decorFolder = Instance.new("Folder", world)
        decorFolder.Name = "Decorations"
    end

    local newDecor = foundModel:Clone()
    -- Use a more unique name for existing decorations
    newDecor.Name = itemId .. "_" .. player.UserId .. "_" .. math.random(1000, 9999)
    
    -- Apply Scale
    if dropScale ~= 1 then
        newDecor:ScaleTo(dropScale)
    end
    
    newDecor:PivotTo(cframe * baseRotation)
	newDecor.Parent = decorFolder
	
	-- Ensure all parts can be detected by raycasts/overlaps
	for _, part in ipairs(newDecor:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanQuery = true
		end
	end
	
	-- Tag it with owner
    newDecor:SetAttribute("OwnerId", player.UserId)
    newDecor:SetAttribute("ItemId", itemId)

    return newDecor
end

function InventoryService:HandleRemoveDecoration(player: Player, decorId: string)
    print(string.format("🌿 [InventoryService] RequestRemoveDecoration from %s: %s", player.Name, decorId))
    
    local world = workspace:FindFirstChild("UnderwaterWorld")
    local decorFolder = world and world:FindFirstChild("Decorations")
    local decorModel = decorFolder and decorFolder:FindFirstChild(decorId)
    
    if not decorModel then return false, "Dekorasi tidak ditemukan" end
    if decorModel:GetAttribute("OwnerId") ~= player.UserId then return false, "Bukan pemilik dekorasi" end
    
    local itemId = decorModel:GetAttribute("ItemId")
    if not itemId then return false, "Item ID tidak valid" end

    -- 1. Update Player Data
    local playerData = DataService:Get(player)
    if not playerData then return false, "Data tidak ditemukan" end

    -- Return to Inventory
    if not playerData.Inventory then playerData.Inventory = {} end
    if not playerData.Inventory.Decoration then playerData.Inventory.Decoration = {} end
    playerData.Inventory.Decoration[itemId] = (playerData.Inventory.Decoration[itemId] or 0) + 1

    -- Remove from PlacedDecorations
    if playerData.PlacedDecorations then
        for i, data in ipairs(playerData.PlacedDecorations) do
            -- We don't have a unique ID for each placed decoration in the data, 
            -- but we can match by CFrame if needed. For now, let's just remove one instance of this itemId.
            if data.itemId == itemId then
                table.remove(playerData.PlacedDecorations, i)
                break
            end
        end
    end

    DataService:Update(player, playerData)
    
    -- 2. Destroy Model
    decorModel:Destroy()
    
    return true
end

function InventoryService:HandlePlaceDecoration(player: Player, itemId: string, cframe: CFrame)
    print(string.format("🌿 [InventoryService] RequestPlaceDecoration from %s: %s", player.Name, itemId))

    -- 1. Security Check: Player has the decoration
    local playerData = DataService:Get(player)
    if not playerData then
        print("❌ [InventoryService] Player data not found for", player.Name)
        return false, "Data tidak ditemukan"
    end
    
    if not playerData.Inventory or not playerData.Inventory.Decoration then
        print("❌ [InventoryService] Inventory/Decoration table missing for", player.Name)
        return false, "Inventory dekorasi tidak ditemukan"
    end

    local stock = playerData.Inventory.Decoration[itemId]
    print(string.format("📦 [InventoryService] Stock for %s: %s", itemId, tostring(stock)))
    
    if not stock or stock <= 0 then
        warn(string.format("🛡️ [InventoryService] %s attempted to place decoration they don't have: %s", player.Name, itemId))
        return false, "Anda tidak memiliki dekorasi ini"
    end

    -- 2. Get Item Data
    local itemsData = DataService:Get("/items")
    if itemsData and itemsData.await then
        itemsData = itemsData:await()
    end
    
    local decorationData = itemsData and (itemsData.Decoration or itemsData.decoration) and (itemsData.Decoration or itemsData.decoration)[itemId]
    if not decorationData then
        print("❌ [InventoryService] Decoration data not found in /items for", itemId)
        return false, "Data dekorasi tidak valid"
    end

    -- 3. Spawn Decoration
    print("🔨 [InventoryService] Spawning decoration instance...")
    local newDecor = self:SpawnDecorationInstance(player, itemId, cframe)
    if not newDecor then
        print("❌ [InventoryService] SpawnDecorationInstance failed for", itemId)
        return false, "Gagal memunculkan model dekorasi"
    end

    -- 4. Update Inventory & PlacedDecorations
    local newInventory = {}
    for k, v in pairs(playerData.Inventory) do
        if type(v) == "table" then
            newInventory[k] = {}
            for k2, v2 in pairs(v) do newInventory[k][k2] = v2 end
        else
            newInventory[k] = v
        end
    end

    newInventory.Decoration[itemId] = (newInventory.Decoration[itemId] or 1) - 1
    if newInventory.Decoration[itemId] <= 0 then
        newInventory.Decoration[itemId] = nil
    end

    playerData.Inventory = newInventory
    
    if not playerData.PlacedDecorations then playerData.PlacedDecorations = {} end
    table.insert(playerData.PlacedDecorations, {
        itemId = itemId,
        cframe = {cframe:GetComponents()} -- Serialize CFrame for JSON/Firebase
    })

    DataService:Update(player, playerData)
    
    -- Save to DataStore/Firebase immediately
    if DataService.savePlayerData then
        DataService.savePlayerData(tostring(player.UserId), playerData, false)
    end

    print(string.format("🌿 [InventoryService] %s placed decoration %s", player.Name, itemId))
    return true
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
