--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Remote = require(ReplicatedStorage.Shared.RemoteClient)

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local PlotController = {}

local UNDERWATER_POS = Vector3.new(5000, -100, 5000)
local isInteracting = false

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
    local sg = Instance.new("ScreenGui")
    sg.Name = "UnderwaterGui"
    sg.ResetOnSpawn = false
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(100, 40)
    closeBtn.Position = UDim2.new(1, -120, 0, 20)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "CLOSE"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = sg
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = closeBtn
    
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
    -- Extreme zoom (10 studs distance) and lower height for true 2.5D effect
    -- Target looking slightly down towards the background wall to show gravel/floor
    local underwaterCamPos = UNDERWATER_POS + Vector3.new(0, 10, 10) 
    local underwaterTarget = UNDERWATER_POS + Vector3.new(0, 8, 0)
    Camera.CFrame = CFrame.lookAt(underwaterCamPos, underwaterTarget)
    
    task.wait(1.0) -- Simulate loading
    
    -- 4. Show Underwater GUI
    local uwGui
    uwGui = createUnderwaterGui(function()
        self:StartExitSequence(plotModel, loadingSg, uwGui)
    end)
    
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
