-- Server-authoritative Door Access Control Service.
-- Verifies Key/Keycard, Power, Floor Clearance, Mission Prereqs, and Boss Defeated gates
-- BEFORE unlocking any secured door. Enforces atomic per-door locks & consume-on-success-only rules.

local DoorAccessService = {}

function DoorAccessService.create(deps)
	deps = deps or {}
	local keyItemService = deps.keyItemService
	local floorClearanceService = deps.floorClearanceService
	local isMissionCompletedFn = deps.isMissionCompletedFn
	local clockFn = deps.clockFn or os.clock

	local doors = {} -- [doorId] = DoorState
	local localLocks = {}

	local service = {}

	local function acquireDoorLock(doorId, userId)
		local lockKey = "DOOR_ACCESS:" .. tostring(doorId)
		if keyItemService and keyItemService.acquireLock then
			return keyItemService.acquireLock(lockKey, userId, 0.7)
		end
		local now = clockFn()
		local existing = localLocks[lockKey]
		if existing and existing.holderUserId ~= userId and existing.expiresAt > now then
			return false, "Another survivor is accessing this door"
		end
		localLocks[lockKey] = { holderUserId = userId, expiresAt = now + 0.7 }
		return true
	end

	local function releaseDoorLock(doorId, userId)
		local lockKey = "DOOR_ACCESS:" .. tostring(doorId)
		if keyItemService and keyItemService.releaseLock then
			keyItemService.releaseLock(lockKey, userId)
			return
		end
		local existing = localLocks[lockKey]
		if existing and (userId == nil or existing.holderUserId == userId) then
			localLocks[lockKey] = nil
		end
	end

	function service.registerDoor(spec)
		if type(spec) ~= "table" or type(spec.doorId) ~= "string" or spec.doorId == "" then
			error("DoorAccessService.registerDoor requires spec.doorId")
		end
		local startsUnlocked = spec.startsUnlocked == true
		local record = {
			doorId = spec.doorId,
			displayName = spec.displayName or spec.doorId,
			floor = spec.floor or 1,
			requiredKey = spec.requiredKey,
			consumeKey = spec.consumeKey == true,
			requiresPower = spec.requiresPower == true,
			requiredClearance = tonumber(spec.requiredClearance) or 0,
			requiredMissionId = spec.requiredMissionId,
			requiredBossId = spec.requiredBossId,
			startsUnlocked = startsUnlocked,
			unlocked = startsUnlocked,
			isOpen = spec.startsOpen == true,
			unlockedBy = nil,
			onStateChanged = spec.onStateChanged,
		}
		doors[spec.doorId] = record
		return record
	end

	function service.getDoor(doorId)
		return doors[doorId]
	end

	function service.listDoors()
		local out = {}
		for _, d in pairs(doors) do
			table.insert(out, {
				doorId = d.doorId,
				displayName = d.displayName,
				floor = d.floor,
				unlocked = d.unlocked,
				isOpen = d.isOpen,
				requiredKey = d.requiredKey,
				consumeKey = d.consumeKey,
				requiresPower = d.requiresPower,
				requiredClearance = d.requiredClearance,
				requiredMissionId = d.requiredMissionId,
				requiredBossId = d.requiredBossId,
			})
		end
		table.sort(out, function(a, b)
			return a.doorId < b.doorId
		end)
		return out
	end

	function service.isUnlocked(doorId)
		local d = doors[doorId]
		return d ~= nil and d.unlocked == true
	end

	function service.isOpen(doorId)
		local d = doors[doorId]
		return d ~= nil and d.isOpen == true
	end

	local function evaluateRequirements(d, playerContext)
		playerContext = playerContext or {}
		local bypass = (playerContext.devBypass == true) or (floorClearanceService and floorClearanceService.isDevBypass())
		if bypass then
			return true, "[DEV] Lock Bypassed"
		end

		if d.requiresPower then
			local powerOn = floorClearanceService and floorClearanceService.isPowerOn() or false
			if not powerOn then
				return false, string.format("%s: Requires Building Power ON", d.displayName)
			end
		end

		if d.requiredMissionId then
			local done = type(isMissionCompletedFn) == "function" and isMissionCompletedFn(d.requiredMissionId) or false
			if not done then
				return false, string.format("%s: Complete %s first", d.displayName, d.requiredMissionId)
			end
		end

		if d.requiredBossId then
			local bossDone = floorClearanceService and floorClearanceService.isBossDefeated(d.requiredBossId) or false
			if not bossDone then
				return false, string.format("%s: Sealed until %s is defeated", d.displayName, d.requiredBossId)
			end
		end

		if (d.requiredClearance or 0) > 0 then
			local tier = floorClearanceService and floorClearanceService.getEffectiveTier() or 0
			if tier < d.requiredClearance then
				return false, string.format("%s: Requires Clearance Tier %d (Current: Tier %d)", d.displayName, d.requiredClearance, tier)
			end
		end

		if d.requiredKey then
			local hasKey = keyItemService and keyItemService.hasTeamItem(d.requiredKey, 1) or false
			if not hasKey then
				return false, string.format("%s: Requires %s", d.displayName, d.requiredKey)
			end
		end

		return true, "Requirements met"
	end

	function service.canAccess(doorId, playerContext)
		local d = doors[doorId]
		if not d then
			return false, "Unknown door: " .. tostring(doorId)
		end
		playerContext = playerContext or {}
		if playerContext.isDowned or playerContext.isDead then
			return false, "Incapacitated players cannot open doors"
		end
		if d.unlocked then
			return true, "Unlocked"
		end
		return evaluateRequirements(d, playerContext)
	end

	function service.attemptAccess(doorId, playerContext, opts)
		local d = doors[doorId]
		if not d then
			return false, "Unknown door: " .. tostring(doorId), nil
		end
		playerContext = playerContext or {}
		if playerContext.isDowned or playerContext.isDead then
			return false, "Incapacitated players cannot operate doors", nil
		end

		local userId = playerContext.userId or 0
		local playerName = playerContext.playerName or ("Player_" .. tostring(userId))
		opts = opts or {}

		local okLock, lockErr = acquireDoorLock(doorId, userId)
		if not okLock then
			return false, lockErr, { busy = true }
		end

		-- Guaranteed lock release regardless of branch
		local function finish(success, msg, meta)
			releaseDoorLock(doorId, userId)
			return success, msg, meta
		end

		if d.unlocked then
			if opts.toggleIfUnlocked then
				d.isOpen = not d.isOpen
				if type(d.onStateChanged) == "function" then
					pcall(d.onStateChanged, d)
				end
				return finish(true, d.isOpen and (d.displayName .. " opened") or (d.displayName .. " closed"), {
					unlockedNow = false,
					isOpen = d.isOpen,
					keyConsumed = false,
				})
			end
			return finish(true, d.displayName .. " already unlocked", {
				unlockedNow = false,
				isOpen = d.isOpen,
				keyConsumed = false,
			})
		end

		local reqOk, reqReason = evaluateRequirements(d, playerContext)
		if not reqOk then
			-- Explicitly ZERO key consumption on failed requirement
			return finish(false, reqReason, {
				unlockedNow = false,
				isOpen = d.isOpen,
				keyConsumed = false,
			})
		end

		local bypass = (playerContext.devBypass == true) or (floorClearanceService and floorClearanceService.isDevBypass())
		local keyConsumed = false
		local consumedFromUserId = nil

		-- Consume key ONLY when consumeKey == true AND we are not on dev bypass.
		if d.requiredKey and d.consumeKey == true and not bypass then
			if not keyItemService then
				return finish(false, "KeyItemService unavailable", { keyConsumed = false })
			end
			local cOk, cMsg, cUid = keyItemService.consumeItem(userId, d.requiredKey, 1, { requireDirectHolder = false })
			if not cOk then
				return finish(false, cMsg or ("Missing " .. tostring(d.requiredKey)), { keyConsumed = false })
			end
			keyConsumed = true
			consumedFromUserId = cUid
		end

		d.unlocked = true
		d.isOpen = true
		d.unlockedBy = playerName
		if type(d.onStateChanged) == "function" then
			pcall(d.onStateChanged, d)
		end

		local successMsg = string.format("%s unlocked by %s", d.displayName, playerName)
		if keyConsumed then
			successMsg ..= string.format(" (%s used)", tostring(d.requiredKey))
		end

		return finish(true, successMsg, {
			unlockedNow = true,
			isOpen = true,
			keyConsumed = keyConsumed,
			consumedItem = keyConsumed and d.requiredKey or nil,
			consumedFromUserId = consumedFromUserId,
		})
	end

	function service.forceUnlock(doorId, reason)
		local d = doors[doorId]
		if not d then
			return false, "Unknown door: " .. tostring(doorId)
		end
		d.unlocked = true
		d.isOpen = true
		d.unlockedBy = reason or "DEV"
		if type(d.onStateChanged) == "function" then
			pcall(d.onStateChanged, d)
		end
		return true, d.displayName .. " unlocked (" .. tostring(reason or "System") .. ")"
	end

	function service.forceLock(doorId, reason)
		local d = doors[doorId]
		if not d then
			return false, "Unknown door: " .. tostring(doorId)
		end
		d.unlocked = false
		d.isOpen = false
		d.unlockedBy = nil
		if type(d.onStateChanged) == "function" then
			pcall(d.onStateChanged, d)
		end
		return true, d.displayName .. " locked (" .. tostring(reason or "System") .. ")"
	end

	function service.resetAll()
		localLocks = {}
		for _, d in pairs(doors) do
			d.unlocked = d.startsUnlocked == true
			d.isOpen = false
			d.unlockedBy = nil
			if type(d.onStateChanged) == "function" then
				pcall(d.onStateChanged, d)
			end
		end
	end

	return service
end

return DoorAccessService
