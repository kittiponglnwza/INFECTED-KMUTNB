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
        local rootCF = gunRoot and gunRoot.CFrame or CFrame.identity
        for _, p in ipairs(realGun:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
                p.CanQuery = false
                p.CanTouch = false
                p.Anchored = true
                p.CastShadow = false
                weaponParts[p] = rootCF:ToObjectSpace(p.CFrame)
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
        local len = math.abs(zStart - zEnd)
        local zMid = (zStart + zEnd) * 0.5
        addPart(prefix .. "_Base", Vector3.new(width * 0.78, 0.024, len + step * 0.5), color, Enum.Material.Metal, CFrame.new(0, yPos - 0.015, zMid))
        local i = 0
        local z = zStart
        while z >= zEnd do
            i = i + 1
            addPart(prefix .. "_Tooth_" .. i, Vector3.new(width, 0.036, step * 0.52), color, Enum.Material.Metal, CFrame.new(0, yPos + 0.005, z))
            z = z - step
        end
    end

    local darkMetal  = Color3.fromRGB(26, 29, 34)
    local gunmetal   = Color3.fromRGB(38, 42, 49)
    local steelMid   = Color3.fromRGB(56, 61, 70)
    local brightStl  = Color3.fromRGB(168, 174, 184)
    local polymer    = Color3.fromRGB(22, 24, 28)
    local boreBlack  = Color3.fromRGB(6, 7, 9)
    local brassCol   = Color3.fromRGB(214, 172, 66)
    local copperTip  = Color3.fromRGB(184, 114, 58)
    local walnutWood = Color3.fromRGB(98, 57, 34)
    local oliveMatte = Color3.fromRGB(64, 76, 56)

    local function addTriggerAssembly(prefix, yCenter, zCenter, guardCol, mat)
        mat = mat or Enum.Material.Metal
        addPart(prefix .. "_BowBot", Vector3.new(0.056, 0.030, 0.27), guardCol, mat, CFrame.new(0, yCenter - 0.095, zCenter))
        addPart(prefix .. "_BowF", Vector3.new(0.054, 0.135, 0.032), guardCol, mat, CFrame.new(0, yCenter - 0.035, zCenter - 0.13) * CFrame.Angles(math.rad(18), 0, 0))
        addPart(prefix .. "_BowR", Vector3.new(0.054, 0.115, 0.032), guardCol, mat, CFrame.new(0, yCenter - 0.042, zCenter + 0.12) * CFrame.Angles(math.rad(-14), 0, 0))
        addPart(prefix .. "_TriggerShoe", Vector3.new(0.026, 0.115, 0.036), brightStl, Enum.Material.Metal, CFrame.new(0, yCenter - 0.025, zCenter + 0.025) * CFrame.Angles(math.rad(20), 0, 0))
    end

    local function addReceiverControls(prefix, halfW, yMid, zPinF, zPinR, zSel, accCol)
        addCylX(prefix .. "_PinF", halfW * 2 + 0.014, 0.042, brightStl, Enum.Material.Metal, CFrame.new(0, yMid - 0.04, zPinF))
        addCylX(prefix .. "_PinR", halfW * 2 + 0.014, 0.042, brightStl, Enum.Material.Metal, CFrame.new(0, yMid - 0.03, zPinR))
        addPart(prefix .. "_Selector", Vector3.new(0.022, 0.028, 0.11), accCol, Enum.Material.Metal, CFrame.new(-halfW - 0.012, yMid - 0.01, zSel) * CFrame.Angles(math.rad(-18), 0, 0))
        addPart(prefix .. "_MagRelease", Vector3.new(0.022, 0.055, 0.075), gunmetal, Enum.Material.Metal, CFrame.new(halfW + 0.010, yMid - 0.05, zPinF - 0.06))
    end

    local function addHollowMuzzle(prefix, boreDiam, yPos, zTip, outerDiam, bodyCol)
        if outerDiam and bodyCol then
            addCylZ(prefix .. "_Crown", 0.06, outerDiam, bodyCol, Enum.Material.Metal, CFrame.new(0, yPos, zTip + 0.02))
        end
        addCylZ(prefix .. "_Bore", 0.035, boreDiam, boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0, yPos, zTip - 0.008))
    end

    local function addSlottedBrake(prefix, yPos, zCenter, length, diam, bodyCol, boreDiam, slotCount)
        addCylZ(prefix .. "_Body", length, diam, bodyCol, Enum.Material.Metal, CFrame.new(0, yPos, zCenter))
        local count = slotCount or 2
        local step = (length * 0.58) / math.max(count, 1)
        for i = 1, count do
            local sz = zCenter + length * 0.20 - (i - 1) * step
            addPart(prefix .. "_Port_" .. i, Vector3.new(diam + 0.012, boreDiam * 0.85, step * 0.45), boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0, yPos, sz))
        end
        addHollowMuzzle(prefix, boreDiam, yPos, zCenter - length * 0.5, nil, nil)
    end

    local function addVentedSlots(prefix, yPos, zStart, step, count, halfW, slotH, slotL)
        for i = 1, count do
            addPart(prefix .. "_Slot_" .. i, Vector3.new(halfW * 2 + 0.012, slotH, slotL), boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0, yPos, zStart - (i - 1) * step))
        end
    end

    -- Low-profile tactical reflex / holographic optic (for CQB automatics only)
    local function addReflexOptic(prefix, baseY, zCenter, frameCol, dotCol)
        addPart(prefix .. "_Mount", Vector3.new(0.19, 0.042, 0.34), frameCol, Enum.Material.Metal, CFrame.new(0, baseY - 0.072, zCenter))
        addCylX(prefix .. "_ClampNut", 0.22, 0.045, brightStl, Enum.Material.Metal, CFrame.new(0, baseY - 0.072, zCenter + 0.06))
        addPart(prefix .. "_PillarL", Vector3.new(0.028, 0.145, 0.16), frameCol, Enum.Material.Metal, CFrame.new(-0.088, baseY + 0.015, zCenter))
        addPart(prefix .. "_PillarR", Vector3.new(0.028, 0.145, 0.16), frameCol, Enum.Material.Metal, CFrame.new(0.088, baseY + 0.015, zCenter))
        addPart(prefix .. "_HoodTop", Vector3.new(0.204, 0.024, 0.17), frameCol, Enum.Material.Metal, CFrame.new(0, baseY + 0.095, zCenter))
        addPart(prefix .. "_Lens", Vector3.new(0.15, 0.13, 0.014), Color3.fromRGB(115, 200, 225), Enum.Material.Glass, CFrame.new(0, baseY + 0.015, zCenter), { transparency = 0.86 })
        addPart(prefix .. "_Dot", Vector3.new(0.016, 0.016, 0.016), dotCol, Enum.Material.Neon, CFrame.new(0, baseY + 0.015, zCenter - 0.01))
    end

    -- Multi-stage Precision Tactical Telescopic Scope (cantilever mount, coated glass, locking turrets)
    local function addTelescopicScope(prefix, centerY, centerZ, tubeCol, ringCol, accentCol, scale)
        scale = scale or 1.0
        local glassCoat = Color3.fromRGB(36, 118, 168)
        -- Cantilever rail saddle + dual split rings with hex clamp bolts
        addPart(prefix .. "_MountBase", Vector3.new(0.16 * scale, 0.046 * scale, 1.06 * scale), ringCol, Enum.Material.Metal, CFrame.new(0, centerY - 0.155 * scale, centerZ - 0.04 * scale))
        addPart(prefix .. "_StanchionF", Vector3.new(0.15 * scale, 0.14 * scale, 0.15 * scale), ringCol, Enum.Material.Metal, CFrame.new(0, centerY - 0.075 * scale, centerZ - 0.42 * scale))
        addPart(prefix .. "_StanchionR", Vector3.new(0.15 * scale, 0.14 * scale, 0.15 * scale), ringCol, Enum.Material.Metal, CFrame.new(0, centerY - 0.075 * scale, centerZ + 0.34 * scale))
        addCylZ(prefix .. "_RingF", 0.16 * scale, 0.215 * scale, ringCol, Enum.Material.Metal, CFrame.new(0, centerY, centerZ - 0.42 * scale))
        addCylZ(prefix .. "_RingR", 0.16 * scale, 0.215 * scale, ringCol, Enum.Material.Metal, CFrame.new(0, centerY, centerZ + 0.34 * scale))
        addCylX(prefix .. "_BoltF", 0.20 * scale, 0.038 * scale, brightStl, Enum.Material.Metal, CFrame.new(-0.02 * scale, centerY - 0.115 * scale, centerZ - 0.42 * scale))
        addCylX(prefix .. "_BoltR", 0.20 * scale, 0.038 * scale, brightStl, Enum.Material.Metal, CFrame.new(-0.02 * scale, centerY - 0.115 * scale, centerZ + 0.34 * scale))

        -- 34mm main anodized tube + central turret housing + 3 tactile turrets
        addCylZ(prefix .. "_Tube", 1.66 * scale, 0.172 * scale, tubeCol, Enum.Material.Metal, CFrame.new(0, centerY, centerZ))
        addPart(prefix .. "_TurretHub", Vector3.new(0.195 * scale, 0.195 * scale, 0.25 * scale), tubeCol, Enum.Material.Metal, CFrame.new(0, centerY, centerZ - 0.04 * scale))
        addCylY(prefix .. "_ElevTurret", 0.095 * scale, 0.125 * scale, ringCol, Enum.Material.Metal, CFrame.new(0, centerY + 0.13 * scale, centerZ - 0.04 * scale))
        addCylY(prefix .. "_ElevBand", 0.022 * scale, 0.130 * scale, accentCol, Enum.Material.Metal, CFrame.new(0, centerY + 0.105 * scale, centerZ - 0.04 * scale))
        addCylX(prefix .. "_WindTurret", 0.085 * scale, 0.115 * scale, ringCol, Enum.Material.Metal, CFrame.new(0.128 * scale, centerY, centerZ - 0.04 * scale))
        addCylX(prefix .. "_ParallaxDial", 0.075 * scale, 0.130 * scale, accentCol, Enum.Material.Metal, CFrame.new(-0.125 * scale, centerY, centerZ - 0.04 * scale))

        -- Stepped objective bell + extended sunshade + recessed coated sapphire lens
        addCylZ(prefix .. "_ObjTaper", 0.22 * scale, 0.220 * scale, tubeCol, Enum.Material.Metal, CFrame.new(0, centerY, centerZ - 0.72 * scale))
        addCylZ(prefix .. "_ObjBell", 0.56 * scale, 0.268 * scale, tubeCol, Enum.Material.Metal, CFrame.new(0, centerY, centerZ - 1.06 * scale))
        addCylZ(prefix .. "_ObjRing", 0.04 * scale, 0.274 * scale, accentCol, Enum.Material.Metal, CFrame.new(0, centerY, centerZ - 1.32 * scale))
        addCylZ(prefix .. "_ObjCavity", 0.04 * scale, 0.228 * scale, boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0, centerY, centerZ - 1.31 * scale))
        addCylZ(prefix .. "_LensF", 0.022 * scale, 0.226 * scale, glassCoat, Enum.Material.Glass, CFrame.new(0, centerY, centerZ - 1.325 * scale), { transparency = 0.28 })

        -- Eyepiece magnification ring + throw lever + rubber diopter cup + rear lens
        addCylZ(prefix .. "_EyeTaper", 0.18 * scale, 0.212 * scale, ringCol, Enum.Material.Metal, CFrame.new(0, centerY, centerZ + 0.64 * scale))
        addPart(prefix .. "_ThrowLever", Vector3.new(0.032 * scale, 0.075 * scale, 0.042 * scale), brightStl, Enum.Material.Metal, CFrame.new(-0.085 * scale, centerY + 0.095 * scale, centerZ + 0.64 * scale) * CFrame.Angles(0, 0, math.rad(32)))
        addCylZ(prefix .. "_EyeBell", 0.34 * scale, 0.236 * scale, tubeCol, Enum.Material.SmoothPlastic, CFrame.new(0, centerY, centerZ + 0.88 * scale))
        addCylZ(prefix .. "_EyeRubber", 0.09 * scale, 0.244 * scale, polymer, Enum.Material.Rubber, CFrame.new(0, centerY, centerZ + 1.04 * scale))
        addCylZ(prefix .. "_EyeCavity", 0.03 * scale, 0.195 * scale, boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0, centerY, centerZ + 1.05 * scale))
        addCylZ(prefix .. "_LensR", 0.02 * scale, 0.192 * scale, glassCoat, Enum.Material.Glass, CFrame.new(0, centerY, centerZ + 1.06 * scale), { transparency = 0.32 })
    end

    -- Precision Iron Sight Set aligned directly on ADS sightline (no center occlusion)
    local function addIronSightSet(prefix, sightY, frontZ, rearZ, frameCol, dotCol, style)
        if style == "flipup" then
            addPart(prefix .. "_RearBase", Vector3.new(0.15, 0.045, 0.18), frameCol, Enum.Material.Metal, CFrame.new(0, sightY - 0.09, rearZ))
            addPart(prefix .. "_RearWingL", Vector3.new(0.032, 0.125, 0.09), frameCol, Enum.Material.Metal, CFrame.new(-0.056, sightY - 0.015, rearZ))
            addPart(prefix .. "_RearWingR", Vector3.new(0.032, 0.125, 0.09), frameCol, Enum.Material.Metal, CFrame.new(0.056, sightY - 0.015, rearZ))
            addPart(prefix .. "_RearBridgeL", Vector3.new(0.028, 0.022, 0.07), gunmetal, Enum.Material.Metal, CFrame.new(-0.032, sightY + 0.038, rearZ))
            addPart(prefix .. "_RearBridgeR", Vector3.new(0.028, 0.022, 0.07), gunmetal, Enum.Material.Metal, CFrame.new(0.032, sightY + 0.038, rearZ))
            addCylX(prefix .. "_Windage", 0.05, 0.048, brightStl, Enum.Material.Metal, CFrame.new(0.088, sightY - 0.04, rearZ))
            addPart(prefix .. "_FrontBase", Vector3.new(0.14, 0.045, 0.16), frameCol, Enum.Material.Metal, CFrame.new(0, sightY - 0.09, frontZ))
            addPart(prefix .. "_FrontWingL", Vector3.new(0.024, 0.125, 0.08), frameCol, Enum.Material.Metal, CFrame.new(-0.052, sightY - 0.015, frontZ))
            addPart(prefix .. "_FrontWingR", Vector3.new(0.024, 0.125, 0.08), frameCol, Enum.Material.Metal, CFrame.new(0.052, sightY - 0.015, frontZ))
            addPart(prefix .. "_FrontPost", Vector3.new(0.018, 0.082, 0.022), darkMetal, Enum.Material.Metal, CFrame.new(0, sightY - 0.035, frontZ))
            addPart(prefix .. "_FrontDot", Vector3.new(0.016, 0.020, 0.016), dotCol, Enum.Material.Neon, CFrame.new(0, sightY, frontZ + 0.006))
        elseif style == "open_v" then
            addPart(prefix .. "_RearDovetail", Vector3.new(0.12, 0.036, 0.14), frameCol, Enum.Material.Metal, CFrame.new(0, sightY - 0.065, rearZ))
            addPart(prefix .. "_RearRamp", Vector3.new(0.06, 0.045, 0.22), gunmetal, Enum.Material.Metal, CFrame.new(0, sightY - 0.055, rearZ - 0.06) * CFrame.Angles(math.rad(-12), 0, 0))
            addPart(prefix .. "_RearHornL", Vector3.new(0.036, 0.058, 0.045), frameCol, Enum.Material.Metal, CFrame.new(-0.044, sightY - 0.015, rearZ) * CFrame.Angles(0, 0, math.rad(-14)))
            addPart(prefix .. "_RearHornR", Vector3.new(0.036, 0.058, 0.045), frameCol, Enum.Material.Metal, CFrame.new(0.044, sightY - 0.015, rearZ) * CFrame.Angles(0, 0, math.rad(14)))
            addPart(prefix .. "_FrontRamp", Vector3.new(0.055, 0.065, 0.18), frameCol, Enum.Material.Metal, CFrame.new(0, sightY - 0.065, frontZ))
            addPart(prefix .. "_FrontBlade", Vector3.new(0.018, 0.068, 0.075), darkMetal, Enum.Material.Metal, CFrame.new(0, sightY - 0.022, frontZ))
            addPart(prefix .. "_FrontBead", Vector3.new(0.018, 0.020, 0.018), dotCol, Enum.Material.Neon, CFrame.new(0, sightY + 0.005, frontZ + 0.028))
        elseif style == "ghost" then
            addPart(prefix .. "_GhostBase", Vector3.new(0.13, 0.038, 0.10), frameCol, Enum.Material.Metal, CFrame.new(0, sightY - 0.07, rearZ))
            addPart(prefix .. "_GhostL", Vector3.new(0.026, 0.095, 0.055), frameCol, Enum.Material.Metal, CFrame.new(-0.052, sightY - 0.01, rearZ))
            addPart(prefix .. "_GhostR", Vector3.new(0.026, 0.095, 0.055), frameCol, Enum.Material.Metal, CFrame.new(0.052, sightY - 0.01, rearZ))
            addPart(prefix .. "_GhostTop", Vector3.new(0.13, 0.022, 0.055), frameCol, Enum.Material.Metal, CFrame.new(0, sightY + 0.048, rearZ))
            addPart(prefix .. "_FrontPost", Vector3.new(0.042, 0.095, 0.075), frameCol, Enum.Material.Metal, CFrame.new(0, sightY - 0.045, frontZ))
            addPart(prefix .. "_FrontBead", Vector3.new(0.022, 0.022, 0.022), dotCol, Enum.Material.Neon, CFrame.new(0, sightY, frontZ + 0.018))
        else -- "aperture"
            addPart(prefix .. "_RearBase", Vector3.new(0.14, 0.042, 0.18), frameCol, Enum.Material.Metal, CFrame.new(0, sightY - 0.085, rearZ))
            addPart(prefix .. "_RearEarL", Vector3.new(0.030, 0.110, 0.09), frameCol, Enum.Material.Metal, CFrame.new(-0.052, sightY - 0.018, rearZ))
            addPart(prefix .. "_RearEarR", Vector3.new(0.030, 0.110, 0.09), frameCol, Enum.Material.Metal, CFrame.new(0.052, sightY - 0.018, rearZ))
            addPart(prefix .. "_RearShelf", Vector3.new(0.08, 0.024, 0.07), gunmetal, Enum.Material.Metal, CFrame.new(0, sightY - 0.052, rearZ))
            addCylX(prefix .. "_WindDrum", 0.045, 0.042, brassCol, Enum.Material.Metal, CFrame.new(0.084, sightY - 0.042, rearZ))
            addPart(prefix .. "_FrontBase", Vector3.new(0.13, 0.045, 0.14), frameCol, Enum.Material.Metal, CFrame.new(0, sightY - 0.085, frontZ))
            addPart(prefix .. "_FrontHoodL", Vector3.new(0.022, 0.115, 0.08), frameCol, Enum.Material.Metal, CFrame.new(-0.048, sightY - 0.015, frontZ))
            addPart(prefix .. "_FrontHoodR", Vector3.new(0.022, 0.115, 0.08), frameCol, Enum.Material.Metal, CFrame.new(0.048, sightY - 0.015, frontZ))
            addPart(prefix .. "_FrontPost", Vector3.new(0.018, 0.078, 0.024), darkMetal, Enum.Material.Metal, CFrame.new(0, sightY - 0.032, frontZ))
            addPart(prefix .. "_FrontFiber", Vector3.new(0.016, 0.020, 0.018), dotCol, Enum.Material.Neon, CFrame.new(0, sightY + 0.002, frontZ + 0.005))
        end
    end

    local function addBoxMagWithBrass(prefix, size, bodyCol, plateCol, roundCol, relCF)
        addPart(prefix .. "_Body", size, bodyCol, Enum.Material.SmoothPlastic, relCF, { group = "Magazine" })
        addPart(prefix .. "_Rib", Vector3.new(size.X + 0.014, size.Y * 0.72, size.Z * 0.42), gunmetal, Enum.Material.Metal, relCF, { group = "Magazine" })
        addPart(prefix .. "_BasePlate", Vector3.new(size.X + 0.028, 0.075, size.Z + 0.036), plateCol, Enum.Material.Metal, relCF * CFrame.new(0, -size.Y * 0.5 - 0.03, 0), { group = "Magazine" })
        addCylZ(prefix .. "_BrassCase", size.Z * 0.56, 0.072, roundCol, Enum.Material.Metal, relCF * CFrame.new(0, size.Y * 0.5 + 0.01, 0.03), { group = "Magazine" })
        addCylZ(prefix .. "_BulletTip", size.Z * 0.24, 0.056, copperTip, Enum.Material.Metal, relCF * CFrame.new(0, size.Y * 0.5 + 0.01, -size.Z * 0.28), { group = "Magazine" })
    end

    local function addPistolIronSights(topY, frontZ, rearZ, glowCol, frameCol)
        addPart("FrontSightPost", Vector3.new(0.028, 0.068, 0.058), frameCol, Enum.Material.Metal, CFrame.new(0, topY + 0.028, frontZ))
        addPart("FrontSightDot", Vector3.new(0.018, 0.024, 0.016), glowCol, Enum.Material.Neon, CFrame.new(0, topY + 0.044, frontZ + 0.022))
        addPart("RearSightBase", Vector3.new(0.145, 0.026, 0.065), frameCol, Enum.Material.Metal, CFrame.new(0, topY + 0.008, rearZ))
        addPart("RearSightL", Vector3.new(0.044, 0.052, 0.062), frameCol, Enum.Material.Metal, CFrame.new(-0.050, topY + 0.028, rearZ))
        addPart("RearSightR", Vector3.new(0.044, 0.052, 0.062), frameCol, Enum.Material.Metal, CFrame.new(0.050, topY + 0.028, rearZ))
        addPart("RearDotL", Vector3.new(0.016, 0.018, 0.014), glowCol, Enum.Material.Neon, CFrame.new(-0.050, topY + 0.034, rearZ + 0.028))
        addPart("RearDotR", Vector3.new(0.016, 0.018, 0.014), glowCol, Enum.Material.Neon, CFrame.new(0.050, topY + 0.034, rearZ + 0.028))
    end

    -- ----------------------------------------------------------------
    -- 1. VANDAL (Stamped-Steel 7.62 Assault Rifle)
    -- ----------------------------------------------------------------
    if wName == "VANDAL" then
        local bakelite = Color3.fromRGB(142, 66, 36)
        addPart("Receiver", Vector3.new(0.28, 0.36, 1.70), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0.04))
        addPart("DustCover", Vector3.new(0.24, 0.13, 1.38), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.25, 0.16))
        addWedge("ReceiverFrontSlope", Vector3.new(0.24, 0.12, 0.34), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.25, -0.62) * CFrame.Angles(0, math.rad(180), 0))
        addPart("DovetailRail", Vector3.new(0.03, 0.10, 0.56), steelMid, Enum.Material.Metal, CFrame.new(-0.15, 0.05, 0.25))
        addPart("EjectionPort", Vector3.new(0.04, 0.11, 0.46), boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0.13, 0.17, -0.05))
        addReceiverControls("Vandal", 0.14, 0.02, -0.45, 0.62, 0.32, steelMid)

        -- Animated Charging Handle + Machined Bolt Carrier
        addPart("BoltCarrier", Vector3.new(0.055, 0.095, 0.44), brightStl, Enum.Material.Metal, CFrame.new(0.14, 0.17, -0.04), { group = "Bolt" })
        addCylX("ChargingHandle", 0.18, 0.058, brightStl, Enum.Material.Metal, CFrame.new(0.21, 0.17, -0.18), { group = "Bolt" })

        -- Gas tube, gas block, cleaning rod & ventilated walnut handguard
        addCylZ("GasTube", 1.32, 0.14, gunmetal, Enum.Material.Metal, CFrame.new(0, 0.21, -1.36))
        addPart("GasBlock", Vector3.new(0.16, 0.24, 0.20), steelMid, Enum.Material.Metal, CFrame.new(0, 0.15, -2.04) * CFrame.Angles(math.rad(-14), 0, 0))
        addPart("HandguardWood", Vector3.new(0.29, 0.24, 1.24), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.01, -1.36))
        addPart("HandguardRetainer", Vector3.new(0.30, 0.25, 0.10), steelMid, Enum.Material.Metal, CFrame.new(0, 0.02, -1.96))
        addVentedSlots("VandalVent", 0.11, -1.06, 0.22, 3, 0.145, 0.042, 0.12)

        -- Barrel, cleaning rod, slant brake + AK iron sights aligned at Y=0.415
        addCylZ("Barrel", 1.98, 0.13, steelMid, Enum.Material.Metal, CFrame.new(0, 0.08, -2.28))
        addCylZ("CleaningRod", 1.88, 0.036, brightStl, Enum.Material.Metal, CFrame.new(0, -0.04, -2.20))
        addSlottedBrake("VandalBrake", 0.08, -3.28, 0.42, 0.19, darkMetal, 0.088, 2)
        addPart("FrontSightBase", Vector3.new(0.12, 0.22, 0.14), steelMid, Enum.Material.Metal, CFrame.new(0, 0.20, -2.92))
        addPart("FrontSightWingL", Vector3.new(0.024, 0.16, 0.09), steelMid, Enum.Material.Metal, CFrame.new(-0.055, 0.35, -2.92))
        addPart("FrontSightWingR", Vector3.new(0.024, 0.16, 0.09), steelMid, Enum.Material.Metal, CFrame.new(0.055, 0.35, -2.92))
        addPart("FrontSightPost", Vector3.new(0.018, 0.11, 0.022), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.365, -2.92))
        addPart("FrontSightFiber", Vector3.new(0.016, 0.020, 0.016), Color3.fromRGB(0, 240, 145), Enum.Material.Neon, CFrame.new(0, 0.415, -2.91))
        addPart("RearSightBlock", Vector3.new(0.14, 0.06, 0.28), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.34, 0.56))
        addPart("RearSightNotchL", Vector3.new(0.040, 0.055, 0.065), steelMid, Enum.Material.Metal, CFrame.new(-0.048, 0.395, 0.64))
        addPart("RearSightNotchR", Vector3.new(0.040, 0.055, 0.065), steelMid, Enum.Material.Metal, CFrame.new(0.048, 0.395, 0.64))

        -- Curved Bakelite 7.62 Magazine ("Magazine")
        addPart("MagUpper", Vector3.new(0.21, 0.56, 0.40), bakelite, Enum.Material.SmoothPlastic, CFrame.new(0, -0.37, -0.22) * CFrame.Angles(math.rad(-10), 0, 0), { group = "Magazine" })
        addPart("MagLower", Vector3.new(0.20, 0.52, 0.38), bakelite, Enum.Material.SmoothPlastic, CFrame.new(0, -0.73, -0.37) * CFrame.Angles(math.rad(-26), 0, 0), { group = "Magazine" })
        addPart("MagFloor", Vector3.new(0.22, 0.07, 0.42), darkMetal, Enum.Material.Metal, CFrame.new(0, -0.96, -0.49) * CFrame.Angles(math.rad(-26), 0, 0), { group = "Magazine" })
        addCylZ("MagBrassRound", 0.28, 0.072, brassCol, Enum.Material.Metal, CFrame.new(0, -0.09, -0.19), { group = "Magazine" })

        addTriggerAssembly("Vandal", -0.18, 0.16, darkMetal, Enum.Material.Metal)
        addPart("Grip", Vector3.new(0.22, 0.76, 0.34), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.46, 0.46) * CFrame.Angles(math.rad(-18), 0, 0))
        addPart("StockTang", Vector3.new(0.20, 0.16, 0.30), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.04, 1.00))
        addPart("StockTopBar", Vector3.new(0.18, 0.12, 1.25), walnutWood, Enum.Material.Wood, CFrame.new(0, 0.02, 1.62))
        addPart("StockBotStrut", Vector3.new(0.15, 0.13, 1.22), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.15, 1.62) * CFrame.Angles(math.rad(-8), 0, 0))
        addPart("StockButt", Vector3.new(0.23, 0.68, 0.16), polymer, Enum.Material.Rubber, CFrame.new(0, -0.12, 2.26))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 175, 65), Enum.Material.Neon, CFrame.new(0, 0.08, -3.55), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 2. PHANTOM (Integrally Suppressed Tactical Spec-Ops Carbine)
    -- ----------------------------------------------------------------
    elseif wName == "PHANTOM" then
        local dotCol = Color3.fromRGB(0, 225, 255)
        addPart("LowerReceiver", Vector3.new(0.28, 0.24, 1.44), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.05, 0.04))
        addPart("UpperReceiver", Vector3.new(0.27, 0.24, 1.48), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.16, 0.02))
        addWedge("BrassDeflector", Vector3.new(0.08, 0.12, 0.14), gunmetal, Enum.Material.Metal, CFrame.new(0.15, 0.18, 0.18))
        addPart("DustPort", Vector3.new(0.03, 0.10, 0.42), boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0.13, 0.17, -0.10))
        addPicatinnyRail("PhantomRail", 0.66, -1.68, 0.30, 0.17, gunmetal, 0.14)
        addReflexOptic("PhantomReflex", 0.39, -0.14, darkMetal, dotCol)
        addReceiverControls("Phantom", 0.14, -0.04, -0.34, 0.56, 0.32, steelMid)

        addPart("BoltCarrier", Vector3.new(0.048, 0.10, 0.40), brightStl, Enum.Material.Metal, CFrame.new(0.135, 0.17, -0.10), { group = "Bolt" })
        addPart("ChargingLatch", Vector3.new(0.22, 0.055, 0.14), steelMid, Enum.Material.Metal, CFrame.new(0, 0.24, 0.74), { group = "Bolt" })

        -- M-LOK Handguard + Stepped Matte Titanium Suppressor with Hollow Bore
        addPart("Handguard", Vector3.new(0.29, 0.31, 1.12), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.07, -1.18))
        addVentedSlots("PhantomMLOK", 0.07, -0.82, 0.22, 4, 0.146, 0.045, 0.14)
        addCylZ("SuppressorCollar", 0.18, 0.36, steelMid, Enum.Material.Metal, CFrame.new(0, 0.09, -1.74))
        addCylZ("SuppressorBody", 1.80, 0.32, darkMetal, Enum.Material.SmoothPlastic, CFrame.new(0, 0.09, -2.56))
        addCylZ("SuppressorFlute", 0.10, 0.34, gunmetal, Enum.Material.Metal, CFrame.new(0, 0.09, -3.40))
        addHollowMuzzle("Phantom", 0.095, 0.09, -3.46, nil, nil)

        -- Windowed Polymer PMAG showing real brass rounds behind glass ("Magazine")
        addBoxMagWithBrass("PhantomMag", Vector3.new(0.21, 0.78, 0.37), polymer, steelMid, brassCol, CFrame.new(0, -0.48, -0.22) * CFrame.Angles(math.rad(-8), 0, 0))
        addPart("MagWindowBrass", Vector3.new(0.17, 0.34, 0.10), brassCol, Enum.Material.Metal, CFrame.new(0, -0.48, -0.22) * CFrame.Angles(math.rad(-8), 0, 0), { group = "Magazine" })
        addPart("MagWindowGlass", Vector3.new(0.22, 0.36, 0.12), Color3.fromRGB(45, 52, 58), Enum.Material.Glass, CFrame.new(0, -0.48, -0.22) * CFrame.Angles(math.rad(-8), 0, 0), { group = "Magazine", transparency = 0.55 })

        addTriggerAssembly("Phantom", -0.17, 0.12, darkMetal, Enum.Material.Metal)
        addPart("Grip", Vector3.new(0.23, 0.74, 0.34), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.44, 0.42) * CFrame.Angles(math.rad(-16), 0, 0))
        addCylZ("BufferTube", 1.15, 0.18, steelMid, Enum.Material.Metal, CFrame.new(0, 0.06, 1.30))
        addWedge("StockCheek", Vector3.new(0.24, 0.34, 0.88), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, 0.02, 1.54) * CFrame.Angles(0, math.rad(180), 0))
        addPart("StockPad", Vector3.new(0.26, 0.60, 0.18), Color3.fromRGB(16, 16, 18), Enum.Material.Rubber, CFrame.new(0, -0.06, 2.00))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), dotCol, Enum.Material.Neon, CFrame.new(0, 0.09, -3.58), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 3. BULLDOG (Bullpup Combat Rifle)
    -- ----------------------------------------------------------------
    elseif wName == "BULLDOG" then
        local dotCol = Color3.fromRGB(90, 235, 130)
        addPart("BullpupChassis", Vector3.new(0.32, 0.46, 2.28), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0.25))
        addPart("ChassisSideArmor", Vector3.new(0.34, 0.26, 1.62), oliveMatte, Enum.Material.SmoothPlastic, CFrame.new(0, 0.03, 0.12))
        addPart("EjectionPort", Vector3.new(0.04, 0.12, 0.42), boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0.16, 0.12, 0.72))
        addPicatinnyRail("BulldogRail", 0.80, -0.82, 0.27, 0.17, gunmetal, 0.14)
        addReflexOptic("BulldogHolo", 0.39, -0.10, darkMetal, dotCol)
        addReceiverControls("Bulldog", 0.17, 0.02, -0.25, 0.62, 0.24, steelMid)
        addPart("ChargingHandle", Vector3.new(0.14, 0.07, 0.13), brightStl, Enum.Material.Metal, CFrame.new(-0.19, 0.18, -0.62), { group = "Bolt" })

        addVentedSlots("BulldogVent", 0.05, -0.58, 0.20, 3, 0.172, 0.045, 0.12)
        addCylZ("Barrel", 1.48, 0.145, steelMid, Enum.Material.Metal, CFrame.new(0, 0.08, -1.42))
        addSlottedBrake("BulldogBrake", 0.08, -2.20, 0.32, 0.20, darkMetal, 0.085, 2)
        addBoxMagWithBrass("BulldogMag", Vector3.new(0.21, 0.72, 0.37), polymer, steelMid, brassCol, CFrame.new(0, -0.45, 0.92) * CFrame.Angles(math.rad(-6), 0, 0))
        addTriggerAssembly("Bulldog", -0.20, -0.05, polymer, Enum.Material.SmoothPlastic)
        addPart("Grip", Vector3.new(0.23, 0.74, 0.34), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.44, 0.18) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("ButtPad", Vector3.new(0.30, 0.64, 0.18), Color3.fromRGB(16, 16, 18), Enum.Material.Rubber, CFrame.new(0, -0.02, 1.48))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), dotCol, Enum.Material.Neon, CFrame.new(0, 0.08, -2.42), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 4. GUARDIAN (Heavy DMR - Iron Sights Only, Zero Scope)
    -- ----------------------------------------------------------------
    elseif wName == "GUARDIAN" then
        local gold = Color3.fromRGB(198, 162, 68)
        local fiberCol = Color3.fromRGB(0, 235, 165)
        addPart("Receiver", Vector3.new(0.29, 0.40, 1.66), steelMid, Enum.Material.Metal, CFrame.new(0, 0.02, 0.04))
        addPart("Handguard", Vector3.new(0.27, 0.28, 1.46), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.05, -1.35))
        addVentedSlots("GuardMLOK", 0.05, -0.78, 0.24, 5, 0.136, 0.045, 0.15)
        addPart("BrassDeflector", Vector3.new(0.06, 0.12, 0.14), gunmetal, Enum.Material.Metal, CFrame.new(0.15, 0.14, 0.30))
        addPart("EjectionPort", Vector3.new(0.04, 0.11, 0.44), boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0.14, 0.15, 0.05))
        addPart("GoldInlay", Vector3.new(0.302, 0.026, 1.10), gold, Enum.Material.Metal, CFrame.new(0, 0.11, 0.02))
        addPicatinnyRail("GuardRail", 0.72, -1.96, 0.26, 0.16, darkMetal, 0.15)
        -- Precision diopter aperture iron sights aligned on ADS crosshair (Y = 0.42)
        addIronSightSet("GuardIrons", 0.42, -1.86, 0.62, darkMetal, fiberCol, "aperture")
        addReceiverControls("Guard", 0.145, -0.02, -0.35, 0.56, 0.32, gold)
        addPart("BoltCarrier", Vector3.new(0.048, 0.105, 0.44), brightStl, Enum.Material.Metal, CFrame.new(0.145, 0.15, 0.05), { group = "Bolt" })

        -- Gas block, stainless tube, fluted match barrel & 3-port brake
        addCylZ("GasTube", 1.15, 0.042, brightStl, Enum.Material.Metal, CFrame.new(0, 0.18, -2.02))
        addPart("GasBlock", Vector3.new(0.16, 0.20, 0.18), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.12, -2.62))
        addCylZ("MatchBarrel", 2.40, 0.15, steelMid, Enum.Material.Metal, CFrame.new(0, 0.08, -2.65))
        addPart("BarrelFluteL", Vector3.new(0.025, 0.032, 1.45), gunmetal, Enum.Material.Metal, CFrame.new(-0.072, 0.08, -2.95))
        addPart("BarrelFluteR", Vector3.new(0.025, 0.032, 1.45), gunmetal, Enum.Material.Metal, CFrame.new(0.072, 0.08, -2.95))
        addSlottedBrake("GuardBrake", 0.08, -3.90, 0.48, 0.22, darkMetal, 0.088, 3)

        addBoxMagWithBrass("GuardMag", Vector3.new(0.19, 0.60, 0.42), darkMetal, gold, brassCol, CFrame.new(0, -0.40, -0.24))
        addTriggerAssembly("Guard", -0.19, 0.14, darkMetal, Enum.Material.Metal)
        addPart("Grip", Vector3.new(0.23, 0.74, 0.34), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.45, 0.45) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("MarksmanStock", Vector3.new(0.26, 0.64, 1.34), darkMetal, Enum.Material.SmoothPlastic, CFrame.new(0, -0.06, 1.54))
        addPart("CheekRiser", Vector3.new(0.28, 0.14, 0.72), gunmetal, Enum.Material.SmoothPlastic, CFrame.new(0, 0.30, 1.48))
        addCylX("CheekWheel", 0.32, 0.055, gold, Enum.Material.Metal, CFrame.new(0, 0.16, 1.48))
        addPart("ButtPad", Vector3.new(0.28, 0.66, 0.14), Color3.fromRGB(16, 16, 18), Enum.Material.Rubber, CFrame.new(0, -0.06, 2.24))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), gold, Enum.Material.Neon, CFrame.new(0, 0.08, -4.22), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 5. SPECTRE (Suppressed Tactical SMG)
    -- ----------------------------------------------------------------
    elseif wName == "SPECTRE" then
        local dotCol = Color3.fromRGB(60, 215, 235)
        addPart("Receiver", Vector3.new(0.27, 0.36, 1.36), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0.05))
        addPart("Handguard", Vector3.new(0.28, 0.30, 0.85), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, 0.04, -0.95))
        addVentedSlots("SpecVent", 0.04, -0.68, 0.20, 3, 0.142, 0.042, 0.11)
        addPicatinnyRail("SpecRail", 0.56, -0.78, 0.23, 0.16, gunmetal, 0.13)
        addReflexOptic("SpecOptic", 0.38, -0.10, darkMetal, dotCol)
        addReceiverControls("Spec", 0.135, -0.02, -0.35, 0.45, 0.22, steelMid)
        addPart("BoltHandle", Vector3.new(0.14, 0.06, 0.11), brightStl, Enum.Material.Metal, CFrame.new(-0.17, 0.16, -0.35), { group = "Bolt" })

        addCylZ("SuppressorCollar", 0.14, 0.32, steelMid, Enum.Material.Metal, CFrame.new(0, 0.06, -1.32))
        addCylZ("SMGSilencer", 1.32, 0.29, darkMetal, Enum.Material.SmoothPlastic, CFrame.new(0, 0.06, -1.90))
        addCylZ("SilencerCap", 0.08, 0.27, gunmetal, Enum.Material.Metal, CFrame.new(0, 0.06, -2.54))
        addHollowMuzzle("Spec", 0.082, 0.06, -2.58, nil, nil)

        addBoxMagWithBrass("SpectreMag", Vector3.new(0.17, 0.80, 0.27), polymer, gunmetal, brassCol, CFrame.new(0, -0.48, -0.32) * CFrame.Angles(math.rad(10), 0, 0))
        addPart("StubbyForegrip", Vector3.new(0.15, 0.32, 0.19), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.25, -0.95))
        addTriggerAssembly("Spec", -0.16, 0.12, polymer, Enum.Material.SmoothPlastic)
        addPart("Grip", Vector3.new(0.22, 0.70, 0.31), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.42, 0.36) * CFrame.Angles(math.rad(-16), 0, 0))
        addCylZ("WireStockL", 1.05, 0.055, brightStl, Enum.Material.Metal, CFrame.new(-0.11, 0.04, 1.18))
        addCylZ("WireStockR", 1.05, 0.055, brightStl, Enum.Material.Metal, CFrame.new(0.11, 0.04, 1.18))
        addPart("WireButt", Vector3.new(0.26, 0.44, 0.14), polymer, Enum.Material.Rubber, CFrame.new(0, -0.02, 1.72))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), dotCol, Enum.Material.Neon, CFrame.new(0, 0.06, -2.62), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 6. STINGER (High-RPM PDW SMG)
    -- ----------------------------------------------------------------
    elseif wName == "STINGER" then
        local dotCol = Color3.fromRGB(255, 130, 45)
        addPart("Receiver", Vector3.new(0.27, 0.38, 1.18), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0.02))
        addPart("PDWShroud", Vector3.new(0.28, 0.28, 0.75), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.04, -0.82))
        addVentedSlots("StingVent", 0.04, -0.58, 0.18, 3, 0.142, 0.040, 0.10)
        addPicatinnyRail("StingRail", 0.46, -0.95, 0.23, 0.16, steelMid, 0.13)
        addReflexOptic("StingHolo", 0.38, -0.08, gunmetal, dotCol)
        addReceiverControls("Sting", 0.135, -0.02, -0.28, 0.36, 0.18, dotCol)
        addPart("SideBoltKnob", Vector3.new(0.13, 0.07, 0.09), brightStl, Enum.Material.Metal, CFrame.new(-0.17, 0.14, -0.25), { group = "Bolt" })

        addCylZ("ShortBarrel", 0.85, 0.135, darkMetal, Enum.Material.Metal, CFrame.new(0, 0.06, -1.45))
        addSlottedBrake("StingComp", 0.06, -1.96, 0.30, 0.185, steelMid, 0.082, 2)
        addBoxMagWithBrass("StingerMag", Vector3.new(0.16, 0.88, 0.25), darkMetal, gunmetal, brassCol, CFrame.new(0, -0.52, -0.28) * CFrame.Angles(math.rad(6), 0, 0))
        addTriggerAssembly("Sting", -0.17, 0.08, polymer, Enum.Material.SmoothPlastic)
        addPart("Grip", Vector3.new(0.22, 0.70, 0.31), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.42, 0.30) * CFrame.Angles(math.rad(-15), 0, 0))
        addPart("WireStockTop", Vector3.new(0.20, 0.07, 0.88), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.10, 1.04))
        addPart("WireStockBot", Vector3.new(0.18, 0.06, 0.88), steelMid, Enum.Material.Metal, CFrame.new(0, -0.08, 1.04) * CFrame.Angles(math.rad(-8), 0, 0))
        addPart("WireStockPad", Vector3.new(0.22, 0.40, 0.12), polymer, Enum.Material.Rubber, CFrame.new(0, -0.02, 1.48))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), dotCol, Enum.Material.Neon, CFrame.new(0, 0.06, -2.18), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 7. BUCKY (Pump-Action 12-Gauge Tactical Shotgun)
    -- ----------------------------------------------------------------
    elseif wName == "BUCKY" then
        local shellRed = Color3.fromRGB(195, 38, 38)
        addPart("Receiver", Vector3.new(0.31, 0.44, 1.56), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0.04))
        addPart("ReceiverTopRib", Vector3.new(0.19, 0.06, 1.44), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.26, 0.04))
        addPart("EjectionPort", Vector3.new(0.04, 0.16, 0.56), boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0.145, 0.10, -0.15))
        addPart("BoltCarrier", Vector3.new(0.055, 0.15, 0.46), brightStl, Enum.Material.Metal, CFrame.new(0.135, 0.10, -0.15), { group = "Bolt" })
        addReceiverControls("Bucky", 0.155, -0.06, -0.35, 0.52, 0.44, brightStl)

        -- Heavy 12ga Cylindrical Barrel, Under-Tube Magazine, Clamp & Heat Shield
        addCylZ("ShotgunBarrel", 2.66, 0.21, steelMid, Enum.Material.Metal, CFrame.new(0, 0.13, -1.96))
        addHollowMuzzle("Bucky", 0.155, 0.13, -3.30, nil, nil)
        addCylZ("TubeMagazine", 2.24, 0.175, darkMetal, Enum.Material.Metal, CFrame.new(0, -0.09, -1.78))
        addCylZ("TubeCap", 0.18, 0.20, brightStl, Enum.Material.Metal, CFrame.new(0, -0.09, -2.92))
        addPart("BarrelClamp", Vector3.new(0.24, 0.34, 0.12), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.02, -2.76))
        addPart("HeatShield", Vector3.new(0.24, 0.11, 1.44), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.22, -1.48))
        addVentedSlots("BuckyShield", 0.22, -0.94, 0.20, 6, 0.122, 0.042, 0.09)

        -- Ghost ring + Front bead sight aligned at Y=0.415
        addIronSightSet("BuckyIrons", 0.415, -3.12, 0.64, darkMetal, Color3.fromRGB(255, 155, 40), "ghost")

        -- Ribbed Pump Slide Forend ("Pump" group)
        addPart("PumpSlide", Vector3.new(0.31, 0.27, 1.14), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.10, -1.42), { group = "Pump" })
        addPart("PumpCollar", Vector3.new(0.33, 0.29, 0.10), steelMid, Enum.Material.Metal, CFrame.new(0, -0.10, -0.84), { group = "Pump" })
        addPart("PumpHandStop", Vector3.new(0.26, 0.08, 0.12), gunmetal, Enum.Material.Metal, CFrame.new(0, -0.25, -1.92), { group = "Pump" })

        -- 4-Shell Left Receiver Side Saddle + Animated Loading Shell ("Magazine")
        addPart("SaddlePlate", Vector3.new(0.03, 0.18, 0.82), gunmetal, Enum.Material.Metal, CFrame.new(-0.165, -0.01, -0.02))
        for s = 0, 3 do
            local sz = -0.32 + s * 0.20
            addCylY("SideShellRed_" .. s, 0.22, 0.082, shellRed, Enum.Material.SmoothPlastic, CFrame.new(-0.18, 0.04, sz))
            addCylY("SideShellBrass_" .. s, 0.07, 0.088, brassCol, Enum.Material.Metal, CFrame.new(-0.18, -0.09, sz))
        end
        addCylZ("ReloadShellRed", 0.32, 0.095, shellRed, Enum.Material.SmoothPlastic, CFrame.new(0, -0.22, -0.22), { group = "Magazine" })
        addCylZ("ReloadShellBrass", 0.10, 0.10, brassCol, Enum.Material.Metal, CFrame.new(0, -0.22, -0.02), { group = "Magazine" })

        addTriggerAssembly("Bucky", -0.21, 0.16, darkMetal, Enum.Material.Metal)
        addPart("Grip", Vector3.new(0.24, 0.76, 0.34), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.46, 0.45) * CFrame.Angles(math.rad(-18), 0, 0))
        addPart("StockBody", Vector3.new(0.27, 0.62, 1.45), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.10, 1.55))
        addPart("RecoilPad", Vector3.new(0.29, 0.66, 0.18), Color3.fromRGB(16, 16, 18), Enum.Material.Rubber, CFrame.new(0, -0.10, 2.32))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 190, 55), Enum.Material.Neon, CFrame.new(0, 0.13, -3.35), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 8. JUDGE (Automatic Revolving Drum Shotgun)
    -- ----------------------------------------------------------------
    elseif wName == "JUDGE" then
        local dotCol = Color3.fromRGB(235, 55, 55)
        addPart("Receiver", Vector3.new(0.35, 0.50, 1.64), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0.04))
        addPicatinnyRail("JudgeRail", 0.72, -0.84, 0.29, 0.19, steelMid, 0.15)
        addReflexOptic("JudgeSight", 0.39, -0.08, darkMetal, dotCol)
        addReceiverControls("Judge", 0.175, -0.02, -0.45, 0.52, 0.28, steelMid)
        addPart("BoltHandle", Vector3.new(0.15, 0.075, 0.11), brightStl, Enum.Material.Metal, CFrame.new(0.21, 0.16, -0.10), { group = "Bolt" })

        -- Ribbed Revolving Drum Magazine ("Magazine")
        addCylZ("DrumBody", 0.78, 0.60, steelMid, Enum.Material.Metal, CFrame.new(0, -0.34, -0.25), { group = "Magazine" })
        addCylZ("DrumRingF", 0.09, 0.63, gunmetal, Enum.Material.Metal, CFrame.new(0, -0.34, -0.63), { group = "Magazine" })
        addCylZ("DrumRingR", 0.09, 0.63, gunmetal, Enum.Material.Metal, CFrame.new(0, -0.34, 0.13), { group = "Magazine" })
        addCylZ("DrumKey", 0.84, 0.16, brightStl, Enum.Material.Metal, CFrame.new(0, -0.34, -0.25), { group = "Magazine" })

        addCylZ("Barrel", 1.72, 0.23, steelMid, Enum.Material.Metal, CFrame.new(0, 0.12, -1.55))
        addPart("CompBox", Vector3.new(0.30, 0.28, 0.50), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.12, -2.48))
        addVentedSlots("JudgeBrake", 0.12, -2.35, 0.22, 2, 0.152, 0.13, 0.12)
        addHollowMuzzle("Judge", 0.155, 0.12, -2.74, nil, nil)
        addPart("VertForegrip", Vector3.new(0.17, 0.54, 0.21), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.38, -1.25))
        addTriggerAssembly("Judge", -0.22, 0.14, polymer, Enum.Material.SmoothPlastic)
        addPart("Grip", Vector3.new(0.24, 0.76, 0.36), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.46, 0.48) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("CQBStock", Vector3.new(0.29, 0.62, 1.14), gunmetal, Enum.Material.Metal, CFrame.new(0, -0.06, 1.35))
        addPart("CQBPad", Vector3.new(0.30, 0.64, 0.14), Color3.fromRGB(16, 16, 18), Enum.Material.Rubber, CFrame.new(0, -0.06, 1.94))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), dotCol, Enum.Material.Neon, CFrame.new(0, 0.12, -2.84), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 9. OPERATOR (.50 BMG Long-Range Anti-Material Sniper Rifle)
    -- ----------------------------------------------------------------
    elseif wName == "OPERATOR" then
        local opCrimson = Color3.fromRGB(190, 52, 58)
        addPart("BullpupChassis", Vector3.new(0.34, 0.52, 2.28), darkMetal, Enum.Material.Metal, CFrame.new(0, -0.02, 0.05))
        addPart("UpperMonolith", Vector3.new(0.29, 0.18, 2.15), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.22, -0.08))
        addPart("EjectionPort", Vector3.new(0.04, 0.15, 0.56), boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0.16, 0.16, 0.18))
        addVentedSlots("OpChassisSlot", 0.08, -0.15, 0.24, 4, 0.172, 0.055, 0.14)
        addPicatinnyRail("OpRail", 0.85, -1.85, 0.32, 0.19, steelMid, 0.16)
        addTelescopicScope("OpScope", 0.52, -0.26, darkMetal, gunmetal, opCrimson, 1.0)
        addPart("FoldedBUISF", Vector3.new(0.14, 0.042, 0.15), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.36, -1.72))
        addReceiverControls("Op", 0.17, -0.04, -0.35, 0.62, 0.38, steelMid)

        -- Machined Steel Bolt Arm + Knurled Ball ("Bolt" group preserves exact FPSController pivot!)
        addCylX("BoltArm", 0.24, 0.058, brightStl, Enum.Material.Metal, CFrame.new(0.24, 0.16, 0.42), { group = "Bolt" })
        addPart("BoltKnob", Vector3.new(0.105, 0.105, 0.105), steelMid, Enum.Material.Metal, CFrame.new(0.36, 0.14, 0.45), { group = "Bolt", shape = Enum.PartType.Ball })

        -- Fluted .50 Match Barrel + Baffled Barrett Tank Muzzle Brake + Hollow Crown
        addCylZ("BarrelCollar", 0.26, 0.28, gunmetal, Enum.Material.Metal, CFrame.new(0, 0.09, -1.16))
        addCylZ("HeavyBarrel", 2.86, 0.20, steelMid, Enum.Material.Metal, CFrame.new(0, 0.09, -2.35))
        addPart("OpFluteL", Vector3.new(0.025, 0.04, 1.85), darkMetal, Enum.Material.Metal, CFrame.new(-0.095, 0.09, -2.42))
        addPart("OpFluteR", Vector3.new(0.025, 0.04, 1.85), darkMetal, Enum.Material.Metal, CFrame.new(0.095, 0.09, -2.42))
        addPart("TankBrake", Vector3.new(0.40, 0.28, 0.72), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.09, -3.88))
        addVentedSlots("OpBrakePort", 0.09, -3.72, 0.28, 2, 0.205, 0.15, 0.16)
        addHollowMuzzle("Op", 0.125, 0.09, -4.25, nil, nil)

        -- Folded Twin Bipod + Rubber/Steel Feet
        addCylZ("BipodL", 1.15, 0.070, steelMid, Enum.Material.Metal, CFrame.new(-0.15, -0.22, -1.50))
        addCylZ("BipodR", 1.15, 0.070, steelMid, Enum.Material.Metal, CFrame.new(0.15, -0.22, -1.50))
        addPart("BipodFootL", Vector3.new(0.10, 0.11, 0.12), polymer, Enum.Material.Rubber, CFrame.new(-0.15, -0.22, -2.08))
        addPart("BipodFootR", Vector3.new(0.10, 0.11, 0.12), polymer, Enum.Material.Rubber, CFrame.new(0.15, -0.22, -2.08))
        addBoxMagWithBrass("OpMag", Vector3.new(0.24, 0.66, 0.54), darkMetal, gunmetal, brassCol, CFrame.new(0, -0.45, -0.15))

        addTriggerAssembly("Op", -0.23, 0.20, darkMetal, Enum.Material.Metal)
        addPart("Grip", Vector3.new(0.25, 0.78, 0.36), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.46, 0.55) * CFrame.Angles(math.rad(-16), 0, 0))
        addPart("SniperStock", Vector3.new(0.30, 0.70, 1.30), darkMetal, Enum.Material.Metal, CFrame.new(0, -0.05, 1.65))
        addPart("CheekPad", Vector3.new(0.32, 0.16, 0.68), polymer, Enum.Material.Rubber, CFrame.new(0, 0.32, 1.48))
        addPart("OpButtPad", Vector3.new(0.32, 0.74, 0.16), Color3.fromRGB(16, 16, 18), Enum.Material.Rubber, CFrame.new(0, -0.05, 2.34))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 185, 55), Enum.Material.Neon, CFrame.new(0, 0.09, -4.32), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 10. MARSHAL (Lever-Action Tactical Scout Sniper Rifle)
    -- ----------------------------------------------------------------
    elseif wName == "MARSHAL" then
        local amber = Color3.fromRGB(195, 148, 65)
        addPart("ScoutReceiver", Vector3.new(0.25, 0.36, 1.32), steelMid, Enum.Material.Metal, CFrame.new(0, 0.02, 0.02))
        addPart("LoadingGate", Vector3.new(0.024, 0.12, 0.32), brightStl, Enum.Material.Metal, CFrame.new(0.128, 0.03, -0.14))
        addPart("ReceiverHammer", Vector3.new(0.055, 0.12, 0.10), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.19, 0.62) * CFrame.Angles(math.rad(-25), 0, 0))
        addCylX("SaddlePin", 0.28, 0.042, brightStl, Enum.Material.Metal, CFrame.new(0, -0.05, 0.30))
        addPicatinnyRail("MarshalRail", 0.42, -0.62, 0.22, 0.15, darkMetal, 0.14)
        addTelescopicScope("MarshalScope", 0.39, -0.18, gunmetal, darkMetal, amber, 0.78)

        -- Tapered Barrel + Tubular Magazine + Barrel Bands + Low Backup Front Blade
        addCylZ("ScoutBarrel", 2.75, 0.145, darkMetal, Enum.Material.Metal, CFrame.new(0, 0.11, -1.95))
        addHollowMuzzle("Marshal", 0.088, 0.11, -3.33, nil, nil)
        addCylZ("UnderTube", 2.30, 0.105, gunmetal, Enum.Material.Metal, CFrame.new(0, -0.04, -1.72))
        addPart("BandF", Vector3.new(0.22, 0.25, 0.09), steelMid, Enum.Material.Metal, CFrame.new(0, 0.03, -2.52))
        addPart("BandR", Vector3.new(0.26, 0.28, 0.09), steelMid, Enum.Material.Metal, CFrame.new(0, 0.02, -1.25))
        addPart("WoodForend", Vector3.new(0.25, 0.23, 1.32), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.05, -1.28))
        addPart("MarshalFrontBase", Vector3.new(0.05, 0.045, 0.16), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.19, -3.14))

        -- Lever Loop ("Bolt" group preserves FPSController lever swing pivot (0,-0.14,0.04))
        addPart("LeverLoop", Vector3.new(0.075, 0.28, 0.50), brightStl, Enum.Material.Metal, CFrame.new(0, -0.30, 0.25) * CFrame.Angles(math.rad(-14), 0, 0), { group = "Bolt" })
        addPart("LeverTrigger", Vector3.new(0.026, 0.11, 0.036), darkMetal, Enum.Material.Metal, CFrame.new(0, -0.20, 0.20) * CFrame.Angles(math.rad(16), 0, 0))
        addCylZ("MarshalShell", 0.36, 0.078, brassCol, Enum.Material.Metal, CFrame.new(0.13, 0.05, 0.02), { group = "Magazine" })

        addPart("ScoutStock", Vector3.new(0.23, 0.52, 1.75), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.10, 1.48) * CFrame.Angles(math.rad(-6), 0, 0))
        addPart("MarshalButtPlate", Vector3.new(0.24, 0.54, 0.09), brassCol, Enum.Material.Metal, CFrame.new(0, -0.16, 2.34) * CFrame.Angles(math.rad(-6), 0, 0))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), amber, Enum.Material.Neon, CFrame.new(0, 0.11, -3.40), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 11. OUTLAW (Twin-Barrel Heavy Break-Action Marksman Sniper)
    -- ----------------------------------------------------------------
    elseif wName == "OUTLAW" then
        local crimson = Color3.fromRGB(185, 52, 52)
        addPart("BreechReceiver", Vector3.new(0.35, 0.42, 1.14), darkMetal, Enum.Material.Metal, CFrame.new(0, 0, 0.15))
        addPart("SidePlateL", Vector3.new(0.025, 0.24, 0.72), steelMid, Enum.Material.Metal, CFrame.new(-0.175, 0.02, 0.12))
        addPart("SidePlateR", Vector3.new(0.025, 0.24, 0.72), steelMid, Enum.Material.Metal, CFrame.new(0.175, 0.02, 0.12))
        addPicatinnyRail("OutlawRail", 0.20, -0.72, 0.23, 0.16, steelMid, 0.14)
        addTelescopicScope("OutlawScope", 0.41, -0.22, darkMetal, steelMid, crimson, 0.84)

        -- Twin parallel rifle barrels + soldered express rib + twin hollow muzzles
        addCylZ("BarrelL", 2.65, 0.155, steelMid, Enum.Material.Metal, CFrame.new(-0.085, 0.10, -1.68))
        addCylZ("BarrelR", 2.65, 0.155, steelMid, Enum.Material.Metal, CFrame.new(0.085, 0.10, -1.68))
        addPart("ExpressCenterRib", Vector3.new(0.075, 0.085, 2.58), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.16, -1.64))
        addCylZ("OutlawBoreL", 0.035, 0.092, boreBlack, Enum.Material.SmoothPlastic, CFrame.new(-0.085, 0.10, -3.01))
        addCylZ("OutlawBoreR", 0.035, 0.092, boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0.085, 0.10, -3.01))
        addPart("OutlawFrontBead", Vector3.new(0.022, 0.032, 0.022), brassCol, Enum.Material.Metal, CFrame.new(0, 0.215, -2.86))

        addPart("BarrelShroud", Vector3.new(0.32, 0.19, 1.15), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.02, -0.95))
        addCylX("HingePin", 0.37, 0.105, brightStl, Enum.Material.Metal, CFrame.new(0, -0.08, -0.45))

        addCylZ("ShellL", 0.44, 0.095, brassCol, Enum.Material.Metal, CFrame.new(-0.085, 0.10, -0.35), { group = "Magazine" })
        addCylZ("ShellR", 0.44, 0.095, brassCol, Enum.Material.Metal, CFrame.new(0.085, 0.10, -0.35), { group = "Magazine" })
        addPart("TopLatch", Vector3.new(0.085, 0.095, 0.24), brightStl, Enum.Material.Metal, CFrame.new(0, 0.24, 0.35), { group = "Bolt" })

        addTriggerAssembly("Outlaw", -0.20, 0.24, darkMetal, Enum.Material.Metal)
        addPart("Grip", Vector3.new(0.24, 0.70, 0.36), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.40, 0.56) * CFrame.Angles(math.rad(-20), 0, 0))
        addPart("Stock", Vector3.new(0.28, 0.60, 1.24), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.08, 1.38))
        addPart("OutlawPad", Vector3.new(0.29, 0.62, 0.14), Color3.fromRGB(16, 16, 18), Enum.Material.Rubber, CFrame.new(0, -0.08, 2.02))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 85, 75), Enum.Material.Neon, CFrame.new(0, 0.10, -3.08), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 12. ARES / ODIN (Heavy Squad Machine Guns)
    -- ----------------------------------------------------------------
    elseif wName == "ARES" or wName == "ODIN" then
        local heavyCol = (wName == "ODIN") and Color3.fromRGB(255, 85, 45) or Color3.fromRGB(225, 165, 40)
        addPart("LMGReceiver", Vector3.new(0.40, 0.50, 1.84), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.02, 0))
        addPart("FeedCover", Vector3.new(0.36, 0.11, 1.14), steelMid, Enum.Material.Metal, CFrame.new(0, 0.32, 0.05), { group = "Bolt" })
        addPicatinnyRail("LMGRail", 0.56, -0.46, 0.38, 0.19, darkMetal, 0.15)
        addReflexOptic("LMGSight", 0.43, 0.10, darkMetal, heavyCol)
        addPart("CarryBar", Vector3.new(0.075, 0.22, 0.88), steelMid, Enum.Material.Metal, CFrame.new(-0.22, 0.36, -0.40))
        addReceiverControls("LMG", 0.20, -0.04, -0.45, 0.58, 0.35, brightStl)

        -- Barrel(s) & Perforated Shroud (no neon vents!)
        if wName == "ODIN" then
            addCylZ("RotShroud", 1.64, 0.41, gunmetal, Enum.Material.Metal, CFrame.new(0, 0.06, -1.65))
            addVentedSlots("OdinVent", 0.06, -1.05, 0.24, 5, 0.208, 0.09, 0.12)
            for idx, off in ipairs({ { -0.09, 0.14 }, { 0.09, 0.14 }, { -0.09, -0.02 }, { 0.09, -0.02 } }) do
                addCylZ("MiniBarrel_" .. idx, 2.40, 0.092, steelMid, Enum.Material.Metal, CFrame.new(off[1], off[2], -2.10))
                addCylZ("MiniBore_" .. idx, 0.03, 0.055, boreBlack, Enum.Material.SmoothPlastic, CFrame.new(off[1], off[2], -3.31))
            end
            addCylZ("ClampDiscF", 0.12, 0.36, darkMetal, Enum.Material.Metal, CFrame.new(0, 0.06, -2.95))
        else
            addPart("CoolingShroud", Vector3.new(0.32, 0.32, 1.44), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.06, -1.55))
            addVentedSlots("AresVent", 0.06, -1.02, 0.22, 5, 0.165, 0.075, 0.11)
            addCylZ("HeavyLMGBarrel", 2.35, 0.165, steelMid, Enum.Material.Metal, CFrame.new(0, 0.08, -2.05))
            addSlottedBrake("AresMuzzle", 0.08, -3.28, 0.34, 0.22, brightStl, 0.095, 2)
        end

        -- Exposed Ammo Belt Links + Heavy Steel Drum Box ("Magazine")
        addPart("AmmoDrumBox", Vector3.new(0.54, 0.56, 0.70), oliveMatte, Enum.Material.Metal, CFrame.new(-0.10, -0.50, -0.25), { group = "Magazine" })
        addPart("DrumAccent", Vector3.new(0.56, 0.09, 0.72), gunmetal, Enum.Material.Metal, CFrame.new(-0.10, -0.50, -0.25), { group = "Magazine" })
        for b = 0, 3 do
            addCylZ("AmmoBelt_" .. b, 0.22, 0.064, brassCol, Enum.Material.Metal, CFrame.new(-0.24, -0.18 + b * 0.09, -0.25), { group = "Magazine" })
        end
        addTriggerAssembly("LMG", -0.23, 0.18, darkMetal, Enum.Material.Metal)
        addPart("Grip", Vector3.new(0.25, 0.78, 0.36), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.48, 0.52) * CFrame.Angles(math.rad(-15), 0, 0))
        addPart("LMGStock", Vector3.new(0.30, 0.68, 1.24), gunmetal, Enum.Material.Metal, CFrame.new(0, -0.06, 1.52))
        addPart("LMGButt", Vector3.new(0.31, 0.70, 0.14), Color3.fromRGB(16, 16, 18), Enum.Material.Rubber, CFrame.new(0, -0.06, 2.16))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), heavyCol, Enum.Material.Neon, CFrame.new(0, 0.08, -3.50), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 13. SHERIFF (Heavy 6-Shot .357 Magnum Revolver)
    -- ----------------------------------------------------------------
    elseif wName == "SHERIFF" then
        local revSteel = pCol or Color3.fromRGB(168, 174, 184)
        local revGlow = Color3.fromRGB(255, 110, 45)
        addPart("FrameBase", Vector3.new(0.21, 0.32, 0.86), revSteel, Enum.Material.Metal, CFrame.new(0, 0.02, -0.05))
        addPart("TopStrap", Vector3.new(0.15, 0.075, 0.70), revSteel, Enum.Material.Metal, CFrame.new(0, 0.21, -0.12))
        addPart("ThumbLatch", Vector3.new(0.03, 0.065, 0.11), gunmetal, Enum.Material.Metal, CFrame.new(-0.11, 0.10, 0.18))
        addTriggerAssembly("Sheriff", -0.15, -0.05, revSteel, Enum.Material.Metal)
        addPart("Hammer", Vector3.new(0.052, 0.145, 0.135), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.22, 0.34) * CFrame.Angles(math.rad(-28), 0, 0), { group = "Bolt" })

        -- Full-Underlug Barrel + Vent Rib + Hollow Bore + Iron Sights at Y=0.315
        addCylZ("MagnumBarrel", 1.20, 0.145, revSteel, Enum.Material.Metal, CFrame.new(0, 0.12, -1.05))
        addHollowMuzzle("Sheriff", 0.085, 0.12, -1.66, nil, nil)
        addPart("BarrelUnderlug", Vector3.new(0.17, 0.17, 1.14), revSteel, Enum.Material.Metal, CFrame.new(0, -0.01, -1.03))
        addCylZ("EjectorRod", 0.82, 0.055, gunmetal, Enum.Material.Metal, CFrame.new(0, -0.03, -0.82))
        addPart("TopRib", Vector3.new(0.105, 0.065, 1.15), gunmetal, Enum.Material.Metal, CFrame.new(0, 0.21, -1.03))
        addPistolIronSights(0.265, -1.52, 0.22, revGlow, darkMetal)

        -- Swinging 6-Chamber Cylindrical Drum ("Cylinder")
        addCylZ("RevolverDrum", 0.44, 0.34, brightStl, Enum.Material.Metal, CFrame.new(0, 0.05, -0.15), { group = "Cylinder" })
        for idx = 0, 5 do
            local ang = math.rad(idx * 60)
            local ox = math.cos(ang) * 0.10
            local oy = math.sin(ang) * 0.10
            addCylZ("ChamberBrass_" .. idx, 0.46, 0.066, brassCol, Enum.Material.Metal, CFrame.new(ox, 0.05 + oy, -0.15), { group = "Cylinder" })
        end
        addCylZ("SpeedloaderBase", 0.14, 0.30, darkMetal, Enum.Material.Metal, CFrame.new(-0.26, 0.05, 0.08), { group = "Magazine" })

        addPart("WoodGrip", Vector3.new(0.21, 0.70, 0.33), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.40, 0.34) * CFrame.Angles(math.rad(-22), 0, 0))
        addCylX("GripMedallion", 0.22, 0.075, brassCol, Enum.Material.Metal, CFrame.new(0, -0.34, 0.32))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), revGlow, Enum.Material.Neon, CFrame.new(0, 0.12, -1.72), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 14. SHORTY (Double-Barrel Break-Action Coach Sidearm)
    -- ----------------------------------------------------------------
    elseif wName == "SHORTY" then
        local shellRed = Color3.fromRGB(195, 38, 38)
        addCylZ("BarrelL", 1.48, 0.165, steelMid, Enum.Material.Metal, CFrame.new(-0.088, 0.09, -0.98))
        addCylZ("BarrelR", 1.48, 0.165, steelMid, Enum.Material.Metal, CFrame.new(0.088, 0.09, -0.98))
        addCylZ("ShortyBoreL", 0.035, 0.115, boreBlack, Enum.Material.SmoothPlastic, CFrame.new(-0.088, 0.09, -1.73))
        addCylZ("ShortyBoreR", 0.035, 0.115, boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0.088, 0.09, -1.73))
        addPart("TopRib", Vector3.new(0.075, 0.065, 1.42), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.16, -0.96))
        addPart("ShortyBead", Vector3.new(0.022, 0.030, 0.022), brassCol, Enum.Material.Metal, CFrame.new(0, 0.20, -1.62))
        addPart("Receiver", Vector3.new(0.31, 0.34, 0.84), darkMetal, Enum.Material.Metal, CFrame.new(0, 0, -0.05))
        addCylX("HingePin", 0.35, 0.105, brassCol, Enum.Material.Metal, CFrame.new(0, -0.08, -0.40))
        addPart("BreakSnapLever", Vector3.new(0.075, 0.095, 0.24), brightStl, Enum.Material.Metal, CFrame.new(0, 0.22, 0.22), { group = "Bolt" })
        addCylZ("BreakShellL", 0.34, 0.115, shellRed, Enum.Material.SmoothPlastic, CFrame.new(-0.088, 0.09, -0.25), { group = "Magazine" })
        addCylZ("BreakShellR", 0.34, 0.115, shellRed, Enum.Material.SmoothPlastic, CFrame.new(0.088, 0.09, -0.25), { group = "Magazine" })
        addTriggerAssembly("Shorty", -0.17, 0.10, darkMetal, Enum.Material.Metal)
        addPart("WoodForend", Vector3.new(0.29, 0.19, 0.78), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.07, -0.84))
        addPart("SawedGrip", Vector3.new(0.23, 0.65, 0.36), walnutWood, Enum.Material.Wood, CFrame.new(0, -0.40, 0.42) * CFrame.Angles(math.rad(-28), 0, 0))
        muzzleFlashPart = addPart("MuzzleFlashAnchor", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 185, 55), Enum.Material.Neon, CFrame.new(0, 0.09, -1.78), { isMuzzle = true })

    -- ----------------------------------------------------------------
    -- 15. CLASSIC / GHOST / FRENZY (Tactical Semi/Auto/Suppressed Pistols)
    -- ----------------------------------------------------------------
    else
        local isGhost = (wName == "GHOST")
        local isFrenzy = (wName == "FRENZY")
        local slideCol = isGhost and Color3.fromRGB(32, 36, 44) or (isFrenzy and Color3.fromRGB(48, 52, 60) or steelMid)
        local glowCol = isGhost and Color3.fromRGB(80, 200, 255) or (isFrenzy and Color3.fromRGB(255, 185, 45) or Color3.fromRGB(0, 255, 165))

        -- Moving CNC Machined Slide ("Bolt") + Ejection Port + Recessed Barrel
        addPart("Slide", Vector3.new(0.24, 0.27, 1.14), slideCol, Enum.Material.Metal, CFrame.new(0, 0.12, -0.18), { group = "Bolt" })
        addWedge("SlideBevel", Vector3.new(0.20, 0.055, 1.04), brightStl, Enum.Material.Metal, CFrame.new(0, 0.265, -0.16), { group = "Bolt" })
        addPart("SlideSerrations", Vector3.new(0.254, 0.19, 0.30), polymer, Enum.Material.DiamondPlate, CFrame.new(0, 0.12, 0.20), { group = "Bolt" })
        addPart("SlideEjectPort", Vector3.new(0.03, 0.10, 0.26), boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0.115, 0.17, -0.22), { group = "Bolt" })
        addCylZ("PistolBarrel", 0.56, 0.12, brightStl, Enum.Material.Metal, CFrame.new(0, 0.11, -0.78))

        if isGhost then
            addCylZ("PistolSuppCollar", 0.12, 0.25, steelMid, Enum.Material.Metal, CFrame.new(0, 0.11, -0.94))
            addCylZ("PistolSuppressor", 1.24, 0.23, darkMetal, Enum.Material.SmoothPlastic, CFrame.new(0, 0.11, -1.54))
            addHollowMuzzle("Ghost", 0.075, 0.11, -2.17, nil, nil)
            addPistolIronSights(0.29, -0.68, 0.32, glowCol, darkMetal)
        elseif isFrenzy then
            addPart("FrenzyComp", Vector3.new(0.23, 0.23, 0.26), darkMetal, Enum.Material.Metal, CFrame.new(0, 0.11, -0.92))
            addPart("CompPortTop", Vector3.new(0.11, 0.04, 0.12), boreBlack, Enum.Material.SmoothPlastic, CFrame.new(0, 0.22, -0.92))
            addHollowMuzzle("Frenzy", 0.075, 0.11, -1.06, nil, nil)
            addReflexOptic("FrenzyDot", 0.29, 0.05, darkMetal, glowCol)
        else
            addHollowMuzzle("Classic", 0.075, 0.11, -1.07, nil, nil)
            addPistolIronSights(0.27, -0.68, 0.32, glowCol, darkMetal)
        end

        addPart("PolymerFrame", Vector3.new(0.23, 0.21, 1.06), polymer, Enum.Material.SmoothPlastic, CFrame.new(0, -0.10, -0.18))
        addPart("UnderRail", Vector3.new(0.17, 0.055, 0.42), darkMetal, Enum.Material.Metal, CFrame.new(0, -0.215, -0.50))
        addCylX("SlideStopPin", 0.25, 0.036, brightStl, Enum.Material.Metal, CFrame.new(0, -0.04, -0.16))
        addTriggerAssembly("Pistol", -0.20, -0.14, polymer, Enum.Material.SmoothPlastic)
        addPart("GripPistol", Vector3.new(0.22, 0.70, 0.34), polymer, Enum.Material.DiamondPlate, CFrame.new(0, -0.44, 0.18) * CFrame.Angles(math.rad(-16), 0, 0))

        local magLen = isFrenzy and 0.90 or 0.68
        local magY = isFrenzy and -0.58 or -0.46
        addBoxMagWithBrass("PistolMag", Vector3.new(0.16, magLen, 0.25), darkMetal, steelMid, brassCol, CFrame.new(0, magY, 0.17) * CFrame.Angles(math.rad(-16), 0, 0))

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

