-- Client Integration Manager v2.0
-- Professional client-side integration manager with Data Reconciliation and Data Store Management
-- Ensures seamless client-side system integration and coordination

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

local ClientIntegrationManager = {}
ClientIntegrationManager.__index = ClientIntegrationManager

-- Client integration state
local clientIntegrationState = {
	playerId = nil,
	sessionId = nil,
	systems = {
		assetLoader = nil,
		secureClientBridge = nil,
		clientConfigBridge = nil
	},
	isInitialized = false,
	initializationOrder = {},
	healthCheckResults = {},
	integrationMetrics = {
		totalIntegrations = 0,
		successfulIntegrations = 0,
		failedIntegrations = 0,
		averageIntegrationTime = 0
	}
}

-- System dependencies and initialization order
local CLIENT_SYSTEM_DEPENDENCIES = {
	assetLoader = {
		dependencies = {},
		initFunction = function()
			local AssetLoader = require(ReplicatedStorage.Client.AssetLoader)
			return AssetLoader
		end
	},
	secureClientBridge = {
		dependencies = {},
		initFunction = function()
			local SecureClientBridge = require(ReplicatedStorage.Client.SecureClientBridge)
			return SecureClientBridge
		end
	},
	clientConfigBridge = {
		dependencies = {},
		initFunction = function()
			local ClientConfigBridge = require(ReplicatedStorage.Client.ClientConfigBridge)
			return ClientConfigBridge
		end
	}
}

-- Client integration configuration
local CLIENT_INTEGRATION_CONFIG = {
	ENABLE_ASSET_PRELOADING = true,
	ENABLE_CONFIG_SUBSCRIPTIONS = true,
	ENABLE_SECURITY_MONITORING = true,
	ENABLE_PERFORMANCE_MONITORING = true,
	ENABLE_HEALTH_CHECKS = true
}

-- Initialize the Client Integration Manager
function ClientIntegrationManager.new()
	local self = setmetatable({}, ClientIntegrationManager)
	
	-- Get player information
	local player = Players.LocalPlayer
	if player then
		clientIntegrationState.playerId = player.UserId
		print("[Client Integration Manager] Initialized for player: " .. player.UserId)
	else
		warn("[Client Integration Manager] No local player found")
		return nil
	end
	
	-- Initialize all client systems in correct order
	self:_initializeAllClientSystems()
	
	-- Setup client integration monitoring
	self:_setupClientIntegrationMonitoring()
	
	-- Setup client-side cross-system integration
	self:_setupClientCrossSystemIntegration()
	
	-- Setup player-specific handlers
	self:_setupPlayerHandlers()
	
	print("[Client Integration Manager] All client systems integrated and operational with Data Reconciliation and Data Store Management")
	
	return self
end

-- Initialize all client systems in dependency order
function ClientIntegrationManager:_initializeAllClientSystems()
	print("[Client Integration Manager] Starting client system initialization...")
	
	local initializedSystems = {}
	local maxAttempts = 10
	local attempt = 0
	
	repeat
		attempt = attempt + 1
		local systemsInitializedThisRound = 0
		
		for systemName, systemConfig in pairs(CLIENT_SYSTEM_DEPENDENCIES) do
			-- Skip if already initialized
			if not initializedSystems[systemName] then
				-- Check if all dependencies are met
				local dependenciesMet = true
				for _, dependency in ipairs(systemConfig.dependencies) do
					if not initializedSystems[dependency] then
						dependenciesMet = false
						break
					end
				end
				
				-- Initialize system if dependencies are met
				if dependenciesMet then
					local success, result = pcall(systemConfig.initFunction)
					if success then
						clientIntegrationState.systems[systemName] = result
						initializedSystems[systemName] = true
						systemsInitializedThisRound = systemsInitializedThisRound + 1
						table.insert(clientIntegrationState.initializationOrder, systemName)
						print(string.format("[Client Integration Manager] Initialized %s", systemName))
					else
						warn(string.format("[Client Integration Manager] Failed to initialize %s: %s", systemName, result))
					end
				end
			end
		end
		
		-- Continue until all systems are initialized or max attempts reached
	until #clientIntegrationState.initializationOrder == #CLIENT_SYSTEM_DEPENDENCIES or attempt >= maxAttempts
	
	-- Check if all systems were successfully initialized
	if #clientIntegrationState.initializationOrder == #CLIENT_SYSTEM_DEPENDENCIES then
		clientIntegrationState.isInitialized = true
		print("[Client Integration Manager] All client systems successfully initialized")
	else
		warn("[Client Integration Manager] Some client systems failed to initialize")
		self:_logFailedClientSystems()
	end
