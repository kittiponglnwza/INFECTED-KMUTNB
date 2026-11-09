--[[
    StairBuilder.lua
    สร้างบันไดคอนกรีตเสริมเหล็กในอาคารแบบ U-Shape (ชานพักกลาง) สมจริงระดับสถาปัตยกรรมจริง:
      - มีท้องบันไดคอนกรีตแนวลาดเอียง (Sloped Concrete Waist Slab / Stringer) รับใต้ขั้นบันไดตลอดแนว ไม่ลอยเป็นก้อนหยัก
      - ขั้นบันไดปูกระเบื้องแกรนิตโต้พร้อมจมูกบันไดกันลื่นสีเหลือง-ดำ
      - ราวบันไดสแตนเลสลาดเอียงตามองศาขั้นบันไดจริง (True Sloped Handrails) พร้อมเสาลูกกรงแนวตั้งรับทุกช่วง
      - ชานพักหน้าบันไดกว้าง 8 studs และชานพักกลางกว้าง 8 studs เดินเลี้ยวขึ้น-ลงชั้น 1 -> 2 -> 3 ได้ลื่นไหลหัวไม่ชน
      - ป้ายบอกเลขชั้น (FL.1 / FL.2 / FL.3) และป้ายไฟทางหนีไฟ EXIT ภายในโถงบันได
]]

local PartBuilder = require(script.Parent.PartBuilder)

local StairBuilder = {}

StairBuilder.HALF_X = 19          -- ความยาวคอร์ 38 (แนว X: ±30..±68)
StairBuilder.HALF_Z = 17          -- ความกว้างคอร์ 34 (แนว Z: ±86..±120)
StairBuilder.WALL = 2             -- ความหนาผนังปล่องบันได
StairBuilder.ENTRY_DEPTH = 8      -- โถงชานพักหน้าปากบันไดกว้าง 8 studs เดินเลี้ยวสบาย
StairBuilder.FLIGHT_RUN = 20      -- ความยาวช่วงบันได 20 studs
StairBuilder.LANDING_DEPTH = 8    -- ชานพักกลางกลับตัวกว้าง 8 studs
StairBuilder.STEPS_PER_FLIGHT = 10
StairBuilder.DIVIDER = 1.2        -- ช่องว่างราวบันไดกั้นกลาง

local STEP_COLOR = Color3.fromRGB(220, 216, 208)
local STRINGER_COLOR = Color3.fromRGB(195, 192, 185)
local NOSE_COLOR = Color3.fromRGB(240, 180, 20)
local WALL_COLOR = Color3.fromRGB(240, 237, 230)
local RAIL_STEEL = Color3.fromRGB(185, 192, 200)
local POST_DARK = Color3.fromRGB(70, 76, 84)

function StairBuilder.geometry(def)
    local e = def.entranceDir
    local cx, cz = def.centerX, def.centerZ
    local innerHalfZ = StairBuilder.HALF_Z - StairBuilder.WALL      -- 15
    local laneOffset = StairBuilder.DIVIDER / 2 + (innerHalfZ - StairBuilder.DIVIDER / 2) / 2
    local laneWidth = innerHalfZ - StairBuilder.DIVIDER / 2         -- 14.4

    local leftSign = e
    local flight1Sign = (def.startSide == "right") and -leftSign or leftSign

    local g = {
        e = e, cx = cx, cz = cz,
        innerHalfZ = innerHalfZ,
        laneWidth = laneWidth,
        flight1Sign = flight1Sign,
        flight1Z = cz + flight1Sign * laneOffset,
        flight2Z = cz - flight1Sign * laneOffset,
    }
    function g.x(t)
        return cx + e * (StairBuilder.HALF_X - t)
    end
    g.tFlightStart = StairBuilder.ENTRY_DEPTH
    g.tLanding = StairBuilder.ENTRY_DEPTH + StairBuilder.FLIGHT_RUN
    g.tEnd = g.tLanding + StairBuilder.LANDING_DEPTH
    return g
end

function StairBuilder.slabHole(def)
    local g = StairBuilder.geometry(def)
    local x1, x2 = g.x(g.tFlightStart), g.x(g.tEnd)
    return {
        minX = math.min(x1, x2), maxX = math.max(x1, x2),
        minZ = g.cz - g.innerHalfZ, maxZ = g.cz + g.innerHalfZ,
    }
