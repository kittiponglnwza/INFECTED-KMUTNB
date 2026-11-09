--[[
    Spectre.lua
    การตั้งค่าเฉพาะของปืน SPECTRE (Valorant)
    จุดเด่น: ปืนกลมือเก็บเสียง รัวเร็ว 800 RPM คล่องตัวสูง
]]

return {
    Name = "SPECTRE",
    Category = "SMGs",
    Type = "SMG",
    FiringType = "Auto",
    Mag = 30,
    Reserve = 150,
    FireRate = 0.075, -- 800 RPM
    Pellets = 1,

    Damage = {
        Head = 78,
        Body = 26,
        Legs = 22
    },
    HeadDmg = 78,
    BodyDmg = 26,

    Optics = {
        CanADS = true,
        ZoomFOV = 58,
        ADS_FireRateMult = 0.90,
        Offset = CFrame.new(0, -0.40, -1.10)
    },
    HipOffset = CFrame.new(0.55, -0.52, -1.25),

    Recoil = {
        KickZ = 0.28,
        PitchX = 2.8,
        YawY = 1.0,
        RecoverySpeed = 26
    },

    Audio = {
        Pitch = 3.2,
        Volume = 0.65,
        Silenced = true
    },

    Visual = {
        PrimaryColor = Color3.fromRGB(30, 32, 38),
        AccentColor = Color3.fromRGB(60, 200, 220),
        BarrelLength = 2.0,
        MuzzleZ = -2.5
    }
}
