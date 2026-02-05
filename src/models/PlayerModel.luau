-- Player Model
-- Example model demonstrating MVC framework usage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseModel = require(ReplicatedStorage.Framework.BaseModel)

local PlayerModel = BaseModel.new()
PlayerModel.Name = "PlayerModel"

-- Initialize model
function PlayerModel:Initialize()
	BaseModel.Initialize(self)
	self:Log("PlayerModel initialized")
end

-- Define model fields
function PlayerModel:SetupFields()
	self.Fields = {
		id = { type = "number", required = true },
		username = { type = "string", required = true, min = 3, max = 20 },
		displayName = { type = "string", required = false, max = 50 },
		team = { type = "string", required = false, default = "Default" },
		level = { type = "number", required = false, default = 1 },
		experience = { type = "number", required = false, default = 0 },
		coins = { type = "number", required = false, default = 0 },
		createdAt = { type = "number", required = true },
		updatedAt = { type = "number", required = true }
	}
end

-- Create initial data
function PlayerModel:CreateInitialData()
	self:SetupFields()
	
	-- Create some sample players
	self:Create({
		username = "player1",
		displayName = "Player One",
		team = "Red",
		level = 5,
		experience = 1500,
		coins = 100,
		createdAt = os.time(),
		updatedAt = os.time()
	})
	
	self:Create({
		username = "player2",
		displayName = "Player Two",
		team = "Blue",
		level = 3,
		experience = 800,
		coins = 50,
		createdAt = os.time(),
		updatedAt = os.time()
	})
	
	self:Create({
		username = "player3",
		displayName = "Player Three",
		team = "Green",
		level = 8,
		experience = 2500,
		coins = 200,
		createdAt = os.time(),
		updatedAt = os.time()
	})
	
	print("[Model] Sample player data created")
end

-- Get player by username
function PlayerModel:GetByUsername(username)
	return self:Where({ username = username })[1]
end

-- Get player by display name
function PlayerModel:GetByDisplayName(displayName)
	return self:Where({ displayName = displayName })[1]
end

-- Get players by team
function PlayerModel:GetByTeam(team)
	return self:Where({ team = team })
end

-- Get players by level range
function PlayerModel:GetByLevelRange(minLevel, maxLevel)
	local results = {}
	for _, player in pairs(self.Table) do
		if player.level >= minLevel and player.level <= maxLevel then
			table.insert(results, player)
		end
	end
	return results
end

-- Get top players by experience
function PlayerModel:GetTopPlayers(limit)
	local players = {}
	for _, player in pairs(self.Table) do
		table.insert(players, player)
	end
	
	-- Sort by experience (descending)
	table.sort(players, function(a, b)
		return a.experience > b.experience
	end)
	
	-- Return top N players
	local topPlayers = {}
	for i = 1, math.min(limit or #players, #players) do
		table.insert(topPlayers, players[i])
	end
	
	return topPlayers
end

-- Level up player
function PlayerModel:LevelUp(playerId, levels)
	local player = self:Find(playerId)
	if not player then
		return nil, "Player not found"
	end
	
	player.level = player.level + (levels or 1)
	player.updatedAt = os.time()
	
	return player
end

-- Add experience to player
function PlayerModel:AddExperience(playerId, amount)
	local player = self:Find(playerId)
	if not player then
		return nil, "Player not found"
	end
	
	player.experience = player.experience + (amount or 0)
	player.updatedAt = os.time()
	
	-- Check for level up
	local newLevel = math.floor(player.experience / 500) + 1
	if newLevel > player.level then
		player.level = newLevel
		return player, "Level up!"
	end
	
	return player
end

-- Add coins to player
function PlayerModel:AddCoins(playerId, amount)
	local player = self:Find(playerId)
	if not player then
		return nil, "Player not found"
	end
	
	player.coins = player.coins + (amount or 0)
	player.updatedAt = os.time()
	
	return player
end

-- Remove coins from player
function PlayerModel:RemoveCoins(playerId, amount)
	local player = self:Find(playerId)
	if not player then
		return nil, "Player not found"
	end
	
	if player.coins < amount then
		return nil, "Insufficient coins"
	end
	
	player.coins = player.coins - amount
	player.updatedAt = os.time()
	
	return player
end

-- Change player team
function PlayerModel:ChangeTeam(playerId, newTeam)
	local player = self:Find(playerId)
	if not player then
		return nil, "Player not found"
	end
	
	player.team = newTeam or player.team
	player.updatedAt = os.time()
	
	return player
end

-- Reset player stats
function PlayerModel:ResetStats(playerId)
	local player = self:Find(playerId)
	if not player then
		return nil, "Player not found"
	end
	
	player.level = 1
	player.experience = 0
	player.coins = 0
	player.updatedAt = os.time()
	
	return player
end

-- Get player statistics
function PlayerModel:GetStatistics()
	local stats = {
		totalPlayers = self:Count(),
		averageLevel = 0,
		averageExperience = 0,
		totalCoins = 0,
		teamCounts = {}
	}
	
	if stats.totalPlayers == 0 then
		return stats
	end
	
	local totalLevel = 0
	local totalExperience = 0
	
	for _, player in pairs(self.Table) do
		totalLevel = totalLevel + player.level
		totalExperience = totalExperience + player.experience
		stats.totalCoins = stats.totalCoins + player.coins
		
		-- Count teams
		if not stats.teamCounts[player.team] then
			stats.teamCounts[player.team] = 0
		end
		stats.teamCounts[player.team] = stats.teamCounts[player.team] + 1
	end
	
	stats.averageLevel = totalLevel / stats.totalPlayers
	stats.averageExperience = totalExperience / stats.totalPlayers
	
	return stats
end

-- Export all players to JSON
function PlayerModel:ExportAll()
	local exportData = {
		exportTime = os.time(),
		totalPlayers = self:Count(),
		players = {}
	}
	
	for _, player in pairs(self.Table) do
		table.insert(exportData.players, self:ToJson(player))
	end
	
	return exportData
end

-- Import players from JSON
function PlayerModel:Import(playersData)
	if type(playersData) ~= "table" then
		return false, "Invalid data format"
	end
	
	local importedCount = 0
	for _, playerData in pairs(playersData) do
		if type(playerData) == "table" then
			local player = self:FromJson(playerData)
			if player then
				self:Create(player)
				importedCount = importedCount + 1
			end
		end
	end
	
	return true, "Imported " .. importedCount .. " players"
end

-- Backup player data
function PlayerModel:Backup()
	local backupData = {
		backupTime = os.time(),
		modelName = self.Name,
		data = self.Table
	}
	
	return backupData
end

-- Restore from backup
function PlayerModel:Restore(backupData)
	if not backupData or backupData.modelName ~= self.Name then
		return false, "Invalid backup data"
	end
	
	self.Table = backupData.data
	return true, "Data restored successfully"
end

return PlayerModel