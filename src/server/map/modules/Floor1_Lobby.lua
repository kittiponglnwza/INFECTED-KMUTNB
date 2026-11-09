--[[
    Floor1_Lobby.lua
    โครงสร้างชั้น 1 (Floor G) อาคาร 40 ปี มจพ.
    สร้างตรงตามภาพแปลนลายเส้นที่อัปเดตล่าสุด (media_1794242823441_57b638da.png)

    จุดสำคัญ:
      1. ลิฟต์และบันไดอยู่ในตัวอาคารทั้งหมด (กรอบสี่เหลี่ยมผืนผ้าเดียว 300 x 240 studs ไม่ยื่นออกนอกตึก)
      2. แถบบน (หลังตึก Z = -120..-44): [ห้อง] [ลิฟ] [ทางเข้าออก] [บันได] [คาเฟ่] เรียงแนวเดียวกัน
      3. แถบล่าง (หน้าตึก Z = +44..+120): [ห้อง] [บันได] [ทางเข้าออก] [ลิฟ] [ธนาคาร] เรียงแนวเดียวกัน
      4. ตรงกลาง (Z = -44..+44): ลานจอดรถแบบขับทะลุ (Drive-Through) เปิดโล่งทั้งฝั่งขวา (X = +150) และฝั่งซ้าย (X = -150)
         รถขับเข้าทางหนึ่งแล้วออกอีกทางหนึ่งได้ เชื่อมกับถนนรอบตึก (Building40_SiteGrounds.lua)
      5. ปิดตายทุกห้อง + บันไดหันหน้าเข้าหาลิฟต์ใกล้ๆ เริ่มขึ้นจากเลนซ้าย + ไม่มีขอบทางเข้าออก
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local CarBuilder = require(script.Parent.Parent.utils.CarBuilder)
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
    -- 1. พื้นฐานชั้น 1 (Main Ground Concrete Slab 300 x 240 studs — พื้นปูนเต็มพื้นที่)
    ------------------------------------------------------------------
    PartBuilder.makePart(
        floor1,
        "Floor1_BaseSlab_2X",
        Vector3.new(body.halfX * 2, 2.0, body.halfZ * 2),
        CFrame.new(0, floorY - 1.0, 0),
        Color3.fromRGB(218, 215, 208),
        Enum.Material.Concrete
    )

    ------------------------------------------------------------------
    -- 2. ลานจอดรถขับทะลุ (Drive-Through Parking ที่ Z = -44..+44, X = -150..+150)
    --    เปิดโล่งทั้งฝั่งขวา (X = +150) และฝั่งซ้าย (X = -150) — รถขับเข้าทางหนึ่ง ออกอีกทางหนึ่งได้
    --    ขับชิดซ้ายตามกฎจราจรไทย: เลนมุ่งหน้าฝั่งขวา (+X) อยู่ Z < 0, เลนมุ่งหน้าฝั่งซ้าย (-X) อยู่ Z > 0
    ------------------------------------------------------------------
    local parkingZone = Instance.new("Folder")
    parkingZone.Name = "DriveThroughParkingLot"
    parkingZone.Parent = floor1

    local asphaltCol = Color3.fromRGB(52, 54, 58)
    local paintWhite = Color3.fromRGB(240, 240, 240)
    local paintYellow = Color3.fromRGB(255, 205, 30)
    local hazardBlack = Color3.fromRGB(30, 30, 32)
    local laneHalf = 16 -- ช่องทางวิ่ง Z = -16..+16 (2 เลน เลนละ 16 studs)

    -- พื้นยางมะตอยทั้งลานจอดรถ (ยาวทะลุตลอดตัวตึก)
    PartBuilder.makePart(parkingZone, "ParkingAsphalt", Vector3.new(body.halfX * 2, 0.02, core.bandInnerZ * 2),
        CFrame.new(0, floorY + 0.01, 0), asphaltCol, Enum.Material.Asphalt, { CanCollide = false })

    -- เส้นแบ่งเลนกึ่งกลางสีเหลืองคู่ + เส้นขอบช่องทางวิ่งสีขาว
    for _, lz in ipairs({ -0.7, 0.7 }) do
        PartBuilder.makePart(parkingZone, "CenterYellowLine", Vector3.new(body.halfX * 2, 0.03, 0.45),
            CFrame.new(0, floorY + 0.025, lz), paintYellow, Enum.Material.SmoothPlastic, { CanCollide = false })
    end

    -- ช่องจอดรถทั้ง 2 ฝั่ง (กว้าง 12 studs ลึก 28 studs) + หมอนหยุดล้อ + เลขช่องจอด
    local stallW = 12
    local stallDepth = core.bandInnerZ - laneHalf -- 28
    for sx = -132, 132, stallW do
        if math.abs(sx) > 30 then
            for _, side in ipairs({ -1, 1 }) do
                PartBuilder.makePart(parkingZone, "StallStripe", Vector3.new(0.5, 0.03, stallDepth),
                    CFrame.new(sx, floorY + 0.025, side * (laneHalf + stallDepth / 2)), paintWhite, Enum.Material.SmoothPlastic, { CanCollide = false })
            end
        end
    end
    -- ทางม้าลายคนเดินกลางลานจอดรถ เชื่อมทางเข้าออกหน้าตึก-หลังตึก (X = -24..+24)
    for zx = -22, 22, 4 do
        PartBuilder.makePart(parkingZone, "ZebraCrossing", Vector3.new(2.0, 0.03, core.bandInnerZ * 2 - 2),
            CFrame.new(zx, floorY + 0.03, 0), paintWhite, Enum.Material.SmoothPlastic, { CanCollide = false })
    end
    local stallIdx = 0
    for cx = -126, 126, stallW do
        local nearPillar = math.abs(math.abs(cx) - 70) < 6
        local isWalkway = math.abs(cx) < 30
        for _, side in ipairs({ -1, 1 }) do
            if isWalkway then
                -- ช่วงทางม้าลาย ไม่มีช่องจอด
            elseif not nearPillar then
                stallIdx += 1
                PartBuilder.makePart(parkingZone, "WheelStop", Vector3.new(7.0, 0.6, 1.2),
                    CFrame.new(cx, floorY + 0.3, side * (core.bandInnerZ - 3.5)), paintYellow, Enum.Material.Concrete)
                PartBuilder.makeSign(parkingZone, "StallNumber",
                    string.format("%s%02d", side < 0 and "A" or "B", stallIdx),
                    Vector3.new(5.0, 0.02, 2.4), Vector3.new(cx, floorY + 0.03, side * (laneHalf + 3.0)),
                    Enum.NormalId.Top, asphaltCol, paintWhite)
            else
                -- ช่องข้างเสา: ตีเส้นทแยงห้ามจอด
                PartBuilder.makePart(parkingZone, "NoParkingHatch", Vector3.new(10, 0.03, 0.5),
                    CFrame.new(cx, floorY + 0.03, side * (laneHalf + stallDepth / 2)) * CFrame.Angles(0, math.rad(35), 0),
                    paintYellow, Enum.Material.SmoothPlastic, { CanCollide = false })
            end
        end
    end

    -- ลูกศรทิศทางการวิ่ง (ชิดซ้าย) และป้ายพื้น "ลานจอดรถ"
    for _, ax in ipairs({ -105, 50 }) do
        PartBuilder.makeSign(parkingZone, "LaneArrow_East", "→  ทางออก ฝั่งขวา (EXIT)  →",
            Vector3.new(22, 0.02, 4.5), Vector3.new(ax, floorY + 0.03, -8), Enum.NormalId.Top, asphaltCol, paintWhite)
        PartBuilder.makeSign(parkingZone, "LaneArrow_West", "←  ทางออก ฝั่งซ้าย (EXIT)  ←",
            Vector3.new(22, 0.02, 4.5), Vector3.new(-ax, floorY + 0.03, 8), Enum.NormalId.Top, asphaltCol, paintWhite)
    end

    -- เสาโครงสร้างลานจอดรถ 4 ต้น + แถบสะท้อนแสงเหลือง-ดำ
    for _, px in ipairs({ -70, 70 }) do
        for _, pz in ipairs({ -36, 36 }) do
            PartBuilder.makePart(parkingZone, "Pillar_2X", Vector3.new(6.0, wallH, 6.0),
                CFrame.new(px, floorY + wallH / 2, pz), Color3.fromRGB(212, 210, 205), Enum.Material.Concrete)
            for b = 0, 3 do
                PartBuilder.makePart(parkingZone, "PillarHazardBand", Vector3.new(6.3, 0.9, 6.3),
                    CFrame.new(px, floorY + 0.45 + b * 0.9, pz), (b % 2 == 0) and paintYellow or hazardBlack, Enum.Material.SmoothPlastic)
            end
        end
    end

    -- ทางเข้า-ออกทั้ง 2 ฝั่ง: คานบน (ความสูงลอดได้ 15 studs), ป้าย, ลูกระนาด, เกาะกลาง + ป้อมจ่ายบัตร + ไม้กั้นยกขึ้น
    local praduRed = Color3.fromRGB(138, 30, 42)
    local gateSides = {
        { tag = "East", dir =  1, face = Enum.NormalId.Right, faceIn = Enum.NormalId.Left,
          label = "ทางเข้า-ออก ลานจอดรถ (ฝั่งขวา)\nPARKING ENTRANCE / EXIT — EAST" },
        { tag = "West", dir = -1, face = Enum.NormalId.Left,  faceIn = Enum.NormalId.Right,
          label = "ทางเข้า-ออก ลานจอดรถ (ฝั่งซ้าย)\nPARKING ENTRANCE / EXIT — WEST" },
    }
    for _, g in ipairs(gateSides) do
        local edgeX = g.dir * (body.halfX - wallThick / 2) -- X = ±149
        local gm = Instance.new("Model")
        gm.Name = "ParkingGate_" .. g.tag
        gm.Parent = parkingZone

        -- คานบนเหนือช่องทางเข้า (Y = 16..23) แทนกำแพงเดิม
        PartBuilder.makePart(gm, "GateHeaderBeam", Vector3.new(wallThick, 7.0, core.bandInnerZ * 2),
            CFrame.new(edgeX, floorY + wallH - 3.5, 0), wallColor, wallMaterial)
        PartBuilder.makeSign(gm, "GateSign_Outer", g.label, Vector3.new(0.3, 4.4, 46),
            Vector3.new(edgeX + g.dir * 1.2, floorY + 18.6, 0), g.face, praduRed, Color3.fromRGB(255, 255, 255))
        PartBuilder.makeSign(gm, "GateSign_Inner", "ลานจอดรถ อาคาร 40 ปี — ขับช้า 10 กม./ชม.\nPARKING — SPEED LIMIT 10 KM/H",
            Vector3.new(0.3, 4.0, 42), Vector3.new(edgeX - g.dir * 1.2, floorY + 18.6, 0), g.faceIn, praduRed, Color3.fromRGB(255, 255, 255))
        PartBuilder.makeSign(gm, "ClearanceSign", "⚠ ความสูงไม่เกิน 2.1 ม. (MAX HEIGHT 2.1 m)",
            Vector3.new(0.3, 1.4, 22), Vector3.new(edgeX + g.dir * 1.2, floorY + 15.6, 0), g.face, paintYellow, hazardBlack)

        -- ลูกระนาดชะลอความเร็ว (Speed Bump) สลับเหลือง-ดำ
        for i = 0, 7 do
            local bz = -laneHalf + 2 + i * 4
            PartBuilder.makePart(gm, "SpeedBump", Vector3.new(1.6, 0.3, 4.0),
                CFrame.new(g.dir * 132, floorY + 0.15, bz), (i % 2 == 0) and paintYellow or hazardBlack, Enum.Material.SmoothPlastic)
        end

        -- เกาะกลางเล็ก + ป้อมจ่ายบัตรจอดรถ + ไม้กั้นยกขึ้น (เปิดให้รถผ่านได้)
        local islandX = g.dir * 140
        PartBuilder.makePart(gm, "MedianIsland", Vector3.new(12, 0.5, 3.0),
            CFrame.new(islandX, floorY + 0.25, 0), Color3.fromRGB(200, 198, 192), Enum.Material.Concrete)
        PartBuilder.makePart(gm, "TicketBooth", Vector3.new(4.0, 7.5, 2.6),
            CFrame.new(islandX + g.dir * 3, floorY + 0.5 + 3.75, 0), Color3.fromRGB(235, 235, 238), Enum.Material.SmoothPlastic)
        PartBuilder.makePart(gm, "TicketBoothWindow", Vector3.new(3.0, 2.4, 2.7),
            CFrame.new(islandX + g.dir * 3, floorY + 5.4, 0), Color3.fromRGB(150, 200, 225), Enum.Material.Glass, { Transparency = 0.3 })
        PartBuilder.makePart(gm, "TicketBoothRoof", Vector3.new(5.0, 0.5, 3.4),
            CFrame.new(islandX + g.dir * 3, floorY + 8.5, 0), praduRed, Enum.Material.SmoothPlastic)
        for _, side in ipairs({ -1, 1 }) do
            PartBuilder.makePart(gm, "BarrierPost", Vector3.new(1.2, 3.5, 1.2),
                CFrame.new(islandX - g.dir * 3, floorY + 0.5 + 1.75, side * 1.0), Color3.fromRGB(240, 180, 20), Enum.Material.Metal)
            -- ไม้กั้นยกขึ้นตั้งตรง (เปิดอยู่)
            PartBuilder.makePart(gm, "BarrierArm_Raised", Vector3.new(0.4, 12, 0.4),
                CFrame.new(islandX - g.dir * 3, floorY + 4.0 + 6, side * 1.0), (side < 0) and praduRed or paintWhite, Enum.Material.SmoothPlastic)
        end
    end

    -- ไฟส่องสว่างลานจอดรถ
    for _, lx in ipairs({ -110, -40, 40, 110 }) do
        for _, lz in ipairs({ -26, 26 }) do
            PartBuilder.addPointLight(parkingZone, string.format("ParkingLight_%d_%d", lx, lz),
                Vector3.new(lx, floorY + wallH - 1.0, lz), Color3.fromRGB(245, 250, 255), 40, 1.0)
        end
    end

    -- รถจอดอยู่ในลานจอดรถ (ตกแต่ง)
    local parkedNorth = { -114, -42, 54, 102 }
    local parkedSouth = { -90, -54, 42, 126 }
    for i, cx in ipairs(parkedNorth) do
        CarBuilder.buildParkedCar(parkingZone, "ParkedCar_A_" .. i, cx, floorY, -(core.bandInnerZ - 13), 0,
            CarBuilder.CAR_COLORS[(i - 1) % #CarBuilder.CAR_COLORS + 1])
    end
    for i, cx in ipairs(parkedSouth) do
        CarBuilder.buildParkedCar(parkingZone, "ParkedCar_B_" .. i, cx, floorY, (core.bandInnerZ - 13), 180,
            CarBuilder.CAR_COLORS[(i + 2) % #CarBuilder.CAR_COLORS + 1])
    end

    ------------------------------------------------------------------
    -- 3. ห้องมุมทั้ง 4 ของชั้น 1 (X = ±68..±150, Z = ±44..±120, ขนาด 82 x 76 studs)
    --    - ขวาล่าง (X = +68..+150, Z = +44..+120): ธนาคารกรุงเทพ สาขา มจพ. (หน้าร้านและประตูทางเข้าอยู่ด้านหน้าตึก Z=+120 และด้านขวาของอาคาร X=+150, ผนังด้านใน Z=+44 ทึบ)
    --    - ขวาบน (X = +68..+150, Z = -120..-44): คาเฟ่เปิดโล่ง (เอากำแพงออกทั้งหมด + ตกแต่งเคาน์เตอร์กาแฟ ตู้เค้ก ป้ายเมนู และชุดโต๊ะนั่งครบชุด)
    --    - ซ้ายล่าง & ซ้ายบน (X = -150..-68, Z = ±44..±120): ห้องศูนย์บริการนักศึกษา / สำนักงาน (ผนังด้านใน Z=±44 เป็นผนังปูนทึบ)
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

        -- ผนังทึบด้านซ้าย (ติดลิฟต์ X = 69) และผนังทึบด้านในโถงกลาง (Z = 45 — ไม่ทำหน้าร้านฝั่งที่จอดรถเดิม)
        PartBuilder.makePart(model, "Wall_West_LiftSide", Vector3.new(wallThick, wallH, sizeZ),
            CFrame.new(posX - sizeX / 2 + wallThick / 2, floorY + wallH / 2, posZ), wallColor, wallMaterial)
        PartBuilder.makePart(model, "Wall_North_InnerSolid", Vector3.new(sizeX, wallH, wallThick),
            CFrame.new(posX, floorY + wallH / 2, 44 + wallThick / 2), wallColor, wallMaterial)

        -- 1) หน้าร้านธนาคารด้านหน้าตึก (Z = +120)
        local zWallFront = 120 - wallThick / 2
        PartBuilder.makePart(model, "BaseLowWall_Front", Vector3.new(54, 3.2, wallThick),
            CFrame.new(95, floorY + 1.6, zWallFront), Color3.fromRGB(52, 56, 64), Enum.Material.Granite)
        PartBuilder.makePart(model, "UpperHeaderWall_Front", Vector3.new(sizeX, 7.5, wallThick),
            CFrame.new(posX, floorY + wallH - 3.75, zWallFront), wallColor, wallMaterial)
        PartBuilder.makePart(model, "ATMBayWall_Front", Vector3.new(28, 14.5, wallThick),
            CFrame.new(136, floorY + 7.25, zWallFront), Color3.fromRGB(228, 232, 238), Enum.Material.Concrete)
        PartBuilder.makePart(model, "BankGlassCurtain_Front", Vector3.new(54, 11.3, 0.5),
            CFrame.new(95, floorY + 3.2 + 5.65, zWallFront), glassBlue, Enum.Material.Glass, { Transparency = 0.42 })
        PartBuilder.makePart(model, "FrostedPrivacyBand_Front", Vector3.new(54.2, 2.2, 0.55),
            CFrame.new(95, floorY + 6.8, zWallFront), Color3.fromRGB(240, 245, 250), Enum.Material.SmoothPlastic, { Transparency = 0.2 })
        for mx = 70, 120, 12.5 do
            PartBuilder.makePart(model, "Mullion_Front_" .. mx, Vector3.new(0.45, 11.5, 0.8),
                CFrame.new(mx, floorY + 3.2 + 5.75, zWallFront), frameMetal, Enum.Material.Metal)
        end
        PartBuilder.makePart(model, "SlidingDoorFrame_Front", Vector3.new(10.6, 11.0, 0.9),
            CFrame.new(95, floorY + 5.5, zWallFront), frameMetal, Enum.Material.Metal)
        PartBuilder.makePart(model, "SlidingDoorGlassL_Front", Vector3.new(4.8, 10.4, 0.65),
            CFrame.new(92.5, floorY + 5.3, zWallFront), glassBlue, Enum.Material.Glass, { Transparency = 0.3 })
        PartBuilder.makePart(model, "SlidingDoorGlassR_Front", Vector3.new(4.8, 10.4, 0.65),
            CFrame.new(97.5, floorY + 5.3, zWallFront), glassBlue, Enum.Material.Glass, { Transparency = 0.3 })
        PartBuilder.makeSign(model, "BangkokBankSign_Front",
            "🏦 ธนาคารกรุงเทพ สาขา มจพ. (อาคาร 40 ปี)\nBANGKOK BANK — KMUTNB BRANCH",
            Vector3.new(78, 5.2, 0.35),
            Vector3.new(posX, floorY + 18.2, 120.2),
            Enum.NormalId.Back, bankBlue, Color3.fromRGB(255, 255, 255))
        PartBuilder.makePart(model, "BankOrangeAccent_Front", Vector3.new(78, 0.65, 0.45),
            CFrame.new(posX, floorY + 15.2, 120.22), bankOrange, Enum.Material.Neon)
        for idx, ax in ipairs({ 126, 135, 144 }) do
            buildATMBooth(model, "ATM_Front_" .. idx, ax, 120, floorY, 1)
        end

        -- 2) หน้าร้านและประตูทางเข้าธนาคาร ด้านขวาของอาคาร (X = +150, Z = 44..120)
        local xWallEast = 150 - wallThick / 2
        PartBuilder.makePart(model, "UpperHeaderWall_East", Vector3.new(wallThick, 7.5, sizeZ),
            CFrame.new(xWallEast, floorY + wallH - 3.75, posZ), wallColor, wallMaterial)
        -- ผนังฐานและกระจกขนาบข้างประตูทางเข้าด้านขวาของธนาคาร (เว้นช่องประตูเดินเข้า-ออกที่ Z = 76..88)
        for _, seg in ipairs({ { zc = 60, len = 32 }, { zc = 104, len = 32 } }) do
            PartBuilder.makePart(model, "BaseLowWall_East_" .. seg.zc, Vector3.new(wallThick, 3.2, seg.len),
                CFrame.new(xWallEast, floorY + 1.6, seg.zc), Color3.fromRGB(52, 56, 64), Enum.Material.Granite)
            PartBuilder.makePart(model, "BankGlass_East_" .. seg.zc, Vector3.new(0.5, 11.3, seg.len - 1),
                CFrame.new(xWallEast, floorY + 3.2 + 5.65, seg.zc), glassBlue, Enum.Material.Glass, { Transparency = 0.42 })
            PartBuilder.makePart(model, "FrostedBand_East_" .. seg.zc, Vector3.new(0.55, 2.2, seg.len - 1),
                CFrame.new(xWallEast, floorY + 6.8, seg.zc), Color3.fromRGB(240, 245, 250), Enum.Material.SmoothPlastic, { Transparency = 0.2 })
        end
        -- ซุ้มประตูทางเข้าธนาคารด้านขวา (Z = 76..88, เปิดให้เดินเข้าธนาคารได้จริง)
        PartBuilder.makePart(model, "EastBankDoorJamb_L", Vector3.new(1.4, 14.5, 1.2),
            CFrame.new(xWallEast, floorY + 7.25, 75.5), frameMetal, Enum.Material.Metal)
        PartBuilder.makePart(model, "EastBankDoorJamb_R", Vector3.new(1.4, 14.5, 1.2),
            CFrame.new(xWallEast, floorY + 7.25, 88.5), frameMetal, Enum.Material.Metal)
        PartBuilder.makePart(model, "EastBankDoorHeader", Vector3.new(1.6, 1.2, 14.2),
            CFrame.new(xWallEast, floorY + 14.2, 82), frameMetal, Enum.Material.Metal)
        PartBuilder.makePart(model, "EastBankOpenLeaf_L", Vector3.new(0.5, 13.0, 3.2),
            CFrame.new(xWallEast, floorY + 6.5, 77.6), glassBlue, Enum.Material.Glass, { Transparency = 0.3 })
        PartBuilder.makePart(model, "EastBankOpenLeaf_R", Vector3.new(0.5, 13.0, 3.2),
            CFrame.new(xWallEast, floorY + 6.5, 86.4), glassBlue, Enum.Material.Glass, { Transparency = 0.3 })

        PartBuilder.makeSign(model, "BangkokBankSign_EastRight",
            "🏦 ธนาคารกรุงเทพ สาขา มจพ. (ทางเข้าด้านขวา)\nBANGKOK BANK — EAST ENTRANCE",
            Vector3.new(0.35, 5.2, 72),
            Vector3.new(150.2, floorY + 18.2, posZ),
            Enum.NormalId.Right, bankBlue, Color3.fromRGB(255, 255, 255))
        PartBuilder.makePart(model, "BankOrangeAccent_EastRight", Vector3.new(0.45, 0.65, 72),
            CFrame.new(150.22, floorY + 15.2, posZ), bankOrange, Enum.Material.Neon)

        -- ตกแต่งภายในห้องธนาคาร (มองเห็นและเดินเข้าทางประตูด้านขวาได้):
        -- 1) เคาน์เตอร์พนักงานธนาคาร 5 ช่องบริการ (Teller Counter)
        PartBuilder.makePart(model, "TellerCounterBase", Vector3.new(46, 3.8, 3.6),
            CFrame.new(98, floorY + 1.9, 68), bankBlue, Enum.Material.SmoothPlastic)
        PartBuilder.makePart(model, "TellerCounterTop", Vector3.new(46.6, 0.4, 4.2),
            CFrame.new(98, floorY + 3.9, 68), Color3.fromRGB(235, 230, 220), Enum.Material.Marble)
        PartBuilder.makePart(model, "TellerGlassScreen", Vector3.new(44, 4.2, 0.25),
            CFrame.new(98, floorY + 6.2, 68), glassBlue, Enum.Material.Glass, { Transparency = 0.45 })
        PartBuilder.makeSign(model, "InteriorBackdropSign",
            "ธนาคารกรุงเทพ จำกัด (มหาชน) — สาขา มจพ.\nBANGKOK BANK PUBLIC COMPANY LIMITED",
            Vector3.new(48, 4.8, 0.25), Vector3.new(98, floorY + 13.5, 45.4),
            Enum.NormalId.Back, bankBlue, Color3.fromRGB(255, 255, 255))

        -- 2) เก้าอี้รับรองลูกค้าและตู้กดบัตรคิว
        for _, rowZ in ipairs({ 86, 102 }) do
            for _, cx in ipairs({ 84, 98, 112 }) do
                PartBuilder.makePart(model, "WaitingBenchSeat_" .. rowZ .. "_" .. cx, Vector3.new(9.5, 0.4, 2.2),
                    CFrame.new(cx, floorY + 1.8, rowZ), bankBlue, Enum.Material.SmoothPlastic)
                PartBuilder.makePart(model, "WaitingBenchBack_" .. rowZ .. "_" .. cx, Vector3.new(9.5, 1.6, 0.35),
                    CFrame.new(cx, floorY + 2.8, rowZ + 0.9), bankBlue, Enum.Material.SmoothPlastic)
            end
        end
        PartBuilder.makePart(model, "QueueKiosk", Vector3.new(1.8, 4.8, 1.6),
            CFrame.new(132, floorY + 2.4, 74), frameMetal, Enum.Material.Metal)

        -- 3) ไฟเพดานภายในธนาคาร
        for _, lx in ipairs({ 88, 118 }) do
            for _, lz in ipairs({ 64, 100 }) do
                PartBuilder.addPointLight(model, string.format("BankLight_%d_%d", lx, lz),
                    Vector3.new(lx, floorY + wallH - 2.0, lz), Color3.fromRGB(255, 250, 240), 42, 1.3)
            end
        end
    end

    ------------------------------------------------------------------
    -- 3.2 คาเฟ่อาคาร 40 ปี (Open-Plan Campus Cafe ที่ X = +68..+150, Z = -120..-44)
    --     เอากำแพงออกทั้งหมด และตกแต่งเคาน์เตอร์กาแฟ ตู้เบเกอรี่ ป้ายเมนู โต๊ะเก้าอี้ และโคมไฟครบชุด
    ------------------------------------------------------------------
    local function buildOpenCafeF1()
        local cafe = Instance.new("Model")
        cafe.Name = "OpenCafe_TopRight"
        cafe.Parent = floor1

        local posX, posZ = 109, -82
        local sizeX, sizeZ = 82, 76 -- X = 68..150, Z = -120..-44
        local woodWarm = Color3.fromRGB(148, 98, 56)
        local woodDark = Color3.fromRGB(82, 52, 32)
        local marbleTop = Color3.fromRGB(242, 239, 232)
        local metalBlack = Color3.fromRGB(38, 42, 48)
        local chromeCol = Color3.fromRGB(215, 220, 228)
        local goldAccent = Color3.fromRGB(238, 175, 65)

        -- 1) พื้นไม้คาเฟ่แบบเปิดโล่ง (ไม่มีกำแพงกั้น เดินเข้า-ออกได้ทุกทิศทาง)
        PartBuilder.makePart(cafe, "CafeWoodFloor", Vector3.new(sizeX - 2, 0.04, sizeZ - 2),
            CFrame.new(posX, floorY + 0.02, posZ), Color3.fromRGB(162, 118, 78), Enum.Material.WoodPlanks, { CanCollide = false })

        -- 2) เคาน์เตอร์บาร์กาแฟทรงตัว L (L-Shaped Espresso & Bakery Counter)
        PartBuilder.makePart(cafe, "CounterMainBase", Vector3.new(42, 3.8, 4.2),
            CFrame.new(98, floorY + 1.9, -98), woodWarm, Enum.Material.Wood)
        PartBuilder.makePart(cafe, "CounterMainTop", Vector3.new(42.8, 0.45, 4.8),
            CFrame.new(98, floorY + 4.0, -98), marbleTop, Enum.Material.Marble)
        PartBuilder.makePart(cafe, "CounterFrontAccent", Vector3.new(42.2, 0.5, 0.2),
            CFrame.new(98, floorY + 3.4, -95.8), goldAccent, Enum.Material.Neon)

        PartBuilder.makePart(cafe, "CounterSideBase", Vector3.new(4.2, 3.8, 22),
            CFrame.new(79, floorY + 1.9, -87), woodWarm, Enum.Material.Wood)
        PartBuilder.makePart(cafe, "CounterSideTop", Vector3.new(4.8, 0.45, 22.6),
            CFrame.new(79, floorY + 4.0, -87), marbleTop, Enum.Material.Marble)

        -- 3) เครื่องชงกาแฟ Espresso Machine 2 หัว + เครื่องบดกาแฟ 2 เครื่อง + เครื่องคิดเงิน POS
        PartBuilder.makePart(cafe, "EspressoMachineBody", Vector3.new(4.6, 2.4, 2.4),
            CFrame.new(90, floorY + 5.4, -98), chromeCol, Enum.Material.Metal)
        PartBuilder.makePart(cafe, "EspressoMachineTop", Vector3.new(4.8, 0.3, 2.6),
            CFrame.new(90, floorY + 6.7, -98), metalBlack, Enum.Material.Metal)
        for _, gx in ipairs({ 84.5, 86.2 }) do
            PartBuilder.makePart(cafe, "CoffeeGrinderBase_" .. gx, Vector3.new(1.1, 1.8, 1.2),
                CFrame.new(gx, floorY + 5.1, -98), metalBlack, Enum.Material.Metal)
            PartBuilder.makeCylinder(cafe, "BeanHopper_" .. gx, Vector3.new(1.2, 1.0, 1.0),
                CFrame.new(gx, floorY + 6.5, -98) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(210, 180, 140), Enum.Material.Glass, { Transparency = 0.35 })
        end
        PartBuilder.makePart(cafe, "POSCashRegister", Vector3.new(2.0, 1.6, 1.4),
            CFrame.new(97, floorY + 5.0, -97.2), metalBlack, Enum.Material.Metal)

        -- 4) ตู้กระจกโชว์เค้กและเบเกอรี่ (Glass Bakery & Cake Showcase)
        PartBuilder.makePart(cafe, "CakeShowcaseBase", Vector3.new(12.0, 2.2, 4.0),
            CFrame.new(112, floorY + 5.1, -98), metalBlack, Enum.Material.Metal)
        PartBuilder.makePart(cafe, "CakeShowcaseGlass", Vector3.new(11.6, 2.8, 3.8),
            CFrame.new(112, floorY + 6.6, -98), Color3.fromRGB(210, 235, 245), Enum.Material.Glass, { Transparency = 0.45 })
        PartBuilder.makePart(cafe, "CakeShelfMiddle", Vector3.new(11.2, 0.15, 3.2),
            CFrame.new(112, floorY + 6.4, -98), chromeCol, Enum.Material.Metal)
        for idx, cx in ipairs({ 108, 111, 114, 116.5 }) do
            local cakeCol = (idx % 2 == 0) and Color3.fromRGB(245, 195, 205) or Color3.fromRGB(235, 185, 115)
            PartBuilder.makeCylinder(cafe, "CakeDisplay_" .. idx, Vector3.new(0.9, 1.8, 1.8),
                CFrame.new(cx, floorY + 6.95, -98) * CFrame.Angles(0, 0, math.rad(90)),
                cakeCol, Enum.Material.SmoothPlastic)
        end

        -- 5) เคาน์เตอร์เตรียมเครื่องดื่มด้านหลังและชั้นวางขวดโหลกาแฟ
        PartBuilder.makePart(cafe, "BackBarCounter", Vector3.new(38, 3.6, 3.0),
            CFrame.new(98, floorY + 1.8, -110), woodDark, Enum.Material.Wood)
        PartBuilder.makePart(cafe, "BackBarTop", Vector3.new(38.4, 0.35, 3.4),
            CFrame.new(98, floorY + 3.75, -110), chromeCol, Enum.Material.Metal)
        PartBuilder.makePart(cafe, "BackShelfFrame", Vector3.new(32, 7.5, 1.6),
            CFrame.new(98, floorY + 7.5, -110.5), metalBlack, Enum.Material.Metal)

        -- 6) ป้ายชื่อคาเฟ่และกระดานเมนูแขวนเพดาน (Hanging Ceiling Sign & Menu Boards)
        for _, rx in ipairs({ 82, 98, 114 }) do
            PartBuilder.makePart(cafe, "CeilingMenuRod_" .. rx, Vector3.new(0.4, 7.5, 0.4),
                CFrame.new(rx, floorY + wallH - 3.75, -98), metalBlack, Enum.Material.Metal)
        end
        PartBuilder.makeSign(cafe, "CafeMainHangingSign_Front",
            "☕ คาเฟ่อาคาร 40 ปี มจพ. — 40th AVENUE CAFE & BAKERY",
            Vector3.new(42, 3.6, 0.6),
            Vector3.new(98, floorY + 17.5, -98),
            Enum.NormalId.Back, woodDark, goldAccent)
        PartBuilder.makeSign(cafe, "CafeMainHangingSign_Rear",
            "☕ คาเฟ่อาคาร 40 ปี มจพ. — 40th AVENUE CAFE & BAKERY",
            Vector3.new(42, 3.6, 0.6),
            Vector3.new(98, floorY + 17.5, -98.7),
            Enum.NormalId.Front, woodDark, goldAccent)
        PartBuilder.makeSign(cafe, "CafeMenuBoard",
            "ESPRESSO / AMERICANO 45.-   |   LATTE / CAPPUCCINO / MOCHA 55.-\nMATCHA LATTE / THAI TEA 50.-   |   FRESH CROISSANT & HOMEMADE CAKE 65.-",
            Vector3.new(38, 2.8, 0.5),
            Vector3.new(98, floorY + 13.8, -98),
            Enum.NormalId.Back, metalBlack, Color3.fromRGB(255, 248, 230))

        -- 7) เก้าอี้บาร์หน้าเคาน์เตอร์ 5 ตัว (Bar Stools)
        for i = 1, 5 do
            local sx = 86 + (i - 1) * 5.5
            PartBuilder.makeCylinder(cafe, "BarStoolLeg_" .. i, Vector3.new(2.8, 0.4, 0.4),
                CFrame.new(sx, floorY + 1.4, -93) * CFrame.Angles(0, 0, math.rad(90)),
                metalBlack, Enum.Material.Metal)
            PartBuilder.makeCylinder(cafe, "BarStoolSeat_" .. i, Vector3.new(0.4, 2.2, 2.2),
                CFrame.new(sx, floorY + 2.9, -93) * CFrame.Angles(0, 0, math.rad(90)),
                woodDark, Enum.Material.SmoothPlastic)
        end

        -- 8) ชุดโต๊ะกลมคาเฟ่ 6 ชุด พร้อมเก้าอี้ 24 ตัว และแก้วกาแฟบนโต๊ะ
        local tableCoords = {
            { x =  92, z = -74 },
            { x = 116, z = -74 },
            { x = 138, z = -74 },
            { x =  92, z = -54 },
            { x = 116, z = -54 },
            { x = 138, z = -54 },
        }
        for idx, tc in ipairs(tableCoords) do
            PartBuilder.makeCylinder(cafe, "CafeTableBase_" .. idx, Vector3.new(0.25, 3.2, 3.2),
                CFrame.new(tc.x, floorY + 0.15, tc.z) * CFrame.Angles(0, 0, math.rad(90)),
                metalBlack, Enum.Material.Metal)
            PartBuilder.makeCylinder(cafe, "CafeTablePole_" .. idx, Vector3.new(2.8, 0.5, 0.5),
                CFrame.new(tc.x, floorY + 1.5, tc.z) * CFrame.Angles(0, 0, math.rad(90)),
                metalBlack, Enum.Material.Metal)
            PartBuilder.makeCylinder(cafe, "CafeTableTop_" .. idx, Vector3.new(0.35, 6.2, 6.2),
                CFrame.new(tc.x, floorY + 3.0, tc.z) * CFrame.Angles(0, 0, math.rad(90)),
                marbleTop, Enum.Material.Marble)
            PartBuilder.makeCylinder(cafe, "CoffeeCup_" .. idx, Vector3.new(0.7, 0.6, 0.6),
                CFrame.new(tc.x + 0.8, floorY + 3.5, tc.z - 0.5) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic)

            local chairOffsets = {
                { dx = -4.5, dz =  0,   rotY =  90 },
                { dx =  4.5, dz =  0,   rotY = -90 },
                { dx =  0,   dz = -4.5, rotY =   0 },
                { dx =  0,   dz =  4.5, rotY = 180 },
            }
            for cIdx, co in ipairs(chairOffsets) do
                local cx, cz = tc.x + co.dx, tc.z + co.dz
                local chairCF = CFrame.new(cx, floorY + 1.7, cz) * CFrame.Angles(0, math.rad(co.rotY), 0)
                PartBuilder.makePart(cafe, string.format("CafeChairSeat_%d_%d", idx, cIdx),
                    Vector3.new(2.2, 0.3, 2.2), chairCF, woodWarm, Enum.Material.Wood)
                PartBuilder.makePart(cafe, string.format("CafeChairLeg_%d_%d", idx, cIdx),
                    Vector3.new(1.8, 1.6, 1.8), chairCF * CFrame.new(0, -0.95, 0), metalBlack, Enum.Material.Metal)
                PartBuilder.makePart(cafe, string.format("CafeChairBack_%d_%d", idx, cIdx),
                    Vector3.new(2.2, 1.8, 0.3), chairCF * CFrame.new(0, 1.0, -0.95), woodDark, Enum.Material.Wood)
            end
        end

        -- 9) โซฟาพักผ่อนมุมคาเฟ่ (Lounge Sofa Corner) ที่ X = 136, Z = -102
        PartBuilder.makePart(cafe, "LoungeSofaSeat", Vector3.new(14, 1.4, 3.6),
            CFrame.new(136, floorY + 1.1, -104), woodDark, Enum.Material.SmoothPlastic)
        PartBuilder.makePart(cafe, "LoungeSofaBack", Vector3.new(14, 2.4, 0.8),
            CFrame.new(136, floorY + 2.6, -105.5), woodDark, Enum.Material.SmoothPlastic)
        PartBuilder.makePart(cafe, "LoungeLowTable", Vector3.new(8.0, 1.4, 3.6),
            CFrame.new(136, floorY + 0.9, -98), woodWarm, Enum.Material.Wood)

        -- 10) โคมไฟแขวนเพดานโทนอบอุ่นในคาเฟ่ (Warm Cafe Pendant Lights)
        for _, lx in ipairs({ 92, 116, 138 }) do
            for _, lz in ipairs({ -98, -74, -54 }) do
                PartBuilder.addPointLight(cafe, string.format("CafeWarmLight_%d_%d", lx, lz),
                    Vector3.new(lx, floorY + wallH - 2.0, lz), Color3.fromRGB(255, 228, 185), 42, 1.35)
            end
        end
    end

    ------------------------------------------------------------------
    -- 3.3 ห้องฝั่งซ้าย (Room_TopLeft & Room_BottomLeft): ผนังด้านใน Z = ±44 เป็นผนังปูนทึบ
    ------------------------------------------------------------------
    local function buildLeftClosedRoomF1(roomName, posX, posZ, sizeX, sizeZ, signText, signColor, accentColor)
        local model = Instance.new("Model")
        model.Name = roomName
        model.Parent = floor1

        local frameMetal = Color3.fromRGB(48, 52, 58)
        local glassTint = Color3.fromRGB(170, 210, 230)

        -- ผนังทึบด้านซ้ายสุด (X = -149), ด้านขวา (X = -69), และด้านในโถงกลาง (Z = ±45)
        PartBuilder.makePart(model, "Wall_West", Vector3.new(wallThick, wallH, sizeZ),
            CFrame.new(posX - sizeX / 2 + wallThick / 2, floorY + wallH / 2, posZ), wallColor, wallMaterial)
        PartBuilder.makePart(model, "Wall_East", Vector3.new(wallThick, wallH, sizeZ),
            CFrame.new(posX + sizeX / 2 - wallThick / 2, floorY + wallH / 2, posZ), wallColor, wallMaterial)

        local isNorthRoom = (posZ < 0)
        local zInnerSolid = isNorthRoom and (posZ + sizeZ / 2 - wallThick / 2) or (posZ - sizeZ / 2 + wallThick / 2)
        PartBuilder.makePart(model, "Wall_InnerConcreteSolid", Vector3.new(sizeX, wallH, wallThick),
            CFrame.new(posX, floorY + wallH / 2, zInnerSolid), wallColor, wallMaterial)

        -- หน้าร้านเฉพาะด้านนอกอาคาร (Z = ±120)
        local zwOuter = isNorthRoom and (posZ - sizeZ / 2 + wallThick / 2) or (posZ + sizeZ / 2 - wallThick / 2)
        local zSignOuter = isNorthRoom and (posZ - sizeZ / 2 - 0.2) or (posZ + sizeZ / 2 + 0.2)
        local outerFace = isNorthRoom and Enum.NormalId.Front or Enum.NormalId.Back

        PartBuilder.makePart(model, "LowWall_Outer", Vector3.new(sizeX, 3.5, wallThick),
            CFrame.new(posX, floorY + 1.75, zwOuter), Color3.fromRGB(58, 62, 70), Enum.Material.Granite)
        PartBuilder.makePart(model, "HeaderWall_Outer", Vector3.new(sizeX, 7.5, wallThick),
            CFrame.new(posX, floorY + wallH - 3.75, zwOuter), wallColor, wallMaterial)
        PartBuilder.makePart(model, "StoreGlass_Outer", Vector3.new(sizeX - 4, 11.0, 0.5),
            CFrame.new(posX, floorY + 3.5 + 5.5, zwOuter), glassTint, Enum.Material.Glass, { Transparency = 0.45 })
        PartBuilder.makePart(model, "DoorFrame_Outer", Vector3.new(9.6, 10.8, 0.85),
            CFrame.new(posX, floorY + 5.4, zwOuter), frameMetal, Enum.Material.Metal)

        PartBuilder.makeSign(model, "Sign_Outer", signText, Vector3.new(sizeX - 6, 4.8, 0.3),
            Vector3.new(posX, floorY + 18.2, zSignOuter), outerFace, signColor, Color3.fromRGB(255, 255, 255))
        PartBuilder.makePart(model, "AccentStripe_Outer", Vector3.new(sizeX - 6, 0.55, 0.38),
            CFrame.new(posX, floorY + 15.4, zSignOuter), accentColor, Enum.Material.Neon)
        return model
    end

    buildLeftClosedRoomF1("Room_TopLeft",    -109, -82, 82, 76,
        "ศูนย์บริการนักศึกษา (ห้อง 101)\nSTUDENT SERVICE CENTER (CLOSED)",
        Color3.fromRGB(55, 65, 78), Color3.fromRGB(138, 30, 42))
    buildLeftClosedRoomF1("Room_BottomLeft", -109,  82, 82, 76,
        "สำนักงานบริหารอาคาร 40 ปี (ห้อง 102)\nBUILDING ADMINISTRATION OFFICE (CLOSED)",
        Color3.fromRGB(55, 65, 78), Color3.fromRGB(138, 30, 42))
    buildOpenCafeF1()
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
    -- 7. ฝั่งซ้ายสุดของลานจอดรถ (X = -150, Z = -44..+44): ทุบกำแพงออกแล้ว
    --    เปิดเป็นทางเข้า-ออกรถฝั่งซ้าย (ParkingGate_West) ให้รถขับทะลุไปอีกฝั่งได้
    ------------------------------------------------------------------

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
