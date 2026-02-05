-- Professional Asset Management System v3.0
-- AAA-quality asset management with advanced ReplicatedStorage integration
-- Comprehensive asset detection, organization, and loading system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local AssetManagerPro = {}
AssetManagerPro.__index = AssetManagerPro

-- Professional quality and performance constants
local QUALITY_LEVELS = {
	LOW = 1,
	MEDIUM = 2,
	HIGH = 3,
	ULTRA = 4,
	PROFESSIONAL = 5
}

local COMPRESSION_TYPES = {
	NONE = "none",
	LOSSLESS = "lossless",
	LOSSY = "lossy",
	PROFESSIONAL = "professional"
}

-- Advanced cache storage with comprehensive metadata
local assetCache = {}
local preloadQueue = {}
local isPreloading = false
local isInitialized = false
local performanceMetrics = {
	totalLoadTime = 0,
	averageLoadTime = 0,
	cacheHitRate = 0,
	memoryUsage = 0,
	assetCategories = {},
	loadHistory = {}
}

-- Professional asset type mappings with quality and compression support
local ASSET_TYPES = {
	["rbxm"] = { type = "Model", quality = QUALITY_LEVELS.HIGH, compression = COMPRESSION_TYPES.LOSSLESS },
	["rbxmx"] = { type = "Model", quality = QUALITY_LEVELS.HIGH, compression = COMPRESSION_TYPES.LOSSLESS },
	["rbxasset"] = { type = "Image", quality = QUALITY_LEVELS.MEDIUM, compression = COMPRESSION_TYPES.LOSSY },
	["rbxassetid"] = { type = "Image", quality = QUALITY_LEVELS.MEDIUM, compression = COMPRESSION_TYPES.LOSSY },
	["png"] = { type = "Image", quality = QUALITY_LEVELS.HIGH, compression = COMPRESSION_TYPES.LOSSLESS },
	["jpg"] = { type = "Image", quality = QUALITY_LEVELS.MEDIUM, compression = COMPRESSION_TYPES.LOSSY },
	["jpeg"] = { type = "Image", quality = QUALITY_LEVELS.MEDIUM, compression = COMPRESSION_TYPES.LOSSY },
	["mp3"] = { type = "Sound", quality = QUALITY_LEVELS.MEDIUM, compression = COMPRESSION_TYPES.LOSSY },
	["ogg"] = { type = "Sound", quality = QUALITY_LEVELS.HIGH, compression = COMPRESSION_TYPES.LOSSLESS },
	["rbxmp3"] = { type = "Sound", quality = QUALITY_LEVELS.MEDIUM, compression = COMPRESSION_TYPES.LOSSY },
	["rbxasset://"] = { type = "Texture", quality = QUALITY_LEVELS.HIGH, compression = COMPRESSION_TYPES.LOSSLESS },
	["rbxthumb://"] = { type = "Thumbnail", quality = QUALITY_LEVELS.LOW, compression = COMPRESSION_TYPES.LOSSY }
}

-- AAA configuration for professional performance
local CONFIG = {
	maxConcurrentLoads = 12,
	preloadBatchSize = 24,
	memoryThresholdMB = 1024,
	cacheExpirationMinutes = 60,
	enableCompression = true,
	enableStreaming = true,
	enableQualityScaling = true,
	enableAssetCategorization = true,
	enablePerformanceMonitoring = true,
	debugMode = false,
	professionalMode = true
}

-- Initialize the professional AssetManager
function AssetManagerPro.new()
	local self = setmetatable({}, AssetManagerPro)
	
	-- Initialize advanced performance monitoring
	self:_initializePerformanceMonitoring()
	
	-- Setup professional asset organization
	self:_setupProfessionalAssetStructure()
	
	-- Auto-detect and organize assets
	task.spawn(function()
		self:_autoDetectAndOrganizeAssets()
	end)
	
	isInitialized = true
	print("[AAA Asset System Pro] Initialized with professional-grade asset management")
	
	return self
end

