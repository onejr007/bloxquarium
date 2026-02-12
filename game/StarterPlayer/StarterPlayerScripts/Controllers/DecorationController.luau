--!strict
local DecorationController = {}
local screenGui: ScreenGui?
local mainFrame: Frame?

-- [SERVICES]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- [CONSTANTS]
local PLAYER = Players.LocalPlayer
local PLAYER_GUI = PLAYER:WaitForChild("PlayerGui")
local SHARED = ReplicatedStorage:WaitForChild("Shared")
local ASSET_MANAGER = require(SHARED:WaitForChild("AssetManagerV3"))
local REMOTE_CLIENT = require(SHARED:WaitForChild("RemoteClient"))
local ViewportManager = require(SHARED:WaitForChild("ViewportManager"))
local ASSET_CONFIG = require(SHARED:WaitForChild("asset_config"))

local THEME = {
	PRIMARY = Color3.fromRGB(15, 20, 35),
	SECONDARY = Color3.fromRGB(26, 36, 58),
	ACCENT = Color3.fromRGB(0, 210, 255),
	TEXT = Color3.fromRGB(240, 245, 255),
	GOLD = Color3.fromRGB(255, 200, 50),
	SUCCESS = Color3.fromRGB(90, 220, 150),
	DANGER = Color3.fromRGB(255, 90, 90),
	WHITE = Color3.fromRGB(255, 255, 255),
	GRAY = Color3.fromRGB(180, 180, 180),
}

local UNDERWATER_POS = Vector3.new(5000, -82.5, 5000)
local AQUARIUM_SIZE = Vector3.new(60, 35, 8)

-- [STATE]
local isPlacementMode = false
local isWaitingConfirmation = false 
local isDeleteMode = false
local isMoveSelectionMode = false
local currentPreviewModel: Model? = nil
local currentItemId: string? = nil
local placementConnection: RBXScriptConnection? = nil
local mouseConnection: RBXScriptConnection? = nil
local moveModeDecorId: string? = nil
local originalCFrame: CFrame? = nil
local currentRotation = 0
local lastHighlighted: Model? = nil
local originalColors: {[BasePart]: Color3} = {}
local activeSelectionGuis: {BillboardGui} = {}
local selectionCancelGui: ScreenGui? = nil

local function cleanupSelectionMode()
	isDeleteMode = false
	isMoveSelectionMode = false
	for _, gui in ipairs(activeSelectionGuis) do
		if gui then 
			gui.Enabled = false -- Sembunyikan instan untuk cegah blinking
			gui:Destroy() 
		end
	end
	table.clear(activeSelectionGuis)
	
	if selectionCancelGui then
		selectionCancelGui:Destroy()
		selectionCancelGui = nil
	end
	
	-- Cleanup highlights from models
	local world = workspace:FindFirstChild("UnderwaterWorld")
	local decorFolder = world and world:FindFirstChild("Decorations")
	if decorFolder then
		for _, model in ipairs(decorFolder:GetChildren()) do
			local h = model:FindFirstChild("SelectionHighlight")
			if h then h:Destroy() end
		end
	end

	print("🧹 [DecorationController] Selection mode cleaned up")
end

local function toggleMainGUI(visible: boolean)
	local PlotController = require(script.Parent:WaitForChild("PlotController"))
	if (PlotController :: any).ToggleUI then
		(PlotController :: any):ToggleUI(visible)
	end
	
	-- Hide/Show other GUIs more aggressively
	local guisToToggle = {"MainHUD", "UnderwaterGui", "CoinFrame", "MenuButtons", "ActionButtons", "PlayerStats", "DecorationUI", "GachaUI", "ShopUI"}
	for _, name in ipairs(guisToToggle) do
		local gui = PLAYER_GUI:FindFirstChild(name)
		if gui then
			if gui:IsA("ScreenGui") then
				gui.Enabled = visible
			elseif gui:IsA("GuiObject") then
				gui.Visible = visible
			end
		end
	end
	
	-- Special case for MainHUDController if it exists
	local MainHUDController = require(script.Parent:WaitForChild("MainHUDController"))
	if MainHUDController and (MainHUDController :: any).SetHUDVisible then
		(MainHUDController :: any).SetHUDVisible(visible)
	end
end

-- [UI UTILS]
local function applyDecor(inst: GuiObject, radius: number, strokeColor: Color3?)
	local c = inst:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = inst
	if strokeColor then
		local s = inst:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
		s.Color, s.Thickness, s.ApplyStrokeMode = strokeColor, 1.5, Enum.ApplyStrokeMode.Border
		s.Parent = inst
	end
end

function DecorationController:Init()
	print("🌿 [DecorationController] Initialized")
