--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local InjectedDataService: any
local InjectedRemoteService: any
local InjectedUnderwaterService: any

local PlotService = {}
PlotService.ServiceName = "PlotService"

PlotService.plots = {}
PlotService.unownedPlots = {}
PlotService.playerPlots = {} -- {[Player]: Model}
PlotService.plotOwners = {} -- {[Model]: Player}

local PLOT_COUNT = 50
local WORLD_RADIUS = 200
local PLOT_AREA_RADIUS = WORLD_RADIUS - 50
local PLOT_Y_LEVEL = 21
local GRASS_Y_LEVEL = 18

function PlotService:Init(DataService: any, RemoteService: any, UnderwaterService: any)
    InjectedDataService = DataService
    InjectedRemoteService = RemoteService
    InjectedUnderwaterService = UnderwaterService
    
    print("🏝️ [PlotService] Initializing Plot Service...")
    self:GeneratePlots()

    if InjectedRemoteService then
        InjectedRemoteService:Register("RequestEnterAquarium", function(player: Player, plotModel: Model)
            local owner = self.plotOwners[plotModel]
            if owner then
                if InjectedUnderwaterService then
                    InjectedUnderwaterService:PrepareAquariumForPlayer(player, owner, plotModel)
                end
                InjectedRemoteService:SendToClient(player, "EnterAquariumSequence", owner, plotModel)
            end
        end)
    end

    if InjectedDataService and InjectedDataService.StateUpdated then
        InjectedDataService.StateUpdated:Connect(function(player: Player)
            if self.playerPlots[player] then
                local plotToUpdate = self.playerPlots[player]
                local updatedPlot = self:UpdateAquariumModel(player, plotToUpdate)
                if updatedPlot then
                    self.playerPlots[player] = updatedPlot
                end
            end
        end)
        print("   -> [PlotService] Berhasil terhubung ke DataService.StateUpdated.")
    else
        warn("   -> [PlotService] KRITIS: Gagal terhubung ke DataService.StateUpdated.")
    end

    local function onPlayerAdded(player: Player)
        self:AssignPlotToPlayer(player)
        
        player.CharacterAdded:Connect(function(character)
            task.wait(1) -- Beri waktu agar semua siap
            local plot = self.playerPlots[player]
            if plot and character:FindFirstChild("HumanoidRootPart") then
                self:TeleportCharacterToPlot(character, plot)
            end
        end)
        
        if player.Character then
            task.spawn(function()
                task.wait(1) -- Beri waktu agar semua siap
                local plot = self.playerPlots[player]
                if plot and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then 
                    self:TeleportCharacterToPlot(player.Character, plot) 
                end
            end)
        end
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end

    print("✅ [PlotService] Inisialisasi selesai.")
end

function PlotService:Start()
end

function PlotService:GeneratePlots()
    local plotContainer = Instance.new("Folder")
    plotContainer.Name = "Plots"
    plotContainer.Parent = Workspace
    
    local assets = ReplicatedStorage:WaitForChild("assets", 10)
    local models = if assets then assets:WaitForChild("models", 10) else nil
    local mAquarium = if models then models:WaitForChild("M_Aquarium", 10) else nil
    local aquariumAsset = if mAquarium then mAquarium:WaitForChild("Aquarium_Lv1", 10) else nil
    
    if not aquariumAsset then 
        warn("!!! Gagal menunggu aset Aquarium_Lv1.")
        return 
    end
    
    for i = 1, PLOT_COUNT do
        local angle = (i/PLOT_COUNT) * 2 * math.pi
        local x = PLOT_AREA_RADIUS * math.cos(angle)
        local z = PLOT_AREA_RADIUS * math.sin(angle)
        local pos = Vector3.new(x, PLOT_Y_LEVEL, z)
        local center = Vector3.new(0, PLOT_Y_LEVEL, 0)
        local cframe = CFrame.lookAt(pos, center)
        
        local newAquarium = (aquariumAsset :: Model):Clone()
        newAquarium.Name = "UnownedPlot_" .. tostring(i)
        
        if not newAquarium.PrimaryPart then
            local p = nil
            for _, d in ipairs(newAquarium:GetDescendants()) do 
                if d:IsA("BasePart") then 
                    p = d
                    break 
                end 
            end
            if p then 
                newAquarium.PrimaryPart = p 
            else 
                newAquarium:Destroy()
                continue 
            end
        end
        
        newAquarium:PivotTo(cframe)
        newAquarium.Parent = plotContainer
        table.insert(self.plots, newAquarium)
        table.insert(self.unownedPlots, newAquarium)
    end
