--[[
    Building40Master.server.lua
    ใส่ใน: ServerScriptService -> Map
    หน้าที่: ตัวจัดการหลักในการสร้างแมพอาคาร 40 ปี มจพ. (อาคาร 77)
    
    โหมดการทำงาน:
      - TEST_MODE = false: แมพอาคาร 40 ปี มจพ. เต็มรูปแบบ [Phase 1: โครงสร้าง 12 ชั้น + ชั้น 1 ล็อบบี้ละเอียด]
      - TEST_MODE = true:  ลานยิงปืนทดสอบชั่วคราว (Firing Range)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local TEST_MODE = false -- 🚀 เปิดใช้งานแมพอาคาร 40 ปี มจพ. เต็มรูปแบบ (Phase 1)

if TEST_MODE then
    print("=========================================================")
    print("🎯 [Firing Range Mode] กำลังสร้างลานทดสอบยิงปืน...")
    print("=========================================================")

    Lighting.ClockTime = 14
    Lighting.Brightness = 2.5
    Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
    Lighting.Ambient = Color3.fromRGB(170, 170, 170)
    Lighting.FogEnd = 100000

    if Workspace:FindFirstChild("KMUTNB_Building40") then
        Workspace.KMUTNB_Building40:Destroy()
    end
    if Workspace:FindFirstChild("TestArena") then
        Workspace.TestArena:Destroy()
    end

    local arena = Instance.new("Model")
    arena.Name = "TestArena"
    arena.Parent = Workspace

    local floor = Instance.new("Part")
    floor.Name = "TestFloor"
    floor.Size = Vector3.new(350, 2, 350)
    floor.CFrame = CFrame.new(0, 0, 0)
    floor.Color = Color3.fromRGB(48, 50, 56)
    floor.Material = Enum.Material.Concrete
    floor.Anchored = true
    floor.Parent = arena

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "TestSpawn"
    spawn.Size = Vector3.new(10, 0.4, 10)
    spawn.CFrame = CFrame.new(0, 1.4, 5)
    spawn.Color = Color3.fromRGB(80, 200, 255)
    spawn.Material = Enum.Material.Neon
    spawn.Anchored = true
    spawn.Parent = arena

    print("✅ [Firing Range] ลานซ้อมยิงปืนพร้อมทดสอบเรียบร้อยแล้ว!")
else
    print("=========================================================")
    print("🏛️ [KMUTNB Building 40 - Phase 1] กำลังเริ่มก่อสร้างอาคาร 40 ปี มจพ. ...")
    print("=========================================================")

    -- โหลดโมดูลแยกตามสถาปัตยกรรมที่ชัดเจน
    local LightingSetup = require(script.Parent.LightingSetup)
    local ExteriorPlaza = require(script.Parent.modules.ExteriorPlaza)
    local Floor1_Lobby = require(script.Parent.modules.Floor1_Lobby)
    local Floor2_Canteen = require(script.Parent.modules.Floor2_Canteen)
    local BuildingCoreStructure = require(script.Parent.modules.BuildingCoreStructure)

    -- 1. ตั้งค่าแสงสว่างสดใส สบายตา สมจริง
    LightingSetup.init()

    -- 2. เคลียร์พื้นที่เดิม
    if Workspace:FindFirstChild("KMUTNB_Building40") then
        Workspace.KMUTNB_Building40:Destroy()
    end
    if Workspace:FindFirstChild("TestArena") then
        Workspace.TestArena:Destroy()
    end

    -- 3. สร้าง Model หลักของอาคาร
    local building = Instance.new("Model")
    building.Name = "KMUTNB_Building40"
    building.Parent = Workspace

    -- 4. ก่อสร้างตามลำดับ:
    --    ก. ลานภายนอก Plaza, เสาธงชาติ, ถนน มจพ., ป้ายชื่ออาคาร 40 ปี
    ExteriorPlaza.build(building)

    --    ข. ชั้น 1 ล็อบบี้หลักแบบละเอียด (ธนาคารกรุงเทพ, ศูนย์บริการนักศึกษา, ลิฟต์ 4 ตัว, บันไดคู่, Wall Buys, Barricades)
    Floor1_Lobby.build(building)

    --    ค. ชั้น 2 โรงอาหาร 40 ปี สจพ. (ตรงตามแปลนจริง 100% พร้อมบันไดใหญ่หน้าตึก, ร้านข้าว 8 ร้าน, โต๊ะสแตนเลส, 4 ห้องน้ำ, ที่เก็บจาน, Wall Buys)
    Floor2_Canteen.build(building)

    --    ง. โครงสร้างสถาปัตยกรรมหลักชั้น 3 ถึง 12 (เสา 16 ต้น, พื้นทุกชั้นโปร่ง, ปล่องลิฟต์, บันไดหนีไฟ, Facade, ดาดฟ้า Helipad)
    BuildingCoreStructure.build(building)

    print("=========================================================")
    print("🏆 [Building 40 - Floor 1 & 2 Completed] อาคาร 40 ปี มจพ. (ชั้น 1 ล็อบบี้ + ชั้น 2 โรงอาหารสมบูรณ์แบบ) พร้อมเข้าเล่นแล้ว!")
    print("=========================================================")
end
