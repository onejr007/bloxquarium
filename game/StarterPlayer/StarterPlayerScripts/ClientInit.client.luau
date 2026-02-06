--[[
	ClientInit.client.luau
	Contoh bagaimana menggunakan AssetManager baru yang lebih sistematis.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage.Shared

-- Cukup require AssetManager, satu-satunya handler yang Anda perlukan.
local AssetManager = require(SharedModules.AssetManager)
-- INTEGRASI: Impor RemoteClient untuk komunikasi yang aman
local RemoteClient = require(SharedModules.RemoteClient)

print("🚀 [ClientInit] Menggunakan AssetManager baru...")

-- Tunggu beberapa detik hingga semua aset selesai di-load oleh AssetLoader
wait(5)

-- Contoh 1: Mendapatkan ID Gambar
print("\n-- Contoh 1: Mendapatkan ID Gambar --")
local coinIconId = AssetManager.get("Coin_ico")
if coinIconId then
	print(string.format("✅ Berhasil mendapatkan ID gambar 'Coin_ico': %s", coinIconId))
end

-- Contoh 2: Mendapatkan dan Memainkan Suara
print("\n-- Contoh 2: Mendapatkan dan Memainkan Suara --")
local buttonClickSound = AssetManager.get("BUTTON_CLICK")
if buttonClickSound then
	print("✅ Berhasil mendapatkan objek Sound 'BUTTON_CLICK' dari cache.")
	print("   - Volume:", buttonClickSound.Volume)
	print("   - Looped:", buttonClickSound.Looped)
	
	-- Mainkan suara (Anda mungkin perlu menambahkannya ke Workspace atau GUI agar terdengar)
	buttonClickSound.Parent = workspace
	-- buttonClickSound:Play()
	print("   -> Siap dimainkan!")

	-- Jika Anda butuh instance baru (untuk dimainkan bersamaan), gunakan getClone()
	local newClickSound = AssetManager.getClone("BUTTON_CLICK")
	print("\n✅ Berhasil mendapatkan CLONE dari 'BUTTON_CLICK'. Ini adalah instance yang berbeda.")
end

-- Contoh 3: Men-spawn Model
print("\n-- Contoh 3: Men-spawn Model --")
-- Coba spawn model ikan, misalnya 'Goldfish'. Pastikan model ini ada di assets/models.
local fishName = "Goldfish" -- Ganti dengan nama model yang ada di proyek Anda
if AssetManager.get(fishName) then -- Cek dulu apakah asetnya ada
	print(string.format("✅ Aset model '%s' ditemukan. Men-spawn..."), fishName)
	local newFish = AssetManager.spawn(fishName, Vector3.new(0, 5, -10))
	if newFish then
		print(string.format("   -> Berhasil men-spawn '%s' di posisi %s", fishName, tostring(newFish.PrimaryPart.Position)))
	end
else
	print(string.format("🟡 Model dengan nama '%s' tidak ditemukan. Contoh spawn dilewati.", fishName))
end

print("\n✨ [ClientInit] Demo AssetManager selesai! ✨")

-- INTEGRASI: Memberi tahu server bahwa klien telah selesai memuat dan siap.
-- Ini menggunakan sistem RemoteService yang aman dengan validasi nonce.
print("\n🔌 [RemoteClient] Mengirim sinyal 'PlayerReady' ke server...")
RemoteClient:FireServer("PlayerReady")
print("✅ [RemoteClient] Sinyal terkirim. Server sekarang tahu kita siap.")
