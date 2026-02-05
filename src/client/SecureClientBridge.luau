-- Client-Side Secure Bridge v1.0
-- Professional client-side security handler for the dual-bridge system
-- Manages secure communication from client to server with validation and encryption

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SecureCommunication = require(ReplicatedStorage.Shared.SecureCommunication)
local SecurityFramework = require(ReplicatedStorage.Shared.SecurityFramework)
local Players = game:GetService("Players")

local SecureClientBridge = {}
SecureClientBridge.__index = SecureClientBridge

-- Client bridge configuration
local CLIENT_BRIDGE_CONFIG = {
	MAX_RETRY_ATTEMPTS = 3,
	RETRY_DELAY = 1, -- 1 second
	ENABLE_REQUEST_CACHING = true,
	ENABLE_DETAILED_LOGGING = true,
	REQUEST_TIMEOUT = 10 -- 10 seconds
}

-- Client bridge state
local clientBridgeState = {
	playerId = nil,
	sessionId = nil,
	currentToken = nil,
	pendingRequests = {},
	requestCache = {},
	bridgeMetrics = {
		totalRequests = 0,
		successfulRequests = 0,
		failedRequests = 0,
		retryAttempts = 0,
		averageResponseTime = 0
	}
}

-- Initialize the Secure Client Bridge
function SecureClientBridge.new()
	local self = setmetatable({}, SecureClientBridge)
	
	-- Get player information
	local player = Players.LocalPlayer
	if player then
		clientBridgeState.playerId = player.UserId
		print("[Secure Client Bridge] Initialized for player: " .. player.UserId)
	else
		warn("[Secure Client Bridge] No local player found")
		return nil
	end
	
	-- Setup client-side bridge handlers
	self:_setupClientBridgeHandlers()
	
	-- Initialize monitoring
	self:_initializeClientBridgeMonitoring()
	
	-- Request initial session and token
	self:_requestInitialSession()
	
	print("[Secure Client Bridge] Client-side secure bridge initialized")
	
	return self
end

-- Setup client bridge handlers
function SecureClientBridge:_setupClientBridgeHandlers()
	-- Handle incoming secure messages from server
	local serverBridge = ReplicatedStorage:FindFirstChild("SecureServerBridge")
	if serverBridge then
		serverBridge.OnClientEvent:Connect(function(encryptedMessage)
			self:_handleSecureServerMessage(encryptedMessage)
		end)
		print("[Secure Client Bridge] Server bridge handler registered")
	else
		warn("[Secure Client Bridge] Server bridge not found!")
	end
end

-- Initialize client bridge monitoring
function SecureClientBridge:_initializeClientBridgeMonitoring()
	-- Monitor bridge performance
	spawn(function()
		while true do
			task.wait(60) -- Log metrics every minute
			self:_logClientBridgeMetrics()
		end
	end)
	
	-- Cleanup old data
	spawn(function()
		while true do
			task.wait(300) -- Cleanup every 5 minutes
			self:_cleanupClientBridgeData()
		end
	end)
end

-- Request initial session and token
function SecureClientBridge:_requestInitialSession()
	-- This would typically be handled by an authentication system
	-- For now, we'll simulate getting a session and token
	task.spawn(function()
		-- Simulate server response time
		task.wait(1)
		
		-- Generate mock session and token
		local sessionId = "mock_session_" .. clientBridgeState.playerId .. "_" .. tick()
		local token = "mock_token_" .. clientBridgeState.playerId .. "_" .. tick()
		
		clientBridgeState.sessionId = sessionId
		clientBridgeState.currentToken = token
		
		print("[Secure Client Bridge] Initial session established: " .. sessionId)
	end)
end

