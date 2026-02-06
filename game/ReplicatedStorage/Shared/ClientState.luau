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
-- none

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
    if not newState then return end
    print("🎨 [ClientState] State baru diterima dari server.")
    state = newState
    stateChanged:Fire(state) -- Beri tahu semua pelanggan tentang perubahan.
end

-- Inisialisasi: Tunggu server mengirimkan state awal.
local function init()
    print("🎨 [ClientState] Manajer state klien diinisialisasi, menunggu data awal dari server...")
    local channel = ReplicatedStorage:WaitForChild("ClientStateChannel")
    channel.OnClientEvent:Connect(setState)
end

-- PERBAIKAN: Pastikan inisialisasi HANYA berjalan di klien untuk mencegah error di server.
if RunService:IsClient() then
    init()
end

return ClientState
