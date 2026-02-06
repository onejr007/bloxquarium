--[[
    ExampleClientAction.client.luau

    Contoh LocalScript yang menunjukkan cara memanggil aksi server yang aman
    dari sisi klien menggunakan modul RemoteClient.
]]

--=================[ SERVICES ]=================--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--=================[ MODULES ]=================--
-- Impor modul klien yang bertanggung jawab untuk komunikasi aman dengan server.
local RemoteClient = require(ReplicatedStorage.Shared.RemoteClient)

--=================[ CONTOH AKSI ]=================--

-- Bayangkan skrip ini berada di dalam sebuah tombol GUI "Beli Goldfish".
-- Kita akan menghubungkan ini ke event MouseButton1Click tombol tersebut.

local function onBuyGoldfishClick()
    local itemIdToBuy = "Goldfish"
    
    print(string.format("🐠 [Client] Mencoba membeli item: %s", itemIdToBuy))
    
    -- Panggil server menggunakan RemoteClient.
    -- Argumen pertama adalah nama event yang terdaftar di ServerInit.server.luau
    -- Argumen berikutnya adalah parameter untuk fungsi tersebut (dalam hal ini, itemId).
    -- RemoteClient akan secara otomatis menangani pembuatan nonce yang aman.
    RemoteClient:FireServer("GameAction_BuyItem", itemIdToBuy)
    
    print("✅ [Client] Permintaan pembelian terkirim ke server.")
end

-- =======================================================================
-- MODIFIKASI: Semua aksi pembelian dinonaktifkan untuk validasi data murni.
print("🔧 [ExampleClientAction] Mode Validasi Data: Semua aksi pembelian telah dinonaktifkan.")
-- =======================================================================

-- Untuk tujuan demonstrasi, kita akan memanggil fungsi ini 3 detik setelah pemain bergabung.
-- Dalam game nyata, Anda akan menghubungkan ini ke event GUI, seperti:
-- buyButton.MouseButton1Click:Connect(onBuyGoldfishClick)
-- task.wait(3)
-- onBuyGoldfishClick()

-- CONTOH PENANGANAN INPUT YANG BURUK (YANG SEKARANG AMAN KARENA VALIDASI SERVER)
-- Seorang peretas mungkin mencoba memanggil ini dengan argumen palsu dari exploit mereka:
-- task.wait(1)
-- print("👿 [Client] Peretas mencoba membeli item palsu...")
-- RemoteClient:FireServer("GameAction_BuyItem", "LegendaryAdminSword") -- Server akan menolak ini karena "LegendaryAdminSword" tidak ada di tabel harga GameActions.

-- task.wait(1)
-- print("👿 [Client] Peretas mencoba membeli tanpa cukup koin...")
-- Misalkan pemain hanya punya 100 koin, tetapi mencoba membeli item seharga 200.
-- RemoteClient:FireServer("GameAction_BuyItem", "TreasureChest") -- Server akan menolak ini karena validasi koin di GameActions akan gagal.
