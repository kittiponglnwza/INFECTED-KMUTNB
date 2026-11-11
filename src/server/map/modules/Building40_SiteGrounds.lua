--[[
    Building40_SiteGrounds.lua
    พื้นลานคอนกรีตรอบอาคาร 40 ปี มจพ. (Clean Campus Ground)
    - มีเฉพาะตัวอาคารและพื้นลานคอนกรีตรอบอาคารเท่านั้น
    - ลบคลอง, ลบต้นปาล์ม, ลบอาคารจำลองรอบข้างออกทั้งหมด 100%
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Building40_SiteGrounds = {}

local GROUND = Layout.GROUND_Y

function Building40_SiteGrounds.build(parent)
    local site = Instance.new("Model")
    site.Name = "Building40_SiteGrounds"
    site.Parent = parent

    -- พื้นลานคอนกรีตเรียบสะอาดรอบอาคาร 40 ปี (ขนาด 450 x 390 studs)
    PartBuilder.makePart(
        site,
        "BuildingPerimeterGround",
        Vector3.new(450, 2.0, 390),
        CFrame.new(0, GROUND - 1.0, 0),
        Color3.fromRGB(185, 185, 185),
        Enum.Material.Concrete,
        { Anchored = true }
    )

    -- ทางเท้ารอบฐานตึก (Sidewalk Curb)
    PartBuilder.makePart(
        site,
        "BuildingBaseApron",
        Vector3.new(330, 0.4, 270),
        CFrame.new(0, GROUND + 0.2, 0),
        Color3.fromRGB(215, 212, 204),
        Enum.Material.Concrete,
        { Anchored = true }
    )

    print("[Site Grounds] Clean base ground built. Removed canal, removed palm trees. Only Building 40 remains.")
end

return Building40_SiteGrounds
