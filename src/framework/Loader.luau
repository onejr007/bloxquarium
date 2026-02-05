-- Framework Loader
-- Main entry point for the MVC framework

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Framework = {}

-- Framework configuration
Framework.Config = {
	AutoLoad = true,
	CacheEnabled = true,
	DevelopmentMode = true
}

-- Framework paths
Framework.Paths = {
	Models = "assets/models",
	Controllers = "src/controllers",
	Models = "src/models", 
	Views = "src/views",
	Libraries = "src/libraries",
	Helpers = "src/helpers"
}

-- Framework storage
Framework.Storage = {
	Controllers = {},
	Models = {},
	Views = {},
	Libraries = {},
	Helpers = {},
	Cache = {}
}

-- Auto-loader function
function Framework:AutoLoad()
	if not self.Config.AutoLoad then return end
	
	print("[Framework] Starting auto-load process...")
	
	-- Load libraries first (dependencies)
	self:LoadLibraries()
	
	-- Load helpers
	self:LoadHelpers()
	
	-- Load models
	self:LoadModels()
	
	-- Load controllers
	self:LoadControllers()
	
	-- Load views
	self:LoadViews()
	
	print("[Framework] Auto-load completed!")
end

-- Library loader
function Framework:LoadLibraries()
	print("[Framework] Loading libraries...")
	
	local libPath = ReplicatedStorage:FindFirstChild("Libraries")
	if not libPath then
		print("[Framework] Libraries folder not found, creating...")
		libPath = Instance.new("Folder")
		libPath.Name = "Libraries"
		libPath.Parent = ReplicatedStorage
	end
	
	for _, item in pairs(libPath:GetChildren()) do
		if item:IsA("ModuleScript") then
			local success, result = pcall(function()
				return require(item)
			end)
			
			if success then
				self.Storage.Libraries[item.Name] = result
				print("[Framework] Loaded library: " .. item.Name)
			else
				warn("[Framework] Failed to load library: " .. item.Name .. " - " .. result)
			end
		end
	end
end

-- Helper loader
function Framework:LoadHelpers()
	print("[Framework] Loading helpers...")
	
	local helperPath = ReplicatedStorage:FindFirstChild("Helpers")
	if not helperPath then
		print("[Framework] Helpers folder not found, creating...")
		helperPath = Instance.new("Folder")
		helperPath.Name = "Helpers"
		helperPath.Parent = ReplicatedStorage
	end
	
	for _, item in pairs(helperPath:GetChildren()) do
		if item:IsA("ModuleScript") then
			local success, result = pcall(function()
				return require(item)
			end)
			
			if success then
				self.Storage.Helpers[item.Name] = result
				print("[Framework] Loaded helper: " .. item.Name)
			else
				warn("[Framework] Failed to load helper: " .. item.Name .. " - " .. result)
			end
		end
	end
end

-- Model loader with caching
function Framework:LoadModels()
	print("[Framework] Loading models...")
	
	local modelPath = ReplicatedStorage:FindFirstChild("Models")
	if not modelPath then
		print("[Framework] Models folder not found, creating...")
		modelPath = Instance.new("Folder")
		modelPath.Name = "Models"
		modelPath.Parent = ReplicatedStorage
	end
	
	for _, item in pairs(modelPath:GetChildren()) do
		if item:IsA("ModuleScript") then
			local success, result = pcall(function()
				return require(item)
			end)
			
			if success then
				self.Storage.Models[item.Name] = result
				print("[Framework] Loaded model: " .. item.Name)
			else
				warn("[Framework] Failed to load model: " .. item.Name .. " - " .. result)
			end
		end
	end
end

