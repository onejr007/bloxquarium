--!strict
local MainHUDController = {}

-- [SERVICES]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- [CONSTANTS]
local PLAYER = Players.LocalPlayer
local PLAYER_GUI = PLAYER:WaitForChild("PlayerGui")
local SHARED = ReplicatedStorage:WaitForChild("Shared")
local REMOTE_CLIENT = require(SHARED:WaitForChild("RemoteClient"))
local ASSET_MANAGER = require(SHARED:WaitForChild("AssetManagerV3"))

local THEME = {
	PRIMARY = Color3.fromRGB(20, 24, 30),
	ACCENT = Color3.fromRGB(0, 180, 255),
	WHITE = Color3.fromRGB(255, 255, 255),
}

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

function MainHUDController:Init()
	local sg = Instance.new("ScreenGui")
	sg.Name = "MainHUD"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.Enabled = false -- Wait for loading
	sg.Parent = PLAYER_GUI

	local container = Instance.new("Frame", sg)
	container.Name = "TeleportContainer"
	container.Size = UDim2.fromOffset(420, 50)
	container.Position = UDim2.new(0.5, 0, 0, 20)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundTransparency = 1

	local layout = Instance.new("UIListLayout", container)
	layout.Padding = UDim.new(0, 15)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	local function createTPButton(text: string, action: string)
		local btn = Instance.new("TextButton")
		btn.Name = text .. "Btn"
		btn.Size = UDim2.fromOffset(180, 40)
		btn.BackgroundColor3 = THEME.PRIMARY
		btn.Text = text:upper()
		btn.TextColor3 = THEME.WHITE
		btn.Font = Enum.Font.GothamBlack
		btn.TextSize = 13
		applyDecor(btn, 8, THEME.ACCENT)
		btn.Parent = container

		btn.MouseButton1Click:Connect(function()
			REMOTE_CLIENT:InvokeServer("GameAction_Teleport", action)
		end)

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.ACCENT}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.PRIMARY}):Play()
		end)
	end

	createTPButton("Teleport to Shop", "Shop")
	createTPButton("Teleport to Plot", "Plot")

	-- Show HUD when server is ready
	REMOTE_CLIENT:On("ServerReady", function()
		task.wait(1.5) -- Small delay after loading screen fades
		sg.Enabled = true
	end)
end

return MainHUDController
