--[[
    MissionService.server.lua
    Server-authoritative Campaign Mission Service for INFECTED-KMUTNB.
    - Phase 1: M1 (FIRST CONTACT) playable vertical slice + M2-M7 structural graph (M3/M4 parallel)
    - Integrates KeyItemService, DoorAccessService, FloorClearanceService, ObjectiveTracker, CCTVPuzzleEngine
    - Wires ReplicatedStorage.MissionEvents (including PhoneAction) + ServerStorage.MissionSignals & CampaignSignals
    - Supports 2-4 Co-op shared progress, late-join sync, and Death/Disconnect Keycard & Key recovery
]]

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

local LightingSetup = require(ServerScriptService:WaitForChild("Map"):WaitForChild("LightingSetup"))

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

local function syncWorkspaceAttributes(snapshot)
	local clampedIndex = math.min((snapshot.completedSubCount or 0) + 1, math.max(1, snapshot.totalSubCount or 1))
	Workspace:SetAttribute(NetProtocol.Attributes.ActiveMissionId, snapshot.missionId)
	Workspace:SetAttribute(NetProtocol.Attributes.ActiveObjectiveIndex, clampedIndex)
	Workspace:SetAttribute(NetProtocol.Attributes.ActiveObjectiveLabel, snapshot.activeObjectiveTitle)
	Workspace:SetAttribute(NetProtocol.Attributes.SecurityRoomUnlocked, snapshot.securityDoorUnlocked)
	Workspace:SetAttribute(NetProtocol.Attributes.BuildingPowerOn, snapshot.buildingPowerOn)
	Workspace:SetAttribute(NetProtocol.Attributes.FloorClearanceTier, snapshot.floorClearanceTier or 0)
	Workspace:SetAttribute(NetProtocol.Attributes.CampaignComplete, snapshot.campaignComplete == true)
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
			message = "Stand near the Room 102 CCTV Terminal (and be alive/standing) to submit.",
		}
	end

	local result = puzzleEngine.validateSubmission(player.UserId, submittedSequence)
	if result.solved then
		tracker.completeCCTVPuzzle(player.UserId, player.Name)
		broadcastState()
	end
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
	local resetText = string.format(
		"[DEV] Mission 01 reset by %s (CCTV Variant: %s)",
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
		return false, string.format("Unknown mission '%s'. Valid: M1..M7", tostring(missionArg))
	end
	if not m.implemented and allowPreview ~= true then
		return false, string.format("%s (%s) is [%s] in Phase 1. Pass '--preview' to stage interface only, or play M1.",
			m.code, m.name, m.implementationStatus)
	end
	puzzleEngine.reset()
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

-- Build Floor 1 M1 World Interactables once Building 40 F1 exists
task.spawn(function()
	Workspace:WaitForChild("Floor_1_Building40", 60)
	worldController = MissionWorldInteractables.build({
		tracker = tracker,
		puzzleEngine = puzzleEngine,
		floorY = 1.0,
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
	print("🎯 [MissionService] Phase 1 Core Infrastructure + M1 (FIRST CONTACT) mounted cleanly.")
end)
