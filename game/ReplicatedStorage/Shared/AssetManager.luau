--[[
	AssetManager.luau
	
	Satu-satunya interface yang dibutuhkan developer untuk berinteraksi dengan semua jenis aset.
	Menyediakan API yang sistematis, mudah digunakan, dan memiliki caching cerdas.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetLoader = require(script.Parent.AssetLoader)

local AssetManager = {}

-- Cache untuk aset yang sudah diproses (misalnya, objek Sound yang sudah dibuat)
local processedAssetCache = {}

--[[
	Fungsi utama untuk mendapatkan aset apa pun.
	Secara cerdas menentukan tindakan yang benar berdasarkan jenis aset.

	@param assetName Nama aset yang akan didapatkan.
	@return Beragam, tergantung pada jenis aset:
		- Instance (Model/Part): Mengembalikan clone dari model.
		- string (Image/Decal ID): Mengembalikan asset ID.
		- Sound (dari config): Mengembalikan objek Sound yang telah di-cache dan siap digunakan.
]]
function AssetManager.get(assetName)
	local asset = AssetLoader.GetAsset(assetName, true) -- true untuk auto-preload

	if not asset then
		warn(string.format("[AssetManager] Aset '%s' tidak ditemukan!", assetName))
		return nil
	end

	local assetType = typeof(asset)

	-- 1. Jika aset adalah sebuah Instance (Model, Part)
	if assetType == "Instance" then
		return asset:Clone()
	end

	-- 2. Jika aset adalah sebuah string (Image ID, Decal ID)
	if assetType == "string" then
		return asset
	end

	-- 3. Jika aset adalah sebuah tabel (Sound dari config)
	if assetType == "table" and asset.id then
		-- Cek apakah objek Sound sudah ada di cache
		if processedAssetCache[assetName] then
			return processedAssetCache[assetName]
		end

		-- Jika tidak, buat objek Sound, konfigurasikan, dan simpan di cache
		print(string.format("[AssetManager] Membuat dan caching objek Sound untuk '%s'", assetName))
		local sound = Instance.new("Sound")
		sound.Name = assetName
		sound.SoundId = asset.id
		sound.Volume = asset.volume or 1
		sound.Looped = asset.looped or false
		
		processedAssetCache[assetName] = sound
		return sound
	end

	warn(string.format("[AssetManager] Jenis aset tidak dikenal untuk '%s'", assetName))
	return asset
end

--[[
	Secara spesifik mendapatkan clone dari sebuah aset. Sangat berguna untuk suara
	yang perlu dimainkan secara bersamaan (overlapping).

	@param assetName Nama aset yang akan di-clone.
	@return Clone dari aset yang diminta.
]]
function AssetManager.getClone(assetName)
	local asset = AssetManager.get(assetName)
	if not asset then return nil end

	if typeof(asset) == "Instance" or typeof(asset) == "Sound" then
		return asset:Clone()
	else
		-- Aset seperti ID gambar (string) tidak bisa di-clone, jadi kembalikan saja nilainya
		return asset
	end
end

--[[
	Shortcut untuk men-spawn model ke dalam workspace (atau parent lain) dengan posisi tertentu.

	@param assetName Nama model yang akan di-spawn.
	@param position Vector3 opsional untuk posisi spawn.
	@param parent Instance opsional sebagai parent dari model.
]]
function AssetManager.spawn(assetName, position, parent)
	local model = AssetManager.get(assetName)

	if not (model and model:IsA("Model")) then
		warn(string.format("[AssetManager] Tidak bisa spawn '%s', karena bukan sebuah Model.", assetName))
		return nil
	end

	model.Parent = parent or workspace
	if position and model.PrimaryPart then
		model:SetPrimaryPartCFrame(CFrame.new(position))
	end
	
	return model
end

return AssetManager
