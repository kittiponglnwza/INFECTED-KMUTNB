--[[
    KMUTNBArms.lua
    โมดูลสร้างแขนและมือตัวละคร มจพ. (KMUTNB Tactical Student Arms)
    - แขนเสื้อเชิ้ตขาวนักศึกษาพับแขนพร้อมแถบข้อมือสีแดงประดู่ มจพ. และนาฬิกาข้อมือซ้าย
    - ท่อนแขนทรงกระบอกต่อเนื่องไร้รอยแยก เชื่อมจากแขนเสื้อถึงข้อมือพอดี
    - ถุงมือครึ่งนิ้ว (Tactical Half-Finger Gloves) พร้อมนิ้วโป้งและนิ้วกำด้าม/ประกับมือ
]]

local KMUTNBArms = {}

local SHIRT_COLOR   = Color3.fromRGB(244, 246, 250)
local CUFF_COLOR    = Color3.fromRGB(220, 224, 232)
local KMUTNB_ACCENT = Color3.fromRGB(138, 30, 42)
local SKIN_COLOR    = Color3.fromRGB(224, 180, 148)
local GLOVE_DARK    = Color3.fromRGB(34, 38, 45)
local GLOVE_PAD     = Color3.fromRGB(55, 60, 68)
local WATCH_CASE    = Color3.fromRGB(28, 32, 38)
local WATCH_DIAL    = Color3.fromRGB(0, 210, 190)

