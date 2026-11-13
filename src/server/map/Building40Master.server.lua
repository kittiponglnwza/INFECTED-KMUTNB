--[[
    Building40Master.server.lua
    ใส่ใน: ServerScriptService -> Map
    หน้าที่: ตัวจัดการแมพอาคาร 40 ปี มจพ.
            - โหมด Static Map (AUTO_REBUILD_MAP = false): ใช้โมเดลตึกถาวรใน Workspace เพื่อให้ตกแต่งใน Studio ได้อิสระ
            - โหมด Procedural (AUTO_REBUILD_MAP = true): เสกตึกใหม่ด้วยโค้ดทุกครั้งตอน Play
]]

local Workspace = game:GetService("Workspace")

-- ตั้งเป็น false เพื่อใช้ตึกถาวรใน Edit Mode (ไม่ลบของตกแต่งที่ผู้ใช้วางไว้ใน Studio)
local AUTO_REBUILD_MAP = false

-- Bright Day mode by default for clear map/weapon inspection; switch to "Night" when ready for horror mode.
local PLAY_LIGHTING_MODE = "Day"
local LightingSetup = require(script.Parent.LightingSetup)
LightingSetup.init(PLAY_LIGHTING_MODE)

local WallBuysSetup = require(script.Parent.modules.WallBuysSetup)

if not AUTO_REBUILD_MAP then
    print("=========================================================")
    print("🏛️ [Building 40 Map] โหมด Static Map: เปิดใช้งาน")
    print("   -> สคริปต์จะไม่ลบหรือเสกตึกทับ ตกแต่งใน Studio ได้อิสระ 100%")
    print("=========================================================")

    -- สร้างจุดซื้ออาวุธบนกำแพงเฉพาะเมื่อยังไม่มีใน Workspace
    if not Workspace:FindFirstChild("MapWeaponBuys") then
        local ok, err = pcall(WallBuysSetup.build, Workspace)
        if not ok then
            warn("❌ [Building40Master] Error setting up WallBuys:", tostring(err))
        end
    end

    -- ลบโมเดลผู้จัดการเดิมในธนาคารออกอัตโนมัติ (เพื่อให้วางศพ/ตกแต่งแทน)
    local f1 = Workspace:FindFirstChild("Floor_1_Building40")
    local bank = f1 and f1:FindFirstChild("Room_Bank_BottomRight")
    if bank then
        local oldMgr = bank:FindFirstChild("BankManager_LastStandNPC")
        if oldMgr then
            oldMgr:Destroy()
            print("🗑️ [Building40Master] ลบ BankManager_LastStandNPC ในธนาคารเรียบร้อย")
        end
    end

    -- เปิดการทำงานและผูกระบบกด [E] ให้กับประตูธนาคารและคาเฟ่ชั้น 1 ทุกบาน
    local Floor1_Lobby = require(script.Parent.modules.Floor1_Lobby)
    pcall(Floor1_Lobby.ensureInteractiveDoors, f1)
    print("🚪 [Building40Master] เปิดการทำงานประตูธนาคารและคาเฟ่ชั้น 1 ทุกบานเรียบร้อย")

    -- เปิดการทำงานและผูกระบบกด [E] ให้กับตู้เซฟและศพผู้จัดการชั้น 1 ทันที
    task.spawn(function()
        task.wait(0.2)
        local okMWI, MWI = pcall(function()
            return require(game.ServerScriptService.Campaign.MissionWorldInteractables)
        end)
        if okMWI and MWI and MWI.ensureSafeAndCorpse then
            pcall(MWI.ensureSafeAndCorpse)
            print("🔐 [Building40Master] เปิดการทำงานระบบตู้เซฟและศพผู้จัดการชั้น 1 เรียบร้อย")
        end
    end)
    return
end

-- =========================================================
-- ส่วนด้านล่างจะทำงานเฉพาะเมื่อ AUTO_REBUILD_MAP = true เท่านั้น
-- =========================================================

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
if Workspace:FindFirstChild("Floor_12_TopSportsArena") then
    Workspace.Floor_12_TopSportsArena:Destroy()
end
if Workspace:FindFirstChild("Building40_ExteriorFacade_12Floors") then
    Workspace.Building40_ExteriorFacade_12Floors:Destroy()
end
if Workspace:FindFirstChild("Building40_SiteGrounds") then
    Workspace.Building40_SiteGrounds:Destroy()
end

