-- Main Framework Entry Point
-- Creates the Framework module in ReplicatedStorage and initializes the system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Create the main Framework module
local Framework = {}

-- Framework metadata
Framework.Metadata = {
	Name = "MVC Framework",
	Version = "1.0.0",
	Author = "Framework Developer",
	Initialized = false
}

-- Framework configuration
Framework.Config = {
	AutoLoad = true,
	CacheEnabled = true,
	DevelopmentMode = true,
	ValidationEnabled = true,
	DependencyInjection = true
}

-- Storage for loaded components
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

-- Loading state
Framework.LoadingState = {
	Initialized = false,
	ComponentsLoaded = 0,
	TotalComponents = 0,
	Errors = {}
}

-- Performance tracking
Framework.Performance = {
	StartTime = 0,
	LoadTime = 0,
	ComponentTimes = {}
}

-- Initialize the framework
function Framework:Initialize()
	if self.Metadata.Initialized then
		warn("[Framework] Framework already initialized!")
		return self
	end
	
	print("[Framework] Starting framework initialization...")
	
	self.Performance.StartTime = tick()
	
	-- Create framework folders in ReplicatedStorage
	self:CreateFrameworkFolders()
	
	-- Load core components first
	if not self:LoadCoreComponents() then
		warn("[Framework] Failed to load core components")
		return false
	end
	
	-- Auto-load all components
	if self.Config.AutoLoad then
		if not self:AutoLoad() then
			warn("[Framework] Auto-load failed")
			return false
		end
	end
	
	-- Validate dependencies
	if self.Config.DependencyInjection then
		if not self:ValidateDependencies() then
			warn("[Framework] Dependency validation failed")
			return false
		end
	end
	
	-- Cache assets
	if self.Config.CacheEnabled then
		self:CacheAssets()
	end
	
	-- Complete initialization
	self.Metadata.Initialized = true
	self.LoadingState.Initialized = true
	self.Performance.LoadTime = tick() - self.Performance.StartTime
	
	print(string.format("[Framework] Framework initialized successfully in %.3fms", 
		self.Performance.LoadTime * 1000))
	
	return self
end

-- Create framework folders in ReplicatedStorage
function Framework:CreateFrameworkFolders()
	local folders = {
		"Controllers",
		"Models", 
		"Views",
		"Services",
		"Middleware",
		"Libraries",
		"Helpers",
		"Assets",
		"Shared"
	}
	
	for _, folderName in ipairs(folders) do
		if not ReplicatedStorage:FindFirstChild(folderName) then
			local folder = Instance.new("Folder")
			folder.Name = folderName
			folder.Parent = ReplicatedStorage
			print("[Framework] Created folder: " .. folderName)
		end
	end
	
	-- Create Controllers folder in ServerScriptService
	if not ServerScriptService:FindFirstChild("Controllers") then
		local controllersFolder = Instance.new("Folder")
		controllersFolder.Name = "Controllers"
		controllersFolder.Parent = ServerScriptService
		print("[Framework] Created server folder: Controllers")
	end
end

-- Load core components
function Framework:LoadCoreComponents()
	print("[Framework] Loading core components...")
	
	local coreComponents = {
		{ type = "Library", name = "Config" },
		{ type = "Library", name = "Logger" },
		{ type = "Library", name = "ServiceContainer" },
		{ type = "Library", name = "MiddlewareManager" },
		{ type = "Library", name = "BaseService" },
		{ type = "Library", name = "BaseController" },
		{ type = "Library", name = "BaseModel" },
		{ type = "Library", name = "BaseView" },
		{ type = "Library", name = "Router" }
	}
	
	for _, component in ipairs(coreComponents) do
		local success = self:LoadComponent(component.type, component.name)
		if not success then
			warn("[Framework] Failed to load core component: " .. component.name)
			return false
		end
	end
	
	print("[Framework] Core components loaded successfully")
	return true
end

