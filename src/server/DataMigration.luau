-- Data Migration System v1.0
-- Professional data migration system for schema updates and data transformations
-- Handles versioned migrations with rollback capabilities and data validation

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local DataMigration = {}
DataMigration.__index = DataMigration

-- Migration configuration
local MIGRATION_CONFIG = {
	MAX_MIGRATION_ATTEMPTS = 3,
	MIGRATION_TIMEOUT = 300, -- 5 minutes
	ENABLE_BACKUP_BEFORE_MIGRATION = true,
	ENABLE_ROLLBACK_ON_FAILURE = true,
	MAX_MIGRATION_HISTORY = 100,
	VALIDATION_ENABLED = true
}

-- Migration state
local migrationState = {
	currentVersion = "1.0.0",
	migrations = {}, -- Registered migrations
	migrationHistory = {}, -- History of applied migrations
	pendingMigrations = {}, -- Migrations waiting to be applied
	backupData = {}, -- Backup data for rollback
	validationRules = {} -- Data validation rules
}

-- Migration structure
local Migration = {
	__index = Migration
}

function Migration.new(version, description, upFunction, downFunction, validationRules)
	local self = setmetatable({}, Migration)
	self.version = version
	self.description = description
	self.up = upFunction
	self.down = downFunction
	self.validationRules = validationRules or {}
	self.status = "PENDING"
	self.appliedAt = nil
	self.rollbackData = nil
	return self
end

-- Initialize the Data Migration System
function DataMigration.new()
	local self = setmetatable({}, DataMigration)
	
	-- Setup migration monitoring
	self:_setupMigrationMonitoring()
	
	-- Setup player handlers
	self:_setupPlayerHandlers()
	
	-- Load migration state
	self:_loadMigrationState()
	
	print("[Data Migration] Initialized with professional-grade schema management")
	
	return self
end

-- Setup migration monitoring
function DataMigration:_setupMigrationMonitoring()
	-- Monitor migration health
	spawn(function()
		while true do
			task.wait(300) -- Check every 5 minutes
			self:_performMigrationHealthCheck()
		end
	end)
	
	-- Cleanup old migration history
	spawn(function()
		while true do
			task.wait(3600) -- Cleanup every hour
			self:_cleanupOldMigrationHistory()
		end
	end)
end

-- Setup player handlers
function DataMigration:_setupPlayerHandlers()
	Players.PlayerAdded:Connect(function(player)
		self:_handlePlayerJoin(player)
	end)
end

-- Load migration state
function DataMigration:_loadMigrationState()
	local migrationDatastore = DataStoreService:GetDataStore("MigrationDatastore")
	
	local success, result = pcall(function()
		return migrationDatastore:GetAsync("migrationState")
	end)
	
	if success and result then
		migrationState.currentVersion = result.currentVersion or "1.0.0"
		migrationState.migrationHistory = result.migrationHistory or {}
		migrationState.backupData = result.backupData or {}
		print(string.format("[Data Migration] Loaded migration state, current version: %s", migrationState.currentVersion))
	else
		-- Initialize default state
		migrationState.currentVersion = "1.0.0"
		migrationState.migrationHistory = {}
		migrationState.backupData = {}
		print("[Data Migration] Initialized default migration state")
	end
end

-- Register a migration
function DataMigration:registerMigration(version, description, upFunction, downFunction, validationRules)
	if migrationState.migrations[version] then
		return false, "Migration version already exists"
	end
	
	local migration = Migration.new(version, description, upFunction, downFunction, validationRules)
	migrationState.migrations[version] = migration
	
	-- Check if migration should be pending
	if self:_isMigrationPending(version) then
		table.insert(migrationState.pendingMigrations, migration)
	end
	
	return true, "Migration registered successfully"
end

