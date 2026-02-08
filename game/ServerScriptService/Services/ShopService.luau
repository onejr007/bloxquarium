--!strict
--[=[
    @class ShopService
    Layanan ini bertanggung jawab untuk mengelola toko-toko di dalam game,
    termasuk memunculkan dan menggerakkan toko perahu, serta me-reset item toko secara berkala. (v10.2 - Admin Integration)
--]=]
local ShopService = {}
ShopService.Name = "ShopService"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local RemoteService -- Akan di-inject dari ServiceLoader
local DataService     -- Akan di-inject dari ServiceLoader

local SHOP_COOLDOWN = 600 -- 10 menit dalam detik
local currentShopDataCache = nil -- FIX: Menambahkan cache untuk data toko

function ShopService:Init(remoteService, dataService)
    print("⚓ [ShopService] Memulai layanan toko (v10.2 - Admin Integration)...")
    RemoteService = remoteService
    DataService = dataService

    self:StartBoatMovement()
    self:StartShopCycle()

    print("✅ [ShopService] Layanan toko berhasil dimulai!")
end

-- FIX: Fungsi publik baru untuk mendapatkan data dari cache
function ShopService:GetCachedShopData()
    return currentShopDataCache
end

function ShopService:StartBoatMovement()
    print("🛥️ [ShopService] Memulai pergerakan perahu...")
    local perahuModel = ReplicatedStorage:WaitForChild("assets"):WaitForChild("models"):WaitForChild("M_NPC"):WaitForChild("Perahu_shop")
    if not perahuModel then
        warn("WAR: [ShopService] Gagal menemukan model 'Perahu_shop'.")
        return
    end

    local perahuInstance = perahuModel:Clone()
    perahuInstance.Name = "PerahuShopInstance"

    local primaryPart = perahuInstance:FindFirstChild("Klop")
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

            perahuInstance:SetPrimaryPartCFrame(CFrame.new(newPosition, lookAtPosition) * rotationOffset * rollRotation)
        end
    end)

    prompt.Triggered:Connect(function(player)
        print(string.format("🛍️ [ShopService] Pemain '%s' membuka toko perahu.", player.Name))
        isMoving = false
        self:GetShopData():andThen(function(shopData)
            if shopData then
                RemoteService:SendToClient(player, "OpenShopGUI", shopData)
            else
                warn("WAR: [ShopService] Gagal mengirim data toko ke klien karena tidak ada datanya.")
            end
        end)
    end)

    RemoteService:Register("ResumeBoatMovement", function(player)
        print(string.format("🛥️ [ShopService] Menerima sinyal dari klien '%s'. Perahu kembali bergerak.", player.Name))
        isMoving = true
    end)
end

function ShopService:StartShopCycle()
    local function cycle()
        self:GetShopData():andThen(function(shopData)
            currentShopDataCache = shopData -- Memperbarui cache setiap kali data diambil
            local remainingTime = 0

            if shopData and shopData["end"] then
                local endTime = self:ParseISO8601(shopData["end"])
                local now = os.time()
                remainingTime = endTime - now
            end

            if remainingTime <= 0 then
                print("🛍️ [ShopService] Waktu toko berakhir atau data tidak ada. Mereset item toko...")
                self:ResetShop()
                task.wait(SHOP_COOLDOWN)
                cycle()
            else
                print(string.format("🛍️ [ShopService] Toko masih valid. Cooldown berikutnya dalam %d detik.", remainingTime))
                task.wait(remainingTime)
                cycle()
            end
        end):catch(function(err)
            warn("[ShopService] Gagal mendapatkan data toko di StartShopCycle. Mencoba lagi dalam 60 detik. Error: " .. tostring(err))
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
    DataService:Get("/game"):andThen(function(gameData)
        if not gameData or not gameData.chance then
            warn("CRITICAL: [ShopService] Tidak dapat mengambil data '/game/chance' dari Firebase untuk reset toko.")
            return
        end

        local newShopItems = {}
        for itemId, chanceData in pairs(gameData.chance) do
            if math.random() * 100 <= chanceData.chance then
                local stock = math.random(chanceData.stockMin, chanceData.stockMax)
                newShopItems[itemId] = stock
            end
        end

        local now = os.time()
        local startTime = os.date("!*t", now)
        local endTime = os.date("!*t", now + SHOP_COOLDOWN)

        local newShopData = {
            start = string.format("%04d-%02d-%02dT%02d:%02d:%02dZ", startTime.year, startTime.month, startTime.day, startTime.hour, startTime.min, startTime.sec),
            ["end"] = string.format("%04d-%02d-%02dT%02d:%02d:%02dZ", endTime.year, endTime.month, endTime.day, endTime.hour, endTime.min, endTime.sec),
            item = newShopItems
        }

        DataService:Set("/game/shop", newShopData):andThen(function()
            print("✅ [ShopService] Toko berhasil direset dengan item baru di Firebase.")
            currentShopDataCache = newShopData -- Memperbarui cache setelah reset berhasil
            
            for _, player in ipairs(Players:GetPlayers()) do
                RemoteService:SendToClient(player, "ShopUpdated", newShopData)
            end

        end):catch(function(err)
            warn("CRITICAL: [ShopService] Gagal menulis data toko baru ke Firebase. Error: " .. tostring(err))
        end)

    end):catch(function(err)
        warn("CRITICAL: [ShopService] Gagal mengambil data '/game' dari Firebase. Error: " .. tostring(err))
    end)
end

function ShopService:ParseISO8601(dateTimeString)
    local year, month, day, hour, min, sec = dateTimeString:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z")
    if not year then
        warn("WAR: [ShopService] Gagal mem-parsing string ISO8601: " .. dateTimeString)
        return os.time()
    end
    return os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec)
    })
end

return ShopService
