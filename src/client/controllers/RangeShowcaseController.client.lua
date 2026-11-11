--[[
    RangeShowcaseController.client.lua
    THE RANGE — Dark Studio 3D Model Showcase & Animation Preview Client Controller.
    Active strictly inside Workspace.INFECTED_TestRange; restores full FPS combat & camera on exit.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local function safeWaitChild(parent, name, timeout)
    if not parent then return nil end
    return parent:WaitForChild(name, timeout or 10)
end

local function safeRequire(modScript)
    if not modScript then return nil end
    local ok, res = pcall(require, modScript)
    if not ok then
        warn("[RangeShowcase] Failed to require " .. modScript:GetFullName() .. ": " .. tostring(res))
        return nil
    end
    return res
end

local weaponsFolder = safeWaitChild(ReplicatedStorage, "Weapons", 10)
local animationsFolder = safeWaitChild(weaponsFolder, "animations", 5)
local effectsFolder = safeWaitChild(weaponsFolder, "effects", 5)
local modelsFolder = safeWaitChild(weaponsFolder, "models", 5)

local WeaponRegistry = safeRequire(safeWaitChild(weaponsFolder, "WeaponRegistry", 5))
local WeaponPoseSolver = safeRequire(safeWaitChild(animationsFolder, "WeaponPoseSolver", 5))
local WeaponModelBuilder = safeRequire(safeWaitChild(modelsFolder, "WeaponModelBuilder", 5))
local KMUTNBArms = safeRequire(safeWaitChild(modelsFolder, "KMUTNBArms", 5))
local RecoilSpring = safeRequire(safeWaitChild(effectsFolder, "RecoilSpring", 5))
local WeaponAudio = safeRequire(safeWaitChild(effectsFolder, "WeaponAudio", 5))

local showcaseEvents = safeWaitChild(ReplicatedStorage, "ShowcaseEvents", 10)
local stageControlEvent = safeWaitChild(showcaseEvents, "StageControl", 5)
local stageStateEvent = safeWaitChild(showcaseEvents, "StageState", 5)

if not WeaponRegistry or not WeaponPoseSolver or not WeaponModelBuilder or not KMUTNBArms then
    warn("[RangeShowcase] Missing required weapon studio modules; Showcase Controller disabled.")
    return
end

----------------------------------------------------------------------
-- 1. THEME, STUDIO ZONE DEFINITIONS & ASSET CATALOG
----------------------------------------------------------------------
local COLORS = {
    BgPanel = Color3.fromRGB(14, 16, 22),
    BgCard = Color3.fromRGB(22, 26, 35),
    BgElevated = Color3.fromRGB(30, 36, 48),
    BgSelected = Color3.fromRGB(38, 66, 108),
    AccentBlue = Color3.fromRGB(62, 158, 255),
    AccentAmber = Color3.fromRGB(245, 168, 64),
    AccentGreen = Color3.fromRGB(64, 200, 134),
    AccentRed = Color3.fromRGB(235, 86, 86),
    TextPrimary = Color3.fromRGB(238, 242, 248),
    TextMuted = Color3.fromRGB(146, 156, 174),
    Border = Color3.fromRGB(48, 56, 72),
}

local STUDIO_FONT = Enum.Font.GothamMedium
local STUDIO_FONT_BOLD = Enum.Font.GothamBold
local STUDIO_FONT_MONO = Enum.Font.Code

local STAGE_POS = Vector3.new(0, 1.85, 428)
local WEAPON_BAY_POS = Vector3.new(0, 1.58, 456)
local WEAPON_BAY_EYE_CF = CFrame.lookAt(Vector3.new(-0.35, 4.95, 457.6), Vector3.new(-0.35, 4.95, 452.0))
local MOVEMENT_AREA_FOCUS = Vector3.new(0, 4.5, 496)

local CATEGORIES = {
    { id = "Characters", label = "Characters" },
    { id = "Zombies", label = "Zombies" },
    { id = "Bosses", label = "Bosses" },
    { id = "Weapons", label = "Weapons" },
    { id = "Animations", label = "Animations" },
    { id = "Movement", label = "Movement" },
}

local CHARACTER_ASSETS = {
    {
        id = "PlayerR15",
        kind = "Plinth",
        title = "Default Player (R15)",
        subtitle = "Standard Roblox R15 Humanoid • ~5.0 studs",
        rigNote = "Uses player Avatar R15 + Animate script runtime tracks; no custom StarterCharacter override in repo.",
        stageHeroId = "PlayerR15",
    },
    {
        id = "KMUTNBArms",
        kind = "WeaponBayArms",
        title = "KMUTNB Student 1P Arms",
        subtitle = "Custom Tactical Student First-Person Sleeves & Watch",
        rigNote = "Procedural 1P arm geometry in KMUTNBArms.lua (supports Rifle, SMG, Shotgun, Pistol grips).",
        stageHeroId = nil,
    },
}

local ZOMBIE_ASSETS = {
    {
        id = "MaleWalker",
        title = "Male Infected (Walker)",
        subtitle = "5.15 studs • R15 Motor6D • Torn KMUTNB Shirt",
        rigNote = "Custom 15-part R15 zombie rig with Motor6D joints + 8 procedural Animator states (AnimationIds blank).",
        stageHeroId = "MaleWalker",
    },
    {
        id = "FemaleWalker",
        title = "Female Infected (Walker)",
        subtitle = "4.95 studs • R15 Motor6D • Layered Bob Hair & Jacket",
        rigNote = "Distinct shoulder/waist female silhouette + 8 procedural R15 states (AnimationIds blank).",
        stageHeroId = "FemaleWalker",
    },
    {
        id = "MaleRunner",
        title = "Male Runner (Sprinter)",
        subtitle = "5.06 studs • R15 Motor6D • Athletic Stance",
        rigNote = "Forward-hunched sprint kinematics + procedural R15 states (AnimationIds blank).",
        stageHeroId = "MaleRunner",
    },
    {
        id = "FemaleRunner",
        title = "Female Runner (Sprinter)",
        subtitle = "4.88 studs • R15 Motor6D • Ponytail & Crop Vest",
        rigNote = "Fast agile runner variant with custom female head/hair geometry (AnimationIds blank).",
        stageHeroId = "FemaleRunner",
    },
}

local BOSS_ASSETS = {
    {
        id = "MaleBoss",
        title = "Tyrant Alpha (Male Boss)",
        subtitle = "9.00 studs (~1.8x) • Mutated Muscular Rig • Glowing Cores",
        rigNote = "Heavier procedural slam, jaw/brow asymmetry, glowing ribcage bio-cores (no custom .rbxm/.fbx mesh yet).",
        stageHeroId = "MaleBoss",
    },
}

local WEAPON_ORDER = {
    "Classic", "Shorty", "Frenzy", "Ghost", "Sheriff",
    "Stinger", "Spectre",
    "Bucky", "Judge",
    "Bulldog", "Guardian", "Phantom", "Vandal",
    "Marshal", "Outlaw", "Operator",
    "Ares", "Odin",
}

local STAGE_HERO_OPTIONS = {
    { id = "PlayerR15", label = "Player R15", isZombie = false },
    { id = "MaleWalker", label = "Male Walker", isZombie = true },
    { id = "FemaleWalker", label = "Female Walker", isZombie = true },
    { id = "MaleRunner", label = "Male Runner", isZombie = true },
    { id = "FemaleRunner", label = "Female Runner", isZombie = true },
    { id = "MaleBoss", label = "Male Boss (9st)", isZombie = true },
}

local ZOMBIE_STAGE_CLIPS = {
    { id = "Idle", label = "Idle", source = "PROC R15", supported = true, note = "Procedural breathing & uneven head twitch." },
    { id = "Walking", label = "Walk", source = "PROC R15", supported = true, note = "Procedural asymmetric limp stride." },
    { id = "Running", label = "Run", source = "PROC R15", supported = true, note = "Procedural fast lean sprint." },
    { id = "Chasing", label = "Zombie Chase", source = "PROC R15", supported = true, note = "Lunge arms reached forward in pursuit." },
    { id = "Attacking", label = "Attack / Boss Strike", source = "PROC R15", supported = true, note = "Swipe / overhead boss slam cycle." },
    { id = "TakingDamage", label = "Take Damage", source = "PROC R15", supported = true, note = "Torso/head flinch (toggle Headshot for heavy whip)." },
    { id = "Stunned", label = "Stagger / Stunned", source = "PROC R15", supported = true, note = "Dazed sway recovery state." },
    { id = "Death", label = "Death", source = "PROC R15", supported = true, note = "Collapse to ground pose." },
    { id = "ZombieBite", label = "Zombie Bite", source = "MISSING ASSET", supported = false, note = "No dedicated Bite AnimationId or procedural Bite state exists in ZombieCatalog; Attacking uses swipe/slam." },
}

local PLAYER_STAGE_CLIPS = {
    { id = "Idle", label = "Idle", animateKey = "idle", supported = true, note = "Reads real Animate.idle AnimationId from spawned player R15 rig." },
    { id = "Walking", label = "Walk", animateKey = "walk", supported = true, note = "Reads real Animate.walk AnimationId from spawned player R15 rig." },
    { id = "Running", label = "Run", animateKey = "run", supported = true, note = "Reads real Animate.run AnimationId from spawned player R15 rig." },
    { id = "Jump", label = "Jump", animateKey = "jump", supported = true, note = "Reads real Animate.jump AnimationId from spawned player R15 rig." },
    { id = "Fall", label = "Fall", animateKey = "fall", supported = true, note = "Reads real Animate.fall AnimationId from spawned player R15 rig." },
    { id = "Climb", label = "Climb", animateKey = "climb", supported = true, note = "Reads real Animate.climb AnimationId from spawned player R15 rig." },
    { id = "Sprint", label = "Sprint (Uses Run @ 1.35x)", animateKey = "run", speedBoost = 1.35, supported = true, note = "No dedicated Sprint AnimationId in repo; FPS sprint raises WalkSpeed to 24 + FOV." },
    { id = "Crouch", label = "Crouch", supported = false, note = "MISSING ASSET: No Crouch system or Crouch AnimationId exists in repo (only Neon Slide)." },
    { id = "Attack", label = "Attack / Fire (1P Only)", redirectWeaponBay = "Fire", supported = false, note = "No 3P attack AnimationId; 1P fire/recoil solver runs in Weapon Anim Bay." },
    { id = "Reload", label = "Reload (1P Only)", redirectWeaponBay = "Reload", supported = false, note = "No 3P reload AnimationId; 1P multi-phase reload runs in Weapon Anim Bay." },
    { id = "Equip", label = "Equip Weapon (1P Only)", redirectWeaponBay = "Equip", supported = false, note = "No 3P equip AnimationId; 1P equip curve exists in WeaponPoseSolver." },
    { id = "Unequip", label = "Unequip Weapon (1P Only)", redirectWeaponBay = "Unequip", supported = false, note = "No 3P unequip AnimationId; 1P unequip curve exists in WeaponPoseSolver." },
    { id = "TakeDamage", label = "Take Damage", supported = false, note = "MISSING ASSET: Player hit feedback is HUD vignette/SFX only, no 3P hit AnimationId." },
    { id = "Death", label = "Death", supported = false, note = "MISSING ASSET: Game uses Downed state / Roblox BreakJoints, no custom Death AnimationId." },
}

local WEAPON_ANIM_CLIPS = {
    { id = "Idle", label = "Weapon Idle" },
    { id = "Equip", label = "Equip" },
    { id = "Unequip", label = "Unequip" },
    { id = "Fire", label = "Fire (Single Shot)" },
    { id = "FireAuto", label = "Fire + Recoil (Burst/Auto)" },
    { id = "Reload", label = "Reload (Full Phases)" },
    { id = "Inspect", label = "Inspect Weapon" },
    { id = "ADS", label = "ADS / Sight Aim" },
}

local SPEED_PRESETS = { 0.25, 0.5, 1.0, 1.5, 2.0 }

----------------------------------------------------------------------
-- 2. CONTROLLER STATE
----------------------------------------------------------------------
local state = {
    inRange = false,
    studioOpen = false,
    activeCategory = "Characters",
    selectedAssetId = "PlayerR15",
    weaponSubMode = "Stand",       -- "Stand" (Zone B) | "AnimBay" (Zone E)
    cameraMode = "Orbit",          -- "Orbit" | "Walk" | "ThirdPersonFollow" | "WeaponEye1P"
    -- Orbit camera state
    focusPos = Vector3.new(0, 4.5, 428),
    targetFocus = Vector3.new(0, 4.5, 428),
    yaw = math.rad(180),
    pitch = math.rad(-14),
    dist = 10,
    targetYaw = math.rad(180),
    targetPitch = math.rad(-14),
    targetDist = 10,
    minDist = 1.8,
    maxDist = 28.0,
    draggingOrbit = false,
    lastMousePos = Vector2.zero,
    -- Stage playback state
    stageHeroId = "MaleWalker",
    stageIsZombie = true,
    stageClipId = "Idle",
    stagePaused = false,
    stageSpeed = 1.0,
    stageLoop = true,
    stageHeadshot = false,
    stageStatusText = "",
    -- Weapon Anim Lab state
    bayWeaponName = "Vandal",
    bayViewMode = "1P_Arms",       -- "1P_Arms" | "1P_GunOnly" | "3P_Character"
    bayClipId = "Idle",
    bayPaused = false,
    baySpeed = 1.0,
    bayLoop = true,
    bayTimer = 0,
    bayLastShotAt = -10,
    bayMuzzleFlashTimer = 0,
    bayMuzzleRoll = 0,
    bayClock = 0,
    bayPrevReloadProg = 0,
    -- Patrol bot state
    patrolAssetId = "MaleRunner",
    patrolSpeedMode = "Run",
    patrolRunning = false,
    -- Telemetry state
    lastHorizVel = Vector3.zero,
    peakSpeed = 0,
    smoothedAccel = 0,
}

----------------------------------------------------------------------
-- 3. SCENE & RIG MANAGEMENT HELPERS
----------------------------------------------------------------------
local function getRangeFolder()
    return Workspace:FindFirstChild("INFECTED_TestRange")
end

local function isPlayerInsideRange()
    local range = getRangeFolder()
    if not range then return false end
    local floor = range:FindFirstChild("RangeFloor")
    if not floor or not floor:IsA("BasePart") then return false end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local rel = floor.CFrame:PointToObjectSpace(root.Position)
    local half = floor.Size * 0.5
    return math.abs(rel.X) <= (half.X + 3)
        and math.abs(rel.Z) <= (half.Z + 3)
        and rel.Y >= -5
        and rel.Y <= 36
end

local function getPlinthFocusData(kind, id)
    local range = getRangeFolder()
    if not range then return nil end

    if kind == "Character" or kind == "Zombie" or kind == "Boss" then
        local gallery = range:FindFirstChild("CharacterShowcaseGallery")
        local target = gallery and gallery:FindFirstChild("Display_" .. id)
        if target then
            local fx = target:GetAttribute("ShowcaseFocusX")
            local fy = target:GetAttribute("ShowcaseFocusY")
            local fz = target:GetAttribute("ShowcaseFocusZ")
            local d = target:GetAttribute("ShowcaseDefaultDist") or 9
            if fx and fy and fz then
                return Vector3.new(fx, fy, fz), d, math.rad(205), math.rad(-12)
            end
        end
    elseif kind == "Weapon" then
        local gallery = range:FindFirstChild("WeaponShowcaseGallery")
        local target = gallery and gallery:FindFirstChild("Pickup_" .. id)
        if target then
            local fx = target:GetAttribute("ShowcaseFocusX")
            local fy = target:GetAttribute("ShowcaseFocusY")
            local fz = target:GetAttribute("ShowcaseFocusZ")
            local d = target:GetAttribute("ShowcaseDefaultDist") or 4.5
            if fx and fy and fz then
                return Vector3.new(fx, fy, fz), d, math.rad(215), math.rad(-16)
            end
        end
    end
    return nil
end

local function createIsolatedCharacterClone(anchorPos, facingDeg)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

    local prevArch = char.Archivable
    char.Archivable = true
    local ok, clone = pcall(function() return char:Clone() end)
    char.Archivable = prevArch
    if not ok or not clone then return nil end

    for _, desc in ipairs(clone:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Tool")
            or desc:IsA("ForceField") or desc:IsA("BillboardGui") or desc:IsA("Sound") then
            desc:Destroy()
        elseif desc:IsA("BasePart") then
            desc.CanCollide = false
            desc.CanQuery = false
            desc.CanTouch = false
            desc.Anchored = (desc.Name == "HumanoidRootPart")
            desc.Massless = (desc.Name ~= "HumanoidRootPart")
        end
    end

    local hum = clone:FindFirstChildOfClass("Humanoid")
    local root = clone:FindFirstChild("HumanoidRootPart")
    if not hum or not root then
        clone:Destroy()
        return nil
    end

    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    hum.AutoRotate = false
    hum.PlatformStand = true
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local yCenter = anchorPos.Y + (root.Size.Y * 0.5) + hum.HipHeight
    root.CFrame = CFrame.new(anchorPos.X, yCenter, anchorPos.Z) * CFrame.Angles(0, math.rad(facingDeg or 180), 0)
    clone.PrimaryPart = root
    return clone, hum, animator, root
end

local function collectPlayerAnimateTracks()
    local tracks = {}
    local char = player.Character
    local animate = char and char:FindFirstChild("Animate")
    if not animate then return tracks end

    for _, child in ipairs(animate:GetChildren()) do
        if child:IsA("StringValue") then
            local animObj = child:FindFirstChildOfClass("Animation")
            if animObj and animObj.AnimationId ~= "" then
                tracks[child.Name:lower()] = {
                    animObj = animObj,
                    animId = animObj.AnimationId,
                }
            end
        end
    end
    return tracks
end

----------------------------------------------------------------------
-- 4. CLIENT STAGE PLAYER-R15 OVERLAY & WEAPON ANIM BAY RIG
----------------------------------------------------------------------
local stagePlayerPreview = {
    clone = nil,
    animator = nil,
    track = nil,
    currentClip = "Idle",
    animateMap = {},
}

local function setServerHeroHiddenLocally(hidden)
    local range = getRangeFolder()
    local stageFolder = range and range:FindFirstChild("AnimationPreviewStage")
    local heroMount = stageFolder and stageFolder:FindFirstChild("ActiveHeroRig")
    if not heroMount then return end
    local staticRig = heroMount:FindFirstChild("PlayerR15_Showcase")
    if not staticRig then return end

    for _, d in ipairs(staticRig:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Decal") then
            d.LocalTransparencyModifier = hidden and 1 or 0
        end
    end
end

local function destroyStagePlayerPreview()
    if stagePlayerPreview.track then
        pcall(function() stagePlayerPreview.track:Stop(0) end)
        stagePlayerPreview.track = nil
    end
    if stagePlayerPreview.clone then
        stagePlayerPreview.clone:Destroy()
        stagePlayerPreview.clone = nil
    end
    stagePlayerPreview.animator = nil
    setServerHeroHiddenLocally(false)
end

local function playStagePlayerClip(clipId, opts)
    opts = opts or {}
    local clipDef = nil
    for _, c in ipairs(PLAYER_STAGE_CLIPS) do
        if c.id == clipId then
            clipDef = c
            break
        end
    end
    if not clipDef then return "Unknown clip" end

    if not clipDef.supported then
        -- Still keep rig visible in Idle so rig does not freeze in weird pose
        state.stageStatusText = clipDef.note
        return clipDef.note
    end

    if not stagePlayerPreview.clone or not stagePlayerPreview.clone.Parent then
        local clone, _, animator = createIsolatedCharacterClone(STAGE_POS, 180)
        if not clone then
            state.stageStatusText = "Waiting for player character to spawn..."
            return state.stageStatusText
        end
        clone.Name = "ClientStagePlayerPreview"
        clone.Parent = Workspace
        stagePlayerPreview.clone = clone
        stagePlayerPreview.animator = animator
        stagePlayerPreview.animateMap = collectPlayerAnimateTracks()
        setServerHeroHiddenLocally(true)
    end

    local key = clipDef.animateKey or "idle"
    local entry = stagePlayerPreview.animateMap[key]
    if not entry then
        state.stageStatusText = "No runtime AnimationId found under Animate." .. key
        return state.stageStatusText
    end

    if opts.restart or stagePlayerPreview.currentClip ~= clipId or not stagePlayerPreview.track then
        if stagePlayerPreview.track then
            pcall(function() stagePlayerPreview.track:Stop(0.1) end)
            stagePlayerPreview.track = nil
        end
        local ok, loadedTrack = pcall(function()
            return stagePlayerPreview.animator:LoadAnimation(entry.animObj)
        end)
        if ok and loadedTrack then
            loadedTrack.Looped = (key ~= "jump") and state.stageLoop
            loadedTrack:Play(0.12)
            stagePlayerPreview.track = loadedTrack
        end
    end

    stagePlayerPreview.currentClip = clipId
    local mult = clipDef.speedBoost or 1.0
    local effectiveSpeed = state.stagePaused and 0 or (state.stageSpeed * mult)
    if stagePlayerPreview.track then
        if opts.restart then
            stagePlayerPreview.track.TimePosition = 0
        end
        stagePlayerPreview.track.Looped = (key ~= "jump") and state.stageLoop
        stagePlayerPreview.track:AdjustSpeed(effectiveSpeed)
    end

    state.stageStatusText = string.format("Playing %s (%s @ %.2fx)", clipDef.label, entry.animId, state.stageSpeed * mult)
    return state.stageStatusText
end

-- Weapon Animation Bay Client Preview Rig (Zone E)
local weaponBayRig = {
    folder = nil,
    gunRoot = nil,
    parts = {},
    leftArmParts = {},
    baseTransparency = {},
    animGroups = { Magazine = {}, Bolt = {}, Pump = {}, Cylinder = {}, ReloadOnly = {} },
    muzzleFlashParts = {},
    flashLight = nil,
    smokeEmitter = nil,
    thirdPersonClone = nil,
    thirdPersonRoot = nil,
    weaponCfg = nil,
    animState = WeaponPoseSolver.newState(),
    recoilSpring = RecoilSpring and RecoilSpring.new(1, 45, 6, 8) or nil,
}

local function destroyWeaponBayRig()
    if weaponBayRig.thirdPersonClone then
        weaponBayRig.thirdPersonClone:Destroy()
        weaponBayRig.thirdPersonClone = nil
        weaponBayRig.thirdPersonRoot = nil
    end
    if weaponBayRig.folder then
        weaponBayRig.folder:Destroy()
        weaponBayRig.folder = nil
    end
    weaponBayRig.gunRoot = nil
    weaponBayRig.parts = {}
    weaponBayRig.leftArmParts = {}
    weaponBayRig.baseTransparency = {}
    weaponBayRig.animGroups = { Magazine = {}, Bolt = {}, Pump = {}, Cylinder = {}, ReloadOnly = {} }
    weaponBayRig.muzzleFlashParts = {}
    weaponBayRig.flashLight = nil
    weaponBayRig.smokeEmitter = nil
    WeaponPoseSolver.resetState(weaponBayRig.animState)
end

local function buildWeaponBayRig(weaponName, viewMode)
    destroyWeaponBayRig()
    local cfg = WeaponRegistry.get(weaponName)
    if not cfg then return end

    weaponBayRig.weaponCfg = cfg
    WeaponPoseSolver.resetState(weaponBayRig.animState)
    if RecoilSpring then
        weaponBayRig.recoilSpring = RecoilSpring.new(1, 45, 6, 8)
    end

    local container = Instance.new("Model")
    container.Name = "ShowcaseWeaponAnimRig"
    container.Parent = Workspace
    weaponBayRig.folder = container

    local gunRoot = Instance.new("Part")
    gunRoot.Name = "ShowcaseGunRoot"
    gunRoot.Size = Vector3.new(0.2, 0.2, 0.2)
    gunRoot.Transparency = 1
    gunRoot.CanCollide = false
    gunRoot.CanQuery = false
    gunRoot.CanTouch = false
    gunRoot.Anchored = true
    gunRoot.Parent = container
    weaponBayRig.gunRoot = gunRoot

    if viewMode == "1P_Arms" then
        local arms, leftArms = KMUTNBArms.build(container, cfg)
        for p, relCF in pairs(arms) do
            weaponBayRig.parts[p] = relCF
            weaponBayRig.baseTransparency[p] = p.Transparency
        end
        for p, relCF in pairs(leftArms) do
            weaponBayRig.leftArmParts[p] = relCF
        end
    elseif viewMode == "3P_Character" then
        local clone, _, animator, root = createIsolatedCharacterClone(WEAPON_BAY_POS, 180)
        if clone then
            clone.Name = "WeaponBay3PCharacter"
            clone.Parent = container
            weaponBayRig.thirdPersonClone = clone
            weaponBayRig.thirdPersonRoot = root
            local animMap = collectPlayerAnimateTracks()
            if animMap.idle and animator then
                local ok, tr = pcall(function() return animator:LoadAnimation(animMap.idle.animObj) end)
                if ok and tr then
                    tr.Looped = true
                    tr:Play(0.05)
                end
            end
        end
    end

    local wParts, mParts, fLight, sEmitter, pGroups = WeaponModelBuilder.build(container, cfg, gunRoot)
    for p, relCF in pairs(wParts) do
        weaponBayRig.parts[p] = relCF
        weaponBayRig.baseTransparency[p] = p.Transparency
        if p.Name == "SpeedloaderBase" or p.Name:match("^ReloadShell") or p.Name == "MarshalShell" then
            weaponBayRig.animGroups.ReloadOnly[p] = true
            p.Transparency = 1
        end
    end
    if type(pGroups) == "table" then
        for gName, gMap in pairs(pGroups) do
            if weaponBayRig.animGroups[gName] and type(gMap) == "table" then
                for p, flag in pairs(gMap) do
                    if flag then weaponBayRig.animGroups[gName][p] = true end
                end
            end
        end
    end
    weaponBayRig.muzzleFlashParts = mParts or {}
    weaponBayRig.flashLight = fLight
    weaponBayRig.smokeEmitter = sEmitter
end

local function triggerWeaponBayShot()
    local cfg = weaponBayRig.weaponCfg
    if not cfg then return end
    weaponBayRig.animState.lastShotTime = state.bayClock
    weaponBayRig.animState.cylinderIndex = (weaponBayRig.animState.cylinderIndex or 0) + 1
    state.bayMuzzleFlashTimer = 0.055
    state.bayMuzzleRoll = math.random(0, 360)

    if weaponBayRig.recoilSpring then
        weaponBayRig.recoilSpring:Impulse(Vector3.new(
            math.rad(cfg.Recoil and cfg.Recoil.Pitch or 3.5),
            math.rad((math.random() - 0.5) * 3.5),
            0.16
        ))
    end
    if WeaponAudio then
        WeaponAudio.playShot(cfg)
    end
    if weaponBayRig.smokeEmitter then
        weaponBayRig.smokeEmitter:Emit(3)
    end
end

local function startWeaponBayClip(clipId)
    state.bayClipId = clipId
    state.bayTimer = 0
    state.bayPrevReloadProg = 0
    state.bayLastShotAt = -10
    WeaponPoseSolver.resetState(weaponBayRig.animState)

    if clipId == "Equip" and WeaponAudio then
        WeaponAudio.playClick(2.7)
    elseif clipId == "Fire" or clipId == "FireAuto" then
        triggerWeaponBayShot()
        state.bayLastShotAt = state.bayClock
    end
end

local function updateWeaponBayPreview(dt)
    if not (state.studioOpen and state.activeCategory == "Weapons" and state.weaponSubMode == "AnimBay") then
        if weaponBayRig.folder then
            destroyWeaponBayRig()
        end
        return
    end

    if not weaponBayRig.folder or not weaponBayRig.folder.Parent then
        buildWeaponBayRig(state.bayWeaponName, state.bayViewMode)
    end

    local cfg = weaponBayRig.weaponCfg
    if not cfg or not weaponBayRig.gunRoot then return end

    local dtScaled = state.bayPaused and 0 or (dt * state.baySpeed)
    state.bayClock = state.bayClock + dtScaled
    state.bayTimer = state.bayTimer + dtScaled

    local clip = state.bayClipId
    local profile = WeaponPoseSolver.getProfile(cfg)
    local isReload = (clip == "Reload")
    local isInspect = (clip == "Inspect")
    local isADS = (clip == "ADS")
    local reloadDur = math.max(0.4, cfg.ReloadTime or 2.2)
    local reloadProg = 0

    if isReload then
        if state.bayTimer >= reloadDur then
            if state.bayLoop then
                state.bayTimer = 0
                state.bayPrevReloadProg = 0
            else
                state.bayTimer = reloadDur
            end
        end
        reloadProg = math.clamp(state.bayTimer / reloadDur, 0, 1)
        if not state.bayPaused and WeaponAudio and profile.audioCues then
            for _, cue in ipairs(profile.audioCues) do
                if state.bayPrevReloadProg < cue[1] and reloadProg >= cue[1] then
                    WeaponAudio.playReloadStage(cfg, cue[2])
                end
            end
        end
        state.bayPrevReloadProg = reloadProg
    elseif clip == "FireAuto" and not state.bayPaused then
        local shotInterval = 60 / math.max(60, cfg.FireRate or 540)
        if (state.bayClock - state.bayLastShotAt) >= shotInterval then
            triggerWeaponBayShot()
            state.bayLastShotAt = state.bayClock
        end
    elseif clip == "Inspect" then
        if state.bayTimer >= WeaponPoseSolver.INSPECT_DURATION then
            if state.bayLoop then
                state.bayTimer = 0
                weaponBayRig.animState.inspectTimer = 0
            end
        end
    end

    local extraGunCF = CFrame.identity
    local extraLeftCF = CFrame.identity
    if clip == "Equip" then
        if state.bayTimer >= WeaponPoseSolver.EQUIP_DURATION and state.bayLoop then
            state.bayTimer = 0
        end
        local ep = math.clamp(state.bayTimer / WeaponPoseSolver.EQUIP_DURATION, 0, 1)
        extraGunCF, extraLeftCF = WeaponPoseSolver.evalEquipPose(ep)
    elseif clip == "Unequip" then
        if state.bayTimer >= WeaponPoseSolver.UNEQUIP_DURATION and state.bayLoop then
            state.bayTimer = 0
        end
        local up = math.clamp(state.bayTimer / WeaponPoseSolver.UNEQUIP_DURATION, 0, 1)
        extraGunCF, extraLeftCF = WeaponPoseSolver.evalUnequipPose(up)
    end

    local recVec = Vector3.zero
    if weaponBayRig.recoilSpring then
        recVec = weaponBayRig.recoilSpring:Update(dtScaled)
    end
    local recCF = CFrame.new(0, 0, recVec.Z) * CFrame.Angles(recVec.X, recVec.Y, 0)

    local gAnim, lAnim, detachAlpha, magCF, boltCF, pumpCF, cylCF, showMag, showReloadOnly =
        WeaponPoseSolver.solve(weaponBayRig.animState, dtScaled, cfg, isReload, reloadProg, isInspect, isADS, false, state.bayClock)

    local baseCF
    if state.bayViewMode == "3P_Character" and weaponBayRig.thirdPersonRoot then
        -- Anchor gun neatly beside the 3P character's right chest/shoulder
        baseCF = weaponBayRig.thirdPersonRoot.CFrame * CFrame.new(0.85, 0.30, -1.35) * recCF
    elseif state.bayViewMode == "1P_GunOnly" then
        baseCF = CFrame.new(0, 4.35, 456.0) * CFrame.Angles(0, math.rad(180), 0) * recCF
    else
        local hipOff = cfg.HipOffset or CFrame.new(0.60, -0.55, -1.35)
        local aimOff = cfg.AimOffset or CFrame.new(0, -0.24, -0.92)
        local offset = isADS and aimOff or hipOff
        baseCF = WEAPON_BAY_EYE_CF * offset * recCF
    end

    local finalRootCF = baseCF * extraGunCF * gAnim
    local leftArmRootCF = baseCF * extraGunCF * extraLeftCF * (gAnim:Lerp(CFrame.identity, detachAlpha) * lAnim)
    weaponBayRig.gunRoot.CFrame = finalRootCF

    if state.bayMuzzleFlashTimer > 0 then
        state.bayMuzzleFlashTimer = math.max(0, state.bayMuzzleFlashTimer - dtScaled)
    end
    local flashVisible = state.bayMuzzleFlashTimer > 0
    for _, mp in ipairs(weaponBayRig.muzzleFlashParts) do
        if mp and mp.Parent then
            mp.Transparency = flashVisible and 0.12 or 1
        end
    end
    if weaponBayRig.flashLight then
        weaponBayRig.flashLight.Brightness = flashVisible and 3.0 or 0
    end

    for part, relCF in pairs(weaponBayRig.parts) do
        if part and part.Parent then
            if weaponBayRig.leftArmParts[part] then
                part.CFrame = leftArmRootCF * relCF
            elseif weaponBayRig.animGroups.ReloadOnly[part] then
                part.Transparency = showReloadOnly and (weaponBayRig.baseTransparency[part] or 0) or 1
                part.CFrame = finalRootCF * magCF * relCF
            elseif weaponBayRig.animGroups.Magazine[part] then
                part.Transparency = showMag and (weaponBayRig.baseTransparency[part] or 0) or 1
                part.CFrame = finalRootCF * magCF * relCF
            elseif weaponBayRig.animGroups.Bolt[part] then
                part.CFrame = finalRootCF * boltCF * relCF
            elseif weaponBayRig.animGroups.Pump[part] then
                part.CFrame = finalRootCF * pumpCF * relCF
            elseif weaponBayRig.animGroups.Cylinder[part] then
                part.CFrame = finalRootCF * cylCF * relCF
            elseif part.Name:match("MuzzleFlashFlame") then
                part.CFrame = finalRootCF * relCF * CFrame.Angles(0, 0, math.rad(state.bayMuzzleRoll))
            else
                part.CFrame = finalRootCF * relCF
            end
        end
    end

    -- Keep orbit focus locked onto the weapon bay center unless in 1P Eye Cam
    if state.cameraMode == "Orbit" then
        state.targetFocus = finalRootCF.Position
    end
end

----------------------------------------------------------------------
-- 5. CAMERA CONTROLLER & ATTRIBUTE SYNC
----------------------------------------------------------------------
local function syncCameraAttributes()
    local orbitActive = state.inRange and state.studioOpen and (state.cameraMode == "Orbit" or state.cameraMode == "WeaponEye1P")
    local tpMoveActive = state.inRange and state.cameraMode == "ThirdPersonFollow"

    player:SetAttribute("ShowcaseOrbitMode", orbitActive)
    player:SetAttribute("ShowcaseThirdPersonMove", tpMoveActive)

    if orbitActive then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    elseif not state.studioOpen then
        camera.CameraType = Enum.CameraType.Custom
    end
end

local function setFocusView(pos, dist, yawRad, pitchRad)
    state.targetFocus = pos
    state.targetDist = math.clamp(dist or 8, state.minDist, state.maxDist)
    if yawRad then state.targetYaw = yawRad end
    if pitchRad then state.targetPitch = pitchRad end
end

local function setCameraMode(mode)
    state.cameraMode = mode
    syncCameraAttributes()
end

----------------------------------------------------------------------
-- 6. STUDIO UI CONSTRUCTION (DARK MINIMALIST THEME)
----------------------------------------------------------------------
local playerGui = player:WaitForChild("PlayerGui")
local studioGui = Instance.new("ScreenGui")
studioGui.Name = "RangeShowcaseStudioUI"
studioGui.ResetOnSpawn = false
studioGui.DisplayOrder = 25
studioGui.IgnoreGuiInset = true
studioGui.Parent = playerGui

local function addCorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = inst
    return c
end

local function addStroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function makeButton(parent, props)
    local btn = Instance.new("TextButton")
    btn.AutoButtonColor = false
    btn.Font = props.font or STUDIO_FONT
    btn.TextSize = props.textSize or 12
    btn.TextColor3 = props.textColor or COLORS.TextPrimary
    btn.BackgroundColor3 = props.bgColor or COLORS.BgCard
    btn.Text = props.text or ""
    btn.Size = props.size or UDim2.new(1, 0, 0, 28)
    btn.Position = props.pos or UDim2.new()
    btn.BorderSizePixel = 0
    if props.anchor then btn.AnchorPoint = props.anchor end
    addCorner(btn, props.radius or 6)
    if props.stroke ~= false then
        addStroke(btn, props.strokeColor or COLORS.Border, 1)
    end
    btn.Parent = parent
    return btn
end

local function makeLabel(parent, props)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Font = props.font or STUDIO_FONT
    lbl.TextSize = props.textSize or 12
    lbl.TextColor3 = props.textColor or COLORS.TextPrimary
    lbl.TextXAlignment = props.alignX or Enum.TextXAlignment.Left
    lbl.TextYAlignment = props.alignY or Enum.TextYAlignment.Center
    lbl.TextWrapped = props.wrap or false
    lbl.Text = props.text or ""
    lbl.Size = props.size or UDim2.new(1, 0, 0, 18)
    lbl.Position = props.pos or UDim2.new()
    if props.anchor then lbl.AnchorPoint = props.anchor end
    lbl.Parent = parent
    return lbl
end

-- Floating Toggle Pill (visible strictly inside The Range)
local togglePill = makeButton(studioGui, {
    text = "3D SHOWCASE STUDIO [V]",
    font = STUDIO_FONT_BOLD,
    textSize = 12,
    textColor = COLORS.TextPrimary,
    bgColor = COLORS.BgPanel,
    strokeColor = COLORS.AccentBlue,
    size = UDim2.new(0, 198, 0, 32),
    pos = UDim2.new(1, -18, 0, 14),
    anchor = Vector2.new(1, 0),
    radius = 8,
})
togglePill.Visible = false

local rangeHintPill = makeLabel(studioGui, {
    text = "[F] Inspect Plinth / Stage / Weapon   •   [V] Open 3D Studio",
    font = STUDIO_FONT,
    textSize = 12,
    textColor = COLORS.TextMuted,
    alignX = Enum.TextXAlignment.Center,
    size = UDim2.new(0, 440, 0, 24),
    pos = UDim2.new(0.5, 0, 1, -14),
    anchor = Vector2.new(0.5, 1),
})
rangeHintPill.Visible = false

-- Studio Workspace Container (Only rendered when studioOpen == true)
local studioRoot = Instance.new("Frame")
studioRoot.Name = "StudioWorkspace"
studioRoot.BackgroundTransparency = 1
studioRoot.Size = UDim2.new(1, 0, 1, 0)
studioRoot.Visible = false
studioRoot.Parent = studioGui

-- Top Navigation Header
local topBar = Instance.new("Frame")
topBar.BackgroundColor3 = COLORS.BgPanel
topBar.BackgroundTransparency = 0.06
topBar.Size = UDim2.new(1, -28, 0, 44)
topBar.Position = UDim2.new(0, 14, 0, 10)
addCorner(topBar, 8)
addStroke(topBar, COLORS.Border, 1)
topBar.Parent = studioRoot

makeLabel(topBar, {
    text = "INFECTED-KMUTNB  //  3D STUDIO",
    font = STUDIO_FONT_BOLD,
    textSize = 13,
    textColor = COLORS.AccentBlue,
    size = UDim2.new(0, 245, 1, 0),
    pos = UDim2.new(0, 14, 0, 0),
})

local tabRow = Instance.new("Frame")
tabRow.BackgroundTransparency = 1
tabRow.Size = UDim2.new(0, 620, 0, 30)
tabRow.Position = UDim2.new(0, 265, 0.5, 0)
tabRow.AnchorPoint = Vector2.new(0, 0.5)
tabRow.Parent = topBar

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.Parent = tabRow

local categoryTabButtons = {}
for _, cat in ipairs(CATEGORIES) do
    local b = makeButton(tabRow, {
        text = cat.label,
        font = STUDIO_FONT_BOLD,
        textSize = 12,
        size = UDim2.new(0, 96, 1, 0),
        radius = 6,
    })
    categoryTabButtons[cat.id] = b
end

local camToggleTopBtn = makeButton(topBar, {
    text = "Mode: Orbit 360",
    font = STUDIO_FONT_BOLD,
    textSize = 11,
    bgColor = COLORS.BgElevated,
    strokeColor = COLORS.AccentAmber,
    size = UDim2.new(0, 128, 0, 28),
    pos = UDim2.new(1, -94, 0.5, 0),
    anchor = Vector2.new(1, 0.5),
})

local closeStudioBtn = makeButton(topBar, {
    text = "Close [V]",
    font = STUDIO_FONT_BOLD,
    textSize = 11,
    bgColor = Color3.fromRGB(58, 28, 32),
    strokeColor = COLORS.AccentRed,
    size = UDim2.new(0, 74, 0, 28),
    pos = UDim2.new(1, -10, 0.5, 0),
    anchor = Vector2.new(1, 0.5),
})

-- Left Asset List Panel (Compact width 250px, leaving center clear)
local leftDock = Instance.new("Frame")
leftDock.BackgroundColor3 = COLORS.BgPanel
leftDock.BackgroundTransparency = 0.08
leftDock.Size = UDim2.new(0, 250, 1, -130)
leftDock.Position = UDim2.new(0, 14, 0, 64)
addCorner(leftDock, 8)
addStroke(leftDock, COLORS.Border, 1)
leftDock.Parent = studioRoot

local leftTitleLbl = makeLabel(leftDock, {
    text = "ASSET INVENTORY",
    font = STUDIO_FONT_BOLD,
    textSize = 12,
    textColor = COLORS.TextMuted,
    size = UDim2.new(1, -24, 0, 24),
    pos = UDim2.new(0, 12, 0, 10),
})

local leftScroll = Instance.new("ScrollingFrame")
leftScroll.BackgroundTransparency = 1
leftScroll.BorderSizePixel = 0
leftScroll.ScrollBarThickness = 4
leftScroll.ScrollBarImageColor3 = COLORS.AccentBlue
leftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
leftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
leftScroll.Size = UDim2.new(1, -16, 1, -46)
leftScroll.Position = UDim2.new(0, 8, 0, 38)
leftScroll.Parent = leftDock

local leftListLayout = Instance.new("UIListLayout")
leftListLayout.Padding = UDim.new(0, 6)
leftListLayout.Parent = leftScroll

-- Right Inspector & Controls Panel (Compact width 296px)
local rightDock = Instance.new("Frame")
rightDock.BackgroundColor3 = COLORS.BgPanel
rightDock.BackgroundTransparency = 0.08
rightDock.Size = UDim2.new(0, 296, 1, -130)
rightDock.Position = UDim2.new(1, -14, 0, 64)
rightDock.AnchorPoint = Vector2.new(1, 0)
addCorner(rightDock, 8)
addStroke(rightDock, COLORS.Border, 1)
rightDock.Parent = studioRoot

local rightScroll = Instance.new("ScrollingFrame")
rightScroll.BackgroundTransparency = 1
rightScroll.BorderSizePixel = 0
rightScroll.ScrollBarThickness = 4
rightScroll.ScrollBarImageColor3 = COLORS.AccentBlue
rightScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
rightScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
rightScroll.Size = UDim2.new(1, -16, 1, -20)
rightScroll.Position = UDim2.new(0, 8, 0, 10)
rightScroll.Parent = rightDock

local rightLayout = Instance.new("UIListLayout")
rightLayout.Padding = UDim.new(0, 8)
rightLayout.Parent = rightScroll

-- Bottom Camera Control Bar
local bottomBar = Instance.new("Frame")
bottomBar.BackgroundColor3 = COLORS.BgPanel
bottomBar.BackgroundTransparency = 0.08
bottomBar.Size = UDim2.new(0, 610, 0, 40)
bottomBar.Position = UDim2.new(0.5, 0, 1, -14)
bottomBar.AnchorPoint = Vector2.new(0.5, 1)
addCorner(bottomBar, 8)
addStroke(bottomBar, COLORS.Border, 1)
bottomBar.Parent = studioRoot

local bottomLayout = Instance.new("UIListLayout")
bottomLayout.FillDirection = Enum.FillDirection.Horizontal
bottomLayout.VerticalAlignment = Enum.VerticalAlignment.Center
bottomLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
bottomLayout.Padding = UDim.new(0, 6)
bottomLayout.Parent = bottomBar

local btnCamFront = makeButton(bottomBar, { text = "Front", size = UDim2.new(0, 56, 0, 26), textSize = 11 })
local btnCamSide = makeButton(bottomBar, { text = "Side", size = UDim2.new(0, 52, 0, 26), textSize = 11 })
local btnCamBack = makeButton(bottomBar, { text = "Back", size = UDim2.new(0, 52, 0, 26), textSize = 11 })
local btnZoomOut = makeButton(bottomBar, { text = "- Zoom", size = UDim2.new(0, 60, 0, 26), textSize = 11 })
local zoomReadout = makeLabel(bottomBar, {
    text = "9.0m",
    font = STUDIO_FONT_MONO,
    textSize = 11,
    textColor = COLORS.AccentAmber,
    alignX = Enum.TextXAlignment.Center,
    size = UDim2.new(0, 54, 0, 26),
})
local btnZoomIn = makeButton(bottomBar, { text = "+ Zoom", size = UDim2.new(0, 60, 0, 26), textSize = 11 })
local btnCamReset = makeButton(bottomBar, { text = "Reset Cam", size = UDim2.new(0, 76, 0, 26), textSize = 11, strokeColor = COLORS.AccentBlue })
makeLabel(bottomBar, {
    text = "Drag Viewport: Orbit 360  •  Wheel: Zoom",
    font = STUDIO_FONT,
    textSize = 11,
    textColor = COLORS.TextMuted,
    size = UDim2.new(0, 165, 0, 26),
})

----------------------------------------------------------------------
-- 7. DYNAMIC UI REBUILDERS (CLEAN SECTION HELPERS)
----------------------------------------------------------------------
local rebuildUI
local openStudioMode

local function clearChildrenKeepingLayout(frame)
    for _, c in ipairs(frame:GetChildren()) do
        if not c:IsA("UIListLayout") then
            c:Destroy()
        end
    end
end

local function addInspectorCard(parent, titleText, bodyText, accentColor)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = COLORS.BgCard
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Size = UDim2.new(1, -6, 0, 48)
    addCorner(card, 6)
    addStroke(card, accentColor or COLORS.Border, 1)
    card.Parent = parent

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = card

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 4)
    lay.Parent = card

    makeLabel(card, {
        text = titleText,
        font = STUDIO_FONT_BOLD,
        textSize = 12,
        textColor = accentColor or COLORS.AccentBlue,
        size = UDim2.new(1, 0, 0, 16),
        wrap = true,
    })

    local body = makeLabel(card, {
        text = bodyText,
        font = STUDIO_FONT,
        textSize = 11,
        textColor = COLORS.TextPrimary,
        size = UDim2.new(1, 0, 0, 0),
        wrap = true,
        alignY = Enum.TextYAlignment.Top,
    })
    body.AutomaticSize = Enum.AutomaticSize.Y
    return card, body
end

local function selectAssetAndFocus(category, assetId)
    state.activeCategory = category
    state.selectedAssetId = assetId

    if category == "Characters" then
        if assetId == "KMUTNBArms" then
            state.activeCategory = "Weapons"
            state.selectedAssetId = state.bayWeaponName
            state.weaponSubMode = "AnimBay"
            state.bayViewMode = "1P_Arms"
            setCameraMode("Orbit")
            setFocusView(WEAPON_BAY_POS + Vector3.new(0, 2.8, 0), 3.6, math.rad(210), math.rad(-14))
        else
            local fPos, d, yaw, pitch = getPlinthFocusData("Character", assetId)
            if fPos then
                setCameraMode("Orbit")
                setFocusView(fPos, d, yaw, pitch)
            end
        end
    elseif category == "Zombies" or category == "Bosses" then
        local fPos, d, yaw, pitch = getPlinthFocusData("Character", assetId)
        if fPos then
            setCameraMode("Orbit")
            setFocusView(fPos, d, yaw, pitch)
        end
    elseif category == "Weapons" then
        state.bayWeaponName = assetId
        if state.weaponSubMode == "AnimBay" then
            buildWeaponBayRig(assetId, state.bayViewMode)
            if state.cameraMode ~= "WeaponEye1P" then
                setCameraMode("Orbit")
                setFocusView(WEAPON_BAY_POS + Vector3.new(0, 2.8, 0), 3.5, math.rad(215), math.rad(-15))
            end
        else
            local fPos, d, yaw, pitch = getPlinthFocusData("Weapon", assetId)
            if fPos then
                setCameraMode("Orbit")
                setFocusView(fPos, d, yaw, pitch)
            end
        end
    elseif category == "Animations" then
        setCameraMode("Orbit")
        setFocusView(STAGE_POS + Vector3.new(0, 2.8, 0), state.stageHeroId == "MaleBoss" and 13 or 8.5, math.rad(195), math.rad(-12))
    elseif category == "Movement" then
        setFocusView(MOVEMENT_AREA_FOCUS, 26, math.rad(205), math.rad(-22))
    end
end

local function sendStageCommand(payload)
    if stageControlEvent then
        stageControlEvent:FireServer(payload)
    end
end

local function selectStageHero(heroId)
    state.stageHeroId = heroId
    local isZombie = (heroId ~= "PlayerR15")
    state.stageIsZombie = isZombie
    state.stageClipId = "Idle"
    state.stagePaused = false

    if isZombie then
        destroyStagePlayerPreview()
    end
    sendStageCommand({ action = "SpawnHero", assetId = heroId })
    if not isZombie then
        task.defer(function()
            playStagePlayerClip("Idle", { restart = true })
            if rebuildUI then rebuildUI() end
        end)
    end
end

local function populateLeftList()
    clearChildrenKeepingLayout(leftScroll)

    local function addLeftCard(title, sub, isSelected, onClick)
        local card = makeButton(leftScroll, {
            text = "",
            bgColor = isSelected and COLORS.BgSelected or COLORS.BgCard,
            strokeColor = isSelected and COLORS.AccentBlue or COLORS.Border,
            size = UDim2.new(1, -6, 0, 48),
            radius = 6,
        })
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = card

        makeLabel(card, {
            text = title,
            font = STUDIO_FONT_BOLD,
            textSize = 12,
            textColor = isSelected and COLORS.TextPrimary or COLORS.TextPrimary,
            size = UDim2.new(1, 0, 0, 20),
            pos = UDim2.new(0, 0, 0, 5),
        })
        makeLabel(card, {
            text = sub,
            font = STUDIO_FONT,
            textSize = 10,
            textColor = isSelected and COLORS.AccentAmber or COLORS.TextMuted,
            size = UDim2.new(1, 0, 0, 16),
            pos = UDim2.new(0, 0, 0, 25),
        })
        card.MouseButton1Click:Connect(onClick)
    end

    local cat = state.activeCategory
    if cat == "Characters" then
        leftTitleLbl.Text = "CHARACTERS & 1P RIG (ZONE A/E)"
        for _, item in ipairs(CHARACTER_ASSETS) do
            addLeftCard(item.title, item.subtitle, state.selectedAssetId == item.id, function()
                selectAssetAndFocus("Characters", item.id)
                rebuildUI()
            end)
        end
    elseif cat == "Zombies" then
        leftTitleLbl.Text = "INFECTED R15 RIGS (ZONE A)"
        for _, item in ipairs(ZOMBIE_ASSETS) do
            addLeftCard(item.title, item.subtitle, state.selectedAssetId == item.id, function()
                selectAssetAndFocus("Zombies", item.id)
                rebuildUI()
            end)
        end
    elseif cat == "Bosses" then
        leftTitleLbl.Text = "BOSS MUTANT RIG (ZONE A)"
        for _, item in ipairs(BOSS_ASSETS) do
            addLeftCard(item.title, item.subtitle, state.selectedAssetId == item.id, function()
                selectAssetAndFocus("Bosses", item.id)
                rebuildUI()
            end)
        end
    elseif cat == "Weapons" then
        leftTitleLbl.Text = "WEAPONS (18 @ 1:1 SCALE)"
        for _, wName in ipairs(WEAPON_ORDER) do
            local cfg = WeaponRegistry.get(wName)
            if cfg then
                local sub = string.format("%s  •  DMG %d  •  %d/%d",
                    cfg.Category or cfg.Type or "Weapon",
                    math.floor(cfg.Damage or 0),
                    cfg.Mag or 0,
                    cfg.Reserve or 0)
                addLeftCard(cfg.Name or wName, sub, state.selectedAssetId == wName, function()
                    selectAssetAndFocus("Weapons", wName)
                    rebuildUI()
                end)
            end
        end
    elseif cat == "Animations" then
        leftTitleLbl.Text = "STAGE HERO RIGS (ZONE C)"
        for _, opt in ipairs(STAGE_HERO_OPTIONS) do
            local tag = opt.isZombie and "ZombieAnimationController (8 States)" or "Roblox R15 Animate"
            addLeftCard(opt.label, tag, state.stageHeroId == opt.id, function()
                selectStageHero(opt.id)
                setFocusView(STAGE_POS + Vector3.new(0, 2.8, 0), opt.id == "MaleBoss" and 13 or 8.5, math.rad(195), math.rad(-12))
                rebuildUI()
            end)
        end
    elseif cat == "Movement" then
        leftTitleLbl.Text = "MOVEMENT RUNNER RIGS (ZONE D)"
        for _, opt in ipairs(STAGE_HERO_OPTIONS) do
            if opt.isZombie then
                addLeftCard(opt.label, "Patrol Runway Tester (80-stud track)", state.patrolAssetId == opt.id, function()
                    state.patrolAssetId = opt.id
                    rebuildUI()
                end)
            end
        end
    end
end

local function buildPlaybackTransportRow(parent, isPaused, currentSpeed, onPlay, onPause, onRestart, onResetPose, onSpeedPick)
    local row1 = Instance.new("Frame")
    row1.BackgroundTransparency = 1
    row1.Size = UDim2.new(1, -6, 0, 28)
    row1.Parent = parent

    local l1 = Instance.new("UIListLayout")
    l1.FillDirection = Enum.FillDirection.Horizontal
    l1.Padding = UDim.new(0, 5)
    l1.Parent = row1

    local playBtn = makeButton(row1, {
        text = "Play",
        bgColor = not isPaused and COLORS.BgSelected or COLORS.BgCard,
        strokeColor = not isPaused and COLORS.AccentGreen or COLORS.Border,
        size = UDim2.new(0, 58, 1, 0),
        textSize = 11,
    })
    playBtn.MouseButton1Click:Connect(onPlay)

    local pauseBtn = makeButton(row1, {
        text = "Pause",
        bgColor = isPaused and COLORS.BgSelected or COLORS.BgCard,
        strokeColor = isPaused and COLORS.AccentAmber or COLORS.Border,
        size = UDim2.new(0, 58, 1, 0),
        textSize = 11,
    })
    pauseBtn.MouseButton1Click:Connect(onPause)

    local restartBtn = makeButton(row1, {
        text = "Restart",
        size = UDim2.new(0, 68, 1, 0),
        textSize = 11,
    })
    restartBtn.MouseButton1Click:Connect(onRestart)

    local resetBtn = makeButton(row1, {
        text = "Default Pose",
        size = UDim2.new(0, 82, 1, 0),
        textSize = 11,
    })
    resetBtn.MouseButton1Click:Connect(onResetPose)

    local speedRow = Instance.new("Frame")
    speedRow.BackgroundTransparency = 1
    speedRow.Size = UDim2.new(1, -6, 0, 26)
    speedRow.Parent = parent

    local l2 = Instance.new("UIListLayout")
    l2.FillDirection = Enum.FillDirection.Horizontal
    l2.Padding = UDim.new(0, 4)
    l2.Parent = speedRow

    for _, spd in ipairs(SPEED_PRESETS) do
        local selected = math.abs(currentSpeed - spd) < 0.01
        local b = makeButton(speedRow, {
            text = tostring(spd) .. "x",
            bgColor = selected and COLORS.BgSelected or COLORS.BgCard,
            strokeColor = selected and COLORS.AccentBlue or COLORS.Border,
            size = UDim2.new(0, 50, 1, 0),
            textSize = 11,
        })
        b.MouseButton1Click:Connect(function()
            onSpeedPick(spd)
        end)
    end
end

local movementTelemetryBody = nil

local function populateRightInspector()
    clearChildrenKeepingLayout(rightScroll)
    movementTelemetryBody = nil

    local cat = state.activeCategory

    if cat == "Characters" or cat == "Zombies" or cat == "Bosses" then
        local list = (cat == "Characters" and CHARACTER_ASSETS) or (cat == "Zombies" and ZOMBIE_ASSETS) or BOSS_ASSETS
        local selected = list[1]
        for _, item in ipairs(list) do
            if item.id == state.selectedAssetId then
                selected = item
                break
            end
        end
        addInspectorCard(rightScroll, selected.title, selected.subtitle .. "\n\n" .. selected.rigNote, COLORS.AccentBlue)
        addInspectorCard(rightScroll, "Asset Audit Status",
            (selected.id == "PlayerR15")
                and "Mesh/Rig: Standard Roblox R15 Avatar\nScale: 1:1 Player (~5.0 studs)"
                or "Mesh/Rig: Procedural R15 Motor6D Rig (no external .fbx/.rbxm imported)\nScale: Verified 1:1 in ZombieCatalog",
            COLORS.AccentAmber)

        if selected.stageHeroId then
            local stageBtn = makeButton(rightScroll, {
                text = "Send to Animation Preview Stage ->",
                font = STUDIO_FONT_BOLD,
                bgColor = COLORS.BgSelected,
                strokeColor = COLORS.AccentBlue,
                size = UDim2.new(1, -6, 0, 34),
            })
            stageBtn.MouseButton1Click:Connect(function()
                selectStageHero(selected.stageHeroId)
                state.activeCategory = "Animations"
                setCameraMode("Orbit")
                setFocusView(STAGE_POS + Vector3.new(0, 2.8, 0), selected.stageHeroId == "MaleBoss" and 13 or 8.5, math.rad(195), math.rad(-12))
                rebuildUI()
            end)
        end
    elseif cat == "Weapons" then
        local cfg = WeaponRegistry.get(state.selectedAssetId) or WeaponRegistry.get("Vandal")
        local subRow = Instance.new("Frame")
        subRow.BackgroundTransparency = 1
        subRow.Size = UDim2.new(1, -6, 0, 30)
        subRow.Parent = rightScroll
        local l = Instance.new("UIListLayout")
        l.FillDirection = Enum.FillDirection.Horizontal
        l.Padding = UDim.new(0, 6)
        l.Parent = subRow

        local bStand = makeButton(subRow, {
            text = "Zone B: Stand 1:1",
            font = STUDIO_FONT_BOLD,
            bgColor = (state.weaponSubMode == "Stand") and COLORS.BgSelected or COLORS.BgCard,
            strokeColor = (state.weaponSubMode == "Stand") and COLORS.AccentAmber or COLORS.Border,
            size = UDim2.new(0.49, 0, 1, 0),
        })
        bStand.MouseButton1Click:Connect(function()
            state.weaponSubMode = "Stand"
            setCameraMode("Orbit")
            selectAssetAndFocus("Weapons", cfg.Name)
            rebuildUI()
        end)

        local bBay = makeButton(subRow, {
            text = "Zone E: Anim Lab",
            font = STUDIO_FONT_BOLD,
            bgColor = (state.weaponSubMode == "AnimBay") and COLORS.BgSelected or COLORS.BgCard,
            strokeColor = (state.weaponSubMode == "AnimBay") and COLORS.AccentBlue or COLORS.Border,
            size = UDim2.new(0.49, 0, 1, 0),
        })
        bBay.MouseButton1Click:Connect(function()
            state.weaponSubMode = "AnimBay"
            state.bayWeaponName = cfg.Name
            buildWeaponBayRig(cfg.Name, state.bayViewMode)
            setCameraMode("Orbit")
            setFocusView(WEAPON_BAY_POS + Vector3.new(0, 2.8, 0), 3.6, math.rad(215), math.rad(-14))
            rebuildUI()
        end)

        local profile = WeaponPoseSolver.getProfile(cfg)
        addInspectorCard(rightScroll, cfg.Name .. "  (" .. (cfg.Category or cfg.Type) .. ")",
            string.format("Damage: %d   •   FireRate: %d RPM\nMag / Reserve: %d / %d   •   Reload: %.1fs\nFiring: %s   •   Action Mode: %s",
                math.floor(cfg.Damage or 0),
                math.floor(cfg.FireRate or 0),
                cfg.Mag or 0, cfg.Reserve or 0,
                cfg.ReloadTime or 2.0,
                cfg.FiringType or "Semi",
                profile and profile.shotMode or "Standard"),
            COLORS.AccentAmber)

        if state.weaponSubMode == "AnimBay" then
            -- View perspective switcher (1P Arms / 1P Gun / 3P R15 + Eye Cam toggle)
            local vRow = Instance.new("Frame")
            vRow.BackgroundTransparency = 1
            vRow.Size = UDim2.new(1, -6, 0, 28)
            vRow.Parent = rightScroll
            local vl = Instance.new("UIListLayout")
            vl.FillDirection = Enum.FillDirection.Horizontal
            vl.Padding = UDim.new(0, 4)
            vl.Parent = vRow

            for _, vOpt in ipairs({
                { id = "1P_Arms", label = "1P Arms+Gun" },
                { id = "1P_GunOnly", label = "Gun Only" },
                { id = "3P_Character", label = "3P Rig" },
            }) do
                local vb = makeButton(vRow, {
                    text = vOpt.label,
                    bgColor = (state.bayViewMode == vOpt.id) and COLORS.BgSelected or COLORS.BgCard,
                    strokeColor = (state.bayViewMode == vOpt.id) and COLORS.AccentBlue or COLORS.Border,
                    size = UDim2.new(0.32, 0, 1, 0),
                    textSize = 11,
                })
                vb.MouseButton1Click:Connect(function()
                    state.bayViewMode = vOpt.id
                    buildWeaponBayRig(state.bayWeaponName, vOpt.id)
                    if state.cameraMode == "WeaponEye1P" and vOpt.id ~= "1P_Arms" then
                        setCameraMode("Orbit")
                    end
                    rebuildUI()
                end)
            end

            if state.bayViewMode == "1P_Arms" then
                local eyeBtn = makeButton(rightScroll, {
                    text = (state.cameraMode == "WeaponEye1P") and "Cam: FPS Eye-Level (Click for Orbit)" or "Cam: Switch to Real FPS Eye-Level View",
                    font = STUDIO_FONT_BOLD,
                    bgColor = (state.cameraMode == "WeaponEye1P") and COLORS.BgSelected or COLORS.BgCard,
                    strokeColor = COLORS.AccentGreen,
                    size = UDim2.new(1, -6, 0, 28),
                    textSize = 11,
                })
                eyeBtn.MouseButton1Click:Connect(function()
                    if state.cameraMode == "WeaponEye1P" then
                        setCameraMode("Orbit")
                        setFocusView(WEAPON_BAY_POS + Vector3.new(0, 2.8, 0), 3.6, math.rad(215), math.rad(-14))
                    else
                        setCameraMode("WeaponEye1P")
                    end
                    rebuildUI()
                end)
            elseif state.bayViewMode == "3P_Character" then
                addInspectorCard(rightScroll, "3P Support Note",
                    "No dedicated 3P weapon AnimationIds exist in repo; driving real 1:1 weapon model with synced WeaponPoseSolver poses.",
                    COLORS.TextMuted)
            end

            buildPlaybackTransportRow(rightScroll, state.bayPaused, state.baySpeed,
                function() state.bayPaused = false; rebuildUI() end,
                function() state.bayPaused = true; rebuildUI() end,
                function() startWeaponBayClip(state.bayClipId); rebuildUI() end,
                function() state.bayPaused = false; startWeaponBayClip("Idle"); rebuildUI() end,
                function(spd) state.baySpeed = spd; rebuildUI() end
            )

            for _, clip in ipairs(WEAPON_ANIM_CLIPS) do
                local selected = (state.bayClipId == clip.id)
                local cb = makeButton(rightScroll, {
                    text = clip.label,
                    bgColor = selected and COLORS.BgSelected or COLORS.BgCard,
                    strokeColor = selected and COLORS.AccentBlue or COLORS.Border,
                    size = UDim2.new(1, -6, 0, 26),
                    textSize = 11,
                })
                cb.MouseButton1Click:Connect(function()
                    state.bayPaused = false
                    startWeaponBayClip(clip.id)
                    rebuildUI()
                end)
            end
        end
    elseif cat == "Animations" then
        local heroNote = state.stageIsZombie
            and "Driving live server ZombieAnimationController (Procedural R15 Motor6D)."
            or "Driving Player R15 clone with real runtime Animate tracks."
        addInspectorCard(rightScroll, "Stage Hero: " .. state.stageHeroId, heroNote, COLORS.AccentBlue)

        if state.stageStatusText ~= "" then
            addInspectorCard(rightScroll, "Clip / Asset Status", state.stageStatusText, COLORS.AccentAmber)
        end

        if not state.stageIsZombie then
            for _, pClip in ipairs(PLAYER_STAGE_CLIPS) do
                if pClip.id == state.stageClipId and pClip.redirectWeaponBay then
                    local jumpBtn = makeButton(rightScroll, {
                        text = "Open '" .. pClip.redirectWeaponBay .. "' in 1P/3P Weapon Anim Lab ->",
                        font = STUDIO_FONT_BOLD,
                        bgColor = COLORS.BgSelected,
                        strokeColor = COLORS.AccentAmber,
                        size = UDim2.new(1, -6, 0, 30),
                        textSize = 11,
                    })
                    jumpBtn.MouseButton1Click:Connect(function()
                        openStudioMode("Weapons", state.bayWeaponName, "WeaponAnim")
                        state.bayPaused = false
                        startWeaponBayClip(pClip.redirectWeaponBay)
                        rebuildUI()
                    end)
                    break
                end
            end
        end

        buildPlaybackTransportRow(rightScroll, state.stagePaused, state.stageSpeed,
            function()
                state.stagePaused = false
                if state.stageIsZombie then
                    sendStageCommand({ action = "Playback", state = state.stageClipId, paused = false, speed = state.stageSpeed, loop = state.stageLoop, isHeadshot = state.stageHeadshot })
                else
                    playStagePlayerClip(state.stageClipId, {})
                end
                rebuildUI()
            end,
            function()
                state.stagePaused = true
                if state.stageIsZombie then
                    sendStageCommand({ action = "Playback", state = state.stageClipId, paused = true, speed = state.stageSpeed, loop = state.stageLoop })
                else
                    playStagePlayerClip(state.stageClipId, {})
                end
                rebuildUI()
            end,
            function()
                state.stagePaused = false
                if state.stageIsZombie then
                    sendStageCommand({ action = "Playback", state = state.stageClipId, paused = false, speed = state.stageSpeed, loop = state.stageLoop, restart = true, isHeadshot = state.stageHeadshot })
                else
                    playStagePlayerClip(state.stageClipId, { restart = true })
                end
                rebuildUI()
            end,
            function()
                state.stageClipId = "Idle"
                state.stagePaused = false
                state.stageSpeed = 1.0
                if state.stageIsZombie then
                    sendStageCommand({ action = "ResetPose" })
                else
                    playStagePlayerClip("Idle", { restart = true })
                end
                rebuildUI()
            end,
            function(spd)
                state.stageSpeed = spd
                if state.stageIsZombie then
                    sendStageCommand({ action = "Playback", state = state.stageClipId, paused = state.stagePaused, speed = spd, loop = state.stageLoop })
                else
                    playStagePlayerClip(state.stageClipId, {})
                end
                rebuildUI()
            end
        )

        local optRow = Instance.new("Frame")
        optRow.BackgroundTransparency = 1
        optRow.Size = UDim2.new(1, -6, 0, 26)
        optRow.Parent = rightScroll
        local ol = Instance.new("UIListLayout")
        ol.FillDirection = Enum.FillDirection.Horizontal
        ol.Padding = UDim.new(0, 6)
        ol.Parent = optRow

        local loopBtn = makeButton(optRow, {
            text = state.stageLoop and "Loop: ON" or "Loop: OFF",
            bgColor = state.stageLoop and COLORS.BgSelected or COLORS.BgCard,
            size = UDim2.new(0.49, 0, 1, 0),
            textSize = 11,
        })
        loopBtn.MouseButton1Click:Connect(function()
            state.stageLoop = not state.stageLoop
            if state.stageIsZombie then
                sendStageCommand({ action = "Playback", state = state.stageClipId, paused = state.stagePaused, speed = state.stageSpeed, loop = state.stageLoop })
            else
                playStagePlayerClip(state.stageClipId, {})
            end
            rebuildUI()
        end)

        if state.stageIsZombie then
            local hsBtn = makeButton(optRow, {
                text = state.stageHeadshot and "Hit: HEADSHOT" or "Hit: BODY",
                bgColor = state.stageHeadshot and Color3.fromRGB(78, 32, 36) or COLORS.BgCard,
                strokeColor = state.stageHeadshot and COLORS.AccentRed or COLORS.Border,
                size = UDim2.new(0.49, 0, 1, 0),
                textSize = 11,
            })
            hsBtn.MouseButton1Click:Connect(function()
                state.stageHeadshot = not state.stageHeadshot
                rebuildUI()
            end)
        end

        local clips = state.stageIsZombie and ZOMBIE_STAGE_CLIPS or PLAYER_STAGE_CLIPS
        for _, clip in ipairs(clips) do
            local selected = (state.stageClipId == clip.id)
            local labelText = clip.supported
                and (clip.label .. (clip.source and ("  [" .. clip.source .. "]") or ""))
                or (clip.label .. "  [NO ASSET]")
            local cb = makeButton(rightScroll, {
                text = labelText,
                textColor = clip.supported and COLORS.TextPrimary or COLORS.TextMuted,
                bgColor = selected and COLORS.BgSelected or COLORS.BgCard,
                strokeColor = selected and COLORS.AccentBlue or (clip.supported and COLORS.Border or Color3.fromRGB(70, 42, 46)),
                size = UDim2.new(1, -6, 0, 26),
                textSize = 11,
            })
            cb.MouseButton1Click:Connect(function()
                state.stageClipId = clip.id
                if clip.redirectWeaponBay then
                    state.stageStatusText = clip.note
                    rebuildUI()
                    return
                end
                if not clip.supported then
                    state.stageStatusText = clip.note
                    rebuildUI()
                    return
                end
                state.stagePaused = false
                if state.stageIsZombie then
                    state.stageStatusText = clip.note
                    sendStageCommand({
                        action = "Playback",
                        state = clip.id,
                        paused = false,
                        speed = state.stageSpeed,
                        loop = state.stageLoop,
                        restart = true,
                        isHeadshot = state.stageHeadshot,
                    })
                else
                    playStagePlayerClip(clip.id, { restart = true })
                end
                rebuildUI()
            end)
        end
    elseif cat == "Movement" then
        addInspectorCard(rightScroll, "Zone D — Movement Testing Area",
            "80-stud Speed Runway (walk/sprint calibration), Slalom Pylons (turning/accel), Jump Steps, & Neon Slide Gate.",
            COLORS.AccentGreen)

        local tpBtn = makeButton(rightScroll, {
            text = (state.cameraMode == "ThirdPersonFollow")
                and "3rd-Person Follow Cam: ON (Play WASD Now!)"
                or "Enable 3rd-Person Movement Camera (WASD)",
            font = STUDIO_FONT_BOLD,
            bgColor = (state.cameraMode == "ThirdPersonFollow") and COLORS.BgSelected or COLORS.BgCard,
            strokeColor = COLORS.AccentGreen,
            size = UDim2.new(1, -6, 0, 34),
            textSize = 11,
        })
        tpBtn.MouseButton1Click:Connect(function()
            if state.cameraMode == "ThirdPersonFollow" then
                setCameraMode("Orbit")
                setFocusView(MOVEMENT_AREA_FOCUS, 26, math.rad(205), math.rad(-22))
            else
                setCameraMode("ThirdPersonFollow")
            end
            rebuildUI()
        end)

        local _, body = addInspectorCard(rightScroll, "Live Character Telemetry", "Sampling...", COLORS.AccentAmber)
        movementTelemetryBody = body

        local resetPeakBtn = makeButton(rightScroll, {
            text = "Reset Peak Speed",
            size = UDim2.new(1, -6, 0, 24),
            textSize = 11,
        })
        resetPeakBtn.MouseButton1Click:Connect(function()
            state.peakSpeed = 0
        end)

        -- Zombie / Boss Runway Patrol Tester
        local modeRow = Instance.new("Frame")
        modeRow.BackgroundTransparency = 1
        modeRow.Size = UDim2.new(1, -6, 0, 26)
        modeRow.Parent = rightScroll
        local ml = Instance.new("UIListLayout")
        ml.FillDirection = Enum.FillDirection.Horizontal
        ml.Padding = UDim.new(0, 4)
        ml.Parent = modeRow

        for _, spdMode in ipairs({ "Walk", "Run", "Chase" }) do
            local mb = makeButton(modeRow, {
                text = spdMode,
                bgColor = (state.patrolSpeedMode == spdMode) and COLORS.BgSelected or COLORS.BgCard,
                size = UDim2.new(0.32, 0, 1, 0),
                textSize = 11,
            })
            mb.MouseButton1Click:Connect(function()
                state.patrolSpeedMode = spdMode
                if state.patrolRunning then
                    sendStageCommand({ action = "StartPatrol", assetId = state.patrolAssetId, speedMode = spdMode })
                end
                rebuildUI()
            end)
        end

        local patrolRow = Instance.new("Frame")
        patrolRow.BackgroundTransparency = 1
        patrolRow.Size = UDim2.new(1, -6, 0, 30)
        patrolRow.Parent = rightScroll
        local pl = Instance.new("UIListLayout")
        pl.FillDirection = Enum.FillDirection.Horizontal
        pl.Padding = UDim.new(0, 6)
        pl.Parent = patrolRow

        local startPatrolBtn = makeButton(patrolRow, {
            text = "Run Bot: " .. state.patrolAssetId,
            bgColor = COLORS.BgSelected,
            strokeColor = COLORS.AccentBlue,
            size = UDim2.new(0.66, 0, 1, 0),
            textSize = 11,
        })
        startPatrolBtn.MouseButton1Click:Connect(function()
            state.patrolRunning = true
            sendStageCommand({ action = "StartPatrol", assetId = state.patrolAssetId, speedMode = state.patrolSpeedMode })
            if state.cameraMode == "Orbit" then
                setFocusView(MOVEMENT_AREA_FOCUS, 26, math.rad(205), math.rad(-20))
            end
        end)

        local stopPatrolBtn = makeButton(patrolRow, {
            text = "Stop Bot",
            bgColor = Color3.fromRGB(58, 28, 32),
            strokeColor = COLORS.AccentRed,
            size = UDim2.new(0.32, 0, 1, 0),
            textSize = 11,
        })
        stopPatrolBtn.MouseButton1Click:Connect(function()
            state.patrolRunning = false
            sendStageCommand({ action = "StopPatrol" })
        end)
    end
end

rebuildUI = function()
    togglePill.Visible = state.inRange and not state.studioOpen
    rangeHintPill.Visible = state.inRange and not state.studioOpen
    studioRoot.Visible = state.inRange and state.studioOpen

    if not (state.inRange and state.studioOpen) then return end

    for catId, btn in pairs(categoryTabButtons) do
        local active = (state.activeCategory == catId)
        btn.BackgroundColor3 = active and COLORS.BgSelected or COLORS.BgCard
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = active and COLORS.AccentBlue or COLORS.Border
        end
    end

    camToggleTopBtn.Text = (state.cameraMode == "Walk") and "FPS Walk [K]"
        or ((state.cameraMode == "ThirdPersonFollow") and "3P Follow [K]"
        or ((state.cameraMode == "WeaponEye1P") and "1P Eye Cam" or "Orbit 360 [K]"))

    bottomBar.Visible = (state.cameraMode == "Orbit")
    populateLeftList()
    populateRightInspector()
end

----------------------------------------------------------------------
-- 8. OPEN / CLOSE & INTERACTION WIRING
----------------------------------------------------------------------
local function syncStageHeroFromWorld()
    local range = getRangeFolder()
    local stageFolder = range and range:FindFirstChild("AnimationPreviewStage")
    local heroMount = stageFolder and stageFolder:FindFirstChild("ActiveHeroRig")
    if not heroMount then return end
    for _, child in ipairs(heroMount:GetChildren()) do
        if child.Name == "PlayerR15_Showcase" then
            state.stageHeroId = "PlayerR15"
            state.stageIsZombie = false
            return
        elseif child.Name:sub(1, 10) == "StageHero_" then
            state.stageHeroId = child.Name:sub(11)
            state.stageIsZombie = true
            return
        end
    end
end

local function exitStudioMode()
    state.studioOpen = false
    state.draggingOrbit = false
    setCameraMode("Walk")
    destroyStagePlayerPreview()
    destroyWeaponBayRig()
    if state.patrolRunning then
        state.patrolRunning = false
        sendStageCommand({ action = "StopPatrol" })
    end
    rebuildUI()
end

openStudioMode = function(category, assetId, kindOverride)
    if not isPlayerInsideRange() then return end
    syncStageHeroFromWorld()
    state.studioOpen = true
    if category then
        state.activeCategory = category
    end
    if kindOverride == "WeaponAnim" then
        state.activeCategory = "Weapons"
        state.weaponSubMode = "AnimBay"
        buildWeaponBayRig(state.bayWeaponName, state.bayViewMode)
        setCameraMode("Orbit")
        setFocusView(WEAPON_BAY_POS + Vector3.new(0, 2.8, 0), 3.6, math.rad(215), math.rad(-14))
    elseif kindOverride == "Stage" then
        state.activeCategory = "Animations"
        setCameraMode("Orbit")
        setFocusView(STAGE_POS + Vector3.new(0, 2.8, 0), state.stageHeroId == "MaleBoss" and 13 or 8.5, math.rad(195), math.rad(-12))
    elseif assetId then
        if category == "Weapons" then
            state.weaponSubMode = "Stand"
        end
        selectAssetAndFocus(state.activeCategory, assetId)
    else
        selectAssetAndFocus(state.activeCategory, state.selectedAssetId)
    end
    if state.activeCategory == "Animations" and not state.stageIsZombie then
        task.defer(function()
            playStagePlayerClip(state.stageClipId, {})
            if rebuildUI then rebuildUI() end
        end)
    end
    rebuildUI()
end

togglePill.MouseButton1Click:Connect(function()
    openStudioMode()
end)

closeStudioBtn.MouseButton1Click:Connect(function()
    exitStudioMode()
end)

camToggleTopBtn.MouseButton1Click:Connect(function()
    if state.cameraMode == "Orbit" or state.cameraMode == "WeaponEye1P" then
        setCameraMode("Walk")
    elseif state.activeCategory == "Movement" and state.cameraMode == "Walk" then
        setCameraMode("ThirdPersonFollow")
    else
        setCameraMode("Orbit")
    end
    rebuildUI()
end)

for catId, btn in pairs(categoryTabButtons) do
    btn.MouseButton1Click:Connect(function()
        local defaultId = (catId == "Characters" and "PlayerR15")
            or (catId == "Zombies" and "MaleWalker")
            or (catId == "Bosses" and "MaleBoss")
            or (catId == "Weapons" and (state.bayWeaponName or "Vandal"))
            or state.stageHeroId
        selectAssetAndFocus(catId, defaultId)
        if catId == "Animations" and not state.stageIsZombie then
            task.defer(function()
                playStagePlayerClip(state.stageClipId, {})
                if rebuildUI then rebuildUI() end
            end)
        end
        rebuildUI()
    end)
end

btnCamFront.MouseButton1Click:Connect(function() state.targetYaw = math.rad(180); state.targetPitch = math.rad(-12) end)
btnCamSide.MouseButton1Click:Connect(function() state.targetYaw = math.rad(90); state.targetPitch = math.rad(-10) end)
btnCamBack.MouseButton1Click:Connect(function() state.targetYaw = 0; state.targetPitch = math.rad(-12) end)
btnZoomOut.MouseButton1Click:Connect(function() state.targetDist = math.clamp(state.targetDist + 1.5, state.minDist, state.maxDist) end)
btnZoomIn.MouseButton1Click:Connect(function() state.targetDist = math.clamp(state.targetDist - 1.5, state.minDist, state.maxDist) end)
btnCamReset.MouseButton1Click:Connect(function()
    selectAssetAndFocus(state.activeCategory, state.selectedAssetId)
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, triggerPlayer)
    if triggerPlayer ~= player then return end
    if prompt.Name ~= "StudioInspectPrompt" then return end
    local kind = prompt:GetAttribute("ShowcaseKind")
    local assetId = prompt:GetAttribute("ShowcaseAssetId")
    if kind == "Character" then
        local cat = (assetId == "MaleBoss" and "Bosses")
            or ((assetId == "PlayerR15") and "Characters" or "Zombies")
        openStudioMode(cat, assetId)
    elseif kind == "Weapon" then
        state.weaponSubMode = "Stand"
        openStudioMode("Weapons", assetId)
    elseif kind == "Stage" then
        openStudioMode("Animations", nil, "Stage")
    elseif kind == "WeaponAnim" then
        openStudioMode("Weapons", state.bayWeaponName, "WeaponAnim")
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if UserInputService:GetFocusedTextBox() then return end

    if input.KeyCode == Enum.KeyCode.V and not gameProcessed then
        if state.inRange then
            if state.studioOpen then
                exitStudioMode()
            else
                openStudioMode()
            end
        end
        return
    end

    if input.KeyCode == Enum.KeyCode.K and state.inRange and state.studioOpen and not gameProcessed then
        if state.cameraMode == "Orbit" or state.cameraMode == "WeaponEye1P" then
            setCameraMode("Walk")
        elseif state.activeCategory == "Movement" and state.cameraMode == "Walk" then
            setCameraMode("ThirdPersonFollow")
        else
            setCameraMode("Orbit")
        end
        rebuildUI()
        return
    end

    if not (state.inRange and state.studioOpen and state.cameraMode == "Orbit") then return end

    if not gameProcessed and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2) then
        state.draggingOrbit = true
        state.lastMousePos = input.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
        state.draggingOrbit = false
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if not (state.inRange and state.studioOpen and state.cameraMode == "Orbit") then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement and state.draggingOrbit then
        local delta = Vector2.new(input.Position.X - state.lastMousePos.X, input.Position.Y - state.lastMousePos.Y)
        state.lastMousePos = input.Position
        state.targetYaw = state.targetYaw - delta.X * 0.0085
        state.targetPitch = math.clamp(state.targetPitch - delta.Y * 0.0075, math.rad(-72), math.rad(58))
    elseif input.UserInputType == Enum.UserInputType.MouseWheel and not gameProcessed then
        state.targetDist = math.clamp(state.targetDist - input.Position.Z * 1.1, state.minDist, state.maxDist)
    end
end)

if stageStateEvent then
    stageStateEvent.OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then return end
        if payload.assetId then
            state.stageHeroId = payload.assetId
            state.stageIsZombie = (payload.isZombie ~= false)
        end
        if payload.state then state.stageClipId = payload.state end
        if payload.paused ~= nil then state.stagePaused = payload.paused end
        if payload.speed then state.stageSpeed = payload.speed end
        if state.studioOpen and state.activeCategory == "Animations" then
            rebuildUI()
        end
    end)
