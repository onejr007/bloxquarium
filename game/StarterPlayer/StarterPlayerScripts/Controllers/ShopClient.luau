--!strict
local ShopClient = {}

-- [SERVICES]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- [CONSTANTS]
local PLAYER = Players.LocalPlayer
local PLAYER_GUI = PLAYER:WaitForChild("PlayerGui")
local SHARED = ReplicatedStorage:WaitForChild("Shared")
local REMOTE_CLIENT = require(SHARED:WaitForChild("RemoteClient"))
local ASSET_MANAGER = require(SHARED:WaitForChild("AssetManagerV3"))
local VIEWPORT_MANAGER = require(SHARED:WaitForChild("ViewportManager"))

local THEME = {
	BG = Color3.fromRGB(10, 12, 18),
	CARD = Color3.fromRGB(20, 23, 33),
	ACCENT = Color3.fromRGB(0, 210, 255),
	GRADIENT = ColorSequence.new(Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 100, 255)),
	TEXT = Color3.fromRGB(255, 255, 255),
	SUBTEXT = Color3.fromRGB(140, 150, 175),
	DANGER = Color3.fromRGB(255, 65, 85),
	GOLD = Color3.fromRGB(255, 215, 0),
	-- Rarity Palette
	COMMON = Color3.fromRGB(170, 170, 170),
	RARE = Color3.fromRGB(0, 200, 255),
	EPIC = Color3.fromRGB(190, 60, 255),
	LEGENDARY = Color3.fromRGB(255, 145, 0),
}

local T_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local T_BOUNCE = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- [STATE]
local activeCards = {}
local timerConn: RBXScriptConnection? = nil
local distanceCheckConn: RBXScriptConnection? = nil

-- [HELPERS]
local function log(msg: string) print(`[SHOP_CLIENT] {os.date("%X")} | {msg}`) end

