--[[
    AnimationPreviewController.lua
    Coordinates Animation Lab across Player, Zombie/Boss, and Weapon rigs,
    plus the isolated Movement Testing Mode (Walk/Run/Sprint/Chase transitions,
    turn cycles, adjustable playback speed, and calibration grid scroll).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZombieModules = ReplicatedStorage:WaitForChild("ZombieModules", 10)
local ZombieCatalog = require(ZombieModules:WaitForChild("ZombieCatalog"))

local WeaponPreviewController = require(script.Parent:WaitForChild("WeaponPreviewController"))

local AnimationPreviewController = {}
AnimationPreviewController.__index = AnimationPreviewController

AnimationPreviewController.PLAYER_CLIPS = {
    { id = "Idle", label = "Idle", animateKey = "idle", supported = true, note = "Runtime Animate.idle AnimationId from spawned R15 rig." },
    { id = "Walk", label = "Walk", animateKey = "walk", supported = true, note = "Runtime Animate.walk AnimationId from spawned R15 rig." },
    { id = "Run", label = "Run", animateKey = "run", supported = true, note = "Runtime Animate.run AnimationId from spawned R15 rig." },
    { id = "Sprint", label = "Sprint (Scaled Run)", animateKey = "run", speedMul = 1.35, supported = true, note = "FPS sprint uses WalkSpeed 24 + scaled Run track (no separate Sprint asset ID)." },
    { id = "Jump", label = "Jump", animateKey = "jump", supported = true, note = "Runtime Animate.jump AnimationId from spawned R15 rig." },
    { id = "Crouch", label = "Crouch", supported = false, note = "UNAVAILABLE: No Crouch system or AnimationId exists in repo (only Neon Slide)." },
}

AnimationPreviewController.ZOMBIE_CLIPS = {
    { id = "Idle", label = "Idle", supported = true, note = "Procedural R15 idle breathing & irregular head twitch." },
    { id = "Walking", label = "Walking", supported = true, note = "Procedural asymmetric dragging walk cycle." },
    { id = "Running", label = "Running", supported = true, note = "Procedural hunched sprint cycle." },
    { id = "Chasing", label = "Chasing", supported = true, note = "Aggressive pursuit stride with forward arms reach." },
    { id = "Attacking", label = "Attacking", supported = true, note = "Slash / Heavy Boss right-claw cleave strike." },
    { id = "TakingDamage", label = "TakingDamage", supported = true, note = "Impact flinch (supports Body vs Headshot Hit toggle)." },
    { id = "Stunned", label = "Stunned", supported = true, note = "Dazed wobble stagger loop." },
    { id = "Death", label = "Death", supported = true, note = "Knockdown collapse death pose." },
}

AnimationPreviewController.MOVEMENT_TURN_MODES = {
    { id = "Straight", label = "Straight Forward" },
    { id = "Slalom", label = "Direction Turns (+/-45°)" },
    { id = "Pivot180", label = "180° Pivot Turns" },
    { id = "AutoBlend", label = "Auto Walk -> Run -> Chase" },
}

function AnimationPreviewController.new(charCtrl, zombieCtrl, weaponCtrl)
    return setmetatable({
        charCtrl = charCtrl,
        zombieCtrl = zombieCtrl,
        weaponCtrl = weaponCtrl,

        domain = "Zombie",     -- "Player" | "Zombie" | "Weapon"
        targetId = "MaleWalker",
        clipId = "Idle",
        paused = false,
        stopped = false,
        speed = 1.0,
        loop = true,
        isHeadshot = false,
        statusNote = "Ready",

        -- Movement Preview Mode state
        movementEnabled = false,
        moveGait = "Walking",  -- "Idle" | "Walking" | "Running" | "Chasing" (or Player Walk/Run/Sprint)
        turnMode = "Straight",
        gridAngle = 0,
        rigYaw = 0,
        moveClock = 0,
        autoBlendPhase = 0,
    }, AnimationPreviewController)
end

function AnimationPreviewController:getAvailableClips()
    if self.domain == "Player" then
        return AnimationPreviewController.PLAYER_CLIPS
    elseif self.domain == "Zombie" then
        return AnimationPreviewController.ZOMBIE_CLIPS
    end
    return WeaponPreviewController.WEAPON_CLIPS
end

function AnimationPreviewController:spawnTarget(domain, targetId, mountParent, groundPos)
    self.charCtrl:clear()
    self.zombieCtrl:clear()
    self.weaponCtrl:clear()

    self.domain = domain or self.domain
    self.targetId = targetId or self.targetId
    self.paused = false
    self.stopped = false
    self.clipId = "Idle"
    self.rigYaw = 0
    self.moveClock = 0
    self.autoBlendPhase = 0

    if self.domain == "Player" then
        self.targetId = "PlayerR15"
        local camPreset = self.charCtrl:spawn("PlayerR15", mountParent, groundPos)
        self.statusNote = "Player R15 rig ready (runtime Animate tracks)."
        if self.movementEnabled then
            self:setMovementGait(self.moveGait)
        end
        return camPreset
    elseif self.domain == "Zombie" then
        local arch = ZombieCatalog.get(self.targetId)
        self.targetId = arch.Id
        local camPreset = self.zombieCtrl:spawn(arch.Id, mountParent, groundPos)
        self.statusNote = arch.DisplayName .. " ready (ZombieAnimationController)."
        if self.movementEnabled then
            self:setMovementGait(self.moveGait)
        end
        return camPreset
    end

    local viewMode = (self.weaponCtrl.viewMode == "Gun3D") and "Viewmodel1P" or self.weaponCtrl.viewMode
    local camPreset = self.weaponCtrl:spawn(self.targetId, viewMode, mountParent, groundPos)
    self.statusNote = self.weaponCtrl.weaponKey .. " Weapon Lab ready."
    return camPreset
end

function AnimationPreviewController:playClip(clipId, restart)
    self.clipId = clipId or self.clipId
    self.paused = false
    self.stopped = false

    if self.domain == "Zombie" then
        local ctrl = self.zombieCtrl.animCtrl
        if not ctrl then return end
        ctrl:setPreviewPlayback({
            state = self.clipId,
            paused = false,
            speed = self.speed,
            loop = self.loop,
            restart = (restart == true),
            isHeadshot = self.isHeadshot,
        })
        if self.zombieCtrl.audioCtrl and (self.clipId == "Attacking" or self.clipId == "TakingDamage" or self.clipId == "Death") then
            self.zombieCtrl.audioCtrl:triggerEvent(self.clipId)
        end
        self.statusNote = string.format("%s -> %s (%.2fx)", self.targetId, self.clipId, self.speed)
    elseif self.domain == "Player" then
        local def = nil
        for _, c in ipairs(AnimationPreviewController.PLAYER_CLIPS) do
            if c.id == self.clipId then def = c; break end
        end
        if not def or not def.supported then
            self.statusNote = def and def.note or "Animation unavailable."
            return
        end
        local effSpeed = self.speed * (def.speedMul or 1.0)
        local ok, info = self.charCtrl:playTrack(def.animateKey, effSpeed, self.loop, false)
        if restart then
            self.charCtrl:restartTrack()
        end
        self.statusNote = ok and (def.label .. " (" .. tostring(info) .. ")") or tostring(info)
    else
        self.weaponCtrl.speed = self.speed
        self.weaponCtrl.loop = self.loop
        self.weaponCtrl:playClip(self.clipId)
        self.statusNote = string.format("%s -> %s (%.2fx)", self.weaponCtrl.weaponKey, self.clipId, self.speed)
    end
end

function AnimationPreviewController:pause()
    self.paused = true
    if self.domain == "Zombie" and self.zombieCtrl.animCtrl then
        self.zombieCtrl.animCtrl:setPreviewPlayback({ paused = true })
    elseif self.domain == "Player" then
        self.charCtrl:setSpeedAndPaused(self.speed, true)
    elseif self.domain == "Weapon" then
        self.weaponCtrl.paused = true
    end
    self.statusNote = "Paused @ " .. self.clipId
end

function AnimationPreviewController:resumeOrPlay()
    if self.stopped then
        self:playClip(self.clipId, true)
        return
    end
    self.paused = false
    if self.domain == "Zombie" and self.zombieCtrl.animCtrl then
        self.zombieCtrl.animCtrl:setPreviewPlayback({ paused = false, speed = self.speed, loop = self.loop })
    elseif self.domain == "Player" then
        self.charCtrl:setSpeedAndPaused(self.speed, false)
    elseif self.domain == "Weapon" then
        self.weaponCtrl.paused = false
        self.weaponCtrl.speed = self.speed
    end
    self.statusNote = "Playing " .. self.clipId .. string.format(" (%.2fx)", self.speed)
end

function AnimationPreviewController:stop()
    self.stopped = true
    self.paused = true
    self.clipId = "Idle"
    if self.domain == "Zombie" and self.zombieCtrl.animCtrl then
        self.zombieCtrl.animCtrl:resetToIdle()
        self.zombieCtrl.animCtrl:setPreviewPlayback({ state = "Idle", paused = true, speed = 1.0, restart = true })
    elseif self.domain == "Player" then
        self.charCtrl:stopTrack()
        self.charCtrl:setTurntableYaw(0)
    elseif self.domain == "Weapon" then
        self.weaponCtrl:stop()
    end
    self.rigYaw = 0
    self.statusNote = "Stopped (Reset to Rest Pose)"
end

function AnimationPreviewController:restart()
    self:playClip(self.clipId, true)
end

function AnimationPreviewController:returnToIdle()
    self.movementEnabled = false
    self.rigYaw = 0
    self.charCtrl:setTurntableYaw(0)
    self.zombieCtrl:setTurntableYaw(0)
    self:playClip("Idle", true)
end

function AnimationPreviewController:setSpeed(spd)
    self.speed = math.clamp(spd, 0.25, 2.5)
    if self.domain == "Zombie" and self.zombieCtrl.animCtrl then
        self.zombieCtrl.animCtrl:setPreviewPlayback({ speed = self.speed })
    elseif self.domain == "Player" then
        local speedMul = (self.clipId == "Sprint") and 1.35 or 1.0
        self.charCtrl:setSpeedAndPaused(self.speed * speedMul, self.paused)
    elseif self.domain == "Weapon" then
        self.weaponCtrl.speed = self.speed
    end
end

function AnimationPreviewController:setLoop(enabled)
    self.loop = (enabled == true)
    if self.domain == "Zombie" and self.zombieCtrl.animCtrl then
        self.zombieCtrl.animCtrl:setPreviewPlayback({ loop = self.loop })
    elseif self.domain == "Weapon" then
        self.weaponCtrl.loop = self.loop
    end
end

function AnimationPreviewController:setMovementGait(gait)
    self.moveGait = gait
    if not self.movementEnabled then return end
    if self.domain == "Player" then
        local map = {
            Idle = "Idle",
            Walking = "Walk",
            Running = "Run",
            Chasing = "Sprint",
        }
        self:playClip(map[gait] or "Walk", false)
    elseif self.domain == "Zombie" then
        self:playClip(gait, false)
    end
end

function AnimationPreviewController:step(dt, stageHandle)
    if not self.movementEnabled or self.paused or self.stopped or self.domain == "Weapon" then
        return
    end

    local dtScaled = dt * self.speed
    self.moveClock = self.moveClock + dtScaled

    -- Auto Transition Blending sequence to expose blending/proportion issues
    if self.turnMode == "AutoBlend" then
        local seq = { "Idle", "Walking", "Running", "Chasing", "Walking", "Idle" }
        local segLen = 2.4
        local idx = (math.floor(self.moveClock / segLen) % #seq) + 1
        local desiredGait = seq[idx]
        if desiredGait ~= self.moveGait then
            self:setMovementGait(desiredGait)
        end
    end

    -- Simulated horizontal speed for floor calibration spokes
    local baseSpeed = 0
    if self.domain == "Zombie" and self.zombieCtrl.archetype then
        local a = self.zombieCtrl.archetype
        if self.moveGait == "Walking" then
            baseSpeed = a.WalkSpeed or 14
        elseif self.moveGait == "Running" then
            baseSpeed = a.RunSpeed or 17
        elseif self.moveGait == "Chasing" then
            baseSpeed = a.ChaseSpeed or 19
        end
    elseif self.domain == "Player" then
        if self.moveGait == "Walking" then
            baseSpeed = 16
        elseif self.moveGait == "Running" then
            baseSpeed = 20
        elseif self.moveGait == "Chasing" then
            baseSpeed = 24 -- FPS Sprint speed
        end
    end

    -- Direction change / turning modes
    local targetYaw = 0
    if self.turnMode == "Slalom" then
        targetYaw = math.sin(self.moveClock * 1.8) * math.rad(48)
    elseif self.turnMode == "Pivot180" then
        local flip = (math.floor(self.moveClock / 2.2) % 2 == 1) and math.pi or 0
        targetYaw = flip
    end
    local turnAlpha = 1 - math.exp(-dtScaled * 7)
    self.rigYaw = self.rigYaw + (targetYaw - self.rigYaw) * turnAlpha

    if self.domain == "Player" then
        self.charCtrl:setTurntableYaw(self.rigYaw)
    elseif self.domain == "Zombie" then
        self.zombieCtrl:setTurntableYaw(self.rigYaw)
    end

    if stageHandle and baseSpeed > 0 then
        -- Rotate calibration floor spokes in opposite visual angular pace (~4.6 stud radius)
        self.gridAngle = self.gridAngle + (baseSpeed / 4.6) * dtScaled * 0.45
        stageHandle.setCalibrationRotation(self.gridAngle)
    end
end

return AnimationPreviewController
