--!strict
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UnderwaterService = {}
UnderwaterService.ServiceName = "UnderwaterService"

local UNDERWATER_POS = Vector3.new(5000, -82.5, 5000)

function UnderwaterService:Init(DataService, RemoteService)
    print("🌊 [UnderwaterService] Initializing...")
    self.DataService = DataService
    self.RemoteService = RemoteService
    self.activeAquariums = {} -- {[Player] = Model}
    
    self.RemoteService:Register("RequestEnterAquarium", function(player, plotModel)
        -- Logic handled in PlotService but we can listen here too or call from PlotService
    end)
end

function UnderwaterService:PrepareAquariumForPlayer(visitor: Player, owner: Player, plotModel: Model)
    -- This function no longer clones the plot model into the underwater sand
    -- because the underwater view is its own 2.5D context.
    print(string.format("🌊 [UnderwaterService] Preparing view for %s (Visiting %s)", visitor.Name, owner.Name))
end

function UnderwaterService:GetAquariumBounds()
    local boxSize = Vector3.new(60, 35, 8)
    return UNDERWATER_POS, boxSize
end

return UnderwaterService
