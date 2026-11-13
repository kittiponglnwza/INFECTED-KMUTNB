# 🧟 INFECTED-KMUTNB — สรุปภาพรวมโปรเจค

> **โปรเจค:** `INFECTED-KMUTNB` (`KMUTNB_Building40_ZombieDefense`)  
> **แนวเกม:** Co-op FPS Zombie Survival & Barricade Defense (2–4 ผู้เล่น)  
> **สถานที่จำลอง:** อาคารเอนกประสงค์ 40 ปี มจพ. (อาคาร 77) มหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ  
> **เทคโนโลยี:** Roblox Studio (Luau), Rojo (`default.project.json`, `rojo.exe`), Procedural Map Builders, Server-Authoritative Architecture  
> **ไฟล์ Place หลัก:** `HorrorGame.rbxl`  
> **Repository:** `https://github.com/kittiponglnwza/INFECTED-KMUTNB.git` (`main`)

---

## 1. แนวคิดและจุดเด่นของเกม

เกมเอาชีวิตรอดมุมมองบุคคลที่หนึ่ง (LockFirstPerson FPS) ผสมผสานระหว่าง **การลุยฝ่าอาคาร 12 ชั้นสไตล์ Co-op L4D**, **บรรยากาศสยองขวัญไฟดับทั้งตึก**, **ระบบป้องกันห้องด้วย Barricade**, และ **การดำเนินภารกิจเชิงเนื้อเรื่อง (Campaign Missions)** ที่ฝั่ง Server เป็นผู้ตรวจและตัดสินสถานะทั้งหมดเพื่อกัน exploit

### จุดเด่นสำคัญ
- **ตึก 40 ปี มจพ. เต็มสเกล 12 ชั้น + พื้นที่รอบตึก:** ฐานอาคารขนาด `300 × 240` studs (`GROUND_Y = 1.0`, ความสูงชั้นละ `22.0` studs) พร้อมโถง Atrium กลาง ลิฟต์ บันไดหนีไฟ-บันไดลอย และภูมิทัศน์รอบอาคาร
- **เปิดเกมในความมืด (`Horror` Blackout) + ไฟฉุกเฉิน:** เมื่อเริ่ม Campaign ไฟฟ้าหลักอาคารจะดับ (`BuildingPowerOn = false`, `Lighting.ClockTime = 0.2`) เหลือเพียงไฟฉุกเฉิน (`HorrorEmergencyLight`), ไฟสำรอง UPS ในห้องควบคุม `102`, และไฟฉายประจำตัวผู้เล่น จนกว่าทีมจะทำภารกิจ M2 กู้คืนไฟฟ้าสำเร็จจึงจะสว่างกลับสู่โหมด `"Day"`
- **ซอมบี้ซุ่ม (`IsLurking`) + กับดักสัญญาณกันขโมยรถ (`CarAlarmHazard`):** ซอมบี้ตามจุดซุ่มจะยืนนิ่งเงียบในมุมมืด/ห้อง/เต็นท์ จนกว่าผู้เล่นเข้าใกล้, ส่องไฟฉาย, ยิงปืนเสียงดัง หรือพลาดไปโดนรถติดสัญญาณกันขโมยบนลานจอดชั้น 1 ที่จะเปิดไซเรนและดึงฝูงซอมบี้ (`Noise` horde) เข้ามา
- **ภารกิจ Co-op แบบ Server-Authoritative + ระบบมือถือเจ้าหน้าที่ (`StaffPhoneUI`):** ความคืบหน้าภารกิจ คีย์การ์ด รหัสเซฟ และปริศนา CCTV ถูกตรวจที่ Server ทั้งหมด แชร์ร่วมกันทั้งทีม และคืนคีย์ไอเทมให้อัตโนมัติหากผู้เล่นที่ถืออยู่ล้มตายหรือหลุดออกจากเกม
- **คลังปืน 18 กระบอก + ระบบเอาชีวิตรอดเต็มรูปแบบ:** มีทั้งอาวุธมุมมอง 1P (`KMUTNBArms`), ระบบแรงดีด, กล้องเล็ง (`OpticsManager`), จุดซื้อปืนตามผนัง/ลังเสบียง, ความหิว (`Hunger`), แบตเตอรี่ไฟฉาย (`Battery`), ระบบเพื่อนล้มคลานและช่วยชุบ (`30` วินาที) และ **THE RANGE** โซนทดสอบโมเดล 3D/แอนิเมชัน/อาวุธ

