-- Service Container
-- Dependency injection container for the MVC framework

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceContainer = {}
ServiceContainer.__index = ServiceContainer

-- Constructor
function ServiceContainer.new()
	local self = setmetatable({}, ServiceContainer)
	
	self.Services = {}
	self.SingletonInstances = {}
	self.Factories = {}
	self.Aliases = {}
	
	return self
end

-- Register a service
function ServiceContainer:Register(name, implementation, isSingleton)
	if type(implementation) == "string" then
		-- Register alias
		self.Aliases[name] = implementation
		return self
	elseif type(implementation) == "function" then
		-- Register factory
		self.Factories[name] = implementation
		if isSingleton then
			self.SingletonInstances[name] = nil
		end
	else
		-- Register instance
		self.Services[name] = implementation
	end
	
	return self
end

-- Register a singleton service
function ServiceContainer:Singleton(name, implementation)
	return self:Register(name, implementation, true)
end

-- Register an alias
function ServiceContainer:Alias(alias, target)
	self.Aliases[alias] = target
	return self
end

-- Resolve a service
function ServiceContainer:Resolve(name, ...)
	-- Check for alias
	if self.Aliases[name] then
		name = self.Aliases[name]
	end
	
	-- Check for singleton instance
	if self.SingletonInstances[name] then
		return self.SingletonInstances[name]
	end
	
	-- Check for factory
	if self.Factories[name] then
		local instance = self.Factories[name](...)
		
		-- Cache singleton
		if self.SingletonInstances[name] ~= nil then
			self.SingletonInstances[name] = instance
		end
		
		return instance
	end
	
	-- Check for registered service
	if self.Services[name] then
		return self.Services[name]
	end
	
	-- Try to load from ReplicatedStorage
	local servicePath = ReplicatedStorage:FindFirstChild(name)
	if servicePath and servicePath:IsA("ModuleScript") then
		local service = require(servicePath)
		self.Services[name] = service
		return service
	end
	
	error("Service not found: " .. name)
end

-- Check if service is registered
function ServiceContainer:Has(name)
	-- Check alias
	if self.Aliases[name] then
		return true
	end
	
	-- Check singleton
	if self.SingletonInstances[name] then
		return true
	end
	
	-- Check factory
	if self.Factories[name] then
		return true
	end
	
	-- Check service
	if self.Services[name] then
		return true
	end
	
	-- Check ReplicatedStorage
	local servicePath = ReplicatedStorage:FindFirstChild(name)
	return servicePath and servicePath:IsA("ModuleScript")
end

-- Get all registered services
function ServiceContainer:GetAllServices()
	local services = {}
	
	-- Add aliases
	for alias, target in pairs(self.Aliases) do
		services[alias] = "alias -> " .. target
	end
	
	-- Add singletons
	for name in pairs(self.SingletonInstances) do
		services[name] = "singleton"
	end
	
	-- Add factories
	for name in pairs(self.Factories) do
		if not services[name] then
			services[name] = "factory"
		end
	end
	
	-- Add services
	for name in pairs(self.Services) do
		if not services[name] then
			services[name] = "instance"
		end
	end
	
	return services
end

-- Clear all services
function ServiceContainer:Clear()
	self.Services = {}
	self.SingletonInstances = {}
	self.Factories = {}
	self.Aliases = {}
end

-- Remove a service
function ServiceContainer:Remove(name)
	if self.Aliases[name] then
		self.Aliases[name] = nil
	end
	
	if self.SingletonInstances[name] then
		self.SingletonInstances[name] = nil
	end
	
	if self.Factories[name] then
		self.Factories[name] = nil
	end
	
	if self.Services[name] then
		self.Services[name] = nil
	end
end

-- Create a scoped container
function ServiceContainer:CreateScope()
	local scope = ServiceContainer.new()
	
	-- Inherit parent services
	scope.Services = self.Services
	scope.SingletonInstances = self.SingletonInstances
	scope.Factories = self.Factories
	scope.Aliases = self.Aliases
	
	return scope
