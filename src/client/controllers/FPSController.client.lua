--[[
    FPSController.client.lua
    ใส่ใน: StarterPlayer -> StarterPlayerScripts
    หน้าที่:
      1. ล็อคมุมมอง First Person 100%
      2. โมเดลปืนไรเฟิลจู่โจม AK-47 3D Viewmodel (โครงโลหะสีเข้ม, ประกับไม้ & พานท้ายไม้วอลนัท, แม็กกาซีนกล้วย 30 นัด)
      3. ยิงแบบฟูลออโต้ Full-Auto (คลิกซ้ายค้างรัวกระสุน 600 RPM)
      4. เล็งประณีต Aim Down Sights (ADS) ผ่านศูนย์เล็งเหล็กจริง (ศูนย์หน้าเรืองแสง Tritium สีเขียว)
      5. เอฟเฟกต์และเสียงปืน AK-47 กระหึ่ม หนักแน่นสมจริง (Muzzle Flash, Recoil Kickback, Bullet Tracer, Screen Shake)
      6. ระบบตรวจจับ Headshot ดาเมจทะลวง x2.5 พร้อมตัวเลขดาเมจลอย (Floating Damage Popup)
      7. HUD กระสุน, เป้าเล็ง Crosshair & Hitmarker
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

player.CameraMode = Enum.CameraMode.LockFirstPerson

-- Remote Events
local zombieEvents = ReplicatedStorage:WaitForChild("ZombieGameEvents", 25)
local updateScoreboardEvent = zombieEvents:WaitForChild("UpdateScoreboard", 25)
local waveAnnounceEvent = zombieEvents:WaitForChild("WaveAnnounce", 25)
local zombieHitEvent = zombieEvents:WaitForChild("ZombieHitEvent", 25)

----------------------------------------------------------------------
-- 1. ล้างโมเดลและ UI เก่า
----------------------------------------------------------------------
local oldVm = camera:FindFirstChild("AK47_ViewModel") or camera:FindFirstChild("GunViewModel")
if oldVm then oldVm:Destroy() end

local oldHud = pGui:FindFirstChild("AK47_HUD") or pGui:FindFirstChild("ZombieFPS_HUD") or pGui:FindFirstChild("TestInfoUI")
if oldHud then oldHud:Destroy() end

----------------------------------------------------------------------
-- 2. สร้าง 3D AK-47 VIEWMODEL (ไรเฟิลจู่โจมคาลาชนิคอฟ)
----------------------------------------------------------------------
local viewmodel = Instance.new("Model")
viewmodel.Name = "AK47_ViewModel"
viewmodel.Parent = camera

local gunRoot = Instance.new("Part")
gunRoot.Name = "GunRoot"
gunRoot.Size = Vector3.new(0.2, 0.2, 0.2)
gunRoot.Transparency = 1
gunRoot.CanCollide = false
gunRoot.Anchored = true
gunRoot.Parent = viewmodel

local partOffsets = {}

local function createGunPart(name, size, color, material, relCFrame)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = material
    p.CanCollide = false
    p.Anchored = true
    p.CastShadow = false
    p.Parent = viewmodel
    partOffsets[p] = relCFrame
    return p
end

-- โครงปืนส่วนรับลูกเลื่อน (Receiver) - เหล็กดำด้าน
createGunPart("Receiver", Vector3.new(0.36, 0.54, 1.8), Color3.fromRGB(36, 38, 42), Enum.Material.Metal, CFrame.new(0, 0, 0))

-- ฝาครอบห้องลูกเลื่อนด้านบน (Dust Cover) - แผ่นเหล็กโค้ง
createGunPart("DustCover", Vector3.new(0.33, 0.26, 1.45), Color3.fromRGB(30, 32, 36), Enum.Material.Metal, CFrame.new(0, 0.35, 0.12))

-- ฐานศูนย์เล็งหลัง (Rear Sight Base & Notch)
createGunPart("RearSightBase", Vector3.new(0.24, 0.22, 0.35), Color3.fromRGB(35, 36, 40), Enum.Material.Metal, CFrame.new(0, 0.36, -0.65))
createGunPart("RearNotchL", Vector3.new(0.08, 0.14, 0.12), Color3.fromRGB(24, 25, 28), Enum.Material.Metal, CFrame.new(-0.08, 0.46, -0.65))
createGunPart("RearNotchR", Vector3.new(0.08, 0.14, 0.12), Color3.fromRGB(24, 25, 28), Enum.Material.Metal, CFrame.new(0.08, 0.46, -0.65))

-- ประกับรองมือล่าง (Lower Handguard) - ไม้วอลนัทสีน้ำตาลทอง/แดงเข้ม
createGunPart("HandguardLower", Vector3.new(0.38, 0.48, 1.25), Color3.fromRGB(125, 60, 24), Enum.Material.Wood, CFrame.new(0, -0.02, -1.45))

-- ท่อดักแก๊สบน (Upper Gas Tube Guard) - ไม้
createGunPart("GasTubeUpper", Vector3.new(0.32, 0.36, 1.05), Color3.fromRGB(120, 56, 22), Enum.Material.Wood, CFrame.new(0, 0.32, -1.42))

-- บล็อคทางเดินแก๊ส (Gas Block) - เหล็กเชื่อม
createGunPart("GasBlock", Vector3.new(0.22, 0.42, 0.25), Color3.fromRGB(28, 30, 34), Enum.Material.Metal, CFrame.new(0, 0.26, -2.08))

-- ลำกล้องปืนไรเฟิล (Rifle Barrel) - เหล็กยาว
createGunPart("Barrel", Vector3.new(0.18, 0.18, 2.6), Color3.fromRGB(24, 25, 28), Enum.Material.Metal, CFrame.new(0, 0.05, -2.25))

-- ปลอกลดแสงปากลำกล้องทรงเฉียง (AK Slant Muzzle Brake)
createGunPart("SlantBrake", Vector3.new(0.22, 0.22, 0.35), Color3.fromRGB(28, 28, 32), Enum.Material.Metal, CFrame.new(0, 0.05, -3.55))

-- ฐานศูนย์เล็งหน้าทรงสามเหลี่ยม (Front Sight Tower)
createGunPart("FrontSightBase", Vector3.new(0.22, 0.48, 0.18), Color3.fromRGB(28, 30, 34), Enum.Material.Metal, CFrame.new(0, 0.34, -3.3))

-- แท่งศูนย์เล็งหน้าเรืองแสง Tritium สีเขียว (Tritium Dot Pin)
createGunPart("FrontSightPin", Vector3.new(0.06, 0.14, 0.06), Color3.fromRGB(60, 255, 60), Enum.Material.Neon, CFrame.new(0, 0.46, -3.3))

-- แม็กกาซีนกล้วย 30 นัด (Signature Curved Banana Magazine)
createGunPart("MagUpper", Vector3.new(0.28, 0.75, 0.55), Color3.fromRGB(135, 62, 28), Enum.Material.SmoothPlastic, CFrame.new(0, -0.55, -0.32) * CFrame.Angles(math.rad(10), 0, 0))
createGunPart("MagLower", Vector3.new(0.26, 0.75, 0.52), Color3.fromRGB(135, 62, 28), Enum.Material.SmoothPlastic, CFrame.new(0, -1.15, -0.48) * CFrame.Angles(math.rad(24), 0, 0))

-- ด้ามจับปืน (Pistol Grip) - ไม้เอียงรับมือ
createGunPart("PistolGrip", Vector3.new(0.32, 0.95, 0.48), Color3.fromRGB(115, 55, 22), Enum.Material.Wood, CFrame.new(0, -0.5, 0.52) * CFrame.Angles(math.rad(-18), 0, 0))

-- พานท้ายปืน (Classic Wooden Buttstock) - ไม้เนื้อแข็ง
createGunPart("Stock", Vector3.new(0.35, 0.9, 1.8), Color3.fromRGB(120, 58, 24), Enum.Material.Wood, CFrame.new(0, -0.05, 1.6) * CFrame.Angles(math.rad(-4), 0, 0))

-- คันรั้งลูกเลื่อนด้านขวา (Charging Handle)
createGunPart("ChargingHandle", Vector3.new(0.22, 0.12, 0.14), Color3.fromRGB(50, 52, 58), Enum.Material.Metal, CFrame.new(0.25, 0.12, -0.2))

-- แสงแฟลชประกายไฟปากกระบอกปืน (Muzzle Flash)
local muzzleFlash = createGunPart("MuzzleFlash", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(255, 190, 50), Enum.Material.Neon, CFrame.new(0, 0.05, -3.85))
muzzleFlash.Transparency = 1

local flashLight = Instance.new("PointLight")
flashLight.Color = Color3.fromRGB(255, 185, 50)
flashLight.Range = 22
flashLight.Brightness = 0
flashLight.Parent = muzzleFlash

----------------------------------------------------------------------
-- 3. ตำแหน่งและมุมกล้อง (HIPFIRE VS ADS AIMING)
----------------------------------------------------------------------
local HIP_OFFSET = CFrame.new(0.62, -0.58, -1.35) * CFrame.Angles(math.rad(-2), math.rad(-3), math.rad(1))
local ADS_OFFSET = CFrame.new(0, -0.46, -1.2) * CFrame.Angles(0, 0, 0) -- ศูนย์หน้า-หลังเรียงตรงกึ่งกลางสายตาพอดี!

local currentOffset = HIP_OFFSET
local isAiming = false
local recoilZ = 0
local recoilRotX = 0
local recoilRotY = 0
local swayTimer = 0

----------------------------------------------------------------------
-- 4. ข้อมูลปืน AK-47 & กระสุน
----------------------------------------------------------------------
local maxClip = 30
local clipAmmo = 30
local reserveAmmo = 180
local isReloading = false
local isFiring = false
local fireCooldown = false
local FIRE_RATE = 0.10 -- 600 RPM ฟูลออโต้
local BASE_DAMAGE = 45 -- ยิงตัว 45, ยิงหัวคูณ 2.5 = 112.5 (ยิงหัวนัดเดียวดับ!)

----------------------------------------------------------------------
-- 5. HUD หน้าจอเกม (HUD & UI)
----------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AK47_HUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = pGui

-- เป้าเล็ง Crosshair 4 ทิศทาง
local crosshairGui = Instance.new("Frame")
crosshairGui.Name = "CrosshairGui"
crosshairGui.Size = UDim2.new(0, 40, 0, 40)
crosshairGui.Position = UDim2.new(0.5, -20, 0.5, -20)
crosshairGui.BackgroundTransparency = 1
crosshairGui.Parent = screenGui

local chDot = Instance.new("Frame")
chDot.Size = UDim2.new(0, 4, 0, 4)
chDot.Position = UDim2.new(0.5, -2, 0.5, -2)
chDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
chDot.BorderSizePixel = 0
chDot.Parent = crosshairGui

local chTop = Instance.new("Frame")
chTop.Size = UDim2.new(0, 2, 0, 8)
chTop.Position = UDim2.new(0.5, -1, 0.5, -14)
chTop.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
chTop.BorderSizePixel = 0
chTop.Parent = crosshairGui

local chBottom = Instance.new("Frame")
chBottom.Size = UDim2.new(0, 2, 0, 8)
chBottom.Position = UDim2.new(0.5, -1, 0.5, 6)
chBottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
chBottom.BorderSizePixel = 0
chBottom.Parent = crosshairGui

local chLeft = Instance.new("Frame")
chLeft.Size = UDim2.new(0, 8, 0, 2)
chLeft.Position = UDim2.new(0.5, -14, 0.5, -1)
chLeft.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
chLeft.BorderSizePixel = 0
chLeft.Parent = crosshairGui

local chRight = Instance.new("Frame")
chRight.Size = UDim2.new(0, 8, 0, 2)
chRight.Position = UDim2.new(0.5, 6, 0.5, -1)
chRight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
chRight.BorderSizePixel = 0
chRight.Parent = crosshairGui

-- Hitmarker เมื่อยิงโดน
local hitmarker = Instance.new("ImageLabel")
hitmarker.Size = UDim2.new(0, 28, 0, 28)
hitmarker.Position = UDim2.new(0.5, -14, 0.5, -14)
hitmarker.BackgroundTransparency = 1
hitmarker.Image = "rbxassetid://6732495498"
hitmarker.ImageColor3 = Color3.fromRGB(255, 255, 255)
hitmarker.ImageTransparency = 1
hitmarker.Parent = screenGui

-- กล่องข้อมูลปืน (มุมขวาล่าง)
local gunCard = Instance.new("Frame")
gunCard.Size = UDim2.new(0, 260, 0, 95)
gunCard.Position = UDim2.new(1, -280, 1, -115)
gunCard.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
gunCard.BackgroundTransparency = 0.25
gunCard.BorderSizePixel = 0
gunCard.Parent = screenGui
Instance.new("UICorner", gunCard).CornerRadius = UDim.new(0, 10)

local gunBorder = Instance.new("UIStroke", gunCard)
gunBorder.Color = Color3.fromRGB(220, 160, 50)
gunBorder.Thickness = 1.5

local gunNameLabel = Instance.new("TextLabel")
gunNameLabel.Size = UDim2.new(1, -20, 0, 24)
gunNameLabel.Position = UDim2.new(0, 12, 0, 8)
gunNameLabel.BackgroundTransparency = 1
gunNameLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
gunNameLabel.Font = Enum.Font.GothamBold
gunNameLabel.TextSize = 18
gunNameLabel.TextXAlignment = Enum.TextXAlignment.Left
gunNameLabel.Text = "AK-47 KALASHNIKOV"
gunNameLabel.Parent = gunCard

local caliberLabel = Instance.new("TextLabel")
caliberLabel.Size = UDim2.new(1, -20, 0, 16)
caliberLabel.Position = UDim2.new(0, 12, 0, 32)
caliberLabel.BackgroundTransparency = 1
caliberLabel.TextColor3 = Color3.fromRGB(160, 180, 200)
caliberLabel.Font = Enum.Font.Gotham
caliberLabel.TextSize = 12
caliberLabel.TextXAlignment = Enum.TextXAlignment.Left
caliberLabel.Text = "7.62 x 39mm | FULL-AUTO"
caliberLabel.Parent = gunCard

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Size = UDim2.new(1, -20, 0, 36)
ammoLabel.Position = UDim2.new(0, 12, 0, 50)
ammoLabel.BackgroundTransparency = 1
ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextSize = 28
ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
ammoLabel.Text = "30 / 180"
ammoLabel.Parent = gunCard

-- กล่องคำแนะนำปุ่มล่างจอ
local hintCard = Instance.new("Frame")
hintCard.Size = UDim2.new(0, 520, 0, 32)
hintCard.Position = UDim2.new(0.5, -260, 1, -45)
hintCard.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
hintCard.BackgroundTransparency = 0.4
hintCard.BorderSizePixel = 0
hintCard.Parent = screenGui
Instance.new("UICorner", hintCard).CornerRadius = UDim.new(0, 6)

local hintText = Instance.new("TextLabel")
hintText.Size = UDim2.new(1, 0, 1, 0)
hintText.BackgroundTransparency = 1
hintText.TextColor3 = Color3.fromRGB(220, 230, 245)
hintText.Font = Enum.Font.Gotham
hintText.TextSize = 13
hintText.Text = "🖱️ [คลิกซ้ายค้าง] รัว Auto | 🎯 [คลิกขวาค้าง] เล็งศูนย์ปืน ADS | 🔄 [R] รีโหลดกระสุน"
hintText.Parent = hintCard

local function updateAmmoUI()
    if isReloading then
        ammoLabel.Text = "RELOADING..."
        ammoLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    else
        ammoLabel.Text = string.format("%d / %d", clipAmmo, reserveAmmo)
        ammoLabel.TextColor3 = (clipAmmo <= 5) and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(255, 255, 255)
    end
end

----------------------------------------------------------------------
-- 6. ระบบเสียงปืน (PUNCHY GUNSHOT SOUNDS)
----------------------------------------------------------------------
local function playGunshotSound()
    -- เสียงปืนกระแทกหนักแน่น (Layer 1: Punchy Shot)
    local s1 = Instance.new("Sound")
    s1.SoundId = "rbxassetid://9114221147"
    s1.Volume = 1.3
    s1.PlaybackSpeed = math.random(88, 96) / 100 -- ลด Pitch ให้ได้เสียงทุ้มแน่นของ 7.62mm
    s1.Parent = camera
    s1:Play()
    Debris:AddItem(s1, 1.2)

    -- เสียงกังวานและสะท้อน (Layer 2: Echo / Rifle Body)
    local s2 = Instance.new("Sound")
    s2.SoundId = "rbxassetid://9114221808"
    s2.Volume = 0.75
    s2.PlaybackSpeed = math.random(95, 105) / 100
    s2.Parent = camera
    s2:Play()
    Debris:AddItem(s2, 1.2)
end

local function playReloadSound()
    local rSound = Instance.new("Sound")
    rSound.SoundId = "rbxassetid://9114221949"
    rSound.Volume = 1.0
    rSound.Parent = camera
    rSound:Play()
    Debris:AddItem(rSound, 2.0)
end

local function playDryFireSound()
    local dSound = Instance.new("Sound")
    dSound.SoundId = "rbxassetid://9114221949"
    dSound.Volume = 0.5
    dSound.PlaybackSpeed = 2.0
    dSound.Parent = camera
    dSound:Play()
    Debris:AddItem(dSound, 0.8)
end

local function playHitSound(isHeadshot)
    local hSound = Instance.new("Sound")
    hSound.SoundId = isHeadshot and "rbxassetid://9114223170" or "rbxassetid://9114221147"
    hSound.Volume = isHeadshot and 1.2 or 0.5
    hSound.PlaybackSpeed = isHeadshot and 1.5 or 2.2
    hSound.Parent = camera
    hSound:Play()
    Debris:AddItem(hSound, 1.0)
end

----------------------------------------------------------------------
-- 7. ระบบรีโหลดกระสุน (RELOAD)
----------------------------------------------------------------------
local function reloadWeapon()
    if isReloading or clipAmmo == maxClip or reserveAmmo <= 0 then return end
    isReloading = true
    updateAmmoUI()
    playReloadSound()

    task.wait(1.8)
    local needed = maxClip - clipAmmo
    local toAdd = math.min(needed, reserveAmmo)
    clipAmmo = clipAmmo + toAdd
    reserveAmmo = reserveAmmo - toAdd
    isReloading = false
    updateAmmoUI()
end

----------------------------------------------------------------------
-- 8. ตัวเลขดาเมจลอยบนจอ (FLOATING DAMAGE POPUP)
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
    bb.Size = UDim2.new(0, 160, 0, 36)
    bb.AlwaysOnTop = true
    bb.Parent = pPart

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = isHeadshot and Color3.fromRGB(255, 45, 45) or Color3.fromRGB(255, 185, 45)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = isHeadshot and 22 or 16
    label.Text = isHeadshot and ("💥 " .. damage .. " HEADSHOT!") or tostring(damage)
    label.Parent = bb

    TweenService:Create(pPart, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = pPart.CFrame + Vector3.new(0, 2.5, 0)
    }):Play()
    TweenService:Create(label, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        TextTransparency = 1,
        TextStrokeTransparency = 1
    }):Play()

    Debris:AddItem(pPart, 0.85)