end

local function attachCharacterHooks(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.Died:Connect(function()
            exitStudioMode()
        end)
    end
end

if player.Character then
    task.spawn(attachCharacterHooks, player.Character)
end

player.CharacterAdded:Connect(function(char)
    exitStudioMode()
    attachCharacterHooks(char)
end)

----------------------------------------------------------------------
-- 9. RENDER & TELEMETRY LOOP
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    local nowInRange = isPlayerInsideRange()
    if nowInRange ~= state.inRange then
        state.inRange = nowInRange
        if not nowInRange then
            exitStudioMode()
        else
            togglePill.Visible = not state.studioOpen
            rangeHintPill.Visible = not state.studioOpen
        end
    end

    if not state.inRange then return end

    updateWeaponBayPreview(dt)

    -- Live movement telemetry (Zone D)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if root and hum then
        local v = root.AssemblyLinearVelocity
        local hv = Vector3.new(v.X, 0, v.Z)
        local speed = hv.Magnitude
        if speed > state.peakSpeed then state.peakSpeed = speed end
        local rawAccel = (speed - state.lastHorizVel.Magnitude) / math.max(0.001, dt)
        state.smoothedAccel = state.smoothedAccel + (rawAccel - state.smoothedAccel) * math.clamp(dt * 8, 0, 1)
        state.lastHorizVel = hv

        if movementTelemetryBody and movementTelemetryBody.Parent then
            movementTelemetryBody.Text = string.format(
                "Horiz Speed: %.1f st/s  (Peak %.1f)\nWalkSpeed Target: %.1f st/s\nAccel: %+.1f st/s2\nState: %s   |   Grounded: %s",
                speed, state.peakSpeed, hum.WalkSpeed, state.smoothedAccel,
                hum:GetState().Name, tostring(hum.FloorMaterial ~= Enum.Material.Air)
            )
        end
    end

    -- Studio Camera framing
    if state.studioOpen and state.cameraMode == "Orbit" then
        local alpha = 1 - math.exp(-dt * 14)
        state.focusPos = state.focusPos:Lerp(state.targetFocus, alpha)
        state.yaw = state.yaw + (state.targetYaw - state.yaw) * alpha
        state.pitch = state.pitch + (state.targetPitch - state.pitch) * alpha
        state.dist = state.dist + (state.targetDist - state.dist) * alpha

        local rotCF = CFrame.fromEulerAnglesYXZ(state.pitch, state.yaw, 0)
        local camPos = state.focusPos + (rotCF * Vector3.new(0, 0, state.dist))
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.lookAt(camPos, state.focusPos)
        zoomReadout.Text = string.format("%.1fm", state.dist)
    elseif state.studioOpen and state.cameraMode == "WeaponEye1P" then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = WEAPON_BAY_EYE_CF
    end
end)
