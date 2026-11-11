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

    -- 💥 1. OPERATOR / MARSHAL / OUTLAW: เสียงปืนสไนเปอร์คำรามก้องกังวาน
    if weaponConfig.IsSniper or wName == "OPERATOR" or wName == "OUTLAW" or wName == "MARSHAL" then
        playLayer(sndExplosion, 1.25, 1.6, 1.2) -- Sub-bass Thunder boom
        playLayer(sndThump, 1.80, 1.3, 0.8)     -- Heavy Body Thump
        playLayer(sndPlastic, 3.10, 0.95, 0.4)  -- High Supersonic Crack

        -- เสียงดึงคันรั้งลูกเลื่อนสไนเปอร์ (Bolt Action Cycle Click-Clack)
        if wName == "OPERATOR" or wName == "MARSHAL" then
            task.delay(0.28, function()
                playLayer(sndPlastic, 2.7, 0.75, 0.2)
            end)
            task.delay(0.55, function()
                playLayer(sndPlastic, 3.2, 0.80, 0.2)
            end)
        end
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

function WeaponAudio.playReloadStage(weaponConfig, stage)
    local isHeavy = weaponConfig and (weaponConfig.IsSniper or weaponConfig.Type == "Heavy" or weaponConfig.Type == "Shotgun")
    local isPistol = weaponConfig and (weaponConfig.Type == "Pistol" or weaponConfig.Type == "Revolver")

    if stage == "MagOut" then
        playLayer(sndPlastic, isPistol and 3.1 or 2.3, 0.55, 0.3)
        playLayer(sndSlice, isPistol and 2.6 or 1.9, 0.25, 0.25)
    elseif stage == "MagIn" then
        playLayer(sndThump, isPistol and 2.5 or 1.85, isHeavy and 0.9 or 0.7, 0.35)
        playLayer(sndPlastic, isPistol and 3.4 or 2.75, 0.75, 0.3)
    elseif stage == "BoltBack" then
        playLayer(sndPlastic, isPistol and 3.6 or 2.6, 0.65, 0.25)
        playLayer(sndSlap, 2.8, 0.35, 0.25)
    elseif stage == "BoltForward" then
        playLayer(sndPlastic, isPistol and 3.9 or 3.1, 0.80, 0.3)
        playLayer(sndThump, 2.3, 0.55, 0.25)
    elseif stage == "ShellIn" then
        playLayer(sndPlastic, 3.2, 0.65, 0.25)
        playLayer(sndThump, 2.7, 0.40, 0.2)
    elseif stage == "LatchOpen" then
        playLayer(sndPlastic, 3.4, 0.65, 0.25)
        playLayer(sndSlice, 2.4, 0.25, 0.25)
    elseif stage == "SnapShut" then
        playLayer(sndThump, 2.2, 0.85, 0.35)
        playLayer(sndPlastic, 3.3, 0.75, 0.3)
    end
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

-- ⚡ เสียงสไลด์สไตล์ Neon (Valorant High Gear Slide)
function WeaponAudio.playSlide()
    playLayer(sndThump, 1.55, 0.72, 0.35) -- Initial dash kick

    local surge = playLayer(sndSlice, 2.75, 0.85, 0.55) -- Electric air rush
    local eq = Instance.new("EqualizerSoundEffect")
    eq.HighGain = 6
    eq.MidGain = 3
    eq.LowGain = -4
    eq.Parent = surge

    playLayer(sndSlap, 0.76, 0.60, 0.50) -- Floor slide friction scrape
end

function WeaponAudio.playMeleeSwing()
    playLayer(sndSlice, 2.1, 0.65, 0.35)
    playLayer(sndSlap, 1.4, 0.35, 0.25)
end

function WeaponAudio.playEatOrDrink(isDrink)
    if isDrink then
        playLayer(sndSlice, 3.2, 0.45, 0.35)
        task.delay(0.14, function()
            playLayer(sndPlastic, 3.8, 0.35, 0.25)
        end)
    else
        playLayer(sndPlastic, 2.1, 0.45, 0.25)
        task.delay(0.16, function()
            playLayer(sndPlastic, 2.5, 0.40, 0.25)
        end)
    end
end

function WeaponAudio.playHeartbeat()
    playLayer(sndThump, 0.72, 0.52, 0.35)
    task.delay(0.24, function()
        playLayer(sndThump, 0.62, 0.38, 0.35)
    end)
end

function WeaponAudio.playHorrorCue(kind, worldPos)
    local template = (kind == "Footstep") and sndPlastic or ((kind == "Buzz") and sndSlice or sndThump)
    local pitch = (kind == "Footstep") and 0.92 or ((kind == "Buzz") and 0.45 or 0.32)
    local vol = (kind == "Buzz") and 0.22 or 0.28

    if typeof(worldPos) == "Vector3" then
        local anchor = Instance.new("Part")
        anchor.Name = "HorrorCueEmitter"
        anchor.Size = Vector3.new(0.2, 0.2, 0.2)
        anchor.Transparency = 1
        anchor.CanCollide = false
        anchor.CanQuery = false
        anchor.CanTouch = false
        anchor.Anchored = true
        anchor.CFrame = CFrame.new(worldPos)
        anchor.Parent = Workspace
        local s = template:Clone()
        s.PlaybackSpeed = pitch + (math.random() - 0.5) * 0.08
        s.Volume = vol
        s.RollOffMaxDistance = 85
        s.RollOffMinDistance = 8
        s.Parent = anchor
        s:Play()
        Debris:AddItem(anchor, 1.4)
    else
        playLayer(template, pitch, vol, 1.1)
    end
end

return WeaponAudio