end

function DecorationController:OpenUI()
	if screenGui then screenGui:Destroy() end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DecorationUI"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PLAYER_GUI

	mainFrame = Instance.new("Frame", screenGui)
	mainFrame.Name = "DecorationPanel"
	mainFrame.Size = UDim2.fromOffset(450, 140) -- Pipih (Flat)
	mainFrame.Position = UDim2.fromScale(0.5, 1.2) -- Start from below
	mainFrame.AnchorPoint = Vector2.new(0.5, 1)
	mainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
	mainFrame.BackgroundTransparency = 0.2
	
	local corner = Instance.new("UICorner", mainFrame)
	corner.CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", mainFrame)
	stroke.Color = THEME.ACCENT
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	-- Glass Blur effect
	local blur = Instance.new("ImageLabel", mainFrame)
	blur.Name = "GlassBlur"
	blur.Size = UDim2.fromScale(1, 1)
	blur.BackgroundTransparency = 1
	blur.Image = "rbxassetid://1316045217"
	blur.ImageColor3 = THEME.ACCENT
	blur.ImageTransparency = 0.85
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(10, 10, 10, 10)
	blur.ZIndex = 0

	local header = Instance.new("Frame", mainFrame)
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.ZIndex = 5
	
	local title = Instance.new("TextLabel", header)
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.fromOffset(12, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = "DECORATION INVENTORY"
	title.TextColor3 = THEME.WHITE
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 6

	local function createHeaderBtn(icon: string, color: Color3, xOffset: number)
		local b = Instance.new("ImageButton", header)
		b.Size = UDim2.fromOffset(24, 24)
		b.Position = UDim2.new(1, xOffset, 0.5, 0)
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.BackgroundColor3 = THEME.SECONDARY
		b.BackgroundTransparency = 0.2
		b.Image = icon
		b.ImageColor3 = THEME.WHITE
		b.ZIndex = 6
		applyDecor(b, 6, color)
		return b
	end

	local closeBtn = createHeaderBtn(ASSET_CONFIG.Images.Close_ico, THEME.WHITE, -12)
	local deleteBtn = createHeaderBtn(ASSET_CONFIG.Images.Del_ico, THEME.DANGER, -40)
	local moveBtn = createHeaderBtn(ASSET_CONFIG.Images.Move_ico, THEME.GOLD, -68)
	
	closeBtn.MouseButton1Click:Connect(function()
		self:CloseUI()
	end)

	local function clearHighlight()
		if lastHighlighted then
			for part, color in pairs(originalColors) do
				if part.Parent then
					part.Color = color
					part.Transparency = 0
				end
			end
			table.clear(originalColors)
			lastHighlighted = nil
		end
	end

	local function startSelectionMode(mode: "Delete" | "Move")
		local world = workspace:WaitForChild("UnderwaterWorld", 5)
		local decorFolder = world and world:WaitForChild("Decorations", 5)
		
		print("🔍 [DecorationController] Checking for items in:", decorFolder and decorFolder:GetFullName() or "NOT FOUND")
		
		-- 1. Validate if there are decorations to delete/move
		local itemsFound = 0
		if decorFolder then
			for _, model in ipairs(decorFolder:GetChildren()) do
				local ownerId = model:GetAttribute("OwnerId")
				print(string.format("   > Checking model: %s, OwnerId: %s, PlayerId: %s", model.Name, tostring(ownerId), tostring(PLAYER.UserId)))
				if model:IsA("Model") and ownerId == PLAYER.UserId then
					itemsFound += 1
				end
			end
		end

		if itemsFound == 0 then
			warn("⚠️ No decorations placed to " .. mode:lower())
			
			-- Notification UI
			local notify = Instance.new("ScreenGui", PLAYER_GUI)
			notify.Name = "NoDecorNotification"
			local frame = Instance.new("Frame", notify)
			frame.Size = UDim2.fromOffset(300, 40)
			frame.Position = UDim2.fromScale(0.5, 0.5)
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.BackgroundColor3 = THEME.DANGER
			frame.BackgroundTransparency = 0.2
			applyDecor(frame, 8)
			
			local txt = Instance.new("TextLabel", frame)
			txt.Size = UDim2.new(1, 0, 1, 0)
			txt.BackgroundTransparency = 1
			txt.Font = Enum.Font.GothamBold
			txt.Text = "TIDAK ADA ITEM DECOR YANG DITEMPATKAN"
			txt.TextColor3 = THEME.WHITE
			txt.TextSize = 12
			
			task.delay(2, function() if notify then notify:Destroy() end end)
			return
		end

		cleanupSelectionMode() -- Clear any existing ones first
		
		-- Capture the mode into local variables immediately
		local targetIsDelete = (mode == "Delete")
		local targetIsMove = (mode == "Move")
		
		isDeleteMode = targetIsDelete
		isMoveSelectionMode = targetIsMove
		
		print("🎯 [DecorationController] startSelectionMode CALLED with:", mode)
		print("   > isDeleteMode set to:", isDeleteMode)
		print("   > isMoveSelectionMode set to:", isMoveSelectionMode)
		
		self:CloseUI()
		toggleMainGUI(false) -- Hide UI during selection mode
		
		-- 2. Create Cancel Button for Selection Mode
		selectionCancelGui = Instance.new("ScreenGui", PLAYER_GUI)
		selectionCancelGui.Name = "SelectionCancelUI"
		
		local cancelFrame = Instance.new("Frame", selectionCancelGui)
		cancelFrame.Size = UDim2.fromOffset(120, 40)
		cancelFrame.Position = UDim2.new(0.5, 0, 0.05, 0)
		cancelFrame.AnchorPoint = Vector2.new(0.5, 0)
		cancelFrame.BackgroundColor3 = THEME.PRIMARY
		cancelFrame.BackgroundTransparency = 0.3
		applyDecor(cancelFrame, 8, THEME.ACCENT)
		
		local cancelBtn = Instance.new("TextButton", cancelFrame)
		cancelBtn.Size = UDim2.new(1, -10, 1, -10)
		cancelBtn.Position = UDim2.fromScale(0.5, 0.5)
		cancelBtn.AnchorPoint = Vector2.new(0.5, 0.5)
		cancelBtn.BackgroundColor3 = THEME.DANGER
		cancelBtn.Text = "CANCEL " .. mode:upper()
		cancelBtn.TextColor3 = THEME.WHITE
		cancelBtn.Font = Enum.Font.GothamBlack
		cancelBtn.TextSize = 12
		applyDecor(cancelBtn, 6)
		
		cancelBtn.MouseButton1Click:Connect(function()
			cleanupSelectionMode()
			toggleMainGUI(true)
			self:OpenUI()
		end)

		itemsFound = 0
		for _, model in ipairs(decorFolder:GetChildren()) do
			if not model:IsA("Model") or model:GetAttribute("OwnerId") ~= PLAYER.UserId then continue end
			itemsFound += 1

			local bb = Instance.new("BillboardGui")
			bb.Name = "SelectionGui"
			bb.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
			bb.Size = UDim2.fromOffset(40, 40)
			bb.StudsOffset = Vector3.new(0, 2, 0)
			bb.AlwaysOnTop = true
			bb.Active = true -- PENTING: Agar bisa menerima input klik
			bb.Parent = PLAYER_GUI
			table.insert(activeSelectionGuis, bb)

			local btn = Instance.new("ImageButton", bb)
			btn.Name = "SelectionButton"
			btn.Size = UDim2.fromScale(1, 1)
			btn.BackgroundTransparency = 0.2
			btn.BackgroundColor3 = targetIsDelete and THEME.DANGER or THEME.GOLD
			btn.Active = true -- PENTING
			
			local icon = targetIsDelete and ASSET_CONFIG.Images.Del_ico or ASSET_CONFIG.Images.Move_ico
			if not icon then
				warn("⚠️ Icon missing for mode:", mode)
				icon = ""
			end
			btn.Image = icon
			
			applyDecor(btn, 8, THEME.WHITE)

			-- Add Hover Highlight for selection mode
			local selectionHighlight = Instance.new("Highlight")
			selectionHighlight.Name = "SelectionHighlight"
			selectionHighlight.FillColor = targetIsDelete and THEME.DANGER or THEME.GOLD
			selectionHighlight.OutlineColor = THEME.WHITE
			selectionHighlight.FillTransparency = 1 -- Hidden by default
			selectionHighlight.OutlineTransparency = 1
			selectionHighlight.Adornee = model
			selectionHighlight.Parent = model

			btn.MouseEnter:Connect(function()
				selectionHighlight.FillTransparency = 0.5
				selectionHighlight.OutlineTransparency = 0
			end)
			
			btn.MouseLeave:Connect(function()
				selectionHighlight.FillTransparency = 1
				selectionHighlight.OutlineTransparency = 1
			end)

			btn.MouseButton1Click:Connect(function()
				print("🖱️ World Button Clicked! Mode:", targetIsDelete and "Delete" or "Move", "Item:", model.Name)
				local itemId = model:GetAttribute("ItemId")
				local registry = ASSET_MANAGER.GetItemRegistry()
				local data = registry and registry.decoration and registry.decoration[itemId]
				local mName = model.Name

				-- FIX BLINKING: Clean up selection GUIs IMMEDIATELY before server call
				cleanupSelectionMode()

				if targetIsDelete then
					print("🗑️ Requesting removal of:", mName)
					REMOTE_CLIENT:InvokeServer("RequestRemoveDecoration", mName):andThen(function(success)
						if success then 
							print("✅ Decoration removed")
							toggleMainGUI(true) -- Kembalikan UI setelah berhasil hapus
							self:OpenUI() -- Buka kembali inventory
						end
					end)
				elseif targetIsMove then
					print("🚚 Requesting move of:", mName)
					moveModeDecorId = mName
					originalCFrame = model:GetPivot()
					
					REMOTE_CLIENT:InvokeServer("RequestRemoveDecoration", mName):andThen(function(success)
						if success then
							self:StartPlacement(itemId, data)
						end
					end)
				end
			end)
		end
		print("📦 BillboardGuis created for", itemsFound, "decorations")

		-- Cancel selection mode if clicking elsewhere
		local clickConn
		clickConn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				task.wait(0.1) -- Wait for button clicks
				if isDeleteMode or isMoveSelectionMode then
					local pos = input.Position
					local guis = PLAYER_GUI:GetGuiObjectsAtPosition(pos.X, pos.Y)
					local clickedSelection = false
					for _, g in ipairs(guis) do
						if g.Parent and g.Parent.Name == "SelectionGui" then clickedSelection = true break end
					end
					
					if not clickedSelection then
						cleanupSelectionMode()
						if clickConn then clickConn:Disconnect() end
						toggleMainGUI(true) -- Kembalikan UI jika batal
						self:OpenUI() -- Re-open inventory if cancelled
					end
				end
			end
		end)
	end

	deleteBtn.MouseButton1Click:Connect(function() startSelectionMode("Delete") end)
	moveBtn.MouseButton1Click:Connect(function() startSelectionMode("Move") end)

	local scroll = Instance.new("ScrollingFrame", mainFrame)
	scroll.Size = UDim2.new(1, -24, 1, -65)
	scroll.Position = UDim2.fromOffset(12, 55)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = THEME.ACCENT
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	scroll.ScrollingDirection = Enum.ScrollingDirection.X
	scroll.ZIndex = 5

	local layout = Instance.new("UIListLayout", scroll)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	-- [CATEGORY TABS]
	local tabContainer = Instance.new("Frame", mainFrame)
	tabContainer.Name = "Tabs"
	tabContainer.Size = UDim2.new(1, -24, 0, 20)
	tabContainer.Position = UDim2.fromOffset(12, 32)
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = 5

	local tabLayout = Instance.new("UIListLayout", tabContainer)
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 5)

	-- Get decorations from inventory
	local ClientState = require(SHARED:WaitForChild("ClientState"))
	local state = ClientState:GetState()
	local inventory = state.Inventory and state.Inventory.Decoration or {}
	local allItems = ASSET_MANAGER.GetItemRegistry()
	local decorationData = allItems and allItems.decoration or {}

	local currentCategory = "All"
	local categoryButtons = {}

	local function refreshList(filter: string)
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
		end

		local hasItems = false
		local itemsCount = 0
		
		-- Inventory Logic
		for id, count in pairs(inventory) do
			local data = decorationData[id]
			if not data or count <= 0 then continue end
			
			local itemCat = data.category or "Decoration"
			if filter ~= "All" and itemCat ~= filter then continue end

			hasItems = true
			itemsCount += 1
			
			local card = Instance.new("Frame", scroll)
			card.Name = id
			card.Size = UDim2.fromOffset(70, 75)
			card.BackgroundColor3 = THEME.SECONDARY
			card.BackgroundTransparency = 0.5
			card.ZIndex = 6
			applyDecor(card, 8, THEME.ACCENT)

			local vpfContainer = Instance.new("Frame", card)
			vpfContainer.Size = UDim2.new(1, -4, 0, 45)
			vpfContainer.Position = UDim2.fromOffset(2, 2)
			vpfContainer.BackgroundTransparency = 1
			vpfContainer.ZIndex = 7

			local nameLabel = Instance.new("TextLabel", card)
			nameLabel.Size = UDim2.new(1, -4, 0, 15)
			nameLabel.Position = UDim2.fromOffset(2, 47)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.Text = (data.mName or id):upper()
			nameLabel.TextColor3 = THEME.WHITE
			nameLabel.TextSize = 7
			nameLabel.TextWrapped = true
			nameLabel.ZIndex = 7

			local countLabel = Instance.new("TextLabel", card)
			countLabel.Size = UDim2.new(0, 20, 0, 15)
			countLabel.Position = UDim2.new(1, -2, 0, 2)
			countLabel.AnchorPoint = Vector2.new(1, 0)
			countLabel.BackgroundColor3 = THEME.ACCENT
			countLabel.Text = "x" .. count
			countLabel.TextColor3 = THEME.PRIMARY
			countLabel.Font = Enum.Font.GothamBlack
			countLabel.TextSize = 10
			countLabel.ZIndex = 8
			applyDecor(countLabel, 4)

			local useBtn = Instance.new("TextButton", card)
			useBtn.Size = UDim2.new(1, -4, 0, 15)
			useBtn.Position = UDim2.new(0, 2, 1, -2)
			useBtn.AnchorPoint = Vector2.new(0, 1)
			useBtn.BackgroundColor3 = THEME.SUCCESS
			useBtn.Text = "PLACE"
			useBtn.TextColor3 = THEME.PRIMARY
			useBtn.Font = Enum.Font.GothamBlack
			useBtn.TextSize = 10
			useBtn.ZIndex = 7
			applyDecor(useBtn, 4)

			ViewportManager:CreateModelViewport(
				vpfContainer, 
				data.mInfoName or data.mDropName, 
				data.mInfoRotate or data.mDropRotate or "0,0,0", 
				data.mInfoScale or 1.2
			)
			
			useBtn.MouseButton1Click:Connect(function()
				self:StartPlacement(id, data)
				self:CloseUI()
			end)
		end

		if not hasItems then
			local emptyLabel = Instance.new("TextLabel", scroll)
			emptyLabel.Size = UDim2.new(1, 0, 1, 0)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = "NO ITEMS IN " .. filter:upper()
			emptyLabel.TextColor3 = THEME.GRAY
			emptyLabel.Font = Enum.Font.GothamBold
			emptyLabel.TextSize = 12
			emptyLabel.ZIndex = 6
		else
			scroll.CanvasSize = UDim2.new(0, itemsCount * 80, 0, 0)
		end
	end

	local function createTab(name: string)
		local btn = Instance.new("TextButton", tabContainer)
		btn.Name = name .. "Tab"
		btn.Size = UDim2.fromOffset(60, 18)
		btn.BackgroundColor3 = THEME.SECONDARY
		btn.BackgroundTransparency = 0.5
		btn.Text = name:upper()
		btn.TextColor3 = THEME.GRAY
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 10
		btn.ZIndex = 6
		applyDecor(btn, 4, THEME.ACCENT)

		btn.MouseButton1Click:Connect(function()
			for _, b in pairs(categoryButtons) do
				b.BackgroundColor3 = THEME.SECONDARY
				b.TextColor3 = THEME.GRAY
			end
			btn.BackgroundColor3 = THEME.ACCENT
			btn.TextColor3 = THEME.PRIMARY
			refreshList(name)
		end)

		categoryButtons[name] = btn
		return btn
	end

	createTab("All")
	createTab("Coral")
	createTab("Flower")
	createTab("Tree")
	createTab("Decoration")

	-- Select All by default
	categoryButtons["All"].BackgroundColor3 = THEME.ACCENT
	categoryButtons["All"].TextColor3 = THEME.PRIMARY
	refreshList("All")

	-- Animate Open
	TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.98)
	}):Play()
