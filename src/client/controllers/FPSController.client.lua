--[[
    FPSController.client.lua
    KMUTNB Building 40 - Zombie Defense // Master FPS Controller
    
    คุณสมบัติระบบ:
      - ระบบ 3 ช่องอาวุธ [1] ปืนหลัก, [2] ปืนรอง, [3] มีดคารัมบิตควงได้
      - รองรับเลื่อนลูกกลิ้งเมาส์ (Scroll Wheel) สลับช่อง 1 -> 2 -> 3
      - กดปุ่ม [Left Shift] วิ่งเร็ว (Sprint) พร้อมแถบพละกำลังจำกัด (Stamina Bar)
      - Dynamic FOV (+5 FOV) & Tactical Viewmodel Bobbing ตอนวิ่ง
      - หมดแรง (Exhausted Penalty) ต้องรอฟื้นฟูถึง 25% จึงวิ่งใหม่ได้
      - เมนูซื้อปืน [B] คลังแสง Valorant ครบทุกกระบอก
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera", 5)

-- 🔒 บังคับมุมมองบุคคลที่ 1 (FPS Lock First Person) 100%
local function enforceFirstPerson()
    pcall(function()
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        player.CameraMaxZoomDistance = 0.5
        player.CameraMinZoomDistance = 0.5
        if camera then
            camera.CameraType = Enum.CameraType.Custom
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end)
end

enforceFirstPerson()

player.CharacterAdded:Connect(function(char)
    task.wait(0.05)
    enforceFirstPerson()
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local newCam = Workspace.CurrentCamera
    if newCam then
        camera = newCam
        enforceFirstPerson()
    end
end)

-- ปิด CoreGui Backpack ของ Roblox เพื่อไม่ให้แย่งการกดปุ่ม 1, 2, 3
task.spawn(function()
    for _ = 1, 5 do
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        end)
        task.wait(0.2)
    end
end)

----------------------------------------------------------------------
-- โหลดโฟลเดอร์โมดูลปืนเฉพาะ (GAUNTLET-LOOP BULLETPROOF WEAPONS RESOLVER)
----------------------------------------------------------------------
local function resolveWeaponsFolder()
    -- 1. Sibling ใน PlayerScripts (ตำแหน่งมาตรฐานตาม default.project.json)
    if script.Parent and script.Parent:FindFirstChild("Weapons") then
        return script.Parent:FindFirstChild("Weapons")
    end
    -- 2. รอ Sibling 3 วินาที
    if script.Parent then
        local found = script.Parent:WaitForChild("Weapons", 3)
        if found then return found end
    end
    -- 3. ค้นหาใน PlayerScripts ของ LocalPlayer โดยตรง
    local pScripts = player:FindFirstChild("PlayerScripts") or player:WaitForChild("PlayerScripts", 3)
    if pScripts and pScripts:FindFirstChild("Weapons") then
        return pScripts:FindFirstChild("Weapons")
    end
    -- 4. ค้นหาใน StarterPlayerScripts
    local sps = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
    if sps and sps:FindFirstChild("Weapons") then
        return sps:FindFirstChild("Weapons")
    end
    -- 5. ค้นหาใน ReplicatedStorage
    if ReplicatedStorage:FindFirstChild("Weapons") then
        return ReplicatedStorage:FindFirstChild("Weapons")
    end
    error("[FPSController FATAL] ไม่สามารถค้นหาโฟลเดอร์ 'Weapons' ได้จากทุกช่องทาง!")
end

local weaponsFolder = resolveWeaponsFolder()

local function safeRequire(parentInstance, childName)
    local child = parentInstance:WaitForChild(childName, 10)
    if not child then
        error(string.format("[FPSController ERROR] ไม่พบโมดูล '%s' ใน %s", childName, parentInstance:GetFullName()))
    end
    local success, result = pcall(require, child)
    if not success then
        error(string.format("[FPSController ERROR] โหลดโมดูล '%s' ไม่สำเร็จ: %s", childName, tostring(result)))
    end
    return result
end

local WeaponRegistry = safeRequire(weaponsFolder, "WeaponRegistry")

local modelsFolder = weaponsFolder:WaitForChild("models", 10)
local KMUTNBArms = safeRequire(modelsFolder, "KMUTNBArms")
local WeaponModelBuilder = safeRequire(modelsFolder, "WeaponModelBuilder")

local opticsFolder = weaponsFolder:WaitForChild("optics", 10)
local OpticsManager = safeRequire(opticsFolder, "OpticsManager")

local effectsFolder = weaponsFolder:WaitForChild("effects", 10)
local WeaponAudio = safeRequire(effectsFolder, "WeaponAudio")
local RecoilSpring = safeRequire(effectsFolder, "RecoilSpring")

local uiFolder = weaponsFolder:WaitForChild("ui", 10)
local ValorantBuyMenu = safeRequire(uiFolder, "ValorantBuyMenu")

-- Remote Events (Non-blocking fallback)
local zombieEvents = ReplicatedStorage:WaitForChild("ZombieGameEvents", 10)
local buyWeaponEvent = zombieEvents and zombieEvents:WaitForChild("BuyWeaponEvent", 10)
local playerDamageEvent = zombieEvents and zombieEvents:WaitForChild("PlayerDamageEvent", 10)
local waveAnnounceEvent = zombieEvents and zombieEvents:WaitForChild("WaveAnnounce", 10)
local updateScoreboardEvent = zombieEvents and zombieEvents:WaitForChild("UpdateScoreboard", 10)
local toggleAdminEvent = zombieEvents and zombieEvents:WaitForChild("ToggleAdminMode", 10)

-- Weapon combat events
local weaponCombatEvents = ReplicatedStorage:WaitForChild("WeaponCombatEvents", 10)
local weaponFireEvent = weaponCombatEvents and weaponCombatEvents:WaitForChild("FireWeapon", 5)
local weaponReloadEvent = weaponCombatEvents and weaponCombatEvents:WaitForChild("ReloadWeapon", 5)
local weaponAmmoSyncEvent = weaponCombatEvents and weaponCombatEvents:WaitForChild("AmmoSync", 5)
local weaponHitFeedbackEvent = weaponCombatEvents and weaponCombatEvents:WaitForChild("HitFeedback", 5)
local equipWeaponEvent = weaponCombatEvents and weaponCombatEvents:WaitForChild("EquipWeapon", 5)

----------------------------------------------------------------------
-- 1. ระบบจัดการ 2 ช่องอาวุธ (2-SLOT INVENTORY SYSTEM: PRIMARY & SECONDARY)
----------------------------------------------------------------------
local inventorySlots = {
    [1] = nil,         -- Primary is acquired at a survival weapon station.
    [2] = "Classic",  -- Everyone starts with a server-owned sidearm.
}
local activeSlot = 2

local currentWeaponKey = inventorySlots[activeSlot]
local currentWeapon = WeaponRegistry.get(currentWeaponKey)
local clipAmmo = currentWeapon.Mag
local reserveAmmo = currentWeapon.Reserve
local slotAmmoCache = {
    [1] = nil,
    [2] = { key = currentWeaponKey, clip = clipAmmo, reserve = reserveAmmo },
}

local showWeaponNotice
local isInsideTestRangeClient
local canUseAdminMode

local function isSidearmWeapon(weaponKey, wData)
    local cat = wData and wData.Category and wData.Category:upper() or ""
    if cat == "SIDEARMS" then return true end
    return weaponKey == "Classic" or weaponKey == "Shorty" or weaponKey == "Frenzy" or weaponKey == "Ghost" or weaponKey == "Sheriff"
end

local function slotIndexForKey(weaponKey)
    local wData = WeaponRegistry.get(weaponKey)
    return isSidearmWeapon(weaponKey, wData) and 2 or 1
end

-- ตัวแปรสถานะ
local isAiming = false
local isReloading = false
local isMouseDown = false
local isCursorFree = false
local isInspecting = false
local lastShotTime = 0

----------------------------------------------------------------------
-- 1.1 ระบบพละกำลังและการวิ่ง + โหมด ADMIN (STAMINA, SPRINT & ADMIN GOD MODE)
----------------------------------------------------------------------
local WALK_SPEED_NORMAL = 16
local SPRINT_SPEED = 25
local EXHAUSTED_SPEED = 13.5

local WALK_SPEED_ADMIN = 34
local SPRINT_SPEED_ADMIN = 56
local isAdminMode = player:GetAttribute("IsAdminGodMode") == true

local MAX_STAMINA = 100
local currentStamina = 100
local STAMINA_DRAIN_PER_SEC = 22     -- ใช้งานต่อเนื่องได้ประมาณ ~4.5 วินาที
local STAMINA_REGEN_PER_SEC = 20     -- ฟื้นฟูกลับเต็มใน ~5.0 วินาที
local STAMINA_REGEN_DELAY = 1.0      -- รอ 1.0 วินาทีหลังหยุดวิ่งแล้วเริ่มฟื้นฟู
local EXHAUSTION_RECOVERY_POINT = 25 -- เมื่อหมดแรง ต้องรอรีเจนถึง 25% จึงจะวิ่งใหม่ได้

local isShiftDown = false
local isSprinting = false
local isExhausted = false
local lastSprintTime = 0
local currentSprintCFrame = CFrame.identity

local function syncAdminModeToServer()
    if toggleAdminEvent and player:GetAttribute("CanUseAdminMode") == true then
        toggleAdminEvent:FireServer(isAdminMode)
    end
end

local flashlightEnabled = true
local flashlightLight
local lightingMode = "Day"

local function setFlashlightForCharacter(character)
    local head = character and character:FindFirstChild("Head")
    if not head then return end
    local attachment = head:FindFirstChild("SurvivalFlashlightAttachment")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "SurvivalFlashlightAttachment"
        attachment.Position = Vector3.new(0, 0, -0.2)
        attachment.Parent = head
    end
    flashlightLight = attachment:FindFirstChild("SurvivalFlashlight")
    if not flashlightLight then
        flashlightLight = Instance.new("SpotLight")
        flashlightLight.Name = "SurvivalFlashlight"
        flashlightLight.Angle = 62
        flashlightLight.Range = 52
        flashlightLight.Brightness = 2.4
        flashlightLight.Shadows = true
        flashlightLight.Color = Color3.fromRGB(220, 232, 255)
        flashlightLight.Parent = attachment
    end
    flashlightLight.Enabled = flashlightEnabled
end

local function toggleFlashlight()
    flashlightEnabled = not flashlightEnabled
    if flashlightLight then flashlightLight.Enabled = flashlightEnabled end
    WeaponAudio.playClick(flashlightEnabled and 2.4 or 1.5)
end

local function applyLightingMode(mode)
    lightingMode = (mode == "Night") and "Night" or "Day"

    local stale = Lighting:FindFirstChild("SurvivalColorCorrection")
    if stale then stale:Destroy() end

    local correction = Lighting:FindFirstChild("Building40ColorCorrection")
    if not correction then
        correction = Instance.new("ColorCorrectionEffect")
        correction.Name = "Building40ColorCorrection"
        correction.Parent = Lighting
    end

    if lightingMode == "Day" then
        Lighting.ClockTime = 14
        Lighting.Brightness = 2.2
        Lighting.Ambient = Color3.fromRGB(135, 138, 145)
        Lighting.OutdoorAmbient = Color3.fromRGB(155, 160, 168)
        Lighting.FogColor = Color3.fromRGB(190, 200, 215)
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        correction.Saturation = 0.05
        correction.Contrast = 0.04
        correction.Brightness = 0
        correction.TintColor = Color3.fromRGB(255, 255, 255)
    else
        Lighting.ClockTime = 0.2
        Lighting.Brightness = 0.9
        Lighting.Ambient = Color3.fromRGB(25, 29, 39)
        Lighting.OutdoorAmbient = Color3.fromRGB(12, 16, 26)
        Lighting.FogColor = Color3.fromRGB(15, 19, 29)
        Lighting.FogStart = 12
        Lighting.FogEnd = 420
        correction.Saturation = -0.28
        correction.Contrast = 0.18
        correction.Brightness = -0.04
        correction.TintColor = Color3.fromRGB(185, 205, 235)
    end
end

local function toggleLightingMode()
    local targetMode = lightingMode == "Night" and "Day" or "Night"
    applyLightingMode(targetMode)
    if showWeaponNotice then
        showWeaponNotice(lightingMode == "Day" and "โหมดกลางวัน: เปิดไฟแมพสว่าง (กด [N] เพื่อสลับกลางคืน)" or "โหมดกลางคืน: กด [L] เปิดไฟฉาย | กด [N] เปิดไฟแมพ")
    end
    WeaponAudio.playClick(lightingMode == "Night" and 1.4 or 2.2)
end

player:GetAttributeChangedSignal("IsAdminGodMode"):Connect(function()
    isAdminMode = player:GetAttribute("IsAdminGodMode") == true
end)

local function setupCharacter(char)
    task.spawn(function()
        applyLightingMode(lightingMode)
        currentStamina = MAX_STAMINA
        isExhausted = false
        isSprinting = false
        isShiftDown = false
        syncAdminModeToServer()
        local hum = char:WaitForChild("Humanoid", 10)
        setFlashlightForCharacter(char)
        if hum then
            hum.WalkSpeed = isAdminMode and WALK_SPEED_ADMIN or WALK_SPEED_NORMAL
        end
        task.wait(0.1)
        if viewmodel and camera and viewmodel.Parent ~= camera then
            viewmodel.Parent = camera
        end
        if rebuildViewmodel then
            rebuildViewmodel()
        end
    end)
end

if player.Character then
    setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

-- ฟิสิกส์สปริงแรงถีบ (Recoil Springs)
local recoilSpring = RecoilSpring.new(1, 45, 6, 8)

-- Sway & Bobbing (Valorant Pro Standard Tuning)
local currentOffset = currentWeapon.HipOffset or CFrame.new(0.60, -0.55, -1.35)
local swayTimer = 0
local targetMouseSwayX = 0
local targetMouseSwayY = 0
local currentMouseSwayX = 0
local currentMouseSwayY = 0

-- Reload Animation
local reloadTimeTotal = 2.0
local reloadTimer = 0
local reloadSequence = 0

-- Forward declaration สำหรับฟังก์ชันสลับช่องอาวุธ
local equipSlot = nil

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
local rightArmParts = {}
local rigPartBaseTransparency = {}
local weaponAnimGroups = { Magazine = {}, Bolt = {}, Pump = {}, Cylinder = {}, ReloadOnly = {} }
local weaponAnimState = {
    lastShotTime = -10,
    cylinderIndex = 0,
    currentCylinderAngle = 0,
    inspectTimer = 0,
    gunAnimCF = CFrame.identity,
    leftArmAnimCF = CFrame.identity,
    leftDetachAlpha = 0,
}
local muzzleFlashParts = {}
local flashLight = nil
local muzzleSmokeEmitter = nil
local muzzleFlashRollAngle = 0
local lastMuzzleFlashTime = 0

local function rebuildViewmodel()
    for p, _ in pairs(rigParts) do
        if p and p.Parent then p:Destroy() end
    end
    rigParts = {}
    leftArmParts = {}
    rightArmParts = {}
    rigPartBaseTransparency = {}
    weaponAnimGroups = { Magazine = {}, Bolt = {}, Pump = {}, Cylinder = {}, ReloadOnly = {} }
    weaponAnimState.lastShotTime = -10
    weaponAnimState.cylinderIndex = 0
    weaponAnimState.currentCylinderAngle = 0
    weaponAnimState.inspectTimer = 0
    weaponAnimState.gunAnimCF = CFrame.identity
    weaponAnimState.leftArmAnimCF = CFrame.identity
    weaponAnimState.leftDetachAlpha = 0
    muzzleFlashParts = {}
    flashLight = nil
    muzzleSmokeEmitter = nil

    -- 1. แขนนักศึกษา มจพ. (ปรับระยะมือซ้ายอัตโนมัติตามรุ่นปืน)
    local arms, leftArms, rightArms = KMUTNBArms.build(viewmodel, currentWeapon)
    for p, cf in pairs(arms) do
        rigParts[p] = cf
        rigPartBaseTransparency[p] = p.Transparency
    end
    for p, cf in pairs(leftArms) do leftArmParts[p] = cf end
    for p, cf in pairs(rightArms) do rightArmParts[p] = cf end

    -- 2. โมเดลปืน 3D พร้อมกลุ่มชิ้นส่วนเคลื่อนไหว (Magazine, Bolt, Pump, Cylinder)
    local wParts, mParts, fLight, sEmitter, pGroups = WeaponModelBuilder.build(viewmodel, currentWeapon, gunRoot)
    for p, cf in pairs(wParts) do
        rigParts[p] = cf
        rigPartBaseTransparency[p] = p.Transparency
        if p.Name == "SpeedloaderBase" or p.Name:match("^ReloadShell") or p.Name == "MarshalShell" then
            weaponAnimGroups.ReloadOnly[p] = true
            p.Transparency = 1
        end
    end
    if type(pGroups) == "table" then
        for groupName, groupMap in pairs(pGroups) do
            if weaponAnimGroups[groupName] and type(groupMap) == "table" then
                for part, flag in pairs(groupMap) do
                    if flag then weaponAnimGroups[groupName][part] = true end
                end
            end
        end
    end
    muzzleFlashParts = (type(mParts) == "table") and mParts or (mParts and { mParts } or {})
    flashLight = fLight
    muzzleSmokeEmitter = sEmitter
end

----------------------------------------------------------------------
-- 4. หน้าจอ UI HUD, SLOTS INDICATOR, และเมนูเลือกปืน
----------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ValorantMasterHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10
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
hitmarker.ZIndex = 15
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

-- 🌟 UI แสดง 2 ช่องอาวุธ [1] ปืนหลัก [2] ปืนรอง
local slotsFrame = Instance.new("Frame")
slotsFrame.Size = UDim2.new(0, 280, 0, 34)
slotsFrame.Position = UDim2.new(1, -300, 1, -165)
slotsFrame.BackgroundTransparency = 1
slotsFrame.Parent = screenGui

local slotButtons = {}
local slotTitles = { "[1] ปืนหลัก", "[2] ปืนรอง" }

for s = 1, 2 do
    local sBox = Instance.new("TextButton")
    sBox.Name = "SlotButton_" .. s
    sBox.Size = UDim2.new(0.48, 0, 1, 0)
    sBox.Position = UDim2.new((s - 1) * 0.52, 0, 0, 0)
    sBox.BackgroundColor3 = (s == activeSlot) and Color3.fromRGB(255, 70, 85) or Color3.fromRGB(20, 26, 36)
    sBox.BackgroundTransparency = 0.3
    sBox.Text = ""
    sBox.AutoButtonColor = true
    sBox.Parent = slotsFrame
    Instance.new("UICorner", sBox).CornerRadius = UDim.new(0, 6)

    local sStroke = Instance.new("UIStroke", sBox)
    sStroke.Color = (s == activeSlot) and Color3.fromRGB(255, 120, 130) or Color3.fromRGB(60, 75, 95)
    sStroke.Thickness = 1.2

    local sNum = Instance.new("TextLabel")
    sNum.Size = UDim2.new(1, 0, 0.45, 0)
    sNum.Position = UDim2.new(0, 0, 0.05, 0)
    sNum.BackgroundTransparency = 1
    sNum.TextColor3 = (s == activeSlot) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 195, 215)
    sNum.Font = Enum.Font.GothamBold
    sNum.TextSize = 10
    sNum.Text = slotTitles[s]
    sNum.Parent = sBox

    local sName = Instance.new("TextLabel")
    sName.Size = UDim2.new(1, 0, 0.5, 0)
    sName.Position = UDim2.new(0, 0, 0.48, 0)
    sName.BackgroundTransparency = 1
    sName.TextColor3 = Color3.fromRGB(255, 255, 255)
    sName.Font = Enum.Font.GothamBold
    sName.TextSize = 11
    sName.Text = (WeaponRegistry.get(inventorySlots[s]) and WeaponRegistry.get(inventorySlots[s]).Name) or "NONE"
    sName.Parent = sBox

    -- รองรับการคลิกเลือกช่องอาวุธโดยตรงด้วยเมาส์
    sBox.MouseButton1Click:Connect(function()
        if equipSlot then
            equipSlot(s)
        end
    end)

    slotButtons[s] = { Box = sBox, Stroke = sStroke, NameLabel = sName, NumLabel = sNum }
