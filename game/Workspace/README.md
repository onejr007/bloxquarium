# Workspace

Folder ini berisi semua objects yang akan muncul di game world.

## Kegunaan:
- Models dan Parts
- Terrain modifications
- Spawn locations
- Interactive objects

## Contoh Penggunaan:

### Spawn Location
```lua
-- SpawnLocation.luau
-- Ini akan menjadi SpawnLocation di Workspace
return {
    $className = "SpawnLocation",
    $properties = {
        Anchored = true,
        Size = Vector3.new(4, 1, 4),
        Position = Vector3.new(0, 0.5, 0),
        BrickColor = BrickColor.new("Bright green"),
        TopSurface = Enum.SurfaceType.Smooth,
        BottomSurface = Enum.SurfaceType.Smooth
    }
}
```

### Interactive Part
```lua
-- InteractivePart.luau
-- Ini akan menjadi Part dengan script
return {
    $className = "Part",
    $properties = {
        Name = "InteractivePart",
        Anchored = true,
        Size = Vector3.new(4, 4, 4),
        Position = Vector3.new(10, 2, 0),
        BrickColor = BrickColor.new("Bright blue")
    },
    ClickDetector = {
        $className = "ClickDetector"
    },
    Script = {
        $className = "Script",
        Source = [[
            local part = script.Parent
            local clickDetector = part.ClickDetector
            
            clickDetector.MouseClick:Connect(function(player)
                print(player.Name .. " clicked the part!")
                part.BrickColor = BrickColor.random()
            end)
        ]]
    }
}
```

## Tips:
- Semua object di sini akan muncul di game world
- Bisa berisi Parts, Models, Scripts, dan object lainnya
- Gunakan untuk level design dan interactive elements