--[[
    ElevatorBuilder.lua
    สร้างโถงลิฟต์โดยสารคู่ (Twin Passenger Elevator Bank) สมจริงสำหรับอาคาร 40 ปี มจพ.
      - ผนังหน้าลิฟต์ก่อปิดทึบเต็มกรอบพร้อมซุ้มวงกบสแตนเลส (ไม่มีรูโหว่ทะลุเห็นปล่องโล่งด้านหลัง)
      - ประตูลิฟต์สแตนเลสแยกซ้าย-ขวา (Center-Opening Twin Doors) พร้อมร่องกลางและธรณีประตูสแตนเลส
      - จอดิจิทัล LED บอกชั้นเหนือประตูลิฟต์ + แผงปุ่มกดเรียกลิฟต์ตรงกลาง + ป้ายบอกชั้นอาคาร 40 ปี
      - มี ProximityPrompt กด [E] เพื่อขึ้น/ลงชั้นถัดไปได้จริง
]]

local Players = game:GetService("Players")
local PartBuilder = require(script.Parent.PartBuilder)
local Layout = require(script.Parent.Building40Layout)

local ElevatorBuilder = {}

local WALL_COLOR = Color3.fromRGB(240, 237, 230)
local GRANITE_DARK = Color3.fromRGB(48, 52, 58)
local STEEL_BRIGHT = Color3.fromRGB(195, 200, 206)
local STEEL_DARK = Color3.fromRGB(125, 130, 138)
local SEAM_BLACK = Color3.fromRGB(22, 24, 28)
local LED_ORANGE = Color3.fromRGB(255, 145, 20)

