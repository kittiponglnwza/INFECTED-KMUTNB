--[[
    Phantom.lua
    การตั้งค่าเฉพาะของปืน PHANTOM (Valorant)
    จุดเด่น: เก็บเสียง ลำแสงกระสุนสีฟ้า รัวเร็ว 660 RPM แรงถีบควบคุมง่าย
]]

return {
    Name = "PHANTOM",
    Category = "Rifles",
    Type = "Rifle",
    FiringType = "Auto",
    Mag = 30,
    Reserve = 150,
    FireRate = 0.09, -- 660 RPM
    Pellets = 1,

    Damage = {
        Head = 156,
        Body = 39,
        Legs = 33
    },
    HeadDmg = 156,
    BodyDmg = 39,

    Optics = {
        CanADS = true,
        ZoomFOV = 56,
        ADS_FireRateMult = 0.90,
        Offset = CFrame.new(0, -0.42, -1.15)
    },
    HipOffset = CFrame.new(0.60, -0.55, -1.35),

    Recoil = {
        KickZ = 0.35,
        PitchX = 3.6,
        YawY = 1.2,
        RecoverySpeed = 24
    },

    Audio = {
        Pitch = 3.1,
        Volume = 0.7,
        Silenced = true
    },

    Visual = {
        PrimaryColor = Color3.fromRGB(25, 27, 32),
        AccentColor = Color3.fromRGB(0, 220, 255),
        BarrelLength = 2.4,
        MuzzleZ = -2.9
    }
}
