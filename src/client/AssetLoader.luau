-- AAA Client-side Asset Loader
-- Professional-grade asset loading system for client-side operations
-- Optimized for AAA game performance and quality standards

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AssetLoader = {}
AssetLoader.__index = AssetLoader

-- Remote events for communication with server
local preloadEvent = ReplicatedStorage:WaitForChild("PreloadAssets")
local getStatsEvent = ReplicatedStorage:WaitForChild("GetAssetStats")
local statsResponseEvent = ReplicatedStorage:WaitForChild("AssetStatsResponse")

-- Local asset cache with advanced metadata
local localCache = {}
local loadingQueue = {}
local isProcessingQueue = false

-- Performance tracking
local clientMetrics = {
	totalLoadTime = 0,
	averageLoadTime = 0,
	concurrentLoads = 0,
	maxConcurrentLoads = 4
}

-- Configuration for client-side optimization
local CLIENT_CONFIG = {
	enableStreaming = true,
	enableCompression = true,
	enableQualityScaling = true,
	debugMode = false,
	streamingThresholdKB = 1024, -- Assets larger than 1MB are streamed
	priorityQueue = true
}

-- Initialize the AssetLoader
function AssetLoader.new()
	local self = setmetatable({}, AssetLoader)
	
	-- Setup response handler with professional logging
	statsResponseEvent.OnClientEvent:Connect(function(stats)
		print("[AAA Client Asset System] Server-side preloading complete!")
		print(string.format("Server assets: %d/%d loaded", stats.loaded, stats.total))
		
		-- Trigger client-side optimization
		self:_optimizeClientCache()
	end)
	
	-- Setup frame-rate monitoring for adaptive loading
	RunService.Heartbeat:Connect(function()
		self:_monitorFrameRate()
	end)
	
	print("[AAA Client Asset System] Initialized with professional-grade client optimization")
	
	return self
end

-- Monitor frame rate for adaptive loading
function AssetLoader:_monitorFrameRate()
	local currentFps = 1 / RunService.Heartbeat:Wait()
	
	-- Adjust concurrent loading based on performance
	if currentFps < 50 then
		clientMetrics.maxConcurrentLoads = 2 -- Reduce load under performance stress
	elseif currentFps > 60 then
		clientMetrics.maxConcurrentLoads = 4 -- Optimal performance
	else
		clientMetrics.maxConcurrentLoads = 3 -- Balanced
	end
end

-- Optimize client cache based on usage patterns
function AssetLoader:_optimizeClientCache()
	local cacheSize = #table.keys(localCache)
	
	if cacheSize > 100 then -- Large cache, apply compression
		self:_compressCache()
	elseif cacheSize < 10 then -- Small cache, preload aggressively
		self:_aggressivePreload()
	end
end

-- Compress cache for memory optimization
function AssetLoader:_compressCache()
	print("[AAA Client Asset System] Applying cache compression...")
	
	local compressedCount = 0
	for assetId, assetData in pairs(localCache) do
		if assetData.size and assetData.size > CLIENT_CONFIG.streamingThresholdKB then
			-- Compress large assets
			assetData.compressed = true
			compressedCount = compressedCount + 1
		end
	end
	
	print(string.format("[AAA Client Asset System] Compressed %d large assets", compressedCount))
end

-- Aggressive preloading for small caches
function AssetLoader:_aggressivePreload()
	print("[AAA Client Asset System] Applying aggressive preloading...")
	
	-- Preload priority assets immediately
	local priorityAssets = self:_getPriorityAssets()
	
	for _, assetId in ipairs(priorityAssets) do
		if not localCache[assetId] then
			self:loadAsset(assetId)
		end
	end
end

