--[[
    FPSController.client.lua
    ใส่ใน: StarterPlayer -> StarterPlayerScripts
    หน้าที่:
      1. ล็อคมุมมอง First Person 100%
      2. โมเดลปืนพก 3D Viewmodel ในมือผู้เล่น
      3. แอนิเมชันเล็งปืน (Aim Down Sights - ADS) เมื่อคลิกขวาค้าง ซูมกล้องและยกศูนย์เล็งขึ้นกลางจอ
      4. แอนิเมชันการยิง (Recoil Kickback, ปากกระบอกปืนวาบ Muzzle Flash, แรงสะบัดปืน)
      5. HUD กระสุน, เป้าเล็ง, และกระดานคะแนนทีม
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

player.CameraMode = Enum.CameraMode.LockFirstPerson

local zombieEvents = ReplicatedStorage:WaitForChild("ZombieGameEvents", 25)
local updateScoreboardEvent = zombieEvents:WaitForChild("UpdateScoreboard", 25)
local waveAnnounceEvent = zombieEvents:WaitForChild("WaveAnnounce", 25)
local zombieHitEvent = zombieEvents:WaitForChild("ZombieHitEvent", 25)

----------------------------------------------------------------------
-- 1. สร้าง 3D GUN VIEWMODEL (ปืนพกในมือมุมมองบุคคลที่หนึ่ง)
----------------------------------------------------------------------
local viewmodel = Instance.new("Model")
viewmodel.Name = "GunViewModel"
viewmodel.Parent = camera

local gunRoot = Instance.new("Part")
gunRoot.Name = "GunRoot"
gunRoot.Size = Vector3.new(0.4, 0.4, 0.4)
gunRoot.Transparency = 1
gunRoot.CanCollide = false
gunRoot.Anchored = true
gunRoot.Parent = viewmodel

-- ด้ามจับปืน (Grip)
local grip = Instance.new("Part")
grip.Name = "Grip"
grip.Size = Vector3.new(0.32, 0.85, 0.45)
grip.Color = Color3.fromRGB(30, 30, 32)
grip.Material = Enum.Material.SmoothPlastic
grip.CanCollide = false
grip.Anchored = true
grip.Parent = viewmodel

-- โครงปืนด้านบน (Slide)
local slide = Instance.new("Part")
slide.Name = "Slide"
slide.Size = Vector3.new(0.34, 0.42, 1.4)
slide.Color = Color3.fromRGB(55, 58, 62)
slide.Material = Enum.Material.Metal
slide.CanCollide = false
slide.Anchored = true
slide.Parent = viewmodel

-- ลำกล้องปืน (Barrel)
local barrel = Instance.new("Part")
barrel.Name = "Barrel"
barrel.Size = Vector3.new(0.24, 0.24, 0.5)
barrel.Color = Color3.fromRGB(20, 20, 20)
barrel.Material = Enum.Material.Metal
barrel.CanCollide = false
barrel.Anchored = true
barrel.Parent = viewmodel

-- ศูนย์เล็งหน้า (Front Sight) มีจุดเรืองแสงช่วยเล็ง
local frontSight = Instance.new("Part")
frontSight.Name = "FrontSight"
frontSight.Size = Vector3.new(0.08, 0.12, 0.12)
frontSight.Color = Color3.fromRGB(50, 255, 50)
frontSight.Material = Enum.Material.Neon
frontSight.CanCollide = false
frontSight.Anchored = true
frontSight.Parent = viewmodel

-- ศูนย์เล็งหลัง (Rear Sight)
local rearSight = Instance.new("Part")
rearSight.Name = "RearSight"
rearSight.Size = Vector3.new(0.28, 0.1, 0.1)
rearSight.Color = Color3.fromRGB(30, 30, 30)
rearSight.Material = Enum.Material.Metal
rearSight.CanCollide = false
rearSight.Anchored = true
rearSight.Parent = viewmodel

-- แสงประกายไฟปากกระบอกปืน (Muzzle Flash)
local muzzleFlash = Instance.new("Part")
muzzleFlash.Name = "MuzzleFlash"
muzzleFlash.Size = Vector3.new(0.4, 0.4, 0.4)
muzzleFlash.Color = Color3.fromRGB(255, 180, 40)
muzzleFlash.Material = Enum.Material.Neon
muzzleFlash.Transparency = 1
muzzleFlash.CanCollide = false
muzzleFlash.Anchored = true
muzzleFlash.Parent = viewmodel

local flashLight = Instance.new("PointLight")
flashLight.Color = Color3.fromRGB(255, 170, 40)
flashLight.Range = 16
flashLight.Brightness = 0
flashLight.Parent = muzzleFlash

----------------------------------------------------------------------
-- 2. ตำแหน่งปืน: ถือธรรมดา (HIPFIRE) vs เล็งประณีต (ADS)
----------------------------------------------------------------------
local HIP_OFFSET = CFrame.new(0.68, -0.65, -1.35) * CFrame.Angles(math.rad(-2), math.rad(-3), 0)
local ADS_OFFSET = CFrame.new(0, -0.34, -1.05)   * CFrame.Angles(0, 0, 0) -- ยกศูนย์ปืนขึ้นกึ่งกลางสายตาพอดี!

local currentOffset = HIP_OFFSET
local isAiming = false
local defaultFOV = 70
local adsFOV = 50

-- ค่าแรงถีบปืน (Recoil Spring)
local recoilOffsetZ = 0
local recoilRotX = 0

----------------------------------------------------------------------
-- 3. อัปเดตตำแหน่งปืนทุกเฟรม (VIEWMODEL LERP & ADS)
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    -- คำนวณ Lerp การเล็ง (Aiming transition)
    local targetOffset = isAiming and ADS_OFFSET or HIP_OFFSET
    currentOffset = currentOffset:Lerp(targetOffset, dt * 14)

    -- คำนวณการฟื้นตัวของแรงถีบ (Recoil recovery)
    recoilOffsetZ = math.max(0, recoilOffsetZ - dt * 2.5)
    recoilRotX = math.max(0, recoilRotX - dt * 25)

    -- การซูมกล้อง FOV
    local targetFOV = isAiming and adsFOV or defaultFOV
    camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * dt * 12

    -- ประกอบ CFrame รวมของปืน
    local baseCF = camera.CFrame * currentOffset * CFrame.new(0, 0, recoilOffsetZ) * CFrame.Angles(math.rad(recoilRotX), 0, 0)

    gunRoot.CFrame = baseCF
    grip.CFrame = baseCF * CFrame.new(0, -0.28, 0.15) * CFrame.Angles(math.rad(-15), 0, 0)
    slide.CFrame = baseCF * CFrame.new(0, 0.18, -0.15)
    barrel.CFrame = baseCF * CFrame.new(0, 0.18, -0.85)
    frontSight.CFrame = baseCF * CFrame.new(0, 0.44, -0.8)
    rearSight.CFrame = baseCF * CFrame.new(0, 0.43, 0.45)
    muzzleFlash.CFrame = baseCF * CFrame.new(0, 0.18, -1.1)
end)

----------------------------------------------------------------------
-- 4. หน้าจอ HUD (AMMO, CROSSHAIR, SCOREBOARD)
----------------------------------------------------------------------
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "ZombieFPS_HUD"
hudGui.ResetOnSpawn = false
hudGui.IgnoreGuiInset = true
hudGui.Parent = pGui

-- เป้าเล็ง Crosshair กลางจอ (จะจางหายไปเวลาเล็ง ADS ผ่านศูนย์ปืนจริง)
local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.new(0, 6, 0, 6)
crosshair.Position = UDim2.new(0.5, -3, 0.5, -3)
crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
crosshair.BorderSizePixel = 0
crosshair.Parent = hudGui
Instance.new("UICorner", crosshair).CornerRadius = UDim.new(1, 0)

local ammoFrame = Instance.new("Frame")
ammoFrame.Size = UDim2.new(0, 180, 0, 60)
ammoFrame.Position = UDim2.new(1, -200, 1, -80)
ammoFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ammoFrame.BackgroundTransparency = 0.3
ammoFrame.Parent = hudGui
Instance.new("UICorner", ammoFrame).CornerRadius = UDim.new(0, 8)

local ammoText = Instance.new("TextLabel")
ammoText.Size = UDim2.new(1, 0, 1, 0)
ammoText.BackgroundTransparency = 1
ammoText.TextColor3 = Color3.fromRGB(255, 220, 80)
ammoText.Font = Enum.Font.SpecialElite
ammoText.TextSize = 28
ammoText.Text = "12 / 72"
ammoText.Parent = ammoFrame

local waveFrame = Instance.new("Frame")
waveFrame.Size = UDim2.new(0, 160, 0, 50)
waveFrame.Position = UDim2.new(0, 20, 0, 25)
waveFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
waveFrame.BackgroundTransparency = 0.3
waveFrame.Parent = hudGui
Instance.new("UICorner", waveFrame).CornerRadius = UDim.new(0, 8)

local waveText = Instance.new("TextLabel")
waveText.Size = UDim2.new(1, 0, 1, 0)
waveText.BackgroundTransparency = 1
waveText.TextColor3 = Color3.fromRGB(255, 50, 50)
waveText.Font = Enum.Font.SpecialElite
waveText.TextSize = 26
waveText.Text = "WAVE 1"
waveText.Parent = waveFrame

local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.new(0, 700, 0, 80)
toastLabel.Position = UDim2.new(0.5, -350, 0.22, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
toastLabel.Font = Enum.Font.SpecialElite
toastLabel.TextSize = 28
toastLabel.TextTransparency = 1
toastLabel.Parent = hudGui

local function showAnnouncement(msg, color)
    toastLabel.Text = msg
    toastLabel.TextColor3 = color or Color3.fromRGB(255, 220, 50)
    toastLabel.TextTransparency = 0
    task.delay(4, function()
        TweenService:Create(toastLabel, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
    end)
end

waveAnnounceEvent.OnClientEvent:Connect(function(waveNum, message)
    if waveNum > 0 then
        waveText.Text = "WAVE " .. waveNum
    end
    showAnnouncement(message)
end)

-- กระดานคะแนนทีม
local scoreFrame = Instance.new("Frame")
scoreFrame.Size = UDim2.new(0, 260, 0, 160)
scoreFrame.Position = UDim2.new(1, -280, 0, 25)
scoreFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
scoreFrame.BackgroundTransparency = 0.35
scoreFrame.Parent = hudGui
Instance.new("UICorner", scoreFrame).CornerRadius = UDim.new(0, 8)

local scoreTitle = Instance.new("TextLabel")
scoreTitle.Size = UDim2.new(1, 0, 0, 26)
scoreTitle.BackgroundTransparency = 1
scoreTitle.Text = "👥 TEAM POINTS"
scoreTitle.TextColor3 = Color3.fromRGB(255, 200, 80)
scoreTitle.Font = Enum.Font.GothamBold
scoreTitle.TextSize = 14
scoreTitle.Parent = scoreFrame

local scoreListContainer = Instance.new("ScrollingFrame")
scoreListContainer.Size = UDim2.new(1, -12, 1, -32)
scoreListContainer.Position = UDim2.new(0, 6, 0, 28)
scoreListContainer.BackgroundTransparency = 1
scoreListContainer.ScrollBarThickness = 2
scoreListContainer.Parent = scoreFrame

local scoreListLayout = Instance.new("UIListLayout")
scoreListLayout.Padding = UDim.new(0, 4)
scoreListLayout.Parent = scoreListContainer

updateScoreboardEvent.OnClientEvent:Connect(function(teamScores)
    for _, child in ipairs(scoreListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for _, pData in ipairs(teamScores) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 24)
        row.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        row.BackgroundTransparency = 0.5
        row.Parent = scoreListContainer
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.48, 0, 1, 0)
        nameLabel.Position = UDim2.new(0.04, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Text = pData.Name
        nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.TextSize = 12
        nameLabel.Parent = row

        local pointsLabel = Instance.new("TextLabel")
        pointsLabel.Size = UDim2.new(0.44, 0, 1, 0)
        pointsLabel.Position = UDim2.new(0.52, 0, 0, 0)
        pointsLabel.BackgroundTransparency = 1
        pointsLabel.TextXAlignment = Enum.TextXAlignment.Right
        pointsLabel.Text = pData.Points .. " Pts (" .. pData.Kills .. "K)"
        pointsLabel.TextColor3 = (pData.Status == "Downed") and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 220, 80)
        pointsLabel.Font = Enum.Font.GothamBold
        pointsLabel.TextSize = 12
        pointsLabel.Parent = row
    end
end)

----------------------------------------------------------------------
-- 5. ระบบการยิงและแอนิเมชันแรงถีบ (SHOOTING & RECOIL ANIMATION)
----------------------------------------------------------------------
local clipAmmo = 12
local reserveAmmo = 72
local maxClip = 12
local isReloading = false
local fireRateCooldown = false

local function updateAmmoUI()
    ammoText.Text = clipAmmo .. " / " .. reserveAmmo
    ammoText.TextColor3 = (clipAmmo == 0) and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 220, 80)
end

local function reloadWeapon()
    if isReloading or clipAmmo == maxClip or reserveAmmo <= 0 then return end
    isReloading = true
    ammoText.Text = "RELOADING..."
    ammoText.TextColor3 = Color3.fromRGB(255, 180, 50)

    -- แอนิเมชันเอียงปืนลงเพื่อเปลี่ยนแม็ก
    task.spawn(function()
        for i = 1, 10 do
            recoilRotX = recoilRotX - 2.5
            task.wait(0.02)
        end
        task.wait(0.8)
        for i = 1, 10 do
            recoilRotX = recoilRotX + 2.5
            task.wait(0.02)
        end
    end)

    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://9114223170"
    s.Volume = 0.8
    s.Parent = camera
    s:Play()
    Debris:AddItem(s, 2)

    task.wait(1.5)
    local needed = maxClip - clipAmmo
    local toAdd = math.min(needed, reserveAmmo)
    clipAmmo = clipAmmo + toAdd
    reserveAmmo = reserveAmmo - toAdd
    isReloading = false
    updateAmmoUI()
end

local function playMuzzleFlashAnimation()
    muzzleFlash.Transparency = 0
    flashLight.Brightness = 4
    task.delay(0.04, function()
        muzzleFlash.Transparency = 1
        flashLight.Brightness = 0
    end)
end

local function shootWeapon()
    if fireRateCooldown or isReloading then return end
    if clipAmmo <= 0 then
        reloadWeapon()
        return
    end

    fireRateCooldown = true
    clipAmmo = clipAmmo - 1
    updateAmmoUI()

    -- 1. แอนิเมชันแรงถีบปืน (Recoil Kickback)
    recoilOffsetZ = 0.35 -- สไลด์ปืนถอยหลัง
    recoilRotX = isAiming and 4.0 or 7.0 -- กระดกปากกระบอกปืนขึ้น

    -- 2. แอนิเมชันแฟลชปากกระบอกปืน
    playMuzzleFlashAnimation()

    -- 3. เสียงปืนพก
    local gunSound = Instance.new("Sound")
    gunSound.SoundId = "rbxassetid://9114221147"
    gunSound.Volume = 1.0
    gunSound.Parent = camera
    gunSound:Play()
    Debris:AddItem(gunSound, 1.5)

    -- 4. กล้องสั่นเล็กน้อย
    camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(isAiming and 0.5 or 1.0), math.rad((math.random() - 0.5) * 0.5), 0)

    -- 5. ยิง Raycast ตรวจจับเป้าหมาย
    local rayOrigin = camera.CFrame.Position
    local rayDirection = camera.CFrame.LookVector * 300

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { player.Character, viewmodel }
    rayParams.FilterType = RaycastFilterType.Exclude

    local hit = Workspace:Raycast(rayOrigin, rayDirection, rayParams)

    -- สร้างเส้นกระสุนพุ่ง (Bullet Tracer Streak)
    local tracerEnd = hit and hit.Position or (rayOrigin + rayDirection)
    local tracer = Instance.new("Part")
    tracer.Size = Vector3.new(0.08, 0.08, (tracerEnd - muzzleFlash.Position).Magnitude)
    tracer.CFrame = CFrame.lookAt((muzzleFlash.Position + tracerEnd) / 2, tracerEnd)
    tracer.Color = Color3.fromRGB(255, 220, 100)
    tracer.Material = Enum.Material.Neon
    tracer.CanCollide = false
    tracer.Anchored = true
    tracer.Parent = Workspace
    Debris:AddItem(tracer, 0.04)

    if hit and hit.Instance then
        local hitPart = hit.Instance
        local hitZombie = hitPart:FindFirstAncestorOfClass("Model")
        if hitZombie and hitZombie.Name:sub(1, 7) == "Zombie_" then
            local isHeadshot = (hitPart.Name == "Head" or hitPart.Name == "Eyes")
            local dmg = isHeadshot and 100 or 35
            zombieHitEvent:FireServer(hitPart, dmg, isHeadshot)

            -- แสดงเอฟเฟกต์เป้าแดงเวลายิงโดน
            crosshair.BackgroundColor3 = isHeadshot and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(255, 180, 0)
            crosshair.Size = UDim2.new(0, 10, 0, 10)
            crosshair.Position = UDim2.new(0.5, -5, 0.5, -5)
            task.delay(0.1, function()
                crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                crosshair.Size = UDim2.new(0, 6, 0, 6)
                crosshair.Position = UDim2.new(0.5, -3, 0.5, -3)
            end)
        end
    end

    task.wait(0.18)
    fireRateCooldown = false
end

----------------------------------------------------------------------
-- 6. การควบคุมเมาส์และปุ่มกด (MOUSE & KEYBOARD INPUTS)
----------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- คลิกซ้ายยิงปืน
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        shootWeapon()
    -- คลิกขวาค้างเพื่อเล็งปืน (Aim Down Sights - ADS)
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = true
        crosshair.BackgroundTransparency = 1 -- ซ่อนเป้า เพื่อเล็งผ่านศูนย์ปืนจริง
    -- กด R เพื่อรีโหลด
    elseif input.KeyCode == Enum.KeyCode.R then
        reloadWeapon()
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    -- ปล่อยคลิกขวา เลิกเล็ง
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = false
        crosshair.BackgroundTransparency = 0
    end
end)

print("🎯 ระบบปืนพก 3D Viewmodel, แอนิเมชันเล็ง (ADS) และแอนิเมชันยิงปืน พร้อมทำงานแล้ว!")
