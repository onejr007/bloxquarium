-- Server Initialization
-- Main entry point for the server-side MVC framework

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Load the framework
local Framework = require(ReplicatedStorage.Framework)

-- Initialize the framework
local frameworkInstance = Framework:Initialize()

-- Register routes
local Router = require(ReplicatedStorage.Framework.Router)
local routerInstance = Router.new()
routerInstance:Initialize()

-- Register default routes
routerInstance:RegisterDefaults()

-- Register custom routes
routerInstance:Get("/api/players", "PlayerController", "GetAllPlayers")
routerInstance:Get("/api/players/:id", "PlayerController", "GetPlayer")
routerInstance:Post("/api/players", "PlayerController", "CreatePlayer")
routerInstance:Put("/api/players/:id", "PlayerController", "UpdatePlayer")
routerInstance:Delete("/api/players/:id", "PlayerController", "DeletePlayer")

-- Register middleware
routerInstance:AddMiddleware("Auth", function(player, data)
	-- Authentication middleware
	print("[Middleware] Auth check for player: " .. player.Name)
	return true -- For now, allow all players
end)

routerInstance:AddMiddleware("RateLimit", function(player, data)
	-- Rate limiting middleware
	print("[Middleware] Rate limit check for player: " .. player.Name)
	return true -- For now, allow all requests
end)

-- Add middleware to specific routes
routerInstance:AddMiddlewareToRoute("GET", "/api/players", "Auth")
routerInstance:AddMiddlewareToRoute("POST", "/api/players", "Auth")
routerInstance:AddMiddlewareToRoute("PUT", "/api/players/:id", "Auth")
routerInstance:AddMiddlewareToRoute("DELETE", "/api/players/:id", "Auth")

-- Player joining event
Players.PlayerAdded:Connect(function(player)
	print("[Server] Player joined: " .. player.Name)
	
	-- Send framework ready signal to client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local readyEvent = remoteEvents:FindFirstChild("FrameworkReady")
		if readyEvent then
			readyEvent:FireClient(player, {
				framework = "MVC Framework",
				version = "1.0.0",
				status = "ready"
			})
		end
	end
end)

-- Player leaving event
Players.PlayerRemoving:Connect(function(player)
	print("[Server] Player left: " .. player.Name)
end)

-- Game started event
game:BindToClose(function()
	print("[Server] Game shutting down...")
	
	-- Save any unsaved data
	local playerModel = frameworkInstance:Get("Model", "PlayerModel")
	if playerModel then
		local backup = playerModel:Backup()
		print("[Server] Player data backed up")
	end
	
	return false
end)

print("[Server] MVC Framework server initialized successfully!")