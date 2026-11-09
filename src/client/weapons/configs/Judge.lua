--[[
    Judge.lua
    การตั้งค่าเฉพาะของปืน JUDGE (Valorant)
    จุดเด่น: ปืนลูกซองออโตเมติกลูกโม่ยักษ์ (Automatic Revolving Drum Shotgun)
            ยิงรัวต่อเนื่องระยะประชิดถล่มซอมบี้
]]

return {
    Name = "JUDGE",
    Category = "Shotguns",
    Type = "Shotgun",
    FiringType = "Auto",
    Mag = 7,
    Reserve = 60,
    FireRate = 0.28, -- ยิงออโตเมติกต่อเนื่อง 214 RPM
    Pellets = 12,

    Damage = {
        Head = 34,
        Body = 17,
        Legs = 13
    },
    HeadDmg = 34,
    BodyDmg = 17,

    Optics = {
        CanADS = true,
        ZoomFOV = 60,
        Offset = CFrame.new(0, -0.42, -1.15)
    },
    HipOffset = CFrame.new(0.55, -0.52, -1.25),

    Recoil = {
        KickZ = 0.70,
        PitchX = 7.0,
        YawY = 2.0,
        RecoverySpeed = 18
    },

    Audio = {
        Pitch = 1.50,
        Volume = 1.45,
        Silenced = false
    },

    Visual = {
        PrimaryColor = Color3.fromRGB(40, 42, 48),
        AccentColor = Color3.fromRGB(240, 55, 55),
        BarrelLength = 2.0,
        MuzzleZ = -2.90
    }
}
