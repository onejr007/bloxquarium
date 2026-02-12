--!strict
local GachaController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Remote = require(ReplicatedStorage.Shared.RemoteClient)
local Assets = require(ReplicatedStorage.Shared.AssetManagerV3)
local ViewportManager = require(ReplicatedStorage.Shared.ViewportManager)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local THEME = {
	PRIMARY = Color3.fromRGB(11, 15, 25),
	SECONDARY = Color3.fromRGB(20, 28, 45),
	ACCENT = Color3.fromRGB(0, 210, 255),
    GOLD = Color3.fromRGB(255, 215, 0),
	TEXT = Color3.fromRGB(240, 245, 255),
	SUCCESS = Color3.fromRGB(90, 220, 150),
    RARITY_COMMON = Color3.fromRGB(180, 180, 180),
    RARITY_UNCOMMON = Color3.fromRGB(90, 220, 150),
    RARITY_RARE = Color3.fromRGB(0, 180, 255),
    RARITY_EPIC = Color3.fromRGB(180, 0, 255),
    RARITY_LEGENDARY = Color3.fromRGB(255, 180, 0),
}

local screenGui: ScreenGui? = nil
local mainFrame: Frame? = nil
local wheelFrame: Frame? = nil

function GachaController:Init()
    print("🎡 [GachaController] Initialized with AAA visuals")
end

