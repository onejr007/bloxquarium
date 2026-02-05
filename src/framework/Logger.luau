-- Enhanced Logger Class
-- Advanced logging system for the MVC framework

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Logger = {}
Logger.__index = Logger

-- Log levels
Logger.Levels = {
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
	FATAL = 5
}

-- Constructor
function Logger.new(name)
	local self = setmetatable({}, Logger)
	
	self.Name = name or "Framework"
	self.Level = Logger.Levels.INFO
	self.LogToFile = true
	self.LogToConsole = true
	self.LogToRemote = false
	self.MaxFileSize = 1024 * 1024 -- 1MB
	self.LogBuffer = {}
	self.LogHistory = {}
	self.MaxHistorySize = 1000
	
	-- Create log file path
	self.LogFilePath = "logs/" .. self.Name .. "_" .. os.date("%Y%m%d_%H%M%S") .. ".log"
	
	return self
end

-- Set log level
function Logger:SetLevel(level)
	if type(level) == "string" then
		self.Level = Logger.Levels[level:upper()] or Logger.Levels.INFO
	else
		self.Level = level
	end
end

-- Set output options
function Logger:SetOutputOptions(options)
	self.LogToFile = options.logToFile ~= false
	self.LogToConsole = options.logToConsole ~= false
	self.LogToRemote = options.logToRemote or false
	self.MaxFileSize = options.maxFileSize or self.MaxFileSize
end

-- Format log message
function Logger:FormatMessage(level, message, context)
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local levelName = self:GetLevelName(level)
	
	local formattedMessage = string.format("[%s] [%s] [%s] %s", 
		timestamp, levelName, self.Name, message)
	
	if context then
		formattedMessage = formattedMessage .. " | Context: " .. HttpService:JSONEncode(context)
	end
	
	return formattedMessage
end

-- Get level name from number
function Logger:GetLevelName(level)
	for name, value in pairs(Logger.Levels) do
		if value == level then
			return name
		end
	end
	return "UNKNOWN"
end

-- Check if should log
function Logger:ShouldLog(level)
	return level >= self.Level
end

-- Add to log buffer
function Logger:AddToBuffer(message)
	table.insert(self.LogBuffer, message)
	
	-- Limit buffer size
	if #self.LogBuffer > 100 then
		table.remove(self.LogBuffer, 1)
	end
end

-- Write to file
function Logger:WriteToFile(message)
	if not self.LogToFile then return end
	
	-- Check file size and rotate if needed
	if self:CheckFileSize() then
		self:RotateLogFile()
	end
	
	-- Write to file (this would need actual file system access in a real implementation)
	-- For now, we'll just add to history
	self:AddToHistory(message)
end

-- Check file size
function Logger:CheckFileSize()
	-- In a real implementation, this would check actual file size
	-- For now, we'll simulate based on history size
	return #self.LogHistory > 1000
end

-- Rotate log file
function Logger:RotateLogFile()
	local oldPath = self.LogFilePath
	self.LogFilePath = "logs/" .. self.Name .. "_" .. os.date("%Y%m%d_%H%M%S") .. ".log"
	
	-- In a real implementation, this would move/rename the file
	print("[Logger] Rotating log file: " .. oldPath .. " -> " .. self.LogFilePath)
end

-- Add to history
function Logger:AddToHistory(message)
	table.insert(self.LogHistory, {
		timestamp = os.time(),
		message = message
	})
	
	-- Limit history size
	if #self.LogHistory > self.MaxHistorySize then
		table.remove(self.LogHistory, 1)
	end
end

-- Write to console
function Logger:WriteToConsole(message)
	if self.LogToConsole then
		print(message)
	end
end

-- Write to remote service
function Logger:WriteToRemote(message)
	if not self.LogToRemote then return end
	
	-- This would send to a remote logging service
	-- For now, just add to buffer
	self:AddToBuffer(message)
end

-- Core log function
function Logger:Log(level, message, context)
	if not self:ShouldLog(level) then return end
	
	local formattedMessage = self:FormatMessage(level, message, context)
	
	-- Write to outputs
	self:WriteToFile(formattedMessage)
	self:WriteToConsole(formattedMessage)
	self:WriteToRemote(formattedMessage)
end

-- Debug level logging
function Logger:Debug(message, context)
	self:Log(Logger.Levels.DEBUG, message, context)
