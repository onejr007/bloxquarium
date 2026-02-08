--[[
    ServiceLoader.luau (v2.0 - ShopService Injection for Admin)
]]

local ServiceLoader = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ServicesFolder = ServerScriptService:WaitForChild("Services")

local INIT_ORDER = {
    "WorldService",
    "FirebaseService",
    "DatabaseService",
    "DataService",
    "RemoteService",
    "ShopService",
    "PlotService",
    "UnderwaterService",
    "LeaderboardService",
    "GameActions",
    "AdminService" -- AdminService tetap terakhir agar service lain bisa di-inject
}

local services = {}

function ServiceLoader:Init()
    print("🤖 [ServiceLoader] Starting service initialization...")

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

    print("🚀 [ServiceLoader] Initializing services in order...")
    for _, serviceName in ipairs(INIT_ORDER) do
        local service = services[serviceName]
        if not service then continue end

        if service.Init then
            print(string.format("   -> Initializing service: %s", serviceName))
            
            local args = {}
            -- FIX: Logika Dependency Injection diperbarui untuk AdminService
            if serviceName == "AdminService" then
                 args = {services["RemoteService"], services["DataService"], services["ShopService"]} -- Menambahkan ShopService
            elseif serviceName == "ShopService" then
                args = {services["RemoteService"], services["DataService"]}
            elseif serviceName == "DataService" then
                args = {services["FirebaseService"], services["DatabaseService"]}
            elseif serviceName == "PlotService" then
                args = {services["DataService"], services["RemoteService"], services["UnderwaterService"]}
            elseif serviceName == "UnderwaterService" then
                args = {services["DataService"], services["RemoteService"]}
            elseif serviceName == "RemoteService" then
                args = {services["DataService"]}
            elseif serviceName == "LeaderboardService" then
                args = {services["DataService"]}
            elseif serviceName == "GameActions" then
                args = {services["RemoteService"]}
            end

            local success, err = pcall(service.Init, service, unpack(args))
            if not success then error(string.format("CRITICAL: '%s' failed to init. Error: %s", serviceName, tostring(err))) end
        
        elseif serviceName == "WorldService" and service.Generate then
            print("   -> Generating world via WorldService...")
            service:Generate()
        else
            print(string.format("   -> Service '%s' has no Init method. Skipping.", serviceName))
        end
    end
    
    print("✅ [ServiceLoader] All services initialized.")
end

function ServiceLoader:GetService(name)
    return services[name]
end

return ServiceLoader
