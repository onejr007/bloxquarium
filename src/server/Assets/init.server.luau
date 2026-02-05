-- Professional Asset System Integration v2.0
-- Comprehensive asset management system with Data Reconciliation and Data Store Management integration
-- Ensures all assets are properly loaded, secured, and synchronized

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

local AssetSystem = {}
AssetSystem.__index = AssetSystem

-- Asset system state
local assetSystemState = {
	assets = {},
	assetCategories = {},
	loadedAssets = {},
	securityFramework = nil,
	assetManager = nil,
	dataReconciliation = nil,
	dataStoreManager = nil,
	isInitialized = false
}

-- Asset categories and their paths
local ASSET_CATEGORIES = {
	Aquariums = {
		"Aquarium_Lv1",
		"Aquarium_Lv2", 
		"Aquarium_Lv3"
	},
	Characters = {
		"Goldfish",
		"Guppy",
		"Piranha",
		"Gentong"
	},
	Items = {
		"Coin",
		"Coin1"
	}
}

-- Initialize the Asset System
function AssetSystem.new()
	local self = setmetatable({}, AssetSystem)
	
	-- Initialize asset management system with Data Reconciliation and Data Store Management
	self:_initializeAssetManagement()
	
	-- Setup asset security with enhanced monitoring
	self:_setupAssetSecurity()
	
	-- Setup asset monitoring with reconciliation integration
	self:_setupAssetMonitoring()
	
	-- Setup player handlers with data store integration
	self:_setupPlayerHandlers()
	
	print("[Asset System] Professional asset system v2.0 initialized with Data Reconciliation and Data Store Management")
	
	return self
end

-- Initialize asset management system
function AssetSystem:_initializeAssetManagement()
	print("[Asset System] Initializing asset management with Data Reconciliation and Data Store Management...")
	
	-- Initialize AssetManagerPro
	local AssetManagerPro = require(ReplicatedStorage.Shared.AssetManagerPro)
	assetSystemState.assetManager = AssetManagerPro
	
	-- Initialize Security Framework
	local SecurityFramework = require(ReplicatedStorage.Shared.SecurityFramework)
	assetSystemState.securityFramework = SecurityFramework
	
	-- Initialize Data Reconciliation system
	local DataReconciliation = require(ReplicatedStorage.Shared.DataReconciliation)
	assetSystemState.dataReconciliation = DataReconciliation
	
	-- Initialize Data Store Manager
	local DataStoreManager = require(ServerScriptService.Server.DataStoreManager)
	assetSystemState.dataStoreManager = DataStoreManager
	
	-- Setup asset categories with safe path checking
	for categoryName, assetNames in pairs(ASSET_CATEGORIES) do
		assetSystemState.assetCategories[categoryName] = {}
		
		-- Get the category folder from ReplicatedStorage
		local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
		if modelsFolder then
			local categoryFolder = modelsFolder:FindFirstChild(categoryName)
			if categoryFolder then
				for _, assetName in ipairs(assetNames) do
					local assetPath = "Models/" .. categoryName .. "/" .. assetName
					local assetModel = categoryFolder:FindFirstChild(assetName)
					
					if assetModel then
						assetSystemState.assets[assetPath] = assetModel
						table.insert(assetSystemState.assetCategories[categoryName], assetPath)
						print("[Asset System] Registered asset: " .. assetPath)
					else
						warn("[Asset System] Missing asset: " .. assetPath)
					end
				end
			else
				warn("[Asset System] Missing category folder: " .. categoryName)
			end
		else
			warn("[Asset System] Models folder not found in ReplicatedStorage")
		end
	end
	
	-- Preload all assets with reconciliation monitoring
	self:preloadAllAssets()
	
	-- Initialize data reconciliation for asset operations
	self:_setupAssetReconciliation()
	
	assetSystemState.isInitialized = true
	print("[Asset System] Asset management initialized successfully with Data Reconciliation and Data Store Management")
end

-- Setup asset security with enhanced monitoring
function AssetSystem:_setupAssetSecurity()
	print("[Asset System] Setting up enhanced asset security...")
	
	-- Monitor asset access attempts with reconciliation
	spawn(function()
		while true do
			task.wait(60) -- Check every minute
			self:_auditAssetAccess()
		end
	end)
	
	-- Setup asset integrity monitoring with data store backup
	spawn(function()
		while true do
			task.wait(300) -- Check every 5 minutes
			self:_checkAssetIntegrity()
		end
	end)
	
	-- Setup data reconciliation monitoring for asset operations
	spawn(function()
		while true do
			task.wait(120) -- Check every 2 minutes
			self:_monitorAssetReconciliation()
		end
	end)
end

