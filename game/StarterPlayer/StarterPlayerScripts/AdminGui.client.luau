--[[
    AdminGui.client.luau (v6.1 - Panel Parenting Fix)

    - Addresses the issue where the admin panel would not appear on toggle.
    - The original `createAdminPanel` function did not parent the newly created
      panel to the GUI, so making it "visible" had no effect.
    - This fix properly creates, configures, and parents the admin panel.
]]

--=================[ SERVICES ]=================--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--=================[ MODULES ]=================--
local RemoteClient = require(ReplicatedStorage.Shared.RemoteClient)
local AssetManager = require(ReplicatedStorage.Shared.AssetManager)

--=================[ VARIABLES ]=================--
local player = Players.LocalPlayer
local guiCreated = false

local INACTIVE_COLOR = Color3.fromRGB(128, 128, 128)
local ACTIVE_COLOR = Color3.fromRGB(255, 193, 7)
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--///////////////////////////////////////////////////////////////////////////
--// FUNGSI PEMBUATAN GUI (Perbaikan Logika Parenting)
--///////////////////////////////////////////////////////////////////////////

local function createAdminPanel(parentGui)
    -- Coba cari panel yang sudah ada terlebih dahulu untuk menghindari duplikasi
    local panel = parentGui:FindFirstChild("AdminPanelFrame")
    if panel then
        return panel
    end

    -- Jika tidak ditemukan, buat instance baru dan konfigurasikan propertinya
    panel = Instance.new("Frame")
    panel.Name = "AdminPanelFrame"
    panel.Size = UDim2.new(0.4, 0, 0.5, 0) -- Ukuran yang lebih sesuai
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0) -- Posisi di tengah layar
    panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Warna latar belakang gelap
    panel.BackgroundTransparency = 0.2
    panel.BorderSizePixel = 1
    panel.BorderColor3 = ACTIVE_COLOR
    panel.Visible = false -- Mulai dalam keadaan tidak terlihat
    
    -- PERBAIKAN UTAMA: Parentkan panel ke ScreenGui agar menjadi bagian dari hierarki UI
    panel.Parent = parentGui

    return panel
end

local function createAdminImageButton(parentGui, onClick)
    -- (Fungsi ini tidak berubah dari versi sebelumnya)
    local toggleButton = Instance.new("ImageButton")
    toggleButton.Name = "AdminToggleButton"
    toggleButton.BackgroundTransparency = 1
    toggleButton.Size = UDim2.new(0, 64, 0, 64)
    toggleButton.Position = UDim2.new(0, 15, 0.5, 0)
    toggleButton.AnchorPoint = Vector2.new(0, 0.5)
    
    toggleButton.Image = AssetManager.get("Admin_ico") 
    
    toggleButton.ImageColor3 = INACTIVE_COLOR
    toggleButton.Parent = parentGui

    local scaleTween
    toggleButton.MouseEnter:Connect(function()
        scaleTween = TweenService:Create(toggleButton, TWEEN_INFO, {Size = UDim2.new(0, 72, 0, 72)})
        scaleTween:Play()
    end)
    toggleButton.MouseLeave:Connect(function()
        scaleTween = TweenService:Create(toggleButton, TWEEN_INFO, {Size = UDim2.new(0, 64, 0, 64)})
        scaleTween:Play()
    end)

    toggleButton.MouseButton1Click:Connect(onClick)

    return toggleButton
end

--///////////////////////////////////////////////////////////////////////////
--// LOGIKA UTAMA (Event-Driven)
--///////////////////////////////////////////////////////////////////////////

local function initializeAdminFeatures()
    if guiCreated then return end
    guiCreated = true

    print("👑 [AdminGui] AssetManager siap. Membuat GUI...")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AdminGui"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Panel dibuat dan diparentkan dengan benar oleh fungsi yang telah diperbaiki
    local adminPanel = createAdminPanel(screenGui)
    local isActive = adminPanel.Visible -- Sinkronkan state awal dari properti Visible panel

    local function onToggleClick()
        -- Logika toggle sekarang akan berfungsi seperti yang diharapkan
        isActive = not isActive
        adminPanel.Visible = isActive

        local colorTarget = isActive and ACTIVE_COLOR or INACTIVE_COLOR
        local colorTween = TweenService:Create(screenGui.AdminToggleButton, TWEEN_INFO, { ImageColor3 = colorTarget })
        colorTween:Play()
    end

    createAdminImageButton(screenGui, onToggleClick)
    
    print("👑 [AdminGui] Tombol toggle admin (AAA Style) berhasil dibuat.")
end

local function onReadyToInitialize(isAdmin)
    if not isAdmin then
        return
    end

    print("👑 [AdminGui] Status admin terkonfirmasi. Menunggu AssetManager...")

    if AssetManager.IsReady() then
        initializeAdminFeatures()
    else
        AssetManager.OnReady:Once(initializeAdminFeatures)
    end
end

--=================[ MAIN EXECUTION ]=================--

RemoteClient:On("AdminCheckResponse", onReadyToInitialize)

print("👑 [AdminGui] Mengirim permintaan pengecekan status admin ke server...")
RemoteClient:FireServer("RequestAdminCheck")
