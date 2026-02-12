--!strict

--------------------------------------------------
-- SERVICES & MODULES
--------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Remote = require(ReplicatedStorage.Shared.RemoteClient)
local ClientState = require(ReplicatedStorage.Shared.ClientState)
local Assets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AssetManagerV3"))
local MainHUD = require(script.Parent:WaitForChild("MainHUDController"))
local GachaController = require(script.Parent:WaitForChild("GachaController"))
local DecorationController = require(script.Parent:WaitForChild("DecorationController"))
local ViewportManager = require(ReplicatedStorage.Shared:WaitForChild("ViewportManager"))

--------------------------------------------------
-- CORE VARS
--------------------------------------------------
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlotController = {}
local UNDERWATER_POS = Vector3.new(5000, -82.5, 5000) -- CENTER of aquarium
local AQUARIUM_SIZE = Vector3.new(60, 35, 8)
local isInteracting = false
local currentVisitingOwnerId: number? = nil
local initialized = false

-- UI REFERENCES
local infoFrame: Frame? = nil
local rewardFrame: Frame? = nil
local rewardList: Frame? = nil
local infoDesc: TextLabel? = nil
local infoName: TextLabel? = nil
local infoModelContainer: Frame? = nil
local infoStroke: UIStroke? = nil
local miniStroke: UIStroke? = nil
local miniBtn: TextButton? = nil
local hatchBtn: TextButton? = nil
local autoHatchBtn: TextButton? = nil
local isAutoHatching = false
local currentFoodId: string? = nil -- Moved up for global access
local originalPos: UDim2 = UDim2.fromScale(0.5, 0.975)
local isMinimized = false
local infoRotationConn: RBXScriptConnection? = nil
local currentSelectedId: string? = nil
local currentSelectedCategory: string? = nil
local activeUwGui: ScreenGui? = nil
local hideItemInfo: () -> () -- Forward declaration for scope access

--------------------------------------------------
-- ASSETS & THEME
--------------------------------------------------
local FRAME_ICO, MENU_ICO, FISH_ICO, CLOSE_ICO, COIN_ICO, EGG_ICO, FOOD_ICO, DECOR_ICO

local THEME = {
	PRIMARY = Color3.fromRGB(16, 22, 36),
	SECONDARY = Color3.fromRGB(26, 36, 58),
	ACCENT = Color3.fromRGB(0, 210, 255),
	TEXT = Color3.fromRGB(240, 245, 255),
	GOLD = Color3.fromRGB(255, 200, 50),
	DANGER = Color3.fromRGB(255, 90, 90),
	GRADIENT_TOP = Color3.fromRGB(50, 75, 120),
	EMPTY_TEXT = Color3.fromRGB(150, 165, 195),
	SHADOW = Color3.fromRGB(0, 0, 0),
	SUCCESS = Color3.fromRGB(90, 220, 150),
}

local function log(...) print("[AquariumUI]", ...) end

local function loadAssets()
	FRAME_ICO = Assets.get("Frame_ico") or ""
	MENU_ICO = Assets.get("Menu_ico") or ""
	FISH_ICO = Assets.get("Fish_ico") or ""
	CLOSE_ICO = Assets.get("Close_ico") or ""
	COIN_ICO = Assets.get("Coin_ico") or ""
	EGG_ICO = Assets.get("Egg_ico") or ""
	FOOD_ICO = Assets.get("Food_ico") or ""
	DECOR_ICO = Assets.get("Decoration_ico") or ""
	log("Assets loaded")
end

local function setControlsEnabled(enabled: boolean)
	local char = Player.Character
	local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?
	if not hum then return end
	hum.WalkSpeed = enabled and 16 or 0
	hum.JumpPower = enabled and 50 or 0
	log("Controls:", enabled)
end

--------------------------------------------------
-- UTILS
--------------------------------------------------
local function parseRotation(rot: any): CFrame
	if typeof(rot) == "string" then
		local parts = string.split(rot, ",")
		if #parts == 3 then
			local x = tonumber(parts[1]) or 0
			local y = tonumber(parts[2]) or 0
			local z = tonumber(parts[3]) or 0
			return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
		end
	elseif typeof(rot) == "number" then
		return CFrame.Angles(0, math.rad(rot), 0)
	end
	return CFrame.new()
end

local function applyDecor(inst: GuiObject, radius: number?, color: Color3?)
	if not inst then return end
	local corner = inst:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", inst)
	corner.CornerRadius = UDim.new(0, radius or 8)

	local stroke = inst:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke", inst)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Transparency = 0.6
	stroke.Thickness = 1
	stroke.Color = color or Color3.fromRGB(255, 255, 255)
end

--------------------------------------------------
-- UNDERWATER WORLD GENERATION (LOCAL)
--------------------------------------------------
local function GenerateUnderwaterAreaLocal()
	local container = workspace:FindFirstChild("UnderwaterWorld")
	if not container then
		container = Instance.new("Folder")
		container.Name = "UnderwaterWorld"
		container.Parent = workspace
	else
		-- Clear existing drops if any
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Model") and child.Name:find("InvItem_") or child.Name:find("Food_") then
				child:Destroy()
			end
		end
	end
	
	local boxSize = AQUARIUM_SIZE
	local halfY = boxSize.Y / 2
	
	-- Floor (Sand/Gravel)
	if not container:FindFirstChild("UnderwaterFloor") then
		local floor = Instance.new("Part")
		floor.Name = "UnderwaterFloor"
		floor.Size = Vector3.new(boxSize.X + 2, 1, boxSize.Z)
		floor.Position = UNDERWATER_POS - Vector3.new(0, halfY + 0.5, 0)
		floor.Anchored = true
		floor.Material = Enum.Material.Sand
		floor.Color = Color3.fromRGB(180, 170, 130)
		floor.Parent = container
	end
	
	-- Background Wall
	if not container:FindFirstChild("BackgroundWall") then
		local backWall = Instance.new("Part")
		backWall.Name = "BackgroundWall"
		backWall.Size = Vector3.new(boxSize.X + 100, boxSize.Y + 60, 1)
		backWall.Position = UNDERWATER_POS - Vector3.new(0, 0, boxSize.Z/2 + 2)
		backWall.Anchored = true
		backWall.Material = Enum.Material.Concrete
		backWall.Color = Color3.fromRGB(10, 35, 70)
		backWall.CastShadow = false
		backWall.Parent = container
	end
	
	local function createGlassWall(name, size, pos, transparency)
		local g = container:FindFirstChild(name)
		if not g then
			g = Instance.new("Part")
			g.Name = name
			g.Size = size
			g.Position = pos
			g.Anchored = true
			g.Material = Enum.Material.Glass
			g.Transparency = transparency or 0.9
			g.Color = Color3.fromRGB(150, 220, 255)
			g.CastShadow = false
			g.CanCollide = true
			g.Parent = container
		end
		return g
	end
	
	-- Left & Right Walls
	createGlassWall("LeftWall", Vector3.new(1, boxSize.Y, boxSize.Z), UNDERWATER_POS + Vector3.new(boxSize.X/2, 0, 0))
	createGlassWall("RightWall", Vector3.new(1, boxSize.Y, boxSize.Z), UNDERWATER_POS + Vector3.new(-boxSize.X/2, 0, 0))
	
	-- Top/Ceiling
	createGlassWall("Ceiling", Vector3.new(boxSize.X, 1, boxSize.Z), UNDERWATER_POS + Vector3.new(0, halfY, 0), 0.9)

	-- Define Aquarium Bounds for 2D Logic (Invisible Part)
	if not container:FindFirstChild("AquariumBounds") then
		local bounds = Instance.new("Part")
		bounds.Name = "AquariumBounds"
		bounds.Size = boxSize
		bounds.Position = UNDERWATER_POS
		bounds.Anchored = true
		bounds.Transparency = 1
		bounds.CanCollide = false
		bounds.Parent = container
	end
end

--------------------------------------------------
-- LOADING SCREEN
--------------------------------------------------
local function createLoadingScreen()
	local sg = Instance.new("ScreenGui")
	sg.Name, sg.IgnoreGuiInset, sg.DisplayOrder = "LoadingScreen", true, 100

	local frame = Instance.new("Frame", sg)
	frame.Size, frame.BackgroundColor3, frame.BorderSizePixel = UDim2.fromScale(1,1), Color3.fromRGB(6,12,24), 0

	local text = Instance.new("TextLabel", frame)
	text.Size, text.BackgroundTransparency = UDim2.fromScale(1,1), 1
	text.Font, text.Text = Enum.Font.GothamBlack, "EXPLORING AQUARIUM..."
	text.TextColor3, text.TextSize, text.TextTransparency = THEME.ACCENT, 28, 1

	sg.Parent = Player.PlayerGui
	log("Loading screen created")
	return sg, frame, text
end

