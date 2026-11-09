--[[
    WeaponRegistry.lua
    คลังศูนย์กลางรวบรวมอาวุธทั้งหมดของโปรเจกต์
    - ดึง Config แยกไฟล์จากโฟลเดอร์ configs/ (Vandal, Phantom, Operator, Sheriff, Spectre, ฯลฯ)
    - รองรับการปรับแต่งสเปกปืนแต่ละกระบอกแบบแยกไฟล์โดยเฉพาะจุด
]]

local configsFolder = script.Parent:WaitForChild("configs", 10)

local WeaponRegistry = {}
local weapons = {}

-- 1. โหลดปืนที่มีไฟล์ Config แยกเป็นเอกเทศ (Gauntlet-Loop Safe Requiring)
local specificConfigs = { "Vandal", "Phantom", "Operator", "Sheriff", "Spectre", "Classic", "Bucky", "Judge" }
for _, name in ipairs(specificConfigs) do
    local mod = configsFolder and (configsFolder:WaitForChild(name, 5) or configsFolder:FindFirstChild(name))
    if mod and mod:IsA("ModuleScript") then
        local success, data = pcall(require, mod)
        if success and type(data) == "table" then
            weapons[name] = data
        else
            warn("[WeaponRegistry] Failed to require config: " .. name .. ", error: " .. tostring(data))
        end
    else
        warn("[WeaponRegistry] Config ModuleScript not found: " .. name)
    end
end

