-- Client-Side Configuration Bridge v1.0
-- Professional client-side configuration handler for secure configuration access
-- Manages client-safe and shared configuration requests with validation

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ConfigManager = require(ReplicatedStorage.Shared.ConfigManager)

local ClientConfigBridge = {}
ClientConfigBridge.__index = ClientConfigBridge

-- Client configuration state
local clientConfigState = {
	playerId = nil,
	sessionId = nil,
	currentToken = nil,
	subscribedConfigs = {},
	configCache = {},
	lastConfigUpdate = 0,
	isAuthenticated = false
}

-- Client bridge configuration
local CLIENT_BRIDGE_CONFIG = {
	MAX_CACHE_SIZE = 100,
	CACHE_TIMEOUT = 600, -- 10 minutes
	ENABLE_CONFIG_VALIDATION = true,
	ENABLE_CONFIG_CACHING = true,
	ENABLE_SUBSCRIPTION_UPDATES = true
}

-- Initialize the Client Configuration Bridge
function ClientConfigBridge.new()
	local self = setmetatable({}, ClientConfigBridge)
	
	-- Get player information
	local player = Players.LocalPlayer
	if player then
		clientConfigState.playerId = player.UserId
		print("[Client Config Bridge] Initialized for player: " .. player.UserId)
	else
		warn("[Client Config Bridge] No local player found")
		return nil
	end
	
	-- Setup client configuration handlers
	self:_setupClientConfigHandlers()
	
	-- Setup configuration monitoring
	self:_setupClientConfigMonitoring()
	
	-- Request initial configuration
	self:_requestInitialConfiguration()
	
	print("[Client Config Bridge] Client-side configuration bridge initialized")
	
	return self
end

-- Setup client configuration handlers
function ClientConfigBridge:_setupClientConfigHandlers()
	-- Handle configuration update notifications
	local configUpdateNotification = ReplicatedStorage:FindFirstChild("ConfigUpdateNotification")
	if configUpdateNotification then
		configUpdateNotification.OnClientEvent:Connect(function(category, configPath, newValue)
			self:_handleConfigUpdateNotification(category, configPath, newValue)
		end)
		print("[Client Config Bridge] Configuration update notification handler registered")
	else
		warn("[Client Config Bridge] ConfigUpdateNotification event not found!")
	end
end

-- Setup client configuration monitoring
function ClientConfigBridge:_setupClientConfigMonitoring()
	-- Monitor configuration cache
	spawn(function()
		while true do
			task.wait(300) -- Cleanup cache every 5 minutes
			self:_cleanupConfigCache()
		end
	end)
	
	-- Monitor subscription health
	spawn(function()
		while true do
			task.wait(600) -- Check subscriptions every 10 minutes
			self:_checkSubscriptionHealth()
		end
	end)
end

-- Request initial configuration
function ClientConfigBridge:_requestInitialConfiguration()
	-- Request client-safe configurations
	task.spawn(function()
		local success, clientSafeConfigs = self:getClientSafeConfigs()
		if success then
			print("[Client Config Bridge] Client-safe configurations loaded")
		else
			warn("[Client Config Bridge] Failed to load client-safe configurations")
		end
	end)
	
	-- Request shared configurations
	task.spawn(function()
		local success, sharedConfigs = self:getSharedConfigs()
		if success then
			print("[Client Config Bridge] Shared configurations loaded")
		else
			warn("[Client Config Bridge] Failed to load shared configurations")
		end
	end)
	
	-- Request configuration schema
	task.spawn(function()
		local success, schema = self:getConfigSchema()
		if success then
			print("[Client Config Bridge] Configuration schema loaded")
		else
			warn("[Client Config Bridge] Failed to load configuration schema")
		end
	end)
end

-- Get client-safe configurations
function ClientConfigBridge:getClientSafeConfigs()
	local clientConfigRequestEvent = ReplicatedStorage:FindFirstChild("ClientConfigRequest")
	if not clientConfigRequestEvent then
		return false, "ClientConfigRequest event not found"
	end
	
	-- Request all client-safe configurations
	local success, result = pcall(function()
		return clientConfigRequestEvent:InvokeServer("GET_CLIENT_SAFE", nil)
	end)
	
	if success then
		if CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING then
			self:_updateConfigCache("CLIENT_SAFE", nil, result)
		end
		
		return true, result
	else
		return false, result
	end
end

