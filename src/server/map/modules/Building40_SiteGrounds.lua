--[[
    Building40_SiteGrounds.lua
    พื้นลานคอนกรีตรอบอาคาร 40 ปี มจพ. (Clean Campus Ground)
    - มีเฉพาะตัวอาคารและพื้นลานคอนกรีตรอบอาคารเท่านั้น
    - ลบคลอง, ลบต้นปาล์ม, ลบอาคารจำลองรอบข้างออกทั้งหมด 100%
]]

local SlabBuilder = require(script.Parent.Parent.utils.SlabBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Building40_SiteGrounds = {}

local GROUND = Layout.GROUND_Y

function Building40_SiteGrounds.build(parent)
    local site = Instance.new("Model")
    site.Name = "Building40_SiteGrounds"
    site.Parent = parent

    local body = Layout.BODY
    -- พื้นอิฐรอบอาคาร 40 ปีทั้งผืน (450 x 430 studs เว้นช่องตัวอาคารเพื่อไม่ให้ Z-fight กับพื้นชั้น 1)
    SlabBuilder.build(
        site,
        "BuildingPerimeterGround",
        {
            { minX = -225, maxX = 225, minZ = -215, maxZ = 215 },
        },
        {
            { minX = -body.halfX, maxX = body.halfX, minZ = -body.halfZ, maxZ = body.halfZ },
        },
        GROUND,
        2.0,
        Color3.fromRGB(200, 120, 110),
        Enum.Material.Brick
    )

    print("[Site Grounds] Clean brick perimeter ground built around Building 40 (no Z-fighting).")
end

return Building40_SiteGrounds
