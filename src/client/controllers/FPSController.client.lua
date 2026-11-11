--[[
    FPSController.client.lua
    KMUTNB Building 40 - Zombie Defense // Master FPS Controller
    
    คุณสมบัติระบบ:
      - ระบบช่องอาวุธ [1] ปืนหลัก, [2] ปืนรอง
      - รองรับเลื่อนลูกกลิ้งเมาส์ (Scroll Wheel) สลับช่อง 1 -> 2
      - กดปุ่ม [Left Shift] วิ่งเร็ว (Sprint) พร้อมแถบพละกำลังจำกัด (Stamina Bar)
      - กดปุ่ม [Left Control / Right Control] สไลด์แบบ Neon (Valorant Slide) ยิงระหว่างสไลด์ได้
      - Dynamic FOV & Tactical Viewmodel Bobbing
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

local isPlayerDeadClient = false
local isPlayerDownedClient = false
local deathStartTime = 0
local deathOverlay = nil
local deathSubLabel = nil
local downedBanner = nil

local function isCharacterDead()
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return (not hum) or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead
end

local function isCharacterDowned()
    if isCharacterDead() then return false end
    if player:GetAttribute("IsDowned") == true then return true end
    local char = player.Character
    if not char then return false end
    if char:GetAttribute("IsDowned") == true then return true end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp ~= nil and hrp:FindFirstChild("RevivePrompt") ~= nil
end

local function isShowcaseOrbitActive()
    return player:GetAttribute("ShowcaseOrbitMode") == true
end

local function isShowcaseThirdPersonActive()
    return player:GetAttribute("ShowcaseThirdPersonMove") == true
end

local function isShowcaseCameraActive()
    return isShowcaseOrbitActive() or isShowcaseThirdPersonActive()
end

-- 🔒 บังคับมุมมองบุคคลที่ 1 (FPS Lock First Person) 100%
local function enforceFirstPerson()
    if isShowcaseCameraActive() then return end
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

player:GetAttributeChangedSignal("ShowcaseOrbitMode"):Connect(function()
    if not isShowcaseCameraActive() and not isCharacterDead() then
        enforceFirstPerson()
    end
end)

player:GetAttributeChangedSignal("ShowcaseThirdPersonMove"):Connect(function()
    if isShowcaseThirdPersonActive() and not isShowcaseOrbitActive() and not isCharacterDead() then
        pcall(function()
            player.CameraMode = Enum.CameraMode.Classic
            player.CameraMinZoomDistance = 8
            player.CameraMaxZoomDistance = 16
            if camera then
                camera.CameraType = Enum.CameraType.Custom
            end
        end)
    elseif not isShowcaseCameraActive() and not isCharacterDead() then
        enforceFirstPerson()
    end
end)

enforceFirstPerson()

player.CharacterAdded:Connect(function(char)
    isPlayerDeadClient = false
    isPlayerDownedClient = false
    if deathOverlay then deathOverlay.Visible = false end
    if downedBanner then downedBanner.Visible = false end
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
    -- 1. ReplicatedStorage.Weapons (Shared between Server & Client)
    if ReplicatedStorage:FindFirstChild("Weapons") then
        return ReplicatedStorage:FindFirstChild("Weapons")
    end
    -- 2. Sibling ใน PlayerScripts (Fallback)
    if script.Parent and script.Parent:FindFirstChild("Weapons") then
        return script.Parent:FindFirstChild("Weapons")
    end
    -- 3. ค้นหาใน PlayerScripts ของ LocalPlayer
    local pScripts = player:FindFirstChild("PlayerScripts") or player:WaitForChild("PlayerScripts", 3)
    if pScripts and pScripts:FindFirstChild("Weapons") then
        return pScripts:FindFirstChild("Weapons")
    end
    -- 4. รอจาก ReplicatedStorage เป็นหลัก
    local repFound = ReplicatedStorage:WaitForChild("Weapons", 5)
    if repFound then return repFound end
    -- 5. Fallback StarterPlayerScripts
    local sps = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
    if sps and sps:FindFirstChild("Weapons") then
        return sps:FindFirstChild("Weapons")
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
local animationsFolder = weaponsFolder:WaitForChild("animations", 10)
local WeaponPoseSolver = safeRequire(animationsFolder, "WeaponPoseSolver")

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

-- Survival & Horror events
local survivalEvents = ReplicatedStorage:WaitForChild("SurvivalEvents", 10)
local survivalFeedbackEvent = survivalEvents and survivalEvents:WaitForChild("SurvivalFeedback", 5)
local flashlightSyncEvent = survivalEvents and survivalEvents:WaitForChild("FlashlightSync", 5)
local horrorModeSyncEvent = survivalEvents and survivalEvents:WaitForChild("HorrorModeSync", 5)
local useSupplySlotEvent = survivalEvents and survivalEvents:WaitForChild("UseSupplySlot", 5)

----------------------------------------------------------------------
-- 1. ระบบจัดการ 3 ช่องอาวุธ (3-SLOT ARSENAL: PRIMARY, SECONDARY & UNARMED)
----------------------------------------------------------------------
local UNARMED_CONFIG = {
    Name = "UNARMED",
    Category = "HANDS",
    Type = "Unarmed",
    FiringType = "Melee",
    Mag = 0,
    Reserve = 0,
    FireRate = 0.65,
    ReloadTime = 0,
    HipOffset = CFrame.new(0, -0.35, -0.82),
    Recoil = { KickZ = -0.18, PitchX = 2.0, YawY = 1.5 },
}

local function getWeaponConfig(weaponKey)
    if weaponKey == "Unarmed" then
        return UNARMED_CONFIG
    end
    return WeaponRegistry.get(weaponKey)
end

local inventorySlots = {
    [1] = nil,        -- Primary weapon (scavenge in Building 40 / Floor 2+)
    [2] = nil,        -- Sidearm (scavenge in Floor 2 Storage / Security)
    [3] = "Unarmed",  -- Empty hands: default start + faster auto-run
}
local activeSlot = 3
local lastArmedSlot = 2

local currentWeaponKey = inventorySlots[activeSlot]
local currentWeapon = getWeaponConfig(currentWeaponKey) or UNARMED_CONFIG
local clipAmmo = currentWeapon.Mag or 0
local reserveAmmo = currentWeapon.Reserve or 0
local slotAmmoCache = {
    [1] = nil,
    [2] = nil,
    [3] = { key = "Unarmed", clip = 0, reserve = 0 },
}

local showWeaponNotice
local isInsideTestRangeClient
local canUseAdminMode
local updateHorrorModeUI
local toggleMapMenu
local useSupplySlot

local function isSidearmWeapon(weaponKey, wData)
    local cat = wData and wData.Category and wData.Category:upper() or ""
    if cat == "SIDEARMS" then return true end
    return weaponKey == "Classic" or weaponKey == "Shorty" or weaponKey == "Frenzy" or weaponKey == "Ghost" or weaponKey == "Sheriff"
end

local function slotIndexForKey(weaponKey)
    if weaponKey == "Unarmed" then return 3 end
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
local meleePunchUntil = 0

----------------------------------------------------------------------
-- 1.1 ระบบพละกำลัง (W วิ่ง Auto + Shift บูส +4 + มือเปล่าวิ่งไว + Admin)
----------------------------------------------------------------------
local AUTORUN_ARMED_SPEED = 20
local AUTORUN_UNARMED_SPEED = 24
local SHIFT_BOOST_BONUS = 4
local EXHAUSTED_ARMED_SPEED = 14
local EXHAUSTED_UNARMED_SPEED = 17

local WALK_SPEED_NORMAL = AUTORUN_UNARMED_SPEED
local SPRINT_SPEED = AUTORUN_UNARMED_SPEED + SHIFT_BOOST_BONUS
local EXHAUSTED_SPEED = EXHAUSTED_ARMED_SPEED

local WALK_SPEED_ADMIN = 34
local SPRINT_SPEED_ADMIN = 56
local isAdminMode = player:GetAttribute("IsAdminGodMode") == true

local MAX_STAMINA = 100
local currentStamina = 100
local STAMINA_DRAIN_PER_SEC = 22
local STAMINA_REGEN_PER_SEC = 20
local STAMINA_REGEN_DELAY = 1.0
local EXHAUSTION_RECOVERY_POINT = 25

local isShiftDown = false
local isSprinting = false
local isExhausted = false
local lastSprintTime = 0
local currentSprintCFrame = CFrame.identity

-- ⚡ ระบบสไลด์สไตล์ Neon (Valorant High Gear Slide // กด L-Ctrl หรือ R-Ctrl)
local SLIDE_DURATION = 0.46
local SLIDE_PEAK_SPEED = 52
local SLIDE_END_SPEED = 20
local SLIDE_PEAK_SPEED_ADMIN = 78
local SLIDE_END_SPEED_ADMIN = 32
local SLIDE_COOLDOWN = 1.65
local SLIDE_COOLDOWN_ADMIN = 0.75
local SLIDE_STAMINA_COST = 20
local SLIDE_CAMERA_DROP = -1.75

local isSliding = false
local slideStartTime = 0
local lastSlideEndTime = -10
local slideDirection = Vector3.new(0, 0, -1)
local slideLateralSign = -1
local slideLinearVelocity = nil
local slideTrail = nil
local currentSlideCamOffsetY = 0
local currentSlideViewmodelCF = CFrame.identity

local function syncAdminModeToServer()
    if toggleAdminEvent and player:GetAttribute("CanUseAdminMode") == true then
        toggleAdminEvent:FireServer(isAdminMode)
    end
end

local flashlightEnabled = true
local flashlightLight
local activeHorrorPreset = "Blackout" -- "Blackout" | "Unstable"
local lightingMode = "Horror" -- "Horror" | "Day" (toggled anytime with [N])
local buildingLightsCache = {}
local emergencyLightsList = {}
local flickerLightsList = {}
local lightsCached = false
local trackedLights = {}
local flickerLoopGeneration = 0

local function isExcludedLight(inst)
    if inst.Name == "SurvivalFlashlight" then return true end
    local p = inst.Parent
    while p and p ~= Workspace do
        if p.Name == "INFECTED_TestRange" or p.Name == "ClientShowcaseStudioBooth" or p.Name == "Building40_SurvivalLoot" or p.Name == "CampaignStations" then
            return true
        end
        p = p.Parent
    end
    return false
end

local function registerWorkspaceLight(inst, applyNow)
    if not (inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight")) then return end
    if trackedLights[inst] or isExcludedLight(inst) then return end
    trackedLights[inst] = true

    if inst:GetAttribute("HorrorEmergencyLight") == true then
        table.insert(emergencyLightsList, inst)
        if applyNow then
            inst.Enabled = (lightingMode == "Horror")
        end
    else
        local saved = {
            Enabled = inst.Enabled,
            Brightness = inst.Brightness,
        }
        buildingLightsCache[inst] = saved
        table.insert(flickerLightsList, inst)
        if applyNow then
            if lightingMode == "Horror" and activeHorrorPreset == "Blackout" then
                inst.Enabled = false
            elseif lightingMode == "Horror" and activeHorrorPreset == "Unstable" then
                inst.Enabled = saved.Enabled
                inst.Brightness = saved.Brightness * 0.42
            end
        end
    end
end

local function refreshBuildingLightCache()
    buildingLightsCache = {}
    emergencyLightsList = {}
    flickerLightsList = {}
    trackedLights = {}
    for _, inst in ipairs(Workspace:GetDescendants()) do
        registerWorkspaceLight(inst, false)
    end
    lightsCached = true
end

Workspace.DescendantAdded:Connect(function(inst)
    if inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
        task.defer(function()
            if inst.Parent then
                registerWorkspaceLight(inst, lightsCached)
            end
        end)
    end
end)

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
        flashlightLight.Range = 58
        flashlightLight.Brightness = 2.6
        flashlightLight.Shadows = true
        flashlightLight.Color = Color3.fromRGB(220, 232, 255)
        flashlightLight.Parent = attachment
    end
    flashlightLight.Enabled = flashlightEnabled
end

local function toggleFlashlight()
    flashlightEnabled = not flashlightEnabled
    if flashlightLight then flashlightLight.Enabled = flashlightEnabled end
    if flashlightSyncEvent then
        flashlightSyncEvent:FireServer(flashlightEnabled)
    end
    WeaponAudio.playClick(flashlightEnabled and 2.4 or 1.5)
end

local function applyLightingMode(mode)
    if mode == "Day" then
        lightingMode = "Day"
    elseif mode == "Blackout" or mode == "Unstable" then
        activeHorrorPreset = mode
        lightingMode = "Horror"
    else
        lightingMode = (mode == "Night" or mode == "Horror") and "Horror" or "Day"
    end

    if not lightsCached then
        refreshBuildingLightCache()
    end

    local stale = Lighting:FindFirstChild("SurvivalColorCorrection")
    if stale then stale:Destroy() end

    local correction = Lighting:FindFirstChild("Building40ColorCorrection")
    if not correction then
        correction = Instance.new("ColorCorrectionEffect")
        correction.Name = "Building40ColorCorrection"
        correction.Parent = Lighting
    end

    flickerLoopGeneration = flickerLoopGeneration + 1
    local myGen = flickerLoopGeneration

    if lightingMode == "Day" then
        Lighting.ClockTime = 14
        Lighting.Brightness = 2.2
        Lighting.ExposureCompensation = 0
        Lighting.Ambient = Color3.fromRGB(135, 138, 145)
        Lighting.OutdoorAmbient = Color3.fromRGB(155, 160, 168)
        Lighting.FogColor = Color3.fromRGB(190, 200, 215)
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        correction.Saturation = 0.05
        correction.Contrast = 0.04
        correction.Brightness = 0
        correction.TintColor = Color3.fromRGB(255, 255, 255)

        for light, saved in pairs(buildingLightsCache) do
            if light and light.Parent then
                light.Enabled = saved.Enabled
                light.Brightness = saved.Brightness
            end
        end
        for _, emerg in ipairs(emergencyLightsList) do
            if emerg and emerg.Parent then
                emerg.Enabled = false
            end
        end
    elseif activeHorrorPreset == "Blackout" then
        Lighting.ClockTime = 0.0
        Lighting.Brightness = 0.24
        Lighting.ExposureCompensation = -0.15
        Lighting.Ambient = Color3.fromRGB(9, 11, 16)
        Lighting.OutdoorAmbient = Color3.fromRGB(4, 6, 10)
        Lighting.FogColor = Color3.fromRGB(7, 9, 14)
        Lighting.FogStart = 4
        Lighting.FogEnd = 92
        correction.Saturation = -0.38
        correction.Contrast = 0.24
        correction.Brightness = -0.06
        correction.TintColor = Color3.fromRGB(165, 185, 220)

        for light in pairs(buildingLightsCache) do
            if light and light.Parent then
                light.Enabled = false
            end
        end
        for _, emerg in ipairs(emergencyLightsList) do
            if emerg and emerg.Parent then
                emerg.Enabled = true
            end
        end
    else -- "Unstable"
        Lighting.ClockTime = 0.25
        Lighting.Brightness = 0.52
        Lighting.ExposureCompensation = -0.05
        Lighting.Ambient = Color3.fromRGB(14, 18, 26)
        Lighting.OutdoorAmbient = Color3.fromRGB(8, 12, 20)
        Lighting.FogColor = Color3.fromRGB(12, 17, 25)
        Lighting.FogStart = 8
        Lighting.FogEnd = 165
        correction.Saturation = -0.26
        correction.Contrast = 0.20
        correction.Brightness = -0.03
        correction.TintColor = Color3.fromRGB(175, 210, 215)

        for light, saved in pairs(buildingLightsCache) do
            if light and light.Parent then
                light.Enabled = saved.Enabled
                light.Brightness = saved.Brightness * 0.42
            end
        end
        for _, emerg in ipairs(emergencyLightsList) do
            if emerg and emerg.Parent then
                emerg.Enabled = true
            end
        end

        task.spawn(function()
            while myGen == flickerLoopGeneration and lightingMode == "Horror" and activeHorrorPreset == "Unstable" do
                task.wait(math.random(12, 32) * 0.1)
                if myGen ~= flickerLoopGeneration or lightingMode ~= "Horror" or activeHorrorPreset ~= "Unstable" then break end

                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root and #flickerLightsList > 0 and (not isInsideTestRangeClient or not isInsideTestRangeClient()) then
                    local candidates = {}
                    for _, lt in ipairs(flickerLightsList) do
                        local lp = lt.Parent and lt.Parent:IsA("BasePart") and lt.Parent.Position
                        local saved = buildingLightsCache[lt]
                        if lp and saved and saved.Enabled and (lp - root.Position).Magnitude <= 145 then
                            table.insert(candidates, lt)
                        end
                    end
                    if #candidates > 0 then
                        local pick = candidates[math.random(1, #candidates)]
                        local saved = buildingLightsCache[pick]
                        local pPos = pick.Parent and pick.Parent:IsA("BasePart") and pick.Parent.Position
                        if saved and pPos then
                            WeaponAudio.playHorrorCue("Buzz", pPos)
                            for step = 1, math.random(3, 5) do
                                if myGen ~= flickerLoopGeneration or not pick.Parent then break end
                                pick.Enabled = (step % 2 == 0)
                                pick.Brightness = saved.Brightness * (math.random(15, 70) * 0.01)
                                task.wait(0.06 + math.random() * 0.07)
                            end
                            if pick.Parent and myGen == flickerLoopGeneration and lightingMode == "Horror" and activeHorrorPreset == "Unstable" then
                                pick.Enabled = false
                                task.delay(math.random(7, 16) * 0.1, function()
                                    if pick.Parent and myGen == flickerLoopGeneration and lightingMode == "Horror" and activeHorrorPreset == "Unstable" then
                                        pick.Enabled = saved.Enabled
                                        pick.Brightness = saved.Brightness * 0.42
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end

    if horrorModeSyncEvent then
        horrorModeSyncEvent:FireServer(lightingMode == "Horror")
    end
    if updateHorrorModeUI then
        updateHorrorModeUI()
    end
end

local function toggleLightingMode()
    if lightingMode == "Day" then
        applyLightingMode(activeHorrorPreset)
    else
        applyLightingMode("Day")
    end
    if showWeaponNotice then
        if lightingMode == "Day" then
            showWeaponNotice("☀️ โหมดดูตึกสว่าง [N] // กด [N] อีกรอบเพื่อกลับโหมดหลอน")
        elseif activeHorrorPreset == "Blackout" then
            showWeaponNotice("🌙 โหมดหลอน 1: DEEP BLACKOUT (ไฟดับทั้งตึก) | [L] ไฟฉาย | [H] สลับแบบ 2")
        else
            showWeaponNotice("⚡ โหมดหลอน 2: UNSTABLE POWER (ไฟตกติดๆ ดับๆ) | [L] ไฟฉาย | [H] สลับแบบ 1")
        end
    end
    WeaponAudio.playClick(lightingMode == "Horror" and 1.4 or 2.2)
end

local function cycleHorrorPreset()
    local nextPreset = (activeHorrorPreset == "Blackout") and "Unstable" or "Blackout"
    applyLightingMode(nextPreset)
    if showWeaponNotice then
        if nextPreset == "Blackout" then
            showWeaponNotice("🌙 โหมดหลอน 1: DEEP BLACKOUT (มืดสนิท + ไฟฉุกเฉินสีแดง) | กด [N] ดูตึกสว่าง")
        else
            showWeaponNotice("⚡ โหมดหลอน 2: EERIE UNSTABLE POWER (ไฟตึกกระพริบติดๆ ดับๆ) | กด [N] ดูตึกสว่าง")
        end
    end
    WeaponAudio.playClick(1.8)
end

player:GetAttributeChangedSignal("IsAdminGodMode"):Connect(function()
    isAdminMode = player:GetAttribute("IsAdminGodMode") == true
end)

local function setupCharacter(char)
    task.spawn(function()
        applyLightingMode(lightingMode)
        isPlayerDeadClient = false
        isPlayerDownedClient = false
        deathStartTime = 0
        if deathOverlay then deathOverlay.Visible = false end
        if downedBanner then downedBanner.Visible = false end
        currentStamina = MAX_STAMINA
        isExhausted = false
        isSprinting = false
        isShiftDown = false
        isSliding = false
        isMouseDown = false
        isAiming = false
        isInspecting = false
        currentSlideCamOffsetY = 0
        currentSlideViewmodelCF = CFrame.identity
        if slideLinearVelocity then
            slideLinearVelocity:Destroy()
            slideLinearVelocity = nil
        end
        syncAdminModeToServer()
        local hum = char:WaitForChild("Humanoid", 10)
        setFlashlightForCharacter(char)
        local unarmed = (currentWeaponKey == "Unarmed")
        local baseAuto = unarmed and AUTORUN_UNARMED_SPEED or AUTORUN_ARMED_SPEED
        if hum then
            hum.WalkSpeed = isAdminMode and WALK_SPEED_ADMIN or baseAuto
            hum.CameraOffset = Vector3.zero
        end
        if flashlightSyncEvent then
            flashlightSyncEvent:FireServer(flashlightEnabled)
        end
        if horrorModeSyncEvent then
            horrorModeSyncEvent:FireServer(lightingMode == "Horror")
        end
        enforceFirstPerson()
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

    -- 1. แขนนักศึกษา มจพ. (รองรับทั้งมือเปล่า Unarmed และอาวุธปืนทุกรุ่น)
    local armBuildArg = (currentWeaponKey == "Unarmed") and "Unarmed" or currentWeapon
    local arms, leftArms, rightArms = KMUTNBArms.build(viewmodel, armBuildArg)
    for p, cf in pairs(arms) do
        rigParts[p] = cf
        rigPartBaseTransparency[p] = p.Transparency
    end
    for p, cf in pairs(leftArms) do leftArmParts[p] = cf end
    for p, cf in pairs(rightArms) do rightArmParts[p] = cf end

    if currentWeaponKey == "Unarmed" then
        return
    end

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

-- Helper: สร้างกรอบ Dark Tactical Horror Glass Panel แบบรวมศูนย์
local function createHudPanel(name, size, pos, anchor, strokeColor, strokeThick, cornerRadius, bgAlpha)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = pos
    if anchor then frame.AnchorPoint = anchor end
    frame.BackgroundColor3 = Color3.fromRGB(11, 15, 22)
    frame.BackgroundTransparency = bgAlpha or 0.16
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, cornerRadius or 10)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = strokeColor or Color3.fromRGB(58, 74, 96)
    stroke.Thickness = strokeThick or 1.4
    stroke.Transparency = 0.18
    return frame, stroke
end

-- Helper: แถบ Meter แบบรวมศูนย์ (Health / Stamina / Hunger) ภายใน Survival Dock
local function createMeterRow(parent, yOffset, titleText, titleColor, fillColor, trackHeight)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.66, -12, 0, 15)
    titleLabel.Position = UDim2.new(0, 12, 0, yOffset)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 10
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = titleColor
    titleLabel.Text = titleText
    titleLabel.Parent = parent

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.34, -12, 0, 15)
    valueLabel.Position = UDim2.new(0.66, 0, 0, yOffset)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 11
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextColor3 = titleColor
    valueLabel.Text = "100%"
    valueLabel.Parent = parent

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, trackHeight or 7)
    track.Position = UDim2.new(0, 12, 0, yOffset + 17)
    track.BackgroundColor3 = Color3.fromRGB(24, 30, 42)
    track.BorderSizePixel = 0
    track.Parent = parent
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = fillColor
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    return titleLabel, valueLabel, fill
end

-- 🔔 Non-colliding Toast แจ้งเตือนเก็บเสบียง / อาวุธ / สถานะมุมขวาล่าง (ไม่ทับ WaveBanner)
local noticeToast, noticeStroke = createHudPanel(
    "SurvivalNoticeToast",
    UDim2.new(0, 330, 0, 42),
    UDim2.new(1, -18, 1, -122),
    Vector2.new(1, 1),
    Color3.fromRGB(75, 205, 255),
    1.3,
    9,
    0.12
)
noticeToast.ZIndex = 24
noticeToast.Visible = false

local noticeLabel = Instance.new("TextLabel")
noticeLabel.Size = UDim2.new(1, -20, 1, -6)
noticeLabel.Position = UDim2.new(0, 10, 0, 3)
noticeLabel.BackgroundTransparency = 1
noticeLabel.Font = Enum.Font.GothamBold
noticeLabel.TextSize = 12
noticeLabel.TextWrapped = true
noticeLabel.TextXAlignment = Enum.TextXAlignment.Center
noticeLabel.TextColor3 = Color3.fromRGB(235, 246, 255)
noticeLabel.Text = ""
noticeLabel.ZIndex = 25
noticeLabel.Parent = noticeToast

local noticeSeq = 0
showWeaponNotice = function(message)
    if type(message) ~= "string" or message == "" then return end
    noticeSeq += 1
    local seq = noticeSeq
    noticeLabel.Text = message
    noticeToast.Visible = true
    task.delay(3.4, function()
        if seq == noticeSeq and noticeToast and noticeToast.Parent then
            noticeToast.Visible = false
        end
    end)
end

-- 🎯 Minimal Bottom-Right Weapon Readout Card
local gunCard, gunStroke = createHudPanel(
    "WeaponReadoutCard",
    UDim2.new(0, 260, 0, 96),
    UDim2.new(1, -18, 1, -18),
    Vector2.new(1, 1),
    Color3.fromRGB(95, 245, 175),
    1.5,
    10,
    0.16
)

local gunNameLabel = Instance.new("TextLabel")
gunNameLabel.Size = UDim2.new(1, -24, 0, 24)
gunNameLabel.Position = UDim2.new(0, 12, 0, 8)
gunNameLabel.BackgroundTransparency = 1
gunNameLabel.TextColor3 = Color3.fromRGB(95, 245, 175)
gunNameLabel.Font = Enum.Font.GothamBold
gunNameLabel.TextSize = 19
gunNameLabel.TextXAlignment = Enum.TextXAlignment.Left
gunNameLabel.Text = currentWeapon.Name
gunNameLabel.Parent = gunCard

local gunTypeLabel = Instance.new("TextLabel")
gunTypeLabel.Size = UDim2.new(1, -24, 0, 15)
gunTypeLabel.Position = UDim2.new(0, 12, 0, 32)
gunTypeLabel.BackgroundTransparency = 1
gunTypeLabel.TextColor3 = Color3.fromRGB(165, 182, 204)
gunTypeLabel.Font = Enum.Font.Gotham
gunTypeLabel.TextSize = 11
gunTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
gunTypeLabel.Text = string.format("%s // %s", (currentWeapon.Category or "HANDS"):upper(), (currentWeapon.FiringType or "MELEE"):upper())
gunTypeLabel.Parent = gunCard

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Size = UDim2.new(1, -24, 0, 38)
ammoLabel.Position = UDim2.new(0, 12, 0, 50)
ammoLabel.BackgroundTransparency = 1
ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextSize = 27
ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
ammoLabel.Text = (currentWeaponKey == "Unarmed") and "SHOVE // +SPEED" or string.format("%d / %d", clipAmmo, reserveAmmo)
ammoLabel.Parent = gunCard

-- 🧭 Top-Right Tactical Utility Capsule (ปลดความทับซ้อนจาก MissionHUD มุมซ้ายบน)
local utilityBar = Instance.new("Frame")
utilityBar.Name = "TopRightUtilityBar"
utilityBar.AnchorPoint = Vector2.new(1, 0)
utilityBar.Position = UDim2.new(1, -190, 0, 12)
utilityBar.AutomaticSize = Enum.AutomaticSize.X
utilityBar.Size = UDim2.new(0, 0, 0, 34)
utilityBar.BackgroundColor3 = Color3.fromRGB(11, 15, 22)
utilityBar.BackgroundTransparency = 0.16
utilityBar.BorderSizePixel = 0
utilityBar.ZIndex = 26
utilityBar.Parent = screenGui
Instance.new("UICorner", utilityBar).CornerRadius = UDim.new(0, 9)
local utilityStroke = Instance.new("UIStroke", utilityBar)
utilityStroke.Color = Color3.fromRGB(175, 45, 55)
utilityStroke.Thickness = 1.2
utilityStroke.Transparency = 0.25

local utilityPad = Instance.new("UIPadding", utilityBar)
utilityPad.PaddingLeft = UDim.new(0, 6)
utilityPad.PaddingRight = UDim.new(0, 6)
utilityPad.PaddingTop = UDim.new(0, 4)
utilityPad.PaddingBottom = UDim.new(0, 4)

local utilityList = Instance.new("UIListLayout", utilityBar)
utilityList.FillDirection = Enum.FillDirection.Horizontal
utilityList.SortOrder = Enum.SortOrder.LayoutOrder
utilityList.VerticalAlignment = Enum.VerticalAlignment.Center
utilityList.Padding = UDim.new(0, 5)

local function createUtilButton(name, order, bgColor, textColor, text, strokeColor)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.LayoutOrder = order
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.Size = UDim2.new(0, 0, 0, 26)
    btn.BackgroundColor3 = bgColor
    btn.BackgroundTransparency = 0.1
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = textColor
    btn.Text = text
    btn.ZIndex = 27
    btn.Parent = utilityBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 9)
    pad.PaddingRight = UDim.new(0, 9)
    local st = Instance.new("UIStroke", btn)
    st.Color = strokeColor or Color3.fromRGB(60, 78, 102)
    st.Thickness = 1
    st.Transparency = 0.3
    return btn, st
end

local mapTopBtn = createUtilButton("MapTopButton", 1, Color3.fromRGB(16, 26, 38), Color3.fromRGB(95, 225, 255), "🗺 [M] แมพ", Color3.fromRGB(0, 175, 220))
mapTopBtn.MouseButton1Click:Connect(function()
    if toggleMapMenu then toggleMapMenu() end
end)

local dayToggleBtn = createUtilButton("DayToggleButton", 2, Color3.fromRGB(24, 30, 42), Color3.fromRGB(245, 220, 135), "☀ [N] ดูตึกสว่าง", Color3.fromRGB(95, 110, 135))
dayToggleBtn.MouseButton1Click:Connect(function()
    toggleLightingMode()
end)

local horrorModeBtn = createUtilButton("HorrorPresetButton", 3, Color3.fromRGB(38, 15, 20), Color3.fromRGB(255, 145, 155), "🌙 [H] หลอน 1", Color3.fromRGB(165, 50, 65))
horrorModeBtn.MouseButton1Click:Connect(function()
    cycleHorrorPreset()
end)

local adminToggleBtn, adminBtnStroke = createUtilButton("AdminModeToggleButton", 4, Color3.fromRGB(45, 36, 12), Color3.fromRGB(255, 225, 85), "👑 [G] ADMIN: เปิด", Color3.fromRGB(255, 200, 45))
adminToggleBtn.Visible = player:GetAttribute("CanUseAdminMode") == true

-- 🎒 Minecraft-Style Center-Bottom 6-Slot Action & Supply Hotbar
local SUPPLY_SLOTS = {
    [4] = { icon = "🍖", label = "เสบียง", attr = "FoodPacks", max = 4, accent = Color3.fromRGB(245, 175, 65) },
    [5] = { icon = "✚",  label = "ชุดยา",  attr = "MedkitPacks", max = 3, accent = Color3.fromRGB(255, 95, 105) },
    [6] = { icon = "🔋", label = "ถ่าน",   attr = "BatteryPacks", max = 4, accent = Color3.fromRGB(95, 215, 255) },
}

local hotbarFrame = Instance.new("Frame")
hotbarFrame.Name = "MinecraftHotbarFrame"
hotbarFrame.AnchorPoint = Vector2.new(0.5, 1)
hotbarFrame.Position = UDim2.new(0.5, 0, 1, -18)
hotbarFrame.Size = UDim2.new(0, 415, 0, 86)
hotbarFrame.BackgroundTransparency = 1
hotbarFrame.Parent = screenGui

local hotbarHintLabel = Instance.new("TextLabel")
hotbarHintLabel.Size = UDim2.new(1, 0, 0, 15)
hotbarHintLabel.Position = UDim2.new(0, 0, 0, 0)
hotbarHintLabel.BackgroundTransparency = 1
hotbarHintLabel.Font = Enum.Font.GothamBold
hotbarHintLabel.TextSize = 10
hotbarHintLabel.TextColor3 = Color3.fromRGB(190, 206, 226)
hotbarHintLabel.TextStrokeColor3 = Color3.fromRGB(6, 8, 12)
hotbarHintLabel.TextStrokeTransparency = 0.25
hotbarHintLabel.Text = "1-3 อาวุธ / มือเปล่า (+SPEED)   •   4-6 กดใช้เสบียง / ยา / ถ่านพกพา"
hotbarHintLabel.Parent = hotbarFrame

local hotbarDock = Instance.new("Frame")
hotbarDock.Name = "HotbarDock"
hotbarDock.Size = UDim2.new(1, 0, 0, 68)
hotbarDock.Position = UDim2.new(0, 0, 0, 18)
hotbarDock.BackgroundColor3 = Color3.fromRGB(10, 13, 19)
hotbarDock.BackgroundTransparency = 0.14
hotbarDock.BorderSizePixel = 0
hotbarDock.Parent = hotbarFrame
Instance.new("UICorner", hotbarDock).CornerRadius = UDim.new(0, 10)
local hotbarStroke = Instance.new("UIStroke", hotbarDock)
hotbarStroke.Color = Color3.fromRGB(62, 78, 102)
hotbarStroke.Thickness = 1.4
hotbarStroke.Transparency = 0.18

local hotbarDivider = Instance.new("Frame")
hotbarDivider.Size = UDim2.new(0, 1, 0, 44)
hotbarDivider.Position = UDim2.new(0, 207, 0.5, -22)
hotbarDivider.BackgroundColor3 = Color3.fromRGB(85, 102, 128)
hotbarDivider.BackgroundTransparency = 0.4
hotbarDivider.BorderSizePixel = 0
hotbarDivider.Parent = hotbarDock

local slotButtons = {}
local pulseSupplySlot

for s = 1, 6 do
    local xPos = (s <= 3) and (8 + (s - 1) * 66) or (215 + (s - 4) * 66)
    local sBox = Instance.new("TextButton")
    sBox.Name = "HotbarSlot_" .. s
    sBox.Size = UDim2.new(0, 60, 0, 58)
    sBox.Position = UDim2.new(0, xPos, 0, 5)
    sBox.BackgroundColor3 = Color3.fromRGB(18, 24, 34)
    sBox.BackgroundTransparency = 0.18
    sBox.Text = ""
    sBox.AutoButtonColor = true
    sBox.Parent = hotbarDock
    Instance.new("UICorner", sBox).CornerRadius = UDim.new(0, 7)

    local sStroke = Instance.new("UIStroke", sBox)
    sStroke.Color = Color3.fromRGB(60, 75, 95)
    sStroke.Thickness = 1.3

    local sNum = Instance.new("TextLabel")
    sNum.Size = UDim2.new(0, 16, 0, 13)
    sNum.Position = UDim2.new(0, 4, 0, 3)
    sNum.BackgroundTransparency = 1
    sNum.Font = Enum.Font.GothamBold
    sNum.TextSize = 10
    sNum.TextXAlignment = Enum.TextXAlignment.Left
    sNum.TextColor3 = Color3.fromRGB(175, 190, 212)
    sNum.Text = tostring(s)
    sNum.Parent = sBox

    local sBadge = Instance.new("TextLabel")
    sBadge.Size = UDim2.new(0, 36, 0, 13)
    sBadge.Position = UDim2.new(1, -40, 0, 3)
    sBadge.BackgroundTransparency = 1
    sBadge.Font = Enum.Font.GothamBold
    sBadge.TextSize = 9
    sBadge.TextXAlignment = Enum.TextXAlignment.Right
    sBadge.TextColor3 = Color3.fromRGB(160, 180, 205)
    sBadge.Text = ""
    sBadge.Parent = sBox

    local sIcon = Instance.new("TextLabel")
    sIcon.Size = UDim2.new(1, 0, 0, 22)
    sIcon.Position = UDim2.new(0, 0, 0, 16)
    sIcon.BackgroundTransparency = 1
    sIcon.Font = Enum.Font.GothamBold
    sIcon.TextSize = 16
    sIcon.TextColor3 = Color3.fromRGB(235, 242, 255)
    sIcon.Text = (s == 3) and "👊" or (SUPPLY_SLOTS[s] and SUPPLY_SLOTS[s].icon or "🔫")
    sIcon.Parent = sBox

    local sName = Instance.new("TextLabel")
    sName.Size = UDim2.new(1, -6, 0, 14)
    sName.Position = UDim2.new(0, 3, 1, -17)
    sName.BackgroundTransparency = 1
    sName.Font = Enum.Font.GothamBold
    sName.TextSize = 9
    sName.TextTruncate = Enum.TextTruncate.AtEnd
    sName.TextColor3 = Color3.fromRGB(235, 242, 255)
    sName.Text = SUPPLY_SLOTS[s] and SUPPLY_SLOTS[s].label or ((s == 3) and "มือเปล่า" or "EMPTY")
    sName.Parent = sBox

    sBox.MouseButton1Click:Connect(function()
        if s <= 3 then
            if equipSlot then equipSlot(s) end
        elseif useSupplySlot then
            useSupplySlot(s)
        end
    end)

    slotButtons[s] = {
        Box = sBox,
        Stroke = sStroke,
        NumLabel = sNum,
        BadgeLabel = sBadge,
        IconLabel = sIcon,
        NameLabel = sName,
    }
end

-- ❤️⚡🍖 Unified Bottom-Left Survival & Energy Dock
local survivalDock, hpStroke = createHudPanel(
    "SurvivalEnergyDock",
    UDim2.new(0, 296, 0, 174),
    UDim2.new(0, 18, 1, -18),
    Vector2.new(0, 1),
    Color3.fromRGB(45, 210, 115),
    1.5,
    10,
    0.16
)

local pointsLabel = Instance.new("TextLabel")
pointsLabel.Size = UDim2.new(0.62, -10, 0, 20)
pointsLabel.Position = UDim2.new(0, 12, 0, 7)
pointsLabel.BackgroundTransparency = 1
pointsLabel.Font = Enum.Font.GothamBold
pointsLabel.TextSize = 11
pointsLabel.TextXAlignment = Enum.TextXAlignment.Left
pointsLabel.TextColor3 = Color3.fromRGB(255, 218, 92)
pointsLabel.Text = "💰 500 แต้ม  •  ☠ 0 Kills"
pointsLabel.Parent = survivalDock

local speedBadge = Instance.new("Frame")
speedBadge.Size = UDim2.new(0.36, -6, 0, 18)
speedBadge.Position = UDim2.new(0.64, -4, 0, 8)
speedBadge.BackgroundColor3 = Color3.fromRGB(18, 32, 42)
speedBadge.BorderSizePixel = 0
speedBadge.Parent = survivalDock
Instance.new("UICorner", speedBadge).CornerRadius = UDim.new(0, 5)
local speedStroke = Instance.new("UIStroke", speedBadge)
speedStroke.Color = Color3.fromRGB(55, 215, 195)
speedStroke.Thickness = 1
speedStroke.Transparency = 0.35

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -8, 1, 0)
speedLabel.Position = UDim2.new(0, 4, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 10
speedLabel.TextColor3 = Color3.fromRGB(130, 248, 225)
speedLabel.Text = "💨 24 STD/S"
speedLabel.Parent = speedBadge

local dockDivider = Instance.new("Frame")
dockDivider.Size = UDim2.new(1, -24, 0, 1)
dockDivider.Position = UDim2.new(0, 12, 0, 30)
dockDivider.BackgroundColor3 = Color3.fromRGB(70, 88, 112)
dockDivider.BackgroundTransparency = 0.55
dockDivider.BorderSizePixel = 0
dockDivider.Parent = survivalDock

local hpTitle, hpValueLabel, hpFill = createMeterRow(
    survivalDock, 35, "✚ HEALTH // พลังชีวิต", Color3.fromRGB(45, 235, 125), Color3.fromRGB(45, 225, 115), 8
)
hpValueLabel.Text = "100 / 100 HP"

local staminaTitle, staminaPercent, barFill = createMeterRow(
    survivalDock, 71, "⚡ STAMINA [SHIFT +4]", Color3.fromRGB(0, 240, 215), Color3.fromRGB(0, 240, 215), 7
)

local hungerTitle, hungerPercentLabel, hungerFill = createMeterRow(
    survivalDock, 105, "🍖 HUNGER // ความอิ่ม", Color3.fromRGB(245, 195, 105), Color3.fromRGB(240, 175, 60), 6
)

local flashlightBtn = Instance.new("TextButton")
flashlightBtn.Size = UDim2.new(0.49, -14, 0, 24)
flashlightBtn.Position = UDim2.new(0, 12, 1, -32)
flashlightBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 44)
flashlightBtn.BorderSizePixel = 0
flashlightBtn.Font = Enum.Font.GothamBold
flashlightBtn.TextSize = 10
flashlightBtn.TextColor3 = Color3.fromRGB(205, 232, 255)
flashlightBtn.Text = "🔦 [L] ON: 100%"
flashlightBtn.Parent = survivalDock
Instance.new("UICorner", flashlightBtn).CornerRadius = UDim.new(0, 5)
local flashBtnStroke = Instance.new("UIStroke", flashlightBtn)
flashBtnStroke.Color = Color3.fromRGB(65, 125, 175)
flashBtnStroke.Thickness = 1
flashBtnStroke.Transparency = 0.35
flashlightBtn.MouseButton1Click:Connect(function()
    toggleFlashlight()
end)

local slideCard = Instance.new("Frame")
slideCard.Name = "NeonSlidePill"
slideCard.Size = UDim2.new(0.49, -14, 0, 24)
slideCard.Position = UDim2.new(0.51, 2, 1, -32)
slideCard.BackgroundColor3 = Color3.fromRGB(14, 24, 36)
slideCard.BorderSizePixel = 0
slideCard.Parent = survivalDock
Instance.new("UICorner", slideCard).CornerRadius = UDim.new(0, 5)
local slideStroke = Instance.new("UIStroke", slideCard)
slideStroke.Color = Color3.fromRGB(40, 195, 255)
slideStroke.Thickness = 1
slideStroke.Transparency = 0.25

local slideCDTrack = Instance.new("Frame")
slideCDTrack.Size = UDim2.new(1, -8, 0, 3)
slideCDTrack.Position = UDim2.new(0, 4, 1, -5)
slideCDTrack.BackgroundColor3 = Color3.fromRGB(22, 34, 48)
slideCDTrack.BorderSizePixel = 0
slideCDTrack.Parent = slideCard
Instance.new("UICorner", slideCDTrack).CornerRadius = UDim.new(1, 0)

local slideCDFill = Instance.new("Frame")
slideCDFill.Size = UDim2.new(1, 0, 1, 0)
slideCDFill.BackgroundColor3 = Color3.fromRGB(55, 225, 255)
slideCDFill.BorderSizePixel = 0
slideCDFill.Parent = slideCDTrack
Instance.new("UICorner", slideCDFill).CornerRadius = UDim.new(1, 0)

local slideLabel = Instance.new("TextLabel")
slideLabel.Size = UDim2.new(1, -8, 0, 15)
slideLabel.Position = UDim2.new(0, 4, 0, 2)
slideLabel.BackgroundTransparency = 1
slideLabel.Font = Enum.Font.GothamBold
slideLabel.TextSize = 9
slideLabel.TextColor3 = Color3.fromRGB(95, 230, 255)
slideLabel.Text = "⚡ SLIDE [CTRL] READY"
slideLabel.Parent = slideCard

local function updateStaminaUI()
    local isUnarmed = (currentWeaponKey == "Unarmed")
    local baseAuto = isUnarmed and AUTORUN_UNARMED_SPEED or AUTORUN_ARMED_SPEED
    local boostRem = math.max(0, (player:GetAttribute("StaminaBoostUntil") or 0) - Workspace:GetServerTimeNow())

    if isAdminMode then
        adminToggleBtn.Text = "👑 [G] ADMIN: เปิด"
        adminToggleBtn.BackgroundColor3 = Color3.fromRGB(52, 40, 12)
        adminToggleBtn.TextColor3 = Color3.fromRGB(255, 225, 85)
        adminBtnStroke.Color = Color3.fromRGB(255, 205, 50)

        barFill.Size = UDim2.new(1, 0, 1, 0)
        staminaTitle.Text = isSprinting and "👑 ADMIN SUPER SPRINT!" or "👑 ADMIN STAMINA // ∞"
        staminaTitle.TextColor3 = Color3.fromRGB(255, 225, 85)
        staminaPercent.Text = "∞ UNLIMITED"
        staminaPercent.TextColor3 = Color3.fromRGB(255, 230, 95)
        barFill.BackgroundColor3 = Color3.fromRGB(255, 210, 55)

        speedLabel.Text = string.format("👑 %d STD/S", isSprinting and SPRINT_SPEED_ADMIN or WALK_SPEED_ADMIN)
        speedLabel.TextColor3 = Color3.fromRGB(255, 228, 96)
        speedBadge.BackgroundColor3 = Color3.fromRGB(48, 38, 14)
        speedStroke.Color = Color3.fromRGB(255, 205, 50)
        return
    else
        adminToggleBtn.Text = "⚙️ [G] ADMIN: ปิด"
        adminToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 26, 36)
        adminToggleBtn.TextColor3 = Color3.fromRGB(165, 180, 200)
        adminBtnStroke.Color = Color3.fromRGB(65, 80, 100)
    end

    if boostRem > 0 then
        barFill.Size = UDim2.new(1, 0, 1, 0)
        staminaTitle.Text = isSprinting and "⚡ ENERGY SPRINT // วิ่งบูสฟรี!" or "⚡ ENERGY DRINK ACTIVE"
        staminaTitle.TextColor3 = Color3.fromRGB(80, 255, 225)
        staminaPercent.Text = string.format("FREE %ds", math.ceil(boostRem))
        staminaPercent.TextColor3 = Color3.fromRGB(110, 255, 230)
        barFill.BackgroundColor3 = Color3.fromRGB(65, 255, 220)

        local curSpd = isSprinting and (baseAuto + SHIFT_BOOST_BONUS) or baseAuto
        speedLabel.Text = string.format("⚡ %d FREE %ds", curSpd, math.ceil(boostRem))
        speedLabel.TextColor3 = Color3.fromRGB(95, 255, 225)
        speedBadge.BackgroundColor3 = Color3.fromRGB(14, 44, 42)
        speedStroke.Color = Color3.fromRGB(65, 255, 220)
        return
    end

    local ratio = math.clamp(currentStamina / MAX_STAMINA, 0, 1)
    barFill.Size = UDim2.new(ratio, 0, 1, 0)
    local pct = math.floor(ratio * 100)

    if isExhausted then
        staminaTitle.Text = "⚠ EXHAUSTED // หมดแรง"
        staminaTitle.TextColor3 = Color3.fromRGB(255, 75, 75)
        staminaPercent.Text = string.format("%d%%", pct)
        staminaPercent.TextColor3 = Color3.fromRGB(255, 75, 75)
        barFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)

        local exhSpeed = isUnarmed and EXHAUSTED_UNARMED_SPEED or EXHAUSTED_ARMED_SPEED
        speedLabel.Text = string.format("⚠ %d STD/S", exhSpeed)
        speedLabel.TextColor3 = Color3.fromRGB(255, 110, 110)
        speedBadge.BackgroundColor3 = Color3.fromRGB(40, 18, 22)
        speedStroke.Color = Color3.fromRGB(235, 70, 75)
    elseif ratio <= 0.35 then
        staminaTitle.Text = "⚡ LOW STAMINA [SHIFT +4]"
        staminaTitle.TextColor3 = Color3.fromRGB(255, 195, 45)
        staminaPercent.Text = string.format("%d%%", pct)
        staminaPercent.TextColor3 = Color3.fromRGB(255, 195, 45)
        barFill.BackgroundColor3 = Color3.fromRGB(255, 195, 45)

        local curSpd = isSprinting and (baseAuto + SHIFT_BOOST_BONUS) or baseAuto
        speedLabel.Text = string.format(isSprinting and "⚡ %d BOOST" or "🏃 %d STD/S", curSpd)
        speedLabel.TextColor3 = Color3.fromRGB(255, 210, 95)
        speedBadge.BackgroundColor3 = Color3.fromRGB(36, 30, 14)
        speedStroke.Color = Color3.fromRGB(235, 180, 45)
    else
        staminaTitle.Text = isSprinting and "⚡ SPRINTING [SHIFT +4]" or "⚡ STAMINA [SHIFT +4]"
        staminaTitle.TextColor3 = isSprinting and Color3.fromRGB(0, 255, 230) or Color3.fromRGB(165, 200, 228)
        staminaPercent.Text = string.format("%d%%", pct)
        staminaPercent.TextColor3 = Color3.fromRGB(0, 240, 215)
        barFill.BackgroundColor3 = Color3.fromRGB(0, 240, 215)

        local curSpd = isSprinting and (baseAuto + SHIFT_BOOST_BONUS) or baseAuto
        speedLabel.Text = string.format(isSprinting and "⚡ %d BOOST" or (isUnarmed and "💨 %d FAST" or "🏃 %d STD/S"), curSpd)
        speedLabel.TextColor3 = isSprinting and Color3.fromRGB(95, 255, 230) or Color3.fromRGB(145, 230, 215)
        speedBadge.BackgroundColor3 = Color3.fromRGB(18, 32, 42)
        speedStroke.Color = isSprinting and Color3.fromRGB(0, 240, 215) or Color3.fromRGB(55, 195, 180)
    end
end

local function updateSlideUI(now)
    local cd = isAdminMode and SLIDE_COOLDOWN_ADMIN or SLIDE_COOLDOWN
    if isSliding then
        local rem = math.clamp(1 - (now - slideStartTime) / SLIDE_DURATION, 0, 1)
        slideCDFill.Size = UDim2.new(rem, 0, 1, 0)
        slideCDFill.BackgroundColor3 = Color3.fromRGB(145, 252, 255)
        slideStroke.Color = Color3.fromRGB(115, 245, 255)
        slideLabel.Text = "⚡ SLIDING!"
        slideLabel.TextColor3 = Color3.fromRGB(165, 252, 255)
    else
        local elapsedSince = now - lastSlideEndTime
        if elapsedSince < cd then
            local ratio = math.clamp(elapsedSince / cd, 0, 1)
            slideCDFill.Size = UDim2.new(ratio, 0, 1, 0)
            slideCDFill.BackgroundColor3 = Color3.fromRGB(50, 150, 210)
            slideStroke.Color = Color3.fromRGB(55, 105, 145)
            slideLabel.Text = string.format("⚡ SLIDE %.1fs", math.max(0.1, cd - elapsedSince))
            slideLabel.TextColor3 = Color3.fromRGB(130, 175, 205)
        else
            local boostRem = math.max(0, (player:GetAttribute("StaminaBoostUntil") or 0) - Workspace:GetServerTimeNow())
            local hasStam = isAdminMode or boostRem > 0 or (not isExhausted and currentStamina >= SLIDE_STAMINA_COST)
            slideCDFill.Size = UDim2.new(1, 0, 1, 0)
            slideCDFill.BackgroundColor3 = hasStam and Color3.fromRGB(45, 225, 255) or Color3.fromRGB(120, 75, 75)
            slideStroke.Color = hasStam and Color3.fromRGB(40, 195, 255) or Color3.fromRGB(110, 60, 60)
            slideLabel.Text = hasStam and "⚡ SLIDE [CTRL] RDY" or "⚡ SLIDE LOW STAM"
            slideLabel.TextColor3 = hasStam and Color3.fromRGB(95, 230, 255) or Color3.fromRGB(220, 115, 115)
        end
    end
end

-- Overlay กระพริบแดงเมื่อโดนตี + Death/Downed overlays
local damageFlash = Instance.new("Frame")
damageFlash.Name = "DamageFlashOverlay"
damageFlash.Size = UDim2.new(1, 0, 1, 0)
damageFlash.BackgroundColor3 = Color3.fromRGB(220, 20, 30)
damageFlash.BackgroundTransparency = 1
damageFlash.BorderSizePixel = 0
damageFlash.ZIndex = 0
damageFlash.Parent = screenGui

deathOverlay = Instance.new("Frame")
deathOverlay.Name = "DeathOverlay"
deathOverlay.Size = UDim2.new(1, 0, 1, 0)
deathOverlay.BackgroundColor3 = Color3.fromRGB(28, 6, 8)
deathOverlay.BackgroundTransparency = 0.58
deathOverlay.BorderSizePixel = 0
deathOverlay.ZIndex = 35
deathOverlay.Visible = false
deathOverlay.Parent = screenGui

local deathCard = Instance.new("Frame")
deathCard.Size = UDim2.new(0, 380, 0, 96)
deathCard.Position = UDim2.new(0.5, -190, 0.24, 0)
deathCard.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
deathCard.BackgroundTransparency = 0.16
deathCard.BorderSizePixel = 0
deathCard.ZIndex = 36
deathCard.Parent = deathOverlay
Instance.new("UICorner", deathCard).CornerRadius = UDim.new(0, 10)
local deathStroke = Instance.new("UIStroke", deathCard)
deathStroke.Color = Color3.fromRGB(235, 65, 75)
deathStroke.Thickness = 2

local deathTitleLabel = Instance.new("TextLabel")
deathTitleLabel.Size = UDim2.new(1, -20, 0, 38)
deathTitleLabel.Position = UDim2.new(0, 10, 0, 14)
deathTitleLabel.BackgroundTransparency = 1
deathTitleLabel.Font = Enum.Font.GothamBlack
deathTitleLabel.TextSize = 24
deathTitleLabel.TextColor3 = Color3.fromRGB(255, 85, 95)
deathTitleLabel.Text = "💀 YOU DIED // เสียชีวิต"
deathTitleLabel.ZIndex = 37
deathTitleLabel.Parent = deathCard

deathSubLabel = Instance.new("TextLabel")
deathSubLabel.Size = UDim2.new(1, -20, 0, 24)
deathSubLabel.Position = UDim2.new(0, 10, 0, 56)
deathSubLabel.BackgroundTransparency = 1
deathSubLabel.Font = Enum.Font.GothamBold
deathSubLabel.TextSize = 14
deathSubLabel.TextColor3 = Color3.fromRGB(220, 226, 236)
deathSubLabel.Text = "กำลังเตรียมเกิดใหม่..."
deathSubLabel.ZIndex = 37
deathSubLabel.Parent = deathCard

downedBanner = Instance.new("TextLabel")
downedBanner.Name = "DownedStatusBanner"
downedBanner.Size = UDim2.new(0, 440, 0, 38)
downedBanner.Position = UDim2.new(0.5, -220, 1, -152)
downedBanner.BackgroundColor3 = Color3.fromRGB(24, 14, 16)
downedBanner.BackgroundTransparency = 0.14
downedBanner.TextColor3 = Color3.fromRGB(255, 195, 75)
downedBanner.Font = Enum.Font.GothamBold
downedBanner.TextSize = 14
downedBanner.Text = "🚨 DOWNED // คลานรอเพื่อนกด [E] ชุบ"
downedBanner.ZIndex = 32
downedBanner.Visible = false
downedBanner.Parent = screenGui
Instance.new("UICorner", downedBanner).CornerRadius = UDim.new(0, 8)
local downedStroke = Instance.new("UIStroke", downedBanner)
downedStroke.Color = Color3.fromRGB(255, 110, 65)
downedStroke.Thickness = 1.6

local function updateHealthUI(hum)
    local deadNow = isPlayerDeadClient or (hum and hum.Health <= 0)
    if deadNow then
        hpTitle.Text = "💀 YOU DIED // เสียชีวิต"
        hpTitle.TextColor3 = Color3.fromRGB(255, 95, 105)
        hpFill.Size = UDim2.new(0, 0, 1, 0)
        local maxHP = (hum and hum.MaxHealth > 0) and math.floor(hum.MaxHealth) or 100
        hpValueLabel.Text = string.format("0 / %d HP", maxHP)
        local deadRed = Color3.fromRGB(235, 55, 65)
        hpFill.BackgroundColor3 = deadRed
        hpValueLabel.TextColor3 = deadRed
        hpStroke.Color = deadRed
        return
    end

    if isPlayerDownedClient then
        local char = player.Character
        local bleedEnd = (char and char:GetAttribute("BleedoutEndTime")) or player:GetAttribute("BleedoutEndTime")
        local rem = bleedEnd and math.max(0, math.ceil(bleedEnd - Workspace:GetServerTimeNow())) or 30
        local bleedRatio = math.clamp(rem / 30, 0, 1)
        local warnColor = Color3.fromRGB(255, 120, 55)
        hpTitle.Text = "🚨 DOWNED // รอเพื่อนกด [E] ชุบ"
        hpTitle.TextColor3 = Color3.fromRGB(255, 200, 95)
        hpFill.Size = UDim2.new(bleedRatio, 0, 1, 0)
        hpValueLabel.Text = string.format("BLEEDOUT %ds", rem)
        hpFill.BackgroundColor3 = warnColor
        hpValueLabel.TextColor3 = warnColor
        hpStroke.Color = warnColor
        return
    end

    if isAdminMode then
        hpTitle.Text = "👑 ADMIN GOD MODE // อมตะ"
        hpTitle.TextColor3 = Color3.fromRGB(255, 225, 85)
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpValueLabel.Text = "∞ / ∞ GOD"
        local gold = Color3.fromRGB(255, 210, 55)
        hpFill.BackgroundColor3 = gold
        hpValueLabel.TextColor3 = gold
        hpStroke.Color = gold
        return
    end

    hpTitle.Text = "✚ HEALTH // พลังชีวิต"
    hpTitle.TextColor3 = Color3.fromRGB(165, 200, 228)
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

local function refreshPointsDisplay(overridePoints, overrideKills)
    local pts = overridePoints or player:GetAttribute("Points") or 500
    local kills = overrideKills or player:GetAttribute("Kills") or 0
    pointsLabel.Text = string.format("💰 %d แต้ม  •  ☠ %d Kills", pts, kills)
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

-- Atmospheric 4-edge UIGradient horror tunnel vignette (zero external decal dependency)
local horrorVignetteEdges = {}
local vignetteEdgeSpecs = {
    { Name = "VigTop",    Size = UDim2.new(1, 0, 0.22, 0), Pos = UDim2.new(0, 0, 0, 0),    Rot = 90 },
    { Name = "VigBottom", Size = UDim2.new(1, 0, 0.22, 0), Pos = UDim2.new(0, 0, 0.78, 0), Rot = 270 },
    { Name = "VigLeft",   Size = UDim2.new(0.18, 0, 1, 0), Pos = UDim2.new(0, 0, 0, 0),    Rot = 0 },
    { Name = "VigRight",  Size = UDim2.new(0.18, 0, 1, 0), Pos = UDim2.new(0.82, 0, 0, 0), Rot = 180 },
}
for _, spec in ipairs(vignetteEdgeSpecs) do
    local edge = Instance.new("Frame")
    edge.Name = spec.Name
    edge.Size = spec.Size
    edge.Position = spec.Pos
    edge.BackgroundColor3 = Color3.fromRGB(4, 4, 8)
    edge.BackgroundTransparency = 1
    edge.BorderSizePixel = 0
    edge.Active = false
    edge.ZIndex = 1
    edge.Parent = screenGui

    local grad = Instance.new("UIGradient")
    grad.Rotation = spec.Rot
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(0.55, 0.65),
        NumberSequenceKeypoint.new(1, 1),
    })
    grad.Parent = edge
    table.insert(horrorVignetteEdges, edge)
