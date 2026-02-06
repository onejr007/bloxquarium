# ServerScriptService

Folder ini berisi semua server-side scripts yang berjalan di server.

## Struktur File:
- `*.server.luau` - Server scripts yang akan dijalankan otomatis
- `*.luau` - ModuleScripts yang bisa di-require oleh script lain

## Contoh Penggunaan:

### Server Script
```lua
-- MyScript.server.luau
print("Server script berjalan!")

-- Akses shared modules
local AssetManager = require(game.ReplicatedStorage.Shared.AssetManager)
```

### Module Script
```lua
-- MyModule.luau
local MyModule = {}

function MyModule.DoSomething()
    print("Module function called!")
end

return MyModule
```

## Tips:
- File dengan ekstensi `.server.luau` akan otomatis dijalankan sebagai server script
- File dengan ekstensi `.luau` akan menjadi ModuleScript
- Gunakan folder untuk mengorganisir script berdasarkan fitur