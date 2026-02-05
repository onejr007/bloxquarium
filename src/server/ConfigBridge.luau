-- Server-Side Configuration Bridge v1.0
-- Professional server-side configuration handler that manages client-safe vs server-only separation
-- Ensures secure configuration distribution and validation

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigManager = require(ReplicatedStorage.Shared.ConfigManager)

local ConfigBridge = {}
ConfigBridge.__index = ConfigBridge

-- Configuration bridge state
local configBridgeState = {
	clientSafeConfigs = {},
	sharedConfigs = {},
	serverOnlyConfigs = {},
	configSubscriptions = {},
	configVersion = "1.0.0"
}

-- Configuration bridge configuration
local BRIDGE_CONFIG = {
	MAX_CONFIG_REQUESTS_PER_MINUTE = 100,
	CONFIG_CACHE_TIMEOUT = 300, -- 5 minutes
	ENABLE_CONFIG_VALIDATION = true,
	ENABLE_CONFIG_AUDITING = true
}

-- Initialize the Configuration Bridge
function ConfigBridge.new()
	local self = setmetatable({}, ConfigBridge)
	
	-- Setup configuration bridge handlers
	self:_setupConfigBridgeHandlers()
	
	-- Setup configuration monitoring
	self:_setupConfigBridgeMonitoring()
	
	-- Initialize configuration cache
	self:_initializeConfigCache()
	
	print("[Config Bridge] Server-side configuration bridge initialized")
	
	return self
end

-- Setup configuration bridge handlers
function ConfigBridge:_setupConfigBridgeHandlers()
	-- Handle client configuration requests
	local clientConfigRequestEvent = ReplicatedStorage:FindFirstChild("ClientConfigRequest")
	if clientConfigRequestEvent then
		clientConfigRequestEvent.OnServerEvent:Connect(function(player, requestType, configPath)
			self:_handleClientConfigRequest(player, requestType, configPath)
		end)
		print("[Config Bridge] Client configuration request handler registered")
	else
		warn("[Config Bridge] ClientConfigRequest event not found!")
	end
	
	-- Handle configuration updates
	local configUpdateEvent = ReplicatedStorage:FindFirstChild("ConfigUpdate")
	if configUpdateEvent then
		configUpdateEvent.OnServerEvent:Connect(function(player, category, configPath, value)
			self:_handleConfigUpdate(player, category, configPath, value)
		end)
		print("[Config Bridge] Configuration update handler registered")
	else
		warn("[Config Bridge] ConfigUpdate event not found!")
	end
end

-- Setup configuration bridge monitoring
function ConfigBridge:_setupConfigBridgeMonitoring()
	-- Monitor configuration requests
	spawn(function()
		while true do
			task.wait(60) -- Log metrics every minute
			self:_logConfigBridgeMetrics()
		end
	end)
	
	-- Cleanup old subscriptions
	spawn(function()
		while true do
			task.wait(300) -- Cleanup every 5 minutes
			self:_cleanupOldSubscriptions()
		end
	end)
end

-- Initialize configuration cache
function ConfigBridge:_initializeConfigCache()
	-- Cache client-safe configurations
	configBridgeState.clientSafeConfigs = ConfigManager.getAllClientSafeConfigs()
	
	-- Cache shared configurations
	configBridgeState.sharedConfigs = ConfigManager.getAllSharedConfigs()
	
	-- Cache server-only configurations (for server-side access)
	configBridgeState.serverOnlyConfigs = ConfigManager.getConfig("SERVER_ONLY", "")
	
	print("[Config Bridge] Configuration cache initialized")
end

