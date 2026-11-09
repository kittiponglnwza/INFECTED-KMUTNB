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
if Workspace:FindFirstChild("Floor_3_SportsArena") then
    Workspace.Floor_3_SportsArena:Destroy()
end
for f = 4, 6 do
    local fn = string.format("Floor_%d_Building40", f)
    if Workspace:FindFirstChild(fn) then
        Workspace[fn]:Destroy()
    end
end
if Workspace:FindFirstChild("Floor_7_VolleyballBadminton") then
    Workspace.Floor_7_VolleyballBadminton:Destroy()
end
for f = 8, 11 do
    local fn = string.format("Floor_%d_Building40", f)
    if Workspace:FindFirstChild(fn) then
        Workspace[fn]:Destroy()
    end
end

-- 2. ตั้งค่าแสงสว่างสบายตา ไม่จ้าสะท้อนพื้นขาวเกินไป
Lighting.ClockTime = 14
Lighting.Brightness = 1.5
Lighting.OutdoorAmbient = Color3.fromRGB(125, 125, 130)
Lighting.Ambient = Color3.fromRGB(115, 115, 120)
Lighting.FogEnd = 100000

-- 3. โหลดและสร้างชั้น 1 (Floor 1 Lobby & Parking)
local Floor1_Lobby = require(script.Parent.modules.Floor1_Lobby)
Floor1_Lobby.build(Workspace)

-- 4. โหลดและสร้างชั้น 2 (Floor 2 Canteen & Grand Stairs)
local Floor2_Canteen = require(script.Parent.modules.Floor2_Canteen)
Floor2_Canteen.build(Workspace)

-- 5. โหลดและสร้างชั้น 3 (Floor 3 Indoor Sports Arena: Futsal, Basketball, Bleachers, Restrooms, Storage)
local Floor3_SportsArena = require(script.Parent.modules.Floor3_SportsArena)
Floor3_SportsArena.build(Workspace)

-- 6. โหลดและสร้างชั้น 4, 5, 6 (Upper Atrium Floors: รูเห็นสนามฟุตซอล & สนามบาส, ห้องน้ำ 4 มุม, ห้องปิด)
local Floors4To6_UpperAtrium = require(script.Parent.modules.Floors4To6_UpperAtrium)
Floors4To6_UpperAtrium.build(Workspace)

-- 7. โหลดและสร้างชั้น 7 (Floor 7 Volleyball Court & 4 Badminton Courts)
local Floor7_VolleyballBadminton = require(script.Parent.modules.Floor7_VolleyballBadminton)
Floor7_VolleyballBadminton.build(Workspace)

-- 8. โหลดและสร้างชั้น 8, 9, 10, 11 (Upper Atrium Floors: รูเห็นสนามวอลเลย์บอล & สนามแบดมินตัน, ห้องน้ำ 4 มุม, ห้องปิดประตูหลากหลายดีไซน์)
local Floors8To11_UpperAtrium = require(script.Parent.modules.Floors8To11_UpperAtrium)
Floors8To11_UpperAtrium.build(Workspace)

print("=========================================================")
print("🏛️ [Building 40 Map Built] สร้างชั้น 1 ถึง ชั้น 11 อาคาร 40 ปี มจพ. สำเร็จสมบูรณ์!")
print("=========================================================")
