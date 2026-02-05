-- Server-Side Security Bridge v1.0
-- Professional server-side security handler that works with the dual-bridge system
-- Validates all incoming requests and ensures secure communication flow

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SecureCommunication = require(ReplicatedStorage.Shared.SecureCommunication)
local SecurityFramework = require(ReplicatedStorage.Shared.SecurityFramework)

local SecurityBridge = {}
SecurityBridge.__index = SecurityBridge

-- Security bridge configuration
local BRIDGE_CONFIG = {
	MAX_CONCURRENT_REQUESTS = 100,
	REQUEST_TIMEOUT = 15, -- 15 seconds
	ENABLE_DETAILED_LOGGING = true,
	ENABLE_AUTO_PUNISHMENT = true
}

-- Bridge state
local bridgeState = {
	pendingRequests = {},
	processedRequests = {},
	securityViolations = {},
	bridgeMetrics = {
		totalRequests = 0,
		validatedRequests = 0,
		rejectedRequests = 0,
		securityViolations = 0,
		averageProcessingTime = 0
	}
}

-- Initialize the Security Bridge
function SecurityBridge.new()
	local self = setmetatable({}, SecurityBridge)
	
	-- Setup server-side bridge handlers
	self:_setupServerBridgeHandlers()
	
	-- Initialize monitoring
	self:_initializeBridgeMonitoring()
	
	print("[Security Bridge] Server-side security bridge initialized")
	
	return self
end

-- Setup server bridge handlers
function SecurityBridge:_setupServerBridgeHandlers()
	-- Handle incoming secure messages from clients
	local clientBridge = ReplicatedStorage:FindFirstChild("SecureClientBridge")
	if clientBridge then
		clientBridge.OnServerEvent:Connect(function(player, encryptedMessage)
			self:_processSecureClientMessage(player, encryptedMessage)
		end)
		print("[Security Bridge] Client bridge handler registered")
	else
		warn("[Security Bridge] Client bridge not found!")
	end
	
	-- Setup server response handler
	local serverBridge = ReplicatedStorage:FindFirstChild("SecureServerBridge")
	if serverBridge then
		print("[Security Bridge] Server bridge ready for responses")
	else
		warn("[Security Bridge] Server bridge not found!")
	end
end

-- Initialize bridge monitoring
function SecurityBridge:_initializeBridgeMonitoring()
	-- Monitor bridge performance
	spawn(function()
		while true do
			task.wait(60) -- Log metrics every minute
			self:_logBridgeMetrics()
		end
	end)
	
	-- Cleanup old data
	spawn(function()
		while true do
			task.wait(300) -- Cleanup every 5 minutes
			self:_cleanupBridgeData()
		end
	end)
end

-- Process secure client message
function SecurityBridge:_processSecureClientMessage(player, encryptedMessage)
	local playerId = player.UserId
	local startTime = tick()
	
	-- Log incoming request
	self:_logBridgeEvent(playerId, "REQUEST_RECEIVED", {
		messageSize = #encryptedMessage,
		timestamp = startTime
	})
	
	-- Validate request format
	if not encryptedMessage or type(encryptedMessage) ~= "string" then
		self:_handleSecurityViolation(playerId, "INVALID_MESSAGE_FORMAT", {
			messageType = type(encryptedMessage)
		})
		return false, "Invalid message format"
	end
	
	-- Check request size limit
	if #encryptedMessage > 20480 then -- 20KB limit
		self:_handleSecurityViolation(playerId, "MESSAGE_SIZE_EXCEEDED", {
			messageSize = #encryptedMessage
		})
		return false, "Message size exceeded"
	end
	
	-- Process message through secure communication
	local success, result = SecureCommunication._handleSecureClientMessage(player, encryptedMessage)
	
	local processingTime = tick() - startTime
	
	if success then
		-- Log successful processing
		self:_logBridgeEvent(playerId, "REQUEST_PROCESSED", {
			processingTime = processingTime,
			actionType = result.actionType
		})
		
		-- Update metrics
		bridgeState.bridgeMetrics.totalRequests = bridgeState.bridgeMetrics.totalRequests + 1
		bridgeState.bridgeMetrics.validatedRequests = bridgeState.bridgeMetrics.validatedRequests + 1
		
		-- Store processed request
		table.insert(bridgeState.processedRequests, {
			playerId = playerId,
			timestamp = tick(),
			actionType = result.actionType,
			processingTime = processingTime,
			status = "SUCCESS"
		})
		
		return true, result
		
	else
		-- Handle failed processing
		self:_handleSecurityViolation(playerId, "REQUEST_PROCESSING_FAILED", {
			reason = result,
			processingTime = processingTime
		})
		
		return false, result
	end
