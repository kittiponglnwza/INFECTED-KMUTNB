--[[
    ZombiePreviewController.lua
    Spawns and inspects any of the 5 actual INFECTED-KMUTNB zombie archetypes
    (MaleWalker, FemaleWalker, MaleRunner, FemaleRunner, MaleBoss) directly from
    ZombieCatalog & ZombieModelFactory, wired to ZombieAnimationController and
    ZombieAudioController with zero fake models or duplicate controllers.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZombieModules = ReplicatedStorage:WaitForChild("ZombieModules", 10)
local ZombieCatalog = require(ZombieModules:WaitForChild("ZombieCatalog"))
local ZombieModelFactory = require(ZombieModules:WaitForChild("ZombieModelFactory"))
local ZombieAnimationController = require(ZombieModules:WaitForChild("ZombieAnimationController"))
local ZombieAudioController = require(ZombieModules:WaitForChild("ZombieAudioController"))

local ZombiePreviewController = {}
ZombiePreviewController.__index = ZombiePreviewController

ZombiePreviewController.ARCHETYPE_ORDER = {
    "MaleWalker",
    "FemaleWalker",
    "MaleRunner",
    "FemaleRunner",
    "MaleBoss",
}

function ZombiePreviewController.getOrderedArchetypes()
    local list = {}
    for _, id in ipairs(ZombiePreviewController.ARCHETYPE_ORDER) do
        local arch = ZombieCatalog.ARCHETYPES[id]
        if arch then
            table.insert(list, arch)
        end
    end
    return list
end

function ZombiePreviewController.new()
    return setmetatable({
        activeId = nil,
        archetype = nil,
        rig = nil,
        animCtrl = nil,
        audioCtrl = nil,
        baseRootCF = nil,
    }, ZombiePreviewController)
end

function ZombiePreviewController:clear()
    if self.animCtrl then
        self.animCtrl:destroy()
        self.animCtrl = nil
    end
    if self.audioCtrl then
        self.audioCtrl:destroy()
        self.audioCtrl = nil
    end
    if self.rig and self.rig.model then
        self.rig.model:Destroy()
    end
    self.rig = nil
    self.archetype = nil
    self.activeId = nil
    self.baseRootCF = nil
end

function ZombiePreviewController:spawn(zombieId, mountParent, groundPos)
    self:clear()
    local arch = ZombieCatalog.get(zombieId)
    local rig = ZombieModelFactory.build({
        zombieType = arch.Id,
        groundPos = groundPos,
        facingDeg = 180,
        anchored = true,
        anchorRootOnly = true,
        canCollideMain = false,
        modelName = "ShowcasePreview_" .. arch.Id,
    })

    for _, d in ipairs(rig.model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.CanCollide = false
            d.CanTouch = false
            d.CanQuery = false
        end
    end
    rig.model.Parent = mountParent

    local animCtrl = ZombieAnimationController.new(rig, arch)
    animCtrl:setPreviewMode(true)
    animCtrl:setPreviewPlayback({
        state = "Idle",
        paused = false,
        speed = 1.0,
        loop = true,
    })

    local audioCtrl = ZombieAudioController.new(rig, arch)

    self.activeId = arch.Id
    self.archetype = arch
    self.rig = rig
    self.animCtrl = animCtrl
    self.audioCtrl = audioCtrl
    self.baseRootCF = rig.hrp and rig.hrp.CFrame or CFrame.new(groundPos)

    local height = arch.TargetHeight or 5.15
    return {
        focusPos = groundPos + Vector3.new(0, height * 0.54, 0),
        dist = arch.IsBoss and 12.8 or 7.8,
        yaw = math.rad(198),
        pitch = math.rad(-12),
    }
end

function ZombiePreviewController:setTurntableYaw(yawRad)
    if self.rig and self.rig.hrp and self.baseRootCF then
        local pos = self.baseRootCF.Position
        self.rig.hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(180) + yawRad, 0)
    end
end

function ZombiePreviewController:getMetadata()
    local arch = self.archetype
    if not arch then
        return { title = "Zombie", subtitle = "", details = "" }
    end

    local publishedCount = 0
    local animIds = arch.AnimationProfile and arch.AnimationProfile.AnimationIds or {}
    for _, stateName in ipairs(ZombieCatalog.ANIMATION_STATES) do
        local id = animIds[stateName]
        if type(id) == "string" and id ~= "" then
            publishedCount = publishedCount + 1
        end
    end

    local animSourceNote = (publishedCount > 0)
        and (string.format("%d/%d states use published AnimationIds", publishedCount, #ZombieCatalog.ANIMATION_STATES))
        or "0/8 published AnimationIds (All 8 states run real Procedural R15 Motor6D controller)"

    local details = string.format(
        "Archetype ID: %s\nCategory: %s  |  Gender: %s  |  Role: %s%s\nHeight: %.2f studs\nMax HP: %d  |  Damage: %d (Range %.1f st)\nWalkSpeed: %.1f  |  Run: %.1f  |  Chase: %.1f st/s\n\nAnimation Source:\n%s\n\nAudio Profile:\n3D %s Vocal + Footsteps (%s engine synthesis)",
        arch.Id,
        arch.Category or "-",
        arch.Gender or "-",
        arch.Role or "-",
        arch.IsBoss and "  [BOSS]" or "",
        arch.TargetHeight or 5.0,
        arch.MaxHealth or 100,
        arch.AttackDamage or 15,
        arch.AttackRange or 5.8,
        arch.WalkSpeed or 14,
        arch.RunSpeed or 16,
        arch.ChaseSpeed or 18,
        animSourceNote,
        arch.AudioProfile and arch.AudioProfile.VocalClass or arch.Category,
        arch.IsBoss and "Heavy Bass" or "Humanoid"
    )

    return {
        title = arch.DisplayName .. " (" .. arch.Id .. ")",
        subtitle = string.format("%s %s  •  %.2f studs  •  HP %d", arch.Gender, arch.Role, arch.TargetHeight, arch.MaxHealth),
        details = details,
    }
end

return ZombiePreviewController
