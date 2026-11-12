-- Server-authoritative Mission State Machine, Parallel Mission Graph, & Staff Phone Feed.
-- Delegates Inventory/Keys to KeyItemService, Floor Access to FloorClearanceService, and
-- Door Locks to DoorAccessService while keeping pure-Luau testability intact.

local ObjectiveTracker = {}

local VALID_STATE_TRANSITIONS = {
	LOCKED = { AVAILABLE = true, ACTIVE = true, COMPLETED = true },
	AVAILABLE = { ACTIVE = true, LOCKED = true, COMPLETED = true },
	ACTIVE = { COMPLETED = true, FAILED = true, LOCKED = true, AVAILABLE = true },
	COMPLETED = { ACTIVE = true, LOCKED = true, AVAILABLE = true },
	FAILED = { ACTIVE = true, AVAILABLE = true, LOCKED = true },
}

local function tryRequireSibling(name)
	if script and script.Parent then
		local child = script.Parent:FindFirstChild(name)
		if child then
			local ok, mod = pcall(require, child)
			if ok then
				return mod
			end
		end
	end
	return nil
end

function ObjectiveTracker.create(deps)
	deps = deps or {}
	local MissionConfig = deps.MissionConfig
	local ItemCatalog = deps.ItemCatalog
	local NetProtocol = deps.NetProtocol
	local clockFn = deps.clockFn or os.clock
	assert(MissionConfig and ItemCatalog and NetProtocol, "ObjectiveTracker requires MissionConfig, ItemCatalog, and NetProtocol")

	local KeyItemMod = deps.KeyItemService or tryRequireSibling("KeyItemService")
	local FloorClearanceMod = deps.FloorClearanceService or tryRequireSibling("FloorClearanceService")
	local DoorAccessMod = deps.DoorAccessService or tryRequireSibling("DoorAccessService")

	local keyItemService = deps.keyItemService or (KeyItemMod and KeyItemMod.create({
		ItemCatalog = ItemCatalog,
		clockFn = clockFn,
	}))
	assert(keyItemService, "ObjectiveTracker requires KeyItemService")

	local floorClearanceService = deps.floorClearanceService or (FloorClearanceMod and FloorClearanceMod.create({
		MissionConfig = MissionConfig,
		keyItemService = keyItemService,
		clockFn = clockFn,
	}))
	assert(floorClearanceService, "ObjectiveTracker requires FloorClearanceService")

	local missionStates = {}
	local objectiveStates = {}

	local function isMissionCompleted(mId)
		return missionStates[mId] == NetProtocol.MissionState.COMPLETED
	end

	local doorAccessService = deps.doorAccessService or (DoorAccessMod and DoorAccessMod.create({
		keyItemService = keyItemService,
		floorClearanceService = floorClearanceService,
		isMissionCompletedFn = isMissionCompleted,
		clockFn = clockFn,
	}))
	assert(doorAccessService, "ObjectiveTracker requires DoorAccessService")

	local S = NetProtocol.MissionState
	local tracker = {}

	local activeMissionId = "M1"
	local campaignComplete = false
	local devBypassLocks = false
	local devTouchedMission = false
	local lastNotice = "Investigate Building 40 Floor 1 for security credentials."
	local noticeSeq = 0
	local notes = {}
	local messages = {}
	local readByPlayer = {} -- [userId] = { [entryKey] = true }

	local function setNotice(text)
		lastNotice = tostring(text or "")
		noticeSeq += 1
		return lastNotice
	end

	local function getMissionDef(missionId)
		return MissionConfig.getMission(missionId)
	end

	-- Register canonical Phase 1 + Interface Doors cleanly once on tracker init
	local function registerDefaultDoors()
		doorAccessService.registerDoor({
			doorId = "M1_SECURITY_ROOM_DOOR",
			displayName = "Security Control Room 102 Door",
			floor = 1,
			requiredKey = "SecurityKeycard",
			consumeKey = false,
			requiresPower = false,
			requiredClearance = 0,
			startsUnlocked = false,
		})
		doorAccessService.registerDoor({
			doorId = "M1_SERVICE_LOCKER",
			displayName = "F1 Maintenance Supply Locker",
			floor = 1,
			requiredKey = "MaintenanceKey",
			consumeKey = true,
			requiresPower = false,
			requiredClearance = 0,
			startsUnlocked = false,
		})
		doorAccessService.registerDoor({
			doorId = "F11_QUARANTINE_AIRLOCK",
			displayName = "Floor 11 Quarantine Airlock",
			floor = 11,
			requiredKey = "QuarantineKeycard",
			consumeKey = false,
			requiresPower = true,
			requiredClearance = 3,
			startsUnlocked = false,
		})
	end
	registerDefaultDoors()

	function tracker.addPhoneNote(spec)
		if type(spec) ~= "table" or type(spec.id) ~= "string" or spec.id == "" then
			return false
		end
		for _, existing in ipairs(notes) do
			if existing.id == spec.id then
				if spec.body then
					existing.body = spec.body
				end
				return false
			end
		end
		table.insert(notes, 1, {
			id = spec.id,
			title = tostring(spec.title or "Field Note"),
			category = tostring(spec.category or "Investigation"),
			missionId = tostring(spec.missionId or activeMissionId),
			floor = tonumber(spec.floor) or 1,
			body = tostring(spec.body or ""),
			discoveredBy = tostring(spec.discoveredBy or "Squad"),
			discoveredAt = clockFn(),
		})
		noticeSeq += 1
		return true
	end

	function tracker.addPhoneMessage(spec)
		if type(spec) ~= "table" or type(spec.id) ~= "string" or spec.id == "" then
			return false
		end
		for _, existing in ipairs(messages) do
			if existing.id == spec.id then
				return false
			end
		end
		table.insert(messages, 1, {
			id = spec.id,
			sender = tostring(spec.sender or "KMUTNB DISPATCH"),
			subject = tostring(spec.subject or "Alert"),
			body = tostring(spec.body or ""),
			missionId = tostring(spec.missionId or activeMissionId),
			timestamp = clockFn(),
		})
		noticeSeq += 1
		return true
	end

	function tracker.markPhoneEntryRead(userId, kind, entryId)
		if type(userId) ~= "number" or type(entryId) ~= "string" then
			return false
		end
		readByPlayer[userId] = readByPlayer[userId] or {}
		readByPlayer[userId][tostring(kind) .. ":" .. entryId] = true
		return true
	end

	function tracker.getUnreadPhoneCountForPlayer(userId)
		local readMap = (userId and readByPlayer[userId]) or {}
		local count = 0
		for _, n in ipairs(notes) do
			if not readMap["note:" .. n.id] then
				count += 1
			end
		end
		for _, m in ipairs(messages) do
			if not readMap["msg:" .. m.id] then
				count += 1
			end
		end
		return count
	end

	local function seedInitialPhoneData()
		notes = {}
		messages = {}
		readByPlayer = {}
		tracker.addPhoneMessage({
			id = "MSG_M1_DISPATCH_OPEN",
			sender = "B40 AUTOMATED DISPATCH",
			subject = "LOCKDOWN ACTIVE — F1",
			missionId = "M1",
			body = "Emergency blackout triggered in Building 40. Upper elevators locked. Locate on-site security credentials and restore Room 102 monitoring.",
		})
		tracker.addPhoneNote({
			id = "NOTE_M1_BRIEFING",
			title = "Shift Handover: Security Room 102",
			category = "Briefing",
			missionId = "M1",
			floor = 1,
			discoveredBy = "Staff Phone Archive",
			body = "Guard rotation keys and ID badges were last signed out at F1 public service desks before lockdown. Room 102 card reader retains local backup battery.",
		})
	end

	local function initMissionTree(suppressNotice)
		activeMissionId = "M1"
		campaignComplete = false
		keyItemService.resetAll()
		floorClearanceService.resetAll()
		doorAccessService.resetAll()

		for _, mId in ipairs(MissionConfig.ORDER) do
			local m = MissionConfig.MISSIONS[mId]
			missionStates[mId] = (mId == "M1") and S.ACTIVE or S.LOCKED
			objectiveStates[mId] = {}
			for idx, obj in ipairs(m.objectives) do
				if mId == "M1" then
					objectiveStates[mId][obj.id] = (idx == 1) and S.ACTIVE or S.LOCKED
				else
					objectiveStates[mId][obj.id] = S.LOCKED
				end
			end
		end
		seedInitialPhoneData()
		if not suppressNotice then
			setNotice("FIRST CONTACT: Investigate Building 40 F1 and locate security credentials.")
		end
	end

	initMissionTree(false)

	-- Exposes modular services cleanly for MissionService, WorldInteractables, Elevator, DevCommands & Tests.
	function tracker.getServices()
		return {
			keyItemService = keyItemService,
			floorClearanceService = floorClearanceService,
			doorAccessService = doorAccessService,
		}
	end

	function tracker.getActiveMissionId()
		return activeMissionId
	end

	function tracker.getActiveMissionIds()
		local list = {}
		for _, mId in ipairs(MissionConfig.ORDER) do
			if missionStates[mId] == S.ACTIVE then
				table.insert(list, mId)
			end
		end
		return list
	end

	function tracker.getMissionState(missionId)
		return missionStates[missionId]
	end

	function tracker.getObjectiveState(missionId, objectiveId)
		local map = objectiveStates[missionId]
		return map and map[objectiveId] or nil
	end

	function tracker.isSecurityDoorUnlocked()
		return doorAccessService.isUnlocked("M1_SECURITY_ROOM_DOOR")
	end

	function tracker.isBuildingPowerOn()
		return floorClearanceService.isPowerOn()
	end

	function tracker.setBuildingPowerOn(enabled, noticeOverride)
		floorClearanceService.setPowerOn(enabled == true)
		if type(noticeOverride) == "string" and noticeOverride ~= "" then
			setNotice(noticeOverride)
		else
			setNotice(floorClearanceService.isPowerOn() and "Building 40 Power Grid: ONLINE" or "Building 40 Power Grid: BLACKOUT (OFF)")
		end
	end

	function tracker.setDevBypassLocks(enabled)
		devBypassLocks = enabled == true
		floorClearanceService.setDevBypass(devBypassLocks)
	end

	function tracker.isDevBypassLocks()
		return devBypassLocks
	end

	function tracker.isDevTouched()
		return devTouchedMission
	end

	function tracker.markDevTouched()
		devTouchedMission = true
	end

	function tracker.getLastNotice()
		return lastNotice
	end

	function tracker.getActiveObjectiveId(missionId)
		local mId = missionId or activeMissionId
		local m = getMissionDef(mId)
		if not m then
			return nil
		end
		local states = objectiveStates[mId]
		for _, obj in ipairs(m.objectives) do
			if states[obj.id] == S.ACTIVE or states[obj.id] == S.AVAILABLE then
				return obj.id
			end
		end
		return nil
	end

	function tracker.hasTeamQuestItem(itemId)
		return keyItemService.hasTeamItem(itemId, 1)
	end

	function tracker.getQuestItemHolder(itemId)
		return keyItemService.getItemHolder(itemId)
	end

	function tracker.playerHasQuestItem(userId, itemId)
		return keyItemService.hasItem(userId, itemId, 1) or keyItemService.hasTeamItem(itemId, 1)
	end

	function tracker.registerPlayer(userId, playerName)
		if type(userId) ~= "number" then
			return false
		end
		keyItemService.registerPlayer(userId, playerName)
		return true
	end

	function tracker.setPlayerAliveState(userId, isAlive, isDowned)
		return keyItemService.setPlayerStatus(userId, isAlive, isDowned)
	end

	local function handleItemEvacuationEvents(events, verb)
		local out = {}
		for _, ev in ipairs(events or {}) do
			if ev.respawnWorld and ev.itemId == "SecurityKeycard" and not tracker.isSecurityDoorUnlocked() then
				if objectiveStates.M1.M1_LOCATE_KEYCARD == S.COMPLETED then
					objectiveStates.M1.M1_LOCATE_KEYCARD = S.ACTIVE
					objectiveStates.M1.M1_ENTER_SECURITY_ROOM = S.LOCKED
				end
				setNotice(string.format("%s %s with Security Keycard; badge returned to F1 reception counter.", tostring(ev.fromName), verb))
			elseif ev.newHolder then
				setNotice(string.format("%s %s; %s transferred to %s.", tostring(ev.fromName), verb, tostring(ev.itemId), tostring(ev.newHolder)))
			end
			table.insert(out, ev)
		end
		return out
	end

	function tracker.removePlayer(userId)
		local rawEvents = keyItemService.removePlayer(userId)
		readByPlayer[userId] = nil
		return handleItemEvacuationEvents(rawEvents, "disconnected")
	end

	function tracker.onPlayerDied(userId)
		local rawEvents = keyItemService.onPlayerDied(userId)
		return handleItemEvacuationEvents(rawEvents, "was incapacitated")
	end

	function tracker.getPlayerCount()
		return #keyItemService.getInventoryList() >= 0 and (function()
			-- Count via KeyItemService player registry indirectly? No: let's track connected roster count cleanly.
			return nil
		end)()
	end

	-- Maintain lightweight player count map synchronized with register/remove
	local connectedPlayers = {}
	local origRegister = tracker.registerPlayer
	function tracker.registerPlayer(userId, playerName)
		if type(userId) ~= "number" then
			return false
		end
		connectedPlayers[userId] = true
		return origRegister(userId, playerName)
	end
	local origRemove = tracker.removePlayer
	function tracker.removePlayer(userId)
		connectedPlayers[userId] = nil
		return origRemove(userId)
	end
	function tracker.getPlayerCount()
		local count = 0
		for _ in pairs(connectedPlayers) do
			count += 1
		end
		return count
	end

	function tracker.acquireInteractionLock(objectId, userId, durationSeconds)
		return keyItemService.acquireLock(objectId, userId, durationSeconds or 1.25)
	end

	function tracker.releaseInteractionLock(objectId, userId)
		keyItemService.releaseLock(objectId, userId)
	end

	-- Recomputes AVAILABLE unlocks across linear and parallel mission branches (M2 -> M3 + M4 -> M5 -> M6 -> M7).
	function tracker.recomputeUnlocks()
		local newlyUnlocked = {}
		for _, mId in ipairs(MissionConfig.ORDER) do
			local m = MissionConfig.MISSIONS[mId]
			if missionStates[mId] == S.LOCKED then
				local prereqs = m.prerequisites or {}
				local ready = #prereqs > 0
				if ready then
					if m.requireAllPrerequisites ~= false then
						for _, pId in ipairs(prereqs) do
							if missionStates[pId] ~= S.COMPLETED then
								ready = false
								break
							end
						end
					else
						ready = false
						for _, pId in ipairs(prereqs) do
							if missionStates[pId] == S.COMPLETED then
								ready = true
								break
							end
						end
					end
				end
				if ready then
					missionStates[mId] = S.AVAILABLE
					table.insert(newlyUnlocked, mId)
				end
			end
		end
		return newlyUnlocked
	end

	-- Starts an AVAILABLE (or optionally prerequisite-satisfied) mission, supporting parallel ACTIVE missions (e.g. M3 & M4).
	function tracker.activateMission(rawMissionId, opts)
		opts = opts or {}
		local m = getMissionDef(rawMissionId)
		if not m then
			return false, "Unknown mission ID: " .. tostring(rawMissionId)
		end
		if not m.implemented and opts.allowUnimplemented ~= true then
			return false, string.format("%s (%s) is [%s].", m.code, m.name, m.implementationStatus)
		end
		local cur = missionStates[m.id]
		if cur == S.COMPLETED and opts.allowReplay ~= true then
			return false, m.code .. " is already COMPLETED"
		end
		if cur == S.LOCKED and opts.forceUnlock ~= true then
			return false, m.code .. " prerequisites are not complete"
		end

		missionStates[m.id] = S.ACTIVE
		for idx, obj in ipairs(m.objectives) do
			objectiveStates[m.id][obj.id] = (idx == 1) and S.ACTIVE or S.LOCKED
		end
		activeMissionId = m.id
		setNotice(string.format("%s ACTIVE: %s", m.code, m.name))
		return true, lastNotice
	end

	local function completeMissionInternal(missionId, noticeText)
		local m = getMissionDef(missionId)
		if not m then
			return false, "Unknown mission"
		end
		missionStates[missionId] = S.COMPLETED
		for _, obj in ipairs(m.objectives) do
			objectiveStates[missionId][obj.id] = S.COMPLETED
		end

		local unlockedList = tracker.recomputeUnlocks()
		if missionId == "M7" then
			campaignComplete = true
		elseif #unlockedList == 0 then
			-- Switch primary focus to another still-ACTIVE parallel mission if any
			for _, candidateId in ipairs(MissionConfig.ORDER) do
				if missionStates[candidateId] == S.ACTIVE then
					activeMissionId = candidateId
					break
				end
			end
		end

		if #unlockedList > 0 then
			local labels = {}
			for _, uId in ipairs(unlockedList) do
				local uDef = getMissionDef(uId)
				table.insert(labels, uDef and string.format("%s (%s — %s)", uDef.code, uDef.name, uDef.implementationStatus) or uId)
			end
			setNotice(noticeText or string.format("%s COMPLETED! Unlocked: %s", m.code, table.concat(labels, " & ")))
		else
			setNotice(noticeText or string.format("%s COMPLETED!", m.code))
		end
		return true, lastNotice
	end

	local function completeObjectiveInternal(missionId, objectiveId, noticeText)
		local m = getMissionDef(missionId)
		if not m then
			return false, "Unknown mission"
		end
		local states = objectiveStates[missionId]
		if not states or not states[objectiveId] then
			return false, "Unknown objective"
		end
		if states[objectiveId] == S.COMPLETED then
			return false, "Objective already completed"
		end

		states[objectiveId] = S.COMPLETED

		local foundCurrent = false
		local activatedNext = nil
		for _, obj in ipairs(m.objectives) do
			if obj.id == objectiveId then
				foundCurrent = true
			elseif foundCurrent and states[obj.id] == S.LOCKED then
				states[obj.id] = S.ACTIVE
				activatedNext = obj
				break
			end
		end

		if activatedNext then
			setNotice(noticeText or string.format("NEXT OBJECTIVE: %s", activatedNext.title))
			return true, lastNotice
		else
			return completeMissionInternal(missionId, noticeText)
		end
	end

	function tracker.collectKeycard(userId, playerName)
		if missionStates.M1 ~= S.ACTIVE then
			return false, "Mission 01 is not currently active."
		end
		if keyItemService.hasTeamItem("SecurityKeycard", 1) then
			return false, "Security Keycard has already been picked up by the squad."
		end
		if objectiveStates.M1.M1_LOCATE_KEYCARD ~= S.ACTIVE then
			return false, "Security Keycard objective is not active."
		end

		tracker.registerPlayer(userId, playerName)
		local gOk, gMsg = keyItemService.grantItem(userId, playerName, "SecurityKeycard", 1)
		if not gOk then
			return false, gMsg
		end

		tracker.addPhoneMessage({
			id = "MSG_M1_KEYCARD_FOUND",
			sender = "SQUAD LINK",
			subject = "Tier 1 Keycard Recovered",
			missionId = "M1",
			body = string.format("%s recovered a Security Keycard (Tier 1). Locate Security Control Room 102.", tostring(playerName or "Squad")),
		})

		return completeObjectiveInternal("M1", "M1_LOCATE_KEYCARD",
			string.format("%s obtained Security Keycard! Locate Security Room 102.", tostring(playerName or "Squad")))
	end

	function tracker.collectMaintenanceKey(userId, playerName)
		tracker.registerPlayer(userId, playerName)
		local gOk, gMsg = keyItemService.grantItem(userId, playerName, "MaintenanceKey", 1)
		if not gOk then
			return false, gMsg
		end
		setNotice(string.format("%s picked up the F1 Maintenance Key.", tostring(playerName or "Squad")))
		return true, lastNotice
	end

	function tracker.unlockSecurityDoor(userId, playerName)
		if missionStates.M1 ~= S.ACTIVE then
			return false, "Mission 01 is not active."
		end
		if doorAccessService.isUnlocked("M1_SECURITY_ROOM_DOOR") then
			return false, "Security Room 102 is already unlocked."
		end
		if objectiveStates.M1.M1_LOCATE_KEYCARD ~= S.COMPLETED then
			return false, "LOCKED: Locate Security Access Credentials first."
		end

		local dOk, dMsg = doorAccessService.attemptAccess("M1_SECURITY_ROOM_DOOR", {
			userId = userId,
			playerName = playerName,
			devBypass = false,
		}, { toggleIfUnlocked = false })
		if not dOk then
			return false, dMsg
		end

		tracker.addPhoneMessage({
			id = "MSG_M1_ROOM102_OPEN",
			sender = "ROOM 102 TERMINAL",
			subject = "CCTV Terminal Accessible",
			missionId = "M1",
			body = "Room 102 door unsealed. Corrupted CCTV timeline buffer detected on the security terminal inside.",
		})

		if objectiveStates.M1.M1_ENTER_SECURITY_ROOM == S.ACTIVE then
			return completeObjectiveInternal("M1", "M1_ENTER_SECURITY_ROOM",
				string.format("%s unlocked Room 102! Verify the CCTV Timeline inside.", tostring(playerName or "Squad")))
		end
		return true, setNotice("Room 102 Security Door unlocked.")
	end

	function tracker.canAccessCCTVTerminal()
		if missionStates.M1 ~= S.ACTIVE then
			return false, "Mission 01 is not active."
		end
		if not doorAccessService.isUnlocked("M1_SECURITY_ROOM_DOOR") or objectiveStates.M1.M1_ENTER_SECURITY_ROOM ~= S.COMPLETED then
			return false, "Unlock and enter Security Room 102 first."
		end
		if objectiveStates.M1.M1_SOLVE_CCTV_PUZZLE == S.COMPLETED then
			return false, "CCTV Timeline already verified. Activate the Override Console!"
		end
		return true
	end

	function tracker.completeCCTVPuzzle(userId, playerName)
		local canOpen, err = tracker.canAccessCCTVTerminal()
		if not canOpen then
			return false, err
		end
		tracker.addPhoneNote({
			id = "NOTE_M1_CCTV_VERIFIED",
			title = "CCTV Breach Sequence Verified",
			category = "Evidence",
			missionId = "M1",
			floor = 1,
			discoveredBy = tostring(playerName or "Squad"),
			body = "Reconstructed F1 camera timestamps confirm containment failure spread upward from the service conduit before emergency lockdown.",
		})
		return completeObjectiveInternal("M1", "M1_SOLVE_CCTV_PUZZLE",
			string.format("%s verified CCTV Timeline! Activate Security Override console.", tostring(playerName or "Squad")))
	end

	function tracker.activateSecurityControl(userId, playerName)
		if missionStates.M1 ~= S.ACTIVE then
			return false, "Mission 01 is not active."
		end
		if objectiveStates.M1.M1_SOLVE_CCTV_PUZZLE ~= S.COMPLETED then
			return false, "CONSOLE LOCKED: Verify CCTV Timeline logs first."
		end
		if objectiveStates.M1.M1_ACTIVATE_SECURITY_CONTROL ~= S.ACTIVE then
			return false, "Security Control Override already activated."
		end

		floorClearanceService.grantClearanceTier(1)
		tracker.addPhoneMessage({
			id = "MSG_M1_COMPLETE_BRIEF",
			sender = "BUILDING 40 SECURITY CORE",
			subject = "FIRST CONTACT COMPLETE",
			missionId = "M1",
			body = "F1 Security Override online. Tier 1 Clearance confirmed. Upper Grid remains dark — M2 (Restore Power) is NOT IMPLEMENTED yet in Phase 1.",
		})

		return completeObjectiveInternal("M1", "M1_ACTIVATE_SECURITY_CONTROL",
			string.format("MISSION 01 COMPLETE (%s)! M2 (Restore Power — NOT IMPLEMENTED) is now AVAILABLE.", tostring(playerName or "Squad")))
	end

	function tracker.resetCampaignToM1(reasonNotice)
		local finalNotice = (type(reasonNotice) == "string" and reasonNotice ~= "")
			and reasonNotice
			or "FIRST CONTACT: Investigate Building 40 F1 and locate security credentials."
		initMissionTree(true)
		return true, setNotice(finalNotice)
	end

	function tracker.setMissionById(rawMissionId, isDevCommand, opts)
		opts = opts or {}
		local m = MissionConfig.getMission(rawMissionId)
		if not m then
			return false, string.format("Unknown mission ID '%s'. Valid: M1..M7", tostring(rawMissionId))
		end
		if not m.implemented and opts.allowUnimplementedPreview ~= true then
			return false, string.format("%s (%s) is [%s] in Phase 1 and cannot be started.", m.code, m.name, m.implementationStatus)
		end
		if not VALID_STATE_TRANSITIONS[missionStates[m.id]][S.ACTIVE] then
			return false, string.format("Invalid transition into %s from %s", m.id, tostring(missionStates[m.id]))
		end
		if isDevCommand then
			tracker.markDevTouched()
		end
		if m.id == "M1" and opts.preserveProgress ~= true then
			return tracker.resetCampaignToM1("[DEV] Reset & loaded MISSION 01 — FIRST CONTACT.")
		end
		return tracker.activateMission(m.id, {
			allowUnimplemented = opts.allowUnimplementedPreview == true,
			forceUnlock = true,
			allowReplay = true,
		})
	end

	-- Explicit progression/test helper supporting parallel M3/M4 branching without faking unimplemented world gameplay.
	function tracker.completeMissionNode(rawMissionId, noticeText)
		local m = getMissionDef(rawMissionId)
		if not m then
			return false, "Unknown mission ID"
		end
		return completeMissionInternal(m.id, noticeText)
	end

	function tracker.devCompleteObjective(rawObjectiveId, actorPlayer)
		local m, obj = MissionConfig.findObjective(rawObjectiveId)
		if not m or not obj then
			return false, string.format("Unknown objective ID '%s'. Example: M1_LOCATE_KEYCARD", tostring(rawObjectiveId))
		end
		if not m.implemented then
			return false, string.format("Objective '%s' belongs to %s (%s) and is not implemented.", rawObjectiveId, m.code, m.implementationStatus)
		end
		tracker.markDevTouched()

		if objectiveStates[m.id][obj.id] == S.COMPLETED then
			return true, setNotice(string.format("[DEV] Objective %s is already COMPLETED.", obj.id))
		end

		if missionStates.M1 ~= S.ACTIVE and objectiveStates.M1[obj.id] ~= S.COMPLETED then
			missionStates.M1 = S.ACTIVE
		end

		for _, step in ipairs(m.objectives) do
			if objectiveStates[m.id][step.id] ~= S.COMPLETED then
				if step.id == "M1_LOCATE_KEYCARD" and not keyItemService.hasTeamItem("SecurityKeycard", 1) then
					local uid = actorPlayer and actorPlayer.UserId or 0
					local uname = actorPlayer and actorPlayer.Name or "Developer"
					if uid ~= 0 then
						tracker.registerPlayer(uid, uname)
					end
					keyItemService.grantItem(uid, uname, "SecurityKeycard", 1, { allowDuplicateTeam = true })
				elseif step.id == "M1_ENTER_SECURITY_ROOM" then
					doorAccessService.forceUnlock("M1_SECURITY_ROOM_DOOR", "DEV_OBJECTIVE_SKIP")
				end
				completeObjectiveInternal(m.id, step.id, string.format("[DEV] Completed objective %s", step.id))
			end
			if step.id == obj.id then
				break
			end
		end

		return true, string.format("[DEV] Objective %s is now COMPLETED.", obj.id)
	end

	function tracker.devGrantQuestItem(itemId, userId, playerName, allowFutureTest)
		local item = ItemCatalog.getQuestItem(itemId)
		if not item then
			return false, string.format("Unknown quest item '%s'", tostring(itemId))
		end
		if item.phase ~= "Phase1" and allowFutureTest ~= true then
			return false, string.format("%s is part of %s (NOT IMPLEMENTED in Phase 1).", item.displayName, item.missionId)
		end
		tracker.markDevTouched()
		if itemId == "SecurityKeycard" and objectiveStates.M1.M1_LOCATE_KEYCARD == S.ACTIVE and not keyItemService.hasTeamItem("SecurityKeycard", 1) then
			return tracker.collectKeycard(userId or 0, playerName or "Developer")
		end
		local gOk, gMsg = keyItemService.grantItem(userId or 0, playerName or "Developer", itemId, 1, { allowDuplicateTeam = true })
		if not gOk then
			return false, gMsg
		end
		return true, setNotice(string.format("[DEV] %s.", gMsg))
	end

	function tracker.serializeSnapshot(environmentMode, puzzleSolved, extraContext)
		extraContext = extraContext or {}
		local m = MissionConfig.MISSIONS[activeMissionId] or MissionConfig.MISSIONS.M1
		local states = objectiveStates[m.id] or {}
		local subList = {}
		local completedCount = 0
		local activeObj = nil

		for _, obj in ipairs(m.objectives) do
			local st = states[obj.id] or S.LOCKED
			if st == S.COMPLETED then
				completedCount += 1
			elseif not activeObj and (st == S.ACTIVE or st == S.AVAILABLE) then
				activeObj = obj
			end
			table.insert(subList, {
				id = obj.id,
				index = obj.index,
				type = obj.type,
				title = obj.title,
				detail = obj.detail,
				state = st,
				completed = (st == S.COMPLETED),
			})
		end

		local totalCount = #m.objectives
		local missionStatesCopy = {}
		local activeMissionsList = {}
		local nextAvailableInfo = nil
		for _, mId in ipairs(MissionConfig.ORDER) do
			local def = MissionConfig.MISSIONS[mId]
			missionStatesCopy[mId] = missionStates[mId]
			if missionStates[mId] == S.ACTIVE then
				table.insert(activeMissionsList, {
					id = def.id,
					code = def.code,
					name = def.name,
					implemented = def.implemented,
					implementationStatus = def.implementationStatus,
					parallelGroup = def.parallelGroup,
				})
			elseif mId ~= m.id and missionStates[mId] == S.AVAILABLE and not nextAvailableInfo then
				nextAvailableInfo = {
					id = def.id,
					code = def.code,
					name = def.name,
					implemented = def.implemented,
					implementationStatus = def.implementationStatus,
				}
			end
		end

		local inventoryList = keyItemService.getInventoryList()
		local questSummary = {}
		for _, entry in ipairs(inventoryList) do
			table.insert(questSummary, {
				itemId = entry.id,
				displayName = entry.displayName,
				holderUserId = entry.holderUserId,
				holderName = entry.holderName,
				quantity = entry.quantity,
				consumeOnUse = entry.consumeOnUse,
				description = entry.description,
			})
		end

		local viewerUserId = extraContext.viewerUserId
		local readMap = (viewerUserId and readByPlayer[viewerUserId]) or {}
		local notesCopy = {}
		for _, n in ipairs(notes) do
			table.insert(notesCopy, {
				id = n.id,
				title = n.title,
				category = n.category,
				missionId = n.missionId,
				floor = n.floor,
				body = n.body,
				discoveredBy = n.discoveredBy,
				discoveredAt = n.discoveredAt,
				read = readMap["note:" .. n.id] == true,
			})
		end
		local msgsCopy = {}
		for _, msg in ipairs(messages) do
			table.insert(msgsCopy, {
				id = msg.id,
				sender = msg.sender,
				subject = msg.subject,
				body = msg.body,
				missionId = msg.missionId,
				timestamp = msg.timestamp,
				read = readMap["msg:" .. msg.id] == true,
			})
		end

		local floorStatuses = floorClearanceService.getFloorStatuses({ devBypass = devBypassLocks })
		local doorsList = doorAccessService.listDoors()

		local legacyDone = (missionStates.M1 == S.COMPLETED) and 1 or 0
		return {
			protocolVersion = 3,
			missionId = m.id,
			missionCode = m.code,
			missionName = m.name,
			missionDisplayName = m.displayName,
			mainObjective = m.mainObjective,
			missionState = missionStates[m.id],
			implemented = m.implemented,
			implementationStatus = m.implementationStatus,
			objectives = subList,
			activeObjectiveId = activeObj and activeObj.id or nil,
			activeObjectiveTitle = activeObj and activeObj.title or (missionStates[m.id] == S.COMPLETED and "Mission Completed" or m.mainObjective),
			activeObjectiveDetail = activeObj and activeObj.detail or m.mainObjective,
			completedSubCount = completedCount,
			totalSubCount = totalCount,
			questItems = questSummary,
			hasKeycard = keyItemService.hasTeamItem("SecurityKeycard", 1),
			securityDoorUnlocked = doorAccessService.isUnlocked("M1_SECURITY_ROOM_DOOR"),
			puzzleSolved = puzzleSolved == true,
			buildingPowerOn = floorClearanceService.isPowerOn(),
			floorClearanceTier = floorClearanceService.getEffectiveTier(),
			environmentMode = environmentMode or NetProtocol.EnvironmentMode.Campaign,
			isDevSessionTainted = devTouchedMission,
			zombieMode = extraContext.zombieMode or NetProtocol.ZombieMode.Campaign,
			zombieStats = extraContext.zombieStats,
			notice = lastNotice,
			noticeSeq = noticeSeq,
			nextMission = nextAvailableInfo,
			activeMissions = activeMissionsList,
			missionStates = missionStatesCopy,
			coopPlayerCount = tracker.getPlayerCount(),
			phone = {
				notes = notesCopy,
				messages = msgsCopy,
				inventory = inventoryList,
				floors = floorStatuses,
				doors = doorsList,
				unreadCount = tracker.getUnreadPhoneCountForPlayer(viewerUserId),
			},

			-- Legacy fields preserved so older UI listeners never break
			completedCount = legacyDone,
			totalCount = #MissionConfig.ORDER,
			currentIndex = math.min(#MissionConfig.ORDER, legacyDone + 1),
			currentId = m.legacyId,
			currentTitle = activeObj and activeObj.title or m.displayName,
			currentDesc = activeObj and activeObj.detail or m.mainObjective,
			completed = {
				[m.legacyId] = (missionStates[m.id] == S.COMPLETED),
			},
			campaignComplete = campaignComplete,
		}
	end

	return tracker
end

return ObjectiveTracker
