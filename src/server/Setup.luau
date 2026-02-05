-- Server Setup Script
-- This script runs first to initialize the framework before any other scripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Run the framework setup
print("[Server] Running framework setup...")

-- Load and execute the setup script
local setupScript = script:FindFirstChild("Setup")
if setupScript then
	require(setupScript)()
else
	warn("[Server] Setup script not found, trying alternative path...")
	
	-- Try to load from ReplicatedStorage
	local frameworkSetup = ReplicatedStorage:FindFirstChild("FrameworkSetup")
	if frameworkSetup then
		require(frameworkSetup)()
	else
		warn("[Server] Framework setup not found in ReplicatedStorage")
		
		-- Fallback: Create basic framework structure manually
		print("[Server] Creating basic framework structure...")
		
		-- Create Framework module manually
		if not ReplicatedStorage:FindFirstChild("Framework") then
			local frameworkModule = Instance.new("ModuleScript")
			frameworkModule.Name = "Framework"
			frameworkModule.Source = [[
-- Basic Framework Module
local Framework = {}

Framework.Metadata = {
	Name = "MVC Framework",
	Version = "1.0.0",
	Initialized = false
}

Framework.Config = {
	AutoLoad = true,
	CacheEnabled = true,
	DevelopmentMode = true
}

Framework.Storage = {
	Controllers = {},
	Models = {},
	Views = {},
	Services = {},
	Middleware = {},
	Libraries = {},
	Helpers = {},
	Cache = {}
}

function Framework:Initialize()
	print("[Framework] Basic framework initialized")
	self.Metadata.Initialized = true
	return self
end

function Framework:Get(componentType, name)
	return nil -- Placeholder
end

return Framework
]]
			frameworkModule.Parent = ReplicatedStorage
			print("[Server] Created basic Framework module")
		end
		
		-- Create Shared folder and Util
		local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
		if not sharedFolder then
			sharedFolder = Instance.new("Folder")
			sharedFolder.Name = "Shared"
			sharedFolder.Parent = ReplicatedStorage
		end
		
		if not sharedFolder:FindFirstChild("Util") then
			local utilModule = Instance.new("ModuleScript")
			utilModule.Name = "Util"
			utilModule.Source = [[
local Util = {}

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
			print("[Server] Created Shared.Util module")
		end
	end
end

print("[Server] Framework setup completed")

-- Now load the main server initialization
print("[Server] Loading main server initialization...")

-- Load the main server init script
local mainInit = script:FindFirstChild("init")
if mainInit then
	require(mainInit)
else
	warn("[Server] Main init script not found")
end

print("[Server] Server setup completed")