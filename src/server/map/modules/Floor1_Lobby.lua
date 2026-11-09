--[[
    Floor1_Lobby.lua
    โครงสร้างและรายละเอียดชั้น 1 (Floor G) อาคาร 40 ปี มจพ.
    สร้างตรงตามภาพแปลนลายเส้น (media_1794240497684_660796bc.png) 100%
    
    ข้อกำหนดเฉพาะ:
      1. ลิฟต์หันหน้าเข้าหาบันได (Elevator doors face directly towards the stairs across the hallway)
      2. บันไดวนซ้าย (Left-turning switchback staircase with landing, turning left as you ascend)
      3. ลงรายละเอียดครบทุกห้อง:
         - มุมล่างขวา: ธนาคาร (Bangkok Bank) มีเคาน์เตอร์, ตู้ ATM, เก้าอี้รอรับบริการ
         - มุมบนขวา: คาเฟ่ (Cafe) มีเคาน์เตอร์กาแฟ, เครื่องชง Espresso, โต๊ะเก้าอี้คาเฟ่
         - มุมบนซ้าย: ห้องพัสดุและซ่อมบำรุง (Facilities & Storage)
         - มุมล่างซ้าย: ห้องศูนย์ควบคุมความปลอดภัย & กล้องวงจรปิด (Security & CCTV)
         - ตรงกลาง: ลานจอดรถ (Parking Lot) มีเสาค้ำคาดแถบเหลือง-ดำ, ซองจอดรถ, ขอบทาง, ลูกศรเข้า-ออก
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
    PartBuilder.makePart(
        floor1,
        "Floor1_BaseSlab",
        Vector3.new(150, 1.2, 120),
        CFrame.new(0, floorY - 0.6, 0),
        Color3.fromRGB(225, 222, 215),
        Enum.Material.SmoothPlastic
    )

    ------------------------------------------------------------------
    -- 2. พื้นที่ตรงกลาง: "ลานจอดรถ" (PARKING LOT & CAR DRIVEWAY)
    -- เสาโครงสร้างคาดแถบสะท้อนแสงเหลือง-ดำ + ซองจอดรถ + ลูกศรเข้า/ออกทางขวา
    ------------------------------------------------------------------
    local parkingZone = Instance.new("Folder")
    parkingZone.Name = "ParkingLotZone"
    parkingZone.Parent = floor1

    -- ถนนแอสฟัลต์ลานจอดรถ
    PartBuilder.makePart(
        parkingZone,
        "DrivewayAsphalt",
        Vector3.new(150, 0.1, 44),
        CFrame.new(0, floorY + 0.05, 0),
        Color3.fromRGB(48, 50, 54),
        Enum.Material.Asphalt
    )

    -- เส้นแบ่งเลนและเส้นจอดรถสีขาว/เหลือง
    for z = -16, 16, 8 do
        PartBuilder.makePart(parkingZone, "LaneStripe", Vector3.new(120, 0.05, 0.6), CFrame.new(-10, floorY + 0.1, z), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic)
    end

    -- ช่องจอดรถ 6 ซอง พร้อมแท่งคอนกรีตหยุดล้อ (Wheel Stops)
    for p = 1, 6 do
        local pX = -55 + ((p - 1) * 16)
        PartBuilder.makePart(parkingZone, "Bay_Top_" .. p, Vector3.new(0.6, 0.05, 14), CFrame.new(pX, floorY + 0.1, -14), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
        PartBuilder.makePart(parkingZone, "WheelStop_T_" .. p, Vector3.new(6, 0.6, 0.8), CFrame.new(pX + 8, floorY + 0.4, -20), Color3.fromRGB(230, 180, 40), Enum.Material.Concrete)

        PartBuilder.makePart(parkingZone, "Bay_Bot_" .. p, Vector3.new(0.6, 0.05, 14), CFrame.new(pX, floorY + 0.1, 14), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
        PartBuilder.makePart(parkingZone, "WheelStop_B_" .. p, Vector3.new(6, 0.6, 0.8), CFrame.new(pX + 8, floorY + 0.4, 20), Color3.fromRGB(230, 180, 40), Enum.Material.Concrete)
    end

    -- เสาโครงสร้างลานจอดรถ 4 ต้น คาดลายเฉียงเซฟตี้เหลือง-ดำ (Safety Warning Pillars)
    for _, px in ipairs({ -35, 35 }) do
        for _, pz in ipairs({ -18, 18 }) do
            local pil = PartBuilder.makePart(parkingZone, "ParkingPillar", Vector3.new(3.5, wallH, 3.5), CFrame.new(px, floorY + wallH/2, pz), Color3.fromRGB(210, 210, 215), Enum.Material.Concrete)
            -- แถบสะท้อนแสงเหลือง-ดำ
            PartBuilder.makePart(parkingZone, "HazardBand", Vector3.new(3.7, 3.0, 3.7), CFrame.new(px, floorY + 3.0, pz), Color3.fromRGB(235, 185, 30), Enum.Material.SmoothPlastic)
        end
    end

    -- ป้ายตัวหนังสือ "ลานจอดรถ" กึ่งกลาง
    PartBuilder.makeSign(
        parkingZone,
        "Sign_Parking",
        "ลานจอดรถ\nPARKING LOT",
        Vector3.new(16, 4, 0.2),
        Vector3.new(-15, floorY + 0.12, 0),
        Enum.NormalId.Top,
        Color3.fromRGB(48, 50, 54),
        Color3.fromRGB(255, 220, 50)
    )

    -- ลูกศรเข้า-ออกทางขวา (ตามภาพแปลนเป๊ะ 100%)
    PartBuilder.makeSign(parkingZone, "Arrow_Out", "→ ทางออก (EXIT) →", Vector3.new(14, 2.5, 0.2), Vector3.new(58, floorY + 0.12, -10), Enum.NormalId.Top, Color3.fromRGB(48, 50, 54), Color3.fromRGB(255, 255, 255))
    PartBuilder.makeSign(parkingZone, "Arrow_In",  "← ทางเข้า (IN) ←", Vector3.new(14, 2.5, 0.2), Vector3.new(58, floorY + 0.12, 10),  Enum.NormalId.Top, Color3.fromRGB(48, 50, 54), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 3. มุมล่างขวา: "ธนาคาร" (BANGKOK BANK - FULL DETAIL)
    ------------------------------------------------------------------
    local bankModel = Instance.new("Model")
    bankModel.Name = "Room_Bank_BottomRight"
    bankModel.Parent = floor1

    local bX, bZ = 52.5, 38.5
    local bW, bL = 35, 33

    PartBuilder.makePart(bankModel, "Floor", Vector3.new(bW, 0.1, bL), CFrame.new(bX, floorY + 0.06, bZ), Color3.fromRGB(235, 242, 248), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(bankModel, "Wall_Outer_R", Vector3.new(wallThick, wallH, bL), CFrame.new(bX + bW/2, floorY + wallH/2, bZ), wallColor, wallMaterial)
    PartBuilder.makePart(bankModel, "Wall_Outer_B", Vector3.new(bW, wallH, wallThick), CFrame.new(bX, floorY + wallH/2, bZ + bL/2), wallColor, wallMaterial)
    PartBuilder.makePart(bankModel, "Wall_Inner_L", Vector3.new(wallThick, wallH, bL), CFrame.new(bX - bW/2, floorY + wallH/2, bZ), wallColor, wallMaterial)
    PartBuilder.makePart(bankModel, "Wall_Front_A", Vector3.new(12, wallH, wallThick), CFrame.new(bX - 11.5, floorY + wallH/2, bZ - bL/2), wallColor, wallMaterial)
    PartBuilder.makePart(bankModel, "Wall_Front_B", Vector3.new(12, wallH, wallThick), CFrame.new(bX + 11.5, floorY + wallH/2, bZ - bL/2), wallColor, wallMaterial)
    PartBuilder.makePart(bankModel, "Wall_DoorHeader", Vector3.new(11, 4.5, wallThick), CFrame.new(bX, floorY + wallH - 2.25, bZ - bL/2), wallColor, wallMaterial)

    PartBuilder.makeSign(bankModel, "Sign", "ธนาคารกรุงเทพ สาขา มจพ.\nBANGKOK BANK", Vector3.new(14, 2.8, 0.3), Vector3.new(bX, floorY + 9.5, bZ - bL/2 - 0.2), Enum.NormalId.Back, Color3.fromRGB(0, 52, 138), Color3.fromRGB(255, 255, 255))

    -- เคาน์เตอร์ฝาก-ถอนธนาคาร 2 ช่องบริการ
    PartBuilder.makePart(bankModel, "TellerCounter", Vector3.new(20, 3.8, 3.5), CFrame.new(bX, floorY + 1.9, bZ + 5), Color3.fromRGB(0, 40, 110), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(bankModel, "TellerGlass", Vector3.new(18, 3.5, 0.3), CFrame.new(bX, floorY + 5.55, bZ + 5), PartBuilder.COLORS.glass, Enum.Material.Glass, { Transparency = 0.65 })

    -- เก้าอี้รอรับบริการสีน้ำเงิน BBL
    for r = 1, 2 do
        local rZ = bZ - 3 - (r * 5)
        PartBuilder.makePart(bankModel, "Bench_" .. r, Vector3.new(14, 1.8, 2.4), CFrame.new(bX, floorY + 1.1, rZ), Color3.fromRGB(0, 70, 160), Enum.Material.SmoothPlastic)
    end

    -- ตู้ ATM 2 ตู้เรืองแสงหน้าธนาคาร
    for atm = 1, 2 do
        local aX = (bX - 10) + ((atm - 1) * 8)
        local aPart = PartBuilder.makePart(bankModel, "ATM_" .. atm, Vector3.new(3.5, 7.5, 3.2), CFrame.new(aX, floorY + 3.75, bZ + 12), (atm == 1) and Color3.fromRGB(0, 50, 140) or Color3.fromRGB(75, 40, 130), Enum.Material.Metal)
        PartBuilder.makePart(bankModel, "Screen_" .. atm, Vector3.new(2.2, 1.8, 0.2), CFrame.new(aX, floorY + 4.8, bZ + 10.3), Color3.fromRGB(220, 245, 255), Enum.Material.Neon)
        PartBuilder.makeSign(bankModel, "Sign_ATM_" .. atm, (atm == 1) and "BBL ATM" or "SCB ATM", Vector3.new(3.2, 1.2, 0.2), Vector3.new(aX, floorY + 6.8, bZ + 10.3), Enum.NormalId.Back, (atm == 1) and Color3.fromRGB(0, 50, 140) or Color3.fromRGB(75, 40, 130))
    end

    ------------------------------------------------------------------
    -- 4. มุมบนขวา: "คาเฟ่" (COFFEE & CAFE - FULL DETAIL)
    ------------------------------------------------------------------
    local cafeModel = Instance.new("Model")
    cafeModel.Name = "Room_Cafe_TopRight"
    cafeModel.Parent = floor1

    local cX, cZ = 52.5, -38.5
    local cW, cL = 35, 33

    PartBuilder.makePart(cafeModel, "Floor", Vector3.new(cW, 0.1, cL), CFrame.new(cX, floorY + 0.06, cZ), Color3.fromRGB(240, 232, 222), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(cafeModel, "Wall_Outer_R", Vector3.new(wallThick, wallH, cL), CFrame.new(cX + cW/2, floorY + wallH/2, cZ), wallColor, wallMaterial)
    PartBuilder.makePart(cafeModel, "Wall_Outer_T", Vector3.new(cW, wallH, wallThick), CFrame.new(cX, floorY + wallH/2, cZ - cL/2), wallColor, wallMaterial)
    PartBuilder.makePart(cafeModel, "Wall_Inner_L", Vector3.new(wallThick, wallH, cL), CFrame.new(cX - cW/2, floorY + wallH/2, cZ), wallColor, wallMaterial)
    PartBuilder.makePart(cafeModel, "Wall_Front_A", Vector3.new(12, wallH, wallThick), CFrame.new(cX - 11.5, floorY + wallH/2, cZ + cL/2), wallColor, wallMaterial)
    PartBuilder.makePart(cafeModel, "Wall_Front_B", Vector3.new(12, wallH, wallThick), CFrame.new(cX + 11.5, floorY + wallH/2, cZ + cL/2), wallColor, wallMaterial)
    PartBuilder.makePart(cafeModel, "Wall_DoorHeader", Vector3.new(11, 4.5, wallThick), CFrame.new(cX, floorY + wallH - 2.25, cZ + cL/2), wallColor, wallMaterial)

    PartBuilder.makeSign(cafeModel, "Sign", "คาเฟ่ มจพ.\nKMUTNB COFFEE & BAKERY", Vector3.new(14, 2.8, 0.3), Vector3.new(cX, floorY + 9.5, cZ + cL/2 + 0.2), Enum.NormalId.Back, Color3.fromRGB(120, 75, 40), Color3.fromRGB(255, 255, 255))

    -- บาร์สั่งกาแฟไม้และเครื่องชง Espresso (Coffee Counter)
    PartBuilder.makePart(cafeModel, "CoffeeBar", Vector3.new(18, 3.8, 4), CFrame.new(cX, floorY + 1.9, cZ - 6), Color3.fromRGB(90, 55, 30), Enum.Material.WoodPlanks)
    PartBuilder.makePart(cafeModel, "EspressoMachine", Vector3.new(3.5, 2.2, 2.5), CFrame.new(cX - 4, floorY + 4.9, cZ - 6), Color3.fromRGB(180, 185, 190), Enum.Material.Metal)
    PartBuilder.makePart(cafeModel, "PastryCase", Vector3.new(6.0, 2.5, 2.5), CFrame.new(cX + 4, floorY + 5.0, cZ - 6), PartBuilder.COLORS.glass, Enum.Material.Glass, { Transparency = 0.6 })

    -- โต๊ะกลมคาเฟ่ 2 ชุด
    for t = 1, 2 do
        local tX = (cX - 6) + ((t - 1) * 12)
        local tZ = cZ + 6
        PartBuilder.makeCylinder(cafeModel, "CafeTable_" .. t, Vector3.new(0.4, 4.5, 4.5), CFrame.new(tX, floorY + 3.0, tZ) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(160, 100, 50), Enum.Material.Wood)
        PartBuilder.makeCylinder(cafeModel, "CafeLeg_" .. t, Vector3.new(3.0, 0.5, 0.5), CFrame.new(tX, floorY + 1.5, tZ) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
    end

    ------------------------------------------------------------------
    -- 5. มุมบนซ้าย: "ห้อง" (FACILITIES & STORAGE - FULL DETAIL)
    ------------------------------------------------------------------
    local roomTL = Instance.new("Model")
    roomTL.Name = "Room_TopLeft_Facilities"
    roomTL.Parent = floor1

    local tlX, tlZ = -52.5, -38.5
    local tlW, tlL = 35, 33

    PartBuilder.makePart(roomTL, "Floor", Vector3.new(tlW, 0.1, tlL), CFrame.new(tlX, floorY + 0.06, tlZ), Color3.fromRGB(230, 230, 230), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(roomTL, "Wall_Outer_L", Vector3.new(wallThick, wallH, tlL), CFrame.new(tlX - tlW/2, floorY + wallH/2, tlZ), wallColor, wallMaterial)
    PartBuilder.makePart(roomTL, "Wall_Outer_T", Vector3.new(tlW, wallH, wallThick), CFrame.new(tlX, floorY + wallH/2, tlZ - tlL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomTL, "Wall_Inner_R", Vector3.new(wallThick, wallH, tlL), CFrame.new(tlX + tlW/2, floorY + wallH/2, tlZ), wallColor, wallMaterial)
    PartBuilder.makePart(roomTL, "Wall_Front_A", Vector3.new(12, wallH, wallThick), CFrame.new(tlX - 11.5, floorY + wallH/2, tlZ + tlL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomTL, "Wall_Front_B", Vector3.new(12, wallH, wallThick), CFrame.new(tlX + 11.5, floorY + wallH/2, tlZ + tlL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomTL, "Wall_DoorHeader", Vector3.new(11, 4.5, wallThick), CFrame.new(tlX, floorY + wallH - 2.25, tlZ + tlL/2), wallColor, wallMaterial)

    PartBuilder.makeSign(roomTL, "Sign", "ห้องพัสดุและซ่อมบำรุง\nFACILITIES & STORAGE", Vector3.new(14, 2.8, 0.3), Vector3.new(tlX, floorY + 9.5, tlZ + tlL/2 + 0.2), Enum.NormalId.Back, Color3.fromRGB(80, 85, 95), Color3.fromRGB(255, 255, 255))

    -- ชั้นวางของเหล็กและกล่องเครื่องมือ (Storage Shelves)
    for sh = 1, 2 do
        local shX = (tlX - 8) + ((sh - 1) * 16)
        PartBuilder.makePart(roomTL, "Shelf_" .. sh, Vector3.new(12, 9, 3.5), CFrame.new(shX, floorY + 4.5, tlZ - 8), Color3.fromRGB(90, 95, 105), Enum.Material.Metal)
    end
    PartBuilder.makePart(roomTL, "Workbench", Vector3.new(14, 3.2, 4), CFrame.new(tlX, floorY + 1.6, tlZ + 6), Color3.fromRGB(120, 85, 55), Enum.Material.WoodPlanks)

    ------------------------------------------------------------------
    -- 6. มุมล่างซ้าย: "ห้อง" (SECURITY & CCTV - FULL DETAIL)
    ------------------------------------------------------------------
    local roomBL = Instance.new("Model")
    roomBL.Name = "Room_BottomLeft_Security"
    roomBL.Parent = floor1

    local blX, blZ = -52.5, 38.5
    local blW, blL = 35, 33

    PartBuilder.makePart(roomBL, "Floor", Vector3.new(blW, 0.1, blL), CFrame.new(blX, floorY + 0.06, blZ), Color3.fromRGB(230, 230, 230), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(roomBL, "Wall_Outer_L", Vector3.new(wallThick, wallH, blL), CFrame.new(blX - blW/2, floorY + wallH/2, blZ), wallColor, wallMaterial)
    PartBuilder.makePart(roomBL, "Wall_Outer_B", Vector3.new(blW, wallH, wallThick), CFrame.new(blX, floorY + wallH/2, blZ + blL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomBL, "Wall_Inner_R", Vector3.new(wallThick, wallH, blL), CFrame.new(blX + blW/2, floorY + wallH/2, blZ), wallColor, wallMaterial)
    PartBuilder.makePart(roomBL, "Wall_Front_A", Vector3.new(12, wallH, wallThick), CFrame.new(blX - 11.5, floorY + wallH/2, blZ - blL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomBL, "Wall_Front_B", Vector3.new(12, wallH, wallThick), CFrame.new(blX + 11.5, floorY + wallH/2, blZ - blL/2), wallColor, wallMaterial)
    PartBuilder.makePart(roomBL, "Wall_DoorHeader", Vector3.new(11, 4.5, wallThick), CFrame.new(blX, floorY + wallH - 2.25, blZ - blL/2), wallColor, wallMaterial)

    PartBuilder.makeSign(roomBL, "Sign", "ศูนย์ควบคุมความปลอดภัย & CCTV\nSECURITY & SURVEILLANCE", Vector3.new(14, 2.8, 0.3), Vector3.new(blX, floorY + 9.5, blZ - blL/2 - 0.2), Enum.NormalId.Back, Color3.fromRGB(180, 40, 50), Color3.fromRGB(255, 255, 255))

    -- โต๊ะควบคุมพร้อมหน้าจอวงจรปิด CCTV 4 จอเรืองแสง
    PartBuilder.makePart(roomBL, "ControlDesk", Vector3.new(18, 3.2, 4), CFrame.new(blX, floorY + 1.6, blZ + 6), Color3.fromRGB(40, 42, 48), Enum.Material.Metal)
    for cctv = 1, 4 do
        local cX = (blX - 6) + ((cctv - 1) * 4)
        PartBuilder.makePart(roomBL, "CCTV_Screen_" .. cctv, Vector3.new(3.2, 2.2, 0.2), CFrame.new(cX, floorY + 4.5, blZ + 7.8), Color3.fromRGB(70, 200, 255), Enum.Material.Neon)
    end

    ------------------------------------------------------------------
    -- 7. ด้านบน (REAR CORE)
    -- "ลิฟ" (ซ้าย) หันหน้าเข้าหาบันได | "ทางเข้าออก" (กลาง) | "บันไดวนซ้าย" (ขวา)
    ------------------------------------------------------------------
    local topCore = Instance.new("Folder")
    topCore.Name = "TopCirculationCore"
    topCore.Parent = floor1

    local topZ = -63.5
    local coreH = wallH

    -- 7.1 ลิฟต์ด้านบนซ้าย (Top Left Elevators): **หันหน้าเข้าหาบันได (+X)**
    local topLift = Instance.new("Model")
    topLift.Name = "TopElevators_Left"
    topLift.Parent = topCore
    PartBuilder.makePart(topLift, "Floor", Vector3.new(24, 0.1, 18), CFrame.new(-23, floorY + 0.06, topZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(topLift, "Wall_Back", Vector3.new(24, coreH, wallThick), CFrame.new(-23, floorY + coreH/2, topZ - 9), wallColor, wallMaterial)
    PartBuilder.makePart(topLift, "Wall_Left", Vector3.new(wallThick, coreH, 18), CFrame.new(-35, floorY + coreH/2, topZ), wallColor, wallMaterial)
    -- ผนังขวาเจาะช่องประตูลิฟต์ หันหน้าเข้าหาบันไดทางขวา (+X)
    PartBuilder.makePart(topLift, "Wall_Right_Top", Vector3.new(wallThick, 3.5, 18), CFrame.new(-11, floorY + coreH - 1.75, topZ), wallColor, wallMaterial)
    -- ประตูลิฟต์ 2 ตัว หันหน้าทางทิศตะวันออก (+X) เข้าหาบันได!
    for el = 1, 2 do
        local eZ = (topZ - 4.5) + ((el - 1) * 9.0)
        PartBuilder.makePart(topLift, "LiftDoor_" .. el, Vector3.new(0.4, 10.5, 6.8), CFrame.new(-11.2, floorY + 5.25, eZ), PartBuilder.COLORS.steel, Enum.Material.Metal)
        PartBuilder.makeSign(topLift, "Ind_" .. el, "[ 1 ] ▲", Vector3.new(0.2, 1.2, 2.8), Vector3.new(-11.4, floorY + 11.5, eZ), Enum.NormalId.Left, Color3.fromRGB(20, 20, 25), Color3.fromRGB(255, 140, 0))
    end
    PartBuilder.makeSign(topLift, "Sign", "โถงลิฟต์โดยสาร\nPASSENGER LIFTS", Vector3.new(8, 2.5, 0.3), Vector3.new(-23, floorY + 8.5, -55 + 0.2), Enum.NormalId.Back, Color3.fromRGB(30, 40, 50), Color3.fromRGB(255, 255, 255))

    -- 7.2 ทางเข้าออกด้านบนกลาง (Top Center Entrance/Exit)
    local topEntrance = Instance.new("Model")
    topEntrance.Name = "TopEntrance_Center"
    topEntrance.Parent = topCore
    PartBuilder.makePart(topEntrance, "Floor", Vector3.new(22, 0.1, 18), CFrame.new(0, floorY + 0.06, topZ), Color3.fromRGB(230, 225, 215), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(topEntrance, "Wall_BackL", Vector3.new(6, coreH, wallThick), CFrame.new(-8, floorY + coreH/2, topZ - 9), wallColor, wallMaterial)
    PartBuilder.makePart(topEntrance, "Wall_BackR", Vector3.new(6, coreH, wallThick), CFrame.new(8, floorY + coreH/2, topZ - 9), wallColor, wallMaterial)
    PartBuilder.makePart(topEntrance, "DoorHeader", Vector3.new(10, 4, wallThick), CFrame.new(0, floorY + coreH - 2, topZ - 9), wallColor, wallMaterial)
    PartBuilder.makeSign(topEntrance, "Sign", "ทางเข้าออก\nENTRANCE / EXIT", Vector3.new(12, 2.5, 0.3), Vector3.new(0, floorY + 9.5, -55 + 0.2), Enum.NormalId.Back, PartBuilder.COLORS.maroon, Color3.fromRGB(255, 255, 255))

    -- 7.3 บันไดด้านบนขวา (Top Right Stairwell): **บันไดวนซ้าย (Left-Turning Switchback Stairs)**
    local topStairs = Instance.new("Model")
    topStairs.Name = "TopStairs_Right_TurnLeft"
    topStairs.Parent = topCore
    PartBuilder.makePart(topStairs, "Floor", Vector3.new(24, 0.1, 18), CFrame.new(23, floorY + 0.06, topZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(topStairs, "Wall_Back", Vector3.new(24, coreH, wallThick), CFrame.new(23, floorY + coreH/2, topZ - 9), wallColor, wallMaterial)
    PartBuilder.makePart(topStairs, "Wall_Left", Vector3.new(wallThick, coreH, 18), CFrame.new(11, floorY + coreH/2, topZ), wallColor, wallMaterial)
    PartBuilder.makePart(topStairs, "Wall_Right", Vector3.new(wallThick, coreH, 18), CFrame.new(35, floorY + coreH/2, topZ), wallColor, wallMaterial)

    -- ช่วงที่ 1: เดินขึ้นทางขวา (Z ไปทางลบ)
    for s = 1, 7 do
        PartBuilder.makePart(topStairs, "Step1_" .. s, Vector3.new(5.5, 1.0, 1.4), CFrame.new(28, floorY + (s * 1.0), (topZ + 6) - (s * 1.3)), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    end
    -- ชานพักกลาง (Mid Landing): เลี้ยวซ้าย!
    PartBuilder.makePart(topStairs, "MidLanding", Vector3.new(18, 1.0, 5.0), CFrame.new(23, floorY + 7.5, topZ - 5.5), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    -- ช่วงที่ 2: วนซ้ายกลับขึ้นชั้น 2 (Z ไปทางบวก)
    for s = 1, 7 do
        PartBuilder.makePart(topStairs, "Step2_" .. s, Vector3.new(5.5, 1.0, 1.4), CFrame.new(18, floorY + 7.5 + (s * 1.0), (topZ - 3) + (s * 1.3)), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    end
    PartBuilder.makeSign(topStairs, "Sign", "บันไดวนซ้ายขึ้นชั้น 2\nSTAIRS TO FLOOR 2", Vector3.new(10, 2.5, 0.3), Vector3.new(23, floorY + 8.5, -55 + 0.2), Enum.NormalId.Back, PartBuilder.COLORS.orange, Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 8. ด้านล่าง (FRONT CORE)
    -- "บันไดวนซ้าย" (ซ้าย) | "ทางเข้าออก" (กลาง) | "ลิฟ" (ขวา) หันหน้าเข้าหาบันได
    ------------------------------------------------------------------
    local bottomCore = Instance.new("Folder")
    bottomCore.Name = "BottomCirculationCore"
    bottomCore.Parent = floor1

    local botZ = 63.5

    -- 8.1 บันไดด้านล่างซ้าย: **บันไดวนซ้าย (Left-Turning Switchback Stairs)**
    local botStairs = Instance.new("Model")
    botStairs.Name = "BottomStairs_Left_TurnLeft"
    botStairs.Parent = bottomCore
    PartBuilder.makePart(botStairs, "Floor", Vector3.new(24, 0.1, 18), CFrame.new(-23, floorY + 0.06, botZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(botStairs, "Wall_Front", Vector3.new(24, coreH, wallThick), CFrame.new(-23, floorY + coreH/2, botZ + 9), wallColor, wallMaterial)
    PartBuilder.makePart(botStairs, "Wall_Left", Vector3.new(wallThick, coreH, 18), CFrame.new(-35, floorY + coreH/2, botZ), wallColor, wallMaterial)
    PartBuilder.makePart(botStairs, "Wall_Right", Vector3.new(wallThick, coreH, 18), CFrame.new(-11, floorY + coreH/2, botZ), wallColor, wallMaterial)

    -- ช่วงที่ 1: เดินขึ้นตรงไปทางใต้
    for s = 1, 7 do
        PartBuilder.makePart(botStairs, "Step1_" .. s, Vector3.new(5.5, 1.0, 1.4), CFrame.new(-28, floorY + (s * 1.0), (botZ - 6) + (s * 1.3)), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    end
    -- ชานพักกลาง: เลี้ยวซ้าย!
    PartBuilder.makePart(botStairs, "MidLanding", Vector3.new(18, 1.0, 5.0), CFrame.new(-23, floorY + 7.5, botZ + 5.5), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    -- ช่วงที่ 2: วนซ้ายกลับขึ้นชั้น 2
    for s = 1, 7 do
        PartBuilder.makePart(botStairs, "Step2_" .. s, Vector3.new(5.5, 1.0, 1.4), CFrame.new(-18, floorY + 7.5 + (s * 1.0), (botZ + 3) - (s * 1.3)), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    end
    PartBuilder.makeSign(botStairs, "Sign", "บันไดวนซ้ายขึ้นชั้น 2\nSTAIRS TO FLOOR 2", Vector3.new(10, 2.5, 0.3), Vector3.new(-23, floorY + 8.5, 55 - 0.2), Enum.NormalId.Back, PartBuilder.COLORS.orange, Color3.fromRGB(255, 255, 255))

    -- 8.2 ทางเข้าออกด้านล่างกลาง (Bottom Center Entrance/Exit)
    local botEntrance = Instance.new("Model")
    botEntrance.Name = "BottomEntrance_Center"
    botEntrance.Parent = bottomCore
    PartBuilder.makePart(botEntrance, "Floor", Vector3.new(22, 0.1, 18), CFrame.new(0, floorY + 0.06, botZ), Color3.fromRGB(230, 225, 215), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(botEntrance, "Wall_FrontL", Vector3.new(6, coreH, wallThick), CFrame.new(-8, floorY + coreH/2, botZ + 9), wallColor, wallMaterial)
    PartBuilder.makePart(botEntrance, "Wall_FrontR", Vector3.new(6, coreH, wallThick), CFrame.new(8, floorY + coreH/2, botZ + 9), wallColor, wallMaterial)
    PartBuilder.makePart(botEntrance, "DoorHeader", Vector3.new(10, 4, wallThick), CFrame.new(0, floorY + coreH - 2, botZ + 9), wallColor, wallMaterial)
    PartBuilder.makeSign(botEntrance, "Sign", "ทางเข้าออก\nENTRANCE / EXIT", Vector3.new(12, 2.5, 0.3), Vector3.new(0, floorY + 9.5, 55 - 0.2), Enum.NormalId.Back, PartBuilder.COLORS.maroon, Color3.fromRGB(255, 255, 255))

    -- 8.3 ลิฟต์ด้านล่างขวา: **หันหน้าเข้าหาบันได (-X)**
    local botLift = Instance.new("Model")
    botLift.Name = "BottomElevators_Right"
    botLift.Parent = bottomCore
    PartBuilder.makePart(botLift, "Floor", Vector3.new(24, 0.1, 18), CFrame.new(23, floorY + 0.06, botZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(botLift, "Wall_Front", Vector3.new(24, coreH, wallThick), CFrame.new(23, floorY + coreH/2, botZ + 9), wallColor, wallMaterial)
    PartBuilder.makePart(botLift, "Wall_Right", Vector3.new(wallThick, coreH, 18), CFrame.new(35, floorY + coreH/2, botZ), wallColor, wallMaterial)
    -- ผนังซ้ายเจาะช่องประตูลิฟต์ หันหน้าเข้าหาบันไดทางซ้าย (-X)!
    PartBuilder.makePart(botLift, "Wall_Left_Top", Vector3.new(wallThick, 3.5, 18), CFrame.new(11, floorY + coreH - 1.75, botZ), wallColor, wallMaterial)
    for el = 1, 2 do
        local eZ = (botZ - 4.5) + ((el - 1) * 9.0)
        PartBuilder.makePart(botLift, "LiftDoor_" .. el, Vector3.new(0.4, 10.5, 6.8), CFrame.new(11.2, floorY + 5.25, eZ), PartBuilder.COLORS.steel, Enum.Material.Metal)
        PartBuilder.makeSign(botLift, "Ind_" .. el, "[ 1 ] ▲", Vector3.new(0.2, 1.2, 2.8), Vector3.new(11.4, floorY + 11.5, eZ), Enum.NormalId.Right, Color3.fromRGB(20, 20, 25), Color3.fromRGB(255, 140, 0))
    end
    PartBuilder.makeSign(botLift, "Sign", "โถงลิฟต์โดยสาร\nPASSENGER LIFTS", Vector3.new(8, 2.5, 0.3), Vector3.new(23, floorY + 8.5, 55 - 0.2), Enum.NormalId.Back, Color3.fromRGB(30, 40, 50), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 9. กำแพงรอบนอกด้านซ้าย-ขวา (Outer Boundary Walls)
    ------------------------------------------------------------------
    PartBuilder.makePart(floor1, "OuterWall_West", Vector3.new(wallThick, wallH, 44), CFrame.new(-70, floorY + wallH/2, 0), wallColor, wallMaterial)
    PartBuilder.makePart(floor1, "Driveway_Header_East", Vector3.new(wallThick, 3.5, 44), CFrame.new(70, floorY + wallH - 1.75, 0), Color3.fromRGB(180, 80, 30), Enum.Material.Metal)

    ------------------------------------------------------------------
    -- 10. แสงสว่างประจำชั้น 1 (Ceiling Lights)
    ------------------------------------------------------------------
    local lights = Instance.new("Folder")
    lights.Name = "Lights"
    lights.Parent = floor1

    local lightPositions = {
        Vector3.new(0, floorY + wallH - 1, 0),
        Vector3.new(-35, floorY + wallH - 1, 0),
        Vector3.new(35, floorY + wallH - 1, 0),
        Vector3.new(bX, floorY + wallH - 1, bZ),
        Vector3.new(cX, floorY + wallH - 1, cZ),
        Vector3.new(tlX, floorY + wallH - 1, tlZ),
        Vector3.new(blX, floorY + wallH - 1, blZ),
        Vector3.new(0, floorY + wallH - 1, topZ),
        Vector3.new(0, floorY + wallH - 1, botZ),
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
    print("🏢 [Floor 1 Details Built] ลงรายละเอียดครบ 100%: ลิฟต์หันหน้าเข้าหาบันได + บันไดวนซ้าย + ธนาคาร + คาเฟ่ + ปิดสปอว์นซอมบี้แล้ว!")
    print("=========================================================")
end

return Floor1_Lobby
