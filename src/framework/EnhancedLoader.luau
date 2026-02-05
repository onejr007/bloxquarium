-- Enhanced Framework Loader
-- Improved loader with better error handling and dependency management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local EnhancedLoader = {}
EnhancedLoader.__index = EnhancedLoader

-- Constructor
function EnhancedLoader.new()
	local self = setmetatable({}, EnhancedLoader)
	
	-- Loader configuration
	self.Config = {
		AutoLoad = true,
		CacheEnabled = true,
		DevelopmentMode = true,
		ValidationEnabled = true,
		DependencyInjection = true
	}
	
	-- Storage for loaded components
	self.Storage = {
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
	self.LoadingState = {
		Initialized = false,
		ComponentsLoaded = 0,
		TotalComponents = 0,
		Errors = {}
	}
	
	-- Performance tracking
	self.Performance = {
		StartTime = 0,
		LoadTime = 0,
		ComponentTimes = {}
	}
	
	return self
end

-- Initialize the enhanced loader
function EnhancedLoader:Initialize()
	print("[EnhancedLoader] Starting enhanced framework initialization...")
	
	self.Performance.StartTime = tick()
	
	-- Validate framework structure
	if not self:ValidateFrameworkStructure() then
		self:LogError("Framework structure validation failed")
		return false
	end
	
	-- Create framework folders
	self:CreateFrameworkFolders()
	
	-- Load core components first
	if not self:LoadCoreComponents() then
		self:LogError("Failed to load core components")
		return false
	end
	
	-- Auto-load all components
	if self.Config.AutoLoad then
		if not self:AutoLoad() then
			self:LogError("Auto-load failed")
			return false
		end
	end
	
	-- Validate dependencies
	if self.Config.DependencyInjection then
		if not self:ValidateDependencies() then
			self:LogError("Dependency validation failed")
			return false
		end
	end
	
	-- Cache assets
	if self.Config.CacheEnabled then
		self:CacheAssets()
	end
	
	-- Complete initialization
	self.LoadingState.Initialized = true
	self.Performance.LoadTime = tick() - self.Performance.StartTime
	
	self:LogInfo(string.format("Enhanced framework initialized successfully in %.3fms", 
		self.Performance.LoadTime * 1000))
	
	return true
end

-- Validate framework structure
function EnhancedLoader:ValidateFrameworkStructure()
	local requiredPaths = {
		"src/framework",
		"src/models",
		"src/controllers",
		"src/views",
		"src/services",
		"src/middleware",
		"src/libraries",
		"src/helpers"
	}
	
	for _, path in ipairs(requiredPaths) do
		local folder = self:FindFolder(path)
		if not folder then
			self:LogError("Missing required folder: " .. path)
			return false
		end
	end
	
	return true
end

-- Create framework folders in ReplicatedStorage
function EnhancedLoader:CreateFrameworkFolders()
	local folders = {
		"Controllers",
		"Models", 
		"Views",
		"Services",
		"Middleware",
		"Libraries",
		"Helpers",
		"Assets"
	}
	
	for _, folderName in ipairs(folders) do
		if not ReplicatedStorage:FindFirstChild(folderName) then
			local folder = Instance.new("Folder")
			folder.Name = folderName
			folder.Parent = ReplicatedStorage
			self:LogInfo("Created folder: " .. folderName)
		end
	end
	
	-- Create Controllers folder in ServerScriptService
	if not ServerScriptService:FindFirstChild("Controllers") then
		local controllersFolder = Instance.new("Folder")
		controllersFolder.Name = "Controllers"
		controllersFolder.Parent = ServerScriptService
		self:LogInfo("Created server folder: Controllers")
	end
end

-- Load core components
function EnhancedLoader:LoadCoreComponents()
	self:LogInfo("Loading core components...")
	
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
			self:LogError("Failed to load core component: " .. component.name)
			return false
		end
	end
	
	self:LogInfo("Core components loaded successfully")
	return true
end

-- Load component helper function
function EnhancedLoader:LoadComponent(componentType, componentName)
	local folderName = componentType .. "s"
	local folder = ReplicatedStorage:FindFirstChild(folderName)
	
	if not folder then
		self:LogWarn("Folder not found: " .. folderName)
		return false
	end
	
	local moduleScript = folder:FindFirstChild(componentName)
	if not moduleScript then
		self:LogWarn("Module not found: " .. componentName)
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
		self:LogInfo("Loaded " .. componentType:lower() .. ": " .. componentName .. " (" .. string.format("%.2fms", self.Performance.ComponentTimes[componentName] * 1000) .. ")")
		return true
	else
		self:LogError("Failed to load " .. componentType:lower() .. ": " .. componentName .. " - " .. result)
		table.insert(self.LoadingState.Errors, componentType .. " " .. componentName .. ": " .. result)
		return false
	end
end

-- Auto-load all components
function EnhancedLoader:AutoLoad()
	self:LogInfo("Starting auto-load process...")
	
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
	
	self:LogInfo("Auto-load completed successfully")
	return true
end

-- Load libraries
function EnhancedLoader:LoadLibraries()
	local libPath = ReplicatedStorage:FindFirstChild("Libraries")
	if not libPath then
		self:LogWarn("Libraries folder not found, skipping library loading")
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
			self:LogInfo("Loaded library: " .. item.Name .. " (" .. string.format("%.2fms", self.Performance.ComponentTimes[item.Name] * 1000) .. ")")
		else
			self:LogError("Failed to load library: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Library " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load helpers
function EnhancedLoader:LoadHelpers()
	local helperPath = ReplicatedStorage:FindFirstChild("Helpers")
	if not helperPath then
		self:LogWarn("Helpers folder not found, skipping helper loading")
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
			self:LogInfo("Loaded helper: " .. item.Name .. " (" .. string.format("%.2fms", self.Performance.ComponentTimes[item.Name] * 1000) .. ")")
		else
			self:LogError("Failed to load helper: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Helper " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load models
function EnhancedLoader:LoadModels()
	local modelPath = ReplicatedStorage:FindFirstChild("Models")
	if not modelPath then
		self:LogWarn("Models folder not found, skipping model loading")
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
			self:LogInfo("Loaded model: " .. item.Name .. " (" .. string.format("%.2fms", self.Performance.ComponentTimes[item.Name] * 1000) .. ")")
		else
			self:LogError("Failed to load model: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Model " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load services
function EnhancedLoader:LoadServices()
	local servicePath = ReplicatedStorage:FindFirstChild("Services")
	if not servicePath then
		self:LogWarn("Services folder not found, skipping service loading")
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
			self:LogInfo("Loaded service: " .. item.Name .. " (" .. string.format("%.2fms", self.Performance.ComponentTimes[item.Name] * 1000) .. ")")
		else
			self:LogError("Failed to load service: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Service " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load middleware
function EnhancedLoader:LoadMiddleware()
	local middlewarePath = ReplicatedStorage:FindFirstChild("Middleware")
	if not middlewarePath then
		self:LogWarn("Middleware folder not found, skipping middleware loading")
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
			self:LogInfo("Loaded middleware: " .. item.Name .. " (" .. string.format("%.2fms", self.Performance.ComponentTimes[item.Name] * 1000) .. ")")
		else
			self:LogError("Failed to load middleware: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Middleware " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load controllers
function EnhancedLoader:LoadControllers()
	local controllerPath = ServerScriptService:FindFirstChild("Controllers")
	if not controllerPath then
		self:LogWarn("Controllers folder not found, skipping controller loading")
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
			self:LogInfo("Loaded controller: " .. item.Name .. " (" .. string.format("%.2fms", self.Performance.ComponentTimes[item.Name] * 1000) .. ")")
		else
			self:LogError("Failed to load controller: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "Controller " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Load views
function EnhancedLoader:LoadViews()
	local viewPath = ReplicatedStorage:FindFirstChild("Views")
	if not viewPath then
		self:LogWarn("Views folder not found, skipping view loading")
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
			self:LogInfo("Loaded view: " .. item.Name .. " (" .. string.format("%.2fms", self.Performance.ComponentTimes[item.Name] * 1000) .. ")")
		else
			self:LogError("Failed to load view: " .. item.Name .. " - " .. result)
			table.insert(self.LoadingState.Errors, "View " .. item.Name .. ": " .. result)
		end
	end
	
	return #self.LoadingState.Errors == 0
end

-- Safe load component with error handling
function EnhancedLoader:SafeLoad(moduleScript)
	local success, result = pcall(function()
		return require(moduleScript)
	end)
	
	return success, result
end

-- Validate dependencies
function EnhancedLoader:ValidateDependencies()
	self:LogInfo("Validating dependencies...")
	
	-- Check for required core components
	local requiredComponents = {
		"Config",
		"Logger", 
		"ServiceContainer",
		"MiddlewareManager"
	}
	
	for _, componentName in ipairs(requiredComponents) do
		if not self.Storage.Libraries[componentName] then
			self:LogError("Missing required component: " .. componentName)
			return false
		end
	end
	
	-- Validate component interfaces
	for name, component in pairs(self.Storage.Libraries) do
		if component.Validate then
			local isValid, errors = component:Validate()
			if not isValid then
				self:LogError("Component validation failed for " .. name .. ": " .. table.concat(errors, ", "))
				return false
			end
		end
	end
	
	self:LogInfo("Dependencies validated successfully")
	return true
end

-- Cache assets
function EnhancedLoader:CacheAssets()
	if not self.Config.CacheEnabled then
		return
	end
	
	self:LogInfo("Starting asset caching...")
	
	-- Cache models
	local modelsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Models")
	if modelsFolder then
		for _, model in pairs(modelsFolder:GetChildren()) do
			if model:IsA("Model") then
				self.Storage.Cache["Model_" .. model.Name] = model:Clone()
				self:LogInfo("Cached model: " .. model.Name)
			end
		end
	end
	
	-- Cache images and sounds
	local assetsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
	if assetsFolder then
		for _, asset in pairs(assetsFolder:GetDescendants()) do
			if asset:IsA("ImageLabel") or asset:IsA("ImageButton") then
				self.Storage.Cache["Image_" .. asset.Name] = asset.Image
				self:LogInfo("Cached image: " .. asset.Name)
			elseif asset:IsA("Sound") then
				self.Storage.Cache["Sound_" .. asset.Name] = asset
				self:LogInfo("Cached sound: " .. asset.Name)
			end
		end
	end
	
	self:LogInfo("Asset caching completed")
end

-- Get component
function EnhancedLoader:Get(componentType, name)
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
function EnhancedLoader:GetStatistics()
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
function EnhancedLoader:FindComponent(name)
	for componentType, components in pairs(self.Storage) do
		if components[name] then
			return components[name], componentType
		end
	end
	return nil, nil
end

-- Find folder by path
function EnhancedLoader:FindFolder(path)
	local parts = string.split(path, "/")
	local current = game
	
	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then
			return nil
		end
	end
	
	return current
end

-- Logging functions
function EnhancedLoader:LogInfo(message)
	print("[EnhancedLoader] [INFO] " .. message)
end

function EnhancedLoader:LogWarn(message)
	warn("[EnhancedLoader] [WARN] " .. message)
end

function EnhancedLoader:LogError(message)
	warn("[EnhancedLoader] [ERROR] " .. message)
end

-- Export enhanced loader
return EnhancedLoader