--[[
    FPSController.client.lua
    KMUTNB Building 40 - Zombie Defense // Full Rigged Viewmodel & Valorant Arsenal
    
    คุณสมบัติหลัก:
      1. แขนนักศึกษา มจพ. (KMUTNB Student Arms): เสื้อเชิ้ตขาวแขนสั้น + ท่อนแขนและมือคนจริง
      2. คลังแสง VALORANT ครบทุกกระบอก (18 กระบอก) กด [B] เพื่อเปิดเมนูเลือกปืน
         - Sidearms: Classic, Shorty, Frenzy, Ghost, Sheriff
         - SMGs: Stinger, Spectre
         - Shotguns: Bucky, Judge
         - Rifles: Bulldog, Guardian, Phantom, Vandal
         - Snipers: Marshal, Outlaw, Operator
         - Heavy: Ares, Odin
      3. ระบบแอนิเมชัน COD Style:
         - Procedural Reload [R]: มือซ้ายปลดแม็กกาซีน เสียบแม็กใหม่ สับคันรั้งลูกเลื่อน
         - Mouse Look Sway: ปืนเอียงตามแรงเหวี่ยงเมาส์อย่างนุ่มนวล
         - Walk Bobbing: ปืนและแขนโยกตามจังหวะก้าวเดิน
         - Spring Recoil: แรงถีบปืนสะบัดสมจริงตามประเภทปืน
         - ADS เล็งศูนย์ประณีต / สไนเปอร์ซูมกล้อง Scope แบบสมจริง
      4. เสียงปืนระดับ Engine ไม่ติด Audio Privacy ดังชัดเจน 100%
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

player.CameraMode = Enum.CameraMode.LockFirstPerson

-- ระบบจัดการสถานะเมาส์ (Free Cursor vs LockCenter)
local isCursorFree = false

local function setCameraFrozen(frozen)
    if frozen then
        ContextActionService:BindActionAtPriority(
            "FreezeCameraForBuyMenu",
            function() return Enum.ContextActionResult.Sink end,
            false,
            Enum.ContextActionPriority.High.Value + 100,
            Enum.UserInputType.MouseMovement
        )
    else
        ContextActionService:UnbindAction("FreezeCameraForBuyMenu")
    end
end

-- Remote Events
local zombieEvents = ReplicatedStorage:WaitForChild("ZombieGameEvents", 25)
local zombieHitEvent = zombieEvents:WaitForChild("ZombieHitEvent", 25)

----------------------------------------------------------------------
-- 1. ฐานข้อมูลคลังแสงปืน VALORANT ARSENAL DATABASE (18 WEAPONS)
----------------------------------------------------------------------
local VALORANT_ARSENAL = {
    -- Sidearms (ปืนพก)
    Classic = {
        Name = "CLASSIC", Category = "Sidearms", Mag = 12, Reserve = 120,
        FireRate = 0.15, FiringType = "Semi", HeadDmg = 78, BodyDmg = 26,
        SoundPitch = 2.8, Recoil = 2.8, Type = "Pistol",
        PrimaryColor = Color3.fromRGB(40, 42, 48), AccentColor = Color3.fromRGB(180, 185, 195)
    },
    Shorty = {
        Name = "SHORTY", Category = "Sidearms", Mag = 2, Reserve = 40,
        FireRate = 0.30, FiringType = "Shotgun", Pellets = 10, HeadDmg = 36, BodyDmg = 12,
        SoundPitch = 2.1, Recoil = 5.5, Type = "Pistol",
        PrimaryColor = Color3.fromRGB(60, 45, 35), AccentColor = Color3.fromRGB(30, 30, 35)
    },
    Frenzy = {
        Name = "FRENZY", Category = "Sidearms", Mag = 13, Reserve = 90,
        FireRate = 0.10, FiringType = "Auto", HeadDmg = 78, BodyDmg = 26,
        SoundPitch = 2.9, Recoil = 3.2, Type = "Pistol",
        PrimaryColor = Color3.fromRGB(35, 38, 45), AccentColor = Color3.fromRGB(240, 180, 40)
    },
    Ghost = {
        Name = "GHOST", Category = "Sidearms", Mag = 15, Reserve = 90,
        FireRate = 0.15, FiringType = "Semi", HeadDmg = 105, BodyDmg = 30,
        SoundPitch = 3.4, Recoil = 2.5, Silenced = true, Type = "Pistol",
        PrimaryColor = Color3.fromRGB(28, 30, 35), AccentColor = Color3.fromRGB(80, 120, 150)
    },
    Sheriff = {
        Name = "SHERIFF", Category = "Sidearms", Mag = 6, Reserve = 60,
        FireRate = 0.25, FiringType = "Semi", HeadDmg = 159, BodyDmg = 55,
        SoundPitch = 2.2, Recoil = 6.0, Type = "Revolver",
        PrimaryColor = Color3.fromRGB(160, 165, 175), AccentColor = Color3.fromRGB(110, 60, 30)
    },

    -- SMGs (ปืนกลมือ)
    Stinger = {
        Name = "STINGER", Category = "SMGs", Mag = 20, Reserve = 120,
        FireRate = 0.062, FiringType = "Auto", HeadDmg = 67, BodyDmg = 27,
        SoundPitch = 2.9, Recoil = 2.9, Type = "SMG",
        PrimaryColor = Color3.fromRGB(42, 45, 52), AccentColor = Color3.fromRGB(255, 120, 40)
    },
    Spectre = {
        Name = "SPECTRE", Category = "SMGs", Mag = 30, Reserve = 150,
        FireRate = 0.075, FiringType = "Auto", HeadDmg = 78, BodyDmg = 26,
        SoundPitch = 3.2, Recoil = 2.4, Silenced = true, Type = "SMG",
        PrimaryColor = Color3.fromRGB(30, 32, 38), AccentColor = Color3.fromRGB(60, 200, 220)
    },

    -- Shotguns (ปืนลูกซอง)
    Bucky = {
        Name = "BUCKY", Category = "Shotguns", Mag = 8, Reserve = 60,
        FireRate = 0.70, FiringType = "Shotgun", Pellets = 15, HeadDmg = 40, BodyDmg = 20,
        SoundPitch = 1.8, Recoil = 7.5, Type = "Shotgun",
        PrimaryColor = Color3.fromRGB(50, 52, 58), AccentColor = Color3.fromRGB(130, 70, 30)
    },
    Judge = {
        Name = "JUDGE", Category = "Shotguns", Mag = 7, Reserve = 60,
        FireRate = 0.28, FiringType = "Auto", Pellets = 12, HeadDmg = 34, BodyDmg = 17,
        SoundPitch = 1.9, Recoil = 6.2, Type = "Shotgun",
        PrimaryColor = Color3.fromRGB(40, 42, 46), AccentColor = Color3.fromRGB(230, 60, 60)
    },

    -- Rifles (ปืนไรเฟิลจู่โจม)
    Bulldog = {
        Name = "BULLDOG", Category = "Rifles", Mag = 24, Reserve = 120,
        FireRate = 0.105, FiringType = "Auto", HeadDmg = 115, BodyDmg = 35,
        SoundPitch = 2.4, Recoil = 3.6, Type = "Rifle",
        PrimaryColor = Color3.fromRGB(45, 48, 55), AccentColor = Color3.fromRGB(100, 180, 100)
    },
    Guardian = {
        Name = "GUARDIAN", Category = "Rifles", Mag = 12, Reserve = 90,
        FireRate = 0.19, FiringType = "Semi", HeadDmg = 195, BodyDmg = 65,
        SoundPitch = 2.2, Recoil = 5.2, Type = "Rifle",
        PrimaryColor = Color3.fromRGB(55, 58, 65), AccentColor = Color3.fromRGB(220, 200, 100)
    },
    Phantom = {
        Name = "PHANTOM", Category = "Rifles", Mag = 30, Reserve = 150,
        FireRate = 0.09, FiringType = "Auto", HeadDmg = 156, BodyDmg = 39,
        SoundPitch = 3.1, Recoil = 3.2, Silenced = true, Type = "Rifle",
        PrimaryColor = Color3.fromRGB(25, 27, 32), AccentColor = Color3.fromRGB(0, 220, 255)
    },
    Vandal = {
        Name = "VANDAL", Category = "Rifles", Mag = 25, Reserve = 125,
        FireRate = 0.103, FiringType = "Auto", HeadDmg = 160, BodyDmg = 40,
        SoundPitch = 2.3, Recoil = 4.2, Type = "Rifle",
        PrimaryColor = Color3.fromRGB(35, 38, 44), AccentColor = Color3.fromRGB(255, 120, 30)
    },

    -- Sniper Rifles (ปืนสไนเปอร์)
    Marshal = {
        Name = "MARSHAL", Category = "Snipers", Mag = 5, Reserve = 40,
        FireRate = 0.65, FiringType = "Semi", HeadDmg = 202, BodyDmg = 101,
        SoundPitch = 2.1, Recoil = 6.5, IsSniper = true, Type = "Sniper",
        PrimaryColor = Color3.fromRGB(50, 45, 40), AccentColor = Color3.fromRGB(180, 140, 80)
    },
    Outlaw = {
        Name = "OUTLAW", Category = "Snipers", Mag = 2, Reserve = 30,
        FireRate = 0.40, FiringType = "Semi", HeadDmg = 238, BodyDmg = 140,
        SoundPitch = 1.9, Recoil = 7.8, IsSniper = true, Type = "Sniper",
        PrimaryColor = Color3.fromRGB(45, 48, 52), AccentColor = Color3.fromRGB(255, 60, 60)
    },
    Operator = {
        Name = "OPERATOR", Category = "Snipers", Mag = 5, Reserve = 30,
        FireRate = 1.25, FiringType = "Semi", HeadDmg = 255, BodyDmg = 150,
        SoundPitch = 1.6, Recoil = 9.0, IsSniper = true, Type = "Sniper",
        PrimaryColor = Color3.fromRGB(30, 32, 38), AccentColor = Color3.fromRGB(240, 50, 70)
    },

    -- Heavy (ปืนกลหนัก)
    Ares = {
        Name = "ARES", Category = "Heavy", Mag = 50, Reserve = 150,
        FireRate = 0.085, FiringType = "Auto", HeadDmg = 72, BodyDmg = 30,
        SoundPitch = 2.4, Recoil = 3.5, Type = "Heavy",
        PrimaryColor = Color3.fromRGB(48, 50, 56), AccentColor = Color3.fromRGB(220, 160, 40)
    },
    Odin = {
        Name = "ODIN", Category = "Heavy", Mag = 100, Reserve = 200,
        FireRate = 0.07, FiringType = "Auto", HeadDmg = 95, BodyDmg = 38,
        SoundPitch = 2.2, Recoil = 4.0, Type = "Heavy",
        PrimaryColor = Color3.fromRGB(38, 40, 45), AccentColor = Color3.fromRGB(255, 80, 50)
    }
}

----------------------------------------------------------------------
-- 2. ตัวแปรสถานะอาวุธปัจจุบัน (ACTIVE WEAPON STATE)
----------------------------------------------------------------------
local currentWeaponKey = "Vandal"
local currentWeapon = VALORANT_ARSENAL[currentWeaponKey]
local clipAmmo = currentWeapon.Mag
local reserveAmmo = currentWeapon.Reserve

local isAiming = false
local isReloading = false
local isMouseDown = false
local lastShotTime = 0

-- สปริงและมุมกล้อง
local currentOffset = CFrame.new(0.60, -0.55, -1.35)
local recoilZ = 0
local recoilRotX = 0
local recoilRotY = 0
local swayTimer = 0
local mouseSwayX = 0
local mouseSwayY = 0

-- Reload Animation Timer
local reloadTimeTotal = 2.0
local reloadTimer = 0

----------------------------------------------------------------------
-- 3. เสียงปืนระดับ ENGINE (GUARANTEED NO-MUTE AUDIO)
----------------------------------------------------------------------
local soundFolder = camera:FindFirstChild("GunSounds") or Instance.new("Folder")
soundFolder.Name = "GunSounds"
soundFolder.Parent = camera

local soundGunshot = Instance.new("Sound")
soundGunshot.Name = "GunshotEngine"
soundGunshot.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
soundGunshot.Volume = 1.0
soundGunshot.Parent = soundFolder

local soundClick = Instance.new("Sound")
soundClick.Name = "ClickSound"
soundClick.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
soundClick.PlaybackSpeed = 3.2
soundClick.Volume = 0.6
soundClick.Parent = soundFolder

local function playWeaponFireSound()
    local s = soundGunshot:Clone()
    local pitch = currentWeapon.SoundPitch or 2.4
    s.PlaybackSpeed = pitch + (math.random() - 0.5) * 0.15
    s.Volume = currentWeapon.Silenced and 0.55 or 1.15
    s.Parent = camera
    s:Play()
    Debris:AddItem(s, 0.6)
end

local function playClickSound(speed)
    local c = soundClick:Clone()
    c.PlaybackSpeed = speed or 2.8
    c.Parent = camera
    c:Play()
    Debris:AddItem(c, 0.5)
end

local function playHitSound(isHeadshot)
    local h = Instance.new("Sound")
    h.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
    h.Volume = isHeadshot and 0.85 or 0.35
    h.PlaybackSpeed = isHeadshot and 4.2 or 3.2
    h.Parent = camera
    h:Play()
    Debris:AddItem(h, 0.4)
end

----------------------------------------------------------------------
-- 4. ระบบ VIEWMODEL: แขนนักศึกษา มจพ. + โมเดลปืน (KMUTNB ARMS RIG)
----------------------------------------------------------------------
local viewmodel = camera:FindFirstChild("Valorant_ViewModel") or Instance.new("Model")
viewmodel.Name = "Valorant_ViewModel"
viewmodel.Parent = camera

local gunRoot = Instance.new("Part")
gunRoot.Name = "GunRoot"
gunRoot.Size = Vector3.new(0.2, 0.2, 0.2)
gunRoot.Transparency = 1
gunRoot.CanCollide = false
gunRoot.Anchored = true
gunRoot.Parent = viewmodel

local rigParts = {}
local leftArmParts = {} -- ชิ้นส่วนแขนซ้ายสำหรับแอนิเมชันรีโหลด
local muzzleFlashPart = nil
local flashLight = nil

local function clearModel()
    for p, _ in pairs(rigParts) do
        if p and p.Parent then p:Destroy() end
    end
    rigParts = {}
    leftArmParts = {}
    muzzleFlashPart = nil
    flashLight = nil
end

-- ฟังก์ชันสร้างชิ้นส่วน Viewmodel
local function createRigPart(name, size, color, material, relCF, isLeftArm)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = material
    p.CanCollide = false
    p.Anchored = true
    p.CastShadow = false
    p.Parent = viewmodel

    rigParts[p] = relCF
    if isLeftArm then
        leftArmParts[p] = relCF
    end
    return p
end

-- สร้างแขนและปืนสำหรับอาวุธปัจจุบัน
local function buildCurrentViewmodel()
    clearModel()

    local wData = currentWeapon
    local isPistol = (wData.Type == "Pistol" or wData.Type == "Revolver")
    local skinColor = Color3.fromRGB(228, 186, 155) -- ผิวนักศึกษาไทย
    local shirtWhite = Color3.fromRGB(246, 248, 252) -- เสื้อเชิ้ตขาว มจพ.
    local shirtCuff = Color3.fromRGB(220, 224, 232)

    ------------------------------------------------------------------
    -- A. แขนขวา (Right Arm - ถือด้ามปืน)
    ------------------------------------------------------------------
    -- แขนเสื้อเชิ้ตขาวพับแขน
    createRigPart("RightSleeve", Vector3.new(0.38, 0.42, 0.70), shirtWhite, Enum.Material.Fabric, CFrame.new(0.55, -0.85, 1.65))
    createRigPart("RightCuff", Vector3.new(0.40, 0.44, 0.12), shirtCuff, Enum.Material.Fabric, CFrame.new(0.55, -0.85, 1.30))
    -- ท่อนแขนล่าง (Forearm)
    createRigPart("RightForearm", Vector3.new(0.32, 0.34, 1.05), skinColor, Enum.Material.SmoothPlastic, CFrame.new(0.45, -0.70, 0.95) * CFrame.Angles(math.rad(12), math.rad(-8), 0))
    -- ข้อมือและฝ่ามือขวา (Right Hand)
    createRigPart("RightHand", Vector3.new(0.30, 0.22, 0.38), skinColor, Enum.Material.SmoothPlastic, CFrame.new(0.08, -0.42, 0.42))

    ------------------------------------------------------------------
    -- B. แขนซ้าย (Left Arm - ประคองปืน & ขยับตอนรีโหลด)
    ------------------------------------------------------------------
    if isPistol then
        -- ท่าจับปืนพกสองมือ (Two-handed combat grip)
        createRigPart("LeftSleeve", Vector3.new(0.38, 0.42, 0.70), shirtWhite, Enum.Material.Fabric, CFrame.new(-0.35, -0.85, 1.55), true)
        createRigPart("LeftCuff", Vector3.new(0.40, 0.44, 0.12), shirtCuff, Enum.Material.Fabric, CFrame.new(-0.35, -0.85, 1.20), true)
        createRigPart("LeftForearm", Vector3.new(0.32, 0.34, 1.05), skinColor, Enum.Material.SmoothPlastic, CFrame.new(-0.25, -0.68, 0.90) * CFrame.Angles(math.rad(15), math.rad(12), 0), true)
        createRigPart("LeftHand", Vector3.new(0.32, 0.22, 0.36), skinColor, Enum.Material.SmoothPlastic, CFrame.new(-0.06, -0.44, 0.40), true)
    else
        -- ท่าจับปืนยาวประคองกระโจมมือหน้า (Rifle handguard grip)
        createRigPart("LeftSleeve", Vector3.new(0.38, 0.42, 0.70), shirtWhite, Enum.Material.Fabric, CFrame.new(-0.65, -0.90, 0.65), true)
        createRigPart("LeftCuff", Vector3.new(0.40, 0.44, 0.12), shirtCuff, Enum.Material.Fabric, CFrame.new(-0.65, -0.90, 0.30), true)
        createRigPart("LeftForearm", Vector3.new(0.32, 0.34, 1.15), skinColor, Enum.Material.SmoothPlastic, CFrame.new(-0.45, -0.65, -0.30) * CFrame.Angles(math.rad(18), math.rad(14), 0), true)
        createRigPart("LeftHand", Vector3.new(0.30, 0.22, 0.38), skinColor, Enum.Material.SmoothPlastic, CFrame.new(-0.12, -0.22, -1.25), true)
    end

    ------------------------------------------------------------------
    -- C. โมเดลปืน VALORANT
    ------------------------------------------------------------------
    local pCol = wData.PrimaryColor
    local aCol = wData.AccentColor
    local barrelLength = isPistol and 1.2 or (wData.IsSniper and 3.4 or 2.4)
    local muzzleZ = isPistol and -1.4 or (wData.IsSniper and -3.8 or -2.9)

    -- โครงปืนหลัก (Receiver)
    createRigPart("GunReceiver", Vector3.new(0.34, 0.52, isPistol and 1.1 or 1.8), pCol, Enum.Material.Metal, CFrame.new(0, 0, 0))
    -- ฝาครอบบนและแถบสี Accent
    createRigPart("GunCover", Vector3.new(0.30, 0.18, isPistol and 0.9 or 1.5), aCol, Enum.Material.SmoothPlastic, CFrame.new(0, 0.30, 0))
    -- ลำกล้องปืน (Barrel)
    createRigPart("GunBarrel", Vector3.new(0.18, 0.18, barrelLength), Color3.fromRGB(25, 25, 28), Enum.Material.Metal, CFrame.new(0, 0.05, muzzleZ * 0.55))

    -- แม็กกาซีน (Magazine)
    if not (wData.Name == "Shorty" or wData.Name == "Outlaw" or wData.Type == "Revolver") then
        local magH = isPistol and 0.55 or 0.9
        createRigPart("Magazine", Vector3.new(0.24, magH, 0.45), aCol, Enum.Material.SmoothPlastic, CFrame.new(0, -0.45, -0.15))
    end

    -- ด้ามจับ (Pistol Grip)
    createRigPart("PistolGrip", Vector3.new(0.30, 0.85, 0.42), Color3.fromRGB(30, 32, 36), Enum.Material.SmoothPlastic, CFrame.new(0, -0.45, 0.40) * CFrame.Angles(math.rad(-16), 0, 0))

    -- พานท้ายปืน (Stock สำหรับปืนยาว)
    if not isPistol then
        createRigPart("Stock", Vector3.new(0.32, 0.80, 1.6), pCol, Enum.Material.Metal, CFrame.new(0, -0.05, 1.45))
    end

    -- ลำกล้องเก็บเสียง (Silencer สำหรับ Ghost, Spectre, Phantom)
    if wData.Silenced then
        createRigPart("Silencer", Vector3.new(0.26, 0.26, 1.2), Color3.fromRGB(20, 22, 26), Enum.Material.Metal, CFrame.new(0, 0.05, muzzleZ - 0.5))
        muzzleZ = muzzleZ - 1.1
    end

    -- สโคปสไนเปอร์ (Scope สำหรับ Operator, Marshal, Outlaw)
    if wData.IsSniper then
        createRigPart("ScopeMount", Vector3.new(0.20, 0.25, 0.6), Color3.fromRGB(30, 30, 35), Enum.Material.Metal, CFrame.new(0, 0.38, -0.3))
        createRigPart("ScopeTube", Vector3.new(0.32, 0.32, 1.6), Color3.fromRGB(20, 22, 26), Enum.Material.Metal, CFrame.new(0, 0.55, -0.3))
        createRigPart("ScopeRing", Vector3.new(0.36, 0.36, 0.2), aCol, Enum.Material.Neon, CFrame.new(0, 0.55, -1.0))
    else
        -- ศูนย์หน้าเรืองแสงสำหรับปืนทั่วไป
        createRigPart("FrontSight", Vector3.new(0.06, 0.12, 0.06), Color3.fromRGB(50, 255, 120), Enum.Material.Neon, CFrame.new(0, 0.42, muzzleZ + 0.2))
    end

    -- ปากกระบอกปืนและไฟแฟลช (Muzzle Flash)
    muzzleFlashPart = createRigPart("MuzzleFlash", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(255, 200, 50), Enum.Material.Neon, CFrame.new(0, 0.05, muzzleZ))
    muzzleFlashPart.Transparency = 1

    flashLight = Instance.new("PointLight")
    flashLight.Color = Color3.fromRGB(255, 180, 50)
    flashLight.Range = 22
    flashLight.Brightness = 0
    flashLight.Parent = muzzleFlashPart
end

----------------------------------------------------------------------
-- 5. หน้าจอ UI: HUD ข้อมูลปืน, CROSSHAIR, และสโคปสไนเปอร์
----------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Valorant_HUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = pGui

-- Crosshair
local crosshairGui = Instance.new("Frame")
crosshairGui.Name = "Crosshair"
crosshairGui.Size = UDim2.new(0, 24, 0, 24)
crosshairGui.Position = UDim2.new(0.5, -12, 0.5, -12)
crosshairGui.BackgroundTransparency = 1
crosshairGui.Parent = screenGui

local function makeChLine(pos, size)
    local l = Instance.new("Frame")
    l.Size = size
    l.Position = pos
    l.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
    l.BorderSizePixel = 0
    l.Parent = crosshairGui
    return l
end
makeChLine(UDim2.new(0.5, -1, 0.5, -10), UDim2.new(0, 2, 0, 6))
makeChLine(UDim2.new(0.5, -1, 0.5, 4),   UDim2.new(0, 2, 0, 6))
makeChLine(UDim2.new(0.5, -10, 0.5, -1), UDim2.new(0, 6, 0, 2))
makeChLine(UDim2.new(0.5, 4, 0.5, -1),   UDim2.new(0, 6, 0, 2))

-- Sniper Scope Overlay (จอดำซูมของ Operator / Marshal)
local scopeOverlay = Instance.new("Frame")
scopeOverlay.Size = UDim2.new(1, 0, 1, 0)
scopeOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scopeOverlay.BackgroundTransparency = 1
scopeOverlay.BorderSizePixel = 0
scopeOverlay.Visible = false
scopeOverlay.Parent = screenGui

local scopeReticle = Instance.new("Frame")
scopeReticle.Size = UDim2.new(0, 500, 0, 500)
scopeReticle.Position = UDim2.new(0.5, -250, 0.5, -250)
scopeReticle.BackgroundTransparency = 1
scopeReticle.Parent = scopeOverlay

local scopeLineV = Instance.new("Frame")
scopeLineV.Size = UDim2.new(0, 2, 1, 0)
scopeLineV.Position = UDim2.new(0.5, -1, 0, 0)
scopeLineV.BackgroundColor3 = Color3.fromRGB(255, 40, 60)
scopeLineV.BorderSizePixel = 0
scopeLineV.Parent = scopeReticle

local scopeLineH = Instance.new("Frame")
scopeLineH.Size = UDim2.new(1, 0, 0, 2)
scopeLineH.Position = UDim2.new(0, 0, 0.5, -1)
scopeLineH.BackgroundColor3 = Color3.fromRGB(255, 40, 60)
scopeLineH.BorderSizePixel = 0
scopeLineH.Parent = scopeReticle

-- Hitmarker
local hitmarker = Instance.new("ImageLabel")
hitmarker.Size = UDim2.new(0, 28, 0, 28)
hitmarker.Position = UDim2.new(0.5, -14, 0.5, -14)
hitmarker.BackgroundTransparency = 1
hitmarker.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
hitmarker.ImageColor3 = Color3.fromRGB(255, 50, 50)
hitmarker.ImageTransparency = 1
hitmarker.Parent = screenGui

-- Card แสดงข้อมูลปืน (มุมขวาล่าง)
local gunCard = Instance.new("Frame")
gunCard.Size = UDim2.new(0, 280, 0, 105)
gunCard.Position = UDim2.new(1, -300, 1, -125)
gunCard.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
gunCard.BackgroundTransparency = 0.2
gunCard.BorderSizePixel = 0
gunCard.Parent = screenGui
Instance.new("UICorner", gunCard).CornerRadius = UDim.new(0, 8)

local cardStroke = Instance.new("UIStroke", gunCard)
cardStroke.Color = Color3.fromRGB(255, 70, 85)
cardStroke.Thickness = 1.5

local gunNameLabel = Instance.new("TextLabel")
gunNameLabel.Size = UDim2.new(1, -20, 0, 26)
gunNameLabel.Position = UDim2.new(0, 14, 0, 8)
gunNameLabel.BackgroundTransparency = 1
gunNameLabel.TextColor3 = Color3.fromRGB(255, 70, 85)
gunNameLabel.Font = Enum.Font.GothamBold
gunNameLabel.TextSize = 20
gunNameLabel.TextXAlignment = Enum.TextXAlignment.Left
gunNameLabel.Text = "VANDAL"
gunNameLabel.Parent = gunCard

local gunTypeLabel = Instance.new("TextLabel")
gunTypeLabel.Size = UDim2.new(1, -20, 0, 16)
gunTypeLabel.Position = UDim2.new(0, 14, 0, 34)
gunTypeLabel.BackgroundTransparency = 1
gunTypeLabel.TextColor3 = Color3.fromRGB(170, 185, 205)
gunTypeLabel.Font = Enum.Font.Gotham
gunTypeLabel.TextSize = 12
gunTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
gunTypeLabel.Text = "RIFLE // FULL-AUTO"
gunTypeLabel.Parent = gunCard

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Size = UDim2.new(1, -20, 0, 42)
ammoLabel.Position = UDim2.new(0, 14, 0, 52)
ammoLabel.BackgroundTransparency = 1
ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextSize = 32
ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
ammoLabel.Text = "25 / 125"
ammoLabel.Parent = gunCard

-- ปุ่มลัดเมนูซื้อปืน [B]
local buyHint = Instance.new("TextLabel")
buyHint.Size = UDim2.new(0, 240, 0, 24)
buyHint.Position = UDim2.new(1, -260, 1, -155)
buyHint.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
buyHint.BackgroundTransparency = 0.4
buyHint.TextColor3 = Color3.fromRGB(255, 210, 80)
buyHint.Font = Enum.Font.GothamBold
buyHint.TextSize = 12
buyHint.Text = "🛒 กดปุ่ม [B] เพื่อเลือกปืน VALORANT"
buyHint.Parent = screenGui
Instance.new("UICorner", buyHint).CornerRadius = UDim.new(0, 4)

local function updateAmmoUI()
    if isReloading then
        ammoLabel.Text = "RELOADING..."
        ammoLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    else
        ammoLabel.Text = string.format("%d / %d", clipAmmo, reserveAmmo)
        ammoLabel.TextColor3 = (clipAmmo <= math.floor(currentWeapon.Mag * 0.25)) and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 255, 255)
    end
end

----------------------------------------------------------------------
-- 6. VALORANT BUY MENU (ARSENAL SHOP // กดย่อ-ขยายด้วยปุ่ม B)
----------------------------------------------------------------------
local buyMenu = Instance.new("Frame")
buyMenu.Name = "BuyMenu"
buyMenu.Size = UDim2.new(0.92, 0, 0.88, 0)
buyMenu.Position = UDim2.new(0.04, 0, 0.06, 0)
buyMenu.BackgroundColor3 = Color3.fromRGB(15, 23, 34)
buyMenu.BackgroundTransparency = 0.05
buyMenu.Visible = false
buyMenu.Parent = screenGui
Instance.new("UICorner", buyMenu).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", buyMenu).Color = Color3.fromRGB(255, 70, 85)

-- Header เมนู
local menuTitle = Instance.new("TextLabel")
menuTitle.Size = UDim2.new(1, -160, 0, 45)
menuTitle.Position = UDim2.new(0, 20, 0, 10)
menuTitle.BackgroundTransparency = 1
menuTitle.TextColor3 = Color3.fromRGB(255, 70, 85)
menuTitle.Font = Enum.Font.GothamBold
menuTitle.TextSize = 22
menuTitle.TextXAlignment = Enum.TextXAlignment.Left
menuTitle.Text = "VALORANT ARSENAL // คลังแสงเลือกปืนทดสอบ (กด [B] หรือคลิกปุ่มเพื่อปิด)"
menuTitle.Parent = buyMenu

local closeMenuBtn = Instance.new("TextButton")
closeMenuBtn.Size = UDim2.new(0, 120, 0, 34)
closeMenuBtn.Position = UDim2.new(1, -140, 0, 14)
closeMenuBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 85)
closeMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeMenuBtn.Font = Enum.Font.GothamBold
closeMenuBtn.TextSize = 14
closeMenuBtn.Text = "✕ ปิดเมนู [B]"
closeMenuBtn.Parent = buyMenu
Instance.new("UICorner", closeMenuBtn).CornerRadius = UDim.new(0, 6)

-- คำสั่งระดับ Engine ของ Roblox: เมื่อปุ่มที่มี Modal=true แสดงผล Roblox จะปลดล็อคเมาส์ออกจาก First Person ทันที 100%!
local engineModalUnlocker = Instance.new("TextButton")
engineModalUnlocker.Name = "EngineModalUnlocker"
engineModalUnlocker.Size = UDim2.new(0, 0, 0, 0)
engineModalUnlocker.BackgroundTransparency = 1
engineModalUnlocker.Text = ""
engineModalUnlocker.Modal = true
engineModalUnlocker.Parent = buyMenu

local categories = { "Sidearms", "SMGs", "Shotguns", "Rifles", "Snipers", "Heavy" }
local colWidth = 1 / #categories

for i, catName in ipairs(categories) do
    local colFrame = Instance.new("Frame")
    colFrame.Size = UDim2.new(colWidth, -12, 1, -70)
    colFrame.Position = UDim2.new((i - 1) * colWidth, 6, 0, 60)
    colFrame.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
    colFrame.BackgroundTransparency = 0.3
    colFrame.Parent = buyMenu
    Instance.new("UICorner", colFrame).CornerRadius = UDim.new(0, 6)

    local catLabel = Instance.new("TextLabel")
    catLabel.Size = UDim2.new(1, 0, 0, 30)
    catLabel.BackgroundTransparency = 1
    catLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
    catLabel.Font = Enum.Font.GothamBold
    catLabel.TextSize = 14
    catLabel.Text = catName:upper()
    catLabel.Parent = colFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent = colFrame

    -- ใส่ปืนในหมวดนั้นๆ
    for key, w in pairs(VALORANT_ARSENAL) do
        if w.Category == catName then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.92, 0, 0, 65)
            btn.BackgroundColor3 = Color3.fromRGB(28, 38, 54)
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = true
            btn.Text = ""
            btn.Parent = colFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            local wTitle = Instance.new("TextLabel")
            wTitle.Size = UDim2.new(1, -12, 0, 22)
            wTitle.Position = UDim2.new(0, 6, 0, 4)
            wTitle.BackgroundTransparency = 1
            wTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            wTitle.Font = Enum.Font.GothamBold
            wTitle.TextSize = 15
            wTitle.TextXAlignment = Enum.TextXAlignment.Left
            wTitle.Text = w.Name
            wTitle.Parent = btn

            local wInfo = Instance.new("TextLabel")
            wInfo.Size = UDim2.new(1, -12, 0, 16)
            wInfo.Position = UDim2.new(0, 6, 0, 26)
            wInfo.BackgroundTransparency = 1
            wInfo.TextColor3 = Color3.fromRGB(160, 180, 205)
            wInfo.Font = Enum.Font.Gotham
            wInfo.TextSize = 11
            wInfo.TextXAlignment = Enum.TextXAlignment.Left
            wInfo.Text = string.format("หัว %d | ตัว %d", w.HeadDmg, w.BodyDmg)
            wInfo.Parent = btn

            local wMag = Instance.new("TextLabel")
            wMag.Size = UDim2.new(1, -12, 0, 16)
            wMag.Position = UDim2.new(0, 6, 0, 44)
            wMag.BackgroundTransparency = 1
            wMag.TextColor3 = Color3.fromRGB(255, 70, 85)
            wMag.Font = Enum.Font.GothamBold
            wMag.TextSize = 11
            wMag.TextXAlignment = Enum.TextXAlignment.Left
            wMag.Text = string.format("แม็ก: %d นัด (%s)", w.Mag, w.FiringType)
            wMag.Parent = btn

            btn.MouseButton1Click:Connect(function()
                -- สลับอาวุธ
                currentWeaponKey = key
                currentWeapon = VALORANT_ARSENAL[key]
                clipAmmo = currentWeapon.Mag
                reserveAmmo = currentWeapon.Reserve
                isAiming = false
                isReloading = false

                gunNameLabel.Text = currentWeapon.Name
                gunTypeLabel.Text = string.format("%s // %s", currentWeapon.Category:upper(), currentWeapon.FiringType:upper())
                updateAmmoUI()

                buildCurrentViewmodel()
                playClickSound(1.8)

                buyMenu.Visible = false
                setCameraFrozen(false)
                isCursorFree = false
                crosshairGui.Visible = true
            end)
        end
    end