-- Apply pending migrations
function DataMigration:applyPendingMigrations()
	local appliedMigrations = {}
	local failedMigrations = {}
	
	for _, migration in ipairs(migrationState.pendingMigrations) do
		local success, result = self:applyMigration(migration)
		
		if success then
			table.insert(appliedMigrations, migration.version)
			migration.status = "APPLIED"
		else
			table.insert(failedMigrations, {version = migration.version, error = result})
			migration.status = "FAILED"
		end
	end
	
	-- Update pending migrations list
	migrationState.pendingMigrations = {}
	for version, migration in pairs(migrationState.migrations) do
		if self:_isMigrationPending(version) then
			table.insert(migrationState.pendingMigrations, migration)
		end
	end
	
	return {
		applied = appliedMigrations,
		failed = failedMigrations,
		totalPending = #migrationState.pendingMigrations
	}
end

-- Apply a specific migration
function DataMigration:applyMigration(migration)
	if migration.status == "APPLIED" then
		return true, "Migration already applied"
	end
	
	-- Create backup if enabled
	local backupData = nil
	if MIGRATION_CONFIG.ENABLE_BACKUP_BEFORE_MIGRATION then
		backupData = self:_createBackup()
		migration.rollbackData = backupData
	end
	
	-- Apply migration with retry logic
	local attempts = 0
	while attempts < MIGRATION_CONFIG.MAX_MIGRATION_ATTEMPTS do
		attempts = attempts + 1
		
		local success, result = pcall(function()
			return migration:up()
		end)
		
		if success then
			-- Validate migration if enabled
			if MIGRATION_CONFIG.VALIDATION_ENABLED then
				local validationSuccess, validationError = self:_validateMigration(migration, result)
				if not validationSuccess then
					-- Rollback on validation failure
					if MIGRATION_CONFIG.ENABLE_ROLLBACK_ON_FAILURE then
						self:_rollbackMigration(migration)
					end
					return false, "Migration validation failed: " .. validationError
				end
			end
			
			-- Update migration state
			migration.status = "APPLIED"
			migration.appliedAt = tick()
			migrationState.currentVersion = migration.version
			
			-- Add to migration history
			table.insert(migrationState.migrationHistory, {
				version = migration.version,
				description = migration.description,
				appliedAt = migration.appliedAt,
				status = "APPLIED",
				rollbackData = backupData
			})
			
			-- Save migration state
			self:_saveMigrationState()
			
			print(string.format("[Data Migration] Successfully applied migration %s: %s", 
				migration.version, migration.description))
			
			return true, "Migration applied successfully"
		else
			warn(string.format("[Data Migration] Migration %s attempt %d failed: %s", 
				migration.version, attempts, result))
			
			if attempts < MIGRATION_CONFIG.MAX_MIGRATION_ATTEMPTS then
				task.wait(2 ^ attempts) -- Exponential backoff
			end
		end
	end
	
	return false, "Migration failed after all attempts"
end

-- Rollback a migration
function DataMigration:rollbackMigration(migration)
	if migration.status ~= "APPLIED" then
		return false, "Migration not applied"
	end
	
	-- Check for rollback data
	if not migration.rollbackData then
		return false, "No rollback data available"
	end
	
	-- Apply rollback with retry logic
	local attempts = 0
	while attempts < MIGRATION_CONFIG.MAX_MIGRATION_ATTEMPTS do
		attempts = attempts + 1
		
		local success, result = pcall(function()
			return migration:down(migration.rollbackData)
		end)
		
		if success then
			-- Update migration state
			migration.status = "ROLLED_BACK"
			migrationState.currentVersion = self:_getPreviousVersion(migration.version)
			
			-- Add to migration history
			table.insert(migrationState.migrationHistory, {
				version = migration.version,
				description = migration.description,
				rolledBackAt = tick(),
				status = "ROLLED_BACK"
			})
			
			-- Save migration state
			self:_saveMigrationState()
			
			print(string.format("[Data Migration] Successfully rolled back migration %s", migration.version))
			
			return true, "Migration rolled back successfully"
		else
			warn(string.format("[Data Migration] Rollback %s attempt %d failed: %s", 
				migration.version, attempts, result))
			
			if attempts < MIGRATION_CONFIG.MAX_MIGRATION_ATTEMPTS then
				task.wait(2 ^ attempts) -- Exponential backoff
			end
		end
	end
	
	return false, "Rollback failed after all attempts"
