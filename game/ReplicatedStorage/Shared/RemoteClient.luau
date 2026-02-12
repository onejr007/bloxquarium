--[[
    RemoteClient.luau (v1.4 - Definitive Return Value Unpacking)

    - This is the second half of the definitive fix for invoke/return value mismatches.
    - The server (`RemoteServer` v1.5+) now guarantees to send a single table containing all return values.
    - This version updates `InvokeServer` to unpack that table before resolving the Promise.
    - `resolve(unpack(result))` effectively reconstructs the original, multi-value return from the server handler on the client side.
    - This makes the entire network protocol robust and transparent to the rest of the codebase.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Promise = require(script.Parent.Promise)

local RemoteClient = {}

local remoteEvent
local remoteFunction
local isInitialized = false
local initializedEvent = Instance.new("BindableEvent")

local serverEventHandlers = {}

local function initializeFromServerListener()
    print("🔌 [RemoteClient] Waiting for server communication channels...")
    remoteEvent = ReplicatedStorage:WaitForChild("ClientStateChannel", 10)
    remoteFunction = ReplicatedStorage:WaitForChild("ClientInvokeChannel", 10)
    
    if not remoteEvent or not remoteFunction then
        warn("❌ [RemoteClient] CRITICAL: Server communication channels not found within timeout!")
        return
    end
    
    print("✅ [RemoteClient] Server channels found. Connection established.")
    isInitialized = true
    initializedEvent:Fire()

    remoteEvent.OnClientEvent:Connect(function(eventData)
        if type(eventData) ~= "table" then return end
        
        -- Support for legacy direct-state updates if eventName is missing
        if not eventData.eventName then
            -- If it's just state data, we don't handle it here, 
            -- but we also don't block other listeners (like ClientState).
            return 
        end
        
        local handlers = serverEventHandlers[eventData.eventName]
        if handlers then
            for _, handler in ipairs(handlers) do
                local args = eventData.args or {}
                task.spawn(handler, unpack(args))
            end
        end
    end)
end

function RemoteClient:WaitForConnection()
    if isInitialized then return Promise.resolve(true) end
    return Promise.new(function(resolve)
        local connection
        connection = initializedEvent.Event:Connect(function()
            connection:Disconnect()
            resolve(true)
        end)
        
        -- Fallback if already initialized by the time we connect
        if isInitialized then
            connection:Disconnect()
            resolve(true)
        end
    end)
end

function RemoteClient:FireServer(eventName, ...)
    if not remoteEvent then
        warn("[RemoteClient] Cannot FireServer, remote event not initialized.")
        return
    end
    local packedArgs = {...}
    local eventData = {eventName = eventName, args = packedArgs}
    remoteEvent:FireServer(eventData)
end

function RemoteClient:InvokeServer(eventName, ...)
    if not remoteFunction then
        warn("[RemoteClient] Cannot InvokeServer, remote function not initialized.")
        return Promise.reject("Remote function not available")
    end

    local packedArgs = {...}

    return Promise.new(function(resolve, reject)
        local success, result = pcall(function()
            return {remoteFunction:InvokeServer({eventName = eventName, args = packedArgs})}
        end)

        if success then
            -- 🚀 DEFINITIVE FIX: The server returns a single table {success, wonFishId}
            -- We must unpack it to resolve with multiple values
            if type(result[1]) == "table" then
                warn("📡 [RemoteClient] Received packaged result, unpacking...")
                resolve(unpack(result[1]))
            else
                warn("📡 [RemoteClient] Received direct result:", result[1])
                resolve(unpack(result))
            end
        else
            reject(result)
        end
    end)
end

function RemoteClient:On(eventName, callback)
    if not serverEventHandlers[eventName] then
        serverEventHandlers[eventName] = {}
    end
    local connection = {}
    table.insert(serverEventHandlers[eventName], callback)
    
    function connection:Disconnect()
        for i, handler in ipairs(serverEventHandlers[eventName]) do
            if handler == callback then
                table.remove(serverEventHandlers[eventName], i)
                break
            end
        end
    end
    return connection
end

-- CRITICAL FIX: Only run client-specific initialization on the client.
if RunService:IsClient() then
    task.spawn(initializeFromServerListener)
end

return RemoteClient
