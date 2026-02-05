-- Validation Helper
-- Provides validation functionality for the MVC framework

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Validation = {}
Validation.__index = Validation

-- Constructor
function Validation.new()
	local self = setmetatable({}, Validation)
	
	-- Validation properties
	self.Name = "Validation"
	self.Rules = {}
	
	return self
end

-- Initialize validation helper
function Validation:Initialize()
	print("[Validation] Validation helper initialized")
	self:SetupDefaultRules()
end

-- Setup default validation rules
function Validation:SetupDefaultRules()
	self.Rules = {
		required = function(value)
			return value ~= nil and value ~= ""
		end,
		
		string = function(value)
			return type(value) == "string"
		end,
		
		number = function(value)
			return type(value) == "number"
		end,
		
		boolean = function(value)
			return type(value) == "boolean"
		end,
		
		table = function(value)
			return type(value) == "table"
		end,
		
		min = function(value, min)
			if type(value) == "string" then
				return #value >= min
			elseif type(value) == "number" then
				return value >= min
			end
			return false
		end,
		
		max = function(value, max)
			if type(value) == "string" then
				return #value <= max
			elseif type(value) == "number" then
				return value <= max
			end
			return false
		end,
		
		email = function(value)
			if type(value) ~= "string" then
				return false
			end
			local emailPattern = "^[a-zA-Z0-9._%-%+]-@[a-zA-Z0-9.-]%.[a-zA-Z][a-zA-Z][a-zA-Z]*$"
			return string.match(value, emailPattern) ~= nil
		end,
		
		username = function(value)
			if type(value) ~= "string" then
				return false
			end
			local usernamePattern = "^[a-zA-Z0-9_][a-zA-Z0-9_]*$"
			return string.match(value, usernamePattern) ~= nil and #value >= 3 and #value <= 20
		end,
		
		password = function(value)
			if type(value) ~= "string" then
				return false
			end
			return #value >= 8
		end,
		
		url = function(value)
			if type(value) ~= "string" then
				return false
			end
			local urlPattern = "^https?://[a-zA-Z0-9.-]+%.[a-zA-Z][a-zA-Z][a-zA-Z]*"
			return string.match(value, urlPattern) ~= nil
		end,
		
		phone = function(value)
			if type(value) ~= "string" then
				return false
			end
			local phonePattern = "^%+[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]?$"
			return string.match(value, phonePattern) ~= nil
		end,
		
		date = function(value)
			if type(value) ~= "string" then
				return false
			end
			local datePattern = "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$"
			return string.match(value, datePattern) ~= nil
		end,
		
		time = function(value)
			if type(value) ~= "string" then
				return false
			end
			local timePattern = "^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$"
			return string.match(value, timePattern) ~= nil
		end,
		
		alphanumeric = function(value)
			if type(value) ~= "string" then
				return false
			end
			local alphaNumPattern = "^[a-zA-Z0-9]*$"
			return string.match(value, alphaNumPattern) ~= nil
		end,
		
		contains = function(value, substring)
			if type(value) ~= "string" then
				return false
			end
			return string.find(value, substring) ~= nil
		end,
		
		notContains = function(value, substring)
			if type(value) ~= "string" then
				return false
			end
			return string.find(value, substring) == nil
		end,
		
		startsWith = function(value, prefix)
			if type(value) ~= "string" then
				return false
			end
			return string.sub(value, 1, #prefix) == prefix
		end,
		
		endsWith = function(value, suffix)
			if type(value) ~= "string" then
				return false
			end
			return string.sub(value, -#suffix) == suffix
		end,
		
		between = function(value, min, max)
			if type(value) == "number" then
				return value >= min and value <= max
			elseif type(value) == "string" then
				return #value >= min and #value <= max
			end
			return false
		end,
		
		inArray = function(value, array)
			if type(array) ~= "table" then
				return false
			end
			for _, item in pairs(array) do
				if item == value then
					return true
				end
			end
			return false
		end,
		
		notInArray = function(value, array)
			return not self:inArray(value, array)
		end,
		
		unique = function(value, existingValues)
			if type(existingValues) ~= "table" then
				return true
			end
			for _, existingValue in pairs(existingValues) do
				if existingValue == value then
					return false
				end
			end
			return true
		end
	}
end

-- Validate single value
function Validation:ValidateValue(value, rules, fieldName)
	local errors = {}
	
	for ruleName, ruleValue in pairs(rules) do
		local ruleFunction = self.Rules[ruleName]
		if ruleFunction then
			local isValid = false
			
			if type(ruleValue) == "table" then
				isValid = ruleFunction(value, unpack(ruleValue))
			else
				isValid = ruleFunction(value, ruleValue)
			end
			
			if not isValid then
				table.insert(errors, self:GetErrorMessage(fieldName, ruleName, ruleValue))
			end
		end
	end
	
	return #errors == 0, errors
end

-- Validate data object
function Validation:Validate(data, rules)
	local errors = {}
	
	for fieldName, fieldRules in pairs(rules) do
		local value = data[fieldName]
		local isValid, fieldErrors = self:ValidateValue(value, fieldRules, fieldName)
		
		if not isValid then
			errors[fieldName] = fieldErrors
		end
	end
	
	return #errors == 0, errors
end

-- Get error message
function Validation:GetErrorMessage(fieldName, ruleName, ruleValue)
	local messages = {
		required = fieldName .. " is required",
		string = fieldName .. " must be a string",
		number = fieldName .. " must be a number",
		boolean = fieldName .. " must be a boolean",
		table = fieldName .. " must be a table",
		min = fieldName .. " must be at least " .. ruleValue .. " characters",
		max = fieldName .. " must be at most " .. ruleValue .. " characters",
		email = fieldName .. " must be a valid email address",
		username = fieldName .. " must be a valid username (3-20 characters, alphanumeric and underscores only)",
		password = fieldName .. " must be at least 8 characters long",
		url = fieldName .. " must be a valid URL",
		phone = fieldName .. " must be a valid phone number",
		date = fieldName .. " must be a valid date (YYYY-MM-DD format)",
		time = fieldName .. " must be a valid time (HH:MM:SS format)",
		alphanumeric = fieldName .. " must contain only alphanumeric characters",
		contains = fieldName .. " must contain " .. ruleValue,
		notContains = fieldName .. " must not contain " .. ruleValue,
		startsWith = fieldName .. " must start with " .. ruleValue,
		endsWith = fieldName .. " must end with " .. ruleValue,
		between = fieldName .. " must be between " .. ruleValue[1] .. " and " .. ruleValue[2],
		inArray = fieldName .. " must be one of the allowed values",
		notInArray = fieldName .. " must not be one of the forbidden values",
		unique = fieldName .. " must be unique"
	}
	
	return messages[ruleName] or fieldName .. " failed validation"
end

-- Add custom validation rule
function Validation:AddRule(name, ruleFunction)
	self.Rules[name] = ruleFunction
	print("[Validation] Added custom rule: " .. name)
end

-- Remove validation rule
function Validation:RemoveRule(name)
	if self.Rules[name] then
		self.Rules[name] = nil
		print("[Validation] Removed rule: " .. name)
	end
end

-- Check if rule exists
function Validation:HasRule(name)
	return self.Rules[name] ~= nil
end

-- Get all rules
function Validation:GetRules()
	return self.Rules
end

-- Validate email format
function Validation:IsEmail(value)
	return self:ValidateValue(value, { email = true }, "email")
end

-- Validate username format
function Validation:IsUsername(value)
	return self:ValidateValue(value, { username = true }, "username")
end

-- Validate password strength
function Validation:IsStrongPassword(value)
	local rules = {
		min = 8,
		contains = { "[a-z]" }, -- lowercase
		contains = { "[A-Z]" }, -- uppercase
		contains = { "[0-9]" }  -- number
	}
	return self:ValidateValue(value, rules, "password")
end

-- Validate phone number
function Validation:IsPhoneNumber(value)
	return self:ValidateValue(value, { phone = true }, "phone")
end

-- Validate URL
function Validation:IsUrl(value)
	return self:ValidateValue(value, { url = true }, "url")
end

-- Validate date format
function Validation:IsDate(value)
	return self:ValidateValue(value, { date = true }, "date")
end

-- Validate time format
function Validation:IsTime(value)
	return self:ValidateValue(value, { time = true }, "time")
end

-- Validate alphanumeric
function Validation:IsAlphanumeric(value)
	return self:ValidateValue(value, { alphanumeric = true }, "value")
end

-- Validate in range
function Validation:IsInRange(value, min, max)
	return self:ValidateValue(value, { between = { min, max } }, "value")
end

-- Validate array contains value
function Validation:Contains(array, value)
	return self:ValidateValue(value, { inArray = array }, "value")
end

-- Validate array does not contain value
function Validation:NotContains(array, value)
	return self:ValidateValue(value, { notInArray = array }, "value")
end

-- Sanitize string input
function Validation:SanitizeString(input)
	if type(input) ~= "string" then
		return ""
	end
	
	-- Remove potentially dangerous characters
	input = string.gsub(input, "[<>\"'%;]", "")
	input = string.gsub(input, "\\", "")
	input = string.gsub(input, "\n", " ")
	input = string.gsub(input, "\r", " ")
	input = string.gsub(input, "\t", " ")
	
	-- Trim whitespace
	input = string.gsub(input, "^%s+", "")
	input = string.gsub(input, "%s+$", "")
	
	return input
end

-- Sanitize number input
function Validation:SanitizeNumber(input)
	if type(input) == "number" then
		return input
	end
	
	if type(input) == "string" then
		local number = tonumber(input)
		if number then
			return number
		end
	end
	
	return 0
end

-- Sanitize boolean input
function Validation:SanitizeBoolean(input)
	if type(input) == "boolean" then
		return input
	end
	
	if type(input) == "string" then
		input = string.lower(input)
		if input == "true" or input == "1" or input == "yes" then
			return true
		elseif input == "false" or input == "0" or input == "no" then
			return false
		end
	end
	
	if type(input) == "number" then
		return input ~= 0
	end
	
	return false
end

return Validation