--------------------------------------------------
-- UNDERWATER GUI (PRO UI/UX)
--------------------------------------------------
local function createUnderwaterGui(onClose: () -> ())
	if not Assets.IsReady() then log("Assets not ready"); return end
	if not FRAME_ICO then loadAssets() end

	log("Mounting Underwater GUI")

	local destroyed = false
	local sg = Instance.new("ScreenGui")
	sg.Name, sg.ResetOnSpawn = "UnderwaterGui", false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	--------------------------------------------------
	-- MENU CONTAINER (BOTTOM RIGHT)
	--------------------------------------------------
	local menuContainer = Instance.new("Frame", sg)
	menuContainer.Name = "MenuButtons"
	menuContainer.Size = UDim2.fromScale(0.14, 0.42)
	menuContainer.Position = UDim2.fromScale(1, 1)
	menuContainer.AnchorPoint = Vector2.new(1, 1)
	menuContainer.BackgroundTransparency = 1

	--------------------------------------------------
	-- INVENTORY PANEL (SNAPS BESIDE CATEGORY BUTTON)
	--------------------------------------------------
	local menuFrame = Instance.new("CanvasGroup", sg)
	menuFrame.Name = "InventoryPanel"
	menuFrame.Size = UDim2.fromScale(0.34, 0.22)
	menuFrame.AnchorPoint = Vector2.new(1, 0.5)
	menuFrame.BackgroundColor3 = THEME.PRIMARY
	menuFrame.GroupTransparency = 1
	menuFrame.Visible = false

	Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 18)

	--------------------------------------------------
	-- INVENTORY SCROLL (HORIZONTAL, COMPACT)
	--------------------------------------------------
	local invScroll = Instance.new("ScrollingFrame", menuFrame)
	invScroll.Size = UDim2.new(1, -20, 1, -20)
	invScroll.Position = UDim2.fromOffset(10, 10)
	invScroll.BackgroundTransparency = 1
	invScroll.ScrollBarThickness = 3
	invScroll.ScrollBarImageColor3 = THEME.ACCENT
	invScroll.CanvasSize = UDim2.fromScale(0,0)
	invScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	invScroll.ScrollingDirection = Enum.ScrollingDirection.X
	invScroll.ZIndex = 2

	local invLayout = Instance.new("UIListLayout", invScroll)
	invLayout.Padding = UDim.new(0, 8)
	invLayout.FillDirection = Enum.FillDirection.Horizontal
	invLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	--------------------------------------------------
	-- EMPTY INVENTORY LABEL
	--------------------------------------------------
	local emptyLabel = Instance.new("TextLabel", menuFrame)
	emptyLabel.Size = UDim2.fromScale(1,1)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.TextWrapped = true
	emptyLabel.TextYAlignment = Enum.TextYAlignment.Center
	emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
	emptyLabel.Font = Enum.Font.GothamMedium
	emptyLabel.TextSize = 13
	emptyLabel.TextColor3 = THEME.EMPTY_TEXT
	emptyLabel.TextTransparency = 1
	emptyLabel.Text = "INVENTORY KOSONG"
	emptyLabel.Visible = false
	emptyLabel.ZIndex = 3

	--------------------------------------------------
	-- ITEM INFO PANEL (AAA GLASSMORPHISM DESIGN)
	--------------------------------------------------
	infoFrame = Instance.new("Frame", sg)
	infoFrame.Name = "ItemInfoPanel"
	infoFrame.Size = UDim2.fromOffset(280, 0)
	infoFrame.AutomaticSize = Enum.AutomaticSize.Y
	infoFrame.Position = UDim2.fromScale(0.5, 0.995)
	infoFrame.AnchorPoint = Vector2.new(0.5, 1)
	infoFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
	infoFrame.BackgroundTransparency = 0.2
	infoFrame.Visible = false
	infoFrame.ZIndex = 10
	infoFrame.ClipsDescendants = false -- 🔧 Biarkan HatchContainer terlihat di luar frame jika perlu

	local infoBlur = Instance.new("ImageLabel", infoFrame)
	infoBlur.Name = "GlassBlur"
	infoBlur.Size = UDim2.fromScale(1, 1) -- Menutupi seluruh infoFrame
	infoBlur.Position = UDim2.fromOffset(0, 0)
	infoBlur.BackgroundTransparency = 1
	infoBlur.Image = "rbxassetid://1316045217"
	infoBlur.ImageColor3 = THEME.ACCENT
	infoBlur.ImageTransparency = 0.85
	infoBlur.ZIndex = 1 -- Di bawah konten
	infoBlur.ScaleType = Enum.ScaleType.Slice
	infoBlur.SliceCenter = Rect.new(10, 10, 10, 10)

	Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0, 12)
	infoStroke = Instance.new("UIStroke", infoFrame)
	infoStroke.Color = THEME.ACCENT
	infoStroke.Thickness = 2
	infoStroke.Transparency = 0.3
	infoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local infoGrad = Instance.new("UIGradient", infoFrame)
	infoGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))
	})
	infoGrad.Rotation = 45

	-- 📦 CONTENT CONTAINER (Solusi layout aneh & Z-Index)
	local content = Instance.new("Frame", infoFrame)
	content.Name = "Content"
	content.Size = UDim2.fromScale(1, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.ZIndex = 5

	local mainLayout = Instance.new("UIListLayout", content)
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainLayout.Padding = UDim.new(0, 4)

	local header = Instance.new("Frame", content)
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 36)
	header.BackgroundTransparency = 1
	header.ZIndex = 6

	local headerPadding = Instance.new("UIPadding", header)
	headerPadding.PaddingLeft = UDim.new(0, 12)
	headerPadding.PaddingRight = UDim.new(0, 12)

	miniBtn = Instance.new("TextButton", header)
	miniBtn.Name = "MinimizeButton"
	miniBtn.Size = UDim2.fromOffset(24, 24)
	miniBtn.Position = UDim2.new(1, 0, 0.5, 0)
	miniBtn.AnchorPoint = Vector2.new(1, 0.5)
	miniBtn.BackgroundColor3 = THEME.SECONDARY
	miniBtn.BackgroundTransparency = 0.5
	miniBtn.Text = "v"
	miniBtn.Font = Enum.Font.GothamBold
	miniBtn.TextSize = 14
	miniBtn.TextColor3 = THEME.TEXT
	miniBtn.ZIndex = 7
	Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 6)

	infoName = Instance.new("TextLabel", header)
	infoName.Name = "ItemName"
	infoName.Size = UDim2.new(1, -30, 1, 0)
	infoName.BackgroundTransparency = 1
	infoName.Font = Enum.Font.GothamBlack
	infoName.TextSize = 14
	infoName.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoName.TextXAlignment = Enum.TextXAlignment.Left
	infoName.ZIndex = 7

	local body = Instance.new("Frame", content)
	body.Name = "Body"
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.BackgroundTransparency = 1
	body.ZIndex = 6

	local bodyPadding = Instance.new("UIPadding", body)
	bodyPadding.PaddingLeft = UDim.new(0, 12)
	bodyPadding.PaddingRight = UDim.new(0, 12)
	bodyPadding.PaddingBottom = UDim.new(0, 12)

	local bodyLayout = Instance.new("UIListLayout", body)
	bodyLayout.FillDirection = Enum.FillDirection.Horizontal
	bodyLayout.Padding = UDim.new(0, 12)
	bodyLayout.VerticalAlignment = Enum.VerticalAlignment.Center -- 🔧 CENTERED SYMMETRY

	infoModelContainer = Instance.new("Frame", body)
	infoModelContainer.Name = "ModelPreviewContainer"
	infoModelContainer.Size = UDim2.fromOffset(80, 80)
	infoModelContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	infoModelContainer.BackgroundTransparency = 0.95
	infoModelContainer.ZIndex = 7
	Instance.new("UICorner", infoModelContainer).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", infoModelContainer).Color = THEME.ACCENT

	local rightContent = Instance.new("Frame", body)
	rightContent.Name = "RightContent"
	rightContent.Size = UDim2.new(1, -92, 0, 0)
	rightContent.AutomaticSize = Enum.AutomaticSize.Y
	rightContent.BackgroundTransparency = 1
	rightContent.ZIndex = 7

	local rightLayout = Instance.new("UIListLayout", rightContent)
	rightLayout.Padding = UDim.new(0, 4)
	rightLayout.VerticalAlignment = Enum.VerticalAlignment.Center -- 🔧 CENTERED

	infoDesc = Instance.new("TextLabel", rightContent)
	infoDesc.Name = "StatsLabel"
	infoDesc.Size = UDim2.new(1, 0, 0, 0)
	infoDesc.AutomaticSize = Enum.AutomaticSize.Y
	infoDesc.BackgroundTransparency = 1
	infoDesc.Font = Enum.Font.GothamMedium
	infoDesc.TextSize = 11
	infoDesc.TextColor3 = THEME.EMPTY_TEXT
	infoDesc.TextXAlignment = Enum.TextXAlignment.Left
	infoDesc.TextWrapped = true
	infoDesc.ZIndex = 7

	rewardFrame = Instance.new("Frame", content)
	rewardFrame.Name = "RewardFrame"
	rewardFrame.Size = UDim2.new(1, 0, 0, 0)
	rewardFrame.AutomaticSize = Enum.AutomaticSize.Y
	rewardFrame.BackgroundTransparency = 1
	rewardFrame.Visible = false
	rewardFrame.ZIndex = 6

	local rewardTitle = Instance.new("TextLabel", rewardFrame)
	rewardTitle.Size = UDim2.new(1, 0, 0, 24)
	rewardTitle.Position = UDim2.fromOffset(12, 0)
	rewardTitle.BackgroundTransparency = 1
	rewardTitle.Text = "POSSIBLE REWARDS:"
	rewardTitle.Font = Enum.Font.GothamBold
	rewardTitle.TextSize = 10
	rewardTitle.TextColor3 = THEME.GOLD
	rewardTitle.TextXAlignment = Enum.TextXAlignment.Left
	rewardTitle.ZIndex = 7

	local rewardListFrame = Instance.new("Frame", rewardFrame)
	rewardListFrame.Name = "RewardListContainer"
	rewardListFrame.Size = UDim2.new(1, 0, 0, 50)
	rewardListFrame.Position = UDim2.fromOffset(0, 26) -- Memberi jarak dari judul
	rewardListFrame.BackgroundTransparency = 1
	rewardListFrame.ZIndex = 7

	rewardList = Instance.new("Frame", rewardListFrame)
	rewardList.Name = "RewardList"
	rewardList.Size = UDim2.fromScale(1, 1)
	rewardList.BackgroundTransparency = 1
	rewardList.ZIndex = 8

	local rewardLayout = Instance.new("UIListLayout", rewardList)
	rewardLayout.FillDirection = Enum.FillDirection.Horizontal
	rewardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rewardLayout.Padding = UDim.new(0, 8)

	header.LayoutOrder = 1
	body.LayoutOrder = 2
	rewardFrame.LayoutOrder = 3

	--------------------------------------------------
	-- 🔧 HATCH BUTTONS (Directly on infoFrame to ensure visibility)
	--------------------------------------------------
	hatchBtn = Instance.new("TextButton", infoFrame)
	hatchBtn.Name = "HatchButton"
	hatchBtn.Size = UDim2.new(0.4, 0, 0, 32)
	hatchBtn.Position = UDim2.new(0.3, -5, 1, 10) -- Geser kiri
	hatchBtn.AnchorPoint = Vector2.new(0.5, 0)
	hatchBtn.BackgroundColor3 = THEME.SUCCESS
	hatchBtn.TextColor3 = THEME.PRIMARY
	hatchBtn.Font = Enum.Font.GothamBlack
	hatchBtn.TextSize = 12
	hatchBtn.Text = "HATCH"
	hatchBtn.ZIndex = 2000 -- Jauh lebih tinggi
	hatchBtn.Visible = false
	Instance.new("UICorner", hatchBtn).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", hatchBtn).Thickness = 2

	autoHatchBtn = Instance.new("TextButton", infoFrame)
	autoHatchBtn.Name = "AutoHatchButton"
	autoHatchBtn.Size = UDim2.new(0.4, 0, 0, 32)
	autoHatchBtn.Position = UDim2.new(0.7, 5, 1, 10) -- Geser kanan
	autoHatchBtn.AnchorPoint = Vector2.new(0.5, 0)
	autoHatchBtn.BackgroundColor3 = THEME.GOLD
	autoHatchBtn.TextColor3 = THEME.PRIMARY
	autoHatchBtn.Font = Enum.Font.GothamBlack
	autoHatchBtn.TextSize = 12
	autoHatchBtn.Text = "AUTO"
	autoHatchBtn.ZIndex = 2000
	autoHatchBtn.Visible = false
	Instance.new("UICorner", autoHatchBtn).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", autoHatchBtn).Thickness = 2

	hatchBtn.MouseEnter:Connect(function()
		TweenService:Create(hatchBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 255, 180)}):Play()
	end)
	hatchBtn.MouseLeave:Connect(function()
		TweenService:Create(hatchBtn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.SUCCESS}):Play()
	end)

	autoHatchBtn.MouseEnter:Connect(function()
		TweenService:Create(autoHatchBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 230, 100)}):Play()
	end)
	autoHatchBtn.MouseLeave:Connect(function()
		TweenService:Create(autoHatchBtn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.GOLD}):Play()
	end)

	-- 🔧 MINIMIZE LOGIC (Tebal 36px saat mini)
	isMinimized = false
	originalPos = UDim2.fromScale(0.5, 0.995)
	
	miniBtn.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		miniBtn.Text = isMinimized and "^" or "v"
		
		local targetPos = isMinimized and UDim2.new(0.5, 0, 0.995, infoFrame.AbsoluteSize.Y - 36) or originalPos
		
		TweenService:Create(infoFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = targetPos
		}):Play()
	end)

	--------------------------------------------------
	-- ICON BUTTON FACTORY (ANTI GEPENG)
	--------------------------------------------------
	local function createIconButton(icon: string, pos: UDim2, size: number, name: string, color: Color3?)
		local btn = Instance.new("ImageButton")
		btn.Name = name or "IconButton"
		btn.Size = UDim2.fromOffset(size, size)
		btn.Position = pos
		btn.AnchorPoint = Vector2.new(0.5, 0.5)
		btn.BackgroundTransparency = 1
		btn.Image = FRAME_ICO
		btn.ImageColor3 = color or THEME.PRIMARY
		btn.AutoButtonColor = false

		local aspect = Instance.new("UIAspectRatioConstraint", btn)
		aspect.AspectRatio = 1

		local padding = Instance.new("UIPadding", btn)
		padding.PaddingTop = UDim.new(0, 7)
		padding.PaddingBottom = UDim.new(0, 7)
		padding.PaddingLeft = UDim.new(0, 7)
		padding.PaddingRight = UDim.new(0, 7)

		local ico = Instance.new("ImageLabel", btn)
		ico.Size = UDim2.fromScale(1, 1)
		ico.Position = UDim2.fromScale(0.5, 0.5)
		ico.AnchorPoint = Vector2.new(0.5, 0.5)
		ico.BackgroundTransparency = 1
		ico.Image = icon
		ico.ScaleType = Enum.ScaleType.Fit

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(size + 6, size + 6),
				ImageColor3 = THEME.GRADIENT_TOP,
			}):Play()
		end)

		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(size, size),
				ImageColor3 = color or THEME.PRIMARY,
			}):Play()
		end)

		return btn
	end

	--------------------------------------------------
	-- BUTTONS
	--------------------------------------------------
	local toggleBtn = createIconButton(MENU_ICO, UDim2.new(0.5, 0, 1, -36), 66, "Toggle", THEME.ACCENT)
	toggleBtn.Parent = menuContainer

	local fishBtn = createIconButton(FISH_ICO, UDim2.new(0.5, 0, 1, -36), 52, "Fish")
	local eggBtn = createIconButton(EGG_ICO, UDim2.new(0.5, 0, 1, -36), 52, "Egg")
	local foodBtn = createIconButton(FOOD_ICO, UDim2.new(0.5, 0, 1, -36), 52, "Food")
	local decorBtn = createIconButton(DECOR_ICO, UDim2.new(0.5, 0, 1, -36), 52, "Decoration")
	local closeBtn = createIconButton(CLOSE_ICO, UDim2.new(0.5, 0, 1, -36), 52, "Close", THEME.DANGER)

	fishBtn.Visible, eggBtn.Visible, foodBtn.Visible, decorBtn.Visible, closeBtn.Visible = false, false, false, false, false
	fishBtn.Parent, eggBtn.Parent, foodBtn.Parent, decorBtn.Parent, closeBtn.Parent = menuContainer, menuContainer, menuContainer, menuContainer, menuContainer

	--------------------------------------------------
	-- COIN DISPLAY (AUTO FIT CONTENT + TEXT WIDTH)
	--------------------------------------------------
	local coinFrame = Instance.new("Frame", sg)
	coinFrame.Name = "CoinFrame"
	coinFrame.Size = UDim2.fromOffset(120, 44)
	coinFrame.AutomaticSize = Enum.AutomaticSize.X
	coinFrame.Position = UDim2.fromScale(0.035, 0.965)
	coinFrame.AnchorPoint = Vector2.new(0,1)
	coinFrame.BackgroundColor3 = THEME.PRIMARY

	Instance.new("UICorner", coinFrame).CornerRadius = UDim.new(0, 18)
	local coinStroke = Instance.new("UIStroke", coinFrame)
	coinStroke.Color, coinStroke.Thickness = THEME.GOLD, 2

	local coinPadding = Instance.new("UIPadding", coinFrame)
	coinPadding.PaddingLeft = UDim.new(0, 10)
	coinPadding.PaddingRight = UDim.new(0, 10)
	coinPadding.PaddingTop = UDim.new(0, 6)
	coinPadding.PaddingBottom = UDim.new(0, 6)

	local coinLayout = Instance.new("UIListLayout", coinFrame)
	coinLayout.FillDirection = Enum.FillDirection.Horizontal
	coinLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	coinLayout.Padding = UDim.new(0, 8)

	local coinIcon = Instance.new("ImageLabel", coinFrame)
	coinIcon.Size = UDim2.fromOffset(24, 24)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Image = COIN_ICO
	coinIcon.ScaleType = Enum.ScaleType.Fit

	local coinLabel = Instance.new("TextLabel", coinFrame)
	coinLabel.Size = UDim2.fromScale(0, 1)
	coinLabel.AutomaticSize = Enum.AutomaticSize.X
	coinLabel.BackgroundTransparency = 1
	coinLabel.Font = Enum.Font.GothamBold
	coinLabel.TextSize = 20
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.TextColor3 = THEME.TEXT
	coinLabel.Text = "0"

	--------------------------------------------------
	-- CAPACITY DISPLAY (FISH & DECOR)
	--------------------------------------------------
	local capacityFrame = Instance.new("Frame", sg)
	capacityFrame.Name = "CapacityFrame"
	capacityFrame.Size = UDim2.fromOffset(100, 44)
	capacityFrame.AutomaticSize = Enum.AutomaticSize.X
	capacityFrame.Position = UDim2.new(0.035, 0, 0.965, -52)
	capacityFrame.AnchorPoint = Vector2.new(0,1)
	capacityFrame.BackgroundColor3 = THEME.PRIMARY
	capacityFrame.BackgroundTransparency = 0.3
	Instance.new("UICorner", capacityFrame).CornerRadius = UDim.new(0, 12)
	applyDecor(capacityFrame, 4, THEME.ACCENT)

	local capLayout = Instance.new("UIListLayout", capacityFrame)
	capLayout.FillDirection = Enum.FillDirection.Horizontal
	capLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	capLayout.Padding = UDim.new(0, 12)
	
	local capPadding = Instance.new("UIPadding", capacityFrame)
	capPadding.PaddingLeft = UDim.new(0, 10)
	capPadding.PaddingRight = UDim.new(0, 10)

	-- Fish Capacity
	local fishCapFrame = Instance.new("Frame", capacityFrame)
	fishCapFrame.Size = UDim2.fromOffset(0, 30)
	fishCapFrame.AutomaticSize = Enum.AutomaticSize.X
	fishCapFrame.BackgroundTransparency = 1
	
	local fishCapLayout = Instance.new("UIListLayout", fishCapFrame)
	fishCapLayout.FillDirection = Enum.FillDirection.Horizontal
	fishCapLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	fishCapLayout.Padding = UDim.new(0, 4)

	local fishCapIcon = Instance.new("ImageLabel", fishCapFrame)
	fishCapIcon.Size = UDim2.fromOffset(20, 20)
	fishCapIcon.BackgroundTransparency = 1
	fishCapIcon.Image = FISH_ICO
	fishCapIcon.ImageColor3 = THEME.ACCENT

	local fishCapLabel = Instance.new("TextLabel", fishCapFrame)
	fishCapLabel.Size = UDim2.fromScale(0, 1)
	fishCapLabel.AutomaticSize = Enum.AutomaticSize.X
	fishCapLabel.BackgroundTransparency = 1
	fishCapLabel.Font = Enum.Font.GothamBold
	fishCapLabel.TextSize = 14
	fishCapLabel.TextColor3 = THEME.TEXT
	fishCapLabel.Text = "0/0"

	-- Decor Capacity
	local decorCapFrame = Instance.new("Frame", capacityFrame)
	decorCapFrame.Size = UDim2.fromOffset(0, 30)
	decorCapFrame.AutomaticSize = Enum.AutomaticSize.X
	decorCapFrame.BackgroundTransparency = 1
	
	local decorCapLayout = Instance.new("UIListLayout", decorCapFrame)
	decorCapLayout.FillDirection = Enum.FillDirection.Horizontal
	decorCapLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	decorCapLayout.Padding = UDim.new(0, 4)

	local decorCapIcon = Instance.new("ImageLabel", decorCapFrame)
	decorCapIcon.Size = UDim2.fromOffset(20, 20)
	decorCapIcon.BackgroundTransparency = 1
	decorCapIcon.Image = DECOR_ICO
	decorCapIcon.ImageColor3 = THEME.GOLD

	local decorCapLabel = Instance.new("TextLabel", decorCapFrame)
	decorCapLabel.Size = UDim2.fromScale(0, 1)
	decorCapLabel.AutomaticSize = Enum.AutomaticSize.X
	decorCapLabel.BackgroundTransparency = 1
	decorCapLabel.Font = Enum.Font.GothamBold
	decorCapLabel.TextSize = 14
	decorCapLabel.TextColor3 = THEME.TEXT
	decorCapLabel.Text = "0/0"

	local function updateCapacity(state)
		state = state or ClientState:GetState()
		if not state then return end
		
		-- 🔍 GET FISH COUNT (From World)
		local fishCount = 0
		local world = workspace:FindFirstChild("UnderwaterWorld")
		local fishFolder = world and world:FindFirstChild("Fish")
		if fishFolder then
			for _, f in ipairs(fishFolder:GetChildren()) do
				if f:IsA("Model") and f:GetAttribute("OwnerId") == Player.UserId then
					fishCount += 1
				end
			end
		end

		-- 🔍 GET DECOR COUNT (From World)
		local decorCount = 0
		local decorFolder = world and world:FindFirstChild("Decorations")
		if decorFolder then
			for _, d in ipairs(decorFolder:GetChildren()) do
				if d:IsA("Model") and d:GetAttribute("OwnerId") == Player.UserId then
					decorCount += 1
				end
			end
		end

		-- 🔍 GET MAX LIMITS (From Firebase Data Structure)
		-- Based on database_structure.json: game.aquarium[level].maxDecoration / maxFish
		local aqLevel = state.AquariumLevel or 1
		local maxFish = 10 -- Default
		local maxDecor = 3 -- Default

		-- Mapping from database_structure.json
		local aqConfig = {
			[1] = {maxDecoration = 3, maxFish = 10},
			[2] = {maxDecoration = 5, maxFish = 15},
			[3] = {maxDecoration = 10, maxFish = 20},
		}
		
		local currentLimit = aqConfig[aqLevel] or aqConfig[1]
		maxFish = currentLimit.maxFish
		maxDecor = currentLimit.maxDecoration

		fishCapLabel.Text = string.format("%d/%d", fishCount, maxFish)
		decorCapLabel.Text = string.format("%d/%d", decorCount, maxDecor)
	end

	updateCapacity()
	ClientState:OnChange(updateCapacity)

	-- Also update when fish or decorations are added/removed locally
	task.spawn(function()
		while task.wait(1) do
			if not destroyed then updateCapacity() end
		end
	end)

	hideItemInfo = function()
		if not infoFrame or not infoFrame.Visible then return end
		
		if infoRotationConn then
			infoRotationConn:Disconnect()
			infoRotationConn = nil
		end

		TweenService:Create(infoFrame, TweenInfo.new(0.12), {
			BackgroundTransparency = 1
		}):Play()
		task.delay(0.12, function()
			if infoFrame then infoFrame.Visible = false end
			if hatchBtn then hatchBtn.Visible = false end
		end)
	end

	--------------------------------------------------
	-- INVENTORY LOGIC
	--------------------------------------------------
	local function clearInventory()
		for _, child in ipairs(invScroll:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end
		end
	end

	local function showEmpty(text: string)
		emptyLabel.Text = text
		emptyLabel.Visible = true
		TweenService:Create(emptyLabel, TweenInfo.new(0.14), {TextTransparency = 0}):Play()
		log("Empty inventory:", text)
	end

	local function hideEmpty()
		if not emptyLabel.Visible then return end
		TweenService:Create(emptyLabel, TweenInfo.new(0.12), {TextTransparency = 1}):Play()
		task.delay(0.12, function() emptyLabel.Visible = false end)
	end

	local function closeAllMenusExceptInfo()
		menuFrame.Visible = false
		menuFrame.GroupTransparency = 1
		clearInventory()

		for _, btn in ipairs({fishBtn, eggBtn, foodBtn, closeBtn}) do
			btn.Visible = false
			btn.Position = UDim2.new(0.5, 0, 1, -36)
		end
	end

	--------------------------------------------------
	-- MENU STATE
	--------------------------------------------------
	local toggleMenu -- Forward declaration

	local uiConnections = {}

	local function showItemInfo(id: string, count: number, category: string)
		currentSelectedId = id
		currentSelectedCategory = category
		local itemData = Assets.GetItemData(id)
		local modelName = itemData and (itemData.mInfoName or itemData.mDropName or itemData.name) or tostring(id)
		
		-- 🎨 UPDATE BORDER WARNA RARITY
		local rarityColor = itemData and THEME[itemData.rarity or "Common"] or THEME.ACCENT
		if infoStroke then infoStroke.Color = rarityColor end
		if miniStroke then miniStroke.Color = rarityColor end
		
		if infoName then
			infoName.Text = modelName:upper()
			infoName.TextColor3 = rarityColor
		end
		
		local statsText = ""
		if category == "Egg" then
			infoName.Text = (itemData.name or "UNKNOWN"):upper()
			statsText = string.format(
				"RARITY: %s\n%s",
				(itemData.rarity or "COMMON"):upper(),
				itemData.desc or "Hatch to get a random fish!"
			)
		elseif category == "Food" then
			statsText = string.format(
				"RARITY: %s\nEXP: +%d\nHUNGER CD: %ds\nSTOCK: x%d",
				(itemData.rarity or "COMMON"):upper(),
				itemData.addExp or 0,
				itemData.addHungerCD or 0,
				count
			)
		elseif category == "Fish" then
			statsText = string.format(
				"RARITY: %s\nNAME: %s\nEXP: +%d\nHUNGER CD: %ds",
				(itemData.rarity or "COMMON"):upper(),
				(itemData.name or "UNKNOWN"):upper(),
				itemData.addExp or 0,
				itemData.addHungerCD or 0
			)
		else
			statsText = itemData and itemData.desc or "Jumlah: x"..tostring(count)
		end
		
		if infoDesc then infoDesc.Text = statsText end
		
		if hatchBtn and autoHatchBtn then 
			local isEgg = (category == "Egg")
			hatchBtn.Visible = isEgg
			autoHatchBtn.Visible = isEgg
			
			warn("🥚 [PlotController] Buttons visibility set to:", isEgg, "for category:", category)
			warn("🥚 [PlotController] HatchBtn ZIndex:", hatchBtn.ZIndex, "Visible:", hatchBtn.Visible)
			
			-- Reset auto hatch state if switching items
			if currentSelectedId ~= id then
				isAutoHatching = false
				autoHatchBtn.Text = "AUTO HATCH"
				autoHatchBtn.BackgroundColor3 = THEME.GOLD
			end

			-- 🧪 RE-BIND CLICK (Because id is local to showItemInfo)
			for _, conn in ipairs(uiConnections) do conn:Disconnect() end
			table.clear(uiConnections)
			
			local function performHatch(hatchMode: boolean?)
				warn("🥚 [PlotController] performHatch called with hatchMode:", hatchMode, "isAutoHatching:", isAutoHatching)
				if not id then 
					warn("🥚 [PlotController] performHatch failed: No egg ID selected")
					return require(game:GetService("ReplicatedStorage").Shared.Promise).resolve(false)
				end
				hatchBtn.Text = "HATCHING..."
				hatchBtn.Active = false
				
			local isAutoMode = (hatchMode == true)
			if hatchMode == nil then 
				isAutoMode = isAutoHatching 
			end
			
			-- 🔧 FORCE UI MINI IF AUTO
			if isAutoHatching then isAutoMode = true end

				-- 🔧 CRITICAL: Mark as success even if wonFishId is slow to arrive
				return Remote:InvokeServer("RequestHatchEgg", id):andThen(function(success, wonFishId)
					warn("🥚 [PlotController] Server response - success:", success, "wonFishId:", wonFishId)
					
					if success then
						-- Jika wonFishId nil (masalah transport), coba ambil dari ClientState
						if not wonFishId then
							warn("⚠️ [PlotController] wonFishId is nil from server response, attempting ClientState fallback...")
							local state = ClientState:GetState()
							-- Fallback: Cari fish yang ada di inventory tapi mungkin baru saja bertambah
							-- Namun karena kita sudah memperbaiki Promise, ini seharusnya tidak terjadi lagi.
						end
						
						hatchBtn.Text = "SUCCESS!"
						hatchBtn.BackgroundColor3 = THEME.SUCCESS
							
						if not isMinimized then
							isMinimized = true
							miniBtn.Text = "^"
							local targetPos = UDim2.new(0.5, 0, 0.995, infoFrame.AbsoluteSize.Y - 36)
							TweenService:Create(infoFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
								Position = targetPos
							}):Play()
						end

						if wonFishId then
							print("🎡 [PlotController] Calling StartGacha with isMini:", isAutoMode)
							local gachaPromise = GachaController:StartGacha(id, wonFishId, isAutoMode)
							if gachaPromise and typeof(gachaPromise) == "table" and gachaPromise.await then
								gachaPromise:await()
							else
								-- Fallback wait if StartGacha doesn't return a promise
								if not isAutoMode then
									task.wait(3.5)
								else
									task.wait(1.5)
								end
							end
						else
							warn("❌ [PlotController] Gacha cancelled: wonFishId is STILL nil after fallback attempts.")
						end
						
						hatchBtn.Text = "HATCH EGG"
						hatchBtn.BackgroundColor3 = THEME.SUCCESS -- Kembalikan ke warna default
						hatchBtn.Active = true
						return true
					else
						hatchBtn.Text = "HATCH FAILED"
						hatchBtn.BackgroundColor3 = THEME.DANGER -- 🔧 MERAH JIKA GAGAL
						task.wait(1)
						hatchBtn.Text = "HATCH EGG"
						hatchBtn.BackgroundColor3 = THEME.SUCCESS
						hatchBtn.Active = true
						return false
					end
				end):catch(function(err)
					warn("🥚 [PlotController] Hatch error:", err)
					hatchBtn.Text = "ERROR"
					task.wait(1)
					hatchBtn.Text = "HATCH EGG"
					hatchBtn.Active = true
					return false
				end)
			end

			table.insert(uiConnections, hatchBtn.MouseButton1Click:Connect(function()
				performHatch(false)
			end))

			table.insert(uiConnections, autoHatchBtn.MouseButton1Click:Connect(function()
				isAutoHatching = not isAutoHatching
				if isAutoHatching then
					autoHatchBtn.Text = "STOP AUTO"
					autoHatchBtn.BackgroundColor3 = THEME.DANGER
					
					-- Auto hatch loop
					task.spawn(function()
						local loopId = id -- Simpan ID telur saat loop dimulai
						warn("🥚 [PlotController] Auto-hatch loop STARTED for ID:", loopId)
						
						while isAutoHatching do
							-- 🔧 CRITICAL: Use loopId to ensure we're hatching the right egg
							local targetEggId = loopId
							local state = ClientState:GetState()
							local currentStock = state and state.Inventory and state.Inventory.Egg and state.Inventory.Egg[targetEggId] or 0
							
							if currentStock <= 0 then
								warn("🥚 [PlotController] Auto hatch stopped: Out of stock")
								PlotController:StopAutoHatch()
								break
							end
							
							local promise = performHatch(true)
							
							if promise and typeof(promise) == "table" and promise.await then
								local success = promise:await()
								
								if not success then 
									warn("🥚 [PlotController] Auto-hatch stopped: performHatch returned false")
									PlotController:StopAutoHatch()
									break 
								end
							else
								warn("❌ [PlotController] NO PROMISE RETURNED from performHatch")
								PlotController:StopAutoHatch()
								break
							end
							
							task.wait(0.5) -- Small buffer between cycles
						end
						
						-- Final cleanup in case of loop break
						if isAutoHatching then
							PlotController:StopAutoHatch()
						end
					end)
				else
					autoHatchBtn.Text = "AUTO HATCH"
					autoHatchBtn.BackgroundColor3 = THEME.GOLD
				end
			end))
		end

		-- 🥚 POPULATE EGG REWARDS
		if rewardFrame and rewardList then
			rewardFrame.Visible = (category == "Egg")
			rewardList:ClearAllChildren()
			local rLayout = Instance.new("UIGridLayout", rewardList)
			rLayout.CellSize = UDim2.fromOffset(42, 42)
			rLayout.CellPadding = UDim2.fromOffset(6, 6)
			rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

			if category == "Egg" and itemData and itemData.eggReward then
				rewardListFrame.Size = UDim2.new(1, 0, 0, #itemData.eggReward > 4 and 100 or 50)
				for _, reward in pairs(itemData.eggReward) do
					local fishId = reward.fishId
					local fishData = Assets.GetItemData(fishId)
					if fishData then
						local fishModelName = fishData.mInfoName or fishData.mDropName or fishData.name
						local rewardBox = Instance.new("Frame", rewardList)
						rewardBox.Size = UDim2.fromScale(1, 1)
						rewardBox.BackgroundColor3 = THEME.SECONDARY
						rewardBox.BackgroundTransparency = 0.5
						Instance.new("UICorner", rewardBox).CornerRadius = UDim.new(0, 8)
						
						local boxStroke = Instance.new("UIStroke", rewardBox)
						boxStroke.Color = THEME["RARITY_" .. (fishData.rarity or "COMMON"):upper()] or THEME.ACCENT
						boxStroke.Thickness = 1.5
						boxStroke.Transparency = 0.4 -- 🔧 LEBIH TERLIHAT
						
						local vp, model = ViewportManager:CreateModelViewport(
							rewardBox,
							fishModelName,
							fishData.mInfoRotate or 0,
							fishData.mInfoScale or 1.1 -- 🔧 SEDIKIT LEBIH BESAR
						)
						
						if model then
							local baseRotation = model:GetPivot()
							local rot = 0
							task.spawn(function()
								while rewardBox and rewardBox.Parent do
									rot += task.wait() * 60 -- 🔧 SEDIKIT LEBIH CEPAT
									model:PivotTo(baseRotation * CFrame.Angles(0, math.rad(rot), 0))
								end
							end)
						end

						-- Chance Label AAA
						local chanceBG = Instance.new("Frame", rewardBox)
						chanceBG.Size = UDim2.new(1, 0, 0, 14)
						chanceBG.Position = UDim2.new(0, 0, 1, 0)
						chanceBG.AnchorPoint = Vector2.new(0, 1)
						chanceBG.BackgroundColor3 = Color3.new(0, 0, 0)
						chanceBG.BackgroundTransparency = 0.6
						chanceBG.ZIndex = 4
						Instance.new("UICorner", chanceBG).CornerRadius = UDim.new(0, 4)

						local chanceLbl = Instance.new("TextLabel", rewardBox)
						chanceLbl.Size = UDim2.new(1, 0, 0, 14)
						chanceLbl.Position = UDim2.new(0, 0, 1, 0)
						chanceLbl.AnchorPoint = Vector2.new(0, 1)
						chanceLbl.BackgroundTransparency = 1
						chanceLbl.Text = tostring(reward.chance) .. "%"
						chanceLbl.Font = Enum.Font.GothamBold
						chanceLbl.TextSize = 8
						chanceLbl.TextColor3 = THEME.GOLD
						chanceLbl.ZIndex = 5
					end
				end
			end
		end
		
		if category == "Food" or category == "Egg" then
			if toggleMenu then toggleMenu(false) end
			closeAllMenusExceptInfo()
		end
		
		-- Viewport update
		if infoModelContainer then
			infoModelContainer:ClearAllChildren() -- 🔧 FIXED: Hapus model lama agar tidak bertumpuk
			local _, model = ViewportManager:CreateModelViewport(
				infoModelContainer,
				modelName,
				itemData and itemData.mInfoRotate or 0,
				itemData and itemData.mInfoScale or 1
			)

			if infoRotationConn then
				infoRotationConn:Disconnect()
				infoRotationConn = nil
			end

			if model then
				local baseRotation = model:GetPivot()
				local currentRot = 0
				infoRotationConn = RunService.RenderStepped:Connect(function(dt)
					if not model or not model.Parent then
						if infoRotationConn then infoRotationConn:Disconnect() end
						return
					end
					currentRot += dt * 60 -- Slow rotation for info frame
					model:PivotTo(baseRotation * CFrame.Angles(0, math.rad(currentRot), 0))
				end)
			end
		end
		
		-- Reset minimize state when opening new info
		isMinimized = false
		if miniBtn then miniBtn.Text = "v" end
		if infoFrame then 
			infoFrame.Position = originalPos 
			infoFrame.Visible = true
			infoFrame.BackgroundTransparency = 1
			TweenService:Create(infoFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0
			}):Play()
		end
	end

	local function populateInventory(category: string)
		log("Populate inventory:", category)
		clearInventory()
		hideEmpty()

		local currentHoverItem: string? = nil
		local rotationConn: RBXScriptConnection? = nil
		local currentRotationY = 0

		local function stopRotation()
			if rotationConn then
				rotationConn:Disconnect()
				rotationConn = nil
			end
		end

		local function startRotation(model: Model, baseRotation: CFrame)
			stopRotation()
			currentRotationY = 0
			rotationConn = RunService.RenderStepped:Connect(function(dt)
				if not model or not model.Parent then 
					stopRotation()
					return 
				end
				currentRotationY += dt * 90 -- 90 degrees per second
				model:PivotTo(baseRotation * CFrame.Angles(0, math.rad(currentRotationY), 0))
			end)
		end

		local state = ClientState:GetState()
		log("Current state for inventory check:", 
			"State exists:", state ~= nil, 
			"Inventory exists:", state and state.Inventory ~= nil,
			"Category exists:", state and state.Inventory and state.Inventory[category] ~= nil
		)
		
		if not state or not state.Inventory then
			-- 🧪 DEBUG: Try to pull state again just in case
			log("Inventory missing in state, requesting refresh...")
			ClientState:Refresh():andThen(function(newState)
				if newState and newState.Inventory then
					log("Refresh successful, retrying populate...")
					populateInventory(category)
				else
					log("Refresh failed to provide inventory.")
				end
			end)
			
			showEmpty("DATA SEDANG DIMUAT...")
			return
		end

		local inventory = state.Inventory[category]
		if not inventory or next(inventory) == nil then
			showEmpty("INVENTORY KOSONG")
			return
		end

		local hasItem = false
		for id, count in pairs(inventory) do
			if typeof(count) ~= "number" or count <= 0 then continue end
			hasItem = true

			local item = Instance.new("TextButton", invScroll)
			item.Name = "InvItem_" .. id
			item.Size = UDim2.fromOffset(64, 64)
			item.BackgroundColor3 = THEME.SECONDARY
			item.AutoButtonColor = false
			item.Text = ""
			Instance.new("UICorner", item).CornerRadius = UDim.new(0, 12)

			local vpf = Instance.new("Frame", item)
			vpf.Size = UDim2.fromScale(0.85, 0.75) -- Sedikit lebih besar
			vpf.Position = UDim2.fromScale(0.5, 0.42)
			vpf.AnchorPoint, vpf.BackgroundTransparency = Vector2.new(0.5,0.5), 1

			local itemData = Assets.GetItemData(id)
			if not itemData then
				log("WARNING: No data for item", id)
				continue 
			end

			local modelName = itemData and (itemData.mInfoName or itemData.mDropName or itemData.name) or tostring(id)

			local _, model = ViewportManager:CreateModelViewport(
				vpf,
				modelName,
				itemData and itemData.mInfoRotate or 0,
				itemData and tonumber(itemData.mInfoScale) or 0.9,
				itemData -- Pass metadata (mInfoRotate, mInfoScale)
			)

			local baseRotation = model and model:GetPivot() or CFrame.new()

			item.MouseEnter:Connect(function()
				if model then
					startRotation(model, baseRotation)
				end
			end)

			item.MouseLeave:Connect(function()
				stopRotation()
				if model then
					model:PivotTo(baseRotation)
				end
			end)

			local nameLbl = Instance.new("TextLabel", item)
			nameLbl.Size = UDim2.new(1,0,0,12)
			nameLbl.Position = UDim2.new(0,0,1,-12)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 8
			nameLbl.TextColor3 = THEME.TEXT
			nameLbl.Text = modelName:upper()
			nameLbl.ZIndex = 3

			local nameBG = Instance.new("Frame", item)
			nameBG.Size = UDim2.new(1, 0, 0, 14)
			nameBG.Position = UDim2.new(0, 0, 1, 0)
			nameBG.AnchorPoint = Vector2.new(0, 1)
			nameBG.BackgroundColor3 = Color3.new(0, 0, 0)
			nameBG.BackgroundTransparency = 0.7
			nameBG.ZIndex = 2
			Instance.new("UICorner", nameBG).CornerRadius = UDim.new(0, 4)

			local bubble = Instance.new("Frame", item)
			bubble.Name = "CountBubble"
			bubble.Size = UDim2.fromOffset(20,20)
			bubble.Position = UDim2.new(1,-6,0,6)
			bubble.AnchorPoint = Vector2.new(1,0)
			bubble.BackgroundColor3 = THEME.ACCENT
			Instance.new("UICorner", bubble).CornerRadius = UDim.new(1,0)

			local countLbl = Instance.new("TextLabel", bubble)
			countLbl.Name = "CountLabel"
			countLbl.Size = UDim2.fromScale(1,1)
			countLbl.BackgroundTransparency = 1
			countLbl.Font = Enum.Font.GothamBlack
			countLbl.TextSize = 9
			countLbl.TextColor3 = THEME.PRIMARY
			countLbl.Text = "x"..tostring(count)

			item.MouseButton1Click:Connect(function()
				showItemInfo(id, count, category)
				if category == "Food" then
					PlotController:StartFoodDropMode(id)
				end
			end)
		end

		if not hasItem then showEmpty("INVENTORY KOSONG") end
	end

	--------------------------------------------------
	-- MENU STATE
	--------------------------------------------------
	local isOpen = false
	local currentMenu: string? = nil
	local destroyed = false
	-- local toggleMenu -- Forward declaration moved up

	local function forceCloseInventory()
		if destroyed then return end
		currentMenu = nil
		hideEmpty()
		hideItemInfo()
		DecorationController:CloseUI()
		menuFrame.Visible = false
		menuFrame.GroupTransparency = 1
		clearInventory()
		log("Inventory force closed")
	end

	local function closeInventoryFrame()
		if destroyed then return end
		currentMenu = nil
		hideEmpty()
		hideItemInfo()
		TweenService:Create(menuFrame, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 1,
			Position = menuFrame.Position + UDim2.fromScale(0.04, 0),
		}):Play()
		task.delay(0.14, function()
			if destroyed then return end
			menuFrame.Visible = false
			clearInventory()
			log("Inventory closed")
		end)
	end

	local function openInventoryFrame(category: string, anchorBtn: GuiObject)
		if destroyed then return end
		currentMenu = category
		populateInventory(category)

		local btnAbsPos = anchorBtn.AbsolutePosition
		local btnAbsSize = anchorBtn.AbsoluteSize
		local screenSize = Camera.ViewportSize

		local x = (btnAbsPos.X - 18) / screenSize.X
		local y = (btnAbsPos.Y + btnAbsSize.Y / 2) / screenSize.Y

		menuFrame.Position = UDim2.fromScale(x, y)
		menuFrame.Visible = true
		menuFrame.GroupTransparency = 1

		TweenService:Create(menuFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			GroupTransparency = 0,
			Position = UDim2.fromScale(x - 0.04, y),
		}):Play()

		log("Inventory opened:", category)
	end

	local function toggleSubMenu(category: string, btn: GuiObject)
		if destroyed then return end
		hideItemInfo()
		DecorationController:CloseUI()
		if currentMenu == category then
			closeInventoryFrame()
		else
			openInventoryFrame(category, btn)
		end
	end

	--------------------------------------------------
	-- TOGGLE MAIN MENU
	--------------------------------------------------
	toggleMenu = function(forceState: boolean?)
		if destroyed then return end
		
		if forceState ~= nil then
			if isOpen == forceState then return end
			isOpen = forceState
		else
			isOpen = not isOpen
		end

		log("Toggle menu:", isOpen)

		-- 🔧 NEW: If menu is opened, stop any active food drop mode
		if isOpen then
			PlotController:StopFoodDropMode()
			forceCloseInventory()
		else
			DecorationController:CloseUI()
			DecorationController:CancelPlacement()
		end

		local targets = {
			{btn = fishBtn, pos = -120},
			{btn = eggBtn, pos = -185},
			{btn = foodBtn, pos = -250},
			{btn = decorBtn, pos = -315},
			{btn = closeBtn, pos = -380},
		}

		for i, data in ipairs(targets) do
			if isOpen then
				data.btn.Visible = true
				TweenService:Create(data.btn, TweenInfo.new(0.2 + (i*0.03), Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Position = UDim2.new(0.5,0,1,data.pos),
				}):Play()
			else
				TweenService:Create(data.btn, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = UDim2.new(0.5,0,1,-36),
				}):Play()
				task.delay(0.14, function()
					if not isOpen and not destroyed then data.btn.Visible = false end
				end)
			end
		end
	end

	toggleBtn.MouseButton1Click:Connect(function()
		toggleMenu()
	end)

	--------------------------------------------------
	-- CATEGORY BUTTONS
	--------------------------------------------------
	fishBtn.MouseButton1Click:Connect(function() toggleSubMenu("Fish", fishBtn) end)
	eggBtn.MouseButton1Click:Connect(function() toggleSubMenu("Egg", eggBtn) end)
	foodBtn.MouseButton1Click:Connect(function() toggleSubMenu("Food", foodBtn) end)
	decorBtn.MouseButton1Click:Connect(function()
		if DecorationController:IsOpen() then
			DecorationController:CloseUI()
		else
			forceCloseInventory()
			DecorationController:OpenUI()
		end
	end)

	--------------------------------------------------
	-- CLOSE BUTTON (FULL CLEANUP)
	--------------------------------------------------
	closeBtn.MouseButton1Click:Connect(function()
		if destroyed then return end
		destroyed = true
		log("Close pressed — full UI cleanup")
		forceCloseInventory()
		DecorationController:CloseUI() -- Ensure decoration UI and selection modes are cleaned up
		sg:Destroy()
		onClose()
	end)

	--------------------------------------------------
	-- COIN SYNC
	--------------------------------------------------
	local function refreshCoins(state)
		state = state or ClientState:GetState()
		if state and state.Coins then
			coinLabel.Text = tostring(state.Coins)
			log("Coins refreshed:", state.Coins)
		end
	end
	refreshCoins()
	ClientState:OnChange(refreshCoins)

	--------------------------------------------------
	-- INVENTORY STATE SYNC
	--------------------------------------------------
	ClientState:OnChange(function(newState)
		-- 🔧 REALTIME INFO FRAME UPDATE (Update text and auto-close if empty)
		if infoFrame and infoFrame.Visible and currentSelectedId and currentSelectedCategory then
			local inventory = newState.Inventory and newState.Inventory[currentSelectedCategory]
			local currentStock = inventory and inventory[currentSelectedId] or 0
			
			if currentStock <= 0 then
				log("Stock empty for current item, auto-closing info frame")
				if currentSelectedCategory == "Food" then PlotController:StopFoodDropMode() end
				hideItemInfo()
			else
				-- Update the description text with new stock
				local itemData = Assets.GetItemData(currentSelectedId)
				if itemData and infoDesc then
					local statsText = ""
					if currentSelectedCategory == "Food" then
						statsText = string.format(
							"RARITY: %s\nEXP: +%d\nHUNGER CD: %ds\nSTOCK: x%d",
							(itemData.rarity or "COMMON"):upper(),
							itemData.addExp or 0,
							itemData.addHungerCD or 0,
							currentStock
						)
					elseif currentSelectedCategory == "Fish" then
						statsText = string.format(
							"RARITY: %s\nNAME: %s\nEXP: +%d\nHUNGER CD: %ds",
							(itemData.rarity or "COMMON"):upper(),
							(itemData.name or "UNKNOWN"):upper(),
							itemData.addExp or 0,
							itemData.addHungerCD or 0
						)
					else
						statsText = itemData.desc or "Jumlah: x"..tostring(currentStock)
					end
					infoDesc.Text = statsText
				end
			end
		end

		if not menuFrame.Visible or not currentMenu then return end
		
		local inventory = newState.Inventory and newState.Inventory[currentMenu]
		if not inventory then 
			clearInventory()
			showEmpty("INVENTORY KOSONG")
			return 
		end
		
		-- Update existing or remove
		local hasAny = false
		for _, itemUI in ipairs(invScroll:GetChildren()) do
			if not itemUI:IsA("TextButton") or not itemUI.Name:find("InvItem_") then continue end
			
			local id = itemUI.Name:gsub("InvItem_", "")
			local count = inventory[id]
			
			if not count or count <= 0 then
				itemUI:Destroy()
				log("Item removed from UI:", id)
			else
				hasAny = true
				local bubble = itemUI:FindFirstChild("CountBubble")
				local countLbl = bubble and bubble:FindFirstChild("CountLabel") :: TextLabel?
				if countLbl then
					countLbl.Text = "x" .. tostring(count)
				end
			end
		end
		
		-- Check if we need to show empty
		if not hasAny then
			showEmpty("INVENTORY KOSONG")
		end
	end)

	-- 🧪 EXPERIMENTAL: Force re-populate inventory on ANY state change if visible
	ClientState:OnChange(function(newState)
		if menuFrame.Visible and currentMenu then
			log("State change detected, force re-populating inventory:", currentMenu)
			populateInventory(currentMenu)
		end
	end)

	sg.Parent = Player.PlayerGui
	log("Underwater GUI mounted")
	return sg
