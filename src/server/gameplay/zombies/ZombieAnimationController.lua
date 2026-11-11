--[[
    ZombieAnimationController.lua
    8-state R15 animation controller for INFECTED-KMUTNB zombies.
    States:
      1. Idle
      2. Walking
      3. Running
      4. Chasing
      5. Attacking
      6. TakingDamage
      7. Stunned
      8. Death

    Supports:
      - Smooth CFrame damping across all 15 R15 Motor6D joints
      - Strict priority arbitration so incompatible states never fight
      - Distinct animation styles for Male, Female, and Male Boss
      - Optional Roblox Animator AnimationTrack playback whenever real AnimationIds
        are configured in ZombieCatalog.lua (zero invented asset IDs).
]]

local RunService = game:GetService("RunService")

local ZombieAnimationController = {}
ZombieAnimationController.__index = ZombieAnimationController

local STATE_PRIORITY = {
    Idle = 1,
    Walking = 2,
    Running = 3,
    Chasing = 4,
    TakingDamage = 5,
    Stunned = 6,
    Attacking = 7,
    Death = 8,
}

local VALID_STATES = {
    Idle = true,
    Walking = true,
    Running = true,
    Chasing = true,
    Attacking = true,
    TakingDamage = true,
    Stunned = true,
    Death = true,
}

local activeControllers = {}
local heartbeatConnection = nil

local function rotCF(rx, ry, rz)
    return CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

local function isValidAssetId(id)
    return type(id) == "string" and #id > 0 and string.find(id, "^rbxassetid://%d+$") ~= nil
end