-- Bright Day mode by default for clear map/weapon inspection; switch to "Night" when ready for horror mode.
local PLAY_LIGHTING_MODE = "Day"
local LightingSetup = require(script.Parent.LightingSetup)
LightingSetup.init(PLAY_LIGHTING_MODE)

local function safeBuild(name, buildFn, ...)
    local ok, err = pcall(buildFn, ...)
    if not ok then
        warn(string.format("❌ [Building40Master] Error building %s: %s", name, tostring(err)))
    end
    return ok
end

-- 3. โหลดและสร้างชั้น 1 (Floor 1 Lobby & Parking)
local Floor1_Lobby = require(script.Parent.modules.Floor1_Lobby)
safeBuild("Floor 1 Lobby", Floor1_Lobby.build, Workspace)

-- 4. โหลดและสร้างชั้น 2 (Floor 2 Canteen & Grand Stairs)
local Floor2_Canteen = require(script.Parent.modules.Floor2_Canteen)
safeBuild("Floor 2 Canteen", Floor2_Canteen.build, Workspace)

-- 5. โหลดและสร้างชั้น 3 (Floor 3 Indoor Sports Arena: Futsal, Basketball, Bleachers, Restrooms, Storage)
local Floor3_SportsArena = require(script.Parent.modules.Floor3_SportsArena)
safeBuild("Floor 3 Sports Arena", Floor3_SportsArena.build, Workspace)

-- 6. โหลดและสร้างชั้น 4, 5, 6 (Upper Atrium Floors: รูเห็นสนามฟุตซอล & สนามบาส, ห้องน้ำ 4 มุม, ห้องปิด)
local Floors4To6_UpperAtrium = require(script.Parent.modules.Floors4To6_UpperAtrium)
safeBuild("Floors 4-6 Upper Atrium", Floors4To6_UpperAtrium.build, Workspace)

-- 7. โหลดและสร้างชั้น 7 (Floor 7 Volleyball Court & 4 Badminton Courts)
local Floor7_VolleyballBadminton = require(script.Parent.modules.Floor7_VolleyballBadminton)
safeBuild("Floor 7 Volleyball Badminton", Floor7_VolleyballBadminton.build, Workspace)

-- 8. โหลดและสร้างชั้น 8, 9, 10, 11 (Upper Atrium Floors: รูเห็นสนามวอลเลย์บอล & สนามแบดมินตัน, ห้องน้ำ 4 มุม, ห้องปิดประตูหลากหลายดีไซน์)
local Floors8To11_UpperAtrium = require(script.Parent.modules.Floors8To11_UpperAtrium)
safeBuild("Floors 8-11 Upper Atrium", Floors8To11_UpperAtrium.build, Workspace)

-- 9. โหลดและสร้างชั้น 12 (ชั้นบนสุด ขึ้นทางบันไดเท่านั้น: สนามเซปักตะกร้อ 2 สนาม, สนามเทนนิส, สนามฟุตซอล, WC.1 & WC.2)
local Floor12_TopSportsArena = require(script.Parent.modules.Floor12_TopSportsArena)
safeBuild("Floor 12 Top Sports Arena", Floor12_TopSportsArena.build, Workspace)

-- 10. โหลดและสร้างสถาปัตยกรรมภายนอก (12 ชั้น) + ป้ายอาคาร 77 (อิงภาพถ่ายภายนอก; รายละเอียดมิติยังไม่ยืนยัน)
local Building40_ExteriorFacade = require(script.Parent.modules.Building40_ExteriorFacade)
safeBuild("Building 40 Exterior Facade", Building40_ExteriorFacade.build, Workspace)

-- 11. โหลดและสร้างบริบทพื้นที่มหาวิทยาลัย (ทางเดินเข้าหลัก, คลอง/สะพานคนเดิน, สวนปาล์ม, มวลอาคารฝั่งคณะวิศวกรรมฯ แบบ low-detail)
local Building40_SiteGrounds = require(script.Parent.modules.Building40_SiteGrounds)
safeBuild("Building 40 Site Grounds", Building40_SiteGrounds.build, Workspace)

-- Survival weapon stations are rebuilt after the floor geometry so they are
-- available in the active map and can be registered by the server combat system.
local WallBuysSetup = require(script.Parent.modules.WallBuysSetup)
safeBuild("Wall Buys Setup", WallBuysSetup.build, Workspace)

print("=========================================================")
print("🏛️ [Building 40 Map Built] สร้างโครงอาคาร 12 ชั้น + บริบทพื้นที่มหาวิทยาลัย (gameplay scale) แล้ว; ต้องตรวจภาพใน Studio ต่อ")
print("=========================================================")
