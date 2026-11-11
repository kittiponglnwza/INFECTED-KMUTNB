--[[
    OfficeBuilder.lua
    ตัวช่วยสร้างห้องกระจกแบบสำนักงาน (Modern Glass-Walled Offices) สำหรับชั้น 4 และชั้น 5 อาคาร 40 ปี มจพ.
    - ผนังด้านหน้าทางเดินเป็นกระจกเต็มแนวพร้อมเฟรมอะลูมิเนียม แถบฝ้าบังสายตา และประตูกระจกคู่เปิดเดินเข้าได้จริง
    - ผนังกั้นระหว่างห้อง (Internal Dividers) เป็นผนังกระจกสำนักงานโปร่งตา
    - เจาะช่องหน้าต่างริมอาคารตรงแนวกระจกภายนอกของ Building40_ExteriorFacade เพื่อให้แสงและมุมมองสมจริง
    - ตกแต่งภายในด้วยโต๊ะทำงาน คอมพิวเตอร์ เก้าอี้สำนักงาน เคาน์เตอร์บริการ ห้องประชุม ตู้เอกสาร และไฟฝ้า LED
]]

local PartBuilder = require(script.Parent.PartBuilder)

local OfficeBuilder = {}

-- พาเลตต์สีและวัสดุมาตรฐานสำนักงานสมัยใหม่
local FRAME_DARK     = Color3.fromRGB(44, 48, 56)    -- กรอบอะลูมิเนียมสีเทาเข้ม
local ALUMINUM_TRIM  = Color3.fromRGB(165, 172, 180) -- สแตนเลส/มือจับประตู
local GLASS_TINT     = Color3.fromRGB(172, 214, 232) -- กระจกสำนักงานใสอมฟ้า
local FROST_STRIPE   = Color3.fromRGB(238, 244, 248) -- แถบสติกเกอร์ฝ้าคาดกลางกระจก
local SIGN_BG        = Color3.fromRGB(42, 48, 58)
local TEXT_WHITE     = Color3.fromRGB(255, 255, 255)

local WOOD_DESK      = Color3.fromRGB(192, 152, 108)
local WOOD_WALNUT    = Color3.fromRGB(124, 86, 56)
local DESK_WHITE     = Color3.fromRGB(240, 238, 234)
local CHAIR_FABRIC   = Color3.fromRGB(52, 58, 66)
local SOFA_FABRIC    = Color3.fromRGB(64, 78, 96)
local CABINET_METAL  = Color3.fromRGB(198, 202, 208)
local SCREEN_GLOW    = Color3.fromRGB(58, 122, 178)
local PLANT_GREEN    = Color3.fromRGB(56, 128, 66)
local POT_COLOR      = Color3.fromRGB(224, 220, 214)

-- ความสูงชั้นมาตรฐานของผนังกระจกสำนักงาน (สูงถึงฝ้าบุผนัง 16.5 และผนังทึบด้านบน 16.5..22.0)
local GLASS_TOP_H = 16.5
local DOOR_OPEN_W = 8.0
local DOOR_OPEN_H = 11.2
local DOOR_LEAF_W = 3.85
local DOOR_LEAF_H = 10.8

--------------------------------------------------------------------------------
-- 1. ชิ้นส่วนเฟอร์นิเจอร์สำนักงานที่ใช้ซ้ำ (หมุนด้วย baseCF ได้ทุกทิศทาง)
--------------------------------------------------------------------------------

local function buildOfficeChair(parent, prefix, baseCF, seatColor)
    local col = seatColor or CHAIR_FABRIC
    -- ฐานล้อและแกนกลาง
    PartBuilder.makePart(parent, prefix .. "_Base", Vector3.new(1.6, 0.2, 1.6),
        baseCF * CFrame.new(0, 0.1, 0), FRAME_DARK, Enum.Material.Metal)
    PartBuilder.makePart(parent, prefix .. "_Stem", Vector3.new(0.32, 1.3, 0.32),
        baseCF * CFrame.new(0, 0.75, 0), ALUMINUM_TRIM, Enum.Material.Metal)
    -- เบาะนั่ง (หันหน้าไปทาง -Z ของ baseCF)
    PartBuilder.makePart(parent, prefix .. "_Seat", Vector3.new(2.0, 0.32, 2.0),
        baseCF * CFrame.new(0, 1.55, 0), col, Enum.Material.Fabric)
    -- พนักพิง (+Z ของ baseCF)
    PartBuilder.makePart(parent, prefix .. "_Back", Vector3.new(1.9, 2.1, 0.28),
        baseCF * CFrame.new(0, 2.65, 0.88), col, Enum.Material.Fabric)
end

