-- Framework Test Script
-- This script tests the framework loading and basic functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

print("[Test] Starting framework test...")

-- Test 1: Check if Framework module exists
print("[Test] Test 1: Checking Framework module...")
local frameworkModule = ReplicatedStorage:FindFirstChild("Framework")
if frameworkModule then
	print("[Test] ✓ Framework module found in ReplicatedStorage")
else
	print("[Test] ✗ Framework module NOT found in ReplicatedStorage")
end

-- Test 2: Check if Shared folder exists
print("[Test] Test 2: Checking Shared folder...")
local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
if sharedFolder then
	print("[Test] ✓ Shared folder found in ReplicatedStorage")
else
	print("[Test] ✗ Shared folder NOT found in ReplicatedStorage")
end

-- Test 3: Check if Util module exists
print("[Test] Test 3: Checking Util module...")
if sharedFolder then
	local utilModule = sharedFolder:FindFirstChild("Util")
	if utilModule then
		print("[Test] ✓ Util module found in Shared folder")
	else
		print("[Test] ✗ Util module NOT found in Shared folder")
	end
else
	print("[Test] ✗ Cannot test Util module - Shared folder not found")
end

-- Test 4: Test framework loading
print("[Test] Test 4: Testing framework loading...")
if frameworkModule then
	local success, framework = pcall(function()
		return require(frameworkModule)
	end)
	
	if success then
		print("[Test] ✓ Framework loaded successfully")
		
		-- Test framework initialization
		local success2, frameworkInstance = pcall(function()
			return framework:Initialize()
		end)
		
		if success2 then
			print("[Test] ✓ Framework initialized successfully")
			print("[Test] Framework name: " .. frameworkInstance.Metadata.Name)
			print("[Test] Framework version: " .. frameworkInstance.Metadata.Version)
			print("[Test] Framework initialized: " .. tostring(frameworkInstance.Metadata.Initialized))
		else
			print("[Test] ✗ Framework initialization failed: " .. frameworkInstance)
		end
	else
		print("[Test] ✗ Framework loading failed: " .. framework)
	end
else
	print("[Test] ✗ Cannot test framework loading - Framework module not found")
end

-- Test 5: Test Shared.Util loading
print("[Test] Test 5: Testing Shared.Util loading...")
if sharedFolder and sharedFolder:FindFirstChild("Util") then
	local success, util = pcall(function()
		return require(sharedFolder.Util)
	end)
	
	if success then
		print("[Test] ✓ Shared.Util loaded successfully")
		
		-- Test Util functions
		local timestamp = util.GetTimestamp()
		print("[Test] ✓ Util.GetTimestamp() works: " .. timestamp)
		
		local formatted = util.FormatTimestamp(timestamp)
		print("[Test] ✓ Util.FormatTimestamp() works: " .. formatted)
		
		local testTable = {a = 1, b = {c = 2}}
		local copied = util.DeepCopy(testTable)
		print("[Test] ✓ Util.DeepCopy() works: " .. tostring(copied.a == 1 and copied.b.c == 2))
	else
		print("[Test] ✗ Shared.Util loading failed: " .. util)
	end
else
	print("[Test] ✗ Cannot test Shared.Util - Util module not found")
end

-- Test 6: Check RemoteEvents
print("[Test] Test 6: Checking RemoteEvents...")
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if remoteEventsFolder then
	print("[Test] ✓ RemoteEvents folder found")
	
	local events = {"FrameworkReady", "ClientReady", "RouteRequest", "RouteResponse", "RouteError"}
	for _, eventName in pairs(events) do
		local event = remoteEventsFolder:FindFirstChild(eventName)
		if event then
			print("[Test] ✓ RemoteEvent found: " .. eventName)
		else
			print("[Test] ✗ RemoteEvent NOT found: " .. eventName)
		end
	end
else
	print("[Test] ✗ RemoteEvents folder NOT found")
end

-- Test 7: Check RemoteFunctions
print("[Test] Test 7: Checking RemoteFunctions...")
local remoteFunctionsFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if remoteFunctionsFolder then
	print("[Test] ✓ RemoteFunctions folder found")
	
	local functions = {"RouteHandler", "GetStatistics", "GetComponents"}
	for _, functionName in pairs(functions) do
		local func = remoteFunctionsFolder:FindFirstChild(functionName)
		if func then
			print("[Test] ✓ RemoteFunction found: " .. functionName)
		else
			print("[Test] ✗ RemoteFunction NOT found: " .. functionName)
		end
	end
else
	print("[Test] ✗ RemoteFunctions folder NOT found")
end

print("[Test] Framework test completed!")
print("[Test] If all tests passed, the framework should be working correctly.")