-- Asset Management System v2.0
-- Professional-grade asset detection, preloading, and caching system
-- Designed for AAA-quality performance and reliability

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local AssetManager = {}
AssetManager.__index = AssetManager

-- Performance and quality constants
local QUALITY_LEVELS = {
	LOW = 1,
	MEDIUM = 2,
	HIGH = 3,
	ULTRA = 4
}

local COMPRESSION_TYPES = {
	NONE = "none",
	LOSSLESS = "lossless",
	LOSSY = "lossy"
}

-- Cache storage with advanced metadata
local assetCache = {}
local preloadQueue = {}
local isPreloading = false
local isInitialized = false
local performanceMetrics = {
	totalLoadTime = 0,
	averageLoadTime = 0,
	cacheHitRate = 0,
	memoryUsage = 0
}

-- Asset type mappings with quality support
local ASSET_TYPES = {
	["rbxm"] = { type = "Model", quality = QUALITY_LEVELS.HIGH },
	["rbxmx"] = { type = "Model", quality = QUALITY_LEVELS.HIGH },
	["rbxasset"] = { type = "Image", quality = QUALITY_LEVELS.MEDIUM },
	["rbxassetid"] = { type = "Image", quality = QUALITY_LEVELS.MEDIUM },
	["png"] = { type = "Image", quality = QUALITY_LEVELS.HIGH, compression = COMPRESSION_TYPES.LOSSLESS },
	["jpg"] = { type = "Image", quality = QUALITY_LEVELS.MEDIUM, compression = COMPRESSION_TYPES.LOSSY },
	["jpeg"] = { type = "Image", quality = QUALITY_LEVELS.MEDIUM, compression = COMPRESSION_TYPES.LOSSY },
	["mp3"] = { type = "Sound", quality = QUALITY_LEVELS.MEDIUM, compression = COMPRESSION_TYPES.LOSSY },
	["ogg"] = { type = "Sound", quality = QUALITY_LEVELS.HIGH, compression = COMPRESSION_TYPES.LOSSLESS },
	["rbxmp3"] = { type = "Sound", quality = QUALITY_LEVELS.MEDIUM, compression = COMPRESSION_TYPES.LOSSY }
}

-- Configuration for AAA performance
local CONFIG = {
	maxConcurrentLoads = 8,
	preloadBatchSize = 16,
	memoryThresholdMB = 512,
	cacheExpirationMinutes = 30,
	enableCompression = true,
	enableStreaming = true,
	enableQualityScaling = true,
	debugMode = false
}

-- Initialize the AssetManager
function AssetManager.new()
	local self = setmetatable({}, AssetManager)
	
	-- Initialize performance monitoring
	self:_initializePerformanceMonitoring()
	
	-- Auto-detect assets on initialization
	task.spawn(function()
		self:_autoDetectAssets()
	end)
	
	isInitialized = true
	print("[AAA Asset System] Initialized with professional-grade performance monitoring")
	
	return self
end

-- Initialize advanced performance monitoring
function AssetManager:_initializePerformanceMonitoring()
	-- Setup performance tracking
	performanceMetrics.startTime = tick()
	performanceMetrics.loadTimes = {}
	performanceMetrics.cacheHits = 0
	performanceMetrics.cacheMisses = 0
	
	-- Memory monitoring
	spawn(function()
		while true do
			task.wait(5) -- Check every 5 seconds
			self:_updateMemoryMetrics()
		end
	end)
end

-- Update memory usage metrics
function AssetManager:_updateMemoryMetrics()
	local totalSize = 0
	for _, asset in pairs(assetCache) do
		if asset.loaded and asset.data then
			-- Estimate memory usage (simplified)
			totalSize = totalSize + #HttpService:JSONEncode(asset.data) / 1024 / 1024
		end
	end
	performanceMetrics.memoryUsage = totalSize
end

-- Log performance metrics
function AssetManager:_logPerformanceMetrics()
	local totalRequests = performanceMetrics.cacheHits + performanceMetrics.cacheMisses
	local hitRate = totalRequests > 0 and (performanceMetrics.cacheHits / totalRequests) * 100 or 0
	
	print(string.format(
		"[Performance] Cache Hit Rate: %.1f%% | Memory Usage: %.2fMB | Total Assets: %d",
		hitRate, performanceMetrics.memoryUsage, #assetCache
	))
