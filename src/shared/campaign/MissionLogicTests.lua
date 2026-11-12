-- Automated pure-Luau Unit & Integration Test Suite for INFECTED-KMUTNB Phase 1.
-- Covers Foundation, M1 FIRST CONTACT, KeyItemService, DoorAccessService, FloorClearanceService,
-- Parallel M3/M4 Mission Graph, Staff Phone Feeds, and Dual-Mode ZombieDirector.
-- Executable inside Roblox Studio via `!test` or any standalone Luau/Lua CLI.

local MissionLogicTests = {}

local function fail(msg)
	error("[MissionLogicTests FAIL] " .. tostring(msg), 2)
end

local function assertTrue(cond, msg)
	if not cond then
		fail(msg or "Expected true")
	end
end

local function assertEqual(actual, expected, label)
	if actual ~= expected then
		fail(string.format("%s: expected '%s', got '%s'", tostring(label), tostring(expected), tostring(actual)))
	end
end

function MissionLogicTests.runAll(modules)
	local NetProtocol = modules.NetProtocol
	local ItemCatalog = modules.ItemCatalog
	local MissionConfig = modules.MissionConfig
	local DevAuthService = modules.DevAuthService
	local KeyItemService = modules.KeyItemService
	local FloorClearanceService = modules.FloorClearanceService
	local DoorAccessService = modules.DoorAccessService
	local ZombieDirector = modules.ZombieDirector
	local ObjectiveTracker = modules.ObjectiveTracker
	local CCTVPuzzleEngine = modules.CCTVPuzzleEngine

	assertTrue(
		NetProtocol and ItemCatalog and MissionConfig and DevAuthService
			and KeyItemService and FloorClearanceService and DoorAccessService
			and ZombieDirector and ObjectiveTracker and CCTVPuzzleEngine,
		"All Phase 1 core modules must be provided"
	)

	local results = {}
	local function runCase(name, fn)
		fn()
		table.insert(results, { name = name, passed = true })
	end

	local function createTrackerWithServices(clockFn)
		return ObjectiveTracker.create({
			MissionConfig = MissionConfig,
			ItemCatalog = ItemCatalog,
			NetProtocol = NetProtocol,
			KeyItemService = KeyItemService,
			FloorClearanceService = FloorClearanceService,
			DoorAccessService = DoorAccessService,
			clockFn = clockFn,
		})
	end

	-- 1. MissionConfig integrity (M1 FIRST CONTACT implemented; M2-M7 NOT IMPLEMENTED; NO FREE INFORMATION)
	runCase("test_mission_config_m1_to_m7_honesty_and_no_spoilers", function()
		assertEqual(#MissionConfig.ORDER, 7, "Total campaign missions")
		local m1 = MissionConfig.getMission("M1")
		assertTrue(m1 and m1.implemented == true, "M1 must be marked implemented")
		assertEqual(m1.name, "FIRST CONTACT", "M1 canonical name")
		assertEqual(MissionConfig.normalizeMissionId("FIRST_CONTACT"), "M1", "FIRST_CONTACT alias")
		assertEqual(MissionConfig.normalizeMissionId("SECURITY_ACCESS"), "M1", "Legacy SECURITY_ACCESS alias")
		assertEqual(#m1.objectives, 4, "M1 sub-objective count")

		for _, obj in ipairs(m1.objectives) do
			assertTrue(obj.locationHint == nil, "NO FREE INFORMATION: M1 objective must not expose locationHint spoiler")
		end

		for i = 2, 7 do
			local m = MissionConfig.getMission("M" .. i)
			assertTrue(m ~= nil, "M" .. i .. " defined")
			assertEqual(m.implemented, false, m.id .. " implemented flag must stay false")
			assertEqual(m.implementationStatus, "NOT IMPLEMENTED", m.id .. " status")
		end

		local m5 = MissionConfig.getMission("M5")
		assertEqual(#m5.prerequisites, 2, "M5 requires parallel M3 + M4")
	end)

	-- 2. DevAuthService security & environment separation
	runCase("test_dev_auth_public_server_blocked_and_studio_player_isolation", function()
		local fakeConfig = {
			DEV_USER_IDS = { [999] = true },
			ALLOW_DEV_TOOLS_IN_STUDIO = true,
			ALLOW_OFFLINE_STUDIO_PLAYER1_DEV = true,
			ALLOW_DEV_TOOLS_IN_PRIVATE_SERVER = true,
			ALLOW_DEV_TOOLS_IN_PUBLIC_SERVER = false,
		}

		local wsAttrs = {}
		local publicEngine = DevAuthService.createEngine({
			config = fakeConfig,
			env = {
				isStudio = function() return false end,
				getPrivateServerId = function() return "" end,
				getCreatorType = function() return "User" end,
				getCreatorId = function() return 999 end,
				isUserCreatorType = function(t) return t == "User" end,
				setWorkspaceAttribute = function(k, v) wsAttrs[k] = v end,
				syncPlayerAttributes = function() end,
			},
		})
		local creatorPlayer = { UserId = 999, Name = "Creator" }
		local okPublic = publicEngine.setDevModeEnabled(creatorPlayer, true)
		assertEqual(okPublic, false, "Public server must block !dev even for allowlisted creator")
		assertEqual(publicEngine.isDevModeEnabled(creatorPlayer), false, "Public server DevModeActive")

		local syncedAttrs = {}
		local studioEngine = DevAuthService.createEngine({
			config = fakeConfig,
			env = {
				isStudio = function() return true end,
				getPrivateServerId = function() return "" end,
				getCreatorType = function() return "User" end,
				getCreatorId = function() return 0 end,
				isUserCreatorType = function(t) return t == "User" end,
				setWorkspaceAttribute = function(k, v) wsAttrs[k] = v end,
				syncPlayerAttributes = function(p, canTools, devActive, godActive)
					syncedAttrs[p.UserId] = { canTools = canTools, devActive = devActive, godActive = godActive }
				end,
			},
		})
		local p1 = { UserId = -1, Name = "Player1" }
		local p2 = { UserId = -2, Name = "Player2" }
		studioEngine.syncPlayer(p1)
		studioEngine.syncPlayer(p2)
		assertEqual(syncedAttrs[-1].canTools, true, "Studio Player1 allowed")
		assertEqual(syncedAttrs[-1].devActive, false, "Starts in Campaign Mode by default")
		assertEqual(syncedAttrs[-2].canTools, false, "Studio Player2 stays normal player")

		assertEqual(studioEngine.setDevModeEnabled(p2, true), false, "P2 rejected for !dev")
		assertEqual(studioEngine.setGodModeEnabled(p2, true), false, "P2 rejected for !god")

		assertEqual(studioEngine.setGodModeEnabled(p1, true), false, "Godmode blocked before !dev")
		assertEqual(studioEngine.setDevModeEnabled(p1, true), true, "!dev succeeds for P1")
		assertEqual(wsAttrs.EnvironmentMode, "Development", "Workspace flipped to Development")
		assertEqual(studioEngine.setGodModeEnabled(p1, true), true, "!god on succeeds after !dev")
		assertEqual(studioEngine.isGodModeEnabled(p1), true, "GodMode active")

		assertEqual(studioEngine.setDevModeEnabled(p1, false), true, "!dev off succeeds")
		assertEqual(studioEngine.isGodModeEnabled(p1), false, "GodMode auto-cleared on !dev off")
		assertEqual(wsAttrs.EnvironmentMode, "Campaign", "Workspace restored to Campaign")
		assertEqual(studioEngine.isDevSessionTainted(), true, "Session tainted flag retained")
	end)

	-- 3. ObjectiveTracker M1 vertical slice, Phone Feeds, & honesty
	runCase("test_tracker_m1_vertical_slice_and_guards", function()
		local clockNow = 100
		local tracker = createTrackerWithServices(function() return clockNow end)
		tracker.registerPlayer(101, "Alice")
		tracker.registerPlayer(102, "Bob")

		assertEqual(tracker.getMissionState("M1"), "ACTIVE", "M1 starts ACTIVE")
		assertEqual(tracker.getMissionState("M2"), "LOCKED", "M2 starts LOCKED")
		assertEqual(tracker.getObjectiveState("M1", "M1_LOCATE_KEYCARD"), "ACTIVE", "Obj 1 ACTIVE")
		assertEqual(tracker.getObjectiveState("M1", "M1_ENTER_SECURITY_ROOM"), "LOCKED", "Obj 2 LOCKED")

		assertEqual(tracker.unlockSecurityDoor(101, "Alice"), false, "Cannot unlock door before Keycard")
		assertEqual(tracker.canAccessCCTVTerminal(), false, "Cannot open CCTV before Room 102 unlock")
		assertEqual(tracker.activateSecurityControl(101, "Alice"), false, "Cannot activate override before CCTV solve")
		assertEqual(tracker.setMissionById("M2", true), false, "M2 blocked because NOT IMPLEMENTED")

		local okCollect = tracker.collectKeycard(101, "Alice")
		assertTrue(okCollect, "Alice picks up Keycard")
		assertEqual(tracker.getObjectiveState("M1", "M1_LOCATE_KEYCARD"), "COMPLETED", "Obj 1 done")
		assertEqual(tracker.getObjectiveState("M1", "M1_ENTER_SECURITY_ROOM"), "ACTIVE", "Obj 2 activated")
		assertEqual(tracker.collectKeycard(102, "Bob"), false, "Duplicate Keycard pickup blocked")

		local okDoor = tracker.unlockSecurityDoor(102, "Bob")
		assertTrue(okDoor, "Bob uses team keycard on Door 102")
		assertTrue(tracker.isSecurityDoorUnlocked(), "Door state unlocked")
		assertEqual(tracker.getObjectiveState("M1", "M1_SOLVE_CCTV_PUZZLE"), "ACTIVE", "Obj 3 activated")

		assertTrue(tracker.canAccessCCTVTerminal(), "CCTV terminal accessible")
		assertTrue(tracker.completeCCTVPuzzle(101, "Alice"), "CCTV solved")
		assertEqual(tracker.getObjectiveState("M1", "M1_ACTIVATE_SECURITY_CONTROL"), "ACTIVE", "Obj 4 activated")
		assertTrue(tracker.activateSecurityControl(102, "Bob"), "Override activated")

		assertEqual(tracker.getMissionState("M1"), "COMPLETED", "M1 COMPLETED")
		assertEqual(tracker.getMissionState("M2"), "AVAILABLE", "M2 AVAILABLE")
		local snap = tracker.serializeSnapshot("Campaign", true, { viewerUserId = 101 })
		assertEqual(snap.campaignComplete, false, "Campaign does NOT fake complete after M1")
		assertEqual(snap.nextMission.implementationStatus, "NOT IMPLEMENTED", "M2 flagged NOT IMPLEMENTED")
		assertTrue(snap.phone and #snap.phone.notes >= 2, "Phone notes populated")
		assertTrue(snap.phone and #snap.phone.messages >= 3, "Phone messages populated")
		assertTrue((snap.phone.unreadCount or 0) >= 1, "Unread badge tracks unread phone items")
	end)

	-- 4. CCTV Puzzle Server-Only Secret + Cooldown + Tamper Validation
	runCase("test_cctv_puzzle_server_secrecy_and_cooldown", function()
		local now = 50
		local puzzle = CCTVPuzzleEngine.create({
			variantIndex = 1,
			clockFn = function() return now end,
			wrongCooldownSeconds = 4.0,
		})

		local payload = puzzle.getClientModalPayload()
		assertEqual(#payload.frames, 4, "4 sanitized frames sent to client")
		for _, f in ipairs(payload.frames) do
			assertTrue(f.chronologicalIndex == nil, "Answer index must NEVER be in client payload")
		end

		local badLen = puzzle.validateSubmission(101, { "CLIP_PARKING_WEST" })
		assertEqual(badLen.solved, false, "Short payload rejected")
		local dupeFrame = puzzle.validateSubmission(101, { "CLIP_PARKING_WEST", "CLIP_PARKING_WEST", "CLIP_BANK_COUNTER", "CLIP_ROOM102_SEAL" })
		assertEqual(dupeFrame.solved, false, "Duplicate clip IDs rejected")

		local wrongOrder = puzzle.validateSubmission(101, { "CLIP_ROOM102_SEAL", "CLIP_BANK_COUNTER", "CLIP_POWER_CONDUIT", "CLIP_PARKING_WEST" })
		assertEqual(wrongOrder.solved, false, "Wrong sequence fails")
		assertEqual(wrongOrder.cooldownRemaining, 4.0, "Cooldown triggered")

		now = 51.5
		local blockedRetry = puzzle.validateSubmission(101, puzzle.getServerAnswerDebug())
		assertEqual(blockedRetry.ok, false, "Immediate brute-force attempt blocked during cooldown")

		now = 55.0
		local solved = puzzle.validateSubmission(101, puzzle.getServerAnswerDebug())
		assertEqual(solved.solved, true, "Correct chronological sequence verified after cooldown")

		local doubleSolve = puzzle.validateSubmission(102, puzzle.getServerAnswerDebug())
		assertEqual(doubleSolve.ok, false, "Cannot double-solve completed puzzle")
	end)

	-- 5. Co-op Disconnect & Death Recovery, Concurrent Lock, & Dev Reset
	runCase("test_coop_death_disconnect_protection_and_dev_reset", function()
		local t = 10
		local tracker = createTrackerWithServices(function() return t end)
		tracker.registerPlayer(201, "Host")
		tracker.registerPlayer(202, "Wingman")

		assertEqual(tracker.acquireInteractionLock("M1_KEYCARD", 201, 1.0), true, "Host acquires lock")
		assertEqual(tracker.acquireInteractionLock("M1_KEYCARD", 202, 1.0), false, "Concurrent pickup blocked")
		tracker.releaseInteractionLock("M1_KEYCARD", 201)

		assertTrue(tracker.collectKeycard(201, "Host"), "Host collects keycard")
		local holderInfo = tracker.getQuestItemHolder("SecurityKeycard")
		assertTrue(type(holderInfo) == "table" and type(holderInfo.holderName) == "string", "Keycard holder metadata has scalar holderName")

		-- Player death transfers keycard to alive teammate without losing progression
		local deathEvents = tracker.onPlayerDied(201)
		assertTrue(deathEvents and deathEvents[1] and deathEvents[1].newHolder == "Wingman", "Keycard transfers to Wingman on Host death")

		-- Disconnect of last holder respawns keycard back on F1 table cleanly
		local emptyEvents = tracker.removePlayer(202)
		assertTrue(emptyEvents and emptyEvents[1] and emptyEvents[1].respawnWorld == true, "Keycard respawns if last holder leaves")
		assertEqual(tracker.getObjectiveState("M1", "M1_LOCATE_KEYCARD"), "ACTIVE", "Obj 1 reactivates cleanly")

		local devPlayer = { UserId = -1, Name = "Dev1" }
		local okDev = tracker.devCompleteObjective("M1_SOLVE_CCTV_PUZZLE", devPlayer)
		assertTrue(okDev, "Dev skip up to CCTV succeeds")
		assertTrue(tracker.isSecurityDoorUnlocked(), "Door auto-unlocked to prevent softlock")
		assertEqual(tracker.getObjectiveState("M1", "M1_ACTIVATE_SECURITY_CONTROL"), "ACTIVE", "Obj 4 ready")

		tracker.setBuildingPowerOn(true, "[DEV] Power ON")
		assertEqual(tracker.isBuildingPowerOn(), true, "Power toggled ON")

		tracker.resetCampaignToM1("[DEV] Reset")
		assertEqual(tracker.getObjectiveState("M1", "M1_LOCATE_KEYCARD"), "ACTIVE", "Reset restores Obj 1")
		assertEqual(tracker.isSecurityDoorUnlocked(), false, "Reset re-locks Room 102")
		assertEqual(tracker.isBuildingPowerOn(), false, "Reset restores Power blackout")
	end)

	-- 6. KeyItemService + DoorAccessService consume-on-unlock-only & concurrent press guard
	runCase("test_door_access_consume_only_on_unlock_and_concurrent_lock", function()
		local t = 25
		local kis = KeyItemService.create({ ItemCatalog = ItemCatalog, clockFn = function() return t end })
		local fcs = FloorClearanceService.create({ MissionConfig = MissionConfig, keyItemService = kis, clockFn = function() return t end })
		local das = DoorAccessService.create({ keyItemService = kis, floorClearanceService = fcs, clockFn = function() return t end })

		kis.registerPlayer(11, "P1")
		kis.registerPlayer(12, "P2")
		kis.grantItem(11, "P1", "MaintenanceKey", 1)

		das.registerDoor({
			doorId = "POWERED_LOCKER",
			displayName = "Powered Locker",
			requiredKey = "MaintenanceKey",
			consumeKey = true,
			requiresPower = true,
		})
		das.registerDoor({
			doorId = "BOSS_LOCKER",
			displayName = "Boss Vault",
			requiredKey = "MaintenanceKey",
			consumeKey = true,
			requiredBossId = "THE_WARDEN",
		})
		das.registerDoor({
			doorId = "SERVICE_LOCKER",
			displayName = "Service Locker",
			requiredKey = "MaintenanceKey",
			consumeKey = true,
		})

		-- Failed prerequisite (no power / alive boss) must NEVER consume key
		local okFailPwr = das.attemptAccess("POWERED_LOCKER", { userId = 11, playerName = "P1" })
		assertEqual(okFailPwr, false, "Unlock fails without power")
		assertEqual(kis.getTeamItemCount("MaintenanceKey"), 1, "Key NOT consumed on failed power gate")

		local okFailBoss = das.attemptAccess("BOSS_LOCKER", { userId = 11, playerName = "P1" })
		assertEqual(okFailBoss, false, "Unlock fails while boss alive")
		assertEqual(kis.getTeamItemCount("MaintenanceKey"), 1, "Key NOT consumed on failed boss gate")

		-- Valid unlock consumes key ONCE
		local okSuccess, _, meta1 = das.attemptAccess("SERVICE_LOCKER", { userId = 11, playerName = "P1" }, { toggleIfUnlocked = true })
		assertEqual(okSuccess, true, "Service locker unlocks")
		assertEqual(meta1.keyConsumed, true, "Consumable key spent on successful unlock")
		assertEqual(kis.getTeamItemCount("MaintenanceKey"), 0, "Key count decremented once")

		-- Simultaneous / follow-up press by teammate does NOT attempt second consume
		local okToggle, _, meta2 = das.attemptAccess("SERVICE_LOCKER", { userId = 12, playerName = "P2" }, { toggleIfUnlocked = true })
		assertEqual(okToggle, true, "P2 can toggle unlocked door")
		assertEqual(meta2.keyConsumed, false, "Already-unlocked door does not re-consume key")

		-- Explicit simultaneous lock contention check (two players pressing [E] at same tick)
		das.registerDoor({ doorId = "RACE_DOOR", displayName = "Race Door", requiredKey = "MaintenanceKey", consumeKey = true })
		kis.grantItem(11, "P1", "MaintenanceKey", 1)
		assertEqual(kis.acquireLock("DOOR_ACCESS:RACE_DOOR", 11, 2.0), true, "P1 holds door lock")
		local okRace, _, metaRace = das.attemptAccess("RACE_DOOR", { userId = 12, playerName = "P2" })
		assertEqual(okRace, false, "Concurrent P2 press blocked while P1 holds lock")
		assertEqual(metaRace and metaRace.busy, true, "Concurrent press reports busy without consuming key")
		assertEqual(kis.getTeamItemCount("MaintenanceKey"), 1, "Key untouched under lock contention")
		kis.releaseLock("DOOR_ACCESS:RACE_DOOR", 11)
	end)

	-- 7. Parallel M3 (DECODE THE SAFE) & M4 (CONTACT THE OUTSIDE) -> M5 Gate
	runCase("test_parallel_m3_m4_unlock_and_m5_dependency_gate", function()
		local tracker = createTrackerWithServices()
		tracker.completeMissionNode("M1")
		assertEqual(tracker.getMissionState("M2"), "AVAILABLE", "M2 AVAILABLE after M1")

		tracker.completeMissionNode("M2")
		assertEqual(tracker.getMissionState("M3"), "AVAILABLE", "M3 AVAILABLE simultaneously after M2")
		assertEqual(tracker.getMissionState("M4"), "AVAILABLE", "M4 AVAILABLE simultaneously after M2")
		assertEqual(tracker.getMissionState("M5"), "LOCKED", "M5 still LOCKED")

		assertEqual(tracker.activateMission("M3", { allowUnimplemented = true }), true, "M3 started")
		assertEqual(tracker.activateMission("M4", { allowUnimplemented = true }), true, "M4 started alongside M3")
		assertEqual(#tracker.getActiveMissionIds(), 2, "Both M3 and M4 ACTIVE concurrently")

		-- Complete M4 out-of-order first; M5 must stay LOCKED until M3 finishes too
		tracker.completeMissionNode("M4")
		assertEqual(tracker.getMissionState("M4"), "COMPLETED", "M4 COMPLETED")
		assertEqual(tracker.getMissionState("M5"), "LOCKED", "M5 stays LOCKED while M3 incomplete")

		tracker.completeMissionNode("M3")
		assertEqual(tracker.getMissionState("M3"), "COMPLETED", "M3 COMPLETED")
		assertEqual(tracker.getMissionState("M5"), "AVAILABLE", "M5 unlocks ONLY after both M3 and M4 finish")
	end)

	-- 8. FloorClearanceService & Elevator tier + power + incapacitated checks
	runCase("test_floor_clearance_and_elevator_gates", function()
		local kis = KeyItemService.create({ ItemCatalog = ItemCatalog })
		local fcs = FloorClearanceService.create({ MissionConfig = MissionConfig, keyItemService = kis })
		kis.registerPlayer(1, "S1")

		local okOff = fcs.canUseElevator({ userId = 1 }, 1, 2)
		assertEqual(okOff, false, "Elevator blocked while Building Power OFF")

		fcs.setPowerOn(true)
		local okNoTier = fcs.canUseElevator({ userId = 1 }, 1, 2)
		assertEqual(okNoTier, false, "Floor 2 blocked at Tier 0")

		kis.grantItem(1, "S1", "SecurityKeycard", 1)
		assertEqual(fcs.getEffectiveTier(), 1, "SecurityKeycard grants Tier 1")
		assertEqual(fcs.canUseElevator({ userId = 1 }, 1, 2), true, "Floor 2 allowed at Tier 1")
		assertEqual(fcs.canUseElevator({ userId = 1 }, 1, 11), false, "Floor 11 denied at Tier 1")

		kis.grantItem(1, "S1", "QuarantineKeycard", 1)
		assertEqual(fcs.getEffectiveTier(), 3, "QuarantineKeycard grants Tier 3")
		assertEqual(fcs.canUseElevator({ userId = 1 }, 1, 11), true, "Floor 11 allowed at Tier 3")
		assertEqual(fcs.canUseElevator({ userId = 1 }, 11, 12), false, "Floor 12 denied at Tier 3")

		assertEqual(fcs.canUseElevator({ userId = 1, isDowned = true }, 1, 2), false, "Downed player blocked from elevator")
		assertEqual(fcs.canUseElevator({ userId = 1, devBypass = true }, 11, 12), true, "Dev bypass grants F12 ride")
	end)

	-- 9. Dual-Mode ZombieDirector: Campaign vs Wave Isolation, Caps, Distance, Anti-Overlap, LOS
	runCase("test_zombie_director_dual_mode_caps_and_los_guards", function()
		local now = 100
		local dir = ZombieDirector.create({
			clockFn = function() return now end,
			maxAliveCampaign = 6,
			ambientCap = 3,
			noiseThreshold = 30,
			noiseSpawnCooldown = 10,
			hasLineOfSightFn = function(eyePos, spawnPos)
				-- Point at x=60,z=0 is obstructed by wall; x=45,z=0 is direct visible LOS
				local sx = spawnPos.X or spawnPos.x
				return sx < 55
			end,
		})

		assertEqual(dir.getMode(), "Campaign", "Starts in Campaign Mode by default")

		-- Cap enforcement
		dir.registerSpawned("A1", { channel = "Ambient", mode = "Campaign" })
		dir.registerSpawned("A2", { channel = "Ambient", mode = "Campaign" })
		dir.registerSpawned("A3", { channel = "Ambient", mode = "Campaign" })
		assertEqual(dir.getRemainingCapacity("Ambient"), 0, "Ambient cap enforced at 3")

		-- Distance, anti-overlap & LOS spawn point checks
		local playerViews = {
			{ pos = { x = 0, y = 0, z = 0 }, eyePos = { x = 0, y = 2, z = 0 }, lookVector = { x = 1, y = 0, z = 0 } },
		}
		local existingZ = { { x = 62, y = 0, z = 0 } }
		local okClose, rClose = dir.evaluateSpawnPoint({ x = 10, y = 0, z = 0 }, playerViews, existingZ)
		assertEqual(okClose, false, "Rejects close spawn <24 studs")
		assertEqual(rClose, "too_close_to_player", "Too close reason")

		local okVis, rVis = dir.evaluateSpawnPoint({ x = 45, y = 0, z = 0 }, playerViews, existingZ)
		assertEqual(okVis, false, "Rejects spawn directly in front of player clear LOS")
		assertEqual(rVis, "visible_to_player", "Visible reason")

		local okOverlap, rOverlap = dir.evaluateSpawnPoint({ x = 61, y = 0, z = 0 }, playerViews, existingZ)
		assertEqual(okOverlap, false, "Rejects zombie anti-overlap <4.5 studs")
		assertEqual(rOverlap, "overlaps_existing_zombie", "Overlap reason")

		local okHidden = dir.evaluateSpawnPoint({ x = 75, y = 0, z = 0 }, playerViews, existingZ)
		assertEqual(okHidden, true, "Allows safe out-of-sight spawn point")

		-- Noise heat & cooldown
		local lowNoise = dir.recordNoise({ x = 0, y = 0, z = 0 }, 10, "Ghost")
		assertEqual(lowNoise.triggered, false, "Suppressed pistol below noise threshold")
		local loudNoise = dir.recordNoise({ x = 0, y = 0, z = 0 }, 35, "Vandal")
		assertEqual(loudNoise.triggered, true, "Rifle noise crosses threshold and spawns")
		local immediateSecond = dir.recordNoise({ x = 0, y = 0, z = 0 }, 40, "Vandal")
		assertEqual(immediateSecond.triggered, false, "Noise spawn cooldown prevents instant spam")

		-- Wave mode isolation & Campaign cleanup
		assertEqual(dir.setMode("Wave"), true, "Switch to Wave Mode")
		assertEqual(dir.getWaveState().waveNumber, 1, "Wave resets to 1")
		dir.resetAll("Campaign")
		assertEqual(dir.getMode(), "Campaign", "Reset back to Campaign Mode")
		assertEqual(dir.getWaveState().active, false, "Wave loop inactive in Campaign Mode")
		assertEqual(dir.getAliveCount(nil, nil), 0, "Reset clears zombie registry")
	end)

	return results
end

return MissionLogicTests
