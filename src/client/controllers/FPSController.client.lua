--[[
    FPSController.client.lua
    KMUTNB Building 40 - Zombie Defense // Master FPS Controller
    
    โครงสร้างสถาปัตยกรรมแยกโมดูลาร์ (Modular Architecture):
      - Weapons/WeaponRegistry: ดึงสเปกและสถิติปืน
      - Weapons/configs/: ปรับจูนปืนเฉพาะกระบอก (Vandal, Phantom, Operator, ฯลฯ)
      - Weapons/models/: จัดการแขนนักศึกษา มจพ. และโมเดลปืน 3D
      - Weapons/optics/: จัดการระบบซูม ADS, สโคปสไนเปอร์, และ Crosshair
      - Weapons/effects/: จัดการเสียงปืน Engine และแรงถีบฟิสิกส์สปริง
      - Weapons/ui/: จัดการหน้าต่างคลังแสง VALORANT ARSENAL [B]
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

-- โหลดโฟลเดอร์โมดูลปืนเฉพาะ (Weapons Directory)
local weaponsFolder = script.Parent.Parent:WaitForChild("Weapons", 20)
local WeaponRegistry = require(weaponsFolder:WaitForChild("WeaponRegistry"))
local KMUTNBArms = require(weaponsFolder:WaitForChild("models"):WaitForChild("KMUTNBArms"))
local WeaponModelBuilder = require(weaponsFolder:WaitForChild("models"):WaitForChild("WeaponModelBuilder"))
local OpticsManager = require(weaponsFolder:WaitForChild("optics"):WaitForChild("OpticsManager"))
local WeaponAudio = require(weaponsFolder:WaitForChild("effects"):WaitForChild("WeaponAudio"))
local RecoilSpring = require(weaponsFolder:WaitForChild("effects"):WaitForChild("RecoilSpring"))
local ValorantBuyMenu = require(weaponsFolder:WaitForChild("ui"):WaitForChild("ValorantBuyMenu"))

-- Remote Events
local zombieEvents = ReplicatedStorage:WaitForChild("ZombieGameEvents", 25)
local zombieHitEvent = zombieEvents:WaitForChild("ZombieHitEvent", 25)

----------------------------------------------------------------------
-- 1. ตัวแปรสถานะเกม (STATE VARIABLES)
----------------------------------------------------------------------
local currentWeaponKey = "Vandal"
local currentWeapon = WeaponRegistry.get(currentWeaponKey)
local clipAmmo = currentWeapon.Mag
local reserveAmmo = currentWeapon.Reserve

local isAiming = false
local isReloading = false
local isMouseDown = false
local isCursorFree = false
local lastShotTime = 0

-- ฟิสิกส์สปริงแรงถีบ (Recoil Springs)
local recoilSpring = RecoilSpring.new(1, 45, 6, 8)

-- Sway & Bobbing
local currentOffset = currentWeapon.HipOffset or CFrame.new(0.60, -0.55, -1.35)
local swayTimer = 0
local mouseSwayX = 0
local mouseSwayY = 0

-- Reload Animation
local reloadTimeTotal = 2.0
local reloadTimer = 0

----------------------------------------------------------------------
-- 2. ระบบจัดการการล็อค/ปลดล็อคเมาส์ (ENGINE LEVEL MOUSE MANAGER)
----------------------------------------------------------------------
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

----------------------------------------------------------------------
-- 3. สร้าง VIEWMODEL และชิ้นส่วน 3D
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
local leftArmParts = {}
local muzzleFlashPart = nil
local flashLight = nil

local function rebuildViewmodel()
    -- ล้างชิ้นส่วนเดิม
    for p, _ in pairs(rigParts) do
        if p and p.Parent then p:Destroy() end
    end
    rigParts = {}
    leftArmParts = {}
    muzzleFlashPart = nil
    flashLight = nil

    local isPistol = (currentWeapon.Type == "Pistol" or currentWeapon.Type == "Revolver")

    -- 1. แขนนักศึกษา มจพ.
    local arms, leftArms = KMUTNBArms.build(viewmodel, isPistol)
    for p, cf in pairs(arms) do rigParts[p] = cf end
    for p, cf in pairs(leftArms) do leftArmParts[p] = cf end

    -- 2. โมเดลปืน 3D (หรือโมเดลนำเข้าจาก ReplicatedStorage)
    local wParts, mPart, fLight = WeaponModelBuilder.build(viewmodel, currentWeapon, gunRoot)
    for p, cf in pairs(wParts) do rigParts[p] = cf end
    muzzleFlashPart = mPart
    flashLight = fLight
end

----------------------------------------------------------------------
-- 4. หน้าจอ UI HUD & เมนูเลือกปืน
----------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ValorantMasterHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = pGui

-- ระบบกล้องสโคปและ Crosshair
local opticsUI = OpticsManager.createUI(screenGui)

-- Hitmarker
local hitmarker = Instance.new("ImageLabel")
hitmarker.Size = UDim2.new(0, 28, 0, 28)
hitmarker.Position = UDim2.new(0.5, -14, 0.5, -14)
hitmarker.BackgroundTransparency = 1
hitmarker.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
hitmarker.ImageColor3 = Color3.fromRGB(255, 50, 50)
hitmarker.ImageTransparency = 1
hitmarker.Parent = screenGui

-- Card ข้อมูลปืนมุมขวาล่าง
local gunCard = Instance.new("Frame")
gunCard.Size = UDim2.new(0, 280, 0, 105)
gunCard.Position = UDim2.new(1, -300, 1, -125)
gunCard.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
gunCard.BackgroundTransparency = 0.2
gunCard.BorderSizePixel = 0
gunCard.Parent = screenGui
Instance.new("UICorner", gunCard).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", gunCard).Color = Color3.fromRGB(255, 70, 85)

local gunNameLabel = Instance.new("TextLabel")
gunNameLabel.Size = UDim2.new(1, -20, 0, 26)
gunNameLabel.Position = UDim2.new(0, 14, 0, 8)
gunNameLabel.BackgroundTransparency = 1
gunNameLabel.TextColor3 = Color3.fromRGB(255, 70, 85)
gunNameLabel.Font = Enum.Font.GothamBold
gunNameLabel.TextSize = 20
gunNameLabel.TextXAlignment = Enum.TextXAlignment.Left
gunNameLabel.Text = currentWeapon.Name
gunNameLabel.Parent = gunCard

local gunTypeLabel = Instance.new("TextLabel")
gunTypeLabel.Size = UDim2.new(1, -20, 0, 16)
gunTypeLabel.Position = UDim2.new(0, 14, 0, 34)
gunTypeLabel.BackgroundTransparency = 1
gunTypeLabel.TextColor3 = Color3.fromRGB(170, 185, 205)
gunTypeLabel.Font = Enum.Font.Gotham
gunTypeLabel.TextSize = 12
gunTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
gunTypeLabel.Text = string.format("%s // %s", currentWeapon.Category:upper(), currentWeapon.FiringType:upper())
gunTypeLabel.Parent = gunCard

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Size = UDim2.new(1, -20, 0, 42)
ammoLabel.Position = UDim2.new(0, 14, 0, 52)
ammoLabel.BackgroundTransparency = 1
ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextSize = 32
ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
ammoLabel.Text = string.format("%d / %d", clipAmmo, reserveAmmo)
ammoLabel.Parent = gunCard

local function updateAmmoUI()
    if isReloading then
        ammoLabel.Text = "RELOADING..."
        ammoLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    else
        ammoLabel.Text = string.format("%d / %d", clipAmmo, reserveAmmo)
        ammoLabel.TextColor3 = (clipAmmo <= math.floor(currentWeapon.Mag * 0.25)) and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 255, 255)
    end
end

-- สร้างเมนูเลือกปืน VALORANT ARSENAL
local buyMenuObj = nil
local function onSelectWeapon(weaponKey)
    local wData = WeaponRegistry.get(weaponKey)
    if not wData then return end

    currentWeaponKey = weaponKey
    currentWeapon = wData
    clipAmmo = currentWeapon.Mag
    reserveAmmo = currentWeapon.Reserve
    isAiming = false
    isReloading = false

    gunNameLabel.Text = currentWeapon.Name
    gunTypeLabel.Text = string.format("%s // %s", currentWeapon.Category:upper(), currentWeapon.FiringType:upper())
    updateAmmoUI()

    rebuildViewmodel()
    WeaponAudio.playClick(1.8)

    buyMenuObj.Frame.Visible = false
    setCameraFrozen(false)
    isCursorFree = false
    opticsUI.Crosshair.Visible = true
end

buyMenuObj = ValorantBuyMenu.create(screenGui, WeaponRegistry.getAll(), onSelectWeapon)

local function toggleBuyMenu()
    buyMenuObj.Frame.Visible = not buyMenuObj.Frame.Visible
    WeaponAudio.playClick(2.2)

    if buyMenuObj.Frame.Visible then
        setCameraFrozen(true)
        isMouseDown = false
        isAiming = false
        opticsUI.Crosshair.Visible = false
        opticsUI:SetAiming(false, currentWeapon)
    else
        setCameraFrozen(false)
        isCursorFree = false
        opticsUI.Crosshair.Visible = true
    end
end

buyMenuObj.CloseButton.MouseButton1Click:Connect(toggleBuyMenu)

-- บังคับเมาส์ให้เป็นอิสระเมื่อเปิดเมนู ชนะระบบกล้องของ Roblox
RunService:BindToRenderStep("EnforceMouseBehavior", Enum.RenderPriority.Camera.Value + 1, function()
    if buyMenuObj.Frame.Visible or isCursorFree then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end
end)

----------------------------------------------------------------------
-- 5. ระบบรีโหลด COD STYLE
----------------------------------------------------------------------
local function reloadWeapon()
    if isReloading or clipAmmo == currentWeapon.Mag or reserveAmmo <= 0 then return end
    isReloading = true
    isAiming = false
    opticsUI:SetAiming(false, currentWeapon)
    reloadTimer = 0
    updateAmmoUI()

    WeaponAudio.playClick(2.0)
    task.delay(0.9, function() WeaponAudio.playClick(2.8) end)
    task.delay(1.5, function() WeaponAudio.playClick(1.6) end)

    task.wait(reloadTimeTotal)
    local needed = currentWeapon.Mag - clipAmmo
    local toAdd = math.min(needed, reserveAmmo)
    clipAmmo = clipAmmo + toAdd
    reserveAmmo = reserveAmmo - toAdd
    isReloading = false
    updateAmmoUI()
end

----------------------------------------------------------------------
-- 6. ตัวเลขดาเมจลอย (DAMAGE POPUP)
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
-- 7. ระบบการยิงและคำนวณวิถีกระสุน (BALLISTICS ENGINE)
----------------------------------------------------------------------
local function executeShoot()
    if isReloading or buyMenuObj.Frame.Visible then return end

    local fireRate = currentWeapon.FireRate
    if isAiming and currentWeapon.Optics and currentWeapon.Optics.ADS_FireRateMult then
        fireRate = fireRate / currentWeapon.Optics.ADS_FireRateMult
    end

    local now = os.clock()
    if now - lastShotTime < fireRate then return end

    if clipAmmo <= 0 then
        WeaponAudio.playClick(3.5)
        reloadWeapon()
        return
    end

    lastShotTime = now
    clipAmmo = clipAmmo - 1
    updateAmmoUI()

    -- 1. เล่นเสียงปืน
    WeaponAudio.playShot(currentWeapon)

    -- 2. ฟิสิกส์สปริงแรงถีบ (Recoil Spring Impulse)
    local rec = currentWeapon.Recoil or { KickZ = 0.4, PitchX = 4, YawY = 1.2 }
    recoilSpring:Impulse(Vector3.new(
        math.rad(isAiming and (rec.PitchX * 0.7) or rec.PitchX),
        math.rad((math.random() - 0.5) * rec.YawY),
        isAiming and (rec.KickZ * 0.6) or rec.KickZ
    ))

    -- 3. แฟลชไฟปากกระบอกปืน
    if muzzleFlashPart then
        muzzleFlashPart.Transparency = 0
        flashLight.Brightness = (currentWeapon.Audio and currentWeapon.Audio.Silenced) and 1.5 or 4.5
        task.delay(0.04, function()
            muzzleFlashPart.Transparency = 1
            flashLight.Brightness = 0
        end)
    end

    -- 4. สั่นกล้อง
    camera.CFrame = camera.CFrame * CFrame.Angles(
        math.rad(isAiming and 0.25 or 0.55),
        math.rad((math.random() - 0.5) * 0.3),
        0
    )

    -- 5. Raycast ตรวจจับเป้าหมาย
    local pellets = currentWeapon.Pellets or 1
    local rayOrigin = camera.CFrame.Position
    local baseDir = camera.CFrame.LookVector

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { player.Character, viewmodel }
    rayParams.FilterType = RaycastFilterType.Exclude

    for i = 1, pellets do
        local spread = (pellets > 1) and Vector3.new((math.random() - 0.5) * 0.08, (math.random() - 0.5) * 0.08, (math.random() - 0.5) * 0.08) or Vector3.zero
        local shotDir = (baseDir + spread).Unit * 500

        local hit = Workspace:Raycast(rayOrigin, shotDir, rayParams)
        local tracerEnd = hit and hit.Position or (rayOrigin + shotDir)
        local muzzlePos = muzzleFlashPart and muzzleFlashPart.Position or rayOrigin

        -- กระสุนวิ่ง
        local dist = (tracerEnd - muzzlePos).Magnitude
        if dist > 0.5 then
            local tracer = Instance.new("Part")
            tracer.Size = Vector3.new(0.08, 0.08, dist)
            tracer.CFrame = CFrame.lookAt((muzzlePos + tracerEnd) / 2, tracerEnd)
            tracer.Color = (currentWeapon.Audio and currentWeapon.Audio.Silenced) and Color3.fromRGB(100, 220, 255) or Color3.fromRGB(255, 215, 90)
            tracer.Material = Enum.Material.Neon
            tracer.CanCollide = false
            tracer.Anchored = true
            tracer.Parent = Workspace
            Debris:AddItem(tracer, 0.04)
        end

        -- โดนเป้าหมาย
        if hit and hit.Instance then
            local hitPart = hit.Instance
            local hitModel = hitPart:FindFirstAncestorOfClass("Model")
            if hitModel and hitModel.Name:sub(1, 7) == "Zombie_" then
                local isHeadshot = (hitPart.Name == "Head" or hitPart.Name == "Eyes")
                local dmg = isHeadshot and currentWeapon.HeadDmg or currentWeapon.BodyDmg

                zombieHitEvent:FireServer(hitPart, dmg, isHeadshot)
                WeaponAudio.playHit(isHeadshot)
                showDamagePopup(hit.Position, dmg, isHeadshot)

                hitmarker.ImageColor3 = isHeadshot and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 190, 50)
                hitmarker.ImageTransparency = 0
                task.delay(0.08, function()
                    hitmarker.ImageTransparency = 1
                end)
            else
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
-- 8. ตรวจจับการกดปุ่ม & เมาส์ (INPUTS)
----------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end

    -- [B] เปิด/ปิด คลังแสง Valorant
    if input.KeyCode == Enum.KeyCode.B then
        toggleBuyMenu()
        return
    end

    -- [Left Alt] ปลดล็อคเมาส์อิสระ
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        isCursorFree = not isCursorFree
        setCameraFrozen(isCursorFree)
        return
    end

    if buyMenuObj.Frame.Visible then return end

    -- คลิกซ้าย: ยิง
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isCursorFree then
            isCursorFree = false
            setCameraFrozen(false)
        end
        isMouseDown = true
        executeShoot()
    -- คลิกขวา: เล็ง ADS
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = true
        opticsUI:SetAiming(true, currentWeapon)
    -- [R] รีโหลด
    elseif input.KeyCode == Enum.KeyCode.R then
        reloadWeapon()
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = false
        opticsUI:SetAiming(false, currentWeapon)
    end
