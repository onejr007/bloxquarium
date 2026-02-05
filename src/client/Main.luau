local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the shared modules to be available
local Util = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util")
local NetworkService = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetworkService")
local AssetManager = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AssetManager")
local AssetLoader = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("AssetLoader"))

-- Use the utility function
Util.printHello()

-- Initialize network service
NetworkService:Initialize()

-- Initialize comprehensive client integration
print("Initializing comprehensive client integration with Data Reconciliation and Data Store Management...")
local ClientIntegrationManager = require(ReplicatedStorage.Client.ClientIntegrationManager)

-- Wait for client integration to be ready
task.wait(3)

-- Get integration status
local integrationStatus = ClientIntegrationManager.getIntegrationStatus()
print("Client Integration Status:", integrationStatus)

-- Get system statistics
local systemStats = ClientIntegrationManager.getSystemStatistics()
print("Client System Statistics:", systemStats)

-- Initialize Data Reconciliation monitoring
task.spawn(function()
	task.wait(10)
	if systemStats.clientConfigBridge then
		print("Client Configuration Bridge: ACTIVE")
		print("  - Subscribed Configs:", systemStats.clientConfigBridge.subscribedConfigs)
		print("  - Cached Configs:", systemStats.clientConfigBridge.cachedConfigs)
		print("  - Authenticated:", systemStats.clientConfigBridge.isAuthenticated)
	end
end)

-- Initialize Secure Client Bridge monitoring
task.spawn(function()
	task.wait(10)
	if systemStats.secureClientBridge then
		print("Secure Client Bridge: ACTIVE")
		print("  - Pending Requests:", systemStats.secureClientBridge.pendingRequests)
		print("  - Failed Requests:", systemStats.secureClientBridge.failedRequests)
		print("  - Total Requests:", systemStats.secureClientBridge.totalRequests)
	end
end)

-- Initialize Asset Loader monitoring
task.spawn(function()
	task.wait(10)
	if systemStats.assetLoader then
		print("Asset Loader: ACTIVE")
		print("  - Total Assets:", systemStats.assetLoader.totalAssets)
		print("  - Loaded Assets:", systemStats.assetLoader.loadedAssets)
		print("  - Failed Assets:", systemStats.assetLoader.failedAssets)
	end
end)

-- Professional client-side asset loading from ReplicatedStorage
task.spawn(function()
	-- Get asset statistics from server
	local stats = AssetManager:getStats()
	print("Asset statistics:", stats)
	
	-- Load aquarium models from organized ReplicatedStorage
	local aquariumLv1 = AssetLoader:loadAssetFromReplicatedStorage("Models/Aquariums/Aquarium_Lv1")
	if aquariumLv1 then
		aquariumLv1.Parent = workspace
		print("Successfully loaded Aquarium Level 1")
	end
	
	local aquariumLv2 = AssetLoader:loadAssetFromReplicatedStorage("Models/Aquariums/Aquarium_Lv2")
	if aquariumLv2 then
		aquariumLv2.Parent = workspace
		print("Successfully loaded Aquarium Level 2")
	end
	
	-- Load character models (fish)
	local goldfish = AssetLoader:loadAssetFromReplicatedStorage("Models/Characters/Goldfish")
	if goldfish then
		goldfish.Parent = workspace
		print("Successfully loaded Goldfish model")
	end
	
	local guppy = AssetLoader:loadAssetFromReplicatedStorage("Models/Characters/Guppy")
	if guppy then
		guppy.Parent = workspace
		print("Successfully loaded Guppy model")
	end
	
	-- Load item models
	local coin = AssetLoader:loadAssetFromReplicatedStorage("Models/Items/Coin")
	if coin then
		coin.Parent = workspace
		print("Successfully loaded Coin item")
	end
	
	-- Get all assets by category for dynamic loading
	local aquariumAssets = AssetLoader:getAssetsByCategory("Aquariums")
	print("Found", #aquariumAssets, "aquarium assets")
	
	local characterAssets = AssetLoader:getAssetsByCategory("Characters")
	print("Found", #characterAssets, "character assets")
	
	local itemAssets = AssetLoader:getAssetsByCategory("Items")
	print("Found", #itemAssets, "item assets")
end)

-- Test secure communication
task.spawn(function()
	print("Testing secure communication...")
	
	local success, result = ClientIntegrationManager.sendSecureRequest("TEST_ACTION", {
		testData = "Hello from client",
		timestamp = tick()
	}, function(success, result, requestData)
		if success then
			print("Secure request successful:", result)
		else
			print("Secure request failed:", result)
		end
	end)
	
	if success then
		print("Secure communication test initiated")
	else
		print("Secure communication test failed:", result)
	end
end)

-- Request server-side asset preloading
AssetLoader:preloadAllAssets()

-- Get asset statistics from server
AssetLoader:getAssetStats()

-- Perform manual health check
task.spawn(function()
	task.wait(5) -- Wait for systems to stabilize
	local healthCheck = ClientIntegrationManager.performManualHealthCheck()
	print("Manual Health Check Results:", healthCheck)
end)

print("Client main script loaded successfully with comprehensive integration!")