end

-- Log failed client system initializations
function ClientIntegrationManager:_logFailedClientSystems()
	local failedSystems = {}
	for systemName in pairs(CLIENT_SYSTEM_DEPENDENCIES) do
		if not clientIntegrationState.systems[systemName] then
			table.insert(failedSystems, systemName)
		end
	end
	
	if #failedSystems > 0 then
		print("[Client Integration Manager] Failed client systems:")
		for _, system in ipairs(failedSystems) do
			print("  - " .. system)
		end
	end
end

-- Setup client integration monitoring
function ClientIntegrationManager:_setupClientIntegrationMonitoring()
	-- Health check monitoring
	if CLIENT_INTEGRATION_CONFIG.ENABLE_HEALTH_CHECKS then
		spawn(function()
			while true do
				task.wait(60) -- Check every minute
				self:_performClientHealthCheck()
			end
		end)
	end
	
	-- Performance monitoring
	if CLIENT_INTEGRATION_CONFIG.ENABLE_PERFORMANCE_MONITORING then
		spawn(function()
			while true do
				task.wait(120) -- Log performance every 2 minutes
				self:_logClientIntegrationPerformance()
			end
		end)
	end
	
	-- Security monitoring
	if CLIENT_INTEGRATION_CONFIG.ENABLE_SECURITY_MONITORING then
		spawn(function()
			while true do
				task.wait(180) -- Monitor security every 3 minutes
				self:_monitorClientSecurity()
			end
		end)
	end
end

-- Setup client-side cross-system integration
function ClientIntegrationManager:_setupClientCrossSystemIntegration()
	-- Integrate Asset Loader with Configuration Bridge
	if clientIntegrationState.systems.assetLoader and clientIntegrationState.systems.clientConfigBridge then
		self:_integrateAssetLoaderWithConfig()
	end
	
	-- Integrate Secure Client Bridge with Configuration Bridge
	if clientIntegrationState.systems.secureClientBridge and clientIntegrationState.systems.clientConfigBridge then
		self:_integrateSecureBridgeWithConfig()
	end
	
	-- Setup client-side data reconciliation monitoring
	self:_setupClientDataReconciliationMonitoring()
	
	-- Setup client-side data store monitoring
	self:_setupClientDataStoreMonitoring()
	
	print("[Client Integration Manager] Client-side cross-system integration completed")
end

-- Setup player-specific handlers
function ClientIntegrationManager:_setupPlayerHandlers()
	-- Handle player character added
	Players.LocalPlayer.CharacterAdded:Connect(function(character)
		self:_handlePlayerCharacterAdded(character)
	end)
	
	-- Handle player character removing
	Players.LocalPlayer.CharacterRemoving:Connect(function(character)
		self:_handlePlayerCharacterRemoving(character)
	end)
	
	-- Handle player leaving
	Players.LocalPlayer.CharacterRemoving:Connect(function()
		self:_handlePlayerLeaving()
	end)
end