end

updateHorrorModeUI = function()
    if lightingMode == "Day" then
        dayToggleBtn.BackgroundColor3 = Color3.fromRGB(65, 58, 22)
        dayToggleBtn.TextColor3 = Color3.fromRGB(255, 240, 150)
        dayToggleBtn.Text = "☀ [N] สว่าง (ON)"
        utilityStroke.Color = Color3.fromRGB(215, 185, 80)
    else
        dayToggleBtn.BackgroundColor3 = Color3.fromRGB(24, 30, 42)
        dayToggleBtn.TextColor3 = Color3.fromRGB(245, 220, 135)
        dayToggleBtn.Text = "☀ [N] ดูตึกสว่าง"
        utilityStroke.Color = (activeHorrorPreset == "Blackout")
            and Color3.fromRGB(190, 45, 55)
            or Color3.fromRGB(70, 175, 185)
    end

    if activeHorrorPreset == "Blackout" then
        horrorModeBtn.BackgroundColor3 = Color3.fromRGB(38, 15, 20)
        horrorModeBtn.TextColor3 = Color3.fromRGB(255, 140, 150)
        horrorModeBtn.Text = "🌙 [H] หลอน 1: ไฟดับ"
    else
        horrorModeBtn.BackgroundColor3 = Color3.fromRGB(16, 34, 42)
        horrorModeBtn.TextColor3 = Color3.fromRGB(140, 235, 230)
        horrorModeBtn.Text = "⚡ [H] หลอน 2: ไฟกระพริบ"
    end
