--[[
    GameActions.luau

    Modul ini adalah "gatekeeper" untuk semua tindakan yang dipicu oleh klien.
    Setiap fungsi di sini HARUS melakukan validasi server-side yang ketat
    sebelum memodifikasi data pemain.
]]

--=================[ SERVICES ]=================--
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--=================[ MODULES ]=================--
local DataService = require(ServerScriptService:WaitForChild("DataService"))
local Promise = require(ReplicatedStorage.Shared.Promise)

--=================[ CONFIGURATION ]=================--
local GameActions = {}

local itemPrices = {
    ["FishFood"] = 50,
    ["TreasureChest"] = 200,
    ["Goldfish"] = 100
}

--///////////////////////////////////////////////////////////////////////////
--// API PUBLIK (Fungsi yang akan dipanggil oleh Klien)
--///////////////////////////////////////////////////////////////////////////

function GameActions:BuyItem(player, itemId)
    return Promise.new(function(resolve, reject)
        local itemCost = itemPrices[itemId]
        if not itemCost then
            return reject(string.format("Item tidak valid: %s", tostring(itemId)))
        end

        local currentData = DataService:GetSessionData(player) 
        if not currentData then
            return reject("Data pemain tidak ditemukan di sesi.")
        end

        if currentData.coins < itemCost then
            return reject(string.format("Koin tidak cukup. Butuh: %d, Punya: %d", itemCost, currentData.coins))
        end

        -- NEW (v5.1): Gunakan DataService:SetState untuk memodifikasi data
        local newCoinAmount = currentData.coins - itemCost
        DataService:SetState(player, "coins", newCoinAmount)

        -- Tambahkan item ke inventaris (ini aman untuk dimodifikasi secara langsung
        -- karena tidak ada UI lain yang bergantung padanya saat ini)
        if not currentData.inventory then currentData.inventory = {} end
        table.insert(currentData.inventory, itemId)

        -- Data sekarang disimpan secara otomatis oleh autosave DataService,
        -- jadi kita tidak perlu memanggil SaveToDataStore di sini.
        print(string.format("✅ [GameActions] Pemain %s berhasil membeli %s", player.Name, itemId))
        resolve(DataService:GetSessionData(player)) -- Mengirim data terbaru kembali ke klien
    end)
end

return GameActions
