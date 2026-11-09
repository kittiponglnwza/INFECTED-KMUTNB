--[[
    CarBuilder.lua
    สร้างรถยนต์จอดตกแต่งแบบเรียบง่าย (Static Parked Car) สำหรับลานจอดรถชั้น 1 และลานจอดรถรอบตึก
    - ความยาวรถอยู่แนวแกน Z ของตัวรถ (ด้านหน้ารถ = -Z ของตัวรถ)
    - yawDeg หมุนรถรอบแกน Y
]]

local PartBuilder = require(script.Parent.PartBuilder)

local CarBuilder = {}

function CarBuilder.buildParkedCar(parent, name, cx, groundY, cz, yawDeg, bodyColor)
    local car = Instance.new("Model")
    car.Name = name
    car.Parent = parent

    local base = CFrame.new(cx, groundY, cz) * CFrame.Angles(0, math.rad(yawDeg or 0), 0)
    local glassDark = Color3.fromRGB(35, 45, 58)
    local tyreBlack = Color3.fromRGB(28, 28, 30)

    -- ตัวถังรถ + ห้องโดยสาร + หลังคา
    PartBuilder.makePart(car, "Chassis", Vector3.new(7.0, 1.9, 15.0),
        base * CFrame.new(0, 1.95, 0), bodyColor, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(car, "Cabin", Vector3.new(6.4, 2.0, 8.0),
        base * CFrame.new(0, 3.9, 0.6), glassDark, Enum.Material.Glass, { Transparency = 0.15 })
    PartBuilder.makePart(car, "Roof", Vector3.new(6.5, 0.3, 7.2),
        base * CFrame.new(0, 5.05, 0.6), bodyColor, Enum.Material.SmoothPlastic)

    -- ล้อรถ 4 ล้อ (Cylinder แกน X)
    for _, wx in ipairs({ -3.35, 3.35 }) do
        for _, wz in ipairs({ -4.8, 4.8 }) do
            PartBuilder.makeCylinder(car, "Wheel", Vector3.new(1.0, 2.6, 2.6),
                base * CFrame.new(wx, 1.3, wz), tyreBlack, Enum.Material.SmoothPlastic)
        end
    end

    -- ไฟหน้า / ไฟท้าย / กันชน
    for _, lx in ipairs({ -2.5, 2.5 }) do
        PartBuilder.makePart(car, "Headlight", Vector3.new(1.4, 0.6, 0.2),
            base * CFrame.new(lx, 2.3, -7.55), Color3.fromRGB(255, 252, 230), Enum.Material.Neon)
        PartBuilder.makePart(car, "Taillight", Vector3.new(1.4, 0.5, 0.2),
            base * CFrame.new(lx, 2.3, 7.55), Color3.fromRGB(210, 30, 30), Enum.Material.Neon)
    end
    PartBuilder.makePart(car, "BumperFront", Vector3.new(7.1, 0.6, 0.4),
        base * CFrame.new(0, 1.2, -7.6), Color3.fromRGB(45, 48, 54), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(car, "BumperRear", Vector3.new(7.1, 0.6, 0.4),
        base * CFrame.new(0, 1.2, 7.6), Color3.fromRGB(45, 48, 54), Enum.Material.SmoothPlastic)

    return car
end

CarBuilder.CAR_COLORS = {
    Color3.fromRGB(235, 235, 238),
    Color3.fromRGB(30, 32, 36),
    Color3.fromRGB(150, 155, 162),
    Color3.fromRGB(165, 28, 35),
    Color3.fromRGB(28, 70, 150),
    Color3.fromRGB(210, 185, 140),
}

return CarBuilder
