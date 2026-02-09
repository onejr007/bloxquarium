-- loading_config.luau
-- Mendefinisikan proses pemuatan multi-fase yang terstruktur untuk klien.
-- AssetManager akan memproses setiap fase dalam urutan yang ditentukan di sini.

local Config = {
    -- Mendefinisikan urutan fase pemuatan.
    LoadingPhases = {
        {
            PhaseName = "UI Inti & Sistem",
            Description = "Elemen UI esensial dan suara inti yang diperlukan untuk menu utama.",
            AssetNames = {
                "DEFAULT_BACKGROUND",
                "BUTTON_CLICK",
                "Menu_ico",
                "Admin_ico",
                "Close_ico",
                "Frame_ico",
            }
        },
        {
            PhaseName = "Toko & Item",
            Description = "Aset yang terkait dengan ikon toko dan item yang dapat dibeli.",
            AssetNames = {
                "Coin_ico",
                "Coin1_ico",
                "Fish_ico",
                "Egg_ico",
                "Shop_BACKGROUND",
            }
        },
        {
            PhaseName = "Dunia & Dekorasi",
            Description = "Aset lingkungan dan efek akuarium.",
            AssetNames = {
                "BUBBLE",
                "FISH_SPAWN",
            }
        },
    },

    -- Opsional: Daftar modul di ReplicatedStorage untuk di-require() selama pemuatan.
    -- Ini dapat digunakan untuk menginisialisasi sistem sisi klien dalam urutan tertentu.
    ModuleInitOrder = {
        "Shared/Promise",
        "Shared/RemoteClient",
        "Shared/SystemValidator",
        "Shared/ClientState",
    }
}

return Config
