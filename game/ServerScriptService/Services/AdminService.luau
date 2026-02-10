--[[
    AdminService.luau (v7.0 - Centralized Actions)
    - All remote event registrations have been REMOVED.
    - Public functions are now exposed to be called by GameActions.
    - This centralizes control and improves modularity.
]]

local Players = game:GetService("Players")

--=================[ SERVICES ]=================--
local InjectedDataService
local InjectedShopService

--=================[ CONFIGURATION ]=================--
local AdminService = {}

local adminIdCache = {} -- {[userIdString] = true}
local ADMIN_PATH = "/admins"
local isReady = false
local readyEvent = Instance.new("BindableEvent")

--///////////////////////////////////////////////////////////////////////////
--// INTERNAL FUNCTIONS
--///////////////////////////////////////////////////////////////////////////

local function saveAdminsToDatabase()
    local adminsArray = {}
    for userIdString, _ in pairs(adminIdCache) do
        table.insert(adminsArray, tonumber(userIdString))
    end
    
    InjectedDataService:Set(ADMIN_PATH, adminsArray):catch(function(err)
        warn("👑 [AdminService] Gagal menyimpan data admin ke Firebase: " .. tostring(err))
    end)
end

--///////////////////////////////////////////////////////////////////////////
--// PUBLIC API
--///////////////////////////////////////////////////////////////////////////

function AdminService.isAdmin(player)
    if not player then return false end
    if not isReady then
        print("👑 [AdminService] isAdmin check yielding for ready status...")
        readyEvent.Event:Wait()
    end
    local isAdm = adminIdCache[tostring(player.UserId)] == true
    print(string.format("👑 [AdminService] Checking admin for %s (%s): %s", player.Name, tostring(player.UserId), tostring(isAdm)))
    return isAdm
end

function AdminService.GetAdminList(player)
    if not isReady then readyEvent.Event:Wait() end
    if not AdminService.isAdmin(player) then return {} end

    local adminList = {}
    for userIdString, _ in pairs(adminIdCache) do
        local userId = tonumber(userIdString)
        local adminPlayer = Players:GetPlayerByUserId(userId)
        table.insert(adminList, {
            userId = userId,
            name = adminPlayer and adminPlayer.Name or "[OFFLINE]"
        })
    end
    return adminList
end

function AdminService.AddAdmin(player, targetIdentifier)
    if not isReady then readyEvent.Event:Wait() end
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end

    local targetUserId = tonumber(targetIdentifier)
    
    if not targetUserId then
        local success, id = pcall(function()
            return Players:GetUserIdFromNameAsync(targetIdentifier)
        end)
        if success then
            targetUserId = id
        else
            return false, "Pemain tidak ditemukan di database Roblox."
        end
    end

    if adminIdCache[tostring(targetUserId)] then
        return false, "Pemain sudah menjadi admin."
    end
    
    adminIdCache[tostring(targetUserId)] = true
    saveAdminsToDatabase()
    return true, "Admin berhasil ditambahkan!"
end

function AdminService.RemoveAdmin(player, targetUserId)
    if not isReady then readyEvent.Event:Wait() end
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    
    targetUserId = tonumber(targetUserId)
    if not targetUserId then return false, "UserID tidak valid." end

    if not adminIdCache[tostring(targetUserId)] then
        return false, "Pemain bukan admin."
    end

    adminIdCache[tostring(targetUserId)] = nil
    saveAdminsToDatabase()
    return true, "Admin berhasil dihapus!"
end

function AdminService.GetShopAdminData(player)
    if not isReady then readyEvent.Event:Wait() end
    if not AdminService.isAdmin(player) then return nil, "Unauthorized" end
    
    if InjectedShopService then
        local shop = InjectedShopService:GetCachedShopData()
        local chance = InjectedShopService:GetChanceData():await()
        local items = InjectedShopService:GetItemsData():await()
        return {
            shop = shop,
            chance = chance,
            items = items
        }
    end
    return nil
end

--///////////////////////////////////////////////////////////////////////////
--// INITIALIZATION
--///////////////////////////////////////////////////////////////////////////

function AdminService:Init(DataService, ShopService)
    InjectedDataService = DataService
    InjectedShopService = ShopService
    
    if not InjectedDataService or not InjectedShopService then
        warn("🔥 [AdminService] Service yang diperlukan tidak ditemukan!")
        return
    end
    
    local function onComplete()
        isReady = true
        readyEvent:Fire()
    end

    -- Sync with Firebase on startup
    InjectedDataService:Get(ADMIN_PATH):andThen(function(adminData)
        print("👑 [AdminService] Raw admin data from DB:", adminData)
        if adminData == nil or (typeof(adminData) == "table" and next(adminData) == nil) then 
            warn("👑 [AdminService] PERINGATAN: Tidak ada data admin yang ditemukan di database.")
            adminIdCache = {}
            onComplete()
        elseif typeof(adminData) == "table" then
            local newCache = {}
            local count = 0
            for _, adminId in ipairs(adminData) do
                if typeof(adminId) == "number" then
                    newCache[tostring(adminId)] = true
                    count = count + 1
                end
            end
            adminIdCache = newCache
            print(string.format("👑 [AdminService] Berhasil memuat %d admin ke cache.", count))
            onComplete()
        else
            warn("👑 [AdminService] Data admin di database tidak valid (bukan tabel).")
            onComplete()
        end
    end):catch(function(err)
        warn("👑 [AdminService] Gagal mengambil data Firebase: " .. tostring(err))
        onComplete()
    end)
    
    print("👑 [AdminService] Berhasil menginisialisasi Manajemen Admin.")
end

return AdminService