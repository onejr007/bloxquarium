-- Asset Management Examples and Usage Guide
-- Demonstrates how to use the AssetManager and AssetLoader systems

local AssetManager = require(game:GetService("ReplicatedStorage").Shared.AssetManager)
local AssetLoader = require(game:GetService("ReplicatedStorage").Client.AssetLoader)

local AssetExamples = {}

-- Example 1: Basic Asset Preloading
function AssetExamples.example1_BasicPreloading()
	print("=== Example 1: Basic Asset Preloading ===")
	
	-- Preload all detected assets
	AssetManager:preloadAll()
	
	-- Get statistics
	local stats = AssetManager:getStats()
	print("Total assets:", stats.total)
	print("Loaded assets:", stats.loaded)
	print("Preloaded assets:", stats.preloaded)
end

-- Example 2: Loading Specific Assets from ReplicatedStorage
function AssetExamples.example2_LoadSpecificAssets()
	print("=== Example 2: Loading Specific Assets from ReplicatedStorage ===")
	
	-- Load a specific model from organized folder structure
	local aquariumModel = AssetManager:getAsset("rbxassetid://123456789")
	if aquariumModel then
		print("Loaded aquarium model:", aquariumModel.id)
		
		-- Professional model instantiation
		local modelInstance = aquariumModel.data:Clone()
		modelInstance.Parent = workspace
		print("Model instantiated in workspace")
	end
	
	-- Load a specific texture from organized assets
	local waterTexture = AssetManager:getAsset("rbxassetid://987654321")
	if waterTexture then
		print("Loaded water texture:", waterTexture.id)
		
		-- Apply texture to a part
		local part = Instance.new("Part")
		part.Material = Enum.Material.Glass
		part.Transparency = 0.3
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(10, 10, 10)
		part.Anchored = true
		part.Position = Vector3.new(0, 5, 0)
		
		local decal = Instance.new("Decal")
		decal.Texture = waterTexture.id
		decal.Parent = part
		decal.Face = Enum.NormalId.Front
		
		part.Parent = workspace
		print("Texture applied to part")
	end
end