local function applyStyle(inst: GuiObject, radius: number, hasStroke: boolean?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = inst
	
	if hasStroke then
		local stroke = Instance.new("UIStroke")
		stroke.Thickness, stroke.Color, stroke.Transparency = 1.2, Color3.new(1, 1, 1), 0.85
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = inst
	end
end

local function formatTime(s: number): string
	return s <= 0 and "00:00" or string.format("%02d:%02d", math.floor(s/60), s%60)
end

-- [COMPONENTS]
local function createItemCard(id: string, itemData: any, stock: number, parent: GuiObject)
	local rarity = (itemData.rarity or "common"):upper()
	local rColor = THEME[rarity] or THEME.COMMON

	local card = Instance.new("Frame")
	card.Name, card.BackgroundColor3, card.Parent = id, THEME.CARD, parent
	applyStyle(card, 14, true)
	
	-- Glow Effect (Modern Touch)
	local glow = Instance.new("ImageLabel")
	glow.Name, glow.Size, glow.Position = "Glow", UDim2.new(1.4, 0, 1.4, 0), UDim2.fromScale(0.5, 0.5)
	glow.AnchorPoint, glow.BackgroundTransparency = Vector2.new(0.5, 0.5), 1
	glow.Image, glow.ImageColor3, glow.ImageTransparency = "rbxassetid://6201725661", rColor, 0.92
	glow.ZIndex = card.ZIndex - 1
	glow.Parent = card

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio, aspect.Parent = 0.72, card

	local container = Instance.new("Frame")
	container.Size, container.BackgroundTransparency, container.Parent = UDim2.fromScale(1, 1), 1, card
	
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 12), UDim.new(0, 12)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
	pad.Parent = container

	local title = Instance.new("TextLabel")
	title.Size, title.Text = UDim2.new(1, 0, 0, 20), (itemData.name or id):upper()
	title.TextColor3, title.Font, title.TextSize = THEME.TEXT, Enum.Font.GothamBold, 13
	title.RichText, title.BackgroundTransparency, title.Parent = true, 1, container
	title.TextTruncate = Enum.TextTruncate.AtEnd

	local viewContainer = Instance.new("Frame")
	viewContainer.Name, viewContainer.Size, viewContainer.Position = "ViewportContainer", UDim2.new(1, 0, 0.45, 0), UDim2.fromScale(0, 0.18)
	viewContainer.BackgroundTransparency, viewContainer.Parent = 1, container

	local modelName = itemData.mInfoName or itemData.mDropName
	if modelName then
		VIEWPORT_MANAGER:CreateModelViewport(viewContainer, modelName, 0, 1.2)
		local model = VIEWPORT_MANAGER:GetModel(modelName)
		if model then
			local rotSpeed = 45 -- degrees per second
			task.spawn(function()
				while model and model.Parent do
					local dt = RunService.RenderStepped:Wait()
					model:PivotTo(model:GetPivot() * CFrame.Angles(0, math.rad(rotSpeed * dt), 0))
				end
			end)
		end
	end

	local priceLbl = Instance.new("TextLabel")
	priceLbl.Size, priceLbl.Position = UDim2.new(1, 0, 0, 18), UDim2.fromScale(0, 0.68)
	priceLbl.Text = `<b>{itemData.price or 0}</b> <font color="#FFD700">🪙</font>`
	priceLbl.RichText, priceLbl.TextColor3, priceLbl.Font, priceLbl.TextSize = true, THEME.TEXT, Enum.Font.GothamMedium, 15
	priceLbl.BackgroundTransparency, priceLbl.Parent = 1, container

	local stockLbl = Instance.new("TextLabel")
	stockLbl.Name, stockLbl.Size = "StockLabel", UDim2.new(1, 0, 0, 15)
	stockLbl.Position, stockLbl.BackgroundTransparency = UDim2.fromScale(0, 0.76), 1
	stockLbl.Text = stock > 0 and `STOCK: {stock}` or "OUT OF STOCK"
	stockLbl.TextColor3 = stock > 0 and THEME.SUBTEXT or THEME.DANGER
	stockLbl.Font, stockLbl.TextSize, stockLbl.Parent = Enum.Font.GothamBold, 10, container

	local btn = Instance.new("TextButton")
	btn.Name, btn.Size, btn.Position = "BuyButton", UDim2.new(1, 0, 0, 32), UDim2.fromScale(0, 1)
	btn.AnchorPoint, btn.BackgroundColor3 = Vector2.new(0, 1), stock > 0 and THEME.ACCENT or Color3.fromRGB(40, 42, 50)
	btn.Text, btn.TextColor3, btn.Font = stock > 0 and "PURCHASE" or "SOLD", Color3.new(1, 1, 1), Enum.Font.GothamBlack
	btn.TextSize, btn.AutoButtonColor, btn.Parent = 11, false, container
	btn:SetAttribute("Stock", stock)
	applyStyle(btn, 8)
	
	if stock > 0 then
		local grad = Instance.new("UIGradient")
		grad.Color, grad.Rotation, grad.Parent = THEME.GRADIENT, 45, btn
	end

	btn.MouseEnter:Connect(function()
		if btn:GetAttribute("Stock") > 0 then
			TweenService:Create(btn, T_INFO, {Size = UDim2.new(1, 6, 0, 36), Position = UDim2.new(0, -3, 1, 2)}):Play()
			TweenService:Create(card, T_INFO, {BackgroundColor3 = Color3.fromRGB(35, 38, 50)}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, T_INFO, {Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromScale(0, 1)}):Play()
		TweenService:Create(card, T_INFO, {BackgroundColor3 = THEME.CARD}):Play()
	end)

	return card
end

