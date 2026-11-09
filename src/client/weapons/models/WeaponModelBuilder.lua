--[[
    WeaponModelBuilder.lua
    โมดูลสร้างโมเดลปืน 3D และมีดคารัมบิตแท้สไตล์ VALORANT
    - VANDAL: ทรง AK ล้ำยุค แม็กกล้วยโค้ง ด้ามจับไม้/คาร์บอน รางท่อแก๊ส และคอมเพนเซเตอร์ปากกระบอก
    - PHANTOM: ปืนไรเฟิลเก็บเสียงอินทิกรัล ลำกล้องคาร์บอนกระบอกหนา แม็กตรง ราง Picatinny และเรืองแสงฟ้า
    - OPERATOR: ปืนสไนเปอร์หนัก .50 Cal ลำกล้องหนา ปากกระบอกคอมเพนเซเตอร์รถถัง สโคปยักษ์พร้อมปุ่มหมุนระยะ
    - CLASSIC: ปืนพกเริ่มต้น สไลด์เหล็กเซาะร่อง โครงโพลีเมอร์ ศูนย์เล็งเรืองแสง
    - KARAMBIT: มีดกรงเล็บคารัมบิตควงได้ ห่วงนิ้วทองเหลือง/คาร์บอน คมมีดโค้งเรืองแสง Champions / Prime 2.0
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponModelBuilder = {}

function WeaponModelBuilder.build(parentModel, weaponConfig, gunRoot)
    local weaponParts = {}
    local muzzleFlashPart = nil
    local flashLight = nil

    local wName = (weaponConfig.Name or ""):upper()
    local isPistol = (weaponConfig.Type == "Pistol" or weaponConfig.Type == "Revolver")
    local vis = weaponConfig.Visual or {}
    local pCol = vis.PrimaryColor or Color3.fromRGB(32, 34, 40)
    local aCol = vis.AccentColor or Color3.fromRGB(255, 120, 30)

    -- 1. ตรวจสอบโมเดลจริงจาก ReplicatedStorage เผื่อผู้เล่นมีโมเดลนำเข้า
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
        return weaponParts, muzzleFlashPart, flashLight
    end

    -- ฟังก์ชันช่วยสร้างชิ้นส่วน 3D
    local function addPart(name, size, color, material, relCF, canBeMuzzle)
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
        if canBeMuzzle then
            muzzleFlashPart = p
        end
        return p
    end

    ------------------------------------------------------------------
    -- 🗡️ 2. TACTICAL KARAMBIT KNIFE (Champions / Prime 2.0 Style)
    ------------------------------------------------------------------
    if weaponConfig.Type == "Knife" or wName == "KARAMBIT" then
        local knifeGold = Color3.fromRGB(240, 190, 50)
        local knifeCarbon = Color3.fromRGB(24, 26, 30)
        local bladeSteel = Color3.fromRGB(50, 55, 65)
        local neonGlow = aCol or Color3.fromRGB(0, 240, 255)

        -- A. ห่วงคล้องนิ้วสำหรับควงมีด (Karambit Finger Ring)
        addPart("KarambitRingOuter", Vector3.new(0.24, 0.24, 0.14), knifeGold, Enum.Material.Metal, CFrame.new(0, -0.20, 0.38))
        addPart("KarambitRingBevel", Vector3.new(0.20, 0.20, 0.16), knifeCarbon, Enum.Material.SmoothPlastic, CFrame.new(0, -0.20, 0.38))

        -- B. ด้ามจับมีดทรงเว้ากระชับนิ้ว (Contoured Ergonomic Handle)
        addPart("HandleMain", Vector3.new(0.18, 0.55, 0.22), knifeCarbon, Enum.Material.DiamondPlate, CFrame.new(0, -0.44, 0.14) * CFrame.Angles(math.rad(-14), 0, 0))
        addPart("HandleFingerGroove1", Vector3.new(0.19, 0.12, 0.24), knifeGold, Enum.Material.Metal, CFrame.new(0, -0.35, 0.18) * CFrame.Angles(math.rad(-14), 0, 0))
        addPart("HandleFingerGroove2", Vector3.new(0.19, 0.12, 0.24), knifeGold, Enum.Material.Metal, CFrame.new(0, -0.52, 0.10) * CFrame.Angles(math.rad(-14), 0, 0))
        addPart("HandleSpine", Vector3.new(0.10, 0.58, 0.08), knifeGold, Enum.Material.Neon, CFrame.new(0, -0.42, 0.25) * CFrame.Angles(math.rad(-14), 0, 0))

        -- C. โครงใบมีดโค้งกรงเล็บเสือ 3 ท่อน (Sweeping Curved Hawkbill Talon)
        -- โคนใบมีด
        addPart("BladeBase", Vector3.new(0.08, 0.40, 0.35), bladeSteel, Enum.Material.Metal, CFrame.new(0, -0.16, -0.20) * CFrame.Angles(math.rad(22), 0, 0))
        -- กลางใบมีดโค้งลง
        addPart("BladeMid", Vector3.new(0.07, 0.42, 0.28), bladeSteel, Enum.Material.Metal, CFrame.new(0, -0.28, -0.45) * CFrame.Angles(math.rad(42), 0, 0))
        -- ปลายเล็บแหลมคม
        addPart("BladeTip", Vector3.new(0.06, 0.35, 0.18), bladeSteel, Enum.Material.Metal, CFrame.new(0, -0.42, -0.65) * CFrame.Angles(math.rad(62), 0, 0))

        -- D. คมมีดเรืองแสงนีออนตลอดแนวโค้ง (Full Curved Neon Cutting Edge)
        addPart("NeonEdge1", Vector3.new(0.05, 0.42, 0.08), neonGlow, Enum.Material.Neon, CFrame.new(0, -0.25, -0.32) * CFrame.Angles(math.rad(25), 0, 0))
        addPart("NeonEdge2", Vector3.new(0.05, 0.45, 0.08), neonGlow, Enum.Material.Neon, CFrame.new(0, -0.42, -0.55) * CFrame.Angles(math.rad(50), 0, 0))
        addPart("NeonEdge3", Vector3.new(0.05, 0.30, 0.06), neonGlow, Enum.Material.Neon, CFrame.new(0, -0.56, -0.72) * CFrame.Angles(math.rad(72), 0, 0))

        -- E. ตราสัญลักษณ์ Valorant สีทองบนสันใบมีด
        addPart("BladeInsignia", Vector3.new(0.09, 0.14, 0.14), knifeGold, Enum.Material.Neon, CFrame.new(0, -0.15, -0.22) * CFrame.Angles(math.rad(45), 0, 0))

        muzzleFlashPart = Instance.new("Part")
        muzzleFlashPart.Name = "MuzzleFlash"
        muzzleFlashPart.Size = Vector3.new(0.1, 0.1, 0.1)
        muzzleFlashPart.Transparency = 1
        muzzleFlashPart.CanCollide = false
        muzzleFlashPart.Anchored = true
        muzzleFlashPart.Parent = parentModel
        weaponParts[muzzleFlashPart] = CFrame.new(0, 0, -1)
        return weaponParts, muzzleFlashPart, nil
    end

    ------------------------------------------------------------------
    -- 🔫 3. VANDAL (Iconic Futuristic 7.62 Assault Rifle)
    ------------------------------------------------------------------
    if wName == "VANDAL" then
        local woodTone = Color3.fromRGB(85, 50, 32)
        local darkCarbon = Color3.fromRGB(30, 32, 38)
        local metalSteel = Color3.fromRGB(45, 48, 55)
        local orangeAccent = Color3.fromRGB(255, 115, 30)

        -- โครงปืนหลัก (Receiver)
        addPart("Receiver", Vector3.new(0.32, 0.48, 1.8), darkCarbon, Enum.Material.Metal, CFrame.new(0, 0, 0))
        -- ฝาครอบห้องลูกเลื่อนบน (Dust Cover)
        addPart("DustCover", Vector3.new(0.28, 0.16, 1.4), metalSteel, Enum.Material.Metal, CFrame.new(0, 0.28, 0.05))
        -- ท่อส่งแก๊สบน (Gas Tube) ทรงกระบอก AK แท้
        addPart("GasTube", Vector3.new(0.18, 0.18, 1.6), darkCarbon, Enum.Material.Metal, CFrame.new(0, 0.20, -1.2))

        -- ประกับมือล่างไม้ผสมคาร์บอน (Wood/Carbon Lower Handguard)
        addPart("Handguard", Vector3.new(0.34, 0.32, 1.4), woodTone, Enum.Material.Wood, CFrame.new(0, -0.05, -1.2))
        addPart("HandguardRail", Vector3.new(0.36, 0.06, 1.3), orangeAccent, Enum.Material.Neon, CFrame.new(0, 0.08, -1.2))

        -- ลำกล้องปืน (Barrel)
        addPart("Barrel", Vector3.new(0.16, 0.16, 2.2), metalSteel, Enum.Material.Metal, CFrame.new(0, 0.08, -2.1))
        -- ปากกระบอก Vandal Muzzle Brake รูระบายแก๊สคู่
        addPart("MuzzleBrake", Vector3.new(0.24, 0.24, 0.45), darkCarbon, Enum.Material.Metal, CFrame.new(0, 0.08, -3.15))

        -- ศูนย์หน้าทรงสามเหลี่ยม AK (Front Sight Post)
        addPart("FrontSightBase", Vector3.new(0.12, 0.24, 0.15), metalSteel, Enum.Material.Metal, CFrame.new(0, 0.28, -2.9))
        addPart("FrontSightTritium", Vector3.new(0.04, 0.08, 0.04), Color3.fromRGB(0, 255, 140), Enum.Material.Neon, CFrame.new(0, 0.34, -2.9))

        -- แม็กกาซีนกล้วยโค้งสไตล์ AK (Curved Banana Magazine)
        addPart("MagUpper", Vector3.new(0.24, 0.65, 0.45), orangeAccent, Enum.Material.SmoothPlastic, CFrame.new(0, -0.42, -0.22) * CFrame.Angles(math.rad(-12), 0, 0))
        addPart("MagLower", Vector3.new(0.22, 0.55, 0.42), darkCarbon, Enum.Material.Metal, CFrame.new(0, -0.80, -0.38) * CFrame.Angles(math.rad(-25), 0, 0))
        addPart("MagBase", Vector3.new(0.24, 0.10, 0.46), orangeAccent, Enum.Material.Neon, CFrame.new(0, -1.02, -0.48) * CFrame.Angles(math.rad(-25), 0, 0))

        -- ด้ามจับปืน (Pistol Grip)
        addPart("Grip", Vector3.new(0.28, 0.85, 0.40), woodTone, Enum.Material.Wood, CFrame.new(0, -0.48, 0.45) * CFrame.Angles(math.rad(-18), 0, 0))

        -- พานท้ายปืนโครงเหล็กโปร่ง (Skeletonized Tactical Stock)
        addPart("StockRoot", Vector3.new(0.26, 0.45, 0.8), darkCarbon, Enum.Material.Metal, CFrame.new(0, 0, 1.2))
        addPart("StockStrut", Vector3.new(0.18, 0.22, 1.2), metalSteel, Enum.Material.Metal, CFrame.new(0, -0.08, 1.8) * CFrame.Angles(math.rad(-8), 0, 0))
        addPart("StockButt", Vector3.new(0.28, 0.75, 0.25), woodTone, Enum.Material.Wood, CFrame.new(0, -0.15, 2.35))

        -- จุดประกายไฟปากกระบอก
        muzzleFlashPart = addPart("MuzzleFlash", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(255, 200, 60), Enum.Material.Neon, CFrame.new(0, 0.08, -3.4), true)

    ------------------------------------------------------------------
    -- 🤫 4. PHANTOM (Integrally Suppressed Tactical Rifle)
    ------------------------------------------------------------------
    elseif wName == "PHANTOM" then
        local stealthBlack = Color3.fromRGB(24, 26, 30)
        local carbonGrey = Color3.fromRGB(40, 44, 52)
        local cyanNeon = Color3.fromRGB(0, 230, 255)

        -- โครงปืนบน/ล่าง (Upper & Lower Receiver)
        addPart("Receiver", Vector3.new(0.32, 0.46, 1.6), stealthBlack, Enum.Material.Metal, CFrame.new(0, 0, 0))
        addPart("TopRail", Vector3.new(0.24, 0.08, 1.5), carbonGrey, Enum.Material.Metal, CFrame.new(0, 0.26, 0))

        -- ศูนย์เล็งโฮโลกราฟิกบนราง (Reflex Optic Housing)
        addPart("SightBase", Vector3.new(0.22, 0.18, 0.5), carbonGrey, Enum.Material.Metal, CFrame.new(0, 0.35, -0.2))
        addPart("SightEmitter", Vector3.new(0.16, 0.14, 0.04), cyanNeon, Enum.Material.Neon, CFrame.new(0, 0.38, -0.4))

        -- ท่อเก็บเสียงกระบอกหนาอินทิกรัล (Thick Integral Suppressor Shroud)
        addPart("SuppressorShroud", Vector3.new(0.38, 0.38, 2.4), stealthBlack, Enum.Material.SmoothPlastic, CFrame.new(0, 0.06, -1.8))
        addPart("SuppressorCore", Vector3.new(0.32, 0.32, 1.2), carbonGrey, Enum.Material.Metal, CFrame.new(0, 0.06, -2.8))
        addPart("SuppressorTip", Vector3.new(0.26, 0.26, 0.3), cyanNeon, Enum.Material.Neon, CFrame.new(0, 0.06, -3.45))

        -- แถบเส้นเรืองแสง Cyan สไตล์ Phantom
        addPart("TechStripeL", Vector3.new(0.04, 0.06, 1.2), cyanNeon, Enum.Material.Neon, CFrame.new(-0.17, 0.12, -0.1))
        addPart("TechStripeR", Vector3.new(0.04, 0.06, 1.2), cyanNeon, Enum.Material.Neon, CFrame.new(0.17, 0.12, -0.1))

        -- แม็กกาซีนตรง PMAG พร้อมช่องดูจำนวนกระสุน
        addPart("Magazine", Vector3.new(0.24, 0.85, 0.42), stealthBlack, Enum.Material.SmoothPlastic, CFrame.new(0, -0.50, -0.18) * CFrame.Angles(math.rad(-10), 0, 0))
        addPart("MagWindow", Vector3.new(0.26, 0.40, 0.08), cyanNeon, Enum.Material.Neon, CFrame.new(0, -0.48, -0.18) * CFrame.Angles(math.rad(-10), 0, 0))

        -- ด้ามจับและพานท้าย CTR
        addPart("Grip", Vector3.new(0.28, 0.80, 0.38), stealthBlack, Enum.Material.SmoothPlastic, CFrame.new(0, -0.45, 0.40) * CFrame.Angles(math.rad(-15), 0, 0))
        addPart("StockTube", Vector3.new(0.20, 0.20, 1.2), carbonGrey, Enum.Material.Metal, CFrame.new(0, 0.02, 1.4))
        addPart("StockCTR", Vector3.new(0.28, 0.65, 0.8), stealthBlack, Enum.Material.SmoothPlastic, CFrame.new(0, -0.10, 1.7))

        muzzleFlashPart = addPart("MuzzleFlash", Vector3.new(0.35, 0.35, 0.35), cyanNeon, Enum.Material.Neon, CFrame.new(0, 0.06, -3.6), true)

    ------------------------------------------------------------------
    -- 🎯 5. OPERATOR (Heavy Anti-Material Sniper Rifle)
    ------------------------------------------------------------------
    elseif wName == "OPERATOR" or weaponConfig.IsSniper then
        local sniperGunmetal = Color3.fromRGB(36, 40, 48)
        local darkChassis = Color3.fromRGB(24, 26, 30)
        local scopeAccent = Color3.fromRGB(255, 60, 75)

        -- ลำตัวปืนบูลพัพขนาดยักษ์ (Heavy Bullpup Chassis)
        addPart("Chassis", Vector3.new(0.38, 0.65, 2.2), darkChassis, Enum.Material.Metal, CFrame.new(0, -0.05, 0))
        addPart("TopRail", Vector3.new(0.28, 0.10, 1.8), sniperGunmetal, Enum.Material.Metal, CFrame.new(0, 0.32, -0.2))

        -- กล้องสโคปสไนเปอร์ความคมชัดสูงขนาดยักษ์ (Giant Sniper Scope)
        addPart("ScopeMountF", Vector3.new(0.26, 0.25, 0.2), sniperGunmetal, Enum.Material.Metal, CFrame.new(0, 0.44, -0.7))
        addPart("ScopeMountR", Vector3.new(0.26, 0.25, 0.2), sniperGunmetal, Enum.Material.Metal, CFrame.new(0, 0.44, 0.1))
        addPart("ScopeTube", Vector3.new(0.34, 0.34, 2.0), darkChassis, Enum.Material.Metal, CFrame.new(0, 0.62, -0.3))
        addPart("ScopeSunshade", Vector3.new(0.40, 0.40, 0.5), scopeAccent, Enum.Material.Metal, CFrame.new(0, 0.62, -1.25))
        addPart("ScopeEyepiece", Vector3.new(0.38, 0.38, 0.4), darkChassis, Enum.Material.SmoothPlastic, CFrame.new(0, 0.62, 0.65))
        -- ปุ่มหมุนปรับระยะ (Elevation & Windage Turrets)
        addPart("ScopeTurretTop", Vector3.new(0.14, 0.16, 0.14), scopeAccent, Enum.Material.Neon, CFrame.new(0, 0.82, -0.3))
        addPart("ScopeTurretSide", Vector3.new(0.16, 0.14, 0.14), scopeAccent, Enum.Material.Neon, CFrame.new(0.22, 0.62, -0.3))

        -- ลำกล้องปืนสไนเปอร์หนาพิเศษ (Heavy Fluted Barrel)
        addPart("HeavyBarrel", Vector3.new(0.22, 0.22, 2.8), sniperGunmetal, Enum.Material.Metal, CFrame.new(0, 0.08, -2.3))

        -- ปากกระบอกคอมเพนเซเตอร์รถถังพอร์ตคู่ (Oversized Dual-Port Tank Muzzle Brake)
        addPart("TankBrake", Vector3.new(0.42, 0.35, 0.75), darkChassis, Enum.Material.Metal, CFrame.new(0, 0.08, -3.8))
        addPart("BrakePortL", Vector3.new(0.06, 0.24, 0.5), scopeAccent, Enum.Material.Neon, CFrame.new(-0.21, 0.08, -3.8))
        addPart("BrakePortR", Vector3.new(0.06, 0.24, 0.5), scopeAccent, Enum.Material.Neon, CFrame.new(0.21, 0.08, -3.8))

        -- ขาทรายพับใต้ปืน (Folded Bipod)
        addPart("BipodMount", Vector3.new(0.24, 0.15, 0.3), darkChassis, Enum.Material.Metal, CFrame.new(0, -0.22, -1.8))
        addPart("BipodLegL", Vector3.new(0.08, 0.08, 1.2), sniperGunmetal, Enum.Material.Metal, CFrame.new(-0.14, -0.22, -1.4))
        addPart("BipodLegR", Vector3.new(0.08, 0.08, 1.2), sniperGunmetal, Enum.Material.Metal, CFrame.new(0.14, -0.22, -1.4))

        -- แม็กกาซีนสไนเปอร์กล่องหนาและคันรั้งลูกเลื่อน
        addPart("HeavyMag", Vector3.new(0.28, 0.70, 0.55), darkChassis, Enum.Material.Metal, CFrame.new(0, -0.48, -0.15))
        addPart("BoltHandle", Vector3.new(0.35, 0.08, 0.08), scopeAccent, Enum.Material.Metal, CFrame.new(0.26, 0.22, 0.45) * CFrame.Angles(0, 0, math.rad(-25)))

        -- ด้ามจับและพานท้ายเสริมโมโนพอด
        addPart("Grip", Vector3.new(0.30, 0.90, 0.42), darkChassis, Enum.Material.SmoothPlastic, CFrame.new(0, -0.50, 0.55) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("SniperStock", Vector3.new(0.34, 0.85, 1.4), darkChassis, Enum.Material.Metal, CFrame.new(0, -0.05, 1.6))
        addPart("CheekPad", Vector3.new(0.36, 0.20, 0.7), sniperGunmetal, Enum.Material.SmoothPlastic, CFrame.new(0, 0.35, 1.4))

        muzzleFlashPart = addPart("MuzzleFlash", Vector3.new(0.65, 0.65, 0.65), Color3.fromRGB(255, 180, 50), Enum.Material.Neon, CFrame.new(0, 0.08, -4.2), true)

    ------------------------------------------------------------------
    -- 🔫 6. CLASSIC (Valorant Starter Sidearm)
    ------------------------------------------------------------------
    elseif wName == "CLASSIC" or isPistol then
        local slideSteel = Color3.fromRGB(42, 45, 52)
        local framePolymer = Color3.fromRGB(26, 28, 33)
        local tritiumGlow = Color3.fromRGB(0, 255, 160)

        -- สไลด์ปืนเหล็กกล้าเซาะร่อง (Steel Slide with Cocking Serrations)
        addPart("Slide", Vector3.new(0.26, 0.32, 1.15), slideSteel, Enum.Material.Metal, CFrame.new(0, 0.12, -0.2))
        addPart("SlideTopBevel", Vector3.new(0.22, 0.08, 1.10), slideSteel, Enum.Material.Metal, CFrame.new(0, 0.26, -0.2))

        -- ร่องเซาะสไลด์หลัง (Serrations)
        addPart("Serrations", Vector3.new(0.28, 0.24, 0.35), framePolymer, Enum.Material.DiamondPlate, CFrame.new(0, 0.12, 0.18))

        -- โครงปืนโพลีเมอร์ล่างและโกร่งไก (Polymer Frame & Trigger Guard)
        addPart("PolymerFrame", Vector3.new(0.26, 0.25, 1.10), framePolymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.12, -0.2))
        addPart("TriggerGuard", Vector3.new(0.12, 0.22, 0.35), framePolymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.28, -0.15))
        addPart("Trigger", Vector3.new(0.06, 0.14, 0.06), slideSteel, Enum.Material.Metal, CFrame.new(0, -0.24, -0.10) * CFrame.Angles(math.rad(15), 0, 0))

        -- ลำกล้องและปากกระบอกปืนพก
        addPart("BarrelPistol", Vector3.new(0.14, 0.14, 0.5), slideSteel, Enum.Material.Metal, CFrame.new(0, 0.10, -0.8))

        -- ศูนย์เล็งไนท์ไซต์เรืองแสง Tritium
        addPart("FrontNightSight", Vector3.new(0.04, 0.08, 0.04), tritiumGlow, Enum.Material.Neon, CFrame.new(0, 0.30, -0.7))
        addPart("RearSightL", Vector3.new(0.04, 0.06, 0.04), tritiumGlow, Enum.Material.Neon, CFrame.new(-0.08, 0.30, 0.32))
        addPart("RearSightR", Vector3.new(0.04, 0.06, 0.04), tritiumGlow, Enum.Material.Neon, CFrame.new(0.08, 0.30, 0.32))

        -- ด้ามจับปืนพกสองมือ
        addPart("GripPistol", Vector3.new(0.24, 0.75, 0.38), framePolymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.46, 0.18) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("MagFloorPlate", Vector3.new(0.26, 0.08, 0.40), slideSteel, Enum.Material.Metal, CFrame.new(0, -0.82, 0.08) * CFrame.Angles(math.rad(-16), 0, 0))

        muzzleFlashPart = addPart("MuzzleFlash", Vector3.new(0.35, 0.35, 0.35), Color3.fromRGB(255, 210, 80), Enum.Material.Neon, CFrame.new(0, 0.10, -1.05), true)

    ------------------------------------------------------------------
    -- 🔫 7. ปืนอื่นๆ ทั่วไป (Fallback Procedural)
    ------------------------------------------------------------------
    else
        addPart("Receiver", Vector3.new(0.34, 0.52, 1.8), pCol, Enum.Material.Metal, CFrame.new(0, 0, 0))
        addPart("Cover", Vector3.new(0.30, 0.18, 1.5), aCol, Enum.Material.SmoothPlastic, CFrame.new(0, 0.30, 0))
        addPart("Barrel", Vector3.new(0.18, 0.18, 2.2), Color3.fromRGB(25, 25, 28), Enum.Material.Metal, CFrame.new(0, 0.05, -1.6))
        addPart("Magazine", Vector3.new(0.24, 0.85, 0.45), aCol, Enum.Material.SmoothPlastic, CFrame.new(0, -0.45, -0.15))
        addPart("Grip", Vector3.new(0.30, 0.85, 0.42), Color3.fromRGB(30, 32, 36), Enum.Material.SmoothPlastic, CFrame.new(0, -0.45, 0.40) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("Stock", Vector3.new(0.32, 0.80, 1.6), pCol, Enum.Material.Metal, CFrame.new(0, -0.05, 1.45))
        addPart("FrontSight", Vector3.new(0.06, 0.12, 0.06), Color3.fromRGB(50, 255, 120), Enum.Material.Neon, CFrame.new(0, 0.42, -2.6))
        muzzleFlashPart = addPart("MuzzleFlash", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(255, 200, 50), Enum.Material.Neon, CFrame.new(0, 0.05, -2.8), true)
    end

    if not muzzleFlashPart then
        muzzleFlashPart = Instance.new("Part")
        muzzleFlashPart.Name = "MuzzleFlash"
        muzzleFlashPart.Size = Vector3.new(0.3, 0.3, 0.3)
        muzzleFlashPart.Transparency = 1
        muzzleFlashPart.CanCollide = false
        muzzleFlashPart.Anchored = true
        muzzleFlashPart.Parent = parentModel
        weaponParts[muzzleFlashPart] = CFrame.new(0, 0, -2.5)
    end
    muzzleFlashPart.Transparency = 1

    flashLight = Instance.new("PointLight")
    flashLight.Color = Color3.fromRGB(255, 190, 60)
    flashLight.Range = 22
    flashLight.Brightness = 0
    flashLight.Parent = muzzleFlashPart

    return weaponParts, muzzleFlashPart, flashLight
end

return WeaponModelBuilder
