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
    if type(newState) ~= "table" then
        return
    end

    -- ## FILTER: Abaikan event game umum (multiplexed) ##
    -- Karena RemoteServer menggunakan ClientStateChannel untuk semua event,
    -- kita harus mengabaikan payload yang berisi 'eventName' (itu adalah event, bukan state).
    if newState.eventName and newState.args then
        return 
    end

    -- Validasi minimal: Harus punya Coins atau Inventory untuk dianggap sebagai state
    if newState.Coins == nil and newState.Inventory == nil then
        -- Opsional: log jika perlu debug, tapi biasanya ini adalah event lain yang tidak terfilter
        return
    end

    state = newState
    
    -- Helper to get keys for logging
    local invKeys = {}
    if state.Inventory and typeof(state.Inventory) == "table" then
        for k in pairs(state.Inventory) do table.insert(invKeys, tostring(k)) end
    end
    
    print("🎨 [ClientState] State updated. Coins:", state.Coins, "Inventory categories:", #invKeys > 0 and table.concat(invKeys, ", ") or "none")
    stateChanged:Fire(state)
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