-- สร้างคอร์ลิฟต์สำหรับชั้นที่กำหนด (floorNum = 1, 2, 3)
-- extraDepthBand = true สำหรับชั้น 1 ที่ต้องกั้นผนังส่วนใน Z = ±44..±86 ให้เสมอแนวลานจอดรถ
function ElevatorBuilder.build(parent, def, floorNum, floorY, wallH, extraDepthBand)
    local core = Layout.CORE
    local wallThick = Layout.WALL_THICK

    local m = Instance.new("Model")
    m.Name = string.format("%s_F%d", def.name, floorNum)
    m.Parent = parent

    local cx, cz, d = def.centerX, def.centerZ, def.doorDir
    local sz = (cz > 0) and 1 or -1
    local halfW = core.sideWidth / 2 -- 19
    local halfD = core.depth / 2     -- 17

    -- 1. ผนังปล่องลิฟต์ 3 ด้าน (หลังตึก Z=±120, ด้านใน Z=±86, และด้านหลังปล่อง X = cx - d*18)
    PartBuilder.makePart(m, "ShaftWall_OuterZ", Vector3.new(core.sideWidth, wallH, wallThick),
        CFrame.new(cx, floorY + wallH / 2, sz * (core.outerZ - wallThick / 2)), WALL_COLOR, Enum.Material.Concrete)
    PartBuilder.makePart(m, "ShaftWall_InnerZ", Vector3.new(core.sideWidth, wallH, wallThick),
        CFrame.new(cx, floorY + wallH / 2, sz * (core.innerZ + wallThick / 2)), WALL_COLOR, Enum.Material.Concrete)
    PartBuilder.makePart(m, "ShaftWall_BackX", Vector3.new(wallThick, wallH, core.depth),
        CFrame.new(cx - d * (halfW - wallThick / 2), floorY + wallH / 2, cz), WALL_COLOR, Enum.Material.Concrete)

    -- 2. ผนังด้านหน้าลิฟต์ (Front Facade ที่ X = cx + d * (halfW - wallThick/2))
    --    เจาะช่องประตูลิฟต์ 2 ช่องที่ cz - 8.5 และ cz + 8.5 (กว้างช่องละ 8.0, สูง 11.0)
    --    ปิดผนังข้างซ้าย-ขวา เสาคั่นกลาง และผนังส่วนบนทึบสนิท 100%
    local frontWallX = cx + d * (halfW - wallThick / 2)
    local doorOpenW = 8.0
    local doorOpenH = 11.0
    local elevOffsets = { -8.5, 8.5 }

    -- ผนังส่วนบนเหนือวงกบลิฟต์ยาวเต็มความกว้างปล่อง (Y = floorY + 11 .. floorY + wallH)
    local upperH = wallH - doorOpenH
    PartBuilder.makePart(m, "Facade_UpperWall", Vector3.new(wallThick, upperH, core.depth),
        CFrame.new(frontWallX, floorY + doorOpenH + upperH / 2, cz), WALL_COLOR, Enum.Material.Concrete)

    -- เสาผนังขนาบซ้ายสุด (Z = cz - 17 .. cz - 12.5, กว้าง 4.5)
    PartBuilder.makePart(m, "Facade_Pillar_Left", Vector3.new(wallThick, doorOpenH, 4.5),
        CFrame.new(frontWallX, floorY + doorOpenH / 2, cz - 14.75), WALL_COLOR, Enum.Material.Concrete)
    -- เสาผนังคั่นกลางระหว่างลิฟต์ 2 ตัว (Z = cz - 4.5 .. cz + 4.5, กว้าง 9.0)
    PartBuilder.makePart(m, "Facade_Pillar_Center", Vector3.new(wallThick, doorOpenH, 9.0),
        CFrame.new(frontWallX, floorY + doorOpenH / 2, cz), WALL_COLOR, Enum.Material.Concrete)
    -- เสาผนังขนาบขวาสุด (Z = cz + 12.5 .. cz + 17, กว้าง 4.5)
    PartBuilder.makePart(m, "Facade_Pillar_Right", Vector3.new(wallThick, doorOpenH, 4.5),
        CFrame.new(frontWallX, floorY + doorOpenH / 2, cz + 14.75), WALL_COLOR, Enum.Material.Concrete)

    -- แผ่นหินแกรนิตสีเข้มประดับผนังหน้าลิฟต์ (Luxury Elevator Lobby Cladding)
    PartBuilder.makePart(m, "GraniteClad_Center", Vector3.new(0.25, doorOpenH + 2.5, 5.4),
        CFrame.new(frontWallX + d * (wallThick / 2 + 0.12), floorY + (doorOpenH + 2.5) / 2, cz),
        GRANITE_DARK, Enum.Material.Granite)

    -- 3. สร้างประตูลิฟต์คู่ 2 ตัว พร้อมวงกบสแตนเลสและป้ายไฟ LED บอกชั้น
    local indText = (floorNum == 1 and "[ FL.1 ] ▲")
        or (floorNum == 2 and "[ FL.2 ] ▲▼")
        or string.format("[ FL.%d ] ▼", floorNum)

    for idx, offZ in ipairs(elevOffsets) do
        local ez = cz + offZ
        local doorX = frontWallX - d * 0.15
        local frameFaceX = frontWallX + d * (wallThick / 2 + 0.2)

        -- ธรณีประตูสแตนเลส (Threshold Sill)
        PartBuilder.makePart(m, "Threshold_" .. idx, Vector3.new(wallThick + 0.6, 0.16, doorOpenW + 0.8),
            CFrame.new(frontWallX, floorY + 0.08, ez), STEEL_DARK, Enum.Material.Metal)

        -- วงกบสแตนเลสซ้าย-ขวา-บน (Stainless Steel Door Jamb & Header Frame)
        PartBuilder.makePart(m, "JambL_" .. idx, Vector3.new(0.5, doorOpenH + 0.6, 0.7),
            CFrame.new(frameFaceX, floorY + (doorOpenH + 0.6) / 2, ez - doorOpenW / 2 - 0.35), GRANITE_DARK, Enum.Material.Metal)
        PartBuilder.makePart(m, "JambR_" .. idx, Vector3.new(0.5, doorOpenH + 0.6, 0.7),
            CFrame.new(frameFaceX, floorY + (doorOpenH + 0.6) / 2, ez + doorOpenW / 2 + 0.35), GRANITE_DARK, Enum.Material.Metal)
        PartBuilder.makePart(m, "JambTop_" .. idx, Vector3.new(0.5, 0.8, doorOpenW + 1.4),
            CFrame.new(frameFaceX, floorY + doorOpenH + 0.4, ez), GRANITE_DARK, Enum.Material.Metal)

        -- บานประตูลิฟต์สแตนเลส 2 บานประกบกัน (Left Leaf & Right Leaf) + ร่องดำตรงกลาง
        local leafW = (doorOpenW - 0.14) / 2
        PartBuilder.makePart(m, "DoorLeaf_A_" .. idx, Vector3.new(0.45, doorOpenH, leafW),
            CFrame.new(doorX, floorY + doorOpenH / 2, ez - leafW / 2 - 0.04), STEEL_BRIGHT, Enum.Material.Metal)
        PartBuilder.makePart(m, "DoorLeaf_B_" .. idx, Vector3.new(0.45, doorOpenH, leafW),
            CFrame.new(doorX, floorY + doorOpenH / 2, ez + leafW / 2 + 0.04), STEEL_BRIGHT, Enum.Material.Metal)
        PartBuilder.makePart(m, "DoorCenterSeam_" .. idx, Vector3.new(0.48, doorOpenH, 0.12),
            CFrame.new(doorX, floorY + doorOpenH / 2, ez), SEAM_BLACK, Enum.Material.SmoothPlastic)

        -- ป้ายไฟดิจิทัล LED เหนือประตูลิฟต์แต่ละบาน
        PartBuilder.makeSign(m, "DigitalIndicator_" .. idx, indText, Vector3.new(0.35, 1.5, 4.6),
            Vector3.new(frameFaceX + d * 0.2, floorY + doorOpenH + 1.6, ez),
            d > 0 and Enum.NormalId.Right or Enum.NormalId.Left,
            SEAM_BLACK, LED_ORANGE)
    end

    -- 4. แผงปุ่มกดเรียกลิฟต์ตรงกลาง (Hall Call Panel) + ป้ายทำเนียบชั้นอาคาร 40 ปี มจพ.
    local callBoxX = frontWallX + d * (wallThick / 2 + 0.3)
    local callBox = PartBuilder.makePart(m, "HallCallPanel", Vector3.new(0.25, 2.6, 1.2),
        CFrame.new(callBoxX, floorY + 4.8, cz), STEEL_BRIGHT, Enum.Material.Metal)
    PartBuilder.makePart(m, "CallBtn_Up", Vector3.new(0.3, 0.45, 0.45),
        CFrame.new(callBoxX + d * 0.08, floorY + 5.2, cz), Color3.fromRGB(80, 240, 120), Enum.Material.Neon)
    PartBuilder.makePart(m, "CallBtn_Down", Vector3.new(0.3, 0.45, 0.45),
        CFrame.new(callBoxX + d * 0.08, floorY + 4.4, cz), LED_ORANGE, Enum.Material.Neon)

    -- ป้ายบอกชั้นหน้าลิฟต์
    PartBuilder.makeSign(m, "DirectorySign",
        "ลิฟต์โดยสาร อาคาร 40 ปี มจพ.\n[3] สนามกีฬาในร่ม  [2] โรงอาหาร  [1] ลานจอดรถ",
        Vector3.new(0.3, 2.8, 4.8),
        Vector3.new(callBoxX, floorY + 8.5, cz),
        d > 0 and Enum.NormalId.Right or Enum.NormalId.Left,
        Color3.fromRGB(128, 28, 38), Color3.fromRGB(255, 255, 255))

    -- ระบบกด [E] เรียกลิฟต์เพื่อสลับชั้นได้จริง (1 -> 2 -> 3 -> 1)
    local nextFloor = (floorNum % 3) + 1
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "ElevatorCallPrompt"
    prompt.ActionText = string.format("โดยสารลิฟต์ไป ชั้น %d", nextFloor)
    prompt.ObjectText = string.format("ลิฟต์อาคาร 40 ปี (ปัจจุบัน: ชั้น %d)", floorNum)
    prompt.HoldDuration = 0.4
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = callBox

    prompt.Triggered:Connect(function(player)
        local char = player and player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local destY = Layout.floorY(nextFloor) + 3.5
            local destX = cx + d * (halfW + 6)
            hrp.CFrame = CFrame.new(destX, destY, cz)
        end
    end)

    -- 5. สำหรับชั้น 1: กั้นผนังส่วนใน (Z = ±44..±86) ให้เสมอแนวห้องมุมและลานจอดรถ
    if extraDepthBand then
        local bandCenterZ = sz * 82
        PartBuilder.makePart(m, "Floor_BandF1", Vector3.new(core.sideWidth, 0.1, core.bandDepth),
            CFrame.new(cx, floorY + 0.06, bandCenterZ), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic)

        local innerLen = core.innerZ - core.bandInnerZ -- 42
        local innerMidZ = sz * ((core.innerZ + core.bandInnerZ) / 2)
        PartBuilder.makePart(m, "InnerWall_Hall", Vector3.new(wallThick, wallH, innerLen),
            CFrame.new(frontWallX, floorY + wallH / 2, innerMidZ), WALL_COLOR, Enum.Material.Concrete)
        PartBuilder.makePart(m, "InnerWall_BackX", Vector3.new(wallThick, wallH, innerLen),
            CFrame.new(cx - d * (halfW - wallThick / 2), floorY + wallH / 2, innerMidZ), WALL_COLOR, Enum.Material.Concrete)
        PartBuilder.makePart(m, "InnerWall_Parking", Vector3.new(core.sideWidth, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, sz * (core.bandInnerZ + wallThick / 2)), WALL_COLOR, Enum.Material.Concrete)
        PartBuilder.makeSign(m, "Sign_ParkingSide", "ลิฟต์โดยสาร\nELEVATOR",
            Vector3.new(16, 3.8, 0.4),
            Vector3.new(cx, floorY + wallH / 2, sz * (core.bandInnerZ - 0.2)),
            sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
            GRANITE_DARK, Color3.fromRGB(255, 255, 255))
    end

    return m
end

return ElevatorBuilder