end

-- 🌟 UI แถบพลังงาน/ความเหนื่อย (STAMINA & SPRINT BAR)
local staminaCard = Instance.new("Frame")
staminaCard.Name = "StaminaCard"
staminaCard.Size = UDim2.new(0, 280, 0, 26)
staminaCard.Position = UDim2.new(1, -300, 1, -197)
staminaCard.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
staminaCard.BackgroundTransparency = 0.25
staminaCard.BorderSizePixel = 0
staminaCard.Parent = screenGui
Instance.new("UICorner", staminaCard).CornerRadius = UDim.new(0, 6)

local staminaStroke = Instance.new("UIStroke", staminaCard)
staminaStroke.Color = Color3.fromRGB(45, 60, 80)
staminaStroke.Thickness = 1.2

local staminaTitle = Instance.new("TextLabel")
staminaTitle.Size = UDim2.new(0.65, 0, 0, 14)
staminaTitle.Position = UDim2.new(0, 8, 0, 1)
staminaTitle.BackgroundTransparency = 1
staminaTitle.TextColor3 = Color3.fromRGB(170, 195, 220)
staminaTitle.Font = Enum.Font.GothamBold
staminaTitle.TextSize = 10
staminaTitle.TextXAlignment = Enum.TextXAlignment.Left
staminaTitle.Text = "⚡ STAMINA [L-SHIFT]"
staminaTitle.Parent = staminaCard

local staminaPercent = Instance.new("TextLabel")
staminaPercent.Size = UDim2.new(0.35, -8, 0, 14)
staminaPercent.Position = UDim2.new(0.65, 0, 0, 1)
staminaPercent.BackgroundTransparency = 1
staminaPercent.TextColor3 = Color3.fromRGB(0, 240, 215)
staminaPercent.Font = Enum.Font.GothamBold
staminaPercent.TextSize = 10
staminaPercent.TextXAlignment = Enum.TextXAlignment.Right
staminaPercent.Text = "100%"
staminaPercent.Parent = staminaCard

local barTrack = Instance.new("Frame")
barTrack.Size = UDim2.new(1, -16, 0, 6)
barTrack.Position = UDim2.new(0, 8, 0, 16)
barTrack.BackgroundColor3 = Color3.fromRGB(25, 32, 45)
barTrack.BorderSizePixel = 0
barTrack.Parent = staminaCard
Instance.new("UICorner", barTrack).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.Position = UDim2.new(0, 0, 0, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 240, 215)
barFill.BorderSizePixel = 0
barFill.Parent = barTrack
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

-- 👑 ปุ่มเลือกเปิด/ปิด โหมด ADMIN (อันลิมิต Stamina + ไม่ตาย + วิ่งไว) กดคลิกหรือกดปุ่ม [G] ได้ทันที
local adminToggleBtn = Instance.new("TextButton")
adminToggleBtn.Name = "AdminModeToggleButton"
adminToggleBtn.Size = UDim2.new(0, 280, 0, 28)
adminToggleBtn.Position = UDim2.new(1, -300, 1, -231)
adminToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 36, 12)
adminToggleBtn.BackgroundTransparency = 0.15
adminToggleBtn.BorderSizePixel = 0
adminToggleBtn.AutoButtonColor = true
adminToggleBtn.Font = Enum.Font.GothamBold
adminToggleBtn.TextSize = 11
adminToggleBtn.TextColor3 = Color3.fromRGB(255, 225, 85)
adminToggleBtn.Text = "👑 [G] โหมด ADMIN: เปิด (∞ วิ่งไว + อมตะ)"
adminToggleBtn.Visible = player:GetAttribute("CanUseAdminMode") == true
adminToggleBtn.Parent = screenGui
Instance.new("UICorner", adminToggleBtn).CornerRadius = UDim.new(0, 6)

local adminBtnStroke = Instance.new("UIStroke", adminToggleBtn)
adminBtnStroke.Color = Color3.fromRGB(255, 200, 45)
adminBtnStroke.Thickness = 1.4

local function updateStaminaUI()
    if isAdminMode then
        adminToggleBtn.Text = "👑 [G] โหมด ADMIN: เปิด (∞ วิ่งไว + อมตะ)"
        adminToggleBtn.BackgroundColor3 = Color3.fromRGB(48, 38, 12)
        adminToggleBtn.TextColor3 = Color3.fromRGB(255, 225, 85)
        adminBtnStroke.Color = Color3.fromRGB(255, 205, 50)

        barFill.Size = UDim2.new(1, 0, 1, 0)
        staminaTitle.Text = isSprinting and "👑 ADMIN SUPER SPRINT // วิ่งไวสูงสุด!" or "👑 ADMIN STAMINA // อันลิมิต"
        staminaTitle.TextColor3 = Color3.fromRGB(255, 225, 85)
        staminaPercent.Text = "∞ UNLIMITED"
        staminaPercent.TextColor3 = Color3.fromRGB(255, 230, 95)
        barFill.BackgroundColor3 = Color3.fromRGB(255, 210, 55)
        staminaStroke.Color = Color3.fromRGB(255, 205, 50)
        staminaCard.BackgroundTransparency = 0.2
        return
    else
        adminToggleBtn.Text = "⚙️ [G] โหมด ADMIN: ปิด (กด G เพื่อเปิด)"
        adminToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 26, 36)
        adminToggleBtn.TextColor3 = Color3.fromRGB(165, 180, 200)
        adminBtnStroke.Color = Color3.fromRGB(65, 80, 100)
    end

    local ratio = math.clamp(currentStamina / MAX_STAMINA, 0, 1)
    barFill.Size = UDim2.new(ratio, 0, 1, 0)
    local pct = math.floor(ratio * 100)

    if isExhausted then
        staminaTitle.Text = "⚠ EXHAUSTED // หมดแรง (รอฟื้นฟู)"
        staminaTitle.TextColor3 = Color3.fromRGB(255, 75, 75)
        staminaPercent.Text = string.format("%d%%", pct)
        staminaPercent.TextColor3 = Color3.fromRGB(255, 75, 75)
        barFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        staminaStroke.Color = Color3.fromRGB(255, 70, 85)
        staminaCard.BackgroundTransparency = 0.15
    elseif ratio <= 0.35 then
        staminaTitle.Text = "⚡ LOW STAMINA // พลังงานต่ำ"
        staminaTitle.TextColor3 = Color3.fromRGB(255, 195, 45)
        staminaPercent.Text = string.format("%d%%", pct)
        staminaPercent.TextColor3 = Color3.fromRGB(255, 195, 45)
        barFill.BackgroundColor3 = Color3.fromRGB(255, 195, 45)
        staminaStroke.Color = Color3.fromRGB(160, 120, 30)
        staminaCard.BackgroundTransparency = 0.2
    else
        staminaTitle.Text = isSprinting and "⚡ SPRINTING // วิ่งเต็มสปีด" or "⚡ STAMINA [L-SHIFT]"
        staminaTitle.TextColor3 = isSprinting and Color3.fromRGB(0, 255, 230) or Color3.fromRGB(170, 195, 220)
        staminaPercent.Text = string.format("%d%%", pct)
        staminaPercent.TextColor3 = Color3.fromRGB(0, 240, 215)
        barFill.BackgroundColor3 = Color3.fromRGB(0, 240, 215)
        staminaStroke.Color = isSprinting and Color3.fromRGB(0, 240, 215) or Color3.fromRGB(45, 60, 80)

        if ratio >= 0.99 and not isSprinting then
            staminaCard.BackgroundTransparency = 0.45
        else
            staminaCard.BackgroundTransparency = 0.25
        end
    end
end

-- ❤️ UI แถบพลังชีวิตผู้เล่นมุมซ้ายล่าง (PLAYER HP BAR & DAMAGE OVERLAY)
local damageFlash = Instance.new("Frame")
damageFlash.Name = "DamageFlashOverlay"
damageFlash.Size = UDim2.new(1, 0, 1, 0)
damageFlash.BackgroundColor3 = Color3.fromRGB(220, 20, 30)
damageFlash.BackgroundTransparency = 1
damageFlash.BorderSizePixel = 0
damageFlash.ZIndex = 0
damageFlash.Parent = screenGui

local hpCard = Instance.new("Frame")
hpCard.Name = "PlayerHealthCard"
hpCard.Size = UDim2.new(0, 260, 0, 82)
hpCard.Position = UDim2.new(0, 20, 1, -102)
hpCard.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
hpCard.BackgroundTransparency = 0.2
hpCard.BorderSizePixel = 0
hpCard.Parent = screenGui
Instance.new("UICorner", hpCard).CornerRadius = UDim.new(0, 8)

local hpStroke = Instance.new("UIStroke", hpCard)
hpStroke.Color = Color3.fromRGB(45, 210, 115)
hpStroke.Thickness = 1.5

local hpTitle = Instance.new("TextLabel")
hpTitle.Size = UDim2.new(1, -24, 0, 18)
hpTitle.Position = UDim2.new(0, 12, 0, 6)
hpTitle.BackgroundTransparency = 1
hpTitle.TextColor3 = Color3.fromRGB(170, 195, 220)
hpTitle.Font = Enum.Font.GothamBold
hpTitle.TextSize = 11
hpTitle.TextXAlignment = Enum.TextXAlignment.Left
hpTitle.Text = "✚ PLAYER HEALTH // พลังชีวิต"
hpTitle.Parent = hpCard

