-- State-Based Replication System v1.0
-- Professional state replication system for real-time data synchronization
-- between server and clients with conflict resolution and version control

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local StateReplication = {}
StateReplication.__index = StateReplication

-- Replication configuration
local REPLICATION_CONFIG = {
	MAX_STATE_HISTORY = 100,
	REPLICATION_INTERVAL = 0.1, -- 100ms update interval
	CONFLICT_RESOLUTION_TIMEOUT = 5,
	ENABLE_STATE_COMPRESSION = true,
	ENABLE_VERSION_CONTROL = true,
	MAX_PENDING_UPDATES = 50
}

-- State replication state
local replicationState = {
	entities = {}, -- Active replicated entities
	stateHistory = {}, -- Historical state data
	pendingUpdates = {}, -- Pending state updates
	replicationQueue = {}, -- Queue for replication updates
	conflictQueue = {}, -- Queue for conflict resolution
	versionControl = {}, -- Version tracking
	syncStatus = {} -- Synchronization status per player
}

-- Replicated entity structure
local ReplicatedEntity = {
	__index = ReplicatedEntity
}

function ReplicatedEntity.new(entityId, entityType, initialState)
	local self = setmetatable({}, ReplicatedEntity)
	self.entityId = entityId
	self.entityType = entityType
	self.state = initialState
	self.version = 1
	self.lastUpdated = tick()
	self.authoritative = true -- Server is authoritative by default
	self.clients = {} -- Track which clients have this entity
	self.stateHistory = {}
	return self
end

-- Initialize the State Replication System
function StateReplication.new()
	local self = setmetatable({}, StateReplication)
	
	-- Setup replication monitoring
	self:_setupReplicationMonitoring()
	
	-- Setup state update processing
	self:_setupStateUpdateProcessing()
	
	-- Setup conflict resolution
	self:_setupConflictResolution()
	
	-- Setup player handlers
	self:_setupPlayerHandlers()
	
	-- Setup remote events
	self:_setupRemoteEvents()
	
	print("[State Replication] Initialized with professional-grade state synchronization")
	
	return self
end

-- Setup replication monitoring
function StateReplication:_setupReplicationMonitoring()
	-- Monitor replication health
	spawn(function()
		while true do
			task.wait(30) -- Check every 30 seconds
			self:_performReplicationHealthCheck()
		end
	end)
	
	-- Cleanup old state history
	spawn(function()
		while true do
			task.wait(600) -- Cleanup every 10 minutes
			self:_cleanupOldStateHistory()
		end
	end)
end

-- Setup state update processing
function StateReplication:_setupStateUpdateProcessing()
	-- Process replication queue
	spawn(function()
		while true do
			task.wait(REPLICATION_CONFIG.REPLICATION_INTERVAL)
			self:_processReplicationQueue()
		end
	end)
end

-- Setup conflict resolution
function StateReplication:_setupConflictResolution()
	-- Process conflict queue
	spawn(function()
		while true do
			task.wait(1) -- Process conflicts every second
			self:_processConflictQueue()
		end
	end)
end