end

local function updateSurvivalHUD(hungerVal, batVal)
    local hunger = math.clamp(hungerVal or player:GetAttribute("Hunger") or 100, 0, 100)
    local bat = math.clamp(batVal or player:GetAttribute("FlashlightBattery") or 100, 0, 100)
    local hRatio = hunger / 100
    hungerFill.Size = UDim2.new(hRatio, 0, 1, 0)
    hungerPercentLabel.Text = string.format("%d%%", math.floor(hunger + 0.5))

    if hunger <= 0 then
        hungerTitle.Text = "⚠ STARVING! // กด [4] กินเสบียง!"
        hungerTitle.TextColor3 = Color3.fromRGB(255, 75, 75)
        hungerPercentLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
        hungerFill.BackgroundColor3 = Color3.fromRGB(235, 55, 55)
    elseif hunger <= 25 then
        hungerTitle.Text = "🍖 HUNGRY // หิวมาก [4]"
        hungerTitle.TextColor3 = Color3.fromRGB(255, 145, 70)
        hungerPercentLabel.TextColor3 = Color3.fromRGB(255, 160, 90)
        hungerFill.BackgroundColor3 = Color3.fromRGB(255, 130, 50)
    else
        hungerTitle.Text = "🍖 HUNGER // ความอิ่ม"
        hungerTitle.TextColor3 = Color3.fromRGB(245, 195, 105)
        hungerPercentLabel.TextColor3 = Color3.fromRGB(255, 225, 160)
        hungerFill.BackgroundColor3 = Color3.fromRGB(240, 175, 60)
    end

    if bat <= 0 and not isAdminMode then
        flashlightBtn.Text = "🔦 [L] BAT 0% [กด 6]"
        flashlightBtn.TextColor3 = Color3.fromRGB(255, 95, 95)
        flashlightBtn.BackgroundColor3 = Color3.fromRGB(40, 18, 22)
        flashBtnStroke.Color = Color3.fromRGB(230, 75, 80)
    else
        flashlightBtn.Text = string.format("🔦 [L] %s: %d%%", flashlightEnabled and "ON" or "OFF", math.floor(bat + 0.5))
        flashlightBtn.TextColor3 = flashlightEnabled and Color3.fromRGB(205, 232, 255) or Color3.fromRGB(135, 145, 165)
        flashlightBtn.BackgroundColor3 = flashlightEnabled and Color3.fromRGB(22, 34, 48) or Color3.fromRGB(18, 22, 30)
        flashBtnStroke.Color = flashlightEnabled and Color3.fromRGB(70, 155, 225) or Color3.fromRGB(58, 72, 92)
    end