end

local AQUARIUM_SIZE = Vector3.new(60, 35, 8)

local function getMousePlanePos(mouse: Mouse)
	local ray = Camera:ScreenPointToRay(mouse.X, mouse.Y)
	local planeZ = UNDERWATER_POS.Z -- 🔧 FIXED: Gunakan tepat di tengah aquarium (Z=5000)
	
	-- t = (planeZ - ray.Origin.Z) / ray.Direction.Z
	if math.abs(ray.Direction.Z) < 0.0001 then 
		log("Ray parallel to plane")
		return nil 
	end
	local t = (planeZ - ray.Origin.Z) / ray.Direction.Z

	local pos = ray.Origin + ray.Direction * t
	
	-- 🔧 FORCE Z POSITION: Pastikan Z benar-benar 0 (relatif ke UNDERWATER_POS)
	return Vector3.new(pos.X, pos.Y, UNDERWATER_POS.Z)
end

function PlotController:AnimateFoodDrop(foodId: string, position: Vector3)
	local itemData = Assets.GetItemData(foodId)
	local modelName = itemData and (itemData.mDropName or itemData.name) or foodId
	
	local assets = ReplicatedStorage:WaitForChild("assets"):WaitForChild("models")
	local foodModel = assets:FindFirstChild(modelName, true)
	
	if not foodModel then
		-- Try last resort search
		for _, desc in ipairs(assets:GetDescendants()) do
			if (desc.Name == modelName or desc.Name == "M_Food/"..modelName) and desc:IsA("Model") then
				foodModel = desc
				break
			end
		end
		
		if not foodModel and modelName:find("/") then
			local actualName = modelName:split("/")[#modelName:split("/")]
			foodModel = assets:FindFirstChild(actualName, true)
		end
	end

	if not foodModel or not foodModel:IsA("Model") then 
		log("ERROR: Food model not found for animation:", modelName)
		return 
	end
	
	local drop = foodModel:Clone()
	
	-- 🔧 ENSURE PRIMARYPART
	if not drop.PrimaryPart then
		local part = drop:FindFirstChildWhichIsA("BasePart", true)
		if part then
			drop.PrimaryPart = part
		else
			log("ERROR: Food model has no parts:", modelName)
			drop:Destroy()
			return
		end
	end
	
	drop.Parent = workspace:FindFirstChild("UnderwaterWorld") or workspace
	
	-- Apply mDropRotate and mDropScale
	local dropRotate = itemData and itemData.mDropRotate or "0,0,0"
	local dropScale = itemData and itemData.mDropScale or 1
	
	local rotationCFrame = parseRotation(dropRotate)
	drop:PivotTo(CFrame.new(position) * rotationCFrame)
	
	if dropScale ~= 1 then
		drop:ScaleTo(dropScale)
	end
	
	-- 🎭 PROFESSIONAL ANIMATION (FALL + ROTATION)
	local floorY = UNDERWATER_POS.Y - (AQUARIUM_SIZE.Y / 2)
	local fallTargetY = floorY + 1.8 -- 🔧 KEMBALIKAN: Agar benar-benar di atas pasir sesuai permintaan
	
	-- Random speed & rotation
	local fallSpeed = 3 + math.random() * 2.5 -- 🔧 KURANGI LAGI: Lebih lambat (sebelumnya 5 + random 4)
	local rotSpeed = Vector3.new(
		math.random(-100, 100),
		math.random(-100, 100),
		math.random(-100, 100)
	)

	local currentY = position.Y
	local currentRotation = CFrame.Angles(0,0,0) -- Simpan state rotasi terpisah
	
	local rotConn
	rotConn = RunService.Heartbeat:Connect(function(dt)
		if not drop or not drop.Parent then
			if rotConn then rotConn:Disconnect() end
			return
		end

		currentY -= fallSpeed * dt
		
		-- Update rotasi state
		currentRotation *= CFrame.Angles(
			math.rad(rotSpeed.X * dt),
			math.rad(rotSpeed.Y * dt),
			math.rad(rotSpeed.Z * dt)
		)
		
		if currentY <= fallTargetY then
			if rotConn then rotConn:Disconnect() end
			currentY = fallTargetY
			
			-- 🔧 FIXED: Statis diam total (posisi X, Z dan rotasi dikunci) - TANPA EFEK PANTUL
			drop:PivotTo(CFrame.new(position.X, fallTargetY, position.Z) * currentRotation)
			
			-- Jalankan sequence landing di thread terpisah
			task.spawn(function()
				-- 1. BERKEDIP (3 Detik) - Langsung berkedip setelah mendarat
				local blinkStart = os.clock()
				local blinkDuration = 3
				local isVisible = true
				
				while drop and drop.Parent and (os.clock() - blinkStart < blinkDuration) do
					local elapsed = os.clock() - blinkStart
					local ratio = elapsed / blinkDuration
					local waitTime = math.max(0.04, 0.35 * (1 - ratio))
					
					isVisible = not isVisible
					for _, p in ipairs(drop:GetDescendants()) do
						if p:IsA("BasePart") then
							p.Transparency = isVisible and 0 or 1
						end
					end
					
					task.wait(waitTime)
				end

				-- 2. HILANG
				if drop then drop:Destroy() end
			end)
		else
			-- Terapkan posisi dan rotasi selama jatuh
			drop:PivotTo(CFrame.new(position.X, currentY, position.Z) * currentRotation)
		end
	end)
end

--------------------------------------------------
-- FOOD DROP LOGIC
--------------------------------------------------
local activeFoodModel: Model? = nil
local dropModeActive = false
-- local currentFoodId: string? = nil -- Moved up to UI REFERENCES

-- local AQUARIUM_SIZE = Vector3.new(60, 35, 8) -- Moved up

local dropConnections = {}
local lastDropTime = 0
local DROP_COOLDOWN = 0.1 -- 🔧 COOLDOWN SINGKAT: Mencegah spam berlebihan tapi tetap responsif

function PlotController:StartFoodDropMode(foodId: string)
	if dropModeActive and currentFoodId == foodId then return end
	
	-- Clean up previous mode if switching food
	self:StopFoodDropMode()
	
	dropModeActive = true
	currentFoodId = foodId
	
	local itemData = Assets.GetItemData(foodId)
	local modelName = itemData and (itemData.mDropName or itemData.name) or foodId
	log("Starting food drop mode:", foodId, "Model:", modelName)
	
	-- Create preview model
	local assets = ReplicatedStorage:WaitForChild("assets"):WaitForChild("models")
	
	-- Debug: list children of models folder
	log("Searching for model:", modelName)
	local foodModel = assets:FindFirstChild(modelName, true)
	if not foodModel then
		-- Try last resort search
		for _, desc in ipairs(assets:GetDescendants()) do
			if (desc.Name == modelName or desc.Name == "M_Food/"..modelName) and desc:IsA("Model") then
				foodModel = desc
				break
			end
		end
	end
	
	local mouse = Player:GetMouse()
	if foodModel and foodModel:IsA("Model") then
		log("Found food model, cloning...")
		activeFoodModel = foodModel:Clone()
		
		-- 🔧 ENSURE PRIMARYPART for preview
		if not activeFoodModel.PrimaryPart then
			local part = activeFoodModel:FindFirstChildWhichIsA("BasePart", true)
			if part then activeFoodModel.PrimaryPart = part end
		end

		-- Apply mDropRotate and mDropScale for preview
		local dropRotate = itemData and itemData.mDropRotate or "0,0,0"
		local dropScale = itemData and itemData.mDropScale or 1
		local rotationCFrame = parseRotation(dropRotate)
		
		-- Apply scale before setting position
		if dropScale ~= 1 then
			activeFoodModel:ScaleTo(dropScale)
		end

		-- Set initial position immediately
		local targetPos = getMousePlanePos(mouse)
		if targetPos then
			activeFoodModel:PivotTo(CFrame.new(targetPos) * rotationCFrame)
		end
		
		activeFoodModel.Parent = workspace:FindFirstChild("UnderwaterWorld") or workspace
		log("Preview model parented to UnderwaterWorld at pivot:", activeFoodModel:GetPivot())
		
		for _, part in ipairs(activeFoodModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Transparency = 0.5
				part.Anchored = true
			end
		end
	else
		log("ERROR: Food model not found in assets/models:", modelName)
	end
	
	-- Mouse tracking
	dropConnections.Render = RunService.RenderStepped:Connect(function()
		local targetPos = getMousePlanePos(mouse)
		if not targetPos then 
			if activeFoodModel then activeFoodModel.Parent = nil end
			return 
		end
		
		local uwFolder = workspace:FindFirstChild("UnderwaterWorld") or workspace
		if activeFoodModel and activeFoodModel.Parent ~= uwFolder then
			activeFoodModel.Parent = uwFolder
		end
		
		-- Check bounds
		local halfSize = AQUARIUM_SIZE / 2
		local minBound = UNDERWATER_POS - halfSize
		local maxBound = UNDERWATER_POS + halfSize
		
		local inBounds = (targetPos.X >= minBound.X and targetPos.X <= maxBound.X and
						  targetPos.Y >= minBound.Y and targetPos.Y <= maxBound.Y)
		
		if activeFoodModel then
			local dropRotate = itemData and itemData.mDropRotate or "0,0,0"
			local rotationCFrame = parseRotation(dropRotate)
			activeFoodModel:PivotTo(CFrame.new(targetPos) * rotationCFrame)
			
			-- Color indicator
			local color = inBounds and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
			for _, desc in ipairs(activeFoodModel:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.Color = color
					desc.Transparency = 0.3 -- Sedikit lebih pekat agar terlihat
					desc.CanQuery = false -- Jangan terdeteksi raycast mouse
					desc.CastShadow = false
				end
			end
		end

		-- 🔧 REALTIME STOCK UPDATE (Update text di Info Frame)
		local state = ClientState:GetState()
		local currentStock = state.Inventory and state.Inventory.Food and state.Inventory.Food[foodId] or 0
		
		-- 🔧 FIXED: Tutup info frame jika stok habis
		if currentStock <= 0 then
			self:StopFoodDropMode()
			hideItemInfo()
			return
		end

		if infoDesc then
			local statsText = string.format(
				"RARITY: %s\nEXP: +%d\nHUNGER CD: %ds\nSTOCK: x%d",
				(itemData.rarity or "COMMON"):upper(),
				itemData.addExp or 0,
				itemData.addHungerCD or 0,
				currentStock
			)
			infoDesc.Text = statsText
		end
	end)
	
	-- Click to drop
	dropConnections.Input = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local targetPos = getMousePlanePos(mouse)
			if not targetPos then return end
			
			-- Check bounds before firing
			local halfSize = AQUARIUM_SIZE / 2
			local minBound = UNDERWATER_POS - halfSize
			local maxBound = UNDERWATER_POS + halfSize
			
			if targetPos.X >= minBound.X and targetPos.X <= maxBound.X and
			   targetPos.Y >= minBound.Y and targetPos.Y <= maxBound.Y then
				
				-- 🔧 DEBOUNCE / COOLDOWN CHECK
				local now = os.clock()
				if now - lastDropTime < DROP_COOLDOWN then return end
				lastDropTime = now

				log("Firing RequestDropFood for:", currentFoodId, "at", targetPos, "owner:", currentVisitingOwnerId)
				Remote:FireServer("RequestDropFood", currentFoodId, targetPos, currentVisitingOwnerId)
				
				-- 🔧 ANIMATE LOCALLY IMMEDIATELY (Better UX)
				self:AnimateFoodDrop(currentFoodId, targetPos)

				-- 🔧 AUTO MINIMIZE ON FIRST DROP
				if not isMinimized then
					isMinimized = true
					if miniBtn then miniBtn.Text = "^" end
					local targetPos = UDim2.new(0.5, 0, 0.995, infoFrame.AbsoluteSize.Y - 36)
					TweenService:Create(infoFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Position = targetPos
					}):Play()
				end
				
				-- If stock is 1 (about to be 0), stop drop mode
				local state = ClientState:GetState()
				local stock = state.Inventory and state.Inventory.Food and state.Inventory.Food[currentFoodId] or 0
				if stock <= 1 then
					log("Out of stock, stopping drop mode")
					self:StopFoodDropMode()
				end
			else
				log("Drop rejected: Out of bounds", targetPos)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			log("Right click — stopping food drop mode")
			self:StopFoodDropMode()
		end
	end)
end

function PlotController:StopFoodDropMode()
	dropModeActive = false
	currentFoodId = nil
	if activeFoodModel then
		activeFoodModel:Destroy()
		activeFoodModel = nil
	end
	for name, conn in pairs(dropConnections) do
		conn:Disconnect()
		log("Disconnected drop connection:", name)
	end
	table.clear(dropConnections)
end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------
function PlotController:StopAutoHatch()
	isAutoHatching = false
	if autoHatchBtn then
		autoHatchBtn.Text = "AUTO HATCH"
		autoHatchBtn.BackgroundColor3 = THEME.GOLD
	end
	
	-- Cleanup Stop button in Gacha UI if exists
	local PlayerGui = Player:WaitForChild("PlayerGui")
	local miniGachaUI = PlayerGui:FindFirstChild("GachaMiniUI")
	if miniGachaUI and miniGachaUI:FindFirstChild("StopAutoBtn") then
		miniGachaUI.StopAutoBtn:Destroy()
	end
	
	log("Auto hatch stopped externally")
end

function PlotController:Init()
	if initialized then return end
	initialized = true
	
	-- Handle food drops from server
	Remote:On("FoodDropped", function(playerUserId: number, foodId: string, position: Vector3, ownerId: number)
		-- 🛡️ DEBUG: Log incoming drop
		log("Incoming FoodDropped signal. OwnerId:", ownerId, "CurrentVisiting:", currentVisitingOwnerId)
		
		-- 🔧 FIXED: Check ownerId against currentVisitingOwnerId
		-- ownerId is the owner of the plot where the food was dropped
		if ownerId ~= currentVisitingOwnerId then 
			log("Ignoring drop: Not in this aquarium. PlotOwner:", ownerId, "CurrentVisiting:", currentVisitingOwnerId)
			return 
		end
		
		-- 🛡️ IGNORE OWN DROPS (Already animated locally)
		if playerUserId == Player.UserId then 
			log("Ignoring own drop signal to prevent double animation")
			return 
		end
		
		local player = Players:GetPlayerByUserId(playerUserId)
		log("Food dropped by", player and player.Name or "Unknown", ":", foodId)
		self:AnimateFoodDrop(foodId, position)
	end)

	RunService.Heartbeat:Connect(function()
		for _, prompt in ipairs(workspace:GetDescendants()) do
			if prompt:IsA("ProximityPrompt") and prompt.Name == "PlotPrompt" then
				prompt.Enabled = not isInteracting
				local plot = prompt.Parent and prompt.Parent.Parent
				if plot and plot:IsA("Model") then
					local ownerName = plot.Name:gsub("Plot_", "")
					prompt.ActionText = (ownerName == Player.Name) and "MANAGE AQUARIUM" or "VISIT AQUARIUM"
					prompt.ObjectText = ownerName:upper()
				end
			end
		end
	end)

	Remote:On("RequestEnterAquariumClient", function(plotModel: Model, owner: Player)
		if isInteracting then return end
		isInteracting = true
		log("RequestEnterAquariumClient")
		Remote:FireServer("RequestEnterAquarium", plotModel)
	end)

	Remote:On("EnterAquariumSequence", function(owner: Player, plotModel: Model)
		log("EnterAquariumSequence")
		self:StartEnterSequence(owner, plotModel)
	end)
end

--------------------------------------------------
-- ENTER SEQUENCE
--------------------------------------------------
function PlotController:StartEnterSequence(owner: Player, plotModel: Model)
	log("StartEnterSequence")
	currentVisitingOwnerId = owner.UserId
	setControlsEnabled(false)
	MainHUD.SetHUDVisible(false)
	isInteracting = true

	GenerateUnderwaterAreaLocal()

	Camera.CameraType = Enum.CameraType.Scriptable
	local pivot = plotModel:GetPivot()
	local camPos = pivot.Position + (pivot.LookVector * -3) + Vector3.new(0,2,0)
	TweenService:Create(Camera, TweenInfo.new(1.2, Enum.EasingStyle.Quart), {
		CFrame = CFrame.lookAt(camPos, pivot.Position + Vector3.new(0,2,0)),
	}):Play()
	task.wait(1)

	local loadingSg, loadingFrame, loadingText = createLoadingScreen()
	TweenService:Create(loadingFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
	TweenService:Create(loadingText, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	task.wait(0.6)

	Camera.CFrame = CFrame.lookAt(
		UNDERWATER_POS + Vector3.new(0, -7, 15), -- 🔧 ZOOM IN (+1) & TURUN (+1) LAGI
		UNDERWATER_POS + Vector3.new(0, -7, 0)
	)

	activeUwGui = createUnderwaterGui(function()
		log("Underwater onClose")
		self:StartExitSequence(plotModel, loadingSg, activeUwGui)
	end)

	task.wait(0.5)
	TweenService:Create(loadingFrame, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
	TweenService:Create(loadingText, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
end

function PlotController:ToggleUI(visible: boolean)
	if activeUwGui then
		activeUwGui.Enabled = visible
	end
end

--------------------------------------------------
-- EXIT SEQUENCE
--------------------------------------------------
function PlotController:StartExitSequence(plotModel: Model, loadingSg: ScreenGui, uwGui: ScreenGui)
	log("StartExitSequence")
	currentVisitingOwnerId = nil

	local frame = loadingSg.Frame
	local text = frame.TextLabel

	TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
	TweenService:Create(text, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	task.wait(0.6)

	if activeUwGui then
		activeUwGui:Destroy()
		activeUwGui = nil
		log("Underwater GUI destroyed")
	end

	self:StopFoodDropMode()

	local pivot = plotModel:GetPivot()
	Camera.CFrame = CFrame.lookAt(
		pivot.Position + (pivot.LookVector * -3) + Vector3.new(0,2,0),
		pivot.Position + Vector3.new(0,2,0)
	)

	task.wait(0.2)
	TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(text, TweenInfo.new(0.5), {TextTransparency = 1}):Play()

	local char = Player.Character
	if char and char.PrimaryPart then
		local targetCF = char.PrimaryPart.CFrame * CFrame.new(0,5,10)
		local zoomOut = TweenService:Create(Camera, TweenInfo.new(1, Enum.EasingStyle.Quart), {
			CFrame = CFrame.lookAt(targetCF.Position, char.PrimaryPart.Position),
		})
		zoomOut:Play()
		zoomOut.Completed:Wait()
	end

	Camera.CameraType = Enum.CameraType.Custom
	setControlsEnabled(true)
	MainHUD.SetHUDVisible(true)
	loadingSg:Destroy()
	isInteracting = false
	log("Exit sequence complete")
end

--------------------------------------------------
-- INIT
--------------------------------------------------
PlotController:Init()
log("PlotController initialized")
return PlotController
