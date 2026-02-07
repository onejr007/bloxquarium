--[[
	LoadingScreen.client.luau (v1.1 - World Sync)
	
	- Waits for a 'WorldReady' signal from the server before hiding.
	- Ensures the game world is fully generated before the player is allowed in.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules to load
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameBootstrapper = require(Shared:WaitForChild("GameBootstrapper"))
local RemoteClient = require(Shared:WaitForChild("RemoteClient"))

local LoadingScreen = {}

-- UI Elements
local screenGui, mainFrame, backgroundFrame, logoFrame, titleLabel, subtitleLabel, progressFrame, progressBar, progressFill, progressText, phaseLabel, statusLabel, errorFrame, errorList, skipButton, versionLabel

-- Loading state
local loadingState = {
	isVisible = false,
	bootstrapComplete = false,
	worldReady = false,
	errors = {},
}

-- Create professional loading UI (function remains the same, omitted for brevity)
local function createLoadingUI()
	-- Main ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LoadingScreen"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 100
	screenGui.Parent = playerGui
	
	-- Background Frame
	backgroundFrame = Instance.new("Frame")
	backgroundFrame.Name = "Background"
	backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
	backgroundFrame.Position = UDim2.new(0, 0, 0, 0)
	backgroundFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	backgroundFrame.BorderSizePixel = 0
	backgroundFrame.Parent = screenGui
	
	-- Gradient background
	local backgroundGradient = Instance.new("UIGradient")
	backgroundGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 25, 35)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
	}
	backgroundGradient.Rotation = 45
	backgroundGradient.Parent = backgroundFrame
	
	-- Main Content Frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 600, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = backgroundFrame
	
	-- Logo Frame
	logoFrame = Instance.new("Frame")
	logoFrame.Name = "LogoFrame"
	logoFrame.Size = UDim2.new(1, 0, 0, 120)
	logoFrame.Position = UDim2.new(0, 0, 0, 0)
	logoFrame.BackgroundTransparency = 1
	logoFrame.Parent = mainFrame
	
	-- Title Label
	titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 60)
	titleLabel.Position = UDim2.new(0, 0, 0, 20)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🎮 BLOXQUARIUM 🎮"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = logoFrame
	
	-- Subtitle Label
	subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubtitleLabel"
	subtitleLabel.Size = UDim2.new(1, 0, 0, 30)
	subtitleLabel.Position = UDim2.new(0, 0, 0, 85)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Professional Game Engine"
	subtitleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	subtitleLabel.TextScaled = true
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.Parent = logoFrame
	
	-- Progress Frame
	progressFrame = Instance.new("Frame")
	progressFrame.Name = "ProgressFrame"
	progressFrame.Size = UDim2.new(1, 0, 0, 100)
	progressFrame.Position = UDim2.new(0, 0, 0, 150)
	progressFrame.BackgroundTransparency = 1
	progressFrame.Parent = mainFrame
	
	-- Progress Bar Background
	progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(1, -40, 0, 8)
	progressBar.Position = UDim2.new(0, 20, 0, 40)
	progressBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressFrame
	
	-- Progress Bar Corner
	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 4)
	progressCorner.Parent = progressBar
	
	-- Progress Fill
	progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.Position = UDim2.new(0, 0, 0, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBar
	
	-- Progress Fill Corner
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = progressFill
	
	-- Progress Fill Gradient
	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 255))
	}
	fillGradient.Parent = progressFill
	
	-- Progress Text
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
	
	-- Phase Label
	phaseLabel = Instance.new("TextLabel")
	phaseLabel.Name = "PhaseLabel"
	phaseLabel.Size = UDim2.new(1, 0, 0, 20)
	phaseLabel.Position = UDim2.new(0, 0, 0, 10)
	phaseLabel.BackgroundTransparency = 1
	phaseLabel.Text = "Initializing..."
	phaseLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	phaseLabel.TextScaled = true
	phaseLabel.Font = Enum.Font.Gotham
	phaseLabel.Parent = progressFrame
	
	-- Status Label
	statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 40)
	statusLabel.Position = UDim2.new(0, 0, 0, 280)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Starting game systems..."
	statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = mainFrame
	
	-- Version Label
	versionLabel = Instance.new("TextLabel")
	versionLabel.Name = "VersionLabel"
	versionLabel.Size = UDim2.new(0, 200, 0, 20)
	versionLabel.Position = UDim2.new(1, -220, 1, -40)
	versionLabel.BackgroundTransparency = 1
	versionLabel.Text = "v1.1.0 - World Sync Edition"
	versionLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	versionLabel.TextSize = 12
	versionLabel.Font = Enum.Font.Gotham
	versionLabel.Parent = backgroundFrame
