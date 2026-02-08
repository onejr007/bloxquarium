--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local InjectedDataService

local PlotService = {}
PlotService.ServiceName = "PlotService"

PlotService.plots = {}
PlotService.unownedPlots = {}
PlotService.playerPlots = {}

local PLOT_COUNT = 50
local WORLD_RADIUS = 200
local PLOT_AREA_RADIUS = WORLD_RADIUS - 50
local PLOT_Y_LEVEL = 21
local GRASS_Y_LEVEL = 18

function PlotService:Init(DataService)
    InjectedDataService = DataService
    print("🏝️ [PlotService] Initializing Plot Service...")
    self:GeneratePlots()

    if InjectedDataService and InjectedDataService.StateUpdated then
        InjectedDataService.StateUpdated:Connect(function(player)
            if self.playerPlots[player] then
                local plotToUpdate = self.playerPlots[player]
                local updatedPlot = self:UpdateAquariumModel(player, plotToUpdate)
                self.playerPlots[player] = updatedPlot
            end
        end)
        print("   -> [PlotService] Berhasil terhubung ke DataService.StateUpdated.")
    else
        warn("   -> [PlotService] KRITIS: Gagal terhubung ke DataService.StateUpdated.")
    end

    local function onPlayerAdded(player)
        self:AssignPlotToPlayer(player)
        
        -- DIPERBAIKI: Logika teleportasi sekarang ditangani dengan aman di sini.
        player.CharacterAdded:Connect(function(character)
            task.wait() -- Menunggu 1 frame untuk memastikan spawn default Roblox selesai.
            local plot = self.playerPlots[player]
            if plot then
                self:TeleportCharacterToPlot(character, plot)
            end
        end)
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end

    print("✅ [PlotService] Inisialisasi selesai.")
end

function PlotService:Start() end

function PlotService:GeneratePlots()
    local plotContainer = Instance.new("Folder"); plotContainer.Name = "Plots"; plotContainer.Parent = Workspace
    local aquariumAsset = ReplicatedStorage:WaitForChild("assets", 10):WaitForChild("models", 10):WaitForChild("M_Aquarium", 10):WaitForChild("Aquarium_Lv1", 10)
    if not aquariumAsset then warn("!!! Gagal menunggu aset Aquarium_Lv1."); return end
    for i = 1, PLOT_COUNT do
        local angle = (i/PLOT_COUNT)*2*math.pi; local x=PLOT_AREA_RADIUS*math.cos(angle); local z=PLOT_AREA_RADIUS*math.sin(angle)
        local pos = Vector3.new(x,PLOT_Y_LEVEL,z); local center=Vector3.new(0,PLOT_Y_LEVEL,0); local cframe = CFrame.lookAt(pos, center)
        local newAquarium = aquariumAsset:Clone(); newAquarium.Name = "UnownedPlot_" .. i
        if not newAquarium.PrimaryPart then
            local p; for _,d in ipairs(newAquarium:GetDescendants()) do if d:IsA("BasePart") then p=d; break end end
            if p then newAquarium.PrimaryPart = p else newAquarium:Destroy(); continue end
        end
        newAquarium:SetPrimaryPartCFrame(cframe); newAquarium.Parent = plotContainer
        table.insert(self.plots, newAquarium); table.insert(self.unownedPlots, newAquarium)
    end
end

-- DIPERBAIKI: Fungsi ini sekarang HANYA menugaskan plot, tidak menteleportasi.
function PlotService:AssignPlotToPlayer(player)
    if self.playerPlots[player] then return end -- Sudah punya plot
    if #self.unownedPlots > 0 then
        local randomIndex = math.random(#self.unownedPlots)
        local assignedPlot = self.unownedPlots[randomIndex]
        table.remove(self.unownedPlots, randomIndex)
        assignedPlot.Name = "Plot_" .. player.Name
        self.playerPlots[player] = assignedPlot
        print(string.format("   -> [AssignPlot] Plot '%s' ditugaskan ke %s.", assignedPlot.Name, player.Name))
    end
end

function PlotService:UpdateAquariumModel(player, currentPlot)
    local playerData = InjectedDataService:Get(player)
    if not playerData then return currentPlot end 
    
    local level = playerData.AquariumLevel or 1
    local desiredModelName = "Aquarium_Lv" .. tostring(level)
    
    if not currentPlot or (currentPlot:GetAttribute("ModelName") == desiredModelName) then return currentPlot end

    print(string.format("      -> [UpdateModel] Level pemain adalah %d. Mengganti dengan model '%s'.", level, desiredModelName))
    local aquariumModelContainer = ReplicatedStorage.assets.models.M_Aquarium
    local newAquariumAsset = aquariumModelContainer:FindFirstChild(desiredModelName)
    if not newAquariumAsset then warn(string.format("      -> GAGAL: Tidak dapat menemukan aset untuk %s.", desiredModelName)); return currentPlot end

    local oldCFrame = currentPlot:GetPrimaryPartCFrame()
    local parent = currentPlot.Parent
    local name = currentPlot.Name
    
    local newPlot = newAquariumAsset:Clone()
    currentPlot:Destroy()
    
    newPlot.Name = name; newPlot.Parent = parent
    if not newPlot.PrimaryPart then
        local p; for _,d in ipairs(newPlot:GetDescendants()) do if d:IsA("BasePart") then p=d; break end end
        if p then newPlot.PrimaryPart = p else newPlot:Destroy(); return nil end
    end
    newPlot:SetPrimaryPartCFrame(oldCFrame); newPlot:SetAttribute("ModelName", desiredModelName)
    return newPlot
end

-- DIPERBAIKI: Fungsi yang aman dan terfokus untuk menteleportasi karakter yang sudah ada.
function PlotService:TeleportCharacterToPlot(character, plot)
    if not plot or not plot.PrimaryPart or not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local plotPos = plot.PrimaryPart.Position
    local outVec = (plotPos - Vector3.new(0, plotPos.Y, 0)).Unit
    local tpPos = plotPos + (outVec * 20)
    local groundPos = Vector3.new(tpPos.X, GRASS_Y_LEVEL + 3, tpPos.Z)
    local tpCFrame = CFrame.lookAt(groundPos, plotPos)
    
    root.CFrame = tpCFrame
    print(string.format("      -> [Teleport] Karakter telah diteleportasi ke plot."))
end

return PlotService
