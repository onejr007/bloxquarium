--[[
    RemoteClient.luau (v1.2 - Two-Way Communication)

    Handles all communication to AND from the server.
    - :FireServer() sends events to the server with a secure nonce.
    - :On() listens for events sent from the server.
]]

--=================[ SERVICES ]=================--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--=================[ MODULES ]=================--
-- none

--=================[ CONFIGURATION ]=================--
local RemoteClient = {}

-- Channels (lazy loaded)
local toServerChannel = nil
local fromServerChannel = nil

-- Security
local nonceCounter = 0

-- Client-side event listeners
local eventListeners = {}

--///////////////////////////////////////////////////////////////////////////
--// INTERNAL LOGIC
--///////////////////////////////////////////////////////////////////////////

-- Handler utama untuk semua event yang datang DARI server
local function onServerEvent(payload)
    if typeof(payload) ~= "table" or not payload.eventName then
        warn("[RemoteClient] Invalid payload received from server.")
        return
    end

    local eventName = payload.eventName
    local listener = eventListeners[eventName]

    if listener then
        -- pcall untuk keamanan, agar satu listener error tidak merusak yang lain
        local success, err = pcall(listener, table.unpack(payload.args or {}))
        if not success then
            warn(string.format("[RemoteClient] Error running listener for event '%s': %s", eventName, err))
        end
    end
end

-- Menginisialisasi listener dari server (jika belum)
local function initializeFromServerListener()
    if not fromServerChannel then
        print("🔌 [RemoteClient] Connecting to 'ClientStateChannel' for server events...")
        fromServerChannel = ReplicatedStorage:WaitForChild("ClientStateChannel")
        fromServerChannel.OnClientEvent:Connect(onServerEvent)
        print("✅ [RemoteClient] Connected to server events.")
    end
end

--///////////////////////////////////////////////////////////////////////////
--// PUBLIC API
--///////////////////////////////////////////////////////////////////////////

-- Mendaftarkan listener untuk sebuah event yang dikirim OLEH server
function RemoteClient:On(eventName, callback)
    if eventListeners[eventName] then
        warn(string.format("🔌 [RemoteClient] Overwriting listener for event '%s'.", eventName))
    end
    eventListeners[eventName] = callback
    -- Pastikan listener utama sudah aktif
    initializeFromServerListener()
end

-- Mengirim event KE server
function RemoteClient:FireServer(eventName, ...)
    if not toServerChannel then
        print("🔌 [RemoteClient] Finding 'ClientToServerChannel'...")
        toServerChannel = ReplicatedStorage:WaitForChild("ClientToServerChannel")
        print("✅ [RemoteClient] Client->Server channel cached.")
    end

    nonceCounter += 1

    local payload = {
        eventName = eventName,
        nonce = nonceCounter,
        args = {...}
    }

    toServerChannel:FireServer(payload)
end

return RemoteClient