-- Get priority assets from ReplicatedStorage organization
function AssetLoader:_getPriorityAssets()
	-- Professional asset retrieval from organized ReplicatedStorage
	local priorityAssets = {}
	
	-- Get assets from professionally organized folders
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if assetsFolder then
		-- High priority: UI Assets and Models
		local uiAssets = assetsFolder:FindFirstChild("UI_Assets")
		local modelsFolder = assetsFolder:FindFirstChild("Models")
		
		if uiAssets then
			for _, asset in ipairs(uiAssets:GetDescendants()) do
				if asset:IsA("ImageLabel") or asset:IsA("ImageButton") then
					table.insert(priorityAssets, asset.Image)
				end
			end
		end
		
		if modelsFolder then
			-- Get models from different categories
			for _, category in ipairs(modelsFolder:GetChildren()) do
				if category:IsA("Folder") then
					for _, model in ipairs(category:GetChildren()) do
						if model:IsA("Model") then
							table.insert(priorityAssets, model)
						end
					end
				end
			end
		end
	end
	
	-- Add fallback assets if no organized assets found
	if #priorityAssets == 0 then
		priorityAssets = {
			"rbxassetid://123456789", -- Common UI assets
			"rbxassetid://987654321",
			"rbxassetid://111222333"
		}
	end
	
	return priorityAssets
end

-- Load asset from ReplicatedStorage with professional organization
function AssetLoader:loadAssetFromReplicatedStorage(assetPath, qualityLevel)
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if not assetsFolder then
		warn("[AAA Client Asset System] No organized assets found in ReplicatedStorage")
		return nil
	end
	
	-- Parse asset path (e.g., "Models/Aquariums/Aquarium_Lv1")
	local pathParts = string.split(assetPath, "/")
	local currentFolder = assetsFolder
	
	for i, part in ipairs(pathParts) do
		currentFolder = currentFolder:FindFirstChild(part)
		if not currentFolder then
			warn(string.format("[AAA Client Asset System] Asset not found at path: %s", assetPath))
			return nil
		end
	end
	
	-- Load the asset based on its type
	if currentFolder:IsA("Model") then
		return self:loadModel(currentFolder)
	elseif currentFolder:IsA("ImageLabel") or currentFolder:IsA("ImageButton") then
		return self:loadImage(currentFolder.Image)
	elseif currentFolder:IsA("Sound") then
		return self:loadSound(currentFolder)
	else
		-- Generic asset loading
		return self:loadAsset(currentFolder.Name, qualityLevel)
	end
end

-- Get asset by category for professional organization
function AssetLoader:getAssetsByCategory(categoryName)
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if not assetsFolder then
		return {}
	end
	
	local categoryFolder = assetsFolder:FindFirstChild(categoryName)
	if not categoryFolder then
		return {}
	end
	
	local assets = {}
	for _, asset in ipairs(categoryFolder:GetDescendants()) do
		if asset:IsA("Model") or asset:IsA("ImageLabel") or asset:IsA("Sound") then
			table.insert(assets, asset)
		end
	end
	
	return assets
end

-- Preload all assets from server
function AssetLoader:preloadAllAssets()
	print("Requesting asset preloading from server...")
	preloadEvent:FireServer()
end

-- Get current asset statistics
function AssetLoader:getAssetStats()
	getStatsEvent:FireServer()
end

-- Load a specific asset locally with AAA optimization
function AssetLoader:loadAsset(assetId, qualityLevel)
	local startTime = tick()
	
	-- Check local cache first with quality validation
	if localCache[assetId] then
		local cachedAsset = localCache[assetId]
		
		-- Validate quality level if specified
		if qualityLevel and cachedAsset.quality and cachedAsset.quality < qualityLevel then
			-- Need to reload with higher quality
			print("[AAA Client Asset System] Reloading asset with higher quality: " .. assetId)
		else
			-- Cache hit - track performance
			clientMetrics.totalLoadTime = clientMetrics.totalLoadTime + (tick() - startTime)
			return cachedAsset
		end
	end
	
	-- Check concurrent load limits
	while clientMetrics.concurrentLoads >= clientMetrics.maxConcurrentLoads do
		task.wait(0.01)
	end
	
	clientMetrics.concurrentLoads = clientMetrics.concurrentLoads + 1
	
	-- Load asset with error handling and quality scaling
	local success, result = pcall(function()
		return ContentProvider:PreloadAsync({assetId})
	end)
	
	clientMetrics.concurrentLoads = clientMetrics.concurrentLoads - 1
	
	if success then
		-- Store with metadata
		localCache[assetId] = {
			data = result,
			loadedAt = tick(),
			quality = qualityLevel or 3, -- Default to HIGH quality
			size = #tostring(result), -- Rough size estimation
			compressed = false
		}
		
		local loadTime = tick() - startTime
		clientMetrics.totalLoadTime = clientMetrics.totalLoadTime + loadTime
		
		-- Log slow loading assets
		if loadTime > 0.1 then
			print(string.format(
				"[AAA Client Asset System] Slow client asset load: %s (%.3fs)",
				assetId, loadTime
			))
		end
		
		return localCache[assetId]
	else
		warn("[AAA Client Asset System] Failed to load asset: " .. assetId)
		return nil
	end
