-- Player View
-- UI component for player management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local BaseView = require(ReplicatedStorage.Framework.BaseView)

local PlayerView = BaseView.new()
PlayerView.Name = "PlayerView"

-- Constructor
function PlayerView.new()
	local self = setmetatable({}, PlayerView)
	
	self.Name = "PlayerView"
	self.Template = nil
	self.Components = {}
	self.Data = {}
	self.Visible = false
	self.PlayerService = nil
	
	return self
end

-- Initialize view
function PlayerView:Initialize()
	BaseView.Initialize(self)
	self:CreateTemplate()
	self:LoadComponents()
	self:LoadPlayerService()
	print("[PlayerView] View initialized")
end

-- Load player service
function PlayerView:LoadPlayerService()
	local ServiceContainer = require(ReplicatedStorage.Framework.ServiceContainer)
	local container = ServiceContainer.new()
	container:AutoWire()
	
	self.PlayerService = container:Resolve("PlayerService")
end

-- Create view template
function PlayerView:CreateTemplate()
	if not self.Template then
		self.Template = Instance.new("ScreenGui")
		self.Template.Name = self.Name
		self.Template.ResetOnSpawn = false
		self.Template.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		
		-- Main container
		local mainFrame = Instance.new("Frame")
		mainFrame.Name = "MainFrame"
		mainFrame.Size = UDim2.new(0, 400, 0, 600)
		mainFrame.Position = UDim2.new(0.5, -200, 0.5, -300)
		mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
		mainFrame.BorderSizePixel = 0
		mainFrame.Parent = self.Template
		
		-- Title
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Text = "Player Management"
		title.Size = UDim2.new(1, 0, 0, 50)
		title.Position = UDim2.new(0, 0, 0, 0)
		title.BackgroundTransparency = 1
		title.TextColor3 = Color3.new(1, 1, 1)
		title.Font = Enum.Font.SourceSansBold
		title.TextSize = 24
		title.Parent = mainFrame
		
		-- Content area
		local contentFrame = Instance.new("Frame")
		contentFrame.Name = "ContentFrame"
		contentFrame.Size = UDim2.new(1, 0, 1, -50)
		contentFrame.Position = UDim2.new(0, 0, 0, 50)
		contentFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
		contentFrame.BorderSizePixel = 0
		contentFrame.Parent = mainFrame
		
		self:AddComponent("MainFrame", mainFrame)
		self:AddComponent("Title", title)
		self:AddComponent("ContentFrame", contentFrame)
		
		print("[PlayerView] Template created")
	end
end

-- Load view components
function PlayerView:LoadComponents()
	local contentFrame = self:GetComponent("ContentFrame")
	if not contentFrame then
		return
	end
	
	-- Create tabs
	self:CreateTabs(contentFrame)
	
	-- Create player list
	self:CreatePlayerList(contentFrame)
	
	-- Create player form
	self:CreatePlayerForm(contentFrame)
	
	-- Create statistics
	self:CreateStatistics(contentFrame)
	
	print("[PlayerView] Components loaded")
end

-- Create tabs
function PlayerView:CreateTabs(parent)
	local tabsFrame = Instance.new("Frame")
	tabsFrame.Name = "TabsFrame"
	tabsFrame.Size = UDim2.new(1, 0, 0, 40)
	tabsFrame.Position = UDim2.new(0, 0, 0, 0)
	tabsFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	tabsFrame.BorderSizePixel = 0
	tabsFrame.Parent = parent
	
	-- Tab buttons
	local tabs = {
		{ name = "List", key = "list" },
		{ name = "Create", key = "create" },
		{ name = "Stats", key = "stats" }
	}
	
	for i, tab in ipairs(tabs) do
		local button = Instance.new("TextButton")
		button.Name = tab.key .. "Tab"
		button.Text = tab.name
		button.Size = UDim2.new(0, 120, 1, 0)
		button.Position = UDim2.new(0, (i - 1) * 120, 0, 0)
		button.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = 16
		button.Parent = tabsFrame
		
		button.MouseButton1Click:Connect(function()
			self:SwitchTab(tab.key)
		end)
		
		self:AddComponent(tab.key .. "Tab", button)
	end
	
	self:AddComponent("TabsFrame", tabsFrame)
