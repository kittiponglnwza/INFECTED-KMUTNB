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
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local newCam = Workspace.CurrentCamera
    if newCam then
        camera = newCam
    end
end)

player.CameraMode = Enum.CameraMode.LockFirstPerson

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
local playerDamageEvent = zombieEvents and zombieEvents:WaitForChild("PlayerDamageEvent", 10)
local waveAnnounceEvent = zombieEvents and zombieEvents:WaitForChild("WaveAnnounce", 10)
local toggleAdminEvent = zombieEvents and zombieEvents:WaitForChild("ToggleAdminMode", 10)

-- All weapon fire, reload, ammo and damage decisions are validated by the server.
local weaponCombatEvents = ReplicatedStorage:WaitForChild("WeaponCombatEvents", 10)
local weaponFireEvent = weaponCombatEvents and weaponCombatEvents:WaitForChild("FireWeapon", 10)
local weaponReloadEvent = weaponCombatEvents and weaponCombatEvents:WaitForChild("ReloadWeapon", 10)
local weaponAmmoSyncEvent = weaponCombatEvents and weaponCombatEvents:WaitForChild("AmmoSync", 10)
local weaponHitFeedbackEvent = weaponCombatEvents and weaponCombatEvents:WaitForChild("HitFeedback", 10)

----------------------------------------------------------------------
-- 1. ระบบจัดการ 2 ช่องอาวุธ (2-SLOT INVENTORY SYSTEM: PRIMARY & SECONDARY)
----------------------------------------------------------------------
local inventorySlots = {
    [1] = "Classic", -- ผู้เล่นเริ่มด้วยปืนพกเพียงกระบอกเดียว
    [2] = nil,       -- ไม่มีช่องปืนสำรอง: ถือได้ครั้งละ 1 กระบอกเท่านั้น
}
local activeSlot = 1

local currentWeaponKey = inventorySlots[activeSlot]
local currentWeapon = WeaponRegistry.get(currentWeaponKey)
local clipAmmo = currentWeapon.Mag
local reserveAmmo = currentWeapon.Reserve

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
local isAdminMode = false -- God Mode is off by default; server only authorizes the experience owner/whitelist

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
    if toggleAdminEvent then
        toggleAdminEvent:FireServer(isAdminMode)
    end
end

local function setupCharacter(char)
    task.spawn(function()
        currentStamina = MAX_STAMINA
        isExhausted = false
        isSprinting = false
        isShiftDown = false
        syncAdminModeToServer()
        local hum = char:WaitForChild("Humanoid", 10)
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
local weaponSpecificParts = {} -- ชิ้นส่วนปืน/มีดสำหรับหมุนควง
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
    weaponSpecificParts = {}
    muzzleFlashParts = {}
    flashLight = nil
    muzzleSmokeEmitter = nil

    local isPistol = (currentWeapon.Type == "Pistol" or currentWeapon.Type == "Revolver")

    -- 1. แขนนักศึกษา มจพ.
    local arms, leftArms, rightArms = KMUTNBArms.build(viewmodel, isPistol)
    for p, cf in pairs(arms) do rigParts[p] = cf end
    for p, cf in pairs(leftArms) do leftArmParts[p] = cf end
    for p, cf in pairs(rightArms) do rightArmParts[p] = cf end

    -- 2. โมเดลปืน 3D
    local wParts, mParts, fLight, sEmitter = WeaponModelBuilder.build(viewmodel, currentWeapon, gunRoot)
    for p, cf in pairs(wParts) do
        rigParts[p] = cf
        weaponSpecificParts[p] = cf
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

-- Keep this list in sync with ADMIN_USER_IDS in WaveAndZombieManager.server.lua
-- when the experience is group-owned.
local CLIENT_ADMIN_USER_IDS = {}

local function canUseAdminMode()
    if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
        return true
    end
    return CLIENT_ADMIN_USER_IDS[player.UserId] == true
end

local function toggleAdminMode()
    if not canUseAdminMode() then
        isAdminMode = false
        syncAdminModeToServer()
        adminToggleBtn.Text = "ADMIN: LOCKED"
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

-- แบนเนอร์แจ้งเตือนเวฟซอมบี้ด้านบนจอ
local waveBanner = Instance.new("TextLabel")
waveBanner.Name = "WaveBanner"
waveBanner.Size = UDim2.new(0, 520, 0, 40)
waveBanner.Position = UDim2.new(0.5, -260, 0, 18)
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
        if weaponName ~= currentWeaponKey then return end
        if type(serverClip) == "number" then clipAmmo = math.max(0, math.floor(serverClip)) end
        if type(serverReserve) == "number" then reserveAmmo = math.max(0, math.floor(serverReserve)) end
        isReloading = serverReloading == true
        updateAmmoUI()
    end)
