--[[
    Classic.lua
    การตั้งค่าเฉพาะของปืนพก CLASSIC (Valorant Starter Sidearm)
    จุดเด่น: อาวุธรองประจำตัว ยิงกึ่งอัตโนมัติ แม่นยำ คล่องตัวสูง
]]

return {
    Name = "CLASSIC",
    Category = "Sidearms",
    Type = "Pistol",
    FiringType = "Semi",
    Mag = 12,
    Reserve = 120,
    FireRate = 0.15,
    Pellets = 1,
    HeadDmg = 78,
    BodyDmg = 26,

    Damage = {
        Head = 78,
        Body = 26,
        Legs = 22
    },

    Optics = {
        CanADS = true,
        ZoomFOV = 62,
        Offset = CFrame.new(0, -0.32, -0.95)
    },
    HipOffset = CFrame.new(0.45, -0.50, -1.15),

    Recoil = {
        KickZ = 0.30,
        PitchX = 3.0,
        YawY = 0.9,
        RecoverySpeed = 22
    },

    Audio = {
        Pitch = 2.8,
        Volume = 1.0,
        Silenced = false
    },

    Visual = {
        PrimaryColor = Color3.fromRGB(40, 42, 48),
        AccentColor = Color3.fromRGB(180, 185, 195),
        BarrelLength = 1.2,
        MuzzleZ = -1.4
    }
}
