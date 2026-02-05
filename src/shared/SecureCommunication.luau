-- Secure Communication Framework v1.0
-- Professional dual-bridge communication system with encryption,
-- request validation, and comprehensive security measures
-- Ensures all client-server communication passes through secure bridges

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SecurityFramework = require(ReplicatedStorage.Shared.SecurityFramework)
local HttpService = game:GetService("HttpService")

local SecureCommunication = {}
SecureCommunication.__index = SecureCommunication

-- Communication configuration
local COMMUNICATION_CONFIG = {
	ENCRYPTION_ENABLED = true,
	VALIDATION_ENABLED = true,
	AUDIT_LOGGING_ENABLED = true,
	MAX_MESSAGE_SIZE = 10240, -- 10KB
	MESSAGE_TIMEOUT = 30, -- 30 seconds
	RETRY_ATTEMPTS = 3,
	RETRY_DELAY = 1 -- 1 second
}

-- Communication state
local communicationState = {
	bridges = {
		client = {},
		server = {}
	},
	messageQueue = {},
	securityLog = {},
	sequenceNumbers = {}
}

-- Initialize the Secure Communication Framework
function SecureCommunication.new()
	local self = setmetatable({}, SecureCommunication)
	
	-- Setup secure bridges
	self:_setupSecureBridges()
	
	-- Initialize message processing
	self:_initializeMessageProcessing()
	
	print("[Secure Communication] Initialized with dual-bridge security system")
	
	return self
end

-- Setup secure client and server bridges
function SecureCommunication:_setupSecureBridges()
	-- Create secure client bridge
	local clientBridge = Instance.new("RemoteEvent")
	clientBridge.Name = "SecureClientBridge"
	clientBridge.Parent = ReplicatedStorage
	
	-- Create secure server bridge
	local serverBridge = Instance.new("RemoteEvent")
	serverBridge.Name = "SecureServerBridge"
	serverBridge.Parent = ReplicatedStorage
	
	-- Setup bridge handlers
	clientBridge.OnServerEvent:Connect(function(player, encryptedMessage)
		self:_handleSecureClientMessage(player, encryptedMessage)
	end)
	
	serverBridge.OnClientEvent:Connect(function(encryptedMessage)
		self:_handleSecureServerMessage(encryptedMessage)
	end)
	
	-- Store bridge references
	communicationState.bridges.client = clientBridge
	communicationState.bridges.server = serverBridge
	
	print("[Secure Communication] Dual-bridge system established")
end

-- Initialize message processing system
function SecureCommunication:_initializeMessageProcessing()
	-- Process message queue
	spawn(function()
		while true do
			task.wait(0.1) -- Process every 100ms
			self:_processMessageQueue()
		end
	end)
	
	-- Cleanup old logs
	spawn(function()
		while true do
			task.wait(300) -- Cleanup every 5 minutes
			self:_cleanupOldLogs()
		end
	end)
end

-- Send secure message from client to server
function SecureCommunication:sendToServer(playerId, sessionId, token, actionType, actionData)
	-- Validate request first
	local isValid, message = SecurityFramework.validateRequest(playerId, sessionId, token)
	if not isValid then
		self:_logSecurityEvent(playerId, "CLIENT_TO_SERVER_REJECTED", {
			reason = message,
			actionType = actionType
		})
		return false, "Request validation failed"
	end
	
	-- Validate action
	isValid, message = SecurityFramework.validateAction(playerId, actionType, actionData)
	if not isValid then
		self:_logSecurityEvent(playerId, "ACTION_VALIDATION_FAILED", {
			reason = message,
			actionType = actionType
		})
		return false, "Action validation failed"
	end
	
	-- Create secure message
	local message = self:_createSecureMessage(playerId, sessionId, token, actionType, actionData)
	
	-- Encrypt message
	local encryptedMessage = self:_encryptMessage(message)
	
	-- Send through client bridge
	local clientBridge = communicationState.bridges.client
	if clientBridge then
		clientBridge:FireServer(encryptedMessage)
		self:_logCommunicationEvent(playerId, "CLIENT_TO_SERVER_SENT", {
			actionType = actionType,
			messageSize = #HttpService:JSONEncode(message)
		})
		return true, "Message sent"
	else
		return false, "Bridge not available"
	end
end

-- Send secure message from server to client
function SecureCommunication:sendToClient(player, actionType, actionData)
	-- Create secure message
	local message = self:_createSecureServerMessage(actionType, actionData)
	
	-- Encrypt message
	local encryptedMessage = self:_encryptMessage(message)
	
	-- Send through server bridge
	local serverBridge = communicationState.bridges.server
	if serverBridge then
		serverBridge:FireClient(player, encryptedMessage)
		self:_logCommunicationEvent(player.UserId, "SERVER_TO_CLIENT_SENT", {
			actionType = actionType,
			messageSize = #HttpService:JSONEncode(message)
		})
		return true, "Message sent"
	else
		return false, "Bridge not available"
	end
end

