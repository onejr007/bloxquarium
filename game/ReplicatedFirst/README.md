# ReplicatedFirst

Folder ini berisi scripts yang harus dijalankan PERTAMA KALI sebelum game dimuat.

## Kegunaan:
- Loading screens
- Essential initialization
- Pre-game setup
- Asset preloading

## Contoh Penggunaan:

### Loading Screen
```lua
-- LoadingScreen.client.luau
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Buat loading screen
local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "LoadingScreen"
loadingGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.Parent = loadingGui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.Text = "Loading..."
label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true
label.BackgroundTransparency = 1
label.Parent = frame

-- Wait for game to load
game.Loaded:Wait()

-- Remove loading screen
loadingGui:Destroy()

-- Remove default loading screen
ReplicatedFirst:RemoveDefaultLoadingScreen()
```

## Tips:
- Scripts di sini berjalan sebelum character spawn
- Gunakan untuk setup yang harus selesai sebelum game dimulai
- Ideal untuk loading screens dan initialization