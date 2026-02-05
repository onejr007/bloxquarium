-- Base Model Class
-- Provides common functionality for all models

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseModel = {}
BaseModel.__index = BaseModel

-- Constructor
function BaseModel.new()
	local self = setmetatable({}, BaseModel)
	
	-- Model properties
	self.Name = "BaseModel"
	self.Table = nil
	self.PrimaryKey = "id"
	self.AutoIncrement = true
	self.Fields = {}
	
	return self
end

-- Initialize model
function BaseModel:Initialize()
	print("[Model] " .. self.Name .. " initialized")
	self:CreateTable()
end

-- Create database table
function BaseModel:CreateTable()
	if not self.Table then
		self.Table = {}
		print("[Model] Table created for " .. self.Name)
	end
end

-- Get all records
function BaseModel:All()
	return self.Table
end

-- Find record by ID
function BaseModel:Find(id)
	for _, record in pairs(self.Table) do
		if record[self.PrimaryKey] == id then
			return record
		end
	end
	return nil
end

-- Find records by conditions
function BaseModel:Where(conditions)
	local results = {}
	
	for _, record in pairs(self.Table) do
		local matches = true
		for key, value in pairs(conditions) do
			if record[key] ~= value then
				matches = false
				break
			end
		end
		if matches then
			table.insert(results, record)
		end
	end
	
	return results
end

-- Create new record
function BaseModel:Create(data)
	local record = {}
	
	-- Set default values
	for field, defaultValue in pairs(self.Fields) do
		record[field] = data[field] or defaultValue
	end
	
	-- Set primary key
	if self.AutoIncrement then
		record[self.PrimaryKey] = #self.Table + 1
	else
		record[self.PrimaryKey] = data[self.PrimaryKey]
	end
	
	-- Add to table
	table.insert(self.Table, record)
	
	return record
end

-- Update record
function BaseModel:Update(id, data)
	local record = self:Find(id)
	if record then
		for key, value in pairs(data) do
			if self.Fields[key] ~= nil then
				record[key] = value
			end
		end
		return record
	end
	return nil
end

-- Delete record
function BaseModel:Delete(id)
	for i, record in pairs(self.Table) do
		if record[self.PrimaryKey] == id then
			table.remove(self.Table, i)
			return true
		end
	end
	return false
end

-- Count records
function BaseModel:Count()
	return #self.Table
end

-- Get first record
function BaseModel:First()
	if #self.Table > 0 then
		return self.Table[1]
	end
	return nil
end

-- Get last record
function BaseModel:Last()
	if #self.Table > 0 then
		return self.Table[#self.Table]
	end
	return nil
end

-- Validate data
function BaseModel:Validate(data)
	local errors = {}
	
	for field, rules in pairs(self.Fields) do
		if data[field] == nil and rules.required then
			table.insert(errors, field .. " is required")
		elseif data[field] ~= nil then
			if rules.type == "string" and type(data[field]) ~= "string" then
				table.insert(errors, field .. " must be a string")
			elseif rules.type == "number" and type(data[field]) ~= "number" then
				table.insert(errors, field .. " must be a number")
			elseif rules.min and #tostring(data[field]) < rules.min then
				table.insert(errors, field .. " must be at least " .. rules.min .. " characters")
			elseif rules.max and #tostring(data[field]) > rules.max then
				table.insert(errors, field .. " must be at most " .. rules.max .. " characters")
			end
		end
	end
	
	return #errors == 0, errors
end

-- Save record (create or update)
function BaseModel:Save(data)
	if data[self.PrimaryKey] then
		return self:Update(data[self.PrimaryKey], data)
	else
		return self:Create(data)
	end
end

-- Get field names
function BaseModel:GetFields()
	local fields = {}
	for field in pairs(self.Fields) do
		table.insert(fields, field)
	end
	return fields
end

-- Get field value
function BaseModel:GetFieldValue(record, field)
	return record[field]
end

-- Set field value
function BaseModel:SetFieldValue(record, field, value)
	if self.Fields[field] ~= nil then
		record[field] = value
		return true
	end
	return false
end

-- Get primary key value
function BaseModel:GetPrimaryKeyValue(record)
	return record[self.PrimaryKey]
end

-- Set primary key value
function BaseModel:SetPrimaryKeyValue(record, value)
	record[self.PrimaryKey] = value
end

-- Clone record
function BaseModel:Clone(record)
	local clone = {}
	for key, value in pairs(record) do
		clone[key] = value
	end
	return clone
end

-- Export record to JSON
function BaseModel:ToJson(record)
	local json = {}
	for key, value in pairs(record) do
		json[key] = value
	end
	return game:GetService("HttpService"):JSONEncode(json)
end

-- Import record from JSON
function BaseModel:FromJson(jsonString)
	local json = game:GetService("HttpService"):JSONDecode(jsonString)
	return json
end

return BaseModel