--[[
    KMUTNBArms.lua
    โมดูลสร้างและจัดตำแหน่งแขนนักศึกษา มจพ. (KMUTNB Student Arms)
    - เสื้อเชิ้ตขาวนักศึกษาแขนสั้นพับแขน (White Fabric Cuffs)
    - ท่อนแขนและมือคนจริง 3D
    - รองรับท่าจับปืนยาว, ปืนสั้น 2 มือ, และการขยับแขนตอนรีโหลด
]]

local KMUTNBArms = {}

local SHIRT_COLOR = Color3.fromRGB(246, 248, 252) -- เสื้อเชิ้ตขาว มจพ.
local CUFF_COLOR = Color3.fromRGB(222, 226, 235)  -- ขอบรอยพับแขนเสื้อ
local SKIN_COLOR = Color3.fromRGB(228, 186, 155)  -- สีผิวคนจริง

function KMUTNBArms.build(parentModel, isPistol)
    local armParts = {}
    local leftArmParts = {}
    rightArmParts = {}

    local function addPart(name, size, color, material, relCF, isLeft)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.Color = color
        p.Material = material
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

    ------------------------------------------------------------------
    -- 1. แขนขวา (Right Arm - จับด้ามปืน)
    ------------------------------------------------------------------
    addPart("RightSleeve", Vector3.new(0.38, 0.42, 0.70), SHIRT_COLOR, Enum.Material.Fabric, CFrame.new(0.55, -0.85, 1.65))
    addPart("RightCuff", Vector3.new(0.40, 0.44, 0.12), CUFF_COLOR, Enum.Material.Fabric, CFrame.new(0.55, -0.85, 1.30))
    addPart("RightForearm", Vector3.new(0.32, 0.34, 1.05), SKIN_COLOR, Enum.Material.SmoothPlastic, CFrame.new(0.45, -0.70, 0.95) * CFrame.Angles(math.rad(12), math.rad(-8), 0))
    addPart("RightHand", Vector3.new(0.30, 0.22, 0.38), SKIN_COLOR, Enum.Material.SmoothPlastic, CFrame.new(0.08, -0.42, 0.42))

    ------------------------------------------------------------------
    -- 2. แขนซ้าย (Left Arm)
    ------------------------------------------------------------------
    if isPistol then
        -- ท่าจับปืนพกสองมือ
        addPart("LeftSleeve", Vector3.new(0.38, 0.42, 0.70), SHIRT_COLOR, Enum.Material.Fabric, CFrame.new(-0.35, -0.85, 1.55), true)
        addPart("LeftCuff", Vector3.new(0.40, 0.44, 0.12), CUFF_COLOR, Enum.Material.Fabric, CFrame.new(-0.35, -0.85, 1.20), true)
        addPart("LeftForearm", Vector3.new(0.32, 0.34, 1.05), SKIN_COLOR, Enum.Material.SmoothPlastic, CFrame.new(-0.25, -0.68, 0.90) * CFrame.Angles(math.rad(15), math.rad(12), 0), true)
        addPart("LeftHand", Vector3.new(0.32, 0.22, 0.36), SKIN_COLOR, Enum.Material.SmoothPlastic, CFrame.new(-0.06, -0.44, 0.40), true)
    else
        -- ท่าจับประคองปืนยาว / ปืนลูกซอง / ปืนสไนเปอร์
        addPart("LeftSleeve", Vector3.new(0.38, 0.42, 0.70), SHIRT_COLOR, Enum.Material.Fabric, CFrame.new(-0.65, -0.90, 0.65), true)
        addPart("LeftCuff", Vector3.new(0.40, 0.44, 0.12), CUFF_COLOR, Enum.Material.Fabric, CFrame.new(-0.65, -0.90, 0.30), true)
        addPart("LeftForearm", Vector3.new(0.32, 0.34, 1.15), SKIN_COLOR, Enum.Material.SmoothPlastic, CFrame.new(-0.45, -0.65, -0.30) * CFrame.Angles(math.rad(18), math.rad(14), 0), true)
        addPart("LeftHand", Vector3.new(0.30, 0.22, 0.38), SKIN_COLOR, Enum.Material.SmoothPlastic, CFrame.new(-0.12, -0.22, -1.25), true)
    end

    return armParts, leftArmParts, rightArmParts
end

return KMUTNBArms
