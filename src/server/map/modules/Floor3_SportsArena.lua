--[[
    Floor3_SportsArena.lua
    โมดูลสร้างชั้น 3: ลานกิจกรรมกีฬาในร่ม, โต๊ะปิงปอง ("เล้าไก่" มจพ.), แป้นบาสเกตบอล
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local Floor3_SportsArena = {}

function Floor3_SportsArena.build(building)
    local floor3 = Instance.new("Model")
    floor3.Name = "Floor_3_SportsArena"
    floor3.Parent = building

    local bW = PartBuilder.WIDTH
    local bL = PartBuilder.LENGTH
    local f3BaseY = PartBuilder.floorY(3)

    -- พื้นไม้ปาร์เกต์สนามกีฬาในร่ม (Parquet Floor)
    PartBuilder.makePart(
        floor3,
        "ArenaFloor",
        Vector3.new(bW, 1.5, bL),
        CFrame.new(0, f3BaseY, 0),
        Color3.fromRGB(195, 145, 90),
        Enum.Material.WoodPlanks
    )

    -- โต๊ะปิงปอง มจพ. (โซน "เล้าไก่")
    local function createPingPongTable(pos)
        local tableTop = PartBuilder.makePart(
            floor3,
            "PingPongTable",
            Vector3.new(9, 2.8, 15),
            CFrame.new(pos),
            Color3.fromRGB(30, 80, 140),
            Enum.Material.SmoothPlastic
        )
        PartBuilder.makePart(
            floor3,
            "Net",
            Vector3.new(9.4, 0.8, 0.3),
            CFrame.new(pos + Vector3.new(0, 1.8, 0)),
            Color3.fromRGB(240, 240, 240),
            Enum.Material.Fabric
        )
    end

    createPingPongTable(Vector3.new(-30, f3BaseY + 1.8, 10))
    createPingPongTable(Vector3.new(-30, f3BaseY + 1.8, -15))
    createPingPongTable(Vector3.new(10, f3BaseY + 1.8, 10))
    createPingPongTable(Vector3.new(10, f3BaseY + 1.8, -15))

    -- แป้นบาสเกตบอล (Basketball Hoop)
    PartBuilder.makeCylinder(
        floor3,
        "HoopPost",
        Vector3.new(12, 0.8, 0.8),
        CFrame.new(50, f3BaseY + 6, 0) * CFrame.Angles(0, 0, math.rad(90)),
        PartBuilder.COLORS.darkGrey,
        Enum.Material.Metal
    )
    PartBuilder.makePart(
        floor3,
        "Backboard",
        Vector3.new(1, 4.5, 6),
        CFrame.new(48, f3BaseY + 11, 0),
        Color3.fromRGB(240, 240, 245),
        Enum.Material.SmoothPlastic
    )
    PartBuilder.makePart(
        floor3,
        "Rim",
        Vector3.new(2.5, 0.3, 2.5),
        CFrame.new(46, f3BaseY + 10, 0),
        Color3.fromRGB(255, 80, 20),
        Enum.Material.Neon
    )
end

return Floor3_SportsArena
