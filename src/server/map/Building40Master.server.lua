--[[
    Building40Master.server.lua -> Test Arena Mode
    สร้างแมพเปล่า ลานกว้างโล่งๆ สำหรับทดสอบระบบ (Test Arena)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

print("=========================================================")
print("🧪 [Test Mode] กำลังสร้างแมพเปล่า ลานกว้างสำหรับทดสอบ...")
print("=========================================================")

-- 1. แสงสว่างตอนกลางวัน ชัดเจน
Lighting.ClockTime = 14
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
Lighting.Ambient = Color3.fromRGB(160, 160, 160)
Lighting.FogEnd = 100000

-- ลบแมพเก่าออกทั้งหมด
if Workspace:FindFirstChild("KMUTNB_Building40") then
    Workspace.KMUTNB_Building40:Destroy()
end
if Workspace:FindFirstChild("TestArena") then
    Workspace.TestArena:Destroy()
end

local arena = Instance.new("Model")
arena.Name = "TestArena"
arena.Parent = Workspace

-- ลานพื้นกว้าง 350x350 studs
local floor = Instance.new("Part")
floor.Name = "TestFloor"
floor.Size = Vector3.new(350, 2, 350)
floor.CFrame = CFrame.new(0, 0, 0)
floor.Color = Color3.fromRGB(220, 222, 225)
floor.Material = Enum.Material.SmoothPlastic
floor.Anchored = true
floor.CastShadow = false
floor.Parent = arena

-- จุดเกิดตรงกลางลาน
local spawn = Instance.new("SpawnLocation")
spawn.Name = "TestSpawn"
spawn.Size = Vector3.new(12, 1, 12)
spawn.CFrame = CFrame.new(0, 1.5, 0)
spawn.Color = Color3.fromRGB(100, 200, 100)
spawn.Material = Enum.Material.Neon
spawn.Anchored = true
spawn.Parent = arena

-- เสาอ้างอิงระยะห่าง (Marker Pillars)
for r = 20, 80, 20 do
    local marker = Instance.new("Part")
    marker.Name = "DistanceMarker_" .. r
    marker.Size = Vector3.new(2, 6, 2)
    marker.CFrame = CFrame.new(0, 4, -r)
    marker.Color = Color3.fromRGB(255, 100, 100)
    marker.Anchored = true
    marker.CanCollide = false
    marker.Parent = arena
end

print("✅ [Test Mode] แมพเปล่าโล่งๆ พร้อมทดสอบแล้ว!")
