-- Server-authoritative Floor Clearance & Building Power Access Service for Building 40 (F1-F12).
-- Controls Elevator access, Tier 0-4 security clearance, Boss gates, and Dev overrides.
-- Pure-Luau factory (`FloorClearanceService.create(deps)`) for deterministic unit + Studio testing.

local FloorClearanceService = {}

function FloorClearanceService.create(deps)
	deps = deps or {}
	local MissionConfig = deps.MissionConfig
	local keyItemService = deps.keyItemService

	local floorLookup = {}
	if MissionConfig and type(MissionConfig.BUILDING_FLOORS) == "table" then
		for _, entry in ipairs(MissionConfig.BUILDING_FLOORS) do
			floorLookup[entry.floor] = entry
		end
	end

	local explicitTier = 0
	local devOverrideTier = nil
	local powerOn = false
	local devBypass = false
	local defeatedBosses = {}
	local floorBossRequirements = {
		-- Prepared cleanly for Phase 4-5 without blocking non-boss F1-F11 testing:
		-- [12] = "THE_WARDEN", (enabled once Phase 4 Warden encounter is added)
	}

	local service = {}

	function service.setPowerOn(isOn)
		powerOn = isOn == true
		return powerOn
	end

	function service.isPowerOn()
		return powerOn
	end

	function service.setDevBypass(enabled)
		devBypass = enabled == true
		return devBypass
	end

	function service.isDevBypass()
		return devBypass
	end

	function service.grantClearanceTier(tier)
		local clamped = math.clamp(math.floor(tonumber(tier) or 0), 0, 4)
		if clamped > explicitTier then
			explicitTier = clamped
		end
		return service.getEffectiveTier()
	end

	-- Dev / Reset explicit tier setter (overrides to exact tier when provided, or nil to clear override).
	function service.setClearanceOverride(tierOrNil)
		if tierOrNil == nil then
			devOverrideTier = nil
		else
			devOverrideTier = math.clamp(math.floor(tonumber(tierOrNil) or 0), 0, 4)
		end
		return service.getEffectiveTier()
	end

	function service.getEffectiveTier()
		if devOverrideTier ~= nil then
			return devOverrideTier
		end
		local keyTier = keyItemService and keyItemService.getHighestClearanceFromKeys() or 0
		return math.max(explicitTier, keyTier)
	end

	function service.setBossDefeated(bossId, defeated)
		if type(bossId) ~= "string" or bossId == "" then
			return false
		end
		defeatedBosses[string.upper(bossId)] = defeated == true
		return true
	end

	function service.isBossDefeated(bossId)
		if type(bossId) ~= "string" or bossId == "" then
			return false
		end
		return defeatedBosses[string.upper(bossId)] == true
	end

	function service.setFloorRequiredBoss(floorNum, bossIdOrNil)
		floorBossRequirements[floorNum] = bossIdOrNil
	end

	function service.getFloorDef(floorNum)
		local num = math.floor(tonumber(floorNum) or 0)
		local existing = floorLookup[num]
		if existing then
			return existing
		end
		if num >= 1 and num <= 12 then
			return {
				floor = num,
				name = "Building 40 — Floor " .. tostring(num),
				zone = "Sector",
				requiredTier = 0,
				requiresPower = num > 1,
			}
		end
		return nil
	end

	function service.canAccessFloor(floorNum, playerContext)
		playerContext = playerContext or {}
		if playerContext.isDowned or playerContext.isDead then
			return {
				allowed = false,
				reason = "Incapacitated players cannot operate floor access",
				floor = floorNum,
				requiredTier = 0,
				currentTier = service.getEffectiveTier(),
				powerRequired = false,
				powerOn = powerOn,
			}
		end

		local def = service.getFloorDef(floorNum)
		if not def then
			return {
				allowed = false,
				reason = "Unknown floor: " .. tostring(floorNum),
				floor = floorNum,
				requiredTier = 0,
				currentTier = service.getEffectiveTier(),
				powerRequired = false,
				powerOn = powerOn,
			}
		end

		local currentTier = service.getEffectiveTier()
		local bypass = devBypass or (playerContext.devBypass == true)
		if bypass then
			return {
				allowed = true,
				reason = "[DEV] Clearance Bypass Active",
				floor = def.floor,
				name = def.name,
				requiredTier = def.requiredTier,
				currentTier = currentTier,
				powerRequired = def.requiresPower == true,
				powerOn = powerOn,
			}
		end

		if def.requiresPower and not powerOn then
			return {
				allowed = false,
				reason = string.format("Floor %d access denied: Building 40 power is OFFLINE", def.floor),
				floor = def.floor,
				name = def.name,
				requiredTier = def.requiredTier,
				currentTier = currentTier,
				powerRequired = true,
				powerOn = powerOn,
			}
		end

		if currentTier < (def.requiredTier or 0) then
			return {
				allowed = false,
				reason = string.format("Floor %d requires Clearance Tier %d (Current: Tier %d)", def.floor, def.requiredTier, currentTier),
				floor = def.floor,
				name = def.name,
				requiredTier = def.requiredTier,
				currentTier = currentTier,
				powerRequired = def.requiresPower == true,
				powerOn = powerOn,
			}
		end

		local reqBoss = floorBossRequirements[def.floor]
		if reqBoss and not service.isBossDefeated(reqBoss) then
			return {
				allowed = false,
				reason = string.format("Floor %d locked until Boss '%s' is defeated", def.floor, reqBoss),
				floor = def.floor,
				name = def.name,
				requiredTier = def.requiredTier,
				currentTier = currentTier,
				powerRequired = def.requiresPower == true,
				powerOn = powerOn,
			}
		end

		return {
			allowed = true,
			reason = "Access Granted",
			floor = def.floor,
			name = def.name,
			requiredTier = def.requiredTier,
			currentTier = currentTier,
			powerRequired = def.requiresPower == true,
			powerOn = powerOn,
		}
	end

	function service.canUseElevator(playerContext, fromFloor, toFloor)
		playerContext = playerContext or {}
		if playerContext.isDowned or playerContext.isDead then
			return false, "Incapacitated players cannot operate the elevator"
		end

		local bypass = devBypass or (playerContext.devBypass == true)
		if not bypass and not powerOn then
			return false, string.format("ELEVATOR OFFLINE — Restore Building 40 Power before travelling to F%d", tonumber(toFloor) or 0)
		end

		local floorCheck = service.canAccessFloor(toFloor, playerContext)
		return floorCheck.allowed, floorCheck.reason, floorCheck
	end

	function service.getFloorStatuses(playerContext)
		local list = {}
		for floorNum = 1, 12 do
			local check = service.canAccessFloor(floorNum, playerContext)
			local def = service.getFloorDef(floorNum)
			table.insert(list, {
				floor = floorNum,
				name = def and def.name or ("Floor " .. floorNum),
				zone = def and def.zone or "",
				requiredTier = def and def.requiredTier or 0,
				requiresPower = def and def.requiresPower == true,
				accessible = check.allowed == true,
				statusReason = check.reason,
			})
		end
		return list
	end

	function service.resetAll()
		explicitTier = 0
		devOverrideTier = nil
		powerOn = false
		devBypass = false
		defeatedBosses = {}
	end

	return service
end

return FloorClearanceService
