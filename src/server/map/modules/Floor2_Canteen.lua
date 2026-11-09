--[[
    Floor2_Canteen.lua
    โครงสร้างและรายละเอียดชั้น 2 (Floor 2): โรงอาหาร 40 ปี สจพ. (มจพ.)
    อัปเดตตามผังที่สั่งแก้ล่าสุด (media_1794244100343_57269656.png & media_1794244304869_53344d7e.jpg):
      1. โซนลิฟต์และบันไดโปร่งโล่ง ไม่แออัด:
         - ขยายโถงทางเข้าออกกลางเป็นกว้าง 60 studs (X = -30..+30)
         - คอร์ลิฟต์/บันไดขนาดกระชับ 38 x 34 studs (X = ±30..±68, Z = ±86..±120)
         - จุดที่เก็บจาน (Dish Return) เป็นเคาน์เตอร์สแตนเลสเปิดโล่ง (ไม่มีกำแพงทึบบังหน้าบันได)
         - ห้องสำนักงาน/ห้องพัสดุ ลดความลึกเหลือ 14 studs (Z = ±72..±86) ผนังกระจกโปร่งตา
      2. ห้องน้ำ 4 มุม — แต่ละมุมมีทั้ง "ห้องน้ำชาย" และ "ห้องน้ำหญิง" คู่กัน (รวม 8 ห้องย่อยใน 4 มุม):
         - ขนาดมุมละ 40 x 44 studs (X = ±110..±150, Z = ±76..±120)
         - แบ่งครึ่งซ้าย-ขวา มีประตูทางเข้าแยกชาย (ป้ายน้ำเงิน) และหญิง (ป้ายชมพู) พร้อมสุขภัณฑ์ครบ
      3. เพิ่ม "ห้องกินข้าว" (ห้องรับประทานอาหารปรับอากาศ / AC Dining Room) 4 ห้อง ตามตำแหน่งสีเขียวในผัง:
         - ตั้งอยู่ระหว่างห้องน้ำมุมกับลิฟต์/บันได (X = ±68..±110, Z = ±86..±120, ขนาด 42 x 34 studs)
         - ผนังกระจกใสกรอบอลูมิเนียม ประตูเดินเข้าได้จริง มีแอร์ติดผนังและชุดโต๊ะอาหารด้านใน
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
    local frameDark = Color3.fromRGB(48, 52, 58)

    local core = Layout.CORE
    local body = Layout.BODY
    local bridge = Layout.FRONT_BRIDGE
    local frontStair = Layout.STAIRS.Front
    local rearStair = Layout.STAIRS.Rear
    local frontLift = Layout.LIFTS.Front
    local rearLift = Layout.LIFTS.Rear

    ------------------------------------------------------------------
    -- 1. พื้นชั้น 2 (กรอบสี่เหลี่ยมตัวอาคาร 300 x 240 studs เดียวกับชั้น 1)
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
    local landingW = 64
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
    -- ฟังก์ชันสร้างคอร์บันได / ลิฟต์ ชั้น 2 (โปร่งโล่ง ไม่แออัด: 38 x 34 studs)
    ------------------------------------------------------------------
    local function buildStairLevel(folder, def)
        local m = Instance.new("Model")
        m.Name = def.name .. "_F2"
        m.Parent = folder
        StairBuilder.buildEnclosure(m, def, floorY, wallH)
        -- บันไดเดินขึ้นจากชั้น 2 ไปชั้น 3 (สนามกีฬาในร่ม)
        StairBuilder.buildUStair(m, def, floorY, wallH)
        local openX = def.centerX + def.entranceDir * (StairBuilder.HALF_X - 0.8)
        PartBuilder.makeSign(m, "Sign", "บันได (ชั้น 2 -> 3)\nSTAIRS TO FL.3",
            Vector3.new(0.4, 2.4, 12),
            Vector3.new(openX, floorY + wallH - 1.5, def.centerZ),
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
        for _, off in ipairs({ -8, 8 }) do
            PartBuilder.makePart(m, "LiftDoor_" .. off, Vector3.new(0.6, 16.0, 10.0),
                CFrame.new(cx + d * (core.sideWidth / 2 - 0.3), floorY + 8.0, cz + off), PartBuilder.COLORS.steel, Enum.Material.Metal)
            PartBuilder.makeSign(m, "LiftInd_" .. off, "[ 2 ] ▲▼", Vector3.new(0.3, 2.0, 4.2),
                Vector3.new(cx + d * (core.sideWidth / 2 + 0.1), floorY + 17.5, cz + off),
                d > 0 and Enum.NormalId.Right or Enum.NormalId.Left,
                Color3.fromRGB(20, 20, 25), Color3.fromRGB(255, 140, 0))
        end
    end

    ------------------------------------------------------------------
    -- 3. โซนหน้าตึกและหลังตึก (ลิฟต์ | ทางเข้าออกกว้าง 60 studs | บันได)
    ------------------------------------------------------------------
    local botCore = Instance.new("Model")
    botCore.Name = "SouthCore_Entrance"
    botCore.Parent = floor2
    buildStairLevel(botCore, frontStair)
    buildLiftLevel(botCore, frontLift)
    PartBuilder.makePart(botCore, "MainEntrance_PillarL", Vector3.new(2.5, wallH, 2.5), CFrame.new(-30, floorY + wallH / 2, core.outerZ - 1.25), Color3.fromRGB(180, 80, 40), Enum.Material.Metal)
    PartBuilder.makePart(botCore, "MainEntrance_PillarR", Vector3.new(2.5, wallH, 2.5), CFrame.new( 30, floorY + wallH / 2, core.outerZ - 1.25), Color3.fromRGB(180, 80, 40), Enum.Material.Metal)
    PartBuilder.makeSign(botCore, "MainEntranceSign", "ยินดีต้อนรับสู่ โรงอาหาร 40 ปี มจพ.\nKMUTNB 40-YEAR CANTEEN", Vector3.new(54, 3.8, 0.5),
        Vector3.new(0, floorY + wallH - 2, core.outerZ - 1.25), Enum.NormalId.Back, Color3.fromRGB(0, 100, 50), Color3.fromRGB(255, 255, 255))

    local topCore = Instance.new("Model")
    topCore.Name = "NorthCore_ElevatorAndStairs"
    topCore.Parent = floor2
    buildLiftLevel(topCore, rearLift)
    buildStairLevel(topCore, rearStair)
    PartBuilder.makePart(topCore, "NorthExit_GuardRail", Vector3.new(core.centerWidth, 3.5, 0.6),
        CFrame.new(0, floorY + 1.75, -core.outerZ + 0.5), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
    PartBuilder.makeSign(topCore, "NorthExitSign", "ทางเข้าออกหลังตึก\nNORTH EXIT", Vector3.new(32, 3.2, 0.4),
        Vector3.new(0, floorY + wallH - 2.5, -core.outerZ + 1.0), Enum.NormalId.Back, Color3.fromRGB(40, 50, 60), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 4. จุดเก็บจาน (Open Counter โปร่งโล่ง) & ห้องสำนักงาน/พัสดุ (Z = ±72..±86, ลึกเพียง 14 studs!)
    --    ไม่มีกำแพงทึบยื่นยาวมาบีบทางเดินหน้าลิฟต์และบันไดอีกต่อไป
    ------------------------------------------------------------------
    local facilities = Instance.new("Model")
    facilities.Name = "InnerFacilities_Compact"
    facilities.Parent = floor2

    local function buildOpenDishReturn(name, cx, sz)
        local m = Instance.new("Model")
        m.Name = name
        m.Parent = facilities
        local frontZ = sz * 74
        local backZ  = sz * 83
        -- เคาน์เตอร์สแตนเลสเปิดโล่ง (ไม่มีกำแพงข้างทึบ ทำให้โถงบันไดดูโล่งสบายตา)
        PartBuilder.makePart(m, "Counter", Vector3.new(32, 3.6, 3.5), CFrame.new(cx, floorY + 1.8, frontZ), PartBuilder.COLORS.steel, Enum.Material.Metal)
        PartBuilder.makePart(m, "TrayRack", Vector3.new(30, 5.2, 2.4), CFrame.new(cx, floorY + 2.6, backZ), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
        PartBuilder.makeSign(m, "Sign", "ที่เก็บจาน / แยกภาชนะ\nDISH RETURN", Vector3.new(26, 2.6, 0.3),
            Vector3.new(cx, floorY + 14.5, frontZ), sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
            Color3.fromRGB(0, 120, 160), Color3.fromRGB(255, 255, 255))
        for idx, c in ipairs({ Color3.fromRGB(30, 140, 40), Color3.fromRGB(220, 180, 20), Color3.fromRGB(30, 80, 200) }) do
            PartBuilder.makePart(m, "Bin_" .. idx, Vector3.new(3.0, 3.6, 3.0), CFrame.new(cx - 12 + (idx * 6), floorY + 1.8, sz * 78.5), c, Enum.Material.SmoothPlastic)
        end
    end

    local function buildCompactRoom(name, label, cx, sz)
        local m = Instance.new("Model")
        m.Name = name
        m.Parent = facilities
        local midZ = sz * 79 -- Z = ±72..±86 (ลึก 14 studs)
        local frontZ = sz * 72
        PartBuilder.makePart(m, "Wall_West", Vector3.new(1.2, wallH, 14), CFrame.new(cx - 17, floorY + wallH/2, midZ), wallColor, wallMaterial)
        PartBuilder.makePart(m, "Wall_East", Vector3.new(1.2, wallH, 14), CFrame.new(cx + 17, floorY + wallH/2, midZ), wallColor, wallMaterial)
        -- ด้านหน้าเป็นกระจกใส + ช่องประตูเดินเข้าได้
        PartBuilder.makePart(m, "Glass_L", Vector3.new(11, 10, 0.5), CFrame.new(cx - 11.5, floorY + 5, frontZ), Color3.fromRGB(200, 230, 245), Enum.Material.Glass, { Transparency = 0.55 })
        PartBuilder.makePart(m, "Glass_R", Vector3.new(11, 10, 0.5), CFrame.new(cx + 11.5, floorY + 5, frontZ), Color3.fromRGB(200, 230, 245), Enum.Material.Glass, { Transparency = 0.55 })
        PartBuilder.makePart(m, "Header", Vector3.new(34, wallH - 10, 1.2), CFrame.new(cx, floorY + 10 + (wallH - 10)/2, frontZ), wallColor, wallMaterial)
        PartBuilder.makePart(m, "Desk", Vector3.new(12, 3.0, 4.0), CFrame.new(cx, floorY + 1.5, sz * 81), Color3.fromRGB(145, 100, 60), Enum.Material.Wood)
        PartBuilder.makeSign(m, "Sign", label, Vector3.new(24, 2.6, 0.3),
            Vector3.new(cx, floorY + 14.5, frontZ - sz * 0.8), sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
            Color3.fromRGB(45, 55, 70), Color3.fromRGB(255, 255, 255))
    end

    -- ด้านหน้า: ที่เก็บจาน (ซ้าย) / ห้องสำนักงาน (ขวา)
    buildOpenDishReturn("DishReturn_South", -49, 1)
    buildCompactRoom("Office_South", "ห้องสำนักงาน\nOFFICE", 49, 1)
    -- ด้านหลัง: ห้องพัสดุ (ซ้าย) / ที่เก็บจาน (ขวา)
    buildCompactRoom("Storage_North", "ห้องพัสดุ\nSTORAGE", -49, -1)
    buildOpenDishReturn("DishReturn_North", 49, -1)

    ------------------------------------------------------------------
    -- 5. ห้องกินข้าว 4 ห้อง (ห้องรับประทานอาหารปรับอากาศ / AC DINING ROOMS)
    --    X = ±68..±98 (กว้าง 30), Z = ±86..±120 (ลึก 34)
    --    เว้นทางเดินกว้าง 18 studs (X = ±98..±116) หน้าประตูห้องน้ำที่หันหน้าเข้าหาลิฟต์และบันได!
    ------------------------------------------------------------------
    local acDiningFolder = Instance.new("Model")
    acDiningFolder.Name = "AC_DiningRooms_4Zones"
    acDiningFolder.Parent = floor2

    local acConfigs = {
        { name = "AC_Dining_TopLeft",  cx = -83, sz = -1, title = "ห้องกินข้าวปรับอากาศ 1\nAC DINING ROOM" },
        { name = "AC_Dining_TopRight", cx =  83, sz = -1, title = "ห้องกินข้าวปรับอากาศ 2\nAC DINING ROOM" },
        { name = "AC_Dining_BotLeft",  cx = -83, sz =  1, title = "ห้องกินข้าวปรับอากาศ 3\nAC DINING ROOM" },
        { name = "AC_Dining_BotRight", cx =  83, sz =  1, title = "ห้องกินข้าวปรับอากาศ 4\nAC DINING ROOM" },
    }

    for _, ac in ipairs(acConfigs) do
        local rm = Instance.new("Model")
        rm.Name = ac.name
        rm.Parent = acDiningFolder

        local cx, sz = ac.cx, ac.sz
        local sx = (cx > 0) and 1 or -1
        local roomW = 30 -- X = ±68..±98
        local roomD = 34 -- Z = ±86..±120
        local cz = sz * 103
        local frontZ = sz * 86
        local outerZ = sz * (120 - wallThick/2)
        local outerSideX = cx + sx * (roomW / 2 - wallThick / 2) -- ผนังด้านติดทางเดินหน้าห้องน้ำ (X = ±98)

        -- พื้นลายไม้ลามิเนตอบอุ่นในห้องกินข้าวติดแอร์
        PartBuilder.makePart(rm, "WoodFloor", Vector3.new(roomW, 0.12, roomD),
            CFrame.new(cx, floorY + 0.06, cz), Color3.fromRGB(175, 135, 95), Enum.Material.WoodPlanks)

        -- ผนังหลังชิดขอบตึก (Z = ±120) และผนังข้างด้านติดทางเดินห้องน้ำ (X = ±98 เป็นกระจกครึ่งบน)
        PartBuilder.makePart(rm, "Wall_OuterZ", Vector3.new(roomW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH/2, outerZ), wallColor, wallMaterial)
        PartBuilder.makePart(rm, "SideWall_Low", Vector3.new(wallThick, 4.0, roomD),
            CFrame.new(outerSideX, floorY + 2.0, cz), wallColor, wallMaterial)
        PartBuilder.makePart(rm, "SideWall_Glass", Vector3.new(0.5, 9.0, roomD - 2),
            CFrame.new(outerSideX, floorY + 8.5, cz), Color3.fromRGB(195, 230, 245), Enum.Material.Glass, { Transparency = 0.55 })
        PartBuilder.makePart(rm, "SideWall_Header", Vector3.new(wallThick, wallH - 13, roomD),
            CFrame.new(outerSideX, floorY + 13 + (wallH - 13)/2, cz), wallColor, wallMaterial)

        -- ผนังด้านหน้า (Z = ±86) เป็นกระจกใสกรอบอลูมิเนียม + ช่องประตูทางเข้ากลางกว้าง 12 studs
        local doorW = 12
        local glassW = (roomW - doorW) / 2 -- 9
        PartBuilder.makePart(rm, "GlassWall_L", Vector3.new(glassW, 13, 0.6),
            CFrame.new(cx - (doorW/2 + glassW/2), floorY + 6.5, frontZ), Color3.fromRGB(195, 230, 245), Enum.Material.Glass, { Transparency = 0.55 })
        PartBuilder.makePart(rm, "GlassWall_R", Vector3.new(glassW, 13, 0.6),
            CFrame.new(cx + (doorW/2 + glassW/2), floorY + 6.5, frontZ), Color3.fromRGB(195, 230, 245), Enum.Material.Glass, { Transparency = 0.55 })
        PartBuilder.makePart(rm, "DoorFrame_L", Vector3.new(1.0, 13, 1.2), CFrame.new(cx - doorW/2, floorY + 6.5, frontZ), frameDark, Enum.Material.Metal)
        PartBuilder.makePart(rm, "DoorFrame_R", Vector3.new(1.0, 13, 1.2), CFrame.new(cx + doorW/2, floorY + 6.5, frontZ), frameDark, Enum.Material.Metal)
        PartBuilder.makePart(rm, "FrontHeader", Vector3.new(roomW, wallH - 13, 1.4),
            CFrame.new(cx, floorY + 13 + (wallH - 13)/2, frontZ), wallColor, wallMaterial)

        PartBuilder.makeSign(rm, "Sign", ac.title, Vector3.new(26, 3.0, 0.4),
            Vector3.new(cx, floorY + 16, frontZ - sz * 0.9), sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
            Color3.fromRGB(25, 115, 65), Color3.fromRGB(255, 255, 255))

        for _, ax in ipairs({ -7, 7 }) do
            PartBuilder.makePart(rm, "AirCon_" .. ax, Vector3.new(7, 2.2, 2.0),
                CFrame.new(cx + ax, floorY + 17, sz * 117.5), Color3.fromRGB(245, 248, 252), Enum.Material.SmoothPlastic)
        end

        -- เพิ่มชุดโต๊ะอาหารไม้โมเดิร์นเป็น 6 ชุดต่อห้อง (2 คอลัมน์ x 3 แถว = 24 โต๊ะรวม 4 ห้อง)
        for _, tx in ipairs({ -7.5, 7.5 }) do
            for _, tzOff in ipairs({ -9.5, 0, 9.5 }) do
                local tX = cx + tx
                local tZ = cz + tzOff
                PartBuilder.makePart(rm, "DiningTable", Vector3.new(8.0, 0.4, 3.8),
                    CFrame.new(tX, floorY + 3.2, tZ), Color3.fromRGB(215, 170, 115), Enum.Material.Wood)
                PartBuilder.makePart(rm, "TablePedestal", Vector3.new(1.0, 3.0, 2.4),
                    CFrame.new(tX, floorY + 1.5, tZ), frameDark, Enum.Material.Metal)
                for _, chairX in ipairs({ -2.4, 2.4 }) do
                    for _, chairZ in ipairs({ -2.6, 2.6 }) do
                        PartBuilder.makePart(rm, "ChairSeat", Vector3.new(1.9, 0.3, 1.9),
                            CFrame.new(tX + chairX, floorY + 1.9, tZ + chairZ), Color3.fromRGB(60, 130, 85), Enum.Material.SmoothPlastic)
                        PartBuilder.makePart(rm, "ChairLeg", Vector3.new(0.4, 1.8, 0.4),
                            CFrame.new(tX + chairX, floorY + 0.9, tZ + chairZ), frameDark, Enum.Material.Metal)
                    end
                end
            end
        end
    end

    ------------------------------------------------------------------
    -- 6. ห้องน้ำ 4 มุม — หันหน้าเข้าหาลิฟต์และบันได (ประตูอยู่ฝั่ง X = ±116 หันเข้าหาตึก!)
    --    ขนาดมุมละ 34 x 44 studs (X = ±116..±150, Z = ±76..±120)
    --    แบ่งครึ่งตามแนว Z เป็น 2 ห้องย่อย (ห้องละ 34 x 22 studs) หันประตูเข้าหาลิฟต์และบันได:
    --      - ห้องริมนอก (Z = ±98..±120): ห้องน้ำชาย (MALE 🚹)
    --      - ห้องริมใน  (Z = ±76..±98):  ห้องน้ำหญิง (FEMALE 🚺)
    ------------------------------------------------------------------
    local restrooms = Instance.new("Model")
    restrooms.Name = "Restrooms_4Corners_MaleAndFemale"
    restrooms.Parent = floor2

    local rrW = 34 -- ความลึกแนว X (X = ±116..±150)
    local rrL = 44 -- ความยาวแนว Z (Z = ±76..±120)
    local cornerBlocks = {
        { name = "RestroomCorner_TopLeft",  sx = -1, sz = -1 },
        { name = "RestroomCorner_TopRight", sx =  1, sz = -1 },
        { name = "RestroomCorner_BotLeft",  sx = -1, sz =  1 },
        { name = "RestroomCorner_BotRight", sx =  1, sz =  1 },
    }

    for _, cb in ipairs(cornerBlocks) do
        local rModel = Instance.new("Model")
        rModel.Name = cb.name
        rModel.Parent = restrooms

        local sx, sz = cb.sx, cb.sz
        local cx = sx * (150 - rrW / 2) -- ±133
        local cz = sz * (120 - rrL / 2) -- ±98 (เส้นแบ่งกึ่งกลางระหว่างชายกับหญิง)
        local innerX = sx * (150 - rrW) -- ±116 (ผนังด้านหน้าห้องน้ำที่หันหน้าไปหาลิฟต์และบันได!)
        local innerZ = sz * (120 - rrL) -- ±76
        -- ป้ายและประตูหันเข้าหาลิฟต์และบันได (ฝั่งซ้าย sx=-1 หันไปทาง +X = Right, ฝั่งขวา sx=+1 หันไปทาง -X = Left)
        local signFace = (sx < 0) and Enum.NormalId.Right or Enum.NormalId.Left

        -- ผนังทึบ 3 ด้าน (ริมนอก X=±150, ริมนอก Z=±120, และด้านติดร้านข้าว Z=±76) + ผนังกั้นกลางแยกชาย-หญิง (Z=±98)
        PartBuilder.makePart(rModel, "Wall_Outer_X", Vector3.new(wallThick, wallH, rrL),
            CFrame.new(sx * (150 - wallThick/2), floorY + wallH/2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Outer_Z", Vector3.new(rrW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH/2, sz * (120 - wallThick/2)), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Inner_Z", Vector3.new(rrW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH/2, innerZ + sz * (wallThick/2)), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_CenterDivider_MF", Vector3.new(rrW, wallH, 1.4),
            CFrame.new(cx, floorY + wallH/2, cz), wallColor, wallMaterial)

        -- สร้าง 2 ห้องคู่กันในแต่ละมุม หันหน้าไปทางลิฟต์กับบันได (ที่ X = ±116):
        --   1. ห้องน้ำชาย (midZ = sz * 109)
        --   2. ห้องน้ำหญิง (midZ = sz * 87)
        local halves = {
            { sub = "Male",   midZ = sz * 109, label = "ห้องน้ำชาย\nMALE WC",   color = Color3.fromRGB(20, 90, 165) },
            { sub = "Female", midZ = sz * 87,  label = "ห้องน้ำหญิง\nFEMALE WC", color = Color3.fromRGB(185, 45, 95) },
        }
        for _, h in ipairs(halves) do
            -- ผนังด้านหน้า (ที่ X = ±116) กว้าง 22 studs เปิดช่องประตูตรงกลางกว้าง 8 studs หันหน้าหาลิฟต์และบันได
            PartBuilder.makePart(rModel, "FrontWall_A_" .. h.sub, Vector3.new(wallThick, wallH, 7),
                CFrame.new(innerX + sx * (wallThick/2), floorY + wallH/2, h.midZ - 7.5), wallColor, wallMaterial)
            PartBuilder.makePart(rModel, "FrontWall_B_" .. h.sub, Vector3.new(wallThick, wallH, 7),
                CFrame.new(innerX + sx * (wallThick/2), floorY + wallH/2, h.midZ + 7.5), wallColor, wallMaterial)
            PartBuilder.makePart(rModel, "FrontHeader_" .. h.sub, Vector3.new(wallThick, 6.0, 8),
                CFrame.new(innerX + sx * (wallThick/2), floorY + wallH - 3.0, h.midZ), wallColor, wallMaterial)

            -- ป้ายห้องน้ำชาย / หญิง เหนือประตู หันหน้าไปหาลิฟต์กับบันไดชัดเจน
            PartBuilder.makeSign(rModel, "Sign_" .. h.sub, h.label, Vector3.new(0.4, 3.2, 16),
                Vector3.new(innerX - sx * 0.3, floorY + wallH - 3.2, h.midZ), signFace, h.color, Color3.fromRGB(255, 255, 255))

            -- อ่างล้างมือ + กระจกเงา + ห้องส้วมย่อยด้านในแต่ละห้อง
            PartBuilder.makePart(rModel, "Sink_" .. h.sub, Vector3.new(12, 3.2, 2.6),
                CFrame.new(cx - sx * 4, floorY + 1.6, h.midZ - sz * 7.0), Color3.fromRGB(215, 220, 225), Enum.Material.Marble)
            PartBuilder.makePart(rModel, "Mirror_" .. h.sub, Vector3.new(10, 4.5, 0.2),
                CFrame.new(cx - sx * 4, floorY + 6.0, h.midZ - sz * 8.2), Color3.fromRGB(190, 225, 245), Enum.Material.Glass, { Reflectance = 0.4 })
            for st = 1, 2 do
                local stX = (cx + sx * 2) + sx * ((st - 1) * 9)
                PartBuilder.makePart(rModel, "Cubicle_" .. h.sub .. "_" .. st, Vector3.new(0.4, 8.5, 7),
                    CFrame.new(stX - sx * 4.0, floorY + 4.25, h.midZ + sz * 5.0), Color3.fromRGB(200, 205, 210), Enum.Material.SmoothPlastic)
                PartBuilder.makePart(rModel, "Toilet_" .. h.sub .. "_" .. st, Vector3.new(2.2, 2.2, 2.2),
                    CFrame.new(stX, floorY + 1.1, h.midZ + sz * 6.5), Color3.fromRGB(250, 250, 252), Enum.Material.SmoothPlastic)
            end
        end
    end

    ------------------------------------------------------------------
    -- 7. ปีกซ้าย / ขวา: ร้านข้าว & ร้านน้ำ 8 ร้าน (ลึกสมส่วน 26 studs: X = ±124..±150)
    ------------------------------------------------------------------
    local stallDepth = 26
    local stallWidth = 28
    local totalStallsSpan = stallWidth * 4 -- 112 (Z = -56..+56)

    local function buildStallRow(modelName, side, stalls)
        local row = Instance.new("Model")
        row.Name = modelName
        row.Parent = floor2

        local outerWallX = side * (150 - wallThick/2)
        local dividerMidX = side * (150 - stallDepth / 2)
        local counterX = side * (150 - stallDepth + 2.0)
        local backBenchX = side * (150 - 4.0)

        PartBuilder.makePart(row, "OuterWall", Vector3.new(wallThick, wallH, 152),
            CFrame.new(outerWallX, floorY + wallH/2, 0), wallColor, wallMaterial)

        for _, endZ in ipairs({ -totalStallsSpan / 2, totalStallsSpan / 2 }) do
            PartBuilder.makePart(row, "EndWall_" .. endZ, Vector3.new(stallDepth, wallH, 1.2),
                CFrame.new(dividerMidX, floorY + wallH/2, endZ), wallColor, wallMaterial)
        end

        for idx, stall in ipairs(stalls) do
            local sM = Instance.new("Model")
            sM.Name = modelName .. "_Stall" .. idx
            sM.Parent = row

            if idx < #stalls then
                PartBuilder.makePart(sM, "Divider", Vector3.new(stallDepth, wallH, 1.0),
                    CFrame.new(dividerMidX, floorY + wallH/2, stall.z + stallWidth / 2), wallColor, wallMaterial)
            end

            PartBuilder.makePart(sM, "BackKitchenBench", Vector3.new(3.2, 3.6, stallWidth - 3),
                CFrame.new(backBenchX, floorY + 1.8, stall.z), PartBuilder.COLORS.steel, Enum.Material.Metal)

            local cLen = stallWidth - 5
            PartBuilder.makePart(sM, "Counter", Vector3.new(3.6, 3.8, cLen),
                CFrame.new(counterX, floorY + 1.9, stall.z - 1.5), Color3.fromRGB(220, 215, 205), Enum.Material.Concrete)
            PartBuilder.makePart(sM, "CounterTop", Vector3.new(4.2, 0.4, cLen + 0.6),
                CFrame.new(counterX, floorY + 4.0, stall.z - 1.5), Color3.fromRGB(60, 60, 65), Enum.Material.Granite)
            PartBuilder.makePart(sM, "GlassCase", Vector3.new(2.4, 2.8, cLen - 4),
                CFrame.new(counterX, floorY + 5.6, stall.z - 1.5), Color3.fromRGB(220, 240, 255), Enum.Material.Glass, { Transparency = 0.6 })

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
    -- 8. กลางโรงอาหาร: เพิ่มจำนวนโต๊ะสแตนเลส มจพ. (6 แถว x 7 คอลัมน์ = 42 โต๊ะ, โต๊ะละ 6 ที่นั่ง!)
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

    local tableRowsZ = { -54, -33, -11, 11, 33, 54 }
    local tableColsX = { -96, -64, -32, 0, 32, 64, 96 }

    for rIdx, tz in ipairs(tableRowsZ) do
        for cIdx, tx in ipairs(tableColsX) do
            -- ขยับหลบเสาโครงสร้าง 4 ต้นที่ (±65, ±36) เล็กน้อยเพื่อไม่ให้โต๊ะชนเสา
            local adjZ = tz
            if math.abs( math.abs(tx) - 64 ) < 4 and math.abs( math.abs(tz) - 33 ) < 5 then
                adjZ = (tz > 0) and 27 or -27
            end

            local t = Instance.new("Model")
            t.Name = string.format("CanteenTable_R%d_C%d", rIdx, cIdx)
            t.Parent = diningArea
            PartBuilder.makePart(t, "TableTop", Vector3.new(17, 0.4, 5.2), CFrame.new(tx, floorY + 3.4, adjZ), PartBuilder.COLORS.steel, Enum.Material.Metal)
            PartBuilder.makePart(t, "TableLegL", Vector3.new(0.6, 3.2, 4.6), CFrame.new(tx - 7.0, floorY + 1.6, adjZ), Color3.fromRGB(80, 85, 90), Enum.Material.Metal)
            PartBuilder.makePart(t, "TableLegR", Vector3.new(0.6, 3.2, 4.6), CFrame.new(tx + 7.0, floorY + 1.6, adjZ), Color3.fromRGB(80, 85, 90), Enum.Material.Metal)
            for _, sx in ipairs({ -5.5, 0, 5.5 }) do
                for _, sz in ipairs({ -3.8, 3.8 }) do
                    PartBuilder.makeCylinder(t, "StoolSeat", Vector3.new(0.4, 2.1, 2.1), CFrame.new(tx + sx, floorY + 2.0, adjZ + sz) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 65, 70), Enum.Material.Metal)
                    PartBuilder.makePart(t, "StoolLeg", Vector3.new(0.4, 2.0, 0.4), CFrame.new(tx + sx, floorY + 1.0, adjZ + sz), Color3.fromRGB(100, 105, 110), Enum.Material.Metal)
                end
            end
        end
    end

    ------------------------------------------------------------------
    -- 9. ไฟส่องสว่างชั้น 2
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
        Vector3.new(-89, floorY + wallH - 2, -103),
        Vector3.new( 89, floorY + wallH - 2, -103),
        Vector3.new(-89, floorY + wallH - 2,  103),
        Vector3.new( 89, floorY + wallH - 2,  103),
        Vector3.new(0, floorY + 14, stairZ),
    }
    for idx, pos in ipairs(lightPoints) do
        PartBuilder.addPointLight(lights, "Light_F2_" .. idx, pos, Color3.fromRGB(255, 248, 235), 45, 0.9)
    end

    print("🍜 [Floor 2] ปรับโถงลิฟต์-บันไดโปร่งโล่ง + ห้องน้ำ 4 มุม (ชาย-หญิงคู่กันทุกมุม) + ห้องกินข้าวติดแอร์ 4 ห้อง เสร็จสมบูรณ์!")
end

return Floor2_Canteen