end

function DecorationController:CloseUI()
	-- Cleanup selection modes if active
	cleanupSelectionMode()
	
	if mainFrame then
		local tween = TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Position = UDim2.fromScale(0.5, 1.2)
		})
		tween:Play()
		tween.Completed:Connect(function()
			if screenGui then
				screenGui:Destroy()
				screenGui = nil
				mainFrame = nil
			end
		end)
	end
end

function DecorationController:IsOpen(): boolean
	return screenGui ~= nil
end

function DecorationController:StartPlacement(id: string, data: any)
	if isPlacementMode then self:CancelPlacement() end
	cleanupSelectionMode() -- Ensure no leftover buttons from selection mode
	
	-- 1. Check Max Decoration
	local ClientState = require(SHARED:WaitForChild("ClientState"))
	local state = ClientState:GetState()
	local aqLevel = state.AquariumLevel or 1
	
	-- Count current decorations in world (ONLY OWNED BY PLAYER)
	local currentDecorCount = 0
	local world = workspace:FindFirstChild("UnderwaterWorld")
	if world then
		local decorFolder = world:FindFirstChild("Decorations")
		if decorFolder then
			for _, decor in ipairs(decorFolder:GetChildren()) do
				if decor:GetAttribute("OwnerId") == PLAYER.UserId then
					currentDecorCount += 1
				end
			end
		end
	end

	-- Get maxDecoration from aquarium levels
	local maxDecor = 10
	local aquariumConfigs = {
		[1] = {maxDecoration = 3},
		[2] = {maxDecoration = 5},
		[3] = {maxDecoration = 10},
	}
	if aquariumConfigs[aqLevel] then
		maxDecor = aquariumConfigs[aqLevel].maxDecoration
	end

	print(string.format("📊 Decor Count: %d/%d (Level %d)", currentDecorCount, maxDecor, aqLevel))

	if currentDecorCount >= maxDecor and not moveModeDecorId then
		warn("⚠️ Maximum decorations reached!")
		-- Simple screen notification
		local notify = Instance.new("ScreenGui", PLAYER_GUI)
		local frame = Instance.new("Frame", notify)
		frame.Size = UDim2.fromOffset(250, 40)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.BackgroundColor3 = THEME.DANGER
		applyDecor(frame, 8)
		
		local txt = Instance.new("TextLabel", frame)
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.Font = Enum.Font.GothamBold
		txt.Text = "MAX DECORATIONS REACHED!"
		txt.TextColor3 = THEME.WHITE
		txt.TextSize = 12
		
		task.delay(2, function() notify:Destroy() end)
		return
	end

	-- 2. Setup Mode
	isPlacementMode = true
	isWaitingConfirmation = false
	currentItemId = id
	currentRotation = 0 -- Reset rotation
	toggleMainGUI(false) -- Hide all UI
	if self:IsOpen() then self:CloseUI() end

	-- 3. Create Preview Model
	local modelName = data.mDropName
	local dropScale = data.mDropScale or 1
	local dropRotateStr = data.mDropRotate or "0,0,0"
	
	-- Parse rotation string "x,y,z"
	local rx, ry, rz = 0, 0, 0
	local parts = dropRotateStr:split(",")
	if #parts == 3 then
		rx, ry, rz = tonumber(parts[1]) or 0, tonumber(parts[2]) or 0, tonumber(parts[3]) or 0
	end
	local baseRotation = CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))

	local model = ViewportManager:GetModel(modelName)
	if not model then
		warn("Model not found:", modelName)
		isPlacementMode = false
		toggleMainGUI(true)
		return
	end

	currentPreviewModel = model:Clone()
	currentPreviewModel.Parent = workspace:FindFirstChild("UnderwaterWorld") or workspace
	
	-- Add Highlight for better visual feedback
	local highlight = Instance.new("Highlight")
	highlight.Name = "PlacementHighlight"
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Parent = currentPreviewModel

	if currentPreviewModel then
		if dropScale ~= 1 then currentPreviewModel:ScaleTo(dropScale) end
		for _, part in ipairs(currentPreviewModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.CanQuery = false
				part.Anchored = true
				-- We still keep transparency for the parts themselves
				part.Transparency = 0.5
			end
		end
	end

	-- 4. Create Placement HUD
	local placementHUD = Instance.new("ScreenGui", PLAYER_GUI)
	placementHUD.Name = "PlacementHUD"

	local controls = Instance.new("Frame", placementHUD)
	controls.Name = "PlacementControls"
	controls.Size = UDim2.fromOffset(300, 45) -- Increased width for more buttons
	controls.Position = UDim2.new(0.5, 0, 0.05, 0)
	controls.AnchorPoint = Vector2.new(0.5, 0)
	controls.BackgroundColor3 = THEME.PRIMARY
	controls.BackgroundTransparency = 0.3
	applyDecor(controls, 8, THEME.ACCENT)

	local btnContainer = Instance.new("Frame", controls)
	btnContainer.Size = UDim2.new(1, -10, 1, -10)
	btnContainer.Position = UDim2.fromOffset(5, 5)
	btnContainer.BackgroundTransparency = 1

	local uiLayout = Instance.new("UIListLayout", btnContainer)
	uiLayout.FillDirection = Enum.FillDirection.Horizontal
	uiLayout.Padding = UDim.new(0, 5)
	uiLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local function createBtn(icon: string?, color: Color3)
		local b = Instance.new("ImageButton", btnContainer)
		b.Name = "ControlBtn"
		b.Size = UDim2.fromOffset(35, 35)
		b.BackgroundColor3 = THEME.SECONDARY
		b.BackgroundTransparency = 0.2
		b.Image = icon or ""
		if not icon then
			warn("⚠️ Control button icon is nil!")
		end
		b.ImageColor3 = THEME.WHITE
		applyDecor(b, 8, color) -- Use the color for the stroke instead of background
		
		-- Hover effect
		b.MouseEnter:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
		end)
		b.MouseLeave:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
		end)
		
		return b
	end

	local cancelBtn = createBtn(ASSET_CONFIG.Images.Close_ico, THEME.DANGER)
	local rotateBtn = createBtn(ASSET_CONFIG.Images.Rotate_ico, THEME.WHITE)
	local confirmBtn = createBtn(ASSET_CONFIG.Images.Confirm_ico, THEME.SUCCESS)
	
	rotateBtn.Visible = false
	confirmBtn.Visible = false
	
	local category = data.category or "Decoration"

	cancelBtn.MouseButton1Click:Connect(function()
		self:CancelPlacement()
		placementHUD:Destroy()
	end)

	confirmBtn.MouseButton1Click:Connect(function()
		if currentPreviewModel then
			local isValid = currentPreviewModel:GetAttribute("IsValidPlacement")
			if isValid ~= false then
				print("✅ Confirming placement for", currentItemId)
				self:ConfirmPlacement()
				placementHUD:Destroy()
			else
				print("⚠️ Cannot confirm: IsValidPlacement is false")
			end
		else
			print("⚠️ Cannot confirm: No currentPreviewModel")
		end
	end)

	rotateBtn.MouseButton1Click:Connect(function()
		currentRotation = (currentRotation + 90) % 360
		print("🔄 Rotating to:", currentRotation)
		
		if currentPreviewModel then
			local cf, size = currentPreviewModel:GetBoundingBox()
			local rotationCF = CFrame.Angles(0, math.rad(currentRotation), 0)
			
			-- Recalculate position to keep it on floor
			local pivotPos = currentPreviewModel:GetPivot().p
			local floorY = UNDERWATER_POS.Y - (AQUARIUM_SIZE.Y / 2)
			local bottomY = cf.p.Y - (size.Y/2)
			local pivotOffset = pivotPos.Y - bottomY
			
			-- Use current position but update rotation
			local currentPos = currentPreviewModel:GetPivot().p
			local targetCF = CFrame.new(currentPos.X, floorY + pivotOffset, currentPos.Z) * baseRotation * rotationCF
			
			currentPreviewModel:PivotTo(targetCF)
		end
	end)

	-- Placement loop
	mouseConnection = RunService.RenderStepped:Connect(function()
		if not isPlacementMode or not currentPreviewModel or isWaitingConfirmation then return end
		
		local mouseLocation = UserInputService:GetMouseLocation()
		local viewportRay = workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
		
		-- Hitung interseksi Ray dengan plane Z (dinding belakang)
		local targetZ_Value = UNDERWATER_POS.Z - 3.5
		local t = (targetZ_Value - viewportRay.Origin.Z) / viewportRay.Direction.Z
		local worldPos = viewportRay.Origin + viewportRay.Direction * t
		
		-- Floor (Gravel) Y Position
		local floorY = UNDERWATER_POS.Y - (AQUARIUM_SIZE.Y / 2)
		
		-- Aquarium bounds
		local halfX = AQUARIUM_SIZE.X / 2
		local halfZ = AQUARIUM_SIZE.Z / 2
		local minX = UNDERWATER_POS.X - halfX + 1
		local maxX = UNDERWATER_POS.X + halfX - 1
		
		-- Check if category requires 2D grid placement
		local is2D = (category == "Coral" or category == "Flower" or category == "Tree")
		
		local targetX = math.clamp(worldPos.X, minX, maxX)
		local targetZ = targetZ_Value
		
		if not is2D then
			local mouse = PLAYER:GetMouse()
			targetZ = math.clamp(mouse.Hit.Position.Z, UNDERWATER_POS.Z - halfZ + 1, UNDERWATER_POS.Z + halfZ - 1)
		end

		-- 1. OVERLAP CHECK
		local isValid = true
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = {currentPreviewModel, workspace:FindFirstChild("PlacementGrid")}
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local cf, size = currentPreviewModel:GetBoundingBox()
		local rotationCF = CFrame.Angles(0, math.rad(currentRotation), 0)
		
		-- FIX: Normalisasi Y agar tidak melayang (bottom of model bounding box = floorY)
		-- Hitung offset dari pivot ke bagian bawah bounding box
		local pivotPos = currentPreviewModel:GetPivot().p
		local bottomY = cf.p.Y - (size.Y/2)
		local pivotOffset = pivotPos.Y - bottomY
		
		local targetCF = CFrame.new(targetX, floorY + pivotOffset, targetZ) * baseRotation * rotationCF
		
		local hits = workspace:GetPartBoundsInBox(targetCF, size * 0.8, overlapParams)
		for _, hit in ipairs(hits) do
			local hitModel = hit:FindFirstAncestorOfClass("Model")
			if hitModel and hitModel:GetAttribute("ItemId") and hitModel ~= currentPreviewModel then
				isValid = false
				print("❌ Overlap with decoration:", hitModel.Name)
				break
			end
		end

		-- 2. FLOOR CHECK
		if is2D then
			local mouse = PLAYER:GetMouse()
			if mouse and mouse.Hit then
				local distY = math.abs(mouse.Hit.Position.Y - floorY)
				if distY > 20 then
					isValid = false 
					print("❌ Too far from floor:", distY)
				end
			else
				isValid = false
				print("❌ Mouse position invalid for floor check")
			end
		end

		-- Visual Feedback
		local color = isValid and THEME.SUCCESS or THEME.DANGER
		
		-- Update Highlight
		local highlight = currentPreviewModel:FindFirstChild("PlacementHighlight") :: Highlight
		if highlight then
			highlight.FillColor = color
			highlight.OutlineColor = color
		end

		for _, part in ipairs(currentPreviewModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Color = color
				part.Transparency = 0.5
			end
		end

		currentPreviewModel:PivotTo(targetCF)
		currentPreviewModel:SetAttribute("IsValidPlacement", isValid)
	end)

	-- Handle clicking to place
	placementConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not isPlacementMode then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isWaitingConfirmation then return end

			local pos = input.Position
			local guis = PLAYER_GUI:GetGuiObjectsAtPosition(pos.X, pos.Y)
			local clickedUI = false
			for _, gui in ipairs(guis) do
				if gui:IsDescendantOf(placementHUD) then clickedUI = true break end
			end
			
			if not clickedUI then
				if currentPreviewModel then
					local isValid = currentPreviewModel:GetAttribute("IsValidPlacement")
					if isValid ~= false then
						isWaitingConfirmation = true
						
						local finalCF = currentPreviewModel:GetPivot()
						currentPreviewModel:PivotTo(finalCF)
						
						-- UI Update based on frozen state
						cancelBtn.Visible = false -- Sesuai instruksi: hanya confirm & rotate saat frozen
						confirmBtn.Visible = true
						rotateBtn.Visible = true
						
						print("📍 Placement frozen, waiting for confirmation")
					else
						print("⚠️ Cannot place here: IsValidPlacement is false")
					end
				end
			end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			self:CancelPlacement()
			placementHUD:Destroy()
		end
	end)
