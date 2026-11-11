--[[
    ZombieCatalog.lua
    Centralized data specification for all INFECTED-KMUTNB zombie archetypes.
    Defines 3 distinct character categories:
      - Male (MaleWalker, MaleRunner) -> Standard Roblox player height (~5.15 studs)
      - Female (FemaleWalker, FemaleRunner) -> Standard Roblox female avatar height (~4.95 studs)
      - Male Boss (MaleBoss) -> Mutated male threat (~9.0 studs, ~1.75x player height)

    Asset ID Policy:
      - All AnimationIds and CustomSoundIds start EMPTY ("" / {}) intentionally.
      - Never invent rbxassetid:// numbers. Populate verified Roblox Studio IDs here
        after publishing animations or uploading licensed audio.
      - Until custom sound assets are configured, ZombieAudioController synthesizes
        3D vocal/footstep profiles exclusively from verified local engine assets
        under rbxasset://sounds/.
]]

local ZombieCatalog = {}

ZombieCatalog.ANIMATION_STATES = {
    "Idle",
    "Walking",
    "Running",
    "Chasing",
    "Attacking",
    "TakingDamage",
    "Stunned",
    "Death",
}

ZombieCatalog.AUDIO_EVENTS = {
    "Idle",
    "Walking",
    "Running",
    "Chasing",
    "Attacking",
    "TakingDamage",
    "Death",
}

local EMPTY_ANIMATION_IDS = {
    Idle = "",
    Walking = "",
    Running = "",
    Chasing = "",
    Attacking = "",
    TakingDamage = "",
    Stunned = "",
    Death = "",
}

local function makeEmptySoundIdMap()
    return {
        Idle = {},
        Walking = {},
        Running = {},
        Chasing = {},
        Attacking = {},
        TakingDamage = {},
        Death = {},
    }
end

