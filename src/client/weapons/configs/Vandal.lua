--[[
    Vandal.lua
    การตั้งค่าเฉพาะของปืน VANDAL (Valorant)
    จุดเด่น: ยิงหัว 160 ดาเมจ นัดเดียวจอดทุกระยะ
]]

return {
    Name = "VANDAL",
    Category = "Rifles",
    Type = "Rifle",
    FiringType = "Auto",
    Mag = 25,
    Reserve = 125,
    FireRate = 0.103, -- 585 RPM
    Pellets = 1,

    Damage = {
        Head = 160,
        Body = 40,
        Legs = 34
    },
    HeadDmg = 160,
    BodyDmg = 40,

    -- การเล็งและซูม (Optics & ADS)
    Optics = {
        CanADS = true,
        ZoomFOV = 56, -- Valorant 1.25x zoom
        ADS_FireRateMult = 0.90, -- ยิงช้าลง 10% เมื่อเล็ง ADS
        Offset = CFrame.new(0, -0.42, -1.15)
    },
    HipOffset = CFrame.new(0.60, -0.55, -1.35),

    -- แรงถีบปืน (Recoil Profile)
    Recoil = {
        KickZ = 0.42,
        PitchX = 4.5,
        YawY = 1.6,
        RecoverySpeed = 22
    },

    -- เสียงปืน (Audio Profile)
    Audio = {
        Pitch = 2.35,
        Volume = 1.2,
        Silenced = false
    },

    -- รูปลักษณ์และโมเดล 3D (Visual Aesthetics)
    Visual = {
        PrimaryColor = Color3.fromRGB(35, 38, 44),
        AccentColor = Color3.fromRGB(255, 120, 30),
        BarrelLength = 2.4,
        MuzzleZ = -2.9
    }
}