end

local function toggleBuyMenu()
    buyMenu.Visible = not buyMenu.Visible
    playClickSound(2.2)
    if buyMenu.Visible then
        setCameraFrozen(true)
        isMouseDown = false
        isAiming = false
        crosshairGui.Visible = false
    else
        setCameraFrozen(false)
        isCursorFree = false
        crosshairGui.Visible = true
    end
end

closeMenuBtn.MouseButton1Click:Connect(function()
    toggleBuyMenu()
end)

-- บังคับสถานะเมาส์แบบ Real-time ให้ชนะ PlayerModule ของ Roblox เสมอ
RunService:BindToRenderStep("EnforceMouseBehavior", Enum.RenderPriority.Camera.Value + 1, function()
    if buyMenu.Visible or isCursorFree then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end
end)

----------------------------------------------------------------------
-- 7. ระบบรีโหลด COD STYLE (PROCEDURAL RELOAD ANIMATION)
----------------------------------------------------------------------
local function reloadWeapon()
    if isReloading or clipAmmo == currentWeapon.Mag or reserveAmmo <= 0 then return end
    isReloading = true
    isAiming = false
    reloadTimer = 0
    updateAmmoUI()

    playClickSound(2.0) -- เสียงปลดแม็กกาซีน

    task.delay(0.9, function()
        playClickSound(2.8) -- เสียงตบแม็กใหม่เข้าช่อง
    end)
    task.delay(1.5, function()
        playClickSound(1.6) -- เสียงสับคันรั้งลูกเลื่อน
    end)

    task.wait(reloadTimeTotal)
    local needed = currentWeapon.Mag - clipAmmo
    local toAdd = math.min(needed, reserveAmmo)
    clipAmmo = clipAmmo + toAdd
    reserveAmmo = reserveAmmo - toAdd
    isReloading = false
    updateAmmoUI()
