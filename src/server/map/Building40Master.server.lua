--[[
    Building40Master.server.lua
    ใส่ใน: ServerScriptService -> Map
    หน้าที่: ตัวจัดการสร้างแมพอาคาร 40 ปี มจพ. (แบบทีละชั้นตามแปลนจริง)
            - โฟกัสเฉพาะ "ชั้น 1 (Floor G)" ตามภาพแปลนลายเส้น
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
if Workspace:FindFirstChild("Floor_1_Building40") then
    Workspace.Floor_1_Building40:Destroy()
end

-- 2. ตั้งค่าแสงสว่างสดใส สบายตา สมจริง
Lighting.ClockTime = 14
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
Lighting.Ambient = Color3.fromRGB(160, 160, 160)
Lighting.FogEnd = 100000

-- 3. โหลดและสร้างเฉพาะ "ชั้น 1" ตามภาพแปลนลายเส้น
local Floor1_Lobby = require(script.Parent.modules.Floor1_Lobby)
Floor1_Lobby.build(Workspace)

print("=========================================================")
print("🏛️ [Floor 1 Built] สร้างโครงสร้างชั้น 1 ตามแปลนลายเส้นสำเร็จเรียบร้อย!")
print("=========================================================")
