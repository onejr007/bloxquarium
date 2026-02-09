--!strict
--[=[
    @class ShopService
    Layanan ini bertanggung jawab untuk mengelola toko-toko di dalam game,
    termasuk memunculkan dan menggerakkan toko perahu, serta me-reset item toko secara berkala. (v11.0 - Database Driven)
--]=]
local ShopService = {}
ShopService.Name = "ShopService"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Promise = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Promise"))

local RemoteService: any -- Akan di-inject dari ServiceLoader
local DataService: any     -- Akan di-inject dari ServiceLoader

local SHOP_COOLDOWN = 600 -- 10 menit dalam detik
local currentShopDataCache: any = nil

function ShopService:Init(remoteService: any, dataService: any)
    print("⚓ [ShopService] Memulai layanan toko (v11.0 - Database Driven)...")
    RemoteService = remoteService
    DataService = dataService
    self.playersInShop = {} -- {[Player]: boolean}

    -- Seeding check
    self:GetItemsData():andThen(function(data)
        if not data then
            warn("⚠️ [ShopService] Database '/items' kosong! Toko tidak akan menampilkan item.")
        end
    end)

    self:StartBoatMovement()
    self:StartShopCycle()

    Players.PlayerRemoving:Connect(function(player)
        if self.playersInShop[player] then
            self.playersInShop[player] = nil
        end
    end)

    print("✅ [ShopService] Layanan toko berhasil dimulai!")
end

function ShopService:GetCachedShopData()
    return currentShopDataCache
end

function ShopService:GetChanceData()
    return DataService:Get("/game/chance")
end

function ShopService:UpdateShopStock(itemId: string, newStock: number)
    if not currentShopDataCache or not currentShopDataCache.item then return end
    currentShopDataCache.item[itemId] = newStock
    return DataService:Set("/game/shop/item/" .. itemId, newStock)
end

function ShopService:ForceRegenerateShop()
    print("🛍️ [ShopService] Memaksa regenerasi toko dari Admin...")
    self:ResetShop()
    return true
end

function ShopService:AddItemToShop(itemId: string, stock: number)
    if not currentShopDataCache or not currentShopDataCache.item then return end
    currentShopDataCache.item[itemId] = stock
    return DataService:Set("/game/shop/item/" .. itemId, stock)
end

function ShopService:UpdateChanceData(itemId: string, data: any)
    return DataService:Update("/game/chance/" .. itemId, data)
end

function ShopService:AddItemToChance(itemId: string, data: any)
    return DataService:Set("/game/chance/" .. itemId, data)
end

function ShopService:GetItemsData()
    return DataService:Get("/items")
end

function ShopService:UpdateItemData(category: string, itemId: string, data: any)
    return DataService:Update("/items/" .. category .. "/" .. itemId, data)
end

function ShopService:AddItemData(category: string, itemId: string, data: any)
    return DataService:Set("/items/" .. category .. "/" .. itemId, data)
end

