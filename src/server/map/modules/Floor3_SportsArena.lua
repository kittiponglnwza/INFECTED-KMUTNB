--[[
    Floor3_SportsArena.lua
    โครงสร้างและรายละเอียดชั้น 3 (Floor 3): สนามกีฬาในร่ม อาคาร 40 ปี มจพ.
    สร้างตามผังที่สั่ง (media_1794258762874_7166335a.png) และแปลนจริง (media_1794258782427_a16417ff.jpg):
      1. กรอบตัวอาคาร 300 x 240 studs (X = -150..+150, Z = -120..+120) ตรงกับชั้น 1 และชั้น 2
      2. โซนลิฟต์และบันได (หน้าตึก & หลังตึก) ตรงแนวดิ่งกับชั้น 2 พร้อมเจาะช่องบันไดขึ้นมาจากชั้น 2 พอดีเป๊ะ
      3. แถบบน (Z = -120..-86):
         - ซ้าย: ห้องน้ำ (แบ่งชาย/หญิง ประตูเปิดเดินเข้าได้จริง) | ลิฟต์ | โถงกลาง | บันได | ขวา: ห้องน้ำ (แบ่งชาย/หญิง)
      4. แถบล่าง (Z = +86..+120):
         - ซ้าย: ห้องเก็บของ (อุปกรณ์ฟุตซอล) | บันได | โถงกลาง | ลิฟต์ | ขวา: ห้องเก็บของ (อุปกรณ์บาสเกตบอล)
      5. โซนสนามกีฬาตรงกลาง (Z = -76..+76):
         - ฝั่งซ้ายสุด (X = -146..-124): สแตนเชียร์ 5 ขั้น หันหน้าเข้าสนามฟุตซอล
         - ฝั่งซ้ายกลาง (X = -114..-32): สนามฟุตซอล (Futsal Court) ตีเส้นครบ + ประตูฟุตซอล 2 ฝั่ง
         - ตรงกลาง (X = -32..+32): โถงทางเดินกลางชั้น 3 อาคาร 40 ปี
         - ฝั่งขวากลาง (X = +32..+114): สนามบาสเกตบอล (Basketball Court) ตีเส้นครบ + แป้นบาส 2 ฝั่ง
         - ฝั่งขวาสุด (X = +124..+146): สแตนเชียร์ฝั่งขวา 5 ขั้น หันหน้าเข้าสนามบาส
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local StairBuilder = require(script.Parent.Parent.utils.StairBuilder)
local ElevatorBuilder = require(script.Parent.Parent.utils.ElevatorBuilder)
local SlabBuilder = require(script.Parent.Parent.utils.SlabBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Floor3_SportsArena = {}

function Floor3_SportsArena.build(parent)
    local floor3 = Instance.new("Model")
    floor3.Name = "Floor_3_SportsArena"
    floor3.Parent = parent

    local floorY = Layout.floorY(3)      -- 45.0
    local wallH = 26.0                   -- เพดานโรงยิมสูงโปร่ง 26 studs
    local wallThick = Layout.WALL_THICK  -- 2.0
    local wallColor = Color3.fromRGB(240, 237, 230)
    local wallMaterial = Enum.Material.Concrete
    local floorColor = Color3.fromRGB(212, 210, 204)

    local core = Layout.CORE
    local body = Layout.BODY
    local frontStair = Layout.STAIRS.Front
    local rearStair = Layout.STAIRS.Rear
    local frontLift = Layout.LIFTS.Front
    local rearLift = Layout.LIFTS.Rear

    ------------------------------------------------------------------
    -- 1. พื้นชั้น 3 (300 x 240 studs) เจาะช่องรับบันไดจากชั้น 2 อัตโนมัติ
    ------------------------------------------------------------------
    SlabBuilder.build(
        floor3,
        "Floor3_Slab",
        {
            { minX = -body.halfX, maxX = body.halfX, minZ = -body.halfZ, maxZ = body.halfZ },
        },
        { StairBuilder.slabHole(frontStair), StairBuilder.slabHole(rearStair) },
        floorY, 2.0, floorColor, Enum.Material.Concrete
    )

    ------------------------------------------------------------------
    -- 2. คอร์ลิฟต์และบันไดชั้น 3 (ตรงแนวดิ่งกับชั้น 1 และชั้น 2)
    ------------------------------------------------------------------
    local function buildStairEnclosureF3(folder, def)
        local m = Instance.new("Model")
        m.Name = def.name .. "_F3"
        m.Parent = folder

        StairBuilder.buildEnclosure(m, def, floorY, wallH, 3)
        local g = StairBuilder.geometry(def)

        -- ราวกันตกสแตนเลสชั้น 3 รอบปากหลุมบันไดเพื่อความปลอดภัย
        local railLen = StairBuilder.FLIGHT_RUN + StairBuilder.LANDING_DEPTH
        local railMidX = (g.x(g.tFlightStart) + g.x(g.tEnd)) / 2
        PartBuilder.makePart(m, "GuardRail_CenterTop", Vector3.new(railLen, 0.3, 0.3),
            CFrame.new(railMidX, floorY + 3.4, g.cz), Color3.fromRGB(185, 192, 200), Enum.Material.Metal)
        PartBuilder.makePart(m, "GuardRail_CenterMid", Vector3.new(railLen, 1.8, 0.2),
            CFrame.new(railMidX, floorY + 1.6, g.cz), Color3.fromRGB(70, 76, 84), Enum.Material.Metal)
        PartBuilder.makePart(m, "GuardRail_Front", Vector3.new(0.4, 3.4, g.laneWidth),
            CFrame.new(g.x(g.tFlightStart) + g.e * 0.2, floorY + 1.7, g.flight1Z), Color3.fromRGB(70, 76, 84), Enum.Material.Metal)
    end

    local function buildLiftLevelF3(folder, def)
        ElevatorBuilder.build(folder, def, 3, floorY, wallH, false)
    end

    local northCore = Instance.new("Model")
    northCore.Name = "NorthCore_F3"
    northCore.Parent = floor3
    buildLiftLevelF3(northCore, rearLift)
    buildStairEnclosureF3(northCore, rearStair)
    PartBuilder.makePart(northCore, "NorthEndWall_Low", Vector3.new(core.centerWidth, 5.0, wallThick),
        CFrame.new(0, floorY + 2.5, -core.outerZ + wallThick / 2), wallColor, wallMaterial)
    PartBuilder.makePart(northCore, "NorthEndGlass", Vector3.new(core.centerWidth - 4, wallH - 9, 0.4),
        CFrame.new(0, floorY + 5 + (wallH - 9) / 2, -core.outerZ + 1.0), Color3.fromRGB(165, 205, 220), Enum.Material.Glass, { Transparency = 0.55 })

    local southCore = Instance.new("Model")
    southCore.Name = "SouthCore_F3"
    southCore.Parent = floor3
    buildStairEnclosureF3(southCore, frontStair)
    buildLiftLevelF3(southCore, frontLift)
    PartBuilder.makePart(southCore, "SouthEndWall_Low", Vector3.new(core.centerWidth, 5.0, wallThick),
        CFrame.new(0, floorY + 2.5, core.outerZ - wallThick / 2), wallColor, wallMaterial)
    PartBuilder.makePart(southCore, "SouthEndGlass", Vector3.new(core.centerWidth - 4, wallH - 9, 0.4),
        CFrame.new(0, floorY + 5 + (wallH - 9) / 2, core.outerZ - 1.0), Color3.fromRGB(165, 205, 220), Enum.Material.Glass, { Transparency = 0.55 })

    ------------------------------------------------------------------
    -- 3. ห้องน้ำแถบบน 2 ฝั่ง (ซ้าย WC.2 & ขวา WC.3 — มีแยกชาย/หญิง เดินเข้าได้จริง)
    --    ตำแหน่งตามผัง: X = ±68..±128 (กว้าง 60), Z = -120..-86 (ลึก 34)
    ------------------------------------------------------------------
    local restroomsF3 = Instance.new("Folder")
    restroomsF3.Name = "Restrooms_NorthBand"
    restroomsF3.Parent = floor3

    local function buildRestroomPair(tag, minX, maxX)
        local block = Instance.new("Model")
        block.Name = "Restroom_" .. tag
        block.Parent = restroomsF3

        local midX = (minX + maxX) / 2
        local halfW = (maxX - minX) / 2 -- 30 ต่อห้องย่อย
        local zOuter = -120
        local zInner = -86
        local zMid = (zOuter + zInner) / 2 -- -103
        local depth = zInner - zOuter      -- 34
        local doorW = 8
        local doorH = 13

        local subRooms = {
            { sub = "Male",   label = "ห้องน้ำชาย\nMEN WC",   color = Color3.fromRGB(25, 95, 185),  x1 = minX, x2 = midX },
            { sub = "Female", label = "ห้องน้ำหญิง\nWOMEN WC", color = Color3.fromRGB(205, 65, 115), x1 = midX, x2 = maxX },
        }

        for _, sr in ipairs(subRooms) do
            local rM = Instance.new("Model")
            rM.Name = sr.sub
            rM.Parent = block
            local cx = (sr.x1 + sr.x2) / 2

            PartBuilder.makePart(rM, "TileFloor", Vector3.new(halfW - 1, 0.08, depth - 1),
                CFrame.new(cx, floorY + 0.04, zMid), Color3.fromRGB(225, 232, 238), Enum.Material.SmoothPlastic)

            -- ผนังหลังตึก (-120) และผนังข้าง
            PartBuilder.makePart(rM, "Wall_Back", Vector3.new(halfW, wallH, wallThick),
                CFrame.new(cx, floorY + wallH / 2, zOuter + wallThick / 2), wallColor, wallMaterial)
            PartBuilder.makePart(rM, "Wall_Left", Vector3.new(wallThick, wallH, depth),
                CFrame.new(sr.x1 + wallThick / 2, floorY + wallH / 2, zMid), wallColor, wallMaterial)
            PartBuilder.makePart(rM, "Wall_Right", Vector3.new(wallThick, wallH, depth),
                CFrame.new(sr.x2 - wallThick / 2, floorY + wallH / 2, zMid), wallColor, wallMaterial)

            -- ผนังด้านหน้า (Z = -86) เจาะช่องประตูทางเข้ากว้าง 8 studs
            local sideSegW = (halfW - doorW) / 2
            PartBuilder.makePart(rM, "Front_L", Vector3.new(sideSegW, wallH, wallThick),
                CFrame.new(sr.x1 + sideSegW / 2, floorY + wallH / 2, zInner - wallThick / 2), wallColor, wallMaterial)
            PartBuilder.makePart(rM, "Front_R", Vector3.new(sideSegW, wallH, wallThick),
                CFrame.new(sr.x2 - sideSegW / 2, floorY + wallH / 2, zInner - wallThick / 2), wallColor, wallMaterial)
            PartBuilder.makePart(rM, "Front_Header", Vector3.new(doorW, wallH - doorH, wallThick),
                CFrame.new(cx, floorY + doorH + (wallH - doorH) / 2, zInner - wallThick / 2), wallColor, wallMaterial)

            PartBuilder.makeSign(rM, "Sign", sr.label, Vector3.new(18, 3.2, 0.4),
                CFrame.new(cx, floorY + doorH + 2.4, zInner + 0.3).Position, Enum.NormalId.Back, sr.color, Color3.fromRGB(255, 255, 255))

            -- อ่างล้างมือ + กระจกเงา + ห้องส้วมย่อยด้านใน
            PartBuilder.makePart(rM, "SinkCounter", Vector3.new(2.8, 3.2, 12),
                CFrame.new(sr.x1 + 3.0, floorY + 1.6, zMid + 3), Color3.fromRGB(235, 238, 242), Enum.Material.Marble)
            PartBuilder.makePart(rM, "Mirror", Vector3.new(0.2, 4.5, 11),
                CFrame.new(sr.x1 + 1.8, floorY + 5.8, zMid + 3), Color3.fromRGB(170, 215, 235), Enum.Material.Glass)

            for cIdx = 1, 2 do
                local cX = sr.x1 + 7 + (cIdx - 1) * 10
                PartBuilder.makePart(rM, "StallPartition_" .. cIdx, Vector3.new(0.6, 8.5, 9),
                    CFrame.new(cX, floorY + 4.5, zOuter + 6.5), Color3.fromRGB(205, 210, 218), Enum.Material.SmoothPlastic)
                PartBuilder.makePart(rM, "Toilet_" .. cIdx, Vector3.new(2.2, 2.2, 3.0),
                    CFrame.new(cX + 4, floorY + 1.1, zOuter + 4.5), Color3.fromRGB(250, 250, 252), Enum.Material.SmoothPlastic)
            end
        end
    end

    buildRestroomPair("West_WC2", -128, -68)
    buildRestroomPair("East_WC3",   68, 128)

    ------------------------------------------------------------------
    -- 4. ห้องเก็บของแถบล่าง 2 ฝั่ง (ซ้าย & ขวา — Z = +86..+120)
    --    ตามผัง: "ห้องเก็บของ" อยู่ข้างบันไดล่างซ้าย และข้างลิฟต์ล่างขวา
    ------------------------------------------------------------------
    local storageFolder = Instance.new("Folder")
    storageFolder.Name = "StorageRooms_SouthBand"
    storageFolder.Parent = floor3

    local function buildStorageRoom(name, title, minX, maxX, ballColor)
        local sM = Instance.new("Model")
        sM.Name = name
        sM.Parent = storageFolder

        local cx = (minX + maxX) / 2
        local w = maxX - minX       -- 56
        local zInner = 86
        local zOuter = 120
        local zMid = (zInner + zOuter) / 2 -- 103
        local depth = zOuter - zInner      -- 34
        local doorW = 12
        local doorH = 13

        PartBuilder.makePart(sM, "Floor", Vector3.new(w - 1, 0.08, depth - 1),
            CFrame.new(cx, floorY + 0.04, zMid), Color3.fromRGB(185, 188, 192), Enum.Material.Concrete)

        PartBuilder.makePart(sM, "Wall_South", Vector3.new(w, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, zOuter - wallThick / 2), wallColor, wallMaterial)
        PartBuilder.makePart(sM, "Wall_West", Vector3.new(wallThick, wallH, depth),
            CFrame.new(minX + wallThick / 2, floorY + wallH / 2, zMid), wallColor, wallMaterial)
        PartBuilder.makePart(sM, "Wall_East", Vector3.new(wallThick, wallH, depth),
            CFrame.new(maxX - wallThick / 2, floorY + wallH / 2, zMid), wallColor, wallMaterial)

        local sideSegW = (w - doorW) / 2
        PartBuilder.makePart(sM, "Front_L", Vector3.new(sideSegW, wallH, wallThick),
            CFrame.new(minX + sideSegW / 2, floorY + wallH / 2, zInner + wallThick / 2), wallColor, wallMaterial)
        PartBuilder.makePart(sM, "Front_R", Vector3.new(sideSegW, wallH, wallThick),
            CFrame.new(maxX - sideSegW / 2, floorY + wallH / 2, zInner + wallThick / 2), wallColor, wallMaterial)
        PartBuilder.makePart(sM, "Front_Header", Vector3.new(doorW, wallH - doorH, wallThick),
            CFrame.new(cx, floorY + doorH + (wallH - doorH) / 2, zInner + wallThick / 2), wallColor, wallMaterial)

        PartBuilder.makeSign(sM, "Sign", title, Vector3.new(26, 3.2, 0.4),
            Vector3.new(cx, floorY + doorH + 2.4, zInner - 0.3), Enum.NormalId.Front,
            Color3.fromRGB(65, 75, 90), Color3.fromRGB(255, 255, 255))

        -- ชั้นวางอุปกรณ์กีฬาและตะกร้าลูกบอลด้านในห้องเก็บของ
        for rIdx = -1, 1, 2 do
            local rx = cx + rIdx * 16
            PartBuilder.makePart(sM, "EquipmentRack_" .. rIdx, Vector3.new(12, 8.0, 4.0),
                CFrame.new(rx, floorY + 4.0, zOuter - 6.0), Color3.fromRGB(70, 78, 88), Enum.Material.Metal)
            PartBuilder.makePart(sM, "BallCart_" .. rIdx, Vector3.new(6.0, 3.6, 4.5),
                CFrame.new(rx, floorY + 1.8, zMid - 2.0), Color3.fromRGB(45, 110, 175), Enum.Material.Metal)
            for b = -1, 1 do
                local ball = PartBuilder.makePart(sM, "SportBall_" .. rIdx .. "_" .. b, Vector3.new(1.5, 1.5, 1.5),
                    CFrame.new(rx + b * 1.6, floorY + 3.8, zMid - 2.0), ballColor, Enum.Material.SmoothPlastic)
                ball.Shape = Enum.PartType.Ball
            end
        end
    end

    buildStorageRoom("Storage_West_Futsal", "ห้องเก็บของ (อุปกรณ์ฟุตซอล)\nSTORAGE ROOM", -124, -68, Color3.fromRGB(245, 245, 250))
    buildStorageRoom("Storage_East_Basket", "ห้องเก็บของ (อุปกรณ์บาสเกตบอล)\nSTORAGE ROOM", 68, 124, Color3.fromRGB(230, 105, 35))

    ------------------------------------------------------------------
    -- 5. สแตนเชียร์ 2 ฝั่ง (ซ้ายสุด X = -146..-124 และ ขวาสุด X = +124..+146)
    ------------------------------------------------------------------
    local bleachersFolder = Instance.new("Folder")
    bleachersFolder.Name = "Bleachers_Grandstands"
    bleachersFolder.Parent = floor3

    local function buildBleachers(name, centerX, faceDir, lengthZ)
        local bM = Instance.new("Model")
        bM.Name = name
        bM.Parent = bleachersFolder

        local tiers = 5
        local tierRun = 4.0
        local tierRise = 1.8
        local totalW = tiers * tierRun -- 20 studs

        for t = 1, tiers do
            -- faceDir = +1 (หันไปทางขวา +X): ขั้นที่ 1 อยู่ขวาสุด ขั้นที่ 5 อยู่ชิดกำแพงซ้ายสุด
            local offsetFromFront = (t - 0.5) * tierRun
            local xPos = centerX + faceDir * (totalW / 2 - offsetFromFront)
            local h = t * tierRise
            PartBuilder.makePart(bM, "TierBase_" .. t, Vector3.new(tierRun + 0.1, h, lengthZ),
                CFrame.new(xPos, floorY + h / 2, 0), Color3.fromRGB(190, 188, 182), Enum.Material.Concrete)
            -- ที่นั่งสีแสด มจพ. สลับเทา
            local seatColor = (t % 2 == 1) and Color3.fromRGB(228, 110, 42) or Color3.fromRGB(75, 82, 92)
            PartBuilder.makePart(bM, "SeatPlank_" .. t, Vector3.new(tierRun - 0.8, 0.35, lengthZ - 1),
                CFrame.new(xPos, floorY + h + 0.18, 0), seatColor, Enum.Material.SmoothPlastic)
        end

        -- ราวกันตกหัวท้ายสแตนเชียร์
        for _, sz in ipairs({ -1, 1 }) do
            PartBuilder.makePart(bM, "SideRail_" .. sz, Vector3.new(totalW, tiers * tierRise + 2.5, 0.8),
                CFrame.new(centerX, floorY + (tiers * tierRise + 2.5) / 2, sz * (lengthZ / 2 + 0.4)),
                Color3.fromRGB(90, 96, 105), Enum.Material.Metal)
        end

        PartBuilder.makeSign(bM, "BleacherSign", "สแตนเชียร์\nGRANDSTAND",
            Vector3.new(0.3, 3.0, 24),
            Vector3.new(centerX - faceDir * (totalW / 2 - 0.5), floorY + tiers * tierRise + 4.5, 0),
            faceDir > 0 and Enum.NormalId.Right or Enum.NormalId.Left,
            Color3.fromRGB(215, 95, 30), Color3.fromRGB(255, 255, 255))
    end

    buildBleachers("Bleachers_West_Futsal", -136,  1, 148)
    buildBleachers("Bleachers_East_Basket",  136, -1, 148)

    ------------------------------------------------------------------
    -- 6. สนามฟุตซอลฝั่งซ้าย ("สนามฟุตซอล" X = -114..-32, Z = -74..+74)
    ------------------------------------------------------------------
    local futsalModel = Instance.new("Model")
    futsalModel.Name = "FutsalCourt_West"
    futsalModel.Parent = floor3

    local fX = -73      -- กึ่งกลางสนามฟุตซอล ((-114 + -32) / 2)
    local fW = 82       -- ความกว้างสนาม (X = -114..-32)
    local fL = 148      -- ความยาวสนาม (Z = -74..+74)
    local courtY = floorY + 0.08
    local lineY = floorY + 0.15
    local lineWhite = Color3.fromRGB(250, 250, 252)

    -- พื้นสนามฟุตซอลสีฟ้าน้ำเงินตัดขอบเขียวมาตรฐานสนามกีฬาในร่ม
    PartBuilder.makePart(futsalModel, "FutsalBorderSurface", Vector3.new(fW + 6, 0.1, fL + 6),
        CFrame.new(fX, floorY + 0.05, 0), Color3.fromRGB(42, 138, 85), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(futsalModel, "FutsalPlaySurface", Vector3.new(fW, 0.12, fL),
        CFrame.new(fX, courtY, 0), Color3.fromRGB(32, 112, 168), Enum.Material.SmoothPlastic)

    -- ตีเส้นสนามฟุตซอล (เส้นข้าง, เส้นหลัง, เส้นแบ่งครึ่งสนาม, วงกลมกลาง, เขตโทษ 2 ฝั่ง)
    local function makeLine(parentModel, name, sx, sz, px, pz)
        PartBuilder.makePart(parentModel, name, Vector3.new(sx, 0.04, sz),
            CFrame.new(px, lineY, pz), lineWhite, Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
    end

    makeLine(futsalModel, "Line_West",   0.8, fL, fX - fW / 2, 0)
    makeLine(futsalModel, "Line_East",   0.8, fL, fX + fW / 2, 0)
    makeLine(futsalModel, "Line_North",  fW, 0.8, fX, -fL / 2)
    makeLine(futsalModel, "Line_South",  fW, 0.8, fX,  fL / 2)
    makeLine(futsalModel, "Line_Center", fW, 0.8, fX, 0)

    -- วงกลมกลางสนามฟุตซอล
    PartBuilder.makeCylinder(futsalModel, "CenterCircle_Outer", Vector3.new(0.03, 24, 24),
        CFrame.new(fX, lineY, 0) * CFrame.Angles(0, 0, math.rad(90)), lineWhite, Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
    PartBuilder.makeCylinder(futsalModel, "CenterCircle_Inner", Vector3.new(0.04, 22.4, 22.4),
        CFrame.new(fX, lineY + 0.005, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(32, 112, 168), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })

    -- เขตโทษ + ประตูฟุตซอล 2 ฝั่ง (เหนือ Z = -74 และ ใต้ Z = +74)
    for _, sideZ in ipairs({ -1, 1 }) do
        local goalZ = sideZ * (fL / 2)
        local boxDepth = 22
        local boxWidth = 38
        makeLine(futsalModel, "PenaltyFront_" .. sideZ, boxWidth, 0.8, fX, goalZ - sideZ * boxDepth)
        makeLine(futsalModel, "PenaltyLeft_" .. sideZ,  0.8, boxDepth, fX - boxWidth / 2, goalZ - sideZ * (boxDepth / 2))
        makeLine(futsalModel, "PenaltyRight_" .. sideZ, 0.8, boxDepth, fX + boxWidth / 2, goalZ - sideZ * (boxDepth / 2))

        -- โกลฟุตซอล (กว้าง 14, สูง 8, ลึก 5)
        local gW, gH, gD = 14, 8.0, 5.0
        local postCol = Color3.fromRGB(235, 45, 45)
        PartBuilder.makePart(futsalModel, "GoalPostL_" .. sideZ, Vector3.new(0.7, gH, 0.7),
            CFrame.new(fX - gW / 2, floorY + gH / 2, goalZ), postCol, Enum.Material.Metal)
        PartBuilder.makePart(futsalModel, "GoalPostR_" .. sideZ, Vector3.new(0.7, gH, 0.7),
            CFrame.new(fX + gW / 2, floorY + gH / 2, goalZ), postCol, Enum.Material.Metal)
        PartBuilder.makePart(futsalModel, "GoalCrossbar_" .. sideZ, Vector3.new(gW + 0.7, 0.7, 0.7),
            CFrame.new(fX, floorY + gH, goalZ), lineWhite, Enum.Material.Metal)
        PartBuilder.makePart(futsalModel, "GoalNetBack_" .. sideZ, Vector3.new(gW, gH, 0.2),
            CFrame.new(fX, floorY + gH / 2, goalZ + sideZ * gD), lineWhite, Enum.Material.Fabric, { Transparency = 0.55, CanCollide = false, CanQuery = false })
        PartBuilder.makePart(futsalModel, "GoalNetTop_" .. sideZ, Vector3.new(gW, 0.2, gD),
            CFrame.new(fX, floorY + gH, goalZ + sideZ * (gD / 2)), lineWhite, Enum.Material.Fabric, { Transparency = 0.55, CanCollide = false, CanQuery = false })
    end

    PartBuilder.makeSign(futsalModel, "FutsalFloorSign", "สนามฟุตซอล\nFUTSAL COURT",
        Vector3.new(24, 0.06, 5.5), Vector3.new(fX, lineY + 0.02, 0), Enum.NormalId.Top,
        Color3.fromRGB(22, 82, 130), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 7. สนามบาสเกตบอลฝั่งขวา ("สนามบาส" X = +32..+114, Z = -74..+74)
    ------------------------------------------------------------------
    local basketModel = Instance.new("Model")
    basketModel.Name = "BasketballCourt_East"
    basketModel.Parent = floor3

    local bX = 73       -- กึ่งกลางสนามบาส ((32 + 114) / 2)
    local bW = 82       -- ความกว้างสนาม (X = 32..114)
    local bL = 148      -- ความยาวสนาม (Z = -74..+74)
    local courtWood = Color3.fromRGB(208, 152, 92)
    local keyMaroon = Color3.fromRGB(168, 52, 42)

    PartBuilder.makePart(basketModel, "BasketBorderSurface", Vector3.new(bW + 6, 0.1, bL + 6),
        CFrame.new(bX, floorY + 0.05, 0), keyMaroon, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(basketModel, "BasketPlaySurface", Vector3.new(bW, 0.12, bL),
        CFrame.new(bX, courtY, 0), courtWood, Enum.Material.WoodPlanks)

    makeLine(basketModel, "Line_West",   0.8, bL, bX - bW / 2, 0)
    makeLine(basketModel, "Line_East",   0.8, bL, bX + bW / 2, 0)
    makeLine(basketModel, "Line_North",  bW, 0.8, bX, -bL / 2)
    makeLine(basketModel, "Line_South",  bW, 0.8, bX,  bL / 2)
    makeLine(basketModel, "Line_Center", bW, 0.8, bX, 0)

    -- วงกลมกลางสนามบาสสีแสด/เลือดหมู มจพ.
    PartBuilder.makeCylinder(basketModel, "CenterJump_Outer", Vector3.new(0.03, 24, 24),
        CFrame.new(bX, lineY, 0) * CFrame.Angles(0, 0, math.rad(90)), lineWhite, Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
    PartBuilder.makeCylinder(basketModel, "CenterJump_Fill", Vector3.new(0.04, 22.4, 22.4),
        CFrame.new(bX, lineY + 0.005, 0) * CFrame.Angles(0, 0, math.rad(90)), keyMaroon, Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })

    -- เขตใต้แป้น (Key) + เส้น 3 แต้ม + แป้นบาสเกตบอล 2 ฝั่ง (เหนือ & ใต้)
    for _, sideZ in ipairs({ -1, 1 }) do
        local baseZ = sideZ * (bL / 2)
        local keyW, keyD = 24, 30

        -- พื้นเขตโทษใต้แป้นสีเลือดหมู มจพ.
        PartBuilder.makePart(basketModel, "KeyPaint_" .. sideZ, Vector3.new(keyW, 0.03, keyD),
            CFrame.new(bX, lineY - 0.01, baseZ - sideZ * (keyD / 2)), keyMaroon, Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
        makeLine(basketModel, "KeyFront_" .. sideZ, keyW, 0.8, bX, baseZ - sideZ * keyD)
        makeLine(basketModel, "KeyLeft_" .. sideZ,  0.8, keyD, bX - keyW / 2, baseZ - sideZ * (keyD / 2))
        makeLine(basketModel, "KeyRight_" .. sideZ, 0.8, keyD, bX + keyW / 2, baseZ - sideZ * (keyD / 2))

        -- วงกลมเส้นโยนโทษ
        PartBuilder.makeCylinder(basketModel, "FreeThrowCircle_" .. sideZ, Vector3.new(0.03, 20, 20),
            CFrame.new(bX, lineY, baseZ - sideZ * keyD) * CFrame.Angles(0, 0, math.rad(90)), lineWhite, Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })

        -- โครงสร้างแป้นบาสเกตบอลมาตรฐาน (เสาฐาน + แขนยื่น + แป้นกระจก + ห่วงส้ม)
        local postZ = baseZ + sideZ * 2.5
        local boardZ = baseZ - sideZ * 4.0
        PartBuilder.makePart(basketModel, "HoopBasePad_" .. sideZ, Vector3.new(3.2, 6.0, 3.2),
            CFrame.new(bX, floorY + 3.0, postZ), Color3.fromRGB(30, 65, 135), Enum.Material.SmoothPlastic)
        PartBuilder.makePart(basketModel, "HoopMainPost_" .. sideZ, Vector3.new(1.4, 13.5, 1.4),
            CFrame.new(bX, floorY + 6.75, postZ), Color3.fromRGB(45, 50, 58), Enum.Material.Metal)
        PartBuilder.makePart(basketModel, "HoopExtensionArm_" .. sideZ, Vector3.new(1.2, 1.2, 6.8),
            CFrame.new(bX, floorY + 12.8, (postZ + boardZ) / 2), Color3.fromRGB(45, 50, 58), Enum.Material.Metal)

        -- แป้นบาสกระจกใส + กรอบขาว
        PartBuilder.makePart(basketModel, "Backboard_" .. sideZ, Vector3.new(9.0, 5.6, 0.4),
            CFrame.new(bX, floorY + 12.5, boardZ), Color3.fromRGB(235, 245, 255), Enum.Material.Glass, { Transparency = 0.35 })
        PartBuilder.makePart(basketModel, "BackboardTarget_" .. sideZ, Vector3.new(3.2, 2.4, 0.45),
            CFrame.new(bX, floorY + 11.6, boardZ), lineWhite, Enum.Material.SmoothPlastic)

        -- ห่วงบาสสีส้ม + ตาข่าย
        local rimZ = boardZ - sideZ * 1.4
        PartBuilder.makePart(basketModel, "BasketballRim_" .. sideZ, Vector3.new(2.4, 0.3, 2.4),
            CFrame.new(bX, floorY + 10.5, rimZ), Color3.fromRGB(255, 85, 20), Enum.Material.Neon)
        PartBuilder.makeCylinder(basketModel, "BasketballNet_" .. sideZ, Vector3.new(2.0, 2.0, 2.0),
            CFrame.new(bX, floorY + 9.4, rimZ) * CFrame.Angles(0, 0, math.rad(90)), lineWhite, Enum.Material.Fabric, { Transparency = 0.4, CanCollide = false, CanQuery = false })
    end

    PartBuilder.makeSign(basketModel, "BasketFloorSign", "สนามบาสเกตบอล\nBASKETBALL COURT",
        Vector3.new(26, 0.06, 5.5), Vector3.new(bX, lineY + 0.02, 0), Enum.NormalId.Top,
        keyMaroon, Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 8. โถงทางเดินกลางชั้น 3 + เสาโครงสร้างตามแปลนจริง (Grid E & F)
    ------------------------------------------------------------------
    local concourse = Instance.new("Model")
    concourse.Name = "CentralConcourse_F3"
    concourse.Parent = floor3

    PartBuilder.makeSign(concourse, "CenterHallSign", "ชั้น 3 อาคาร 40 ปี มจพ.\nSPORTS ARENA CONCOURSE",
        Vector3.new(26, 0.08, 6.0), Vector3.new(0, floorY + 0.12, 0), Enum.NormalId.Top,
        Color3.fromRGB(128, 28, 38), Color3.fromRGB(255, 255, 255))

    -- เสาโครงสร้างเรียงตามแนวขอบสนามเหมือนแปลนจริง (Grid B, E, F, I: X = -118, -28, +28, +118 / Z = -60, -20, +20, +60)
    local function attachColumnBasketballHoop(parentModel, colX, colZ, dirX)
        local hoopTag = tostring(colX) .. "_" .. tostring(colZ)
        local armLen = 4.6
        local boardX = colX + dirX * (1.6 + armLen)
        local armMidX = colX + dirX * (1.6 + armLen / 2)

        -- แผ่นเหล็กยึดเสา (Mounting Plate) + แขนเหล็กคู่ยื่นออกจากเสาเข้าหาสนามบาส
        PartBuilder.makePart(parentModel, "ColHoopPlate_" .. hoopTag, Vector3.new(0.4, 4.2, 2.6),
            CFrame.new(colX + dirX * 1.7, floorY + 12.2, colZ), Color3.fromRGB(45, 50, 58), Enum.Material.Metal)
        PartBuilder.makePart(parentModel, "ColHoopArmTop_" .. hoopTag, Vector3.new(armLen, 0.55, 1.4),
            CFrame.new(armMidX, floorY + 13.4, colZ), Color3.fromRGB(45, 50, 58), Enum.Material.Metal)
        PartBuilder.makePart(parentModel, "ColHoopArmBot_" .. hoopTag, Vector3.new(armLen, 0.55, 1.4),
            CFrame.new(armMidX, floorY + 11.0, colZ), Color3.fromRGB(45, 50, 58), Enum.Material.Metal)

        -- แป้นบาสกระจกใสขอบขาว (หันหน้าเข้าสนามบาสตามแกน X)
        PartBuilder.makePart(parentModel, "ColBackboard_" .. hoopTag, Vector3.new(0.4, 5.2, 8.2),
            CFrame.new(boardX, floorY + 12.5, colZ), Color3.fromRGB(235, 245, 255), Enum.Material.Glass, { Transparency = 0.35 })
        PartBuilder.makePart(parentModel, "ColBackboardBorder_" .. hoopTag, Vector3.new(0.42, 5.4, 8.4),
            CFrame.new(boardX - dirX * 0.05, floorY + 12.5, colZ), lineWhite, Enum.Material.SmoothPlastic, { Transparency = 0.7 })
        PartBuilder.makePart(parentModel, "ColBackboardTarget_" .. hoopTag, Vector3.new(0.46, 2.2, 3.0),
            CFrame.new(boardX, floorY + 11.6, colZ), lineWhite, Enum.Material.SmoothPlastic)

        -- ห่วงบาสสีส้ม + ตาข่ายขาว
        local rimX = boardX + dirX * 1.35
        PartBuilder.makePart(parentModel, "ColBasketballRim_" .. hoopTag, Vector3.new(2.3, 0.3, 2.3),
            CFrame.new(rimX, floorY + 10.5, colZ), Color3.fromRGB(255, 85, 20), Enum.Material.Neon)
        PartBuilder.makeCylinder(parentModel, "ColBasketballNet_" .. hoopTag, Vector3.new(2.0, 1.9, 1.9),
            CFrame.new(rimX, floorY + 9.4, colZ) * CFrame.Angles(0, 0, math.rad(90)), lineWhite, Enum.Material.Fabric,
            { Transparency = 0.38, CanCollide = false, CanQuery = false })
    end

    for _, px in ipairs({ -28, 28 }) do
        for _, pz in ipairs({ -60, -20, 20, 60 }) do
            PartBuilder.makePart(concourse, "ArenaColumn_" .. px .. "_" .. pz, Vector3.new(3.2, wallH, 3.2),
                CFrame.new(px, floorY + wallH / 2, pz), Color3.fromRGB(225, 222, 215), Enum.Material.Concrete)
            PartBuilder.makePart(concourse, "ColumnPad_" .. px .. "_" .. pz, Vector3.new(3.6, 5.0, 3.6),
                CFrame.new(px, floorY + 2.5, pz), Color3.fromRGB(225, 110, 40), Enum.Material.SmoothPlastic)

            -- ติดแป้นบาสเฉพาะเสาแถวกลาง (X = 28) หันเข้าสู่สนามบาส (เอาแป้นบาสฝั่งสแตนเชียร์ออกตามคำสั่ง)
            if px == 28 then
                attachColumnBasketballHoop(basketModel, px, pz, 1)
            end
        end
    end

    ------------------------------------------------------------------
    -- 8.5 ตะแกรงเหล็กกั้นข้างสนามฟุตซอล + ทางเข้า-ออกจากตรงกลาง
    --     แนว X = -28 ยาวจากคอร์บน (Z = -86) ถึงคอร์ล่าง (Z = +86)
    --     เว้นช่องทางเข้า-ออกตรงกลาง (Z = -14 .. +14, กว้าง 28 studs)
    ------------------------------------------------------------------
    local meshCage = Instance.new("Model")
    meshCage.Name = "FutsalSteelMeshCage"
    meshCage.Parent = floor3

    local bulletPassColliders = Instance.new("Folder")
    bulletPassColliders.Name = "BulletPassColliders"
    bulletPassColliders.Parent = meshCage

    local cageX = -28
    local cageH = 21.0
    local gateHalfZ = 14.0 -- ช่องทางเข้า-ออกตรงกลาง Z = -14..+14 (กว้าง 28 studs)
    local frameColor = Color3.fromRGB(52, 58, 66)
    local meshColor = Color3.fromRGB(95, 105, 115)
    local kickColor = Color3.fromRGB(225, 110, 40)

    local function buildMeshFenceSpan(spanName, zStart, zEnd)
        local spanLen = math.abs(zEnd - zStart)
        local zMid = (zStart + zEnd) / 2

        -- แผ่นกั้น Collision สำหรับคนและซอมบี้ (แต่กระสุนยิงทะลุช่องตะแกรงได้)
        PartBuilder.makePart(bulletPassColliders, spanName .. "_Collider", Vector3.new(1.2, cageH, spanLen),
            CFrame.new(cageX, floorY + cageH / 2, zMid), frameColor, Enum.Material.Metal,
            { Transparency = 1, CanCollide = true, CanQuery = true })

        -- ขอบเหล็กกันกระแทกด้านล่าง (Kickboard สูง 2.0 studs)
        PartBuilder.makePart(meshCage, spanName .. "_Kickboard", Vector3.new(0.8, 2.0, spanLen),
            CFrame.new(cageX, floorY + 1.0, zMid), kickColor, Enum.Material.Metal)

        -- คานเหล็กแนวนอน 4 ระดับ
        for _, hY in ipairs({ 2.1, 8.5, 14.8, cageH }) do
            PartBuilder.makePart(meshCage, spanName .. "_HorizRail_" .. hY, Vector3.new(0.65, 0.45, spanLen),
                CFrame.new(cageX, floorY + hY, zMid), frameColor, Enum.Material.Metal)
        end

        -- แผงเนื้อตะแกรงเหล็กโปร่งแสงมองทะลุได้
        PartBuilder.makePart(meshCage, spanName .. "_WireSheet", Vector3.new(0.15, cageH - 2.2, spanLen),
            CFrame.new(cageX, floorY + 2.1 + (cageH - 2.2) / 2, zMid), meshColor, Enum.Material.Fabric,
            { Transparency = 0.62, CanCollide = false, CanQuery = false })

        -- ซี่กรงตะแกรงเหล็กแนวตั้งและแนวนอนถี่ๆ ให้เห็นเป็นตารางเหล็กชัดเจน
        local postStep = 4.5
        local numSteps = math.floor(spanLen / postStep)
        for i = 0, numSteps do
            local pz = zStart + (i * (spanLen / numSteps))
            local isMajor = (i % 2 == 0)
            PartBuilder.makePart(meshCage, spanName .. "_VBar_" .. i,
                Vector3.new(isMajor and 0.45 or 0.22, cageH - 2.0, isMajor and 0.45 or 0.22),
                CFrame.new(cageX, floorY + 2.0 + (cageH - 2.0) / 2, pz),
                isMajor and frameColor or meshColor, Enum.Material.Metal,
                { CanCollide = false, CanQuery = isMajor })
        end

        for hBar = 4.0, cageH - 1.5, 2.2 do
            PartBuilder.makePart(meshCage, spanName .. "_HWire_" .. math.floor(hBar * 10),
                Vector3.new(0.20, 0.18, spanLen),
                CFrame.new(cageX, floorY + hBar, zMid),
                meshColor, Enum.Material.Metal, { CanCollide = false, CanQuery = false })
        end
    end

    -- ปีกเหนือ (เชื่อมจากคอร์ลิฟต์บน Z = -86 มาถึงขอบประตูกลาง Z = -14)
    buildMeshFenceSpan("NorthFence", -86, -gateHalfZ)
    -- ปีกใต้ (เชื่อมจากขอบประตูกลาง Z = +14 ไปถึงคอร์บันไดล่าง Z = +86)
    buildMeshFenceSpan("SouthFence",  gateHalfZ, 86)

    -- ซุ้มประตูทางเข้า-ออกตรงกลาง (Z = -14 .. +14, กว้าง 28 studs, สูง 13 studs)
    local gateH = 13.0
    for _, gz in ipairs({ -gateHalfZ, gateHalfZ }) do
        PartBuilder.makePart(meshCage, "CenterGatePost_" .. gz, Vector3.new(1.4, cageH, 1.4),
            CFrame.new(cageX, floorY + cageH / 2, gz), kickColor, Enum.Material.Metal)
    end
    -- แผงตะแกรงเหนือซุ้มประตูทางเข้า-ออกตรงกลาง (Y = 13..21)
    PartBuilder.makePart(meshCage, "CenterGateHeaderBeam", Vector3.new(1.0, 0.8, gateHalfZ * 2),
        CFrame.new(cageX, floorY + gateH, 0), frameColor, Enum.Material.Metal)
    PartBuilder.makePart(meshCage, "CenterGateTopBeam", Vector3.new(1.0, 0.8, gateHalfZ * 2),
        CFrame.new(cageX, floorY + cageH, 0), frameColor, Enum.Material.Metal)
    PartBuilder.makePart(meshCage, "CenterGateTransomMesh", Vector3.new(0.2, cageH - gateH, gateHalfZ * 2),
        CFrame.new(cageX, floorY + gateH + (cageH - gateH) / 2, 0), meshColor, Enum.Material.Fabric,
        { Transparency = 0.62, CanCollide = false, CanQuery = false })

    PartBuilder.makeSign(meshCage, "CenterGateSign_Out", "◀ ทางเข้า-ออกสนามฟุตซอล\nFUTSAL COURT ENTRANCE / EXIT",
        Vector3.new(0.4, 2.8, 22), Vector3.new(cageX + 0.6, floorY + gateH + 2.2, 0),
        Enum.NormalId.Right, Color3.fromRGB(22, 95, 145), Color3.fromRGB(255, 255, 255))
    PartBuilder.makeSign(meshCage, "CenterGateSign_In", "ทางออกสู่โถงกลาง ▶\nEXIT TO CENTRAL HALL",
        Vector3.new(0.4, 2.8, 22), Vector3.new(cageX - 0.6, floorY + gateH + 2.2, 0),
        Enum.NormalId.Left, Color3.fromRGB(22, 95, 145), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 9. ผนังรอบนอกชั้น 3 + ช่องลมระบายอากาศโรงยิม + หลังคาและไฟสปอตไลท์
    ------------------------------------------------------------------
    local envelope = Instance.new("Model")
    envelope.Name = "ArenaEnvelopeAndRoof"
    envelope.Parent = floor3

    -- ผนังด้านซ้ายสุด (-150) และขวาสุด (+150)
    for _, sx in ipairs({ -1, 1 }) do
        local xWall = sx * (body.halfX - wallThick / 2)
        PartBuilder.makePart(envelope, "SideWall_Lower_" .. sx, Vector3.new(wallThick, 14.0, body.halfZ * 2),
            CFrame.new(xWall, floorY + 7.0, 0), wallColor, wallMaterial)
        PartBuilder.makePart(envelope, "SideWall_UpperBeam_" .. sx, Vector3.new(wallThick, 4.0, body.halfZ * 2),
            CFrame.new(xWall, floorY + wallH - 2.0, 0), wallColor, wallMaterial)
        -- เสาซอยและช่องแสงระบายอากาศด้านบนสแตนเชียร์
        for z = -100, 100, 40 do
            PartBuilder.makePart(envelope, "SidePillar_" .. sx .. "_" .. z, Vector3.new(wallThick + 0.6, wallH, 3.5),
                CFrame.new(xWall, floorY + wallH / 2, z), Color3.fromRGB(215, 212, 205), Enum.Material.Concrete)
        end
    end

    -- ผนังปิดมุมทั้ง 4 (X = ±124..±150, Z = ±86..±120)
    for _, sx in ipairs({ -1, 1 }) do
        for _, sz in ipairs({ -1, 1 }) do
            PartBuilder.makePart(envelope, "CornerWall_" .. sx .. "_" .. sz, Vector3.new(26, wallH, wallThick),
                CFrame.new(sx * 137, floorY + wallH / 2, sz * (body.halfZ - wallThick / 2)), wallColor, wallMaterial)
        end
    end

    -- เพดานและหลังคาโรงยิมชั้น 3 (Y = floorY + wallH = 71.0)
    PartBuilder.makePart(envelope, "GymRoofSlab", Vector3.new(body.halfX * 2, 2.0, body.halfZ * 2),
        CFrame.new(0, floorY + wallH + 1.0, 0), Color3.fromRGB(235, 235, 240), Enum.Material.Concrete)

    -- โครงถักเหล็กหลังคาโรงยิม (Roof Trusses) + โคมไฟสปอตไลท์สนามกีฬา
    local lightsFolder = Instance.new("Folder")
    lightsFolder.Name = "GymHighBayLights"
    lightsFolder.Parent = floor3

    for z = -60, 60, 40 do
        PartBuilder.makePart(envelope, "RoofTruss_" .. z, Vector3.new(body.halfX * 2 - 8, 1.8, 1.5),
            CFrame.new(0, floorY + wallH - 0.9, z), Color3.fromRGB(70, 78, 88), Enum.Material.Metal)
        for _, lx in ipairs({ -73, 0, 73 }) do
            PartBuilder.addPointLight(lightsFolder, "GymLight_" .. lx .. "_" .. z,
                Vector3.new(lx, floorY + wallH - 2.0, z), Color3.fromRGB(255, 252, 245), 60, 1.65)
        end
    end

    print("🏀⚽ [Floor 3 Built] สร้างชั้น 3 สนามฟุตซอล + สนามบาส + สแตนเชียร์ + ห้องน้ำ + ห้องเก็บของ สำเร็จ!")
end

return Floor3_SportsArena
