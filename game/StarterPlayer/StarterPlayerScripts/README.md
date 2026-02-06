# StarterPlayerScripts

Folder ini berisi semua client-side scripts yang berjalan di setiap player.

## Struktur File:
- `*.client.luau` - Client scripts yang akan dijalankan otomatis di setiap player
- `*.luau` - LocalScripts atau ModuleScripts

## Contoh Penggunaan:

### Client Script
```lua
-- MyClientScript.client.luau
print("Client script berjalan untuk player:", game.Players.LocalPlayer.Name)

-- Akses shared modules
local AssetManager = require(game.ReplicatedStorage.Shared.AssetManager)

-- Handle player input
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        print("Player pressed E!")
    end
end)
```

### Local Script
```lua
-- MyLocalScript.luau
-- Ini akan menjadi LocalScript di Roblox
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("Local script untuk:", player.Name)
```

## Tips:
- File dengan ekstensi `.client.luau` akan otomatis dijalankan sebagai LocalScript
- Scripts di sini berjalan untuk setiap player yang join
- Gunakan untuk UI, input handling, dan client-side logic