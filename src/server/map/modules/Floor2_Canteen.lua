--[[
    Floor2_Canteen.lua
    โมดูลสร้างชั้น 2: โรงอาหาร มจพ. (Canteen), ซุ้มร้านค้า (ข้าวนัมเบอร์ 1, ก๋วยเตี๋ยว, น้ำปั่น),
                      โต๊ะสแตนเลส, ลิฟต์ซอมบี้, ประตูชัตเตอร์ขึ้นชั้น 3
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local Floor2_Canteen = {}

function Floor2_Canteen.build(building)
    local floor2 = Instance.new("Model")
    floor2.Name = "Floor_2_Canteen"
    floor2.Parent = building

    local bW = PartBuilder.WIDTH
    local bL = PartBuilder.LENGTH
    local fH = PartBuilder.FLOOR_HEIGHT
    local f2BaseY = PartBuilder.floorY(2)

    -- พื้นชั้น 2 (เว้นช่องบันได)
    PartBuilder.makePart(
        floor2,
        "Floor2_DeckL",
        Vector3.new(bW/2 + 25, 1.5, bL),
        CFrame.new(-bW/4 - 12.5, f2BaseY, 0),
        PartBuilder.COLORS.tileLight,
        Enum.Material.SmoothPlastic
    )
    PartBuilder.makePart(
        floor2,
        "Floor2_DeckR",
        Vector3.new(bW/2 - 35, 1.5, bL),
        CFrame.new(bW/4 + 22.5, f2BaseY, 0),
        PartBuilder.COLORS.tileLight,
        Enum.Material.SmoothPlastic
    )
    PartBuilder.makePart(
        floor2,
        "Floor2_Walkway",
        Vector3.new(20, 1.5, bL - 50),
        CFrame.new(30, f2BaseY, 20),
        PartBuilder.COLORS.tileLight,
        Enum.Material.SmoothPlastic
    )

    -- ซุ้มร้านอาหาร มจพ. (Food Stalls)
    local function createDetailedStall(stallName, position, awningColor)
        local stall = Instance.new("Model")
        stall.Name = stallName
        stall.Parent = floor2

        PartBuilder.makePart(stall, "Counter", Vector3.new(18, 3.8, 5), CFrame.new(position), PartBuilder.COLORS.tileLight, Enum.Material.SmoothPlastic)
        PartBuilder.makePart(stall, "GlassDisplay", Vector3.new(12, 2.5, 3), CFrame.new(position + Vector3.new(0, 3.1, -0.5)), PartBuilder.COLORS.glass, Enum.Material.Glass, { Transparency = 0.6 })
        PartBuilder.makePart(stall, "Awning", Vector3.new(18, 0.8, 4), CFrame.new(position + Vector3.new(0, 6.5, 1)) * CFrame.Angles(math.rad(15), 0, 0), awningColor, Enum.Material.Fabric)
        PartBuilder.makeSign(stall, "StallSign", stallName, Vector3.new(18, 2.2, 0.4), position + Vector3.new(0, 8, -0.5), Enum.NormalId.Back, awningColor)
    end

    createDetailedStall("ร้านข้าวนัมเบอร์ 1 มจพ.", Vector3.new(-bW/2 + 22, f2BaseY + 1.9, -40), PartBuilder.COLORS.maroon)
    createDetailedStall("ก๋วยเตี๋ยวเรือตึก 40 ปี", Vector3.new(-bW/2 + 46, f2BaseY + 1.9, -40), Color3.fromRGB(30, 90, 160))
    createDetailedStall("ร้านน้ำปั่น & ชานม มจพ.", Vector3.new(-bW/2 + 70, f2BaseY + 1.9, -40), Color3.fromRGB(40, 140, 70))

    -- แถวโต๊ะอาหาร มจพ. (สแตนเลส)
    for row = 1, 3 do
        for col = 1, 4 do
            local tx = -bW/2 + 22 + (col * 15)
            local tz = -10 + (row * 13)
            PartBuilder.makePart(floor2, "Table_" .. row .. "_" .. col, Vector3.new(10, 3.2, 4.5), CFrame.new(tx, f2BaseY + 2.1, tz), PartBuilder.COLORS.steel, Enum.Material.Metal)
            PartBuilder.makePart(floor2, "BenchA_" .. row .. "_" .. col, Vector3.new(10, 1.8, 1.4), CFrame.new(tx, f2BaseY + 1.4, tz - 3.2), PartBuilder.COLORS.warmGrey, Enum.Material.Metal)
            PartBuilder.makePart(floor2, "BenchB_" .. row .. "_" .. col, Vector3.new(10, 1.8, 1.4), CFrame.new(tx, f2BaseY + 1.4, tz + 3.2), PartBuilder.COLORS.warmGrey, Enum.Material.Metal)
        end
    end

    -- โถงลิฟต์ชั้น 2 (ZOMBIE ELEVATOR)
    PartBuilder.makePart(
        floor2,
        "ElevatorLobbyF2",
        Vector3.new(46, fH, 3),
        CFrame.new(-15, f2BaseY + fH/2, -bL/2 + 20),
        PartBuilder.COLORS.warmGrey,
        Enum.Material.Metal
    )
    for el = 1, 4 do
        local elX = -32 + (el * 9)
        local elDoor = PartBuilder.makePart(
            floor2,
            "ElevatorDoor_F2_" .. el,
            Vector3.new(6.5, 10.5, 0.4),
            CFrame.new(elX, f2BaseY + 5.25, -bL/2 + 21.6),
            PartBuilder.COLORS.steel,
            Enum.Material.Metal
        )
        elDoor.Name = "ZombieElevatorDoor_" .. el
    end

    -- ประตูชัตเตอร์เหล็กกั้นทางขึ้นชั้น 3 (Security Shutter)
    local shutter = PartBuilder.makePart(
        floor2,
        "SteelShutter_Floor3",
        Vector3.new(20, 12, 1.2),
        CFrame.new(40, f2BaseY + 6.5, -45),
        PartBuilder.COLORS.darkGrey,
        Enum.Material.Metal
    )
    shutter.Name = "SteelShutter_Floor3"

    local sConsole = PartBuilder.makePart(
        floor2,
        "ShutterConsole",
        Vector3.new(2.5, 4.5, 1.5),
        CFrame.new(53, f2BaseY + 2.25, -43),
        Color3.fromRGB(45, 50, 55),
        Enum.Material.Metal
    )
    local sPrompt = Instance.new("ProximityPrompt")
    sPrompt.ActionText = "เปิดชัตเตอร์ขึ้นชั้น 3"
    sPrompt.ObjectText = "Security Shutter [2,000 Pts / Keycard]"
    sPrompt.HoldDuration = 1.5
    sPrompt.MaxActivationDistance = 9
    sPrompt.Parent = sConsole
end

return Floor2_Canteen