end

-- Create backup before migration
function DataMigration:_createBackup()
	local backup = {
		timestamp = tick(),
		version = migrationState.currentVersion,
		data = {}
	}
	
	-- Backup all data stores
	local datastores = {
		"PlayerData",
		"PlayerInventory",
		"PlayerProgress",
		"PlayerSettings"
	}
	
	for _, datastoreName in ipairs(datastores) do
		local datastore = DataStoreService:GetDataStore(datastoreName)
		local playerData = {}
		
		-- Get all player data (simplified for demo)
		-- In production, you would iterate through all player IDs
		for playerId, _ in pairs(Players:GetPlayers()) do
			local success, result = pcall(function()
				return datastore:GetAsync(playerId)
			end)
			
			if success then
				playerData[playerId] = result
			end
		end
		
		backup.data[datastoreName] = playerData
	end
	
	return backup
end

-- Validate migration
function DataMigration:_validateMigration(migration, migrationResult)
	-- Apply validation rules
	for _, rule in ipairs(migration.validationRules) do
		local success, error = rule(migrationResult)
		if not success then
			return false, error
		end
	end
	
	return true, "Validation passed"
end

-- Rollback migration
function DataMigration:_rollbackMigration(migration)
	if not migration.rollbackData then
		return false, "No rollback data available"
	end
	
	-- Restore from backup
	for datastoreName, playerData in pairs(migration.rollbackData.data) do
		local datastore = DataStoreService:GetDataStore(datastoreName)
		
		for playerId, data in pairs(playerData) do
			local success, result = pcall(function()
				return datastore:SetAsync(playerId, data)
			end)
			
			if not success then
				warn(string.format("[Data Migration] Failed to restore backup for player %d in datastore %s: %s", 
					playerId, datastoreName, result))
			end
		end
	end
	
	return true
end

-- Get previous version
function DataMigration:_getPreviousVersion(currentVersion)
	local history = migrationState.migrationHistory
	
	for i = #history, 1, -1 do
		if history[i].version < currentVersion and history[i].status == "APPLIED" then
			return history[i].version
		end
	end
	
	return "1.0.0"
end

-- Save migration state
function DataMigration:_saveMigrationState()
	local migrationDatastore = DataStoreService:GetDataStore("MigrationDatastore")
	
	local state = {
		currentVersion = migrationState.currentVersion,
		migrationHistory = migrationState.migrationHistory,
		backupData = migrationState.backupData
	}
	
	local success, result = pcall(function()
		return migrationDatastore:SetAsync("migrationState", state)
	end)
	
	if not success then
		warn(string.format("[Data Migration] Failed to save migration state: %s", result))
	end
end

-- Check if migration is pending
function DataMigration:_isMigrationPending(version)
	return version > migrationState.currentVersion
end

-- Handle player join
function DataMigration:_handlePlayerJoin(player)
	-- Check if player data needs migration
	local playerId = player.UserId
	
	-- In a real implementation, you would check player-specific data versions
	-- For now, we'll assume global version applies to all players
end