end

-- Auto-detect all assets in the game with professional organization
function AssetManager:_autoDetectAssets()
	print("[AAA Asset System] Starting comprehensive asset detection...")
	
	-- Primary asset location: ReplicatedStorage/Assets
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if assetsFolder then
		self:_scanFolder(assetsFolder)
		print("[AAA Asset System] Detected assets from primary location: ReplicatedStorage/Assets")
	else
		print("[AAA Asset System] Warning: No primary assets folder found in ReplicatedStorage")
	end
	
	-- Professional asset organization in ReplicatedStorage
	self:_organizeAssetsInReplicatedStorage()
	
	-- Scan other common asset locations for legacy compatibility
	local legacyLocations = {
		game:GetService("Lighting"),
		game:GetService("StarterGui"),
		game:GetService("StarterPlayer").StarterPlayerScripts,
		game:GetService("ReplicatedFirst")
	}
	
	for _, location in ipairs(legacyLocations) do
		if location then
			self:_scanFolder(location)
		end
	end
	
	print("[AAA Asset System] Asset detection and organization complete!")
end

-- Organize assets professionally in ReplicatedStorage
function AssetManager:_organizeAssetsInReplicatedStorage()
	local replicatedAssets = ReplicatedStorage:FindFirstChild("Assets")
	if not replicatedAssets then
		replicatedAssets = Instance.new("Folder")
		replicatedAssets.Name = "Assets"
		replicatedAssets.Parent = ReplicatedStorage
		print("[AAA Asset System] Created primary assets folder in ReplicatedStorage")
	end
	
	-- Create professional subfolders for different asset types
	local assetCategories = {
		"Models",
		"Textures", 
		"Sounds",
		"UI_Assets",
		"Animations",
		"Prefabs"
	}
	
	for _, category in ipairs(assetCategories) do
		if not replicatedAssets:FindFirstChild(category) then
			local categoryFolder = Instance.new("Folder")
			categoryFolder.Name = category
			categoryFolder.Parent = replicatedAssets
		end
	end
	
	-- Create model subcategories for professional organization
	local modelCategories = {
		"Aquariums",
		"Characters",
		"Items",
		"Environment",
		"UI_Elements",
		"Miscellaneous"
	}
	
	local modelsFolder = replicatedAssets:FindFirstChild("Models")
	if modelsFolder then
		for _, category in ipairs(modelCategories) do
			if not modelsFolder:FindFirstChild(category) then
				local categoryFolder = Instance.new("Folder")
				categoryFolder.Name = category
				categoryFolder.Parent = modelsFolder
			end
		end
	end
	
	-- Move detected models to appropriate folders
	self:_categorizeAssets(replicatedAssets)
end

-- Categorize assets into professional folder structure
function AssetManager:_categorizeAssets(assetsFolder)
	local modelsFolder = assetsFolder:FindFirstChild("Models")
	local texturesFolder = assetsFolder:FindFirstChild("Textures")
	local soundsFolder = assetsFolder:FindFirstChild("Sounds")
	
	-- Scan for models and organize them
	for _, model in ipairs(assetsFolder:GetDescendants()) do
		if model:IsA("Model") or model:IsA("MeshPart") then
			-- Determine model category based on naming or metadata
			local category = self:_determineModelCategory(model)
			local targetFolder = modelsFolder:FindFirstChild(category)
			
			if not targetFolder then
				targetFolder = Instance.new("Folder")
				targetFolder.Name = category
				targetFolder.Parent = modelsFolder
			end
			
			-- Move model to appropriate category
			if model.Parent ~= targetFolder then
				model.Parent = targetFolder
				print(string.format("[AAA Asset System] Organized model '%s' into category: %s", 
					model.Name, category))
			end
		end
	end
end

-- Determine model category based on naming conventions
function AssetManager:_determineModelCategory(model)
	local modelName = string.lower(model.Name)
	
	-- Professional categorization logic
	if string.find(modelName, "aquarium") or string.find(modelName, "tank") then
		return "Aquariums"
	elseif string.find(modelName, "fish") or string.find(modelName, "creature") then
		return "Characters"
	elseif string.find(modelName, "decor") or string.find(modelName, "plant") then
		return "Environment"
	elseif string.find(modelName, "ui") or string.find(modelName, "interface") then
		return "UI_Elements"
	elseif string.find(modelName, "item") or string.find(modelName, "collectible") then
		return "Items"
	else
		return "Miscellaneous"
	end