function ShopService:GetResolvedShopPayload(): any
    return Promise.new(function(resolve, reject)
        local shopData, itemsData = nil, nil

        local function checkAndResolve()
            if shopData and itemsData then
                print("🔍 [ShopService] Memulai resolusi data toko...")

                if not shopData then
                    warn("❌ [ShopService] GetResolvedShopPayload: shopData is NIL from DataService.")
                    reject("shopData is nil")
                    return
                end

                if not itemsData then
                    warn("❌ [ShopService] GetResolvedShopPayload: itemsData is NIL from DataService.")
                    reject("itemsData is nil")
                    return
                end

                local resolvedItems = {}
                local itemMap = shopData.item or {}

                print(string.format("   -> [Info] Ditemukan %d item di stok toko.", (function() local c = 0 for _ in pairs(itemMap) do c += 1 end return c end)()))

                for id, stock in pairs(itemMap) do
                    if typeof(id) ~= "string" then continue end
                    if id == "start" or id == "end" then continue end

                    local details = nil
                    local foundCategory = nil

                    for categoryName, categoryItems in pairs(itemsData) do
                        if typeof(categoryItems) == "table" and categoryItems[id] then
                            details = categoryItems[id]
                            foundCategory = categoryName
                            break
                        end
                    end

                    if details and foundCategory then
                        local modelName = details.mInfoName or details.mDropName or "ModelMissing"
                        print(string.format("   -> [Resolved] ID: %s | Kategori: %s | Model: %s", id, foundCategory, tostring(modelName)))
                        print(string.format("   -> [DEBUG] Data lengkap untuk ID %s: %s", id, HttpService:JSONEncode(details)))

                        table.insert(resolvedItems, {
                            id = id,
                            stock = stock,
                            category = foundCategory,
                            details = {
                                name = details.name or id,
                                mInfoName = modelName,
                                price = details.price or 0,
                                rarity = details.rarity or "common",
                                description = details.desc or ""
                            }
                        })
                    else
                        warn(string.format("⚠️ [ShopService] Item ID '%s' ditemukan di stok toko tapi TIDAK ada di database items!", id))
                    end
                end

                print(string.format("✅ [ShopService] Berhasil meresolusi %d item.", #resolvedItems))

                local finalPayload = {
                    endTime = shopData["end"],
                    startTime = shopData.start,
                    items = resolvedItems
                }
                print("   -> [DEBUG] Payload final yang akan dikirim: " .. HttpService:JSONEncode(finalPayload))
                resolve(finalPayload)
            end
        end

        self:GetShopData():andThen(function(data)
            shopData = data
            checkAndResolve()
        end)

        self:GetItemsData():andThen(function(data)
            itemsData = data
            checkAndResolve()
        end)
    end)
end

function ShopService:StartBoatMovement()
    print("🛥️ [ShopService] Memulai pergerakan perahu...")
    local assets = ReplicatedStorage:WaitForChild("assets")
    local models = assets:WaitForChild("models")
    local npcModels = models:WaitForChild("M_NPC")
    local perahuModel = npcModels:WaitForChild("Perahu_shop") :: Model?
    
    if not perahuModel then
        warn("WAR: [ShopService] Gagal menemukan model 'Perahu_shop'.")
        return
    end

    local perahuInstance = perahuModel:Clone() :: Model
    perahuInstance.Name = "PerahuShopInstance"

    local primaryPart = perahuInstance:FindFirstChild("Klop") :: BasePart?
    if not primaryPart then
        warn("CRITICAL: [ShopService] Tidak dapat menemukan PrimaryPart 'Klop'.")
        perahuInstance:Destroy()
        return
    end
    perahuInstance.PrimaryPart = primaryPart
    perahuInstance.Parent = workspace

    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText = "Nelayan"
    prompt.ActionText = "Buka Toko"
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 25
    prompt.RequiresLineOfSight = false
    prompt.Parent = primaryPart

    local isMoving = true

    task.spawn(function()
        local RADIUS = 235
        local Y_LEVEL = 14.8
        local DEGREES_PER_SECOND = 3
        local angle = 0
        local time = 0

        while perahuInstance and perahuInstance.Parent do
            local deltaTime = RunService.Heartbeat:Wait()
            time = time + deltaTime

            if isMoving then
                local angleChange = math.rad(DEGREES_PER_SECOND) * deltaTime
                angle = (angle + angleChange) % (math.pi * 2)
            else
                local count = 0
                for _ in pairs(self.playersInShop) do count += 1 end
                if count == 0 then
                    isMoving = true
                end
            end

            local bobbleHeight = 0.2
            local bobbleSpeed = 0.7
            local yOffset = math.sin(time * bobbleSpeed * math.pi * 2) * bobbleHeight

            local rollAngle = 1.5
            local rollSpeed = 0.5
            local zRoll = math.rad(math.cos(time * rollSpeed * math.pi * 2) * rollAngle)

            local newX = RADIUS * math.cos(angle)
            local newZ = RADIUS * math.sin(angle)
            local newPosition = Vector3.new(newX, Y_LEVEL + yOffset, newZ)

            local lookAtAngle = angle + math.rad(1)
            local lookAtX = RADIUS * math.cos(lookAtAngle)
            local lookAtZ = RADIUS * math.sin(lookAtAngle)
            local lookAtPosition = Vector3.new(lookAtX, Y_LEVEL, lookAtZ)

            local rotationOffset = CFrame.Angles(0, math.rad(90), 0)
            local rollRotation = CFrame.Angles(0, 0, zRoll)

            perahuInstance:PivotTo(CFrame.new(newPosition, lookAtPosition) * rotationOffset * rollRotation)
        end
    end)

    prompt.Triggered:Connect(function(player: Player)
        print(string.format("🛍️ [ShopService] Pemain '%s' membuka toko perahu.", player.Name))
        self.playersInShop[player] = true
        isMoving = false
        
        self:GetResolvedShopPayload():andThen(function(payload: any)
            if payload then
                print(string.format("--> [DEBUG] Hendak mengirim OpenShopGUI ke %s...", player.Name))
                RemoteService:SendToClient(player, "OpenShopGUI", payload)
                print(string.format("<-- [DEBUG] Selesai mengirim OpenShopGUI ke %s.", player.Name))
            else
                warn("WAR: [ShopService] Gagal mengirim data toko ke klien karena data tidak lengkap.")
            end
        end):catch(function(err)
            warn("WAR: [ShopService] Error saat mengambil data toko: " .. tostring(err))
        end)
    end)

    RemoteService:Register("ResumeBoatMovement", function(player: Player)
        print(string.format("🛥️ [ShopService] Menerima sinyal dari klien '%s'.", player.Name))
        self.playersInShop[player] = nil
    end)
end

function ShopService:StartShopCycle()
    local function cycle()
        print("🛍️ [ShopService] Mengecek status toko...")
        self:GetShopData():andThen(function(shopData: any)
            local now = os.time()
            local needsReset = false
            local remainingTime = 0

            if not shopData or not shopData["end"] then
                needsReset = true
            else
                local endTime = self:ParseISO8601(shopData["end"])
                remainingTime = (endTime :: number) - now
                if remainingTime <= 0 then
                    needsReset = true
                end
            end

            if needsReset then
                print("🛍️ [ShopService] Toko kedaluwarsa atau kosong. Mereset...")
                self:ResetShop()
                task.wait(30) 
                cycle()
            else
                currentShopDataCache = shopData
                print(string.format("🛍️ [ShopService] Toko masih valid. Reset berikutnya dalam %d detik.", remainingTime))
                task.wait(math.min(remainingTime, 300))
                cycle()
            end
        end):catch(function(err: any)
            warn("[ShopService] Gagal sinkronisasi toko. Mencoba lagi dalam 60 detik. Error: " .. tostring(err))
            task.wait(60)
            cycle()
        end)
    end

    task.spawn(cycle)
end

function ShopService:GetShopData()
    return DataService:Get("/game/shop")
end

function ShopService:ResetShop()
    print("🛍️ [ShopService] Mengambil probabilitas item dari database...")
    
    DataService:Get("/game/chance"):andThen(function(chanceData: any)
        if not chanceData then
            warn("CRITICAL: [ShopService] Data '/game/chance' tidak ditemukan di database!")
            return
        end

        local newShopItems = {}
        local chanceList = {}
        for id, cfg in pairs(chanceData) do
            table.insert(chanceList, {id = id, cfg = cfg})
        end

        local attempts = 0
        while next(newShopItems) == nil or (#(function() local t={} for k in pairs(newShopItems) do table.insert(t,k) end return t end)()) < 2 do
            for _, entry in ipairs(chanceList) do
                local itemId = entry.id
                local itemConfig = entry.cfg
                if math.random() * 100 <= (itemConfig.chance or 0) then
                    local stock = math.random(itemConfig.stockMin or 1, itemConfig.stockMax or 10)
                    newShopItems[itemId] = stock
                end
            end
            attempts += 1
            if attempts > 5 then break end 
        end

        local now = os.time()
        local startTimeISO = self:ToISO8601(now)
        local endTimeISO = self:ToISO8601(now + SHOP_COOLDOWN)

        local newShopData = {
            start = startTimeISO,
            ["end"] = endTimeISO,
            item = newShopItems
        }

        Promise.all({
            DataService:Set("/game/shop", newShopData)
        }):andThen(function()
            return self:GetResolvedShopPayload()
        end):andThen(function(payload: any)
            if not payload then error("Gagal generate payload") end
            print("✅ [ShopService] Toko berhasil diperbarui di Firebase.")
            currentShopDataCache = newShopData
            
            for _, player in ipairs(Players:GetPlayers()) do
                -- This is for broadcasting to everyone on reset, not for individual triggers
                -- RemoteService:SendToClient(player, "OpenShopGUI", payload)
            end
        end):catch(function(err: any)
            warn("CRITICAL: [ShopService] Gagal menulis atau mengirim data toko baru! " .. tostring(err))
        end)

    end):catch(function(err: any)
        warn("CRITICAL: [ShopService] Gagal mengakses database '/game/chance'! " .. tostring(err))
    end)
end

function ShopService:ParseISO8601(dateTimeString: string)
    local year, month, day, hour, min, sec = dateTimeString:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z")
    if not year then return os.time() end
    
    return os.time({
        year = tonumber(year) :: number,
        month = tonumber(month) :: number,
        day = tonumber(day) :: number,
        hour = tonumber(hour) :: number,
        min = tonumber(min) :: number,
        sec = tonumber(sec) :: number
    })
end

function ShopService:ToISO8601(timestamp: number)
    local t = os.date("!*t", timestamp) :: any
    return string.format("%04d-%02d-%02dT%02d:%02d:%02dZ", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

function ShopService:DeleteItemData(category: string, itemId: string)
    return DataService:Delete("/items/" .. category .. "/" .. itemId)
end

return ShopService
