-- Campaign mission definitions & Building 40 floor structure for INFECTED-KMUTNB.
-- Follows Project Direction:
--   - M1 (FIRST CONTACT) is playable end-to-end in Phase 1 while preserving CCTVPuzzleEngine.
--   - Obeys "NO FREE INFORMATION": no exact item coordinate/location spoilers in objective definitions.
--   - M2-M7 (including M3 & M4 parallel branch, M6 F12 SUBJECT ZERO Arena, M7 Roof Access & Helipad)
--     are accurately represented in config and cleanly marked NOT IMPLEMENTED until Phases 2-5.

local NetProtocol = require(script.Parent:WaitForChild("NetProtocol"))

local MissionConfig = {}

MissionConfig.ENDING_NAME = "LAST SURVIVORS"
MissionConfig.CAMPAIGN_DIFFICULTY = "HARD"
MissionConfig.COOP_MIN_PLAYERS = 2
MissionConfig.COOP_MAX_PLAYERS = 4

-- Configurable parameters for Room 102 Monitor Wall, UPS power, and Hold-Out defense.
MissionConfig.ROOM102 = {
	MONITOR_GRID_ROWS = 3, -- Adjustable: 3 (3x4 grid) or 4 (4x4 grid)
	MONITOR_GRID_COLS = 4,
	USE_MODAL_PUZZLE_FALLBACK = false, -- true = fallback to CCTVPuzzleModal UI; false = press CAM-01..04 on Monitor Wall
	OVERRIDE_HOLDOUT_SECONDS = 75, -- 60-90s upload hold-out defense
	UPS_INITIAL_PERCENT = 34,
	UPS_MIN_PERCENT = 8,
	WRONG_CCTV_PENALTY_ZOMBIES = 4,
	WRONG_CCTV_ALARM_SECONDS = 8,
	HOLDOUT_WAVE_INTERVAL_SECONDS = 12,
	HOLDOUT_ZOMBIES_PER_WAVE = 4,
	TIER1_UNLOCKED_WEAPONS = { "Stinger", "Bucky", "Spectre" },
}

MissionConfig.ORDER = { "M1", "M2", "M3", "M4" }

-- Accurate Building 40 directory mapped to the actual server map modules.
-- Used by both FloorClearanceService (server) and Staff Phone Map/Status tabs (client).
MissionConfig.BUILDING_FLOORS = {
	{ floor = 1, name = "โถงล็อบบี้หลัก & ห้องควบคุมความปลอดภัย 102", zone = "Ground Ingress", requiredTier = 0, requiresPower = false },
	{ floor = 2, name = "โรงอาหาร มจพ. & ตู้จ่ายไฟหลัก", zone = "Lower Commons", requiredTier = 1, requiresPower = false },
	{ floor = 3, name = "สนามกีฬาในร่มชั้นล่าง", zone = "Lower Assembly", requiredTier = 1, requiresPower = false },
	{ floor = 4, name = "โถงวิจัยชั้น 4", zone = "Mid Atrium", requiredTier = 1, requiresPower = true },
	{ floor = 5, name = "ห้องปฏิบัติการ & คลังเอกสารชั้น 5", zone = "Mid Atrium", requiredTier = 1, requiresPower = true },
	{ floor = 6, name = "ส่วนต่อขยายอาคารชั้น 6", zone = "Mid Atrium", requiredTier = 1, requiresPower = true },
	{ floor = 7, name = "สนามวอลเลย์บอล & แบดมินตัน", zone = "Recreational Core", requiredTier = 2, requiresPower = true },
	{ floor = 8, name = "โซนการเรียนชั้นบน F8", zone = "Upper Atrium", requiredTier = 2, requiresPower = true },
	{ floor = 9, name = "โซนสื่อสารอาคาร 40 ชั้น 9", zone = "Upper Atrium", requiredTier = 2, requiresPower = true },
	{ floor = 10, name = "พื้นที่จำกัดชั้น 10", zone = "Upper Atrium", requiredTier = 2, requiresPower = true },
	{ floor = 11, name = "เขตกักกันเชื้อชีวภาพชั้น 11", zone = "Quarantine Sector", requiredTier = 3, requiresPower = true },
	{ floor = 12, name = "ลานดาดฟ้า & จุดจอดเฮลิคอปเตอร์ F12", zone = "Extraction / Helipad", requiredTier = 4, requiresPower = true },
}

