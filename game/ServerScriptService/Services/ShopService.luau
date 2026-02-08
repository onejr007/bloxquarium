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

local RemoteService: any -- Akan di-inject dari ServiceLoader
local DataService: any     -- Akan di-inject dari ServiceLoader

local SHOP_COOLDOWN = 600 -- 10 menit dalam detik
local currentShopDataCache: any = nil 

function ShopService:Init(remoteService: any, dataService: any)
    print("⚓ [ShopService] Memulai layanan toko (v11.0 - Database Driven)...")
    RemoteService = remoteService
    DataService = dataService

    self:StartBoatMovement()
    self:StartShopCycle()

    print("✅ [ShopService] Layanan toko berhasil dimulai!")
end

function ShopService:GetCachedShopData()
    return currentShopDataCache
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
        isMoving = false
        self:GetShopData():andThen(function(shopData: any)
            if shopData then
                RemoteService:SendToClient(player, "OpenShopGUI", shopData)
            else
                warn("WAR: [ShopService] Gagal mengirim data toko ke klien karena tidak ada datanya.")
            end
        end)
    end)

    RemoteService:Register("ResumeBoatMovement", function(player: Player)
        print(string.format("🛥️ [ShopService] Menerima sinyal dari klien '%s'. Perahu kembali bergerak.", player.Name))
        isMoving = true
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
                task.wait(30) -- Beri waktu Firebase untuk sinkronisasi sebelum siklus berikutnya
                cycle()
            else
                currentShopDataCache = shopData
                print(string.format("🛍️ [ShopService] Toko masih valid. Reset berikutnya dalam %d detik.", remainingTime))
                task.wait(math.min(remainingTime, 300)) -- Cek setiap 5 menit atau saat expired
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
        for itemId, config in pairs(chanceData) do
            local itemConfig = config :: any
            if math.random() * 100 <= (itemConfig.chance or 0) then
                local stock = math.random(itemConfig.stockMin or 1, itemConfig.stockMax or 5)
                newShopItems[itemId] = stock
            end
        end

        local now = os.time()
        local startTimeISO = self:ToISO8601(now)
        local endTimeISO = self:ToISO8601(now + SHOP_COOLDOWN)

        local newShopData = {
            start = startTimeISO,
            ["end"] = endTimeISO,
            item = newShopItems
        }

        DataService:Set("/game/shop", newShopData):andThen(function()
            print("✅ [ShopService] Toko berhasil diperbarui di Firebase.")
            currentShopDataCache = newShopData
            
            for _, player in ipairs(Players:GetPlayers()) do
                RemoteService:SendToClient(player, "ShopUpdated", newShopData)
            end
        end):catch(function(err: any)
            warn("CRITICAL: [ShopService] Gagal menulis data toko baru! " .. tostring(err))
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

return ShopService
