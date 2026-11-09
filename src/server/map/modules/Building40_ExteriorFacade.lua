--[[
    Building40_ExteriorFacade.lua
    สถาปัตยกรรมภายนอกทั้งตึก (12 ชั้น) และภูมิทัศน์หน้าตึก อาคารเอนกประสงค์ 40 ปี มจพ. (รหัสอาคาร 77)
    อ้างอิงตามลักษณะอาคารจริงและข้อมูลทางการของมหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ (kmutnb.ac.th):
      1. แนวเสาและครีบคอนกรีตภายนอก (Exterior Structural Pilasters & Sun-Shading Fins) ตามกริดเสา A-J และ 1-9 ตลอดความสูง 12 ชั้น
      2. คานขอบพื้นทุกชั้น (Horizontal Spandrel Beams) สลับแถบสีแดงหมากสุก มจพ. (Pradu Daeng Accent Bands)
      3. แผงหน้าต่างกระจกตัดแสงและบานเกล็ดอลูมิเนียมกันแดด (Exterior Window & Aluminum Louver Bays) รอบผนังทึบชั้นบน
      4. ดาดฟ้าและยอดตึก (Rooftop Parapet Crown, ห้องเครื่องลิฟต์ดาดฟ้า, และป้ายไฟชื่ออาคาร "อาคาร 40 ปี มจพ. (อาคาร 77)" ทั้ง 4 ทิศ)
      5. ลานสวนปาล์มหน้าอาคาร (Palm Garden Plaza) พร้อมต้นปาล์ม โคมไฟถนน และป้ายทำเนียบอาคาร 77 ครบทั้ง 12 ชั้นตามเว็บทางการ
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Building40_ExteriorFacade = {}

function Building40_ExteriorFacade.build(parent)
    local extModel = Instance.new("Model")
    extModel.Name = "Building40_ExteriorFacade_12Floors"
    extModel.Parent = parent

    local body = Layout.BODY -- halfX = 150, halfZ = 120
    local floorH = Layout.FLOOR_HEIGHT -- 22.0
    local topRoofY = Layout.floorY(12) + floorH -- 265.0

    local concreteLight = Color3.fromRGB(236, 233, 226)
    local concreteMid   = Color3.fromRGB(208, 205, 198)
    local praduRed      = Color3.fromRGB(138, 30, 42)  -- สีแดงหมากสุก มจพ.
    local frameDark     = Color3.fromRGB(45, 50, 58)
    local glassTint     = Color3.fromRGB(95, 135, 160)
    local louverSilver  = Color3.fromRGB(185, 192, 200)

    ------------------------------------------------------------------
    -- 1. เสาและครีบคอนกรีตภายนอกตลอดความสูงตึก (Vertical Structural Grid Fins)
    ------------------------------------------------------------------
    local finsFolder = Instance.new("Model")
    finsFolder.Name = "ExteriorVerticalGridFins"
    finsFolder.Parent = extModel

    local totalUpperH = topRoofY - Layout.floorY(2) -- 242.0 (ตั้งแต่พื้นชั้น 2 ถึงหลังคาชั้น 12)
    local midUpperY = (Layout.floorY(2) + topRoofY) / 2

    -- เสามุมตึกขนาดใหญ่ทั้ง 4 มุม (ตั้งแต่พื้นชั้น 1 ถึงขอบดาดฟ้า Y = 272)
    local fullCornerH = topRoofY + 7.0 - 1.0
    local fullCornerMidY = 1.0 + fullCornerH / 2
    for _, sx in ipairs({ -1, 1 }) do
        for _, sz in ipairs({ -1, 1 }) do
            PartBuilder.makePart(finsFolder, string.format("CornerMegaPillar_%d_%d", sx, sz),
                Vector3.new(3.2, fullCornerH, 3.2),
                CFrame.new(sx * (body.halfX + 0.4), fullCornerMidY, sz * (body.halfZ + 0.4)),
                concreteMid, Enum.Material.Concrete)
            PartBuilder.makePart(finsFolder, string.format("CornerRedStripe_%d_%d", sx, sz),
                Vector3.new(1.4, fullCornerH, 1.4),
                CFrame.new(sx * (body.halfX + 1.4), fullCornerMidY, sz * (body.halfZ + 1.4)),
                praduRed, Enum.Material.SmoothPlastic)
        end
    end

    -- ครีบเสาแนวตั้งด้านหน้าตึก (Z = +120.5) และหลังตึก (Z = -120.5) ตามแนวกริด A-J
    local gridXs = { -116, -98, -68, -30, 30, 68, 98, 116 }
    for _, gx in ipairs(gridXs) do
        for _, sz in ipairs({ -1, 1 }) do
            PartBuilder.makePart(finsFolder, string.format("Pilaster_NS_%d_%d", gx, sz),
                Vector3.new(1.8, totalUpperH, 1.2),
                CFrame.new(gx, midUpperY, sz * (body.halfZ + 0.5)),
                concreteMid, Enum.Material.Concrete)
        end
    end

    -- ครีบเสาแนวตั้งด้านซ้าย (X = -150.5) และขวา (X = +150.5) ตามแนวกริด 1-9
    local gridZs = { -86, -60, -20, 20, 60, 86 }
    for _, gz in ipairs(gridZs) do
        for _, sx in ipairs({ -1, 1 }) do
            PartBuilder.makePart(finsFolder, string.format("Pilaster_WE_%d_%d", gz, sx),
                Vector3.new(1.2, totalUpperH, 1.8),
                CFrame.new(sx * (body.halfX + 0.5), midUpperY, gz),
                concreteMid, Enum.Material.Concrete)
        end
    end

    ------------------------------------------------------------------
    -- 2. คานขอบพื้นรอบตึกทั้ง 12 ชั้น + แถบสีแดงหมากสุก มจพ. (Horizontal Spandrel Bands)
    ------------------------------------------------------------------
    local bandsFolder = Instance.new("Model")
    bandsFolder.Name = "ExteriorFloorSpandrelBands"
    bandsFolder.Parent = extModel

    for f = 2, 13 do
        local bandY = Layout.floorY(f)
        local isAccentFloor = (f == 2 or f == 3 or f == 7 or f == 12 or f == 13)
        local trimCol = isAccentFloor and praduRed or concreteMid

        -- ด้านซ้ายสุดและขวาสุด (ยาวเต็ม 240 studs)
        for _, sx in ipairs({ -1, 1 }) do
            PartBuilder.makePart(bandsFolder, string.format("Spandrel_WE_F%d_%d", f, sx),
                Vector3.new(1.0, 2.4, body.halfZ * 2 + 1.6),
                CFrame.new(sx * (body.halfX + 0.4), bandY - 0.2, 0),
                concreteLight, Enum.Material.Concrete)
            PartBuilder.makePart(bandsFolder, string.format("TrimBand_WE_F%d_%d", f, sx),
                Vector3.new(1.25, 0.75, body.halfZ * 2 + 1.8),
                CFrame.new(sx * (body.halfX + 0.5), bandY - 0.9, 0),
                trimCol, Enum.Material.SmoothPlastic)
        end

        -- ด้านหลังตึก (ทิศเหนือ Z = -120.4 ยาวเต็ม 300 studs)
        PartBuilder.makePart(bandsFolder, string.format("Spandrel_North_F%d", f),
            Vector3.new(body.halfX * 2 + 1.6, 2.4, 1.0),
            CFrame.new(0, bandY - 0.2, -(body.halfZ + 0.4)),
            concreteLight, Enum.Material.Concrete)
        PartBuilder.makePart(bandsFolder, string.format("TrimBand_North_F%d", f),
            Vector3.new(body.halfX * 2 + 1.8, 0.75, 1.25),
            CFrame.new(0, bandY - 0.9, -(body.halfZ + 0.5)),
            trimCol, Enum.Material.SmoothPlastic)

        -- ด้านหน้าตึก (ทิศใต้ Z = +120.4): ชั้น 2 เว้นช่วงสะพานหน้าโรงอาหาร (X = -28..+28)
        if f == 2 then
            for _, sx in ipairs({ -1, 1 }) do
                PartBuilder.makePart(bandsFolder, "Spandrel_South_F2_" .. sx,
                    Vector3.new(122, 2.4, 1.0),
                    CFrame.new(sx * 89, bandY - 0.2, body.halfZ + 0.4),
                    concreteLight, Enum.Material.Concrete)
                PartBuilder.makePart(bandsFolder, "TrimBand_South_F2_" .. sx,
                    Vector3.new(122, 0.75, 1.25),
                    CFrame.new(sx * 89, bandY - 0.9, body.halfZ + 0.5),
                    trimCol, Enum.Material.SmoothPlastic)
            end
        else
            PartBuilder.makePart(bandsFolder, string.format("Spandrel_South_F%d", f),
                Vector3.new(body.halfX * 2 + 1.6, 2.4, 1.0),
                CFrame.new(0, bandY - 0.2, body.halfZ + 0.4),
                concreteLight, Enum.Material.Concrete)
            PartBuilder.makePart(bandsFolder, string.format("TrimBand_South_F%d", f),
                Vector3.new(body.halfX * 2 + 1.8, 0.75, 1.25),
                CFrame.new(0, bandY - 0.9, body.halfZ + 0.5),
                trimCol, Enum.Material.SmoothPlastic)
        end
    end

    ------------------------------------------------------------------
    -- 3. แผงหน้าต่างกระจกและบานเกล็ดอลูมิเนียมภายนอก (Exterior Architectural Windows & Louvers)
    --    ติดเฉพาะชั้นห้องเรียน/กิจการนักศึกษา/หอพัก (ชั้น 4-6 และ ชั้น 8-11) เพื่อให้ภายนอกดูสมจริงเหมือนตึก 12 ชั้นของจริง
    ------------------------------------------------------------------
    local winFolder = Instance.new("Model")
    winFolder.Name = "ExteriorWindowAndLouverBays"
    winFolder.Parent = extModel

    local activeWindowFloors = { 4, 5, 6, 8, 9, 10, 11 }
    for _, f in ipairs(activeWindowFloors) do
        local fy = Layout.floorY(f)
        -- หน้าต่างด้านข้างซ้าย-ขวา (X = ±150.15) ช่วงห้องปีกซ้ายและปีกขวา (Z = -70, -36, 0, 36, 70)
        for _, sx in ipairs({ -1, 1 }) do
            local wx = sx * (body.halfX + 0.15)
            for _, wz in ipairs({ -66, -34, 0, 34, 66 }) do
                PartBuilder.makePart(winFolder, string.format("SideWinFrame_F%d_%d_%d", f, sx, wz),
                    Vector3.new(0.25, 9.6, 18.0), CFrame.new(wx, fy + 11.5, wz), frameDark, Enum.Material.Metal)
                PartBuilder.makePart(winFolder, string.format("SideWinGlass_F%d_%d_%d", f, sx, wz),
                    Vector3.new(0.3, 8.8, 17.0), CFrame.new(wx, fy + 11.5, wz), glassTint, Enum.Material.Glass, { Reflectance = 0.25 })
                PartBuilder.makePart(winFolder, string.format("SideSunFin_F%d_%d_%d", f, sx, wz),
                    Vector3.new(1.4, 0.45, 18.6), CFrame.new(wx + sx * 0.6, fy + 16.5, wz), louverSilver, Enum.Material.Metal)
            end
        end

        -- หน้าต่างและบานเกล็ดด้านหน้า-หลังตึก (Z = ±120.15) ช่วงห้องปิดและห้องน้ำมุมตึก
        for _, sz in ipairs({ -1, 1 }) do
            local wz = sz * (body.halfZ + 0.15)
            for _, wx in ipairs({ -133, -83, 83, 133 }) do
                PartBuilder.makePart(winFolder, string.format("NSWinFrame_F%d_%d_%d", f, sz, wx),
                    Vector3.new(18.0, 8.4, 0.25), CFrame.new(wx, fy + 12.0, wz), frameDark, Enum.Material.Metal)
                PartBuilder.makePart(winFolder, string.format("NSWinGlass_F%d_%d_%d", f, sz, wx),
                    Vector3.new(17.0, 7.6, 0.3), CFrame.new(wx, fy + 12.0, wz), glassTint, Enum.Material.Glass, { Reflectance = 0.25 })
                PartBuilder.makePart(winFolder, string.format("NSSunFin_F%d_%d_%d", f, sz, wx),
                    Vector3.new(18.6, 0.45, 1.4), CFrame.new(wx, fy + 16.4, wz + sz * 0.6), louverSilver, Enum.Material.Metal)
            end
        end
    end

    ------------------------------------------------------------------
    -- 4. ดาดฟ้า, กำแพงขอบดาดฟ้า (Parapet Crown), ห้องเครื่องลิฟต์ และป้ายชื่ออาคารบนยอดตึก 4 ทิศ
    ------------------------------------------------------------------
    local crownFolder = Instance.new("Model")
    crownFolder.Name = "RooftopCrownAndSigns"
    crownFolder.Parent = extModel

    local parapetH = 6.5
    local parapetY = topRoofY + 2.5 + parapetH / 2
    -- กำแพงขอบดาดฟ้า 4 ด้าน
    for _, sz in ipairs({ -1, 1 }) do
        PartBuilder.makePart(crownFolder, "Parapet_NS_" .. sz, Vector3.new(body.halfX * 2 + 2, parapetH, 2.2),
            CFrame.new(0, parapetY, sz * (body.halfZ - 0.5)), concreteLight, Enum.Material.Concrete)
        PartBuilder.makePart(crownFolder, "ParapetCoping_NS_" .. sz, Vector3.new(body.halfX * 2 + 2.6, 1.2, 2.6),
            CFrame.new(0, parapetY + parapetH / 2 + 0.4, sz * (body.halfZ - 0.5)), praduRed, Enum.Material.SmoothPlastic)
    end
    for _, sx in ipairs({ -1, 1 }) do
        PartBuilder.makePart(crownFolder, "Parapet_WE_" .. sx, Vector3.new(2.2, parapetH, body.halfZ * 2 + 2),
            CFrame.new(sx * (body.halfX - 0.5), parapetY, 0), concreteLight, Enum.Material.Concrete)
        PartBuilder.makePart(crownFolder, "ParapetCoping_WE_" .. sx, Vector3.new(2.6, 1.2, body.halfZ * 2 + 2.6),
            CFrame.new(sx * (body.halfX - 0.5), parapetY + parapetH / 2 + 0.4, 0), praduRed, Enum.Material.SmoothPlastic)
    end

    -- ห้องเครื่องลิฟต์และถังพักน้ำบนดาดฟ้าเหนือคอร์ทิศเหนือและทิศใต้
    for _, sz in ipairs({ -1, 1 }) do
        PartBuilder.makePart(crownFolder, "ElevatorPenthouse_" .. sz, Vector3.new(136, 14.0, 32),
            CFrame.new(0, topRoofY + 2.5 + 7.0, sz * 103), concreteLight, Enum.Material.Concrete)
        PartBuilder.makePart(crownFolder, "PenthouseRoof_" .. sz, Vector3.new(138, 1.5, 34),
            CFrame.new(0, topRoofY + 2.5 + 14.75, sz * 103), praduRed, Enum.Material.SmoothPlastic)
    end

    -- ป้ายชื่ออาคารขนาดใหญ่บนยอดตึกทั้ง 4 ทิศ (มองเห็นชัดเจนจากระยะไกลรอบมหาวิทยาลัย)
    local roofSignTitle = "อาคารเอนกประสงค์ 40 ปี มจพ. (อาคาร 77)\nKMUTNB 40th ANNIVERSARY BUILDING"
    PartBuilder.makeSign(crownFolder, "CrownSign_SouthFront", roofSignTitle,
        Vector3.new(110, 9.5, 0.8), Vector3.new(0, topRoofY + 11.5, body.halfZ + 0.8),
        Enum.NormalId.Back, praduRed, Color3.fromRGB(255, 255, 255))
    PartBuilder.makeSign(crownFolder, "CrownSign_NorthRear", roofSignTitle,
        Vector3.new(110, 9.5, 0.8), Vector3.new(0, topRoofY + 11.5, -(body.halfZ + 0.8)),
        Enum.NormalId.Front, praduRed, Color3.fromRGB(255, 255, 255))
    PartBuilder.makeSign(crownFolder, "CrownSign_West", roofSignTitle,
        Vector3.new(0.8, 9.5, 96), Vector3.new(-(body.halfX + 0.8), topRoofY + 6.5, 0),
        Enum.NormalId.Left, praduRed, Color3.fromRGB(255, 255, 255))
    PartBuilder.makeSign(crownFolder, "CrownSign_East", roofSignTitle,
        Vector3.new(0.8, 9.5, 96), Vector3.new(body.halfX + 0.8, topRoofY + 6.5, 0),
        Enum.NormalId.Right, praduRed, Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 5. ป้ายทำเนียบอาคาร 77 (อาคารกิจกรรม 40 ปี มจพ.) หน้าตึก (ไม่วางต้นปาล์มบังหน้าห้องธนาคารชั้น 1)
    ------------------------------------------------------------------
    local palmPlaza = Instance.new("Model")
    palmPlaza.Name = "FrontDirectoryMonument_Building77"
    palmPlaza.Parent = extModel

    local monumentX = -38
    local monumentZ = 136
    PartBuilder.makePart(palmPlaza, "DirectoryPedestal", Vector3.new(16, 2.2, 2.4),
        CFrame.new(monumentX, 2.1, monumentZ), Color3.fromRGB(48, 52, 58), Enum.Material.Granite)
    PartBuilder.makeSign(palmPlaza, "OfficialBuilding77Directory",
        "อาคาร 77 : อาคารเอนกประสงค์ 40 ปี มจพ.\n"
        .. "[ชั้น 12] สนามกีฬาชั้นบนสุด: เวทีมวย / เทควันโด & กระสอบทราย / เทนนิส / ฟุตซอล (ขึ้นบันไดเท่านั้น)\n"
        .. "[ชั้น 11] หอพัก KMUTNB Residence & โถงมองสนามกีฬา\n"
        .. "[ชั้น 8-10] ห้องชมรมนักศึกษา / กิจกรรมนักศึกษา & โถงมองสนามกีฬา\n"
        .. "[ชั้น 7] สนามวอลเลย์บอล & สนามแบดมินตัน 4 คอร์ท\n"
        .. "[ชั้น 4-6] กองกิจการนักศึกษา (ชั้น 5 กิจกรรม นศ./กยศ./แนะแนว/วินัย)\n"
        .. "[ชั้น 3] สนามฟุตซอล (กรงตาข่าย) & สนามบาสเกตบอล & ปิงปอง\n"
        .. "[ชั้น 2] โรงอาหาร 40 ปี มจพ.  |  [ชั้น 1] ธนาคารกรุงเทพ & คาเฟ่ & ศูนย์บริการ นศ.",
        Vector3.new(15.4, 8.5, 1.0), Vector3.new(monumentX, 7.4, monumentZ),
        Enum.NormalId.Back, praduRed, Color3.fromRGB(255, 255, 255))

    print("🏛️ [Exterior Built] สร้างสถาปัตยกรรมภายนอกทั้ง 12 ชั้น + ป้ายทำเนียบทางการ อาคาร 40 ปี มจพ. (อาคาร 77) สำเร็จ!")
end

return Building40_ExteriorFacade
