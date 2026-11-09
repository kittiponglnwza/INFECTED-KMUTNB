--[[
    StairBuilder.lua
    สร้างบันไดในอาคารแบบ U (ชานพักกลาง) ให้ปากบันไดหันหน้าเข้าหาลิฟต์

    ผังบันได (มองจากด้านบน, ตัวอย่างบันไดหน้าตึก ปากบันไดหัน +X เข้าหาลิฟต์):

        ผนังข้างนอก (+Z)
        ┌──────────────────────────────┬────────┐
        │ ชาน │ ◀◀◀ ช่วงที่ 1 ขึ้น ◀◀◀ │ ← เริ่ม │   ← เลนซ้ายมือ (เมื่อเดินเข้าไป)
        │ พัก │═══════ผนังกั้นกลาง═══════│  โถง   │ ◀── ปากบันได ── ลิฟต์
        │ กลาง│ ▶▶▶ ช่วงที่ 2 ขึ้น ▶▶▶ │ → ถึง ชั้น2│   ← เลนขวามือ
        └──────────────────────────────┴────────┘
        ผนังข้างใน (-Z)

    - เดินเข้าปากบันได → ขึ้นช่วงที่ 1 จากเลนซ้าย (startSide = "left")
    - ถึงชานพักกลาง กลับตัว 180° → ขึ้นช่วงที่ 2 ย้อนกลับมาที่ปากบันได บนชั้นถัดไป
    - ขั้นบันไดเป็นก้อนทึบถึงพื้น ไม่ลอย ไม่ทะลุ
]]

local PartBuilder = require(script.Parent.PartBuilder)

local StairBuilder = {}

-- ขนาดคอร์บันได
StairBuilder.HALF_X = 23      -- ความยาวคอร์ 46 (แนว X)
StairBuilder.HALF_Z = 18      -- ความกว้างคอร์ 36 (แนว Z)
StairBuilder.WALL = 2
StairBuilder.ENTRY_DEPTH = 8  -- โถงหน้าบันได
StairBuilder.FLIGHT_RUN = 28  -- ความยาวช่วงบันไดแต่ละช่วง
StairBuilder.LANDING_DEPTH = 8
StairBuilder.STEPS_PER_FLIGHT = 10
StairBuilder.DIVIDER = 1

local STEP_COLOR = Color3.fromRGB(205, 200, 192)
local NOSE_COLOR = Color3.fromRGB(240, 180, 20)
local WALL_COLOR = Color3.fromRGB(242, 239, 233)
local RAIL_COLOR = Color3.fromRGB(120, 125, 130)

-- คำนวณตำแหน่งต่างๆ ของบันไดจากค่าใน Layout
function StairBuilder.geometry(def)
    local e = def.entranceDir
    local cx, cz = def.centerX, def.centerZ
    local innerHalfZ = StairBuilder.HALF_Z - StairBuilder.WALL      -- 16
    local laneOffset = StairBuilder.DIVIDER / 2 + (innerHalfZ - StairBuilder.DIVIDER / 2) / 2
    local laneWidth = innerHalfZ - StairBuilder.DIVIDER / 2

    -- เดินเข้าบันไดไปทิศ -e  →  ซ้ายมือคือ Z ทิศ e
    local leftSign = e
    local flight1Sign = (def.startSide == "right") and -leftSign or leftSign

    local g = {
        e = e, cx = cx, cz = cz,
        innerHalfZ = innerHalfZ,
        laneWidth = laneWidth,
        flight1Z = cz + flight1Sign * laneOffset,
        flight2Z = cz - flight1Sign * laneOffset,
    }
    -- t = ระยะลึกจากปากบันได (0) เข้าไปถึงผนังด้านใน
    function g.x(t)
        return cx + e * (StairBuilder.HALF_X - t)
    end
    g.tFlightStart = StairBuilder.ENTRY_DEPTH
    g.tLanding = StairBuilder.ENTRY_DEPTH + StairBuilder.FLIGHT_RUN
    g.tEnd = g.tLanding + StairBuilder.LANDING_DEPTH
    return g
end

-- ช่องที่ต้องเจาะบนพื้นชั้นบน (เหนือช่วงบันไดและชานพัก)
function StairBuilder.slabHole(def)
    local g = StairBuilder.geometry(def)
    local x1, x2 = g.x(g.tFlightStart), g.x(g.tEnd)
    return {
        minX = math.min(x1, x2), maxX = math.max(x1, x2),
        minZ = g.cz - g.innerHalfZ, maxZ = g.cz + g.innerHalfZ,
    }
