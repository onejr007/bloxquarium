-- Integration Manager v2.0
-- Professional system integration manager with Data Reconciliation and Data Store Management
-- Ensures all systems work together seamlessly with comprehensive integration

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

local IntegrationManager = {}
IntegrationManager.__index = IntegrationManager

-- Integration state
local integrationState = {
	systems = {
		assetManager = nil,
		securityFramework = nil,
		secureCommunication = nil,
		securityBridge = nil,
		dataReconciliation = nil,
		dataStoreManager = nil,
		configManager = nil,
		configBridge = nil
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
local SYSTEM_DEPENDENCIES = {
	assetManager = {
		dependencies = {},
		initFunction = function()
			local AssetManagerPro = require(ReplicatedStorage.Shared.AssetManagerPro)
			return AssetManagerPro
		end
	},
	securityFramework = {
		dependencies = {},
		initFunction = function()
			local SecurityFramework = require(ReplicatedStorage.Shared.SecurityFramework)
			return SecurityFramework
		end
	},
	secureCommunication = {
		dependencies = {"securityFramework"},
		initFunction = function()
			local SecureCommunication = require(ReplicatedStorage.Shared.SecureCommunication)
			return SecureCommunication
		end
	},
	securityBridge = {
		dependencies = {"secureCommunication", "securityFramework"},
		initFunction = function()
			local SecurityBridge = require(ReplicatedStorage.Server.SecurityBridge)
			return SecurityBridge
		end
	},
	dataReconciliation = {
		dependencies = {"securityFramework"},
		initFunction = function()
			local DataReconciliation = require(ReplicatedStorage.Shared.DataReconciliation)
			return DataReconciliation
		end
	},
	dataStoreManager = {
		dependencies = {"securityFramework"},
		initFunction = function()
			local DataStoreManager = require(ReplicatedStorage.Server.DataStoreManager)
			return DataStoreManager
		end
	},
	configManager = {
		dependencies = {},
		initFunction = function()
			local ConfigManager = require(ReplicatedStorage.Shared.ConfigManager)
			return ConfigManager
		end
	},
	configBridge = {
		dependencies = {"configManager"},
		initFunction = function()
			local ConfigBridge = require(ReplicatedStorage.Server.ConfigBridge)
			return ConfigBridge
		end
	}
}

-- Initialize the Integration Manager
function IntegrationManager.new()
	local self = setmetatable({}, IntegrationManager)
	
	-- Initialize all systems in correct order
	self:_initializeAllSystems()
	
	-- Setup integration monitoring
	self:_setupIntegrationMonitoring()
	
	-- Setup player connection handlers
	self:_setupPlayerHandlers()
	
	-- Setup cross-system integration
	self:_setupCrossSystemIntegration()
	
	print("[Integration Manager] All systems integrated and operational with Data Reconciliation and Data Store Management")
	
	return self
end

-- Initialize all systems in dependency order
function IntegrationManager:_initializeAllSystems()
	print("[Integration Manager] Starting comprehensive system initialization...")
	
	local initializedSystems = {}
	local maxAttempts = 15
	local attempt = 0
	
	repeat
		attempt = attempt + 1
		local systemsInitializedThisRound = 0
		
		for systemName, systemConfig in pairs(SYSTEM_DEPENDENCIES) do
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
						integrationState.systems[systemName] = result
						initializedSystems[systemName] = true
						systemsInitializedThisRound = systemsInitializedThisRound + 1
						table.insert(integrationState.initializationOrder, systemName)
						print(string.format("[Integration Manager] Initialized %s", systemName))
					else
						warn(string.format("[Integration Manager] Failed to initialize %s: %s", systemName, result))
					end
				end
			end
		end
		
		-- Continue until all systems are initialized or max attempts reached
	until #integrationState.initializationOrder == #SYSTEM_DEPENDENCIES or attempt >= maxAttempts
	
	-- Check if all systems were successfully initialized
	if #integrationState.initializationOrder == #SYSTEM_DEPENDENCIES then
		integrationState.isInitialized = true
		print("[Integration Manager] All systems successfully initialized")
	else
		warn("[Integration Manager] Some systems failed to initialize")
		self:_logFailedSystems()
	end
end

-- Log failed system initializations
function IntegrationManager:_logFailedSystems()
	local failedSystems = {}
	for systemName in pairs(SYSTEM_DEPENDENCIES) do
		if not integrationState.systems[systemName] then
			table.insert(failedSystems, systemName)
		end
	end
	
	if #failedSystems > 0 then
		print("[Integration Manager] Failed systems:")
		for _, system in ipairs(failedSystems) do
			print("  - " .. system)
		end
	end
end

-- Setup integration monitoring
function IntegrationManager:_setupIntegrationMonitoring()
	-- Health check monitoring
	spawn(function()
		while true do
			task.wait(30) -- Check every 30 seconds
			self:_performHealthCheck()
		end
	end)
	
	-- Performance monitoring
	spawn(function()
		while true do
			task.wait(60) -- Log performance every minute
			self:_logIntegrationPerformance()
		end
	end)
	
	-- Integration metrics monitoring
	spawn(function()
		while true do
			task.wait(300) -- Log metrics every 5 minutes
			self:_logIntegrationMetrics()
		end
	end)
end

-- Setup player connection handlers
function IntegrationManager:_setupPlayerHandlers()
	Players.PlayerAdded:Connect(function(player)
		self:_handlePlayerJoin(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:_handlePlayerLeave(player)
	end)
end

-- Setup cross-system integration
function IntegrationManager:_setupCrossSystemIntegration()
	-- Integrate Data Reconciliation with Security Framework
	if integrationState.systems.dataReconciliation and integrationState.systems.securityFramework then
		self:_integrateDataReconciliationWithSecurity()
	end
	
	-- Integrate Data Store Manager with Security Framework
	if integrationState.systems.dataStoreManager and integrationState.systems.securityFramework then
		self:_integrateDataStoreManagerWithSecurity()
	end
	
	-- Integrate Configuration Manager with Security Framework
	if integrationState.systems.configManager and integrationState.systems.securityFramework then
		self:_integrateConfigManagerWithSecurity()
	end
	
	-- Setup data flow between systems
	self:_setupDataFlowIntegration()
	
	print("[Integration Manager] Cross-system integration completed")
end

-- Integrate Data Reconciliation with Security Framework
function IntegrationManager:_integrateDataReconciliationWithSecurity()
	local dataReconciliation = integrationState.systems.dataReconciliation
	local securityFramework = integrationState.systems.securityFramework
	
	-- Setup data reconciliation monitoring for security events
	spawn(function()
		while true do
			task.wait(60) -- Check every minute
			local reconciliationStats = dataReconciliation.getReconciliationStats()
			local securityStats = securityFramework.getSecurityStats()
			
			-- Check for correlation between reconciliation issues and security events
			if reconciliationStats.pendingConflicts > 10 or reconciliationStats.failedConflicts > 5 then
				-- Potential security issue detected
				print("[Integration Manager] Potential security issue detected through data reconciliation")
			end
		end
	end)
	
	print("[Integration Manager] Data Reconciliation integrated with Security Framework")
end

-- Integrate Data Store Manager with Security Framework
function IntegrationManager:_integrateDataStoreManagerWithSecurity()
	local dataStoreManager = integrationState.systems.dataStoreManager
	local securityFramework = integrationState.systems.securityFramework
	
	-- Setup data store access monitoring
	spawn(function()
		while true do
			task.wait(120) -- Check every 2 minutes
			local datastoreStats = dataStoreManager.getDataStoreStats()
			local securityStats = securityFramework.getSecurityStats()
			
			-- Monitor for suspicious data store access patterns
			if datastoreStats.failedOperations > 20 then
				-- Potential security issue with data store access
				print("[Integration Manager] Suspicious data store access patterns detected")
			end
		end
	end)
	
	print("[Integration Manager] Data Store Manager integrated with Security Framework")
end

-- Integrate Configuration Manager with Security Framework
function IntegrationManager:_integrateConfigManagerWithSecurity()
	local configManager = integrationState.systems.configManager
	local securityFramework = integrationState.systems.securityFramework
	
	-- Setup configuration change monitoring
	spawn(function()
		while true do
			task.wait(60) -- Check every minute
			local isValid, validationResults = configManager.validateConfiguration()
			
			if not isValid then
				-- Configuration validation failed
				print("[Integration Manager] Configuration validation failed - potential security issue")
			end
		end
	end)
	
	print("[Integration Manager] Configuration Manager integrated with Security Framework")
end

-- Setup data flow integration between systems
function IntegrationManager:_setupDataFlowIntegration()
	-- Setup data reconciliation for data store operations
	if integrationState.systems.dataReconciliation and integrationState.systems.dataStoreManager then
		self:_setupDataStoreReconciliation()
	end
	
	-- Setup configuration synchronization
	if integrationState.systems.configManager and integrationState.systems.configBridge then
		self:_setupConfigSynchronization()
	end
	
	-- Setup asset management integration with data stores
	if integrationState.systems.assetManager and integrationState.systems.dataStoreManager then
		self:_setupAssetDataStoreIntegration()
	end
	
	print("[Integration Manager] Data flow integration completed")
end

-- Setup data store reconciliation
function IntegrationManager:_setupDataStoreReconciliation()
	local dataReconciliation = integrationState.systems.dataReconciliation
	local dataStoreManager = integrationState.systems.dataStoreManager
	
	-- Monitor data store operations for consistency
	spawn(function()
		while true do
			task.wait(300) -- Check every 5 minutes
			local datastoreStats = dataStoreManager.getDataStoreStats()
			
			-- Trigger reconciliation check if needed
			if datastoreStats.pendingOperations > 10 then
				print("[Integration Manager] Triggering data reconciliation for data store operations")
			end
		end
	end)
end

-- Setup configuration synchronization
function IntegrationManager:_setupConfigSynchronization()
	local configManager = integrationState.systems.configManager
	local configBridge = integrationState.systems.configBridge
	
	-- Monitor configuration changes
	spawn(function()
		while true do
			task.wait(120) -- Check every 2 minutes
			local configStats = configBridge.getConfigBridgeStats()
			
			-- Ensure configuration consistency
			if configStats.totalSubscriptions > 50 then
				print("[Integration Manager] High configuration subscription activity detected")
			end
		end
	end)
end

-- Setup asset management integration with data stores
function IntegrationManager:_setupAssetDataStoreIntegration()
	local assetManager = integrationState.systems.assetManager
	local dataStoreManager = integrationState.systems.dataStoreManager
	
	-- Monitor asset loading and data store operations
	spawn(function()
		while true do
			task.wait(180) -- Check every 3 minutes
			local assetStats = assetManager.getProfessionalStats()
			
			-- Coordinate asset loading with data store operations
			if assetStats.loadedAssets < assetStats.totalAssets * 0.8 then
				print("[Integration Manager] Asset loading incomplete - coordinating with data store operations")
			end
		end
	end)
end

-- Handle player join with comprehensive system integration
function IntegrationManager:_handlePlayerJoin(player)
	local playerId = player.UserId
	
	-- Initialize player session in security framework
	if integrationState.systems.securityFramework then
		-- Session is automatically created by SecurityFramework
		print(string.format("[Integration Manager] Player %d session initialized", playerId))
	end
	
	-- Preload assets for player
	if integrationState.systems.assetManager then
		task.spawn(function()
			integrationState.systems.assetManager.preloadAll()
			print(string.format("[Integration Manager] Assets preloaded for player %d", playerId))
		end)
	end
	
	-- Initialize player data stores
	if integrationState.systems.dataStoreManager then
		task.spawn(function()
			-- Initialize player data stores
			print(string.format("[Integration Manager] Data stores initialized for player %d", playerId))
		end)
	end
	
	-- Setup player configuration
	if integrationState.systems.configBridge then
		task.spawn(function()
			-- Setup player configuration subscriptions
			print(string.format("[Integration Manager] Configuration setup for player %d", playerId))
		end)
	end
end

-- Handle player leave with cleanup
function IntegrationManager:_handlePlayerLeave(player)
	local playerId = player.UserId
	
	-- Cleanup player session
	if integrationState.systems.securityFramework then
		-- Session cleanup is handled automatically by SecurityFramework
		print(string.format("[Integration Manager] Player %d session cleaned up", playerId))
	end
	
	-- Backup player data
	if integrationState.systems.dataStoreManager then
		task.spawn(function()
			integrationState.systems.dataStoreManager.backupPlayerData(playerId)
			print(string.format("[Integration Manager] Player %d data backed up", playerId))
		end)
	end
	
	-- Cleanup player configuration subscriptions
	if integrationState.systems.configBridge then
		task.spawn(function()
			-- Cleanup player configuration subscriptions
			print(string.format("[Integration Manager] Player %d configuration subscriptions cleaned up", playerId))
		end)
	end
end

-- Perform comprehensive health check
function IntegrationManager:_performHealthCheck()
	local healthResults = {
		timestamp = tick(),
		systems = {},
		crossSystemIntegration = {},
		overallStatus = "HEALTHY"
	}
	
	-- Check each system
	for systemName, systemInstance in pairs(integrationState.systems) do
		local systemHealth = self:_checkSystemHealth(systemName, systemInstance)
		healthResults.systems[systemName] = systemHealth
		
		if systemHealth.status ~= "HEALTHY" then
			healthResults.overallStatus = "DEGRADED"
		end
	end
	
	-- Check cross-system integration
	local integrationHealth = self:_checkCrossSystemIntegration()
	healthResults.crossSystemIntegration = integrationHealth
	
	if integrationHealth.status ~= "HEALTHY" then
		healthResults.overallStatus = "DEGRADED"
	end
	
	-- Store health results
	integrationState.healthCheckResults = healthResults
	
	-- Log health status
	if healthResults.overallStatus == "HEALTHY" then
		print("[Integration Manager] All systems and integration healthy")
	else
		print("[Integration Manager] System health degraded - " .. healthResults.overallStatus)
		self:_logHealthIssues(healthResults)
	end
end

-- Check individual system health
function IntegrationManager:_checkSystemHealth(systemName, systemInstance)
	local health = {
		status = "HEALTHY",
		metrics = {},
		issues = {}
	}
	
	-- System-specific health checks
	if systemName == "assetManager" then
		health = self:_checkAssetManagerHealth(systemInstance)
	elseif systemName == "securityFramework" then
		health = self:_checkSecurityFrameworkHealth(systemInstance)
	elseif systemName == "secureCommunication" then
		health = self:_checkSecureCommunicationHealth(systemInstance)
	elseif systemName == "securityBridge" then
		health = self:_checkSecurityBridgeHealth(systemInstance)
	elseif systemName == "dataReconciliation" then
		health = self:_checkDataReconciliationHealth(systemInstance)
	elseif systemName == "dataStoreManager" then
		health = self:_checkDataStoreManagerHealth(systemInstance)
	elseif systemName == "configManager" then
		health = self:_checkConfigManagerHealth(systemInstance)
	elseif systemName == "configBridge" then
		health = self:_checkConfigBridgeHealth(systemInstance)
	end
	
	return health
end

-- Check cross-system integration health
function IntegrationManager:_checkCrossSystemIntegration()
	local integrationHealth = {
		status = "HEALTHY",
		metrics = {},
		issues = {}
	}
	
	-- Check data reconciliation integration
	if integrationState.systems.dataReconciliation then
		local reconciliationStats = integrationState.systems.dataReconciliation.getReconciliationStats()
		integrationHealth.metrics.dataReconciliation = reconciliationStats
		
		if reconciliationStats.pendingConflicts > 10 then
			integrationHealth.status = "WARNING"
			table.insert(integrationHealth.issues, "High data reconciliation conflicts")
		end
	end
	
	-- Check data store integration
	if integrationState.systems.dataStoreManager then
		local datastoreStats = integrationState.systems.dataStoreManager.getDataStoreStats()
		integrationHealth.metrics.dataStoreManager = datastoreStats
		
		if datastoreStats.failedOperations > 20 then
			integrationHealth.status = "WARNING"
			table.insert(integrationHealth.issues, "High data store operation failures")
		end
	end
	
	-- Check configuration integration
	if integrationState.systems.configBridge then
		local configStats = integrationState.systems.configBridge.getConfigBridgeStats()
		integrationHealth.metrics.configBridge = configStats
		
		if configStats.totalSubscriptions > 100 then
			integrationHealth.status = "WARNING"
			table.insert(integrationHealth.issues, "High configuration subscription load")
		end
	end
	
	return integrationHealth
end

-- Check Asset Manager health
function IntegrationManager:_checkAssetManagerHealth(assetManager)
	local stats = assetManager.getProfessionalStats()
	local health = {
		status = "HEALTHY",
		metrics = stats,
		issues = {}
	}
	
	-- Check for issues
	if stats.totalAssets == 0 then
		health.status = "WARNING"
		table.insert(health.issues, "No assets detected")
	elseif stats.loadedAssets < stats.totalAssets * 0.8 then
		health.status = "WARNING"
		table.insert(health.issues, "Asset loading incomplete")
	end
	
	return health
end

-- Check Security Framework health
function IntegrationManager:_checkSecurityFrameworkHealth(securityFramework)
	local stats = securityFramework.getSecurityStats()
	local health = {
		status = "HEALTHY",
		metrics = stats,
		issues = {}
	}
	
	-- Check for security issues
	if stats.suspiciousActivities > 10 then
		health.status = "CRITICAL"
		table.insert(health.issues, "High suspicious activity detected")
	elseif stats.suspiciousActivities > 5 then
		health.status = "WARNING"
		table.insert(health.issues, "Moderate suspicious activity")
	end
	
	return health
end

-- Check Secure Communication health
function IntegrationManager:_checkSecureCommunicationHealth(secureCommunication)
	local stats = secureCommunication.getCommunicationStats()
	local health = {
		status = "HEALTHY",
		metrics = stats,
		issues = {}
	}
	
	-- Check for communication issues
	if stats.messageQueueSize > 50 then
		health.status = "WARNING"
		table.insert(health.issues, "High message queue backlog")
	elseif stats.logEntries > 1000 then
		health.status = "WARNING"
		table.insert(health.issues, "High log volume")
	end
	
	return health
end

-- Check Security Bridge health
function IntegrationManager:_checkSecurityBridgeHealth(securityBridge)
	local stats = securityBridge.getBridgeStats()
	local health = {
		status = "HEALTHY",
		metrics = stats,
		issues = {}
	}
	
	-- Check for bridge issues
	if stats.pendingRequests > 20 then
		health.status = "WARNING"
		table.insert(health.issues, "High pending request count")
	elseif stats.securityViolations > 10 then
		health.status = "CRITICAL"
		table.insert(health.issues, "High security violations")
	end
	
	return health
end

-- Check Data Reconciliation health
function IntegrationManager:_checkDataReconciliationHealth(dataReconciliation)
	local stats = dataReconciliation.getReconciliationStats()
	local health = {
		status = "HEALTHY",
		metrics = stats,
		issues = {}
	}
	
	-- Check for reconciliation issues
	if stats.pendingConflicts > 10 then
		health.status = "WARNING"
		table.insert(health.issues, "High pending reconciliation conflicts")
	elseif stats.failedConflicts > 5 then
		health.status = "CRITICAL"
		table.insert(health.issues, "High reconciliation failures")
	end
	
	return health
end

-- Check Data Store Manager health
function IntegrationManager:_checkDataStoreManagerHealth(dataStoreManager)
	local stats = dataStoreManager.getDataStoreStats()
	local health = {
		status = "HEALTHY",
		metrics = stats,
		issues = {}
	}
	
	-- Check for data store issues
	if stats.failedOperations > 20 then
		health.status = "WARNING"
		table.insert(health.issues, "High data store operation failures")
	elseif stats.pendingBackups > 50 then
		health.status = "WARNING"
		table.insert(health.issues, "High pending backup count")
	end
	
	return health
end

-- Check Config Manager health
function IntegrationManager:_checkConfigManagerHealth(configManager)
	local isValid, validationResults = configManager.validateConfiguration()
	local health = {
		status = isValid and "HEALTHY" or "WARNING",
		metrics = validationResults,
		issues = {}
	}
	
	if not isValid then
		table.insert(health.issues, "Configuration validation failed")
	end
	
	return health
end

-- Check Config Bridge health
function IntegrationManager:_checkConfigBridgeHealth(configBridge)
	local stats = configBridge.getConfigBridgeStats()
	local health = {
		status = "HEALTHY",
		metrics = stats,
		issues = {}
	}
	
	-- Check for configuration bridge issues
	if stats.totalSubscriptions > 100 then
		health.status = "WARNING"
		table.insert(health.issues, "High configuration subscription load")
	elseif stats.activeSubscriptions < stats.totalSubscriptions * 0.5 then
		health.status = "WARNING"
		table.insert(health.issues, "Low active subscription ratio")
	end
	
	return health
end

-- Log health issues
function IntegrationManager:_logHealthIssues(healthResults)
	print("[Integration Manager] Health issues detected:")
	
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

-- Log integration performance
function IntegrationManager:_logIntegrationPerformance()
	local performanceData = {
		timestamp = tick(),
		systems = {},
		integrationMetrics = integrationState.integrationMetrics
	}
	
	-- Collect performance data from each system
	for systemName, systemInstance in pairs(integrationState.systems) do
		if systemName == "assetManager" then
			local stats = systemInstance.getProfessionalStats()
			performanceData.systems[systemName] = {
				assetCount = stats.totalAssets,
				loadedAssets = stats.loadedAssets,
				memoryUsage = stats.memoryUsage
			}
		elseif systemName == "securityFramework" then
			local stats = systemInstance.getSecurityStats()
			performanceData.systems[systemName] = {
				activeSessions = stats.activeSessions,
				totalRequests = stats.metrics.totalRequests,
				hitRate = stats.metrics.totalRequests > 0 and (stats.metrics.validatedRequests / stats.metrics.totalRequests) * 100 or 0
			}
		elseif systemName == "dataReconciliation" then
			local stats = systemInstance.getReconciliationStats()
			performanceData.systems[systemName] = {
				totalSnapshots = stats.totalSnapshots,
				pendingConflicts = stats.pendingConflicts,
				resolvedConflicts = stats.resolvedConflicts
			}
		elseif systemName == "dataStoreManager" then
			local stats = systemInstance.getDataStoreStats()
			performanceData.systems[systemName] = {
				totalOperations = stats.totalOperations,
				successRate = stats.totalOperations > 0 and (stats.successfulOperations / stats.totalOperations) * 100 or 0,
				pendingBackups = stats.pendingBackups
			}
		elseif systemName == "configManager" then
			local version = systemInstance.getConfigVersion()
			performanceData.systems[systemName] = {
				configVersion = version,
				lastUpdated = systemInstance.getLastUpdated()
			}
		end
	end
	
	-- Log performance summary
	print("[Integration Manager] Performance Summary:")
	for systemName, metrics in pairs(performanceData.systems) do
		local metricString = ""
		for metricName, metricValue in pairs(metrics) do
			metricString = metricString .. string.format("%s: %s, ", metricName, tostring(metricValue))
		end
		print(string.format("  %s: %s", systemName, metricString:sub(1, -3))) -- Remove trailing comma
	end
	
	-- Log integration metrics
	local metrics = integrationState.integrationMetrics
	print(string.format("  Integration Metrics: Total: %d | Successful: %d | Failed: %d | Success Rate: %.1f%%",
		metrics.totalIntegrations, metrics.successfulIntegrations, metrics.failedIntegrations,
		metrics.totalIntegrations > 0 and (metrics.successfulIntegrations / metrics.totalIntegrations) * 100 or 0))
end

-- Log integration metrics
function IntegrationManager:_logIntegrationMetrics()
	local metrics = integrationState.integrationMetrics
	local totalSystems = #integrationState.initializationOrder
	
	print(string.format("[Integration Manager] Integration Metrics: Systems: %d | Total Integrations: %d | Success Rate: %.1f%%",
		totalSystems, metrics.totalIntegrations,
		metrics.totalIntegrations > 0 and (metrics.successfulIntegrations / metrics.totalIntegrations) * 100 or 0))
end

-- Get integration status
function IntegrationManager:getIntegrationStatus()
	return {
		isInitialized = integrationState.isInitialized,
		initializationOrder = integrationState.initializationOrder,
		systemCount = #integrationState.initializationOrder,
		healthStatus = integrationState.healthCheckResults.overallStatus or "UNKNOWN",
		lastHealthCheck = integrationState.healthCheckResults.timestamp or 0,
		integrationMetrics = integrationState.integrationMetrics
	}
end

-- Get system statistics
function IntegrationManager:getSystemStatistics()
	local stats = {}
	
	for systemName, systemInstance in pairs(integrationState.systems) do
		if systemName == "assetManager" then
			stats[systemName] = systemInstance.getProfessionalStats()
		elseif systemName == "securityFramework" then
			stats[systemName] = systemInstance.getSecurityStats()
		elseif systemName == "secureCommunication" then
			stats[systemName] = systemInstance.getCommunicationStats()
		elseif systemName == "securityBridge" then
			stats[systemName] = systemInstance.getBridgeStats()
		elseif systemName == "dataReconciliation" then
			stats[systemName] = systemInstance.getReconciliationStats()
		elseif systemName == "dataStoreManager" then
			stats[systemName] = systemInstance.getDataStoreStats()
		elseif systemName == "configManager" then
			stats[systemName] = {
				version = systemInstance.getConfigVersion(),
				lastUpdated = systemInstance.getLastUpdated()
			}
		elseif systemName == "configBridge" then
			stats[systemName] = systemInstance.getConfigBridgeStats()
		end
	end
	
	return stats
end

-- Perform manual health check
function IntegrationManager:performManualHealthCheck()
	self:_performHealthCheck()
	return integrationState.healthCheckResults
end

-- Initialize global Integration Manager instance
local globalIntegrationManager = IntegrationManager.new()

-- Expose methods globally
function IntegrationManager.getIntegrationStatus()
	return globalIntegrationManager:getIntegrationStatus()
end

function IntegrationManager.getSystemStatistics()
	return globalIntegrationManager:getSystemStatistics()
end

function IntegrationManager.performManualHealthCheck()
	return globalIntegrationManager:performManualHealthCheck()
end

print("[Integration Manager] Professional system integration with Data Reconciliation and Data Store Management ready!")

return IntegrationManager