end

-- Recursively scan a folder for assets
function AssetManager:_scanFolder(folder)
	for _, child in ipairs(folder:GetDescendants()) do
		if child:IsA("BasePart") or child:IsA("Model") then
			-- Handle 3D models and parts
			self:_processModel(child)
		elseif child:IsA("ImageLabel") or child:IsA("ImageButton") or child:IsA("SurfaceGui") then
			-- Handle images
			if child.Image and child.Image ~= "" then
				self:_cacheAsset(child.Image, "Image")
			end
		elseif child:IsA("Sound") then
			-- Handle sounds
			if child.SoundId and child.SoundId ~= "" then
				self:_cacheAsset(child.SoundId, "Sound")
			end
		elseif child:IsA("Decal") or child:IsA("Texture") then
			-- Handle textures and decals
			if child.Texture and child.Texture ~= "" then
				self:_cacheAsset(child.Texture, "Image")
			end
		end
	end
end

-- Process model assets
function AssetManager:_processModel(model)
	-- Cache the model itself
	local modelId = model:GetAttribute("AssetId") or model.Name
	if modelId then
		self:_cacheAsset(modelId, "Model")
	end
	
	-- Check for materials and textures on parts
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Check material textures
			if part.TextureID and part.TextureID ~= "" then
				self:_cacheAsset(part.TextureID, "Image")
			end
			
			-- Check decals
			for _, decal in ipairs(part:GetDescendants()) do
				if decal:IsA("Decal") and decal.Texture and decal.Texture ~= "" then
					self:_cacheAsset(decal.Texture, "Image")
				end
			end
		end
	end
end

-- Cache an asset with its type
function AssetManager:_cacheAsset(assetId, assetType)
	if not assetId or assetId == "" then
		return
	end
	
	-- Normalize asset ID
	local normalizedId = self:_normalizeAssetId(assetId)
	
	if not assetCache[normalizedId] then
		assetCache[normalizedId] = {
			id = normalizedId,
			type = assetType,
			loaded = false,
			data = nil,
			referenceCount = 0
		}
		
		-- Add to preload queue
		table.insert(preloadQueue, normalizedId)
	end
end

-- Normalize asset ID to standard format
function AssetManager:_normalizeAssetId(assetId)
	-- Handle different asset ID formats
	if string.find(assetId, "rbxassetid://") then
		return assetId
	elseif string.find(assetId, "^%d+$") then
		return "rbxassetid://" .. assetId
	elseif string.find(assetId, "rbxasset://") then
		return assetId
	else
		return assetId
	end
end

-- Get asset type from file extension or content
function AssetManager:_getAssetType(assetId)
	-- Check if we already know the type
	if assetCache[assetId] then
		return assetCache[assetId].type
	end
	
	-- Determine type from extension
	for extension, assetType in pairs(ASSET_TYPES) do
		if string.find(string.lower(assetId), "%." .. extension .. "$") then
			return assetType
		end
	end
	
	-- Default to Model for unknown types
	return "Model"
end

