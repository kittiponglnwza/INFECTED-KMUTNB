--[[
    Building40Master.server.lua
    ใส่ใน: ServerScriptService -> Map
    หน้าที่: ตัวจัดการสร้างแมพอาคาร 40 ปี มจพ. (แบบทีละชั้นตามแปลนจริง)
            - ชั้น 1 (Floor G): ลานจอดรถ, ธนาคาร, คาเฟ่, บันไดวนซ้าย, ลิฟต์, ปิดตายทุกห้อง
            - ชั้น 2 (Floor 2): โรงอาหาร 40 ปี สจพ. พร้อมบันไดใหญ่หน้าตึก ป้าย Coke ร้านข้าว 8 ร้าน ห้องน้ำ 4 มุม
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
if Workspace:FindFirstChild("Floor_2_Canteen") then
    Workspace.Floor_2_Canteen:Destroy()
end

-- 2. ตั้งค่าแสงสว่างสดใส สบายตา สมจริง
Lighting.ClockTime = 14
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
Lighting.Ambient = Color3.fromRGB(160, 160, 160)
Lighting.FogEnd = 100000

-- 3. โหลดและสร้างชั้น 1 (Floor 1 Lobby & Parking)
local Floor1_Lobby = require(script.Parent.modules.Floor1_Lobby)
Floor1_Lobby.build(Workspace)

-- 4. โหลดและสร้างชั้น 2 (Floor 2 Canteen & Grand Stairs)
local Floor2_Canteen = require(script.Parent.modules.Floor2_Canteen)
Floor2_Canteen.build(Workspace)

print("=========================================================")
print("🏛️ [Building 40 Map Built] สร้างชั้น 1 และ ชั้น 2 (โรงอาหาร 40 ปี สจพ. + บันไดหน้าตึก) สเกล 2 เท่า สำเร็จสมบูรณ์!")
print("=========================================================")