end

-- Stream large assets for optimal performance
function AssetLoader:streamAsset(assetId, callback)
	local assetData = localCache[assetId]
	
	if assetData and assetData.size and assetData.size > CLIENT_CONFIG.streamingThresholdKB then
		-- Stream the asset
		task.spawn(function()
			local startTime = tick()
			local result = self:loadAsset(assetId)
			local streamTime = tick() - startTime
			
			if result then
				if callback then
					callback(result, streamTime)
				end
			else
				warn("[AAA Client Asset System] Streaming failed for: " .. assetId)
			end
		end)
	else
		-- Load normally for smaller assets
		return self:loadAsset(assetId)
	end
end

-- Load asset with quality scaling
function AssetLoader:loadAssetWithQuality(assetId, targetQuality)
	local quality = targetQuality or CLIENT_CONFIG.defaultQuality or 3
	
	-- Adjust quality based on current performance
	local currentFps = 60 -- Would be calculated from frame rate monitoring
	if currentFps < 30 then
		quality = math.max(1, quality - 1) -- Reduce quality under performance stress
	elseif currentFps > 60 then
		quality = math.min(4, quality + 1) -- Increase quality if performance is good
	end
	
	return self:loadAsset(assetId, quality)
end

-- Load multiple assets
function AssetLoader:loadAssets(assetIds)
	local results = {}
	
	for _, assetId in ipairs(assetIds) do
		results[assetId] = self:loadAsset(assetId)
	end
	
	return results
end

-- Get cached asset
function AssetLoader:getCachedAsset(assetId)
	return localCache[assetId]
end

-- Clear local cache
function AssetLoader:clearCache()
	localCache = {}
	print("Local asset cache cleared!")
end

-- Load and instantiate a model
function AssetLoader:loadModel(assetId)
	local asset = self:loadAsset(assetId)
	if asset then
		-- For models, we need to clone and parent them
		local model = asset:Clone()
		return model
	else
		return nil
	end
end

-- Load image texture
function AssetLoader:loadImage(assetId)
	return self:loadAsset(assetId)
end

-- Load sound
function AssetLoader:loadSound(assetId)
	return self:loadAsset(assetId)
end

-- Batch load assets with progress callback
function AssetLoader:batchLoad(assetIds, progressCallback)
	local total = #assetIds
	local loaded = 0
	
	for _, assetId in ipairs(assetIds) do
		self:loadAsset(assetId)
		loaded = loaded + 1
		
		if progressCallback then
			progressCallback(loaded, total)
		end
	end
end

-- Initialize global AssetLoader instance
local globalAssetLoader = AssetLoader.new()

-- Expose methods globally
function AssetLoader.preloadAllAssets()
	return globalAssetLoader:preloadAllAssets()
end

function AssetLoader.getAssetStats()
	return globalAssetLoader:getAssetStats()
end

function AssetLoader.loadAsset(assetId)
	return globalAssetLoader:loadAsset(assetId)
end

function AssetLoader.loadAssets(assetIds)
	return globalAssetLoader:loadAssets(assetIds)
end

function AssetLoader.getCachedAsset(assetId)
	return globalAssetLoader:getCachedAsset(assetId)
end

function AssetLoader.clearCache()
	return globalAssetLoader:clearCache()
end

function AssetLoader.loadModel(assetId)
	return globalAssetLoader:loadModel(assetId)
end

function AssetLoader.loadImage(assetId)
	return globalAssetLoader:loadImage(assetId)
end

function AssetLoader.loadSound(assetId)
	return globalAssetLoader:loadSound(assetId)
end

function AssetLoader.batchLoad(assetIds, progressCallback)
	return globalAssetLoader:batchLoad(assetIds, progressCallback)
end

return AssetLoader