---

## 2. สถาปัตยกรรมโค้ดและโครงสร้าง Rojo (`default.project.json`)

```text
src/
├─ shared/
│  ├─ campaign/                 -> ReplicatedStorage.Shared (ห้ามเก็บเฉลยปริศนาไว้ฝั่ง Client)
│  │  ├─ NetProtocol.lua        # ชื่อ Remote/Signal, Attributes, Teleport Aliases, States
│  │  ├─ MissionConfig.lua      # โครงภารกิจ M1-M4, รายชื่อชั้น B40, ค่าปรับแต่งห้อง 102
│  │  ├─ ItemCatalog.lua        # คลัง Quest Items, เสบียง (Food/Medkit/Battery) & Cap
│  │  └─ MissionLogicTests.lua  # Automated Test Suite 11 ชุดทดสอบระบบ Campaign/Director/CCTV
│  └─ zombies/                  -> ReplicatedStorage.ZombieModules
│     ├─ ZombieCatalog.lua      # สเปกซอมบี้ 5 ประเภท + โปรไฟล์แอนิเมชัน/เสียง
│     ├─ ZombieModelFactory.lua # ตัวสร้าง Rig ซอมบี้สเกลตามประเภท
│     ├─ ZombieAnimationController.lua
│     └─ ZombieAudioController.lua # เสียง 3D สังเคราะห์จาก local engine assets
├─ server/
│  ├─ campaign/                 -> ServerScriptService.Campaign
│  │  ├─ CCTVPuzzleEngine.lua   # เฉลยลำดับ CCTV หลาย Variant & ตรวจคำตอบฝั่ง Server
│  │  ├─ ObjectiveTracker.lua   # State machine ภารกิจหลัก-ย่อย, Parallel M3/M4 graph
│  │  ├─ KeyItemService.lua     # จัดการถือ/ส่งต่อ/กู้คืนคีย์ไอเทมทั้งทีม
│  │  ├─ DoorAccessService.lua  # ตรวจสิทธิ์เปิดประตู/ลิฟต์ (Clearance Tier & Power)
│  │  ├─ FloorClearanceService.lua # สิทธิ์ชั้น Tier 0-4 & ปลดล็อกปืน Tier 1
│  │  ├─ ZombieDirector.lua     # Dual-Mode Director (Campaign vs Wave), ระยะ/LOS guard, Noise heat
│  │  ├─ MissionWorldInteractables.lua # จุดโต้ตอบ M1-M2: ศพ/เซฟ/โน้ต/Monitor Wall/Generator
│  │  ├─ DevAuthService.lua     # ตรวจสิทธิ์ Dev / เจ้าของแมพ (Studio / Owner / Allowlist)
│  │  └─ ServerEnvironmentConfig.lua
│  ├─ gameplay/                 -> ServerScriptService.*
│  │  ├─ zombies/ZombieAI.lua   # Pathfinding ขึ้นลงบันได, พังประตู/Barricade, สถานะซุ่ม IsLurking
│  │  ├─ WaveAndZombieManager.server.lua # Spawn/Ambush Pods, Server Raycast ปืน, CarAlarm, Wave/Campaign loop
│  │  ├─ MissionService.server.lua # ศูนย์กลางเชื่อม StateChanged, Puzzle, Hold-Out ห้อง 102, M2 Power
│  │  ├─ SurvivalAndHorrorSetup.server.lua # Hunger, แบตไฟฉาย, Loot F1-F11, ห้องแล็บลับชั้น 11
│  │  ├─ DownedAndReviveManager.server.lua # ล้มคลาน 30s, กดค้าง [E] 3s ชุบที่ 60 HP
│  │  ├─ BarricadeManager.server.lua # ซ่อมแผ่นไม้ [E] (+10 แต้ม) และระบบซอมบี้ทุบไม้
│  │  ├─ DevCommandService.server.lua # คำสั่งแชท !test, !mission, !tp, !wave ฯลฯ
│  │  ├─ TeleportService.server.lua # วาร์ป /range <-> /lobby และจุดต่าง ๆ ในตึก
│  │  ├─ TestRangeSetup.server.lua # สร้างโซน INFECTED_TestRange (THE RANGE)
│  │  └─ MissionWorldSetup.server.lua
│  └─ map/                      -> ServerScriptService.Map
│     ├─ Building40Master.server.lua # ตัวคุมสร้าง/โหลดแมพ (Static vs Procedural) & Horror Lighting
│     ├─ LightingSetup.lua      # พรีเซ็ตแสง Day / Horror
│     ├─ modules/               # Floor1_Lobby .. Floor12_TopSportsArena, Floors1To3OutbreakSetup, WallBuysSetup, Exterior
│     └─ utils/                 # Building40Layout, PartBuilder, StairBuilder, ElevatorBuilder, CarBuilder ฯลฯ
└─ client/
   ├─ controllers/              -> StarterPlayerScripts.*
   │  ├─ FPSController.client.lua # กล้อง FPS, ยิงปืน, ไฟฉาย, Slide, HUD เอาชีวิตรอด & Lighting Sync
   │  ├─ MissionController.client.lua # UI ภารกิจ, โน้ต, Keypad เซฟธนาคาร, Fallback CCTV Modal, Hold-Out HUD
   │  ├─ RangeShowcaseController.client.lua # ควบคุมหุ่นโชว์/เวทีแอนิเมชันใน THE RANGE
   │  ├─ MapSelectorController.client.lua
   │  └─ showcase/              # โมดูล Animation/Character/Weapon/Zombie/Camera Showcase
   ├─ modules/                  -> StarterPlayerScripts.ClientModules
   │  ├─ StaffPhoneUI.lua       # มือถือเจ้าหน้าที่ [P] (Notes / Messages / Inventory / Status / Map)
   │  ├─ Room102MonitorEffects.lua # เอฟเฟกต์ static/scanline/flicker บน Monitor Wall ห้อง 102
   │  ├─ CCTVPuzzleModal.lua, BankSafeKeypadModal.lua, EmergencyMemoModal.lua
   │  └─ UIStateManager.lua     # ประสานสถานะ Modal & ปลดล็อกเมาส์ให้ตรงกัน
   └─ weapons/                  -> ReplicatedStorage.Weapons
      ├─ WeaponRegistry.lua     # รวมคลังอาวุธ 18 กระบอก (configs/ + extraWeapons)
      ├─ configs/               # Classic, Sheriff, Spectre, Bucky, Judge, Vandal, Phantom, Operator
      ├─ models/                # WeaponModelBuilder, KMUTNBArms
      ├─ animations/, effects/, optics/, ui/ (ValorantBuyMenu)
```

