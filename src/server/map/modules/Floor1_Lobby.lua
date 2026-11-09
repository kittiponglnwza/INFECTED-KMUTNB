--[[
    Floor1_Lobby.lua
    โมดูลสร้างชั้น 1: โถงใหญ่, กระจก Curtain Wall, ธนาคารกรุงเทพ & ตู้ ATM, ศูนย์บริการนักศึกษา, โถงลิฟต์ 4 ตัว, บันไดกว้าง
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local Floor1_Lobby = {}

function Floor1_Lobby.build(building)
    local floor1 = Instance.new("Model")
    floor1.Name = "Floor_1_MainLobby"
    floor1.Parent = building

    local bW = PartBuilder.WIDTH
    local bL = PartBuilder.LENGTH
    local fH = PartBuilder.FLOOR_HEIGHT
    local f1BaseY = PartBuilder.FLOOR1_Y

    -- พื้นหินแกรนิตชั้น 1
    PartBuilder.makePart(
        floor1,
        "Floor1_Tile",
        Vector3.new(bW, 1.5, bL),
        CFrame.new(0, f1BaseY, 0),
        PartBuilder.COLORS.tileLight,
        Enum.Material.SmoothPlastic
    )

    -- แผงกระจกบานใหญ่หน้าทางเข้า (Glass Curtain Wall)
    PartBuilder.makePart(
        floor1,
        "CurtainWallL",
        Vector3.new((bW - 24)/2, fH, 1.2),
        CFrame.new(-(bW + 24)/4, f1BaseY + fH/2, bL/2),
        PartBuilder.COLORS.glass,
        Enum.Material.Glass,
        { Transparency = 0.55 }
    )
    PartBuilder.makePart(
        floor1,
        "CurtainWallR",
        Vector3.new((bW - 24)/2, fH, 1.2),
        CFrame.new((bW + 24)/4, f1BaseY + fH/2, bL/2),
        PartBuilder.COLORS.glass,
        Enum.Material.Glass,
        { Transparency = 0.55 }
    )
    -- ซุ้มประตูกระจกอัตโนมัติ
    PartBuilder.makePart(
        floor1,
        "AutoDoorFrame",
        Vector3.new(24, 2, 1.5),
        CFrame.new(0, f1BaseY + 11, bL/2),
        PartBuilder.COLORS.warmGrey,
        Enum.Material.Metal
    )

    -- กำแพงด้านข้างและด้านหลัง
    PartBuilder.makePart(floor1, "OuterWallL1", Vector3.new(1.8, fH, bL), CFrame.new(-bW/2, f1BaseY + fH/2, 0), PartBuilder.COLORS.cream)
    PartBuilder.makePart(floor1, "OuterWallR1", Vector3.new(1.8, fH, bL), CFrame.new(bW/2, f1BaseY + fH/2, 0), PartBuilder.COLORS.cream)
    PartBuilder.makePart(floor1, "OuterWallB1", Vector3.new(bW, fH, 1.8), CFrame.new(0, f1BaseY + fH/2, -bL/2), PartBuilder.COLORS.cream)

    -- ภายในชั้น 1: ธนาคารกรุงเทพ สาขา มจพ.
    local bank = Instance.new("Model")
    bank.Name = "BangkokBank_Branch"
    bank.Parent = floor1

    PartBuilder.makeSign(
        bank,
        "BankSign",
        "ธนาคารกรุงเทพ สาขา มจพ. (Bangkok Bank)",
        Vector3.new(24, 3.5, 0.5),
        Vector3.new(-bW/2 + 25, f1BaseY + 10, 25),
        Enum.NormalId.Back,
        Color3.fromRGB(0, 50, 130)
    )
    PartBuilder.makePart(
        bank,
        "BankCounterDesk",
        Vector3.new(24, 3.8, 4),
        CFrame.new(-bW/2 + 25, f1BaseY + 1.9, 25),
        PartBuilder.COLORS.tileLight,
        Enum.Material.SmoothPlastic
    )

    -- ตู้ ATM 2 ตู้
    for atm = 1, 2 do
        local atmX = -bW/2 + 8 + (atm * 4)
        local atmBox = PartBuilder.makePart(
            bank,
            "ATM_" .. atm,
            Vector3.new(3, 7, 3),
            CFrame.new(atmX, f1BaseY + 3.5, 38),
            Color3.fromRGB(0, 45, 125),
            Enum.Material.Metal
        )
        PartBuilder.makeSign(
            atmBox,
            "ATMSign",
            "ATM BBL\nมจพ.",
            Vector3.new(2.8, 2, 0.2),
            Vector3.new(atmX, f1BaseY + 6, 39.6),
            Enum.NormalId.Back,
            Color3.fromRGB(0, 50, 140)
        )
    end

    -- เคาน์เตอร์ศูนย์บริการนักศึกษา มจพ.
    PartBuilder.makePart(
        floor1,
        "StudentServiceDesk",
        Vector3.new(34, 3.8, 5),
        CFrame.new(bW/2 - 30, f1BaseY + 1.9, 22),
        PartBuilder.COLORS.darkGrey,
        Enum.Material.WoodPlanks
    )
    PartBuilder.makeSign(
        floor1,
        "StudentServiceSign",
        "ศูนย์บริการนักศึกษาครบวงจร มจพ.",
        Vector3.new(34, 3, 0.5),
        Vector3.new(bW/2 - 30, f1BaseY + 9, 22),
        Enum.NormalId.Back,
        PartBuilder.COLORS.maroon
    )

    -- โถงลิฟต์โดยสาร 4 ตัว (Elevator Bank)
    PartBuilder.makePart(
        floor1,
        "ElevatorLobbyWall",
        Vector3.new(46, fH, 3),
        CFrame.new(-15, f1BaseY + fH/2, -bL/2 + 20),
        PartBuilder.COLORS.warmGrey,
        Enum.Material.Metal
    )
    for el = 1, 4 do
        local elX = -32 + (el * 9)
        PartBuilder.makePart(
            floor1,
            "ElevatorDoor_F1_" .. el,
            Vector3.new(6.5, 10.5, 0.4),
            CFrame.new(elX, f1BaseY + 5.25, -bL/2 + 21.6),
            PartBuilder.COLORS.steel,
            Enum.Material.Metal
        )
        PartBuilder.makePart(
            floor1,
            "Ind_F1_" .. el,
            Vector3.new(2.5, 1, 0.2),
            CFrame.new(elX, f1BaseY + 12, -bL/2 + 21.6),
            Color3.fromRGB(255, 140, 0),
            Enum.Material.Neon
        )
    end

    -- บันไดกว้างเชื่อมขึ้นชั้น 2 (Grand Staircase)
    local stairW = 20
    local stepsCount = 20
    local stairStart = Vector3.new(40, f1BaseY, -10)
    for s = 1, stepsCount do
        local sY = f1BaseY + (s * (fH / stepsCount))
        local sZ = stairStart.Z - (s * 2.2)
        PartBuilder.makePart(
            floor1,
            "GrandStair_" .. s,
            Vector3.new(stairW, 0.85, 2.3),
            CFrame.new(stairStart.X, sY, sZ),
            PartBuilder.COLORS.warmGrey,
            Enum.Material.Concrete
        )
    end
end

return Floor1_Lobby