ZombieCatalog.ARCHETYPES = {
    MaleWalker = {
        Id = "MaleWalker",
        DisplayName = "MALE INFECTED",
        Category = "Male",
        Gender = "Male",
        Role = "Walker",
        IsBoss = false,
        TemplateName = "MaleWalker",
        FallbackTemplateNames = { "Male" },

        -- True Roblox player height: ~5.15 studs
        TargetHeight = 5.15,
        MaxHealth = 125,
        WalkSpeed = 14.0,
        RunSpeed = 15.8,
        ChaseSpeed = 17.2,
        AttackDamage = 16,
        AttackRange = 5.8,
        AttackCooldown = 1.05,
        StunThreshold = 55,
        StunDuration = 0.70,
        PointRewardKill = 50,
        PointRewardHeadshotKill = 100,

        Proportions = {
            footSize = Vector3.new(0.46, 0.24, 0.84),
            lowerLegSize = Vector3.new(0.46, 0.96, 0.48),
            upperLegSize = Vector3.new(0.52, 1.00, 0.54),
            hipSpacing = 0.30,
            lowerTorsoSize = Vector3.new(1.30, 0.58, 0.74),
            upperTorsoSize = Vector3.new(1.56, 1.24, 0.84),
            shoulderSpan = 1.04,
            upperArmSize = Vector3.new(0.42, 0.96, 0.44),
            lowerArmSize = Vector3.new(0.36, 0.90, 0.38),
            handSize = Vector3.new(0.34, 0.36, 0.24),
            neckGap = 0.14,
            headSize = Vector3.new(1.06, 1.18, 1.10),
            humanoidRootSize = Vector3.new(1.60, 2.00, 1.00),
            rightArmScale = 1.00,
        },

        Appearance = {
            skinColor = Color3.fromRGB(134, 150, 128),
            bruiseColor = Color3.fromRGB(82, 74, 88),
            rotColor = Color3.fromRGB(72, 92, 68),
            shirtColor = Color3.fromRGB(204, 206, 202),
            shirtAccentColor = Color3.fromRGB(28, 38, 66),
            pantsColor = Color3.fromRGB(28, 32, 42),
            shoeColor = Color3.fromRGB(22, 22, 24),
            bloodColor = Color3.fromRGB(115, 14, 18),
            hairColor = Color3.fromRGB(26, 24, 24),
            eyeColor = Color3.fromRGB(205, 212, 182),
            eyeGlow = false,
            hairStyle = "ShortMale",
            clothingStyle = "StudentShirtTie",
        },

        AnimationProfile = {
            category = "Male",
            hunchRad = math.rad(-13),
            strideDeg = 32,
            kneeBendDeg = 38,
            armReachDeg = 42,
            swayDeg = 6,
            headTwitchRate = 1.45,
            attackStyle = "DoubleSlash",
            AnimationIds = table.clone(EMPTY_ANIMATION_IDS),
        },

        AudioProfile = {
            VocalClass = "Male",
            RollOffMin = 6,
            RollOffMax = 54,
            StepRollOffMax = 38,
            BaseVolume = 0.44,
            PitchRange = { 0.44, 0.56 },
            ScreechPitchRange = { 0.52, 0.66 },
            StepPitchRange = { 0.84, 1.00 },
            DistortionLevel = 0.58,
            EqLowGain = 5,
            EqMidGain = 2,
            EqHighGain = -6,
            ReverbWet = -24,
            IdleInterval = { 3.5, 6.2 },
            ChaseInterval = { 2.0, 3.4 },
            StepIntervalWalk = 0.44,
            StepIntervalRun = 0.28,
            CustomSoundIds = makeEmptySoundIdMap(),
        },
    },

    MaleRunner = {
        Id = "MaleRunner",
        DisplayName = "MALE RUNNER",
        Category = "Male",
        Gender = "Male",
        Role = "Runner",
        IsBoss = false,
        TemplateName = "MaleRunner",
        FallbackTemplateNames = { "Male" },

        TargetHeight = 5.06,
        MaxHealth = 95,
        WalkSpeed = 16.5,
        RunSpeed = 19.8,
        ChaseSpeed = 21.6,
        AttackDamage = 13,
        AttackRange = 5.8,
        AttackCooldown = 0.85,
        StunThreshold = 42,
        StunDuration = 0.65,
        PointRewardKill = 60,
        PointRewardHeadshotKill = 115,

        Proportions = {
            footSize = Vector3.new(0.42, 0.22, 0.80),
            lowerLegSize = Vector3.new(0.41, 0.96, 0.43),
            upperLegSize = Vector3.new(0.46, 0.98, 0.48),
            hipSpacing = 0.28,
            lowerTorsoSize = Vector3.new(1.18, 0.56, 0.68),
            upperTorsoSize = Vector3.new(1.42, 1.22, 0.76),
            shoulderSpan = 0.94,
            upperArmSize = Vector3.new(0.38, 0.96, 0.40),
            lowerArmSize = Vector3.new(0.32, 0.92, 0.34),
            handSize = Vector3.new(0.32, 0.36, 0.22),
            neckGap = 0.14,
            headSize = Vector3.new(1.00, 1.16, 1.06),
            humanoidRootSize = Vector3.new(1.48, 1.96, 0.94),
            rightArmScale = 1.02,
        },

        Appearance = {
            skinColor = Color3.fromRGB(146, 126, 118),
            bruiseColor = Color3.fromRGB(96, 52, 58),
            rotColor = Color3.fromRGB(115, 42, 44),
            shirtColor = Color3.fromRGB(64, 52, 54),
            shirtAccentColor = Color3.fromRGB(130, 26, 30),
            pantsColor = Color3.fromRGB(36, 36, 40),
            shoeColor = Color3.fromRGB(32, 24, 24),
            bloodColor = Color3.fromRGB(136, 12, 16),
            hairColor = Color3.fromRGB(24, 20, 20),
            eyeColor = Color3.fromRGB(255, 68, 45),
            eyeGlow = true,
            hairStyle = "TornMale",
            clothingStyle = "RaggedHoodie",
        },

        AnimationProfile = {
            category = "Male",
            hunchRad = math.rad(-22),
            strideDeg = 42,
            kneeBendDeg = 50,
            armReachDeg = 58,
            swayDeg = 9,
            headTwitchRate = 2.30,
            attackStyle = "FeralLunge",
            AnimationIds = table.clone(EMPTY_ANIMATION_IDS),
        },

        AudioProfile = {
            VocalClass = "Male",
            RollOffMin = 6,
            RollOffMax = 58,
            StepRollOffMax = 42,
            BaseVolume = 0.48,
            PitchRange = { 0.56, 0.72 },
            ScreechPitchRange = { 0.80, 1.02 },
            StepPitchRange = { 0.94, 1.12 },
            DistortionLevel = 0.68,
            EqLowGain = 2,
            EqMidGain = 5,
            EqHighGain = -2,
            ReverbWet = -22,
            IdleInterval = { 2.8, 5.0 },
            ChaseInterval = { 1.5, 2.7 },
            StepIntervalWalk = 0.36,
            StepIntervalRun = 0.22,
            CustomSoundIds = makeEmptySoundIdMap(),
        },
    },

    FemaleWalker = {
        Id = "FemaleWalker",
        DisplayName = "FEMALE INFECTED",
        Category = "Female",
        Gender = "Female",
        Role = "Walker",
        IsBoss = false,
        TemplateName = "FemaleWalker",
        FallbackTemplateNames = { "Female" },

        -- True Roblox female avatar height: ~4.95 studs, distinct narrower silhouette
        TargetHeight = 4.95,
        MaxHealth = 110,
        WalkSpeed = 14.5,
        RunSpeed = 16.4,
        ChaseSpeed = 18.0,
        AttackDamage = 15,
        AttackRange = 5.7,
        AttackCooldown = 0.98,
        StunThreshold = 45,
        StunDuration = 0.72,
        PointRewardKill = 50,
        PointRewardHeadshotKill = 100,

        Proportions = {
            footSize = Vector3.new(0.36, 0.22, 0.74),
            lowerLegSize = Vector3.new(0.36, 0.94, 0.38),
            upperLegSize = Vector3.new(0.42, 0.98, 0.44),
            hipSpacing = 0.26,
            lowerTorsoSize = Vector3.new(1.16, 0.54, 0.68), -- flared hip base under pinched waist
            upperTorsoSize = Vector3.new(1.22, 1.16, 0.70), -- narrower shoulders
            shoulderSpan = 0.84,
            upperArmSize = Vector3.new(0.32, 0.90, 0.34),
            lowerArmSize = Vector3.new(0.28, 0.86, 0.30),
            handSize = Vector3.new(0.26, 0.32, 0.18),
            neckGap = 0.14,
            headSize = Vector3.new(0.96, 1.12, 1.00),
            humanoidRootSize = Vector3.new(1.36, 1.92, 0.88),
            rightArmScale = 1.00,
        },

        Appearance = {
            skinColor = Color3.fromRGB(152, 162, 154), -- pale cold ash tone distinct from male
            bruiseColor = Color3.fromRGB(92, 68, 86),
            rotColor = Color3.fromRGB(86, 78, 92),
            shirtColor = Color3.fromRGB(218, 214, 212),
            shirtAccentColor = Color3.fromRGB(108, 18, 28),
            pantsColor = Color3.fromRGB(24, 30, 52),
            shoeColor = Color3.fromRGB(24, 20, 22),
            bloodColor = Color3.fromRGB(122, 14, 20),
            hairColor = Color3.fromRGB(20, 16, 18),
            eyeColor = Color3.fromRGB(228, 232, 238),
            eyeGlow = false,
            hairStyle = "LongPonytail",
            clothingStyle = "StudentBlouseSkirt",
        },

        AnimationProfile = {
            category = "Female",
            hunchRad = math.rad(-10),
            strideDeg = 34,
            kneeBendDeg = 42,
            armReachDeg = 48,
            swayDeg = 8,
            headTwitchRate = 2.65,
            attackStyle = "TwinClawRake",
            AnimationIds = table.clone(EMPTY_ANIMATION_IDS),
        },

        AudioProfile = {
            VocalClass = "Female",
            RollOffMin = 6,
            RollOffMax = 56,
            StepRollOffMax = 36,
            BaseVolume = 0.42,
            PitchRange = { 1.38, 1.72 },
            ScreechPitchRange = { 1.85, 2.35 },
            StepPitchRange = { 1.06, 1.24 },
            DistortionLevel = 0.52,
            EqLowGain = -5,
            EqMidGain = 5,
            EqHighGain = 6,
            ReverbWet = -20,
            IdleInterval = { 3.2, 5.8 },
            ChaseInterval = { 1.8, 3.0 },
            StepIntervalWalk = 0.41,
            StepIntervalRun = 0.25,
            CustomSoundIds = makeEmptySoundIdMap(),
        },
    },

    FemaleRunner = {
        Id = "FemaleRunner",
        DisplayName = "FEMALE SHRIEKER",
        Category = "Female",
        Gender = "Female",
        Role = "Runner",
        IsBoss = false,
        TemplateName = "FemaleRunner",
        FallbackTemplateNames = { "Female" },

        TargetHeight = 4.88,
        MaxHealth = 90,
        WalkSpeed = 17.0,
        RunSpeed = 20.4,
        ChaseSpeed = 22.2,
        AttackDamage = 13,
        AttackRange = 5.7,
        AttackCooldown = 0.80,
        StunThreshold = 38,
        StunDuration = 0.65,
        PointRewardKill = 60,
        PointRewardHeadshotKill = 115,

        Proportions = {
            footSize = Vector3.new(0.35, 0.22, 0.72),
            lowerLegSize = Vector3.new(0.34, 0.94, 0.36),
            upperLegSize = Vector3.new(0.40, 0.96, 0.42),
            hipSpacing = 0.25,
            lowerTorsoSize = Vector3.new(1.12, 0.52, 0.66),
            upperTorsoSize = Vector3.new(1.18, 1.14, 0.68),
            shoulderSpan = 0.82,
            upperArmSize = Vector3.new(0.30, 0.88, 0.32),
            lowerArmSize = Vector3.new(0.26, 0.86, 0.28),
            handSize = Vector3.new(0.26, 0.32, 0.18),
            neckGap = 0.14,
            headSize = Vector3.new(0.94, 1.10, 0.98),
            humanoidRootSize = Vector3.new(1.32, 1.88, 0.86),
            rightArmScale = 1.00,
        },

        Appearance = {
            skinColor = Color3.fromRGB(168, 144, 148),
            bruiseColor = Color3.fromRGB(110, 44, 58),
            rotColor = Color3.fromRGB(122, 34, 42),
            shirtColor = Color3.fromRGB(88, 28, 36),
            shirtAccentColor = Color3.fromRGB(190, 184, 178),
            pantsColor = Color3.fromRGB(34, 34, 40),
            shoeColor = Color3.fromRGB(36, 30, 32),
            bloodColor = Color3.fromRGB(145, 14, 22),
            hairColor = Color3.fromRGB(28, 18, 20),
            eyeColor = Color3.fromRGB(255, 88, 120),
            eyeGlow = true,
            hairStyle = "DisheveledBangsBob",
            clothingStyle = "TornTrackTop",
        },

        AnimationProfile = {
            category = "Female",
            hunchRad = math.rad(-19),
            strideDeg = 44,
            kneeBendDeg = 52,
            armReachDeg = 64,
            swayDeg = 10,
            headTwitchRate = 3.40,
            attackStyle = "TwinClawRake",
            AnimationIds = table.clone(EMPTY_ANIMATION_IDS),
        },

        AudioProfile = {
            VocalClass = "Female",
            RollOffMin = 6,
            RollOffMax = 62,
            StepRollOffMax = 40,
            BaseVolume = 0.46,
            PitchRange = { 1.62, 2.02 },
            ScreechPitchRange = { 2.15, 2.68 },
            StepPitchRange = { 1.15, 1.32 },
            DistortionLevel = 0.64,
            EqLowGain = -6,
            EqMidGain = 6,
            EqHighGain = 8,
            ReverbWet = -18,
            IdleInterval = { 2.6, 4.8 },
            ChaseInterval = { 1.4, 2.5 },
            StepIntervalWalk = 0.34,
            StepIntervalRun = 0.21,
            CustomSoundIds = makeEmptySoundIdMap(),
        },
    },

    MaleBoss = {
        Id = "MaleBoss",
        DisplayName = "ABOMINATION BOSS",
        Category = "Boss",
        Gender = "Male",
        Role = "Boss",
        IsBoss = true,
        TemplateName = "MaleBoss",
        FallbackTemplateNames = { "Boss" },

        -- Male-only boss: ~9.0 studs tall (~1.75x normal male height)
        TargetHeight = 9.00,
        MaxHealth = 780,
        WalkSpeed = 11.4,
        RunSpeed = 13.4,
        ChaseSpeed = 15.2,
        AttackDamage = 34,
        AttackRange = 7.6,
        AttackCooldown = 1.35,
        StunThreshold = 145,
        StunDuration = 0.85,
        PointRewardKill = 250,
        PointRewardHeadshotKill = 420,

        Proportions = {
            footSize = Vector3.new(0.86, 0.42, 1.52),
            lowerLegSize = Vector3.new(0.92, 1.68, 0.96),
            upperLegSize = Vector3.new(1.06, 1.76, 1.12),
            hipSpacing = 0.56,
            lowerTorsoSize = Vector3.new(2.46, 0.98, 1.48),
            upperTorsoSize = Vector3.new(3.38, 2.38, 1.82), -- huge mutated barrel torso
            shoulderSpan = 2.08,
            upperArmSize = Vector3.new(0.80, 1.76, 0.84),
            lowerArmSize = Vector3.new(0.72, 1.68, 0.76),
            handSize = Vector3.new(0.68, 0.72, 0.48),
            neckGap = 0.22,
            headSize = Vector3.new(1.66, 1.78, 1.72),
            humanoidRootSize = Vector3.new(3.10, 3.60, 1.90),
            rightArmScale = 1.36, -- mutated oversized right claw arm
        },

        Appearance = {
            skinColor = Color3.fromRGB(98, 108, 94),
            bruiseColor = Color3.fromRGB(62, 34, 42),
            rotColor = Color3.fromRGB(165, 34, 38),
            coreGlowColor = Color3.fromRGB(255, 58, 36),
            boneColor = Color3.fromRGB(205, 194, 174),
            shirtColor = Color3.fromRGB(36, 38, 44), -- shredded guard/security vest
            shirtAccentColor = Color3.fromRGB(92, 24, 24),
            pantsColor = Color3.fromRGB(30, 32, 36),
            shoeColor = Color3.fromRGB(18, 18, 20),
            bloodColor = Color3.fromRGB(145, 10, 14),
            hairColor = Color3.fromRGB(20, 18, 18),
            eyeColor = Color3.fromRGB(255, 72, 24),
            eyeGlow = true,
            hairStyle = "MutatedSpikes",
            clothingStyle = "ShreddedSecurityArmor",
        },

        AnimationProfile = {
            category = "Boss",
            hunchRad = math.rad(-14),
            strideDeg = 28,
            kneeBendDeg = 32,
            armReachDeg = 38,
            swayDeg = 8,
            headTwitchRate = 0.90,
            attackStyle = "HeavyRightCleave",
            AnimationIds = table.clone(EMPTY_ANIMATION_IDS),
        },

        AudioProfile = {
            VocalClass = "Boss",
            RollOffMin = 10,
            RollOffMax = 92,
            StepRollOffMax = 68,
            BaseVolume = 0.76,
            PitchRange = { 0.24, 0.34 },
            ScreechPitchRange = { 0.34, 0.44 },
            StepPitchRange = { 0.52, 0.64 },
            DistortionLevel = 0.74,
            EqLowGain = 10,
            EqMidGain = 3,
            EqHighGain = -8,
            ReverbWet = -12,
            IdleInterval = { 4.2, 7.0 },
            ChaseInterval = { 2.2, 3.6 },
            StepIntervalWalk = 0.56,
            StepIntervalRun = 0.40,
            CustomSoundIds = makeEmptySoundIdMap(),
        },
    },
}

