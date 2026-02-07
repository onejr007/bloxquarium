--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local PlotService = {}
PlotService.ServiceName = "PlotService"

PlotService.plots = {} -- Semua model plot
PlotService.unownedPlots = {} -- Plot yang belum ditugaskan
PlotService.playerPlots = {} -- Memetakan Player ke plot mereka

local PLOT_COUNT = 50
local WORLD_RADIUS = 200
local PLOT_AREA_RADIUS = WORLD_RADIUS - 50
local PLOT_Y_LEVEL = 21
local GRASS_Y_LEVEL = 18

-- FUNGSI :Start() YANG LAMA SEKARANG DIGABUNGKAN KE DALAM :Init()
function PlotService:Init()
    print("🏝️ [PlotService] Initializing Plot Service...")
    
    -- Langkah 1: Buat semua plot terlebih dahulu
    self:GeneratePlots()

    print("   -> [PlotService] Plot dibuat. Sekarang menginisialisasi penanganan pemain...")

    -- Langkah 2: Siapkan fungsi untuk menangani pemain baru
    local function onPlayerAdded(player)
        task.spawn(function()
            print(string.format("==> [PlotService] Tugas baru di-spawn untuk pemain yang bergabung: %s", player.Name))
            self:AssignPlotToPlayer(player)
        end)
    end

    -- Langkah 3: Hubungkan fungsi di atas ke event PlayerAdded
    Players.PlayerAdded:Connect(onPlayerAdded)

    -- Langkah 4: Jalankan untuk semua pemain yang sudah ada di dalam game saat layanan ini dimulai
    for _, player in ipairs(Players:GetPlayers()) do
        print(string.format("==> [PlotService] Menjalankan untuk pemain yang sudah ada: %s", player.Name))
        onPlayerAdded(player)
    end
    
    print("✅ [PlotService] Inisialisasi selesai dan siap untuk pemain.")
end

-- Fungsi Start() yang kosong ini tidak lagi diperlukan karena ServiceLoader tidak memanggilnya,
-- tetapi dibiarkan di sini untuk konsistensi jika loader diperbarui di masa mendatang.
function PlotService:Start()
end

function PlotService:GeneratePlots()
    local plotContainer = Instance.new("Folder")
    plotContainer.Name = "Plots"
    plotContainer.Parent = Workspace
    local aquariumAsset = ReplicatedStorage:WaitForChild("assets", 10):WaitForChild("models", 10):WaitForChild("M_Aquarium", 10):WaitForChild("Aquarium_Lv1", 10)
    if not aquariumAsset then warn("!!! [PlotService] Timeout: Gagal menunggu aset akuarium."); return end
    print("   -> [GeneratePlots] Aset akuarium ditemukan. Memulai pembuatan...")
    for i = 1, PLOT_COUNT do
        local angle = (i / PLOT_COUNT) * 2 * math.pi
        local x = PLOT_AREA_RADIUS * math.cos(angle)
        local z = PLOT_AREA_RADIUS * math.sin(angle)
        local position = Vector3.new(x, PLOT_Y_LEVEL, z)
        local centerPoint = Vector3.new(0, PLOT_Y_LEVEL, 0)
        local plotCFrame = CFrame.lookAt(position, centerPoint)
        local newAquarium = aquariumAsset:Clone()
        newAquarium.Name = "UnownedPlot_" .. tostring(i)
        if not newAquarium.PrimaryPart then
            local firstPart = nil
            for _, descendant in ipairs(newAquarium:GetDescendants()) do
                if descendant:IsA("BasePart") then firstPart = descendant; break end
            end
            if firstPart then newAquarium.PrimaryPart = firstPart else newAquarium:Destroy(); continue end
        end
        newAquarium:SetPrimaryPartCFrame(plotCFrame)
        newAquarium.Parent = plotContainer
        table.insert(self.plots, newAquarium)
        table.insert(self.unownedPlots, newAquarium)
    end
    print(string.format("   -> [GeneratePlots] Pembuatan %d plot selesai.", #self.plots))
end

function PlotService:AssignPlotToPlayer(player)
    print(string.format("   -> [AssignPlot] Memulai proses untuk %s.", player.Name))
    if self.playerPlots[player] then
        print(string.format("   -> [AssignPlot] %s sudah memiliki plot. Menteleportasi kembali.", player.Name))
        self:TeleportPlayerToPlot(player, self.playerPlots[player])
        return
    end

    print(string.format("   -> [AssignPlot] Jumlah plot yang belum dimiliki: %d", #self.unownedPlots))
    if #self.unownedPlots > 0 then
        local randomIndex = math.random(#self.unownedPlots)
        local assignedPlot = self.unownedPlots[randomIndex]
        print(string.format("   -> [AssignPlot] Plot acak #%d dipilih untuk %s.", randomIndex, player.Name))
        table.remove(self.unownedPlots, randomIndex)
        self.playerPlots[player] = assignedPlot
        assignedPlot.Name = "Plot_" .. player.Name
        print(string.format("   -> [AssignPlot] BERHASIL: Plot '%s' ditugaskan ke %s. Memulai teleportasi...", assignedPlot.Name, player.Name))
        self:TeleportPlayerToPlot(player, assignedPlot)
    else
        warn(string.format("!!! [PlotService] GAGAL: Tidak ada plot yang tersedia untuk ditugaskan ke %s!", player.Name))
    end
end

function PlotService:TeleportPlayerToPlot(player, plot)
    print("      -> [Teleport] Memulai proses teleportasi...")
    local character = player.Character or player.CharacterAdded:Wait()
    print("      -> [Teleport] Karakter ditemukan.")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoidRootPart then warn("      -> [Teleport] GAGAL: HumanoidRootPart tidak ditemukan."); return end
    print("      -> [Teleport] HumanoidRootPart ditemukan.")
    local plotPrimaryPart = plot.PrimaryPart
    if not plotPrimaryPart then warn("      -> [Teleport] GAGAL: Plot tidak memiliki PrimaryPart."); return end
    print("      -> [Teleport] PrimaryPart plot ditemukan.")
    print("      -> [Teleport] Menunggu 0.5 detik untuk menghindari penimpaan spawn...")
    task.wait(0.5)
    print("      -> [Teleport] Penundaan selesai. Menghitung CFrame...")
    local plotPosition = plotPrimaryPart.Position
    local outwardVector = (plotPosition - Vector3.new(0, plotPosition.Y, 0)).Unit
    local teleportPosition = plotPosition + (outwardVector * 20)
    local groundPosition = Vector3.new(teleportPosition.X, GRASS_Y_LEVEL + 3, teleportPosition.Z)
    local teleportCFrame = CFrame.lookAt(groundPosition, plotPosition)
    print(string.format("      -> [Teleport] CFrame dihitung. Menteleportasi %s sekarang...", player.Name))
    humanoidRootPart.CFrame = teleportCFrame
    print(string.format("      -> [Teleport] BERHASIL: %s telah diteleportasi.", player.Name))
end

return PlotService