-- Handle client configuration request
function ConfigBridge:_handleClientConfigRequest(player, requestType, configPath)
	local playerId = player.UserId
	
	-- Rate limiting check
	if not self:_checkRateLimit(playerId) then
		self:_logConfigEvent(playerId, "RATE_LIMIT_EXCEEDED", {
			requestType = requestType,
			configPath = configPath
		})
		return false, "Rate limit exceeded"
	end
	
	-- Validate request type
	if requestType == "GET_CLIENT_SAFE" then
		return self:_handleGetClientSafeConfig(player, configPath)
	elseif requestType == "GET_SHARED" then
		return self:_handleGetSharedConfig(player, configPath)
	elseif requestType == "GET_SCHEMA" then
		return self:_handleGetConfigSchema(player)
	elseif requestType == "SUBSCRIBE" then
		return self:_handleConfigSubscription(player, configPath)
	else
		self:_logConfigEvent(playerId, "INVALID_REQUEST_TYPE", {
			requestType = requestType
		})
		return false, "Invalid request type"
	end
end

-- Handle getting client-safe configuration
function ConfigBridge:_handleGetClientSafeConfig(player, configPath)
	local playerId = player.UserId
	
	if configPath then
		-- Get specific configuration
		local config = ConfigManager.getConfig("CLIENT_SAFE", configPath)
		if config then
			self:_logConfigEvent(playerId, "CLIENT_SAFE_CONFIG_ACCESSED", {
				configPath = configPath
			})
			return true, config
		else
			self:_logConfigEvent(playerId, "CLIENT_SAFE_CONFIG_NOT_FOUND", {
				configPath = configPath
			})
			return false, "Configuration not found"
		end
	else
		-- Get all client-safe configurations
		local configs = ConfigManager.getAllClientSafeConfigs()
		self:_logConfigEvent(playerId, "ALL_CLIENT_SAFE_CONFIGS_ACCESSED", {})
		return true, configs
	end
end

-- Handle getting shared configuration
function ConfigBridge:_handleGetSharedConfig(player, configPath)
	local playerId = player.UserId
	
	if configPath then
		-- Get specific shared configuration
		local config = ConfigManager.getConfig("SHARED", configPath)
		if config then
			-- Validate configuration on server side
			local isValid, validationResults = ConfigManager.validateConfiguration()
			if isValid then
				self:_logConfigEvent(playerId, "SHARED_CONFIG_ACCESSED", {
					configPath = configPath
				})
				return true, config
			else
				self:_logConfigEvent(playerId, "SHARED_CONFIG_INVALID", {
					configPath = configPath,
					validationErrors = validationResults.errors
				})
				return false, "Configuration validation failed"
			end
		else
			self:_logConfigEvent(playerId, "SHARED_CONFIG_NOT_FOUND", {
				configPath = configPath
			})
			return false, "Configuration not found"
		end
	else
		-- Get all shared configurations
		local configs = ConfigManager.getAllSharedConfigs()
		self:_logConfigEvent(playerId, "ALL_SHARED_CONFIGS_ACCESSED", {})
		return true, configs
	end
end

-- Handle getting configuration schema
function ConfigBridge:_handleGetConfigSchema(player)
	local playerId = player.UserId
	
	local schema = ConfigManager.getConfigSchema()
	self:_logConfigEvent(playerId, "CONFIG_SCHEMA_ACCESSED", {
		version = schema.version
	})
	
	return true, schema
end

-- Handle configuration subscription
function ConfigBridge:_handleConfigSubscription(player, configPath)
	local playerId = player.UserId
	
	-- Validate subscription path
	if not configPath or configPath == "" then
		return false, "Invalid subscription path"
	end
	
	-- Check if path is client-safe or shared
	local isClientSafe = self:_isClientSafePath(configPath)
	local isShared = self:_isSharedPath(configPath)
	
	if not isClientSafe and not isShared then
		self:_logConfigEvent(playerId, "SUBSCRIPTION_DENIED", {
			configPath = configPath,
			reason = "Not client-safe or shared"
		})
		return false, "Cannot subscribe to server-only configuration"
	end
	
	-- Add subscription
	if not configBridgeState.configSubscriptions[playerId] then
		configBridgeState.configSubscriptions[playerId] = {}
	end
	
	configBridgeState.configSubscriptions[playerId][configPath] = {
		subscribedAt = tick(),
		lastUpdated = tick()
	}
	
	self:_logConfigEvent(playerId, "CONFIG_SUBSCRIPTION_CREATED", {
		configPath = configPath
	})
	
	return true, "Subscription created successfully"
