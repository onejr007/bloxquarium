--[[
	LoadingScreen.client.luau
	
	🎮 PROFESSIONAL LOADING SCREEN 🎮
	
	Loading screen UI yang profesional untuk menampilkan progress startup game
	Terintegrasi dengan GameBootstrapper untuk real-time progress updates
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules to load
local GameBootstrapper = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameBootstrapper"))

local LoadingScreen = {}

-- UI Elements
local screenGui
local mainFrame
local backgroundFrame
local logoFrame
local titleLabel
local subtitleLabel
local progressFrame
local progressBar
local progressFill
local progressText
local phaseLabel
local statusLabel
local errorFrame
local errorList
local skipButton
local versionLabel

-- Loading state
local loadingState = {
	isVisible = false,
	currentProgress = 0,
	targetProgress = 0,
	currentPhase = "INITIALIZING",
	errors = {},
	canSkip = false
}

-- Animation tweens
local progressTween
local fadeInTween
local fadeOutTween

-- Create professional loading UI
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
	versionLabel.Text = "v1.0.0 - Professional Edition"
	versionLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	versionLabel.TextSize = 12
	versionLabel.Font = Enum.Font.Gotham
	versionLabel.Parent = backgroundFrame
	
	-- Error Frame (initially hidden)
	errorFrame = Instance.new("Frame")
	errorFrame.Name = "ErrorFrame"
	errorFrame.Size = UDim2.new(0, 500, 0, 200)
	errorFrame.Position = UDim2.new(0.5, -250, 0.5, 100)
	errorFrame.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
	errorFrame.BorderSizePixel = 0
	errorFrame.Visible = false
	errorFrame.Parent = backgroundFrame
	
	-- Error Frame Corner
	local errorCorner = Instance.new("UICorner")
	errorCorner.CornerRadius = UDim.new(0, 8)
	errorCorner.Parent = errorFrame
	
	-- Error List
	errorList = Instance.new("ScrollingFrame")
	errorList.Name = "ErrorList"
	errorList.Size = UDim2.new(1, -20, 1, -20)
	errorList.Position = UDim2.new(0, 10, 0, 10)
	errorList.BackgroundTransparency = 1
	errorList.ScrollBarThickness = 6
	errorList.Parent = errorFrame
	
	-- Skip Button (for debugging)
	skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Size = UDim2.new(0, 100, 0, 30)
	skipButton.Position = UDim2.new(1, -120, 1, -50)
	skipButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	skipButton.BorderSizePixel = 0
	skipButton.Text = "Skip"
	skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	skipButton.Font = Enum.Font.Gotham
	skipButton.Visible = false
	skipButton.Parent = backgroundFrame
	
	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, 4)
	skipCorner.Parent = skipButton
end

-- Update progress bar with smooth animation
local function updateProgress(targetPercent)
	loadingState.targetProgress = targetPercent
	
	if progressTween then
		progressTween:Cancel()
	end
	
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	progressTween = TweenService:Create(progressFill, tweenInfo, {
		Size = UDim2.new(targetPercent / 100, 0, 1, 0)
	})
	
	progressTween:Play()
	progressText.Text = string.format("%d%%", targetPercent)
end

-- Update phase display
local function updatePhase(phase, message)
	loadingState.currentPhase = phase
	
	local phaseNames = {
		INITIALIZING = "🔧 Initializing Systems",
		VALIDATING = "🔍 Validating Components", 
		LOADING_ASSETS = "📦 Loading Assets",
		PREPARING_SYSTEMS = "⚙️ Preparing Systems",
		FINALIZING = "✨ Finalizing Setup",
		READY = "✅ Ready to Play",
		ERROR = "❌ Error Occurred"
	}
	
	phaseLabel.Text = phaseNames[phase] or phase
	if message then
		statusLabel.Text = message
	end
	
	-- Color coding for different phases
	local phaseColors = {
		INITIALIZING = Color3.fromRGB(255, 200, 100),
		VALIDATING = Color3.fromRGB(100, 200, 255),
		LOADING_ASSETS = Color3.fromRGB(150, 255, 150),
		PREPARING_SYSTEMS = Color3.fromRGB(255, 150, 255),
		FINALIZING = Color3.fromRGB(255, 255, 100),
		READY = Color3.fromRGB(100, 255, 100),
		ERROR = Color3.fromRGB(255, 100, 100)
	}
	
	phaseLabel.TextColor3 = phaseColors[phase] or Color3.fromRGB(200, 200, 200)
end

-- Show error information
local function showErrors(errors)
	if #errors == 0 then return end
	
	errorFrame.Visible = true
	
	-- Clear existing error labels
	for _, child in pairs(errorList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	
	-- Add error labels
	for i, error in ipairs(errors) do
		local errorLabel = Instance.new("TextLabel")
		errorLabel.Name = "Error" .. i
		errorLabel.Size = UDim2.new(1, -10, 0, 25)
		errorLabel.Position = UDim2.new(0, 5, 0, (i-1) * 30)
		errorLabel.BackgroundTransparency = 1
		errorLabel.Text = string.format("❌ %s", error.message)
		errorLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
		errorLabel.TextSize = 14
		errorLabel.Font = Enum.Font.Gotham
		errorLabel.TextXAlignment = Enum.TextXAlignment.Left
		errorLabel.Parent = errorList
	end
	
	errorList.CanvasSize = UDim2.new(0, 0, 0, #errors * 30)
end

-- Show loading screen
function LoadingScreen.Show()
	if loadingState.isVisible then return end
	
	loadingState.isVisible = true
	screenGui.Enabled = true
	
	-- Fade in animation
	backgroundFrame.BackgroundTransparency = 1
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
	
	local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	fadeInTween = TweenService:Create(backgroundFrame, fadeInfo, {
		BackgroundTransparency = 0
	})
	
	local slideInfo = TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local slideTween = TweenService:Create(mainFrame, slideInfo, {
		Position = UDim2.new(0.5, -300, 0.5, -200)
	})
	
	fadeInTween:Play()
	slideTween:Play()
end

-- Hide loading screen
function LoadingScreen.Hide()
	if not loadingState.isVisible then return end
	
	loadingState.isVisible = false
	
	-- Fade out animation
	local fadeInfo = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	fadeOutTween = TweenService:Create(backgroundFrame, fadeInfo, {
		BackgroundTransparency = 1
	})
	
	local slideInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local slideTween = TweenService:Create(mainFrame, slideInfo, {
		Position = UDim2.new(0.5, -300, 0.5, -100)
	})
	
	fadeOutTween:Play()
	slideTween:Play()
	
	fadeOutTween.Completed:Connect(function()
		screenGui.Enabled = false
	end)
end

-- Initialize loading screen
local function initialize()
	createLoadingUI()
	
	-- Connect to GameBootstrapper events
	GameBootstrapper.PhaseChanged:Connect(function(phase, message)
		updatePhase(phase, message)
	end)
	
	GameBootstrapper.ProgressUpdated:Connect(function(step, total, percentage, message)
		updateProgress(percentage)
		if message then
			statusLabel.Text = message
		end
	end)
	
	GameBootstrapper.BootstrapComplete:Connect(function(success, totalTime, state)
		if success then
			updateProgress(100)
			updatePhase("READY", string.format("Game ready! (%.2fs)", totalTime))
			
			-- Hide loading screen after a short delay
			wait(2)
			LoadingScreen.Hide()
		else
			updatePhase("ERROR", "Bootstrap failed - check errors below")
			showErrors(state.errors)
			skipButton.Visible = true
		end
	end)
	
	GameBootstrapper.ErrorOccurred:Connect(function(errorType, message, details)
		table.insert(loadingState.errors, {message = message, details = details})
		
		if errorType == "ERROR" then
			showErrors(loadingState.errors)
		end
	end)
	
	-- Skip button functionality (for debugging)
	skipButton.MouseButton1Click:Connect(function()
		LoadingScreen.Hide()
	end)
	
	-- Show loading screen immediately
	LoadingScreen.Show()
	
	-- Start bootstrap process
	GameBootstrapper.StartBootstrapAsync(function(success, state)
		print("🎮 [LoadingScreen] Bootstrap completed:", success and "SUCCESS" or "FAILED")
	end)
end

-- Start initialization
initialize()

return LoadingScreen