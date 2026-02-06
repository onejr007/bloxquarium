-- Konfigurasi Aset Terpusat (v2 - Dengan Preload Prioritas)
--[[ 
    Struktur Baru:
    - Preload: Aset kritis yang dimuat selama loading screen awal. Jaga agar tetap sedikit!
    - Images, Sounds, dll: Aset on-demand yang dimuat saat pertama kali diminta.
]]
return {
	-- (WAJIB) Aset yang harus ada sebelum game bisa dimainkan
	Preload = {
		DEFAULT_BACKGROUND = "rbxassetid://5922319985",
		BUTTON_CLICK = { id = "rbxassetid://6725330394", volume = 0.8, looped = false },
		Menu_ico = "rbxassetid://5073599420", -- Contoh ikon UI penting
	},

	-- (On-Demand) Aset yang akan dimuat saat dibutuhkan
	Images = {
		Coin_ico = "rbxassetid://10676998516",
		Coin1_ico = "rbxassetid://10677189255",
		Fish_ico = "rbxassetid://5073599420",
		Close_ico = "rbxassetid://5073599420", 
		Frame_ico = "rbxassetid://5073599420", 
	},

	Sounds = {
		-- Kategori Suara Gameplay
		FISH_COIN = { id = "rbxassetid://3773015931", volume = 0.5, looped = false },
		FISH_DEATH = { id = "rbxassetid://152269963", volume = 0.7, looped = false },
		FISH_EAT = { id = "rbxassetid://161242139", volume = 0.6, looped = false },
		FISH_SPAWN = { id = "rbxassetid://131972793", volume = 0.8, looped = false },
		BUBBLE = { id = "rbxassetid://122216439", volume = 0.4, looped = false },

		-- Kategori Suara UI & Gacha
		GACHA_ROLL = { id = "rbxassetid://10822051217", volume = 1, looped = true },
		GACHA_WIN = { id = "rbxassetid://10822055660", volume = 1, looped = false },
		OPEN_AQUARIUM = { id = "rbxassetid://1107599033", volume = 1, looped = false },

		-- Kategori Suara Boss & Bonus
		BOSS_SPAWN = { id = "rbxassetid://264879633", volume = 1, looped = false },
		BOSS_CLICK = { id = "rbxassetid://132224229", volume = 1, looped = false },
		BOSS_EAT = { id = "rbxassetid://132224203", volume = 1, looped = false },
		BOSS_FIGHTING = { id = "rbxassetid://184738593", volume = 0.9, looped = true },
		BOSS_WARNING = { id = "rbxassetid://264879519", volume = 1, looped = true },
		BONUS_TIME = { id = "rbxassetid://5151379331", volume = 1, looped = true },
		BONUS_CLICK = { id = "rbxassetid://893048092", volume = 1, looped = false },
		BONUS_CLICK_EGG = { id = "rbxassetid://476319401", volume = 1, looped = false },
		BONUS_TIME_CD = { id = "rbxassetid://912368945", volume = 1, looped = false },
		BONUS_RESULT = { id = "rbxassetid://5425356610", volume = 2, looped = false },
		FOOD_DROP = { id = "rbxassetid://3773015931", volume = 1, looped = false },
	},

	Decals = {},
	Animations = {}
}
