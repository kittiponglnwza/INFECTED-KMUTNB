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
        Vector3.new(body.halfX * 2, 0.1, core.bandInnerZ * 2),
        CFrame.new(0, floorY + 0.05, 0),
        Color3.fromRGB(48, 50, 54),
        Enum.Material.Asphalt
    )

    -- เส้นจราจรแบ่งเลนกึ่งกลางสีเหลืองคู่
    PartBuilder.makePart(parkingZone, "YellowLine_1", Vector3.new(280, 0.05, 0.8), CFrame.new(-5, floorY + 0.1, -1.0), Color3.fromRGB(255, 215, 30), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(parkingZone, "YellowLine_2", Vector3.new(280, 0.05, 0.8), CFrame.new(-5, floorY + 0.1,  1.0), Color3.fromRGB(255, 215, 30), Enum.Material.SmoothPlastic)

    -- ช่องจอดรถ 10 ซอง พร้อมหมอนหยุดล้อ
    for p = 1, 5 do
        local pX = -110 + ((p - 1) * 32)
        PartBuilder.makePart(parkingZone, "Stripe_Top_" .. p, Vector3.new(1.0, 0.05, 28), CFrame.new(pX, floorY + 0.1, -30), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
        PartBuilder.makePart(parkingZone, "WheelStop_T_" .. p, Vector3.new(12, 0.9, 1.5), CFrame.new(pX + 16, floorY + 0.5, -41), Color3.fromRGB(235, 185, 30), Enum.Material.Concrete)

        PartBuilder.makePart(parkingZone, "Stripe_Bot_" .. p, Vector3.new(1.0, 0.05, 28), CFrame.new(pX, floorY + 0.1, 30), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
        PartBuilder.makePart(parkingZone, "WheelStop_B_" .. p, Vector3.new(12, 0.9, 1.5), CFrame.new(pX + 16, floorY + 0.5, 41), Color3.fromRGB(235, 185, 30), Enum.Material.Concrete)
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
        Vector3.new(28, 0.08, 7.0),
        Vector3.new(-25, floorY + 0.12, 0),
        Enum.NormalId.Top,
        Color3.fromRGB(48, 50, 54),
        Color3.fromRGB(255, 220, 50)
    )

    -- ลูกศรทางเข้า-ออกฝั่งขวา (+X)
    PartBuilder.makeSign(parkingZone, "Arrow_Out_2X", "→ ทางออก (EXIT) →", Vector3.new(24, 0.08, 4.5), Vector3.new(120, floorY + 0.12, -22), Enum.NormalId.Top, Color3.fromRGB(48, 50, 54), Color3.fromRGB(255, 255, 255))
    PartBuilder.makeSign(parkingZone, "Arrow_In_2X",  "← ทางเข้า (IN) ←",  Vector3.new(24, 0.08, 4.5), Vector3.new(120, floorY + 0.12,  22), Enum.NormalId.Top, Color3.fromRGB(48, 50, 54), Color3.fromRGB(255, 255, 255))

    ------------------------------------------------------------------
    -- 3. ห้องมุมทั้ง 4 (ปิดตายทึบ 4 ด้าน เรียงเสมอขอบตึก Z = ±120 และขอบลานจอดรถ Z = ±44)
    --    ขนาดแต่ละห้อง: กว้าง 80 (X = ±70..±150), ลึก 76 (Z = ±44..±120)
    ------------------------------------------------------------------
    local function createSealedRoom(roomName, posX, posZ, sizeX, sizeZ, signText, signColor)
        local model = Instance.new("Model")
        model.Name = roomName
        model.Parent = floor1

        PartBuilder.makePart(model, "Floor", Vector3.new(sizeX, 0.1, sizeZ), CFrame.new(posX, floorY + 0.06, posZ), Color3.fromRGB(230, 230, 230), Enum.Material.SmoothPlastic)

        PartBuilder.makePart(model, "Wall_North", Vector3.new(sizeX, wallH, wallThick), CFrame.new(posX, floorY + wallH/2, posZ - sizeZ/2 + wallThick/2), wallColor, wallMaterial)
        PartBuilder.makePart(model, "Wall_South", Vector3.new(sizeX, wallH, wallThick), CFrame.new(posX, floorY + wallH/2, posZ + sizeZ/2 - wallThick/2), wallColor, wallMaterial)
        PartBuilder.makePart(model, "Wall_West",  Vector3.new(wallThick, wallH, sizeZ), CFrame.new(posX - sizeX/2 + wallThick/2, floorY + wallH/2, posZ), wallColor, wallMaterial)
        PartBuilder.makePart(model, "Wall_East",  Vector3.new(wallThick, wallH, sizeZ), CFrame.new(posX + sizeX/2 - wallThick/2, floorY + wallH/2, posZ), wallColor, wallMaterial)

        local signZ = (posZ > 0) and (posZ - sizeZ/2 - 0.2) or (posZ + sizeZ/2 + 0.2)
        local signFace = (posZ > 0) and Enum.NormalId.Front or Enum.NormalId.Back
        PartBuilder.makeSign(model, "Sign", signText, Vector3.new(22, 5.0, 0.4), Vector3.new(posX, floorY + wallH/2, signZ), signFace, signColor, Color3.fromRGB(255, 255, 255))
        return model
    end

    createSealedRoom("Room_TopLeft",          -109, -82, 82, 76, "ห้อง\nROOM (SEALED)",   Color3.fromRGB(80, 85, 95))
    createSealedRoom("Room_Cafe_TopRight",     109, -82, 82, 76, "คาเฟ่\nCAFE (SEALED)",  Color3.fromRGB(120, 75, 40))
    createSealedRoom("Room_BottomLeft",       -109,  82, 82, 76, "ห้อง\nROOM (SEALED)",   Color3.fromRGB(80, 85, 95))
    createSealedRoom("Room_Bank_BottomRight",  109,  82, 82, 76, "ธนาคาร\nBANK (SEALED)", Color3.fromRGB(0, 52, 138))

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
        local bandCenterZ = sz * 82
        PartBuilder.makePart(coreModel, "Floor", Vector3.new(core.sideWidth, 0.1, core.bandDepth),
            CFrame.new(def.centerX, floorY + 0.06, bandCenterZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)

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
            Vector3.new(16, 4.0, 0.4),
            Vector3.new(def.centerX, floorY + wallH/2, sz * (core.bandInnerZ - 0.2)),
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
    PartBuilder.makePart(topEntrance, "Floor", Vector3.new(core.centerWidth, 0.1, core.bandDepth),
        CFrame.new(0, floorY + 0.06, -82), Color3.fromRGB(230, 225, 215), Enum.Material.SmoothPlastic)
    PartBuilder.makeSign(topEntrance, "Sign", "ทางเข้าออก\nENTRANCE / EXIT",
        Vector3.new(22, 0.08, 4.0), Vector3.new(0, floorY + 0.12, -82), Enum.NormalId.Top,
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
    PartBuilder.makePart(botEntrance, "Floor", Vector3.new(core.centerWidth, 0.1, core.bandDepth),
        CFrame.new(0, floorY + 0.06, 82), Color3.fromRGB(230, 225, 215), Enum.Material.SmoothPlastic)
    PartBuilder.makeSign(botEntrance, "Sign", "ทางเข้าออก\nENTRANCE / EXIT",
        Vector3.new(22, 0.08, 4.0), Vector3.new(0, floorY + 0.12, 82), Enum.NormalId.Top,
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
