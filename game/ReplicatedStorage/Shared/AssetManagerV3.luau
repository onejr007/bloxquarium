--[[
    AssetManager.luau (v3.2 - FINAL STRUCTURE FIX)

    - CRITICAL FIX (1/2): The `flattenAndRegister` function now correctly ignores the `CriticalAssetNames` table,
      preventing the asset registry from being corrupted during synchronization.
    - CRITICAL FIX (2/2): The `syncWithServerAsync` function has been updated to read the `CriticalAssetNames` table
      (instead of the old `Critical` table) to correctly identify which assets to preload.
	- This is the definitive fix that aligns the client's logic with the server's data structure.
]]--

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Promise)
local RemoteClient = require(script.Parent.RemoteClient)

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

-- FIXED: Now correctly ignores the `CriticalAssetNames` list.
local function flattenAndRegister(config, targetRegistry)
    for category, assets in pairs(config) do
        if typeof(assets) == "table" and category ~= "CriticalAssetNames" then
            AssetManager[category] = assets
            for assetName, assetData in pairs(assets) do
                if not targetRegistry[assetName] then
                    targetRegistry[assetName] = assetData
                end
            end
        end
    end
end

function AssetManager.syncWithServerAsync()
    if RunService:IsServer() then return true end
    if isInitialized then return true end

    print("🔍 [AssetManager v3.2] Meminta registry aset dari server melalui RemoteClient...")
    
    return Promise.new(function(resolve, reject)
        RemoteClient:InvokeServer("GetAssetRegistry"):andThen(function(receivedConfig)
            if not receivedConfig then
                warn("[AssetManager v3.2] Gagal menerima payload aset dari server.")
                reject("Payload was nil")
                return
            end

            flattenAndRegister(receivedConfig, assetRegistry)

            -- FIXED: Reads the new `CriticalAssetNames` table to build the preload list.
            if receivedConfig.CriticalAssetNames then
                preloadList = receivedConfig.CriticalAssetNames
            end

            isInitialized = true
            readyEvent:Fire()
            
            local assetCount = 0
            for _ in pairs(assetRegistry) do assetCount = assetCount + 1 end
            print(string.format("📦 [AssetManager v3.2] Client sinkronisasi selesai. Menerima %d aset total.", assetCount))
            resolve(true)
        
        end, function(err)
            warn("[AssetManager v3.2] Panggilan InvokeServer gagal: " .. tostring(err))
            reject(err)
        end)
    end)
end


function AssetManager.Initialize()
    if not RunService:IsServer() then
        print("🔍 [AssetManager v3.2] Menginisialisasi registry aset (klien menunggu sinkronisasi)...")
    end
end

--======================================================================
--=                       PRELOADING & CACHING                         =
--======================================================================

local function preloadAsset(asset, assetName)
    local id = type(asset) == 'table' and asset.id or asset
    if not (id and type(id) == 'string' and id:match("rbxassetid")) then
        warn(string.format("    -> ⚠️ Aset '%s' tidak memiliki ID yang valid untuk preloading.", assetName))
        return false
    end

    local success, message = pcall(function() 
        ContentProvider:PreloadAsync({id})
    end)

    if success then
        preloadedAssets[assetName] = true
    else
        warn(string.format("    -> ❌ Kegagalan preloading untuk %s (%s): %s", assetName, id, message))
    end
    return success
end

function AssetManager.preloadInitialAsync()
    if isPreloading then return end
	isPreloading = true

	print("⏳ [AssetManager v3.2] Memulai proses preloading aset KRITIS...")
	local startTime = tick()
    
    local totalAssets = #preloadList
    if totalAssets == 0 then
        print("✅ [AssetManager v3.2] Tidak ada aset kritis untuk di-preload. Langsung selesai.")
        isPreloading = false
        preloadCompleteEvent:Fire(0, 0)
        return
    end

    local loadedAssets, failedAssets = 0, 0
	for i, assetName in ipairs(preloadList) do
        local assetData = assetRegistry[assetName]
        if not assetData then
            warn(string.format("    -> ⚠️ Tidak dapat melakukan preload: aset '%s' tidak ditemukan di registry.", assetName))
            failedAssets = failedAssets + 1
        elseif preloadAsset(assetData, assetName) then
			loadedAssets = loadedAssets + 1
		else
			failedAssets = failedAssets + 1
		end
        preloadProgressEvent:Fire(loadedAssets, totalAssets, assetName)
		if i % 10 == 0 then task.wait() end
	end

	isPreloading = false
	print(string.format("✅ [AssetManager v3.2] Preloading kritis selesai dalam %.2fs. Berhasil: %d, Gagal: %d.", (tick() - startTime), loadedAssets, failedAssets))
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
		warn(string.format("[AssetManager v3.2] Aset '%s' tidak ditemukan di registry!", assetName))
		return nil
	end
	return asset
end


--======================================================================
--=                         AUTO-INISIALISASI                        =
--======================================================================

AssetManager.Initialize()

return AssetManager