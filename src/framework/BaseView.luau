-- Base View Class
-- Provides common functionality for all views

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local BaseView = {}
BaseView.__index = BaseView

-- Constructor
function BaseView.new()
	local self = setmetatable({}, BaseView)
	
	-- View properties
	self.Name = "BaseView"
	self.Template = nil
	self.Components = {}
	self.Data = {}
	self.Visible = false
	
	return self
end

-- Initialize view
function BaseView:Initialize()
	print("[View] " .. self.Name .. " initialized")
	self:CreateTemplate()
	self:LoadComponents()
end

-- Create view template
function BaseView:CreateTemplate()
	if not self.Template then
		self.Template = Instance.new("ScreenGui")
		self.Template.Name = self.Name
		self.Template.ResetOnSpawn = false
		self.Template.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		
		print("[View] Template created for " .. self.Name)
	end
end

-- Load view components
function BaseView:LoadComponents()
	-- Override in child classes
end

-- Render view
function BaseView:Render(data)
	self.Data = data or {}
	
	if self.Template then
		self:UpdateComponents()
		self:Show()
	end
end

-- Update components with data
function BaseView:UpdateComponents()
	-- Override in child classes
end

-- Show view
function BaseView:Show()
	if self.Template and not self.Visible then
		self.Template.Enabled = true
		self.Visible = true
		print("[View] " .. self.Name .. " shown")
	end
end

-- Hide view
function BaseView:Hide()
	if self.Template and self.Visible then
		self.Template.Enabled = false
		self.Visible = false
		print("[View] " .. self.Name .. " hidden")
	end
end

-- Toggle view visibility
function BaseView:Toggle()
	if self.Visible then
		self:Hide()
	else
		self:Show()
	end
end

-- Get component by name
function BaseView:GetComponent(name)
	return self.Components[name]
end

-- Add component
function BaseView:AddComponent(name, component)
	self.Components[name] = component
end

-- Remove component
function BaseView:RemoveComponent(name)
	if self.Components[name] then
		self.Components[name]:Destroy()
		self.Components[name] = nil
	end
end

-- Create text label
function BaseView:CreateLabel(text, position, size, parent)
	local label = Instance.new("TextLabel")
	label.Text = text
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.SourceSans
	label.TextSize = 18
	label.Parent = parent or self.Template
	
	return label
end

-- Create button
function BaseView:CreateButton(text, position, size, parent, callback)
	local button = Instance.new("TextButton")
	button.Text = text
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.SourceSans
	button.TextSize = 18
	button.Parent = parent or self.Template
	
	if callback then
		button.MouseButton1Click:Connect(callback)
	end
	
	return button
end

-- Create image
function BaseView:CreateImage(imageId, position, size, parent)
	local image = Instance.new("ImageLabel")
	image.Image = imageId
	image.Position = position
	image.Size = size
	image.BackgroundTransparency = 1
	image.Parent = parent or self.Template
	
	return image
end

-- Create frame
function BaseView:CreateFrame(position, size, parent, color)
	local frame = Instance.new("Frame")
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = color or Color3.new(0.1, 0.1, 0.1)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	frame.Parent = parent or self.Template
	
	return frame
end

-- Create input field
function BaseView:CreateInputField(placeholder, position, size, parent, callback)
	local frame = self:CreateFrame(position, size, parent, Color3.new(0.2, 0.2, 0.2))
	frame.BackgroundTransparency = 0.8
	
	local input = Instance.new("TextBox")
	input.PlaceholderText = placeholder
	input.Position = UDim2.new(0, 5, 0, 5)
	input.Size = UDim2.new(1, -10, 1, -10)
	input.BackgroundColor3 = Color3.new(1, 1, 1)
	input.TextColor3 = Color3.new(0, 0, 0)
	input.Font = Enum.Font.SourceSans
	input.TextSize = 16
	input.Parent = frame
	
	if callback then
		input.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				callback(input.Text)
			end
		end)
	end
	
	return input
end

-- Update label text
function BaseView:UpdateLabel(label, text)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

-- Update button text
function BaseView:UpdateButton(button, text)
	if button and button:IsA("TextButton") then
		button.Text = text
	end
end

-- Update image
function BaseView:UpdateImage(image, imageId)
	if image and image:IsA("ImageLabel") then
		image.Image = imageId
	end
end

-- Clear all components
function BaseView:Clear()
	for name, component in pairs(self.Components) do
		component:Destroy()
		self.Components[name] = nil
	end
end

-- Destroy view
function BaseView:Destroy()
	self:Clear()
	if self.Template then
		self.Template:Destroy()
		self.Template = nil
	end
	print("[View] " .. self.Name .. " destroyed")
end

-- Get view data
function BaseView:GetData()
	return self.Data
end

-- Set view data
function BaseView:SetData(data)
	self.Data = data
	self:Render(data)
end

-- Add event listener
function BaseView:AddEventListener(eventType, callback)
	if eventType == "Show" then
		self.Template.Changed:Connect(function(property)
			if property == "Enabled" and self.Template.Enabled then
				callback()
			end
		end)
	elseif eventType == "Hide" then
		self.Template.Changed:Connect(function(property)
			if property == "Enabled" and not self.Template.Enabled then
				callback()
			end
		end)
	end
end

-- Create progress bar
function BaseView:CreateProgressBar(position, size, parent)
	local frame = self:CreateFrame(position, size, parent, Color3.new(0.2, 0.2, 0.2))
	
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	background.BorderSizePixel = 1
	background.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
	background.Parent = frame
	
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
	fill.BorderSizePixel = 0
	fill.Parent = background
	
	return {
		Frame = frame,
		Background = background,
		Fill = fill,
		SetProgress = function(progress)
			progress = math.clamp(progress, 0, 1)
			fill.Size = UDim2.new(progress, 0, 1, 0)
		end
	}
end

-- Create list view
function BaseView:CreateListView(position, size, parent)
	local frame = self:CreateFrame(position, size, parent, Color3.new(0.1, 0.1, 0.1))
	
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 10
	scrollFrame.ScrollBarImageColor3 = Color3.new(0.2, 0.6, 1)
	scrollFrame.Parent = frame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.Parent = scrollFrame
	
	return {
		Frame = frame,
		ScrollFrame = scrollFrame,
		Layout = layout,
		AddItem = function(itemText, callback)
			local item = Instance.new("TextButton")
			item.Text = itemText
			item.Size = UDim2.new(1, 0, 0, 30)
			item.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
			item.TextColor3 = Color3.new(1, 1, 1)
			item.Font = Enum.Font.SourceSans
			item.TextSize = 16
			item.Parent = scrollFrame
			
			if callback then
				item.MouseButton1Click:Connect(callback)
			end
			
			return item
		end
	}
end

return BaseView