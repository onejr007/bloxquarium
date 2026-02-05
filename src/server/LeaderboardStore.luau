-- Leaderboard Store System v1.0
-- Professional leaderboard system with real-time updates, persistence, and ranking algorithms
-- Supports multiple leaderboard types with caching and performance optimization

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LeaderboardStore = {}
LeaderboardStore.__index = LeaderboardStore

-- Leaderboard configuration
local LEADERBOARD_CONFIG = {
	MAX_LEADERBOARD_SIZE = 1000,
	CACHE_UPDATE_INTERVAL = 30, -- 30 seconds
	RANKING_ALGORITHM = "ELO", -- ELO, WIN_LOSS, POINTS
	ENABLE_REAL_TIME_UPDATES = true,
	ENABLE_HISTORICAL_DATA = true,
	MAX_HISTORICAL_ENTRIES = 100,
	ENABLE_SEASONAL_RESETS = true
}

-- Leaderboard state
local leaderboardState = {
	leaderboards = {}, -- Active leaderboards
	cache = {}, -- Cached leaderboard data
	historicalData = {}, -- Historical leaderboard snapshots
	seasonalData = {}, -- Seasonal leaderboard data
	updateQueue = {}, -- Queue for updates
	rankingCache = {} -- Cached ranking calculations
}

-- Leaderboard structure
local Leaderboard = {
	__index = Leaderboard
}

function Leaderboard.new(name, description, rankingType, maxSize)
	local self = setmetatable({}, Leaderboard)
	self.name = name
	self.description = description
	self.rankingType = rankingType -- "POINTS", "WINS", "TIME", "SCORE"
	self.maxSize = maxSize or LEADERBOARD_CONFIG.MAX_LEADERBOARD_SIZE
	self.entries = {} -- {playerId = {value, rank, lastUpdated}}
	self.lastUpdated = tick()
	self.totalEntries = 0
	self.seasonalReset = false
	return self
end

-- Initialize the Leaderboard Store System
function LeaderboardStore.new()
	local self = setmetatable({}, LeaderboardStore)
	
	-- Setup leaderboard monitoring
	self:_setupLeaderboardMonitoring()
	
	-- Setup cache management
	self:_setupCacheManagement()
	
	-- Setup player handlers
	self:_setupPlayerHandlers()
	
	-- Setup data persistence
	self:_setupDataPersistence()
	
	print("[Leaderboard Store] Initialized with professional-grade ranking system")
	
	return self
end

-- Setup leaderboard monitoring
function LeaderboardStore:_setupLeaderboardMonitoring()
	-- Monitor leaderboard health
	spawn(function()
		while true do
			task.wait(300) -- Check every 5 minutes
			self:_performLeaderboardHealthCheck()
		end
	end)
	
	-- Process update queue
	spawn(function()
		while true do
			task.wait(1) -- Process updates every second
			self:_processUpdateQueue()
		end
	end)
end

-- Setup cache management
function LeaderboardStore:_setupCacheManagement()
	-- Update cache periodically
	spawn(function()
		while true do
			task.wait(LEADERBOARD_CONFIG.CACHE_UPDATE_INTERVAL)
			self:_updateLeaderboardCache()
		end
	end)
end

