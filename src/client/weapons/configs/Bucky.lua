--[[
    Bucky.lua
    การตั้งค่าเฉพาะของปืน BUCKY (Valorant)
    จุดเด่น: ปืนลูกซองปั๊มแอคชั่น 12 Gauge ยิงทีละ 15 เม็ด กระจายตัวหนัก ดาเมจระยะใกล้รุนแรง
]]

return {
    Name = "BUCKY",
    Category = "Shotguns",
    Type = "Shotgun",
    FiringType = "Shotgun",
    Mag = 8,
    Reserve = 60,
    FireRate = 0.75, -- จังหวะปั๊มลูกซอง (Pump Action)
    Pellets = 15,

    Damage = {
        Head = 40,
        Body = 20,
        Legs = 15
    },
    HeadDmg = 40,
    BodyDmg = 20,

    Optics = {
        CanADS = true,
        ZoomFOV = 60,
        Offset = CFrame.new(0, -0.42, -1.15)
    },
    HipOffset = CFrame.new(0.55, -0.52, -1.25),

    Recoil = {
        KickZ = 0.90,
        PitchX = 9.0,
        YawY = 2.2,
        RecoverySpeed = 15
    },

    Audio = {
        Pitch = 1.45,
        Volume = 1.55,
        Silenced = false
    },

    Visual = {
        PrimaryColor = Color3.fromRGB(48, 50, 56),
        AccentColor = Color3.fromRGB(180, 90, 40),
        BarrelLength = 2.4,
        MuzzleZ = -3.35
    }
}
