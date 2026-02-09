--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Remote = require(ReplicatedStorage.Shared.RemoteClient)
local ClientState = require(ReplicatedStorage.Shared.ClientState)
local Assets = require(ReplicatedStorage.Shared.AssetManagerV3)

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local PlotController = {}

local UNDERWATER_POS = Vector3.new(5000, -100, 5000)
local isInteracting = false

-- ASSETS - Will be loaded when assets are ready
local FRAME_ICO, MENU_ICO, FISH_ICO, CLOSE_ICO, COIN_ICO

local function loadAssets()
    FRAME_ICO = Assets.get("Frame_ico") or ""
    MENU_ICO = Assets.get("Menu_ico") or ""
    FISH_ICO = Assets.get("Fish_ico") or ""
    CLOSE_ICO = Assets.get("Close_ico") or ""
    COIN_ICO = Assets.get("Coin_ico") or ""
end

local function setControlsEnabled(enabled: boolean)
    local char = Player.Character
    local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?
    if not hum then return end
    
    if not enabled then
        hum.WalkSpeed = 0
        hum.JumpPower = 0
    else
        hum.WalkSpeed = 16 -- Default
        hum.JumpPower = 50 -- Default
    end
end

local function createLoadingScreen()
    local sg = Instance.new("ScreenGui")
    sg.Name = "LoadingScreen"
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 100
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(10, 20, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = sg
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.Text = "LOADING AQUARIUM..."
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextSize = 24
    text.TextTransparency = 1
    text.Parent = frame
    
    sg.Parent = Player.PlayerGui
    return sg, frame, text
end

local function createUnderwaterGui(onClose)
    -- Ensure assets are loaded before creating GUI
    if not Assets.IsReady() then
        warn("[PlotController] Assets not ready when creating underwater GUI!")
        return
    end
    
    -- Load assets if not already loaded
    if not FRAME_ICO then
        loadAssets()
    end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "UnderwaterGui"
    sg.ResetOnSpawn = false
    
    local menuContainer = Instance.new("Frame")
    menuContainer.Size = UDim2.fromOffset(80, 450)
    menuContainer.Position = UDim2.new(1, -15, 1, -15)
    menuContainer.AnchorPoint = Vector2.new(1, 1)
    menuContainer.BackgroundTransparency = 1
    menuContainer.Parent = sg

    -- Submenu for Fish (CanvasGroup for professional fade/masking)
    local fishMenu = Instance.new("CanvasGroup")
    fishMenu.Name = "FishSubMenu"
    fishMenu.Size = UDim2.fromOffset(220, 320)
    fishMenu.Position = UDim2.new(0, -20, 1, -110)
    fishMenu.AnchorPoint = Vector2.new(1, 1)
    fishMenu.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
    fishMenu.GroupTransparency = 1
    fishMenu.Visible = false
    fishMenu.Parent = menuContainer
    
    local fishMenuGrad = Instance.new("UIGradient")
    fishMenuGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 25, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 12, 20))
    })
    fishMenuGrad.Rotation = 45
    fishMenuGrad.Parent = fishMenu
    
    local uiCornerM = Instance.new("UICorner")
    uiCornerM.CornerRadius = UDim.new(0, 15)
    uiCornerM.Parent = fishMenu
    
    local uiStrokeM = Instance.new("UIStroke")
    uiStrokeM.Color = Color3.fromRGB(0, 170, 255)
    uiStrokeM.Thickness = 2
    uiStrokeM.Transparency = 0.4
    uiStrokeM.Parent = fishMenu

    local fishTitle = Instance.new("TextLabel")
    fishTitle.Size = UDim2.new(1, 0, 0, 40)
    fishTitle.BackgroundTransparency = 1
    fishTitle.Text = "AQUARIUM BIOTA"
    fishTitle.TextColor3 = Color3.new(1, 1, 1)
    fishTitle.Font = Enum.Font.GothamBold
    fishTitle.TextSize = 14
    fishTitle.Parent = fishMenu
    
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255), Color3.new(1,1,1))
    grad.Parent = fishTitle

    local fishScroll = Instance.new("ScrollingFrame")
    fishScroll.Size = UDim2.new(1, -20, 1, -60)
    fishScroll.Position = UDim2.fromOffset(10, 45)
    fishScroll.BackgroundTransparency = 1
    fishScroll.ScrollBarThickness = 2
    fishScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
    fishScroll.CanvasSize = UDim2.fromScale(0, 0)
    fishScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    fishScroll.Parent = fishMenu
    
    local fishListLayout = Instance.new("UIListLayout")
    fishListLayout.Padding = UDim.new(0, 8)
    fishListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    fishListLayout.Parent = fishScroll

    local function createIconButton(icon, position, size, name)
        local btn = Instance.new("ImageButton")
        btn.Name = name or "IconButton"
        btn.Size = UDim2.fromOffset(size or 60, size or 60)
        btn.Position = position
        btn.BackgroundTransparency = 1
        btn.Image = FRAME_ICO
        btn.AnchorPoint = Vector2.new(0.5, 0.5)
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(255, 255, 255)
        btnStroke.Thickness = 2
        btnStroke.Transparency = 0.9
        btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        btnStroke.Parent = btn
        
        local innerIcon = Instance.new("ImageLabel")
        innerIcon.Size = UDim2.fromScale(0.6, 0.6)
        innerIcon.Position = UDim2.fromScale(0.5, 0.5)
        innerIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        innerIcon.BackgroundTransparency = 1
        innerIcon.Image = icon
        innerIcon.Parent = btn
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.fromOffset((size or 60) + 10, (size or 60) + 10)}):Play()
            TweenService:Create(innerIcon, TweenInfo.new(0.3), {ImageColor3 = Color3.fromRGB(0, 200, 255)}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.3), {Transparency = 0.4, Color = Color3.fromRGB(0, 200, 255)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(size or 60, size or 60)}):Play()
            TweenService:Create(innerIcon, TweenInfo.new(0.3), {ImageColor3 = Color3.new(1, 1, 1)}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.3), {Transparency = 0.9, Color = Color3.new(1, 1, 1)}):Play()
        end)
        
        return btn
    end

    local toggleBtn = createIconButton(MENU_ICO, UDim2.new(0.5, 0, 1, -35), 70, "Toggle")
    toggleBtn.Parent = menuContainer
    
    local fishBtn = createIconButton(FISH_ICO, UDim2.new(0.5, 0, 1, -35), 60, "Fish")
    fishBtn.Visible = false
    fishBtn.Parent = menuContainer
    
    local closeBtn = createIconButton(CLOSE_ICO, UDim2.new(0.5, 0, 1, -35), 60, "Close")
    closeBtn.Visible = false
    closeBtn.Parent = menuContainer
    
    -- Coin Display (Bottom Left) - AAA Style
    local coinFrame = Instance.new("Frame")
    coinFrame.Name = "CoinDisplay"
    coinFrame.Size = UDim2.fromOffset(160, 45)
    coinFrame.Position = UDim2.new(0, 25, 1, -25)
    coinFrame.AnchorPoint = Vector2.new(0, 1)
    coinFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
    coinFrame.BorderSizePixel = 0
    coinFrame.Parent = sg
    
    local coinCorner = Instance.new("UICorner")
    coinCorner.CornerRadius = UDim.new(0, 10)
    coinCorner.Parent = coinFrame
    
    local coinStroke = Instance.new("UIStroke")
    coinStroke.Color = Color3.fromRGB(255, 200, 0)
    coinStroke.Thickness = 2
    coinStroke.Transparency = 0.6
    coinStroke.Parent = coinFrame
    
    local coinGrad = Instance.new("UIGradient")
    coinGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 40, 70)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 20, 35))
    })
    coinGrad.Rotation = 90
    coinGrad.Parent = coinFrame
    
    local coinIcon = Instance.new("ImageLabel")
    coinIcon.Size = UDim2.fromOffset(30, 30)
    coinIcon.Position = UDim2.new(0, 8, 0.5, 0)
    coinIcon.AnchorPoint = Vector2.new(0, 0.5)
    coinIcon.BackgroundTransparency = 1
    coinIcon.Image = COIN_ICO
    coinIcon.Parent = coinFrame
    
    local coinLabel = Instance.new("TextLabel")
    coinLabel.Size = UDim2.new(1, -50, 1, 0)
    coinLabel.Position = UDim2.new(0, 45, 0, 0)
    coinLabel.BackgroundTransparency = 1
    coinLabel.Text = "0"
    coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    coinLabel.Font = Enum.Font.GothamBold
    coinLabel.TextSize = 20
    coinLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinLabel.Parent = coinFrame
    
    -- Update Coins dynamically
    ClientState:OnChange(function(state)
        if state and state.Coins then
            coinLabel.Text = tostring(state.Coins)
            
            -- Simple punch effect when coins change
            TweenService:Create(coinFrame, TweenInfo.new(0.1, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(170, 50)}):Play()
            task.delay(0.1, function()
                TweenService:Create(coinFrame, TweenInfo.new(0.2), {Size = UDim2.fromOffset(160, 45)}):Play()
            end)
        end
    end)

    local function populateFishList()
        for _, child in ipairs(fishScroll:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        
        local stateData = ClientState:GetState()
        local fishInventory = (stateData.Inventory and stateData.Inventory.Fish) or {}
        local aquariumFish = stateData.AquariumFish or {}
        
        local hasAny = false
        
        local function addSection(title)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.9, 0, 0, 25)
            lbl.BackgroundTransparency = 1
            lbl.Text = title
            lbl.TextColor3 = Color3.fromRGB(0, 170, 255)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 11
            lbl.Parent = fishScroll
        end
        
        local function addFishItem(name, subtext)
            local item = Instance.new("Frame")
            item.Size = UDim2.new(0.95, 0, 0, 55)
            item.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
            item.Parent = fishScroll
            
            local itemCorner = Instance.new("UICorner")
            itemCorner.CornerRadius = UDim.new(0, 10)
            itemCorner.Parent = item
            
            local itemStroke = Instance.new("UIStroke")
            itemStroke.Color = Color3.fromRGB(0, 170, 255)
            itemStroke.Thickness = 1
            itemStroke.Transparency = 0.8
            itemStroke.Parent = item
            
            local itemGrad = Instance.new("UIGradient")
            itemGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 45, 70)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 30, 50))
            })
            itemGrad.Rotation = 90
            itemGrad.Parent = item
            
            local nLbl = Instance.new("TextLabel")
            nLbl.Size = UDim2.new(1, -15, 0, 25)
            nLbl.Position = UDim2.fromOffset(12, 6)
            nLbl.BackgroundTransparency = 1
            nLbl.Text = name
            nLbl.TextColor3 = Color3.new(1, 1, 1)
            nLbl.Font = Enum.Font.GothamBold
            nLbl.TextSize = 14
            nLbl.TextXAlignment = Enum.TextXAlignment.Left
            nLbl.Parent = item
            
            local sLbl = Instance.new("TextLabel")
            sLbl.Size = UDim2.new(1, -15, 0, 15)
            sLbl.Position = UDim2.fromOffset(12, 28)
            sLbl.BackgroundTransparency = 1
            sLbl.Text = subtext
            sLbl.TextColor3 = Color3.fromRGB(180, 190, 210)
            sLbl.Font = Enum.Font.Gotham
            sLbl.TextSize = 11
            sLbl.TextXAlignment = Enum.TextXAlignment.Left
            sLbl.Parent = item
        end
        
        if #aquariumFish > 0 then
            hasAny = true
            addSection("ALIVE IN TANK")
            for _, fish in ipairs(aquariumFish) do
                addFishItem(fish.Name or "Unknown Fish", "Healthy • Age: " .. (fish.Age or "Baby"))
            end
        end
        
        local invEntries = 0
        for _ in pairs(fishInventory) do invEntries += 1 end
        
        if invEntries > 0 then
            hasAny = true
            addSection("FISH INVENTORY")
            for fishId, count in pairs(fishInventory) do
                addFishItem(fishId:gsub("id_", ""):upper(), "Quantity: " .. tostring(count))
            end
        end
        
        if not hasAny then
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 100)
            lbl.BackgroundTransparency = 1
            lbl.Text = "No fish found in tank or inventory."
            lbl.TextColor3 = Color3.fromRGB(120, 120, 120)
            lbl.TextWrapped = true
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.Parent = fishScroll
        end
    end

    local isOpen = false
    local isFishMenuOpen = false
    
    toggleBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if not isOpen and isFishMenuOpen then
            isFishMenuOpen = false
            TweenService:Create(fishMenu, TweenInfo.new(0.3), {GroupTransparency = 1, Position = UDim2.new(0, -10, 1, -110)}):Play()
            task.delay(0.3, function() if not isFishMenuOpen then fishMenu.Visible = false end end)
        end
        
        if isOpen then
            fishBtn.Visible = true
            closeBtn.Visible = true
            TweenService:Create(fishBtn, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, 1, -120)}):Play()
            TweenService:Create(closeBtn, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, 1, -200)}):Play()
        else
            TweenService:Create(fishBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1, -35)}):Play()
            TweenService:Create(closeBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1, -35)}):Play()
            task.wait(0.4)
            if not isOpen then
                fishBtn.Visible = false
                closeBtn.Visible = false
            end
        end
    end)
    
    fishBtn.MouseButton1Click:Connect(function()
        isFishMenuOpen = not isFishMenuOpen
        if isFishMenuOpen then
            populateFishList()
            fishMenu.Visible = true
            TweenService:Create(fishMenu, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {GroupTransparency = 0, Position = UDim2.new(0, -25, 1, -110)}):Play()
        else
            TweenService:Create(fishMenu, TweenInfo.new(0.3), {GroupTransparency = 1, Position = UDim2.new(0, -10, 1, -110)}):Play()
            task.delay(0.3, function() if not isFishMenuOpen then fishMenu.Visible = false end end)
        end
    end)
    
    fishBtn.MouseEnter:Connect(function()
        if isOpen and not isFishMenuOpen then
            populateFishList()
            fishMenu.Visible = true
            TweenService:Create(fishMenu, TweenInfo.new(0.3), {GroupTransparency = 0, Position = UDim2.new(0, -20, 1, -110)}):Play()
        end
    end)
    
    fishMenu.MouseLeave:Connect(function()
        if not isFishMenuOpen then
            TweenService:Create(fishMenu, TweenInfo.new(0.3), {GroupTransparency = 1, Position = UDim2.new(0, -10, 1, -110)}):Play()
            task.delay(0.3, function() if not isFishMenuOpen then fishMenu.Visible = false end end)
        end
    end)

    closeBtn.MouseButton1Click:Connect(onClose)
    
    sg.Parent = Player.PlayerGui
    return sg