-- Controller loader
function Framework:LoadControllers()
	print("[Framework] Loading controllers...")
	
	local controllerPath = ServerScriptService:FindFirstChild("Controllers")
	if not controllerPath then
		print("[Framework] Controllers folder not found, creating...")
		controllerPath = Instance.new("Folder")
		controllerPath.Name = "Controllers"
		controllerPath.Parent = ServerScriptService
	end
	
	for _, item in pairs(controllerPath:GetChildren()) do
		if item:IsA("ModuleScript") then
			local success, result = pcall(function()
				return require(item)
			end)
			
			if success then
				self.Storage.Controllers[item.Name] = result
				print("[Framework] Loaded controller: " .. item.Name)
			else
				warn("[Framework] Failed to load controller: " .. item.Name .. " - " .. result)
			end
		end
	end
end

-- View loader
function Framework:LoadViews()
	print("[Framework] Loading views...")
	
	local viewPath = ReplicatedStorage:FindFirstChild("Views")
	if not viewPath then
		print("[Framework] Views folder not found, creating...")
		viewPath = Instance.new("Folder")
		viewPath.Name = "Views"
		viewPath.Parent = ReplicatedStorage
	end
	
	for _, item in pairs(viewPath:GetChildren()) do
		if item:IsA("ModuleScript") then
			local success, result = pcall(function()
				return require(item)
			end)
			
			if success then
				self.Storage.Views[item.Name] = result
				print("[Framework] Loaded view: " .. item.Name)
			else
				warn("[Framework] Failed to load view: " .. item.Name .. " - " .. result)
			end
		end
	end
end

-- Asset cache system
function Framework:CacheAssets()
	if not self.Config.CacheEnabled then return end
	
	print("[Framework] Starting asset caching...")
	
	-- Cache models
	local modelsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Models")
	if modelsFolder then
		for _, model in pairs(modelsFolder:GetChildren()) do
			if model:IsA("Model") then
				self.Storage.Cache["Model_" .. model.Name] = model:Clone()
				print("[Framework] Cached model: " .. model.Name)
			end
		end
	end
	
	-- Cache images and sounds
	local assetsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
	if assetsFolder then
		for _, asset in pairs(assetsFolder:GetDescendants()) do
			if asset:IsA("ImageLabel") or asset:IsA("ImageButton") then
				self.Storage.Cache["Image_" .. asset.Name] = asset.Image
				print("[Framework] Cached image: " .. asset.Name)
			elseif asset:IsA("Sound") then
				self.Storage.Cache["Sound_" .. asset.Name] = asset
				print("[Framework] Cached sound: " .. asset.Name)
			end
		end
	end
	
	print("[Framework] Asset caching completed!")
end

-- Get framework component
function Framework:Get(componentType, name)
	if componentType == "Controller" then
		return self.Storage.Controllers[name]
	elseif componentType == "Model" then
		return self.Storage.Models[name]
	elseif componentType == "View" then
		return self.Storage.Views[name]
	elseif componentType == "Library" then
		return self.Storage.Libraries[name]
	elseif componentType == "Helper" then
		return self.Storage.Helpers[name]
	elseif componentType == "Cached" then
		return self.Storage.Cache[name]
	end
	return nil
end

-- Framework initialization
function Framework:Initialize()
	print("[Framework] Initializing MVC Framework...")
	
	-- Create framework folders in ReplicatedStorage
	local folders = {"Libraries", "Helpers", "Models", "Views", "Assets"}
	for _, folderName in pairs(folders) do
		if not ReplicatedStorage:FindFirstChild(folderName) then
			local folder = Instance.new("Folder")
			folder.Name = folderName
			folder.Parent = ReplicatedStorage
		end
	end
	
	-- Create Controllers folder in ServerScriptService
	if not ServerScriptService:FindFirstChild("Controllers") then
		local controllersFolder = Instance.new("Folder")
		controllersFolder.Name = "Controllers"
		controllersFolder.Parent = ServerScriptService
	end
	
	-- Auto-load components
	self:AutoLoad()
	
	-- Cache assets
	self:CacheAssets()
	
	print("[Framework] MVC Framework initialized successfully!")
	return self
end

return Framework