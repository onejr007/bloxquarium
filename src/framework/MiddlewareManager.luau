-- Middleware Manager
-- Advanced middleware system for the MVC framework

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MiddlewareManager = {}
MiddlewareManager.__index = MiddlewareManager

-- Constructor
function MiddlewareManager.new()
	local self = setmetatable({}, MiddlewareManager)
	
	self.GlobalMiddleware = {}
	self.RouteMiddleware = {}
	self.MiddlewareStack = {}
	
	return self
end

-- Register global middleware
function MiddlewareManager:RegisterGlobal(name, middleware)
	self.GlobalMiddleware[name] = middleware
	table.insert(self.MiddlewareStack, {
		type = "global",
		name = name,
		middleware = middleware
	})
	return self
end

-- Register route-specific middleware
function MiddlewareManager:RegisterRoute(route, name, middleware)
	if not self.RouteMiddleware[route] then
		self.RouteMiddleware[route] = {}
	end
	
	self.RouteMiddleware[route][name] = middleware
	return self
end

-- Get middleware for a route
function MiddlewareManager:GetMiddlewareForRoute(route)
	local middleware = {}
	
	-- Add global middleware
	for _, global in pairs(self.GlobalMiddleware) do
		table.insert(middleware, global)
	end
	
	-- Add route-specific middleware
	if self.RouteMiddleware[route] then
		for _, routeMiddleware in pairs(self.RouteMiddleware[route]) do
			table.insert(middleware, routeMiddleware)
		end
	end
	
	return middleware
end

-- Execute middleware stack
function MiddlewareManager:Execute(middlewareList, context)
	local index = 0
	
	local function nextMiddleware()
		index = index + 1
		local middleware = middlewareList[index]
		
		if not middleware then
			return true -- All middleware executed successfully
		end
		
		local success, result = pcall(middleware, context, nextMiddleware)
		
		if not success then
			warn("[Middleware] Error in middleware: " .. tostring(result))
			return false
		end
		
		return result
	end
	
	return nextMiddleware()
end

-- Execute global middleware
function MiddlewareManager:ExecuteGlobal(context)
	return self:Execute(self.GlobalMiddleware, context)
end

-- Execute route middleware
function MiddlewareManager:ExecuteRoute(route, context)
	local routeMiddleware = self.RouteMiddleware[route] or {}
	return self:Execute(routeMiddleware, context)
end

-- Execute all middleware for a route
function MiddlewareManager:ExecuteAll(route, context)
	-- Execute global middleware first
	local globalSuccess = self:ExecuteGlobal(context)
	if not globalSuccess then
		return false
	end
	
	-- Execute route-specific middleware
	local routeSuccess = self:ExecuteRoute(route, context)
	return routeSuccess
end

-- Remove middleware
function MiddlewareManager:Remove(name, route)
	if route then
		-- Remove route-specific middleware
		if self.RouteMiddleware[route] then
			self.RouteMiddleware[route][name] = nil
		end
	else
		-- Remove global middleware
		self.GlobalMiddleware[name] = nil
		
		-- Remove from stack
		for i, middleware in ipairs(self.MiddlewareStack) do
			if middleware.name == name and middleware.type == "global" then
				table.remove(self.MiddlewareStack, i)
				break
			end
		end
	end
	return self
end

-- Get all registered middleware
function MiddlewareManager:GetAllMiddleware()
	local all = {
		global = {},
		route = {}
	}
	
	-- Global middleware
	for name in pairs(self.GlobalMiddleware) do
		table.insert(all.global, name)
	end
	
	-- Route middleware
	for route, middleware in pairs(self.RouteMiddleware) do
		all.route[route] = {}
		for name in pairs(middleware) do
			table.insert(all.route[route], name)
		end
	end
	
	return all
end

-- Clear all middleware
function MiddlewareManager:Clear()
	self.GlobalMiddleware = {}
	self.RouteMiddleware = {}
	self.MiddlewareStack = {}
end

-- Create standard middleware functions

-- Authentication middleware
function MiddlewareManager.CreateAuthMiddleware()
	return function(context, next)
		local player = context.player
		local data = context.data
		
		-- Check if user is authenticated
		if not player or not data then
			context.error = "Authentication required"
			return false
		end
		
		-- Add user info to context
		context.user = {
			id = player.UserId,
			name = player.Name,
			displayName = player.DisplayName
		}
		
		return next()
	end
end

-- Rate limiting middleware
function MiddlewareManager.CreateRateLimitMiddleware(maxRequests, windowMs)
	local requestCounts = {}
	
	return function(context, next)
		local player = context.player
		local now = os.time()
		local playerId = player.UserId
		
		-- Initialize request count
		if not requestCounts[playerId] then
			requestCounts[playerId] = {
				count = 0,
				resetTime = now + windowMs
			}
		end
		
		local playerStats = requestCounts[playerId]
		
		-- Reset counter if window expired
		if now > playerStats.resetTime then
			playerStats.count = 0
			playerStats.resetTime = now + windowMs
		end
		
		-- Check rate limit
		if playerStats.count >= maxRequests then
			context.error = "Rate limit exceeded"
			return false
		end
		
		-- Increment counter
		playerStats.count = playerStats.count + 1
		
		return next()
	end
