--[[
    Building40Master.server.lua
    ใส่ใน: ServerScriptService -> Map
    หน้าที่: ตัวจัดการสร้างแมพอาคาร 40 ปี มจพ. (แบบทีละชั้นตามแปลนจริง)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- 1. เคลียร์แมพและตึกเดิมทิ้งทั้งหมด 100%
if Workspace:FindFirstChild("KMUTNB_Building40") then
    Workspace.KMUTNB_Building40:Destroy()
end
if Workspace:FindFirstChild("TestArena") then
    Workspace.TestArena:Destroy()
end
if Workspace:FindFirstChild("CleanCanvas") then
    Workspace.CleanCanvas:Destroy()
end

-- 2. ตั้งค่าแสงสว่างสดใส เคลียร์ท้องฟ้า สบายตา
Lighting.ClockTime = 14
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
Lighting.Ambient = Color3.fromRGB(160, 160, 160)
Lighting.FogEnd = 100000

-- 3. สร้างพื้นที่เปล่าสะอาด (Clean Canvas Platform) รอรับโครงสร้างชั้น 1
local canvas = Instance.new("Model")
canvas.Name = "CleanCanvas"
canvas.Parent = Workspace

local basePlate = Instance.new("Part")
basePlate.Name = "CleanBase"
basePlate.Size = Vector3.new(300, 2, 300)
basePlate.CFrame = CFrame.new(0, 0, 0)
basePlate.Color = Color3.fromRGB(215, 215, 215)
basePlate.Material = Enum.Material.SmoothPlastic
basePlate.Anchored = true
basePlate.Parent = canvas

local spawn = Instance.new("SpawnLocation")
spawn.Name = "SpawnLocation"
spawn.Size = Vector3.new(12, 0.5, 12)
spawn.CFrame = CFrame.new(0, 1.3, 0)
spawn.Color = Color3.fromRGB(0, 200, 255)
spawn.Material = Enum.Material.SmoothPlastic
spawn.Anchored = true
spawn.Parent = canvas

print("=========================================================")
print("🧹 เคลียร์ตึกและสิ่งกีดขวางทั้งหมดออกเรียบร้อยแล้ว!")
print("📍 พื้นที่พร้อม 100% สำหรับเริ่มสร้างโครงสร้าง 'ชั้น 1 (Floor G)' ตามแปลน")
print("=========================================================")
