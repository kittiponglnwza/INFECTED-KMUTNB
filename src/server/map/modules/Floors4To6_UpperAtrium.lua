--[[
    Floors4To6_UpperAtrium.lua
    โครงสร้างและรายละเอียดชั้น 4, ชั้น 5, และ ชั้น 6 อาคาร 40 ปี มจพ.
    ปรับแนวเส้นกริดให้สมดุล เสมอเป็นระนาบและพื้นเดียวกันทั้งหมด (ไม่มีเหลี่ยมยื่นเหลื่อมกัน):
      - แถบบน (Z = -120..-86) และแถบล่าง (Z = +86..+120):
        [ห้องน้ำ] [ห้อง ปิด] [ลิฟต์/บันได] | โถงกลาง | [บันได/ลิฟต์] [ห้อง ปิด] [ห้องน้ำ]
        ทุกห้องในแถบบนและล่างมีระนาบหน้าห้องตรงกันที่ Z = ±86 เป๊ะ 100%
      - ปีกซ้ายสุด & ขวาสุด (X = ±116..±150, Z = -86..+86):
        [ห้อง ปิด] ยาวเชื่อมชนห้องน้ำมุมบนและล่าง มีระนาบผนังหน้าห้องตรงกันที่ X = ±116 เป๊ะ 100%
      - รูเห็นสนามฟุตซอล (X = -98..-30, Z = -68..+68) และ รูเห็นสนามบาส (X = +30..+98, Z = -68..+68):
        ขอบซ้าย-ขวาตรงแนวเดียวกับบล็อก [ห้อง ปิด + ลิฟต์/บันได] (X = ±30..±98) สมมาตรซ้าย-ขวาและบน-ล่าง
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local StairBuilder = require(script.Parent.Parent.utils.StairBuilder)
local ElevatorBuilder = require(script.Parent.Parent.utils.ElevatorBuilder)
local SlabBuilder = require(script.Parent.Parent.utils.SlabBuilder)
local OfficeBuilder = require(script.Parent.Parent.utils.OfficeBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Floors4To6_UpperAtrium = {}

-- ช่องโถงมองลงสนามฟุตซอล (ซ้าย) และสนามบาส (ขวา) ตรงแนวเดียวกับบล็อกลิฟต์/บันได + ห้องปิด (X = ±30..±98)
local FUTSAL_VOID = { minX = -98, maxX = -30, minZ = -68, maxZ = 68 }
local BASKET_VOID = { minX =  30, maxX =  98, minZ = -68, maxZ = 68 }

local function buildAtriumRailing(parent, name, rect, floorY, signTitle)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent

    local railH = 3.6
    local thick = 0.4
    local topRailColor = Color3.fromRGB(185, 192, 200)
    local postColor = Color3.fromRGB(58, 64, 72)
    local glassColor = Color3.fromRGB(190, 225, 240)

    local w = rect.maxX - rect.minX -- 68
    local l = rect.maxZ - rect.minZ -- 136
    local midX = (rect.minX + rect.maxX) / 2
    local midZ = (rect.minZ + rect.maxZ) / 2

    -- ราวกันตกกระจกนิรภัยเรียบเสมอขอบช่องโถงพอดี (ไม่มีขอบปูนยื่นล้ำออกมาเกะกะทางเดิน)
    local sides = {
        { tag = "North", sizeX = w,     sizeZ = thick, px = midX,                  pz = rect.minZ - thick / 2 },
        { tag = "South", sizeX = w,     sizeZ = thick, px = midX,                  pz = rect.maxZ + thick / 2 },
        { tag = "West",  sizeX = thick, sizeZ = l,     px = rect.minX - thick / 2, pz = midZ },
        { tag = "East",  sizeX = thick, sizeZ = l,     px = rect.maxX + thick / 2, pz = midZ },
    }

    for _, s in ipairs(sides) do
        PartBuilder.makePart(m, "GlassGuard_" .. s.tag,
            Vector3.new(s.sizeX, railH - 0.3, s.sizeZ),
            CFrame.new(s.px, floorY + (railH - 0.3) / 2, s.pz), glassColor, Enum.Material.Glass, { Transparency = 0.55 })
        PartBuilder.makePart(m, "TopHandrail_" .. s.tag,
            Vector3.new(s.sizeX, 0.3, s.sizeZ),
            CFrame.new(s.px, floorY + railH - 0.15, s.pz), topRailColor, Enum.Material.Metal)
    end

    -- เสาเหล็กสแตนเลสเรียบเสมอแนวราวกันตก (ไม่ยื่นเหลี่ยมออกมา)
    for _, cx in ipairs({ rect.minX - thick / 2, rect.maxX + thick / 2 }) do
        for z = rect.minZ, rect.maxZ, 34 do
            PartBuilder.makePart(m, "Post_" .. cx .. "_" .. z, Vector3.new(thick, railH, thick),
                CFrame.new(cx, floorY + railH / 2, z), postColor, Enum.Material.Metal)
        end
    end
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
    -- 1. พื้นชั้น 4-6 ผืนเดียวกันทั้งชั้น (Top = floorY เป๊ะทุกตารางนิ้ว)
    --    เจาะช่องบันได 2 จุด + รูเห็นสนามฟุตซอล (ซ้าย) + รูเห็นสนามบาส (ขวา)
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

    buildAtriumRailing(floorModel, "FutsalAtriumOpening", FUTSAL_VOID, floorY,
        string.format("รูเห็นสนามฟุตซอล (ชั้น %d)\nFUTSAL COURT VIEW", floorNum))
    buildAtriumRailing(floorModel, "BasketballAtriumOpening", BASKET_VOID, floorY,
        string.format("รูเห็นสนามบาส (ชั้น %d)\nBASKETBALL COURT VIEW", floorNum))

    ------------------------------------------------------------------
    -- 2. คอร์ลิฟต์และบันได (X = ±30..±68, Z = ±86..±120)
    ------------------------------------------------------------------
    local function buildStairCore(folder, def)
        local m = Instance.new("Model")
        m.Name = string.format("%s_F%d", def.name, floorNum)
        m.Parent = folder

        StairBuilder.buildEnclosure(m, def, floorY, wallH, floorNum)
        if not isTopFloor then
            StairBuilder.buildUStair(m, def, floorY, wallH)
        else
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
    PartBuilder.makePart(northCore, "NorthEndGlass", Vector3.new(core.centerWidth, wallH - 9, 0.4),
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
    PartBuilder.makePart(southCore, "SouthEndGlass", Vector3.new(core.centerWidth, wallH - 9, 0.4),
        CFrame.new(0, floorY + 5 + (wallH - 9) / 2, core.outerZ - 1.0), Color3.fromRGB(165, 205, 220), Enum.Material.Glass, { Transparency = 0.55 })
    PartBuilder.makePart(southCore, "SouthEndHeader", Vector3.new(core.centerWidth, 4.0, wallThick),
        CFrame.new(0, floorY + wallH - 2.0, core.outerZ - wallThick / 2), wallColor, wallMaterial)

    ------------------------------------------------------------------
    -- 3. ห้องน้ำ 4 มุม (X = ±116..±150, Z = ±86..±120, ขนาด 34 x 34 studs)
    --    ขอบในอยู่ที่ Z = ±86 ตรงแนวเดียวกับ [ห้อง ปิด], [ลิฟต์], และ [บันได] เป๊ะ ไม่มีเหลี่ยมยื่นล้ำออกมา!
    ------------------------------------------------------------------
    local restrooms = Instance.new("Model")
    restrooms.Name = "Restrooms_4Corners_F" .. floorNum
    restrooms.Parent = floorModel

    local rrW = 34 -- X = ±116..±150
    local rrL = 34 -- Z = ±86..±120 (เสมอแนวเดียวกับห้องปิดและลิฟต์/บันไดที่ Z = ±86!)
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
            -- ช่องครึ่งห้องกว้าง 17 studs: ผนังข้างประตู 5 + ประตู 7 + ผนังข้างประตู 5 = 17 studs พอดีเป๊ะ
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
    -- 4. โซนห้องแถบบน & แถบล่าง 4 ห้อง (X = ±68..±98, Z = ±86..±120)
    --    ชั้น 4-5: ห้องกระจกสำนักงานเปิดเดินเข้าได้ | ชั้น 6: ห้องปิดทึบ
    ------------------------------------------------------------------
    local isOfficeFloor = (floorNum == 4 or floorNum == 5)
    local sealedRoomsNS = Instance.new("Model")
    sealedRoomsNS.Name = isOfficeFloor and "GlassOffices_NorthSouth_4Zones" or "SealedRooms_NorthSouth_4Zones"
    sealedRoomsNS.Parent = floorModel

    local nsConfigs
    if floorNum == 4 then
        nsConfigs = {
            { name = "Office_401", cx = -83, sz = -1, preset = "Meeting",     code = "ห้องประชุมย่อย 401\nMEETING ROOM 401" },
            { name = "Office_402", cx =  83, sz = -1, preset = "Executive",   code = "ห้องหัวหน้าฝ่าย 402\nSUPERVISOR OFFICE 402" },
            { name = "Office_403", cx = -83, sz =  1, preset = "Workstation", code = "ห้องให้คำปรึกษา นศ. 403\nADVISORY OFFICE 403" },
            { name = "Office_404", cx =  83, sz =  1, preset = "Meeting",     code = "ห้องประชุมแผนงาน 404\nPLANNING MEETING 404" },
        }
    elseif floorNum == 5 then
        nsConfigs = {
            { name = "Office_501", cx = -83, sz = -1, preset = "Meeting",     code = "ห้องประชุมกิจการ นศ. 501\nSTUDENT AFFAIRS MEETING 501" },
            { name = "Office_502", cx =  83, sz = -1, preset = "Executive",   code = "ห้องผู้อำนวยการ 502\nDIRECTOR OFFICE 502" },
            { name = "Office_503", cx = -83, sz =  1, preset = "Workstation", code = "ห้องทุนการศึกษา/กยศ. 503\nSCHOLARSHIP OFFICE 503" },
            { name = "Office_504", cx =  83, sz =  1, preset = "Meeting",     code = "ห้องประชุมชมรม นศ. 504\nCLUBS MEETING ROOM 504" },
        }
    else
        nsConfigs = {
            { name = "ClosedRoom_TopLeft",  cx = -83, sz = -1, code = string.format("ห้อง %d01 (ปิด)\nCLOSED ROOM", floorNum) },
            { name = "ClosedRoom_TopRight", cx =  83, sz = -1, code = string.format("ห้อง %d02 (ปิด)\nCLOSED ROOM", floorNum) },
            { name = "ClosedRoom_BotLeft",  cx = -83, sz =  1, code = string.format("ห้อง %d03 (ปิด)\nCLOSED ROOM", floorNum) },
            { name = "ClosedRoom_BotRight", cx =  83, sz =  1, code = string.format("ห้อง %d04 (ปิด)\nCLOSED ROOM", floorNum) },
        }
    end

    for _, cfg in ipairs(nsConfigs) do
        if isOfficeFloor then
            OfficeBuilder.buildNorthSouthOffice(sealedRoomsNS, {
                name = cfg.name,
                cx = cfg.cx,
                sz = cfg.sz,
                preset = cfg.preset,
                label = cfg.code,
                floorY = floorY,
                wallH = wallH,
                wallThick = wallThick,
                wallColor = wallColor,
                wallMat = wallMaterial,
            })
        else
            local rm = Instance.new("Model")
            rm.Name = cfg.name
            rm.Parent = sealedRoomsNS

            local cx, sz = cfg.cx, cfg.sz
            local sx = (cx > 0) and 1 or -1
            local roomW = 30 -- X = ±68..±98
            local roomD = 34 -- Z = ±86..±120
            local cz = sz * 103
            local frontWallCenterZ = sz * (86 + wallThick / 2) -- ±87 (ให้ผิวหน้าอยู่ที่ Z = ±86 เป๊ะ!)
            local outerZ = sz * (120 - wallThick / 2)
            local outerSideX = cx + sx * (roomW / 2 - wallThick / 2) -- ±97 (ผิวหน้าอยู่ที่ X = ±98 เป๊ะ!)
            local innerSideX = cx - sx * (roomW / 2 - wallThick / 2) -- ±69 (ชิดคอร์ลิฟต์/บันไดที่ X = ±68)

            PartBuilder.makePart(rm, "Wall_OuterZ", Vector3.new(roomW, wallH, wallThick),
                CFrame.new(cx, floorY + wallH / 2, outerZ), wallColor, wallMaterial)
            PartBuilder.makePart(rm, "Wall_OppositeRestroom", Vector3.new(wallThick, wallH, roomD),
                CFrame.new(outerSideX, floorY + wallH / 2, cz), wallColor, wallMaterial)
            PartBuilder.makePart(rm, "Wall_CoreSide", Vector3.new(wallThick, wallH, roomD),
                CFrame.new(innerSideX, floorY + wallH / 2, cz), wallColor, wallMaterial)
            PartBuilder.makePart(rm, "Wall_FrontSolid", Vector3.new(roomW, wallH, wallThick),
                CFrame.new(cx, floorY + wallH / 2, frontWallCenterZ), wallColor, wallMaterial)

            -- ปิดผนังขอบตึก (Z = ±120) ช่วงทางเดินหน้าห้องน้ำ (X = ±98..±116)
            PartBuilder.makePart(rm, "CorridorEndWall_OuterZ", Vector3.new(18, wallH, wallThick),
                CFrame.new(sx * 107, floorY + wallH / 2, outerZ), wallColor, wallMaterial)

            -- ประตูไม้คู่ฝังเรียบไปกับระนาบผนัง (Flush Door ที่ Z = ±86)
            local doorFaceZ = sz * 86 - sz * 0.05
            PartBuilder.makePart(rm, "ClosedDoor_Frame", Vector3.new(8.6, 11.2, 0.12),
                CFrame.new(cx, floorY + 5.6, doorFaceZ), frameDark, Enum.Material.Metal)
            PartBuilder.makePart(rm, "ClosedDoor_PanelL", Vector3.new(3.8, 10.6, 0.16),
                CFrame.new(cx - 2.0, floorY + 5.3, doorFaceZ), doorWood, Enum.Material.Wood)
            PartBuilder.makePart(rm, "ClosedDoor_PanelR", Vector3.new(3.8, 10.6, 0.16),
                CFrame.new(cx + 2.0, floorY + 5.3, doorFaceZ), doorWood, Enum.Material.Wood)

            PartBuilder.makeSign(rm, "ClosedRoomSign", cfg.code, Vector3.new(16, 2.8, 0.15),
                Vector3.new(cx, floorY + 14.0, sz * 86 - sz * 0.1),
                sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
                Color3.fromRGB(65, 72, 82), Color3.fromRGB(255, 255, 255))
        end
    end

    ------------------------------------------------------------------
    -- 5. ปีกซ้ายสุด & ปีกขวาสุด (X = ±116..±150, Z = -86..+86)
    --    ชั้น 4-5: ห้องกระจกสำนักงานทั้ง 3 ล็อก | ชั้น 6: ห้องปิดทึบ
    ------------------------------------------------------------------
    local wingSealedFolder = Instance.new("Model")
    wingSealedFolder.Name = isOfficeFloor and "GlassOffices_WestAndEastWings" or "SealedRooms_WestAndEastWings"
    wingSealedFolder.Parent = floorModel

    local wingDepth = 34  -- X = ±116..±150
    local wingSpanZ = 172 -- Z = -86..+86 (ชนผนังห้องน้ำที่ Z = ±86 พอดีเป๊ะ!)

    for _, side in ipairs({ -1, 1 }) do
        if isOfficeFloor then
            local titles
            if floorNum == 5 then
                titles = (side < 0)
                    and { "ฝ่ายกิจกรรมนักศึกษา", "ศูนย์บริการ กยศ./ทุน", "ห้องประชุมสโมสร นศ." }
                    or  { "สำนักงานกองพัฒนานักศึกษา", "ศูนย์รับเรื่องและบริการ", "ห้องประชุมคณะกรรมการ" }
            else
                titles = (side < 0)
                    and { "สำนักงานกิจการนักศึกษา", "ศูนย์บริการนักศึกษา", "ห้องประชุมและประสานงาน" }
                    or  { "ฝ่ายพัฒนานักศึกษา", "ศูนย์แนะแนวและบริการ", "ห้องประชุมฝ่ายวิชาการ" }
            end
            OfficeBuilder.buildWingOfficeSuite(wingSealedFolder, {
                side = side,
                floorNum = floorNum,
                roomTitles = titles,
                floorY = floorY,
                wallH = wallH,
                wallThick = wallThick,
                wallColor = wallColor,
                wallMat = wallMaterial,
            })
        else
            local wModel = Instance.new("Model")
            wModel.Name = (side < 0) and "WestWing_ClosedRooms" or "EastWing_ClosedRooms"
            wModel.Parent = wingSealedFolder

            local outerWallX = side * (150 - wallThick / 2)
            local innerWallX = side * (150 - wingDepth + wallThick / 2) -- ±117 (ผิวหน้าอยู่ที่ X = ±116 เป๊ะ!)
            local midX = side * (150 - wingDepth / 2)

            PartBuilder.makePart(wModel, "OuterWall_X", Vector3.new(wallThick, wallH, wingSpanZ),
                CFrame.new(outerWallX, floorY + wallH / 2, 0), wallColor, wallMaterial)
            PartBuilder.makePart(wModel, "CorridorWall_X", Vector3.new(wallThick, wallH, wingSpanZ),
                CFrame.new(innerWallX, floorY + wallH / 2, 0), wallColor, wallMaterial)

            local doorFaceX = side * 116 - side * 0.05
            local signFace = (side < 0) and Enum.NormalId.Right or Enum.NormalId.Left

            for idx, doorZ in ipairs({ -54, 0, 54 }) do
                local roomNum = (side < 0) and (floorNum * 100 + 10 + idx) or (floorNum * 100 + 20 + idx)
                PartBuilder.makePart(wModel, "ClosedDoorFrame_" .. idx, Vector3.new(0.12, 11.2, 8.6),
                    CFrame.new(doorFaceX, floorY + 5.6, doorZ), frameDark, Enum.Material.Metal)
                PartBuilder.makePart(wModel, "ClosedDoorL_" .. idx, Vector3.new(0.16, 10.6, 3.8),
                    CFrame.new(doorFaceX, floorY + 5.3, doorZ - 2.0), doorWood, Enum.Material.Wood)
                PartBuilder.makePart(wModel, "ClosedDoorR_" .. idx, Vector3.new(0.16, 10.6, 3.8),
                    CFrame.new(doorFaceX, floorY + 5.3, doorZ + 2.0), doorWood, Enum.Material.Wood)

                local deptLabel = string.format("กองกิจการนักศึกษา/ห้องเรียน %d (ห้องปิด)\nSTUDENT AFFAIRS & CLASSROOM (CLOSED)", roomNum)
                PartBuilder.makeSign(wModel, "WingClosedSign_" .. idx,
                    deptLabel,
                    Vector3.new(0.15, 2.8, 18),
                    Vector3.new(side * 116 - side * 0.1, floorY + 14.0, doorZ),
                    signFace, Color3.fromRGB(65, 72, 82), Color3.fromRGB(255, 255, 255))
            end

            for _, divZ in ipairs({ -28, 28 }) do
                PartBuilder.makePart(wModel, "InternalDivider_" .. divZ, Vector3.new(wingDepth - wallThick * 2, wallH, 1.2),
                    CFrame.new(midX, floorY + wallH / 2, divZ), wallColor, wallMaterial)
            end
        end
    end

    ------------------------------------------------------------------
    -- 6. โถงทางเดินกลาง + เสาโครงสร้างเรียบเสมอแนวขอบโถง (X = ±30)
    ------------------------------------------------------------------
    local concourse = Instance.new("Model")
    concourse.Name = "CentralConcourse_F" .. floorNum
    concourse.Parent = floorModel

    for _, px in ipairs({ -30, 30 }) do
        for _, pz in ipairs({ -60, -20, 20, 60 }) do
            PartBuilder.makePart(concourse, "Column_" .. px .. "_" .. pz, Vector3.new(2.4, wallH, 2.4),
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
    for _, sx in ipairs({ -107, 107 }) do
        for _, lz in ipairs({ -75, 0, 75 }) do
            PartBuilder.addPointLight(lights, "WalkwayLight_" .. sx .. "_" .. lz,
                Vector3.new(sx, floorY + wallH - 2.0, lz), Color3.fromRGB(255, 248, 238), 42, 0.9)
        end
    end

    ------------------------------------------------------------------
    -- 7. ไฟส่องสว่างโถงสูง Atrium ใต้พื้นชั้น 7 (ที่เพดานชั้น 6)
    ------------------------------------------------------------------
    if floorNum == 6 then
        for z = -60, 60, 40 do
            for _, lx in ipairs({ -64, 0, 64 }) do
                PartBuilder.addPointLight(lights, "HighBayAtriumLight_" .. lx .. "_" .. z,
                    Vector3.new(lx, floorY + wallH - 2.2, z), Color3.fromRGB(255, 252, 245), 60, 1.4)
            end
        end
    end
end

function Floors4To6_UpperAtrium.build(parent)
    buildSingleUpperFloor(parent, 4, false)
    buildSingleUpperFloor(parent, 5, false)
    buildSingleUpperFloor(parent, 6, false)
    print("🏢 [Floors 4-6 Built] ปรับแนวผนังและพื้นชั้น 4-6 ให้สมดุล เชื่อมบันไดขึ้นไปชั้น 7 เรียบร้อย!")
end

return Floors4To6_UpperAtrium
