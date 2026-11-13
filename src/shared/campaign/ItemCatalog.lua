-- Shared catalog unifying Weapons, Survival Supplies, and Campaign Quest Items.
-- Preserves existing WeaponRegistry IDs & SurvivalAndHorrorSetup pouch caps.

local ItemCatalog = {}

ItemCatalog.MAX_QUEST_SLOTS = 3
ItemCatalog.SUPPLY_CAPS = {
	FoodPacks = 4,
	MedkitPacks = 3,
	BatteryPacks = 4,
}

ItemCatalog.QUEST_ITEMS = {
	MaintenanceKey = {
		id = "MaintenanceKey",
		displayName = "กุญแจห้องบำรุงรักษา (F1)",
		shortLabel = "กุญแจซ่อมบำรุง",
		missionId = "M1",
		kind = "QuestKey",
		consumeOnUse = true,
		maxStack = 1,
		teamShared = true,
		phase = "Phase1",
		description = "กุญแจทองเหลืองสำหรับเปิดตู้เก็บอุปกรณ์บำรุงรักษาชั้น 1",
	},
	SecurityKeycard = {
		id = "SecurityKeycard",
		displayName = "คีย์การ์ด รปภ. (Clearance Tier 1)",
		shortLabel = "คีย์การ์ด T1",
		missionId = "M1",
		kind = "QuestKey",
		consumeOnUse = false,
		maxStack = 1,
		clearanceTier = 1,
		teamShared = true,
		phase = "Phase1",
		description = "คีย์การ์ดสำหรับปลดล็อกประตูห้องควบคุมความปลอดภัย 102 และสิทธิ์ชั้นล่าง F2-F3",
	},
	CCTVEventLog = {
		id = "CCTVEventLog",
		displayName = "สมุดเวร รปภ. & บันทึก CCTV",
		shortLabel = "สมุดเวร รปภ.",
		missionId = "M1",
		kind = "Evidence",
		consumeOnUse = false,
		maxStack = 1,
		teamShared = true,
		phase = "Phase1",
		description = "บันทึกเหตุการณ์การระบาดและเบาะแสลำดับกล้องวงจรปิดอาคาร 40",
	},
	FuseA = {
		id = "FuseA",
		displayName = "High-Voltage Fuse A",
		shortLabel = "FUSE A",
		missionId = "M2",
		kind = "QuestPart",
		consumeOnUse = true,
		maxStack = 1,
		teamShared = true,
		phase = "Planned_M2_M7",
	},
	FuseB = {
		id = "FuseB",
		displayName = "High-Voltage Fuse B",
		shortLabel = "FUSE B",
		missionId = "M2",
		kind = "QuestPart",
		consumeOnUse = true,
		maxStack = 1,
		teamShared = true,
		phase = "Planned_M2_M7",
	},
	FuseC = {
		id = "FuseC",
		displayName = "High-Voltage Fuse C",
		shortLabel = "FUSE C",
		missionId = "M2",
		kind = "QuestPart",
		consumeOnUse = true,
		maxStack = 1,
		teamShared = true,
		phase = "Planned_M2_M7",
	},
	LabJournal = {
		id = "LabJournal",
		displayName = "Researcher Journal",
		shortLabel = "JOURNAL",
		missionId = "M3",
		kind = "Evidence",
		consumeOnUse = false,
		maxStack = 1,
		teamShared = true,
		phase = "Planned_M2_M7",
	},
	SecurityOverrideToken = {
		id = "SecurityOverrideToken",
		displayName = "Safe Override Cipher",
		shortLabel = "SAFE CIPHER",
		missionId = "M3",
		kind = "QuestKey",
		consumeOnUse = true,
		maxStack = 1,
		clearanceTier = 2,
		teamShared = true,
		phase = "Planned_M2_M7",
	},
	BatteryModule = {
		id = "BatteryModule",
		displayName = "Radio Battery Module",
		shortLabel = "BATTERY MOD",
		missionId = "M4",
		kind = "QuestPart",
		consumeOnUse = true,
		maxStack = 1,
		teamShared = true,
		phase = "Planned_M2_M7",
	},
	QuarantineKeycard = {
		id = "QuarantineKeycard",
		displayName = "Quarantine Keycard (Tier 3)",
		shortLabel = "KEYCARD T3",
		missionId = "M5",
		kind = "QuestKey",
		consumeOnUse = false,
		maxStack = 1,
		clearanceTier = 3,
		teamShared = true,
		phase = "Planned_M2_M7",
	},
	MasterKeycard = {
		id = "MasterKeycard",
		displayName = "Master Keycard (Tier 4)",
		shortLabel = "MASTER KEY",
		missionId = "M5",
		kind = "QuestKey",
		consumeOnUse = false,
		maxStack = 1,
		clearanceTier = 4,
		teamShared = true,
		phase = "Planned_M2_M7",
	},
	EmergencyBeaconKey = {
		id = "EmergencyBeaconKey",
		displayName = "Helipad Beacon Key",
		shortLabel = "BEACON KEY",
		missionId = "M6",
		kind = "QuestKey",
		consumeOnUse = true,
		maxStack = 1,
		teamShared = true,
		phase = "Planned_M2_M7",
	},
}