-- Setup asset monitoring with reconciliation integration
function AssetSystem:_setupAssetMonitoring()
	-- Monitor asset loading performance with data store integration
	spawn(function()
		while true do
			task.wait(60) -- Log every minute
			self:_logAssetPerformance()
		end
	end)
	
	-- Cleanup old asset references with data store cleanup
	spawn(function()
		while true do
			task.wait(600) -- Cleanup every 10 minutes
			self:_cleanupAssetReferences()
		end
	end)
	
	-- Monitor data store operations for asset data
	spawn(function()
		while true do
			task.wait(180) -- Monitor every 3 minutes
			self:_monitorAssetDataStoreOperations()
		end
	end)
end

-- Setup player handlers with data store integration
function AssetSystem:_setupPlayerHandlers()
	Players.PlayerAdded:Connect(function(player)
		self:_handlePlayerJoin(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:_handlePlayerLeave(player)
	end)
end

-- Handle player join with data store integration
function AssetSystem:_handlePlayerJoin(player)
	local playerId = player.UserId
	
	-- Log player asset access
	print(string.format("[Asset System] Player %d joined, preloading assets", playerId))
	
	-- Preload assets for player with reconciliation
	task.spawn(function()
		self:preloadAllAssets()
		print(string.format("[Asset System] Assets preloaded for player %d", playerId))
		
		-- Initialize player data stores
		if assetSystemState.dataStoreManager then
			assetSystemState.dataStoreManager.initializePlayerData(playerId)
			print(string.format("[Asset System] Data stores initialized for player %d", playerId))
		end
	end)
end

-- Handle player leave with data store backup
function AssetSystem:_handlePlayerLeave(player)
	local playerId = player.UserId
	
	-- Cleanup player-specific asset references
	print(string.format("[Asset System] Player %d left, cleaning up assets", playerId))
	
	-- Backup player data
	if assetSystemState.dataStoreManager then
		task.spawn(function()
			assetSystemState.dataStoreManager.backupPlayerData(playerId)
			print(string.format("[Asset System] Player %d data backed up", playerId))
		end)
	end
end

-- Preload all assets with reconciliation monitoring
function AssetSystem:preloadAllAssets()
	if not assetSystemState.isInitialized then
		return false, "Asset system not initialized"
	end
	
	print("[Asset System] Preloading all assets with reconciliation monitoring...")
	
	local startTime = tick()
	local loadedCount = 0
	local totalCount = 0
	
	-- Count total assets
	for _, categoryAssets in pairs(assetSystemState.assetCategories) do
		totalCount = totalCount + #categoryAssets
	end
	
	-- Preload each asset with reconciliation tracking
	for categoryName, categoryAssets in pairs(assetSystemState.assetCategories) do
		for _, assetPath in ipairs(categoryAssets) do
			local assetModel = assetSystemState.assets[assetPath]
			if assetModel then
				-- Use ContentProvider to preload
				local success, result = pcall(function()
					ContentProvider:PreloadAsync({assetModel})
				end)
				
				if success then
					loadedCount = loadedCount + 1
					assetSystemState.loadedAssets[assetPath] = true
					print(string.format("[Asset System] Preloaded: %s", assetPath))
					
					-- Record asset loading in data reconciliation
					if assetSystemState.dataReconciliation then
						assetSystemState.dataReconciliation.recordOperation("ASSET_LOAD", {
							assetPath = assetPath,
							loadTime = tick(),
							success = true
						})
					end
				else
					warn(string.format("[Asset System] Failed to preload: %s - %s", assetPath, result))
					
					-- Record asset loading failure in data reconciliation
					if assetSystemState.dataReconciliation then
						assetSystemState.dataReconciliation.recordOperation("ASSET_LOAD", {
							assetPath = assetPath,
							loadTime = tick(),
							success = false,
							error = result
						})
					end
				end
			end
		end
	end
	
	local loadTime = tick() - startTime
	local loadRate = totalCount > 0 and (loadedCount / totalCount) * 100 or 0
	
	print(string.format("[Asset System] Preload complete: %d/%d assets (%.1f%%) in %.2fs", 
		loadedCount, totalCount, loadRate, loadTime))
	
	return loadedCount == totalCount, string.format("Preloaded %d/%d assets with reconciliation monitoring", loadedCount, totalCount)
end

-- Get asset by path with security validation and reconciliation
function AssetSystem:getAsset(playerId, assetPath)
	-- Validate player session
	if assetSystemState.securityFramework then
		local isValid, message = assetSystemState.securityFramework.validateRequest(playerId, nil, nil)
		if not isValid then
			print(string.format("[Asset System] Access denied for player %d: %s", playerId, message))
			return nil, "Access denied: " .. message
		end
	end
	
	-- Check if asset exists
	local assetModel = assetSystemState.assets[assetPath]
	if not assetModel then
		print(string.format("[Asset System] Asset not found: %s", assetPath))
		return nil, "Asset not found"
	end
	
	-- Check if asset is loaded
	if not assetSystemState.loadedAssets[assetPath] then
		print(string.format("[Asset System] Asset not loaded: %s", assetPath))
		return nil, "Asset not loaded"
	end
	
	-- Clone and return asset with reconciliation tracking
	local clonedAsset = assetModel:Clone()
	print(string.format("[Asset System] Asset delivered to player %d: %s", playerId, assetPath))
	
	-- Record asset delivery in data reconciliation
	if assetSystemState.dataReconciliation then
		assetSystemState.dataReconciliation.recordOperation("ASSET_DELIVERY", {
			playerId = playerId,
			assetPath = assetPath,
			deliveryTime = tick(),
			success = true
		})
	end
	
	return clonedAsset, "Asset delivered successfully"
end

-- Get assets by category with reconciliation
function AssetSystem:getAssetsByCategory(categoryName)
	local categoryAssets = assetSystemState.assetCategories[categoryName]
	if not categoryAssets then
		return {}, "Category not found"
	end
	
	local assets = {}
	for _, assetPath in ipairs(categoryAssets) do
		if assetSystemState.loadedAssets[assetPath] then
			table.insert(assets, assetPath)
		end
	end
	
	-- Record category access in data reconciliation
	if assetSystemState.dataReconciliation then
		assetSystemState.dataReconciliation.recordOperation("CATEGORY_ACCESS", {
			categoryName = categoryName,
			accessTime = tick(),
			assetCount = #assets
		})
	end
	
	return assets, string.format("Found %d assets in category %s", #assets, categoryName)
end

-- Get asset statistics with reconciliation and data store integration
function AssetSystem:getAssetStats()
	local totalAssets = 0
	local loadedAssets = 0
	local categories = {}
	
	for categoryName, categoryAssets in pairs(assetSystemState.assetCategories) do
		totalAssets = totalAssets + #categoryAssets
		categories[categoryName] = #categoryAssets
		
		for _, assetPath in ipairs(categoryAssets) do
			if assetSystemState.loadedAssets[assetPath] then
				loadedAssets = loadedAssets + 1
			end
		end
	end
	
	-- Get reconciliation statistics
	local reconciliationStats = {}
	if assetSystemState.dataReconciliation then
		reconciliationStats = assetSystemState.dataReconciliation.getReconciliationStats()
	end
	
	-- Get data store statistics
	local datastoreStats = {}
	if assetSystemState.dataStoreManager then
		datastoreStats = assetSystemState.dataStoreManager.getDataStoreStats()
	end
	
	return {
		totalAssets = totalAssets,
		loadedAssets = loadedAssets,
		loadRate = totalAssets > 0 and (loadedAssets / totalAssets) * 100 or 0,
		categories = categories,
		isInitialized = assetSystemState.isInitialized,
		reconciliationStats = reconciliationStats,
		datastoreStats = datastoreStats
	}
end

-- Setup asset reconciliation
function AssetSystem:_setupAssetReconciliation()
	if assetSystemState.dataReconciliation then
		print("[Asset System] Setting up asset reconciliation...")
		
		-- Create asset reconciliation snapshots
		task.spawn(function()
			while true do
				task.wait(300) -- Create snapshots every 5 minutes
				assetSystemState.dataReconciliation.createSnapshot("ASSET_SYSTEM", {
					loadedAssets = assetSystemState.loadedAssets,
					assetCategories = assetSystemState.assetCategories,
					totalAssets = #table.keys(assetSystemState.assets)
				})
			end
		end)
	end
end

-- Monitor asset reconciliation
function AssetSystem:_monitorAssetReconciliation()
	if assetSystemState.dataReconciliation then
		local reconciliationStats = assetSystemState.dataReconciliation.getReconciliationStats()
		
		if reconciliationStats.pendingConflicts > 5 then
			print("[Asset System] High reconciliation conflicts detected - potential asset system issues")
		elseif reconciliationStats.failedConflicts > 2 then
			print("[Asset System] Reconciliation failures detected - investigating asset system integrity")
		end
	end
end

-- Monitor asset data store operations
function AssetSystem:_monitorAssetDataStoreOperations()
	if assetSystemState.dataStoreManager then
		local datastoreStats = assetSystemState.dataStoreManager.getDataStoreStats()
		
		if datastoreStats.failedOperations > 10 then
			print("[Asset System] High data store operation failures - potential asset data issues")
		elseif datastoreStats.pendingBackups > 20 then
			print("[Asset System] High pending backups - monitoring asset data synchronization")
		end
	end
end

-- Audit asset access with reconciliation
function AssetSystem:_auditAssetAccess()
	local stats = self:getAssetStats()
	
	print("[Asset System] Asset access audit:")
	print(string.format("  Total Assets: %d", stats.totalAssets))
	print(string.format("  Loaded Assets: %d (%.1f%%)", stats.loadedAssets, stats.loadRate))
	print("  Categories:")
	for categoryName, count in pairs(stats.categories) do
		print(string.format("    %s: %d", categoryName, count))
	end
	
	-- Print reconciliation status
	if stats.reconciliationStats then
		print("  Reconciliation Status:")
		print(string.format("    Total Snapshots: %d", stats.reconciliationStats.totalSnapshots))
		print(string.format("    Pending Conflicts: %d", stats.reconciliationStats.pendingConflicts))
		print(string.format("    Resolved Conflicts: %d", stats.reconciliationStats.resolvedConflicts))
	end
	
	-- Print data store status
	if stats.datastoreStats then
		print("  Data Store Status:")
		print(string.format("    Total Operations: %d", stats.datastoreStats.totalOperations))
		print(string.format("    Success Rate: %.1f%%", stats.datastoreStats.successRate))
		print(string.format("    Pending Backups: %d", stats.datastoreStats.pendingBackups))
	end
end

-- Check asset integrity with data store backup
function AssetSystem:_checkAssetIntegrity()
	print("[Asset System] Checking asset integrity with data store backup...")
	
	local integrityIssues = {}
	
	for assetPath, assetModel in pairs(assetSystemState.assets) do
		if not assetModel or not assetModel.Parent then
			table.insert(integrityIssues, assetPath)
			print(string.format("[Asset System] Integrity issue: %s", assetPath))
		end
	end
	
	if #integrityIssues > 0 then
		print(string.format("[Asset System] Found %d integrity issues - creating data store backup", #integrityIssues))
		
		-- Create data store backup for integrity issues
		if assetSystemState.dataStoreManager then
			assetSystemState.dataStoreManager.createBackup("ASSET_INTEGRITY", {
				integrityIssues = integrityIssues,
				timestamp = tick()
			})
		end
	else
		print("[Asset System] All assets integrity verified")
	end
end

-- Log asset performance with reconciliation
function AssetSystem:_logAssetPerformance()
	local stats = self:getAssetStats()
	
	print(string.format("[Asset System] Performance: Load Rate %.1f%%, Total %d, Loaded %d", 
		stats.loadRate, stats.totalAssets, stats.loadedAssets))
	
	-- Log reconciliation performance
	if stats.reconciliationStats then
		print(string.format("  Reconciliation: %d snapshots, %d conflicts", 
			stats.reconciliationStats.totalSnapshots, stats.reconciliationStats.pendingConflicts))
	end
	
	-- Log data store performance
	if stats.datastoreStats then
		print(string.format("  Data Store: %.1f%% success rate, %d pending backups", 
			stats.datastoreStats.successRate, stats.datastoreStats.pendingBackups))
	end
end

-- Cleanup asset references with data store cleanup
function AssetSystem:_cleanupAssetReferences()
	-- Cleanup old loaded asset references
	local currentAssets = {}
	for assetPath in pairs(assetSystemState.assets) do
		currentAssets[assetPath] = true
	end
	
	for loadedAssetPath in pairs(assetSystemState.loadedAssets) do
		if not currentAssets[loadedAssetPath] then
			assetSystemState.loadedAssets[loadedAssetPath] = nil
			print(string.format("[Asset System] Cleaned up reference: %s", loadedAssetPath))
		end
	end
	
	-- Cleanup old data store operations
	if assetSystemState.dataStoreManager then
		task.spawn(function()
			assetSystemState.dataStoreManager.cleanupOldOperations()
		end)
	end
end

-- Initialize global Asset System instance
local globalAssetSystem = AssetSystem.new()

-- Expose methods globally
function AssetSystem.preloadAllAssets()
	return globalAssetSystem:preloadAllAssets()
end

function AssetSystem.getAsset(playerId, assetPath)
	return globalAssetSystem:getAsset(playerId, assetPath)
end

function AssetSystem.getAssetsByCategory(categoryName)
	return globalAssetSystem:getAssetsByCategory(categoryName)
end

function AssetSystem.getAssetStats()
	return globalAssetSystem:getAssetStats()
end

print("[Asset System] Professional asset system v2.0 ready with Data Reconciliation and Data Store Management!")

return AssetSystem
