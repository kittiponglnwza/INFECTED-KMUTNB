--[[
    Floor12_TopSportsArena.lua
    โครงสร้างและรายละเอียดชั้น 12 (ชั้นบนสุดของอาคาร 40 ปี มจพ. / อาคาร 77)
    สร้างตามแปลนจริง "แปลนห้องน้ำ ชั้น 12" (media_1794263539167_239ffc99.jpg) และข้อมูลทางการ มจพ.:
      1. การเข้าถึง: **ขึ้น-ลงได้ทางบันไดเท่านั้น (Stairs Only)** ลิฟต์โดยสารสิ้นสุดที่ชั้น 11
         - ปล่องลิฟต์ทิศเหนือและทิศใต้บนชั้น 12 ปิดทึบพร้อมป้ายแจ้งเตือนชัดเจน
         - บันได U-Stair ทิศเหนือและทิศใต้เชื่อมขึ้นมาจากชั้น 11 พร้อมราวกันตกสแตนเลสรอบปากปล่องบันได
      2. แถบบน (Z = -120..-86) และแถบล่าง (Z = +86..+120) เรียบเสมอระนาบ Z = ±86 เป๊ะ:
         - ห้องน้ำ WC.2 (ทิศเหนือ ติดปล่องลิฟต์ X = -98..-68) และ WC.1 (ทิศใต้ ติดบันได X = -98..-68) ตามตำแหน่งในแปลนจริง
         - ห้องปิดมุมซ้ายและขวาเรียงหน้ากระดานตรงแนว Z = ±86 ไม่มียื่นเหลื่อม
      3. โซนสนามกีฬาในร่มชั้น 12 (3 โซนเรียงจากซ้ายไปขวาตามแปลนจริง พื้นเรียบเสมอโถง 100%):
         - ฝั่งซ้าย (Grid A-D, X = -134..-82): สนามเซปักตะกร้อมาตรฐาน 2 สนาม (เหนือ-ใต้) พร้อมตาข่ายและเส้นสนามครบ
         - ตรงกลาง (Grid D-G, X = -62..+14): สนามเทนนิสในร่มมาตรฐาน พร้อมเส้นเดี่ยว/เส้นคู่/เส้นเสิร์ฟ ตาข่าย และเก้าอี้กรรมการตรงกลางตามแปลน
         - ฝั่งขวา (Grid G-J, X = +30..+134): สนามฟุตซอล/แฮนด์บอล พร้อมวงกลมกลางสนาม กรอบเขตโทษสี่เหลี่ยมซ้อน โค้งหน้าเขตโทษ และประตูทั้ง 2 ฝั่ง
      4. หลังคาใหญ่บนสุดของอาคารที่ชั้น 12 (Y = 265.0) พร้อมโครงถักเหล็กและโคมไฟสนามกีฬาในร่ม
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local StairBuilder = require(script.Parent.Parent.utils.StairBuilder)
local SlabBuilder = require(script.Parent.Parent.utils.SlabBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Floor12_TopSportsArena = {}

function Floor12_TopSportsArena.build(parent)
    local floor12 = Instance.new("Model")
    floor12.Name = "Floor_12_TopSportsArena"
    floor12.Parent = parent

    local floorNum = 12
    local floorY = Layout.floorY(floorNum) -- 243.0
    local wallH = Layout.FLOOR_HEIGHT      -- 22.0
    local wallThick = Layout.WALL_THICK    -- 2.0
    local wallColor = Color3.fromRGB(240, 237, 230)
    local wallMaterial = Enum.Material.Concrete
    local floorColor = Color3.fromRGB(216, 214, 208)
    local lineWhite = Color3.fromRGB(250, 250, 252)
    local lineYellow = Color3.fromRGB(255, 215, 45)

    local core = Layout.CORE
    local body = Layout.BODY
    local frontStair = Layout.STAIRS.Front
    local rearStair = Layout.STAIRS.Rear
    local frontLift = Layout.LIFTS.Front
    local rearLift = Layout.LIFTS.Rear

    ------------------------------------------------------------------
    -- 1. พื้นชั้น 12 ผืนเดียวกันทั้งชั้น (300 x 240 studs) เจาะเฉพาะช่องบันได 2 จุดจากชั้น 11
    ------------------------------------------------------------------
    SlabBuilder.build(
        floor12,
        "Floor12_Slab",
        {
            { minX = -body.halfX, maxX = body.halfX, minZ = -body.halfZ, maxZ = body.halfZ },
        },
        {
            StairBuilder.slabHole(frontStair),
            StairBuilder.slabHole(rearStair),
        },
        floorY, 2.0, floorColor, Enum.Material.Concrete
    )

    ------------------------------------------------------------------
    -- 2. คอร์บันได (เปิดใช้งาน) & ปล่องลิฟต์ปิดตาย (ชั้น 12 ขึ้นทางบันไดเท่านั้น!)
    ------------------------------------------------------------------
    local function buildTopStairCoreF12(folder, def)
        local m = Instance.new("Model")
        m.Name = def.name .. "_F12"
        m.Parent = folder

        StairBuilder.buildEnclosure(m, def, floorY, wallH, floorNum)
        local g = StairBuilder.geometry(def)
        local railLen = StairBuilder.FLIGHT_RUN + StairBuilder.LANDING_DEPTH
        local railMidX = (g.x(g.tFlightStart) + g.x(g.tEnd)) / 2
        PartBuilder.makePart(m, "GuardRail_CenterTop", Vector3.new(railLen, 0.3, 0.3),
            CFrame.new(railMidX, floorY + 3.4, g.cz), Color3.fromRGB(185, 192, 200), Enum.Material.Metal)
        PartBuilder.makePart(m, "GuardRail_CenterMid", Vector3.new(railLen, 1.8, 0.2),
            CFrame.new(railMidX, floorY + 1.6, g.cz), Color3.fromRGB(70, 76, 84), Enum.Material.Metal)
        PartBuilder.makePart(m, "GuardRail_Front", Vector3.new(0.4, 3.4, g.laneWidth),
            CFrame.new(g.x(g.tFlightStart) + g.e * 0.2, floorY + 1.7, g.flight1Z), Color3.fromRGB(70, 76, 84), Enum.Material.Metal)
    end

    local function buildSealedElevatorShaftF12(folder, def)
        local m = Instance.new("Model")
        m.Name = def.name .. "_SealedShaft_F12"
        m.Parent = folder

        local cx, cz, d = def.centerX, def.centerZ, def.doorDir
        local sz = (cz > 0) and 1 or -1
        local halfW = core.sideWidth / 2 -- 19
        local frontWallX = cx + d * (halfW - wallThick / 2)

        -- ผนังปล่องลิฟต์ปิดทึบทั้ง 4 ด้าน (ไม่มีประตูลิฟต์เปิดที่ชั้น 12 เพราะลิฟต์สุดที่ชั้น 11)
        PartBuilder.makePart(m, "ShaftWall_OuterZ", Vector3.new(core.sideWidth, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, sz * (core.outerZ - wallThick / 2)), wallColor, wallMaterial)
        PartBuilder.makePart(m, "ShaftWall_InnerZ", Vector3.new(core.sideWidth, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, sz * (core.innerZ + wallThick / 2)), wallColor, wallMaterial)
        PartBuilder.makePart(m, "ShaftWall_BackX", Vector3.new(wallThick, wallH, core.depth),
            CFrame.new(cx - d * (halfW - wallThick / 2), floorY + wallH / 2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(m, "ShaftWall_FrontSolid", Vector3.new(wallThick, wallH, core.depth),
            CFrame.new(frontWallX, floorY + wallH / 2, cz), wallColor, wallMaterial)

        -- ประตูห้องเครื่องลิฟต์บานเหล็กปิดล็อก + ป้ายแจ้งว่าชั้น 12 ขึ้นทางบันไดเท่านั้น
        local faceX = frontWallX + d * (wallThick / 2 + 0.05)
        PartBuilder.makePart(m, "ServiceHatchFrame", Vector3.new(0.12, 9.2, 6.4),
            CFrame.new(faceX, floorY + 4.6, cz), Color3.fromRGB(48, 52, 58), Enum.Material.Metal)
        PartBuilder.makePart(m, "ServiceHatchDoor", Vector3.new(0.16, 8.6, 5.8),
            CFrame.new(faceX, floorY + 4.3, cz), Color3.fromRGB(115, 122, 130), Enum.Material.Metal)

        PartBuilder.makeSign(m, "StairsOnlyNotice",
            "⛔ ลิฟต์โดยสารสิ้นสุดที่ชั้น 11 (ห้องเครื่องลิฟต์)\nชั้น 12 ขึ้น-ลงทางบันไดเท่านั้น (STAIRS ACCESS ONLY)",
            Vector3.new(0.15, 3.2, 18.0),
            Vector3.new(faceX + d * 0.05, floorY + 12.5, cz),
            d > 0 and Enum.NormalId.Right or Enum.NormalId.Left,
            Color3.fromRGB(145, 28, 35), Color3.fromRGB(255, 255, 255))
    end

    local northCore = Instance.new("Model")
    northCore.Name = "NorthCore_F12"
    northCore.Parent = floor12
    buildSealedElevatorShaftF12(northCore, rearLift)
    buildTopStairCoreF12(northCore, rearStair)
    PartBuilder.makePart(northCore, "NorthEndWall_Low", Vector3.new(core.centerWidth, 5.0, wallThick),
        CFrame.new(0, floorY + 2.5, -core.outerZ + wallThick / 2), wallColor, wallMaterial)
    PartBuilder.makePart(northCore, "NorthEndGlass", Vector3.new(core.centerWidth, wallH - 9, 0.4),
        CFrame.new(0, floorY + 5 + (wallH - 9) / 2, -core.outerZ + 1.0), Color3.fromRGB(165, 205, 220), Enum.Material.Glass, { Transparency = 0.55 })
    PartBuilder.makePart(northCore, "NorthEndHeader", Vector3.new(core.centerWidth, 4.0, wallThick),
        CFrame.new(0, floorY + wallH - 2.0, -core.outerZ + wallThick / 2), wallColor, wallMaterial)

    local southCore = Instance.new("Model")
    southCore.Name = "SouthCore_F12"
    southCore.Parent = floor12
    buildTopStairCoreF12(southCore, frontStair)
    buildSealedElevatorShaftF12(southCore, frontLift)
    PartBuilder.makePart(southCore, "SouthEndWall_Low", Vector3.new(core.centerWidth, 5.0, wallThick),
        CFrame.new(0, floorY + 2.5, core.outerZ - wallThick / 2), wallColor, wallMaterial)
    PartBuilder.makePart(southCore, "SouthEndGlass", Vector3.new(core.centerWidth, wallH - 9, 0.4),
        CFrame.new(0, floorY + 5 + (wallH - 9) / 2, core.outerZ - 1.0), Color3.fromRGB(165, 205, 220), Enum.Material.Glass, { Transparency = 0.55 })
    PartBuilder.makePart(southCore, "SouthEndHeader", Vector3.new(core.centerWidth, 4.0, wallThick),
        CFrame.new(0, floorY + wallH - 2.0, core.outerZ - wallThick / 2), wallColor, wallMaterial)

    ------------------------------------------------------------------
    -- 3. ห้องน้ำ WC.1 & WC.2 และห้องปิดแถบบน-ล่างตามแปลนชั้น 12 (เรียบเสมอระนาบ Z = ±86)
    --    - ในแปลนชั้น 12: WC.2 อยู่แถบบน (X = -98..-68) ติดปล่องลิฟต์เหนือ, WC.1 อยู่แถบล่าง (X = -98..-68) ติดบันไดใต้
    ------------------------------------------------------------------
    local bandRooms = Instance.new("Model")
    bandRooms.Name = "NorthSouthBand_WC_And_Rooms_F12"
    bandRooms.Parent = floor12

    local wcConfigs = {
        { name = "Restroom_WC2_North", cx = -83, sz = -1, code = "ห้องน้ำชั้น 12 (WC.2)\nRESTROOM WC.2" },
        { name = "Restroom_WC1_South", cx = -83, sz =  1, code = "ห้องน้ำชั้น 12 (WC.1)\nRESTROOM WC.1" },
    }

    for _, wc in ipairs(wcConfigs) do
        local wm = Instance.new("Model")
        wm.Name = wc.name
        wm.Parent = bandRooms

        local cx, sz = wc.cx, wc.sz -- cx = -83 (X = -98..-68, กว้าง 30 studs)
        local roomW = 30
        local roomD = 34
        local cz = sz * 103
        local innerZ = sz * 86
        local outerZ = sz * (120 - wallThick / 2)

        PartBuilder.makePart(wm, "Wall_OuterZ", Vector3.new(roomW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, outerZ), wallColor, wallMaterial)
        PartBuilder.makePart(wm, "Wall_LeftX", Vector3.new(wallThick, wallH, roomD),
            CFrame.new(cx - roomW / 2 + wallThick / 2, floorY + wallH / 2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(wm, "Wall_RightX", Vector3.new(wallThick, wallH, roomD),
            CFrame.new(cx + roomW / 2 - wallThick / 2, floorY + wallH / 2, cz), wallColor, wallMaterial)

        -- ผนังด้านหน้า (Z = ±86) เว้นช่องประตูทางเข้ากว้าง 7 studs ตรงกลาง
        PartBuilder.makePart(wm, "FrontWall_L", Vector3.new(11.5, wallH, wallThick),
            CFrame.new(cx - 9.25, floorY + wallH / 2, innerZ + sz * (wallThick / 2)), wallColor, wallMaterial)
        PartBuilder.makePart(wm, "FrontWall_R", Vector3.new(11.5, wallH, wallThick),
            CFrame.new(cx + 9.25, floorY + wallH / 2, innerZ + sz * (wallThick / 2)), wallColor, wallMaterial)
        PartBuilder.makePart(wm, "FrontHeader", Vector3.new(7.0, 6.0, wallThick),
            CFrame.new(cx, floorY + wallH - 3.0, innerZ + sz * (wallThick / 2)), wallColor, wallMaterial)

        PartBuilder.makeSign(wm, "WCSign", wc.code, Vector3.new(16, 2.8, 0.15),
            Vector3.new(cx, floorY + wallH - 3.2, innerZ - sz * 0.1),
            sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
            Color3.fromRGB(20, 90, 165), Color3.fromRGB(255, 255, 255))

        -- เคาน์เตอร์อ่างล้างมือ 3 อ่าง + กระจกเงา + ห้องส้วม 3 ห้องด้านในตามแปลน WC.1 / WC.2
        PartBuilder.makePart(wm, "SinkCounter", Vector3.new(2.2, 3.2, 14.0),
            CFrame.new(cx - 11.5, floorY + 1.6, cz), Color3.fromRGB(215, 220, 225), Enum.Material.Marble)
        PartBuilder.makePart(wm, "Mirror", Vector3.new(0.2, 4.2, 13.0),
            CFrame.new(cx - 12.8, floorY + 5.8, cz), Color3.fromRGB(190, 225, 245), Enum.Material.Glass, { Reflectance = 0.4 })

        for st = 1, 3 do
            local stZ = cz - 10 + (st - 1) * 8.5
            PartBuilder.makePart(wm, "CubiclePartition_" .. st, Vector3.new(6.5, 8.5, 0.4),
                CFrame.new(cx + 8.5, floorY + 4.25, stZ - 4.0), Color3.fromRGB(200, 205, 210), Enum.Material.SmoothPlastic)
            PartBuilder.makePart(wm, "Toilet_" .. st, Vector3.new(2.2, 2.2, 2.0),
                CFrame.new(cx + 10.5, floorY + 1.1, stZ), Color3.fromRGB(250, 250, 252), Enum.Material.SmoothPlastic)
        end
    end

    -- ห้องปิดฝั่งซ้ายของ WC (X = -150..-98, กว้าง 52 studs) และฝั่งขวาของบันได/ลิฟต์ (X = +68..+150, กว้าง 82 studs)
    local closedBlocksF12 = {
        { name = "ClosedRoom_NW_West", minX = -150, maxX = -98, sz = -1, label = "ห้องเก็บอุปกรณ์กีฬา 1201 (ปิด)\nSPORTS STORAGE (CLOSED)" },
        { name = "ClosedRoom_SW_West", minX = -150, maxX = -98, sz =  1, label = "ห้องเครื่องและซ่อมบำรุง 1202 (ปิด)\nMAINTENANCE ROOM (CLOSED)" },
        { name = "ClosedRoom_NE_East", minX =   68, maxX = 150, sz = -1, label = "ห้องชมรมกีฬาชั้น 1203 (ปิด)\nSPORTS CLUB ROOM (CLOSED)" },
        { name = "ClosedRoom_SE_East", minX =   68, maxX = 150, sz =  1, label = "ห้องควบคุมไฟสนาม 1204 (ปิด)\nCONTROL ROOM (CLOSED)" },
    }

    for _, cb in ipairs(closedBlocksF12) do
        local rm = Instance.new("Model")
        rm.Name = cb.name
        rm.Parent = bandRooms

        local w = cb.maxX - cb.minX
        local cx = (cb.minX + cb.maxX) / 2
        local sz = cb.sz
        local cz = sz * 103
        local frontWallZ = sz * (86 + wallThick / 2)
        local outerWallZ = sz * (120 - wallThick / 2)

        PartBuilder.makePart(rm, "Wall_OuterZ", Vector3.new(w, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, outerWallZ), wallColor, wallMaterial)
        PartBuilder.makePart(rm, "Wall_FrontZ", Vector3.new(w, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, frontWallZ), wallColor, wallMaterial)
        PartBuilder.makePart(rm, "Wall_LeftX", Vector3.new(wallThick, wallH, 34),
            CFrame.new(cb.minX + wallThick / 2, floorY + wallH / 2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(rm, "Wall_RightX", Vector3.new(wallThick, wallH, 34),
            CFrame.new(cb.maxX - wallThick / 2, floorY + wallH / 2, cz), wallColor, wallMaterial)

        local doorFaceZ = sz * 86 - sz * 0.05
        PartBuilder.makePart(rm, "DoorFrame", Vector3.new(8.8, 11.2, 0.12),
            CFrame.new(cx, floorY + 5.6, doorFaceZ), Color3.fromRGB(42, 46, 54), Enum.Material.Metal)
        PartBuilder.makePart(rm, "DoorPanelL", Vector3.new(3.85, 10.6, 0.16),
            CFrame.new(cx - 2.0, floorY + 5.3, doorFaceZ), Color3.fromRGB(85, 95, 108), Enum.Material.Metal)
        PartBuilder.makePart(rm, "DoorPanelR", Vector3.new(3.85, 10.6, 0.16),
            CFrame.new(cx + 2.0, floorY + 5.3, doorFaceZ), Color3.fromRGB(85, 95, 108), Enum.Material.Metal)

        PartBuilder.makeSign(rm, "RoomSign", cb.label, Vector3.new(18, 2.8, 0.15),
            Vector3.new(cx, floorY + 14.2, sz * 86 - sz * 0.1),
            sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
            Color3.fromRGB(55, 64, 76), Color3.fromRGB(255, 255, 255))
    end

    ------------------------------------------------------------------
    -- 4. โซนซ้าย (Grid A-D, X = -134..-82): สนามเซปักตะกร้อ 2 สนาม (เหนือ-ใต้ ตามแปลนชั้น 12)
    ------------------------------------------------------------------
    local takrawFolder = Instance.new("Model")
    takrawFolder.Name = "SepakTakrawCourts_2_West"
    takrawFolder.Parent = floor12

    local surfaceThick = 0.01
    local surfaceY = floorY + 0.005
    local lineThick = 0.02
    local lineY = floorY + 0.01

    -- แผ่นกรอบรวมสนามตะกร้อฝั่งซ้าย
    PartBuilder.makePart(takrawFolder, "TakrawOuterApron", Vector3.new(52, surfaceThick, 144),
        CFrame.new(-108, surfaceY, 0), Color3.fromRGB(58, 118, 86), Enum.Material.SmoothPlastic, { CanCollide = false })

    local takrawCourts = {
        { idx = 1, cz = -36, title = "สนามเซปักตะกร้อ 1\nSEPAK TAKRAW COURT 1" },
        { idx = 2, cz =  36, title = "สนามเซปักตะกร้อ 2\nSEPAK TAKRAW COURT 2" },
    }

    for _, tc in ipairs(takrawCourts) do
        local cm = Instance.new("Model")
        cm.Name = "SepakTakrawCourt_" .. tc.idx
        cm.Parent = takrawFolder

        local cx, cz = -108, tc.cz
        local cw, cl = 28, 56 -- สัดส่วน 6.1m x 13.4m

        PartBuilder.makePart(cm, "CourtPlayMat", Vector3.new(cw, surfaceThick + 0.002, cl),
            CFrame.new(cx, surfaceY + 0.001, cz), Color3.fromRGB(210, 118, 58), Enum.Material.SmoothPlastic, { CanCollide = false })

        -- เส้นขอบสนาม + เส้นแบ่งแดนกลาง
        PartBuilder.makePart(cm, "Line_North", Vector3.new(cw, lineThick, 0.35),
            CFrame.new(cx, lineY, cz - cl / 2), lineWhite, Enum.Material.Neon, { CanCollide = false })
        PartBuilder.makePart(cm, "Line_South", Vector3.new(cw, lineThick, 0.35),
            CFrame.new(cx, lineY, cz + cl / 2), lineWhite, Enum.Material.Neon, { CanCollide = false })
        PartBuilder.makePart(cm, "Line_West", Vector3.new(0.35, lineThick, cl),
            CFrame.new(cx - cw / 2, lineY, cz), lineWhite, Enum.Material.Neon, { CanCollide = false })
        PartBuilder.makePart(cm, "Line_East", Vector3.new(0.35, lineThick, cl),
            CFrame.new(cx + cw / 2, lineY, cz), lineWhite, Enum.Material.Neon, { CanCollide = false })
        PartBuilder.makePart(cm, "CenterLine", Vector3.new(cw, lineThick, 0.35),
            CFrame.new(cx, lineY, cz), lineWhite, Enum.Material.Neon, { CanCollide = false })

        -- วงกลมเสิร์ฟตะกร้อทั้ง 2 แดน
        for _, sz in ipairs({ -1, 1 }) do
            PartBuilder.makePart(cm, "ServiceCircle_" .. sz, Vector3.new(0.02, 5.2, 5.2),
                CFrame.new(cx, lineY, cz + sz * 12) * CFrame.Angles(0, 0, math.rad(90)),
                lineWhite, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, CanCollide = false })
            PartBuilder.makePart(cm, "ServiceCircleInner_" .. sz, Vector3.new(0.022, 4.6, 4.6),
                CFrame.new(cx, lineY + 0.002, cz + sz * 12) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(210, 118, 58), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, CanCollide = false })
        end

        -- เสาและตาข่ายเซปักตะกร้อ (สูง 5.1 studs)
        local postH = 5.2
        for _, sx in ipairs({ -1, 1 }) do
            PartBuilder.makePart(cm, "TakrawPost_" .. sx, Vector3.new(0.35, postH, 0.35),
                CFrame.new(cx + sx * (cw / 2 + 1.0), floorY + postH / 2, cz), Color3.fromRGB(45, 50, 58), Enum.Material.Metal)
        end
        PartBuilder.makePart(cm, "TakrawNet", Vector3.new(cw + 1.6, 2.4, 0.1),
            CFrame.new(cx, floorY + 3.8, cz), Color3.fromRGB(35, 35, 40), Enum.Material.Fabric, { Transparency = 0.35 })
        PartBuilder.makePart(cm, "TakrawNetTopTape", Vector3.new(cw + 1.8, 0.22, 0.14),
            CFrame.new(cx, floorY + 5.05, cz), Color3.fromRGB(215, 45, 45), Enum.Material.SmoothPlastic)
    end

    ------------------------------------------------------------------
    -- 5. โซนกลาง (Grid D-G, X = -62..+14): สนามเทนนิสในร่มมาตรฐาน + เก้าอี้กรรมการตามแปลน
    ------------------------------------------------------------------
    local tennisModel = Instance.new("Model")
    tennisModel.Name = "IndoorTennisCourt_Center"
    tennisModel.Parent = floor12

    local tcx, tcz = -24, 0
    local tennisDoublesW = 50
    local tennisSinglesW = 37
    local tennisL = 112
    local serviceDist = 29

    PartBuilder.makePart(tennisModel, "TennisOuterApron", Vector3.new(72, surfaceThick, 144),
        CFrame.new(tcx, surfaceY, tcz), Color3.fromRGB(52, 112, 82), Enum.Material.SmoothPlastic, { CanCollide = false })
    PartBuilder.makePart(tennisModel, "TennisInnerCourt", Vector3.new(tennisDoublesW, surfaceThick + 0.002, tennisL),
        CFrame.new(tcx, surfaceY + 0.001, tcz), Color3.fromRGB(42, 98, 165), Enum.Material.SmoothPlastic, { CanCollide = false })

    -- เส้นหลัง (Baselines), เส้นข้างคู่ (Doubles Sidelines), เส้นข้างเดี่ยว (Singles Sidelines)
    for _, sz in ipairs({ -1, 1 }) do
        PartBuilder.makePart(tennisModel, "Baseline_" .. sz, Vector3.new(tennisDoublesW, lineThick, 0.45),
            CFrame.new(tcx, lineY, tcz + sz * (tennisL / 2)), lineWhite, Enum.Material.Neon, { CanCollide = false })
        PartBuilder.makePart(tennisModel, "ServiceLine_" .. sz, Vector3.new(tennisSinglesW, lineThick, 0.38),
            CFrame.new(tcx, lineY, tcz + sz * serviceDist), lineWhite, Enum.Material.Neon, { CanCollide = false })
    end
    for _, sx in ipairs({ -1, 1 }) do
        PartBuilder.makePart(tennisModel, "DoublesSideline_" .. sx, Vector3.new(0.42, lineThick, tennisL),
            CFrame.new(tcx + sx * (tennisDoublesW / 2), lineY, tcz), lineWhite, Enum.Material.Neon, { CanCollide = false })
        PartBuilder.makePart(tennisModel, "SinglesSideline_" .. sx, Vector3.new(0.38, lineThick, tennisL),
            CFrame.new(tcx + sx * (tennisSinglesW / 2), lineY, tcz), lineWhite, Enum.Material.Neon, { CanCollide = false })
    end
    PartBuilder.makePart(tennisModel, "CenterServiceLine", Vector3.new(0.38, lineThick, serviceDist * 2),
        CFrame.new(tcx, lineY, tcz), lineWhite, Enum.Material.Neon, { CanCollide = false })

    -- เสาและตาข่ายเทนนิส + เก้าอี้กรรมการสูงตรงกลางขวาตามแปลน (Umpire Chair)
    for _, sx in ipairs({ -1, 1 }) do
        PartBuilder.makePart(tennisModel, "TennisPost_" .. sx, Vector3.new(0.5, 3.8, 0.5),
            CFrame.new(tcx + sx * (tennisDoublesW / 2 + 2.0), floorY + 1.9, tcz), Color3.fromRGB(35, 65, 50), Enum.Material.Metal)
    end
    PartBuilder.makePart(tennisModel, "TennisNet", Vector3.new(tennisDoublesW + 3.6, 3.1, 0.12),
        CFrame.new(tcx, floorY + 1.75, tcz), Color3.fromRGB(28, 32, 36), Enum.Material.Fabric, { Transparency = 0.3 })
    PartBuilder.makePart(tennisModel, "TennisNetTopBand", Vector3.new(tennisDoublesW + 3.8, 0.25, 0.16),
        CFrame.new(tcx, floorY + 3.4, tcz), lineWhite, Enum.Material.SmoothPlastic)

    -- เก้าอี้กรรมการเทนนิส (Umpire Stand ตรงตำแหน่งสี่เหลี่ยมข้างตาข่ายในแปลน)
    local umpX = tcx + tennisDoublesW / 2 + 4.8
    PartBuilder.makePart(tennisModel, "UmpirePlatform", Vector3.new(3.2, 5.5, 3.2),
        CFrame.new(umpX, floorY + 2.75, tcz), Color3.fromRGB(58, 65, 75), Enum.Material.Metal)
    PartBuilder.makePart(tennisModel, "UmpireSeat", Vector3.new(2.2, 2.2, 2.2),
        CFrame.new(umpX, floorY + 6.4, tcz), Color3.fromRGB(128, 28, 38), Enum.Material.SmoothPlastic)

    ------------------------------------------------------------------
    -- 6. โซนขวา (Grid G-J, X = +30..+134): สนามฟุตซอล/แฮนด์บอล ชั้น 12 ตามแปลนจริง
    ------------------------------------------------------------------
    local futsal12 = Instance.new("Model")
    futsal12.Name = "FutsalHandballCourt_East_F12"
    futsal12.Parent = floor12

    local fcx, fcz = 82, 0
    local fcW, fcL = 88, 136

    PartBuilder.makePart(futsal12, "Futsal12Apron", Vector3.new(100, surfaceThick, 144),
        CFrame.new(fcx, surfaceY, fcz), Color3.fromRGB(185, 82, 48), Enum.Material.SmoothPlastic, { CanCollide = false })
    PartBuilder.makePart(futsal12, "Futsal12Pitch", Vector3.new(fcW, surfaceThick + 0.002, fcL),
        CFrame.new(fcx, surfaceY + 0.001, fcz), Color3.fromRGB(35, 118, 175), Enum.Material.SmoothPlastic, { CanCollide = false })

    -- เส้นขอบสนาม + เส้นกลางสนาม + วงกลมกลางสนาม
    PartBuilder.makePart(futsal12, "Touchline_W", Vector3.new(0.45, lineThick, fcL),
        CFrame.new(fcx - fcW / 2, lineY, fcz), lineWhite, Enum.Material.Neon, { CanCollide = false })
    PartBuilder.makePart(futsal12, "Touchline_E", Vector3.new(0.45, lineThick, fcL),
        CFrame.new(fcx + fcW / 2, lineY, fcz), lineWhite, Enum.Material.Neon, { CanCollide = false })
    PartBuilder.makePart(futsal12, "GoalLine_N", Vector3.new(fcW, lineThick, 0.45),
        CFrame.new(fcx, lineY, -fcL / 2), lineWhite, Enum.Material.Neon, { CanCollide = false })
    PartBuilder.makePart(futsal12, "GoalLine_S", Vector3.new(fcW, lineThick, 0.45),
        CFrame.new(fcx, lineY,  fcL / 2), lineWhite, Enum.Material.Neon, { CanCollide = false })
    PartBuilder.makePart(futsal12, "HalfwayLine", Vector3.new(fcW, lineThick, 0.45),
        CFrame.new(fcx, lineY, 0), lineWhite, Enum.Material.Neon, { CanCollide = false })

    PartBuilder.makePart(futsal12, "CenterCircleOuter", Vector3.new(0.02, 24, 24),
        CFrame.new(fcx, lineY, 0) * CFrame.Angles(0, 0, math.rad(90)),
        lineWhite, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, CanCollide = false })
    PartBuilder.makePart(futsal12, "CenterCircleInner", Vector3.new(0.022, 23.0, 23.0),
        CFrame.new(fcx, lineY + 0.002, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(35, 118, 175), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, CanCollide = false })

    -- กรอบเขตโทษ 2 ชั้น + ครึ่งวงกลมหน้าเขตโทษ + โกลฟุตซอลทั้งฝั่งเหนือและใต้ตามแปลนชั้น 12
    for _, sz in ipairs({ -1, 1 }) do
        local gz = sz * (fcL / 2)
        -- ครึ่งวงกลมหน้าเขตโทษ (วางก่อนเพื่อให้กรอบเขตโทษทับด้านใน)
        PartBuilder.makePart(futsal12, "PenaltyArcOuter_" .. sz, Vector3.new(0.018, 22, 22),
            CFrame.new(fcx, lineY, gz - sz * 20) * CFrame.Angles(0, 0, math.rad(90)),
            lineWhite, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, CanCollide = false })
        PartBuilder.makePart(futsal12, "PenaltyArcInner_" .. sz, Vector3.new(0.02, 21.0, 21.0),
            CFrame.new(fcx, lineY + 0.001, gz - sz * 20) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(35, 118, 175), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, CanCollide = false })

        -- กรอบเขตโทษใหญ่ (กว้าง 46, ลึก 20) และกรอบประตูเล็ก (กว้าง 24, ลึก 8)
        PartBuilder.makePart(futsal12, "PenaltyBox_Front_" .. sz, Vector3.new(46, lineThick + 0.004, 0.42),
            CFrame.new(fcx, lineY + 0.003, gz - sz * 20), lineWhite, Enum.Material.Neon, { CanCollide = false })
        PartBuilder.makePart(futsal12, "PenaltyBox_L_" .. sz, Vector3.new(0.42, lineThick + 0.004, 20),
            CFrame.new(fcx - 23, lineY + 0.003, gz - sz * 10), lineWhite, Enum.Material.Neon, { CanCollide = false })
        PartBuilder.makePart(futsal12, "PenaltyBox_R_" .. sz, Vector3.new(0.42, lineThick + 0.004, 20),
            CFrame.new(fcx + 23, lineY + 0.003, gz - sz * 10), lineWhite, Enum.Material.Neon, { CanCollide = false })

        PartBuilder.makePart(futsal12, "GoalBox_Front_" .. sz, Vector3.new(24, lineThick + 0.004, 0.38),
            CFrame.new(fcx, lineY + 0.003, gz - sz * 8), lineYellow, Enum.Material.Neon, { CanCollide = false })
        PartBuilder.makePart(futsal12, "GoalBox_L_" .. sz, Vector3.new(0.38, lineThick + 0.004, 8),
            CFrame.new(fcx - 12, lineY + 0.003, gz - sz * 4), lineYellow, Enum.Material.Neon, { CanCollide = false })
        PartBuilder.makePart(futsal12, "GoalBox_R_" .. sz, Vector3.new(0.38, lineThick + 0.004, 8),
            CFrame.new(fcx + 12, lineY + 0.003, gz - sz * 4), lineYellow, Enum.Material.Neon, { CanCollide = false })

        -- ประตูฟุตซอล/แฮนด์บอล (Goal)
        local goalW, goalH, goalD = 15, 7.8, 5.0
        PartBuilder.makePart(futsal12, "GoalPostL_" .. sz, Vector3.new(0.5, goalH, 0.5),
            CFrame.new(fcx - goalW / 2, floorY + goalH / 2, gz), Color3.fromRGB(220, 40, 40), Enum.Material.Metal)
        PartBuilder.makePart(futsal12, "GoalPostR_" .. sz, Vector3.new(0.5, goalH, 0.5),
            CFrame.new(fcx + goalW / 2, floorY + goalH / 2, gz), Color3.fromRGB(220, 40, 40), Enum.Material.Metal)
        PartBuilder.makePart(futsal12, "GoalCrossbar_" .. sz, Vector3.new(goalW + 0.5, 0.5, 0.5),
            CFrame.new(fcx, floorY + goalH, gz), lineWhite, Enum.Material.Metal)
        PartBuilder.makePart(futsal12, "GoalNetBack_" .. sz, Vector3.new(goalW, goalH, 0.15),
            CFrame.new(fcx, floorY + goalH / 2, gz + sz * goalD), lineWhite, Enum.Material.Fabric, { Transparency = 0.45 })
    end

    ------------------------------------------------------------------
    -- 7. ม้านั่งยาวข้างสนาม (เฉพาะด้านข้างตามแนวยาว Z ไม่มีด้านกว้างหัว-ท้ายสนาม)
    ------------------------------------------------------------------
    local benchesF12 = Instance.new("Folder")
    benchesF12.Name = "CourtPerimeterBenches_F12"
    benchesF12.Parent = floor12

    local function buildBenchF12(name, cx, cz, length, faceDir)
        local bM = Instance.new("Model")
        bM.Name = name
        bM.Parent = benchesF12
        PartBuilder.makePart(bM, "SeatPlank", Vector3.new(2.0, 0.26, length),
            CFrame.new(cx, floorY + 1.75, cz), Color3.fromRGB(220, 125, 50), Enum.Material.Wood)
        PartBuilder.makePart(bM, "Backrest", Vector3.new(0.28, 1.3, length),
            CFrame.new(cx - faceDir * 0.82, floorY + 2.6, cz), Color3.fromRGB(128, 28, 38), Enum.Material.SmoothPlastic)
        for _, lz in ipairs({ cz - length / 2 + 2, cz, cz + length / 2 - 2 }) do
            PartBuilder.makePart(bM, "Leg", Vector3.new(1.7, 1.65, 0.35),
                CFrame.new(cx, floorY + 0.825, lz), Color3.fromRGB(52, 58, 66), Enum.Material.Metal)
        end
    end

    for idx, bz in ipairs({ -45, 0, 45 }) do
        buildBenchF12("Bench_WestWall_" .. idx, -142, bz, 24,  1)
        buildBenchF12("Bench_EastWall_" .. idx,  142, bz, 24, -1)
        buildBenchF12("Bench_MidDivider_" .. idx, 22, bz, 22,  1)
    end

    ------------------------------------------------------------------
    -- 8. ผนังรอบนอกชั้น 12 + เสาโครงสร้าง + หลังคาใหญ่บนสุดของตึก (Y = 265.0) + โคมไฟสนามกีฬา
    ------------------------------------------------------------------
    local envelope12 = Instance.new("Model")
    envelope12.Name = "Floor12_EnvelopeAndMainRoof"
    envelope12.Parent = floor12

    PartBuilder.makeSign(envelope12, "Floor12CenterSign",
        "ชั้น 12 อาคาร 40 ปี มจพ. (สนามตะกร้อ / เทนนิส / ฟุตซอล — ขึ้นทางบันไดเท่านั้น)\nFLOOR 12 TOP INDOOR SPORTS ARENA (STAIRS ACCESS ONLY)",
        Vector3.new(34, 0.02, 6.5), Vector3.new(0, floorY + 0.01, -78), Enum.NormalId.Top,
        Color3.fromRGB(128, 28, 38), Color3.fromRGB(255, 255, 255))

    for _, px in ipairs({ -70, 22 }) do
        for _, pz in ipairs({ -60, -20, 20, 60 }) do
            PartBuilder.makePart(envelope12, "Column_" .. px .. "_" .. pz, Vector3.new(2.2, wallH, 2.2),
                CFrame.new(px, floorY + wallH / 2, pz), Color3.fromRGB(225, 222, 215), Enum.Material.Concrete)
            PartBuilder.makePart(envelope12, "ColumnPad_" .. px .. "_" .. pz, Vector3.new(2.4, 5.0, 2.4),
                CFrame.new(px, floorY + 2.5, pz), Color3.fromRGB(225, 110, 40), Enum.Material.SmoothPlastic)
        end
    end

    for _, sx in ipairs({ -1, 1 }) do
        local xWall = sx * (body.halfX - wallThick / 2)
        PartBuilder.makePart(envelope12, "SideWall_Lower_" .. sx, Vector3.new(wallThick, 14.0, 172),
            CFrame.new(xWall, floorY + 7.0, 0), wallColor, wallMaterial)
        PartBuilder.makePart(envelope12, "SideWall_UpperBeam_" .. sx, Vector3.new(wallThick, 4.0, 172),
            CFrame.new(xWall, floorY + wallH - 2.0, 0), wallColor, wallMaterial)
        PartBuilder.makePart(envelope12, "SideGlassLouver_" .. sx, Vector3.new(0.4, 4.0, 172),
            CFrame.new(xWall, floorY + 16.0, 0), Color3.fromRGB(175, 215, 235), Enum.Material.Glass, { Transparency = 0.5 })
    end

    -- หลังคาใหญ่ปิดบนสุดของอาคารที่ชั้น 12 + โครงถักเหล็กหลังคาโรงยิม + โคมไฟติดโครงหลังคา
    PartBuilder.makePart(envelope12, "MainRoofSlab_F12", Vector3.new(body.halfX * 2, 2.5, body.halfZ * 2),
        CFrame.new(0, floorY + wallH + 1.25, 0), Color3.fromRGB(235, 235, 240), Enum.Material.Concrete)

    local lights = Instance.new("Folder")
    lights.Name = "Lights_Floor12"
    lights.Parent = floor12

    for z = -60, 60, 40 do
        PartBuilder.makePart(envelope12, "RoofSteelTruss_" .. z, Vector3.new(body.halfX * 2 - 4, 2.0, 1.6),
            CFrame.new(0, floorY + wallH - 1.0, z), Color3.fromRGB(70, 78, 88), Enum.Material.Metal)
        for _, lx in ipairs({ -108, -24, 82 }) do
            PartBuilder.addPointLight(lights, "ArenaLight_F12_" .. lx .. "_" .. z,
                Vector3.new(lx, floorY + wallH - 2.2, z), Color3.fromRGB(255, 252, 245), 60, 1.4)
        end
    end

    print("🏆 [Floor 12 Built] สร้างชั้น 12 (ชั้นบนสุด ขึ้นทางบันไดเท่านั้น: ตะกร้อ 2 สนาม + เทนนิส + ฟุตซอล + WC.1/WC.2) สำเร็จ!")
end

return Floor12_TopSportsArena
