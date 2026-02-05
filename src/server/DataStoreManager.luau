-- Data Store Management System v1.0
-- Professional data store management with encryption, backup, and recovery
-- Enterprise-grade data persistence for game state and player data

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local DataStoreManager = {}
DataStoreManager.__index = DataStoreManager

-- Data store configuration
local DATASTORE_CONFIG = {
	ENCRYPTION_ENABLED = true,
	BACKUP_ENABLED = true,
	RECOVERY_ENABLED = true,
	MAX_RETRIES = 3,
	RETRY_DELAY = 1,
	BACKUP_INTERVAL = 3600, -- 1 hour
	MAX_BACKUP_COUNT = 24, -- 24 hourly backups
	DATA_VERSION = "1.0"
}

-- Data store state
local datastoreState = {
	datastores = {},
	backupQueue = {},
	recoveryQueue = {},
	encryptionKeys = {},
	operationHistory = {},
	backupHistory = {}
}

-- Encrypted data store wrapper
local EncryptedDataStore = {}
EncryptedDataStore.__index = EncryptedDataStore

function EncryptedDataStore.new(datastoreName, encryptionKey)
	local self = setmetatable({}, EncryptedDataStore)
	self.datastore = DataStoreService:GetDataStore(datastoreName)
	self.encryptionKey = encryptionKey
	self.name = datastoreName
	return self
end

-- Initialize the Data Store Manager
function DataStoreManager.new()
	local self = setmetatable({}, DataStoreManager)
	
	-- Setup data store monitoring
	self:_setupDataStoreMonitoring()
	
	-- Setup backup system
	self:_setupBackupSystem()
	
	-- Setup recovery system
	self:_setupRecoverySystem()
	
	-- Setup player handlers
	self:_setupPlayerHandlers()
	
	print("[Data Store Manager] Initialized with professional-grade data persistence")
	
	return self
end

-- Setup data store monitoring
function DataStoreManager:_setupDataStoreMonitoring()
	-- Monitor data store operations
	spawn(function()
		while true do
			task.wait(300) -- Log every 5 minutes
			self:_logDataStoreMetrics()
		end
	end)
	
	-- Cleanup old operation history
	spawn(function()
		while true do
			task.wait(3600) -- Cleanup every hour
			self:_cleanupOperationHistory()
		end
	end)
end

-- Setup backup system
function DataStoreManager:_setupBackupSystem()
	-- Automated backup process
	spawn(function()
		while true do
			task.wait(DATASTORE_CONFIG.BACKUP_INTERVAL)
			self:_performAutomatedBackup()
		end
	end)
end

-- Setup recovery system
function DataStoreManager:_setupRecoverySystem()
	-- Monitor recovery queue
	spawn(function()
		while true do
			task.wait(60) -- Check recovery queue every minute
			self:_processRecoveryQueue()
		end
	end)
end

