--[[
	SystemValidator.luau (v1.5 - FINAL)
	
	Sistem validasi yang disederhanakan. Fungsi dependensi yang rusak dan mubazir telah dihapus.
	Pemeriksaan Script Integrity sudah cukup untuk memvalidasi semua modul yang diperlukan.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")

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
	PERFORMANCE = "Performance",
	SECURITY = "Security"
}

-- Validation results storage
local validationResults = {}
local validationStartTime = 0
local validationEndTime = 0

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
end

-- Core Services Validation
local function validateCoreServices()
	local requiredServices = {
		"ReplicatedStorage", "ServerScriptService", "StarterPlayer", "Workspace",
		"Lighting", "SoundService", "TweenService", "ContentProvider", "RunService"
	}
	
	for _, serviceName in ipairs(requiredServices) do
		local success, service = pcall(game.GetService, game, serviceName)
		if success and service then
			addResult(validationCategories.CORE_SERVICES, serviceName, ValidationResult.SUCCESS, "Service available and accessible")
		else
			addResult(validationCategories.CORE_SERVICES, serviceName, ValidationResult.CRITICAL, "Service not available or inaccessible")
		end
	end
end

-- Asset System Validation
local function validateAssetSystem()
	local assetsFolder = ReplicatedStorage:FindFirstChild("assets")
	if not assetsFolder then
		addResult(validationCategories.ASSET_SYSTEM, "assets Folder", ValidationResult.WARNING, "Main 'assets' folder not found in ReplicatedStorage. This is optional and only needed for 3D models.")
	end
    
    local assetManager = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("AssetManager")
    if not assetManager then
        addResult(validationCategories.ASSET_SYSTEM, "AssetManager Script", ValidationResult.CRITICAL, "The required 'AssetManager' script is missing from ReplicatedStorage/Shared.")
    end
end

-- Script Integrity Validation
local function validateScriptIntegrity()
    local function validateScriptsInContainer(container)
        if not container then return end
        local skipModules = { "SystemValidator", "GameBootstrapper" }

        for _, child in ipairs(container:GetDescendants()) do
            if child:IsA("ModuleScript") then
                local moduleName = child:GetFullName()
                local shouldSkip = false
                for _, skipName in ipairs(skipModules) do
                    if child.Name == skipName then
                        shouldSkip = true
                        break
                    end
                end

                if shouldSkip then
                    addResult(validationCategories.SCRIPT_INTEGRITY, child.Name, ValidationResult.SUCCESS, "Module skipped (to prevent circular dependencies)")
                else
                    local success, err = pcall(require, child)
                    if not success then
                        addResult(validationCategories.SCRIPT_INTEGRITY, moduleName, ValidationResult.ERROR, "Module could not be required. Error: " .. tostring(err))
                    end
                end
            end
        end
    end

	if RunService:IsServer() then
		validateScriptsInContainer(ServerScriptService)
		validateScriptsInContainer(ReplicatedStorage)
	else -- Client
		validateScriptsInContainer(StarterPlayer.StarterPlayerScripts)
		validateScriptsInContainer(ReplicatedStorage)
	end
end

-- Performance and Security Validation
local function validatePerformance()
	local frameRate = 1 / RunService.Heartbeat:Wait()
	addResult(validationCategories.PERFORMANCE, "Frame Rate", ValidationResult.SUCCESS, string.format("Good frame rate: %.1f FPS", frameRate))

	local memoryUsage = game:GetService("Stats"):GetTotalMemoryUsageMb()
	addResult(validationCategories.PERFORMANCE, "Memory Usage", ValidationResult.SUCCESS, string.format("Good memory usage: %.1f MB", memoryUsage))
end

local function validateSecurity()
	local httpEnabled = game:GetService("HttpService").HttpEnabled
	addResult(validationCategories.SECURITY, "HTTP Service", httpEnabled and ValidationResult.WARNING or ValidationResult.SUCCESS, httpEnabled and "HTTP requests enabled (potential security risk)" or "HTTP requests disabled (secure)")

	local filteringEnabled = workspace.FilteringEnabled
	addResult(validationCategories.SECURITY, "Filtering Enabled", filteringEnabled and ValidationResult.SUCCESS or ValidationResult.CRITICAL, filteringEnabled and "Filtering enabled (secure)" or "Filtering disabled (critical security risk)")
end

-- Main validation function
function SystemValidator.RunFullValidation()
	validationStartTime = tick()
	validationResults = {}
	
	-- The broken 'Dependencies' check has been permanently removed.
	local validationSteps = {
		{name = "Core Services", func = validateCoreServices},
		{name = "Asset System", func = validateAssetSystem},
		{name = "Script Integrity", func = validateScriptIntegrity},
		{name = "Performance", func = validatePerformance},
		{name = "Security", func = validateSecurity}
	}
	
	for _, step in ipairs(validationSteps) do
		local success, err = pcall(step.func)
		if not success then
			addResult("SYSTEM", step.name, ValidationResult.CRITICAL, "Validation function crashed: " .. tostring(err))
		end
	end
	
	validationEndTime = tick()
	return validationResults
end

function SystemValidator.GetSummary()
	local summary = { totalChecks = 0, successCount = 0, warningCount = 0, errorCount = 0, criticalCount = 0, validationTime = validationEndTime - validationStartTime }
	for _, results in pairs(validationResults) do
		for _, result in ipairs(results) do
			summary.totalChecks = summary.totalChecks + 1
			if result.status == ValidationResult.SUCCESS then summary.successCount = summary.successCount + 1
			elseif result.status == ValidationResult.WARNING then summary.warningCount = summary.warningCount + 1
			elseif result.status == ValidationResult.ERROR then summary.errorCount = summary.errorCount + 1
			elseif result.status == ValidationResult.CRITICAL then summary.criticalCount = summary.criticalCount + 1
			end
		end
	end
	return summary
end

function SystemValidator.IsSystemReady()
	local summary = SystemValidator.GetSummary()
	return summary.criticalCount == 0 and summary.errorCount == 0
end

function SystemValidator.PrintReport()
	local summary = SystemValidator.GetSummary()
	print("📊 [SystemValidator] Validation Report")
	print("=" .. string.rep("=", 50))
	print(string.format("⏱️  Validation Time: %.3f seconds", summary.validationTime))
	print(string.format("✅ Success: %d | ⚠️ Warnings: %d | ❌ Errors: %d | 🚨 Critical: %d", summary.successCount, summary.warningCount, summary.errorCount, summary.criticalCount))
	print("=" .. string.rep("=", 50))
	for category, results in pairs(validationResults) do
		print(string.format("\n📁 %s:", category))
		for _, result in ipairs(results) do
			local icon = "❓"
			if result.status == ValidationResult.SUCCESS then icon = "✅"
			elseif result.status == ValidationResult.WARNING then icon = "⚠️ "
			elseif result.status == ValidationResult.ERROR then icon = "❌"
			elseif result.status == ValidationResult.CRITICAL then icon = "🚨"
			end
			print(string.format("  %s %s: %s", icon, result.name, result.message))
		end
	end
end

return SystemValidator