end

-- Create player list
function PlayerView:CreatePlayerList(parent)
	local listFrame = Instance.new("Frame")
	listFrame.Name = "ListFrame"
	listFrame.Size = UDim2.new(1, 0, 1, -40)
	listFrame.Position = UDim2.new(0, 0, 0, 40)
	listFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	listFrame.BorderSizePixel = 0
	listFrame.Visible = true
	listFrame.Parent = parent
	
	-- Search box
	local searchBox = self:CreateInputField("Search players...", UDim2.new(0, 10, 0, 10), UDim2.new(0, 200, 0, 30), listFrame, function(text)
		self:SearchPlayers(text)
	end)
	searchBox.Name = "SearchBox"
	
	-- Refresh button
	local refreshButton = self:CreateButton("Refresh", UDim2.new(0, 220, 0, 10), UDim2.new(0, 100, 0, 30), listFrame, function()
		self:RefreshPlayerList()
	end)
	refreshButton.Name = "RefreshButton"
	
	-- Player list container
	local playerList = Instance.new("ScrollingFrame")
	playerList.Name = "PlayerList"
	playerList.Size = UDim2.new(1, -20, 1, -50)
	playerList.Position = UDim2.new(0, 10, 0, 50)
	playerList.BackgroundTransparency = 1
	playerList.ScrollBarThickness = 10
	playerList.Parent = listFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = playerList
	
	self:AddComponent("ListFrame", listFrame)
	self:AddComponent("SearchBox", searchBox)
	self:AddComponent("RefreshButton", refreshButton)
	self:AddComponent("PlayerList", playerList)
	self:AddComponent("ListLayout", listLayout)
end

-- Create player form
function PlayerView:CreatePlayerForm(parent)
	local formFrame = Instance.new("Frame")
	formFrame.Name = "FormFrame"
	formFrame.Size = UDim2.new(1, 0, 1, -40)
	formFrame.Position = UDim2.new(0, 0, 0, 40)
	formFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	formFrame.BorderSizePixel = 0
	formFrame.Visible = false
	formFrame.Parent = parent
	
	-- Form fields
	local fields = {
		{ name = "Username", key = "username", placeholder = "Enter username" },
		{ name = "Display Name", key = "displayName", placeholder = "Enter display name" },
		{ name = "Team", key = "team", placeholder = "Enter team name" }
	}
	
	for i, field in ipairs(fields) do
		local label = self:CreateLabel(field.name, UDim2.new(0, 10, 0, 10 + (i - 1) * 50), UDim2.new(0, 100, 0, 30), formFrame)
		label.Name = field.key .. "Label"
		
		local input = self:CreateInputField(field.placeholder, UDim2.new(0, 120, 0, 10 + (i - 1) * 50), UDim2.new(0, 200, 0, 30), formFrame)
		input.Name = field.key .. "Input"
	end
	
	-- Create button
	local createButton = self:CreateButton("Create Player", UDim2.new(0, 10, 0, 200), UDim2.new(0, 120, 0, 40), formFrame, function()
		self:CreatePlayer()
	end)
	createButton.Name = "CreateButton"
	
	-- Clear form button
	local clearButton = self:CreateButton("Clear Form", UDim2.new(0, 140, 0, 200), UDim2.new(0, 120, 0, 40), formFrame, function()
		self:ClearForm()
	end)
	clearButton.Name = "ClearButton"
	
	self:AddComponent("FormFrame", formFrame)
end