end

-- Register multiple services at once
function ServiceContainer:RegisterBatch(services)
	for name, implementation in pairs(services) do
		self:Register(name, implementation)
	end
	return self
end

-- Register middleware services
function ServiceContainer:RegisterMiddleware()
	self:Register("Logger", function()
		return require(ReplicatedStorage.Framework.Logger)
	end, true)
	
	self:Register("Config", function()
		return require(ReplicatedStorage.Framework.Config)
	end, true)
	
	self:Register("Database", function()
		return require(ReplicatedStorage.Framework.Database)
	end, true)
	
	return self
end

-- Register controller services
function ServiceContainer:RegisterControllers()
	-- Auto-discover controllers
	local controllersFolder = game:GetService("ServerScriptService"):FindFirstChild("Controllers")
	if controllersFolder then
		for _, controller in pairs(controllersFolder:GetChildren()) do
			if controller:IsA("ModuleScript") then
				self:Register(controller.Name, function()
					return require(controller)
				end)
			end
		end
	end
	
	return self
end

-- Register model services
function ServiceContainer:RegisterModels()
	-- Auto-discover models
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	if modelsFolder then
		for _, model in pairs(modelsFolder:GetChildren()) do
			if model:IsA("ModuleScript") then
				self:Register(model.Name, function()
					return require(model)
				end)
			end
		end
	end
	
	return self
end

-- Register view services
function ServiceContainer:RegisterViews()
	-- Auto-discover views
	local viewsFolder = ReplicatedStorage:FindFirstChild("Views")
	if viewsFolder then
		for _, view in pairs(viewsFolder:GetChildren()) do
			if view:IsA("ModuleScript") then
				self:Register(view.Name, function()
					return require(view)
				end)
			end
		end
	end
	
	return self
end

-- Inject dependencies into an object
function ServiceContainer:InjectDependencies(object, dependencies)
	for name, serviceName in pairs(dependencies) do
		object[name] = self:Resolve(serviceName)
	end
	return object
end

-- Create a service with dependencies
function ServiceContainer:CreateWithDependencies(serviceName, dependencies, constructor)
	local resolvedDeps = {}
	
	for name, depName in pairs(dependencies) do
		resolvedDeps[name] = self:Resolve(depName)
	end
	
	return constructor(resolvedDeps)
end

-- Get service statistics
function ServiceContainer:GetStatistics()
	local stats = {
		totalServices = 0,
		singletonCount = 0,
		factoryCount = 0,
		instanceCount = 0,
		aliasCount = 0
	}
	
	stats.aliasCount = #self.Aliases
	stats.singletonCount = #self.SingletonInstances
	stats.factoryCount = #self.Factories
	stats.instanceCount = #self.Services
	stats.totalServices = stats.aliasCount + stats.singletonCount + stats.factoryCount + stats.instanceCount
	
	return stats
end

-- Validate service dependencies
function ServiceContainer:ValidateDependencies()
	local services = self:GetAllServices()
	local errors = {}
	
	for name, service in pairs(services) do
		-- This would validate dependencies in a real implementation
		-- For now, just check if service can be resolved
		local success, result = pcall(function()
			return self:Resolve(name)
		end)
		
		if not success then
			table.insert(errors, name .. ": " .. result)
		end
	end
	
	return #errors == 0, errors
end

-- Auto-wire services based on naming conventions
function ServiceContainer:AutoWire()
	-- Register common services with standard names
	self:Singleton("Logger", function()
		return require(ReplicatedStorage.Framework.Logger)
	end)
	
	self:Singleton("Config", function()
		return require(ReplicatedStorage.Framework.Config)
	end)
	
	self:Singleton("Database", function()
		return require(ReplicatedStorage.Framework.Database)
	end)
	
	self:Singleton("Router", function()
		return require(ReplicatedStorage.Framework.Router)
	end)
	
	return self
end

return ServiceContainer