local hpValueLabel = Instance.new("TextLabel")
hpValueLabel.Size = UDim2.new(1, -24, 0, 34)
hpValueLabel.Position = UDim2.new(0, 12, 0, 22)
hpValueLabel.BackgroundTransparency = 1
hpValueLabel.TextColor3 = Color3.fromRGB(45, 235, 125)
hpValueLabel.Font = Enum.Font.GothamBold
hpValueLabel.TextSize = 28
hpValueLabel.TextXAlignment = Enum.TextXAlignment.Left
hpValueLabel.Text = "100 / 100 HP"
hpValueLabel.Parent = hpCard

local hpTrack = Instance.new("Frame")
hpTrack.Size = UDim2.new(1, -24, 0, 10)
hpTrack.Position = UDim2.new(0, 12, 0, 62)
hpTrack.BackgroundColor3 = Color3.fromRGB(28, 35, 48)
hpTrack.BorderSizePixel = 0
hpTrack.Parent = hpCard
Instance.new("UICorner", hpTrack).CornerRadius = UDim.new(1, 0)

local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = Color3.fromRGB(45, 225, 115)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpTrack
Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

local function updateHealthUI(hum)
    if isAdminMode then
        hpTitle.Text = "👑 ADMIN GOD MODE // อมตะไม่ตาย"
        hpTitle.TextColor3 = Color3.fromRGB(255, 225, 85)
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpValueLabel.Text = "∞ / ∞ GOD"
        local gold = Color3.fromRGB(255, 210, 55)
        hpFill.BackgroundColor3 = gold
        hpValueLabel.TextColor3 = gold
        hpStroke.Color = gold
        return
    end

    hpTitle.Text = "✚ PLAYER HEALTH // พลังชีวิต"
    hpTitle.TextColor3 = Color3.fromRGB(170, 195, 220)
    local curHP = hum and math.max(0, math.floor(hum.Health + 0.5)) or 100
    local maxHP = (hum and hum.MaxHealth > 0) and math.floor(hum.MaxHealth) or 100
    local ratio = math.clamp(curHP / maxHP, 0, 1)

    hpFill.Size = UDim2.new(ratio, 0, 1, 0)
    hpValueLabel.Text = string.format("%d / %d HP", curHP, maxHP)

    local color
    if ratio > 0.5 then
        color = Color3.fromRGB(45, 225, 115)
    elseif ratio > 0.25 then
        color = Color3.fromRGB(255, 185, 40)
    else
        color = Color3.fromRGB(255, 55, 65)
    end
    hpFill.BackgroundColor3 = color
    hpValueLabel.TextColor3 = color
    hpStroke.Color = color
end

canUseAdminMode = function()
    return player:GetAttribute("CanUseAdminMode") == true
end

player:GetAttributeChangedSignal("CanUseAdminMode"):Connect(function()
    local allowed = canUseAdminMode()
    adminToggleBtn.Visible = allowed
    if not allowed then
        isAdminMode = false
        updateStaminaUI()
    end
end)

local function toggleAdminMode()
    if not canUseAdminMode() then
        isAdminMode = false
        syncAdminModeToServer()
        adminToggleBtn.Visible = false
        updateStaminaUI()
        return
    end

    isAdminMode = not isAdminMode
    if isAdminMode then
        currentStamina = MAX_STAMINA
        isExhausted = false
    end
    syncAdminModeToServer()
    WeaponAudio.playClick(isAdminMode and 2.6 or 1.6)
    updateStaminaUI()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    updateHealthUI(hum)
end

adminToggleBtn.MouseButton1Click:Connect(toggleAdminMode)

-- Points & Kills HUD Card above HP Card
local pointsCard = Instance.new("Frame")
pointsCard.Name = "PointsAndKillsCard"
pointsCard.Size = UDim2.new(0, 260, 0, 34)
pointsCard.Position = UDim2.new(0, 20, 1, -142)
pointsCard.BackgroundColor3 = Color3.fromRGB(14, 19, 27)
pointsCard.BackgroundTransparency = 0.2
pointsCard.BorderSizePixel = 0
pointsCard.Parent = screenGui
Instance.new("UICorner", pointsCard).CornerRadius = UDim.new(0, 8)
local pointsStroke = Instance.new("UIStroke", pointsCard)
pointsStroke.Color = Color3.fromRGB(235, 185, 55)
pointsStroke.Thickness = 1.2
pointsStroke.Transparency = 0.25

local pointsLabel = Instance.new("TextLabel")
pointsLabel.Size = UDim2.new(1, -16, 1, 0)
pointsLabel.Position = UDim2.new(0, 10, 0, 0)
pointsLabel.BackgroundTransparency = 1
pointsLabel.Font = Enum.Font.GothamBold
pointsLabel.TextSize = 13
pointsLabel.TextXAlignment = Enum.TextXAlignment.Left
pointsLabel.TextColor3 = Color3.fromRGB(255, 218, 92)
pointsLabel.Text = "💰 500 แต้ม   •   ☠ 0 Kills"
pointsLabel.Parent = pointsCard

local function refreshPointsDisplay(overridePoints, overrideKills)
    local pts = overridePoints or player:GetAttribute("Points") or 500
    local kills = overrideKills or player:GetAttribute("Kills") or 0
    pointsLabel.Text = string.format("💰 %d แต้ม   •   ☠ %d Kills", pts, kills)
end

player:GetAttributeChangedSignal("Points"):Connect(function()
    refreshPointsDisplay()
end)
player:GetAttributeChangedSignal("Kills"):Connect(function()
    refreshPointsDisplay()
end)
if updateScoreboardEvent then
    updateScoreboardEvent.OnClientEvent:Connect(function(scoreList)
        if type(scoreList) ~= "table" then return end
        for _, entry in ipairs(scoreList) do
            if entry.UserId == player.UserId then
                refreshPointsDisplay(entry.Points, entry.Kills)
                break
            end
        end
    end)
end
refreshPointsDisplay()

-- แบนเนอร์แจ้งเตือนเวฟซอมบี้ด้านบนจอ
local waveBanner = Instance.new("TextLabel")
waveBanner.Name = "WaveBanner"
waveBanner.Size = UDim2.new(0, 520, 0, 40)
waveBanner.Position = UDim2.new(0.5, -260, 0, 62)
waveBanner.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
waveBanner.BackgroundTransparency = 0.25
waveBanner.TextColor3 = Color3.fromRGB(255, 215, 60)
waveBanner.Font = Enum.Font.GothamBold
waveBanner.TextSize = 16
waveBanner.Text = "🧟 WAVE 1 // เตรียมรับมือฝูงซอมบี้!"
waveBanner.Visible = false
waveBanner.Parent = screenGui
Instance.new("UICorner", waveBanner).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", waveBanner).Color = Color3.fromRGB(255, 90, 90)

if playerDamageEvent then
    playerDamageEvent.OnClientEvent:Connect(function(dmg, newHP, maxHP)
        damageFlash.BackgroundTransparency = 0.55
        TweenService:Create(damageFlash, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()
        recoilSpring:Impulse(Vector3.new(math.rad(3.5), math.rad((math.random() - 0.5) * 4), 0.15))
    end)
end

if waveAnnounceEvent then
    waveAnnounceEvent.OnClientEvent:Connect(function(waveNum, msg)
        waveBanner.Text = msg or ("⚠️ WAVE " .. tostring(waveNum))
        waveBanner.Visible = true
        task.delay(4.5, function()
            waveBanner.Visible = false
        end)
    end)
end

local function updateSlotUI()
    for s = 1, 2 do
        local isAct = (s == activeSlot)
        local w = inventorySlots[s] and WeaponRegistry.get(inventorySlots[s]) or nil
        slotButtons[s].Box.BackgroundColor3 = isAct and Color3.fromRGB(255, 70, 85) or Color3.fromRGB(20, 26, 36)
        slotButtons[s].Stroke.Color = isAct and Color3.fromRGB(255, 140, 150) or Color3.fromRGB(60, 75, 95)
        slotButtons[s].NumLabel.TextColor3 = isAct and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 195, 215)
        slotButtons[s].NameLabel.Text = w and w.Name or "EMPTY"
    end
end

local function updateAmmoUI()
    if isReloading then
        ammoLabel.Text = "RELOADING..."
        ammoLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    else
        ammoLabel.Text = string.format("%d / %d", clipAmmo, reserveAmmo)
        ammoLabel.TextColor3 = (clipAmmo <= math.floor(currentWeapon.Mag * 0.25)) and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 255, 255)
    end
end

if weaponAmmoSyncEvent then
    weaponAmmoSyncEvent.OnClientEvent:Connect(function(weaponName, serverClip, serverReserve, serverReloading)
        if type(weaponName) ~= "string" or type(serverClip) ~= "number" or type(serverReserve) ~= "number" then return end
        local slotIdx = slotIndexForKey(weaponName)
        if inventorySlots[slotIdx] == weaponName then
            slotAmmoCache[slotIdx] = { key = weaponName, clip = serverClip, reserve = serverReserve }
        end
        if weaponName ~= currentWeaponKey then return end
        clipAmmo = serverClip
        reserveAmmo = serverReserve
        isReloading = (serverReloading == true)
        if not isReloading then
            reloadSequence = reloadSequence + 1
        end
        updateAmmoUI()
    end)
end

-- (Client syncs slot clip/reserve with server AmmoSync while caching per-slot counts locally)

-- สลับไปยังช่องอาวุธ (Equip Slot: 1 = Primary, 2 = Secondary)
equipSlot = function(slotIndex, forceEquip)
    if slotIndex < 1 or slotIndex > 2 then return end

    if isReloading then
        isReloading = false -- ยกเลิกการรีโหลดทันทีเมื่อสลับอาวุธ
        reloadSequence = reloadSequence + 1 -- invalidate the old local reload task
    end

    local wKey = inventorySlots[slotIndex]
    if not wKey then return end

    -- ข้ามเฉพาะกรณีที่กดซ้ำช่องเดิมและเป็นปืนกระบอกเดิมอยู่แล้ว (และไม่ได้ถูกสั่ง forceEquip จาก Buy Menu)
    if not forceEquip and activeSlot == slotIndex and currentWeaponKey == wKey and currentWeapon then
        return
    end

    activeSlot = slotIndex
    currentWeaponKey = wKey
    currentWeapon = WeaponRegistry.get(wKey)
    if equipWeaponEvent then
        equipWeaponEvent:FireServer(wKey)
    end

    local cached = slotAmmoCache[slotIndex]
    if cached and cached.key == wKey then
        clipAmmo = cached.clip
        reserveAmmo = cached.reserve
    else
        clipAmmo = currentWeapon.Mag or 25
        reserveAmmo = currentWeapon.Reserve or 100
        slotAmmoCache[slotIndex] = { key = wKey, clip = clipAmmo, reserve = reserveAmmo }
    end
    isAiming = false
    isReloading = false
    isInspecting = false

    WeaponAudio.playClick(2.0)

    gunNameLabel.Text = currentWeapon.Name or "WEAPON"
    gunTypeLabel.Text = string.format("%s // %s", (currentWeapon.Category or "RIFLES"):upper(), (currentWeapon.FiringType or "AUTO"):upper())
    updateSlotUI()
    updateAmmoUI()
    rebuildViewmodel()
    opticsUI:SetAiming(false, currentWeapon)
    print(string.format("🔫 [Inventory] สลับใช้งานช่อง [%d]: %s (เรียลไทม์)", slotIndex, currentWeapon.Name))
end

local function applyEquippedWeapon(weaponKey)
    if type(weaponKey) ~= "string" or not WeaponRegistry.get(weaponKey) then return end
    local wData = WeaponRegistry.get(weaponKey)
    local targetSlot = isSidearmWeapon(weaponKey, wData) and 2 or 1
    inventorySlots[targetSlot] = weaponKey
    slotAmmoCache[targetSlot] = { key = weaponKey, clip = wData.Mag or 25, reserve = wData.Reserve or 100 }
    equipSlot(targetSlot, true)
    print(string.format("[WeaponPickup] Equipped %s to Slot %d", weaponKey, targetSlot))
end

-- Server-granted pickup/purchase state only; local prompt activation never grants a weapon.
player:GetAttributeChangedSignal("EquippedWeapon"):Connect(function()
    if not player:GetAttribute("LastWeaponPickupAt") then return end
    local wKey = player:GetAttribute("EquippedWeapon")
    if wKey then
        applyEquippedWeapon(wKey)
    end
end)

-- RemoteEvent fallback for server-granted pickups.
task.spawn(function()
    local pickupFolder = ReplicatedStorage:WaitForChild("WeaponPickupEvents", 30)
    if pickupFolder then
        local pickupEvent = pickupFolder:WaitForChild("WeaponGranted", 30)
        if pickupEvent then
            pickupEvent.OnClientEvent:Connect(function(weaponKey)
                applyEquippedWeapon(weaponKey)
            end)
        end
    end
end)

-- สร้างเมนูเลือกปืน VALORANT ARSENAL
local buyMenuObj = nil
isInsideTestRangeClient = function()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local range = Workspace:FindFirstChild("INFECTED_TestRange")
    local floor = range and range:FindFirstChild("RangeFloor")
    if not root or not floor or not floor:IsA("BasePart") then return false end
    local localPosition = floor.CFrame:PointToObjectSpace(root.Position)
    return math.abs(localPosition.X) <= floor.Size.X / 2
        and math.abs(localPosition.Z) <= floor.Size.Z / 2
        and math.abs(localPosition.Y) <= 18
end

showWeaponNotice = function(message)
    waveBanner.Text = message
    waveBanner.Visible = true
    task.delay(3.5, function()
        if waveBanner and waveBanner.Parent then waveBanner.Visible = false end
    end)
end

local function onSelectWeapon(weaponKey)
    if not WeaponRegistry.get(weaponKey) or not buyWeaponEvent then return end
    local callOk, purchased, message = pcall(function()
        return buyWeaponEvent:InvokeServer(weaponKey)
    end)
    if not callOk or not purchased then
        showWeaponNotice(callOk and (message or "ซื้ออาวุธไม่สำเร็จ") or "เชื่อมต่อร้านทดสอบไม่ได้")
        return
    end

    buyMenuObj.Frame.Visible = false
    if buyMenuObj.ModalButton then
        buyMenuObj.ModalButton.Modal = false
    end
    setCameraFrozen(false)
    isCursorFree = false
    opticsUI.Crosshair.Visible = true
end

buyMenuObj = ValorantBuyMenu.create(screenGui, WeaponRegistry.getAll(), onSelectWeapon)