-- Create statistics
function PlayerView:CreateStatistics(parent)
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.new(1, 0, 1, -40)
	statsFrame.Position = UDim2.new(0, 0, 0, 40)
	statsFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	statsFrame.BorderSizePixel = 0
	statsFrame.Visible = false
	statsFrame.Parent = parent
	
	-- Statistics labels
	local stats = {
		{ name = "Total Players", key = "totalPlayers" },
		{ name = "Online Players", key = "onlinePlayers" },
		{ name = "Average Level", key = "avgLevel" },
		{ name = "Total Coins", key = "totalCoins" }
	}
	
	for i, stat in ipairs(stats) do
		local label = self:CreateLabel(stat.name .. ": ", UDim2.new(0, 10, 0, 10 + (i - 1) * 40), UDim2.new(0, 150, 0, 30), statsFrame)
		label.Name = stat.key .. "Label"
		
		local value = self:CreateLabel("0", UDim2.new(0, 170, 0, 10 + (i - 1) * 40), UDim2.new(0, 200, 0, 30), statsFrame)
		value.Name = stat.key .. "Value"
		value.TextColor3 = Color3.new(0.5, 0.8, 1)
	end
	
	-- Refresh stats button
	local refreshStatsButton = self:CreateButton("Refresh Stats", UDim2.new(0, 10, 0, 200), UDim2.new(0, 120, 0, 40), statsFrame, function()
		self:RefreshStatistics()
	end)
	refreshStatsButton.Name = "RefreshStatsButton"
	
	self:AddComponent("StatsFrame", statsFrame)
end

-- Switch tab
function PlayerView:SwitchTab(tabKey)
	-- Hide all frames
	self:GetComponent("ListFrame").Visible = false
	self:GetComponent("FormFrame").Visible = false
	self:GetComponent("StatsFrame").Visible = false
	
	-- Show selected frame
	local frame = self:GetComponent(tabKey:sub(1, 1):upper() .. tabKey:sub(2) .. "Frame")
	if frame then
		frame.Visible = true
	end
	
	-- Update tab button colors
	for _, tab in ipairs({"List", "Create", "Stats"}) do
		local button = self:GetComponent(tab:lower() .. "Tab")
		if button then
			if tab:lower() == tabKey then
				button.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
			else
				button.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
			end
		end
	end
end

-- Render view
function PlayerView:Render(data)
	self.Data = data or {}
	
	if self.Template then
		self:UpdateComponents()
		self:Show()
	end
end

-- Update components with data
function PlayerView:UpdateComponents()
	-- Update player list
	self:RefreshPlayerList()
	
	-- Update statistics
	self:RefreshStatistics()
end

-- Refresh player list
function PlayerView:RefreshPlayerList()
	if not self.PlayerService then
		return
	end
	
	local players = self.PlayerService:GetAllPlayers()
	local playerList = self:GetComponent("PlayerList")
	
	-- Clear existing items
	for _, item in pairs(playerList:GetChildren()) do
		if item:IsA("TextButton") then
			item:Destroy()
		end
	end
	
	-- Add players to list
	for _, player in ipairs(players) do
		local playerItem = Instance.new("TextButton")
		playerItem.Text = string.format("%s (Level %d) - %s", player.username, player.level, player.team)
		playerItem.Size = UDim2.new(1, 0, 0, 30)
		playerItem.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		playerItem.TextColor3 = Color3.new(1, 1, 1)
		playerItem.Font = Enum.Font.SourceSans
		playerItem.TextSize = 16
		playerItem.Parent = playerList
		
		playerItem.MouseButton1Click:Connect(function()
			self:ShowPlayerDetails(player)
		end)
	end
end

-- Search players
function PlayerView:SearchPlayers(query)
	if not self.PlayerService then
		return
	end
	
	local players = self.PlayerService:GetAllPlayers()
	local filteredPlayers = {}
	
	for _, player in ipairs(players) do
		if string.find(string.lower(player.username), string.lower(query)) or
		   string.find(string.lower(player.displayName), string.lower(query)) then
			table.insert(filteredPlayers, player)
		end
	end
	
	-- Update list with filtered results
	local playerList = self:GetComponent("PlayerList")
	
	-- Clear existing items
	for _, item in pairs(playerList:GetChildren()) do
		if item:IsA("TextButton") then
			item:Destroy()
		end
	end
	
	-- Add filtered players
	for _, player in ipairs(filteredPlayers) do
		local playerItem = Instance.new("TextButton")
		playerItem.Text = string.format("%s (Level %d) - %s", player.username, player.level, player.team)
		playerItem.Size = UDim2.new(1, 0, 0, 30)
		playerItem.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		playerItem.TextColor3 = Color3.new(1, 1, 1)
		playerItem.Font = Enum.Font.SourceSans
		playerItem.TextSize = 16
		playerItem.Parent = playerList
		
		playerItem.MouseButton1Click:Connect(function()
			self:ShowPlayerDetails(player)
		end)
	end
