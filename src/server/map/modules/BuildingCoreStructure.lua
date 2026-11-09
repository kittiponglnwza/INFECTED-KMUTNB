--[[
    BuildingCoreStructure.lua
    โมดูลสร้างโครงสร้างสถาปัตยกรรมหลักของอาคาร 40 ปี มจพ. (อาคาร 77) ทั้ง 12 ชั้น + ดาดฟ้า
    - เสาโครงสร้างหลัก 16 ต้น (Grid 4x4) ทะลุจากชั้น 1 ถึงชั้น 12
    - แผ่นพื้นคอนกรีตทุกชั้น (Floors 2 - 12) แบบโปร่ง เว้นช่องลิฟต์และบันได (ไม่มีก้อนตันมาขวาง)
    - ปล่องลิฟต์โดยสารแกนกลาง (Central Elevator Core)
    - ปล่องบันไดหนีไฟ (Emergency Fire Stairwell)
    - ผนัง Facade ภายนอก แถบกระจก Ribbon Windows และเส้นคาดสีแสด-แดงเลือดหมู มจพ.
    - ดาดฟ้า (Rooftop Deck), ลานจอดเฮลิคอปเตอร์ (Helipad ตัว H), ชิลเลอร์แอร์ และเสาสัญญาณวิทยุ
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local BuildingCoreStructure = {}

function BuildingCoreStructure.build(building)
    local coreModel = Instance.new("Model")
    coreModel.Name = "BuildingCoreStructure_12Floors"
    coreModel.Parent = building

    local bW = PartBuilder.WIDTH          -- 135 studs
    local bL = PartBuilder.LENGTH         -- 120 studs
    local fH = PartBuilder.FLOOR_HEIGHT   -- 16 studs per floor
    local totalFloors = PartBuilder.FLOOR_COUNT -- 12 floors
    local groundY = PartBuilder.FLOOR1_Y  -- 4 studs
    local totalHeight = totalFloors * fH  -- 192 studs
    local roofY = groundY + totalHeight   -- 196 studs

    ------------------------------------------------------------------
    -- 1. เสาโครงสร้างคอนกรีตเสริมเหล็กหลัก 16 ต้น (4x4 Structural Columns Grid)
    ------------------------------------------------------------------
    local columnsFolder = Instance.new("Folder")
    columnsFolder.Name = "StructuralColumns"
    columnsFolder.Parent = coreModel

    local colXPoints = { -bW/2 + 8, -bW/6, bW/6, bW/2 - 8 }
    local colZPoints = { -bL/2 + 8, -bL/6, bL/6, bL/2 - 8 }

    for colIndexX, x in ipairs(colXPoints) do
        for colIndexZ, z in ipairs(colZPoints) do
            PartBuilder.makePart(
                columnsFolder,
                string.format("Pillar_Col_%d_%d", colIndexX, colIndexZ),
                Vector3.new(3.5, totalHeight, 3.5),
                CFrame.new(x, groundY + totalHeight/2, z),
                PartBuilder.COLORS.warmGrey,
                Enum.Material.Concrete
            )
        end
    end

    ------------------------------------------------------------------
    -- 2. แผ่นพื้นคอนกรีตทุกชั้น (Floors 3 ถึง 12 Floor Slabs)
    -- ชั้น 1 สร้างโดย Floor1_Lobby, ชั้น 2 สร้างโดย Floor2_Canteen
    -- เว้นช่องว่างตรงกลางสำหรับโถงบันไดและช่องลิฟต์ เพื่อไม่ให้เกิดกล่องตัน
    ------------------------------------------------------------------
    local floorsFolder = Instance.new("Folder")
    floorsFolder.Name = "FloorSlabs"
    floorsFolder.Parent = coreModel

    for fl = 3, totalFloors do
        local flY = PartBuilder.floorY(fl)
        local flModel = Instance.new("Model")
        flModel.Name = "FloorSlab_F" .. fl
        flModel.Parent = floorsFolder

        -- ปีกซ้าย (Left Wing Slab)
        PartBuilder.makePart(
            flModel,
            "Slab_Left",
            Vector3.new(bW/2 - 12, 1.4, bL - 6),
            CFrame.new(-bW/4 - 3, flY, 0),
            PartBuilder.COLORS.tileLight,
            Enum.Material.Concrete
        )

        -- ปีกขวา (Right Wing Slab)
        PartBuilder.makePart(
            flModel,
            "Slab_Right",
            Vector3.new(bW/2 - 12, 1.4, bL - 6),
            CFrame.new(bW/4 + 3, flY, 0),
            PartBuilder.COLORS.tileLight,
            Enum.Material.Concrete
        )

        -- สะพานเชื่อมหน้า-หลังแกนกลาง (Center Walkway Bridge)
        PartBuilder.makePart(
            flModel,
            "Bridge_Front",
            Vector3.new(18, 1.4, 28),
            CFrame.new(0, flY, bL/4 + 8),
            PartBuilder.COLORS.tileLight,
            Enum.Material.Concrete
        )
        PartBuilder.makePart(
            flModel,
            "Bridge_Back",
            Vector3.new(18, 1.4, 28),
            CFrame.new(0, flY, -bL/4 - 8),
            PartBuilder.COLORS.tileLight,
            Enum.Material.Concrete
        )

        -- ป้ายบอกเลขชั้นที่โถงลิฟต์
        PartBuilder.makeSign(
            flModel,
            "FloorIndicatorSign",
            "ชั้น " .. fl .. " // FLOOR " .. fl,
            Vector3.new(14, 2.4, 0.4),
            Vector3.new(0, flY + 8, -bL/2 + 23),
            Enum.NormalId.Back,
            PartBuilder.COLORS.maroon
        )
    end

    ------------------------------------------------------------------
    -- 3. ปล่องแกนกลาง: โถงลิฟต์ 4 ตัว & บันไดหนีไฟ (Shaft Enclosures)
    ------------------------------------------------------------------
    local coreShafts = Instance.new("Folder")
    coreShafts.Name = "CoreVerticalShafts"
    coreShafts.Parent = coreModel

    -- ผนังปล่องลิฟต์ด้านหลัง
    PartBuilder.makePart(
        coreShafts,
        "ElevatorBackWall",
        Vector3.new(46, totalHeight, 1.8),
        CFrame.new(0, groundY + totalHeight/2, -bL/2 + 18),
        PartBuilder.COLORS.warmGrey,
        Enum.Material.Concrete
    )

    -- ผนังแบ่งช่องลิฟต์ซ้าย-ขวา
    for _, xPos in ipairs({ -23, 23 }) do
        PartBuilder.makePart(
            coreShafts,
            "ElevatorSideWall",
            Vector3.new(1.8, totalHeight, 8),
            CFrame.new(xPos, groundY + totalHeight/2, -bL/2 + 22),
            PartBuilder.COLORS.warmGrey,
            Enum.Material.Concrete
        )
    end

    -- ประตูลิฟต์จำลองประจำทุกชั้น (Floors 3 ถึง 12)
    for fl = 3, totalFloors do
        local flY = PartBuilder.floorY(fl)
        for el = 1, 4 do
            local elX = -17.5 + ((el - 1) * 11.5)
            PartBuilder.makePart(
                coreShafts,
                string.format("ElevatorDoor_F%d_%d", fl, el),
                Vector3.new(6.8, 10.5, 0.4),
                CFrame.new(elX, flY + 5.25, -bL/2 + 24),
                PartBuilder.COLORS.steel,
                Enum.Material.Metal
            )
            PartBuilder.makePart(
                coreShafts,
                string.format("Ind_F%d_%d", fl, el),
                Vector3.new(2.4, 1.0, 0.2),
                CFrame.new(elX, flY + 11.8, -bL/2 + 24.2),
                Color3.fromRGB(255, 140, 0),
                Enum.Material.Neon
            )
        end
    end

    -- ปล่องบันไดหนีไฟด้านหลังขวา (Emergency Fire Stairwell Enclosure)
    PartBuilder.makePart(
        coreShafts,
        "FireStairWall_R",
        Vector3.new(1.6, totalHeight, 24),
        CFrame.new(bW/2 - 2, groundY + totalHeight/2, -bL/2 + 16),
        PartBuilder.COLORS.warmGrey,
        Enum.Material.Concrete
    )
    PartBuilder.makePart(
        coreShafts,
        "FireStairWall_Inner",
        Vector3.new(1.6, totalHeight, 24),
        CFrame.new(bW/2 - 18, groundY + totalHeight/2, -bL/2 + 16),
        PartBuilder.COLORS.warmGrey,
        Enum.Material.Concrete
    )

    -- ประตูหนีไฟเหล็กสีแดงพร้อมป้าย Exit ทุกชั้น (Floors 3 ถึง 12)
    for fl = 3, totalFloors do
        local flY = PartBuilder.floorY(fl)
        PartBuilder.makePart(
            coreShafts,
            "FireDoor_F" .. fl,
            Vector3.new(4.5, 9, 0.6),
            CFrame.new(bW/2 - 18, flY + 4.5, -bL/2 + 20),
            PartBuilder.COLORS.maroon,
            Enum.Material.Metal
        )
        PartBuilder.makeSign(
            coreShafts,
            "ExitSign_F" .. fl,
            "EXIT\nทางหนีไฟ",
            Vector3.new(3.2, 1.2, 0.2),
            Vector3.new(bW/2 - 18.4, flY + 10, -bL/2 + 20),
            Enum.NormalId.Left,
            Color3.fromRGB(20, 160, 60)
        )
    end

    ------------------------------------------------------------------
    -- 4. เปลือกอาคารภายนอกทั้ง 12 ชั้น (Exterior Facade & Curtain Windows)
    ------------------------------------------------------------------
    local facadeFolder = Instance.new("Folder")
    facadeFolder.Name = "ExteriorFacade"
    facadeFolder.Parent = coreModel

    -- เสามุมอาคาร 4 มุม ขนาดใหญ่ (Major Corner Pylons)
    local cornerOffset = 2
    local corners = {
        Vector3.new(-bW/2 - cornerOffset, groundY + totalHeight/2, -bL/2 - cornerOffset),
        Vector3.new(bW/2 + cornerOffset,  groundY + totalHeight/2, -bL/2 - cornerOffset),
        Vector3.new(-bW/2 - cornerOffset, groundY + totalHeight/2, bL/2 + cornerOffset),
        Vector3.new(bW/2 + cornerOffset,  groundY + totalHeight/2, bL/2 + cornerOffset),
    }
    for i, cPos in ipairs(corners) do
        PartBuilder.makePart(
            facadeFolder,
            "CornerPylon_" .. i,
            Vector3.new(5.5, totalHeight + 6, 5.5),
            CFrame.new(cPos),
            PartBuilder.COLORS.cream,
            Enum.Material.Concrete
        )
    end

    -- แผงหน้าต่างและแถบสีแสด-แดงเลือดหมู มจพ. ประจำชั้น 2 ถึง 12
    for fl = 2, totalFloors do
        local flY = PartBuilder.floorY(fl)
        local winCenterY = flY + fH/2

        -- หน้าต่างด้านหน้า (Front Windows)
        PartBuilder.makePart(
            facadeFolder,
            string.format("Win_Front_F%d", fl),
            Vector3.new(bW - 20, 7.5, 0.8),
            CFrame.new(0, winCenterY, bL/2),
            PartBuilder.COLORS.glass,
            Enum.Material.Glass,
            { Transparency = 0.50 }
        )

        -- หน้าต่างด้านหลัง (Rear Windows)
        PartBuilder.makePart(
            facadeFolder,
            string.format("Win_Rear_F%d", fl),
            Vector3.new(bW - 40, 7.5, 0.8),
            CFrame.new(10, winCenterY, -bL/2),
            PartBuilder.COLORS.glass,
            Enum.Material.Glass,
            { Transparency = 0.50 }
        )

        -- หน้าต่างด้านข้างซ้าย-ขวา (Side Windows)
        PartBuilder.makePart(
            facadeFolder,
            string.format("Win_Left_F%d", fl),
            Vector3.new(0.8, 7.5, bL - 20),
            CFrame.new(-bW/2, winCenterY, 0),
            PartBuilder.COLORS.glass,
            Enum.Material.Glass,
            { Transparency = 0.50 }
        )
        PartBuilder.makePart(
            facadeFolder,
            string.format("Win_Right_F%d", fl),
            Vector3.new(0.8, 7.5, bL - 20),
            CFrame.new(bW/2, winCenterY, 0),
            PartBuilder.COLORS.glass,
            Enum.Material.Glass,
            { Transparency = 0.50 }
        )

        -- แถบคานปูนกันแดด (Spandrel Beam)
        PartBuilder.makePart(
            facadeFolder,
            string.format("Spandrel_Front_F%d", fl),
            Vector3.new(bW - 14, 4.0, 1.8),
            CFrame.new(0, flY + 2.0, bL/2 + 0.4),
            PartBuilder.COLORS.creamLight,
            Enum.Material.Concrete
        )

        -- เส้นคาดสีเอกลักษณ์ มจพ.: สีแสด (KMUTNB Orange) & สีแดงเลือดหมู (Maroon)
        local stripeColor = (fl % 2 == 0) and PartBuilder.COLORS.orange or PartBuilder.COLORS.maroon
        PartBuilder.makePart(
            facadeFolder,
            string.format("KMUTNB_Stripe_F%d", fl),
            Vector3.new(bW - 10, 1.4, 2.2),
            CFrame.new(0, flY + 4.2, bL/2 + 0.6),
            stripeColor,
            Enum.Material.SmoothPlastic
        )
    end

    ------------------------------------------------------------------
    -- 5. ดาดฟ้าชั้นสูงสุด & ลานจอดเฮลิคอปเตอร์ (Rooftop Deck & Helipad)
    ------------------------------------------------------------------
    local roofFolder = Instance.new("Folder")
    roofFolder.Name = "Rooftop"
    roofFolder.Parent = coreModel

    -- พื้นดาดฟ้าใหญ่
    PartBuilder.makePart(
        roofFolder,
        "RoofDeck",
        Vector3.new(bW + 8, 3.0, bL + 8),
        CFrame.new(0, roofY + 1.5, 0),
        PartBuilder.COLORS.warmGrey,
        Enum.Material.Concrete
    )

    -- กำแพงกั้นตกขอบดาดฟ้า (Parapet Safety Wall)
    PartBuilder.makePart(roofFolder, "Parapet_Front", Vector3.new(bW + 8, 4.5, 1.8), CFrame.new(0, roofY + 4.5, bL/2 + 3.5), PartBuilder.COLORS.cream, Enum.Material.Concrete)
    PartBuilder.makePart(roofFolder, "Parapet_Rear",  Vector3.new(bW + 8, 4.5, 1.8), CFrame.new(0, roofY + 4.5, -bL/2 - 3.5), PartBuilder.COLORS.cream, Enum.Material.Concrete)
    PartBuilder.makePart(roofFolder, "Parapet_Left",  Vector3.new(1.8, 4.5, bL + 8), CFrame.new(-bW/2 - 3.5, roofY + 4.5, 0), PartBuilder.COLORS.cream, Enum.Material.Concrete)
    PartBuilder.makePart(roofFolder, "Parapet_Right", Vector3.new(1.8, 4.5, bL + 8), CFrame.new(bW/2 + 3.5, roofY + 4.5, 0), PartBuilder.COLORS.cream, Enum.Material.Concrete)

    -- ลานจอดเฮลิคอปเตอร์วงกลม (Helipad)
    local heliPlatform = PartBuilder.makeCylinder(
        roofFolder,
        "HeliPadPlatform",
        Vector3.new(0.6, 42, 42),
        CFrame.new(0, roofY + 3.3, 10) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(45, 48, 52),
        Enum.Material.Concrete
    )

    -- วงแหวนสีเหลืองรอบลานจอด
    PartBuilder.makeCylinder(
        roofFolder,
        "HeliRing",
        Vector3.new(0.7, 36, 36),
        CFrame.new(0, roofY + 3.4, 10) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(240, 190, 40),
        Enum.Material.SmoothPlastic
    )

    -- ตัวอักษร "H" ขนาดใหญ่บนดาดฟ้า
    PartBuilder.makePart(roofFolder, "H_Bar1", Vector3.new(3.5, 0.8, 20), CFrame.new(-6, roofY + 3.6, 10), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(roofFolder, "H_Bar2", Vector3.new(3.5, 0.8, 20), CFrame.new(6, roofY + 3.6, 10), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(roofFolder, "H_Cross", Vector3.new(12, 0.8, 3.5), CFrame.new(0, roofY + 3.6, 10), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)

    -- ห้องเครื่องชิลเลอร์แอร์และแท็งก์น้ำ (HVAC Chiller & Elevator Machine Room)
    local mechRoom = PartBuilder.makePart(
        roofFolder,
        "ElevatorMachineRoom",
        Vector3.new(36, 12, 28),
        CFrame.new(0, roofY + 9, -bL/2 + 20),
        PartBuilder.COLORS.cream,
        Enum.Material.Concrete
    )

    -- แท็งก์น้ำระบายความร้อน 2 แท็งก์
    for t = 1, 2 do
        local tX = -10 + (t * 10)
        PartBuilder.makeCylinder(
            roofFolder,
            "CoolingTower_" .. t,
            Vector3.new(10, 8, 8),
            CFrame.new(tX, roofY + 8, -bL/2 + 42) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(160, 165, 170),
            Enum.Material.Metal
        )
    end

    -- เสาสัญญาณวิทยุสื่อสาร มจพ. พร้อมไฟเตือนการบินสีแดงกระพริบ (Radio Mast & Beacon)
    local mastBase = PartBuilder.makePart(
        roofFolder,
        "RadioMastBase",
        Vector3.new(4, 2, 4),
        CFrame.new(-25, roofY + 4, -20),
        PartBuilder.COLORS.darkGrey,
        Enum.Material.Metal
    )
    local mast = PartBuilder.makeCylinder(
        roofFolder,
        "RadioMast",
        Vector3.new(36, 1.2, 1.2),
        CFrame.new(-25, roofY + 22, -20) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(210, 50, 50),
        Enum.Material.Metal
    )
    local beacon = PartBuilder.makePart(
        roofFolder,
        "AviationBeacon",
        Vector3.new(1.8, 1.8, 1.8),
        CFrame.new(-25, roofY + 41, -20),
        Color3.fromRGB(255, 30, 40),
        Enum.Material.Neon
    )
    local beaconLight = Instance.new("PointLight")
    beaconLight.Color = Color3.fromRGB(255, 30, 40)
    beaconLight.Range = 60
    beaconLight.Brightness = 3
    beaconLight.Parent = beacon

    print(string.format("🏛️ [BuildingCoreStructure] สร้างโครงสร้างอาคาร 40 ปี ครบ %d ชั้น + ดาดฟ้า Helipad สำเร็จ (ความสูงรวม %.1f studs)", totalFloors, totalHeight))
end

return BuildingCoreStructure