end

if survivalFeedbackEvent then
    survivalFeedbackEvent.OnClientEvent:Connect(function(kind, message, staminaBonus, isDrink)
        if kind == "EatFood" then
            WeaponAudio.playEatOrDrink(isDrink == true)
            if type(staminaBonus) == "number" and staminaBonus > 0 then
                currentStamina = math.min(MAX_STAMINA, currentStamina + staminaBonus)
                if currentStamina >= EXHAUSTION_RECOVERY_POINT then
                    isExhausted = false
                end
            end
            if type(message) == "string" and showWeaponNotice then
                showWeaponNotice(message)
            end
        elseif type(message) == "string" and showWeaponNotice then
            WeaponAudio.playClick(kind == "WeaponFound" and 2.5 or 2.0)
            showWeaponNotice(message)
        end
    end)
end

-- แบนเนอร์แจ้งเตือนเวฟซอมบี้ด้านบนจอ
local waveBanner = Instance.new("TextLabel")
waveBanner.Name = "WaveBanner"
waveBanner.Size = UDim2.new(0, 520, 0, 38)
waveBanner.Position = UDim2.new(0.5, -260, 0, 56)
waveBanner.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
waveBanner.BackgroundTransparency = 0.22
waveBanner.TextColor3 = Color3.fromRGB(255, 215, 60)
waveBanner.Font = Enum.Font.GothamBold
waveBanner.TextSize = 15
waveBanner.Text = "🧟 WAVE 1 // เตรียมรับมือฝูงซอมบี้!"
waveBanner.Visible = false
waveBanner.Parent = screenGui
Instance.new("UICorner", waveBanner).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", waveBanner).Color = Color3.fromRGB(255, 90, 90)

