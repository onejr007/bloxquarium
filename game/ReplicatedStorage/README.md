# ReplicatedStorage

Folder ini berisi semua shared resources yang bisa diakses dari server dan client.

## Struktur:
- `Shared/` - ModuleScripts yang bisa di-require dari server dan client
- `Assets/` - Asset files (models, sounds, images, animations)

## Contoh Penggunaan:

### Shared Module
```lua
-- MySharedModule.luau
local MySharedModule = {}

MySharedModule.CONSTANTS = {
    MAX_PLAYERS = 50,
    GAME_VERSION = "1.0.0"
}

function MySharedModule.CalculateDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

return MySharedModule
```

### Menggunakan dari Server
```lua
-- Di ServerScriptService
local MySharedModule = require(game.ReplicatedStorage.MySharedModule)
print("Game version:", MySharedModule.CONSTANTS.GAME_VERSION)
```

### Menggunakan dari Client
```lua
-- Di StarterPlayerScripts
local MySharedModule = require(game.ReplicatedStorage.MySharedModule)
local distance = MySharedModule.CalculateDistance(Vector3.new(0,0,0), Vector3.new(10,0,0))
```

## Tips:
- Semua file di sini bisa diakses dari server dan client
- Gunakan untuk shared utilities, constants, dan configurations
- Asset system otomatis mapping dari folder `assets/`