-- Send secure request to server
function SecureClientBridge:sendSecureRequest(actionType, actionData, callback)
	-- Validate client state
	if not clientBridgeState.playerId or not clientBridgeState.sessionId or not clientBridgeState.currentToken then
		self:_logClientBridgeEvent("CLIENT_STATE_INVALID", {
			hasPlayerId = clientBridgeState.playerId ~= nil,
			hasSessionId = clientBridgeState.sessionId ~= nil,
			hasToken = clientBridgeState.currentToken ~= nil
		})
		return false, "Client state invalid"
	end
	
	-- Create request ID
	local requestId = "req_" .. clientBridgeState.playerId .. "_" .. tick()
	
	-- Create request data
	local requestData = {
		requestId = requestId,
		actionType = actionType,
		actionData = actionData,
		timestamp = tick(),
		retryCount = 0
	}
	
	-- Store pending request
	clientBridgeState.pendingRequests[requestId] = requestData
	
	-- Send request with retry logic
	local success, result = self:_sendRequestWithRetry(requestData)
	
	-- Remove from pending requests
	clientBridgeState.pendingRequests[requestId] = nil
	
	-- Update metrics
	clientBridgeState.bridgeMetrics.totalRequests = clientBridgeState.bridgeMetrics.totalRequests + 1
	if success then
		clientBridgeState.bridgeMetrics.successfulRequests = clientBridgeState.bridgeMetrics.successfulRequests + 1
	else
		clientBridgeState.bridgeMetrics.failedRequests = clientBridgeState.bridgeMetrics.failedRequests + 1
	end
	
	-- Handle callback if provided
	if callback then
		callback(success, result, requestData)
	end
	
	return success, result
end

-- Send request with retry logic
function SecureClientBridge:_sendRequestWithRetry(requestData)
	local startTime = tick()
	
	for attempt = 1, CLIENT_BRIDGE_CONFIG.MAX_RETRY_ATTEMPTS do
		-- Send request through secure communication
		local success, result = SecureCommunication.sendToServer(
			clientBridgeState.playerId,
			clientBridgeState.sessionId,
			clientBridgeState.currentToken,
			requestData.actionType,
			requestData.actionData
		)
		
		if success then
			local responseTime = tick() - startTime
			self:_logClientBridgeEvent("REQUEST_SUCCESS", {
				requestId = requestData.requestId,
				attempt = attempt,
				responseTime = responseTime,
				actionType = requestData.actionType
			})
			return true, result
		else
			clientBridgeState.bridgeMetrics.retryAttempts = clientBridgeState.bridgeMetrics.retryAttempts + 1
			
			self:_logClientBridgeEvent("REQUEST_FAILED", {
				requestId = requestData.requestId,
				attempt = attempt,
				reason = result,
				actionType = requestData.actionType
			})
			
			-- Wait before retry (except on last attempt)
			if attempt < CLIENT_BRIDGE_CONFIG.MAX_RETRY_ATTEMPTS then
				task.wait(CLIENT_BRIDGE_CONFIG.RETRY_DELAY)
			end
		end
	end
	
	-- All retries failed
	self:_logClientBridgeEvent("REQUEST_PERMANENTLY_FAILED", {
		requestId = requestData.requestId,
		totalAttempts = CLIENT_BRIDGE_CONFIG.MAX_RETRY_ATTEMPTS,
		actionType = requestData.actionType
	})
	
	return false, "All retry attempts failed"
end

-- Handle secure server message
function SecureClientBridge:_handleSecureServerMessage(encryptedMessage)
	-- Decrypt message using secure communication
	local message = SecureCommunication._handleSecureServerMessage(encryptedMessage)
	
	if message then
		self:_logClientBridgeEvent("SERVER_MESSAGE_RECEIVED", {
			actionType = message.actionType,
			timestamp = message.timestamp
		})
		
		-- Process the message based on action type
		self:_processServerMessage(message)
		
		return true, message
	else
		self:_logClientBridgeEvent("SERVER_MESSAGE_DECRYPTION_FAILED", {})
		return false, "Message decryption failed"
	end
end

-- Process server message
function SecureClientBridge:_processServerMessage(message)
	-- This is where you would handle different types of server messages
	-- For example: updates, notifications, responses to requests, etc.
	
	if message.actionType == "UPDATE_TOKEN" then
		-- Handle token update
		self:_updateToken(message.actionData.newToken)
	elseif message.actionType == "SECURITY_ALERT" then
		-- Handle security alerts
		self:_handleSecurityAlert(message.actionData)
	elseif message.actionType == "GAME_UPDATE" then
		-- Handle game state updates
		self:_handleGameUpdate(message.actionData)
	end
end

-- Update token
function SecureClientBridge:_updateToken(newToken)
	clientBridgeState.currentToken = newToken
	self:_logClientBridgeEvent("TOKEN_UPDATED", {
		tokenLength = #newToken
	})
end