end

-- สลับไปยังช่องอาวุธ (Equip Slot: 1 = Primary, 2 = Secondary)
equipSlot = function(slotIndex, forceEquip)
    if slotIndex ~= 1 then return end -- one-weapon inventory: no secondary slot

    if isReloading then
        isReloading = false -- ยกเลิกการรีโหลดทันทีเมื่อสลับอาวุธ
        reloadSequence = reloadSequence + 1 -- invalidate the old local reload task
    end

    local wKey = inventorySlots[1]
    if not wKey then return end

    -- ข้ามเฉพาะกรณีที่กดซ้ำช่องเดิมและเป็นปืนกระบอกเดิมอยู่แล้ว (และไม่ได้ถูกสั่ง forceEquip จาก Buy Menu)
    if not forceEquip and activeSlot == slotIndex and currentWeaponKey == wKey and currentWeapon then
        return
    end

    activeSlot = slotIndex
    currentWeaponKey = wKey
    currentWeapon = WeaponRegistry.get(wKey)

    clipAmmo = currentWeapon.Mag or 25
    reserveAmmo = currentWeapon.Reserve or 100
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


-- Server-authoritative floor pickup: the server validates the prompt and sends one weapon key.
local pickupFolder = ReplicatedStorage:WaitForChild("WeaponPickupEvents", 10)
local pickupEvent = pickupFolder and pickupFolder:WaitForChild("WeaponGranted", 10)
if pickupEvent then
    pickupEvent.OnClientEvent:Connect(function(weaponKey)
        if type(weaponKey) ~= "string" or not WeaponRegistry.get(weaponKey) then return end
        inventorySlots[1] = weaponKey
        inventorySlots[2] = nil
        equipSlot(1, true)
        print("[WeaponPickup] Equipped single weapon: " .. weaponKey)
    end)
end

-- สร้างเมนูเลือกปืน VALORANT ARSENAL
local buyMenuObj = nil
local function onSelectWeapon(weaponKey)
    local wData = WeaponRegistry.get(weaponKey)
    if not wData then return end

    -- ทุกชนิดรวมปืนพกใช้ช่องเดียวกัน: การเลือกใหม่คือแทนที่กระบอกเดิม
    inventorySlots[1] = weaponKey
    inventorySlots[2] = nil
    equipSlot(1, true)

    buyMenuObj.Frame.Visible = false
    setCameraFrozen(false)
    isCursorFree = false
    opticsUI.Crosshair.Visible = true
end

buyMenuObj = ValorantBuyMenu.create(screenGui, WeaponRegistry.getAll(), onSelectWeapon)

local function toggleBuyMenu()
    -- Weapon acquisition is world-based now; keep the legacy catalogue disabled.
    buyMenuObj.Frame.Visible = false
    return

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

-- Modal Unlocker to free mouse from First-Person lock
local mapModalUnlocker = Instance.new("TextButton")
mapModalUnlocker.Name = "MapModalUnlocker"
mapModalUnlocker.Size = UDim2.new(0, 0, 0, 0)
mapModalUnlocker.BackgroundTransparency = 1
mapModalUnlocker.Text = ""
mapModalUnlocker.Modal = true
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
mapScreenBtn.Position = UDim2.new(0, 20, 0, 18)
mapScreenBtn.Size = UDim2.new(0, 150, 0, 36)
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
        desc = "ลานกว้างด้านหน้าตึก สะพานข้ามคลอง สวนปาล์ม และลานจอดรถ",
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
        -- วาร์ป CFrame ทันทีฝั่ง Client
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = item.cframe
            end
        end
        -- ซิงค์ยืนยันกับ Server
        local remotes = ReplicatedStorage:FindFirstChild("TeleportEvents")
        local req = remotes and remotes:FindFirstChild("RequestTeleport")
        if req then
            req:FireServer(item.key)
        end
    end)
end

