-- Framework Setup Script
-- This script must run first to create the Framework module in ReplicatedStorage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Create the Framework module in ReplicatedStorage if it doesn't exist
if not ReplicatedStorage:FindFirstChild("Framework") then
	print("[Setup] Creating Framework module in ReplicatedStorage...")
	
	-- Load the main framework
	local Framework = require(script.Parent.Main)
	
	-- Create the Framework module
	local frameworkModule = Instance.new("ModuleScript")
	frameworkModule.Name = "Framework"
	frameworkModule.Source = [[
-- Framework Module
-- This is the main entry point for the MVC Framework

return require(game:GetService("ReplicatedStorage").FrameworkSource)
]]
	frameworkModule.Parent = ReplicatedStorage
	
	-- Create the FrameworkSource module (the actual framework)
	local frameworkSource = Instance.new("ModuleScript")
	frameworkSource.Name = "FrameworkSource"
	frameworkSource.Source = Framework
	frameworkSource.Parent = ReplicatedStorage
	
	print("[Setup] Framework module created successfully")
else
	print("[Setup] Framework module already exists")
end

-- Create Shared folder and Util module
local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
if not sharedFolder then
	sharedFolder = Instance.new("Folder")
	sharedFolder.Name = "Shared"
	sharedFolder.Parent = ReplicatedStorage
	print("[Setup] Created Shared folder")
end

-- Create Util module if it doesn't exist
if not sharedFolder:FindFirstChild("Util") then
	local utilModule = Instance.new("ModuleScript")
	utilModule.Name = "Util"
	utilModule.Source = [[
-- Shared utility module
local Util = {}

-- Utility functions
function Util.GetTimestamp()
	return os.time()
end

function Util.FormatTimestamp(timestamp)
	local date = os.date("*t", timestamp)
	return string.format("%04d-%02d-%02d %02d:%02d:%02d", 
		date.year, date.month, date.day, 
		date.hour, date.min, date.sec)
end

function Util.DeepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = Util.DeepCopy(value)
	end
	return copy
end

return Util
]]
	utilModule.Parent = sharedFolder
	print("[Setup] Created Shared.Util module")
end

-- Create RemoteEvents folder for communication
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
	remoteEventsFolder = Instance.new("Folder")
	remoteEventsFolder.Name = "RemoteEvents"
	remoteEventsFolder.Parent = ReplicatedStorage
	
	-- Create required remote events
	local events = {
		"FrameworkReady",
		"ClientReady", 
		"RouteRequest",
		"RouteResponse",
		"RouteError",
		"BroadcastMessage",
		"PrivateMessage"
	}
	
	for _, eventName in pairs(events) do
		local remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = eventName
		remoteEvent.Parent = remoteEventsFolder
	end
	
	print("[Setup] Created RemoteEvents folder with required events")
end

-- Create RemoteFunctions folder for communication
local remoteFunctionsFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not remoteFunctionsFolder then
	remoteFunctionsFolder = Instance.new("Folder")
	remoteFunctionsFolder.Name = "RemoteFunctions"
	remoteFunctionsFolder.Parent = ReplicatedStorage
	
	-- Create required remote functions
	local functions = {
		"RouteHandler",
		"GetStatistics",
		"GetComponents"
	}
	
	for _, functionName in pairs(functions) do
		local remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = functionName
		remoteFunction.Parent = remoteFunctionsFolder
	end
	
	print("[Setup] Created RemoteFunctions folder with required functions")
end

print("[Setup] Framework setup completed successfully!")