function KMUTNBArms.build(parentModel, isPistolOrConfig)
    local isUnarmed = false
    local isPistol = false
    local supportZ = -1.20
    if isPistolOrConfig == "Unarmed" then
        isUnarmed = true
    elseif type(isPistolOrConfig) == "boolean" then
        isPistol = isPistolOrConfig
    elseif type(isPistolOrConfig) == "table" then
        local wType = isPistolOrConfig.Type
        local wName = (isPistolOrConfig.Name or ""):upper()
        if wType == "Unarmed" then
            isUnarmed = true
        else
            isPistol = (wType == "Pistol" or wType == "Revolver")
            if wType == "SMG" or wName == "BULLDOG" then
                supportZ = -0.88
            elseif wName == "BUCKY" or wName == "JUDGE" then
                supportZ = -1.35
            elseif isPistolOrConfig.IsSniper then
                supportZ = -1.25
            end
        end
    end

    local armParts = {}
    local leftArmParts = {}
    local rightArmParts = {}

    local function addPart(name, size, color, material, relCF, isLeft, shape)
        local p = Instance.new("Part")
        p.Name = name
        p.Shape = shape or Enum.PartType.Block
        p.Size = size
        p.Color = color
        p.Material = material
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.Anchored = true
        p.CastShadow = false
        p.Parent = parentModel

        armParts[p] = relCF
        if isLeft then
            leftArmParts[p] = relCF
        else
            rightArmParts[p] = relCF
        end
        return p
    end

    local function addLimbSegment(name, pStart, pEnd, dia, color, mat, isLeft)
        local delta = pEnd - pStart
        local len = math.max(0.05, delta.Magnitude)
        local mid = (pStart + pEnd) * 0.5
        local cf = CFrame.lookAt(mid, pEnd) * CFrame.Angles(0, math.rad(90), 0)
        return addPart(name, Vector3.new(len, dia, dia), color, mat, cf, isLeft, Enum.PartType.Cylinder)
    end

    if isUnarmed then
        ------------------------------------------------------------------
        -- 0. มือเปล่า (Unarmed // Fast Sprint & Melee Shove Pose)
        ------------------------------------------------------------------
        local rShoulder = Vector3.new(0.86, -1.04, 1.38)
        local rElbow    = Vector3.new(0.76, -0.82, 0.58)
        local rWrist    = Vector3.new(0.46, -0.44, -0.22)
        local rPalmPos  = Vector3.new(0.40, -0.40, -0.42)

        addLimbSegment("RightSleeve", rShoulder, rElbow, 0.42, SHIRT_COLOR, Enum.Material.Fabric, false)
        addLimbSegment("RightCuff", rElbow + (rShoulder - rElbow).Unit * 0.04, rElbow - (rWrist - rElbow).Unit * 0.12, 0.45, CUFF_COLOR, Enum.Material.Fabric, false)
        addLimbSegment("RightCuffStripe", rElbow - (rWrist - rElbow).Unit * 0.11, rElbow - (rWrist - rElbow).Unit * 0.16, 0.44, KMUTNB_ACCENT, Enum.Material.SmoothPlastic, false)
        addLimbSegment("RightForearm", rElbow - (rWrist - rElbow).Unit * 0.08, rWrist, 0.30, SKIN_COLOR, Enum.Material.SmoothPlastic, false)

        local rHandCF = CFrame.new(rPalmPos) * CFrame.Angles(math.rad(-8), math.rad(16), math.rad(14))
        addPart("RightGlovePalm", Vector3.new(0.28, 0.21, 0.31), GLOVE_DARK, Enum.Material.Fabric, rHandCF, false)
        addPart("RightKnucklePad", Vector3.new(0.29, 0.08, 0.17), GLOVE_PAD, Enum.Material.SmoothPlastic, rHandCF * CFrame.new(0, 0.08, -0.04), false)
        addPart("RightFingers", Vector3.new(0.24, 0.14, 0.22), SKIN_COLOR, Enum.Material.SmoothPlastic, rHandCF * CFrame.new(-0.02, -0.05, -0.15) * CFrame.Angles(math.rad(38), 0, 0), false)
        addPart("RightThumb", Vector3.new(0.09, 0.10, 0.22), SKIN_COLOR, Enum.Material.SmoothPlastic, rHandCF * CFrame.new(-0.15, 0.06, -0.08) * CFrame.Angles(math.rad(15), math.rad(-14), 0), false)

        local lShoulder = Vector3.new(-0.86, -1.04, 1.38)
        local lElbow    = Vector3.new(-0.76, -0.82, 0.58)
        local lWrist    = Vector3.new(-0.46, -0.44, -0.22)
        local lPalmPos  = Vector3.new(-0.40, -0.40, -0.42)

        addLimbSegment("LeftSleeve", lShoulder, lElbow, 0.42, SHIRT_COLOR, Enum.Material.Fabric, true)
        addLimbSegment("LeftCuff", lElbow + (lShoulder - lElbow).Unit * 0.04, lElbow - (lWrist - lElbow).Unit * 0.12, 0.45, CUFF_COLOR, Enum.Material.Fabric, true)
        addLimbSegment("LeftCuffStripe", lElbow - (lWrist - lElbow).Unit * 0.11, lElbow - (lWrist - lElbow).Unit * 0.16, 0.44, KMUTNB_ACCENT, Enum.Material.SmoothPlastic, true)
        addLimbSegment("LeftForearm", lElbow - (lWrist - lElbow).Unit * 0.08, lWrist, 0.29, SKIN_COLOR, Enum.Material.SmoothPlastic, true)

        local watchCF = CFrame.lookAt(lWrist + (lElbow - lWrist).Unit * 0.15, lWrist)
        addPart("LeftWatchStrap", Vector3.new(0.31, 0.28, 0.12), WATCH_CASE, Enum.Material.SmoothPlastic, watchCF, true)
        addPart("LeftWatchFace", Vector3.new(0.15, 0.05, 0.13), WATCH_DIAL, Enum.Material.Neon, watchCF * CFrame.new(-0.05, 0.13, 0), true)

        local lHandCF = CFrame.new(lPalmPos) * CFrame.Angles(math.rad(-8), math.rad(-16), math.rad(-14))
        addPart("LeftGlovePalm", Vector3.new(0.28, 0.21, 0.31), GLOVE_DARK, Enum.Material.Fabric, lHandCF, true)
        addPart("LeftKnucklePad", Vector3.new(0.29, 0.08, 0.17), GLOVE_PAD, Enum.Material.SmoothPlastic, lHandCF * CFrame.new(0, 0.08, -0.04), true)
        addPart("LeftFingers", Vector3.new(0.24, 0.14, 0.22), SKIN_COLOR, Enum.Material.SmoothPlastic, lHandCF * CFrame.new(0.02, -0.05, -0.15) * CFrame.Angles(math.rad(38), 0, 0), true)
        addPart("LeftThumb", Vector3.new(0.09, 0.10, 0.22), SKIN_COLOR, Enum.Material.SmoothPlastic, lHandCF * CFrame.new(0.15, 0.06, -0.08) * CFrame.Angles(math.rad(15), math.rad(14), 0), true)

        return armParts, leftArmParts, rightArmParts
    end

    ------------------------------------------------------------------
    -- 1. แขนขวา (Right Arm - จับด้ามและโกร่งไกปืน)
    ------------------------------------------------------------------
    local rShoulder = Vector3.new(0.84, -1.00, 2.02)
    local rElbow    = Vector3.new(0.62, -0.78, 1.32)
    local rWrist    = isPistol and Vector3.new(0.08, -0.44, 0.48) or Vector3.new(0.08, -0.42, 0.68)
    local rPalmPos  = isPistol and Vector3.new(0.02, -0.44, 0.24) or Vector3.new(0.03, -0.42, 0.44)

    addLimbSegment("RightSleeve", rShoulder, rElbow, 0.42, SHIRT_COLOR, Enum.Material.Fabric, false)
    addLimbSegment("RightCuff", rElbow + (rShoulder - rElbow).Unit * 0.04, rElbow - (rWrist - rElbow).Unit * 0.12, 0.45, CUFF_COLOR, Enum.Material.Fabric, false)
    addLimbSegment("RightCuffStripe", rElbow - (rWrist - rElbow).Unit * 0.11, rElbow - (rWrist - rElbow).Unit * 0.16, 0.44, KMUTNB_ACCENT, Enum.Material.SmoothPlastic, false)
    addLimbSegment("RightForearm", rElbow - (rWrist - rElbow).Unit * 0.08, rWrist, 0.30, SKIN_COLOR, Enum.Material.SmoothPlastic, false)

    -- ถุงมือขวา + สนับมือ + นิ้วมือจับกริป + นิ้วชี้พักโครงไก
    local rHandCF = CFrame.new(rPalmPos) * CFrame.Angles(math.rad(-14), 0, 0)
    addPart("RightGlovePalm", Vector3.new(0.29, 0.22, 0.30), GLOVE_DARK, Enum.Material.Fabric, rHandCF, false)
    addPart("RightKnucklePad", Vector3.new(0.30, 0.08, 0.16), GLOVE_PAD, Enum.Material.SmoothPlastic, rHandCF * CFrame.new(0, 0.09, -0.06), false)
    addPart("RightFingers", Vector3.new(0.24, 0.14, 0.20), SKIN_COLOR, Enum.Material.SmoothPlastic, rHandCF * CFrame.new(-0.04, -0.06, -0.14) * CFrame.Angles(math.rad(35), 0, 0), false)
    addPart("RightThumb", Vector3.new(0.09, 0.10, 0.22), SKIN_COLOR, Enum.Material.SmoothPlastic, rHandCF * CFrame.new(-0.15, 0.07, -0.08) * CFrame.Angles(math.rad(12), math.rad(-16), 0), false)
    addPart("RightTriggerFinger", Vector3.new(0.07, 0.07, 0.24), SKIN_COLOR, Enum.Material.SmoothPlastic, rHandCF * CFrame.new(0.14, 0.06, -0.22) * CFrame.Angles(math.rad(6), math.rad(10), 0), false)

    ------------------------------------------------------------------
    -- 2. แขนซ้าย (Left Arm - ประคองด้ามปืน / ประกับมือ & เคลื่อนที่ทั้งแขนตอนรีโหลด)
    ------------------------------------------------------------------
    if isPistol then
        local lShoulder = Vector3.new(-0.74, -1.04, 1.88)
        local lElbow    = Vector3.new(-0.46, -0.78, 1.15)
        local lWrist    = Vector3.new(-0.10, -0.49, 0.38)
        local lPalmPos  = Vector3.new(-0.04, -0.46, 0.16)

        addLimbSegment("LeftSleeve", lShoulder, lElbow, 0.42, SHIRT_COLOR, Enum.Material.Fabric, true)
        addLimbSegment("LeftCuff", lElbow + (lShoulder - lElbow).Unit * 0.04, lElbow - (lWrist - lElbow).Unit * 0.12, 0.45, CUFF_COLOR, Enum.Material.Fabric, true)
        addLimbSegment("LeftCuffStripe", lElbow - (lWrist - lElbow).Unit * 0.11, lElbow - (lWrist - lElbow).Unit * 0.16, 0.44, KMUTNB_ACCENT, Enum.Material.SmoothPlastic, true)
        addLimbSegment("LeftForearm", lElbow - (lWrist - lElbow).Unit * 0.08, lWrist, 0.29, SKIN_COLOR, Enum.Material.SmoothPlastic, true)

        -- นาฬิกาข้อมือซ้าย
        local watchCF = CFrame.lookAt(lWrist + (lElbow - lWrist).Unit * 0.14, lWrist)
        addPart("LeftWatchStrap", Vector3.new(0.32, 0.29, 0.12), WATCH_CASE, Enum.Material.SmoothPlastic, watchCF, true)
        addPart("LeftWatchFace", Vector3.new(0.16, 0.05, 0.14), WATCH_DIAL, Enum.Material.Neon, watchCF * CFrame.new(-0.06, 0.14, 0), true)

        local lHandCF = CFrame.new(lPalmPos) * CFrame.Angles(math.rad(-10), math.rad(14), 0)
        addPart("LeftGlovePalm", Vector3.new(0.28, 0.20, 0.30), GLOVE_DARK, Enum.Material.Fabric, lHandCF, true)
        addPart("LeftKnucklePad", Vector3.new(0.28, 0.08, 0.16), GLOVE_PAD, Enum.Material.SmoothPlastic, lHandCF * CFrame.new(-0.06, 0.07, -0.04), true)
        addPart("LeftFingers", Vector3.new(0.22, 0.13, 0.20), SKIN_COLOR, Enum.Material.SmoothPlastic, lHandCF * CFrame.new(0.08, -0.05, -0.14) * CFrame.Angles(math.rad(25), math.rad(15), 0), true)
        addPart("LeftThumb", Vector3.new(0.09, 0.09, 0.22), SKIN_COLOR, Enum.Material.SmoothPlastic, lHandCF * CFrame.new(0.06, 0.10, -0.10), true)
    else
        local lShoulder = Vector3.new(-0.96, -0.96, 1.18)
        local lElbow    = Vector3.new(-0.56, -0.68, 0.12)
        local lWrist    = Vector3.new(-0.14, -0.26, supportZ + 0.24)
        local lPalmPos  = Vector3.new(-0.04, -0.22, supportZ)

        addLimbSegment("LeftSleeve", lShoulder, lElbow, 0.42, SHIRT_COLOR, Enum.Material.Fabric, true)
        addLimbSegment("LeftCuff", lElbow + (lShoulder - lElbow).Unit * 0.04, lElbow - (lWrist - lElbow).Unit * 0.12, 0.45, CUFF_COLOR, Enum.Material.Fabric, true)
        addLimbSegment("LeftCuffStripe", lElbow - (lWrist - lElbow).Unit * 0.11, lElbow - (lWrist - lElbow).Unit * 0.16, 0.44, KMUTNB_ACCENT, Enum.Material.SmoothPlastic, true)
        addLimbSegment("LeftForearm", lElbow - (lWrist - lElbow).Unit * 0.08, lWrist, 0.29, SKIN_COLOR, Enum.Material.SmoothPlastic, true)

        local watchCF = CFrame.lookAt(lWrist + (lElbow - lWrist).Unit * 0.15, lWrist)
        addPart("LeftWatchStrap", Vector3.new(0.31, 0.28, 0.12), WATCH_CASE, Enum.Material.SmoothPlastic, watchCF, true)
        addPart("LeftWatchFace", Vector3.new(0.15, 0.05, 0.13), WATCH_DIAL, Enum.Material.Neon, watchCF * CFrame.new(-0.05, 0.13, 0), true)

        local lHandCF = CFrame.new(lPalmPos) * CFrame.Angles(0, math.rad(10), math.rad(18))
        addPart("LeftGlovePalm", Vector3.new(0.30, 0.19, 0.34), GLOVE_DARK, Enum.Material.Fabric, lHandCF, true)
        addPart("LeftKnucklePad", Vector3.new(0.28, 0.08, 0.18), GLOVE_PAD, Enum.Material.SmoothPlastic, lHandCF * CFrame.new(-0.06, -0.06, -0.04), true)
        addPart("LeftFingers", Vector3.new(0.20, 0.16, 0.26), SKIN_COLOR, Enum.Material.SmoothPlastic, lHandCF * CFrame.new(0.12, 0.08, -0.02) * CFrame.Angles(0, 0, math.rad(-20)), true)
        addPart("LeftThumb", Vector3.new(0.09, 0.10, 0.24), SKIN_COLOR, Enum.Material.SmoothPlastic, lHandCF * CFrame.new(-0.10, 0.14, -0.08) * CFrame.Angles(math.rad(-10), math.rad(18), 0), true)
    end

    return armParts, leftArmParts, rightArmParts
end

return KMUTNBArms
