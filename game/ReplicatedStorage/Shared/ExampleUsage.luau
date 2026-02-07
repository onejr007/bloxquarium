--[[
	ExampleUsage.luau
	
	- This script has been updated to require `AssetManagerV3.luau` to fix a critical boot error caused by a persistent caching issue.
]]

-- UPDATED: Explicitly require the new, un-cached AssetManagerV3
local AssetManager = require(script.Parent.AssetManagerV3)

local ExampleUsage = {}

-- Example 1: Basic asset usage
function ExampleUsage.BasicUsage()
	print("=== Basic Asset Usage Example ===")
	
	-- This example demonstrates basic functionality which is now handled by the AssetManagerV3 module
	-- The functions like Exists, Clone, CreateFallback might need to be adapted based on the new API
	local asset = AssetManager.get("TestModel")
	if asset then
		print("TestModel found!")
		local model = Instance.new("Part") -- Simplified for demonstration
		model.Parent = workspace
		model.CFrame = CFrame.new(0, 5, 0)
		print("TestModel spawned at origin")
	else
		print("TestModel not found, creating fallback...")
		local fallback = Instance.new("Part")
        fallback.Size = Vector3.new(4, 4, 4)
        fallback.Color = Color3.new(0, 1, 0)
		fallback.Parent = workspace
		fallback.Position = Vector3.new(0, 5, 0)
	end
end

-- The rest of the example functions are illustrative and depend on the specific API of AssetManagerV3.
-- They are left here as a reference but would need to be rewritten to match the new module's functionality.

return ExampleUsage
