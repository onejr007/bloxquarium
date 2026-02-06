# 🚀 Quick Start Guide - Bloxquarium

Panduan cepat untuk mulai menggunakan struktur folder Roblox Explorer dengan Rojo.

## 📂 Dimana Menempatkan Script?

### Server Scripts (Berjalan di Server)
```
📁 game/ServerScriptService/
├── 📄 MyScript.server.luau        # Server script utama
├── 📄 DataHandler.server.luau     # Handle data player
├── 📁 Systems/                    # Folder untuk sistem
│   ├── 📄 Economy.server.luau     # Sistem ekonomi
│   └── 📄 Combat.server.luau      # Sistem combat
└── 📄 README.md                   # Dokumentasi
```

### Client Scripts (Berjalan di Player)
```
📁 game/StarterPlayer/StarterPlayerScripts/
├── 📄 MainClient.client.luau      # Client script utama
├── 📄 InputHandler.client.luau    # Handle input player
├── 📁 UI/                         # Folder untuk UI scripts
│   ├── 📄 MainMenu.client.luau    # Menu utama
│   └── 📄 HUD.client.luau         # HUD game
└── 📄 README.md                   # Dokumentasi
```

### GUI Elements
```
📁 game/StarterPlayer/StarterGui/
├── 📄 MainGui.client.luau         # GUI script
├── 📁 Menus/                      # Folder untuk menu
│   ├── 📄 SettingsMenu.luau       # Menu settings
│   └── 📄 ShopMenu.luau           # Menu shop
└── 📄 README.md                   # Dokumentasi
```

### Shared Modules (Diakses Server & Client)
```
📁 game/ReplicatedStorage/
├── 📁 Shared/                     # Modules yang bisa diakses semua
│   ├── 📄 AssetManager.luau       # Asset system (sudah ada)
│   ├── 📄 Utils.luau              # Utility functions
│   ├── 📄 Constants.luau          # Game constants
│   └── 📄 Config.luau             # Game configuration
└── 📄 README.md                   # Dokumentasi
```

### Loading Scripts (Load Pertama)
```
📁 game/ReplicatedFirst/
├── 📄 LoadingScreen.client.luau   # Loading screen
├── 📄 PreLoader.client.luau       # Pre-load assets
└── 📄 README.md                   # Dokumentasi
```

### Game World Objects
```
📁 game/Workspace/
├── 📄 SpawnLocation.luau          # Spawn point
├── 📁 Buildings/                  # Folder untuk bangunan
│   ├── 📄 Shop.luau               # Toko
│   └── 📄 Bank.luau               # Bank
└── 📄 README.md                   # Dokumentasi
```

### Assets (Models, Sounds, Images)
```
📁 assets/
├── 📁 models/                     # Model files
│   ├── 📄 Tree.rbxm               # Model pohon
│   └── 📄 House.rbxm              # Model rumah
├── 📁 sounds/                     # Audio files
│   ├── 📄 BGM.mp3                 # Background music
│   └── 📄 Click.ogg               # Click sound
├── 📁 images/                     # Image files
│   ├── 📄 Logo.png                # Game logo
│   └── 📄 Icon.jpg                # Game icon
└── 📁 animations/                 # Animation files
    └── 📄 Walk.rbxm               # Walk animation
```

## 🎯 Contoh Workflow

### 1. Membuat Server Script Baru
```lua
-- 📁 game/ServerScriptService/PlayerManager.server.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import shared modules
local AssetManager = require(ReplicatedStorage.Shared.AssetManager)
local Utils = require(ReplicatedStorage.Shared.Utils)

Players.PlayerAdded:Connect(function(player)
    print("Player joined:", player.Name)
    
    -- Spawn welcome asset
    AssetManager.Spawn("WelcomeSign", Vector3.new(0, 10, 0))
end)
```

### 2. Membuat Client Script Baru
```lua
-- 📁 game/StarterPlayer/StarterPlayerScripts/InputManager.client.luau
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import shared modules
local Utils = require(ReplicatedStorage.Shared.Utils)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        print("Player pressed E!")
        -- Do something
    end
end)
```

### 3. Membuat Shared Module Baru
```lua
-- 📁 game/ReplicatedStorage/Shared/Utils.luau
local Utils = {}

function Utils.FormatNumber(number)
    return string.format("%.2f", number)
end

function Utils.GetRandomColor()
    return Color3.new(math.random(), math.random(), math.random())
end

function Utils.WaitForChild(parent, childName, timeout)
    timeout = timeout or 5
    local startTime = tick()
    
    while not parent:FindFirstChild(childName) do
        if tick() - startTime > timeout then
            warn("Timeout waiting for child:", childName)
            return nil
        end
        wait(0.1)
    end
    
    return parent:FindFirstChild(childName)
end

return Utils
```

### 4. Menggunakan Assets
```lua
-- Dari script manapun
local AssetManager = require(game.ReplicatedStorage.Shared.AssetManager)

-- Spawn model
local tree = AssetManager.Clone("Tree")
tree.Parent = workspace
tree.Position = Vector3.new(10, 0, 10)

-- Play sound
local sound = game.ReplicatedStorage.Assets.Sounds.BGM
sound:Play()
```

## ⚡ Commands Rojo

### Build Project
```bash
rojo build -o "bloxquarium.rbxlx"
```

### Start Development Server
```bash
rojo serve
```

### Build untuk Production
```bash
rojo build -o "bloxquarium_release.rbxlx"
```

## 🔧 Tips & Tricks

### 1. Naming Convention
- **Server Scripts**: `NamaScript.server.luau`
- **Client Scripts**: `NamaScript.client.luau`
- **Modules**: `NamaModule.luau`
- **Folders**: `PascalCase` (contoh: `PlayerSystems`)

### 2. Organisasi Folder
- Gunakan folder untuk mengelompokkan script berdasarkan fitur
- Buat README.md di setiap folder untuk dokumentasi
- Pisahkan server dan client logic dengan jelas

### 3. Import Modules
```lua
-- Selalu gunakan path lengkap untuk clarity
local AssetManager = require(game.ReplicatedStorage.Shared.AssetManager)
local Utils = require(game.ReplicatedStorage.Shared.Utils)
```

### 4. Error Handling
```lua
-- Gunakan pcall untuk error handling
local success, result = pcall(function()
    return AssetManager.Clone("MyModel")
end)

if success then
    result.Parent = workspace
else
    warn("Failed to clone model:", result)
end
```

## 🎮 Ready to Code!

Sekarang Anda sudah siap untuk mulai coding! Struktur folder sudah siap dan Rojo akan otomatis mapping semua file ke tempat yang tepat di Roblox Studio.

**Happy Coding! 🚀**