---

## 3. โครงสร้างแผนที่อาคาร 40 ปี มจพ. และสิ่งกีดขวาง

| โซน / ชั้น | รายละเอียดพื้นที่หลัก | องค์ประกอบ Outbreak & เกมเพลย์ |
|---|---|---|
| **รอบอาคาร** | ถนนวงแหวน 2 เลน, ลานเสาธง มจพ., ลานจอดรถกลางแจ้ง, โรงจอดมอเตอร์ไซค์ | จุดเชื่อมต่อทางเข้า-ออกลานจอดชั้น 1 และภูมิทัศน์มหาวิทยาลัย |
| **ชั้น 1 (`Floor1_Lobby`)** | ลานจอดรถ Drive-Through, คาเฟ่เรือนกระจก, ธนาคารกรุงเทพ (ATM + ห้องผู้จัดการ + ตู้เซฟ `M1_BankVaultSafe`), **ห้องควบคุม 102** (`Room_BottomLeft`) | `F1_OutbreakWreckage`: ซากรถชน, รถพยาบาล, ด่านแบริเออร์/กระสอบทราย, โต๊ะคาเฟ่ล้ม, ไฟฉุกเฉิน, **รถติดสัญญาณกันขโมย (`CarAlarmHazard`) 3 คัน**, `Buy_Ghost_F1`, `Buy_Sheriff_F1`, `Buy_Spectre_F1Armory` |
| **ชั้น 2 (`Floor2_Canteen`)** | บันไดลอยหน้าตึก, โรงอาหารกลาง มจพ., 8 ร้านอาหาร, 4 ห้องปรับอากาศ, ห้องน้ำ | `F2_CanteenOutbreak`: โต๊ะโรงอาหารล้ม/เอียง (เว้น 12 โต๊ะที่มีไอเทม Loot), แนวแบริเออร์ซิกแซก, ชัตเตอร์ร้านค้าหล่นครึ่งบาน, **เครื่องกำเนิดไฟฟ้าหลัก (`M2_PowerRoomGenerator`)**, `Buy_Bucky_F2` |
| **ชั้น 3 (`Floor3_SportsArena`)** | สนามฟุตซอลในกรงตาข่าย, สนามบาสเกตบอล, สแตนเชียร์ 5 ชั้น, โต๊ะปิงปอง | `F3_QuarantineCamp`: เต็นท์คัดกรองแพทย์ 4 หลัง (`TriageTent_*`), รั้วกักกันตาข่าย, บังเกอร์กระสอบทราย, ถัง biohazard, สปอร์ตไลต์, `Buy_Spectre_F3` |
| **ชั้น 4–6 (`Floors4To6_UpperAtrium`)** | โถงสูงมองลงสนามชั้น 3, กองกิจการนักศึกษา, ทุนการศึกษา, ห้องกิจกรรม | `Buy_Judge_F4`, `Buy_Vandal_F6`, ต้องใช้ Tier 1 + ไฟฟ้าตึก (เมื่อใช้งานลิฟต์/การเข้าถึงตามระบบสิทธิ์) |
| **ชั้น 7 (`Floor7_VolleyballBadminton`)** | สนามวอลเลย์บอลพร้อมแท่นกรรมการ + สนามแบดมินตัน 4 คอร์ท | โซนกีฬาชั้นกลาง (Clearance Tier 2) |
| **ชั้น 8–10 (`Floors8To11_UpperAtrium`)** | โถงสูงชั้นบน, ห้องพัก KMUTNB Residence, ห้องชมรม | `Buy_Phantom_F8`, `Buy_Operator_F10` (Clearance Tier 2) |
| **ชั้น 11 (`SurvivalAndHorrorSetup`)** | เขตกักกันเชื้อชีวภาพชั้น 11, ห้องแล็บลับหลังกระจกดำ & ประตูนิรภัย | จุดเก็บอาวุธระดับสูง บันทึกการทดลอง และทางขึ้นสู่ชั้น 12 |
| **ชั้น 12 (`Floor12_TopSportsArena`)** | ขึ้นได้ทางบันไดเท่านั้น: เวทีมวย, เวทีเทควันโด, กระสอบทรายเตะแกว่งได้ 3 ลูก, สนามเทนนิส, ฟุตซอล | พื้นที่วางโครงสร้างเป้าหมายอพยพดาดฟ้า / Helipad สำหรับ M3–M4 |
| **THE RANGE (`INFECTED_TestRange`)** | พื้นที่แยกที่ `Z = 470` (`TestRangeSetup.server.lua`) สำหรับโชว์และเทส Dev | หยิบลองปืนครบ 18 กระบอก, โชว์ Rig ซอมบี้/บอส 5 แบบ, เวทีเทสแอนิเมชัน 8 สถานะ, ลู่ทดสอบการเคลื่อนไหว |

