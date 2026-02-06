# Bloxquarium - Professional Game Foundation

Selamat datang di Bloxquarium! Ini bukan sekadar game, melainkan sebuah **fondasi arsitektur game profesional** yang dibangun di Roblox. Proyek ini dirancang untuk menjadi titik awal yang solid bagi proyek game serius apa pun, dengan menekankan pada stabilitas, skalabilitas, dan praktik pengembangan modern.

[![Rojo](https://img.shields.io/badge/managed%20by-Rojo-blue.svg?style=for-the-badge&logo=roblox)](https://rojo.space/)

## 🌟 Fitur Arsitektur Utama

Proyek ini tidak hanya berisi aset, tetapi juga serangkaian sistem inti yang saling berhubungan dan siap pakai:

*   **🚀 Game Bootstrapper Profesional:**
    *   Mengelola urutan startup yang kompleks secara terkendali dan dapat diandalkan.
    *   Menjalankan tugas-tugas secara asinkron dengan pelaporan status yang jelas.
    *   Memastikan semua sistem diinisialisasi dalam urutan yang benar untuk mencegah *race condition*.

*   **🔒 Layanan Komunikasi Aman (`RemoteService`):
    *   Satu titik masuk tunggal untuk semua komunikasi client-server, menyederhanakan keamanan.
    *   Validasi *nonce* otomatis untuk melindungi dari serangan replay sederhana.
    *   Mekanisme pendaftaran event yang bersih, mencegah pemanggilan fungsi yang tidak sah.

*   **💾 Layanan Data & State (`DataService` & `ClientState`):
    *   Mengabstraksi logika `DataStore` dengan *retry mechanism* bawaan.
    *   Secara otomatis menyinkronkan data pemain ke klien saat mereka bergabung.
    *   Menyediakan **manajer state reaktif di sisi klien (`ClientState`)** yang memungkinkan UI dan sistem lain untuk "berlangganan" perubahan data secara real-time, menyederhanakan pengembangan UI secara drastis.

*   **🔑 Manajemen Konfigurasi & Rahasia (Hybrid):
    *   `config.luau` untuk konfigurasi gameplay yang dapat diakses oleh klien dan server.
    *   `secrets_config.server.luau` (di-gitignore) untuk menyimpan kunci API dan rahasia lain dengan aman di server.

*   **📦 Manajemen Aset Terpusat (`AssetManager` v2):
    *   Semua aset (gambar, suara, model) didaftarkan dalam satu file konfigurasi (`asset_config.luau`).
    *   Menghilangkan kebutuhan untuk menelusuri folder; cukup minta aset berdasarkan nama kustom Anda.
    *   Mendukung *preloading* dan *caching* untuk performa optimal.

## 📁 Struktur Proyek yang Disempurnakan

Struktur direktori dirancang agar intuitif dan selaras dengan praktik terbaik Rojo.

```
bloxquarium/
├── game/                           # Struktur 1:1 dengan Roblox Explorer
│   ├── ServerScriptService/        # Skrip dan Layanan Inti Server
│   │   ├── DataService.luau
│   │   ├── RemoteService.luau
│   │   ├── asset_config.luau
│   │   └── secrets_config.server.luau.example
│   ├── StarterPlayer/
│   │   └── StarterPlayerScripts/
│   │       └── ClientInit.client.luau # Titik masuk utama Klien
│   └── ReplicatedStorage/          # Modul Bersama
│       └── Shared/
│           ├── AssetManager.luau
│           ├── ClientState.luau
│           ├── GameBootstrapper.luau
│           └── RemoteClient.luau
├── assets/
│   ├── models/                     # HANYA untuk file model .rbxm
│   └── README.md                   # Penjelasan alur kerja aset
└── default.project.json            # Konfigurasi Rojo
```

## 🛠️ Memulai

1.  **Konfigurasi Rahasia:**
    *   Salin `game/ServerScriptService/secrets_config.server.luau.example` menjadi `secrets_config.server.luau`.
    *   Isi file tersebut dengan kunci API atau data rahasia Anda. File ini sudah terdaftar di `.gitignore` untuk mencegah kebocoran.

2.  **Daftarkan Aset:**
    *   Unggah gambar/suara Anda ke Roblox dan salin ID-nya.
    *   Letakkan model `.rbxm` Anda di `assets/models/`.
    *   Buka `game/ServerScriptService/asset_config.luau` dan daftarkan semua aset Anda.

3.  **Build & Jalankan:**
    *   Gunakan ekstensi Rojo di VS Code untuk melakukan sinkronisasi dengan Roblox Studio.
    *   Atau, jalankan perintah `rojo build -o "bloxquarium.rbxlx"` untuk membuat file proyek.

## 💡 Contoh Penggunaan: UI Reaktif

Berkat `ClientState`, membuat UI yang menampilkan data pemain menjadi sangat mudah. Tidak perlu lagi meminta data secara manual.

```lua
-- Di dalam sebuah LocalScript di dalam GUI Anda

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientState = require(ReplicatedStorage.Shared.ClientState)

local coinLabel = script.Parent.CoinLabel

-- Fungsi yang akan berjalan setiap kali data berubah
local function updateUI(newState)
    coinLabel.Text = string.format("Koin: %d", newState.coins or 0)
end

-- Berlangganan ke perubahan state. UI akan diperbarui secara otomatis.
local unsubscribe = ClientState:OnChange(updateUI)

-- (Opsional) Panggil 'unsubscribe()' saat UI dihancurkan untuk membersihkan memori.
script.Parent.Destroying:Connect(unsubscribe)
```

Arsitektur ini menyediakan fondasi yang kuat sehingga Anda bisa langsung fokus pada hal yang paling penting: **membangun gameplay yang menarik.**
