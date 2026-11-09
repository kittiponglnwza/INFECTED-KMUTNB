--[[
    KMUTNBBuilding40.server.lua (HIGH FIDELITY EDITION)
    ใส่ใน: ServerScriptService
    หน้าที่: สร้างสถาปัตยกรรม "อาคาร 40 ปี มจพ. (อาคารกิจกรรมนักศึกษา 40 ปี / อาคาร 77)"
            จำลองจากสถานที่จริงแบบละเอียดสูง (Realistic Scale & Details)
    
    รายละเอียดสถาปัตยกรรม:
      - ปรับแสงเป็น "เวลากลางวัน (Daytime)" แดดส่องสว่าง มองเห็นตัวตึกได้ชัดเจน 100%
      - สวนปาล์ม มจพ. & ถนนหน้าตึก ฝั่งตรงข้ามคณะวิทยาศาสตร์ประยุกต์
      - ลานบันไดทางขึ้น เสาคอนกรีตทรงกลมรองรับชายคาหน้าตึก
      - ป้ายชื่อทางการ "อาคาร 40 ปี พระจอมเกล้าพระนครเหนือ"
      - โครงสร้างตึกสูง 11 ชั้น (High-rise Facade พร้อมกรอบหน้าต่างระบายอากาศ)
      - ชั้น 1: โถงสูงแกรนิตโต้, ศูนย์บริการนักศึกษา, ธนาคารกรุงเทพ & ตู้ ATM, โถงลิฟต์ 4 ตัว
      - ชั้น 2: ศูนย์อาหาร มจพ. (Canteen), ซุ้มร้านค้า, แถวโต๊ะสแตนเลส
      - ชั้น 3: ลานกิจกรรมกีฬาในร่ม (สนามปิงปอง "เล้าไก่" & สนามบาสเกตบอล)
      - จุดซื้อปืนตามผนัง (Wall-Buys)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

print("=========================================================")
print("🏛️ กำลังสร้างอาคาร 40 ปี มจพ. ฉบับของจริง (Realistic High-Fidelity)...")
print("=========================================================")

----------------------------------------------------------------------
-- 1. ปรับแสงเป็นเวลากลางวัน (REALISTIC DAYTIME LIGHTING)
----------------------------------------------------------------------
Lighting.ClockTime = 13.5 -- บ่ายโมงครึ่ง แดดส่องสว่าง ชัดเจนทุกมุม
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(140, 145, 155)
Lighting.Ambient = Color3.fromRGB(150, 155, 160)
Lighting.FogEnd = 100000 -- ปิดหมอก มองเห็นได้ไกลสุดตา
Lighting.GlobalShadows = true

-- ท้องฟ้าและโทนสีโปร่งสบายตา
local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
cc.Saturation = 0.15
cc.Contrast = 0.08
cc.Brightness = 0.03
cc.TintColor = Color3.fromRGB(255, 255, 255)

local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
sky.SunAngularSize = 15

----------------------------------------------------------------------
-- 2. ฟังก์ชันช่วยสร้างวัตถุ (BUILDING HELPERS)
----------------------------------------------------------------------
local function createPart(parent, name, size, cframe, color, material, anchored)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color or Color3.fromRGB(225, 225, 220)
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = (anchored == nil) and true or anchored
    part.CastShadow = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function createCylinder(parent, name, size, cframe, color, material)
    local cyl = Instance.new("Part")
    cyl.Shape = Enum.PartType.Cylinder
    cyl.Name = name
    cyl.Size = size
    cyl.CFrame = cframe
    cyl.Color = color or Color3.fromRGB(220, 220, 215)
    cyl.Material = material or Enum.Material.Concrete
    cyl.Anchored = true
    cyl.CastShadow = true
    cyl.TopSurface = Enum.SurfaceType.Smooth
    cyl.BottomSurface = Enum.SurfaceType.Smooth
    cyl.Parent = parent
    return cyl
end

-- ลบโมเดลเก่าออก
if Workspace:FindFirstChild("KMUTNB_Building40") then
    Workspace.KMUTNB_Building40:Destroy()
end

local building = Instance.new("Model")
building.Name = "KMUTNB_Building40"
building.Parent = Workspace

----------------------------------------------------------------------
-- 3. ขนาดและสัดส่วนจริงของตึก (REALISTIC ARCHITECTURE DIMENSIONS)
----------------------------------------------------------------------
local bW = 160 -- หน้ากว้างของตึก (160 studs)
local bL = 130 -- ความลึกของตึก (130 studs)
local fH = 16  -- ความสูงของแต่ละชั้น (16 studs)
local totalFloors = 11 -- ตึก 11 ชั้นตามของจริง

-- โทนสีและวัสดุของจริง มจพ.
local colConcreteLight = Color3.fromRGB(230, 230, 225) -- ปูนสีขาวอมครีม
local colConcreteGrey = Color3.fromRGB(180, 185, 190)  -- คอนกรีตเสาเทา
local colMaroonKMUTNB = Color3.fromRGB(140, 25, 25)    -- สีแดงเลือดหมู มจพ.
local colGlassTint = Color3.fromRGB(150, 190, 215)     -- กระจกตัดแสงสีเขียวฟ้า
local colGraniteFloor = Color3.fromRGB(240, 240, 245)  -- กระเบื้องแกรนิตโต้
local colRoad = Color3.fromRGB(50, 50, 55)             -- ถนนยางมะตอย

-- ถนนและทางเท้าหน้าตึก มจพ.
local road = createPart(building, "KMUTNB_CampusRoad", Vector3.new(300, 2, 260), CFrame.new(0, -1, 20), colRoad, Enum.Material.Asphalt)
-- ทางเท้ารอบตึก (Sidewalk)
local sidewalk = createPart(building, "Sidewalk", Vector3.new(bW + 40, 1.2, bL + 50), CFrame.new(0, 0.6, 5), Color3.fromRGB(195, 195, 195), Enum.Material.Cobblestone)

-- สวนปาล์ม มจพ. ด้านหน้าตึก (KMUTNB Palm Garden)
local function createPalmTree(pos)
    local trunk = createCylinder(building, "PalmTrunk", Vector3.new(16, 2, 2), CFrame.new(pos + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(90, 75, 60), Enum.Material.Wood)
    local leaves = createPart(building, "PalmLeaves", Vector3.new(12, 4, 12), CFrame.new(pos + Vector3.new(0, 16, 0)), Color3.fromRGB(50, 110, 45), Enum.Material.Grass)
end

for px = -bW/2 + 10, bW/2 - 10, 25 do
    createPalmTree(Vector3.new(px, 1.2, bL/2 + 35))
end

----------------------------------------------------------------------
-- 4. ลานหน้าตึก, ป้ายชื่อ และทางเข้าหลัก (GRAND ENTRANCE & FACADE)
----------------------------------------------------------------------
-- บันไดลานกว้างขึ้นตัวตึก (Plaza Stairs)
for step = 1, 4 do
    local stepW = bW - 20 - (step * 2)
    local stepY = 1.2 + (step * 0.7)
    local stepZ = bL/2 + 25 - (step * 2.5)
    createPart(building, "PlazaStep_" .. step, Vector3.new(stepW, 0.7, 3), CFrame.new(0, stepY, stepZ), Color3.fromRGB(210, 210, 215), Enum.Material.Concrete)
end

-- ลานชานพักหน้าตึก (Main Entrance Podium)
local podium = createPart(building, "EntrancePodium", Vector3.new(bW - 20, 1.5, 20), CFrame.new(0, 4, bL/2 + 10), colGraniteFloor, Enum.Material.SmoothPlastic)

-- ป้ายชื่ออาคาร 40 ปี พระจอมเกล้าพระนครเหนือ อย่างเป็นทางการ
local grandSign = createPart(building, "KMUTNB_BuildingSign", Vector3.new(32, 4.5, 1.2), CFrame.new(0, 4.5, bL/2 + 22), colMaroonKMUTNB, Enum.Material.Concrete)
local signGui = Instance.new("SurfaceGui")
signGui.Face = Enum.NormalId.Back
signGui.Parent = grandSign
local signTxt = Instance.new("TextLabel")
signTxt.Size = UDim2.new(1, 0, 1, 0)
signTxt.BackgroundTransparency = 1
signTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
signTxt.TextScaled = true
signTxt.Font = Enum.Font.GothamBold
signTxt.Text = "อาคาร 40 ปี พระจอมเกล้าพระนครเหนือ (อาคาร 77)\nKMUTNB 40th ANNIVERSARY BUILDING"
signTxt.Parent = signGui

-- เสากลมต้นใหญ่ 6 ต้น รองรับชายคาหน้าตึก (Colonnade Facade)
for c = 1, 6 do
    local cx = -bW/2 + 20 + ((c - 1) * ((bW - 40) / 5))
    createCylinder(building, "GrandPillar_" .. c, Vector3.new(fH * 2, 4, 4), CFrame.new(cx, 4 + fH, bL/2 + 8) * CFrame.Angles(0, 0, math.rad(90)), colConcreteGrey, Enum.Material.Concrete)
end

-- หลังคาชายคาซุ้มทางเข้าด้านหน้า (Front Canopy)
local canopy = createPart(building, "FrontCanopy", Vector3.new(bW - 10, 2.5, 24), CFrame.new(0, 4 + fH * 2, bL/2 + 8), colMaroonKMUTNB, Enum.Material.SmoothPlastic)

-- จุดเกิดผู้เล่น (Spawn Points ที่ลานหน้าตึก)
local spawnPad = Instance.new("SpawnLocation")
spawnPad.Name = "PlazaSpawnLocation"
spawnPad.Size = Vector3.new(16, 1, 16)
spawnPad.CFrame = CFrame.new(0, 4.8, bL/2 + 5)
spawnPad.Anchored = true
spawnPad.CanCollide = false
spawnPad.Transparency = 1
spawnPad.Parent = building

----------------------------------------------------------------------
-- 5. ชั้น 1: โถงใหญ่, ศูนย์บริการนักศึกษา, ธนาคารกรุงเทพ & โถงลิฟต์
----------------------------------------------------------------------
local floor1 = Instance.new("Model")
floor1.Name = "Floor_1_MainLobby"
floor1.Parent = building

local f1BaseY = 4
-- พื้นหินแกรนิตชั้น 1
createPart(floor1, "Floor1_Tile", Vector3.new(bW, 1.5, bL), CFrame.new(0, f1BaseY, 0), colGraniteFloor, Enum.Material.SmoothPlastic)

-- แผงกระจกบานใหญ่หน้าทางเข้า (Glass Curtain Wall)
createPart(floor1, "CurtainWallL", Vector3.new((bW - 24)/2, fH, 1.2), CFrame.new(-(bW + 24)/4, f1BaseY + fH/2, bL/2), colGlassTint, Enum.Material.Glass).Transparency = 0.55
createPart(floor1, "CurtainWallR", Vector3.new((bW - 24)/2, fH, 1.2), CFrame.new((bW + 24)/4, f1BaseY + fH/2, bL/2), colGlassTint, Enum.Material.Glass).Transparency = 0.55
-- ซุ้มประตูกระจกอัตโนมัติบานเลื่อน
createPart(floor1, "AutoDoorFrame", Vector3.new(24, 2, 1.5), CFrame.new(0, f1BaseY + 11, bL/2), colConcreteGrey, Enum.Material.Metal)

-- กำแพงด้านข้างและด้านหลัง
createPart(floor1, "OuterWallL1", Vector3.new(1.8, fH, bL), CFrame.new(-bW/2, f1BaseY + fH/2, 0), colConcreteLight)
createPart(floor1, "OuterWallR1", Vector3.new(1.8, fH, bL), CFrame.new(bW/2, f1BaseY + fH/2, 0), colConcreteLight)
createPart(floor1, "OuterWallB1", Vector3.new(bW, fH, 1.8), CFrame.new(0, f1BaseY + fH/2, -bL/2), colConcreteLight)

-- ภายในชั้น 1: สาขาธนาคารกรุงเทพ (Bangkok Bank KMUTNB)
local bank = Instance.new("Model")
bank.Name = "BangkokBank_Branch"
bank.Parent = floor1

local bankSign = createPart(bank, "BankSign", Vector3.new(24, 3.5, 0.5), CFrame.new(-bW/2 + 25, f1BaseY + 10, 25), Color3.fromRGB(0, 50, 130), Enum.Material.SmoothPlastic)
local bGui = Instance.new("SurfaceGui")
bGui.Face = Enum.NormalId.Back
bGui.Parent = bankSign
local bTxt = Instance.new("TextLabel")
bTxt.Size = UDim2.new(1, 0, 1, 0)
bTxt.BackgroundTransparency = 1
bTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
bTxt.TextScaled = true
bTxt.Font = Enum.Font.GothamBold
bTxt.Text = "ธนาคารกรุงเทพ สาขา มจพ. (Bangkok Bank)"
bTxt.Parent = bGui

-- เคาน์เตอร์ธนาคาร & กระจกกั้น
createPart(bank, "BankCounterDesk", Vector3.new(24, 3.8, 4), CFrame.new(-bW/2 + 25, f1BaseY + 1.9, 25), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic)
-- ตู้ ATM ธนาคารกรุงเทพ 2 ตู้
for atm = 1, 2 do
    local atmX = -bW/2 + 8 + (atm * 4)
    local atmBox = createPart(bank, "ATM_" .. atm, Vector3.new(3, 7, 3), CFrame.new(atmX, f1BaseY + 3.5, 38), Color3.fromRGB(0, 45, 125), Enum.Material.Metal)
    local aGui = Instance.new("SurfaceGui")
    aGui.Face = Enum.NormalId.Back
    aGui.Parent = atmBox
    local aTxt = Instance.new("TextLabel")
    aTxt.Size = UDim2.new(1, 0, 0.4, 0)
    aTxt.BackgroundTransparency = 1
    aTxt.TextColor3 = Color3.fromRGB(255, 215, 0)
    aTxt.TextScaled = true
    aTxt.Font = Enum.Font.GothamBold
    aTxt.Text = "ATM BBL\nมจพ."
    aTxt.Parent = aGui
end

-- เคาน์เตอร์ศูนย์บริการนักศึกษา มจพ. (Student Service Center)
local sDesk = createPart(floor1, "StudentServiceDesk", Vector3.new(34, 3.8, 5), CFrame.new(bW/2 - 30, f1BaseY + 1.9, 22), Color3.fromRGB(60, 65, 75), Enum.Material.WoodPlanks)
local sSign = createPart(floor1, "StudentServiceSign", Vector3.new(34, 3, 0.5), CFrame.new(bW/2 - 30, f1BaseY + 9, 22), colMaroonKMUTNB, Enum.Material.SmoothPlastic)
local ssGui = Instance.new("SurfaceGui")
ssGui.Face = Enum.NormalId.Back
ssGui.Parent = sSign
local ssTxt = Instance.new("TextLabel")
ssTxt.Size = UDim2.new(1, 0, 1, 0)
ssTxt.BackgroundTransparency = 1
ssTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
ssTxt.TextScaled = true
ssTxt.Font = Enum.Font.GothamBold
ssTxt.Text = "ศูนย์บริการนักศึกษาครบวงจร มจพ."
ssTxt.Parent = ssGui

-- โถงลิฟต์โดยสาร 4 ตัว (Elevator Bank)
local elevWall = createPart(floor1, "ElevatorLobbyWall", Vector3.new(46, fH, 3), CFrame.new(-15, f1BaseY + fH/2, -bL/2 + 20), colConcreteGrey, Enum.Material.Metal)
for el = 1, 4 do
    local elX = -32 + (el * 9)
    -- ประตูลิฟต์สแตนเลส
    local elDoor = createPart(floor1, "ElevatorDoor_F1_" .. el, Vector3.new(6.5, 10.5, 0.4), CFrame.new(elX, f1BaseY + 5.25, -bL/2 + 21.6), Color3.fromRGB(200, 205, 210), Enum.Material.Metal)
    -- ป้ายไฟบอกชั้นดิจิตอล (Floor Indicator)
    local ind = createPart(floor1, "Ind_F1_" .. el, Vector3.new(2.5, 1, 0.2), CFrame.new(elX, f1BaseY + 12, -bL/2 + 21.6), Color3.fromRGB(255, 140, 0), Enum.Material.Neon)
end

-- บันไดกว้างเชื่อมขึ้นชั้น 2 (Grand Staircase)
local stairW = 20
local stepsCount = 20
local stairStart = Vector3.new(40, f1BaseY, -10)
for s = 1, stepsCount do
    local sY = f1BaseY + (s * (fH / stepsCount))
    local sZ = stairStart.Z - (s * 2.2)
    createPart(floor1, "GrandStair_" .. s, Vector3.new(stairW, 0.85, 2.3), CFrame.new(stairStart.X, sY, sZ), Color3.fromRGB(160, 165, 170), Enum.Material.Concrete)
end

----------------------------------------------------------------------
-- 6. ชั้น 2: โรงอาหาร มจพ. (CANTEEN & BARRICADE ZONE)
----------------------------------------------------------------------
local floor2 = Instance.new("Model")
floor2.Name = "Floor_2_Canteen"
floor2.Parent = building

local f2BaseY = f1BaseY + fH

-- พื้นชั้น 2
createPart(floor2, "Floor2_DeckL", Vector3.new(bW/2 + 25, 1.5, bL), CFrame.new(-bW/4 - 12.5, f2BaseY, 0), colGraniteFloor, Enum.Material.SmoothPlastic)
createPart(floor2, "Floor2_DeckR", Vector3.new(bW/2 - 35, 1.5, bL), CFrame.new(bW/4 + 22.5, f2BaseY, 0), colGraniteFloor, Enum.Material.SmoothPlastic)
createPart(floor2, "Floor2_Walkway", Vector3.new(20, 1.5, bL - 50), CFrame.new(30, f2BaseY, 20), colGraniteFloor, Enum.Material.SmoothPlastic)

-- ซุ้มร้านอาหาร มจพ. (Food Stalls พร้อมกันสาด)
local function createDetailedStall(stallName, position, awningColor)
    local stall = Instance.new("Model")
    stall.Name = stallName
    stall.Parent = floor2

    -- เคาน์เตอร์กระเบื้องขาว
    createPart(stall, "Counter", Vector3.new(18, 3.8, 5), CFrame.new(position), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic)
    -- ตู้กระจกใส่วัตถุดิบ
    createPart(stall, "GlassDisplay", Vector3.new(12, 2.5, 3), CFrame.new(position + Vector3.new(0, 3.1, -0.5)), colGlassTint, Enum.Material.Glass).Transparency = 0.6
    -- กันสาดผ้าใบหน้าร้าน
    createPart(stall, "Awning", Vector3.new(18, 0.8, 4), CFrame.new(position + Vector3.new(0, 6.5, 1)) * CFrame.Angles(math.rad(15), 0, 0), awningColor, Enum.Material.Fabric)
    -- ป้ายชื่อร้าน
    local sign = createPart(stall, "StallSign", Vector3.new(18, 2.2, 0.4), CFrame.new(position + Vector3.new(0, 8, -0.5)), awningColor, Enum.Material.SmoothPlastic)
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Back
    sg.Parent = sign
    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(1, 0, 1, 0)
    st.BackgroundTransparency = 1
    st.TextColor3 = Color3.fromRGB(255, 255, 255)
    st.TextScaled = true
    st.Font = Enum.Font.GothamBold
    st.Text = stallName
    st.Parent = sg
end

createDetailedStall("ร้านข้าวนัมเบอร์ 1 มจพ.", Vector3.new(-bW/2 + 22, f2BaseY + 1.9, -40), colMaroonKMUTNB)
createDetailedStall("ก๋วยเตี๋ยวเรือตึก 40 ปี", Vector3.new(-bW/2 + 46, f2BaseY + 1.9, -40), Color3.fromRGB(30, 90, 160))
createDetailedStall("ร้านน้ำปั่น & ชานม มจพ.", Vector3.new(-bW/2 + 70, f2BaseY + 1.9, -40), Color3.fromRGB(40, 140, 70))

-- แถวโต๊ะ-ม้านั่งยาวโรงอาหาร มจพ. (สแตนเลสเงางาม)
for row = 1, 3 do
    for col = 1, 4 do
        local tx = -bW/2 + 22 + (col * 15)
        local tz = -10 + (row * 13)
        createPart(floor2, "Table_" .. row .. "_" .. col, Vector3.new(10, 3.2, 4.5), CFrame.new(tx, f2BaseY + 2.1, tz), Color3.fromRGB(215, 220, 225), Enum.Material.Metal)
        createPart(floor2, "BenchA_" .. row .. "_" .. col, Vector3.new(10, 1.8, 1.4), CFrame.new(tx, f2BaseY + 1.4, tz - 3.2), Color3.fromRGB(180, 185, 190), Enum.Material.Metal)
        createPart(floor2, "BenchB_" .. row .. "_" .. col, Vector3.new(10, 1.8, 1.4), CFrame.new(tx, f2BaseY + 1.4, tz + 3.2), Color3.fromRGB(180, 185, 190), Enum.Material.Metal)
    end
end

-- โถงลิฟต์ชั้น 2 (ZOMBIE ELEVATOR)
local elevF2 = createPart(floor2, "ElevatorLobbyF2", Vector3.new(46, fH, 3), CFrame.new(-15, f2BaseY + fH/2, -bL/2 + 20), colConcreteGrey, Enum.Material.Metal)
for el = 1, 4 do
    local elX = -32 + (el * 9)
    local elDoor = createPart(floor2, "ElevatorDoor_F2_" .. el, Vector3.new(6.5, 10.5, 0.4), CFrame.new(elX, f2BaseY + 5.25, -bL/2 + 21.6), Color3.fromRGB(200, 205, 210), Enum.Material.Metal)
    elDoor.Name = "ZombieElevatorDoor_" .. el
end

-- ประตูชัตเตอร์เหล็กกั้นทางขึ้นชั้น 3 (Security Shutter)
local shutter = createPart(floor2, "SteelShutter_Floor3", Vector3.new(20, 12, 1.2), CFrame.new(40, f2BaseY + 6.5, -45), Color3.fromRGB(90, 95, 100), Enum.Material.Metal)
shutter.Name = "SteelShutter_Floor3"

local sConsole = createPart(floor2, "ShutterConsole", Vector3.new(2.5, 4.5, 1.5), CFrame.new(53, f2BaseY + 2.25, -43), Color3.fromRGB(45, 50, 55), Enum.Material.Metal)
local sPrompt = Instance.new("ProximityPrompt")
sPrompt.ActionText = "เปิดชัตเตอร์ขึ้นชั้น 3"
sPrompt.ObjectText = "Security Shutter [2,000 Pts / Keycard]"
sPrompt.HoldDuration = 1.5
sPrompt.MaxActivationDistance = 9
sPrompt.Parent = sConsole

----------------------------------------------------------------------
-- 7. ชั้น 3: ลานกิจกรรมกีฬาในร่ม (INDOOR SPORTS ARENA & PING-PONG)
----------------------------------------------------------------------
local floor3 = Instance.new("Model")
floor3.Name = "Floor_3_SportsArena"
floor3.Parent = building

local f3BaseY = f2BaseY + fH

-- พื้นไม้ปาร์เกต์สนามกีฬาในร่ม (Parquet Floor)
createPart(floor3, "ArenaFloor", Vector3.new(bW, 1.5, bL), CFrame.new(0, f3BaseY, 0), Color3.fromRGB(195, 145, 90), Enum.Material.WoodPlanks)

-- โต๊ะปิงปอง มจพ. (โซน "เล้าไก่")
local function createPingPongTable(pos)
    local tableTop = createPart(floor3, "PingPongTable", Vector3.new(9, 2.8, 15), CFrame.new(pos), Color3.fromRGB(30, 80, 140), Enum.Material.SmoothPlastic)
    -- ตาข่ายเน็ตสีขาว
    createPart(floor3, "Net", Vector3.new(9.4, 0.8, 0.3), CFrame.new(pos + Vector3.new(0, 1.8, 0)), Color3.fromRGB(240, 240, 240), Enum.Material.Fabric)
end

createPingPongTable(Vector3.new(-30, f3BaseY + 1.8, 10))
createPingPongTable(Vector3.new(-30, f3BaseY + 1.8, -15))
createPingPongTable(Vector3.new(10, f3BaseY + 1.8, 10))
createPingPongTable(Vector3.new(10, f3BaseY + 1.8, -15))

-- แป้นบาสเกตบอล (Basketball Hoop)
local hoopPost = createCylinder(floor3, "HoopPost", Vector3.new(12, 0.8, 0.8), CFrame.new(50, f3BaseY + 6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
local backboard = createPart(floor3, "Backboard", Vector3.new(1, 4.5, 6), CFrame.new(48, f3BaseY + 11, 0), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic)
local rim = createPart(floor3, "Rim", Vector3.new(2.5, 0.3, 2.5), CFrame.new(46, f3BaseY + 10, 0), Color3.fromRGB(255, 80, 20), Enum.Material.Neon)

----------------------------------------------------------------------
-- 8. เปลือกอาคารตึกสูง 11 ชั้น (TOWERING HIGH-RISE FACADE)
----------------------------------------------------------------------
-- สร้าง Facade ชั้น 4 ถึง 11 เพื่อให้ตึก 40 ปี สูงตระหง่านสมจริงตามภาพจริง มจพ.!
local upperTower = Instance.new("Model")
upperTower.Name = "UpperTower_Floors_4_to_11"
upperTower.Parent = building

local towerStartY = f3BaseY + fH
local remainingFloors = 8
local towerTotalH = remainingFloors * fH

-- กรอบตึกสูงด้านบน
createPart(upperTower, "TowerCore", Vector3.new(bW, towerTotalH, bL), CFrame.new(0, towerStartY + towerTotalH/2, 0), colConcreteLight, Enum.Material.Concrete)

-- แถวหน้าต่างกระจกระบายอากาศและระแนง Facade แต่ละชั้น
for fl = 1, remainingFloors do
    local winY = towerStartY + (fl - 1) * fH + fH/2
    -- แถบหน้าต่างกระจกด้านหน้า
    createPart(upperTower, "TowerWindows_F" .. (fl + 3), Vector3.new(bW - 20, 6, 1.5), CFrame.new(0, winY, bL/2 + 0.5), colGlassTint, Enum.Material.Glass).Transparency = 0.5
    -- เส้นคาดสถาปัตยกรรมสีแดงเลือดหมู มจพ.
    createPart(upperTower, "MaroonStripe_F" .. (fl + 3), Vector3.new(bW - 10, 1.5, 2), CFrame.new(0, winY + 4, bL/2 + 0.6), colMaroonKMUTNB, Enum.Material.SmoothPlastic)
end

-- ดาดฟ้าตึก (Rooftop & KMUTNB Residence Crest)
local roofY = towerStartY + towerTotalH
createPart(upperTower, "RooftopSlab", Vector3.new(bW + 6, 3, bL + 6), CFrame.new(0, roofY + 1.5, 0), colConcreteGrey, Enum.Material.Concrete)
createPart(upperTower, "HelipadMark", Vector3.new(30, 0.4, 30), CFrame.new(0, roofY + 3.2, 0), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic)

----------------------------------------------------------------------
-- 9. จุดซื้อปืนตามผนัง (WALL-BUYS)
----------------------------------------------------------------------
local wallBuys = Instance.new("Model")
wallBuys.Name = "WallBuys"
wallBuys.Parent = building

local function createWallBuy(name, weaponName, cost, position, normalAngle)
    local plate = createPart(wallBuys, name, Vector3.new(6, 4, 0.4), CFrame.new(position) * CFrame.Angles(0, normalAngle, 0), Color3.fromRGB(25, 25, 30), Enum.Material.Metal)
    plate.Name = weaponName
    plate:SetAttribute("Cost", cost)
    plate:SetAttribute("WeaponType", weaponName)

    local outline = Instance.new("SelectionBox")
    outline.Color3 = Color3.fromRGB(255, 215, 0)
    outline.Adornee = plate
    outline.Parent = plate

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Back
    gui.Parent = plate
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.TextColor3 = Color3.fromRGB(255, 220, 80)
    txt.TextScaled = true
    txt.Font = Enum.Font.SpecialElite
    txt.Text = "🔫 " .. weaponName .. "\n[" .. cost .. " POINTS]"
    txt.Parent = gui

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "ซื้อ " .. weaponName
    prompt.ObjectText = cost .. " Points"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 9
    prompt.Parent = plate

    return plate
end

createWallBuy("Buy_Shotgun", "Shotgun Remington", 800, Vector3.new(-bW/2 + 2, f2BaseY + 5, 10), math.rad(90))
createWallBuy("Buy_SMG", "SMG MP5", 1000, Vector3.new(-bW/2 + 2, f2BaseY + 5, -10), math.rad(90))
createWallBuy("Buy_Rifle", "M4A1 Carbine", 1500, Vector3.new(bW/2 - 2, f2BaseY + 5, 0), math.rad(-90))
createWallBuy("Buy_Ammo", "Ammo Refill", 300, Vector3.new(25, f2BaseY + 5, bL/2 - 2), math.rad(180))
createWallBuy("Buy_Turret", "Sentry Turret", 1200, Vector3.new(50, f2BaseY + 5, 10), math.rad(-90))

print("=========================================================")
print("🏛️ อาคาร 40 ปี มจพ. (ของจริง 11 ชั้น + กลางวัน) สร้างเสร็จสมบูรณ์!")
print("=========================================================")
