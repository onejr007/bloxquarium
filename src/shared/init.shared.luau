-- Shared Initialization
-- Shared utilities and constants for the MVC framework

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Framework constants
local FrameworkConstants = {
	VERSION = "1.0.0",
	NAME = "MVC Framework",
	AUTHOR = "Framework Developer",
	
	-- HTTP methods
	HTTP_METHODS = {
		GET = "GET",
		POST = "POST",
		PUT = "PUT",
		DELETE = "DELETE",
		PATCH = "PATCH"
	},
	
	-- Response codes
	RESPONSE_CODES = {
		SUCCESS = 200,
		CREATED = 201,
		NO_CONTENT = 204,
		BAD_REQUEST = 400,
		UNAUTHORIZED = 401,
		FORBIDDEN = 403,
		NOT_FOUND = 404,
		INTERNAL_ERROR = 500
	},
	
	-- Event names
	EVENTS = {
		FRAMEWORK_READY = "FrameworkReady",
		CLIENT_READY = "ClientReady",
		ROUTE_REQUEST = "RouteRequest",
		ROUTE_RESPONSE = "RouteResponse",
		ROUTE_ERROR = "RouteError",
		BROADCAST_MESSAGE = "BroadcastMessage",
		PRIVATE_MESSAGE = "PrivateMessage"
	}
}

-- Utility functions
local Utils = {}

-- Generate unique ID
function Utils.GenerateId()
	return "id_" .. os.time() .. "_" .. math.random(1000, 9999)
end

-- Format timestamp
function Utils.FormatTimestamp(timestamp)
	local date = os.date("*t", timestamp)
	return string.format("%04d-%02d-%02d %02d:%02d:%02d", 
		date.year, date.month, date.day, 
		date.hour, date.min, date.sec)
end

-- Deep copy table
function Utils.DeepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = Utils.DeepCopy(value)
	end
	return copy
end

-- Merge tables
function Utils.MergeTables(target, source)
	for key, value in pairs(source) do
		if type(value) == "table" and type(target[key]) == "table" then
			Utils.MergeTables(target[key], value)
		else
			target[key] = value
		end
	end
	return target
end

-- Check if value is in array
function Utils.InArray(value, array)
	for _, item in pairs(array) do
		if item == value then
			return true
		end
	end
	return false
end

-- Get array length
function Utils.ArrayLength(array)
	local count = 0
	for _ in pairs(array) do
		count = count + 1
	end
	return count
end

-- Shuffle array
function Utils.ShuffleArray(array)
	local shuffled = Utils.DeepCopy(array)
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

-- Get random element from array
function Utils.GetRandomElement(array)
	if #array == 0 then
		return nil
	end
	return array[math.random(1, #array)]
end

-- Clamp value
function Utils.Clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

-- Lerp between values
function Utils.Lerp(start, finish, alpha)
	return start + (finish - start) * alpha
end

-- Distance between two points
function Utils.Distance(point1, point2)
	return (point1 - point2).magnitude
end

-- Angle between two vectors
function Utils.Angle(vector1, vector2)
	return math.acos(vector1.unit:Dot(vector2.unit))
end

-- Format number with commas
function Utils.FormatNumber(number)
	local formatted = tostring(math.floor(number))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

-- Format file size
function Utils.FormatFileSize(bytes)
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

-- Get current timestamp
function Utils.GetTimestamp()
	return os.time()
end

-- Sleep function (coroutine-based)
function Utils.Sleep(seconds)
	local start = tick()
	repeat wait() until tick() - start >= seconds
end

-- Debounce function
function Utils.Debounce(func, delay)
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
function Utils.Throttle(func, delay)
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
function Utils.Retry(func, maxAttempts, baseDelay)
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
			return Utils.Retry(func, maxAttempts, delay)(...)
		else
			error("Max attempts reached: " .. maxAttempts)
		end
	end
end

-- Create singleton pattern
function Utils.CreateSingleton(class)
	local instance = nil
	return function(...)
		if not instance then
			instance = class.new(...)
		end
		return instance
	end
end

-- Validate email
function Utils.IsValidEmail(email)
	if type(email) ~= "string" then
		return false
	end
	local emailPattern = "^[a-zA-Z0-9._%-%+]-@[a-zA-Z0-9.-]%.[a-zA-Z][a-zA-Z][a-zA-Z]*$"
	return string.match(email, emailPattern) ~= nil
end

-- Validate URL
function Utils.IsValidUrl(url)
	if type(url) ~= "string" then
		return false
	end
	local urlPattern = "^https?://[a-zA-Z0-9.-]+%.[a-zA-Z][a-zA-Z][a-zA-Z]*"
	return string.match(url, urlPattern) ~= nil
end

-- Sanitize string
function Utils.SanitizeString(input)
	if type(input) ~= "string" then
		return ""
	end
	
	-- Remove potentially dangerous characters
	input = string.gsub(input, "[<>\"'%;]", "")
	input = string.gsub(input, "\\", "")
	input = string.gsub(input, "\n", " ")
	input = string.gsub(input, "\r", " ")
	input = string.gsub(input, "\t", " ")
	
	-- Trim whitespace
	input = string.gsub(input, "^%s+", "")
	input = string.gsub(input, "%s+$", "")
	
	return input
end

-- Export shared module
local Shared = {
	Constants = FrameworkConstants,
	Utils = Utils
}

return Shared
