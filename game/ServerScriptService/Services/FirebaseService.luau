--[[
    FirebaseService.luau (v3.3 - FINAL, VERIFIED Path Fix)

    - Corrects the `require` path for the Promise library using a verified file location.
    - The module is located at `ReplicatedStorage.Shared.Promise`.
    - This resolves the startup crash caused by incorrect path assumptions.
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- Get service

-- Core Dependencies
local Config = require(ServerScriptService.Config)
local Promise = require(ReplicatedStorage.Shared.Promise) -- VERIFIED & FIXED PATH

local FirebaseService = {}

--======================================================================
--=                              INTERNAL                              =
--======================================================================

local FIREBASE_URL
local AUTH_SECRET

local function Log(m)
	print(string.format("🔥 [FirebaseService v3.3] %s", m))
end

local function initializeCredentials()
    if RunService:IsStudio() then
        FIREBASE_URL = Config.Studio.FIREBASE_URL
        AUTH_SECRET = Config.Studio.FIREBASE_SECRET
    else
        Log("Using Studio credentials as a fallback in a non-Studio environment.")
        FIREBASE_URL = Config.Studio.FIREBASE_URL
        AUTH_SECRET = Config.Studio.FIREBASE_SECRET
    end

    if not FIREBASE_URL or not AUTH_SECRET then
        error("[FirebaseService] CRITICAL: Could not load Firebase URL or Auth Secret.")
    end
end

-- Constructs the final, authenticated URL for any given path.
local function buildUrl(path)
    if not path:match("^/") then 
        path = "/" .. path 
    end
	return string.format("%s%s.json?auth=%s", FIREBASE_URL, path, AUTH_SECRET)
end

--======================================================================
--=                          PUBLIC API (Promise-based)                =
--======================================================================

function FirebaseService:GetAsync(path)
    return Promise.new(function(resolve, reject)
        local url = buildUrl(path)
        
        local success, result = pcall(function() 
            return HttpService:GetAsync(url)
        end)

        if not success then
            Log(string.format("HTTP GET request FAILED for path '%s': %s", path, tostring(result)))
            return reject(result)
        end
        
        if result == "null" then
            Log(string.format("No data found at path: %s", path))
            return resolve(nil)
        end
        
        local dataSuccess, decodedData = pcall(function()
            return HttpService:JSONDecode(result)
        end)

        if not dataSuccess then
            Log(string.format("JSON Decode FAILED for path '%s'. Error: %s", path, tostring(decodedData)))
            return reject("JSON Decode Error")
        end

        return resolve(decodedData)
    end)
end

function FirebaseService:SetAsync(path, data)
    return Promise.new(function(resolve, reject)
        local url = buildUrl(path)
        local json_data

        local json_success, json_err = pcall(function()
            json_data = HttpService:JSONEncode(data)
        end)

        if not json_success then
            Log(string.format("Failed to encode data to JSON for path '%s': %s", path, json_err))
            return reject("JSON Encode Error")
        end

        local success, result = pcall(function() 
            HttpService:RequestAsync({
                Url = url,
                Method = "PUT",
                Headers = {["Content-Type"] = "application/json"},
                Body = json_data
            })
        end)

        if not success then
            Log(string.format("HTTP PUT request FAILED for path '%s': %s", path, tostring(result)))
            return reject(result)
        end
        
        Log(string.format("Successfully set data at path: %s", path))
        return resolve(true)
    end)
end

--======================================================================
--=                         INITIALIZATION                           =
--======================================================================

initializeCredentials()

return FirebaseService
