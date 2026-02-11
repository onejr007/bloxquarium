--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Remote = require(ReplicatedStorage.Shared.RemoteClient)
local ClientState = require(ReplicatedStorage.Shared.ClientState)
local Assets = require(ReplicatedStorage.Shared.AssetManagerV3)
local MainHUD = require(script.Parent:WaitForChild("MainHUDController"))
local ViewportManager = require(ReplicatedStorage.Shared:WaitForChild("ViewportManager"))

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local PlotController = {}
local UNDERWATER_POS = Vector3.new(5000, -100, 5000)
local isInteracting = false

-- ASSETS
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
	log("Controls enabled:", enabled)
end

-- LOADING SCREEN
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

-- UNDERWATER GUI
local function createUnderwaterGui(onClose: () -> ())
	if not Assets.IsReady() then
		log("Assets not ready, UI aborted")
		return
	end
	if not FRAME_ICO then loadAssets() end

	log("Creating Underwater GUI")

	local sg = Instance.new("ScreenGui")
	sg.Name, sg.ResetOnSpawn = "UnderwaterGui", false

	local menuContainer = Instance.new("Frame", sg)
	menuContainer.Size = UDim2.fromOffset(100, 500)
	menuContainer.Position = UDim2.new(1, -20, 1, -20)
	menuContainer.AnchorPoint, menuContainer.BackgroundTransparency = Vector2.new(1,1), 1

	-- MAIN MENU FRAME
	local menuFrame = Instance.new("CanvasGroup", menuContainer)
	menuFrame.Name = "menu_frame"
	menuFrame.Size = UDim2.fromOffset(580, 220)
	menuFrame.Position = UDim2.new(0, -40, 1, -140)
	menuFrame.AnchorPoint = Vector2.new(1,1)
	menuFrame.BackgroundColor3 = THEME.PRIMARY
	menuFrame.GroupTransparency, menuFrame.Visible = 1, false

	Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 24)
	local grad = Instance.new("UIGradient", menuFrame)
	grad.Color, grad.Rotation = ColorSequence.new(THEME.GRADIENT_TOP, THEME.SECONDARY), 90

	local shadow = Instance.new("ImageLabel", menuFrame)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageTransparency = 0.85
	shadow.Size = UDim2.new(1, 40, 1, 40)
	shadow.Position = UDim2.new(0, -20, 0, -20)
	shadow.ZIndex = 0

	-- INVENTORY SCROLL
	local invScroll = Instance.new("ScrollingFrame", menuFrame)
	invScroll.Size = UDim2.new(1, -30, 1, -30)
	invScroll.Position = UDim2.fromOffset(15, 15)
	invScroll.BackgroundTransparency = 1
	invScroll.ScrollBarThickness = 3
	invScroll.ScrollBarImageColor3 = THEME.ACCENT
	invScroll.CanvasSize = UDim2.fromScale(0,0)
	invScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	invScroll.ScrollingDirection = Enum.ScrollingDirection.X
	invScroll.ZIndex = 2

	local invLayout = Instance.new("UIListLayout", invScroll)
	invLayout.Padding = UDim.new(0, 16)
	invLayout.FillDirection = Enum.FillDirection.Horizontal
	invLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	-- EMPTY INVENTORY LABEL
	local emptyLabel = Instance.new("TextLabel", menuFrame)
	emptyLabel.Size = UDim2.fromScale(1,1)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.TextWrapped = true
	emptyLabel.TextYAlignment = Enum.TextYAlignment.Center
	emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
	emptyLabel.Font = Enum.Font.GothamMedium
	emptyLabel.TextSize = 16
	emptyLabel.TextColor3 = THEME.EMPTY_TEXT
	emptyLabel.TextTransparency = 1
	emptyLabel.Text = "INVENTORY KOSONG"
	emptyLabel.Visible = false
	emptyLabel.ZIndex = 3

	-- ICON BUTTON FACTORY
	local function createIconButton(icon: string, pos: UDim2, size: number, name: string, color: Color3?)
		local btn = Instance.new("ImageButton")
		btn.Name, btn.Size, btn.Position = name or "IconButton", UDim2.fromOffset(size,size), pos
		btn.AnchorPoint, btn.BackgroundTransparency = Vector2.new(0.5,0.5), 1
		btn.Image, btn.ImageColor3 = FRAME_ICO, color or THEME.PRIMARY

		local ico = Instance.new("ImageLabel", btn)
		ico.Size, ico.Position = UDim2.fromScale(0.55,0.55), UDim2.fromScale(0.5,0.5)
		ico.AnchorPoint, ico.BackgroundTransparency, ico.Image = Vector2.new(0.5,0.5), 1, icon

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Back), {
				Size = UDim2.fromOffset(size+10, size+10),
				ImageColor3 = THEME.GRADIENT_TOP,
			}):Play()
		end)

		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Back), {
				Size = UDim2.fromOffset(size, size),
				ImageColor3 = color or THEME.PRIMARY,
			}):Play()
		end)

		return btn
	end

	local toggleBtn = createIconButton(MENU_ICO, UDim2.new(0.5,0,1,-40), 78, "Toggle", THEME.ACCENT)
	toggleBtn.Parent = menuContainer

	local fishBtn = createIconButton(FISH_ICO, UDim2.new(0.5,0,1,-40), 66, "Fish")
	local eggBtn = createIconButton(EGG_ICO, UDim2.new(0.5,0,1,-40), 66, "Egg")
	local foodBtn = createIconButton(FOOD_ICO, UDim2.new(0.5,0,1,-40), 66, "Food")
	local closeBtn = createIconButton(CLOSE_ICO, UDim2.new(0.5,0,1,-40), 66, "Close")

	fishBtn.Visible, eggBtn.Visible, foodBtn.Visible, closeBtn.Visible = false, false, false, false
	fishBtn.Parent, eggBtn.Parent, foodBtn.Parent, closeBtn.Parent = menuContainer, menuContainer, menuContainer, menuContainer

	-- COIN DISPLAY
	local coinFrame = Instance.new("Frame", sg)
	coinFrame.Size = UDim2.fromOffset(220, 58)
	coinFrame.Position = UDim2.new(0, 26, 1, -26)
	coinFrame.AnchorPoint = Vector2.new(0,1)
	coinFrame.BackgroundColor3 = THEME.PRIMARY

	Instance.new("UICorner", coinFrame).CornerRadius = UDim.new(1,0)
	local coinStroke = Instance.new("UIStroke", coinFrame)
	coinStroke.Color, coinStroke.Thickness = THEME.GOLD, 3

	local coinIcon = Instance.new("ImageLabel", coinFrame)
	coinIcon.Size, coinIcon.Position = UDim2.fromOffset(40,40), UDim2.new(0,10,0.5,0)
	coinIcon.AnchorPoint, coinIcon.BackgroundTransparency, coinIcon.Image = Vector2.new(0,0.5), 1, COIN_ICO

	local coinLabel = Instance.new("TextLabel", coinFrame)
	coinLabel.Size = UDim2.new(1,-65,1,0)
	coinLabel.Position = UDim2.new(0,55,0,0)
	coinLabel.BackgroundTransparency = 1
	coinLabel.Font = Enum.Font.GothamBlack
	coinLabel.TextSize = 24
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.TextColor3 = THEME.TEXT
	coinLabel.Text = "0"

	-- INVENTORY LOGIC
	local function clearInventory()
		for _, child in ipairs(invScroll:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end
		end
		log("Inventory cleared")
	end

	local function showEmpty(text: string)
		emptyLabel.Text = text
		emptyLabel.Visible = true
		TweenService:Create(emptyLabel, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
		log("Empty inventory shown:", text)
	end

	local function hideEmpty()
		if not emptyLabel.Visible then return end
		TweenService:Create(emptyLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		task.delay(0.2, function()
			emptyLabel.Visible = false
			log("Empty inventory hidden")
		end)
	end

	local function populateInventory(category: string)
		log("Populate inventory:", category)
		clearInventory()
		hideEmpty()

		local state = ClientState:GetState()
		if not state or not state.Inventory then
			showEmpty("INVENTORY BELUM TERSEDIA")
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

			local item = Instance.new("Frame", invScroll)
			item.Size = UDim2.fromOffset(114,114)
			item.BackgroundColor3 = THEME.SECONDARY
			Instance.new("UICorner", item).CornerRadius = UDim.new(0,18)

			local stroke = Instance.new("UIStroke", item)
			stroke.Color = THEME.GRADIENT_TOP

			local vpf = Instance.new("Frame", item)
			vpf.Size = UDim2.fromScale(0.86,0.86)
			vpf.Position = UDim2.fromScale(0.5,0.45)
			vpf.AnchorPoint, vpf.BackgroundTransparency = Vector2.new(0.5,0.5), 1

			local itemData = Assets.GetItemData(id)
			local modelName = itemData and (itemData.mInfoName or itemData.mDropName or itemData.name) or "Placeholder"
			ViewportManager:CreateModelViewport(
				vpf,
				modelName,
				itemData and itemData.mInfoRotate or 0,
				itemData and tonumber(itemData.mInfoScale) or 1.2
			)

			local nameLbl = Instance.new("TextLabel", item)
			nameLbl.Size = UDim2.new(1,0,0,24)
			nameLbl.Position = UDim2.new(0,0,1,-22)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 10
			nameLbl.TextColor3 = THEME.TEXT
			nameLbl.Text = (itemData and itemData.name or id):upper()

			local bubble = Instance.new("Frame", item)
			bubble.Size = UDim2.fromOffset(30,30)
			bubble.Position = UDim2.new(1,-3,0,3)
			bubble.AnchorPoint = Vector2.new(1,0)
			bubble.BackgroundColor3 = THEME.ACCENT
			Instance.new("UICorner", bubble).CornerRadius = UDim.new(1,0)

			local countLbl = Instance.new("TextLabel", bubble)
			countLbl.Size = UDim2.fromScale(1,1)
			countLbl.BackgroundTransparency = 1
			countLbl.Font = Enum.Font.GothamBlack
			countLbl.TextSize = 12
			countLbl.TextColor3 = THEME.PRIMARY
			countLbl.Text = "x"..tostring(count)
		end

		if not hasItem then showEmpty("INVENTORY KOSONG") end
	end

	-- MENU STATE
	local isOpen = false
	local currentMenu: string? = nil
	local destroyed = false

	local function forceCloseInventory()
		if destroyed then return end
		log("Force closing inventory & cleanup")
		currentMenu = nil
		hideEmpty()
		menuFrame.Visible = false
		menuFrame.GroupTransparency = 1
		clearInventory()
	end

	local function closeInventoryFrame()
		if destroyed then return end
		log("Closing inventory frame")
		currentMenu = nil
		hideEmpty()
		TweenService:Create(menuFrame, TweenInfo.new(0.22), {
			GroupTransparency = 1,
			Position = UDim2.new(0,-10,1,-140),
		}):Play()
		task.delay(0.22, function()
			if destroyed then return end
			menuFrame.Visible = false
			clearInventory()
			log("Inventory frame fully closed")
		end)
	end

	local function openInventoryFrame(category: string)
		if destroyed then return end
		log("Opening inventory frame:", category)
		currentMenu = category
		populateInventory(category)
		menuFrame.Visible = true
		TweenService:Create(menuFrame, TweenInfo.new(0.32, Enum.EasingStyle.Back), {
			GroupTransparency = 0,
			Position = UDim2.new(0,-40,1,-140),
		}):Play()
	end

	local function toggleSubMenu(category: string)
		if destroyed then return end
		log("Toggle submenu:", category)
		if currentMenu == category then
			closeInventoryFrame()
		else
			openInventoryFrame(category)
		end
	end

	toggleBtn.MouseButton1Click:Connect(function()
		if destroyed then return end
		isOpen = not isOpen
		log("Toggle main menu:", isOpen)

		if not isOpen then forceCloseInventory() end

		local targets = {
			{btn = fishBtn, pos = -135},
			{btn = eggBtn, pos = -220},
			{btn = foodBtn, pos = -305},
			{btn = closeBtn, pos = -390},
		}

		for i, data in ipairs(targets) do
			if isOpen then
				data.btn.Visible = true
				TweenService:Create(data.btn, TweenInfo.new(0.26 + (i*0.04), Enum.EasingStyle.Back), {
					Position = UDim2.new(0.5,0,1,data.pos),
				}):Play()
			else
				TweenService:Create(data.btn, TweenInfo.new(0.22), {
					Position = UDim2.new(0.5,0,1,-40),
				}):Play()
				task.delay(0.22, function()
					if not isOpen and not destroyed then
						data.btn.Visible = false
						log("Button hidden:", data.btn.Name)
					end
				end)
			end
		end
	end)

	fishBtn.MouseButton1Click:Connect(function() toggleSubMenu("Fish") end)
	eggBtn.MouseButton1Click:Connect(function() toggleSubMenu("Egg") end)
	foodBtn.MouseButton1Click:Connect(function() toggleSubMenu("Food") end)
	closeBtn.MouseButton1Click:Connect(function()
		if destroyed then return end
		log("Close button clicked")
		destroyed = true
		forceCloseInventory()
		sg:Destroy()
		onClose()
	end)

	-- COIN SYNC
	local function refreshCoins()
		local state = ClientState:GetState()
		if state and state.Coins then
			coinLabel.Text = tostring(state.Coins)
			log("Coins updated:", state.Coins)
		end
	end
	refreshCoins()
	ClientState:OnChange(refreshCoins)

	sg.Parent = Player.PlayerGui
	log("Underwater GUI mounted")
	return sg
end

-- INITIALIZATION & FIXES
function PlotController:Init()
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
		log("RequestEnterAquariumClient received")
		Remote:FireServer("RequestEnterAquarium", plotModel)
	end)

	Remote:On("EnterAquariumSequence", function(owner: Player, plotModel: Model)
		log("EnterAquariumSequence received")
		self:StartEnterSequence(owner, plotModel)
	end)
end

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
		UNDERWATER_POS + Vector3.new(0,12,12),
		UNDERWATER_POS + Vector3.new(0,10,0)
	)

	local uwGui = createUnderwaterGui(function()
		log("Underwater GUI onClose triggered")
		self:StartExitSequence(plotModel, loadingSg, uwGui)
	end)

	task.wait(0.5)
	TweenService:Create(loadingFrame, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
	TweenService:Create(loadingText, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
end

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

PlotController:Init()
log("PlotController initialized")
return PlotController
