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
local REMOTE_CLIENT = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteClient"))

local THEME = {
	BG = Color3.fromRGB(11, 12, 15),
	CARD = Color3.fromRGB(20, 22, 27),
	ACCENT = Color3.fromRGB(0, 170, 255),
	GRADIENT = ColorSequence.new(Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 110, 255)),
	TEXT = Color3.fromRGB(240, 240, 240),
	SUBTEXT = Color3.fromRGB(140, 145, 155),
	DANGER = Color3.fromRGB(255, 60, 60),
}

local T_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- [STATE]
local activeCards: { [string]: Frame } = {}
local timerConn: RBXScriptConnection? = nil

-- [HELPERS]
local function log(msg: string) print(`[SHOP_AAA] {os.date("%X")} | {msg}`) end

local function applyStyle(inst: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = inst
	local stroke = Instance.new("UIStroke")
	stroke.Thickness, stroke.Color, stroke.Transparency = 1.5, Color3.new(1, 1, 1), 0.85
	stroke.Parent = inst
end

local function formatTime(seconds: number): string
	return seconds > 0 and string.format("%02d:%02d", math.floor(seconds/60), seconds%60) or "00:00"
end

-- [COMPONENTS]
local function createItemCard(id: string, stock: number, parent: GuiObject)
	local card = Instance.new("Frame")
	card.Name, card.BackgroundColor3, card.Parent = id, THEME.CARD, parent
	applyStyle(card, 12)
	
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio, aspect.Parent = 0.78, card

	local container = Instance.new("Frame")
	container.Size, container.BackgroundTransparency, container.Parent = UDim2.fromScale(1, 1), 1, card
	
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	pad.Parent = container

	local _title = Instance.new("TextLabel")
	_title.Size, _title.Text = UDim2.new(1, 0, 0, 25), id:gsub("id_", ""):upper()
	_title.TextColor3, _title.Font, _title.TextSize = THEME.TEXT, Enum.Font.GothamBold, 13
	_title.BackgroundTransparency, _title.Parent = 1, container

	local _stockLbl = Instance.new("TextLabel")
	_stockLbl.Name, _stockLbl.Size = "StockLabel", UDim2.new(1, 0, 0, 20)
	_stockLbl.Position, _stockLbl.BackgroundTransparency = UDim2.fromScale(0, 0.65), 1
	_stockLbl.Text, _stockLbl.TextColor3 = `STOCK: {stock}`, stock > 0 and THEME.SUBTEXT or THEME.DANGER
	_stockLbl.Font, _stockLbl.TextSize, _stockLbl.Parent = Enum.Font.GothamMedium, 11, container

	local btn = Instance.new("TextButton")
	btn.Name, btn.Size, btn.Position = "BuyButton", UDim2.new(1, 0, 0, 32), UDim2.fromScale(0, 1)
	btn.AnchorPoint, btn.BackgroundColor3 = Vector2.new(0, 1), stock > 0 and THEME.ACCENT or THEME.CARD
	btn.Text, btn.TextColor3, btn.Font = stock > 0 and "PURCHASE" or "SOLD OUT", Color3.new(1, 1, 1), Enum.Font.GothamBold
	btn.TextSize, btn.AutoButtonColor, btn.Parent = 12, false, container
	btn:SetAttribute("Stock", stock)
	applyStyle(btn, 6)
	
	local grad = Instance.new("UIGradient")
	grad.Color, grad.Rotation, grad.Enabled, grad.Parent = THEME.GRADIENT, 90, stock > 0, btn

	btn.MouseEnter:Connect(function()
		local sAttr = btn:GetAttribute("Stock")
		if typeof(sAttr) == "number" and sAttr > 0 then
			TweenService:Create(btn, T_INFO, { Size = UDim2.new(1, 4, 0, 34), Position = UDim2.new(0, -2, 1, 1) }):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, T_INFO, { Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromScale(0, 1) }):Play()
	end)

	return card
end

