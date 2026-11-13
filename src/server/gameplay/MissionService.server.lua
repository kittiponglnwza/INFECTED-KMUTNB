--[[
    MissionService.server.lua
    Server-authoritative Campaign Mission Service for INFECTED-KMUTNB.
    - Phase 1: M1 (FIRST CONTACT) playable vertical slice + M2-M7 structural graph (M3/M4 parallel)
    - Integrates KeyItemService, DoorAccessService, FloorClearanceService, ObjectiveTracker, CCTVPuzzleEngine
    - Wires ReplicatedStorage.MissionEvents (including PhoneAction) + ServerStorage.MissionSignals & CampaignSignals
    - Supports 2-4 Co-op shared progress, late-join sync, and Death/Disconnect Keycard & Key recovery
]]

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local NetProtocol = require(sharedFolder:WaitForChild("NetProtocol"))
local ItemCatalog = require(sharedFolder:WaitForChild("ItemCatalog"))
local MissionConfig = require(sharedFolder:WaitForChild("MissionConfig"))

local campaignFolder = ServerScriptService:WaitForChild("Campaign", 10)
local DevAuthService = require(campaignFolder:WaitForChild("DevAuthService"))
local KeyItemService = require(campaignFolder:WaitForChild("KeyItemService"))
local FloorClearanceService = require(campaignFolder:WaitForChild("FloorClearanceService"))
local DoorAccessService = require(campaignFolder:WaitForChild("DoorAccessService"))
local ObjectiveTracker = require(campaignFolder:WaitForChild("ObjectiveTracker"))
local CCTVPuzzleEngine = require(campaignFolder:WaitForChild("CCTVPuzzleEngine"))
local MissionWorldInteractables = require(campaignFolder:WaitForChild("MissionWorldInteractables"))

local mapFolder = ServerScriptService:WaitForChild("Map", 10)
local LightingSetup = require(mapFolder:WaitForChild("LightingSetup"))
local WallBuysSetup = require(mapFolder:WaitForChild("modules"):WaitForChild("WallBuysSetup"))

local devAuth = DevAuthService.getSingleton()
local puzzleEngine = CCTVPuzzleEngine.create()
local tracker = ObjectiveTracker.create({
	MissionConfig = MissionConfig,
	ItemCatalog = ItemCatalog,
	NetProtocol = NetProtocol,
	KeyItemService = KeyItemService,
	FloorClearanceService = FloorClearanceService,
	DoorAccessService = DoorAccessService,
})

local services = tracker.getServices()
local keyItemService = services.keyItemService
local floorClearanceService = services.floorClearanceService
local doorAccessService = services.doorAccessService

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if f then
		return f
	end
	f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function ensureChild(folder, className, name)
	local existing = folder:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = folder
	return created
end

-- Remotes setup (idempotent)
local eventsFolder = ensureFolder(ReplicatedStorage, NetProtocol.Remotes.MissionEventsFolder)
local stateChangedEvent = ensureChild(eventsFolder, "RemoteEvent", NetProtocol.Remotes.StateChanged)
local stateRequestEvent = ensureChild(eventsFolder, "RemoteEvent", NetProtocol.Remotes.StateRequest)
local openPuzzleModalEvent = ensureChild(eventsFolder, "RemoteEvent", NetProtocol.Remotes.OpenPuzzleModal)
local submitPuzzleSolutionFn = ensureChild(eventsFolder, "RemoteFunction", NetProtocol.Remotes.SubmitPuzzleSolution)
local phoneActionFn = ensureChild(eventsFolder, "RemoteFunction", NetProtocol.Remotes.PhoneAction)
local devFeedbackEvent = ensureChild(eventsFolder, "RemoteEvent", NetProtocol.Remotes.DevFeedback)
local openBankSafeKeypadEvent = ensureChild(eventsFolder, "RemoteEvent", NetProtocol.Remotes.OpenBankSafeKeypad)
local submitBankSafeCodeFn = ensureChild(eventsFolder, "RemoteFunction", NetProtocol.Remotes.SubmitBankSafeCode)
local showEmergencyMemoEvent = ensureChild(eventsFolder, "RemoteEvent", NetProtocol.Remotes.ShowEmergencyMemo)

-- Server Signals: MissionSignals + CampaignSignals
local missionSignalsFolder = ensureFolder(ServerStorage, NetProtocol.Signals.MissionSignalsFolder)
local completeObjectiveSignal = ensureChild(missionSignalsFolder, "BindableEvent", NetProtocol.Signals.CompleteObjective)
local setMissionFn = ensureChild(missionSignalsFolder, "BindableFunction", NetProtocol.Signals.SetMission)
local resetMissionFn = ensureChild(missionSignalsFolder, "BindableFunction", NetProtocol.Signals.ResetMission)
local getStatusFn = ensureChild(missionSignalsFolder, "BindableFunction", "GetMissionStatus")
local devCompleteObjectiveFn = ensureChild(missionSignalsFolder, "BindableFunction", "DevCompleteObjective")
local grantQuestItemFn = ensureChild(missionSignalsFolder, "BindableFunction", NetProtocol.Signals.GrantQuestItem)
local setBuildingPowerFn = ensureChild(missionSignalsFolder, "BindableFunction", NetProtocol.Signals.SetBuildingPower)

local campaignSignalsFolder = ensureFolder(ServerStorage, NetProtocol.Signals.CampaignSignalsFolder)
local requestDoorAccessFn = ensureChild(campaignSignalsFolder, "BindableFunction", NetProtocol.Signals.RequestDoorAccess)
local requestElevatorRideFn = ensureChild(campaignSignalsFolder, "BindableFunction", NetProtocol.Signals.RequestElevatorRide)
local grantClearanceFn = ensureChild(campaignSignalsFolder, "BindableFunction", NetProtocol.Signals.GrantClearance)
local setBossDefeatedFn = ensureChild(campaignSignalsFolder, "BindableFunction", NetProtocol.Signals.SetBossDefeated)
local unlockDoorFn = ensureChild(campaignSignalsFolder, "BindableFunction", NetProtocol.Signals.UnlockDoor)
local lockDoorFn = ensureChild(campaignSignalsFolder, "BindableFunction", NetProtocol.Signals.LockDoor)
local consumeQuestItemFn = ensureChild(campaignSignalsFolder, "BindableFunction", NetProtocol.Signals.ConsumeQuestItem)
local phoneCommandFn = ensureChild(campaignSignalsFolder, "BindableFunction", "DevDoorCommand")

