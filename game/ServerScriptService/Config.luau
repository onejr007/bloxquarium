--[[
    Config.luau

    MODUL KONFIGURASI LOKAL UNTUK PENGEMBANGAN DI STUDIO

    =========================================================================
    !!! PERINGATAN KEAMANAN KRITIS !!!
    =========================================================================
    
    File ini berisi informasi sensitif (seperti kunci API).

    >> TAMBAHKAN FILE INI KE `.gitignore` ANDA SEKARANG JUGA! <<

    Jangan pernah meng-commit file ini ke repositori Git publik atau membagikannya.
    File ini HANYA untuk kenyamanan pengujian di Roblox Studio. Di server
    game yang sudah di-publish, kunci akan diambil dengan aman dari SecretService.

]]

local Config = {}

-- Konfigurasi untuk lingkungan pengembangan (Roblox Studio)
Config.Studio = {
    -- URL Realtime Database Firebase Anda
    FIREBASE_URL = "https://bloxaquarium-default-rtdb.asia-southeast1.firebasedatabase.app/",
    
    -- [PENTING] Ini adalah **DATABASE SECRET**, bukan API Key.
    -- Diperlukan untuk otentikasi server legacy.
    FIREBASE_SECRET = "OVIURisf0NwJpGjooxUEVos4tcYyLiFHCjAwziGS"
}

-- Konfigurasi untuk lingkungan produksi (Server Roblox Live)
-- Nama-nama ini harus cocok dengan nama secret yang Anda buat di Creator Dashboard.
Config.Production = {
    FIREBASE_URL_SECRET_NAME = "FIREBASE_URL",
    FIREBASE_SECRET_NAME = "FIREBASE_SECRET" -- Nama secret untuk Database Secret Anda
}

return Config
