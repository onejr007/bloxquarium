--[[
    RemoteServer.luau (v1.3 - Definitive Packager Fix)

    - This version definitively fixes the `unpack` error by correctly handling all argument types.
    - It changes the function signature to use varargs (`...`) to capture any and all arguments passed to it.
    - It then explicitly packs these arguments into a table, ensuring that single booleans, nils, or other types don't break the client-side parser.
    - This module is now solely responsible for data packaging, creating a robust and predictable communication channel.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteServer = {}
local remoteEvent

function RemoteServer.initialize()
    if ReplicatedStorage:FindFirstChild("ClientStateChannel") then
        remoteEvent = ReplicatedStorage.ClientStateChannel
    else
        remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = "ClientStateChannel"
        remoteEvent.Parent = ReplicatedStorage
    end
end

-- Handler for events fired from the client
local clientEventHandlers = {}
function RemoteServer:On(eventName, callback)
    if not clientEventHandlers[eventName] then
        clientEventHandlers[eventName] = {}
    end
    table.insert(clientEventHandlers[eventName], callback)
end

-- Handler for functions invoked from the client
local clientInvokeHandlers = {}
function RemoteServer:OnInvoke(eventName, callback)
    clientInvokeHandlers[eventName] = callback
end

-- ## THE DEFINITIVE FIX ##
function RemoteServer:FireClient(player, eventName, ...)
    if remoteEvent then
        -- Capture all variable arguments into a single, safe table.
        local packedArgs = {...}
        -- Build the payload in the exact format the client expects.
        local payload = {eventName = eventName, args = packedArgs}
        remoteEvent:FireClient(player, payload)
    end
end

function RemoteServer:FireAllClients(eventName, ...)
    if remoteEvent then
        -- Apply the same robust logic for FireAllClients.
        local packedArgs = {...}
        local payload = {eventName = eventName, args = packedArgs}
        remoteEvent:FireAllClients(payload)
    end
end

-- Internal handler for all incoming client events
local function onClientEvent(player, eventData)
    if type(eventData) ~= "table" or not eventData.eventName then
        return
    end

    local handlers = clientEventHandlers[eventData.eventName]
    if handlers then
        for _, handler in ipairs(handlers) do
            local args = eventData.args or {}
            task.spawn(handler, player, unpack(args))
        end
    end
end

-- Initialize everything
RemoteServer.initialize()

-- Connect the single server-side listener
remoteEvent.OnServerEvent:Connect(onClientEvent)

-- Create a RemoteFunction for invoke calls if it doesn't exist
local remoteFunction
if ReplicatedStorage:FindFirstChild("ClientInvokeChannel") then
    remoteFunction = ReplicatedStorage.ClientInvokeChannel
else
    remoteFunction = Instance.new("RemoteFunction")
    remoteFunction.Name = "ClientInvokeChannel"
    remoteFunction.Parent = ReplicatedStorage
end

remoteFunction.OnServerInvoke = function(player, eventData)
    if type(eventData) ~= "table" or not eventData.eventName then
        return nil, "Invalid invocation format"
    end

    local handler = clientInvokeHandlers[eventData.eventName]
    if handler then
        local args = eventData.args or {}
        return handler(player, unpack(args))
    end

    return nil, string.format("No handler registered for invocation '%s'", eventData.eventName)
end

return RemoteServer
