--[[
	GameBootstrapper.luau (v1.3 - Priority Loading)
	
	Calls the new `preloadInitialAsync` function to only load critical assets
	during the initial loading screen, drastically reducing wait times.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import systems
local SystemValidator = require(script.Parent.SystemValidator)
local AssetManager = require(script.Parent.AssetManager)

local GameBootstrapper = {}

-- Bootstrap phases (no changes)
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

-- State and Events (no changes)
local bootstrapState = { currentPhase = BootstrapPhase.INITIALIZING, startTime = 0, endTime = 0, totalSteps = 0, completedSteps = 0, errors = {}, warnings = {}, isComplete = false, systemReady = false }
local phaseChangedEvent = Instance.new("BindableEvent")
GameBootstrapper.PhaseChanged = phaseChangedEvent.Event
local progressUpdatedEvent = Instance.new("BindableEvent")
GameBootstrapper.ProgressUpdated = progressUpdatedEvent.Event
local bootstrapCompleteEvent = Instance.new("BindableEvent")
GameBootstrapper.BootstrapComplete = bootstrapCompleteEvent.Event
local errorOccurredEvent = Instance.new("BindableEvent")
GameBootstrapper.ErrorOccurred = errorOccurredEvent.Event

-- Helper functions (no changes)
local function updatePhase(newPhase, message)
	bootstrapState.currentPhase = newPhase
	print(string.format("🚀 [GameBootstrapper] Phase: %s - %s", newPhase, message or ""))
	phaseChangedEvent:Fire(newPhase, message)
end

local function updateProgress(step, total, message)
	bootstrapState.completedSteps = step
	bootstrapState.totalSteps = total
	local percentage = math.floor((step / total) * 100)
	print(string.format("📊 [GameBootstrapper] Progress: %d/%d (%d%%) - %s", step, total, percentage, message or ""))
	progressUpdatedEvent:Fire(step, total, percentage, message)
end

local function addError(message, details)
	table.insert(bootstrapState.errors, { message = message, details = details or {}, timestamp = tick() })
	warn("❌ [GameBootstrapper] ERROR: " .. message)
	errorOccurredEvent:Fire("ERROR", message, details)
end

local function addWarning(message, details)
	table.insert(bootstrapState.warnings, { message = message, details = details or {}, timestamp = tick() })
	warn("⚠️ [GameBootstrapper] WARNING: " .. message)
	errorOccurredEvent:Fire("WARNING", message, details)
end

-- Phases 1 & 2 (no changes)
local function initializePhase() updatePhase(BootstrapPhase.INITIALIZING, "Initializing game systems...") updateProgress(1, 5, "Starting bootstrap sequence") bootstrapState.errors = {} bootstrapState.warnings = {} bootstrapState.startTime = tick() print("╔" .. string.rep("═", 60) .. "╗") print("║" .. string.rep(" ", 18) .. "🎮 BLOXQUARIUM 🎮" .. string.rep(" ", 17) .. "║") print("║" .. string.rep(" ", 15) .. "Professional Game Engine" .. string.rep(" ", 15) .. "║") print("╚" .. string.rep("═", 60) .. "╝\n") return true end
local function validationPhase() updatePhase(BootstrapPhase.VALIDATING, "Running comprehensive system validation...") updateProgress(2, 5, "Validating all game systems") local validationResults, summary local success = pcall(function() validationResults = SystemValidator.RunFullValidation() summary = SystemValidator.GetSummary() end) if not success then addError("Failed to run system validation: " .. tostring(validationResults)) updatePhase(BootstrapPhase.ERROR, "System validation failed to execute") return false end if summary.criticalCount > 0 or summary.errorCount > 0 then addError(string.format("Validation failed: %d critical, %d errors", summary.criticalCount, summary.errorCount)) SystemValidator.PrintReport() updatePhase(BootstrapPhase.ERROR, "Critical validation failures - cannot continue") return false end if summary.warningCount > 0 then addWarning(string.format("Validation warnings: %d warnings (non-critical)", summary.warningCount)) SystemValidator.PrintReport() end print(string.format("✅ [GameBootstrapper] Validation Complete: %d checks passed, %d warnings", summary.successCount, summary.warningCount)) return true end

-- Phase 3: Asset Loading (UPDATED)
local function assetLoadingPhase()
    updatePhase(BootstrapPhase.LOADING_ASSETS, "Synchronizing and preloading CRITICAL game assets...")
    updateProgress(3, 5, "Starting critical asset preload...")

    local syncSuccess = true
    if RunService:IsClient() then
        updateProgress(3, 5, "Requesting asset registry from server...")
        syncSuccess = AssetManager.syncWithServerAsync()
    end

    if not syncSuccess then
        addError("Failed to synchronize assets with the server.")
        updatePhase(BootstrapPhase.ERROR, "Asset synchronization failed.")
        return false
    end

    local preloadFinished = Instance.new("BindableEvent")
    local connection

    connection = AssetManager.PreloadComplete:Connect(function(loadedCount, totalCount)
        updateProgress(3, 5, string.format("Critical asset preloading complete. Loaded %d/%d assets.", loadedCount, totalCount))
        preloadFinished:Fire()
        connection:Disconnect()
    end)
    
    local progressConnection
    progressConnection = AssetManager.PreloadProgress:Connect(function(loadedCount, totalCount, assetName)
        local percentage = totalCount > 0 and math.floor((loadedCount / totalCount) * 100) or 100
        updateProgress(3, 5, string.format("Loading %d%% - %s", percentage, assetName))
    end)

    -- UPDATED: Call the new priority preload function
    spawn(function() AssetManager.preloadInitialAsync() end)

    preloadFinished.Event:Wait()
    progressConnection:Disconnect()

    return true
end

-- Phases 4 & 5 (no changes)
local function systemPreparationPhase() updatePhase(BootstrapPhase.PREPARING_SYSTEMS, "Preparing game systems for launch...") updateProgress(4, 5, "Configuring game systems") wait(0.2) print("⚙️ [GameBootstrapper] Game systems prepared and ready") return true end
local function finalizationPhase() updatePhase(BootstrapPhase.FINALIZING, "Finalizing startup sequence...") updateProgress(5, 5, "Finalizing game initialization") bootstrapState.endTime = tick() bootstrapState.isComplete = true bootstrapState.systemReady = true local totalTime = bootstrapState.endTime - bootstrapState.startTime print("\n╔" .. string.rep("═", 60) .. "╗") print("║" .. string.rep(" ", 20) .. "🎉 GAME READY! 🎉" .. string.rep(" ", 19) .. "║") print(string.format("║  Startup Time: %.3f seconds", totalTime) .. string.rep(" ", 50 - string.len(string.format("%.3f", totalTime))) .. "║") print(string.format("║  Errors: %d | Warnings: %d", #bootstrapState.errors, #bootstrapState.warnings) .. string.rep(" ", 41 - string.len(tostring(#bootstrapState.errors)) - string.len(tostring(#bootstrapState.warnings))) .. "║") print("╚" .. string.rep("═", 60) .. "╝\n") updatePhase(BootstrapPhase.READY, "Game is ready to play!") bootstrapCompleteEvent:Fire(true, totalTime, bootstrapState) return true end

-- Main bootstrap function and public API (no changes)
function GameBootstrapper.StartBootstrap() print("🎮 [GameBootstrapper] Starting professional game bootstrap sequence...") local phases = { initializePhase, validationPhase, assetLoadingPhase, systemPreparationPhase, finalizationPhase } for i, phaseFunction in ipairs(phases) do local success, result = pcall(phaseFunction) if not success or result == false then local errorMessage = not success and tostring(result) or ("Phase " .. i .. " returned false") addError("Phase " .. i .. " failed with error: " .. errorMessage) updatePhase(BootstrapPhase.ERROR, "Bootstrap failed during phase " .. i) bootstrapCompleteEvent:Fire(false, tick() - bootstrapState.startTime, bootstrapState) return false end if i < #phases then wait(0.1) end end return true end
function GameBootstrapper.StartBootstrapAsync(callback) spawn(function() local success = GameBootstrapper.StartBootstrap() if callback then callback(success, bootstrapState) end end) end
function GameBootstrapper.GetState() return bootstrapState end
function GameBootstrapper.GetCurrentPhase() return bootstrapState.currentPhase end
function GameBootstrapper.IsComplete() return bootstrapState.isComplete end
function GameBootstrapper.IsSystemReady() return bootstrapState.systemReady end
function GameBootstrapper.GetStats() local currentTime = tick() local totalTime = (bootstrapState.endTime > 0 and bootstrapState.endTime or currentTime) - bootstrapState.startTime return { totalTime = totalTime, errorCount = #bootstrapState.errors, warningCount = #bootstrapState.warnings, phase = bootstrapState.currentPhase, progress = { completed = bootstrapState.completedSteps, total = bootstrapState.totalSteps, percentage = bootstrapState.totalSteps > 0 and math.floor((bootstrapState.completedSteps / bootstrapState.totalSteps) * 100) or 0 } } end
function GameBootstrapper.PrintReport() local stats = GameBootstrapper.GetStats() print("📊 [GameBootstrapper] Bootstrap Report") print("=" .. string.rep("=", 50)) print(string.format("⏱️  Total Time: %.3f seconds", stats.totalTime)) print(string.format("📋 Current Phase: %s", stats.phase)) print(string.format("📈 Progress: %d/%d (%d%%)", stats.progress.completed, stats.progress.total, stats.progress.percentage)) print(string.format("❌ Errors: %d", stats.errorCount)) print(string.format("⚠️  Warnings: %d", stats.warningCount)) print(string.format("✅ System Ready: %s", bootstrapState.systemReady and "YES" or "NO")) print("=" .. string.rep("=", 50)) if #bootstrapState.errors > 0 then print("\n❌ Errors:") for i, error in ipairs(bootstrapState.errors) do print(string.format("  %d. %s", i, error.message)) end end if #bootstrapState.warnings > 0 then print("\n⚠️  Warnings:") for i, warning in ipairs(bootstrapState.warnings) do print(string.format("  %d. %s", i, warning.message)) end end end

return GameBootstrapper