local function toggleBuyMenu()
    if not buyMenuObj.Frame.Visible and not isInsideTestRangeClient() then
        showWeaponNotice("โหมดเอาตัวรอด: ซื้อปืนที่จุดซื้อบนแผนที่ด้วยแต้ม | [B] ฟรีเฉพาะ Test Range")
        return
    end
    buyMenuObj.Frame.Visible = not buyMenuObj.Frame.Visible
    if buyMenuObj.ModalButton then
        buyMenuObj.ModalButton.Modal = buyMenuObj.Frame.Visible
    end
    if buyMenuObj.Frame.Visible then
        setCameraFrozen(true)
        isMouseDown = false
        isAiming = false
        isShiftDown = false
        isSprinting = false
        opticsUI.Crosshair.Visible = false
        opticsUI:SetAiming(false, currentWeapon)
    else
        setCameraFrozen(false)
        isCursorFree = false
        opticsUI.Crosshair.Visible = true
    end
end

buyMenuObj.CloseButton.MouseButton1Click:Connect(toggleBuyMenu)

----------------------------------------------------------------------
-- 4.2 ระบบเลือกแมพและโซน (MAP & ZONE SELECTOR UI)
----------------------------------------------------------------------
local mapMenuFrame = Instance.new("Frame")
mapMenuFrame.Name = "MapMenuFrame"
mapMenuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mapMenuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mapMenuFrame.Size = UDim2.new(0, 750, 0, 480)
mapMenuFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 23)
mapMenuFrame.BackgroundTransparency = 0.05
mapMenuFrame.Visible = false
mapMenuFrame.ZIndex = 50
mapMenuFrame.Parent = screenGui

Instance.new("UICorner", mapMenuFrame).CornerRadius = UDim.new(0, 10)
local mapMenuStroke = Instance.new("UIStroke", mapMenuFrame)
mapMenuStroke.Color = Color3.fromRGB(0, 210, 255)
mapMenuStroke.Thickness = 1.5

-- Modal Unlocker to free mouse from First-Person lock (active ONLY when menu is visible)
local mapModalUnlocker = Instance.new("TextButton")
mapModalUnlocker.Name = "MapModalUnlocker"
mapModalUnlocker.Size = UDim2.new(0, 0, 0, 0)
mapModalUnlocker.BackgroundTransparency = 1
mapModalUnlocker.Text = ""
mapModalUnlocker.Modal = false
mapModalUnlocker.Parent = mapMenuFrame

-- Header
local mapHeader = Instance.new("Frame")
mapHeader.Size = UDim2.new(1, 0, 0, 56)
mapHeader.BackgroundColor3 = Color3.fromRGB(18, 25, 36)
mapHeader.BorderSizePixel = 0
mapHeader.ZIndex = 51
mapHeader.Parent = mapMenuFrame
Instance.new("UICorner", mapHeader).CornerRadius = UDim.new(0, 10)

local mapTitle = Instance.new("TextLabel")
mapTitle.Position = UDim2.new(0, 18, 0, 8)
mapTitle.Size = UDim2.new(1, -80, 0, 22)
mapTitle.BackgroundTransparency = 1
mapTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
mapTitle.Font = Enum.Font.GothamBold
mapTitle.TextSize = 17
mapTitle.TextXAlignment = Enum.TextXAlignment.Left
mapTitle.Text = "🗺️ MAP SELECTOR // เลือกแมพและโซนที่ต้องการไป"
mapTitle.ZIndex = 52
mapTitle.Parent = mapHeader

local mapSubtitle = Instance.new("TextLabel")
mapSubtitle.Position = UDim2.new(0, 18, 0, 30)
mapSubtitle.Size = UDim2.new(1, -80, 0, 18)
mapSubtitle.BackgroundTransparency = 1
mapSubtitle.TextColor3 = Color3.fromRGB(140, 165, 190)
mapSubtitle.Font = Enum.Font.Gotham
mapSubtitle.TextSize = 11
mapSubtitle.TextXAlignment = Enum.TextXAlignment.Left
mapSubtitle.Text = "คลิกเลือกโซนเพื่อวาร์ปทันที • กด [M] หรือคลิก ✕ เพื่อปิดหน้าต่าง"
mapSubtitle.ZIndex = 52
mapSubtitle.Parent = mapHeader

local mapCloseBtn = Instance.new("TextButton")
mapCloseBtn.AnchorPoint = Vector2.new(1, 0.5)
mapCloseBtn.Position = UDim2.new(1, -14, 0.5, 0)
mapCloseBtn.Size = UDim2.new(0, 34, 0, 34)
mapCloseBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 62)
mapCloseBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
mapCloseBtn.Font = Enum.Font.GothamBold
mapCloseBtn.TextSize = 15
mapCloseBtn.Text = "✕"
mapCloseBtn.ZIndex = 53
mapCloseBtn.Parent = mapHeader
Instance.new("UICorner", mapCloseBtn).CornerRadius = UDim.new(0, 6)

-- On-screen Toggle Button
local mapScreenBtn = Instance.new("TextButton")
mapScreenBtn.Name = "MapScreenToggleButton"
mapScreenBtn.Position = UDim2.new(0, 22, 0, 62)
mapScreenBtn.Size = UDim2.new(0, 154, 0, 34)
mapScreenBtn.BackgroundColor3 = Color3.fromRGB(14, 20, 30)
mapScreenBtn.BackgroundTransparency = 0.15
mapScreenBtn.TextColor3 = Color3.fromRGB(0, 220, 255)
mapScreenBtn.Font = Enum.Font.GothamBold
mapScreenBtn.TextSize = 13
mapScreenBtn.Text = "🗺️ เลือกแมพ [M]"
mapScreenBtn.ZIndex = 30
mapScreenBtn.Parent = screenGui
Instance.new("UICorner", mapScreenBtn).CornerRadius = UDim.new(0, 8)
local mapBtnStroke = Instance.new("UIStroke", mapScreenBtn)
mapBtnStroke.Color = Color3.fromRGB(0, 200, 255)
mapBtnStroke.Thickness = 1.2
mapBtnStroke.Transparency = 0.35

local function toggleMapMenu(forceState)
    local newState = if forceState ~= nil then forceState else not mapMenuFrame.Visible
    mapMenuFrame.Visible = newState
    mapModalUnlocker.Modal = newState
    if newState then
        setCameraFrozen(true)
        isMouseDown = false
        isAiming = false
        isShiftDown = false
        isSprinting = false
        isCursorFree = true
        opticsUI.Crosshair.Visible = false
        opticsUI:SetAiming(false, currentWeapon)
    else
        setCameraFrozen(false)
        isCursorFree = false
        opticsUI.Crosshair.Visible = true
    end
end

mapScreenBtn.MouseButton1Click:Connect(function()
    toggleMapMenu()
end)

mapCloseBtn.MouseButton1Click:Connect(function()
    toggleMapMenu(false)
end)

local mapScroll = Instance.new("ScrollingFrame")
mapScroll.Position = UDim2.new(0, 14, 0, 66)
mapScroll.Size = UDim2.new(1, -28, 1, -78)
mapScroll.BackgroundTransparency = 1
mapScroll.BorderSizePixel = 0
mapScroll.ScrollBarThickness = 6
mapScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
mapScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
mapScroll.ZIndex = 51
mapScroll.Parent = mapMenuFrame

local mapGrid = Instance.new("UIGridLayout")
mapGrid.CellPadding = UDim2.new(0, 10, 0, 10)
mapGrid.CellSize = UDim2.new(0.5, -5, 0, 118)
mapGrid.SortOrder = Enum.SortOrder.LayoutOrder
mapGrid.Parent = mapScroll

local MAP_LIST = {
    {
        key = "TheRange",
        order = 1,
        title = "🎯 THE RANGE (สนามยิงปืน)",
        badge = "FEATURED // TEST",
        badgeColor = Color3.fromRGB(0, 220, 130),
        accentColor = Color3.fromRGB(0, 210, 160),
        desc = "หยิบปืนฟรีครบ 18 กระบอก (กด E) • หุ่นซอมบี้ 5 ไซส์ (Crawler ถึง Titan) ลองยิงวัดดาเมจ",
        btnText = "🚀 ไปยัง The Range",
        cframe = CFrame.lookAt(Vector3.new(0, 3.5, 395), Vector3.new(0, 3.5, 432)),
    },
    {
        key = "Floor1",
        order = 2,
        title = "🏢 ตึก 40 ปี — ชั้น 1 LOBBY",
        badge = "MAIN CAMPAIGN",
        badgeColor = Color3.fromRGB(235, 75, 65),
        accentColor = Color3.fromRGB(220, 70, 60),
        desc = "โถงทางเข้าหลัก ประชาสัมพันธ์ ตู้เซฟ จุดซ่อมหน้าต่าง ลิฟต์และบันไดวน",
        btnText = "🚀 ไปยัง ชั้น 1 Lobby",
        cframe = CFrame.lookAt(Vector3.new(0, 3.5, 10), Vector3.new(0, 3.5, 40)),
    },
    {
        key = "Plaza",
        order = 3,
        title = "🌳 ลานหน้าอาคาร 40 ปี",
        badge = "OUTDOOR",
        badgeColor = Color3.fromRGB(0, 170, 255),
        accentColor = Color3.fromRGB(0, 160, 240),
        desc = "ลานกว้างด้านหน้าตึก อาคาร 40 ปี มจพ. และทางเดินหน้าอาคาร",
        btnText = "🚀 ไปยัง ลานหน้าตึก",
        cframe = CFrame.lookAt(Vector3.new(0, 5.5, 125), Vector3.new(0, 5.5, 60)),
    },
    {
        key = "Canteen",
        order = 4,
        title = "🍽️ ชั้น 2 — โรงอาหาร 40 ปี",
        badge = "CANTEEN",
        badgeColor = Color3.fromRGB(255, 170, 30),
        accentColor = Color3.fromRGB(240, 160, 20),
        desc = "โรงอาหาร 40 ปี สจพ. ร้านค้า 8 ร้าน จุดคืนจาน และห้องกินข้าวติดแอร์",
        btnText = "🚀 ไปยัง ชั้น 2",
        cframe = CFrame.lookAt(Vector3.new(0, 25.5, 10), Vector3.new(0, 25.5, 40)),
    },
    {
        key = "SportsArena",
        order = 5,
        title = "🏀 ชั้น 3 — สนามกีฬาในร่ม",
        badge = "ARENA",
        badgeColor = Color3.fromRGB(170, 85, 255),
        accentColor = Color3.fromRGB(160, 75, 240),
        desc = "สนามฟุตซอล สนามบาสเกตบอล และอัฒจันทร์เชียร์ 2 ฝั่ง",
        btnText = "🚀 ไปยัง ชั้น 3",
        cframe = CFrame.lookAt(Vector3.new(0, 47.5, 0), Vector3.new(0, 47.5, 30)),
    },
    {
        key = "Rooftop",
        order = 6,
        title = "🏆 ชั้น 12 — สนามกีฬาดาดฟ้า",
        badge = "ROOFTOP",
        badgeColor = Color3.fromRGB(255, 80, 160),
        accentColor = Color3.fromRGB(240, 70, 150),
        desc = "สนามเซปักตะกร้อ 2 สนาม สนามเทนนิส และวิวชมทัศนียภาพรอบตึก",
        btnText = "🚀 ไปยัง ชั้น 12",
        cframe = CFrame.lookAt(Vector3.new(0, 245.5, 0), Vector3.new(0, 245.5, 30)),
    },
}

for _, item in ipairs(MAP_LIST) do
    local card = Instance.new("Frame")
    card.Name = "Card_" .. item.key
    card.LayoutOrder = item.order
    card.BackgroundColor3 = Color3.fromRGB(18, 25, 36)
    card.BackgroundTransparency = 0.15
    card.ZIndex = 52
    card.Parent = mapScroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = item.accentColor
    cardStroke.Transparency = 0.5
    cardStroke.Thickness = 1

    local bFrame = Instance.new("Frame")
    bFrame.Position = UDim2.new(0, 10, 0, 8)
    bFrame.Size = UDim2.new(0, 110, 0, 16)
    bFrame.BackgroundColor3 = item.badgeColor
    bFrame.BackgroundTransparency = 0.8
    bFrame.ZIndex = 53
    bFrame.Parent = card
    Instance.new("UICorner", bFrame).CornerRadius = UDim.new(0, 4)

    local bTxt = Instance.new("TextLabel")
    bTxt.Size = UDim2.new(1, 0, 1, 0)
    bTxt.BackgroundTransparency = 1
    bTxt.Font = Enum.Font.GothamBold
    bTxt.Text = item.badge
    bTxt.TextColor3 = item.badgeColor
    bTxt.TextSize = 9
    bTxt.ZIndex = 54
    bTxt.Parent = bFrame

    local cardTitle = Instance.new("TextLabel")
    cardTitle.Position = UDim2.new(0, 10, 0, 28)
    cardTitle.Size = UDim2.new(1, -20, 0, 18)
    cardTitle.BackgroundTransparency = 1
    cardTitle.Font = Enum.Font.GothamBold
    cardTitle.Text = item.title
    cardTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
    cardTitle.TextSize = 12
    cardTitle.TextXAlignment = Enum.TextXAlignment.Left
    cardTitle.ZIndex = 53
    cardTitle.Parent = card

    local cardDesc = Instance.new("TextLabel")
    cardDesc.Position = UDim2.new(0, 10, 0, 48)
    cardDesc.Size = UDim2.new(1, -20, 0, 28)
    cardDesc.BackgroundTransparency = 1
    cardDesc.Font = Enum.Font.Gotham
    cardDesc.Text = item.desc
    cardDesc.TextColor3 = Color3.fromRGB(155, 170, 190)
    cardDesc.TextSize = 10
    cardDesc.TextWrapped = true
    cardDesc.TextXAlignment = Enum.TextXAlignment.Left
    cardDesc.TextYAlignment = Enum.TextYAlignment.Top
    cardDesc.ZIndex = 53
    cardDesc.Parent = card

    local warpBtn = Instance.new("TextButton")
    warpBtn.Position = UDim2.new(0, 10, 1, -32)
    warpBtn.Size = UDim2.new(1, -20, 0, 24)
    warpBtn.BackgroundColor3 = item.accentColor
    warpBtn.BackgroundTransparency = 0.15
    warpBtn.Text = item.btnText
    warpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    warpBtn.Font = Enum.Font.GothamBold
    warpBtn.TextSize = 11
    warpBtn.AutoButtonColor = true
    warpBtn.ZIndex = 54
    warpBtn.Parent = card
    Instance.new("UICorner", warpBtn).CornerRadius = UDim.new(0, 6)

    warpBtn.MouseButton1Click:Connect(function()
        toggleMapMenu(false)
        local remotes = ReplicatedStorage:FindFirstChild("TeleportEvents")
        local req = remotes and remotes:FindFirstChild("RequestTeleport")
        if req then
            req:FireServer(item.key)
        else
            showWeaponNotice("ระบบวาร์ปยังไม่พร้อม กรุณารอสักครู่")
        end
    end)