-- Handle security alert
function SecureClientBridge:_handleSecurityAlert(alertData)
	self:_logClientBridgeEvent("SECURITY_ALERT_RECEIVED", alertData)
	
	-- Handle different types of security alerts
	if alertData.type == "SESSION_EXPIRED" then
		-- Request new session
		self:_requestInitialSession()
	elseif alertData.type == "SECURITY_VIOLATION" then
		-- Handle security violation
		warn("[Secure Client Bridge] Security violation detected: " .. alertData.message)
	end
end

-- Handle game update
function SecureClientBridge:_handleGameUpdate(updateData)
	self:_logClientBridgeEvent("GAME_UPDATE_RECEIVED", {
		updateType = updateData.type,
		updateSize = #tostring(updateData)
	})
	
	-- Process game state updates
	-- This would typically update the client's game state
end

-- Get client bridge statistics
function SecureClientBridge:getClientBridgeStats()
	local currentTime = tick()
	local recentRequests = 0
	
	-- Count recent activity
	for _, request in pairs(clientBridgeState.pendingRequests) do
		if currentTime - request.timestamp < 300 then -- Last 5 minutes
			recentRequests = recentRequests + 1
		end
	end
	
	return {
		totalRequests = clientBridgeState.bridgeMetrics.totalRequests,
		successfulRequests = clientBridgeState.bridgeMetrics.successfulRequests,
		failedRequests = clientBridgeState.bridgeMetrics.failedRequests,
		retryAttempts = clientBridgeState.bridgeMetrics.retryAttempts,
		averageResponseTime = clientBridgeState.bridgeMetrics.averageResponseTime,
		pendingRequests = #table.keys(clientBridgeState.pendingRequests),
		recentRequests = recentRequests,
		hasValidSession = clientBridgeState.sessionId ~= nil,
		hasValidToken = clientBridgeState.currentToken ~= nil
	}
end

-- Log client bridge events
function SecureClientBridge:_logClientBridgeEvent(eventType, details)
	if not CLIENT_BRIDGE_CONFIG.ENABLE_DETAILED_LOGGING then
		return
	end
	
	local logEntry = {
		eventType = eventType,
		timestamp = tick(),
		details = details,
		eventSource = "SECURE_CLIENT_BRIDGE"
	}
	
	-- This would typically go to a logging service
	-- For now, just print with security prefix
	print(string.format(
		"[Secure Client Bridge] %s - %s",
		eventType, game:GetService("HttpService"):JSONEncode(details)
	))
end

-- Log client bridge metrics
function SecureClientBridge:_logClientBridgeMetrics()
	local metrics = clientBridgeState.bridgeMetrics
	local totalRequests = metrics.totalRequests
	local successRate = totalRequests > 0 and (metrics.successfulRequests / totalRequests) * 100 or 0
	
	print(string.format(
		"[Secure Client Bridge Metrics] Total: %d | Successful: %d | Failed: %d | Success Rate: %.1f%% | Retries: %d",
		totalRequests, metrics.successfulRequests, metrics.failedRequests, successRate,
		metrics.retryAttempts
	))
end

-- Cleanup client bridge data
function SecureClientBridge:_cleanupClientBridgeData()
	-- Cleanup old pending requests (remove expired)
	local currentTime = tick()
	local validPending = {}
	for requestId, request in pairs(clientBridgeState.pendingRequests) do
		if currentTime - request.timestamp < CLIENT_BRIDGE_CONFIG.REQUEST_TIMEOUT then
			validPending[requestId] = request
		end
	end
	clientBridgeState.pendingRequests = validPending
	
	-- Cleanup request cache if enabled
	if CLIENT_BRIDGE_CONFIG.ENABLE_REQUEST_CACHING then
		-- Keep only last 100 cached requests
		local cacheKeys = table.keys(clientBridgeState.requestCache)
		if #cacheKeys > 100 then
			for i = 1, #cacheKeys - 100 do
				clientBridgeState.requestCache[cacheKeys[i]] = nil
			end
		end
	end
end

-- Initialize global Secure Client Bridge instance
local globalSecureClientBridge = SecureClientBridge.new()

-- Expose methods globally
function SecureClientBridge.sendSecureRequest(actionType, actionData, callback)
	return globalSecureClientBridge:sendSecureRequest(actionType, actionData, callback)
end

function SecureClientBridge.getClientBridgeStats()
	return globalSecureClientBridge:getClientBridgeStats()
end

print("[Secure Client Bridge] Professional client-side secure bridge ready!")

return SecureClientBridge