end

----------------------------------------------------------------------
-- 8. ตัวเลขดาเมจลอย (DAMAGE POPUP)
----------------------------------------------------------------------
local function showDamagePopup(pos, damage, isHeadshot)
    local pPart = Instance.new("Part")
    pPart.Size = Vector3.new(0.1, 0.1, 0.1)
    pPart.CFrame = CFrame.new(pos + Vector3.new((math.random() - 0.5) * 1.5, 1.5, (math.random() - 0.5) * 1.5))
    pPart.Transparency = 1
    pPart.CanCollide = false
    pPart.Anchored = true
    pPart.Parent = Workspace

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 150, 0, 35)
    bb.AlwaysOnTop = true
    bb.Parent = pPart

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = isHeadshot and Color3.fromRGB(255, 45, 45) or Color3.fromRGB(255, 200, 50)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = isHeadshot and 22 or 16
    label.Text = isHeadshot and ("💥 " .. damage .. " HEADSHOT!") or tostring(damage)
    label.Parent = bb

    TweenService:Create(pPart, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = pPart.CFrame + Vector3.new(0, 2.2, 0)
    }):Play()
    TweenService:Create(label, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        TextTransparency = 1,
        TextStrokeTransparency = 1
    }):Play()

    Debris:AddItem(pPart, 0.85)
