--[[
    TestRangeSetup.server.lua
    THE RANGE — 3D Model Showcase & Animation Testing Studio (Dark Semi-Realistic Dev Facility)

    Zones inside INFECTED_TestRange (RangeFloor 250x2x170 @ 0,0,470, top surface Y = 1.0):
      A. Character & Zombie Showcase Gallery (X = -86..-28, Z = 406..458) -> Player R15 + 5 actual Zombie/Boss rigs
      B. Weapon Showcase Gallery             (X = +28..+90, Z = 406..464) -> All 18 real weapons at 1:1 game scale
      C. Animation Preview Stage             (X = 0, Z = 428)             -> Hero Turntable Stage w/ 8-state controller
      D. Movement Testing Area               (X = -76..+76, Z = 478..546) -> Runway, turns, jump/slide blocks & patrol bot
      E. Weapon Animation Preview Bay        (X = 0, Z = 456)             -> Illuminated 1P/3P weapon animation booth

    Preserves all gameplay compatibility:
      - RangeFloor bounds for WaveAndZombieManager.isPlayerInsideTestRange()
      - PickupPrompt for all 18 weapons
      - TestRangeSpawnLocation, teleporters, /range & /lobby chat, TeleportEvents.RequestTeleport
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local campaignFolder = ServerScriptService:WaitForChild("Campaign", 10)
local DevAuthService = require(campaignFolder:WaitForChild("DevAuthService"))
local devAuth = DevAuthService.getSingleton()

local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons", 10)
local WeaponRegistry = require(weaponsFolder:WaitForChild("WeaponRegistry"))
local WeaponModelBuilder = require(weaponsFolder:WaitForChild("models"):WaitForChild("WeaponModelBuilder"))
local zombieSharedFolder = ReplicatedStorage:WaitForChild("ZombieModules", 10)
local ZombieCatalog = require(zombieSharedFolder:WaitForChild("ZombieCatalog"))
local ZombieModelFactory = require(zombieSharedFolder:WaitForChild("ZombieModelFactory"))
local ZombieAnimationController = require(zombieSharedFolder:WaitForChild("ZombieAnimationController"))
local ZombieAudioController = require(zombieSharedFolder:WaitForChild("ZombieAudioController"))

local ROOT_NAME = "INFECTED_TestRange"
local old = Workspace:FindFirstChild(ROOT_NAME)
if old then old:Destroy() end

----------------------------------------------------------------------
-- Remote Events (Pickups + Teleports + Showcase Studio Control)
----------------------------------------------------------------------
local remotes = ReplicatedStorage:FindFirstChild("WeaponPickupEvents") or Instance.new("Folder")
remotes.Name = "WeaponPickupEvents"
remotes.Parent = ReplicatedStorage

local granted = remotes:FindFirstChild("WeaponGranted") or Instance.new("RemoteEvent")
granted.Name = "WeaponGranted"
granted.Parent = remotes

local showcaseRemotes = ReplicatedStorage:FindFirstChild("ShowcaseEvents") or Instance.new("Folder")
showcaseRemotes.Name = "ShowcaseEvents"
showcaseRemotes.Parent = ReplicatedStorage

local stageControlEvent = showcaseRemotes:FindFirstChild("StageControl") or Instance.new("RemoteEvent")
stageControlEvent.Name = "StageControl"
stageControlEvent.Parent = showcaseRemotes

local stageStateEvent = showcaseRemotes:FindFirstChild("StageState") or Instance.new("RemoteEvent")
stageStateEvent.Name = "StageState"
stageStateEvent.Parent = showcaseRemotes

local range = Instance.new("Model")
range.Name = ROOT_NAME
range.Parent = Workspace

----------------------------------------------------------------------
-- Dark Studio Visual Palette & Helpers
----------------------------------------------------------------------
local STUDIO_FLOOR_COLOR = Color3.fromRGB(30, 34, 41)
local STUDIO_ZONE_COLOR = Color3.fromRGB(24, 27, 33)
local STUDIO_PLINTH_COLOR = Color3.fromRGB(40, 45, 54)
local STUDIO_PLINTH_TOP = Color3.fromRGB(54, 60, 72)
local STUDIO_WALL_COLOR = Color3.fromRGB(34, 38, 46)
local STUDIO_ACCENT_BLUE = Color3.fromRGB(56, 174, 255)
local STUDIO_ACCENT_AMBER = Color3.fromRGB(240, 178, 56)
local STUDIO_ACCENT_RED = Color3.fromRGB(228, 72, 82)
local STUDIO_TEXT_LIGHT = Color3.fromRGB(238, 243, 250)
local STUDIO_TEXT_MUTED = Color3.fromRGB(156, 170, 190)

local function part(parent, name, size, cf, color, material, anchored, canCollide, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Shape = shape or Enum.PartType.Block
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = (anchored ~= false)
    p.CanCollide = (canCollide ~= false)
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function addStudioLight(parent, position, color, brightness, rangeDist)
    local node = Instance.new("Part")
    node.Name = "StudioLightNode"
    node.Size = Vector3.new(0.8, 0.2, 0.8)
    node.CFrame = CFrame.new(position)
    node.Anchored = true
    node.CanCollide = false
    node.CanQuery = false
    node.CanTouch = false
    node.Transparency = 1
    node.Parent = parent

    local light = Instance.new("PointLight")
    light.Color = color or Color3.fromRGB(244, 248, 255)
    light.Brightness = brightness or 1.4
    light.Range = rangeDist or 38
    light.Shadows = true
    light.Parent = node
    return node
end

local function addPlaqueGui(parentPart, face, titleText, subtitleText, accentColor)
    local sgui = Instance.new("SurfaceGui")
    sgui.Face = face
    sgui.CanvasSize = Vector2.new(440, 140)
    sgui.LightInfluence = 0.2
    sgui.Parent = parentPart

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(16, 19, 24)
    bg.BorderSizePixel = 0
    bg.Parent = sgui

    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(1, 0, 0, 8)
    stripe.BackgroundColor3 = accentColor or STUDIO_ACCENT_BLUE
    stripe.BorderSizePixel = 0
    stripe.Parent = bg

    local title = Instance.new("TextLabel")
    title.Position = UDim2.new(0, 16, 0, 18)
    title.Size = UDim2.new(1, -32, 0, 56)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = titleText
    title.TextColor3 = STUDIO_TEXT_LIGHT
    title.TextScaled = true
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = bg

    local sub = Instance.new("TextLabel")
    sub.Position = UDim2.new(0, 16, 0, 80)
    sub.Size = UDim2.new(1, -32, 0, 44)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.GothamBold
    sub.Text = subtitleText or ""
    sub.TextColor3 = STUDIO_TEXT_MUTED
    sub.TextScaled = true
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = bg

    return sgui
end

local function buildZoneHeader(parent, name, pos, lookTarget, titleText, subText, accentColor)
    local board = part(parent, name, Vector3.new(16, 3.2, 0.45),
        CFrame.lookAt(pos, lookTarget), Color3.fromRGB(20, 24, 30), Enum.Material.SmoothPlastic, true, false)
    addPlaqueGui(board, Enum.NormalId.Front, titleText, subText, accentColor)
    return board
end

local function setFocusMetadata(model, centerPos, defaultDist, label, category)
    model:SetAttribute("ShowcaseFocusX", centerPos.X)
    model:SetAttribute("ShowcaseFocusY", centerPos.Y)
    model:SetAttribute("ShowcaseFocusZ", centerPos.Z)
    model:SetAttribute("ShowcaseDefaultDist", defaultDist)
    model:SetAttribute("ShowcaseLabel", label)
    model:SetAttribute("ShowcaseCategory", category)
end

local function buildPlayerR15Model(sourcePlayer, groundPos, facingDeg)
    local desc = Instance.new("HumanoidDescription")
    if sourcePlayer and sourcePlayer.UserId and sourcePlayer.UserId > 0 then
        local ok, loaded = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(sourcePlayer.UserId)
        end)
        if ok and loaded then
            desc = loaded
        end
    end

    local ok, model = pcall(function()
        return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
    end)
    if not ok or not model then
        model = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
    end

    model.Name = "PlayerR15_Showcase"
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
    local animateScript = model:FindFirstChild("Animate")
    if animateScript then
        animateScript:Destroy()
    end

    local hipH = hum and hum.HipHeight or 2.0
    local rootHalfY = hrp and (hrp.Size.Y * 0.5) or 1.0
    local rootY = groundPos.Y + hipH + rootHalfY
    if hrp then
        hrp.CFrame = CFrame.new(groundPos.X, rootY, groundPos.Z) * CFrame.Angles(0, math.rad(facingDeg or 0), 0)
        hrp.Anchored = true
    end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.CanCollide = false
            d.CanTouch = false
        end
    end
    return model, hum, hrp
end

----------------------------------------------------------------------
-- 1. Dark Modern Studio Floor, Zoning Strips & Architectural Backdrop
----------------------------------------------------------------------
part(range, "RangeFloor", Vector3.new(250, 2, 170), CFrame.new(0, 0, 470),
    STUDIO_FLOOR_COLOR, Enum.Material.Concrete)

-- Recessed dark studio zone pads (flush at Y = 1.01)
part(range, "ZonePad_Characters", Vector3.new(58, 0.04, 62), CFrame.new(-57, 1.02, 430),
    STUDIO_ZONE_COLOR, Enum.Material.SmoothPlastic, true, false)
part(range, "ZonePad_Weapons", Vector3.new(64, 0.04, 62), CFrame.new(58, 1.02, 430),
    STUDIO_ZONE_COLOR, Enum.Material.SmoothPlastic, true, false)
part(range, "ZonePad_Movement", Vector3.new(152, 0.04, 70), CFrame.new(0, 1.02, 512),
    STUDIO_ZONE_COLOR, Enum.Material.SmoothPlastic, true, false)

-- Thin studio accent floor trims separating functional bays
part(range, "Divider_Char", Vector3.new(0.25, 0.05, 62), CFrame.new(-28, 1.03, 430),
    STUDIO_ACCENT_BLUE, Enum.Material.Neon, true, false)
part(range, "Divider_Weapon", Vector3.new(0.25, 0.05, 62), CFrame.new(26, 1.03, 430),
    STUDIO_ACCENT_AMBER, Enum.Material.Neon, true, false)
part(range, "Divider_Movement", Vector3.new(152, 0.05, 0.28), CFrame.new(0, 1.03, 476),
    STUDIO_ACCENT_BLUE, Enum.Material.Neon, true, false)

-- Clean dark studio backdrop walls around outer wings (non-distracting architectural context)
part(range, "Backdrop_CharWest", Vector3.new(1.2, 16, 62), CFrame.new(-88, 9, 430),
    STUDIO_WALL_COLOR, Enum.Material.SmoothPlastic)
part(range, "Backdrop_WeaponEast", Vector3.new(1.2, 16, 62), CFrame.new(92, 9, 430),
    STUDIO_WALL_COLOR, Enum.Material.SmoothPlastic)
part(range, "Backdrop_MovementSouth", Vector3.new(156, 14, 1.2), CFrame.new(0, 8, 548),
    STUDIO_WALL_COLOR, Enum.Material.SmoothPlastic)

-- Studio zone lighting (Soft overhead softboxes + warm/cool fill)
addStudioLight(range, Vector3.new(-57, 18, 416), Color3.fromRGB(238, 244, 255), 1.45, 58)
addStudioLight(range, Vector3.new(-57, 18, 444), Color3.fromRGB(246, 240, 234), 1.45, 58)
addStudioLight(range, Vector3.new(58, 18, 416), Color3.fromRGB(255, 246, 232), 1.55, 62)
addStudioLight(range, Vector3.new(58, 18, 446), Color3.fromRGB(236, 244, 255), 1.55, 62)
addStudioLight(range, Vector3.new(0, 19, 428), Color3.fromRGB(248, 250, 255), 1.75, 50)
addStudioLight(range, Vector3.new(0, 16, 456), Color3.fromRGB(242, 246, 255), 1.55, 42)
addStudioLight(range, Vector3.new(-36, 18, 512), Color3.fromRGB(238, 244, 252), 1.35, 68)
addStudioLight(range, Vector3.new(36, 18, 512), Color3.fromRGB(238, 244, 252), 1.35, 68)

----------------------------------------------------------------------
-- 2. ZONE A — CHARACTER & ZOMBIE SHOWCASE GALLERY (Full-body 1:1 Scale)
----------------------------------------------------------------------
local charGallery = Instance.new("Folder")
charGallery.Name = "CharacterShowcaseGallery"
charGallery.Parent = range

buildZoneHeader(charGallery, "Header_CharGallery", Vector3.new(-39, 10.5, 424), Vector3.new(-39, 10.5, 405),
    "CHARACTER SHOWCASE", "DEFAULT PLAYER R15  •  1:1 SCALE", STUDIO_ACCENT_BLUE)
buildZoneHeader(charGallery, "Header_ZombieGallery", Vector3.new(-66, 11.5, 458), Vector3.new(-66, 11.5, 420),
    "ZOMBIE & BOSS SHOWCASE", "5 INFECTED R15 RIGS  •  WALKERS / RUNNERS / BOSS", STUDIO_ACCENT_RED)

local characterDisplays = {
    { id = "PlayerR15", type = "Player", title = "PLAYER (DEFAULT R15)", sub = "ROBLOX R15 HUMANOID  •  ~5.15 STUDS", x = -39, z = 414, radius = 6.6, dist = 8.5, accent = STUDIO_ACCENT_BLUE },
    { id = "MaleWalker", type = "Zombie", title = "MALE INFECTED", sub = "WALKER VARIANT  •  5.15 STUDS", x = -57, z = 414, radius = 6.6, dist = 8.5, accent = Color3.fromRGB(115, 200, 130) },
    { id = "FemaleWalker", type = "Zombie", title = "FEMALE INFECTED", sub = "WALKER VARIANT  •  4.95 STUDS", x = -75, z = 414, radius = 6.6, dist = 8.5, accent = Color3.fromRGB(190, 145, 235) },
    { id = "MaleRunner", type = "Zombie", title = "MALE RUNNER", sub = "FAST INFECTED  •  5.06 STUDS", x = -39, z = 442, radius = 6.6, dist = 8.5, accent = STUDIO_ACCENT_AMBER },
    { id = "FemaleRunner", type = "Zombie", title = "FEMALE RUNNER", sub = "FAST INFECTED  •  4.88 STUDS", x = -57, z = 442, radius = 6.6, dist = 8.5, accent = Color3.fromRGB(235, 145, 195) },
    { id = "MaleBoss", type = "Boss", title = "ABOMINATION BOSS", sub = "MUTATED MALE BOSS  •  9.00 STUDS", x = -75, z = 442, radius = 9.4, dist = 13.5, accent = STUDIO_ACCENT_RED },
}

for _, spec in ipairs(characterDisplays) do
    local plinthModel = Instance.new("Model")
    plinthModel.Name = "Display_" .. spec.id
    plinthModel.Parent = charGallery

    local plinthH = 0.85
    local plinthTopY = 1.0 + plinthH
    local base = part(plinthModel, "PlinthBase", Vector3.new(spec.radius, plinthH, spec.radius),
        CFrame.new(spec.x, 1.0 + plinthH * 0.5, spec.z), STUDIO_PLINTH_COLOR, Enum.Material.SmoothPlastic)
    part(plinthModel, "PlinthDeck", Vector3.new(spec.radius - 0.5, 0.14, spec.radius - 0.5),
        CFrame.new(spec.x, plinthTopY + 0.07, spec.z), STUDIO_PLINTH_TOP, Enum.Material.SmoothPlastic)
    part(plinthModel, "PlinthTrim", Vector3.new(spec.radius + 0.12, 0.10, spec.radius + 0.12),
        CFrame.new(spec.x, 1.10, spec.z), spec.accent, Enum.Material.Neon, true, false)

    -- Angled front studio nameplate
    local signBoard = part(plinthModel, "Nameplate", Vector3.new(spec.radius * 0.86, 1.25, 0.22),
        CFrame.new(spec.x, 1.48, spec.z - spec.radius * 0.5 - 0.35) * CFrame.Angles(math.rad(-28), 0, 0),
        Color3.fromRGB(16, 19, 24), Enum.Material.SmoothPlastic, true, false)
    addPlaqueGui(signBoard, Enum.NormalId.Front, spec.title, spec.sub, spec.accent)

    local groundPos = Vector3.new(spec.x, plinthTopY + 0.14, spec.z)
    local charModel, targetFocusY
    if spec.type == "Player" then
        charModel = buildPlayerR15Model(nil, groundPos, 180)
        charModel.Parent = plinthModel
        targetFocusY = groundPos.Y + 2.85
    else
        local arch = ZombieCatalog.get(spec.id)
        local rig = ZombieModelFactory.build({
            zombieType = arch.Id,
            groundPos = groundPos,
            facingDeg = 180,
            anchored = true,
            anchorRootOnly = true,
            canCollideMain = false,
            modelName = "Showcase_" .. arch.Id,
        })
        charModel = rig.model
        charModel.Parent = plinthModel
        targetFocusY = groundPos.Y + (arch.TargetHeight * 0.54)
        for _, d in ipairs(charModel:GetDescendants()) do
            if d:IsA("BasePart") then
                d.CanCollide = false
                d.CanTouch = false
                d.CanQuery = (d.Name ~= "HumanoidRootPart")
            end
        end
    end

    setFocusMetadata(plinthModel, Vector3.new(spec.x, targetFocusY, spec.z), spec.dist, spec.title, spec.type)
    plinthModel:SetAttribute("AssetId", spec.id)

    -- Dedicated studio inspection prompt (press [E] to open Camera Orbit directly on this model)
    local inspectPrompt = Instance.new("ProximityPrompt")
    inspectPrompt.Name = "StudioInspectPrompt"
    inspectPrompt.ActionText = "Inspect 3D Model"
    inspectPrompt.ObjectText = spec.title
    inspectPrompt.KeyboardKeyCode = Enum.KeyCode.F
    inspectPrompt.HoldDuration = 0
    inspectPrompt.MaxActivationDistance = 9
    inspectPrompt.RequiresLineOfSight = false
    inspectPrompt:SetAttribute("ShowcaseKind", "Character")
    inspectPrompt:SetAttribute("ShowcaseAssetId", spec.id)
    inspectPrompt.Parent = base
end

----------------------------------------------------------------------
-- 3. ZONE B — WEAPON SHOWCASE GALLERY (All 18 Weapons @ 1:1 Scale)
----------------------------------------------------------------------
local weaponGallery = Instance.new("Folder")
weaponGallery.Name = "WeaponShowcaseGallery"
weaponGallery.Parent = range

buildZoneHeader(weaponGallery, "Header_WeaponGallery", Vector3.new(58, 11.5, 458), Vector3.new(58, 11.5, 420),
    "WEAPON EXHIBITION GALLERY", "18 WEAPONS @ 1:1 SCALE  •  [E] EQUIP  •  [F] ORBIT INSPECT", STUDIO_ACCENT_AMBER)

local weaponAttachmentNotes = {
    Classic = "Iron Sights • 3-Round Alternate",
    Shorty = "Sawed-Off • Break-Action Twin",
    Frenzy = "Full-Auto Machine Pistol",
    Ghost = "Suppressor Barrel • Precision Semi",
    Sheriff = "Heavy Revolver • 6-Shot Cylinder",
    Stinger = "Compact Reflex Sight • High ROF",
    Spectre = "Integrated Silencer • Reflex Optic",
    Bucky = "Pump-Action • Tube Fed",
    Judge = "Drum Auto-Shotgun • Foregrip",
    Bulldog = "Bullpup Frame • Holo Burst Optic",
    Guardian = "DMR Long Barrel • Precision Optic",
    Phantom = "Integrated Suppressor • Reflex Sight",
    Vandal = "Heavy Compensator • Reflex Optic",
    Marshal = "Lever-Action • Low-Zoom Sniper Optic",
    Outlaw = "Double-Barrel Break • Heavy Sniper Optic",
    Operator = "Bolt-Action • 26° High-Zoom Scope",
    Ares = "Belt-Fed Shroud • Spooling Barrel",
    Odin = "Heavy Box Feed • Compensated Barrel",
}

local weaponShowcaseOrder = {
    -- Row 1 (X = +36): Sidearms + Stinger
    { name = "Classic", x = 36, z = 408 },
    { name = "Shorty", x = 36, z = 417 },
    { name = "Frenzy", x = 36, z = 426 },
    { name = "Ghost", x = 36, z = 435 },
    { name = "Sheriff", x = 36, z = 444 },
    { name = "Stinger", x = 36, z = 453 },
    -- Row 2 (X = +58): Spectre + Shotguns + Bulldog/Guardian/Phantom
    { name = "Spectre", x = 58, z = 408 },
    { name = "Bucky", x = 58, z = 417 },
    { name = "Judge", x = 58, z = 426 },
    { name = "Bulldog", x = 58, z = 435 },
    { name = "Guardian", x = 58, z = 444 },
    { name = "Phantom", x = 58, z = 453 },
    -- Row 3 (X = +80): Vandal + Snipers + Heavy
    { name = "Vandal", x = 80, z = 408 },
    { name = "Marshal", x = 80, z = 417 },
    { name = "Outlaw", x = 80, z = 426 },
    { name = "Operator", x = 80, z = 435 },
    { name = "Ares", x = 80, z = 444 },
    { name = "Odin", x = 80, z = 453 },
}

for _, entry in ipairs(weaponShowcaseOrder) do
    local wName = entry.name
    local wCfg = WeaponRegistry.get(wName)
    local stand = Instance.new("Model")
    stand.Name = "Pickup_" .. wName
    stand.Parent = weaponGallery

    local pedH = 2.0
    local topY = 1.0 + pedH
    local base = part(stand, "DisplayPedestal", Vector3.new(5.4, pedH, 6.8),
        CFrame.new(entry.x, 1.0 + pedH * 0.5, entry.z), STUDIO_PLINTH_COLOR, Enum.Material.SmoothPlastic)
    local matColor = Color3.fromRGB(70, 76, 88)
    part(stand, "DisplayPad", Vector3.new(4.8, 0.12, 6.2),
        CFrame.new(entry.x, topY + 0.06, entry.z), matColor, Enum.Material.SmoothPlastic)
    part(stand, "DisplayCradle", Vector3.new(1.1, 0.22, 3.6),
        CFrame.new(entry.x, topY + 0.23, entry.z), Color3.fromRGB(94, 102, 118), Enum.Material.SmoothPlastic)

    -- Angled crisp nameplate facing the walking aisle (-X direction)
    local catText = wCfg and string.format("%s • %s", (wCfg.Category or wCfg.Type or "Weapon"):upper(), (wCfg.FiringType or "Semi"):upper()) or "WEAPON"
    local noteText = weaponAttachmentNotes[wName] or catText
    local plaque = part(stand, "WeaponPlaque", Vector3.new(0.22, 1.05, 5.2),
        CFrame.new(entry.x - 2.95, 2.35, entry.z) * CFrame.Angles(0, 0, math.rad(28)),
        Color3.fromRGB(16, 19, 24), Enum.Material.SmoothPlastic, true, false)
    addPlaqueGui(plaque, Enum.NormalId.Left, wName:upper(), noteText, STUDIO_ACCENT_AMBER)

    -- Display at 1:1 realistic in-game proportions (tilt slightly toward viewer aisle)
    local gunMountCF = CFrame.new(entry.x, topY + 0.42, entry.z) * CFrame.Angles(0, 0, math.rad(16))
    WeaponModelBuilder.buildDisplayModel(stand, wCfg, gunMountCF, {
        anchorMode = "BottomCenter",
        scale = 1.0,
        castShadow = true,
    })

    setFocusMetadata(stand, Vector3.new(entry.x, topY + 0.85, entry.z), 4.6, wName:upper(), wCfg and wCfg.Category or "Weapons")
    stand:SetAttribute("AssetId", wName)

    -- Preserve server PickupPrompt cleanly ([E] Equip)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "PickupPrompt"
    prompt.ActionText = "Equip Weapon"
    prompt.ObjectText = wName
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 6.2
    prompt.RequiresLineOfSight = false
    prompt.Parent = base

    -- Studio Inspect Prompt ([F] Orbit Inspect in Showcase UI)
    local inspectPrompt = Instance.new("ProximityPrompt")
    inspectPrompt.Name = "StudioInspectPrompt"
    inspectPrompt.ActionText = "Inspect Weapon 3D"
    inspectPrompt.ObjectText = wName:upper()
    inspectPrompt.KeyboardKeyCode = Enum.KeyCode.F
    inspectPrompt.HoldDuration = 0
    inspectPrompt.MaxActivationDistance = 6.2
    inspectPrompt.RequiresLineOfSight = false
    inspectPrompt:SetAttribute("ShowcaseKind", "Weapon")
    inspectPrompt:SetAttribute("ShowcaseAssetId", wName)
    inspectPrompt.Parent = base
end

----------------------------------------------------------------------
-- 4. ZONE C — HERO ANIMATION PREVIEW STAGE (Center Studio Turntable)
----------------------------------------------------------------------
local animStageFolder = Instance.new("Model")
animStageFolder.Name = "AnimationPreviewStage"
animStageFolder.Parent = range

local STAGE_CENTER = Vector3.new(0, 1.0, 428)
local STAGE_TOP_Y = 1.85

part(animStageFolder, "StageBase", Vector3.new(20, 0.85, 20),
    CFrame.new(STAGE_CENTER.X, 1.425, STAGE_CENTER.Z), STUDIO_PLINTH_COLOR, Enum.Material.SmoothPlastic, true, true, Enum.PartType.Cylinder)
-- Rotate cylinder flat upright
animStageFolder.StageBase.Size = Vector3.new(0.85, 20, 20)
animStageFolder.StageBase.CFrame = CFrame.new(STAGE_CENTER.X, 1.425, STAGE_CENTER.Z) * CFrame.Angles(0, 0, math.rad(90))

local stageTop = part(animStageFolder, "StageSurface", Vector3.new(0.12, 18.6, 18.6),
    CFrame.new(STAGE_CENTER.X, 1.85, STAGE_CENTER.Z) * CFrame.Angles(0, 0, math.rad(90)),
    STUDIO_PLINTH_TOP, Enum.Material.SmoothPlastic, true, true, Enum.PartType.Cylinder)
local stageRing = part(animStageFolder, "StageTrim", Vector3.new(0.08, 19.2, 19.2),
    CFrame.new(STAGE_CENTER.X, 1.80, STAGE_CENTER.Z) * CFrame.Angles(0, 0, math.rad(90)),
    STUDIO_ACCENT_BLUE, Enum.Material.Neon, true, false, Enum.PartType.Cylinder)

-- Height scale backdrop behind Stage (1M / 2M / 3M)
local SCALE_WALL_Z = 440
part(animStageFolder, "StageScaleBackdrop", Vector3.new(18, 12.5, 0.8),
    CFrame.new(0, 7.25, SCALE_WALL_Z), Color3.fromRGB(38, 43, 52), Enum.Material.SmoothPlastic)
for _, h in ipairs({ { studs = 3.57, label = "1M" }, { studs = 7.14, label = "2M" }, { studs = 10.71, label = "3M" } }) do
    part(animStageFolder, "ScaleRule_" .. h.label, Vector3.new(17.2, 0.08, 0.10),
        CFrame.new(0, STAGE_TOP_Y + h.studs, SCALE_WALL_Z - 0.44), STUDIO_TEXT_MUTED, Enum.Material.SmoothPlastic, true, false)
end

buildZoneHeader(animStageFolder, "Header_AnimStage", Vector3.new(0, 12.6, SCALE_WALL_Z - 0.5), Vector3.new(0, 12.6, 395),
    "ANIMATION PREVIEW STAGE", "SELECT MODEL & ANIMATION IN STUDIO [V]  •  [F] STAGE FOCUS", STUDIO_ACCENT_BLUE)

local stagePrompt = Instance.new("ProximityPrompt")
stagePrompt.Name = "StudioInspectPrompt"
stagePrompt.ActionText = "Open Animation Stage Studio"
stagePrompt.ObjectText = "Animation Preview Stage"
stagePrompt.KeyboardKeyCode = Enum.KeyCode.F
stagePrompt.HoldDuration = 0
stagePrompt.MaxActivationDistance = 13
stagePrompt.RequiresLineOfSight = false
stagePrompt:SetAttribute("ShowcaseKind", "Stage")
stagePrompt.Parent = stageTop

local heroMount = Instance.new("Folder")
heroMount.Name = "ActiveHeroRig"
heroMount.Parent = animStageFolder

----------------------------------------------------------------------
-- 5. ZONE E — WEAPON ANIMATION PREVIEW BAY (Center Forward Studio Pad)
----------------------------------------------------------------------
local weaponBay = Instance.new("Model")
weaponBay.Name = "WeaponAnimPreviewBay"
weaponBay.Parent = range

local WEAPON_BAY_POS = Vector3.new(0, 1.0, 456)
part(weaponBay, "WeaponBayPad", Vector3.new(14, 0.5, 11),
    CFrame.new(WEAPON_BAY_POS.X, 1.25, WEAPON_BAY_POS.Z), STUDIO_PLINTH_COLOR, Enum.Material.SmoothPlastic)
part(weaponBay, "WeaponBayTop", Vector3.new(13.4, 0.08, 10.4),
    CFrame.new(WEAPON_BAY_POS.X, 1.54, WEAPON_BAY_POS.Z), STUDIO_PLINTH_TOP, Enum.Material.SmoothPlastic)
part(weaponBay, "WeaponBayTrim", Vector3.new(14.1, 0.06, 11.1),
    CFrame.new(WEAPON_BAY_POS.X, 1.04, WEAPON_BAY_POS.Z), STUDIO_ACCENT_AMBER, Enum.Material.Neon, true, false)

local weaponBayPrompt = Instance.new("ProximityPrompt")
weaponBayPrompt.Name = "StudioInspectPrompt"
weaponBayPrompt.ActionText = "Open Weapon Anim Lab"
weaponBayPrompt.ObjectText = "1P / 3P Weapon Animation Preview"
weaponBayPrompt.KeyboardKeyCode = Enum.KeyCode.F
weaponBayPrompt.HoldDuration = 0
weaponBayPrompt.MaxActivationDistance = 10
weaponBayPrompt.RequiresLineOfSight = false
weaponBayPrompt:SetAttribute("ShowcaseKind", "WeaponAnim")
weaponBayPrompt.Parent = weaponBay.WeaponBayTop

----------------------------------------------------------------------
-- 6. ZONE D — MOVEMENT TESTING AREA (Runway, Slalom, Jump/Slide Frames)
----------------------------------------------------------------------
local movementZone = Instance.new("Model")
movementZone.Name = "MovementTestingArea"
movementZone.Parent = range

buildZoneHeader(movementZone, "Header_Movement", Vector3.new(0, 11.5, 547), Vector3.new(0, 11.5, 480),
    "MOVEMENT & TRANSITION TESTING TRACK", "WALK / RUN / SPRINT / SLIDE / TURN CALIBRATION", STUDIO_ACCENT_BLUE)

-- 80-stud straight calibration runway (X = -40..+40, Z = 486..498)
part(movementZone, "SpeedRunway", Vector3.new(84, 0.06, 12),
    CFrame.new(0, 1.04, 492), Color3.fromRGB(46, 52, 64), Enum.Material.SmoothPlastic, true, false)

for idx = 0, 8 do
    local xTick = -40 + idx * 10
    part(movementZone, "RunwayTick_" .. idx, Vector3.new(0.25, 0.07, 12),
        CFrame.new(xTick, 1.05, 492), Color3.fromRGB(165, 180, 200), Enum.Material.SmoothPlastic, true, false)
    local markPad = part(movementZone, "RunwayMark_" .. idx, Vector3.new(3.2, 0.06, 1.8),
        CFrame.new(xTick, 1.055, 485), Color3.fromRGB(16, 19, 24), Enum.Material.SmoothPlastic, true, false)
    addPlaqueGui(markPad, Enum.NormalId.Top, string.format("%dM", idx * 3), "CALIBRATION", STUDIO_ACCENT_BLUE)
end

-- Slalom / Sharp Turn Testing Pylons (Z = 510..526)
for idx = 1, 7 do
    local px = -30 + (idx - 1) * 10
    local pz = (idx % 2 == 1) and 512 or 522
    part(movementZone, "SlalomPylon_" .. idx, Vector3.new(1.2, 5.2, 1.2),
        CFrame.new(px, 3.6, pz), Color3.fromRGB(58, 66, 80), Enum.Material.SmoothPlastic)
    part(movementZone, "SlalomCap_" .. idx, Vector3.new(1.3, 0.35, 1.3),
        CFrame.new(px, 6.2, pz), STUDIO_ACCENT_AMBER, Enum.Material.Neon, true, false)
end

-- Step-up / Jump Height Blocks (left side X = -58..-48, Z = 516..534)
for idx, h in ipairs({ 1.5, 2.5, 3.5 }) do
    local bx = -58
    local bz = 512 + (idx - 1) * 9
    part(movementZone, "JumpBlock_" .. idx, Vector3.new(7, h, 5.5),
        CFrame.new(bx, 1.0 + h * 0.5, bz), STUDIO_PLINTH_COLOR, Enum.Material.SmoothPlastic)
end

-- Slide / Crouch Overhead Clearance Arch (right side X = +56, Z = 520, clearance 3.8 studs)
part(movementZone, "SlideArchLeft", Vector3.new(1.0, 5.5, 1.2), CFrame.new(51, 3.75, 520), STUDIO_PLINTH_COLOR)
part(movementZone, "SlideArchRight", Vector3.new(1.0, 5.5, 1.2), CFrame.new(61, 3.75, 520), STUDIO_PLINTH_COLOR)
part(movementZone, "SlideArchBeam", Vector3.new(11.0, 1.2, 1.2), CFrame.new(56, 5.4, 520), STUDIO_ACCENT_BLUE)

local patrolFolder = Instance.new("Folder")
patrolFolder.Name = "MovementPatrolBot"
patrolFolder.Parent = movementZone

----------------------------------------------------------------------
-- Server Hero Animation Stage & Movement Patrol Controller
----------------------------------------------------------------------
local activeHero = {
    assetId = nil,
    model = nil,
    animCtrl = nil,
    audioCtrl = nil,
}

local activePatrol = {
    running = false,
    model = nil,
    animCtrl = nil,
    token = 0,
}

local function destroyHero()
    if activeHero.animCtrl then
        activeHero.animCtrl:destroy()
        activeHero.animCtrl = nil
    end
    if activeHero.audioCtrl then
        activeHero.audioCtrl:destroy()
        activeHero.audioCtrl = nil
    end
    if activeHero.model and activeHero.model.Parent then
        activeHero.model:Destroy()
    end
    activeHero.model = nil
    activeHero.assetId = nil
end

local function spawnHeroOnStage(assetId, requestingPlayer)
    destroyHero()
    activeHero.assetId = assetId

    local groundPos = Vector3.new(STAGE_CENTER.X, STAGE_TOP_Y, STAGE_CENTER.Z)
    if assetId == "PlayerR15" then
        local model = buildPlayerR15Model(requestingPlayer, groundPos, 180)
        model.Parent = heroMount
        activeHero.model = model
        stageStateEvent:FireAllClients({
            kind = "HeroSpawned",
            assetId = assetId,
            isZombie = false,
            state = "Idle",
            paused = false,
            speed = 1.0,
        })
        return
    end

    local arch = ZombieCatalog.get(assetId)
    local rig = ZombieModelFactory.build({
        zombieType = arch.Id,
        groundPos = groundPos,
        facingDeg = 180,
        anchored = true,
        anchorRootOnly = true,
        canCollideMain = false,
        modelName = "StageHero_" .. arch.Id,
    })
    rig.model.Parent = heroMount
    for _, d in ipairs(rig.model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.CanCollide = false
            d.CanTouch = false
            d.CanQuery = (d.Name ~= "HumanoidRootPart")
        end
    end

    local animCtrl = ZombieAnimationController.new(rig, arch)
    animCtrl:setPreviewMode(true)
    animCtrl:setPreviewPlayback({ state = "Idle", paused = false, speed = 1.0, loop = true })

    local audioCtrl = ZombieAudioController.new(rig, arch)

    activeHero.model = rig.model
    activeHero.animCtrl = animCtrl
    activeHero.audioCtrl = audioCtrl

    stageStateEvent:FireAllClients({
        kind = "HeroSpawned",
        assetId = arch.Id,
        isZombie = true,
        state = "Idle",
        paused = false,
        speed = 1.0,
    })
end

local function stopPatrolBot()
    activePatrol.token = activePatrol.token + 1
    activePatrol.running = false
    if activePatrol.animCtrl then
        activePatrol.animCtrl:destroy()
        activePatrol.animCtrl = nil
    end
    if activePatrol.model and activePatrol.model.Parent then
        activePatrol.model:Destroy()
    end
    activePatrol.model = nil
end

local function startPatrolBot(assetId, modeName)
    stopPatrolBot()
    local token = activePatrol.token
    activePatrol.running = true

    local arch = ZombieCatalog.get(assetId or "MaleWalker")
    local rig = ZombieModelFactory.build({
        zombieType = arch.Id,
        groundPos = Vector3.new(-36, 1.05, 492),
        facingDeg = -90,
        anchored = false,
        canCollideMain = true,
        modelName = "MovementTester_" .. arch.Id,
    })
    rig.model.Parent = patrolFolder
    pcall(function()
        rig.hrp:SetNetworkOwner(nil)
    end)

    local targetSpeed = arch.WalkSpeed
    local chasing = false
    if modeName == "Run" then
        targetSpeed = arch.RunSpeed or (arch.WalkSpeed * 1.18)
    elseif modeName == "Sprint" or modeName == "Chase" then
        targetSpeed = arch.ChaseSpeed or (arch.WalkSpeed * 1.32)
        chasing = true
    end
    rig.humanoid.WalkSpeed = targetSpeed
    rig.model:SetAttribute("IsChasing", chasing)

    local animCtrl = ZombieAnimationController.new(rig, arch)
    activePatrol.model = rig.model
    activePatrol.animCtrl = animCtrl

    task.spawn(function()
        local waypoints = {
            Vector3.new(36, 1.05, 492),
            Vector3.new(-36, 1.05, 492),
        }
        local wpIdx = 1
        while activePatrol.running and activePatrol.token == token and rig.model.Parent do
            local targetPos = waypoints[wpIdx]
            rig.humanoid:MoveTo(targetPos)
            local dist = (Vector3.new(rig.hrp.Position.X, 0, rig.hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
            if dist < 3.0 then
                task.wait(0.35)
                wpIdx = (wpIdx % #waypoints) + 1
            else
                task.wait(0.15)
            end
        end
    end)
end

-- Spawn default hero MaleWalker cleanly at startup
spawnHeroOnStage("MaleWalker", nil)

local function isPlayerInsideRangeBounds(player)
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local floor = range:FindFirstChild("RangeFloor")
    if not root or not floor then return false end
    local localPos = floor.CFrame:PointToObjectSpace(root.Position)
    return math.abs(localPos.X) <= floor.Size.X / 2
        and math.abs(localPos.Z) <= floor.Size.Z / 2
        and math.abs(localPos.Y) <= 28
end

local VALID_HERO_IDS = {
    PlayerR15 = true,
    MaleWalker = true,
    FemaleWalker = true,
    MaleRunner = true,
    FemaleRunner = true,
    MaleBoss = true,
}

local VALID_PATROL_MODES = {
    Walk = true,
    Run = true,
    Chase = true,
    Sprint = true,
}

local VALID_ANIM_STATES = {}
for _, stateName in ipairs(ZombieCatalog.ANIMATION_STATES) do
    VALID_ANIM_STATES[stateName] = true
end

local lastStageActionByPlayer = {}

stageControlEvent.OnServerEvent:Connect(function(player, payload)
    if type(payload) ~= "table" or not devAuth.isDevModeEnabled(player) or not isPlayerInsideRangeBounds(player) then
        return
    end
    local now = os.clock()
    if (lastStageActionByPlayer[player] or 0) + 0.12 > now then
        return
    end
    lastStageActionByPlayer[player] = now

    local action = payload.action
    if action == "SpawnHero" and type(payload.assetId) == "string" and VALID_HERO_IDS[payload.assetId] then
        spawnHeroOnStage(payload.assetId, player)
    elseif action == "Playback" and activeHero.animCtrl then
        local ctrl = activeHero.animCtrl
        local reqState = (type(payload.state) == "string" and VALID_ANIM_STATES[payload.state]) and payload.state or nil
        local reqSpeed = (type(payload.speed) == "number") and math.clamp(payload.speed, 0.1, 3.0) or nil
        ctrl:setPreviewPlayback({
            state = reqState,
            paused = (type(payload.paused) == "boolean") and payload.paused or nil,
            speed = reqSpeed,
            loop = (type(payload.loop) == "boolean") and payload.loop or nil,
            restart = (payload.restart == true),
            isHeadshot = (payload.isHeadshot == true),
        })
        if activeHero.audioCtrl and reqState then
            if reqState == "Attacking" or reqState == "TakingDamage" or reqState == "Death" then
                activeHero.audioCtrl:triggerEvent(reqState)
            end
        end
        stageStateEvent:FireAllClients({
            kind = "PlaybackUpdated",
            assetId = activeHero.assetId,
            state = ctrl.state,
            paused = ctrl.previewPaused,
            speed = ctrl.previewSpeed,
        })
    elseif action == "ResetPose" and activeHero.animCtrl then
        activeHero.animCtrl:setPreviewPlayback({
            state = "Idle",
            paused = false,
            speed = 1.0,
            restart = true,
        })
        stageStateEvent:FireAllClients({
            kind = "PlaybackUpdated",
            assetId = activeHero.assetId,
            state = "Idle",
            paused = false,
            speed = 1.0,
        })
    elseif action == "StartPatrol" then
        local zId = (type(payload.assetId) == "string" and VALID_HERO_IDS[payload.assetId] and payload.assetId ~= "PlayerR15")
            and payload.assetId or "MaleWalker"
        local spdMode = (type(payload.speedMode) == "string" and VALID_PATROL_MODES[payload.speedMode])
            and payload.speedMode or "Walk"
        startPatrolBot(zId, spdMode)
    elseif action == "StopPatrol" then
        stopPatrolBot()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    lastStageActionByPlayer[player] = nil
end)

----------------------------------------------------------------------
-- 7. Spawn Location & Preserved Teleportation System
----------------------------------------------------------------------
local rangeSpawn = Instance.new("SpawnLocation")
rangeSpawn.Name = "TestRangeSpawnLocation"
rangeSpawn.Size = Vector3.new(12, 0.5, 12)
rangeSpawn.CFrame = CFrame.lookAt(Vector3.new(0, 1.25, 395), Vector3.new(0, 1.25, 432))
rangeSpawn.Color = Color3.fromRGB(0, 210, 160)
rangeSpawn.Material = Enum.Material.Neon
rangeSpawn.Transparency = 0.45
rangeSpawn.Anchored = true
rangeSpawn.CanCollide = false
rangeSpawn.Enabled = false -- Campaign players spawn in Building 40 F1 Lobby; Dev Mode allows warping to TestRange
rangeSpawn.Parent = range

local TARGET_RANGE_CF = CFrame.lookAt(Vector3.new(0, 3.5, 395), Vector3.new(0, 3.5, 432))
local TARGET_LOBBY_CF = CFrame.lookAt(Vector3.new(0, 3.5, 15), Vector3.new(0, 3.5, 40))

local function safeTeleport(character, targetCFrame)
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = targetCFrame
    end
end

local function createTeleportPad(parent, name, cframe, targetCFrame, color, title, promptText)
    local pad = Instance.new("Part")
    pad.Name = name
    pad.Size = Vector3.new(7.5, 0.4, 7.5)
    pad.CFrame = cframe
    pad.Color = color
    pad.Material = Enum.Material.Neon
    pad.Anchored = true
    pad.CanCollide = true
    pad.Parent = parent

    local gui = Instance.new("BillboardGui")
    gui.Name = "TeleportLabel"
    gui.Size = UDim2.fromOffset(175, 42)
    gui.StudsOffset = Vector3.new(0, 2.8, 0)
    gui.AlwaysOnTop = false
    gui.MaxDistance = 42
    gui.Parent = pad

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(12, 17, 24)
    text.BackgroundTransparency = 0.15
    text.TextColor3 = Color3.fromRGB(245, 245, 245)
    text.TextStrokeTransparency = 0.6
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Text = title
    text.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = text

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "WarpPrompt"
    prompt.ActionText = promptText
    prompt.ObjectText = "Teleporter"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = pad

    local lastUsed = {}
    local function doWarp(player)
        if not player or not player.Character then return end
        if not devAuth.isDevModeEnabled(player) then return end
        local now = os.clock()
        if (lastUsed[player] or 0) + 1.2 > now then return end
        lastUsed[player] = now
        safeTeleport(player.Character, targetCFrame)
    end

    prompt.Triggered:Connect(doWarp)
    pad.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            doWarp(player)
        end
    end)

    return pad
end

createTeleportPad(range, "RangeToLobbyPad",
    CFrame.new(-14, 1.2, 392),
    TARGET_LOBBY_CF,
    Color3.fromRGB(255, 140, 0),
    "🏢 [DEV] RETURN TO BUILDING 40\nกลับตึก 40 ปี",
    "วาร์ปกลับตึก 40 ปี"
)

createTeleportPad(range, "LobbyToRangePad",
    CFrame.new(18, 1.3, 10),
    TARGET_RANGE_CF,
    Color3.fromRGB(0, 200, 255),
    "🎬 [DEV] 3D STUDIO & RANGE\nศูนย์ทดสอบ (!dev)",
    "วาร์ปไป 3D Studio Range"
)

createTeleportPad(range, "PlazaToRangePad",
    CFrame.new(18, 5.5, 130),
    TARGET_RANGE_CF,
    Color3.fromRGB(0, 200, 255),
    "🎬 [DEV] 3D STUDIO & RANGE\nศูนย์ทดสอบ (!dev)",
    "วาร์ปไป 3D Studio Range"
)

-- TeleportEvents.RequestTeleport and dev chat warps are managed exclusively by TeleportService.server.lua

print("[TestRange] Built 3D Model & Animation Showcase Studio (Dev-Mode gated).")
