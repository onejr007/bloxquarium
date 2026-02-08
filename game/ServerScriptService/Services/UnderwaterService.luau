--!strict
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UnderwaterService = {}
UnderwaterService.ServiceName = "UnderwaterService"

local UNDERWATER_POS = Vector3.new(5000, -100, 5000)

function UnderwaterService:Init(DataService, RemoteService)
    print("🌊 [UnderwaterService] Initializing Underwater World...")
    self.DataService = DataService
    self.RemoteService = RemoteService
    self.activeAquariums = {} -- {[Player] = Model}
    self:GenerateUnderwaterArea()
    
    self.RemoteService:Register("RequestEnterAquarium", function(player, plotModel)
        -- Logic handled in PlotService but we can listen here too or call from PlotService
    end)
end

function UnderwaterService:PrepareAquariumForPlayer(visitor: Player, owner: Player, plotModel: Model)
    -- This function no longer clones the plot model into the underwater sand
    -- because the underwater view is its own 2.5D context.
    print(string.format("🌊 [UnderwaterService] Preparing view for %s (Visiting %s)", visitor.Name, owner.Name))
end

function UnderwaterService:GenerateUnderwaterArea()
    local container = Instance.new("Folder")
    container.Name = "UnderwaterWorld"
    container.Parent = Workspace
    
    -- Shrink Box size: Narrower depth (Z) for true 2.5D/2D feeling
    local boxSize = Vector3.new(60, 35, 8)
    
    -- Floor (Sand/Gravel)
    local floor = Instance.new("Part")
    floor.Name = "UnderwaterFloor"
    floor.Size = Vector3.new(boxSize.X + 2, 1, boxSize.Z)
    floor.Position = UNDERWATER_POS - Vector3.new(0, 0.5, 0)
    floor.Anchored = true
    floor.Material = Enum.Material.Sand
    floor.Color = Color3.fromRGB(180, 170, 130)
    floor.Parent = container
    
    -- Background Wall (Large enough to cover camera frustum)
    local backWall = Instance.new("Part")
    backWall.Name = "BackgroundWall"
    backWall.Size = Vector3.new(boxSize.X + 40, boxSize.Y + 30, 1)
    backWall.Position = UNDERWATER_POS - Vector3.new(0, -boxSize.Y/2 + 5, boxSize.Z/2)
    backWall.Anchored = true
    backWall.Material = Enum.Material.Concrete
    backWall.Color = Color3.fromRGB(10, 35, 70)
    backWall.Parent = container
    
    local function createGlassWall(size, pos, transparency)
        local g = Instance.new("Part")
        g.Size = size
        g.Position = pos
        g.Anchored = true
        g.Material = Enum.Material.Glass
        g.Transparency = transparency or 0.9
        g.Color = Color3.fromRGB(150, 220, 255)
        g.CastShadow = false
        g.CanCollide = true
        g.Parent = container
        return g
    end
    
    -- Left & Right Walls
    createGlassWall(Vector3.new(1, boxSize.Y, boxSize.Z), UNDERWATER_POS + Vector3.new(boxSize.X/2, boxSize.Y/2, 0))
    createGlassWall(Vector3.new(1, boxSize.Y, boxSize.Z), UNDERWATER_POS + Vector3.new(-boxSize.X/2, boxSize.Y/2, 0))
    
    -- Front Wall (Facing camera)
    createGlassWall(Vector3.new(boxSize.X, boxSize.Y, 1), UNDERWATER_POS + Vector3.new(0, boxSize.Y/2, boxSize.Z/2), 0.95)
    
    -- Top/Ceiling
    createGlassWall(Vector3.new(boxSize.X, 1, boxSize.Z), UNDERWATER_POS + Vector3.new(0, boxSize.Y, 0), 0.9)

    -- Define Aquarium Bounds for 2D Logic (Invisible Part)
    local bounds = Instance.new("Part")
    bounds.Name = "AquariumBounds"
    bounds.Size = boxSize
    bounds.Position = UNDERWATER_POS + Vector3.new(0, boxSize.Y/2, 0)
    bounds.Anchored = true
    bounds.Transparency = 1
    bounds.CanCollide = false
    bounds.Parent = container
    
    -- Lighting
    local lightPart = Instance.new("Part")
    lightPart.Name = "LightSource"
    lightPart.Size = Vector3.new(1, 1, 1)
    lightPart.Position = UNDERWATER_POS + Vector3.new(0, boxSize.Y - 2, 0)
    lightPart.Anchored = true
    lightPart.Transparency = 1
    lightPart.CanCollide = false
    lightPart.Parent = container

    local light = Instance.new("PointLight")
    light.Range = 100
    light.Brightness = 3
    light.Color = Color3.fromRGB(100, 200, 255)
    light.Parent = lightPart
end

return UnderwaterService
