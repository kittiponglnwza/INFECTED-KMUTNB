--[[
    Building40Master.server.lua
    ใส่ใน: ServerScriptService -> Map
    หน้าที่: จัดการแมพในเกม
    
    มีสวิตช์ TEST_MODE:
      - true:  ลานซ้อมยิงปืน (KMUTNB Firing Range) สำหรับเทสปืน AK-47 และเป้าซอมบี้
      - false: แมพอาคาร 40 ปี มจพ. เต็มรูปแบบ (Plaza, Canteen, Sports Arena, Wall Buys)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local TEST_MODE = true -- เปลี่ยนเป็น false เมื่อต้องการเปิดแมพตึก 40 เต็มระบบ

if TEST_MODE then
    print("=========================================================")
    print("🎯 [Firing Range Mode] กำลังสร้างลานทดสอบยิงปืน AK-47...")
    print("=========================================================")

    -- 1. แสงสว่างสดใส ชัดเจน
    Lighting.ClockTime = 14
    Lighting.Brightness = 2.5
    Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
    Lighting.Ambient = Color3.fromRGB(170, 170, 170)
    Lighting.FogEnd = 100000

    -- ลบแมพเดิมออก
    if Workspace:FindFirstChild("KMUTNB_Building40") then
        Workspace.KMUTNB_Building40:Destroy()
    end
    if Workspace:FindFirstChild("TestArena") then
        Workspace.TestArena:Destroy()
    end

    local arena = Instance.new("Model")
    arena.Name = "TestArena"
    arena.Parent = Workspace

    -- พื้นลานยิงปืน 350x350 studs
    local floor = Instance.new("Part")
    floor.Name = "TestFloor"
    floor.Size = Vector3.new(350, 2, 350)
    floor.CFrame = CFrame.new(0, 0, 0)
    floor.Color = Color3.fromRGB(48, 50, 56)
    floor.Material = Enum.Material.Concrete
    floor.Anchored = true
    floor.CastShadow = false
    floor.Parent = arena

    -- แท่นยิงของผู้เล่น (Shooting Booth Platform)
    local spawnPlatform = Instance.new("Part")
    spawnPlatform.Name = "SpawnPlatform"
    spawnPlatform.Size = Vector3.new(28, 1.2, 18)
    spawnPlatform.CFrame = CFrame.new(0, 0.6, 5)
    spawnPlatform.Color = Color3.fromRGB(32, 35, 40)
    spawnPlatform.Material = Enum.Material.DiamondPlate
    spawnPlatform.Anchored = true
    spawnPlatform.Parent = arena

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "TestSpawn"
    spawn.Size = Vector3.new(10, 0.4, 10)
    spawn.CFrame = CFrame.new(0, 1.4, 5)
    spawn.Color = Color3.fromRGB(80, 200, 255)
    spawn.Material = Enum.Material.Neon
    spawn.Anchored = true
    spawn.Parent = arena

    -- แผงกั้นยิงปืนซ้าย-ขวา
    for _, x in ipairs({ -12, 12 }) do
        local barrier = Instance.new("Part")
        barrier.Size = Vector3.new(0.8, 5, 14)
        barrier.CFrame = CFrame.new(x, 3.2, 5)
        barrier.Color = Color3.fromRGB(70, 75, 85)
        barrier.Material = Enum.Material.Metal
        barrier.Anchored = true
        barrier.Parent = arena
    end

    -- ป้ายใหญ่ต้อนรับด้านหน้าจุดเกิด
    local billboardPart = Instance.new("Part")
    billboardPart.Size = Vector3.new(22, 4.5, 0.8)
    billboardPart.CFrame = CFrame.new(0, 7.5, 13)
    billboardPart.Color = Color3.fromRGB(20, 22, 26)
    billboardPart.Anchored = true
    billboardPart.Parent = arena

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.Parent = billboardPart
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.55, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 200, 60)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 28
    title.Text = "🎯 KMUTNB FIRING RANGE [AK-47 TEST]"
    title.Parent = gui
    
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0.45, 0)
    sub.Position = UDim2.new(0, 0, 0.55, 0)
    sub.BackgroundTransparency = 1
    sub.TextColor3 = Color3.fromRGB(200, 225, 255)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 17
    sub.Text = "ซอมบี้เป้าซ้อมยืนนิ่ง | [คลิกซ้ายค้าง] รัว Auto | [คลิกขวาค้าง] เล็งศูนย์ปืน (ADS) | [R] รีโหลด"
    sub.Parent = gui

    -- เส้นและป้ายบอกระยะยิง (Distance Target Lines)
    local distances = { 20, 35, 50, 70, 90 }
    for _, dist in ipairs(distances) do
        -- แถบสีบนพื้น
        local line = Instance.new("Part")
        line.Name = "Line_" .. dist
        line.Size = Vector3.new(60, 0.2, 1.5)
        line.CFrame = CFrame.new(0, 1.05, -dist)
        line.Color = (dist == 50) and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 220, 80)
        line.Material = Enum.Material.Neon
        line.Anchored = true
        line.CanCollide = false
        line.Parent = arena

        -- เสาและป้ายบอกระยะทางซ้าย-ขวา
        for _, side in ipairs({ -32, 32 }) do
            local post = Instance.new("Part")
            post.Size = Vector3.new(1.2, 6, 1.2)
            post.CFrame = CFrame.new(side, 4, -dist)
            post.Color = Color3.fromRGB(40, 42, 48)
            post.Anchored = true
            post.Parent = arena

            local sign = Instance.new("Part")
            sign.Size = Vector3.new(5, 2.2, 0.4)
            sign.CFrame = CFrame.new(side, 7.5, -dist)
            sign.Color = Color3.fromRGB(25, 25, 30)
            sign.Anchored = true
            sign.Parent = arena

            local sg = Instance.new("SurfaceGui")
            sg.Face = Enum.NormalId.Back
            sg.Parent = sign
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.TextColor3 = (dist == 50) and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 220, 80)
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = 22
            txt.Text = (dist == 50) and (dist .. " STUDS (TANK)") or (dist .. " STUDS")
            txt.Parent = sg
        end
    end

    print("✅ [Firing Range] ลานซ้อมยิงปืนพร้อมทดสอบเรียบร้อยแล้ว!")
else
    -- โหมดแมพเต็ม อาคาร 40 ปี มจพ.
    local LightingSetup = require(script.Parent.LightingSetup)
    local ExteriorPlaza = require(script.Parent.modules.ExteriorPlaza)
    local Floor1_Lobby = require(script.Parent.modules.Floor1_Lobby)
    local Floor2_Canteen = require(script.Parent.modules.Floor2_Canteen)
    local Floor3_SportsArena = require(script.Parent.modules.Floor3_SportsArena)
    local UpperTowerFacade = require(script.Parent.modules.UpperTowerFacade)
    local WallBuysSetup = require(script.Parent.modules.WallBuysSetup)

    LightingSetup.init()

    if Workspace:FindFirstChild("KMUTNB_Building40") then
        Workspace.KMUTNB_Building40:Destroy()
    end
    if Workspace:FindFirstChild("TestArena") then
        Workspace.TestArena:Destroy()
    end

    local building = Instance.new("Model")
    building.Name = "KMUTNB_Building40"
    building.Parent = Workspace

    ExteriorPlaza.build(building)
    Floor1_Lobby.build(building)
    Floor2_Canteen.build(building)
    Floor3_SportsArena.build(building)
    UpperTowerFacade.build(building)
    WallBuysSetup.build(building)

    print("🏛️ แมพอาคาร 40 ปี มจพ. สร้างเสร็จสมบูรณ์!")
end
