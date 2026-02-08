--!strict
--[=[
    @class ShopClient
    Mengelola interaksi GUI toko perahu di sisi klien. (v1.1 - FIX)
--]=]
local ShopClient = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- [FIX] Gunakan RemoteClient yang sudah ada, bukan require RemoteService
local RemoteClient = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteClient"))

function ShopClient:Init()
    print("🛥️ [ShopClient] Inisialisasi handler toko perahu klien...")

    -- Anggap kita punya GUI bernama "BoatShopGui" di dalam PlayerGui
    local shopGui = Instance.new("ScreenGui")
    shopGui.Name = "BoatShopGui"
    shopGui.Enabled = false
    shopGui.ResetOnSpawn = false
    shopGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.5, 0, 0.6, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Parent = shopGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.1, 0)
    title.Text = "Toko Nelayan"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24
    title.Parent = frame

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0.2, 0, 0.1, 0)
    closeButton.Position = UDim2.new(0.8, 0, 0, 0)
    closeButton.Text = "Tutup"
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Parent = frame

    -- [FIX] Gunakan RemoteClient:On() untuk event dari server
    RemoteClient:On("OpenShopGUI", function()
        print("[ShopClient] Membuka GUI toko perahu.")
        shopGui.Enabled = true
    end)

    -- Event handler untuk tombol tutup
    closeButton.MouseButton1Click:Connect(function()
        print("[ShopClient] Menutup GUI toko perahu, memberitahu server.")
        shopGui.Enabled = false
        -- [FIX] Gunakan RemoteClient:FireServer() untuk mengirim event ke server
        RemoteClient:FireServer("ResumeBoatMovement")
    end)

    print("✅ [ShopClient] Handler toko perahu klien siap.")
end

return ShopClient