if playerDamageEvent then
    playerDamageEvent.OnClientEvent:Connect(function(dmg, newHP, maxHP)
        if isCharacterDowned() then return end
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
    for s = 1, 3 do
        local tile = slotButtons[s]
        local isAct = (s == activeSlot)
        if s == 3 then
            tile.Box.BackgroundColor3 = isAct and Color3.fromRGB(28, 128, 92) or Color3.fromRGB(18, 26, 30)
            tile.Stroke.Color = isAct and Color3.fromRGB(95, 245, 175) or Color3.fromRGB(52, 95, 78)
            tile.Stroke.Thickness = isAct and 2.1 or 1.2
            tile.NumLabel.TextColor3 = isAct and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 225, 190)
            tile.BadgeLabel.Text = "+SPD"
            tile.BadgeLabel.TextColor3 = Color3.fromRGB(115, 250, 185)
            tile.IconLabel.Text = "👊"
            tile.NameLabel.Text = "มือเปล่า"
        else
            local w = inventorySlots[s] and WeaponRegistry.get(inventorySlots[s]) or nil
            local cached = slotAmmoCache[s]
            local magShown = (isAct and clipAmmo) or (cached and cached.clip) or (w and w.Mag) or 0
            tile.Box.BackgroundColor3 = isAct and Color3.fromRGB(178, 42, 56) or (w and Color3.fromRGB(22, 28, 38) or Color3.fromRGB(15, 18, 25))
            tile.Stroke.Color = isAct and Color3.fromRGB(255, 130, 145) or (w and Color3.fromRGB(72, 90, 118) or Color3.fromRGB(45, 55, 70))
            tile.Stroke.Thickness = isAct and 2.1 or 1.2
            tile.NumLabel.TextColor3 = isAct and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(175, 190, 212)
            tile.BadgeLabel.Text = w and string.format("%d", magShown) or "--"
            tile.BadgeLabel.TextColor3 = w and Color3.fromRGB(220, 232, 248) or Color3.fromRGB(110, 122, 142)
            tile.IconLabel.Text = w and (s == 1 and "🔫" or "⌖") or "·"
            tile.IconLabel.TextTransparency = w and 0 or 0.55
            tile.NameLabel.Text = w and w.Name or "EMPTY"
            tile.NameLabel.TextColor3 = w and Color3.fromRGB(245, 248, 255) or Color3.fromRGB(125, 136, 155)
        end
    end

    for s = 4, 6 do
        local spec = SUPPLY_SLOTS[s]
        local tile = slotButtons[s]
        local count = player:GetAttribute(spec.attr) or 0
        local hasItem = count > 0
        tile.Box.BackgroundColor3 = hasItem and Color3.fromRGB(24, 30, 42) or Color3.fromRGB(15, 18, 25)
        tile.Stroke.Color = hasItem and spec.accent or Color3.fromRGB(46, 56, 70)
        tile.Stroke.Thickness = hasItem and 1.6 or 1.1
        tile.NumLabel.TextColor3 = hasItem and Color3.fromRGB(240, 245, 255) or Color3.fromRGB(130, 140, 156)
        tile.BadgeLabel.Text = string.format("x%d/%d", count, spec.max)
        tile.BadgeLabel.TextColor3 = hasItem and spec.accent or Color3.fromRGB(118, 128, 146)
        tile.IconLabel.TextTransparency = hasItem and 0 or 0.6
        tile.NameLabel.Text = spec.label
        tile.NameLabel.TextColor3 = hasItem and Color3.fromRGB(242, 246, 252) or Color3.fromRGB(120, 132, 150)
    end