end

----------------------------------------------------------------------
-- 9. ยิงปืน (SHOOTING MECHANICS & RAYCAST)
----------------------------------------------------------------------
local function shootWeapon()
    if fireCooldown or isReloading then return end
    if clipAmmo <= 0 then
        playDryFireSound()
        reloadWeapon()
        return
    end

    fireCooldown = true
    clipAmmo = clipAmmo - 1
    updateAmmoUI()

    -- 1. เล่นเสียงปืนกระหึ่ม
    playGunshotSound()

    -- 2. แรงถีบปืนสะบัด (Recoil Kickback)
    recoilZ = 0.42
    recoilRotX = isAiming and 3.8 or 6.8
    recoilRotY = (math.random() - 0.5) * 1.6

    -- 3. แฟลชปากกระบอกปืนวาบ
    muzzleFlash.Transparency = 0
    flashLight.Brightness = 4.5
    task.delay(0.04, function()
        muzzleFlash.Transparency = 1
        flashLight.Brightness = 0
    end)

    -- 4. สั่นกล้องผู้เล่นเล็กน้อย
    camera.CFrame = camera.CFrame * CFrame.Angles(
        math.rad(isAiming and 0.35 or 0.75),
        math.rad((math.random() - 0.5) * 0.4),
        0
    )

    -- 5. ยิง Raycast ตรวจจับเป้าหมาย
    local rayOrigin = camera.CFrame.Position
    local rayDirection = camera.CFrame.LookVector * 500

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { player.Character, viewmodel }
    rayParams.FilterType = RaycastFilterType.Exclude

    local hit = Workspace:Raycast(rayOrigin, rayDirection, rayParams)

    -- สร้างเส้นทางวิถีกระสุนเรืองแสง (Bullet Tracer Beam)
    local tracerEnd = hit and hit.Position or (rayOrigin + rayDirection)
    local muzzlePos = muzzleFlash.Position
    local tracerDist = (tracerEnd - muzzlePos).Magnitude

    local tracer = Instance.new("Part")
    tracer.Size = Vector3.new(0.08, 0.08, tracerDist)
    tracer.CFrame = CFrame.lookAt((muzzlePos + tracerEnd) / 2, tracerEnd)
    tracer.Color = Color3.fromRGB(255, 215, 90)
    tracer.Material = Enum.Material.Neon
    tracer.CanCollide = false
    tracer.Anchored = true
    tracer.Parent = Workspace
    Debris:AddItem(tracer, 0.04)

    -- 6. ตรวจจับการโดนซอมบี้
    if hit and hit.Instance then
        local hitPart = hit.Instance
        local hitZombie = hitPart:FindFirstAncestorOfClass("Model")
        if hitZombie and hitZombie.Name:sub(1, 7) == "Zombie_" then
            local isHeadshot = (hitPart.Name == "Head" or hitPart.Name == "Eyes")
            local dmg = isHeadshot and math.floor(BASE_DAMAGE * 2.5) or BASE_DAMAGE

            -- ส่งข้อมูลไปยัง Server
            zombieHitEvent:FireServer(hitPart, BASE_DAMAGE, isHeadshot)

            -- เสียงและเอฟเฟกต์ยิงโดน
            playHitSound(isHeadshot)
            showDamagePopup(hit.Position, dmg, isHeadshot)

            -- Hitmarker แสดงบนหน้าจอ
            hitmarker.ImageColor3 = isHeadshot and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 190, 50)
            hitmarker.ImageTransparency = 0
            hitmarker.Size = isHeadshot and UDim2.new(0, 36, 0, 36) or UDim2.new(0, 26, 0, 26)
            hitmarker.Position = isHeadshot and UDim2.new(0.5, -18, 0.5, -18) or UDim2.new(0.5, -13, 0.5, -13)
            task.delay(0.1, function()
                hitmarker.ImageTransparency = 1
            end)
        else
            -- ยิงโดนพื้น/กำแพง -> สร้างประกายไฟฝุ่น
            local spark = Instance.new("Part")
            spark.Size = Vector3.new(0.2, 0.2, 0.2)
            spark.CFrame = CFrame.new(hit.Position)
            spark.Color = Color3.fromRGB(255, 240, 150)
            spark.Material = Enum.Material.Neon
            spark.Anchored = true
            spark.CanCollide = false
            spark.Parent = Workspace
            Debris:AddItem(spark, 0.06)
        end
    end

    task.wait(FIRE_RATE)
    fireCooldown = false