-- Normalize legacy wave/test-range names cleanly onto the new archetypes.
local LEGACY_ALIAS = {
    Walker = "MaleWalker",
    WALKER = "MaleWalker",
    Runner = "MaleRunner",
    RUNNER = "MaleRunner",
    Tank = "MaleBoss",
    Brute = "MaleBoss",
    BRUTE = "MaleBoss",
    Titan = "MaleBoss",
    TITAN = "MaleBoss",
    Boss = "MaleBoss",
    BOSS = "MaleBoss",
    Male = "MaleWalker",
    Female = "FemaleWalker",
}

function ZombieCatalog.get(archetypeName)
    local key = LEGACY_ALIAS[archetypeName] or archetypeName
    return ZombieCatalog.ARCHETYPES[key] or ZombieCatalog.ARCHETYPES.MaleWalker
end

function ZombieCatalog.pickForWave(waveNumber)
    local r = math.random()
    if waveNumber <= 1 then
        return (r < 0.52) and "MaleWalker" or "FemaleWalker"
    elseif waveNumber == 2 then
        if r < 0.34 then
            return "MaleWalker"
        elseif r < 0.68 then
            return "FemaleWalker"
        elseif r < 0.84 then
            return "MaleRunner"
        else
            return "FemaleRunner"
        end
    else
        -- Wave 3+: mixed male/female horde with runners and regular Boss arrivals
        if r < 0.28 then
            return "MaleWalker"
        elseif r < 0.56 then
            return "FemaleWalker"
        elseif r < 0.73 then
            return "MaleRunner"
        elseif r < 0.89 then
            return "FemaleRunner"
        else
            return "MaleBoss"
        end
    end
end

return ZombieCatalog