-- Setup player handlers
function StateReplication:_setupPlayerHandlers()
	Players.PlayerAdded:Connect(function(player)
		self:_handlePlayerJoin(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:_handlePlayerLeave(player)
	end)
end

-- Setup remote events
function StateReplication:_setupRemoteEvents()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	
	-- State update event
	self.Events.StateUpdate = Instance.new("RemoteEvent")
	self.Events.StateUpdate.Name = "StateUpdate"
	self.Events.StateUpdate.Parent = ReplicatedStorage
	
	-- State request event
	self.Events.StateRequest = Instance.new("RemoteEvent")
	self.Events.StateRequest.Name = "StateRequest"
	self.Events.StateRequest.Parent = ReplicatedStorage
	
	-- Conflict resolution event
	self.Events.ConflictResolution = Instance.new("RemoteEvent")
	self.Events.ConflictResolution.Name = "ConflictResolution"
	self.Events.ConflictResolution.Parent = ReplicatedStorage
	
	-- Setup event handlers
	self.Events.StateRequest.OnServerEvent:Connect(function(player, entityId, version)
		self:_handleStateRequest(player, entityId, version)
	end)
	
	self.Events.ConflictResolution.OnServerEvent:Connect(function(player, entityId, resolutionData)
		self:_handleConflictResolution(player, entityId, resolutionData)
	end)
end

-- Handle player join
function StateReplication:_handlePlayerJoin(player)
	local playerId = player.UserId
	
	-- Initialize sync status
	replicationState.syncStatus[playerId] = {
		isSynced = false,
		lastSyncTime = 0,
		pendingUpdates = 0,
		conflictCount = 0
	}
	
	-- Send initial state to player
	self:_sendInitialState(player)
	
	print(string.format("[State Replication] Player %d joined, sending initial state", playerId))
end

-- Handle player leave
function StateReplication:_handlePlayerLeave(player)
	local playerId = player.UserId
	
	-- Cleanup player state
	replicationState.syncStatus[playerId] = nil
	
	-- Remove player from entity clients
	for entityId, entity in pairs(replicationState.entities) do
		entity.clients[playerId] = nil
	end
	
	print(string.format("[State Replication] Player %d left, cleaned up replication state", playerId))
end

-- Create replicated entity
function StateReplication:createEntity(entityId, entityType, initialState)
	if replicationState.entities[entityId] then
		return false, "Entity already exists"
	end
	
	local entity = ReplicatedEntity.new(entityId, entityType, initialState)
	replicationState.entities[entityId] = entity
	
	-- Add to state history
	self:_addToStateHistory(entityId, entity.state, entity.version)
	
	-- Replicate to all players
	self:_replicateToAllPlayers(entityId)
	
	return true, entity
end

-- Update entity state
function StateReplication:updateEntity(entityId, newState, sourcePlayer)
	local entity = replicationState.entities[entityId]
	if not entity then
		return false, "Entity not found"
	end
	
	-- Validate update authority
	if not entity.authoritative and sourcePlayer then
		-- Client wants to update, check if allowed
		if not self:_validateClientUpdate(entity, newState, sourcePlayer) then
			return false, "Client update not authorized"
		end
	end
	
	-- Update state
	entity.state = newState
	entity.version = entity.version + 1
	entity.lastUpdated = tick()
	
	-- Add to state history
	self:_addToStateHistory(entityId, entity.state, entity.version)
	
	-- Add to replication queue
	self:_addToReplicationQueue(entityId, entity.state, entity.version)
	
	return true, entity.version
end

-- Get entity state
function StateReplication:getEntityState(entityId)
	local entity = replicationState.entities[entityId]
	if not entity then
		return nil, "Entity not found"
	end
	
	return entity.state, entity.version
end

-- Replicate entity to specific player
function StateReplication:replicateToPlayer(entityId, playerId)
	local entity = replicationState.entities[entityId]
	if not entity then
		return false, "Entity not found"
	end
	
	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		return false, "Player not found"
	end
	
	-- Send state update to player
	self:_sendStateUpdate(player, entityId, entity.state, entity.version)
	
	-- Track that player has this entity
	entity.clients[playerId] = true
	
	return true, "State replicated to player"
end

-- Replicate entity to all players
function StateReplication:_replicateToAllPlayers(entityId)
	local entity = replicationState.entities[entityId]
	if not entity then
		return
	end
	
	for _, player in ipairs(Players:GetPlayers()) do
		self:_sendStateUpdate(player, entityId, entity.state, entity.version)
		entity.clients[player.UserId] = true
	end
end

-- Send state update to player
function StateReplication:_sendStateUpdate(player, entityId, state, version)
	if not self.Events.StateUpdate then
		return
	end
	
	-- Compress state if enabled
	local stateToSend = state
	if REPLICATION_CONFIG.ENABLE_STATE_COMPRESSION then
		stateToSend = self:_compressState(state)
	end
	
	-- Send update
	self.Events.StateUpdate:FireClient(player, {
		entityId = entityId,
		state = stateToSend,
		version = version,
		timestamp = tick()
	})
end

-- Send initial state to player
function StateReplication:_sendInitialState(player)
	for entityId, entity in pairs(replicationState.entities) do
		self:_sendStateUpdate(player, entityId, entity.state, entity.version)
		entity.clients[player.UserId] = true
	end
	
	-- Mark player as synced
	local status = replicationState.syncStatus[player.UserId]
	if status then
		status.isSynced = true
		status.lastSyncTime = tick()
	end
end

-- Handle state request from client
function StateReplication:_handleStateRequest(player, entityId, version)
	local entity = replicationState.entities[entityId]
	if not entity then
		return
	end
	
	-- Check if client is behind
	if version < entity.version then
		-- Send current state to client
		self:_sendStateUpdate(player, entityId, entity.state, entity.version)
		
		-- Log state request
		print(string.format("[State Replication] State request from player %d for entity %s, sending version %d", 
			player.UserId, entityId, entity.version))
	end
end

-- Handle conflict resolution from client
function StateReplication:_handleConflictResolution(player, entityId, resolutionData)
	local entity = replicationState.entities[entityId]
	if not entity then
		return
	end
	
	-- Add to conflict queue
	local conflict = {
		entityId = entityId,
		playerId = player.UserId,
		clientState = resolutionData.clientState,
		serverState = entity.state,
		clientVersion = resolutionData.clientVersion,
		serverVersion = entity.version,
		timestamp = tick(),
		status = "PENDING"
	}
	
	table.insert(replicationState.conflictQueue, conflict)
	
	print(string.format("[State Replication] Conflict resolution request from player %d for entity %s", 
		player.UserId, entityId))
end

-- Add to replication queue
function StateReplication:_addToReplicationQueue(entityId, state, version)
	local update = {
		entityId = entityId,
		state = state,
		version = version,
		timestamp = tick(),
		status = "PENDING"
	}
	
	table.insert(replicationState.replicationQueue, update)
	
	-- Limit queue size
	if #replicationState.replicationQueue > REPLICATION_CONFIG.MAX_PENDING_UPDATES then
		table.remove(replicationState.replicationQueue, 1)
	end
end

-- Process replication queue
function StateReplication:_processReplicationQueue()
	if #replicationState.replicationQueue == 0 then
		return
	end
	
	-- Process updates in batches
	local batchSize = 10
	local processed = 0
	
	for i = 1, math.min(batchSize, #replicationState.replicationQueue) do
		local update = replicationState.replicationQueue[1]
		
		if update then
			-- Send to all clients that have this entity
			local entity = replicationState.entities[update.entityId]
			if entity then
				for playerId, _ in pairs(entity.clients) do
					local player = Players:GetPlayerByUserId(playerId)
					if player then
						self:_sendStateUpdate(player, update.entityId, update.state, update.version)
					end
				end
			end
			
			-- Mark as processed
			update.status = "PROCESSED"
			table.remove(replicationState.replicationQueue, 1)
			processed = processed + 1
		end
	end
	
	-- Update sync status
	for playerId, status in pairs(replicationState.syncStatus) do
		status.pendingUpdates = math.max(0, status.pendingUpdates - processed)
	end
end

-- Process conflict queue
function StateReplication:_processConflictQueue()
	if #replicationState.conflictQueue == 0 then
		return
	end
	
	-- Process conflicts
	for i = #replicationState.conflictQueue, 1, -1 do
		local conflict = replicationState.conflictQueue[i]
		
		if conflict.status == "PENDING" then
			local resolved = self:_resolveConflict(conflict)
			
			if resolved then
				table.remove(replicationState.conflictQueue, i)
			elseif tick() - conflict.timestamp > REPLICATION_CONFIG.CONFLICT_RESOLUTION_TIMEOUT then
				-- Timeout, remove from queue
				table.remove(replicationState.conflictQueue, i)
			end
		end
	end
end

-- Resolve conflict
function StateReplication:_resolveConflict(conflict)
	local entity = replicationState.entities[conflict.entityId]
	if not entity then
		return false
	end
	
	-- Apply conflict resolution strategy
	local resolutionStrategy = self:_determineResolutionStrategy(conflict)
	
	if resolutionStrategy == "SERVER_WINS" then
		-- Server state is authoritative
		self:_sendStateUpdate(
			Players:GetPlayerByUserId(conflict.playerId),
			conflict.entityId,
			entity.state,
			entity.version
		)
		return true
	elseif resolutionStrategy == "CLIENT_WINS" then
		-- Accept client state
		entity.state = conflict.clientState
		entity.version = conflict.clientVersion
		entity.lastUpdated = tick()
		
		-- Replicate to all players
		self:_replicateToAllPlayers(conflict.entityId)
		return true
	elseif resolutionStrategy == "MERGE" then
		-- Merge states
		local mergedState = self:_mergeStates(entity.state, conflict.clientState)
		entity.state = mergedState
		entity.version = entity.version + 1
		entity.lastUpdated = tick()
		
		-- Replicate to all players
		self:_replicateToAllPlayers(conflict.entityId)
		return true
	else
		return false
	end
end

-- Determine resolution strategy
function StateReplication:_determineResolutionStrategy(conflict)
	-- Strategy based on entity type and context
	if conflict.entityType == "PLAYER_DATA" then
		return "MERGE" -- Merge player data
	elseif conflict.entityType == "GAME_STATE" then
		return "SERVER_WINS" -- Server authoritative for game state
	elseif conflict.entityType == "UI_STATE" then
		return "CLIENT_WINS" -- Client authoritative for UI
	else
		return "SERVER_WINS" -- Default to server wins
	end
end

-- Merge states
function StateReplication:_mergeStates(serverState, clientState)
	local merged = {}
	
	-- Deep merge logic
	for key, value in pairs(serverState) do
		if clientState[key] ~= nil then
			-- Conflict on this key
			if type(value) == "number" then
				merged[key] = math.max(value, clientState[key])
			elseif type(value) == "string" then
				merged[key] = value -- Prefer server string
			elseif type(value) == "boolean" then
				merged[key] = value or clientState[key] -- Prefer true
			else
				merged[key] = value -- Default to server
			end
		else
			merged[key] = value
		end
	end
	
	-- Add client-only keys
	for key, value in pairs(clientState) do
		if merged[key] == nil then
			merged[key] = value
		end
	end
	
	return merged
end

-- Validate client update
function StateReplication:_validateClientUpdate(entity, newState, player)
	-- Basic validation logic
	-- In a real implementation, this would have more sophisticated validation
	
	if entity.entityType == "PLAYER_DATA" then
		-- Allow player to update their own data
		return true
	elseif entity.entityType == "GAME_STATE" then
		-- Only allow server updates for game state
		return false
	else
		return true
	end
end

-- Add to state history
function StateReplication:_addToStateHistory(entityId, state, version)
	if not REPLICATION_CONFIG.ENABLE_VERSION_CONTROL then
		return
	end
	
	local history = replicationState.stateHistory[entityId] or {}
	
	table.insert(history, {
		state = state,
		version = version,
		timestamp = tick()
	})
	
	-- Limit history size
	if #history > REPLICATION_CONFIG.MAX_STATE_HISTORY then
		table.remove(history, 1)
	end
	
	replicationState.stateHistory[entityId] = history
end

-- Compress state
function StateReplication:_compressState(state)
	if not REPLICATION_CONFIG.ENABLE_STATE_COMPRESSION then
		return state
	end
	
	-- Simple compression (in production, use proper compression)
	local jsonString = HttpService:JSONEncode(state)
	return {
		compressed = true,
		data = jsonString,
		originalSize = #jsonString
	}
end

-- Perform replication health check
function StateReplication:_performReplicationHealthCheck()
	local totalEntities = #table.keys(replicationState.entities)
	local totalConflicts = #replicationState.conflictQueue
	local totalPendingUpdates = #replicationState.replicationQueue
	local totalSyncedPlayers = 0
	
	for _, status in pairs(replicationState.syncStatus) do
		if status.isSynced then
			totalSyncedPlayers = totalSyncedPlayers + 1
		end
	end
	
	print(string.format(
		"[State Replication] Health Check: Entities: %d | Conflicts: %d | Pending Updates: %d | Synced Players: %d",
		totalEntities, totalConflicts, totalPendingUpdates, totalSyncedPlayers
	))
	
	-- Log health metrics
	if totalConflicts > 10 then
		warn("[State Replication] High conflict count detected")
	end
	
	if totalPendingUpdates > 20 then
		warn("[State Replication] High pending update count detected")
	end
end

-- Cleanup old state history
function StateReplication:_cleanupOldStateHistory()
	if not REPLICATION_CONFIG.ENABLE_VERSION_CONTROL then
		return
	end
	
	for entityId, history in pairs(replicationState.stateHistory) do
		-- Keep only recent history
		if #history > REPLICATION_CONFIG.MAX_STATE_HISTORY then
			for i = 1, #history - REPLICATION_CONFIG.MAX_STATE_HISTORY do
				table.remove(history, i)
			end
		end
	end
end

-- Get replication statistics
function StateReplication:getReplicationStats()
	local stats = {
		totalEntities = #table.keys(replicationState.entities),
		totalStateHistory = 0,
		totalPendingUpdates = #replicationState.replicationQueue,
		totalConflicts = #replicationState.conflictQueue,
		totalPlayers = #table.keys(replicationState.syncStatus),
		syncedPlayers = 0,
		averageReplicationLatency = 0
	}
	
	-- Count synced players
	for _, status in pairs(replicationState.syncStatus) do
		if status.isSynced then
			stats.syncedPlayers = stats.syncedPlayers + 1
		end
	end
	
	-- Count total state history
	for entityId, history in pairs(replicationState.stateHistory) do
		stats.totalStateHistory = stats.totalStateHistory + #history
	end
	
	return stats
end

-- Get entity details
function StateReplication:getEntityDetails(entityId)
	local entity = replicationState.entities[entityId]
	if not entity then
		return nil
	end
	
	return {
		entityId = entity.entityId,
		entityType = entity.entityType,
		version = entity.version,
		lastUpdated = entity.lastUpdated,
		authoritative = entity.authoritative,
		clientCount = #table.keys(entity.clients)
	}
end

-- Force state synchronization
function StateReplication:forceSynchronization(playerId)
	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		return false, "Player not found"
	end
	
	-- Send initial state
	self:_sendInitialState(player)
	
	return true, "Forced synchronization initiated"
end

-- Initialize global State Replication instance
local globalStateReplication = StateReplication.new()

-- Expose methods globally
function StateReplication.createEntity(entityId, entityType, initialState)
	return globalStateReplication:createEntity(entityId, entityType, initialState)
end

function StateReplication.updateEntity(entityId, newState, sourcePlayer)
	return globalStateReplication:updateEntity(entityId, newState, sourcePlayer)
end

function StateReplication.getEntityState(entityId)
	return globalStateReplication:getEntityState(entityId)
end

function StateReplication.replicateToPlayer(entityId, playerId)
	return globalStateReplication:replicateToPlayer(entityId, playerId)
end

function StateReplication.getReplicationStats()
	return globalStateReplication:getReplicationStats()
end

function StateReplication.getEntityDetails(entityId)
	return globalStateReplication:getEntityDetails(entityId)
end

function StateReplication.forceSynchronization(playerId)
	return globalStateReplication:forceSynchronization(playerId)
end

print("[State Replication] Professional state replication system ready!")

return StateReplication