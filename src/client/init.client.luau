-- Client Initialization
-- Main entry point for the client-side MVC framework

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- Load the framework
local Framework = require(ReplicatedStorage.Framework)

-- Initialize the framework
local frameworkInstance = Framework:Initialize()

-- Setup UI
local function setupUI()
	print("[Client] Setting up UI...")
	
	-- Create main UI container
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MVC_Framework_UI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")
	
	-- Create title
	local title = Instance.new("TextLabel")
	title.Text = "MVC Framework Client"
	title.Size = UDim2.new(0, 300, 0, 50)
	title.Position = UDim2.new(0.5, -150, 0.1, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 24
	title.Parent = screenGui
	
	-- Create status indicator
	local status = Instance.new("TextLabel")
	status.Text = "Status: Connecting..."
	status.Size = UDim2.new(0, 200, 0, 30)
	status.Position = UDim2.new(0.5, -100, 0.2, 0)
	status.BackgroundTransparency = 1
	status.TextColor3 = Color3.new(0.5, 0.5, 0.5)
	status.Font = Enum.Font.SourceSans
	status.TextSize = 18
	status.Parent = screenGui
	
	-- Create test buttons
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Size = UDim2.new(0, 400, 0, 200)
	buttonContainer.Position = UDim2.new(0.5, -200, 0.4, 0)
	buttonContainer.BackgroundTransparency = 0.8
	buttonContainer.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	buttonContainer.BorderSizePixel = 0
	buttonContainer.Parent = screenGui
	
	-- Test buttons layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.Parent = buttonContainer
	
	-- Test API button
	local testButton = Instance.new("TextButton")
	testButton.Text = "Test API: Get Players"
	testButton.Size = UDim2.new(1, 0, 0, 40)
	testButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
	testButton.TextColor3 = Color3.new(1, 1, 1)
	testButton.Font = Enum.Font.SourceSansBold
	testButton.TextSize = 16
	testButton.Parent = buttonContainer
	
	testButton.MouseButton1Click:Connect(function()
		testButton.Text = "Loading..."
		testButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
		
		-- Send request to server
		local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remoteEvents then
			local routeRequest = remoteEvents:FindFirstChild("RouteRequest")
			if routeRequest then
				routeRequest:FireServer("GET /api/players", {})
			end
		end
	end)
	
	-- Test create player button
	local createButton = Instance.new("TextButton")
	createButton.Text = "Test API: Create Player"
	createButton.Size = UDim2.new(1, 0, 0, 40)
	createButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
	createButton.TextColor3 = Color3.new(1, 1, 1)
	createButton.Font = Enum.Font.SourceSansBold
	createButton.TextSize = 16
	createButton.Parent = buttonContainer
	
	createButton.MouseButton1Click:Connect(function()
		createButton.Text = "Creating..."
		createButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
		
		-- Send request to server
		local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remoteEvents then
			local routeRequest = remoteEvents:FindFirstChild("RouteRequest")
			if routeRequest then
				routeRequest:FireServer("POST /api/players", {
					username = "testuser" .. math.random(1000, 9999),
					displayName = "Test User",
					team = "Test Team"
				})
			end
		end
	end)
	
	-- Test statistics button
	local statsButton = Instance.new("TextButton")
	statsButton.Text = "Test API: Get Statistics"
	statsButton.Size = UDim2.new(1, 0, 0, 40)
	statsButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
	statsButton.TextColor3 = Color3.new(1, 1, 1)
	statsButton.Font = Enum.Font.SourceSansBold
	statsButton.TextSize = 16
	statsButton.Parent = buttonContainer
	
	statsButton.MouseButton1Click:Connect(function()
		statsButton.Text = "Loading..."
		statsButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
		
		-- Send request to server
		local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remoteEvents then
			local routeRequest = remoteEvents:FindFirstChild("RouteRequest")
			if routeRequest then
				routeRequest:FireServer("GET /api/players", {})
			end
		end
	end)
	
	return screenGui
end

-- Setup event listeners
local function setupEventListeners()
	print("[Client] Setting up event listeners...")
	
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		-- Framework ready event
		local readyEvent = remoteEvents:FindFirstChild("FrameworkReady")
		if readyEvent then
			readyEvent.OnClientEvent:Connect(function(data)
				print("[Client] Framework ready: " .. data.framework .. " v" .. data.version)
				
				-- Update UI status
				local screenGui = player.PlayerGui:FindFirstChild("MVC_Framework_UI")
				if screenGui then
					local status = screenGui:FindFirstChild("Status")
					if status then
						status.Text = "Status: Ready"
						status.TextColor3 = Color3.new(0.2, 0.8, 0.2)
					end
				end
			end)
		end
		
		-- Route response event
		local responseEvent = remoteEvents:FindFirstChild("RouteResponse")
		if responseEvent then
			responseEvent.OnClientEvent:Connect(function(data)
				print("[Client] Route response received")
				print("[Client] Response: " .. game:GetService("HttpService"):JSONEncode(data))
				
				-- Update button text back to normal
				local screenGui = player.PlayerGui:FindFirstChild("MVC_Framework_UI")
				if screenGui then
					local testButton = screenGui:FindFirstChild("TestButton")
					local createButton = screenGui:FindFirstChild("CreateButton")
					local statsButton = screenGui:FindFirstChild("StatsButton")
					
					if testButton then testButton.Text = "Test API: Get Players" end
					if createButton then createButton.Text = "Test API: Create Player" end
					if statsButton then statsButton.Text = "Test API: Get Statistics" end
				end
			end)
		end
		
		-- Route error event
		local errorEvent = remoteEvents:FindFirstChild("RouteError")
		if errorEvent then
			errorEvent.OnClientEvent:Connect(function(errorMessage)
				print("[Client] Route error: " .. errorMessage)
				
				-- Update button text back to normal
				local screenGui = player.PlayerGui:FindFirstChild("MVC_Framework_UI")
				if screenGui then
					local testButton = screenGui:FindFirstChild("TestButton")
					local createButton = screenGui:FindFirstChild("CreateButton")
					local statsButton = screenGui:FindFirstChild("StatsButton")
					
					if testButton then testButton.Text = "Test API: Get Players" end
					if createButton then createButton.Text = "Test API: Create Player" end
					if statsButton then statsButton.Text = "Test API: Get Statistics" end
				end
			end)
		end
	end
end

-- Initialize client
local function initializeClient()
	print("[Client] Initializing MVC Framework client...")
	
	-- Setup UI
	local ui = setupUI()
	
	-- Setup event listeners
	setupEventListeners()
	
	-- Send ready signal to server
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local readyEvent = remoteEvents:FindFirstChild("ClientReady")
		if readyEvent then
			readyEvent:FireServer()
		end
	end
	
	print("[Client] MVC Framework client initialized successfully!")
end

-- Start initialization
initializeClient()