# Assets

Folder ini berisi semua asset files yang akan otomatis di-mapping ke ReplicatedStorage.Assets.

## Struktur:
- `models/` - Model files (.rbxm, .obj, dll)
- `sounds/` - Audio files (.mp3, .ogg, dll)  
- `images/` - Image files (.png, .jpg, dll)
- `animations/` - Animation files (.rbxm)

## Cara Penggunaan:

### 1. Tambahkan Asset
Letakkan file asset di folder yang sesuai:
```
assets/
├── models/
│   ├── Tree.rbxm
│   └── House.rbxm
├── sounds/
│   ├── BackgroundMusic.mp3
│   └── ClickSound.ogg
├── images/
│   ├── Logo.png
│   └── Icon.jpg
└── animations/
    └── WalkAnimation.rbxm
```

### 2. Akses dari Script
```lua
-- Akses model
local AssetManager = require(game.ReplicatedStorage.Shared.AssetManager)
local tree = AssetManager.Clone("Tree")
tree.Parent = workspace

-- Akses sound
local sound = game.ReplicatedStorage.Assets.Sounds.BackgroundMusic
sound:Play()

-- Akses image
local imageLabel = Instance.new("ImageLabel")
imageLabel.Image = game.ReplicatedStorage.Assets.Images.Logo
```

## Tips:
- Asset akan otomatis ter-detect dan di-register oleh Asset System
- Nama file akan menjadi nama asset (tanpa ekstensi)
- Gunakan nama file yang deskriptif dan konsisten
- Asset system akan otomatis pre-load untuk performance