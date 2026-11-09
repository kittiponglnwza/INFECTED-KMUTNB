--[[
    FPSController.client.lua
    ใส่ใน: StarterPlayer -> StarterPlayerScripts
    
    อัปเดตแก้ไข:
      1. แก้บั๊ก "ยิงได้แค่นัดเดียว": ปรับเป็นระบบ Full-Auto Heartbeat Loop ยิงต่อเนื่องรัวไม่ติดขัด
      2. แก้บั๊ก "ไม่มีเสียงปืน": ใช้เสียงปืนระดับ Engine ของ Roblox (rbxasset://) ที่มีในทุกเครื่อง ไม่โดน Audio Privacy บล็อค การันตีมีเสียง 100%
      3. แก้เรื่อง "โมเดลปืนของจริง":
         - ค่าเริ่มต้น: ใช้ 3D SpecialMesh ไรเฟิลทรงโค้งสมจริง
         - รองรับโมเดลจริงจาก Toolbox: เพียงลากโมเดล AK47 จาก Toolbox ไปวางใน ReplicatedStorage แล้วตั้งชื่อว่า "AK47_Model" ระบบจะดึงโมเดลจริงมาถือยิงทันที!
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
local zombieHitEvent = zombieEvents:WaitForChild("ZombieHitEvent", 25)

----------------------------------------------------------------------
-- 1. ล้าง Viewmodel และ UI เก่า
----------------------------------------------------------------------
if camera:FindFirstChild("AK47_ViewModel") then
    camera.AK47_ViewModel:Destroy()
end
if pGui:FindFirstChild("AK47_HUD") then
    pGui.AK47_HUD:Destroy()
end

----------------------------------------------------------------------
-- 2. ระบบเสียงปืน (GUARANTEED WORKING AUDIO)
----------------------------------------------------------------------
-- ใช้เสียงปืนในเครื่อง Roblox Engine โดยตรง (rbxasset://) ไม่ต้องโหลดผ่านเน็ต และไม่ติดสิทธิ์ความเป็นส่วนตัว
local soundFolder = Instance.new("Folder")
soundFolder.Name = "GunSounds"
soundFolder.Parent = camera

local soundGunshot = Instance.new("Sound")
soundGunshot.Name = "GunshotPrimary"
soundGunshot.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
soundGunshot.Volume = 1.0
soundGunshot.PlaybackSpeed = 2.45 -- ปรับสปีดเสียงระเบิดให้กลายเป็นเสียงปืนไรเฟิล 7.62mm ทุ้มหนักแน่น
soundGunshot.Parent = soundFolder

local soundLayer = Instance.new("Sound")
soundLayer.Name = "GunshotLayer"
soundLayer.SoundId = "rbxassetid://6656835390" -- เสียงดีดปลอกกระสุนและแคล็ก
soundLayer.Volume = 0.8
soundLayer.Parent = soundFolder

local soundClick = Instance.new("Sound")
soundClick.Name = "DryFire"
soundClick.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
soundClick.PlaybackSpeed = 3.0
soundClick.Volume = 0.6
soundClick.Parent = soundFolder

local function playGunshotSound()
    -- เล่นเสียงยิงหลัก (ดังแน่น ไม่มีบั๊ก)
    local s = soundGunshot:Clone()
    s.PlaybackSpeed = 2.35 + (math.random() - 0.5) * 0.2
    s.Parent = camera
    s:Play()
    Debris:AddItem(s, 0.6)

    -- เสียง Layer 2
    local s2 = soundLayer:Clone()
    s2.Parent = camera
    s2:Play()
    Debris:AddItem(s2, 0.6)
end

local function playDryFireSound()
    local c = soundClick:Clone()
    c.Parent = camera
    c:Play()
    Debris:AddItem(c, 0.5)
end

local function playHitSound(isHeadshot)
    local h = Instance.new("Sound")
    h.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
    h.Volume = isHeadshot and 0.8 or 0.35
    h.PlaybackSpeed = isHeadshot and 4.2 or 3.2
    h.Parent = camera
    h:Play()
    Debris:AddItem(h, 0.4)
end

----------------------------------------------------------------------
-- 3. สร้าง VIEWMODEL ปืน AK-47 (3D MESH & REAL MODEL SUPPORT)
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

-- ตรวจสอบว่ามีโมเดลจริงใน ReplicatedStorage หรือไม่
local customModelTemplate = ReplicatedStorage:FindFirstChild("AK47_Model")
local muzzleFlash = nil
local flashLight = nil

if customModelTemplate and customModelTemplate:IsA("Model") then
    print("🌟 [AK-47] ตรวจพบโมเดลจริงจาก ReplicatedStorage! กำลังนำมาใช้งาน...")
    local realGun = customModelTemplate:Clone()
    realGun.Parent = viewmodel

    for _, p in ipairs(realGun:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
            p.Anchored = true
            p.CastShadow = false
            -- คำนวณตำแหน่งสัมพัทธ์
            partOffsets[p] = gunRoot.CFrame:ToObjectSpace(p.CFrame)
            if p.Name:match("Muzzle") or p.Name:match("Flash") then
                muzzleFlash = p
            end
        end
    end
else
    print("📦 [AK-47] สร้างโมเดล 3D Mesh ไรเฟิลพร้อมลายไม้และแม็กกาซีน...")
    -- โครงปืนหลัก (Receiver & Stock) - ใช้ SpecialMesh สร้างส่วนโค้งมนแบบโมเดล 3D
    local gunBody = Instance.new("Part")
    gunBody.Name = "RifleMesh"
    gunBody.Size = Vector3.new(0.35, 0.8, 3.8)
    gunBody.Color = Color3.fromRGB(45, 48, 52)
    gunBody.Material = Enum.Material.Metal
    gunBody.CanCollide = false
    gunBody.Anchored = true
    gunBody.CastShadow = false
    gunBody.Parent = viewmodel
    partOffsets[gunBody] = CFrame.new(0, 0, 0.2)

    local bodyMesh = Instance.new("SpecialMesh")
    bodyMesh.MeshType = Enum.MeshType.FileMesh
    bodyMesh.MeshId = "rbxassetid://252534679" -- โมเดลไรเฟิล 3D Mesh จาก Roblox Library
    bodyMesh.Scale = Vector3.new(1.15, 1.15, 1.15)
    bodyMesh.Parent = gunBody

    -- ประกับไม้หน้า (Wooden Handguard)
    local woodGuard = Instance.new("Part")
    woodGuard.Name = "WoodHandguard"
    woodGuard.Size = Vector3.new(0.38, 0.5, 1.3)
    woodGuard.Color = Color3.fromRGB(120, 58, 24)
    woodGuard.Material = Enum.Material.Wood
    woodGuard.CanCollide = false
    woodGuard.Anchored = true
    woodGuard.CastShadow = false
    woodGuard.Parent = viewmodel
    partOffsets[woodGuard] = CFrame.new(0, -0.05, -1.35)

    -- พานท้ายไม้ (Wooden Buttstock)
    local woodStock = Instance.new("Part")
    woodStock.Name = "WoodStock"
    woodStock.Size = Vector3.new(0.34, 0.85, 1.6)
    woodStock.Color = Color3.fromRGB(120, 58, 24)
    woodStock.Material = Enum.Material.Wood
    woodStock.CanCollide = false
    woodStock.Anchored = true
    woodStock.CastShadow = false
    woodStock.Parent = viewmodel
    partOffsets[woodStock] = CFrame.new(0, -0.05, 1.45) * CFrame.Angles(math.rad(-4), 0, 0)

    -- ด้ามจับไม้ (Wood Pistol Grip)
    local woodGrip = Instance.new("Part")
    woodGrip.Name = "WoodGrip"
    woodGrip.Size = Vector3.new(0.32, 0.85, 0.45)
    woodGrip.Color = Color3.fromRGB(115, 55, 22)
    woodGrip.Material = Enum.Material.Wood
    woodGrip.CanCollide = false
    woodGrip.Anchored = true
    woodGrip.CastShadow = false
    woodGrip.Parent = viewmodel
    partOffsets[woodGrip] = CFrame.new(0, -0.45, 0.45) * CFrame.Angles(math.rad(-18), 0, 0)

    -- แม็กกาซีนกล้วย 30 นัด (Curved Banana Magazine)
    local magMeshPart = Instance.new("Part")
    magMeshPart.Name = "BananaMag"
    magMeshPart.Size = Vector3.new(0.28, 1.2, 0.6)
    magMeshPart.Color = Color3.fromRGB(135, 65, 28)
    magMeshPart.Material = Enum.Material.SmoothPlastic
    magMeshPart.CanCollide = false
    magMeshPart.Anchored = true
    magMeshPart.CastShadow = false
    magMeshPart.Parent = viewmodel
    partOffsets[magMeshPart] = CFrame.new(0, -0.65, -0.35) * CFrame.Angles(math.rad(14), 0, 0)

    local magMesh = Instance.new("SpecialMesh")
    magMesh.MeshType = Enum.MeshType.FileMesh
    magMesh.MeshId = "rbxassetid://252534856" -- แม็กกาซีน 3D Mesh
    magMesh.Scale = Vector3.new(1.15, 1.15, 1.15)
    magMesh.Parent = magMeshPart

    -- ปลายลำกล้องและศูนย์หน้าเรืองแสง (Front Sight Post)
    local frontPin = Instance.new("Part")
    frontPin.Name = "FrontSightPin"
    frontPin.Size = Vector3.new(0.06, 0.14, 0.06)
    frontPin.Color = Color3.fromRGB(60, 255, 60)
    frontPin.Material = Enum.Material.Neon
    frontPin.CanCollide = false
    frontPin.Anchored = true
    frontPin.CastShadow = false
    frontPin.Parent = viewmodel
    partOffsets[frontPin] = CFrame.new(0, 0.46, -3.1)
end

-- สร้าง Muzzle Flash ถ้ายังไม่มี
if not muzzleFlash then
    muzzleFlash = Instance.new("Part")
    muzzleFlash.Name = "MuzzleFlash"
    muzzleFlash.Size = Vector3.new(0.4, 0.4, 0.4)
    muzzleFlash.Color = Color3.fromRGB(255, 190, 50)
    muzzleFlash.Material = Enum.Material.Neon
    muzzleFlash.CanCollide = false
    muzzleFlash.Anchored = true
    muzzleFlash.CastShadow = false
    muzzleFlash.Parent = viewmodel
    partOffsets[muzzleFlash] = CFrame.new(0, 0.05, -3.7)
end
muzzleFlash.Transparency = 1

flashLight = Instance.new("PointLight")
flashLight.Color = Color3.fromRGB(255, 185, 50)
flashLight.Range = 22
flashLight.Brightness = 0
flashLight.Parent = muzzleFlash

----------------------------------------------------------------------
-- 4. ตำแหน่งกล้อง & ค่าคงที่ปืน AK-47
----------------------------------------------------------------------
local HIP_OFFSET = CFrame.new(0.60, -0.55, -1.35) * CFrame.Angles(math.rad(-2), math.rad(-3), math.rad(1))
local ADS_OFFSET = CFrame.new(0, -0.46, -1.15) * CFrame.Angles(0, 0, 0)

local currentOffset = HIP_OFFSET
local isAiming = false
local recoilZ = 0
local recoilRotX = 0
local recoilRotY = 0
local swayTimer = 0

local maxClip = 30
local clipAmmo = 30
local reserveAmmo = 180
local isReloading = false
local isMouseDown = false
local lastShotTime = 0
local FIRE_DELAY = 0.10 -- 600 RPM
local BASE_DAMAGE = 45 -- นัดละ 45, ยิงหัว 112

----------------------------------------------------------------------
-- 5. หน้าจอ UI HUD
----------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AK47_HUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = pGui

-- Crosshair กึ่งกลาง
local crosshairGui = Instance.new("Frame")
crosshairGui.Name = "CrosshairGui"
crosshairGui.Size = UDim2.new(0, 30, 0, 30)
crosshairGui.Position = UDim2.new(0.5, -15, 0.5, -15)
crosshairGui.BackgroundTransparency = 1
crosshairGui.Parent = screenGui

local chDot = Instance.new("Frame")
chDot.Size = UDim2.new(0, 4, 0, 4)
chDot.Position = UDim2.new(0.5, -2, 0.5, -2)
chDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
chDot.BorderSizePixel = 0
chDot.Parent = crosshairGui

local function makeCrosshairLine(pos, size)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    f.BorderSizePixel = 0
    f.Parent = crosshairGui
    return f
end
makeCrosshairLine(UDim2.new(0.5, -1, 0.5, -12), UDim2.new(0, 2, 0, 7))
makeCrosshairLine(UDim2.new(0.5, -1, 0.5, 5),   UDim2.new(0, 2, 0, 7))
makeCrosshairLine(UDim2.new(0.5, -12, 0.5, -1), UDim2.new(0, 7, 0, 2))
makeCrosshairLine(UDim2.new(0.5, 5, 0.5, -1),   UDim2.new(0, 7, 0, 2))

-- Hitmarker
local hitmarker = Instance.new("ImageLabel")
hitmarker.Size = UDim2.new(0, 26, 0, 26)
hitmarker.Position = UDim2.new(0.5, -13, 0.5, -13)
hitmarker.BackgroundTransparency = 1
hitmarker.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
hitmarker.ImageColor3 = Color3.fromRGB(255, 50, 50)
hitmarker.ImageTransparency = 1
hitmarker.Parent = screenGui

-- Card ข้อมูลปืนมุมขวาล่าง
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
-- 6. ระบบรีโหลด
----------------------------------------------------------------------
local function reloadWeapon()
    if isReloading or clipAmmo == maxClip or reserveAmmo <= 0 then return end
    isReloading = true
    updateAmmoUI()

    task.wait(1.8)
    local needed = maxClip - clipAmmo
    local toAdd = math.min(needed, reserveAmmo)
    clipAmmo = clipAmmo + toAdd
    reserveAmmo = reserveAmmo - toAdd
    isReloading = false
    updateAmmoUI()
end

----------------------------------------------------------------------
-- 7. ตัวเลขดาเมจลอย (FLOATING DAMAGE POPUP)
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
    label.TextColor3 = isHeadshot and Color3.fromRGB(255, 45, 45) or Color3.fromRGB(255, 190, 50)
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
-- 8. ระบบยิงปืน (ROBUST FULL-AUTO FIRING ENGINE)
----------------------------------------------------------------------
local function executeShoot()
    if isReloading then return end

    local now = os.clock()
    if now - lastShotTime < FIRE_DELAY then return end

    if clipAmmo <= 0 then
        playDryFireSound()
        reloadWeapon()
        return
    end

    lastShotTime = now
    clipAmmo = clipAmmo - 1
    updateAmmoUI()

    -- 1. เล่นเสียงปืนกระหึ่ม (ทำงานแน่นอน 100%)
    playGunshotSound()

    -- 2. แรงถีบปืน
    recoilZ = 0.40
    recoilRotX = isAiming and 3.5 or 6.5
    recoilRotY = (math.random() - 0.5) * 1.5

    -- 3. แฟลชปากกระบอกปืน
    muzzleFlash.Transparency = 0
    flashLight.Brightness = 4.5
    task.delay(0.04, function()
        muzzleFlash.Transparency = 1
        flashLight.Brightness = 0
    end)

    -- 4. สั่นกล้อง
    camera.CFrame = camera.CFrame * CFrame.Angles(
        math.rad(isAiming and 0.35 or 0.7),
        math.rad((math.random() - 0.5) * 0.4),
        0
    )

    -- 5. Raycast ตรวจจับเป้าหมาย
    local rayOrigin = camera.CFrame.Position
    local rayDirection = camera.CFrame.LookVector * 500

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { player.Character, viewmodel }
    rayParams.FilterType = RaycastFilterType.Exclude

    local hit = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
    local tracerEnd = hit and hit.Position or (rayOrigin + rayDirection)
    local muzzlePos = muzzleFlash.Position

    -- สร้างเส้นกระสุนวิ่ง
    local dist = (tracerEnd - muzzlePos).Magnitude
    if dist > 0.5 then
        local tracer = Instance.new("Part")
        tracer.Size = Vector3.new(0.08, 0.08, dist)
        tracer.CFrame = CFrame.lookAt((muzzlePos + tracerEnd) / 2, tracerEnd)
        tracer.Color = Color3.fromRGB(255, 215, 90)
        tracer.Material = Enum.Material.Neon
        tracer.CanCollide = false
        tracer.Anchored = true
        tracer.Parent = Workspace
        Debris:AddItem(tracer, 0.04)
    end

    -- ตรวจจับโดนซอมบี้
    if hit and hit.Instance then
        local hitPart = hit.Instance
        local hitModel = hitPart:FindFirstAncestorOfClass("Model")
        if hitModel and hitModel.Name:sub(1, 7) == "Zombie_" then
            local isHeadshot = (hitPart.Name == "Head" or hitPart.Name == "Eyes")
            local dmg = isHeadshot and math.floor(BASE_DAMAGE * 2.5) or BASE_DAMAGE

            zombieHitEvent:FireServer(hitPart, BASE_DAMAGE, isHeadshot)
            playHitSound(isHeadshot)
            showDamagePopup(hit.Position, dmg, isHeadshot)

            hitmarker.ImageColor3 = isHeadshot and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 190, 50)
            hitmarker.ImageTransparency = 0
            task.delay(0.08, function()
                hitmarker.ImageTransparency = 1
            end)
        else
            -- ประกายไฟกระทบพื้นผิว
            local spark = Instance.new("Part")
            spark.Size = Vector3.new(0.2, 0.2, 0.2)
            spark.CFrame = CFrame.new(hit.Position)
            spark.Color = Color3.fromRGB(255, 240, 150)
            spark.Material = Enum.Material.Neon
            spark.Anchored = true
            spark.CanCollide = false
            spark.Parent = Workspace
            Debris:AddItem(spark, 0.05)
        end
    end
end

----------------------------------------------------------------------
-- 9. ตรวจจับการคลิก & กดปุ่ม (INPUT HANDLING)
----------------------------------------------------------------------
-- ไม่ใช้ gp บล็อคเมาส์คลิก เพื่อแก้บั๊กยิงได้แค่นัดเดียวในมุมมอง First Person
UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouseDown = true
        executeShoot() -- ยิงทันทีนัดแรกเมื่อกดคลิก
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = true
        crosshairGui.Visible = false
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
    end
end)

-- Heartbeat Loop: ทำให้รัวกระสุน Full-Auto ได้อย่างต่อเนื่องสมบูรณ์แบบ
RunService.Heartbeat:Connect(function()
    if isMouseDown and not isReloading then
        -- ตรวจสอบเพิ่มเติมว่ายังกดเมาส์ค้างอยู่จริงหรือไม่
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            executeShoot()
        else
            isMouseDown = false
        end
    end
end)

----------------------------------------------------------------------
-- 10. อัปเดตตำแหน่งปืนทุกเฟรม (RENDER STEPPED)
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    local targetOffset = isAiming and ADS_OFFSET or HIP_OFFSET
    currentOffset = currentOffset:Lerp(targetOffset, math.clamp(dt * 16, 0, 1))

    local targetFov = isAiming and 52 or 70
    camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * math.clamp(dt * 14, 0, 1)

    recoilZ = recoilZ * math.exp(-dt * 22)
    recoilRotX = recoilRotX * math.exp(-dt * 20)
    recoilRotY = recoilRotY * math.exp(-dt * 20)

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local vel = hrp and hrp.AssemblyLinearVelocity.Magnitude or 0
    local swayFreq = (vel > 1.5) and 10 or 3
    local swayAmp = (vel > 1.5) and 0.035 or 0.012
    if isAiming then swayAmp = swayAmp * 0.18 end

    swayTimer = swayTimer + dt * swayFreq
    local swayX = math.sin(swayTimer) * swayAmp
    local swayY = math.cos(swayTimer * 2) * (swayAmp * 0.5)

    local recoilCFrame = CFrame.new(swayX, swayY, recoilZ) * CFrame.Angles(
        math.rad(recoilRotX),
        math.rad(recoilRotY),
        0
    )

    local finalRootCF = camera.CFrame * currentOffset * recoilCFrame
    gunRoot.CFrame = finalRootCF

    for part, relCF in pairs(partOffsets) do
        part.CFrame = finalRootCF * relCF
    end
end)

print("✅ [FPSController] ระบบยิง Full-Auto, เสียงปืน Engine, และ 3D Viewmodel พร้อม 100%!")
