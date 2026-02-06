--[[
    RemoteClient.luau (v1.1 - Race Condition Fix)

    Satu-satunya titik antarmuka bagi skrip klien untuk berkomunikasi dengan server.
    Secara otomatis menangani pembuatan nonce untuk setiap permintaan.
]]

--=================[ SERVICES ]=================--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--=================[ MODULES ]=================--
-- none

--=================[ CONFIGURATION ]=================--
local RemoteClient = {}

-- PERBAIKAN: Deklarasikan variabel channel di sini, tetapi jangan langsung mencarinya.
-- Ini akan diinisialisasi saat pertama kali dibutuhkan (lazy initialization).
local channel = nil

-- Penghitung nonce di sisi klien. Terus bertambah untuk setiap permintaan.
local nonceCounter = 0

--///////////////////////////////////////////////////////////////////////////
--// API PUBLIK
--///////////////////////////////////////////////////////////////////////////

-- Mengirim permintaan ke server dengan payload yang aman.
-- Ini adalah satu-satunya fungsi yang akan digunakan oleh skrip klien lain.
function RemoteClient:FireServer(eventName, ...)
    -- PERBAIKAN: Jika channel belum ditemukan, cari sekarang. Ini hanya akan berjalan sekali.
    if not channel then
        print("🔌 [RemoteClient] Mencari 'ClientToServerChannel' untuk pertama kalinya...")
        channel = ReplicatedStorage:WaitForChild("ClientToServerChannel")
        print("✅ [RemoteClient] Channel ditemukan dan di-cache.")
    end

    -- 1. Tingkatkan nonce untuk membuat permintaan ini unik
    nonceCounter += 1

    -- 2. Bungkus semua informasi ke dalam satu tabel (payload)
    local payload = {
        eventName = eventName,
        nonce = nonceCounter,
        args = {...} -- Semua argumen tambahan dikemas di sini
    }

    -- 3. Kirim payload melalui channel tunggal
    channel:FireServer(payload)
end

return RemoteClient
