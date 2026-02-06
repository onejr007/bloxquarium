--[[
	ExampleUsage.luau
	
	Contoh penggunaan Asset Management System
	File ini menunjukkan berbagai cara menggunakan AssetManager
]]

local AssetManager = require(script.Parent.AssetManager)

local ExampleUsage = {}

-- Example 1: Basic asset usage
function ExampleUsage.BasicUsage()
	print("=== Basic Asset Usage Example ===")
	
	-- Check if asset exists
	if AssetManager.Exists("TestModel") then
		print("TestModel found!")
		
		-- Get asset clone
		local model = AssetManager.Clone("TestModel")
		if model then
			model.Parent = workspace
			model:SetPrimaryPartCFrame(CFrame.new(0, 5, 0))
			print("TestModel spawned at origin")
		end
	else
		print("TestModel not found, creating fallback...")
		local fallback = AssetManager.CreateFallback("TestModel", Vector3.new(4, 4, 4), Color3.new(0, 1, 0))
		fallback.Parent = workspace
		fallback.Position = Vector3.new(0, 5, 0)
	end
end

-- Example 2: Safe operations with fallbacks
function ExampleUsage.SafeOperations()
	print("=== Safe Operations Example ===")
	
	-- Create fallback asset
	local fallback = AssetManager.CreateFallback("SafeModel", Vector3.new(2, 2, 2), Color3.new(1, 1, 0))
	
	-- Safe clone with fallback
	local model = AssetManager.SafeClone("NonExistentModel", fallback)
	if model then
		model.Parent = workspace
		model.Position = Vector3.new(10, 5, 0)
		print("Safe clone successful (using fallback)")
	end
	
	-- Safe spawn with fallback
	local spawned = AssetManager.SafeSpawn("AnotherNonExistentModel", Vector3.new(20, 5, 0), workspace, fallback)
	if spawned then
		print("Safe spawn successful")
	end
end

-- Example 3: Batch operations
function ExampleUsage.BatchOperations()
	print("=== Batch Operations Example ===")
	
	local assetNames = AssetManager.GetAssetNames()
	print("Available assets:", #assetNames)
	
	-- Spawn all available assets in a line
	for i, assetName in pairs(assetNames) do
		local position = Vector3.new(i * 8, 5, -10)
		local spawned = AssetManager.Spawn(assetName, position)
		if spawned then
			print("Spawned", assetName, "at position", i)
		end
		
		-- Limit to first 10 assets to avoid clutter
		if i >= 10 then break end
	end
end

-- Example 4: Event handling
function ExampleUsage.EventHandling()
	print("=== Event Handling Example ===")
	
	-- Listen for new assets
	AssetManager.AssetAdded:Connect(function(assetName)
		print("New asset detected:", assetName)
		-- Auto-spawn new assets for demonstration
		local position = Vector3.new(math.random(-20, 20), 10, math.random(-20, 20))
		AssetManager.Spawn(assetName, position)
	end)
	
	-- Listen for preload completion
	AssetManager.PreloadComplete:Connect(function(loaded, total)
		print(string.format("Preloading completed: %d/%d assets loaded", loaded, total))
		
		-- Run batch operations after preloading
		ExampleUsage.BatchOperations()
	end)
	
	-- Listen for errors
	AssetManager.ErrorOccurred:Connect(function(errorEntry)
		print("Asset error occurred:", errorEntry.type, "-", errorEntry.message)
	end)
end

-- Example 5: Monitoring and debugging
function ExampleUsage.MonitoringExample()
	print("=== Monitoring Example ===")
	
	-- Check loading status
	local status = AssetManager.GetLoadingStatus()
	print(string.format("Loading Status: %d/%d assets loaded (%.1f%%)", 
		status.preloaded, status.total, status.percentage))
	
	-- Check health status
	local health = AssetManager.GetHealthStatus()
	print("System Health Score:", health.healthScore)
	print("Total Errors:", health.totalErrors)
	
	-- Show error statistics
	local errorStats = AssetManager.GetErrorStats()
	print("Error Statistics:")
	for errorType, count in pairs(errorStats) do
		if count > 0 then
			print("  " .. errorType .. ":", count)
		end
	end
	
	-- Full debug info
	AssetManager.Debug()
end

-- Example 6: Performance testing
function ExampleUsage.PerformanceTest()
	print("=== Performance Test Example ===")
	
	local startTime = tick()
	local spawnCount = 0
	
	-- Spawn 50 random assets
	for i = 1, 50 do
		local assetNames = AssetManager.GetAssetNames()
		if #assetNames > 0 then
			local randomAsset = assetNames[math.random(1, #assetNames)]
			local position = Vector3.new(
				math.random(-50, 50),
				math.random(5, 20),
				math.random(-50, 50)
			)
			
			local spawned = AssetManager.Spawn(randomAsset, position)
			if spawned then
				spawnCount = spawnCount + 1
			end
		end
	end
	
	local endTime = tick()
	local duration = endTime - startTime
	
	print(string.format("Performance Test Results:"))
	print(string.format("  Spawned: %d assets", spawnCount))
	print(string.format("  Duration: %.3f seconds", duration))
	print(string.format("  Rate: %.1f assets/second", spawnCount / duration))
end

-- Example 7: Cleanup and maintenance
function ExampleUsage.CleanupExample()
	print("=== Cleanup Example ===")
	
	-- Clear all spawned assets (example cleanup)
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name:find("TestModel") or obj.Name:find("FallbackAsset") then
			obj:Destroy()
			print("Cleaned up:", obj.Name)
		end
	end
	
	-- Clear caches
	AssetManager.ClearCache()
	AssetManager.ClearErrorLog()
	print("Caches cleared")
end

-- Main demo function
function ExampleUsage.RunDemo()
	print("=== Asset Management System Demo ===")
	
	-- Wait a bit for system to initialize
	wait(1)
	
	-- Run examples in sequence
	ExampleUsage.BasicUsage()
	wait(2)
	
	ExampleUsage.SafeOperations()
	wait(2)
	
	ExampleUsage.EventHandling()
	wait(2)
	
	ExampleUsage.MonitoringExample()
	wait(2)
	
	ExampleUsage.PerformanceTest()
	wait(5)
	
	ExampleUsage.CleanupExample()
	
	print("=== Demo Complete ===")
end

return ExampleUsage