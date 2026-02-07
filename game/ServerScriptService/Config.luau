--[[
    Konfigurasi Game Terpusat (Config.luau v1.3 - URL FIX)

    PENTING: KREDENSIAL DI SINI HANYA UNTUK PENGUJIAN LOKAL DI STUDIO.
    File ini harus ditambahkan ke .gitignore untuk mencegah kebocoran kunci API.

]]

local Config = {}

-- Konfigurasi untuk lingkungan pengembangan (Roblox Studio)
Config.Studio = {
    -- URL Realtime Database Firebase Anda
    -- FIXED: Trailing slash removed to prevent double slashes in request URLs.
    FIREBASE_URL = "https://bloxaquarium-default-rtdb.asia-southeast1.firebasedatabase.app",
    
    -- [PENTING] Ini adalah **DATABASE SECRET**, bukan API Key.
    -- Diperlukan untuk otentikasi server legacy.
    -- JANGAN PERNAH MENGISI SECRET DI SINI UNTUK LINGKUNGAN PRODUKSI
    -- Secret ini akan diambil dari SecretService di lingkungan produksi.
    FIREBASE_SECRET = "OVIURisf0NwJpGjooxUEVos4tcYyLiFHCjAwziGS"
}

-- Konfigurasi untuk lingkungan produksi (Server Roblox Live)
-- Nama-nama ini harus cocok dengan nama secret yang Anda buat di Creator Dashboard.
Config.Production = {
    FIREBASE_URL_SECRET_NAME = "FIREBASE_URL",
    -- Pastikan nama secret di Roblox cocok dengan ini
    FIREBASE_SECRET_NAME = "FIREBASE_SECRET"
}

return Config