end

function PlotService:RefreshPrompt(plot: Model, owner: Player)
    local promptInst = plot:FindFirstChild("PlotPrompt")
    if not promptInst then
        local newPrompt = Instance.new("ProximityPrompt")
        newPrompt.Name = "PlotPrompt"
        newPrompt.Parent = plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
        promptInst = newPrompt
    end
    
    local prompt = promptInst :: ProximityPrompt
    prompt.ObjectText = owner.Name .. "'s Aquarium"
    prompt.ActionText = "View Aquarium"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 15
    prompt.RequiresLineOfSight = false
    
    if not plot:GetAttribute("PromptConnected") then
        prompt.Triggered:Connect(function(player)
            InjectedRemoteService:SendToClient(player, "RequestEnterAquariumClient", plot, owner)
        end)
        plot:SetAttribute("PromptConnected", true)
    end
end

function PlotService:AssignPlotToPlayer(player: Player)
    if self.playerPlots[player] then return end
    
    if #self.unownedPlots > 0 then
        local randomIndex = math.random(#self.unownedPlots)
        local assignedPlot = self.unownedPlots[randomIndex]
        table.remove(self.unownedPlots, randomIndex)
        
        assignedPlot.Name = "Plot_" .. player.Name
        self.playerPlots[player] = assignedPlot
        self.plotOwners[assignedPlot] = player
        
        self:RefreshPrompt(assignedPlot, player)
        print(string.format("   -> [AssignPlot] Plot '%s' ditugaskan ke %s.", assignedPlot.Name, player.Name))
    end
end

function PlotService:UpdateAquariumModel(player: Player, currentPlot: Model?): Model?
    local playerData = InjectedDataService:Get(player)
    if not playerData then return currentPlot end 
    
    local level = playerData.AquariumLevel or 1
    local desiredModelName = "Aquarium_Lv" .. tostring(level)
    
    if not currentPlot then return nil end
    if currentPlot:GetAttribute("ModelName") == desiredModelName then return currentPlot end

    print(string.format("      -> [UpdateModel] Level pemain adalah %d. Mengganti dengan model '%s'.", level, desiredModelName))
    
    local assets = ReplicatedStorage:WaitForChild("assets")
    local models = assets:WaitForChild("models")
    local aquariumModelContainer = models:WaitForChild("M_Aquarium")
    local newAquariumAsset = aquariumModelContainer:FindFirstChild(desiredModelName) :: Model?
    
    if not newAquariumAsset then 
        warn(string.format("      -> GAGAL: Tidak dapat menemukan aset untuk %s.", desiredModelName))
        return currentPlot 
    end

    local oldPivot = currentPlot:GetPivot()
    local parent = currentPlot.Parent
    local name = currentPlot.Name
    
    local newPlot = newAquariumAsset:Clone()
    currentPlot:Destroy()
    
    newPlot.Name = name
    newPlot.Parent = parent
    
    if not newPlot.PrimaryPart then
        local p = nil
        for _, d in ipairs(newPlot:GetDescendants()) do 
            if d:IsA("BasePart") then 
                p = d
                break 
            end 
        end
        if p then 
            newPlot.PrimaryPart = p 
        else 
            newPlot:Destroy()
            return nil 
        end
    end
    
    newPlot:PivotTo(oldPivot)
    newPlot:SetAttribute("ModelName", desiredModelName)
    
    self.playerPlots[player] = newPlot
    self.plotOwners[newPlot] = player
    self:RefreshPrompt(newPlot, player)
    
    return newPlot
end

function PlotService:TeleportCharacterToPlot(character: Model, plot: Model)
    local primaryPart = plot.PrimaryPart
    if not primaryPart or not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return end
    
    local plotPos = primaryPart.Position
    local outVec = (plotPos - Vector3.new(0, plotPos.Y, 0)).Unit
    local tpPos = plotPos + (outVec * 20)
    local groundPos = Vector3.new(tpPos.X, GRASS_Y_LEVEL + 3, tpPos.Z)
    local tpCFrame = CFrame.lookAt(groundPos, plotPos)
    
    root:PivotTo(tpCFrame)
    print(string.format("      -> [Teleport] Karakter telah diteleportasi ke plot."))
end

return PlotService
