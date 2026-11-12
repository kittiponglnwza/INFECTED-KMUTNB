--!strict
-- Shared campaign constants, state enums, remote names, and attribute keys.
-- Note: Zero server secrets or puzzle answers belong in ReplicatedStorage.

local NetProtocol = {}

NetProtocol.EnvironmentMode = {
	Campaign = "Campaign",
	Development = "Development",
}

NetProtocol.MissionState = {
	LOCKED = "LOCKED",
	AVAILABLE = "AVAILABLE",
	ACTIVE = "ACTIVE",
	COMPLETED = "COMPLETED",
	FAILED = "FAILED",
}

NetProtocol.ObjectiveType = {
	CollectItem = "CollectItem",
	Interact = "Interact",
	SolvePuzzle = "SolvePuzzle",
	Survive = "Survive",
	Defend = "Defend",
	ReachArea = "ReachArea",
	Activate = "Activate",
}

NetProtocol.ZombieMode = {
	Campaign = "Campaign",
	Wave = "Wave",
}

NetProtocol.ClearanceTier = {
	Tier0_Lobby = 0,
	Tier1_Lower = 1,
	Tier2_MidLabs = 2,
	Tier3_Quarantine = 3,
	Tier4_CommandRoof = 4,
}

NetProtocol.Attributes = {
	EnvironmentMode = "EnvironmentMode",
	DevModeActive = "DevModeActive",
	CanUseDevTools = "CanUseDevTools",
	CanUseAdminMode = "CanUseAdminMode",
	IsAdminGodMode = "IsAdminGodMode",
	DevBypassLocks = "DevBypassLocks",
	BuildingPowerOn = "BuildingPowerOn",
	DevSessionTainted = "DevSessionTainted",
	CampaignComplete = "CampaignComplete",
	SecurityRoomUnlocked = "SecurityRoomUnlocked",
	FloorClearanceTier = "FloorClearanceTier",
	ZombieMode = "ZombieMode",
	ZombiesPaused = "ZombiesPaused",
	ActiveMissionId = "ActiveMissionId",
	ActiveObjectiveIndex = "ActiveObjectiveIndex",
	ActiveObjectiveLabel = "ActiveObjectiveLabel",
	QuestKeycardHolder = "QuestKeycardHolder",
	QuestInventoryJson = "QuestInventoryJson",
	UnreadPhoneCount = "UnreadPhoneCount",
}

NetProtocol.Remotes = {
	MissionEventsFolder = "MissionEvents",
	StateChanged = "StateChanged",
	StateRequest = "StateRequest",
	OpenPuzzleModal = "OpenPuzzleModal",
	SubmitPuzzleSolution = "SubmitPuzzleSolution",
	PhoneAction = "PhoneAction",
	DevFeedback = "DevFeedback",
	ClientCommand = "ClientCommand",
	ToggleZombiesPaused = "ToggleZombiesPaused",
}

NetProtocol.Signals = {
	MissionSignalsFolder = "MissionSignals",
	CompleteObjective = "CompleteObjective",
	ResetMission = "ResetMission",
	SetMission = "SetMission",
	GrantQuestItem = "GrantQuestItem",
	ConsumeQuestItem = "ConsumeQuestItem",
	SetBuildingPower = "SetBuildingPower",
	ToggleDevMode = "ToggleDevMode",
	RunDevCommand = "RunDevCommand",
	CampaignSignalsFolder = "CampaignSignals",
	RequestDoorAccess = "RequestDoorAccess",
	RequestElevatorRide = "RequestElevatorRide",
	GrantClearance = "GrantClearance",
	SetBossDefeated = "SetBossDefeated",
	UnlockDoor = "UnlockDoor",
	LockDoor = "LockDoor",
	ZombieSignalsFolder = "ZombieSignals",
	SetZombieMode = "SetZombieMode",
	TriggerNoise = "TriggerNoise",
	TriggerHorde = "TriggerHorde",
	TriggerEncounter = "TriggerEncounter",
	ResetZombies = "ResetZombies",
	GetZombieStats = "GetZombieStats",
	SetZombiesPaused = "SetZombiesPaused",
	DevSignalsFolder = "DevSignals",
	SpawnZombie = "SpawnZombie",
	WeaponSignalsFolder = "WeaponSignals",
	GrantWeapon = "GrantWeapon",
	RefillAmmo = "RefillAmmo",
	AddPoints = "AddPoints",
	SurvivalSignalsFolder = "SurvivalSignals",
	GrantSupply = "GrantSupply",
}

-- Canonical teleport aliases mapped to server destination keys for Dev !tp helper.
NetProtocol.TeleportAliases = ({
	lobby = "Floor1",
	f1 = "Floor1",
	floor1 = "Floor1",
	spawn = "Floor1",
	b40 = "Floor1",
	keycard = "F1Keycard",
	bank = "F1Keycard",
	security = "SecurityRoom",
	sec = "SecurityRoom",
	room102 = "SecurityRoom",
	door = "SecurityDoor",
	cafe = "F1Cafe",
	plaza = "Plaza",
	canteen = "Canteen",
	f2 = "Canteen",
	floor2 = "Canteen",
	arena = "SportsArena",
	sports = "SportsArena",
	f3 = "SportsArena",
	floor3 = "SportsArena",
	lab = "Floor11",
	f11 = "Floor11",
	floor11 = "Floor11",
	roof = "Rooftop",
	rooftop = "Rooftop",
	f12 = "Rooftop",
	floor12 = "Rooftop",
	range = "TheRange",
	testrange = "TheRange",
} :: { [string]: string })

function NetProtocol.resolveTeleportAlias(rawName: any): string?
	if type(rawName) ~= "string" then
		return nil
	end
	local normalized = string.lower((rawName:gsub("^%s+", ""):gsub("%s+$", "")))
	if normalized == "" then
		return nil
	end
	return NetProtocol.TeleportAliases[normalized]
end

return NetProtocol
