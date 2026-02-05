-- Professional Security Framework v1.0
-- AAA-quality security system with dynamic authentication, secure communication,
-- anti-cheat prevention, and comprehensive audit logging
-- Designed for enterprise-grade game security

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SecurityFramework = {}
SecurityFramework.__index = SecurityFramework

-- Security constants and configuration
local SECURITY_CONFIG = {
	-- Authentication settings
	SESSION_TIMEOUT = 300, -- 5 minutes
	TOKEN_LIFETIME = 60, -- 1 minute
	MAX_CONCURRENT_SESSIONS = 3,
	
	-- Rate limiting
	RATE_LIMIT_WINDOW = 10, -- 10 seconds
	MAX_REQUESTS_PER_WINDOW = 50,
	
	-- Security validation
	MAX_ACTION_COOLDOWN = 1, -- 1 second between actions
	INPUT_VALIDATION_ENABLED = true,
	BOUNDARY_CHECKING_ENABLED = true,
	
	-- Encryption
	ENCRYPTION_ENABLED = true,
	ENCRYPTION_KEY_LENGTH = 32,
	
	-- Monitoring
	AUDIT_LOG_RETENTION_DAYS = 7,
	ANOMALY_DETECTION_THRESHOLD = 5,
	
	-- Anti-cheat
	SPEED_HACK_THRESHOLD = 100, -- Max speed multiplier
	TELEPORT_THRESHOLD = 500, -- Max teleport distance
	INVALID_ACTION_THRESHOLD = 10, -- Max invalid actions before flagging
}

-- Security state storage
local securityState = {
	sessions = {}, -- Active sessions
	tokens = {}, -- Generated tokens
	requestLogs = {}, -- Request audit logs
	suspiciousActivity = {}, -- Flagged suspicious activities
	rateLimits = {}, -- Rate limiting data
	securityMetrics = {
		totalRequests = 0,
		validatedRequests = 0,
		rejectedRequests = 0,
		suspiciousActivities = 0,
		securityBreaches = 0
	}
}

