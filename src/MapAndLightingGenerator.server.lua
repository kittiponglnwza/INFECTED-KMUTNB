--[[
    MapAndLightingGenerator.server.lua
    ใส่ใน: ServerScriptService
    หน้าที่: ปรับแต่ง Lighting ให้มืดสลัว หลอน และเนรมิตฉากห้องทดลอง/อาคารร้างพร้อมไฟกระพริบอัตโนมัติ
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

----------------------------------------------------------------------
-- 1. ตั้งค่าบรรยากาศ (HORROR LIGHTING SETUP)
----------------------------------------------------------------------
local function setupHorrorLighting()
    Lighting.ClockTime = 14 -- บ่ายสอง แสงสว่างจ้า
    Lighting.Brightness = 2.5
    Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
    Lighting.Ambient = Color3.fromRGB(150, 150, 150)
    Lighting.FogColor = Color3.fromRGB(200, 200, 200)
    Lighting.FogStart = 100
    Lighting.FogEnd = 10000 -- ปิดหมอกมืด มองเห็นได้ไกลทั่วทั้งแมพ
    Lighting.GlobalShadows = true

    -- Atmosphere (ลดหมอกให้โปร่งใส สบายตา)
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atmosphere.Density = 0.1
    atmosphere.Offset = 0.25
    atmosphere.Color = Color3.fromRGB(200, 210, 225)
    atmosphere.Decay = Color3.fromRGB(220, 220, 230)
    atmosphere.Glare = 0
    atmosphere.Haze = 0

    -- Color Correction (สีสดใส สว่าง ไม่มืดหม่น)
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
    cc.Saturation = 0.2
    cc.Contrast = 0.05
    cc.Brightness = 0.1
    cc.TintColor = Color3.fromRGB(255, 255, 255)

    -- Bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.4
    bloom.Size = 10
    bloom.Threshold = 0.9
end

----------------------------------------------------------------------
-- 2. ฟังก์ชันช่วยสร้างกำแพงและชิ้นส่วน
----------------------------------------------------------------------
local function createPart(parent, name, size, cframe, color, material, anchored)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color or Color3.fromRGB(50, 50, 55)
    part.Material = material or Enum.Material.Concrete
    part.Anchored = (anchored == nil) and true or anchored
    part.CastShadow = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

-- สร้างหลอดไฟเพดานที่มีระบบไฟกระพริบหลอนๆ
local function createFlickeringLight(parent, position, lightColor)
    local fixture = createPart(parent, "LightFixture", Vector3.new(2, 0.4, 2), CFrame.new(position), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
    
    local bulb = createPart(parent, "Bulb", Vector3.new(1.2, 0.3, 1.2), CFrame.new(position - Vector3.new(0, 0.2, 0)), Color3.fromRGB(255, 240, 180), Enum.Material.Neon)
    
    local pointLight = Instance.new("PointLight")
    pointLight.Color = lightColor or Color3.fromRGB(255, 240, 200)
    pointLight.Range = 40
    pointLight.Brightness = 3.0
    pointLight.Shadows = true
    pointLight.Parent = bulb

    -- สุ่มไฟกระพริบ
    task.spawn(function()
        local originalBrightness = pointLight.Brightness
        while bulb and bulb.Parent do
            task.wait(math.random(3, 10))
            for i = 1, math.random(2, 6) do
                pointLight.Brightness = 0
                bulb.Material = Enum.Material.SmoothPlastic
                task.wait(math.random(5, 15) / 100)
                pointLight.Brightness = originalBrightness
                bulb.Material = Enum.Material.Neon
                task.wait(math.random(5, 20) / 100)
            end
        end
    end)

    return bulb
end

----------------------------------------------------------------------
-- 3. เนรมิตแผนที่ศูนย์วิจัย / อาคารปิดตาย (BUILD MAP)
----------------------------------------------------------------------
local function buildHorrorFacility()
    local facility = Instance.new("Model")
    facility.Name = "HorrorFacility"
    facility.Parent = Workspace

    local wallColor = Color3.fromRGB(45, 48, 52)
    local floorColor = Color3.fromRGB(35, 36, 38)
    local ceilingColor = Color3.fromRGB(28, 28, 30)

    -- ขนาดพื้นฐาน
    local wallH = 14
    local hallL = 120
    local hallW = 16

    -- พื้นทางเดินหลัก (Main Hallway)
    createPart(facility, "HallFloor", Vector3.new(hallW, 1, hallL), CFrame.new(0, 0, 0), floorColor, Enum.Material.Concrete)
    -- เพดานทางเดินหลัก
    createPart(facility, "HallCeiling", Vector3.new(hallW, 1, hallL), CFrame.new(0, wallH, 0), ceilingColor, Enum.Material.Concrete)

    -- กำแพงทางเดินหลัก (ซ้ายและขวา มีช่องเปิดเข้าห้อง)
    -- กำแพงซ้าย
    createPart(facility, "WallL1", Vector3.new(1, wallH, 30), CFrame.new(-hallW/2, wallH/2, -40), wallColor)
    createPart(facility, "WallL2", Vector3.new(1, wallH, 30), CFrame.new(-hallW/2, wallH/2, 0), wallColor)
    createPart(facility, "WallL3", Vector3.new(1, wallH, 30), CFrame.new(-hallW/2, wallH/2, 40), wallColor)

    -- กำแพงขวา
    createPart(facility, "WallR1", Vector3.new(1, wallH, 30), CFrame.new(hallW/2, wallH/2, -40), wallColor)
    createPart(facility, "WallR2", Vector3.new(1, wallH, 30), CFrame.new(hallW/2, wallH/2, 0), wallColor)
    createPart(facility, "WallR3", Vector3.new(1, wallH, 30), CFrame.new(hallW/2, wallH/2, 40), wallColor)

    -- กำแพงปลายทางด้านเกิด (Spawn End)
    createPart(facility, "BackWall", Vector3.new(hallW, wallH, 1), CFrame.new(0, wallH/2, hallL/2), wallColor)

    -- จุดเกิดผู้เล่น (Spawn Point)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "FacilitySpawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.CFrame = CFrame.new(0, 0.5, (hallL/2) - 8)
    spawn.Anchored = true
    spawn.CanCollide = false
    spawn.Transparency = 1
    spawn.Parent = facility

    -- ฟังก์ชันสร้างห้องย่อย
    local function buildRoom(roomName, centerPos, roomW, roomL)
        local room = Instance.new("Model")
        room.Name = roomName
        room.Parent = facility

        -- พื้น & เพดานห้อง
        createPart(room, "Floor", Vector3.new(roomW, 1, roomL), CFrame.new(centerPos.X, 0, centerPos.Z), floorColor, Enum.Material.WoodPlanks)
        createPart(room, "Ceiling", Vector3.new(roomW, 1, roomL), CFrame.new(centerPos.X, wallH, centerPos.Z), ceilingColor)

        -- กำแพงด้านนอกรอบห้อง
        local halfW, halfL = roomW/2, roomL/2
        -- กำแพงหน้า/หลัง
        createPart(room, "WallNorth", Vector3.new(roomW, wallH, 1), CFrame.new(centerPos.X, wallH/2, centerPos.Z - halfL), wallColor)
        createPart(room, "WallSouth", Vector3.new(roomW, wallH, 1), CFrame.new(centerPos.X, wallH/2, centerPos.Z + halfL), wallColor)
        
        -- กำแพงด้านนอก (ซ้ายหรือขวาสุด)
        if centerPos.X < 0 then
            createPart(room, "WallOuter", Vector3.new(1, wallH, roomL), CFrame.new(centerPos.X - halfW, wallH/2, centerPos.Z), wallColor)
        else
            createPart(room, "WallOuter", Vector3.new(1, wallH, roomL), CFrame.new(centerPos.X + halfW, wallH/2, centerPos.Z), wallColor)
        end

        -- เฟอร์นิเจอร์หลอนๆ ตกแต่งในห้อง (โต๊ะคว่ำ / ลังไม้)
        local tablePart = createPart(room, "BrokenTable", Vector3.new(7, 3, 4), CFrame.new(centerPos.X, 1.5, centerPos.Z) * CFrame.Angles(0, math.rad(25), math.rad(5)), Color3.fromRGB(60, 45, 35), Enum.Material.Wood)

        -- ดวงไฟในห้อง (แสงสลัวมาก)
        createFlickeringLight(room, centerPos + Vector3.new(0, wallH - 0.5, 0), Color3.fromRGB(200, 160, 120))

        return room
    end

    -- สร้าง 3 ห้องสำหรับซ่อนฟิวส์ (Fuses)
    buildRoom("Room_A", Vector3.new(-28, 0, -20), 40, 32)
    buildRoom("Room_B", Vector3.new(28, 0, -20), 40, 32)
    buildRoom("Room_C", Vector3.new(-28, 0, 20), 40, 32)

    -- ไฟสลัวตลอดทางเดินหลัก
    createFlickeringLight(facility, Vector3.new(0, wallH - 0.5, -35), Color3.fromRGB(255, 120, 100))
    createFlickeringLight(facility, Vector3.new(0, wallH - 0.5, 0), Color3.fromRGB(150, 180, 255))
    createFlickeringLight(facility, Vector3.new(0, wallH - 0.5, 35), Color3.fromRGB(220, 220, 180))

    ----------------------------------------------------------------------
    -- 4. ประตูทางออกหลัก (MAIN EXIT GATE) & แผงฟิวส์ (GENERATOR)
    ----------------------------------------------------------------------
    local exitArea = Instance.new("Model")
    exitArea.Name = "ExitArea"
    exitArea.Parent = facility

    -- กำแพงด้านหน้า (มีช่องประตู)
    local gateZ = -(hallL/2)
    createPart(exitArea, "FrontWallL", Vector3.new(4, wallH, 1), CFrame.new(-6, wallH/2, gateZ), wallColor)
    createPart(exitArea, "FrontWallR", Vector3.new(4, wallH, 1), CFrame.new(6, wallH/2, gateZ), wallColor)
    createPart(exitArea, "FrontWallTop", Vector3.new(hallW, 4, 1), CFrame.new(0, wallH - 2, gateZ), wallColor)

    -- ประตูเหล็กทางออก (Exit Door)
    local exitDoor = createPart(exitArea, "ExitDoor", Vector3.new(8, 10, 1.2), CFrame.new(0, 5, gateZ), Color3.fromRGB(120, 30, 30), Enum.Material.Metal)
    exitDoor.Name = "ExitDoor"

    -- ตู้เบรกเกอร์ / เครื่องปั่นไฟข้างประตู
    local generator = createPart(exitArea, "GeneratorBox", Vector3.new(3, 5, 2), CFrame.new(6, 2.5, gateZ + 2), Color3.fromRGB(40, 60, 45), Enum.Material.Metal)
    generator.Name = "GeneratorBox"

    local genLight = Instance.new("PointLight")
    genLight.Name = "StatusLight"
    genLight.Color = Color3.fromRGB(255, 30, 30) -- สีแดงแปลว่าไฟยังไม่ติด
    genLight.Range = 10
    genLight.Brightness = 1.5
    genLight.Parent = generator

    -- ป้ายบอกสถานะบนตู้ไฟ
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.Parent = generator

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SpecialElite
    textLabel.Text = "POWER OFFLINE\n[NEED 3 FUSES]"
    textLabel.Name = "StatusText"
    textLabel.Parent = surfaceGui

    print("[Horror Facility] แผนที่และระบบบรรยากาศถูกสร้างเสร็จเรียบร้อยแล้ว!")
end

-- รันฟังก์ชัน
setupHorrorLighting()
buildHorrorFacility()
