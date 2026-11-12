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

MissionConfig.ORDER = { "M1", "M2", "M3", "M4", "M5", "M6", "M7" }

-- Accurate Building 40 directory mapped to the actual server map modules.
-- Used by both FloorClearanceService (server) and Staff Phone Map/Status tabs (client).
MissionConfig.BUILDING_FLOORS = {
	{ floor = 1, name = "Main Lobby & Security Room 102", zone = "Ground Ingress", requiredTier = 0, requiresPower = false },
	{ floor = 2, name = "KMUTNB Canteen & Power Conduit", zone = "Lower Commons", requiredTier = 1, requiresPower = false },
	{ floor = 3, name = "Lower Indoor Sports Arena", zone = "Lower Assembly", requiredTier = 1, requiresPower = false },
	{ floor = 4, name = "Atrium Research Wing F4", zone = "Mid Atrium", requiredTier = 1, requiresPower = true },
	{ floor = 5, name = "Atrium Labs & Archive F5", zone = "Mid Atrium", requiredTier = 1, requiresPower = true },
	{ floor = 6, name = "Atrium Annex F6", zone = "Mid Atrium", requiredTier = 1, requiresPower = true },
	{ floor = 7, name = "Volleyball & Badminton Courts", zone = "Recreational Core", requiredTier = 2, requiresPower = true },
	{ floor = 8, name = "Upper Academic Wing F8", zone = "Upper Atrium", requiredTier = 2, requiresPower = true },
	{ floor = 9, name = "Upper Communications Wing F9", zone = "Upper Atrium", requiredTier = 2, requiresPower = true },
	{ floor = 10, name = "Restricted Annex F10", zone = "Upper Atrium", requiredTier = 2, requiresPower = true },
	{ floor = 11, name = "Biohazard Quarantine Wing", zone = "Quarantine Sector", requiredTier = 3, requiresPower = true },
	{ floor = 12, name = "F12 Indoor Sports Arena & Roof Helipad", zone = "Boss Arena / Extraction", requiredTier = 4, requiresPower = true },
}

