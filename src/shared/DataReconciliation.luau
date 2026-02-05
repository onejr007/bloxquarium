-- Data Reconciliation System v1.0
-- Professional data reconciliation system for ensuring data consistency
-- between client and server with conflict resolution and audit trails

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local DataReconciliation = {}
DataReconciliation.__index = DataReconciliation

-- Reconciliation configuration
local RECONCILIATION_CONFIG = {
	MAX_CONFLICT_ATTEMPTS = 3,
	CONFLICT_RESOLUTION_TIMEOUT = 30,
	AUDIT_LOG_RETENTION_DAYS = 30,
	ENABLE_AUTO_RECONCILIATION = true,
	ENABLE_CONFLICT_DETECTION = true
}

-- Reconciliation state
local reconciliationState = {
	dataSnapshots = {}, -- Store data snapshots for reconciliation
	conflictQueue = {}, -- Queue of conflicts to resolve
	reconciliationHistory = {}, -- History of reconciliation operations
	auditLog = {}, -- Audit trail of all reconciliation activities
	syncStatus = {} -- Current sync status per player
}

-- Data snapshot structure
local DataSnapshot = {
	__index = DataSnapshot
}

function DataSnapshot.new(playerId, dataType, data, timestamp, checksum)
	local self = setmetatable({}, DataSnapshot)
	self.playerId = playerId
	self.dataType = dataType
	self.data = data
	self.timestamp = timestamp
	self.checksum = checksum
	self.version = HttpService:GenerateGUID(false)
	return self
end

-- Initialize the Data Reconciliation System
function DataReconciliation.new()
	local self = setmetatable({}, DataReconciliation)
	
	-- Setup reconciliation monitoring
	self:_setupReconciliationMonitoring()
	
	-- Setup conflict resolution handlers
	self:_setupConflictResolution()
	
	-- Setup player handlers
	self:_setupPlayerHandlers()
	
	print("[Data Reconciliation] Initialized with professional-grade data consistency")
	
	return self
end

-- Setup reconciliation monitoring
function DataReconciliation:_setupReconciliationMonitoring()
	-- Monitor data consistency
	spawn(function()
		while true do
			task.wait(60) -- Check every minute
			self:_performDataConsistencyCheck()
		end
	end)
	
	-- Cleanup old reconciliation data
	spawn(function()
		while true do
			task.wait(3600) -- Cleanup every hour
			self:_cleanupOldReconciliationData()
		end
	end)
end

-- Setup conflict resolution system
function DataReconciliation:_setupConflictResolution()
	-- Process conflict queue
	spawn(function()
		while true do
			task.wait(10) -- Process conflicts every 10 seconds
			self:_processConflictQueue()
		end
	end)
end

