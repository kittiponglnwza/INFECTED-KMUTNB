--[[
    ExteriorPlaza.lua
    โมดูลสร้างพื้นที่ภายนอกอาคาร: ถนน มจพ., ทางเท้า, สวนปาล์ม, ลานบันได, เสากลางแจ้ง 6 ต้น, ป้ายชื่อทางการ
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local ExteriorPlaza = {}

function ExteriorPlaza.build(building)
    local plazaModel = Instance.new("Model")
    plazaModel.Name = "ExteriorPlaza"
    plazaModel.Parent = building

    local bW = PartBuilder.WIDTH
    local bL = PartBuilder.LENGTH
    local fH = PartBuilder.FLOOR_HEIGHT

    -- ถนนหน้าตึก มจพ.
    PartBuilder.makePart(
        plazaModel,
        "KMUTNB_CampusRoad",
        Vector3.new(300, 2, 260),
        CFrame.new(0, -1, 20),
        Color3.fromRGB(50, 50, 55),
        Enum.Material.Asphalt
    )

    -- ทางเท้ารอบตึก (Sidewalk)
    PartBuilder.makePart(
        plazaModel,
        "Sidewalk",
        Vector3.new(bW + 40, 1.2, bL + 50),
        CFrame.new(0, 0.6, 5),
        Color3.fromRGB(195, 195, 195),
        Enum.Material.Cobblestone
    )

    -- สวนปาล์ม มจพ. (KMUTNB Palm Garden)
    local function createPalmTree(pos)
        PartBuilder.makeCylinder(
            plazaModel,
            "PalmTrunk",
            Vector3.new(16, 2, 2),
            CFrame.new(pos + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(90, 75, 60),
            Enum.Material.Wood
        )
        PartBuilder.makePart(
            plazaModel,
            "PalmLeaves",
            Vector3.new(12, 4, 12),
            CFrame.new(pos + Vector3.new(0, 16, 0)),
            Color3.fromRGB(50, 110, 45),
            Enum.Material.Grass
        )
    end

    for px = -bW/2 + 10, bW/2 - 10, 25 do
        createPalmTree(Vector3.new(px, 1.2, bL/2 + 35))
    end

    -- บันไดลานกว้างขึ้นตัวตึก (Plaza Steps)
    for step = 1, 4 do
        local stepW = bW - 20 - (step * 2)
        local stepY = 1.2 + (step * 0.7)
        local stepZ = bL/2 + 25 - (step * 2.5)
        PartBuilder.makePart(
            plazaModel,
            "PlazaStep_" .. step,
            Vector3.new(stepW, 0.7, 3),
            CFrame.new(0, stepY, stepZ),
            Color3.fromRGB(210, 210, 215),
            Enum.Material.Concrete
        )
    end

    -- ลานชานพักหน้าตึก (Main Entrance Podium)
    PartBuilder.makePart(
        plazaModel,
        "EntrancePodium",
        Vector3.new(bW - 20, 1.5, 20),
        CFrame.new(0, 4, bL/2 + 10),
        PartBuilder.COLORS.tileLight,
        Enum.Material.SmoothPlastic
    )

    -- ป้ายชื่ออาคาร 40 ปี พระจอมเกล้าพระนครเหนือ อย่างเป็นทางการ
    PartBuilder.makeSign(
        plazaModel,
        "KMUTNB_BuildingSign",
        "อาคาร 40 ปี พระจอมเกล้าพระนครเหนือ (อาคาร 77)\nKMUTNB 40th ANNIVERSARY BUILDING",
        Vector3.new(32, 4.5, 1.2),
        Vector3.new(0, 4.5, bL/2 + 22),
        Enum.NormalId.Back,
        PartBuilder.COLORS.maroon
    )

    -- เสากลมยักษ์ 6 ต้น รองรับชายคาหน้าตึก (Colonnade Facade)
    for c = 1, 6 do
        local cx = -bW/2 + 20 + ((c - 1) * ((bW - 40) / 5))
        PartBuilder.makeCylinder(
            plazaModel,
            "GrandPillar_" .. c,
            Vector3.new(fH * 2, 4, 4),
            CFrame.new(cx, 4 + fH, bL/2 + 8) * CFrame.Angles(0, 0, math.rad(90)),
            PartBuilder.COLORS.warmGrey,
            Enum.Material.Concrete
        )
    end

    -- ชายคาซุ้มทางเข้าด้านหน้า (Front Canopy)
    PartBuilder.makePart(
        plazaModel,
        "FrontCanopy",
        Vector3.new(bW - 10, 2.5, 24),
        CFrame.new(0, 4 + fH * 2, bL/2 + 8),
        PartBuilder.COLORS.maroon,
        Enum.Material.SmoothPlastic
    )

    -- จุดเกิดผู้เล่น (Spawn Points ที่ลานหน้าตึก หันหน้าเข้าหาทางเข้าตึก 40 ปี)
    local spawnPad = Instance.new("SpawnLocation")
    spawnPad.Name = "PlazaSpawnLocation"
    spawnPad.Size = Vector3.new(16, 1, 16)
    spawnPad.CFrame = CFrame.lookAt(Vector3.new(0, 5.2, bL/2 + 12), Vector3.new(0, 5.2, 0))
    spawnPad.Anchored = true
    spawnPad.CanCollide = false
    spawnPad.Transparency = 1
    spawnPad.Parent = plazaModel
end

return ExteriorPlaza
