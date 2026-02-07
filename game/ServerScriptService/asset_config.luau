--[[
	asset_config.luau (v2 - STRUCTURE FIX)

	- CRITICAL FIX: Restructured the entire config to avoid duplicate keys (e.g., 'Images').
	- Lua tables were overwriting keys, causing the AssetManager to receive a corrupted/incomplete list.
	- All assets are now merged under a single category key, and a separate 'CriticalAssetNames' list is used to identify which ones to preload.
	- This is the definitive fix for the preloading and caching failure.
]]

local Config = {

    -- This table now ONLY contains the NAMES of assets to be preloaded.
    -- The AssetManager will look up these names in the tables below.
	CriticalAssetNames = {
        "DEFAULT_BACKGROUND",
        "BUTTON_CLICK",
        "Menu_ico",
        "Admin_ico"
    },

	Images = {
        -- Critical Assets
        Menu_ico = "rbxassetid://5073599420",
		Admin_ico = "rbxassetid://80033067852103",

        -- On-Demand Assets
		Coin_ico = "rbxassetid://10676998516",
		Coin1_ico = "rbxassetid://10677189255",
		Fish_ico = "rbxassetid://5073599420",
		Close_ico = "rbxassetid://5107147822", 
		Frame_ico = "rbxassetid://9149429184"
	},

	Sounds = {
        -- Critical Assets
        DEFAULT_BACKGROUND = { id = "rbxassetid://1836597579", volume = 0.2, looped = true },
		BUTTON_CLICK = { id = "rbxassetid://1839133488", volume = 0.5, looped = false },

		-- On-Demand Assets (Gameplay)
		FISH_COIN = { id = "rbxassetid://3773015931", volume = 0.5, looped = false },

		-- On-Demand Assets (UI)
		UI_HOVER = { id = "rbxassetid://1839133538", volume = 0.5, looped = false },
		UI_SUCCESS = { id = "rbxassetid://1839133644", volume = 0.5, looped = false },
		UI_ERROR = { id = "rbxassetid://1839133745", volume = 0.5, looped = false },
	},

	Models = {
		-- Fish Store
		SHOP_ITEM_1 = { id = "rbxassetid://10676998516", price = 100 },
		SHOP_ITEM_2 = { id = "rbxassetid://10677189255", price = 250 },
		SHOP_ITEM_3 = { id = "rbxassetid://5073599420", price = 500 },

		-- Decorations
		DECOR_1 = { id = "rbxassetid://10676998516" },
		DECOR_2 = { id = "rbxassetid://10677189255" },

		-- Effects
		EFFECT_SPAWN = { id = "rbxassetid://5073599420" }
	}
}

return Config
