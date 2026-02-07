--[[
    GameActions.luau (v2.1 - Updated for AdminService v2)

    Handles server-side logic for remote events.
    Now uses the synchronous version of AdminService.isAdmin.
]]

--=================[ SERVICES ]=================--
local ServerScriptService = game:GetService("ServerScriptService")

--=================[ MODULES ]=================--
local RemoteService = require(ServerScriptService.RemoteService)
local AdminService = require(ServerScriptService.AdminService)

--=================[ CONFIGURATION ]=================--
local GameActions = {}

--///////////////////////////////////////////////////////////////////////////
--// EVENT HANDLERS
--///////////////////////////////////////////////////////////////////////////

local function onRequestAdminCheck(player)
    -- PERBAIKAN: Panggil AdminService.isAdmin secara langsung
    local isAdmin = AdminService.isAdmin(player)
    RemoteService:SendToClient(player, "AdminCheckResponse", isAdmin)
end

local function onKickPlayer(player, targetPlayerName)
    -- Keamanan: Hanya admin yang bisa menjalankan perintah ini
    if not AdminService.isAdmin(player) then
        player:Kick("Anda tidak memiliki izin untuk menggunakan perintah ini.")
        return
    end

    local targetPlayer = game:GetService("Players"):FindFirstChild(targetPlayerName)
    if targetPlayer then
        targetPlayer:Kick(string.format("Anda telah di-kick oleh seorang admin (%s).", player.Name))
    else
        -- Opsional: Beri tahu admin jika pemain tidak ditemukan
        -- RemoteService:SendToClient(player, "Notify", string.format("Pemain '%s' tidak ditemukan.", targetPlayerName))
    end
end

--///////////////////////////////////////////////////////////////////////////
--// INISIALISASI
--///////////////////////////////////////////////////////////////////////////

function GameActions:Init()
    print("🎮 [GameActions] Inisialisasi Tindakan Game...")
    
    RemoteService:Register("RequestAdminCheck", onRequestAdminCheck)
    RemoteService:Register("KickPlayer", onKickPlayer)
    
    print("✅ [GameActions] Tindakan Game berhasil diinisialisasi.")
end

return GameActions