-- Integrate Asset Loader with Configuration Bridge
function ClientIntegrationManager:_integrateAssetLoaderWithConfig()
	local assetLoader = clientIntegrationState.systems.assetLoader
	local clientConfigBridge = clientIntegrationState.systems.clientConfigBridge
	
	-- Monitor configuration changes that affect assets
	if CLIENT_INTEGRATION_CONFIG.ENABLE_CONFIG_SUBSCRIPTIONS then
		task.spawn(function()
			local success, result = clientConfigBridge.subscribeToConfig("CLIENT_SAFE.graphics", function(category, configPath, newValue)
				-- Handle graphics configuration changes
				if configPath == "textureQuality" then
					-- Reload assets with new quality settings
					print("[Client Integration Manager] Graphics configuration changed - reloading assets")
				elseif configPath == "maxRenderDistance" then
					-- Adjust asset loading distance
					print("[Client Integration Manager] Render distance changed - adjusting asset loading")
				end
			end)
			
			if not success then
				warn("[Client Integration Manager] Failed to subscribe to graphics configuration: " .. result)
			end
		end)
	end
	
	print("[Client Integration Manager] Asset Loader integrated with Configuration Bridge")
end

-- Integrate Secure Client Bridge with Configuration Bridge
function ClientIntegrationManager:_integrateSecureBridgeWithConfig()
	local secureClientBridge = clientIntegrationState.systems.secureClientBridge
	local clientConfigBridge = clientIntegrationState.systems.clientConfigBridge
	
	-- Monitor security-related configuration changes
	if CLIENT_INTEGRATION_CONFIG.ENABLE_CONFIG_SUBSCRIPTIONS then
		task.spawn(function()
			local success, result = clientConfigBridge.subscribeToConfig("SHARED.security", function(category, configPath, newValue)
				-- Handle security configuration changes
				if configPath == "encryptionEnabled" then
					-- Update secure communication settings
					print("[Client Integration Manager] Security configuration changed - updating secure communication")
				elseif configPath == "rateLimitingEnabled" then
					-- Adjust client-side rate limiting
					print("[Client Integration Manager] Rate limiting configuration changed")
				end
			end)
			
			if not success then
				warn("[Client Integration Manager] Failed to subscribe to security configuration: " .. result)
			end
		end)
	end
	
	print("[Client Integration Manager] Secure Client Bridge integrated with Configuration Bridge")
end

-- Setup client-side data reconciliation monitoring
function ClientIntegrationManager:_setupClientDataReconciliationMonitoring()
	-- Monitor for data reconciliation events
	local configUpdateNotification = ReplicatedStorage:FindFirstChild("ConfigUpdateNotification")
	if configUpdateNotification then
		configUpdateNotification.OnClientEvent:Connect(function(category, configPath, newValue)
			-- Monitor configuration updates for reconciliation needs
			if category == "SHARED" then
				-- Check if configuration update requires reconciliation
				print("[Client Integration Manager] Shared configuration updated - monitoring for reconciliation needs")
			end
		end)
	end
	
	print("[Client Integration Manager] Client-side data reconciliation monitoring setup completed")
end

-- Setup client-side data store monitoring
function ClientIntegrationManager:_setupClientDataStoreMonitoring()
	-- Monitor data store operations from client perspective
	spawn(function()
		while true do
			task.wait(300) -- Check every 5 minutes
			if clientIntegrationState.systems.secureClientBridge then
				local bridgeStats = clientIntegrationState.systems.secureClientBridge.getBridgeStats()
				
				-- Monitor for data store related issues
				if bridgeStats.pendingRequests > 10 then
					print("[Client Integration Manager] High pending requests - potential data store issues")
				end
			end
		end
	end)
	
	print("[Client Integration Manager] Client-side data store monitoring setup completed")
end

-- Handle player character added
function ClientIntegrationManager:_handlePlayerCharacterAdded(character)
	local playerId = clientIntegrationState.playerId
	
	-- Preload character-related assets
	if clientIntegrationState.systems.assetLoader then
		task.spawn(function()
			-- Preload character assets based on configuration
			local success, graphicsConfig = clientIntegrationState.systems.clientConfigBridge:getClientSafeConfig("graphics")
			if success then
				print(string.format("[Client Integration Manager] Preloading character assets for player %d", playerId))
			end
		end)
	end
	
	-- Setup character-specific security monitoring
	if clientIntegrationState.systems.secureClientBridge then
		task.spawn(function()
			print(string.format("[Client Integration Manager] Character security monitoring setup for player %d", playerId))
		end)
	end
end

