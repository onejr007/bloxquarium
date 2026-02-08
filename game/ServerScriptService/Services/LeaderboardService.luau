--[[
    LeaderboardService.luau (v1.6 - Dependency Injection)

    - Refactored to accept DataService via the Init method.
    - Removed all hardcoded `require` paths.
]]

local Players = game:GetService("Players")

-- Service will be injected by ServiceLoader
local InjectedDataService

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
    if not player or not playerData then return end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        -- It's possible the leaderstats haven't been created yet, so don't warn.
        return
    end

    if leaderstats:FindFirstChild("Coins") then
        leaderstats.Coins.Value = playerData.Coins or 0
    end

    if leaderstats:FindFirstChild("Level") then
        leaderstats.Level.Value = playerData.Level or 0
    end
end

function LeaderboardService:Init(DataService)
    InjectedDataService = DataService -- Dependency Injection

    if not InjectedDataService then
        warn("🔥 [LeaderboardService] DataService not provided. Leaderboards will not function.")
        return
    end

    print("✅ [LeaderboardService v1.6] Service initialized and reactive.")

    local function setupPlayer(player)
        print("🏆 [Leaderboard] Setting up for " .. player.Name .. "...")
        createLeaderstat(player)
        
        -- Wait for data to be loaded if not already present
        task.spawn(function()
            local data = InjectedDataService:Get(player)
            local timeout = 0
            while not data and timeout < 10 do
                task.wait(0.5)
                data = InjectedDataService:Get(player)
                timeout += 0.5
            end
            if data then
                updateLeaderboard(player, data)
            end
        end)
    end

    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(setupPlayer, player)
    end

    Players.PlayerAdded:Connect(setupPlayer)

    InjectedDataService.StateUpdated:Connect(function(player)
        if player then
            print("🏆 [Leaderboard] Data changed for " .. player.Name .. ". Updating stats.")
            local playerData = InjectedDataService:Get(player)
            updateLeaderboard(player, playerData)
        end
    end)

end

return LeaderboardService