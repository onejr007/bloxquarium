-- Database Library
-- Provides database functionality for the MVC framework

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Database = {}
Database.__index = Database

-- Constructor
function Database.new()
	local self = setmetatable({}, Database)
	
	-- Database properties
	self.Name = "Database"
	self.Connections = {}
	self.Tables = {}
	self.Backups = {}
	
	return self
end

-- Initialize database
function Database:Initialize()
	print("[Database] Database initialized")
	self:CreateSystemTables()
end

-- Create system tables
function Database:CreateSystemTables()
	-- Users table
	self.Tables.Users = {
		Fields = {
			id = { type = "number", required = true, autoIncrement = true },
			username = { type = "string", required = true, unique = true },
			email = { type = "string", required = true, unique = true },
			password = { type = "string", required = true },
			createdAt = { type = "number", required = true },
			updatedAt = { type = "number", required = true }
		},
		Data = {}
	}
	
	-- Sessions table
	self.Tables.Sessions = {
		Fields = {
			id = { type = "string", required = true },
			userId = { type = "number", required = true },
			expiresAt = { type = "number", required = true },
			createdAt = { type = "number", required = true }
		},
		Data = {}
	}
	
	-- Logs table
	self.Tables.Logs = {
		Fields = {
			id = { type = "number", required = true, autoIncrement = true },
			level = { type = "string", required = true },
			message = { type = "string", required = true },
			timestamp = { type = "number", required = true },
			source = { type = "string", required = false }
		},
		Data = {}
	}
	
	print("[Database] System tables created")
end

-- Create custom table
function Database:CreateTable(tableName, fields)
	if self.Tables[tableName] then
		return false, "Table already exists"
	end
	
	self.Tables[tableName] = {
		Fields = fields,
		Data = {}
	}
	
	return true, "Table created successfully"
end

-- Insert record
function Database:Insert(tableName, data)
	local tableDef = self.Tables[tableName]
	if not tableDef then
		return nil, "Table not found"
	end
	
	-- Validate data
	local validatedData = {}
	for fieldName, fieldDef in pairs(tableDef.Fields) do
		if fieldDef.required and not data[fieldName] then
			return nil, "Missing required field: " .. fieldName
		end
		
		if data[fieldName] then
			if fieldDef.type == "string" and type(data[fieldName]) ~= "string" then
				return nil, "Invalid type for field: " .. fieldName
			elseif fieldDef.type == "number" and type(data[fieldName]) ~= "number" then
				return nil, "Invalid type for field: " .. fieldName
			end
			
			validatedData[fieldName] = data[fieldName]
		elseif fieldDef.default then
			validatedData[fieldName] = fieldDef.default
		end
		
		-- Handle auto-increment
		if fieldDef.autoIncrement then
			validatedData[fieldName] = #tableDef.Data + 1
		end
	end
	
	-- Check unique constraints
	for fieldName, value in pairs(validatedData) do
		local fieldDef = tableDef.Fields[fieldName]
		if fieldDef and fieldDef.unique then
			for _, existingRecord in pairs(tableDef.Data) do
				if existingRecord[fieldName] == value then
					return nil, "Duplicate value for unique field: " .. fieldName
				end
			end
		end
	end
	
	-- Insert record
	table.insert(tableDef.Data, validatedData)
	return validatedData
end

