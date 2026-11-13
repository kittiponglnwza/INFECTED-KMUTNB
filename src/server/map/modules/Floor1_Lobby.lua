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
local InteractiveDoorBuilder = require(script.Parent.Parent.utils.InteractiveDoorBuilder)

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
    local room102WalkwayBuilt = false
    for cx = -126, 126, stallW do
        local nearPillar = math.abs(math.abs(cx) - 70) < 6
        local isWalkway = math.abs(cx) < 30
        for _, side in ipairs({ -1, 1 }) do
            local isRoom102Entrance = (side == 1 and math.abs(cx - (-109)) <= 7.5)
            if isWalkway then
                -- ช่วงทางม้าลาย ไม่มีช่องจอด
            elseif isRoom102Entrance then
                -- ช่องทางเดินเข้าสู่ห้องควบคุมความปลอดภัย (Room 102 North Doorway) ไม่วางที่กั้นล้อขวางทางเดิน (สร้างแผ่นพื้นทางเดินเพียงครั้งเดียว)
                if not room102WalkwayBuilt then
                    room102WalkwayBuilt = true
                    PartBuilder.makePart(parkingZone, "Room102_WalkwayPad", Vector3.new(9.5, 0.05, 6.0),
                        CFrame.new(-109, floorY + 0.03, side * (core.bandInnerZ - 3.0)), Color3.fromRGB(132, 138, 146), Enum.Material.Concrete, { CanCollide = false })
                end
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

        -- 1) หน้าร้านธนาคารด้านหน้าตึก (Z = +120) เว้นช่องประตูบานคู่เปิด-ปิดได้จริงที่ X = 90..100
        local zWallFront = 120 - wallThick / 2
        local marbleCream = Color3.fromRGB(238, 234, 224)
        local darkSlate = Color3.fromRGB(46, 52, 62)
        local warmWood = Color3.fromRGB(88, 56, 36)
        local darkWalnut = Color3.fromRGB(62, 38, 24)
        local brassGold = Color3.fromRGB(210, 172, 86)

        for _, fSeg in ipairs({ { xc = 79, len = 22 }, { xc = 111, len = 22 } }) do
            PartBuilder.makePart(model, "BaseLowWall_Front_" .. fSeg.xc, Vector3.new(fSeg.len, 3.2, wallThick),
                CFrame.new(fSeg.xc, floorY + 1.6, zWallFront), Color3.fromRGB(52, 56, 64), Enum.Material.Granite)
            PartBuilder.makePart(model, "BankGlassCurtain_Front_" .. fSeg.xc, Vector3.new(fSeg.len, 11.3, 0.5),
                CFrame.new(fSeg.xc, floorY + 3.2 + 5.65, zWallFront), glassBlue, Enum.Material.Glass, { Transparency = 0.36 })
            PartBuilder.makePart(model, "FrostedPrivacyBand_Front_" .. fSeg.xc, Vector3.new(fSeg.len + 0.1, 1.8, 0.55),
                CFrame.new(fSeg.xc, floorY + 6.4, zWallFront), Color3.fromRGB(240, 245, 250), Enum.Material.SmoothPlastic, { Transparency = 0.25 })
        end
        PartBuilder.makePart(model, "UpperHeaderWall_Front", Vector3.new(sizeX, 7.5, wallThick),
            CFrame.new(posX, floorY + wallH - 3.75, zWallFront), wallColor, wallMaterial)
        PartBuilder.makePart(model, "ATMBayWall_Front", Vector3.new(28, 14.5, wallThick),
            CFrame.new(136, floorY + 7.25, zWallFront), Color3.fromRGB(228, 232, 238), Enum.Material.Concrete)
        for _, mx in ipairs({ 70, 80, 90, 100, 110, 120 }) do
            PartBuilder.makePart(model, "Mullion_Front_" .. mx, Vector3.new(0.45, 11.5, 0.8),
                CFrame.new(mx, floorY + 3.2 + 5.75, zWallFront), frameMetal, Enum.Material.Metal)
        end
        InteractiveDoorBuilder.buildDoubleGlassDoor(model, "FrontBankDoor", {
            axis = "X",
            doorCenterAlong = 95,
            fixedPos = zWallFront,
            inDirSign = -1,
            floorY = floorY,
            openW = 10.0,
            leafW = 4.85,
            openH = 11.2,
            leafH = 10.8,
            glassTopH = 14.5,
            maxHP = 130,
            openDeg = 82,
            initialOpen = false,
            doorLabel = "ประตูทางเข้าธนาคารกรุงเทพ (ด้านหน้า)",
        })
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
        -- ผนังฐานและกระจกขนาบข้างประตูทางเข้าด้านขวาของธนาคาร (เว้นช่องประตูเปิด-ปิดได้ที่ Z = 76..88)
        for _, seg in ipairs({ { zc = 60, len = 32 }, { zc = 104, len = 32 } }) do
            PartBuilder.makePart(model, "BaseLowWall_East_" .. seg.zc, Vector3.new(wallThick, 3.2, seg.len),
                CFrame.new(xWallEast, floorY + 1.6, seg.zc), Color3.fromRGB(52, 56, 64), Enum.Material.Granite)
            PartBuilder.makePart(model, "BankGlass_East_" .. seg.zc, Vector3.new(0.5, 11.3, seg.len - 1),
                CFrame.new(xWallEast, floorY + 3.2 + 5.65, seg.zc), glassBlue, Enum.Material.Glass, { Transparency = 0.36 })
            PartBuilder.makePart(model, "FrostedBand_East_" .. seg.zc, Vector3.new(0.55, 1.8, seg.len - 1),
                CFrame.new(xWallEast, floorY + 6.4, seg.zc), Color3.fromRGB(240, 245, 250), Enum.Material.SmoothPlastic, { Transparency = 0.25 })
        end
        InteractiveDoorBuilder.buildDoubleGlassDoor(model, "EastBankDoor", {
            axis = "Z",
            doorCenterAlong = 82,
            fixedPos = xWallEast,
            inDirSign = -1,
            floorY = floorY,
            openW = 12.0,
            leafW = 5.85,
            openH = 11.6,
            leafH = 11.2,
            glassTopH = 14.5,
            maxHP = 130,
            openDeg = 82,
            initialOpen = false,
            doorLabel = "ประตูทางเข้าธนาคาร (ฝั่งตะวันออก)",
        })

        PartBuilder.makeSign(model, "BangkokBankSign_EastRight",
            "🏦 ธนาคารกรุงเทพ สาขา มจพ. (ทางเข้าด้านขวา)\nBANGKOK BANK — EAST ENTRANCE",
            Vector3.new(0.35, 5.2, 72),
            Vector3.new(150.2, floorY + 18.2, posZ),
            Enum.NormalId.Right, bankBlue, Color3.fromRGB(255, 255, 255))
        PartBuilder.makePart(model, "BankOrangeAccent_EastRight", Vector3.new(0.45, 0.65, 72),
            CFrame.new(150.22, floorY + 15.2, posZ), bankOrange, Enum.Material.Neon)

        -- 3) ตกแต่งภายในธนาคารให้หรูหรา: พื้นหินอ่อน เคาน์เตอร์ 4 ช่องบริการ โซนรับรอง และป้ายดิจิทัล
        PartBuilder.makePart(model, "BankLobbyMarbleFloor", Vector3.new(sizeX - 4, 0.03, sizeZ - 4),
            CFrame.new(posX, floorY + 0.015, posZ), marbleCream, Enum.Material.Marble, { CanCollide = false })
        PartBuilder.makePart(model, "BankFloorRunnerTrim", Vector3.new(40, 0.04, 18),
            CFrame.new(95, floorY + 0.03, 94), Color3.fromRGB(218, 224, 232), Enum.Material.Granite, { CanCollide = false })
        PartBuilder.makePart(model, "BankOrangeLogoStripe_N", Vector3.new(46, 0.4, 0.3),
            CFrame.new(94, floorY + 10.6, 46.2), bankOrange, Enum.Material.Neon)

        -- เคาน์เตอร์พนักงาน 4 ช่องบริการ (X = 72..116, Z = 68; เว้นช่อง X = 116..120 เดินอ้อมหลังเคาน์เตอร์ได้)
        PartBuilder.makePart(model, "TellerCounterBase", Vector3.new(44, 3.8, 3.6),
            CFrame.new(94, floorY + 1.9, 68), bankBlue, Enum.Material.SmoothPlastic)
        PartBuilder.makePart(model, "TellerCounterAccentLED", Vector3.new(43.4, 0.22, 0.2),
            CFrame.new(94, floorY + 0.65, 69.85), bankOrange, Enum.Material.Neon)
        PartBuilder.makePart(model, "TellerCounterTop", Vector3.new(44.6, 0.4, 4.2),
            CFrame.new(94, floorY + 3.9, 68), marbleCream, Enum.Material.Marble)
        PartBuilder.makePart(model, "TellerGlassScreen", Vector3.new(43.2, 4.4, 0.25),
            CFrame.new(94, floorY + 6.3, 68), glassBlue, Enum.Material.Glass, { Transparency = 0.45 })
        for i, tx in ipairs({ 77.5, 88.5, 99.5, 110.5 }) do
            PartBuilder.makePart(model, "TellerDivider_" .. i, Vector3.new(0.28, 4.6, 0.55),
                CFrame.new(tx - 5.2, floorY + 6.3, 68), frameMetal, Enum.Material.Metal)
            PartBuilder.makeSign(model, "TellerSlotLabel_" .. i,
                string.format("COUNTER %d", i),
                Vector3.new(4.8, 1.1, 0.16),
                Vector3.new(tx, floorY + 8.9, 68.25),
                Enum.NormalId.Back, bankBlue, Color3.fromRGB(255, 220, 120))
            -- คอมพิวเตอร์และเก้าอี้พนักงานหลังเคาน์เตอร์ (Z = 64..67)
            PartBuilder.makePart(model, "TellerMonitor_" .. i, Vector3.new(2.0, 1.4, 0.18),
                CFrame.new(tx, floorY + 5.0, 67.1), Color3.fromRGB(26, 30, 38), Enum.Material.Metal)
            PartBuilder.makePart(model, "TellerScreenGlow_" .. i, Vector3.new(1.75, 1.15, 0.08),
                CFrame.new(tx, floorY + 5.0, 66.98), Color3.fromRGB(58, 138, 210), Enum.Material.Neon)
            PartBuilder.makePart(model, "TellerChairSeat_" .. i, Vector3.new(2.1, 0.35, 2.0),
                CFrame.new(tx, floorY + 1.9, 63.8), darkSlate, Enum.Material.Fabric)
            PartBuilder.makePart(model, "TellerChairBack_" .. i, Vector3.new(2.0, 2.2, 0.35),
                CFrame.new(tx, floorY + 3.0, 62.9), darkSlate, Enum.Material.Fabric)
        end
        PartBuilder.makeSign(model, "InteriorBackdropSign",
            "ธนาคารกรุงเทพ จำกัด (มหาชน) — สาขา มจพ.\nBANGKOK BANK PUBLIC COMPANY LIMITED",
            Vector3.new(44, 4.6, 0.25), Vector3.new(94, floorY + 13.5, 46.2),
            Enum.NormalId.Back, bankBlue, Color3.fromRGB(255, 255, 255))

        -- แนวเสากั้นคิวหน้าเคาน์เตอร์ (Z = 75) และบอร์ดอัตราแลกเปลี่ยนฝั่งผนังตะวันตก
        for idx, sx in ipairs({ 74, 83, 92, 101, 110 }) do
            PartBuilder.makePart(model, "StanchionPost_" .. idx, Vector3.new(0.32, 3.2, 0.32),
                CFrame.new(sx, floorY + 1.6, 75), brassGold, Enum.Material.Metal)
            if idx < 5 then
                PartBuilder.makePart(model, "StanchionBelt_" .. idx, Vector3.new(8.7, 0.22, 0.1),
                    CFrame.new(sx + 4.5, floorY + 2.95, 75), bankBlue, Enum.Material.Fabric)
            end
        end
        PartBuilder.makeSign(model, "BankRateBoard_West",
            "FX EXCHANGE & SERVICE\nUSD 34.10 | EUR 37.25 | JPY 0.228\nWELCOME TO BANGKOK BANK",
            Vector3.new(0.28, 5.4, 11.0),
            Vector3.new(70.35, floorY + 7.6, 90),
            Enum.NormalId.Right, Color3.fromRGB(20, 32, 54), Color3.fromRGB(130, 220, 255))

        -- โซนที่นั่งรับรองลูกค้า (Z = 104 เว้นโถงกลาง Z = 78..96 โล่งชัดเจน) + ตู้กดบัตรคิว + กระถางต้นไม้
        for _, cx in ipairs({ 80, 102 }) do
            PartBuilder.makePart(model, "WaitingBenchBase_" .. cx, Vector3.new(10.0, 1.3, 2.2),
                CFrame.new(cx, floorY + 0.65, 104), frameMetal, Enum.Material.Metal)
            PartBuilder.makePart(model, "WaitingBenchSeat_" .. cx, Vector3.new(10.4, 0.45, 2.5),
                CFrame.new(cx, floorY + 1.55, 104), bankBlue, Enum.Material.Fabric)
            PartBuilder.makePart(model, "WaitingBenchBack_" .. cx, Vector3.new(10.4, 1.8, 0.4),
                CFrame.new(cx, floorY + 2.55, 105.0), bankBlue, Enum.Material.Fabric)
        end
        PartBuilder.makePart(model, "LobbyBrochureTable", Vector3.new(5.2, 1.7, 3.0),
            CFrame.new(91, floorY + 0.85, 109.5), marbleCream, Enum.Material.Marble)
        PartBuilder.makePart(model, "QueueKiosk", Vector3.new(2.0, 5.2, 1.8),
            CFrame.new(119, floorY + 2.6, 108), bankBlue, Enum.Material.Metal)
        PartBuilder.makePart(model, "QueueKioskScreen", Vector3.new(1.5, 1.4, 0.16),
            CFrame.new(119, floorY + 3.8, 107.05), Color3.fromRGB(70, 200, 255), Enum.Material.Neon)

        for idx, pt in ipairs({
            Vector3.new(72.5, floorY, 72.5),
            Vector3.new(72.5, floorY, 114.5),
            Vector3.new(114.5, floorY, 114.5),
            Vector3.new(145.0, floorY, 113.5),
        }) do
            PartBuilder.makePart(model, "BankPlanterPot_" .. idx, Vector3.new(2.4, 2.2, 2.4),
                CFrame.new(pt.X, floorY + 1.1, pt.Z), marbleCream, Enum.Material.Marble)
            PartBuilder.makePart(model, "BankPlanterLeaf_" .. idx, Vector3.new(3.0, 3.2, 3.0),
                CFrame.new(pt.X, floorY + 3.6, pt.Z), Color3.fromRGB(48, 112, 62), Enum.Material.Grass)
        end

        -- 4) ห้องผู้จัดการธนาคาร (Manager's Office ปิดมิดชิดถึงเพดาน X = 120..148, Z = 46..72)
        -- กั้นผนังด้านตะวันตก (X = 120) และด้านใต้ (Z = 72) พร้อมประตูเดียวปิดไว้ (initialOpen = false)
        local mgrFloorCenter = Vector3.new(134, floorY, 59)
        PartBuilder.makePart(model, "ManagerWall_West_Base", Vector3.new(1.0, 4.5, 26.5),
            CFrame.new(120, floorY + 2.25, 59), darkWalnut, Enum.Material.Wood)
        PartBuilder.makePart(model, "ManagerWall_West_Glass", Vector3.new(0.45, 6.0, 25.5),
            CFrame.new(120, floorY + 7.5, 59), glassBlue, Enum.Material.Glass, { Transparency = 0.55 })
        PartBuilder.makePart(model, "ManagerWall_West_Upper", Vector3.new(1.0, wallH - 10.5, 26.5),
            CFrame.new(120, floorY + 10.5 + (wallH - 10.5) / 2, 59), wallColor, wallMaterial)

        for _, mSeg in ipairs({ { xc = 124.5, len = 9.0 }, { xc = 141.5, len = 13.0 } }) do
            PartBuilder.makePart(model, "ManagerWall_South_Base_" .. mSeg.xc, Vector3.new(mSeg.len, 4.5, 1.0),
                CFrame.new(mSeg.xc, floorY + 2.25, 72), darkWalnut, Enum.Material.Wood)
            PartBuilder.makePart(model, "ManagerWall_South_Glass_" .. mSeg.xc, Vector3.new(mSeg.len - 0.5, 6.0, 0.45),
                CFrame.new(mSeg.xc, floorY + 7.5, 72), glassBlue, Enum.Material.Glass, { Transparency = 0.55 })
            PartBuilder.makePart(model, "ManagerWall_South_Upper_" .. mSeg.xc, Vector3.new(mSeg.len, wallH - 10.5, 1.0),
                CFrame.new(mSeg.xc, floorY + 10.5 + (wallH - 10.5) / 2, 72), wallColor, wallMaterial)
        end
        PartBuilder.makePart(model, "ManagerWall_DoorHeader", Vector3.new(6.8, wallH - 10.5, 1.0),
            CFrame.new(132, floorY + 10.5 + (wallH - 10.5) / 2, 72), wallColor, wallMaterial)
        PartBuilder.makeSign(model, "ManagerOfficePlaque",
            "BRANCH MANAGER'S OFFICE\nห้องผู้จัดการสาขา",
            Vector3.new(5.6, 1.4, 0.16),
            Vector3.new(132, floorY + 11.6, 72.58),
            Enum.NormalId.Back, darkWalnut, brassGold)
        InteractiveDoorBuilder.buildSingleDoor(model, "BankManagerOfficeDoor", {
            axis = "X",
            doorCenterAlong = 132,
            fixedPos = 72,
            inDirSign = -1,
            hingeSide = -1,
            floorY = floorY,
            openW = 6.0,
            openH = 10.5,
            thick = 0.36,
            style = "ManagerOffice",
            color = darkWalnut,
            material = Enum.Material.Wood,
            maxHP = 180,
            openDeg = 85,
            initialOpen = false,
            doorLabel = "ห้องผู้จัดการสาขา (Manager's Office)",
        })

        -- เฟอร์นิเจอร์ห้องผู้จัดการ: พรม โต๊ะไม้ผู้บริหาร ตู้เซฟ ชั้นเอกสาร เก้าอี้ที่ดันขวางประตู และโคมไฟตั้งโต๊ะ
        PartBuilder.makePart(model, "ManagerOfficeRug", Vector3.new(20, 0.04, 16),
            CFrame.new(mgrFloorCenter.X, floorY + 0.04, mgrFloorCenter.Z - 1), Color3.fromRGB(68, 30, 38), Enum.Material.Fabric, { CanCollide = false })
        PartBuilder.makePart(model, "ManagerDeskBody", Vector3.new(11.0, 3.3, 4.6),
            CFrame.new(135, floorY + 1.65, 55), darkWalnut, Enum.Material.Wood)
        PartBuilder.makePart(model, "ManagerDeskTop", Vector3.new(11.6, 0.35, 5.0),
            CFrame.new(135, floorY + 3.475, 55), warmWood, Enum.Material.Wood)
        PartBuilder.makePart(model, "ManagerDeskGoldTrim", Vector3.new(11.2, 0.18, 0.15),
            CFrame.new(135, floorY + 3.15, 57.35), brassGold, Enum.Material.Metal)
        PartBuilder.makeSign(model, "ManagerNameplate",
            "PHATCHAREE S. — BRANCH MANAGER",
            Vector3.new(3.6, 0.65, 0.25),
            Vector3.new(135, floorY + 3.98, 57.0),
            Enum.NormalId.Back, darkWalnut, brassGold)
        PartBuilder.makePart(model, "ManagerBankerLampBase", Vector3.new(0.85, 0.2, 0.85),
            CFrame.new(130.4, floorY + 3.75, 54.0), brassGold, Enum.Material.Metal)
        PartBuilder.makePart(model, "ManagerBankerLampStem", Vector3.new(0.18, 1.3, 0.18),
            CFrame.new(130.4, floorY + 4.4, 54.0), brassGold, Enum.Material.Metal)
        local mgrLampShade = PartBuilder.makePart(model, "ManagerBankerLampShade", Vector3.new(1.3, 0.55, 0.8),
            CFrame.new(130.4, floorY + 5.1, 54.2), Color3.fromRGB(36, 118, 74), Enum.Material.Neon)
        local mgrDeskLight = Instance.new("PointLight")
        mgrDeskLight.Name = "ManagerDeskLight"
        mgrDeskLight.Color = Color3.fromRGB(255, 214, 150)
        mgrDeskLight.Range = 18
        mgrDeskLight.Brightness = 0.85
        mgrDeskLight.Parent = mgrLampShade

        PartBuilder.makePart(model, "ManagerBookshelf_N", Vector3.new(11.0, 8.8, 2.2),
            CFrame.new(137, floorY + 4.4, 47.2), darkWalnut, Enum.Material.Wood)
        PartBuilder.makePart(model, "ManagerVaultSafe", Vector3.new(4.2, 5.2, 3.6),
            CFrame.new(124.2, floorY + 2.6, 48.2), darkSlate, Enum.Material.Metal)
        PartBuilder.makePart(model, "ManagerVaultDial", Vector3.new(0.8, 0.8, 0.25),
            CFrame.new(124.2, floorY + 3.1, 50.05), brassGold, Enum.Material.Metal)
        PartBuilder.makePart(model, "ManagerPlant_NE", Vector3.new(2.0, 2.0, 2.0),
            CFrame.new(145.0, floorY + 1.0, 48.5), marbleCream, Enum.Material.Marble)
        PartBuilder.makePart(model, "ManagerPlantLeaves_NE", Vector3.new(2.6, 3.0, 2.6),
            CFrame.new(145.0, floorY + 3.4, 48.5), Color3.fromRGB(48, 112, 62), Enum.Material.Grass)
        -- เก้าอี้รับแขกที่ถูกผลักขวางแนวประตู (Last Stand Barricade Storytelling)
        PartBuilder.makePart(model, "BarricadeVisitorChairSeat", Vector3.new(2.2, 0.38, 2.2),
            CFrame.new(127.5, floorY + 1.1, 63.0) * CFrame.Angles(math.rad(68), math.rad(28), math.rad(-14)), darkSlate, Enum.Material.Fabric)
        PartBuilder.makePart(model, "BarricadeVisitorChairBack", Vector3.new(2.2, 2.1, 0.35),
            CFrame.new(127.0, floorY + 1.75, 62.1) * CFrame.Angles(math.rad(68), math.rad(28), math.rad(-14)), darkSlate, Enum.Material.Fabric)
        for idx, cx in ipairs({ 131.2, 132.0, 132.6, 131.7 }) do
            PartBuilder.makePart(model, "SpentShellCasing_" .. idx, Vector3.new(0.1, 0.08, 0.24),
                CFrame.new(cx, floorY + 0.06, 65.4 + idx * 0.65) * CFrame.Angles(0, math.rad(idx * 42), 0),
                brassGold, Enum.Material.Metal, { CanCollide = false })
        end

        -- 5) เก้าอี้ผู้บริหารในห้องผู้จัดการ (พื้นที่เปิดโล่งสำหรับวางของตกแต่ง/ศพ)
        PartBuilder.makePart(model, "MgrChairSeat", Vector3.new(2.6, 0.45, 2.5),
            CFrame.new(136.6, floorY + 1.5, 50.6) * CFrame.Angles(0, math.rad(18), math.rad(-12)), darkSlate, Enum.Material.Fabric)
        PartBuilder.makePart(model, "MgrChairBack", Vector3.new(2.5, 3.2, 0.45),
            CFrame.new(137.1, floorY + 2.8, 49.5) * CFrame.Angles(math.rad(-22), math.rad(18), math.rad(-12)), darkSlate, Enum.Material.Fabric)

        -- 6) ไฟเพดานภายในธนาคาร (โถงลูกค้าสว่างเรียบร้อย, ห้องผู้จัดการแสงนุ่มเฉพาะโคมไฟโต๊ะ)
        for _, lx in ipairs({ 84, 108, 134 }) do
            for _, lz in ipairs({ 84, 104 }) do
                PartBuilder.addPointLight(model, string.format("BankLight_%d_%d", lx, lz),
                    Vector3.new(lx, floorY + wallH - 2.0, lz), Color3.fromRGB(255, 250, 240), 40, 1.2)
            end
        end
    end

    ------------------------------------------------------------------
    -- 3.2 คาเฟ่อาคาร 40 ปี (Modern Glass Enclosed Campus Cafe ที่ X = +68..+150, Z = -120..-44)
    --     ผนังกระจกใสรอบด้าน (Glass Curtain Walls) ชมวิวถนนและลานจอดรถ พร้อมประตูกระจกบานเปิด และตกแต่งครบชุด
    ------------------------------------------------------------------
    local function buildOpenCafeF1()
        local cafe = Instance.new("Model")
        cafe.Name = "ModernGlassCafe_TopRight"
        cafe.Parent = floor1

        local posX, posZ = 109, -82
        local sizeX, sizeZ = 82, 76 -- X = 68..150, Z = -120..-44
        local woodWarm = Color3.fromRGB(148, 98, 56)
        local woodDark = Color3.fromRGB(82, 52, 32)
        local marbleTop = Color3.fromRGB(242, 239, 232)
        local metalBlack = Color3.fromRGB(38, 42, 48)
        local chromeCol = Color3.fromRGB(215, 220, 228)
        local goldAccent = Color3.fromRGB(238, 175, 65)
        local cafeGlass = Color3.fromRGB(175, 218, 238)

        -- 1) พื้นไม้คาเฟ่
        PartBuilder.makePart(cafe, "CafeWoodFloor", Vector3.new(sizeX - 2, 0.04, sizeZ - 2),
            CFrame.new(posX, floorY + 0.02, posZ), Color3.fromRGB(162, 118, 78), Enum.Material.WoodPlanks, { CanCollide = false })

        -- 1.5) ผนังกระจกใสรอบด้านของคาเฟ่ (Glass Curtain Walls with Mullions & Doors)
        local glassH = 14.5
        local glassY = floorY + 2.2 + glassH / 2

        -- [A] ผนังกระจกทิศใต้หันเข้าหาลานจอดรถ (Z = -44) — ผนังกระจกปิดทึบ ไม่มีทางเข้าจากลานจอดรถ
        local zFront = -44 - wallThick / 2
        PartBuilder.makePart(cafe, "GlassWall_Front", Vector3.new(sizeX - 2, glassH, 0.5),
            CFrame.new(posX, glassY, zFront), cafeGlass, Enum.Material.Glass, { Transparency = 0.5 })
        PartBuilder.makePart(cafe, "BasePlinth_Front", Vector3.new(sizeX, 2.2, wallThick),
            CFrame.new(posX, floorY + 1.1, zFront), Color3.fromRGB(52, 56, 62), Enum.Material.Granite)
        PartBuilder.makePart(cafe, "HeaderBeam_Front", Vector3.new(sizeX, 5.3, wallThick),
            CFrame.new(posX, floorY + wallH - 2.65, zFront), wallColor, wallMaterial)
        for _, mx in ipairs({ 76, 88, 100, 112, 124, 136, 144 }) do
            PartBuilder.makePart(cafe, "Mullion_Front_" .. mx, Vector3.new(0.5, glassH, 0.8),
                CFrame.new(mx, glassY, zFront), metalBlack, Enum.Material.Metal)
        end

        -- [B] ผนังกระจกทิศตะวันออกมองเห็นถนนฝั่งขวา (X = +150) — ทางเข้าหลักด้านนอกอาคาร
        local xEast = 150 - wallThick / 2
        PartBuilder.makePart(cafe, "GlassWall_East_N", Vector3.new(0.5, glassH, 37),
            CFrame.new(xEast, glassY, -101.5), cafeGlass, Enum.Material.Glass, { Transparency = 0.48 })
        PartBuilder.makePart(cafe, "GlassWall_East_S", Vector3.new(0.5, glassH, 29),
            CFrame.new(xEast, glassY, -58.5), cafeGlass, Enum.Material.Glass, { Transparency = 0.48 })
        PartBuilder.makePart(cafe, "BasePlinth_East_N", Vector3.new(wallThick, 2.2, 37),
            CFrame.new(xEast, floorY + 1.1, -101.5), Color3.fromRGB(52, 56, 62), Enum.Material.Granite)
        PartBuilder.makePart(cafe, "BasePlinth_East_S", Vector3.new(wallThick, 2.2, 29),
            CFrame.new(xEast, floorY + 1.1, -58.5), Color3.fromRGB(52, 56, 62), Enum.Material.Granite)
        PartBuilder.makePart(cafe, "HeaderBeam_East", Vector3.new(wallThick, 5.3, sizeZ),
            CFrame.new(xEast, floorY + wallH - 2.65, posZ), wallColor, wallMaterial)
        for _, mz in ipairs({ -114, -102, -90, -68, -54 }) do
            PartBuilder.makePart(cafe, "Mullion_East_" .. mz, Vector3.new(0.8, glassH, 0.5),
                CFrame.new(xEast, glassY, mz), metalBlack, Enum.Material.Metal)
        end
        -- ประตูกระจกบานคู่เปิด-ปิดได้จริงทางเข้าคาเฟ่จากด้านนอกอาคารฝั่งขวา (X = 150, Z = -83..-73)
        InteractiveDoorBuilder.buildDoubleGlassDoor(cafe, "EastCafeDoor", {
            axis = "Z",
            doorCenterAlong = -78,
            fixedPos = xEast,
            inDirSign = -1,
            floorY = floorY,
            openW = 10.0,
            leafW = 4.8,
            openH = 14.5,
            leafH = 14.1,
            glassTopH = 16.7,
            maxHP = 120,
            openDeg = 80,
            initialOpen = false,
            doorLabel = "ประตูคาเฟ่ (ทางเข้าด้านนอกอาคาร)",
        })
        PartBuilder.makeSign(cafe, "CafeEastSign",
            "☕ คาเฟ่ อาคาร 40 ปี มจพ. (CAMPUS COFFEE & BAKERY)",
            Vector3.new(0.35, 4.2, 42),
            Vector3.new(150.2, floorY + 18.2, -78),
            Enum.NormalId.Right, woodDark, goldAccent)

        -- [C] ผนังกระจกทิศเหนือมองเห็นถนนหลังตึก (Z = -120) — ทางเข้าจากด้านหลังตึก (ด้านนอกอาคาร)
        local zNorth = -120 + wallThick / 2
        PartBuilder.makePart(cafe, "GlassWall_North_W", Vector3.new(59, glassH, 0.5),
            CFrame.new(97.5, glassY, zNorth), cafeGlass, Enum.Material.Glass, { Transparency = 0.48 })
        PartBuilder.makePart(cafe, "GlassWall_North_E", Vector3.new(13, glassH, 0.5),
            CFrame.new(143.5, glassY, zNorth), cafeGlass, Enum.Material.Glass, { Transparency = 0.48 })
        PartBuilder.makePart(cafe, "BasePlinth_North_W", Vector3.new(59, 2.2, wallThick),
            CFrame.new(97.5, floorY + 1.1, zNorth), Color3.fromRGB(52, 56, 62), Enum.Material.Granite)
        PartBuilder.makePart(cafe, "BasePlinth_North_E", Vector3.new(13, 2.2, wallThick),
            CFrame.new(143.5, floorY + 1.1, zNorth), Color3.fromRGB(52, 56, 62), Enum.Material.Granite)
        PartBuilder.makePart(cafe, "HeaderBeam_North", Vector3.new(sizeX, 5.3, wallThick),
            CFrame.new(posX, floorY + wallH - 2.65, zNorth), wallColor, wallMaterial)
        for _, mx in ipairs({ 76, 92, 108, 122, 142 }) do
            PartBuilder.makePart(cafe, "Mullion_North_" .. mx, Vector3.new(0.5, glassH, 0.8),
                CFrame.new(mx, glassY, zNorth), metalBlack, Enum.Material.Metal)
        end
        -- ประตูกระจกบานคู่เปิด-ปิดได้จริงทางเข้าคาเฟ่จากด้านหลังตึก (Z = -120, X = 127..137)
        InteractiveDoorBuilder.buildDoubleGlassDoor(cafe, "NorthCafeDoor", {
            axis = "X",
            doorCenterAlong = 132,
            fixedPos = zNorth,
            inDirSign = 1,
            floorY = floorY,
            openW = 10.0,
            leafW = 4.8,
            openH = 14.5,
            leafH = 14.1,
            glassTopH = 16.7,
            maxHP = 120,
            openDeg = 80,
            initialOpen = false,
            doorLabel = "ประตูคาเฟ่ (ทางเข้าด้านหลังตึก)",
        })
        PartBuilder.makeSign(cafe, "CafeNorthSign",
            "☕ คาเฟ่ อาคาร 40 ปี — ทางเข้าด้านหลัง",
            Vector3.new(34, 3.8, 0.35),
            Vector3.new(132, floorY + 18.2, zNorth - 0.2),
            Enum.NormalId.Front, woodDark, goldAccent)

        -- [D] ผนังทึบด้านตะวันตกกั้นโซนบันได/คอร์อาคาร (X = 68) — กั้นทึบสนิท ไม่มีประตูและไม่มีห้องเสริม
        local xWest = 68 + wallThick / 2
        PartBuilder.makePart(cafe, "Wall_West_CoreSolid", Vector3.new(wallThick, wallH, sizeZ),
            CFrame.new(xWest, floorY + wallH / 2, posZ), wallColor, wallMaterial)

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
        -- แก้วกาแฟกระดาษซ้อน + เหยือกสตรีมนม + เมนูตั้งโต๊ะเคาน์เตอร์ + ป้ายไฟ OPEN
        for sIdx = 1, 2 do
            PartBuilder.makeCylinder(cafe, "PaperCupStack_" .. sIdx, Vector3.new(2.0, 0.72, 0.72),
                CFrame.new(99.8 + sIdx * 1.1, floorY + 5.2, -97.5) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(246, 242, 234), Enum.Material.SmoothPlastic, { CanCollide = false })
        end
        PartBuilder.makeCylinder(cafe, "MilkPitcher", Vector3.new(0.85, 0.65, 0.65),
            CFrame.new(93.8, floorY + 4.65, -97.2) * CFrame.Angles(0, 0, math.rad(90)),
            chromeCol, Enum.Material.Metal, { CanCollide = false })
        PartBuilder.makePart(cafe, "QRPayStandCafe", Vector3.new(0.95, 1.25, 0.16),
            CFrame.new(102.8, floorY + 4.85, -96.5) * CFrame.Angles(math.rad(-14), 0, 0),
            Color3.fromRGB(30, 95, 185), Enum.Material.SmoothPlastic, { CanCollide = false })

        -- 4) ตู้กระจกโชว์เค้กและเบเกอรี่ (Glass Bakery & Cake Showcase — ครบ 2 ชั้นทั้งเค้กปอนด์ เค้กชิ้น ครัวซองต์)
        PartBuilder.makePart(cafe, "CakeShowcaseBase", Vector3.new(12.0, 2.0, 4.0),
            CFrame.new(112, floorY + 5.1, -98), metalBlack, Enum.Material.Metal)
        PartBuilder.makePart(cafe, "CakeShowcaseGlass", Vector3.new(11.6, 3.2, 3.8),
            CFrame.new(112, floorY + 7.7, -98), Color3.fromRGB(210, 235, 245), Enum.Material.Glass, { Transparency = 0.48 })
        PartBuilder.makePart(cafe, "CakeShelfMiddle", Vector3.new(11.2, 0.14, 3.2),
            CFrame.new(112, floorY + 7.3, -98), chromeCol, Enum.Material.Metal)
        for idx, cx in ipairs({ 108, 111, 114, 116.5 }) do
            local cakeCol = (idx % 2 == 0) and Color3.fromRGB(245, 195, 205) or Color3.fromRGB(235, 185, 115)
            PartBuilder.makeCylinder(cafe, "CakeDisplay_" .. idx, Vector3.new(0.85, 1.8, 1.8),
                CFrame.new(cx, floorY + 7.8, -98) * CFrame.Angles(0, 0, math.rad(90)),
                cakeCol, Enum.Material.SmoothPlastic, { CanCollide = false })
            -- ถาดเบเกอรี่ & ครัวซองต์บนชั้นล่าง (วางเหนือฐานตู้โชว์ 6.1 ชัดเจน)
            PartBuilder.makePart(cafe, "PastryTray_" .. idx, Vector3.new(2.2, 0.14, 2.5),
                CFrame.new(cx, floorY + 6.18, -98), chromeCol, Enum.Material.Metal, { CanCollide = false })
            PartBuilder.makePart(cafe, "Croissant_" .. idx, Vector3.new(1.1, 0.45, 0.7),
                CFrame.new(cx, floorY + 6.48, -98) * CFrame.Angles(0, math.rad(idx * 18), 0),
                Color3.fromRGB(210, 145, 72), Enum.Material.SmoothPlastic, { CanCollide = false })
        end

        -- 5) เคาน์เตอร์เตรียมเครื่องดื่มด้านหลัง + ขวดไซรัป 6 สี + โหลเมล็ดกาแฟ + แก้วเรียงชั้นบน
        PartBuilder.makePart(cafe, "BackBarCounter", Vector3.new(38, 3.6, 3.0),
            CFrame.new(98, floorY + 1.8, -110), woodDark, Enum.Material.Wood)
        PartBuilder.makePart(cafe, "BackBarTop", Vector3.new(38.4, 0.35, 3.4),
            CFrame.new(98, floorY + 3.75, -110), chromeCol, Enum.Material.Metal)
        PartBuilder.makePart(cafe, "BackShelfFrame", Vector3.new(32, 7.5, 1.6),
            CFrame.new(98, floorY + 7.5, -110.5), metalBlack, Enum.Material.Metal)
        PartBuilder.makePart(cafe, "BackShelfTier1", Vector3.new(31, 0.18, 1.4),
            CFrame.new(98, floorY + 6.0, -110.5), woodWarm, Enum.Material.Wood)
        PartBuilder.makePart(cafe, "BackShelfTier2", Vector3.new(31, 0.18, 1.4),
            CFrame.new(98, floorY + 8.6, -110.5), woodWarm, Enum.Material.Wood)

        local syrupCols = {
            Color3.fromRGB(205, 128, 42),
            Color3.fromRGB(238, 212, 148),
            Color3.fromRGB(115, 58, 28),
            Color3.fromRGB(82, 165, 75),
            Color3.fromRGB(210, 52, 72),
            Color3.fromRGB(165, 112, 68),
        }
        for bIdx, sCol in ipairs(syrupCols) do
            PartBuilder.makeCylinder(cafe, "SyrupBottle_" .. bIdx, Vector3.new(1.35, 0.5, 0.5),
                CFrame.new(84.5 + (bIdx - 1) * 1.4, floorY + 4.6, -110.0) * CFrame.Angles(0, 0, math.rad(90)),
                sCol, Enum.Material.Glass, { Transparency = 0.2, CanCollide = false })
        end
        for cIdx = 1, 4 do
            local jx = 100 + (cIdx - 1) * 2.8
            PartBuilder.makeCylinder(cafe, "BeanCanister_" .. cIdx, Vector3.new(1.5, 1.1, 1.1),
                CFrame.new(jx, floorY + 6.85, -110.4) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(88, 52, 30), Enum.Material.Glass, { Transparency = 0.35, CanCollide = false })
        end
        -- เครื่องปั่นกาแฟ / Ice Shaver บนเคาน์เตอร์ข้างตัว L
        PartBuilder.makePart(cafe, "SideBarBlenderBase", Vector3.new(1.6, 1.1, 1.6),
            CFrame.new(79, floorY + 4.75, -83), metalBlack, Enum.Material.Metal)
        PartBuilder.makeCylinder(cafe, "SideBarBlenderJar", Vector3.new(1.6, 1.1, 1.1),
            CFrame.new(79, floorY + 6.0, -83) * CFrame.Angles(0, 0, math.rad(90)),
            cafeGlass, Enum.Material.Glass, { Transparency = 0.45 })
        -- ป้ายขาตั้ง A-Frame หน้าร้านด้านนอกอาคาร (ฝั่งทางเข้าตะวันออก)
        PartBuilder.makePart(cafe, "AFrameBoardEast", Vector3.new(2.8, 3.8, 0.16),
            CFrame.new(154.5, floorY + 1.9, -74) * CFrame.Angles(math.rad(-12), math.rad(75), 0),
            woodDark, Enum.Material.Wood)
        PartBuilder.makeSign(cafe, "AFramePromoEast", "TODAY SPECIAL!\nICED LATTE 55.-\nCROISSANT SET 89.-",
            Vector3.new(2.4, 3.0, 0.18), Vector3.new(154.4, floorY + 2.0, -74),
            Enum.NormalId.Right, Color3.fromRGB(36, 40, 46), goldAccent)

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

        -- 10) โคมไฟแขวนเพดานโทนอบอุ่นพร้อมโคมครอบทองเหลือง (Warm Cafe Pendant Lights)
        for _, lx in ipairs({ 92, 116, 138 }) do
            for _, lz in ipairs({ -98, -74, -54 }) do
                PartBuilder.makeCylinder(cafe, string.format("PendantCord_%d_%d", lx, lz), Vector3.new(3.2, 0.14, 0.14),
                    CFrame.new(lx, floorY + wallH - 1.6, lz) * CFrame.Angles(0, 0, math.rad(90)),
                    metalBlack, Enum.Material.Metal, { CanCollide = false })
                PartBuilder.makeCylinder(cafe, string.format("PendantShade_%d_%d", lx, lz), Vector3.new(0.7, 1.8, 1.8),
                    CFrame.new(lx, floorY + wallH - 3.3, lz) * CFrame.Angles(0, 0, math.rad(90)),
                    goldAccent, Enum.Material.Metal, { CanCollide = false })
                PartBuilder.addPointLight(cafe, string.format("CafeWarmLight_%d_%d", lx, lz),
                    Vector3.new(lx, floorY + wallH - 3.8, lz), Color3.fromRGB(255, 228, 185), 42, 1.35)
            end
        end

        -- 11) กระถางต้นไม้ประดับมุมร้าน (2 จุด ไม่บังทางเดินหรือโต๊ะ)
        for pIdx, pPos in ipairs({ Vector3.new(73, floorY, -114), Vector3.new(144, floorY, -49) }) do
            PartBuilder.makeCylinder(cafe, "CafePot_" .. pIdx, Vector3.new(1.8, 1.9, 1.9),
                CFrame.new(pPos + Vector3.new(0, 0.9, 0)) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(228, 224, 218), Enum.Material.SmoothPlastic)
            PartBuilder.makeCylinder(cafe, "CafePlantLeaves_" .. pIdx, Vector3.new(2.2, 2.8, 2.8),
                CFrame.new(pPos + Vector3.new(0, 2.9, 0)) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(58, 132, 68), Enum.Material.Grass, { CanCollide = false })
        end
    end

    ------------------------------------------------------------------
    -- 3.3 ห้องฝั่งซ้าย (Room_TopLeft & Room_BottomLeft): ผนังด้านใน Z = ±44 เป็นผนังปูนทึบ
    ------------------------------------------------------------------
    local function buildLeftClosedRoomF1(roomName, posX, posZ, sizeX, sizeZ, signText, signColor, accentColor, options)
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
        local doorway = options and options.northDoorway
        if doorway and not isNorthRoom then
            local leftBound = posX - sizeX / 2
            local rightBound = posX + sizeX / 2
            local openLeft = doorway.centerX - doorway.width / 2
            local openRight = doorway.centerX + doorway.width / 2
            local westWidth = openLeft - leftBound
            local eastWidth = rightBound - openRight
            local lintelH = wallH - doorway.height

            PartBuilder.makePart(model, "Wall_InnerConcrete_West", Vector3.new(westWidth, wallH, wallThick),
                CFrame.new(leftBound + westWidth / 2, floorY + wallH / 2, zInnerSolid), wallColor, wallMaterial)
            PartBuilder.makePart(model, "Wall_InnerConcrete_East", Vector3.new(eastWidth, wallH, wallThick),
                CFrame.new(openRight + eastWidth / 2, floorY + wallH / 2, zInnerSolid), wallColor, wallMaterial)
            PartBuilder.makePart(model, "Wall_InnerConcrete_Lintel", Vector3.new(doorway.width, lintelH, wallThick),
                CFrame.new(doorway.centerX, floorY + doorway.height + lintelH / 2, zInnerSolid), wallColor, wallMaterial)

            -- Steel doorway trim + Parking-side signage
            PartBuilder.makePart(model, "DoorJamb_West", Vector3.new(0.4, doorway.height, wallThick + 0.3),
                CFrame.new(openLeft - 0.15, floorY + doorway.height / 2, zInnerSolid), frameMetal, Enum.Material.Metal)
            PartBuilder.makePart(model, "DoorJamb_East", Vector3.new(0.4, doorway.height, wallThick + 0.3),
                CFrame.new(openRight + 0.15, floorY + doorway.height / 2, zInnerSolid), frameMetal, Enum.Material.Metal)
            PartBuilder.makePart(model, "DoorHeader_Steel", Vector3.new(doorway.width + 1.0, 0.5, wallThick + 0.4),
                CFrame.new(doorway.centerX, floorY + doorway.height + 0.25, zInnerSolid), frameMetal, Enum.Material.Metal)
            PartBuilder.makeSign(model, "Sign_ParkingDoor102",
                "🔐 SECURITY CONTROL ROOM // ห้อง 102\nKEYCARD ACCESS REQUIRED",
                Vector3.new(13, 3.0, 0.18),
                Vector3.new(doorway.centerX, floorY + doorway.height + 2.4, zInnerSolid - wallThick / 2 - 0.12),
                Enum.NormalId.Front, Color3.fromRGB(28, 34, 46), Color3.fromRGB(255, 225, 130))
        else
            PartBuilder.makePart(model, "Wall_InnerConcreteSolid", Vector3.new(sizeX, wallH, wallThick),
                CFrame.new(posX, floorY + wallH / 2, zInnerSolid), wallColor, wallMaterial)
        end

        if options and options.interior == "SecurityRoom102" then
            local darkSteel = Color3.fromRGB(34, 38, 46)
            local charcoalMetal = Color3.fromRGB(22, 24, 30)
            local deadScreenColor = Color3.fromRGB(16, 18, 24)
            local crackLineColor = Color3.fromRGB(115, 125, 138)
            local paperWhite = Color3.fromRGB(236, 232, 222)
            local folderColors = {
                Color3.fromRGB(186, 152, 92),
                Color3.fromRGB(48, 74, 118),
                Color3.fromRGB(145, 48, 48),
            }

            local function buildBrokenMonitor(prefix, cf, scale)
                local s = scale or 1
                PartBuilder.makePart(model, prefix .. "_Bezel", Vector3.new(2.2 * s, 1.45 * s, 0.2 * s),
                    cf, charcoalMetal, Enum.Material.Metal)
                PartBuilder.makePart(model, prefix .. "_DeadGlass", Vector3.new(1.95 * s, 1.2 * s, 0.08 * s),
                    cf * CFrame.new(0, 0, -0.09 * s), deadScreenColor, Enum.Material.Glass, { CanCollide = false })
                PartBuilder.makePart(model, prefix .. "_CrackA", Vector3.new(1.4 * s, 0.06 * s, 0.09 * s),
                    cf * CFrame.new(0.1 * s, 0.05 * s, -0.1 * s) * CFrame.Angles(0, 0, math.rad(34)),
                    crackLineColor, Enum.Material.SmoothPlastic, { CanCollide = false })
                PartBuilder.makePart(model, prefix .. "_CrackB", Vector3.new(0.95 * s, 0.05 * s, 0.09 * s),
                    cf * CFrame.new(-0.2 * s, -0.15 * s, -0.1 * s) * CFrame.Angles(0, 0, math.rad(-42)),
                    crackLineColor, Enum.Material.SmoothPlastic, { CanCollide = false })
            end

            local function buildOverturnedChair(prefix, pos, rotAngles)
                local baseCF = CFrame.new(pos) * rotAngles
                PartBuilder.makePart(model, prefix .. "_Seat", Vector3.new(2.1, 0.35, 2.0),
                    baseCF, darkSteel, Enum.Material.Fabric)
                PartBuilder.makePart(model, prefix .. "_Back", Vector3.new(2.0, 2.2, 0.32),
                    baseCF * CFrame.new(0, 1.15, 0.9), darkSteel, Enum.Material.Fabric)
                PartBuilder.makePart(model, prefix .. "_Stem", Vector3.new(0.32, 1.3, 0.32),
                    baseCF * CFrame.new(0, -0.75, 0), charcoalMetal, Enum.Material.Metal)
            end

            -- พื้นห้องมืดและคราบความเสียหายจากการถูกรื้อค้น
            PartBuilder.makePart(model, "Room102_DarkFloor", Vector3.new(sizeX - 4, 0.04, sizeZ - 4),
                CFrame.new(posX, floorY + 0.02, posZ), Color3.fromRGB(26, 28, 34), Enum.Material.SmoothPlastic, { CanCollide = false })

            -- ม่าน/บานเกล็ดทึบปิดหน้าต่างด้านใต้ (Z = 117.4) ทำให้ห้องมืดเหมือนไฟดับทั้งห้อง (มีช่องบานหักเอียง 2 จุด)
            for idx, bx in ipairs({ -140, -124, -109, -94, -78 }) do
                local brokenBlind = (idx == 2 or idx == 4)
                PartBuilder.makePart(model, "Room102_BlackoutBlind_" .. idx, Vector3.new(14.5, 11.8, 0.25),
                    CFrame.new(bx, floorY + 8.6, 117.4) * CFrame.Angles(0, 0, math.rad(brokenBlind and (idx == 2 and 6 or -8) or 0)),
                    Color3.fromRGB(20, 22, 26), Enum.Material.Metal)
            end

            -- โต๊ะ CCTV หลัก และโต๊ะ Security Override (คงพื้นที่วาง Terminal/Console กลางโต๊ะให้กด [E] ได้สะดวก)
            PartBuilder.makePart(model, "Room102_CCTVDesk", Vector3.new(14, 3.6, 5.5),
                CFrame.new(-122, floorY + 1.8, 74), Color3.fromRGB(36, 40, 48), Enum.Material.Metal)
            PartBuilder.makePart(model, "Room102_OverrideDesk", Vector3.new(12, 3.6, 5.5),
                CFrame.new(-96, floorY + 1.8, 74), Color3.fromRGB(36, 40, 48), Enum.Material.Metal)

            -- จอคอมและเคสพีซีพังที่มุมซ้าย/ขวาของโต๊ะหลัก (ไม่บัง M1_CCTVTerminal และ M1_SecurityOverrideConsole)
            buildBrokenMonitor("Room102_CCTVBrokenSideMon",
                CFrame.new(-127.3, floorY + 4.35, 74.3) * CFrame.Angles(math.rad(-18), math.rad(24), math.rad(16)), 0.9)
            PartBuilder.makePart(model, "Room102_CCTVTippedTower", Vector3.new(0.95, 1.9, 1.8),
                CFrame.new(-116.5, floorY + 4.1, 74.8) * CFrame.Angles(0, math.rad(-16), math.rad(72)),
                charcoalMetal, Enum.Material.Metal)
            buildBrokenMonitor("Room102_OverrideBrokenSideMon",
                CFrame.new(-91.2, floorY + 4.15, 74.2) * CFrame.Angles(math.rad(-35), math.rad(-28), math.rad(-22)), 0.85)
            PartBuilder.makePart(model, "Room102_BrokenKeyboard", Vector3.new(1.8, 0.14, 0.72),
                CFrame.new(-100.5, floorY + 3.68, 72.1) * CFrame.Angles(0, math.rad(28), math.rad(-6)),
                charcoalMetal, Enum.Material.SmoothPlastic)

            -- โซนคอมพิวเตอร์พังเพิ่มเติม (ฝั่งตะวันตก X = -140 และมุมตะวันตกเฉียงเหนือ X = -136, Z = 54)
            PartBuilder.makePart(model, "Room102_WestStationDesk", Vector3.new(5.5, 3.6, 22),
                CFrame.new(-141, floorY + 1.8, 78), Color3.fromRGB(36, 40, 48), Enum.Material.Metal)
            buildBrokenMonitor("Room102_WestBrokenMon_1",
                CFrame.new(-140.5, floorY + 4.4, 71) * CFrame.Angles(0, math.rad(-75), math.rad(18)), 1.05)
            buildBrokenMonitor("Room102_WestBrokenMon_2",
                CFrame.new(-141.2, floorY + 3.95, 79.5) * CFrame.Angles(math.rad(76), math.rad(-88), 0), 1.0)
            buildBrokenMonitor("Room102_WestBrokenMon_3",
                CFrame.new(-140.4, floorY + 4.4, 86.5) * CFrame.Angles(math.rad(-12), math.rad(-105), math.rad(-20)), 0.95)
            PartBuilder.makePart(model, "Room102_WestDeadWallRack", Vector3.new(0.8, 6.2, 16.0),
                CFrame.new(-147.2, floorY + 9.0, 78), charcoalMetal, Enum.Material.Metal)
            for idx, wz in ipairs({ 72.5, 78.0, 83.5 }) do
                local tilt = (idx == 2) and math.rad(16) or 0
                buildBrokenMonitor("Room102_WallCCTVDead_" .. idx,
                    CFrame.new(-146.5, floorY + 9.0 - (idx == 2 and 0.6 or 0), wz) * CFrame.Angles(tilt, math.rad(-90), 0), 1.35)
            end

            PartBuilder.makePart(model, "Room102_NWBrokenDesk", Vector3.new(13, 3.6, 5.0),
                CFrame.new(-136, floorY + 1.8, 54), Color3.fromRGB(36, 40, 48), Enum.Material.Metal)
            buildBrokenMonitor("Room102_NWBrokenMon",
                CFrame.new(-136, floorY + 4.05, 54.4) * CFrame.Angles(math.rad(68), math.rad(18), 0), 1.0)
            PartBuilder.makePart(model, "Room102_NWFallenTower", Vector3.new(1.0, 2.1, 2.0),
                CFrame.new(-131.5, floorY + 0.55, 58.2) * CFrame.Angles(math.rad(10), math.rad(36), math.rad(86)),
                charcoalMetal, Enum.Material.Metal)

            -- ตู้เอกสารและชั้นวางที่ถูกรื้อค้น: ลิ้นชักถูกดึงค้าง, ตู้ล้มคว่ำ, เก้าอี้ล้ม และกองเอกสารเกลื่อนพื้น
            PartBuilder.makePart(model, "Room102_BackCabinet", Vector3.new(28, 8.5, 2.8),
                CFrame.new(-109, floorY + 4.25, 92), Color3.fromRGB(48, 54, 62), Enum.Material.Metal)
            for idx, dx in ipairs({ -119, -113, -106, -99 }) do
                local pullOut = (idx % 2 == 0) and 2.1 or 1.4
                local skewY = (idx == 3) and -0.45 or 0
                PartBuilder.makePart(model, "Room102_PulledDrawer_" .. idx, Vector3.new(4.8, 1.3, 2.4),
                    CFrame.new(dx, floorY + 2.2 + (idx % 2) * 2.2 + skewY, 92 - pullOut) * CFrame.Angles(math.rad(idx == 3 and 14 or 4), math.rad((idx - 2) * 3), 0),
                    darkSteel, Enum.Material.Metal)
            end
            PartBuilder.makePart(model, "Room102_FallenDrawer", Vector3.new(4.6, 0.9, 2.4),
                CFrame.new(-103, floorY + 0.45, 86.2) * CFrame.Angles(0, math.rad(26), 0),
                darkSteel, Enum.Material.Metal)

            -- ตู้เหล็กฝั่งตะวันออกและล็อกเกอร์ที่ถูกล้มคว่ำฝั่งใต้
            PartBuilder.makePart(model, "Room102_EastServerRack", Vector3.new(3.2, 9.5, 7.0),
                CFrame.new(-74.0, floorY + 4.75, 98), charcoalMetal, Enum.Material.Metal)
            PartBuilder.makePart(model, "Room102_OpenRackDoor", Vector3.new(0.25, 8.8, 3.0),
                CFrame.new(-76.3, floorY + 4.75, 95.8) * CFrame.Angles(0, math.rad(48), 0),
                darkSteel, Enum.Material.Metal)
            PartBuilder.makePart(model, "Room102_RansackedCabinetSW", Vector3.new(3.6, 8.2, 6.0),
                CFrame.new(-144, floorY + 4.1, 104), Color3.fromRGB(48, 54, 62), Enum.Material.Metal)
            PartBuilder.makePart(model, "Room102_ToppledLocker", Vector3.new(3.0, 9.0, 4.2),
                CFrame.new(-126, floorY + 1.5, 106) * CFrame.Angles(math.rad(6), math.rad(28), math.rad(88)),
                Color3.fromRGB(52, 58, 66), Enum.Material.Metal)
            PartBuilder.makePart(model, "Room102_ArchiveCabinetSE", Vector3.new(8.0, 7.6, 3.2),
                CFrame.new(-86, floorY + 3.8, 109), Color3.fromRGB(48, 54, 62), Enum.Material.Metal)

            -- เก้าอี้สำนักงานล้ม/ถูกผลักกระเด็น (เว้นแนวเดิน X = -117..-101, Z = 46..70 โล่งเดินสะดวก)
            buildOverturnedChair("Room102_ChairFallen_W", Vector3.new(-121.5, floorY + 1.05, 62.5),
                CFrame.Angles(math.rad(82), math.rad(35), math.rad(-20)))
            buildOverturnedChair("Room102_ChairShoved_E", Vector3.new(-87.5, floorY + 1.55, 65.5),
                CFrame.Angles(math.rad(-14), math.rad(132), 0))
            buildOverturnedChair("Room102_ChairFallen_S", Vector3.new(-103.5, floorY + 1.05, 99.5),
                CFrame.Angles(math.rad(-78), math.rad(-42), math.rad(18)))

            -- ลังเอกสารล้ม + กระดาษและแฟ้มคดีกระจัดกระจายเกลื่อนห้อง (CanCollide = false ไม่สะดุดเท้า)
            for idx, boxPos in ipairs({ Vector3.new(-116, floorY + 0.9, 85), Vector3.new(-95, floorY + 0.9, 88) }) do
                PartBuilder.makePart(model, "Room102_RansackedBox_" .. idx, Vector3.new(2.2, 1.8, 2.6),
                    CFrame.new(boxPos) * CFrame.Angles(math.rad(80), math.rad(idx * 55), 0),
                    Color3.fromRGB(142, 114, 78), Enum.Material.Cardboard, { CanCollide = false })
            end
            for idx = 1, 24 do
                local angle = idx * 47
                local px = -138 + ((idx * 17) % 58)
                local pz = 58 + ((idx * 23) % 48)
                -- รักษาทางเดินหน้าประตู X = -115..-103, Z = 46..56 ให้โล่งตา
                if not (px > -115 and px < -103 and pz < 58) then
                    local isFolder = (idx % 3 == 0)
                    local col = isFolder and folderColors[(idx % #folderColors) + 1] or paperWhite
                    local sz = isFolder and Vector3.new(1.15, 0.05, 1.45) or Vector3.new(0.88, 0.025, 1.15)
                    PartBuilder.makePart(model, "Room102_Paper_" .. idx, sz,
                        CFrame.new(px, floorY + 0.05 + (idx % 2) * 0.015, pz) * CFrame.Angles(0, math.rad(angle), 0),
                        col, Enum.Material.SmoothPlastic, { CanCollide = false })
                end
            end

            -- ระบบไฟฟ้าดับ: โคมไฟเพดานดับสนิท (มี 1 โคมห้อยเอียง), ตู้เบรกเกอร์ทริปไหม้ + ไฟฉุกเฉินแดง HorrorEmergencyLight
            PartBuilder.makePart(model, "Room102_DeadCeilingLamp_L", Vector3.new(6.0, 0.45, 1.6),
                CFrame.new(-122, floorY + wallH - 0.3, 70), charcoalMetal, Enum.Material.Metal)
            PartBuilder.makePart(model, "Room102_BrokenHangingLamp", Vector3.new(6.2, 0.45, 1.6),
                CFrame.new(-98, floorY + wallH - 1.5, 82) * CFrame.Angles(math.rad(-20), math.rad(8), math.rad(14)),
                charcoalMetal, Enum.Material.Metal)
            PartBuilder.makePart(model, "Room102_DeadCeilingLamp_E", Vector3.new(5.5, 0.45, 1.6),
                CFrame.new(-84, floorY + wallH - 0.3, 66), charcoalMetal, Enum.Material.Metal)

            -- ตู้เบรกเกอร์ที่ทริปและเปิดอ้าอยู่บนผนังตะวันออก (X = -70.6, Z = 62)
            PartBuilder.makePart(model, "Room102_TrippedBreakerBox", Vector3.new(0.55, 3.6, 2.8),
                CFrame.new(-70.5, floorY + 5.8, 62), darkSteel, Enum.Material.Metal)
            PartBuilder.makePart(model, "Room102_TrippedBreakerDoor", Vector3.new(0.18, 3.4, 2.6),
                CFrame.new(-71.6, floorY + 5.8, 60.4) * CFrame.Angles(0, math.rad(-58), 0),
                Color3.fromRGB(48, 54, 64), Enum.Material.Metal)
            local breakerLed = PartBuilder.makePart(model, "Room102_BreakerFaultLED", Vector3.new(0.18, 0.28, 0.6),
                CFrame.new(-70.82, floorY + 6.7, 62), Color3.fromRGB(225, 45, 40), Enum.Material.Neon, { CanCollide = false })
            local breakerLight = Instance.new("PointLight")
            breakerLight.Name = "Room102_BreakerFaultLight"
            breakerLight.Color = Color3.fromRGB(225, 45, 40)
            breakerLight.Range = 12
            breakerLight.Brightness = 0.65
            breakerLight:SetAttribute("HorrorEmergencyLight", true)
            breakerLight.Parent = breakerLed

            local emergPart = PartBuilder.makePart(model, "Room102_EmergencyLamp", Vector3.new(1.4, 0.4, 1.4),
                CFrame.new(-109, floorY + wallH - 1.2, 58), Color3.fromRGB(225, 55, 48), Enum.Material.Neon, { CanCollide = false })
            local emergLight = Instance.new("PointLight")
            emergLight.Name = "Room102_EmergencyLight"
            emergLight.Color = Color3.fromRGB(235, 65, 55)
            emergLight.Range = 32
            emergLight.Brightness = 0.88
            emergLight:SetAttribute("HorrorEmergencyLight", true)
            emergLight.Parent = emergPart
        end

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
        "ห้องควบคุมความปลอดภัย (ห้อง 102)\nSECURITY CONTROL ROOM (KEYCARD ACCESS)",
        Color3.fromRGB(40, 56, 74), Color3.fromRGB(45, 175, 225), {
            northDoorway = { centerX = -109, width = 8, height = 11 },
            interior = "SecurityRoom102",
        })
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

    ------------------------------------------------------------------
    -- 6. แถบล่าง (หน้าตึก Z = +44..+120): บันได (ซ้าย) | ทางเข้าออก (กลาง) | ลิฟ (ขวา)
    ------------------------------------------------------------------
    local bottomCore = Instance.new("Folder")
    bottomCore.Name = "BottomCirculationCore"
    bottomCore.Parent = floor1

    buildInBuildingStair(bottomCore, Layout.STAIRS.Front)
    buildInBuildingLift(bottomCore, Layout.LIFTS.Front)

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

-- ฟังก์ชันสำหรับเปิดใช้งานประตูแบบมีชีวิตทุกบานของชั้น 1 เมื่อใช้โหมด Static Map
function Floor1_Lobby.ensureInteractiveDoors(parent)
    local f1 = parent or Workspace:FindFirstChild("Floor_1_Building40")
    if not f1 then return end

    local bankRoom = f1:FindFirstChild("Room_Bank_BottomRight")
    if bankRoom then
        -- 1. Front Bank Double Door (หน้าธนาคาร)
        local oldFront = bankRoom:FindFirstChild("FrontBankDoor_InteractiveDoor")
        if oldFront then oldFront:Destroy() end
        local zWallFront = 120 - 1.2 / 2
        InteractiveDoorBuilder.buildDoubleGlassDoor(bankRoom, "FrontBankDoor", {
            axis = "X",
            doorCenterAlong = 95,
            fixedPos = zWallFront,
            inDirSign = -1,
            floorY = 1.0,
            openW = 10.0,
            leafW = 4.85,
            openH = 11.2,
            leafH = 10.8,
            glassTopH = 14.5,
            maxHP = 130,
            openDeg = 82,
            initialOpen = false,
            doorLabel = "ประตูทางเข้าธนาคารกรุงเทพ (ด้านหน้า)",
        })

        -- 2. East Bank Double Door (ทางเข้าด้านข้างธนาคาร)
        local oldEast = bankRoom:FindFirstChild("EastBankDoor_InteractiveDoor")
        if oldEast then oldEast:Destroy() end
        local xWallEast = 150 - 1.2 / 2
        InteractiveDoorBuilder.buildDoubleGlassDoor(bankRoom, "EastBankDoor", {
            axis = "Z",
            doorCenterAlong = 82,
            fixedPos = xWallEast,
            inDirSign = -1,
            floorY = 1.0,
            openW = 12.0,
            leafW = 5.85,
            openH = 11.6,
            leafH = 11.2,
            glassTopH = 14.5,
            maxHP = 130,
            openDeg = 82,
            initialOpen = false,
            doorLabel = "ประตูทางเข้าธนาคาร (ฝั่งตะวันออก)",
        })

        -- 3. Manager Office Single Door (ประตูห้องผู้จัดการธนาคาร)
        local oldMgrDoor = bankRoom:FindFirstChild("BankManagerOfficeDoor_Door")
        if oldMgrDoor then oldMgrDoor:Destroy() end
        local darkWalnut = Color3.fromRGB(48, 32, 24)
        InteractiveDoorBuilder.buildSingleDoor(bankRoom, "BankManagerOfficeDoor", {
            axis = "X",
            doorCenterAlong = 132,
            fixedPos = 72,
            inDirSign = -1,
            hingeSide = -1,
            floorY = 1.0,
            openW = 6.0,
            openH = 10.5,
            thick = 0.36,
            style = "ManagerOffice",
            color = darkWalnut,
            material = Enum.Material.Wood,
            maxHP = 180,
            openDeg = 85,
            initialOpen = false,
            doorLabel = "ห้องผู้จัดการสาขา (Manager's Office)",
        })
    end

    local cafe = f1:FindFirstChild("OpenCafe_TopRight")
    if cafe then
        -- 4. East Cafe Door
        local oldEastCafe = cafe:FindFirstChild("EastCafeDoor_InteractiveDoor")
        if oldEastCafe then oldEastCafe:Destroy() end
        local xEast = 150 - 1.2 / 2
        InteractiveDoorBuilder.buildDoubleGlassDoor(cafe, "EastCafeDoor", {
            axis = "Z",
            doorCenterAlong = -78,
            fixedPos = xEast,
            inDirSign = -1,
            floorY = 1.0,
            openW = 10.0,
            leafW = 4.8,
            openH = 14.5,
            leafH = 14.1,
            glassTopH = 16.7,
            maxHP = 120,
            openDeg = 80,
            initialOpen = false,
            doorLabel = "ประตูคาเฟ่ (ทางเข้าด้านนอกอาคาร)",
        })

        -- 5. North Cafe Door
        local oldNorthCafe = cafe:FindFirstChild("NorthCafeDoor_InteractiveDoor")
        if oldNorthCafe then oldNorthCafe:Destroy() end
        local zNorth = -120 + 1.2 / 2
        InteractiveDoorBuilder.buildDoubleGlassDoor(cafe, "NorthCafeDoor", {
            axis = "X",
            doorCenterAlong = 132,
            fixedPos = zNorth,
            inDirSign = 1,
            floorY = 1.0,
            openW = 10.0,
            leafW = 4.8,
            openH = 14.5,
            leafH = 14.1,
            glassTopH = 16.7,
            maxHP = 120,
            openDeg = 80,
            initialOpen = false,
            doorLabel = "ประตูคาเฟ่ (ทางเข้าด้านหลังตึก)",
        })
    end
end

return Floor1_Lobby
