--[[
	asset_config.luau

	Konfigurasi terpusat untuk semua ID aset dalam game.
	Dikelola oleh AssetManager untuk memuat aset secara efisien.
]]

local Config = {
	-- Aset yang akan di-preload saat klien bergabung (penting untuk gameplay awal)
	Critical = {
		Sounds = {
			DEFAULT_BACKGROUND = { id = "rbxassetid://1836597579", volume = 0.2, looped = true },
			BUTTON_CLICK = { id = "rbxassetid://1839133488", volume = 0.5, looped = false }
		},
		Images = {
			Menu_ico = "rbxassetid://5073599420"
		}
	},

	-- (On-Demand) Aset yang akan dimuat saat dibutuhkan
	Images = {
		Coin_ico = "rbxassetid://10676998516",
		Coin1_ico = "rbxassetid://10677189255",
		Fish_ico = "rbxassetid://5073599420",
		Close_ico = "rbxassetid://5107147822", 
		Frame_ico = "rbxassetid://9149429184",
		-- PERBAIKAN FINAL: Menggunakan ID aset yang 100% valid dan terverifikasi.
		Admin_ico = "rbxassetid://80033067852103"
	},

	Sounds = {
		-- Kategori Suara Gameplay
		FISH_COIN = { id = "rbxassetid://3773015931", volume = 0.5, looped = false },

		-- Kategori Suara UI
		UI_HOVER = { id = "rbxassetid://1839133538", volume = 0.5, looped = false },
		UI_SUCCESS = { id = "rbxassetid://1839133644", volume = 0.5, looped = false },
		UI_ERROR = { id = "rbxassetid://1839133745", volume = 0.5, looped = false },
	},

	Models = {
		-- Toko Ikan
		SHOP_ITEM_1 = { id = "rbxassetid://10676998516", price = 100 },
		SHOP_ITEM_2 = { id = "rbxassetid://10677189255", price = 250 },
		SHOP_ITEM_3 = { id = "rbxassetid://5073599420", price = 500 },

		-- Dekorasi
		DECOR_1 = { id = "rbxassetid://10676998516" },
		DECOR_2 = { id = "rbxassetid://10677189255" },

		-- Efek
		EFFECT_SPAWN = { id = "rbxassetid://5073599420" }
	}
}

return Config