---

## 4. ระบบภารกิจเนื้อเรื่อง (Campaign Missions)

กำหนดค่าและโครงสร้างไว้ใน `MissionConfig.lua` และควบคุมฝั่ง Server ด้วย `MissionService.server.lua` + `ObjectiveTracker.lua`:

- **ภารกิจ 01 — `FIRST CONTACT` (`IMPLEMENTED`):**
  1. `M1_LOCATE_KEYCARD`: ตรวจค้นชั้น 1 โซนธนาคาร (`M1_BranchManagerCorpse`, `M1_BankVaultSafe` พร้อม `BankSafeKeypadModal`, `M1_KeycardPickup`, `M1_ManagerRevolverPickup`, `M1_ManagerOfficeNote`) รวมถึง `M1_MaintenanceKeyPickup` / `M1_ServiceLocker`
  2. `M1_ENTER_SECURITY_ROOM`: นำ `SecurityKeycard` ปลดล็อกประตู `M1_SecurityRoomDoor` เข้าห้องควบคุม 102 ซึ่งใช้ไฟสำรอง UPS เหลืองสลัว (`Room102UPSPercent` เริ่ม `34%` ลดต่ำสุด `8%`) และมีบันทึก `M1_GuardNote` เล่าเหตุการณ์ระบาด ผู้รอดชีวิตบนดาดฟ้า และทางหนีด้วยเฮลิคอปเตอร์
  3. `M1_SOLVE_CCTV_PUZZLE`: ตรวจเบาะแส (`M1_ClueBoard_Atrium`, `M1_ClueMemo_Room102`) แล้วกดเรียงกล้อง `CAM-01` ถึง `CAM-04` บน `M1_MonitorWall` ให้ตรงตามไทม์ไลน์ (ตั้งค่า Grid 3×4 หรือ 4×4 ได้ และมี `USE_MODAL_PUZZLE_FALLBACK` สลับไปใช้ UI `CCTVPuzzleModal` ได้) — หากกดผิดจะเปิดสัญญาณเตือน (`8` วินาที) และเรียกซอมบี้โทษ (`4` ตัว)
  4. `M1_ACTIVATE_SECURITY_CONTROL`: กด `M1_SecurityOverrideConsole` เพื่อเริ่ม **Hold-Out อัปโหลด 75 วินาที** ซอมบี้บุกห้อง 102 เป็นระลอก (ทุก `12` วินาที ครั้งละ `4` ตัว) ทีมต้องต้านทานและซ่อม Barricade จนครบเวลา → ปลดล็อก **Clearance Tier 1** และคลังอาวุธ Tier 1 (`Stinger`, `Bucky`, `Spectre`)
