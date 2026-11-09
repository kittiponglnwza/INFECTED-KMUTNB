--[[
    StairBuilder.lua
    สร้างบันไดในอาคารแบบ U (ชานพักกลาง) โปร่งสบายตา ไม่ทึบอึดอัด
      - ปากบันไดหันหน้าเข้าหาลิฟต์ฝั่งตรงข้ามโถงทางเข้าออก
      - ช่วงที่ 1 เริ่มขึ้นจากเลนซ้ายมือ (เมื่อยืนหน้าปากบันไดมองเข้าไป)
      - ราวกันตกกั้นกลางเป็นราวเตี้ย (สูง 3.4 studs) มองทะลุเห็นโถงบันไดโปร่งโล่ง
]]

local PartBuilder = require(script.Parent.PartBuilder)

local StairBuilder = {}

StairBuilder.HALF_X = 19      -- ความยาวคอร์ 38 (แนว X: ±30..±68)
StairBuilder.HALF_Z = 17      -- ความกว้างคอร์ 34 (แนว Z: ±86..±120)
StairBuilder.WALL = 2
StairBuilder.ENTRY_DEPTH = 6  -- โถงหน้าบันได
StairBuilder.FLIGHT_RUN = 22  -- ความยาวช่วงบันได
StairBuilder.LANDING_DEPTH = 8
StairBuilder.STEPS_PER_FLIGHT = 10
StairBuilder.DIVIDER = 1.0

local STEP_COLOR = Color3.fromRGB(210, 206, 198)
local NOSE_COLOR = Color3.fromRGB(240, 180, 20)
local WALL_COLOR = Color3.fromRGB(242, 239, 233)
local RAIL_COLOR = Color3.fromRGB(95, 102, 110)

function StairBuilder.geometry(def)
    local e = def.entranceDir
    local cx, cz = def.centerX, def.centerZ
    local innerHalfZ = StairBuilder.HALF_Z - StairBuilder.WALL      -- 15
    local laneOffset = StairBuilder.DIVIDER / 2 + (innerHalfZ - StairBuilder.DIVIDER / 2) / 2
    local laneWidth = innerHalfZ - StairBuilder.DIVIDER / 2

    local leftSign = e
    local flight1Sign = (def.startSide == "right") and -leftSign or leftSign

    local g = {
        e = e, cx = cx, cz = cz,
        innerHalfZ = innerHalfZ,
        laneWidth = laneWidth,
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

function StairBuilder.buildEnclosure(parent, def, baseY, height)
    local g = StairBuilder.geometry(def)
    local W = StairBuilder.WALL
    local farX = g.cx - g.e * (StairBuilder.HALF_X - W / 2)
    PartBuilder.makePart(parent, "StairWall_Far", Vector3.new(W, height, StairBuilder.HALF_Z * 2),
        CFrame.new(farX, baseY + height / 2, g.cz), WALL_COLOR, Enum.Material.Concrete)
    for _, s in ipairs({ -1, 1 }) do
        PartBuilder.makePart(parent, "StairWall_Side" .. (s > 0 and "P" or "N"), Vector3.new(StairBuilder.HALF_X * 2, height, W),
            CFrame.new(g.cx, baseY + height / 2, g.cz + s * (StairBuilder.HALF_Z - W / 2)), WALL_COLOR, Enum.Material.Concrete)
    end
end

function StairBuilder.buildUStair(parent, def, baseY, rise)
    local model = Instance.new("Model")
    model.Name = def.name or "UStair"
    model.Parent = parent

    local g = StairBuilder.geometry(def)
    local N = StairBuilder.STEPS_PER_FLIGHT
    local r = rise / (2 * N)
    local run = StairBuilder.FLIGHT_RUN / N
    local landingTop = baseY + N * r

    -- ช่วงที่ 1: เลนซ้าย เดินขึ้นไปหาชานพัก
    for i = 1, N do
        local t0 = g.tFlightStart + (i - 1) * run
        local top = baseY + i * r
        local xMid = g.x(t0 + run / 2)
        PartBuilder.makePart(model, "Flight1_Step" .. i, Vector3.new(run, top - baseY + 0.02, g.laneWidth),
            CFrame.new(xMid, (baseY + top) / 2, g.flight1Z), STEP_COLOR, Enum.Material.Concrete)
        PartBuilder.makePart(model, "Flight1_Nose" .. i, Vector3.new(0.45, 0.06, g.laneWidth - 1),
            CFrame.new(g.x(t0 + 0.25), top + 0.03, g.flight1Z), NOSE_COLOR, Enum.Material.SmoothPlastic, { CanCollide = false })
    end

    -- ชานพักกลาง (กลับตัว 180°)
    local lx = g.x((g.tLanding + g.tEnd) / 2)
    PartBuilder.makePart(model, "MidLanding", Vector3.new(StairBuilder.LANDING_DEPTH, landingTop - baseY, g.innerHalfZ * 2),
        CFrame.new(lx, (baseY + landingTop) / 2, g.cz), STEP_COLOR, Enum.Material.Concrete)

    -- ช่วงที่ 2: เลนขวาย้อนกลับมาออกปากบันไดชั้นถัดไป
    for j = 1, N do
        local tFar = g.tLanding - (j - 1) * run
        local top = landingTop + j * r
        local xMid = g.x(tFar - run / 2)
        PartBuilder.makePart(model, "Flight2_Step" .. j, Vector3.new(run, top - baseY + 0.02, g.laneWidth),
            CFrame.new(xMid, (baseY + top) / 2, g.flight2Z), STEP_COLOR, Enum.Material.Concrete)
        PartBuilder.makePart(model, "Flight2_Nose" .. j, Vector3.new(0.45, 0.06, g.laneWidth - 1),
            CFrame.new(g.x(tFar - 0.25), top + 0.03, g.flight2Z), NOSE_COLOR, Enum.Material.SmoothPlastic, { CanCollide = false })
    end

    -- ราวกันตกกั้นกลางแบบโปร่ง (ไม่ก่อทึบชนเพดาน เพื่อไม่ให้บันไดดูแคบอึดอัด)
    local x1, x2 = g.x(g.tFlightStart), g.x(g.tLanding)
    PartBuilder.makePart(model, "CenterBalustrade_Low", Vector3.new(math.abs(x2 - x1), rise + 3.4, StairBuilder.DIVIDER),
        CFrame.new((x1 + x2) / 2, baseY + (rise + 3.4) / 2, g.cz), RAIL_COLOR, Enum.Material.Metal)

    -- ราวกันตกชั้นบน กั้นช่องเหนือช่วงที่ 1
    PartBuilder.makePart(model, "TopGuardRail", Vector3.new(0.6, 3.4, g.laneWidth),
        CFrame.new(g.x(g.tFlightStart) + g.e * 0.3, baseY + rise + 1.7, g.flight1Z), RAIL_COLOR, Enum.Material.Metal)

    -- ป้ายลูกศรบนพื้นบอกจุดเริ่มขึ้น
    PartBuilder.makeSign(model, "UpArrow", "▲ ขึ้น UP", Vector3.new(5, 0.1, g.laneWidth - 3),
        Vector3.new(g.x(g.tFlightStart / 2), baseY + 0.1, g.flight1Z), Enum.NormalId.Top,
        Color3.fromRGB(20, 120, 50), Color3.fromRGB(255, 255, 255))

    return model, g
end

return StairBuilder
