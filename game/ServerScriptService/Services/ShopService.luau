--!strict
--[=[
    @class ShopService
    Layanan ini bertanggung jawab untuk mengelola toko-toko di dalam game,
    termasuk memunculkan dan menggerakkan toko perahu. (v7.4 - Idle Animation)
--]=]
local ShopService = {}
ShopService.Name = "ShopService"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteService -- Akan di-inject dari ServiceLoader

function ShopService:Init(remoteService)
    print("⚓ [ShopService] Memulai layanan toko (v7.4 - Idle Animation)...")
    RemoteService = remoteService

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
        -- [CONFIG] Nilai yang diminta dipertahankan
        local RADIUS = 235
        local Y_LEVEL = 14.8
        local DEGREES_PER_SECOND = 3
        local angle = 0
        local time = 0 -- Timer untuk animasi ombak

        while perahuInstance and perahuInstance.Parent do
            local deltaTime = RunService.Heartbeat:Wait()
            time = time + deltaTime

            -- [NEW] Logika pergerakan hanya aktif jika isMoving == true
            if isMoving then
                local angleChange = math.rad(DEGREES_PER_SECOND) * deltaTime
                angle = (angle + angleChange) % (math.pi * 2)
            end

            -- [NEW] Animasi ombak selalu aktif, baik bergerak maupun diam
            local bobbleHeight = 0.2 -- Mengurangi intensitas agar air tidak masuk
            local bobbleSpeed = 0.7
            local yOffset = math.sin(time * bobbleSpeed * math.pi * 2) * bobbleHeight

            local rollAngle = 1.5 -- Mengurangi goyangan agar lebih stabil
            local rollSpeed = 0.5
            local zRoll = math.rad(math.cos(time * rollSpeed * math.pi * 2) * rollAngle)

            -- Perhitungan posisi dan rotasi yang selalu diperbarui
            local newX = RADIUS * math.cos(angle)
            local newZ = RADIUS * math.sin(angle)
            local newPosition = Vector3.new(newX, Y_LEVEL + yOffset, newZ)

            local lookAtAngle = angle + math.rad(1)
            local lookAtX = RADIUS * math.cos(lookAtAngle)
            local lookAtZ = RADIUS * math.sin(lookAtAngle)
            local lookAtPosition = Vector3.new(lookAtX, Y_LEVEL, lookAtZ)
            
            local rotationOffset = CFrame.Angles(0, math.rad(90), 0)
            local rollRotation = CFrame.Angles(0, 0, zRoll)
            
            -- Menerapkan CFrame setiap frame
            perahuInstance:SetPrimaryPartCFrame(CFrame.new(newPosition, lookAtPosition) * rotationOffset * rollRotation)
        end
    end)

    prompt.Triggered:Connect(function(player)
        print(string.format("🛍️ [ShopService] Pemain '%s' membuka toko perahu.", player.Name))
        isMoving = false
        RemoteService:SendToClient(player, "OpenShopGUI")
    end)

    RemoteService:Register("ResumeBoatMovement", function(player)
        print(string.format("🛥️ [ShopService] Menerima sinyal dari klien '%s'. Perahu kembali bergerak.", player.Name))
        isMoving = true
    end)

    print("✅ [ShopService] Toko perahu dengan idle animation berhasil ditempatkan!")
end

return ShopService
