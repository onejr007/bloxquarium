# ReplicatedStorage

Folder ini berisi semua sumber daya bersama yang perlu diakses oleh **baik Klien maupun Server**.

## Struktur Penting

- **`Shared/`**: Direktori ini berisi modul `ModuleScript` yang dapat digunakan di mana saja.
    - **`RemoteClient.luau`**: Modul KLIEN yang paling penting. Ini adalah satu-satunya cara klien harus berkomunikasi dengan server. Ia menyediakan metode `.invoke()` dan `.fire()` yang menyederhanakan pengiriman permintaan ke `RemoteService` di server.
    - **`AssetManagerV3.luau`**: Modul bersama untuk mengelola dan memuat aset game.

- **`Assets/`**: Direktori ini menampung aset bersama seperti Model, Suara, dan Animasi yang perlu diakses saat runtime.

---

## Alur Kerja: Komunikasi Klien-ke-Server

Klien **TIDAK BOLEH** menggunakan `RemoteEvent` atau `RemoteFunction` secara langsung. Sebaliknya, mereka harus menggunakan modul `RemoteClient`.

### Contoh: Memanggil Fungsi Server dari Skrip Klien

Asumsikan ada layanan sisi server (`GameActions`) yang mendaftarkan tindakan yang dapat dipanggil bernama `GameAction_BuyItem`.

```lua
-- Di dalam skrip LocalScript atau ModuleScript sisi klien

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Impor modul RemoteClient
local RemoteClient = require(ReplicatedStorage.Shared.RemoteClient)

-- 2. Panggil fungsi invoke untuk menjalankan fungsi di server dan mendapatkan hasilnya
-- Argumen pertama adalah nama invoke yang terdaftar di server.
local success, message = RemoteClient:invoke("GameAction_BuyItem", "SwordOfPower")

if success then
    print("Pembelian berhasil:", message)
else
    warn("Pembelian gagal:", message)
end
```

### Contoh: Menembakkan Peristiwa Sekali Jalan ke Server

```lua
-- Di dalam skrip LocalScript atau ModuleScript sisi klien
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteClient = require(ReplicatedStorage.Shared.RemoteClient)

-- Kirim data ke server tanpa menunggu balasan
-- Argumen pertama adalah nama peristiwa yang terdaftar di server.
RemoteClient:fire("PlayerAnalytics_ButtonClicked", "ShopBuyButton")
```

Dengan menggunakan `RemoteClient`, kami memastikan bahwa semua komunikasi jaringan dirutekan melalui satu titik, sehingga lebih mudah untuk melakukan debug, mengamankan, dan memelihara.
