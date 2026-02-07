--[[
    LeaderboardService.luau (v1.5 - COMPATIBILITY FIX)

    - This version fixes the breaking changes introduced by the `DataService` rewrite.
    - It now calls the correct function: `DataService:Get(player)` instead of the old `:GetPlayerData()`.
    - It correctly listens to the `StateUpdated` event and handles its new argument signature.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(ServerScriptService.DataService)

local LeaderboardService = {}

local function createLeaderstat(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = leaderstats

    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = 0
    level.Parent = leaderstats

    return leaderstats
end

local function updateLeaderboard(player, playerData)
    -- Add a safety check in case this is called before data is ready
    if not player or not playerData then return end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        warn("Leaderstats not found for player: " .. player.Name)
        return
    end

    if leaderstats:FindFirstChild("Coins") then
        leaderstats.Coins.Value = playerData.Coins or 0 -- Property names are case-sensitive
    end

    if leaderstats:FindFirstChild("Level") then
        leaderstats.Level.Value = playerData.Level or 0 -- Property names are case-sensitive
    end
end

function LeaderboardService:Init()
    print("✅ [LeaderboardService v1.5] Service initialized and reactive.")

    Players.PlayerAdded:Connect(function(player)
        print("🏆 [Leaderboard] Setting up for " .. player.Name .. "...")
        createLeaderstat(player)
        
        -- FIXED: Use the new, correct function name `Get`
        local initialData = DataService:Get(player)
        if initialData then
            updateLeaderboard(player, initialData)
        end
    end)

    -- FIXED: Correctly connect to the event and use the new `player` argument
    DataService.StateUpdated:Connect(function(player)
        if player then
            print("🏆 [Leaderboard] Data changed for " .. player.Name .. ". Updating stats.")
            local playerData = DataService:Get(player)
            updateLeaderboard(player, playerData)
        end
    end)

end

return LeaderboardService