ItemCatalog.SUPPLIES = {
	Food = { id = "Food", displayName = "Emergency Ration (+1 Food Pack)", kind = "Supply", slot = 4 },
	Medkit = { id = "Medkit", displayName = "First Aid Medkit (+1 Med Pack)", kind = "Supply", slot = 5 },
	Battery = { id = "Battery", displayName = "Flashlight Battery (+1 Battery Pack)", kind = "Supply", slot = 6 },
	Ammo = { id = "Ammo", displayName = "Full Magazine Refill", kind = "Ammo" },
}

-- Canonical case-insensitive weapon names supported by WaveAndZombieManager.
ItemCatalog.WEAPON_NAMES = {
	"Classic", "Shorty", "Frenzy", "Ghost", "Sheriff",
	"Stinger", "Spectre", "Bucky", "Judge",
	"Bulldog", "Guardian", "Phantom", "Vandal",
	"Marshal", "Outlaw", "Operator", "Ares", "Odin",
}

local ALIASES = {
	mkey = { category = "Quest", id = "MaintenanceKey" },
	maintenancekey = { category = "Quest", id = "MaintenanceKey" },
	servicekey = { category = "Quest", id = "MaintenanceKey" },
	keycard = { category = "Quest", id = "SecurityKeycard" },
	securitykeycard = { category = "Quest", id = "SecurityKeycard" },
	card = { category = "Quest", id = "SecurityKeycard" },
	dutylog = { category = "Quest", id = "CCTVEventLog" },
	cctvlog = { category = "Quest", id = "CCTVEventLog" },
	fusea = { category = "Quest", id = "FuseA" },
	fuseb = { category = "Quest", id = "FuseB" },
	fusec = { category = "Quest", id = "FuseC" },
	journal = { category = "Quest", id = "LabJournal" },
	token = { category = "Quest", id = "SecurityOverrideToken" },
	cipher = { category = "Quest", id = "SecurityOverrideToken" },
	batterymodule = { category = "Quest", id = "BatteryModule" },
	qcard = { category = "Quest", id = "QuarantineKeycard" },
	quarantinekeycard = { category = "Quest", id = "QuarantineKeycard" },
	quarantinecard = { category = "Quest", id = "QuarantineKeycard" },
	masterkeycard = { category = "Quest", id = "MasterKeycard" },
	masterkey = { category = "Quest", id = "MasterKeycard" },
	beaconkey = { category = "Quest", id = "EmergencyBeaconKey" },
	emergencybeaconkey = { category = "Quest", id = "EmergencyBeaconKey" },
	food = { category = "Supply", id = "Food" },
	ration = { category = "Supply", id = "Food" },
	medkit = { category = "Supply", id = "Medkit" },
	heal = { category = "Supply", id = "Medkit" },
	battery = { category = "Supply", id = "Battery" },
	ammo = { category = "Supply", id = "Ammo" },
	pistol = { category = "Weapon", id = "Classic" },
	rifle = { category = "Weapon", id = "Vandal" },
	shotgun = { category = "Weapon", id = "Judge" },
	sniper = { category = "Weapon", id = "Operator" },
}

for _, wName in ipairs(ItemCatalog.WEAPON_NAMES) do
	ALIASES[string.lower(wName)] = { category = "Weapon", id = wName }
end

function ItemCatalog.getQuestItem(itemId)
	return ItemCatalog.QUEST_ITEMS[itemId]
end

function ItemCatalog.isPhase1QuestItem(itemId)
	local item = ItemCatalog.QUEST_ITEMS[itemId]
	return item ~= nil and item.phase == "Phase1"
end

function ItemCatalog.resolveDevGiveToken(rawToken)
	if type(rawToken) ~= "string" then
		return nil
	end
	local cleaned = string.lower((rawToken:gsub("[%s_%-]", "")))
	return ALIASES[cleaned]
end

function ItemCatalog.resolveQuestItemId(rawToken)
	if type(rawToken) ~= "string" then
		return nil
	end
	if ItemCatalog.QUEST_ITEMS[rawToken] then
		return rawToken
	end
	local cleaned = string.lower((rawToken:gsub("[%s_%-]", "")))
	local entry = ALIASES[cleaned]
	if entry and entry.category == "Quest" then
		return entry.id
	end
	for itemId in pairs(ItemCatalog.QUEST_ITEMS) do
		if string.lower(itemId) == cleaned then
			return itemId
		end
	end
	return nil
end

return ItemCatalog