end

-- ผนังล้อมคอร์บันได 3 ด้าน (เปิดเฉพาะด้านปากบันไดที่หันหาลิฟต์)
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

-- สร้างบันได U จาก baseY ขึ้นไป rise studs
function StairBuilder.buildUStair(parent, def, baseY, rise)
    local model = Instance.new("Model")
    model.Name = def.name or "UStair"
    model.Parent = parent

    local g = StairBuilder.geometry(def)
    local N = StairBuilder.STEPS_PER_FLIGHT
    local r = rise / (2 * N)
    local run = StairBuilder.FLIGHT_RUN / N
    local landingTop = baseY + N * r

    -- ช่วงที่ 1: เลนเริ่มต้น เดินลึกเข้าไป
    for i = 1, N do
        local t0 = g.tFlightStart + (i - 1) * run
        local top = baseY + i * r
        local xMid = g.x(t0 + run / 2)
        PartBuilder.makePart(model, "Flight1_Step" .. i, Vector3.new(run, top - baseY + 0.02, g.laneWidth),
            CFrame.new(xMid, (baseY + top) / 2, g.flight1Z), STEP_COLOR, Enum.Material.Concrete)
        -- แถบกันลื่นสีเหลืองที่จมูกบันได
        PartBuilder.makePart(model, "Flight1_Nose" .. i, Vector3.new(0.5, 0.06, g.laneWidth - 1),
            CFrame.new(g.x(t0 + 0.3), top + 0.03, g.flight1Z), NOSE_COLOR, Enum.Material.SmoothPlastic, { CanCollide = false })
    end

    -- ชานพักกลาง (กลับตัว 180°)
    local lx = g.x((g.tLanding + g.tEnd) / 2)
    PartBuilder.makePart(model, "MidLanding", Vector3.new(StairBuilder.LANDING_DEPTH, landingTop - baseY, g.innerHalfZ * 2),
        CFrame.new(lx, (baseY + landingTop) / 2, g.cz), STEP_COLOR, Enum.Material.Concrete)

    -- ช่วงที่ 2: เลนฝั่งตรงข้าม ย้อนกลับมาทางปากบันได
    for j = 1, N do
        local tFar = g.tLanding - (j - 1) * run
        local top = landingTop + j * r
        local xMid = g.x(tFar - run / 2)
        PartBuilder.makePart(model, "Flight2_Step" .. j, Vector3.new(run, top - baseY + 0.02, g.laneWidth),
            CFrame.new(xMid, (baseY + top) / 2, g.flight2Z), STEP_COLOR, Enum.Material.Concrete)
        PartBuilder.makePart(model, "Flight2_Nose" .. j, Vector3.new(0.5, 0.06, g.laneWidth - 1),
            CFrame.new(g.x(tFar - 0.3), top + 0.03, g.flight2Z), NOSE_COLOR, Enum.Material.SmoothPlastic, { CanCollide = false })
    end

    -- ผนังกั้นกลางระหว่างสองช่วง (สูงเลยพื้นชั้นบนเป็นราวกันตก)
    local x1, x2 = g.x(g.tFlightStart), g.x(g.tLanding)
    local divTop = baseY + rise + 3.5
    PartBuilder.makePart(model, "CenterDivider", Vector3.new(math.abs(x2 - x1), divTop - baseY, StairBuilder.DIVIDER),
        CFrame.new((x1 + x2) / 2, (baseY + divTop) / 2, g.cz), WALL_COLOR, Enum.Material.Concrete)

    -- ราวกันตกชั้นบน กั้นช่องเหนือช่วงที่ 1 (ช่วงที่ 2 เปิดเป็นทางขึ้นถึงชั้นบน)
    PartBuilder.makePart(model, "TopGuardRail", Vector3.new(0.6, 3.5, g.laneWidth),
        CFrame.new(g.x(g.tFlightStart) + g.e * 0.3, baseY + rise + 1.75, g.flight1Z), RAIL_COLOR, Enum.Material.Metal)

    -- ป้ายลูกศรบนพื้นบอกจุดเริ่มขึ้น
    PartBuilder.makeSign(model, "UpArrow", "▲ ขึ้น UP", Vector3.new(6, 0.1, g.laneWidth - 3),
        Vector3.new(g.x(g.tFlightStart / 2), baseY + 0.1, g.flight1Z), Enum.NormalId.Top,
        Color3.fromRGB(20, 120, 50), Color3.fromRGB(255, 255, 255))

    return model, g
end

return StairBuilder