-- [CORE]
function ShopClient:Init()
	local sg = Instance.new("ScreenGui")
	sg.Name, sg.ResetOnSpawn, sg.Enabled, sg.Parent = "FishermanShop_AAA", false, false, PLAYER_GUI
	
	local blur = Instance.new("Frame")
	blur.Size, blur.BackgroundColor3, blur.BackgroundTransparency, blur.Parent = UDim2.fromScale(1, 1), Color3.new(0,0,0), 1, sg
	
	local main = Instance.new("CanvasGroup")
	main.Size, main.AnchorPoint = UDim2.fromOffset(650, 480), Vector2.new(0.5, 0.5)
	main.Position, main.GroupTransparency = UDim2.fromScale(0.5, 0.6), 1
	main.BackgroundColor3, main.Parent = THEME.BG, sg
	applyStyle(main, 20)

	local header = Instance.new("Frame")
	header.Size, header.BackgroundTransparency, header.Parent = UDim2.new(1, 0, 0, 70), 1, main
	
	local _headerTitle = Instance.new("TextLabel")
	_headerTitle.Text, _headerTitle.Size = "FISHERMAN MARKET", UDim2.new(1, -60, 1, 0)
	_headerTitle.Position, _headerTitle.TextColor3 = UDim2.fromOffset(30, 5), THEME.TEXT
	_headerTitle.Font, _headerTitle.TextSize, _headerTitle.TextXAlignment = Enum.Font.GothamBold, 24, Enum.TextXAlignment.Left
	_headerTitle.BackgroundTransparency, _headerTitle.Parent = 1, header
	
	local timerLbl = Instance.new("TextLabel")
	timerLbl.Text, timerLbl.Size = "00:00", UDim2.new(1, -40, 0, 30)
	timerLbl.Position, timerLbl.TextColor3 = UDim2.fromOffset(0, 22), THEME.ACCENT
	timerLbl.Font, timerLbl.TextSize, timerLbl.TextXAlignment = Enum.Font.Code, 14, Enum.TextXAlignment.Right
	timerLbl.BackgroundTransparency, timerLbl.Parent = 1, header

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size, scroll.Position = UDim2.new(1, -50, 1, -110), UDim2.fromOffset(25, 85)
	scroll.BackgroundTransparency, scroll.ScrollBarThickness, scroll.Parent = 1, 0, main
	
	local _grid = Instance.new("UIGridLayout")
	_grid.CellPadding, _grid.CellSize, _grid.Parent = UDim2.fromOffset(15, 15), UDim2.fromOffset(140, 185), scroll

	local close = Instance.new("TextButton")
	close.Size, close.Position = UDim2.fromOffset(32, 32), UDim2.new(1, -20, 0, 20)
	close.AnchorPoint, close.BackgroundColor3 = Vector2.new(1, 0), THEME.DANGER
	close.Text, close.TextColor3, close.Font, close.TextSize = "×", Color3.new(1,1,1), Enum.Font.GothamBold, 20
	close.Parent = main
	applyStyle(close, 8)

	local function toggle(state: boolean)
		if not state then 
			if timerConn then timerConn:Disconnect(); timerConn = nil end
			REMOTE_CLIENT:FireServer("ResumeBoatMovement")
		end
		
		TweenService:Create(blur, T_INFO, { BackgroundTransparency = state and 0.5 or 1 }):Play()
		local t = TweenService:Create(main, T_INFO, { 
			Position = state and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0.5, 0.6),
			GroupTransparency = state and 0 or 1 
		})
		t:Play()
		if not state then t.Completed:Wait(); sg.Enabled = false else sg.Enabled = true end
	end

	close.MouseButton1Click:Connect(function() toggle(false) end)

	REMOTE_CLIENT:On("OpenShopGUI", function(data: any)
		toggle(true)
		log("Processing Shop Data...")

		local endTs = os.time() + 3600
		local dateStr = tostring(data["end"])
		local y, m, d, h, min, s = dateStr:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z")
		
		if y and m and d and h and min and s then
			endTs = os.time({
				year = tonumber(y) :: number,
				month = tonumber(m) :: number,
				day = tonumber(d) :: number,
				hour = tonumber(h) :: number,
				min = tonumber(min) :: number,
				sec = tonumber(s) :: number
			})
		end

		if timerConn then timerConn:Disconnect() end
		timerConn = RunService.Heartbeat:Connect(function()
			local diff = endTs - os.time()
			timerLbl.Text = `RESTOCK IN: {formatTime(diff)}`
			if diff <= 0 and timerConn then timerConn:Disconnect(); timerConn = nil end
		end)

		for id, stock in pairs(data.item or {}) do
			local card = activeCards[id] or createItemCard(id, stock, scroll)
			activeCards[id] = card
			
			local buyBtn = card:FindFirstChild("BuyButton", true)
			local labelStock = card:FindFirstChild("StockLabel", true)
			
			if buyBtn and buyBtn:IsA("TextButton") and labelStock and labelStock:IsA("TextLabel") then
				buyBtn:SetAttribute("Stock", stock)
				buyBtn.Text = stock > 0 and "PURCHASE" or "SOLD OUT"
				buyBtn.BackgroundColor3 = stock > 0 and THEME.ACCENT or THEME.CARD
				local gradObj = buyBtn:FindFirstChildOfClass("UIGradient")
				if gradObj then gradObj.Enabled = stock > 0 end
				labelStock.Text = `STOCK: {stock}`
				labelStock.TextColor3 = stock > 0 and THEME.SUBTEXT or THEME.DANGER
			end
		end
	end)
end

return ShopClient