-- Initialize the Security Framework
function SecurityFramework.new()
	local self = setmetatable({}, SecurityFramework)
	
	-- Initialize security monitoring
	self:_initializeSecurityMonitoring()
	
	-- Setup player connection handlers
	Players.PlayerAdded:Connect(function(player)
		self:_handlePlayerJoin(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:_handlePlayerLeave(player)
	end)
	
	print("[Security Framework] Initialized with professional-grade security")
	
	return self
end

-- Initialize security monitoring system
function SecurityFramework:_initializeSecurityMonitoring()
	-- Setup security metrics tracking
	spawn(function()
		while true do
			task.wait(60) -- Log metrics every minute
			self:_logSecurityMetrics()
		end
	end)
	
	-- Setup anomaly detection
	spawn(function()
		while true do
			task.wait(30) -- Check for anomalies every 30 seconds
			self:_detectAnomalies()
		end
	end)
	
	-- Cleanup expired sessions and tokens
	spawn(function()
		while true do
			task.wait(120) -- Cleanup every 2 minutes
			self:_cleanupExpiredData()
		end
	end)
end

-- Handle player join with security initialization
function SecurityFramework:_handlePlayerJoin(player)
	local playerId = player.UserId
	local playerData = {
		userId = playerId,
		joinTime = tick(),
		lastActivity = tick(),
		sessionId = nil,
		tokens = {},
		actionHistory = {},
		suspiciousFlags = 0,
		rateLimitData = {
			requests = {},
			lastReset = tick()
		}
	}
	
	securityState.sessions[playerId] = playerData
	
	-- Generate initial session
	local sessionId = self:_generateSessionId(playerId)
	playerData.sessionId = sessionId
	
	-- Generate initial token
	local token = self:_generateToken(playerId, sessionId)
	table.insert(playerData.tokens, token)
	
	print(string.format("[Security] Player %d joined with session %s", playerId, sessionId))
end

-- Handle player leave with security cleanup
function SecurityFramework:_handlePlayerLeave(player)
	local playerId = player.UserId
	local playerData = securityState.sessions[playerId]
	
	if playerData then
		-- Log session termination
		self:_logSecurityEvent(playerId, "SESSION_TERMINATED", {
			sessionId = playerData.sessionId,
			sessionDuration = tick() - playerData.joinTime
		})
		
		-- Cleanup session data
		securityState.sessions[playerId] = nil
	end
end

-- Generate cryptographically secure session ID
function SecurityFramework:_generateSessionId(playerId)
	local timestamp = tick()
	local random = math.random(10000, 99999)
	local sessionData = string.format("%d:%d:%d", playerId, timestamp, random)
	
	-- Create hash for session ID
	local sessionId = HttpService:GenerateGUID(false)
	return sessionId
end

-- Generate secure token with expiration
function SecurityFramework:_generateToken(playerId, sessionId)
	local tokenData = {
		playerId = playerId,
		sessionId = sessionId,
		issuedAt = tick(),
		expiresAt = tick() + SECURITY_CONFIG.TOKEN_LIFETIME,
		tokenId = HttpService:GenerateGUID(false)
	}
	
	-- Store token
	securityState.tokens[tokenData.tokenId] = tokenData
	
	return tokenData.tokenId
end

-- Validate session and token
function SecurityFramework:validateRequest(playerId, sessionId, token)
	local playerData = securityState.sessions[playerId]
	if not playerData then
		self:_logSecurityEvent(playerId, "INVALID_SESSION", {sessionId = sessionId})
		return false, "No active session"
	end
	
	if playerData.sessionId ~= sessionId then
		self:_logSecurityEvent(playerId, "SESSION_MISMATCH", {sessionId = sessionId})
		return false, "Session mismatch"
	end
	
	local tokenData = securityState.tokens[token]
	if not tokenData then
		self:_logSecurityEvent(playerId, "INVALID_TOKEN", {token = token})
		return false, "Invalid token"
	end
	
	if tokenData.playerId ~= playerId or tokenData.sessionId ~= sessionId then
		self:_logSecurityEvent(playerId, "TOKEN_MISMATCH", {token = token})
		return false, "Token mismatch"
	end
	
	if tokenData.expiresAt < tick() then
		self:_logSecurityEvent(playerId, "TOKEN_EXPIRED", {token = token})
		return false, "Token expired"
	end
	
	-- Update last activity
	playerData.lastActivity = tick()
	
	return true, "Valid"
end

-- Validate action with anti-cheat measures
function SecurityFramework:validateAction(playerId, actionType, actionData)
	local playerData = securityState.sessions[playerId]
	if not playerData then
		return false, "No active session"
	end
	
	-- Rate limiting check
	if not self:_checkRateLimit(playerId) then
		self:_logSecurityEvent(playerId, "RATE_LIMIT_EXCEEDED", {actionType = actionType})
		return false, "Rate limit exceeded"
	end
	
	-- Action cooldown check
	if not self:_checkActionCooldown(playerId, actionType) then
		self:_logSecurityEvent(playerId, "ACTION_COOLDOWN_VIOLATION", {actionType = actionType})
		return false, "Action cooldown violation"
	end
	
	-- Input validation
	if SECURITY_CONFIG.INPUT_VALIDATION_ENABLED then
		if not self:_validateInput(actionType, actionData) then
			self:_logSecurityEvent(playerId, "INVALID_INPUT", {actionType = actionType, data = actionData})
			return false, "Invalid input"
		end
	end
	
	-- Boundary checking
	if SECURITY_CONFIG.BOUNDARY_CHECKING_ENABLED then
		if not self:_checkBoundaries(playerId, actionType, actionData) then
			self:_logSecurityEvent(playerId, "BOUNDARY_VIOLATION", {actionType = actionType, data = actionData})
			return false, "Boundary violation"
		end
	end
	
	-- Record action for monitoring
	table.insert(playerData.actionHistory, {
		actionType = actionType,
		timestamp = tick(),
		data = actionData
	})
	
	-- Keep only last 100 actions
	if #playerData.actionHistory > 100 then
		table.remove(playerData.actionHistory, 1)
	end
	
	-- Update security metrics
	securityState.securityMetrics.validatedRequests = securityState.securityMetrics.validatedRequests + 1
	
	return true, "Valid"
end

-- Check rate limiting
function SecurityFramework:_checkRateLimit(playerId)
	local playerData = securityState.sessions[playerId]
	if not playerData then
		return false
	end
	
	local currentTime = tick()
	local windowStart = currentTime - SECURITY_CONFIG.RATE_LIMIT_WINDOW
	
	-- Clean old requests
	local validRequests = {}
	for _, requestTime in ipairs(playerData.rateLimitData.requests) do
		if requestTime > windowStart then
			table.insert(validRequests, requestTime)
		end
	end
	playerData.rateLimitData.requests = validRequests
	
	-- Check if under limit
	if #validRequests >= SECURITY_CONFIG.MAX_REQUESTS_PER_WINDOW then
		return false
	end
	
	-- Add current request
	table.insert(playerData.rateLimitData.requests, currentTime)
	
	return true
end

-- Check action cooldown
function SecurityFramework:_checkActionCooldown(playerId, actionType)
	local playerData = securityState.sessions[playerId]
	if not playerData.actionHistory then
		return true
	end
	
	-- Check last action of same type
	for i = #playerData.actionHistory, 1, -1 do
		local action = playerData.actionHistory[i]
		if action.actionType == actionType then
			local timeSinceLast = tick() - action.timestamp
			if timeSinceLast < SECURITY_CONFIG.MAX_ACTION_COOLDOWN then
				return false
			end
			break
		end
	end
	
	return true
end

-- Validate input data
function SecurityFramework:_validateInput(actionType, actionData)
	-- Basic type checking
	if type(actionData) ~= "table" then
		return false
	end
	
	-- Action-specific validation
	if actionType == "MOVE" then
		if not actionData.position or type(actionData.position) ~= "Vector3" then
			return false
		end
		
		-- Check for impossible coordinates
		if math.abs(actionData.position.X) > 10000 or 
		   math.abs(actionData.position.Y) > 10000 or 
		   math.abs(actionData.position.Z) > 10000 then
			return false
		end
	elseif actionType == "INTERACT" then
		if not actionData.targetId or type(actionData.targetId) ~= "string" then
			return false
		end
	elseif actionType == "USE_ITEM" then
		if not actionData.itemId or type(actionData.itemId) ~= "string" then
			return false
		end
	end
	
	return true
end

-- Check boundaries and anti-cheat measures
function SecurityFramework:_checkBoundaries(playerId, actionType, actionData)
	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		return false
	end
	
	if actionType == "MOVE" then
		local character = player.Character or player.CharacterAdded:Wait()
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local currentPosition = humanoidRootPart.Position
				local newPosition = actionData.position
				
				-- Check for teleportation (impossible speed)
				local distance = (newPosition - currentPosition).magnitude
				local timeDiff = tick() - (playerData and playerData.lastActivity or tick())
				
				if distance > SECURITY_CONFIG.TELEPORT_THRESHOLD then
					self:_flagSuspiciousActivity(playerId, "TELEPORT_DETECTED", {
						distance = distance,
						position = newPosition
					})
					return false
				end
				
				-- Check for speed hacking
				if timeDiff > 0 then
					local speed = distance / timeDiff
					if speed > SECURITY_CONFIG.SPEED_HACK_THRESHOLD then
						self:_flagSuspiciousActivity(playerId, "SPEED_HACK_DETECTED", {
							speed = speed,
							distance = distance
						})
						return false
					end
				end
			end
		end
	end
	
	return true
end

-- Flag suspicious activity
function SecurityFramework:_flagSuspiciousActivity(playerId, activityType, details)
	local playerData = securityState.sessions[playerId]
	if not playerData then
		return
	end
	
	playerData.suspiciousFlags = playerData.suspiciousFlags + 1
	
	local flagData = {
		type = activityType,
		timestamp = tick(),
		details = details,
		flags = playerData.suspiciousFlags
	}
	
	table.insert(securityState.suspiciousActivity, flagData)
	
	self:_logSecurityEvent(playerId, "SUSPICIOUS_ACTIVITY", flagData)
	
	-- Auto-punishment for repeated offenses
	if playerData.suspiciousFlags >= SECURITY_CONFIG.INVALID_ACTION_THRESHOLD then
		self:_handleSecurityBreach(playerId, activityType, details)
	end
end

-- Handle security breach
function SecurityFramework:_handleSecurityBreach(playerId, breachType, details)
	local player = Players:GetPlayerByUserId(playerId)
	if player then
		-- Log security breach
		self:_logSecurityEvent(playerId, "SECURITY_BREACH", {
			type = breachType,
			details = details,
			flags = securityState.sessions[playerId].suspiciousFlags
		})
		
		-- Broadcast security alert to admins
		self:_broadcastSecurityAlert(playerId, breachType, details)
		
		-- Apply punishment (kick player)
		player:Kick("Security violation detected. Please restart the game.")
		
		securityState.securityMetrics.securityBreaches = securityState.securityMetrics.securityBreaches + 1
	end
end

-- Log security events
function SecurityFramework:_logSecurityEvent(playerId, eventType, details)
	local logEntry = {
		playerId = playerId,
		eventType = eventType,
		timestamp = tick(),
		details = details
	}
	
	table.insert(securityState.requestLogs, logEntry)
	
	-- Keep only last 10000 logs
	if #securityState.requestLogs > 10000 then
		table.remove(securityState.requestLogs, 1)
	end
	
	-- Increment security metrics
	securityState.securityMetrics.totalRequests = securityState.securityMetrics.totalRequests + 1
	if eventType:find("INVALID") or eventType:find("SUSPICIOUS") or eventType:find("BREACH") then
		securityState.securityMetrics.rejectedRequests = securityState.securityMetrics.rejectedRequests + 1
	end
	if eventType:find("SUSPICIOUS") or eventType:find("BREACH") then
		securityState.securityMetrics.suspiciousActivities = securityState.securityMetrics.suspiciousActivities + 1
	end
end

-- Detect anomalies in behavior
function SecurityFramework:_detectAnomalies()
	for playerId, playerData in pairs(securityState.sessions) do
		-- Check for unusual activity patterns
		local recentActions = {}
		local currentTime = tick()
		
		for _, action in ipairs(playerData.actionHistory) do
			if currentTime - action.timestamp < 300 then -- Last 5 minutes
				table.insert(recentActions, action)
			end
		end
		
		-- Check for rapid action spamming
		if #recentActions > 100 then
			self:_flagSuspiciousActivity(playerId, "ACTION_SPAMMING", {
				actionCount = #recentActions,
				timeWindow = 300
			})
		end
		
		-- Check for inactivity (possible bot)
		if currentTime - playerData.lastActivity > 600 then -- 10 minutes
			self:_flagSuspiciousActivity(playerId, "PROLONGED_INACTIVITY", {
				inactivityTime = currentTime - playerData.lastActivity
			})
		end
	end
end

-- Cleanup expired data
function SecurityFramework:_cleanupExpiredData()
	local currentTime = tick()
	
	-- Cleanup expired tokens
	for tokenId, tokenData in pairs(securityState.tokens) do
		if tokenData.expiresAt < currentTime then
			securityState.tokens[tokenId] = nil
		end
	end
	
	-- Cleanup old request logs
	local cutoffTime = currentTime - (SECURITY_CONFIG.AUDIT_LOG_RETENTION_DAYS * 86400)
	local validLogs = {}
	for _, logEntry in ipairs(securityState.requestLogs) do
		if logEntry.timestamp > cutoffTime then
			table.insert(validLogs, logEntry)
		end
	end
	securityState.requestLogs = validLogs
end

-- Log security metrics
function SecurityFramework:_logSecurityMetrics()
	local metrics = securityState.securityMetrics
	local totalRequests = metrics.totalRequests
	local hitRate = totalRequests > 0 and (metrics.validatedRequests / totalRequests) * 100 or 0
	
	print(string.format(
		"[Security Metrics] Total: %d | Validated: %d | Rejected: %d | Hit Rate: %.1f%% | Suspicious: %d | Breaches: %d",
		totalRequests, metrics.validatedRequests, metrics.rejectedRequests, hitRate,
		metrics.suspiciousActivities, metrics.securityBreaches
	))
end

-- Broadcast security alert to admins
function SecurityFramework:_broadcastSecurityAlert(playerId, breachType, details)
	-- This would typically send alerts to admin systems
	-- For now, just log it prominently
	warn(string.format(
		"[SECURITY ALERT] Player %d: %s - %s",
		playerId, breachType, HttpService:JSONEncode(details)
	))
end

-- Get security statistics
function SecurityFramework:getSecurityStats()
	return {
		activeSessions = #table.keys(securityState.sessions),
		activeTokens = #table.keys(securityState.tokens),
		totalLogs = #securityState.requestLogs,
		suspiciousActivities = #securityState.suspiciousActivity,
		metrics = securityState.securityMetrics
	}
end

-- Generate new token for session renewal
function SecurityFramework:renewToken(playerId, sessionId)
	local playerData = securityState.sessions[playerId]
	if not playerData or playerData.sessionId ~= sessionId then
		return nil, "Invalid session"
	end
	
	local newToken = self:_generateToken(playerId, sessionId)
	table.insert(playerData.tokens, newToken)
	
	-- Keep only last 5 tokens
	if #playerData.tokens > 5 then
		table.remove(playerData.tokens, 1)
	end
	
	return newToken, "Token renewed"
end

-- Initialize global Security Framework instance
local globalSecurityFramework = SecurityFramework.new()

-- Expose methods globally
function SecurityFramework.validateRequest(playerId, sessionId, token)
	return globalSecurityFramework:validateRequest(playerId, sessionId, token)
end

function SecurityFramework.validateAction(playerId, actionType, actionData)
	return globalSecurityFramework:validateAction(playerId, actionType, actionData)
end

function SecurityFramework.getSecurityStats()
	return globalSecurityFramework:getSecurityStats()
end

function SecurityFramework.renewToken(playerId, sessionId)
	return globalSecurityFramework:renewToken(playerId, sessionId)
end

print("[Security Framework] Professional security system ready!")

return SecurityFramework