MissionConfig.MISSIONS = {
	M1 = {
		id = "M1",
		code = "ภารกิจ 01",
		legacyId = "SECURITY_ACCESS",
		aliases = { "FIRST_CONTACT", "SECURITY_ACCESS", "M1" },
		name = "FIRST CONTACT",
		displayName = "ปฐมบทเอาชีวิตรอด (First Contact)",
		mainObjective = "ค้นหาคีย์การ์ดปลดล็อกห้อง 102 ตรวจสมุดเวร รปภ. เรียงลำดับกล้อง CCTV และป้องกันห้องระหว่างอัปโหลด Security Override",
		floorHint = "อาคาร 40 — ชั้น 1",
		implemented = true,
		implementationStatus = "IMPLEMENTED",
		prerequisites = {},
		requireAllPrerequisites = true,
		nextMissionId = "M2",
		nextMissions = { "M2" },
		objectives = {
			{
				id = "M1_LOCATE_KEYCARD",
				index = 1,
				type = NetProtocol.ObjectiveType.CollectItem,
				itemId = "SecurityKeycard",
				title = "ค้นหาคีย์การ์ดระบบความปลอดภัย",
				detail = "ตรวจค้นพื้นที่สำนักงานชั้น 1 เพื่อหาคีย์การ์ดสำหรับปลดล็อกประตูห้องควบคุมความปลอดภัย",
			},
			{
				id = "M1_ENTER_SECURITY_ROOM",
				index = 2,
				type = NetProtocol.ObjectiveType.Interact,
				requiredItem = "SecurityKeycard",
				requiredDoorId = "M1_SECURITY_ROOM_DOOR",
				title = "ปลดล็อกประตูห้องควบคุมความปลอดภัย (ห้อง 102)",
				detail = "นำคีย์การ์ดไปแตะที่เครื่องอ่านบัตรหน้าห้อง 102 เพื่อเข้าสู่ระบบสำรองไฟ UPS",
			},
			{
				id = "M1_SOLVE_CCTV_PUZZLE",
				index = 3,
				type = NetProtocol.ObjectiveType.SolvePuzzle,
				puzzleId = "M1_CCTV_TIMELINE",
				title = "เรียงลำดับเหตุการณ์กล้องวงจรปิด (CAM-01 ถึง CAM-04)",
				detail = "ตรวจเบาะแสและกดจอ CAM-01 ถึง CAM-04 บนแผง Monitor Wall ตามลำดับเวลาให้ถูกต้อง (กดผิดสัญญาณเตือนจะดัง!)",
			},
			{
				id = "M1_ACTIVATE_SECURITY_CONTROL",
				index = 4,
				type = NetProtocol.ObjectiveType.Defend,
				title = "อัปโหลด Security Override & ป้องกันห้อง 102",
				detail = "กดสั่งการ Override แล้วต้านฝูงซอมบี้พร้อมซ่อม Barricade ประตู-หน้าต่างให้ครบ 75 วินาที เพื่อรับสิทธิ์ Tier 1",
			},
		},
	},
	M2 = {
		id = "M2",
		code = "ภารกิจ 02",
		legacyId = "RESTORE_POWER",
		aliases = { "POWER_OUTAGE", "RESTORE_POWER", "M2" },
		name = "RESTORE POWER",
		displayName = "กู้คืนระบบไฟฟ้า (Restore Power)",
		mainObjective = "มุ่งหน้าไปยังห้องไฟ / เครื่องกำเนิดไฟฟ้าหลักเพื่อคืนระบบไฟฟ้าให้ทั่วทั้งอาคาร 40",
		floorHint = "อาคาร 40 — ชั้น 2 โซนเครื่องกำเนิดไฟฟ้า",
		implemented = true,
		implementationStatus = "IMPLEMENTED",
		prerequisites = { "M1" },
		requireAllPrerequisites = true,
		nextMissionId = "M3",
		nextMissions = { "M3" },
		objectives = {
			{
				id = "M2_REACH_POWER_ROOM",
				index = 1,
				type = NetProtocol.ObjectiveType.ReachArea,
				title = "ไปที่ห้องควบคุมไฟฟ้า / เครื่องกำเนิดไฟฟ้าชั้น 2",
				detail = "ใช้สิทธิ์ระดับ 1 (Tier 1) ฝ่าฝูงซอมบี้ขึ้นบันไดไปยังชั้น 2 เพื่อค้นหาตู้เครื่องกำเนิดไฟฟ้าหลักของอาคาร",
			},
			{
				id = "M2_RESTORE_BUILDING_POWER",
				index = 2,
				type = NetProtocol.ObjectiveType.Activate,
				title = "สับสวิตช์กู้คืนไฟฟ้าหลักทั้งอาคาร",
				detail = "เดินเครื่องกำเนิดไฟฟ้าเพื่อคืนแสงสว่างทั่วอาคารและจ่ายไฟให้ระบบลิฟต์และเส้นทางสู่ดาดฟ้า",
			},
		},
	},
	M3 = {
		id = "M3",
		code = "ภารกิจ 03",
		legacyId = "SIGNAL",
		aliases = { "SIGNAL", "M3", "CONTACT_THE_OUTSIDE", "CALL_RESCUE", "DECODE_THE_SAFE", "DECODE_SAFE" },
		name = "SIGNAL",
		displayName = "ส่งสัญญาณขอความช่วยเหลือ (Signal)",
		mainObjective = "ฝ่าขึ้นสู่ชั้นดาดฟ้าอาคาร 40 และเปิดวิทยุสื่อสารติดต่อขอเฮลิคอปเตอร์อพยพ",
		floorHint = "อาคาร 40 — ชั้นดาดฟ้า / ห้องวิทยุสื่อสาร (เตรียมโครงระบบ)",
		implemented = false,
		implementationStatus = "NOT IMPLEMENTED",
		prerequisites = { "M2" },
		requireAllPrerequisites = true,
		nextMissionId = "M4",
		nextMissions = { "M4" },
		objectives = {
			{
				id = "M3_ASCEND_ROOF",
				index = 1,
				type = NetProtocol.ObjectiveType.ReachArea,
				title = "ฝ่าขึ้นสู่ชั้นดาดฟ้าอาคาร 40 [ยังไม่เปิดให้เล่นเต็มระบบ]",
				detail = "ใช้ระบบไฟและสิทธิ์ที่ปลดล็อกแล้วมุ่งหน้าสู่จุดสื่อสารชั้นบนสุด",
				implemented = false,
			},
			{
				id = "M3_RADIO_CONTACT",
				index = 2,
				type = NetProtocol.ObjectiveType.Activate,
				title = "ติดต่อวิทยุขอรับการช่วยเหลือฉุกเฉิน [ยังไม่เปิดให้เล่นเต็มระบบ]",
				detail = "ส่งสัญญาณแจ้งพิกัดผู้รอดชีวิตบนดาดฟ้าให้หน่วยกู้ภัยทราบ",
				implemented = false,
			},
		},
	},
	M4 = {
		id = "M4",
		code = "ภารกิจ 04",
		legacyId = "EVAC",
		aliases = { "EVAC", "M4", "BOARD_HELICOPTER", "FINAL_EXTRACTION", "ASCEND_TO_QUARANTINE", "SUBJECT_ZERO" },
		name = "EVAC",
		displayName = "อพยพทางอากาศ (Evac)",
		mainObjective = "ต้านทานฝูงซอมบี้ที่ลานจอดเฮลิคอปเตอร์ (Hold-Out) จนกว่าเฮลิคอปเตอร์ช่วยเหลือจะลงจอด",
		floorHint = "อาคาร 40 — ลานจอดเฮลิคอปเตอร์ดาดฟ้า (เตรียมโครงระบบ)",
		implemented = false,
		implementationStatus = "NOT IMPLEMENTED",
		prerequisites = { "M3" },
		requireAllPrerequisites = true,
		nextMissionId = nil,
		nextMissions = {},
		objectives = {
			{
				id = "M4_DEFEND_HELIPAD",
				index = 1,
				type = NetProtocol.ObjectiveType.Defend,
				title = "ต้านทานฝูงซอมบี้รอเฮลิคอปเตอร์ที่ลานดาดฟ้า (Hold-Out) [ยังไม่เปิดให้เล่นเต็มระบบ]",
				detail = "ป้องกันพื้นที่ลานจอดร่วมกับผู้รอดชีวิตจนครบเวลานับถอยหลังการลงจอด",
				implemented = false,
			},
			{
				id = "M4_BOARD_CHOPPER",
				index = 2,
				type = NetProtocol.ObjectiveType.Survive,
				title = "ขึ้นเฮลิคอปเตอร์อพยพออกจากอาคาร 40 [ยังไม่เปิดให้เล่นเต็มระบบ]",
				detail = "นำทีมขึ้นเครื่องให้ทันก่อนจุดอพยพถูกตีแตก (ฉากจบ: LAST SURVIVORS)",
				implemented = false,
			},
		},
	},
}

