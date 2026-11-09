--[[
    WeaponAudio.lua
    โมดูลจัดการระบบเสียงปืนและมีด Valorant ทั้งหมด
    ใช้สถาปัตยกรรม Multi-Layered Sound Synthesis ระดับ Engine (rbxasset://)
    การันตีเสียงดัง ชัดเจน สมจริง ไม่ถูกบล็อกเรื่อง Audio Privacy 100%
]]

local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local WeaponAudio = {}
local camera = Workspace.CurrentCamera

local soundFolder = camera:FindFirstChild("ValorantWeaponSounds") or Instance.new("Folder")
soundFolder.Name = "ValorantWeaponSounds"
soundFolder.Parent = camera

local function createSound(id, name)
    local s = Instance.new("Sound")
    s.Name = name
    s.SoundId = "rbxasset://sounds/" .. id
    s.Parent = soundFolder
    return s
end

local sndExplosion = createSound("impact_explosion_03.mp3", "ExplosionBase")
local sndPlastic = createSound("action_footsteps_plastic.mp3", "PlasticSnapBase")
local sndSlap = createSound("action_get_up.mp3", "MuzzleSlapBase")
local sndThump = createSound("action_jump_land.mp3", "BassThumpBase")
local sndSlice = createSound("action_swim.mp3", "BladeWhooshBase")

local function playLayer(template, pitch, volume, lifetime)
    local s = template:Clone()
    s.PlaybackSpeed = pitch + (math.random() - 0.5) * 0.1
    s.Volume = volume
    s.Parent = camera
    s:Play()
    Debris:AddItem(s, lifetime or 0.6)
    return s
end

function WeaponAudio.playShot(weaponConfig)
    local wName = (weaponConfig.Name or ""):upper()
    local isSilenced = (weaponConfig.Audio and weaponConfig.Audio.Silenced) or false

    -- 💥 1. OPERATOR / OUTLAW: เสียงปืนสไนเปอร์หนัก .50 Cal คำรามก้องกังวาน
    if weaponConfig.IsSniper or wName == "OPERATOR" or wName == "OUTLAW" then
        playLayer(sndExplosion, 1.25, 1.6, 1.2) -- Sub-bass Thunder boom
        playLayer(sndThump, 1.80, 1.3, 0.8)     -- Heavy Body Thump
        playLayer(sndPlastic, 3.10, 0.95, 0.4)  -- High Supersonic Crack
        return
    end

    -- 🤫 2. PHANTOM / GHOST (Silenced): เสียงเก็บเสียงซับโซนิก ฟึ่บ-แป๊ะ แน่นๆ
    if isSilenced or wName == "PHANTOM" or wName == "GHOST" then
        playLayer(sndExplosion, 3.65, 0.55, 0.4) -- Subsonic Thud
        playLayer(sndPlastic, 3.50, 0.75, 0.3)   -- Carbon Baffle Snap
        return
    end

    -- 🔥 3. VANDAL: เสียง 7.62mm กระแทกหนัก คม แน่น สไตล์ Valorant Prime / Default
    if wName == "VANDAL" then
        playLayer(sndExplosion, 2.30, 1.30, 0.6) -- Punchy 7.62 Crack
        playLayer(sndPlastic, 2.80, 0.85, 0.4)   -- Metallic Bolt Slap
        playLayer(sndSlap, 3.70, 0.45, 0.3)      -- Gas Shroud Vent
        return
    end

    -- 💥 4. SHOTGUNS (Bucky, Judge, Shorty): เสียงลูกซอง 12 Gauge ระเบิดก้องกังวาน หนักแน่น สะใจ
    if weaponConfig.Type == "Shotgun" or wName == "BUCKY" or wName == "JUDGE" or wName == "SHORTY" then
        playLayer(sndExplosion, 1.45, 1.55, 0.8) -- 12-Gauge Heavy Powder Boom
        playLayer(sndThump, 1.65, 1.40, 0.6)     -- Deep Chest Thump
        playLayer(sndPlastic, 2.40, 0.90, 0.4)   -- Muzzle Pressure Crack
        if wName == "BUCKY" then
            -- เสียงชักกระโจมมือปั๊มลูกซอง (Pump Action Clack)
            task.delay(0.20, function()
                playLayer(sndPlastic, 2.9, 0.70, 0.25)
            end)
            task.delay(0.36, function()
                playLayer(sndPlastic, 3.4, 0.75, 0.25)
            end)
        end
        return
    end

    -- 🔫 5. PISTOLS (Classic, Sheriff, Frenzy): เสียงปืนพกกระชับ แน่น
    if weaponConfig.Type == "Pistol" or weaponConfig.Type == "Revolver" or wName == "CLASSIC" or wName == "SHERIFF" then
        local pPitch = (wName == "SHERIFF") and 2.15 or 2.90
        local pVol = (wName == "SHERIFF") and 1.35 or 0.95
        playLayer(sndExplosion, pPitch, pVol, 0.5)
        playLayer(sndPlastic, 3.35, 0.65, 0.3)
        return
    end

    -- 🔫 5. ปืนอื่นๆ (Spectre, Bulldog, Guardian, Ares, Odin)
    local basePitch = (weaponConfig.Audio and weaponConfig.Audio.Pitch) or 2.4
    local baseVol = (weaponConfig.Audio and weaponConfig.Audio.Volume) or 1.15
    playLayer(sndExplosion, basePitch, baseVol, 0.5)
    playLayer(sndPlastic, basePitch + 0.5, 0.60, 0.3)
end

function WeaponAudio.playClick(speed)
    playLayer(sndPlastic, speed or 2.8, 0.6, 0.4)
end

-- 💥 เสียงยิงโดนซอมบี้ (Valorant Hit Confirm & Headshot DINK!)
function WeaponAudio.playHit(isHeadshot)
    if isHeadshot then
        playLayer(sndExplosion, 4.4, 0.9, 0.35)
        playLayer(sndPlastic, 4.2, 0.8, 0.3) -- เสียง "ดริ๊งก์!" ยิงหัวสะใจ
    else
        playLayer(sndExplosion, 3.2, 0.4, 0.3)
    end
end

return WeaponAudio
