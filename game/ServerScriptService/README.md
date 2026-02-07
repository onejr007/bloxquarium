# ServerScriptService (Arsitektur v2)

Folder ini berisi semua logika sisi server, yang diatur ke dalam arsitektur layanan modular.

## Struktur File

- **`ServerInit.server.luau`**: Titik masuk UTAMA untuk semua kode sisi server. Satu-satunya tugasnya adalah memuat dan menjalankan `ServiceLoader`.

- **`ServiceLoader.luau`**: Inti dari server. Modul ini secara otomatis menemukan, memuat (`require`), dan menginisialisasi semua modul layanan dari folder `Services` dalam urutan yang telah ditentukan. Ia juga menangani **Dependency Injection**.

- **`Services/`**: Direktori ini berisi semua fungsionalitas inti server, di mana setiap file adalah `ModuleScript` yang mewakili satu layanan.

## Alur Kerja: Menambahkan Fungsionalitas Server Baru

Untuk menambahkan fitur sisi server baru, jangan letakkan skrip acak di sini. Sebagai gantinya, ikuti arsitektur layanan:

1.  **Buat Modul Layanan Baru**:
    Buat file `ModuleScript` baru di dalam direktori `Services/` (misalnya, `InventoryService.luau`). Modul ini harus mengembalikan tabel dengan setidaknya metode `Init`.

    ```lua
    -- game/ServerScriptService/Services/InventoryService.luau
    local InventoryService = {}

    -- Init adalah tempat Anda mengatur segalanya.
    -- Jika Anda membutuhkan layanan lain (seperti RemoteService), tambahkan sebagai parameter.
    function InventoryService:Init(RemoteService)
        print("[InventoryService] Diinisialisasi!")
        -- Gunakan RemoteService untuk mendaftarkan remotes di sini
    end

    return InventoryService
    ```

2.  **Daftarkan di ServiceLoader**:
    Buka `ServiceLoader.luau` dan tambahkan nama modul layanan baru Anda ke tabel `INIT_ORDER`. Urutannya penting untuk dependensi!

    ```lua
    -- game/ServerScriptService/ServiceLoader.luau
    local INIT_ORDER = {
        -- ... layanan yang ada
        "InventoryService" -- Tambahkan layanan Anda
    }
    ```

Dengan mengikuti pola ini, Anda memastikan bahwa kode Anda teratur, dapat dipelihara, dan terintegrasi dengan benar dengan sisa server.
