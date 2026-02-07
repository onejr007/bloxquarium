--!strict
--[=[
	@class WorldService
	Layanan ini bertanggung jawab untuk pembuatan dan manajemen dunia game secara profesional
	menggunakan teknik 'layered carving' Terrain untuk hasil yang kompleks dan alami.
--]=]
local WorldService = {}

--[=[
	Membangun dunia awal game menggunakan metode profesional multi-lapis untuk menciptakan
	pulau realistis dengan pantai dan area berumput.

	@within WorldService
]=]
function WorldService:Generate()
	-- Hapus artefak lama untuk memastikan build yang bersih
	for _, child in ipairs(workspace:GetChildren()) do
		if (child:IsA("BasePart") or child:IsA("MeshPart")) and not child:IsA("Terrain") and not child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end

	-- 1. Persiapan: Mulai dengan kanvas kosong
	print("🌍 [WorldService] Memulai pembangunan dunia v5 (Metode Layered Carve)...")
	workspace.Terrain:Clear()

	-- --- Konfigurasi Dunia ---
	local seaLevel = 0
	local flatTopSandLevel = 16  -- Ketinggian (Y) dari pantai pasir
	local flatTopGrassLevel = 18 -- Ketinggian (Y) dari area rumput (sedikit lebih tinggi)

	local sandRadius = 200  -- Radius total pulau (termasuk pantai)
	local grassRadius = 160 -- Radius area berumput (lebih kecil dari pasir)
	
	-- Ukuran bola mentah harus lebih besar dari radius target untuk mendapatkan lereng yang bagus
	local sandBallGrowth = 100
	local grassBallGrowth = 50
	--------------------------

	-- 2. Buat Fondasi Bola Pasir (Untuk Diukir)
	print("🏝️ [WorldService] Membentuk bola pasir mentah...")
	local sandBallRadius = sandRadius + sandBallGrowth
	local sandBallCenter = Vector3.new(0, flatTopSandLevel - sandRadius, 0)
	workspace.Terrain:FillBall(sandBallCenter, sandBallRadius, Enum.Material.Sand)

	-- 3. Ukir Lapisan Pasir menjadi Datar
	print("🔪 [WorldService] Mengukir pantai pasir menjadi datar...")
	local sandCarveCFrame = CFrame.new(0, flatTopSandLevel + 50, 0) -- Pusatkan balok di atas
	local sandCarveSize = Vector3.new(4096, 100, 4096)
	workspace.Terrain:FillBlock(sandCarveCFrame, sandCarveSize, Enum.Material.Air)

	-- 4. Buat Bola Rumput di Atasnya (Untuk Diukir)
	print("🌿 [WorldService] Menambahkan bola rumput mentah di atas pasir...")
	local grassBallRadius = grassRadius + grassBallGrowth
	local grassBallCenter = Vector3.new(0, flatTopGrassLevel - grassRadius, 0)
	workspace.Terrain:FillBall(grassBallCenter, grassBallRadius, Enum.Material.Grass)
	
	-- 5. Ukir Lapisan Rumput menjadi Datar
	print("🔪 [WorldService] Mengukir puncak rumput menjadi datar...")
	local grassCarveCFrame = CFrame.new(0, flatTopGrassLevel + 50, 0) -- Pusatkan balok di atas
	local grassCarveSize = Vector3.new(4096, 100, 4096)
	workspace.Terrain:FillBlock(grassCarveCFrame, grassCarveSize, Enum.Material.Air)

	-- 6. Ciptakan Lautan: Isi dunia dengan air di sekitar pulau yang sudah terbentuk.
	print("🌊 [WorldService] Mengisi lautan...")
	local seaDepth = 60
	local oceanSize = Vector3.new(4096, seaDepth, 4096)
	local oceanCFrame = CFrame.new(0, seaLevel - (seaDepth / 2), 0)
	workspace.Terrain:FillBlock(oceanCFrame, oceanSize, Enum.Material.Water)
	
	-- 7. Finalisasi Spawn: Posisikan SpawnLocation dengan presisi di atas area berumput.
	print("📍 [WorldService] Menyesuaikan posisi spawn...")
	local spawnLocation = workspace:FindFirstChild("DefaultSpawn") or Instance.new("SpawnLocation")
	spawnLocation.Name = "DefaultSpawn"
	spawnLocation.Position = Vector3.new(0, flatTopGrassLevel + 3, 0) -- Tepat di atas permukaan rumput
	spawnLocation.Anchored = true
	spawnLocation.AllowTeamChangeOnTouch = false
	spawnLocation.Size = Vector3.new(50, 1, 50)
	spawnLocation.Transparency = 1
	spawnLocation.Parent = workspace

	print("✅ [WorldService] Pembangunan pulau ukiran berlapis telah selesai!")
end

return WorldService
