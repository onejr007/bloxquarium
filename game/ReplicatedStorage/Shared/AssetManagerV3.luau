--[[
    AssetManager.luau (v4.0 - Multi-Phase Loading)

    - MAJOR REWRITE: This version introduces a structured, multi-phase preloading system.
    - It now depends on a `loading_config` file from the server to define loading phases.
    - `syncWithServerAsync`: Now expects a dictionary containing `AssetConfig` and `LoadingConfig`.
    - `preloadInitialAsync`: Completely rewritten. It now iterates through the defined `LoadingPhases`,
      firing a new `PhaseChanged` event before starting each phase.
    - This provides a much more robust and informative loading experience.
]]--
--!strict

local ContentProvider = game:GetService("ContentProvider")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Promise)
local RemoteClient = require(script.Parent.RemoteClient)

local AssetManager = {}

--======================================================================
--=                              INTERNAL                              =
--======================================================================

local assetRegistry = {} 
local loadingPhases = {} -- New: To store loading phases
local preloadedAssets = {} 
local serverIsReady = false -- New: Track if server is ready during sync

local isInitialized = false
local isPreloading = false

-- Events
local phaseChangedEvent = Instance.new("BindableEvent") -- New: For phase changes
local preloadProgressEvent = Instance.new("BindableEvent")
local preloadCompleteEvent = Instance.new("BindableEvent")
local readyEvent = Instance.new("BindableEvent")

--======================================================================
--=                     INISIALISASI & REGISTRASI                      =
--======================================================================

-- Unchanged: Still flattens the asset config into the registry.
local function flattenAndRegister(config, targetRegistry)
    for category, assets in pairs(config) do
        if typeof(assets) == "table" and category ~= "CriticalAssetNames" then
            (AssetManager :: any)[category] = assets
            for assetName, assetData in pairs(assets) do
                if not targetRegistry[assetName] then
                    targetRegistry[assetName] = assetData
                end
            end
        end
    end
end