-- Load component helper function
function Framework:LoadComponent(componentType, componentName)
	local folderName = componentType .. "s"
	local folder = ReplicatedStorage:FindFirstChild(folderName)
	
	if not folder then
		warn("[Framework] Folder not found: " .. folderName)
		return false
	end
	
	local moduleScript = folder:FindFirstChild(componentName)
	if not moduleScript then
		warn("[Framework] Module not found: " .. componentName)
		return false
	end
	
	local startTime = tick()
	local success, result = self:SafeLoad(moduleScript)
	
	if success then
		if componentType == "Library" then
			self.Storage.Libraries[componentName] = result
		end
		self.LoadingState.ComponentsLoaded = self.LoadingState.ComponentsLoaded + 1
		self.Performance.ComponentTimes[componentName] = tick() - startTime
		print(string.format("[Framework] Loaded %s: %s (%.2fms)", 
			componentType:lower(), componentName, self.Performance.ComponentTimes[componentName] * 1000))
		return true
	else
		warn("[Framework] Failed to load " .. componentType:lower() .. ": " .. componentName .. " - " .. result)
		table.insert(self.LoadingState.Errors, componentType .. " " .. componentName .. ": " .. result)
		return false
	end
end

-- Auto-load all components
function Framework:AutoLoad()
	print("[Framework] Starting auto-load process...")
	
	-- Load libraries first (dependencies)
	if not self:LoadLibraries() then
		return false
	end
	
	-- Load helpers
	if not self:LoadHelpers() then
		return false
	end
	
	-- Load models
	if not self:LoadModels() then
		return false
	end
	
	-- Load services
	if not self:LoadServices() then
		return false
	end
	
	-- Load middleware
	if not self:LoadMiddleware() then
		return false
	end
	
	-- Load controllers
	if not self:LoadControllers() then
		return false
	end
	
	-- Load views
	if not self:LoadViews() then
		return false
	end
	
	print("[Framework] Auto-load completed successfully")
	return true
end