end

local function isAnyModalOpen()
    if buyMenuObj and buyMenuObj.Frame and buyMenuObj.Frame.Visible then return true end
    if mapMenuFrame and mapMenuFrame.Visible then return true end
    if pGui then
        local mapHud = pGui:FindFirstChild("MapSelectorHUD")
        if mapHud then
            local win = mapHud:FindFirstChild("MapSelectorWindow")
            if win and win.Visible then return true end
        end
    end
    return false
end

-- บังคับล็อคเมาส์กลางจอและซ่อนเคอร์เซอร์ระหว่างเล่น (ปลดล็อคเฉพาะตอนเปิดเมนูเท่านั้น)
RunService:BindToRenderStep("EnforceMouseBehavior", Enum.RenderPriority.Last.Value, function()
    if isAnyModalOpen() or isCursorFree then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end
end)

----------------------------------------------------------------------
-- 5. ระบบรีโหลด COD STYLE & ตัวประมวลผลแอนิเมชัน 3D แยกตามกลไกปืน
----------------------------------------------------------------------
local WEAPON_ANIM_PROFILES
local getWeaponAnimProfile
local solveWeaponAnimPose

do
    local I = CFrame.identity
    local function rotD(rx, ry, rz)
        return CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
    end
    local function cf(x, y, z, rx, ry, rz)
        return CFrame.new(x or 0, y or 0, z or 0) * rotD(rx, ry, rz)
    end
    local function pivotRot(pivot, rx, ry, rz)
        return CFrame.new(pivot) * rotD(rx, ry, rz) * CFrame.new(-pivot)
    end
    local function smooth01(t)
        t = math.clamp(t, 0, 1)
        return t * t * (3 - 2 * t)
    end

    local function evalCFTrack(track, prog)
        if not track then return I end
        local n = #track
        if prog <= track[1][1] then return track[1][2] end
        if prog >= track[n][1] then return track[n][2] end
        for i = 1, n - 1 do
            local k1, k2 = track[i], track[i + 1]
            if prog >= k1[1] and prog <= k2[1] then
                local span = math.max(0.0001, k2[1] - k1[1])
                return k1[2]:Lerp(k2[2], smooth01((prog - k1[1]) / span))
            end
        end
        return I
    end

    local function evalScalarTrack(track, prog)
        if not track then return 0 end
        local n = #track
        if prog <= track[1][1] then return track[1][2] end
        if prog >= track[n][1] then return track[n][2] end
        for i = 1, n - 1 do
            local k1, k2 = track[i], track[i + 1]
            if prog >= k1[1] and prog <= k2[1] then
                local span = math.max(0.0001, k2[1] - k1[1])
                local a = smooth01((prog - k1[1]) / span)
                return k1[2] + (k2[2] - k1[2]) * a
            end
        end
        return 0
    end

    local INSPECT_DURATION = 3.6
    local INSPECT_GUN_TRACK = {
        { 0.00, I },
        { 0.22, cf(-0.14, 0.14, 0.18, 14, 34, -22) },
        { 0.48, cf(-0.06, 0.16, 0.15, 10, 18, -32) },
        { 0.72, cf(0.14, 0.12, 0.16, 12, -32, 26) },
        { 0.88, cf(0.06, 0.08, 0.10, 6, -12, 8) },
        { 1.00, I },
    }
    local INSPECT_LEFT_TRACK = {
        { 0.00, I },
        { 0.25, cf(0.02, 0.04, 0.05, 0, 8, -10) },
        { 0.72, cf(-0.02, 0.02, 0.04, 0, -6, 8) },
        { 1.00, I },
    }

    local RIFLE_GUN_TRACK = {
        { 0.00, I },
        { 0.18, cf(-0.08, 0.08, 0.04, 14, -14, -20) },
        { 0.28, cf(-0.09, 0.03, 0.06, 10, -14, -22) },
        { 0.50, cf(-0.08, 0.08, 0.04, 15, -12, -18) },
        { 0.62, cf(-0.05, 0.14, 0.02, 20, -10, -14) },
        { 0.74, cf(0.05, 0.05, 0.04, 8, 14, 16) },
        { 0.85, cf(0.04, 0.02, 0.11, 5, 12, 14) },
        { 1.00, I },
    }
    local RIFLE_MAG_TRACK = {
        { 0.00, I },
        { 0.18, I },
        { 0.38, cf(0, -0.82, 0.12, 10, 0, 0) },
        { 0.45, cf(-0.10, -1.60, 0.18, 12, 0, 0) },
        { 0.50, cf(0, -0.78, 0.10, 8, 0, 0) },
        { 0.62, I },
        { 1.00, I },
    }
    local RIFLE_BOLT_TRACK = {
        { 0.00, I },
        { 0.75, I },
        { 0.85, cf(0, 0, 0.32) },
        { 0.90, I },
        { 1.00, I },
    }
    local DETACH_MAG_SWAP = {
        { 0.00, 0 },
        { 0.20, 0.20 },
        { 0.38, 0.90 },
        { 0.48, 1.00 },
        { 0.60, 0.25 },
        { 0.74, 0 },
        { 1.00, 0 },
    }
    local BREAK_GUN_TRACK = {
        { 0.00, I },
        { 0.18, cf(-0.04, 0.04, 0.06, -24, 10, -18) },
        { 0.36, cf(-0.05, 0.02, 0.08, -26, 12, -20) },
        { 0.58, cf(-0.04, 0.04, 0.06, -22, 10, -18) },
        { 0.74, cf(-0.03, 0.04, 0.05, -18, 8, -12) },
        { 0.86, cf(0.00, 0.08, -0.02, 6, 0, 2) },
        { 1.00, I },
    }
    local BREAK_MAG_TRACK = {
        { 0.00, I },
        { 0.18, I },
        { 0.28, cf(0, 0.02, 0.48) },
        { 0.39, cf(-0.06, -0.75, 0.68) },
        { 0.48, cf(0, -0.55, 0.56) },
        { 0.62, cf(0, 0.02, 0.36) },
        { 0.73, I },
        { 1.00, I },
    }
    local BREAK_LATCH_TRACK = {
        { 0.00, I },
        { 0.12, rotD(0, 22, 0) },
        { 0.82, rotD(0, 22, 0) },
        { 0.88, I },
        { 1.00, I },
    }

    WEAPON_ANIM_PROFILES = {
        Rifle = {
            audioCues = { { 0.19, "MagOut" }, { 0.58, "MagIn" }, { 0.75, "BoltBack" }, { 0.87, "BoltForward" } },
            gunTrack = RIFLE_GUN_TRACK,
            leftArmTrack = {
                { 0.00, I },
                { 0.18, cf(0.05, -0.22, 0.88, 6, -10, 0) },
                { 0.36, cf(0.03, -0.92, 0.98, 12, -12, 0) },
                { 0.45, cf(-0.14, -1.55, 1.05, 18, 0, 0) },
                { 0.55, cf(0.03, -0.58, 0.94, 8, -8, 0) },
                { 0.63, cf(0.05, -0.20, 0.88, 6, -8, 0) },
                { 0.75, cf(-0.10, 0.24, 0.86, -8, 8, -8) },
                { 0.85, cf(-0.10, 0.22, 1.18, -10, 10, -8) },
                { 0.90, cf(-0.12, 0.18, 0.86, -4, 4, 0) },
                { 1.00, I },
            },
            magTrack = RIFLE_MAG_TRACK,
            boltTrack = RIFLE_BOLT_TRACK,
            leftDetachTrack = DETACH_MAG_SWAP,
            magHideWindow = { 0.39, 0.49 },
            shotMode = "Blowback",
        },
        SMG = {
            audioCues = { { 0.19, "MagOut" }, { 0.58, "MagIn" }, { 0.75, "BoltBack" }, { 0.87, "BoltForward" } },
            gunTrack = RIFLE_GUN_TRACK,
            leftArmTrack = {
                { 0.00, I },
                { 0.18, cf(0.04, -0.22, 0.58, 6, -10, 0) },
                { 0.36, cf(0.02, -0.90, 0.68, 12, -12, 0) },
                { 0.45, cf(-0.14, -1.50, 0.76, 18, 0, 0) },
                { 0.55, cf(0.03, -0.56, 0.64, 8, -8, 0) },
                { 0.63, cf(0.04, -0.20, 0.58, 6, -8, 0) },
                { 0.75, cf(-0.12, 0.24, 0.54, -8, 8, -8) },
                { 0.85, cf(-0.12, 0.22, 0.84, -10, 10, -8) },
                { 0.90, cf(-0.12, 0.18, 0.54, -4, 4, 0) },
                { 1.00, I },
            },
            magTrack = RIFLE_MAG_TRACK,
            boltTrack = RIFLE_BOLT_TRACK,
            leftDetachTrack = DETACH_MAG_SWAP,
            magHideWindow = { 0.39, 0.49 },
            shotMode = "Blowback",
        },
        Bulldog = {
            audioCues = { { 0.20, "MagOut" }, { 0.58, "MagIn" }, { 0.76, "BoltBack" }, { 0.88, "BoltForward" } },
            gunTrack = {
                { 0.00, I },
                { 0.18, cf(-0.14, 0.08, -0.18, 16, -24, -22) },
                { 0.32, cf(-0.14, 0.04, -0.16, 12, -24, -24) },
                { 0.58, cf(-0.10, 0.13, -0.16, 19, -20, -18) },
                { 0.74, cf(0.05, 0.06, 0.04, 8, 14, 15) },
                { 0.85, cf(0.04, 0.03, 0.10, 5, 12, 13) },
                { 1.00, I },
            },
            leftArmTrack = {
                { 0.00, I },
                { 0.20, cf(0.05, -0.24, 1.44, 10, -10, 0) },
                { 0.38, cf(0.02, -0.95, 1.50, 16, -12, 0) },
                { 0.46, cf(-0.14, -1.55, 1.56, 20, 0, 0) },
                { 0.56, cf(0.03, -0.58, 1.46, 10, -8, 0) },
                { 0.63, cf(0.05, -0.22, 1.42, 8, -8, 0) },
                { 0.75, cf(-0.14, 0.32, 0.24, -8, 8, -8) },
                { 0.85, cf(-0.14, 0.30, 0.56, -10, 10, -8) },
                { 0.90, cf(-0.14, 0.24, 0.24, -4, 4, 0) },
                { 1.00, I },
            },
            magTrack = RIFLE_MAG_TRACK,
            boltTrack = RIFLE_BOLT_TRACK,
            leftDetachTrack = DETACH_MAG_SWAP,
            magHideWindow = { 0.39, 0.49 },
            shotMode = "Blowback",
        },
        Pistol = {
            audioCues = { { 0.19, "MagOut" }, { 0.57, "MagIn" }, { 0.75, "BoltBack" }, { 0.87, "BoltForward" } },
            gunTrack = {
                { 0.00, I },
                { 0.18, cf(0.02, 0.08, 0.05, 18, -14, -24) },
                { 0.36, cf(0.01, 0.05, 0.06, 16, -14, -26) },
                { 0.58, cf(0.04, 0.14, 0.03, 22, -10, -20) },
                { 0.73, cf(0.05, 0.06, 0.04, 10, 12, 16) },
                { 0.84, cf(0.05, 0.03, 0.10, 6, 10, 14) },
                { 1.00, I },
            },
            leftArmTrack = {
                { 0.00, I },
                { 0.18, cf(-0.02, -0.14, 0.04, 8, 0, 0) },
                { 0.36, cf(-0.04, -0.78, 0.24, 16, 0, 0) },
                { 0.45, cf(-0.10, -1.42, 0.34, 22, 0, 0) },
                { 0.54, cf(-0.02, -0.48, 0.16, 10, 0, 0) },
                { 0.62, cf(0.01, -0.02, 0.02, 4, 0, 0) },
                { 0.74, cf(-0.02, 0.56, -0.24, -12, 10, -10) },
                { 0.84, cf(-0.02, 0.54, 0.08, -14, 12, -10) },
                { 0.89, cf(-0.04, 0.42, -0.20, -6, 6, 0) },
                { 1.00, I },
            },
            magTrack = {
                { 0.00, I },
                { 0.18, I },
                { 0.36, cf(0, -0.74, 0.22) },
                { 0.45, cf(-0.08, -1.35, 0.34) },
                { 0.52, cf(0, -0.62, 0.18) },
                { 0.61, I },
                { 1.00, I },
            },
            boltTrack = {
                { 0.00, I },
                { 0.74, I },
                { 0.84, cf(0, 0, 0.32) },
                { 0.89, I },
                { 1.00, I },
            },
            leftDetachTrack = DETACH_MAG_SWAP,
            magHideWindow = { 0.38, 0.48 },
            shotMode = "PistolSlide",
        },
        Sheriff = {
            audioCues = { { 0.09, "LatchOpen" }, { 0.26, "MagOut" }, { 0.60, "MagIn" }, { 0.83, "SnapShut" } },
            gunTrack = {
                { 0.00, I },
                { 0.16, cf(-0.04, 0.06, 0.05, 22, 12, -38) },
                { 0.26, cf(-0.06, 0.22, 0.08, 36, 12, -36) },
                { 0.42, cf(-0.04, 0.06, 0.05, 20, 14, -40) },
                { 0.62, cf(-0.04, 0.04, 0.08, 18, 14, -38) },
                { 0.78, cf(-0.02, 0.06, 0.04, 14, 8, -28) },
                { 0.85, cf(0.02, 0.08, 0.00, 6, -6, 12) },
                { 0.93, cf(0, 0.02, 0, 2, -2, -3) },
                { 1.00, I },
            },
            leftArmTrack = {
                { 0.00, I },
                { 0.16, cf(-0.22, -0.60, 0.35, 16, 0, 0) },
                { 0.36, cf(-0.24, -0.95, 0.25, 12, 0, 0) },
                { 0.46, cf(-0.22, 0.42, 0.14, -8, 12, 0) },
                { 0.60, cf(-0.22, 0.44, -0.14, -10, 14, 0) },
                { 0.72, cf(-0.26, -0.35, 0.18, 8, 6, 0) },
                { 0.86, cf(-0.08, -0.22, 0.10) },
                { 1.00, I },
            },
            magTrack = {
                { 0.00, cf(0, -0.80, 0.40) },
                { 0.36, cf(-0.04, -0.65, 0.34) },
                { 0.48, cf(-0.04, -0.02, 0.06) },
                { 0.60, cf(-0.04, -0.02, -0.22) },
                { 0.72, cf(-0.06, -0.45, 0.22) },
                { 1.00, cf(0, -0.80, 0.40) },
            },
            boltTrack = {
                { 0.00, I },
                { 0.08, pivotRot(Vector3.new(0, 0.12, 0.34), -18, 0, 0) },
                { 0.82, pivotRot(Vector3.new(0, 0.12, 0.34), -18, 0, 0) },
                { 0.90, I },
                { 1.00, I },
            },
            cylinderSwingTrack = {
                { 0.00, 0 }, { 0.08, 0 }, { 0.18, 88 }, { 0.76, 88 }, { 0.84, 0 }, { 1.00, 0 },
            },
            cylinderSpinTrack = {
                { 0.00, 0 }, { 0.20, 0 }, { 0.42, 240 }, { 0.76, 240 }, { 1.00, 240 },
            },
            leftDetachTrack = { { 0.00, 0 }, { 0.14, 0.8 }, { 0.74, 0.9 }, { 0.90, 0 }, { 1.00, 0 } },
            reloadOnlyShowWindows = { { 0.36, 0.72 } },
            shotMode = "Revolver",
        },
        Bucky = {
            audioCues = { { 0.12, "MagOut" }, { 0.29, "ShellIn" }, { 0.52, "ShellIn" }, { 0.74, "BoltBack" }, { 0.85, "BoltForward" } },
            gunTrack = {
                { 0.00, I },
                { 0.16, cf(0.08, 0.10, 0.04, 14, -14, -30) },
                { 0.30, cf(0.08, 0.13, 0.03, 16, -14, -28) },
                { 0.42, cf(0.08, 0.09, 0.04, 14, -14, -30) },
                { 0.54, cf(0.08, 0.13, 0.03, 16, -14, -28) },
                { 0.68, cf(0.02, 0.04, 0.02, 6, -4, -10) },
                { 0.76, cf(0.00, -0.02, 0.08, -3, 0, -4) },
                { 0.86, cf(0.00, 0.02, -0.03, 4, 0, 0) },
                { 1.00, I },
            },
            leftArmTrack = {
                { 0.00, I },
                { 0.18, cf(0.02, -0.58, 1.04, 12, -8, 0) },
                { 0.29, cf(0.04, -0.08, 1.00, 4, -8, 0) },
                { 0.41, cf(0.00, -0.62, 1.08, 14, -6, 0) },
                { 0.53, cf(0.04, -0.08, 1.00, 4, -8, 0) },
                { 0.66, I },
                { 0.76, cf(0, 0, 0.42) },
                { 0.85, I },
                { 1.00, I },
            },
            magTrack = {
                { 0.00, cf(0, -0.55, 0.10) },
                { 0.20, cf(0, -0.52, 0.12) },
                { 0.31, cf(0, 0.16, -0.06) },
                { 0.40, cf(0, 0.22, -0.14) },
                { 0.43, cf(0, -0.55, 0.12) },
                { 0.54, cf(0, 0.16, -0.06) },
                { 0.63, cf(0, 0.22, -0.14) },
                { 1.00, cf(0, -0.55, 0.10) },
            },
            boltTrack = {
                { 0.00, I }, { 0.68, I }, { 0.76, cf(0, 0, 0.42) }, { 0.85, I }, { 1.00, I },
            },
            pumpTrack = {
                { 0.00, I }, { 0.68, I }, { 0.76, cf(0, 0, 0.42) }, { 0.85, I }, { 1.00, I },
            },
            leftDetachTrack = {
                { 0.00, 0 }, { 0.16, 0.75 }, { 0.42, 0.85 }, { 0.64, 0.15 }, { 0.68, 0 }, { 1.00, 0 },
            },
            reloadOnlyShowWindows = { { 0.20, 0.40 }, { 0.44, 0.63 } },
            shotMode = "Pump",
        },
        Shorty = {
            audioCues = { { 0.09, "LatchOpen" }, { 0.25, "MagOut" }, { 0.50, "ShellIn" }, { 0.66, "ShellIn" }, { 0.85, "SnapShut" } },
            gunTrack = BREAK_GUN_TRACK,
            leftArmTrack = {
                { 0.00, I },
                { 0.22, cf(-0.04, 0.16, -0.20, -10, 0, 0) },
                { 0.38, cf(-0.08, -0.82, 0.32, 16, 0, 0) },
                { 0.50, cf(-0.04, 0.04, 0.06, -4, 0, 0) },
                { 0.70, cf(-0.02, 0.22, -0.22, -10, 0, 0) },
                { 0.84, cf(0.00, -0.02, 0.02) },
                { 1.00, I },
            },
            magTrack = BREAK_MAG_TRACK,
            boltTrack = BREAK_LATCH_TRACK,
            leftDetachTrack = DETACH_MAG_SWAP,
            magHideWindow = { 0.39, 0.47 },
            shotMode = "Break",
        },
        Outlaw = {
            audioCues = { { 0.09, "LatchOpen" }, { 0.25, "MagOut" }, { 0.50, "ShellIn" }, { 0.66, "ShellIn" }, { 0.85, "SnapShut" } },
            gunTrack = BREAK_GUN_TRACK,
            leftArmTrack = {
                { 0.00, I },
                { 0.22, cf(-0.02, 0.12, 0.82, -10, 0, 0) },
                { 0.38, cf(-0.08, -0.78, 1.05, 16, 0, 0) },
                { 0.52, cf(-0.04, -0.10, 0.92, 0, 0, 0) },
                { 0.70, cf(-0.02, 0.16, 0.78, -8, 0, 0) },
                { 0.85, cf(0, 0, 0.10) },
                { 1.00, I },
            },
            magTrack = BREAK_MAG_TRACK,
            boltTrack = BREAK_LATCH_TRACK,
            leftDetachTrack = DETACH_MAG_SWAP,
            magHideWindow = { 0.39, 0.47 },
            shotMode = "Break",
        },
        BeltFed = {
            audioCues = { { 0.11, "LatchOpen" }, { 0.26, "MagOut" }, { 0.58, "MagIn" }, { 0.73, "SnapShut" }, { 0.82, "BoltBack" }, { 0.91, "BoltForward" } },
            gunTrack = {
                { 0.00, I },
                { 0.16, cf(-0.06, 0.05, 0.06, 10, -10, -12) },
                { 0.36, cf(-0.10, -0.04, 0.08, 6, -16, -22) },
                { 0.62, cf(-0.06, 0.08, 0.05, 14, -14, -18) },
                { 0.75, cf(0.00, 0.02, 0.03, -6, 4, 4) },
                { 0.85, cf(0.04, 0.02, 0.08, 4, 8, 8) },
                { 1.00, I },
            },
            leftArmTrack = {
                { 0.00, I },
                { 0.14, cf(-0.04, 0.52, 0.58, -14, 0, 0) },
                { 0.38, cf(-0.16, -0.95, 0.90, 12, -10, 0) },
                { 0.46, cf(-0.18, -1.55, 0.98, 18, 0, 0) },
                { 0.62, cf(-0.10, -0.28, 0.88, 6, -8, 0) },
                { 0.74, cf(-0.04, 0.48, 0.58, -10, 0, 0) },
                { 0.83, cf(0.10, 0.22, 0.95, -6, 8, 0) },
                { 0.90, cf(0.10, 0.20, 1.24, -8, 10, 0) },
                { 1.00, I },
            },
            magTrack = {
                { 0.00, I },
                { 0.20, I },
                { 0.38, cf(-0.18, -0.95, 0.10, 0, 0, 12) },
                { 0.46, cf(-0.24, -1.65, 0.14) },
                { 0.52, cf(-0.14, -0.82, 0.08) },
                { 0.63, I },
                { 1.00, I },
            },
            boltTrack = {
                { 0.00, I },
                { 0.15, pivotRot(Vector3.new(0, 0.32, -0.52), -50, 0, 0) },
                { 0.68, pivotRot(Vector3.new(0, 0.32, -0.52), -50, 0, 0) },
                { 0.76, I },
                { 1.00, I },
            },
            leftDetachTrack = { { 0.00, 0 }, { 0.20, 0.3 }, { 0.42, 1.0 }, { 0.66, 0.2 }, { 0.80, 0 }, { 1.00, 0 } },
            magHideWindow = { 0.39, 0.49 },
            shotMode = "HeavyRattle",
        },
        Marshal = {
            audioCues = { { 0.10, "LatchOpen" }, { 0.34, "ShellIn" }, { 0.56, "ShellIn" }, { 0.82, "SnapShut" } },
            gunTrack = {
                { 0.00, I },
                { 0.16, cf(-0.06, 0.08, 0.06, 16, -18, -22) },
                { 0.56, cf(-0.06, 0.10, 0.06, 18, -18, -22) },
                { 0.82, cf(0.02, 0.06, 0.00, 4, 4, 8) },
                { 1.00, I },
            },
            leftArmTrack = {
                { 0.00, I },
                { 0.22, cf(0.16, -0.45, 1.05, 12, -14, 0) },
                { 0.35, cf(0.14, 0.06, 1.08, 4, -14, 0) },
                { 0.47, cf(0.16, -0.48, 1.05, 12, -14, 0) },
                { 0.58, cf(0.14, 0.06, 1.08, 4, -14, 0) },
                { 0.76, I },
                { 1.00, I },
            },
            magTrack = {
                { 0.00, cf(0.24, -0.20, 0.12) },
                { 0.24, cf(0.22, -0.16, 0.10) },
                { 0.36, cf(-0.02, 0, 0) },
                { 0.42, cf(-0.12, 0, -0.08) },
                { 0.46, cf(0.22, -0.16, 0.10) },
                { 0.58, cf(-0.02, 0, 0) },
                { 0.65, cf(-0.12, 0, -0.08) },
                { 1.00, cf(0.24, -0.20, 0.12) },
            },
            boltTrack = {
                { 0.00, I },
                { 0.16, pivotRot(Vector3.new(0, -0.14, 0.04), 48, 0, 0) },
                { 0.74, pivotRot(Vector3.new(0, -0.14, 0.04), 48, 0, 0) },
                { 0.84, I },
                { 1.00, I },
            },
            leftDetachTrack = { { 0.00, 0 }, { 0.18, 0.8 }, { 0.66, 0.8 }, { 0.80, 0 }, { 1.00, 0 } },
            reloadOnlyShowWindows = { { 0.24, 0.43 }, { 0.48, 0.66 } },
            shotMode = "Lever",
        },
        Operator = {
            audioCues = { { 0.19, "MagOut" }, { 0.58, "MagIn" }, { 0.75, "BoltBack" }, { 0.87, "BoltForward" } },
            gunTrack = RIFLE_GUN_TRACK,
            leftArmTrack = {
                { 0.00, I },
                { 0.18, cf(0.05, -0.22, 0.92, 6, -10, 0) },
                { 0.36, cf(0.03, -0.92, 1.02, 12, -12, 0) },
                { 0.45, cf(-0.14, -1.55, 1.10, 18, 0, 0) },
                { 0.55, cf(0.03, -0.58, 0.98, 8, -8, 0) },
                { 0.63, cf(0.05, -0.20, 0.92, 6, -8, 0) },
                { 0.75, cf(-0.10, 0.24, 0.90, -8, 8, -8) },
                { 0.85, cf(-0.10, 0.22, 1.24, -10, 10, -8) },
                { 0.90, cf(-0.12, 0.18, 0.90, -4, 4, 0) },
                { 1.00, I },
            },
            magTrack = RIFLE_MAG_TRACK,
            boltTrack = {
                { 0.00, I },
                { 0.72, I },
                { 0.76, pivotRot(Vector3.new(0.15, 0.16, 0.42), 0, 0, 42) },
                { 0.85, cf(0, 0, 0.38) * pivotRot(Vector3.new(0.15, 0.16, 0.42), 0, 0, 42) },
                { 0.92, I },
                { 1.00, I },
            },
            leftDetachTrack = DETACH_MAG_SWAP,
            magHideWindow = { 0.39, 0.49 },
            shotMode = "BoltAction",
        },
    }

    getWeaponAnimProfile = function(weaponCfg)
        local wName = (weaponCfg and weaponCfg.Name or ""):upper()
        local wType = weaponCfg and weaponCfg.Type or "Rifle"
        if WEAPON_ANIM_PROFILES[wName] then
            return WEAPON_ANIM_PROFILES[wName]
        elseif wName == "BUCKY" then
            return WEAPON_ANIM_PROFILES.Bucky
        elseif wName == "SHERIFF" then
            return WEAPON_ANIM_PROFILES.Sheriff
        elseif wName == "SHORTY" then
            return WEAPON_ANIM_PROFILES.Shorty
        elseif wName == "OUTLAW" then
            return WEAPON_ANIM_PROFILES.Outlaw
        elseif wName == "BULLDOG" then
            return WEAPON_ANIM_PROFILES.Bulldog
        elseif wName == "MARSHAL" then
            return WEAPON_ANIM_PROFILES.Marshal
        elseif wName == "OPERATOR" then
            return WEAPON_ANIM_PROFILES.Operator
        elseif wName == "ARES" or wName == "ODIN" then
            return WEAPON_ANIM_PROFILES.BeltFed
        elseif wType == "Pistol" or wType == "Revolver" then
            return WEAPON_ANIM_PROFILES.Pistol
        elseif wType == "SMG" then
            return WEAPON_ANIM_PROFILES.SMG
        end
        return WEAPON_ANIM_PROFILES.Rifle
    end

    local function windowContains(win, p)
        return win ~= nil and p >= win[1] and p <= win[2]
    end

    solveWeaponAnimPose = function(dt, weaponCfg, reloadActive, reloadProg, inspectActive, isAimActive, isSprintActive)
        local profile = getWeaponAnimProfile(weaponCfg)
        local targetGunCF, targetLeftArmCF = I, I
        local magCF, boltCF, pumpCF, cylinderCF = I, I, I, I
        local targetDetachAlpha = 0
        local showMag = true
        local showReloadOnly = false

        -- 1. แอนิเมชันหมุนลูกโม่ / กระชากสไลด์-ปั๊ม-ลูกเลื่อนทุกนัดที่ยิง
        local targetCylDeg = weaponAnimState.cylinderIndex * 60
        local cylLerp = math.clamp(dt * 24, 0, 1)
        weaponAnimState.currentCylinderAngle = weaponAnimState.currentCylinderAngle + (targetCylDeg - weaponAnimState.currentCylinderAngle) * cylLerp

        local dtShot = os.clock() - weaponAnimState.lastShotTime
        local shotMode = profile.shotMode
        if dtShot >= 0 then
            if shotMode == "Blowback" or shotMode == "PistolSlide" then
                if dtShot < 0.095 then
                    local p = dtShot / 0.095
                    local back = (p < 0.28) and (p / 0.28) or (1 - (p - 0.28) / 0.72)
                    boltCF = CFrame.new(0, 0, (shotMode == "PistolSlide" and 0.28 or 0.22) * smooth01(back))
                end
            elseif shotMode == "Pump" then
                if dtShot > 0.14 and dtShot < 0.44 then
                    local s = math.sin(((dtShot - 0.14) / 0.30) * math.pi)
                    local travel = 0.42 * smooth01(s)
                    pumpCF = CFrame.new(0, 0, travel)
                    boltCF = CFrame.new(0, 0, travel)
                    targetLeftArmCF = CFrame.new(0, 0, travel)
                    targetGunCF = cf(0, -0.015 * s, 0.05 * s, -2.5 * s, 0, -3 * s)
                end
            elseif shotMode == "BoltAction" then
                if dtShot > 0.15 and dtShot < 0.62 then
                    local u = (dtShot - 0.15) / 0.47
                    local lift = (u < 0.22) and smooth01(u / 0.22) or ((u > 0.78) and smooth01((1 - u) / 0.22) or 1)
                    local pull = (u > 0.20 and u < 0.80) and math.sin(((u - 0.20) / 0.60) * math.pi) or 0
                    boltCF = cf(0, 0, 0.38 * smooth01(pull)) * pivotRot(Vector3.new(0.15, 0.16, 0.42), 0, 0, 42 * lift)
                    targetGunCF = cf(0.02 * lift, 0.02 * lift, 0.04 * pull, 3 * lift, -4 * lift, -6 * lift)
                end
            elseif shotMode == "Lever" then
                if dtShot > 0.14 and dtShot < 0.50 then
                    local s = math.sin(((dtShot - 0.14) / 0.36) * math.pi)
                    boltCF = pivotRot(Vector3.new(0, -0.14, 0.04), 44 * smooth01(s), 0, 0)
                    targetGunCF = cf(0, 0.015 * s, 0.03 * s, 4 * s, 0, -4 * s)
                end
            elseif shotMode == "Revolver" then
                if dtShot < 0.08 then
                    local s = math.sin((dtShot / 0.08) * math.pi)
                    boltCF = pivotRot(Vector3.new(0, 0.12, 0.34), -32 * s, 0, 0)
                end
            elseif shotMode == "HeavyRattle" then
                if dtShot < 0.07 then
                    local s = math.sin((dtShot / 0.07) * math.pi)
                    boltCF = cf(0, 0.015 * s, 0)
                end
            end
        end

        -- 2. แอนิเมชันรีโหลดหลายเฟส + ซิงค์มือ/แม็ก/ลูกเลื่อน
        local cylSwingDeg, cylReloadSpinDeg = 0, 0
        if reloadActive then
            local p = math.clamp(reloadProg, 0, 1)
            targetGunCF = evalCFTrack(profile.gunTrack, p)
            targetLeftArmCF = evalCFTrack(profile.leftArmTrack, p)
            magCF = evalCFTrack(profile.magTrack, p)
            boltCF = evalCFTrack(profile.boltTrack, p)
            pumpCF = evalCFTrack(profile.pumpTrack, p)
            targetDetachAlpha = evalScalarTrack(profile.leftDetachTrack, p)

            if profile.magHideWindow and windowContains(profile.magHideWindow, p) then
                showMag = false
            end
            if profile.reloadOnlyShowWindows then
                for _, win in ipairs(profile.reloadOnlyShowWindows) do
                    if windowContains(win, p) then
                        showReloadOnly = true
                        break
                    end
                end
            end
            if profile.cylinderSwingTrack then
                cylSwingDeg = evalScalarTrack(profile.cylinderSwingTrack, p)
            end
            if profile.cylinderSpinTrack then
                cylReloadSpinDeg = evalScalarTrack(profile.cylinderSpinTrack, p)
            end
        elseif inspectActive and not isAimActive and not isSprintActive then
            weaponAnimState.inspectTimer = weaponAnimState.inspectTimer + dt
            if weaponAnimState.inspectTimer >= INSPECT_DURATION then
                isInspecting = false
                weaponAnimState.inspectTimer = 0
            else
                local ip = weaponAnimState.inspectTimer / INSPECT_DURATION
                targetGunCF = evalCFTrack(INSPECT_GUN_TRACK, ip)
                targetLeftArmCF = evalCFTrack(INSPECT_LEFT_TRACK, ip)
            end
        end

        -- หมุน & กางลูกโม่ Sheriff
        local totalSpinRad = math.rad(weaponAnimState.currentCylinderAngle + cylReloadSpinDeg)
        local spinCF = CFrame.new(0, 0.05, -0.15) * CFrame.Angles(0, 0, totalSpinRad) * CFrame.new(0, -0.05, 0.15)
        if math.abs(cylSwingDeg) > 0.01 then
            local swingCF = pivotRot(Vector3.new(-0.16, -0.11, -0.15), 0, 0, cylSwingDeg)
            cylinderCF = swingCF * spinCF
        elseif totalSpinRad ~= 0 then
            cylinderCF = spinCF
        end

        local blendRate = math.clamp(dt * (reloadActive and 26 or 18), 0, 1)
        weaponAnimState.gunAnimCF = weaponAnimState.gunAnimCF:Lerp(targetGunCF, blendRate)
        weaponAnimState.leftArmAnimCF = weaponAnimState.leftArmAnimCF:Lerp(targetLeftArmCF, blendRate)
        weaponAnimState.leftDetachAlpha = weaponAnimState.leftDetachAlpha + (targetDetachAlpha - weaponAnimState.leftDetachAlpha) * blendRate

        return weaponAnimState.gunAnimCF,
            weaponAnimState.leftArmAnimCF,
            weaponAnimState.leftDetachAlpha,
            magCF,
            boltCF,
            pumpCF,
            cylinderCF,
            showMag,
            showReloadOnly
    end
