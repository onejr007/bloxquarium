--!strict
--[[
    @class ViewportManager (v1.3 - Visual Polish)
    - VISUAL FIX: Uses the model\'s geometric center (`GetBoundingBox().p`) for camera positioning instead of the model\'s pivot. This guarantees the model is always centered correctly.
    - VISUAL FIX: Increased the default scale factor slightly to make models appear larger and more prominent in the viewport.
    - NEW: Automatically sets `PrimaryPart` on the cloned model to its first child. While `GetBoundingBox` works without it, this is good practice and may help with other potential operations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [TYPE DEFINITION]
export type ViewportManager = {
    ClassName: string,
    GetModel: (self: ViewportManager, modelName: string) -> Model?,
    CreateModelViewport: (self: ViewportManager, parentFrame: GuiObject, modelName: string, rotation: number, scale: number) -> ViewportFrame
}

local ViewportManager: ViewportManager = {} :: any
ViewportManager.ClassName = "ViewportManager"

local modelCache = {}

function ViewportManager:GetModel(modelName: string): Model?
    if modelCache[modelName] then
        return modelCache[modelName]:Clone() :: Model
    end

    local assets = ReplicatedStorage:WaitForChild("assets")
    local models = assets:WaitForChild("models")
    
    local foundModel = nil
    for _, category in ipairs(models:GetChildren()) do
        if category:IsA("Folder") then
            foundModel = category:FindFirstChild(modelName, true)
            if foundModel then break end
        end
    end

    if foundModel and foundModel:IsA("Model") then
        modelCache[modelName] = foundModel
        return foundModel:Clone() :: Model
    else
        warn(string.format("⚠️ [ViewportManager] Model '%s' not found!", modelName))
        return nil
    end
end

function ViewportManager:CreateModelViewport(parentFrame: GuiObject, modelName: string, rotation: number, scale: number): ViewportFrame
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1, 0, 1, 0)
    viewport.BackgroundTransparency = 1
    viewport.Parent = parentFrame

    local camera = Instance.new("Camera")
    viewport.CurrentCamera = camera
    camera.Parent = viewport

    local model = self:GetModel(modelName)
    if not model then 
        return viewport 
    end
    model.Parent = viewport

    if not model.PrimaryPart and #model:GetChildren() > 0 then
        model.PrimaryPart = model:GetChildren()[1]
    end

    local boundingBoxCFrame, modelSize = model:GetBoundingBox()
    local center = boundingBoxCFrame.p 
    
    local maxDim = math.max(modelSize.X, modelSize.Y, modelSize.Z)
    local distance = (maxDim / math.tan(math.rad(camera.FieldOfView / 2))) * (scale or 1.5)

    local rotationCFrame = CFrame.Angles(0, math.rad(rotation or 0), 0)
    local cameraPosition = center + (rotationCFrame * Vector3.new(0, maxDim * 0.2, distance))
    
    camera.CFrame = CFrame.new(cameraPosition, center)

    return viewport
end

return ViewportManager
