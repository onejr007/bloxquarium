# Asset Management System (v2 - Centralized)

Folder `assets/` ini adalah sumber untuk semua aset dalam game. Namun, tidak seperti sistem tradisional yang bergantung pada struktur folder, arsitektur ini menggunakan pendekatan terpusat melalui `asset_config.luau` untuk manajemen aset yang lebih kuat dan fleksibel.

## Prinsip Utama

1.  **Satu Sumber Kebenaran (`Single Source of Truth`):** File `asset_config.luau` adalah satu-satunya tempat di mana Anda perlu mendaftarkan dan mengonfigurasi aset.

2.  **Agnostik Terhadap Lokasi:** Anda dapat mengunggah gambar, suara, atau mesh Anda langsung ke Roblox dan hanya perlu menempelkan *Asset ID* mereka di dalam `asset_config.luau`. Anda tidak perlu lagi menyimpan file fisik `.png` atau `.mp3` di dalam proyek.

3.  **Model Tetap Lokal:** Satu-satunya pengecualian adalah untuk aset model (`.rbxm`). Model-model ini **harus** ditempatkan di dalam folder `assets/models/` agar sistem dapat secara otomatis mengimpornya saat *bootstrap*.

## Alur Kerja Manajemen Aset

### Langkah 1: Tambahkan Aset

*   **Untuk Gambar, Suara, Mesh, dll.:**
    1.  Unggah aset Anda ke Roblox (misalnya melalui Asset Manager di Studio).
    2.  Salin *Asset ID* yang dihasilkan (contoh: `rbxassetid://123456789`).

*   **Untuk Model:**
    1.  Simpan model Anda sebagai file `.rbxm`.
    2.  Letakkan file tersebut di dalam direktori `assets/models/`.

### Langkah 2: Daftarkan Aset di `asset_config.luau`

Buka `game/ServerScriptService/asset_config.luau` dan tambahkan entri baru. Gunakan nama yang jelas sebagai kunci.

```lua
-- game/ServerScriptService/asset_config.luau

return {
    -- ... aset lain

    -- Contoh mendaftarkan ID Gambar
    Coin_ico = "rbxassetid://987654321",

    -- Contoh mendaftarkan ID Suara
    BUTTON_CLICK = "rbxassetid://112233445",

    -- Contoh mendaftarkan model lokal (nama file tanpa ekstensi)
    Goldfish = "Goldfish",
}
```

### Langkah 3: Gunakan Aset Melalui `AssetManager`

Di skrip mana pun (klien atau server), gunakan `AssetManager` untuk mengakses aset Anda. **Selalu gunakan kunci yang Anda tentukan di `asset_config.luau`**, bukan nama file atau ID.

```lua
local AssetManager = require(game.ReplicatedStorage.Shared.AssetManager)

-- Mengambil ID gambar
local iconId = AssetManager.get("Coin_ico") -- -> "rbxassetid://987654321"

-- Mengambil objek Suara (sudah di-preload dan di-cache)
local clickSound = AssetManager.get("BUTTON_CLICK")
clickSound:Play()

-- Men-spawn klon dari sebuah model
local newFish = AssetManager.spawn("Goldfish", Vector3.new(10, 5, 0))
```

Sistem ini memastikan bahwa semua aset dikelola dari satu lokasi terpusat, membuat proyek lebih mudah dipelihara dan diskalakan.
