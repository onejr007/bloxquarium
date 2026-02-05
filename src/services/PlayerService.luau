-- Player Service
-- Business logic service for player management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BaseService = require(ReplicatedStorage.Framework.BaseService)
local PlayerModel = require(ReplicatedStorage.Framework.PlayerModel)
local Validation = require(ReplicatedStorage.Framework.Validation)

local PlayerService = BaseService.new()
PlayerService.Name = "PlayerService"

-- Constructor
function PlayerService.new()
	local self = setmetatable({}, PlayerService)
	
	self.Name = "PlayerService"
	self.PlayerModel = PlayerModel.new()
	self.Validation = Validation.new()
	self.PlayerCache = {}
	
	return self
end

-- Initialize service
function PlayerService:Initialize()
	BaseService.Initialize(self)
	self.PlayerModel:Initialize()
	self.Validation:Initialize()
	print("[PlayerService] Service initialized")
end

-- Create new player
function PlayerService:CreatePlayer(data)
	-- Validate input
	local validationRules = {
		username = { required = true, type = "string", min = 3, max = 20 },
		displayName = { required = false, type = "string", max = 50 },
		team = { required = false, type = "string" },
		level = { required = false, type = "number", default = 1 },
		experience = { required = false, type = "number", default = 0 },
		coins = { required = false, type = "number", default = 0 }
	}
	
	local isValid, errors = self.Validation:Validate(data, validationRules)
	if not isValid then
		return nil, errors
	end
	
	-- Check if username already exists
	local existingPlayer = self.PlayerModel:GetByUsername(data.username)
	if existingPlayer then
		return nil, { "Username already exists" }
	end
	
	-- Create player
	local playerData = {
		username = data.username,
		displayName = data.displayName or data.username,
		team = data.team or "Default",
		level = data.level or 1,
		experience = data.experience or 0,
		coins = data.coins or 0,
		createdAt = os.time(),
		updatedAt = os.time()
	}
	
	local player = self.PlayerModel:Create(playerData)
	if player then
		-- Cache player
		self.PlayerCache[player.id] = player
		self:Log("Player created: " .. player.username)
		return player
	else
		return nil, { "Failed to create player" }
	end
end

-- Get player by ID
function PlayerService:GetPlayer(playerId)
	-- Check cache first
	if self.PlayerCache[playerId] then
		return self.PlayerCache[playerId]
	end
	
	-- Get from model
	local player = self.PlayerModel:Find(playerId)
	if player then
		self.PlayerCache[playerId] = player
	end
	
	return player
end

-- Get player by username
function PlayerService:GetPlayerByUsername(username)
	return self.PlayerModel:GetByUsername(username)
end

-- Update player
function PlayerService:UpdatePlayer(playerId, data)
	local player = self:GetPlayer(playerId)
	if not player then
		return nil, { "Player not found" }
	end
	
	-- Validate update data
	local validationRules = {
		displayName = { required = false, type = "string", max = 50 },
		team = { required = false, type = "string" },
		level = { required = false, type = "number" },
		experience = { required = false, type = "number" },
		coins = { required = false, type = "number" }
	}
	
	local isValid, errors = self.Validation:Validate(data, validationRules)
	if not isValid then
		return nil, errors
	end
	
	-- Update player
	local updateData = {}
	if data.displayName then updateData.displayName = data.displayName end
	if data.team then updateData.team = data.team end
	if data.level then updateData.level = data.level end
	if data.experience then updateData.experience = data.experience end
	if data.coins then updateData.coins = data.coins end
	updateData.updatedAt = os.time()
	
	local updatedPlayer = self.PlayerModel:Update(playerId, updateData)
	if updatedPlayer then
		-- Update cache
		self.PlayerCache[playerId] = updatedPlayer
		self:Log("Player updated: " .. updatedPlayer.username)
		return updatedPlayer
	else
		return nil, { "Failed to update player" }
	end
end

-- Delete player
function PlayerService:DeletePlayer(playerId)
	local player = self:GetPlayer(playerId)
	if not player then
		return false, { "Player not found" }
	end
	
	local success = self.PlayerModel:Delete(playerId)
	if success then
		-- Remove from cache
		self.PlayerCache[playerId] = nil
		self:Log("Player deleted: " .. player.username)
		return true
	else
		return false, { "Failed to delete player" }
	end
end

-- Get all players
function PlayerService:GetAllPlayers()
	return self.PlayerModel:All()
end

-- Get players by team
function PlayerService:GetPlayersByTeam(team)
	return self.PlayerModel:GetByTeam(team)
end

-- Get players by level range
function PlayerService:GetPlayersByLevelRange(minLevel, maxLevel)
	return self.PlayerModel:GetByLevelRange(minLevel, maxLevel)
end

-- Get top players by experience
function PlayerService:GetTopPlayers(limit)
	return self.PlayerModel:GetTopPlayers(limit)
end

-- Level up player
function PlayerService:LevelUp(playerId, levels)
	local player = self:GetPlayer(playerId)
	if not player then
		return nil, { "Player not found" }
	end
	
	local updatedPlayer, message = self.PlayerModel:LevelUp(playerId, levels)
	if updatedPlayer then
		self.PlayerCache[playerId] = updatedPlayer
		self:Log("Player leveled up: " .. updatedPlayer.username .. " (Level " .. updatedPlayer.level .. ")")
		return updatedPlayer, message
	else
		return nil, { message }
	end
end

