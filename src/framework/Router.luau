-- Router Class
-- Handles routing and URL mapping for the MVC framework

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Router = {}
Router.__index = Router

-- Constructor
function Router.new()
	local self = setmetatable({}, Router)
	
	-- Router properties
	self.Routes = {}
	self.Middleware = {}
	self.BasePath = ""
	
	return self
end

-- Initialize router
function Router:Initialize()
	print("[Router] Router initialized")
	self:CreateRemoteEvents()
end

-- Create remote events for communication
function Router:CreateRemoteEvents()
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		remoteEvents = Instance.new("Folder")
		remoteEvents.Name = "RemoteEvents"
		remoteEvents.Parent = ReplicatedStorage
	end
	
	-- Create main route handler
	local routeEvent = Instance.new("RemoteEvent")
	routeEvent.Name = "RouteRequest"
	routeEvent.OnServerEvent:Connect(function(player, route, data)
		self:HandleRoute(player, route, data)
	end)
	routeEvent.Parent = remoteEvents
	
	-- Create middleware handler
	local middlewareEvent = Instance.new("RemoteEvent")
	middlewareEvent.Name = "MiddlewareRequest"
	middlewareEvent.OnServerEvent:Connect(function(player, middlewareName, data)
		self:HandleMiddleware(player, middlewareName, data)
	end)
	middlewareEvent.Parent = remoteEvents
end

-- Add route
function Router:AddRoute(method, path, controller, action)
	local routeKey = method:upper() .. " " .. path
	self.Routes[routeKey] = {
		Method = method:upper(),
		Path = path,
		Controller = controller,
		Action = action,
		Middleware = {}
	}
	print("[Router] Added route: " .. routeKey)
end

-- Add GET route
function Router:Get(path, controller, action)
	self:AddRoute("GET", path, controller, action)
end

-- Add POST route
function Router:Post(path, controller, action)
	self:AddRoute("POST", path, controller, action)
end

-- Add PUT route
function Router:Put(path, controller, action)
	self:AddRoute("PUT", path, controller, action)
end

-- Add DELETE route
function Router:Delete(path, controller, action)
	self:AddRoute("DELETE", path, controller, action)
end

-- Add middleware
function Router:AddMiddleware(name, callback)
	self.Middleware[name] = callback
	print("[Router] Added middleware: " .. name)
end

-- Add middleware to route
function Router:AddMiddlewareToRoute(method, path, middlewareName)
	local routeKey = method:upper() .. " " .. path
	if self.Routes[routeKey] then
		table.insert(self.Routes[routeKey].Middleware, middlewareName)
		print("[Router] Added middleware '" .. middlewareName .. "' to route: " .. routeKey)
	end
end

-- Handle route request
function Router:HandleRoute(player, route, data)
	local routeInfo = self:ParseRoute(route)
	if not routeInfo then
		self:SendError(player, "Invalid route format")
		return
	end
	
	local method = routeInfo.method
	local path = routeInfo.path
	
	-- Find matching route
	local routeKey = method .. " " .. path
	local routeDefinition = self.Routes[routeKey]
	
	if not routeDefinition then
		-- Try wildcard routes
		routeDefinition = self:FindWildcardRoute(method, path)
		if not routeDefinition then
			self:SendError(player, "Route not found: " .. route)
			return
		end
	end
	
	-- Execute middleware
	local middlewareResult = self:ExecuteMiddleware(player, routeDefinition.Middleware, data)
	if not middlewareResult then
		self:SendError(player, "Middleware failed")
		return
	end
	
	-- Execute controller action
	self:ExecuteAction(player, routeDefinition, data)
end

-- Parse route string
function Router:ParseRoute(route)
	local parts = string.split(route, " ")
	if #parts ~= 2 then
		return nil
	end
	
	return {
		method = parts[1]:upper(),
		path = parts[2]
	}
end

