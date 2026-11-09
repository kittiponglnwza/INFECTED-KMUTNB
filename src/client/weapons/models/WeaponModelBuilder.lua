--[[
    WeaponModelBuilder.lua
    โมดูลสร้างโมเดลปืน 3D และประกอบเข้ากับ Viewmodel
    รองรับทั้ง:
      1. โมเดลจริงจาก ReplicatedStorage (ถ้าผู้เล่นใส่โมเดล เช่น "Vandal_Model", "Phantom_Model")
      2. โมเดล 3D Procedural Mesh & Shaders ทรงปืนตามสเปก Valorant
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponModelBuilder = {}

function WeaponModelBuilder.build(parentModel, weaponConfig, gunRoot)
    local weaponParts = {}
    local muzzleFlashPart = nil
    local flashLight = nil

    -- 1. ตรวจสอบว่ามีโมเดลจริงจากผู้เล่นหรือไม่
    local customName = weaponConfig.Name .. "_Model"
    local customTemplate = ReplicatedStorage:FindFirstChild(customName) or ReplicatedStorage:FindFirstChild(weaponConfig.Name)

    if customTemplate and customTemplate:IsA("Model") then
        local realGun = customTemplate:Clone()
        realGun.Parent = parentModel

        for _, p in ipairs(realGun:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
                p.Anchored = true
                p.CastShadow = false
                weaponParts[p] = gunRoot.CFrame:ToObjectSpace(p.CFrame)
                if p.Name:match("Muzzle") or p.Name:match("Flash") then
                    muzzleFlashPart = p
                end
            end
        end
    else
        -- 2. สร้างโครงสร้าง 3D ตามสเปก Valorant
        local isPistol = (weaponConfig.Type == "Pistol" or weaponConfig.Type == "Revolver")
        local vis = weaponConfig.Visual or {}
        local pCol = vis.PrimaryColor or Color3.fromRGB(35, 38, 44)
        local aCol = vis.AccentColor or Color3.fromRGB(255, 120, 30)
        local barrelLen = vis.BarrelLength or (isPistol and 1.2 or 2.4)
        local muzzleZ = vis.MuzzleZ or (isPistol and -1.4 or -2.9)

        local function addGunPart(name, size, color, material, relCF)
            local p = Instance.new("Part")
            p.Name = name
            p.Size = size
            p.Color = color
            p.Material = material
            p.CanCollide = false
            p.Anchored = true
            p.CastShadow = false
            p.Parent = parentModel
            weaponParts[p] = relCF
            return p
        end

        -- ตัวปืนหลัก (Receiver)
        addGunPart("Receiver", Vector3.new(0.34, 0.52, isPistol and 1.1 or 1.8), pCol, Enum.Material.Metal, CFrame.new(0, 0, 0))
        -- ฝาครอบบนและสี Accent
        addGunPart("Cover", Vector3.new(0.30, 0.18, isPistol and 0.9 or 1.5), aCol, Enum.Material.SmoothPlastic, CFrame.new(0, 0.30, 0))
        -- ลำกล้อง (Barrel)
        addGunPart("Barrel", Vector3.new(0.18, 0.18, barrelLen), Color3.fromRGB(25, 25, 28), Enum.Material.Metal, CFrame.new(0, 0.05, muzzleZ * 0.55))

        -- แม็กกาซีน
        if not (weaponConfig.Name == "Shorty" or weaponConfig.Name == "Outlaw" or weaponConfig.Type == "Revolver") then
            local magH = isPistol and 0.55 or 0.9
            addGunPart("Magazine", Vector3.new(0.24, magH, 0.45), aCol, Enum.Material.SmoothPlastic, CFrame.new(0, -0.45, -0.15))
        end

        -- ด้ามจับ
        addGunPart("PistolGrip", Vector3.new(0.30, 0.85, 0.42), Color3.fromRGB(30, 32, 36), Enum.Material.SmoothPlastic, CFrame.new(0, -0.45, 0.40) * CFrame.Angles(math.rad(-16), 0, 0))

        -- พานท้ายปืนยาว
        if not isPistol then
            addGunPart("Stock", Vector3.new(0.32, 0.80, 1.6), pCol, Enum.Material.Metal, CFrame.new(0, -0.05, 1.45))
        end

        -- ท่อเก็บเสียง
        if weaponConfig.Audio and weaponConfig.Audio.Silenced then
            addGunPart("Silencer", Vector3.new(0.26, 0.26, 1.2), Color3.fromRGB(20, 22, 26), Enum.Material.Metal, CFrame.new(0, 0.05, muzzleZ - 0.5))
            muzzleZ = muzzleZ - 1.1
        end

        -- สโคปสไนเปอร์
        if weaponConfig.IsSniper then
            addGunPart("ScopeMount", Vector3.new(0.20, 0.25, 0.6), Color3.fromRGB(30, 30, 35), Enum.Material.Metal, CFrame.new(0, 0.38, -0.3))
            addGunPart("ScopeTube", Vector3.new(0.32, 0.32, 1.6), Color3.fromRGB(20, 22, 26), Enum.Material.Metal, CFrame.new(0, 0.55, -0.3))
            addGunPart("ScopeRing", Vector3.new(0.36, 0.36, 0.2), aCol, Enum.Material.Neon, CFrame.new(0, 0.55, -1.0))
        else
            -- ศูนย์หน้าเรืองแสง
            addGunPart("FrontSight", Vector3.new(0.06, 0.12, 0.06), Color3.fromRGB(50, 255, 120), Enum.Material.Neon, CFrame.new(0, 0.42, muzzleZ + 0.2))
        end

        -- ปากกระบอกและแฟลชไฟ
        muzzleFlashPart = addGunPart("MuzzleFlash", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(255, 200, 50), Enum.Material.Neon, CFrame.new(0, 0.05, muzzleZ))
    end

    if not muzzleFlashPart then
        muzzleFlashPart = Instance.new("Part")
        muzzleFlashPart.Name = "MuzzleFlash"
        muzzleFlashPart.Size = Vector3.new(0.4, 0.4, 0.4)
        muzzleFlashPart.Color = Color3.fromRGB(255, 200, 50)
        muzzleFlashPart.Material = Enum.Material.Neon
        muzzleFlashPart.CanCollide = false
        muzzleFlashPart.Anchored = true
        muzzleFlashPart.CastShadow = false
        muzzleFlashPart.Parent = parentModel
        weaponParts[muzzleFlashPart] = CFrame.new(0, 0.05, -2.5)
    end
    muzzleFlashPart.Transparency = 1

    flashLight = Instance.new("PointLight")
    flashLight.Color = Color3.fromRGB(255, 180, 50)
    flashLight.Range = 22
    flashLight.Brightness = 0
    flashLight.Parent = muzzleFlashPart

    return weaponParts, muzzleFlashPart, flashLight
end

return WeaponModelBuilder
