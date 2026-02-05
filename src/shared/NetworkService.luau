-- Network service for handling remote events and functions
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkService = {}

-- Remote events
NetworkService.Events = {}

-- Remote functions
NetworkService.Functions = {}

function NetworkService:Initialize()
	-- Initialize remote events
	self.Events.TestEvent = Instance.new("RemoteEvent")
	self.Events.TestEvent.Name = "TestEvent"
	self.Events.TestEvent.Parent = ReplicatedStorage
	
	-- Initialize remote functions
	self.Functions.TestFunction = Instance.new("RemoteFunction")
	self.Functions.TestFunction.Name = "TestFunction"
	self.Functions.TestFunction.Parent = ReplicatedStorage
	
	-- Initialize asset management events
	self:_setupAssetEvents()
	
	print("NetworkService initialized successfully!")
end

-- Setup asset management remote events
function NetworkService:_setupAssetEvents()
	-- Asset preloading event
	self.Events.PreloadAssets = Instance.new("RemoteEvent")
	self.Events.PreloadAssets.Name = "PreloadAssets"
	self.Events.PreloadAssets.Parent = ReplicatedStorage
	
	-- Asset stats request event
	self.Events.GetAssetStats = Instance.new("RemoteEvent")
	self.Events.GetAssetStats.Name = "GetAssetStats"
	self.Events.GetAssetStats.Parent = ReplicatedStorage
	
	-- Asset stats response event
	self.Events.AssetStatsResponse = Instance.new("RemoteEvent")
	self.Events.AssetStatsResponse.Name = "AssetStatsResponse"
	self.Events.AssetStatsResponse.Parent = ReplicatedStorage
	
	-- Setup event handlers
	self.Events.PreloadAssets.OnServerEvent:Connect(function(player)
		-- Handle asset preloading request from client
		local AssetManager = require(ReplicatedStorage.Shared.AssetManager)
		AssetManager:preloadAll()
		
		-- Send completion notification back to client
		self.Events.AssetStatsResponse:FireClient(player, AssetManager:getStats())
	end)
	
	self.Events.GetAssetStats.OnServerEvent:Connect(function(player)
		-- Send current asset statistics to client
		local AssetManager = require(ReplicatedStorage.Shared.AssetManager)
		self.Events.AssetStatsResponse:FireClient(player, AssetManager:getStats())
	end)
end

return NetworkService