end

pulseSupplySlot = function(slotIdx)
    local tile = slotButtons[slotIdx]
    if not tile then return end
    tile.Box.BackgroundColor3 = Color3.fromRGB(60, 82, 108)
    task.delay(0.14, function()
        updateSlotUI()
    end)
end

useSupplySlot = function(slotIdx)
    if slotIdx ~= 4 and slotIdx ~= 5 and slotIdx ~= 6 then return end
    if isCharacterDead() or isCharacterDowned() then return end
    pulseSupplySlot(slotIdx)
    WeaponAudio.playClick(2.2)
    if useSupplySlotEvent then
        useSupplySlotEvent:FireServer(slotIdx)
    end
end

for _, attrName in ipairs({ "FoodPacks", "MedkitPacks", "BatteryPacks" }) do
    player:GetAttributeChangedSignal(attrName):Connect(updateSlotUI)
end
player:GetAttributeChangedSignal("StaminaBoostUntil"):Connect(updateStaminaUI)

local function updateAmmoUI()
    if currentWeaponKey == "Unarmed" then
        ammoLabel.Text = "SHOVE // +SPEED"
        ammoLabel.TextColor3 = Color3.fromRGB(95, 245, 175)
        gunNameLabel.TextColor3 = Color3.fromRGB(95, 245, 175)
        gunStroke.Color = Color3.fromRGB(95, 245, 175)
    elseif isReloading then
        ammoLabel.Text = "RELOADING..."
        ammoLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        gunNameLabel.TextColor3 = Color3.fromRGB(255, 85, 98)
        gunStroke.Color = Color3.fromRGB(255, 200, 50)
    else
        ammoLabel.Text = string.format("%d / %d", clipAmmo, reserveAmmo)
        ammoLabel.TextColor3 = (clipAmmo <= math.floor((currentWeapon.Mag or 1) * 0.25)) and Color3.fromRGB(255, 65, 70) or Color3.fromRGB(255, 255, 255)
        gunNameLabel.TextColor3 = Color3.fromRGB(255, 85, 98)
        gunStroke.Color = Color3.fromRGB(255, 75, 90)
    end
    updateSlotUI()
end

if weaponAmmoSyncEvent then
    weaponAmmoSyncEvent.OnClientEvent:Connect(function(weaponName, serverClip, serverReserve, serverReloading)
        if type(weaponName) ~= "string" or type(serverClip) ~= "number" or type(serverReserve) ~= "number" then return end
        local slotIdx = slotIndexForKey(weaponName)
        if inventorySlots[slotIdx] == weaponName then
            slotAmmoCache[slotIdx] = { key = weaponName, clip = serverClip, reserve = serverReserve }
            updateSlotUI()
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

-- สลับไปยังช่องอาวุธ (Equip Slot: 1 = Primary, 2 = Secondary, 3 = Unarmed)
equipSlot = function(slotIndex, forceEquip)
    if slotIndex < 1 or slotIndex > 3 then return end

    if isReloading then
        isReloading = false -- ยกเลิกการรีโหลดทันทีเมื่อสลับอาวุธ
        reloadSequence = reloadSequence + 1 -- invalidate the old local reload task
    end

    local wKey = inventorySlots[slotIndex]
    if not wKey then
        if slotIndex <= 2 and showWeaponNotice then
            showWeaponNotice(string.format("ช่อง [%d] ยังว่าง — รีบขึ้นชั้น 2 โรงอาหารหาของ & อาวุธ!", slotIndex))
        end
        return
    end

    -- ข้ามเฉพาะกรณีที่กดซ้ำช่องเดิมและเป็นอาวุธเดิมอยู่แล้ว (และไม่ได้ถูกสั่ง forceEquip)
    if not forceEquip and activeSlot == slotIndex and currentWeaponKey == wKey and currentWeapon then
        return
    end

    activeSlot = slotIndex
    if slotIndex == 1 or slotIndex == 2 then
        lastArmedSlot = slotIndex
    end
    currentWeaponKey = wKey
    currentWeapon = getWeaponConfig(wKey) or UNARMED_CONFIG
    if equipWeaponEvent then
        equipWeaponEvent:FireServer(wKey)
    end

    if wKey == "Unarmed" then
        clipAmmo = 0
        reserveAmmo = 0
        slotAmmoCache[3] = { key = "Unarmed", clip = 0, reserve = 0 }
    else
        local cached = slotAmmoCache[slotIndex]
        if cached and cached.key == wKey then
            clipAmmo = cached.clip
            reserveAmmo = cached.reserve
        else
            clipAmmo = currentWeapon.Mag or 25
            reserveAmmo = currentWeapon.Reserve or 100
            slotAmmoCache[slotIndex] = { key = wKey, clip = clipAmmo, reserve = reserveAmmo }
        end
    end
    isAiming = false
    isReloading = false
    isInspecting = false

    WeaponAudio.playClick(2.0)

    gunNameLabel.Text = currentWeapon.Name or "UNARMED"
    gunTypeLabel.Text = string.format("%s // %s", (currentWeapon.Category or "HANDS"):upper(), (currentWeapon.FiringType or "MELEE"):upper())
    updateSlotUI()
    updateAmmoUI()
    rebuildViewmodel()
    opticsUI:SetAiming(false, currentWeapon)
end

local function applyEquippedWeapon(weaponKey)
    if weaponKey == "Unarmed" then
        equipSlot(3, true)
        return
    end
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

toggleMapMenu = function(forceState)
    local newState = if forceState ~= nil then forceState else not mapMenuFrame.Visible
    if newState and buyMenuObj and buyMenuObj.Frame and buyMenuObj.Frame.Visible then
        buyMenuObj.Frame.Visible = false
    end
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

local function stopNeonSlide(preserveMomentum)
    if not isSliding then return end
    isSliding = false
    lastSlideEndTime = os.clock()

    if slideLinearVelocity then
        slideLinearVelocity:Destroy()
        slideLinearVelocity = nil
    end
    if slideTrail then
        slideTrail.Enabled = false
    end

    if not preserveMomentum then
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local v = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(v.X * 0.45, v.Y, v.Z * 0.45)
        end
    end
end

local function startNeonSlide()
    if isSliding or isAnyModalOpen() then
        return false
    end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 or hrp:FindFirstChild("RevivePrompt") then
        return false
    end

    if hum.FloorMaterial == Enum.Material.Air and math.abs(hrp.AssemblyLinearVelocity.Y) > 10 then
        return false
    end

    local now = os.clock()
    local cd = isAdminMode and SLIDE_COOLDOWN_ADMIN or SLIDE_COOLDOWN
    if (now - lastSlideEndTime) < cd then
        return false
    end
    local hasEnergyBoost = (player:GetAttribute("StaminaBoostUntil") or 0) > Workspace:GetServerTimeNow()
    if not isAdminMode and not hasEnergyBoost and (isExhausted or currentStamina < SLIDE_STAMINA_COST) then
        WeaponAudio.playClick(1.2)
        return false
    end

    -- Omni-directional Neon Slide: follow WASD MoveDirection, or camera forward if standing still
    local moveDir = hum.MoveDirection
    local flatMove = Vector3.new(moveDir.X, 0, moveDir.Z)
    if flatMove.Magnitude > 0.08 then
        slideDirection = flatMove.Unit
    else
        local camLook = camera and camera.CFrame.LookVector or hrp.CFrame.LookVector
        local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
        slideDirection = (flatLook.Magnitude > 0.01) and flatLook.Unit or Vector3.new(0, 0, -1)
    end

    local camRight = camera and camera.CFrame.RightVector or hrp.CFrame.RightVector
    local flatRight = Vector3.new(camRight.X, 0, camRight.Z)
    local latDot = (flatRight.Magnitude > 0.01) and flatRight.Unit:Dot(slideDirection) or 0
    slideLateralSign = (latDot > 0.25) and -1 or ((latDot < -0.25) and 1 or -1)

    if not isAdminMode and not hasEnergyBoost then
        currentStamina = math.max(0, currentStamina - SLIDE_STAMINA_COST)
        lastSprintTime = now
    end

    -- PerAxis LinearVelocity on X/Z keeps Y gravity 100% untouched & respects wall collision
    local slideAttach = hrp:FindFirstChild("NeonSlideAttachment")
    if not slideAttach then
        slideAttach = Instance.new("Attachment")
        slideAttach.Name = "NeonSlideAttachment"
        slideAttach.Parent = hrp
    end

    local staleVel = hrp:FindFirstChild("NeonSlideVelocity")
    if staleVel then staleVel:Destroy() end

    local peakSpeed = isAdminMode and SLIDE_PEAK_SPEED_ADMIN or SLIDE_PEAK_SPEED
    local lv = Instance.new("LinearVelocity")
    lv.Name = "NeonSlideVelocity"
    lv.Attachment0 = slideAttach
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    lv.MaxAxesForce = Vector3.new(85000, 0, 85000)
    lv.VectorVelocity = Vector3.new(slideDirection.X * peakSpeed, 0, slideDirection.Z * peakSpeed)
    lv.Parent = hrp
    slideLinearVelocity = lv

    if not slideTrail or not slideTrail.Parent or slideTrail.Parent ~= hrp then
        local tAtt0 = hrp:FindFirstChild("NeonTrailTop") or Instance.new("Attachment")
        tAtt0.Name = "NeonTrailTop"
        tAtt0.Position = Vector3.new(0, -1.5, 0)
        tAtt0.Parent = hrp

        local tAtt1 = hrp:FindFirstChild("NeonTrailBottom") or Instance.new("Attachment")
        tAtt1.Name = "NeonTrailBottom"
        tAtt1.Position = Vector3.new(0, -2.6, 0)
        tAtt1.Parent = hrp

        local trail = hrp:FindFirstChild("NeonSlideTrail") or Instance.new("Trail")
        trail.Name = "NeonSlideTrail"
        trail.Attachment0 = tAtt0
        trail.Attachment1 = tAtt1
        trail.Lifetime = 0.28
        trail.MinLength = 0.1
        trail.LightEmission = 1
        trail.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(165, 250, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 90, 255)),
        })
        trail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(1, 1),
        })
        trail.Parent = hrp
        slideTrail = trail
    end
    slideTrail.Enabled = true

    isSliding = true
    slideStartTime = now
    isInspecting = false
    WeaponAudio.playSlide()
    return true
end

-- บังคับล็อคเมาส์กลางจอและซ่อนเคอร์เซอร์ระหว่างเล่น (ปลดล็อคเฉพาะตอนเปิดเมนูเท่านั้น)
RunService:BindToRenderStep("EnforceMouseBehavior", Enum.RenderPriority.Last.Value, function()
    if isAnyModalOpen() or isCursorFree or isPlayerDeadClient or isShowcaseOrbitActive() then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    elseif isShowcaseThirdPersonActive() then
        UserInputService.MouseIconEnabled = true
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end
end)

----------------------------------------------------------------------
-- 5. ระบบรีโหลด COD STYLE & ตัวประมวลผลแอนิเมชัน 3D แยกตามกลไกปืน
----------------------------------------------------------------------
local WEAPON_ANIM_PROFILES = WeaponPoseSolver.PROFILES
local function getWeaponAnimProfile(weaponCfg)
    return WeaponPoseSolver.getProfile(weaponCfg)
