--[[
    Building40_SiteGrounds.lua
    Site context for KMUTNB Building 40 / Building 77.

    Evidence-based layout notes:
    - Building 77 is beside a pedestrian bridge/canal-side public area.
    - The right-side elevator zone is described as next to Suan Palm/canal;
      the left-side elevator zone is described as next to the Faculty of Engineering.
    - The campus approach described by TGGS is: pass Buildings 21 and 46,
      cross the green pedestrian bridge, then turn right toward Building 77.

    IMPORTANT:
    The campus map does not provide surveyed dimensions. Coordinates below are
    gameplay-scale staging values relative to the existing building footprint,
    not claimed real-world measurements. No invented four-sided ring road or
    unsupported east/west parking lots are generated here.
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Building40_SiteGrounds = {}

local GROUND = Layout.GROUND_Y
local pathConcrete = Color3.fromRGB(211, 207, 194)
local grass = Color3.fromRGB(78, 119, 67)
local palmGreen = Color3.fromRGB(58, 111, 62)
local water = Color3.fromRGB(47, 105, 119)
local bridgeGreen = Color3.fromRGB(65, 132, 91)
local darkMetal = Color3.fromRGB(68, 74, 78)

local function slab(parent, name, size, position, color, material)
    return PartBuilder.makePart(
        parent,
        name,
        size,
        CFrame.new(position),
        color,
        material,
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

local function palm(parent, name, x, z, height)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent

    local trunkHeight = height
    PartBuilder.makeCylinder(
        model,
        "Trunk",
        Vector3.new(trunkHeight, 2.2, 2.2),
        CFrame.new(x, GROUND + trunkHeight / 2, z) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(117, 91, 61),
        Enum.Material.Wood
    )

    local crownY = GROUND + trunkHeight
    for i = 0, 5 do
        local angle = math.rad(i * 60)
        local dx = math.cos(angle) * 5.2
        local dz = math.sin(angle) * 5.2
        PartBuilder.makePart(
            model,
            "Frond_" .. (i + 1),
            Vector3.new(1.1, 0.35, 10.5),
            CFrame.new(x + dx / 2, crownY, z + dz / 2)
                * CFrame.Angles(0, -angle, math.rad(-18)),
            palmGreen,
            Enum.Material.Grass,
            { CanCollide = false }
        )
    end
    local crown = PartBuilder.makePart(
        model,
        "Crown",
        Vector3.new(3.2, 2.6, 3.2),
        CFrame.new(x, crownY - 0.8, z),
        Color3.fromRGB(67, 104, 55),
        Enum.Material.Grass
    )
    crown.Shape = Enum.PartType.Ball
end

local function streetLamp(parent, name, x, z)
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
        Vector3.new(4.2, 0.35, 0.35),
        CFrame.new(x + 1.8, GROUND + 12.6, z),
        darkMetal,
        Enum.Material.Metal
    )
    local lamp = PartBuilder.makePart(
        model,
        "Lamp",
        Vector3.new(1.8, 0.45, 1.1),
        CFrame.new(x + 3.2, GROUND + 12.3, z),
        Color3.fromRGB(255, 235, 190),
        Enum.Material.Neon,
        { CanCollide = false }
    )
    local light = Instance.new("PointLight")
    light.Range = 28
    light.Brightness = 0.65
    light.Color = Color3.fromRGB(255, 230, 185)
    light.Shadows = false
    light.Parent = lamp
end

function Building40_SiteGrounds.build(parent)
    local site = Instance.new("Model")
    site.Name = "Building40_SiteGrounds"
    site.Parent = parent

    -- A compact campus ground plane. The old 720 x 620 lawn implied an
    -- isolated building on an empty field and is intentionally removed.
    -- Split the ground plane around the canal so water is not hidden below grass.
    slab(site, "CampusGround_West", Vector3.new(575, 2, 760),
        Vector3.new(-102.5, GROUND - 1, 0), grass, Enum.Material.Grass)
    slab(site, "CampusGround_East", Vector3.new(571, 2, 760),
        Vector3.new(104.5, GROUND - 1, 0), grass, Enum.Material.Grass)

    -- Front approach: connect the existing Floor 2 grand stair landing to
    -- a pedestrian campus spine. +Z is the front used by the current map.
    local approach = Instance.new("Folder")
    approach.Name = "MainPedestrianApproach"
    approach.Parent = site
    path(approach, "GrandStairApron", -88, 88, 145, 205, 0.7)
    path(approach, "CampusWalkwayToFront", -18, 18, 204, 340, 0.45)
    path(approach, "FrontCrossWalk", -38, 38, 218, 226, 0.12)

    -- Canal-side public edge on the right side of the building, matching
    -- the published description of the right elevator zone beside the canal.
    local canal = Instance.new("Folder")
    canal.Name = "CanalSide"
    canal.Parent = site
    slab(
        canal,
        "CanalWater",
        Vector3.new(34, 0.8, 510),
        Vector3.new(202, GROUND + 0.35, 6),
        water,
        Enum.Material.Water
    )
    path(canal, "CanalWalkway_BuildingSide", 154, 174, -220, 238, 0.55)
    path(canal, "CanalWalkway_OuterSide", 226, 242, -220, 238, 0.55)

    -- Green pedestrian bridge crossing the canal, with simple rails.
    local bridge = Instance.new("Model")
    bridge.Name = "GreenPedestrianBridge"
    bridge.Parent = canal
    slab(
        bridge,
        "BridgeDeck",
        Vector3.new(88, 1.1, 13),
        Vector3.new(200, GROUND + 2.0, 34),
        bridgeGreen,
        Enum.Material.Concrete
    )
    for _, sideZ in ipairs({ 26.5, 41.5 }) do
        PartBuilder.makePart(
            bridge,
            "BridgeRail",
            Vector3.new(88, 3.0, 0.55),
            CFrame.new(200, GROUND + 4.0, sideZ),
            Color3.fromRGB(76, 119, 86),
            Enum.Material.Metal
        )
    end
    path(bridge, "BridgeApproach_West", 144, 156, 27, 41, 0.45)
    path(bridge, "BridgeApproach_East", 244, 258, 27, 41, 0.45)

    -- Suan Palm / shaded landscape zone on the canal side. Palm positions
    -- are decorative staging points, not surveyed tree coordinates.
    local garden = Instance.new("Folder")
    garden.Name = "SuanPalm_CanalGarden"
    garden.Parent = site
    slab(
        garden,
        "GardenBed",
        Vector3.new(118, 0.55, 190),
        Vector3.new(300, GROUND + 0.1, 6),
        Color3.fromRGB(88, 126, 67),
        Enum.Material.Grass
    )
    path(garden, "GardenWalkway", 244, 356, -94, 106, 0.4)
    for i, p in ipairs({
        { x = 264, z = -66, h = 18 },
        { x = 322, z = -58, h = 20 },
        { x = 278, z = 4, h = 17 },
        { x = 334, z = 34, h = 19 },
        { x = 260, z = 78, h = 18 },
        { x = 320, z = 88, h = 17 },
    }) do
        palm(garden, "Palm_" .. i, p.x, p.z, p.h)
    end

    -- Engineering-side context: low-detail massing only. It gives the
    -- player a campus edge rather than a second fabricated parking lot.
    -- Exact neighboring-building footprints/heights remain unverified.
    local engineeringSide = Instance.new("Folder")
    engineeringSide.Name = "EngineeringFaculty_ContextMass"
    engineeringSide.Parent = site
    slab(
        engineeringSide,
        "ContextBuildingMass",
        Vector3.new(118, 38, 176),
        Vector3.new(-252, GROUND + 19, -24),
        Color3.fromRGB(177, 178, 174),
        Enum.Material.Concrete
    )
    slab(
        engineeringSide,
        "ContextBuildingRoof",
        Vector3.new(122, 2, 180),
        Vector3.new(-252, GROUND + 39, -24),
        Color3.fromRGB(120, 124, 124),
        Enum.Material.Concrete
    )
    for floor = 1, 5 do
        local y = GROUND + 5 + (floor - 1) * 6.5
        for _, z in ipairs({ -92, -52, -12, 28, 68 }) do
            PartBuilder.makePart(
                engineeringSide,
                "ContextWindow",
                Vector3.new(0.35, 3.2, 24),
                CFrame.new(-192.7, y, z),
                Color3.fromRGB(105, 139, 153),
                Enum.Material.Glass,
                { CanCollide = false, Transparency = 0.18 }
            )
        end
    end
    path(engineeringSide, "EngineeringSideWalk", -194, -178, -178, 132, 0.45)

    -- Small landscape strips and lamps around the approach, avoiding a
    -- false road loop, invented flag plaza, and unsupported parking layout.
    local landscape = Instance.new("Folder")
    landscape.Name = "CampusLandscape"
    landscape.Parent = site
    for i, x in ipairs({ -70, -35, 35, 70 }) do
        palm(landscape, "FrontPalm_" .. i, x, 196, 15 + (i % 2) * 2)
    end
    for i, p in ipairs({
        { x = -42, z = 236 }, { x = 42, z = 236 },
        { x = 170, z = -150 }, { x = 170, z = 150 },
        { x = 246, z = -130 }, { x = 246, z = 142 },
    }) do
        streetLamp(landscape, "CampusLamp_" .. i, p.x, p.z)
    end

    print("[Site Grounds] Built evidence-led campus approach, canal edge, green pedestrian bridge, Suan Palm garden, and engineering-side context.")
end

return Building40_SiteGrounds