-- สร้างโมเดลปืน 3D สำหรับวางโชว์ / Drop / Wall-Buy ให้หน้าตาตรงกับปืนที่ถือจริง 100%
function WeaponModelBuilder.buildDisplayModel(parentModel, weaponConfig, mountCF, opts)
    opts = opts or {}
    local scale = opts.scale or 1.0
    local anchorMode = opts.anchorMode or "BottomCenter"
    local castShadow = (opts.castShadow ~= false)

    local dummyRoot = { CFrame = CFrame.identity }
    local weaponParts = WeaponModelBuilder.build(parentModel, weaponConfig, dummyRoot)

    local visibleParts = {}
    for part, relCF in pairs(weaponParts) do
        local isTransient = part.Name:match("^MuzzleFlash")
            or part.Name == "SpeedloaderBase"
            or part.Name:match("^ReloadShell")
            or part.Name == "MarshalShell"
        if isTransient then
            part:Destroy()
        else
            visibleParts[part] = relCF
        end
    end

    local function computeLocalBounds(testScale)
        local minX, minY, minZ = math.huge, math.huge, math.huge
        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
        for part, relCF in pairs(visibleParts) do
            local sz = part.Size * testScale
            local scaledCF = (relCF - relCF.Position) + (relCF.Position * testScale)
            local rx, ry, rz = sz.X * 0.5, sz.Y * 0.5, sz.Z * 0.5
            local right = scaledCF.RightVector
            local up = scaledCF.UpVector
            local look = scaledCF.LookVector
            local ex = math.abs(right.X) * rx + math.abs(up.X) * ry + math.abs(look.X) * rz
            local ey = math.abs(right.Y) * rx + math.abs(up.Y) * ry + math.abs(look.Y) * rz
            local ez = math.abs(right.Z) * rx + math.abs(up.Z) * ry + math.abs(look.Z) * rz
            local c = scaledCF.Position
            minX = math.min(minX, c.X - ex)
            maxX = math.max(maxX, c.X + ex)
            minY = math.min(minY, c.Y - ey)
            maxY = math.max(maxY, c.Y + ey)
            minZ = math.min(minZ, c.Z - ez)
            maxZ = math.max(maxZ, c.Z + ez)
        end
        if minX == math.huge then
            return Vector3.zero, Vector3.zero, Vector3.one
        end
        return Vector3.new(minX, minY, minZ), Vector3.new(maxX, maxY, maxZ), Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
    end

    local minV, maxV, sizeV = computeLocalBounds(scale)
    if opts.maxLength and sizeV.Z > opts.maxLength and sizeV.Z > 0.01 then
        scale = scale * (opts.maxLength / sizeV.Z)
        minV, maxV, sizeV = computeLocalBounds(scale)
    end

    local midX = (minV.X + maxV.X) * 0.5
    local midY = (minV.Y + maxV.Y) * 0.5
    local midZ = (minV.Z + maxV.Z) * 0.5
    local shift = (anchorMode == "Center")
        and Vector3.new(-midX, -midY, -midZ)
        or Vector3.new(-midX, -minV.Y, -midZ)

    local primaryPart = nil
    for part, relCF in pairs(visibleParts) do
        part.Size = part.Size * scale
        local pos = relCF.Position * scale + shift
        local orientedCF = (relCF - relCF.Position) + pos
        part.CFrame = mountCF * orientedCF
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = castShadow
        if not primaryPart or part.Name:match("Receiver") or part.Name:match("Body") or part.Name:match("Frame") then
            primaryPart = part
        end
    end

    return primaryPart, sizeV, visibleParts
end

return WeaponModelBuilder
