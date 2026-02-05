-- Configuration Management System v1.0
-- Professional configuration management with client-safe and server-only separation
-- Secure configuration handling with validation and versioning

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local ConfigManager = {}
ConfigManager.__index = ConfigManager

-- Configuration categories
local CONFIG_CATEGORIES = {
	CLIENT_SAFE = "CLIENT_SAFE",
	SERVER_ONLY = "SERVER_ONLY",
	SHARED = "SHARED"
}

-- Configuration structure
local CONFIGURATION = {
	-- Client-safe configurations (can be accessed by client)
	CLIENT_SAFE = {
		-- Graphics settings
		graphics = {
			maxRenderDistance = 1000,
			particleQuality = "HIGH",
			shadowsEnabled = true,
			antiAliasing = "MSAA_4x",
			textureQuality = "HIGH",
			shadowResolution = 2048,
			fpsCap = 60,
			vSyncEnabled = false
		},
		
		-- Audio settings
		audio = {
			masterVolume = 1.0,
			musicVolume = 0.8,
			sfxVolume = 1.0,
			voiceVolume = 1.0,
			audioQuality = "HIGH",
			spatialAudioEnabled = true
		},
		
		-- UI settings
		ui = {
			scale = 1.0,
			theme = "DEFAULT",
			animationsEnabled = true,
			tooltipsEnabled = true,
			minimapEnabled = true,
			chatEnabled = true,
			hudOpacity = 1.0,
			fontSize = "MEDIUM"
		},
		
		-- Gameplay settings
		gameplay = {
			sensitivity = 1.0,
			invertY = false,
			aimAssistEnabled = true,
			crosshairEnabled = true,
			minimapZoom = 1.0,
			interactionDistance = 10,
			autoSaveEnabled = true,
			difficulty = "NORMAL"
		},
		
		-- Network settings
		network = {
			pingThreshold = 150,
			packetLossThreshold = 5,
			bandwidthLimit = 10000,
			compressionEnabled = true,
			predictionEnabled = true
		},
		
		-- Accessibility settings
		accessibility = {
			colorBlindMode = "NONE",
			subtitlesEnabled = false,
			subtitleSize = "MEDIUM",
			highContrastMode = false,
			textToSpeechEnabled = false,
			keyboardNavigation = true
		}
	},
	
	-- Server-only configurations (never sent to client)
	SERVER_ONLY = {
		-- Security settings
		security = {
			antiCheatEnabled = true,
			rateLimitingEnabled = true,
			ipBanningEnabled = true,
			encryptionRequired = true,
			sessionTimeout = 1800, -- 30 minutes
			maxConcurrentSessions = 3,
			securityLogLevel = "HIGH"
		},
		
		-- Game balance
		balance = {
			-- Player stats
			playerStats = {
				maxHealth = 100,
				maxStamina = 100,
				baseDamageMultiplier = 1.0,
				experienceMultiplier = 1.0,
				lootDropRate = 1.0,
				craftingSpeedMultiplier = 1.0
			},
			
			-- Economy
			economy = {
				baseCurrencyRate = 1.0,
				tradingTaxRate = 0.05,
				marketFeeRate = 0.02,
				inflationRate = 0.01,
				maxBankBalance = 1000000
			},
			
			-- Combat
			combat = {
				damageMultiplier = 1.0,
				cooldownReduction = 0.0,
				criticalChance = 0.05,
				blockChance = 0.1,
				dodgeChance = 0.05,
				pvpEnabled = true,
				pvpCooldown = 300 -- 5 minutes
			}
		},
		
		-- Server settings
		server = {
			maxPlayers = 50,
			tickRate = 60,
			backupInterval = 300, -- 5 minutes
			logRetentionDays = 30,
			autoRestartEnabled = true,
			maintenanceMode = false,
			serverName = "Game Server"
		},
		
		-- Database settings
		database = {
			connectionTimeout = 30,
			maxConnections = 100,
			backupEnabled = true,
			encryptionEnabled = true,
			compressionEnabled = true
		},
		
		-- Development settings
		development = {
			debugMode = false,
			verboseLogging = false,
			performanceMonitoring = true,
			profilingEnabled = false,
			hotReloadEnabled = false
		}
	},
	
	-- Shared configurations (sent to client but with server validation)
	SHARED = {
		-- Game rules
		gameRules = {
			maxLevel = 100,
			levelUpExperienceBase = 1000,
			experienceCurveMultiplier = 1.2,
			pvpEnabled = true,
			friendlyFireEnabled = false,
			teamPlayEnabled = true,
			sandboxMode = false
		},
		
		-- World settings
		world = {
			dayNightCycleEnabled = true,
			weatherSystemEnabled = true,
			gravity = 196.2,
			mapSize = 10000,
			seaLevel = 0,
			fogDensity = 0.01,
			fogColor = Color3.fromRGB(128, 128, 128)
		},
		
		-- Content settings
		content = {
			contentRating = "TEEN",
			languageFilterEnabled = true,
			matureContentEnabled = false,
			violenceLevel = "MEDIUM",
			bloodEnabled = true
		}
	}
}