end

-- Handle security violations
function SecurityBridge:_handleSecurityViolation(playerId, violationType, details)
	-- Log violation
	local violationData = {
		playerId = playerId,
		violationType = violationType,
		timestamp = tick(),
		details = details
	}
	
	table.insert(bridgeState.securityViolations, violationData)
	
	-- Update metrics
	bridgeState.bridgeMetrics.totalRequests = bridgeState.bridgeMetrics.totalRequests + 1
	bridgeState.bridgeMetrics.rejectedRequests = bridgeState.bridgeMetrics.rejectedRequests + 1
	bridgeState.bridgeMetrics.securityViolations = bridgeState.bridgeMetrics.securityViolations + 1
	
	-- Log violation event
	self:_logBridgeEvent(playerId, "SECURITY_VIOLATION", {
		violationType = violationType,
		details = details
	})
	
	-- Auto-punishment if enabled
	if BRIDGE_CONFIG.ENABLE_AUTO_PUNISHMENT then
		self:_applyAutoPunishment(playerId, violationType, details)
	end
	
	-- Broadcast to security framework
	SecurityFramework._logSecurityEvent(playerId, "BRIDGE_SECURITY_VIOLATION", {
		violationType = violationType,
		details = details
	})
end

-- Apply auto-punishment for security violations
function SecurityBridge:_applyAutoPunishment(playerId, violationType, details)
	local player = game:GetService("Players"):GetPlayerByUserId(playerId)
	if not player then
		return
	end
	
	-- Count recent violations for this player
	local recentViolations = 0
	local currentTime = tick()
	
	for _, violation in ipairs(bridgeState.securityViolations) do
		if violation.playerId == playerId and (currentTime - violation.timestamp) < 300 then -- Last 5 minutes
			recentViolations = recentViolations + 1
		end
	end
	
	-- Apply punishment based on violation count
	if recentViolations >= 5 then
		-- Severe punishment: Kick player
		player:Kick("Multiple security violations detected. Please restart the game.")
		self:_logBridgeEvent(playerId, "PLAYER_KICKED", {
			violationCount = recentViolations,
			violationType = violationType
		})
	elseif recentViolations >= 3 then
		-- Moderate punishment: Warning and temporary restriction
		self:_logBridgeEvent(playerId, "PLAYER_WARNED", {
			violationCount = recentViolations,
			violationType = violationType
		})
	end
end

-- Send secure response to client
function SecurityBridge:sendSecureResponse(player, actionType, actionData)
	local success, message = SecureCommunication.sendToClient(player, actionType, actionData)
	
	if success then
		self:_logBridgeEvent(player.UserId, "RESPONSE_SENT", {
			actionType = actionType,
			messageSize = #tostring(actionData)
		})
	else
		self:_logBridgeEvent(player.UserId, "RESPONSE_FAILED", {
			reason = message,
			actionType = actionType
		})
	end
	
	return success, message
end

-- Broadcast secure message to multiple players
function SecurityBridge:broadcastSecureMessage(players, actionType, actionData)
	local results = {}
	
	for _, player in ipairs(players) do
		local success, message = self:sendSecureResponse(player, actionType, actionData)
		table.insert(results, {
			playerId = player.UserId,
			success = success,
			message = message
		})
	end
	
	return results
end