-- Handle secure client message
function SecureCommunication:_handleSecureClientMessage(player, encryptedMessage)
	local playerId = player.UserId
	
	-- Decrypt message
	local message = self:_decryptMessage(encryptedMessage)
	if not message then
		self:_logSecurityEvent(playerId, "DECRYPTION_FAILED", {})
		return false, "Message decryption failed"
	end
	
	-- Validate message structure
	if not self:_validateMessageStructure(message) then
		self:_logSecurityEvent(playerId, "INVALID_MESSAGE_STRUCTURE", {})
		return false, "Invalid message structure"
	end
	
	-- Validate message integrity
	if not self:_validateMessageIntegrity(message) then
		self:_logSecurityEvent(playerId, "MESSAGE_INTEGRITY_VIOLATION", {})
		return false, "Message integrity violation"
	end
	
	-- Extract message data
	local sessionId = message.sessionId
	local token = message.token
	local actionType = message.actionType
	local actionData = message.actionData
	local timestamp = message.timestamp
	local sequenceNumber = message.sequenceNumber
	
	-- Validate session and token
	local isValid, validationMessage = SecurityFramework.validateRequest(playerId, sessionId, token)
	if not isValid then
		self:_logSecurityEvent(playerId, "SESSION_VALIDATION_FAILED", {
			reason = validationMessage
		})
		return false, "Session validation failed"
	end
	
	-- Validate action
	isValid, validationMessage = SecurityFramework.validateAction(playerId, actionType, actionData)
	if not isValid then
		self:_logSecurityEvent(playerId, "ACTION_VALIDATION_FAILED", {
			reason = validationMessage,
			actionType = actionType
		})
		return false, "Action validation failed"
	end
	
	-- Check sequence number for replay attack prevention
	if not self:_validateSequenceNumber(playerId, sequenceNumber) then
		self:_logSecurityEvent(playerId, "REPLAY_ATTACK_DETECTED", {
			sequenceNumber = sequenceNumber
		})
		return false, "Replay attack detected"
	end
	
	-- Log successful message processing
	self:_logCommunicationEvent(playerId, "CLIENT_TO_SERVER_PROCESSED", {
		actionType = actionType,
		timestamp = timestamp
	})
	
	-- Return processed message data
	return true, {
		playerId = playerId,
		sessionId = sessionId,
		token = token,
		actionType = actionType,
		actionData = actionData,
		timestamp = timestamp
	}
end

-- Handle secure server message
function SecureCommunication:_handleSecureServerMessage(encryptedMessage)
	-- This would be called on the client side
	-- For now, we'll return the decrypted message
	local message = self:_decryptMessage(encryptedMessage)
	return message
end

-- Create secure client message
function SecureCommunication:_createSecureMessage(playerId, sessionId, token, actionType, actionData)
	local message = {
		playerId = playerId,
		sessionId = sessionId,
		token = token,
		actionType = actionType,
		actionData = actionData,
		timestamp = tick(),
		sequenceNumber = self:_generateSequenceNumber(playerId),
		messageType = "CLIENT_TO_SERVER",
		checksum = nil -- Will be calculated
	}
	
	-- Calculate checksum
	message.checksum = self:_calculateChecksum(message)
	
	return message
end

-- Create secure server message
function SecureCommunication:_createSecureServerMessage(actionType, actionData)
	local message = {
		actionType = actionType,
		actionData = actionData,
		timestamp = tick(),
		messageType = "SERVER_TO_CLIENT",
		checksum = nil -- Will be calculated
	}
	
	-- Calculate checksum
	message.checksum = self:_calculateChecksum(message)
	
	return message
end

-- Encrypt message
function SecureCommunication:_encryptMessage(message)
	if not COMMUNICATION_CONFIG.ENCRYPTION_ENABLED then
		return message
	end
	
	-- Convert to JSON string
	local jsonString = HttpService:JSONEncode(message)
	
	-- Simple encryption (in production, use proper encryption)
	-- This is a placeholder - in real implementation, use proper crypto
	local encrypted = ""
	for i = 1, #jsonString do
		local char = string.byte(jsonString:sub(i, i))
		encrypted = encrypted .. string.char(char + 1) -- Simple Caesar cipher
	end
	
	return encrypted
end

-- Decrypt message
function SecureCommunication:_decryptMessage(encryptedMessage)
	if not COMMUNICATION_CONFIG.ENCRYPTION_ENABLED then
		return encryptedMessage
	end
	
	-- Simple decryption (reverse of encryption)
	local decrypted = ""
	for i = 1, #encryptedMessage do
		local char = string.byte(encryptedMessage:sub(i, i))
		decrypted = decrypted .. string.char(char - 1) -- Reverse Caesar cipher
	end
	
	-- Convert back to table
	local success, result = pcall(function()
		return HttpService:JSONDecode(decrypted)
	end)
	
	if success then
		return result
	else
		return nil
	end
end

