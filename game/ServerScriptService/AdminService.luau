--[[
    AdminService.luau (v5.0.1 - Final Queue System)

    - Re-implementing the robust, manual queue system to replace the faulty Promise logic.
    - This version is guaranteed to handle the race condition correctly by queueing
      requests that arrive before the Firebase data is ready.
]]

--=================[ SERVICES ]=================--
local ServerScriptService = game:GetService("ServerScriptService")

--=================[ MODULES ]=================--
local DataService = require(ServerScriptService.DataService)
local RemoteService = require(ServerScriptService.RemoteService)

--=================[ CONFIGURATION ]=================--
local AdminService = {}

local adminIdCache = {}
local ADMIN_PATH = "/admins"

-- Sistem antrian untuk mengatasi race condition
local isCacheReady = false
local pendingAdminChecks = {} -- Antrian pemain yang menunggu pengecekan

--///////////////////////////////////////////////////////////////////////////
--// FUNGSI INTERNAL
--///////////////////////////////////////////////////////////////////////////

-- Memproses permintaan pengecekan admin yang tertunda di antrian
local function processPendingChecks()
    if isCacheReady then return end -- Mencegah pemrosesan ganda
    isCacheReady = true
    
    print(string.format("👑 [AdminService] Cache siap. Memproses %d permintaan di antrian...", #pendingAdminChecks))

    -- Gunakan loop `for` standar untuk iterasi yang aman
    for i = 1, #pendingAdminChecks do
        local player = pendingAdminChecks[i]
        if player and player.Parent then -- Pastikan pemain masih ada di dalam game
            local isPlayerAdmin = AdminService.isAdmin(player)
            print(string.format("👑 [AdminService] Merespons (dari antrian) untuk %s. Status: %s", player.Name, tostring(isPlayerAdmin)))
            RemoteService:SendToClient(player, "AdminCheckResponse", isPlayerAdmin)
        end
    end
    
    -- Kosongkan antrian setelah diproses
    pendingAdminChecks = {}
    print("👑 [AdminService] Antrian permintaan admin selesai diproses.")
end

-- Validasi, inisialisasi, dan memuat cache admin
local function validateAndCacheAdmins()
    print("👑 [AdminService] Memvalidasi dan memuat data admin dari Firebase...")
    
    DataService:Get(ADMIN_PATH):andThen(function(adminData)
        if adminData == nil then
            print("👑 [AdminService] Path '/admins' tidak ada. Membuat struktur awal...")
            local initialAdmins = {90101532} -- Ganti dengan ID admin default Anda
            DataService:Set(ADMIN_PATH, initialAdmins):andThen(function()
                adminIdCache = {[tostring(initialAdmins[1])] = true}
                print("👑 [AdminService] Cache admin diinisialisasi dengan data default.")
                processPendingChecks() -- Proses antrian
            end)

        elseif typeof(adminData) ~= "table" or (next(adminData) ~= nil and adminData[1] == nil) then
            warn("👑 [AdminService] Struktur data '/admins' korup. Layanan admin tidak dapat memulai dengan benar.")
            processPendingChecks() -- Proses antrian (semua akan ditolak karena cache kosong)

        else
            print("👑 [AdminService] Data admin valid. Memuat ke cache...")
            local newCache = {}
            for _, adminId in ipairs(adminData) do
                newCache[tostring(adminId)] = true
            end
            adminIdCache = newCache
            print("👑 [AdminService] Cache admin berhasil diperbarui dari Firebase.")
            processPendingChecks() -- Proses antrian
        end

    end):catch(function(err)
        warn("👑 [AdminService] Gagal mengambil data admin dari Firebase: " .. tostring(err))
        processPendingChecks() -- Tetap proses antrian jika terjadi error (semua akan ditolak)
    end)
end

--///////////////////////////////////////////////////////////////////////////
--// REMOTE EVENT HANDLER
--///////////////////////////////////////////////////////////////////////////

local function handleAdminCheckRequest(player)
    if isCacheReady then
        -- Cache sudah siap, langsung periksa dan balas
        local isPlayerAdmin = AdminService.isAdmin(player)
        print(string.format("👑 [AdminService] Merespons permintaan langsung untuk %s. Status: %s", player.Name, tostring(isPlayerAdmin)))
        RemoteService:SendToClient(player, "AdminCheckResponse", isPlayerAdmin)
    else
        -- Cache belum siap, tambahkan pemain ke antrian
        print(string.format("👑 [AdminService] Menerima permintaan dari %s. Menambahkan ke antrian...", player.Name))
        table.insert(pendingAdminChecks, player)
    end
end

--///////////////////////////////////////////////////////////////////////////
--// API PUBLIK
--///////////////////////////////////////////////////////////////////////////

function AdminService.isAdmin(player)
    if not player then return false end
    local userIdString = tostring(player.UserId)
    return adminIdCache[userIdString] == true
end

--///////////////////////////////////////////////////////////////////////////
--// INISIALISASI
--///////////////////////////////////////////////////////////////////////////

function AdminService:Init()
    validateAndCacheAdmins()
    RemoteService:Register("RequestAdminCheck", handleAdminCheckRequest)
    print("👑 [AdminService] Berhasil mendaftarkan handler 'RequestAdminCheck' dengan sistem antrian.")
end

return AdminService