local function computePoseOffsets(ctrl, now, dt, horizSpeed, moveRatio)
    local profile = ctrl.profile
    local category = profile.category
    local isBoss = (category == "Boss")
    local isFemale = (category == "Female")

    ctrl.phase = ctrl.phase + dt * (1.8 + horizSpeed * 0.56)
    local p = ctrl.phase
    local seed = ctrl.seed
    local state = ctrl.state
    local stateElapsed = now - ctrl.stateStartedAt

    -- Target offset table keyed by Motor6D name
    local o = {}

    -- Head twitch common unsettling element (stronger & sharper on Female, slow heavy on Boss)
    local twitchPeriod = isFemale and 2.6 or (isBoss and 5.2 or 3.6)
    local twitchCycle = (now * profile.headTwitchRate + seed) % twitchPeriod
    local twitchAmp = isFemale and 24 or (isBoss and 10 or 18)
    local headSpasm = (twitchCycle < 0.14) and math.sin(twitchCycle * 48) * twitchAmp or 0
    local idleNod = math.sin(now * 1.9 + seed) * (isBoss and 3 or 5)
    local idleTilt = math.cos(now * 1.35 + seed) * (isFemale and 10 or 6) + headSpasm

    if state == "Death" then
        local a = math.clamp((now - ctrl.deathTime) / (isBoss and 0.55 or 0.34), 0, 1)
        local e = 1 - (1 - a) * (1 - a)
        local s = ctrl.archetype.TargetHeight / 5.15
        local fs = ctrl.fallSide

        o.Root = CFrame.new(0, -1.95 * s * e, 0.55 * s * e) * rotCF(-84 * e, 0, fs * 16 * e)
        o.Waist = rotCF(-12 * e, fs * 8 * e, fs * 6 * e)
        o.Neck = rotCF(-24 * e, fs * 14 * e, fs * 18 * e)
        o.LeftShoulder = rotCF(22 * e, 0, -56 * e)
        o.RightShoulder = rotCF(14 * e, 0, 52 * e)
        o.LeftElbow = rotCF(24 * e, 0, 0)
        o.RightElbow = rotCF(18 * e, 0, 0)
        o.LeftHip = rotCF(-12 * e, 0, -12 * e)
        o.RightHip = rotCF(-8 * e, 0, 14 * e)
        o.LeftKnee = rotCF(-18 * e, 0, 0)
        o.RightKnee = rotCF(-12 * e, 0, 0)
        return o, 14
    end

    if state == "Attacking" then
        local dur = isBoss and 0.72 or 0.50
        local t = math.clamp(stateElapsed / dur, 0, 1)

        if isBoss then
            -- Heavy brutal right-claw cleave with waist twist
            if t < 0.35 then
                local w = t / 0.35
                o.Root = CFrame.new(0, -0.22 * w, 0) * rotCF(-6 + 18 * w, -22 * w, -6 * w)
                o.Waist = rotCF(14 * w, -24 * w, -8 * w)
                o.Neck = rotCF(-10 * w, 18 * w, 6)
                o.RightShoulder = rotCF(132 * w + 24, -18 * w, 26 * w)
                o.RightElbow = rotCF(55 * w, 0, 0)
                o.LeftShoulder = rotCF(28, 0, -24 * w)
                o.LeftElbow = rotCF(36, 0, 0)
            elseif t < 0.65 then
                local s = (t - 0.35) / 0.30
                o.Root = CFrame.new(0, -0.30 * (1 - s * 0.5), -0.35 * s) * rotCF(-24 * s, 26 * s, 8 * s)
                o.Waist = rotCF(14 - 38 * s, -24 + 48 * s, 10 * s)
                o.Neck = rotCF(-18 * s, -16 * s, -8)
                o.RightShoulder = rotCF(156 - 122 * s, 22 * s, 10)
                o.RightElbow = rotCF(55 - 32 * s, 0, 0)
                o.LeftShoulder = rotCF(42, 0, -18)
                o.LeftElbow = rotCF(45, 0, 0)
            else
                local r = (t - 0.65) / 0.35
                local inv = 1 - r
                o.Root = rotCF(-18 * inv, 14 * inv, 0)
                o.Waist = rotCF(-18 * inv, 16 * inv, 0)
                o.Neck = rotCF(-8 * inv, 0, idleTilt * r)
                o.RightShoulder = rotCF(34 + 20 * r, 0, 12)
                o.RightElbow = rotCF(24 + 14 * r, 0, 0)
                o.LeftShoulder = rotCF(34, 0, -14)
                o.LeftElbow = rotCF(36, 0, 0)
            end
            o.LeftHip = rotCF(math.sin(p) * 14 * moveRatio + 8, 0, -6)
            o.RightHip = rotCF(-math.sin(p) * 14 * moveRatio - 12, 0, 6)
            o.LeftKnee = rotCF(-18, 0, 0)
            o.RightKnee = rotCF(-24, 0, 0)
            return o, 24
        else
            -- Twin zombie claw lunge / rake
            local armBias = isFemale and 1.15 or 1.0
            if t < 0.28 then
                local w = t / 0.28
                o.Waist = rotCF(12 * w, 0, 0)
                o.Neck = rotCF(8 * w, 0, idleTilt)
                o.LeftShoulder = rotCF((62 + 54 * w) * armBias, 0, -16 * w)
                o.RightShoulder = rotCF((62 + 54 * w) * armBias, 0, 16 * w)
                o.LeftElbow = rotCF(54 * w, 0, 0)
                o.RightElbow = rotCF(54 * w, 0, 0)
            elseif t < 0.62 then
                local s = (t - 0.28) / 0.34
                o.Waist = rotCF(12 - 34 * s, isFemale and 12 * math.sin(s * 3.14) or 0, 0)
                o.Neck = rotCF(-16 * s, 0, 0)
                o.LeftShoulder = rotCF((116 - 88 * s) * armBias, 0, -8)
                o.RightShoulder = rotCF((116 - 88 * s) * armBias, 0, 8)
                o.LeftElbow = rotCF(54 - 36 * s, 0, 0)
                o.RightElbow = rotCF(54 - 36 * s, 0, 0)
            else
                local r = (t - 0.62) / 0.38
                local inv = 1 - r
                o.Waist = rotCF(-20 * inv, 0, 0)
                o.LeftShoulder = rotCF(30 + 28 * r, 0, -8)
                o.RightShoulder = rotCF(30 + 28 * r, 0, 8)
                o.LeftElbow = rotCF(24, 0, 0)
                o.RightElbow = rotCF(24, 0, 0)
            end
            o.LeftWrist = rotCF(-22, 0, 0)
            o.RightWrist = rotCF(-22, 0, 0)
            o.LeftHip = rotCF(math.sin(p) * 18 * moveRatio, 0, 0)
            o.RightHip = rotCF(-math.sin(p) * 18 * moveRatio, 0, 0)
            return o, 24
        end
    end

    if state == "Stunned" then
        local wobble = math.sin(now * 16 + seed)
        local droop = isBoss and 14 or 22
        o.Root = CFrame.new(0, -0.18, 0.14) * rotCF(10, wobble * 8, wobble * 7)
        o.Waist = rotCF(-8 + wobble * 6, wobble * -10, wobble * 6)
        o.Neck = rotCF(-droop, wobble * 16, 16)
        o.LeftShoulder = rotCF(24, 0, -32 + wobble * 10)
        o.RightShoulder = rotCF(20, 0, 34 - wobble * 10)
        o.LeftElbow = rotCF(48, 0, 0)
        o.RightElbow = rotCF(48, 0, 0)
        o.LeftHip = rotCF(18, 0, -8)
        o.RightHip = rotCF(10, 0, 8)
        o.LeftKnee = rotCF(-34, 0, 0)
        o.RightKnee = rotCF(-28, 0, 0)
        return o, 18
    end

    if state == "TakingDamage" then
        local a = math.clamp(stateElapsed / 0.24, 0, 1)
        local snap = math.sin(a * math.pi)
        local headMul = ctrl.lastHitHeadshot and 2.1 or 1.0
        local dir = ctrl.fallSide

        o.Root = rotCF(10 * snap, dir * 8 * snap, 0)
        o.Waist = rotCF(16 * snap, dir * 10 * snap, dir * 8 * snap)
        o.Neck = rotCF(26 * snap * headMul, dir * 14 * snap, dir * 20 * snap * headMul)
        o.LeftShoulder = rotCF(36 + 22 * snap, 0, -20 * snap)
        o.RightShoulder = rotCF(36 + 18 * snap, 0, 22 * snap)
        o.LeftElbow = rotCF(44 * snap, 0, 0)
        o.RightElbow = rotCF(44 * snap, 0, 0)
        o.LeftKnee = rotCF(-20 * snap, 0, 0)
        o.RightKnee = rotCF(-20 * snap, 0, 0)
        return o, 26
    end

    -- Locomotion & Idle states: Idle, Walking, Running, Chasing
    local archHunch = math.deg(profile.hunchRad)
    if state == "Idle" then
        local breath = math.sin(now * (isBoss and 1.6 or 2.4) + seed)
        local torsoHunch = archHunch * 0.65 + breath * 2.2
        local sway = math.sin(now * 1.1 + seed) * (isFemale and 4 or 2.5)

        o.Root = CFrame.new(0, breath * 0.03, 0) * rotCF(torsoHunch * 0.4, sway * 0.5, sway)
        o.Waist = rotCF(torsoHunch * 0.6, math.sin(now * 0.8 + seed) * 3, 0)
        o.Neck = rotCF(-torsoHunch * 0.5 + idleNod, 0, idleTilt)
        if isBoss then
            o.LeftShoulder = rotCF(14 + breath * 3, 0, -10)
            o.RightShoulder = rotCF(24 + breath * 4, 0, 14)
            o.LeftElbow = rotCF(28, 0, 0)
            o.RightElbow = rotCF(44 + breath * 5, 0, 0)
        else
            o.LeftShoulder = rotCF(20 + breath * 3, 0, -8)
            o.RightShoulder = rotCF(26 - breath * 2, 0, 8)
            o.LeftElbow = rotCF(26, 0, 0)
            o.RightElbow = rotCF(32, 0, 0)
        end
        o.LeftWrist = rotCF(-12, 0, 0)
        o.RightWrist = rotCF(-14, 0, 0)
        o.LeftHip = rotCF(4, 0, -3)
        o.RightHip = rotCF(-3, 0, 3)
        o.LeftKnee = rotCF(-8, 0, 0)
        o.RightKnee = rotCF(-6, 0, 0)
        return o, 9
    end

    -- Walking / Running / Chasing (differentiated by category!)
    local isChasing = (state == "Chasing")
    local isRunning = (state == "Running" or isChasing)
    local strideGain = isChasing and 1.25 or (isRunning and 1.12 or 0.88)
    local leanMul = isChasing and 1.38 or (isRunning and 1.18 or 0.90)
    local m = math.max(0.25, moveRatio)

    -- Irregular dragging limp: right leg drags slightly behind with asymmetrical phase
    local stepSin = math.sin(p)
    local limpRight = (not isRunning) and (math.sin(p + 0.32) * 0.78) or (-stepSin)
    local leftStride = stepSin * profile.strideDeg * strideGain * m
    local rightStride = (not isRunning and (-stepSin * 0.74 + limpRight * 0.22) or (-stepSin)) * profile.strideDeg * strideGain * m

    local kneeBendBase = profile.kneeBendDeg
    local leftKnee = -math.max(4, (math.cos(p) * 0.5 + 0.5) * kneeBendBase * m)
    local rightKnee = -math.max(4, ((-math.cos(p)) * 0.5 + 0.5) * kneeBendBase * (not isRunning and 0.72 or 1.0) * m)

    local sScale = ctrl.archetype.TargetHeight / 5.15
    local bob = math.abs(math.cos(p)) * (isBoss and 0.14 or 0.10) * sScale * m
    local bodyTwist = math.cos(p) * (isBoss and 11 or 7) * m
    local bodyRoll = math.sin(p) * profile.swayDeg * (not isRunning and 1.15 or 0.8) * m
    local forwardHunch = archHunch * leanMul

    local reachBase = profile.armReachDeg + (isChasing and 26 or (isRunning and 14 or 4))
    local armSwing = math.cos(p) * (isRunning and 22 or 12) * m

    o.Root = CFrame.new(0, bob - 0.04 * sScale, 0) * rotCF(forwardHunch * 0.45, bodyTwist * 0.35, bodyRoll)
    o.Waist = rotCF(forwardHunch * 0.65, bodyTwist * 0.65, isFemale and (math.sin(p) * 5) or 0)
    o.Neck = rotCF(-forwardHunch * 0.70 + idleNod, -bodyTwist * 0.3, idleTilt)

    if isBoss then
        o.LeftShoulder = rotCF(reachBase * 0.72 + armSwing, 0, -12)
        o.RightShoulder = rotCF(reachBase * 0.95 - armSwing * 0.7, 0, 16)
        o.LeftElbow = rotCF(36, 0, 0)
        o.RightElbow = rotCF(48 + (isChasing and 12 or 0), 0, 0)
    else
        o.LeftShoulder = rotCF(reachBase + armSwing, 0, isFemale and -10 or -7)
        o.RightShoulder = rotCF(reachBase * 0.94 - armSwing * 0.85, 0, isFemale and 10 or 7)
        o.LeftElbow = rotCF(isChasing and 24 or 32, 0, 0)
        o.RightElbow = rotCF(isChasing and 28 or 36, 0, 0)
    end

    o.LeftWrist = rotCF(isChasing and -24 or -14, 0, isFemale and 8 or 0)
    o.RightWrist = rotCF(isChasing and -24 or -14, 0, isFemale and -8 or 0)

    o.LeftHip = rotCF(leftStride, 0, isFemale and 2 or -3)
    o.RightHip = rotCF(rightStride, 0, isFemale and -2 or 3)
    o.LeftKnee = rotCF(leftKnee, 0, 0)
    o.RightKnee = rotCF(rightKnee, 0, 0)
    o.LeftAnkle = rotCF(-leftKnee * 0.45, 0, 0)
    o.RightAnkle = rotCF(-rightKnee * 0.45, 0, 0)

    return o, isChasing and 18 or 14