-- Load libraries
function Framework:LoadLibraries()
	local libPath = ReplicatedStorage:FindFirstChild("Libraries")
	if not libPath then
		print("[Framework] Libraries folder not found, skipping library loading")
		return true
	end
	
	local libraries = {}
	for _, item in pairs(libPath:GetChildren()) do
		if item:IsA("ModuleScript") then
			table.insert(libraries, item)
		end
	end
	
	self.LoadingState.TotalComponents = self.LoadingState.TotalComponents + #libraries
	
	for _, item in ipairs(libraries) do
		local startTime = tick()
		local success, result = self:SafeLoad(item)
		
		if success then
			self.Storage.Libraries[item.Name] = result
			self.LoadingState.ComponentsLoaded = self.LoadingState.ComponentsLoaded + 1
			self.Performance.ComponentTimes[item.Name] = tick() - startTime
			print(string.format("[Framework] Loaded library: %s (%.2fms)", 
				item.Name, self.Performance.ComponentTimes[item.Name] * 1000))
		else
			warn("[Framework] Failed to load library: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Library " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load helpers
function Framework:LoadHelpers()
	local helperPath = ReplicatedStorage:FindFirstChild("Helpers")
	if not helperPath then
		print("[Framework] Helpers folder not found, skipping helper loading")
		return true
	end
	
	local helpers = {}
	for _, item in pairs(helperPath:GetChildren()) do
		if item:IsA("ModuleScript") then
			table.insert(helpers, item)
		end
	end
	
	self.LoadingState.TotalComponents = self.LoadingState.TotalComponents + #helpers
	
	for _, item in ipairs(helpers) do
		local startTime = tick()
		local success, result = self:SafeLoad(item)
		
		if success then
			self.Storage.Helpers[item.Name] = result
			self.LoadingState.ComponentsLoaded = self.LoadingState.ComponentsLoaded + 1
			self.Performance.ComponentTimes[item.Name] = tick() - startTime
			print(string.format("[Framework] Loaded helper: %s (%.2fms)", 
				item.Name, self.Performance.ComponentTimes[item.Name] * 1000))
		else
			warn("[Framework] Failed to load helper: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Helper " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load models
function Framework:LoadModels()
	local modelPath = ReplicatedStorage:FindFirstChild("Models")
	if not modelPath then
		print("[Framework] Models folder not found, skipping model loading")
		return true
	end
	
	local models = {}
	for _, item in pairs(modelPath:GetChildren()) do
		if item:IsA("ModuleScript") then
			table.insert(models, item)
		end
	end
	
	self.LoadingState.TotalComponents = self.LoadingState.TotalComponents + #models
	
	for _, item in ipairs(models) do
		local startTime = tick()
		local success, result = self:SafeLoad(item)
		
		if success then
			self.Storage.Models[item.Name] = result
			self.LoadingState.ComponentsLoaded = self.LoadingState.ComponentsLoaded + 1
			self.Performance.ComponentTimes[item.Name] = tick() - startTime
			print(string.format("[Framework] Loaded model: %s (%.2fms)", 
				item.Name, self.Performance.ComponentTimes[item.Name] * 1000))
		else
			warn("[Framework] Failed to load model: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Model " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load services
function Framework:LoadServices()
	local servicePath = ReplicatedStorage:FindFirstChild("Services")
	if not servicePath then
		print("[Framework] Services folder not found, skipping service loading")
		return true
	end
	
	local services = {}
	for _, item in pairs(servicePath:GetChildren()) do
		if item:IsA("ModuleScript") then
			table.insert(services, item)
		end
	end
	
	self.LoadingState.TotalComponents = self.LoadingState.TotalComponents + #services
	
	for _, item in ipairs(services) do
		local startTime = tick()
		local success, result = self:SafeLoad(item)
		
		if success then
			self.Storage.Services[item.Name] = result
			self.LoadingState.ComponentsLoaded = self.LoadingState.ComponentsLoaded + 1
			self.Performance.ComponentTimes[item.Name] = tick() - startTime
			print(string.format("[Framework] Loaded service: %s (%.2fms)", 
				item.Name, self.Performance.ComponentTimes[item.Name] * 1000))
		else
			warn("[Framework] Failed to load service: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Service " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load middleware
function Framework:LoadMiddleware()
	local middlewarePath = ReplicatedStorage:FindFirstChild("Middleware")
	if not middlewarePath then
		print("[Framework] Middleware folder not found, skipping middleware loading")
		return true
	end
	
	local middleware = {}
	for _, item in pairs(middlewarePath:GetChildren()) do
		if item:IsA("ModuleScript") then
			table.insert(middleware, item)
		end
	end
	
	self.LoadingState.TotalComponents = self.LoadingState.TotalComponents + #middleware
	
	for _, item in ipairs(middleware) do
		local startTime = tick()
		local success, result = self:SafeLoad(item)
		
		if success then
			self.Storage.Middleware[item.Name] = result
			self.LoadingState.ComponentsLoaded = self.LoadingState.ComponentsLoaded + 1
			self.Performance.ComponentTimes[item.Name] = tick() - startTime
			print(string.format("[Framework] Loaded middleware: %s (%.2fms)", 
				item.Name, self.Performance.ComponentTimes[item.Name] * 1000))
		else
			warn("[Framework] Failed to load middleware: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Middleware " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load controllers
function Framework:LoadControllers()
	local controllerPath = ServerScriptService:FindFirstChild("Controllers")
	if not controllerPath then
		print("[Framework] Controllers folder not found, skipping controller loading")
		return true
	end
	
	local controllers = {}
	for _, item in pairs(controllerPath:GetChildren()) do
		if item:IsA("ModuleScript") then
			table.insert(controllers, item)
		end
	end
	
	self.LoadingState.TotalComponents = self.LoadingState.TotalComponents + #controllers
	
	for _, item in ipairs(controllers) do
		local startTime = tick()
		local success, result = self:SafeLoad(item)
		
		if success then
			self.Storage.Controllers[item.Name] = result
			self.LoadingState.ComponentsLoaded = self.LoadingState.ComponentsLoaded + 1
			self.Performance.ComponentTimes[item.Name] = tick() - startTime
			print(string.format("[Framework] Loaded controller: %s (%.2fms)", 
				item.Name, self.Performance.ComponentTimes[item.Name] * 1000))
		else
			warn("[Framework] Failed to load controller: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Controller " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load views
function Framework:LoadViews()
	local viewPath = ReplicatedStorage:FindFirstChild("Views")
	if not viewPath then
		print("[Framework] Views folder not found, skipping view loading")
		return true
	end
	
	local views = {}
	for _, item in pairs(viewPath:GetChildren()) do
		if item:IsA("ModuleScript") then
			table.insert(views, item)
		end
	end
	
	self.LoadingState.TotalComponents = self.LoadingState.TotalComponents + #views
	
	for _, item in ipairs(views) do
		local startTime = tick()
		local success, result = self:SafeLoad(item)
		
		if success then
			self.Storage.Views[item.Name] = result
			self.LoadingState.ComponentsLoaded = self.LoadingState.ComponentsLoaded + 1
			self.Performance.ComponentTimes[item.Name] = tick() - startTime
			print(string.format("[Framework] Loaded view: %s (%.2fms)", 
				item.Name, self.Performance.ComponentTimes[item.Name] * 1000))
		else
			warn("[Framework] Failed to load view: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "View " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Safe load component with error handling
function Framework:SafeLoad(moduleScript)
	local success, result = pcall(function()
		return require(moduleScript)
	end)
	
	return success, result
end

-- Validate dependencies
function Framework:ValidateDependencies()
	print("[Framework] Validating dependencies...")
	
	-- Check for required core components
	local requiredComponents = {
		"Config",
		"Logger", 
		"ServiceContainer",
		"MiddlewareManager"
	}
	
	for _, componentName in ipairs(requiredComponents) do
		if not self.Storage.Libraries[componentName] then
			warn("[Framework] Missing required component: " .. componentName)
			return false
		end
	end
	
	-- Validate component interfaces
	for name, component in pairs(self.Storage.Libraries) do
		if component.Validate then
			local isValid, errors = component:Validate()
			if not isValid then
				warn("[Framework] Component validation failed for " .. name .. ": " .. table.concat(errors, ", "))
				return false
			end
		end
	end
	
	print("[Framework] Dependencies validated successfully")
	return true
end

-- Cache assets
function Framework:CacheAssets()
	if not self.Config.CacheEnabled then
		return
	end
	
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
	
	print("[Framework] Asset caching completed")
end

-- Get component
function Framework:Get(componentType, name)
	if componentType == "Controller" then
		return self.Storage.Controllers[name]
	elseif componentType == "Model" then
		return self.Storage.Models[name]
	elseif componentType == "View" then
		return self.Storage.Views[name]
	elseif componentType == "Service" then
		return self.Storage.Services[name]
	elseif componentType == "Middleware" then
		return self.Storage.Middleware[name]
	elseif componentType == "Library" then
		return self.Storage.Libraries[name]
	elseif componentType == "Helper" then
		return self.Storage.Helpers[name]
	elseif componentType == "Cached" then
		return self.Storage.Cache[name]
	end
	return nil
end

-- Get loading statistics
function Framework:GetStatistics()
	return {
		initialized = self.LoadingState.Initialized,
		componentsLoaded = self.LoadingState.ComponentsLoaded,
		totalComponents = self.LoadingState.TotalComponents,
		loadTime = self.Performance.LoadTime,
		errors = self.LoadingState.Errors,
		componentTimes = self.Performance.ComponentTimes
	}
end

-- Get component by name
function Framework:FindComponent(name)
	for componentType, components in pairs(self.Storage) do
		if components[name] then
			return components[name], componentType
		end
	end
	return nil, nil
end

-- Create Shared folder and Util module for client-side access
function Framework:CreateSharedUtil()
	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if not sharedFolder then
		sharedFolder = Instance.new("Folder")
		sharedFolder.Name = "Shared"
		sharedFolder.Parent = ReplicatedStorage
		print("[Framework] Created Shared folder")
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
		print("[Framework] Created Shared.Util module")
	end
end

-- Export framework
return Framework