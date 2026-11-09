--[[
    Floors4To6_UpperAtrium.lua
    โครงสร้างและรายละเอียดชั้น 4, ชั้น 5, และ ชั้น 6 อาคาร 40 ปี มจพ.
    สร้างตามผังที่สั่ง (media_1794260842319_70285d23.png) เป๊ะทุกจุด:
      1. กรอบตัวอาคาร 300 x 240 studs (X = -150..+150, Z = -120..+120) ตรงกับชั้น 1-3
      2. เจาะช่องโถงสูง (Atrium Voids) 2 ฝั่ง มองทะลุลงไปเห็นสนามกีฬาชั้น 3 พร้อมราวกันตกรอบช่อง:
         - ฝั่งซ้าย: "รูเห็นสนามฟุตซอล" (X = -104..-34, Z = -68..+68)
         - ฝั่งขวา: "รูเห็นสนามบาส"   (X = +34..+104, Z = -68..+68)
      3. แถบบน (Z = -120..-86):
         - มุมซ้ายบน: ห้องน้ำ (ชาย/หญิง) | ห้อง ปิด | ลิฟต์ | โถงกลาง | บันได | ห้อง ปิด | มุมขวาบน: ห้องน้ำ (ชาย/หญิง)
      4. แถบล่าง (Z = +86..+120):
         - มุมซ้ายล่าง: ห้องน้ำ (ชาย/หญิง) | ห้อง ปิด | บันได | โถงกลาง | ลิฟต์ | ห้อง ปิด | มุมขวาล่าง: ห้องน้ำ (ชาย/หญิง)
      5. ปีกซ้ายสุด & ปีกขวาสุด (X = ±116..±150, Z = -76..+76 ชนห้องน้ำทั้ง 4 มุมสนิท):
         - "ห้อง ปิด" ยาวตลอดแนวปีกซ้ายและปีกขวา ปิดทึบพร้อมประตูห้องเรียนปิดตายและป้ายหน้าห้อง
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local StairBuilder = require(script.Parent.Parent.utils.StairBuilder)
local ElevatorBuilder = require(script.Parent.Parent.utils.ElevatorBuilder)
local SlabBuilder = require(script.Parent.Parent.utils.SlabBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Floors4To6_UpperAtrium = {}

-- ขนาดช่องโถงมองลงสนามฟุตซอล (ซ้าย) และสนามบาส (ขวา)
local FUTSAL_VOID = { minX = -104, maxX = -34, minZ = -68, maxZ = 68 }
local BASKET_VOID = { minX =   34, maxX = 104, minZ = -68, maxZ = 68 }

local function buildAtriumRailing(parent, name, rect, floorY, signTitle)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent

    local curbH = 2.0
    local railH = 3.8
    local thick = 0.9
    local curbColor = Color3.fromRGB(228, 224, 216)
    local topRailColor = Color3.fromRGB(185, 192, 200)
    local postColor = Color3.fromRGB(58, 64, 72)
    local glassColor = Color3.fromRGB(190, 225, 240)

    local w = rect.maxX - rect.minX -- 70
    local l = rect.maxZ - rect.minZ -- 136
    local midX = (rect.minX + rect.maxX) / 2
    local midZ = (rect.minZ + rect.maxZ) / 2

    -- ขอบปูนกันตก + กระจกนิรภัยใส + ราวสแตนเลสทั้ง 4 ด้านของช่องโถง (มองทะลุลงไปเห็นสนามชั้น 3 ชัดเจน)
    local sides = {
        { tag = "North", sizeX = w + thick * 2, sizeZ = thick, px = midX, pz = rect.minZ - thick / 2 },
        { tag = "South", sizeX = w + thick * 2, sizeZ = thick, px = midX, pz = rect.maxZ + thick / 2 },
        { tag = "West",  sizeX = thick, sizeZ = l,             px = rect.minX - thick / 2, pz = midZ },
        { tag = "East",  sizeX = thick, sizeZ = l,             px = rect.maxX + thick / 2, pz = midZ },
    }

    for _, s in ipairs(sides) do
        PartBuilder.makePart(m, "Curb_" .. s.tag, Vector3.new(s.sizeX, curbH, s.sizeZ),
            CFrame.new(s.px, floorY + curbH / 2, s.pz), curbColor, Enum.Material.Concrete)
        PartBuilder.makePart(m, "GlassGuard_" .. s.tag,
            Vector3.new(s.sizeX == thick and 0.25 or s.sizeX - 0.4, railH - curbH - 0.2, s.sizeZ == thick and 0.25 or s.sizeZ - 0.4),
            CFrame.new(s.px, floorY + curbH + (railH - curbH) / 2, s.pz), glassColor, Enum.Material.Glass, { Transparency = 0.55 })
        PartBuilder.makePart(m, "TopHandrail_" .. s.tag, Vector3.new(s.sizeX, 0.35, s.sizeZ),
            CFrame.new(s.px, floorY + railH, s.pz), topRailColor, Enum.Material.Metal)
    end

    -- เสาเหล็กยึดราวกันตกตามมุมและแนวขอบ
    for _, cx in ipairs({ rect.minX - thick / 2, rect.maxX + thick / 2 }) do
        for z = rect.minZ, rect.maxZ, 34 do
            PartBuilder.makePart(m, "Post_" .. cx .. "_" .. z, Vector3.new(0.5, railH + 0.2, 0.5),
                CFrame.new(cx, floorY + (railH + 0.2) / 2, z), postColor, Enum.Material.Metal)
        end
    end

    -- ป้ายบอกช่องมองลงสนามฟุตซอล / สนามบาส (ติดด้านโถงกลาง)
    local centerFacingX = (midX < 0) and (rect.maxX + thick + 0.1) or (rect.minX - thick - 0.1)
    local normalFace = (midX < 0) and Enum.NormalId.Right or Enum.NormalId.Left
    PartBuilder.makeSign(m, "AtriumViewSign", signTitle,
        Vector3.new(0.25, 1.8, 22),
        Vector3.new(centerFacingX, floorY + 1.1, 0),
        normalFace, Color3.fromRGB(32, 85, 145), Color3.fromRGB(255, 255, 255))
end

local function buildSingleUpperFloor(parent, floorNum, isTopFloor)
    local floorModel = Instance.new("Model")
    floorModel.Name = string.format("Floor_%d_Building40", floorNum)
    floorModel.Parent = parent

    local floorY = Layout.floorY(floorNum)
    local wallH = Layout.FLOOR_HEIGHT    -- 22.0
    local wallThick = Layout.WALL_THICK  -- 2.0
    local wallColor = Color3.fromRGB(240, 237, 230)
    local wallMaterial = Enum.Material.Concrete
    local floorColor = Color3.fromRGB(220, 216, 208)
    local doorWood = Color3.fromRGB(132, 88, 54)
    local frameDark = Color3.fromRGB(48, 52, 58)

    local core = Layout.CORE
    local body = Layout.BODY
    local frontStair = Layout.STAIRS.Front
    local rearStair = Layout.STAIRS.Rear
    local frontLift = Layout.LIFTS.Front
    local rearLift = Layout.LIFTS.Rear

    ------------------------------------------------------------------
    -- 1. พื้นชั้น 4-6 เจาะช่องบันได 2 จุด + เจาะรูเห็นสนามฟุตซอล (ซ้าย) และรูเห็นสนามบาส (ขวา)
    ------------------------------------------------------------------
    SlabBuilder.build(
        floorModel,
        string.format("Floor%d_Slab", floorNum),
        {
            { minX = -body.halfX, maxX = body.halfX, minZ = -body.halfZ, maxZ = body.halfZ },
        },
        {
            StairBuilder.slabHole(frontStair),
            StairBuilder.slabHole(rearStair),
            FUTSAL_VOID,
            BASKET_VOID,
        },
        floorY, 2.0, floorColor, Enum.Material.SmoothPlastic
    )

    -- สร้างราวกันตกรอบ "รูเห็นสนามฟุตซอล" และ "รูเห็นสนามบาส"
    buildAtriumRailing(floorModel, "FutsalAtriumOpening", FUTSAL_VOID, floorY,
        string.format("รูเห็นสนามฟุตซอล (ชั้น %d)\nFUTSAL COURT VIEW", floorNum))
    buildAtriumRailing(floorModel, "BasketballAtriumOpening", BASKET_VOID, floorY,
        string.format("รูเห็นสนามบาส (ชั้น %d)\nBASKETBALL COURT VIEW", floorNum))

    ------------------------------------------------------------------
    -- 2. คอร์ลิฟต์และบันได (เหนือ & ใต้ — ตรงแนวดิ่งกับชั้น 1-3)
    ------------------------------------------------------------------
    local function buildStairCore(folder, def)
        local m = Instance.new("Model")
        m.Name = string.format("%s_F%d", def.name, floorNum)
        m.Parent = folder

        StairBuilder.buildEnclosure(m, def, floorY, wallH, floorNum)
        if not isTopFloor then
            -- ชั้น 4 และ ชั้น 5 มีบันไดเดินขึ้นต่อไปชั้นถัดไป
            StairBuilder.buildUStair(m, def, floorY, wallH)
        else
            -- ชั้น 6 (ชั้นบนสุด) กั้นราวกันตกสแตนเลสรอบปากหลุมบันได
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
    end

    local northCore = Instance.new("Model")
    northCore.Name = "NorthCore_F" .. floorNum
    northCore.Parent = floorModel
    ElevatorBuilder.build(northCore, rearLift, floorNum, floorY, wallH, false)
    buildStairCore(northCore, rearStair)
    PartBuilder.makePart(northCore, "NorthEndWall_Low", Vector3.new(core.centerWidth, 5.0, wallThick),
        CFrame.new(0, floorY + 2.5, -core.outerZ + wallThick / 2), wallColor, wallMaterial)
    PartBuilder.makePart(northCore, "NorthEndGlass", Vector3.new(core.centerWidth - 4, wallH - 9, 0.4),
        CFrame.new(0, floorY + 5 + (wallH - 9) / 2, -core.outerZ + 1.0), Color3.fromRGB(165, 205, 220), Enum.Material.Glass, { Transparency = 0.55 })
    PartBuilder.makePart(northCore, "NorthEndHeader", Vector3.new(core.centerWidth, 4.0, wallThick),
        CFrame.new(0, floorY + wallH - 2.0, -core.outerZ + wallThick / 2), wallColor, wallMaterial)

    local southCore = Instance.new("Model")
    southCore.Name = "SouthCore_F" .. floorNum
    southCore.Parent = floorModel
    buildStairCore(southCore, frontStair)
    ElevatorBuilder.build(southCore, frontLift, floorNum, floorY, wallH, false)
    PartBuilder.makePart(southCore, "SouthEndWall_Low", Vector3.new(core.centerWidth, 5.0, wallThick),
        CFrame.new(0, floorY + 2.5, core.outerZ - wallThick / 2), wallColor, wallMaterial)
    PartBuilder.makePart(southCore, "SouthEndGlass", Vector3.new(core.centerWidth - 4, wallH - 9, 0.4),
        CFrame.new(0, floorY + 5 + (wallH - 9) / 2, core.outerZ - 1.0), Color3.fromRGB(165, 205, 220), Enum.Material.Glass, { Transparency = 0.55 })
    PartBuilder.makePart(southCore, "SouthEndHeader", Vector3.new(core.centerWidth, 4.0, wallThick),
        CFrame.new(0, floorY + wallH - 2.0, core.outerZ - wallThick / 2), wallColor, wallMaterial)

    ------------------------------------------------------------------
    -- 3. ห้องน้ำ 4 มุม (X = ±116..±150, Z = ±76..±120) — แยกชาย/หญิง หันหน้าเข้าหาลิฟต์และบันได
    ------------------------------------------------------------------
    local restrooms = Instance.new("Model")
    restrooms.Name = "Restrooms_4Corners_F" .. floorNum
    restrooms.Parent = floorModel

    local rrW = 34
    local rrL = 44
    local cornerBlocks = {
        { name = "Restroom_TopLeft",  sx = -1, sz = -1 },
        { name = "Restroom_TopRight", sx =  1, sz = -1 },
        { name = "Restroom_BotLeft",  sx = -1, sz =  1 },
        { name = "Restroom_BotRight", sx =  1, sz =  1 },
    }

    for _, cb in ipairs(cornerBlocks) do
        local rModel = Instance.new("Model")
        rModel.Name = cb.name
        rModel.Parent = restrooms

        local sx, sz = cb.sx, cb.sz
        local cx = sx * (150 - rrW / 2) -- ±133
        local cz = sz * (120 - rrL / 2) -- ±98
        local innerX = sx * (150 - rrW) -- ±116
        local innerZ = sz * (120 - rrL) -- ±76
        local signFace = (sx < 0) and Enum.NormalId.Right or Enum.NormalId.Left

        PartBuilder.makePart(rModel, "Wall_Outer_X", Vector3.new(wallThick, wallH, rrL),
            CFrame.new(sx * (150 - wallThick / 2), floorY + wallH / 2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Outer_Z", Vector3.new(rrW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, sz * (120 - wallThick / 2)), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Inner_Z", Vector3.new(rrW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, innerZ + sz * (wallThick / 2)), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_CenterDivider_MF", Vector3.new(rrW, wallH, 1.4),
            CFrame.new(cx, floorY + wallH / 2, cz), wallColor, wallMaterial)

        local halves = {
            { sub = "Male",   midZ = sz * 109, label = "ห้องน้ำชาย\nMALE WC",   color = Color3.fromRGB(20, 90, 165) },
            { sub = "Female", midZ = sz * 87,  label = "ห้องน้ำหญิง\nFEMALE WC", color = Color3.fromRGB(185, 45, 95) },
        }
        for _, h in ipairs(halves) do
            PartBuilder.makePart(rModel, "FrontWall_A_" .. h.sub, Vector3.new(wallThick, wallH, 7),
                CFrame.new(innerX + sx * (wallThick / 2), floorY + wallH / 2, h.midZ - 7.5), wallColor, wallMaterial)
            PartBuilder.makePart(rModel, "FrontWall_B_" .. h.sub, Vector3.new(wallThick, wallH, 7),
                CFrame.new(innerX + sx * (wallThick / 2), floorY + wallH / 2, h.midZ + 7.5), wallColor, wallMaterial)
            PartBuilder.makePart(rModel, "FrontHeader_" .. h.sub, Vector3.new(wallThick, 6.0, 8),
                CFrame.new(innerX + sx * (wallThick / 2), floorY + wallH - 3.0, h.midZ), wallColor, wallMaterial)

            PartBuilder.makeSign(rModel, "Sign_" .. h.sub, h.label, Vector3.new(0.4, 3.2, 14),
                Vector3.new(innerX - sx * 0.3, floorY + wallH - 3.2, h.midZ), signFace, h.color, Color3.fromRGB(255, 255, 255))

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
    -- 4. "ห้อง ปิด" แถบบน & แถบล่าง 4 ห้อง (X = ±68..±98, Z = ±86..±120)
    --    อยู่ระหว่างห้องน้ำกับลิฟต์/บันได ปิดทึบทั้งหมด (ไม่มีกระจกหน้าห้องน้ำ!)
    ------------------------------------------------------------------
    local sealedRoomsNS = Instance.new("Model")
    sealedRoomsNS.Name = "SealedRooms_NorthSouth_4Zones"
    sealedRoomsNS.Parent = floorModel

    local nsConfigs = {
        { name = "ClosedRoom_TopLeft",  cx = -83, sz = -1, code = string.format("ห้อง %d01 (ปิด)\nCLOSED ROOM", floorNum) },
        { name = "ClosedRoom_TopRight", cx =  83, sz = -1, code = string.format("ห้อง %d02 (ปิด)\nCLOSED ROOM", floorNum) },
        { name = "ClosedRoom_BotLeft",  cx = -83, sz =  1, code = string.format("ห้อง %d03 (ปิด)\nCLOSED ROOM", floorNum) },
        { name = "ClosedRoom_BotRight", cx =  83, sz =  1, code = string.format("ห้อง %d04 (ปิด)\nCLOSED ROOM", floorNum) },
    }

    for _, cfg in ipairs(nsConfigs) do
        local rm = Instance.new("Model")
        rm.Name = cfg.name
        rm.Parent = sealedRoomsNS

        local cx, sz = cfg.cx, cfg.sz
        local sx = (cx > 0) and 1 or -1
        local roomW = 30 -- X = ±68..±98
        local roomD = 34 -- Z = ±86..±120
        local cz = sz * 103
        local frontZ = sz * 86
        local outerZ = sz * (120 - wallThick / 2)
        local outerSideX = cx + sx * (roomW / 2 - wallThick / 2) -- X = ±98
        local innerSideX = cx - sx * (roomW / 2 - wallThick / 2) -- X = ±68

        -- ผนังทึบ 4 ด้าน (ห้องปิดตาย ไม่เอากระจก)
        PartBuilder.makePart(rm, "Wall_OuterZ", Vector3.new(roomW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, outerZ), wallColor, wallMaterial)
        PartBuilder.makePart(rm, "Wall_OppositeRestroom", Vector3.new(wallThick, wallH, roomD),
            CFrame.new(outerSideX, floorY + wallH / 2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(rm, "Wall_CoreSide", Vector3.new(wallThick, wallH, roomD),
            CFrame.new(innerSideX, floorY + wallH / 2, cz), wallColor, wallMaterial)
        PartBuilder.makePart(rm, "Wall_FrontSolid", Vector3.new(roomW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, frontZ), wallColor, wallMaterial)

        -- ปิดผนังขอบตึก (Z = ±120) ช่วงทางเดินหน้าห้องน้ำ (X = ±98..±116)
        PartBuilder.makePart(rm, "CorridorEndWall_OuterZ", Vector3.new(18, wallH, wallThick),
            CFrame.new(sx * 107, floorY + wallH / 2, outerZ), wallColor, wallMaterial)

        -- บานประตูไม้คู่ปิดตาย + วงกบหน้าห้อง (Z = ±86)
        local doorFaceZ = frontZ - sz * (wallThick / 2 + 0.15)
        PartBuilder.makePart(rm, "ClosedDoor_Frame", Vector3.new(8.8, 11.4, 0.4),
            CFrame.new(cx, floorY + 5.7, doorFaceZ), frameDark, Enum.Material.Metal)
        PartBuilder.makePart(rm, "ClosedDoor_PanelL", Vector3.new(3.9, 10.8, 0.5),
            CFrame.new(cx - 2.0, floorY + 5.4, doorFaceZ), doorWood, Enum.Material.Wood)
        PartBuilder.makePart(rm, "ClosedDoor_PanelR", Vector3.new(3.9, 10.8, 0.5),
            CFrame.new(cx + 2.0, floorY + 5.4, doorFaceZ), doorWood, Enum.Material.Wood)

        PartBuilder.makeSign(rm, "ClosedRoomSign", cfg.code, Vector3.new(16, 2.8, 0.35),
            Vector3.new(cx, floorY + 14.0, frontZ - sz * 1.2),
            sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
            Color3.fromRGB(65, 72, 82), Color3.fromRGB(255, 255, 255))
    end

    ------------------------------------------------------------------
    -- 5. "ห้อง ปิด" ปีกซ้ายสุด & ปีกขวาสุด (X = ±116..±150, Z = -76..+76)
    --    ชนห้องน้ำทั้ง 4 มุมสนิทไร้ช่องว่าง!
    ------------------------------------------------------------------
    local wingSealedFolder = Instance.new("Model")
    wingSealedFolder.Name = "SealedRooms_WestAndEastWings"
    wingSealedFolder.Parent = floorModel

    local wingDepth = 34 -- X = ±116..±150 (เสมอแนวห้องน้ำมุมเป๊ะ)
    local wingSpanZ = 152 -- Z = -76..+76 (ชนห้องน้ำบน-ล่างสนิท)

    for _, side in ipairs({ -1, 1 }) do
        local wModel = Instance.new("Model")
        wModel.Name = (side < 0) and "WestWing_ClosedRooms" or "EastWing_ClosedRooms"
        wModel.Parent = wingSealedFolder

        local outerWallX = side * (150 - wallThick / 2)
        local innerWallX = side * (150 - wingDepth + wallThick / 2) -- X = ±117 (ผิวหน้าอยู่ที่ ±116)
        local midX = side * (150 - wingDepth / 2)

        -- ผนังทึบขอบนอกตึก (X = ±150) และผนังทึบฝั่งทางเดิน (X = ±116) ชนห้องน้ำทั้ง 4 มุม
        PartBuilder.makePart(wModel, "OuterWall_X", Vector3.new(wallThick, wallH, wingSpanZ),
            CFrame.new(outerWallX, floorY + wallH / 2, 0), wallColor, wallMaterial)
        PartBuilder.makePart(wModel, "CorridorWall_X", Vector3.new(wallThick, wallH, wingSpanZ),
            CFrame.new(innerWallX, floorY + wallH / 2, 0), wallColor, wallMaterial)

        -- ผนังกั้นซอยด้านใน + ประตูบานคู่ปิดตายและป้าย "ห้องปิด" เรียง 3 ห้องย่อยต่อฝั่ง
        local doorFaceX = side * (150 - wingDepth) - side * 0.2
        local signFace = (side < 0) and Enum.NormalId.Right or Enum.NormalId.Left

        for idx, doorZ in ipairs({ -46, 0, 46 }) do
            local roomNum = (side < 0) and (floorNum * 100 + 10 + idx) or (floorNum * 100 + 20 + idx)
            PartBuilder.makePart(wModel, "ClosedDoorFrame_" .. idx, Vector3.new(0.4, 11.4, 8.8),
                CFrame.new(doorFaceX, floorY + 5.7, doorZ), frameDark, Enum.Material.Metal)
            PartBuilder.makePart(wModel, "ClosedDoorL_" .. idx, Vector3.new(0.5, 10.8, 3.9),
                CFrame.new(doorFaceX, floorY + 5.4, doorZ - 2.0), doorWood, Enum.Material.Wood)
            PartBuilder.makePart(wModel, "ClosedDoorR_" .. idx, Vector3.new(0.5, 10.8, 3.9),
                CFrame.new(doorFaceX, floorY + 5.4, doorZ + 2.0), doorWood, Enum.Material.Wood)

            PartBuilder.makeSign(wModel, "WingClosedSign_" .. idx,
                string.format("ห้องเรียน %d (ห้องปิด)\nCLOSED ROOM", roomNum),
                Vector3.new(0.35, 2.8, 18),
                Vector3.new(doorFaceX - side * 0.2, floorY + 14.0, doorZ),
                signFace, Color3.fromRGB(65, 72, 82), Color3.fromRGB(255, 255, 255))
        end

        for _, divZ in ipairs({ -23, 23 }) do
            PartBuilder.makePart(wModel, "InternalDivider_" .. divZ, Vector3.new(wingDepth, wallH, 1.2),
                CFrame.new(midX, floorY + wallH / 2, divZ), wallColor, wallMaterial)
        end
    end

    ------------------------------------------------------------------
    -- 6. โถงทางเดินกลาง + เสาโครงสร้างต่อเนื่องจากชั้น 3 + ไฟส่องสว่างประจำชั้น
    ------------------------------------------------------------------
    local concourse = Instance.new("Model")
    concourse.Name = "CentralConcourse_F" .. floorNum
    concourse.Parent = floorModel

    PartBuilder.makeSign(concourse, "FloorCenterSign",
        string.format("ชั้น %d อาคาร 40 ปี มจพ.\nFLOOR %d CONCOURSE", floorNum, floorNum),
        Vector3.new(26, 0.08, 6.0), Vector3.new(0, floorY + 0.12, 0), Enum.NormalId.Top,
        Color3.fromRGB(128, 28, 38), Color3.fromRGB(255, 255, 255))

    for _, px in ipairs({ -28, 28 }) do
        for _, pz in ipairs({ -60, -20, 20, 60 }) do
            PartBuilder.makePart(concourse, "Column_" .. px .. "_" .. pz, Vector3.new(3.2, wallH, 3.2),
                CFrame.new(px, floorY + wallH / 2, pz), Color3.fromRGB(225, 222, 215), Enum.Material.Concrete)
        end
    end

    local lights = Instance.new("Folder")
    lights.Name = "Lights_Floor" .. floorNum
    lights.Parent = floorModel
    for _, lz in ipairs({ -95, -45, 0, 45, 95 }) do
        PartBuilder.addPointLight(lights, "CenterLight_" .. lz,
            Vector3.new(0, floorY + wallH - 2.0, lz), Color3.fromRGB(255, 248, 238), 50, 1.0)
    end
    for _, sx in ipairs({ -109, 109 }) do
        for _, lz in ipairs({ -75, 0, 75 }) do
            PartBuilder.addPointLight(lights, "WalkwayLight_" .. sx .. "_" .. lz,
                Vector3.new(sx, floorY + wallH - 2.0, lz), Color3.fromRGB(255, 248, 238), 42, 0.9)
        end
    end

    ------------------------------------------------------------------
    -- 7. หลังคาใหญ่ปิดบนสุดของอาคารที่ชั้น 6 (Y = floorY + wallH = 133.0)
    ------------------------------------------------------------------
    if isTopFloor then
        local roofModel = Instance.new("Model")
        roofModel.Name = "Building40_TopRoof_F6"
        roofModel.Parent = floorModel

        PartBuilder.makePart(roofModel, "MainRoofSlab", Vector3.new(body.halfX * 2, 2.5, body.halfZ * 2),
            CFrame.new(0, floorY + wallH + 1.25, 0), Color3.fromRGB(235, 235, 240), Enum.Material.Concrete)

        for z = -60, 60, 40 do
            PartBuilder.makePart(roofModel, "RoofSteelTruss_" .. z, Vector3.new(body.halfX * 2 - 8, 2.0, 1.6),
                CFrame.new(0, floorY + wallH - 1.0, z), Color3.fromRGB(70, 78, 88), Enum.Material.Metal)
            for _, lx in ipairs({ -69, 0, 69 }) do
                PartBuilder.addPointLight(lights, "HighBayAtriumLight_" .. lx .. "_" .. z,
                    Vector3.new(lx, floorY + wallH - 2.2, z), Color3.fromRGB(255, 252, 245), 60, 1.4)
            end
        end
    end
end

function Floors4To6_UpperAtrium.build(parent)
    buildSingleUpperFloor(parent, 4, false)
    buildSingleUpperFloor(parent, 5, false)
    buildSingleUpperFloor(parent, 6, true)
    print("🏢 [Floors 4-6 Built] สร้างชั้น 4, ชั้น 5, และ ชั้น 6 (รูเห็นสนามฟุตซอล & สนามบาส + ห้องน้ำ 4 มุม + ห้องปิดครบทุกโซน) สำเร็จสมบูรณ์!")
end

return Floors4To6_UpperAtrium
