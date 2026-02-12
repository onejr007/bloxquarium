--[[
    ServiceLoader.luau (v2.3 - Hotfix for SendToAllClients)
]]

local ServiceLoader = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ServicesFolder = ServerScriptService:WaitForChild("Services")

-- Define the initialization order. GameActions is now after the services it depends on.
local INIT_ORDER = {
    "WorldService",
    "FirebaseService",
    "DatabaseService",
    "DataService",
    "RemoteService",
    "ShopService",
    "AdminService",
    "PlotService",
    "UnderwaterService",
    "LeaderboardService",
    "GameActions" -- GameActions is now initialized after AdminService and ShopService
}

local services = {}

function ServiceLoader:Init()
    print("🤖 [ServiceLoader] Starting service initialization...")

    -- Require all service modules first
    for _, serviceName in ipairs(INIT_ORDER) do
        local serviceModule = ServicesFolder:FindFirstChild(serviceName)
        if serviceModule and serviceModule:IsA("ModuleScript") then
            print(string.format("   -> Requiring service: %s", serviceName))
            local success, result = pcall(require, serviceModule)
            if success then services[serviceName] = result else error(string.format("CRITICAL: Module '%s' failed. Error: %s", serviceName, tostring(result))) end
        else
            warn(string.format("   -> Service module not found: %s", serviceName))
        end
    end

    print("🚀 [ServiceLoader] Initializing services with dependency injection...")
    -- Initialize each service with its required dependencies
    for _, serviceName in ipairs(INIT_ORDER) do
        local service = services[serviceName]
        if not service then continue end

        if service.Init then
            print(string.format("   -> Initializing service: %s", serviceName))
            
            local args = {}
            -- Define dependencies for each service
            if serviceName == "GameActions" then
                args = {services["RemoteService"], services["AdminService"], services["ShopService"], services["PlotService"]}
            elseif serviceName == "AdminService" then
                 args = {services["DataService"], services["ShopService"]}
            elseif serviceName == "ShopService" then
                args = {services["RemoteService"], services["DataService"]}
            elseif serviceName == "DataService" then
                args = {services["FirebaseService"], services["DatabaseService"]}
            elseif serviceName == "PlotService" then
                args = {services["DataService"], services["RemoteService"], services["UnderwaterService"]}
            elseif serviceName == "UnderwaterService" then
                args = {services["DataService"], services["RemoteService"]}
            elseif serviceName == "InventoryService" then
                args = {services["DataService"], services["RemoteService"], services["UnderwaterService"]}
            elseif serviceName == "RemoteService" then
                args = {services["DataService"]}
            elseif serviceName == "LeaderboardService" then
                args = {services["DataService"]}
            end

            -- Call the Init method with the specified dependencies
            local success, err = pcall(service.Init, service, unpack(args))
            if not success then error(string.format("CRITICAL: '%s' failed to init. Error: %s", serviceName, tostring(err))) end
        
        elseif serviceName == "WorldService" and service.Generate then
            print("   -> Generating world via WorldService...")
            service:Generate()
        end
    end
    
    print("✅ [ServiceLoader] All services initialized.")
    ServiceLoader.isReady = true

    local RemoteService = services["RemoteService"]
    if RemoteService then
        RemoteService:SetServerReady()
        print("📣 [ServiceLoader] Broadcasting 'ServerReady' to all clients...")
        for _, player in ipairs(Players:GetPlayers()) do
            RemoteService:SendToClient(player, "ServerReady")
        end

        -- Handle late joiners
        Players.PlayerAdded:Connect(function(player)
            if ServiceLoader.isReady then
                task.wait(1) -- Give client a moment to initialize listeners
                print(string.format("📣 [ServiceLoader] Sending late 'ServerReady' to %s", player.Name))
                RemoteService:SendToClient(player, "ServerReady")
            end
        end)
    end
end

function ServiceLoader:GetService(name)
    return services[name]
end

return ServiceLoader
