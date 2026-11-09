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
        p.CanQuery = false
        p.CanTouch = false
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
    -- 🔫 2. VANDAL (Iconic Futuristic 7.62 Assault Rifle)
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

        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 180, 50), Enum.Material.Neon, CFrame.new(0, 0.08, -4.2), true)

    ------------------------------------------------------------------
    -- 💥 6. BUCKY (Pump-Action Tactical Shotgun)
    -- ปืนลูกซองปั๊มแอคชั่นแท้ ไร้แม็กกาซีนปืนกล ลำกล้องคู่บนล่าง กระโจมมือสไลด์
    ------------------------------------------------------------------
    elseif wName == "BUCKY" then
        local gunmetalSteel = Color3.fromRGB(45, 48, 55)
        local darkPolymer = Color3.fromRGB(26, 28, 33)
        local heatShieldColor = Color3.fromRGB(60, 64, 72)
        local shellRed = Color3.fromRGB(220, 40, 40)
        local shellBrass = Color3.fromRGB(220, 180, 50)

        -- โครงปืนลูกซองแท้ (Receiver) - ทรงตัน ทรงลูกซองคอมแบท ไม่มีช่องเสียบแม็กกาซีนปืนกล
        addPart("Receiver", Vector3.new(0.34, 0.52, 1.6), darkPolymer, Enum.Material.Metal, CFrame.new(0, 0, 0))
        addPart("ReceiverTop", Vector3.new(0.28, 0.12, 1.4), gunmetalSteel, Enum.Material.Metal, CFrame.new(0, 0.28, 0.05))

        -- ลำกล้องลูกซอง 12-Gauge ขนาดใหญ่ท่อนบน (Top 12-Gauge Smoothbore Barrel)
        addPart("ShotgunBarrel", Vector3.new(0.24, 0.24, 2.6), gunmetalSteel, Enum.Material.Metal, CFrame.new(0, 0.12, -2.0))
        -- แผงกันความร้อนเจาะรูระบายบนลำกล้อง (Perforated Heat Shield)
        addPart("HeatShield", Vector3.new(0.28, 0.14, 1.5), heatShieldColor, Enum.Material.Metal, CFrame.new(0, 0.22, -1.5))

        -- ท่อบรรจุกระสุนลูกซองหลอดใต้ลำกล้อง (Under-barrel Tubular Magazine)
        addPart("MagazineTube", Vector3.new(0.20, 0.20, 2.2), gunmetalSteel, Enum.Material.Metal, CFrame.new(0, -0.10, -1.8))
        addPart("MagTubeCap", Vector3.new(0.22, 0.22, 0.18), darkPolymer, Enum.Material.Metal, CFrame.new(0, -0.10, -2.95))

        -- กระโจมมือปั๊มลูกซองเซาะร่องกันลื่น (Ribbed Pump Action Slide Forend)
        addPart("PumpSlide", Vector3.new(0.32, 0.32, 1.2), darkPolymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.09, -1.45))
        addPart("PumpStopRing", Vector3.new(0.34, 0.34, 0.12), gunmetalSteel, Enum.Material.Metal, CFrame.new(0, -0.09, -0.85))

        -- ช่องคัดปลอกลูกซองด้านขวา พร้อมลูกปืน 12-Gauge สีแดงทองด้านใน
        addPart("EjectionPort", Vector3.new(0.06, 0.22, 0.65), Color3.fromRGB(15, 15, 18), Enum.Material.Metal, CFrame.new(0.16, 0.12, -0.15))
        addPart("ChamberShellRed", Vector3.new(0.08, 0.14, 0.40), shellRed, Enum.Material.SmoothPlastic, CFrame.new(0.14, 0.12, -0.15))
        addPart("ChamberShellBrass", Vector3.new(0.08, 0.14, 0.12), shellBrass, Enum.Material.Metal, CFrame.new(0.14, 0.12, 0.08))

        -- ด้ามจับและพานท้ายปืนลูกซองโพลีเมอร์ตัน (Tactical Shotgun Stock & Grip)
        addPart("Grip", Vector3.new(0.28, 0.85, 0.38), darkPolymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.48, 0.45) * CFrame.Angles(math.rad(-18), 0, 0))
        addPart("StockWrist", Vector3.new(0.26, 0.40, 0.8), darkPolymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.05, 1.15))
        addPart("StockButt", Vector3.new(0.30, 0.75, 1.1), darkPolymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.12, 1.95))
        addPart("RecoilPad", Vector3.new(0.32, 0.78, 0.20), Color3.fromRGB(18, 18, 20), Enum.Material.Rubber, CFrame.new(0, -0.12, 2.55))

        -- ศูนย์หน้าลูกปัดกลม (Bead Sight)
        addPart("BeadSight", Vector3.new(0.06, 0.10, 0.06), Color3.fromRGB(255, 150, 40), Enum.Material.Neon, CFrame.new(0, 0.28, -3.2))

        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 190, 50), Enum.Material.Neon, CFrame.new(0, 0.12, -3.35), true)

    ------------------------------------------------------------------
    -- 🥁 7. JUDGE (Automatic Revolving Drum Shotgun)
    -- ปืนลูกซองออโตเมติก ดรัมแม็กกาซีนทรงกระบอกลูกโม่ยักษ์
    ------------------------------------------------------------------
    elseif wName == "JUDGE" or (weaponConfig.Type == "Shotgun" and weaponConfig.FiringType == "Auto") then
        local combatBlack = Color3.fromRGB(24, 26, 30)
        local darkGunmetal = Color3.fromRGB(42, 45, 52)
        local redAccent = Color3.fromRGB(240, 55, 55)

        -- ลำตัวปืนลูกซองออโตเมติกทรงเหลี่ยมบึกบึน (Heavy Combat Receiver)
        addPart("Receiver", Vector3.new(0.38, 0.58, 1.7), combatBlack, Enum.Material.Metal, CFrame.new(0, 0, 0))
        addPart("TopRail", Vector3.new(0.28, 0.10, 1.8), darkGunmetal, Enum.Material.Metal, CFrame.new(0, 0.32, -0.2))

        -- 🥁 ดรัมแม็กกาซีนทรงกระบอกลูกโม่ยักษ์ใต้ปืน (Iconic Revolving Drum Cylinder)
        addPart("DrumCore", Vector3.new(0.55, 0.55, 0.85), darkGunmetal, Enum.Material.Metal, CFrame.new(0, -0.32, -0.25))
        addPart("DrumFrontRing", Vector3.new(0.58, 0.58, 0.12), redAccent, Enum.Material.Metal, CFrame.new(0, -0.32, -0.70))
        addPart("DrumRearRing", Vector3.new(0.58, 0.58, 0.12), redAccent, Enum.Material.Metal, CFrame.new(0, -0.32, 0.20))
        -- ร่องบรรจุลูกซองรอบดรัม (Flutes)
        addPart("DrumFluteL", Vector3.new(0.12, 0.40, 0.80), combatBlack, Enum.Material.Metal, CFrame.new(-0.24, -0.32, -0.25))
        addPart("DrumFluteR", Vector3.new(0.12, 0.40, 0.80), combatBlack, Enum.Material.Metal, CFrame.new(0.24, -0.32, -0.25))

        -- ลำกล้องลูกซองหนาพิเศษ (Heavy Combat Shotgun Barrel)
        addPart("Barrel", Vector3.new(0.26, 0.26, 1.8), darkGunmetal, Enum.Material.Metal, CFrame.new(0, 0.12, -1.6))
        -- ปากกระบอกคอมเพนเซเตอร์ลูกซองเจาะรูกระจายแรง (Perforated Shotgun Muzzle Brake)
        addPart("ShotgunBrake", Vector3.new(0.34, 0.34, 0.55), combatBlack, Enum.Material.Metal, CFrame.new(0, 0.12, -2.55))
        addPart("BrakeVentL", Vector3.new(0.06, 0.24, 0.35), redAccent, Enum.Material.Neon, CFrame.new(-0.16, 0.12, -2.55))
        addPart("BrakeVentR", Vector3.new(0.06, 0.24, 0.35), redAccent, Enum.Material.Neon, CFrame.new(0.16, 0.12, -2.55))

        -- ด้ามจับหน้าแนวดิ่งสำหรับคุมแรงดีด (Tactical Foregrip)
        addPart("Foregrip", Vector3.new(0.20, 0.65, 0.28), combatBlack, Enum.Material.DiamondPlate, CFrame.new(0, -0.44, -1.25) * CFrame.Angles(math.rad(-8), 0, 0))

        -- ด้ามจับหลักและพานท้าย CQB ขนาดกะทัดรัด
        addPart("Grip", Vector3.new(0.28, 0.85, 0.40), combatBlack, Enum.Material.SmoothPlastic, CFrame.new(0, -0.48, 0.50) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("CQBStock", Vector3.new(0.32, 0.70, 1.2), darkGunmetal, Enum.Material.Metal, CFrame.new(0, -0.05, 1.35))
        addPart("StockPad", Vector3.new(0.34, 0.75, 0.18), combatBlack, Enum.Material.Rubber, CFrame.new(0, -0.05, 2.0))

        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 170, 45), Enum.Material.Neon, CFrame.new(0, 0.12, -2.90), true)

    ------------------------------------------------------------------
    -- 💥 8. SHORTY (Double-Barrel Break-Action Sawed-Off Sidearm)
    ------------------------------------------------------------------
    elseif wName == "SHORTY" then
        local woodStock = Color3.fromRGB(75, 45, 30)
        local bluedSteel = Color3.fromRGB(38, 40, 46)
        local brassBand = Color3.fromRGB(200, 160, 50)

        -- ลำกล้องคู่แฝด (Side-by-Side Twin Barrels)
        addPart("BarrelLeft", Vector3.new(0.16, 0.16, 1.5), bluedSteel, Enum.Material.Metal, CFrame.new(-0.09, 0.08, -1.0))
        addPart("BarrelRight", Vector3.new(0.16, 0.16, 1.5), bluedSteel, Enum.Material.Metal, CFrame.new(0.09, 0.08, -1.0))
        addPart("BarrelRib", Vector3.new(0.08, 0.08, 1.4), bluedSteel, Enum.Material.Metal, CFrame.new(0, 0.14, -1.0))

        -- โครงห้องลูกเลื่อนหักลำ (Break-Action Receiver)
        addPart("Receiver", Vector3.new(0.32, 0.42, 0.9), bluedSteel, Enum.Material.Metal, CFrame.new(0, 0, -0.1))
        addPart("HingePin", Vector3.new(0.34, 0.12, 0.12), brassBand, Enum.Material.Metal, CFrame.new(0, -0.10, -0.4))
        addPart("TopSnapLever", Vector3.new(0.08, 0.14, 0.25), bluedSteel, Enum.Material.Metal, CFrame.new(0, 0.25, 0.15) * CFrame.Angles(math.rad(15), 0, 0))

        -- ประกับมือไม้สั้นใต้ลำกล้อง (Wood Forend)
        addPart("Forend", Vector3.new(0.30, 0.22, 0.8), woodStock, Enum.Material.Wood, CFrame.new(0, -0.08, -0.85))

        -- ด้ามจับไม้หางนกตัดสั้น (Sawed-Off Birdshead Pistol Grip)
        addPart("GripSawed", Vector3.new(0.26, 0.68, 0.42), woodStock, Enum.Material.Wood, CFrame.new(0, -0.42, 0.40) * CFrame.Angles(math.rad(-28), 0, 0))

        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 180, 50), Enum.Material.Neon, CFrame.new(0, 0.08, -1.8), true)

    ------------------------------------------------------------------
    -- 🔫 9. CLASSIC (Valorant Starter Sidearm)
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

        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 210, 80), Enum.Material.Neon, CFrame.new(0, 0.10, -1.05), true)

    ------------------------------------------------------------------
    -- 🔫 10. ปืนอื่นๆ ทั่วไป (Fallback Procedural)
    ------------------------------------------------------------------
    else
        addPart("Receiver", Vector3.new(0.34, 0.52, 1.8), pCol, Enum.Material.Metal, CFrame.new(0, 0, 0))
        addPart("Cover", Vector3.new(0.30, 0.18, 1.5), aCol, Enum.Material.SmoothPlastic, CFrame.new(0, 0.30, 0))
        addPart("Barrel", Vector3.new(0.18, 0.18, 2.2), Color3.fromRGB(25, 25, 28), Enum.Material.Metal, CFrame.new(0, 0.05, -1.6))
        addPart("Magazine", Vector3.new(0.24, 0.85, 0.45), aCol, Enum.Material.SmoothPlastic, CFrame.new(0, -0.45, -0.15))
        addPart("Grip", Vector3.new(0.30, 0.85, 0.42), Color3.fromRGB(30, 32, 36), Enum.Material.SmoothPlastic, CFrame.new(0, -0.45, 0.40) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("Stock", Vector3.new(0.32, 0.80, 1.6), pCol, Enum.Material.Metal, CFrame.new(0, -0.05, 1.45))
        addPart("FrontSight", Vector3.new(0.06, 0.12, 0.06), Color3.fromRGB(50, 255, 120), Enum.Material.Neon, CFrame.new(0, 0.42, -2.6))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 200, 50), Enum.Material.Neon, CFrame.new(0, 0.05, -2.8), true)
    end

    ------------------------------------------------------------------
    -- 🌟 11. ระบบประกายไฟปากกระบอก 3D STARBURST & POINTLIGHT กำลังสูง
    ------------------------------------------------------------------
    local muzzleFlashParts = {}
    local flashLight = nil
    local smokeEmitter = nil

    if muzzleFlashPart then
        local mCF = weaponParts[muzzleFlashPart] or CFrame.new(0, 0, -2.5)
        local isShotgun = (weaponConfig.Type == "Shotgun")
        local isSniper = (weaponConfig.IsSniper == true)
        local isSuppressed = (weaponConfig.Audio and weaponConfig.Audio.Silenced) or false

        -- ซ่อน Anchor เล็ก
        muzzleFlashPart.Transparency = 1

        -- 1. ลูกไฟแกนกลางขาวสว่างจ้า (White-Hot Plasma Flash Core)
        local flashCore = Instance.new("Part")
        flashCore.Name = "MuzzleFlashCore"
        flashCore.Shape = Enum.PartType.Ball
        flashCore.Size = isShotgun and Vector3.new(0.65, 0.65, 0.65) or (isSniper and Vector3.new(0.55, 0.55, 0.55) or Vector3.new(0.40, 0.40, 0.40))
        flashCore.Color = Color3.fromRGB(255, 255, 240)
        flashCore.Material = Enum.Material.Neon
        flashCore.CanCollide = false
        flashCore.Anchored = true
        flashCore.CastShadow = false
        flashCore.Transparency = 1
        flashCore.Parent = parentModel

        local coreCF = mCF * CFrame.new(0, 0, -0.15)
        weaponParts[flashCore] = coreCF
        table.insert(muzzleFlashParts, flashCore)

        -- 2. แฉกเปลวไฟแนวนอน (Horizontal Flame Starburst)
        local flameH = Instance.new("Part")
        flameH.Name = "MuzzleFlashFlameH"
        flameH.Size = isShotgun and Vector3.new(1.35, 0.32, 1.05) or (isSniper and Vector3.new(1.40, 0.28, 0.90) or Vector3.new(0.95, 0.22, 0.70))
        flameH.Color = isSuppressed and Color3.fromRGB(80, 220, 255) or Color3.fromRGB(255, 175, 40)
        flameH.Material = Enum.Material.Neon
        flameH.CanCollide = false
        flameH.Anchored = true
        flameH.CastShadow = false
        flameH.Transparency = 1
        flameH.Parent = parentModel

        weaponParts[flameH] = coreCF
        table.insert(muzzleFlashParts, flameH)

        -- 3. แฉกเปลวไฟแนวตั้ง (Vertical Flame Starburst)
        local flameV = Instance.new("Part")
        flameV.Name = "MuzzleFlashFlameV"
        flameV.Size = isShotgun and Vector3.new(0.32, 1.35, 1.05) or (isSniper and Vector3.new(0.28, 1.40, 0.90) or Vector3.new(0.22, 0.95, 0.70))
        flameV.Color = isSuppressed and Color3.fromRGB(80, 220, 255) or Color3.fromRGB(255, 130, 25)
        flameV.Material = Enum.Material.Neon
        flameV.CanCollide = false
        flameV.Anchored = true
        flameV.CastShadow = false
        flameV.Transparency = 1
        flameV.Parent = parentModel

        weaponParts[flameV] = coreCF
        table.insert(muzzleFlashParts, flameV)

        -- 4. ดวงไฟ PointLight กำลังสูง สาดส่องแสงสว่างชัดเจนแม้เวลากลางวัน
        flashLight = Instance.new("PointLight")
        flashLight.Name = "MuzzlePointLight"
        flashLight.Color = isSuppressed and Color3.fromRGB(100, 220, 255) or Color3.fromRGB(255, 195, 75)
        flashLight.Range = isShotgun and 40 or (isSniper and 45 or 32)
        flashLight.Brightness = 0
        flashLight.Shadows = true
        flashLight.Parent = flashCore

        -- 5. ควันปืนลอยละล่องจางๆ (Muzzle Smoke Puff)
        smokeEmitter = Instance.new("ParticleEmitter")
        smokeEmitter.Name = "MuzzleSmoke"
        smokeEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
        smokeEmitter.Color = ColorSequence.new(Color3.fromRGB(190, 190, 200))
        smokeEmitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.25),
            NumberSequenceKeypoint.new(1, 0.95)
        })
        smokeEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.35),
            NumberSequenceKeypoint.new(1, 1.0)
        })
        smokeEmitter.Lifetime = NumberRange.new(0.3, 0.5)
        smokeEmitter.Rate = 0
        smokeEmitter.Speed = NumberRange.new(2, 6)
        smokeEmitter.SpreadAngle = Vector2.new(20, 20)
        smokeEmitter.Enabled = false
        smokeEmitter.Parent = flashCore
    end

    return weaponParts, muzzleFlashParts, flashLight, smokeEmitter
end

return WeaponModelBuilder
