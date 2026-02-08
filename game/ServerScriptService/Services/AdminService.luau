--[[
    AdminService.luau (v6.1 - Shop Data Integration)
    - Integrasi penuh dengan Firebase via Injected DataService.
    - Sistem Antrean (Queue) untuk menangani pengecekan admin sebelum cache siap.
    - Penanganan penambahan admin via Name (Offline/Online) atau UserID.
    - Zero Hardcoded Requires (Dependency Injection via :Init).
    - NEW: Menambahkan endpoint "GetShopData" untuk GUI Admin.
]]

local Players = game:GetService("Players")

--=================[ SERVICES ]=================--
local InjectedRemoteService
local InjectedDataService
local InjectedShopService -- FIX: Menambahkan ShopService

--=================[ CONFIGURATION ]=================--
local AdminService = {}

local adminIdCache = {} -- {[userIdString] = true}
local ADMIN_PATH = "/admins"

local isCacheReady = false
local pendingAdminChecks = {} -- Antrean pemain yang menunggu validasi

--///////////////////////////////////////////////////////////////////////////
--// INTERNAL FUNCTIONS
--///////////////////////////////////////////////////////////////////////////

-- Menyimpan cache saat ini kembali ke Firebase
local function saveAdminsToDatabase()
    local adminsArray = {}
    for userIdString, _ in pairs(adminIdCache) do
        table.insert(adminsArray, tonumber(userIdString))
    end
    
    InjectedDataService:Set(ADMIN_PATH, adminsArray):catch(function(err)
        warn("👑 [AdminService] Gagal menyimpan data admin ke Firebase: " .. tostring(err))
    end)
end