end

-- Show player details
function PlayerView:ShowPlayerDetails(player)
	-- This would show a detailed view of the player
	-- For now, just log the player data
	print("[PlayerView] Player details:", player.username, player.level, player.team)
end

-- Create player
function PlayerView:CreatePlayer()
	if not self.PlayerService then
		return
	end
	
	local usernameInput = self:GetComponent("usernameInput")
	local displayNameInput = self:GetComponent("displayNameInput")
	local teamInput = self:GetComponent("teamInput")
	
	if not usernameInput or not displayNameInput or not teamInput then
		return
	end
	
	local data = {
		username = usernameInput.Text,
		displayName = displayNameInput.Text,
		team = teamInput.Text
	}
	
	local player, errors = self.PlayerService:CreatePlayer(data)
	
	if player then
		self:ShowMessage("Player created successfully!", "success")
		self:ClearForm()
		self:RefreshPlayerList()
	else
		self:ShowMessage("Error creating player: " .. table.concat(errors, ", "), "error")
	end
end

-- Clear form
function PlayerView:ClearForm()
	local usernameInput = self:GetComponent("usernameInput")
	local displayNameInput = self:GetComponent("displayNameInput")
	local teamInput = self:GetComponent("teamInput")
	
	if usernameInput then usernameInput.Text = "" end
	if displayNameInput then displayNameInput.Text = "" end
	if teamInput then teamInput.Text = "" end
end

-- Refresh statistics
function PlayerView:RefreshStatistics()
	if not self.PlayerService then
		return
	end
	
	local stats = self.PlayerService:GetStatistics()
	local onlineCount = self.PlayerService:GetOnlinePlayersCount()
	
	-- Update labels
	local totalPlayersLabel = self:GetComponent("totalPlayersValue")
	local onlinePlayersLabel = self:GetComponent("onlinePlayersValue")
	local avgLevelLabel = self:GetComponent("avgLevelValue")
	local totalCoinsLabel = self:GetComponent("totalCoinsValue")
	
	if totalPlayersLabel then totalPlayersLabel.Text = tostring(stats.totalPlayers) end
	if onlinePlayersLabel then onlinePlayersLabel.Text = tostring(onlineCount) end
	if avgLevelLabel then avgLevelLabel.Text = string.format("%.2f", stats.averageLevel) end
	if totalCoinsLabel then totalCoinsLabel.Text = tostring(stats.totalCoins) end
end

-- Show message
function PlayerView:ShowMessage(message, type)
	-- Create temporary message label
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Text = message
	messageLabel.Size = UDim2.new(0, 300, 0, 40)
	messageLabel.Position = UDim2.new(0.5, -150, 0.9, 0)
	messageLabel.BackgroundTransparency = 0.8
	messageLabel.BackgroundColor3 = type == "error" and Color3.new(0.8, 0.2, 0.2) or Color3.new(0.2, 0.8, 0.2)
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.Font = Enum.Font.SourceSansBold
	messageLabel.TextSize = 18
	messageLabel.Parent = self.Template
	
	-- Auto-remove after 3 seconds
	delay(3, function()
		messageLabel:Destroy()
	end)
end

-- Toggle view visibility
function PlayerView:Toggle()
	if self.Visible then
		self:Hide()
	else
		self:Show()
	end
end

-- Destroy view
function PlayerView:Destroy()
	self:Clear()
	if self.Template then
		self.Template:Destroy()
		self.Template = nil
	end
	print("[PlayerView] View destroyed")
end

return PlayerView