MissionConfig.MISSIONS = {
	M1 = {
		id = "M1",
		code = "MISSION 01",
		legacyId = "SECURITY_ACCESS",
		aliases = { "FIRST_CONTACT", "SECURITY_ACCESS", "M1" },
		name = "FIRST CONTACT",
		displayName = "ปฐมบทเอาชีวิตรอด (First Contact)",
		mainObjective = "Investigate the Building 40 F1 breach, access Security Room 102, verify CCTV Timeline logs, and restore Security Control",
		floorHint = "Building 40 — Floor 1",
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
				title = "Find Security Access Credentials",
				detail = "Search Floor 1 offices, service counters, and reception areas for a Building 40 Security Keycard.",
			},
			{
				id = "M1_ENTER_SECURITY_ROOM",
				index = 2,
				type = NetProtocol.ObjectiveType.Interact,
				requiredItem = "SecurityKeycard",
				requiredDoorId = "M1_SECURITY_ROOM_DOOR",
				title = "Unlock Security Room 102",
				detail = "Locate Security Control Room 102 off the ground floor corridor and bypass the card reader.",
			},
			{
				id = "M1_SOLVE_CCTV_PUZZLE",
				index = 3,
				type = NetProtocol.ObjectiveType.SolvePuzzle,
				puzzleId = "M1_CCTV_TIMELINE",
				title = "Reconstruct CCTV Breach Timeline",
				detail = "Piece together environmental security memos and sort the 4 CCTV camera logs in chronological order.",
			},
			{
				id = "M1_ACTIVATE_SECURITY_CONTROL",
				index = 4,
				type = NetProtocol.ObjectiveType.Activate,
				title = "Bring F1 Security Override Online",
				detail = "Activate the Security Control Override console inside Room 102 to complete First Contact.",
			},
		},
	},
	M2 = {
		id = "M2",
		code = "MISSION 02",
		legacyId = "RESTORE_POWER",
		aliases = { "POWER_OUTAGE", "RESTORE_POWER", "M2" },
		name = "RESTORE POWER",
		displayName = "กู้คืนระบบไฟฟ้า (Restore Power)",
		mainObjective = "Collect Fuse A/B/C and solve Circuit Puzzle to unlock elevator power",
		floorHint = "Building 40 — Lower Floors F2-F3 (Planned)",
		implemented = false,
		implementationStatus = "NOT IMPLEMENTED",
		prerequisites = { "M1" },
		requireAllPrerequisites = true,
		nextMissionId = "M3",
		nextMissions = { "M3", "M4" },
		objectives = {
			{
				id = "M2_COLLECT_FUSES",
				index = 1,
				type = NetProtocol.ObjectiveType.CollectItem,
				requiredItems = { "FuseA", "FuseB", "FuseC" },
				title = "Collect Fuse A / B / C [NOT IMPLEMENTED]",
				detail = "Planned for Phase 3: locate 3 high-voltage fuses across lower campus floors.",
				implemented = false,
			},
			{
				id = "M2_SOLVE_CIRCUIT",
				index = 2,
				type = NetProtocol.ObjectiveType.SolvePuzzle,
				puzzleId = "M2_CIRCUIT",
				title = "Solve Circuit Breaker Puzzle [NOT IMPLEMENTED]",
				detail = "Planned for Phase 3.",
				implemented = false,
			},
		},
	},
	M3 = {
		id = "M3",
		code = "MISSION 03",
		legacyId = "DECODE_SAFE",
		aliases = { "DECODE_THE_SAFE", "DECODE_SAFE", "M3" },
		name = "DECODE THE SAFE",
		displayName = "ถอดรหัสตู้นิรภัย (Decode the Safe)",
		mainObjective = "Investigate mid-floor research journals and decode the encrypted safe",
		floorHint = "Building 40 — Mid Atrium F4-F7 (Parallel w/ M4, Planned)",
		implemented = false,
		implementationStatus = "NOT IMPLEMENTED",
		prerequisites = { "M2" },
		requireAllPrerequisites = true,
		parallelGroup = "MID_BRANCH",
		nextMissionId = "M5",
		nextMissions = { "M5" },
		objectives = {
			{
				id = "M3_SOLVE_SAFE",
				index = 1,
				type = NetProtocol.ObjectiveType.SolvePuzzle,
				puzzleId = "M3_SAFE_CODE",
				title = "Analyze Journal & Decode Safe [NOT IMPLEMENTED]",
				detail = "Planned for Phase 3 (can run alongside M4).",
				implemented = false,
			},
		},
	},
	M4 = {
		id = "M4",
		code = "MISSION 04",
		legacyId = "CALL_RESCUE",
		aliases = { "CONTACT_THE_OUTSIDE", "CALL_RESCUE", "M4" },
		name = "CONTACT THE OUTSIDE",
		displayName = "ติดต่อภายนอก (Contact the Outside)",
		mainObjective = "Recover Battery Module, repair transceiver, and match rescue frequency",
		floorHint = "Building 40 — Upper Atrium F8-F10 (Parallel w/ M3, Planned)",
		implemented = false,
		implementationStatus = "NOT IMPLEMENTED",
		prerequisites = { "M2" },
		requireAllPrerequisites = true,
		parallelGroup = "MID_BRANCH",
		nextMissionId = "M5",
		nextMissions = { "M5" },
		objectives = {
			{
				id = "M4_REPAIR_RADIO",
				index = 1,
				type = NetProtocol.ObjectiveType.SolvePuzzle,
				puzzleId = "M4_FREQUENCY",
				title = "Repair Radio & Match Frequency [NOT IMPLEMENTED]",
				detail = "Planned for Phase 3 (can run alongside M3).",
				implemented = false,
			},
		},
	},
	M5 = {
		id = "M5",
		code = "MISSION 05",
		legacyId = "REACH_ROOF",
		aliases = { "ASCEND_TO_QUARANTINE", "REACH_ROOF", "M5" },
		name = "ASCEND TO QUARANTINE",
		displayName = "ฝ่าเขตกักกันชั้น 11 (Ascend to Quarantine)",
		mainObjective = "Obtain Quarantine & Master Keycards and breach Floor 11 Quarantine",
		floorHint = "Building 40 — Floor 11 Quarantine Wing (Planned)",
		implemented = false,
		implementationStatus = "NOT IMPLEMENTED",
		prerequisites = { "M3", "M4" },
		requireAllPrerequisites = true,
		nextMissionId = "M6",
		nextMissions = { "M6" },
		objectives = {
			{
				id = "M5_REACH_F11",
				index = 1,
				type = NetProtocol.ObjectiveType.ReachArea,
				title = "Unlock F11 Airlock & Confront Threat [NOT IMPLEMENTED]",
				detail = "Planned for Phase 4 (requires M3 and M4 complete).",
				implemented = false,
			},
		},
	},
	M6 = {
		id = "M6",
		code = "MISSION 06",
		legacyId = "ACTIVATE_BEACON",
		aliases = { "SUBJECT_ZERO", "ACTIVATE_BEACON", "M6" },
		name = "SUBJECT ZERO",
		displayName = "เผชิญหน้า Subject Zero (F12 Arena)",
		mainObjective = "Enter the F12 Indoor Sports Arena, defeat SUBJECT ZERO, and activate Beacon",
		floorHint = "Building 40 — F12 Indoor Sports Arena (Boss Arena, Planned)",
		implemented = false,
		implementationStatus = "NOT IMPLEMENTED",
		prerequisites = { "M5" },
		requireAllPrerequisites = true,
		nextMissionId = "M7",
		nextMissions = { "M7" },
		objectives = {
			{
				id = "M6_DEFEND_BEACON",
				index = 1,
				type = NetProtocol.ObjectiveType.Defend,
				title = "Defeat SUBJECT ZERO & Activate Beacon [NOT IMPLEMENTED]",
				detail = "Planned for Phase 4-5 in the F12 Indoor Sports Arena.",
				implemented = false,
			},
		},
	},
	M7 = {
		id = "M7",
		code = "MISSION 07",
		legacyId = "BOARD_HELICOPTER",
		aliases = { "FINAL_EXTRACTION", "BOARD_HELICOPTER", "M7" },
		name = "BOARD HELICOPTER",
		displayName = "ฝ่าดาดฟ้าขึ้นเฮลิคอปเตอร์ (Final Extraction)",
		mainObjective = "Ascend F12 Roof Access to the Helipad, hold the extraction zone, and escape",
		floorHint = "Building 40 — F12 Roof Access & Helipad (Ending: LAST SURVIVORS, Planned)",
		implemented = false,
		implementationStatus = "NOT IMPLEMENTED",
		prerequisites = { "M6" },
		requireAllPrerequisites = true,
		nextMissionId = nil,
		nextMissions = {},
		objectives = {
			{
				id = "M7_EXTRACTION",
				index = 1,
				type = NetProtocol.ObjectiveType.Survive,
				title = "Board Helicopter at Roof Helipad [NOT IMPLEMENTED]",
				detail = "Planned for Phase 5 (Ending: LAST SURVIVORS).",
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
