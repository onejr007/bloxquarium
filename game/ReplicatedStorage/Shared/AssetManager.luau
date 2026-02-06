--[[
	AssetManager.luau
	
	API Interface utama untuk developer mengakses asset system
	Menyediakan interface yang mudah dan intuitif untuk menggunakan asset
]]

local AssetRegistry = require(script.Parent.AssetRegistry)
local AssetLoader = require(script.Parent.AssetLoader)
local AssetErrorHandler = require(script.Parent.AssetErrorHandler)

local AssetManager = {}

-- Fungsi utama untuk mendapatkan asset (reference ke original)
function AssetManager.Get(assetName)
	return AssetLoader.GetAsset(assetName)
end

-- Fungsi untuk mendapatkan clone asset (untuk digunakan di game)
function AssetManager.Clone(assetName)
	return AssetLoader.GetAssetClone(assetName)
end

-- Fungsi untuk spawn asset langsung ke workspace
function AssetManager.Spawn(assetName, position, parent)
	return AssetLoader.SpawnAsset(assetName, position, parent)
end

-- Fungsi untuk check apakah asset exists
function AssetManager.Exists(assetName)
	return AssetRegistry.HasAsset(assetName)
end

-- Fungsi untuk mendapatkan semua asset yang tersedia
function AssetManager.GetAll()
	return AssetRegistry.GetAllAssets()
end

-- Fungsi untuk mendapatkan list nama asset
function AssetManager.GetAssetNames()
	local assets = AssetRegistry.GetAllAssets()
	local names = {}
	
	for name in pairs(assets) do
		table.insert(names, name)
	end
	
	return names
end

-- Fungsi untuk preload asset tertentu
function AssetManager.Preload(assetName)
	return AssetLoader.PreloadAsset(assetName)
end

-- Fungsi untuk preload semua asset
function AssetManager.PreloadAll()
	AssetLoader.PreloadAllAssets()
end

-- Fungsi untuk check status preloading
function AssetManager.GetLoadingStatus()
	return AssetLoader.GetPreloadStatus()
end

-- Fungsi untuk check apakah asset sudah di-preload
function AssetManager.IsLoaded(assetName)
	return AssetLoader.IsPreloaded(assetName)
end

-- Event untuk notifikasi ketika asset baru ditambahkan
AssetManager.AssetAdded = AssetRegistry.AssetLoaded

-- Event untuk notifikasi ketika preloading selesai
AssetManager.PreloadComplete = AssetLoader.PreloadComplete

-- Fungsi utility untuk debugging
function AssetManager.Debug()
	local status = AssetLoader.GetPreloadStatus()
	local allAssets = AssetRegistry.GetAllAssets()
	
	print("=== Asset Manager Debug Info ===")
	print("Total Assets:", status.total)
	print("Preloaded Assets:", status.preloaded)
	print("Preload Percentage:", string.format("%.1f%%", status.percentage))
	print("Currently Preloading:", status.isPreloading)
	print("\nAsset List:")
	
	for name, asset in pairs(allAssets) do
		local isPreloaded = AssetLoader.IsPreloaded(name)
		local path = AssetRegistry.GetAssetPath(name)
		print(string.format("  %s [%s] - %s", name, isPreloaded and "LOADED" or "NOT LOADED", path or "unknown path"))
	end
	
	print("================================")
end

-- Safe versions dengan error handling
function AssetManager.SafeGet(assetName, fallbackAsset)
	return AssetErrorHandler.SafeGetAsset(assetName, fallbackAsset)
end

function AssetManager.SafeClone(assetName, fallbackAsset)
	return AssetErrorHandler.SafeCloneAsset(assetName, fallbackAsset)
end

function AssetManager.SafeSpawn(assetName, position, parent, fallbackAsset)
	return AssetErrorHandler.SafeSpawnAsset(assetName, position, parent, fallbackAsset)
end

-- Error handling functions
function AssetManager.GetErrorLog()
	return AssetErrorHandler.GetErrorLog()
end

function AssetManager.GetErrorStats()
	return AssetErrorHandler.GetErrorStats()
end

function AssetManager.GetHealthStatus()
	return AssetErrorHandler.HealthCheck()
end

function AssetManager.CreateFallback(name, size, color)
	return AssetErrorHandler.CreateFallbackAsset(name, size, color)
end

-- Event untuk error notifications
AssetManager.ErrorOccurred = AssetErrorHandler.ErrorOccurred

-- Fungsi untuk clear cache (debugging)
function AssetManager.ClearCache()
	AssetLoader.ClearCache()
end

function AssetManager.ClearErrorLog()
	AssetErrorHandler.ClearErrorLog()
end

return AssetManager