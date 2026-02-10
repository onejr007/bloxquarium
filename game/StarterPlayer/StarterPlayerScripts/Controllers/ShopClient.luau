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
	PRIMARY = Color3.fromRGB(10, 12, 16),
	SECONDARY = Color3.fromRGB(20, 24, 30),
	CARD_BG = Color3.fromRGB(26, 30, 38),
	ACCENT = Color3.fromRGB(0, 180, 255),
	WHITE = Color3.fromRGB(255, 255, 255),
	DANGER = Color3.fromRGB(255, 50, 70),
	SUCCESS = Color3.fromRGB(0, 255, 130),
}

local itemUIs = {} -- [itemId]: { stockLabel: TextLabel, updateStock: (newStock: number) -> () }

-- [DECORATOR]
local function applyDecor(inst: GuiObject, radius: number, strokeColor: Color3?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = inst
	if strokeColor then
		local s = Instance.new("UIStroke")
		s.Color, s.Thickness, s.ApplyStrokeMode = strokeColor, 1.5, Enum.ApplyStrokeMode.Border
		s.Parent = inst
	end
end

-- [ITEM COMPONENT]
local function createItemEntry(id: string, data: any, stockCount: number, parent: GuiObject)
	local stock, currentQty, isHovered = stockCount or 0, 1, false
	local basePrice = data.price or 0
	
	local container = Instance.new("Frame")
	container.Name, container.Size, container.BackgroundColor3 = id, UDim2.new(1, -10, 0, 105), THEME.CARD_BG
	container.Parent = parent
	applyDecor(container, 10, Color3.fromRGB(60, 65, 75))

	-- 1. Viewport
	local iconBox = Instance.new("Frame", container)
	iconBox.Size, iconBox.Position, iconBox.BackgroundColor3 = UDim2.fromOffset(85, 85), UDim2.fromOffset(10, 10), THEME.PRIMARY
	applyDecor(iconBox, 8)
	
	if data.mInfoName or data.mDropName then
		local _, model = VIEWPORT_MANAGER:CreateModelViewport(iconBox, data.mInfoName or data.mDropName, 0, 1.25)
		if model then
			task.spawn(function()
				local rot = 0
				while container and container.Parent do
					local dt = RunService.RenderStepped:Wait()
					if not isHovered then
						rot += 60 * dt
						model:PivotTo(CFrame.new(model:GetPivot().Position) * CFrame.Angles(0, math.rad(rot), 0))
					end
				end
			end)
		end
	end

	-- 2. Title
	local title = Instance.new("TextLabel", container)
	title.Size, title.Position = UDim2.new(0.4, 0, 0, 30), UDim2.fromOffset(110, 35)
	title.Text, title.TextColor3, title.Font, title.TextSize = (data.name or id):upper(), THEME.WHITE, Enum.Font.GothamBlack, 15
	title.TextXAlignment, title.BackgroundTransparency = Enum.TextXAlignment.Left, 1

	-- 3. INTERACTION AREA ([-], QTY/STOCK, [+], BUY)
	local interaction = Instance.new("Frame", container)
	interaction.Size, interaction.Position = UDim2.fromOffset(320, 45), UDim2.new(1, -10, 0.5, 0)
	interaction.AnchorPoint, interaction.BackgroundTransparency = Vector2.new(1, 0.5), 1

	local iLayout = Instance.new("UIListLayout", interaction)
	iLayout.FillDirection, iLayout.HorizontalAlignment, iLayout.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center
	iLayout.Padding = UDim.new(0, 10)

	local function createQtyBtn(txt: string)
		local b = Instance.new("TextButton")
		b.Size, b.BackgroundColor3 = UDim2.fromOffset(35, 35), THEME.SECONDARY
		b.Text, b.TextColor3, b.Font, b.TextSize = txt, THEME.ACCENT, Enum.Font.GothamBlack, 20
		applyDecor(b, 6, THEME.ACCENT)
		return b
	end

	local bMin = createQtyBtn("-")
	bMin.Parent = interaction

	local qtyCenter = Instance.new("Frame", interaction)
	qtyCenter.Size, qtyCenter.BackgroundTransparency = UDim2.fromOffset(70, 40), 1
	
	local qtyVal = Instance.new("TextLabel", qtyCenter)
	qtyVal.Size, qtyVal.Position = UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 0)
	qtyVal.Text, qtyVal.TextColor3, qtyVal.Font, qtyVal.TextSize = "1", THEME.WHITE, Enum.Font.GothamBlack, 16
	qtyVal.BackgroundTransparency = 1

	local stockSub = Instance.new("TextLabel", qtyCenter)
	stockSub.Size, stockSub.Position = UDim2.new(1, 0, 0, 15), UDim2.fromOffset(0, 20)
	stockSub.Text = `STOK: {stock}`
	stockSub.TextColor3, stockSub.Font, stockSub.TextSize = (stock > 0 and THEME.SUCCESS or THEME.DANGER), Enum.Font.GothamBold, 9
	stockSub.BackgroundTransparency = 1

	local function setStock(newStock: number)
		stock = newStock
		stockSub.Text = `STOK: {stock}`
		stockSub.TextColor3 = (stock > 0 and THEME.SUCCESS or THEME.DANGER)
		if currentQty > stock then
			currentQty = math.max(1, stock)
			qtyVal.Text = tostring(currentQty)
		end
	end
	itemUIs[id] = { updateStock = setStock }

	local bPlus = createQtyBtn("+")
	bPlus.Parent = interaction

	local buyBtn = Instance.new("TextButton", interaction)
	buyBtn.Size, buyBtn.BackgroundColor3 = UDim2.fromOffset(110, 38), THEME.ACCENT
	buyBtn.Text, buyBtn.TextColor3, buyBtn.Font, buyBtn.TextSize = `{basePrice} 🪙`, THEME.WHITE, Enum.Font.GothamBlack, 13
	applyDecor(buyBtn, 6)

	local function updateUI()
		qtyVal.Text = tostring(currentQty)
		buyBtn.Text = `{basePrice * currentQty} 🪙`
	end

	local function bindQty(btn: TextButton, step: number)
		local isDown = false
		btn.MouseButton1Down:Connect(function()
			isDown = true
			local delay = 0.3
			while isDown do
				if step > 0 and currentQty < stock then currentQty += 1
				elseif step < 0 and currentQty > 1 then currentQty -= 1 end
				updateUI()
				task.wait(delay)
				delay = math.max(0.04, delay * 0.75)
			end
		end)
		btn.MouseButton1Up:Connect(function() isDown = false end)
		btn.MouseLeave:Connect(function() isDown = false end)
	end

	bindQty(bMin, -1); bindQty(bPlus, 1)
	return container, buyBtn, function() return currentQty end
