--[[
    PartBuilder.lua
    โมดูลเครื่องมือสร้าง Part และฟังก์ชันคำนวณสัดส่วนตึก 40 ปี มจพ.
]]

local PartBuilder = {}

PartBuilder.STUDS_PER_METER = 2.5
PartBuilder.WIDTH = 54 * PartBuilder.STUDS_PER_METER   -- 135 studs
PartBuilder.LENGTH = 48 * PartBuilder.STUDS_PER_METER  -- 120 studs
PartBuilder.FLOOR_HEIGHT = 16
PartBuilder.FLOOR_COUNT = 11
PartBuilder.FLOOR1_Y = 4
PartBuilder.FRONT_Z = PartBuilder.LENGTH / 2
PartBuilder.REAR_Z = -PartBuilder.LENGTH / 2

PartBuilder.COLORS = {
    cream = Color3.fromRGB(232, 225, 211),
    creamLight = Color3.fromRGB(245, 239, 226),
    warmGrey = Color3.fromRGB(164, 161, 153),
    darkGrey = Color3.fromRGB(68, 72, 76),
    orange = Color3.fromRGB(202, 105, 54),
    orangeLight = Color3.fromRGB(224, 139, 78),
    maroon = Color3.fromRGB(126, 34, 43),
    glass = Color3.fromRGB(112, 162, 178),
    floor = Color3.fromRGB(218, 215, 207),
    tileLight = Color3.fromRGB(235, 232, 222),
    tileDark = Color3.fromRGB(207, 204, 195),
    wood = Color3.fromRGB(130, 91, 58),
    steel = Color3.fromRGB(176, 181, 183),
    green = Color3.fromRGB(57, 105, 69),
}

function PartBuilder.makePart(parent, name, size, cframe, color, material, properties)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color or PartBuilder.COLORS.cream
    part.Material = material or Enum.Material.Concrete
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CastShadow = true
    if properties then
        for key, value in pairs(properties) do
            part[key] = value
        end
    end
    part.Parent = parent
    return part
end

function PartBuilder.makeCylinder(parent, name, size, cframe, color, material, properties)
    local part = PartBuilder.makePart(parent, name, size, cframe, color, material, properties)
    part.Shape = Enum.PartType.Cylinder
    return part
end

function PartBuilder.floorY(floorNumber)
    return PartBuilder.FLOOR1_Y + (floorNumber - 1) * PartBuilder.FLOOR_HEIGHT
end

function PartBuilder.makeSign(parent, name, text, size, position, face, color)
    local sign = PartBuilder.makePart(
        parent,
        name,
        size,
        CFrame.new(position),
        color or PartBuilder.COLORS.maroon,
        Enum.Material.SmoothPlastic
    )
    sign.CanCollide = false

    local surface = Instance.new("SurfaceGui")
    surface.Name = "SignSurface"
    surface.Face = face or Enum.NormalId.Back
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 48
    surface.LightInfluence = 0
    surface.Parent = sign

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.Parent = surface
    return sign
end

function PartBuilder.addPointLight(parent, name, position, color, range, brightness)
    local mount = PartBuilder.makePart(
        parent,
        name .. "_Fixture",
        Vector3.new(3.2, 0.35, 1.2),
        CFrame.new(position),
        Color3.fromRGB(65, 66, 66),
        Enum.Material.Metal,
        { CanCollide = false }
    )
    local bulb = PartBuilder.makePart(
        parent,
        name .. "_Diffuser",
        Vector3.new(2.8, 0.12, 0.9),
        CFrame.new(position - Vector3.new(0, 0.22, 0)),
        color,
        Enum.Material.Neon,
        { CanCollide = false }
    )
    local light = Instance.new("PointLight")
    light.Name = name .. "_Light"
    light.Color = color
    light.Range = range
    light.Brightness = brightness
    light.Shadows = true
    light.Parent = bulb
    return mount
end

function PartBuilder.addWindow(parent, name, width, height, cframe, rotationY, properties)
    local rotation = CFrame.Angles(0, rotationY or 0, 0)
    local windowCanCollide = not (properties and properties.CanCollide == false)
    local glass = PartBuilder.makePart(
        parent,
        name .. "_Glass",
        Vector3.new(width, height, 0.45),
        cframe * rotation,
        PartBuilder.COLORS.glass,
        Enum.Material.Glass,
        {
            Transparency = properties and properties.Transparency or 0.35,
            Reflectance = properties and properties.Reflectance or 0.08,
            CanCollide = windowCanCollide,
        }
    )
    local frameColor = PartBuilder.COLORS.creamLight
    local frameDepth = 0.65
    PartBuilder.makePart(parent, name .. "_FrameTop", Vector3.new(width + 0.8, 0.45, frameDepth), cframe * CFrame.new(0, height / 2 + 0.2, 0) * rotation, frameColor, Enum.Material.Concrete, { CanCollide = windowCanCollide })
    PartBuilder.makePart(parent, name .. "_FrameBottom", Vector3.new(width + 0.8, 0.4, frameDepth), cframe * CFrame.new(0, -height / 2 - 0.2, 0) * rotation, frameColor, Enum.Material.Concrete, { CanCollide = windowCanCollide })
    PartBuilder.makePart(parent, name .. "_Mullion", Vector3.new(0.3, height, frameDepth), cframe * rotation, PartBuilder.COLORS.orange, Enum.Material.Metal, { CanCollide = windowCanCollide })
    return glass
end

function PartBuilder.addStairFlight(parent, lowerFloor, x, startZ)
    local startY = PartBuilder.floorY(lowerFloor)
    local steps = 14
    local run = 1.25
    local rise = PartBuilder.FLOOR_HEIGHT / steps
    local stairLength = (steps - 1) * run
    local direction = lowerFloor % 2 == 1 and -1 or 1
    startZ = lowerFloor % 2 == 1 and 25 or (25 - stairLength)
    for index = 1, steps do
        local stepY = startY + index * rise
        local stepZ = startZ + direction * index * run
        PartBuilder.makePart(
            parent,
            "Stair_F" .. lowerFloor .. "_Step_" .. index,
            Vector3.new(10, 0.9, run + 0.15),
            CFrame.new(x, stepY, stepZ),
            PartBuilder.COLORS.warmGrey,
            Enum.Material.Concrete
        )
    end

    local railLength = stairLength + 2
    local railCenterY = startY + PartBuilder.FLOOR_HEIGHT / 2 + 3.4
    local railCenterZ = startZ + direction * stairLength / 2
    local railAngle = math.atan(PartBuilder.FLOOR_HEIGHT / stairLength) * -direction
    for side = -1, 1, 2 do
        PartBuilder.makePart(
            parent,
            "Stair_F" .. lowerFloor .. "_Handrail_" .. side,
            Vector3.new(0.35, 0.45, railLength),
            CFrame.new(x + side * 5.1, railCenterY, railCenterZ) * CFrame.Angles(railAngle, 0, 0),
            PartBuilder.COLORS.darkGrey,
            Enum.Material.Metal
        )
    end

    PartBuilder.makePart(
        parent,
        "Stair_F" .. lowerFloor .. "_UpperLanding",
        Vector3.new(11, 1, 8),
        CFrame.new(x, startY + PartBuilder.FLOOR_HEIGHT - 0.4, startZ + direction * (stairLength + 3)),
        PartBuilder.COLORS.tileDark,
        Enum.Material.Concrete
    )
end

return PartBuilder