-- Get specific client-safe configuration
function ClientConfigBridge:getClientSafeConfig(configPath)
	local clientConfigRequestEvent = ReplicatedStorage:FindFirstChild("ClientConfigRequest")
	if not clientConfigRequestEvent then
		return false, "ClientConfigRequest event not found"
	end
	
	-- Check cache first
	if CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING then
		local cachedConfig = self:_getCachedConfig("CLIENT_SAFE", configPath)
		if cachedConfig then
			return true, cachedConfig
		end
	end
	
	-- Request specific configuration
	local success, result = pcall(function()
		return clientConfigRequestEvent:InvokeServer("GET_CLIENT_SAFE", configPath)
	end)
	
	if success then
		if CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING then
			self:_updateConfigCache("CLIENT_SAFE", configPath, result)
		end
		
		return true, result
	else
		return false, result
	end
end

-- Get shared configurations
function ClientConfigBridge:getSharedConfigs()
	local clientConfigRequestEvent = ReplicatedStorage:FindFirstChild("ClientConfigRequest")
	if not clientConfigRequestEvent then
		return false, "ClientConfigRequest event not found"
	end
	
	-- Request all shared configurations
	local success, result = pcall(function()
		return clientConfigRequestEvent:InvokeServer("GET_SHARED", nil)
	end)
	
	if success then
		if CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING then
			self:_updateConfigCache("SHARED", nil, result)
		end
		
		return true, result
	else
		return false, result
	end
end

-- Get specific shared configuration
function ClientConfigBridge:getSharedConfig(configPath)
	local clientConfigRequestEvent = ReplicatedStorage:FindFirstChild("ClientConfigRequest")
	if not clientConfigRequestEvent then
		return false, "ClientConfigRequest event not found"
	end
	
	-- Check cache first
	if CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING then
		local cachedConfig = self:_getCachedConfig("SHARED", configPath)
		if cachedConfig then
			return true, cachedConfig
		end
	end
	
	-- Request specific configuration
	local success, result = pcall(function()
		return clientConfigRequestEvent:InvokeServer("GET_SHARED", configPath)
	end)
	
	if success then
		if CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING then
			self:_updateConfigCache("SHARED", configPath, result)
		end
		
		return true, result
	else
		return false, result
	end
end

-- Get configuration schema
function ClientConfigBridge:getConfigSchema()
	local clientConfigRequestEvent = ReplicatedStorage:FindFirstChild("ClientConfigRequest")
	if not clientConfigRequestEvent then
		return false, "ClientConfigRequest event not found"
	end
	
	-- Request configuration schema
	local success, result = pcall(function()
		return clientConfigRequestEvent:InvokeServer("GET_SCHEMA", nil)
	end)
	
	if success then
		return true, result
	else
		return false, result
	end
end

-- Subscribe to configuration updates
function ClientConfigBridge:subscribeToConfig(configPath, callback)
	local clientConfigRequestEvent = ReplicatedStorage:FindFirstChild("ClientConfigRequest")
	if not clientConfigRequestEvent then
		return false, "ClientConfigRequest event not found"
	end
	
	-- Validate subscription path
	if not configPath or configPath == "" then
		return false, "Invalid subscription path"
	end
	
	-- Request subscription
	local success, result = pcall(function()
		return clientConfigRequestEvent:InvokeServer("SUBSCRIBE", configPath)
	end)
	
	if success then
		-- Store subscription
		clientConfigState.subscribedConfigs[configPath] = {
			subscribedAt = tick(),
			callback = callback
		}
		
		return true, "Subscription created successfully"
	else
		return false, result
	end
end

-- Update configuration (client-side only for client-safe configs)
function ClientConfigBridge:updateConfig(category, configPath, value)
	-- Only allow updates to client-safe configurations
	if category ~= "CLIENT_SAFE" then
		return false, "Cannot update non-client-safe configuration from client"
	end
	
	local configUpdateEvent = ReplicatedStorage:FindFirstChild("ConfigUpdate")
	if not configUpdateEvent then
		return false, "ConfigUpdate event not found"
	end
	
	-- Validate configuration value
	if CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_VALIDATION then
		local isValid, validationMessage = ConfigManager.setConfig(category, configPath, value)
		if not isValid then
			return false, validationMessage
		end
	end
	
	-- Send update request
	local success, result = pcall(function()
		return configUpdateEvent:InvokeServer(category, configPath, value)
	end)
	
	if success then
		-- Update local cache
		if CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING then
			self:_updateConfigCache(category, configPath, value)
		end
		
		return true, result
	else
		return false, result
	end
end

-- Handle configuration update notification
function ClientConfigBridge:_handleConfigUpdateNotification(category, configPath, newValue)
	-- Update local cache
	if CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING then
		self:_updateConfigCache(category, configPath, newValue)
	end
	
	-- Notify subscribers
	if clientConfigState.subscribedConfigs[configPath] then
		local subscription = clientConfigState.subscribedConfigs[configPath]
		if subscription.callback then
			task.spawn(function()
				subscription.callback(category, configPath, newValue)
			end)
		end
	end
	
	-- Update last config update time
	clientConfigState.lastConfigUpdate = tick()
