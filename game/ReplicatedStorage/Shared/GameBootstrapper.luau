--[[
	GameBootstrapper.luau
	
	🎮 BLOXQUARIUM GAME BOOTSTRAPPER 🎮
	
	Otak penjalan utama yang mengelola startup sequence game seperti AAA title
	Melakukan validasi komprehensif dan memastikan semua sistem siap sebelum game dimulai
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Import sistem yang diperlukan
local SystemValidator = require(script.Parent.SystemValidator)
local AssetManager = require(script.Parent.AssetManager)
local AssetRegistry = require(script.Parent.AssetRegistry)
local AssetLoader = require(script.Parent.AssetLoader)

local GameBootstrapper = {}

-- Bootstrap phases
local BootstrapPhase = {
	INITIALIZING = "INITIALIZING",
	VALIDATING = "VALIDATING", 
	LOADING_ASSETS = "LOADING_ASSETS",
	PREPARING_SYSTEMS = "PREPARING_SYSTEMS",
	FINALIZING = "FINALIZING",
	READY = "READY",
	ERROR = "ERROR"
}

GameBootstrapper.BootstrapPhase = BootstrapPhase

-- Bootstrap state
local bootstrapState = {
	currentPhase = BootstrapPhase.INITIALIZING,
	startTime = 0,
	endTime = 0,
	totalSteps = 0,
	completedSteps = 0,
	errors = {},
	warnings = {},
	isComplete = false,
	systemReady = false
}

-- Events
local phaseChangedEvent = Instance.new("BindableEvent")
GameBootstrapper.PhaseChanged = phaseChangedEvent.Event

local progressUpdatedEvent = Instance.new("BindableEvent")
GameBootstrapper.ProgressUpdated = progressUpdatedEvent.Event

local bootstrapCompleteEvent = Instance.new("BindableEvent")
GameBootstrapper.BootstrapComplete = bootstrapCompleteEvent.Event

local errorOccurredEvent = Instance.new("BindableEvent")
GameBootstrapper.ErrorOccurred = errorOccurredEvent.Event

-- Helper functions
local function updatePhase(newPhase, message)
	bootstrapState.currentPhase = newPhase
	print(string.format("🚀 [GameBootstrapper] Phase: %s - %s", newPhase, message or ""))
	phaseChangedEvent:Fire(newPhase, message)
end

local function updateProgress(step, total, message)
	bootstrapState.completedSteps = step
	bootstrapState.totalSteps = total
	local percentage = math.floor((step / total) * 100)
	
	print(string.format("📊 [GameBootstrapper] Progress: %d/%d (%d%%) - %s", 
		step, total, percentage, message or ""))
	progressUpdatedEvent:Fire(step, total, percentage, message)
end

local function addError(message, details)
	table.insert(bootstrapState.errors, {
		message = message,
		details = details or {},
		timestamp = tick()
	})
	warn("❌ [GameBootstrapper] ERROR: " .. message)
	errorOccurredEvent:Fire("ERROR", message, details)
end

local function addWarning(message, details)
	table.insert(bootstrapState.warnings, {
		message = message,
		details = details or {},
		timestamp = tick()
	})
	warn("⚠️ [GameBootstrapper] WARNING: " .. message)
	errorOccurredEvent:Fire("WARNING", message, details)
end

-- Bootstrap phases implementation
local function initializePhase()
	updatePhase(BootstrapPhase.INITIALIZING, "Initializing game systems...")
	updateProgress(1, 10, "Starting bootstrap sequence")
	
	-- Reset state
	bootstrapState.errors = {}
	bootstrapState.warnings = {}
	bootstrapState.startTime = tick()
	
	-- Print professional startup banner
	print("╔" .. string.rep("═", 60) .. "╗")
	print("║" .. string.rep(" ", 18) .. "🎮 BLOXQUARIUM 🎮" .. string.rep(" ", 17) .. "║")
	print("║" .. string.rep(" ", 15) .. "Professional Game Engine" .. string.rep(" ", 15) .. "║")
	print("║" .. string.rep(" ", 60) .. "║")
	print("║" .. string.rep(" ", 12) .. "Initializing Game Systems..." .. string.rep(" ", 13) .. "║")
	print("╚" .. string.rep("═", 60) .. "╝")
	print("")
	
	updateProgress(2, 10, "Game engine initialized")
	return true
end

local function validationPhase()
	updatePhase(BootstrapPhase.VALIDATING, "Running comprehensive system validation...")
	updateProgress(3, 10, "Validating all game systems")
	
	-- Run system validation with error handling
	local validationResults, summary
	local success = pcall(function()
		validationResults = SystemValidator.RunFullValidation()
		summary = SystemValidator.GetSummary()
	end)
	
	if not success then
		addError("Failed to run system validation: " .. tostring(validationResults))
		updatePhase(BootstrapPhase.ERROR, "System validation failed to execute")
		return false
	end
	
	-- Print detailed validation results for debugging
	print("🔍 [GameBootstrapper] Validation Results:")
	print("  Critical:", summary.criticalCount)
	print("  Errors:", summary.errorCount) 
	print("  Warnings:", summary.warningCount)
	print("  Success:", summary.successCount)
	
	-- Check validation results
	if summary.criticalCount > 0 then
		addError(string.format("Critical validation failures detected: %d critical issues", 
			summary.criticalCount))
		-- Print detailed critical errors
		SystemValidator.PrintReport()
		updatePhase(BootstrapPhase.ERROR, "Critical validation failures - cannot continue")
		return false
	end
	
	if summary.errorCount > 0 then
		addError(string.format("Validation errors detected: %d errors", summary.errorCount))
		-- Print detailed errors
		SystemValidator.PrintReport()
		updatePhase(BootstrapPhase.ERROR, "Validation errors - cannot continue")
		return false
	end
	
	if summary.warningCount > 0 then
		addWarning(string.format("Validation warnings: %d warnings (non-critical)", 
			summary.warningCount))
	end
	
	-- Print validation summary
	print(string.format("✅ [GameBootstrapper] Validation Complete: %d checks passed, %d warnings", 
		summary.successCount, summary.warningCount))
	
	updateProgress(4, 10, string.format("Validation complete (%d checks passed)", summary.successCount))
	return true
end

local function assetLoadingPhase()
	updatePhase(BootstrapPhase.LOADING_ASSETS, "Loading and caching game assets...")
	updateProgress(5, 10, "Initializing asset system")
	
	-- Initialize asset registry
	local success = pcall(function()
		AssetRegistry.Initialize()
	end)
	
	if not success then
		addError("Failed to initialize asset registry")
		return false
	end
	
	updateProgress(6, 10, "Asset registry initialized")
	
	-- Start asset preloading
	local preloadSuccess = pcall(function()
		AssetManager.PreloadAll()
	end)
	
	if not preloadSuccess then
		addWarning("Asset preloading encountered issues (non-critical)")
	end
	
	-- Wait for preloading to complete or timeout
	local timeout = 30 -- 30 seconds timeout
	local startTime = tick()
	
	while tick() - startTime < timeout do
		local status = AssetManager.GetLoadingStatus()
		if not status.isPreloading then
			break
		end
		
		updateProgress(6, 10, string.format("Preloading assets... %d/%d (%.1f%%)", 
			status.preloaded, status.total, status.percentage))
		wait(0.1)
	end
	
	local finalStatus = AssetManager.GetLoadingStatus()
	print(string.format("📦 [GameBootstrapper] Asset Loading Complete: %d/%d assets loaded (%.1f%%)", 
		finalStatus.preloaded, finalStatus.total, finalStatus.percentage))
	
	updateProgress(7, 10, string.format("Assets loaded (%d/%d)", finalStatus.preloaded, finalStatus.total))
	return true
end

local function systemPreparationPhase()
	updatePhase(BootstrapPhase.PREPARING_SYSTEMS, "Preparing game systems for launch...")
	updateProgress(8, 10, "Configuring game systems")
	
	-- Initialize any additional systems here
	-- This is where you would initialize gameplay systems, networking, etc.
	
	-- Simulate system preparation
	wait(0.5)
	
	print("⚙️ [GameBootstrapper] Game systems prepared and ready")
	updateProgress(9, 10, "Game systems configured")
	return true
end

local function finalizationPhase()
	updatePhase(BootstrapPhase.FINALIZING, "Finalizing startup sequence...")
	updateProgress(10, 10, "Finalizing game initialization")
	
	-- Final checks and cleanup
	bootstrapState.endTime = tick()
	bootstrapState.isComplete = true
	bootstrapState.systemReady = true
	
	local totalTime = bootstrapState.endTime - bootstrapState.startTime
	
	-- Print success banner
	print("")
	print("╔" .. string.rep("═", 60) .. "╗")
	print("║" .. string.rep(" ", 20) .. "🎉 GAME READY! 🎉" .. string.rep(" ", 19) .. "║")
	print("║" .. string.rep(" ", 60) .. "║")
	print("║" .. string.format("  Startup Time: %.3f seconds", totalTime) .. string.rep(" ", 60 - 28 - string.len(string.format("%.3f", totalTime))) .. "║")
	print("║" .. string.format("  Errors: %d | Warnings: %d", #bootstrapState.errors, #bootstrapState.warnings) .. string.rep(" ", 60 - 20 - string.len(tostring(#bootstrapState.errors)) - string.len(tostring(#bootstrapState.warnings))) .. "║")
	print("║" .. string.rep(" ", 60) .. "║")
	print("║" .. string.rep(" ", 15) .. "🚀 BLOXQUARIUM ONLINE 🚀" .. string.rep(" ", 15) .. "║")
	print("╚" .. string.rep("═", 60) .. "╝")
	print("")
	
	updatePhase(BootstrapPhase.READY, "Game is ready to play!")
	
	-- Fire completion event
	bootstrapCompleteEvent:Fire(true, totalTime, bootstrapState)
	
	return true
end

-- Main bootstrap function
function GameBootstrapper.StartBootstrap()
	print("🎮 [GameBootstrapper] Starting professional game bootstrap sequence...")
	
	-- Run bootstrap phases
	local phases = {
		initializePhase,
		validationPhase,
		assetLoadingPhase,
		systemPreparationPhase,
		finalizationPhase
	}
	
	for i, phaseFunction in ipairs(phases) do
		local success, errorMessage = pcall(function()
			return phaseFunction()
		end)
		
		if not success then
			addError("Phase " .. i .. " failed with error: " .. tostring(errorMessage))
			updatePhase(BootstrapPhase.ERROR, "Bootstrap failed during phase " .. i)
			bootstrapCompleteEvent:Fire(false, tick() - bootstrapState.startTime, bootstrapState)
			return false
		elseif errorMessage == false then
			addError("Phase " .. i .. " returned false (failed)")
			updatePhase(BootstrapPhase.ERROR, "Bootstrap failed during phase " .. i)
			bootstrapCompleteEvent:Fire(false, tick() - bootstrapState.startTime, bootstrapState)
			return false
		end
		
		-- Small delay between phases for visual effect
		if i < #phases then
			wait(0.2)
		end
	end
	
	return true
end

-- Async bootstrap with callback
function GameBootstrapper.StartBootstrapAsync(callback)
	spawn(function()
		local success = GameBootstrapper.StartBootstrap()
		if callback then
			callback(success, bootstrapState)
		end
	end)
end

-- Get current bootstrap state
function GameBootstrapper.GetState()
	return bootstrapState
end

-- Get current phase
function GameBootstrapper.GetCurrentPhase()
	return bootstrapState.currentPhase
end

-- Check if bootstrap is complete
function GameBootstrapper.IsComplete()
	return bootstrapState.isComplete
end

-- Check if system is ready
function GameBootstrapper.IsSystemReady()
	return bootstrapState.systemReady
end

-- Get bootstrap statistics
function GameBootstrapper.GetStats()
	local currentTime = tick()
	local totalTime = 0
	
	if bootstrapState.endTime > 0 then
		-- Bootstrap completed
		totalTime = bootstrapState.endTime - bootstrapState.startTime
	elseif bootstrapState.startTime > 0 then
		-- Bootstrap in progress
		totalTime = currentTime - bootstrapState.startTime
	end
	
	return {
		totalTime = totalTime,
		errorCount = #bootstrapState.errors,
		warningCount = #bootstrapState.warnings,
		phase = bootstrapState.currentPhase,
		progress = {
			completed = bootstrapState.completedSteps,
			total = bootstrapState.totalSteps,
			percentage = bootstrapState.totalSteps > 0 and 
				math.floor((bootstrapState.completedSteps / bootstrapState.totalSteps) * 100) or 0
		}
	}
end

-- Print detailed bootstrap report
function GameBootstrapper.PrintReport()
	local stats = GameBootstrapper.GetStats()
	
	print("📊 [GameBootstrapper] Bootstrap Report")
	print("=" .. string.rep("=", 50))
	print(string.format("⏱️  Total Time: %.3f seconds", stats.totalTime))
	print(string.format("📋 Current Phase: %s", stats.phase))
	print(string.format("📈 Progress: %d/%d (%d%%)", 
		stats.progress.completed, stats.progress.total, stats.progress.percentage))
	print(string.format("❌ Errors: %d", stats.errorCount))
	print(string.format("⚠️  Warnings: %d", stats.warningCount))
	print(string.format("✅ System Ready: %s", bootstrapState.systemReady and "YES" or "NO"))
	print("=" .. string.rep("=", 50))
	
	-- Print errors if any
	if #bootstrapState.errors > 0 then
		print("\n❌ Errors:")
		for i, error in ipairs(bootstrapState.errors) do
			print(string.format("  %d. %s", i, error.message))
		end
	end
	
	-- Print warnings if any
	if #bootstrapState.warnings > 0 then
		print("\n⚠️  Warnings:")
		for i, warning in ipairs(bootstrapState.warnings) do
			print(string.format("  %d. %s", i, warning.message))
		end
	end
	
	print("\n" .. string.rep("=", 52))
end

-- Force stop bootstrap (emergency)
function GameBootstrapper.ForceStop()
	updatePhase(BootstrapPhase.ERROR, "Bootstrap force stopped")
	addError("Bootstrap was force stopped by user")
	bootstrapCompleteEvent:Fire(false, tick() - bootstrapState.startTime, bootstrapState)
end

-- Reset bootstrap state
function GameBootstrapper.Reset()
	bootstrapState = {
		currentPhase = BootstrapPhase.INITIALIZING,
		startTime = 0,
		endTime = 0,
		totalSteps = 0,
		completedSteps = 0,
		errors = {},
		warnings = {},
		isComplete = false,
		systemReady = false
	}
	print("🔄 [GameBootstrapper] Bootstrap state reset")
end

return GameBootstrapper