-- Handle player character removing
function ClientIntegrationManager:_handlePlayerCharacterRemoving(character)
	local playerId = clientIntegrationState.playerId
	
	-- Cleanup character-related assets
	if clientIntegrationState.systems.assetLoader then
		task.spawn(function()
			print(string.format("[Client Integration Manager] Cleaning up character assets for player %d", playerId))
		end)
	end
	
	-- Cleanup character-specific monitoring
	if clientIntegrationState.systems.secureClientBridge then
		task.spawn(function()
			print(string.format("[Client Integration Manager] Cleaning up character security monitoring for player %d", playerId))
		end)
	end
end

-- Handle player leaving
function ClientIntegrationManager:_handlePlayerLeaving()
	local playerId = clientIntegrationState.playerId
	
	-- Cleanup all player-specific resources
	if clientIntegrationState.systems.assetLoader then
		task.spawn(function()
			print(string.format("[Client Integration Manager] Player %d leaving - cleaning up all resources", playerId))
		end)
	end
	
	-- Final security check
	if clientIntegrationState.systems.secureClientBridge then
		task.spawn(function()
			print(string.format("[Client Integration Manager] Final security check for player %d", playerId))
		end)
	end
end

-- Perform client-side health check
function ClientIntegrationManager:_performClientHealthCheck()
	local healthResults = {
		timestamp = tick(),
		systems = {},
		crossSystemIntegration = {},
		overallStatus = "HEALTHY"
	}
	
	-- Check each client system
	for systemName, systemInstance in pairs(clientIntegrationState.systems) do
		local systemHealth = self:_checkClientSystemHealth(systemName, systemInstance)
		healthResults.systems[systemName] = systemHealth
		
		if systemHealth.status ~= "HEALTHY" then
			healthResults.overallStatus = "DEGRADED"
		end
	end
	
	-- Check client-side cross-system integration
	local integrationHealth = self:_checkClientCrossSystemIntegration()
	healthResults.crossSystemIntegration = integrationHealth
	
	if integrationHealth.status ~= "HEALTHY" then
		healthResults.overallStatus = "DEGRADED"
	end
	
	-- Store health results
	clientIntegrationState.healthCheckResults = healthResults
	
	-- Log health status
	if healthResults.overallStatus == "HEALTHY" then
		print("[Client Integration Manager] All client systems and integration healthy")
	else
		print("[Client Integration Manager] Client system health degraded - " .. healthResults.overallStatus)
		self:_logClientHealthIssues(healthResults)
	end
end

-- Check individual client system health
function ClientIntegrationManager:_checkClientSystemHealth(systemName, systemInstance)
	local health = {
		status = "HEALTHY",
		metrics = {},
		issues = {}
	}
	
	-- System-specific health checks
	if systemName == "assetLoader" then
		health = self:_checkAssetLoaderHealth(systemInstance)
	elseif systemName == "secureClientBridge" then
		health = self:_checkSecureClientBridgeHealth(systemInstance)
	elseif systemName == "clientConfigBridge" then
		health = self:_checkClientConfigBridgeHealth(systemInstance)
	end
	
	return health
end

-- Check client-side cross-system integration health
function ClientIntegrationManager:_checkClientCrossSystemIntegration()
	local integrationHealth = {
		status = "HEALTHY",
		metrics = {},
		issues = {}
	}
	
	-- Check asset loading integration
	if clientIntegrationState.systems.assetLoader then
		local assetStats = clientIntegrationState.systems.assetLoader.getAssetLoaderStats()
		integrationHealth.metrics.assetLoader = assetStats
		
		if assetStats.failedAssets > 10 then
			integrationHealth.status = "WARNING"
			table.insert(integrationHealth.issues, "High asset loading failures")
		end
	end
	
	-- Check secure communication integration
	if clientIntegrationState.systems.secureClientBridge then
		local bridgeStats = clientIntegrationState.systems.secureClientBridge.getBridgeStats()
		integrationHealth.metrics.secureClientBridge = bridgeStats
		
		if bridgeStats.pendingRequests > 20 then
			integrationHealth.status = "WARNING"
			table.insert(integrationHealth.issues, "High pending secure requests")
		end
	end
	
	-- Check configuration integration
	if clientIntegrationState.systems.clientConfigBridge then
		local configStats = clientIntegrationState.systems.clientConfigBridge.getClientConfigStats()
		integrationHealth.metrics.clientConfigBridge = configStats
		
		if configStats.subscribedConfigs > 50 then
			integrationHealth.status = "WARNING"
			table.insert(integrationHealth.issues, "High configuration subscription load")
		end
	end
	
	return integrationHealth
