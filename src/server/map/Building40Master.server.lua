--[[
    Building40Master.server.lua
    ใส่ใน: ServerScriptService -> map
    หน้าที่: Script หลักควบคุมการสร้างสถาปัตยกรรม "อาคาร 40 ปี มจพ. (KMUTNB Building 40)"
            ทำงานร่วมกับโมดูลย่อยใน modules/ และ utils/
]]

local Workspace = game:GetService("Workspace")

-- โหลดโมดูลย่อย
local PartBuilder = require(script.Parent.utils.PartBuilder)
local LightingSetup = require(script.Parent.LightingSetup)
local ExteriorPlaza = require(script.Parent.modules.ExteriorPlaza)
local Floor1_Lobby = require(script.Parent.modules.Floor1_Lobby)
local Floor2_Canteen = require(script.Parent.modules.Floor2_Canteen)
local Floor3_SportsArena = require(script.Parent.modules.Floor3_SportsArena)
local UpperTowerFacade = require(script.Parent.modules.UpperTowerFacade)
local WallBuysSetup = require(script.Parent.modules.WallBuysSetup)

print("=========================================================")
print("🏛️ [Map Manager] กำลังสร้างอาคาร 40 ปี มจพ. แบบแยกโมดูลาร์...")
print("=========================================================")

-- 1. ตั้งค่าบรรยากาศและแสงตอนกลางวัน
LightingSetup.init()

-- 2. ลบโมเดลเดิมถ้าเคยสร้างไว้
if Workspace:FindFirstChild("KMUTNB_Building40") then
    Workspace.KMUTNB_Building40:Destroy()
end

local building = Instance.new("Model")
building.Name = "KMUTNB_Building40"
building.Parent = Workspace

-- 3. สั่งให้แต่ละโมดูลประกอบตึกตามลำดับ
ExteriorPlaza.build(building)        -- ลานหน้าตึก, สวนปาล์ม, ถนน, เสากลางแจ้ง 6 ต้น, ป้ายชื่อทางการ
Floor1_Lobby.build(building)         -- ชั้น 1: โถงใหญ่, ธนาคารกรุงเทพ & ตู้ ATM, ศูนย์บริการนักศึกษา, ลิฟต์, บันได
Floor2_Canteen.build(building)       -- ชั้น 2: โรงอาหาร มจพ., ซุ้มร้านค้า, โต๊ะสแตนเลส, ลิฟต์ซอมบี้, ประตูชัตเตอร์
Floor3_SportsArena.build(building)   -- ชั้น 3: ลานกีฬาในร่ม, โต๊ะปิงปอง ("เล้าไก่"), แป้นบาส
UpperTowerFacade.build(building)     -- ชั้น 4-11: เปลือกตึกสูง 11 ชั้น, Facade ระบายอากาศ, ดาดฟ้าลานจอด ฮ.
WallBuysSetup.build(building)        -- จุดซื้อปืนและกระสุนตามผนังโรงอาหาร

print("=========================================================")
print("✅ [Map Manager] อาคาร 40 ปี มจพ. ประกอบเสร็จสมบูรณ์ 100%!")
print("=========================================================")