end

function ZombieAnimationController.new(rig, archetype)
    local self = setmetatable({
        model = rig.model,
        hrp = rig.hrp,
        humanoid = rig.humanoid,
        animator = rig.animator,
        archetype = archetype,
        profile = archetype.AnimationProfile,
        motors = rig.motors or {},
        baseC0s = rig.baseC0s or {},
        currentOffsets = {},
        tracks = {},
        activeTrackState = nil,
        state = "Idle",
        stateStartedAt = os.clock(),
        lockedUntil = 0,
        deathTime = nil,
        lastHitHeadshot = false,
        phase = math.random() * 6.28,
        seed = math.random() * 100,
        fallSide = (math.random(0, 1) == 0) and -1 or 1,
        destroyed = false,
    }, ZombieAnimationController)

    for name in pairs(self.motors) do
        self.currentOffsets[name] = CFrame.identity
    end

    -- Load optional Studio AnimationIds if provided in ZombieCatalog.lua
    if self.animator and self.profile.AnimationIds then
        for stateName, animId in pairs(self.profile.AnimationIds) do
            if isValidAssetId(animId) then
                local ok, track = pcall(function()
                    local anim = Instance.new("Animation")
                    anim.Name = archetype.Id .. "_" .. stateName
                    anim.AnimationId = animId
                    local loaded = self.animator:LoadAnimation(anim)
                    loaded.Looped = (stateName == "Idle" or stateName == "Walking" or stateName == "Running" or stateName == "Chasing")
                    return loaded
                end)
                if ok and track then
                    self.tracks[stateName] = track
                end
            end
        end
    end

    table.insert(activeControllers, self)
    if not heartbeatConnection then
        heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
            ZombieAnimationController._stepAll(dt)
        end)
    end

    return self