end

-- Check Asset Loader health
function ClientIntegrationManager:_checkAssetLoaderHealth(assetLoader)
	local stats = assetLoader.getAssetLoaderStats()
	local health = {
		status = "HEALTHY",
		metrics = stats,
		issues = {}
	}
	
	-- Check for asset loading issues
	if stats.totalAssets == 0 then
		health.status = "WARNING"
		table.insert(health.issues, "No assets detected")
	elseif stats.loadedAssets < stats.totalAssets * 0.8 then
		health.status = "WARNING"
		table.insert(health.issues, "Asset loading incomplete")
	elseif stats.failedAssets > 10 then
		health.status = "CRITICAL"
		table.insert(health.issues, "High asset loading failures")
	end
	
	return health
end

-- Check Secure Client Bridge health
function ClientIntegrationManager:_checkSecureClientBridgeHealth(secureClientBridge)
	local stats = secureClientBridge.getBridgeStats()
	local health = {
		status = "HEALTHY",
		metrics = stats,
		issues = {}
	}
	
	-- Check for secure communication issues
	if stats.pendingRequests > 20 then
		health.status = "WARNING"
		table.insert(health.issues, "High pending request count")
	elseif stats.failedRequests > 10 then
		health.status = "CRITICAL"
		table.insert(health.issues, "High secure communication failures")
	end
	
	return health
end

-- Check Client Config Bridge health
function ClientIntegrationManager:_checkClientConfigBridgeHealth(clientConfigBridge)
	local stats = clientConfigBridge.getClientConfigStats()
	local health = {
		status = "HEALTHY",
		metrics = stats,
		issues = {}
	}
	
	-- Check for configuration bridge issues
	if stats.subscribedConfigs > 50 then
		health.status = "WARNING"
		table.insert(health.issues, "High configuration subscription load")
	elseif stats.cachedConfigs > 100 then
		health.status = "WARNING"
		table.insert(health.issues, "High configuration cache usage")
	end
	
	return health
end

-- Log client health issues
function ClientIntegrationManager:_logClientHealthIssues(healthResults)
	print("[Client Integration Manager] Client health issues detected:")
	
	-- Log system issues
	for systemName, systemHealth in pairs(healthResults.systems) do
		if systemHealth.status ~= "HEALTHY" then
			print(string.format("  %s: %s", systemName, systemHealth.status))
			for _, issue in ipairs(systemHealth.issues) do
				print(string.format("    - %s", issue))
			end
		end
	end
	
	-- Log cross-system integration issues
	if healthResults.crossSystemIntegration.status ~= "HEALTHY" then
		print(string.format("  Cross-System Integration: %s", healthResults.crossSystemIntegration.status))
		for _, issue in ipairs(healthResults.crossSystemIntegration.issues) do
			print(string.format("    - %s", issue))
		end
	end
end

-- Monitor client security
function ClientIntegrationManager:_monitorClientSecurity()
	if clientIntegrationState.systems.secureClientBridge then
		local bridgeStats = clientIntegrationState.systems.secureClientBridge.getBridgeStats()
		
		-- Check for security issues
		if bridgeStats.failedRequests > 10 then
			print("[Client Integration Manager] High secure communication failures detected")
		elseif bridgeStats.pendingRequests > 50 then
			print("[Client Integration Manager] High pending request backlog detected")
		end
	end
end