- **ภารกิจ 02 — `RESTORE POWER` (`IMPLEMENTED`):**
  - `M2_REACH_POWER_ROOM` → `M2_RESTORE_BUILDING_POWER`: ฝ่าขึ้นชั้น 2 ไปที่ `M2_PowerRoomGenerator` เพื่อสับสวิตช์กู้คืนไฟฟ้าหลักทั่วอาคาร (`BuildingPowerOn = true`) คืนแสงสว่าง `"Day"` และระบบไฟฟ้าให้เส้นทางสู่ชั้นบน
- **ภารกิจ 03 — `SIGNAL` และ ภารกิจ 04 — `EVAC` (`NOT IMPLEMENTED` — เตรียมโครง Config/Objective):**
  - วางโครงสร้าง `M3` (ขึ้นดาดฟ้าและติดต่อวิทยุฉุกเฉิน) และ `M4` (Hold-Out ต้านฝูงซอมบี้รอเฮลิคอปเตอร์ที่ลานดาดฟ้า — ฉากจบ `LAST SURVIVORS`) ไว้ใน `MissionConfig.lua` แล้วสำหรับพัฒนาต่อ

---

## 5. ระบบต่อสู้ ซอมบี้ และเอาชีวิตรอด

### อาวุธและเศรษฐกิจ (`WeaponRegistry.lua`, `WallBuysSetup.lua`, `WaveAndZombieManager.server.lua`)
- **ปืน 18 กระบอก (Config เฉพาะ 8 + Extra 10):**
  - *Sidearms:* `Classic` (เริ่มต้น), `Shorty`, `Frenzy`, `Ghost`, `Sheriff`
  - *SMGs:* `Stinger`, `Spectre`
  - *Shotguns:* `Bucky`, `Judge`
  - *Rifles:* `Bulldog`, `Guardian`, `Vandal`, `Phantom`
  - *Snipers:* `Marshal`, `Outlaw`, `Operator`
  - *Heavy:* `Ares`, `Odin`
