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

local THEME = {
	BG = Color3.fromRGB(12, 14, 20),
	CARD = Color3.fromRGB(25, 28, 38),
	ACCENT = Color3.fromRGB(0, 200, 255),
	GRADIENT = ColorSequence.new(Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 140, 255)),
	TEXT = Color3.fromRGB(255, 255, 255),
	SUBTEXT = Color3.fromRGB(160, 170, 185),
	DANGER = Color3.fromRGB(255, 75, 75),
	GOLD = Color3.fromRGB(255, 215, 0),
	COMMON = Color3.fromRGB(180, 180, 180),
	RARE = Color3.fromRGB(0, 200, 255),
	EPIC = Color3.fromRGB(200, 50, 255),
	LEGENDARY = Color3.fromRGB(255, 150, 0),
}

local T_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- [STATE]
local activeCards = {}
local timerConn: RBXScriptConnection? = nil
local distanceCheckConn: RBXScriptConnection? = nil

-- [HELPERS]
local function log(msg: string) print(`[SHOP_AAA] {os.date("%X")} | {msg}`) end

local function applyStyle(inst: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = inst
	local stroke = Instance.new("UIStroke")
	stroke.Thickness, stroke.Color, stroke.Transparency = 1.5, Color3.new(1, 1, 1), 0.88
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = inst
	
	if radius > 0 then
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "Shadow"
		shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		shadow.Position = UDim2.fromScale(0.5, 0.5)
		shadow.Size = UDim2.new(1, 20, 1, 20)
		shadow.BackgroundTransparency = 1
		shadow.Image = "rbxassetid://1316045217"
		shadow.ImageColor3 = Color3.new(0, 0, 0)
		shadow.ImageTransparency = 0.6
		shadow.ScaleType = Enum.ScaleType.Slice
		shadow.SliceCenter = Rect.new(10, 10, 118, 118)
		shadow.ZIndex = inst.ZIndex - 1
		shadow.Parent = inst
	end
end

local function formatTime(seconds: number): string
	if seconds < 0 then return "00:00" end
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

-- [COMPONENTS]
local function createItemCard(id: string, itemData: any, stock: number, parent: GuiObject)
	local card = Instance.new("Frame")
	card.Name, card.BackgroundColor3, card.Parent = id, THEME.CARD, parent
	applyStyle(card, 12)
	
	local rarity = (itemData.rarity or "common"):upper()
	local rarityColor = THEME[rarity] or THEME.COMMON

	local rarityBar = Instance.new("Frame")
	rarityBar.Size = UDim2.new(1, 0, 0, 4)
	rarityBar.BackgroundColor3 = rarityColor
	rarityBar.BorderSizePixel = 0
	rarityBar.Parent = card
	Instance.new("UICorner", rarityBar).CornerRadius = UDim.new(0, 12)

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio, aspect.Parent = 0.72, card

	local container = Instance.new("Frame")
	container.Size, container.BackgroundTransparency, container.Parent = UDim2.fromScale(1, 1), 1, card
	
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	pad.Parent = container

	local _title = Instance.new("TextLabel")
	_title.Size, _title.Text = UDim2.new(1, 0, 0, 20), (itemData.name or id):upper()
	_title.TextColor3, _title.Font, _title.TextSize = THEME.TEXT, Enum.Font.GothamBlack, 12
	_title.BackgroundTransparency, _title.Parent = 1, container
	_title.TextTruncate = Enum.TextTruncate.AtEnd

	-- [VIEWPORT]
	local viewFrame = Instance.new("ViewportFrame")
	viewFrame.Name = "Viewport"
	viewFrame.Size = UDim2.new(1, 0, 0.45, 0)
	viewFrame.Position = UDim2.fromScale(0, 0.15)
	viewFrame.BackgroundTransparency = 1
	viewFrame.Ambient = Color3.fromRGB(180, 180, 180)
	viewFrame.LightColor = Color3.fromRGB(255, 255, 255)
	viewFrame.LightDirection = Vector3.new(-1, -1, -1)
	viewFrame.Parent = container

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewFrame

	local cam = Instance.new("Camera")
	cam.FieldOfView = 35
	viewFrame.CurrentCamera = cam
	cam.Parent = viewFrame

	task.spawn(function()
		local mName = itemData.mInfoName
		if not mName then return end

		local assets = ReplicatedStorage:WaitForChild("assets", 5)
		if not assets then return end
		local models = assets:WaitForChild("models", 5)
		if not models then return end

		local targetModel = models:FindFirstChild(mName, true)
		if targetModel then
			local clone = targetModel:Clone()
			
			if clone:IsA("Model") then
				for _, p in ipairs(clone:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false; p.Anchored = true end
				end
			elseif clone:IsA("BasePart") then
				clone.CanCollide = false
				clone.Anchored = true
			end
			
			clone.Parent = worldModel
			
			local cf: CFrame, size: Vector3
			if clone:IsA("Model") then
				cf, size = (clone :: Model):GetBoundingBox()
				clone:PivotTo(CFrame.new(-cf.Position))
			elseif clone:IsA("BasePart") then
				size = (clone :: BasePart).Size;
				clone.CFrame = CFrame.new(-(clone.Position))
			end

			local maxDim = math.max(size.X, size.Y, size.Z)
			local dist = (maxDim / math.tan(math.rad(cam.FieldOfView / 2))) * 0.9
			cam.CFrame = CFrame.new(Vector3.new(dist, dist * 0.5, dist), Vector3.new(0, 0, 0))

			local rotSpeed = 0.5
			local conn: RBXScriptConnection?
			conn = RunService.RenderStepped:Connect(function(_dt)
				if not viewFrame or not viewFrame.Parent or not clone.Parent then
					if conn then conn:Disconnect() end
					return
				end
				local rot = CFrame.Angles(0, math.rad(rotSpeed), 0)
				if clone:IsA("Model") then
					clone:PivotTo(clone:GetPivot() * rot)
				elseif clone:IsA("BasePart") then
					clone.CFrame = clone.CFrame * rot
				end
			end)
		end
	end)

	local _priceLbl = Instance.new("TextLabel")
	_priceLbl.Size = UDim2.new(1, 0, 0, 18)
	_priceLbl.Position = UDim2.fromScale(0, 0.65)
	_priceLbl.Text = `{itemData.price or 0} 🪙`
	_priceLbl.TextColor3, _priceLbl.Font, _priceLbl.TextSize = THEME.GOLD, Enum.Font.GothamBold, 14
	_priceLbl.BackgroundTransparency, _priceLbl.Parent = 1, container

	local _stockLbl = Instance.new("TextLabel")
	_stockLbl.Name, _stockLbl.Size = "StockLabel", UDim2.new(1, 0, 0, 15)
	_stockLbl.Position, _stockLbl.BackgroundTransparency = UDim2.fromScale(0, 0.75), 1
	_stockLbl.Text, _stockLbl.TextColor3 = `STOCK: {stock}`, stock > 0 and THEME.SUBTEXT or THEME.DANGER
	_stockLbl.Font, _stockLbl.TextSize, _stockLbl.Parent = Enum.Font.GothamBold, 10, container

	local btn = Instance.new("TextButton")
	btn.Name, btn.Size, btn.Position = "BuyButton", UDim2.new(1, 0, 0, 30), UDim2.fromScale(0, 1)
	btn.AnchorPoint, btn.BackgroundColor3 = Vector2.new(0, 1), stock > 0 and THEME.ACCENT or THEME.CARD
	btn.Text, btn.TextColor3, btn.Font = stock > 0 and "PURCHASE" or "SOLD OUT", Color3.new(1, 1, 1), Enum.Font.GothamBold
	btn.TextSize, btn.AutoButtonColor, btn.Parent = 11, false, container
	btn:SetAttribute("Stock", stock)
	applyStyle(btn, 6)
	
	local grad = Instance.new("UIGradient")
	grad.Color, grad.Rotation, grad.Enabled, grad.Parent = THEME.GRADIENT, 90, stock > 0, btn

	btn.MouseEnter:Connect(function()
		local sAttr = btn:GetAttribute("Stock")
		if typeof(sAttr) == "number" and sAttr > 0 then
			TweenService:Create(btn, T_INFO, { Size = UDim2.new(1, 4, 0, 32), Position = UDim2.new(0, -2, 1, 1) }):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, T_INFO, { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromScale(0, 1) }):Play()
	end)

	return card
end

local function createSectionHeader(title: string, parent: GuiObject)
	local container = Instance.new("Frame")
	container.Name = "Header_" .. title
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = title:upper()
	label.TextColor3 = THEME.ACCENT
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.BackgroundTransparency = 1
	label.Parent = container
	
	local line = Instance.new("Frame")
	line.Size = UDim2.new(0, 35, 0, 3)
	line.Position = UDim2.new(0, 0, 1, -2)
	line.BackgroundColor3 = THEME.ACCENT
	line.BorderSizePixel = 0
	line.Parent = container
end

-- [CORE]
function ShopClient:Init()
	local sg = Instance.new("ScreenGui")
	sg.Name, sg.ResetOnSpawn, sg.Enabled, sg.Parent = "FishermanShop_AAA", false, false, PLAYER_GUI
	
	local blur = Instance.new("Frame")
	blur.Size, blur.BackgroundColor3, blur.BackgroundTransparency, blur.Parent = UDim2.fromScale(1, 1), Color3.new(0,0,0), 1, sg
	
	local main = Instance.new("CanvasGroup")
	main.Size, main.AnchorPoint = UDim2.fromOffset(650, 500), Vector2.new(0.5, 0.5)
	main.Position, main.GroupTransparency = UDim2.fromScale(0.5, 0.6), 1
	main.BackgroundColor3, main.Parent = THEME.BG, sg
	applyStyle(main, 16)

	-- [HEADER]
	local header = Instance.new("ImageLabel")
	header.Size, header.BackgroundTransparency, header.Parent = UDim2.new(1, 0, 0, 100), 0, main
	
	local function updateHeaderImage()
		local img = ASSET_MANAGER.get("Shop_BACKGROUND")
		if img then
			header.Image = img
		else
			header.Image = "rbxassetid://102151919452993"
		end
	end
	
	updateHeaderImage()
	task.spawn(function()
		if not ASSET_MANAGER.IsReady() then ASSET_MANAGER.OnReady:Wait() end
		updateHeaderImage()
	end)
	
	header.ScaleType = Enum.ScaleType.Crop
	
	local headerOverlay = Instance.new("Frame")
	headerOverlay.Size, headerOverlay.Parent = UDim2.fromScale(1, 1), header
	headerOverlay.BackgroundColor3 = Color3.new(0,0,0)
	headerOverlay.BackgroundTransparency = 0.5
	
	local _headerTitle = Instance.new("TextLabel")
	_headerTitle.Text, _headerTitle.Size = "ROYAL MARKET", UDim2.new(1, -60, 0, 40)
	_headerTitle.Position, _headerTitle.TextColor3 = UDim2.fromOffset(25, 20), THEME.TEXT
	_headerTitle.Font, _headerTitle.TextSize, _headerTitle.TextXAlignment = Enum.Font.GothamBlack, 28, Enum.TextXAlignment.Left
	_headerTitle.BackgroundTransparency, _headerTitle.ZIndex, _headerTitle.Parent = 1, 2, header
	
	local _headerSub = Instance.new("TextLabel")
	_headerSub.Text, _headerSub.Size = "PROFESSIONAL AQUATIC SUPPLIES", UDim2.new(1, -60, 0, 20)
	_headerSub.Position, _headerSub.TextColor3 = UDim2.fromOffset(25, 55), THEME.ACCENT
	_headerSub.Font, _headerSub.TextSize, _headerSub.TextXAlignment = Enum.Font.GothamBold, 11, Enum.TextXAlignment.Left
	_headerSub.BackgroundTransparency, _headerSub.ZIndex, _headerSub.Parent = 1, 2, header
	
	local timerLbl = Instance.new("TextLabel")
	timerLbl.Text, timerLbl.Size = "00:00", UDim2.new(1, -30, 0, 30)
	timerLbl.Position, timerLbl.TextColor3 = UDim2.fromOffset(0, 35), THEME.TEXT
	timerLbl.Font, timerLbl.TextSize, timerLbl.TextXAlignment = Enum.Font.Code, 16, Enum.TextXAlignment.Right
	timerLbl.BackgroundTransparency, timerLbl.ZIndex, timerLbl.Parent = 1, 2, header

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size, scroll.Position = UDim2.new(1, -40, 1, -130), UDim2.fromOffset(20, 110)
	scroll.BackgroundTransparency, scroll.ScrollBarThickness, scroll.Parent = 1, 0, main
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	
	local _list = Instance.new("UIListLayout")
	_list.Padding = UDim.new(0, 15)
	_list.SortOrder = Enum.SortOrder.LayoutOrder
	_list.Parent = scroll
	
	local _pad = Instance.new("UIPadding")
	_pad.PaddingLeft, _pad.PaddingRight = UDim.new(0, 5), UDim.new(0, 5)
	_pad.PaddingTop, _pad.PaddingBottom = UDim.new(0, 5), UDim.new(0, 5)
	_pad.Parent = scroll

	local close = Instance.new("TextButton")
	close.Size, close.Position = UDim2.fromOffset(28, 28), UDim2.new(1, -15, 0, 15)
	close.AnchorPoint, close.BackgroundColor3 = Vector2.new(1, 0), THEME.DANGER
	close.Text, close.TextColor3, close.Font, close.TextSize = "×", Color3.new(1,1,1), Enum.Font.GothamBold, 18
	close.ZIndex, close.Parent = 3, main
	applyStyle(close, 6)

	local function toggle(state: boolean)
		if not state then 
			if timerConn then timerConn:Disconnect(); timerConn = nil end
			if distanceCheckConn then distanceCheckConn:Disconnect(); distanceCheckConn = nil end
			REMOTE_CLIENT:FireServer("ResumeBoatMovement")
		end
		
		TweenService:Create(blur, T_INFO, { BackgroundTransparency = state and 0.5 or 1 }):Play()
		local t = TweenService:Create(main, T_INFO, { 
			Position = state and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0.5, 0.6),
			GroupTransparency = state and 0 or 1 
		})
		t:Play()
		if not state then 
			t.Completed:Wait() 
			sg.Enabled = false 
		else 
			sg.Enabled = true 
		end
	end

	local function startDistanceCheck(boatModel: Model)
		if distanceCheckConn then distanceCheckConn:Disconnect() end
		distanceCheckConn = RunService.Heartbeat:Connect(function()
			if not sg.Enabled then return end
			local char = PLAYER.Character
			if not char or not boatModel.PrimaryPart then return end
			local dist = (char:GetPivot().Position - boatModel:GetPivot().Position).Magnitude
			if dist > 35 then toggle(false) end
		end)
	end

	close.MouseButton1Click:Connect(function() toggle(false) end)

	REMOTE_CLIENT:On("OpenShopGUI", function(payload: any)
		if not payload or not payload.items then return end
		log(`Shop Data Received: {payload.items and #payload.items or 0} items`)
		toggle(true)
		
		for _, child in ipairs(scroll:GetChildren()) do
			if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
		end
		activeCards = {}

		local boat = workspace:FindFirstChild("PerahuShopInstance")
		if boat and boat:IsA("Model") then startDistanceCheck(boat) end

		local endTime = payload.endTime or os.time() + 3600
		local endTs = 0
		if typeof(endTime) == "string" then
			local y, m, d, h, mn, s = endTime:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z")
			if y then
				local dateTable: any = {
					year = tonumber(y) or 2026,
					month = tonumber(m) or 2,
					day = tonumber(d) or 9,
					hour = tonumber(h) or 0,
					min = tonumber(mn) or 0,
					sec = tonumber(s) or 0
				}
				endTs = os.time(dateTable)
			else
				endTs = os.time() + 600
			end
		elseif typeof(endTime) == "number" then
			endTs = endTime
		end

		if timerConn then timerConn:Disconnect() end
		timerConn = RunService.Heartbeat:Connect(function()
			local diff = endTs - os.time()
			timerLbl.Text = `RESTOCK IN: {formatTime(diff)}`
			if diff <= 0 then
				if timerConn then timerConn:Disconnect(); timerConn = nil end
			end
		end)

		local cats = {"Egg", "Fish", "Food"}
		local byCat = {}
		for _, c in ipairs(cats) do byCat[c] = {} end
		
		for _, item in ipairs(payload.items) do
			local c = item.category or "Other"
			if not byCat[c] then 
				byCat[c] = {} 
				table.insert(cats, c)
			end
			table.insert(byCat[c], item)
		end

		for i, catName in ipairs(cats) do
			local items = byCat[catName]
			if not items or #items == 0 then continue end

			local catContainer = Instance.new("Frame")
			catContainer.Name, catContainer.Size = "Cat_" .. catName, UDim2.new(1, 0, 0, 0)
			catContainer.AutomaticSize, catContainer.BackgroundTransparency = Enum.AutomaticSize.Y, 1
			catContainer.LayoutOrder, catContainer.Parent = i, scroll

			createSectionHeader(catName, catContainer)

			local gridFrame = Instance.new("Frame")
			gridFrame.Size, gridFrame.Position = UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 35)
			gridFrame.AutomaticSize, gridFrame.BackgroundTransparency = Enum.AutomaticSize.Y, 1
			gridFrame.Parent = catContainer

			local grid = Instance.new("UIGridLayout")
			grid.CellPadding, grid.CellSize = UDim2.fromOffset(12, 12), UDim2.fromOffset(150, 210)
			grid.Parent = gridFrame

			for _, item in ipairs(items) do
				local card = createItemCard(item.id, item.details, item.stock, gridFrame)
				activeCards[item.id] = card
				
				local buyBtn = card:FindFirstChild("BuyButton", true) :: TextButton
				if buyBtn then
					buyBtn.MouseButton1Click:Connect(function()
						local s = buyBtn:GetAttribute("Stock")
						if typeof(s) == "number" and s > 0 then
							buyBtn.Text = "WAITING..."
							REMOTE_CLIENT:InvokeServer("GameAction_BuyItem", item.id):andThen(function(ok, _msg)
								if ok then
									buyBtn.Text = "SUCCESS!"
									buyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
								else
									buyBtn.Text = "FAILED"; buyBtn.BackgroundColor3 = THEME.DANGER
									task.wait(1)
									buyBtn.Text = "PURCHASE"; buyBtn.BackgroundColor3 = THEME.ACCENT
								end
							end)
						end
					end)
				end
			end
		end
	end)
end

return ShopClient
