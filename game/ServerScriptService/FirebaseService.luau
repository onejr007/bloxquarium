--[[
    FirebaseService.luau (v2.1 - EXTENSIVE DEBUGGING)

    - This version adds significant debugging output to the `GetPlayerDataAsync` function.
    - It will now log the exact URL being requested and the full, raw response from the Firebase server.
    - This is intended to definitively diagnose the data loading issue.
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Core Dependencies
local Config = require(ServerScriptService.Config)
-- local SecretService -- Uncomment when in Production

local FirebaseService = {}

--======================================================================
--=                              INTERNAL                              =
--======================================================================

local FIREBASE_URL
local AUTH_SECRET

local function Log(m)
	print(string.format("🔥 [FirebaseService v2.1] %s", m))
end

-- Environment-aware credential loader
local function initializeCredentials()
    if RunService:IsStudio() then
        Log("Running in Studio. Using credentials from Config.Studio.")
        FIREBASE_URL = Config.Studio.FIREBASE_URL
        AUTH_SECRET = Config.Studio.FIREBASE_SECRET
    else
        -- PRODUCTION CODE (Currently commented out)
        Log("Running in a non-Studio environment. Using Studio credentials as a fallback for now.")
        FIREBASE_URL = Config.Studio.FIREBASE_URL
        AUTH_SECRET = Config.Studio.FIREBASE_SECRET
    end

    if not FIREBASE_URL or not AUTH_SECRET then
        error("[FirebaseService] CRITICAL: Could not load Firebase URL or Auth Secret. Check Config.luau.")
    end
end

-- Constructs the final, authenticated URL
local function getPlayerUrl(userId)
	return string.format("%s/players/%s.json?auth=%s", FIREBASE_URL, tostring(userId), AUTH_SECRET)
end

--======================================================================
--=                          PUBLIC API                              =
--======================================================================

function FirebaseService.GetPlayerDataAsync(userId)
    local url = getPlayerUrl(userId)
    
    -- DEBUG: Log the request URL (without the secret for security)
    local debugUrl = string.format("%s/players/%s.json", FIREBASE_URL, tostring(userId))
    Log(string.format("DEBUG: Requesting data from URL: %s", debugUrl))

	local success, result = pcall(function() 
        return HttpService:GetAsync(url)
    end)

	if not success then
		Log(string.format("DEBUG: HTTP GET request FAILED for user %s: %s", userId, tostring(result)))
		return false, result
	end
    
    -- DEBUG: Log the full raw response from Firebase
    Log(string.format("DEBUG: Received RAW response for user %s: [%s]", userId, tostring(result)))

	if result == "null" then
		Log(string.format("No data found in Firebase for user %s. This might be a new player.", userId))
		return true, nil
	end
    
    local dataSuccess, decodedData = pcall(function()
        return HttpService:JSONDecode(result)
    end)

    if not dataSuccess then
        Log(string.format("DEBUG: JSON Decode FAILED for user %s. Error: %s", userId, tostring(decodedData)))
        return false, "JSON Decode Error"
    end

    Log(string.format("DEBUG: JSON Decode SUCCESS for user %s.", userId))
    return true, decodedData
end

function FirebaseService.SavePlayerDataAsync(userId, data)
    local url = getPlayerUrl(userId)
    local json_data
    local json_success, json_err = pcall(function()
        json_data = HttpService:JSONEncode(data)
    end)

    if not json_success then
        Log(string.format("Failed to encode data to JSON for user %s: %s", userId, json_err))
        return false, "JSON Encode Error"
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
		Log(string.format("HTTP PUT request failed for user %s: %s", userId, tostring(result)))
		return false, result
	end
    
    Log(string.format("Successfully saved data for user %s to Firebase.", userId))
	return true, nil
end

--======================================================================
--=                         INITIALIZATION                           =
--======================================================================

initializeCredentials()

return FirebaseService
