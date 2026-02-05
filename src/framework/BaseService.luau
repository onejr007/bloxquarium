-- Base Service Class
-- Provides common functionality for all services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = {}
BaseService.__index = BaseService

-- Constructor
function BaseService.new()
	local self = setmetatable({}, BaseService)
	
	-- Service properties
	self.Name = "BaseService"
	self.Initialized = false
	self.Logger = nil
	self.Config = nil
	self.Cache = {}
	self.CacheTTL = 300 -- 5 minutes default
	self.CacheSize = 1000
	
	return self
end

-- Initialize service
function BaseService:Initialize()
	if self.Initialized then
		return
	end
	
	self.Initialized = true
	
	-- Get framework dependencies
	self.Logger = self:GetLogger()
	self.Config = self:GetConfig()
	
	self:Log("Service initialized: " .. self.Name)
end

-- Get logger instance
function BaseService:GetLogger()
	if self.Logger then
		return self.Logger
	end
	
	local Logger = require(ReplicatedStorage.Framework.Logger)
	self.Logger = Logger.new(self.Name)
	return self.Logger
end

-- Get config instance
function BaseService:GetConfig()
	if self.Config then
		return self.Config
	end
	
	local Config = require(ReplicatedStorage.Framework.Config)
	return Config
end

-- Log message
function BaseService:Log(message, level)
	if self.Logger then
		self.Logger:Info(message)
	else
		print("[" .. self.Name .. "] " .. message)
	end
end

-- Log error
function BaseService:Error(message)
	if self.Logger then
		self.Logger:Error(message)
	else
		warn("[" .. self.Name .. "] ERROR: " .. message)
	end
end

-- Log warning
function BaseService:Warn(message)
	if self.Logger then
		self.Logger:Warn(message)
	else
		warn("[" .. self.Name .. "] WARN: " .. message)
	end
end

-- Log debug
function BaseService:Debug(message)
	if self.Logger then
		self.Logger:Debug(message)
	end
end

-- Cache operations
function BaseService:CacheSet(key, value, ttl)
	if not self.Config or not self.Config.Performance.CacheEnabled then
		return
	end
	
	local cacheKey = self.Name .. ":" .. key
	local expiration = os.time() + (ttl or self.CacheTTL)
	
	self.Cache[cacheKey] = {
		value = value,
		expiration = expiration
	}
	
	-- Limit cache size
	if #self.Cache > self.CacheSize then
		self:CleanCache()
	end
end

function BaseService:CacheGet(key)
	if not self.Config or not self.Config.Performance.CacheEnabled then
		return nil
	end
	
	local cacheKey = self.Name .. ":" .. key
	local cached = self.Cache[cacheKey]
	
	if not cached then
		return nil
	end
	
	-- Check expiration
	if os.time() > cached.expiration then
		self.Cache[cacheKey] = nil
		return nil
	end
	
	return cached.value
end

function BaseService:CacheDelete(key)
	local cacheKey = self.Name .. ":" .. key
	self.Cache[cacheKey] = nil
end

function BaseService:CacheClear()
	self.Cache = {}
end

function BaseService:CleanCache()
	local now = os.time()
	local keysToRemove = {}
	
	for key, cached in pairs(self.Cache) do
		if now > cached.expiration then
			table.insert(keysToRemove, key)
		end
	end
	
	for _, key in ipairs(keysToRemove) do
		self.Cache[key] = nil
	end
end

-- Validate input
function BaseService:ValidateInput(data, rules)
	local Validation = require(ReplicatedStorage.Framework.Validation)
	local validation = Validation.new()
	
	return validation:Validate(data, rules)
end

-- Get current timestamp
function BaseService:GetTimestamp()
	return os.time()
end

-- Format timestamp
function BaseService:FormatTimestamp(timestamp)
	return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

-- Generate unique ID
function BaseService:GenerateId()
	return self.Name .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
end

-- Deep copy table
function BaseService:DeepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = self:DeepCopy(value)
	end
	return copy
end

