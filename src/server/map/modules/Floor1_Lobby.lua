--[[
    Floor1_Lobby.lua
    โครงสร้างชั้น 1 (Floor G) อาคาร 40 ปี มจพ.
    สร้างตรงตามภาพแปลนลายเส้นที่อัปเดตล่าสุด (media_1794242823441_57b638da.png)

    จุดสำคัญ:
      1. ลิฟต์และบันไดอยู่ในตัวอาคารทั้งหมด (กรอบสี่เหลี่ยมผืนผ้าเดียว 300 x 240 studs ไม่ยื่นออกนอกตึก)
      2. แถบบน (หลังตึก Z = -120..-44): [ห้อง] [ลิฟ] [ทางเข้าออก] [บันได] [คาเฟ่] เรียงแนวเดียวกัน
      3. แถบล่าง (หน้าตึก Z = +44..+120): [ห้อง] [บันได] [ทางเข้าออก] [ลิฟ] [ธนาคาร] เรียงแนวเดียวกัน
      4. ตรงกลาง (Z = -44..+44): ลานจอดรถ มีลูกศรทางเข้า/ออกฝั่งขวา
      5. ปิดตายทุกห้อง + บันไดหันหน้าเข้าหาลิฟต์ใกล้ๆ เริ่มขึ้นจากเลนซ้าย + ไม่มีขอบทางเข้าออก
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local StairBuilder = require(script.Parent.Parent.utils.StairBuilder)
local ElevatorBuilder = require(script.Parent.Parent.utils.ElevatorBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Floor1_Lobby = {}

function Floor1_Lobby.build(parent)
    local floor1 = Instance.new("Model")
    floor1.Name = "Floor_1_Building40"
    floor1.Parent = parent

    local floorY = Layout.GROUND_Y       -- 1.0
    local wallH = Layout.FLOOR_HEIGHT    -- 22.0
    local wallThick = Layout.WALL_THICK  -- 2.0
    local wallColor = Color3.fromRGB(242, 239, 233)
    local wallMaterial = Enum.Material.Concrete

    local body = Layout.BODY
    local core = Layout.CORE

    ------------------------------------------------------------------
    -- 1. พื้นฐานชั้น 1 (Main Ground Slab 300 x 240 studs กรอบสี่เหลี่ยมเดียว)
    ------------------------------------------------------------------
    PartBuilder.makePart(
        floor1,
        "Floor1_BaseSlab_2X",
        Vector3.new(body.halfX * 2, 2.0, body.halfZ * 2),
        CFrame.new(0, floorY - 1.0, 0),
        Color3.fromRGB(225, 222, 215),
        Enum.Material.SmoothPlastic
    )

    ------------------------------------------------------------------
    -- 2. พื้นที่ตรงกลาง: "ลานจอดรถ" (Z = -44..+44, กว้าง 88 studs)
    ------------------------------------------------------------------
    local parkingZone = Instance.new("Folder")
    parkingZone.Name = "ParkingLotZone"
    parkingZone.Parent = floor1

    PartBuilder.makePart(
        parkingZone,
        "DrivewayAsphalt_2X",
        Vector3.new(body.halfX * 2, 0.01, core.bandInnerZ * 2),
        CFrame.new(0, floorY + 0.005, 0),
        Color3.fromRGB(48, 50, 54),
        Enum.Material.Asphalt,
        { CanCollide = false }
    )

    -- เส้นจราจรแบ่งเลนกึ่งกลางสีเหลืองคู่
    PartBuilder.makePart(parkingZone, "YellowLine_1", Vector3.new(280, 0.02, 0.8), CFrame.new(-5, floorY + 0.015, -1.0), Color3.fromRGB(255, 215, 30), Enum.Material.SmoothPlastic, { CanCollide = false })
    PartBuilder.makePart(parkingZone, "YellowLine_2", Vector3.new(280, 0.02, 0.8), CFrame.new(-5, floorY + 0.015,  1.0), Color3.fromRGB(255, 215, 30), Enum.Material.SmoothPlastic, { CanCollide = false })

    -- ช่องจอดรถ 10 ซอง พร้อมหมอนหยุดล้อ
    for p = 1, 5 do
        local pX = -110 + ((p - 1) * 32)
        PartBuilder.makePart(parkingZone, "Stripe_Top_" .. p, Vector3.new(1.0, 0.02, 28), CFrame.new(pX, floorY + 0.015, -30), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, { CanCollide = false })
        PartBuilder.makePart(parkingZone, "WheelStop_T_" .. p, Vector3.new(12, 0.9, 1.5), CFrame.new(pX + 16, floorY + 0.45, -41), Color3.fromRGB(235, 185, 30), Enum.Material.Concrete)

        PartBuilder.makePart(parkingZone, "Stripe_Bot_" .. p, Vector3.new(1.0, 0.02, 28), CFrame.new(pX, floorY + 0.015, 30), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, { CanCollide = false })
        PartBuilder.makePart(parkingZone, "WheelStop_B_" .. p, Vector3.new(12, 0.9, 1.5), CFrame.new(pX + 16, floorY + 0.45, 41), Color3.fromRGB(235, 185, 30), Enum.Material.Concrete)
    end

    -- เสาโครงสร้างลานจอดรถ 4 ต้น
    for _, px in ipairs({ -70, 70 }) do
        for _, pz in ipairs({ -36, 36 }) do
            PartBuilder.makePart(parkingZone, "Pillar_2X", Vector3.new(6.0, wallH, 6.0), CFrame.new(px, floorY + wallH/2, pz), Color3.fromRGB(215, 215, 220), Enum.Material.Concrete)
            PartBuilder.makePart(parkingZone, "SafetyBand", Vector3.new(6.4, 4.5, 6.4), CFrame.new(px, floorY + 4.0, pz), Color3.fromRGB(240, 180, 20), Enum.Material.SmoothPlastic)
        end
    end

    PartBuilder.makeSign(
        parkingZone,
        "Sign_Parking_2X",
        "ลานจอดรถ\nPARKING LOT",
        Vector3.new(28, 0.02, 7.0),
        Vector3.new(-25, floorY + 0.02, 0),
        Enum.NormalId.Top,
        Color3.fromRGB(48, 50, 54),
        Color3.fromRGB(255, 220, 50)
    )

    -- ลูกศรทางเข้า-ออกฝั่งขวา (+X)
    PartBuilder.makeSign(parkingZone, "Arrow_Out_2X", "→ ทางออก (EXIT) →", Vector3.new(24, 0.02, 4.5), Vector3.new(120, floorY + 0.02, -22), Enum.NormalId.Top, Color3.fromRGB(48, 50, 54), Color3.fromRGB(255, 255, 255))
    PartBuilder.makeSign(parkingZone, "Arrow_In_2X",  "← ทางเข้า (IN) ←",  Vector3.new(24, 0.02, 4.5), Vector3.new(120, floorY + 0.02,  22), Enum.NormalId.Top, Color3.fromRGB(48, 50, 54), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 3. ห้องมุมทั้ง 4 ของชั้น 1 (X = ±68..±150, Z = ±44..±120, ขนาด 82 x 76 studs)
    --    สร้างหน้าร้านและตกแต่งภายในตามห้องจริงทั้งด้านหน้าตึก (Z = ±120) และด้านในลานจอดรถ (Z = ±44):
    --      - ขวาล่าง (หน้าตึกฝั่งขวา X = +68..+150, Z = +44..+120): ธนาคารกรุงเทพ สาขา มจพ. (พร้อมตู้ ATM/CDM, เคาน์เตอร์ธนาคาร, เก้าอี้รับรอง)
    --      - ขวาบน (หลังตึกฝั่งขวา X = +68..+150, Z = -120..-44): คาเฟ่ (Campus Cafe พร้อมเคาน์เตอร์กาแฟและชุดโต๊ะนั่ง)
    --      - ซ้ายล่าง & ซ้ายบน (X = -150..-68, Z = ±44..±120): ห้องศูนย์บริการนักศึกษา / ห้องสำนักงาน (ปิดล็อก)
    ------------------------------------------------------------------
    local function buildATMBooth(parent, name, ax, az, floorY, faceSignZ)
        local atm = Instance.new("Model")
        atm.Name = name
        atm.Parent = parent

        local navyBlue = Color3.fromRGB(0, 48, 135)
        local orangeStripe = Color3.fromRGB(242, 105, 34)
        local bodySteel = Color3.fromRGB(190, 196, 204)

        PartBuilder.makePart(atm, "ATMBody", Vector3.new(3.8, 7.6, 1.4),
            CFrame.new(ax, floorY + 3.8, az + faceSignZ * 0.4), bodySteel, Enum.Material.Metal)
        PartBuilder.makePart(atm, "ATMHeader", Vector3.new(4.0, 1.6, 1.6),
            CFrame.new(ax, floorY + 8.2, az + faceSignZ * 0.45), navyBlue, Enum.Material.SmoothPlastic)
        PartBuilder.makePart(atm, "ATMOrangeBand", Vector3.new(4.02, 0.3, 1.62),
            CFrame.new(ax, floorY + 7.3, az + faceSignZ * 0.45), orangeStripe, Enum.Material.Neon)
        PartBuilder.makePart(atm, "ATMScreen", Vector3.new(2.2, 1.6, 0.2),
            CFrame.new(ax, floorY + 4.8, az + faceSignZ * 1.05), Color3.fromRGB(85, 205, 255), Enum.Material.Neon)
        PartBuilder.makePart(atm, "ATMKeypad", Vector3.new(1.8, 0.3, 0.8),
            CFrame.new(ax, floorY + 3.5, az + faceSignZ * 1.15), Color3.fromRGB(50, 55, 62), Enum.Material.Metal)
        PartBuilder.makeSign(atm, "ATMSign", "ATM / CDM 24 Hrs.\nบัวหลวง เอทีเอ็ม", Vector3.new(3.8, 1.3, 0.12),
            Vector3.new(ax, floorY + 8.2, az + faceSignZ * 1.28),
            faceSignZ > 0 and Enum.NormalId.Back or Enum.NormalId.Front,
            navyBlue, Color3.fromRGB(255, 255, 255))
    end

    local function buildBankRoomF1()
        local model = Instance.new("Model")
        model.Name = "Room_Bank_BottomRight"
        model.Parent = floor1

        local posX, posZ = 109, 82
        local sizeX, sizeZ = 82, 76 -- X = 68..150, Z = 44..120
        local bankBlue = Color3.fromRGB(0, 48, 135)
        local bankOrange = Color3.fromRGB(242, 105, 34)
        local frameMetal = Color3.fromRGB(45, 50, 58)
        local glassBlue = Color3.fromRGB(165, 210, 235)

        -- พื้นหินแกรนิตภายในธนาคาร (เรียบเสมอพื้นชั้น 1)
        PartBuilder.makePart(model, "BankMarbleFloor", Vector3.new(sizeX - 2, 0.01, sizeZ - 2),
            CFrame.new(posX, floorY + 0.005, posZ), Color3.fromRGB(238, 236, 230), Enum.Material.Marble, { CanCollide = false })

        -- ผนังทึบด้านซ้าย (ติดลิฟต์ X = 69) และด้านขวาสุดของตึก (X = 149)
        PartBuilder.makePart(model, "Wall_West_LiftSide", Vector3.new(wallThick, wallH, sizeZ),
            CFrame.new(posX - sizeX / 2 + wallThick / 2, floorY + wallH / 2, posZ), wallColor, wallMaterial)
        PartBuilder.makePart(model, "Wall_East_Outer", Vector3.new(wallThick, wallH, sizeZ),
            CFrame.new(posX + sizeX / 2 - wallThick / 2, floorY + wallH / 2, posZ), wallColor, wallMaterial)

        -- สร้างหน้าร้านธนาคารทั้ง 2 ด้าน: ด้านหน้าตึก (Z = +120 ข้างบันไดใหญ่) และด้านในลานจอดรถ (Z = +44)
        local facades = {
            { tag = "FrontOuter_Z120", zWall = 120 - wallThick / 2, zFace = 120, dirZ =  1, signFace = Enum.NormalId.Back },
            { tag = "ParkingInner_Z44", zWall = 44 + wallThick / 2, zFace =  44, dirZ = -1, signFace = Enum.NormalId.Front },
        }

        for _, f in ipairs(facades) do
            -- ผนังฐานหินแกรนิตด้านล่าง (สูง 3.2 studs) + ผนังคานป้ายด้านบน (Y = 14.5..22)
            PartBuilder.makePart(model, "BaseLowWall_" .. f.tag, Vector3.new(54, 3.2, wallThick),
                CFrame.new(95, floorY + 1.6, f.zWall), Color3.fromRGB(52, 56, 64), Enum.Material.Granite)
            PartBuilder.makePart(model, "UpperHeaderWall_" .. f.tag, Vector3.new(sizeX, 7.5, wallThick),
                CFrame.new(posX, floorY + wallH - 3.75, f.zWall), wallColor, wallMaterial)

            -- โซนผนังฝั่งขวาสำหรับติดตั้งตู้ ATM/CDM 3 ตู้ (X = 122..150)
            PartBuilder.makePart(model, "ATMBayWall_" .. f.tag, Vector3.new(28, 14.5, wallThick),
                CFrame.new(136, floorY + 7.25, f.zWall), Color3.fromRGB(228, 232, 238), Enum.Material.Concrete)

            -- กระจกหน้าร้านธนาคาร (X = 68..122, Y = 3.2..14.5) พร้อมเสากรอบอลูมิเนียมและแถบฝ้าบังสายตา
            PartBuilder.makePart(model, "BankGlassCurtain_" .. f.tag, Vector3.new(54, 11.3, 0.5),
                CFrame.new(95, floorY + 3.2 + 5.65, f.zWall), glassBlue, Enum.Material.Glass, { Transparency = 0.42 })
            PartBuilder.makePart(model, "FrostedPrivacyBand_" .. f.tag, Vector3.new(54.2, 2.2, 0.55),
                CFrame.new(95, floorY + 6.8, f.zWall), Color3.fromRGB(240, 245, 250), Enum.Material.SmoothPlastic, { Transparency = 0.2 })

            for mx = 70, 120, 12.5 do
                PartBuilder.makePart(model, "Mullion_" .. f.tag .. "_" .. mx, Vector3.new(0.45, 11.5, 0.8),
                    CFrame.new(mx, floorY + 3.2 + 5.75, f.zWall), frameMetal, Enum.Material.Metal)
            end

            -- ประตูบานเลื่อนกระจกคู่หน้าธนาคาร (ปิดล็อก) ที่ X = 95
            PartBuilder.makePart(model, "SlidingDoorFrame_" .. f.tag, Vector3.new(10.6, 11.0, 0.9),
                CFrame.new(95, floorY + 5.5, f.zWall), frameMetal, Enum.Material.Metal)
            PartBuilder.makePart(model, "SlidingDoorGlassL_" .. f.tag, Vector3.new(4.8, 10.4, 0.65),
                CFrame.new(92.5, floorY + 5.3, f.zWall), glassBlue, Enum.Material.Glass, { Transparency = 0.3 })
            PartBuilder.makePart(model, "SlidingDoorGlassR_" .. f.tag, Vector3.new(4.8, 10.4, 0.65),
                CFrame.new(97.5, floorY + 5.3, f.zWall), glassBlue, Enum.Material.Glass, { Transparency = 0.3 })
            PartBuilder.makePart(model, "DoorCenterSeam_" .. f.tag, Vector3.new(0.2, 10.4, 0.75),
                CFrame.new(95, floorY + 5.3, f.zWall), frameMetal, Enum.Material.Metal)

            -- ป้ายชื่อธนาคารกรุงเทพขนาดใหญ่เต็มหน้าห้อง + แถบสีส้มเอกลักษณ์
            PartBuilder.makeSign(model, "BangkokBankSign_" .. f.tag,
                "🏦 ธนาคารกรุงเทพ สาขา มจพ. (อาคาร 40 ปี)\nBANGKOK BANK — KMUTNB BRANCH",
                Vector3.new(78, 5.2, 0.35),
                Vector3.new(posX, floorY + 18.2, f.zFace + f.dirZ * 0.2),
                f.signFace, bankBlue, Color3.fromRGB(255, 255, 255))
            PartBuilder.makePart(model, "BankOrangeAccent_" .. f.tag, Vector3.new(78, 0.65, 0.45),
                CFrame.new(posX, floorY + 15.2, f.zFace + f.dirZ * 0.22), bankOrange, Enum.Material.Neon)

            -- ตู้ ATM & CDM 3 ตู้เรียงหน้าห้องธนาคาร
            for idx, ax in ipairs({ 126, 135, 144 }) do
                buildATMBooth(model, string.format("ATM_%s_%d", f.tag, idx), ax, f.zFace, floorY, f.dirZ)
            end
        end

        -- ตกแต่งภายในห้องธนาคาร (มองเห็นผ่านกระจกหน้าร้านได้ชัดเจน):
        -- 1) เคาน์เตอร์พนักงานธนาคาร 5 ช่องบริการ (Teller Counter)
        PartBuilder.makePart(model, "TellerCounterBase", Vector3.new(46, 3.8, 3.6),
            CFrame.new(98, floorY + 1.9, 82), bankBlue, Enum.Material.SmoothPlastic)
        PartBuilder.makePart(model, "TellerCounterTop", Vector3.new(46.6, 0.4, 4.2),
            CFrame.new(98, floorY + 3.9, 82), Color3.fromRGB(235, 230, 220), Enum.Material.Marble)
        PartBuilder.makePart(model, "TellerGlassScreen", Vector3.new(44, 4.2, 0.25),
            CFrame.new(98, floorY + 6.2, 82), glassBlue, Enum.Material.Glass, { Transparency = 0.45 })
        PartBuilder.makeSign(model, "InteriorBackdropSign",
            "ธนาคารกรุงเทพ จำกัด (มหาชน) — สาขา มจพ.\nBANGKOK BANK PUBLIC COMPANY LIMITED",
            Vector3.new(42, 4.5, 0.25), Vector3.new(98, floorY + 13.5, 82),
            Enum.NormalId.Back, bankBlue, Color3.fromRGB(255, 255, 255))

        -- 2) เก้าอี้รับรองลูกค้าทั้งฝั่งหน้าตึกและฝั่งลานจอดรถ + ตู้กดบัตรคิว
        for _, rowZ in ipairs({ 62, 102 }) do
            for _, cx in ipairs({ 84, 98, 112 }) do
                PartBuilder.makePart(model, "WaitingBenchSeat_" .. rowZ .. "_" .. cx, Vector3.new(9.5, 0.4, 2.2),
                    CFrame.new(cx, floorY + 1.8, rowZ), bankBlue, Enum.Material.SmoothPlastic)
                PartBuilder.makePart(model, "WaitingBenchBack_" .. rowZ .. "_" .. cx, Vector3.new(9.5, 1.6, 0.35),
                    CFrame.new(cx, floorY + 2.8, rowZ + (rowZ > 82 and 0.9 or -0.9)), bankBlue, Enum.Material.SmoothPlastic)
            end
        end
        PartBuilder.makePart(model, "QueueKiosk", Vector3.new(1.8, 4.8, 1.6),
            CFrame.new(76, floorY + 2.4, 98), frameMetal, Enum.Material.Metal)

        -- 3) ไฟเพดานภายในธนาคารให้สว่างเห็นเคาน์เตอร์ชัดเจน
        for _, lx in ipairs({ 88, 118 }) do
            for _, lz in ipairs({ 64, 100 }) do
                PartBuilder.addPointLight(model, string.format("BankLight_%d_%d", lx, lz),
                    Vector3.new(lx, floorY + wallH - 2.0, lz), Color3.fromRGB(255, 250, 240), 42, 1.3)
            end
        end
    end

    local function buildStorefrontRoomF1(roomName, posX, posZ, sizeX, sizeZ, signText, signColor, accentColor)
        local model = Instance.new("Model")
        model.Name = roomName
        model.Parent = floor1

        local frameMetal = Color3.fromRGB(48, 52, 58)
        local glassTint = Color3.fromRGB(170, 210, 230)

        PartBuilder.makePart(model, "Wall_West", Vector3.new(wallThick, wallH, sizeZ),
            CFrame.new(posX - sizeX / 2 + wallThick / 2, floorY + wallH / 2, posZ), wallColor, wallMaterial)
        PartBuilder.makePart(model, "Wall_East", Vector3.new(wallThick, wallH, sizeZ),
            CFrame.new(posX + sizeX / 2 - wallThick / 2, floorY + wallH / 2, posZ), wallColor, wallMaterial)

        -- สร้างหน้าร้านทั้งฝั่งนอกตึก (Z = ±120) และฝั่งในลานจอดรถ (Z = ±44)
        local zNorth = posZ - sizeZ / 2 + wallThick / 2
        local zSouth = posZ + sizeZ / 2 - wallThick / 2
        local faces = {
            { tag = "North", zw = zNorth, zSign = posZ - sizeZ / 2 - 0.2, face = Enum.NormalId.Front },
            { tag = "South", zw = zSouth, zSign = posZ + sizeZ / 2 + 0.2, face = Enum.NormalId.Back },
        }
        for _, f in ipairs(faces) do
            PartBuilder.makePart(model, "LowWall_" .. f.tag, Vector3.new(sizeX, 3.5, wallThick),
                CFrame.new(posX, floorY + 1.75, f.zw), Color3.fromRGB(58, 62, 70), Enum.Material.Granite)
            PartBuilder.makePart(model, "HeaderWall_" .. f.tag, Vector3.new(sizeX, 7.5, wallThick),
                CFrame.new(posX, floorY + wallH - 3.75, f.zw), wallColor, wallMaterial)
            PartBuilder.makePart(model, "StoreGlass_" .. f.tag, Vector3.new(sizeX - 4, 11.0, 0.5),
                CFrame.new(posX, floorY + 3.5 + 5.5, f.zw), glassTint, Enum.Material.Glass, { Transparency = 0.45 })
            PartBuilder.makePart(model, "DoorFrame_" .. f.tag, Vector3.new(9.6, 10.8, 0.85),
                CFrame.new(posX, floorY + 5.4, f.zw), frameMetal, Enum.Material.Metal)

            PartBuilder.makeSign(model, "Sign_" .. f.tag, signText, Vector3.new(sizeX - 6, 4.8, 0.3),
                Vector3.new(posX, floorY + 18.2, f.zSign), f.face, signColor, Color3.fromRGB(255, 255, 255))
            PartBuilder.makePart(model, "AccentStripe_" .. f.tag, Vector3.new(sizeX - 6, 0.55, 0.38),
                CFrame.new(posX, floorY + 15.4, f.zSign), accentColor, Enum.Material.Neon)
        end
        return model
    end

    buildStorefrontRoomF1("Room_TopLeft",        -109, -82, 82, 76,
        "ศูนย์บริการนักศึกษา (ห้อง 101)\nSTUDENT SERVICE CENTER (CLOSED)",
        Color3.fromRGB(55, 65, 78), Color3.fromRGB(138, 30, 42))
    buildStorefrontRoomF1("Room_Cafe_TopRight",   109, -82, 82, 76,
        "☕ คาเฟ่ อาคาร 40 ปี มจพ.\nCAMPUS COFFEE & BAKERY (CLOSED)",
        Color3.fromRGB(110, 65, 35), Color3.fromRGB(235, 165, 55))
    buildStorefrontRoomF1("Room_BottomLeft",     -109,  82, 82, 76,
        "สำนักงานบริหารอาคาร 40 ปี (ห้อง 102)\nBUILDING ADMINISTRATION OFFICE (CLOSED)",
        Color3.fromRGB(55, 65, 78), Color3.fromRGB(138, 30, 42))
    buildBankRoomF1()

    ------------------------------------------------------------------
    -- 4. ฟังก์ชันสร้างบล็อกลิฟต์และบันไดในตัวอาคาร (ลึกเต็มแถบ Z = ±44..±120)
    --    ปล่องลิฟต์/บันไดอยู่ที่ Z = ±84..±120 (ตรงกับชั้น 2)
    --    และส่วนใน Z = ±44..±84 กั้นผนังเสมอแนวห้องมุมและทางเข้าออกกลาง
    ------------------------------------------------------------------
    local function buildInBuildingStair(folder, def)
        local coreModel = Instance.new("Model")
        coreModel.Name = def.name .. "_InBuilding"
        coreModel.Parent = folder

        local sz = def.centerZ > 0 and 1 or -1

        -- ปล่องบันได U (Z = ±86..±120) หันหน้าเข้าหาลิฟต์ฝั่งตรงข้ามทางเข้าออก
        StairBuilder.buildEnclosure(coreModel, def, floorY, wallH, 1)
        StairBuilder.buildUStair(coreModel, def, floorY, Layout.FLOOR_HEIGHT)

        local openX = def.centerX + def.entranceDir * (StairBuilder.HALF_X - 1)
        -- ผนังกั้นส่วนใน (Z = ±44..±86) ให้ขอบเสมอแนวลานจอดรถและทางเข้าออกกลาง
        local innerLen = core.innerZ - core.bandInnerZ
        local innerMidZ = sz * ((core.innerZ + core.bandInnerZ) / 2)
        PartBuilder.makePart(coreModel, "InnerWall_Hall", Vector3.new(wallThick, wallH, innerLen),
            CFrame.new(openX, floorY + wallH/2, innerMidZ), wallColor, wallMaterial)
        PartBuilder.makePart(coreModel, "InnerWall_Parking", Vector3.new(core.sideWidth, wallH, wallThick),
            CFrame.new(def.centerX, floorY + wallH/2, sz * (core.bandInnerZ + wallThick/2)), wallColor, wallMaterial)
        PartBuilder.makeSign(coreModel, "Sign_ParkingSide", "บันได\nSTAIRS",
            Vector3.new(16, 4.0, 0.15),
            Vector3.new(def.centerX, floorY + wallH/2, sz * (core.bandInnerZ - 0.1)),
            sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
            Color3.fromRGB(20, 120, 50), Color3.fromRGB(255, 255, 255))
    end

    local function buildInBuildingLift(folder, def)
        ElevatorBuilder.build(folder, def, 1, floorY, wallH, true)
    end

    ------------------------------------------------------------------
    -- 5. แถบบน (หลังตึก Z = -120..-44): ลิฟ (ซ้าย) | ทางเข้าออก (กลาง) | บันได (ขวา)
    ------------------------------------------------------------------
    local topCore = Instance.new("Folder")
    topCore.Name = "TopCirculationCore"
    topCore.Parent = floor1

    buildInBuildingLift(topCore, Layout.LIFTS.Rear)
    buildInBuildingStair(topCore, Layout.STAIRS.Rear)

    local topEntrance = Instance.new("Model")
    topEntrance.Name = "TopEntrance_Center_Open"
    topEntrance.Parent = topCore
    PartBuilder.makeSign(topEntrance, "Sign", "ทางเข้าออก\nENTRANCE / EXIT",
        Vector3.new(22, 0.02, 4.0), Vector3.new(0, floorY + 0.015, -82), Enum.NormalId.Top,
        Color3.fromRGB(120, 30, 40), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 6. แถบล่าง (หน้าตึก Z = +44..+120): บันได (ซ้าย) | ทางเข้าออก (กลาง) | ลิฟ (ขวา)
    ------------------------------------------------------------------
    local bottomCore = Instance.new("Folder")
    bottomCore.Name = "BottomCirculationCore"
    bottomCore.Parent = floor1

    buildInBuildingStair(bottomCore, Layout.STAIRS.Front)
    buildInBuildingLift(bottomCore, Layout.LIFTS.Front)

    local botEntrance = Instance.new("Model")
    botEntrance.Name = "BottomEntrance_Center_Open"
    botEntrance.Parent = bottomCore
    PartBuilder.makeSign(botEntrance, "Sign", "ทางเข้าออก\nENTRANCE / EXIT",
        Vector3.new(22, 0.02, 4.0), Vector3.new(0, floorY + 0.015, 82), Enum.NormalId.Top,
        Color3.fromRGB(120, 30, 40), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 7. กำแพงรอบนอกด้านซ้ายสุดของลานจอดรถ (X = -150, Z = -44..+44)
    ------------------------------------------------------------------
    PartBuilder.makePart(floor1, "OuterWall_West_2X", Vector3.new(wallThick, wallH, core.bandInnerZ * 2),
        CFrame.new(-body.halfX + wallThick/2, floorY + wallH/2, 0), wallColor, wallMaterial)

    ------------------------------------------------------------------
    -- 8. ไฟส่องสว่างชั้น 1
    ------------------------------------------------------------------
    local lights = Instance.new("Folder")
    lights.Name = "Lights_2X"
    lights.Parent = floor1

    local lightPoints = {
        Vector3.new(0, floorY + wallH - 2, 0),
        Vector3.new(-70, floorY + wallH - 2, 0),
        Vector3.new(70, floorY + wallH - 2, 0),
        Vector3.new(0, floorY + wallH - 2, -82),
        Vector3.new(0, floorY + wallH - 2,  82),
        Vector3.new(Layout.STAIRS.Rear.centerX,  floorY + wallH - 2, Layout.STAIRS.Rear.centerZ - 6),
        Vector3.new(Layout.STAIRS.Front.centerX, floorY + wallH - 2, Layout.STAIRS.Front.centerZ + 6),
    }
    for idx, pos in ipairs(lightPoints) do
        PartBuilder.addPointLight(lights, "Light_2X_" .. idx, pos, Color3.fromRGB(255, 250, 240), 55, 1.6)
    end

    ------------------------------------------------------------------
    -- 9. จุดเกิดผู้เล่น (Spawn Location)
    ------------------------------------------------------------------
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "PlayerSpawn_F1_2X"
    spawn.Size = Vector3.new(14, 0.5, 14)
    spawn.CFrame = CFrame.new(0, floorY + 0.3, 0)
    spawn.Color = Color3.fromRGB(0, 220, 255)
    spawn.Material = Enum.Material.Neon
    spawn.Transparency = 0.5
    spawn.Anchored = true
    spawn.CanCollide = false
    spawn.Parent = floor1

    print("🏢 [Floor 1] ลิฟต์และบันไดอยู่ในตัวอาคารเรียบร้อย (กรอบ 300x240 เดียว)")
end

return Floor1_Lobby