end

function DecorationController:ConfirmPlacement()
	print("🖱️ ConfirmPlacement called")
	if not isPlacementMode then print("❌ Not in placement mode") return end
	if not currentPreviewModel then print("❌ No preview model") return end
	if not currentItemId then print("❌ No item ID") return end
	if not isWaitingConfirmation then print("❌ Not waiting confirmation") return end
	
	local finalCFrame = currentPreviewModel:GetPivot()
	print("📡 Sending RequestPlaceDecoration for:", currentItemId)
	
	REMOTE_CLIENT:InvokeServer("RequestPlaceDecoration", currentItemId, finalCFrame):andThen(function(success, msg)
		if success then
			print("✅ Decoration placed successfully")
			moveModeDecorId = nil
			originalCFrame = nil
			self:CancelPlacement()
		else
			warn("❌ Failed to place decoration:", msg or "Unknown error")
		end
	end):catch(function(err)
		warn("🔥 Error in RequestPlaceDecoration:", err)
	end)
end

function DecorationController:CancelPlacement()
	cleanupSelectionMode()
	if not isPlacementMode then return end

	if moveModeDecorId and originalCFrame then
		-- Return to original position (item sudah di inventory karena di-remove saat pick-up)
		REMOTE_CLIENT:InvokeServer("RequestPlaceDecoration", currentItemId, originalCFrame):andThen(function(success)
			if success then print("✅ Decoration returned to original position") end
		end)
	end

	isPlacementMode = false
	isWaitingConfirmation = false
	moveModeDecorId = nil
	originalCFrame = nil
	currentItemId = nil
	currentRotation = 0
	toggleMainGUI(true) -- Show all UI back
	
	if currentPreviewModel then
		currentPreviewModel:Destroy()
		currentPreviewModel = nil
	end
	
	-- Clean up grid parts
	local grid = workspace:FindFirstChild("PlacementGrid")
	if grid then grid:Destroy() end

	if placementConnection then
		placementConnection:Disconnect()
		placementConnection = nil
	end
	if mouseConnection then
		mouseConnection:Disconnect()
		mouseConnection = nil
	end

	local hud = PLAYER_GUI:FindFirstChild("PlacementHUD")
	if hud then hud:Destroy() end
end

return DecorationController