-- Find wildcard route
function Router:FindWildcardRoute(method, path)
	for routeKey, routeDef in pairs(self.Routes) do
		if routeDef.Method == method then
			local pattern = self:ConvertToPattern(routeDef.Path)
			if string.match(path, pattern) then
				return routeDef
			end
		end
	end
	return nil
end

-- Convert path to pattern
function Router:ConvertToPattern(path)
	local pattern = path
	pattern = string.gsub(pattern, "/", "\\/")
	pattern = string.gsub(pattern, ":%w+", "(%w+)")
	return "^" .. pattern .. "$"
end

-- Execute middleware
function Router:ExecuteMiddleware(player, middlewareList, data)
	for _, middlewareName in pairs(middlewareList) do
		local middleware = self.Middleware[middlewareName]
		if middleware then
			local success, result = pcall(middleware, player, data)
			if not success or not result then
				return false
			end
		else
			warn("[Router] Middleware not found: " .. middlewareName)
			return false
		end
	end
	return true
end

-- Execute controller action
function Router:ExecuteAction(player, routeDefinition, data)
	local controllerName = routeDefinition.Controller
	local actionName = routeDefinition.Action
	
	-- Get controller
	local framework = require(ReplicatedStorage.Framework)
	local controller = framework:Get("Controller", controllerName)
	
	if not controller then
		self:SendError(player, "Controller not found: " .. controllerName)
		return
	end
	
	-- Execute action
	if controller[actionName] then
		local success, result = pcall(controller[actionName], controller, player, data)
		if success then
			self:SendResponse(player, result)
		else
			self:SendError(player, "Action failed: " .. result)
		end
	else
		self:SendError(player, "Action not found: " .. actionName)
	end
end

-- Handle middleware request
function Router:HandleMiddleware(player, middlewareName, data)
	local middleware = self.Middleware[middlewareName]
	if middleware then
		local success, result = pcall(middleware, player, data)
		if success then
			self:SendResponse(player, result)
		else
			self:SendError(player, "Middleware execution failed")
		end
	else
		self:SendError(player, "Middleware not found: " .. middlewareName)
	end
end

-- Send response to client
function Router:SendResponse(player, data)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local responseEvent = remoteEvents:FindFirstChild("RouteResponse")
		if responseEvent then
			responseEvent:FireClient(player, data)
		end
	end
end

-- Send error to client
function Router:SendError(player, errorMessage)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local errorEvent = remoteEvents:FindFirstChild("RouteError")
		if errorEvent then
			errorEvent:FireClient(player, errorMessage)
		end
	end
end

-- Generate URL
function Router:GenerateUrl(method, path, params)
	local url = method:upper() .. " " .. path
	
	if params then
		local queryString = {}
		for key, value in pairs(params) do
			table.insert(queryString, key .. "=" .. tostring(value))
		end
		if #queryString > 0 then
			url = url .. "?" .. table.concat(queryString, "&")
		end
	end
	
	return url
end

-- Redirect to route
function Router:Redirect(player, route, data)
	self:HandleRoute(player, route, data)
end

-- Get all routes
function Router:GetRoutes()
	local routes = {}
	for routeKey, routeDef in pairs(self.Routes) do
		table.insert(routes, {
			Route = routeKey,
			Controller = routeDef.Controller,
			Action = routeDef.Action,
			Middleware = routeDef.Middleware
		})
	end
	return routes
end

-- Register default routes
function Router:RegisterDefaults()
	-- Health check route
	self:Get("/health", "SystemController", "HealthCheck")
	
	-- API routes
	self:Get("/api/players", "PlayerController", "GetAllPlayers")
	self:Get("/api/players/:id", "PlayerController", "GetPlayer")
	self:Post("/api/players", "PlayerController", "CreatePlayer")
	self:Put("/api/players/:id", "PlayerController", "UpdatePlayer")
	self:Delete("/api/players/:id", "PlayerController", "DeletePlayer")
	
	print("[Router] Default routes registered")
end

return Router