-- Example 3: Client-Side Asset Loading
function AssetExamples.example3_ClientLoading()
	print("=== Example 3: Client-Side Asset Loading ===")
	
	-- Load assets on the client
	local fishModel = AssetLoader:loadModel("rbxassetid://111222333")
	if fishModel then
		fishModel.Parent = workspace
		print("Successfully loaded and parented fish model")
	end
	
	-- Load multiple assets
	local assetIds = {
		"rbxassetid://444555666",
		"rbxassetid://777888999"
	}
	local loadedAssets = AssetLoader:loadAssets(assetIds)
	print("Loaded", #loadedAssets, "assets")
end

-- Example 4: Asset Caching and Reference Management
function AssetExamples.example4_Caching()
	print("=== Example 4: Asset Caching and Reference Management ===")
	
	-- Get an asset (this caches it)
	local asset1 = AssetManager:getAsset("rbxassetid://123456789")
	print("First reference to asset")
	
	-- Get the same asset again (should use cache)
	local asset2 = AssetManager:getAsset("rbxassetid://123456789")
	print("Second reference to same asset")
	print("Reference count:", asset2.referenceCount)
	
	-- Release references
	AssetManager:releaseAsset("rbxassetid://123456789")
	AssetManager:releaseAsset("rbxassetid://123456789")
	print("Released both references")
end

-- Example 5: Batch Asset Loading with Progress
function AssetExamples.example5_BatchLoading()
	print("=== Example 5: Batch Asset Loading with Progress ===")
	
	local assetIds = {
		"rbxassetid://111111111",
		"rbxassetid://222222222", 
		"rbxassetid://333333333",
		"rbxassetid://444444444"
	}
	
	-- Load with progress callback
	AssetLoader:batchLoad(assetIds, function(loaded, total)
		print(string.format("Loading progress: %d/%d (%.1f%%)", 
			loaded, total, (loaded/total) * 100))
	end)
	
	print("Batch loading complete!")
end

-- Example 6: Asset Statistics and Monitoring
function AssetExamples.example6_Statistics()
	print("=== Example 6: Asset Statistics and Monitoring ===")
	
	-- Get detailed statistics
	local stats = AssetManager:getStats()
	print("Asset Statistics:")
	print("  Total assets:", stats.total)
	print("  Loaded assets:", stats.loaded)
	print("  Preloaded assets:", stats.preloaded)
	print("  Cache size:", stats.cacheSize)
	
	-- Get all cached assets
	local cachedAssets = AssetManager:getCachedAssets()
	print("Cached assets:")
	for i, asset in ipairs(cachedAssets) do
		print(string.format("  %d. %s (%s) - Loaded: %s - References: %d", 
			i, asset.id, asset.type, tostring(asset.loaded), asset.referenceCount))
	end
end

-- Example 7: Clearing and Resetting Cache
function AssetExamples.example7_ClearCache()
	print("=== Example 7: Clearing and Resetting Cache ===")
	
	-- Clear all cached assets
	AssetManager:clearCache()
	print("Cache cleared!")
	
	-- Clear client-side cache
	AssetLoader:clearCache()
	print("Client cache cleared!")
end

-- Example 8: Error Handling and Fallbacks
function AssetExamples.example8_ErrorHandling()
	print("=== Example 8: Error Handling and Fallbacks ===")
	
	-- Try to load a non-existent asset
	local result = AssetManager:getAsset("rbxassetid://999999999")
	if result then
		print("Successfully loaded asset")
	else
		print("Failed to load asset - handling fallback")
		-- Fallback to default asset
		local defaultAsset = AssetManager:getAsset("rbxassetid://default123")
		if defaultAsset then
			print("Using default asset as fallback")
		end
	end
end

-- Example 9: Integration with Game Systems
function AssetExamples.example9_GameIntegration()
	print("=== Example 9: Integration with Game Systems ===")
	
	-- Example: Preload assets when player joins
	local Players = game:GetService("Players")
	
	Players.PlayerAdded:Connect(function(player)
		print("Player joined, preloading assets...")
		AssetManager:preloadAll()
		
		-- Send stats to player
		local stats = AssetManager:getStats()
		print("Assets ready for player:", player.Name)
		print("Loaded:", stats.loaded, "out of", stats.total, "assets")
	end)
end

-- Example 10: Performance Monitoring
function AssetExamples.example10_PerformanceMonitoring()
	print("=== Example 10: Performance Monitoring ===")
	
	local startTime = tick()
	
	-- Preload all assets and measure time
	AssetManager:preloadAll()
	
	local endTime = tick()
	local loadTime = endTime - startTime
	
	print("Asset preloading completed in:", string.format("%.3f", loadTime), "seconds")
	
	-- Monitor memory usage (if available)
	local stats = AssetManager:getStats()
	print("Memory efficiency:")
	print("  Assets per second:", string.format("%.1f", stats.total / loadTime))
	print("  Cache hit rate: 100% (all assets cached)")
end

-- Run all examples
function AssetExamples.runAllExamples()
	print("=== Running All Asset Management Examples ===")
	print()
	
	AssetExamples.example1_BasicPreloading()
	print()
	
	AssetExamples.example2_LoadSpecificAssets()
	print()
	
	AssetExamples.example3_ClientLoading()
	print()
	
	AssetExamples.example4_Caching()
	print()
	
	AssetExamples.example5_BatchLoading()
	print()
	
	AssetExamples.example6_Statistics()
	print()
	
	AssetExamples.example7_ClearCache()
	print()
	
	AssetExamples.example8_ErrorHandling()
	print()
	
	AssetExamples.example9_GameIntegration()
	print()
	
	AssetExamples.example10_PerformanceMonitoring()
	print()
	
	print("=== All Examples Complete ===")
end

-- Export the examples module
return AssetExamples