--[[
	AssetManager.luau (v2.4 - Correct Sync Logic)

	Fixes the critical client-side error by changing the sync mechanism.
	The server now sends both the full asset list and a specific preload list,
	making the server the single source of truth and preventing the client
	from illegally accessing ServerScriptService.
]]

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AssetManager = {}

--======================================================================
--=                              INTERNAL                              =
--======================================================================

local assetRegistry = {} 
local preloadList = {} -- NEW: A simple array of names to preload
local preloadedAssets = {} 
local processedAssetCache = {}

local isInitialized = false
local isPreloading = false

-- Events
local preloadProgressEvent = Instance.new("BindableEvent")
local preloadCompleteEvent = Instance.new("BindableEvent")

--======================================================================
--=                     INISIALISASI & REGISTRASI                      =
--======================================================================

-- Recursively flattens the asset config into a single-level registry
local function flattenAssetRegistry(config)
    local flatRegistry = {}
    for category, assets in pairs(config) do
        if typeof(assets) == "table" then
            for assetName, assetData in pairs(assets) do
                if flatRegistry[assetName] then
                    warn(string.format("[AssetManager] Nama aset duplikat '%s'. Registrasi dilewati.", assetName))
                else
                    flatRegistry[assetName] = assetData
                end
            end
        end
    end
    return flatRegistry
end

-- Scans for model files in ReplicatedStorage.Assets
local function scanModelAssets(modelFolder, targetRegistry)
    local count = 0
    for _, child in ipairs(modelFolder:GetChildren()) do
        if child:IsA("Model") or child:IsA("Part") or child:IsA("MeshPart") then
            if not targetRegistry[child.Name] then
                targetRegistry[child.Name] = child
                count = count + 1
            end
        elseif child:IsA("Folder") then
            count = count + scanModelAssets(child, targetRegistry)
        end
    end
    return count
end


-- SERVER-SIDE INITIALIZATION
local function initializeServer()
	local startTime = tick()
	local success, config = pcall(require, game:GetService("ServerScriptService"):WaitForChild("asset_config"))

    if not success or not config then
        warn("[AssetManager] Gagal memuat asset_config. Error: " .. tostring(config))
        assetRegistry = {}
    else
        assetRegistry = flattenAssetRegistry(config)
    end

    local modelAssetCount = 0
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if assetsFolder and assetsFolder:FindFirstChild("models") then
        -- Add models to the registry without overwriting config entries
		modelAssetCount = scanModelAssets(assetsFolder.models, assetRegistry)
    else
        warn("[AssetManager] Folder 'Assets/models' tidak ditemukan. Melewati pemindaian model.")
	end

    local idAssetCount = 0
    for _ in pairs(assetRegistry) do idAssetCount = idAssetCount + 1 end
    idAssetCount = idAssetCount - modelAssetCount

	print(string.format("📦 [AssetManager] Server Inisialisasi selesai dalam %.2fs. %d total aset ditemukan (%d model, %d ID-based).", (tick() - startTime), idAssetCount + modelAssetCount, modelAssetCount, idAssetCount))
    
    -- Create the RemoteFunction for client sync
    local syncFunction = Instance.new("RemoteFunction")
    syncFunction.Name = "GetAssetRegistry"
    syncFunction.Parent = ReplicatedStorage
    syncFunction.OnServerInvoke = function(player)
        print("[AssetManager] Client " .. player.Name .. " meminta registry aset. Mengirim...")
        
        -- Generate the preload list from the original config
        local preloadNames = {}
        if config and config.Preload then
            for name, _ in pairs(config.Preload) do
                table.insert(preloadNames, name)
            end
        end

        return {
            fullRegistry = assetRegistry, -- Send the flattened, complete registry
            preloadList = preloadNames    -- Send the list of names to preload
        }
    end
end