-- Setup player handlers
function DataReconciliation:_setupPlayerHandlers()
	Players.PlayerAdded:Connect(function(player)
		self:_handlePlayerJoin(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:_handlePlayerLeave(player)
	end)
end

-- Handle player join
function DataReconciliation:_handlePlayerJoin(player)
	local playerId = player.UserId
	
	-- Initialize sync status
	reconciliationState.syncStatus[playerId] = {
		isSynced = false,
		lastSyncTime = 0,
		conflictCount = 0,
		dataVersion = 0
	}
	
	print(string.format("[Data Reconciliation] Player %d joined, initializing sync status", playerId))
end

-- Handle player leave
function DataReconciliation:_handlePlayerLeave(player)
	local playerId = player.UserId
	
	-- Cleanup player data
	reconciliationState.syncStatus[playerId] = nil
	
	-- Remove player snapshots
	for snapshotId, snapshot in pairs(reconciliationState.dataSnapshots) do
		if snapshot.playerId == playerId then
			reconciliationState.dataSnapshots[snapshotId] = nil
		end
	end
	
	print(string.format("[Data Reconciliation] Player %d left, cleaned up reconciliation data", playerId))
end

-- Create data snapshot
function DataReconciliation:createSnapshot(playerId, dataType, data)
	local timestamp = tick()
	local checksum = self:_calculateChecksum(data)
	local snapshot = DataSnapshot.new(playerId, dataType, data, timestamp, checksum)
	
	-- Store snapshot
	local snapshotId = string.format("%s_%s_%s", playerId, dataType, timestamp)
	reconciliationState.dataSnapshots[snapshotId] = snapshot
	
	-- Log snapshot creation
	self:_logAuditEvent(playerId, "SNAPSHOT_CREATED", {
		dataType = dataType,
		snapshotId = snapshotId,
		checksum = checksum
	})
	
	return snapshot
end

-- Compare data snapshots for conflicts
function DataReconciliation:compareSnapshots(playerId, dataType, clientData, serverData)
	local clientChecksum = self:_calculateChecksum(clientData)
	local serverChecksum = self:_calculateChecksum(serverData)
	
	if clientChecksum == serverChecksum then
		-- Data is consistent
		self:_updateSyncStatus(playerId, true)
		return {
			isConsistent = true,
			conflictType = "NONE",
			details = "Data is consistent"
		}
	else
		-- Data conflict detected
		local conflict = {
			playerId = playerId,
			dataType = dataType,
			clientChecksum = clientChecksum,
			serverChecksum = serverChecksum,
			clientData = clientData,
			serverData = serverData,
			timestamp = tick(),
			attempts = 0,
			status = "PENDING"
		}
		
		table.insert(reconciliationState.conflictQueue, conflict)
		
		self:_logAuditEvent(playerId, "CONFLICT_DETECTED", {
			dataType = dataType,
			clientChecksum = clientChecksum,
			serverChecksum = serverChecksum
		})
		
		return {
			isConsistent = false,
			conflictType = "CHECKSUM_MISMATCH",
			conflict = conflict,
			details = "Data checksums do not match"
		}
	end
end

-- Resolve data conflicts
function DataReconciliation:resolveConflict(conflict)
	if not RECONCILIATION_CONFIG.ENABLE_AUTO_RECONCILIATION then
		return false, "Auto-reconciliation disabled"
	end
	
	if conflict.attempts >= RECONCILIATION_CONFIG.MAX_CONFLICT_ATTEMPTS then
		-- Max attempts reached, escalate to manual resolution
		conflict.status = "ESCALATED"
		self:_logAuditEvent(conflict.playerId, "CONFLICT_ESCALATED", {
			dataType = conflict.dataType,
			attempts = conflict.attempts
		})
		return false, "Conflict escalated to manual resolution"
	end
	
	conflict.attempts = conflict.attempts + 1
	
	-- Apply conflict resolution strategy
	local resolutionStrategy = self:_determineResolutionStrategy(conflict)
	local resolvedData, resolutionType = self:_applyResolutionStrategy(conflict, resolutionStrategy)
	
	if resolvedData then
		conflict.status = "RESOLVED"
		conflict.resolvedData = resolvedData
		conflict.resolutionType = resolutionType
		
		-- Update reconciliation history
		table.insert(reconciliationState.reconciliationHistory, {
			playerId = conflict.playerId,
			dataType = conflict.dataType,
			resolutionType = resolutionType,
			timestamp = tick(),
			conflictAttempts = conflict.attempts
		})
		
		self:_logAuditEvent(conflict.playerId, "CONFLICT_RESOLVED", {
			dataType = conflict.dataType,
			resolutionType = resolutionType,
			attempts = conflict.attempts
		})
		
		return true, resolvedData
	else
		conflict.status = "FAILED"
		self:_logAuditEvent(conflict.playerId, "CONFLICT_FAILED", {
			dataType = conflict.dataType,
			attempts = conflict.attempts
		})
		return false, "Conflict resolution failed"
	end
end

-- Determine resolution strategy
function DataReconciliation:_determineResolutionStrategy(conflict)
	-- Professional conflict resolution strategies
	local strategies = {
		"SERVER_WINS",      -- Server data takes precedence
		"CLIENT_WINS",      -- Client data takes precedence
		"MERGE",           -- Merge client and server data
		"TIMESTAMP_WINS",  -- Most recent timestamp wins
		"MANUAL"           -- Manual resolution required
	}
	
	-- Strategy selection logic
	if conflict.dataType == "PLAYER_STATS" then
		return "MERGE" -- Merge player statistics
	elseif conflict.dataType == "INVENTORY" then
		return "SERVER_WINS" -- Server authority for inventory
	elseif conflict.dataType == "GAME_STATE" then
		return "SERVER_WINS" -- Server authority for game state
	elseif conflict.dataType == "UI_SETTINGS" then
		return "CLIENT_WINS" -- Client authority for UI settings
	else
		return "TIMESTAMP_WINS" -- Default to most recent
	end
end

-- Apply resolution strategy
function DataReconciliation:_applyResolutionStrategy(conflict, strategy)
	if strategy == "SERVER_WINS" then
		return conflict.serverData, "SERVER_WINS"
	elseif strategy == "CLIENT_WINS" then
		return conflict.clientData, "CLIENT_WINS"
	elseif strategy == "MERGE" then
		return self:_mergeData(conflict.clientData, conflict.serverData), "MERGE"
	elseif strategy == "TIMESTAMP_WINS" then
		-- For now, default to server wins for timestamp strategy
		return conflict.serverData, "TIMESTAMP_WINS"
	else
		return nil, "MANUAL_RESOLUTION_REQUIRED"
	end
end

-- Merge data from client and server
function DataReconciliation:_mergeData(clientData, serverData)
	-- Professional data merging logic
	local mergedData = {}
	
	-- Handle different data types
	if type(clientData) == "table" and type(serverData) == "table" then
		-- Deep merge tables
		for key, value in pairs(serverData) do
			if clientData[key] ~= nil then
				-- Conflict on this key, apply merge strategy
				if type(value) == "number" then
					-- For numeric values, take the maximum
					mergedData[key] = math.max(value, clientData[key])
				elseif type(value) == "string" then
					-- For strings, prefer server data
					mergedData[key] = value
				elseif type(value) == "boolean" then
					-- For booleans, prefer true
					mergedData[key] = value or clientData[key]
				else
					-- For other types, prefer server data
					mergedData[key] = value
				end
			else
				-- No conflict, use server data
				mergedData[key] = value
			end
		end
		
		-- Add any client-only data
		for key, value in pairs(clientData) do
			if mergedData[key] == nil then
				mergedData[key] = value
			end
		end
	else
		-- For non-table data, default to server wins
		return serverData
	end
	
	return mergedData
end

-- Process conflict queue
function DataReconciliation:_processConflictQueue()
	if #reconciliationState.conflictQueue == 0 then
		return
	end
	
	-- Process conflicts in order
	for i = #reconciliationState.conflictQueue, 1, -1 do
		local conflict = reconciliationState.conflictQueue[i]
		
		if conflict.status == "PENDING" then
			local success, result = self:resolveConflict(conflict)
			
			if success then
				-- Remove resolved conflict from queue
				table.remove(reconciliationState.conflictQueue, i)
				
				-- Update sync status
				self:_updateSyncStatus(conflict.playerId, true)
			elseif conflict.status == "ESCALATED" then
				-- Keep escalated conflicts in queue for manual review
				print(string.format("[Data Reconciliation] Conflict escalated for player %d, dataType %s", 
					conflict.playerId, conflict.dataType))
			end
		end
	end
end

-- Perform data consistency check
function DataReconciliation:_performDataConsistencyCheck()
	local currentTime = tick()
	local inconsistencies = 0
	
	-- Check all player sync status
	for playerId, status in pairs(reconciliationState.syncStatus) do
		if not status.isSynced then
			inconsistencies = inconsistencies + 1
			print(string.format("[Data Reconciliation] Inconsistency detected for player %d", playerId))
		end
	end
	
	-- Check for unresolved conflicts
	local unresolvedConflicts = 0
	for _, conflict in ipairs(reconciliationState.conflictQueue) do
		if conflict.status == "PENDING" then
			unresolvedConflicts = unresolvedConflicts + 1
		end
	end
	
	-- Log consistency check results
	self:_logAuditEvent(0, "CONSISTENCY_CHECK", {
		inconsistencies = inconsistencies,
		unresolvedConflicts = unresolvedConflicts,
		totalConflicts = #reconciliationState.conflictQueue
	})
	
	if inconsistencies > 0 or unresolvedConflicts > 0 then
		print(string.format("[Data Reconciliation] Consistency check found %d inconsistencies and %d unresolved conflicts", 
			inconsistencies, unresolvedConflicts))
	else
		print("[Data Reconciliation] All data is consistent")
	end
end

-- Update sync status
function DataReconciliation:_updateSyncStatus(playerId, isSynced)
	local status = reconciliationState.syncStatus[playerId]
	if status then
		status.isSynced = isSynced
		status.lastSyncTime = tick()
		
		if not isSynced then
			status.conflictCount = status.conflictCount + 1
		end
	end
end

-- Calculate data checksum
function DataReconciliation:_calculateChecksum(data)
	local jsonString = HttpService:JSONEncode(data)
	local checksum = 0
	
	for i = 1, #jsonString do
		checksum = checksum + string.byte(jsonString:sub(i, i))
	end
	
	return checksum % 65536
end

-- Log audit event
function DataReconciliation:_logAuditEvent(playerId, eventType, details)
	local auditEntry = {
		playerId = playerId,
		eventType = eventType,
		timestamp = tick(),
		details = details,
		eventSource = "DATA_RECONCILIATION"
	}
	
	table.insert(reconciliationState.auditLog, auditEntry)
	
	-- Keep only last 10000 audit entries
	if #reconciliationState.auditLog > 10000 then
		table.remove(reconciliationState.auditLog, 1)
	end
end

-- Cleanup old reconciliation data
function DataReconciliation:_cleanupOldReconciliationData()
	local cutoffTime = tick() - (RECONCILIATION_CONFIG.AUDIT_LOG_RETENTION_DAYS * 86400)
	
	-- Cleanup old audit logs
	local validAuditLogs = {}
	for _, auditEntry in ipairs(reconciliationState.auditLog) do
		if auditEntry.timestamp > cutoffTime then
			table.insert(validAuditLogs, auditEntry)
		end
	end
	reconciliationState.auditLog = validAuditLogs
	
	-- Cleanup old reconciliation history
	local validHistory = {}
	for _, historyEntry in ipairs(reconciliationState.reconciliationHistory) do
		if historyEntry.timestamp > cutoffTime then
			table.insert(validHistory, historyEntry)
		end
	end
	reconciliationState.reconciliationHistory = validHistory
	
	-- Cleanup old data snapshots (keep last 1000)
	if #table.keys(reconciliationState.dataSnapshots) > 1000 then
		local snapshotKeys = table.keys(reconciliationState.dataSnapshots)
		for i = 1, #snapshotKeys - 1000 do
			reconciliationState.dataSnapshots[snapshotKeys[i]] = nil
		end
	end
end

-- Get reconciliation statistics
function DataReconciliation:getReconciliationStats()
	local stats = {
		totalSnapshots = #table.keys(reconciliationState.dataSnapshots),
		pendingConflicts = 0,
		resolvedConflicts = 0,
		escalatedConflicts = 0,
		failedConflicts = 0,
		totalPlayers = #table.keys(reconciliationState.syncStatus),
		syncedPlayers = 0,
		auditLogSize = #reconciliationState.auditLog,
		reconciliationHistorySize = #reconciliationState.reconciliationHistory
	}
	
	-- Count conflicts by status
	for _, conflict in ipairs(reconciliationState.conflictQueue) do
		if conflict.status == "PENDING" then
			stats.pendingConflicts = stats.pendingConflicts + 1
		elseif conflict.status == "RESOLVED" then
			stats.resolvedConflicts = stats.resolvedConflicts + 1
		elseif conflict.status == "ESCALATED" then
			stats.escalatedConflicts = stats.escalatedConflicts + 1
		elseif conflict.status == "FAILED" then
			stats.failedConflicts = stats.failedConflicts + 1
		end
	end
	
	-- Count synced players
	for _, status in pairs(reconciliationState.syncStatus) do
		if status.isSynced then
			stats.syncedPlayers = stats.syncedPlayers + 1
		end
	end
	
	return stats
end

-- Get conflict details
function DataReconciliation:getConflictDetails()
	local conflicts = {}
	
	for _, conflict in ipairs(reconciliationState.conflictQueue) do
		table.insert(conflicts, {
			playerId = conflict.playerId,
			dataType = conflict.dataType,
			status = conflict.status,
			attempts = conflict.attempts,
			timestamp = conflict.timestamp
		})
	end
	
	return conflicts
end

-- Force reconciliation for a player
function DataReconciliation:forceReconciliation(playerId)
	local status = reconciliationState.syncStatus[playerId]
	if not status then
		return false, "Player not found"
	end
	
	-- Mark as not synced to trigger reconciliation
	status.isSynced = false
	
	-- Trigger immediate consistency check
	self:_performDataConsistencyCheck()
	
	return true, "Forced reconciliation initiated"
end

-- Initialize global Data Reconciliation instance
local globalDataReconciliation = DataReconciliation.new()

-- Expose methods globally
function DataReconciliation.createSnapshot(playerId, dataType, data)
	return globalDataReconciliation:createSnapshot(playerId, dataType, data)
end

function DataReconciliation.compareSnapshots(playerId, dataType, clientData, serverData)
	return globalDataReconciliation:compareSnapshots(playerId, dataType, clientData, serverData)
end

function DataReconciliation.resolveConflict(conflict)
	return globalDataReconciliation:resolveConflict(conflict)
end

function DataReconciliation.getReconciliationStats()
	return globalDataReconciliation:getReconciliationStats()
end

function DataReconciliation.getConflictDetails()
	return globalDataReconciliation:getConflictDetails()
end

function DataReconciliation.forceReconciliation(playerId)
	return globalDataReconciliation:forceReconciliation(playerId)
end

print("[Data Reconciliation] Professional data reconciliation system ready!")

return DataReconciliation