-- Configuration state
local configState = {
	version = "1.0.0",
	lastUpdated = tick(),
	validationRules = {},
	customConfigs = {},
	overrides = {}
}

-- Configuration validator
local ConfigValidator = {}
ConfigValidator.__index = ConfigValidator

function ConfigValidator.new()
	local self = setmetatable({}, ConfigValidator)
	self.rules = {}
	return self
end

-- Initialize the Configuration Manager
function ConfigManager.new()
	local self = setmetatable({}, ConfigManager)
	
	-- Setup configuration validation
	self:_setupValidationRules()
	
	-- Setup configuration monitoring
	self:_setupConfigurationMonitoring()
	
	print("[Config Manager] Initialized with professional-grade configuration management")
	
	return self
end

-- Setup validation rules
function ConfigManager:_setupValidationRules()
	-- Graphics validation rules
	self:_addValidationRule("CLIENT_SAFE.graphics.maxRenderDistance", function(value)
		return type(value) == "number" and value >= 100 and value <= 5000
	end, "Render distance must be between 100 and 5000")
	
	self:_addValidationRule("CLIENT_SAFE.graphics.particleQuality", function(value)
		return value == "LOW" or value == "MEDIUM" or value == "HIGH" or value == "ULTRA"
	end, "Invalid particle quality setting")
	
	self:_addValidationRule("CLIENT_SAFE.graphics.shadowsEnabled", function(value)
		return type(value) == "boolean"
	end, "Shadows enabled must be boolean")
	
	-- Audio validation rules
	self:_addValidationRule("CLIENT_SAFE.audio.masterVolume", function(value)
		return type(value) == "number" and value >= 0 and value <= 1
	end, "Master volume must be between 0 and 1")
	
	-- Gameplay validation rules
	self:_addValidationRule("CLIENT_SAFE.gameplay.sensitivity", function(value)
		return type(value) == "number" and value >= 0.1 and value <= 5.0
	end, "Sensitivity must be between 0.1 and 5.0")
	
	self:_addValidationRule("CLIENT_SAFE.gameplay.difficulty", function(value)
		return value == "EASY" or value == "NORMAL" or value == "HARD" or value == "EXPERT"
	end, "Invalid difficulty setting")
	
	-- Server security validation rules
	self:_addValidationRule("SERVER_ONLY.security.sessionTimeout", function(value)
		return type(value) == "number" and value >= 300 and value <= 7200
	end, "Session timeout must be between 5 minutes and 2 hours")
	
	self:_addValidationRule("SERVER_ONLY.security.maxConcurrentSessions", function(value)
		return type(value) == "number" and value >= 1 and value <= 10
	end, "Max concurrent sessions must be between 1 and 10")
	
	-- Game balance validation rules
	self:_addValidationRule("SERVER_ONLY.balance.playerStats.maxHealth", function(value)
		return type(value) == "number" and value >= 50 and value <= 1000
	end, "Max health must be between 50 and 1000")
	
	self:_addValidationRule("SERVER_ONLY.balance.economy.baseCurrencyRate", function(value)
		return type(value) == "number" and value >= 0.1 and value <= 10.0
	end, "Currency rate must be between 0.1 and 10.0")
	
	-- Server settings validation rules
	self:_addValidationRule("SERVER_ONLY.server.maxPlayers", function(value)
		return type(value) == "number" and value >= 1 and value <= 1000
	end, "Max players must be between 1 and 1000")
	
	self:_addValidationRule("SERVER_ONLY.server.tickRate", function(value)
		return type(value) == "number" and (value == 30 or value == 60 or value == 120)
	end, "Tick rate must be 30, 60, or 120")
end

-- Setup configuration monitoring
function ConfigManager:_setupConfigurationMonitoring()
	-- Monitor configuration changes
	spawn(function()
		while true do
			task.wait(300) -- Log every 5 minutes
			self:_logConfigurationStatus()
		end
	end)
end

-- Add validation rule
function ConfigManager:_addValidationRule(configPath, validator, errorMessage)
	if not configState.validationRules[configPath] then
		configState.validationRules[configPath] = {}
	end
	
	table.insert(configState.validationRules[configPath], {
		validator = validator,
		errorMessage = errorMessage
	})
end