local worldController = nil

local function getCurrentEnvironmentMode()
	return devAuth.hasAnyActiveDevMode() and NetProtocol.EnvironmentMode.Development or NetProtocol.EnvironmentMode.Campaign
end

local function isPlayerDownedOrDead(player)
	if not player or player.Parent ~= Players then
		return true
	end
	if player:GetAttribute("IsDowned") == true then
		return true
	end
	local char = player.Character
	if not char or char:GetAttribute("IsDowned") == true then
		return true
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
		return true
	end
	return false
end

local function readZombieDirectorStats()
	local zFolder = ServerStorage:FindFirstChild(NetProtocol.Signals.ZombieSignalsFolder)
	local getStatsFn = zFolder and zFolder:FindFirstChild(NetProtocol.Signals.GetZombieStats)
	if getStatsFn and getStatsFn:IsA("BindableFunction") then
		local ok, stats = pcall(function()
			return getStatsFn:Invoke()
		end)
		if ok and type(stats) == "table" then
			return stats
		end
	end
	return nil
end

local function buildPlayerContext(player)
	local isDowned = player:GetAttribute("IsDowned") == true
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local isDead = (not hum) or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead
	return {
		userId = player.UserId,
		playerName = player.Name,
		isDowned = isDowned or (char and char:GetAttribute("IsDowned") == true) or false,
		isDead = isDead,
		devBypass = devAuth.isDevModeEnabled(player) and (player:GetAttribute(NetProtocol.Attributes.DevBypassLocks) == true),
	}
end

local function notifyPlayer(player, ok, msg)
	if player and player.Parent == Players then
		devFeedbackEvent:FireClient(player, ok, tostring(msg))
	end
end

-- Room 102 Server-Authoritative Hold-Out, UPS, Monitor Wall & Alarm State
local r102Cfg = MissionConfig.ROOM102 or {}
local ROOM102_CENTER_TARGET = Vector3.new(-109, 4.5, 70)
local ROOM102_PERIMETER_SPAWNS = {
	Vector3.new(-126, 4.0, 38),
	Vector3.new(-86, 4.0, 38),
	Vector3.new(-62, 4.0, 74),
	Vector3.new(-109, 4.0, 126),
	Vector3.new(-109, 4.0, 38),
}
local M2_POWER_ROOM_POS = Vector3.new(-22, 23, 76)

local monitorSequence = {}
local alarmUntil = 0
local alarmToken = 0
local holdoutGen = 0
local holdoutState = {
	active = false,
	total = tonumber(r102Cfg.OVERRIDE_HOLDOUT_SECONDS) or 75,
	remaining = 0,
	progress = 0,
}
local room102UPSPercent = tonumber(r102Cfg.UPS_INITIAL_PERCENT) or 34
local cctvIntelRevealed = false
local cctvIntelText = "ทางขึ้นดาดฟ้า: เข้ารหัสอยู่ — เรียง CCTV เพื่อสแกนฝูงซอมบี้"

local function getRoom102StateTable()
	return {
		upsPercent = room102UPSPercent,
		monitorSequence = monitorSequence,
		alarmActive = (os.clock() < alarmUntil),
		alarmUntil = alarmUntil,
		holdoutActive = holdoutState.active,
		holdoutRemaining = holdoutState.remaining,
		holdoutTotal = holdoutState.total,
		cctvIntelRevealed = cctvIntelRevealed,
		intelText = cctvIntelText,
	}
end

local function syncRoom102WorkspaceAttributes()
	local r102 = getRoom102StateTable()
	Workspace:SetAttribute(NetProtocol.Attributes.Room102UPSPercent, r102.upsPercent)
	Workspace:SetAttribute(NetProtocol.Attributes.Room102MonitorSequence, table.concat(monitorSequence, ","))
	Workspace:SetAttribute(NetProtocol.Attributes.Room102AlarmActive, r102.alarmActive)
	Workspace:SetAttribute(NetProtocol.Attributes.Room102AlarmUntil, r102.alarmUntil)
	Workspace:SetAttribute(NetProtocol.Attributes.Room102HoldoutActive, r102.holdoutActive)
	Workspace:SetAttribute(NetProtocol.Attributes.Room102HoldoutRemaining, r102.holdoutRemaining)
	Workspace:SetAttribute(NetProtocol.Attributes.Room102HoldoutTotal, r102.holdoutTotal)
	Workspace:SetAttribute(NetProtocol.Attributes.Room102CCTVIntelRevealed, r102.cctvIntelRevealed)
	Workspace:SetAttribute(NetProtocol.Attributes.Room102IntelText, r102.intelText)
end

local function resetRoom102Barricades()
	for _, bar in ipairs(CollectionService:GetTagged("BreakableBarricade")) do
		local resetFn = bar:FindFirstChild("ResetBarricade")
		if resetFn and resetFn:IsA("BindableFunction") then
			pcall(function()
				resetFn:Invoke()
			end)
		end
	end
end

local function resetRoom102Runtime()
	holdoutGen += 1
	monitorSequence = {}
	alarmToken += 1
	alarmUntil = 0
	holdoutState.active = false
	holdoutState.remaining = 0
	holdoutState.progress = 0
	room102UPSPercent = tonumber(r102Cfg.UPS_INITIAL_PERCENT) or 34
	cctvIntelRevealed = false
	cctvIntelText = "ทางขึ้นดาดฟ้า: เข้ารหัสอยู่ — เรียง CCTV เพื่อสแกนฝูงซอมบี้"
	resetRoom102Barricades()
	syncRoom102WorkspaceAttributes()
end

local function playRoom102AlarmPulse(durationSec)
	local m1Root = Workspace:FindFirstChild("MissionM1_Interactables")
	local wallModel = m1Root and m1Root:FindFirstChild("M1_MonitorWall")
	local host = (wallModel and wallModel:FindFirstChild("MonitorWallBacking")) or Workspace
	task.spawn(function()
		local endsAt = os.clock() + math.min(durationSec or 6, 8)
		local myTok = alarmToken
		while os.clock() < endsAt and alarmToken == myTok do
			local s = Instance.new("Sound")
			s.SoundId = "rbxasset://sounds/volume_slider.ogg"
			s.Volume = 0.65
			s.PlaybackSpeed = 1.45
			s.RollOffMaxDistance = 85
			s.Parent = host
			s:Play()
			game:GetService("Debris"):AddItem(s, 1.0)
			task.wait(0.85)
		end
	end)
