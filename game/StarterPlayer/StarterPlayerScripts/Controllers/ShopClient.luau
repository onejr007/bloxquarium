--!strict
--[=[
    @class ShopClient
    Mengelola interaksi GUI toko perahu di sisi klien. (v1.3 - Layout FIX)
--]=]
local ShopClient = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local RemoteClient = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteClient"))

function ShopClient:Init()
    print("🛥️ [ShopClient] Inisialisasi handler toko perahu klien (v1.3)...")

    local shopGui = Instance.new("ScreenGui")
    shopGui.Name = "BoatShopGui"
    shopGui.Enabled = false
    shopGui.ResetOnSpawn = false
    shopGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.6, 0, 0.7, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Parent = shopGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.1, 0)
    title.Text = "Toko Nelayan"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 28
    title.Parent = frame

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0.15, 0, 0.08, 0)
    closeButton.Position = UDim2.new(0.82, 0, 0.01, 0)
    closeButton.Text = "Tutup"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextSize = 18
    closeButton.Parent = frame

    local itemsContainer = Instance.new("ScrollingFrame")
    itemsContainer.Size = UDim2.new(0.96, 0, 0.85, 0)
    itemsContainer.Position = UDim2.new(0.02, 0, 0.12, 0)
    itemsContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    itemsContainer.BorderSizePixel = 0
    itemsContainer.Parent = frame

    -- [FIX] UIGridLayout harus menjadi child dari container yang diaturnya.
    local itemGrid = Instance.new("UIGridLayout")
    itemGrid.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
    itemGrid.CellSize = UDim2.new(0.2, 0, 0.3, 0)
    itemGrid.SortOrder = Enum.SortOrder.LayoutOrder
    itemGrid.Parent = itemsContainer -- Ini perbaikannya

    -- Terima shopData saat event dipicu
    RemoteClient:On("OpenShopGUI", function(shopData)
        print("[ShopClient] Membuka GUI toko perahu dengan data:", shopData)
        shopGui.Enabled = true

        -- Bersihkan item lama
        for _, child in ipairs(itemsContainer:GetChildren()) do
            -- Pastikan tidak menghapus UIGridLayout
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        if shopData and shopData.item then
            for itemId, stock in pairs(shopData.item) do
                -- Buat frame untuk setiap item
                local itemFrame = Instance.new("Frame")
                itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                itemFrame.BorderSizePixel = 1
                itemFrame.LayoutOrder = tonumber(string.sub(itemId, 2)) or 0 -- Urutkan berdasarkan ID
                itemFrame.Parent = itemsContainer

                local itemName = Instance.new("TextLabel")
                itemName.Size = UDim2.new(1, 0, 0.2, 0)
                itemName.Text = "Item " .. itemId
                itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
                itemName.Font = Enum.Font.SourceSans
                itemName.TextSize = 16
                itemName.Parent = itemFrame

                local itemIcon = Instance.new("ImageLabel")
                itemIcon.Size = UDim2.new(0.8, 0, 0.5, 0)
                itemIcon.Position = UDim2.new(0.1, 0, 0.2, 0)
                itemIcon.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                -- Ganti dengan path ke ikon item jika ada
                -- itemIcon.Image = "rbxassetid://..."
                itemIcon.Parent = itemFrame
                
                local stockLabel = Instance.new("TextLabel")
                stockLabel.Size = UDim2.new(0.5, 0, 0.2, 0)
                stockLabel.Position = UDim2.new(0, 0, 0.75, 0)
                stockLabel.Text = "Stok: " .. tostring(stock)
                stockLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                stockLabel.Font = Enum.Font.SourceSansLight
                stockLabel.TextSize = 14
                stockLabel.Parent = itemFrame

                local buyButton = Instance.new("TextButton")
                buyButton.Size = UDim2.new(0.4, 0, 0.2, 0)
                buyButton.Position = UDim2.new(0.55, 0, 0.75, 0)
                buyButton.Text = "Beli"
                buyButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
                buyButton.Font = Enum.Font.SourceSansBold
                buyButton.TextSize = 16
                buyButton.Parent = itemFrame

                buyButton.MouseButton1Click:Connect(function()
                    print(string.format("[ShopClient] Mencoba membeli item '%s'", itemId))
                    -- [TODO] Tambahkan event untuk mengirim permintaan pembelian ke server
                    -- RemoteClient:FireServer("PurchaseShopItem", itemId) 
                end)
            end
        end
    end)

    closeButton.MouseButton1Click:Connect(function()
        print("[ShopClient] Menutup GUI toko perahu, memberitahu server.")
        shopGui.Enabled = false
        RemoteClient:FireServer("ResumeBoatMovement")
    end)

    print("✅ [ShopClient] Handler toko perahu klien siap.")
end

return ShopClient
