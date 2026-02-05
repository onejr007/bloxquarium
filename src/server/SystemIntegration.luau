-- System Integration Manager v1.0
-- Professional integration system that coordinates State-Based Replication,
-- Data Migration, and Leaderboard Store systems
-- Provides unified interface and cross-system coordination

local StateReplication = require(game:GetService("ReplicatedStorage").Shared.StateReplication)
local DataMigration = require(game:GetService("ServerScriptService").Server.DataMigration)
local LeaderboardStore = require(game:GetService("ServerScriptService").Server.LeaderboardStore)
local DataStoreManager = require(game:GetService("ServerScriptService").Server.DataStoreManager)
local DataReconciliation = require(game:GetService("ReplicatedStorage").Shared.DataReconciliation)

local SystemIntegration = {}
SystemIntegration.__index = SystemIntegration

-- Integration configuration
local INTEGRATION_CONFIG = {
	ENABLE_CROSS_SYSTEM_VALIDATION = true,
	ENABLE_UNIFIED_MONITORING = true,
	ENABLE_AUTO_MIGRATION_TRIGGER = true,
	ENABLE_LEADERBOARD_REPLICATION = true
}

-- Integration state
local integrationState = {
	systems = {
		stateReplication = StateReplication,
		dataMigration = DataMigration,
		leaderboardStore = LeaderboardStore,
		dataStoreManager = DataStoreManager,
		dataReconciliation = DataReconciliation
	},
	integrationHooks = {},
	crossSystemEvents = {},
	monitoringData = {}
}

-- Integration event structure
local IntegrationEvent = {
	__index = IntegrationEvent
}

function IntegrationEvent.new(eventType, sourceSystem, data, timestamp)
	local self = setmetatable({}, IntegrationEvent)
	self.eventType = eventType
	self.sourceSystem = sourceSystem
	self.data = data
	self.timestamp = timestamp or tick()
	self.processed = false
	return self
end

-- Initialize the System Integration Manager
function SystemIntegration.new()
	local self = setmetatable({}, SystemIntegration)
	
	-- Setup integration monitoring
	self:_setupIntegrationMonitoring()
	
	-- Setup cross-system coordination
	self:_setupCrossSystemCoordination()
	
	-- Setup unified event handling
	self:_setupUnifiedEventHandling()
	
	-- Register integration hooks
	self:_registerIntegrationHooks()
	
	print("[System Integration] Initialized with professional-grade system coordination")
	
	return self
end

-- Setup integration monitoring
function SystemIntegration:_setupIntegrationMonitoring()
	if not INTEGRATION_CONFIG.ENABLE_UNIFIED_MONITORING then
		return
	end
	
	-- Monitor all systems health
	spawn(function()
		while true do
			task.wait(60) -- Check every minute
			self:_performUnifiedHealthCheck()
		end
	end)
end

-- Setup cross-system coordination
function SystemIntegration:_setupCrossSystemCoordination()
	-- Coordinate data migration with state replication
	if INTEGRATION_CONFIG.ENABLE_AUTO_MIGRATION_TRIGGER then
		spawn(function()
			while true do
				task.wait(300) -- Check every 5 minutes
				self:_checkMigrationTriggers()
			end
		end)
	end
	
	-- Coordinate leaderboard updates with state replication
	if INTEGRATION_CONFIG.ENABLE_LEADERBOARD_REPLICATION then
		spawn(function()
			while true do
				task.wait(10) -- Update leaderboard replication every 10 seconds
				self:_updateLeaderboardReplication()
			end
		end)
	end
end

-- Setup unified event handling
function SystemIntegration:_setupUnifiedEventHandling()
	-- Process cross-system events
	spawn(function()
		while true do
			task.wait(5) -- Process events every 5 seconds
			self:_processCrossSystemEvents()
		end
	end)
end

-- Register integration hooks
function SystemIntegration:_registerIntegrationHooks()
	-- Hook into data migration events
	self:_registerMigrationHooks()
	
	-- Hook into leaderboard events
	self:_registerLeaderboardHooks()
	
	-- Hook into state replication events
	self:_registerReplicationHooks()
end

-- Register migration hooks
function SystemIntegration:_registerMigrationHooks()
	-- Hook into migration completion
	local originalApplyPendingMigrations = DataMigration.applyPendingMigrations
	DataMigration.applyPendingMigrations = function(...)
		local result = {originalApplyPendingMigrations(...)}
		
		-- Trigger integration event
		self:_triggerIntegrationEvent("MIGRATION_COMPLETED", "DATA_MIGRATION", {
			applied = result[1].applied,
			failed = result[1].failed
		})
		
		return unpack(result)
	end
	
	-- Hook into migration registration
	local originalRegisterMigration = DataMigration.registerMigration
	DataMigration.registerMigration = function(...)
		local result = {originalRegisterMigration(...)}
		
		-- Trigger integration event
		self:_triggerIntegrationEvent("MIGRATION_REGISTERED", "DATA_MIGRATION", {
			success = result[1],
			message = result[2]
		})
		
		return unpack(result)
	end