end

local function spawnRoom102Wave(encounterId, requestedCount)
	local zFolder = ServerStorage:FindFirstChild("ZombieSignals")
	local triggerFn = zFolder and zFolder:FindFirstChild("TriggerEncounter")
	if triggerFn and triggerFn:IsA("BindableFunction") then
		pcall(function()
			triggerFn:Invoke(encounterId, requestedCount, 1, {
				spawnPositions = ROOM102_PERIMETER_SPAWNS,
				targetPos = ROOM102_CENTER_TARGET,
				ignoreCap = true,
			})
		end)
	end
end

local function broadcastNoticeToAll(ok, msg)
	for _, p in ipairs(Players:GetPlayers()) do
		notifyPlayer(p, ok, msg)
	end
end

local function syncWorkspaceAttributes(snapshot)
	local clampedIndex = math.min((snapshot.completedSubCount or 0) + 1, math.max(1, snapshot.totalSubCount or 1))
	Workspace:SetAttribute(NetProtocol.Attributes.ActiveMissionId, snapshot.missionId)
	Workspace:SetAttribute(NetProtocol.Attributes.ActiveObjectiveIndex, clampedIndex)
	Workspace:SetAttribute(NetProtocol.Attributes.ActiveObjectiveLabel, snapshot.activeObjectiveTitle)
	Workspace:SetAttribute(NetProtocol.Attributes.SecurityRoomUnlocked, snapshot.securityDoorUnlocked)
	Workspace:SetAttribute(NetProtocol.Attributes.BuildingPowerOn, snapshot.buildingPowerOn)
	Workspace:SetAttribute(NetProtocol.Attributes.FloorClearanceTier, snapshot.floorClearanceTier or 0)
	Workspace:SetAttribute(NetProtocol.Attributes.CampaignComplete, snapshot.campaignComplete == true)
	local m1Done = (snapshot.missionStates and snapshot.missionStates.M1 == NetProtocol.MissionState.COMPLETED)
	Workspace:SetAttribute(NetProtocol.Attributes.M1SecurityOverrideDone, m1Done)
	Workspace:SetAttribute(NetProtocol.Attributes.M2PowerRoomReached, tracker.getObjectiveState("M2", "M2_REACH_POWER_ROOM") == NetProtocol.MissionState.COMPLETED)

	local holderInfo = tracker.getQuestItemHolder("SecurityKeycard")
	local holderName = (type(holderInfo) == "table" and type(holderInfo.holderName) == "string" and holderInfo.holderName)
		or (type(holderInfo) == "string" and holderInfo)
		or ""
	Workspace:SetAttribute(NetProtocol.Attributes.QuestKeycardHolder, holderName)

	local okJson, encoded = pcall(function()
		return HttpService:JSONEncode(snapshot.phone and snapshot.phone.inventory or {})
	end)
	if okJson then
		Workspace:SetAttribute(NetProtocol.Attributes.QuestInventoryJson, encoded)
	end

	Workspace:SetAttribute("MissionCurrentIndex", snapshot.currentIndex)
	Workspace:SetAttribute("MissionTotalCount", snapshot.totalCount)
	Workspace:SetAttribute("MissionCompletedCount", snapshot.completedCount)
	syncRoom102WorkspaceAttributes()
	pcall(WallBuysSetup.syncTierVisuals, Workspace, snapshot.floorClearanceTier or 0, m1Done)
end

local function buildSnapshotFor(viewerUserId)
	local zStats = readZombieDirectorStats()
	local zMode = (zStats and zStats.mode)
		or Workspace:GetAttribute(NetProtocol.Attributes.ZombieMode)
		or NetProtocol.ZombieMode.Campaign
	return tracker.serializeSnapshot(getCurrentEnvironmentMode(), puzzleEngine.isSolved(), {
		viewerUserId = viewerUserId,
		zombieMode = zMode,
		zombieStats = zStats,
		room102State = getRoom102StateTable(),
	})
end

local function sendSnapshotToPlayer(player)
	if not player or player.Parent ~= Players then
		return
	end
	local snapshot = buildSnapshotFor(player.UserId)
	local unread = (snapshot.phone and snapshot.phone.unreadCount) or 0
	player:SetAttribute(NetProtocol.Attributes.UnreadPhoneCount, unread)
	stateChangedEvent:FireClient(player, snapshot)
end

local function broadcastState()
	local masterSnapshot = buildSnapshotFor(nil)
	syncWorkspaceAttributes(masterSnapshot)
	for _, p in ipairs(Players:GetPlayers()) do
		sendSnapshotToPlayer(p)
	end
	if worldController then
		worldController.syncWorldState(false)
	end
	return masterSnapshot
end

-- Player join, alive/death tracking, & disconnect Co-op recovery
local function hookPlayerLifecycle(player)
	tracker.registerPlayer(player.UserId, player.Name)
	devAuth.syncPlayer(player)

	local function onCharacterAdded(character)
		tracker.setPlayerAliveState(player.UserId, true, player:GetAttribute("IsDowned") == true)
		local hum = character:WaitForChild("Humanoid", 10)
		if hum then
			hum.Died:Connect(function()
				tracker.setPlayerAliveState(player.UserId, false, false)
				local events = tracker.onPlayerDied(player.UserId)
				if events and #events > 0 then
					broadcastState()
				end
			end)
		end
	end

	player:GetAttributeChangedSignal("IsDowned"):Connect(function()
		local dead = isPlayerDownedOrDead(player)
		tracker.setPlayerAliveState(player.UserId, not dead, player:GetAttribute("IsDowned") == true)
	end)

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	hookPlayerLifecycle(p)
end

Players.PlayerAdded:Connect(function(player)
	hookPlayerLifecycle(player)
	broadcastState()
end)

Players.PlayerRemoving:Connect(function(player)
	local result = tracker.removePlayer(player.UserId)
	if result and #result > 0 then
		if worldController then
			worldController.syncWorldState(false)
		end
	end
	broadcastState()
end)

stateRequestEvent.OnServerEvent:Connect(function(player)
	sendSnapshotToPlayer(player)
end)

-- Staff Phone RemoteFunction: mark read & refresh
phoneActionFn.OnServerInvoke = function(player, action, payload)
	if not player or player.Parent ~= Players then
		return { ok = false }
	end
	if action == "MarkRead" and type(payload) == "table" then
		tracker.markPhoneEntryRead(player.UserId, tostring(payload.kind), tostring(payload.id))
		sendSnapshotToPlayer(player)
		return { ok = true }
	elseif action == "Refresh" then
		local snap = buildSnapshotFor(player.UserId)
		return { ok = true, snapshot = snap }
	end
	return { ok = false, message = "Unknown phone action" }