end

-- Logging middleware
function MiddlewareManager.CreateLoggingMiddleware(logger)
	return function(context, next)
		local startTime = tick()
		local player = context.player
		local route = context.route
		
		-- Log request start
		if logger then
			logger:Info(string.format("Request: %s from %s", route, player.Name))
		end
		
		-- Execute next middleware
		local result = next()
		
		-- Log request end
		local duration = tick() - startTime
		if logger then
			logger:Info(string.format("Response: %s - %.3fms", route, duration * 1000))
		end
		
		return result
	end
end

-- Validation middleware
function MiddlewareManager.CreateValidationMiddleware(schema)
	return function(context, next)
		local data = context.data or {}
		
		-- Validate data against schema
		local validation = require(ReplicatedStorage.Framework.Validation)
		local isValid, errors = validation:Validate(data, schema)
		
		if not isValid then
			context.error = "Validation failed"
			context.validationErrors = errors
			return false
		end
		
		return next()
	end
end

-- Error handling middleware
function MiddlewareManager.CreateErrorMiddleware(logger)
	return function(context, next)
		local success, result = pcall(next)
		
		if not success then
			-- Log error
			if logger then
				logger:Error("Middleware error: " .. tostring(result))
			end
			
			-- Set error context
			context.error = "Internal server error"
			context.errorDetails = result
			
			return false
		end
		
		return result
	end
end

-- CORS middleware
function MiddlewareManager.CreateCORSMiddleware(allowedOrigins)
	return function(context, next)
		local origin = context.data.origin
		
		if origin and #allowedOrigins > 0 then
			local isAllowed = false
			for _, allowed in ipairs(allowedOrigins) do
				if origin == allowed then
					isAllowed = true
					break
				end
			end
			
			if not isAllowed then
				context.error = "CORS policy violation"
				return false
			end
		end
		
		return next()
	end
end

-- Performance monitoring middleware
function MiddlewareManager.CreatePerformanceMiddleware(logger)
	return function(context, next)
		local startTime = tick()
		local route = context.route
		
		local result = next()
		
		local duration = tick() - startTime
		
		-- Log slow requests
		if duration > 0.1 then -- 100ms threshold
			if logger then
				logger:Warn(string.format("Slow request: %s took %.3fms", route, duration * 1000))
			end
		end
		
		return result
	end
end

-- Security headers middleware
function MiddlewareManager.CreateSecurityHeadersMiddleware()
	return function(context, next)
		-- Add security headers to response
		context.headers = context.headers or {}
		context.headers["X-Frame-Options"] = "DENY"
		context.headers["X-Content-Type-Options"] = "nosniff"
		context.headers["X-XSS-Protection"] = "1; mode=block"
		
		return next()
	end
end

-- Request ID middleware
function MiddlewareManager.CreateRequestIDMiddleware()
	return function(context, next)
		-- Generate unique request ID
		context.requestId = "req_" .. os.time() .. "_" .. math.random(1000, 9999)
		
		return next()
	end
end

-- Transaction middleware
function MiddlewareManager.CreateTransactionMiddleware(database)
	return function(context, next)
		local success, result
		
		-- Start transaction
		if database and database.BeginTransaction then
			database:BeginTransaction()
		end
		
		success, result = pcall(next)
		
		-- Commit or rollback
		if success and database then
			if database.Commit then
				database:Commit()
			end
		else
			if database.Rollback then
				database:Rollback()
			end
		end
		
		return success and result
	end
end

-- Cache middleware
function MiddlewareManager.CreateCacheMiddleware(cache, ttl)
	return function(context, next)
		local route = context.route
		local cacheKey = "route_" .. route
		
		-- Try to get from cache
		local cached = cache:Get(cacheKey)
		if cached then
			context.cached = true
			context.result = cached
			return true
		end
		
		-- Execute next middleware
		local success = next()
		
		-- Cache result
		if success and context.result then
			cache:Set(cacheKey, context.result, ttl)
		end
		
		return success
	end
end

-- Priority middleware execution
function MiddlewareManager:ExecuteWithPriority(middlewareList, context)
	-- Sort middleware by priority (if defined)
	local sortedMiddleware = {}
	for _, middleware in pairs(middlewareList) do
		table.insert(sortedMiddleware, middleware)
	end
	
	table.sort(sortedMiddleware, function(a, b)
		local priorityA = a.priority or 0
		local priorityB = b.priority or 0
		return priorityA < priorityB
	end)
	
	return self:Execute(sortedMiddleware, context)
end

-- Conditional middleware
function MiddlewareManager.CreateConditionalMiddleware(condition, middleware)
	return function(context, next)
		if condition(context) then
			return middleware(context, next)
		else
			return next()
		end
	end
end

return MiddlewareManager