--[[
    RemoteServer.luau (v1.5 - Definitive Return Value Packaging)

    - THIS IS THE FINAL FIX for all invoke/return value mismatches.
    - The previous `select(1, ...)` fix was too aggressive. It would discard legitimate secondary return values (like `nil, "error_message"`), causing the client to receive a malformed `nil` payload.
    - This version fixes it at the protocol level. It now captures ALL return values from a handler into a single table: `{...}`.
    - This single table is then returned to the client.
    - The client-side `RemoteClient` will then unpack this table, resolving the Promise with the original, full set of return values.
    - This creates a robust, predictable, and error-proof invocation contract, regardless of what a handler returns.
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

function RemoteServer:FireClient(player, eventName, ...)
    if remoteEvent then
        local payload = {eventName = eventName, args = {...}}
        remoteEvent:FireClient(player, payload)
    end
end

function RemoteServer:FireAllClients(eventName, ...)
    if remoteEvent then
        local payload = {eventName = eventName, args = {...}}
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

-- ## THE FINAL, DEFINITIVE FIX ##
remoteFunction.OnServerInvoke = function(player, eventData)
    if type(eventData) ~= "table" or not eventData.eventName then
        -- Return the error in the standardized packaged format
        return {nil, "Invalid invocation format"}
    end

    local handler = clientInvokeHandlers[eventData.eventName]
    if handler then
        local args = eventData.args or {}
        -- 🚀 DEFINITIVE FIX: Package results in a table for guaranteed transport
        -- This ensures wonFishId (2nd return) isn't lost during the network hop
        local results = {handler(player, unpack(args))}
        warn("📡 [RemoteServer] Packaging results for", eventData.eventName, ":", results[1], results[2])
        return results
    end

    -- Return the error in the standardized packaged format
    return {nil, string.format("No handler registered for invocation '%s'", eventData.eventName)}
end

return RemoteServer
