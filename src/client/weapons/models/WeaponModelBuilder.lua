--[[
    WeaponModelBuilder.lua
    โมดูลสร้างโมเดลปืน 3D ความละเอียดสูงครบทั้ง 18 กระบอก (Cylinders + Wedges + Picatinny Rails)
    พร้อมการจัดกลุ่มชิ้นส่วนเคลื่อนไหวสำหรับแอนิเมชันจริง (Body, Magazine, Bolt, Pump, Cylinder, Muzzle)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponModelBuilder = {}

function WeaponModelBuilder.build(parentModel, weaponConfig, gunRoot)
    local weaponParts = {}
    local partGroups = {
        Magazine = {},
        Bolt = {},
        Pump = {},
        Cylinder = {},
    }
    local muzzleFlashPart = nil

    local wName = (weaponConfig.Name or ""):upper()
    local vis = weaponConfig.Visual or {}
    local pCol = vis.PrimaryColor or Color3.fromRGB(34, 38, 46)
    local aCol = vis.AccentColor or Color3.fromRGB(255, 130, 35)

    -- รองรับกรณีนำเข้าโมเดลสำเร็จรูปจาก ReplicatedStorage
    local customTemplate = ReplicatedStorage:FindFirstChild((weaponConfig.Name or "") .. "_Model")
        or ReplicatedStorage:FindFirstChild(weaponConfig.Name or "")
    if customTemplate and customTemplate:IsA("Model") then
        local realGun = customTemplate:Clone()
        realGun.Parent = parentModel
        for _, p in ipairs(realGun:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
                p.CanQuery = false
                p.CanTouch = false
                p.Anchored = true
                p.CastShadow = false
                weaponParts[p] = gunRoot.CFrame:ToObjectSpace(p.CFrame)
                if p.Name:match("Mag") then partGroups.Magazine[p] = true end
                if p.Name:match("Bolt") or p.Name:match("Slide") then partGroups.Bolt[p] = true end
                if p.Name:match("Pump") then partGroups.Pump[p] = true end
                if p.Name:match("Cylinder") then partGroups.Cylinder[p] = true end
                if p.Name:match("Muzzle") or p.Name:match("Flash") then muzzleFlashPart = p end
            end
        end
        return weaponParts, (muzzleFlashPart and { muzzleFlashPart } or {}), nil, nil, partGroups
    end

    -- ----------------------------------------------------------------
    -- Geometry Helpers
    -- ----------------------------------------------------------------
    local function addPart(name, size, color, material, relCF, opts)
        opts = opts or {}
        local p = (opts.className == "WedgePart") and Instance.new("WedgePart") or Instance.new("Part")
        if p:IsA("Part") and opts.shape then
            p.Shape = opts.shape
        end
        p.Name = name
        p.Size = size
        p.Color = color
        p.Material = material or Enum.Material.Metal
        p.Transparency = opts.transparency or 0
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.Anchored = true
        p.CastShadow = false
        p.Parent = parentModel

        weaponParts[p] = relCF
        if opts.group and partGroups[opts.group] then
            partGroups[opts.group][p] = true
        end
        if opts.isMuzzle then
            muzzleFlashPart = p
        end
        return p
    end

    local function addCylZ(name, length, dia, color, mat, relCF, opts)
        opts = opts or {}
        opts.shape = Enum.PartType.Cylinder
        return addPart(name, Vector3.new(length, dia, dia), color, mat, relCF * CFrame.Angles(0, math.rad(90), 0), opts)
    end

    local function addCylX(name, length, dia, color, mat, relCF, opts)
        opts = opts or {}
        opts.shape = Enum.PartType.Cylinder
        return addPart(name, Vector3.new(length, dia, dia), color, mat, relCF, opts)
    end

    local function addCylY(name, height, dia, color, mat, relCF, opts)
        opts = opts or {}
        opts.shape = Enum.PartType.Cylinder
        return addPart(name, Vector3.new(height, dia, dia), color, mat, relCF * CFrame.Angles(0, 0, math.rad(90)), opts)
    end

    local function addWedge(name, size, color, mat, relCF, opts)
        opts = opts or {}
        opts.className = "WedgePart"
        return addPart(name, size, color, mat, relCF, opts)
    end

    local function addPicatinnyRail(prefix, zStart, zEnd, yPos, width, color, step)
        step = step or 0.14
        local i = 0
        local z = zStart
        while z >= zEnd do
            i = i + 1
            addPart(prefix .. "_Tooth_" .. i, Vector3.new(width, 0.045, step * 0.55), color, Enum.Material.Metal, CFrame.new(0, yPos, z))
            z = z - step
        end
    end

    -- Open Reflex / Holographic Sight aligned cleanly on ADS axis (no center occlusion)
    local function addReflexOptic(prefix, baseY, zCenter, frameCol, dotCol)
        addPart(prefix .. "_Mount", Vector3.new(0.20, 0.05, 0.34), frameCol, Enum.Material.Metal, CFrame.new(0, baseY - 0.075, zCenter))
        addPart(prefix .. "_PillarL", Vector3.new(0.035, 0.16, 0.18), frameCol, Enum.Material.Metal, CFrame.new(-0.095, baseY + 0.02, zCenter))
        addPart(prefix .. "_PillarR", Vector3.new(0.035, 0.16, 0.18), frameCol, Enum.Material.Metal, CFrame.new(0.095, baseY + 0.02, zCenter))
        addPart(prefix .. "_HoodTop", Vector3.new(0.22, 0.03, 0.18), frameCol, Enum.Material.Metal, CFrame.new(0, baseY + 0.105, zCenter))
        addPart(prefix .. "_Lens", Vector3.new(0.16, 0.14, 0.02), Color3.fromRGB(110, 210, 235), Enum.Material.Glass, CFrame.new(0, baseY + 0.02, zCenter), { transparency = 0.82 })
        addPart(prefix .. "_Dot", Vector3.new(0.022, 0.022, 0.022), dotCol, Enum.Material.Neon, CFrame.new(0, baseY + 0.02, zCenter - 0.01))
    end

    -- Multi-stage Cylindrical Scope
    local function addTelescopicScope(prefix, centerY, centerZ, tubeCol, accentCol, scale)
        scale = scale or 1.0
        addPart(prefix .. "_RingF", Vector3.new(0.22 * scale, 0.24 * scale, 0.14 * scale), tubeCol, Enum.Material.Metal, CFrame.new(0, centerY - 0.16 * scale, centerZ - 0.45 * scale))
        addPart(prefix .. "_RingR", Vector3.new(0.22 * scale, 0.24 * scale, 0.14 * scale), tubeCol, Enum.Material.Metal, CFrame.new(0, centerY - 0.16 * scale, centerZ + 0.35 * scale))
        addCylZ(prefix .. "_Tube", 1.75 * scale, 0.24 * scale, tubeCol, Enum.Material.Metal, CFrame.new(0, centerY, centerZ))
        addCylZ(prefix .. "_ObjBell", 0.50 * scale, 0.34 * scale, tubeCol, Enum.Material.Metal, CFrame.new(0, centerY, centerZ - 0.95 * scale))
        addCylZ(prefix .. "_ObjRing", 0.08 * scale, 0.36 * scale, accentCol, Enum.Material.Neon, CFrame.new(0, centerY, centerZ - 1.18 * scale))
        addCylZ(prefix .. "_LensF", 0.04 * scale, 0.28 * scale, Color3.fromRGB(60, 150, 220), Enum.Material.Glass, CFrame.new(0, centerY, centerZ - 1.20 * scale), { transparency = 0.35 })
        addCylZ(prefix .. "_EyeBell", 0.36 * scale, 0.30 * scale, tubeCol, Enum.Material.SmoothPlastic, CFrame.new(0, centerY, centerZ + 0.92 * scale))
        addCylY(prefix .. "_TurretTop", 0.12 * scale, 0.12 * scale, accentCol, Enum.Material.Metal, CFrame.new(0, centerY + 0.16 * scale, centerZ - 0.05 * scale))
        addCylX(prefix .. "_TurretSide", 0.12 * scale, 0.11 * scale, accentCol, Enum.Material.Metal, CFrame.new(0.16 * scale, centerY, centerZ - 0.05 * scale))
    end

    local function addBoxMagWithBrass(prefix, size, bodyCol, plateCol, brassCol, relCF)
        addPart(prefix .. "_Body", size, bodyCol, Enum.Material.SmoothPlastic, relCF, { group = "Magazine" })
        addPart(prefix .. "_BasePlate", Vector3.new(size.X + 0.03, 0.08, size.Z + 0.04), plateCol, Enum.Material.Metal, relCF * CFrame.new(0, -size.Y * 0.5 - 0.03, 0), { group = "Magazine" })
        addCylZ(prefix .. "_BrassTop", size.Z * 0.72, 0.075, brassCol, Enum.Material.Metal, relCF * CFrame.new(0, size.Y * 0.5 + 0.01, -0.02), { group = "Magazine" })
    end

    local function addPistolIronSights(topY, frontZ, rearZ, glowCol, frameCol)
        addPart("FrontSightPost", Vector3.new(0.036, 0.075, 0.055), frameCol, Enum.Material.Metal, CFrame.new(0, topY + 0.03, frontZ))
        addPart("FrontSightDot", Vector3.new(0.024, 0.035, 0.02), glowCol, Enum.Material.Neon, CFrame.new(0, topY + 0.045, frontZ + 0.02))
        addPart("RearSightL", Vector3.new(0.05, 0.065, 0.07), frameCol, Enum.Material.Metal, CFrame.new(-0.055, topY + 0.025, rearZ))
        addPart("RearSightR", Vector3.new(0.05, 0.065, 0.07), frameCol, Enum.Material.Metal, CFrame.new(0.055, topY + 0.025, rearZ))
        addPart("RearDotL", Vector3.new(0.02, 0.024, 0.02), glowCol, Enum.Material.Neon, CFrame.new(-0.055, topY + 0.032, rearZ + 0.032))
        addPart("RearDotR", Vector3.new(0.02, 0.024, 0.02), glowCol, Enum.Material.Neon, CFrame.new(0.055, topY + 0.032, rearZ + 0.032))
    end

    local darkMetal = Color3.fromRGB(28, 31, 37)
    local steelMid  = Color3.fromRGB(54, 59, 68)
    local brightStl = Color3.fromRGB(168, 174, 184)
    local polymer   = Color3.fromRGB(24, 26, 31)
    local brassCol  = Color3.fromRGB(218, 176, 68)
    local walnutWood = Color3.fromRGB(96, 56, 34)

    -- ----------------------------------------------------------------
    -- 1. VANDAL (AK-style Futuristic 7.62 Assault Rifle)
    -- ----------------------------------------------------------------
    if wName == "VANDAL" then
        local orange = Color3.fromRGB(245, 112, 32)
        addPart("Receiver", Vector3.new(0.30, 0.40, 1.72), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0.04))
        addWedge("ReceiverFrontSlope", Vector3.new(0.30, 0.16, 0.42), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.28, -0.58) * CFrame.Angles(0, math.rad(180), 0))
        addPart("DustCover", Vector3.new(0.25, 0.14, 1.38), steelMid, Enum.Material.Metal, CFrame.new(0, 0.27, 0.15))
        addPicatinnyRail("VandalRail", 0.72, -0.45, 0.36, 0.18, darkMetal, 0.14)
        addPart("EjectionPort", Vector3.new(0.05, 0.13, 0.48), Color3.fromRGB(14, 15, 18), Enum.Material.Metal, CFrame.new(0.14, 0.18, -0.05))
        -- Animated Charging Handle + Bolt Carrier
        addPart("BoltCarrier", Vector3.new(0.06, 0.10, 0.44), brightStl, Enum.Material.Metal, CFrame.new(0.15, 0.18, -0.04), { group = "Bolt" })
        addCylX("ChargingHandle", 0.22, 0.065, brightStl, Enum.Material.Metal, CFrame.new(0.22, 0.18, -0.18), { group = "Bolt" })

        -- Gas tube + Wood/Carbon handguard
        addCylZ("GasTube", 1.35, 0.16, darkMetal, Enum.Material.Metal, CFrame.new(0, 0.22, -1.38))
        addPart("HandguardWood", Vector3.new(0.31, 0.26, 1.28), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.02, -1.38))
        addPart("HandguardVentL", Vector3.new(0.03, 0.05, 0.95), orange, Enum.Material.Neon, CFrame.new(-0.16, 0.04, -1.38))
        addPart("HandguardVentR", Vector3.new(0.03, 0.05, 0.95), orange, Enum.Material.Neon, CFrame.new(0.16, 0.04, -1.38))

        -- Cylindrical barrel + Muzzle Brake + AK Iron Sight at ADS Y=0.41
        addCylZ("Barrel", 1.95, 0.135, steelMid, Enum.Material.Metal, CFrame.new(0, 0.08, -2.28))
        addCylZ("MuzzleBrake", 0.44, 0.21, darkMetal, Enum.Material.Metal, CFrame.new(0, 0.08, -3.28))
        addPart("BrakeSlot", Vector3.new(0.23, 0.07, 0.22), Color3.fromRGB(12, 12, 14), Enum.Material.Metal, CFrame.new(0, 0.08, -3.28))
        addPart("FrontSightWingL", Vector3.new(0.03, 0.20, 0.12), steelMid, Enum.Material.Metal, CFrame.new(-0.065, 0.30, -2.92))
        addPart("FrontSightWingR", Vector3.new(0.03, 0.20, 0.12), steelMid, Enum.Material.Metal, CFrame.new(0.065, 0.30, -2.92))
        addPart("FrontSightPost", Vector3.new(0.025, 0.16, 0.03), Color3.fromRGB(0, 255, 145), Enum.Material.Neon, CFrame.new(0, 0.34, -2.92))
        addPart("RearSightNotchL", Vector3.new(0.045, 0.07, 0.08), darkMetal, Enum.Material.Metal, CFrame.new(-0.055, 0.39, 0.62))
        addPart("RearSightNotchR", Vector3.new(0.045, 0.07, 0.08), darkMetal, Enum.Material.Metal, CFrame.new(0.055, 0.39, 0.62))

        -- Curved Banana Magazine ("Magazine")
        addPart("MagUpper", Vector3.new(0.22, 0.56, 0.42), orange, Enum.Material.SmoothPlastic, CFrame.new(0, -0.38, -0.22) * CFrame.Angles(math.rad(-10), 0, 0), { group = "Magazine" })
        addPart("MagLower", Vector3.new(0.21, 0.52, 0.40), darkMetal, Enum.Material.Metal, CFrame.new(0, -0.74, -0.37) * CFrame.Angles(math.rad(-26), 0, 0), { group = "Magazine" })
        addPart("MagFloor", Vector3.new(0.23, 0.08, 0.44), orange, Enum.Material.Neon, CFrame.new(0, -0.97, -0.49) * CFrame.Angles(math.rad(-26), 0, 0), { group = "Magazine" })
        addCylZ("MagBrassRound", 0.30, 0.08, brassCol, Enum.Material.Metal, CFrame.new(0, -0.10, -0.19), { group = "Magazine" })

        -- Ergonomic Grip & Skeletonized Stock
        addPart("Grip", Vector3.new(0.24, 0.78, 0.36), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.46, 0.46) * CFrame.Angles(math.rad(-18), 0, 0))
        addPart("TriggerGuard", Vector3.new(0.10, 0.22, 0.34), darkMetal, Enum.Material.Metal, CFrame.new(0, -0.26, 0.16))
        addPart("StockTopBar", Vector3.new(0.18, 0.14, 1.35), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.04, 1.52))
        addPart("StockBotStrut", Vector3.new(0.14, 0.12, 1.30), steelMid, Enum.Material.Metal, CFrame.new(0, -0.16, 1.52) * CFrame.Angles(math.rad(-10), 0, 0))
        addPart("StockButt", Vector3.new(0.26, 0.72, 0.24), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.12, 2.24))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), orange, Enum.Material.Neon, CFrame.new(0, 0.08, -3.55), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 2. PHANTOM (Integrally Suppressed Tactical Carbine)
    -- ----------------------------------------------------------------
    elseif wName == "PHANTOM" then
        local cyan = Color3.fromRGB(0, 225, 255)
        addPart("LowerReceiver", Vector3.new(0.30, 0.26, 1.48), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.06, 0.04))
        addPart("UpperReceiver", Vector3.new(0.28, 0.24, 1.50), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.16, 0.02))
        addPicatinnyRail("PhantomRail", 0.65, -0.82, 0.30, 0.18, steelMid, 0.13)
        addReflexOptic("PhantomReflex", 0.38, -0.15, darkMetal, cyan)
        addPart("BoltCarrier", Vector3.new(0.05, 0.11, 0.42), brightStl, Enum.Material.Metal, CFrame.new(0.14, 0.17, -0.10), { group = "Bolt" })
        addPart("ChargingLatch", Vector3.new(0.24, 0.06, 0.14), cyan, Enum.Material.Metal, CFrame.new(0, 0.24, 0.74), { group = "Bolt" })

        -- Handguard + Thick Cylindrical Suppressor
        addPart("Handguard", Vector3.new(0.31, 0.34, 1.10), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, 0.06, -1.18))
        addPart("SideAccentL", Vector3.new(0.03, 0.05, 1.25), cyan, Enum.Material.Neon, CFrame.new(-0.16, 0.11, -0.18))
        addPart("SideAccentR", Vector3.new(0.03, 0.05, 1.25), cyan, Enum.Material.Neon, CFrame.new(0.16, 0.11, -0.18))
        addCylZ("SuppressorBody", 1.85, 0.34, darkMetal, Enum.Material.SmoothPlastic, CFrame.new(0, 0.09, -2.55))
        addCylZ("SuppressorCollar", 0.16, 0.37, steelMid, Enum.Material.Metal, CFrame.new(0, 0.09, -1.72))
        addCylZ("SuppressorRingTip", 0.12, 0.30, cyan, Enum.Material.Neon, CFrame.new(0, 0.09, -3.45))

        -- Windowed PMAG ("Magazine")
        addBoxMagWithBrass("PhantomMag", Vector3.new(0.22, 0.80, 0.38), polymer, steelMid, brassCol, CFrame.new(0, -0.48, -0.22) * CFrame.Angles(math.rad(-8), 0, 0))
        addPart("MagWindowGlow", Vector3.new(0.23, 0.38, 0.08), cyan, Enum.Material.Neon, CFrame.new(0, -0.48, -0.22) * CFrame.Angles(math.rad(-8), 0, 0), { group = "Magazine" })

        addPart("Grip", Vector3.new(0.25, 0.76, 0.36), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.44, 0.42) * CFrame.Angles(math.rad(-16), 0, 0))
        addCylZ("BufferTube", 1.15, 0.19, steelMid, Enum.Material.Metal, CFrame.new(0, 0.06, 1.32))
        addWedge("StockCheek", Vector3.new(0.26, 0.36, 0.90), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, 0.02, 1.55) * CFrame.Angles(0, math.rad(180), 0))
        addPart("StockPad", Vector3.new(0.28, 0.62, 0.28), darkMetal, Enum.Material.Rubber, CFrame.new(0, -0.06, 1.98))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), cyan, Enum.Material.Neon, CFrame.new(0, 0.09, -3.58), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 3. BULLDOG (Bullpup Combat Rifle)
    -- ----------------------------------------------------------------
    elseif wName == "BULLDOG" then
        local olive = Color3.fromRGB(68, 92, 68)
        local mint = Color3.fromRGB(90, 235, 130)
        addPart("BullpupChassis", Vector3.new(0.34, 0.48, 2.30), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0.25))
        addPart("ChassisSideArmor", Vector3.new(0.36, 0.28, 1.65), olive, Enum.Material.SmoothPlastic, CFrame.new(0, 0.04, 0.10))
        addPicatinnyRail("BulldogRail", 0.80, -0.80, 0.28, 0.18, steelMid, 0.14)
        addReflexOptic("BulldogHolo", 0.39, -0.10, darkMetal, mint)
        addPart("ChargingHandle", Vector3.new(0.16, 0.08, 0.14), brightStl, Enum.Material.Metal, CFrame.new(-0.20, 0.18, -0.62), { group = "Bolt" })

        addCylZ("Barrel", 1.45, 0.15, steelMid, Enum.Material.Metal, CFrame.new(0, 0.08, -1.42))
        addCylZ("FlashHider", 0.32, 0.21, darkMetal, Enum.Material.Metal, CFrame.new(0, 0.08, -2.20))
        -- Rear Bullpup Magazine behind Grip
        addBoxMagWithBrass("BulldogMag", Vector3.new(0.22, 0.72, 0.38), polymer, olive, brassCol, CFrame.new(0, -0.45, 0.92) * CFrame.Angles(math.rad(-6), 0, 0))
        addPart("Grip", Vector3.new(0.25, 0.75, 0.36), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.44, 0.18) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("ButtPad", Vector3.new(0.32, 0.64, 0.22), polymer, Enum.Material.Rubber, CFrame.new(0, -0.02, 1.48))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), mint, Enum.Material.Neon, CFrame.new(0, 0.08, -2.42), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 4. GUARDIAN (Long Precision DMR)
    -- ----------------------------------------------------------------
    elseif wName == "GUARDIAN" then
        local gold = Color3.fromRGB(225, 190, 85)
        addPart("Receiver", Vector3.new(0.30, 0.42, 1.65), steelMid, Enum.Material.Metal, CFrame.new(0, 0.02, 0.04))
        addPart("Handguard", Vector3.new(0.28, 0.30, 1.45), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.04, -1.35))
        addPart("GoldInlay", Vector3.new(0.32, 0.04, 1.15), gold, Enum.Material.Metal, CFrame.new(0, 0.14, 0.02))
        addPicatinnyRail("GuardRail", 0.72, -1.60, 0.25, 0.16, darkMetal, 0.15)
        addTelescopicScope("GuardScope", 0.42, -0.15, darkMetal, gold, 0.72)
        addPart("BoltCarrier", Vector3.new(0.05, 0.11, 0.44), gold, Enum.Material.Metal, CFrame.new(0.15, 0.15, 0.05), { group = "Bolt" })

        addCylZ("MatchBarrel", 2.40, 0.15, steelMid, Enum.Material.Metal, CFrame.new(0, 0.08, -2.65))
        addCylZ("PrecisionBrake", 0.48, 0.23, darkMetal, Enum.Material.Metal, CFrame.new(0, 0.08, -3.90))
        addBoxMagWithBrass("GuardMag", Vector3.new(0.20, 0.64, 0.42), darkMetal, gold, brassCol, CFrame.new(0, -0.40, -0.24))
        addPart("Grip", Vector3.new(0.24, 0.76, 0.36), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.45, 0.45) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("MarksmanStock", Vector3.new(0.28, 0.68, 1.35), darkMetal, Enum.Material.SmoothPlastic, CFrame.new(0, -0.06, 1.55))
        addPart("CheekRiser", Vector3.new(0.30, 0.16, 0.72), steelMid, Enum.Material.SmoothPlastic, CFrame.new(0, 0.32, 1.48))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), gold, Enum.Material.Neon, CFrame.new(0, 0.08, -4.22), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 5. SPECTRE (Compact Suppressed Tactical SMG)
    -- ----------------------------------------------------------------
    elseif wName == "SPECTRE" then
        local teal = Color3.fromRGB(60, 215, 235)
        addPart("Receiver", Vector3.new(0.28, 0.38, 1.36), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0.05))
        addPart("Handguard", Vector3.new(0.29, 0.32, 0.85), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, 0.04, -0.95))
        addPicatinnyRail("SpecRail", 0.55, -0.75, 0.24, 0.16, steelMid, 0.13)
        addReflexOptic("SpecOptic", 0.38, -0.10, darkMetal, teal)
        addPart("BoltHandle", Vector3.new(0.16, 0.07, 0.12), brightStl, Enum.Material.Metal, CFrame.new(-0.18, 0.16, -0.35), { group = "Bolt" })

        addCylZ("SMGSilencer", 1.35, 0.30, darkMetal, Enum.Material.SmoothPlastic, CFrame.new(0, 0.06, -1.88))
        addCylZ("SilencerRing", 0.10, 0.32, teal, Enum.Material.Neon, CFrame.new(0, 0.06, -2.50))
        -- Angled SMG Stick Magazine ("Magazine")
        addBoxMagWithBrass("SpectreMag", Vector3.new(0.18, 0.82, 0.28), polymer, teal, brassCol, CFrame.new(0, -0.48, -0.32) * CFrame.Angles(math.rad(10), 0, 0))
        addPart("StubbyForegrip", Vector3.new(0.16, 0.34, 0.20), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.26, -0.95))
        addPart("Grip", Vector3.new(0.23, 0.72, 0.32), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.42, 0.36) * CFrame.Angles(math.rad(-16), 0, 0))
        addCylZ("WireStockL", 1.05, 0.06, brightStl, Enum.Material.Metal, CFrame.new(-0.12, 0.04, 1.18))
        addCylZ("WireStockR", 1.05, 0.06, brightStl, Enum.Material.Metal, CFrame.new(0.12, 0.04, 1.18))
        addPart("WireButt", Vector3.new(0.28, 0.45, 0.14), polymer, Enum.Material.Rubber, CFrame.new(0, -0.02, 1.72))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), teal, Enum.Material.Neon, CFrame.new(0, 0.06, -2.62), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 6. STINGER (High-RPM PDW SMG)
    -- ----------------------------------------------------------------
    elseif wName == "STINGER" then
        local ember = Color3.fromRGB(255, 130, 45)
        addPart("Receiver", Vector3.new(0.28, 0.40, 1.18), steelMid, Enum.Material.Metal, CFrame.new(0, 0.02, 0.02))
        addPart("PDWShroud", Vector3.new(0.30, 0.30, 0.75), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.04, -0.82))
        addReflexOptic("StingHolo", 0.38, -0.08, steelMid, ember)
        addPart("SideBoltKnob", Vector3.new(0.14, 0.08, 0.10), ember, Enum.Material.Metal, CFrame.new(-0.18, 0.14, -0.25), { group = "Bolt" })

        addCylZ("ShortBarrel", 0.85, 0.14, darkMetal, Enum.Material.Metal, CFrame.new(0, 0.06, -1.45))
        addCylZ("VentedComp", 0.30, 0.19, steelMid, Enum.Material.Metal, CFrame.new(0, 0.06, -1.96))
        addBoxMagWithBrass("StingerMag", Vector3.new(0.17, 0.90, 0.26), darkMetal, ember, brassCol, CFrame.new(0, -0.52, -0.28) * CFrame.Angles(math.rad(6), 0, 0))
        addPart("Grip", Vector3.new(0.23, 0.72, 0.32), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.42, 0.30) * CFrame.Angles(math.rad(-15), 0, 0))
        addPart("WireStock", Vector3.new(0.22, 0.42, 0.90), darkMetal, Enum.Material.Metal, CFrame.new(0, -0.02, 1.05))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), ember, Enum.Material.Neon, CFrame.new(0, 0.06, -2.18), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 7. BUCKY (Pump-Action 12-Gauge Tactical Shotgun)
    -- ----------------------------------------------------------------
    elseif wName == "BUCKY" then
        local shellRed = Color3.fromRGB(215, 42, 42)
        addPart("Receiver", Vector3.new(0.32, 0.46, 1.56), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0.04))
        addPart("ReceiverTopRib", Vector3.new(0.20, 0.07, 1.45), steelMid, Enum.Material.Metal, CFrame.new(0, 0.27, 0.04))
        addPart("EjectionPort", Vector3.new(0.05, 0.18, 0.56), Color3.fromRGB(14, 15, 18), Enum.Material.Metal, CFrame.new(0.15, 0.10, -0.15))
        addPart("BoltCarrier", Vector3.new(0.06, 0.16, 0.46), brightStl, Enum.Material.Metal, CFrame.new(0.14, 0.10, -0.15), { group = "Bolt" })

        -- Cylindrical 12-Gauge Barrel & Tube Magazine + Heat Shield
        addCylZ("ShotgunBarrel", 2.65, 0.22, steelMid, Enum.Material.Metal, CFrame.new(0, 0.13, -1.96))
        addCylZ("TubeMagazine", 2.25, 0.18, darkMetal, Enum.Material.Metal, CFrame.new(0, -0.09, -1.78))
        addCylZ("TubeCap", 0.20, 0.21, brightStl, Enum.Material.Metal, CFrame.new(0, -0.09, -2.92))
        addPart("HeatShield", Vector3.new(0.25, 0.12, 1.45), steelMid, Enum.Material.Metal, CFrame.new(0, 0.23, -1.48))

        -- Ghost ring + Front bead sight aligned at Y=0.41
        addPart("RearGhostRing", Vector3.new(0.14, 0.14, 0.06), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.37, 0.65))
        addPart("FrontBeadBase", Vector3.new(0.06, 0.14, 0.08), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.30, -3.12))
        addPart("FrontBeadGlow", Vector3.new(0.04, 0.045, 0.04), Color3.fromRGB(255, 155, 40), Enum.Material.Neon, CFrame.new(0, 0.39, -3.12))

        -- Ribbed Pump Slide Forend ("Pump" group moves cleanly back/forward!)
        addPart("PumpSlide", Vector3.new(0.32, 0.28, 1.15), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.10, -1.42), { group = "Pump" })
        addPart("PumpCollar", Vector3.new(0.34, 0.30, 0.10), steelMid, Enum.Material.Metal, CFrame.new(0, -0.10, -0.84), { group = "Pump" })

        -- 4-Shell Left Receiver Side Saddle + Animated Loading Shell ("Magazine")
        for s = 0, 3 do
            local sz = -0.32 + s * 0.20
            addCylY("SideShellRed_" .. s, 0.22, 0.085, shellRed, Enum.Material.SmoothPlastic, CFrame.new(-0.18, 0.04, sz))
            addCylY("SideShellBrass_" .. s, 0.07, 0.09, brassCol, Enum.Material.Metal, CFrame.new(-0.18, -0.09, sz))
        end
        addCylZ("ReloadShellRed", 0.32, 0.095, shellRed, Enum.Material.SmoothPlastic, CFrame.new(0, -0.22, -0.22), { group = "Magazine" })
        addCylZ("ReloadShellBrass", 0.10, 0.10, brassCol, Enum.Material.Metal, CFrame.new(0, -0.22, -0.02), { group = "Magazine" })

        addPart("Grip", Vector3.new(0.25, 0.78, 0.36), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.46, 0.45) * CFrame.Angles(math.rad(-18), 0, 0))
        addPart("StockBody", Vector3.new(0.28, 0.64, 1.45), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.10, 1.55))
        addPart("RecoilPad", Vector3.new(0.30, 0.68, 0.18), Color3.fromRGB(16, 16, 18), Enum.Material.Rubber, CFrame.new(0, -0.10, 2.32))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 190, 55), Enum.Material.Neon, CFrame.new(0, 0.13, -3.35), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 8. JUDGE (Automatic Revolving Drum Shotgun)
    -- ----------------------------------------------------------------
    elseif wName == "JUDGE" then
        local red = Color3.fromRGB(235, 55, 55)
        addPart("Receiver", Vector3.new(0.36, 0.52, 1.65), polymer, Enum.Material.Metal, CFrame.new(0, 0.02, 0.04))
        addPicatinnyRail("JudgeRail", 0.72, -0.82, 0.30, 0.20, steelMid, 0.15)
        addReflexOptic("JudgeSight", 0.39, -0.08, darkMetal, red)
        addPart("BoltHandle", Vector3.new(0.16, 0.08, 0.12), brightStl, Enum.Material.Metal, CFrame.new(0.22, 0.16, -0.10), { group = "Bolt" })

        -- Huge Cylindrical Drum Magazine ("Magazine")
        addCylZ("DrumBody", 0.80, 0.62, steelMid, Enum.Material.Metal, CFrame.new(0, -0.34, -0.25), { group = "Magazine" })
        addCylZ("DrumRingF", 0.10, 0.65, red, Enum.Material.SmoothPlastic, CFrame.new(0, -0.34, -0.64), { group = "Magazine" })
        addCylZ("DrumRingR", 0.10, 0.65, red, Enum.Material.SmoothPlastic, CFrame.new(0, -0.34, 0.14), { group = "Magazine" })

        addCylZ("Barrel", 1.70, 0.24, steelMid, Enum.Material.Metal, CFrame.new(0, 0.12, -1.55))
        addPart("CompBox", Vector3.new(0.32, 0.30, 0.52), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.12, -2.48))
        addPart("CompVentGlowL", Vector3.new(0.04, 0.18, 0.30), red, Enum.Material.Neon, CFrame.new(-0.16, 0.12, -2.48))
        addPart("CompVentGlowR", Vector3.new(0.04, 0.18, 0.30), red, Enum.Material.Neon, CFrame.new(0.16, 0.12, -2.48))
        addPart("VertForegrip", Vector3.new(0.18, 0.56, 0.22), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.38, -1.25))
        addPart("Grip", Vector3.new(0.25, 0.78, 0.38), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.46, 0.48) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("CQBStock", Vector3.new(0.30, 0.64, 1.15), steelMid, Enum.Material.Metal, CFrame.new(0, -0.06, 1.35))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), red, Enum.Material.Neon, CFrame.new(0, 0.12, -2.84), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 9. OPERATOR (.50 Cal Anti-Material Sniper Rifle)
    -- ----------------------------------------------------------------
    elseif wName == "OPERATOR" then
        local opRed = Color3.fromRGB(255, 62, 75)
        addPart("BullpupChassis", Vector3.new(0.36, 0.56, 2.25), polymer, Enum.Material.Metal, CFrame.new(0, -0.02, 0.05))
        addPicatinnyRail("OpRail", 0.80, -0.95, 0.28, 0.20, steelMid, 0.16)
        addTelescopicScope("OpScope", 0.58, -0.24, darkMetal, opRed, 1.05)

        -- Bolt Lever + Ball ("Bolt")
        addCylX("BoltArm", 0.24, 0.06, brightStl, Enum.Material.Metal, CFrame.new(0.24, 0.16, 0.42), { group = "Bolt" })
        addPart("BoltKnob", Vector3.new(0.11, 0.11, 0.11), opRed, Enum.Material.Metal, CFrame.new(0.36, 0.14, 0.45), { group = "Bolt", shape = Enum.PartType.Ball })

        addCylZ("HeavyBarrel", 2.85, 0.21, steelMid, Enum.Material.Metal, CFrame.new(0, 0.09, -2.35))
        addPart("TankBrake", Vector3.new(0.42, 0.30, 0.72), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.09, -3.88))
        addPart("BrakePortL", Vector3.new(0.05, 0.18, 0.44), opRed, Enum.Material.Neon, CFrame.new(-0.21, 0.09, -3.88))
        addPart("BrakePortR", Vector3.new(0.05, 0.18, 0.44), opRed, Enum.Material.Neon, CFrame.new(0.21, 0.09, -3.88))

        addCylZ("BipodL", 1.15, 0.075, steelMid, Enum.Material.Metal, CFrame.new(-0.15, -0.22, -1.50))
        addCylZ("BipodR", 1.15, 0.075, steelMid, Enum.Material.Metal, CFrame.new(0.15, -0.22, -1.50))
        addBoxMagWithBrass("OpMag", Vector3.new(0.25, 0.66, 0.54), darkMetal, opRed, brassCol, CFrame.new(0, -0.45, -0.15))

        addPart("Grip", Vector3.new(0.26, 0.80, 0.38), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.46, 0.55) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("SniperStock", Vector3.new(0.32, 0.74, 1.30), darkMetal, Enum.Material.Metal, CFrame.new(0, -0.05, 1.65))
        addPart("CheekPad", Vector3.new(0.34, 0.18, 0.68), steelMid, Enum.Material.SmoothPlastic, CFrame.new(0, 0.33, 1.48))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 185, 55), Enum.Material.Neon, CFrame.new(0, 0.09, -4.32), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 10. MARSHAL (Lever-Action Scout Sniper Rifle)
    -- ----------------------------------------------------------------
    elseif wName == "MARSHAL" then
        local amber = Color3.fromRGB(205, 155, 70)
        addPart("ScoutReceiver", Vector3.new(0.26, 0.38, 1.35), steelMid, Enum.Material.Metal, CFrame.new(0, 0.02, 0.02))
        addTelescopicScope("MarshalScope", 0.42, -0.10, darkMetal, amber, 0.80)
        addCylZ("ScoutBarrel", 2.75, 0.145, darkMetal, Enum.Material.Metal, CFrame.new(0, 0.11, -1.95))
        addCylZ("UnderTube", 2.30, 0.11, steelMid, Enum.Material.Metal, CFrame.new(0, -0.04, -1.72))
        addPart("WoodForend", Vector3.new(0.26, 0.24, 1.32), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.05, -1.28))

        -- Lever Loop ("Bolt" swings cleanly on shot & reload)
        addPart("LeverLoop", Vector3.new(0.08, 0.30, 0.52), brightStl, Enum.Material.Metal, CFrame.new(0, -0.30, 0.25) * CFrame.Angles(math.rad(-14), 0, 0), { group = "Bolt" })
        addCylZ("MarshalShell", 0.36, 0.08, brassCol, Enum.Material.Metal, CFrame.new(0.13, 0.05, 0.02), { group = "Magazine" })
        addPart("ScoutStock", Vector3.new(0.24, 0.54, 1.75), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.10, 1.48) * CFrame.Angles(math.rad(-6), 0, 0))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), amber, Enum.Material.Neon, CFrame.new(0, 0.11, -3.40), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 11. OUTLAW (Twin-Barrel Heavy Break-Action Sniper)
    -- ----------------------------------------------------------------
    elseif wName == "OUTLAW" then
        local crimson = Color3.fromRGB(240, 65, 65)
        addPart("BreechReceiver", Vector3.new(0.36, 0.44, 1.15), darkMetal, Enum.Material.Metal, CFrame.new(0, 0, 0.15))
        addTelescopicScope("OutlawScope", 0.46, -0.10, darkMetal, crimson, 0.85)
        addCylZ("BarrelL", 2.65, 0.16, steelMid, Enum.Material.Metal, CFrame.new(-0.085, 0.10, -1.68))
        addCylZ("BarrelR", 2.65, 0.16, steelMid, Enum.Material.Metal, CFrame.new(0.085, 0.10, -1.68))
        addPart("BarrelShroud", Vector3.new(0.34, 0.20, 1.15), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.02, -0.95))
        addCylX("HingePin", 0.38, 0.11, crimson, Enum.Material.Metal, CFrame.new(0, -0.08, -0.45))

        addCylZ("ShellL", 0.44, 0.10, brassCol, Enum.Material.Metal, CFrame.new(-0.085, 0.10, -0.35), { group = "Magazine" })
        addCylZ("ShellR", 0.44, 0.10, brassCol, Enum.Material.Metal, CFrame.new(0.085, 0.10, -0.35), { group = "Magazine" })
        addPart("TopLatch", Vector3.new(0.09, 0.10, 0.24), brightStl, Enum.Material.Metal, CFrame.new(0, 0.24, 0.35), { group = "Bolt" })

        addPart("Grip", Vector3.new(0.26, 0.72, 0.38), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.40, 0.56) * CFrame.Angles(math.rad(-20), 0, 0))
        addPart("Stock", Vector3.new(0.30, 0.62, 1.25), darkMetal, Enum.Material.Metal, CFrame.new(0, -0.08, 1.38))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), crimson, Enum.Material.Neon, CFrame.new(0, 0.10, -3.08), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 12. ARES / ODIN (Heavy Squad Machine Guns)
    -- ----------------------------------------------------------------
    elseif wName == "ARES" or wName == "ODIN" then
        local heavyCol = (wName == "ODIN") and Color3.fromRGB(255, 85, 45) or Color3.fromRGB(225, 165, 40)
        addPart("LMGReceiver", Vector3.new(0.42, 0.52, 1.85), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0))
        addPart("FeedCover", Vector3.new(0.38, 0.12, 1.15), steelMid, Enum.Material.Metal, CFrame.new(0, 0.32, 0.05), { group = "Bolt" })
        addReflexOptic("LMGSight", 0.42, 0.10, darkMetal, heavyCol)
        addPart("CarryBar", Vector3.new(0.08, 0.24, 0.90), steelMid, Enum.Material.Metal, CFrame.new(-0.22, 0.36, -0.40))

        -- Barrel(s) & Perforated Shroud
        if wName == "ODIN" then
            addCylZ("RotShroud", 1.65, 0.42, steelMid, Enum.Material.Metal, CFrame.new(0, 0.06, -1.65))
            for _, off in ipairs({ { -0.09, 0.14 }, { 0.09, 0.14 }, { -0.09, -0.02 }, { 0.09, -0.02 } }) do
                addCylZ("MiniBarrel", 2.40, 0.095, darkMetal, Enum.Material.Metal, CFrame.new(off[1], off[2], -2.10))
            end
            addPart("HeatGlowL", Vector3.new(0.04, 0.10, 1.20), heavyCol, Enum.Material.Neon, CFrame.new(-0.22, 0.06, -1.65))
            addPart("HeatGlowR", Vector3.new(0.04, 0.10, 1.20), heavyCol, Enum.Material.Neon, CFrame.new(0.22, 0.06, -1.65))
        else
            addPart("CoolingShroud", Vector3.new(0.34, 0.34, 1.45), steelMid, Enum.Material.Metal, CFrame.new(0, 0.06, -1.55))
            addCylZ("HeavyLMGBarrel", 2.35, 0.17, darkMetal, Enum.Material.Metal, CFrame.new(0, 0.08, -2.05))
            addCylZ("LMGMuzzle", 0.34, 0.23, brightStl, Enum.Material.Metal, CFrame.new(0, 0.08, -3.28))
        end

        -- Exposed Ammo Belt Links + Heavy Drum Box ("Magazine")
        addPart("AmmoDrumBox", Vector3.new(0.56, 0.58, 0.72), darkMetal, Enum.Material.Metal, CFrame.new(-0.10, -0.50, -0.25), { group = "Magazine" })
        addPart("DrumAccent", Vector3.new(0.58, 0.12, 0.74), heavyCol, Enum.Material.Neon, CFrame.new(-0.10, -0.50, -0.25), { group = "Magazine" })
        for b = 0, 3 do
            addCylZ("AmmoBelt_" .. b, 0.24, 0.065, brassCol, Enum.Material.Metal, CFrame.new(-0.24, -0.18 + b * 0.09, -0.25), { group = "Magazine" })
        end
        addPart("Grip", Vector3.new(0.26, 0.80, 0.38), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.48, 0.52) * CFrame.Angles(math.rad(-15), 0, 0))
        addPart("LMGStock", Vector3.new(0.32, 0.72, 1.25), steelMid, Enum.Material.Metal, CFrame.new(0, -0.06, 1.52))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), heavyCol, Enum.Material.Neon, CFrame.new(0, 0.08, -3.50), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 13. SHERIFF (Heavy 6-Shot .357 Magnum Revolver)
    -- ----------------------------------------------------------------
    elseif wName == "SHERIFF" then
        local revSteel = pCol or Color3.fromRGB(165, 170, 180)
        local revGlow = Color3.fromRGB(255, 110, 45)
        addPart("FrameBase", Vector3.new(0.22, 0.34, 0.88), revSteel, Enum.Material.Metal, CFrame.new(0, 0.02, -0.05))
        addPart("TopStrap", Vector3.new(0.16, 0.08, 0.72), revSteel, Enum.Material.Metal, CFrame.new(0, 0.21, -0.12))
        addPart("TriggerGuard", Vector3.new(0.09, 0.20, 0.32), revSteel, Enum.Material.Metal, CFrame.new(0, -0.22, -0.05))
        addPart("Hammer", Vector3.new(0.06, 0.15, 0.14), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.22, 0.34) * CFrame.Angles(math.rad(-28), 0, 0), { group = "Bolt" })

        -- Full-Underlug Barrel + Vent Rib + Iron Sights at Y=0.31
        addCylZ("MagnumBarrel", 1.20, 0.15, revSteel, Enum.Material.Metal, CFrame.new(0, 0.12, -1.05))
        addPart("BarrelUnderlug", Vector3.new(0.18, 0.18, 1.15), revSteel, Enum.Material.Metal, CFrame.new(0, -0.01, -1.03))
        addPart("TopRib", Vector3.new(0.11, 0.07, 1.16), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.21, -1.03))
        addPistolIronSights(0.26, -1.52, 0.22, revGlow, darkMetal)

        -- Swinging 6-Chamber Cylindrical Drum ("Cylinder")
        addCylZ("RevolverDrum", 0.44, 0.34, brightStl, Enum.Material.Metal, CFrame.new(0, 0.05, -0.15), { group = "Cylinder" })
        for idx = 0, 5 do
            local ang = math.rad(idx * 60)
            local ox = math.cos(ang) * 0.10
            local oy = math.sin(ang) * 0.10
            addCylZ("ChamberBrass_" .. idx, 0.46, 0.068, brassCol, Enum.Material.Metal, CFrame.new(ox, 0.05 + oy, -0.15), { group = "Cylinder" })
        end
        -- Speedloader / Cartridge Cluster ("Magazine")
        addCylZ("SpeedloaderBase", 0.14, 0.30, darkMetal, Enum.Material.Metal, CFrame.new(-0.26, 0.05, 0.08), { group = "Magazine" })

        addPart("WoodGrip", Vector3.new(0.22, 0.72, 0.34), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.40, 0.34) * CFrame.Angles(math.rad(-22), 0, 0))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), revGlow, Enum.Material.Neon, CFrame.new(0, 0.12, -1.72), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 14. SHORTY (Double-Barrel Break-Action Sidearm)
    -- ----------------------------------------------------------------
    elseif wName == "SHORTY" then
        local shellRed = Color3.fromRGB(215, 42, 42)
        addCylZ("BarrelL", 1.48, 0.17, steelMid, Enum.Material.Metal, CFrame.new(-0.09, 0.09, -0.98))
        addCylZ("BarrelR", 1.48, 0.17, steelMid, Enum.Material.Metal, CFrame.new(0.09, 0.09, -0.98))
        addPart("TopRib", Vector3.new(0.08, 0.07, 1.42), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.16, -0.96))
        addPart("Receiver", Vector3.new(0.32, 0.36, 0.85), darkMetal, Enum.Material.Metal, CFrame.new(0, 0, -0.05))
        addCylX("HingePin", 0.36, 0.11, brassCol, Enum.Material.Metal, CFrame.new(0, -0.08, -0.40))
        addPart("BreakSnapLever", Vector3.new(0.08, 0.10, 0.24), brightStl, Enum.Material.Metal, CFrame.new(0, 0.22, 0.22), { group = "Bolt" })
        addCylZ("BreakShellL", 0.34, 0.12, shellRed, Enum.Material.SmoothPlastic, CFrame.new(-0.09, 0.09, -0.25), { group = "Magazine" })
        addCylZ("BreakShellR", 0.34, 0.12, shellRed, Enum.Material.SmoothPlastic, CFrame.new(0.09, 0.09, -0.25), { group = "Magazine" })
        addPart("WoodForend", Vector3.new(0.30, 0.20, 0.78), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.07, -0.84))
        addPart("SawedGrip", Vector3.new(0.24, 0.66, 0.38), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.40, 0.42) * CFrame.Angles(math.rad(-28), 0, 0))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 185, 55), Enum.Material.Neon, CFrame.new(0, 0.09, -1.78), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 15. CLASSIC / GHOST / FRENZY (Tactical Semi/Auto/Suppressed Pistols)
    -- ----------------------------------------------------------------
    else
        local isGhost = (wName == "GHOST")
        local isFrenzy = (wName == "FRENZY")
        local slideCol = isGhost and Color3.fromRGB(32, 36, 44) or (isFrenzy and Color3.fromRGB(48, 52, 60) or steelMid)
        local glowCol = isGhost and Color3.fromRGB(80, 200, 255) or (isFrenzy and Color3.fromRGB(255, 185, 45) or Color3.fromRGB(0, 255, 165))

        -- Moving Machined Slide ("Bolt") + Recessed Barrel
        addPart("Slide", Vector3.new(0.25, 0.28, 1.15), slideCol, Enum.Material.Metal, CFrame.new(0, 0.12, -0.18), { group = "Bolt" })
        addWedge("SlideBevel", Vector3.new(0.21, 0.06, 1.05), brightStl, Enum.Material.Metal, CFrame.new(0, 0.27, -0.16), { group = "Bolt" })
        addPart("SlideSerrations", Vector3.new(0.265, 0.20, 0.30), polymer, Enum.Material.DiamondPlate, CFrame.new(0, 0.12, 0.20), { group = "Bolt" })
        addCylZ("PistolBarrel", 0.56, 0.125, brightStl, Enum.Material.Metal, CFrame.new(0, 0.11, -0.78))

        if isGhost then
            addCylZ("PistolSuppressor", 1.28, 0.24, darkMetal, Enum.Material.SmoothPlastic, CFrame.new(0, 0.11, -1.52))
            addCylZ("SuppressorTip", 0.08, 0.22, glowCol, Enum.Material.Neon, CFrame.new(0, 0.11, -2.14))
            addPistolIronSights(0.29, -0.68, 0.32, glowCol, darkMetal)
        elseif isFrenzy then
            addPart("FrenzyComp", Vector3.new(0.24, 0.24, 0.26), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.11, -0.92))
            addReflexOptic("FrenzyDot", 0.29, 0.05, darkMetal, glowCol)
        else
            addPistolIronSights(0.27, -0.68, 0.32, glowCol, darkMetal)
        end

        addPart("PolymerFrame", Vector3.new(0.24, 0.22, 1.08), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.10, -0.18))
        addPart("UnderRail", Vector3.new(0.18, 0.06, 0.42), darkMetal, Enum.Material.Metal, CFrame.new(0, -0.22, -0.50))
        addPart("TriggerGuard", Vector3.new(0.10, 0.20, 0.32), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.26, -0.14))
        addPart("GripPistol", Vector3.new(0.23, 0.72, 0.35), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.44, 0.18) * CFrame.Angles(math.rad(-16), 0, 0))

        local magLen = isFrenzy and 0.92 or 0.70
        local magY = isFrenzy and -0.58 or -0.46
        addBoxMagWithBrass("PistolMag", Vector3.new(0.17, magLen, 0.26), darkMetal, glowCol, brassCol, CFrame.new(0, magY, 0.17) * CFrame.Angles(math.rad(-16), 0, 0))

        local muzzleZ = isGhost and -2.24 or (isFrenzy and -1.12 or -1.04)
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), glowCol, Enum.Material.Neon, CFrame.new(0, 0.11, muzzleZ), { isMuzzle = true })
    end

    -- ----------------------------------------------------------------
    -- 16. Muzzle Flash 3D Starburst, Light & Smoke
    -- ----------------------------------------------------------------
    local muzzleFlashParts = {}
    local flashLight = nil
    local smokeEmitter = nil

    if muzzleFlashPart then
        local mCF = weaponParts[muzzleFlashPart] or CFrame.new(0, 0, -2.5)
        local isShotgun = (weaponConfig.Type == "Shotgun")
        local isSniper = (weaponConfig.IsSniper == true)
        local isSuppressed = (weaponConfig.Audio and weaponConfig.Audio.Silenced) or false

        muzzleFlashPart.Transparency = 1
        local coreCF = mCF * CFrame.new(0, 0, -0.12)

        local flashCore = addPart("MuzzleFlashCore",
            isShotgun and Vector3.new(0.62, 0.62, 0.62) or (isSniper and Vector3.new(0.52, 0.52, 0.52) or Vector3.new(0.36, 0.36, 0.36)),
            Color3.fromRGB(255, 255, 240), Enum.Material.Neon, coreCF, { shape = Enum.PartType.Ball, transparency = 1 })
        table.insert(muzzleFlashParts, flashCore)

        local flameCol = isSuppressed and Color3.fromRGB(80, 220, 255) or Color3.fromRGB(255, 175, 40)
        local flameH = addPart("MuzzleFlashFlameH",
            isShotgun and Vector3.new(1.30, 0.30, 1.00) or (isSniper and Vector3.new(1.35, 0.26, 0.85) or Vector3.new(0.88, 0.20, 0.65)),
            flameCol, Enum.Material.Neon, coreCF, { transparency = 1 })
        table.insert(muzzleFlashParts, flameH)

        local flameV = addPart("MuzzleFlashFlameV",
            isShotgun and Vector3.new(0.30, 1.30, 1.00) or (isSniper and Vector3.new(0.26, 1.35, 0.85) or Vector3.new(0.20, 0.88, 0.65)),
            isSuppressed and Color3.fromRGB(80, 220, 255) or Color3.fromRGB(255, 130, 25), Enum.Material.Neon, coreCF, { transparency = 1 })
        table.insert(muzzleFlashParts, flameV)

        flashLight = Instance.new("PointLight")
        flashLight.Name = "MuzzlePointLight"
        flashLight.Color = isSuppressed and Color3.fromRGB(100, 220, 255) or Color3.fromRGB(255, 195, 75)
        flashLight.Range = isShotgun and 40 or (isSniper and 45 or 32)
        flashLight.Brightness = 0
        flashLight.Shadows = true
        flashLight.Parent = flashCore

        smokeEmitter = Instance.new("ParticleEmitter")
        smokeEmitter.Name = "MuzzleSmoke"
        smokeEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
        smokeEmitter.Color = ColorSequence.new(Color3.fromRGB(190, 190, 200))
        smokeEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0.95) })
        smokeEmitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1.0) })
        smokeEmitter.Lifetime = NumberRange.new(0.3, 0.5)
        smokeEmitter.Rate = 0
        smokeEmitter.Speed = NumberRange.new(2, 6)
        smokeEmitter.SpreadAngle = Vector2.new(20, 20)
        smokeEmitter.Enabled = false
        smokeEmitter.Parent = flashCore
    end

    return weaponParts, muzzleFlashParts, flashLight, smokeEmitter, partGroups
end

return WeaponModelBuilder