end

local function reloadWeapon()
    if isReloading or clipAmmo >= currentWeapon.Mag or reserveAmmo <= 0 or not weaponReloadEvent then return end
    reloadSequence = reloadSequence + 1
    local thisReload = reloadSequence
    local reloadWeaponCfg = currentWeapon
    local profile = getWeaponAnimProfile(reloadWeaponCfg)

    reloadTimeTotal = currentWeapon.ReloadTime or 2.0
    isReloading = true
    weaponReloadEvent:FireServer(currentWeaponKey)
    isAiming = false
    isInspecting = false
    weaponAnimState.inspectTimer = 0
    opticsUI:SetAiming(false, currentWeapon)
    reloadTimer = 0
    updateAmmoUI()

    if profile and profile.audioCues then
        for _, cue in ipairs(profile.audioCues) do
            task.delay(cue[1] * reloadTimeTotal, function()
                if thisReload == reloadSequence then
                    WeaponAudio.playReloadStage(reloadWeaponCfg, cue[2])
                end
            end)
        end
    end

    task.wait(reloadTimeTotal + 0.15)
    if thisReload ~= reloadSequence then return end
    isReloading = false
    updateAmmoUI()
end

----------------------------------------------------------------------
-- 6. ตัวเลขดาเมจลอย & โฟลเดอร์เอฟเฟกต์กระสุน (DAMAGE POPUP & EFFECTS)
----------------------------------------------------------------------
local clientEffectsFolder = Workspace:FindFirstChild("ClientBulletEffects") or Instance.new("Folder")
clientEffectsFolder.Name = "ClientBulletEffects"
clientEffectsFolder.Parent = Workspace

