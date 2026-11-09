--[[
    Floor2_Canteen.lua
    โครงสร้างและรายละเอียดชั้น 2 (Floor 2): โรงอาหาร 40 ปี สจพ. (มจพ.)
    สร้างตรงตามภาพแปลนลายเส้น (media_1794241774064_60e8d531.png)
    และภาพถ่ายจริง Google Street View (media_1794241774088_9b422119.jpg)
    
    สเกลขยาย 2 เท่า (Footprint 300 x 240 studs, ความสูง 23 studs ถึง 45 studs):
      1. บันไดใหญ่หน้าตึก (Outdoor Grand Stairs) มีหลังคาโค้ง + ป้าย "โรงอาหาร 40 ปี สจพ." พร้อมตรา Coke
      2. โซนด้านหน้า (Bottom Core): บันได (ซ้าย) / ทางเข้าออก (กลาง) / ลิฟต์ (ขวา) ตรงกับชั้น 1
      3. โซนด้านในหน้า (Inner Bottom): ที่เก็บจาน (ซ้าย) / ห้องสำนักงาน (ขวา)
      4. มุมทั้ง 4 (4 Corners): ห้องน้ำทั้ง 4 มุม (ซ้ายบน, ขวาบน, ซ้ายล่าง, ขวาล่าง)
      5. ปีกซ้าย (West Wing): แถวร้านข้าว (ข้าวมันไก่, ข้าวแกง, ก๋วยเตี๋ยวเรือ, ข้าวหมูกรอบ)
      6. ปีกขวา (East Wing): แถวร้านข้าว & ร้านน้ำ (ชานมไข่มุก/กาแฟโบราณ, ผลไม้/น้ำปั่น, อาหารตามสั่ง)
      7. โซนด้านในหลัง (Inner Top): ห้องพัสดุ (ซ้าย) / ที่เก็บจาน (ขวา)
      8. โซนด้านหลัง (Top Core): ลิฟต์ (ซ้าย) / ทางเข้าออก (กลาง) / บันได (ขวา) ตรงกับชั้น 1
      9. กลางโรงอาหาร (Center Dining Hall): โต๊ะสแตนเลส มจพ. พร้อมเก้าอี้กลม, ถังขยะแยกประเภท, ไฟส่องสว่าง
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local Floor2_Canteen = {}

function Floor2_Canteen.build(parent)
    local floor2 = Instance.new("Model")
    floor2.Name = "Floor_2_Canteen"
    floor2.Parent = parent

    -- ระดับความสูงและขนาด (2X Scale ให้ตรงกับชั้น 1)
    local floorY = 23.0        -- พื้นชั้น 2 อยู่เหนือชั้น 1 (Y = 1 + 22)
    local wallH = 22.0         -- ความสูงผนังชั้น 2 (22 studs, เพดานที่ Y = 45)
    local wallThick = 2.0
    local wallColor = Color3.fromRGB(244, 241, 235)
    local wallMaterial = Enum.Material.Concrete
    local tileColor = Color3.fromRGB(238, 234, 226)

    ------------------------------------------------------------------
    -- 1. พื้นฐานชั้น 2 (Floor 2 Slab 300 x 240 studs)
    -- เว้นช่องบันได (Stair Openings) ทั้ง 2 ฝั่งเพื่อเดินขึ้นมาจากชั้น 1
    ------------------------------------------------------------------
    -- พื้นหลักตรงกลางและปีกข้าง (Main Floor Slab)
    PartBuilder.makePart(
        floor2,
        "Floor2_BaseSlab_Center",
        Vector3.new(300, 2.0, 148),
        CFrame.new(0, floorY - 1.0, 0),
        tileColor,
        Enum.Material.SmoothPlastic
    )
    -- พื้นโซนหลัง (North Floor Slab เว้นช่องบันไดขวา X = 47.5, Z = -97)
    PartBuilder.makePart(floor2, "Floor2_Slab_North_Left", Vector3.new(175, 2.0, 46), CFrame.new(-62.5, floorY - 1.0, -97), tileColor, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(floor2, "Floor2_Slab_North_Right", Vector3.new(80, 2.0, 46), CFrame.new(110, floorY - 1.0, -97), tileColor, Enum.Material.SmoothPlastic)

    -- พื้นโซนหน้า (South Floor Slab เว้นช่องบันไดซ้าย X = -47.5, Z = 97)
    PartBuilder.makePart(floor2, "Floor2_Slab_South_Left", Vector3.new(80, 2.0, 46), CFrame.new(-110, floorY - 1.0, 97), tileColor, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(floor2, "Floor2_Slab_South_Right", Vector3.new(175, 2.0, 46), CFrame.new(62.5, floorY - 1.0, 97), tileColor, Enum.Material.SmoothPlastic)

    ------------------------------------------------------------------
    -- 2. บันไดใหญ่หน้าตึก (GRAND OUTDOOR STAIRS ตามรูปภาพ GOOGLE STREET VIEW)
    -- มีป้าย "โรงอาหาร 40 ปี สจพ." พร้อมตรา Coca-Cola สองข้าง และหลังคาโค้ง
    ------------------------------------------------------------------
    local outdoorStairs = Instance.new("Model")
    outdoorStairs.Name = "OutdoorGrandStairs_Front"
    outdoorStairs.Parent = floor2

    local stairZ = 120 + 26  -- Z = 146
    local landingW = 60
    local landingL = 36

    -- ชานพักลอยฟ้าหน้าโรงอาหารชั้น 2 (Elevated Bridge Landing)
    PartBuilder.makePart(
        outdoorStairs,
        "GrandLandingPlatform",
        Vector3.new(landingW, 2.0, landingL),
        CFrame.new(0, floorY - 1.0, stairZ),
        Color3.fromRGB(228, 222, 214),
        Enum.Material.Concrete
    )

    -- ทางเชื่อมจากชานพักเข้าสู่ตัวอาคารชั้น 2 (Bridge to building entrance)
    PartBuilder.makePart(
        outdoorStairs,
        "GrandEntranceBridge",
        Vector3.new(44, 2.0, 26),
        CFrame.new(0, floorY - 1.0, 120 + 13),
        Color3.fromRGB(228, 222, 214),
        Enum.Material.Concrete
    )

    -- ราวกันตกชานพักลอยฟ้าสีส้มอิฐ (Peach/Orange Facade Balustrade ตามภาพถ่ายจริง)
    PartBuilder.makePart(outdoorStairs, "Rail_Front", Vector3.new(landingW, 4.2, 1.5), CFrame.new(0, floorY + 2.1, stairZ + landingL/2), Color3.fromRGB(235, 138, 88), Enum.Material.Concrete)
    PartBuilder.makePart(outdoorStairs, "Rail_Bridge_L", Vector3.new(1.5, 4.2, 26), CFrame.new(-22, floorY + 2.1, 120 + 13), Color3.fromRGB(235, 138, 88), Enum.Material.Concrete)
    PartBuilder.makePart(outdoorStairs, "Rail_Bridge_R", Vector3.new(1.5, 4.2, 26), CFrame.new(22, floorY + 2.1, 120 + 13), Color3.fromRGB(235, 138, 88), Enum.Material.Concrete)

    -- 🌟 ป้ายชื่อ "โรงอาหาร 40 ปี สจพ." ขนาดใหญ่ (Facade Signboard ตรงตามรูปภาพ 100%)
    PartBuilder.makeSign(
        outdoorStairs,
        "GrandCanteenSign",
        "โรงอาหาร 40 ปี\nสจพ. (มจพ.)",
        Vector3.new(24, 6.0, 0.8),
        Vector3.new(0, floorY + 3.0, stairZ + landingL/2 + 0.9),
        Enum.NormalId.Back,
        Color3.fromRGB(250, 250, 248),
        Color3.fromRGB(0, 135, 68) -- สีเขียวเอกลักษณ์
    )
    -- ตราโลโก้ Coca-Cola สีแดงขนาบข้างสองฝั่ง
    PartBuilder.makeSign(
        outdoorStairs,
        "CokeBadge_Left",
        "Coke",
        Vector3.new(5.0, 5.0, 0.9),
        Vector3.new(-15, floorY + 3.0, stairZ + landingL/2 + 0.9),
        Enum.NormalId.Back,
        Color3.fromRGB(220, 20, 30),
        Color3.fromRGB(255, 255, 255)
    )
    PartBuilder.makeSign(
        outdoorStairs,
        "CokeBadge_Right",
        "Coke",
        Vector3.new(5.0, 5.0, 0.9),
        Vector3.new(15, floorY + 3.0, stairZ + landingL/2 + 0.9),
        Enum.NormalId.Back,
        Color3.fromRGB(220, 20, 30),
        Color3.fromRGB(255, 255, 255)
    )

    -- เสากลมค้ำชานพักบันไดใหญ่จากชั้น 1 (Pillars Y=1 to Y=23)
    for _, px in ipairs({ -18, 18 }) do
        PartBuilder.makeCylinder(
            outdoorStairs,
            "GrandStairPillar_" .. px,
            Vector3.new(22, 3.2, 3.2),
            CFrame.new(px, 12.0, stairZ) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(245, 240, 230),
            Enum.Material.Concrete
        )
    end

    -- บันไดใหญ่สองปีก ซ้าย-ขวา ทอดลงสู่พื้นลานด้านล่าง (Left & Right Sweeping Staircases)
    local stepCount = 20
    local stepRise = (floorY - 1.0) / stepCount -- 22 / 20 = 1.1 studs
    local stepRun = 3.6

    -- ปีกบันไดฝั่งซ้าย (Sweeping Left Flight)
    for s = 1, stepCount do
        local curY = 1.0 + (s - 0.5) * stepRise
        local curX = -(landingW/2) - (s * stepRun)
        PartBuilder.makePart(
            outdoorStairs,
            "Step_L_" .. s,
            Vector3.new(stepRun + 0.2, stepRise, 20),
            CFrame.new(curX, curY, stairZ),
            Color3.fromRGB(225, 140, 75),
            Enum.Material.Concrete
        )
    end

    -- ปีกบันไดฝั่งขวา (Sweeping Right Flight)
    for s = 1, stepCount do
        local curY = 1.0 + (s - 0.5) * stepRise
        local curX = (landingW/2) + (s * stepRun)
        PartBuilder.makePart(
            outdoorStairs,
            "Step_R_" .. s,
            Vector3.new(stepRun + 0.2, stepRise, 20),
            CFrame.new(curX, curY, stairZ),
            Color3.fromRGB(225, 140, 75),
            Enum.Material.Concrete
        )
    end

    -- โครงหลังคาโค้งกันแดด-ฝนเหนือบันได (Curved Canopy Roof ตามภาพจริง)
    PartBuilder.makePart(
        outdoorStairs,
        "CanopyRoof_Center",
        Vector3.new(landingW + 8, 1.2, landingL + 12),
        CFrame.new(0, floorY + 16, stairZ),
        Color3.fromRGB(55, 65, 75),
        Enum.Material.Metal
    )

    -- โต๊ะม้านั่งหินใต้บันไดชั้นล่าง (Picnic stone tables as seen in photo)
    for _, tx in ipairs({ -10, 10 }) do
        PartBuilder.makePart(outdoorStairs, "PicnicTable_" .. tx, Vector3.new(12, 1.2, 4), CFrame.new(tx, 2.8, stairZ), Color3.fromRGB(210, 205, 195), Enum.Material.Concrete)
        PartBuilder.makePart(outdoorStairs, "PicnicBench1_" .. tx, Vector3.new(12, 0.8, 2), CFrame.new(tx, 1.8, stairZ - 3.5), Color3.fromRGB(200, 195, 185), Enum.Material.Concrete)
        PartBuilder.makePart(outdoorStairs, "PicnicBench2_" .. tx, Vector3.new(12, 0.8, 2), CFrame.new(tx, 1.8, stairZ + 3.5), Color3.fromRGB(200, 195, 185), Enum.Material.Concrete)
    end

    ------------------------------------------------------------------
    -- 3. โซนด้านหน้า (South Core Z = 74 ถึง 120):
    --   - ซ้าย (X = -47.5): บันได (ตรงกับชั้น 1)
    --   - กลาง (X = 0): ทางเข้าออก (เชื่อมกับสะพานบันไดใหญ่หน้าตึก)
    --   - ขวา (X = +47.5): ลิฟต์ (ตรงกับชั้น 1)
    ------------------------------------------------------------------
    local botCore = Instance.new("Model")
    botCore.Name = "SouthCore_Entrance"
    botCore.Parent = floor2

    local botZ = 97
    local blCoreX = -47.5
    local brCoreX = 47.5

    -- ผนังแบ่งช่องบันไดซ้าย
    PartBuilder.makePart(botCore, "BotStair_W", Vector3.new(wallThick, wallH, 46), CFrame.new(blCoreX - 22.5, floorY + wallH/2, botZ), wallColor, wallMaterial)
    PartBuilder.makePart(botCore, "BotStair_S", Vector3.new(45, wallH, wallThick), CFrame.new(blCoreX, floorY + wallH/2, 120), wallColor, wallMaterial)
    PartBuilder.makeSign(botCore, "BotStairSign", "บันไดหนีไฟ (ชั้น 2)\nSTAIRS", Vector3.new(12, 3.5, 0.4), Vector3.new(blCoreX, floorY + 14, 120 - 0.3), Enum.NormalId.Back, Color3.fromRGB(20, 120, 50), Color3.fromRGB(255, 255, 255))

    -- ผนังแบ่งช่องลิฟต์ขวา
    PartBuilder.makePart(botCore, "BotLift_E", Vector3.new(wallThick, wallH, 46), CFrame.new(brCoreX + 22.5, floorY + wallH/2, botZ), wallColor, wallMaterial)
    PartBuilder.makePart(botCore, "BotLift_S", Vector3.new(45, wallH, wallThick), CFrame.new(brCoreX, floorY + wallH/2, 120), wallColor, wallMaterial)
    -- ประตูลิฟต์หันหน้าเข้าหาทางเดินกลาง (West Wall)
    PartBuilder.makePart(botCore, "BotLift_InnerWall", Vector3.new(wallThick, wallH, 46), CFrame.new(brCoreX - 22.5, floorY + wallH/2, botZ), wallColor, wallMaterial)
    for _, el in ipairs({ -10, 10 }) do
        local eZ = botZ + el
        PartBuilder.makePart(botCore, "LiftDoor_S_" .. el, Vector3.new(0.6, 16.0, 11.0), CFrame.new(brCoreX - 22.2, floorY + 8.0, eZ), PartBuilder.COLORS.steel, Enum.Material.Metal)
        PartBuilder.makeSign(botCore, "LiftInd_S_" .. el, "[ 2 ] ▲▼", Vector3.new(0.3, 2.0, 4.5), Vector3.new(brCoreX - 22.5, floorY + 17.5, eZ), Enum.NormalId.Right, Color3.fromRGB(20, 20, 25), Color3.fromRGB(255, 140, 0))
    end
    PartBuilder.makeSign(botCore, "BotLiftSign", "ลิฟต์โดยสาร (ชั้น 2)\nELEVATOR LOBBY", Vector3.new(14, 4.0, 0.4), Vector3.new(brCoreX, floorY + 14, 120 - 0.3), Enum.NormalId.Back, Color3.fromRGB(30, 40, 50), Color3.fromRGB(255, 255, 255))

    -- ประตูทางเข้าออกกลาง (Double Grand Glass Entrance Doors)
    PartBuilder.makePart(botCore, "MainEntrance_PillarL", Vector3.new(3, wallH, 3), CFrame.new(-22, floorY + wallH/2, 120), Color3.fromRGB(180, 80, 40), Enum.Material.Metal)
    PartBuilder.makePart(botCore, "MainEntrance_PillarR", Vector3.new(3, wallH, 3), CFrame.new(22, floorY + wallH/2, 120), Color3.fromRGB(180, 80, 40), Enum.Material.Metal)
    PartBuilder.makeSign(botCore, "MainEntranceSign", "ยินดีต้อนรับสู่ โรงอาหาร 40 ปี มจพ.\nKMUTNB 40-YEAR CANTEEN ENTRANCE", Vector3.new(38, 4.0, 0.5), Vector3.new(0, floorY + wallH - 3, 120), Enum.NormalId.Back, Color3.fromRGB(0, 100, 50), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 4. โซนด้านในหน้า (Inner South Z = 44 ถึง 74):
    --   - ซ้าย: ที่เก็บจาน (Dish Return Station)
    --   - ขวา: ห้องสำนักงาน / ศูนย์ควบคุม (Admin Office)
    ------------------------------------------------------------------
    local innerSouth = Instance.new("Model")
    innerSouth.Name = "InnerSouth_Facilities"
    innerSouth.Parent = floor2

    local inSZ = 59
    -- ที่เก็บจานฝั่งซ้าย (Left Dish Return)
    local dishL = Instance.new("Model")
    dishL.Name = "DishReturn_South"
    dishL.Parent = innerSouth
    PartBuilder.makePart(dishL, "Wall_Back", Vector3.new(50, wallH, wallThick), CFrame.new(-45, floorY + wallH/2, 74), wallColor, wallMaterial)
    PartBuilder.makePart(dishL, "Wall_West", Vector3.new(wallThick, wallH, 30), CFrame.new(-70, floorY + wallH/2, inSZ), wallColor, wallMaterial)
    -- เคาน์เตอร์รับจานสแตนเลส + รางส่งถาด
    PartBuilder.makePart(dishL, "Counter", Vector3.new(46, 4.0, 4.0), CFrame.new(-45, floorY + 2.0, 46), Color3.fromRGB(180, 185, 190), Enum.Material.Metal)
    PartBuilder.makePart(dishL, "TrayRack", Vector3.new(42, 6.0, 3.0), CFrame.new(-45, floorY + 7.0, 46), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
    PartBuilder.makeSign(dishL, "Sign", "จุดส่งคืนภาชนะและแยกเศษอาหาร (SOUTH)\nDISH RETURN STATION", Vector3.new(36, 3.2, 0.3), Vector3.new(-45, floorY + 12, 46 - 0.2), Enum.NormalId.Back, Color3.fromRGB(0, 120, 160), Color3.fromRGB(255, 255, 255))

    -- ถังแยกขยะเศษอาหารใต้เคาน์เตอร์
    for idx, c in ipairs({ Color3.fromRGB(30, 140, 40), Color3.fromRGB(220, 180, 20), Color3.fromRGB(30, 80, 200) }) do
        PartBuilder.makePart(dishL, "Bin_" .. idx, Vector3.new(3.5, 4.5, 3.5), CFrame.new(-58 + (idx * 6.5), floorY + 2.25, 52), c, Enum.Material.SmoothPlastic)
    end

    -- ห้องสำนักงานฝั่งขวา (Right Office Room)
    local offS = Instance.new("Model")
    offS.Name = "Office_South"
    offS.Parent = innerSouth
    PartBuilder.makePart(offS, "Wall_Back", Vector3.new(50, wallH, wallThick), CFrame.new(45, floorY + wallH/2, 74), wallColor, wallMaterial)
    PartBuilder.makePart(offS, "Wall_East", Vector3.new(wallThick, wallH, 30), CFrame.new(70, floorY + wallH/2, inSZ), wallColor, wallMaterial)
    PartBuilder.makePart(offS, "Wall_Front", Vector3.new(50, wallH, wallThick), CFrame.new(45, floorY + wallH/2, 44), wallColor, wallMaterial)
    PartBuilder.makeSign(offS, "Sign", "ห้องสำนักงานบริหารโรงอาหาร 40 ปี\nCANTEEN ADMINISTRATION OFFICE", Vector3.new(34, 3.2, 0.3), Vector3.new(45, floorY + 12, 44 - 0.2), Enum.NormalId.Back, Color3.fromRGB(40, 50, 65), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 5. โซนด้านหลัง (North Core Z = -120 ถึง -74):
    --   - ซ้าย (X = -47.5): ลิฟต์ (ตรงกับชั้น 1)
    --   - กลาง (X = 0): ทางเข้าออกหลังตึก
    --   - ขวา (X = +47.5): บันได (ตรงกับชั้น 1)
    ------------------------------------------------------------------
    local topCore = Instance.new("Model")
    topCore.Name = "NorthCore_ElevatorAndStairs"
    topCore.Parent = floor2

    local topZ = -97
    local tlCoreX = -47.5
    local trCoreX = 47.5

    -- ผนังแบ่งช่องลิฟต์ซ้าย
    PartBuilder.makePart(topCore, "TopLift_W", Vector3.new(wallThick, wallH, 46), CFrame.new(tlCoreX - 22.5, floorY + wallH/2, topZ), wallColor, wallMaterial)
    PartBuilder.makePart(topCore, "TopLift_N", Vector3.new(45, wallH, wallThick), CFrame.new(tlCoreX, floorY + wallH/2, -120), wallColor, wallMaterial)
    -- ประตูลิฟต์หันหน้าเข้าหาทางเดินกลาง (East Wall)
    PartBuilder.makePart(topCore, "TopLift_InnerWall", Vector3.new(wallThick, wallH, 46), CFrame.new(tlCoreX + 22.5, floorY + wallH/2, topZ), wallColor, wallMaterial)
    for _, el in ipairs({ -10, 10 }) do
        local eZ = topZ + el
        PartBuilder.makePart(topCore, "LiftDoor_N_" .. el, Vector3.new(0.6, 16.0, 11.0), CFrame.new(tlCoreX + 22.2, floorY + 8.0, eZ), PartBuilder.COLORS.steel, Enum.Material.Metal)
        PartBuilder.makeSign(topCore, "LiftInd_N_" .. el, "[ 2 ] ▲▼", Vector3.new(0.3, 2.0, 4.5), Vector3.new(tlCoreX + 22.5, floorY + 17.5, eZ), Enum.NormalId.Left, Color3.fromRGB(20, 20, 25), Color3.fromRGB(255, 140, 0))
    end
    PartBuilder.makeSign(topCore, "TopLiftSign", "ลิฟต์โดยสาร (ชั้น 2)\nELEVATOR LOBBY", Vector3.new(14, 4.0, 0.4), Vector3.new(tlCoreX, floorY + 14, -120 + 0.3), Enum.NormalId.Front, Color3.fromRGB(30, 40, 50), Color3.fromRGB(255, 255, 255))

    -- ผนังแบ่งช่องบันไดขวา
    PartBuilder.makePart(topCore, "TopStair_E", Vector3.new(wallThick, wallH, 46), CFrame.new(trCoreX + 22.5, floorY + wallH/2, topZ), wallColor, wallMaterial)
    PartBuilder.makePart(topCore, "TopStair_N", Vector3.new(45, wallH, wallThick), CFrame.new(trCoreX, floorY + wallH/2, -120), wallColor, wallMaterial)
    PartBuilder.makeSign(topCore, "TopStairSign", "บันไดหนีไฟ (ชั้น 2)\nSTAIRS", Vector3.new(12, 3.5, 0.4), Vector3.new(trCoreX, floorY + 14, -120 + 0.3), Enum.NormalId.Front, Color3.fromRGB(20, 120, 50), Color3.fromRGB(255, 255, 255))

    -- ทางเข้าออกหลังตึก (North Rear Corridor)
    PartBuilder.makePart(topCore, "NorthExit_PillarL", Vector3.new(3, wallH, 3), CFrame.new(-22, floorY + wallH/2, -120), Color3.fromRGB(180, 80, 40), Enum.Material.Metal)
    PartBuilder.makePart(topCore, "NorthExit_PillarR", Vector3.new(3, wallH, 3), CFrame.new(22, floorY + wallH/2, -120), Color3.fromRGB(180, 80, 40), Enum.Material.Metal)
    PartBuilder.makeSign(topCore, "NorthExitSign", "ทางออกสู่สะพานลอย / อาคารข้างเคียง\nNORTH EXIT", Vector3.new(36, 3.5, 0.4), Vector3.new(0, floorY + wallH - 3, -120), Enum.NormalId.Front, Color3.fromRGB(40, 50, 60), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 6. โซนด้านในหลัง (Inner North Z = -74 ถึง -44):
    --   - ซ้าย: ห้องพัสดุ / ซ่อมบำรุง (Storage Room)
    --   - ขวา: ที่เก็บจาน (Dish Return Station)
    ------------------------------------------------------------------
    local innerNorth = Instance.new("Model")
    innerNorth.Name = "InnerNorth_Facilities"
    innerNorth.Parent = floor2

    local inNZ = -59
    -- ห้องซ้าย (Storage Room)
    local roomN = Instance.new("Model")
    roomN.Name = "Storage_North"
    roomN.Parent = innerNorth
    PartBuilder.makePart(roomN, "Wall_Back", Vector3.new(50, wallH, wallThick), CFrame.new(-45, floorY + wallH/2, -74), wallColor, wallMaterial)
    PartBuilder.makePart(roomN, "Wall_West", Vector3.new(wallThick, wallH, 30), CFrame.new(-70, floorY + wallH/2, inNZ), wallColor, wallMaterial)
    PartBuilder.makePart(roomN, "Wall_Front", Vector3.new(50, wallH, wallThick), CFrame.new(-45, floorY + wallH/2, -44), wallColor, wallMaterial)
    PartBuilder.makeSign(roomN, "Sign", "ห้องเก็บพัสดุและอุปกรณ์ทำความสะอาด\nFACILITIES & STORAGE", Vector3.new(34, 3.2, 0.3), Vector3.new(-45, floorY + 12, -44 + 0.2), Enum.NormalId.Front, Color3.fromRGB(50, 55, 60), Color3.fromRGB(255, 255, 255))

    -- ที่เก็บจานฝั่งขวา (Right Dish Return)
    local dishR = Instance.new("Model")
    dishR.Name = "DishReturn_North"
    dishR.Parent = innerNorth
    PartBuilder.makePart(dishR, "Wall_Back", Vector3.new(50, wallH, wallThick), CFrame.new(45, floorY + wallH/2, -74), wallColor, wallMaterial)
    PartBuilder.makePart(dishR, "Wall_East", Vector3.new(wallThick, wallH, 30), CFrame.new(70, floorY + wallH/2, inNZ), wallColor, wallMaterial)
    PartBuilder.makePart(dishR, "Counter", Vector3.new(46, 4.0, 4.0), CFrame.new(45, floorY + 2.0, -46), Color3.fromRGB(180, 185, 190), Enum.Material.Metal)
    PartBuilder.makePart(dishR, "TrayRack", Vector3.new(42, 6.0, 3.0), CFrame.new(45, floorY + 7.0, -46), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
    PartBuilder.makeSign(dishR, "Sign", "จุดส่งคืนภาชนะและแยกเศษอาหาร (NORTH)\nDISH RETURN STATION", Vector3.new(36, 3.2, 0.3), Vector3.new(45, floorY + 12, -46 + 0.2), Enum.NormalId.Front, Color3.fromRGB(0, 120, 160), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 7. ห้องน้ำทั้ง 4 มุม (4 Corner Restrooms):
    --   - มุมซ้ายบน (Top-Left): ห้องน้ำชาย
    --   - มุมขวาบน (Top-Right): ห้องน้ำหญิง
    --   - มุมซ้ายล่าง (Bottom-Left): ห้องน้ำหญิง
    --   - มุมขวาล่าง (Bottom-Right): ห้องน้ำชาย
    ------------------------------------------------------------------
    local restrooms = Instance.new("Model")
    restrooms.Name = "Restrooms_4Corners"
    restrooms.Parent = floor2

    local cornerW = 75
    local cornerL = 55
    local cornerH = wallH

    local cornerConfigs = {
        { name = "Restroom_TopLeft",  x = -112.5, z = -92.5, label = "ห้องน้ำชาย (MALE RESTROOM)",   color = Color3.fromRGB(20, 90, 160),  nId = Enum.NormalId.Back },
        { name = "Restroom_TopRight", x =  112.5, z = -92.5, label = "ห้องน้ำหญิง (FEMALE RESTROOM)", color = Color3.fromRGB(180, 40, 90),  nId = Enum.NormalId.Back },
        { name = "Restroom_BotLeft",  x = -112.5, z =  92.5, label = "ห้องน้ำหญิง (FEMALE RESTROOM)", color = Color3.fromRGB(180, 40, 90),  nId = Enum.NormalId.Front },
        { name = "Restroom_BotRight", x =  112.5, z =  92.5, label = "ห้องน้ำชาย (MALE RESTROOM)",   color = Color3.fromRGB(20, 90, 160),  nId = Enum.NormalId.Front },
    }

    for _, c in ipairs(cornerConfigs) do
        local rModel = Instance.new("Model")
        rModel.Name = c.name
        rModel.Parent = restrooms

        -- ผนังทึบ 4 ด้านปิดห้องน้ำ
        PartBuilder.makePart(rModel, "Wall_Outer_X", Vector3.new(wallThick, cornerH, cornerL), CFrame.new(c.x < 0 and -150 or 150, floorY + cornerH/2, c.z), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Outer_Z", Vector3.new(cornerW, cornerH, wallThick), CFrame.new(c.x, floorY + cornerH/2, c.z < 0 and -120 or 120), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Inner_X", Vector3.new(wallThick, cornerH, cornerL), CFrame.new(c.x < 0 and -75 or 75, floorY + cornerH/2, c.z), wallColor, wallMaterial)
        PartBuilder.makePart(rModel, "Wall_Inner_Z", Vector3.new(cornerW, cornerH, wallThick), CFrame.new(c.x, floorY + cornerH/2, c.z < 0 and -65 or 65), wallColor, wallMaterial)

        -- ป้ายบอกประเภทห้องน้ำ
        local signZ = (c.z < 0) and -65 + 0.3 or 65 - 0.3
        PartBuilder.makeSign(rModel, "Sign", c.label, Vector3.new(28, 3.5, 0.4), Vector3.new(c.x, floorY + 13, signZ), c.nId, c.color, Color3.fromRGB(255, 255, 255))
    end

    ------------------------------------------------------------------
    -- 8. ปีกซ้าย: แถวร้านข้าว (West Wing Canteen Food Stalls)
    --   - ก๋วยเตี๋ยวเรือ มจพ.
    --   - ข้าวมันไก่ตอน
    --   - ข้าวราดแกงปักษ์ใต้
    --   - ข้าวหมูกรอบหมูแดง
    ------------------------------------------------------------------
    local westStalls = Instance.new("Model")
    westStalls.Name = "WestWing_FoodStalls"
    westStalls.Parent = floor2

    -- ผนังรอบนอกทิศตะวันตก
    PartBuilder.makePart(westStalls, "OuterWall_West", Vector3.new(wallThick, wallH, 130), CFrame.new(-150, floorY + wallH/2, 0), wallColor, wallMaterial)

    local westStallData = {
        { name = "ร้านที่ 1: ก๋วยเตี๋ยวเรือ มจพ.",  z = -45, color = Color3.fromRGB(180, 45, 35) },
        { name = "ร้านที่ 2: ข้าวมันไก่ตอนสูตรเด็ด", z = -15, color = Color3.fromRGB(210, 140, 25) },
        { name = "ร้านที่ 3: ข้าวราดแกงปักษ์ใต้",   z =  15, color = Color3.fromRGB(40, 140, 60) },
        { name = "ร้านที่ 4: ข้าวหมูกรอบ-หมูแดง",  z =  45, color = Color3.fromRGB(190, 70, 30) },
    }

    for idx, stall in ipairs(westStallData) do
        local sM = Instance.new("Model")
        sM.Name = "Stall_W_" .. idx
        sM.Parent = westStalls

        -- ผนังแบ่งช่องร้าน
        PartBuilder.makePart(sM, "Divider", Vector3.new(65, wallH, wallThick), CFrame.new(-115, floorY + wallH/2, stall.z + 14), wallColor, wallMaterial)
        -- เคาน์เตอร์สั่งอาหารด้านหน้า
        PartBuilder.makePart(sM, "Counter", Vector3.new(4, 4.0, 24), CFrame.new(-82, floorY + 2.0, stall.z), Color3.fromRGB(220, 215, 205), Enum.Material.Concrete)
        PartBuilder.makePart(sM, "CounterTop", Vector3.new(4.8, 0.4, 25), CFrame.new(-82, floorY + 4.2, stall.z), Color3.fromRGB(60, 60, 65), Enum.Material.Granite)
        -- ตู้กระจกใสโชว์อาหาร
        PartBuilder.makePart(sM, "GlassCase", Vector3.new(3.0, 3.0, 18), CFrame.new(-82, floorY + 5.8, stall.z), Color3.fromRGB(220, 240, 255), Enum.Material.Glass, 0.6)
        -- ป้ายชื่อร้านอาหารเหนือเคาน์เตอร์
        PartBuilder.makeSign(sM, "Sign", stall.name, Vector3.new(0.5, 3.2, 24), Vector3.new(-79, floorY + 12, stall.z), Enum.NormalId.Right, stall.color, Color3.fromRGB(255, 255, 255))
    end

    ------------------------------------------------------------------
    -- 9. ปีกขวา: แถวร้านข้าว & ร้านน้ำ (East Wing Canteen Stalls)
    --   - ชานมไข่มุก & กาแฟโบราณ
    --   - น้ำผลไม้ปั่น & ผลไม้สด
    --   - ข้าวไข่เจียวทรงเครื่อง & สเต็ก
    --   - อาหารตามสั่ง & ส้มตำไก่ย่าง
    ------------------------------------------------------------------
    local eastStalls = Instance.new("Model")
    eastStalls.Name = "EastWing_FoodAndDrinkStalls"
    eastStalls.Parent = floor2

    -- ผนังรอบนอกทิศตะวันออก
    PartBuilder.makePart(eastStalls, "OuterWall_East", Vector3.new(wallThick, wallH, 130), CFrame.new(150, floorY + wallH/2, 0), wallColor, wallMaterial)

    local eastStallData = {
        { name = "ร้านที่ 5: ชานมไข่มุก & กาแฟโบราณ", z = -45, color = Color3.fromRGB(150, 75, 40) },
        { name = "ร้านที่ 6: ผลไม้สด & น้ำผลไม้ปั่น",   z = -15, color = Color3.fromRGB(230, 120, 30) },
        { name = "ร้านที่ 7: ข้าวไข่เจียว & สเต็กกระทะร้อน", z = 15, color = Color3.fromRGB(200, 160, 30) },
        { name = "ร้านที่ 8: อาหารตามสั่ง & ส้มตำไก่ย่าง", z = 45, color = Color3.fromRGB(200, 40, 50) },
    }

    for idx, stall in ipairs(eastStallData) do
        local sM = Instance.new("Model")
        sM.Name = "Stall_E_" .. idx
        sM.Parent = eastStalls

        -- ผนังแบ่งช่องร้าน
        PartBuilder.makePart(sM, "Divider", Vector3.new(65, wallH, wallThick), CFrame.new(115, floorY + wallH/2, stall.z + 14), wallColor, wallMaterial)
        -- เคาน์เตอร์สั่งอาหารด้านหน้า
        PartBuilder.makePart(sM, "Counter", Vector3.new(4, 4.0, 24), CFrame.new(82, floorY + 2.0, stall.z), Color3.fromRGB(220, 215, 205), Enum.Material.Concrete)
        PartBuilder.makePart(sM, "CounterTop", Vector3.new(4.8, 0.4, 25), CFrame.new(82, floorY + 4.2, stall.z), Color3.fromRGB(60, 60, 65), Enum.Material.Granite)
        -- ตู้กระจกใสโชว์อาหาร
        PartBuilder.makePart(sM, "GlassCase", Vector3.new(3.0, 3.0, 18), CFrame.new(82, floorY + 5.8, stall.z), Color3.fromRGB(220, 240, 255), Enum.Material.Glass, 0.6)
        -- ป้ายชื่อร้านอาหารเหนือเคาน์เตอร์
        PartBuilder.makeSign(sM, "Sign", stall.name, Vector3.new(0.5, 3.2, 24), Vector3.new(79, floorY + 12, stall.z), Enum.NormalId.Left, stall.color, Color3.fromRGB(255, 255, 255))
    end

    ------------------------------------------------------------------
    -- 10. กลางโรงอาหาร: ลานโต๊ะอาหารสแตนเลส มจพ. (Center Dining Hall)
    -- กว้างขวาง วิ่งหนีซอมบี้หรือกระโดดขึ้นโต๊ะยิงได้
    ------------------------------------------------------------------
    local diningArea = Instance.new("Model")
    diningArea.Name = "CenterDiningHall_Tables"
    diningArea.Parent = floor2

    -- เสาค้ำอาคารกลางโรงอาหาร (Architectural Columns with yellow safety base)
    local columnPositions = {
        Vector3.new(-38, floorY + wallH/2, -22),
        Vector3.new( 38, floorY + wallH/2, -22),
        Vector3.new(-38, floorY + wallH/2,  22),
        Vector3.new( 38, floorY + wallH/2,  22),
    }
    for idx, pos in ipairs(columnPositions) do
        PartBuilder.makePart(diningArea, "Column_" .. idx, Vector3.new(4, wallH, 4), CFrame.new(pos), Color3.fromRGB(235, 230, 222), Enum.Material.Concrete)
        PartBuilder.makePart(diningArea, "ColBase_" .. idx, Vector3.new(4.6, 2.5, 4.6), CFrame.new(pos.X, floorY + 1.25, pos.Z), Color3.fromRGB(240, 180, 20), Enum.Material.SmoothPlastic)
    end

    -- แถวโต๊ะอาหารสแตนเลส มจพ. (Classic Stainless Steel Canteen Tables with round attached stools)
    for row = -2, 2 do
        local tz = row * 16
        for col = -2, 2 do
            local tx = col * 26
            -- โต๊ะสแตนเลส (Table)
            local tableModel = Instance.new("Model")
            tableModel.Name = "CanteenTable_" .. row .. "_" .. col
            tableModel.Parent = diningArea

            PartBuilder.makePart(tableModel, "TableTop", Vector3.new(16, 0.4, 6.0), CFrame.new(tx, floorY + 3.4, tz), PartBuilder.COLORS.steel, Enum.Material.Metal)
            PartBuilder.makePart(tableModel, "TableLegL", Vector3.new(0.6, 3.2, 5.0), CFrame.new(tx - 6.5, floorY + 1.6, tz), Color3.fromRGB(80, 85, 90), Enum.Material.Metal)
            PartBuilder.makePart(tableModel, "TableLegR", Vector3.new(0.6, 3.2, 5.0), CFrame.new(tx + 6.5, floorY + 1.6, tz), Color3.fromRGB(80, 85, 90), Enum.Material.Metal)

            -- เก้าอี้กลมติดโต๊ะ (Fixed Round Stools 4 ตัวต่อโต๊ะ)
            for _, sx in ipairs({ -5, 5 }) do
                for _, sz in ipairs({ -4.2, 4.2 }) do
                    PartBuilder.makeCylinder(tableModel, "StoolSeat", Vector3.new(0.4, 2.2, 2.2), CFrame.new(tx + sx, floorY + 2.0, tz + sz) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 65, 70), Enum.Material.Metal)
                    PartBuilder.makePart(tableModel, "StoolLeg", Vector3.new(0.4, 2.0, 0.4), CFrame.new(tx + sx, floorY + 1.0, tz + sz), Color3.fromRGB(100, 105, 110), Enum.Material.Metal)
                end
            end
        end
    end

    ------------------------------------------------------------------
    -- 11. ระบบไฟส่องสว่างประจำชั้น 2 (Lighting Grid)
    ------------------------------------------------------------------
    local lights = Instance.new("Folder")
    lights.Name = "Lights_Floor2"
    lights.Parent = floor2

    local lightPoints = {
        Vector3.new(0, floorY + wallH - 2, 0),
        Vector3.new(-70, floorY + wallH - 2, 0),
        Vector3.new(70, floorY + wallH - 2, 0),
        Vector3.new(0, floorY + wallH - 2, topZ),
        Vector3.new(0, floorY + wallH - 2, botZ),
        Vector3.new(-70, floorY + wallH - 2, topZ),
        Vector3.new(70, floorY + wallH - 2, topZ),
        Vector3.new(-70, floorY + wallH - 2, botZ),
        Vector3.new(70, floorY + wallH - 2, botZ),
        Vector3.new(0, floorY + 12, stairZ), -- ไฟส่องสว่างชานพักบันไดใหญ่หน้าตึก
    }
    for idx, pos in ipairs(lightPoints) do
        PartBuilder.addPointLight(lights, "Light_F2_" .. idx, pos, Color3.fromRGB(255, 248, 235), 60, 1.8)
    end

    print("=========================================================")
    print("🍜 [Floor 2 - 2X Scale Built] โรงอาหาร 40 ปี สจพ. ขนาด 2 เท่า + บันไดใหญ่หน้าตึก + ป้าย Coke + ร้านข้าว 8 ร้าน + ห้องน้ำ 4 มุม สำเร็จสมบูรณ์!")
    print("=========================================================")
end

return Floor2_Canteen
