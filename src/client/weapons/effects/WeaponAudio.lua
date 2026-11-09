--[[
    WeaponAudio.lua
    โมดูลจัดการระบบเสียงปืน Valorant ทั้งหมด
    ใช้เสียงระดับ Engine ของ Roblox (rbxasset://) เพื่อการันตีเสียงดังชัดเจน 100%
]]

local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local WeaponAudio = {}
local camera = Workspace.CurrentCamera

local soundFolder = camera:FindFirstChild("ValorantWeaponSounds") or Instance.new("Folder")
soundFolder.Name = "ValorantWeaponSounds"
soundFolder.Parent = camera

-- เสียงต้นแบบสำหรับโคลนใช้งาน
local templateGunshot = Instance.new("Sound")
templateGunshot.Name = "GunshotBase"
templateGunshot.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
templateGunshot.Parent = soundFolder

local templateClick = Instance.new("Sound")
templateClick.Name = "ClickBase"
templateClick.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
templateClick.Parent = soundFolder

function WeaponAudio.playShot(weaponConfig)
    local s = templateGunshot:Clone()
    local pitch = (weaponConfig.Audio and weaponConfig.Audio.Pitch) or 2.4
    local isSilenced = (weaponConfig.Audio and weaponConfig.Audio.Silenced) or false

    s.PlaybackSpeed = pitch + (math.random() - 0.5) * 0.15
    s.Volume = isSilenced and 0.55 or ((weaponConfig.Audio and weaponConfig.Audio.Volume) or 1.15)
    s.Parent = camera
    s:Play()
    Debris:AddItem(s, 0.6)
end

function WeaponAudio.playClick(speed)
    local c = templateClick:Clone()
    c.PlaybackSpeed = speed or 2.8
    c.Volume = 0.6
    c.Parent = camera
    c:Play()
    Debris:AddItem(c, 0.5)
end

function WeaponAudio.playHit(isHeadshot)
    local h = templateGunshot:Clone()
    h.Volume = isHeadshot and 0.85 or 0.35
    h.PlaybackSpeed = isHeadshot and 4.2 or 3.2
    h.Parent = camera
    h:Play()
    Debris:AddItem(h, 0.4)
end

return WeaponAudio
