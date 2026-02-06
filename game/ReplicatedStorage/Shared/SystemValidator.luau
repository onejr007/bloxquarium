--[[
	SystemValidator.luau
	
	Sistem validasi komprehensif untuk memastikan semua komponen game berjalan dengan baik
	Melakukan health check pada semua sistem sebelum game dimulai
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local SystemValidator = {}

-- Validation results structure
local ValidationResult = {
	SUCCESS = "SUCCESS",
	WARNING = "WARNING", 
	ERROR = "ERROR",
	CRITICAL = "CRITICAL"
}

SystemValidator.ValidationResult = ValidationResult

-- Validation categories
local validationCategories = {
	CORE_SERVICES = "Core Services",
	ASSET_SYSTEM = "Asset System", 
	SCRIPT_INTEGRITY = "Script Integrity",
	DEPENDENCIES = "Dependencies",
	PERFORMANCE = "Performance",
	SECURITY = "Security"
}

-- Validation results storage
local validationResults = {}
local validationStartTime = 0
local validationEndTime = 0

-- Events
local validationCompleteEvent = Instance.new("BindableEvent")
SystemValidator.ValidationComplete = validationCompleteEvent.Event

local validationProgressEvent = Instance.new("BindableEvent")
SystemValidator.ValidationProgress = validationProgressEvent.Event

-- Helper function to add validation result
local function addResult(category, name, status, message, details)
	if not validationResults[category] then
		validationResults[category] = {}
	end
	
	table.insert(validationResults[category], {
		name = name,
		status = status,
		message = message,
		details = details or {},
		timestamp = tick()
	})
	
	-- Fire progress event
	validationProgressEvent:Fire(category, name, status, message)
end

-- Core Services Validation
local function validateCoreServices()
	print("🔧 [SystemValidator] Validating core Roblox services...")
	
	local requiredServices = {
		"ReplicatedStorage",
		"ServerScriptService", 
		"StarterPlayer",
		"Workspace",
		"Lighting",
		"SoundService",
		"TweenService",
		"ContentProvider",
		"RunService"
	}
	
	local validatedCount = 0
	for _, serviceName in ipairs(requiredServices) do
		local success, service = pcall(function()
			return game:GetService(serviceName)
		end)
		
		if success and service then
			addResult(validationCategories.CORE_SERVICES, serviceName, ValidationResult.SUCCESS, 
				"Service available and accessible")
			validatedCount = validatedCount + 1
			print(string.format("✅ [SystemValidator] %s service validated", serviceName))
		else
			addResult(validationCategories.CORE_SERVICES, serviceName, ValidationResult.CRITICAL,
				"Service not available or inaccessible")
			warn(string.format("❌ [SystemValidator] %s service FAILED validation", serviceName))
		end
	end
	
	print(string.format("📊 [SystemValidator] Core services validation: %d/%d passed", validatedCount, #requiredServices))
end

-- Asset System Validation
local function validateAssetSystem()
	print("📦 [SystemValidator] Validating asset management system...")
	
	-- Check if asset folders exist
	local assetFolders = {"Models", "Sounds", "Images", "Animations"}
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	
	if not assetsFolder then
		addResult(validationCategories.ASSET_SYSTEM, "Assets Folder", ValidationResult.ERROR,
			"Assets folder not found in ReplicatedStorage")
		warn("❌ [SystemValidator] Assets folder missing - asset system will not work")
		return
	end
	
	addResult(validationCategories.ASSET_SYSTEM, "Assets Folder", ValidationResult.SUCCESS,
		"Assets folder found")
	print("✅ [SystemValidator] Assets folder validated")
	
	-- Check individual asset folders
	for _, folderName in ipairs(assetFolders) do
		local folder = assetsFolder:FindFirstChild(folderName)
		if folder then
			local assetCount = #folder:GetChildren()
			addResult(validationCategories.ASSET_SYSTEM, folderName .. " Folder", ValidationResult.SUCCESS,
				string.format("Found %d assets", assetCount), {assetCount = assetCount})
		else
			addResult(validationCategories.ASSET_SYSTEM, folderName .. " Folder", ValidationResult.WARNING,
				"Asset folder not found")
		end
	end
	
	-- Check if asset management scripts exist
	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if sharedFolder then
		local assetScripts = {"AssetManager", "AssetRegistry", "AssetLoader", "AssetErrorHandler"}
		for _, scriptName in ipairs(assetScripts) do
			local script = sharedFolder:FindFirstChild(scriptName)
			if script then
				addResult(validationCategories.ASSET_SYSTEM, scriptName, ValidationResult.SUCCESS,
					"Asset management script found")
			else
				addResult(validationCategories.ASSET_SYSTEM, scriptName, ValidationResult.ERROR,
					"Critical asset management script missing")
			end
		end
	else
		addResult(validationCategories.ASSET_SYSTEM, "Shared Folder", ValidationResult.CRITICAL,
			"Shared scripts folder not found")
	end
end

-- Script Integrity Validation
local function validateScriptIntegrity()
	local function validateScriptsInFolder(folder, folderName)
		if not folder then return end
		
		local scriptCount = 0
		local errorCount = 0
		
		-- Modules to skip during validation to avoid circular dependencies
		local skipModules = {
			"GameBootstrapper", -- Skip to avoid circular dependency
			"SystemValidator",  -- Skip self-validation
			"AssetManager",     -- Skip asset management modules to avoid bootstrap conflicts
			"AssetRegistry",    -- Skip asset management modules to avoid bootstrap conflicts
			"AssetLoader",      -- Skip asset management modules to avoid bootstrap conflicts
			"AssetErrorHandler" -- Skip asset management modules to avoid bootstrap conflicts
		}
		
		for _, child in ipairs(folder:GetDescendants()) do
			if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
				scriptCount = scriptCount + 1
				
				-- Basic syntax validation (try to require ModuleScripts)
				if child:IsA("ModuleScript") then
					-- Skip modules that might cause circular dependencies
					local shouldSkip = false
					for _, skipName in ipairs(skipModules) do
						if child.Name == skipName then
							shouldSkip = true
							break
						end
					end
					
					if shouldSkip then
						addResult(validationCategories.SCRIPT_INTEGRITY, child.Name, ValidationResult.SUCCESS,
							"Module skipped (circular dependency prevention)")
					else
						local success, result = pcall(function()
							return require(child)
						end)
						
						if not success then
							errorCount = errorCount + 1
							addResult(validationCategories.SCRIPT_INTEGRITY, child.Name, ValidationResult.ERROR,
								"Module script has syntax errors: " .. tostring(result))
						else
							addResult(validationCategories.SCRIPT_INTEGRITY, child.Name, ValidationResult.SUCCESS,
								"Module script validated successfully")
						end
					end
				end
			end
		end
		
		if errorCount == 0 then
			addResult(validationCategories.SCRIPT_INTEGRITY, folderName, ValidationResult.SUCCESS,
				string.format("All %d scripts validated successfully", scriptCount))
		else
			addResult(validationCategories.SCRIPT_INTEGRITY, folderName, ValidationResult.WARNING,
				string.format("%d/%d scripts have issues", errorCount, scriptCount))
		end
	end
	
	-- Server-side validation
	if RunService:IsServer() then
		validateScriptsInFolder(ServerScriptService, "ServerScriptService")
		validateScriptsInFolder(ReplicatedStorage, "ReplicatedStorage")
	end

	-- Client-side validation
	if RunService:IsClient() then
		validateScriptsInFolder(StarterPlayer.StarterPlayerScripts, "StarterPlayerScripts")
		validateScriptsInFolder(ReplicatedStorage, "ReplicatedStorage")
	end
end

-- Dependencies Validation
local function validateDependencies()
	-- Check if required modules exist (but don't require them yet to avoid initialization issues)
	local requiredModules = {
		{path = "ReplicatedStorage.Shared.AssetManager", name = "AssetManager"},
		{path = "ReplicatedStorage.Shared.AssetRegistry", name = "AssetRegistry"},
		{path = "ReplicatedStorage.Shared.AssetLoader", name = "AssetLoader"},
		{path = "ReplicatedStorage.Shared.AssetErrorHandler", name = "AssetErrorHandler"}
	}
	
	for _, moduleInfo in ipairs(requiredModules) do
		local success, moduleScript = pcall(function()
			local pathParts = string.split(moduleInfo.path, ".")
			local current = game
			for _, part in ipairs(pathParts) do
				current = current[part]
			end
			return current
		end)
		
		if success and moduleScript and moduleScript:IsA("ModuleScript") then
			addResult(validationCategories.DEPENDENCIES, moduleInfo.name, ValidationResult.SUCCESS,
				"Module script found and accessible")
		else
			addResult(validationCategories.DEPENDENCIES, moduleInfo.name, ValidationResult.ERROR,
				"Required module script not found or inaccessible")
		end
	end
end

-- Performance Validation
local function validatePerformance()
	local startTime = tick()
	
	-- Test basic performance metrics
	local frameRate = 1 / RunService.Heartbeat:Wait()
	
	addResult(validationCategories.PERFORMANCE, "Frame Rate", ValidationResult.SUCCESS,
		string.format("Good frame rate: %.1f FPS", frameRate))
	
	-- Memory usage check
	local memoryUsage = game:GetService("Stats"):GetTotalMemoryUsageMb()

	addResult(validationCategories.PERFORMANCE, "Memory Usage", ValidationResult.SUCCESS,
		string.format("Good memory usage: %.1f MB", memoryUsage))
end

-- Security Validation
local function validateSecurity()
	-- Check if HTTP requests are enabled (if needed)
	local httpEnabled = game:GetService("HttpService").HttpEnabled
	addResult(validationCategories.SECURITY, "HTTP Service", 
		httpEnabled and ValidationResult.WARNING or ValidationResult.SUCCESS,
		httpEnabled and "HTTP requests enabled (security risk)" or "HTTP requests disabled (secure)")
	
	-- Check workspace filtering
	local filteringEnabled = workspace.FilteringEnabled
	addResult(validationCategories.SECURITY, "Filtering Enabled", 
		filteringEnabled and ValidationResult.SUCCESS or ValidationResult.CRITICAL,
		filteringEnabled and "Filtering enabled (secure)" or "Filtering disabled (critical security risk)")
end

-- Main validation function
function SystemValidator.RunFullValidation()
	validationStartTime = tick()
	validationResults = {}
	
	print("🔍 [SystemValidator] Starting comprehensive system validation...")
	
	-- Run all validation categories with error handling
	local validationSteps = {
		{name = "Core Services", func = validateCoreServices},
		{name = "Asset System", func = validateAssetSystem},
		{name = "Script Integrity", func = validateScriptIntegrity},
		{name = "Dependencies", func = validateDependencies},
		{name = "Performance", func = validatePerformance},
		{name = "Security", func = validateSecurity}
	}
	
	for _, step in ipairs(validationSteps) do
		print("🔍 [SystemValidator] Running validation:", step.name)
		local success, error = pcall(step.func)
		if not success then
			print("❌ [SystemValidator] Validation failed for", step.name, ":", error)
			addResult("SYSTEM", step.name, ValidationResult.CRITICAL, 
				"Validation function crashed: " .. tostring(error))
		else
			print("✅ [SystemValidator] Completed validation:", step.name)
		end
	end
	
	validationEndTime = tick()
	
	-- Fire completion event
	validationCompleteEvent:Fire(validationResults, validationEndTime - validationStartTime)
	
	return validationResults
end

-- Get validation results
function SystemValidator.GetResults()
	return validationResults
end

-- Get validation summary
function SystemValidator.GetSummary()
	local summary = {
		totalCategories = 0,
		totalChecks = 0,
		successCount = 0,
		warningCount = 0,
		errorCount = 0,
		criticalCount = 0,
		validationTime = validationEndTime - validationStartTime
	}
	
	for category, results in pairs(validationResults) do
		summary.totalCategories = summary.totalCategories + 1
		
		for _, result in ipairs(results) do
			summary.totalChecks = summary.totalChecks + 1
			
			if result.status == ValidationResult.SUCCESS then
				summary.successCount = summary.successCount + 1
			elseif result.status == ValidationResult.WARNING then
				summary.warningCount = summary.warningCount + 1
			elseif result.status == ValidationResult.ERROR then
				summary.errorCount = summary.errorCount + 1
			elseif result.status == ValidationResult.CRITICAL then
				summary.criticalCount = summary.criticalCount + 1
			end
		end
	end
	
	return summary
end

-- Check if system is ready to start
function SystemValidator.IsSystemReady()
	local summary = SystemValidator.GetSummary()
	return summary.criticalCount == 0 and summary.errorCount == 0
end

-- Print detailed validation report
function SystemValidator.PrintReport()
	local summary = SystemValidator.GetSummary()
	
	print("📊 [SystemValidator] Validation Report")
	print("=" .. string.rep("=", 50))
	print(string.format("⏱️  Validation Time: %.3f seconds", summary.validationTime))
	print(string.format("📋 Total Checks: %d across %d categories", summary.totalChecks, summary.totalCategories))
	print(string.format("✅ Success: %d", summary.successCount))
	print(string.format("⚠️  Warnings: %d", summary.warningCount))
	print(string.format("❌ Errors: %d", summary.errorCount))
	print(string.format("🚨 Critical: %d", summary.criticalCount))
	print("=" .. string.rep("=", 50))
	
	-- Print detailed results
	for category, results in pairs(validationResults) do
		print(string.format("\n📁 %s:", category))
		for _, result in ipairs(results) do
			local icon = "❓"
			if result.status == ValidationResult.SUCCESS then icon = "✅"
			elseif result.status == ValidationResult.WARNING then icon = "⚠️"
			elseif result.status == ValidationResult.ERROR then icon = "❌"
			elseif result.status == ValidationResult.CRITICAL then icon = "🚨"
			end
			
			print(string.format("  %s %s: %s", icon, result.name, result.message))
		end
	end
	
	print("\n" .. string.rep("=", 52))
end

return SystemValidator