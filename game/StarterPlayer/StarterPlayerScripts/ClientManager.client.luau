--[[
	ClientManager.client.luau (v1.4 - Handshake Fix)

	- FIXES the loading screen getting stuck forever.
	- The previous logic had a race condition where the server could send the "WorldReady" signal before the client was ready to listen for it.
	- This version implements a robust client-server handshake:
	    1. The client connects all of its event listeners as before.
	    2. It then fires a NEW event to the server: "ClientReady".
	    3. The server will now only send "WorldReady" AFTER it receives "ClientReady".
	- This guarantees the signal is never missed.
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Player & GUI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Shared Modules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local AssetManager = require(Shared:WaitForChild("AssetManagerV3"))
local RemoteClient = require(Shared:WaitForChild("RemoteClient"))
local ClientState = require(Shared:WaitForChild("ClientState"))

print("🚀 [ClientManager v1.4] Implementing client-server handshake.")

-- =======================================================================
-- 1. UI CREATION (Unchanged)
-- =======================================================================

local screenGui, backgroundFrame, progressFill, progressText, phaseLabel
local loadingState = { assetsReady = false, worldReady = false }

local function createLoadingUI()
	print("🎨 [ClientManager v1.4] Creating professional loading UI...")
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LoadingScreen"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 100
	backgroundFrame = Instance.new("Frame")
	backgroundFrame.Name = "Background"
	backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
	backgroundFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	backgroundFrame.Parent = screenGui
	local backgroundGradient = Instance.new("UIGradient")
	backgroundGradient.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 25, 35)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 20)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15)) }
	backgroundGradient.Rotation = 45
	backgroundGradient.Parent = backgroundFrame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 600, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = backgroundFrame
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 60)
	titleLabel.Position = UDim2.new(0, 0, 0, 20)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🎮 BLOXQUARIUM 🎮"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = mainFrame
	local progressFrame = Instance.new("Frame")
	progressFrame.Name = "ProgressFrame"
	progressFrame.Size = UDim2.new(1, 0, 0, 100)
	progressFrame.Position = UDim2.new(0, 0, 0, 150)
	progressFrame.BackgroundTransparency = 1
	progressFrame.Parent = mainFrame
	phaseLabel = Instance.new("TextLabel")
	phaseLabel.Name = "PhaseLabel"
	phaseLabel.Size = UDim2.new(1, 0, 0, 20)
	phaseLabel.Position = UDim2.new(0, 0, 0, 10)
	phaseLabel.BackgroundTransparency = 1
	phaseLabel.Text = "Initializing Client..."
	phaseLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	phaseLabel.TextScaled = true
	phaseLabel.Font = Enum.Font.Gotham
	phaseLabel.Parent = progressFrame
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(1, -40, 0, 8)
	progressBar.Position = UDim2.new(0, 20, 0, 40)
	progressBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	progressBar.Parent = progressFrame
	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 4)
	progressCorner.Parent = progressBar
	progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	progressFill.Parent = progressBar
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = progressFill
	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 255))}
	fillGradient.Parent = progressFill
	progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Size = UDim2.new(1, 0, 0, 25)
	progressText.Position = UDim2.new(0, 0, 0, 55)
	progressText.BackgroundTransparency = 1
	progressText.Text = "0%"
	progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressText.TextScaled = true
	progressText.Font = Enum.Font.GothamMedium
	progressText.Parent = progressFrame
	screenGui.Parent = playerGui
	print("✅ [ClientManager v1.4] UI created and parented successfully.")
end

-- =======================================================================
-- 2. UI & LOGIC CONTROLLERS (Unchanged)
-- =======================================================================

local function updateProgress(loaded, total)
	local percentage = (total > 0) and (loaded / total) or 0
	local targetPercent = math.floor(percentage * 100)
	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	local progressTween = TweenService:Create(progressFill, tweenInfo, {Size = UDim2.new(percentage, 0, 1, 0)})
	progressTween:Play()
	progressText.Text = string.format("%d%%", targetPercent)
end

local function updatePhase(phaseName, description)
    phaseLabel.Text = phaseName or ""
end

local function checkCompletionAndHide()
	if loadingState.assetsReady and loadingState.worldReady then
		print("✅ [ClientManager v1.4] All systems go. Hiding loading screen.")
		updatePhase("Welcome to Bloxquarium!")
		task.wait(1.0)
		local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fadeOutTween = TweenService:Create(backgroundFrame, fadeInfo, {BackgroundTransparency = 1})
		fadeOutTween:Play()
		fadeOutTween.Completed:Connect(function()
			screenGui:Destroy()
		end)
	end
end

-- =======================================================================
-- 3. INITIALIZATION SEQUENCE (HANDSHAKE LOGIC)
-- =======================================================================

createLoadingUI()

print("🔌 [ClientManager v1.4] Connecting to engine events...")

-- Listen for events from other modules
AssetManager.PhaseChanged:Connect(updatePhase)
AssetManager.PreloadProgress:Connect(updateProgress)

AssetManager.PreloadComplete:Connect(function(loaded, total)
	print("✅ [ClientManager v1.4] Asset preloading complete.")
	updateProgress(total, total)
	loadingState.assetsReady = true
	checkCompletionAndHide()
end)

-- **HANDSHAKE STEP 2:** The server will send this *after* we tell it we're ready.
RemoteClient:On("WorldReady", function()
	print("✅ [ClientManager v1.4] 'WorldReady' signal received from server.")
	loadingState.worldReady = true
	checkCompletionAndHide()
end)

ClientState:OnChange(function(newState)
	-- Ready to receive state changes.
end)

-- Start the asset loading process in the background
AssetManager.syncWithServerAsync():andThen(function(success)
    if success then
        AssetManager.preloadInitialAsync()
    else
        updatePhase("❌ CRITICAL ERROR: Could not sync with server.")
    end
end)

print("✅ [ClientManager v1.4] Client systems configured. Notifying server.")

-- **HANDSHAKE STEP 1:** Tell the server we are now ready to receive events.
RemoteClient:FireServer("ClientReady")

print("⏳ [ClientManager v1.4] Waiting for tasks and server handshake to complete.")
