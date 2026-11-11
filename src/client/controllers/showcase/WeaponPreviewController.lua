--[[
    WeaponPreviewController.lua
    Manages Weapon Library filtering/searching, single-weapon 3D spawning on the
    isolated stage, 1P/3P rig modes, and procedural WeaponPoseSolver animations
    (Idle, Equip, Unequip, Reload, Fire, Recoil, Inspect) without duplicating solver logic.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponsFolder = ReplicatedStorage:WaitForChild("Weapons", 10)
local WeaponRegistry = require(WeaponsFolder:WaitForChild("WeaponRegistry"))
local WeaponModelBuilder = require(WeaponsFolder:WaitForChild("models"):WaitForChild("WeaponModelBuilder"))
local KMUTNBArms = require(WeaponsFolder:WaitForChild("models"):WaitForChild("KMUTNBArms"))
local WeaponPoseSolver = require(WeaponsFolder:WaitForChild("animations"):WaitForChild("WeaponPoseSolver"))
local RecoilSpring = require(WeaponsFolder:WaitForChild("effects"):WaitForChild("RecoilSpring"))
local WeaponAudio = require(WeaponsFolder:WaitForChild("effects"):WaitForChild("WeaponAudio"))

local CharacterPreviewController = require(script.Parent:WaitForChild("CharacterPreviewController"))

local WeaponPreviewController = {}
WeaponPreviewController.__index = WeaponPreviewController

WeaponPreviewController.CATEGORY_FILTERS = {
    "All",
    "Sidearms",
    "SMGs",
    "Shotguns",
    "Rifles",
    "Snipers",
    "Heavy",
}

local CANONICAL_ORDER = {
    "Classic", "Shorty", "Frenzy", "Ghost", "Sheriff",
    "Stinger", "Spectre",
    "Bucky", "Judge",
    "Bulldog", "Guardian", "Phantom", "Vandal",
    "Marshal", "Outlaw", "Operator",
    "Ares", "Odin",
}

WeaponPreviewController.WEAPON_CLIPS = {
    { id = "Idle", label = "Idle", supported = true, note = "Ready weapon rest stance." },
    { id = "Equip", label = "Equip", supported = true, note = "Procedural draw curve via WeaponPoseSolver.evalEquipPose." },
    { id = "Unequip", label = "Unequip", supported = true, note = "Procedural stow curve via WeaponPoseSolver.evalUnequipPose." },
    { id = "Reload", label = "Reload", supported = true, note = "Full multi-phase reload with Mag/Bolt/Cylinder/Shell audio cues." },
    { id = "Fire", label = "Fire (Single)", supported = true, note = "Single shot with muzzle flash, mechanical cycling & shot SFX." },
    { id = "Recoil", label = "Fire & Recoil (Burst/Auto)", supported = true, note = "Sustained firing at true weapon FireRate with RecoilSpring kick." },
    { id = "Inspect", label = "Weapon Inspection", supported = true, note = "3.6s tactical weapon rotation inspection." },
}

function WeaponPreviewController.getAllWeapons(categoryFilter, searchText)
    local allMap = WeaponRegistry.getAll()
    local seen = {}
    local orderedKeys = {}

    for _, name in ipairs(CANONICAL_ORDER) do
        if allMap[name] then
            table.insert(orderedKeys, name)
            seen[name] = true
        end
    end
    for k in pairs(allMap) do
        if not seen[k] then
            table.insert(orderedKeys, k)
        end
    end

    local query = searchText and string.lower((searchText:gsub("^%s*(.-)%s*$", "%1"))) or ""
    local results = {}
    for _, key in ipairs(orderedKeys) do
        local cfg = allMap[key]
        local cat = cfg.Category or cfg.Type or "Weapons"
        local matchesCat = (not categoryFilter or categoryFilter == "All" or string.lower(cat) == string.lower(categoryFilter))
        local haystack = string.lower(key .. " " .. (cfg.Name or "") .. " " .. cat .. " " .. (cfg.Type or ""))
        local matchesQuery = (query == "" or string.find(haystack, query, 1, true) ~= nil)
        if matchesCat and matchesQuery then
            table.insert(results, { key = key, cfg = cfg })
        end
    end
    return results
end

function WeaponPreviewController.extractStats(weaponKey, cfg)
    cfg = cfg or WeaponRegistry.get(weaponKey)
    local headDmg = (type(cfg.Damage) == "table" and cfg.Damage.Head) or cfg.HeadDmg or 0
    local bodyDmg = (type(cfg.Damage) == "table" and cfg.Damage.Body) or cfg.BodyDmg or 0
    local legsDmg = (type(cfg.Damage) == "table" and cfg.Damage.Legs) or math.round(bodyDmg * 0.85)
    local fireRateSec = (type(cfg.FireRate) == "number" and cfg.FireRate > 0) and cfg.FireRate or 0.15
    local rpm = math.round(60 / fireRateSec)
    local pellets = cfg.Pellets or 1
    local profile = WeaponPoseSolver.getProfile(cfg)
    local zoomFov = cfg.Optics and cfg.Optics.ZoomFOV or 70
    local silenced = (cfg.Audio and cfg.Audio.Silenced) == true

    return {
        key = weaponKey,
        name = cfg.Name or weaponKey:upper(),
        category = cfg.Category or cfg.Type or "Weapon",
        weaponType = cfg.Type or "Rifle",
        firingType = cfg.FiringType or "Semi",
        headDmg = headDmg,
        bodyDmg = bodyDmg,
        legsDmg = legsDmg,
        fireRateSec = fireRateSec,
        rpm = rpm,
        mag = cfg.Mag or 0,
        reserve = cfg.Reserve or 0,
        pellets = pellets,
        zoomFov = zoomFov,
        silenced = silenced,
        shotMode = profile and profile.shotMode or "Standard",
        reloadTime = cfg.ReloadTime or 2.0,
    }
end

function WeaponPreviewController.new()
    return setmetatable({
        weaponKey = "Vandal",
        weaponCfg = WeaponRegistry.get("Vandal"),
        viewMode = "Gun3D", -- "Gun3D" | "Viewmodel1P" | "Character3P"
        isADS = false,
        clipId = "Idle",
        paused = false,
        stopped = false,
        speed = 1.0,
        loop = true,

        timer = 0,
        clock = 0,
        lastShotAt = -10,
        prevReloadProg = 0,
        muzzleFlashTimer = 0,
        muzzleRoll = 0,

        model = nil,
        gunRoot = nil,
        eyeCF = CFrame.identity,
        anchorPos = Vector3.zero,
        gunCenterLocalOffset = Vector3.zero,
        parts = {},
        leftArmParts = {},
        baseTransparency = {},
        animGroups = { Magazine = {}, Bolt = {}, Pump = {}, Cylinder = {}, ReloadOnly = {} },
        muzzleFlashParts = {},
        flashLight = nil,
        smokeEmitter = nil,
        tpClone = nil,
        tpRoot = nil,
        animState = WeaponPoseSolver.newState(),
        recoilSpring = RecoilSpring.new(1, 45, 6, 8),
    }, WeaponPreviewController)
end

function WeaponPreviewController:clear()
    if self.tpClone then
        self.tpClone:Destroy()
        self.tpClone = nil
        self.tpRoot = nil
    end
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
    self.gunRoot = nil
    self.parts = {}
    self.leftArmParts = {}
    self.baseTransparency = {}
    self.animGroups = { Magazine = {}, Bolt = {}, Pump = {}, Cylinder = {}, ReloadOnly = {} }
    self.muzzleFlashParts = {}
    self.flashLight = nil
    self.smokeEmitter = nil
    WeaponPoseSolver.resetState(self.animState)
end

function WeaponPreviewController:spawn(weaponKey, viewMode, mountParent, groundPos)
    self:clear()
    self.weaponKey = weaponKey or self.weaponKey or "Vandal"
    self.weaponCfg = WeaponRegistry.get(self.weaponKey)
    self.viewMode = viewMode or self.viewMode or "Gun3D"
    self.anchorPos = groundPos
    self.eyeCF = CFrame.lookAt(
        groundPos + Vector3.new(-0.35, 3.3, 1.8),
        groundPos + Vector3.new(-0.35, 3.3, -4.0)
    )

    WeaponPoseSolver.resetState(self.animState)
    self.recoilSpring = RecoilSpring.new(1, 45, 6, 8)
    self.muzzleFlashTimer = 0

    local container = Instance.new("Model")
    container.Name = "ShowcaseWeapon_" .. self.weaponKey
    container.Parent = mountParent
    self.model = container

    local gunRoot = Instance.new("Part")
    gunRoot.Name = "ShowcaseGunRoot"
    gunRoot.Size = Vector3.new(0.2, 0.2, 0.2)
    gunRoot.Transparency = 1
    gunRoot.Anchored = true
    gunRoot.CanCollide = false
    gunRoot.CanQuery = false
    gunRoot.CanTouch = false
    gunRoot.Parent = container
    self.gunRoot = gunRoot

    if self.viewMode == "Viewmodel1P" then
        local arms, leftArms = KMUTNBArms.build(container, self.weaponCfg)
        for p, relCF in pairs(arms) do
            self.parts[p] = relCF
            self.baseTransparency[p] = p.Transparency
        end
        for p, relCF in pairs(leftArms) do
            self.leftArmParts[p] = relCF
        end
    elseif self.viewMode == "Character3P" then
        local clone, _, animator, root = CharacterPreviewController.createIsolatedPlayerClone(groundPos, 180)
        if clone then
            clone.Name = "ShowcaseWeapon3PCharacter"
            clone.Parent = container
            self.tpClone = clone
            self.tpRoot = root
            local animMap = CharacterPreviewController.collectPlayerAnimateTracks()
            if animMap.idle and animator then
                local ok, tr = pcall(function() return animator:LoadAnimation(animMap.idle.animObj) end)
                if ok and tr then
                    tr.Looped = true
                    tr:Play(0.05)
                end
            end
        end
    end

    local wParts, mParts, fLight, sEmitter, pGroups = WeaponModelBuilder.build(container, self.weaponCfg, gunRoot)
    local minB = Vector3.new(math.huge, math.huge, math.huge)
    local maxB = Vector3.new(-math.huge, -math.huge, -math.huge)
    local hasGeom = false
    for p, relCF in pairs(wParts) do
        self.parts[p] = relCF
        self.baseTransparency[p] = p.Transparency
        if p.Name == "SpeedloaderBase" or p.Name:match("^ReloadShell") or p.Name == "MarshalShell" then
            self.animGroups.ReloadOnly[p] = true
            p.Transparency = 1
        elseif not p.Name:match("^MuzzleFlash") then
            hasGeom = true
            local pos = relCF.Position
            minB = Vector3.new(math.min(minB.X, pos.X), math.min(minB.Y, pos.Y), math.min(minB.Z, pos.Z))
            maxB = Vector3.new(math.max(maxB.X, pos.X), math.max(maxB.Y, pos.Y), math.max(maxB.Z, pos.Z))
        end
    end
    self.gunCenterLocalOffset = hasGeom and ((minB + maxB) * 0.5) or Vector3.zero
    if type(pGroups) == "table" then
        for gName, gMap in pairs(pGroups) do
            if self.animGroups[gName] and type(gMap) == "table" then
                for p, flag in pairs(gMap) do
                    if flag then self.animGroups[gName][p] = true end
                end
            end
        end
    end
    self.muzzleFlashParts = mParts or {}
    self.flashLight = fLight
    self.smokeEmitter = sEmitter

    -- Step once immediately so parts snap neatly before first frame
    self:step(0)

    if self.viewMode == "Character3P" then
        return {
            focusPos = groundPos + Vector3.new(0, 2.8, 0),
            dist = 7.4,
            yaw = math.rad(205),
            pitch = math.rad(-12),
            eyeCF = self.eyeCF,
        }
    elseif self.viewMode == "Viewmodel1P" then
        return {
            focusPos = (self.eyeCF * (self.weaponCfg.HipOffset or CFrame.new(0.6, -0.55, -1.35))).Position,
            dist = 3.2,
            yaw = math.rad(215),
            pitch = math.rad(-14),
            eyeCF = self.eyeCF,
        }
    end

    local isHeavyOrSniper = (self.weaponCfg.IsSniper or self.weaponCfg.Type == "Heavy")
    return {
        focusPos = groundPos + Vector3.new(0, 2.65, 0),
        dist = isHeavyOrSniper and 4.4 or 3.3,
        yaw = math.rad(220),
        pitch = math.rad(-14),
        eyeCF = self.eyeCF,
    }
end

function WeaponPreviewController:_triggerShot()
    local cfg = self.weaponCfg
    if not cfg then return end
    self.animState.lastShotTime = self.clock
    self.animState.cylinderIndex = (self.animState.cylinderIndex or 0) + 1
    self.muzzleFlashTimer = 0.055
    self.muzzleRoll = math.random(0, 360)

    local rec = cfg.Recoil or {}
    self.recoilSpring:Impulse(Vector3.new(
        math.rad(rec.PitchX or 3.8),
        math.rad((math.random() - 0.5) * (rec.YawY or 1.6) * 2.2),
        rec.KickZ or 0.35
    ))
    WeaponAudio.playShot(cfg)
    if self.smokeEmitter then
        self.smokeEmitter:Emit(3)
    end
end

function WeaponPreviewController:playClip(clipId)
    self.clipId = clipId or "Idle"
    self.paused = false
    self.stopped = false
    self.timer = 0
    self.prevReloadProg = 0
    self.lastShotAt = -10
    WeaponPoseSolver.resetState(self.animState)

    if self.clipId == "Equip" then
        WeaponAudio.playClick(2.7)
    elseif self.clipId == "Fire" or self.clipId == "Recoil" then
        self:_triggerShot()
        self.lastShotAt = self.clock
    end
end

function WeaponPreviewController:stop()
    self.stopped = true
    self.paused = true
    self.timer = 0
    self.prevReloadProg = 0
    self.clipId = "Idle"
    WeaponPoseSolver.resetState(self.animState)
    self.recoilSpring = RecoilSpring.new(1, 45, 6, 8)
    self.muzzleFlashTimer = 0
    self:step(0)
end

function WeaponPreviewController:step(dt)
    if not self.model or not self.gunRoot or not self.weaponCfg then return nil end

    local cfg = self.weaponCfg
    local dtScaled = (self.paused or self.stopped) and 0 or (dt * self.speed)
    self.clock = self.clock + dtScaled
    self.timer = self.timer + dtScaled

    local clip = self.clipId
    local profile = WeaponPoseSolver.getProfile(cfg)
    local isReload = (clip == "Reload") and not self.stopped
    local isInspect = (clip == "Inspect") and not self.stopped
    local reloadDur = math.max(0.4, cfg.ReloadTime or 2.0)
    local reloadProg = 0

    if isReload then
        if self.timer >= reloadDur then
            if self.loop then
                self.timer = 0
                self.prevReloadProg = 0
            else
                self.timer = reloadDur
            end
        end
        reloadProg = math.clamp(self.timer / reloadDur, 0, 1)
        if not self.paused and profile.audioCues then
            for _, cue in ipairs(profile.audioCues) do
                if self.prevReloadProg < cue[1] and reloadProg >= cue[1] then
                    WeaponAudio.playReloadStage(cfg, cue[2])
                end
            end
        end
        self.prevReloadProg = reloadProg
    elseif clip == "Recoil" and not self.paused and not self.stopped then
        local fireInterval = math.max(0.06, (type(cfg.FireRate) == "number" and cfg.FireRate > 0) and cfg.FireRate or 0.14)
        if (self.clock - self.lastShotAt) >= fireInterval then
            self:_triggerShot()
            self.lastShotAt = self.clock
        end
    elseif isInspect and self.timer >= WeaponPoseSolver.INSPECT_DURATION then
        if self.loop then
            self.timer = 0
            self.animState.inspectTimer = 0
        else
            self.stopped = true
            self.clipId = "Idle"
        end
    end

    local extraGunCF = CFrame.identity
    local extraLeftCF = CFrame.identity
    if clip == "Equip" and not self.stopped then
        if self.timer >= WeaponPoseSolver.EQUIP_DURATION then
            if self.loop then
                self.timer = 0
                WeaponAudio.playClick(2.7)
            else
                self.timer = WeaponPoseSolver.EQUIP_DURATION
            end
        end
        local ep = math.clamp(self.timer / WeaponPoseSolver.EQUIP_DURATION, 0, 1)
        extraGunCF, extraLeftCF = WeaponPoseSolver.evalEquipPose(ep)
    elseif clip == "Unequip" and not self.stopped then
        if self.timer >= WeaponPoseSolver.UNEQUIP_DURATION then
            if self.loop then
                self.timer = 0
            else
                self.timer = WeaponPoseSolver.UNEQUIP_DURATION
            end
        end
        local up = math.clamp(self.timer / WeaponPoseSolver.UNEQUIP_DURATION, 0, 1)
        extraGunCF, extraLeftCF = WeaponPoseSolver.evalUnequipPose(up)
    end

    local recVec = self.recoilSpring:Update(dtScaled)
    local recCF = CFrame.new(0, 0, recVec.Z * 0.18) * CFrame.Angles(recVec.X, recVec.Y, 0)

    local gAnim, lAnim, detachAlpha, magCF, boltCF, pumpCF, cylCF, showMag, showReloadOnly =
        WeaponPoseSolver.solve(self.animState, dtScaled, cfg, isReload, reloadProg, isInspect, self.isADS, false, self.clock)

    local baseCF
    if self.viewMode == "Character3P" and self.tpRoot then
        baseCF = self.tpRoot.CFrame * CFrame.new(0.85, 0.30, -1.35) * recCF
    elseif self.viewMode == "Gun3D" then
        baseCF = CFrame.new(self.anchorPos + Vector3.new(0, 2.65, 0)) * CFrame.Angles(0, math.rad(-90), 0) * recCF
    else
        local hipOff = cfg.HipOffset or CFrame.new(0.60, -0.55, -1.35)
        local aimOff = (cfg.Optics and cfg.Optics.Offset) or CFrame.new(0, -0.42, -1.15)
        local offset = self.isADS and aimOff or hipOff
        baseCF = self.eyeCF * offset * recCF
    end

    local finalRootCF = baseCF * extraGunCF * gAnim
    local leftArmRootCF = baseCF * extraGunCF * extraLeftCF * (gAnim:Lerp(CFrame.identity, detachAlpha) * lAnim)
    self.gunRoot.CFrame = finalRootCF

    if self.muzzleFlashTimer > 0 then
        self.muzzleFlashTimer = math.max(0, self.muzzleFlashTimer - dtScaled)
    end
    local flashVisible = self.muzzleFlashTimer > 0
    for _, mp in ipairs(self.muzzleFlashParts) do
        if mp and mp.Parent then
            mp.Transparency = flashVisible and 0.12 or 1
        end
    end
    if self.flashLight then
        self.flashLight.Brightness = flashVisible and 3.0 or 0
    end

    for part, relCF in pairs(self.parts) do
        if part and part.Parent then
            if self.leftArmParts[part] then
                part.CFrame = leftArmRootCF * relCF
            elseif self.animGroups.ReloadOnly[part] then
                part.Transparency = showReloadOnly and (self.baseTransparency[part] or 0) or 1
                part.CFrame = finalRootCF * magCF * relCF
            elseif self.animGroups.Magazine[part] then
                part.Transparency = showMag and (self.baseTransparency[part] or 0) or 1
                part.CFrame = finalRootCF * magCF * relCF
            elseif self.animGroups.Bolt[part] then
                part.CFrame = finalRootCF * boltCF * relCF
            elseif self.animGroups.Pump[part] then
                part.CFrame = finalRootCF * pumpCF * relCF
            elseif self.animGroups.Cylinder[part] then
                part.CFrame = finalRootCF * cylCF * relCF
            elseif part.Name:match("MuzzleFlashFlame") then
                part.CFrame = finalRootCF * relCF * CFrame.Angles(0, 0, math.rad(self.muzzleRoll))
            else
                part.CFrame = finalRootCF * relCF
            end
        end
    end

    if self.viewMode == "Gun3D" then
        return (finalRootCF * self.gunCenterLocalOffset).Position
    end
    return finalRootCF.Position
end

return WeaponPreviewController
