-- Base Controller Class
-- Provides common functionality for all controllers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseController = {}
BaseController.__index = BaseController

-- Constructor
function BaseController.new()
	local self = setmetatable({}, BaseController)
	
	-- Framework reference
	self.Framework = require(ReplicatedStorage.Framework)
	
	-- Controller properties
	self.Name = "BaseController"
	self.Models = {}
	self.Views = {}
	self.Routes = {}
	
	return self
end

-- Initialize controller
function BaseController:Initialize()
	print("[Controller] " .. self.Name .. " initialized")
	self:LoadModels()
	self:LoadViews()
	self:RegisterRoutes()
end

-- Load required models
function BaseController:LoadModels()
	-- Override in child classes
end

-- Load required views
function BaseController:LoadViews()
	-- Override in child classes
end

-- Register routes
function BaseController:RegisterRoutes()
	-- Override in child classes
end

-- Get model instance
function BaseController:GetModel(modelName)
	local model = self.Framework:Get("Model", modelName)
	if model then
		return model
	else
		warn("[Controller] Model not found: " .. modelName)
		return nil
	end
end

-- Get view instance
function BaseController:GetView(viewName)
	local view = self.Framework:Get("View", viewName)
	if view then
		return view
	else
		warn("[Controller] View not found: " .. viewName)
		return nil
	end
end

-- Get library instance
function BaseController:GetLibrary(libName)
	local lib = self.Framework:Get("Library", libName)
	if lib then
		return lib
	else
		warn("[Controller] Library not found: " .. libName)
		return nil
	end
end

-- Get helper instance
function BaseController:GetHelper(helperName)
	local helper = self.Framework:Get("Helper", helperName)
	if helper then
		return helper
	else
		warn("[Controller] Helper not found: " .. helperName)
		return nil
	end
end

-- Get cached asset
function BaseController:GetCachedAsset(assetName)
	local asset = self.Framework:Get("Cached", assetName)
	if asset then
		return asset
	else
		warn("[Controller] Cached asset not found: " .. assetName)
		return nil
	end
end

-- Send response to client
function BaseController:SendResponse(player, action, data)
	local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvent then
		local event = remoteEvent:FindFirstChild(action)
		if event then
			event:FireClient(player, data)
		else
			warn("[Controller] RemoteEvent not found: " .. action)
		end
	else
		warn("[Controller] RemoteEvents folder not found")
	end
end

-- Broadcast to all clients
function BaseController:Broadcast(action, data)
	local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvent then
		local event = remoteEvent:FindFirstChild(action)
		if event then
			event:FireAllClients(data)
		else
			warn("[Controller] RemoteEvent not found: " .. action)
		end
	else
		warn("[Controller] RemoteEvents folder not found")
	end
end

-- Log message
function BaseController:Log(message, level)
	level = level or "INFO"
	print("[" .. level .. "] [" .. self.Name .. "] " .. message)
end

-- Error handling
function BaseController:HandleError(errorMsg, context)
	self:Log("ERROR: " .. errorMsg .. " (Context: " .. context .. ")", "ERROR")
	warn("[Controller] " .. self.Name .. " error: " .. errorMsg)
end

-- Validate input
function BaseController:ValidateInput(input, rules)
	local errors = {}
	
	for field, rule in pairs(rules) do
		if not input[field] then
			table.insert(errors, field .. " is required")
		elseif rule.type == "string" and type(input[field]) ~= "string" then
			table.insert(errors, field .. " must be a string")
		elseif rule.type == "number" and type(input[field]) ~= "number" then
			table.insert(errors, field .. " must be a number")
		elseif rule.min and #input[field] < rule.min then
			table.insert(errors, field .. " must be at least " .. rule.min .. " characters")
		elseif rule.max and #input[field] > rule.max then
			table.insert(errors, field .. " must be at most " .. rule.max .. " characters")
		end
	end
	
	return #errors == 0, errors
end

-- Get player data
function BaseController:GetPlayerData(player)
	local playerData = {}
	
	-- Get player stats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		for _, stat in pairs(leaderstats:GetChildren()) do
			playerData[stat.Name] = stat.Value
		end
	end
	
	-- Get player inventory
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		playerData.Inventory = {}
		for _, item in pairs(backpack:GetChildren()) do
			table.insert(playerData.Inventory, item.Name)
		end
	end
	
	return playerData
end

-- Update player data
function BaseController:UpdatePlayerData(player, data)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	
	for key, value in pairs(data) do
		local stat = leaderstats:FindFirstChild(key)
		if not stat then
			stat = Instance.new("IntValue")
			stat.Name = key
			stat.Parent = leaderstats
		end
		stat.Value = value
	end
end

return BaseController
