--[[
    RemoteClient.luau (v1.3 - Server Guard Fix)

    - FIXED: A critical crash where the script would attempt to run client-only code on the server.
    - The initialization call is now wrapped in a RunService:IsClient() check.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Promise = require(script.Parent.Promise)

local RemoteClient = {}

local remoteEvent
local remoteFunction

local serverEventHandlers = {}

local function initializeFromServerListener()
    print("🔌 [RemoteClient] Waiting for server communication channels...")
    remoteEvent = ReplicatedStorage:WaitForChild("ClientStateChannel")
    remoteFunction = ReplicatedStorage:WaitForChild("ClientInvokeChannel")
    print("✅ [RemoteClient] Server channels found. Connection established.")

    remoteEvent.OnClientEvent:Connect(function(eventData)
        if type(eventData) ~= "table" or not eventData.eventName then return end
        
        local handlers = serverEventHandlers[eventData.eventName]
        if handlers then
            for _, handler in ipairs(handlers) do
                local args = eventData.args or {}
                task.spawn(handler, unpack(args))
            end
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
            return remoteFunction:InvokeServer({eventName = eventName, args = packedArgs})
        end)

        if success then
            resolve(result)
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
