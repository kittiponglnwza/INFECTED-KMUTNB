--[[
    ZombieAudioController.lua
    Individual 3D spatial sound engine for INFECTED-KMUTNB zombies.
    Uses only 2 persistent Sound instances per zombie (VocalChannel on Head +
    FootstepChannel on HumanoidRootPart) to prevent instance churn across waves.

    Supported Events:
      - Idle         (breathing / groaning)
      - Walking      (dragging / slow footsteps)
      - Running      (faster hurried footsteps)
      - Chasing      (aggressive growling / screams / boss roars)
      - Attacking    (melee lunge vocalization)
      - TakingDamage (pain reaction)
      - Death        (final death vocalization)

    Asset Policy:
      - Populates custom SoundIds from ZombieCatalog CustomSoundIds when provided.
      - Never invents rbxassetid:// IDs; relies on verified engine sounds under
        rbxasset://sounds/ shaped with Distortion / EQ / Reverb sound effects.
]]

local ZombieAudioController = {}
ZombieAudioController.__index = ZombieAudioController

-- Verified local Roblox engine audio assets (zero external unverified IDs)
local ENGINE_SOUNDS = {
    GROAN = "rbxasset://sounds/ouch.ogg",
    SHRIEK = "rbxasset://sounds/action_falling.ogg",
    STEP = "rbxasset://sounds/action_footsteps_plastic.mp3",
    DRAG = "rbxasset://sounds/action_get_up.mp3",
    HEAVY_THUD = "rbxasset://sounds/action_jump_land.mp3",
    SWIPE = "rbxasset://sounds/action_swim.mp3",
    BOOM = "rbxasset://sounds/impact_explosion_03.mp3",
}

local VOCAL_PRIORITY = {
    Idle = 1,
    Chasing = 2,
    TakingDamage = 3,
    Attacking = 4,
    Death = 5,
}

local VOCAL_COOLDOWNS = {
    Idle = 3.2,
    Chasing = 1.6,
    TakingDamage = 0.28,
    Attacking = 0.65,
    Death = 0,
}

-- Global concurrency guard so 25+ zombies cannot distort or spam simultaneously
local MAX_GLOBAL_CONCURRENT_VOCALS = 10
local activeVocalSlots = {}

local function pickRange(rangeTbl)
    return rangeTbl[1] + math.random() * (rangeTbl[2] - rangeTbl[1])
end