-- CLIENT-SIDE SYNC
function AssetManager.syncWithServerAsync()
    if RunService:IsServer() then return true end
    if isInitialized then return true end

    print("🔍 [AssetManager] Meminta registry aset dari server...")
    local syncFunction = ReplicatedStorage:WaitForChild("GetAssetRegistry", 15)
    if not syncFunction then
        warn("[AssetManager] Gagal menemukan GetAssetRegistry RemoteFunction. Tidak dapat sinkronisasi aset.")
        return false
    end

    local success, receivedPayload = pcall(syncFunction.InvokeServer, syncFunction)

    if not success or not receivedPayload or not receivedPayload.fullRegistry then
        warn("[AssetManager] Gagal memanggil atau menerima payload aset dari server. Error: " .. tostring(receivedPayload))
        return false
    end
    
    assetRegistry = receivedPayload.fullRegistry -- Store the full list
    preloadList = receivedPayload.preloadList or {} -- Store the names of assets to preload
    isInitialized = true
    
    local assetCount = 0
    for _ in pairs(assetRegistry) do assetCount = assetCount + 1 end
    
    print(string.format("📦 [AssetManager] Client sinkronisasi selesai. Menerima %d aset total, %d aset untuk di-preload.", assetCount, #preloadList))
    return true
end

-- Main initialization logic
function AssetManager.Initialize()
    if isInitialized then return end
    if RunService:IsServer() then
        initializeServer()
        isInitialized = true
    else
        print("🔍 [AssetManager] Menginisialisasi registry aset (klien menunggu sinkronisasi)...")
    end
end

--======================================================================
--=                       PRELOADING & CACHING                         =
--======================================================================

local function preloadAsset(asset, assetName)
	if not asset then return false end
	local success, err = pcall(function()
		if typeof(asset) == "Instance" then ContentProvider:PreloadAsync({asset}) elseif typeof(asset) == "string" then ContentProvider:PreloadAsync({asset}) elseif typeof(asset) == "table" and asset.id then ContentProvider:PreloadAsync({asset.id}) end
	end)
	if not success then warn(string.format("[AssetManager] Gagal mem-preload '%s'. Error: %s", assetName, err)) return false end
	preloadedAssets[assetName] = true
	return true
end

-- REWRITTEN: Now uses the `preloadList` received from the server.
function AssetManager.preloadInitialAsync()
    if not isInitialized then
        warn("[AssetManager] Tidak bisa preload, AssetManager belum diinisialisasi.")
        preloadCompleteEvent:Fire(0, 0)
        return
    end
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
		if i % 10 == 0 then RunService.Heartbeat:Wait() end
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

-- Now handles on-demand loading for non-preloaded assets
function AssetManager.get(assetName)
	local asset = assetRegistry[assetName]
	if not asset then
		warn(string.format("[AssetManager] Aset '%s' tidak ditemukan di registry!", assetName))
		return nil
	end

	-- If not preloaded, load it now (on-demand loading)
	if not preloadedAssets[assetName] then
        print(string.format("📥 [AssetManager] On-demand load: '%s'", assetName))
		preloadAsset(asset, assetName)
	end

	local assetType = typeof(asset)
	if assetType == "Instance" then
		return asset:Clone()
	elseif assetType == "string" then
		return asset
	elseif assetType == "table" and asset.id then
		if processedAssetCache[assetName] then
			return processedAssetCache[assetName]
		end
		local sound = Instance.new("Sound")
		sound.Name = assetName
		sound.SoundId = asset.id
		sound.Volume = asset.volume or 1
		sound.Looped = asset.looped or false
		processedAssetCache[assetName] = sound
		return sound
	end
	warn(string.format("[AssetManager] Tipe aset tidak dikenal untuk '%s'", assetName))
	return asset
end

-- getClone, spawn, has remain the same
function AssetManager.getClone(assetName) local asset = AssetManager.get(assetName) if not asset then return nil end if typeof(asset) == "Instance" then return asset:Clone() else return asset end end
function AssetManager.spawn(assetName, position, parent) local model = AssetManager.get(assetName) if not (model and model:IsA("Model")) then warn(string.format("[AssetManager] Tidak bisa spawn '%s', karena bukan Model.", assetName)) return nil end model.Parent = parent or workspace if position and model.PrimaryPart then model:SetPrimaryPartCFrame(CFrame.new(position)) end return model end
function AssetManager.has(assetName) return assetRegistry[assetName] ~= nil end

--======================================================================
--=                         AUTO-INISIALISASI                        =
--======================================================================

AssetManager.Initialize()

return AssetManager
