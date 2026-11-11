--[[
    Building40_ExteriorFacade.lua
    สถาปัตยกรรมภายนอกทั้งตึก (12 ชั้น) อาคารเอนกประสงค์ 40 ปี มจพ. (รหัสอาคาร 77)
    จำลองครบทั้ง 4 ด้านตามลักษณะอาคารจริงของมหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ (KMUTNB):
      1. แนวเสาและครีบคอนกรีตภายนอก (Exterior Structural Pilasters & Sun-Shading Fins) ตามแนวเสากริด 4 ทิศ
      2. แถบคาดสีส้มอิฐ/น้ำตาลอมส้ม และแดงประดู่ มจพ. (Horizontal Terracotta Bands) รอบตึกทุกชั้น
      3. แผงหน้าต่างกระจกสะท้อนฟ้า บานเกล็ดระบายอากาศ และครีบกันแดดตลอดความสูง 12 ชั้น
      4. ด้านหน้า (ทิศใต้): บันไดใหญ่ขึ้นชั้น 2, โถงกระจกทางเข้าชั้น 1, ป้ายธนาคารกรุงเทพ, ป้ายศูนย์บริการ นศ.
      5. ด้านหลัง (ทิศเหนือ): หันสู่คลองบางเขนใหม่, ช่องลานจอดรถขับทะลุ, ทางออกเซอร์วิสและบันไดหนีไฟ
      6. ด้านข้างซ้าย-ขวา: คอร์เสา Mega Pillars 4 มุม และทาวเวอร์บันไดหนีไฟ/ลิฟต์ทั้งสองฝั่ง
      7. ยอดตึกและดาดฟ้า: ป้ายชื่ออาคารตัวใหญ่เด่นตระหง่านทั้งด้านหน้าและด้านหลัง
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

    local concreteLight = Color3.fromRGB(242, 238, 228) -- คอนกรีตสีครีมสว่าง
    local concreteMid   = Color3.fromRGB(205, 198, 185) -- คอนกรีตเสาโครงสร้าง
    local facadeOrange  = Color3.fromRGB(208, 98, 44)   -- สีส้มอิฐเอกลักษณ์ มจพ.
    local praduRed      = Color3.fromRGB(140, 26, 38)   -- สีแดงประดู่ประจำ มจพ.
    local frameDark     = Color3.fromRGB(40, 45, 52)    -- กรอบอะลูมิเนียมสีดำเทา
    local glassTint     = Color3.fromRGB(80, 142, 172)  -- กระจกตัดแสงสะท้อนเงา
    local louverSilver  = Color3.fromRGB(190, 196, 204) -- บานเกล็ดระบายอากาศ
    local bblBlue       = Color3.fromRGB(15, 65, 145)   -- น้ำเงินธนาคารกรุงเทพ

    ------------------------------------------------------------------
    -- 1. เสามุมตึกขนาดใหญ่ (Mega Corner Pillars) และ ครีบแนวตั้ง (Vertical Fins)
    ------------------------------------------------------------------
    local finsFolder = Instance.new("Model")
    finsFolder.Name = "ExteriorVerticalGridFins"
    finsFolder.Parent = extModel

    local totalUpperH = topRoofY - Layout.floorY(2) -- 242.0 (ชั้น 2 ถึง ดาดฟ้า)
    local midUpperY = (Layout.floorY(2) + topRoofY) / 2
    local fullH = topRoofY + 8.0 - 1.0
    local fullMidY = 1.0 + fullH / 2

    -- เสามุมขนาดใหญ่ 4 มุมตึก พร้อมขอบสีส้มอิฐตัดตรง
    for _, sx in ipairs({ -1, 1 }) do
        for _, sz in ipairs({ -1, 1 }) do
            PartBuilder.makePart(finsFolder, string.format("CornerMegaPillar_%d_%d", sx, sz),
                Vector3.new(3.8, fullH, 3.8),
                CFrame.new(sx * (body.halfX + 0.6), fullMidY, sz * (body.halfZ + 0.6)),
                concreteLight, Enum.Material.Concrete)
            PartBuilder.makePart(finsFolder, string.format("CornerOrangeAccent_%d_%d", sx, sz),
                Vector3.new(1.6, fullH, 1.6),
                CFrame.new(sx * (body.halfX + 1.6), fullMidY, sz * (body.halfZ + 1.6)),
                facadeOrange, Enum.Material.SmoothPlastic)
        end
    end

    -- ครีบเสาแนวตั้งด้านหน้าตึก (Z = +120.5) และด้านหลังตึก (Z = -120.5)
    local gridXs = { -116, -92, -64, -32, 32, 64, 92, 116 }
    for _, gx in ipairs(gridXs) do
        for _, sz in ipairs({ -1, 1 }) do
            PartBuilder.makePart(finsFolder, string.format("Pilaster_NS_%d_%d", gx, sz),
                Vector3.new(2.2, totalUpperH, 1.4),
                CFrame.new(gx, midUpperY, sz * (body.halfZ + 0.6)),
                concreteMid, Enum.Material.Concrete)
            PartBuilder.makePart(finsFolder, string.format("PilasterTrim_NS_%d_%d", gx, sz),
                Vector3.new(1.0, totalUpperH, 0.4),
                CFrame.new(gx, midUpperY, sz * (body.halfZ + 1.4)),
                facadeOrange, Enum.Material.SmoothPlastic)
        end
    end

    -- ครีบเสาแนวตั้งด้านข้างซ้าย (X = -150.5) และขวา (X = +150.5)
    local gridZs = { -86, -58, -22, 22, 58, 86 }
    for _, gz in ipairs(gridZs) do
        for _, sx in ipairs({ -1, 1 }) do
            PartBuilder.makePart(finsFolder, string.format("Pilaster_WE_%d_%d", gz, sx),
                Vector3.new(1.4, totalUpperH, 2.2),
                CFrame.new(sx * (body.halfX + 0.6), midUpperY, gz),
                concreteMid, Enum.Material.Concrete)
            PartBuilder.makePart(finsFolder, string.format("PilasterTrim_WE_%d_%d", gz, sx),
                Vector3.new(0.4, totalUpperH, 1.0),
                CFrame.new(sx * (body.halfX + 1.4), midUpperY, gz),
                facadeOrange, Enum.Material.SmoothPlastic)
        end
    end

    ------------------------------------------------------------------
    -- 2. คานขอบพื้นรอบตึกและแถบสีส้มอิฐ มจพ. (Horizontal Architectural Bands)
    ------------------------------------------------------------------
    local bandsFolder = Instance.new("Model")
    bandsFolder.Name = "ExteriorFloorSpandrelBands"
    bandsFolder.Parent = extModel

    for f = 2, 13 do
        local bandY = Layout.floorY(f)
        local isAccent = (f == 2 or f == 3 or f == 7 or f == 11 or f == 12 or f == 13)
        local trimCol = isAccent and facadeOrange or praduRed

        -- ด้านข้างซ้าย-ขวา (ยาว 240 studs)
        for _, sx in ipairs({ -1, 1 }) do
            PartBuilder.makePart(bandsFolder, string.format("Spandrel_WE_F%d_%d", f, sx),
                Vector3.new(1.2, 2.6, body.halfZ * 2 + 2.0),
                CFrame.new(sx * (body.halfX + 0.5), bandY - 0.2, 0),
                concreteLight, Enum.Material.Concrete)
            PartBuilder.makePart(bandsFolder, string.format("Trim_WE_F%d_%d", f, sx),
                Vector3.new(1.4, 0.8, body.halfZ * 2 + 2.2),
                CFrame.new(sx * (body.halfX + 0.6), bandY - 1.0, 0),
                trimCol, Enum.Material.SmoothPlastic)
        end

        -- ด้านหลังตึก (ทิศเหนือ ติดคลองบางเขนใหม่ Z = -120.5)
        PartBuilder.makePart(bandsFolder, string.format("Spandrel_North_F%d", f),
            Vector3.new(body.halfX * 2 + 2.0, 2.6, 1.2),
            CFrame.new(0, bandY - 0.2, -(body.halfZ + 0.5)),
            concreteLight, Enum.Material.Concrete)
        PartBuilder.makePart(bandsFolder, string.format("Trim_North_F%d", f),
            Vector3.new(body.halfX * 2 + 2.2, 0.8, 1.4),
            CFrame.new(0, bandY - 1.0, -(body.halfZ + 0.6)),
            trimCol, Enum.Material.SmoothPlastic)

        -- ด้านหน้าตึก (ทิศใต้ ลานสวนปาล์ม Z = +120.5)
        if f == 2 then
            -- ชั้น 2 เว้นช่องบันไดใหญ่หน้าโรงอาหาร
            for _, sx in ipairs({ -1, 1 }) do
                PartBuilder.makePart(bandsFolder, "Spandrel_South_F2_" .. sx,
                    Vector3.new(122, 2.6, 1.2),
                    CFrame.new(sx * 89, bandY - 0.2, body.halfZ + 0.5),
                    concreteLight, Enum.Material.Concrete)
                PartBuilder.makePart(bandsFolder, "Trim_South_F2_" .. sx,
                    Vector3.new(122, 0.8, 1.4),
                    CFrame.new(sx * 89, bandY - 1.0, body.halfZ + 0.6),
                    trimCol, Enum.Material.SmoothPlastic)
            end
        else
            PartBuilder.makePart(bandsFolder, string.format("Spandrel_South_F%d", f),
                Vector3.new(body.halfX * 2 + 2.0, 2.6, 1.2),
                CFrame.new(0, bandY - 0.2, body.halfZ + 0.5),
                concreteLight, Enum.Material.Concrete)
            PartBuilder.makePart(bandsFolder, string.format("Trim_South_F%d", f),
                Vector3.new(body.halfX * 2 + 2.2, 0.8, 1.4),
                CFrame.new(0, bandY - 1.0, body.halfZ + 0.6),
                trimCol, Enum.Material.SmoothPlastic)
        end
    end

    ------------------------------------------------------------------
    -- 3. แผงหน้าต่างกระจกและบานเกล็ดรอบด้าน 4 ทิศ (Exterior Glazing & Louvers)
    ------------------------------------------------------------------
    local winFolder = Instance.new("Model")
    winFolder.Name = "ExteriorWindowsAndLouvers"
    winFolder.Parent = extModel

    local floorsWithWindows = { 3, 4, 5, 6, 7, 8, 9, 10, 11 }
    for _, f in ipairs(floorsWithWindows) do
        local fy = Layout.floorY(f)

        -- ด้านข้างซ้ายและขวา (East & West)
        for _, sx in ipairs({ -1, 1 }) do
            local wx = sx * (body.halfX + 0.2)
            for _, wz in ipairs({ -72, -40, 0, 40, 72 }) do
                PartBuilder.makePart(winFolder, string.format("Win_WE_F%d_%d_%d", f, sx, wz),
                    Vector3.new(0.3, 10.0, 20.0), CFrame.new(wx, fy + 11.5, wz), frameDark, Enum.Material.Metal)
                PartBuilder.makePart(winFolder, string.format("Glass_WE_F%d_%d_%d", f, sx, wz),
                    Vector3.new(0.35, 9.2, 19.0), CFrame.new(wx, fy + 11.5, wz), glassTint, Enum.Material.Glass, { Reflectance = 0.3 })
                PartBuilder.makePart(winFolder, string.format("Louver_WE_F%d_%d_%d", f, sx, wz),
                    Vector3.new(1.6, 0.4, 20.6), CFrame.new(wx + sx * 0.7, fy + 16.8, wz), louverSilver, Enum.Material.Metal)
            end
        end

        -- ด้านหน้า (South) และด้านหลัง (North)
        for _, sz in ipairs({ -1, 1 }) do
            local wz = sz * (body.halfZ + 0.2)
            for _, wx in ipairs({ -130, -78, 78, 130 }) do
                PartBuilder.makePart(winFolder, string.format("Win_NS_F%d_%d_%d", f, sz, wx),
                    Vector3.new(20.0, 9.5, 0.3), CFrame.new(wx, fy + 12.0, wz), frameDark, Enum.Material.Metal)
                PartBuilder.makePart(winFolder, string.format("Glass_NS_F%d_%d_%d", f, sz, wx),
                    Vector3.new(19.0, 8.8, 0.35), CFrame.new(wx, fy + 12.0, wz), glassTint, Enum.Material.Glass, { Reflectance = 0.3 })
                PartBuilder.makePart(winFolder, string.format("SunFin_NS_F%d_%d_%d", f, sz, wx),
                    Vector3.new(20.6, 0.4, 1.6), CFrame.new(wx, fy + 16.8, wz + sz * 0.7), louverSilver, Enum.Material.Metal)
            end
        end
    end

    ------------------------------------------------------------------
    -- 4. ชั้น 1 ด้านหน้า: โถงทางเข้ากระจก, ป้ายธนาคารกรุงเทพ & กองกิจการ นศ.
    ------------------------------------------------------------------
    local groundFront = Instance.new("Model")
    groundFront.Name = "Floor1_FrontEntrances"
    groundFront.Parent = extModel

    -- ผนังกระจกใสบานใหญ่ทางเข้าหลักชั้น 1 (Z = +120)
    PartBuilder.makePart(groundFront, "MainEntranceGlazing",
        Vector3.new(62, 16.0, 0.4),
        CFrame.new(0, 9.0, body.halfZ + 0.2),
        glassTint, Enum.Material.Glass, { Transparency = 0.45, Reflectance = 0.2 })

    -- ประตูเลื่อนอัตโนมัติคู่กลาง
    for _, sx in ipairs({ -1, 1 }) do
        PartBuilder.makePart(groundFront, "AutoDoorFrame_" .. sx,
            Vector3.new(6.0, 10.5, 0.5),
            CFrame.new(sx * 4.5, 6.25, body.halfZ + 0.4),
            frameDark, Enum.Material.Metal)
    end

    -- ป้ายธนาคารกรุงเทพ (Bangkok Bank) ชั้น 1 ฝั่งขวา
    local bblSign = Instance.new("Model")
    bblSign.Name = "BangkokBank_Signage"
    bblSign.Parent = groundFront

    PartBuilder.makePart(bblSign, "BBL_SignBacking",
        Vector3.new(34, 4.2, 0.6),
        CFrame.new(62, 17.5, body.halfZ + 0.6),
        bblBlue, Enum.Material.SmoothPlastic)

    PartBuilder.makeSign(bblSign, "BBL_SignLabel",
        "ธนาคารกรุงเทพ  BANGKOK BANK",
        Vector3.new(33, 3.8, 0.2),
        Vector3.new(62, 17.5, body.halfZ + 1.0),
        Enum.NormalId.Back, bblBlue, Color3.fromRGB(255, 255, 255))

    -- ป้ายกองกิจการนักศึกษา ชั้น 1 ฝั่งซ้าย
    PartBuilder.makeSign(groundFront, "StudentAffairs_SignLabel",
        "ศูนย์บริการนักศึกษา (กองกิจการนักศึกษา)",
        Vector3.new(36, 3.8, 0.2),
        Vector3.new(-62, 17.5, body.halfZ + 1.0),
        Enum.NormalId.Back, praduRed, Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 5. ชั้น 1 ด้านหลัง: ช่องทางเข้าออกลานจอดรถขับทะลุ (หันสู่คลอง)
    ------------------------------------------------------------------
    local groundBack = Instance.new("Model")
    groundBack.Name = "Floor1_BackDriveThrough"
    groundBack.Parent = extModel

    -- เสากลมรองรับทางออกลานจอดรถด้านหลัง
    for _, x in ipairs({ -90, -45, 0, 45, 90 }) do
        PartBuilder.makeCylinder(groundBack, "BackDriveColumn_" .. x,
            Vector3.new(18.0, 3.2, 3.2),
            CFrame.new(x, 10.0, -(body.halfZ + 0.5)) * CFrame.Angles(0, 0, math.rad(90)),
            concreteMid, Enum.Material.Concrete)
    end

    ------------------------------------------------------------------
    -- 6. ชั้น 2 ระเบียงและป้ายโรงอาหาร 40 ปี (Canteen Front Overhang)
    ------------------------------------------------------------------
    local canteenExterior = Instance.new("Model")
    canteenExterior.Name = "Floor2_CanteenExterior"
    canteenExterior.Parent = extModel

    local cY = Layout.floorY(2)
    PartBuilder.makeSign(canteenExterior, "CanteenSign",
        "โรงอาหาร 40 ปี สจพ. (มจพ.)  |  CANTEEN",
        Vector3.new(54, 4.5, 0.4),
        Vector3.new(0, cY + 18.0, body.halfZ + 2.2),
        Enum.NormalId.Back, facadeOrange, Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 7. ดาดฟ้าและป้ายชื่ออาคารบนยอดตึก (Rooftop Crown & Grand KMUTNB Signs)
    ------------------------------------------------------------------
    local crownFolder = Instance.new("Model")
    crownFolder.Name = "RooftopCrownAndSigns"
    crownFolder.Parent = extModel

    local parapetH = 7.0
    local parapetY = topRoofY + 2.5 + parapetH / 2

    -- ขอบกำแพงดาดฟ้า 4 ด้าน (Parapet Walls with Pradu-Red Coping)
    for _, sz in ipairs({ -1, 1 }) do
        PartBuilder.makePart(crownFolder, "Parapet_NS_" .. sz,
            Vector3.new(body.halfX * 2 + 2, parapetH, 2.4),
            CFrame.new(0, parapetY, sz * (body.halfZ - 0.5)), concreteLight, Enum.Material.Concrete)
        PartBuilder.makePart(crownFolder, "Coping_NS_" .. sz,
            Vector3.new(body.halfX * 2 + 2.8, 1.4, 2.8),
            CFrame.new(0, parapetY + parapetH / 2 + 0.5, sz * (body.halfZ - 0.5)), praduRed, Enum.Material.SmoothPlastic)
    end
    for _, sx in ipairs({ -1, 1 }) do
        PartBuilder.makePart(crownFolder, "Parapet_WE_" .. sx,
            Vector3.new(2.4, parapetH, body.halfZ * 2 + 2),
            CFrame.new(sx * (body.halfX - 0.5), parapetY, 0), concreteLight, Enum.Material.Concrete)
        PartBuilder.makePart(crownFolder, "Coping_WE_" .. sx,
            Vector3.new(2.8, 1.4, body.halfZ * 2 + 2.8),
            CFrame.new(sx * (body.halfX - 0.5), parapetY + parapetH / 2 + 0.5, 0), praduRed, Enum.Material.SmoothPlastic)
    end

    -- ห้องเครื่องลิฟต์บนยอดดาดฟ้า (Lift Motor Penthouses)
    for _, sz in ipairs({ -1, 1 }) do
        PartBuilder.makePart(crownFolder, "ElevatorPenthouse_" .. sz,
            Vector3.new(140, 15.0, 34),
            CFrame.new(0, topRoofY + 2.5 + 7.5, sz * 102), concreteLight, Enum.Material.Concrete)
        PartBuilder.makePart(crownFolder, "PenthouseCoping_" .. sz,
            Vector3.new(142, 1.6, 36),
            CFrame.new(0, topRoofY + 2.5 + 15.3, sz * 102), praduRed, Enum.Material.SmoothPlastic)
    end

    -- ป้ายชื่ออาคารด้านหน้า (ทิศใต้): "อาคารเอนกประสงค์ 40 ปี มจพ. (อาคาร 77)"
    PartBuilder.makeSign(crownFolder, "GrandCrownSign_South",
        "อาคารเอนกประสงค์ 40 ปี มจพ.  (อาคาร 77)\nKMUTNB 40th ANNIVERSARY BUILDING",
        Vector3.new(125, 10.5, 0.8),
        Vector3.new(0, topRoofY + 12.0, body.halfZ + 1.2),
        Enum.NormalId.Back, praduRed, Color3.fromRGB(255, 255, 255))

    -- ป้ายชื่อมหาวิทยาลัยด้านหลัง (ทิศเหนือ หันสู่คลองบางเขนใหม่)
    PartBuilder.makeSign(crownFolder, "GrandCrownSign_North",
        "มหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ\nKING MONGKUT'S UNIVERSITY OF TECHNOLOGY NORTH BANGKOK",
        Vector3.new(145, 10.5, 0.8),
        Vector3.new(0, topRoofY + 12.0, -(body.halfZ + 1.2)),
        Enum.NormalId.Front, praduRed, Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 8. ป้ายทำเนียบข้อมูลทางการอาคาร 77 หน้าตึก (Official Directory Monument)
    ------------------------------------------------------------------
    local monument = Instance.new("Model")
    monument.Name = "OfficialBuilding77DirectoryMonument"
    monument.Parent = extModel

    local mx = -38
    local mz = 138
    PartBuilder.makePart(monument, "Pedestal", Vector3.new(18, 2.4, 2.6),
        CFrame.new(mx, 2.2, mz), Color3.fromRGB(45, 50, 56), Enum.Material.Granite)
    PartBuilder.makeSign(monument, "DirectoryBoard",
        "อาคาร 77 : อาคารเอนกประสงค์ 40 ปี มจพ.\n"
        .. "[ชั้น 12] สนามกีฬาชั้นบนสุด: เวทีมวย / เทควันโด & กระสอบทราย / เทนนิส / ฟุตซอล\n"
        .. "[ชั้น 11] หอพัก KMUTNB Residence & โถงชมกีฬา\n"
        .. "[ชั้น 8-10] ห้องชมรมนักศึกษา / กิจกรรมนักศึกษา & โถงชมกีฬา\n"
        .. "[ชั้น 7] สนามวอลเลย์บอล & สนามแบดมินตัน 4 คอร์ท\n"
        .. "[ชั้น 4-6] กองกิจการนักศึกษา (ชั้น 5 กิจกรรม นศ./กยศ./แนะแนว/วินัย)\n"
        .. "[ชั้น 3] สนามฟุตซอล (กรงตาข่าย) & สนามบาสเกตบอล & ปิงปอง\n"
        .. "[ชั้น 2] โรงอาหาร 40 ปี มจพ.  |  [ชั้น 1] ธนาคารกรุงเทพ & คาเฟ่ & ศูนย์บริการ นศ.",
        Vector3.new(17.0, 9.0, 1.0), Vector3.new(mx, 7.9, mz),
        Enum.NormalId.Back, praduRed, Color3.fromRGB(255, 255, 255))

    print("🏛️ [Exterior Facade Built] สถาปัตยกรรม 12 ชั้น อาคาร 40 ปี มจพ. (อาคาร 77) ทั้ง 4 ทิศสมบูรณ์!")
end

return Building40_ExteriorFacade