-- 2. ข้อมูลปืนกระบอกอื่นๆ ในคลังแสง Valorant
local extraWeapons = {
    Classic = {
        Name = "CLASSIC", Category = "Sidearms", Type = "Pistol", FiringType = "Semi",
        Mag = 12, Reserve = 120, FireRate = 0.15, Pellets = 1, HeadDmg = 78, BodyDmg = 26,
        Optics = { CanADS = true, ZoomFOV = 62, Offset = CFrame.new(0, -0.32, -0.95) },
        HipOffset = CFrame.new(0.45, -0.50, -1.15),
        Recoil = { KickZ = 0.30, PitchX = 3.0, YawY = 0.9, RecoverySpeed = 22 },
        Audio = { Pitch = 2.8, Volume = 1.0, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(40, 42, 48), AccentColor = Color3.fromRGB(180, 185, 195) }
    },
    Shorty = {
        Name = "SHORTY", Category = "Sidearms", Type = "Pistol", FiringType = "Shotgun",
        Mag = 2, Reserve = 40, FireRate = 0.30, Pellets = 10, HeadDmg = 36, BodyDmg = 12,
        Optics = { CanADS = false, ZoomFOV = 65, Offset = CFrame.new(0, -0.32, -0.95) },
        HipOffset = CFrame.new(0.45, -0.50, -1.15),
        Recoil = { KickZ = 0.55, PitchX = 5.8, YawY = 2.0, RecoverySpeed = 18 },
        Audio = { Pitch = 2.1, Volume = 1.3, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(60, 45, 35), AccentColor = Color3.fromRGB(30, 30, 35) }
    },
    Frenzy = {
        Name = "FRENZY", Category = "Sidearms", Type = "Pistol", FiringType = "Auto",
        Mag = 13, Reserve = 90, FireRate = 0.10, Pellets = 1, HeadDmg = 78, BodyDmg = 26,
        Optics = { CanADS = false, ZoomFOV = 65, Offset = CFrame.new(0, -0.32, -0.95) },
        HipOffset = CFrame.new(0.45, -0.50, -1.15),
        Recoil = { KickZ = 0.32, PitchX = 3.5, YawY = 1.4, RecoverySpeed = 22 },
        Audio = { Pitch = 2.9, Volume = 1.1, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(35, 38, 45), AccentColor = Color3.fromRGB(240, 180, 40) }
    },
    Ghost = {
        Name = "GHOST", Category = "Sidearms", Type = "Pistol", FiringType = "Semi",
        Mag = 15, Reserve = 90, FireRate = 0.15, Pellets = 1, HeadDmg = 105, BodyDmg = 30,
        Optics = { CanADS = true, ZoomFOV = 62, Offset = CFrame.new(0, -0.32, -0.95) },
        HipOffset = CFrame.new(0.45, -0.50, -1.15),
        Recoil = { KickZ = 0.28, PitchX = 2.8, YawY = 0.9, RecoverySpeed = 24 },
        Audio = { Pitch = 3.4, Volume = 0.65, Silenced = true },
        Visual = { PrimaryColor = Color3.fromRGB(28, 30, 35), AccentColor = Color3.fromRGB(80, 120, 150) }
    },
    Stinger = {
        Name = "STINGER", Category = "SMGs", Type = "SMG", FiringType = "Auto",
        Mag = 20, Reserve = 120, FireRate = 0.062, Pellets = 1, HeadDmg = 67, BodyDmg = 27,
        Optics = { CanADS = true, ZoomFOV = 58, Offset = CFrame.new(0, -0.40, -1.10) },
        HipOffset = CFrame.new(0.55, -0.52, -1.25),
        Recoil = { KickZ = 0.32, PitchX = 3.2, YawY = 1.4, RecoverySpeed = 24 },
        Audio = { Pitch = 2.9, Volume = 1.1, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(42, 45, 52), AccentColor = Color3.fromRGB(255, 120, 40) }
    },
    Bucky = {
        Name = "BUCKY", Category = "Shotguns", Type = "Shotgun", FiringType = "Shotgun",
        Mag = 8, Reserve = 60, FireRate = 0.70, Pellets = 15, HeadDmg = 40, BodyDmg = 20,
        Optics = { CanADS = true, ZoomFOV = 60, Offset = CFrame.new(0, -0.42, -1.15) },
        HipOffset = CFrame.new(0.60, -0.55, -1.35),
        Recoil = { KickZ = 0.75, PitchX = 8.0, YawY = 2.0, RecoverySpeed = 16 },
        Audio = { Pitch = 1.8, Volume = 1.4, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(50, 52, 58), AccentColor = Color3.fromRGB(130, 70, 30) }
    },
    Judge = {
        Name = "JUDGE", Category = "Shotguns", Type = "Shotgun", FiringType = "Auto",
        Mag = 7, Reserve = 60, FireRate = 0.28, Pellets = 12, HeadDmg = 34, BodyDmg = 17,
        Optics = { CanADS = true, ZoomFOV = 60, Offset = CFrame.new(0, -0.42, -1.15) },
        HipOffset = CFrame.new(0.60, -0.55, -1.35),
        Recoil = { KickZ = 0.65, PitchX = 6.5, YawY = 1.8, RecoverySpeed = 18 },
        Audio = { Pitch = 1.9, Volume = 1.35, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(40, 42, 46), AccentColor = Color3.fromRGB(230, 60, 60) }
    },
    Bulldog = {
        Name = "BULLDOG", Category = "Rifles", Type = "Rifle", FiringType = "Auto",
        Mag = 24, Reserve = 120, FireRate = 0.105, Pellets = 1, HeadDmg = 115, BodyDmg = 35,
        Optics = { CanADS = true, ZoomFOV = 56, Offset = CFrame.new(0, -0.42, -1.15) },
        HipOffset = CFrame.new(0.60, -0.55, -1.35),
        Recoil = { KickZ = 0.38, PitchX = 3.8, YawY = 1.3, RecoverySpeed = 22 },
        Audio = { Pitch = 2.4, Volume = 1.15, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(45, 48, 55), AccentColor = Color3.fromRGB(100, 180, 100) }
    },
    Guardian = {
        Name = "GUARDIAN", Category = "Rifles", Type = "Rifle", FiringType = "Semi",
        Mag = 12, Reserve = 90, FireRate = 0.19, Pellets = 1, HeadDmg = 195, BodyDmg = 65,
        Optics = { CanADS = true, ZoomFOV = 52, Offset = CFrame.new(0, -0.42, -1.15) },
        HipOffset = CFrame.new(0.60, -0.55, -1.35),
        Recoil = { KickZ = 0.55, PitchX = 5.5, YawY = 1.6, RecoverySpeed = 20 },
        Audio = { Pitch = 2.2, Volume = 1.3, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(55, 58, 65), AccentColor = Color3.fromRGB(220, 200, 100) }
    },
    Marshal = {
        Name = "MARSHAL", Category = "Snipers", Type = "Sniper", FiringType = "Semi", IsSniper = true,
        Mag = 5, Reserve = 40, FireRate = 0.65, Pellets = 1, HeadDmg = 202, BodyDmg = 101,
        Optics = { CanADS = true, ZoomFOV = 40, IsSniperScope = true, Offset = CFrame.new(0, -0.42, -1.15) },
        HipOffset = CFrame.new(0.60, -0.55, -1.35),
        Recoil = { KickZ = 0.65, PitchX = 7.0, YawY = 1.8, RecoverySpeed = 18 },
        Audio = { Pitch = 2.1, Volume = 1.35, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(50, 45, 40), AccentColor = Color3.fromRGB(180, 140, 80) }
    },
    Outlaw = {
        Name = "OUTLAW", Category = "Snipers", Type = "Sniper", FiringType = "Semi", IsSniper = true,
        Mag = 2, Reserve = 30, FireRate = 0.40, Pellets = 1, HeadDmg = 238, BodyDmg = 140,
        Optics = { CanADS = true, ZoomFOV = 38, IsSniperScope = true, Offset = CFrame.new(0, -0.42, -1.15) },
        HipOffset = CFrame.new(0.60, -0.55, -1.35),
        Recoil = { KickZ = 0.78, PitchX = 8.5, YawY = 2.0, RecoverySpeed = 16 },
        Audio = { Pitch = 1.9, Volume = 1.4, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(45, 48, 52), AccentColor = Color3.fromRGB(255, 60, 60) }
    },
    Ares = {
        Name = "ARES", Category = "Heavy", Type = "Heavy", FiringType = "Auto",
        Mag = 50, Reserve = 150, FireRate = 0.085, Pellets = 1, HeadDmg = 72, BodyDmg = 30,
        Optics = { CanADS = true, ZoomFOV = 58, Offset = CFrame.new(0, -0.42, -1.15) },
        HipOffset = CFrame.new(0.60, -0.55, -1.35),
        Recoil = { KickZ = 0.38, PitchX = 3.8, YawY = 1.3, RecoverySpeed = 22 },
        Audio = { Pitch = 2.4, Volume = 1.25, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(48, 50, 56), AccentColor = Color3.fromRGB(220, 160, 40) }
    },
    Odin = {
        Name = "ODIN", Category = "Heavy", Type = "Heavy", FiringType = "Auto",
        Mag = 100, Reserve = 200, FireRate = 0.07, Pellets = 1, HeadDmg = 95, BodyDmg = 38,
        Optics = { CanADS = true, ZoomFOV = 56, Offset = CFrame.new(0, -0.42, -1.15) },
        HipOffset = CFrame.new(0.60, -0.55, -1.35),
        Recoil = { KickZ = 0.42, PitchX = 4.2, YawY = 1.5, RecoverySpeed = 20 },
        Audio = { Pitch = 2.2, Volume = 1.35, Silenced = false },
        Visual = { PrimaryColor = Color3.fromRGB(38, 40, 45), AccentColor = Color3.fromRGB(255, 80, 50) }
    }
}

for k, v in pairs(extraWeapons) do
    if not weapons[k] then
        weapons[k] = v
    end
end

function WeaponRegistry.get(name)
    if not name then return weapons["Vandal"] or extraWeapons.Classic end
    return weapons[name] or weapons["Vandal"] or extraWeapons.Classic
end

function WeaponRegistry.getAll()
    return weapons
end

return WeaponRegistry