-- MODIFIED: Now handles the new config structure with retry logic for race conditions.
function AssetManager.syncWithServerAsync()
    if RunService:IsServer() then return Promise.resolve(true) end
    if isInitialized then return Promise.resolve(true) end

    print("🔍 [AssetManager v4.0] Meminta registry aset & fase pemuatan dari server...")
    
    local maxRetries = 5
    local function attemptSync(attempt: number)
        return Promise.new(function(resolve, reject)
            RemoteClient:InvokeServer("GetAssetRegistry"):andThen(function(receivedPayload: any)
                if not receivedPayload or not receivedPayload.AssetConfig or not receivedPayload.LoadingConfig then
                    if attempt < maxRetries then
                        warn(string.format("[AssetManager v4.0] Payload tidak valid (percobaan %d/%d), mencoba lagi dalam 1 detik...", attempt, maxRetries))
                        task.wait(1)
                        attemptSync(attempt + 1):andThen(resolve, reject)
                    else
                        warn("[AssetManager v4.0] Gagal menerima payload konfigurasi setelah beberapa kali mencoba.")
                        reject("Payload was nil or malformed")
                    end
                    return
                end

                -- Process configs
                flattenAndRegister(receivedPayload.AssetConfig, assetRegistry)
                loadingPhases = receivedPayload.LoadingConfig.LoadingPhases
                serverIsReady = receivedPayload.IsServerReady or false

                isInitialized = true
                readyEvent:Fire()
                
                local assetCount = 0
                for _ in pairs(assetRegistry) do assetCount = assetCount + 1 end
                print(string.format("📦 [AssetManager v4.0] Client sinkronisasi selesai. Menerima %d aset dan %d fase pemuatan.", assetCount, #loadingPhases))
                resolve(true)
            
            end, function(err)
                if attempt < maxRetries then
                    warn(string.format("[AssetManager v4.0] Invoke gagal (percobaan %d/%d): %s. Mencoba lagi...", attempt, maxRetries, tostring(err)))
                    task.wait(1)
                    attemptSync(attempt + 1):andThen(resolve, reject)
                else
                    warn("[AssetManager v4.0] Panggilan InvokeServer gagal total: " .. tostring(err))
                    reject(err)
                end
            end)
        end)
    end

    return attemptSync(1)
end


function AssetManager.Initialize()
    if not RunService:IsServer() then
        print("🔍 [AssetManager v4.0] Menginisialisasi registry aset (menunggu sinkronisasi)...")
    end
end

--======================================================================
--=                       PRELOADING & CACHING                         =
--======================================================================

-- Unchanged: Still preloads a single asset.
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

-- REWRITTEN: Implements multi-phase preloading.
function AssetManager.preloadInitialAsync()
    if isPreloading then return end
    isPreloading = true

    print("⏳ [AssetManager v4.0] Memulai proses pemuatan multi-fase...")
    local startTime = tick()
    
    local totalAssetsToLoad = 0
    for _, phase in ipairs(loadingPhases) do
        totalAssetsToLoad = totalAssetsToLoad + #phase.AssetNames
    end

    if totalAssetsToLoad == 0 then
        print("✅ [AssetManager v4.0] Tidak ada aset untuk di-preload. Langsung selesai.")
        isPreloading = false
        preloadCompleteEvent:Fire(0, 0)
        return
    end

    local totalLoadedAssets = 0
    local totalFailedAssets = 0

    -- Iterate through each phase
    for i, phase in ipairs(loadingPhases) do
        print(string.format("  -> Memulai Fase %d/%d: %s", i, #loadingPhases, phase.PhaseName))
        phaseChangedEvent:Fire(phase.PhaseName, phase.Description, #phase.AssetNames)

        local phaseLoaded, phaseFailed = 0, 0
        for _, assetName in ipairs(phase.AssetNames) do
            local assetData = assetRegistry[assetName]
            if not assetData then
                warn(string.format("    -> ⚠️ Tidak dapat melakukan preload: aset '%s' tidak ditemukan di registry.", assetName))
                phaseFailed = phaseFailed + 1
            elseif preloadAsset(assetData, assetName) then
                phaseLoaded = phaseLoaded + 1
            else
                phaseFailed = phaseFailed + 1
            end
            -- Fire global progress
            preloadProgressEvent:Fire(totalLoadedAssets + phaseLoaded, totalAssetsToLoad, assetName)
            task.wait(0.01) -- Yield to prevent freezing
        end
        
        totalLoadedAssets = totalLoadedAssets + phaseLoaded
        totalFailedAssets = totalFailedAssets + phaseFailed
        print(string.format("    -> Fase '%s' selesai. Berhasil: %d, Gagal: %d.", phase.PhaseName, phaseLoaded, phaseFailed))
    end

    isPreloading = false
    print(string.format("✅ [AssetManager v4.0] Semua fase pemuatan selesai dalam %.2fs. Total Berhasil: %d, Total Gagal: %d.", (tick() - startTime), totalLoadedAssets, totalFailedAssets))
    preloadCompleteEvent:Fire(totalLoadedAssets, totalAssetsToLoad)
end

--======================================================================
--=                            API PUBLIK                            =
--======================================================================

AssetManager.PhaseChanged = phaseChangedEvent.Event -- New Event
AssetManager.PreloadProgress = preloadProgressEvent.Event
AssetManager.PreloadComplete = preloadCompleteEvent.Event
AssetManager.OnReady = readyEvent.Event

function AssetManager.IsReady()
    return isInitialized
end

function AssetManager.CheckServerReady()
    return serverIsReady
end

function AssetManager.get(assetName)
    local asset = assetRegistry[assetName]
    if not asset then
        warn(string.format("[AssetManager v4.0] Aset '%s' tidak ditemukan di registry!", assetName))
        return nil
    end
    return asset
end

--======================================================================
--=                         AUTO-INISIALISASI                        =
--======================================================================

AssetManager.Initialize()

return AssetManager