end

function ZombieAnimationController:setState(nextState, durationOverride, extra)
    if self.destroyed or not VALID_STATES[nextState] then
        return
    end
    local now = os.clock()
    if self.state == "Death" and nextState ~= "Death" then
        return
    end

    local nextPri = STATE_PRIORITY[nextState] or 1
    local curPri = STATE_PRIORITY[self.state] or 1
    if now < self.lockedUntil and nextPri < curPri then
        return
    end

    if nextState == self.state and (nextState == "Idle" or nextState == "Walking" or nextState == "Running" or nextState == "Chasing") then
        return
    end

    self.state = nextState
    self.stateStartedAt = now
    if extra and extra.isHeadshot ~= nil then
        self.lastHitHeadshot = extra.isHeadshot == true
    end
    if nextState == "Death" then
        self.deathTime = (extra and extra.deathTime) or now
        self.lockedUntil = math.huge
    elseif nextState == "Attacking" then
        self.lockedUntil = now + (durationOverride or (self.profile.category == "Boss" and 0.72 or 0.50))
    elseif nextState == "Stunned" then
        self.lockedUntil = now + (durationOverride or self.archetype.StunDuration or 0.70)
    elseif nextState == "TakingDamage" then
        self.lockedUntil = now + (durationOverride or 0.24)
    else
        self.lockedUntil = 0
    end

    -- Exclusively play AnimationTrack if a published asset exists for this state
    local desiredTrack = self.tracks[nextState]
    if self.activeTrackState and self.activeTrackState ~= nextState then
        local prevTrack = self.tracks[self.activeTrackState]
        if prevTrack and prevTrack.IsPlaying then
            prevTrack:Stop(0.16)
        end
        self.activeTrackState = nil
    end
    if desiredTrack and not desiredTrack.IsPlaying then
        desiredTrack:Play(0.16)
        self.activeTrackState = nextState
    end