-- Validate message structure
function SecureCommunication:_validateMessageStructure(message)
	if type(message) ~= "table" then
		return false
	end
	
	-- Check required fields for client messages
	if message.messageType == "CLIENT_TO_SERVER" then
		local requiredFields = {"playerId", "sessionId", "token", "actionType", "timestamp", "sequenceNumber", "checksum"}
		for _, field in ipairs(requiredFields) do
			if message[field] == nil then
				return false
			end
		end
	elseif message.messageType == "SERVER_TO_CLIENT" then
		local requiredFields = {"actionType", "timestamp", "checksum"}
		for _, field in ipairs(requiredFields) do
			if message[field] == nil then
				return false
			end
		end
	end
	
	return true
end

-- Validate message integrity using checksum
function SecureCommunication:_validateMessageIntegrity(message)
	local originalChecksum = message.checksum
	message.checksum = nil -- Remove checksum for calculation
	
	local calculatedChecksum = self:_calculateChecksum(message)
	message.checksum = originalChecksum -- Restore checksum
	
	return originalChecksum == calculatedChecksum
end

-- Calculate message checksum
function SecureCommunication:_calculateChecksum(message)
	local jsonString = HttpService:JSONEncode(message)
	local checksum = 0
	
	for i = 1, #jsonString do
		checksum = checksum + string.byte(jsonString:sub(i, i))
	end
	
	return checksum % 65536 -- 16-bit checksum
end

-- Generate sequence number for replay attack prevention
function SecureCommunication:_generateSequenceNumber(playerId)
	if not communicationState.sequenceNumbers[playerId] then
		communicationState.sequenceNumbers[playerId] = 0
	end
	
	communicationState.sequenceNumbers[playerId] = communicationState.sequenceNumbers[playerId] + 1
	return communicationState.sequenceNumbers[playerId]
end

-- Validate sequence number
function SecureCommunication:_validateSequenceNumber(playerId, sequenceNumber)
	local currentSequence = communicationState.sequenceNumbers[playerId] or 0
	
	-- Allow some tolerance for network delays (up to 100 sequence numbers ahead)
	if sequenceNumber > currentSequence + 100 then
		return false
	end
	
	-- Update sequence number if valid
	if sequenceNumber > currentSequence then
		communicationState.sequenceNumbers[playerId] = sequenceNumber
		return true
	else
		return false
	end
end

-- Process message queue
function SecureCommunication:_processMessageQueue()
	-- Process queued messages
	for i = #communicationState.messageQueue, 1, -1 do
		local message = communicationState.messageQueue[i]
		if message.timestamp < tick() - COMMUNICATION_CONFIG.MESSAGE_TIMEOUT then
			-- Remove expired messages
			table.remove(communicationState.messageQueue, i)
		end
	end
end

-- Log security events
function SecureCommunication:_logSecurityEvent(playerId, eventType, details)
	local logEntry = {
		playerId = playerId,
		eventType = eventType,
		timestamp = tick(),
		details = details,
		eventSource = "SECURE_COMMUNICATION"
	}
	
	table.insert(communicationState.securityLog, logEntry)
	
	-- Keep only last 1000 logs
	if #communicationState.securityLog > 1000 then
		table.remove(communicationState.securityLog, 1)
	end
	
	-- Also log to SecurityFramework
	SecurityFramework._logSecurityEvent(playerId, eventType, details)
end

-- Log communication events
function SecureCommunication:_logCommunicationEvent(playerId, eventType, details)
	if not COMMUNICATION_CONFIG.AUDIT_LOGGING_ENABLED then
		return
	end
	
	local logEntry = {
		playerId = playerId,
		eventType = eventType,
		timestamp = tick(),
		details = details,
		eventSource = "SECURE_COMMUNICATION"
	}
	
	table.insert(communicationState.securityLog, logEntry)
	
	-- Keep only last 1000 logs
	if #communicationState.securityLog > 1000 then
		table.remove(communicationState.securityLog, 1)
	end
end

-- Cleanup old logs
function SecureCommunication:_cleanupOldLogs()
	local cutoffTime = tick() - 86400 -- 24 hours
	local validLogs = {}
	
	for _, logEntry in ipairs(communicationState.securityLog) do
		if logEntry.timestamp > cutoffTime then
			table.insert(validLogs, logEntry)
		end
	end
	
	communicationState.securityLog = validLogs
end

-- Get communication statistics
function SecureCommunication:getCommunicationStats()
	return {
		activeBridges = #table.keys(communicationState.bridges),
		messageQueueSize = #communicationState.messageQueue,
		logEntries = #communicationState.securityLog,
		sequenceNumbers = #table.keys(communicationState.sequenceNumbers)
	}
end

-- Initialize global Secure Communication instance
local globalSecureCommunication = SecureCommunication.new()

-- Expose methods globally
function SecureCommunication.sendToServer(playerId, sessionId, token, actionType, actionData)
	return globalSecureCommunication:sendToServer(playerId, sessionId, token, actionType, actionData)
end

function SecureCommunication.sendToClient(player, actionType, actionData)
	return globalSecureCommunication:sendToClient(player, actionType, actionData)
end

function SecureCommunication.getCommunicationStats()
	return globalSecureCommunication:getCommunicationStats()
end

print("[Secure Communication] Professional dual-bridge system ready!")

return SecureCommunication