-- Get bridge statistics
function SecurityBridge:getBridgeStats()
	local currentTime = tick()
	local recentRequests = 0
	local recentViolations = 0
	
	-- Count recent activity
	for _, request in ipairs(bridgeState.processedRequests) do
		if currentTime - request.timestamp < 300 then -- Last 5 minutes
			recentRequests = recentRequests + 1
		end
	end
	
	for _, violation in ipairs(bridgeState.securityViolations) do
		if currentTime - violation.timestamp < 300 then -- Last 5 minutes
			recentViolations = recentViolations + 1
		end
	end
	
	return {
		totalRequests = bridgeState.bridgeMetrics.totalRequests,
		validatedRequests = bridgeState.bridgeMetrics.validatedRequests,
		rejectedRequests = bridgeState.bridgeMetrics.rejectedRequests,
		securityViolations = bridgeState.bridgeMetrics.securityViolations,
		averageProcessingTime = bridgeState.bridgeMetrics.averageProcessingTime,
		recentRequests = recentRequests,
		recentViolations = recentViolations,
		pendingRequests = #bridgeState.pendingRequests,
		activeViolations = #bridgeState.securityViolations
	}
end

-- Log bridge events
function SecurityBridge:_logBridgeEvent(playerId, eventType, details)
	if not BRIDGE_CONFIG.ENABLE_DETAILED_LOGGING then
		return
	end
	
	local logEntry = {
		playerId = playerId,
		eventType = eventType,
		timestamp = tick(),
		details = details,
		eventSource = "SECURITY_BRIDGE"
	}
	
	-- This would typically go to a logging service
	-- For now, just print with security prefix
	print(string.format(
		"[Security Bridge] Player %d: %s - %s",
		playerId, eventType, game:GetService("HttpService"):JSONEncode(details)
	))
end

-- Log bridge metrics
function SecurityBridge:_logBridgeMetrics()
	local metrics = bridgeState.bridgeMetrics
	local totalRequests = metrics.totalRequests
	local successRate = totalRequests > 0 and (metrics.validatedRequests / totalRequests) * 100 or 0
	
	print(string.format(
		"[Security Bridge Metrics] Total: %d | Validated: %d | Rejected: %d | Success Rate: %.1f%% | Violations: %d | Avg Time: %.3fs",
		totalRequests, metrics.validatedRequests, metrics.rejectedRequests, successRate,
		metrics.securityViolations, metrics.averageProcessingTime
	))
end

-- Cleanup bridge data
function SecurityBridge:_cleanupBridgeData()
	-- Cleanup old processed requests (keep last 1000)
	if #bridgeState.processedRequests > 1000 then
		local validRequests = {}
		for i = #bridgeState.processedRequests, #bridgeState.processedRequests - 999, -1 do
			if bridgeState.processedRequests[i] then
				table.insert(validRequests, 1, bridgeState.processedRequests[i])
			end
		end
		bridgeState.processedRequests = validRequests
	end
	
	-- Cleanup old security violations (keep last 500)
	if #bridgeState.securityViolations > 500 then
		local validViolations = {}
		for i = #bridgeState.securityViolations, #bridgeState.securityViolations - 499, -1 do
			if bridgeState.securityViolations[i] then
				table.insert(validViolations, 1, bridgeState.securityViolations[i])
			end
		end
		bridgeState.securityViolations = validViolations
	end
	
	-- Cleanup pending requests (remove expired)
	local currentTime = tick()
	local validPending = {}
	for _, request in ipairs(bridgeState.pendingRequests) do
		if currentTime - request.timestamp < BRIDGE_CONFIG.REQUEST_TIMEOUT then
			table.insert(validPending, request)
		end
	end
	bridgeState.pendingRequests = validPending
end

-- Initialize global Security Bridge instance
local globalSecurityBridge = SecurityBridge.new()

-- Expose methods globally
function SecurityBridge.processSecureMessage(player, encryptedMessage)
	return globalSecurityBridge:_processSecureClientMessage(player, encryptedMessage)
end

function SecurityBridge.sendSecureResponse(player, actionType, actionData)
	return globalSecurityBridge:sendSecureResponse(player, actionType, actionData)
end

function SecurityBridge.broadcastSecureMessage(players, actionType, actionData)
	return globalSecurityBridge:broadcastSecureMessage(players, actionType, actionData)
end

function SecurityBridge.getBridgeStats()
	return globalSecurityBridge:getBridgeStats()
end

print("[Security Bridge] Professional server-side security bridge ready!")

return SecurityBridge