-- โต๊ะทำงานพร้อมจอคอมพิวเตอร์ คีย์บอร์ด และเก้าอี้ (หันหน้าคนนั่งไปทาง -Z ของ deskCF)
local function buildWorkstation(parent, prefix, deskCF, deskW, deskD, woodColor, hasChair, accentColor)
    local w = deskW or 7.2
    local d = deskD or 3.4
    local legH = 2.6
    local topY = legH + 0.12

    PartBuilder.makePart(parent, prefix .. "_Top", Vector3.new(w, 0.24, d),
        deskCF * CFrame.new(0, topY, 0), woodColor or WOOD_DESK, Enum.Material.Wood)

    for _, lx in ipairs({ -(w / 2 - 0.35), (w / 2 - 0.35) }) do
        PartBuilder.makePart(parent, prefix .. "_Leg_" .. (lx > 0 and "R" or "L"),
            Vector3.new(0.25, legH, d - 0.4),
            deskCF * CFrame.new(lx, legH / 2, 0), FRAME_DARK, Enum.Material.Metal)
    end

    -- จอคอมพิวเตอร์ตั้งโต๊ะหันหน้ามาหาเก้าอี้ (+Z)
    PartBuilder.makePart(parent, prefix .. "_MonStand", Vector3.new(0.6, 0.55, 0.45),
        deskCF * CFrame.new(0, topY + 0.38, -d * 0.24), FRAME_DARK, Enum.Material.Metal)
    PartBuilder.makePart(parent, prefix .. "_MonBezel", Vector3.new(2.8, 1.7, 0.18),
        deskCF * CFrame.new(0, topY + 1.35, -d * 0.24), FRAME_DARK, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(parent, prefix .. "_MonScreen", Vector3.new(2.6, 1.5, 0.06),
        deskCF * CFrame.new(0, topY + 1.35, -d * 0.24 + 0.08), SCREEN_GLOW, Enum.Material.SmoothPlastic)

    -- คีย์บอร์ด & แผ่นรองเมาส์
    PartBuilder.makePart(parent, prefix .. "_Keyboard", Vector3.new(1.5, 0.08, 0.55),
        deskCF * CFrame.new(-0.2, topY + 0.16, d * 0.12), FRAME_DARK, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(parent, prefix .. "_MousePad", Vector3.new(0.65, 0.04, 0.65),
        deskCF * CFrame.new(1.05, topY + 0.14, d * 0.12), accentColor or SOFA_FABRIC, Enum.Material.SmoothPlastic)

    if hasChair ~= false then
        buildOfficeChair(parent, prefix .. "_Chair",
            deskCF * CFrame.new(0, 0, d / 2 + 1.35), accentColor or CHAIR_FABRIC)
    end
end

-- ชุดโต๊ะทำงานหันหน้าชนกัน 2 ที่นั่ง + ฉากกั้นอะคริลิกฝ้า
local function buildDualWorkstationPod(parent, prefix, centerCF, accentColor)
    local d = 3.4
    local w = 7.4
    buildWorkstation(parent, prefix .. "_A", centerCF * CFrame.new(0, 0,  d / 2 + 0.1), w, d, WOOD_DESK, true, accentColor)
    buildWorkstation(parent, prefix .. "_B", centerCF * CFrame.new(0, 0, -(d / 2 + 0.1)) * CFrame.Angles(0, math.rad(180), 0), w, d, WOOD_DESK, true, accentColor)
    PartBuilder.makePart(parent, prefix .. "_DeskDivider", Vector3.new(w - 0.3, 1.4, 0.16),
        centerCF * CFrame.new(0, 3.42, 0), FROST_STRIPE, Enum.Material.Glass, { Transparency = 0.35 })
end

-- ตู้เอกสารสูงสำหรับวางชิดผนัง (ด้านหน้าหัน +Z)
local function buildFilingCabinet(parent, prefix, baseCF, width, height, depth)
    local w = width or 6.0
    local h = height or 7.6
    local d = depth or 2.2
    PartBuilder.makePart(parent, prefix .. "_Body", Vector3.new(w, h, d),
        baseCF * CFrame.new(0, h / 2, 0), CABINET_METAL, Enum.Material.Metal)
    PartBuilder.makePart(parent, prefix .. "_UpperGlass", Vector3.new(w - 0.5, h * 0.45, 0.1),
        baseCF * CFrame.new(0, h * 0.7, d / 2 + 0.02), GLASS_TINT, Enum.Material.Glass, { Transparency = 0.45 })
    PartBuilder.makePart(parent, prefix .. "_MidTrim", Vector3.new(w - 0.4, 0.18, 0.14),
        baseCF * CFrame.new(0, h * 0.42, d / 2 + 0.03), FRAME_DARK, Enum.Material.Metal)
end

-- กระถางต้นไม้ประดับสำนักงาน
local function buildPottedPlant(parent, prefix, posVec)
    PartBuilder.makePart(parent, prefix .. "_Pot", Vector3.new(1.8, 1.8, 1.8),
        CFrame.new(posVec + Vector3.new(0, 0.9, 0)), POT_COLOR, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(parent, prefix .. "_Stem", Vector3.new(0.32, 2.2, 0.32),
        CFrame.new(posVec + Vector3.new(0, 2.6, 0)), WOOD_WALNUT, Enum.Material.Wood)
    PartBuilder.makePart(parent, prefix .. "_FoliageLower", Vector3.new(2.8, 2.2, 2.8),
        CFrame.new(posVec + Vector3.new(0, 3.8, 0)), PLANT_GREEN, Enum.Material.Grass)
    PartBuilder.makePart(parent, prefix .. "_FoliageTop", Vector3.new(1.8, 1.6, 1.8),
        CFrame.new(posVec + Vector3.new(0, 5.1, 0)), PLANT_GREEN, Enum.Material.Grass)
end

-- โต๊ะประชุมยาว + เก้าอี้รอบโต๊ะ (length ตามแกน Z ของ tableCF)
local function buildConferenceSetup(parent, prefix, tableCF, width, length, chairCountPerSide, accentColor)
    local w = width or 6.6
    local l = length or 15.0
    local topY = 2.75
    PartBuilder.makePart(parent, prefix .. "_TableTop", Vector3.new(w, 0.3, l),
        tableCF * CFrame.new(0, topY, 0), WOOD_WALNUT, Enum.Material.Wood)
    for _, lz in ipairs({ -l * 0.32, l * 0.32 }) do
        PartBuilder.makePart(parent, prefix .. "_Pedestal_" .. lz, Vector3.new(w * 0.45, topY - 0.15, 0.8),
            tableCF * CFrame.new(0, (topY - 0.15) / 2, lz), FRAME_DARK, Enum.Material.Metal)
    end

    local spacing = (l - 3.0) / math.max(1, chairCountPerSide - 1)
    local startZ = -(l - 3.0) / 2
    for i = 1, chairCountPerSide do
        local cz = (chairCountPerSide == 1) and 0 or (startZ + (i - 1) * spacing)
        buildOfficeChair(parent, prefix .. "_ChairL_" .. i,
            tableCF * CFrame.new(-(w / 2 + 1.35), 0, cz) * CFrame.Angles(0, math.rad(-90), 0), accentColor)
        buildOfficeChair(parent, prefix .. "_ChairR_" .. i,
            tableCF * CFrame.new(w / 2 + 1.35, 0, cz) * CFrame.Angles(0, math.rad(90), 0), accentColor)
    end
end

-- ไฟฝ้าเพดาน LED สำนักงาน (ใต้ท้องพื้นชั้นบนที่ floorY + 20.0)
local function buildOfficeCeilingLight(parent, name, posXZ, floorY)
    PartBuilder.makePart(parent, name .. "_Housing", Vector3.new(8.5, 0.14, 3.2),
        CFrame.new(posXZ.X, floorY + 19.92, posXZ.Y), FRAME_DARK, Enum.Material.Metal, { CanCollide = false })
    PartBuilder.makePart(parent, name .. "_LED", Vector3.new(8.0, 0.08, 2.7),
        CFrame.new(posXZ.X, floorY + 19.82, posXZ.Y), Color3.fromRGB(252, 250, 245), Enum.Material.Neon, { CanCollide = false })
    -- ฝัง PointLight ไว้ในโคมฝ้าเดียวกันเพื่อไม่ให้เกิดกล่อง _Fixture ลอยต่ำกว่าฝ้าเพดาน
    PartBuilder.addPointLight(parent, name .. "_Light",
        Vector3.new(posXZ.X, floorY + 19.86, posXZ.Y), Color3.fromRGB(248, 250, 255), 42, 1.1)
end

--------------------------------------------------------------------------------
-- 2. โครงสร้างผนังกระจกสำนักงาน & ประตูกระจกคู่เปิดได้จริง
--------------------------------------------------------------------------------

-- สร้างแผงกระจกฟิกซ์ 1 ช่วงตามแกน spanAxis ("X" หรือ "Z")
local function buildGlassWallSegment(parent, prefix, axis, posAlong, frontCenterFixed, spanLen, floorY)
    local function vec(along, h, thick)
        return (axis == "X") and Vector3.new(along, h, thick) or Vector3.new(thick, h, along)
    end
    local function cf(along, y)
        return (axis == "X") and CFrame.new(along, y, frontCenterFixed) or CFrame.new(frontCenterFixed, y, along)
    end

    -- ขอบฐานอะลูมิเนียมล่าง (0..0.5)
    PartBuilder.makePart(parent, prefix .. "_BasePlinth", vec(spanLen, 0.5, 0.65),
        cf(posAlong, floorY + 0.25), FRAME_DARK, Enum.Material.Metal)
    -- แผงกระจกใสสำนักงาน (0.5..16.5)
    PartBuilder.makePart(parent, prefix .. "_Glass", vec(spanLen - 0.1, GLASS_TOP_H - 0.5, 0.24),
        cf(posAlong, floorY + 0.5 + (GLASS_TOP_H - 0.5) / 2), GLASS_TINT, Enum.Material.Glass, { Transparency = 0.62 })
    -- แถบสติกเกอร์ฝ้าบังสายตาตรงกลางกระจก (4.3..6.1)
    PartBuilder.makePart(parent, prefix .. "_FrostBand", vec(spanLen - 0.1, 1.8, 0.30),
        cf(posAlong, floorY + 5.2), FROST_STRIPE, Enum.Material.SmoothPlastic, { Transparency = 0.36, CanCollide = false })
end

-- สร้างช่องประตูกระจกคู่แบบเปิดแง้มเข้าไปด้านในห้อง (เดินเข้าออกได้สะดวก 6.7+ studs)
local function buildOpenDoubleGlassDoor(parent, prefix, axis, doorCenterAlong, frontCenterFixed, inDirSign, floorY)
    local theta = math.rad(82)
    local cosT, sinT = math.cos(theta), math.sin(theta)
    local cy = floorY + DOOR_LEAF_H / 2

    -- แผงกระจก Transom เหนือกรอบประตู (11.2..16.5)
    local transH = GLASS_TOP_H - DOOR_OPEN_H
    local transSize = (axis == "X") and Vector3.new(DOOR_OPEN_W, transH, 0.24) or Vector3.new(0.24, transH, DOOR_OPEN_W)
    local transPos = (axis == "X")
        and CFrame.new(doorCenterAlong, floorY + DOOR_OPEN_H + transH / 2, frontCenterFixed)
        or CFrame.new(frontCenterFixed, floorY + DOOR_OPEN_H + transH / 2, doorCenterAlong)
    PartBuilder.makePart(parent, prefix .. "_TransomGlass", transSize, transPos, GLASS_TINT, Enum.Material.Glass, { Transparency = 0.62 })

    -- บานประตูกระจกคู่ 2 บานเปิดเข้าไปในห้อง
    for _, sideSign in ipairs({ -1, 1 }) do
        local hingeAlong = doorCenterAlong + sideSign * (DOOR_OPEN_W / 2 - 0.1)
        -- rightVec ชี้จากบานพับไปยังขอบปลายบานประตู
        local rightVec = (axis == "X")
            and Vector3.new(-sideSign * cosT, 0, inDirSign * sinT)
            or Vector3.new(inDirSign * sinT, 0, -sideSign * cosT)

        local hingePos = (axis == "X")
            and Vector3.new(hingeAlong, cy, frontCenterFixed)
            or Vector3.new(frontCenterFixed, cy, hingeAlong)
        local leafCenter = hingePos + rightVec * (DOOR_LEAF_W / 2)
        local leafCF = CFrame.fromMatrix(leafCenter, rightVec, Vector3.yAxis)

        local tag = (sideSign < 0) and "A" or "B"
        PartBuilder.makePart(parent, prefix .. "_DoorGlass_" .. tag,
            Vector3.new(DOOR_LEAF_W, DOOR_LEAF_H, 0.22), leafCF,
            GLASS_TINT, Enum.Material.Glass, { Transparency = 0.48 })
        -- คิ้วอะลูมิเนียมบน-ล่างของบานประตู และมือจับสแตนเลส
        PartBuilder.makePart(parent, prefix .. "_DoorRailBot_" .. tag,
            Vector3.new(DOOR_LEAF_W, 0.35, 0.30), leafCF * CFrame.new(0, -DOOR_LEAF_H / 2 + 0.18, 0),
            FRAME_DARK, Enum.Material.Metal)
        PartBuilder.makePart(parent, prefix .. "_DoorRailTop_" .. tag,
            Vector3.new(DOOR_LEAF_W, 0.35, 0.30), leafCF * CFrame.new(0, DOOR_LEAF_H / 2 - 0.18, 0),
            FRAME_DARK, Enum.Material.Metal)
        PartBuilder.makePart(parent, prefix .. "_DoorHandle_" .. tag,
            Vector3.new(0.14, 2.2, 0.48), leafCF * CFrame.new(DOOR_LEAF_W * 0.36, -0.4, 0),
            ALUMINUM_TRIM, Enum.Material.Metal)
    end
end

-- สร้างผนังมีช่องหน้าต่างตรงกับหน้าต่างภายนอกอาคาร (ไม่มีผนังปิดทึบบังหน้าต่าง)
local function buildExteriorWindowWall(parent, prefix, axis, fixedPos, spanStart, spanEnd, windowCenters, winOpenW, floorY, wallH, wallThick, wallColor, wallMat)
    local sillTop = 7.4
    local lintelBot = 16.0
    local totalLen = spanEnd - spanStart
    local midSpan = (spanStart + spanEnd) / 2

    local function vec(along, h)
        return (axis == "X") and Vector3.new(along, h, wallThick) or Vector3.new(wallThick, h, along)
    end
    local function cf(along, y)
        return (axis == "X") and CFrame.new(along, y, fixedPos) or CFrame.new(fixedPos, y, along)
    end

    -- ผนังทึบล่างใต้ขอบหน้าต่าง (0..7.4) และผนังเหนือหน้าต่าง (16.0..wallH)
    PartBuilder.makePart(parent, prefix .. "_SpandrelLow", vec(totalLen, sillTop),
        cf(midSpan, floorY + sillTop / 2), wallColor, wallMat)
    PartBuilder.makePart(parent, prefix .. "_HeaderHigh", vec(totalLen, wallH - lintelBot),
        cf(midSpan, floorY + lintelBot + (wallH - lintelBot) / 2), wallColor, wallMat)

    -- เสาผนังทึบสลับช่องหน้าต่างช่วงระดับกลาง (7.4..16.0)
    local midH = lintelBot - sillTop
    local cur = spanStart
    for idx, wc in ipairs(windowCenters) do
        local winStart = wc - winOpenW / 2
        local winEnd = wc + winOpenW / 2
        if winStart > cur + 0.1 then
            local pierLen = winStart - cur
            PartBuilder.makePart(parent, prefix .. "_Pier_" .. idx, vec(pierLen, midH),
                cf(cur + pierLen / 2, floorY + sillTop + midH / 2), wallColor, wallMat)
        end
        -- ขอบวงกบอลูมิเนียมด้านในช่องหน้าต่าง
        PartBuilder.makePart(parent, prefix .. "_WinSill_" .. idx, vec(winOpenW + 0.4, 0.25),
            cf(wc, floorY + sillTop + 0.12), FRAME_DARK, Enum.Material.Metal)
        PartBuilder.makePart(parent, prefix .. "_WinHead_" .. idx, vec(winOpenW + 0.4, 0.25),
            cf(wc, floorY + lintelBot - 0.12), FRAME_DARK, Enum.Material.Metal)
        cur = winEnd
    end
    if spanEnd > cur + 0.1 then
        local lastLen = spanEnd - cur
        PartBuilder.makePart(parent, prefix .. "_PierEnd", vec(lastLen, midH),
            cf(cur + lastLen / 2, floorY + sillTop + midH / 2), wallColor, wallMat)
    end
end

--------------------------------------------------------------------------------
-- 3. ห้องกระจกแถบเหนือ-ใต้ (Z = ±86..±120, X = ±68..±98) จำนวน 4 ห้องต่อชั้น
--------------------------------------------------------------------------------

-- อุปกรณ์ฟิตเนสสำหรับห้อง Fitness (สร้างเป็นสัดส่วนและหันหน้าถูกต้องตามแกน)
local function buildTreadmill(parent, prefix, baseCF)
    local beltColor = Color3.fromRGB(32, 34, 38)
    local accentOrange = Color3.fromRGB(228, 108, 38)
    -- ฐานลู่วิ่ง + สายพาน (วิ่งเข้าหา -Z)
    PartBuilder.makePart(parent, prefix .. "_Deck", Vector3.new(3.1, 0.42, 6.2),
        baseCF * CFrame.new(0, 0.21, 0), FRAME_DARK, Enum.Material.Metal)
    PartBuilder.makePart(parent, prefix .. "_Belt", Vector3.new(2.4, 0.08, 5.2),
        baseCF * CFrame.new(0, 0.44, 0.35), beltColor, Enum.Material.SmoothPlastic)
    -- เสาตั้งหน้าซ้าย-ขวา + คอนโซลหน้าปัด LED
    for _, sx in ipairs({ -1.35, 1.35 }) do
        PartBuilder.makePart(parent, prefix .. "_Upright_" .. sx, Vector3.new(0.28, 3.8, 0.36),
            baseCF * CFrame.new(sx, 2.0, -2.35) * CFrame.Angles(math.rad(-10), 0, 0), FRAME_DARK, Enum.Material.Metal)
        PartBuilder.makePart(parent, prefix .. "_Grip_" .. sx, Vector3.new(0.24, 0.24, 1.6),
            baseCF * CFrame.new(sx, 3.25, -1.6), accentOrange, Enum.Material.SmoothPlastic)
    end
    PartBuilder.makePart(parent, prefix .. "_Console", Vector3.new(3.0, 0.85, 1.1),
        baseCF * CFrame.new(0, 3.95, -2.45) * CFrame.Angles(math.rad(-25), 0, 0), FRAME_DARK, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(parent, prefix .. "_LED", Vector3.new(2.2, 0.48, 0.08),
        baseCF * CFrame.new(0, 4.02, -2.02) * CFrame.Angles(math.rad(-25), 0, 0), Color3.fromRGB(48, 190, 235), Enum.Material.Neon)
end

local function buildSpinBike(parent, prefix, baseCF)
    local accentOrange = Color3.fromRGB(228, 108, 38)
    PartBuilder.makePart(parent, prefix .. "_Base", Vector3.new(1.8, 0.22, 4.1),
        baseCF * CFrame.new(0, 0.11, 0), FRAME_DARK, Enum.Material.Metal)
    -- ล้อฟลายวีลด้านหน้า (-Z)
    PartBuilder.makeCylinder(parent, prefix .. "_Flywheel", Vector3.new(0.38, 1.9, 1.9),
        baseCF * CFrame.new(0, 1.25, -1.35), ALUMINUM_TRIM, Enum.Material.Metal)
    PartBuilder.makePart(parent, prefix .. "_Fork", Vector3.new(0.45, 2.5, 0.45),
        baseCF * CFrame.new(0, 2.1, -1.2) * CFrame.Angles(math.rad(-14), 0, 0), accentOrange, Enum.Material.Metal)
    PartBuilder.makePart(parent, prefix .. "_Handlebar", Vector3.new(1.8, 0.22, 0.3),
        baseCF * CFrame.new(0, 3.35, -1.05), FRAME_DARK, Enum.Material.SmoothPlastic)
    -- หลักอาน + เบาะนั่ง (+Z)
    PartBuilder.makePart(parent, prefix .. "_SeatPost", Vector3.new(0.3, 2.2, 0.35),
        baseCF * CFrame.new(0, 1.4, 1.15) * CFrame.Angles(math.rad(12), 0, 0), FRAME_DARK, Enum.Material.Metal)
    PartBuilder.makePart(parent, prefix .. "_Saddle", Vector3.new(0.9, 0.3, 1.2),
        baseCF * CFrame.new(0, 2.55, 1.25), accentOrange, Enum.Material.SmoothPlastic)
end

local function buildFitnessInterior(rm, cx, sz, sx, floorY, innerSideX)
    local function gymPos(dx, dy, dz)
        return Vector3.new(cx + sx * dx, floorY + dy, sz * (103 + dz))
    end

    -- 1. พื้นยางกันกระแทกฟิตเนส + กระจกเงาบานใหญ่ติดผนังด้านใน
    PartBuilder.makePart(rm, "GymRubberFloor", Vector3.new(24.6, 0.05, 27.0),
        CFrame.new(cx, floorY + 0.025, sz * 103.5), Color3.fromRGB(36, 40, 46), Enum.Material.SmoothPlastic, { CanCollide = false })
    PartBuilder.makePart(rm, "GymFloorStripe", Vector3.new(24.6, 0.06, 0.5),
        CFrame.new(cx, floorY + 0.03, sz * 95), Color3.fromRGB(228, 108, 38), Enum.Material.SmoothPlastic, { CanCollide = false })

    PartBuilder.makePart(rm, "GymMirrorFrame", Vector3.new(0.16, 9.8, 18.4),
        CFrame.new(innerSideX + sx * 1.1, floorY + 5.2, sz * 104), FRAME_DARK, Enum.Material.Metal)
    PartBuilder.makePart(rm, "GymWallMirror", Vector3.new(0.2, 9.2, 17.8),
        CFrame.new(innerSideX + sx * 1.12, floorY + 5.2, sz * 104), Color3.fromRGB(205, 228, 240), Enum.Material.Glass, { Reflectance = 0.65, Transparency = 0.08 })

    -- 2. แร็คดัมเบล 2 ชั้น (dx = -10.8) + ม้านั่งเล่นเวท (dx = -5.5)
    for _, endDz in ipairs({ -0.4, 8.4 }) do
        PartBuilder.makePart(rm, "DumbbellRackPost_" .. endDz, Vector3.new(1.8, 3.2, 0.35),
            CFrame.new(gymPos(-10.8, 1.6, endDz)), FRAME_DARK, Enum.Material.Metal)
    end
    for tierIdx, tier in ipairs({ { dy = 1.6, shiftX = 0.25 }, { dy = 2.9, shiftX = -0.25 } }) do
        PartBuilder.makePart(rm, "DumbbellShelf_" .. tierIdx, Vector3.new(1.0, 0.2, 9.0),
            CFrame.new(gymPos(-10.8 + tier.shiftX, tier.dy, 4.0)), FRAME_DARK, Enum.Material.Metal)
        for dIdx = 1, 5 do
            local dZ = 0.8 + (dIdx - 1) * 1.6
            PartBuilder.makePart(rm, string.format("Dumbbell_%d_%d", tierIdx, dIdx), Vector3.new(1.2, 0.52, 0.52),
                CFrame.new(gymPos(-10.8 + tier.shiftX, tier.dy + 0.36, dZ)),
                (dIdx % 2 == 1) and Color3.fromRGB(28, 30, 35) or Color3.fromRGB(228, 108, 38), Enum.Material.Metal)
        end
    end

    PartBuilder.makePart(rm, "WeightBenchFrame", Vector3.new(1.4, 1.2, 4.8),
        CFrame.new(gymPos(-5.5, 0.6, 2.5)), FRAME_DARK, Enum.Material.Metal)
    PartBuilder.makePart(rm, "WeightBenchPad", Vector3.new(1.6, 0.35, 5.0),
        CFrame.new(gymPos(-5.5, 1.35, 2.5)), Color3.fromRGB(228, 108, 38), Enum.Material.SmoothPlastic)

    -- 3. ลู่วิ่งไฟฟ้า 2 เครื่อง หน้าหน้าต่าง (dz = +10.5, หันหน้าเข้าโถง)
    local treadRot = (sz > 0) and 0 or 180
    buildTreadmill(rm, "Treadmill_1", CFrame.new(gymPos(-5.5, 0, 10.5)) * CFrame.Angles(0, math.rad(treadRot), 0))
    buildTreadmill(rm, "Treadmill_2", CFrame.new(gymPos( 0.5, 0, 10.5)) * CFrame.Angles(0, math.rad(treadRot), 0))

    -- 4. แร็คสควอท & บาร์เบลพร้อมแผ่นน้ำหนัก (dx = +8.8, dz = +5.5)
    local rx, rz = 8.8, 5.5
    for _, px in ipairs({ -2.1, 2.1 }) do
        for _, pz in ipairs({ -2.0, 2.0 }) do
            PartBuilder.makePart(rm, string.format("RackPost_%s_%s", px, pz), Vector3.new(0.42, 8.2, 0.42),
                CFrame.new(gymPos(rx + px, 4.1, rz + pz)), FRAME_DARK, Enum.Material.Metal)
        end
        PartBuilder.makePart(rm, "RackTopBar_" .. px, Vector3.new(0.42, 0.42, 4.4),
            CFrame.new(gymPos(rx + px, 8.0, rz)), FRAME_DARK, Enum.Material.Metal)
        PartBuilder.makePart(rm, "RackSafety_" .. px, Vector3.new(0.32, 0.25, 4.2),
            CFrame.new(gymPos(rx + px, 3.2, rz)), Color3.fromRGB(228, 108, 38), Enum.Material.Metal)
    end
    PartBuilder.makePart(rm, "RackPullUpBar", Vector3.new(4.6, 0.28, 0.28),
        CFrame.new(gymPos(rx, 8.0, rz - 1.9)), ALUMINUM_TRIM, Enum.Material.Metal)
    -- บาร์เบลวางพาดแร็ค + แผ่นน้ำหนัก
    PartBuilder.makeCylinder(rm, "OlympicBar", Vector3.new(7.8, 0.22, 0.22),
        CFrame.new(gymPos(rx - 1.8, 4.7, rz)) * CFrame.Angles(0, math.rad(90), 0), ALUMINUM_TRIM, Enum.Material.Metal)
    for _, pOff in ipairs({ -3.1, -2.7, 2.7, 3.1 }) do
        PartBuilder.makeCylinder(rm, "BumperPlate_" .. pOff, Vector3.new(0.24, 1.9, 1.9),
            CFrame.new(gymPos(rx - 1.8, 4.7, rz + pOff)) * CFrame.Angles(0, math.rad(90), 0),
            (math.abs(pOff) > 2.9) and Color3.fromRGB(205, 45, 45) or Color3.fromRGB(35, 95, 195), Enum.Material.SmoothPlastic)
    end

    -- 5. จักรยานปั่นออกกำลังกาย 2 คัน มองเห็นชัดจากกระจกด้านหน้า (dx = +8.8, dz = -4.5 / -9.5)
    local bikeRot = sx * 90 -- หันหน้าเข้ากลางห้อง
    buildSpinBike(rm, "SpinBike_1", CFrame.new(gymPos(8.8, 0, -4.5)) * CFrame.Angles(0, math.rad(bikeRot), 0))
    buildSpinBike(rm, "SpinBike_2", CFrame.new(gymPos(8.8, 0, -9.5)) * CFrame.Angles(0, math.rad(bikeRot), 0))

    -- 6. เสื่อโยคะ + ตู้กดน้ำดื่ม
    PartBuilder.makePart(rm, "YogaMat", Vector3.new(3.0, 0.08, 6.0),
        CFrame.new(gymPos(1.0, 0.06, 2.5)), Color3.fromRGB(48, 125, 175), Enum.Material.SmoothPlastic, { CanCollide = false })
    PartBuilder.makePart(rm, "WaterCoolerBody", Vector3.new(1.6, 3.6, 1.6),
        CFrame.new(gymPos(-11.0, 1.8, -12.5)), DESK_WHITE, Enum.Material.SmoothPlastic)
    PartBuilder.makeCylinder(rm, "WaterCoolerJug", Vector3.new(1.6, 1.3, 1.3),
        CFrame.new(gymPos(-11.0, 4.4, -12.5)) * CFrame.Angles(0, 0, math.rad(90)),
        GLASS_TINT, Enum.Material.Glass, { Transparency = 0.35 })
end

function OfficeBuilder.buildNorthSouthOffice(parent, cfg)
    local rm = Instance.new("Model")
    rm.Name = cfg.name
    rm.Parent = parent

    local cx, sz = cfg.cx, cfg.sz
    local sx = (cx > 0) and 1 or -1
    local floorY = cfg.floorY
    local wallH = cfg.wallH
    local wallThick = cfg.wallThick
    local wallColor = cfg.wallColor
    local wallMat = cfg.wallMat

    local roomW = 30
    local roomD = 34
    local cz = sz * 103
    local outerZ = sz * (120 - wallThick / 2)
    local outerSideX = cx + sx * (roomW / 2 - wallThick / 2)
    local innerSideX = cx - sx * (roomW / 2 - wallThick / 2)
    local frontGlassZ = sz * 86.6
    local bulkheadZ = sz * (86 + wallThick / 2)
    local inDirZ = sz -- ทิศทางเปิดประตูจากทางเดินเข้าไปด้านในห้อง (เหนือ -> -Z, ใต้ -> +Z)

    -- 1. ผนังด้านนอกพร้อมช่องหน้าต่าง (wx = sx * 78) + ผนังข้าง 2 ด้าน + ผนังปิดสุดทางเดินหน้าห้องน้ำ
    buildExteriorWindowWall(rm, "OuterWall", "X", outerZ, cx - roomW / 2, cx + roomW / 2,
        { sx * 79 }, 14, floorY, wallH, wallThick, wallColor, wallMat)
    PartBuilder.makePart(rm, "Wall_OppositeRestroom", Vector3.new(wallThick, wallH, roomD),
        CFrame.new(outerSideX, floorY + wallH / 2, cz), wallColor, wallMat)
    PartBuilder.makePart(rm, "Wall_CoreSide", Vector3.new(wallThick, wallH, roomD),
        CFrame.new(innerSideX, floorY + wallH / 2, cz), wallColor, wallMat)
    PartBuilder.makePart(rm, "CorridorEndWall_OuterZ", Vector3.new(18, wallH, wallThick),
        CFrame.new(sx * 107, floorY + wallH / 2, outerZ), wallColor, wallMat)

    -- 2. ผนังกระจกสำนักงานด้านหน้า (Z = ±86.6) พร้อมเฟรมอะลูมิเนียม และประตูเปิดเข้าได้
    buildGlassWallSegment(rm, "FrontGlassL", "X", cx - 9, frontGlassZ, 10, floorY)
    buildGlassWallSegment(rm, "FrontGlassR", "X", cx + 9, frontGlassZ, 10, floorY)
    buildOpenDoubleGlassDoor(rm, "FrontDoor", "X", cx, frontGlassZ, inDirZ, floorY)

    PartBuilder.makePart(rm, "HeaderBar_Door", Vector3.new(28, 0.45, 0.7),
        CFrame.new(cx, floorY + DOOR_OPEN_H, frontGlassZ), FRAME_DARK, Enum.Material.Metal)
    PartBuilder.makePart(rm, "HeaderBar_Top", Vector3.new(28, 0.45, 0.7),
        CFrame.new(cx, floorY + GLASS_TOP_H, frontGlassZ), FRAME_DARK, Enum.Material.Metal)
    for _, mx in ipairs({ -13.8, -9, -4.1, 4.1, 9, 13.8 }) do
        PartBuilder.makePart(rm, "Mullion_" .. mx, Vector3.new(0.45, GLASS_TOP_H, 0.7),
            CFrame.new(cx + mx, floorY + GLASS_TOP_H / 2, frontGlassZ), FRAME_DARK, Enum.Material.Metal)
    end
    PartBuilder.makePart(rm, "UpperBulkhead", Vector3.new(roomW, wallH - GLASS_TOP_H, wallThick),
        CFrame.new(cx, floorY + GLASS_TOP_H + (wallH - GLASS_TOP_H) / 2, bulkheadZ), wallColor, wallMat)

    -- ป้ายชื่อห้องสำนักงานขนาดกะทัดรัดเหนือกรอบกระจก
    PartBuilder.makeSign(rm, "OfficeRoomSign", cfg.label, Vector3.new(14, 2.0, 0.14),
        Vector3.new(cx, floorY + 18.2, sz * 86 - sz * 0.1),
        sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
        SIGN_BG, TEXT_WHITE)

    -- 3. พื้นพรม (สำหรับสำนักงาน) & ไฟเพดาน LED
    if cfg.preset ~= "Fitness" then
        PartBuilder.makePart(rm, "OfficeCarpet", Vector3.new(23, 0.04, 25),
            CFrame.new(cx, floorY + 0.02, sz * 104), Color3.fromRGB(78, 86, 98), Enum.Material.Fabric, { CanCollide = false })
    end
    buildOfficeCeilingLight(rm, "OfficeLight", Vector2.new(cx, sz * 104), floorY)

    -- 4. จัดวางเฟอร์นิเจอร์ภายในตามประเภทห้อง (เว้นช่องประตู sz * 88..sz * 95 โล่ง)
    local faceDoorRot = (sz < 0) and 180 or 0 -- local -Z (หน้าคนนั่ง/โต๊ะ) หันเข้าหาประตูทางเดิน
    if cfg.preset == "Fitness" then
        buildFitnessInterior(rm, cx, sz, sx, floorY, innerSideX)
    elseif cfg.preset == "Meeting" then
        buildConferenceSetup(rm, "ConfTable",
            CFrame.new(cx - sx * 1.5, floorY, sz * 105), 6.2, 14.0, 3, SOFA_FABRIC)
        -- จอทีวีพรีเซนต์ติดผนังด้านข้าง
        PartBuilder.makePart(rm, "PresentationTV", Vector3.new(0.35, 5.2, 9.5),
            CFrame.new(outerSideX - sx * 1.2, floorY + 6.8, sz * 105), FRAME_DARK, Enum.Material.SmoothPlastic)
        PartBuilder.makePart(rm, "PresentationTV_Screen", Vector3.new(0.4, 4.7, 9.0),
            CFrame.new(outerSideX - sx * 1.25, floorY + 6.8, sz * 105), SCREEN_GLOW, Enum.Material.SmoothPlastic)
        buildPottedPlant(rm, "Plant", Vector3.new(innerSideX + sx * 3.0, floorY, sz * 114.5))
    elseif cfg.preset == "Executive" then
        local deskZ = sz * 108
        buildWorkstation(rm, "ExecDesk",
            CFrame.new(cx, floorY, deskZ) * CFrame.Angles(0, math.rad(faceDoorRot), 0),
            10.5, 4.2, WOOD_WALNUT, true, SOFA_FABRIC)
        -- เก้าอี้ผู้ติดต่อหน้าโต๊ะ 2 ตัว
        for _, gx in ipairs({ -2.8, 2.8 }) do
            buildOfficeChair(rm, "GuestChair_" .. gx,
                CFrame.new(cx + gx, floorY, sz * 103) * CFrame.Angles(0, math.rad(faceDoorRot + 180), 0),
                CHAIR_FABRIC)
        end
        buildFilingCabinet(rm, "ExecCabinet",
            CFrame.new(outerSideX - sx * 2.2, floorY, sz * 104) * CFrame.Angles(0, math.rad(sx > 0 and -90 or 90), 0),
            10.0, 8.2, 2.2)
        buildPottedPlant(rm, "Plant", Vector3.new(innerSideX + sx * 3.0, floorY, sz * 114.5))
    else
        -- Advisor / Staff Office (โต๊ะทำงานคู่ + ตู้เอกสาร)
        for _, wx in ipairs({ -6.8, 6.8 }) do
            buildWorkstation(rm, "StaffDesk_" .. wx,
                CFrame.new(cx + wx, floorY, sz * 106) * CFrame.Angles(0, math.rad(faceDoorRot), 0),
                7.0, 3.4, WOOD_DESK, true, SOFA_FABRIC)
        end
        buildFilingCabinet(rm, "BackCabinet",
            CFrame.new(outerSideX - sx * 2.2, floorY, sz * 105) * CFrame.Angles(0, math.rad(sx > 0 and -90 or 90), 0),
            12.0, 7.8, 2.2)
        buildPottedPlant(rm, "Plant", Vector3.new(cx, floorY, sz * 115.2))
    end

    return rm
end

--------------------------------------------------------------------------------
-- 4. ปีกอาคารสำนักงานห้องกระจก (West & East Wings: X = ±116..±150, Z = -86..+86)
--------------------------------------------------------------------------------

function OfficeBuilder.buildWingOfficeSuite(parent, cfg)
    local wModel = Instance.new("Model")
    wModel.Name = (cfg.side < 0) and "WestWing_GlassOffices" or "EastWing_GlassOffices"
    wModel.Parent = parent

    local side = cfg.side -- -1 = West, +1 = East
    local floorNum = cfg.floorNum
    local floorY = cfg.floorY
    local wallH = cfg.wallH
    local wallThick = cfg.wallThick
    local wallColor = cfg.wallColor
    local wallMat = cfg.wallMat

    local wingDepth = 34
    local outerWallX = side * (150 - wallThick / 2) -- ±149
    local frontGlassX = side * 116.6                  -- ชิดแนวผนังห้องน้ำ ±116..±118
    local bulkheadX = side * (150 - wingDepth + wallThick / 2) -- ±117
    local midX = side * (150 - wingDepth / 2)        -- ±133
    local inDirX = side                              -- เดินเข้าจากทางเดิน (±116 -> ±150)

    -- 1. ผนังด้านนอกตึก (X = ±149) เจาะช่องหน้าต่างตรงตำแหน่ง ExteriorWindowsAndLouvers (-72,-40,0,40,72)
    buildExteriorWindowWall(wModel, "OuterWall", "Z", outerWallX, -86, 86,
        { -72, -40, 0, 40, 72 }, 16, floorY, wallH, wallThick, wallColor, wallMat)

    -- 2. ผนังกระจกสำนักงานยาวตลอดทั้งปีก (Z = -86..+86) แบ่งเป็น 3 ห้อง (ประตูที่ Z = -57, 0, +57)
    local doorCenters = { -57, 0, 57 }
    local fixedSegments = {
        { tag = "Seg1", z1 = -86, z2 = -61 },
        { tag = "Seg2", z1 = -53, z2 =  -4 },
        { tag = "Seg3", z1 =   4, z2 =  53 },
        { tag = "Seg4", z1 =  61, z2 =  86 },
    }
    for _, seg in ipairs(fixedSegments) do
        buildGlassWallSegment(wModel, "CorridorGlass_" .. seg.tag, "Z",
            (seg.z1 + seg.z2) / 2, frontGlassX, seg.z2 - seg.z1, floorY)
    end

    for idx, dz in ipairs(doorCenters) do
        buildOpenDoubleGlassDoor(wModel, "OfficeDoor_" .. idx, "Z", dz, frontGlassX, inDirX, floorY)
    end

    PartBuilder.makePart(wModel, "CorridorHeaderBar_Door", Vector3.new(0.7, 0.45, 172),
        CFrame.new(frontGlassX, floorY + DOOR_OPEN_H, 0), FRAME_DARK, Enum.Material.Metal)
    PartBuilder.makePart(wModel, "CorridorHeaderBar_Top", Vector3.new(0.7, 0.45, 172),
        CFrame.new(frontGlassX, floorY + GLASS_TOP_H, 0), FRAME_DARK, Enum.Material.Metal)

    local mullionZs = { -85.7, -73.5, -61.2, -52.8, -40.5, -28.0, -16.0, -4.2, 4.2, 16.0, 28.0, 40.5, 52.8, 61.2, 73.5, 85.7 }
    for _, mz in ipairs(mullionZs) do
        PartBuilder.makePart(wModel, "Mullion_" .. mz, Vector3.new(0.7, GLASS_TOP_H, 0.45),
            CFrame.new(frontGlassX, floorY + GLASS_TOP_H / 2, mz), FRAME_DARK, Enum.Material.Metal)
    end

    PartBuilder.makePart(wModel, "CorridorUpperBulkhead", Vector3.new(wallThick, wallH - GLASS_TOP_H, 172),
        CFrame.new(bulkheadX, floorY + GLASS_TOP_H + (wallH - GLASS_TOP_H) / 2, 0), wallColor, wallMat)

    -- 3. ผนังกั้นห้องกระจกภายใน (Z = -28 และ Z = +28)
    local divSpanX = 30.5 -- เชื่อมจากหน้ากระจก (±117.5) ถึงผนังนอก (±148)
    local divCenterX = side * 132.75
    for _, divZ in ipairs({ -28, 28 }) do
        PartBuilder.makePart(wModel, "DivKneeWall_" .. divZ, Vector3.new(divSpanX, 3.6, 0.9),
            CFrame.new(divCenterX, floorY + 1.8, divZ), wallColor, wallMat)
        PartBuilder.makePart(wModel, "DivGlass_" .. divZ, Vector3.new(divSpanX, GLASS_TOP_H - 3.6, 0.24),
            CFrame.new(divCenterX, floorY + 3.6 + (GLASS_TOP_H - 3.6) / 2, divZ),
            GLASS_TINT, Enum.Material.Glass, { Transparency = 0.62 })
        PartBuilder.makePart(wModel, "DivFrost_" .. divZ, Vector3.new(divSpanX, 1.6, 0.30),
            CFrame.new(divCenterX, floorY + 5.2, divZ), FROST_STRIPE, Enum.Material.SmoothPlastic, { Transparency = 0.36, CanCollide = false })
        PartBuilder.makePart(wModel, "DivTopBar_" .. divZ, Vector3.new(divSpanX, 0.4, 0.6),
            CFrame.new(divCenterX, floorY + GLASS_TOP_H, divZ), FRAME_DARK, Enum.Material.Metal)
        for _, mx in ipairs({ 124, 134, 144 }) do
            PartBuilder.makePart(wModel, string.format("DivMullion_%d_%d", divZ, mx), Vector3.new(0.4, GLASS_TOP_H - 3.6, 0.55),
                CFrame.new(side * mx, floorY + 3.6 + (GLASS_TOP_H - 3.6) / 2, divZ), FRAME_DARK, Enum.Material.Metal)
        end
        PartBuilder.makePart(wModel, "DivBulkhead_" .. divZ, Vector3.new(divSpanX, wallH - GLASS_TOP_H, 0.9),
            CFrame.new(divCenterX, floorY + GLASS_TOP_H + (wallH - GLASS_TOP_H) / 2, divZ), wallColor, wallMat)
    end

    -- 4. ป้ายหน้าห้องสำนักงาน + พรม + ไฟฝ้า LED + เฟอร์นิเจอร์ครบทั้ง 3 ห้อง
    local signFace = (side < 0) and Enum.NormalId.Right or Enum.NormalId.Left
    local roomTitles = cfg.roomTitles
    local faceCorridorRot = (side < 0) and -90 or 90 -- local -Z (หน้าเก้าอี้/โต๊ะ) หันออกมาทางโถงทางเดิน ±116

    for idx, bayZ in ipairs(doorCenters) do
        local roomNum = (side < 0) and (floorNum * 100 + 10 + idx) or (floorNum * 100 + 20 + idx)
        local bayFolder = Instance.new("Folder")
        bayFolder.Name = "WingOfficeBay_" .. roomNum
        bayFolder.Parent = wModel

        PartBuilder.makeSign(bayFolder, "OfficeBaySign",
            string.format("%s %d", roomTitles[idx], roomNum),
            Vector3.new(0.14, 2.0, 15.0),
            Vector3.new(side * 116 - side * 0.1, floorY + 18.2, bayZ),
            signFace, SIGN_BG, TEXT_WHITE)

        PartBuilder.makePart(bayFolder, "BayCarpet", Vector3.new(26, 0.04, 51),
            CFrame.new(midX, floorY + 0.02, bayZ), Color3.fromRGB(82, 90, 102), Enum.Material.Fabric, { CanCollide = false })
        buildOfficeCeilingLight(bayFolder, "BayLight_N", Vector2.new(midX, bayZ - 14), floorY)
        buildOfficeCeilingLight(bayFolder, "BayLight_S", Vector2.new(midX, bayZ + 14), floorY)

        if idx == 1 then
            -- ห้อง 1 (ฝั่งเหนือ Z = -57): โซนโต๊ะทำงานเจ้าหน้าที่ 2 ชุด (4 ที่นั่ง) + ตู้เอกสาร + เครื่องพิมพ์
            buildDualWorkstationPod(bayFolder, "Pod_A",
                CFrame.new(side * 135, floorY, bayZ - 15) * CFrame.Angles(0, math.rad(faceCorridorRot), 0), SOFA_FABRIC)
            buildDualWorkstationPod(bayFolder, "Pod_B",
                CFrame.new(side * 135, floorY, bayZ + 14) * CFrame.Angles(0, math.rad(faceCorridorRot), 0), SOFA_FABRIC)
            buildFilingCabinet(bayFolder, "NorthEndCabinets",
                CFrame.new(side * 134, floorY, -84.2), 14.0, 8.0, 2.2)
            -- โต๊ะวางเครื่องถ่ายเอกสาร/พรินเตอร์ตรงเสาระหว่างหน้าต่าง (Z = -56)
            PartBuilder.makePart(bayFolder, "PrinterStand", Vector3.new(3.2, 2.8, 6.0),
                CFrame.new(side * 146.2, floorY + 1.4, -56), CABINET_METAL, Enum.Material.Metal)
            PartBuilder.makePart(bayFolder, "CopierBody", Vector3.new(2.4, 2.2, 2.6),
                CFrame.new(side * 146.2, floorY + 3.9, -56), DESK_WHITE, Enum.Material.SmoothPlastic)
            buildPottedPlant(bayFolder, "Plant", Vector3.new(side * 145.5, floorY, -30.5))

        elseif idx == 2 then
            -- ห้อง 2 (กลาง Z = 0): เคาน์เตอร์ติดต่อบริการนักศึกษา + โต๊ะทำงานหลังเคาน์เตอร์ + เก้าอี้รอรับบริการ
            local counterX = side * 128.5
            PartBuilder.makePart(bayFolder, "ServiceCounterBase", Vector3.new(2.8, 3.6, 17.0),
                CFrame.new(counterX, floorY + 1.8, bayZ), DESK_WHITE, Enum.Material.SmoothPlastic)
            PartBuilder.makePart(bayFolder, "ServiceCounterTop", Vector3.new(3.4, 0.3, 17.6),
                CFrame.new(counterX, floorY + 3.7, bayZ), WOOD_WALNUT, Enum.Material.Wood)
            PartBuilder.makePart(bayFolder, "ServiceGlassShield", Vector3.new(0.22, 1.8, 16.0),
                CFrame.new(counterX - side * 0.9, floorY + 4.75, bayZ), GLASS_TINT, Enum.Material.Glass, { Transparency = 0.45 })
            for _, cz in ipairs({ -4.5, 4.5 }) do
                buildOfficeChair(bayFolder, "CounterStaffChair_" .. cz,
                    CFrame.new(counterX + side * 2.8, floorY, cz) * CFrame.Angles(0, math.rad(faceCorridorRot), 0), SOFA_FABRIC)
            end

            -- โต๊ะทำงานด้านหลังเคาน์เตอร์ 2 โต๊ะ
            for _, dz in ipairs({ -17.5, 17.5 }) do
                buildWorkstation(bayFolder, "BackDesk_" .. dz,
                    CFrame.new(side * 139.5, floorY, dz) * CFrame.Angles(0, math.rad(faceCorridorRot), 0),
                    7.6, 3.4, WOOD_DESK, true, SOFA_FABRIC)
            end
            -- ชุดเก้าอี้พักคอยหน้าห้อง
            PartBuilder.makePart(bayFolder, "WaitingBenchSeat", Vector3.new(2.2, 0.4, 9.0),
                CFrame.new(side * 121.5, floorY + 1.6, -18), SOFA_FABRIC, Enum.Material.Fabric)
            PartBuilder.makePart(bayFolder, "WaitingBenchFrame", Vector3.new(1.8, 1.4, 8.4),
                CFrame.new(side * 121.5, floorY + 0.7, -18), FRAME_DARK, Enum.Material.Metal)
            buildPottedPlant(bayFolder, "Plant_N", Vector3.new(side * 121, floorY, -25))
            buildPottedPlant(bayFolder, "Plant_S", Vector3.new(side * 121, floorY, 24))

        else
            -- ห้อง 3 (ฝั่งใต้ Z = +57): ห้องประชุมทีมงาน + มุมโซฟารับแขก + ตู้เอกสาร
            buildConferenceSetup(bayFolder, "TeamConfTable",
                CFrame.new(side * 135, floorY, bayZ - 9), 6.8, 18.0, 4, SOFA_FABRIC)

            -- จอพรีเซนต์/ไวท์บอร์ดติดเสาผนังด้านนอก (Z = +56, X = side * 147.6)
            PartBuilder.makePart(bayFolder, "WhiteboardFrame", Vector3.new(0.3, 4.8, 12.0),
                CFrame.new(side * 147.7, floorY + 7.2, 56), FRAME_DARK, Enum.Material.Metal)
            PartBuilder.makePart(bayFolder, "WhiteboardSurface", Vector3.new(0.35, 4.3, 11.4),
                CFrame.new(side * 147.65, floorY + 7.2, 56), FROST_STRIPE, Enum.Material.SmoothPlastic)

            -- มุมโซฟารับรองตรงโซนใต้สุด (Z = +76)
            PartBuilder.makePart(bayFolder, "LoungeSofaSeat", Vector3.new(11.0, 1.4, 3.4),
                CFrame.new(side * 135, floorY + 0.9, 81.5), SOFA_FABRIC, Enum.Material.Fabric)
            PartBuilder.makePart(bayFolder, "LoungeSofaBack", Vector3.new(11.0, 2.2, 0.7),
                CFrame.new(side * 135, floorY + 2.3, 83.0), SOFA_FABRIC, Enum.Material.Fabric)
            PartBuilder.makePart(bayFolder, "LoungeCoffeeTable", Vector3.new(6.5, 1.3, 2.8),
                CFrame.new(side * 135, floorY + 0.65, 76.5), WOOD_DESK, Enum.Material.Wood)
            buildPottedPlant(bayFolder, "Plant", Vector3.new(side * 145.5, floorY, 83.0))
        end
    end

    return wModel
end

return OfficeBuilder