end

----------------------------------------------------------------------
-- 10. ระบบควบคุมเมาส์และคีย์บอร์ด (MOUSE & KEYBOARD INPUTS)
----------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- คลิกซ้าย: เริ่มยิง (ฟูลออโต้ค้าง)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isFiring = true
        task.spawn(function()
            while isFiring do
                shootWeapon()
                task.wait(FIRE_RATE)
            end
        end)
    -- คลิกขวาค้าง: เล็งประณีตผ่านศูนย์เหล็กจริง (ADS)
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = true
        crosshairGui.Visible = false -- ซ่อน Crosshair เมื่อเล็ง เพื่อให้มองผ่านศูนย์ปืนจริง
    -- กด R: รีโหลด
    elseif input.KeyCode == Enum.KeyCode.R then
        reloadWeapon()
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isFiring = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = false
        crosshairGui.Visible = true
    end
end)

----------------------------------------------------------------------
-- 11. อัปเดตตำแหน่งปืนทุกเฟรม (RENDER STEPPED LOOP)
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    -- เล็ง ADS vs Hipfire
    local targetOffset = isAiming and ADS_OFFSET or HIP_OFFSET
    currentOffset = currentOffset:Lerp(targetOffset, math.clamp(dt * 16, 0, 1))

    -- ซูมกล้อง FOV ขณะเล็ง
    local targetFov = isAiming and 52 or 70
    camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * math.clamp(dt * 14, 0, 1)

    -- การคืนตัวของแรงถีบ (Recoil Spring Recovery)
    recoilZ = recoilZ * math.exp(-dt * 22)
    recoilRotX = recoilRotX * math.exp(-dt * 20)
    recoilRotY = recoilRotY * math.exp(-dt * 20)

    -- การโยกตัวตามการหายใจและก้าวเดิน (Breathing & Movement Sway)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local vel = hrp and hrp.AssemblyLinearVelocity.Magnitude or 0
    local swayFreq = (vel > 1.5) and 10 or 3
    local swayAmp = (vel > 1.5) and 0.035 or 0.012
    if isAiming then swayAmp = swayAmp * 0.18 end

    swayTimer = swayTimer + dt * swayFreq
    local swayX = math.sin(swayTimer) * swayAmp
    local swayY = math.cos(swayTimer * 2) * (swayAmp * 0.5)

    -- รวม CFrame ทั้งหมด
    local recoilCFrame = CFrame.new(swayX, swayY, recoilZ) * CFrame.Angles(
        math.rad(recoilRotX),
        math.rad(recoilRotY),
        0
    )

    local finalRootCF = camera.CFrame * currentOffset * recoilCFrame
    gunRoot.CFrame = finalRootCF

    -- ปรับตำแหน่งชิ้นส่วนทั้งหมดของปืน AK-47
    for part, relCF in pairs(partOffsets) do
        part.CFrame = finalRootCF * relCF
    end
end)

print("=========================================================")
print("🔫 [AK-47 Controller] ไรเฟิลจู่โจม AK-47 และระบบเสียงปืนพร้อมใช้งาน 100%!")
print("=========================================================")
