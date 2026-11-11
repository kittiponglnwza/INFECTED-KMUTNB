--[[
    CharacterPreviewController.lua
    Builds and manages an isolated clone of the player's R15 character (never
    touching the live gameplay avatar) or the custom KMUTNB 1P Tactical Arms.
    Reads only real runtime Animation instances from the spawned Animate script.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponsFolder = ReplicatedStorage:WaitForChild("Weapons", 10)
local KMUTNBArms = require(WeaponsFolder:WaitForChild("models"):WaitForChild("KMUTNBArms"))
local WeaponRegistry = require(WeaponsFolder:WaitForChild("WeaponRegistry"))

local CharacterPreviewController = {}
CharacterPreviewController.__index = CharacterPreviewController

CharacterPreviewController.ITEMS = {
    {
        id = "PlayerR15",
        name = "Player Character (R15)",
        typeLabel = "Roblox R15 Avatar Clone",
        heightStuds = "~5.0 - 5.2 studs",
        note = "Live clone of your active avatar appearance. Uses runtime Animate tracks (idle, walk, run, jump, fall, climb).",
    },
    {
        id = "KMUTNBArms",
        name = "KMUTNB Tactical 1P Arms",
        typeLabel = "First-Person Student Viewmodel Rig",
        heightStuds = "1P Shoulder-Wrist Rig",
        note = "Procedural KMUTNB uniform sleeves, half-finger gloves & watch rig paired with weapons in FPS view.",
    },
}

function CharacterPreviewController.createIsolatedPlayerClone(groundPos, facingDeg)
    local player = Players.LocalPlayer
    local char = player and player.Character
    local clone = nil

    if char and char:FindFirstChild("HumanoidRootPart") then
        local prevArch = char.Archivable
        char.Archivable = true
        local ok, cloned = pcall(function() return char:Clone() end)
        char.Archivable = prevArch
        if ok and cloned then
            clone = cloned
        end
    end

    if not clone then
        local ok, fallback = pcall(function()
            return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
        end)
        if ok and fallback then
            clone = fallback
        end
    end

    if not clone then return nil end

    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Tool")
            or d:IsA("ForceField") or d:IsA("BillboardGui") or d:IsA("Sound") then
            d:Destroy()
        elseif d:IsA("BasePart") then
            d.CanCollide = false
            d.CanQuery = false
            d.CanTouch = false
            d.Anchored = (d.Name == "HumanoidRootPart")
            d.Massless = (d.Name ~= "HumanoidRootPart")
        end
    end

    local hum = clone:FindFirstChildOfClass("Humanoid")
    local hrp = clone:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then
        clone:Destroy()
        return nil
    end

    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    hum.AutoRotate = false
    hum.PlatformStand = true
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local yCenter = groundPos.Y + (hrp.Size.Y * 0.5) + hum.HipHeight
    local baseCF = CFrame.new(groundPos.X, yCenter, groundPos.Z) * CFrame.Angles(0, math.rad(facingDeg or 180), 0)
    hrp.CFrame = baseCF
    clone.PrimaryPart = hrp
    return clone, hum, animator, hrp, baseCF
end

function CharacterPreviewController.collectPlayerAnimateTracks()
    local tracks = {}
    local char = Players.LocalPlayer and Players.LocalPlayer.Character
    local animate = char and char:FindFirstChild("Animate")
    if not animate then return tracks end

    for _, child in ipairs(animate:GetChildren()) do
        if child:IsA("StringValue") or child:IsA("Folder") then
            local animObj = child:FindFirstChildOfClass("Animation")
            if animObj and animObj.AnimationId ~= "" then
                tracks[string.lower(child.Name)] = {
                    animObj = animObj,
                    animId = animObj.AnimationId,
                }
            end
        end
    end
    return tracks
end

function CharacterPreviewController.new()
    return setmetatable({
        activeItem = nil,
        model = nil,
        humanoid = nil,
        animator = nil,
        hrp = nil,
        baseCF = nil,
        activeTrack = nil,
        armRigRoot = nil,
        animateTracks = {},
    }, CharacterPreviewController)
end

function CharacterPreviewController:clear()
    if self.activeTrack then
        pcall(function() self.activeTrack:Stop(0) end)
        self.activeTrack = nil
    end
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
    self.humanoid = nil
    self.animator = nil
    self.hrp = nil
    self.baseCF = nil
    self.armRigRoot = nil
end

function CharacterPreviewController:spawn(itemId, mountParent, groundPos)
    self:clear()
    self.activeItem = CharacterPreviewController.ITEMS[1]
    for _, item in ipairs(CharacterPreviewController.ITEMS) do
        if item.id == itemId then
            self.activeItem = item
            break
        end
    end

    if self.activeItem.id == "KMUTNBArms" then
        local rig = Instance.new("Model")
        rig.Name = "Preview_KMUTNBArms"
        rig.Parent = mountParent

        local root = Instance.new("Part")
        root.Name = "ArmsAnchor"
        root.Size = Vector3.new(0.2, 0.2, 0.2)
        root.Transparency = 1
        root.Anchored = true
        root.CanCollide = false
        root.CFrame = CFrame.new(groundPos.X, groundPos.Y + 2.4, groundPos.Z) * CFrame.Angles(0, math.rad(180), 0)
        root.Parent = rig

        local arms = KMUTNBArms.build(rig, WeaponRegistry.get("Vandal"))
        for part, relCF in pairs(arms) do
            part.CFrame = root.CFrame * relCF
        end

        self.model = rig
        self.armRigRoot = root
        return {
            focusPos = root.Position + Vector3.new(0, -0.1, 0),
            dist = 3.2,
            yaw = math.rad(205),
            pitch = math.rad(-14),
        }
    end

    local clone, hum, animator, hrp, baseCF = CharacterPreviewController.createIsolatedPlayerClone(groundPos, 180)
    if not clone then
        return {
            focusPos = groundPos + Vector3.new(0, 2.8, 0),
            dist = 7.8,
            yaw = math.rad(195),
            pitch = math.rad(-12),
        }
    end

    clone.Name = "Preview_PlayerR15"
    clone.Parent = mountParent
    self.model = clone
    self.humanoid = hum
    self.animator = animator
    self.hrp = hrp
    self.baseCF = baseCF
    self.animateTracks = CharacterPreviewController.collectPlayerAnimateTracks()

    -- Start cleanly in real Idle pose when available
    self:playTrack("idle", 1.0, true, false)

    return {
        focusPos = groundPos + Vector3.new(0, 2.8, 0),
        dist = 7.8,
        yaw = math.rad(195),
        pitch = math.rad(-12),
    }
end

function CharacterPreviewController:playTrack(animateKey, speed, loop, paused)
    if not self.animator then
        return false, "No Animator on current rig"
    end
    local entry = self.animateTracks[string.lower(animateKey or "idle")]
    if not entry then
        return false, "Missing Animate." .. tostring(animateKey) .. " AnimationId on avatar"
    end

    if self.activeTrack then
        pcall(function() self.activeTrack:Stop(0.14) end)
        self.activeTrack = nil
    end

    local ok, tr = pcall(function()
        return self.animator:LoadAnimation(entry.animObj)
    end)
    if not ok or not tr then
        return false, "Failed to load track"
    end

    tr.Looped = (loop ~= false) and (animateKey ~= "jump")
    tr:Play(0.14)
    tr:AdjustSpeed(paused and 0 or (speed or 1.0))
    self.activeTrack = tr
    return true, entry.animId
end

function CharacterPreviewController:setSpeedAndPaused(speed, paused)
    if self.activeTrack then
        self.activeTrack:AdjustSpeed(paused and 0 or (speed or 1.0))
    end
end

function CharacterPreviewController:restartTrack()
    if self.activeTrack then
        self.activeTrack.TimePosition = 0
        if not self.activeTrack.IsPlaying then
            self.activeTrack:Play(0.05)
        end
    end
end

function CharacterPreviewController:stopTrack()
    if self.activeTrack then
        pcall(function() self.activeTrack:Stop(0.1) end)
        self.activeTrack = nil
    end
end

function CharacterPreviewController:setTurntableYaw(yawRad)
    if self.hrp and self.baseCF then
        local pos = self.baseCF.Position
        self.hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(180) + yawRad, 0)
    end
end

function CharacterPreviewController:getMetadata()
    local item = self.activeItem or CharacterPreviewController.ITEMS[1]
    local trackList = {}
    for k, v in pairs(self.animateTracks) do
        table.insert(trackList, k .. " (" .. v.animId .. ")")
    end
    table.sort(trackList)
    local tracksText = (#trackList > 0) and table.concat(trackList, "\n") or "No runtime Animate tracks detected yet"

    return {
        title = item.name,
        subtitle = item.typeLabel .. "  •  Height: " .. item.heightStuds,
        details = item.note .. "\n\nDetected Animate Tracks:\n" .. tracksText,
    }
end

return CharacterPreviewController