local LEGACY_TO_ID = {}
for _, mId in ipairs(MissionConfig.ORDER) do
	local m = MissionConfig.MISSIONS[mId]
	LEGACY_TO_ID[string.upper(m.id)] = m.id
	if m.legacyId then
		LEGACY_TO_ID[string.upper(m.legacyId)] = m.id
	end
	if type(m.aliases) == "table" then
		for _, alias in ipairs(m.aliases) do
			LEGACY_TO_ID[string.upper(alias)] = m.id
		end
	end
end

function MissionConfig.normalizeMissionId(rawId)
	if type(rawId) ~= "string" then
		return nil
	end
	local key = string.upper((rawId:gsub("^%s+", ""):gsub("%s+$", "")))
	return LEGACY_TO_ID[key]
end

function MissionConfig.getMission(missionId)
	local canonical = MissionConfig.normalizeMissionId(missionId)
	if not canonical then
		return nil
	end
	return MissionConfig.MISSIONS[canonical]
end

function MissionConfig.findObjective(objectiveId)
	if type(objectiveId) ~= "string" then
		return nil, nil
	end
	for _, mId in ipairs(MissionConfig.ORDER) do
		local mission = MissionConfig.MISSIONS[mId]
		for _, obj in ipairs(mission.objectives) do
			if obj.id == objectiveId then
				return mission, obj
			end
		end
	end
	return nil, nil
end

return MissionConfig