end

-- Update and other UI functions (omitted for brevity)
local function updateProgress(targetPercent)
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local progressTween = TweenService:Create(progressFill, tweenInfo, {Size = UDim2.new(targetPercent / 100, 0, 1, 0)})
	progressTween:Play()
	progressText.Text = string.format("%d%%", targetPercent)
end

local function updatePhase(phase, message)
	local phaseNames = { READY = "✅ World Ready" }
	phaseLabel.Text = phaseNames[phase] or phase
	if message then statusLabel.Text = message end
end

-- Show/Hide functions (omitted for brevity)
function LoadingScreen.Show()
	if loadingState.isVisible then return end
	loadingState.isVisible = true
	screenGui.Enabled = true
	-- animations...
end

function LoadingScreen.Hide()
	if not loadingState.isVisible then return end
	loadingState.isVisible = false
	
	local fadeInfo = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeOutTween = TweenService:Create(backgroundFrame, fadeInfo, {BackgroundTransparency = 1})
	fadeOutTween:Play()
	
	fadeOutTween.Completed:Connect(function()
		screenGui.Enabled = false
		screenGui:Destroy() -- Clean up the UI
	end)
end

-- Check if both client and server are ready
local function checkCompletion()
	if loadingState.bootstrapComplete and loadingState.worldReady then
		print("🎮 [LoadingScreen] Client bootstrap and server world ready. Finalizing...")
		updateProgress(100)
		updatePhase("READY", "Welcome to Bloxquarium!")
		
		task.wait(2) -- Short delay to appreciate the moment
		LoadingScreen.Hide()
	end
end

-- Initialize loading screen
local function initialize()
	createLoadingUI()
	LoadingScreen.Show()

	-- 1. Listen for the server's 'WorldReady' signal
	RemoteClient:On("WorldReady", function()
		print("🌍 [LoadingScreen] Received 'WorldReady' signal from server.")
		loadingState.worldReady = true
		updatePhase("SYNCING", "World generated. Finalizing client...")
		checkCompletion()
	end)

	-- 2. Connect to GameBootstrapper events
	GameBootstrapper.ProgressUpdated:Connect(function(step, total, percentage, message)
		-- We'll scale the bootstrap progress to 90%, with the final 10% for the world sync
		updateProgress(percentage * 0.9)
		if message then statusLabel.Text = message end
	end)
	
	GameBootstrapper.BootstrapComplete:Connect(function(success, totalTime, state)
		if success then
			print("✅ [LoadingScreen] Client bootstrap complete.")
			loadingState.bootstrapComplete = true
			updateProgress(90) -- Mark bootstrap as 90% done
			updatePhase("WAITING_FOR_WORLD", "Client ready. Waiting for server...")
			checkCompletion()
		else
			-- Handle bootstrap errors (omitted for brevity)
		end
	end)

	-- 3. Start the client-side bootstrap process
	GameBootstrapper.StartBootstrapAsync(function(success, state)
		-- Callback logic now handled by the BootstrapComplete event
	end)
end

-- Start initialization
initialize()

return LoadingScreen