end

-- Register leaderboard hooks
function SystemIntegration:_registerLeaderboardHooks()
	-- Hook into leaderboard updates
	local originalUpdatePlayerScore = LeaderboardStore.updatePlayerScore
	LeaderboardStore.updatePlayerScore = function(...)
		local result = {originalUpdatePlayerScore(...)}
		
		-- Trigger integration event
		self:_triggerIntegrationEvent("LEADERBOARD_UPDATED", "LEADERBOARD_STORE", {
			success = result[1],
			data = result[2]
		})
		
		return unpack(result)
	end
	
	-- Hook into leaderboard creation
	local originalCreateLeaderboard = LeaderboardStore.createLeaderboard
	LeaderboardStore.createLeaderboard = function(...)
		local result = {originalCreateLeaderboard(...)}
		
		-- Trigger integration event
		self:_triggerIntegrationEvent("LEADERBOARD_CREATED", "LEADERBOARD_STORE", {
			success = result[1],
			leaderboard = result[2]
		})
		
		return unpack(result)
	end
end

-- Register replication hooks
function SystemIntegration:_registerReplicationHooks()
	-- Hook into entity creation
	local originalCreateEntity = StateReplication.createEntity
	StateReplication.createEntity = function(...)
		local result = {originalCreateEntity(...)}
		
		-- Trigger integration event
		self:_triggerIntegrationEvent("ENTITY_CREATED", "STATE_REPLICATION", {
			success = result[1],
			entity = result[2]
		})
		
		return unpack(result)
	end
	
	-- Hook into entity updates
	local originalUpdateEntity = StateReplication.updateEntity
	StateReplication.updateEntity = function(...)
		local result = {originalUpdateEntity(...)}
		
		-- Trigger integration event
		self:_triggerIntegrationEvent("ENTITY_UPDATED", "STATE_REPLICATION", {
			success = result[1],
			version = result[2]
		})
		
		return unpack(result)
	end
end

-- Trigger integration event
function SystemIntegration:_triggerIntegrationEvent(eventType, sourceSystem, data)
	local event = IntegrationEvent.new(eventType, sourceSystem, data)
	table.insert(integrationState.crossSystemEvents, event)
	
	-- Process event immediately if possible
	self:_processIntegrationEvent(event)
end

-- Process cross-system events
function SystemIntegration:_processCrossSystemEvents()
	if #integrationState.crossSystemEvents == 0 then
		return
	end
	
	for i = #integrationState.crossSystemEvents, 1, -1 do
		local event = integrationState.crossSystemEvents[i]
		
		if not event.processed then
			self:_processIntegrationEvent(event)
			event.processed = true
		end
	end
end

-- Process integration event
function SystemIntegration:_processIntegrationEvent(event)
	if event.eventType == "MIGRATION_COMPLETED" then
		self:_handleMigrationCompleted(event)
	elseif event.eventType == "LEADERBOARD_UPDATED" then
		self:_handleLeaderboardUpdated(event)
	elseif event.eventType == "ENTITY_CREATED" then
		self:_handleEntityCreated(event)
	elseif event.eventType == "ENTITY_UPDATED" then
		self:_handleEntityUpdated(event)
	end
end

-- Handle migration completed event
function SystemIntegration:_handleMigrationCompleted(event)
	local data = event.data
	
	-- Trigger data reconciliation for affected players
	if #data.applied > 0 then
		for _, playerId in pairs(Players:GetPlayers()) do
			DataReconciliation.forceReconciliation(playerId)
		end
		
		print("[System Integration] Triggered data reconciliation after migration")
	end
	
	-- Update state replication with new schema
	self:_updateReplicationSchema()
end

-- Handle leaderboard updated event
function SystemIntegration:_handleLeaderboardUpdated(event)
	if not INTEGRATION_CONFIG.ENABLE_LEADERBOARD_REPLICATION then
		return
	end
	
	local data = event.data
	if data.success and data.data then
		-- Replicate leaderboard changes to clients
		self:_replicateLeaderboardUpdate(data.data)
	end
end

-- Handle entity created event
function SystemIntegration:_handleEntityCreated(event)
	local data = event.data
	if data.success and data.entity then
		-- Create corresponding leaderboard entry if needed
		self:_createLeaderboardEntryForEntity(data.entity)
	end
end

-- Handle entity updated event
function SystemIntegration:_handleEntityUpdated(event)
	local data = event.data
	if data.success and data.version then
		-- Update corresponding leaderboard entry if needed
		self:_updateLeaderboardEntryForEntity(data.version)
	end