end

function StairBuilder.buildEnclosure(parent, def, baseY, height, floorNum)
    local g = StairBuilder.geometry(def)
    local W = StairBuilder.WALL
    local farX = g.cx - g.e * (StairBuilder.HALF_X - W / 2)
    local openX = g.cx + g.e * (StairBuilder.HALF_X - W / 2)

    -- ผนังด้านในสุดของชานพักบันได และผนังขนาบซ้าย-ขวา
    PartBuilder.makePart(parent, "StairWall_Far", Vector3.new(W, height, StairBuilder.HALF_Z * 2),
        CFrame.new(farX, baseY + height / 2, g.cz), WALL_COLOR, Enum.Material.Concrete)
    for _, s in ipairs({ -1, 1 }) do
        PartBuilder.makePart(parent, "StairWall_Side" .. (s > 0 and "P" or "N"), Vector3.new(StairBuilder.HALF_X * 2, height, W),
            CFrame.new(g.cx, baseY + height / 2, g.cz + s * (StairBuilder.HALF_Z - W / 2)), WALL_COLOR, Enum.Material.Concrete)
    end

    -- เสาขนาบปากทางเข้าโถงบันไดซ้าย-ขวา + คานบนสูงโปร่ง (สูง 15 studs ไม่เตี้ยอึดอัด)
    local portalH = math.min(15.5, height - 3.5)
    local headerH = height - portalH
    PartBuilder.makePart(parent, "EntranceHeader", Vector3.new(W, headerH, StairBuilder.HALF_Z * 2),
        CFrame.new(openX, baseY + portalH + headerH / 2, g.cz), WALL_COLOR, Enum.Material.Concrete)
    for _, s in ipairs({ -1, 1 }) do
        PartBuilder.makePart(parent, "EntranceJamb_" .. s, Vector3.new(W + 0.4, portalH, 2.2),
            CFrame.new(openX, baseY + portalH / 2, g.cz + s * (StairBuilder.HALF_Z - W - 0.9)),
            Color3.fromRGB(215, 212, 205), Enum.Material.Concrete)
    end

    -- ป้ายบอกเลขชั้นขนาดใหญ่ด้านในโถงบันได และป้ายไฟทางหนีไฟ EXIT เหนือปากทางเข้า
    local flLabel = floorNum and string.format("ชั้น %d\nFLOOR %d", floorNum, floorNum) or "บันได\nSTAIRS"
    PartBuilder.makeSign(parent, "FloorLevelPlaque", flLabel,
        Vector3.new(0.3, 3.8, 9.0),
        Vector3.new(farX + g.e * (W / 2 + 0.2), baseY + height * 0.5 + 3.0, g.cz),
        g.e > 0 and Enum.NormalId.Right or Enum.NormalId.Left,
        Color3.fromRGB(128, 28, 38), Color3.fromRGB(255, 255, 255))

    PartBuilder.makeSign(parent, "ExitBanner", "🏃 ทางหนีไฟ / บันได (STAIRS)",
        Vector3.new(0.35, 2.2, 13.0),
        Vector3.new(openX + g.e * (W / 2 + 0.2), baseY + portalH + 1.4, g.cz),
        g.e > 0 and Enum.NormalId.Right or Enum.NormalId.Left,
        Color3.fromRGB(20, 125, 55), Color3.fromRGB(255, 255, 255))
end

