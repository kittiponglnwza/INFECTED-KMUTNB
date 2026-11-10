--[[
    PartBuilder.lua
    โมดูลเครื่องมือสร้าง Part และฟังก์ชันคำนวณสัดส่วนอาคาร 40 ปี มจพ. (อาคาร 77)
    Shared geometry helpers for the Building 40 map (legacy constants aligned to Building40Layout)
]]

local PartBuilder = {}

-- Legacy geometry constants retained for helper callers. Keep these aligned
-- with Building40Layout; these are Roblox gameplay-scale studs, not surveyed metres.
PartBuilder.WIDTH = 300
PartBuilder.LENGTH = 240
PartBuilder.FLOOR_HEIGHT = 22
PartBuilder.FLOOR_COUNT = 12
PartBuilder.FLOOR1_Y = 1
PartBuilder.FRONT_Z = PartBuilder.LENGTH / 2
PartBuilder.REAR_Z = -PartBuilder.LENGTH / 2

-- โทนสีและวัสดุเอกลักษณ์ มหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ (มจพ.)
PartBuilder.COLORS = {
    cream = Color3.fromRGB(235, 230, 218),           -- สีปูนเปลือกอาคาร มจพ.
    creamLight = Color3.fromRGB(246, 242, 232),      -- สีผนังภายใน / เพดาน
    warmGrey = Color3.fromRGB(165, 162, 155),        -- สีเสาคอนกรีต / บันได
    darkGrey = Color3.fromRGB(68, 72, 78),           -- สีกรอบหน้าต่าง / เฟรมเหล็ก
    orange = Color3.fromRGB(225, 110, 40),           -- สีแสด มจพ. (KMUTNB Orange)
    orangeLight = Color3.fromRGB(240, 145, 75),      -- สีแสดสว่าง
    maroon = Color3.fromRGB(128, 28, 38),            -- สีแดงเลือดหมู มจพ. (KMUTNB Maroon)
    glass = Color3.fromRGB(115, 165, 180),           -- สีกระจกเขียวตัดแสง
    floor = Color3.fromRGB(220, 218, 210),           -- สีพื้นคอนกรีตขัดมัน
    tileLight = Color3.fromRGB(238, 236, 228),       -- สีแกรนิตโต้ปูพื้นสว่าง
    tileDark = Color3.fromRGB(205, 202, 192),        -- สีกระเบื้องเข้มตัดขอบ
    wood = Color3.fromRGB(135, 92, 55),              -- สีไม้ธรรมชาติ
    steel = Color3.fromRGB(178, 182, 185),           -- สแตนเลส / ประตูลิฟต์
    green = Color3.fromRGB(55, 105, 65),             -- สีใบไม้ / ป้ายปลอดภัย
    bblBlue = Color3.fromRGB(0, 52, 138),            -- สีน้ำเงินธนาคารกรุงเทพ (BBL Blue)
    bblNavy = Color3.fromRGB(0, 32, 90),             -- สีน้ำเงินเข้มเคาน์เตอร์
    scbPurple = Color3.fromRGB(78, 42, 132),         -- สีม่วงไทยพาณิชย์ (ตู้ ATM)
    kbankGreen = Color3.fromRGB(18, 136, 68),        -- สีเขียวกสิกรไทย (ตู้ ATM)
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

function PartBuilder.makeWedge(parent, name, size, cframe, color, material, properties)
    local part = Instance.new("WedgePart")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color or PartBuilder.COLORS.warmGrey
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

function PartBuilder.floorY(floorNumber)
    return PartBuilder.FLOOR1_Y + (floorNumber - 1) * PartBuilder.FLOOR_HEIGHT
end

function PartBuilder.makeSign(parent, name, text, size, position, face, color, textColor)
    local sign = PartBuilder.makePart(
        parent,
        name,
        size,
        CFrame.new(position),
        color or PartBuilder.COLORS.maroon,
        Enum.Material.SmoothPlastic
    )
    sign.CanCollide = false
    sign.CanQuery = false
    sign.CanTouch = false

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
    label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
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
        Vector3.new(3.6, 0.35, 1.4),
        CFrame.new(position),
        Color3.fromRGB(65, 68, 72),
        Enum.Material.Metal,
        { CanCollide = false, CanQuery = false, CanTouch = false }
    )
    local bulb = PartBuilder.makePart(
        parent,
        name .. "_Diffuser",
        Vector3.new(3.2, 0.12, 1.0),
        CFrame.new(position - Vector3.new(0, 0.22, 0)),
        color or Color3.fromRGB(255, 250, 240),
        Enum.Material.Neon,
        { CanCollide = false, CanQuery = false, CanTouch = false }
    )
    local light = Instance.new("PointLight")
    light.Name = name .. "_Light"
    light.Color = color or Color3.fromRGB(255, 250, 240)
    light.Range = range or 24
    light.Brightness = brightness or 1.2
    light.Shadows = true
    light.Parent = bulb
    return mount
end

return PartBuilder
