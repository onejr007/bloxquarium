--[[
	AssetErrorHandler.luau
	
	Error handling dan fallback mechanisms untuk asset system
	Menangani error loading, missing assets, dan recovery mechanisms
]]

local AssetErrorHandler = {}

-- Error types
AssetErrorHandler.ErrorTypes = {
	ASSET_NOT_FOUND = "ASSET_NOT_FOUND",
	PRELOAD_FAILED = "PRELOAD_FAILED",
	CLONE_FAILED = "CLONE_FAILED",
	SPAWN_FAILED = "SPAWN_FAILED",
	REGISTRY_ERROR = "REGISTRY_ERROR"
}

-- Error logging
local errorLog = {}
local maxLogEntries = 100

-- Event untuk error notifications
local errorEvent = Instance.new("BindableEvent")
AssetErrorHandler.ErrorOccurred = errorEvent.Event

-- Fungsi untuk log error
function AssetErrorHandler.LogError(errorType, message, assetName, additionalData)
	local timestamp = os.time()
	local errorEntry = {
		type = errorType,
		message = message,
		assetName = assetName,
		timestamp = timestamp,
		additionalData = additionalData or {}
	}
	
	-- Tambahkan ke log
	table.insert(errorLog, errorEntry)
	
	-- Batasi ukuran log
	if #errorLog > maxLogEntries then
		table.remove(errorLog, 1)
	end
	
	-- Print error untuk debugging
	warn(string.format("[AssetErrorHandler] %s: %s (Asset: %s)", 
		errorType, message, assetName or "unknown"))
	
	-- Fire event
	errorEvent:Fire(errorEntry)
	
	return errorEntry
end

-- Fungsi untuk mendapatkan error log
function AssetErrorHandler.GetErrorLog()
	return errorLog
end

-- Fungsi untuk clear error log
function AssetErrorHandler.ClearErrorLog()
	errorLog = {}
	print("[AssetErrorHandler] Error log cleared")
end

-- Fungsi untuk mendapatkan error statistics
function AssetErrorHandler.GetErrorStats()
	local stats = {}
	
	for _, errorType in pairs(AssetErrorHandler.ErrorTypes) do
		stats[errorType] = 0
	end
	
	for _, entry in pairs(errorLog) do
		if stats[entry.type] then
			stats[entry.type] = stats[entry.type] + 1
		end
	end
	
	return stats
end

-- Safe wrapper untuk asset operations
function AssetErrorHandler.SafeGetAsset(assetName, fallbackAsset)
	local success, result = pcall(function()
		local AssetRegistry = require(script.Parent.AssetRegistry)
		return AssetRegistry.GetAsset(assetName)
	end)
	
	if success and result then
		return result
	else
		AssetErrorHandler.LogError(
			AssetErrorHandler.ErrorTypes.ASSET_NOT_FOUND,
			"Failed to get asset",
			assetName,
			{error = result}
		)
		
		-- Return fallback jika ada
		if fallbackAsset then
			print("[AssetErrorHandler] Using fallback asset for:", assetName)
			return fallbackAsset
		end
		
		return nil
	end
end

-- Safe wrapper untuk asset cloning
function AssetErrorHandler.SafeCloneAsset(assetName, fallbackAsset)
	local success, result = pcall(function()
		local AssetRegistry = require(script.Parent.AssetRegistry)
		return AssetRegistry.GetAssetClone(assetName)
	end)
	
	if success and result then
		return result
	else
		AssetErrorHandler.LogError(
			AssetErrorHandler.ErrorTypes.CLONE_FAILED,
			"Failed to clone asset",
			assetName,
			{error = result}
		)
		
		-- Try fallback
		if fallbackAsset then
			local fallbackSuccess, fallbackResult = pcall(function()
				return fallbackAsset:Clone()
			end)
			
			if fallbackSuccess then
				print("[AssetErrorHandler] Using fallback clone for:", assetName)
				return fallbackResult
			end
		end
		
		return nil
	end
end