function StairBuilder.buildUStair(parent, def, baseY, rise)
    local model = Instance.new("Model")
    model.Name = def.name or "UStair"
    model.Parent = parent

    local g = StairBuilder.geometry(def)
    local N = StairBuilder.STEPS_PER_FLIGHT
    local halfRise = rise / 2
    local r = halfRise / N
    local run = StairBuilder.FLIGHT_RUN / N
    local landingTop = baseY + halfRise
    local stepThick = r + 0.6

    local slopeLen = math.sqrt(StairBuilder.FLIGHT_RUN ^ 2 + halfRise ^ 2)
    local slopeAngle = math.atan2(halfRise, StairBuilder.FLIGHT_RUN)

    ------------------------------------------------------------------
    -- 1. ท้องบันไดคอนกรีตแนวลาดเอียง (Sloped Concrete Waist Slab / Stringer)
    ------------------------------------------------------------------
    local f1MidX = g.x(g.tFlightStart + StairBuilder.FLIGHT_RUN / 2)
    local f1MidY = baseY + halfRise / 2 - 0.9
    PartBuilder.makePart(model, "Flight1_WaistSlab", Vector3.new(slopeLen + 0.8, 1.3, g.laneWidth),
        CFrame.new(f1MidX, f1MidY, g.flight1Z) * CFrame.Angles(0, 0, -g.e * slopeAngle),
        STRINGER_COLOR, Enum.Material.Concrete)

    local f2MidX = g.x(g.tLanding - StairBuilder.FLIGHT_RUN / 2)
    local f2MidY = landingTop + halfRise / 2 - 0.9
    PartBuilder.makePart(model, "Flight2_WaistSlab", Vector3.new(slopeLen + 0.8, 1.3, g.laneWidth),
        CFrame.new(f2MidX, f2MidY, g.flight2Z) * CFrame.Angles(0, 0, g.e * slopeAngle),
        STRINGER_COLOR, Enum.Material.Concrete)

    ------------------------------------------------------------------
    -- 2. ขั้นบันไดช่วงที่ 1 (เลนซ้าย เดินขึ้นไปหาชานพักกลาง)
    ------------------------------------------------------------------
    for i = 1, N do
        local t0 = g.tFlightStart + (i - 1) * run
        local top = baseY + i * r
        local h = math.min(stepThick, top - baseY)
        local xMid = g.x(t0 + run / 2)
        PartBuilder.makePart(model, "Flight1_Step" .. i, Vector3.new(run + 0.08, h, g.laneWidth),
            CFrame.new(xMid, top - h / 2, g.flight1Z), STEP_COLOR, Enum.Material.Concrete)
        PartBuilder.makePart(model, "Flight1_Nose" .. i, Vector3.new(0.35, 0.06, g.laneWidth - 0.6),
            CFrame.new(g.x(t0 + 0.18), top + 0.03, g.flight1Z), NOSE_COLOR, Enum.Material.SmoothPlastic, { CanCollide = false })
    end

    ------------------------------------------------------------------
    -- 3. ชานพักกลาง (กลับตัว 180°) + คานคอนกรีตรับชานพัก
    ------------------------------------------------------------------
    local lx = g.x((g.tLanding + g.tEnd) / 2)
    local landH = 1.6
    PartBuilder.makePart(model, "MidLanding", Vector3.new(StairBuilder.LANDING_DEPTH + 0.4, landH, g.innerHalfZ * 2),
        CFrame.new(lx, landingTop - landH / 2, g.cz), STEP_COLOR, Enum.Material.Concrete)
    PartBuilder.makePart(model, "MidLandingBeam", Vector3.new(1.6, 2.2, g.innerHalfZ * 2),
        CFrame.new(g.x(g.tLanding), landingTop - 1.4, g.cz), STRINGER_COLOR, Enum.Material.Concrete)

    ------------------------------------------------------------------
    -- 4. ขั้นบันไดช่วงที่ 2 (เลนขวา ย้อนกลับขึ้นไปออกชั้นถัดไป)
    ------------------------------------------------------------------
    for j = 1, N do
        local tFar = g.tLanding - (j - 1) * run
        local top = landingTop + j * r
        local h = stepThick
        local xMid = g.x(tFar - run / 2)
        PartBuilder.makePart(model, "Flight2_Step" .. j, Vector3.new(run + 0.08, h, g.laneWidth),
            CFrame.new(xMid, top - h / 2, g.flight2Z), STEP_COLOR, Enum.Material.Concrete)
        PartBuilder.makePart(model, "Flight2_Nose" .. j, Vector3.new(0.35, 0.06, g.laneWidth - 0.6),
            CFrame.new(g.x(tFar - 0.18), top + 0.03, g.flight2Z), NOSE_COLOR, Enum.Material.SmoothPlastic, { CanCollide = false })
    end

    ------------------------------------------------------------------
    -- 5. ราวบันไดสแตนเลสลาดเอียงตามขั้นบันไดจริง (True Sloped Handrails & Balusters)
    ------------------------------------------------------------------
    local railH = 3.4
    local innerZ1 = g.cz + g.flight1Sign * (StairBuilder.DIVIDER / 2 + 0.15)
    local innerZ2 = g.cz - g.flight1Sign * (StairBuilder.DIVIDER / 2 + 0.15)

    -- เสาลูกกรงแนวตั้งรับราวบันไดช่วงที่ 1 และช่วงที่ 2
    for _, stepIdx in ipairs({ 1, 4, 7, 10 }) do
        local t1 = g.tFlightStart + (stepIdx - 0.5) * run
        local y1 = baseY + stepIdx * r
        PartBuilder.makePart(model, "F1_Post_" .. stepIdx, Vector3.new(0.25, railH, 0.25),
            CFrame.new(g.x(t1), y1 + railH / 2, innerZ1), POST_DARK, Enum.Material.Metal)

        local t2 = g.tLanding - (stepIdx - 0.5) * run
        local y2 = landingTop + stepIdx * r
        PartBuilder.makePart(model, "F2_Post_" .. stepIdx, Vector3.new(0.25, railH, 0.25),
            CFrame.new(g.x(t2), y2 + railH / 2, innerZ2), POST_DARK, Enum.Material.Metal)
    end

    -- ราวสแตนเลสลาดเอียงช่วงที่ 1 (Top Rail & Mid Rail)
    PartBuilder.makePart(model, "Flight1_Handrail", Vector3.new(slopeLen + 0.6, 0.28, 0.28),
        CFrame.new(f1MidX, baseY + halfRise / 2 + railH, innerZ1) * CFrame.Angles(0, 0, -g.e * slopeAngle),
        RAIL_STEEL, Enum.Material.Metal)
    PartBuilder.makePart(model, "Flight1_MidRail", Vector3.new(slopeLen + 0.6, 0.16, 0.16),
        CFrame.new(f1MidX, baseY + halfRise / 2 + railH * 0.5, innerZ1) * CFrame.Angles(0, 0, -g.e * slopeAngle),
        POST_DARK, Enum.Material.Metal)

    -- ราวสแตนเลสลาดเอียงช่วงที่ 2 (Top Rail & Mid Rail)
    PartBuilder.makePart(model, "Flight2_Handrail", Vector3.new(slopeLen + 0.6, 0.28, 0.28),
        CFrame.new(f2MidX, landingTop + halfRise / 2 + railH, innerZ2) * CFrame.Angles(0, 0, g.e * slopeAngle),
        RAIL_STEEL, Enum.Material.Metal)
    PartBuilder.makePart(model, "Flight2_MidRail", Vector3.new(slopeLen + 0.6, 0.16, 0.16),
        CFrame.new(f2MidX, landingTop + halfRise / 2 + railH * 0.5, innerZ2) * CFrame.Angles(0, 0, g.e * slopeAngle),
        POST_DARK, Enum.Material.Metal)

    -- ราวเชื่อมตรงชานพักกลาง
    PartBuilder.makePart(model, "LandingTurnRail", Vector3.new(0.28, 0.28, math.abs(innerZ1 - innerZ2) + 0.3),
        CFrame.new(g.x(g.tLanding), landingTop + railH, g.cz), RAIL_STEEL, Enum.Material.Metal)

    -- ราวกันตกชั้นบน กั้นขอบช่องพื้นเหนือช่วงที่ 1
    PartBuilder.makePart(model, "UpperFloorGuardRail", Vector3.new(0.4, railH, g.laneWidth - 0.5),
        CFrame.new(g.x(g.tFlightStart) + g.e * 0.2, baseY + rise + railH / 2, g.flight1Z), POST_DARK, Enum.Material.Metal)
    PartBuilder.makePart(model, "UpperFloorTopBar", Vector3.new(0.5, 0.3, g.laneWidth - 0.4),
        CFrame.new(g.x(g.tFlightStart) + g.e * 0.2, baseY + rise + railH, g.flight1Z), RAIL_STEEL, Enum.Material.Metal)

    -- ป้ายลูกศรบนพื้นบอกจุดเริ่มเดินขึ้น
    PartBuilder.makeSign(model, "UpArrow", "▲ ขึ้น UP", Vector3.new(4.5, 0.06, g.laneWidth - 4),
        Vector3.new(g.x(g.tFlightStart / 2), baseY + 0.08, g.flight1Z), Enum.NormalId.Top,
        Color3.fromRGB(20, 120, 50), Color3.fromRGB(255, 255, 255))

    return model, g
end

return StairBuilder
