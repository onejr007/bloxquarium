local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the shared modules to be available
local Util = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util")
local NetworkService = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetworkService")

-- Use the utility function
Util.printHello()

-- Initialize network service
NetworkService:Initialize()

print("Client main script loaded successfully!")