--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Remote = require(ReplicatedStorage.Shared.RemoteClient)
local ClientState = require(ReplicatedStorage.Shared.ClientState)
local Assets = require(ReplicatedStorage.Shared.AssetManagerV3)
local MainHUD = require(script.Parent:WaitForChild("MainHUDController"))
local ViewportManager = require(ReplicatedStorage.Shared:WaitForChild("ViewportManager"))

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local PlotController = {}

local UNDERWATER_POS = Vector3.new(5000, -100, 5000)
local isInteracting = false

-- ASSETS - Will be loaded when assets are ready
local FRAME_ICO, MENU_ICO, FISH_ICO, CLOSE_ICO, COIN_ICO, EGG_ICO, FOOD_ICO

local function loadAssets()
    FRAME_ICO = Assets.get("Frame_ico") or ""
    MENU_ICO = Assets.get("Menu_ico") or ""
    FISH_ICO = Assets.get("Fish_ico") or ""
    CLOSE_ICO = Assets.get("Close_ico") or ""
    COIN_ICO = Assets.get("Coin_ico") or ""
    EGG_ICO = Assets.get("Egg_ico") or ""
    FOOD_ICO = Assets.get("Food_ico") or ""
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
    
    local THEME = {
        PRIMARY = Color3.fromRGB(15, 25, 45),
        SECONDARY = Color3.fromRGB(10, 20, 35),
        ACCENT = Color3.fromRGB(0, 180, 255),
        WHITE = Color3.fromRGB(255, 255, 255),
        GOLD = Color3.fromRGB(255, 215, 0),
    }

    local sg = Instance.new("ScreenGui")
    sg.Name = "UnderwaterGui"
    sg.ResetOnSpawn = false
    
    local menuContainer = Instance.new("Frame")
    menuContainer.Size = UDim2.fromOffset(80, 480)
    menuContainer.Position = UDim2.new(1, -15, 1, -15)
    menuContainer.AnchorPoint = Vector2.new(1, 1)
    menuContainer.BackgroundTransparency = 1
    menuContainer.Parent = sg

    -- Submenu for Inventory (CanvasGroup for professional fade/masking)
    local invMenu = Instance.new("CanvasGroup")
    invMenu.Name = "InventoryMenu"
    invMenu.Size = UDim2.fromOffset(250, 400)
    invMenu.Position = UDim2.new(0, -25, 1, -110)
    invMenu.AnchorPoint = Vector2.new(1, 1)
    invMenu.BackgroundColor3 = THEME.PRIMARY
    invMenu.GroupTransparency = 1
    invMenu.Visible = false
    invMenu.Parent = menuContainer
    
    local invMenuGrad = Instance.new("UIGradient")
    invMenuGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 35, 60)),
        ColorSequenceKeypoint.new(1, THEME.SECONDARY)
    })
    invMenuGrad.Rotation = 45
    invMenuGrad.Parent = invMenu
    
    local uiCornerM = Instance.new("UICorner")
    uiCornerM.CornerRadius = UDim.new(0, 15)
    uiCornerM.Parent = invMenu
    
    local uiStrokeM = Instance.new("UIStroke")
    uiStrokeM.Color = THEME.ACCENT
    uiStrokeM.Thickness = 2
    uiStrokeM.Transparency = 0.5
    uiStrokeM.Parent = invMenu

    local invTitle = Instance.new("TextLabel")
    invTitle.Size = UDim2.new(1, 0, 0, 45)
    invTitle.BackgroundTransparency = 1
    invTitle.Text = "INVENTORY"
    invTitle.TextColor3 = THEME.WHITE
    invTitle.Font = Enum.Font.GothamBlack
    invTitle.TextSize = 16
    invTitle.Parent = invMenu
    
    local invScroll = Instance.new("ScrollingFrame")
    invScroll.Size = UDim2.new(1, -20, 1, -65)
    invScroll.Position = UDim2.fromOffset(10, 50)
    invScroll.BackgroundTransparency = 1
    invScroll.ScrollBarThickness = 3
    invScroll.ScrollBarImageColor3 = THEME.ACCENT
    invScroll.CanvasSize = UDim2.fromScale(0, 0)
    invScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    invScroll.Parent = invMenu
    
    local invListLayout = Instance.new("UIListLayout")
    invListLayout.Padding = UDim.new(0, 10)
    invListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    invListLayout.Parent = invScroll

    local function createIconButton(icon, position, size, name)
        local btn = Instance.new("ImageButton")
        btn.Name = name or "IconButton"
        btn.Size = UDim2.fromOffset(size or 60, size or 60)
        btn.Position = position
        btn.BackgroundTransparency = 1
        btn.Image = FRAME_ICO
        btn.AnchorPoint = Vector2.new(0.5, 0.5)
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = THEME.WHITE
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
            TweenService:Create(innerIcon, TweenInfo.new(0.3), {ImageColor3 = THEME.ACCENT}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.3), {Transparency = 0.4, Color = THEME.ACCENT}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(size or 60, size or 60)}):Play()
            TweenService:Create(innerIcon, TweenInfo.new(0.3), {ImageColor3 = THEME.WHITE}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.3), {Transparency = 0.9, Color = THEME.WHITE}):Play()
        end)
        
        return btn
    end

    local toggleBtn = createIconButton(MENU_ICO, UDim2.new(0.5, 0, 1, -35), 70, "Toggle")
    toggleBtn.Parent = menuContainer
    
    local fishBtn = createIconButton(FISH_ICO, UDim2.new(0.5, 0, 1, -35), 60, "Fish")
    fishBtn.Visible = false
    fishBtn.Parent = menuContainer
    
    local eggBtn = createIconButton(EGG_ICO, UDim2.new(0.5, 0, 1, -35), 60, "Egg")
    eggBtn.Visible = false
    eggBtn.Parent = menuContainer

    local foodBtn = createIconButton(FOOD_ICO, UDim2.new(0.5, 0, 1, -35), 60, "Food")
    foodBtn.Visible = false
    foodBtn.Parent = menuContainer

    local closeBtn = createIconButton(CLOSE_ICO, UDim2.new(0.5, 0, 1, -35), 60, "Close")
    closeBtn.Visible = false
    closeBtn.Parent = menuContainer
    
    -- Coin Display
    local coinFrame = Instance.new("Frame")
    coinFrame.Name = "CoinDisplay"
    coinFrame.Size = UDim2.fromOffset(180, 50)
    coinFrame.Position = UDim2.new(0, 25, 1, -25)
    coinFrame.AnchorPoint = Vector2.new(0, 1)
    coinFrame.BackgroundColor3 = THEME.PRIMARY
    coinFrame.BorderSizePixel = 0
    coinFrame.Parent = sg
    
    local coinCorner = Instance.new("UICorner")
    coinCorner.CornerRadius = UDim.new(0, 12)
    coinCorner.Parent = coinFrame
    
    local coinStroke = Instance.new("UIStroke")
    coinStroke.Color = THEME.GOLD
    coinStroke.Thickness = 2
    coinStroke.Transparency = 0.5
    coinStroke.Parent = coinFrame
    
    local coinIcon = Instance.new("ImageLabel")
    coinIcon.Size = UDim2.fromOffset(35, 35)
    coinIcon.Position = UDim2.new(0, 10, 0.5, 0)
    coinIcon.AnchorPoint = Vector2.new(0, 0.5)
    coinIcon.BackgroundTransparency = 1
    coinIcon.Image = COIN_ICO
    coinIcon.Parent = coinFrame
    
    local coinLabel = Instance.new("TextLabel")
    coinLabel.Size = UDim2.new(1, -55, 1, 0)
    coinLabel.Position = UDim2.new(0, 50, 0, 0)
    coinLabel.BackgroundTransparency = 1
    coinLabel.Text = "0"
    coinLabel.TextColor3 = THEME.WHITE
    coinLabel.Font = Enum.Font.GothamBlack
    coinLabel.TextSize = 22
    coinLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinLabel.Parent = coinFrame
    
    -- Sync Coins
    local lastCoins = -1 -- Start with -1 to force first update
    local function updateCoins(state)
        if state and state.Coins ~= nil then
            if state.Coins ~= lastCoins then
                lastCoins = state.Coins
                coinLabel.Text = tostring(state.Coins)
                
                -- Punch effect (only if not initial load)
                if lastCoins ~= -1 then
                    TweenService:Create(coinFrame, TweenInfo.new(0.1, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(190, 55)}):Play()
                    task.delay(0.1, function()
                        TweenService:Create(coinFrame, TweenInfo.new(0.2), {Size = UDim2.fromOffset(180, 50)}):Play()
                    end)
                end
            end
        end
    end
    
    -- ClientState:OnChange already calls the callback immediately with current state
    ClientState:OnChange(updateCoins)

    local function populateInventory(category: string)
        for _, child in ipairs(invScroll:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        
        local state = ClientState:GetState()
        local inventory = state.Inventory and state.Inventory[category] or {}
        
        invTitle.Text = category:upper() .. " INVENTORY"
        
        local itemsFound = 0
        for id, count in pairs(inventory) do
            if count <= 0 then continue end
            itemsFound += 1
            
            local item = Instance.new("Frame")
            item.Size = UDim2.new(1, 0, 0, 70)
            item.BackgroundColor3 = Color3.fromRGB(30, 45, 75)
            item.Parent = invScroll
            
            local itemCorner = Instance.new("UICorner")
            itemCorner.CornerRadius = UDim.new(0, 10)
            itemCorner.Parent = item
            
            local vpfFrame = Instance.new("Frame", item)
            vpfFrame.Size = UDim2.fromOffset(60, 60)
            vpfFrame.Position = UDim2.fromOffset(5, 5)
            vpfFrame.BackgroundTransparency = 1
            
            -- Resolve item data from database via AssetManager
            local itemData = Assets.GetItemData(id)
            local displayName = if itemData then itemData.name else id:gsub("id_%a+_", ""):gsub("^%l", string.upper)
            local modelName = if itemData then (itemData.mInfoName or itemData.mDropName) else displayName
            
            ViewportManager:CreateModelViewport(vpfFrame, modelName, 0, 1.2)
            
            local nLbl = Instance.new("TextLabel", item)
            nLbl.Size = UDim2.new(1, -80, 0, 20)
            nLbl.Position = UDim2.fromOffset(75, 15)
            nLbl.BackgroundTransparency = 1
            nLbl.Text = displayName:upper()
            nLbl.TextColor3 = THEME.WHITE
            nLbl.Font = Enum.Font.GothamBold
            nLbl.TextSize = 13
            nLbl.TextXAlignment = Enum.TextXAlignment.Left
            
            local cLbl = Instance.new("TextLabel", item)
            cLbl.Size = UDim2.new(1, -80, 0, 15)
            cLbl.Position = UDim2.fromOffset(75, 35)
            cLbl.BackgroundTransparency = 1
            cLbl.Text = "OWNED: " .. tostring(count)
            cLbl.TextColor3 = THEME.ACCENT
            cLbl.Font = Enum.Font.GothamMedium
            cLbl.TextSize = 11
            cLbl.TextXAlignment = Enum.TextXAlignment.Left
        end
        
        if itemsFound == 0 then
            local empty = Instance.new("TextLabel", invScroll)
            empty.Size = UDim2.new(1, 0, 0, 50)
            empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.Gotham
            empty.Text = "Inventory is empty"
            empty.RichText = true
            empty.Text = "<i>Inventory is empty</i>"
            empty.TextSize = 12
        end
    end

    local isOpen = false
    local currentMenu = nil -- "Fish", "Egg", "Food"
    
    local function toggleSubMenu(menuType)
        -- Map GUI categories to Database Inventory keys
        local dbCategory = menuType
        if menuType == "Fish" then dbCategory = "Fish" end
        if menuType == "Egg" then dbCategory = "Egg" end
        if menuType == "Food" then dbCategory = "Food" end

        if currentMenu == menuType then
            -- Close
            currentMenu = nil
            TweenService:Create(invMenu, TweenInfo.new(0.3), {GroupTransparency = 1, Position = UDim2.new(0, -10, 1, -110)}):Play()
            task.delay(0.3, function() if not currentMenu then invMenu.Visible = false end end)
        else
            -- Open/Switch
            currentMenu = menuType
            populateInventory(dbCategory)
            invMenu.Visible = true
            TweenService:Create(invMenu, TweenInfo.new(0.4, Enum.EasingStyle.Back), {GroupTransparency = 0, Position = UDim2.new(0, -25, 1, -110)}):Play()
        end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if not isOpen and currentMenu then
            toggleSubMenu(currentMenu)
        end
        
        if isOpen then
            fishBtn.Visible, eggBtn.Visible, foodBtn.Visible, closeBtn.Visible = true, true, true, true
            TweenService:Create(fishBtn, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, 1, -120)}):Play()
            TweenService:Create(eggBtn, TweenInfo.new(0.45, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, 1, -200)}):Play()
            TweenService:Create(foodBtn, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, 1, -280)}):Play()
            TweenService:Create(closeBtn, TweenInfo.new(0.55, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, 1, -360)}):Play()
        else
            local t = 0.3
            TweenService:Create(fishBtn, TweenInfo.new(t), {Position = UDim2.new(0.5, 0, 1, -35)}):Play()
            TweenService:Create(eggBtn, TweenInfo.new(t), {Position = UDim2.new(0.5, 0, 1, -35)}):Play()
            TweenService:Create(foodBtn, TweenInfo.new(t), {Position = UDim2.new(0.5, 0, 1, -35)}):Play()
            TweenService:Create(closeBtn, TweenInfo.new(t), {Position = UDim2.new(0.5, 0, 1, -35)}):Play()
            task.delay(t, function()
                if not isOpen then
                    fishBtn.Visible, eggBtn.Visible, foodBtn.Visible, closeBtn.Visible = false, false, false, false
                end
            end)
        end
    end)
    
    fishBtn.MouseButton1Click:Connect(function() toggleSubMenu("Fish") end)
    eggBtn.MouseButton1Click:Connect(function() toggleSubMenu("Egg") end)
    foodBtn.MouseButton1Click:Connect(function() toggleSubMenu("Food") end)
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
    MainHUD.SetHUDVisible(false)
    
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
    MainHUD.SetHUDVisible(true)
    loadingSg:Destroy()
    isInteracting = false
end

-- INITIALIZE IMMEDIATELY WHEN REQUIRED
PlotController:Init()

return PlotController