end
local function solveWeaponAnimPose(dt, weaponCfg, reloadActive, reloadProg, inspectActive, isAimActive, isSprintActive)
    local g, la, da, m, b, p, c, sm, sr, inspectDone = WeaponPoseSolver.solve(weaponAnimState, dt, weaponCfg, reloadActive, reloadProg, inspectActive, isAimActive, isSprintActive, os.clock())
    if inspectDone then isInspecting = false end
    return g, la, da, m, b, p, c, sm, sr
end

local function reloadWeapon()
    if isReloading or isCharacterDead() or isCharacterDowned() or currentWeaponKey == "Unarmed" or (currentWeapon.Mag or 0) <= 0 or clipAmmo >= currentWeapon.Mag or reserveAmmo <= 0 or not weaponReloadEvent then return end
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
    if isReloading or buyMenuObj.Frame.Visible or isCharacterDead() or isCharacterDowned() then return end
    isInspecting = false

    local now = os.clock()
    if currentWeaponKey == "Unarmed" then
        local meleeRate = currentWeapon.FireRate or 0.65
        if now - lastShotTime < meleeRate then return end
        lastShotTime = now
        meleePunchUntil = now + 0.24
        weaponAnimState.lastShotTime = now
        weaponAnimState.inspectTimer = 0
        WeaponAudio.playMeleeSwing()
        recoilSpring:Impulse(Vector3.new(math.rad(-2.5), math.rad(1.5), -0.24))
        if weaponFireEvent then
            weaponFireEvent:FireServer("Unarmed", camera.CFrame.Position, camera.CFrame.LookVector.Unit)
        end
        return
    end

    -- 🔫 ยิงปืน (Gunfire)
    local fireRate = currentWeapon.FireRate
    if isAiming and currentWeapon.Optics and currentWeapon.Optics.ADS_FireRateMult then
        fireRate = fireRate / currentWeapon.Optics.ADS_FireRateMult
    end

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
        if state == Enum.UserInputState.Begin and equipSlot and not isCharacterDead() and not isCharacterDowned() then
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
        if state == Enum.UserInputState.Begin and equipSlot and not isCharacterDead() and not isCharacterDowned() then
            equipSlot(2)
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end,
    false,
    Enum.ContextActionPriority.High.Value + 200,
    Enum.KeyCode.Two, Enum.KeyCode.KeypadTwo
)

local function quickSwitchWeaponSlot()
    if not equipSlot then return end
    if activeSlot == 3 then
        local target = (inventorySlots[lastArmedSlot] and lastArmedSlot)
            or (inventorySlots[1] and 1)
            or (inventorySlots[2] and 2)
        if target then
            equipSlot(target)
        elseif showWeaponNotice then
            showWeaponNotice("ยังไม่มีปืน — รีบขึ้นชั้น 2 โรงอาหารหาของ & อาวุธ!")
        end
    elseif activeSlot == 1 then
        equipSlot(inventorySlots[2] and 2 or 3)
    else
        equipSlot(inventorySlots[1] and 1 or 3)
    end
end

local function cycleWeaponWheel(stepDir)
    if not equipSlot then return end
    local owned = {}
    for s = 1, 3 do
        if inventorySlots[s] then
            table.insert(owned, s)
        end
    end
    if #owned <= 1 then return end
    local curIdx = 1
    for i, slotNum in ipairs(owned) do
        if slotNum == activeSlot then
            curIdx = i
            break
        end
    end
    local nextIdx = ((curIdx - 1 + stepDir) % #owned) + 1
    equipSlot(owned[nextIdx])
end

local SUPPLY_KEY_TO_SLOT = {
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.KeypadFour] = 4,
    [Enum.KeyCode.Five] = 5,
    [Enum.KeyCode.KeypadFive] = 5,
    [Enum.KeyCode.Six] = 6,
    [Enum.KeyCode.KeypadSix] = 6,
}

ContextActionService:BindActionAtPriority(
    "WeaponSlot3",
    function(_, state)
        if state == Enum.UserInputState.Begin and equipSlot and not isCharacterDead() and not isCharacterDowned() then
            equipSlot(3)
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end,
    false,
    Enum.ContextActionPriority.High.Value + 200,
    Enum.KeyCode.Three, Enum.KeyCode.KeypadThree
)

ContextActionService:BindActionAtPriority(
    "SupplySlots456",
    function(_, state, inputObj)
        if UserInputService:GetFocusedTextBox() then
            return Enum.ContextActionResult.Pass
        end
        if state == Enum.UserInputState.Begin and inputObj and useSupplySlot and not isCharacterDead() and not isCharacterDowned() then
            local slotIdx = SUPPLY_KEY_TO_SLOT[inputObj.KeyCode]
            if slotIdx then
                useSupplySlot(slotIdx)
                return Enum.ContextActionResult.Sink
            end
        end
        return Enum.ContextActionResult.Pass
    end,
    false,
    Enum.ContextActionPriority.High.Value + 200,
    Enum.KeyCode.Four, Enum.KeyCode.KeypadFour,
    Enum.KeyCode.Five, Enum.KeyCode.KeypadFive,
    Enum.KeyCode.Six, Enum.KeyCode.KeypadSix
)

ContextActionService:BindActionAtPriority(
    "QuickSwitchQ",
    function(_, state)
        if state == Enum.UserInputState.Begin and equipSlot and not isCharacterDead() and not isCharacterDowned() then
            quickSwitchWeaponSlot()
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end,
    false,
    Enum.ContextActionPriority.High.Value + 200,
    Enum.KeyCode.Q
)

ContextActionService:BindActionAtPriority(
    "NeonSlideAction",
    function(_, state)
        if UserInputService:GetFocusedTextBox() then
            return Enum.ContextActionResult.Pass
        end
        if state == Enum.UserInputState.Begin then
            startNeonSlide()
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end,
    false,
    Enum.ContextActionPriority.High.Value + 500,
    Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl
)

UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end

    -- 🌟 สลับช่องอาวุธ 1-3 และกดใช้เสบียงพกพา 4-6 (InputBegan Fallback)
    local supplySlot = SUPPLY_KEY_TO_SLOT[input.KeyCode]
    if supplySlot then
        if (not gp) and useSupplySlot and not isCharacterDead() and not isCharacterDowned() then
            useSupplySlot(supplySlot)
        end
        return
    elseif input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
        if equipSlot and not isCharacterDead() and not isCharacterDowned() then equipSlot(1) end
        return
    elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.KeypadTwo then
        if equipSlot and not isCharacterDead() and not isCharacterDowned() then equipSlot(2) end
        return
    elseif input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
        if equipSlot and not isCharacterDead() and not isCharacterDowned() then equipSlot(3) end
        return
    elseif input.KeyCode == Enum.KeyCode.Q then
        if not isCharacterDead() and not isCharacterDowned() then
            quickSwitchWeaponSlot()
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

    -- ⚡ กด Left Control / Right Control เพื่อสไลด์แบบ Neon (Valorant High Gear Slide)
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        startNeonSlide()
        return
    end

    -- [Y] inspect is separate from the elevator's [F] interaction.
    if input.KeyCode == Enum.KeyCode.Y then
        if isReloading or isAiming or isSprinting or isCharacterDead() or isCharacterDowned() then
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

    if input.KeyCode == Enum.KeyCode.H then
        cycleHorrorPreset()
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

    if buyMenuObj.Frame.Visible or isAnyModalOpen() or isCharacterDead() or isCharacterDowned() or isShowcaseCameraActive() then return end

    -- คลิกซ้าย: โจมตี (ยิงปืน หรือ ผลักมือเปล่า)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isCursorFree and gp then return end
        if isCursorFree then
            isCursorFree = false
            setCameraFrozen(false)
        end
        isMouseDown = true
        executeAttack()
    -- คลิกขวา: เล็ง ADS (ปิดเมื่อถือมือเปล่า)
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        if currentWeaponKey ~= "Unarmed" then
            isAiming = true
            isInspecting = false
            opticsUI:SetAiming(true, currentWeapon)
        end
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

    -- 🌟 หมุนลูกกลิ้งเมาส์สลับช่องที่มีในตัว [1] <-> [2] <-> [3]
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        if isCharacterDead() or isCharacterDowned() then return end
        local dir = (input.Position.Z < 0) and 1 or -1
        cycleWeaponWheel(dir)
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
    if isMouseDown and not isReloading and currentWeapon.FiringType == "Auto" and not buyMenuObj.Frame.Visible and not isAnyModalOpen() and not isCharacterDead() and not isCharacterDowned() and not isShowcaseCameraActive() then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            executeAttack()
        else
            isMouseDown = false
        end
    end
end)