-- Merge tables
function BaseService:MergeTables(target, source)
	for key, value in pairs(source) do
		if type(value) == "table" and type(target[key]) == "table" then
			self:MergeTables(target[key], value)
		else
			target[key] = value
		end
	end
	return target
end

-- Check if value is in array
function BaseService:InArray(value, array)
	for _, item in pairs(array) do
		if item == value then
			return true
		end
	end
	return false
end

-- Get array length
function BaseService:ArrayLength(array)
	local count = 0
	for _ in pairs(array) do
		count = count + 1
	end
	return count
end

-- Shuffle array
function BaseService:ShuffleArray(array)
	local shuffled = self:DeepCopy(array)
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

-- Get random element from array
function BaseService:GetRandomElement(array)
	if #array == 0 then
		return nil
	end
	return array[math.random(1, #array)]
end

-- Clamp value
function BaseService:Clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

-- Lerp between values
function BaseService:Lerp(start, finish, alpha)
	return start + (finish - start) * alpha
end

-- Distance between two points
function BaseService:Distance(point1, point2)
	return (point1 - point2).magnitude
end

-- Angle between two vectors
function BaseService:Angle(vector1, vector2)
	return math.acos(vector1.unit:Dot(vector2.unit))
end

-- Format number with commas
function BaseService:FormatNumber(number)
	local formatted = tostring(math.floor(number))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

-- Format file size
function BaseService:FormatFileSize(bytes)
	if bytes < 1024 then
		return bytes .. " B"
	elseif bytes < 1024 * 1024 then
		return string.format("%.2f KB", bytes / 1024)
	elseif bytes < 1024 * 1024 * 1024 then
		return string.format("%.2f MB", bytes / (1024 * 1024))
	else
		return string.format("%.2f GB", bytes / (1024 * 1024 * 1024))
	end
end

-- Debounce function
function BaseService:Debounce(func, delay)
	local lastCall = 0
	return function(...)
		local now = tick()
		if now - lastCall >= delay then
			lastCall = now
			return func(...)
		end
	end
end

-- Throttle function
function BaseService:Throttle(func, delay)
	local lastCall = 0
	local pending = false
	return function(...)
		local now = tick()
		if not pending then
			pending = true
			delaycall(delay, function()
				pending = false
			end)
			return func(...)
		end
	end
end

-- Retry function with exponential backoff
function BaseService:Retry(func, maxAttempts, baseDelay)
	local attempt = 0
	local delay = baseDelay or 1
	
	return function(...)
		attempt = attempt + 1
		local success, result = pcall(func, ...)
		
		if success then
			return result
		elseif attempt < maxAttempts then
			wait(delay)
			delay = delay * 2 -- Exponential backoff
			return self:Retry(func, maxAttempts, delay)(...)
		else
			error("Max attempts reached: " .. maxAttempts)
		end
	end
end

-- Performance timing
function BaseService:TimeOperation(operationName, func)
	local startTime = tick()
	local result = func()
	local duration = tick() - startTime
	
	if self.Logger then
		self.Logger:Performance(operationName, duration)
	end
	
	return result, duration
end

-- Error handling wrapper
function BaseService:SafeCall(func, ...)
	local success, result = pcall(func, ...)
	
	if not success then
		self:Error("Error in " .. func .. ": " .. tostring(result))
		return nil, result
	end
	
	return result
end

-- Get service statistics
function BaseService:GetStatistics()
	return {
		name = self.Name,
		initialized = self.Initialized,
		cacheSize = self:ArrayLength(self.Cache),
		cacheEnabled = self.Config and self.Config.Performance.CacheEnabled
	}
end

-- Health check
function BaseService:HealthCheck()
	return {
		name = self.Name,
		status = "healthy",
		timestamp = os.time()
	}
end

-- Export service data
function BaseService:Export()
	return {
		name = self.Name,
		initialized = self.Initialized,
		cache = self.Cache,
		timestamp = os.time()
	}
end

-- Import service data
function BaseService:Import(data)
	if data and data.name == self.Name then
		self.Initialized = data.initialized or false
		self.Cache = data.cache or {}
		return true
	end
	return false
end

return BaseService