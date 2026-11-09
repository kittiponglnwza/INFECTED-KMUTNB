--[[
    Floor2_Canteen.lua
    โครงสร้างและรายละเอียดชั้น 2 (Floor 2): โรงอาหาร 40 ปี สจพ. (มจพ.)
    อัปเดตตามคำสั่งล่าสุด:
      1. ห้องน้ำทั้ง 4 มุม เปิดช่องประตูเดินเข้าไปใช้งานได้จริง (มีอ่างล้างมือ กระจกเงา และห้องส้วมด้านใน)
      2. ปรับสเกลความลึกของแต่ละร้านข้าว/ร้านน้ำลงให้สมส่วน (ลึก 26 studs จากผนังนอก แทนที่จะยื่นยาวเกือบครึ่งตึก)
      3. ลดความลึกของห้องสำนักงานและจุดเก็บจานลง เพื่อให้โถงกลางโรงอาหารมีพื้นที่ใช้สอยกว้างขวาง เดินเชื่อมถึงกันได้หมดทุกโซน
      4. ลิฟต์และบันไดอยู่ในตัวอาคาร (Z = ±84..±120) และมีทางเชื่อมยื่นออกเฉพาะด้านหน้า (Z = 120..148)
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
    local wallColor = Color3.fromRGB(240, 237, 230)
    local wallMaterial = Enum.Material.Concrete
    local tileColor = Color3.fromRGB(222, 218, 210)

    local core = Layout.CORE
    local body = Layout.BODY
    local bridge = Layout.FRONT_BRIDGE
    local frontStair = Layout.STAIRS.Front
    local rearStair = Layout.STAIRS.Rear
    local frontLift = Layout.LIFTS.Front
    local rearLift = Layout.LIFTS.Rear

    ------------------------------------------------------------------
    -- 1. พื้นชั้น 2 (กรอบสี่เหลี่ยมตัวอาคาร 300 x 240 studs เดียวกับชั้น 1)
    --    เจาะช่องบันไดตรงกับบันไดชั้น 1 เป๊ะ
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
    ------------------------------------------------------------------
    local outdoorStairs = Instance.new("Model")
    outdoorStairs.Name = "OutdoorGrandStairs_Front"
    outdoorStairs.Parent = floor2

    local orange = Color3.fromRGB(235, 138, 88)
    local groundY = Layout.GROUND_Y
    local landingW = 60
    local landingL = 30
    local stairZ = bridge.endZ + landingL / 2   -- 163

    PartBuilder.makePart(outdoorStairs, "FrontPlaza", Vector3.new(body.halfX * 2, 2.0, 90),
        CFrame.new(0, groundY - 1.0, body.halfZ + 45), Color3.fromRGB(200, 120, 110), Enum.Material.Brick)

    local bridgeMidZ = (bridge.startZ + bridge.endZ) / 2
    PartBuilder.makePart(outdoorStairs, "FrontProtrudingBridge", Vector3.new(bridge.width, 2.0, bridge.length),
        CFrame.new(0, floorY - 1.0, bridgeMidZ), Color3.fromRGB(228, 222, 214), Enum.Material.Concrete)
    PartBuilder.makePart(outdoorStairs, "BridgeRail_Left", Vector3.new(1.5, 4.2, bridge.length),
        CFrame.new(-bridge.width / 2 + 0.75, floorY + 2.1, bridgeMidZ), orange, Enum.Material.Concrete)
    PartBuilder.makePart(outdoorStairs, "BridgeRail_Right", Vector3.new(1.5, 4.2, bridge.length),
        CFrame.new(bridge.width / 2 - 0.75, floorY + 2.1, bridgeMidZ), orange, Enum.Material.Concrete)

    PartBuilder.makePart(outdoorStairs, "GrandLandingPlatform", Vector3.new(landingW, 2.0, landingL),
        CFrame.new(0, floorY - 1.0, stairZ), Color3.fromRGB(228, 222, 214), Enum.Material.Concrete)
    PartBuilder.makePart(outdoorStairs, "Rail_Front", Vector3.new(landingW, 4.2, 1.5),
        CFrame.new(0, floorY + 2.1, stairZ + landingL / 2 - 0.75), orange, Enum.Material.Concrete)

    local signZ = stairZ + landingL / 2 + 0.2
    PartBuilder.makeSign(outdoorStairs, "GrandCanteenSign", "โรงอาหาร 40 ปี\nสจพ. (มจพ.)",
        Vector3.new(24, 6.0, 0.8), Vector3.new(0, floorY + 3.0, signZ), Enum.NormalId.Back,
        Color3.fromRGB(250, 250, 248), Color3.fromRGB(0, 135, 68))
    for _, sx in ipairs({ -15, 15 }) do
        PartBuilder.makeSign(outdoorStairs, "CokeBadge_" .. sx, "Coke", Vector3.new(5.0, 5.0, 0.9),
            Vector3.new(sx, floorY + 3.0, signZ), Enum.NormalId.Back,
            Color3.fromRGB(220, 20, 30), Color3.fromRGB(255, 255, 255))
    end

    for _, px in ipairs({ -18, 18 }) do
        local h = floorY - 2.0 - groundY
        PartBuilder.makeCylinder(outdoorStairs, "GrandStairPillar_" .. px, Vector3.new(h, 3.2, 3.2),
            CFrame.new(px, groundY + h / 2, stairZ + 6) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(245, 240, 230), Enum.Material.Concrete)
    end

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

    PartBuilder.makePart(outdoorStairs, "CanopyRoof", Vector3.new(landingW + 8, 1.2, bridge.length + landingL + 6),
        CFrame.new(0, floorY + 16, (bridge.startZ + stairZ + landingL / 2) / 2), Color3.fromRGB(55, 65, 75), Enum.Material.Metal)

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

    -- ผนังด้านหน้าและด้านหลังตึกช่วงระหว่างคอร์กลางกับห้องน้ำมุม (X = ±70..±112, Z = ±120)
    for _, sz in ipairs({ -1, 1 }) do
        for _, sx in ipairs({ -1, 1 }) do
            PartBuilder.makePart(floor2, "FacadeWall_" .. sx .. "_" .. sz, Vector3.new(42, wallH, wallThick),
                CFrame.new(sx * 91, floorY + wallH / 2, sz * (body.halfZ - wallThick / 2)), wallColor, wallMaterial)
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
    -- 4. โซนด้านในหน้า (Z = +64..+84, ลึกเพียง 20 studs กะทัดรัด ไม่กินพื้นที่โถงกลาง):
    --    ซ้าย: ที่เก็บจาน (X = -68..-26) | ขวา: ห้องสำนักงาน (X = +26..+68, มีประตูเข้าได้)
    ------------------------------------------------------------------
    local innerSouth = Instance.new("Model")
    innerSouth.Name = "InnerSouth_Facilities"
    innerSouth.Parent = floor2

    local dishL = Instance.new("Model")
    dishL.Name = "DishReturn_South"
    dishL.Parent = innerSouth
    PartBuilder.makePart(dishL, "Wall_Back", Vector3.new(42, wallH, wallThick), CFrame.new(-47, floorY + wallH/2, 84 - wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(dishL, "Wall_West", Vector3.new(wallThick, wallH, 18), CFrame.new(-68 + wallThick/2, floorY + wallH/2, 75), wallColor, wallMaterial)
    PartBuilder.makePart(dishL, "Wall_East", Vector3.new(wallThick, wallH, 18), CFrame.new(-26 - wallThick/2, floorY + wallH/2, 75), wallColor, wallMaterial)
    PartBuilder.makePart(dishL, "Counter", Vector3.new(38, 3.8, 3.6), CFrame.new(-47, floorY + 1.9, 66), Color3.fromRGB(180, 185, 190), Enum.Material.Metal)
    PartBuilder.makePart(dishL, "TrayRack", Vector3.new(34, 5.5, 2.6), CFrame.new(-47, floorY + 6.5, 78), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
    PartBuilder.makeSign(dishL, "Sign", "ที่เก็บจาน (SOUTH)\nDISH RETURN", Vector3.new(28, 3.0, 0.3), Vector3.new(-47, floorY + 13, 66), Enum.NormalId.Front, Color3.fromRGB(0, 120, 160), Color3.fromRGB(255, 255, 255))
    for idx, c in ipairs({ Color3.fromRGB(30, 140, 40), Color3.fromRGB(220, 180, 20), Color3.fromRGB(30, 80, 200) }) do
        PartBuilder.makePart(dishL, "Bin_" .. idx, Vector3.new(3.2, 4.0, 3.2), CFrame.new(-58 + (idx * 5.5), floorY + 2.0, 72), c, Enum.Material.SmoothPlastic)
    end

    local offS = Instance.new("Model")
    offS.Name = "Office_South"
    offS.Parent = innerSouth
    PartBuilder.makePart(offS, "Wall_Back",  Vector3.new(42, wallH, wallThick), CFrame.new(47, floorY + wallH/2, 84 - wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(offS, "Wall_West",  Vector3.new(wallThick, wallH, 20), CFrame.new(26 + wallThick/2, floorY + wallH/2, 74), wallColor, wallMaterial)
    PartBuilder.makePart(offS, "Wall_East",  Vector3.new(wallThick, wallH, 20), CFrame.new(68 - wallThick/2, floorY + wallH/2, 74), wallColor, wallMaterial)
    -- ผนังด้านหน้าเว้นช่องประตู 10 studs ตรงกลางให้เดินเข้าได้
    PartBuilder.makePart(offS, "Wall_Front_L", Vector3.new(16, wallH, wallThick), CFrame.new(34, floorY + wallH/2, 64 + wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(offS, "Wall_Front_R", Vector3.new(16, wallH, wallThick), CFrame.new(60, floorY + wallH/2, 64 + wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(offS, "Wall_Front_Header", Vector3.new(10, 6, wallThick), CFrame.new(47, floorY + wallH - 3, 64 + wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(offS, "OfficeDesk", Vector3.new(14, 3.2, 5), CFrame.new(47, floorY + 1.6, 77), Color3.fromRGB(140, 95, 55), Enum.Material.Wood)
    PartBuilder.makeSign(offS, "Sign", "ห้องสำนักงาน\nOFFICE", Vector3.new(24, 3.0, 0.3), Vector3.new(47, floorY + 18, 64 - 0.2), Enum.NormalId.Front, Color3.fromRGB(40, 50, 65), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 5. โซนหลังตึกในอาคาร (Z = -120..-84): ลิฟต์ (ซ้าย) / ทางเข้าออก (กลาง) / บันได (ขวา)
    ------------------------------------------------------------------
    local topCore = Instance.new("Model")
    topCore.Name = "NorthCore_ElevatorAndStairs"
    topCore.Parent = floor2

    buildLiftLevel(topCore, rearLift)
    buildStairLevel(topCore, rearStair)

    PartBuilder.makePart(topCore, "NorthExit_GuardRail", Vector3.new(core.centerWidth, 3.5, 0.6),
        CFrame.new(0, floorY + 1.75, -core.outerZ + 0.5), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
    PartBuilder.makeSign(topCore, "NorthExitSign", "ทางเข้าออกหลังตึก\nNORTH EXIT", Vector3.new(30, 3.5, 0.4),
        Vector3.new(0, floorY + wallH - 3, -core.outerZ + 1.0), Enum.NormalId.Back, Color3.fromRGB(40, 50, 60), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 6. โซนด้านในหลัง (Z = -84..-64, ลึกเพียง 20 studs กะทัดรัด):
    --    ซ้าย: ห้องเก็บพัสดุ (X = -68..-26, มีประตูเข้าได้) | ขวา: ที่เก็บจาน (X = +26..+68)
    ------------------------------------------------------------------
    local innerNorth = Instance.new("Model")
    innerNorth.Name = "InnerNorth_Facilities"
    innerNorth.Parent = floor2

    local roomN = Instance.new("Model")
    roomN.Name = "Storage_North"
    roomN.Parent = innerNorth
    PartBuilder.makePart(roomN, "Wall_Back",  Vector3.new(42, wallH, wallThick), CFrame.new(-47, floorY + wallH/2, -84 + wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomN, "Wall_West",  Vector3.new(wallThick, wallH, 20), CFrame.new(-68 + wallThick/2, floorY + wallH/2, -74), wallColor, wallMaterial)
    PartBuilder.makePart(roomN, "Wall_East",  Vector3.new(wallThick, wallH, 20), CFrame.new(-26 - wallThick/2, floorY + wallH/2, -74), wallColor, wallMaterial)
    PartBuilder.makePart(roomN, "Wall_Front_L", Vector3.new(16, wallH, wallThick), CFrame.new(-60, floorY + wallH/2, -64 - wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomN, "Wall_Front_R", Vector3.new(16, wallH, wallThick), CFrame.new(-34, floorY + wallH/2, -64 - wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomN, "Wall_Front_Header", Vector3.new(10, 6, wallThick), CFrame.new(-47, floorY + wallH - 3, -64 - wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomN, "StorageShelf", Vector3.new(16, 8, 4), CFrame.new(-47, floorY + 4, -78), Color3.fromRGB(110, 115, 120), Enum.Material.Metal)
    PartBuilder.makeSign(roomN, "Sign", "ห้องเก็บพัสดุ\nSTORAGE", Vector3.new(24, 3.0, 0.3), Vector3.new(-47, floorY + 18, -64 + 0.2), Enum.NormalId.Back, Color3.fromRGB(50, 55, 60), Color3.fromRGB(255, 255, 255))

    local dishR = Instance.new("Model")
    dishR.Name = "DishReturn_North"
    dishR.Parent = innerNorth
    PartBuilder.makePart(dishR, "Wall_Back", Vector3.new(42, wallH, wallThick), CFrame.new(47, floorY + wallH/2, -84 + wallThick/2), wallColor, wallMaterial)
    PartBuilder.makePart(dishR, "Wall_West", Vector3.new(wallThick, wallH, 18), CFrame.new(26 + wallThick/2, floorY + wallH/2, -75), wallColor, wallMaterial)
    PartBuilder.makePart(dishR, "Wall_East", Vector3.new(wallThick, wallH, 18), CFrame.new(68 - wallThick/2, floorY + wallH/2, -75), wallColor, wallMaterial)
    PartBuilder.makePart(dishR, "Counter", Vector3.new(38, 3.8, 3.6), CFrame.new(47, floorY + 1.9, -66), Color3.fromRGB(180, 185, 190), Enum.Material.Metal)
    PartBuilder.makePart(dishR, "TrayRack", Vector3.new(34, 5.5, 2.6), CFrame.new(47, floorY + 6.5, -78), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
    PartBuilder.makeSign(dishR, "Sign", "ที่เก็บจาน (NORTH)\nDISH RETURN", Vector3.new(28, 3.0, 0.3), Vector3.new(47, floorY + 13, -66), Enum.NormalId.Back, Color3.fromRGB(0, 120, 160), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 7. ห้องน้ำ 4 มุม (เข้าใช้งานได้จริง! มีช่องประตู อ่างล้างมือ กระจก และห้องส้วมย่อย)
    --    ขนาดสมส่วน: กว้าง 38 studs (X = ±112..±150), ลึก 48 studs (Z = ±72..±120)
    --    ทำให้เกิดโถงทางเดินกว้าง 42 studs (X = ±70..±112) เดินเข้าห้องน้ำได้สะดวก
    ------------------------------------------------------------------
    local restrooms = Instance.new("Model")
    restrooms.Name = "Restrooms_4Corners"
    restrooms.Parent = floor2

    local rrW = 38 -- X = 112..150
    local rrL = 48 -- Z = 72..120
    local cornerConfigs = {
        { name = "Restroom_TopLeft",  sx = -1, sz = -1, label = "ห้องน้ำชาย\nMALE RESTROOM",     color = Color3.fromRGB(20, 90, 160),  nId = Enum.NormalId.Back },
        { name = "Restroom_TopRight", sx =  1, sz = -1, label = "ห้องน้ำหญิง\nFEMALE RESTROOM",   color = Color3.fromRGB(180, 40, 90),  nId = Enum.NormalId.Back },
        { name = "Restroom_BotLeft",  sx = -1, sz =  1, label = "ห้องน้ำหญิง\nFEMALE RESTROOM",   color = Color3.fromRGB(180, 40, 90),  nId = Enum.NormalId.Front },
        { name = "Restroom_BotRight", sx =  1, sz =  1, label = "ห้องน้ำชาย\nMALE RESTROOM",     color = Color3.fromRGB(20, 90, 160),  nId = Enum.NormalId.Front },
    }
    for _, c in ipairs(cornerConfigs) do
        local rModel = Instance.new("Model")
        rModel.Name = c.name
        rModel.Parent = restrooms

        local sx, sz = c.sx, c.sz
        local cx = sx * (150 - rrW / 2) -- ±131
        local cz = sz * (120 - rrL / 2) -- ±96
        local innerX = sx * (150 - rrW) -- ±112
        local innerZ = sz * (120 - rrL) -- ±72

        -- ผนังนอก X (±150), ผนังนอก Z (±120), ผนังข้างด้านใน X (±112)
        PartBuilder.makePart(rModel, "Wall_Outer_X", Vector3.new(wallThick, wallH, rrL),
            CFrame.new(sx * (150 - wallThick/2), floorY + wallH/2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Outer_Z", Vector3.new(rrW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH/2, sz * (120 - wallThick/2)), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Inner_X", Vector3.new(wallThick, wallH, rrL),
            CFrame.new(innerX + sx * (wallThick/2), floorY + wallH/2, cz), wallColor, wallMaterial)

        -- ผนังด้านหน้า (Z = ±72) เปิดช่องประตูทางเข้ากว้าง 12 studs!
        local doorW = 12
        local sideWallW = (rrW - doorW) / 2 -- 13
        PartBuilder.makePart(rModel, "Wall_Front_A", Vector3.new(sideWallW, wallH, wallThick),
            CFrame.new(cx - (doorW/2 + sideWallW/2), floorY + wallH/2, innerZ + sz * (wallThick/2)), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Front_B", Vector3.new(sideWallW, wallH, wallThick),
            CFrame.new(cx + (doorW/2 + sideWallW/2), floorY + wallH/2, innerZ + sz * (wallThick/2)), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Front_Header", Vector3.new(doorW, 6.0, wallThick),
            CFrame.new(cx, floorY + wallH - 3.0, innerZ + sz * (wallThick/2)), wallColor, wallMaterial)

        -- ป้ายห้องน้ำเหนือช่องประตูทางเข้า
        PartBuilder.makeSign(rModel, "Sign", c.label, Vector3.new(22, 3.6, 0.4),
            Vector3.new(cx, floorY + wallH - 3.2, innerZ - sz * 0.3), c.nId, c.color, Color3.fromRGB(255, 255, 255))

        -- สุขภัณฑ์ภายในห้องน้ำ: เคาน์เตอร์อ่างล้างมือ + กระจกเงา (ริมผนังด้านใน X = ±114)
        PartBuilder.makePart(rModel, "SinkCounter", Vector3.new(3.5, 3.2, 18),
            CFrame.new(innerX + sx * 3.8, floorY + 1.6, cz - sz * 6), Color3.fromRGB(215, 220, 225), Enum.Material.Marble)
        PartBuilder.makePart(rModel, "Mirror", Vector3.new(0.3, 5.0, 16),
            CFrame.new(innerX + sx * 2.2, floorY + 6.2, cz - sz * 6), Color3.fromRGB(190, 225, 245), Enum.Material.Glass, { Reflectance = 0.4 })

        -- ห้องส้วมย่อย 3 ห้องริมผนังด้านนอก (X = ±142)
        for st = 1, 3 do
            local stZ = (cz - sz * 12) + sz * ((st - 1) * 11)
            PartBuilder.makePart(rModel, "CubicleWall_" .. st, Vector3.new(10, 9, 0.5),
                CFrame.new(sx * 143, floorY + 4.5, stZ + sz * 5.5), Color3.fromRGB(200, 205, 210), Enum.Material.SmoothPlastic)
            PartBuilder.makePart(rModel, "Toilet_" .. st, Vector3.new(2.6, 2.2, 2.2),
                CFrame.new(sx * 145, floorY + 1.1, stZ), Color3.fromRGB(250, 250, 252), Enum.Material.SmoothPlastic)
        end
    end

    ------------------------------------------------------------------
    -- 8. ปีกซ้าย / ขวา: ร้านข้าว & ร้านน้ำ 8 ร้าน (ปรับสเกลความลึกลงให้สมส่วน!)
    --    เดิมลึก 68 studs (กินพื้นที่เกือบครึ่งตึก) -> ปรับเหลือลึก 26 studs (X = ±124..±150)
    --    แต่ละร้านกว้าง 28 studs (รวม 4 ร้าน ยาว Z = -56..+56)
    ------------------------------------------------------------------
    local stallDepth = 26       -- ความลึกร้านจากผนังนอก (สมส่วน ไม่ยาวเป็นซอยลึก)
    local stallWidth = 28       -- ความกว้างหน้าซุ้มแต่ละร้าน
    local totalStallsSpan = stallWidth * 4 -- 112 (Z = -56..+56)

    local function buildStallRow(modelName, side, stalls)
        local row = Instance.new("Model")
        row.Name = modelName
        row.Parent = floor2

        local outerWallX = side * (150 - wallThick/2)
        local dividerMidX = side * (150 - stallDepth / 2) -- ±137
        local counterX = side * (150 - stallDepth + 2.0)  -- ±126 (แนวเคาน์เตอร์หน้าร้าน)
        local backBenchX = side * (150 - 4.0)             -- ±146 (เคาน์เตอร์ครัวด้านหลัง)

        -- ผนังนอกตึกช่วงปีกซ้าย/ขวา (Z = -72..+72 เชื่อมชนห้องน้ำมุมพอดี)
        PartBuilder.makePart(row, "OuterWall", Vector3.new(wallThick, wallH, 144),
            CFrame.new(outerWallX, floorY + wallH/2, 0), wallColor, wallMaterial)

        -- ผนังกั้นปิดหัว-ท้ายแถวร้านข้าว (ที่ Z = -56 และ Z = +56)
        for _, endZ in ipairs({ -totalStallsSpan / 2, totalStallsSpan / 2 }) do
            PartBuilder.makePart(row, "EndWall_" .. endZ, Vector3.new(stallDepth, wallH, 1.2),
                CFrame.new(dividerMidX, floorY + wallH/2, endZ), wallColor, wallMaterial)
        end

        for idx, stall in ipairs(stalls) do
            local sM = Instance.new("Model")
            sM.Name = modelName .. "_Stall" .. idx
            sM.Parent = row

            -- ผนังกั้นระหว่างร้าน (ลึก 26 studs สมส่วน)
            if idx < #stalls then
                PartBuilder.makePart(sM, "Divider", Vector3.new(stallDepth, wallH, 1.0),
                    CFrame.new(dividerMidX, floorY + wallH/2, stall.z + stallWidth / 2), wallColor, wallMaterial)
            end

            -- เคาน์เตอร์เตรียมอาหารด้านในชิดผนังหลังร้าน
            PartBuilder.makePart(sM, "BackKitchenBench", Vector3.new(3.2, 3.6, stallWidth - 3),
                CFrame.new(backBenchX, floorY + 1.8, stall.z), PartBuilder.COLORS.steel, Enum.Material.Metal)

            -- เคาน์เตอร์สั่งอาหารหน้าร้าน (เว้นช่องทางเดินเข้าร้านด้านข้าง 4 studs)
            local cLen = stallWidth - 5
            PartBuilder.makePart(sM, "Counter", Vector3.new(3.6, 3.8, cLen),
                CFrame.new(counterX, floorY + 1.9, stall.z - 1.5), Color3.fromRGB(220, 215, 205), Enum.Material.Concrete)
            PartBuilder.makePart(sM, "CounterTop", Vector3.new(4.2, 0.4, cLen + 0.6),
                CFrame.new(counterX, floorY + 4.0, stall.z - 1.5), Color3.fromRGB(60, 60, 65), Enum.Material.Granite)
            PartBuilder.makePart(sM, "GlassCase", Vector3.new(2.4, 2.8, cLen - 4),
                CFrame.new(counterX, floorY + 5.6, stall.z - 1.5), Color3.fromRGB(220, 240, 255), Enum.Material.Glass, { Transparency = 0.6 })

            -- ป้ายชื่อร้านเหนือเคาน์เตอร์หน้าร้าน
            PartBuilder.makePart(sM, "SignFascia", Vector3.new(1.2, 4.5, stallWidth - 1),
                CFrame.new(counterX, floorY + 13.5, stall.z), stall.color, Enum.Material.SmoothPlastic)
            PartBuilder.makeSign(sM, "Sign", stall.name, Vector3.new(0.4, 3.4, stallWidth - 2),
                Vector3.new(counterX - side * 0.8, floorY + 13.5, stall.z),
                side < 0 and Enum.NormalId.Right or Enum.NormalId.Left, stall.color, Color3.fromRGB(255, 255, 255))
        end
    end

    buildStallRow("WestWing_FoodStalls", -1, {
        { name = "ร้านที่ 1: ก๋วยเตี๋ยวเรือ มจพ.",  z = -42, color = Color3.fromRGB(180, 45, 35) },
        { name = "ร้านที่ 2: ข้าวมันไก่ตอน",        z = -14, color = Color3.fromRGB(210, 140, 25) },
        { name = "ร้านที่ 3: ข้าวราดแกงปักษ์ใต้",   z =  14, color = Color3.fromRGB(40, 140, 60) },
        { name = "ร้านที่ 4: ข้าวหมูกรอบ-หมูแดง",  z =  42, color = Color3.fromRGB(190, 70, 30) },
    })
    buildStallRow("EastWing_FoodAndDrinkStalls", 1, {
        { name = "ร้านที่ 5: ชานมไข่มุก & กาแฟโบราณ", z = -42, color = Color3.fromRGB(150, 75, 40) },
        { name = "ร้านที่ 6: ผลไม้สด & น้ำปั่น",       z = -14, color = Color3.fromRGB(230, 120, 30) },
        { name = "ร้านที่ 7: ข้าวไข่เจียว & สเต็ก",     z =  14, color = Color3.fromRGB(200, 160, 30) },
        { name = "ร้านที่ 8: อาหารตามสั่ง & ส้มตำ",    z =  42, color = Color3.fromRGB(200, 40, 50) },
    })

    ------------------------------------------------------------------
    -- 9. กลางโรงอาหาร: โต๊ะสแตนเลส มจพ. (กระจายตัวในพื้นที่ใช้สอยที่กว้างขึ้น)
    ------------------------------------------------------------------
    local diningArea = Instance.new("Model")
    diningArea.Name = "CenterDiningHall_Tables"
    diningArea.Parent = floor2

    for _, px in ipairs({ -65, 65 }) do
        for _, pz in ipairs({ -36, 36 }) do
            PartBuilder.makePart(diningArea, "Column", Vector3.new(4, wallH, 4), CFrame.new(px, floorY + wallH/2, pz), Color3.fromRGB(235, 230, 222), Enum.Material.Concrete)
            PartBuilder.makePart(diningArea, "ColBase", Vector3.new(4.6, 2.5, 4.6), CFrame.new(px, floorY + 1.25, pz), Color3.fromRGB(240, 180, 20), Enum.Material.SmoothPlastic)
        end
    end

    -- จัดแถวโต๊ะอาหาร 4 แถว x 5 คอลัมน์ เว้นทางเดินกลางและรอบนอกกว้างขวาง
    for _, tz in ipairs({ -38, -14, 14, 38 }) do
        for col = -2, 2 do
            local tx = col * 36
            local t = Instance.new("Model")
            t.Name = "CanteenTable_" .. tz .. "_" .. col
            t.Parent = diningArea
            PartBuilder.makePart(t, "TableTop", Vector3.new(16, 0.4, 5.5), CFrame.new(tx, floorY + 3.4, tz), PartBuilder.COLORS.steel, Enum.Material.Metal)
            PartBuilder.makePart(t, "TableLegL", Vector3.new(0.6, 3.2, 4.8), CFrame.new(tx - 6.5, floorY + 1.6, tz), Color3.fromRGB(80, 85, 90), Enum.Material.Metal)
            PartBuilder.makePart(t, "TableLegR", Vector3.new(0.6, 3.2, 4.8), CFrame.new(tx + 6.5, floorY + 1.6, tz), Color3.fromRGB(80, 85, 90), Enum.Material.Metal)
            for _, sx in ipairs({ -5, 5 }) do
                for _, sz in ipairs({ -4.0, 4.0 }) do
                    PartBuilder.makeCylinder(t, "StoolSeat", Vector3.new(0.4, 2.2, 2.2), CFrame.new(tx + sx, floorY + 2.0, tz + sz) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 65, 70), Enum.Material.Metal)
                    PartBuilder.makePart(t, "StoolLeg", Vector3.new(0.4, 2.0, 0.4), CFrame.new(tx + sx, floorY + 1.0, tz + sz), Color3.fromRGB(100, 105, 110), Enum.Material.Metal)
                end
            end
        end
    end

    ------------------------------------------------------------------
    -- 10. ไฟส่องสว่างชั้น 2 (ลดความจ้าลงให้มองเห็นผนังและป้ายคมชัด ไม่ขาวโพลน)
    ------------------------------------------------------------------
    local lights = Instance.new("Folder")
    lights.Name = "Lights_Floor2"
    lights.Parent = floor2
    local lightPoints = {
        Vector3.new(0, floorY + wallH - 2, 0),
        Vector3.new(-80, floorY + wallH - 2, 0),
        Vector3.new( 80, floorY + wallH - 2, 0),
        Vector3.new(0, floorY + wallH - 2, -core.centerZ),
        Vector3.new(0, floorY + wallH - 2,  core.centerZ),
        Vector3.new(-131, floorY + wallH - 2, -96),
        Vector3.new( 131, floorY + wallH - 2, -96),
        Vector3.new(-131, floorY + wallH - 2,  96),
        Vector3.new( 131, floorY + wallH - 2,  96),
        Vector3.new(0, floorY + 14, stairZ),
    }
    for idx, pos in ipairs(lightPoints) do
        PartBuilder.addPointLight(lights, "Light_F2_" .. idx, pos, Color3.fromRGB(255, 248, 235), 45, 0.9)
    end

    print("🍜 [Floor 2] โรงอาหาร 40 ปี สจพ. (ห้องน้ำเข้าได้จริง + ปรับสเกลร้านข้าวสมส่วน + เพิ่มพื้นที่ใช้สอย) สร้างเสร็จสมบูรณ์!")
end

return Floor2_Canteen