end

-- Handle configuration update
function ConfigBridge:_handleConfigUpdate(player, category, configPath, value)
	local playerId = player.UserId
	
	-- Only allow server-side configuration updates
	if category == "SERVER_ONLY" then
		self:_logConfigEvent(playerId, "SERVER_ONLY_UPDATE_ATTEMPTED", {
			configPath = configPath
		})
		return false, "Cannot update server-only configuration from client"
	end
	
	-- Validate configuration update
	local isValid, validationMessage = ConfigManager.setConfig(category, configPath, value)
	if isValid then
		-- Update cache
		self:_updateConfigCache(category, configPath, value)
		
		-- Notify subscribers
		self:_notifyConfigSubscribers(category, configPath, value)
		
		self:_logConfigEvent(playerId, "CONFIG_UPDATED", {
			category = category,
			configPath = configPath,
			value = value
		})
		
		return true, "Configuration updated successfully"
	else
		self:_logConfigEvent(playerId, "CONFIG_UPDATE_FAILED", {
			category = category,
			configPath = configPath,
			error = validationMessage
		})
		return false, validationMessage
	end
end

-- Check if configuration path is client-safe
function ConfigBridge:_isClientSafePath(configPath)
	local clientSafeConfigs = ConfigManager.getAllClientSafeConfigs()
	return self:_checkConfigPathExists(clientSafeConfigs, configPath)
end

-- Check if configuration path is shared
function ConfigBridge:_isSharedPath(configPath)
	local sharedConfigs = ConfigManager.getAllSharedConfigs()
	return self:_checkConfigPathExists(sharedConfigs, configPath)
end

-- Check if configuration path exists in config table
function ConfigBridge:_checkConfigPathExists(configTable, configPath)
	local current = configTable
	
	for part in string.gmatch(configPath, "[^%.]+") do
		if current[part] ~= nil then
			current = current[part]
		else
			return false
		end
	end
	
	return true
end

-- Check rate limiting
function ConfigBridge:_checkRateLimit(playerId)
	-- Simple rate limiting implementation
	-- In a real system, you would track requests per player and enforce limits
	return true
end