-- [CORE]
function ShopClient:Init()
	log("Initializing ShopClient...")
	local sg = Instance.new("ScreenGui")
	sg.Name, sg.ResetOnSpawn, sg.Enabled, sg.Parent = "FishermanShop_PRO", false, false, PLAYER_GUI
	
	local overlay = Instance.new("Frame")
	overlay.Size, overlay.BackgroundColor3, overlay.BackgroundTransparency, overlay.Parent = UDim2.fromScale(1, 1), Color3.new(0,0,0), 1, sg
	
	local main = Instance.new("CanvasGroup")
	main.Size, main.AnchorPoint = UDim2.fromOffset(680, 520), Vector2.new(0.5, 0.5)
	main.Position, main.GroupTransparency = UDim2.fromScale(0.5, 0.55), 1
	main.BackgroundColor3, main.Parent = THEME.BG, sg
	applyStyle(main, 20, true)

	-- Header Section
	local header = Instance.new("ImageLabel")
	header.Size, header.BackgroundTransparency, header.Parent = UDim2.new(1, 0, 0, 100), 0, main
	header.ScaleType = Enum.ScaleType.Crop
	
	local function updateImg() 
		local asset = ASSET_MANAGER.get("Shop_BACKGROUND")
		header.Image = asset or "rbxassetid://102151919452993"
	end
	updateImg()
	task.spawn(function() if not ASSET_MANAGER.IsReady() then ASSET_MANAGER.OnReady:Wait() end; updateImg() end)
	
	local headerGradient = Instance.new("Frame")
	headerGradient.Size, headerGradient.Parent = UDim2.fromScale(1, 1), header
	headerGradient.BackgroundColor3 = Color3.new(0,0,0)
	local hGrad = Instance.new("UIGradient")
	hGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.4), NumberSequenceKeypoint.new(1,1)})
	hGrad.Rotation, hGrad.Parent = 90, headerGradient
	
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Text, titleLbl.Size = "ROYAL MARKET", UDim2.new(1, -60, 0, 30)
	titleLbl.Position, titleLbl.TextColor3 = UDim2.fromOffset(30, 25), THEME.TEXT
	titleLbl.Font, titleLbl.TextSize, titleLbl.TextXAlignment = Enum.Font.GothamBlack, 28, Enum.TextXAlignment.Left
	titleLbl.BackgroundTransparency, titleLbl.Parent = 1, header
	
	local subLbl = Instance.new("TextLabel")
	subLbl.Text, subLbl.Size = "PROFESSIONAL AQUATIC SUPPLIES", UDim2.new(1, -60, 0, 20)
	subLbl.Position, subLbl.TextColor3 = UDim2.fromOffset(30, 55), THEME.ACCENT
	subLbl.Font, subLbl.TextSize, subLbl.TextXAlignment = Enum.Font.GothamBold, 11, Enum.TextXAlignment.Left
	subLbl.BackgroundTransparency, subLbl.Parent = 1, header
	
	local timerLbl = Instance.new("TextLabel")
	timerLbl.Text, timerLbl.Size = "00:00", UDim2.new(0, 200, 0, 30)
	timerLbl.Position, timerLbl.TextColor3 = UDim2.new(1, -230, 0, 35), THEME.TEXT
	timerLbl.Font, timerLbl.TextSize, timerLbl.TextXAlignment = Enum.Font.Code, 16, Enum.TextXAlignment.Right
	timerLbl.BackgroundTransparency, timerLbl.Parent = 1, header

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size, scroll.Position = UDim2.new(1, -50, 1, -135), UDim2.fromOffset(25, 115)
	scroll.BackgroundTransparency, scroll.ScrollBarThickness, scroll.Parent = 1, 0, main
	scroll.CanvasSize, scroll.AutomaticCanvasSize = UDim2.new(0,0,0,0), Enum.AutomaticSize.Y
	
	Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 20)
	Instance.new("UIPadding", scroll).PaddingLeft = UDim.new(0, 5)

	local close = Instance.new("TextButton")
	close.Size, close.Position = UDim2.fromOffset(32, 32), UDim2.new(1, -20, 0, 20)
	close.AnchorPoint, close.BackgroundColor3 = Vector2.new(1, 0), THEME.DANGER
	close.Text, close.TextColor3, close.Font, close.TextSize = "×", Color3.new(1,1,1), Enum.Font.GothamBold, 20
	close.ZIndex, close.Parent = 5, main
	applyStyle(close, 10)

	local function toggle(state: boolean)
		log(`UI Toggle: {state}`)
		if not state then 
			if timerConn then timerConn:Disconnect(); timerConn = nil end
			if distanceCheckConn then distanceCheckConn:Disconnect(); distanceCheckConn = nil end
			REMOTE_CLIENT:FireServer("ResumeBoatMovement")
		end
		
		TweenService:Create(overlay, T_INFO, { BackgroundTransparency = state and 0.45 or 1 }):Play()
		local t = TweenService:Create(main, state and T_BOUNCE or T_INFO, { 
			Position = state and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0.5, 0.55),
			GroupTransparency = state and 0 or 1 
		})
		t:Play()
		if state then sg.Enabled = true else t.Completed:Wait(); sg.Enabled = false end
	end

	close.MouseButton1Click:Connect(function() toggle(false) end)

	REMOTE_CLIENT:On("OpenShopGUI", function(payload: any)
		if not payload or not payload.items then return end
		log(`Data Payload: {#payload.items} items found.`)
		
		for _, v in ipairs(scroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
		activeCards = {}

		local boat = workspace:FindFirstChild("PerahuShopInstance")
		if boat then 
			distanceCheckConn = RunService.Heartbeat:Connect(function()
				if sg.Enabled and (PLAYER.Character:GetPivot().Position - boat:GetPivot().Position).Magnitude > 35 then toggle(false) end
			end)
		end

		-- Timer Logic
		local endTs = typeof(payload.endTime) == "number" and payload.endTime or os.time() + 600
		timerConn = RunService.Heartbeat:Connect(function()
			timerLbl.Text = `RESTOCK: {formatTime(endTs - os.time())}`
		end)

		-- Categorization
		local cats = {"Egg", "Fish", "Food"}
		local byCat = {}
		for _, c in ipairs(cats) do byCat[c] = {} end
		for _, item in ipairs(payload.items) do
			local c = item.category or "Other"
			if not byCat[c] then byCat[c] = {}; table.insert(cats, c) end
			table.insert(byCat[c], item)
		end

		for i, name in ipairs(cats) do
			local items = byCat[name]
			if #items == 0 then continue end
			
			local catFrame = Instance.new("Frame")
			catFrame.Name, catFrame.Size, catFrame.AutomaticSize = "Cat_"..name, UDim2.new(1,0,0,0), Enum.AutomaticSize.Y
			catFrame.BackgroundTransparency, catFrame.LayoutOrder, catFrame.Parent = 1, i, scroll
			
			-- Section Header
			local head = Instance.new("TextLabel")
			head.Text, head.Size = name:upper(), UDim2.new(1,0,0,30)
			head.TextColor3, head.Font, head.TextSize = THEME.ACCENT, Enum.Font.GothamBlack, 16
			head.TextXAlignment, head.BackgroundTransparency, head.Parent = Enum.TextXAlignment.Left, 1, catFrame
			
			local grid = Instance.new("Frame")
			grid.Size, grid.Position, grid.AutomaticSize = UDim2.new(1,0,0,0), UDim2.fromOffset(0, 35), Enum.AutomaticSize.Y
			grid.BackgroundTransparency, grid.Parent = 1, catFrame
			
			local layout = Instance.new("UIGridLayout", grid)
			layout.CellPadding, layout.CellSize = UDim2.fromOffset(15, 15), UDim2.fromOffset(150, 210)

			for _, item in ipairs(items) do
				local card = createItemCard(item.id, item.details, item.stock, grid)
				local buy = card:FindFirstChild("BuyButton", true) :: TextButton
				buy.MouseButton1Click:Connect(function()
					if buy:GetAttribute("Stock") > 0 then
						buy.Text = "..."
						REMOTE_CLIENT:InvokeServer("GameAction_BuyItem", item.id):andThen(function(ok)
							buy.Text = ok and "SUCCESS" or "FAILED"
							buy.BackgroundColor3 = ok and Color3.fromRGB(0,200,100) or THEME.DANGER
							task.wait(1)
							buy.Text = buy:GetAttribute("Stock") > 0 and "PURCHASE" or "SOLD"
							buy.BackgroundColor3 = THEME.ACCENT
						end)
					end
				end)
			end
		end
		toggle(true)
	end)
end

return ShopClient