local function isAnyModalOpen()
    if buyMenuObj and buyMenuObj.Frame and buyMenuObj.Frame.Visible then return true end
    if mapMenuFrame and mapMenuFrame.Visible then return true end
    local mapHud = playerGui:FindFirstChild("MapSelectorHUD")
    if mapHud then
        local win = mapHud:FindFirstChild("MapSelectorWindow")
        if win and win.Visible then return true end
    end
    return false
end

-- บังคับเมาส์ให้เป็นอิสระเมื่อเปิดเมนู ชนะระบบกล้องของ Roblox
RunService:BindToRenderStep("EnforceMouseBehavior", Enum.RenderPriority.Camera.Value + 1, function()
    if isAnyModalOpen() or isCursorFree then
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
    reloadSequence = reloadSequence + 1
    local thisReload = reloadSequence

    isReloading = true
    isAiming = false
    isInspecting = false
    opticsUI:SetAiming(false, currentWeapon)
    reloadTimer = 0
    updateAmmoUI()

    if weaponReloadEvent then
        weaponReloadEvent:FireServer(currentWeaponKey)
    end

    WeaponAudio.playClick(2.0)
    task.delay(0.9, function() if thisReload == reloadSequence then WeaponAudio.playClick(2.8) end end)
    task.delay(1.5, function() if thisReload == reloadSequence then WeaponAudio.playClick(1.6) end end)

    task.wait(reloadTimeTotal)
    if thisReload ~= reloadSequence then return end

    -- AmmoSync is the source of truth, but nudge the server once more
    -- in case the completion packet was dropped or delayed in transit.
    task.wait(0.3)
    if thisReload ~= reloadSequence then return end
    if weaponReloadEvent then
        weaponReloadEvent:FireServer(currentWeaponKey)
    end
end

----------------------------------------------------------------------
-- 6. ตัวเลขดาเมจลอย & โฟลเดอร์เอฟเฟกต์กระสุน (DAMAGE POPUP & EFFECTS)
----------------------------------------------------------------------
local clientEffectsFolder = Workspace:FindFirstChild("ClientBulletEffects") or Instance.new("Folder")
clientEffectsFolder.Name = "ClientBulletEffects"
clientEffectsFolder.Parent = Workspace

local function findZombieModelFromPart(part)
    local cur = part
    while cur and cur ~= Workspace do
        if cur:IsA("Model") and (cur:GetAttribute("IsZombie") or cur.Name:sub(1, 7) == "Zombie_") then
            return cur
        end
        cur = cur.Parent
    end
    return nil
end

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
    clipAmmo = clipAmmo - 1
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

    -- One request per trigger pull: the server performs its own raycasts and spends one shell/round.
    if weaponFireEvent then
        weaponFireEvent:FireServer(currentWeaponKey, rayOrigin, baseDir)
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
            local hitPart = hit.Instance
            local hitModel = findZombieModelFromPart(hitPart)
            if not hitModel then
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

    -- 🌟 สลับช่องอาวุธ 1, 2 (InputBegan Fallback)
    if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
        if equipSlot then equipSlot(1) end
        return
    elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.KeypadTwo or input.KeyCode == Enum.KeyCode.Q then
        return -- no secondary weapon slot
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

    -- 🌟 ปุ่ม [Y] หรือ [F] ยกดูปืน (Inspect Weapon)
    if input.KeyCode == Enum.KeyCode.Y or input.KeyCode == Enum.KeyCode.F then
        isInspecting = not isInspecting
        if isInspecting then
            WeaponAudio.playClick(2.4)
        end
        return
    end

    -- [B] เปิด/ปิด คลังแสง Valorant
    if input.KeyCode == Enum.KeyCode.B then
        toggleBuyMenu()
        return
    end

    -- [M] เปิด/ปิด เมนูเลือกแมพและโซน (Map Selector)
    if input.KeyCode == Enum.KeyCode.M then
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
    local finalRootCF = isSniperAiming and CFrame.new(0, -999, 0) or (camera.CFrame * currentOffset * motionCFrame)
    gunRoot.CFrame = finalRootCF

    -- ปรับตำแหน่งชิ้นส่วนแขนและปืน
    for part, relCF in pairs(rigParts) do
        if part and part.Parent then
            if leftArmParts[part] and isReloading then
                part.CFrame = finalRootCF * relCF * leftArmReloadOffset
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