local function showDamagePopup(pos, damage, isHeadshot)
    local pPart = Instance.new("Part")
    pPart.Size = Vector3.new(0.1, 0.1, 0.1)
    pPart.CFrame = CFrame.new(pos + Vector3.new((math.random() - 0.5) * 1.5, 1.5, (math.random() - 0.5) * 1.5))
    pPart.Transparency = 1
    pPart.CanCollide = false
    pPart.CanQuery = false
    pPart.CanTouch = false
    pPart.Anchored = true
    pPart.Parent = clientEffectsFolder

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

-- Show hit markers and damage numbers only after the server confirms a hit.
if weaponHitFeedbackEvent then
    weaponHitFeedbackEvent.OnClientEvent:Connect(function(hitPosition, confirmedDamage, isHeadshot)
        if typeof(hitPosition) ~= "Vector3" or type(confirmedDamage) ~= "number" then return end
        local headshot = isHeadshot == true
        WeaponAudio.playHit(headshot)
        showDamagePopup(hitPosition, math.floor(confirmedDamage + 0.5), headshot)
        hitmarker.ImageColor3 = headshot and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 190, 50)
        hitmarker.ImageTransparency = 0
        task.delay(0.08, function() hitmarker.ImageTransparency = 1 end)
    end)
end

----------------------------------------------------------------------
-- 7. ระบบการโจมตี (BALLISTICS & MELEE SLASH ENGINE)
----------------------------------------------------------------------
local function executeAttack()
    if isReloading or buyMenuObj.Frame.Visible then return end
    isInspecting = false

    -- 🔫 ยิงปืน (Gunfire)
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
    weaponAnimState.lastShotTime = now
    weaponAnimState.cylinderIndex = (weaponAnimState.cylinderIndex + 1) % 6
    weaponAnimState.inspectTimer = 0
    clipAmmo = math.max(0, clipAmmo - 1)
    if slotAmmoCache[activeSlot] and slotAmmoCache[activeSlot].key == currentWeaponKey then
        slotAmmoCache[activeSlot].clip = clipAmmo
    end
    updateAmmoUI()

    WeaponAudio.playShot(currentWeapon)

    -- 🎯 สไนเปอร์ทุกประเภท (ยกเว้น Outlaw) ยิง 1 นัดแล้วต้องถอนสโคปออกทันที (Auto-descope after 1 shot)
    -- ยกเว้น Outlaw ที่เป็นปืนสไนเปอร์ลูกซอง 2 ลำกล้อง สามารถยิงติดต่อกันได้ 2 นัดโดยไม่ต้องถอนสโคป
    local wName = (currentWeapon.Name or ""):upper()
    if currentWeapon.IsSniper and wName ~= "OUTLAW" then
        if isAiming then
            isAiming = false
            opticsUI:SetAiming(false, currentWeapon)
        end
    end

    local rec = currentWeapon.Recoil or { KickZ = 0.4, PitchX = 4, YawY = 1.2 }
    recoilSpring:Impulse(Vector3.new(
        math.rad(isAiming and (rec.PitchX * 0.7) or rec.PitchX),
        math.rad((math.random() - 0.5) * rec.YawY),
        isAiming and (rec.KickZ * 0.6) or rec.KickZ
    ))

    -- 🌟 ประกายไฟปลายกระบอก 3D Starburst & แสงสว่างจ้าสมจริง
    if muzzleFlashParts and #muzzleFlashParts > 0 then
        local isShotgun = (currentWeapon.Type == "Shotgun")
        local isSniper = (currentWeapon.IsSniper == true)
        local isSilenced = (currentWeapon.Audio and currentWeapon.Audio.Silenced)

        -- สุ่มหมุนองศาเปลวไฟให้มีมิติเคลื่อนไหวสมจริง
        muzzleFlashRollAngle = (muzzleFlashRollAngle + math.random(35, 75)) % 360

        for _, p in ipairs(muzzleFlashParts) do
            if p and p.Parent then
                p.Transparency = 0
            end
        end

        if flashLight then
            flashLight.Brightness = isShotgun and 22 or (isSniper and 26 or 14)
            flashLight.Range = isShotgun and 42 or (isSniper and 45 or 32)
        end

        if muzzleSmokeEmitter then
            muzzleSmokeEmitter:Emit(isShotgun and 10 or 4)
        end

        local shotTime = os.clock()
        lastMuzzleFlashTime = shotTime
        task.delay(0.065, function()
            if lastMuzzleFlashTime == shotTime then
                for _, p in ipairs(muzzleFlashParts) do
                    if p and p.Parent then
                        p.Transparency = 1
                    end
                end
                if flashLight then
                    flashLight.Brightness = 0
                end
            end
        end)
    end

    camera.CFrame = camera.CFrame * CFrame.Angles(
        math.rad(isAiming and 0.25 or 0.55),
        math.rad((math.random() - 0.5) * 0.3),
        0
    )

    local pellets = currentWeapon.Pellets or 1
    local rayOrigin = camera.CFrame.Position
    local baseDir = camera.CFrame.LookVector
    if weaponFireEvent then
        weaponFireEvent:FireServer(currentWeaponKey, rayOrigin, baseDir.Unit)
    end

    local ignoreList = { clientEffectsFolder, camera }
    if viewmodel then table.insert(ignoreList, viewmodel) end
    if player.Character then table.insert(ignoreList, player.Character) end
    local f3 = Workspace:FindFirstChild("Floor_3_SportsArena")
    local cage = f3 and f3:FindFirstChild("FutsalSteelMeshCage")
    local passCol = cage and cage:FindFirstChild("BulletPassColliders")
    if passCol then table.insert(ignoreList, passCol) end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = ignoreList
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true

    local muzzlePos = (muzzleFlashParts[1] and muzzleFlashParts[1].Position) or rayOrigin

    for i = 1, pellets do
        local spread = (pellets > 1) and Vector3.new((math.random() - 0.5) * 0.08, (math.random() - 0.5) * 0.08, (math.random() - 0.5) * 0.08) or Vector3.zero
        local shotDir = (baseDir + spread).Unit * 500

        local hit = Workspace:Raycast(rayOrigin, shotDir, rayParams)
        local tracerEnd = hit and hit.Position or (rayOrigin + shotDir)

        local dist = (tracerEnd - muzzlePos).Magnitude
        if dist > 0.5 then
            local isShotgun = (currentWeapon.Type == "Shotgun")
            local tracer = Instance.new("Part")
            tracer.Size = isShotgun and Vector3.new(0.12, 0.12, dist) or Vector3.new(0.08, 0.08, dist)
            tracer.CFrame = CFrame.lookAt((muzzlePos + tracerEnd) / 2, tracerEnd)
            tracer.Color = (currentWeapon.Audio and currentWeapon.Audio.Silenced) and Color3.fromRGB(100, 220, 255) or (isShotgun and Color3.fromRGB(255, 175, 45) or Color3.fromRGB(255, 220, 95))
            tracer.Material = Enum.Material.Neon
            tracer.CanCollide = false
            tracer.CanQuery = false
            tracer.CanTouch = false
            tracer.Anchored = true
            tracer.Parent = clientEffectsFolder
            Debris:AddItem(tracer, 0.075)
        end

        if hit and hit.Instance then
            local spark = Instance.new("Part")
            spark.Size = Vector3.new(0.2, 0.2, 0.2)
            spark.CFrame = CFrame.new(hit.Position)
            spark.Color = Color3.fromRGB(255, 230, 150)
            spark.Material = Enum.Material.Neon
            spark.Anchored = true
            spark.CanCollide = false
            spark.CanQuery = false
            spark.CanTouch = false
            spark.Parent = clientEffectsFolder
            Debris:AddItem(spark, 0.05)
        end
    end
end

