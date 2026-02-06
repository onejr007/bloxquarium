# StarterGui

Folder ini berisi semua GUI elements yang akan diberikan ke setiap player saat spawn.

## Struktur File:
- `*.luau` - LocalScripts untuk GUI
- Folder untuk ScreenGui dan components

## Contoh Penggunaan:

### GUI Script
```lua
-- MainGui.client.luau
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainGui"
screenGui.Parent = playerGui

-- Buat Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.Parent = screenGui

-- Buat TextLabel
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.Text = "Hello, " .. player.Name .. "!"
label.TextColor3 = Color3.new(1, 1, 1)
label.BackgroundTransparency = 1
label.Parent = frame
```

## Tips:
- GUI yang dibuat di sini akan otomatis diberikan ke setiap player
- Gunakan untuk HUD, menu, dan interface elements
- Bisa berisi ScreenGui, LocalScripts, dan ModuleScripts