end

----------------------------------------------------------------------
-- 9. ระบบยิงปืน (BALLISTICS & SHOOTING ENGINE)
----------------------------------------------------------------------
local function executeShoot()
    if isReloading or buyMenu.Visible then return end

    local now = os.clock()
    if now - lastShotTime < currentWeapon.FireRate then return end

    if clipAmmo <= 0 then
        playClickSound(3.5)
        reloadWeapon()
        return
    end

    lastShotTime = now
    clipAmmo = clipAmmo - 1
    updateAmmoUI()

    -- 1. เล่นเสียงปืน
    playWeaponFireSound()

    -- 2. แรงถีบปืน Recoil สะบัด
    local rMult = currentWeapon.Recoil or 3.5
    recoilZ = isAiming and (rMult * 0.06) or (rMult * 0.09)
    recoilRotX = isAiming and (rMult * 0.8) or (rMult * 1.4)
    recoilRotY = (math.random() - 0.5) * (rMult * 0.3)

    -- 3. แฟลชไฟปากกระบอกปืน
    if muzzleFlashPart then
        muzzleFlashPart.Transparency = 0
        flashLight.Brightness = currentWeapon.Silenced and 1.5 or 4.5
        task.delay(0.04, function()
            muzzleFlashPart.Transparency = 1
            flashLight.Brightness = 0
        end)
    end

    -- 4. สั่นกล้องผู้เล่น
    camera.CFrame = camera.CFrame * CFrame.Angles(
        math.rad(isAiming and 0.3 or 0.6),
        math.rad((math.random() - 0.5) * 0.3),
        0
    )

    -- 5. Raycast ยิงกระสุน (รองรับทั้งนัดเดี่ยวและลูกซองหลายเม็ด Pellets)
    local pelletsCount = currentWeapon.Pellets or 1
    local rayOrigin = camera.CFrame.Position
    local baseDir = camera.CFrame.LookVector

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { player.Character, viewmodel }
    rayParams.FilterType = RaycastFilterType.Exclude

    for i = 1, pelletsCount do
        local spread = (pelletsCount > 1) and Vector3.new((math.random() - 0.5) * 0.08, (math.random() - 0.5) * 0.08, (math.random() - 0.5) * 0.08) or Vector3.zero
        local shotDir = (baseDir + spread).Unit * 500

        local hit = Workspace:Raycast(rayOrigin, shotDir, rayParams)
        local tracerEnd = hit and hit.Position or (rayOrigin + shotDir)
        local muzzlePos = muzzleFlashPart and muzzleFlashPart.Position or rayOrigin

        -- กระสุนพุ่ง
        local dist = (tracerEnd - muzzlePos).Magnitude
        if dist > 0.5 then
            local tracer = Instance.new("Part")
            tracer.Size = Vector3.new(0.08, 0.08, dist)
            tracer.CFrame = CFrame.lookAt((muzzlePos + tracerEnd) / 2, tracerEnd)
            tracer.Color = currentWeapon.Silenced and Color3.fromRGB(100, 220, 255) or Color3.fromRGB(255, 215, 90)
            tracer.Material = Enum.Material.Neon
            tracer.CanCollide = false
            tracer.Anchored = true
            tracer.Parent = Workspace
            Debris:AddItem(tracer, 0.04)
        end

        -- โดนเป้าซอมบี้
        if hit and hit.Instance then
            local hitPart = hit.Instance
            local hitModel = hitPart:FindFirstAncestorOfClass("Model")
            if hitModel and hitModel.Name:sub(1, 7) == "Zombie_" then
                local isHeadshot = (hitPart.Name == "Head" or hitPart.Name == "Eyes")
                local dmg = isHeadshot and currentWeapon.HeadDmg or currentWeapon.BodyDmg

                zombieHitEvent:FireServer(hitPart, dmg, isHeadshot)
                playHitSound(isHeadshot)
                showDamagePopup(hit.Position, dmg, isHeadshot)

                hitmarker.ImageColor3 = isHeadshot and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 190, 50)
                hitmarker.ImageTransparency = 0
                task.delay(0.08, function()
                    hitmarker.ImageTransparency = 1
                end)
            else
                -- ประกายไฟกระทบผนัง
                local spark = Instance.new("Part")
                spark.Size = Vector3.new(0.2, 0.2, 0.2)
                spark.CFrame = CFrame.new(hit.Position)
                spark.Color = Color3.fromRGB(255, 230, 150)
                spark.Material = Enum.Material.Neon
                spark.Anchored = true
                spark.CanCollide = false
                spark.Parent = Workspace
                Debris:AddItem(spark, 0.05)
            end
        end
    end