end

-- Client CCTV Timeline Solution Submission (Server-Authoritative Validation)
local function triggerCCTVWrongPenalty(actorPlayer, reasonMsg)
	local alarmSecs = tonumber(r102Cfg.WRONG_CCTV_ALARM_SECONDS) or 8
	local penaltyZombies = tonumber(r102Cfg.WRONG_CCTV_PENALTY_ZOMBIES) or 4
	alarmToken += 1
	local myToken = alarmToken
	alarmUntil = os.clock() + alarmSecs
	monitorSequence = {}
	syncRoom102WorkspaceAttributes()

	if worldController and worldController.triggerAlarmVisual then
		worldController.triggerAlarmVisual(alarmSecs)
	end
	playRoom102AlarmPulse(alarmSecs)
	spawnRoom102Wave("R102_ALARM_PENALTY", penaltyZombies)

	local errNotice = reasonMsg or "ลำดับกล้อง CCTV ไม่ถูกต้อง! สัญญาณเตือนภัยดังขึ้นและซอมบี้กำลังบุก!"
	tracker.setCustomNotice(errNotice)
	broadcastNoticeToAll(false, errNotice)
	broadcastState()

	task.delay(alarmSecs, function()
		if alarmToken == myToken then
			alarmUntil = 0
			syncRoom102WorkspaceAttributes()
		end
	end)
end

local function handleCCTVSolved(actorPlayer)
	local uid = actorPlayer and actorPlayer.UserId or 0
	local uname = actorPlayer and actorPlayer.Name or "Survivor"
	tracker.completeCCTVPuzzle(uid, uname)
	monitorSequence = {}
	alarmToken += 1
	alarmUntil = 0
	cctvIntelRevealed = true
	cctvIntelText = "ตรวจพบฝูงซอมบี้หนาแน่นที่บันไดชั้น 4-6 และชั้น 11 — รีบอัปโหลด Override ปลดล็อก Tier 1!"
	if tracker.addPhoneNote then
		tracker.addPhoneNote({
			id = "NOTE_M1_CCTV_ROOF_INTEL",
			title = "ข้อมูลกล้องวงจรปิด: ตำแหน่งฝูงซอมบี้ทางขึ้นดาดฟ้า",
			category = "ข้อมูลยุทธวิธี",
			missionId = "M1",
			floor = 1,
			discoveredBy = uname,
			body = "กล้องจับภาพฝูงซอมบี้ปิดกั้นทางขึ้นบันไดชั้น 4-6 และชั้น 11 พบสัญญาณไฟฉุกเฉินจากกลุ่มผู้รอดชีวิตบนลานดาดฟ้าชั้น 12",
		})
	end
	if worldController and worldController.playMonitorWallSolvedSequence then
		worldController.playMonitorWallSolvedSequence()
	end
	broadcastNoticeToAll(true, "เรียงลำดับ CCTV ถูกต้อง! เปิดข้อมูลเส้นทางดาดฟ้าและปลดล็อกแท่น Override แล้ว")
	broadcastState()
end

local function applyPuzzleSubmissionResult(player, result)
	if result.solved then
		handleCCTVSolved(player)
	elseif result.ok then
		triggerCCTVWrongPenalty(player, result.message)
	else
		notifyPlayer(player, false, result.message)
	end
end

