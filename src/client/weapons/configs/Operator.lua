--[[
    Operator.lua
    การตั้งค่าเฉพาะของปืน OPERATOR (Valorant)
    จุดเด่น: สไนเปอร์หนัก นัดเดียวตัวดับ (150 Body / 255 Head) พร้อมสโคปซูมลึก
]]

return {
    Name = "OPERATOR",
    Category = "Snipers",
    Type = "Sniper",
    FiringType = "Semi",
    IsSniper = true,
    Mag = 5,
    Reserve = 30,
    FireRate = 1.25, -- Bolt action
    Pellets = 1,

    Damage = {
        Head = 255,
        Body = 150,
        Legs = 120
    },
    HeadDmg = 255,
    BodyDmg = 150,

    Optics = {
        CanADS = true,
        ZoomFOV = 36, -- Balanced 2.5x Valorant Sniper Scope
        IsSniperScope = true,
        Offset = CFrame.new(0, -0.42, -1.15)
    },
    HipOffset = CFrame.new(0.60, -0.55, -1.35),

    Recoil = {
        KickZ = 0.85,
        PitchX = 9.5,
        YawY = 2.4,
        RecoverySpeed = 16
    },

    Audio = {
        Pitch = 1.6,
        Volume = 1.4,
        Silenced = false
    },

    Visual = {
        PrimaryColor = Color3.fromRGB(30, 32, 38),
        AccentColor = Color3.fromRGB(240, 50, 70),
        BarrelLength = 3.6,
        MuzzleZ = -3.8
    }
}