-- Safe wrapper untuk asset preloading
function AssetErrorHandler.SafePreloadAsset(assetName)
	local success, result = pcall(function()
		local AssetLoader = require(script.Parent.AssetLoader)
		return AssetLoader.PreloadAsset(assetName)
	end)
	
	if not success then
		AssetErrorHandler.LogError(
			AssetErrorHandler.ErrorTypes.PRELOAD_FAILED,
			"Failed to preload asset",
			assetName,
			{error = result}
		)
		return false
	end
	
	return result
end

-- Safe wrapper untuk asset spawning
function AssetErrorHandler.SafeSpawnAsset(assetName, position, parent, fallbackAsset)
	local success, result = pcall(function()
		local AssetLoader = require(script.Parent.AssetLoader)
		return AssetLoader.SpawnAsset(assetName, position, parent)
	end)
	
	if success and result then
		return result
	else
		AssetErrorHandler.LogError(
			AssetErrorHandler.ErrorTypes.SPAWN_FAILED,
			"Failed to spawn asset",
			assetName,
			{error = result, position = position, parent = parent}
		)
		
		-- Try with fallback
		if fallbackAsset then
			local fallbackSuccess, fallbackResult = pcall(function()
				local clone = fallbackAsset:Clone()
				clone.Parent = parent or workspace
				
				if position and clone.PrimaryPart then
					clone:SetPrimaryPartCFrame(CFrame.new(position))
				elseif position and clone:IsA("Part") then
					clone.Position = position
				end
				
				return clone
			end)
			
			if fallbackSuccess then
				print("[AssetErrorHandler] Using fallback spawn for:", assetName)
				return fallbackResult
			end
		end
		
		return nil
	end
end

-- Fungsi untuk create fallback asset (simple part)
function AssetErrorHandler.CreateFallbackAsset(name, size, color)
	name = name or "FallbackAsset"
	size = size or Vector3.new(4, 4, 4)
	color = color or Color3.new(1, 0, 1) -- Magenta untuk mudah dikenali
	
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Anchored = true
	
	-- Tambahkan label untuk identifikasi
	local gui = Instance.new("SurfaceGui")
	gui.Parent = part
	gui.Face = Enum.NormalId.Front
	
	local label = Instance.new("TextLabel")
	label.Parent = gui
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "FALLBACK\n" .. name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	
	return part
end

-- Fungsi untuk recovery dari error
function AssetErrorHandler.RecoverFromError(errorEntry)
	print("[AssetErrorHandler] Attempting recovery for error:", errorEntry.type)
	
	if errorEntry.type == AssetErrorHandler.ErrorTypes.ASSET_NOT_FOUND then
		-- Try to re-scan assets
		local success, result = pcall(function()
			local AssetRegistry = require(script.Parent.AssetRegistry)
			AssetRegistry.Initialize()
		end)
		
		if success then
			print("[AssetErrorHandler] Re-initialized asset registry")
			return true
		end
	elseif errorEntry.type == AssetErrorHandler.ErrorTypes.PRELOAD_FAILED then
		-- Try to preload again after delay
		spawn(function()
			wait(5)
			AssetErrorHandler.SafePreloadAsset(errorEntry.assetName)
		end)
		return true
	end
	
	return false
end

-- Fungsi untuk health check
function AssetErrorHandler.HealthCheck()
	local stats = AssetErrorHandler.GetErrorStats()
	local totalErrors = 0
	
	for _, count in pairs(stats) do
		totalErrors = totalErrors + count
	end
	
	local health = {
		totalErrors = totalErrors,
		errorStats = stats,
		recentErrors = {},
		healthScore = math.max(0, 100 - totalErrors) -- Simple health score
	}
	
	-- Get recent errors (last 10 minutes)
	local currentTime = os.time()
	for _, entry in pairs(errorLog) do
		if currentTime - entry.timestamp <= 600 then -- 10 minutes
			table.insert(health.recentErrors, entry)
		end
	end
	
	return health
end

-- Auto-recovery system
spawn(function()
	while true do
		wait(300) -- Check every 5 minutes
		
		local health = AssetErrorHandler.HealthCheck()
		
		if #health.recentErrors > 5 then
			print("[AssetErrorHandler] High error rate detected, attempting recovery...")
			
			-- Try to recover from recent errors
			for _, errorEntry in pairs(health.recentErrors) do
				AssetErrorHandler.RecoverFromError(errorEntry)
			end
		end
	end
end)

return AssetErrorHandler