-- Setup player handlers
function DataStoreManager:_setupPlayerHandlers()
	Players.PlayerAdded:Connect(function(player)
		self:_handlePlayerJoin(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:_handlePlayerLeave(player)
	end)
end

-- Handle player join
function DataStoreManager:_handlePlayerJoin(player)
	local playerId = player.UserId
	
	-- Initialize player data stores
	self:_initializePlayerDataStores(playerId)
	
	print(string.format("[Data Store Manager] Player %d data stores initialized", playerId))
end

-- Handle player leave
function DataStoreManager:_handlePlayerLeave(player)
	local playerId = player.UserId
	
	-- Backup player data on leave
	task.spawn(function()
		self:_backupPlayerData(playerId)
	end)
	
	print(string.format("[Data Store Manager] Player %d data backup initiated", playerId))
end

-- Initialize player data stores
function DataStoreManager:_initializePlayerDataStores(playerId)
	local playerDatastores = {
		"PlayerData",
		"PlayerInventory", 
		"PlayerProgress",
		"PlayerSettings"
	}
	
	for _, datastoreName in ipairs(playerDatastores) do
		local encryptionKey = self:_generateEncryptionKey(playerId, datastoreName)
		local encryptedDatastore = EncryptedDataStore.new(datastoreName .. "_" .. playerId, encryptionKey)
		
		datastoreState.datastores[playerId] = datastoreState.datastores[playerId] or {}
		datastoreState.datastores[playerId][datastoreName] = encryptedDatastore
		datastoreState.encryptionKeys[playerId] = datastoreState.encryptionKeys[playerId] or {}
		datastoreState.encryptionKeys[playerId][datastoreName] = encryptionKey
	end
end

-- Generate encryption key for player data
function DataStoreManager:_generateEncryptionKey(playerId, datastoreName)
	local baseKey = string.format("%s_%s_%s", playerId, datastoreName, DATASTORE_CONFIG.DATA_VERSION)
	local hash = HttpService:GenerateGUID(false)
	return hash:sub(1, 32) -- 32-character encryption key
end

-- Save data with encryption and backup
function DataStoreManager:saveData(playerId, datastoreName, key, data)
	local playerDatastores = datastoreState.datastores[playerId]
	if not playerDatastores or not playerDatastores[datastoreName] then
		return false, "Datastore not initialized"
	end
	
	local encryptedDatastore = playerDatastores[datastoreName]
	local encryptionKey = datastoreState.encryptionKeys[playerId][datastoreName]
	
	-- Prepare data with metadata
	local dataToSave = {
		data = data,
		metadata = {
			playerId = playerId,
			datastoreName = datastoreName,
			key = key,
			timestamp = tick(),
			version = DATASTORE_CONFIG.DATA_VERSION,
			encryptionKey = encryptionKey
		}
	}
	
	-- Encrypt data if enabled
	local saveData = dataToSave
	if DATASTORE_CONFIG.ENCRYPTION_ENABLED then
		saveData = self:_encryptData(dataToSave, encryptionKey)
	end
	
	-- Save with retry logic
	local success, result = self:_saveWithRetry(encryptedDatastore, key, saveData)
	
	if success then
		-- Log successful save
		self:_logOperation(playerId, "SAVE_SUCCESS", {
			datastoreName = datastoreName,
			key = key,
			dataSize = #HttpService:JSONEncode(data)
		})
		
		-- Add to backup queue
		self:_addToBackupQueue(playerId, datastoreName, key, data)
		
		return true, "Data saved successfully"
	else
		-- Log failed save
		self:_logOperation(playerId, "SAVE_FAILED", {
			datastoreName = datastoreName,
			key = key,
			error = result
		})
		
		return false, result
	end
end

-- Load data with decryption
function DataStoreManager:loadData(playerId, datastoreName, key)
	local playerDatastores = datastoreState.datastores[playerId]
	if not playerDatastores or not playerDatastores[datastoreName] then
		return nil, "Datastore not initialized"
	end
	
	local encryptedDatastore = playerDatastores[datastoreName]
	local encryptionKey = datastoreState.encryptionKeys[playerId][datastoreName]
	
	-- Load with retry logic
	local success, result = self:_loadWithRetry(encryptedDatastore, key)
	
	if success then
		-- Decrypt data if enabled
		local loadedData = result
		if DATASTORE_CONFIG.ENCRYPTION_ENABLED then
			loadedData = self:_decryptData(result, encryptionKey)
		end
		
		-- Validate data integrity
		if loadedData and loadedData.data then
			-- Log successful load
			self:_logOperation(playerId, "LOAD_SUCCESS", {
				datastoreName = datastoreName,
				key = key,
				dataSize = #HttpService:JSONEncode(loadedData.data)
			})
			
			return loadedData.data, "Data loaded successfully"
		else
			return nil, "Invalid data format"
		end
	else
		-- Log failed load
		self:_logOperation(playerId, "LOAD_FAILED", {
			datastoreName = datastoreName,
			key = key,
			error = result
		})
		
		return nil, result
	end
end

-- Save with retry logic
function DataStoreManager:_saveWithRetry(datastore, key, data)
	for attempt = 1, DATASTORE_CONFIG.MAX_RETRIES do
		local success, result = pcall(function()
			return datastore.datastore:SetAsync(key, data)
		end)
		
		if success then
			return true, result
		else
			warn(string.format("[Data Store Manager] Save attempt %d failed: %s", attempt, result))
			if attempt < DATASTORE_CONFIG.MAX_RETRIES then
				task.wait(DATASTORE_CONFIG.RETRY_DELAY * attempt)
			end
		end
	end
	
	return false, "All save attempts failed"
end

-- Load with retry logic
function DataStoreManager:_loadWithRetry(datastore, key)
	for attempt = 1, DATASTORE_CONFIG.MAX_RETRIES do
		local success, result = pcall(function()
			return datastore.datastore:GetAsync(key)
		end)
		
		if success then
			return true, result
		else
			warn(string.format("[Data Store Manager] Load attempt %d failed: %s", attempt, result))
			if attempt < DATASTORE_CONFIG.MAX_RETRIES then
				task.wait(DATASTORE_CONFIG.RETRY_DELAY * attempt)
			end
		end
	end
	
	return false, "All load attempts failed"
end

-- Encrypt data
function DataStoreManager:_encryptData(data, key)
	if not DATASTORE_CONFIG.ENCRYPTION_ENABLED then
		return data
	end
	
	-- Simple encryption (in production, use proper crypto)
	local jsonString = HttpService:JSONEncode(data)
	local encrypted = ""
	
	for i = 1, #jsonString do
		local char = string.byte(jsonString:sub(i, i))
		local keyChar = string.byte(key:sub((i % #key) + 1, (i % #key) + 1))
		encrypted = encrypted .. string.char((char + keyChar) % 256)
	end
	
	return {
		encrypted = true,
		data = encrypted,
		originalSize = #jsonString
	}
end

-- Decrypt data
function DataStoreManager:_decryptData(encryptedData, key)
	if not DATASTORE_CONFIG.ENCRYPTION_ENABLED or not encryptedData.encrypted then
		return encryptedData
	end
	
	local decrypted = ""
	for i = 1, #encryptedData.data do
		local char = string.byte(encryptedData.data:sub(i, i))
		local keyChar = string.byte(key:sub((i % #key) + 1, (i % #key) + 1))
		decrypted = decrypted .. string.char((char - keyChar) % 256)
	end
	
	local success, result = pcall(function()
		return HttpService:JSONDecode(decrypted)
	end)
	
	if success then
		return result
	else
		return nil
	end
end

-- Add to backup queue
function DataStoreManager:_addToBackupQueue(playerId, datastoreName, key, data)
	local backupEntry = {
		playerId = playerId,
		datastoreName = datastoreName,
		key = key,
		data = data,
		timestamp = tick(),
		status = "PENDING"
	}
	
	table.insert(datastoreState.backupQueue, backupEntry)
end

-- Perform automated backup
function DataStoreManager:_performAutomatedBackup()
	if not DATASTORE_CONFIG.BACKUP_ENABLED then
		return
	end
	
	print("[Data Store Manager] Performing automated backup...")
	
	-- Process backup queue
	for i = #datastoreState.backupQueue, 1, -1 do
		local backupEntry = datastoreState.backupQueue[i]
		
		if backupEntry.status == "PENDING" then
			local success = self:_createBackup(backupEntry)
			
			if success then
				backupEntry.status = "COMPLETED"
				table.remove(datastoreState.backupQueue, i)
			elseif backupEntry.timestamp < tick() - 300 then -- 5 minutes old
				backupEntry.status = "FAILED"
				table.remove(datastoreState.backupQueue, i)
			end
		end
	end
	
	-- Cleanup old backups
	self:_cleanupOldBackups()
end

-- Create backup
function DataStoreManager:_createBackup(backupEntry)
	local backupKey = string.format("backup_%s_%s_%s_%d", 
		backupEntry.playerId, backupEntry.datastoreName, backupEntry.key, backupEntry.timestamp)
	
	local backupData = {
		originalData = backupEntry.data,
		metadata = {
			playerId = backupEntry.playerId,
			datastoreName = backupEntry.datastoreName,
			originalKey = backupEntry.key,
			backupTime = backupEntry.timestamp,
			version = DATASTORE_CONFIG.DATA_VERSION
		}
	}
	
	-- Store backup in backup datastore
	local backupDatastore = DataStoreService:GetDataStore("BackupDatastore")
	
	local success, result = pcall(function()
		return backupDatastore:SetAsync(backupKey, backupData)
	end)
	
	if success then
		-- Log backup creation
		table.insert(datastoreState.backupHistory, {
			playerId = backupEntry.playerId,
			datastoreName = backupEntry.datastoreName,
			backupKey = backupKey,
			timestamp = tick(),
			status = "SUCCESS"
		})
		
		return true
	else
		warn(string.format("[Data Store Manager] Backup failed: %s", result))
		return false
	end
end

-- Restore from backup
function DataStoreManager:restoreFromBackup(playerId, datastoreName, key, backupTimestamp)
	local backupDatastore = DataStoreService:GetDataStore("BackupDatastore")
	local backupKey = string.format("backup_%s_%s_%s_%d", playerId, datastoreName, key, backupTimestamp)
	
	local success, result = pcall(function()
		return backupDatastore:GetAsync(backupKey)
	end)
	
	if success and result then
		-- Restore data
		local restoreData = result.originalData
		
		-- Save to original datastore
		local saveSuccess, saveResult = self:saveData(playerId, datastoreName, key, restoreData)
		
		if saveSuccess then
			self:_logOperation(playerId, "RESTORE_SUCCESS", {
				datastoreName = datastoreName,
				key = key,
				backupTimestamp = backupTimestamp
			})
			
			return true, "Data restored successfully"
		else
			return false, saveResult
		end
	else
		return false, "Backup not found or failed to load"
	end
end

-- Add to recovery queue
function DataStoreManager:_addToRecoveryQueue(playerId, datastoreName, key, reason)
	local recoveryEntry = {
		playerId = playerId,
		datastoreName = datastoreName,
		key = key,
		reason = reason,
		timestamp = tick(),
		status = "PENDING"
	}
	
	table.insert(datastoreState.recoveryQueue, recoveryEntry)
end

-- Process recovery queue
function DataStoreManager:_processRecoveryQueue()
	for i = #datastoreState.recoveryQueue, 1, -1 do
		local recoveryEntry = datastoreState.recoveryQueue[i]
		
		if recoveryEntry.status == "PENDING" then
			local success = self:_attemptRecovery(recoveryEntry)
			
			if success then
				recoveryEntry.status = "COMPLETED"
				table.remove(datastoreState.recoveryQueue, i)
			elseif recoveryEntry.timestamp < tick() - 600 then -- 10 minutes old
				recoveryEntry.status = "FAILED"
				table.remove(datastoreState.recoveryQueue, i)
			end
		end
	end
end

-- Attempt data recovery
function DataStoreManager:_attemptRecovery(recoveryEntry)
	-- Try to load from backup
	local backups = self:_getAvailableBackups(recoveryEntry.playerId, recoveryEntry.datastoreName, recoveryEntry.key)
	
	if #backups > 0 then
		-- Use latest backup
		local latestBackup = backups[#backups]
		return self:restoreFromBackup(
			recoveryEntry.playerId, 
			recoveryEntry.datastoreName, 
			recoveryEntry.key, 
			latestBackup.timestamp
		)
	else
		-- No backups available, create default data
		local defaultData = self:_createDefaultData(recoveryEntry.datastoreName)
		return self:saveData(recoveryEntry.playerId, recoveryEntry.datastoreName, recoveryEntry.key, defaultData)
	end
end

-- Get available backups
function DataStoreManager:_getAvailableBackups(playerId, datastoreName, key)
	local backups = {}
	
	for _, backup in ipairs(datastoreState.backupHistory) do
		if backup.playerId == playerId and 
		   backup.datastoreName == datastoreName and
		   backup.status == "SUCCESS" then
			table.insert(backups, backup)
		end
	end
	
	-- Sort by timestamp (newest first)
	table.sort(backups, function(a, b)
		return a.timestamp > b.timestamp
	end)
	
	return backups
end

-- Create default data for recovery
function DataStoreManager:_createDefaultData(datastoreName)
	if datastoreName == "PlayerData" then
		return {
			coins = 0,
			level = 1,
			experience = 0,
			lastLogin = tick()
		}
	elseif datastoreName == "PlayerInventory" then
		return {
			items = {},
			capacity = 20,
			gold = 100
		}
	elseif datastoreName == "PlayerProgress" then
		return {
			completedQuests = {},
			unlockedAchievements = {},
			gameStats = {
				totalPlayTime = 0,
				wins = 0,
				losses = 0
			}
		}
	elseif datastoreName == "PlayerSettings" then
		return {
			graphicsQuality = "HIGH",
			audioVolume = 1.0,
			controls = {
				movement = "WASD",
				interact = "E"
			}
		}
	else
		return {}
	end
end

-- Backup player data
function DataStoreManager:_backupPlayerData(playerId)
	local playerDatastores = datastoreState.datastores[playerId]
	if not playerDatastores then
		return
	end
	
	for datastoreName, encryptedDatastore in pairs(playerDatastores) do
		-- Get all keys for this datastore
		local keys = self:_getAllDatastoreKeys(encryptedDatastore)
		
		for _, key in ipairs(keys) do
			-- Load current data
			local success, data = self:loadData(playerId, datastoreName, key)
			if success then
				-- Add to backup queue
				self:_addToBackupQueue(playerId, datastoreName, key, data)
			end
		end
	end
end

-- Get all keys from datastore (simplified implementation)
function DataStoreManager:_getAllDatastoreKeys(datastore)
	-- In a real implementation, you would need to track all keys
	-- For now, return common keys
	return {
		"main",
		"settings", 
		"inventory",
		"progress"
	}
end

-- Log data store operation
function DataStoreManager:_logOperation(playerId, operationType, details)
	local operation = {
		playerId = playerId,
		operationType = operationType,
		timestamp = tick(),
		details = details
	}
	
	table.insert(datastoreState.operationHistory, operation)
	
	-- Keep only last 1000 operations
	if #datastoreState.operationHistory > 1000 then
		table.remove(datastoreState.operationHistory, 1)
	end
end

-- Log data store metrics
function DataStoreManager:_logDataStoreMetrics()
	local totalOperations = #datastoreState.operationHistory
	local successOperations = 0
	local failedOperations = 0
	
	for _, operation in ipairs(datastoreState.operationHistory) do
		if operation.operationType:find("SUCCESS") then
			successOperations = successOperations + 1
		elseif operation.operationType:find("FAILED") then
			failedOperations = failedOperations + 1
		end
	end
	
	local successRate = totalOperations > 0 and (successOperations / totalOperations) * 100 or 0
	
	print(string.format(
		"[Data Store Manager] Metrics: Total: %d | Success: %d | Failed: %d | Success Rate: %.1f%% | Backups: %d",
		totalOperations, successOperations, failedOperations, successRate,
		#datastoreState.backupHistory
	))
end

-- Cleanup operation history
function DataStoreManager:_cleanupOperationHistory()
	local cutoffTime = tick() - 86400 -- 24 hours
	local validOperations = {}
	
	for _, operation in ipairs(datastoreState.operationHistory) do
		if operation.timestamp > cutoffTime then
			table.insert(validOperations, operation)
		end
	end
	
	datastoreState.operationHistory = validOperations
end

-- Cleanup old backups
function DataStoreManager:_cleanupOldBackups()
	if #datastoreState.backupHistory <= DATASTORE_CONFIG.MAX_BACKUP_COUNT then
		return
	end
	
	-- Keep only the most recent backups
	table.sort(datastoreState.backupHistory, function(a, b)
		return a.timestamp > b.timestamp
	end)
	
	-- Remove old backups
	for i = DATASTORE_CONFIG.MAX_BACKUP_COUNT + 1, #datastoreState.backupHistory do
		table.remove(datastoreState.backupHistory, i)
	end
end

-- Get data store statistics
function DataStoreManager:getDataStoreStats()
	local stats = {
		totalDatastores = 0,
		totalOperations = #datastoreState.operationHistory,
		totalBackups = #datastoreState.backupHistory,
		pendingBackups = #datastoreState.backupQueue,
		pendingRecoveries = #datastoreState.recoveryQueue,
		encryptionEnabled = DATASTORE_CONFIG.ENCRYPTION_ENABLED,
		backupEnabled = DATASTORE_CONFIG.BACKUP_ENABLED
	}
	
	-- Count datastores
	for playerId, playerDatastores in pairs(datastoreState.datastores) do
		stats.totalDatastores = stats.totalDatastores + #table.keys(playerDatastores)
	end
	
	return stats
end

-- Initialize global Data Store Manager instance
local globalDataStoreManager = DataStoreManager.new()

-- Expose methods globally
function DataStoreManager.saveData(playerId, datastoreName, key, data)
	return globalDataStoreManager:saveData(playerId, datastoreName, key, data)
end

function DataStoreManager.loadData(playerId, datastoreName, key)
	return globalDataStoreManager:loadData(playerId, datastoreName, key)
end

function DataStoreManager.restoreFromBackup(playerId, datastoreName, key, backupTimestamp)
	return globalDataStoreManager:restoreFromBackup(playerId, datastoreName, key, backupTimestamp)
end

function DataStoreManager.getDataStoreStats()
	return globalDataStoreManager:getDataStoreStats()
end

print("[Data Store Manager] Professional data store management system ready!")

return DataStoreManager