-- Get configuration by category and path
function ConfigManager:getConfig(category, configPath)
	if category == CONFIG_CATEGORIES.CLIENT_SAFE then
		return self:_getClientSafeConfig(configPath)
	elseif category == CONFIG_CATEGORIES.SERVER_ONLY then
		return self:_getServerOnlyConfig(configPath)
	elseif category == CONFIG_CATEGORIES.SHARED then
		return self:_getSharedConfig(configPath)
	else
		return nil, "Invalid configuration category"
	end
end

-- Get client-safe configuration
function ConfigManager:_getClientSafeConfig(configPath)
	local config = CONFIGURATION.CLIENT_SAFE
	
	-- Navigate through the config path
	for part in string.gmatch(configPath, "[^%.]+") do
		if config[part] ~= nil then
			config = config[part]
		else
			return nil, "Configuration path not found: " .. configPath
		end
	end
	
	return config
end

-- Get server-only configuration
function ConfigManager:_getServerOnlyConfig(configPath)
	local config = CONFIGURATION.SERVER_ONLY
	
	-- Navigate through the config path
	for part in string.gmatch(configPath, "[^%.]+") do
		if config[part] ~= nil then
			config = config[part]
		else
			return nil, "Configuration path not found: " .. configPath
		end
	end
	
	return config
end

-- Get shared configuration
function ConfigManager:_getSharedConfig(configPath)
	local config = CONFIGURATION.SHARED
	
	-- Navigate through the config path
	for part in string.gmatch(configPath, "[^%.]+") do
		if config[part] ~= nil then
			config = config[part]
		else
			return nil, "Configuration path not found: " .. configPath
		end
	end
	
	return config
end

-- Set configuration with validation
function ConfigManager:setConfig(category, configPath, value)
	-- Check if this is a server-only config being set from client
	if category == CONFIG_CATEGORIES.SERVER_ONLY then
		return false, "Cannot modify server-only configuration from client"
	end
	
	-- Validate the value
	local validationSuccess, validationMessage = self:_validateConfigValue(category, configPath, value)
	if not validationSuccess then
		return false, validationMessage
	end
	
	-- Apply the configuration
	local success, result = self:_applyConfigChange(category, configPath, value)
	
	if success then
		configState.lastUpdated = tick()
		return true, "Configuration updated successfully"
	else
		return false, result
	end
end

-- Validate configuration value
function ConfigManager:_validateConfigValue(category, configPath, value)
	local fullConfigPath = category .. "." .. configPath
	local rules = configState.validationRules[fullConfigPath]
	
	if rules then
		for _, rule in ipairs(rules) do
			if not rule.validator(value) then
				return false, rule.errorMessage
			end
		end
	end
	
	return true, "Validation passed"
end

