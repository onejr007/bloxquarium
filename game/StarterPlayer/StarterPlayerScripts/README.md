# StarterPlayerScripts

Folder ini berisi semua skrip sisi klien (`LocalScript`) yang berjalan di perangkat setiap pemain. Gunakan untuk menangani input, mengelola UI, dan berkomunikasi dengan server.

## Struktur File

- **`*.client.luau`**: File-file ini secara otomatis dijalankan sebagai `LocalScript` untuk setiap pemain.
- **`*.luau`**: Ini akan diperlakukan sebagai `ModuleScript` yang dapat Anda `require` dari skrip klien lain.
- **Sub-folder**: Gunakan folder untuk mengatur logika klien berdasarkan fitur (misalnya, `UI`, `Input`).

---

## Contoh Alur Kerja: Berkomunikasi dengan Server

Skrip klien tidak boleh mencoba berkomunikasi dengan server secara langsung. Sebaliknya, mereka harus menggunakan modul `RemoteClient` bersama, yang menangani semua komunikasi jaringan.

### Contoh: Mengirim Permintaan ke Server

```lua
-- game/StarterPlayer/StarterPlayerScripts/InputHandler.client.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- 1. Impor modul RemoteClient
local RemoteClient = require(ReplicatedStorage.Shared.RemoteClient)

print("Input Handler dimuat. Tekan 'B' untuk mencoba membeli item.")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.B then
        print("Tombol 'B' ditekan. Mengirim permintaan pembelian ke server...")
        
        -- 2. Panggil fungsi server menggunakan RemoteClient
        -- Ini memanggil invoke "GameAction_BuyItem" yang terdaftar di server.
        local success, message = RemoteClient:invoke("GameAction_BuyItem", "MagicSword")

        if success then
            print("Server merespons dengan sukses:", message)
        else
            warn("Server merespons dengan kesalahan:", message)
        end
    end
end)
```

## Praktik Terbaik

- **Jangan Percayai Klien**: Logika gameplay penting (seperti memberikan item atau mata uang) harus **selalu** dilakukan di server. Klien hanya boleh mengirim permintaan.
- **Tetap Teratur**: Gunakan folder untuk mengelompokkan skrip Anda berdasarkan fungsionalitasnya (misalnya, folder `UI` untuk semua skrip yang terkait dengan antarmuka pengguna).
- **Gunakan Modul**: Pisahkan kode Anda menjadi modul-modul yang dapat digunakan kembali jika memungkinkan.