end

-- [CORE]
function ShopClient:Init()
	local sg = Instance.new("ScreenGui", PLAYER_GUI)
	sg.Name, sg.IgnoreGuiInset, sg.ResetOnSpawn = "PRO_SHOP_FINAL_V22", true, false
	sg.Enabled = false
	
	local main = Instance.new("Frame", sg)
	main.Size, main.AnchorPoint, main.Position = UDim2.fromScale(0.65, 0.75), Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	main.BackgroundColor3 = THEME.PRIMARY
	applyDecor(main, 12, THEME.WHITE)

	-- FIX HEADER AREA
	local header = Instance.new("ImageLabel", main)
	header.Name = "Header"
	header.Size, header.BackgroundColor3 = UDim2.new(1, 0, 0, 80), THEME.SECONDARY
	header.Image = ASSET_MANAGER.get("Shop_BACKGROUND") or "rbxassetid://102151919452993"
	header.ScaleType = Enum.ScaleType.Crop
	header.Parent = main
	applyDecor(header, 12)

	local titleLabel = Instance.new("TextLabel", header)
	titleLabel.Name = "TitleLabel"
	titleLabel.Text = "SUPPLY TERMINAL"
	titleLabel.Size, titleLabel.Position = UDim2.new(1, -100, 1, 0), UDim2.fromOffset(25, 0)
	titleLabel.TextColor3, titleLabel.Font, titleLabel.TextSize = THEME.WHITE, Enum.Font.GothamBlack, 24
	titleLabel.TextXAlignment, titleLabel.BackgroundTransparency = Enum.TextXAlignment.Left, 1

	local close = Instance.new("TextButton", header)
	close.Name = "CloseBtn"
	close.Size, close.Position, close.BackgroundColor3 = UDim2.fromOffset(30, 30), UDim2.new(1, -15, 0, 15), THEME.DANGER
	close.AnchorPoint, close.Text, close.TextColor3, close.Font = Vector2.new(1, 0), "✕", THEME.WHITE, Enum.Font.GothamBold
	close.Parent = header
	applyDecor(close, 8)

	-- SCROLL AREA
	local scroll = Instance.new("ScrollingFrame", main)
	scroll.Size, scroll.Position, scroll.BackgroundTransparency, scroll.ScrollBarThickness = UDim2.new(1, -20, 1, -100), UDim2.fromOffset(10, 90), 1, 2
	scroll.CanvasSize, scroll.AutomaticCanvasSize, scroll.Parent = UDim2.new(0,0,0,0), Enum.AutomaticSize.Y, main
	local mainLayout = Instance.new("UIListLayout", scroll)
	mainLayout.Padding, mainLayout.SortOrder = UDim.new(0, 15), Enum.SortOrder.LayoutOrder

	REMOTE_CLIENT:On("OpenShopGUI", function(payload)
		if not payload then return end
		itemUIs = {} -- Reset
		for _, v in ipairs(scroll:GetChildren()) do if not v:IsA("UIListLayout") then v:Destroy() end end
		
		local ORDER = {"EGG", "FISH", "FOOD", "PET", "OTHER"}
		local groups = {}
		for _, k in ipairs(ORDER) do groups[k] = {} end

		for _, item in ipairs(payload.items) do
			local c = (item.id:match("^id_(%a+)_") or "OTHER"):upper()
			if groups[c] then table.insert(groups[c], item) else table.insert(groups.OTHER, item) end
		end

		for i, catName in ipairs(ORDER) do
			local list = groups[catName]
			if #list > 0 then
				local catBox = Instance.new("Frame", scroll)
				catBox.Name, catBox.LayoutOrder = catName, i
				catBox.BackgroundTransparency, catBox.AutomaticSize = 1, Enum.AutomaticSize.Y
				catBox.Size = UDim2.new(1, 0, 0, 0)
				
				local catLayout = Instance.new("UIListLayout", catBox)
				catLayout.SortOrder, catLayout.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 8)

				local hBtn = Instance.new("TextButton", catBox)
				hBtn.LayoutOrder = 0
				hBtn.Size, hBtn.BackgroundColor3 = UDim2.new(1, -5, 0, 35), THEME.SECONDARY
				hBtn.Text, hBtn.TextColor3, hBtn.Font, hBtn.TextSize = `[-] {catName}`, THEME.ACCENT, Enum.Font.GothamBlack, 13
				applyDecor(hBtn, 6, Color3.fromRGB(50,50,60))

				local itemCont = Instance.new("Frame", catBox)
				itemCont.LayoutOrder = 1
				itemCont.Name, itemCont.BackgroundTransparency, itemCont.AutomaticSize = "Items", 1, Enum.AutomaticSize.Y
				itemCont.Size = UDim2.new(1, 0, 0, 0)
				Instance.new("UIListLayout", itemCont).Padding = UDim.new(0, 8)

				hBtn.MouseButton1Click:Connect(function()
					itemCont.Visible = not itemCont.Visible
					hBtn.Text = (itemCont.Visible and "[-] " or "[+] ") .. catName
				end)
				
				for _, item in ipairs(list) do
					local row, buy, getQ = createItemEntry(item.id, item.details, item.stock, itemCont)
					buy.MouseButton1Click:Connect(function()
						local success, msg = REMOTE_CLIENT:InvokeServer("GameAction_BuyItem", item.id, getQ()):await()
						
						local oldText, oldColor = buy.Text, buy.BackgroundColor3
						buy.Text = if success then "BERHASIL!" else "GAGAL!"
						buy.BackgroundColor3 = if success then THEME.SUCCESS else THEME.DANGER
						
						task.delay(1.5, function()
							buy.Text = oldText
							buy.BackgroundColor3 = oldColor
						end)
					end)
				end
			end
		end
		sg.Enabled = true
	end)

	REMOTE_CLIENT:On("UpdateShopStock", function(itemId, newStock)
		if itemUIs[itemId] then
			itemUIs[itemId].updateStock(newStock)
		end
	end)

	local function closeShop()
		if sg.Enabled then
			sg.Enabled = false
			REMOTE_CLIENT:FireServer("ResumeBoatMovement")
		end
	end

	close.MouseButton1Click:Connect(closeShop)

	-- Auto-close if distance > 30 studs
	task.spawn(function()
		while true do
			task.wait(1)
			if sg.Enabled then
				local boat = workspace:FindFirstChild("PerahuShopInstance")
				if boat and boat.PrimaryPart and PLAYER.Character and PLAYER.Character.PrimaryPart then
					local dist = (boat.PrimaryPart.Position - PLAYER.Character.PrimaryPart.Position).Magnitude
					if dist > 35 then
						closeShop()
					end
				end
			end
		end
	end)
end

return ShopClient