end

----------------------------------------------------------------------
-- 10. ตรวจจับการกดปุ่ม & เมาส์ (INPUTS)
----------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end

    -- กด B เพื่อเปิด/ปิดเมนูซื้อปืน
    if input.KeyCode == Enum.KeyCode.B then
        toggleBuyMenu()
        return
    end

    -- กด LeftAlt เพื่อปลดล็อคเมาส์อิสระ (Free Cursor) หรือสลับล็อคกลับ
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        isCursorFree = not isCursorFree
        setCameraFrozen(isCursorFree)
        return
    end

    -- ถ้าเมนูซื้อปืนเปิดอยู่ ให้ใช้เมาส์คลิกเมนูได้โดยไม่ยิงปืน
    if buyMenu.Visible then return end

    -- คลิกซ้าย: ยิงปืน (ถ้าเมาส์เคยหลุด ให้ล็อคเมาส์กลับเข้าโหมด FPS ทันที)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isCursorFree then
            isCursorFree = false
            setCameraFrozen(false)
        end
        isMouseDown = true
        executeShoot()
    -- คลิกขวา: เล็งศูนย์ปืน ADS / ซูมสไนเปอร์
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = true
        crosshairGui.Visible = false
        if currentWeapon.IsSniper then
            scopeOverlay.Visible = true
            scopeOverlay.BackgroundTransparency = 0.1
        end
    -- กด R: รีโหลด
    elseif input.KeyCode == Enum.KeyCode.R then
        reloadWeapon()
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = false
        crosshairGui.Visible = true
        if currentWeapon.IsSniper then
            scopeOverlay.Visible = false
            scopeOverlay.BackgroundTransparency = 1
        end
    end