end

-- Check migration triggers
function SystemIntegration:_checkMigrationTriggers()
	-- Check if migrations are needed based on system state
	local migrationStats = DataMigration.getMigrationStats()
	
	if migrationStats.pendingMigrations > 0 then
		print("[System Integration] Detected pending migrations, triggering application")
		
		-- Apply pending migrations
		local result = DataMigration.applyPendingMigrations()
		
		if #result.applied > 0 then
			print(string.format("[System Integration] Applied %d migrations", #result.applied))
		end
	end
end

-- Update leaderboard replication
function SystemIntegration:_updateLeaderboardReplication()
	if not INTEGRATION_CONFIG.ENABLE_LEADERBOARD_REPLICATION then
		return
	end
	
	-- Get top players from all leaderboards
	local leaderboards = LeaderboardStore.getLeaderboardStats()
	
	for name, _ in pairs(LeaderboardStore.getLeaderboardStats()) do
		local topPlayers = LeaderboardStore.getTopPlayers(name, 10)
		
		if topPlayers then
			-- Replicate leaderboard data as state entities
			self:_replicateLeaderboardAsState(name, topPlayers)
		end
	end
end

-- Replicate leaderboard update
function SystemIntegration:_replicateLeaderboardUpdate(data)
	-- Create or update leaderboard entity in state replication
	local entityId = "leaderboard_" .. data.leaderboardName
	local entityType = "LEADERBOARD_UPDATE"
	
	local success, result = StateReplication.createEntity(entityId, entityType, {
		leaderboardName = data.leaderboardName,
		playerId = data.playerId,
		newValue = data.newValue,
		oldValue = data.oldValue,
		change = data.change,
		timestamp = tick()
	})
	
	if success then
		print(string.format("[System Integration] Replicated leaderboard update for %s", data.leaderboardName))
	end
end

-- Replicate leaderboard as state
function SystemIntegration:_replicateLeaderboardAsState(leaderboardName, topPlayers)
	local entityId = "leaderboard_state_" .. leaderboardName
	local entityType = "LEADERBOARD_STATE"
	
	local success, result = StateReplication.createEntity(entityId, entityType, {
		leaderboardName = leaderboardName,
		topPlayers = topPlayers,
		timestamp = tick()
	})
	
	if success then
		print(string.format("[System Integration] Replicated leaderboard state for %s", leaderboardName))
	end
end

-- Create leaderboard entry for entity
function SystemIntegration:_createLeaderboardEntryForEntity(entity)
	-- In a real implementation, this would create leaderboard entries
	-- based on entity data (e.g., player scores, achievements, etc.)
end

-- Update leaderboard entry for entity
function SystemIntegration:_updateLeaderboardEntryForEntity(version)
	-- In a real implementation, this would update leaderboard entries
	-- based on entity version changes
end

-- Update replication schema
function SystemIntegration:_updateReplicationSchema()
	-- In a real implementation, this would update state replication
	-- schema based on migration results
end

-- Perform unified health check
function SystemIntegration:_performUnifiedHealthCheck()
	if not INTEGRATION_CONFIG.ENABLE_UNIFIED_MONITORING then
		return
	end
	
	-- Get stats from all systems
	local stateReplicationStats = StateReplication.getReplicationStats()
	local dataMigrationStats = DataMigration.getMigrationStats()
	local leaderboardStats = LeaderboardStore.getLeaderboardStats()
	local dataStoreStats = DataStoreManager.getDataStoreStats()
	local reconciliationStats = DataReconciliation.getReconciliationStats()
	
	-- Calculate overall health
	local overallHealth = {
		timestamp = tick(),
		stateReplication = stateReplicationStats,
		dataMigration = dataMigrationStats,
		leaderboardStore = leaderboardStats,
		dataStoreManager = dataStoreStats,
		dataReconciliation = reconciliationStats,
		crossSystemEvents = #integrationState.crossSystemEvents
	}
	
	-- Store monitoring data
	table.insert(integrationState.monitoringData, overallHealth)
	
	-- Keep only recent monitoring data
	if #integrationState.monitoringData > 1000 then
		table.remove(integrationState.monitoringData, 1)
	end
	
	-- Log unified health status
	print(string.format(
		"[System Integration] Unified Health Check: SR Entities: %d | DM Migrations: %d | LB Leaderboards: %d | DS Operations: %d | DR Conflicts: %d",
		stateReplicationStats.totalEntities,
		dataMigrationStats.appliedMigrations,
		leaderboardStats.totalLeaderboards,
		dataStoreStats.totalOperations,
		reconciliationStats.pendingConflicts
	))
	
	-- Check for system issues
	self:_checkSystemIssues(overallHealth)
end

-- Check system issues
function SystemIntegration:_checkSystemIssues(healthData)
	local issues = {}
	
	-- Check state replication issues
	if healthData.stateReplication.totalConflicts > 10 then
		table.insert(issues, "High state replication conflict count")
	end
	
	-- Check data migration issues
	if healthData.dataMigration.failedMigrations > 0 then
		table.insert(issues, "Failed data migrations detected")
	end
	
	-- Check leaderboard issues
	if healthData.leaderboardStore.totalEntries == 0 then
		table.insert(issues, "No leaderboard entries found")
	end
	
	-- Check data store issues
	if healthData.dataStoreManager.failedOperations > 100 then
		table.insert(issues, "High data store failure rate")
	end
	
	-- Check reconciliation issues
	if healthData.dataReconciliation.pendingConflicts > 50 then
		table.insert(issues, "High data reconciliation conflict count")
	end
	
	-- Log issues
	if #issues > 0 then
		for _, issue in ipairs(issues) do
			warn("[System Integration] Issue detected: " .. issue)
		end
	else
		print("[System Integration] All systems healthy")
	end
end

-- Get unified system statistics
function SystemIntegration:getUnifiedStats()
	local stats = {
		timestamp = tick(),
		stateReplication = StateReplication.getReplicationStats(),
		dataMigration = DataMigration.getMigrationStats(),
		leaderboardStore = LeaderboardStore.getLeaderboardStats(),
		dataStoreManager = DataStoreManager.getDataStoreStats(),
		dataReconciliation = DataReconciliation.getReconciliationStats(),
		integrationEvents = #integrationState.crossSystemEvents,
		monitoringDataPoints = #integrationState.monitoringData
	}
	
	return stats
end

-- Get system health report
function SystemIntegration:getHealthReport()
	local stats = self:getUnifiedStats()
	
	local healthReport = {
		timestamp = stats.timestamp,
		overallHealth = "HEALTHY",
		systems = {},
		recommendations = {}
	}
	
	-- Analyze each system
	if stats.stateReplication.totalConflicts > 10 then
		healthReport.systems.stateReplication = "ISSUES_DETECTED"
		table.insert(healthReport.recommendations, "Investigate state replication conflicts")
	else
		healthReport.systems.stateReplication = "HEALTHY"
	end
	
	if stats.dataMigration.failedMigrations > 0 then
		healthReport.systems.dataMigration = "ISSUES_DETECTED"
		table.insert(healthReport.recommendations, "Review failed migrations")
	else
		healthReport.systems.dataMigration = "HEALTHY"
	end
	
	if stats.leaderboardStore.totalEntries == 0 then
		healthReport.systems.leaderboardStore = "ISSUES_DETECTED"
		table.insert(healthReport.recommendations, "Check leaderboard data population")
	else
		healthReport.systems.leaderboardStore = "HEALTHY"
	end
	
	if stats.dataStoreManager.failedOperations > 100 then
		healthReport.systems.dataStoreManager = "ISSUES_DETECTED"
		table.insert(healthReport.recommendations, "Review data store error rates")
	else
		healthReport.systems.dataStoreManager = "HEALTHY"
	end
	
	if stats.dataReconciliation.pendingConflicts > 50 then
		healthReport.systems.dataReconciliation = "ISSUES_DETECTED"
		table.insert(healthReport.recommendations, "Investigate data reconciliation conflicts")
	else
		healthReport.systems.dataReconciliation = "HEALTHY"
	end
	
	-- Determine overall health
	for system, status in pairs(healthReport.systems) do
		if status == "ISSUES_DETECTED" then
			healthReport.overallHealth = "ISSUES_DETECTED"
			break
		end
	end
	
	return healthReport
end

-- Force system synchronization
function SystemIntegration:forceSystemSynchronization()
	print("[System Integration] Forcing system synchronization...")
	
	-- Force data reconciliation
	for _, player in ipairs(Players:GetPlayers()) do
		DataReconciliation.forceReconciliation(player.UserId)
	end
	
	-- Force state replication updates
	StateReplication.forceSynchronization(0) -- 0 means all players
	
	-- Force cache updates
	LeaderboardStore.forceCacheUpdate()
	
	-- Trigger migration check
	self:_checkMigrationTriggers()
	
	return true, "System synchronization initiated"
end

-- Initialize global System Integration instance
local globalSystemIntegration = SystemIntegration.new()

-- Expose methods globally
function SystemIntegration.getUnifiedStats()
	return globalSystemIntegration:getUnifiedStats()
end

function SystemIntegration.getHealthReport()
	return globalSystemIntegration:getHealthReport()
end

function SystemIntegration.forceSystemSynchronization()
	return globalSystemIntegration:forceSystemSynchronization()
end

print("[System Integration] Professional system integration manager ready!")

return SystemIntegration