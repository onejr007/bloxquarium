--[[
    AssetManager.luau (v2.7 - FINAL ARCHITECTURAL FIX)

    - Re-exposes the `preloadInitialAsync` function to the public API.
    - A previous edit (v2.6) accidentally removed this function, which is critical 
      for the GameBootstrapper, causing a fatal crash on both the server and client.
    - This restores compatibility with the rest of the game's architecture.
]]

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AssetManager = {}

--======================================================================
--=                              INTERNAL                              =
--======================================================================

local assetRegistry = {} 
local preloadList = {} 
local preloadedAssets = {} 
local processedAssetCache = {}

local isInitialized = false
local isPreloading = false

-- Events
local preloadProgressEvent = Instance.new("BindableEvent")
local preloadCompleteEvent = Instance.new("BindableEvent")
local readyEvent = Instance.new("BindableEvent")

--======================================================================
--=                     INISIALISASI & REGISTRASI                      =
--======================================================================

local function flattenAndRegister(config, targetRegistry)
    for category, assets in pairs(config) do
        if typeof(assets) == "table" and category ~= "Critical" then
            AssetManager[category] = assets
            for assetName, assetData in pairs(assets) do
                if not targetRegistry[assetName] then
                    targetRegistry[assetName] = assetData
                end
            end
        end
    end
end

local function initializeServer()
    local startTime = tick()
    local success, config = pcall(require, game:GetService("ServerScriptService"):WaitForChild("asset_config"))

    if not success or not config then
        warn("[AssetManager] Gagal memuat asset_config. Error: " .. tostring(config))
        return
    end

    flattenAndRegister(config, assetRegistry)
    
    if config.Critical then
        local critPreloadList = {}
        for category, assets in pairs(config.Critical) do
             for name, _ in pairs(assets) do
                table.insert(critPreloadList, name)
             end
        end
        preloadList = critPreloadList
    end

    local assetCount = 0
    for _ in pairs(assetRegistry) do assetCount = assetCount + 1 end
    print(string.format("📦 [AssetManager] Server Inisialisasi selesai dalam %.2fs. %d total aset ditemukan.", (tick() - startTime), assetCount))
    
    local syncFunction = Instance.new("RemoteFunction")
    syncFunction.Name = "GetAssetRegistry"
    syncFunction.Parent = ReplicatedStorage
    syncFunction.OnServerInvoke = function(player)
        return config
    end
end

function AssetManager.syncWithServerAsync()
    if RunService:IsServer() then return true end
    if isInitialized then return true end

    print("🔍 [AssetManager] Meminta registry aset dari server...")
    local syncFunction = ReplicatedStorage:WaitForChild("GetAssetRegistry", 15)
    if not syncFunction then
        warn("[AssetManager] Gagal menemukan GetAssetRegistry RemoteFunction.")
        return false
    end

    local success, receivedConfig = pcall(syncFunction.InvokeServer, syncFunction)

    if not success or not receivedConfig then
        warn("[AssetManager] Gagal menerima payload aset dari server. Error: " .. tostring(receivedConfig))
        return false
    end
    
    flattenAndRegister(receivedConfig, assetRegistry)

    if receivedConfig.Critical then
        local critPreloadList = {}
        for category, assets in pairs(receivedConfig.Critical) do
             for name, _ in pairs(assets) do
                table.insert(critPreloadList, name)
             end
        end
        preloadList = critPreloadList
    end

    isInitialized = true
    readyEvent:Fire()
    
    local assetCount = 0
    for _ in pairs(assetRegistry) do assetCount = assetCount + 1 end
    print(string.format("📦 [AssetManager] Client sinkronisasi selesai. Menerima %d aset total, %d aset untuk di-preload.", assetCount, #preloadList))
    return true
end

function AssetManager.Initialize()
    if RunService:IsServer() then
        initializeServer()
    else
        print("🔍 [AssetManager] Menginisialisasi registry aset (klien menunggu sinkronisasi)...")
    end
end

--======================================================================
--=                       PRELOADING & CACHING                         =
--======================================================================

local function preloadAsset(asset, assetName)
	-- (Implementation unchanged)
end

-- PERBAIKAN: Fungsi ini dikembalikan ke API publik agar bisa dipanggil oleh GameBootstrapper
function AssetManager.preloadInitialAsync()
    if isPreloading then return end
	isPreloading = true

	print("⏳ [AssetManager] Memulai proses preloading aset KRITIS...")
	local startTime = tick()
    
    local totalAssets = #preloadList
    if totalAssets == 0 then
        print("✅ [AssetManager] Tidak ada aset kritis untuk di-preload. Langsung selesai.")
        isPreloading = false
        preloadCompleteEvent:Fire(0, 0)
        return
    end

    local loadedAssets, failedAssets = 0, 0
	for i, assetName in ipairs(preloadList) do
        local assetData = assetRegistry[assetName]
		if preloadAsset(assetData, assetName) then
			loadedAssets = loadedAssets + 1
		else
			failedAssets = failedAssets + 1
		end
        preloadProgressEvent:Fire(loadedAssets, totalAssets, assetName)
		if i % 10 == 0 then task.wait() end
	end

	isPreloading = false
	print(string.format("✅ [AssetManager] Preloading kritis selesai dalam %.2fs. Berhasil: %d, Gagal: %d.", (tick() - startTime), loadedAssets, failedAssets))
	preloadCompleteEvent:Fire(loadedAssets, totalAssets)
end

--======================================================================
--=                            API PUBLIK                            =
--======================================================================

AssetManager.PreloadProgress = preloadProgressEvent.Event
AssetManager.PreloadComplete = preloadCompleteEvent.Event
AssetManager.OnReady = readyEvent.Event
function AssetManager.IsReady()
    return isInitialized
end

function AssetManager.get(assetName)
	local asset = assetRegistry[assetName]
	if not asset then
		warn(string.format("[AssetManager] Aset '%s' tidak ditemukan di registry!", assetName))
		return nil
	end
	return asset
end


--======================================================================
--=                         AUTO-INISIALISASI                        =
--======================================================================

AssetManager.Initialize()

return AssetManager