----------------------------------------------------------------------
-- 8. ตรวจจับการกดปุ่ม & เมาส์ (INPUTS & HOTKEYS)
----------------------------------------------------------------------
-- 🌟 ContextActionService: ผูกปุ่มลัดสลับช่อง 1, 2, 3 และ Q ด้วย Priority สูงสุดเพื่อไม่ให้ CoreGui แย่ง
ContextActionService:BindActionAtPriority(
    "WeaponSlot1",
    function(_, state)
        if state == Enum.UserInputState.Begin and equipSlot then
            equipSlot(1)
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end,
    false,
    Enum.ContextActionPriority.High.Value + 200,
    Enum.KeyCode.One, Enum.KeyCode.KeypadOne
)

ContextActionService:BindActionAtPriority(
    "WeaponSlot2",
    function(_, state)
        if state == Enum.UserInputState.Begin and equipSlot then
            equipSlot(2)
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end,
    false,
    Enum.ContextActionPriority.High.Value + 200,
    Enum.KeyCode.Two, Enum.KeyCode.KeypadTwo
)

ContextActionService:BindActionAtPriority(
    "QuickSwitchQ",
    function(_, state)
        if state == Enum.UserInputState.Begin and equipSlot then
            local nextSlot = (activeSlot == 1) and 2 or 1
            equipSlot(nextSlot)
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end,
    false,
    Enum.ContextActionPriority.High.Value + 200,
    Enum.KeyCode.Q
)

UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end

    -- 🌟 สลับช่องอาวุธ 1, 2, Q (InputBegan Fallback)
    if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
        if equipSlot then equipSlot(1) end
        return
    elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.KeypadTwo then
        if equipSlot then equipSlot(2) end
        return
    elseif input.KeyCode == Enum.KeyCode.Q then
        if equipSlot then
            local nextSlot = (activeSlot == 1) and 2 or 1
            equipSlot(nextSlot)
        end
        return
    end

    -- 👑 กดปุ่ม [G] เพื่อสลับเปิด/ปิด โหมด ADMIN (อันลิมิต Stamina + อมตะ + วิ่งไว)
    if input.KeyCode == Enum.KeyCode.G then
        toggleAdminMode()
        return
    end

    -- ⚡ กด Shift เพื่อวิ่งเร็ว (Sprint)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        isShiftDown = true
        return
    end

    -- [Y] inspect is separate from the elevator's [F] interaction.
    if input.KeyCode == Enum.KeyCode.Y then
        if isReloading or isAiming or isSprinting then
            isInspecting = false
        else
            isInspecting = not isInspecting
            if isInspecting then
                weaponAnimState.inspectTimer = 0
                WeaponAudio.playClick(2.4)
            end
        end
        return
    end

    -- [B] เปิด/ปิด คลังแสง Valorant
    if input.KeyCode == Enum.KeyCode.B then
        if mapMenuFrame.Visible then toggleMapMenu(false) end
        toggleBuyMenu()
        return
    end

    if input.KeyCode == Enum.KeyCode.L then
        toggleFlashlight()
        return
    end

    if input.KeyCode == Enum.KeyCode.N then
        toggleLightingMode()
        return
    end

    -- [M] เปิด/ปิด เมนูเลือกแมพและโซน (Map Selector)
    if input.KeyCode == Enum.KeyCode.M then
        if buyMenuObj.Frame.Visible then toggleBuyMenu() end
        toggleMapMenu()
        return
    end

    -- [Left Alt] ปลดล็อคเมาส์อิสระ
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        isCursorFree = not isCursorFree
        setCameraFrozen(isCursorFree)
        return
    end

    if buyMenuObj.Frame.Visible or isAnyModalOpen() then return end

    -- คลิกซ้าย: โจมตี (ยิงปืน หรือ ตวัดฟันมีด)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isCursorFree and gp then return end
        if isCursorFree then
            isCursorFree = false
            setCameraFrozen(false)
        end
        isMouseDown = true
        executeAttack()
    -- คลิกขวา: เล็ง ADS
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = true
        isInspecting = false
        opticsUI:SetAiming(true, currentWeapon)
    -- [R] รีโหลด
    elseif input.KeyCode == Enum.KeyCode.R then
        reloadWeapon()
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        isShiftDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = false
        opticsUI:SetAiming(false, currentWeapon)
    end
end)

UserInputService.InputChanged:Connect(function(input, gp)
    if buyMenuObj.Frame.Visible or isAnyModalOpen() then return end

    -- 🌟 หมุนลูกกลิ้งเมาส์สลับช่อง 1 <-> 2
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        local nextSlot = (activeSlot == 1) and 2 or 1
        if equipSlot then equipSlot(nextSlot) end
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement and not isCursorFree then
        -- แปลง Delta ให้เป็นการขยับที่นิ่งสนิทและเนียนตา (Smooth Micro-Sway ไม่ส่ายเวียนหัว)
        targetMouseSwayX = math.clamp(input.Delta.X * 0.0003, -0.012, 0.012)
        targetMouseSwayY = math.clamp(input.Delta.Y * 0.0003, -0.012, 0.012)
    end
end)

-- Heartbeat: Full-Auto firing loop
RunService.Heartbeat:Connect(function()
    if isMouseDown and not isReloading and currentWeapon.FiringType == "Auto" and not buyMenuObj.Frame.Visible and not isAnyModalOpen() then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            executeAttack()
        else
            isMouseDown = false
        end
    end
end)

----------------------------------------------------------------------
-- 9. อัปเดตแอนิเมชันทุกเฟรม (RENDER STEPPED // SPRINT & STAMINA & KNIFE SPINS)
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    -- 0. ระบบพละกำลัง การวิ่งเร็ว และความเร็วตัวละคร (Sprint & Stamina Engine)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local vel = hrp and hrp.AssemblyLinearVelocity.Magnitude or 0
    local isMoving = (vel > 1.5)
    local isDead = (not hum or hum.Health <= 0)

    -- เงื่อนไขการสปรินต์: กด Shift, กำลังเคลื่อนที่, ไม่ได้เล็ง ADS, ไม่ได้หมดแรง, มีพลังงานเหลือ, และไม่ได้เปิดเมนู
    if isAdminMode then
        currentStamina = MAX_STAMINA
        isExhausted = false
        isSprinting = isShiftDown and isMoving and (not isAiming) and (not buyMenuObj.Frame.Visible) and (not isDead)
    else
        local canSprint = isShiftDown and isMoving and (not isAiming) and (not isExhausted) and (currentStamina > 0) and (not buyMenuObj.Frame.Visible) and (not isDead)

        if canSprint then
            isSprinting = true
            lastSprintTime = os.clock()
            currentStamina = math.max(0, currentStamina - STAMINA_DRAIN_PER_SEC * dt)
            if currentStamina <= 0 then
                isExhausted = true
                isSprinting = false
                WeaponAudio.playClick(1.4) -- เสียงลมหายใจสะดุดเบาๆ บ่งบอกว่าหมดแรง
            end
        else
            isSprinting = false
            -- รีเจนพลังงานหลังจากหยุดวิ่งตามดีเลย์ที่กำหนด
            if os.clock() - lastSprintTime >= STAMINA_REGEN_DELAY then
                currentStamina = math.min(MAX_STAMINA, currentStamina + STAMINA_REGEN_PER_SEC * dt)
                if isExhausted and currentStamina >= EXHAUSTION_RECOVERY_POINT then
                    isExhausted = false -- ฟื้นฟูกลับมาจนพร้อมวิ่งได้อีกครั้ง
                end
            end
        end
    end

    -- อัปเดต WalkSpeed ของ Humanoid (โหมด Admin วิ่งไวพิเศษ!)
    if hum and hum.Health > 0 then
        if isAdminMode then
            hum.WalkSpeed = isSprinting and SPRINT_SPEED_ADMIN or WALK_SPEED_ADMIN
        elseif isSprinting then
            hum.WalkSpeed = SPRINT_SPEED
        elseif isExhausted then
            hum.WalkSpeed = EXHAUSTED_SPEED
        else
            hum.WalkSpeed = WALK_SPEED_NORMAL
        end
    end

    -- อัปเดตแถบ UI Stamina และ HP ผู้เล่น
    updateStaminaUI()
    updateHealthUI(hum)

    -- 1. ADS Target Offset
    local adsTarget = (currentWeapon.Optics and currentWeapon.Optics.Offset) or CFrame.new(0, -0.42, -1.15)
    local hipTarget = currentWeapon.HipOffset or CFrame.new(0.60, -0.55, -1.35)
    local targetOffset = isAiming and adsTarget or hipTarget
    currentOffset = currentOffset:Lerp(targetOffset, math.clamp(dt * 18, 0, 1))

    -- 2. FOV Zoom & Sprint Dynamic FOV Kick
    local targetFov = 70
    if isAiming then
        targetFov = (currentWeapon.Optics and currentWeapon.Optics.ZoomFOV) or 52
    elseif isSprinting and isMoving then
        targetFov = 76 -- Dynamic Sprint FOV ขยายมุมมองกว้างขึ้นเพื่อความสะใจ
    end
    camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * math.clamp(dt * 15, 0, 1)

    -- 3. อัปเดตสปริงแรงถีบ (Spring Recoil)
    local recSpringVec = recoilSpring:Update(dt)

    -- 4. การโยกตัวตามจังหวะก้าวเดิน (Subtle Tactical Bobbing - นิ่งสนิท สไตล์ Valorant)
    local bobFreq = 2.0
    local bobAmp = 0.002
    if isSprinting and isMoving then
        bobFreq = 10.0
        bobAmp = 0.016 -- วิ่งนุ่มนวล ไม่โยกเวียนหัว
    elseif isMoving then
        bobFreq = 7.0
        bobAmp = 0.007 -- เดินนิ่ง คมชัด สบายตา
    end
    if isAiming then bobAmp = bobAmp * 0.05 end

    swayTimer = swayTimer + dt * bobFreq
    local bobX = math.sin(swayTimer) * bobAmp
    local bobY = math.abs(math.cos(swayTimer)) * (bobAmp * 0.6)

    -- อัปเดต Mouse Sway แบบนุ่มนวล ไม่หมุนเหวี่ยง (สูงสุดแค่ ~1 องศา)
    currentMouseSwayX = currentMouseSwayX + (targetMouseSwayX - currentMouseSwayX) * math.clamp(dt * 20, 0, 1)
    currentMouseSwayY = currentMouseSwayY + (targetMouseSwayY - currentMouseSwayY) * math.clamp(dt * 20, 0, 1)
    targetMouseSwayX = targetMouseSwayX * math.exp(-dt * 18)
    targetMouseSwayY = targetMouseSwayY * math.exp(-dt * 18)

    local swayRotX = math.rad(-currentMouseSwayY * 80)
    local swayRotY = math.rad(-currentMouseSwayX * 80)
    local swayRollZ = math.rad(currentMouseSwayX * 35)

    -- 5. แอนิเมชัน 3D ครบวงจร (รีโหลดหลายเฟส / ส่องปืน [Y] / ลูกเลื่อน / ปั๊ม / ลูกโม่)
    local reloadProg = 0
    if isReloading then
        reloadTimer = reloadTimer + dt
        reloadProg = math.clamp(reloadTimer / math.max(0.1, reloadTimeTotal), 0, 1)
    end
    if isSprinting or isAiming or isReloading then
        isInspecting = false
        if not isInspecting then
            weaponAnimState.inspectTimer = 0
        end
    end

    local gunAnimCF, leftArmAnimCF, leftDetachAlpha, magCF, boltCF, pumpCF, cylinderCF, showMag, showReloadOnly =
        solveWeaponAnimPose(dt, currentWeapon, isReloading, reloadProg, isInspecting, isAiming, isSprinting)

    -- 🌟 6. มุมเอียงปืนขณะวิ่ง (Tactical Sprint Weapon Tilt)
    local targetSprintOffset = CFrame.identity
    if isSprinting and isMoving and not isAiming then
        targetSprintOffset = CFrame.new(-0.04, -0.06, -0.05) * CFrame.Angles(math.rad(-3), math.rad(-5), math.rad(4))
    end
    currentSprintCFrame = currentSprintCFrame:Lerp(targetSprintOffset, math.clamp(dt * 12, 0, 1))

    -- 7. ประกอบ CFrame Viewmodel (นิ่ง แม่นยำ สบายตา สไตล์ Valorant)
    local motionCFrame = CFrame.new(bobX - currentMouseSwayX * 0.4, bobY - currentMouseSwayY * 0.4, recSpringVec.Z) * CFrame.Angles(
        recSpringVec.X + swayRotX,
        recSpringVec.Y + swayRotY,
        swayRollZ
    ) * currentSprintCFrame

    local isSniperAiming = isAiming and currentWeapon.IsSniper
    local baseRootCF = isSniperAiming and CFrame.new(0, -999, 0) or (camera.CFrame * currentOffset * motionCFrame)
    local finalRootCF = isSniperAiming and baseRootCF or (baseRootCF * gunAnimCF)
    local leftArmRootCF = isSniperAiming and baseRootCF or (baseRootCF * gunAnimCF:Lerp(CFrame.identity, leftDetachAlpha) * leftArmAnimCF)
    gunRoot.CFrame = finalRootCF

    -- ปรับตำแหน่งชิ้นส่วนแขนและชิ้นส่วนเคลื่อนไหวของปืน
    for part, relCF in pairs(rigParts) do
        if part and part.Parent then
            if leftArmParts[part] then
                part.CFrame = leftArmRootCF * relCF
            elseif weaponAnimGroups.ReloadOnly[part] then
                part.Transparency = showReloadOnly and (rigPartBaseTransparency[part] or 0) or 1
                part.CFrame = finalRootCF * magCF * relCF
            elseif weaponAnimGroups.Magazine[part] then
                part.Transparency = showMag and (rigPartBaseTransparency[part] or 0) or 1
                part.CFrame = finalRootCF * magCF * relCF
            elseif weaponAnimGroups.Bolt[part] then
                part.CFrame = finalRootCF * boltCF * relCF
            elseif weaponAnimGroups.Pump[part] then
                part.CFrame = finalRootCF * pumpCF * relCF
            elseif weaponAnimGroups.Cylinder[part] then
                part.CFrame = finalRootCF * cylinderCF * relCF
            elseif part.Name:match("MuzzleFlashFlame") then
                -- หมุนเปลวไฟปากกระบอกแบบไดนามิก
                part.CFrame = finalRootCF * relCF * CFrame.Angles(0, 0, math.rad(muzzleFlashRollAngle))
            else
                part.CFrame = finalRootCF * relCF
            end
        end
    end
end)

-- เริ่มต้นอาวุธแรก
rebuildViewmodel()
updateSlotUI()
updateAmmoUI()
updateStaminaUI()

print("=========================================================")
print("🏆 [Sprint & Stamina & 2-Slot Arsenal] ระบบวิ่งสปรินต์ พลังงานจำกัด และช่องอาวุธ [1] ปืนหลัก [2] ปืนรอง พร้อมแล้ว!")
print("=========================================================")
print("=========================================================")