end

function ZombieAnimationController:syncLocomotionState(horizSpeed, isChasing)
    if self.destroyed or self.state == "Death" then
        return
    end
    if os.clock() < self.lockedUntil then
        return
    end

    if horizSpeed < 1.2 then
        self:setState("Idle")
    elseif isChasing then
        self:setState("Chasing")
    elseif horizSpeed >= self.archetype.WalkSpeed * 1.12 then
        self:setState("Running")
    else
        self:setState("Walking")
    end
end

function ZombieAnimationController:resetToIdle()
    self.state = "Idle"
    self.deathTime = nil
    self.lockedUntil = 0
    self.lastHitHeadshot = false
    for stateName, track in pairs(self.tracks) do
        if track.IsPlaying then
            track:Stop(0.1)
        end
        self.activeTrackState = nil
        if stateName == "Idle" then
            track:Play(0.1)
            self.activeTrackState = "Idle"
        end
    end
end

function ZombieAnimationController:destroy()
    self.destroyed = true
    for _, track in pairs(self.tracks) do
        pcall(function()
            track:Stop(0)
        end)
    end
    table.clear(self.tracks)
end

function ZombieAnimationController:_step(now, dt)
    if self.destroyed or not self.model or not self.model.Parent or not self.hrp or not self.hrp.Parent then
        self.destroyed = true
        return false
    end

    if self.model:GetAttribute("IsDead") == true then
        if self.state ~= "Death" then
            self:setState("Death", nil, { deathTime = self.model:GetAttribute("DeathTime") or now })
        end
    else
        local stunnedUntil = self.model:GetAttribute("StunnedUntil") or 0
        if now < stunnedUntil and self.state ~= "Stunned" and STATE_PRIORITY[self.state] < STATE_PRIORITY.Stunned then
            self:setState("Stunned", stunnedUntil - now)
        end
    end

    -- Auto-expire transient states cleanly
    if self.lockedUntil > 0 and now >= self.lockedUntil and self.state ~= "Death" then
        self.lockedUntil = 0
    end

    -- If a real studio AnimationTrack drives this state, let Roblox Animator control bones
    local activeTrack = self.activeTrackState and self.tracks[self.activeTrackState]
    if activeTrack and activeTrack.IsPlaying then
        return true
    end

    local vel = self.hrp.AssemblyLinearVelocity
    local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
    local moveRatio = math.clamp(horizSpeed / math.max(1, self.archetype.WalkSpeed), 0, 1.45)

    if self.lockedUntil == 0 and self.state ~= "Death" then
        self:syncLocomotionState(horizSpeed, self.model:GetAttribute("IsChasing") == true)
    end

    local targets, blendSpeed = computePoseOffsets(self, now, dt, horizSpeed, moveRatio)
    local alpha = 1 - math.exp(-(blendSpeed or 14) * math.min(dt, 0.1))

    for motorName, motor in pairs(self.motors) do
        local baseC0 = self.baseC0s[motorName]
        if baseC0 and motor.Parent then
            local targetOffset = targets[motorName] or CFrame.identity
            local prev = self.currentOffsets[motorName] or CFrame.identity
            local blended = prev:Lerp(targetOffset, alpha)
            self.currentOffsets[motorName] = blended
            motor.C0 = baseC0 * blended
        end
    end

    return true
end

function ZombieAnimationController._stepAll(dt)
    local now = os.clock()
    for i = #activeControllers, 1, -1 do
        local ctrl = activeControllers[i]
        if not ctrl:_step(now, dt) then
            table.remove(activeControllers, i)
        end
    end
end

return ZombieAnimationController