-- Add experience to player
function PlayerService:AddExperience(playerId, amount)
	local player = self:GetPlayer(playerId)
	if not player then
		return nil, { "Player not found" }
	end
	
	local updatedPlayer, message = self.PlayerModel:AddExperience(playerId, amount)
	if updatedPlayer then
		self.PlayerCache[playerId] = updatedPlayer
		self:Log("Player gained experience: " .. updatedPlayer.username .. " (+" .. amount .. " XP)")
		return updatedPlayer, message
	else
		return nil, { message }
	end
end

-- Add coins to player
function PlayerService:AddCoins(playerId, amount)
	local player = self:GetPlayer(playerId)
	if not player then
		return nil, { "Player not found" }
	end
	
	local updatedPlayer = self.PlayerModel:AddCoins(playerId, amount)
	if updatedPlayer then
		self.PlayerCache[playerId] = updatedPlayer
		self:Log("Player gained coins: " .. updatedPlayer.username .. " (+" .. amount .. " coins)")
		return updatedPlayer
	else
		return nil, { "Failed to add coins" }
	end
end

-- Remove coins from player
function PlayerService:RemoveCoins(playerId, amount)
	local player = self:GetPlayer(playerId)
	if not player then
		return nil, { "Player not found" }
	end
	
	local updatedPlayer, message = self.PlayerModel:RemoveCoins(playerId, amount)
	if updatedPlayer then
		self.PlayerCache[playerId] = updatedPlayer
		self:Log("Player lost coins: " .. updatedPlayer.username .. " (-" .. amount .. " coins)")
		return updatedPlayer
	else
		return nil, { message }
	end
end

-- Change player team
function PlayerService:ChangeTeam(playerId, newTeam)
	local player = self:GetPlayer(playerId)
	if not player then
		return nil, { "Player not found" }
	end
	
	local updatedPlayer = self.PlayerModel:ChangeTeam(playerId, newTeam)
	if updatedPlayer then
		self.PlayerCache[playerId] = updatedPlayer
		self:Log("Player changed team: " .. updatedPlayer.username .. " -> " .. newTeam)
		return updatedPlayer
	else
		return nil, { "Failed to change team" }
	end
end

-- Reset player stats
function PlayerService:ResetStats(playerId)
	local player = self:GetPlayer(playerId)
	if not player then
		return nil, { "Player not found" }
	end
	
	local updatedPlayer = self.PlayerModel:ResetStats(playerId)
	if updatedPlayer then
		self.PlayerCache[playerId] = updatedPlayer
		self:Log("Player stats reset: " .. updatedPlayer.username)
		return updatedPlayer
	else
		return nil, { "Failed to reset stats" }
	end
end

-- Get player statistics
function PlayerService:GetStatistics()
	return self.PlayerModel:GetStatistics()
end

-- Get online players count
function PlayerService:GetOnlinePlayersCount()
	return #Players:GetPlayers()
end

-- Get player by Roblox player object
function PlayerService:GetPlayerByRobloxPlayer(robloxPlayer)
	if not robloxPlayer then
		return nil
	end
	
	-- Try to find by username first
	local player = self:GetPlayerByUsername(robloxPlayer.Name)
	if player then
		return player
	end
	
	-- Create player if not exists
	player = self:CreatePlayer({
		username = robloxPlayer.Name,
		displayName = robloxPlayer.DisplayName,
		team = robloxPlayer.Team and robloxPlayer.Team.Name or "Default"
	})
	
	return player
end

-- Update player from Roblox player
function PlayerService:UpdatePlayerFromRoblox(playerId, robloxPlayer)
	local player = self:GetPlayer(playerId)
	if not player then
		return nil, { "Player not found" }
	end
	
	local updateData = {}
	if robloxPlayer.DisplayName ~= player.displayName then
		updateData.displayName = robloxPlayer.DisplayName
	end
	
	if robloxPlayer.Team and robloxPlayer.Team.Name ~= player.team then
		updateData.team = robloxPlayer.Team.Name
	end
	
	if next(updateData) ~= nil then
		return self:UpdatePlayer(playerId, updateData)
	else
		return player
	end
end

-- Get player leaderboard
function PlayerService:GetLeaderboard(sortBy, limit)
	local players = self:GetAllPlayers()
	
	-- Sort players
	if sortBy == "experience" then
		table.sort(players, function(a, b)
			return a.experience > b.experience
		end)
	elseif sortBy == "level" then
		table.sort(players, function(a, b)
			return a.level > b.level
		end)
	elseif sortBy == "coins" then
		table.sort(players, function(a, b)
			return a.coins > b.coins
		end)
	else
		-- Default sort by experience
		table.sort(players, function(a, b)
			return a.experience > b.experience
		end)
	end
	
	-- Limit results
	local leaderboard = {}
	for i = 1, math.min(limit or #players, #players) do
		table.insert(leaderboard, players[i])
	end
	
	return leaderboard
end

-- Export player data
function PlayerService:ExportPlayers()
	return self.PlayerModel:ExportAll()
end

-- Import player data
function PlayerService:ImportPlayers(playersData)
	return self.PlayerModel:Import(playersData)
end

-- Backup player data
function PlayerService:Backup()
	return self.PlayerModel:Backup()
end

-- Restore player data
function PlayerService:Restore(backupData)
	return self.PlayerModel:Restore(backupData)
end

-- Clear player cache
function PlayerService:ClearCache()
	self.PlayerCache = {}
	self:Log("Player cache cleared")
end

-- Get cache statistics
function PlayerService:GetCacheStats()
	return {
		cacheSize = #self.PlayerCache,
		totalPlayers = self.PlayerModel:Count()
	}
end

return PlayerService