# 🚀 Panduan Memulai Cepat - Bloxquarium (v2)

Panduan cepat untuk mulai menggunakan arsitektur layanan modular baru proyek.

## 📂 Di Mana Menempatkan Skrip?

### Skrip Server (Sekarang sebagai Layanan)

Semua logika sisi server sekarang dienkapsulasi dalam **Modul Layanan**. Modul-modul ini berada di dalam direktori `Services` dan dimuat secara otomatis oleh `ServiceLoader`.

```
📁 game/ServerScriptService/
├── 📄 ServerInit.server.luau    # Titik masuk utama (sebaiknya jangan diubah)
├── 📄 ServiceLoader.luau        # Memuat dan menginisialisasi semua layanan
├── 📁 Services/                 # FOLDER UNTUK SEMUA MODUL LAYANAN ANDA
│   ├── 📄 DataService.luau       # Layanan data yang sudah ada
│   ├── 📄 GameActions.luau      # Layanan tindakan game yang sudah ada
│   └── 📄 MyNewService.luau     # Di sini Anda menempatkan layanan baru Anda
└── 📄 README.md                 # Dokumentasi
```

### Skrip Klien (Berjalan di Pemain)
Struktur ini tidak berubah.
```
📁 game/StarterPlayer/StarterPlayerScripts/
├── 📄 MainClient.client.luau      # Skrip klien utama
└── 📁 UI/                         # Folder untuk skrip UI
```

### Modul Bersama (Dapat Diakses oleh Server & Klien)
Struktur ini tidak berubah.
```
📁 game/ReplicatedStorage/
└── 📁 Shared/                     # Modul yang dapat diakses oleh semua
    ├── 📄 AssetManagerV3.luau      # Sistem aset
    └── 📄 RemoteClient.luau       # Modul remote klien
```

---

## 🎯 Alur Kerja Baru: Membuat Layanan Server

Alih-alih membuat `Script` biasa, Anda sekarang akan membuat `ModuleScript` di dalam folder `Services`.

### 1. Buat File Modul Layanan Baru
Buat file baru di `game/ServerScriptService/Services/MyNewService.luau`.

```lua
-- 📁 game/ServerScriptService/Services/MyNewService.luau
local MyNewService = {}

-- Dependensi apa pun yang Anda butuhkan dapat diteruskan di sini
function MyNewService:Init(RemoteService) 
    print("🚀 [MyNewService] Inisialisasi...")

    -- Contoh mendaftarkan remote invoke
    if RemoteService then
        RemoteService:RegisterInvoke("MyAction", function(player, ...)
            return "Hello, " .. player.Name
        end)
    end
end

function MyNewService:DoSomething()
    print("Melakukan sesuatu yang hebat!")
end

return MyNewService
```

### 2. Daftarkan Layanan Anda di ServiceLoader
Buka `game/ServerScriptService/ServiceLoader.luau` dan tambahkan nama layanan baru Anda ke tabel `INIT_ORDER`. Urutan itu penting!

```lua
-- 📄 ServiceLoader.luau

-- ... (kode yang ada)

local INIT_ORDER = {
    "WorldService",
    "RemoteService",
    "LeaderboardService",
    "GameActions",
    "DataService",
    "AdminService",
    "MyNewService" -- TAMBAHKAN LAYANAN BARU ANDA DI SINI
}

-- ... (sisa kode)
```

### 3. Selesai!
Itu saja! `ServiceLoader` akan secara otomatis memuat dan menginisialisasi layanan baru Anda saat server dimulai. Jika layanan Anda membutuhkan `RemoteService`, `ServiceLoader` akan secara otomatis menyuntikkannya.

---

## ⚡ Perintah Rojo

Perintah-perintah ini tidak berubah.

### Build Proyek
```bash
rojo build -o "bloxquarium.rbxlx"
```

### Mulai Server Pengembangan
```bash
rojo serve
```

## 🎮 Siap untuk Mengkode!

Sekarang Anda siap untuk mulai mengkode menggunakan arsitektur layanan yang baru dan lebih baik! Struktur ini dirancang untuk menjaga agar kode Anda tetap teratur dan mudah dikelola.

**Selamat Mengkode! 🚀**