end)

UserInputService.InputChanged:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseMovement and not buyMenuObj.Frame.Visible and not isCursorFree then
        mouseSwayX = math.clamp(input.Delta.X * 0.0015, -0.06, 0.06)
        mouseSwayY = math.clamp(input.Delta.Y * 0.0015, -0.06, 0.06)
    end
end)

-- Heartbeat: Full-Auto firing loop
RunService.Heartbeat:Connect(function()
    if isMouseDown and not isReloading and currentWeapon.FiringType == "Auto" and not buyMenuObj.Frame.Visible then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            executeShoot()
        else
            isMouseDown = false
        end
    end
end)

----------------------------------------------------------------------
-- 9. อัปเดตแอนิเมชันทุกเฟรม (RENDER STEPPED)
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    -- 1. ADS Target Offset
    local adsTarget = (currentWeapon.Optics and currentWeapon.Optics.Offset) or CFrame.new(0, -0.42, -1.15)
    local hipTarget = currentWeapon.HipOffset or CFrame.new(0.60, -0.55, -1.35)
    local targetOffset = isAiming and adsTarget or hipTarget
    currentOffset = currentOffset:Lerp(targetOffset, math.clamp(dt * 18, 0, 1))

    -- 2. FOV Zoom
    local targetFov = isAiming and ((currentWeapon.Optics and currentWeapon.Optics.ZoomFOV) or 52) or 70
    camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * math.clamp(dt * 15, 0, 1)

    -- 3. อัปเดตสปริงแรงถีบ (Spring Recoil)
    local recSpringVec = recoilSpring:Update(dt)

    -- 4. การโยกตัวตามจังหวะก้าวเดิน (Bobbing)
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

    mouseSwayX = mouseSwayX * math.exp(-dt * 14)
    mouseSwayY = mouseSwayY * math.exp(-dt * 14)

    -- 5. แอนิเมชันแขนตอนรีโหลด
    local leftArmReloadOffset = CFrame.identity
    if isReloading then
        reloadTimer = reloadTimer + dt
        local prog = reloadTimer / reloadTimeTotal
        if prog < 0.35 then
            leftArmReloadOffset = CFrame.new(0, -prog * 2.2, prog * 0.8) * CFrame.Angles(math.rad(-prog * 40), 0, 0)
        elseif prog < 0.70 then
            local p2 = (prog - 0.35) / 0.35
            leftArmReloadOffset = CFrame.new(0, -(1 - p2) * 2.2, (1 - p2) * 0.8) * CFrame.Angles(math.rad(-(1 - p2) * 40), 0, 0)
        elseif prog < 0.90 then
            local p3 = (prog - 0.70) / 0.20
            leftArmReloadOffset = CFrame.new(0.2, 0.25, -p3 * 0.4)
        else
            leftArmReloadOffset = CFrame.identity
        end
    end

    -- 6. ประกอบ CFrame Viewmodel
    local motionCFrame = CFrame.new(bobX - mouseSwayX, bobY - mouseSwayY, recSpringVec.Z) * CFrame.Angles(
        recSpringVec.X - mouseSwayY * 40,
        recSpringVec.Y - mouseSwayX * 40,
        mouseSwayX * 25
    )

    local finalRootCF = camera.CFrame * currentOffset * motionCFrame
    gunRoot.CFrame = finalRootCF

    -- ปรับตำแหน่งชิ้นส่วนแขนและปืน
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
rebuildViewmodel()
updateAmmoUI()

print("=========================================================")
print("🏆 [Valorant Weapons Engine] สถาปัตยกรรมคลังแสงปืนแบบแยกโมดูลาร์พร้อมทำงาน 100%!")
print("=========================================================")
