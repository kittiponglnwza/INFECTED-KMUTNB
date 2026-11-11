--[[
    Floors8To11_UpperAtrium.lua
    โครงสร้างและรายละเอียดชั้น 8, ชั้น 9, ชั้น 10, และ ชั้น 11 อาคาร 40 ปี มจพ.
    创建ตามแปลน ชั้น 8-11 (media_1794262974977_a5324a78.png):
      - ผังและแนวเส้นกริดสมดุล เสมอเป็นระนาบและพื้นเดียวกันเหมือนชั้น 4-6 ทุกจุด (ไม่มีเหลี่ยมยื่นเหลื่อมกัน):
        * แถบบน (Z = -120..-86) และแถบล่าง (Z = +86..+120):
          [ห้องน้ำ] [ห้อง ปิด] [ลิฟต์/บันได] | โถงกลาง | [บันได/ลิฟต์] [ห้อง ปิด] [ห้องน้ำ]
          ระนาบหน้าห้องทุกห้องตรงกันที่ Z = ±86 เป๊ะ 100%
        * ปีกซ้ายสุด & ขวาสุด (X = ±116..±150, Z = -86..+86):
          [ห้อง ปิด] ยาวเชื่อมชนห้องน้ำมุมบนและล่าง ระนาบผนังหน้าห้องตรงกันที่ X = ±116 เป๊ะ 100%
        * รูเห็นสนามวอลเลย์บอล (ซ้าย: X = -98..-30, Z = -68..+68) และ รูเห็นสนามแบดมินตัน (ขวา: X = +30..+98, Z = -68..+68)
      - ปรับดีไซน์ประตู "ห้อง ปิด" บนชั้น 8-11 ให้หลากหลายและแตกต่างจากชั้น 4-6 (4 สไตล์สลับกันไปตามห้องและชั้น):
        1) ประตูกรอบอลูมิเนียมโมเดิร์นพร้อมช่องกระจกฝ้าแนวตั้งและมือจับสแตนเลสยาว
        2) ประตูไม้สักคู่มะฮอกกานีคาดคิ้วทองเหลืองพร้อมช่องแสงด้านบน
        3) ประตูเหล็กนิรภัยห้องปฏิบัติการ/ชมรมพร้อมช่องกระจกมองและเครื่องสแกนคีย์การ์ดไฟแดง
        4) ประตูไม้โอ๊คทูโทนคาดแถบกราไฟต์พร้อมป้ายสถานะห้องปิดล็อก
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local StairBuilder = require(script.Parent.Parent.utils.StairBuilder)
local ElevatorBuilder = require(script.Parent.Parent.utils.ElevatorBuilder)
local SlabBuilder = require(script.Parent.Parent.utils.SlabBuilder)
local OfficeBuilder = require(script.Parent.Parent.utils.OfficeBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Floors8To11_UpperAtrium = {}

-- ช่องโถงมองลงสนามวอลเลย์บอล (ซ้าย) และสนามแบดมินตัน (ขวา) ชั้น 7
local VOLLEY_VOID    = { minX = -98, maxX = -30, minZ = -68, maxZ = 68 }
local BADMINTON_VOID = { minX =  30, maxX =  98, minZ = -68, maxZ = 68 }

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

    for _, cx in ipairs({ rect.minX - thick / 2, rect.maxX + thick / 2 }) do
        for z = rect.minZ, rect.maxZ, 34 do
            PartBuilder.makePart(m, "Post_" .. cx .. "_" .. z, Vector3.new(thick, railH, thick),
                CFrame.new(cx, floorY + railH / 2, z), postColor, Enum.Material.Metal)
        end
    end
end

-- สร้างกำแพงกระจกสีดำพร้อมเฟรมอะลูมิเนียมดำปิดทางเข้าโถงชั้น 11 (แนวแกน X ที่ zPos)
local function buildBlackGlassEntryWall(parent, namePrefix, zPos, xMin, xMax, wallHeight, floorY, signInfo)
    local blackFrame = Color3.fromRGB(18, 20, 25)
    local blackGlass = Color3.fromRGB(10, 12, 16)
    local spanX = xMax - xMin
    local midX = (xMin + xMax) / 2

    PartBuilder.makePart(parent, namePrefix .. "_BottomFrame", Vector3.new(spanX, 0.55, 0.7),
        CFrame.new(midX, floorY + 0.275, zPos), blackFrame, Enum.Material.Metal)
    PartBuilder.makePart(parent, namePrefix .. "_TopFrame", Vector3.new(spanX, 0.55, 0.7),
        CFrame.new(midX, floorY + wallHeight - 0.275, zPos), blackFrame, Enum.Material.Metal)
    PartBuilder.makePart(parent, namePrefix .. "_MidTransom", Vector3.new(spanX, 0.4, 0.55),
        CFrame.new(midX, floorY + 9.5, zPos), blackFrame, Enum.Material.Metal)

    local bayCount = 6
    for i = 0, bayCount do
        local mx = xMin + spanX * (i / bayCount)
        local postX = (i == 0) and (mx + 0.25) or (i == bayCount) and (mx - 0.25) or mx
        PartBuilder.makePart(parent, namePrefix .. "_Mullion_" .. i, Vector3.new(0.45, wallHeight - 0.5, 0.6),
            CFrame.new(postX, floorY + wallHeight / 2, zPos), blackFrame, Enum.Material.Metal)
    end

    PartBuilder.makePart(parent, namePrefix .. "_BlackGlass", Vector3.new(spanX - 0.2, wallHeight - 0.6, 0.35),
        CFrame.new(midX, floorY + wallHeight / 2, zPos), blackGlass, Enum.Material.Glass,
        { Transparency = 0.25, Reflectance = 0.25 })

    if signInfo then
        PartBuilder.makeSign(parent, namePrefix .. "_ClosedSign", signInfo.text,
            Vector3.new(24, 3.0, 0.15),
            Vector3.new(0, floorY + 13.0, zPos + signInfo.normalOffsetZ),
            signInfo.face, Color3.fromRGB(28, 30, 36), Color3.fromRGB(245, 245, 248))
    end
end

local function buildSingleUpperFloor8To11(parent, floorNum, isTopFloor)
    local isClosedFloor = (floorNum == 11)
    local floorModel = Instance.new("Model")
    floorModel.Name = string.format("Floor_%d_Building40", floorNum)
    floorModel.Parent = parent

    local floorY = Layout.floorY(floorNum)
    local wallH = Layout.FLOOR_HEIGHT    -- 22.0
    local wallThick = Layout.WALL_THICK  -- 2.0
    local wallColor = Color3.fromRGB(240, 237, 230)
    local wallMaterial = Enum.Material.Concrete
    local floorColor = Color3.fromRGB(220, 216, 208)

    local core = Layout.CORE
    local body = Layout.BODY
    local frontStair = Layout.STAIRS.Front
    local rearStair = Layout.STAIRS.Rear
    local frontLift = Layout.LIFTS.Front
    local rearLift = Layout.LIFTS.Rear

    ------------------------------------------------------------------
    -- 1. พื้นชั้น 8-11 ผืนเดียวกันทั้งชั้น (Top = floorY เป๊ะทุกตารางนิ้ว)
    --    เจาะช่องบันได 2 จุด + รูเห็นสนามวอลเลย์บอล (ซ้าย) + รูเห็นสนามแบดมินตัน (ขวา)
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
            VOLLEY_VOID,
            BADMINTON_VOID,
        },
        floorY, 2.0, floorColor, Enum.Material.SmoothPlastic
    )

    buildAtriumRailing(floorModel, "VolleyballAtriumOpening", VOLLEY_VOID, floorY,
        string.format("รูเห็นสนามวอลเลย์บอล (ชั้น %d)\nVOLLEYBALL COURT VIEW", floorNum))
    buildAtriumRailing(floorModel, "BadmintonAtriumOpening", BADMINTON_VOID, floorY,
        string.format("รูเห็นสนามแบดมินตัน (ชั้น %d)\nBADMINTON COURT VIEW", floorNum))

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

    -- ชั้น 11: กั้นกำแพงกระจกสีดำปิดทางเข้าสู่โถงชั้น 11 ทั้งฝั่งเหนือ-ใต้ (Z = ±86) โดยเปิดโถงลิฟต์และบันไดไว้เชื่อมต่อไปชั้น 12 ตามปกติ
    if isClosedFloor then
        local centerHalfW = core.centerWidth / 2 -- 30
        local clearH = wallH - 2.0               -- 20.0 (ชนใต้ท้องพื้นชั้น 12 พอดี ไม่ทะลุพื้นชั้น 12)
        local closedMsg = "⛔ ชั้น 11 ปิดใช้งาน (FLOOR 11 CLOSED)\n▲ ทางขึ้น ชั้น 12 สนามกีฬาในร่ม (ขึ้นทางบันไดด้านข้าง)"

        -- ฝั่งเหนือ (Z = -86): ขวา = +30 (ผนังบันได), ซ้าย = -31 (ผนังปล่องลิฟต์)
        buildBlackGlassEntryWall(northCore, "BlackGlass_NorthEntrance_F11", -(core.innerZ + 0.35),
            -(centerHalfW + 1.2), centerHalfW + 0.2, clearH, floorY,
            { normalOffsetZ = -0.45, face = Enum.NormalId.Front, text = closedMsg })

        -- ฝั่งใต้ (Z = +86): ซ้าย = -30 (ผนังบันได), ขวา = +31 (ผนังปล่องลิฟต์)
        buildBlackGlassEntryWall(southCore, "BlackGlass_SouthEntrance_F11", core.innerZ + 0.35,
            -(centerHalfW + 0.2), centerHalfW + 1.2, clearH, floorY,
            { normalOffsetZ = 0.45, face = Enum.NormalId.Back, text = closedMsg })
    end

    ------------------------------------------------------------------
    -- 3. ห้องน้ำ 4 มุม (X = ±116..±150, Z = ±86..±120, ขนาด 34 x 34 studs)
    --    ขอบในอยู่ที่ Z = ±86 ตรงแนวเดียวกับ [ห้อง ปิด], [ลิฟต์], และ [บันได] เป๊ะ!
    ------------------------------------------------------------------
    local restrooms = Instance.new("Model")
    restrooms.Name = "Restrooms_4Corners_F" .. floorNum
    restrooms.Parent = floorModel

    local rrW = 34
    local rrL = 34
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
    -- 4. โซนห้องกระจกแถบบน & แถบล่าง 4 ห้อง (X = ±68..±98, Z = ±86..±120)
    --    ชั้น 8-10: ห้องกระจกสำนักงาน/ชมรมเปิดเดินเข้าได้ (ห้อง 1004 บนชั้น 10 เป็นฟิตเนส); ชั้น 11 ปิดไฟและปิดทางเข้า
    ------------------------------------------------------------------
    local officesNS = Instance.new("Model")
    officesNS.Name = "GlassOffices_NorthSouth_4Zones"
    officesNS.Parent = floorModel

    local NS_OFFICE_PRESETS = {
        [8] = {
            { name = "Office_801", cx = -83, sz = -1, preset = "Meeting",     code = "ห้องประชุมชมรม 801\nCLUB MEETING 801" },
            { name = "Office_802", cx =  83, sz = -1, preset = "Executive",   code = "สำนักงานประธานชมรม 802\nCLUB PRESIDENT 802" },
            { name = "Office_803", cx = -83, sz =  1, preset = "Workstation", code = "ห้องปฏิบัติการชมรม 803\nCLUB WORKROOM 803" },
            { name = "Office_804", cx =  83, sz =  1, preset = "Meeting",     code = "ห้องประชุมฝ่ายกีฬา 804\nSPORTS CLUB MEETING 804" },
        },
        [9] = {
            { name = "Office_901", cx = -83, sz = -1, preset = "Meeting",     code = "ห้องประชุมวิชาการ 901\nACADEMIC MEETING 901" },
            { name = "Office_902", cx =  83, sz = -1, preset = "Executive",   code = "สำนักงานสโมสร 902\nCLUB OFFICE 902" },
            { name = "Office_903", cx = -83, sz =  1, preset = "Workstation", code = "ห้องกิจกรรมนักศึกษา 903\nACTIVITY ROOM 903" },
            { name = "Office_904", cx =  83, sz =  1, preset = "Meeting",     code = "ห้องประชุมสัมมนา 904\nSEMINAR ROOM 904" },
        },
        [10] = {
            { name = "Office_1001",  cx = -83, sz = -1, preset = "Meeting",     code = "ห้องประชุมองค์กร นศ. 1001\nSTUDENT ORG MEETING 1001" },
            { name = "Office_1002",  cx =  83, sz = -1, preset = "Executive",   code = "สำนักงานกองกิจการ 1002\nADMIN OFFICE 1002" },
            { name = "Office_1003",  cx = -83, sz =  1, preset = "Workstation", code = "ห้องทำงานโครงการ 1003\nPROJECT OFFICE 1003" },
            { name = "Fitness_1004", cx =  83, sz =  1, preset = "Fitness",     code = "ฟิตเนส 1004\nFITNESS CENTER 1004" },
        },
        [11] = {
            { name = "Office_1101", cx = -83, sz = -1, preset = "Meeting",     code = "ห้องอ่านหนังสือ/ประชุม 1101\nSTUDY & MEETING ROOM 1101" },
            { name = "Office_1102", cx =  83, sz = -1, preset = "Executive",   code = "สำนักงานผู้ดูแลอาคาร 1102\nRESIDENCE OFFICE 1102" },
            { name = "Office_1103", cx = -83, sz =  1, preset = "Workstation", code = "ห้องทำงาน & อ่านหนังสือ 1103\nCO-WORKING LOUNGE 1103" },
            { name = "Office_1104", cx =  83, sz =  1, preset = "Meeting",     code = "ห้องประชุม & พักผ่อน 1104\nLOUNGE & MEETING ROOM 1104" },
        },
    }

    for _, cfg in ipairs(NS_OFFICE_PRESETS[floorNum]) do
        OfficeBuilder.buildNorthSouthOffice(officesNS, {
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
            lightsOff = isClosedFloor,
        })
    end

    ------------------------------------------------------------------
    -- 5. ห้องกระจกสำนักงานปีกซ้าย & ปีกขวา (X = ±116..±150, Z = -86..+86)
    --    ชั้น 8-11: ห้องกระจกสำนักงานชมรม/หอพักทั้ง 3 ล็อกต่อฝั่ง
    ------------------------------------------------------------------
    local wingOfficesFolder = Instance.new("Model")
    wingOfficesFolder.Name = "GlassOffices_WestAndEastWings"
    wingOfficesFolder.Parent = floorModel

    local WING_TITLES = {
        [8] = {
            west = { "ชมรมวิชาการ/หุ่นยนต์", "ศูนย์ประสานงานชมรม", "ห้องประชุมชมรมฝ่ายซ้าย" },
            east = { "ชมรมอาสาพัฒนา", "ศูนย์กิจกรรมนักศึกษา", "ห้องประชุมชมรมฝ่ายขวา" },
        },
        [9] = {
            west = { "ชมรมดนตรี & ศิลปะ", "ศูนย์บริการชมรมกลาง", "ห้องประชุมฝ่ายกิจกรรม" },
            east = { "ชมรมคอมพิวเตอร์ & กีฬา", "สำนักงานองค์กร นศ.", "ห้องประชุมฝ่ายสื่อสาร" },
        },
        [10] = {
            west = { "ฝ่ายสภานักศึกษา", "ศูนย์รับเรื่ององค์กร นศ.", "ห้องประชุมสภานักศึกษา" },
            east = { "สำนักงานสโมสรกลาง", "ศูนย์ประสานโครงการ", "ห้องประชุมกรรมการกลาง" },
        },
        [11] = {
            west = { "KMUTNB Residence Office", "ศูนย์บริการหอพัก มจพ.", "ห้องประชุม & อ่านหนังสือ" },
            east = { "สำนักงานดูแลผู้พักอาศัย", "Co-Working & Lounge", "ห้องกิจกรรมส่วนกลาง" },
        },
    }

    for _, side in ipairs({ -1, 1 }) do
        local titles = (side < 0) and WING_TITLES[floorNum].west or WING_TITLES[floorNum].east
        OfficeBuilder.buildWingOfficeSuite(wingOfficesFolder, {
            side = side,
            floorNum = floorNum,
            roomTitles = titles,
            floorY = floorY,
            wallH = wallH,
            wallThick = wallThick,
            wallColor = wallColor,
            wallMat = wallMaterial,
            lightsOff = isClosedFloor,
        })
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
            Vector3.new(0, floorY + wallH - 2.0, lz), Color3.fromRGB(255, 248, 238), 50, 1.0, isClosedFloor)
    end
    for _, sx in ipairs({ -107, 107 }) do
        for _, lz in ipairs({ -75, 0, 75 }) do
            PartBuilder.addPointLight(lights, "WalkwayLight_" .. sx .. "_" .. lz,
                Vector3.new(sx, floorY + wallH - 2.0, lz), Color3.fromRGB(255, 248, 238), 42, 0.9, isClosedFloor)
        end
    end

    ------------------------------------------------------------------
    -- 7. โคมไฟโถงสูง Atrium ใต้ท้องพื้นชั้น 12 (ปิดไฟบนชั้น 11)
    ------------------------------------------------------------------
    if isClosedFloor then
        for z = -60, 60, 40 do
            for _, lx in ipairs({ -64, 0, 64 }) do
                PartBuilder.addPointLight(lights, "HighBayAtriumLight_" .. lx .. "_" .. z,
                    Vector3.new(lx, floorY + wallH - 2.2, z), Color3.fromRGB(255, 252, 245), 60, 1.45, true)
            end
        end
    end
end

function Floors8To11_UpperAtrium.build(parent)
    buildSingleUpperFloor8To11(parent, 8, false)
    buildSingleUpperFloor8To11(parent, 9, false)
    buildSingleUpperFloor8To11(parent, 10, false)
    buildSingleUpperFloor8To11(parent, 11, false)
    print("🏢 [Floors 8-11 Built] สร้างชั้น 8-11 รูเห็นสนามวอลเลย์บอล & แบดมินตัน + เชื่อมบันไดชั้น 11 ขึ้นสู่ชั้น 12 สำเร็จ!")
end

return Floors8To11_UpperAtrium
