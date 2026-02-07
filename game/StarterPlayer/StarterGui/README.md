# StarterGui

Folder ini berisi semua elemen Antarmuka Pengguna Grafis (GUI) (`ScreenGui`, `LocalScript`, dll.) yang secara otomatis diberikan kepada setiap pemain saat mereka bergabung dengan permainan.

## Struktur File

- **ScreenGuis**: Setiap `ScreenGui` utama harus menjadi turunannya sendiri di sini.
- **Skrip Lokal**: Skrip di dalam elemen GUI harus menangani interaksi pengguna, animasi, dan komunikasi dengan server.
- **Folder**: Atur elemen GUI yang terkait ke dalam folder untuk kejelasan (misalnya, folder `ShopMenu` untuk semua bagian dari UI toko).

---

## Contoh Alur Kerja: Tombol GUI yang Berkomunikasi dengan Server

Skrip GUI tidak boleh berisi logika permainan penting. Sebaliknya, mereka harus meminta server untuk melakukan tindakan menggunakan modul `RemoteClient` bersama.

### Contoh: Skrip untuk Tombol "Beli"

Misalkan kita memiliki `TextButton` bernama `BuyButton` di dalam `ScreenGui`.

```lua
-- Di dalam LocalScript yang merupakan anak dari BuyButton

local button = script.Parent

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Impor modul klien penting
local RemoteClient = require(ReplicatedStorage.Shared.RemoteClient)

-- 2. Dengarkan peristiwa klik tombol
button.MouseButton1Click:Connect(function()
    local itemIdToBuy = "SpecialHealthPotion"
    print(string.format("Tombol beli diklik. Meminta server untuk membeli item: %s", itemIdToBuy))

    -- 3. Gunakan RemoteClient untuk memanggil fungsi server dengan aman
    -- Ini memanggil fungsi "GameAction_BuyItem" yang terdaftar di server.
    local success, message = RemoteClient:invoke("GameAction_BuyItem", itemIdToBuy)

    if success then
        -- Beri pemain umpan balik di GUI
        print("Server mengonfirmasi pembelian! Pesan:", message)
        button.Text = "Dibeli!"
    else
        -- Tampilkan pesan kesalahan di GUI
        warn("Server menolak pembelian! Alasan:", message)
        button.Text = "Gagal!"
    end
end)
```

## Praktik Terbaik

- **Pemisahan Logika**: Jaga agar logika UI (apa yang dilihat pemain) terpisah dari logika permainan (apa yang terjadi di server).
- **Gunakan RemoteClient**: Untuk semua tindakan yang memengaruhi permainan (membeli, menjual, menyimpan), gunakan `RemoteClient` untuk meminta server melakukannya.
- **Berikan Umpan Balik**: Selalu beri tahu pemain apa yang terjadi. Jika mereka mengklik tombol, tunjukkan kepada mereka bahwa itu berfungsi atau mengapa tidak.
