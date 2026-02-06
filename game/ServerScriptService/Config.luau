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
    game yang sudah di-publish, kunci API akan diambil dengan aman dari SecretService.

]]

local Config = {}

-- Konfigurasi untuk lingkungan pengembangan (Roblox Studio)
Config.Studio = {
    -- Tempelkan URL Firebase Anda di sini untuk pengujian lokal
    FIREBASE_URL = "https://bloxaquarium-default-rtdb.asia-southeast1.firebasedatabase.app/",
    
    -- Tempelkan Kunci API Web Firebase Anda di sini untuk pengujian lokal
    FIREBASE_API_KEY = "OVIURisf0NwJpGjooxUEVos4tcYyLiFHCjAwziGS"
}

-- Konfigurasi untuk lingkungan produksi (Server Roblox Live)
-- Nama-nama ini harus cocok dengan nama secret yang Anda buat di Creator Dashboard.
Config.Production = {
    FIREBASE_URL_SECRET_NAME = "FIREBASE_URL",
    FIREBASE_API_KEY_SECRET_NAME = "FIREBASE_API_KEY"
}

return Config
