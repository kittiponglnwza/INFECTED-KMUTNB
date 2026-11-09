--[[
    Sheriff.lua
    การตั้งค่าเฉพาะของปืน SHERIFF (Valorant)
    จุดเด่น: ปืนพกแม็กนั่มหนัก ยิงหัว 159 ดาเมจ นัดเดียวจอด
]]

return {
    Name = "SHERIFF",
    Category = "Sidearms",
    Type = "Revolver",
    FiringType = "Semi",
    Mag = 6,
    Reserve = 60,
    FireRate = 0.25, -- 4 RPS
    Pellets = 1,

    Damage = {
        Head = 159,
        Body = 55,
        Legs = 46
    },
    HeadDmg = 159,
    BodyDmg = 55,

    Optics = {
        CanADS = true,
        ZoomFOV = 62,
        Offset = CFrame.new(0, -0.32, -0.95)
    },
    HipOffset = CFrame.new(0.45, -0.50, -1.15),

    Recoil = {
        KickZ = 0.55,
        PitchX = 6.5,
        YawY = 1.8,
        RecoverySpeed = 18
    },

    Audio = {
        Pitch = 2.15,
        Volume = 1.25,
        Silenced = false
    },

    Visual = {
        PrimaryColor = Color3.fromRGB(160, 165, 175),
        AccentColor = Color3.fromRGB(110, 60, 30),
        BarrelLength = 1.2,
        MuzzleZ = -1.4
    }
}