end

function PlotController:Init()
    -- 1. Handle Prompt Recognition (Owner vs Visitor)
    RunService.Heartbeat:Connect(function()
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Name == "PlotPrompt" then
                local plot = prompt.Parent.Parent
                if plot and plot:IsA("Model") then
                    local ownerName = plot.Name:gsub("Plot_", "")
                    if ownerName == Player.Name then
                        prompt.ActionText = "Manage My Aquarium"
                        prompt.ObjectText = "MY AQUARIUM"
                    else
                        prompt.ActionText = "Visit Aquarium"
                        prompt.ObjectText = ownerName .. "'s Aquarium"
                    end
                end
            end
        end
    end)

    Remote:On("RequestEnterAquariumClient", function(plotModel: Model, owner: Player)
        if isInteracting then return end
        isInteracting = true
        
        -- Logic to check if owner or visitor
        local isOwner = (owner == Player)
        print(string.format("   -> [Aquarium] Entering %s's aquarium (IsOwner: %s)", owner.Name, tostring(isOwner)))
        
        Remote:FireServer("RequestEnterAquarium", plotModel)
    end)
    
    Remote:On("EnterAquariumSequence", function(owner: Player, plotModel: Model)
        self:StartEnterSequence(owner, plotModel)
    end)
end

function PlotController:StartEnterSequence(owner: Player, plotModel: Model)
    setControlsEnabled(false)
    
    -- Disable proximity prompts locally so they don't show up in the camera view
    for _, p in ipairs(workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") then p.Enabled = false end
    end
    
    -- 1. Zoom in camera to front glass of aquarium model
    Camera.CameraType = Enum.CameraType.Scriptable
    local plotPivot = plotModel:GetPivot()
    
    -- Extreme zoom: Closer to the front glass
    -- Use 2.5 studs offset (closer to glass) and lower height (1.8)
    local offset = plotPivot.LookVector * -2.5
    local camHeight = 1.8
    local camPos = plotPivot.Position + offset + Vector3.new(0, camHeight, 0)
    
    -- Look at the center of the back glass (which is at +2 offset)
    local lookTarget = plotPivot.Position + (plotPivot.LookVector * 2) + Vector3.new(0, camHeight, 0)
    local targetCFrame = CFrame.lookAt(camPos, lookTarget)
    
    local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local zoomTween = TweenService:Create(Camera, tweenInfo, {CFrame = targetCFrame})
    zoomTween:Play()
    
    -- Wait for zoom to finish BEFORE showing loading
    zoomTween.Completed:Wait()
    task.wait(0.1)
    
    -- 2. Loading Screen
    local loadingSg, loadingFrame, loadingText = createLoadingScreen()
    local fadeIn = TweenService:Create(loadingFrame, TweenInfo.new(0.4), {BackgroundTransparency = 0})
    fadeIn:Play()
    TweenService:Create(loadingText, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    
    fadeIn.Completed:Wait()
    
    -- 3. Teleport to Underwater
    -- Extreme zoom (10 studs distance) and slightly higher for better framing
    -- Target looking slightly higher towards the center of the background wall
    local underwaterCamPos = UNDERWATER_POS + Vector3.new(0, 12, 10) 
    local underwaterTarget = UNDERWATER_POS + Vector3.new(0, 10, 0)
    Camera.CFrame = CFrame.lookAt(underwaterCamPos, underwaterTarget)
    
    task.wait(1.0) -- Simulate loading
    
    -- 4. Show Underwater GUI - Wait for assets to be ready
    local uwGui
    if Assets.IsReady() then
        uwGui = createUnderwaterGui(function()
            self:StartExitSequence(plotModel, loadingSg, uwGui)
        end)
    else
        -- Wait for assets to be ready before creating GUI
        Assets.OnReady:Once(function()
            uwGui = createUnderwaterGui(function()
                self:StartExitSequence(plotModel, loadingSg, uwGui)
            end)
        end)
        
        -- Wait a bit for the GUI to be created
        local maxWait = 5
        local waitTime = 0
        while not uwGui and waitTime < maxWait do
            task.wait(0.1)
            waitTime += 0.1
        end
        
        if not uwGui then
            warn("[PlotController] Failed to create underwater GUI after waiting for assets")
            return
        end
    end
    
    -- 5. Fade out loading
    TweenService:Create(loadingFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(loadingText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    task.wait(0.5)
end

function PlotController:StartExitSequence(plotModel: Model, loadingSg: ScreenGui, uwGui: ScreenGui)
    local frame = loadingSg:FindFirstChild("Frame") :: Frame
    local text = frame:FindFirstChild("TextLabel") :: TextLabel
    
    -- 1. Fade in loading
    TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    TweenService:Create(text, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    task.wait(0.6)
    
    uwGui:Destroy()
    
    -- 2. Teleport camera back to zoomed-in plot
    local plotPivot = plotModel:GetPivot()
    local offset = plotPivot.LookVector * -2.5
    local camHeight = 1.8
    local lookTarget = plotPivot.Position + (plotPivot.LookVector * 2) + Vector3.new(0, camHeight, 0)
    local zoomCFrame = CFrame.lookAt(plotPivot.Position + offset + Vector3.new(0, camHeight, 0), lookTarget)
    Camera.CFrame = zoomCFrame
    
    task.wait(0.3)
    
    -- 3. Fade out loading
    local fadeOut = TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 1})
    fadeOut:Play()
    TweenService:Create(text, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    fadeOut.Completed:Wait()
    
    -- Re-enable proximity prompts
    for _, p in ipairs(workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") then p.Enabled = true end
    end
    
    -- 4. Zoom out animation (Only after loading is gone)
    local char = Player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            Camera.CameraType = Enum.CameraType.Scriptable
            -- Move camera back to character's shoulder/back
            local backCFrame = hrp.CFrame * CFrame.new(2, 4, 12)
            local targetLook = hrp.Position + Vector3.new(0, 2, 0)
            local zoomOutTween = TweenService:Create(Camera, TweenInfo.new(1.0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {CFrame = CFrame.lookAt(backCFrame.Position, targetLook)})
            zoomOutTween:Play()
            zoomOutTween.Completed:Wait()
        end
    end
    
    -- 5. Reset camera and controls
    Camera.CameraType = Enum.CameraType.Custom
    setControlsEnabled(true)
    loadingSg:Destroy()
    isInteracting = false
end

-- INITIALIZE IMMEDIATELY WHEN REQUIRED
PlotController:Init()

return PlotController
