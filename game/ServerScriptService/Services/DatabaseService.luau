--[[
    DatabaseService.luau (v1.2 - STABLE & CORRECT)

    - RESTORED: This is the correct, stable version of the database service.
    - It correctly returns two values: a `success` boolean and the `result` (data or error).
    - This is the reliable foundation that the rest of the server code will depend on.
]]

local DataStoreService = game:GetService("DataStoreService")
local MainDataStore = DataStoreService:GetDataStore("BloxquariumData")

local DatabaseService = {}

function DatabaseService.Create(key, value)
    local success, err = pcall(function()
        MainDataStore:SetAsync(key, value)
    end)
    return success, err
end

function DatabaseService.Read(key)
    -- This is the correct implementation. It returns two values.
    local success, result = pcall(function()
        return MainDataStore:GetAsync(key)
    end)
    return success, result
end

function DatabaseService.Update(key, value)
    local success, err = pcall(function()
        MainDataStore:SetAsync(key, value)
    end)
    return success, err
end

function DatabaseService.Delete(key)
    local success, err = pcall(function()
        MainDataStore:RemoveAsync(key)
    end)
    return success, err
end

return DatabaseService
