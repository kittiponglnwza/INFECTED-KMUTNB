--[[
    Knife.lua
    การตั้งค่าเฉพาะของมีด TACTICAL KARAMBIT (Valorant Melee)
    จุดเด่น: ควงมีดรอบนิ้วสุดเท่ (Spinning Inspect & Equip), ฟันระยะประชิดแรง 75 ดาเมจ (แทงข้างหลัง 150 ดาเมจ)
]]

return {
    Name = "KARAMBIT",
    Category = "Melee",
    Type = "Knife",
    FiringType = "Melee",
    Mag = 1,
    Reserve = 1,
    FireRate = 0.38, -- ความเร็วในการฟันมีด
    Pellets = 1,
    MeleeRange = 7.5, -- ระยะฟัน 7.5 studs

    Damage = {
        Head = 150,
        Body = 75,
        Backstab = 150
    },
    HeadDmg = 150,
    BodyDmg = 75,

    Optics = {
        CanADS = false,
        ZoomFOV = 70,
        Offset = CFrame.new(0.40, -0.45, -1.10)
    },
    HipOffset = CFrame.new(0.45, -0.50, -1.15) * CFrame.Angles(math.rad(15), math.rad(-20), math.rad(30)),

    Recoil = {
        KickZ = 0.15,
        PitchX = 2.0,
        YawY = 1.0,
        RecoverySpeed = 20
    },

    Audio = {
        Pitch = 3.6,
        Volume = 1.0,
        Silenced = true
    },

    Visual = {
        PrimaryColor = Color3.fromRGB(25, 27, 32),
        AccentColor = Color3.fromRGB(0, 240, 255), -- ใบมีดเรืองแสง Cyan Neon สไตล์ Valorant Prime/Champions
        BladeLength = 1.2
    }
}