- **จุดซื้อปืนในแมพ (`WallBuysSetup.lua`):** มี 9 สถานีกระจายตั้งแต่ `Buy_Ghost_F1` (500 แต้ม) ถึง `Buy_Operator_F10` (4,500 แต้ม) รองรับเติมกระสุน (50% ของราคา) และล็อกสิทธิ์ตาม `RequiredClearanceTier` / `RequiresOverrideDone`
- **ความปลอดภัยฝั่ง Server:** `FireWeapon` ส่งเฉพาะมุมกล้อง/จุดเริ่มจาก Client ให้ Server ตรวจสอบระยะ คำนวณ `Workspace:Raycast`, Headshot/Body damage ตามสเปกอาวุธ และคำนวณเสียงปืน (`handleGunshotNoise`)

### ซอมบี้และ AI Director (`ZombieCatalog.lua`, `ZombieAI.lua`, `ZombieDirector.lua`)
| ประเภท | ชื่อแสดงผล | ความสูง (studs) | Max HP | บทบาทหลัก |
|---|---|---|---|---|
| `MaleWalker` | `MALE INFECTED` | 5.15 | 125 | ซอมบี้เดินพื้นฐาน |
| `FemaleWalker` | `FEMALE INFECTED` | 4.95 | 110 | ซอมบี้เดินความคล่องสูงกว่าเล็กน้อย |
| `MaleRunner` | `MALE RUNNER` | 5.06 | 95 | ซอมบี้วิ่งไล่กดดัน |
| `FemaleRunner` | `FEMALE SHRIEKER` | 4.88 | 90 | ซอมบี้วิ่งเร็วสายจู่โจม |
| `MaleBoss` | `ABOMINATION BOSS` | 9.00 | 780 | บอสขนาดใหญ่ |

- **Dual-Mode ZombieDirector:** แยกโหมด `Campaign` (จัดการ 5 แชนเนล: `Ambient`, `Roaming`, `Noise`, `Objective`, `Boss`, เพดาน `maxAliveCampaign = 28`) ออกจากโหมด `Wave` (`!wave`, เพดาน `maxAliveWave = 28`) พร้อมตัวกรองไม่ให้เกิดต่อหน้าผู้เล่น (LOS/FOV & min distance) และไม่ซ้อนทับตัวอื่น
- **Ambush & Car Alarms:** ซอมบี้พ็อดซุ่ม `BANK_LOBBY_INITIAL_ZOMBIES` และ `FLOOR_AMBUSH_ZOMBIES[1..3]` เกิดแบบซุ่มตามชั้น (`reclaimDistantStragglersForAmbush` ช่วยเคลียร์ตัวหลงชั้นอื่นอัตโนมัติถ้าสล็อตเต็ม), ตื่นเมื่อเข้าใกล้ `15` studs / เห็นในระยะ `22` (`34` ถ้าเปิดไฟฉาย) / โดนยิง / เสียงปืน / สัญญาณกันขโมย `CarAlarmHazard` (รัศมี `80` studs + เรียก `Noise` horde)

### เอาชีวิตรอดและการเล่นเป็นทีม
- **Hunger & Battery (`SurvivalAndHorrorSetup.server.lua`):** ช่องเก็บของ `4–6` (`FoodPacks`, `MedkitPacks`, `BatteryPacks`) เก็บจากจุด Loot ชั้น 1–11
- **Downed & Revive (`DownedAndReviveManager.server.lua`):** เลือดหมดแล้วเข้าสถานะคลาน `30` วินาที เพื่อนกดค้าง `[E]` `3` วินาทีเพื่อชุบกลับมาที่ `60 HP`
- **Barricade (`BarricadeManager.server.lua`):** กด `[E]` ซ่อมไม้กั้นประตู-หน้าต่างได้ `+10` แต้มต่อแผ่น ใช้ถ่วงเวลาซอมบี้โดยเฉพาะช่วง Hold-Out ห้อง 102

---

