--[[
    Floor2_Canteen.lua
    โมดูลสร้างชั้น 2: โรงอาหาร 40 ปี สจพ. (มจพ.) ครบถ้วนตามแปลนจริงและ Google Street View
    
    ผังตามภาพแปลน (media_1794239565318_4be79af6.png):
      - บันไดใหญ่หน้าตึก (Outdoor Grand Stairs) มีป้าย "โรงอาหาร 40 ปี สจพ." พร้อมตราโค้ก
      - โซนด้านหน้า: บันได (ซ้าย) / ทางเข้าออกคู่ (กลาง) / ลิฟต์ (ขวา) / ที่เก็บจาน / ห้องสำนักงาน
      - ตรงกลาง: ลานโต๊ะอาหารสแตนเลส มจพ. กว้างขวาง วิ่งหลบซอมบี้ได้
      - ปีกซ้าย: ห้องน้ำ (มุมหน้า) / แถวร้านข้าว 4 ร้าน (กลาง) / ห้องน้ำ (มุมหลัง)
      - ปีกขวา: ห้องน้ำ (มุมหน้า) / แถวร้านน้ำ-ร้านข้าว 4 ร้าน (กลาง) / ห้องน้ำ (มุมหลัง)
      - โซนด้านหลัง: ลิฟต์ (ซ้าย) / ทางเข้าออก (กลาง) / บันได (ขวา) / ห้องเก็บของ / ที่เก็บจาน
      - จุดซื้อปืนติดผนัง (Wall Buys): Bucky, Spectre, Judge
      - ตู้ Perk: ตู้กดน้ำอัตโนมัติ มจพ. (Juggernog +100 Max HP)
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local Floor2_Canteen = {}

function Floor2_Canteen.build(building)
    local floor2 = Instance.new("Model")
    floor2.Name = "Floor_2_Canteen"
    floor2.Parent = building

    local bW = PartBuilder.WIDTH          -- 135 studs
    local bL = PartBuilder.LENGTH         -- 120 studs
    local fH = PartBuilder.FLOOR_HEIGHT   -- 16 studs
    local f2BaseY = PartBuilder.floorY(2) -- 20 studs (ความสูงพื้นชั้น 2)

    ------------------------------------------------------------------
    -- 1. บันไดใหญ่หน้าตึก (GRAND OUTDOOR STAIRS ตามภาพ GOOGLE STREET VIEW)
    -- บันไดโค้งสองฝั่งขึ้นสู่ชานพักหน้าโรงอาหารชั้น 2 พร้อมป้าย "โรงอาหาร 40 ปี สจพ."
    ------------------------------------------------------------------
    local outdoorStairs = Instance.new("Model")
    outdoorStairs.Name = "OutdoorGrandStairs_Front"
    outdoorStairs.Parent = floor2

    local stairZ = bL/2 + 20 -- Z = 80
    local landingW = 32
    local landingL = 18

    -- ชานพักลอยฟ้าหน้าโรงอาหารชั้น 2 (Elevated Bridge Landing)
    local landing = PartBuilder.makePart(
        outdoorStairs,
        "StairLandingPlatform",
        Vector3.new(landingW, 1.8, landingL),
        CFrame.new(0, f2BaseY, stairZ),
        PartBuilder.COLORS.warmGrey,
        Enum.Material.Concrete
    )

    -- ราวกันตกชานพัก
    PartBuilder.makePart(outdoorStairs, "LandingRail_Front", Vector3.new(landingW, 3.8, 0.8), CFrame.new(0, f2BaseY + 2.7, stairZ + landingL/2), Color3.fromRGB(225, 140, 75), Enum.Material.Concrete)

    -- 🌟 ป้ายชื่อ "โรงอาหาร 40 ปี สจพ." สีเขียว/ขาว พร้อมตรา Coca-Cola สองข้าง (ตามภาพจริงเป๊ะ 100%)
    local signBoard = PartBuilder.makeSign(
        outdoorStairs,
        "CanteenFacadeSign",
        "โรงอาหาร 40 ปี\nสจพ. (มจพ.)",
        Vector3.new(16, 4.2, 0.6),
        Vector3.new(0, f2BaseY + 2.6, stairZ + landingL/2 + 0.6),
        Enum.NormalId.Back,
        Color3.fromRGB(245, 245, 240),
        Color3.fromRGB(0, 140, 70)
    )
    -- โลโก้โค้กสีแดงประกบสองข้าง
    PartBuilder.makeSign(
        outdoorStairs,
        "CokeBadge_L",
        "Coke",
        Vector3.new(3.2, 3.2, 0.7),
        Vector3.new(-9.5, f2BaseY + 2.6, stairZ + landingL/2 + 0.6),
        Enum.NormalId.Back,
        Color3.fromRGB(220, 20, 30),
        Color3.fromRGB(255, 255, 255)
    )
    PartBuilder.makeSign(
        outdoorStairs,
        "CokeBadge_R",
        "Coke",
        Vector3.new(3.2, 3.2, 0.7),
        Vector3.new(9.5, f2BaseY + 2.6, stairZ + landingL/2 + 0.6),
        Enum.NormalId.Back,
        Color3.fromRGB(220, 20, 30),
        Color3.fromRGB(255, 255, 255)
    )

    -- เสากลมค้ำชานพักบันไดด้านล่าง (Ground Pillars Y=4 to Y=20)
    for _, px in ipairs({ -12, 12 }) do
        PartBuilder.makeCylinder(
            outdoorStairs,
            "PodiumPillar",
            Vector3.new(16, 2.5, 2.5),
            CFrame.new(px, 12, stairZ) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(240, 235, 225),
            Enum.Material.Concrete
        )
    end

    -- โต๊ะหินใต้บันไดชั้นล่าง (Picnic Benches Under Staircase)
    PartBuilder.makePart(outdoorStairs, "GroundBench_1", Vector3.new(10, 2.8, 3.5), CFrame.new(-6, 5.4, stairZ), Color3.fromRGB(90, 60, 45), Enum.Material.Wood)
    PartBuilder.makePart(outdoorStairs, "GroundBench_2", Vector3.new(10, 2.8, 3.5), CFrame.new(6, 5.4, stairZ), Color3.fromRGB(90, 60, 45), Enum.Material.Wood)

    -- ขั้นบันไดโค้งปีกซ้ายและปีกขวา (Sweeping Stair Ramps from Plaza Y=4 to Y=20)
    local stairSteps = 16
    local totalRise = 16
    local stepH = totalRise / stairSteps
    local stepW = 8.5
    local rampSpanX = 36

    for i = 1, stairSteps do
        local curY = 4 + (i * stepH)
        local curX_L = -landingW/2 - ((i / stairSteps) * rampSpanX)
        local curX_R = landingW/2 + ((i / stairSteps) * rampSpanX)
        local curZ = stairZ + 4 - (i * 1.2)

        -- บันไดปีกซ้าย
        PartBuilder.makePart(
            outdoorStairs,
            "Stair_L_" .. i,
            Vector3.new(stepW, stepH + 0.2, 2.2),
            CFrame.new(curX_L, curY - stepH/2, curZ),
            Color3.fromRGB(225, 140, 75),
            Enum.Material.Concrete
        )
        -- บันไดปีกขวา
        PartBuilder.makePart(
            outdoorStairs,
            "Stair_R_" .. i,
            Vector3.new(stepW, stepH + 0.2, 2.2),
            CFrame.new(curX_R, curY - stepH/2, curZ),
            Color3.fromRGB(225, 140, 75),
            Enum.Material.Concrete
        )
    end

    -- หลังคากันสาดโค้งสีน้ำเงินเข้มคลุมบันไดทั้งสองฝั่ง (Arched Metal Canopies)
    PartBuilder.makePart(outdoorStairs, "Canopy_L", Vector3.new(rampSpanX + 6, 0.8, 12), CFrame.new(-landingW/2 - rampSpanX/2, f2BaseY + 7, stairZ - 4) * CFrame.Angles(0, 0, math.rad(-18)), Color3.fromRGB(35, 50, 70), Enum.Material.Metal)
    PartBuilder.makePart(outdoorStairs, "Canopy_R", Vector3.new(rampSpanX + 6, 0.8, 12), CFrame.new(landingW/2 + rampSpanX/2, f2BaseY + 7, stairZ - 4) * CFrame.Angles(0, 0, math.rad(18)), Color3.fromRGB(35, 50, 70), Enum.Material.Metal)

    -- สะพานเชื่อมจากชานพักบันไดเข้าสู่ประตูโรงอาหารชั้น 2
    PartBuilder.makePart(
        outdoorStairs,
        "StairBridgeToCanteen",
        Vector3.new(16, 1.8, 15),
        CFrame.new(0, f2BaseY, bL/2 + 7.5),
        PartBuilder.COLORS.tileLight,
        Enum.Material.Concrete
    )

    ------------------------------------------------------------------
    -- 2. พื้นและผนังหลักชั้น 2 (MAIN CANTEEN SLAB & WALLS)
    ------------------------------------------------------------------
    local floorTile = PartBuilder.makePart(
        floor2,
        "CanteenFloorTile",
        Vector3.new(bW, 1.5, bL),
        CFrame.new(0, f2BaseY, 0),
        Color3.fromRGB(235, 230, 220),
        Enum.Material.SmoothPlastic
    )

    -- ผนังภายนอกชั้น 2 พร้อมหน้าต่างระบายอากาศ
    PartBuilder.makePart(floor2, "OuterWall_L2", Vector3.new(1.8, fH, bL), CFrame.new(-bW/2, f2BaseY + fH/2, 0), PartBuilder.COLORS.cream)
    PartBuilder.makePart(floor2, "OuterWall_R2", Vector3.new(1.8, fH, bL), CFrame.new(bW/2, f2BaseY + fH/2, 0), PartBuilder.COLORS.cream)
    PartBuilder.makePart(floor2, "OuterWall_Rear2", Vector3.new(bW, fH, 1.8), CFrame.new(0, f2BaseY + fH/2, -bL/2), PartBuilder.COLORS.cream)
    PartBuilder.makePart(floor2, "OuterWall_Front2_L", Vector3.new((bW - 24)/2, fH, 1.8), CFrame.new(-(bW + 24)/4, f2BaseY + fH/2, bL/2), PartBuilder.COLORS.cream)
    PartBuilder.makePart(floor2, "OuterWall_Front2_R", Vector3.new((bW - 24)/2, fH, 1.8), CFrame.new((bW + 24)/4, f2BaseY + fH/2, bL/2), PartBuilder.COLORS.cream)

    ------------------------------------------------------------------
    -- 3. โซนด้านหน้า (FRONT ZONE ตามภาพแปลน)
    -- ทางเข้าออกคู่ (กลาง) / บันได (ซ้าย) / ลิฟต์ (ขวา) / ที่เก็บจาน / ห้อง
    ------------------------------------------------------------------
    local frontZone = Instance.new("Folder")
    frontZone.Name = "FrontZone"
    frontZone.Parent = floor2

    -- ทางเข้าออกหลัก (Main Front Double Doors)
    PartBuilder.makePart(
        frontZone,
        "FrontEntrance_DoorHeader",
        Vector3.new(24, 2.5, 2.0),
        CFrame.new(0, f2BaseY + fH - 1.25, bL/2),
        PartBuilder.COLORS.darkGrey,
        Enum.Material.Metal
    )
    PartBuilder.makePart(
        frontZone,
        "FrontDoor_L",
        Vector3.new(10, fH - 2.5, 0.4),
        CFrame.new(-5.5, f2BaseY + (fH - 2.5)/2, bL/2),
        PartBuilder.COLORS.glass,
        Enum.Material.Glass,
        { Transparency = 0.6 }
    )
    PartBuilder.makePart(
        frontZone,
        "FrontDoor_R",
        Vector3.new(10, fH - 2.5, 0.4),
        CFrame.new(5.5, f2BaseY + (fH - 2.5)/2, bL/2),
        PartBuilder.COLORS.glass,
        Enum.Material.Glass,
        { Transparency = 0.6 }
    )
    PartBuilder.makeSign(
        frontZone,
        "CanteenWelcomeSign",
        "ทางเข้าโรงอาหาร 40 ปี มจพ. // KMUTNB CANTEEN ENTRANCE",
        Vector3.new(24, 2.0, 0.4),
        Vector3.new(0, f2BaseY + fH - 1.25, bL/2 + 1.1),
        Enum.NormalId.Back,
        PartBuilder.COLORS.maroon
    )

    -- บันไดหน้าฝั่งซ้าย (Front Left Stairs เชื่อมขึ้นชั้น 3 และลงชั้น 1)
    local frontStair = Instance.new("Model")
    frontStair.Name = "FrontStairwell_Left"
    frontStair.Parent = frontZone
    PartBuilder.makePart(frontStair, "StairWall_FL", Vector3.new(18, fH, 1.4), CFrame.new(-23, f2BaseY + fH/2, 48), PartBuilder.COLORS.cream)
    PartBuilder.makePart(frontStair, "StairSide_FL", Vector3.new(1.4, fH, 12), CFrame.new(-32, f2BaseY + fH/2, 54), PartBuilder.COLORS.cream)
    for s = 1, 14 do
        PartBuilder.makePart(frontStair, "Step_" .. s, Vector3.new(10, 1.1, 1.6), CFrame.new(-23, f2BaseY + (s * 1.1), 48 + (s * 0.8)), PartBuilder.COLORS.warmGrey, Enum.Material.Concrete)
    end
    PartBuilder.makeSign(frontStair, "StairSign_FL", "บันไดขึ้นชั้น 3 (สนามกีฬา)\nSTAIRS TO FLOOR 3", Vector3.new(8, 2.2, 0.3), Vector3.new(-23, f2BaseY + 6, 47.2), Enum.NormalId.Back, PartBuilder.COLORS.orange)

    -- ลิฟต์หน้าฝั่งขวา (Front Right Elevators)
    local frontLift = Instance.new("Model")
    frontLift.Name = "FrontElevators_Right"
    frontLift.Parent = frontZone
    PartBuilder.makePart(frontLift, "LiftWall_FR", Vector3.new(18, fH, 1.4), CFrame.new(23, f2BaseY + fH/2, 48), PartBuilder.COLORS.cream)
    for el = 1, 2 do
        local elX = 17 + ((el - 1) * 11)
        PartBuilder.makePart(frontLift, "LiftDoor_" .. el, Vector3.new(6.8, 10.5, 0.4), CFrame.new(elX, f2BaseY + 5.25, 48.8), PartBuilder.COLORS.steel, Enum.Material.Metal)
        PartBuilder.makeSign(frontLift, "LiftInd_" .. el, "[ 2 ] ▲", Vector3.new(2.4, 1.0, 0.2), Vector3.new(elX, f2BaseY + 11.5, 48.9), Enum.NormalId.Back, Color3.fromRGB(20, 20, 25), Color3.fromRGB(255, 140, 0))
    end

    -- ที่เก็บจานด้านหน้า (Dish & Tray Return Station ด้านหน้า)
    local dishReturnFront = Instance.new("Model")
    dishReturnFront.Name = "DishReturn_Front"
    dishReturnFront.Parent = frontZone
    local dfX, dfZ = -22, 38
    PartBuilder.makePart(dishReturnFront, "Partition", Vector3.new(18, fH, 1.2), CFrame.new(dfX, f2BaseY + fH/2, dfZ), PartBuilder.COLORS.cream)
    -- ชั้นวางถาดสแตนเลส 3 ชั้น
    PartBuilder.makePart(dishReturnFront, "TrayRack", Vector3.new(14, 6.5, 3.5), CFrame.new(dfX, f2BaseY + 3.25, dfZ - 3), PartBuilder.COLORS.steel, Enum.Material.Metal)
    -- อ่างล้างมือ & ถังขยะแยกเศษอาหาร
    PartBuilder.makePart(dishReturnFront, "WashSink", Vector3.new(6, 3.2, 3.0), CFrame.new(dfX + 5, f2BaseY + 1.6, dfZ - 3), PartBuilder.COLORS.steel, Enum.Material.Metal)
    PartBuilder.makePart(dishReturnFront, "FoodWasteBin", Vector3.new(3, 3.5, 3), CFrame.new(dfX - 5, f2BaseY + 1.75, dfZ - 3), Color3.fromRGB(40, 120, 60), Enum.Material.SmoothPlastic)
    PartBuilder.makeSign(dishReturnFront, "Sign", "จุดส่งคืนภาชนะและเศษอาหาร\nDISH & TRAY RETURN", Vector3.new(14, 1.8, 0.3), Vector3.new(dfX, f2BaseY + 7.5, dfZ - 0.7), Enum.NormalId.Back, PartBuilder.COLORS.maroon)

    -- ห้องสำนักงานโรงอาหาร / สหกรณ์ (Canteen Office ด้านหน้า)
    local officeFront = Instance.new("Model")
    officeFront.Name = "CanteenOffice_Front"
    officeFront.Parent = frontZone
    local ofX, ofZ = 22, 38
    PartBuilder.makePart(officeFront, "Wall_Front", Vector3.new(18, fH, 1.2), CFrame.new(ofX, f2BaseY + fH/2, ofZ), PartBuilder.COLORS.cream)
    PartBuilder.makePart(officeFront, "OfficeDoor", Vector3.new(4.5, 9, 0.4), CFrame.new(ofX, f2BaseY + 4.5, ofZ - 0.5), PartBuilder.COLORS.wood, Enum.Material.Wood)
    PartBuilder.makePart(officeFront, "Desk", Vector3.new(8, 3.2, 4), CFrame.new(ofX, f2BaseY + 1.6, ofZ + 4), PartBuilder.COLORS.darkGrey, Enum.Material.WoodPlanks)
    PartBuilder.makeSign(officeFront, "Sign", "ห้องสำนักงานผู้จัดการโรงอาหาร 40 ปี\nCANTEEN ADMINISTRATION OFFICE", Vector3.new(14, 1.8, 0.3), Vector3.new(ofX, f2BaseY + 7.5, ofZ - 0.7), Enum.NormalId.Back, PartBuilder.COLORS.orange)

    ------------------------------------------------------------------
    -- 4. ปีกซ้าย: ห้องน้ำ (หน้า) + ร้านข้าว 4 ร้าน + ห้องน้ำ (หลัง)
    ------------------------------------------------------------------
    local leftWing = Instance.new("Folder")
    leftWing.Name = "LeftWing"
    leftWing.Parent = floor2

    -- ห้องน้ำมุมหน้าซ้าย (Men's Restroom)
    local toiletFL = Instance.new("Model")
    toiletFL.Name = "Toilet_FrontLeft_Men"
    toiletFL.Parent = leftWing
    PartBuilder.makePart(toiletFL, "Wall", Vector3.new(18, fH, 18), CFrame.new(-bW/2 + 10, f2BaseY + fH/2, 48), PartBuilder.COLORS.creamLight)
    PartBuilder.makePart(toiletFL, "Door", Vector3.new(4.2, 8.5, 0.5), CFrame.new(-bW/2 + 19.2, f2BaseY + 4.25, 48), Color3.fromRGB(30, 80, 160), Enum.Material.Metal)
    PartBuilder.makeSign(toiletFL, "Sign", "🚹 ห้องน้ำชาย (MEN)", Vector3.new(4.5, 1.4, 0.2), Vector3.new(-bW/2 + 19.4, f2BaseY + 9.5, 48), Enum.NormalId.Back, Color3.fromRGB(30, 80, 160))

    -- ร้านข้าวฝั่งซ้าย (4 Food Stalls Line)
    local leftStalls = {
        { Name = "ร้านข้าวนัมเบอร์วัน มจพ.", Menu = "ข้าวราดแกงบุฟเฟต์ / ต้มยำ / พะแนงหมู", Color = PartBuilder.COLORS.maroon },
        { Name = "ก๋วยเตี๋ยวต้มยำโบราณตึก 40", Menu = "ก๋วยเตี๋ยวเรือ / ต้มยำน้ำข้น / เย็นตาโฟ", Color = Color3.fromRGB(30, 90, 160) },
        { Name = "ข้าวมันไก่-ข้าวหมูกรอบ มจพ.", Menu = "ข้าวมันไก่ต้ม-ไก่ทอด / ข้าวหมูแดง", Color = Color3.fromRGB(180, 90, 30) },
        { Name = "ร้านอาหารตามสั่งเด็กวิศวะ", Menu = "กะเพราถาด / ผัดพริกแกง / ข้าวผัดรถไฟ", Color = Color3.fromRGB(40, 130, 70) },
    }
    for i, st in ipairs(leftStalls) do
        local stZ = 24 - ((i - 1) * 16)
        local stModel = Instance.new("Model")
        stModel.Name = "FoodStall_L_" .. i
        stModel.Parent = leftWing

        -- ผนังล็อคร้าน
        PartBuilder.makePart(stModel, "StallBack", Vector3.new(1.2, fH, 14), CFrame.new(-bW/2 + 1, f2BaseY + fH/2, stZ), PartBuilder.COLORS.cream)
        PartBuilder.makePart(stModel, "Counter", Vector3.new(12, 3.8, 4.5), CFrame.new(-bW/2 + 14, f2BaseY + 1.9, stZ), PartBuilder.COLORS.tileLight, Enum.Material.SmoothPlastic)
        PartBuilder.makePart(stModel, "GlassShowcase", Vector3.new(10, 2.4, 3), CFrame.new(-bW/2 + 14, f2BaseY + 4.2, stZ), PartBuilder.COLORS.glass, Enum.Material.Glass, { Transparency = 0.65 })
        PartBuilder.makePart(stModel, "Awning", Vector3.new(12, 0.8, 3.5), CFrame.new(-bW/2 + 14, f2BaseY + 7.5, stZ + 1.5) * CFrame.Angles(math.rad(15), 0, 0), st.Color, Enum.Material.Fabric)
        PartBuilder.makeSign(stModel, "Sign", st.Name .. "\n" .. st.Menu, Vector3.new(12, 2.2, 0.4), Vector3.new(-bW/2 + 14, f2BaseY + 9.5, stZ + 2.0), Enum.NormalId.Back, st.Color)
    end

    -- ห้องน้ำมุมหลังซ้าย (Women's Restroom)
    local toiletRL = Instance.new("Model")
    toiletRL.Name = "Toilet_RearLeft_Women"
    toiletRL.Parent = leftWing
    PartBuilder.makePart(toiletRL, "Wall", Vector3.new(18, fH, 18), CFrame.new(-bW/2 + 10, f2BaseY + fH/2, -48), PartBuilder.COLORS.creamLight)
    PartBuilder.makePart(toiletRL, "Door", Vector3.new(4.2, 8.5, 0.5), CFrame.new(-bW/2 + 19.2, f2BaseY + 4.25, -48), Color3.fromRGB(180, 40, 80), Enum.Material.Metal)
    PartBuilder.makeSign(toiletRL, "Sign", "🚺 ห้องน้ำหญิง (WOMEN)", Vector3.new(4.5, 1.4, 0.2), Vector3.new(-bW/2 + 19.4, f2BaseY + 9.5, -48), Enum.NormalId.Back, Color3.fromRGB(180, 40, 80))

    ------------------------------------------------------------------
    -- 5. ปีกขวา: ห้องน้ำ (หน้า) + ร้านน้ำ/ร้านข้าว 4 ร้าน + ห้องน้ำ (หลัง)
    ------------------------------------------------------------------
    local rightWing = Instance.new("Folder")
    rightWing.Name = "RightWing"
    rightWing.Parent = floor2

    -- ห้องน้ำมุมหน้าขวา (Staff Restroom)
    local toiletFR = Instance.new("Model")
    toiletFR.Name = "Toilet_FrontRight_Staff"
    toiletFR.Parent = rightWing
    PartBuilder.makePart(toiletFR, "Wall", Vector3.new(18, fH, 18), CFrame.new(bW/2 - 10, f2BaseY + fH/2, 48), PartBuilder.COLORS.creamLight)
    PartBuilder.makePart(toiletFR, "Door", Vector3.new(4.2, 8.5, 0.5), CFrame.new(bW/2 - 19.2, f2BaseY + 4.25, 48), PartBuilder.COLORS.darkGrey, Enum.Material.Metal)
    PartBuilder.makeSign(toiletFR, "Sign", "🚻 ห้องน้ำอาจารย์ / บุคลากร", Vector3.new(4.5, 1.4, 0.2), Vector3.new(bW/2 - 19.4, f2BaseY + 9.5, 48), Enum.NormalId.Back, PartBuilder.COLORS.orange)

    -- ร้านน้ำและร้านอาหารฝั่งขวา (4 Beverage & Food Stalls Line)
    local rightStalls = {
        { Name = "ร้านน้ำปั่น & ชานมไข่มุกตึก 40", Menu = "ชานมไต้หวัน / สมูทตี้ผลไม้ / กาแฟสด", Color = Color3.fromRGB(35, 120, 180) },
        { Name = "ส้มตำ-ไก่ย่าง แซ่บ มจพ.", Menu = "ส้มตำไทย-ปูปลาร้า / ลาบหมู / ไก่ทอดหาดใหญ่", Color = Color3.fromRGB(200, 70, 30) },
        { Name = "ร้านผลไม้สด & ขนมหวาน มจพ.", Menu = "แตงโม / สับปะรด / ลอดช่องน้ำกะทิ / รวมมิตร", Color = Color3.fromRGB(45, 145, 75) },
        { Name = "ปังปิ้งเนยนม & กาแฟโบราณ", Menu = "ปังปิ้งสังขยา / ชาชัก / นมสดร้อน / ไข่ลวก", Color = Color3.fromRGB(150, 95, 45) },
    }
    for i, st in ipairs(rightStalls) do
        local stZ = 24 - ((i - 1) * 16)
        local stModel = Instance.new("Model")
        stModel.Name = "FoodStall_R_" .. i
        stModel.Parent = rightWing

        PartBuilder.makePart(stModel, "StallBack", Vector3.new(1.2, fH, 14), CFrame.new(bW/2 - 1, f2BaseY + fH/2, stZ), PartBuilder.COLORS.cream)
        PartBuilder.makePart(stModel, "Counter", Vector3.new(12, 3.8, 4.5), CFrame.new(bW/2 - 14, f2BaseY + 1.9, stZ), PartBuilder.COLORS.tileLight, Enum.Material.SmoothPlastic)
        PartBuilder.makePart(stModel, "GlassShowcase", Vector3.new(10, 2.4, 3), CFrame.new(bW/2 - 14, f2BaseY + 4.2, stZ), PartBuilder.COLORS.glass, Enum.Material.Glass, { Transparency = 0.65 })
        PartBuilder.makePart(stModel, "Awning", Vector3.new(12, 0.8, 3.5), CFrame.new(bW/2 - 14, f2BaseY + 7.5, stZ + 1.5) * CFrame.Angles(math.rad(15), 0, 0), st.Color, Enum.Material.Fabric)
        PartBuilder.makeSign(stModel, "Sign", st.Name .. "\n" .. st.Menu, Vector3.new(12, 2.2, 0.4), Vector3.new(bW/2 - 14, f2BaseY + 9.5, stZ + 2.0), Enum.NormalId.Back, st.Color)
    end

    -- ห้องน้ำมุมหลังขวา (General Restroom)
    local toiletRR = Instance.new("Model")
    toiletRR.Name = "Toilet_RearRight_General"
    toiletRR.Parent = rightWing
    PartBuilder.makePart(toiletRR, "Wall", Vector3.new(18, fH, 18), CFrame.new(bW/2 - 10, f2BaseY + fH/2, -48), PartBuilder.COLORS.creamLight)
    PartBuilder.makePart(toiletRR, "Door", Vector3.new(4.2, 8.5, 0.5), CFrame.new(bW/2 - 19.2, f2BaseY + 4.25, -48), PartBuilder.COLORS.steel, Enum.Material.Metal)
    PartBuilder.makeSign(toiletRR, "Sign", "🚻 ห้องน้ำ (RESTROOM)", Vector3.new(4.5, 1.4, 0.2), Vector3.new(bW/2 - 19.4, f2BaseY + 9.5, -48), Enum.NormalId.Back, PartBuilder.COLORS.maroon)

    ------------------------------------------------------------------
    -- 6. ลานรับประทานอาหารตรงกลาง (CENTRAL DINING HALL ตามภาพแปลน)
    -- โต๊ะอาหารสแตนเลสพร้อมเก้าอี้กลม มจพ. จัดเป็นแถวระเบียบ สามารถกระโดดขึ้นโต๊ะหลบซอมบี้ได้
    ------------------------------------------------------------------
    local diningHall = Instance.new("Folder")
    diningHall.Name = "CentralDiningHall"
    diningHall.Parent = floor2

    for row = 1, 4 do
        for col = 1, 4 do
            local tX = -27 + ((col - 1) * 18)
            local tZ = 20 - ((row - 1) * 13)

            local tableModel = Instance.new("Model")
            tableModel.Name = string.format("DiningTable_%d_%d", row, col)
            tableModel.Parent = diningHall

            -- โต๊ะสแตนเลส (หนา 3.2 studs กระโดดขึ้นยืนได้)
            local tableTop = PartBuilder.makePart(
                tableModel,
                "TableTop",
                Vector3.new(12, 0.6, 4.5),
                CFrame.new(tX, f2BaseY + 3.1, tZ),
                PartBuilder.COLORS.steel,
                Enum.Material.Metal
            )
            -- ขาโต๊ะสแตนเลส 4 ขา
            for _, dx in ipairs({ -5, 5 }) do
                for _, dz in ipairs({ -1.8, 1.8 }) do
                    PartBuilder.makeCylinder(tableModel, "Leg", Vector3.new(3.0, 0.4, 0.4), CFrame.new(tX + dx, f2BaseY + 1.5, tZ + dz) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
                end
            end

            -- เก้าอี้กลมสแตนเลส 6 ตัวประกบสองฝั่ง
            for _, sZ in ipairs({ tZ - 3.2, tZ + 3.2 }) do
                for sIdx = 1, 3 do
                    local sX = (tX - 4) + ((sIdx - 1) * 4)
                    PartBuilder.makeCylinder(tableModel, "StoolTop", Vector3.new(0.4, 1.8, 1.8), CFrame.new(sX, f2BaseY + 1.8, sZ) * CFrame.Angles(0, 0, math.rad(90)), PartBuilder.COLORS.warmGrey, Enum.Material.Metal)
                    PartBuilder.makeCylinder(tableModel, "StoolLeg", Vector3.new(1.8, 0.3, 0.3), CFrame.new(sX, f2BaseY + 0.9, sZ) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
                end
            end
        end
    end

    ------------------------------------------------------------------
    -- 7. โซนด้านหลัง (REAR ZONE ตามภาพแปลน)
    -- ลิฟต์ (ซ้าย) / ทางเข้าออก (กลาง) / บันได (ขวา) / ห้องเก็บของ / ที่เก็บจาน
    ------------------------------------------------------------------
    local rearZone = Instance.new("Folder")
    rearZone.Name = "RearZone"
    rearZone.Parent = floor2

    -- ทางเข้าออกด้านหลัง (Rear Exit Doors)
    PartBuilder.makePart(rearZone, "RearDoorHeader", Vector3.new(20, 2.5, 2.0), CFrame.new(0, f2BaseY + fH - 1.25, -bL/2), PartBuilder.COLORS.darkGrey, Enum.Material.Metal)
    PartBuilder.makePart(rearZone, "RearDoor_L", Vector3.new(8.5, fH - 2.5, 0.4), CFrame.new(-4.8, f2BaseY + (fH - 2.5)/2, -bL/2), PartBuilder.COLORS.glass, Enum.Material.Glass, { Transparency = 0.6 })
    PartBuilder.makePart(rearZone, "RearDoor_R", Vector3.new(8.5, fH - 2.5, 0.4), CFrame.new(4.8, f2BaseY + (fH - 2.5)/2, -bL/2), PartBuilder.COLORS.glass, Enum.Material.Glass, { Transparency = 0.6 })

    -- ลิฟต์หลังฝั่งซ้าย (Rear Left Elevators)
    local rearLift = Instance.new("Model")
    rearLift.Name = "RearElevators_Left"
    rearLift.Parent = rearZone
    PartBuilder.makePart(rearLift, "LiftWall_RL", Vector3.new(18, fH, 1.4), CFrame.new(-23, f2BaseY + fH/2, -48), PartBuilder.COLORS.cream)
    for el = 1, 2 do
        local elX = -28 + ((el - 1) * 10)
        PartBuilder.makePart(rearLift, "Door_" .. el, Vector3.new(6.8, 10.5, 0.4), CFrame.new(elX, f2BaseY + 5.25, -48.8), PartBuilder.COLORS.steel, Enum.Material.Metal)
        PartBuilder.makeSign(rearLift, "Ind_" .. el, "[ 2 ] ▼", Vector3.new(2.4, 1.0, 0.2), Vector3.new(elX, f2BaseY + 11.5, -48.9), Enum.NormalId.Back, Color3.fromRGB(20, 20, 25), Color3.fromRGB(255, 140, 0))
    end

    -- บันไดหลังฝั่งขวา (Rear Right Stairs / Emergency Fire Stairs)
    local rearStair = Instance.new("Model")
    rearStair.Name = "RearStairs_Right"
    rearStair.Parent = rearZone
    PartBuilder.makePart(rearStair, "StairWall_RR", Vector3.new(18, fH, 1.4), CFrame.new(23, f2BaseY + fH/2, -48), PartBuilder.COLORS.cream)
    PartBuilder.makePart(rearStair, "FireDoor", Vector3.new(4.5, 9, 0.6), CFrame.new(23, f2BaseY + 4.5, -48.8), PartBuilder.COLORS.maroon, Enum.Material.Metal)
    PartBuilder.makeSign(rearStair, "Sign", "EXIT // ทางหนีไฟฉุกเฉิน", Vector3.new(4.2, 1.4, 0.2), Vector3.new(23, f2BaseY + 10.2, -48.9), Enum.NormalId.Back, Color3.fromRGB(20, 160, 60))

    -- ห้องเก็บของด้านหลัง (Food Storage / Utility Room ด้านหลังซ้าย)
    local roomRL = Instance.new("Model")
    roomRL.Name = "UtilityRoom_RearLeft"
    roomRL.Parent = rearZone
    PartBuilder.makePart(roomRL, "Wall", Vector3.new(18, fH, 1.2), CFrame.new(-22, f2BaseY + fH/2, -38), PartBuilder.COLORS.cream)
    PartBuilder.makePart(roomRL, "Door", Vector3.new(4.5, 9, 0.4), CFrame.new(-22, f2BaseY + 4.5, -37.5), PartBuilder.COLORS.wood, Enum.Material.Wood)
    PartBuilder.makeSign(roomRL, "Sign", "ห้องเก็บอุปกรณ์และวัตถุดิบอาหาร\nCANTEEN STORAGE ROOM", Vector3.new(14, 1.8, 0.3), Vector3.new(-22, f2BaseY + 7.5, -37.3), Enum.NormalId.Back, PartBuilder.COLORS.darkGrey)

    -- ที่เก็บจานด้านหลัง (Dish Return Station ด้านหลังขวา)
    local dishReturnRear = Instance.new("Model")
    dishReturnRear.Name = "DishReturn_RearRight"
    dishReturnRear.Parent = rearZone
    PartBuilder.makePart(dishReturnRear, "Wall", Vector3.new(18, fH, 1.2), CFrame.new(22, f2BaseY + fH/2, -38), PartBuilder.COLORS.cream)
    PartBuilder.makePart(dishReturnRear, "TrayRack", Vector3.new(14, 6.5, 3.5), CFrame.new(22, f2BaseY + 3.25, -34.5), PartBuilder.COLORS.steel, Enum.Material.Metal)
    PartBuilder.makePart(dishReturnRear, "WasteBin", Vector3.new(3, 3.5, 3), CFrame.new(17, f2BaseY + 1.75, -34.5), Color3.fromRGB(40, 120, 60), Enum.Material.SmoothPlastic)
    PartBuilder.makeSign(dishReturnRear, "Sign", "จุดส่งคืนภาชนะและเศษอาหาร (หลัง)\nDISH & TRAY RETURN REAR", Vector3.new(14, 1.8, 0.3), Vector3.new(22, f2BaseY + 7.5, -37.3), Enum.NormalId.Back, PartBuilder.COLORS.maroon)

    ------------------------------------------------------------------
    -- 8. ระบบเกมเพลย์ซอมบี้บนชั้น 2 (WALL BUYS & PERK MACHINE)
    ------------------------------------------------------------------
    local gameplayFolder = Instance.new("Folder")
    gameplayFolder.Name = "Gameplay_Floor2"
    gameplayFolder.Parent = floor2

    -- ฟังก์ชันสร้างจุด Wall Buy
    local function createWallBuySpot(weaponName, cost, pos, rotY)
        local plate = PartBuilder.makePart(
            gameplayFolder,
            "WallBuy_" .. weaponName,
            Vector3.new(5.5, 3.6, 0.3),
            CFrame.new(pos) * CFrame.Angles(0, rotY, 0),
            Color3.fromRGB(24, 28, 36),
            Enum.Material.Metal
        )
        plate:SetAttribute("WeaponType", weaponName)
        plate:SetAttribute("Cost", cost)

        local outline = Instance.new("SelectionBox")
        outline.Color3 = Color3.fromRGB(255, 200, 50)
        outline.Adornee = plate
        outline.Parent = plate

        local gui = Instance.new("SurfaceGui")
        gui.Face = Enum.NormalId.Back
        gui.Parent = plate

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.fromRGB(255, 220, 80)
        txt.TextScaled = true
        txt.Font = Enum.Font.GothamBold
        txt.Text = string.format("🔫 %s\n[%d PTS]", weaponName:upper(), cost)
        txt.Parent = gui

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "ซื้อ " .. weaponName
        prompt.ObjectText = cost .. " Points"
        prompt.HoldDuration = 0.4
        prompt.MaxActivationDistance = 9
        prompt.Parent = plate
    end

    -- ปืนลูกซอง Bucky 900 แต้ม (ติดฝั่งร้านข้าวซ้าย)
    createWallBuySpot("Bucky", 900, Vector3.new(-bW/2 + 2, f2BaseY + 5.0, 5), math.rad(90))
    -- ปืนกลเบา Spectre 1,600 แต้ม (ติดฝั่งร้านน้ำขวา)
    createWallBuySpot("Spectre", 1600, Vector3.new(bW/2 - 2, f2BaseY + 5.0, 5), math.rad(-90))
    -- ปืนลูกซองรัว Judge 1,850 แต้ม (ติดใกล้โซนเก็บจาน)
    createWallBuySpot("Judge", 1850, Vector3.new(-12, f2BaseY + 5.0, 39), 0)

    -- 🌟 ตู้ Perk: ตู้กดน้ำอัตโนมัติ มจพ. (KMUTNB Juggernog Energy Drink +100 Max HP)
    local perkMachine = Instance.new("Model")
    perkMachine.Name = "Perk_KMUTNB_Juggernog"
    perkMachine.Parent = gameplayFolder

    local perkBody = PartBuilder.makePart(
        perkMachine,
        "VendingMachine",
        Vector3.new(4.5, 8.5, 3.8),
        CFrame.new(12, f2BaseY + 4.25, 39),
        Color3.fromRGB(220, 35, 45),
        Enum.Material.Metal
    )
    PartBuilder.makePart(
        perkMachine,
        "VendingGlass",
        Vector3.new(3.6, 4.5, 0.4),
        CFrame.new(12, f2BaseY + 5.2, 37.0),
        Color3.fromRGB(80, 240, 200),
        Enum.Material.Neon
    )
    PartBuilder.makeSign(
        perkMachine,
        "PerkSign",
        "⚡ KMUTNB ENERGY\n+100 HP PERK\n[ 2,500 PTS ]",
        Vector3.new(4.2, 2.2, 0.2),
        Vector3.new(12, f2BaseY + 7.5, 37.0),
        Enum.NormalId.Back,
        Color3.fromRGB(255, 180, 20),
        Color3.fromRGB(20, 20, 25)
    )
    local perkPrompt = Instance.new("ProximityPrompt")
    perkPrompt.ActionText = "ดื่มเครื่องดื่มชูกำลัง มจพ. (+100 Max HP)"
    perkPrompt.ObjectText = "2,500 Points"
    perkPrompt.HoldDuration = 1.0
    perkPrompt.MaxActivationDistance = 9
    perkPrompt.Parent = perkBody

    perkPrompt.Triggered:Connect(function(player)
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MaxHealth < 200 then
            hum.MaxHealth = 200
            hum.Health = 200
            perkPrompt.Enabled = false
        end
    end)

    -- แนวกั้นไม้หน้าต่างชั้น 2 (Window Barricades)
    local function createBarricadeSpot(name, pos, rotY)
        local bModel = Instance.new("Model")
        bModel.Name = name
        bModel.Parent = gameplayFolder

        local frame = PartBuilder.makePart(bModel, "Frame", Vector3.new(9, 7.5, 1.2), CFrame.new(pos) * CFrame.Angles(0, rotY, 0), Color3.fromRGB(45, 48, 55), Enum.Material.Wood)
        frame.Transparency = 1
        frame.CanCollide = false
        for p = 1, 5 do
            local pY = (pos.Y - 2.8) + (p * 1.1)
            PartBuilder.makePart(bModel, "Plank_" .. p, Vector3.new(8.5, 0.9, 0.4), CFrame.new(pos.X, pY, pos.Z) * CFrame.Angles(0, rotY, math.rad((p % 2 == 0) and 3 or -3)), Color3.fromRGB(115, 78, 48), Enum.Material.WoodPlanks)
        end
    end
    createBarricadeSpot("Barricade_F2_L1", Vector3.new(-bW/2 + 1, f2BaseY + 5.0, 10), math.rad(90))
    createBarricadeSpot("Barricade_F2_L2", Vector3.new(-bW/2 + 1, f2BaseY + 5.0, -10), math.rad(90))
    createBarricadeSpot("Barricade_F2_R1", Vector3.new(bW/2 - 1, f2BaseY + 5.0, 10), math.rad(-90))
    createBarricadeSpot("Barricade_F2_R2", Vector3.new(bW/2 - 1, f2BaseY + 5.0, -10), math.rad(-90))

    -- ไฟเพดานโรงอาหารชั้น 2 (Ceiling Lights Grid)
    local lights = Instance.new("Folder")
    lights.Name = "CeilingLights"
    lights.Parent = floor2
    for lx = -bW/2 + 20, bW/2 - 20, 24 do
        for lz = -bL/2 + 20, bL/2 - 20, 24 do
            PartBuilder.addPointLight(lights, string.format("Light_F2_%d_%d", math.floor(lx), math.floor(lz)), Vector3.new(lx, f2BaseY + fH - 0.4, lz), Color3.fromRGB(255, 248, 235), 28, 1.4)
        end
    end

    print("🍜 [Floor2_Canteen] สร้างชั้น 2 โรงอาหาร 40 ปี สจพ. (ตรงตามภาพแปลนจริง 100% พร้อมบันไดใหญ่หน้าตึก) สำเร็จครบถ้วน!")
end

return Floor2_Canteen