end

-- Update configuration cache
function ClientConfigBridge:_updateConfigCache(category, configPath, value)
	if not CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING then
		return
	end
	
	-- Create cache key
	local cacheKey = category .. (configPath and "." .. configPath or "")
	
	-- Check cache size limit
	if #table.keys(clientConfigState.configCache) >= CLIENT_BRIDGE_CONFIG.MAX_CACHE_SIZE then
		-- Remove oldest cache entry
		local oldestKey = nil
		local oldestTime = math.huge
		
		for key, cacheEntry in pairs(clientConfigState.configCache) do
			if cacheEntry.timestamp < oldestTime then
				oldestTime = cacheEntry.timestamp
				oldestKey = key
			end
		end
		
		if oldestKey then
			clientConfigState.configCache[oldestKey] = nil
		end
	end
	
	-- Update cache
	clientConfigState.configCache[cacheKey] = {
		value = value,
		timestamp = tick(),
		category = category,
		configPath = configPath
	}
end

-- Get cached configuration
function ClientConfigBridge:_getCachedConfig(category, configPath)
	if not CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING then
		return nil
	end
	
	local cacheKey = category .. (configPath and "." .. configPath or "")
	local cacheEntry = clientConfigState.configCache[cacheKey]
	
	if cacheEntry then
		-- Check cache timeout
		if tick() - cacheEntry.timestamp > CLIENT_BRIDGE_CONFIG.CACHE_TIMEOUT then
			clientConfigState.configCache[cacheKey] = nil
			return nil
		end
		
		return cacheEntry.value
	end
	
	return nil
end

-- Cleanup configuration cache
function ClientConfigBridge:_cleanupConfigCache()
	if not CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING then
		return
	end
	
	local currentTime = tick()
	local timeout = CLIENT_BRIDGE_CONFIG.CACHE_TIMEOUT
	
	for cacheKey, cacheEntry in pairs(clientConfigState.configCache) do
		if currentTime - cacheEntry.timestamp > timeout then
			clientConfigState.configCache[cacheKey] = nil
		end
	end
end

-- Check subscription health
function ClientConfigBridge:_checkSubscriptionHealth()
	-- This would typically check if subscriptions are still active
	-- For now, just log the current subscriptions
	local subscriptionCount = #table.keys(clientConfigState.subscribedConfigs)
	print(string.format("[Client Config Bridge] Active subscriptions: %d", subscriptionCount))
end

-- Get client configuration statistics
function ClientConfigBridge:getClientConfigStats()
	local stats = {
		playerId = clientConfigState.playerId,
		subscribedConfigs = #table.keys(clientConfigState.subscribedConfigs),
		cachedConfigs = #table.keys(clientConfigState.configCache),
		lastConfigUpdate = clientConfigState.lastConfigUpdate,
		isAuthenticated = clientConfigState.isAuthenticated,
		cacheEnabled = CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_CACHING,
		validationEnabled = CLIENT_BRIDGE_CONFIG.ENABLE_CONFIG_VALIDATION
	}
	
	return stats
end

-- Validate configuration locally
function ClientConfigBridge:validateConfig(category, configPath, value)
	if category == "SERVER_ONLY" then
		return false, "Cannot validate server-only configuration on client"
	end
	
	return ConfigManager.setConfig(category, configPath, value)
end

-- Initialize global Client Configuration Bridge instance
local globalClientConfigBridge = ClientConfigBridge.new()

-- Expose methods globally
function ClientConfigBridge.getClientSafeConfigs()
	return globalClientConfigBridge:getClientSafeConfigs()
end

function ClientConfigBridge.getClientSafeConfig(configPath)
	return globalClientConfigBridge:getClientSafeConfig(configPath)
end

function ClientConfigBridge.getSharedConfigs()
	return globalClientConfigBridge:getSharedConfigs()
end

function ClientConfigBridge.getSharedConfig(configPath)
	return globalClientConfigBridge:getSharedConfig(configPath)
end

function ClientConfigBridge.getConfigSchema()
	return globalClientConfigBridge:getConfigSchema()
end

function ClientConfigBridge.subscribeToConfig(configPath, callback)
	return globalClientConfigBridge:subscribeToConfig(configPath, callback)
end

function ClientConfigBridge.updateConfig(category, configPath, value)
	return globalClientConfigBridge:updateConfig(category, configPath, value)
end

function ClientConfigBridge.getClientConfigStats()
	return globalClientConfigBridge:getClientConfigStats()
end

function ClientConfigBridge.validateConfig(category, configPath, value)
	return globalClientConfigBridge:validateConfig(category, configPath, value)
end

print("[Client Config Bridge] Professional client-side configuration bridge ready!")

return ClientConfigBridge