local function pickValidCustomId(list)
    if type(list) ~= "table" or #list == 0 then
        return nil
    end
    local valid = {}
    for _, id in ipairs(list) do
        if type(id) == "string" and #id > 0 and string.find(id, "^rbxassetid://%d+$") then
            table.insert(valid, id)
        end
    end
    if #valid == 0 then
        return nil
    end
    return valid[math.random(1, #valid)]
end

local function canClaimGlobalVocalSlot(now, priority)
    for i = #activeVocalSlots, 1, -1 do
        if activeVocalSlots[i] <= now then
            table.remove(activeVocalSlots, i)
        end
    end
    if #activeVocalSlots < MAX_GLOBAL_CONCURRENT_VOCALS then
        table.insert(activeVocalSlots, now + 0.85)
        return true
    end
    -- Death and Attacking always bypass quiet ambient cap
    if priority >= VOCAL_PRIORITY.Attacking then
        table.insert(activeVocalSlots, now + 0.85)
        return true
    end
    return false
end

function ZombieAudioController.new(rig, archetype)
    local profile = archetype.AudioProfile

    local vocalSound = Instance.new("Sound")
    vocalSound.Name = "ZombieVocalChannel"
    vocalSound.RollOffMode = Enum.RollOffMode.InverseTapered
    vocalSound.RollOffMinDistance = profile.RollOffMin or 6
    vocalSound.RollOffMaxDistance = profile.RollOffMax or 56
    vocalSound.Volume = profile.BaseVolume or 0.44
    vocalSound.Looped = false
    vocalSound.Parent = rig.head

    local dist = Instance.new("DistortionSoundEffect")
    dist.Name = "VocalDistortion"
    dist.Level = profile.DistortionLevel or 0.55
    dist.Parent = vocalSound

    local eq = Instance.new("EqualizerSoundEffect")
    eq.Name = "VocalEQ"
    eq.LowGain = profile.EqLowGain or 0
    eq.MidGain = profile.EqMidGain or 0
    eq.HighGain = profile.EqHighGain or 0
    eq.Parent = vocalSound

    local reverb = Instance.new("ReverbSoundEffect")
    reverb.Name = "VocalReverb"
    reverb.WetLevel = profile.ReverbWet or -22
    reverb.DryLevel = 0
    reverb.Parent = vocalSound

    local stepSound = Instance.new("Sound")
    stepSound.Name = "ZombieFootstepChannel"
    stepSound.RollOffMode = Enum.RollOffMode.InverseTapered
    stepSound.RollOffMinDistance = 4
    stepSound.RollOffMaxDistance = profile.StepRollOffMax or 38
    stepSound.Volume = archetype.IsBoss and 0.52 or 0.24
    stepSound.Looped = false
    stepSound.Parent = rig.hrp

    local self = setmetatable({
        model = rig.model,
        archetype = archetype,
        profile = profile,
        vocalSound = vocalSound,
        vocalDist = dist,
        stepSound = stepSound,
        currentVocalPriority = 0,
        vocalBusyUntil = 0,
        lastEventTimes = {},
        nextIdleAt = os.clock() + 0.6 + math.random() * 2.8,
        nextChaseAt = 0,
        nextStepAt = os.clock() + math.random() * 0.3,
        destroyed = false,
    }, ZombieAudioController)

    return self
end

function ZombieAudioController:_playVocal(eventName)
    if self.destroyed or not self.vocalSound or not self.vocalSound.Parent then
        return
    end
    local now = os.clock()
    local pri = VOCAL_PRIORITY[eventName] or 1
    local cd = VOCAL_COOLDOWNS[eventName] or 0.5
    local lastAt = self.lastEventTimes[eventName] or 0
    if (now - lastAt) < cd then
        return
    end
    if now < self.vocalBusyUntil and pri <= self.currentVocalPriority then
        return
    end
    if not canClaimGlobalVocalSlot(now, pri) then
        return
    end

    local p = self.profile
    local customId = pickValidCustomId(p.CustomSoundIds and p.CustomSoundIds[eventName])
    local soundId = customId
    local pitch = pickRange(p.PitchRange)
    local vol = p.BaseVolume
    local busyDur = 0.65

    if not customId then
        if eventName == "Idle" then
            soundId = (p.VocalClass == "Female" and math.random() < 0.45) and ENGINE_SOUNDS.SHRIEK or ENGINE_SOUNDS.GROAN
            pitch = pickRange(p.PitchRange) * 0.92
            vol = p.BaseVolume * 0.62
            busyDur = 0.85
        elseif eventName == "Chasing" then
            if p.VocalClass == "Female" then
                soundId = ENGINE_SOUNDS.SHRIEK
                pitch = pickRange(p.ScreechPitchRange)
                vol = p.BaseVolume * 1.05
            elseif p.VocalClass == "Boss" then
                soundId = (math.random() < 0.5) and ENGINE_SOUNDS.BOOM or ENGINE_SOUNDS.GROAN
                pitch = pickRange(p.PitchRange) * 0.88
                vol = p.BaseVolume * 1.25
            else
                soundId = (math.random() < 0.35) and ENGINE_SOUNDS.SHRIEK or ENGINE_SOUNDS.GROAN
                pitch = pickRange(p.ScreechPitchRange)
                vol = p.BaseVolume * 1.05
            end
            busyDur = 0.90
        elseif eventName == "Attacking" then
            if p.VocalClass == "Female" then
                soundId = ENGINE_SOUNDS.SHRIEK
                pitch = pickRange(p.ScreechPitchRange) * 1.12
            elseif p.VocalClass == "Boss" then
                soundId = ENGINE_SOUNDS.BOOM
                pitch = 0.48 + math.random() * 0.08
            else
                soundId = ENGINE_SOUNDS.GROAN
                pitch = pickRange(p.ScreechPitchRange) * 1.08
            end
            vol = p.BaseVolume * 1.30
            busyDur = 0.55
        elseif eventName == "TakingDamage" then
            soundId = (p.VocalClass == "Female") and ENGINE_SOUNDS.SHRIEK or ENGINE_SOUNDS.GROAN
            pitch = pickRange(p.PitchRange) * 1.24
            vol = p.BaseVolume * 0.92
            busyDur = 0.36
        elseif eventName == "Death" then
            if p.VocalClass == "Female" then
                soundId = ENGINE_SOUNDS.SHRIEK
                pitch = p.ScreechPitchRange[1] * 0.85
            elseif p.VocalClass == "Boss" then
                soundId = ENGINE_SOUNDS.BOOM
                pitch = 0.34
            else
                soundId = ENGINE_SOUNDS.GROAN
                pitch = p.PitchRange[1] * 0.72
            end
            vol = p.BaseVolume * 1.35
            busyDur = 1.10
        end
    end

    self.lastEventTimes[eventName] = now
    self.currentVocalPriority = pri
    self.vocalBusyUntil = now + busyDur

    self.vocalSound.SoundId = soundId
    self.vocalSound.PlaybackSpeed = math.clamp(pitch, 0.20, 3.0)
    self.vocalSound.Volume = math.clamp(vol, 0.05, 2.0)
    self.vocalSound:Play()
end

function ZombieAudioController:_playFootstep(eventName)
    if self.destroyed or not self.stepSound or not self.stepSound.Parent then
        return
    end
    local p = self.profile
    local customId = pickValidCustomId(p.CustomSoundIds and p.CustomSoundIds[eventName])
    if customId then
        self.stepSound.SoundId = customId
    elseif self.archetype.IsBoss then
        self.stepSound.SoundId = ENGINE_SOUNDS.HEAVY_THUD
    elseif eventName == "Walking" and math.random() < 0.35 then
        self.stepSound.SoundId = ENGINE_SOUNDS.DRAG
    else
        self.stepSound.SoundId = ENGINE_SOUNDS.STEP
    end

    local speedMul = (eventName == "Running") and 1.12 or 1.0
    self.stepSound.PlaybackSpeed = math.clamp(pickRange(p.StepPitchRange) * speedMul, 0.3, 2.2)
    self.stepSound.Volume = self.archetype.IsBoss and ((eventName == "Running") and 0.62 or 0.46)
        or ((eventName == "Running") and 0.28 or 0.20)
    self.stepSound:Play()
end

function ZombieAudioController:triggerEvent(eventName)
    if eventName == "Walking" or eventName == "Running" then
        self:_playFootstep(eventName)
    else
        self:_playVocal(eventName)
    end
end

function ZombieAudioController:update(now, horizSpeed, isChasing, isDead)
    if self.destroyed or isDead then
        return
    end
    local p = self.profile

    if horizSpeed < 1.2 then
        if now >= self.nextIdleAt then
            self:_playVocal("Idle")
            self.nextIdleAt = now + pickRange(p.IdleInterval)
        end
        return
    end

    -- Movement footsteps (Walking vs Running)
    local isRunning = isChasing or (horizSpeed >= self.archetype.WalkSpeed * 1.12)
    if now >= self.nextStepAt then
        local stepEvent = isRunning and "Running" or "Walking"
        self:_playFootstep(stepEvent)
        local interval = isRunning and p.StepIntervalRun or p.StepIntervalWalk
        self.nextStepAt = now + interval * (0.90 + math.random() * 0.20)
    end

    -- Chasing aggressive vocalizations vs normal wandering Idle groans
    if isChasing then
        if now >= self.nextChaseAt then
            self:_playVocal("Chasing")
            self.nextChaseAt = now + pickRange(p.ChaseInterval)
        end
    elseif now >= self.nextIdleAt then
        self:_playVocal("Idle")
        self.nextIdleAt = now + pickRange(p.IdleInterval)
    end
end

function ZombieAudioController:destroy()
    self.destroyed = true
    if self.vocalSound then
        pcall(function() self.vocalSound:Stop() end)
    end
    if self.stepSound then
        pcall(function() self.stepSound:Stop() end)
    end
end

return ZombieAudioController