end)

UserInputService.InputChanged:Connect(function(input, gp)
    -- ตรวจจับแรงสะบัดเมาส์เพื่อสร้าง Mouse Sway
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        mouseSwayX = math.clamp(input.Delta.X * 0.0015, -0.06, 0.06)
        mouseSwayY = math.clamp(input.Delta.Y * 0.0015, -0.06, 0.06)
    end
end)

-- Heartbeat Loop: ยิง Full-Auto อย่างต่อเนื่อง
RunService.Heartbeat:Connect(function()
    if isMouseDown and not isReloading and currentWeapon.FiringType == "Auto" then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            executeShoot()
        else
            isMouseDown = false
        end
    end
end)

----------------------------------------------------------------------
-- 11. อัปเดตตำแหน่งปืนและแอนิเมชันทุกเฟรม (RENDER STEPPED)
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    -- 1. ADS Aiming vs Hipfire
    local isPistol = (currentWeapon.Type == "Pistol" or currentWeapon.Type == "Revolver")
    local hipTarget = isPistol and CFrame.new(0.45, -0.50, -1.15) or CFrame.new(0.60, -0.55, -1.35)
    local adsTarget = isPistol and CFrame.new(0, -0.32, -0.95) or CFrame.new(0, -0.42, -1.15)

    local targetOffset = isAiming and adsTarget or hipTarget
    currentOffset = currentOffset:Lerp(targetOffset, math.clamp(dt * 18, 0, 1))

    -- 2. FOV ซูมเข้า
    local fovTarget = isAiming and (currentWeapon.IsSniper and 28 or 52) or 70
    camera.FieldOfView = camera.FieldOfView + (fovTarget - camera.FieldOfView) * math.clamp(dt * 15, 0, 1)

    -- 3. คืนตัวของแรงถีบ (Recoil Spring)
    recoilZ = recoilZ * math.exp(-dt * 22)
    recoilRotX = recoilRotX * math.exp(-dt * 20)
    recoilRotY = recoilRotY * math.exp(-dt * 20)

    -- 4. การโยกตัวตามการหายใจและก้าวเดิน (Breathing & Walk Bobbing)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local vel = hrp and hrp.AssemblyLinearVelocity.Magnitude or 0
    local isWalking = (vel > 1.5)
    local bobFreq = isWalking and 10.5 or 3.2
    local bobAmp = isWalking and 0.035 or 0.012
    if isAiming then bobAmp = bobAmp * 0.15 end

    swayTimer = swayTimer + dt * bobFreq
    local bobX = math.sin(swayTimer) * bobAmp
    local bobY = math.cos(swayTimer * 2) * (bobAmp * 0.5)

    -- ค่อยๆ คืนค่า Mouse Sway
    mouseSwayX = mouseSwayX * math.exp(-dt * 14)
    mouseSwayY = mouseSwayY * math.exp(-dt * 14)

    -- 5. แอนิเมชันรีโหลด COD Style (Left Arm Displacement)
    local leftArmReloadOffset = CFrame.identity
    if isReloading then
        reloadTimer = reloadTimer + dt
        local prog = reloadTimer / reloadTimeTotal
        if prog < 0.35 then
            -- มือซ้ายเอื้อมดึงแม็กเก่าลงด้านล่าง
            leftArmReloadOffset = CFrame.new(0, -prog * 2.2, prog * 0.8) * CFrame.Angles(math.rad(-prog * 40), 0, 0)
        elseif prog < 0.70 then
            -- มือซ้ายหยิบแม็กใหม่ขึ้นมาตบเข้าช่อง
            local p2 = (prog - 0.35) / 0.35
            leftArmReloadOffset = CFrame.new(0, -(1 - p2) * 2.2, (1 - p2) * 0.8) * CFrame.Angles(math.rad(-(1 - p2) * 40), 0, 0)
        elseif prog < 0.90 then
            -- มือซ้ายเอื้อมขึ้นสับคันรั้งลูกเลื่อน
            local p3 = (prog - 0.70) / 0.20
            leftArmReloadOffset = CFrame.new(0.2, 0.25, -p3 * 0.4)
        else
            -- กลับสู่ตำแหน่งเดิม
            leftArmReloadOffset = CFrame.identity
        end
    end

    -- 6. รวมตำแหน่ง CFrame ทั้งหมด
    local motionCFrame = CFrame.new(bobX - mouseSwayX, bobY - mouseSwayY, recoilZ) * CFrame.Angles(
        math.rad(recoilRotX - mouseSwayY * 40),
        math.rad(recoilRotY - mouseSwayX * 40),
        math.rad(mouseSwayX * 25)
    )

    local finalRootCF = camera.CFrame * currentOffset * motionCFrame
    gunRoot.CFrame = finalRootCF

    -- ปรับตำแหน่งชิ้นส่วนทั้งหมด
    for part, relCF in pairs(rigParts) do
        if part and part.Parent then
            if leftArmParts[part] and isReloading then
                part.CFrame = finalRootCF * relCF * leftArmReloadOffset
            else
                part.CFrame = finalRootCF * relCF
            end
        end
    end
end)

-- สร้าง Viewmodel ครั้งแรก
buildCurrentViewmodel()
updateAmmoUI()

print("=========================================================")
print("✅ [KMUTNB Arsenal] ระบบปืน VALORANT ครบ 18 กระบอก & แขนนักศึกษา มจพ. พร้อมใช้งาน!")
print("=========================================================")
