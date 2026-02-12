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
local ViewportManager = require(ReplicatedStorage.Shared:WaitForChild("ViewportManager"))

--------------------------------------------------
-- CORE VARS
--------------------------------------------------
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlotController = {}
local UNDERWATER_POS = Vector3.new(5000, -82.5, 5000) -- CENTER of aquarium
local isInteracting = false

--------------------------------------------------
-- ASSETS & THEME
--------------------------------------------------
local FRAME_ICO, MENU_ICO, FISH_ICO, CLOSE_ICO, COIN_ICO, EGG_ICO, FOOD_ICO

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

	local sg = Instance.new("ScreenGui")
	sg.Name, sg.ResetOnSpawn = "UnderwaterGui", false

	--------------------------------------------------
	-- MENU CONTAINER (BOTTOM RIGHT)
	--------------------------------------------------
	local menuContainer = Instance.new("Frame", sg)
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
	local grad = Instance.new("UIGradient", menuFrame)
	grad.Color, grad.Rotation = ColorSequence.new(THEME.GRADIENT_TOP, THEME.SECONDARY), 90

	local shadow = Instance.new("ImageLabel", menuFrame)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageTransparency = 0.9
	shadow.Size = UDim2.new(1, 32, 1, 32)
	shadow.Position = UDim2.new(0, -16, 0, -16)
	shadow.ZIndex = 0

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
	-- ITEM INFO PANEL (FIXED POS + LOWER + NO OVERLAY BUG)
	--------------------------------------------------
	local infoFrame = Instance.new("Frame", sg)
	infoFrame.Name = "ItemInfoPanel"
	infoFrame.Size = UDim2.fromScale(0.3, 0)
	infoFrame.AutomaticSize = Enum.AutomaticSize.Y
	infoFrame.Position = UDim2.fromScale(0.5, 0.975)
	infoFrame.AnchorPoint = Vector2.new(0.5, 1)
	infoFrame.BackgroundColor3 = THEME.PRIMARY
	infoFrame.BackgroundTransparency = 1
	infoFrame.Visible = false
	infoFrame.ZIndex = 1 -- 🔧 DIPERKECIL agar tidak menimpa konten internal

	Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0, 18)
	local infoStroke = Instance.new("UIStroke", infoFrame)
	infoStroke.Color, infoStroke.Thickness = THEME.ACCENT, 2

	-- 🔧 CONTENT CONTAINER: agar UIListLayout & Padding tidak mengganggu tombol close
	local contentContainer = Instance.new("Frame", infoFrame)
	contentContainer.Name = "Content"
	contentContainer.Size = UDim2.fromScale(1, 0)
	contentContainer.AutomaticSize = Enum.AutomaticSize.Y
	contentContainer.BackgroundTransparency = 1

	local infoPadding = Instance.new("UIPadding", contentContainer)
	infoPadding.PaddingLeft = UDim.new(0, 14)
	infoPadding.PaddingRight = UDim.new(0, 14)
	infoPadding.PaddingTop = UDim.new(0, 12)
	infoPadding.PaddingBottom = UDim.new(0, 12)

	local infoLayout = Instance.new("UIListLayout", contentContainer)
	infoLayout.Padding = UDim.new(0, 10)
	infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local infoTitle = Instance.new("TextLabel", contentContainer)
	infoTitle.Size = UDim2.fromScale(1, 0)
	infoTitle.AutomaticSize = Enum.AutomaticSize.Y
	infoTitle.BackgroundTransparency = 1
	infoTitle.Font = Enum.Font.GothamBlack
	infoTitle.TextSize = 18
	infoTitle.TextColor3 = THEME.TEXT
	infoTitle.TextWrapped = true
	infoTitle.Text = "ITEM INFO"

	local infoName = Instance.new("TextLabel", contentContainer)
	infoName.Size = UDim2.fromScale(1, 0)
	infoName.AutomaticSize = Enum.AutomaticSize.Y
	infoName.BackgroundTransparency = 1
	infoName.Font = Enum.Font.GothamBold
	infoName.TextSize = 14
	infoName.TextColor3 = THEME.ACCENT
	infoName.TextWrapped = true
	infoName.Text = ""

	local infoDesc = Instance.new("TextLabel", contentContainer)
	infoDesc.Size = UDim2.fromScale(1, 0)
	infoDesc.AutomaticSize = Enum.AutomaticSize.Y
	infoDesc.BackgroundTransparency = 1
	infoDesc.Font = Enum.Font.GothamMedium
	infoDesc.TextSize = 12
	infoDesc.TextColor3 = THEME.TEXT
	infoDesc.TextWrapped = true
	infoDesc.Text = ""

	--------------------------------------------------
	-- ACTION BUTTONS CONTAINER
	--------------------------------------------------
	local actionContainer = Instance.new("Frame", contentContainer)
	actionContainer.Size = UDim2.fromScale(1, 0)
	actionContainer.AutomaticSize = Enum.AutomaticSize.Y
	actionContainer.BackgroundTransparency = 1

	local actionLayout = Instance.new("UIListLayout", actionContainer)
	actionLayout.Padding = UDim.new(0, 8)
	actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	--------------------------------------------------
	-- HATCH BUTTON (ONLY FOR EGG)
	--------------------------------------------------
	local hatchBtn = Instance.new("TextButton", actionContainer)
	hatchBtn.Size = UDim2.fromScale(0.7, 0)
	hatchBtn.AutomaticSize = Enum.AutomaticSize.Y
	hatchBtn.BackgroundColor3 = THEME.SUCCESS
	hatchBtn.TextColor3 = THEME.PRIMARY
	hatchBtn.Font = Enum.Font.GothamBlack
	hatchBtn.TextSize = 13
	hatchBtn.Text = "HATCH"
	hatchBtn.Visible = false
	Instance.new("UICorner", hatchBtn).CornerRadius = UDim.new(0, 10)

	hatchBtn.MouseEnter:Connect(function()
		TweenService:Create(hatchBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(110, 240, 170)}):Play()
	end)
	hatchBtn.MouseLeave:Connect(function()
		TweenService:Create(hatchBtn, TweenInfo.new(0.12), {BackgroundColor3 = THEME.SUCCESS}):Play()
	end)

	hatchBtn.MouseButton1Click:Connect(function()
		log("Hatch requested for:", infoName.Text)
		Remote:FireServer("RequestHatchEgg", infoName.Text)
	end)

	--------------------------------------------------
	-- CLOSE BUTTON (INFO FRAME) 🔧 FIXED
	--------------------------------------------------
    local infoClose = Instance.new("ImageButton", infoFrame)
    infoClose.Size = UDim2.fromOffset(22, 22)
    infoClose.Position = UDim2.new(1, -10, 0, 10) -- Pojok kanan atas (tanpa gangguan padding)
    infoClose.AnchorPoint = Vector2.new(1, 0)
    infoClose.BackgroundTransparency = 1
    infoClose.Image = CLOSE_ICO
    infoClose.ImageColor3 = Color3.fromRGB(255, 0, 0) -- MERAH MURNI
    infoClose.AutoButtonColor = false
    infoClose.ZIndex = 10 -- Dipastikan di atas content



	local closeAspect = Instance.new("UIAspectRatioConstraint", infoClose)
	closeAspect.AspectRatio = 1

	infoClose.MouseEnter:Connect(function()
		TweenService:Create(infoClose, TweenInfo.new(0.12), {
			ImageTransparency = 0,
			Size = UDim2.fromOffset(26, 26),
		}):Play()
	end)

	infoClose.MouseLeave:Connect(function()
		TweenService:Create(infoClose, TweenInfo.new(0.12), {
			ImageTransparency = 0,
			Size = UDim2.fromOffset(22, 22),
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
	local closeBtn = createIconButton(CLOSE_ICO, UDim2.new(0.5, 0, 1, -36), 52, "Close", THEME.DANGER)

	fishBtn.Visible, eggBtn.Visible, foodBtn.Visible, closeBtn.Visible = false, false, false, false
	fishBtn.Parent, eggBtn.Parent, foodBtn.Parent, closeBtn.Parent = menuContainer, menuContainer, menuContainer, menuContainer

	--------------------------------------------------
	-- COIN DISPLAY (AUTO FIT CONTENT + TEXT WIDTH)
	--------------------------------------------------
	local coinFrame = Instance.new("Frame", sg)
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

	local function hideItemInfo()
		if not infoFrame.Visible then return end
		TweenService:Create(infoFrame, TweenInfo.new(0.12), {
			BackgroundTransparency = 1
		}):Play()
		task.delay(0.12, function()
			infoFrame.Visible = false
			hatchBtn.Visible = false
			-- 🔧 REMOVED: PlotController:StopFoodDropMode() here 
			-- because we want drop mode to continue after clicking "Drop"
		end)
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
		local itemData = Assets.GetItemData(id)
		local modelName = itemData and (itemData.mInfoName or itemData.mDropName or itemData.name) or tostring(id)

		infoName.Text = modelName:upper()
		infoDesc.Text = itemData and itemData.desc or "Jumlah: x"..tostring(count)

		hatchBtn.Visible = (category == "Egg")

		-- 🔧 DROP BUTTON (ONLY FOR FOOD)
		local dropBtn = actionContainer:FindFirstChild("DropButton") :: TextButton?
		if not dropBtn then
			dropBtn = hatchBtn:Clone() :: TextButton
			dropBtn.Name = "DropButton"
			dropBtn.Parent = actionContainer
			dropBtn.Text = "DROP"
			dropBtn.BackgroundColor3 = THEME.ACCENT
		end
		dropBtn.Visible = (category == "Food")
		
		-- Clear old connections
		if uiConnections[dropBtn] then
			uiConnections[dropBtn]:Disconnect()
			uiConnections[dropBtn] = nil
		end
		
		uiConnections[dropBtn] = dropBtn.MouseButton1Click:Connect(function()
			log("Drop requested for:", id)
			PlotController:StartFoodDropMode(id)
			hideItemInfo()
		end)

		-- 🔧 HIDE CATEGORY MENU: trigger toggle button false
		if toggleMenu then toggleMenu(false) end
		closeAllMenusExceptInfo()

		infoFrame.Visible = true
		infoFrame.BackgroundTransparency = 1
		TweenService:Create(infoFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0
		}):Play()
	end

	-- 🔧 CLOSE INFO FRAME: hanya toggle panel info, tidak mengganggu menu
	infoClose.MouseButton1Click:Connect(function()
		hideItemInfo()
	end)

	local function populateInventory(category: string)
		log("Populate inventory:", category)
		clearInventory()
		hideEmpty()

		local state = ClientState:GetState()
		log("Current state for inventory:", state ~= nil, state and state.Inventory ~= nil)
		if not state or not state.Inventory then
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

			local stroke = Instance.new("UIStroke", item)
			stroke.Color, stroke.Thickness = THEME.GRADIENT_TOP, 1

			local vpf = Instance.new("Frame", item)
			vpf.Size = UDim2.fromScale(0.82, 0.7)
			vpf.Position = UDim2.fromScale(0.5, 0.38)
			vpf.AnchorPoint, vpf.BackgroundTransparency = Vector2.new(0.5,0.5), 1

			local itemData = Assets.GetItemData(id)
			local modelName = itemData and (itemData.mInfoName or itemData.mDropName or itemData.name) or tostring(id)

			ViewportManager:CreateModelViewport(
				vpf,
				modelName,
				itemData and itemData.mInfoRotate or 0,
				itemData and tonumber(itemData.mInfoScale) or 0.9,
				itemData -- Pass metadata (mInfoRotate, mInfoScale)
			)

			local nameLbl = Instance.new("TextLabel", item)
			nameLbl.Size = UDim2.new(1,0,0,12)
			nameLbl.Position = UDim2.new(0,0,1,-12)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 8
			nameLbl.TextColor3 = THEME.TEXT
			nameLbl.Text = modelName:upper()

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
		end

		local targets = {
			{btn = fishBtn, pos = -120},
			{btn = eggBtn, pos = -185},
			{btn = foodBtn, pos = -250},
			{btn = closeBtn, pos = -315},
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

	--------------------------------------------------
	-- CLOSE BUTTON (FULL CLEANUP)
	--------------------------------------------------
	closeBtn.MouseButton1Click:Connect(function()
		if destroyed then return end
		destroyed = true
		log("Close pressed — full UI cleanup")
		forceCloseInventory()
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

	sg.Parent = Player.PlayerGui
	log("Underwater GUI mounted")
	return sg
end

local AQUARIUM_SIZE = Vector3.new(60, 35, 8)

local function getMousePlanePos(mouse: Mouse)
	local ray = Camera:ScreenPointToRay(mouse.X, mouse.Y)
	local planeZ = UNDERWATER_POS.Z + 4 -- 🔧 Majukan ke Z=5004 agar benar-benar di depan BackgroundWall
	
	-- t = (planeZ - origin.Z) / direction.Z
	if math.abs(ray.Direction.Z) < 0.0001 then 
		log("Ray parallel to plane")
		return nil 
	end
	local t = (planeZ - ray.Origin.Z) / ray.Direction.Z
	
	-- We allow negative t if the plane is behind the camera but within range? 
	-- Actually, for an aquarium view, the plane SHOULD be in front.
	if t < 0 then 
		-- log("Ray pointing away from plane")
		-- return nil 
	end
	
	local pos = ray.Origin + ray.Direction * t
	return pos
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
	drop.Parent = workspace:FindFirstChild("UnderwaterWorld") or workspace
	
	-- Apply mDropRotate and mDropScale
	local dropRotate = itemData and itemData.mDropRotate or "0,0,0"
	local dropScale = itemData and itemData.mDropScale or 1
	
	local rotationCFrame = parseRotation(dropRotate)
	drop:PivotTo(CFrame.new(position) * rotationCFrame)
	
	if dropScale ~= 1 then
		if drop.PrimaryPart then
			drop:ScaleTo(dropScale)
		else
			-- Fallback if no PrimaryPart
			for _, part in ipairs(drop:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Size *= dropScale
				end
			end
		end
	end
	
	-- Fall animation
	local floorY = UNDERWATER_POS.Y - (AQUARIUM_SIZE.Y / 2)
	local fallTargetY = floorY + 0.5
	local fallTime = math.abs(position.Y - fallTargetY) / 10 -- Speed: 10 units per sec
	
	local tween = TweenService:Create(drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart"), 
		TweenInfo.new(fallTime, Enum.EasingStyle.Linear), 
		{Position = Vector3.new(position.X, fallTargetY, position.Z)}
	)
	
	tween:Play()
	tween.Completed:Connect(function()
		task.wait(3)
		TweenService:Create(drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart"), 
			TweenInfo.new(0.5), 
			{Transparency = 1}
		):Play()
		task.delay(0.5, function() drop:Destroy() end)
	end)
end

--------------------------------------------------
-- FOOD DROP LOGIC
--------------------------------------------------
local activeFoodModel: Model? = nil
local dropModeActive = false
local currentFoodId: string? = nil

-- local AQUARIUM_SIZE = Vector3.new(60, 35, 8) -- Moved up

local dropConnections = {}

function PlotController:StartFoodDropMode(foodId: string)
	if dropModeActive then self:StopFoodDropMode() end
	
	currentFoodId = foodId
	dropModeActive = true
	
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
		
		-- Apply mDropRotate and mDropScale for preview
		local dropRotate = itemData and itemData.mDropRotate or "0,0,0"
		local dropScale = itemData and itemData.mDropScale or 1
		local rotationCFrame = parseRotation(dropRotate)
		
		-- Set initial position immediately
		local targetPos = getMousePlanePos(mouse)
		if targetPos then
			activeFoodModel:PivotTo(CFrame.new(targetPos) * rotationCFrame)
		end
		
		activeFoodModel.Parent = workspace:FindFirstChild("UnderwaterWorld") or workspace
		log("Preview model parented to UnderwaterWorld at pivot:", activeFoodModel:GetPivot())
		
		if dropScale ~= 1 then
			if activeFoodModel.PrimaryPart then
				activeFoodModel:ScaleTo(dropScale)
			else
				for _, part in ipairs(activeFoodModel:GetDescendants()) do
					if part:IsA("BasePart") then part.Size *= dropScale end
				end
			end
		end

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
				
				log("Firing RequestDropFood for:", currentFoodId, "at", targetPos)
				Remote:FireServer("RequestDropFood", currentFoodId, targetPos)
				
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
function PlotController:Init()
	-- Handle food drops from server
	Remote:On("FoodDropped", function(player: Player, foodId: string, position: Vector3)
		log("Food dropped by", player.Name, ":", foodId)
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
	setControlsEnabled(false)
	MainHUD.SetHUDVisible(false)
	isInteracting = true

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
		UNDERWATER_POS + Vector3.new(0, -5, 17), -- Zoom 17 (+1 dari 18) & Turun -5 (+1 dari -4)
		UNDERWATER_POS + Vector3.new(0, -5, 0)
	)

	local uwGui
	uwGui = createUnderwaterGui(function()
		log("Underwater onClose")
		self:StartExitSequence(plotModel, loadingSg, uwGui)
	end)

	task.wait(0.5)
	TweenService:Create(loadingFrame, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
	TweenService:Create(loadingText, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
end

--------------------------------------------------
-- EXIT SEQUENCE
--------------------------------------------------
function PlotController:StartExitSequence(plotModel: Model, loadingSg: ScreenGui, uwGui: ScreenGui)
	log("StartExitSequence")

	local frame = loadingSg.Frame
	local text = frame.TextLabel

	TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
	TweenService:Create(text, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	task.wait(0.6)

	if uwGui then
		uwGui:Destroy()
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