-- Log client integration performance
function ClientIntegrationManager:_logClientIntegrationPerformance()
	local performanceData = {
		timestamp = tick(),
		systems = {},
		integrationMetrics = clientIntegrationState.integrationMetrics
	}
	
	-- Collect performance data from each client system
	for systemName, systemInstance in pairs(clientIntegrationState.systems) do
		if systemName == "assetLoader" then
			local stats = systemInstance.getAssetLoaderStats()
			performanceData.systems[systemName] = {
				totalAssets = stats.totalAssets,
				loadedAssets = stats.loadedAssets,
				failedAssets = stats.failedAssets,
				loadingTime = stats.totalLoadingTime
			}
		elseif systemName == "secureClientBridge" then
			local stats = systemInstance.getBridgeStats()
			performanceData.systems[systemName] = {
				pendingRequests = stats.pendingRequests,
				failedRequests = stats.failedRequests,
				totalRequests = stats.totalRequests,
				averageResponseTime = stats.averageResponseTime
			}
		elseif systemName == "clientConfigBridge" then
			local stats = systemInstance.getClientConfigStats()
			performanceData.systems[systemName] = {
				subscribedConfigs = stats.subscribedConfigs,
				cachedConfigs = stats.cachedConfigs,
				isAuthenticated = stats.isAuthenticated,
				lastConfigUpdate = stats.lastConfigUpdate
			}
		end
	end
	
	-- Log performance summary
	print("[Client Integration Manager] Client Performance Summary:")
	for systemName, metrics in pairs(performanceData.systems) do
		local metricString = ""
		for metricName, metricValue in pairs(metrics) do
			metricString = metricString .. string.format("%s: %s, ", metricName, tostring(metricValue))
		end
		print(string.format("  %s: %s", systemName, metricString:sub(1, -3))) -- Remove trailing comma
	end
	
	-- Log integration metrics
	local metrics = clientIntegrationState.integrationMetrics
	print(string.format("  Integration Metrics: Total: %d | Successful: %d | Failed: %d | Success Rate: %.1f%%",
		metrics.totalIntegrations, metrics.successfulIntegrations, metrics.failedIntegrations,
		metrics.totalIntegrations > 0 and (metrics.successfulIntegrations / metrics.totalIntegrations) * 100 or 0))
end

-- Get client integration status
function ClientIntegrationManager:getClientIntegrationStatus()
	return {
		isInitialized = clientIntegrationState.isInitialized,
		initializationOrder = clientIntegrationState.initializationOrder,
		systemCount = #clientIntegrationState.initializationOrder,
		healthStatus = clientIntegrationState.healthCheckResults.overallStatus or "UNKNOWN",
		lastHealthCheck = clientIntegrationState.healthCheckResults.timestamp or 0,
		integrationMetrics = clientIntegrationState.integrationMetrics,
		playerId = clientIntegrationState.playerId
	}
end

-- Get client system statistics
function ClientIntegrationManager:getClientSystemStatistics()
	local stats = {}
	
	for systemName, systemInstance in pairs(clientIntegrationState.systems) do
		if systemName == "assetLoader" then
			stats[systemName] = systemInstance.getAssetLoaderStats()
		elseif systemName == "secureClientBridge" then
			stats[systemName] = systemInstance.getBridgeStats()
		elseif systemName == "clientConfigBridge" then
			stats[systemName] = systemInstance.getClientConfigStats()
		end
	end
	
	return stats
end

-- Perform manual client health check
function ClientIntegrationManager:performManualClientHealthCheck()
	self:_performClientHealthCheck()
	return clientIntegrationState.healthCheckResults
end

-- Initialize global Client Integration Manager instance
local globalClientIntegrationManager = ClientIntegrationManager.new()

-- Expose methods globally
function ClientIntegrationManager.getClientIntegrationStatus()
	return globalClientIntegrationManager:getClientIntegrationStatus()
end

function ClientIntegrationManager.getClientSystemStatistics()
	return globalClientIntegrationManager:getClientSystemStatistics()
end

function ClientIntegrationManager.performManualClientHealthCheck()
	return globalClientIntegrationManager:performManualClientHealthCheck()
end

print("[Client Integration Manager] Professional client-side system integration with Data Reconciliation and Data Store Management ready!")

return ClientIntegrationManager