----------------------------------------------------------------------
-- 9. อัปเดตแอนิเมชันทุกเฟรม (RENDER STEPPED // AUTO-RUN, SHIFT +4 BOOST, HORROR ATMOSPHERE)
----------------------------------------------------------------------
local nextHorrorAmbienceAt = os.clock() + 9
local nextHungerGrowlAt = os.clock() + 10
local currentVignetteAlpha = 0
local rangeLightingPaused = false

RunService.RenderStepped:Connect(function(dt)
    -- 0. ระบบพละกำลัง การวิ่งเร็ว Neon Slide สถานะตาย/ล้ม และความเร็วตัวละคร
    local now = os.clock()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local vel = hrp and hrp.AssemblyLinearVelocity.Magnitude or 0
    local isMoving = (vel > 1.5)
    local isDead = (char ~= nil) and ((not hum) or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead)
    local isDowned = (not isDead) and ((player:GetAttribute("IsDowned") == true)
        or (char and char:GetAttribute("IsDowned") == true)
        or (hrp and hrp:FindFirstChild("RevivePrompt") ~= nil))

    local wasDead = isPlayerDeadClient
    isPlayerDeadClient = isDead
    isPlayerDownedClient = isDowned

    if isDead then
        if not wasDead then
            deathStartTime = now
            stopNeonSlide(false)
            isMouseDown = false
            isSprinting = false
            isShiftDown = false
            isInspecting = false
            if isReloading then
                reloadSequence = reloadSequence + 1
                isReloading = false
                updateAmmoUI()
            end
            if isAiming then
                isAiming = false
                opticsUI:SetAiming(false, currentWeapon)
            end
            pcall(function()
                player.CameraMode = Enum.CameraMode.Classic
                player.CameraMinZoomDistance = 8
                player.CameraMaxZoomDistance = 14
            end)
        end
        if deathOverlay then
            deathOverlay.Visible = true
            if deathSubLabel then
                local respawnDelay = math.max(1, Players.RespawnTime or 5)
                local rem = math.max(0, math.ceil(respawnDelay - (now - deathStartTime)))
                deathSubLabel.Text = (rem > 0)
                    and string.format("กำลังเกิดใหม่ในอีก %d วินาที...", rem)
                    or "กำลังเกิดใหม่..."
            end
        end
        if downedBanner then
            downedBanner.Visible = false
        end
    else
        if wasDead then
            enforceFirstPerson()
        end
        if deathOverlay then
            deathOverlay.Visible = false
        end
        if isDowned then
            if isReloading then
                reloadSequence = reloadSequence + 1
                isReloading = false
                updateAmmoUI()
            end
            if isAiming then
                isAiming = false
                opticsUI:SetAiming(false, currentWeapon)
            end
            isMouseDown = false
            isSprinting = false
            isInspecting = false
            if downedBanner then
                local bleedEnd = (char and char:GetAttribute("BleedoutEndTime")) or player:GetAttribute("BleedoutEndTime")
                local rem = bleedEnd and math.max(0, math.ceil(bleedEnd - Workspace:GetServerTimeNow())) or 30
                downedBanner.Text = string.format("🚨 DOWNED // คลานรอเพื่อนกด [E] ชุบ (เหลือ %d วินาที)", rem)
                downedBanner.Visible = true
            end
        elseif downedBanner then
            downedBanner.Visible = false
        end
    end

    -- อัปเดต Neon Slide (ความเร็ว, ระยะก้มกล้อง, มุมเอียงปืน)
    local targetSlideCamY = 0
    local targetSlideVM = CFrame.identity
    if isSliding then
        local elapsed = now - slideStartTime
        if isDead or isDowned or buyMenuObj.Frame.Visible or (hum and hum.Jump) or elapsed >= SLIDE_DURATION then
            stopNeonSlide(hum and hum.Jump)
        else
            local p = math.clamp(elapsed / SLIDE_DURATION, 0, 1)
            local peak = isAdminMode and SLIDE_PEAK_SPEED_ADMIN or SLIDE_PEAK_SPEED
            local tail = isAdminMode and SLIDE_END_SPEED_ADMIN or SLIDE_END_SPEED
            local slideSpeed = peak + (tail - peak) * (p ^ 0.72)
            if slideLinearVelocity and slideLinearVelocity.Parent then
                slideLinearVelocity.VectorVelocity = Vector3.new(slideDirection.X * slideSpeed, 0, slideDirection.Z * slideSpeed)
            end

            local dropCurve = (p < 0.16) and (p / 0.16)
                or ((p > 0.74) and (1 - (p - 0.74) / 0.26) or 1)
            targetSlideCamY = SLIDE_CAMERA_DROP * math.clamp(dropCurve, 0, 1)

            if not isAiming then
                targetSlideVM = CFrame.new(-0.07 * slideLateralSign, -0.09, -0.04)
                    * CFrame.Angles(math.rad(-4), math.rad(slideLateralSign * 8), math.rad(slideLateralSign * 14))
            end
        end
    elseif isDowned then
        targetSlideCamY = -1.75
    end

    currentSlideCamOffsetY = currentSlideCamOffsetY + (targetSlideCamY - currentSlideCamOffsetY) * math.clamp(dt * 24, 0, 1)
    if hum then
        if math.abs(currentSlideCamOffsetY) > 0.004 then
            hum.CameraOffset = Vector3.new(0, currentSlideCamOffsetY, 0)
        elseif hum.CameraOffset ~= Vector3.zero then
            hum.CameraOffset = Vector3.zero
        end
    end
    currentSlideViewmodelCF = currentSlideViewmodelCF:Lerp(targetSlideVM, math.clamp(dt * 18, 0, 1))

    local hungerVal = player:GetAttribute("Hunger") or 100
    local batVal = player:GetAttribute("FlashlightBattery") or 100
    local staminaBoostRem = math.max(0, (player:GetAttribute("StaminaBoostUntil") or 0) - Workspace:GetServerTimeNow())
    local insideRangeNow = isInsideTestRangeClient and isInsideTestRangeClient() or false

    -- เงื่อนไขการบูส Shift (+4 Speed): กด Shift, กำลังเคลื่อนที่, หิวไม่เป็น 0 (หรือมี Energy Boost), ไม่ได้สไลด์/เล็ง ADS/ล้ม/หมดแรง
    if isAdminMode or staminaBoostRem > 0 then
        currentStamina = MAX_STAMINA
        isExhausted = false
        isSprinting = isShiftDown and isMoving and (not isSliding) and (not isAiming) and (not buyMenuObj.Frame.Visible) and (not isDead) and (not isDowned)
    else
        local hungerAllowsBoost = (hungerVal > 0)
        local canSprint = isShiftDown and isMoving and hungerAllowsBoost and (not isSliding) and (not isAiming) and (not isExhausted) and (currentStamina > 0) and (not buyMenuObj.Frame.Visible) and (not isDead) and (not isDowned)

        if canSprint then
            isSprinting = true
            lastSprintTime = now
            currentStamina = math.max(0, currentStamina - STAMINA_DRAIN_PER_SEC * dt)
            if currentStamina <= 0 then
                isExhausted = true
                isSprinting = false
                WeaponAudio.playClick(1.4) -- เสียงลมหายใจสะดุดเบาๆ บ่งบอกว่าหมดแรง
            end
        else
            isSprinting = false
            -- รีเจนพลังงานหลังจากหยุดวิ่งตามดีเลย์ที่กำหนด (ช้าลงเมื่อหิว)
            if (not isSliding) and (now - lastSprintTime >= STAMINA_REGEN_DELAY) then
                local regenMult = (hungerVal <= 0) and 0.35 or ((hungerVal <= 25) and 0.55 or 1.0)
                currentStamina = math.min(MAX_STAMINA, currentStamina + STAMINA_REGEN_PER_SEC * regenMult * dt)
                if isExhausted and currentStamina >= EXHAUSTION_RECOVERY_POINT then
                    isExhausted = false
                end
            end
        end
    end

    -- อัปเดต WalkSpeed ของ Humanoid (W วิ่ง Auto + Shift บูส +4 + มือเปล่า [3] วิ่งไวกว่า)
    local isUnarmed = (currentWeaponKey == "Unarmed")
    if hum and hum.Health > 0 and not isDowned and not isSliding then
        local baseAuto = isUnarmed and AUTORUN_UNARMED_SPEED or AUTORUN_ARMED_SPEED
        local exhSpeed = isUnarmed and EXHAUSTED_UNARMED_SPEED or EXHAUSTED_ARMED_SPEED
        if isAdminMode then
            hum.WalkSpeed = isSprinting and SPRINT_SPEED_ADMIN or WALK_SPEED_ADMIN
        elseif isSprinting then
            hum.WalkSpeed = baseAuto + SHIFT_BOOST_BONUS
        elseif isExhausted then
            hum.WalkSpeed = exhSpeed
        else
            hum.WalkSpeed = baseAuto
        end
    end

    -- อัปเดต HUD & ไฟฉาย & บรรยากาศสยองขวัญทั้ง 2 โหมด ([H] / [N])
    updateStaminaUI()
    updateSlideUI(now)
    updateHealthUI(hum)
    updateSurvivalHUD(hungerVal, batVal)

    if flashlightLight and flashlightLight.Parent then
        local canShowLight = flashlightEnabled and (isAdminMode or batVal > 0) and (not isDead)
        flashlightLight.Enabled = canShowLight
        if canShowLight then
            if lightingMode == "Horror" and batVal < 15 and not isAdminMode then
                local flicker = math.sin(now * 28) * math.cos(now * 17)
                flashlightLight.Brightness = (flicker > 0.62) and 0.45 or 2.4
            else
                flashlightLight.Brightness = 2.6
            end
        end
    end

    if lightingMode == "Horror" then
        if insideRangeNow then
            if not rangeLightingPaused then
                rangeLightingPaused = true
                Lighting.FogEnd = 420
                Lighting.Brightness = 0.85
            end
        else
            if rangeLightingPaused then
                rangeLightingPaused = false
                Lighting.FogEnd = (activeHorrorPreset == "Blackout") and 92 or 165
                Lighting.Brightness = (activeHorrorPreset == "Blackout") and 0.24 or 0.52
            end
            local beaconPulse = 1.65 + 1.05 * math.sin(now * 2.6)
            for _, emerg in ipairs(emergencyLightsList) do
                if emerg and emerg.Parent then
                    emerg.Enabled = true
                    emerg.Brightness = beaconPulse
                end
            end
        end

        if (not insideRangeNow) and (not isDead) and hrp and now >= nextHorrorAmbienceAt then
            nextHorrorAmbienceAt = now + math.random(13, 25)
            local angle = math.rad(math.random(0, 359))
            local dist = math.random(18, 36)
            local cuePos = hrp.Position + Vector3.new(math.cos(angle) * dist, math.random(-2, 8), math.sin(angle) * dist)
            local cuePool = { "Creak", "Groan", "Heart" }
            WeaponAudio.playHorrorCue(cuePool[math.random(1, #cuePool)], cuePos)
        end
    else
        rangeLightingPaused = false
    end

    if hungerVal <= 15 and (not isAdminMode) and (not isDead) and now >= nextHungerGrowlAt then
        nextHungerGrowlAt = now + 11
        WeaponAudio.playHeartbeat()
    end

    local targetVigAlpha = (lightingMode == "Horror" and not insideRangeNow and not isDead)
        and ((activeHorrorPreset == "Blackout") and 0.58 or 0.34)
        or 0
    currentVignetteAlpha = currentVignetteAlpha + (targetVigAlpha - currentVignetteAlpha) * math.clamp(dt * 4, 0, 1)
    for _, edge in ipairs(horrorVignetteEdges) do
        edge.BackgroundTransparency = 1 - currentVignetteAlpha
    end

    -- 1. ADS Target Offset
    local adsTarget = (currentWeapon.Optics and currentWeapon.Optics.Offset) or CFrame.new(0, -0.42, -1.15)
    local hipTarget = currentWeapon.HipOffset or CFrame.new(0.60, -0.55, -1.35)
    local targetOffset = isAiming and adsTarget or hipTarget
    currentOffset = currentOffset:Lerp(targetOffset, math.clamp(dt * 18, 0, 1))

    -- 2. FOV Zoom & Boost / Empty-Hands Speed Dynamic FOV
    if not isShowcaseOrbitActive() then
        local targetFov = 70
        if isAiming then
            targetFov = (currentWeapon.Optics and currentWeapon.Optics.ZoomFOV) or 52
        elseif isSliding then
            local sp = math.clamp((now - slideStartTime) / SLIDE_DURATION, 0, 1)
            targetFov = 86 - 10 * sp
        elseif isSprinting and isMoving then
            targetFov = 76
        elseif isUnarmed and isMoving then
            targetFov = 73
        end
        camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * math.clamp(dt * (isSliding and 22 or 15), 0, 1)
    end

    -- 3. อัปเดตสปริงแรงถีบ (Spring Recoil)
    local recSpringVec = recoilSpring:Update(dt)

    -- 4. การโยกตัวตามจังหวะก้าวเดิน (Subtle Tactical Bobbing - นิ่งสนิท สไตล์ Valorant)
    local bobFreq = 2.0
    local bobAmp = 0.002
    if isSliding then
        bobFreq = 2.0
        bobAmp = 0.001 -- ไถลราบกับพื้น ปืนไม่กระเด้ง
    elseif isSprinting and isMoving then
        bobFreq = isUnarmed and 11.5 or 10.0
        bobAmp = isUnarmed and 0.022 or 0.016
    elseif isMoving then
        bobFreq = isUnarmed and 9.0 or 7.0
        bobAmp = isUnarmed and 0.012 or 0.007
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

    -- 5. แอนิเมชัน 3D ครบวงจร (แขนมือเปล่าแกว่งวิ่ง + ผลัก Melee / หรือ รีโหลด+ส่องปืน [Y])
    local gunAnimCF, leftArmAnimCF, leftDetachAlpha, magCF, boltCF, pumpCF, cylinderCF, showMag, showReloadOnly
    if isUnarmed then
        local runFactor = isMoving and (isSprinting and 1.0 or 0.72) or 0
        local swing = math.sin(swayTimer)
        gunAnimCF = CFrame.new(0, math.abs(swing) * 0.025 * runFactor, swing * 0.14 * runFactor)
            * CFrame.Angles(math.rad(-swing * 9 * runFactor), 0, 0)
        leftArmAnimCF = CFrame.new(0, math.abs(swing) * 0.025 * runFactor, -swing * 0.14 * runFactor)
            * CFrame.Angles(math.rad(swing * 9 * runFactor), 0, 0)

        if now < meleePunchUntil then
            local shoveT = 1 - math.clamp((meleePunchUntil - now) / 0.24, 0, 1)
            local thrust = math.sin(shoveT * math.pi)
            gunAnimCF = gunAnimCF * CFrame.new(-0.08 * thrust, 0.10 * thrust, -0.58 * thrust)
                * CFrame.Angles(math.rad(14 * thrust), math.rad(12 * thrust), math.rad(-8 * thrust))
            leftArmAnimCF = leftArmAnimCF * CFrame.new(0.08 * thrust, 0.10 * thrust, -0.58 * thrust)
                * CFrame.Angles(math.rad(14 * thrust), math.rad(-12 * thrust), math.rad(8 * thrust))
        end

        leftDetachAlpha = 1
        magCF, boltCF, pumpCF, cylinderCF = CFrame.identity, CFrame.identity, CFrame.identity, CFrame.identity
        showMag, showReloadOnly = false, false
    else
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

        gunAnimCF, leftArmAnimCF, leftDetachAlpha, magCF, boltCF, pumpCF, cylinderCF, showMag, showReloadOnly =
            solveWeaponAnimPose(dt, currentWeapon, isReloading, reloadProg, isInspecting, isAiming, isSprinting)
    end

    -- 🌟 6. มุมเอียงปืนขณะวิ่ง (Tactical Sprint Weapon Tilt)
    local targetSprintOffset = CFrame.identity
    if not isUnarmed and isSprinting and isMoving and not isAiming then
        targetSprintOffset = CFrame.new(-0.04, -0.06, -0.05) * CFrame.Angles(math.rad(-3), math.rad(-5), math.rad(4))
    end
    currentSprintCFrame = currentSprintCFrame:Lerp(targetSprintOffset, math.clamp(dt * 12, 0, 1))

    -- 7. ประกอบ CFrame Viewmodel (นิ่ง แม่นยำ สบายตา สไตล์ Valorant + Neon Slide Cant)
    local motionCFrame = CFrame.new(bobX - currentMouseSwayX * 0.4, bobY - currentMouseSwayY * 0.4, recSpringVec.Z) * CFrame.Angles(
        recSpringVec.X + swayRotX,
        recSpringVec.Y + swayRotY,
        swayRollZ
    ) * currentSprintCFrame * currentSlideViewmodelCF

    local isSniperAiming = (not isUnarmed) and isAiming and (currentWeapon.Optics and currentWeapon.Optics.IsSniperScope == true)
    local hideViewmodel = isDead or isDowned or isSniperAiming or isShowcaseCameraActive()
    local baseRootCF = hideViewmodel and CFrame.new(0, -999, 0) or (camera.CFrame * currentOffset * motionCFrame)
    local finalRootCF = hideViewmodel and baseRootCF or (baseRootCF * gunAnimCF)
    local leftArmRootCF = hideViewmodel and baseRootCF or (baseRootCF * gunAnimCF:Lerp(CFrame.identity, leftDetachAlpha) * leftArmAnimCF)
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

-- เริ่มต้นระบบ Unarmed + HUD + โหมดหลอน 1 (Deep Blackout) พร้อม [N] สลับดูตึกสว่าง & [H] สลับโหมดหลอน
rebuildViewmodel()
updateSlotUI()
updateAmmoUI()
updateStaminaUI()
updateSlideUI(os.clock())
updateSurvivalHUD()
applyLightingMode(lightingMode)

print("=========================================================")
print("🌑 [Survival Horror Ready] Unarmed Auto-Run | Shift +4 Boost | Hunger | [H] 2 Horror Modes | [N] Daylight Inspect")
print("=========================================================")