-- Setup player handlers
function LeaderboardStore:_setupPlayerHandlers()
	Players.PlayerAdded:Connect(function(player)
		self:_handlePlayerJoin(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:_handlePlayerLeave(player)
	end)
end

-- Setup data persistence
function LeaderboardStore:_setupDataPersistence()
	-- Save leaderboards periodically
	spawn(function()
		while true do
			task.wait(600) -- Save every 10 minutes
			self:_saveLeaderboardData()
		end
	end)
end

-- Create a new leaderboard
function LeaderboardStore:createLeaderboard(name, description, rankingType, maxSize)
	if leaderboardState.leaderboards[name] then
		return false, "Leaderboard already exists"
	end
	
	local leaderboard = Leaderboard.new(name, description, rankingType, maxSize)
	leaderboardState.leaderboards[name] = leaderboard
	
	-- Load existing data
	self:_loadLeaderboardData(name)
	
	print(string.format("[Leaderboard Store] Created leaderboard: %s", name))
	
	return true, leaderboard
end

-- Update player score
function LeaderboardStore:updatePlayerScore(leaderboardName, playerId, newValue, metadata)
	local leaderboard = leaderboardState.leaderboards[leaderboardName]
	if not leaderboard then
		return false, "Leaderboard not found"
	end
	
	-- Get current entry
	local currentEntry = leaderboard.entries[playerId]
	local oldValue = currentEntry and currentEntry.value or 0
	
	-- Calculate new value based on ranking type
	local finalValue = self:_calculateNewValue(leaderboard.rankingType, oldValue, newValue, metadata)
	
	-- Update entry
	leaderboard.entries[playerId] = {
		value = finalValue,
		rank = 0, -- Will be recalculated
		lastUpdated = tick(),
		metadata = metadata or {}
	}
	
	leaderboard.lastUpdated = tick()
	leaderboard.totalEntries = #table.keys(leaderboard.entries)
	
	-- Add to update queue
	self:_addToUpdateQueue(leaderboardName, playerId, finalValue)
	
	-- Update cache
	self:_updateLeaderboardCache(leaderboardName)
	
	return true, {
		oldValue = oldValue,
		newValue = finalValue,
		change = finalValue - oldValue
	}
end

-- Get leaderboard entries
function LeaderboardStore:getLeaderboard(leaderboardName, limit, offset)
	local leaderboard = leaderboardState.leaderboards[leaderboardName]
	if not leaderboard then
		return nil, "Leaderboard not found"
	end
	
	-- Get from cache if available
	local cached = leaderboardState.cache[leaderboardName]
	if cached then
		local entries = cached.entries
		local total = #entries
		
		-- Apply pagination
		local start = offset or 1
		local endIdx = math.min(start + (limit or 100) - 1, total)
		
		local result = {}
		for i = start, endIdx do
			if entries[i] then
				table.insert(result, entries[i])
			end
		end
		
		return {
			name = leaderboard.name,
			description = leaderboard.description,
			rankingType = leaderboard.rankingType,
			entries = result,
			totalEntries = total,
			lastUpdated = cached.lastUpdated
		}
	else
		-- Calculate rankings and return
		return self:_calculateLeaderboardRankings(leaderboard, limit, offset)
	end
end

-- Get player rank
function LeaderboardStore:getPlayerRank(leaderboardName, playerId)
	local leaderboard = leaderboardState.leaderboards[leaderboardName]
	if not leaderboard then
		return nil, "Leaderboard not found"
	end
	
	local entry = leaderboard.entries[playerId]
	if not entry then
		return {rank = 0, value = 0, percentile = 0}
	end
	
	-- Get from cache for performance
	local cached = leaderboardState.cache[leaderboardName]
	if cached then
		for rank, entry in ipairs(cached.entries) do
			if entry.playerId == playerId then
				return {
					rank = rank,
					value = entry.value,
					percentile = (rank / cached.totalEntries) * 100
				}
			end
		end
	end
	
	-- Calculate if not in cache
	return self:_calculatePlayerRank(leaderboard, playerId)
end

-- Get top players
function LeaderboardStore:getTopPlayers(leaderboardName, count)
	return self:getLeaderboard(leaderboardName, count, 1)
end

-- Reset leaderboard
function LeaderboardStore:resetLeaderboard(leaderboardName, reason)
	local leaderboard = leaderboardState.leaderboards[leaderboardName]
	if not leaderboard then
		return false, "Leaderboard not found"
	end
	
	-- Create historical snapshot before reset
	if LEADERBOARD_CONFIG.ENABLE_HISTORICAL_DATA then
		self:_createHistoricalSnapshot(leaderboardName, "RESET", reason)
	end
	
	-- Reset entries
	leaderboard.entries = {}
	leaderboard.lastUpdated = tick()
	leaderboard.totalEntries = 0
	
	-- Update cache
	self:_updateLeaderboardCache(leaderboardName)
	
	print(string.format("[Leaderboard Store] Reset leaderboard %s: %s", leaderboardName, reason or "Manual reset"))
	
	return true, "Leaderboard reset successfully"
end

-- Seasonal reset
function LeaderboardStore:seasonalReset(leaderboardName, seasonNumber)
	local leaderboard = leaderboardState.leaderboards[leaderboardName]
	if not leaderboard then
		return false, "Leaderboard not found"
	end
	
	-- Create seasonal snapshot
	if LEADERBOARD_CONFIG.ENABLE_SEASONAL_RESETS then
		self:_createSeasonalSnapshot(leaderboardName, seasonNumber)
	end
	
	-- Reset for new season
	return self:resetLeaderboard(leaderboardName, string.format("Season %d reset", seasonNumber))
end

-- Calculate new value based on ranking type
function LeaderboardStore:_calculateNewValue(rankingType, oldValue, newValue, metadata)
	if rankingType == "POINTS" then
		return oldValue + newValue
	elseif rankingType == "WINS" then
		return oldValue + (newValue > 0 and 1 or 0)
	elseif rankingType == "TIME" then
		return math.max(oldValue, newValue) -- Best time
	elseif rankingType == "SCORE" then
		return math.max(oldValue, newValue) -- High score
	else
		return oldValue + newValue
	end
end

-- Add to update queue
function LeaderboardStore:_addToUpdateQueue(leaderboardName, playerId, value)
	local update = {
		leaderboardName = leaderboardName,
		playerId = playerId,
		value = value,
		timestamp = tick()
	}
	
	table.insert(leaderboardState.updateQueue, update)
	
	-- Limit queue size
	if #leaderboardState.updateQueue > 1000 then
		table.remove(leaderboardState.updateQueue, 1)
	end
end

-- Process update queue
function LeaderboardStore:_processUpdateQueue()
	if #leaderboardState.updateQueue == 0 then
		return
	end
	
	-- Process updates in batches
	local batchSize = 10
	local processed = 0
	
	for i = 1, math.min(batchSize, #leaderboardState.updateQueue) do
		local update = leaderboardState.updateQueue[1]
		
		if update then
			-- Recalculate rankings for this leaderboard
			self:_updateLeaderboardCache(update.leaderboardName)
			
			-- Remove from queue
			table.remove(leaderboardState.updateQueue, 1)
			processed = processed + 1
		end
	end
end

-- Update leaderboard cache
function LeaderboardStore:_updateLeaderboardCache(leaderboardName)
	if leaderboardName then
		-- Update specific leaderboard
		local leaderboard = leaderboardState.leaderboards[leaderboardName]
		if leaderboard then
			leaderboardState.cache[leaderboardName] = self:_calculateLeaderboardRankings(leaderboard)
		end
	else
		-- Update all leaderboards
		for name, leaderboard in pairs(leaderboardState.leaderboards) do
			leaderboardState.cache[name] = self:_calculateLeaderboardRankings(leaderboard)
		end
	end
end

-- Calculate leaderboard rankings
function LeaderboardStore:_calculateLeaderboardRankings(leaderboard, limit, offset)
	local entries = {}
	
	-- Convert to array and sort
	for playerId, entry in pairs(leaderboard.entries) do
		table.insert(entries, {
			playerId = playerId,
			value = entry.value,
			lastUpdated = entry.lastUpdated,
			metadata = entry.metadata
		})
	end
	
	-- Sort by value (descending)
	table.sort(entries, function(a, b)
		return a.value > b.value
	end)
	
	-- Assign ranks
	for i, entry in ipairs(entries) do
		entry.rank = i
	end
	
	-- Apply pagination
	local start = offset or 1
	local endIdx = math.min(start + (limit or 100) - 1, #entries)
	
	local resultEntries = {}
	for i = start, endIdx do
		if entries[i] then
			table.insert(resultEntries, entries[i])
		end
	end
	
	return {
		name = leaderboard.name,
		description = leaderboard.description,
		rankingType = leaderboard.rankingType,
		entries = resultEntries,
		totalEntries = #entries,
		lastUpdated = leaderboard.lastUpdated
	}
end

-- Calculate player rank
function LeaderboardStore:_calculatePlayerRank(leaderboard, playerId)
	local allEntries = {}
	
	for pid, entry in pairs(leaderboard.entries) do
		table.insert(allEntries, {
			playerId = pid,
			value = entry.value
		})
	end
	
	table.sort(allEntries, function(a, b)
		return a.value > b.value
	end)
	
	local rank = 0
	local value = 0
	
	for i, entry in ipairs(allEntries) do
		if entry.playerId == playerId then
			rank = i
			value = entry.value
			break
		end
	end
	
	return {
		rank = rank,
		value = value,
		percentile = rank > 0 and (rank / #allEntries) * 100 or 0
	}
end

-- Create historical snapshot
function LeaderboardStore:_createHistoricalSnapshot(leaderboardName, eventType, reason)
	local leaderboard = leaderboardState.leaderboards[leaderboardName]
	if not leaderboard then
		return
	end
	
	local snapshot = {
		leaderboardName = leaderboardName,
		eventType = eventType,
		reason = reason,
		timestamp = tick(),
		entries = table.clone(leaderboard.entries),
		totalEntries = leaderboard.totalEntries
	}
	
	if not leaderboardState.historicalData[leaderboardName] then
		leaderboardState.historicalData[leaderboardName] = {}
	end
	
	table.insert(leaderboardState.historicalData[leaderboardName], snapshot)
	
	-- Limit historical data size
	if #leaderboardState.historicalData[leaderboardName] > LEADERBOARD_CONFIG.MAX_HISTORICAL_ENTRIES then
		table.remove(leaderboardState.historicalData[leaderboardName], 1)
	end
end

-- Create seasonal snapshot
function LeaderboardStore:_createSeasonalSnapshot(leaderboardName, seasonNumber)
	local leaderboard = leaderboardState.leaderboards[leaderboardName]
	if not leaderboard then
		return
	end
	
	local snapshot = {
		seasonNumber = seasonNumber,
		timestamp = tick(),
		entries = table.clone(leaderboard.entries),
		totalEntries = leaderboard.totalEntries
	}
	
	if not leaderboardState.seasonalData[leaderboardName] then
		leaderboardState.seasonalData[leaderboardName] = {}
	end
	
	leaderboardState.seasonalData[leaderboardName][seasonNumber] = snapshot
end

-- Load leaderboard data
function LeaderboardStore:_loadLeaderboardData(leaderboardName)
	local datastore = DataStoreService:GetDataStore("LeaderboardDatastore")
	
	local success, result = pcall(function()
		return datastore:GetAsync(leaderboardName)
	end)
	
	if success and result then
		local leaderboard = leaderboardState.leaderboards[leaderboardName]
		leaderboard.entries = result.entries or {}
		leaderboard.lastUpdated = result.lastUpdated or tick()
		leaderboard.totalEntries = #table.keys(leaderboard.entries)
		
		print(string.format("[Leaderboard Store] Loaded data for leaderboard: %s", leaderboardName))
	else
		print(string.format("[Leaderboard Store] No existing data for leaderboard: %s", leaderboardName))
	end
end

-- Save leaderboard data
function LeaderboardStore:_saveLeaderboardData()
	for name, leaderboard in pairs(leaderboardState.leaderboards) do
		local datastore = DataStoreService:GetDataStore("LeaderboardDatastore")
		
		local data = {
			entries = leaderboard.entries,
			lastUpdated = leaderboard.lastUpdated,
			totalEntries = leaderboard.totalEntries
		}
		
		local success, result = pcall(function()
			return datastore:SetAsync(name, data)
		end)
		
		if not success then
			warn(string.format("[Leaderboard Store] Failed to save leaderboard %s: %s", name, result))
		end
	end
end

-- Handle player join
function LeaderboardStore:_handlePlayerJoin(player)
	-- Initialize player data if needed
	-- In a real implementation, you might want to preload player data
end

-- Handle player leave
function LeaderboardStore:_handlePlayerLeave(player)
	-- Cleanup player data if needed
	-- In a real implementation, you might want to save player data
end

-- Perform leaderboard health check
function LeaderboardStore:_performLeaderboardHealthCheck()
	local totalLeaderboards = #table.keys(leaderboardState.leaderboards)
	local totalEntries = 0
	local cachedLeaderboards = 0
	
	for name, leaderboard in pairs(leaderboardState.leaderboards) do
		totalEntries = totalEntries + leaderboard.totalEntries
		
		if leaderboardState.cache[name] then
			cachedLeaderboards = cachedLeaderboards + 1
		end
	end
	
	print(string.format(
		"[Leaderboard Store] Health Check: Leaderboards: %d | Total Entries: %d | Cached: %d",
		totalLeaderboards, totalEntries, cachedLeaderboards
	))
	
	-- Log health metrics
	if totalEntries == 0 then
		warn("[Leaderboard Store] No leaderboard entries found")
	end
end

-- Get leaderboard statistics
function LeaderboardStore:getLeaderboardStats()
	local stats = {
		totalLeaderboards = #table.keys(leaderboardState.leaderboards),
		totalEntries = 0,
		cachedLeaderboards = 0,
		updateQueueSize = #leaderboardState.updateQueue,
		historicalDataSize = 0,
		seasonalDataSize = 0
	}
	
	for name, leaderboard in pairs(leaderboardState.leaderboards) do
		stats.totalEntries = stats.totalEntries + leaderboard.totalEntries
		
		if leaderboardState.cache[name] then
			stats.cachedLeaderboards = stats.cachedLeaderboards + 1
		end
		
		if leaderboardState.historicalData[name] then
			stats.historicalDataSize = stats.historicalDataSize + #leaderboardState.historicalData[name]
		end
		
		if leaderboardState.seasonalData[name] then
			stats.seasonalDataSize = stats.seasonalDataSize + #table.keys(leaderboardState.seasonalData[name])
		end
	end
	
	return stats
end

-- Get leaderboard details
function LeaderboardStore:getLeaderboardDetails(name)
	local leaderboard = leaderboardState.leaderboards[name]
	if not leaderboard then
		return nil
	end
	
	return {
		name = leaderboard.name,
		description = leaderboard.description,
		rankingType = leaderboard.rankingType,
		maxSize = leaderboard.maxSize,
		totalEntries = leaderboard.totalEntries,
		lastUpdated = leaderboard.lastUpdated,
		hasCache = leaderboardState.cache[name] ~= nil
	}
end

-- Get historical data
function LeaderboardStore:getHistoricalData(leaderboardName, limit)
	local historical = leaderboardState.historicalData[leaderboardName]
	if not historical then
		return {}
	end
	
	local count = limit or 10
	local startIndex = math.max(1, #historical - count + 1)
	
	local result = {}
	for i = startIndex, #historical do
		table.insert(result, historical[i])
	end
	
	return result
end

-- Get seasonal data
function LeaderboardStore:getSeasonalData(leaderboardName, seasonNumber)
	if not leaderboardState.seasonalData[leaderboardName] then
		return nil
	end
	
	return leaderboardState.seasonalData[leaderboardName][seasonNumber]
end

-- Force cache update
function LeaderboardStore:forceCacheUpdate(leaderboardName)
	if leaderboardName then
		self:_updateLeaderboardCache(leaderboardName)
	else
		self:_updateLeaderboardCache()
	end
	
	return true, "Cache update initiated"
end

-- Initialize global Leaderboard Store instance
local globalLeaderboardStore = LeaderboardStore.new()

-- Expose methods globally
function LeaderboardStore.createLeaderboard(name, description, rankingType, maxSize)
	return globalLeaderboardStore:createLeaderboard(name, description, rankingType, maxSize)
end

function LeaderboardStore.updatePlayerScore(leaderboardName, playerId, newValue, metadata)
	return globalLeaderboardStore:updatePlayerScore(leaderboardName, playerId, newValue, metadata)
end

function LeaderboardStore.getLeaderboard(leaderboardName, limit, offset)
	return globalLeaderboardStore:getLeaderboard(leaderboardName, limit, offset)
end

function LeaderboardStore.getPlayerRank(leaderboardName, playerId)
	return globalLeaderboardStore:getPlayerRank(leaderboardName, playerId)
end

function LeaderboardStore.getTopPlayers(leaderboardName, count)
	return globalLeaderboardStore:getTopPlayers(leaderboardName, count)
end

function LeaderboardStore.resetLeaderboard(leaderboardName, reason)
	return globalLeaderboardStore:resetLeaderboard(leaderboardName, reason)
end

function LeaderboardStore.seasonalReset(leaderboardName, seasonNumber)
	return globalLeaderboardStore:seasonalReset(leaderboardName, seasonNumber)
end

function LeaderboardStore.getLeaderboardStats()
	return globalLeaderboardStore:getLeaderboardStats()
end

function LeaderboardStore.getLeaderboardDetails(name)
	return globalLeaderboardStore:getLeaderboardDetails(name)
end

function LeaderboardStore.getHistoricalData(leaderboardName, limit)
	return globalLeaderboardStore:getHistoricalData(leaderboardName, limit)
end

function LeaderboardStore.getSeasonalData(leaderboardName, seasonNumber)
	return globalLeaderboardStore:getSeasonalData(leaderboardName, seasonNumber)
end

function LeaderboardStore.forceCacheUpdate(leaderboardName)
	return globalLeaderboardStore:forceCacheUpdate(leaderboardName)
end

print("[Leaderboard Store] Professional leaderboard system ready!")

return LeaderboardStore