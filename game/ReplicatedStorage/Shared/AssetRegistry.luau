--[[
	AssetRegistry.luau
	
	Sistem registry untuk mendeteksi dan mapping semua asset yang ada di folder assets/models dan asset_config.luau
	Menyediakan interface untuk mengakses asset dengan mudah
	(Cache-busting comment)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AssetRegistry = {}
AssetRegistry.__index = AssetRegistry

-- Cache untuk menyimpan semua asset yang sudah di-load
local assetCache = {}
local assetPaths = {}
local isInitialized = false

-- Event untuk notifikasi ketika asset selesai di-load
local assetLoadedEvent = Instance.new("BindableEvent")
AssetRegistry.AssetLoaded = assetLoadedEvent.Event

-- Fungsi untuk scan semua asset model di folder Models
local function scanModelAssets(folder, path)
	path = path or ""
	local count = 0

	local children = folder:GetChildren()
	table.sort(children, function(a, b)
		return a.Name < b.Name
	end)

	for _, child in ipairs(children) do
		local currentPath = path == "" and child.Name or path .. "/" .. child.Name
		
		if child:IsA("Model") or child:IsA("Part") or child:IsA("MeshPart") then
			if assetCache[child.Name] then
				warn(string.format("[AssetRegistry] Duplicate asset name '%s'. Skipping registration.", child.Name))
			else
				assetCache[child.Name] = child
				assetPaths[child.Name] = currentPath
				
				local clonedAsset = child:Clone()
				clonedAsset.Parent = nil
				assetCache[child.Name .. "_template"] = clonedAsset
				count = count + 1
			end
		elseif child:IsA("Folder") then
			count = count + scanModelAssets(child, currentPath)
		end
	end
	return count
end

-- Fungsi untuk scan semua asset berbasis ID dari file konfigurasi
local function scanIdBasedAssets()
	local count = 0
	local configModule = script.Parent:WaitForChild("AssetConfigData", 5)
	if not configModule then
		warn("[AssetRegistry] Could not find 'AssetConfigData.luau'. Skipping ID-based assets.")
		return 0
	end

	local success, config = pcall(require, configModule)
	if not success or typeof(config) ~= "table" then
		warn("[AssetRegistry] Failed to load or parse AssetConfigData.luau. Error: " .. tostring(config))
		return 0
	end

	print("📦 [AssetRegistry] Loading ID-based assets from internal config data...")
	for category, assets in pairs(config) do
		if typeof(assets) == "table" then
			for assetName, assetId in pairs(assets) do
				if assetCache[assetName] then
					warn(string.format("[AssetRegistry] Duplicate asset name '%s'. Skipping registration.", assetName))
				else
					assetCache[assetName] = assetId
					assetPaths[assetName] = "AssetConfigData.luau/" .. category
					count = count + 1
				end
			end
		end
	end

	return count
end

-- Fungsi untuk initialize asset registry
function AssetRegistry.Initialize()
	if isInitialized then
		warn("⚠️ [AssetRegistry] Already initialized!")
		return
	end
	
	print("🔍 [AssetRegistry] Initializing... Bypassing file-sync issue.")
	
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	
	local startTime = tick()
	local modelAssetCount = 0
	
	if assetsFolder then
		local modelsFolder = assetsFolder:FindFirstChild("models")
		if modelsFolder then
			print("📂 [AssetRegistry] Scanning for model assets...")
			modelAssetCount = scanModelAssets(modelsFolder)
		else
			warn("[AssetRegistry] 'models' sub-folder not found. Skipping model scan.")
		end
	else
		warn("[AssetRegistry] 'Assets' folder not found. Skipping model scan entirely.")
	end

	local idAssetCount = scanIdBasedAssets()
	
	local totalAssets = modelAssetCount + idAssetCount
	local scanTime = tick() - startTime
	
	isInitialized = true
	
	print("╔" .. string.rep("═", 50) .. "╗")
	print("║" .. string.rep(" ", 10) .. "🔍 ASSET REGISTRY INITIALIZED 🔍" .. string.rep(" ", 7) .. "║")
	print("║" .. string.rep(" ", 50) .. "║")
	print(string.format("║  📦 Total assets discovered: %d", totalAssets) .. string.rep(" ", 50 - 29 - string.len(tostring(totalAssets))) .. "║")
	print(string.format("║    - Models: %d", modelAssetCount) .. string.rep(" ", 50 - 16 - string.len(tostring(modelAssetCount))) .. "║")
	print(string.format("║    - ID-Based: %d", idAssetCount) .. string.rep(" ", 50 - 18 - string.len(tostring(idAssetCount))) .. "║")
	print(string.format("║  ⏱️  Scan time: %.3f seconds" .. string.rep(" ", 50 - 22 - string.len(string.format("%.3f", scanTime))) .. "║", scanTime))
	print("╚" .. string.rep("═", 50) .. "╝")
end

function AssetRegistry.GetAsset(assetName)
	if not isInitialized then AssetRegistry.Initialize() end
	
	local asset = assetCache[assetName]
	if not asset then
		warn("[AssetRegistry] Asset not found:", assetName)
		return nil
	end
	
	return asset
end

function AssetRegistry.GetAssetClone(assetName)
	if not isInitialized then AssetRegistry.Initialize() end

	local asset = assetCache[assetName]
	if typeof(asset) ~= "Instance" then
		warn(string.format("[AssetRegistry] Cannot clone asset '%s'. Not a model.", assetName))
		return nil
	end
	
	local template = assetCache[assetName .. "_template"]
	if not template then
		warn("[AssetRegistry] Asset template not found:", assetName)
		return nil
	end
	
	return template:Clone()
end

function AssetRegistry.GetAllAssets()
	if not isInitialized then AssetRegistry.Initialize() end
	
	local assets = {}
	for name, asset in pairs(assetCache) do
		if not string.find(name, "_template") then
			assets[name] = asset
		end
	end
	
	return assets
end

function AssetRegistry.GetAssetPath(assetName)
	if not isInitialized then AssetRegistry.Initialize() end
	
	return assetPaths[assetName]
end

function AssetRegistry.HasAsset(assetName)
	if not isInitialized then AssetRegistry.Initialize() end
	
	return assetCache[assetName] ~= nil
end

-- PERBAIKAN: Menambahkan fungsi GetAssetCount yang hilang
function AssetRegistry.GetAssetCount()
	if not isInitialized then AssetRegistry.Initialize() end

	local count = 0
	for name, _ in pairs(assetCache) do
		-- Jangan hitung template sebagai asset unik
		if not string.find(name, "_template") then
			count = count + 1
		end
	end
	return count
end

-- Auto-initialize saat script pertama kali di-require
if RunService:IsServer() or RunService:IsClient() then
	AssetRegistry.Initialize()
end

return AssetRegistry