function GachaController:StartGacha(eggId: string, wonFishId: string, isMini: boolean?)
    return require(ReplicatedStorage.Shared.Promise).new(function(resolve)
        warn("🎡 [GachaController] StartGacha RECEIVED - eggId:", eggId, "wonFishId:", wonFishId, "isMini:", isMini)
        
        -- 🔧 FIX: Ensure we destroy existing UI if switching modes or if it's a full UI
        if screenGui then
            warn("🎡 [GachaController] Existing screenGui found. Name:", screenGui.Name)
            if not isMini or screenGui.Name == "GachaUI" then
                warn("🎡 [GachaController] Destroying old screenGui")
                screenGui:Destroy()
                screenGui = nil
            end
        end

        if not (isMini and screenGui) then 
            screenGui = Instance.new("ScreenGui")
            screenGui.Name = isMini and "GachaMiniUI" or "GachaUI"
            screenGui.ResetOnSpawn = false
            screenGui.DisplayOrder = isMini and 99998 or 99999
            screenGui.IgnoreGuiInset = true
            screenGui.Parent = PlayerGui
            warn("🎡 [GachaController] Created new screenGui:", screenGui.Name, "Parented to PlayerGui")
        else
            warn("🎡 [GachaController] Reusing existing mini screenGui")
            -- 🔧 FIX: Clean up any old mainFrame from previous cycle in the same screenGui
            local oldMain = screenGui:FindFirstChild("MainGachaFrame")
            if oldMain then 
                warn("🎡 [GachaController] Destroying old MainGachaFrame for new cycle")
                oldMain:Destroy() 
            end
        end

        -- Overlay Background (Only for Full UI)
        local bg
        if not isMini then
            bg = Instance.new("Frame", screenGui)
            bg.Size = UDim2.fromScale(1, 1)
            bg.BackgroundColor3 = Color3.new(0, 0, 0)
            bg.BackgroundTransparency = 1
            
            local gradient = Instance.new("UIGradient", bg)
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 20, 40)),
                ColorSequenceKeypoint.new(1, Color3.new(0,0,0))
            })
            gradient.Rotation = 45
            TweenService:Create(bg, TweenInfo.new(0.8), {BackgroundTransparency = 0.2}):Play()
        end

        if not wonFishId then
            warn("🎡 [GachaController] CRITICAL: wonFishId is nil! Aborting Gacha UI.")
            if screenGui then screenGui:Destroy() screenGui = nil end
            resolve(false)
            return
        end

        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainGachaFrame"
        mainFrame.BackgroundTransparency = 1
        
        if isMini then
            mainFrame.Size = UDim2.fromScale(0.15, 0.15)
            mainFrame.Position = UDim2.new(0.035, 70, 0.965, -130) -- Above coin frame
            mainFrame.AnchorPoint = Vector2.new(0.5, 1)
            
            -- Keep aspect ratio square
            local aspect = Instance.new("UIAspectRatioConstraint", mainFrame)
            aspect.AspectRatio = 1

            -- Glassmorphism Effect for Mini
            local miniBg = Instance.new("Frame", mainFrame)
            miniBg.Size = UDim2.fromScale(1.2, 1.2)
            miniBg.Position = UDim2.fromScale(0.5, 0.5)
            miniBg.AnchorPoint = Vector2.new(0.5, 0.5)
            miniBg.BackgroundColor3 = THEME.SECONDARY
            miniBg.BackgroundTransparency = 0.3
            miniBg.ZIndex = -1
            Instance.new("UICorner", miniBg).CornerRadius = UDim.new(0.5, 0)
            local stroke = Instance.new("UIStroke", miniBg)
            stroke.Color = THEME.ACCENT
            stroke.Transparency = 0.5
            stroke.Thickness = 2
        else
            -- Normal Hatch: Responsive & Smaller (70% of screen height max)
            mainFrame.Size = UDim2.fromScale(0.55, 0.55) -- Slightly smaller to give breathing room
            mainFrame.Position = UDim2.fromScale(0.5, 0.5)
            mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            
            -- CRITICAL: Ensure it doesn't get too big on wide screens or too small
            local aspect = Instance.new("UIAspectRatioConstraint", mainFrame)
            aspect.AspectRatio = 1
            aspect.DominantAxis = Enum.DominantAxis.Height
            
            local constraint = Instance.new("UISizeConstraint", mainFrame)
            constraint.MaxSize = Vector2.new(550, 550)
            constraint.MinSize = Vector2.new(300, 300)
        end
        mainFrame.Parent = screenGui

        -- 🔧 STOP BUTTON FOR AUTO HATCH
        if isMini then
            if not screenGui:FindFirstChild("StopAutoBtn") then
                local stopBtn = Instance.new("TextButton", screenGui)
                stopBtn.Name = "StopAutoBtn"
                stopBtn.Size = UDim2.fromOffset(120, 36)
                stopBtn.Position = UDim2.new(0.035, 70, 0.965, -300) -- Above gacha frame
                stopBtn.AnchorPoint = Vector2.new(0.5, 1)
                stopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
                stopBtn.TextColor3 = Color3.new(1, 1, 1)
                stopBtn.Font = Enum.Font.GothamBlack
                stopBtn.TextSize = 14
                stopBtn.Text = "STOP AUTO"
                stopBtn.ZIndex = 1000
                Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)
                Instance.new("UIStroke", stopBtn).Thickness = 2
                
                stopBtn.MouseButton1Click:Connect(function()
                    local PlotController = require(script.Parent.PlotController)
                    if PlotController and PlotController.StopAutoHatch then
                        PlotController:StopAutoHatch()
                    end
                    stopBtn:Destroy()
                end)
            end
        end

        -- Background Glow
        local glow = Instance.new("ImageLabel", mainFrame)
        glow.Size = UDim2.fromScale(1.5, 1.5)
        glow.Position = UDim2.fromScale(0.5, 0.5)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        glow.Image = Assets.Images.Gacha_Glow or "rbxassetid://6014264734"
        glow.ImageColor3 = THEME.ACCENT
        glow.ImageTransparency = 0.8
        glow.ZIndex = 0

        task.spawn(function()
            while glow and glow.Parent do
                TweenService:Create(glow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.4}):Play()
                task.wait(2)
                TweenService:Create(glow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.8}):Play()
                task.wait(2)
            end
        end)

        wheelFrame = Instance.new("Frame", mainFrame)
        wheelFrame.Size = UDim2.fromScale(1, 1)
        wheelFrame.BackgroundTransparency = 1
        wheelFrame.ZIndex = 5

        -- Pointer AAA Style
        local pointerContainer = Instance.new("Frame")
        pointerContainer.Name = "PointerContainer"
        pointerContainer.Size = isMini and UDim2.fromScale(0.25, 0.25) or UDim2.fromScale(0.15, 0.15)
        pointerContainer.Position = isMini and UDim2.new(0.5, 0, 0, -5) or UDim2.new(0.5, 0, 0, -20)
        pointerContainer.AnchorPoint = Vector2.new(0.5, 1) -- Bottom center of container at top center of frame
        pointerContainer.BackgroundTransparency = 1
        pointerContainer.ZIndex = 500 -- Ultra high priority
        pointerContainer.Parent = mainFrame

        local pointer = Instance.new("ImageLabel", pointerContainer)
        pointer.Size = UDim2.fromScale(1, 1)
        pointer.BackgroundTransparency = 1
        pointer.Image = Assets.Images.Pointer_ico or "rbxassetid://120202628835237"
        pointer.ScaleType = Enum.ScaleType.Fit
        pointer.ZIndex = 101

        local pointerGlow = Instance.new("ImageLabel", pointer)
        pointerGlow.Size = UDim2.fromScale(2, 2)
        pointerGlow.Position = UDim2.fromScale(0.5, 0.5)
        pointerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
        pointerGlow.BackgroundTransparency = 1
        pointerGlow.Image = Assets.Images.Gacha_Glow or "rbxassetid://6014264734"
        pointerGlow.ImageColor3 = THEME.GOLD
        pointerGlow.ImageTransparency = 0.5
        pointerGlow.ZIndex = 100

        -- Items Population
        local eggData = Assets.GetItemData(eggId)
        local rewards = eggData and eggData.eggReward or {}
        local rewardList = {}
        for _, r in pairs(rewards) do table.insert(rewardList, r.fishId) end
        
        local itemCount = 16
        local wheelItems = {}
        for i = 1, itemCount do
            table.insert(wheelItems, rewardList[(i-1) % #rewardList + 1])
        end

        local radius = isMini and 0.45 or 0.4
        local viewports = {}
        
        -- wheelFrame should be relative scale too
        wheelFrame.Size = UDim2.fromScale(1, 1)
        wheelFrame.Position = UDim2.fromScale(0.5, 0.5)
        wheelFrame.AnchorPoint = Vector2.new(0.5, 0.5)

        for i, fishId in ipairs(wheelItems) do
            local angle = ((i - 1) / #wheelItems) * math.pi * 2
            local x = math.cos(angle) * radius
            local y = math.sin(angle) * radius

            local fishData = Assets.GetItemData(fishId)
            local fishModelName = fishData.mInfoName or fishData.mDropName or fishData.name
            local rarityColor = THEME["RARITY_" .. (fishData.rarity or "COMMON"):upper()] or THEME.RARITY_COMMON

            local container = Instance.new("Frame", wheelFrame)
            container.Size = isMini and UDim2.fromScale(0.25, 0.25) or UDim2.fromScale(0.18, 0.18)
            container.Position = UDim2.fromScale(0.5 + x, 0.5 + y)
            container.AnchorPoint = Vector2.new(0.5, 0.5)
            container.BackgroundColor3 = THEME.SECONDARY
            container.BackgroundTransparency = 0.2
            container.ZIndex = 10
            
            local corner = Instance.new("UICorner", container)
            corner.CornerRadius = UDim.new(0, isMini and 8 or 15)

            local stroke = Instance.new("UIStroke", container)
            stroke.Color = rarityColor
            stroke.Thickness = isMini and 1 or 2
            stroke.Transparency = 0.3

            local itemGlow = Instance.new("ImageLabel", container)
            itemGlow.Size = UDim2.fromScale(1.8, 1.8)
            itemGlow.Position = UDim2.fromScale(0.5, 0.5)
            itemGlow.AnchorPoint = Vector2.new(0.5, 0.5)
            itemGlow.BackgroundTransparency = 1
            itemGlow.Image = Assets.Images.Gacha_Glow or "rbxassetid://6014264734"
            itemGlow.ImageColor3 = rarityColor
            itemGlow.ImageTransparency = 0.8
            itemGlow.ZIndex = 9

            local vp, model = ViewportManager:CreateModelViewport(
                container,
                fishModelName,
                fishData.mInfoRotate or 0,
                fishData.mInfoScale or 1.2
            )
            
            table.insert(viewports, {container = container, fishId = fishId, angleDeg = math.deg(angle)})
        end

        -- Center Viewport for Spin Wheel Model
        local centerContainer = Instance.new("Frame")
        centerContainer.Name = "CenterViewport"
        centerContainer.Size = isMini and UDim2.fromScale(0.45, 0.45) or UDim2.fromScale(0.35, 0.35)
        centerContainer.Position = UDim2.fromScale(0.5, 0.5)
        centerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        centerContainer.BackgroundTransparency = 1
        centerContainer.ZIndex = 200 -- Higher ZIndex to ensure it's on top of winnerUI
        centerContainer.Visible = false -- 🔧 Sembunyikan sampai spin selesai
        centerContainer.Parent = mainFrame

        local centerFishData = Assets.GetItemData(wonFishId)
        if not centerFishData then
            warn("🎡 [GachaController] CRITICAL: Data for wonFishId '" .. tostring(wonFishId) .. "' not found in registry!")
            if screenGui then screenGui:Destroy() screenGui = nil end
            resolve(false)
            return
        end
        
        local centerFishModelName = centerFishData.mInfoName or centerFishData.mDropName or centerFishData.name
        local centerVP, centerModel = ViewportManager:CreateModelViewport(
            centerContainer,
            centerFishModelName,
            centerFishData.mInfoRotate or 0,
            centerFishData.mInfoScale or 1.5
        )
        
        if centerModel then
            local baseCFrame = centerModel:GetPivot()
            task.spawn(function()
                local t = 0
                while centerContainer and centerContainer.Parent do
                    local dt = task.wait()
                    t += dt
                    -- Curve animation: Slow -> Fast -> Slow
                    local speed = 2 + math.sin(t * 2) * 1.5
                    centerModel:PivotTo(baseCFrame * CFrame.Angles(0, t * speed, 0))
                end
            end)
        end

        -- Target calculation
        local occurrences = {}
        for i, fishId in ipairs(wheelItems) do
            if fishId == wonFishId then table.insert(occurrences, i) end
        end
        local targetIndex = occurrences[math.random(1, #occurrences)]
        
        local spinDuration = isMini and 1.5 or 5
        local spins = isMini and 3 or 8
        local itemAngle = ((targetIndex - 1) / #wheelItems) * 360
        local finalRotation = (spins * 360) + (270 - itemAngle)

        -- Animation
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not wheelFrame or not wheelFrame.Parent then
                connection:Disconnect()
                return
            end
            for _, item in ipairs(viewports) do
                item.container.Rotation = -wheelFrame.Rotation
            end
        end)

        local spinTween = TweenService:Create(wheelFrame, TweenInfo.new(spinDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Rotation = finalRotation
        })
        
        spinTween:Play()
        spinTween.Completed:Wait()
        connection:Disconnect()

        -- 🔧 Tampilkan model tengah setelah spin berhenti
        centerContainer.Visible = true
        centerContainer.Size = UDim2.fromOffset(1, 1)
        TweenService:Create(centerContainer, TweenInfo.new(0.5, Enum.EasingStyle.Elastic), {
            Size = isMini and UDim2.fromScale(0.45, 0.45) or UDim2.fromScale(0.35, 0.35)
        }):Play()

        -- Winner Reveal AAA
        local winnerUI = viewports[targetIndex].container
        local wonFishData = centerFishData
        local winColor = THEME["RARITY_" .. (wonFishData.rarity or "COMMON"):upper()] or THEME.RARITY_COMMON

        -- Shake pointer
        TweenService:Create(pointer, TweenInfo.new(0.2, Enum.EasingStyle.Bounce), {Rotation = 15}):Play()
        task.wait(0.2)
        TweenService:Create(pointer, TweenInfo.new(0.2, Enum.EasingStyle.Bounce), {Rotation = 0}):Play()

        -- Scale winner
        TweenService:Create(winnerUI, TweenInfo.new(0.6, Enum.EasingStyle.Elastic), {
            Size = isMini and UDim2.fromScale(0.4, 0.4) or UDim2.fromScale(0.3, 0.3),
            BackgroundColor3 = THEME.PRIMARY,
            BackgroundTransparency = 0
        }):Play()
        
        -- 🔧 FIX: Ensure viewport contents remain visible during reveal
        local innerVP = winnerUI:FindFirstChildOfClass("ViewportFrame")
        if innerVP then
            innerVP.BackgroundTransparency = 1
            innerVP.ZIndex = winnerUI.ZIndex + 1
        end
        
        winnerUI.ZIndex = 50
        winnerUI:FindFirstChildOfClass("UIStroke").Color = THEME.GOLD
        winnerUI:FindFirstChildOfClass("UIStroke").Thickness = isMini and 3 or 5
        winnerUI:FindFirstChildOfClass("UIStroke").Transparency = 0

        if not isMini then
            -- Big win text
            local revealFrame = Instance.new("Frame", screenGui)
            revealFrame.Size = UDim2.fromScale(1, 1)
            revealFrame.BackgroundTransparency = 1
            revealFrame.ZIndex = 100

            local title = Instance.new("TextLabel", revealFrame)
            title.Size = UDim2.new(1, 0, 0, 100)
            title.Position = UDim2.new(0.5, 0, 0.2, 0)
            title.AnchorPoint = Vector2.new(0.5, 0.5)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamBlack
            title.TextSize = 32
            title.TextColor3 = THEME.GOLD
            title.Text = "NEW FISH UNLOCKED!"
            title.ZIndex = 101
            Instance.new("UIStroke", title).Thickness = 2

            local fishName = Instance.new("TextLabel", revealFrame)
            fishName.Size = UDim2.new(1, 0, 0, 50)
            fishName.Position = UDim2.new(0.5, 0, 0.75, 0)
            fishName.AnchorPoint = Vector2.new(0.5, 0.5)
            fishName.BackgroundTransparency = 1
            fishName.Font = Enum.Font.GothamBlack
            fishName.TextSize = 48
            fishName.TextColor3 = winColor
            fishName.Text = (wonFishData.name or "UNKNOWN"):upper()
            fishName.ZIndex = 101
            Instance.new("UIStroke", fishName).Thickness = 3

            task.wait(3)
            if screenGui then
                screenGui:Destroy()
                screenGui = nil
            end
        else
            -- Mini auto-close
            local miniFishName = Instance.new("TextLabel", mainFrame)
            miniFishName.Size = UDim2.new(1.5, 0, 0, 20)
            miniFishName.Position = UDim2.new(0.5, 0, 1, 15)
            miniFishName.AnchorPoint = Vector2.new(0.5, 0)
            miniFishName.BackgroundTransparency = 1
            miniFishName.Font = Enum.Font.GothamBlack
            miniFishName.TextSize = 14
            miniFishName.TextColor3 = winColor
            miniFishName.Text = (wonFishData.name or "UNKNOWN"):upper()
            miniFishName.ZIndex = 101
            local ns = Instance.new("UIStroke", miniFishName)
            ns.Thickness = 2
            ns.Transparency = 0.2

            task.wait(1.5)
            if screenGui and mainFrame and mainFrame.Parent == screenGui then
                mainFrame:Destroy()
            end
        end
        
        resolve(true)
    end)
end

function GachaController:StopGacha()
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
end

return GachaController