-- Memproses pemain yang tertahan di antrean saat cache sudah siap
local function processPendingChecks()
    if isCacheReady then return end
    isCacheReady = true
    
    print(string.format("👑 [AdminService] Cache siap. Memproses %d antrean permintaan...", #pendingAdminChecks))

    for _, player in ipairs(pendingAdminChecks) do
        if player and player.Parent then
            local isPlayerAdmin = AdminService.isAdmin(player)
            if InjectedRemoteService then
                InjectedRemoteService:SendToClient(player, "AdminCheckResponse", isPlayerAdmin)
            end
        end
    end
    
    pendingAdminChecks = {}
    print("👑 [AdminService] Pemrosesan antrean selesai.")
end

-- Mengambil data dari Firebase dan memasukkannya ke cache lokal
local function validateAndCacheAdmins()
    print("👑 [AdminService] Sinkronisasi data admin dari Firebase...")
    
    InjectedDataService:Get(ADMIN_PATH):andThen(function(adminData)
        -- Jika path kosong, buat admin default (ID Anda/Owner)
        if adminData == nil or (typeof(adminData) == "table" and next(adminData) == nil) then 
            local initialAdmins = {90101532} -- ID Default
            InjectedDataService:Set(ADMIN_PATH, initialAdmins):andThen(function()
                adminIdCache = {[tostring(initialAdmins[1])] = true}
                processPendingChecks()
            end)
        elseif typeof(adminData) == "table" then
            local newCache = {}
            for _, adminId in ipairs(adminData) do
                if typeof(adminId) == "number" then
                    newCache[tostring(adminId)] = true
                end
            end
            adminIdCache = newCache
            processPendingChecks()
        else
            warn("👑 [AdminService] Struktur data di '/admins' tidak valid.")
            processPendingChecks() 
        end
    end):catch(function(err)
        warn("👑 [AdminService] Gagal mengambil data Firebase: " .. tostring(err))
        processPendingChecks() -- Tetap proses antrean agar UI pemain tidak stuck
    end)
end

--///////////////////////////////////////////////////////////////////////////
--// REMOTE EVENT HANDLERS
--///////////////////////////////////////////////////////////////////////////

-- Menangani permintaan pengecekan admin dari Client
local function handleRequestAdminCheck(player)
    if isCacheReady then
        local isPlayerAdmin = AdminService.isAdmin(player)
        if InjectedRemoteService then
            InjectedRemoteService:SendToClient(player, "AdminCheckResponse", isPlayerAdmin)
        end
    else
        -- Masukkan ke antrean jika data Firebase belum turun
        table.insert(pendingAdminChecks, player)
    end
end

-- Mengirim daftar admin ke UI Settings (Hanya jika pengirim adalah admin)
local function handleRequestAdminList(player)
    if not AdminService.isAdmin(player) then return {} end

    local adminList = {}
    for userIdString, _ in pairs(adminIdCache) do
        local userId = tonumber(userIdString)
        -- Coba cari nama pemain secara lokal, jika tidak ada tandai offline
        local adminPlayer = Players:GetPlayerByUserId(userId)
        table.insert(adminList, {
            userId = userId,
            name = adminPlayer and adminPlayer.Name or "[OFFLINE]"
        })
    end
    return adminList
end

-- Menambah admin baru berdasarkan Name atau UserID
local function handleAddAdmin(player, targetIdentifier)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end

    local targetUserId = tonumber(targetIdentifier)
    
    -- Jika input bukan angka (UserID), cari UserID berdasarkan nama
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

-- Menghapus admin
local function handleRemoveAdmin(player, targetUserId)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    
    targetUserId = tonumber(targetUserId)
    if not targetUserId then return false, "UserID tidak valid." end

    if not adminIdCache[tostring(targetUserId)] then
        return false, "Pemain bukan admin."
    end

    -- Mencegah owner menghapus dirinya sendiri (Opsional, tapi disarankan)
    -- if targetUserId == player.UserId then return false, "Tidak bisa menghapus diri sendiri." end

    adminIdCache[tostring(targetUserId)] = nil
    saveAdminsToDatabase()
    return true, "Admin berhasil dihapus!"
end

-- FIX: Handler baru untuk mendapatkan data toko dan probabilitas
local function handleGetShopAdminData(player)
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

local function handleUpdateItemData(player, category, itemId, data)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    if InjectedShopService then
        InjectedShopService:UpdateItemData(category, itemId, data)
        return true
    end
    return false
end

local function handleAddItemData(player, category, itemId, data)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    if InjectedShopService then
        InjectedShopService:AddItemData(category, itemId, data)
        return true
    end
    return false
end

local function handleUpdateShopStock(player, itemId, stock)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    if InjectedShopService then
        InjectedShopService:UpdateShopStock(itemId, stock)
        return true
    end
    return false
end

local function handleResetShopCooldown(player)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    if InjectedShopService then
        InjectedShopService:ForceRegenerateShop()
        return true
    end
    return false
end

local function handleAddItemToShop(player, itemId, stock)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    if InjectedShopService then
        InjectedShopService:AddItemToShop(itemId, stock)
        return true
    end
    return false
end

local function handleUpdateChanceData(player, itemId, data)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    if InjectedShopService then
        InjectedShopService:UpdateChanceData(itemId, data)
        return true
    end
    return false
end

local function handleAddItemToChance(player, itemId, data)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    if InjectedShopService then
        InjectedShopService:AddItemToChance(itemId, data)
        return true
    end
    return false
end

local function handleDeleteItemData(player, category, itemId)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    if InjectedShopService then
        InjectedShopService:DeleteItemData(category, itemId)
        return true
    end
    return false
end

local function handleRemoveItemFromChance(player, itemId)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    if InjectedShopService then
        InjectedShopService:RemoveItemFromChance(itemId)
        return true
    end
    return false
end

local function handleRemoveItemFromShop(player, itemId)
    if not AdminService.isAdmin(player) then return false, "Unauthorized" end
    if InjectedShopService then
        InjectedShopService:RemoveItemFromShop(itemId)
        return true
    end
    return false
end

--///////////////////////////////////////////////////////////////////////////
--// PUBLIC API
--///////////////////////////////////////////////////////////////////////////

function AdminService.isAdmin(player)
    if not player then return false end
    return adminIdCache[tostring(player.UserId)] == true
end

--///////////////////////////////////////////////////////////////////////////
--// INITIALIZATION
--///////////////////////////////////////////////////////////////////////////

function AdminService:Init(RemoteService, DataService, ShopService) -- FIX: Menerima ShopService
    InjectedRemoteService = RemoteService
    InjectedDataService = DataService
    InjectedShopService = ShopService -- FIX: Menyimpan referensi ShopService
    
    if not InjectedRemoteService or not InjectedDataService or not InjectedShopService then
        warn("🔥 [AdminService] Service yang diperlukan tidak ditemukan!")
        return
    end
    
    -- Mulai sinkronisasi Firebase
    validateAndCacheAdmins()
    
    -- Registrasi Handlers ke RemoteService
    InjectedRemoteService:Register("RequestAdminCheck", handleRequestAdminCheck)
    InjectedRemoteService:RegisterInvoke("RequestAdminList", handleRequestAdminList)
    InjectedRemoteService:RegisterInvoke("AddAdmin", handleAddAdmin)
    InjectedRemoteService:RegisterInvoke("RemoveAdmin", handleRemoveAdmin)
    InjectedRemoteService:RegisterInvoke("GetShopAdminData", handleGetShopAdminData)
    InjectedRemoteService:RegisterInvoke("UpdateShopStock", handleUpdateShopStock)
    InjectedRemoteService:RegisterInvoke("ResetShopCooldown", handleResetShopCooldown)
    InjectedRemoteService:RegisterInvoke("AddItemToShop", handleAddItemToShop)
    InjectedRemoteService:RegisterInvoke("UpdateChanceData", handleUpdateChanceData)
    InjectedRemoteService:RegisterInvoke("AddItemToChance", handleAddItemToChance)
    InjectedRemoteService:RegisterInvoke("UpdateItemData", handleUpdateItemData)
    InjectedRemoteService:RegisterInvoke("AddItemData", handleAddItemData)
    InjectedRemoteService:RegisterInvoke("DeleteItemData", handleDeleteItemData)
    InjectedRemoteService:RegisterInvoke("RemoveItemFromChance", handleRemoveItemFromChance)
    InjectedRemoteService:RegisterInvoke("RemoveItemFromShop", handleRemoveItemFromShop)
    
    print("👑 [AdminService] Berhasil menginisialisasi Manajemen Admin.")
end

return AdminService