end

-- Info level logging
function Logger:Info(message, context)
	self:Log(Logger.Levels.INFO, message, context)
end

-- Warning level logging
function Logger:Warn(message, context)
	self:Log(Logger.Levels.WARN, message, context)
end

-- Error level logging
function Logger:Error(message, context)
	self:Log(Logger.Levels.ERROR, message, context)
end

-- Fatal level logging
function Logger:Fatal(message, context)
	self:Log(Logger.Levels.FATAL, message, context)
end

-- Log exception
function Logger:Exception(exception, context)
	local message = "Exception: " .. tostring(exception)
	if exception.trace then
		message = message .. "\nTrace: " .. exception.trace
	end
	
	self:Error(message, context)
end

-- Log performance metrics
function Logger:Performance(operation, duration, context)
	local message = string.format("Performance: %s took %.3fms", operation, duration * 1000)
	self:Debug(message, context)
end

-- Log database operations
function Logger:Database(operation, table, duration, context)
	local message = string.format("Database: %s on table '%s' took %.3fms", 
		operation, table, duration * 1000)
	self:Debug(message, context)
end

-- Log network requests
function Logger:Network(method, url, status, duration, context)
	local message = string.format("Network: %s %s - Status: %d - %.3fms", 
		method, url, status, duration * 1000)
	self:Debug(message, context)
end

-- Get log history
function Logger:GetHistory(limit)
	limit = limit or 100
	local history = {}
	
	for i = math.max(1, #self.LogHistory - limit + 1), #self.LogHistory do
		table.insert(history, self.LogHistory[i])
	end
	
	return history
end

-- Get logs by level
function Logger:GetLogsByLevel(level, limit)
	limit = limit or 100
	local logs = {}
	local levelName = self:GetLevelName(level)
	
	for _, log in ipairs(self.LogHistory) do
		if string.find(log.message, "%[" .. levelName .. "%]") then
			table.insert(logs, log)
			if #logs >= limit then break end
		end
	end
	
	return logs
end

-- Clear log history
function Logger:ClearHistory()
	self.LogHistory = {}
	print("[Logger] Log history cleared")
end

-- Export logs
function Logger:ExportLogs(format)
	local logs = self:GetHistory()
	local exportData = {
		exportTime = os.time(),
		loggerName = self.Name,
		logCount = #logs,
		logs = logs
	}
	
	if format == "json" then
		return HttpService:JSONEncode(exportData)
	elseif format == "csv" then
		return self:ExportToCSV(logs)
	else
		return exportData
	end
end

-- Export to CSV format
function Logger:ExportToCSV(logs)
	local csv = "Timestamp,Level,Logger,Message\n"
	
	for _, log in ipairs(logs) do
		-- Parse log message to extract components
		local timestamp = log.timestamp
		local level = "INFO" -- Would need to parse from message
		local logger = self.Name
		local message = log.message:gsub(",", ";") -- Escape commas
		
		csv = csv .. string.format("%d,%s,%s,%s\n", timestamp, level, logger, message)
	end
	
	return csv
end

-- Start timing operation
function Logger:StartTimer(operation)
	return {
		operation = operation,
		startTime = tick(),
		logger = self,
		stop = function(self)
			local duration = tick() - self.startTime
			self.logger:Performance(self.operation, duration)
			return duration
		end
	}
end

-- Create child logger
function Logger:CreateChild(name)
	local child = Logger.new(self.Name .. "." .. name)
	child.Level = self.Level
	child.LogToFile = self.LogToFile
	child.LogToConsole = self.LogToConsole
	child.LogToRemote = self.LogToRemote
	child.MaxFileSize = self.MaxFileSize
	return child
end

-- Batch logging
function Logger:BatchLog(entries)
	for _, entry in ipairs(entries) do
		self:Log(entry.level, entry.message, entry.context)
	end
end

-- Conditional logging
function Logger:ConditionalLog(condition, level, message, context)
	if condition then
		self:Log(level, message, context)
	end
end

-- Log with tags
function Logger:TaggedLog(tags, level, message, context)
	local tagString = ""
	if tags then
		tagString = "[" .. table.concat(tags, "|") .. "] "
	end
	
	local taggedMessage = tagString .. message
	self:Log(level, taggedMessage, context)
end

return Logger