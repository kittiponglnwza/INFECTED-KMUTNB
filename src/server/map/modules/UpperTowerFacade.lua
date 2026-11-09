--[[
    UpperTowerFacade.lua
    โมดูลสร้างเปลือกอาคารตึกสูงชั้น 4 ถึง 11 พร้อมหน้าต่าง Facade ระบายอากาศ และดาดฟ้าลานจอด ฮ.
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local UpperTowerFacade = {}

function UpperTowerFacade.build(building)
    local upperTower = Instance.new("Model")
    upperTower.Name = "UpperTower_Floors_4_to_11"
    upperTower.Parent = building

    local bW = PartBuilder.WIDTH
    local bL = PartBuilder.LENGTH
    local fH = PartBuilder.FLOOR_HEIGHT
    local towerStartY = PartBuilder.floorY(4)
    local remainingFloors = 8
    local towerTotalH = remainingFloors * fH

    -- โครงสร้างแกนกลางตึกสูง (Tower Core)
    PartBuilder.makePart(
        upperTower,
        "TowerCore",
        Vector3.new(bW, towerTotalH, bL),
        CFrame.new(0, towerStartY + towerTotalH/2, 0),
        PartBuilder.COLORS.cream,
        Enum.Material.Concrete
    )

    -- แถบหน้าต่างกระจกระบายอากาศและเส้นคาดสีแดงเลือดหมู มจพ.
    for fl = 1, remainingFloors do
        local winY = towerStartY + (fl - 1) * fH + fH/2
        PartBuilder.makePart(
            upperTower,
            "TowerWindows_F" .. (fl + 3),
            Vector3.new(bW - 20, 6, 1.5),
            CFrame.new(0, winY, bL/2 + 0.5),
            PartBuilder.COLORS.glass,
            Enum.Material.Glass,
            { Transparency = 0.5 }
        )
        PartBuilder.makePart(
            upperTower,
            "MaroonStripe_F" .. (fl + 3),
            Vector3.new(bW - 10, 1.5, 2),
            CFrame.new(0, winY + 4, bL/2 + 0.6),
            PartBuilder.COLORS.maroon,
            Enum.Material.SmoothPlastic
        )
    end

    -- ดาดฟ้าตึก (Rooftop & Helipad)
    local roofY = towerStartY + towerTotalH
    PartBuilder.makePart(
        upperTower,
        "RooftopSlab",
        Vector3.new(bW + 6, 3, bL + 6),
        CFrame.new(0, roofY + 1.5, 0),
        PartBuilder.COLORS.warmGrey,
        Enum.Material.Concrete
    )
    PartBuilder.makePart(
        upperTower,
        "HelipadMark",
        Vector3.new(30, 0.4, 30),
        CFrame.new(0, roofY + 3.2, 0),
        PartBuilder.COLORS.tileLight,
        Enum.Material.SmoothPlastic
    )
end

return UpperTowerFacade