-- Select records
function Database:Select(tableName, conditions, options)
	local tableDef = self.Tables[tableName]
	if not tableDef then
		return nil, "Table not found"
	end
	
	local results = {}
	
	-- Filter records
	for _, record in pairs(tableDef.Data) do
		local matches = true
		
		if conditions then
			for field, value in pairs(conditions) do
				if record[field] ~= value then
					matches = false
					break
				end
			end
		end
		
		if matches then
			table.insert(results, record)
		end
	end
	
	-- Apply options
	if options then
		if options.limit then
			local limitedResults = {}
			for i = 1, math.min(options.limit, #results) do
				table.insert(limitedResults, results[i])
			end
			results = limitedResults
		end
		
		if options.orderBy then
			table.sort(results, function(a, b)
				if options.orderDirection == "DESC" then
					return a[options.orderBy] > b[options.orderBy]
				else
					return a[options.orderBy] < b[options.orderBy]
				end
			end)
		end
	end
	
	return results
end

-- Update records
function Database:Update(tableName, conditions, data)
	local tableDef = self.Tables[tableName]
	if not tableDef then
		return 0, "Table not found"
	end
	
	local updatedCount = 0
	
	for _, record in pairs(tableDef.Data) do
		local matches = true
		
		if conditions then
			for field, value in pairs(conditions) do
				if record[field] ~= value then
					matches = false
					break
				end
			end
		end
		
		if matches then
			for field, value in pairs(data) do
				if tableDef.Fields[field] then
					record[field] = value
				end
			end
			updatedCount = updatedCount + 1
		end
	end
	
	return updatedCount
end

-- Delete records
function Database:Delete(tableName, conditions)
	local tableDef = self.Tables[tableName]
	if not tableDef then
		return 0, "Table not found"
	end
	
	local deletedCount = 0
	local remainingRecords = {}
	
	for _, record in pairs(tableDef.Data) do
		local matches = true
		
		if conditions then
			for field, value in pairs(conditions) do
				if record[field] ~= value then
					matches = false
					break
				end
			end
		end
		
		if matches then
			deletedCount = deletedCount + 1
		else
			table.insert(remainingRecords, record)
		end
	end
	
	tableDef.Data = remainingRecords
	return deletedCount
end

-- Count records
function Database:Count(tableName, conditions)
	local results, error = self:Select(tableName, conditions)
	if error then
		return 0, error
	end
	return #results
end

-- Find record by ID
function Database:Find(tableName, id)
	local results, error = self:Select(tableName, { id = id })
	if error then
		return nil, error
	end
	return results[1]
end

-- Get table schema
function Database:GetSchema(tableName)
	local tableDef = self.Tables[tableName]
	if not tableDef then
		return nil, "Table not found"
	end
	return tableDef.Fields
end

-- Get all table names
function Database:GetTableNames()
	local tableNames = {}
	for tableName in pairs(self.Tables) do
		table.insert(tableNames, tableName)
	end
	return tableNames
end

-- Backup database
function Database:Backup(name)
	local backup = {
		name = name or "backup_" .. os.time(),
		timestamp = os.time(),
		tables = {}
	}
	
	for tableName, tableDef in pairs(self.Tables) do
		backup.tables[tableName] = {
			fields = tableDef.Fields,
			data = tableDef.Data
		}
	end
	
	table.insert(self.Backups, backup)
	return backup
end

-- Restore database from backup
function Database:Restore(backupName)
	local backup = nil
	for _, b in pairs(self.Backups) do
		if b.name == backupName then
			backup = b
			break
		end
	end
	
	if not backup then
		return false, "Backup not found"
	end
	
	-- Clear current data
	self.Tables = {}
	
	-- Restore from backup
	for tableName, tableData in pairs(backup.tables) do
		self.Tables[tableName] = {
			Fields = tableData.fields,
			Data = tableData.data
		}
	end
	
	return true, "Database restored successfully"
end

-- Get backup list
function Database:GetBackups()
	return self.Backups
end

-- Clear table data
function Database:Truncate(tableName)
	local tableDef = self.Tables[tableName]
	if not tableDef then
		return false, "Table not found"
	end
	
	tableDef.Data = {}
	return true, "Table truncated successfully"
end

-- Drop table
function Database:DropTable(tableName)
	if not self.Tables[tableName] then
		return false, "Table not found"
	end
	
	self.Tables[tableName] = nil
	return true, "Table dropped successfully"
end

-- Add index (for future optimization)
function Database:AddIndex(tableName, fieldName)
	local tableDef = self.Tables[tableName]
	if not tableDef then
		return false, "Table not found"
	end
	
	if not tableDef.Fields[fieldName] then
		return false, "Field not found"
	end
	
	-- Mark field for indexing (placeholder for future implementation)
	tableDef.Fields[fieldName].indexed = true
	return true, "Index added successfully"
end

-- Log database operation
function Database:Log(level, message, source)
	local logData = {
		level = level,
		message = message,
		timestamp = os.time(),
		source = source or "Database"
	}
	
	self:Insert("Logs", logData)
end

-- Get database statistics
function Database:GetStatistics()
	local stats = {
		tableCount = #self.Tables,
		totalRecords = 0,
		tableSizes = {}
	}
	
	for tableName, tableDef in pairs(self.Tables) do
		local recordCount = #tableDef.Data
		stats.totalRecords = stats.totalRecords + recordCount
		stats.tableSizes[tableName] = recordCount
	end
	
	return stats
end

return Database