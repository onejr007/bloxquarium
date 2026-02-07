--[[
    RemoteServer.luau (v1.0 - CORE MODULE)

    - This is the missing core module for the server-side remote event handling.
    - It creates and manages a central communication channel (`ClientStateChannel`).
    - Provides clean `On`, `OnInvoke`, `FireClient`, and `FireAllClients` methods.
    - This fixes the "RemoteServer is not a valid member" crash.
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

function RemoteServer:FireClient(player, ...)
    if remoteEvent then
        remoteEvent:FireClient(player, ...)
    end
end

function RemoteServer:FireAllClients(...)
    if remoteEvent then
        remoteEvent:FireAllClients(...)
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
            -- Unpack the arguments, excluding the eventName itself
            local args = {}
            if eventData.args then
                for i=1, #eventData.args do
                    table.insert(args, eventData.args[i])
                end
            end
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