local function handleMonitorWallSelect(player, clipId)
	local canAccess, err = tracker.canAccessCCTVTerminal()
	if not canAccess then
		notifyPlayer(player, false, err)
		return
	end
	if puzzleEngine.isSolved() then
		notifyPlayer(player, true, "ไทม์ไลน์ CCTV ถูกยืนยันแล้ว — ไปที่แท่น Override ด้านขวาเพื่อเริ่มอัปโหลด")
		return
	end
	if os.clock() < alarmUntil then
		notifyPlayer(player, false, string.format("สัญญาณเตือนภัยยังดังอยู่! ป้องกันห้อง 102 ก่อน (%d วิ)", math.ceil(alarmUntil - os.clock())))
		return
	end
	if clipId == "__RESET__" then
		monitorSequence = {}
		syncRoom102WorkspaceAttributes()
		if worldController then worldController.syncWorldState(false) end
		notifyPlayer(player, true, "ล้างลำดับกล้อง CCTV ที่เลือกไว้แล้ว")
		return
	end
	local okLock, lockErr = tracker.acquireInteractionLock("M1_MONITOR_WALL", player.UserId, 0.35)
	if not okLock then
		notifyPlayer(player, false, lockErr)
		return
	end

	-- กดซ้ำที่จอเดิมเพื่อยกเลิกตัวเลือก หรือเลือกเรียงให้ครบ 4 จอ
	local existingIdx = table.find(monitorSequence, clipId)
	if existingIdx then
		table.remove(monitorSequence, existingIdx)
		tracker.releaseInteractionLock("M1_MONITOR_WALL", player.UserId)
		syncRoom102WorkspaceAttributes()
		if worldController then worldController.syncWorldState(false) end
		notifyPlayer(player, true, string.format("ยกเลิกการเลือกกล้องดังกล่าวแล้ว (เลือกไว้ %d/4)", #monitorSequence))
		return
	end

	table.insert(monitorSequence, clipId)
	syncRoom102WorkspaceAttributes()
	if worldController then worldController.syncWorldState(false) end

	if #monitorSequence < 4 then
		notifyPlayer(player, true, string.format("เลือกกล้อง %s เป็นลำดับที่ #%d (ครบ 4 จอแล้วระบบจะตรวจอัตโนมัติ)", tostring(clipId), #monitorSequence))
		tracker.releaseInteractionLock("M1_MONITOR_WALL", player.UserId)
		return
	end

	local submitted = table.clone(monitorSequence)
	local result = puzzleEngine.validateSubmission(player.UserId, submitted)
	tracker.releaseInteractionLock("M1_MONITOR_WALL", player.UserId)
	applyPuzzleSubmissionResult(player, result)
end

local function startOverrideHoldout(player)
	if holdoutState.active then
		notifyPlayer(player, false, "กำลังอัปโหลด Override อยู่แล้ว — ป้องกันห้อง 102 จนกว่าจะครบเวลา!")
		return
	end
	if tracker.getMissionState("M1") == NetProtocol.MissionState.COMPLETED then
		notifyPlayer(player, true, "ภารกิจห้องควบคุม 102 เสร็จสมบูรณ์แล้ว")
		return
	end
	local canAccess, err = tracker.canActivateSecurityControl()
	if not canAccess then
		notifyPlayer(player, false, err)
		return
	end
	if not puzzleEngine.isSolved() then
		notifyPlayer(player, false, "กรุณาเรียงลำดับกล้อง CAM-01..04 ให้ถูกต้องก่อนเริ่มอัปโหลด Override")
		return
	end

	local okLock, lockErr = tracker.acquireInteractionLock("M1_OVERRIDE", player.UserId, 1.0)
	if not okLock then
		notifyPlayer(player, false, lockErr)
		return
	end

	holdoutGen += 1
	local myGen = holdoutGen
	local totalSecs = math.clamp(tonumber(r102Cfg.OVERRIDE_HOLDOUT_SECONDS) or 75, 60, 90)
	local waveInterval = tonumber(r102Cfg.HOLDOUT_WAVE_INTERVAL_SECONDS) or 12
	local perWave = tonumber(r102Cfg.HOLDOUT_ZOMBIES_PER_WAVE) or 4
	local startUPS = tonumber(r102Cfg.UPS_INITIAL_PERCENT) or 34
	local minUPS = tonumber(r102Cfg.UPS_MIN_PERCENT) or 8

	holdoutState.active = true
	holdoutState.total = totalSecs
	holdoutState.remaining = totalSecs
	holdoutState.progress = 0

	tracker.setCustomNotice(string.format("เริ่มอัปโหลด Security Override (%d วิ) — ป้องกันประตูและหน้าต่างห้อง 102!", totalSecs))
	syncRoom102WorkspaceAttributes()
	if worldController then worldController.setHoldoutInfo(holdoutState) end
	broadcastNoticeToAll(true, string.format("%s เริ่มอัปโหลด Override (%d วินาที)! ซ่อม Barricade และต้านซอมบี้ไว้!", player.Name, totalSecs))
	broadcastState()
	tracker.releaseInteractionLock("M1_OVERRIDE", player.UserId)

	task.spawn(function()
		local elapsed = 0
		local nextWaveAt = 0
		while elapsed < totalSecs and holdoutGen == myGen and holdoutState.active do
			-- ตรวจกรณีผู้เล่นทุกคนล้มลงหมดระหว่าง Hold-Out เพื่อรีเซ็ตป้องกัน soft-lock
			local players = Players:GetPlayers()
			if #players > 0 then
				local anyAlive = false
				for _, p in ipairs(players) do
					if not isPlayerDownedOrDead(p) then
						anyAlive = true
						break
					end
				end
				if not anyAlive then
					holdoutState.active = false
					holdoutState.remaining = 0
					holdoutState.progress = 0
					room102UPSPercent = startUPS
					tracker.setCustomNotice("ทีมล้มหมดระหว่างอัปโหลด — การอัปโหลด Override ถูกยกเลิก! กดเริ่มใหม่เมื่อพร้อม")
					syncRoom102WorkspaceAttributes()
					if worldController then worldController.setHoldoutInfo(nil) end
					broadcastNoticeToAll(false, "ทีมล้มลงหมด! การอัปโหลด Override ถูกยกเลิกชั่วคราว")
					broadcastState()
					return
				end
			end

			if elapsed >= nextWaveAt then
				local zStats = readZombieDirectorStats()
				local aliveNow = zStats and tonumber(zStats.aliveCount) or 0
				if aliveNow < 16 then
					spawnRoom102Wave("R102_HOLDOUT_WAVE", perWave)
				end
				nextWaveAt = elapsed + waveInterval
			end

			local frac = math.clamp(elapsed / totalSecs, 0, 1)
			holdoutState.remaining = math.max(0, totalSecs - elapsed)
			holdoutState.progress = frac
			room102UPSPercent = math.max(minUPS, math.floor(startUPS - (startUPS - minUPS) * frac + 0.5))

			syncRoom102WorkspaceAttributes()
			if worldController then
				worldController.setHoldoutInfo(holdoutState)
			end
			if elapsed > 0 and elapsed % 5 == 0 then
				broadcastState()
			end

			task.wait(1)
			elapsed += 1
		end

		if holdoutGen ~= myGen or not holdoutState.active then
			return
		end

		holdoutState.active = false
		holdoutState.remaining = 0
		holdoutState.progress = 1
		room102UPSPercent = minUPS

		local okDone, msgDone = tracker.activateSecurityControl(player and player.UserId or 0, player and player.Name or "Survivor")
		syncRoom102WorkspaceAttributes()
		if worldController then
			worldController.setHoldoutInfo(nil)
		end
		if okDone then
			broadcastNoticeToAll(true, "อัปโหลด Override สำเร็จ! ปลดล็อก Tier 1 และเปิดภารกิจ M2: กู้คืนไฟฟ้าชั้น 2!")
		else
			notifyPlayer(player, false, msgDone)
		end
		broadcastState()
	end)
end

submitPuzzleSolutionFn.OnServerInvoke = function(player, submittedSequence)
	local canAccess, err = tracker.canAccessCCTVTerminal()
	if not canAccess then
		return {
			ok = false,
			solved = puzzleEngine.isSolved(),
			matchedCount = 0,
			cooldownRemaining = 0,
			attemptsUsed = 0,
			message = err,
		}
	end

	if not worldController or not worldController.canPlayerInteractWithCCTV(player) then
		return {
			ok = false,
			solved = puzzleEngine.isSolved(),
			matchedCount = 0,
			cooldownRemaining = 0,
			attemptsUsed = 0,
			message = "กรุณายืนใกล้เครื่องควบคุม CCTV ห้อง 102 เพื่อส่งลำดับภาพ",
		}
	end

	local result = puzzleEngine.validateSubmission(player.UserId, submittedSequence)
	applyPuzzleSubmissionResult(player, result)
	return result
end

-- Client Bangkok Bank Vault Hex Code Submission (Server-Authoritative Validation)
submitBankSafeCodeFn.OnServerInvoke = function(player, submittedCode)
	if worldController and worldController.verifySafeCode then
		local ok, msg = worldController.verifySafeCode(submittedCode)
		if ok then
			notifyPlayer(player, true, "ปลดล็อกตู้เซฟสำเร็จ! ประตูเซฟเปิดออกแล้ว")
			broadcastState()
			return { success = true, message = msg }
		else
			return { success = false, message = msg }
		end
	end

	-- Fallback direct safe unlock
	if string.upper(tostring(submittedCode)) == "B4CA" then
		local interactables = Workspace:FindFirstChild("MissionM1_Interactables")
		local safe = interactables and interactables:FindFirstChild("M1_BankVaultSafe")
		if safe then
			local hinge = safe:FindFirstChild("SafeDoorHinge")
			local leaf = safe:FindFirstChild("SafeDoorLeaf")
			local wheel = safe:FindFirstChild("SafeWheel")
			local keypad = safe:FindFirstChild("SafeKeypadPlate")
			local led = safe:FindFirstChild("SafeKeypadLED")
			local safeTop = safe:FindFirstChild("SafeTop")
			local light = safeTop and safeTop:FindFirstChildOfClass("PointLight")
			local prompt = keypad and keypad:FindFirstChildOfClass("ProximityPrompt")

			if prompt then prompt.Enabled = false end
			if led then led.Color = Color3.fromRGB(45, 235, 75) end
			if light then light.Enabled = true end

			local revolver = interactables:FindFirstChild("M1_ManagerRevolverPickup")
			local rPrompt = revolver and revolver:FindFirstChild("RevolverPickupPrompt", true)
			if rPrompt then rPrompt.Enabled = true end

			if leaf and hinge then
				local hingeCF = hinge.CFrame
				local relLeaf = hingeCF:ToObjectSpace(leaf.CFrame)
				local relWheel = wheel and hingeCF:ToObjectSpace(wheel.CFrame)
				local relKeypad = keypad and hingeCF:ToObjectSpace(keypad.CFrame)
				local relLED = led and hingeCF:ToObjectSpace(led.CFrame)

				leaf.Anchored = true; leaf.CanCollide = false
				if wheel then wheel.Anchored = true; wheel.CanCollide = false end
				if keypad then keypad.Anchored = true; keypad.CanCollide = false end
				if led then led.Anchored = true; led.CanCollide = false end

				local numVal = Instance.new("NumberValue")
				numVal.Value = 0
				local TweenService = game:GetService("TweenService")
				local tween = TweenService:Create(numVal, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = -105 })
				numVal.Changed:Connect(function(deg)
					local curHinge = hingeCF * CFrame.Angles(0, math.rad(deg), 0)
					leaf.CFrame = curHinge * relLeaf
					if wheel then wheel.CFrame = curHinge * relWheel end
					if keypad then keypad.CFrame = curHinge * relKeypad end
					if led then led.CFrame = curHinge * relLED end
				end)
				tween:Play()
				tween.Completed:Connect(function() numVal:Destroy() end)
			end
		end
		notifyPlayer(player, true, "ปลดล็อกตู้เซฟสำเร็จ! ประตูเซฟเปิดออกแล้ว")
		broadcastState()
		return { success = true, message = "ACCESS GRANTED" }
	else
		return { success = false, message = "INCORRECT CODE" }
	end
end

-- CampaignSignals: Elevator, Door Access, Clearance, Boss Flags
requestElevatorRideFn.OnInvoke = function(player, fromFloor, toFloor)
	if not player or not player:IsA("Player") then
		return false, "Invalid player"
	end
	local ctx = buildPlayerContext(player)
	local allowed, reason = floorClearanceService.canUseElevator(ctx, fromFloor, toFloor)
	if not allowed then
		notifyPlayer(player, false, reason)
		return false, reason
	end
	return true, reason
end

requestDoorAccessFn.OnInvoke = function(doorId, player, _doorModel)
	local id = tostring(doorId or "")
	if not player or not player:IsA("Player") then
		return false, "Invalid player"
	end
	if not doorAccessService.getDoor(id) then
		-- Register ad-hoc unconfigured BreakableDoor tagged with DoorId if Dev didn't pre-register
		doorAccessService.registerDoor({
			doorId = id,
			displayName = id,
			startsUnlocked = true,
		})
	end
	local ctx = buildPlayerContext(player)
	local ok, msg, meta = doorAccessService.attemptAccess(id, ctx, { toggleIfUnlocked = true })
	if not ok then
		notifyPlayer(player, false, msg)
		return false, msg
	end
	if meta and meta.unlockedNow then
		notifyPlayer(player, true, msg)
		broadcastState()
	end
	return true, msg
end

grantClearanceFn.OnInvoke = function(tierOrNil, actorPlayer)
	if tierOrNil == nil then
		floorClearanceService.setClearanceOverride(nil)
	else
		local t = tonumber(tierOrNil)
		if not t then
			return false, "Invalid tier number (0..4)"
		end
		floorClearanceService.setClearanceOverride(t)
	end
	local effective = floorClearanceService.getEffectiveTier()
	local msg = string.format("[DEV] Floor Clearance Tier set to %d%s",
		effective, actorPlayer and (" by " .. actorPlayer.Name) or "")
	broadcastState()
	return true, msg
end

setBossDefeatedFn.OnInvoke = function(bossId, defeated, actorPlayer)
	local ok = floorClearanceService.setBossDefeated(bossId, defeated ~= false)
	if not ok then
		return false, "Invalid bossId"
	end
	broadcastState()
	return true, string.format("[DEV] Boss '%s' defeated = %s (%s)",
		tostring(bossId), tostring(defeated ~= false), actorPlayer and actorPlayer.Name or "Server")
end

unlockDoorFn.OnInvoke = function(doorId, actorPlayer)
	if doorId == "all" or doorId == "ALL" then
		for _, d in ipairs(doorAccessService.listDoors()) do
			doorAccessService.forceUnlock(d.doorId, actorPlayer and actorPlayer.Name or "DEV")
		end
		if worldController then
			worldController.onDoorUnlockedByDev()
		end
		broadcastState()
		return true, "[DEV] All registered campaign doors unlocked."
	end
	local ok, msg = doorAccessService.forceUnlock(tostring(doorId), actorPlayer and actorPlayer.Name or "DEV")
	if ok and doorId == "M1_SECURITY_ROOM_DOOR" and worldController then
		worldController.onDoorUnlockedByDev()
	end
	if ok then
		broadcastState()
	end
	return ok, msg
end

lockDoorFn.OnInvoke = function(doorId, actorPlayer)
	local ok, msg = doorAccessService.forceLock(tostring(doorId), actorPlayer and actorPlayer.Name or "DEV")
	if ok then
		if worldController then
			worldController.syncWorldState(false)
		end
		broadcastState()
	end
	return ok, msg
end

consumeQuestItemFn.OnInvoke = function(itemId, targetPlayer)
	local uid = targetPlayer and targetPlayer.UserId or 0
	local ok, msg = keyItemService.consumeItem(uid, itemId, 1, { requireDirectHolder = false })
	if ok then
		broadcastState()
	end
	return ok, msg
end

phoneCommandFn.OnInvoke = function(action, arg, actorPlayer)
	if action == "list" then
		local parts = {}
		for _, d in ipairs(doorAccessService.listDoors()) do
			table.insert(parts, string.format("%s[%s | Key:%s | Tier:%d]",
				d.doorId,
				d.unlocked and "OPEN" or "LOCKED",
				tostring(d.requiredKey or "None"),
				d.requiredClearance or 0))
		end
		return true, table.concat(parts, "; ")
	elseif action == "info" then
		local d = doorAccessService.getDoor(tostring(arg))
		if not d then
			return false, "Unknown doorId: " .. tostring(arg)
		end
		return true, string.format("%s | Unlocked:%s | Key:%s (Consume:%s) | Power:%s | Tier:%d",
			d.doorId, tostring(d.unlocked), tostring(d.requiredKey or "None"),
			tostring(d.consumeKey), tostring(d.requiresPower), d.requiredClearance or 0)
	end
	return false, "Unknown door query"
end

-- Backward-compatible server BindableEvent hook
completeObjectiveSignal.Event:Connect(function(objectiveId, actorPlayer)
	if type(objectiveId) ~= "string" then
		return
	end
	local ok = tracker.devCompleteObjective(objectiveId, actorPlayer)
	if ok then
		if tracker.getObjectiveState("M1", "M1_SOLVE_CCTV_PUZZLE") == NetProtocol.MissionState.COMPLETED then
			puzzleEngine.forceSolvedByDev()
			cctvIntelRevealed = true
			cctvIntelText = "ตรวจพบฝูงซอมบี้รวมตัวที่บันไดชั้น 4-6 และชั้น 11 — ปลดล็อกทางขึ้นดาดฟ้า!"
		end
		if objectiveId == "M2_RESTORE_BUILDING_POWER" or tracker.isBuildingPowerOn() then
			LightingSetup.init("Day")
		end
		if worldController and tracker.isSecurityDoorUnlocked() then
			worldController.onDoorUnlockedByDev()
		end
		broadcastState()
	end
end)

-- Dev Command Signals
resetMissionFn.OnInvoke = function(actorPlayer)
	puzzleEngine.reset()
	resetRoom102Runtime()
	local resetText = string.format(
		"[DEV] รีเซ็ต Mission 01 โดย %s (CCTV Variant: %s)",
		actorPlayer and actorPlayer.Name or "Server",
		puzzleEngine.getVariantId()
	)
	local ok, msg = tracker.resetCampaignToM1(resetText)
	LightingSetup.init(tracker.isBuildingPowerOn() and "Day" or "Horror")
	if worldController then
		worldController.onResetToM1()
	end
	broadcastState()
	return ok, msg
end

setMissionFn.OnInvoke = function(missionArg, actorPlayer, allowPreview)
	local m = MissionConfig.getMission(missionArg)
	if not m then
		return false, string.format("ไม่พบภารกิจ '%s' (ใช้งานได้: M1..M4)", tostring(missionArg))
	end
	if not m.implemented and allowPreview ~= true then
		return false, string.format("%s (%s) ยังอยู่ในสถานะ [%s] — ใส่ '--preview' เพื่อดูโครงสร้างหรือเล่น M1/M2",
			m.code, m.name, m.implementationStatus)
	end
	puzzleEngine.reset()
	resetRoom102Runtime()
	local ok, msg = tracker.setMissionById(m.id, true, { allowUnimplementedPreview = (allowPreview == true) })
	LightingSetup.init(tracker.isBuildingPowerOn() and "Day" or "Horror")
	if m.id == "M1" and worldController then
		worldController.onResetToM1()
	end
	broadcastState()
	return ok, msg
end

getStatusFn.OnInvoke = function()
	local snap = tracker.serializeSnapshot(getCurrentEnvironmentMode(), puzzleEngine.isSolved())
	return true, string.format(
		"[%s] %s (%s) | Obj:%s (%d/%d) | Tier:%d | Keycard:%s | Door102:%s | CCTV:%s | Power:%s | ZMode:%s | Var:%s",
		snap.environmentMode,
		snap.missionId,
		snap.missionState,
		tostring(snap.activeObjectiveId),
		snap.completedSubCount,
		snap.totalSubCount,
		snap.floorClearanceTier or 0,
		snap.hasKeycard and "YES" or "NO",
		snap.securityDoorUnlocked and "OPEN" or "LOCKED",
		snap.puzzleSolved and "SOLVED" or "PENDING",
		snap.buildingPowerOn and "ON" or "OFF",
		tostring(snap.zombieMode or "Campaign"),
		puzzleEngine.getVariantId()
	)
end

devCompleteObjectiveFn.OnInvoke = function(objId, actorPlayer)
	local ok, msg = tracker.devCompleteObjective(objId, actorPlayer)
	if ok then
		if tracker.getObjectiveState("M1", "M1_SOLVE_CCTV_PUZZLE") == NetProtocol.MissionState.COMPLETED then
			puzzleEngine.forceSolvedByDev()
		end
		if worldController and tracker.isSecurityDoorUnlocked() then
			worldController.onDoorUnlockedByDev()
		end
		broadcastState()
	end
	return ok, msg
end

grantQuestItemFn.OnInvoke = function(itemId, actorPlayer, allowFutureTest)
	local ok, msg = tracker.devGrantQuestItem(
		itemId,
		actorPlayer and actorPlayer.UserId,
		actorPlayer and actorPlayer.Name,
		allowFutureTest == true
	)
	if ok then
		broadcastState()
	end
	return ok, msg
end

setBuildingPowerFn.OnInvoke = function(enabled, actorPlayer)
	tracker.setBuildingPowerOn(enabled, string.format("[DEV] Power Grid set %s by %s", enabled and "ON" or "OFF", actorPlayer and actorPlayer.Name or "Server"))
	LightingSetup.init(enabled and "Day" or "Horror")
	local snap = broadcastState()
	return true, snap.notice
end

-- Broadcast initial snapshot & listen to DevMode / ZombieMode flips
Workspace:GetAttributeChangedSignal(NetProtocol.Attributes.EnvironmentMode):Connect(function()
	broadcastState()
end)

Workspace:GetAttributeChangedSignal(NetProtocol.Attributes.ZombieMode):Connect(function()
	broadcastState()
end)

broadcastState()

local GUARD_NOTE_PAYLOAD = {
	variant = "GUARD_NOTE",
	title = "สมุดเวร รปภ. — ห้องควบคุม 102",
	subtitle = "บันทึกฉุกเฉินประจำจุดรักษาความปลอดภัย อาคาร 40 ปี มจพ.",
	body = table.concat({
		"1) เหตุการณ์ที่เกิดขึ้น:",
		"   ไฟฟ้าหลักทั้งอาคารดับลงหลังการระบาดของเชื้อไวรัส ฝูงผู้ติดเชื้อบุกยึดโถงชั้น 1 ห้องควบคุม 102 จึงทำงานด้วยระบบ UPS สำรองฉุกเฉินเท่านั้น (แบตลดลงเรื่อยๆ)",
		"",
		"2) ผู้รอดชีวิตบนดาดฟ้า:",
		"   วิทยุสื่อสารรับสัญญาณจากกลุ่มผู้รอดชีวิตบนลานดาดฟ้าชั้น 12 ได้ — พวกเขายังปลอดภัยและกำลังรอทีมขึ้นไปสมทบ",
		"",
		"3) แผนการอพยพ:",
		"   ปลดล็อกระบบ Security Override (Tier 1) ในห้องนี้ -> ขึ้นชั้น 2 กู้คืนไฟฟ้าหลักที่เครื่องกำเนิดไฟฟ้า -> ขึ้นดาดฟ้าชั้น 12 ใช้กุญแจและวิทยุสื่อสารเรียกเฮลิคอปเตอร์!",
	}, "\n"),
	footer = "วัตถุประกอบที่โต๊ะ: วิทยุสื่อสาร + กุญแจทางขึ้นดาดฟ้า | ข้อมูลบันทึกเข้าโทรศัพท์เจ้าหน้าที่แล้ว",
}

-- Build Floor 1 M1 World Interactables + Floor 2 Power Generator once Building 40 F1 exists
task.spawn(function()
	Workspace:WaitForChild("Floor_1_Building40", 60)
	worldController = MissionWorldInteractables.build({
		tracker = tracker,
		puzzleEngine = puzzleEngine,
		floorY = 1.0,
		floor2Y = 23.0,
		onStateChanged = function(ok, msg, actorPlayer)
			if not ok and actorPlayer then
				notifyPlayer(actorPlayer, false, msg)
			end
			broadcastState()
		end,
		onOpenPuzzleForPlayer = function(player)
			openPuzzleModalEvent:FireClient(player, puzzleEngine.getClientModalPayload())
		end,
		onOpenSafeKeypadForPlayer = function(player)
			openBankSafeKeypadEvent:FireClient(player)
		end,
		onShowEmergencyMemoForPlayer = function(player)
			showEmergencyMemoEvent:FireClient(player)
		end,
		onOpenGuardNoteForPlayer = function(player)
			if tracker.recordGuardNoteRead then
				tracker.recordGuardNoteRead(player.UserId, player.Name)
			end
			if tracker.addPhoneNote then
				tracker.addPhoneNote({
					id = "NOTE_M1_GUARD_LOGBOOK",
					title = GUARD_NOTE_PAYLOAD.title,
					category = "สมุดเวร รปภ.",
					missionId = "M1",
					floor = 1,
					discoveredBy = player.Name,
					body = GUARD_NOTE_PAYLOAD.body,
				})
			end
			showEmergencyMemoEvent:FireClient(player, GUARD_NOTE_PAYLOAD)
			broadcastState()
		end,
		onMonitorWallSelect = function(player, clipId)
			handleMonitorWallSelect(player, clipId)
		end,
		onStartOverrideHoldout = function(player)
			startOverrideHoldout(player)
		end,
		onRestorePowerTriggered = function(player)
			if tracker.reachPowerRoom then
				tracker.reachPowerRoom(player.UserId, player.Name)
			end
			local okPower, msgPower = tracker.restoreBuildingPower(player.UserId, player.Name)
			if okPower then
				LightingSetup.init("Day")
				broadcastNoticeToAll(true, msgPower or "คืนไฟทั้งอาคารสำเร็จ! ไฟส่องสว่างและลิฟต์กลับมาทำงานแล้ว")
			else
				notifyPlayer(player, false, msgPower)
			end
			broadcastState()
		end,
		onPlayerNotice = function(player, ok, msg)
			notifyPlayer(player, ok, msg)
		end,
		onSupplyCacheClaimed = function(player)
			local sFolder = ServerStorage:FindFirstChild(NetProtocol.Signals.SurvivalSignalsFolder)
			local grantSupply = sFolder and sFolder:FindFirstChild(NetProtocol.Signals.GrantSupply)
			if grantSupply and grantSupply:IsA("BindableFunction") then
				pcall(function()
					grantSupply:Invoke(player, "Battery")
				end)
			end
		end,
	})
	broadcastState()
	print("🎯 [MissionService] Room 102 Overhaul + M1/M2 (FIRST CONTACT -> RESTORE POWER) mounted cleanly.")

	-- ตรวจจับการเดินทางถึงเครื่องกำเนิดไฟฟ้าชั้น 2 สำหรับ M2_REACH_POWER_ROOM
	while true do
		task.wait(1.0)
		if tracker.getMissionState("M2") == NetProtocol.MissionState.ACTIVE
			and tracker.getObjectiveState("M2", "M2_REACH_POWER_ROOM") ~= NetProtocol.MissionState.COMPLETED
		then
			for _, p in ipairs(Players:GetPlayers()) do
				if not isPlayerDownedOrDead(p) then
					local char = p.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if hrp and (hrp.Position - M2_POWER_ROOM_POS).Magnitude <= 24 then
						if tracker.reachPowerRoom and tracker.reachPowerRoom(p.UserId, p.Name) then
							broadcastNoticeToAll(true, "พบเครื่องกำเนิดไฟฟ้าหลักชั้น 2 แล้ว! กด [E] ค้างเพื่อกู้คืนไฟทั้งตึก")
							broadcastState()
							break
						end
					end
				end
			end
		end
	end
end)
