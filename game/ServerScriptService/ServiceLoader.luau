--[[
    ServiceLoader.luau (v1.3 - Final DI Fix)

    - Correctly injects DataService into RemoteService.
    - The initialization order has been perfected to prevent race conditions.
]]

local ServiceLoader = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ServicesFolder = ServerScriptService:WaitForChild("Services")

-- Define the specific order of initialization. This is crucial for managing dependencies.
local INIT_ORDER = {
    -- Level 0: Core libraries, no dependencies
    "WorldService",
    "FirebaseService",
    "DatabaseService",
    
    -- Level 1: Services that depend on Level 0
    "DataService",          -- Depends on FirebaseService, DatabaseService
    
    -- Level 2: Services that depend on Level 1. RemoteService is now here.
    "RemoteService",        -- Depends on DataService
    "LeaderboardService",   -- Depends on DataService

    -- Level 3: Services that depend on Level 2
    "GameActions",          -- Depends on RemoteService
    "AdminService"          -- Depends on RemoteService, DataService
}

local services = {}

function ServiceLoader:Init()
    print("🤖 [ServiceLoader] Starting service initialization...")

    -- First, require all service modules so they are available in memory.
    for _, serviceName in ipairs(INIT_ORDER) do
        local serviceModule = ServicesFolder:FindFirstChild(serviceName)
        if serviceModule and serviceModule:IsA("ModuleScript") then
            print(string.format("   -> Requiring service: %s", serviceName))
            local success, result = pcall(require, serviceModule)
            if success then
                services[serviceName] = result
            else
                error(string.format("CRITICAL: Module '%s' failed to be required. Error: %s", serviceName, tostring(result)))
            end
        else
            -- It's possible for services to be temporarily removed, so a warning is appropriate.
            warn(string.format("   -> Service module not found in Services folder: %s", serviceName))
        end
    end

    -- Second, initialize them in order, injecting dependencies as needed.
    print("🚀 [ServiceLoader] Initializing services in order...")
    for _, serviceName in ipairs(INIT_ORDER) do
        local service = services[serviceName]
        if not service then continue end

        if service.Init then
            print(string.format("   -> Initializing service: %s", serviceName))
            
            local args = {}
            if serviceName == "DataService" then
                args = {services["FirebaseService"], services["DatabaseService"]}
            elseif serviceName == "RemoteService" then -- FIXED
                args = {services["DataService"]}
            elseif serviceName == "LeaderboardService" then
                args = {services["DataService"]}
            elseif serviceName == "GameActions" then
                args = {services["RemoteService"]}
            elseif serviceName == "AdminService" then
                 args = {services["RemoteService"], services["DataService"]}
            end

            local success, err = pcall(service.Init, service, unpack(args))
            if not success then
                error(string.format("CRITICAL: Service '%s' failed to initialize. Error: %s", serviceName, tostring(err)))
            end
        
        elseif serviceName == "WorldService" and service.Generate then
            print("   -> Generating world via WorldService...")
            service:Generate()

        else
            print(string.format("   -> Service '%s' loaded but has no Init method. Skipping initialization.", serviceName))
        end
    end
    
    print("✅ [ServiceLoader] All services initialized.")
end

function ServiceLoader:GetService(name)
    return services[name]
end

return ServiceLoader
