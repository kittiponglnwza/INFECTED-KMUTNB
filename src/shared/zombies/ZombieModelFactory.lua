--[[
    ZombieModelFactory.lua
    Builds R15-compatible zombie character rigs across the 3 archetypes:
      - Male (MaleWalker, MaleRunner) ~ 5.06-5.15 studs
      - Female (FemaleWalker, FemaleRunner) ~ 4.88-4.95 studs
      - Male Boss (MaleBoss) ~ 9.00 studs (~1.75x standard player)

    Asset Override Workflow:
      - If a Studio-imported custom R15 MeshPart Model is placed in
        ReplicatedStorage.Assets.Zombies.<TemplateName> (or fallback category name),
        this factory clones and wires that custom model first.
      - Otherwise, it builds a full 15-part articulated R15 rig with Motor6D joints,
        Animator, sculpted anatomy/clothing details, wounds, and floor-aligned soles.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZombieCatalog = require(script.Parent.ZombieCatalog)

local ZombieModelFactory = {}

local R15_MOTOR_NAMES = {
    "Root",
    "Waist",
    "Neck",
    "LeftShoulder",
    "LeftElbow",
    "LeftWrist",
    "RightShoulder",
    "RightElbow",
    "RightWrist",
    "LeftHip",
    "LeftKnee",
    "LeftAnkle",
    "RightHip",
    "RightKnee",
    "RightAnkle",
}

local function resolveHitZoneFromName(partName)
    local lower = string.lower(partName)
    if string.find(lower, "head", 1, true)
        or string.find(lower, "jaw", 1, true)
        or string.find(lower, "eye", 1, true)
        or string.find(lower, "brow", 1, true)
        or string.find(lower, "hair", 1, true)
        or string.find(lower, "fang", 1, true)
        or string.find(lower, "face", 1, true)
    then
        return "Head"
    elseif string.find(lower, "leg", 1, true)
        or string.find(lower, "foot", 1, true)
        or string.find(lower, "knee", 1, true)
        or string.find(lower, "shoe", 1, true)
        or string.find(lower, "boot", 1, true)
        or string.find(lower, "sock", 1, true)
    then
        return "Legs"
    end
    return "Body"
end

local function tagPart(part, hitZone, canCollide, canQuery)
    part:SetAttribute("HitZone", hitZone)
    part:SetAttribute("BaseTransparency", part.Transparency)
    part.CanCollide = canCollide
    part.CanTouch = false
    part.CanQuery = canQuery
end

local function makePart(parent, name, size, color, material, shape, canCollide, canQuery, hitZone)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Shape = shape or Enum.PartType.Block
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Anchored = false
    p.Massless = (name ~= "HumanoidRootPart" and name ~= "LowerTorso" and name ~= "UpperTorso")
    tagPart(p, hitZone or "Body", canCollide or false, canQuery ~= false)
    p.Parent = parent
    return p
end

local function weldTo(parentModel, childPart, targetPart, relCF)
    childPart.CFrame = targetPart.CFrame * (relCF or CFrame.identity)
    local w = Instance.new("WeldConstraint")
    w.Part0 = targetPart
    w.Part1 = childPart
    w.Parent = childPart
    childPart.Parent = parentModel
    return childPart
end

local function attachDetail(model, targetLimb, name, size, relCF, color, material, options)
    options = options or {}
    local part
    if options.isWedge then
        part = Instance.new("WedgePart")
        part.Name = name
        part.Size = size
        part.Color = color
        part.Material = material or Enum.Material.SmoothPlastic
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Anchored = false
        part.Massless = true
        part.Transparency = options.transparency or 0
        tagPart(part, options.hitZone or resolveHitZoneFromName(targetLimb.Name), false, options.canQuery ~= false)
    else
        part = makePart(
            model,
            name,
            size,
            color,
            material,
            options.shape,
            false,
            options.canQuery ~= false,
            options.hitZone or resolveHitZoneFromName(targetLimb.Name)
        )
        part.Transparency = options.transparency or 0
    end

    if options.meshType then
        local m = Instance.new("SpecialMesh")
        m.MeshType = options.meshType
        m.Scale = options.meshScale or Vector3.new(1, 1, 1)
        m.Parent = part
    end

    part:SetAttribute("BaseTransparency", part.Transparency)
    return weldTo(model, part, targetLimb, relCF)
end

local function attachMotor(part0, part1, name, jointWorldCF)
    local motor = Instance.new("Motor6D")
    motor.Name = name
    motor.Part0 = part0
    motor.Part1 = part1
    motor.C0 = part0.CFrame:Inverse() * jointWorldCF
    motor.C1 = part1.CFrame:Inverse() * jointWorldCF
    motor.Parent = part1
    return motor
end

local function addWoundAndBlood(model, limb, woundSpecs, app, s)
    for idx, spec in ipairs(woundSpecs) do
        local bruiseSize = Vector3.new(spec.size.X * 1.35, spec.size.Y * 1.35, 0.04 * s)
        attachDetail(model, limb, "Bruise_" .. limb.Name .. "_" .. idx, bruiseSize, spec.cf, app.bruiseColor, Enum.Material.Slate, {
            meshType = Enum.MeshType.Sphere,
            canQuery = false,
            transparency = 0.25,
        })
        attachDetail(model, limb, "Wound_" .. limb.Name .. "_" .. idx, spec.size, spec.cf * CFrame.new(0, 0, -0.015 * s), app.bloodColor, Enum.Material.Glass, {
            meshType = Enum.MeshType.Sphere,
            canQuery = false,
        })
    end
end

local function addMaleHeadDetails(model, head, hSize, app, s)
    local headMesh = Instance.new("SpecialMesh")
    headMesh.MeshType = Enum.MeshType.Head
    headMesh.Scale = Vector3.new(1.06, 1.04, 1.06)
    headMesh.Parent = head

    -- Sculpted strong jaw & brow ridge (distinct male skull structure)
    attachDetail(model, head, "MaleBrowRidge", Vector3.new(hSize.X * 0.80, hSize.Y * 0.14, hSize.Z * 0.24),
        CFrame.new(0, hSize.Y * 0.18, -hSize.Z * 0.41) * CFrame.Angles(math.rad(-8), 0, 0),
        app.skinColor, Enum.Material.Slate, { hitZone = "Head", canQuery = false })
    attachDetail(model, head, "MaleJaw", Vector3.new(hSize.X * 0.72, hSize.Y * 0.28, hSize.Z * 0.66),
        CFrame.new(0, -hSize.Y * 0.34, -hSize.Z * 0.14),
        app.skinColor, Enum.Material.Slate, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })

    -- Ears
    for _, side in ipairs({ -1, 1 }) do
        attachDetail(model, head, "Ear_" .. side, Vector3.new(0.14 * s, 0.26 * s, 0.16 * s),
            CFrame.new(side * hSize.X * 0.50, -0.02 * s, 0.04 * s),
            app.skinColor, Enum.Material.Slate, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
    end

    -- Deep shadowed eye sockets & pale infected / feral eyes
    local eyeMat = app.eyeGlow and Enum.Material.Neon or Enum.Material.SmoothPlastic
    for _, side in ipairs({ -1, 1 }) do
        attachDetail(model, head, "Socket_" .. side, Vector3.new(0.24 * s, 0.19 * s, 0.10 * s),
            CFrame.new(side * 0.21 * s, 0.08 * s, -hSize.Z * 0.45),
            app.bruiseColor, Enum.Material.Slate, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
        attachDetail(model, head, "Eyes_" .. side, Vector3.new(0.14 * s, 0.10 * s, 0.08 * s),
            CFrame.new(side * 0.21 * s, 0.08 * s, -hSize.Z * 0.48),
            app.eyeColor, eyeMat, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
    end

    -- Mouth laceration & dried blood on chin
    attachDetail(model, head, "MouthGash", Vector3.new(0.38 * s, 0.10 * s, 0.12 * s),
        CFrame.new(0.02 * s, -hSize.Y * 0.24, -hSize.Z * 0.47),
        app.bloodColor, Enum.Material.Glass, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
    attachDetail(model, head, "CheekScar", Vector3.new(0.24 * s, 0.16 * s, 0.06 * s),
        CFrame.new(-0.30 * s, -0.10 * s, -hSize.Z * 0.40) * CFrame.Angles(0, math.rad(28), math.rad(-14)),
        app.rotColor, Enum.Material.Glass, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })

    -- Short tousled male hair
    attachDetail(model, head, "HairCap", Vector3.new(hSize.X * 0.96, hSize.Y * 0.36, hSize.Z * 0.98),
        CFrame.new(0, hSize.Y * 0.36, 0.03 * s),
        app.hairColor, Enum.Material.Fabric, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
    attachDetail(model, head, "HairBack", Vector3.new(hSize.X * 0.88, hSize.Y * 0.56, hSize.Z * 0.32),
        CFrame.new(0, hSize.Y * 0.10, hSize.Z * 0.38),
        app.hairColor, Enum.Material.Fabric, { hitZone = "Head", canQuery = false })
    for i = -1, 1 do
        attachDetail(model, head, "HairTuft_" .. i, Vector3.new(0.24 * s, 0.20 * s, 0.26 * s),
            CFrame.new(i * 0.24 * s, hSize.Y * 0.43, -hSize.Z * 0.22) * CFrame.Angles(math.rad(16), i * math.rad(10), 0),
            app.hairColor, Enum.Material.Fabric, { isWedge = true, hitZone = "Head", canQuery = false })
    end
end

local function addFemaleHeadDetails(model, head, hSize, app, s)
    local headMesh = Instance.new("SpecialMesh")
    headMesh.MeshType = Enum.MeshType.Head
    headMesh.Scale = Vector3.new(0.98, 1.05, 0.98)
    headMesh.Parent = head

    -- Softer slender cheekbones & tapered chin
    attachDetail(model, head, "FemaleChin", Vector3.new(hSize.X * 0.52, hSize.Y * 0.22, hSize.Z * 0.54),
        CFrame.new(0, -hSize.Y * 0.35, -hSize.Z * 0.16),
        app.skinColor, Enum.Material.Slate, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })

    -- Expressive sunken eyes & gaunt cheek shadows
    local eyeMat = app.eyeGlow and Enum.Material.Neon or Enum.Material.SmoothPlastic
    for _, side in ipairs({ -1, 1 }) do
        attachDetail(model, head, "Socket_" .. side, Vector3.new(0.23 * s, 0.21 * s, 0.10 * s),
            CFrame.new(side * 0.20 * s, 0.08 * s, -hSize.Z * 0.43),
            app.bruiseColor, Enum.Material.Slate, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
        attachDetail(model, head, "Eyes_" .. side, Vector3.new(0.14 * s, 0.12 * s, 0.08 * s),
            CFrame.new(side * 0.20 * s, 0.09 * s, -hSize.Z * 0.46),
            app.eyeColor, eyeMat, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
    end

    -- Screaming dark crimson mouth stain & bite tear
    attachDetail(model, head, "FemaleMouth", Vector3.new(0.32 * s, 0.15 * s, 0.12 * s),
        CFrame.new(0, -hSize.Y * 0.22, -hSize.Z * 0.44),
        app.bloodColor, Enum.Material.Glass, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
    attachDetail(model, head, "FaceSlash", Vector3.new(0.22 * s, 0.08 * s, 0.06 * s),
        CFrame.new(0.24 * s, -0.04 * s, -hSize.Z * 0.40) * CFrame.Angles(0, math.rad(-25), math.rad(32)),
        app.rotColor, Enum.Material.Glass, { hitZone = "Head", canQuery = false })

    -- Unique female hairstyle: crown + parted framing bangs + trailing ponytail / layered bob
    attachDetail(model, head, "HairCrown", Vector3.new(hSize.X * 1.02, hSize.Y * 0.44, hSize.Z * 1.04),
        CFrame.new(0, hSize.Y * 0.34, 0.05 * s),
        app.hairColor, Enum.Material.Fabric, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
    for _, side in ipairs({ -1, 1 }) do
        attachDetail(model, head, "HairSideLock_" .. side, Vector3.new(0.22 * s, 0.88 * s, 0.36 * s),
            CFrame.new(side * hSize.X * 0.46, -0.08 * s, -0.10 * s) * CFrame.Angles(math.rad(-4), 0, math.rad(side * -7)),
            app.hairColor, Enum.Material.Fabric, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
        attachDetail(model, head, "HairBangs_" .. side, Vector3.new(0.38 * s, 0.36 * s, 0.22 * s),
            CFrame.new(side * 0.22 * s, hSize.Y * 0.24, -hSize.Z * 0.42) * CFrame.Angles(math.rad(12), side * math.rad(-14), math.rad(side * 16)),
            app.hairColor, Enum.Material.Fabric, { isWedge = true, hitZone = "Head", canQuery = false })
    end

    if app.hairStyle == "LongPonytail" then
        attachDetail(model, head, "HairBackPlate", Vector3.new(hSize.X * 0.88, hSize.Y * 0.72, 0.26 * s),
            CFrame.new(0, 0.02 * s, hSize.Z * 0.42),
            app.hairColor, Enum.Material.Fabric, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
        attachDetail(model, head, "PonytailTie", Vector3.new(0.24 * s, 0.20 * s, 0.24 * s),
            CFrame.new(0, 0.14 * s, hSize.Z * 0.56),
            app.shirtAccentColor, Enum.Material.Fabric, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
        attachDetail(model, head, "PonytailUpper", Vector3.new(0.38 * s, 0.96 * s, 0.34 * s),
            CFrame.new(0.04 * s, -0.22 * s, hSize.Z * 0.66) * CFrame.Angles(math.rad(22), 0, math.rad(-5)),
            app.hairColor, Enum.Material.Fabric, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
        attachDetail(model, head, "PonytailTip", Vector3.new(0.26 * s, 0.80 * s, 0.24 * s),
            CFrame.new(0.08 * s, -0.88 * s, hSize.Z * 0.86) * CFrame.Angles(math.rad(14), 0, math.rad(-8)),
            app.hairColor, Enum.Material.Fabric, { isWedge = true, hitZone = "Head", canQuery = false })
    else
        -- Shrieker messy jagged bob
        attachDetail(model, head, "BobBack", Vector3.new(hSize.X * 0.98, hSize.Y * 0.86, 0.36 * s),
            CFrame.new(0, -0.10 * s, hSize.Z * 0.42) * CFrame.Angles(math.rad(10), 0, 0),
            app.hairColor, Enum.Material.Fabric, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
    end
end

local function addBossHeadDetails(model, head, hSize, app, s)
    local headMesh = Instance.new("SpecialMesh")
    headMesh.MeshType = Enum.MeshType.Head
    headMesh.Scale = Vector3.new(1.12, 1.05, 1.12)
    headMesh.Parent = head

    -- Mutated heavy brow ridge + asymmetric bone ridge
    attachDetail(model, head, "BossBrowRidge", Vector3.new(hSize.X * 0.96, 0.34 * s, 0.52 * s),
        CFrame.new(0, hSize.Y * 0.18, -hSize.Z * 0.38) * CFrame.Angles(math.rad(-14), 0, math.rad(-4)),
        app.skinColor, Enum.Material.Slate, { hitZone = "Head", canQuery = false })
    attachDetail(model, head, "BossSkullSpike", Vector3.new(0.28 * s, 0.66 * s, 0.34 * s),
        CFrame.new(0.42 * s, hSize.Y * 0.44, -0.05 * s) * CFrame.Angles(math.rad(-16), 0, math.rad(-22)),
        app.boneColor, Enum.Material.Limestone, { isWedge = true, hitZone = "Head", canQuery = false })

    -- Mutated split mandible + protruding jagged lower fangs
    attachDetail(model, head, "BossMutatedJaw", Vector3.new(hSize.X * 0.86, hSize.Y * 0.38, hSize.Z * 0.78),
        CFrame.new(0.05 * s, -hSize.Y * 0.36, -hSize.Z * 0.18) * CFrame.Angles(math.rad(12), 0, math.rad(-6)),
        app.bruiseColor, Enum.Material.Slate, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
    attachDetail(model, head, "BossMawCavity", Vector3.new(0.76 * s, 0.34 * s, 0.24 * s),
        CFrame.new(0.03 * s, -hSize.Y * 0.28, -hSize.Z * 0.46),
        app.bloodColor, Enum.Material.Glass, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
    for idx, xOff in ipairs({ -0.26, -0.09, 0.11, 0.28 }) do
        attachDetail(model, head, "BossFang_" .. idx, Vector3.new(0.11 * s, 0.24 * s, 0.11 * s),
            CFrame.new(xOff * s, -hSize.Y * 0.32, -hSize.Z * 0.50) * CFrame.Angles(math.rad(-8), 0, 0),
            app.boneColor, Enum.Material.Limestone, { isWedge = true, hitZone = "Head", canQuery = false })
    end

    -- Recessed glowing ember eyes & cranial infection veins
    for _, side in ipairs({ -1, 1 }) do
        attachDetail(model, head, "BossSocket_" .. side, Vector3.new(0.36 * s, 0.26 * s, 0.18 * s),
            CFrame.new(side * 0.32 * s, 0.06 * s, -hSize.Z * 0.44),
            Color3.fromRGB(22, 10, 12), Enum.Material.Slate, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
        attachDetail(model, head, "BossEye_" .. side, Vector3.new(0.18 * s, 0.13 * s, 0.10 * s),
            CFrame.new(side * 0.32 * s, 0.06 * s, -hSize.Z * 0.48),
            app.eyeColor, Enum.Material.Neon, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
    end
    attachDetail(model, head, "BossInfectionRupture", Vector3.new(0.44 * s, 0.54 * s, 0.20 * s),
        CFrame.new(-0.52 * s, 0.12 * s, 0.10 * s) * CFrame.Angles(0, 0, math.rad(18)),
        app.coreGlowColor, Enum.Material.Neon, { meshType = Enum.MeshType.Sphere, hitZone = "Head", canQuery = false })
end

local function addMaleClothing(model, limbs, P, app, s)
    local upperTorso, lowerTorso = limbs.UpperTorso, limbs.LowerTorso
    local uSize = P.upperTorsoSize
    local lSize = P.lowerTorsoSize

    if app.clothingStyle == "StudentShirtTie" then
        -- Crisp-turned-bloodied student uniform shirt + crooked tie
        attachDetail(model, upperTorso, "ShirtShell", uSize + Vector3.new(0.08 * s, 0.04 * s, 0.08 * s),
            CFrame.identity, app.shirtColor, Enum.Material.Fabric, { canQuery = false })
        for _, side in ipairs({ -1, 1 }) do
            attachDetail(model, upperTorso, "ShirtCollar_" .. side, Vector3.new(0.34 * s, 0.16 * s, 0.46 * s),
                CFrame.new(side * 0.24 * s, uSize.Y * 0.48, -0.14 * s) * CFrame.Angles(math.rad(16), side * math.rad(-20), math.rad(side * -14)),
                app.shirtColor, Enum.Material.Fabric, { isWedge = true, canQuery = false })
        end
        attachDetail(model, upperTorso, "NeckTie", Vector3.new(0.18 * s, 0.82 * s, 0.07 * s),
            CFrame.new(0.06 * s, 0.06 * s, -uSize.Z * 0.56) * CFrame.Angles(math.rad(-6), 0, math.rad(-14)),
            app.shirtAccentColor, Enum.Material.Fabric, { canQuery = false })
        attachDetail(model, upperTorso, "Pocket", Vector3.new(0.28 * s, 0.30 * s, 0.04 * s),
            CFrame.new(0.36 * s, 0.18 * s, -uSize.Z * 0.56),
            app.shirtColor:Lerp(Color3.new(0.85, 0.85, 0.85), 0.2), Enum.Material.Fabric, { canQuery = false })
    else
        -- Ragged torn runner jacket/hoodie
        attachDetail(model, upperTorso, "RunnerJacket", uSize + Vector3.new(0.08 * s, 0.06 * s, 0.08 * s),
            CFrame.identity, app.shirtColor, Enum.Material.Fabric, { canQuery = false })
        attachDetail(model, upperTorso, "ExposedRibChest", Vector3.new(0.56 * s, 0.62 * s, 0.12 * s),
            CFrame.new(-0.22 * s, 0.02 * s, -uSize.Z * 0.52),
            app.bloodColor, Enum.Material.Glass, { meshType = Enum.MeshType.Sphere, canQuery = false })
    end

    -- Belt & slacks waist
    attachDetail(model, lowerTorso, "PelvisPants", lSize + Vector3.new(0.06 * s, 0.04 * s, 0.06 * s),
        CFrame.identity, app.pantsColor, Enum.Material.Fabric, { canQuery = false })
    attachDetail(model, lowerTorso, "Belt", Vector3.new(lSize.X + 0.12 * s, 0.16 * s, lSize.Z + 0.12 * s),
        CFrame.new(0, lSize.Y * 0.36, 0), Color3.fromRGB(22, 20, 20), Enum.Material.Leather, { canQuery = false })

    -- Sleeves on upper arms + cuffed forearms
    for _, sideName in ipairs({ "Left", "Right" }) do
        local uArm = limbs[sideName .. "UpperArm"]
        local len = (sideName == "Right") and uArm.Size.Y * 0.58 or uArm.Size.Y * 0.72
        attachDetail(model, uArm, sideName .. "Sleeve", Vector3.new(uArm.Size.X + 0.07 * s, len, uArm.Size.Z + 0.07 * s),
            CFrame.new(0, (uArm.Size.Y - len) * 0.45, 0), app.shirtColor, Enum.Material.Fabric, { canQuery = false })
    end

    -- Pants legs & shoes
    for _, sideName in ipairs({ "Left", "Right" }) do
        local uLeg = limbs[sideName .. "UpperLeg"]
        local lLeg = limbs[sideName .. "LowerLeg"]
        local foot = limbs[sideName .. "Foot"]
        attachDetail(model, uLeg, sideName .. "TrouserUpper", uLeg.Size + Vector3.new(0.06 * s, 0.04 * s, 0.06 * s),
            CFrame.identity, app.pantsColor, Enum.Material.Fabric, { hitZone = "Legs", canQuery = false })
        local cuffLen = (sideName == "Right") and lLeg.Size.Y * 0.68 or lLeg.Size.Y * 0.88
        attachDetail(model, lLeg, sideName .. "TrouserLower", Vector3.new(lLeg.Size.X + 0.05 * s, cuffLen, lLeg.Size.Z + 0.05 * s),
            CFrame.new(0, (lLeg.Size.Y - cuffLen) * 0.48, 0), app.pantsColor, Enum.Material.Fabric, { hitZone = "Legs", canQuery = false })
        attachDetail(model, foot, sideName .. "Shoe", foot.Size + Vector3.new(0.04 * s, 0.02 * s, 0.04 * s),
            CFrame.identity, app.shoeColor, Enum.Material.Leather, { hitZone = "Legs", canQuery = false })
    end

    addWoundAndBlood(model, upperTorso, {
        { size = Vector3.new(0.46 * s, 0.44 * s, 0.08 * s), cf = CFrame.new(0.28 * s, -0.06 * s, -uSize.Z * 0.53) },
        { size = Vector3.new(0.32 * s, 0.36 * s, 0.08 * s), cf = CFrame.new(-0.34 * s, 0.24 * s, -uSize.Z * 0.52) },
    }, app, s)
    addWoundAndBlood(model, limbs.LeftLowerArm, {
        { size = Vector3.new(0.18 * s, 0.38 * s, 0.08 * s), cf = CFrame.new(0, 0.04 * s, -limbs.LeftLowerArm.Size.Z * 0.50) },
    }, app, s)
end

local function addFemaleClothing(model, limbs, P, app, s)
    local upperTorso, lowerTorso = limbs.UpperTorso, limbs.LowerTorso
    local uSize = P.upperTorsoSize
    local lSize = P.lowerTorsoSize

    -- Contoured female torso silhouette (narrow waist + sculpted bust + fitted blouse)
    attachDetail(model, upperTorso, "FemaleBlouse", Vector3.new(uSize.X + 0.04 * s, uSize.Y * 0.96, uSize.Z + 0.04 * s),
        CFrame.identity, app.shirtColor, Enum.Material.Fabric, { canQuery = false })
    attachDetail(model, upperTorso, "FemaleBustContour", Vector3.new(uSize.X * 0.92, uSize.Y * 0.36, 0.22 * s),
        CFrame.new(0, uSize.Y * 0.08, -uSize.Z * 0.48),
        app.shirtColor, Enum.Material.Fabric, { meshType = Enum.MeshType.Sphere, canQuery = false })
    attachDetail(model, lowerTorso, "FemaleWaistBase", Vector3.new(lSize.X * 0.90, lSize.Y, lSize.Z * 0.92),
        CFrame.identity, app.pantsColor, Enum.Material.Fabric, { canQuery = false })

    if app.clothingStyle == "StudentBlouseSkirt" then
        -- Neck ribbon + pleated student skirt overlapping lower torso & upper thighs
        attachDetail(model, upperTorso, "CollarRibbonCenter", Vector3.new(0.18 * s, 0.14 * s, 0.08 * s),
            CFrame.new(0, uSize.Y * 0.38, -uSize.Z * 0.54),
            app.shirtAccentColor, Enum.Material.Fabric, { canQuery = false })
        for _, side in ipairs({ -1, 1 }) do
            attachDetail(model, upperTorso, "CollarRibbonTail_" .. side, Vector3.new(0.12 * s, 0.28 * s, 0.06 * s),
                CFrame.new(side * 0.12 * s, uSize.Y * 0.22, -uSize.Z * 0.54) * CFrame.Angles(math.rad(-8), 0, math.rad(side * 22)),
                app.shirtAccentColor, Enum.Material.Fabric, { isWedge = true, canQuery = false })
        end
        -- Flared pleated skirt ring welded to LowerTorso
        attachDetail(model, lowerTorso, "PleatedSkirtBody", Vector3.new(lSize.X * 1.18, 0.66 * s, lSize.Z * 1.24),
            CFrame.new(0, -0.22 * s, 0),
            app.pantsColor, Enum.Material.Fabric, { canQuery = false })
        for pIdx = -2, 2 do
            attachDetail(model, lowerTorso, "SkirtPleatF_" .. pIdx, Vector3.new(0.22 * s, 0.66 * s, 0.10 * s),
                CFrame.new(pIdx * 0.25 * s, -0.22 * s, -lSize.Z * 0.63) * CFrame.Angles(math.rad(-10), 0, 0),
                app.pantsColor, Enum.Material.Fabric, { isWedge = true, canQuery = false })
        end
    else
        -- Torn track shorts/leggings for Female Shrieker
        attachDetail(model, upperTorso, "TrackZipperLine", Vector3.new(0.08 * s, uSize.Y * 0.88, 0.06 * s),
            CFrame.new(0, 0, -uSize.Z * 0.53),
            app.shirtAccentColor, Enum.Material.Fabric, { canQuery = false })
    end

    -- Short fitted sleeves & socks/shoes
    for _, sideName in ipairs({ "Left", "Right" }) do
        local uArm = limbs[sideName .. "UpperArm"]
        attachDetail(model, uArm, sideName .. "ShortSleeve", Vector3.new(uArm.Size.X + 0.06 * s, uArm.Size.Y * 0.42, uArm.Size.Z + 0.06 * s),
            CFrame.new(0, uArm.Size.Y * 0.28, 0), app.shirtColor, Enum.Material.Fabric, { canQuery = false })
        local lLeg = limbs[sideName .. "LowerLeg"]
        local foot = limbs[sideName .. "Foot"]
        attachDetail(model, lLeg, sideName .. "KneeSock", Vector3.new(lLeg.Size.X + 0.04 * s, lLeg.Size.Y * 0.65, lLeg.Size.Z + 0.04 * s),
            CFrame.new(0, -lLeg.Size.Y * 0.16, 0), Color3.fromRGB(205, 200, 198), Enum.Material.Fabric, { hitZone = "Legs", canQuery = false })
        attachDetail(model, foot, sideName .. "Loafer", foot.Size + Vector3.new(0.03 * s, 0.02 * s, 0.03 * s),
            CFrame.identity, app.shoeColor, Enum.Material.Leather, { hitZone = "Legs", canQuery = false })
    end

    -- Bite wound on female neck/collarbone + bloodstains on blouse & forearm
    addWoundAndBlood(model, upperTorso, {
        { size = Vector3.new(0.32 * s, 0.24 * s, 0.08 * s), cf = CFrame.new(-0.30 * s, uSize.Y * 0.34, -uSize.Z * 0.46) },
        { size = Vector3.new(0.44 * s, 0.48 * s, 0.08 * s), cf = CFrame.new(0.16 * s, -0.14 * s, -uSize.Z * 0.52) },
    }, app, s)
    addWoundAndBlood(model, limbs.RightLowerArm, {
        { size = Vector3.new(0.16 * s, 0.32 * s, 0.06 * s), cf = CFrame.new(0, 0, -limbs.RightLowerArm.Size.Z * 0.48) },
    }, app, s)
end

local function addBossMutationsAndArmor(model, limbs, P, app, s)
    local upperTorso, lowerTorso = limbs.UpperTorso, limbs.LowerTorso
    local uSize = P.upperTorsoSize
    local lSize = P.lowerTorsoSize

    -- Massive hunched trapezius muscle hump + dorsal spinal bone spikes
    attachDetail(model, upperTorso, "BossTrapeziusHump", Vector3.new(uSize.X * 0.90, 1.35 * s, 1.38 * s),
        CFrame.new(-0.18 * s, uSize.Y * 0.34, 0.46 * s) * CFrame.Angles(math.rad(-22), 0, math.rad(6)),
        app.skinColor, Enum.Material.Slate, { meshType = Enum.MeshType.Sphere, canQuery = false })
    for idx = 1, 4 do
        attachDetail(model, upperTorso, "BossSpineSpike_" .. idx, Vector3.new(0.28 * s, 0.62 * s, 0.48 * s),
            CFrame.new(0.02 * s, uSize.Y * (0.34 - (idx - 1) * 0.22), uSize.Z * 0.58) * CFrame.Angles(math.rad(62), 0, 0),
            app.boneColor, Enum.Material.Limestone, { isWedge = true, canQuery = false })
    end

    -- Giant asymmetric bone shoulder eruption on Left Shoulder
    attachDetail(model, limbs.LeftUpperArm, "BossShoulderBoneHornA", Vector3.new(0.46 * s, 1.05 * s, 0.50 * s),
        CFrame.new(-0.35 * s, limbs.LeftUpperArm.Size.Y * 0.48, 0.05 * s) * CFrame.Angles(math.rad(-12), 0, math.rad(34)),
        app.boneColor, Enum.Material.Limestone, { isWedge = true, canQuery = false })
    attachDetail(model, limbs.LeftUpperArm, "BossShoulderBoneHornB", Vector3.new(0.32 * s, 0.72 * s, 0.36 * s),
        CFrame.new(0.05 * s, limbs.LeftUpperArm.Size.Y * 0.56, 0.16 * s) * CFrame.Angles(math.rad(-24), 0, math.rad(14)),
        app.boneColor, Enum.Material.Limestone, { isWedge = true, canQuery = false })

    -- Exposed glowing infection chest cavity + ribcage bones + shredded tactical vest straps
    attachDetail(model, upperTorso, "BossVestLeft", Vector3.new(uSize.X * 0.42, uSize.Y * 0.94, uSize.Z + 0.14 * s),
        CFrame.new(-uSize.X * 0.28, -0.02 * s, 0), app.shirtColor, Enum.Material.Fabric, { canQuery = false })
    attachDetail(model, upperTorso, "BossChestCavity", Vector3.new(1.22 * s, 1.24 * s, 0.38 * s),
        CFrame.new(0.42 * s, 0.04 * s, -uSize.Z * 0.46), app.bloodColor, Enum.Material.Glass, { meshType = Enum.MeshType.Sphere, canQuery = false })
    attachDetail(model, upperTorso, "BossMutationCore", Vector3.new(0.76 * s, 0.82 * s, 0.34 * s),
        CFrame.new(0.42 * s, 0.06 * s, -uSize.Z * 0.52), app.coreGlowColor, Enum.Material.Neon, { meshType = Enum.MeshType.Sphere, canQuery = false })
    for rIdx = -1, 1 do
        attachDetail(model, upperTorso, "BossRib_" .. rIdx, Vector3.new(0.95 * s, 0.16 * s, 0.14 * s),
            CFrame.new(0.44 * s, 0.06 * s + rIdx * 0.28 * s, -uSize.Z * 0.58) * CFrame.Angles(0, math.rad(16), math.rad(10)),
            app.boneColor, Enum.Material.Limestone, { canQuery = false })
    end

    -- Heavy industrial belt & chains + shredded trousers + steel-toe combat boots
    attachDetail(model, lowerTorso, "BossPantsPelvis", lSize + Vector3.new(0.12 * s, 0.08 * s, 0.12 * s),
        CFrame.identity, app.pantsColor, Enum.Material.Fabric, { canQuery = false })
    attachDetail(model, lowerTorso, "BossUtilityBelt", Vector3.new(lSize.X + 0.28 * s, 0.36 * s, lSize.Z + 0.28 * s),
        CFrame.new(0, lSize.Y * 0.28, 0), Color3.fromRGB(48, 42, 36), Enum.Material.Metal, { canQuery = false })
    attachDetail(model, lowerTorso, "BossChainBuckle", Vector3.new(0.68 * s, 0.44 * s, 0.18 * s),
        CFrame.new(0, lSize.Y * 0.28, -(lSize.Z + 0.26 * s) * 0.52), Color3.fromRGB(115, 118, 124), Enum.Material.Metal, { canQuery = false })

    -- Giant mutated right claw arm details: crimson veins & 3 long jagged bone claws
    local rUpper = limbs.RightUpperArm
    local rLower = limbs.RightLowerArm
    local rHand = limbs.RightHand
    attachDetail(model, rUpper, "BossRightMuscleBulge", Vector3.new(rUpper.Size.X * 1.18, rUpper.Size.Y * 0.85, rUpper.Size.Z * 1.18),
        CFrame.new(0.08 * s, 0, 0), app.skinColor, Enum.Material.Slate, { meshType = Enum.MeshType.Sphere, canQuery = false })
    attachDetail(model, rLower, "BossRightVeinGlow", Vector3.new(0.22 * s, rLower.Size.Y * 0.82, rLower.Size.Z * 1.04),
        CFrame.new(0.14 * s, 0, -0.08 * s), app.coreGlowColor, Enum.Material.Neon, { meshType = Enum.MeshType.Sphere, canQuery = false })
    for cIdx = -1, 1 do
        attachDetail(model, rHand, "BossClaw_" .. cIdx, Vector3.new(0.14 * s, 1.08 * s, 0.18 * s),
            CFrame.new(cIdx * 0.22 * s, -rHand.Size.Y * 0.72, -0.10 * s) * CFrame.Angles(math.rad(-22), 0, math.rad(cIdx * -5)),
            app.boneColor, Enum.Material.Limestone, { isWedge = true, canQuery = false })
    end

    -- Torn guard boots & calves
    for _, sideName in ipairs({ "Left", "Right" }) do
        local uLeg = limbs[sideName .. "UpperLeg"]
        local lLeg = limbs[sideName .. "LowerLeg"]
        local foot = limbs[sideName .. "Foot"]
        attachDetail(model, uLeg, sideName .. "BossCargo", uLeg.Size + Vector3.new(0.12 * s, 0.06 * s, 0.12 * s),
            CFrame.identity, app.pantsColor, Enum.Material.Fabric, { hitZone = "Legs", canQuery = false })
        attachDetail(model, lLeg, sideName .. "BossShinGuard", Vector3.new(lLeg.Size.X + 0.14 * s, lLeg.Size.Y * 0.56, lLeg.Size.Z + 0.14 * s),
            CFrame.new(0, -lLeg.Size.Y * 0.20, 0), app.shoeColor, Enum.Material.Metal, { hitZone = "Legs", canQuery = false })
        attachDetail(model, foot, sideName .. "BossBoot", foot.Size + Vector3.new(0.12 * s, 0.06 * s, 0.14 * s),
            CFrame.identity, app.shoeColor, Enum.Material.Leather, { hitZone = "Legs", canQuery = false })
    end
end

local function collectMotorsAndBaseC0(model)
    local motors = {}
    local baseC0s = {}
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("Motor6D") then
            motors[desc.Name] = desc
            baseC0s[desc.Name] = desc.C0
        end
    end
    return motors, baseC0s
end

local function tryBuildFromCustomTemplate(archetype, config)
    local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
    local zombiesAssets = assetsFolder and (assetsFolder:FindFirstChild("Zombies") or assetsFolder:FindFirstChild("zombies"))
    if not zombiesAssets then
        return nil
    end

    local candidates = { archetype.TemplateName }
    for _, fb in ipairs(archetype.FallbackTemplateNames or {}) do
        table.insert(candidates, fb)
    end

    local template = nil
    for _, name in ipairs(candidates) do
        -- Search both directly and nested inside assets/zombies/{male,female,boss}/
        local found = zombiesAssets:FindFirstChild(name, true)
            or zombiesAssets:FindFirstChild(string.lower(name), true)
        if found and found:IsA("Model") then
            template = found
            break
        elseif found and found:IsA("Folder") then
            template = found:FindFirstChildWhichIsA("Model")
            if template then
                break
            end
        end
    end
    if not template then
        return nil
    end

    local model = template:Clone()
    model.Name = config.modelName or ("Zombie_" .. archetype.Id)

    local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    local head = model:FindFirstChild("Head")
    local upperTorso = model:FindFirstChild("UpperTorso")
    local lowerTorso = model:FindFirstChild("LowerTorso")
    if not hrp or not head then
        model:Destroy()
        return nil
    end

    model.PrimaryPart = hrp
    local humanoid = model:FindFirstChildOfClass("Humanoid") or Instance.new("Humanoid")
    humanoid.RigType = Enum.HumanoidRigType.R15
    humanoid.BreakJointsOnDeath = false
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    humanoid.Parent = model

    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
    animator.Parent = humanoid

    local canCollideMain = (config.canCollideMain ~= false)
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            local hz = desc:GetAttribute("HitZone") or resolveHitZoneFromName(desc.Name)
            desc.Anchored = (config.anchored == true)
            if desc == hrp then
                desc.Transparency = 1
                tagPart(desc, "Body", canCollideMain, false)
            else
                tagPart(desc, hz, false, true)
            end
        end
    end

    local spawnCF = config.spawnPos and CFrame.new(config.spawnPos) or CFrame.new(config.groundPos or Vector3.zero)
    if config.groundPos then
        local _, bboxSize = model:GetBoundingBox()
        local yOffset = (bboxSize.Y * 0.5)
        spawnCF = CFrame.new(config.groundPos + Vector3.new(0, yOffset, 0))
    end
    if config.facingDeg then
        spawnCF = spawnCF * CFrame.Angles(0, math.rad(config.facingDeg), 0)
    end
    model:PivotTo(spawnCF)

    local motors, baseC0s = collectMotorsAndBaseC0(model)
    return {
        model = model,
        archetype = archetype,
        hrp = hrp,
        head = head,
        upperTorso = upperTorso,
        lowerTorso = lowerTorso,
        humanoid = humanoid,
        animator = animator,
        motors = motors,
        baseC0s = baseC0s,
        rootMotor = motors.Root,
        rootBaseCF = baseC0s.Root,
        neckMotor = motors.Neck,
        neckBaseCF = baseC0s.Neck,
        shoulderL = motors.LeftShoulder,
        shoulderR = motors.RightShoulder,
        shoulderBaseL = baseC0s.LeftShoulder,
        shoulderBaseR = baseC0s.RightShoulder,
        hipL = motors.LeftHip,
        hipR = motors.RightHip,
        hipBaseL = baseC0s.LeftHip,
        hipBaseR = baseC0s.RightHip,
        torso = upperTorso or hrp,
        height = archetype.TargetHeight,
        isCustomMeshTemplate = true,
    }
end

function ZombieModelFactory.build(config)
    config = config or {}
    local archetype = ZombieCatalog.get(config.zombieType)

    local customRig = tryBuildFromCustomTemplate(archetype, config)
    if customRig then
        return customRig
    end

    local P = archetype.Proportions
    local app = archetype.Appearance
    local s = archetype.TargetHeight / 5.15
    local skinMat = Enum.Material.Slate

    local model = Instance.new("Model")
    model.Name = config.modelName or ("Zombie_" .. archetype.Id)

    -- Compute exact R15 joint heights relative to floor (Y = 0) so soles never float or sink
    local footH = P.footSize.Y
    local lowerLegH = P.lowerLegSize.Y
    local upperLegH = P.upperLegSize.Y

    local footY = footH * 0.5
    local ankleY = footH
    local lowerLegY = footH + lowerLegH * 0.5
    local kneeY = footH + lowerLegH
    local upperLegY = kneeY + upperLegH * 0.5
    local hipY = kneeY + upperLegH

    local lowerTorsoY = hipY + P.lowerTorsoSize.Y * 0.36
    local waistY = lowerTorsoY + P.lowerTorsoSize.Y * 0.44
    local upperTorsoY = waistY + P.upperTorsoSize.Y * 0.48
    local shoulderY = upperTorsoY + P.upperTorsoSize.Y * 0.36
    local neckY = upperTorsoY + P.upperTorsoSize.Y * 0.50
    local headY = neckY + P.neckGap + P.headSize.Y * 0.50

    local hrpCenterY = lowerTorsoY + P.upperTorsoSize.Y * 0.34
    local hipHeight = math.max(0.25, hrpCenterY - P.humanoidRootSize.Y * 0.5)

    -- Resolve exact placement in world coordinates
    local facingRad = math.rad(config.facingDeg or 0)
    local baseOrigin
    if config.groundPos then
        baseOrigin = CFrame.new(config.groundPos) * CFrame.Angles(0, facingRad, 0)
    else
        local sp = config.spawnPos or Vector3.new(0, 5, 0)
        baseOrigin = CFrame.new(sp) * CFrame.Angles(0, facingRad, 0)
    end

    local canCollideMain = (config.canCollideMain ~= false)
    local anchored = (config.anchored == true)

    local function place(localPos)
        return baseOrigin * CFrame.new(localPos)
    end

    -- Root & Torso
    local hrp = makePart(model, "HumanoidRootPart", P.humanoidRootSize, Color3.fromRGB(160, 160, 160), Enum.Material.SmoothPlastic, Enum.PartType.Block, canCollideMain, false, "Body")
    hrp.Transparency = 1
    hrp.CFrame = place(Vector3.new(0, hrpCenterY, 0))
    hrp.Massless = false

    local lowerTorso = makePart(model, "LowerTorso", P.lowerTorsoSize, app.pantsColor, Enum.Material.Fabric, Enum.PartType.Block, false, true, "Body")
    lowerTorso.CFrame = place(Vector3.new(0, lowerTorsoY, 0))

    local upperTorso = makePart(model, "UpperTorso", P.upperTorsoSize, app.skinColor, skinMat, Enum.PartType.Block, false, true, "Body")
    upperTorso.CFrame = place(Vector3.new(0, upperTorsoY, 0))

    local head = makePart(model, "Head", P.headSize, app.skinColor, skinMat, Enum.PartType.Block, false, true, "Head")
    head.CFrame = place(Vector3.new(0, headY, 0))

    -- Arms (Right arm magnified for Male Boss mutation)
    local limbs = {
        HumanoidRootPart = hrp,
        LowerTorso = lowerTorso,
        UpperTorso = upperTorso,
        Head = head,
    }

    local shoulderX = P.upperTorsoSize.X * 0.50 + P.upperArmSize.X * 0.52
    for _, side in ipairs({ -1, 1 }) do
        local sideName = (side == -1) and "Left" or "Right"
        local armMul = (side == 1) and (P.rightArmScale or 1.0) or 1.0

        local uArmSize = Vector3.new(P.upperArmSize.X * armMul, P.upperArmSize.Y * (1 + (armMul - 1) * 0.65), P.upperArmSize.Z * armMul)
        local lArmSize = Vector3.new(P.lowerArmSize.X * armMul, P.lowerArmSize.Y * (1 + (armMul - 1) * 0.72), P.lowerArmSize.Z * armMul)
        local handSize = Vector3.new(P.handSize.X * armMul, P.handSize.Y * armMul, P.handSize.Z * armMul)

        local armX = side * (P.upperTorsoSize.X * 0.50 + uArmSize.X * 0.52)
        local uArmY = shoulderY - uArmSize.Y * 0.42
        local elbowY = uArmY - uArmSize.Y * 0.48
        local lArmY = elbowY - lArmSize.Y * 0.48
        local wristY = lArmY - lArmSize.Y * 0.48
        local handY = wristY - handSize.Y * 0.46

        local uArm = makePart(model, sideName .. "UpperArm", uArmSize, app.skinColor, skinMat, Enum.PartType.Block, false, true, "Body")
        uArm.CFrame = place(Vector3.new(armX, uArmY, 0))
        local lArm = makePart(model, sideName .. "LowerArm", lArmSize, app.skinColor, skinMat, Enum.PartType.Block, false, true, "Body")
        lArm.CFrame = place(Vector3.new(armX, lArmY, 0))
        local hand = makePart(model, sideName .. "Hand", handSize, app.skinColor, skinMat, Enum.PartType.Block, false, true, "Body")
        hand.CFrame = place(Vector3.new(armX, handY, 0))

        limbs[sideName .. "UpperArm"] = uArm
        limbs[sideName .. "LowerArm"] = lArm
        limbs[sideName .. "Hand"] = hand

        attachMotor(upperTorso, uArm, sideName .. "Shoulder", place(Vector3.new(side * shoulderX, shoulderY, 0)))
        attachMotor(uArm, lArm, sideName .. "Elbow", place(Vector3.new(armX, elbowY, 0)))
        attachMotor(lArm, hand, sideName .. "Wrist", place(Vector3.new(armX, wristY, 0)))
    end

    -- Legs
    for _, side in ipairs({ -1, 1 }) do
        local sideName = (side == -1) and "Left" or "Right"
        local legX = side * P.hipSpacing

        local uLeg = makePart(model, sideName .. "UpperLeg", P.upperLegSize, app.skinColor, skinMat, Enum.PartType.Block, false, true, "Legs")
        uLeg.CFrame = place(Vector3.new(legX, upperLegY, 0))
        local lLeg = makePart(model, sideName .. "LowerLeg", P.lowerLegSize, app.skinColor, skinMat, Enum.PartType.Block, false, true, "Legs")
        lLeg.CFrame = place(Vector3.new(legX, lowerLegY, 0))
        local foot = makePart(model, sideName .. "Foot", P.footSize, app.shoeColor, Enum.Material.Leather, Enum.PartType.Block, false, true, "Legs")
        foot.CFrame = place(Vector3.new(legX, footY, -P.footSize.Z * 0.16))

        limbs[sideName .. "UpperLeg"] = uLeg
        limbs[sideName .. "LowerLeg"] = lLeg
        limbs[sideName .. "Foot"] = foot

        attachMotor(lowerTorso, uLeg, sideName .. "Hip", place(Vector3.new(legX, hipY, 0)))
        attachMotor(uLeg, lLeg, sideName .. "Knee", place(Vector3.new(legX, kneeY, 0)))
        attachMotor(lLeg, foot, sideName .. "Ankle", place(Vector3.new(legX, ankleY, 0)))
    end

    -- Spine & Neck Motors
    attachMotor(hrp, lowerTorso, "Root", place(Vector3.new(0, lowerTorsoY, 0)))
    attachMotor(lowerTorso, upperTorso, "Waist", place(Vector3.new(0, waistY, 0)))
    attachMotor(upperTorso, head, "Neck", place(Vector3.new(0, neckY, 0)))

    -- Apply distinct anatomy, face, hair, clothing & wounds by category
    if archetype.Category == "Female" then
        addFemaleHeadDetails(model, head, P.headSize, app, s)
        addFemaleClothing(model, limbs, P, app, s)
    elseif archetype.Category == "Boss" then
        addBossHeadDetails(model, head, P.headSize, app, s)
        addBossMutationsAndArmor(model, limbs, P, app, s)
    else
        addMaleHeadDetails(model, head, P.headSize, app, s)
        addMaleClothing(model, limbs, P, app, s)
    end

    -- Ensure Humanoid & Animator always exist cleanly on the rig
    model.PrimaryPart = hrp
    local humanoid = Instance.new("Humanoid")
    humanoid.RigType = Enum.HumanoidRigType.R15
    humanoid.AutomaticScalingEnabled = false
    humanoid.BreakJointsOnDeath = false
    humanoid.HipHeight = hipHeight
    humanoid.WalkSpeed = anchored and 0 or archetype.WalkSpeed
    humanoid.JumpPower = 50
    humanoid.MaxHealth = archetype.MaxHealth
    humanoid.Health = archetype.MaxHealth
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    humanoid.AutoRotate = true
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    humanoid.Parent = model

    local animator = Instance.new("Animator")
    animator.Parent = humanoid

    if anchored then
        if config.anchorRootOnly then
            hrp.Anchored = true
            for _, p in ipairs(model:GetDescendants()) do
                if p:IsA("BasePart") and p ~= hrp then
                    p.Anchored = false
                    p.CanCollide = false
                end
            end
        else
            for _, p in ipairs(model:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.Anchored = true
                    p.CanCollide = false
                end
            end
        end
    end

    local motors, baseC0s = collectMotorsAndBaseC0(model)
    for _, motorName in ipairs(R15_MOTOR_NAMES) do
        if not motors[motorName] then
            warn("[ZombieModelFactory] Missing expected R15 motor:", motorName, archetype.Id)
        end
    end

    return {
        model = model,
        archetype = archetype,
        hrp = hrp,
        head = head,
        upperTorso = upperTorso,
        lowerTorso = lowerTorso,
        torso = upperTorso,
        humanoid = humanoid,
        animator = animator,
        motors = motors,
        baseC0s = baseC0s,
        rootMotor = motors.Root,
        rootBaseCF = baseC0s.Root,
        neckMotor = motors.Neck,
        neckBaseCF = baseC0s.Neck,
        shoulderL = motors.LeftShoulder,
        shoulderR = motors.RightShoulder,
        shoulderBaseL = baseC0s.LeftShoulder,
        shoulderBaseR = baseC0s.RightShoulder,
        hipL = motors.LeftHip,
        hipR = motors.RightHip,
        hipBaseL = baseC0s.LeftHip,
        hipBaseR = baseC0s.RightHip,
        height = archetype.TargetHeight,
        hipHeight = hipHeight,
        isCustomMeshTemplate = false,
    }
end

return ZombieModelFactory
