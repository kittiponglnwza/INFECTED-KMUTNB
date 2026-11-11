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
    -- 2. ระเบียงขอบตึกยื่นรอบอาคารทุกชั้น (แบบไม่มีที่กั้น) + คิ้วขอบสีส้มอิฐ/แดงประดู่ มจพ.
    ------------------------------------------------------------------
    local bandsFolder = Instance.new("Model")
    bandsFolder.Name = "ExteriorFloorSpandrelBands"
    bandsFolder.Parent = extModel

    local balconyDepth = 5.0
    local balconyThick = 1.1

    local function makeBalconySpan(nameX, nameTrim, sizeVec, posCF, trimSize, trimCF, trimCol)
        PartBuilder.makePart(bandsFolder, nameX, sizeVec, posCF, concreteLight, Enum.Material.Concrete)
        PartBuilder.makePart(bandsFolder, nameTrim, trimSize, trimCF, trimCol, Enum.Material.SmoothPlastic)
    end

    for f = 2, 13 do
        local bandY = Layout.floorY(f)
        local isAccent = (f == 2 or f == 3 or f == 7 or f == 11 or f == 12 or f == 13)
        local trimCol = isAccent and facadeOrange or praduRed

        if f <= 12 then
            local midY = bandY - balconyThick / 2
            local trimY = bandY - 0.82
            local fullSpanX = body.halfX * 2 + balconyDepth * 2
            local weLen = body.halfZ * 2
            local weTrimLen = body.halfZ * 2 + balconyDepth * 2 - 0.1

            -- ระเบียงด้านข้างซ้าย-ขวา (ยื่น 5.0 studs รอบตึก ไม่มีที่กั้น)
            for _, sx in ipairs({ -1, 1 }) do
                makeBalconySpan(
                    string.format("Balcony_WE_F%d_%d", f, sx),
                    string.format("Trim_WE_F%d_%d", f, sx),
                    Vector3.new(balconyDepth, balconyThick, weLen),
                    CFrame.new(sx * (body.halfX + balconyDepth / 2), midY, 0),
                    Vector3.new(0.25, 0.45, weTrimLen),
                    CFrame.new(sx * (body.halfX + balconyDepth + 0.08), trimY, 0),
                    trimCol
                )
            end

            -- ระเบียงด้านหลังตึก (ทิศเหนือ)
            makeBalconySpan(
                string.format("Balcony_North_F%d", f),
                string.format("Trim_North_F%d", f),
                Vector3.new(fullSpanX, balconyThick, balconyDepth),
                CFrame.new(0, midY, -(body.halfZ + balconyDepth / 2)),
                Vector3.new(fullSpanX + 0.3, 0.45, 0.25),
                CFrame.new(0, trimY, -(body.halfZ + balconyDepth + 0.08)),
                trimCol
            )

            -- ระเบียงด้านหน้าตึก (ทิศใต้ — ชั้น 2 เว้นช่วงสะพานทางขึ้นโรงอาหารตรงกลาง X = -27..+27)
            if f == 2 then
                for _, sx in ipairs({ -1, 1 }) do
                    local segW = 128 -- ±27 ถึง ±155
                    local cx = sx * (27 + segW / 2)
                    makeBalconySpan(
                        "Balcony_South_F2_" .. sx,
                        "Trim_South_F2_" .. sx,
                        Vector3.new(segW, balconyThick, balconyDepth),
                        CFrame.new(cx, midY, body.halfZ + balconyDepth / 2),
                        Vector3.new(segW + 0.15, 0.45, 0.25),
                        CFrame.new(cx + sx * 0.075, trimY, body.halfZ + balconyDepth + 0.08),
                        trimCol
                    )
                end
            else
                makeBalconySpan(
                    string.format("Balcony_South_F%d", f),
                    string.format("Trim_South_F%d", f),
                    Vector3.new(fullSpanX, balconyThick, balconyDepth),
                    CFrame.new(0, midY, body.halfZ + balconyDepth / 2),
                    Vector3.new(fullSpanX + 0.3, 0.45, 0.25),
                    CFrame.new(0, trimY, body.halfZ + balconyDepth + 0.08),
                    trimCol
                )
            end
        else
            -- ขอบชายคาดาดฟ้า (f = 13)
            for _, sx in ipairs({ -1, 1 }) do
                makeBalconySpan(
                    "RoofEave_WE_" .. sx, "Trim_WE_F13_" .. sx,
                    Vector3.new(1.4, 2.2, body.halfZ * 2 + 2.4),
                    CFrame.new(sx * (body.halfX + 0.6), bandY - 0.2, 0),
                    Vector3.new(1.6, 0.8, body.halfZ * 2 + 2.6),
                    CFrame.new(sx * (body.halfX + 0.7), bandY - 0.9, 0),
                    trimCol
                )
            end
            for _, sz in ipairs({ -1, 1 }) do
                makeBalconySpan(
                    "RoofEave_NS_" .. sz, "Trim_NS_F13_" .. sz,
                    Vector3.new(body.halfX * 2 + 2.4, 2.2, 1.4),
                    CFrame.new(0, bandY - 0.2, sz * (body.halfZ + 0.6)),
                    Vector3.new(body.halfX * 2 + 2.6, 0.8, 1.6),
                    CFrame.new(0, bandY - 0.9, sz * (body.halfZ + 0.7)),
                    trimCol
                )
            end
        end
    end

    ------------------------------------------------------------------
    -- 3. แผงหน้าต่างกระจกโปร่งมีวงกบ 4 ด้านและคิ้วกันแดดรอบตึก (ไร้แผ่นทึบซ้อนหลังกระจก)
    ------------------------------------------------------------------
    local winFolder = Instance.new("Model")
    winFolder.Name = "ExteriorWindowsAndLouvers"
    winFolder.Parent = extModel

    local function buildFramedExteriorWindow(prefix, axis, fixedPos, dirSign, alongPos, cy, winW, winH, isSeeThrough)
        local barW = 0.55
        local frameD = 0.44
        local innerW = winW - barW * 2
        local innerH = winH - barW * 2

        local function sz3(along, vert, depth)
            return (axis == "NS") and Vector3.new(along, vert, depth) or Vector3.new(depth, vert, along)
        end
        local function cf3(along, y, depthPos)
            return (axis == "NS") and CFrame.new(along, y, depthPos) or CFrame.new(depthPos, y, along)
        end

        -- วงกบอะลูมิเนียม 4 ด้าน + เสาซอยกลาง (ไม่มีแผ่นเหล็กทึบปิดหลังกระจก)
        PartBuilder.makePart(winFolder, prefix .. "_FrameTop", sz3(winW, barW, frameD),
            cf3(alongPos, cy + winH / 2 - barW / 2, fixedPos), frameDark, Enum.Material.Metal)
        PartBuilder.makePart(winFolder, prefix .. "_FrameBot", sz3(winW, barW, frameD),
            cf3(alongPos, cy - winH / 2 + barW / 2, fixedPos), frameDark, Enum.Material.Metal)
        PartBuilder.makePart(winFolder, prefix .. "_FrameL", sz3(barW, innerH, frameD),
            cf3(alongPos - winW / 2 + barW / 2, cy, fixedPos), frameDark, Enum.Material.Metal)
        PartBuilder.makePart(winFolder, prefix .. "_FrameR", sz3(barW, innerH, frameD),
            cf3(alongPos + winW / 2 - barW / 2, cy, fixedPos), frameDark, Enum.Material.Metal)
        PartBuilder.makePart(winFolder, prefix .. "_Mullion", sz3(0.32, innerH, 0.36),
            cf3(alongPos, cy, fixedPos), frameDark, Enum.Material.Metal)

        if not isSeeThrough then
            PartBuilder.makePart(winFolder, prefix .. "_SpandrelBack", sz3(innerW, innerH, 0.08),
                cf3(alongPos, cy, fixedPos - dirSign * 0.12), Color3.fromRGB(28, 44, 58), Enum.Material.SmoothPlastic)
        end

        PartBuilder.makePart(winFolder, prefix .. "_Glass", sz3(innerW, innerH, 0.14),
            cf3(alongPos, cy, fixedPos), glassTint, Enum.Material.Glass, { Transparency = 0.45, Reflectance = 0.25 })
    end

    local floorsWithWindows = { 3, 4, 5, 6, 7, 8, 9, 10, 11 }
    for _, f in ipairs(floorsWithWindows) do
        local fy = Layout.floorY(f)
        local isOfficeFloor = (f >= 4 and f <= 6) or (f >= 8 and f <= 11)

        -- ด้านข้างซ้ายและขวา (East & West) — เจาะช่องหน้าต่างจริงครบทุกชั้น 3-11
        for _, sx in ipairs({ -1, 1 }) do
            local wx = sx * (body.halfX + 0.12)
            for _, wz in ipairs({ -72, -40, 0, 40, 72 }) do
                buildFramedExteriorWindow(string.format("Win_WE_F%d_%d_%d", f, sx, wz),
                    "WE", wx, sx, wz, fy + 11.5, 20.0, 10.0, true)
                PartBuilder.makePart(winFolder, string.format("Louver_WE_F%d_%d_%d", f, sx, wz),
                    Vector3.new(1.6, 0.4, 20.6), CFrame.new(wx + sx * 0.78, fy + 16.8, wz), louverSilver, Enum.Material.Metal)
            end
        end

        -- ด้านหน้า (South) และด้านหลัง (North)
        for _, sz in ipairs({ -1, 1 }) do
            local wz = sz * (body.halfZ + 0.12)
            for _, wx in ipairs({ -130, -78, 78, 130 }) do
                local openInterior = isOfficeFloor and (math.abs(wx) == 78)
                buildFramedExteriorWindow(string.format("Win_NS_F%d_%d_%d", f, sz, wx),
                    "NS", wz, sz, wx, fy + 12.0, 20.0, 9.5, openInterior)
                PartBuilder.makePart(winFolder, string.format("SunFin_NS_F%d_%d_%d", f, sz, wx),
                    Vector3.new(20.6, 0.4, 1.6), CFrame.new(wx, fy + 16.8, wz + sz * 0.78), louverSilver, Enum.Material.Metal)
            end
        end
    end

    ------------------------------------------------------------------
    -- 4-5. ชั้น 1 ด้านหน้า & ด้านหลัง: โถงทางเข้าเปิดโล่ง (ไม่มีป้ายซ้ำซ้อนหรือเสาเกะกะ)
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 6. ชั้น 2 ระเบียงและป้ายโรงอาหาร 40 ปี (Canteen Front Overhang)
    ------------------------------------------------------------------
    local canteenExterior = Instance.new("Model")
    canteenExterior.Name = "Floor2_CanteenExterior"
    canteenExterior.Parent = extModel

    local cY = Layout.floorY(2)
    PartBuilder.makeSign(canteenExterior, "CanteenSign",
        "โรงอาหาร 40 ปี สจพ. (มจพ.)  |  CANTEEN",
        Vector3.new(54, 3.8, 0.4),
        Vector3.new(0, cY + 18.6, body.halfZ + 2.2),
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

    -- ป้ายชื่อมหาวิทยาลัยด้านหลัง (ทิศเหนือ)
    PartBuilder.makeSign(crownFolder, "GrandCrownSign_North",
        "มหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ\nKING MONGKUT'S UNIVERSITY OF TECHNOLOGY NORTH BANGKOK",
        Vector3.new(145, 10.5, 0.8),
        Vector3.new(0, topRoofY + 12.0, -(body.halfZ + 1.2)),
        Enum.NormalId.Front, praduRed, Color3.fromRGB(255, 255, 255))

    print("🏛️ [Exterior Facade Built] สถาปัตยกรรม 12 ชั้น อาคาร 40 ปี มจพ. (อาคาร 77) ทั้ง 4 ทิศสมบูรณ์!")
end

return Building40_ExteriorFacade
