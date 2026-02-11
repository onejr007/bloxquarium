--[[
    ClientState.luau (v1.1 - Environment Fix)

    Manajer state terpusat di sisi klien. Bertindak sebagai "single source of truth"
    untuk semua data pemain yang relevan dengan UI dan gameplay lokal.

    - Berlangganan (subscribes) ke perubahan state secara reaktif.
    - Diinisialisasi secara otomatis oleh server.
]]

--=================[ SERVICES ]=================--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- PERBAIKAN: Tambahkan RunService untuk memeriksa lingkungan (client/server)
local RunService = game:GetService("RunService")

--=================[ MODULES ]=================--
local RemoteClient = require(script.Parent.RemoteClient)

--=================[ CONFIGURATION ]=================--
local ClientState = {}
ClientState.__index = ClientState

-- Ini adalah "otak" dari sistem, menyimpan semua data.
local state = {}
-- Ini adalah sinyal yang kita kirimkan ketika state berubah.
local stateChanged = Instance.new("BindableEvent")

--///////////////////////////////////////////////////////////////////////////
--// API PUBLIK
--///////////////////////////////////////////////////////////////////////////

-- Mengambil salinan dari seluruh state saat ini.
function ClientState:GetState()
    return table.clone(state)
end

-- Mengambil nilai tertentu dari state berdasarkan kuncinya.
function ClientState:Get(key)
    return state[key]
end

-- Berlangganan (subscribe) ke perubahan state.
-- Callback akan dipanggil setiap kali state diperbarui.
-- Mengembalikan fungsi untuk berhenti berlangganan (unsubscribe).
function ClientState:OnChange(callback)
    -- Panggil callback segera dengan state saat ini agar UI langsung ter-update.
    task.spawn(callback, state)
    
    local connection = stateChanged.Event:Connect(callback)
    
    -- Kembalikan fungsi disconnect untuk pembersihan memori yang mudah
    return function()
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
end

--///////////////////////////////////////////////////////////////////////////
--// FUNGSI INTERNAL & INISIALISASI
--///////////////////////////////////////////////////////////////////////////

-- Mengatur state internal dan memberi tahu semua pelanggan.
local function setState(newState)
    if not newState or typeof(newState) ~= "table" then 
        warn("🎨 [ClientState] Received invalid state (not a table):", typeof(newState))
        return 
    end
    
    -- ## FIX: Filter out multiplexed game events ##
    -- Because RemoteServer uses the same ClientStateChannel for general events,
    -- we must ensure we only process tables that look like actual player state.
    if newState.eventName and newState.args then
        -- This is a general game event, ignore it here.
        return 
    end

    -- Validate that it's actually a state table
    -- We'll be more lenient but log what we find
    local hasCoins = newState.Coins ~= nil
    local hasInv = newState.Inventory ~= nil
    
    if not (hasCoins or hasInv) then
        -- Log keys found to help debugging
        local keys = {}
        for k in pairs(newState) do table.insert(keys, tostring(k)) end
        warn(string.format("🎨 [ClientState] Ignoring table update - missing Coins/Inventory. Keys: %s", table.concat(keys, ", ")))
        return
    end

    print(string.format("🎨 [ClientState] State baru diterima. Coins: %s, Inventory: %s", 
        tostring(newState.Coins), 
        hasInv and "Found" or "Missing"))
        
    state = newState
    stateChanged:Fire(state) -- Beri tahu semua pelanggan tentang perubahan.
end

-- Inisialisasi: Tunggu server mengirimkan state awal.
local function init()
    print("🎨 [ClientState] Manajer state klien diinisialisasi, menunggu data awal dari server...")
    local channel = ReplicatedStorage:WaitForChild("ClientStateChannel")
    channel.OnClientEvent:Connect(setState)

    -- Request initial state from server to ensure we don't start with empty data
    task.spawn(function()
        RemoteClient:WaitForConnection():andThen(function()
            print("🎨 [ClientState] Menarik data awal (initial state) dari server...")
            return RemoteClient:InvokeServer("GetInitialState")
        end):andThen(function(initialState)
            if initialState then
                print("🎨 [ClientState] Data awal berhasil diterima via Invoke.")
                setState(initialState)
            else
                warn("🎨 [ClientState] Gagal mengambil data awal atau data masih kosong.")
            end
        end):catch(function(err)
            warn("🎨 [ClientState] Error saat mengambil data awal:", tostring(err))
        end)
    end)
end

-- PERBAIKAN: Pastikan inisialisasi HANYA berjalan di klien untuk mencegah error di server.
if RunService:IsClient() then
    init()
end

return ClientState