-- Update configuration cache
function ConfigBridge:_updateConfigCache(category, configPath, value)
	if category == "CLIENT_SAFE" then
		-- Update client-safe cache
		local current = configBridgeState.clientSafeConfigs
		local pathParts = {}
		
		for part in string.gmatch(configPath, "[^%.]+") do
			table.insert(pathParts, part)
		end
		
		for i = 1, #pathParts - 1 do
			if current[pathParts[i]] == nil then
				return
			end
			current = current[pathParts[i]]
		end
		
		current[pathParts[#pathParts]] = value
	elseif category == "SHARED" then
		-- Update shared cache
		local current = configBridgeState.sharedConfigs
		local pathParts = {}
		
		for part in string.gmatch(configPath, "[^%.]+") do
			table.insert(pathParts, part)
		end
		
		for i = 1, #pathParts - 1 do
			if current[pathParts[i]] == nil then
				return
			end
			current = current[pathParts[i]]
		end
		
		current[pathParts[#pathParts]] = value
	end
end

-- Notify configuration subscribers
function ConfigBridge:_notifyConfigSubscribers(category, configPath, newValue)
	local notificationEvent = ReplicatedStorage:FindFirstChild("ConfigUpdateNotification")
	if not notificationEvent then
		return
	end
	
	-- Find all players subscribed to this configuration
	for playerId, subscriptions in pairs(configBridgeState.configSubscriptions) do
		for subPath, subscription in pairs(subscriptions) do
			-- Check if subscription matches the updated path
			if subPath == configPath or string.find(subPath, "^" .. configPath .. "%.") then
				-- Get the player
				local player = game:GetService("Players"):GetPlayerByUserId(playerId)
				if player then
					-- Get updated configuration
					local updatedConfig = ConfigManager.getConfig(category, configPath)
					if updatedConfig then
						notificationEvent:FireClient(player, category, configPath, updatedConfig)
					end
				end
			end
		end
	end
end

-- Log configuration event
function ConfigBridge:_logConfigEvent(playerId, eventType, details)
	if not BRIDGE_CONFIG.ENABLE_CONFIG_AUDITING then
		return
	end
	
	-- This would typically go to a logging service
	-- For now, just print with security prefix
	print(string.format(
		"[Config Bridge] Player %d: %s - %s",
		playerId, eventType, game:GetService("HttpService"):JSONEncode(details)
	))
end

-- Log configuration bridge metrics
function ConfigBridge:_logConfigBridgeMetrics()
	local totalSubscriptions = 0
	for _, subscriptions in pairs(configBridgeState.configSubscriptions) do
		totalSubscriptions = totalSubscriptions + #table.keys(subscriptions)
	end
	
	print(string.format(
		"[Config Bridge Metrics] Client-Safe Configs: %d | Shared Configs: %d | Subscriptions: %d | Version: %s",
		#table.keys(configBridgeState.clientSafeConfigs),
		#table.keys(configBridgeState.sharedConfigs),
		totalSubscriptions,
		configBridgeState.configVersion
	))
end

-- Cleanup old subscriptions
function ConfigBridge:_cleanupOldSubscriptions()
	local currentTime = tick()
	local timeout = 1800 -- 30 minutes
	
	for playerId, subscriptions in pairs(configBridgeState.configSubscriptions) do
		local player = game:GetService("Players"):GetPlayerByUserId(playerId)
		if not player or (currentTime - player.LastLoginTime) > timeout then
			configBridgeState.configSubscriptions[playerId] = nil
		end
	end
end

-- Get configuration bridge statistics
function ConfigBridge:getConfigBridgeStats()
	local stats = {
		clientSafeConfigs = #table.keys(configBridgeState.clientSafeConfigs),
		sharedConfigs = #table.keys(configBridgeState.sharedConfigs),
		serverOnlyConfigs = #table.keys(configBridgeState.serverOnlyConfigs),
		totalSubscriptions = 0,
		activeSubscriptions = 0,
		configVersion = configBridgeState.configVersion
	}
	
	-- Count subscriptions
	for _, subscriptions in pairs(configBridgeState.configSubscriptions) do
		stats.totalSubscriptions = stats.totalSubscriptions + #table.keys(subscriptions)
		
		-- Count active subscriptions (players still connected)
		for _ in pairs(subscriptions) do
			local player = game:GetService("Players"):GetPlayerByUserId(_)
			if player then
				stats.activeSubscriptions = stats.activeSubscriptions + 1
			end
		end
	end
	
	return stats
end

-- Broadcast configuration update to all clients
function ConfigBridge:broadcastConfigUpdate(category, configPath, newValue)
	local notificationEvent = ReplicatedStorage:FindFirstChild("ConfigUpdateNotification")
	if not notificationEvent then
		return false, "Notification event not found"
	end
	
	-- Send to all players
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local updatedConfig = ConfigManager.getConfig(category, configPath)
		if updatedConfig then
			notificationEvent:FireClient(player, category, configPath, updatedConfig)
		end
	end
	
	return true, "Configuration broadcasted successfully"
end

-- Initialize global Configuration Bridge instance
local globalConfigBridge = ConfigBridge.new()

-- Expose methods globally
function ConfigBridge.handleClientConfigRequest(player, requestType, configPath)
	return globalConfigBridge:_handleClientConfigRequest(player, requestType, configPath)
end

function ConfigBridge.handleConfigUpdate(player, category, configPath, value)
	return globalConfigBridge:_handleConfigUpdate(player, category, configPath, value)
end

function ConfigBridge.getConfigBridgeStats()
	return globalConfigBridge:getConfigBridgeStats()
end

function ConfigBridge.broadcastConfigUpdate(category, configPath, newValue)
	return globalConfigBridge:broadcastConfigUpdate(category, configPath, newValue)
end

print("[Config Bridge] Professional server-side configuration bridge ready!")

return ConfigBridge