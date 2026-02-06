--[[
    RemoteService.luau

    Handler terpusat dan aman untuk semua komunikasi client-to-server.
    Menerapkan sistem nonce untuk mencegah serangan replay (replay attacks).
]]

--=================[ SERVICES ]=================--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--=================[ MODULES ]=================--
local Promise = require(ReplicatedStorage.Shared.Promise)

--=================[ CONFIGURATION ]=================--
local RemoteService = {}

-- Kamus untuk menyimpan fungsi callback yang terdaftar
local registeredEvents = {}

-- Kamus untuk menyimpan nonce terakhir yang valid dari setiap pemain
-- SECURITY: Ini adalah "state" server-side yang digunakan untuk validasi.
local playerNonceCounters = {}

-- Channel komunikasi tunggal dari client ke server
local channel

--///////////////////////////////////////////////////////////////////////////
--// API PUBLIK
--///////////////////////////////////////////////////////////////////////////

-- Mendaftarkan sebuah event dengan callback-nya.
-- Semua skrip server lain akan memanggil ini untuk mengekspos fungsionalitas ke klien.
function RemoteService:Register(eventName, callback)
    if registeredEvents[eventName] then
        warn(string.format("🔌 [RemoteService] Event '%s' sudah terdaftar. Menimpanya.", eventName))
    end
    registeredEvents[eventName] = callback
    print(string.format("🔌 [RemoteService] Event '%s' berhasil didaftarkan.", eventName))
end

--///////////////////////////////////////////////////////////////////////////
--// LOGIKA INTERNAL & KEAMANAN
--///////////////////////////////////////////////////////////////////////////

-- Handler utama untuk semua permintaan yang masuk dari klien
local function onClientRequest(player, payload)
    --[[ SECURITY CHECKS ]]
    -- 1. Apakah payload-nya sebuah tabel?
    if typeof(payload) ~= "table" then
        player:Kick("[RS-01] Permintaan tidak valid.")
        return
    end

    -- 2. Apakah ada nama event dan nonce?
    local eventName, nonce = payload.eventName, payload.nonce
    if not eventName or not nonce or typeof(nonce) ~= "number" then
        player:Kick("[RS-02] Payload tidak lengkap.")
        return
    end

    -- 3. Apakah nonce yang masuk lebih besar dari yang terakhir kita lihat?
    -- Ini adalah validasi inti untuk mencegah replay attacks.
    local lastNonce = playerNonceCounters[player.UserId]
    if not lastNonce or nonce <= lastNonce then
        player:Kick(string.format("[RS-03] Urutan permintaan tidak valid. Nonce: %d, Server: %d", nonce, lastNonce or -1))
        return
    end

    -- 4. Apakah event-nya terdaftar?
    local callback = registeredEvents[eventName]
    if not callback then
        player:Kick(string.format("[RS-04] Event tidak dikenal: %s", tostring(eventName)))
        return
    end

    --[[ VALIDASI BERHASIL ]]
    -- Update nonce terakhir yang kita lihat dari pemain ini.
    playerNonceCounters[player.UserId] = nonce
    
    -- Panggil callback yang sesuai dengan argumen yang diberikan
    -- pcall untuk menangkap error di dalam callback agar tidak merusak handler
    local success, result = pcall(callback, player, table.unpack(payload.args or {}))
    if not success then
        warn(string.format("🔌 [RemoteService] Error saat menjalankan callback untuk event '%s': %s", eventName, tostring(result)))
    end
end

--///////////////////////////////////////////////////////////////////////////
--// INISIALISASI
--///////////////////////////////////////////////////////////////////////////

function RemoteService:Init()
    print("🔌 [RemoteService] Inisialisasi handler remote yang aman...")

    -- Buat channel komunikasi
    channel = Instance.new("RemoteEvent")
    channel.Name = "ClientToServerChannel"
    channel.Parent = ReplicatedStorage

    -- Setup listener
    channel.OnServerEvent:Connect(onClientRequest)

    -- Setup dan cleanup untuk setiap pemain
    Players.PlayerAdded:Connect(function(player)
        -- Inisialisasi counter nonce untuk pemain baru
        playerNonceCounters[player.UserId] = 0
    end)

    Players.PlayerRemoving:Connect(function(player)
        -- Hapus data pemain dari tabel nonce untuk manajemen memori
        playerNonceCounters[player.UserId] = nil
    end)

    print("✅ [RemoteService] Handler remote siap menerima koneksi aman.")
end

return RemoteService
