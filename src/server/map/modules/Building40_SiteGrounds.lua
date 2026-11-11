--[[
    Building40_SiteGrounds.lua
    Site grounds for KMUTNB Building 40 / Building 77.
    
    Realistic Campus Geography:
    1. ด้านหลังอาคาร (North / -Z side):
       - คลองบางเขนใหม่ (Khlong Bang Khen Mai) ไหลทอดยาวขนานด้านหลังตึก 40 ปี
       - มีเขื่อนคอนกรีตริมคลอง, ราวเหล็กกันตกสีเขียว, ทางเดินเลียบคลอง (Canal Promenade)
       - สะพานคนเดินข้ามคลอง (Green Pedestrian Bridge) เชื่อมไปยังฝั่งตรงข้าม
       - เสาไฟส่องสว่างริมคลอง และทางออกลานจอดรถด้านหลัง
    2. ด้านหน้าอาคาร (South / +Z side):
       - ลานสวนปาล์ม มจพ. (Suan Palm Plaza) ตั้งอยู่บริเวณด้านหน้าตึก 40 ปี
       - เชื่อมต่อกับบันไดใหญ่ขึ้นชั้น 2 โรงอาหาร (Grand Outdoor Stairs)
       - ลานกิจกรรมนักศึกษา, ทางเดินหินคอนกรีต, ต้นปาล์มจัดเรียงสวยงาม
    3. ด้านซ้าย (West / -X side):
       - เปิดโล่งโปร่งตา เป็นลานหญ้าและทางเดินรอบอาคาร (ลบอาคารจำลองทึบตันเดิมทิ้ง 100%)
    4. ด้านขวา (East / +X side):
       - ลานหญ้าและทางเดินเชื่อมต่อระหว่างด้านหน้าและทางเดินเลียบคลองด้านหลัง
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Building40_SiteGrounds = {}

local GROUND = Layout.GROUND_Y
local pathConcrete = Color3.fromRGB(218, 214, 204)
local pathStone    = Color3.fromRGB(195, 190, 180)
local grass        = Color3.fromRGB(72, 114, 62)
local palmGreen    = Color3.fromRGB(52, 108, 56)
local water        = Color3.fromRGB(42, 102, 118)
local bridgeGreen  = Color3.fromRGB(55, 120, 80)
local darkMetal    = Color3.fromRGB(55, 60, 65)
local concreteWall = Color3.fromRGB(190, 185, 175)

local function slab(parent, name, size, position, color, material)
    return PartBuilder.makePart(
        parent,
        name,
        size,
        CFrame.new(position),
        color,
        material or Enum.Material.Concrete,
        { Anchored = true }
    )
end

local function path(parent, name, minX, maxX, minZ, maxZ, widthY)
    return slab(
        parent,
        name,
        Vector3.new(maxX - minX, widthY or 0.5, maxZ - minZ),
        Vector3.new((minX + maxX) / 2, GROUND + (widthY or 0.5) / 2, (minZ + maxZ) / 2),
        pathConcrete,
        Enum.Material.Concrete
    )
end

local function palmTree(parent, name, x, z, height)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent

    local trunkH = height or 18
    PartBuilder.makeCylinder(
        model,
        "Trunk",
        Vector3.new(trunkH, 2.0, 2.0),
        CFrame.new(x, GROUND + trunkH / 2, z) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(115, 88, 58),
        Enum.Material.Wood
    )

    local crownY = GROUND + trunkH
    for i = 0, 7 do
        local angle = math.rad(i * 45)
        local dx = math.cos(angle) * 5.8
        local dz = math.sin(angle) * 5.8
        PartBuilder.makePart(
            model,
            "Frond_" .. (i + 1),
            Vector3.new(1.1, 0.35, 11.5),
            CFrame.new(x + dx / 2, crownY + 0.2, z + dz / 2)
                * CFrame.Angles(0, -angle, math.rad(-20)),
            palmGreen,
            Enum.Material.Grass,
            { CanCollide = false }
        )
    end
    local crown = PartBuilder.makePart(
        model,
        "Crown",
        Vector3.new(3.5, 2.8, 3.5),
        CFrame.new(x, crownY - 0.5, z),
        Color3.fromRGB(62, 98, 50),
        Enum.Material.Grass,
        { CanCollide = false }
    )
    crown.Shape = Enum.PartType.Ball
end

local function campusLamp(parent, name, x, z)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent

    PartBuilder.makePart(
        model,
        "Pole",
        Vector3.new(0.65, 13, 0.65),
        CFrame.new(x, GROUND + 6.5, z),
        darkMetal,
        Enum.Material.Metal
    )
    PartBuilder.makePart(
        model,
        "Arm",
        Vector3.new(3.6, 0.35, 0.35),
        CFrame.new(x + 1.5, GROUND + 12.6, z),
        darkMetal,
        Enum.Material.Metal
    )
    local lamp = PartBuilder.makePart(
        model,
        "Lamp",
        Vector3.new(1.6, 0.45, 1.0),
        CFrame.new(x + 2.8, GROUND + 12.3, z),
        Color3.fromRGB(255, 240, 200),
        Enum.Material.Neon,
        { CanCollide = false }
    )
    local light = Instance.new("PointLight")
    light.Range = 32
    light.Brightness = 0.85
    light.Color = Color3.fromRGB(255, 235, 195)
    light.Shadows = false
    light.Parent = lamp
end

function Building40_SiteGrounds.build(parent)
    local site = Instance.new("Model")
    site.Name = "Building40_SiteGrounds"
    site.Parent = parent

    ------------------------------------------------------------------
    -- 1. พื้นดินรอบอาคาร (Main Campus Ground Slabs)
    ------------------------------------------------------------------
    -- พื้นหลักหน้าตึกและข้างตึก (South of the canal, Z = -160 to +360)
    slab(site, "CampusGround_Main", Vector3.new(680, 2, 520),
        Vector3.new(0, GROUND - 1.0, 100), grass, Enum.Material.Grass)

    -- พื้นดินฝั่งตรงข้ามคลองด้านหลัง (North of the canal, Z = -200 to -340)
    slab(site, "CampusGround_NorthOfCanal", Vector3.new(680, 2, 140),
        Vector3.new(0, GROUND - 1.0, -270), grass, Enum.Material.Grass)

    -- ลานคอนกรีตรอบฐานตึก 40 ปี (Perimeter Apron around 300x240 building footprint)
    path(site, "BuildingApron_North", -160, 160, -145, -120, 0.5)
    path(site, "BuildingApron_South", -160, 160, 120, 145, 0.5)
    path(site, "BuildingApron_West",  -165, -150, -145, 145, 0.5)
    path(site, "BuildingApron_East",   150,  165, -145, 145, 0.5)

    ------------------------------------------------------------------
    -- 2. คลองบางเขนใหม่ ด้านหลังอาคาร 40 ปี (Canal Behind Building 40)
    ------------------------------------------------------------------
    local canal = Instance.new("Folder")
    canal.Name = "Canal_BehindBuilding"
    canal.Parent = site

    local canalCenterZ = -180
    local canalWidth   = 38
    local canalLength  = 680

    -- ผิวน้ำคลองบางเขนใหม่
    local canalWater = slab(
        canal,
        "CanalWater",
        Vector3.new(canalLength, 1.0, canalWidth),
        Vector3.new(0, GROUND - 0.4, canalCenterZ),
        water,
        Enum.Material.Water
    )
    canalWater.CanCollide = false
    canalWater.CanTouch = false
    canalWater.Transparency = 0.25

    -- ก้นคลอง (Canal Bed)
    slab(
        canal,
        "CanalBed",
        Vector3.new(canalLength, 1.2, canalWidth + 2),
        Vector3.new(0, GROUND - 2.8, canalCenterZ),
        Color3.fromRGB(38, 48, 52),
        Enum.Material.Concrete
    )

    -- เขื่อนคอนกรีตริมคลอง 2 ฝั่ง (South Bank & North Bank)
    local southBankZ = canalCenterZ + canalWidth / 2 + 1.2 -- ~ -159.8
    local northBankZ = canalCenterZ - canalWidth / 2 - 1.2 -- ~ -200.2

    slab(canal, "CanalRetainingWall_South", Vector3.new(canalLength, 3.2, 2.4),
        Vector3.new(0, GROUND + 0.6, southBankZ), concreteWall, Enum.Material.Concrete)
    slab(canal, "CanalRetainingWall_North", Vector3.new(canalLength, 3.2, 2.4),
        Vector3.new(0, GROUND + 0.6, northBankZ), concreteWall, Enum.Material.Concrete)

    -- ราวเหล็กกันตกริมคลองสีเขียว มจพ. ทั้ง 2 ฝั่ง
    for _, bz in ipairs({ southBankZ, northBankZ }) do
        PartBuilder.makePart(
            canal,
            "CanalSafetyRailing",
            Vector3.new(canalLength, 3.2, 0.6),
            CFrame.new(0, GROUND + 3.4, bz),
            bridgeGreen,
            Enum.Material.Metal
        )
    end

    -- ทางเดินเลียบคลองด้านหลังอาคาร (Canal Promenade)
    path(canal, "CanalPromenade_Back", -320, 320, -158, -144, 0.55)

    -- ทางเดินเลียบคลองฝั่งตรงข้าม
    path(canal, "CanalPromenade_Opposite", -320, 320, -214, -201, 0.55)

    -- สะพานคนเดินข้ามคลอง (Green Pedestrian Bridge over Canal)
    local bridge = Instance.new("Model")
    bridge.Name = "CanalPedestrianBridge"
    bridge.Parent = canal

    local bridgeX = 0
    local bridgeSpan = canalWidth + 8
    slab(
        bridge,
        "BridgeDeck",
        Vector3.new(14, 1.2, bridgeSpan),
        Vector3.new(bridgeX, GROUND + 1.8, canalCenterZ),
        pathConcrete,
        Enum.Material.Concrete
    )
    for _, sx in ipairs({ -1, 1 }) do
        PartBuilder.makePart(
            bridge,
            "BridgeHandrail",
            Vector3.new(0.6, 3.5, bridgeSpan),
            CFrame.new(bridgeX + sx * 6.7, GROUND + 4.0, canalCenterZ),
            bridgeGreen,
            Enum.Material.Metal
        )
    end
    -- ทางลาดขึ้นสะพาน 2 ฝั่ง
    path(bridge, "BridgeApproach_South", bridgeX - 7, bridgeX + 7, -162, -155, 0.8)
    path(bridge, "BridgeApproach_North", bridgeX - 7, bridgeX + 7, -205, -198, 0.8)

    -- เสาไฟส่องสว่างเลียบคลองด้านหลัง
    local canalLamps = Instance.new("Folder")
    canalLamps.Name = "CanalLamps"
    canalLamps.Parent = canal
    for _, lx in ipairs({ -260, -180, -90, 0, 90, 180, 260 }) do
        campusLamp(canalLamps, "CanalLamp_S_" .. lx, lx, -150)
        campusLamp(canalLamps, "CanalLamp_N_" .. lx, lx, -210)
    end

    ------------------------------------------------------------------
    -- 3. ด้านหน้าอาคาร: ลานสวนปาล์ม มจพ. (Suan Palm Plaza in FRONT of Building 40)
    ------------------------------------------------------------------
    local frontPlaza = Instance.new("Folder")
    frontPlaza.Name = "SuanPalm_FrontPlaza"
    frontPlaza.Parent = site

    -- ลานทางเดินหลักเชื่อมบันไดใหญ่หน้าตึก (Floor 2 Grand Stair Apron)
    path(frontPlaza, "GrandStairLandingPlaza", -95, 95, 142, 215, 0.6)

    -- ลานหินสวนปาล์ม มจพ. (Suan Palm Paver Slab)
    slab(
        frontPlaza,
        "SuanPalmGardenBed",
        Vector3.new(220, 0.5, 100),
        Vector3.new(0, GROUND + 0.1, 265),
        Color3.fromRGB(80, 120, 68),
        Enum.Material.Grass
    )

    -- ทางเดินผ่ากลางสวนปาล์มสู่ทางเข้าหน้ามหาวิทยาลัย
    path(frontPlaza, "CentralPalmBoulevard", -20, 20, 214, 350, 0.5)
    path(frontPlaza, "EastPalmWalkway", 85, 115, 214, 320, 0.45)
    path(frontPlaza, "WestPalmWalkway", -115, -85, 214, 320, 0.45)
    path(frontPlaza, "CrossPalmConnector", -115, 115, 260, 275, 0.4)

    -- แนวต้นปาล์ม มจพ. ด้านหน้าอาคาร 40 ปี (จัดวางเป็นคู่แนวทางเดินสวยงามตามจริง)
    local palmPositions = {
        -- ฝั่งซ้ายของลานหน้าตึก
        { x = -75, z = 160, h = 18 },
        { x = -75, z = 195, h = 19 },
        { x = -75, z = 235, h = 20 },
        { x = -75, z = 280, h = 18 },
        { x = -40, z = 245, h = 17 },
        { x = -40, z = 290, h = 19 },

        -- ฝั่งขวาของลานหน้าตึก
        { x = 75, z = 160, h = 18 },
        { x = 75, z = 195, h = 19 },
        { x = 75, z = 235, h = 20 },
        { x = 75, z = 280, h = 18 },
        { x = 40, z = 245, h = 17 },
        { x = 40, z = 290, h = 19 },
    }
    for idx, p in ipairs(palmPositions) do
        palmTree(frontPlaza, "SuanPalm_" .. idx, p.x, p.z, p.h)
    end

    -- เสาไฟลานหน้าตึก
    for _, pos in ipairs({
        { x = -30, z = 175 }, { x = 30, z = 175 },
        { x = -30, z = 225 }, { x = 30, z = 225 },
        { x = -90, z = 225 }, { x = 90, z = 225 },
        { x = -30, z = 330 }, { x = 30, z = 330 },
    }) do
        campusLamp(frontPlaza, "PlazaLamp_" .. pos.x .. "_" .. pos.z, pos.x, pos.z)
    end

    ------------------------------------------------------------------
    -- 4. ทางเดินรอบอาคารฝั่งซ้ายและขวา (เชื่อมหน้า-หลังตึก)
    ------------------------------------------------------------------
    local perimeter = Instance.new("Folder")
    perimeter.Name = "PerimeterWalkways"
    perimeter.Parent = site

    -- ทางเดินฝั่งซ้าย (West Walkway: X = -180, Z = -150..+150) — โปร่งโล่ง ไม่มีตึกบัง!
    path(perimeter, "WestPerimeterWalk", -190, -172, -150, 150, 0.45)

    -- ทางเดินฝั่งขวา (East Walkway: X = +180, Z = -150..+150)
    path(perimeter, "EastPerimeterWalk", 172, 190, -150, 150, 0.45)

    print("[Site Grounds] Built realistic KMUTNB campus: Canal behind building, Suan Palm plaza in front, and unobstructed lateral grounds.")
end

return Building40_SiteGrounds