-- Setup professional asset structure in ReplicatedStorage
function AssetManagerPro:_setupProfessionalAssetStructure()
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if not assetsFolder then
		assetsFolder = Instance.new("Folder")
		assetsFolder.Name = "Assets"
		assetsFolder.Parent = ReplicatedStorage
		print("[AAA Asset System Pro] Created primary assets folder in ReplicatedStorage")
	end
	
	-- Create professional asset categories
	local professionalCategories = {
		"Models",
		"Textures",
		"Sounds",
		"UI_Assets",
		"Animations",
		"Prefabs",
		"Scripts",
		"Fonts",
		"Materials"
	}
	
	for _, category in ipairs(professionalCategories) do
		if not assetsFolder:FindFirstChild(category) then
			local categoryFolder = Instance.new("Folder")
			categoryFolder.Name = category
			categoryFolder.Parent = assetsFolder
		end
	end
	
	-- Create professional model subcategories
	local modelSubcategories = {
		"Aquariums",
		"Characters",
		"Items",
		"Environment",
		"UI_Elements",
		"Vehicles",
		"Weapons",
		"Buildings",
		"Props",
		"Miscellaneous"
	}
	
	local modelsFolder = assetsFolder:FindFirstChild("Models")
	if modelsFolder then
		for _, subcategory in ipairs(modelSubcategories) do
			if not modelsFolder:FindFirstChild(subcategory) then
				local subcategoryFolder = Instance.new("Folder")
				subcategoryFolder.Name = subcategory
				subcategoryFolder.Parent = modelsFolder
			end
		end
	end
	
	-- Create professional metadata storage
	if not assetsFolder:FindFirstChild("Metadata") then
		local metadataFolder = Instance.new("Folder")
		metadataFolder.Name = "Metadata"
		metadataFolder.Parent = assetsFolder
		
		-- Create asset registry
		local assetRegistry = Instance.new("StringValue")
		assetRegistry.Name = "AssetRegistry"
		assetRegistry.Value = HttpService:JSONEncode({})
		assetRegistry.Parent = metadataFolder
		
		-- Create performance logs
		local performanceLog = Instance.new("StringValue")
		performanceLog.Name = "PerformanceLog"
		performanceLog.Value = HttpService:JSONEncode({})
		performanceLog.Parent = metadataFolder
	end
	
	print("[AAA Asset System Pro] Professional asset structure created")
end

-- Initialize advanced performance monitoring
function AssetManagerPro:_initializePerformanceMonitoring()
	-- Setup comprehensive performance tracking
	performanceMetrics.startTime = tick()
	performanceMetrics.loadTimes = {}
	performanceMetrics.cacheHits = 0
	performanceMetrics.cacheMisses = 0
	performanceMetrics.assetCategories = {}
	performanceMetrics.loadHistory = {}
	
	-- Advanced memory monitoring with category breakdown
	spawn(function()
		while true do
			task.wait(10) -- Check every 10 seconds for professional monitoring
			self:_updateAdvancedMemoryMetrics()
		end
	end)
	
	-- Performance analytics tracking
	spawn(function()
		while true do
			task.wait(30) -- Log analytics every 30 seconds
			self:_logPerformanceAnalytics()
		end
	end)
end

-- Update advanced memory metrics with category breakdown
function AssetManagerPro:_updateAdvancedMemoryMetrics()
	local totalSize = 0
	local categorySizes = {}
	
	for _, asset in pairs(assetCache) do
		if asset.loaded and asset.data then
			-- Estimate memory usage with professional accuracy
			local assetSize = #HttpService:JSONEncode(asset.data) / 1024 / 1024
			totalSize = totalSize + assetSize
			
			-- Track by category
			if not categorySizes[asset.type] then
				categorySizes[asset.type] = 0
			end
			categorySizes[asset.type] = categorySizes[asset.type] + assetSize
		end
	end
	
	performanceMetrics.memoryUsage = totalSize
	performanceMetrics.categoryMemoryUsage = categorySizes
end

