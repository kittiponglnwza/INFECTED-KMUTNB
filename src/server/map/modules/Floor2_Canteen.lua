--[[
    Floor2_Canteen.lua
    โครงสร้างและรายละเอียดชั้น 2 (Floor 2): โรงอาหาร 40 ปี สจพ. (มจพ.)
    สร้างตามผังที่อัปเดตล่าสุด:
      1. ลิฟต์และบันไดอยู่ในตัวอาคารทั้งหมด (กรอบสี่เหลี่ยม 300 x 240 studs เดียวกับชั้น 1 และตรงแนวดิ่งกัน 100%)
      2. เฉพาะด้านหน้าชั้น 2 มี "ทางเชื่อมยื่นออกมา" (Front Walkway Bridge Z = 120..148)
         เชื่อมจากช่องทางเข้าออกหน้าตึก ไปยังชานพักบันไดใหญ่หน้าโรงอาหาร ("โรงอาหาร 40 ปี สจพ." + ป้าย Coke)
      3. แถบหลังในตึก: [ลิฟ (-70..-24)] [ทางเข้าออก (-24..24)] [บันได (24..70)] ที่ Z = -120..-84
         และถัดเข้ามาด้านใน Z = -84..-44 เป็น [ห้อง (-70..-24)] และ [ที่เก็บจาน (24..70)]
      4. แถบหน้าในตึก: [บันได (-70..-24)] [ทางเข้าออก (-24..24)] [ลิฟ (24..70)] ที่ Z = +84..+120
         และถัดเข้ามาด้านใน Z = +44..+84 เป็น [ที่เก็บจาน (-70..-24)] และ [ห้อง (24..70)]
      5. ห้องน้ำครบ 4 มุม (X = ±70..±150) + ร้านข้าวซ้าย-ขวา 8 ร้าน + โต๊ะสแตนเลสกลางโรงอาหาร
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local StairBuilder = require(script.Parent.Parent.utils.StairBuilder)
local SlabBuilder = require(script.Parent.Parent.utils.SlabBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Floor2_Canteen = {}

function Floor2_Canteen.build(parent)
    local floor2 = Instance.new("Model")
    floor2.Name = "Floor_2_Canteen"
    floor2.Parent = parent

    local floorY = Layout.floorY(2)      -- 23.0
    local wallH = Layout.FLOOR_HEIGHT    -- 22.0
    local wallThick = Layout.WALL_THICK  -- 2.0
    local wallColor = Color3.fromRGB(244, 241, 235)
    local wallMaterial = Enum.Material.Concrete
    local tileColor = Color3.fromRGB(238, 234, 226)

    local core = Layout.CORE
    local body = Layout.BODY
    local bridge = Layout.FRONT_BRIDGE
    local frontStair = Layout.STAIRS.Front
    local rearStair = Layout.STAIRS.Rear
    local frontLift = Layout.LIFTS.Front
    local rearLift = Layout.LIFTS.Rear

    ------------------------------------------------------------------
    -- 1. พื้นชั้น 2 (กรอบสี่เหลี่ยมตัวอาคาร 300 x 240 studs เดียวกันกับชั้น 1)
    --    เจาะช่องบันไดในตัวอาคารตรงกับบันไดชั้น 1 เป๊ะ
    ------------------------------------------------------------------
    SlabBuilder.build(
        floor2,
        "Floor2_Slab",
        {
            { minX = -body.halfX, maxX = body.halfX, minZ = -body.halfZ, maxZ = body.halfZ },
        },
        { StairBuilder.slabHole(frontStair), StairBuilder.slabHole(rearStair) },
        floorY, 2.0, tileColor, Enum.Material.SmoothPlastic
    )

    ------------------------------------------------------------------
    -- 2. ทางเชื่อมยื่นออกมาด้านหน้าชั้น 2 + บันไดใหญ่หน้าตึก (GRAND OUTDOOR STAIRS)
    --    ยื่นออกมาเฉพาะด้านหน้า (Z = 120..148) ไปหาชานพักบันไดใหญ่ (Z = 148..178)
    ------------------------------------------------------------------
    local outdoorStairs = Instance.new("Model")
    outdoorStairs.Name = "OutdoorGrandStairs_Front"
    outdoorStairs.Parent = floor2

    local orange = Color3.fromRGB(235, 138, 88)
    local groundY = Layout.GROUND_Y
    local landingW = 60
    local landingL = 30
    local stairZ = bridge.endZ + landingL / 2   -- 148 + 15 = 163

    -- ลานหน้าตึกชั้นล่างรองรับบันไดใหญ่
    PartBuilder.makePart(outdoorStairs, "FrontPlaza", Vector3.new(body.halfX * 2, 2.0, 90),
        CFrame.new(0, groundY - 1.0, body.halfZ + 45), Color3.fromRGB(200, 120, 110), Enum.Material.Brick)

    -- 🌉 ทางเชื่อมยื่นออกมาจากหน้าตึกชั้น 2 (Protruding Front Walkway Bridge: Z = 120..148)
    local bridgeMidZ = (bridge.startZ + bridge.endZ) / 2 -- 134
    PartBuilder.makePart(outdoorStairs, "FrontProtrudingBridge", Vector3.new(bridge.width, 2.0, bridge.length),
        CFrame.new(0, floorY - 1.0, bridgeMidZ), Color3.fromRGB(228, 222, 214), Enum.Material.Concrete)
    -- ราวกันตกซ้าย-ขวาของทางเชื่อมที่ยื่นออกมา
    PartBuilder.makePart(outdoorStairs, "BridgeRail_Left", Vector3.new(1.5, 4.2, bridge.length),
        CFrame.new(-bridge.width / 2 + 0.75, floorY + 2.1, bridgeMidZ), orange, Enum.Material.Concrete)
    PartBuilder.makePart(outdoorStairs, "BridgeRail_Right", Vector3.new(1.5, 4.2, bridge.length),
        CFrame.new(bridge.width / 2 - 0.75, floorY + 2.1, bridgeMidZ), orange, Enum.Material.Concrete)

    -- ชานพักบันไดใหญ่หน้าโรงอาหาร (Z = 148..178)
    PartBuilder.makePart(outdoorStairs, "GrandLandingPlatform", Vector3.new(landingW, 2.0, landingL),
        CFrame.new(0, floorY - 1.0, stairZ), Color3.fromRGB(228, 222, 214), Enum.Material.Concrete)
    PartBuilder.makePart(outdoorStairs, "Rail_Front", Vector3.new(landingW, 4.2, 1.5),
        CFrame.new(0, floorY + 2.1, stairZ + landingL / 2 - 0.75), orange, Enum.Material.Concrete)

    -- ป้าย "โรงอาหาร 40 ปี สจพ." + ตรา Coke สองข้าง
    local signZ = stairZ + landingL / 2 + 0.2
    PartBuilder.makeSign(outdoorStairs, "GrandCanteenSign", "โรงอาหาร 40 ปี\nสจพ. (มจพ.)",
        Vector3.new(24, 6.0, 0.8), Vector3.new(0, floorY + 3.0, signZ), Enum.NormalId.Back,
        Color3.fromRGB(250, 250, 248), Color3.fromRGB(0, 135, 68))
    for _, sx in ipairs({ -15, 15 }) do
        PartBuilder.makeSign(outdoorStairs, "CokeBadge_" .. sx, "Coke", Vector3.new(5.0, 5.0, 0.9),
            Vector3.new(sx, floorY + 3.0, signZ), Enum.NormalId.Back,
            Color3.fromRGB(220, 20, 30), Color3.fromRGB(255, 255, 255))
    end

    -- เสากลมค้ำชานพักและทางเชื่อม
    for _, px in ipairs({ -18, 18 }) do
        local h = floorY - 2.0 - groundY
        PartBuilder.makeCylinder(outdoorStairs, "GrandStairPillar_" .. px, Vector3.new(h, 3.2, 3.2),
            CFrame.new(px, groundY + h / 2, stairZ + 6) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(245, 240, 230), Enum.Material.Concrete)
    end

    -- ขั้นบันไดสองปีก ซ้าย-ขวา (ขั้นบนสุดติดชานพัก แล้วลาดลงออกสองข้าง ขั้นทึบถึงพื้น)
    local stepCount = 20
    local stepRise = (floorY - groundY) / stepCount
    local stepRun = 3.6
    local stepWidth = 20
    for _, side in ipairs({ -1, 1 }) do
        for s = 1, stepCount - 1 do
            local top = floorY - s * stepRise
            local xMid = side * (landingW / 2 + (s - 0.5) * stepRun)
            PartBuilder.makePart(outdoorStairs, "Step_" .. (side < 0 and "L" or "R") .. "_" .. s,
                Vector3.new(stepRun + 0.05, top - groundY, stepWidth),
                CFrame.new(xMid, (groundY + top) / 2, stairZ), orange, Enum.Material.Concrete)
        end
        local runLen = (stepCount - 1) * stepRun
        local midX = side * (landingW / 2 + runLen / 2)
        local slope = math.atan2(floorY - groundY, runLen)
        PartBuilder.makePart(outdoorStairs, "StairBalustrade_" .. side, Vector3.new(runLen + 2, 3.0, 1.0),
            CFrame.new(midX, (floorY + groundY) / 2 + 2.5, stairZ + stepWidth / 2 + 0.5)
                * CFrame.Angles(0, 0, side * -slope),
            orange, Enum.Material.Concrete)
    end

    -- หลังคาคลุมทางเชื่อมและชานพัก
    PartBuilder.makePart(outdoorStairs, "CanopyRoof", Vector3.new(landingW + 8, 1.2, bridge.length + landingL + 6),
        CFrame.new(0, floorY + 16, (bridge.startZ + stairZ + landingL / 2) / 2), Color3.fromRGB(55, 65, 75), Enum.Material.Metal)

    -- โต๊ะม้านั่งหินใต้ชานพักชั้นล่าง
    for _, tx in ipairs({ -8, 8 }) do
        PartBuilder.makePart(outdoorStairs, "PicnicTable_" .. tx, Vector3.new(10, 1.2, 4), CFrame.new(tx, groundY + 2.4, stairZ), Color3.fromRGB(210, 205, 195), Enum.Material.Concrete)
        PartBuilder.makePart(outdoorStairs, "PicnicBenchA_" .. tx, Vector3.new(10, 0.8, 2), CFrame.new(tx, groundY + 1.4, stairZ - 3.5), Color3.fromRGB(200, 195, 185), Enum.Material.Concrete)
        PartBuilder.makePart(outdoorStairs, "PicnicBenchB_" .. tx, Vector3.new(10, 0.8, 2), CFrame.new(tx, groundY + 1.4, stairZ + 3.5), Color3.fromRGB(200, 195, 185), Enum.Material.Concrete)
    end

    ------------------------------------------------------------------
    -- ฟังก์ชันช่วยสร้างคอร์บันได / ลิฟต์ ชั้น 2 (อยู่ในตัวอาคาร Z = ±84..±120)
    ------------------------------------------------------------------
    local function buildStairLevel(folder, def)
        local m = Instance.new("Model")
        m.Name = def.name .. "_F2"
        m.Parent = folder
        StairBuilder.buildEnclosure(m, def, floorY, wallH)
        local openX = def.centerX + def.entranceDir * (StairBuilder.HALF_X - 1)
        PartBuilder.makePart(m, "OpeningHeader", Vector3.new(2, 3, StairBuilder.HALF_Z * 2),
            CFrame.new(openX, floorY + wallH - 1.5, def.centerZ), wallColor, wallMaterial)
        PartBuilder.makeSign(m, "Sign", "บันได (ชั้น 2)\nSTAIRS",
            Vector3.new(0.4, 2.6, 12),
            Vector3.new(openX + def.entranceDir * 1.25, floorY + wallH - 1.5, def.centerZ),
            def.entranceDir > 0 and Enum.NormalId.Right or Enum.NormalId.Left,
            Color3.fromRGB(20, 120, 50), Color3.fromRGB(255, 255, 255))
    end

    local function buildLiftLevel(folder, def)
        local m = Instance.new("Model")
        m.Name = def.name .. "_F2"
        m.Parent = folder
        local cx, cz, d = def.centerX, def.centerZ, def.doorDir
        local sz = cz > 0 and 1 or -1
        PartBuilder.makePart(m, "Wall_Outer", Vector3.new(core.sideWidth, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, sz * (core.outerZ - wallThick / 2)), wallColor, wallMaterial)
        PartBuilder.makePart(m, "Wall_Inner", Vector3.new(core.sideWidth, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, sz * (core.innerZ + wallThick / 2)), wallColor, wallMaterial)
        PartBuilder.makePart(m, "Wall_Side", Vector3.new(wallThick, wallH, core.depth),
            CFrame.new(cx - d * (core.sideWidth / 2 - wallThick / 2), floorY + wallH / 2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(m, "Wall_DoorHeader", Vector3.new(wallThick, 6.0, core.depth),
            CFrame.new(cx + d * (core.sideWidth / 2 - wallThick / 2), floorY + wallH - 3.0, cz), wallColor, wallMaterial)
        for _, off in ipairs({ -9, 9 }) do
            PartBuilder.makePart(m, "LiftDoor_" .. off, Vector3.new(0.6, 16.0, 11.0),
                CFrame.new(cx + d * (core.sideWidth / 2 - 0.3), floorY + 8.0, cz + off), PartBuilder.COLORS.steel, Enum.Material.Metal)
            PartBuilder.makeSign(m, "LiftInd_" .. off, "[ 2 ] ▲▼", Vector3.new(0.3, 2.0, 4.5),
                Vector3.new(cx + d * (core.sideWidth / 2 + 0.1), floorY + 17.5, cz + off),
                d > 0 and Enum.NormalId.Right or Enum.NormalId.Left,
                Color3.fromRGB(20, 20, 25), Color3.fromRGB(255, 140, 0))
        end
    end

    ------------------------------------------------------------------
    -- 3. โซนหน้าตึกในอาคาร (Z = +84..+120): บันได (ซ้าย) / ทางเข้าออก (กลาง) / ลิฟต์ (ขวา)
    ------------------------------------------------------------------
    local botCore = Instance.new("Model")
    botCore.Name = "SouthCore_Entrance"
    botCore.Parent = floor2

    buildStairLevel(botCore, frontStair)
    buildLiftLevel(botCore, frontLift)

    PartBuilder.makePart(botCore, "MainEntrance_PillarL", Vector3.new(3, wallH, 3), CFrame.new(-24, floorY + wallH / 2, core.outerZ - 1.5), Color3.fromRGB(180, 80, 40), Enum.Material.Metal)
    PartBuilder.makePart(botCore, "MainEntrance_PillarR", Vector3.new(3, wallH, 3), CFrame.new( 24, floorY + wallH / 2, core.outerZ - 1.5), Color3.fromRGB(180, 80, 40), Enum.Material.Metal)
    PartBuilder.makeSign(botCore, "MainEntranceSign", "ยินดีต้อนรับสู่ โรงอาหาร 40 ปี มจพ.\nKMUTNB 40-YEAR CANTEEN", Vector3.new(46, 4.0, 0.5),
        Vector3.new(0, floorY + wallH - 2, core.outerZ - 1.5), Enum.NormalId.Back, Color3.fromRGB(0, 100, 50), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 4. โซนด้านในหน้า (Z = +44..+84): ที่เก็บจาน (ซ้าย X=-70..-24) / ห้อง (ขวา X=+24..+70)
    ------------------------------------------------------------------
    local innerSouth = Instance.new("Model")
    innerSouth.Name = "InnerSouth_Facilities"
    innerSouth.Parent = floor2

    local inSZ = 64 -- กึ่งกลางระหว่าง 44..84 (ลึก 40)
    local dishL = Instance.new("Model")
    dishL.Name = "DishReturn_South"
    dishL.Parent = innerSouth
    PartBuilder.makePart(dishL, "Wall_Back", Vector3.new(46, wallH, wallThick), CFrame.new(-47, floorY + wallH/2, 84 - wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(dishL, "Wall_West", Vector3.new(wallThick, wallH, 40), CFrame.new(-70 + wallThick/2, floorY + wallH/2, inSZ), wallColor, wallMaterial)
    PartBuilder.makePart(dishL, "Wall_East", Vector3.new(wallThick, wallH, 40), CFrame.new(-24 - wallThick/2, floorY + wallH/2, inSZ), wallColor, wallMaterial)
    PartBuilder.makePart(dishL, "Counter", Vector3.new(42, 4.0, 4.0), CFrame.new(-47, floorY + 2.0, 46), Color3.fromRGB(180, 185, 190), Enum.Material.Metal)
    PartBuilder.makePart(dishL, "TrayRack", Vector3.new(38, 6.0, 3.0), CFrame.new(-47, floorY + 7.0, 46), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
    PartBuilder.makeSign(dishL, "Sign", "ที่เก็บจาน (SOUTH)\nDISH RETURN", Vector3.new(32, 3.2, 0.3), Vector3.new(-47, floorY + 12, 46 - 1.8), Enum.NormalId.Front, Color3.fromRGB(0, 120, 160), Color3.fromRGB(255, 255, 255))
    for idx, c in ipairs({ Color3.fromRGB(30, 140, 40), Color3.fromRGB(220, 180, 20), Color3.fromRGB(30, 80, 200) }) do
        PartBuilder.makePart(dishL, "Bin_" .. idx, Vector3.new(3.5, 4.5, 3.5), CFrame.new(-58 + (idx * 5.5), floorY + 2.25, 52), c, Enum.Material.SmoothPlastic)
    end

    local offS = Instance.new("Model")
    offS.Name = "Office_South"
    offS.Parent = innerSouth
    PartBuilder.makePart(offS, "Wall_Back",  Vector3.new(46, wallH, wallThick), CFrame.new(47, floorY + wallH/2, 84 - wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(offS, "Wall_Front", Vector3.new(46, wallH, wallThick), CFrame.new(47, floorY + wallH/2, 44 + wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(offS, "Wall_West",  Vector3.new(wallThick, wallH, 40), CFrame.new(24 + wallThick/2, floorY + wallH/2, inSZ), wallColor, wallMaterial)
    PartBuilder.makePart(offS, "Wall_East",  Vector3.new(wallThick, wallH, 40), CFrame.new(70 - wallThick/2, floorY + wallH/2, inSZ), wallColor, wallMaterial)
    PartBuilder.makeSign(offS, "Sign", "ห้องสำนักงาน\nOFFICE", Vector3.new(30, 3.2, 0.3), Vector3.new(47, floorY + 12, 44 - 0.2), Enum.NormalId.Front, Color3.fromRGB(40, 50, 65), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 5. โซนหลังตึกในอาคาร (Z = -120..-84): ลิฟต์ (ซ้าย) / ทางเข้าออก (กลาง) / บันได (ขวา)
    ------------------------------------------------------------------
    local topCore = Instance.new("Model")
    topCore.Name = "NorthCore_ElevatorAndStairs"
    topCore.Parent = floor2

    buildLiftLevel(topCore, rearLift)
    buildStairLevel(topCore, rearStair)

    -- ราวกันตกที่ขอบทางเข้าออกหลังตึก (Z = -120, ไม่ยื่นออกนอกตึก)
    PartBuilder.makePart(topCore, "NorthExit_GuardRail", Vector3.new(core.centerWidth, 3.5, 0.6),
        CFrame.new(0, floorY + 1.75, -core.outerZ + 0.5), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
    PartBuilder.makeSign(topCore, "NorthExitSign", "ทางเข้าออกหลังตึก\nNORTH EXIT", Vector3.new(30, 3.5, 0.4),
        Vector3.new(0, floorY + wallH - 3, -core.outerZ + 1.0), Enum.NormalId.Back, Color3.fromRGB(40, 50, 60), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 6. โซนด้านในหลัง (Z = -84..-44): ห้อง (ซ้าย X=-70..-24) / ที่เก็บจาน (ขวา X=+24..+70)
    ------------------------------------------------------------------
    local innerNorth = Instance.new("Model")
    innerNorth.Name = "InnerNorth_Facilities"
    innerNorth.Parent = floor2

    local inNZ = -64 -- กึ่งกลางระหว่าง -84..-44 (ลึก 40)
    local roomN = Instance.new("Model")
    roomN.Name = "Storage_North"
    roomN.Parent = innerNorth
    PartBuilder.makePart(roomN, "Wall_Back",  Vector3.new(46, wallH, wallThick), CFrame.new(-47, floorY + wallH/2, -84 + wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomN, "Wall_Front", Vector3.new(46, wallH, wallThick), CFrame.new(-47, floorY + wallH/2, -44 - wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomN, "Wall_West",  Vector3.new(wallThick, wallH, 40), CFrame.new(-70 + wallThick/2, floorY + wallH/2, inNZ), wallColor, wallMaterial)
    PartBuilder.makePart(roomN, "Wall_East",  Vector3.new(wallThick, wallH, 40), CFrame.new(-24 - wallThick/2, floorY + wallH/2, inNZ), wallColor, wallMaterial)
    PartBuilder.makeSign(roomN, "Sign", "ห้องเก็บพัสดุ\nSTORAGE", Vector3.new(30, 3.2, 0.3), Vector3.new(-47, floorY + 12, -44 + 0.2), Enum.NormalId.Back, Color3.fromRGB(50, 55, 60), Color3.fromRGB(255, 255, 255))

    local dishR = Instance.new("Model")
    dishR.Name = "DishReturn_North"
    dishR.Parent = innerNorth
    PartBuilder.makePart(dishR, "Wall_Back", Vector3.new(46, wallH, wallThick), CFrame.new(47, floorY + wallH/2, -84 + wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(dishR, "Wall_West", Vector3.new(wallThick, wallH, 40), CFrame.new(24 + wallThick/2, floorY + wallH/2, inNZ), wallColor, wallMaterial)
    PartBuilder.makePart(dishR, "Wall_East", Vector3.new(wallThick, wallH, 40), CFrame.new(70 - wallThick/2, floorY + wallH/2, inNZ), wallColor, wallMaterial)
    PartBuilder.makePart(dishR, "Counter", Vector3.new(42, 4.0, 4.0), CFrame.new(47, floorY + 2.0, -46), Color3.fromRGB(180, 185, 190), Enum.Material.Metal)
    PartBuilder.makePart(dishR, "TrayRack", Vector3.new(38, 6.0, 3.0), CFrame.new(47, floorY + 7.0, -46), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
    PartBuilder.makeSign(dishR, "Sign", "ที่เก็บจาน (NORTH)\nDISH RETURN", Vector3.new(32, 3.2, 0.3), Vector3.new(47, floorY + 12, -46 + 1.8), Enum.NormalId.Back, Color3.fromRGB(0, 120, 160), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 7. ห้องน้ำ 4 มุม (กว้าง 80: X = ±70..±150 ชนขอบลิฟต์/บันไดพอดี, ลึก 55: Z = ±65..±120)
    ------------------------------------------------------------------
    local restrooms = Instance.new("Model")
    restrooms.Name = "Restrooms_4Corners"
    restrooms.Parent = floor2

    local cornerW, cornerL = 80, 55
    local cornerConfigs = {
        { name = "Restroom_TopLeft",  x = -110, z = -92.5, label = "ห้องน้ำชาย (MALE)",   color = Color3.fromRGB(20, 90, 160),  nId = Enum.NormalId.Back },
        { name = "Restroom_TopRight", x =  110, z = -92.5, label = "ห้องน้ำหญิง (FEMALE)", color = Color3.fromRGB(180, 40, 90),  nId = Enum.NormalId.Back },
        { name = "Restroom_BotLeft",  x = -110, z =  92.5, label = "ห้องน้ำหญิง (FEMALE)", color = Color3.fromRGB(180, 40, 90),  nId = Enum.NormalId.Front },
        { name = "Restroom_BotRight", x =  110, z =  92.5, label = "ห้องน้ำชาย (MALE)",   color = Color3.fromRGB(20, 90, 160),  nId = Enum.NormalId.Front },
    }
    for _, c in ipairs(cornerConfigs) do
        local rModel = Instance.new("Model")
        rModel.Name = c.name
        rModel.Parent = restrooms
        local sx = c.x < 0 and -1 or 1
        local sz = c.z < 0 and -1 or 1
        PartBuilder.makePart(rModel, "Wall_Outer_X", Vector3.new(wallThick, wallH, cornerL), CFrame.new(sx * (150 - wallThick/2), floorY + wallH/2, c.z), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Outer_Z", Vector3.new(cornerW, wallH, wallThick), CFrame.new(c.x, floorY + wallH/2, sz * (120 - wallThick/2)), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Inner_X", Vector3.new(wallThick, wallH, cornerL), CFrame.new(sx * (70 + wallThick/2), floorY + wallH/2, c.z), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Inner_Z", Vector3.new(cornerW, wallH, wallThick), CFrame.new(c.x, floorY + wallH/2, sz * 65), wallColor, wallMaterial)
        PartBuilder.makeSign(rModel, "Sign", c.label, Vector3.new(28, 3.5, 0.4), Vector3.new(c.x, floorY + 13, sz * 65 - sz * 1.3), c.nId, c.color, Color3.fromRGB(255, 255, 255))
    end

    ------------------------------------------------------------------
    -- 8. ปีกซ้าย / ขวา: ร้านข้าว & ร้านน้ำ 8 ร้าน (Z = -65..+65)
    ------------------------------------------------------------------
    local function buildStallRow(modelName, side, stalls)
        local row = Instance.new("Model")
        row.Name = modelName
        row.Parent = floor2
        PartBuilder.makePart(row, "OuterWall", Vector3.new(wallThick, wallH, 130), CFrame.new(side * (150 - wallThick/2), floorY + wallH/2, 0), wallColor, wallMaterial)
        for idx, stall in ipairs(stalls) do
            local sM = Instance.new("Model")
            sM.Name = modelName .. "_Stall" .. idx
            sM.Parent = row
            PartBuilder.makePart(sM, "Divider", Vector3.new(65, wallH, wallThick), CFrame.new(side * 115, floorY + wallH/2, stall.z + 14), wallColor, wallMaterial)
            PartBuilder.makePart(sM, "Counter", Vector3.new(4, 4.0, 24), CFrame.new(side * 82, floorY + 2.0, stall.z), Color3.fromRGB(220, 215, 205), Enum.Material.Concrete)
            PartBuilder.makePart(sM, "CounterTop", Vector3.new(4.8, 0.4, 25), CFrame.new(side * 82, floorY + 4.2, stall.z), Color3.fromRGB(60, 60, 65), Enum.Material.Granite)
            PartBuilder.makePart(sM, "GlassCase", Vector3.new(3.0, 3.0, 18), CFrame.new(side * 82, floorY + 5.8, stall.z), Color3.fromRGB(220, 240, 255), Enum.Material.Glass, { Transparency = 0.6 })
            PartBuilder.makeSign(sM, "Sign", stall.name, Vector3.new(0.5, 3.2, 24), Vector3.new(side * 79, floorY + 12, stall.z),
                side < 0 and Enum.NormalId.Right or Enum.NormalId.Left, stall.color, Color3.fromRGB(255, 255, 255))
        end
    end

    buildStallRow("WestWing_FoodStalls", -1, {
        { name = "ร้านที่ 1: ก๋วยเตี๋ยวเรือ มจพ.",  z = -45, color = Color3.fromRGB(180, 45, 35) },
        { name = "ร้านที่ 2: ข้าวมันไก่ตอน",        z = -15, color = Color3.fromRGB(210, 140, 25) },
        { name = "ร้านที่ 3: ข้าวราดแกงปักษ์ใต้",   z =  15, color = Color3.fromRGB(40, 140, 60) },
        { name = "ร้านที่ 4: ข้าวหมูกรอบ-หมูแดง",  z =  45, color = Color3.fromRGB(190, 70, 30) },
    })
    buildStallRow("EastWing_FoodAndDrinkStalls", 1, {
        { name = "ร้านที่ 5: ชานมไข่มุก & กาแฟโบราณ", z = -45, color = Color3.fromRGB(150, 75, 40) },
        { name = "ร้านที่ 6: ผลไม้สด & น้ำปั่น",       z = -15, color = Color3.fromRGB(230, 120, 30) },
        { name = "ร้านที่ 7: ข้าวไข่เจียว & สเต็ก",     z =  15, color = Color3.fromRGB(200, 160, 30) },
        { name = "ร้านที่ 8: อาหารตามสั่ง & ส้มตำ",    z =  45, color = Color3.fromRGB(200, 40, 50) },
    })

    ------------------------------------------------------------------
    -- 9. กลางโรงอาหาร: โต๊ะสแตนเลส มจพ.
    ------------------------------------------------------------------
    local diningArea = Instance.new("Model")
    diningArea.Name = "CenterDiningHall_Tables"
    diningArea.Parent = floor2

    for _, px in ipairs({ -38, 38 }) do
        for _, pz in ipairs({ -22, 22 }) do
            PartBuilder.makePart(diningArea, "Column", Vector3.new(4, wallH, 4), CFrame.new(px, floorY + wallH/2, pz), Color3.fromRGB(235, 230, 222), Enum.Material.Concrete)
            PartBuilder.makePart(diningArea, "ColBase", Vector3.new(4.6, 2.5, 4.6), CFrame.new(px, floorY + 1.25, pz), Color3.fromRGB(240, 180, 20), Enum.Material.SmoothPlastic)
        end
    end

    for row = -2, 2 do
        local tz = row * 16
        for col = -2, 2 do
            local tx = col * 26
            local t = Instance.new("Model")
            t.Name = "CanteenTable_" .. row .. "_" .. col
            t.Parent = diningArea
            PartBuilder.makePart(t, "TableTop", Vector3.new(16, 0.4, 6.0), CFrame.new(tx, floorY + 3.4, tz), PartBuilder.COLORS.steel, Enum.Material.Metal)
            PartBuilder.makePart(t, "TableLegL", Vector3.new(0.6, 3.2, 5.0), CFrame.new(tx - 6.5, floorY + 1.6, tz), Color3.fromRGB(80, 85, 90), Enum.Material.Metal)
            PartBuilder.makePart(t, "TableLegR", Vector3.new(0.6, 3.2, 5.0), CFrame.new(tx + 6.5, floorY + 1.6, tz), Color3.fromRGB(80, 85, 90), Enum.Material.Metal)
            for _, sx in ipairs({ -5, 5 }) do
                for _, sz in ipairs({ -4.2, 4.2 }) do
                    PartBuilder.makeCylinder(t, "StoolSeat", Vector3.new(0.4, 2.2, 2.2), CFrame.new(tx + sx, floorY + 2.0, tz + sz) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 65, 70), Enum.Material.Metal)
                    PartBuilder.makePart(t, "StoolLeg", Vector3.new(0.4, 2.0, 0.4), CFrame.new(tx + sx, floorY + 1.0, tz + sz), Color3.fromRGB(100, 105, 110), Enum.Material.Metal)
                end
            end
        end
    end

    ------------------------------------------------------------------
    -- 10. ไฟส่องสว่างชั้น 2
    ------------------------------------------------------------------
    local lights = Instance.new("Folder")
    lights.Name = "Lights_Floor2"
    lights.Parent = floor2
    local lightPoints = {
        Vector3.new(0, floorY + wallH - 2, 0),
        Vector3.new(-70, floorY + wallH - 2, 0),
        Vector3.new(70, floorY + wallH - 2, 0),
        Vector3.new(0, floorY + wallH - 2, -core.centerZ),
        Vector3.new(0, floorY + wallH - 2,  core.centerZ),
        Vector3.new(-47, floorY + wallH - 2, -core.centerZ),
        Vector3.new( 47, floorY + wallH - 2, -core.centerZ),
        Vector3.new(-47, floorY + wallH - 2,  core.centerZ),
        Vector3.new( 47, floorY + wallH - 2,  core.centerZ),
        Vector3.new(0, floorY + 14, stairZ),
    }
    for idx, pos in ipairs(lightPoints) do
        PartBuilder.addPointLight(lights, "Light_F2_" .. idx, pos, Color3.fromRGB(255, 248, 235), 60, 1.8)
    end

    print("🍜 [Floor 2] โรงอาหาร 40 ปี สจพ. (ลิฟต์/บันไดในตัวอาคาร + ทางเชื่อมยื่นออกเฉพาะด้านหน้า) สร้างเสร็จสมบูรณ์!")
end

return Floor2_Canteen
