--[[
    ThaiHorrorMapGenerator.server.lua
    ใส่ใน: ServerScriptService
    หน้าที่: เนรมิตแมพ "ล่าท้าผีไทยโบราณ" (Thai Ghost Hunting Map)
    ประกอบด้วย:
      1. จุดเริ่มต้น: แคมป์รถตู้ทีมงานล่าท้าผี (Safe Zone)
      2. เรือนไทยโบราณร้าง (ใต้ถุนสูง, ชานเรือน, ห้องนอนมุ้งเก่า, ห้องพระผ้ายันต์)
      3. ป่าช้าเก่า & ศาลเพียงตา (เจดีย์อัฐิ, หลุมศพ, ต้นไม้ใหญ่ผูกผ้าสามสี)
      4. ศาลาริมน้ำ & สะพานไม้ผุ (บึงน้ำมืดมิด หมอกลอยเรี่ยผิวน้ำ)
      5. โบสถ์วัดร้างกลางดึก (กำแพงแก้วโบราณ, องค์พระพุทธรูปปรักหักพัง)
      6. บรรยากาศ: แสงจันทร์มืดสลัว, ควันธูป, หมอกหนา, เสียงหมาหอนและดนตรีไทยหลอนๆ
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

print("=================================================")
print("🏮 กำลังสร้างแมพ: สถานที่ล่าท้าผีไทยโบราณ (Thai Horror)...")
print("=================================================")

----------------------------------------------------------------------
-- 1. บรรยากาศแสง & เงาแบบไทยโบราณ (THAI HORROR ATMOSPHERE)
----------------------------------------------------------------------
local function setupThaiLighting()
    Lighting.ClockTime = 0.2 -- คืนเดือนมืด มีแสงจันทร์สลัว
    Lighting.Brightness = 0.05
    Lighting.OutdoorAmbient = Color3.fromRGB(8, 12, 16)
    Lighting.Ambient = Color3.fromRGB(12, 14, 18)
    Lighting.FogColor = Color3.fromRGB(15, 20, 25)
    Lighting.FogStart = 10
    Lighting.FogEnd = 160
    Lighting.GlobalShadows = true

    -- บรรยากาศหมอกเรี่ยพื้น
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atmosphere.Density = 0.58
    atmosphere.Offset = 0.2
    atmosphere.Color = Color3.fromRGB(18, 22, 28)
    atmosphere.Decay = Color3.fromRGB(30, 35, 40)
    atmosphere.Glare = 0
    atmosphere.Haze = 2.5

    -- โทนสีเขียว/น้ำเงินหม่นแบบหนังสยองขวัญไทย (Shutter / นางนาก vibe)
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
    cc.Saturation = -0.35
    cc.Contrast = 0.25
    cc.Brightness = -0.04
    cc.TintColor = Color3.fromRGB(200, 225, 240)

    local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.5
    bloom.Size = 20
    bloom.Threshold = 0.85

    -- เสียงบรรยากาศลมหวีดหวิว & จิ้งหรีดกลางคืน
    local ambientSound = Workspace:FindFirstChild("ThaiNightAmbience") or Instance.new("Sound")
    ambientSound.Name = "ThaiNightAmbience"
    ambientSound.SoundId = "rbxassetid://9114221580" -- เสียงลมและบรรยากาศกลางคืน
    ambientSound.Looped = true
    ambientSound.Volume = 0.7
    ambientSound.Parent = Workspace
    ambientSound:Play()
end

----------------------------------------------------------------------
-- 2. ฟังก์ชันพื้นฐานสร้างวัตถุ (HELPER FUNCTIONS)
----------------------------------------------------------------------
local function createPart(parent, name, size, cframe, color, material, anchored)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color or Color3.fromRGB(60, 50, 40)
    part.Material = material or Enum.Material.Wood
    part.Anchored = (anchored == nil) and true or anchored
    part.CastShadow = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

-- สร้างเสาไฟ/โคมไฟโบราณแบบกระพริบหลอนๆ
local function createLantern(parent, position, lightColor)
    local pole = createPart(parent, "LampPole", Vector3.new(0.6, 9, 0.6), CFrame.new(position + Vector3.new(0, 4.5, 0)), Color3.fromRGB(35, 30, 25), Enum.Material.Wood)
    local lantern = createPart(parent, "LanternBody", Vector3.new(1.4, 1.6, 1.4), CFrame.new(position + Vector3.new(0, 8.5, 0)), Color3.fromRGB(255, 180, 80), Enum.Material.Neon)
    
    local light = Instance.new("PointLight")
    light.Color = lightColor or Color3.fromRGB(255, 160, 60) -- แสงเทียน/ตะเกียงสีส้ม
    light.Range = 25
    light.Brightness = 2.0
    light.Shadows = true
    light.Parent = lantern

    -- ไฟกระพริบเหมือนเปลวเทียนไหวตามลม
    task.spawn(function()
        local orig = light.Brightness
        while lantern and lantern.Parent do
            task.wait(math.random(2, 6))
            for i = 1, math.random(2, 4) do
                light.Brightness = orig * 0.3
                task.wait(0.08)
                light.Brightness = orig * 1.2
                task.wait(0.06)
                light.Brightness = orig
            end
        end
    end)
    return lantern
end

-- ลบแมพเก่าออกถ้ามี
if Workspace:FindFirstChild("ThaiHorrorMap") then
    Workspace.ThaiHorrorMap:Destroy()
end

local map = Instance.new("Model")
map.Name = "ThaiHorrorMap"
map.Parent = Workspace

----------------------------------------------------------------------
-- 3. พื้นที่ผืนดิน & บึงน้ำ (TERRAIN & GROUND)
----------------------------------------------------------------------
local groundSize = Vector3.new(350, 2, 350)
local mainGround = createPart(map, "DirtGround", groundSize, CFrame.new(0, -1, 0), Color3.fromRGB(30, 28, 24), Enum.Material.Ground)

-- บึงน้ำมืดมิด (Dark Swamp Lake) ทางทิศตะวันออก
local lakeWater = createPart(map, "SwampLake", Vector3.new(120, 1.8, 140), CFrame.new(90, -0.9, 0), Color3.fromRGB(15, 25, 22), Enum.Material.Glass)
lakeWater.Transparency = 0.4
lakeWater.CanCollide = false

-- ทางเดินดิน (Dirt Trails)
local function createTrail(cframe, size)
    createPart(map, "Trail", size, cframe, Color3.fromRGB(45, 40, 32), Enum.Material.Mud)
end
createTrail(CFrame.new(0, 0.05, 70), Vector3.new(8, 0.2, 80))  -- ทางจากแคมป์ไปเรือนไทย
createTrail(CFrame.new(45, 0.05, 0), Vector3.new(80, 0.2, 8))   -- ทางไปศาลาริมน้ำ
createTrail(CFrame.new(-45, 0.05, 0), Vector3.new(80, 0.2, 8))  -- ทางไปป่าช้า
createTrail(CFrame.new(0, 0.05, -70), Vector3.new(8, 0.2, 80)) -- ทางไปโบสถ์วัดร้าง

----------------------------------------------------------------------
-- 4. โซนที่ 1: แคมป์รถตู้ทีมงานล่าท้าผี (SAFE ZONE - THE VAN)
----------------------------------------------------------------------
local vanCamp = Instance.new("Model")
vanCamp.Name = "VanCamp_SafeZone"
vanCamp.Parent = map

local vanCenter = Vector3.new(0, 0, 110)

-- รถตู้ทีมงาน (The Ghost Hunter Van)
local vanBody = createPart(vanCamp, "VanBody", Vector3.new(10, 6, 18), CFrame.new(vanCenter + Vector3.new(0, 3.5, 0)), Color3.fromRGB(35, 38, 45), Enum.Material.Metal)
local vanRoof = createPart(vanCamp, "VanRoof", Vector3.new(9.6, 0.5, 17.6), CFrame.new(vanCenter + Vector3.new(0, 6.7, 0)), Color3.fromRGB(20, 20, 22), Enum.Material.Metal)
-- ล้อรถ
createPart(vanCamp, "Wheel1", Vector3.new(1.2, 2.5, 2.5), CFrame.new(vanCenter + Vector3.new(-5.2, 1.25, 5)), Color3.fromRGB(15, 15, 15), Enum.Material.SmoothPlastic)
createPart(vanCamp, "Wheel2", Vector3.new(1.2, 2.5, 2.5), CFrame.new(vanCenter + Vector3.new(5.2, 1.25, 5)), Color3.fromRGB(15, 15, 15), Enum.Material.SmoothPlastic)
createPart(vanCamp, "Wheel3", Vector3.new(1.2, 2.5, 2.5), CFrame.new(vanCenter + Vector3.new(-5.2, 1.25, -5)), Color3.fromRGB(15, 15, 15), Enum.Material.SmoothPlastic)
createPart(vanCamp, "Wheel4", Vector3.new(1.2, 2.5, 2.5), CFrame.new(vanCenter + Vector3.new(5.2, 1.25, -5)), Color3.fromRGB(15, 15, 15), Enum.Material.SmoothPlastic)

-- แสงไฟนีออนสีขาวจากแคมป์ (จุดปลอดภัย)
local campLight = Instance.new("PointLight")
campLight.Color = Color3.fromRGB(230, 240, 255)
campLight.Range = 35
campLight.Brightness = 2.5
campLight.Parent = vanBody

-- โต๊ะวางอุปกรณ์ล่าท้าผีหน้ารถตู้
local gearTable = createPart(vanCamp, "EquipmentTable", Vector3.new(8, 2.8, 3.5), CFrame.new(vanCenter + Vector3.new(9, 1.4, 0)), Color3.fromRGB(80, 80, 85), Enum.Material.Metal)

-- จุดเกิดผู้เล่น (Spawn Location ในแคมป์)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "HunterSpawn"
spawn.Size = Vector3.new(10, 1, 10)
spawn.CFrame = CFrame.new(vanCenter + Vector3.new(0, 0.6, 12))
spawn.Anchored = true
spawn.CanCollide = false
spawn.Transparency = 1
spawn.Parent = vanCamp

-- ป้ายชื่อทีมล่าท้าผี
local board = createPart(vanCamp, "MissionBoard", Vector3.new(6, 4, 0.3), CFrame.new(vanCenter + Vector3.new(-8, 3, 0)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(30, 30, 35), Enum.Material.Wood)
local sGui = Instance.new("SurfaceGui")
sGui.Face = Enum.NormalId.Back
sGui.Parent = board
local bText = Instance.new("TextLabel")
bText.Size = UDim2.new(1, 0, 1, 0)
bText.BackgroundTransparency = 1
bText.TextColor3 = Color3.fromRGB(255, 200, 80)
bText.TextScaled = true
bText.Font = Enum.Font.SpecialElite
bText.Text = "🚨 ภารกิจล่าท้าผีไทย\n[SAFE ZONE - VAN CAMP]\nเตรียมอุปกรณ์ให้พร้อม!"
bText.Parent = sGui

----------------------------------------------------------------------
-- 5. โซนที่ 2: เรือนไทยโบราณร้าง (ABANDONED TRADITIONAL THAI HOUSE)
----------------------------------------------------------------------
local thaiHouse = Instance.new("Model")
thaiHouse.Name = "AbandonedThaiHouse"
thaiHouse.Parent = map

local housePos = Vector3.new(0, 0, 0)
local houseW, houseL = 36, 42
local stiltH = 7 -- ใต้ถุนสูง 7 studs ตามแบบเรือนไทยโบราณ
local wallH = 12

-- เสาไม้ยกใต้ถุนสูง 12 ต้น
local darkWoodColor = Color3.fromRGB(55, 38, 26)
local plankColor = Color3.fromRGB(65, 45, 30)

for x = -houseW/2 + 3, houseW/2 - 3, (houseW - 6)/3 do
    for z = -houseL/2 + 3, houseL/2 - 3, (houseL - 6)/3 do
        createPart(thaiHouse, "StiltPillar", Vector3.new(1.4, stiltH, 1.4), CFrame.new(housePos.X + x, stiltH/2, housePos.Z + z), darkWoodColor, Enum.Material.Wood)
    end
end

-- ใต้ถุนเรือน (มีโอ่งมังกรเก่า / เกวียนหัก)
createPart(thaiHouse, "WaterJar", Vector3.new(3, 4, 3), CFrame.new(housePos + Vector3.new(-8, 2, 5)), Color3.fromRGB(80, 50, 35), Enum.Material.Cobblestone)
createPart(thaiHouse, "BrokenCart", Vector3.new(5, 2, 8), CFrame.new(housePos + Vector3.new(7, 1, -4)) * CFrame.Angles(0, math.rad(30), 0), darkWoodColor, Enum.Material.Wood)

-- พื้นชานเรือนไม้ (Floor Deck)
local floorDeck = createPart(thaiHouse, "HouseFloor", Vector3.new(houseW, 1, houseL), CFrame.new(housePos.X, stiltH + 0.5, housePos.Z), plankColor, Enum.Material.WoodPlanks)

-- บันไดไม้ขึ้นเรือนไทย
for step = 1, 7 do
    local stepY = (step - 1) * (stiltH / 7) + 0.5
    local stepZ = houseL/2 + (7 - step) * 1.5
    createPart(thaiHouse, "StairStep", Vector3.new(6, 0.8, 1.6), CFrame.new(0, stepY, stepZ), darkWoodColor, Enum.Material.Wood)
end

-- กำแพงฝาปะกนเรือนไทย
-- กำแพงด้านนอกรอบเรือน (เว้นประตูทางขึ้น)
createPart(thaiHouse, "WallBack", Vector3.new(houseW, wallH, 0.8), CFrame.new(housePos.X, stiltH + wallH/2, housePos.Z - houseL/2), plankColor)
createPart(thaiHouse, "WallLeft", Vector3.new(0.8, wallH, houseL), CFrame.new(housePos.X - houseW/2, stiltH + wallH/2, housePos.Z), plankColor)
createPart(thaiHouse, "WallRight", Vector3.new(0.8, wallH, houseL), CFrame.new(housePos.X + houseW/2, stiltH + wallH/2, housePos.Z), plankColor)
-- กำแพงด้านหน้า (มีช่องบันได)
createPart(thaiHouse, "WallFrontL", Vector3.new((houseW - 8)/2, wallH, 0.8), CFrame.new(housePos.X - (houseW + 8)/4, stiltH + wallH/2, housePos.Z + houseL/2), plankColor)
createPart(thaiHouse, "WallFrontR", Vector3.new((houseW - 8)/2, wallH, 0.8), CFrame.new(housePos.X + (houseW + 8)/4, stiltH + wallH/2, housePos.Z + houseL/2), plankColor)

-- หลังคาทรงจั่วเรือนไทย (Thai Gable Roof)
local roofBaseY = stiltH + wallH
local roofSlopeL = createPart(thaiHouse, "RoofL", Vector3.new(houseW/2 + 4, 1, houseL + 4), CFrame.new(housePos.X - houseW/4, roofBaseY + 4, housePos.Z) * CFrame.Angles(0, 0, math.rad(28)), Color3.fromRGB(45, 30, 20), Enum.Material.Wood)
local roofSlopeR = createPart(thaiHouse, "RoofR", Vector3.new(houseW/2 + 4, 1, houseL + 4), CFrame.new(housePos.X + houseW/4, roofBaseY + 4, housePos.Z) * CFrame.Angles(0, 0, math.rad(-28)), Color3.fromRGB(45, 30, 20), Enum.Material.Wood)

-- ภายในเรือนไทย: ห้องนอน & ห้องพระ
-- ผนังกั้นห้องนอน
createPart(thaiHouse, "InnerWall", Vector3.new(houseW - 12, wallH, 0.8), CFrame.new(housePos.X + 6, stiltH + wallH/2, housePos.Z - 6), plankColor)

-- หิ้งพระโบราณ & โต๊ะหมู่บูชาผุๆ มีผ้ายันต์
local altar = createPart(thaiHouse, "AltarTable", Vector3.new(7, 3, 3), CFrame.new(housePos.X - 10, stiltH + 2.5, housePos.Z - houseL/2 + 3), Color3.fromRGB(40, 25, 18), Enum.Material.Wood)
-- กระถางธูปและเทียนไขสีเหลืองบนโต๊ะหมู่
local incenseBurner = createPart(thaiHouse, "IncensePot", Vector3.new(1.2, 0.8, 1.2), CFrame.new(housePos.X - 10, stiltH + 4.4, housePos.Z - houseL/2 + 3), Color3.fromRGB(160, 140, 60), Enum.Material.Metal)

-- ควันธูปสีขาวลอยขึ้น (Smoke Effect)
local smoke = Instance.new("Smoke")
smoke.Color = Color3.fromRGB(220, 220, 220)
smoke.Size = 0.4
smoke.RiseVelocity = 1.2
smoke.Opacity = 0.5
smoke.Parent = incenseBurner

-- ผ้ายันต์สีแดงติดผนังห้องพระ
local talisman = createPart(thaiHouse, "RedTalisman", Vector3.new(2.5, 3.5, 0.2), CFrame.new(housePos.X - 10, stiltH + 7, housePos.Z - houseL/2 + 0.6), Color3.fromRGB(180, 20, 20), Enum.Material.Fabric)

-- เตียงไม้โบราณพร้อมโครงมุ้งขาดๆ ในห้องนอน
local bed = createPart(thaiHouse, "OldBed", Vector3.new(8, 1.5, 12), CFrame.new(housePos.X + 10, stiltH + 1.7, housePos.Z - houseL/2 + 9), Color3.fromRGB(50, 35, 25), Enum.Material.Wood)
-- โครงเสามุ้ง 4 เสา
createPart(thaiHouse, "BedPost1", Vector3.new(0.4, 7, 0.4), CFrame.new(housePos.X + 6.2, stiltH + 4.5, housePos.Z - houseL/2 + 3.2), darkWoodColor)
createPart(thaiHouse, "BedPost2", Vector3.new(0.4, 7, 0.4), CFrame.new(housePos.X + 13.8, stiltH + 4.5, housePos.Z - houseL/2 + 3.2), darkWoodColor)
createPart(thaiHouse, "BedPost3", Vector3.new(0.4, 7, 0.4), CFrame.new(housePos.X + 6.2, stiltH + 4.5, housePos.Z - houseL/2 + 14.8), darkWoodColor)
createPart(thaiHouse, "BedPost4", Vector3.new(0.4, 7, 0.4), CFrame.new(housePos.X + 13.8, stiltH + 4.5, housePos.Z - houseL/2 + 14.8), darkWoodColor)

-- มุ้งขาดสีขาวซีด
local net = createPart(thaiHouse, "MosquitoNet", Vector3.new(7.6, 6, 11.6), CFrame.new(housePos.X + 10, stiltH + 4.8, housePos.Z - houseL/2 + 9), Color3.fromRGB(220, 220, 220), Enum.Material.Fabric)
net.Transparency = 0.75
net.CanCollide = false

-- โคมไฟแขวนชานเรือน
createLantern(thaiHouse, housePos + Vector3.new(0, stiltH, 10), Color3.fromRGB(255, 140, 50))

----------------------------------------------------------------------
-- 6. โซนที่ 3: ป่าช้าเก่า & เจดีย์เก็บอัฐิ (OLD GRAVEYARD & SHED)
----------------------------------------------------------------------
local cemetery = Instance.new("Model")
cemetery.Name = "AncientGraveyard"
cemetery.Parent = map

local gravePos = Vector3.new(-95, 0, 0)

-- ต้นโพธิ์/ไทรใหญ่กลางป่าช้า (Big Spooky Tree)
local treeTrunk = createPart(cemetery, "BanyanTrunk", Vector3.new(6, 26, 6), CFrame.new(gravePos + Vector3.new(0, 13, 0)), Color3.fromRGB(40, 32, 25), Enum.Material.Wood)
local leaves = createPart(cemetery, "TreeFoliage", Vector3.new(28, 14, 28), CFrame.new(gravePos + Vector3.new(0, 26, 0)), Color3.fromRGB(20, 30, 20), Enum.Material.Grass)

-- ผ้าสามสีผูกรอบต้นไม้ (เหลือง ขาว แดง)
createPart(cemetery, "TriColorYellow", Vector3.new(6.4, 0.8, 6.4), CFrame.new(gravePos + Vector3.new(0, 6, 0)), Color3.fromRGB(255, 215, 0), Enum.Material.Fabric)
createPart(cemetery, "TriColorWhite", Vector3.new(6.4, 0.8, 6.4), CFrame.new(gravePos + Vector3.new(0, 7, 0)), Color3.fromRGB(240, 240, 240), Enum.Material.Fabric)
createPart(cemetery, "TriColorRed", Vector3.new(6.4, 0.8, 6.4), CFrame.new(gravePos + Vector3.new(0, 8, 0)), Color3.fromRGB(220, 30, 30), Enum.Material.Fabric)

-- ศาลพระภูมิเก่า / ศาลเพียงตา (Broken Spirit House)
local shrineBase = createPart(cemetery, "ShrinePillar", Vector3.new(1.2, 5, 1.2), CFrame.new(gravePos + Vector3.new(12, 2.5, 8)), Color3.fromRGB(70, 70, 65), Enum.Material.Concrete)
local shrineHouse = createPart(cemetery, "ShrineTop", Vector3.new(3.5, 3, 3.5), CFrame.new(gravePos + Vector3.new(12, 6, 8)) * CFrame.Angles(0, 0, math.rad(12)), Color3.fromRGB(150, 40, 40), Enum.Material.Wood)

-- น้ำแดงไหว้ศาล (Red Soda Bottle)
local redBottle = createPart(cemetery, "RedSoda", Vector3.new(0.6, 1.2, 0.6), CFrame.new(gravePos + Vector3.new(12.5, 5.8, 7.5)), Color3.fromRGB(255, 0, 50), Enum.Material.Neon)

-- ฟังก์ชันสร้างเจดีย์เก็บอัฐิโบราณ (Thai Stupa / Chedi)
local function buildChedi(pos, rot)
    local chedi = Instance.new("Model")
    chedi.Name = "Chedi"
    chedi.Parent = cemetery

    local stoneCol = Color3.fromRGB(75, 75, 70)
    createPart(chedi, "Base", Vector3.new(5, 2, 5), CFrame.new(pos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, rot, 0), stoneCol, Enum.Material.Slate)
    createPart(chedi, "Mid", Vector3.new(3.5, 3.5, 3.5), CFrame.new(pos + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, rot, 0), stoneCol, Enum.Material.Slate)
    createPart(chedi, "Spire", Vector3.new(1.8, 4.5, 1.8), CFrame.new(pos + Vector3.new(0, 7.5, 0)) * CFrame.Angles(0, rot, 0), stoneCol, Enum.Material.Slate)
end

-- สปอว์นเจดีย์อัฐิ 4 องค์รอบป่าช้า
buildChedi(gravePos + Vector3.new(-15, 0, -12), math.rad(15))
buildChedi(gravePos + Vector3.new(-18, 0, 10), math.rad(-20))
buildChedi(gravePos + Vector3.new(8, 0, -18), math.rad(45))
buildChedi(gravePos + Vector3.new(15, 0, 18), math.rad(-10))

-- หลุมฝังศพดินนูนๆ (Mounds)
for i = 1, 5 do
    local offset = Vector3.new(math.random(-20, 20), 0.5, math.random(-20, 20))
    createPart(cemetery, "GraveMound", Vector3.new(4, 1.2, 6.5), CFrame.new(gravePos + offset) * CFrame.Angles(0, math.rad(math.random(0, 180)), 0), Color3.fromRGB(35, 30, 24), Enum.Material.Mud)
end

----------------------------------------------------------------------
-- 7. โซนที่ 4: ศาลาริมน้ำ & สะพานไม้ผุ (WATERFRONT PAVILION & PIER)
----------------------------------------------------------------------
local pierZone = Instance.new("Model")
pierZone.Name = "WaterfrontPavilion"
pierZone.Parent = map

local pierStart = Vector3.new(40, 0, 0)
local pavilionPos = Vector3.new(90, 0, 0)

-- สะพานไม้ผุพาดลงน้ำ
local bridgeL = 50
createPart(pierZone, "WoodBridge", Vector3.new(bridgeL, 0.8, 5.5), CFrame.new(pierStart.X + bridgeL/2, 1.5, pierStart.Z), Color3.fromRGB(50, 38, 28), Enum.Material.WoodPlanks)

-- เสาสะพานปักลงในน้ำ
for bx = 45, 85, 12 do
    createPart(pierZone, "BridgePillarL", Vector3.new(0.8, 8, 0.8), CFrame.new(bx, -0.5, -2.5), darkWoodColor)
    createPart(pierZone, "BridgePillarR", Vector3.new(0.8, 8, 0.8), CFrame.new(bx, -0.5, 2.5), darkWoodColor)
end

-- ศาลาทรงไทยริมน้ำ (Waterfront Pavilion)
local pavW, pavL = 22, 22
-- พื้นศาลา
createPart(pierZone, "PavilionDeck", Vector3.new(pavW, 1.2, pavL), CFrame.new(pavilionPos.X, 1.8, pavilionPos.Z), plankColor, Enum.Material.WoodPlanks)

-- เสาศาลา 4 ต้น
local pavH = 10
createPart(pierZone, "PavCol1", Vector3.new(1.2, pavH, 1.2), CFrame.new(pavilionPos.X - 9, pavH/2 + 1.8, pavilionPos.Z - 9), darkWoodColor)
createPart(pierZone, "PavCol2", Vector3.new(1.2, pavH, 1.2), CFrame.new(pavilionPos.X + 9, pavH/2 + 1.8, pavilionPos.Z - 9), darkWoodColor)
createPart(pierZone, "PavCol3", Vector3.new(1.2, pavH, 1.2), CFrame.new(pavilionPos.X - 9, pavH/2 + 1.8, pavilionPos.Z + 9), darkWoodColor)
createPart(pierZone, "PavCol4", Vector3.new(1.2, pavH, 1.2), CFrame.new(pavilionPos.X + 9, pavH/2 + 1.8, pavilionPos.Z + 9), darkWoodColor)

-- หลังคาทรงปั้นหยา
local pavRoof = createPart(pierZone, "PavRoof", Vector3.new(pavW + 4, 3, pavL + 4), CFrame.new(pavilionPos.X, pavH + 3, pavilionPos.Z), Color3.fromRGB(45, 30, 20), Enum.Material.Wood)

-- ตะเกียงแกว่งริมน้ำ แสงสีฟ้าอมเขียว (จุดสิงสถิตของผีพราย)
local waterLight = createLantern(pierZone, pavilionPos + Vector3.new(0, 1.8, 0), Color3.fromRGB(100, 220, 200))

----------------------------------------------------------------------
-- 8. โซนที่ 5: โบสถ์วัดร้างกลางดึก (ABANDONED TEMPLE / OLD CHAPEL)
----------------------------------------------------------------------
local templeZone = Instance.new("Model")
templeZone.Name = "AbandonedTemple"
templeZone.Parent = map

local templePos = Vector3.new(0, 0, -100)
local tW, tL, tH = 32, 50, 16

-- ฐานไพทีโบสถ์ก่ออิฐเก่า
createPart(templeZone, "TemplePlinth", Vector3.new(tW + 8, 2.5, tL + 8), CFrame.new(templePos.X, 1.25, templePos.Z), Color3.fromRGB(60, 55, 50), Enum.Material.Brick)

-- กำแพงโบสถ์เก่าแตกร้าว (Crumbling Brick Walls)
local brickColor = Color3.fromRGB(75, 45, 35)
createPart(templeZone, "TempleWallL", Vector3.new(1.5, tH, tL), CFrame.new(templePos.X - tW/2, tH/2 + 2.5, templePos.Z), brickColor, Enum.Material.Brick)
createPart(templeZone, "TempleWallR", Vector3.new(1.5, tH, tL), CFrame.new(templePos.X + tW/2, tH/2 + 2.5, templePos.Z), brickColor, Enum.Material.Brick)
createPart(templeZone, "TempleWallBack", Vector3.new(tW, tH, 1.5), CFrame.new(templePos.X, tH/2 + 2.5, templePos.Z - tL/2), brickColor, Enum.Material.Brick)

-- เสาระเบียงด้านหน้าโบสถ์
createPart(templeZone, "PillarL", Vector3.new(2, tH, 2), CFrame.new(templePos.X - 8, tH/2 + 2.5, templePos.Z + tL/2), Color3.fromRGB(80, 75, 70), Enum.Material.Slate)
createPart(templeZone, "PillarR", Vector3.new(2, tH, 2), CFrame.new(templePos.X + 8, tH/2 + 2.5, templePos.Z + tL/2), Color3.fromRGB(80, 75, 70), Enum.Material.Slate)

-- องค์พระประธานเก่าปรักหักพัง (Old Buddha Statue)
local statueBase = createPart(templeZone, "StatueBase", Vector3.new(10, 3, 7), CFrame.new(templePos.X, 4, templePos.Z - tL/2 + 8), Color3.fromRGB(85, 80, 75), Enum.Material.Slate)
local statueTorso = createPart(templeZone, "StatueTorso", Vector3.new(6, 7, 4), CFrame.new(templePos.X, 9, templePos.Z - tL/2 + 8), Color3.fromRGB(150, 130, 70), Enum.Material.Slate) -- ทองเหลืองโบราณลอกคราบ
local statueHead = createPart(templeZone, "StatueHead", Vector3.new(3.5, 4, 3.5), CFrame.new(templePos.X, 14.5, templePos.Z - tL/2 + 8), Color3.fromRGB(140, 120, 65), Enum.Material.Slate)

-- แสงสลัวสีทองซีดๆ ส่องกระทบหน้าพระพุทธรูป
local buddhaLight = Instance.new("PointLight")
buddhaLight.Color = Color3.fromRGB(255, 210, 120)
buddhaLight.Range = 22
buddhaLight.Brightness = 1.2
buddhaLight.Parent = statueHead

print("=================================================")
print("🏮 แมพสถานที่ล่าท้าผีไทยโบราณ สร้างเสร็จสมบูรณ์แล้ว!")
print("=================================================")