## 6. การควบคุมและคำสั่งนักพัฒนา

### ปุ่มควบคุมผู้เล่น (`FPSController.client.lua` & `StaffPhoneUI.lua`)
- **เมาส์ซ้าย / ขวา:** ยิง / เล็ง (ADS / Sniper Scope)
- **`[1]` `[2]` `[3]` / `[Q]`:** สลับปืนหลัก ปืนรอง มีด / Quick Switch
- **`[4]` `[5]` `[6]`:** ใช้เสบียง อาหาร / ชุดปฐมพยาบาล / แบตเตอรี่ไฟฉาย
- **`[R]`:** บรรจุกระสุน (Reload)
- **`[L]`:** เปิด-ปิดไฟฉาย (กินแบตเตอรี่ และเพิ่มระยะที่ซอมบี้ซุ่มมองเห็นเป็น `34` studs)
- **`[Shift]` / `[Ctrl]`:** วิ่งสปรินต์ / สไลด์ (`NeonSlideAction`)
- **`[E]`:** โต้ตอบวัตถุ เก็บของ ซ่อม Barricade ช่วยชุบเพื่อน กดจอ Monitor Wall / Console / Generator
- **`[P]`:** เปิด-ปิด Staff Phone (`Notes`, `Messages`, `Inventory`, `Status`, `Map`)
- **`[B]`:** เปิด-ปิดคลังปืนทดสอบ (`ValorantBuyMenu`)

### ปุ่ม & คำสั่ง Dev / Admin (`DevAuthService.lua`, `DevCommandService.server.lua`)
- **ปุ่มลัด Dev:** `[G]` Admin Mode (God Mode + Stamina ไม่จำกัด + วิ่งไว), `[H]` สลับพรีเซ็ตหลอน, `[N]` สลับแสงสว่าง/มืด, `[Z]` หยุดซอมบี้ชั่วคราว, `[M]` เมนูวาร์ป
- **คำสั่งแชท (`!help`):** `!dev off`, `!bypass on/off`, `!mission M1/status/reset`, `!objective complete <ID>`, `!give <item>`, `!key give/consume <item>`, `!door list/unlock/lock <id>`, `!clearance <0..4|reset>`, `!boss <id>`, `!wave [on/off]`, `!horde [n]`, `!noise [w]`, `!encounter <id>`, `!zombie off/on/reset/stats`, `!clearzombies`, `!spawn <z>`, `!tp <loc>` (เช่น `lobby`, `room102`, `f2`, `f3`, `f11`, `roof`, `range`), `!power on/off`, `!god`, `!test` (รัน Automated Suite 11 ชุด)

---

## 7. วิธีเปิดใช้งาน Sync และทดสอบ

1. **เปิดโปรเจคและ Live Sync:**
   - รัน `launch_game_sync.bat` หรือเปิด `start_rojo.bat` (`.\rojo.exe serve` บน `http://localhost:34872`) แล้วเปิด `HorrorGame.rbxl` ใน Roblox Studio และกด Connect ใน Rojo Plugin
   - หรือ build ไฟล์ `.rbxl` ใหม่จากซอร์สด้วย:
     ```powershell
     .\rojo.exe build default.project.json -o HorrorGame.rbxl
     ```
2. **ตรวจโครงสร้าง Rojo Sourcemap:**
   ```powershell
   .\rojo.exe sourcemap default.project.json
   ```
3. **ทดสอบใน Roblox Studio:**
   - **คนเดียว (Play Solo):** กด **Play** เพื่อลองระบบแสงมืด, ซอมบี้ซุ่ม, รถกันขโมย, ภารกิจ M1 ห้อง 102 จนถึง M2 กู้ไฟชั้น 2 หรือพิมพ์ `!test` เพื่อตรวจ `MissionLogicTests`
   - **หลายคน (Co-op Local Server):** แท็บ **Test → Clients and Servers → 2–4 Players → Start** เพื่อทดสอบการแชร์คีย์ไอเทม การช่วยชุบเพื่อน Hold-Out ห้อง 102 และการซิงค์พ็อดซอมบี้ข้ามชั้น
