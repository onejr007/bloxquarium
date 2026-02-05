-- Framework Configuration
-- Centralized configuration management for the MVC framework

local Config = {}

-- Framework version and metadata
Config.Version = "2.0.0"
Config.Name = "Enhanced MVC Framework"
Config.Author = "Framework Developer"
Config.Description = "A modular, structured MVC framework for Roblox"

-- Environment settings
Config.Environment = {
	Development = true,
	Production = false,
	Test = false
}

-- Database configuration
Config.Database = {
	AutoBackup = true,
	BackupInterval = 300, -- 5 minutes
	MaxBackups = 10,
	AutoCleanup = true
}

-- Logging configuration
Config.Logging = {
	Level = "INFO", -- DEBUG, INFO, WARN, ERROR
	ToFile = true,
	ToConsole = true,
	MaxFileSize = 1024 * 1024, -- 1MB
	RotationEnabled = true
}

-- Security configuration
Config.Security = {
	EnableAuth = true,
	EnableRateLimiting = true,
	MaxRequestsPerMinute = 60,
	SessionTimeout = 3600, -- 1 hour
	PasswordMinLength = 8
}

-- Performance configuration
Config.Performance = {
	CacheEnabled = true,
	CacheTTL = 300, -- 5 minutes
	MaxCacheSize = 1000,
	AsyncProcessing = true,
	WorkerPoolSize = 5
}

-- Network configuration
Config.Network = {
	MaxConcurrentRequests = 100,
	RequestTimeout = 30, -- 30 seconds
	RetryAttempts = 3,
	RetryDelay = 1000 -- 1 second
}

-- UI configuration
Config.UI = {
	Theme = "default",
	AnimationEnabled = true,
	AutoHideTooltips = true,
	MaxNotifications = 5
}

-- Game configuration
Config.Game = {
	MaxPlayers = 100,
	AutoSaveInterval = 600, -- 10 minutes
	EnableAnalytics = true,
	EnableTelemetry = false
}

-- Module configuration
Config.Modules = {
	AutoLoad = true,
	EnableHotReload = true,
	ValidationEnabled = true,
	DependencyInjection = true
}

-- Feature flags
Config.Features = {
	AdvancedLogging = true,
	PerformanceMonitoring = true,
	ErrorReporting = true,
	AutoUpdates = false,
	ExperimentalFeatures = false
}

-- Paths configuration
Config.Paths = {
	Models = "src/models",
	Controllers = "src/controllers",
	Views = "src/views",
	Services = "src/services",
	Middleware = "src/middleware",
	Helpers = "src/helpers",
	Libraries = "src/libraries",
	Assets = "assets",
	Exports = "exports"
}

-- Validation rules
Config.Validation = {
	DefaultRules = {
		required = true,
		minLength = 1,
		maxLength = 1000,
		allowEmptyString = false
	},
	CustomRules = {}
}

-- Middleware stack
Config.Middleware = {
	Global = {
		"Security",
		"Logging",
		"RateLimiting"
	},
	Routes = {}
}

-- Service configuration
Config.Services = {
	Database = {
		Provider = "Local",
		AutoConnect = true,
		ConnectionTimeout = 5000
	},
	Cache = {
		Provider = "Memory",
		AutoCleanup = true,
		DefaultTTL = 300
	},
	Analytics = {
		Provider = "Local",
		AutoTrack = true,
		MaxEvents = 1000
	}
}

-- Error handling configuration
Config.Errors = {
	ShowStackTrace = true,
	LogErrors = true,
	NotifyAdmins = false,
	AutoRecover = true,
	MaxErrorReports = 100
}

-- Utility functions for configuration management

-- Get configuration value with fallback
function Config.Get(path, defaultValue)
	local keys = string.split(path, ".")
	local current = Config
	
	for _, key in ipairs(keys) do
		if current[key] == nil then
			return defaultValue
		end
		current = current[key]
	end
	
	return current
end

-- Set configuration value
function Config.Set(path, value)
	local keys = string.split(path, ".")
	local current = Config
	
	for i = 1, #keys - 1 do
		if current[keys[i]] == nil then
			current[keys[i]] = {}
		end
		current = current[keys[i]]
	end
	
	current[keys[#keys]] = value
end

-- Load configuration from file (if available)
function Config.LoadFromFile()
	-- This would load configuration from a file in a real implementation
	-- For now, we'll just return the default configuration
	return Config
end

-- Validate configuration
function Config.Validate()
	local required = {
		"Version",
		"Name",
		"Environment",
		"Database",
		"Logging",
		"Security"
	}
	
	for _, key in ipairs(required) do
		if Config[key] == nil then
			warn("[Config] Missing required configuration: " .. key)
			return false
		end
	end
	
	return true
end

-- Get environment-specific configuration
function Config.GetEnvironmentConfig(env)
	if env == "development" then
		return {
			Development = true,
			Production = false,
			Test = false,
			Logging = { Level = "DEBUG" },
			Security = { EnableAuth = false }
		}
	elseif env == "production" then
		return {
			Development = false,
			Production = true,
			Test = false,
			Logging = { Level = "ERROR" },
			Security = { EnableAuth = true }
		}
	elseif env == "test" then
		return {
			Development = false,
			Production = false,
			Test = true,
			Logging = { Level = "WARN" },
			Security = { EnableAuth = false }
		}
	end
	
	return Config.Environment
end

-- Initialize configuration
function Config.Initialize()
	print("[Config] Initializing framework configuration...")
	
	if not Config.Validate() then
		warn("[Config] Configuration validation failed!")
		return false
	end
	
	print("[Config] Configuration loaded successfully!")
	return true
end

return Config