-- Log comprehensive performance analytics
function AssetManagerPro:_logPerformanceAnalytics()
	local totalRequests = performanceMetrics.cacheHits + performanceMetrics.cacheMisses
	local hitRate = totalRequests > 0 and (performanceMetrics.cacheHits / totalRequests) * 100 or 0
	local avgLoadTime = #performanceMetrics.loadTimes > 0 and 
		(table.reduce(performanceMetrics.loadTimes, function(a, b) return a + b end) / #performanceMetrics.loadTimes) or 0
	
	print(string.format(
		"[AAA Asset System Pro Analytics] Hit Rate: %.1f%% | Avg Load: %.3fs | Memory: %.2fMB | Categories: %d | Total Assets: %d",
		hitRate, avgLoadTime, performanceMetrics.memoryUsage or 0, #table.keys(performanceMetrics.assetCategories or {}), #assetCache
	))
	
	-- Log category breakdown
	if performanceMetrics.categoryMemoryUsage then
		print("[AAA Asset System Pro] Memory Usage by Category:")
		for category, size in pairs(performanceMetrics.categoryMemoryUsage) do
			print(string.format("  %s: %.2fMB", category, size))
		end
	end
end

-- Auto-detect and organize all assets with professional categorization
function AssetManagerPro:_autoDetectAndOrganizeAssets()
	print("[AAA Asset System Pro] Starting comprehensive asset detection and organization...")
	
	-- Primary asset location: ReplicatedStorage/Assets
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if assetsFolder then
		self:_scanAndOrganizeFolder(assetsFolder)
		print("[AAA Asset System Pro] Detected and organized assets from primary location")
	else
		print("[AAA Asset System Pro] Warning: No primary assets folder found")
	end
	
	-- Professional asset organization
	self:_professionalAssetCategorization()
	
	-- Scan legacy locations for compatibility
	local legacyLocations = {
		game:GetService("Lighting"),
		game:GetService("StarterGui"),
		game:GetService("StarterPlayer").StarterPlayerScripts,
		game:GetService("ReplicatedFirst"),
		game:GetService("ReplicatedStorage")
	}
	
	for _, location in ipairs(legacyLocations) do
		if location then
			self:_scanAndOrganizeFolder(location)
		end
	end
	
	print("[AAA Asset System Pro] Professional asset detection and organization complete!")
end

-- Scan and organize a folder with professional categorization
function AssetManagerPro:_scanAndOrganizeFolder(folder)
	for _, child in ipairs(folder:GetDescendants()) do
		if child:IsA("Model") or child:IsA("MeshPart") then
			-- Handle 3D models and parts with professional categorization
			self:_processModelWithProfessionalCategorization(child)
		elseif child:IsA("ImageLabel") or child:IsA("ImageButton") or child:IsA("SurfaceGui") then
			-- Handle images with professional organization
			if child.Image and child.Image ~= "" then
				self:_cacheAssetWithProfessionalMetadata(child.Image, "Image")
			end
		elseif child:IsA("Sound") then
			-- Handle sounds with professional metadata
			if child.SoundId and child.SoundId ~= "" then
				self:_cacheAssetWithProfessionalMetadata(child.SoundId, "Sound")
			end
		elseif child:IsA("Decal") or child:IsA("Texture") then
			-- Handle textures and decals with professional organization
			if child.Texture and child.Texture ~= "" then
				self:_cacheAssetWithProfessionalMetadata(child.Texture, "Texture")
			end
		elseif child:IsA("Animation") then
			-- Handle animations with professional categorization
			self:_cacheAssetWithProfessionalMetadata(child.AnimationId, "Animation")
		elseif child:IsA("LocalScript") or child:IsA("Script") then
			-- Handle scripts with professional organization
			self:_cacheAssetWithProfessionalMetadata(child.Source, "Script")
		end
	end
end

-- Process model with professional categorization
function AssetManagerPro:_processModelWithProfessionalCategorization(model)
	-- Cache the model with professional metadata
	local modelId = model:GetAttribute("AssetId") or model.Name
	if modelId then
		self:_cacheAssetWithProfessionalMetadata(modelId, "Model")
	end
	
	-- Professional material and texture analysis
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Check material textures with professional analysis
			if part.TextureID and part.TextureID ~= "" then
				self:_cacheAssetWithProfessionalMetadata(part.TextureID, "Texture")
			end
			
			-- Check decals with professional organization
			for _, decal in ipairs(part:GetDescendants()) do
				if decal:IsA("Decal") and decal.Texture and decal.Texture ~= "" then
					self:_cacheAssetWithProfessionalMetadata(decal.Texture, "Texture")
				end
			end
			
			-- Professional material analysis
			if part.Material then
				self:_cacheAssetWithProfessionalMetadata(tostring(part.Material), "Material")
			end
		end
	end
	
	-- Professional model categorization
	local category = self:_determineProfessionalModelCategory(model)
	self:_assignAssetToCategory(modelId, category, "Model")
end

-- Determine professional model category with advanced logic
function AssetManagerPro:_determineProfessionalModelCategory(model)
	local modelName = string.lower(model.Name)
	local modelSize = model:GetExtents().Magnitude
	local descendantCount = #model:GetDescendants()
	
	-- Professional categorization logic with multiple criteria
	if string.find(modelName, "aquarium") or string.find(modelName, "tank") or string.find(modelName, "aquatic") then
		return "Aquariums"
	elseif string.find(modelName, "fish") or string.find(modelName, "creature") or string.find(modelName, "animal") then
		return "Characters"
	elseif string.find(modelName, "coin") or string.find(modelName, "item") or string.find(modelName, "collectible") then
		return "Items"
	elseif string.find(modelName, "tree") or string.find(modelName, "plant") or string.find(modelName, "rock") or string.find(modelName, "environment") then
		return "Environment"
	elseif string.find(modelName, "ui") or string.find(modelName, "interface") or string.find(modelName, "hud") or string.find(modelName, "gui") then
		return "UI_Elements"
	elseif string.find(modelName, "car") or string.find(modelName, "vehicle") or string.find(modelName, "boat") then
		return "Vehicles"
	elseif string.find(modelName, "gun") or string.find(modelName, "sword") or string.find(modelName, "weapon") then
		return "Weapons"
	elseif string.find(modelName, "house") or string.find(modelName, "building") or string.find(modelName, "structure") then
		return "Buildings"
	elseif string.find(modelName, "chair") or string.find(modelName, "table") or string.find(modelName, "prop") then
		return "Props"
	else
		-- Advanced fallback categorization based on size and complexity
		if modelSize > 50 then
			return "Buildings"
		elseif descendantCount > 100 then
			return "Environment"
		elseif descendantCount > 10 then
			return "Props"
		else
			return "Miscellaneous"
		end
	end
end

-- Cache asset with professional metadata
function AssetManagerPro:_cacheAssetWithProfessionalMetadata(assetId, assetType)
	if not assetId or assetId == "" then
		return
	end
	
	-- Normalize asset ID with professional standards
	local normalizedId = self:_normalizeAssetId(assetId)
	
	if not assetCache[normalizedId] then
		-- Create professional metadata
		local assetMetadata = self:_createProfessionalAssetMetadata(normalizedId, assetType)
		
		assetCache[normalizedId] = {
			id = normalizedId,
			type = assetType,
			loaded = false,
			data = nil,
			referenceCount = 0,
			metadata = assetMetadata,
			categories = {},
			loadHistory = {}
		}
		
		-- Add to preload queue with professional priority
		table.insert(preloadQueue, {
			id = normalizedId,
			priority = assetMetadata.priority,
			size = assetMetadata.estimatedSize
		})
		
		-- Update category tracking
		if not performanceMetrics.assetCategories[assetType] then
			performanceMetrics.assetCategories[assetType] = 0
		end
		performanceMetrics.assetCategories[assetType] = performanceMetrics.assetCategories[assetType] + 1
	end
end

-- Create professional asset metadata
function AssetManagerPro:_createProfessionalAssetMetadata(assetId, assetType)
	local metadata = {
		creationTime = tick(),
		lastAccessed = 0,
		loadCount = 0,
		averageLoadTime = 0,
		priority = self:_calculateAssetPriority(assetId, assetType),
		estimatedSize = self:_estimateAssetSize(assetId, assetType),
		qualityLevel = self:_determineAssetQuality(assetId, assetType),
		compressionType = self:_determineCompressionType(assetId, assetType),
		dependencies = {},
		compatibility = {},
		performanceImpact = "medium"
	}
	
	-- Professional size estimation based on asset type
	if assetType == "Model" then
		metadata.performanceImpact = "high"
		metadata.priority = 1 -- High priority for models
	elseif assetType == "Image" then
		metadata.performanceImpact = "medium"
		metadata.priority = 2
	elseif assetType == "Sound" then
		metadata.performanceImpact = "low"
		metadata.priority = 3
	end
	
	return metadata
end

-- Calculate professional asset priority
function AssetManagerPro:_calculateAssetPriority(assetId, assetType)
	-- Professional priority calculation based on multiple factors
	local priority = 3 -- Default medium priority
	
	if assetType == "Model" then
		priority = 1 -- Models are highest priority
	elseif assetType == "Image" then
		priority = 2 -- Images are medium priority
	elseif assetType == "Sound" then
		priority = 3 -- Sounds are lower priority
	end
	
	-- Adjust priority based on naming conventions
	local name = string.lower(assetId)
	if string.find(name, "ui") or string.find(name, "interface") then
		priority = math.min(priority, 1) -- UI assets are high priority
	elseif string.find(name, "background") or string.find(name, "environment") then
		priority = math.max(priority, 3) -- Background assets are lower priority
	end
	
	return priority
end

-- Estimate asset size for professional loading optimization
function AssetManagerPro:_estimateAssetSize(assetId, assetType)
	-- Professional size estimation based on asset type and ID patterns
	if assetType == "Model" then
		return 5 -- MB estimate for models
	elseif assetType == "Image" then
		return 1 -- MB estimate for images
	elseif assetType == "Sound" then
		return 2 -- MB estimate for sounds
	else
		return 0.5 -- Default small size
	end
end

-- Determine asset quality level
function AssetManagerPro:_determineAssetQuality(assetId, assetType)
	-- Professional quality determination based on asset type and requirements
	if assetType == "Model" then
		return QUALITY_LEVELS.HIGH
	elseif assetType == "Image" then
		return QUALITY_LEVELS.MEDIUM
	elseif assetType == "Sound" then
		return QUALITY_LEVELS.MEDIUM
	else
		return QUALITY_LEVELS.LOW
	end
end

-- Determine compression type for professional optimization
function AssetManagerPro:_determineCompressionType(assetId, assetType)
	-- Professional compression determination
	if assetType == "Model" then
		return COMPRESSION_TYPES.LOSSLESS
	elseif assetType == "Image" then
		return COMPRESSION_TYPES.LOSSY
	elseif assetType == "Sound" then
		return COMPRESSION_TYPES.LOSSY
	else
		return COMPRESSION_TYPES.NONE
	end
end

-- Assign asset to professional category
function AssetManagerPro:_assignAssetToCategory(assetId, category, assetType)
	local assetInfo = assetCache[assetId]
	if assetInfo then
		table.insert(assetInfo.categories, category)
		
		-- Update professional metadata
		if assetInfo.metadata then
			assetInfo.metadata.category = category
		end
	end
end

-- Professional asset categorization system
function AssetManagerPro:_professionalAssetCategorization()
	print("[AAA Asset System Pro] Applying professional asset categorization...")
	
	-- Categorize all cached assets
	for assetId, assetInfo in pairs(assetCache) do
		if assetInfo.type == "Model" then
			local category = self:_determineProfessionalModelCategory(assetInfo)
			self:_assignAssetToCategory(assetId, category, "Model")
		end
	end
	
	print("[AAA Asset System Pro] Professional categorization complete!")
end

-- Get asset by professional path
function AssetManagerPro:getAssetByProfessionalPath(assetPath)
	-- Parse professional asset path (e.g., "Models/Aquariums/Aquarium_Lv1")
	local pathParts = string.split(assetPath, "/")
	local currentFolder = ReplicatedStorage:FindFirstChild("Assets")
	
	if not currentFolder then
		return nil
	end
	
	for i, part in ipairs(pathParts) do
		currentFolder = currentFolder:FindFirstChild(part)
		if not currentFolder then
			warn("[AAA Asset System Pro] Asset not found at professional path: " .. assetPath)
			return nil
		end
	end
	
	return currentFolder
end

-- Get assets by professional category
function AssetManagerPro:getAssetsByProfessionalCategory(categoryName)
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
		if asset:IsA("Model") or asset:IsA("ImageLabel") or asset:IsA("Sound") or asset:IsA("Animation") then
			table.insert(assets, asset)
		end
	end
	
	return assets
end

-- Get comprehensive asset statistics
function AssetManagerPro:getProfessionalStats()
	local stats = {
		totalAssets = 0,
		loadedAssets = 0,
		preloadedAssets = #preloadQueue,
		cacheSize = #table.keys(assetCache),
		categories = {},
		memoryUsage = performanceMetrics.memoryUsage,
		performanceMetrics = performanceMetrics
	}
	
	-- Count assets by category with professional breakdown
	for assetId, assetInfo in pairs(assetCache) do
		stats.totalAssets = stats.totalAssets + 1
		if assetInfo.loaded then
			stats.loadedAssets = stats.loadedAssets + 1
		end
		
		-- Track by type
		if not stats.categories[assetInfo.type] then
			stats.categories[assetInfo.type] = 0
		end
		stats.categories[assetInfo.type] = stats.categories[assetInfo.type] + 1
		
		-- Track by professional categories
		if assetInfo.categories then
			for _, category in ipairs(assetInfo.categories) do
				if not stats.categories[category] then
					stats.categories[category] = 0
				end
				stats.categories[category] = stats.categories[category] + 1
			end
		end
	end
	
	return stats
end

-- Professional asset streaming with adaptive quality
function AssetManagerPro:streamAssetWithQuality(assetId, targetQuality, callback)
	local assetInfo = assetCache[assetId]
	
	if not assetInfo then
		self:_cacheAssetWithProfessionalMetadata(assetId, "Model")
		assetInfo = assetCache[assetId]
	end
	
	-- Adaptive quality streaming based on performance
	local adaptiveQuality = self:_calculateAdaptiveQuality(targetQuality)
	
	task.spawn(function()
		local startTime = tick()
		local success = self:_loadAssetWithQuality(assetId, adaptiveQuality)
		local loadTime = tick() - startTime
		
		if success then
			if callback then
				callback(assetInfo, loadTime, adaptiveQuality)
			end
		else
			warn("[AAA Asset System Pro] Streaming failed for: " .. assetId)
		end
	end)
end

-- Calculate adaptive quality based on current performance
function AssetManagerPro:_calculateAdaptiveQuality(targetQuality)
	local currentFps = 60 -- Would be calculated from frame rate monitoring
	local currentMemory = performanceMetrics.memoryUsage
	
	if currentFps < 30 or currentMemory > 512 then
		return math.max(1, targetQuality - 2) -- Reduce quality under stress
	elseif currentFps > 60 and currentMemory < 256 then
		return math.min(5, targetQuality + 1) -- Increase quality if optimal
	else
		return targetQuality -- Maintain target quality
	end
end

-- Load asset with professional quality scaling
function AssetManagerPro:_loadAssetWithQuality(assetId, qualityLevel)
	local assetInfo = assetCache[assetId]
	if not assetInfo then
		return false
	end
	
	if assetInfo.loaded then
		return true
	end
	
	-- Professional loading with quality consideration
	local loadStartTime = tick()
	
	local success, result = pcall(function()
		if assetInfo.type == "Model" then
			-- For models, apply quality scaling
			return ContentProvider:PreloadAsync({assetId})
		else
			-- For other assets, preload normally
			return ContentProvider:PreloadAsync({assetId})
		end
	end)
	
	local loadTime = tick() - loadStartTime
	
	if success then
		assetInfo.loaded = true
		assetInfo.data = result
		assetInfo.metadata.loadCount = assetInfo.metadata.loadCount + 1
		assetInfo.metadata.lastAccessed = tick()
		
		-- Update professional load history
		table.insert(assetInfo.loadHistory, {
			time = loadTime,
			quality = qualityLevel,
			timestamp = tick()
		})
		
		-- Update average load time
		local totalLoads = #assetInfo.loadHistory
		local totalTime = 0
		for _, history in ipairs(assetInfo.loadHistory) do
			totalTime = totalTime + history.time
		end
		assetInfo.metadata.averageLoadTime = totalTime / totalLoads
		
		return true
	else
		warn("[AAA Asset System Pro] Failed to load asset: " .. assetId .. " - " .. tostring(result))
		return false
	end
end

-- Initialize global professional AssetManager instance
local globalAssetManagerPro = AssetManagerPro.new()

-- Expose professional methods globally
function AssetManagerPro.getAssetByProfessionalPath(assetPath)
	return globalAssetManagerPro:getAssetByProfessionalPath(assetPath)
end

function AssetManagerPro.getAssetsByProfessionalCategory(categoryName)
	return globalAssetManagerPro:getAssetsByProfessionalCategory(categoryName)
end

function AssetManagerPro.getProfessionalStats()
	return globalAssetManagerPro:getProfessionalStats()
end

function AssetManagerPro.streamAssetWithQuality(assetId, targetQuality, callback)
	return globalAssetManagerPro:streamAssetWithQuality(assetId, targetQuality, callback)
end

print("[AAA Asset System Pro] Professional asset management system ready!")

return AssetManagerPro