-- Apply configuration change
function ConfigManager:_applyConfigChange(category, configPath, value)
	local configTable = nil
	
	if category == CONFIG_CATEGORIES.CLIENT_SAFE then
		configTable = CONFIGURATION.CLIENT_SAFE
	elseif category == CONFIG_CATEGORIES.SERVER_ONLY then
		configTable = CONFIGURATION.SERVER_ONLY
	elseif category == CONFIG_CATEGORIES.SHARED then
		configTable = CONFIGURATION.SHARED
	else
		return false, "Invalid configuration category"
	end
	
	-- Navigate to the parent configuration
	local currentConfig = configTable
	local pathParts = {}
	
	for part in string.gmatch(configPath, "[^%.]+") do
		table.insert(pathParts, part)
	end
	
	-- Navigate to parent
	for i = 1, #pathParts - 1 do
		if currentConfig[pathParts[i]] == nil then
			return false, "Configuration path does not exist"
		end
		currentConfig = currentConfig[pathParts[i]]
	end
	
	-- Set the value
	local lastPart = pathParts[#pathParts]
	currentConfig[lastPart] = value
	
	return true, "Configuration applied successfully"
end

-- Get all client-safe configurations
function ConfigManager:getAllClientSafeConfigs()
	return CONFIGURATION.CLIENT_SAFE
end

-- Get all shared configurations
function ConfigManager:getAllSharedConfigs()
	return CONFIGURATION.SHARED
end

-- Get configuration schema
function ConfigManager:getConfigSchema()
	return {
		clientSafe = CONFIGURATION.CLIENT_SAFE,
		shared = CONFIGURATION.SHARED,
		categories = CONFIG_CATEGORIES,
		version = configState.version
	}
end

-- Validate entire configuration
function ConfigManager:validateConfiguration()
	local validationResults = {
		valid = true,
		errors = {},
		warnings = {}
	}
	
	-- Validate client-safe configs
	self:_validateCategory(CONFIGURATION.CLIENT_SAFE, "CLIENT_SAFE", validationResults)
	
	-- Validate shared configs
	self:_validateCategory(CONFIGURATION.SHARED, "SHARED", validationResults)
	
	-- Validate server-only configs (server-side only)
	if game:GetService("RunService"):IsServer() then
		self:_validateCategory(CONFIGURATION.SERVER_ONLY, "SERVER_ONLY", validationResults)
	end
	
	return validationResults.valid, validationResults
end

-- Validate configuration category
function ConfigManager:_validateCategory(configTable, category, results)
	for configPath, rules in pairs(configState.validationRules) do
		if string.find(configPath, "^" .. category .. "%.") then
			-- Extract the relative path
			local relativePath = string.gsub(configPath, "^" .. category .. "%.", "")
			
			-- Get current value
			local currentValue = self:_getConfigValue(configTable, relativePath)
			
			if currentValue ~= nil then
				for _, rule in ipairs(rules) do
					if not rule.validator(currentValue) then
						table.insert(results.errors, {
							configPath = configPath,
							errorMessage = rule.errorMessage,
							currentValue = currentValue
						})
						results.valid = false
					end
				end
			end
		end
	end
end

-- Get configuration value from table
function ConfigManager:_getConfigValue(configTable, configPath)
	local current = configTable
	
	for part in string.gmatch(configPath, "[^%.]+") do
		if current[part] ~= nil then
			current = current[part]
		else
			return nil
		end
	end
	
	return current
end

-- Override configuration temporarily
function ConfigManager:overrideConfig(category, configPath, value, duration)
	if category == CONFIG_CATEGORIES.SERVER_ONLY then
		return false, "Cannot override server-only configuration"
	end
	
	local overrideKey = category .. "." .. configPath
	local overrideData = {
		value = value,
		expiryTime = tick() + duration,
		originalValue = self:_getConfigValue(CONFIGURATION[category], configPath)
	}
	
	configState.overrides[overrideKey] = overrideData
	
	-- Apply override
	self:_applyConfigChange(category, configPath, value)
	
	-- Schedule removal
	task.delay(duration, function()
		self:_removeConfigOverride(overrideKey)
	end)
	
	return true, "Configuration override applied"
end

-- Remove configuration override
function ConfigManager:_removeConfigOverride(overrideKey)
	local overrideData = configState.overrides[overrideKey]
	if overrideData then
		-- Restore original value
		local category, configPath = string.match(overrideKey, "^(.-)%.(.+)$")
		if overrideData.originalValue then
			self:_applyConfigChange(category, configPath, overrideData.originalValue)
		end
		
		-- Remove override
		configState.overrides[overrideKey] = nil
	end
end

-- Get configuration version
function ConfigManager:getConfigVersion()
	return configState.version
end

-- Get last updated timestamp
function ConfigManager:getLastUpdated()
	return configState.lastUpdated
end

-- Log configuration status
function ConfigManager:_logConfigurationStatus()
	local clientSafeCount = self:_countConfigItems(CONFIGURATION.CLIENT_SAFE)
	local sharedCount = self:_countConfigItems(CONFIGURATION.SHARED)
	local serverOnlyCount = self:_countConfigItems(CONFIGURATION.SERVER_ONLY)
	
	print(string.format(
		"[Config Manager] Configuration Status: Client-Safe: %d | Shared: %d | Server-Only: %d | Version: %s",
		clientSafeCount, sharedCount, serverOnlyCount, configState.version
	))
end

-- Count configuration items
function ConfigManager:_countConfigItems(configTable)
	local count = 0
	
	local function countRecursive(table)
		for key, value in pairs(table) do
			if type(value) == "table" then
				countRecursive(value)
			else
				count = count + 1
			end
		end
	end
	
	countRecursive(configTable)
	return count
end

-- Initialize global Config Manager instance
local globalConfigManager = ConfigManager.new()

-- Expose methods globally
function ConfigManager.getConfig(category, configPath)
	return globalConfigManager:getConfig(category, configPath)
end

function ConfigManager.setConfig(category, configPath, value)
	return globalConfigManager:setConfig(category, configPath, value)
end

function ConfigManager.getAllClientSafeConfigs()
	return globalConfigManager:getAllClientSafeConfigs()
end

function ConfigManager.getAllSharedConfigs()
	return globalConfigManager:getAllSharedConfigs()
end

function ConfigManager.getConfigSchema()
	return globalConfigManager:getConfigSchema()
end

function ConfigManager.validateConfiguration()
	return globalConfigManager:validateConfiguration()
end

function ConfigManager.overrideConfig(category, configPath, value, duration)
	return globalConfigManager:overrideConfig(category, configPath, value, duration)
end

function ConfigManager.getConfigVersion()
	return globalConfigManager:getConfigVersion()
end

function ConfigManager.getLastUpdated()
	return globalConfigManager:getLastUpdated()
end

print("[Config Manager] Professional configuration management system ready!")

return ConfigManager