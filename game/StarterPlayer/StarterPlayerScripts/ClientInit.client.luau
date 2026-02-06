--[[
	ClientInit.client.luau (v2 - ClientState Integration)

	Entry point utama sisi klien. Bertanggung jawab untuk menginisialisasi
	sistem-sistem penting di klien dan mendemonstrasikan cara kerja ClientState.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage.Shared

-- Impor modul-modul penting
local ClientState = require(SharedModules.ClientState)

print("🚀 [ClientInit] Inisialisasi Klien v2...")

-- DEMONSTRASI ClientState: Cara berlangganan (subscribe) data pemain secara reaktif.
-- Ini adalah pola yang akan Anda gunakan untuk semua UI Anda (HUD, toko, dll.)

print("🎨 [ClientInit] Berlangganan (subscribing) ke perubahan ClientState...")

local function onStateChanged(newState)
    print("--------------------------------------------------")
    print("🎨 [ClientInit] State pemain diperbarui!")
    print(string.format("   - 🪙 Koin: %d", newState.coins or 0))
    print(string.format("   - 💎 Permata: %d", newState.gems or 0))
    print(string.format("   - 📈 Level: %d (XP: %d)", newState.level or 1, newState.xp or 0))
    print("--------------------------------------------------")
end

-- Hubungkan fungsi di atas ke event perubahan ClientState.
-- ClientState:OnChange akan segera memanggilnya sekali dengan data awal,
-- dan kemudian setiap kali data diperbarui oleh server.
local unsubscribe = ClientState:OnChange(onStateChanged)

print("✅ [ClientInit] Klien siap dan reaktif terhadap perubahan data.")

-- Catatan: Fungsi 'unsubscribe' dapat dipanggil jika Anda ingin berhenti mendengarkan,
-- misalnya saat sebuah GUI ditutup, untuk mencegah memory leak.
-- Contoh: task.wait(30) unsubscribe()
