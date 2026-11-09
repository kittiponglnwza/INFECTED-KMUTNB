--[[
    Floor7_VolleyballBadminton.lua
    โครงสร้างและรายละเอียดชั้น 7 (Floor 7): สนามวอลเลย์บอล (ฝั่งซ้าย) & สนามแบดมินตัน 4 คอร์ท (ฝั่งขวา)
    สร้างตามแปลนจริง อาคาร 40 ปี มจพ. (media_1794262149025_34d9f694.jpg)
    พร้อมปรับแนวผนังและพื้นทุกจุดให้สมดุล เรียบเป็นพื้นและระนาบเดียวกัน (ไม่มีเหลี่ยมยื่นเกินออกมา):
      1. กรอบตัวอาคาร 300 x 240 studs (X = -150..+150, Z = -120..+120) ตรงกับชั้น 1-6
      2. แถบบน (Z = -120..-86) และแถบล่าง (Z = +86..+120):
         - ห้องน้ำ 4 มุม (WC.1, WC.2, WC.3, WC.4) + ห้องปิด 4 ห้อง + ลิฟต์ & บันได เรียงหน้ากระดานตรงกันที่ Z = ±86 เป๊ะ
      3. ฝั่งซ้าย (X = -110..-38, Z = -72..+72):
         - สนามวอลเลย์บอลมาตรฐาน (Volleyball Court) พื้นเรียบเสมอโถง ตีเส้นครบ (เส้นข้าง, เส้นหลัง, เส้นแบ่งแดน, เส้นรุก 3 เมตร)
         - เสาและตาข่ายวอลเลย์บอลขึงกลางสนาม + เสาอากาศขาว-แดง + เก้าอี้กรรมการตัดสิน
      4. ฝั่งขวา (X = +38..+118, Z = -72..+72):
         - สนามแบดมินตัน 4 สนาม (2 แถว x 2 คอลัมน์ ตามแปลนจริง) พื้นเรียบเสมอโถง
         - ตีเส้นคอร์ทแบดมินตันครบทุกเส้น (เส้นคู่, เส้นเดี่ยว, เส้นเสิร์ฟสั้น, เส้นเสิร์ฟยาว, เส้นแบ่งครึ่งซ้าย-ขวา) + เสาและตาข่ายแบดมินตันครบทั้ง 4 สนาม
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local StairBuilder = require(script.Parent.Parent.utils.StairBuilder)
local ElevatorBuilder = require(script.Parent.Parent.utils.ElevatorBuilder)
local SlabBuilder = require(script.Parent.Parent.utils.SlabBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Floor7_VolleyballBadminton = {}

function Floor7_VolleyballBadminton.build(parent)
    local floor7 = Instance.new("Model")
    floor7.Name = "Floor_7_VolleyballBadminton"
    floor7.Parent = parent

    local floorNum = 7
    local floorY = Layout.floorY(floorNum) -- 133.0
    local wallH = Layout.FLOOR_HEIGHT      -- 22.0
    local wallThick = Layout.WALL_THICK    -- 2.0
    local wallColor = Color3.fromRGB(240, 237, 230)
    local wallMaterial = Enum.Material.Concrete
    local floorColor = Color3.fromRGB(216, 214, 208)
    local doorWood = Color3.fromRGB(132, 88, 54)
    local frameDark = Color3.fromRGB(48, 52, 58)
    local lineWhite = Color3.fromRGB(250, 250, 252)

    local core = Layout.CORE
    local body = Layout.BODY
    local frontStair = Layout.STAIRS.Front
    local rearStair = Layout.STAIRS.Rear
    local frontLift = Layout.LIFTS.Front
    local rearLift = Layout.LIFTS.Rear

    ------------------------------------------------------------------
    -- 1. พื้นชั้น 7 ผืนเดียวกันทั้งชั้น (300 x 240 studs) เจาะช่องรับบันไดจากชั้น 6
    ------------------------------------------------------------------
    SlabBuilder.build(
        floor7,
        "Floor7_Slab",
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
    -- 2. คอร์ลิฟต์และบันไดชั้น 7 (ชั้นบนสุด กั้นราวกันตกสแตนเลสรอบปากหลุมบันได)
    ------------------------------------------------------------------
    local function buildStairCoreF7(folder, def)
        local m = Instance.new("Model")
        m.Name = def.name .. "_F7"
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

    local northCore = Instance.new("Model")
    northCore.Name = "NorthCore_F7"
    northCore.Parent = floor7
    ElevatorBuilder.build(northCore, rearLift, floorNum, floorY, wallH, false)
    buildStairCoreF7(northCore, rearStair)
    PartBuilder.makePart(northCore, "NorthEndWall_Low", Vector3.new(core.centerWidth, 5.0, wallThick),
        CFrame.new(0, floorY + 2.5, -core.outerZ + wallThick / 2), wallColor, wallMaterial)
    PartBuilder.makePart(northCore, "NorthEndGlass", Vector3.new(core.centerWidth, wallH - 9, 0.4),
        CFrame.new(0, floorY + 5 + (wallH - 9) / 2, -core.outerZ + 1.0), Color3.fromRGB(165, 205, 220), Enum.Material.Glass, { Transparency = 0.55 })
    PartBuilder.makePart(northCore, "NorthEndHeader", Vector3.new(core.centerWidth, 4.0, wallThick),
        CFrame.new(0, floorY + wallH - 2.0, -core.outerZ + wallThick / 2), wallColor, wallMaterial)

    local southCore = Instance.new("Model")
    southCore.Name = "SouthCore_F7"
    southCore.Parent = floor7
    buildStairCoreF7(southCore, frontStair)
    ElevatorBuilder.build(southCore, frontLift, floorNum, floorY, wallH, false)
    PartBuilder.makePart(southCore, "SouthEndWall_Low", Vector3.new(core.centerWidth, 5.0, wallThick),
        CFrame.new(0, floorY + 2.5, core.outerZ - wallThick / 2), wallColor, wallMaterial)
    PartBuilder.makePart(southCore, "SouthEndGlass", Vector3.new(core.centerWidth, wallH - 9, 0.4),
        CFrame.new(0, floorY + 5 + (wallH - 9) / 2, core.outerZ - 1.0), Color3.fromRGB(165, 205, 220), Enum.Material.Glass, { Transparency = 0.55 })
    PartBuilder.makePart(southCore, "SouthEndHeader", Vector3.new(core.centerWidth, 4.0, wallThick),
        CFrame.new(0, floorY + wallH - 2.0, core.outerZ - wallThick / 2), wallColor, wallMaterial)

    ------------------------------------------------------------------
    -- 3. ห้องน้ำ 4 มุม (WC.1, WC.2, WC.3, WC.4 — X = ±116..±150, Z = ±86..±120)
    --    เรียบเสมอแนวเดียวกับห้องปิด ลิฟต์ และบันไดที่ Z = ±86 เป๊ะ!
    ------------------------------------------------------------------
    local restrooms = Instance.new("Model")
    restrooms.Name = "Restrooms_4Corners_F7"
    restrooms.Parent = floor7

    local rrW = 34
    local rrL = 34
    local cornerBlocks = {
        { name = "Restroom_WC2_TopLeft",  sx = -1, sz = -1 },
        { name = "Restroom_WC3_TopRight", sx =  1, sz = -1 },
        { name = "Restroom_WC1_BotLeft",  sx = -1, sz =  1 },
        { name = "Restroom_WC4_BotRight", sx =  1, sz =  1 },
    }

    for _, cb in ipairs(cornerBlocks) do
        local rModel = Instance.new("Model")
        rModel.Name = cb.name
        rModel.Parent = restrooms

        local sx, sz = cb.sx, cb.sz
        local cx = sx * (150 - rrW / 2) -- ±133
        local cz = sz * (120 - rrL / 2) -- ±103
        local innerX = sx * (150 - rrW) -- ±116
        local innerZ = sz * (120 - rrL) -- ±86
        local signFace = (sx < 0) and Enum.NormalId.Right or Enum.NormalId.Left

        PartBuilder.makePart(rModel, "Wall_Outer_X", Vector3.new(wallThick, wallH, rrL),
            CFrame.new(sx * (150 - wallThick / 2), floorY + wallH / 2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Outer_Z", Vector3.new(rrW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, sz * (120 - wallThick / 2)), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Inner_Z", Vector3.new(rrW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, innerZ + sz * (wallThick / 2)), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_CenterDivider_MF", Vector3.new(rrW, wallH, 1.2),
            CFrame.new(cx, floorY + wallH / 2, cz), wallColor, wallMaterial)

        local halves = {
            { sub = "Male",   midZ = sz * 111.5, label = "ห้องน้ำชาย\nMALE WC",   color = Color3.fromRGB(20, 90, 165) },
            { sub = "Female", midZ = sz *  94.5, label = "ห้องน้ำหญิง\nFEMALE WC", color = Color3.fromRGB(185, 45, 95) },
        }
        for _, h in ipairs(halves) do
            PartBuilder.makePart(rModel, "FrontWall_A_" .. h.sub, Vector3.new(wallThick, wallH, 5.0),
                CFrame.new(innerX + sx * (wallThick / 2), floorY + wallH / 2, h.midZ - 6.0), wallColor, wallMaterial)
            PartBuilder.makePart(rModel, "FrontWall_B_" .. h.sub, Vector3.new(wallThick, wallH, 5.0),
                CFrame.new(innerX + sx * (wallThick / 2), floorY + wallH / 2, h.midZ + 6.0), wallColor, wallMaterial)
            PartBuilder.makePart(rModel, "FrontHeader_" .. h.sub, Vector3.new(wallThick, 6.0, 7.0),
                CFrame.new(innerX + sx * (wallThick / 2), floorY + wallH - 3.0, h.midZ), wallColor, wallMaterial)

            PartBuilder.makeSign(rModel, "Sign_" .. h.sub, h.label, Vector3.new(0.15, 2.8, 12.0),
                Vector3.new(innerX - sx * 0.1, floorY + wallH - 3.2, h.midZ), signFace, h.color, Color3.fromRGB(255, 255, 255))

            PartBuilder.makePart(rModel, "Sink_" .. h.sub, Vector3.new(10, 3.2, 2.2),
                CFrame.new(cx - sx * 4, floorY + 1.6, h.midZ - sz * 5.2), Color3.fromRGB(215, 220, 225), Enum.Material.Marble)
            PartBuilder.makePart(rModel, "Mirror_" .. h.sub, Vector3.new(9, 4.2, 0.2),
                CFrame.new(cx - sx * 4, floorY + 5.8, h.midZ - sz * 6.2), Color3.fromRGB(190, 225, 245), Enum.Material.Glass, { Reflectance = 0.4 })
            for st = 1, 2 do
                local stX = (cx + sx * 2) + sx * ((st - 1) * 9)
                PartBuilder.makePart(rModel, "Cubicle_" .. h.sub .. "_" .. st, Vector3.new(0.4, 8.5, 5.5),
                    CFrame.new(stX - sx * 4.0, floorY + 4.25, h.midZ + sz * 3.8), Color3.fromRGB(200, 205, 210), Enum.Material.SmoothPlastic)
                PartBuilder.makePart(rModel, "Toilet_" .. h.sub .. "_" .. st, Vector3.new(2.0, 2.2, 2.0),
                    CFrame.new(stX, floorY + 1.1, h.midZ + sz * 5.0), Color3.fromRGB(250, 250, 252), Enum.Material.SmoothPlastic)
            end
        end
    end

    ------------------------------------------------------------------
    -- 4. ห้องปิด/ห้องเก็บอุปกรณ์กีฬา แถบบน & แถบล่าง 4 ห้อง (X = ±68..±98, Z = ±86..±120)
    --    เรียบเสมอระนาบเดียวกับลิฟต์และบันไดที่ Z = ±86 เป๊ะ!
    ------------------------------------------------------------------
    local sealedRoomsNS = Instance.new("Model")
    sealedRoomsNS.Name = "SealedRooms_NorthSouth_F7"
    sealedRoomsNS.Parent = floor7

    local nsConfigs = {
        { name = "Room_701_TopLeft",  cx = -83, sz = -1, code = "ห้องเก็บอุปกรณ์วอลเลย์บอล (ปิด)\nVOLLEYBALL STORAGE" },
        { name = "Room_702_TopRight", cx =  83, sz = -1, code = "ห้องเก็บอุปกรณ์แบดมินตัน (ปิด)\nBADMINTON STORAGE" },
        { name = "Room_703_BotLeft",  cx = -83, sz =  1, code = "ห้องพักนักกีฬา 703 (ปิด)\nATHLETE ROOM" },
        { name = "Room_704_BotRight", cx =  83, sz =  1, code = "ห้องกรรมการ 704 (ปิด)\nOFFICIALS ROOM" },
    }

    for _, cfg in ipairs(nsConfigs) do
        local rm = Instance.new("Model")
        rm.Name = cfg.name
        rm.Parent = sealedRoomsNS

        local cx, sz = cfg.cx, cfg.sz
        local sx = (cx > 0) and 1 or -1
        local roomW = 30
        local roomD = 34
        local cz = sz * 103
        local frontWallCenterZ = sz * (86 + wallThick / 2) -- ผิวหน้าอยู่ที่ Z = ±86 เป๊ะ
        local outerZ = sz * (120 - wallThick / 2)
        local outerSideX = cx + sx * (roomW / 2 - wallThick / 2) -- X = ±98
        local innerSideX = cx - sx * (roomW / 2 - wallThick / 2) -- X = ±68

        PartBuilder.makePart(rm, "Wall_OuterZ", Vector3.new(roomW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, outerZ), wallColor, wallMaterial)
        PartBuilder.makePart(rm, "Wall_OppositeRestroom", Vector3.new(wallThick, wallH, roomD),
            CFrame.new(outerSideX, floorY + wallH / 2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(rm, "Wall_CoreSide", Vector3.new(wallThick, wallH, roomD),
            CFrame.new(innerSideX, floorY + wallH / 2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(rm, "Wall_FrontSolid", Vector3.new(roomW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, frontWallCenterZ), wallColor, wallMaterial)

        PartBuilder.makePart(rm, "CorridorEndWall_OuterZ", Vector3.new(18, wallH, wallThick),
            CFrame.new(sx * 107, floorY + wallH / 2, outerZ), wallColor, wallMaterial)

        local doorFaceZ = sz * 86 - sz * 0.05
        PartBuilder.makePart(rm, "ClosedDoor_Frame", Vector3.new(8.6, 11.2, 0.12),
            CFrame.new(cx, floorY + 5.6, doorFaceZ), frameDark, Enum.Material.Metal)
        PartBuilder.makePart(rm, "ClosedDoor_PanelL", Vector3.new(3.8, 10.6, 0.16),
            CFrame.new(cx - 2.0, floorY + 5.3, doorFaceZ), doorWood, Enum.Material.Wood)
        PartBuilder.makePart(rm, "ClosedDoor_PanelR", Vector3.new(3.8, 10.6, 0.16),
            CFrame.new(cx + 2.0, floorY + 5.3, doorFaceZ), doorWood, Enum.Material.Wood)

        PartBuilder.makeSign(rm, "ClosedRoomSign", cfg.code, Vector3.new(20, 2.8, 0.15),
            Vector3.new(cx, floorY + 14.0, sz * 86 - sz * 0.1),
            sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
            Color3.fromRGB(55, 65, 80), Color3.fromRGB(255, 255, 255))
    end

    ------------------------------------------------------------------
    -- Helper ตีเส้นสนามกีฬาฝังเรียบกับพื้น (ไม่นูนสะดุด)
    ------------------------------------------------------------------
    local courtY = floorY + 0.008
    local lineY = floorY + 0.02
    local function makeLine(parentModel, name, sx, sz, px, pz, col)
        PartBuilder.makePart(parentModel, name, Vector3.new(sx, 0.02, sz),
            CFrame.new(px, lineY, pz), col or lineWhite, Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
    end

    ------------------------------------------------------------------
    -- 5. ฝั่งซ้าย: สนามวอลเลย์บอลมาตรฐาน ("สนามวอลเลย์บอล" X = -110..-38, Z = -72..+72)
    --    ตรงตามแปลนจริง (แบ่ง 4 ช่องแดนด้วยเส้นกลางและเส้นรุก 3 เมตร + ตาข่ายวอลเลย์บอล)
    ------------------------------------------------------------------
    local volleyModel = Instance.new("Model")
    volleyModel.Name = "VolleyballCourt_West"
    volleyModel.Parent = floor7

    local vX = -74   -- กึ่งกลางสนามวอลเลย์บอล ((-110 + -38) / 2)
    local vW = 72    -- ความกว้างคอร์ทวอลเลย์บอล (X = -110..-38)
    local vL = 144   -- ความยาวคอร์ทวอลเลย์บอล (Z = -72..+72)
    local attackZ = 24 -- เส้นรุก 3 เมตร (Z = -24 และ Z = +24)

    -- พื้น Free Zone สีฟ้าคราม + พื้นคอร์ทวอลเลย์บอลสีส้มอิฐมาตรฐาน FIVB (ฝังเรียบเป็นพื้นเดียวกัน)
    PartBuilder.makePart(volleyModel, "VolleyFreeZoneSurface", Vector3.new(vW + 12, 0.01, vL + 12),
        CFrame.new(vX, floorY + 0.004, 0), Color3.fromRGB(38, 118, 165), Enum.Material.SmoothPlastic, { CanCollide = false })
    PartBuilder.makePart(volleyModel, "VolleyPlaySurface", Vector3.new(vW, 0.012, vL),
        CFrame.new(vX, courtY, 0), Color3.fromRGB(220, 115, 52), Enum.Material.SmoothPlastic, { CanCollide = false })

    -- ตีเส้นสนามวอลเลย์บอลครบตามแปลน (เส้นข้าง, เส้นหลัง, เส้นแบ่งแดนกลาง, เส้นรุก 2 ฝั่ง)
    makeLine(volleyModel, "Line_West",        0.8, vL, vX - vW / 2, 0)
    makeLine(volleyModel, "Line_East",        0.8, vL, vX + vW / 2, 0)
    makeLine(volleyModel, "Line_North",       vW, 0.8, vX, -vL / 2)
    makeLine(volleyModel, "Line_South",       vW, 0.8, vX,  vL / 2)
    makeLine(volleyModel, "Line_Center",      vW, 0.8, vX, 0)
    makeLine(volleyModel, "Line_AttackNorth", vW, 0.8, vX, -attackZ)
    makeLine(volleyModel, "Line_AttackSouth", vW, 0.8, vX,  attackZ)

    -- เสาขึงตาข่ายวอลเลย์บอล + นวมหุ้มเสา + ตาข่ายวอลเลย์บอล + เสาอากาศขาว-แดง + เก้าอี้กรรมการ
    local netPostW = vW + 5.0
    for _, sideX in ipairs({ -1, 1 }) do
        local px = vX + sideX * (netPostW / 2)
        PartBuilder.makeCylinder(volleyModel, "VolleyPost_" .. sideX, Vector3.new(10.8, 0.9, 0.9),
            CFrame.new(px, floorY + 5.4, 0) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(235, 195, 35), Enum.Material.Metal)
        PartBuilder.makeCylinder(volleyModel, "VolleyPostPad_" .. sideX, Vector3.new(6.5, 1.5, 1.5),
            CFrame.new(px, floorY + 3.25, 0) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(25, 85, 160), Enum.Material.SmoothPlastic)
        -- เสาอากาศวอลเลย์บอล (Antenna) ที่ขอบเส้นข้าง
        local antX = vX + sideX * (vW / 2)
        PartBuilder.makePart(volleyModel, "Antenna_" .. sideX, Vector3.new(0.18, 5.2, 0.18),
            CFrame.new(antX, floorY + 9.6, 0), Color3.fromRGB(235, 35, 35), Enum.Material.SmoothPlastic)
    end

    -- ผืนตาข่ายวอลเลย์บอล (Y = 7.0 .. 10.4) + แถบผ้าใบขาวด้านบน
    PartBuilder.makePart(volleyModel, "VolleyballNetMesh", Vector3.new(vW + 3.6, 3.2, 0.15),
        CFrame.new(vX, floorY + 8.6, 0), Color3.fromRGB(35, 38, 44), Enum.Material.Fabric,
        { Transparency = 0.45, CanCollide = false, CanQuery = false })
    PartBuilder.makePart(volleyModel, "VolleyballNetTopBand", Vector3.new(vW + 4.0, 0.35, 0.22),
        CFrame.new(vX, floorY + 10.3, 0), lineWhite, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(volleyModel, "VolleyballNetBottomCord", Vector3.new(vW + 4.0, 0.18, 0.18),
        CFrame.new(vX, floorY + 7.0, 0), lineWhite, Enum.Material.SmoothPlastic)

    -- เก้าอี้กรรมการตัดสินวอลเลย์บอล (Referee Stand)
    local refX = vX - vW / 2 - 4.8
    PartBuilder.makePart(volleyModel, "RefereePlatform", Vector3.new(3.2, 5.2, 3.2),
        CFrame.new(refX, floorY + 2.6, 0), Color3.fromRGB(45, 95, 155), Enum.Material.Metal)
    PartBuilder.makePart(volleyModel, "RefereeSeat", Vector3.new(2.2, 0.4, 2.2),
        CFrame.new(refX, floorY + 5.4, 0), Color3.fromRGB(235, 115, 40), Enum.Material.SmoothPlastic)

    PartBuilder.makeSign(volleyModel, "VolleyFloorSign", "สนามวอลเลย์บอล\nVOLLEYBALL COURT",
        Vector3.new(24, 0.02, 5.5), Vector3.new(vX, lineY + 0.01, -36), Enum.NormalId.Top,
        Color3.fromRGB(25, 85, 145), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 6. ฝั่งขวา: สนามแบดมินตัน 4 สนาม (2x2 Grid ตามแปลนจริง — X = +38..+118, Z = -74..+74)
    ------------------------------------------------------------------
    local badmintonFolder = Instance.new("Model")
    badmintonFolder.Name = "BadmintonCourts_East_4Courts"
    badmintonFolder.Parent = floor7

    local bColsX = { 56, 100 }  -- 2 คอลัมน์ซ้าย-ขวาในฝั่งตะวันออก
    local bRowsZ = { -39, 39 }  -- 2 แถวบน-ล่าง
    local bW = 34               -- ความกว้างคอร์ทคู่ (Doubles Width)
    local bSinglesW = 28        -- ความกว้างคอร์ทเดี่ยว (Singles Width)
    local bL = 68               -- ความยาวคอร์ทแบดมินตัน (Length)
    local bShortService = 11    -- ระยะเส้นเสิร์ฟสั้นจากตาข่าย
    local bLongServiceDbl = 29.5 -- ระยะเส้นเสิร์ฟยาวประเภทคู่
    local matGreen = Color3.fromRGB(32, 134, 84)
    local matBorder = Color3.fromRGB(24, 98, 62)

    local courtIdx = 0
    for rIdx, cZ in ipairs(bRowsZ) do
        for cIdx, cX in ipairs(bColsX) do
            courtIdx += 1
            local bM = Instance.new("Model")
            bM.Name = "BadmintonCourt_" .. courtIdx
            bM.Parent = badmintonFolder

            -- พื้นยางสังเคราะห์สนามแบดมินตันสีเขียวมาตรฐาน BWF (เรียบเสมอเป็นพื้นเดียวกัน)
            PartBuilder.makePart(bM, "MatBorder", Vector3.new(bW + 4, 0.01, bL + 4),
                CFrame.new(cX, floorY + 0.004, cZ), matBorder, Enum.Material.SmoothPlastic, { CanCollide = false })
            PartBuilder.makePart(bM, "MatSurface", Vector3.new(bW, 0.012, bL),
                CFrame.new(cX, courtY, cZ), matGreen, Enum.Material.SmoothPlastic, { CanCollide = false })

            -- เส้นขอบนอกประเภทคู่ (Doubles Sidelines) & เส้นขอบในประเภทเดี่ยว (Singles Sidelines)
            makeLine(bM, "DoublesSide_L", 0.45, bL, cX - bW / 2, cZ)
            makeLine(bM, "DoublesSide_R", 0.45, bL, cX + bW / 2, cZ)
            makeLine(bM, "SinglesSide_L", 0.45, bL, cX - bSinglesW / 2, cZ)
            makeLine(bM, "SinglesSide_R", 0.45, bL, cX + bSinglesW / 2, cZ)

            -- เส้นหลังสุด (Back Boundary) & เส้นเสิร์ฟยาวประเภทคู่ (Long Service Line for Doubles) & เส้นเสิร์ฟสั้น (Short Service Line)
            for _, sz in ipairs({ -1, 1 }) do
                makeLine(bM, "BackLine_" .. sz,        bW, 0.45, cX, cZ + sz * (bL / 2))
                makeLine(bM, "LongServiceDbl_" .. sz,  bW, 0.45, cX, cZ + sz * bLongServiceDbl)
                makeLine(bM, "ShortService_" .. sz,    bW, 0.45, cX, cZ + sz * bShortService)

                -- เส้นแบ่งครึ่งคอร์ทซ้าย/ขวา (Center Line จากเส้นเสิร์ฟสั้นไปถึงเส้นหลังสุด)
                local centerLineLen = (bL / 2) - bShortService
                local centerLineMidZ = cZ + sz * (bShortService + centerLineLen / 2)
                makeLine(bM, "CenterLine_" .. sz, 0.45, centerLineLen, cX, centerLineMidZ)
            end

            -- เส้นกึ่งกลางใต้ตาข่าย
            makeLine(bM, "NetCenterLine", bW, 0.35, cX, cZ)

            -- เสาและตาข่ายแบดมินตันขึงกลางคอร์ท
            for _, sx in ipairs({ -1, 1 }) do
                PartBuilder.makeCylinder(bM, "BadmintonPost_" .. sx, Vector3.new(5.2, 0.45, 0.45),
                    CFrame.new(cX + sx * (bW / 2 + 0.4), floorY + 2.6, cZ) * CFrame.Angles(0, 0, math.rad(90)),
                    Color3.fromRGB(42, 48, 56), Enum.Material.Metal)
            end
            PartBuilder.makePart(bM, "BadmintonNetMesh", Vector3.new(bW + 0.4, 2.4, 0.12),
                CFrame.new(cX, floorY + 3.8, cZ), Color3.fromRGB(95, 32, 38), Enum.Material.Fabric,
                { Transparency = 0.42, CanCollide = false, CanQuery = false })
            PartBuilder.makePart(bM, "BadmintonNetTopTape", Vector3.new(bW + 0.6, 0.22, 0.16),
                CFrame.new(cX, floorY + 5.05, cZ), lineWhite, Enum.Material.SmoothPlastic)

            PartBuilder.makeSign(bM, "CourtSign_" .. courtIdx,
                string.format("สนามแบดมินตัน %d\nBADMINTON %d", courtIdx, courtIdx),
                Vector3.new(14, 0.02, 3.2), Vector3.new(cX, lineY + 0.01, cZ), Enum.NormalId.Top,
                Color3.fromRGB(20, 82, 50), Color3.fromRGB(255, 255, 255))
        end
    end

    ------------------------------------------------------------------
    -- 7. โถงทางเดินกลางชั้น 7 + เสาโครงสร้างเรียบตรงแนว X = ±30 + ผนังรอบนอกและหลังคาใหญ่บนสุด
    ------------------------------------------------------------------
    local concourse = Instance.new("Model")
    concourse.Name = "CentralConcourse_F7"
    concourse.Parent = floor7

    PartBuilder.makeSign(concourse, "Floor7CenterSign",
        "ชั้น 7 อาคาร 40 ปี มจพ. (วอลเลย์บอล & แบดมินตัน)\nFLOOR 7 VOLLEYBALL & BADMINTON ARENA",
        Vector3.new(30, 0.02, 6.5), Vector3.new(0, floorY + 0.01, 0), Enum.NormalId.Top,
        Color3.fromRGB(128, 28, 38), Color3.fromRGB(255, 255, 255))

    for _, px in ipairs({ -30, 30 }) do
        for _, pz in ipairs({ -60, -20, 20, 60 }) do
            PartBuilder.makePart(concourse, "Column_" .. px .. "_" .. pz, Vector3.new(2.4, wallH, 2.4),
                CFrame.new(px, floorY + wallH / 2, pz), Color3.fromRGB(225, 222, 215), Enum.Material.Concrete)
            PartBuilder.makePart(concourse, "ColumnPad_" .. px .. "_" .. pz, Vector3.new(2.6, 5.0, 2.6),
                CFrame.new(px, floorY + 2.5, pz), Color3.fromRGB(225, 110, 40), Enum.Material.SmoothPlastic)
        end
    end

    -- ผนังรอบนอกฝั่งซ้ายสุด (-150) และขวาสุด (+150) ช่วง Z = -86..+86 เรียบเสมอขอบตึกเป๊ะ
    local envelope = Instance.new("Model")
    envelope.Name = "Floor7_EnvelopeAndRoof"
    envelope.Parent = floor7

    for _, sx in ipairs({ -1, 1 }) do
        local xWall = sx * (body.halfX - wallThick / 2)
        PartBuilder.makePart(envelope, "SideWall_Lower_" .. sx, Vector3.new(wallThick, 14.0, 172),
            CFrame.new(xWall, floorY + 7.0, 0), wallColor, wallMaterial)
        PartBuilder.makePart(envelope, "SideWall_UpperBeam_" .. sx, Vector3.new(wallThick, 4.0, 172),
            CFrame.new(xWall, floorY + wallH - 2.0, 0), wallColor, wallMaterial)
        PartBuilder.makePart(envelope, "SideGlassLouver_" .. sx, Vector3.new(0.4, 4.0, 172),
            CFrame.new(xWall, floorY + 16.0, 0), Color3.fromRGB(175, 215, 235), Enum.Material.Glass, { Transparency = 0.5 })
        for z = -60, 60, 40 do
            PartBuilder.makePart(envelope, "SidePillar_" .. sx .. "_" .. z, Vector3.new(wallThick, wallH, 3.2),
                CFrame.new(xWall, floorY + wallH / 2, z), Color3.fromRGB(215, 212, 205), Enum.Material.Concrete)
        end
    end

    -- หลังคาใหญ่ปิดบนสุดของอาคารที่ชั้น 7 + โครงถักเหล็กหลังคาโรงยิม + ไฟสปอตไลท์
    PartBuilder.makePart(envelope, "MainRoofSlab", Vector3.new(body.halfX * 2, 2.5, body.halfZ * 2),
        CFrame.new(0, floorY + wallH + 1.25, 0), Color3.fromRGB(235, 235, 240), Enum.Material.Concrete)

    local lights = Instance.new("Folder")
    lights.Name = "Lights_Floor7"
    lights.Parent = floor7

    for z = -60, 60, 40 do
        PartBuilder.makePart(envelope, "RoofSteelTruss_" .. z, Vector3.new(body.halfX * 2 - 4, 2.0, 1.6),
            CFrame.new(0, floorY + wallH - 1.0, z), Color3.fromRGB(70, 78, 88), Enum.Material.Metal)
        for _, lx in ipairs({ -74, 0, 56, 100 }) do
            PartBuilder.addPointLight(lights, "GymLight_F7_" .. lx .. "_" .. z,
                Vector3.new(lx, floorY + wallH - 2.2, z), Color3.fromRGB(255, 252, 245), 60, 1.45)
        end
    end

    print("🏐🏸 [Floor 7 Built] สร้างชั้น 7 สนามวอลเลย์บอล (ซ้าย) + สนามแบดมินตัน 4 สนาม (ขวา) + ห้องน้ำ 4 มุม สำเร็จสมบูรณ์!")
end

return Floor7_VolleyballBadminton