-- Perform migration health check
function DataMigration:_performMigrationHealthCheck()
	local totalMigrations = #table.keys(migrationState.migrations)
	local appliedMigrations = 0
	local failedMigrations = 0
	local pendingMigrations = #migrationState.pendingMigrations
	
	for _, migration in pairs(migrationState.migrations) do
		if migration.status == "APPLIED" then
			appliedMigrations = appliedMigrations + 1
		elseif migration.status == "FAILED" then
			failedMigrations = failedMigrations + 1
		end
	end
	
	print(string.format(
		"[Data Migration] Health Check: Total: %d | Applied: %d | Failed: %d | Pending: %d | Current Version: %s",
		totalMigrations, appliedMigrations, failedMigrations, pendingMigrations, migrationState.currentVersion
	))
	
	-- Log health metrics
	if failedMigrations > 0 then
		warn("[Data Migration] Failed migrations detected")
	end
	
	if pendingMigrations > 10 then
		warn("[Data Migration] High number of pending migrations")
	end
end

-- Cleanup old migration history
function DataMigration:_cleanupOldMigrationHistory()
	if #migrationState.migrationHistory <= MIGRATION_CONFIG.MAX_MIGRATION_HISTORY then
		return
	end
	
	-- Keep only recent history
	local cutoffIndex = #migrationState.migrationHistory - MIGRATION_CONFIG.MAX_MIGRATION_HISTORY
	for i = 1, cutoffIndex do
		table.remove(migrationState.migrationHistory, i)
	end
end

-- Get migration statistics
function DataMigration:getMigrationStats()
	local stats = {
		currentVersion = migrationState.currentVersion,
		totalMigrations = #table.keys(migrationState.migrations),
		appliedMigrations = 0,
		failedMigrations = 0,
		pendingMigrations = #migrationState.pendingMigrations,
		migrationHistorySize = #migrationState.migrationHistory,
		backupCount = #table.keys(migrationState.backupData)
	}
	
	-- Count migration statuses
	for _, migration in pairs(migrationState.migrations) do
		if migration.status == "APPLIED" then
			stats.appliedMigrations = stats.appliedMigrations + 1
		elseif migration.status == "FAILED" then
			stats.failedMigrations = stats.failedMigrations + 1
		end
	end
	
	return stats
end

-- Get migration details
function DataMigration:getMigrationDetails(version)
	local migration = migrationState.migrations[version]
	if not migration then
		return nil
	end
	
	return {
		version = migration.version,
		description = migration.description,
		status = migration.status,
		appliedAt = migration.appliedAt,
		hasRollbackData = migration.rollbackData ~= nil
	}
end

-- Get migration history
function DataMigration:getMigrationHistory()
	return migrationState.migrationHistory
end

-- Force migration application
function DataMigration:forceMigration(version)
	local migration = migrationState.migrations[version]
	if not migration then
		return false, "Migration not found"
	end
	
	return self:applyMigration(migration)
end

-- Force migration rollback
function DataMigration:forceRollback(version)
	local migration = migrationState.migrations[version]
	if not migration then
		return false, "Migration not found"
	end
	
	return self:rollbackMigration(migration)
end

-- Initialize global Data Migration instance
local globalDataMigration = DataMigration.new()

-- Expose methods globally
function DataMigration.registerMigration(version, description, upFunction, downFunction, validationRules)
	return globalDataMigration:registerMigration(version, description, upFunction, downFunction, validationRules)
end

function DataMigration.applyPendingMigrations()
	return globalDataMigration:applyPendingMigrations()
end

function DataMigration.applyMigration(migration)
	return globalDataMigration:applyMigration(migration)
end

function DataMigration.rollbackMigration(migration)
	return globalDataMigration:rollbackMigration(migration)
end

function DataMigration.getMigrationStats()
	return globalDataMigration:getMigrationStats()
end

function DataMigration.getMigrationDetails(version)
	return globalDataMigration:getMigrationDetails(version)
end

function DataMigration.getMigrationHistory()
	return globalDataMigration:getMigrationHistory()
end

function DataMigration.forceMigration(version)
	return globalDataMigration:forceMigration(version)
end

function DataMigration.forceRollback(version)
	return globalDataMigration:forceRollback(version)
end

print("[Data Migration] Professional data migration system ready!")

return DataMigration