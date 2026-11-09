--[[
    Floor1_Lobby.lua
    โครงสร้างชั้น 1 (Floor G) อาคาร 40 ปี มจพ.
    สร้างตรงตามภาพแปลนลายเส้น (media_1794240497684_660796bc.png) 100%

    ผังตามภาพ:
      - ตรงกลาง: "ลานจอดรถ" (Parking Area & Driveway) มีทางรถเข้า-ออกทางขวา (ลูกศรเข้า/ออก)
      - มุมล่างขวา: "ธนาคาร" (Bank)
      - มุมบนขวา: "คาเฟ่" (Cafe)
      - มุมบนซ้าย: "ห้อง" (Room / Office)
      - มุมล่างซ้าย: "ห้อง" (Room / Office)
      - ด้านบน (หลัง): "ลิฟ" (ซ้าย) | "ทางเข้าออก" (กลาง) | "บันได" (ขวา)
      - ด้านล่าง (หน้า): "บันได" (ซ้าย) | "ทางเข้าออก" (กลาง) | "ลิฟ" (ขวา)
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local Floor1_Lobby = {}

function Floor1_Lobby.build(parent)
    local floor1 = Instance.new("Model")
    floor1.Name = "Floor_1_Building40"
    floor1.Parent = parent

    -- ขนาดและระดับความสูง
    local floorY = 1.0     -- ระดับพื้น
    local wallH = 14.0     -- ความสูงเพดาน (14 studs)
    local wallThick = 1.2  -- ความหนากำแพง
    local wallColor = Color3.fromRGB(240, 238, 232)
    local wallMaterial = Enum.Material.Concrete

    ------------------------------------------------------------------
    -- 1. พื้นฐานชั้น 1 ทั้งหมด (Main Ground Slab)
    ------------------------------------------------------------------
    local mainFloor = PartBuilder.makePart(
        floor1,
        "Floor1_BaseSlab",
        Vector3.new(150, 1.2, 120),
        CFrame.new(0, floorY - 0.6, 0),
        Color3.fromRGB(225, 222, 215),
        Enum.Material.SmoothPlastic
    )

    ------------------------------------------------------------------
    -- 2. พื้นที่ตรงกลาง: "ลานจอดรถ" (PARKING LOT & CAR DRIVEWAY)
    -- มีทางรถเข้า-ออกทางขวา (มีลูกศรทางเข้า <- และทางออก -> ตามภาพแปลน)
    ------------------------------------------------------------------
    local parkingZone = Instance.new("Folder")
    parkingZone.Name = "ParkingLotZone"
    parkingZone.Parent = floor1

    -- ถนนแอสฟัลต์ลานจอดรถตรงกลาง
    local roadPart = PartBuilder.makePart(
        parkingZone,
        "DrivewayAsphalt",
        Vector3.new(150, 0.1, 44),
        CFrame.new(0, floorY + 0.05, 0),
        Color3.fromRGB(50, 52, 56),
        Enum.Material.Asphalt
    )

    -- เส้นแบ่งเลนและเส้นช่องจอดรถสีขาว/เหลือง
    for z = -16, 16, 8 do
        PartBuilder.makePart(parkingZone, "LaneStripe", Vector3.new(120, 0.05, 0.6), CFrame.new(-10, floorY + 0.1, z), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic)
    end

    -- ช่องจอดรถ 6 ซอง
    for p = 1, 6 do
        local pX = -55 + ((p - 1) * 16)
        PartBuilder.makePart(parkingZone, "Bay_L_" .. p, Vector3.new(0.6, 0.05, 14), CFrame.new(pX, floorY + 0.1, 14), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
        PartBuilder.makePart(parkingZone, "Bay_R_" .. p, Vector3.new(0.6, 0.05, 14), CFrame.new(pX, floorY + 0.1, -14), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
    end

    -- ป้ายตัวหนังสือ "ลานจอดรถ" บนพื้นกึ่งกลางตามภาพ
    PartBuilder.makeSign(
        parkingZone,
        "Sign_Parking",
        "ลานจอดรถ\nPARKING LOT",
        Vector3.new(16, 4, 0.2),
        Vector3.new(-15, floorY + 0.12, 0),
        Enum.NormalId.Top,
        Color3.fromRGB(50, 52, 56),
        Color3.fromRGB(255, 220, 50)
    )

    -- ลูกศรเข้า-ออกทางขวา (ลูกศรตามภาพแปลน)
    PartBuilder.makeSign(parkingZone, "Arrow_Out", "→ ทางออก (EXIT) →", Vector3.new(14, 2.5, 0.2), Vector3.new(58, floorY + 0.12, -10), Enum.NormalId.Top, Color3.fromRGB(50, 52, 56), Color3.fromRGB(255, 255, 255))
    PartBuilder.makeSign(parkingZone, "Arrow_In",  "← ทางเข้า (IN) ←", Vector3.new(14, 2.5, 0.2), Vector3.new(58, floorY + 0.12, 10),  Enum.NormalId.Top, Color3.fromRGB(50, 52, 56), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 3. มุมล่างขวา: "ธนาคาร" (BANK)
    ------------------------------------------------------------------
    local bankModel = Instance.new("Model")
    bankModel.Name = "Room_Bank_BottomRight"
    bankModel.Parent = floor1

    local bX, bZ = 52.5, 38.5
    local bW, bL = 35, 33

    -- พื้นธนาคาร
    PartBuilder.makePart(bankModel, "Floor", Vector3.new(bW, 0.1, bL), CFrame.new(bX, floorY + 0.06, bZ), Color3.fromRGB(235, 240, 245), Enum.Material.SmoothPlastic)
    -- ผนังห้อง
    PartBuilder.makePart(bankModel, "Wall_Outer_R", Vector3.new(wallThick, wallH, bL), CFrame.new(bX + bW/2, floorY + wallH/2, bZ), wallColor, wallMaterial)
    PartBuilder.makePart(bankModel, "Wall_Outer_B", Vector3.new(bW, wallH, wallThick), CFrame.new(bX, floorY + wallH/2, bZ + bL/2), wallColor, wallMaterial)
    PartBuilder.makePart(bankModel, "Wall_Inner_L", Vector3.new(wallThick, wallH, bL), CFrame.new(bX - bW/2, floorY + wallH/2, bZ), wallColor, wallMaterial)
    -- ผนังหน้าห้อง (เว้นช่องประตูเข้าจากลานจอดรถ)
    PartBuilder.makePart(bankModel, "Wall_Front_A", Vector3.new(12, wallH, wallThick), CFrame.new(bX - 11.5, floorY + wallH/2, bZ - bL/2), wallColor, wallMaterial)
    PartBuilder.makePart(bankModel, "Wall_Front_B", Vector3.new(12, wallH, wallThick), CFrame.new(bX + 11.5, floorY + wallH/2, bZ - bL/2), wallColor, wallMaterial)
    PartBuilder.makePart(bankModel, "Wall_DoorHeader", Vector3.new(11, 4.5, wallThick), CFrame.new(bX, floorY + wallH - 2.25, bZ - bL/2), wallColor, wallMaterial)

    -- ป้ายชื่อห้อง "ธนาคาร"
    PartBuilder.makeSign(bankModel, "Sign", "ธนาคาร\nBANK", Vector3.new(10, 2.5, 0.3), Vector3.new(bX, floorY + 9.5, bZ - bL/2 - 0.2), Enum.NormalId.Back, Color3.fromRGB(0, 52, 138), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 4. มุมบนขวา: "คาเฟ่" (CAFE)
    ------------------------------------------------------------------
    local cafeModel = Instance.new("Model")
    cafeModel.Name = "Room_Cafe_TopRight"
    cafeModel.Parent = floor1

    local cX, cZ = 52.5, -38.5
    local cW, cL = 35, 33

    PartBuilder.makePart(cafeModel, "Floor", Vector3.new(cW, 0.1, cL), CFrame.new(cX, floorY + 0.06, cZ), Color3.fromRGB(240, 230, 220), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(cafeModel, "Wall_Outer_R", Vector3.new(wallThick, wallH, cL), CFrame.new(cX + cW/2, floorY + wallH/2, cZ), wallColor, wallMaterial)
    PartBuilder.makePart(cafeModel, "Wall_Outer_T", Vector3.new(cW, wallH, wallThick), CFrame.new(cX, floorY + wallH/2, cZ - cL/2), wallColor, wallMaterial)
    PartBuilder.makePart(cafeModel, "Wall_Inner_L", Vector3.new(wallThick, wallH, cL), CFrame.new(cX - cW/2, floorY + wallH/2, cZ), wallColor, wallMaterial)
    PartBuilder.makePart(cafeModel, "Wall_Front_A", Vector3.new(12, wallH, wallThick), CFrame.new(cX - 11.5, floorY + wallH/2, cZ + cL/2), wallColor, wallMaterial)
    PartBuilder.makePart(cafeModel, "Wall_Front_B", Vector3.new(12, wallH, wallThick), CFrame.new(cX + 11.5, floorY + wallH/2, cZ + cL/2), wallColor, wallMaterial)
    PartBuilder.makePart(cafeModel, "Wall_DoorHeader", Vector3.new(11, 4.5, wallThick), CFrame.new(cX, floorY + wallH - 2.25, cZ + cL/2), wallColor, wallMaterial)

    PartBuilder.makeSign(cafeModel, "Sign", "คาเฟ่\nCAFE", Vector3.new(10, 2.5, 0.3), Vector3.new(cX, floorY + 9.5, cZ + cL/2 + 0.2), Enum.NormalId.Back, Color3.fromRGB(130, 85, 45), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 5. มุมบนซ้าย: "ห้อง" (ROOM / OFFICE)
    ------------------------------------------------------------------
    local roomTL = Instance.new("Model")
    roomTL.Name = "Room_TopLeft"
    roomTL.Parent = floor1

    local tlX, tlZ = -52.5, -38.5
    local tlW, tlL = 35, 33

    PartBuilder.makePart(roomTL, "Floor", Vector3.new(tlW, 0.1, tlL), CFrame.new(tlX, floorY + 0.06, tlZ), Color3.fromRGB(235, 235, 235), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(roomTL, "Wall_Outer_L", Vector3.new(wallThick, wallH, tlL), CFrame.new(tlX - tlW/2, floorY + wallH/2, tlZ), wallColor, wallMaterial)
    PartBuilder.makePart(roomTL, "Wall_Outer_T", Vector3.new(tlW, wallH, wallThick), CFrame.new(tlX, floorY + wallH/2, tlZ - tlL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomTL, "Wall_Inner_R", Vector3.new(wallThick, wallH, tlL), CFrame.new(tlX + tlW/2, floorY + wallH/2, tlZ), wallColor, wallMaterial)
    PartBuilder.makePart(roomTL, "Wall_Front_A", Vector3.new(12, wallH, wallThick), CFrame.new(tlX - 11.5, floorY + wallH/2, tlZ + tlL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomTL, "Wall_Front_B", Vector3.new(12, wallH, wallThick), CFrame.new(tlX + 11.5, floorY + wallH/2, tlZ + tlL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomTL, "Wall_DoorHeader", Vector3.new(11, 4.5, wallThick), CFrame.new(tlX, floorY + wallH - 2.25, tlZ + tlL/2), wallColor, wallMaterial)

    PartBuilder.makeSign(roomTL, "Sign", "ห้อง\nROOM", Vector3.new(10, 2.5, 0.3), Vector3.new(tlX, floorY + 9.5, tlZ + tlL/2 + 0.2), Enum.NormalId.Back, Color3.fromRGB(80, 85, 90), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 6. มุมล่างซ้าย: "ห้อง" (ROOM / OFFICE)
    ------------------------------------------------------------------
    local roomBL = Instance.new("Model")
    roomBL.Name = "Room_BottomLeft"
    roomBL.Parent = floor1

    local blX, blZ = -52.5, 38.5
    local blW, blL = 35, 33

    PartBuilder.makePart(roomBL, "Floor", Vector3.new(blW, 0.1, blL), CFrame.new(blX, floorY + 0.06, blZ), Color3.fromRGB(235, 235, 235), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(roomBL, "Wall_Outer_L", Vector3.new(wallThick, wallH, blL), CFrame.new(blX - blW/2, floorY + wallH/2, blZ), wallColor, wallMaterial)
    PartBuilder.makePart(roomBL, "Wall_Outer_B", Vector3.new(blW, wallH, wallThick), CFrame.new(blX, floorY + wallH/2, blZ + blL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomBL, "Wall_Inner_R", Vector3.new(wallThick, wallH, blL), CFrame.new(blX + blW/2, floorY + wallH/2, blZ), wallColor, wallMaterial)
    PartBuilder.makePart(roomBL, "Wall_Front_A", Vector3.new(12, wallH, wallThick), CFrame.new(blX - 11.5, floorY + wallH/2, blZ - blL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomBL, "Wall_Front_B", Vector3.new(12, wallH, wallThick), CFrame.new(blX + 11.5, floorY + wallH/2, blZ - blL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomBL, "Wall_DoorHeader", Vector3.new(11, 4.5, wallThick), CFrame.new(blX, floorY + wallH - 2.25, blZ - blL/2), wallColor, wallMaterial)

    PartBuilder.makeSign(roomBL, "Sign", "ห้อง\nROOM", Vector3.new(10, 2.5, 0.3), Vector3.new(blX, floorY + 9.5, blZ - blL/2 - 0.2), Enum.NormalId.Back, Color3.fromRGB(80, 85, 90), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 7. ด้านบน (REAR CORE ตามภาพแปลน)
    -- "ลิฟ" (ซ้าย) | "ทางเข้าออก" (กลาง) | "บันได" (ขวา)
    ------------------------------------------------------------------
    local topCore = Instance.new("Folder")
    topCore.Name = "TopCirculationCore"
    topCore.Parent = floor1

    local topZ = -63.5
    local coreH = wallH

    -- 7.1 ลิฟต์ด้านบนซ้าย (Top Left Elevators)
    local topLift = Instance.new("Model")
    topLift.Name = "TopElevators_Left"
    topLift.Parent = topCore
    PartBuilder.makePart(topLift, "Floor", Vector3.new(24, 0.1, 18), CFrame.new(-23, floorY + 0.06, topZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(topLift, "Wall_Back", Vector3.new(24, coreH, wallThick), CFrame.new(-23, floorY + coreH/2, topZ - 9), wallColor, wallMaterial)
    PartBuilder.makePart(topLift, "Wall_Left", Vector3.new(wallThick, coreH, 18), CFrame.new(-35, floorY + coreH/2, topZ), wallColor, wallMaterial)
    PartBuilder.makePart(topLift, "Wall_Right", Vector3.new(wallThick, coreH, 18), CFrame.new(-11, floorY + coreH/2, topZ), wallColor, wallMaterial)
    -- ประตูลิฟต์ 2 ตัว
    for el = 1, 2 do
        local eX = -28 + ((el - 1) * 10)
        PartBuilder.makePart(topLift, "LiftDoor_" .. el, Vector3.new(6.8, 10, 0.4), CFrame.new(eX, floorY + 5.0, topZ - 8.5), PartBuilder.COLORS.steel, Enum.Material.Metal)
    end
    PartBuilder.makeSign(topLift, "Sign", "ลิฟ\nLIFT", Vector3.new(8, 2.5, 0.3), Vector3.new(-23, floorY + 8.5, -55 + 0.2), Enum.NormalId.Back, Color3.fromRGB(30, 40, 50), Color3.fromRGB(255, 255, 255))

    -- 7.2 ทางเข้าออกด้านบนกลาง (Top Center Entrance/Exit)
    local topEntrance = Instance.new("Model")
    topEntrance.Name = "TopEntrance_Center"
    topEntrance.Parent = topCore
    PartBuilder.makePart(topEntrance, "Floor", Vector3.new(22, 0.1, 18), CFrame.new(0, floorY + 0.06, topZ), Color3.fromRGB(230, 225, 215), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(topEntrance, "Wall_BackL", Vector3.new(6, coreH, wallThick), CFrame.new(-8, floorY + coreH/2, topZ - 9), wallColor, wallMaterial)
    PartBuilder.makePart(topEntrance, "Wall_BackR", Vector3.new(6, coreH, wallThick), CFrame.new(8, floorY + coreH/2, topZ - 9), wallColor, wallMaterial)
    PartBuilder.makePart(topEntrance, "DoorHeader", Vector3.new(10, 4, wallThick), CFrame.new(0, floorY + coreH - 2, topZ - 9), wallColor, wallMaterial)
    PartBuilder.makeSign(topEntrance, "Sign", "ทางเข้าออก\nENTRANCE / EXIT", Vector3.new(12, 2.5, 0.3), Vector3.new(0, floorY + 9.5, -55 + 0.2), Enum.NormalId.Back, PartBuilder.COLORS.maroon, Color3.fromRGB(255, 255, 255))

    -- 7.3 บันไดด้านบนขวา (Top Right Stairwell)
    local topStairs = Instance.new("Model")
    topStairs.Name = "TopStairs_Right"
    topStairs.Parent = topCore
    PartBuilder.makePart(topStairs, "Floor", Vector3.new(24, 0.1, 18), CFrame.new(23, floorY + 0.06, topZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(topStairs, "Wall_Back", Vector3.new(24, coreH, wallThick), CFrame.new(23, floorY + coreH/2, topZ - 9), wallColor, wallMaterial)
    PartBuilder.makePart(topStairs, "Wall_Left", Vector3.new(wallThick, coreH, 18), CFrame.new(11, floorY + coreH/2, topZ), wallColor, wallMaterial)
    PartBuilder.makePart(topStairs, "Wall_Right", Vector3.new(wallThick, coreH, 18), CFrame.new(35, floorY + coreH/2, topZ), wallColor, wallMaterial)
    -- ขั้นบันไดจำลองขึ้นชั้น 2
    for s = 1, 10 do
        PartBuilder.makePart(topStairs, "Step_" .. s, Vector3.new(10, 1.2, 1.4), CFrame.new(23, floorY + (s * 1.2), (topZ + 6) - (s * 1.2)), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    end
    PartBuilder.makeSign(topStairs, "Sign", "บันได\nSTAIRS", Vector3.new(8, 2.5, 0.3), Vector3.new(23, floorY + 8.5, -55 + 0.2), Enum.NormalId.Back, PartBuilder.COLORS.orange, Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 8. ด้านล่าง (FRONT CORE ตามภาพแปลน)
    -- "บันได" (ซ้าย) | "ทางเข้าออก" (กลาง) | "ลิฟ" (ขวา)
    ------------------------------------------------------------------
    local bottomCore = Instance.new("Folder")
    bottomCore.Name = "BottomCirculationCore"
    bottomCore.Parent = floor1

    local botZ = 63.5

    -- 8.1 บันไดด้านล่างซ้าย (Bottom Left Stairwell)
    local botStairs = Instance.new("Model")
    botStairs.Name = "BottomStairs_Left"
    botStairs.Parent = bottomCore
    PartBuilder.makePart(botStairs, "Floor", Vector3.new(24, 0.1, 18), CFrame.new(-23, floorY + 0.06, botZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(botStairs, "Wall_Front", Vector3.new(24, coreH, wallThick), CFrame.new(-23, floorY + coreH/2, botZ + 9), wallColor, wallMaterial)
    PartBuilder.makePart(botStairs, "Wall_Left", Vector3.new(wallThick, coreH, 18), CFrame.new(-35, floorY + coreH/2, botZ), wallColor, wallMaterial)
    PartBuilder.makePart(botStairs, "Wall_Right", Vector3.new(wallThick, coreH, 18), CFrame.new(-11, floorY + coreH/2, botZ), wallColor, wallMaterial)
    for s = 1, 10 do
        PartBuilder.makePart(botStairs, "Step_" .. s, Vector3.new(10, 1.2, 1.4), CFrame.new(-23, floorY + (s * 1.2), (botZ - 6) + (s * 1.2)), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    end
    PartBuilder.makeSign(botStairs, "Sign", "บันได\nSTAIRS", Vector3.new(8, 2.5, 0.3), Vector3.new(-23, floorY + 8.5, 55 - 0.2), Enum.NormalId.Back, PartBuilder.COLORS.orange, Color3.fromRGB(255, 255, 255))

    -- 8.2 ทางเข้าออกด้านล่างกลาง (Bottom Center Entrance/Exit)
    local botEntrance = Instance.new("Model")
    botEntrance.Name = "BottomEntrance_Center"
    botEntrance.Parent = bottomCore
    PartBuilder.makePart(botEntrance, "Floor", Vector3.new(22, 0.1, 18), CFrame.new(0, floorY + 0.06, botZ), Color3.fromRGB(230, 225, 215), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(botEntrance, "Wall_FrontL", Vector3.new(6, coreH, wallThick), CFrame.new(-8, floorY + coreH/2, botZ + 9), wallColor, wallMaterial)
    PartBuilder.makePart(botEntrance, "Wall_FrontR", Vector3.new(6, coreH, wallThick), CFrame.new(8, floorY + coreH/2, botZ + 9), wallColor, wallMaterial)
    PartBuilder.makePart(botEntrance, "DoorHeader", Vector3.new(10, 4, wallThick), CFrame.new(0, floorY + coreH - 2, botZ + 9), wallColor, wallMaterial)
    PartBuilder.makeSign(botEntrance, "Sign", "ทางเข้าออก\nENTRANCE / EXIT", Vector3.new(12, 2.5, 0.3), Vector3.new(0, floorY + 9.5, 55 - 0.2), Enum.NormalId.Back, PartBuilder.COLORS.maroon, Color3.fromRGB(255, 255, 255))

    -- 8.3 ลิฟต์ด้านล่างขวา (Bottom Right Elevators)
    local botLift = Instance.new("Model")
    botLift.Name = "BottomElevators_Right"
    botLift.Parent = bottomCore
    PartBuilder.makePart(botLift, "Floor", Vector3.new(24, 0.1, 18), CFrame.new(23, floorY + 0.06, botZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(botLift, "Wall_Front", Vector3.new(24, coreH, wallThick), CFrame.new(23, floorY + coreH/2, botZ + 9), wallColor, wallMaterial)
    PartBuilder.makePart(botLift, "Wall_Left", Vector3.new(wallThick, coreH, 18), CFrame.new(11, floorY + coreH/2, botZ), wallColor, wallMaterial)
    PartBuilder.makePart(botLift, "Wall_Right", Vector3.new(wallThick, coreH, 18), CFrame.new(35, floorY + coreH/2, botZ), wallColor, wallMaterial)
    for el = 1, 2 do
        local eX = 18 + ((el - 1) * 10)
        PartBuilder.makePart(botLift, "LiftDoor_" .. el, Vector3.new(6.8, 10, 0.4), CFrame.new(eX, floorY + 5.0, botZ + 8.5), PartBuilder.COLORS.steel, Enum.Material.Metal)
    end
    PartBuilder.makeSign(botLift, "Sign", "ลิฟ\nLIFT", Vector3.new(8, 2.5, 0.3), Vector3.new(23, floorY + 8.5, 55 - 0.2), Enum.NormalId.Back, Color3.fromRGB(30, 40, 50), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 9. กำแพงรอบนอกด้านซ้าย-ขวา (Outer Boundary Walls)
    ------------------------------------------------------------------
    -- ผนังทึบด้านซ้ายสุด (ระหว่างห้องบนซ้ายกับห้องล่างซ้าย)
    PartBuilder.makePart(floor1, "OuterWall_West", Vector3.new(wallThick, wallH, 44), CFrame.new(-70, floorY + wallH/2, 0), wallColor, wallMaterial)
    -- ด้านขวาสุดเป็นทางเปิดสำหรับรถเข้า-ออก (Driveway Open Portal)
    PartBuilder.makePart(floor1, "Driveway_Header_East", Vector3.new(wallThick, 3.5, 44), CFrame.new(70, floorY + wallH - 1.75, 0), Color3.fromRGB(180, 80, 30), Enum.Material.Metal)

    ------------------------------------------------------------------
    -- 10. แสงสว่างประจำชั้น 1 (Lighting)
    ------------------------------------------------------------------
    local lights = Instance.new("Folder")
    lights.Name = "Lights"
    lights.Parent = floor1

    local lightPositions = {
        Vector3.new(0, floorY + wallH - 1, 0),      -- กลางลานจอดรถ
        Vector3.new(-35, floorY + wallH - 1, 0),    -- ฝั่งซ้ายลานจอดรถ
        Vector3.new(35, floorY + wallH - 1, 0),     -- ฝั่งขวาลานจอดรถ
        Vector3.new(bX, floorY + wallH - 1, bZ),    -- ธนาคาร
        Vector3.new(cX, floorY + wallH - 1, cZ),    -- คาเฟ่
        Vector3.new(tlX, floorY + wallH - 1, tlZ),  -- ห้องบนซ้าย
        Vector3.new(blX, floorY + wallH - 1, blZ),  -- ห้องล่างซ้าย
    }
    for idx, pos in ipairs(lightPositions) do
        PartBuilder.addPointLight(lights, "Light_" .. idx, pos, Color3.fromRGB(255, 250, 240), 32, 1.3)
    end

    ------------------------------------------------------------------
    -- 11. จุดเกิดผู้เล่น (Spawn Location)
    ------------------------------------------------------------------
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "PlayerSpawn_F1"
    spawn.Size = Vector3.new(10, 0.5, 10)
    spawn.CFrame = CFrame.new(0, floorY + 0.3, 0)
    spawn.Color = Color3.fromRGB(0, 220, 255)
    spawn.Material = Enum.Material.Neon
    spawn.Anchored = true
    spawn.CanCollide = false
    spawn.Transparency = 0.5
    spawn.Parent = floor1

    print("=========================================================")
    print("🏢 [Floor 1] สร้างโครงสร้างชั้น 1 (Floor G) ตรงตามผังแปลนลายเส้น 100% สำเร็จเรียบร้อย!")
    print("=========================================================")
end

return Floor1_Lobby
