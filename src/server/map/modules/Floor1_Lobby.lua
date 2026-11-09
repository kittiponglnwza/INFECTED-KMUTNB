--[[
    Floor1_Lobby.lua
    โมดูลสร้างชั้น 1: ล็อบบี้หลักอาคาร 40 ปี มจพ. (อาคาร 77)
    จุดเด่นตามข้อมูลจริงของมหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ:
      1. ธนาคารกรุงเทพ สาขา มจพ. (Bangkok Bank) & ตู้ ATM หลากสี (BBL, SCB, KBank)
      2. ศูนย์บริการนักศึกษาครบวงจร (Student One-Stop Service Center)
      3. โถงทางเข้าหลักกระจกสูงโปร่ง (Curtain Wall) พร้อมเคาน์เตอร์ประชาสัมพันธ์
      4. โถงลิฟต์โดยสาร 4 ตัว (Elevator Bank) พร้อมไฟบอกชั้นดิจิทัล
      5. บันไดคู่เชื่อมขึ้นชั้น 2 (Grand Twin Stairs) ปิดกั้นด้วยประตูกันซอมบี้
      6. ประตูหนีไฟฉุกเฉิน (Emergency Exit)
      7. จุดซื้อปืนติดผนัง (Wall Buys) ปืน Classic, Shorty, Ghost
      8. แนวกั้นไม้ Barricades ตามหน้าต่างกระจก
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local Floor1_Lobby = {}

function Floor1_Lobby.build(building)
    local floor1 = Instance.new("Model")
    floor1.Name = "Floor_1_MainLobby"
    floor1.Parent = building

    local bW = PartBuilder.WIDTH          -- 135 studs
    local bL = PartBuilder.LENGTH         -- 120 studs
    local fH = PartBuilder.FLOOR_HEIGHT   -- 16 studs
    local f1BaseY = PartBuilder.FLOOR1_Y  -- 4 studs

    ------------------------------------------------------------------
    -- 1. พื้นหินแกรนิตโต้ขัดมันชั้น 1 (Polished Granite Floor)
    ------------------------------------------------------------------
    local floorBase = PartBuilder.makePart(
        floor1,
        "Floor1_MainTile",
        Vector3.new(bW, 1.5, bL),
        CFrame.new(0, f1BaseY, 0),
        PartBuilder.COLORS.tileLight,
        Enum.Material.SmoothPlastic
    )

    -- เส้นลวดลายกระเบื้องตัดขอบสไตล์ มจพ. (Orange/Maroon Floor Inlays)
    PartBuilder.makePart(
        floor1,
        "FloorInlay_Maroon",
        Vector3.new(bW - 20, 0.05, 4),
        CFrame.new(0, f1BaseY + 0.8, 15),
        PartBuilder.COLORS.maroon,
        Enum.Material.SmoothPlastic
    )
    PartBuilder.makePart(
        floor1,
        "FloorInlay_Orange",
        Vector3.new(bW - 20, 0.05, 1.5),
        CFrame.new(0, f1BaseY + 0.8, 12),
        PartBuilder.COLORS.orange,
        Enum.Material.SmoothPlastic
    )

    -- ผนังทึบด้านข้างและด้านหลังชั้น 1
    PartBuilder.makePart(floor1, "OuterWall_L", Vector3.new(1.8, fH, bL), CFrame.new(-bW/2, f1BaseY + fH/2, 0), PartBuilder.COLORS.cream)
    PartBuilder.makePart(floor1, "OuterWall_R", Vector3.new(1.8, fH, bL), CFrame.new(bW/2, f1BaseY + fH/2, 0), PartBuilder.COLORS.cream)
    PartBuilder.makePart(floor1, "OuterWall_Rear", Vector3.new(bW, fH, 1.8), CFrame.new(0, f1BaseY + fH/2, -bL/2), PartBuilder.COLORS.cream)

    ------------------------------------------------------------------
    -- 2. แผงกระจกบานใหญ่หน้าทางเข้า (Glass Curtain Wall) & ประตูอัตโนมัติ
    ------------------------------------------------------------------
    local entranceFolder = Instance.new("Folder")
    entranceFolder.Name = "GrandEntrance"
    entranceFolder.Parent = floor1

    -- กระจกซีกซ้าย
    PartBuilder.makePart(
        entranceFolder,
        "CurtainWall_Left",
        Vector3.new((bW - 28)/2, fH, 1.2),
        CFrame.new(-(bW + 28)/4, f1BaseY + fH/2, bL/2),
        PartBuilder.COLORS.glass,
        Enum.Material.Glass,
        { Transparency = 0.55 }
    )
    -- กระจกซีกขวา
    PartBuilder.makePart(
        entranceFolder,
        "CurtainWall_Right",
        Vector3.new((bW - 28)/2, fH, 1.2),
        CFrame.new((bW + 28)/4, f1BaseY + fH/2, bL/2),
        PartBuilder.COLORS.glass,
        Enum.Material.Glass,
        { Transparency = 0.55 }
    )
    -- ซุ้มประตูกระจกบานเลื่อนอัตโนมัติ (Automatic Sliding Doors)
    PartBuilder.makePart(
        entranceFolder,
        "AutoDoorHeader",
        Vector3.new(28, 2.5, 1.8),
        CFrame.new(0, f1BaseY + fH - 1.25, bL/2),
        PartBuilder.COLORS.darkGrey,
        Enum.Material.Metal
    )
    PartBuilder.makePart(
        entranceFolder,
        "AutoDoor_PanelL",
        Vector3.new(12, fH - 2.5, 0.4),
        CFrame.new(-6.5, f1BaseY + (fH - 2.5)/2, bL/2),
        PartBuilder.COLORS.glass,
        Enum.Material.Glass,
        { Transparency = 0.65 }
    )
    PartBuilder.makePart(
        entranceFolder,
        "AutoDoor_PanelR",
        Vector3.new(12, fH - 2.5, 0.4),
        CFrame.new(6.5, f1BaseY + (fH - 2.5)/2, bL/2),
        PartBuilder.COLORS.glass,
        Enum.Material.Glass,
        { Transparency = 0.65 }
    )

    -- โต๊ะประชาสัมพันธ์และรักษาความปลอดภัยกลางโถง (Info Desk)
    local infoDesk = Instance.new("Model")
    infoDesk.Name = "InformationSecurityDesk"
    infoDesk.Parent = entranceFolder

    PartBuilder.makePart(
        infoDesk,
        "InfoCounter",
        Vector3.new(16, 3.8, 6),
        CFrame.new(0, f1BaseY + 1.9, 32),
        PartBuilder.COLORS.darkGrey,
        Enum.Material.SmoothPlastic
    )
    PartBuilder.makePart(
        infoDesk,
        "InfoCounterTop",
        Vector3.new(16.8, 0.6, 6.8),
        CFrame.new(0, f1BaseY + 4.0, 32),
        PartBuilder.COLORS.wood,
        Enum.Material.WoodPlanks
    )
    PartBuilder.makeSign(
        infoDesk,
        "InfoSign",
        "จุดประชาสัมพันธ์ & รักษาความปลอดภัย มจพ.\nINFORMATION & SECURITY DESK",
        Vector3.new(16, 1.6, 0.3),
        Vector3.new(0, f1BaseY + 2.5, 35.1),
        Enum.NormalId.Back,
        PartBuilder.COLORS.maroon
    )
    -- จอคอมพิวเตอร์ประจำจุดตรวจ
    PartBuilder.makePart(infoDesk, "PC_Base", Vector3.new(1.8, 0.3, 1.4), CFrame.new(-3, f1BaseY + 4.4, 32), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
    PartBuilder.makePart(infoDesk, "PC_Screen", Vector3.new(3.0, 2.0, 0.3), CFrame.new(-3, f1BaseY + 5.5, 32), Color3.fromRGB(15, 15, 20), Enum.Material.Glass)

    ------------------------------------------------------------------
    -- 3. ธนาคารกรุงเทพ สาขา มจพ. (BANGKOK BANK BRANCH)
    ------------------------------------------------------------------
    local bank = Instance.new("Model")
    bank.Name = "BangkokBank_Branch"
    bank.Parent = floor1

    local bankX = -bW/2 + 28
    local bankZ = 32

    -- ป้ายชื่อธนาคารกรุงเทพสีน้ำเงินทางการ
    PartBuilder.makeSign(
        bank,
        "BangkokBankSign",
        "ธนาคารกรุงเทพ สาขา มหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ\nBANGKOK BANK // KMUTNB BRANCH",
        Vector3.new(34, 3.8, 0.6),
        Vector3.new(bankX, f1BaseY + 11.5, bankZ + 12),
        Enum.NormalId.Back,
        PartBuilder.COLORS.bblBlue,
        Color3.fromRGB(255, 255, 255)
    )

    -- เคาน์เตอร์บริการฝาก-ถอน (Teller Counter)
    PartBuilder.makePart(
        bank,
        "BankCounterBase",
        Vector3.new(32, 3.8, 4),
        CFrame.new(bankX, f1BaseY + 1.9, bankZ),
        PartBuilder.COLORS.bblNavy,
        Enum.Material.SmoothPlastic
    )
    PartBuilder.makePart(
        bank,
        "BankCounterTop",
        Vector3.new(32.8, 0.6, 4.6),
        CFrame.new(bankX, f1BaseY + 4.0, bankZ),
        PartBuilder.COLORS.tileLight,
        Enum.Material.SmoothPlastic
    )

    -- กระจกนิรภัยกั้นช่องบริการ 3 ช่อง (Teller Security Glass)
    for t = 1, 3 do
        local tX = (bankX - 10) + ((t - 1) * 10)
        PartBuilder.makePart(
            bank,
            "TellerGlass_" .. t,
            Vector3.new(7.5, 4.5, 0.4),
            CFrame.new(tX, f1BaseY + 6.5, bankZ + 0.5),
            PartBuilder.COLORS.glass,
            Enum.Material.Glass,
            { Transparency = 0.6 }
        )
        PartBuilder.makeSign(
            bank,
            "TellerNum_" .. t,
            string.format("ช่องบริการ %d", t),
            Vector3.new(4, 0.8, 0.2),
            Vector3.new(tX, f1BaseY + 8.6, bankZ + 0.7),
            Enum.NormalId.Back,
            PartBuilder.COLORS.bblBlue
        )
    end

    -- เก้าอี้พักคอยลูกค้าธนาคาร (Waiting Tandem Chairs)
    local function makeChairRow(rowZ)
        local rowModel = Instance.new("Model")
        rowModel.Name = "WaitingChairs"
        rowModel.Parent = bank
        PartBuilder.makePart(rowModel, "ChairBeam", Vector3.new(18, 0.5, 0.8), CFrame.new(bankX, f1BaseY + 1.2, rowZ), Color3.fromRGB(80, 85, 90), Enum.Material.Metal)
        for s = 1, 4 do
            local sX = (bankX - 7) + ((s - 1) * 4.6)
            PartBuilder.makePart(rowModel, "ChairSeat_" .. s, Vector3.new(3.5, 0.4, 3.2), CFrame.new(sX, f1BaseY + 1.8, rowZ), PartBuilder.COLORS.bblBlue, Enum.Material.SmoothPlastic)
            PartBuilder.makePart(rowModel, "ChairBack_" .. s, Vector3.new(3.5, 2.4, 0.4), CFrame.new(sX, f1BaseY + 3.0, rowZ - 1.4), PartBuilder.COLORS.bblBlue, Enum.Material.SmoothPlastic)
        end
    end
    makeChairRow(bankZ - 10)
    makeChairRow(bankZ - 18)

    -- ตู้ ATM 3 ตู้ (BBL Blue, SCB Purple, KBank Green)
    local atmConfigs = {
        { Name = "BBL_ATM",   Label = "ATM BBL\nธนาคารกรุงเทพ", Color = PartBuilder.COLORS.bblBlue },
        { Name = "SCB_ATM",   Label = "ATM SCB\nไทยพาณิชย์",     Color = PartBuilder.COLORS.scbPurple },
        { Name = "KBANK_ATM", Label = "ATM K-Bank\nกสิกรไทย",    Color = PartBuilder.COLORS.kbankGreen },
    }
    for i, atm in ipairs(atmConfigs) do
        local aX = -bW/2 + 6 + ((i - 1) * 4.8)
        local aZ = 52
        local atmPart = PartBuilder.makePart(
            bank,
            atm.Name,
            Vector3.new(3.8, 7.5, 3.8),
            CFrame.new(aX, f1BaseY + 3.75, aZ),
            atm.Color,
            Enum.Material.Metal
        )
        -- หน้าจอตู้ ATM เรืองแสง
        PartBuilder.makePart(
            bank,
            atm.Name .. "_Screen",
            Vector3.new(2.4, 2.0, 0.2),
            CFrame.new(aX, f1BaseY + 4.8, aZ - 1.95),
            Color3.fromRGB(230, 245, 255),
            Enum.Material.Neon
        )
        -- ป้ายโลโก้บนตู้
        PartBuilder.makeSign(
            bank,
            atm.Name .. "_Sign",
            atm.Label,
            Vector3.new(3.6, 1.8, 0.3),
            Vector3.new(aX, f1BaseY + 6.8, aZ - 1.95),
            Enum.NormalId.Back,
            atm.Color
        )
    end

    ------------------------------------------------------------------
    -- 4. ศูนย์บริการนักศึกษาครบวงจร (STUDENT ONE-STOP SERVICE CENTER)
    ------------------------------------------------------------------
    local studentCenter = Instance.new("Model")
    studentCenter.Name = "StudentOneStopService"
    studentCenter.Parent = floor1

    local scX = bW/2 - 28
    local scZ = 32

    -- ป้ายชื่อศูนย์บริการนักศึกษา มจพ.
    PartBuilder.makeSign(
        studentCenter,
        "StudentCenterSign",
        "ศูนย์บริการนักศึกษาครบวงจร มจพ.\nKMUTNB STUDENT ONE-STOP SERVICE CENTER",
        Vector3.new(34, 3.8, 0.6),
        Vector3.new(scX, f1BaseY + 11.5, scZ + 12),
        Enum.NormalId.Back,
        PartBuilder.COLORS.maroon
    )

    -- เคาน์เตอร์บริการให้คำปรึกษาและทะเบียนนักศึกษา
    PartBuilder.makePart(
        studentCenter,
        "StudentDeskBase",
        Vector3.new(32, 3.8, 4),
        CFrame.new(scX, f1BaseY + 1.9, scZ),
        PartBuilder.COLORS.darkGrey,
        Enum.Material.SmoothPlastic
    )
    PartBuilder.makePart(
        studentCenter,
        "StudentDeskTop",
        Vector3.new(32.8, 0.6, 4.6),
        CFrame.new(scX, f1BaseY + 4.0, scZ),
        PartBuilder.COLORS.orangeLight,
        Enum.Material.SmoothPlastic
    )

    -- แผงกั้นช่องบริการ 3 ช่อง
    local scServices = { "1. งานทะเบียนและประเมินผล", "2. งานการเงินและทุนการศึกษา", "3. งานสวัสดิการและบัตรนักศึกษา" }
    for i, sTitle in ipairs(scServices) do
        local sX = (scX - 10) + ((i - 1) * 10)
        PartBuilder.makePart(
            studentCenter,
            "ServicePartition_" .. i,
            Vector3.new(0.4, 3.5, 3.5),
            CFrame.new(sX - 4.5, f1BaseY + 5.5, scZ),
            PartBuilder.COLORS.tileLight,
            Enum.Material.SmoothPlastic
        )
        PartBuilder.makeSign(
            studentCenter,
            "ServiceSign_" .. i,
            sTitle,
            Vector3.new(8.5, 0.9, 0.2),
            Vector3.new(sX, f1BaseY + 6.0, scZ + 1.8),
            Enum.NormalId.Back,
            PartBuilder.COLORS.maroon
        )
    end

    -- ตู้กดบัตรคิวอัตโนมัติ (Queue Ticket Kiosk)
    local queueKiosk = PartBuilder.makePart(
        studentCenter,
        "QueueKiosk",
        Vector3.new(2.2, 5.0, 2.2),
        CFrame.new(scX - 18, f1BaseY + 2.5, scZ + 10),
        PartBuilder.COLORS.creamLight,
        Enum.Material.Metal
    )
    PartBuilder.makeSign(
        queueKiosk,
        "QueueSign",
        "กดรับบัตรคิว\nTICKET QUEUE",
        Vector3.new(2.0, 1.2, 0.2),
        Vector3.new(scX - 18, f1BaseY + 4.2, scZ + 8.8),
        Enum.NormalId.Back,
        PartBuilder.COLORS.orange
    )

    -- บอร์ดประกาศข่าวนักศึกษา มจพ. (Bulletin Boards)
    local board = PartBuilder.makePart(
        studentCenter,
        "BulletinBoard",
        Vector3.new(1.2, 7.5, 16),
        CFrame.new(bW/2 - 2, f1BaseY + 5.5, scZ),
        PartBuilder.COLORS.wood,
        Enum.Material.Wood
    )
    PartBuilder.makeSign(
        board,
        "BoardTitle",
        "บอร์ดประชาสัมพันธ์กิจกรรมและทุนการศึกษา มจพ.",
        Vector3.new(0.2, 1.5, 14),
        Vector3.new(bW/2 - 2.8, f1BaseY + 8.5, scZ),
        Enum.NormalId.Left,
        PartBuilder.COLORS.maroon
    )

    ------------------------------------------------------------------
    -- 5. โถงลิฟต์โดยสาร 4 ตัว (ELEVATOR BANK)
    ------------------------------------------------------------------
    local elevatorFolder = Instance.new("Folder")
    elevatorFolder.Name = "ElevatorLobby"
    elevatorFolder.Parent = floor1

    local elZ = -bL/2 + 24
    for el = 1, 4 do
        local elX = -17.5 + ((el - 1) * 11.5)
        -- บานประตูลิฟต์สแตนเลสขัดเงา
        PartBuilder.makePart(
            elevatorFolder,
            string.format("ElevatorDoor_F1_%d", el),
            Vector3.new(6.8, 10.5, 0.4),
            CFrame.new(elX, f1BaseY + 5.25, elZ),
            PartBuilder.COLORS.steel,
            Enum.Material.Metal
        )
        -- ป้ายดิจิทัลบอกตำแหน่งชั้น 1 (Digital Floor Indicator LED)
        PartBuilder.makeSign(
            elevatorFolder,
            string.format("FloorDisplay_%d", el),
            "[ 1 ] ▲",
            Vector3.new(2.8, 1.2, 0.2),
            Vector3.new(elX, f1BaseY + 11.8, elZ + 0.3),
            Enum.NormalId.Back,
            Color3.fromRGB(20, 20, 25),
            Color3.fromRGB(255, 140, 20)
        )
        -- กล่องปุ่มกดเรียกลิฟต์
        if el == 2 or el == 4 then
            PartBuilder.makePart(
                elevatorFolder,
                string.format("CallButton_%d", el),
                Vector3.new(0.6, 1.4, 0.2),
                CFrame.new(elX + 4.8, f1BaseY + 4.8, elZ + 0.3),
                Color3.fromRGB(230, 230, 230),
                Enum.Material.Metal
            )
        end
    end

    ------------------------------------------------------------------
    -- 6. บันไดคู่เชื่อมขึ้นชั้น 2 (GRAND TWIN STAIRCASE)
    ------------------------------------------------------------------
    local stairFolder = Instance.new("Folder")
    stairFolder.Name = "GrandStaircase"
    stairFolder.Parent = floor1

    local stairStartX = 34
    local stepsCount = 18
    local stepDepth = 2.0
    local stepRise = fH / stepsCount

    for s = 1, stepsCount do
        local sY = f1BaseY + (s * stepRise)
        local sZ = -5 - (s * stepDepth)
        PartBuilder.makePart(
            stairFolder,
            "StairStep_" .. s,
            Vector3.new(16, stepRise + 0.2, stepDepth),
            CFrame.new(stairStartX, sY - stepRise/2, sZ),
            PartBuilder.COLORS.warmGrey,
            Enum.Material.Concrete
        )
    end

    -- ราวกันตกบันไดสแตนเลส (Stair Handrails)
    local handrailLen = stepsCount * stepDepth
    local handrailAngle = math.atan(fH / handrailLen)
    PartBuilder.makePart(
        stairFolder,
        "Handrail_L",
        Vector3.new(0.4, 0.6, handrailLen + 4),
        CFrame.new(stairStartX - 8.2, f1BaseY + fH/2 + 2.5, -5 - handrailLen/2) * CFrame.Angles(handrailAngle, 0, 0),
        PartBuilder.COLORS.steel,
        Enum.Material.Metal
    )
    PartBuilder.makePart(
        stairFolder,
        "Handrail_R",
        Vector3.new(0.4, 0.6, handrailLen + 4),
        CFrame.new(stairStartX + 8.2, f1BaseY + fH/2 + 2.5, -5 - handrailLen/2) * CFrame.Angles(handrailAngle, 0, 0),
        PartBuilder.COLORS.steel,
        Enum.Material.Metal
    )

    -- ประตูชัตเตอร์เหล็กกั้นชั้น 2 พร้อมป้ายปลดล็อก (Security Shutter to Floor 2)
    local gate = PartBuilder.makePart(
        stairFolder,
        "Gate_To_Floor2",
        Vector3.new(16, 12, 1.2),
        CFrame.new(stairStartX, f1BaseY + fH + 4, -5 - handrailLen),
        PartBuilder.COLORS.darkGrey,
        Enum.Material.Metal
    )
    PartBuilder.makeSign(
        gate,
        "GateSign",
        "ทางขึ้นชั้น 2: โรงอาหาร มจพ. (CANTEEN)\n[ ปลดล็อก 750 แต้ม // UNLOCK 750 PTS ]",
        Vector3.new(15, 3.2, 0.3),
        Vector3.new(stairStartX, f1BaseY + fH + 6, -5 - handrailLen + 0.8),
        Enum.NormalId.Back,
        PartBuilder.COLORS.orange
    )

    ------------------------------------------------------------------
    -- 7. บันไดหนีไฟฉุกเฉิน (EMERGENCY FIRE EXIT)
    ------------------------------------------------------------------
    local fireExit = Instance.new("Model")
    fireExit.Name = "FireExit_F1"
    fireExit.Parent = floor1

    PartBuilder.makePart(
        fireExit,
        "FireDoor",
        Vector3.new(4.5, 9, 0.6),
        CFrame.new(bW/2 - 18, f1BaseY + 4.5, -bL/2 + 20),
        PartBuilder.COLORS.maroon,
        Enum.Material.Metal
    )
    PartBuilder.makeSign(
        fireExit,
        "FireExitSign",
        "EXIT\nทางหนีไฟฉุกเฉิน",
        Vector3.new(3.5, 1.4, 0.2),
        Vector3.new(bW/2 - 18.4, f1BaseY + 10.2, -bL/2 + 20),
        Enum.NormalId.Left,
        Color3.fromRGB(15, 175, 60),
        Color3.fromRGB(255, 255, 255)
    )

    ------------------------------------------------------------------
    -- 8. ระบบไฟส่องสว่างเพดานชั้น 1 (Ceiling Recessed Lighting Panels)
    ------------------------------------------------------------------
    local lightsFolder = Instance.new("Folder")
    lightsFolder.Name = "CeilingLights"
    lightsFolder.Parent = floor1

    for lx = -bW/2 + 20, bW/2 - 20, 24 do
        for lz = -bL/2 + 20, bL/2 - 20, 24 do
            PartBuilder.addPointLight(
                lightsFolder,
                string.format("Light_F1_%d_%d", math.floor(lx), math.floor(lz)),
                Vector3.new(lx, f1BaseY + fH - 0.4, lz),
                Color3.fromRGB(255, 248, 235),
                28,
                1.4
            )
        end
    end

    ------------------------------------------------------------------
    -- 9. จุดซื้อปืนติดผนังชั้น 1 (VALORANT WALL BUYS: CLASSIC, SHORTY, GHOST)
    ------------------------------------------------------------------
    local wallBuysFolder = Instance.new("Folder")
    wallBuysFolder.Name = "WallBuys_Floor1"
    wallBuysFolder.Parent = floor1

    local function createWallBuySpot(weaponName, cost, pos, rotY)
        local plate = PartBuilder.makePart(
            wallBuysFolder,
            "WallBuy_" .. weaponName,
            Vector3.new(5.5, 3.6, 0.3),
            CFrame.new(pos) * CFrame.Angles(0, rotY, 0),
            Color3.fromRGB(24, 28, 36),
            Enum.Material.Metal
        )
        plate:SetAttribute("WeaponType", weaponName)
        plate:SetAttribute("Cost", cost)

        local outline = Instance.new("SelectionBox")
        outline.Color3 = (cost == 0) and Color3.fromRGB(0, 255, 220) or Color3.fromRGB(255, 200, 50)
        outline.Adornee = plate
        outline.Parent = plate

        local gui = Instance.new("SurfaceGui")
        gui.Face = Enum.NormalId.Back
        gui.Parent = plate

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = (cost == 0) and Color3.fromRGB(0, 255, 220) or Color3.fromRGB(255, 220, 80)
        txt.TextScaled = true
        txt.Font = Enum.Font.GothamBold
        txt.Text = string.format("🔫 %s\n[%s PTS]", weaponName:upper(), (cost == 0) and "FREE" or tostring(cost))
        txt.Parent = gui

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = (cost == 0) and "หยิบปืนเริ่มต้น" or ("ซื้อ " .. weaponName)
        prompt.ObjectText = (cost == 0) and "ฟรี (0 Points)" or (cost .. " Points")
        prompt.HoldDuration = 0.4
        prompt.MaxActivationDistance = 9
        prompt.Parent = plate
    end

    -- ปืน Classic ฟรี (จุดเริ่มต้น)
    createWallBuySpot("Classic", 0, Vector3.new(-8, f1BaseY + 4.5, 58), math.rad(180))
    -- ปืนลูกซอง Shorty 300 แต้ม
    createWallBuySpot("Shorty", 300, Vector3.new(-bW/2 + 2, f1BaseY + 4.5, 10), math.rad(90))
    -- ปืนพกเก็บเสียง Ghost 500 แต้ม
    createWallBuySpot("Ghost", 500, Vector3.new(bW/2 - 2, f1BaseY + 4.5, 10), math.rad(-90))

    ------------------------------------------------------------------
    -- 10. แนวกั้นไม้หน้าต่างชั้น 1 (BARRICADES FOR FLOOR 1)
    ------------------------------------------------------------------
    local barricadesFolder = Instance.new("Folder")
    barricadesFolder.Name = "Barricades_Floor1"
    barricadesFolder.Parent = floor1

    local function createBarricadeOpening(name, pos, rotY)
        local bModel = Instance.new("Model")
        bModel.Name = name
        bModel.Parent = barricadesFolder

        local frame = PartBuilder.makePart(
            bModel,
            "Frame",
            Vector3.new(9, 7.5, 1.2),
            CFrame.new(pos) * CFrame.Angles(0, rotY, 0),
            Color3.fromRGB(45, 48, 55),
            Enum.Material.Wood
        )
        frame.Transparency = 1
        frame.CanCollide = false

        for p = 1, 5 do
            local pY = (pos.Y - 2.8) + (p * 1.1)
            PartBuilder.makePart(
                bModel,
                "Plank_" .. p,
                Vector3.new(8.5, 0.9, 0.4),
                CFrame.new(pos.X, pY, pos.Z) * CFrame.Angles(0, rotY, math.rad((p % 2 == 0) and 3 or -3)),
                Color3.fromRGB(115, 78, 48),
                Enum.Material.WoodPlanks
            )
        end
    end

    createBarricadeOpening("Barricade_F1_L1", Vector3.new(-bW/2 + 1, f1BaseY + 4.5, 30), math.rad(90))
    createBarricadeOpening("Barricade_F1_L2", Vector3.new(-bW/2 + 1, f1BaseY + 4.5, -20), math.rad(90))
    createBarricadeOpening("Barricade_F1_R1", Vector3.new(bW/2 - 1, f1BaseY + 4.5, 30), math.rad(-90))
    createBarricadeOpening("Barricade_F1_R2", Vector3.new(bW/2 - 1, f1BaseY + 4.5, -20), math.rad(-90))

    print("🏛️ [Floor1_Lobby] สร้างชั้น 1 ล็อบบี้หลัก (ธนาคารกรุงเทพ / One-Stop Service / โถงลิฟต์ 4 ตัว / บันไดคู่ / Barricades / Wall Buys) สำเร็จครบถ้วน!")
end

return Floor1_Lobby