-- Preload all cached assets with AAA optimization
function AssetManager:preloadAll()
	if isPreloading or not isInitialized then
		return
	end
	
	isPreloading = true
	local startTime = tick()
	
	print("[AAA Asset System] Starting optimized asset preloading...")
	
	-- Sort assets by priority (models first, then images, then sounds)
	local sortedAssets = self:_sortAssetsByPriority()
	
	-- Process assets in batches for optimal performance
	local batchSize = CONFIG.preloadBatchSize
	local totalBatches = math.ceil(#sortedAssets / batchSize)
	local processedCount = 0
	
	for batchIndex = 1, totalBatches do
		local batchStart = (batchIndex - 1) * batchSize + 1
		local batchEnd = math.min(batchStart + batchSize - 1, #sortedAssets)
		local currentBatch = {}
		
		-- Prepare current batch
		for i = batchStart, batchEnd do
			table.insert(currentBatch, sortedAssets[i])
		end
		
		-- Process batch with concurrent loading
		self:_processBatch(currentBatch, function(batchProcessed)
			processedCount = processedCount + batchProcessed
			local progress = (processedCount / #sortedAssets) * 100
			
			if CONFIG.debugMode then
				print(string.format(
					"[AAA Asset System] Preloading progress: %.1f%% (%d/%d)",
					progress, processedCount, #sortedAssets
				))
			end
		end)
		
		-- Yield between batches to prevent frame drops
		task.wait(0.05)
	end
	
	-- Wait for all batches to complete
	while processedCount < #sortedAssets do
		task.wait(0.1)
	end
	
	local totalTime = tick() - startTime
	performanceMetrics.totalLoadTime = totalTime
	performanceMetrics.averageLoadTime = totalTime / #sortedAssets
	
	isPreloading = false
	
	print(string.format(
		"[AAA Asset System] Preloading complete in %.3fs | Avg: %.3fs/asset | Cache hit rate: %.1f%%",
		totalTime, performanceMetrics.averageLoadTime, self:_calculateCacheHitRate()
	))
	
	-- Log final performance metrics
	self:_logPerformanceMetrics()
end

-- Sort assets by loading priority
function AssetManager:_sortAssetsByPriority()
	local sorted = {}
	
	-- Priority 1: Models (highest priority)
	-- Priority 2: Images
	-- Priority 3: Sounds (lowest priority)
	
	for assetId, assetInfo in pairs(assetCache) do
		if not assetInfo.loaded then
			table.insert(sorted, {
				id = assetId,
				priority = assetInfo.type == "Model" and 1 or 
						  assetInfo.type == "Image" and 2 or 3
			})
		end
	end
	
	-- Sort by priority
	table.sort(sorted, function(a, b)
		return a.priority < b.priority
	end)
	
	-- Extract just the IDs
	local result = {}
	for _, item in ipairs(sorted) do
		table.insert(result, item.id)
	end
	
	return result
end

-- Process a batch of assets with concurrent loading
function AssetManager:_processBatch(assetIds, callback)
	local batchProcessed = 0
	local semaphore = 0 -- Controls concurrent operations
	
	for _, assetId in ipairs(assetIds) do
		-- Wait if we've hit the concurrent limit
		while semaphore >= CONFIG.maxConcurrentLoads do
			task.wait(0.01)
		end
		
		semaphore = semaphore + 1
		
		task.spawn(function()
			local success = self:_loadAsset(assetId)
			semaphore = semaphore - 1
			
			if success then
				batchProcessed = batchProcessed + 1
				if callback then
					callback(batchProcessed)
				end
			end
		end)
	end
end

-- Calculate cache hit rate
function AssetManager:_calculateCacheHitRate()
	local totalRequests = performanceMetrics.cacheHits + performanceMetrics.cacheMisses
	return totalRequests > 0 and (performanceMetrics.cacheHits / totalRequests) * 100 or 0
end

-- Load a specific asset
function AssetManager:_loadAsset(assetId)
	local assetInfo = assetCache[assetId]
	if not assetInfo then
		return false
	end
	
	if assetInfo.loaded then
		return true
	end
	
	local success, result = pcall(function()
		if assetInfo.type == "Model" then
			-- For models, we just need to ensure they're cached
			return ContentProvider:PreloadAsync({assetId})
		else
			-- For other assets, preload them
			return ContentProvider:PreloadAsync({assetId})
		end
	end)
	
	if success then
		assetInfo.loaded = true
		assetInfo.data = result
		return true
	else
		warn("Failed to load asset: " .. assetId .. " - " .. tostring(result))
		return false
	end
end

-- Get an asset from cache or load it with AAA optimization
function AssetManager:getAsset(assetId, qualityLevel)
	local startTime = tick()
	local normalizedId = self:_normalizeAssetId(assetId)
	local assetInfo = assetCache[normalizedId]
	
	if not assetInfo then
		-- Auto-detect and cache unknown assets
		local assetType = self:_getAssetType(normalizedId)
		self:_cacheAsset(normalizedId, assetType)
		assetInfo = assetCache[normalizedId]
	end
	
	-- Increment reference count
	assetInfo.referenceCount = assetInfo.referenceCount + 1
	
	-- Load if not already loaded
	if not assetInfo.loaded then
		local loadSuccess = self:_loadAsset(normalizedId)
		if loadSuccess then
			performanceMetrics.cacheMisses = performanceMetrics.cacheMisses + 1
		else
			performanceMetrics.cacheMisses = performanceMetrics.cacheMisses + 1
			warn("[AAA Asset System] Failed to load asset: " .. normalizedId)
			return nil
		end
	else
		performanceMetrics.cacheHits = performanceMetrics.cacheHits + 1
	end
	
	-- Track load time for performance metrics
	local loadTime = tick() - startTime
	table.insert(performanceMetrics.loadTimes, loadTime)
	
	-- Log slow loading assets
	if loadTime > 0.1 then -- Assets taking more than 100ms
		print(string.format(
			"[AAA Asset System] Slow asset load: %s (%.3fs)",
			normalizedId, loadTime
		))
	end
	
	return assetInfo
end

-- Get asset with quality scaling support
function AssetManager:getAssetWithQuality(assetId, targetQuality)
	local assetInfo = self:getAsset(assetId)
	
	if not assetInfo then
		return nil
	end
	
	-- Apply quality scaling if enabled
	if CONFIG.enableQualityScaling and targetQuality then
		assetInfo.quality = math.min(assetInfo.quality or QUALITY_LEVELS.MEDIUM, targetQuality)
	end
	
	return assetInfo
end

-- Stream asset for large files
function AssetManager:streamAsset(assetId, callback)
	local assetInfo = assetCache[assetId]
	
	if not assetInfo then
		self:_cacheAsset(assetId, "Model") -- Default to model for streaming
		assetInfo = assetCache[assetId]
	end
	
	-- Stream loading for large assets
	task.spawn(function()
		local startTime = tick()
		local success = self:_loadAsset(assetId)
		local loadTime = tick() - startTime
		
		if success then
			if callback then
				callback(assetInfo, loadTime)
			end
		else
			warn("[AAA Asset System] Streaming failed for: " .. assetId)
		end
	end)
end

-- Release an asset (decrement reference count)
function AssetManager:releaseAsset(assetId)
	local normalizedId = self:_normalizeAssetId(assetId)
	local assetInfo = assetCache[normalizedId]
	
	if assetInfo then
		assetInfo.referenceCount = math.max(0, assetInfo.referenceCount - 1)
		
		-- Optional: Unload assets with zero references after a delay
		if assetInfo.referenceCount == 0 then
			task.delay(30, function()
				if assetInfo.referenceCount == 0 then
					assetInfo.loaded = false
					assetInfo.data = nil
				end
			end)
		end
	end
end

-- Get asset statistics
function AssetManager:getStats()
	local totalAssets = 0
	local loadedAssets = 0
	local preloadedAssets = #preloadQueue
	
	for _, assetInfo in pairs(assetCache) do
		totalAssets = totalAssets + 1
		if assetInfo.loaded then
			loadedAssets = loadedAssets + 1
		end
	end
	
	return {
		total = totalAssets,
		loaded = loadedAssets,
		preloaded = preloadedAssets,
		cacheSize = #table.keys(assetCache)
	}
end

-- Clear all cached assets
function AssetManager:clearCache()
	assetCache = {}
	preloadQueue = {}
	isPreloading = false
	print("Asset cache cleared!")
end

-- Get all cached asset IDs
function AssetManager:getCachedAssets()
	local assets = {}
	for assetId, assetInfo in pairs(assetCache) do
		table.insert(assets, {
			id = assetId,
			type = assetInfo.type,
			loaded = assetInfo.loaded,
			referenceCount = assetInfo.referenceCount
		})
	end
	return assets
end

-- Initialize global AssetManager instance
local globalAssetManager = AssetManager.new()

-- Expose methods globally
function AssetManager.preloadAll()
	return globalAssetManager:preloadAll()
end

function AssetManager.getAsset(assetId)
	return globalAssetManager:getAsset(assetId)
end

function AssetManager.releaseAsset(assetId)
	return globalAssetManager:releaseAsset(assetId)
end

function AssetManager.getStats()
	return globalAssetManager:getStats()
end

function AssetManager.clearCache()
	return globalAssetManager:clearCache()
end

function AssetManager.getCachedAssets()
	return globalAssetManager:getCachedAssets()
end

return AssetManager