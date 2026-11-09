--[[
    Building40_SiteGrounds.lua
    พื้นที่รอบตัวอาคาร 40 ปี มจพ. (อาคาร 77) — ถนนวงรอบตึก ทางเท้า สนามหญ้า ลานจอดรถกลางแจ้ง
    และลานจอดมอเตอร์ไซค์ เชื่อมกับลานจอดรถขับทะลุชั้น 1 (Floor1_Lobby.lua) ทั้งฝั่งขวาและฝั่งซ้าย

    ผังพื้นที่ (ตัวตึก X = -150..+150, Z = -120..+120):
      - ถนนฝั่งขวา (X = +160..+204) และถนนฝั่งซ้าย (X = -204..-160) วิ่งยาวตลอดแนวตึก
      - ถนนหลังตึก (Z = -174..-130) และถนนหน้าตึก (Z = +214..+254) เชื่อมเป็นถนนวงรอบตึก
      - ทางลาดรถ (Driveway Apron) X = ±150..±160, Z = -44..+44 ต่อจากช่องทางเข้า-ออกลานจอดรถชั้น 1
      - ลานจอดรถกลางแจ้งฝั่งขวา (X = +214..+290) และลานจอดมอเตอร์ไซค์มีหลังคาฝั่งซ้าย (X = -290..-214)
      - ลานเสาธงและป้ายมหาวิทยาลัยหน้าตึก, เสาไฟถนน, ทางม้าลาย, เส้นจราจร
    ระดับพื้น: ถนน/ทางลาด = Y 1.0 (เสมอพื้นชั้น 1), ทางเท้า = Y 1.35, สนามหญ้า = Y 0.8
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local CarBuilder = require(script.Parent.Parent.utils.CarBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Building40_SiteGrounds = {}

local ROAD_TOP = Layout.GROUND_Y     -- 1.0
local WALK_TOP = ROAD_TOP + 0.35     -- 1.35
local GRASS_TOP = ROAD_TOP - 0.2     -- 0.8

local asphaltCol = Color3.fromRGB(58, 60, 64)
local walkCol = Color3.fromRGB(205, 200, 190)
local paintWhite = Color3.fromRGB(240, 240, 240)
local paintYellow = Color3.fromRGB(255, 205, 30)
local praduRed = Color3.fromRGB(138, 30, 42)

-- กล่องจากขอบเขต min/max (ใช้ง่ายกับผังพิกัด)
local function slab(parent, name, minX, maxX, minZ, maxZ, top, thick, color, material)
    local sx, sz = maxX - minX, maxZ - minZ
    return PartBuilder.makePart(parent, name, Vector3.new(sx, thick, sz),
        CFrame.new((minX + maxX) / 2, top - thick / 2, (minZ + maxZ) / 2), color, material)
end

local function road(parent, name, minX, maxX, minZ, maxZ)
    return slab(parent, name, minX, maxX, minZ, maxZ, ROAD_TOP, 1.0, asphaltCol, Enum.Material.Asphalt)
end

local function walk(parent, name, minX, maxX, minZ, maxZ)
    return slab(parent, name, minX, maxX, minZ, maxZ, WALK_TOP, 1.35, walkCol, Enum.Material.Concrete)
end

local function paint(parent, name, size, x, z, color)
    return PartBuilder.makePart(parent, name, Vector3.new(size.X, 0.03, size.Y),
        CFrame.new(x, ROAD_TOP + 0.015, z), color, Enum.Material.SmoothPlastic, { CanCollide = false })
end

local function buildStreetLight(parent, name, x, z, armDirX, armDirZ)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent
    local poleH = 20
    local steel = Color3.fromRGB(95, 100, 108)
    PartBuilder.makePart(m, "Pole", Vector3.new(0.8, poleH, 0.8),
        CFrame.new(x, WALK_TOP + poleH / 2, z), steel, Enum.Material.Metal)
    PartBuilder.makePart(m, "PoleBase", Vector3.new(1.6, 1.0, 1.6),
        CFrame.new(x, WALK_TOP + 0.5, z), steel, Enum.Material.Metal)
    local armLen = 6
    local ax, az = x + armDirX * armLen / 2, z + armDirZ * armLen / 2
    PartBuilder.makePart(m, "Arm", Vector3.new(math.abs(armDirX) * armLen + 0.5, 0.5, math.abs(armDirZ) * armLen + 0.5),
        CFrame.new(ax, WALK_TOP + poleH - 0.25, az), steel, Enum.Material.Metal)
    local hx, hz = x + armDirX * armLen, z + armDirZ * armLen
    PartBuilder.makePart(m, "LampHead", Vector3.new(2.2, 0.6, 2.2),
        CFrame.new(hx, WALK_TOP + poleH - 0.6, hz), Color3.fromRGB(60, 64, 70), Enum.Material.Metal)
    local bulb = PartBuilder.makePart(m, "LampDiffuser", Vector3.new(1.8, 0.15, 1.8),
        CFrame.new(hx, WALK_TOP + poleH - 0.95, hz), Color3.fromRGB(255, 240, 200), Enum.Material.Neon,
        { CanCollide = false })
    local light = Instance.new("PointLight")
    light.Range = 42
    light.Brightness = 0.9
    light.Color = Color3.fromRGB(255, 235, 200)
    light.Shadows = false
    light.Parent = bulb
end

local function buildMotorbike(parent, name, x, z, yawDeg, color)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent
    local base = CFrame.new(x, ROAD_TOP, z) * CFrame.Angles(0, math.rad(yawDeg), 0)
    PartBuilder.makePart(m, "Body", Vector3.new(1.2, 1.3, 4.6), base * CFrame.new(0, 2.0, 0), color, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(m, "Seat", Vector3.new(1.1, 0.4, 2.2), base * CFrame.new(0, 2.85, 0.6), Color3.fromRGB(25, 25, 28), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(m, "Handlebar", Vector3.new(2.4, 0.2, 0.2), base * CFrame.new(0, 3.6, -1.9), Color3.fromRGB(40, 42, 46), Enum.Material.Metal)
    PartBuilder.makePart(m, "FrontFork", Vector3.new(0.3, 2.2, 0.3), base * CFrame.new(0, 2.5, -1.95), Color3.fromRGB(170, 175, 182), Enum.Material.Metal)
    for _, wz in ipairs({ -1.9, 1.9 }) do
        PartBuilder.makeCylinder(m, "Wheel", Vector3.new(0.5, 2.0, 2.0), base * CFrame.new(0, 1.0, wz),
            Color3.fromRGB(28, 28, 30), Enum.Material.SmoothPlastic)
    end
end

function Building40_SiteGrounds.build(parent)
    local site = Instance.new("Model")
    site.Name = "Building40_SiteGrounds"
    site.Parent = parent

    ------------------------------------------------------------------
    -- 1. สนามหญ้าฐานรอบพื้นที่อาคาร (X = -360..+360, Z = -300..+320)
    ------------------------------------------------------------------
    slab(site, "CampusLawn", -360, 360, -300, 320, GRASS_TOP, 1.0, Color3.fromRGB(92, 140, 70), Enum.Material.Grass)

    ------------------------------------------------------------------
    -- 2. ถนนวงรอบตึก + ทางลาดเข้า-ออกลานจอดรถชั้น 1 (ระดับเดียวกับพื้นชั้น 1 รถขับทะลุได้)
    ------------------------------------------------------------------
    local roads = Instance.new("Folder")
    roads.Name = "RingRoads"
    roads.Parent = site

    road(roads, "EastRoad",  160,  204, -174, 254)
    road(roads, "WestRoad", -204, -160, -174, 254)
    road(roads, "RearRoad", -160,  160, -174, -130)
    road(roads, "FrontRoad", -160, 160,  214,  254)
    road(roads, "DrivewayApron_East",  150,  160, -44, 44)
    road(roads, "DrivewayApron_West", -160, -150, -44, 44)
    -- ทางเข้าลานจอดรถกลางแจ้ง (ฝั่งขวา) และลานจอดมอเตอร์ไซค์ (ฝั่งซ้าย)
    road(roads, "LotApron_East_N",  204,  214, -110, -70)
    road(roads, "LotApron_East_S",  204,  214,   70, 110)
    road(roads, "BikeLotApron_West", -214, -204, -20, 20)

    -- เส้นประกึ่งกลางถนน (เหลือง) — ถนนฝั่งขวา/ซ้ายวิ่งแนว Z, ถนนหน้า/หลังวิ่งแนว X
    for z = -168, 248, 12 do
        paint(roads, "CenterDash_E", Vector2.new(0.5, 6), 182, z, paintYellow)
        paint(roads, "CenterDash_W", Vector2.new(0.5, 6), -182, z, paintYellow)
    end
    for x = -154, 154, 12 do
        paint(roads, "CenterDash_Rear", Vector2.new(6, 0.5), x, -152, paintYellow)
        paint(roads, "CenterDash_Front", Vector2.new(6, 0.5), x, 234, paintYellow)
    end

    -- เส้นหยุด + คำว่า "หยุด/STOP" ที่ทางออกลานจอดรถทั้ง 2 ฝั่ง
    for _, g in ipairs({ { x = 157, tag = "East" }, { x = -157, tag = "West" } }) do
        paint(roads, "StopLine_" .. g.tag, Vector2.new(0.8, 40), g.x, 0, paintWhite)
        PartBuilder.makeSign(roads, "StopText_" .. g.tag, "หยุด  STOP", Vector3.new(4.0, 0.02, 14),
            Vector3.new(g.x + (g.x > 0 and -3.5 or 3.5), ROAD_TOP + 0.04, g.x > 0 and -8 or 8), Enum.NormalId.Top,
            asphaltCol, paintWhite)
    end

    -- ทางม้าลาย: หน้าตึก (ข้ามถนนหน้าตึกไปลานเสาธง) และหน้าธนาคาร (ข้ามถนนฝั่งขวา)
    for x = -12, 12, 4.8 do
        paint(roads, "Zebra_Front", Vector2.new(2.4, 38), x, 234, paintWhite)
    end
    for z = 118, 138, 4.8 do
        paint(roads, "Zebra_East", Vector2.new(42, 2.4), 182, z, paintWhite)
    end

    ------------------------------------------------------------------
    -- 3. ทางเท้ารอบตึกและริมถนน (ยกขอบ 0.35 studs)
    ------------------------------------------------------------------
    local walks = Instance.new("Folder")
    walks.Name = "Sidewalks"
    walks.Parent = site

    -- ทางเท้าชิดตึก (เว้นช่องทางลาดรถที่ Z = -44..+44)
    walk(walks, "InnerWalk_East_N",  150,  160, -130, -44)
    walk(walks, "InnerWalk_East_S",  150,  160,   44, 214)
    walk(walks, "InnerWalk_West_N", -160, -150, -130, -44)
    walk(walks, "InnerWalk_West_S", -160, -150,   44, 214)
    walk(walks, "InnerWalk_Rear",   -150,  150, -130, -120)
    walk(walks, "InnerWalk_Front",  -150,  150,  210,  214)

    -- ทางเท้าริมนอกถนน (เว้นช่องทางเข้าลานจอดรถกลางแจ้ง / ลานมอเตอร์ไซค์)
    walk(walks, "OuterWalk_East_1",  204,  214, -184, -110)
    walk(walks, "OuterWalk_East_2",  204,  214,  -70,   70)
    walk(walks, "OuterWalk_East_3",  204,  214,  110,  264)
    walk(walks, "OuterWalk_West_1", -214, -204, -184,  -20)
    walk(walks, "OuterWalk_West_2", -214, -204,   20,  264)
    walk(walks, "OuterWalk_Rear",   -204,  204, -184, -174)
    walk(walks, "OuterWalk_Front",  -204,  204,  254,  264)

    -- เสากั้นสีเหลือง (Bollards) ขนาบทางลาดเข้าลานจอดรถชั้น 1
    for _, bx in ipairs({ 152, 158, -152, -158 }) do
        for _, bz in ipairs({ -46, 46 }) do
            PartBuilder.makeCylinder(walks, "Bollard", Vector3.new(3.0, 0.9, 0.9),
                CFrame.new(bx, WALK_TOP + 1.5, bz) * CFrame.Angles(0, 0, math.rad(90)),
                paintYellow, Enum.Material.SmoothPlastic)
        end
    end

    ------------------------------------------------------------------
    -- 4. ลานจอดรถกลางแจ้งฝั่งขวา (X = +214..+290, Z = -150..+150)
    ------------------------------------------------------------------
    local lot = Instance.new("Folder")
    lot.Name = "OutdoorCarPark_East"
    lot.Parent = site

    road(lot, "LotAsphalt", 214, 290, -150, 150)
    walk(lot, "LotCurb_East",  290, 296, -156, 156)
    walk(lot, "LotCurb_North", 214, 290, -156, -150)
    walk(lot, "LotCurb_South", 214, 290,  150,  156)

    local carIdx = 0
    for z = -144, 144, 12 do
        local cz = z + 6
        local inEntrance = (cz > -112 and cz < -68) or (cz > 68 and cz < 112)
        -- แถวช่องจอดฝั่งตะวันตก (X = 214..232) — เว้นช่วงทางเข้า
        if not inEntrance then
            paint(lot, "Stripe_W", Vector2.new(18, 0.5), 223, z, paintWhite)
            if cz < 144 then
                PartBuilder.makePart(lot, "WheelStop_W", Vector3.new(1.2, 0.6, 7.0),
                    CFrame.new(216.5, ROAD_TOP + 0.3, cz), paintYellow, Enum.Material.Concrete)
            end
        end
        -- แถวช่องจอดฝั่งตะวันออก (X = 272..290)
        paint(lot, "Stripe_E", Vector2.new(18, 0.5), 281, z, paintWhite)
        if cz < 150 then
            PartBuilder.makePart(lot, "WheelStop_E", Vector3.new(1.2, 0.6, 7.0),
                CFrame.new(287.5, ROAD_TOP + 0.3, cz), paintYellow, Enum.Material.Concrete)
        end

        -- รถจอดตกแต่งบางช่อง
        if cz < 150 then
            carIdx += 1
            if (carIdx % 3 == 1) and not inEntrance then
                CarBuilder.buildParkedCar(lot, "LotCar_W_" .. carIdx, 224, ROAD_TOP, cz, 90,
                    CarBuilder.CAR_COLORS[(carIdx - 1) % #CarBuilder.CAR_COLORS + 1])
            end
            if carIdx % 4 == 2 then
                CarBuilder.buildParkedCar(lot, "LotCar_E_" .. carIdx, 280, ROAD_TOP, cz, -90,
                    CarBuilder.CAR_COLORS[(carIdx + 2) % #CarBuilder.CAR_COLORS + 1])
            end
        end
    end
    -- ลูกศรทางวิ่งในลานจอด
    for _, az in ipairs({ -40, 40 }) do
        PartBuilder.makeSign(lot, "LotArrow", "↑  ↓", Vector3.new(6, 0.02, 10),
            Vector3.new(252, ROAD_TOP + 0.04, az), Enum.NormalId.Top, asphaltCol, paintWhite)
    end
    PartBuilder.makeSign(lot, "LotSign", "🅿 ลานจอดรถกลางแจ้ง อาคาร 40 ปี\nOUTDOOR CAR PARK", Vector3.new(0.4, 4.0, 18),
        Vector3.new(214.5, WALK_TOP + 7, -122), Enum.NormalId.Left, Color3.fromRGB(20, 80, 160), paintWhite)
    PartBuilder.makePart(lot, "LotSignPost", Vector3.new(0.6, 9, 0.6),
        CFrame.new(214.5, WALK_TOP + 4.5, -122), Color3.fromRGB(95, 100, 108), Enum.Material.Metal)

    ------------------------------------------------------------------
    -- 5. ลานจอดมอเตอร์ไซค์มีหลังคาฝั่งซ้าย (X = -290..-214, Z = -50..+50)
    ------------------------------------------------------------------
    local bikeLot = Instance.new("Folder")
    bikeLot.Name = "MotorcycleShelter_West"
    bikeLot.Parent = site

    road(bikeLot, "BikeLotPad", -290, -214, -50, 50)
    local roofY = ROAD_TOP + 12
    for _, px in ipairs({ -284, -220 }) do
        for _, pz in ipairs({ -44, 0, 44 }) do
            PartBuilder.makePart(bikeLot, "ShelterPost", Vector3.new(1.0, 12, 1.0),
                CFrame.new(px, ROAD_TOP + 6, pz), Color3.fromRGB(95, 100, 108), Enum.Material.Metal)
        end
    end
    PartBuilder.makePart(bikeLot, "ShelterRoof", Vector3.new(72, 0.6, 96),
        CFrame.new(-252, roofY + 0.3, 0), Color3.fromRGB(70, 110, 150), Enum.Material.CorrodedMetal)
    PartBuilder.makePart(bikeLot, "ShelterFascia", Vector3.new(72.4, 1.6, 0.4),
        CFrame.new(-252, roofY - 0.5, -48.2), praduRed, Enum.Material.SmoothPlastic)
    PartBuilder.makeSign(bikeLot, "BikeLotSign", "🏍 ที่จอดรถจักรยานยนต์\nMOTORCYCLE PARKING", Vector3.new(0.4, 3.2, 20),
        Vector3.new(-214.6, roofY - 2.2, -30), Enum.NormalId.Right, praduRed, paintWhite)
    local bikeColors = { Color3.fromRGB(200, 30, 35), Color3.fromRGB(25, 25, 28), Color3.fromRGB(235, 235, 238), Color3.fromRGB(30, 90, 180) }
    local bIdx = 0
    for z = -40, 40, 6 do
        for _, row in ipairs({ { x = -276, yaw = 90 }, { x = -242, yaw = -90 } }) do
            bIdx += 1
            if bIdx % 5 ~= 0 then
                buildMotorbike(bikeLot, "Motorbike_" .. bIdx, row.x, z, row.yaw, bikeColors[(bIdx - 1) % #bikeColors + 1])
            end
        end
    end

    ------------------------------------------------------------------
    -- 6. ลานเสาธงและป้ายมหาวิทยาลัยหน้าตึก (หลังถนนหน้าตึก Z = +264..+310)
    ------------------------------------------------------------------
    local flagPlaza = Instance.new("Folder")
    flagPlaza.Name = "FlagPlaza_Front"
    flagPlaza.Parent = site

    walk(flagPlaza, "FlagPlazaPaving", -40, 40, 264, 300)
    local function buildFlag(x, stripes)
        local poleH = 36
        PartBuilder.makeCylinder(flagPlaza, "FlagPole", Vector3.new(poleH, 0.6, 0.6),
            CFrame.new(x, WALK_TOP + poleH / 2, 290) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(225, 228, 232), Enum.Material.Metal)
        local flagW, flagH = 12, 8
        local yTop = WALK_TOP + poleH - 1
        local total = 0
        for _, s in ipairs(stripes) do total += s.h end
        local cursor = yTop
        for i, s in ipairs(stripes) do
            local h = flagH * s.h / total
            PartBuilder.makePart(flagPlaza, "FlagStripe_" .. i, Vector3.new(flagW, h, 0.15),
                CFrame.new(x + 0.4 + flagW / 2, cursor - h / 2, 290), s.c, Enum.Material.Fabric)
            cursor -= h
        end
    end
    local red, white, blue = Color3.fromRGB(200, 25, 40), Color3.fromRGB(245, 245, 245), Color3.fromRGB(30, 40, 110)
    buildFlag(-24, { { c = red, h = 1 }, { c = white, h = 1 }, { c = blue, h = 2 }, { c = white, h = 1 }, { c = red, h = 1 } }) -- ธงชาติไทย
    buildFlag(-6,  { { c = Color3.fromRGB(240, 200, 40), h = 1 } })                                                              -- ธงพระราชา (เหลือง)
    buildFlag(12,  { { c = praduRed, h = 3 }, { c = Color3.fromRGB(250, 250, 250), h = 1 } })                                  -- ธงมหาวิทยาลัย (สีแดงหมากสุก)

    PartBuilder.makePart(flagPlaza, "UniversityMonumentBase", Vector3.new(40, 2.0, 4),
        CFrame.new(-90, WALK_TOP + 1.0, 290), Color3.fromRGB(60, 62, 68), Enum.Material.Granite)
    PartBuilder.makeSign(flagPlaza, "UniversityMonumentSign",
        "มหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ\nKING MONGKUT'S UNIVERSITY OF TECHNOLOGY NORTH BANGKOK",
        Vector3.new(38, 6.0, 2.0), Vector3.new(-90, WALK_TOP + 5.0, 290), Enum.NormalId.Front, praduRed, paintWhite)

    ------------------------------------------------------------------
    -- 7. เสาไฟถนนรอบตึก (ติดทางเท้าริมนอก แขนโคมยื่นเข้าหาถนน)
    ------------------------------------------------------------------
    local lights = Instance.new("Folder")
    lights.Name = "StreetLights"
    lights.Parent = site

    for i, z in ipairs({ -150, -40, 40, 150, 240 }) do
        buildStreetLight(lights, "StreetLight_E_" .. i, 209, z, -1, 0)
        buildStreetLight(lights, "StreetLight_W_" .. i, -209, z == 0 and 30 or z, 1, 0)
    end
    for i, x in ipairs({ -150, -50, 50, 150 }) do
        buildStreetLight(lights, "StreetLight_Rear_" .. i, x, -179, 0, 1)
        buildStreetLight(lights, "StreetLight_Front_" .. i, x, 259, 0, -1)
    end
    for i, z in ipairs({ -110, 0, 110 }) do
        buildStreetLight(lights, "LotLight_" .. i, 252, z, 0, 0)
    end

    print("🌳 [Site Grounds Built] ถนนวงรอบตึก + ทางเท้า + ลานจอดรถกลางแจ้ง + ลานมอเตอร์ไซค์ + ลานเสาธง เชื่อมลานจอดรถขับทะลุชั้น 1 สำเร็จ!")
end

return Building40_SiteGrounds
