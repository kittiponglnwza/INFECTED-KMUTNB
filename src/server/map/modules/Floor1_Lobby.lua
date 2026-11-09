--[[
    Floor1_Lobby.lua
    โครงสร้างชั้น 1 (Floor G) อาคาร 40 ปี มจพ.
    สร้างตรงตามภาพแปลนลายเส้น (media_1794240497684_660796bc.png)
    
    อัปเดตตามคำสั่งล่าสุด:
      1. ขยายสเกลใหญ่ขึ้น 2 เท่า (Footprint 300 x 240 studs, เพดานสูง 22 studs)
      2. ปิดตายทุกห้อง (Sealed Solid Walls ทุกห้อง ธนาคาร/คาเฟ่/ห้องซ้ายบน/ห้องซ้ายล่าง)
      3. บันไดหันหน้าเข้าหาลิฟต์ (Stair entrance directly faces elevator doors across the central passage)
      4. ลิฟต์หันหน้าเข้าหาบันได (Elevator doors face directly across to stairs)
      5. บันไดวนซ้าย (Left-turning switchback staircase)
      6. ไม่มีขอบทางเข้าออก (Open seamless corridor entrance/exit, no curbs or blocking walls)
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local Floor1_Lobby = {}

function Floor1_Lobby.build(parent)
    local floor1 = Instance.new("Model")
    floor1.Name = "Floor_1_Building40"
    floor1.Parent = parent

    -- ขนาดสเกลขยายใหญ่ 2 เท่า (2X Scale)
    local floorY = 1.0         -- ระดับพื้น
    local wallH = 22.0         -- ความสูงผนังโปร่งสบายตา (22 studs)
    local wallThick = 2.0      -- ความหนาผนังแข็งแรง (2 studs)
    local wallColor = Color3.fromRGB(242, 239, 233)
    local wallMaterial = Enum.Material.Concrete

    ------------------------------------------------------------------
    -- 1. พื้นฐานชั้น 1 ขนาด 2 เท่า (Main Ground Slab 300 x 240 studs)
    ------------------------------------------------------------------
    PartBuilder.makePart(
        floor1,
        "Floor1_BaseSlab_2X",
        Vector3.new(300, 2.0, 240),
        CFrame.new(0, floorY - 1.0, 0),
        Color3.fromRGB(225, 222, 215),
        Enum.Material.SmoothPlastic
    )

    ------------------------------------------------------------------
    -- 2. พื้นที่ตรงกลาง: "ลานจอดรถ" (PARKING AREA & DRIVEWAY - 2X SCALE)
    -- กว้าง 88 studs ข้ามจากซ้ายไปขวา พร้อมเส้นแบ่งเลน ซองจอดรถ และลูกศรเข้า/ออก
    ------------------------------------------------------------------
    local parkingZone = Instance.new("Folder")
    parkingZone.Name = "ParkingLotZone"
    parkingZone.Parent = floor1

    -- ถนนแอสฟัลต์ลานจอดรถตรงกลาง
    PartBuilder.makePart(
        parkingZone,
        "DrivewayAsphalt_2X",
        Vector3.new(300, 0.1, 88),
        CFrame.new(0, floorY + 0.05, 0),
        Color3.fromRGB(48, 50, 54),
        Enum.Material.Asphalt
    )

    -- เส้นจราจรแบ่งเลนกึ่งกลางสีเหลืองคู่ (Double Yellow Lines)
    PartBuilder.makePart(parkingZone, "YellowLine_1", Vector3.new(280, 0.05, 0.8), CFrame.new(-5, floorY + 0.1, -1.0), Color3.fromRGB(255, 215, 30), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(parkingZone, "YellowLine_2", Vector3.new(280, 0.05, 0.8), CFrame.new(-5, floorY + 0.1, 1.0), Color3.fromRGB(255, 215, 30), Enum.Material.SmoothPlastic)

    -- ช่องจอดรถ 10 ซอง (5 ซองบน, 5 ซองล่าง) พร้อมหมอนหยุดล้อ (Wheel Stops)
    for p = 1, 5 do
        local pX = -110 + ((p - 1) * 32)
        -- ช่องจอดแถวบน
        PartBuilder.makePart(parkingZone, "Stripe_Top_" .. p, Vector3.new(1.0, 0.05, 28), CFrame.new(pX, floorY + 0.1, -30), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
        PartBuilder.makePart(parkingZone, "WheelStop_T_" .. p, Vector3.new(12, 0.9, 1.5), CFrame.new(pX + 16, floorY + 0.5, -41), Color3.fromRGB(235, 185, 30), Enum.Material.Concrete)

        -- ช่องจอดแถวล่าง
        PartBuilder.makePart(parkingZone, "Stripe_Bot_" .. p, Vector3.new(1.0, 0.05, 28), CFrame.new(pX, floorY + 0.1, 30), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
        PartBuilder.makePart(parkingZone, "WheelStop_B_" .. p, Vector3.new(12, 0.9, 1.5), CFrame.new(pX + 16, floorY + 0.5, 41), Color3.fromRGB(235, 185, 30), Enum.Material.Concrete)
    end

    -- เสาโครงสร้างลานจอดรถขนาดใหญ่ 4 ต้น พร้อมลายคาดเซฟตี้เหลือง-ดำ
    for _, px in ipairs({ -70, 70 }) do
        for _, pz in ipairs({ -36, 36 }) do
            PartBuilder.makePart(parkingZone, "Pillar_2X", Vector3.new(6.0, wallH, 6.0), CFrame.new(px, floorY + wallH/2, pz), Color3.fromRGB(215, 215, 220), Enum.Material.Concrete)
            PartBuilder.makePart(parkingZone, "SafetyBand", Vector3.new(6.4, 4.5, 6.4), CFrame.new(px, floorY + 4.0, pz), Color3.fromRGB(240, 180, 20), Enum.Material.SmoothPlastic)
        end
    end

    -- ป้ายตัวหนังสือ "ลานจอดรถ" กลางถนน
    PartBuilder.makeSign(
        parkingZone,
        "Sign_Parking_2X",
        "ลานจอดรถ\nPARKING LOT",
        Vector3.new(28, 7.0, 0.2),
        Vector3.new(-25, floorY + 0.12, 0),
        Enum.NormalId.Top,
        Color3.fromRGB(48, 50, 54),
        Color3.fromRGB(255, 220, 50)
    )

    -- ลูกศรเข้า-ออกทางขวา (ตามภาพแปลน สเกล 2 เท่า)
    PartBuilder.makeSign(parkingZone, "Arrow_Out_2X", "→ ทางออก (EXIT) →", Vector3.new(24, 4.5, 0.2), Vector3.new(120, floorY + 0.12, -22), Enum.NormalId.Top, Color3.fromRGB(48, 50, 54), Color3.fromRGB(255, 255, 255))
    PartBuilder.makeSign(parkingZone, "Arrow_In_2X",  "← ทางเข้า (IN) ←", Vector3.new(24, 4.5, 0.2), Vector3.new(120, floorY + 0.12, 22),  Enum.NormalId.Top, Color3.fromRGB(48, 50, 54), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- ฟังก์ชันสร้างห้องปิดตายทึบทั้ง 4 ด้าน (SEALED ROOM BUILDER)
    ------------------------------------------------------------------
    local function createSealedRoom(roomName, posX, posZ, sizeX, sizeZ, signText, signColor)
        local model = Instance.new("Model")
        model.Name = roomName
        model.Parent = floor1

        -- พื้นห้อง
        PartBuilder.makePart(model, "Floor", Vector3.new(sizeX, 0.1, sizeZ), CFrame.new(posX, floorY + 0.06, posZ), Color3.fromRGB(230, 230, 230), Enum.Material.SmoothPlastic)

        -- ผนังปิดตาย 4 ด้าน (ทึบสนิท ไม่มีช่องประตูเปิดตามคำสั่ง)
        PartBuilder.makePart(model, "Wall_North", Vector3.new(sizeX, wallH, wallThick), CFrame.new(posX, floorY + wallH/2, posZ - sizeZ/2), wallColor, wallMaterial)
        PartBuilder.makePart(model, "Wall_South", Vector3.new(sizeX, wallH, wallThick), CFrame.new(posX, floorY + wallH/2, posZ + sizeZ/2), wallColor, wallMaterial)
        PartBuilder.makePart(model, "Wall_West",  Vector3.new(wallThick, wallH, sizeZ), CFrame.new(posX - sizeX/2, floorY + wallH/2, posZ), wallColor, wallMaterial)
        PartBuilder.makePart(model, "Wall_East",  Vector3.new(wallThick, wallH, sizeZ), CFrame.new(posX + sizeX/2, floorY + wallH/2, posZ), wallColor, wallMaterial)

        -- ป้ายชื่อห้องขนาดใหญ่ติดบนผนังที่หันเข้าหาลานจอดรถ
        local signZ = (posZ > 0) and (posZ - sizeZ/2 - 0.2) or (posZ + sizeZ/2 + 0.2)
        local signFace = (posZ > 0) and Enum.NormalId.Back or Enum.NormalId.Front
        PartBuilder.makeSign(
            model,
            "Sign",
            signText,
            Vector3.new(22, 5.0, 0.4),
            Vector3.new(posX, floorY + wallH/2, signZ),
            signFace,
            signColor or Color3.fromRGB(80, 85, 90),
            Color3.fromRGB(255, 255, 255)
        )

        return model
    end

    ------------------------------------------------------------------
    -- 3. มุมทั้ง 4: ปิดตายทุกห้อง (SEALED ALL 4 CORNER ROOMS - 2X SCALE)
    ------------------------------------------------------------------
    -- 3.1 มุมล่างขวา: "ธนาคาร" (ปิดตาย)
    createSealedRoom("Room_Bank_BottomRight", 105, 77, 70, 66, "ธนาคาร\nBANK (SEALED)", Color3.fromRGB(0, 52, 138))

    -- 3.2 มุมบนขวา: "คาเฟ่" (ปิดตาย)
    createSealedRoom("Room_Cafe_TopRight", 105, -77, 70, 66, "คาเฟ่\nCAFE (SEALED)", Color3.fromRGB(120, 75, 40))

    -- 3.3 มุมบนซ้าย: "ห้อง" (ปิดตาย)
    createSealedRoom("Room_TopLeft", -105, -77, 70, 66, "ห้อง\nROOM (SEALED)", Color3.fromRGB(80, 85, 95))

    -- 3.4 มุมล่างซ้าย: "ห้อง" (ปิดตาย)
    createSealedRoom("Room_BottomLeft", -105, 77, 70, 66, "ห้อง\nROOM (SEALED)", Color3.fromRGB(80, 85, 95))

    ------------------------------------------------------------------
    -- 4. ด้านบน (REAR CORE - 2X SCALE)
    -- ลิฟต์ (ซ้าย) หันหน้าไปหาบันได | ทางเข้าออก (กลาง - ไม่มีขอบ) | บันได (ขวา - หันหน้าไปหาลิฟต์ + วนซ้าย)
    ------------------------------------------------------------------
    local topCore = Instance.new("Folder")
    topCore.Name = "TopCirculationCore"
    topCore.Parent = floor1

    local topZ = -127 -- Z ตำแหน่งคอร์บน
    local coreDepth = 36

    -- 4.1 ลิฟต์ด้านบนซ้าย: **ประตูลิฟต์หันหน้าไปทางทิศตะวันออก (+X) เข้าหาบันได!**
    local topLift = Instance.new("Model")
    topLift.Name = "TopElevators_Left"
    topLift.Parent = topCore

    local tlX = -47
    PartBuilder.makePart(topLift, "Floor", Vector3.new(46, 0.1, coreDepth), CFrame.new(tlX, floorY + 0.06, topZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(topLift, "Wall_Back", Vector3.new(46, wallH, wallThick), CFrame.new(tlX, floorY + wallH/2, topZ - coreDepth/2), wallColor, wallMaterial)
    PartBuilder.makePart(topLift, "Wall_West", Vector3.new(wallThick, wallH, coreDepth), CFrame.new(tlX - 23, floorY + wallH/2, topZ), wallColor, wallMaterial)

    -- ผนังฝั่งขวา (+X) หันหน้าเข้าหาทางเดินและบันได -> ติดตั้งประตูลิฟต์ 2 ตัวหันหน้าไปทางขวา (+X)!
    PartBuilder.makePart(topLift, "Wall_East_Top", Vector3.new(wallThick, 6.0, coreDepth), CFrame.new(tlX + 23, floorY + wallH - 3.0, topZ), wallColor, wallMaterial)
    for el = 1, 2 do
        local eZ = (topZ - 9) + ((el - 1) * 18)
        PartBuilder.makePart(topLift, "LiftDoor_" .. el, Vector3.new(0.6, 16.0, 11.0), CFrame.new(tlX + 23.3, floorY + 8.0, eZ), PartBuilder.COLORS.steel, Enum.Material.Metal)
        PartBuilder.makeSign(topLift, "Ind_" .. el, "[ 1 ] ▲", Vector3.new(0.3, 2.0, 4.5), Vector3.new(tlX + 23.6, floorY + 17.5, eZ), Enum.NormalId.Left, Color3.fromRGB(20, 20, 25), Color3.fromRGB(255, 140, 0))
    end
    PartBuilder.makeSign(topLift, "Sign", "ลิฟ\nLIFT", Vector3.new(14, 4.0, 0.4), Vector3.new(tlX, floorY + 14, -110 + 0.3), Enum.NormalId.Back, Color3.fromRGB(30, 40, 50), Color3.fromRGB(255, 255, 255))

    -- 4.2 ทางเข้าออกด้านบนกลาง: **ไม่มีขอบทางเข้าออก (OPEN SEAMLESS PASSAGE)**
    local topEntrance = Instance.new("Model")
    topEntrance.Name = "TopEntrance_Center_Open"
    topEntrance.Parent = topCore
    PartBuilder.makePart(topEntrance, "Floor", Vector3.new(48, 0.1, coreDepth), CFrame.new(0, floorY + 0.06, topZ), Color3.fromRGB(230, 225, 215), Enum.Material.SmoothPlastic)
    -- โล่งสนิท ไม่มีขอบกำแพงกั้นทางเข้า-ออก เดินทะลุได้ 100%!
    PartBuilder.makeSign(topEntrance, "Sign", "ทางเข้าออก\nENTRANCE / EXIT (OPEN)", Vector3.new(22, 4.0, 0.4), Vector3.new(0, floorY + 0.12, topZ), Enum.NormalId.Top, Color3.fromRGB(120, 30, 40), Color3.fromRGB(255, 255, 255))

    -- 4.3 บันไดด้านบนขวา: **บันไดวนซ้าย & ทางขึ้นหันหน้าไปทางทิศตะวันตก (-X) เข้าหาลิฟต์!**
    local topStairs = Instance.new("Model")
    topStairs.Name = "TopStairs_Right_TurnLeft"
    topStairs.Parent = topCore

    local trX = 47
    PartBuilder.makePart(topStairs, "Floor", Vector3.new(46, 0.1, coreDepth), CFrame.new(trX, floorY + 0.06, topZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(topStairs, "Wall_Back", Vector3.new(46, wallH, wallThick), CFrame.new(trX, floorY + wallH/2, topZ - coreDepth/2), wallColor, wallMaterial)
    PartBuilder.makePart(topStairs, "Wall_East", Vector3.new(wallThick, wallH, coreDepth), CFrame.new(trX + 23, floorY + wallH/2, topZ), wallColor, wallMaterial)
    -- ผนังซ้ายเปิดโล่ง หันหน้าเข้าหาลิฟต์โดยตรง!

    -- บันไดวนซ้าย (Left-Turning Switchback):
    -- ช่วงที่ 1: เดินเข้าจากทางซ้าย (-X) หันหน้าทางขวา หรือก้าวขึ้นฝั่งขวา
    for s = 1, 9 do
        PartBuilder.makePart(topStairs, "Step1_" .. s, Vector3.new(10.0, 1.2, 2.4), CFrame.new(trX + 10, floorY + (s * 1.2), (topZ + 12) - (s * 2.4)), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    end
    -- ชานพักกึ่งกลาง: เลี้ยวซ้าย 180 องศา!
    PartBuilder.makePart(topStairs, "MidLanding", Vector3.new(36, 1.2, 10.0), CFrame.new(trX, floorY + 11.5, topZ - 12), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    -- ช่วงที่ 2: วนซ้ายกลับขึ้นชั้น 2
    for s = 1, 9 do
        PartBuilder.makePart(topStairs, "Step2_" .. s, Vector3.new(10.0, 1.2, 2.4), CFrame.new(trX - 10, floorY + 11.5 + (s * 1.2), (topZ - 7) + (s * 2.4)), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    end
    PartBuilder.makeSign(topStairs, "Sign", "บันไดวนซ้าย (หันหน้าหาลิฟต์)\nSTAIRS (FACES LIFT)", Vector3.new(18, 4.0, 0.4), Vector3.new(trX, floorY + 14, -110 + 0.3), Enum.NormalId.Back, PartBuilder.COLORS.orange, Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 5. ด้านล่าง (FRONT CORE - 2X SCALE)
    -- บันได (ซ้าย - หันหน้าไปหาลิฟต์ + วนซ้าย) | ทางเข้าออก (กลาง - ไม่มีขอบ) | ลิฟต์ (ขวา - หันหน้าไปหาบันได)
    ------------------------------------------------------------------
    local bottomCore = Instance.new("Folder")
    bottomCore.Name = "BottomCirculationCore"
    bottomCore.Parent = floor1

    local botZ = 127 -- Z ตำแหน่งคอร์ล่าง

    -- 5.1 บันไดด้านล่างซ้าย: **บันไดวนซ้าย & ทางขึ้นหันหน้าไปทางทิศตะวันออก (+X) เข้าหาลิฟต์!**
    local botStairs = Instance.new("Model")
    botStairs.Name = "BottomStairs_Left_TurnLeft"
    botStairs.Parent = bottomCore

    local blCoreX = -47
    PartBuilder.makePart(botStairs, "Floor", Vector3.new(46, 0.1, coreDepth), CFrame.new(blCoreX, floorY + 0.06, botZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(botStairs, "Wall_Front", Vector3.new(46, wallH, wallThick), CFrame.new(blCoreX, floorY + wallH/2, botZ + coreDepth/2), wallColor, wallMaterial)
    PartBuilder.makePart(botStairs, "Wall_West", Vector3.new(wallThick, wallH, coreDepth), CFrame.new(blCoreX - 23, floorY + wallH/2, botZ), wallColor, wallMaterial)
    -- ผนังขวาเปิดโล่ง หันหน้าเข้าหาลิฟต์ทางขวา (+X)!

    -- บันไดวนซ้าย:
    -- ช่วงที่ 1: ก้าวขึ้นฝั่งซ้าย
    for s = 1, 9 do
        PartBuilder.makePart(botStairs, "Step1_" .. s, Vector3.new(10.0, 1.2, 2.4), CFrame.new(blCoreX - 10, floorY + (s * 1.2), (botZ - 12) + (s * 2.4)), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    end
    -- ชานพักกึ่งกลาง: เลี้ยวซ้าย 180 องศา!
    PartBuilder.makePart(botStairs, "MidLanding", Vector3.new(36, 1.2, 10.0), CFrame.new(blCoreX, floorY + 11.5, botZ + 12), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    -- ช่วงที่ 2: วนซ้ายกลับขึ้นชั้น 2
    for s = 1, 9 do
        PartBuilder.makePart(botStairs, "Step2_" .. s, Vector3.new(10.0, 1.2, 2.4), CFrame.new(blCoreX + 10, floorY + 11.5 + (s * 1.2), (botZ + 7) - (s * 2.4)), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    end
    PartBuilder.makeSign(botStairs, "Sign", "บันไดวนซ้าย (หันหน้าหาลิฟต์)\nSTAIRS (FACES LIFT)", Vector3.new(18, 4.0, 0.4), Vector3.new(blCoreX, floorY + 14, 110 - 0.3), Enum.NormalId.Back, PartBuilder.COLORS.orange, Color3.fromRGB(255, 255, 255))

    -- 5.2 ทางเข้าออกด้านล่างกลาง: **ไม่มีขอบทางเข้าออก (OPEN SEAMLESS PASSAGE)**
    local botEntrance = Instance.new("Model")
    botEntrance.Name = "BottomEntrance_Center_Open"
    botEntrance.Parent = bottomCore
    PartBuilder.makePart(botEntrance, "Floor", Vector3.new(48, 0.1, coreDepth), CFrame.new(0, floorY + 0.06, botZ), Color3.fromRGB(230, 225, 215), Enum.Material.SmoothPlastic)
    -- โล่งสนิท ไม่มีขอบทางเข้า-ออก เดินทะลุได้ 100%!
    PartBuilder.makeSign(botEntrance, "Sign", "ทางเข้าออก\nENTRANCE / EXIT (OPEN)", Vector3.new(22, 4.0, 0.4), Vector3.new(0, floorY + 0.12, botZ), Enum.NormalId.Top, Color3.fromRGB(120, 30, 40), Color3.fromRGB(255, 255, 255))

    -- 5.3 ลิฟต์ด้านล่างขวา: **ประตูลิฟต์หันหน้าไปทางทิศตะวันตก (-X) เข้าหาบันได!**
    local botLift = Instance.new("Model")
    botLift.Name = "BottomElevators_Right"
    botLift.Parent = bottomCore

    local brCoreX = 47
    PartBuilder.makePart(botLift, "Floor", Vector3.new(46, 0.1, coreDepth), CFrame.new(brCoreX, floorY + 0.06, botZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(botLift, "Wall_Front", Vector3.new(46, wallH, wallThick), CFrame.new(brCoreX, floorY + wallH/2, botZ + coreDepth/2), wallColor, wallMaterial)
    PartBuilder.makePart(botLift, "Wall_East", Vector3.new(wallThick, wallH, coreDepth), CFrame.new(brCoreX + 23, floorY + wallH/2, botZ), wallColor, wallMaterial)

    -- ผนังฝั่งซ้าย (-X) หันหน้าเข้าหาทางเดินและบันได -> ติดตั้งประตูลิฟต์ 2 ตัวหันหน้าไปทางซ้าย (-X)!
    PartBuilder.makePart(botLift, "Wall_West_Top", Vector3.new(wallThick, 6.0, coreDepth), CFrame.new(brCoreX - 23, floorY + wallH - 3.0, botZ), wallColor, wallMaterial)
    for el = 1, 2 do
        local eZ = (botZ - 9) + ((el - 1) * 18)
        PartBuilder.makePart(botLift, "LiftDoor_" .. el, Vector3.new(0.6, 16.0, 11.0), CFrame.new(brCoreX - 23.3, floorY + 8.0, eZ), PartBuilder.COLORS.steel, Enum.Material.Metal)
        PartBuilder.makeSign(botLift, "Ind_" .. el, "[ 1 ] ▲", Vector3.new(0.3, 2.0, 4.5), Vector3.new(brCoreX - 23.6, floorY + 17.5, eZ), Enum.NormalId.Right, Color3.fromRGB(20, 20, 25), Color3.fromRGB(255, 140, 0))
    end
    PartBuilder.makeSign(botLift, "Sign", "ลิฟ\nLIFT", Vector3.new(14, 4.0, 0.4), Vector3.new(brCoreX, floorY + 14, 110 - 0.3), Enum.NormalId.Back, Color3.fromRGB(30, 40, 50), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 6. กำแพงรอบนอกด้านซ้ายสุด (Outer Wall West)
    ------------------------------------------------------------------
    PartBuilder.makePart(floor1, "OuterWall_West_2X", Vector3.new(wallThick, wallH, 88), CFrame.new(-140, floorY + wallH/2, 0), wallColor, wallMaterial)

    ------------------------------------------------------------------
    -- 7. ระบบไฟส่องสว่างครอบคลุมพื้นที่ 2 เท่า (Lighting Grid)
    ------------------------------------------------------------------
    local lights = Instance.new("Folder")
    lights.Name = "Lights_2X"
    lights.Parent = floor1

    local lightPoints = {
        Vector3.new(0, floorY + wallH - 2, 0),
        Vector3.new(-70, floorY + wallH - 2, 0),
        Vector3.new(70, floorY + wallH - 2, 0),
        Vector3.new(0, floorY + wallH - 2, topZ),
        Vector3.new(0, floorY + wallH - 2, botZ),
        Vector3.new(tlX, floorY + wallH - 2, topZ),
        Vector3.new(trX, floorY + wallH - 2, topZ),
        Vector3.new(blCoreX, floorY + wallH - 2, botZ),
        Vector3.new(brCoreX, floorY + wallH - 2, botZ),
    }
    for idx, pos in ipairs(lightPoints) do
        PartBuilder.addPointLight(lights, "Light_2X_" .. idx, pos, Color3.fromRGB(255, 250, 240), 55, 1.6)
    end

    ------------------------------------------------------------------
    -- 8. จุดเกิดผู้เล่น (Spawn Location)
    ------------------------------------------------------------------
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "PlayerSpawn_F1_2X"
    spawn.Size = Vector3.new(14, 0.5, 14)
    spawn.CFrame = CFrame.new(0, floorY + 0.3, 0)
    spawn.Color = Color3.fromRGB(0, 220, 255)
    spawn.Material = Enum.Material.Neon
    spawn.Anchored = true
    spawn.CanCollide = false
    spawn.Transparency = 0.5
    spawn.Parent = floor1

    print("=========================================================")
    print("🏢 [Floor 1 - 2X Scale Built] ขยายสเกล 2 เท่า + ปิดตายทุกห้อง + ลิฟต์/บันไดหันหน้าเข้าหากัน + บันไดวนซ้าย + ไม่มีขอบทางเข้าออก สำเร็จสมบูรณ์!")
    print("=========================================================")
end

return Floor1_Lobby
