-- Dual-Mode Zombie Director Engine (CAMPAIGN MODE vs WAVE / TEST MODE).
-- Pure-Luau state machine & spatial spawn validator:
--   - Campaign Mode (default): Ambient, Roaming, Noise-reactive, Objective, and Boss channels
--     with strict max-alive caps, min player distance, zombie anti-overlap, and player LOS guards.
--   - Wave Mode (!wave): Preserves classic Survival wave loop in an isolated state partition.

local ZombieDirector = {}

local function getXYZ(v)
	if v == nil then
		return 0, 0, 0
	end
	local t = typeof and typeof(v) or type(v)
	if t == "Vector3" or (type(v) == "userdata") then
		return v.X, v.Y, v.Z
	end
	return v.X or v.x or v[1] or 0, v.Y or v.y or v[2] or 0, v.Z or v.z or v[3] or 0
end

local function distanceBetween(a, b)
	local ax, ay, az = getXYZ(a)
	local bx, by, bz = getXYZ(b)
	local dx, dy, dz = ax - bx, ay - by, az - bz
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function isFacingAndVisible(playerView, spawnPos, hasLineOfSightFn)
	local eyePos = playerView.eyePos or playerView.pos or playerView.position
	if not eyePos then
		return false
	end
	local lookVec = playerView.lookVector
	local dist = distanceBetween(eyePos, spawnPos)
	if dist < 8 then
		return true
	end
	if lookVec then
		local ex, ey, ez = getXYZ(eyePos)
		local sx, sy, sz = getXYZ(spawnPos)
		local lx, ly, lz = getXYZ(lookVec)
		local dx, dy, dz = sx - ex, sy - ey, sz - ez
		local mag = math.sqrt(dx * dx + dy * dy + dz * dz)
		if mag > 0.001 then
			local lmag = math.sqrt(lx * lx + ly * ly + lz * lz)
			if lmag > 0.001 then
				local dot = ((dx * lx) + (dy * ly) + (dz * lz)) / (mag * lmag)
				-- Outside 72-degree half-angle cone (~0.31): player isn't looking toward spawn point
				if dot < 0.31 then
					return false
				end
			end
		end
	end
	if type(hasLineOfSightFn) == "function" then
		return hasLineOfSightFn(eyePos, spawnPos) == true
	end
	return false
end

function ZombieDirector.create(deps)
	deps = deps or {}
	local clockFn = deps.clockFn or os.clock
	local hasLineOfSightFn = deps.hasLineOfSightFn

	local config = {
		maxAliveCampaign = deps.maxAliveCampaign or 16,
		maxAliveWave = deps.maxAliveWave or 28,
		ambientCap = deps.ambientCap or 7,
		roamCap = deps.roamCap or 4,
		noiseCap = deps.noiseCap or 5,
		minPlayerDist = deps.minPlayerDist or 24,
		maxPlayerDist = deps.maxPlayerDist or 145,
		minZombieSpacing = deps.minZombieSpacing or 4.5,
		noiseThreshold = deps.noiseThreshold or 35,
		noiseDecayPerSec = deps.noiseDecayPerSec or 4.5,
		noiseSpawnCooldown = deps.noiseSpawnCooldown or 9.0,
		roamCooldown = deps.roamCooldown or 14.0,
		ambientCooldown = deps.ambientCooldown or 8.0,
		maxHordeBurst = deps.maxHordeBurst or 10,
	}

	local mode = "Campaign" -- "Campaign" | "Wave"
	local activeZombies = {} -- [id] = { id, channel, zombieType, mode, floor, encounteredId, bossId, spawnedAt }
	local triggeredEncounters = {}
	local activeBosses = {} -- [bossId] = zombieId
	local defeatedBosses = {}
	local noiseHeat = 0
	local lastNoiseDecayAt = clockFn()
	local lastNoiseSpawnAt = -999
	local lastRoamSpawnAt = -999
	local lastAmbientSpawnAt = -999
	local waveNumber = 0
	local waveRemainingToSpawn = 0
	local nextSerial = 0

	local director = {}

	local function decayNoise(now)
		local dt = math.max(0, now - lastNoiseDecayAt)
		lastNoiseDecayAt = now
		if noiseHeat > 0 then
			noiseHeat = math.max(0, noiseHeat - dt * config.noiseDecayPerSec)
		end
	end

	function director.getConfig()
		return config
	end

	function director.getMode()
		return mode
	end

	function director.setMode(newMode)
		if newMode ~= "Campaign" and newMode ~= "Wave" then
			return false, "Invalid ZombieMode (expected Campaign or Wave)"
		end
		if mode == newMode then
			return true, "Already in " .. mode .. " mode"
		end
		mode = newMode
		noiseHeat = 0
		if newMode == "Wave" then
			waveNumber = 1
			waveRemainingToSpawn = 0
		else
			waveNumber = 0
			waveRemainingToSpawn = 0
		end
		return true, "Switched zombie director to " .. mode .. " mode"
	end

	function director.registerSpawned(id, meta)
		nextSerial += 1
		local key = id or ("Z_" .. tostring(nextSerial))
		meta = meta or {}
		activeZombies[key] = {
			id = key,
			channel = meta.channel or "Ambient",
			zombieType = meta.zombieType or "Shambler",
			mode = meta.mode or mode,
			floor = meta.floor or 1,
			encounterId = meta.encounterId,
			bossId = meta.bossId,
			spawnedAt = clockFn(),
		}
		if meta.bossId then
			activeBosses[meta.bossId] = key
		end
		return key
	end

	function director.unregisterZombie(id, wasKilled)
		local rec = activeZombies[id]
		if not rec then
			return false
		end
		activeZombies[id] = nil
		if rec.bossId and activeBosses[rec.bossId] == id then
			activeBosses[rec.bossId] = nil
			if wasKilled then
				defeatedBosses[rec.bossId] = true
			end
		end
		return true
	end

	function director.getAliveCount(filterChannel, filterMode)
		local n = 0
		for _, rec in pairs(activeZombies) do
			local okMode = (filterMode == nil) or (rec.mode == filterMode)
			local okChan = (filterChannel == nil) or (rec.channel == filterChannel)
			if okMode and okChan then
				n += 1
			end
		end
		return n
	end

	function director.getRemainingCapacity(channel)
		local totalAlive = director.getAliveCount(nil, nil)
		local modeMax = (mode == "Wave") and config.maxAliveWave or config.maxAliveCampaign
		local globalRoom = math.max(0, modeMax - totalAlive)
		if mode ~= "Campaign" or channel == nil then
			return globalRoom
		end
		if channel == "Ambient" then
			return math.min(globalRoom, math.max(0, config.ambientCap - director.getAliveCount("Ambient", "Campaign")))
		elseif channel == "Roaming" then
			return math.min(globalRoom, math.max(0, config.roamCap - director.getAliveCount("Roaming", "Campaign")))
		elseif channel == "Noise" then
			return math.min(globalRoom, math.max(0, config.noiseCap - director.getAliveCount("Noise", "Campaign")))
		elseif channel == "Objective" or channel == "Boss" then
			return globalRoom
		end
		return globalRoom
	end

	-- Spatial validator checking min/max distance from players, anti-overlap against existing zombies,
	-- and optional player Line-Of-Sight / FOV check so Campaign zombies never pop in right in front of eyes.
	function director.evaluateSpawnPoint(candidatePos, playerViews, existingZombiePositions, opts)
		opts = opts or {}
		local minDist = opts.minPlayerDist or config.minPlayerDist
		local maxDist = opts.maxPlayerDist or config.maxPlayerDist
		local minZDist = opts.minZombieSpacing or config.minZombieSpacing
		local checkVisibility = opts.requireOutOfSight ~= false

		playerViews = playerViews or {}
		existingZombiePositions = existingZombiePositions or {}

		local closestPlayerDist = math.huge
		local insideMin = false
		local visibleToAny = false

		for _, pv in ipairs(playerViews) do
			local pPos = pv.pos or pv.eyePos or pv.position
			if pPos then
				local d = distanceBetween(pPos, candidatePos)
				if d < closestPlayerDist then
					closestPlayerDist = d
				end
				if d < minDist then
					insideMin = true
					break
				end
				if checkVisibility and isFacingAndVisible(pv, candidatePos, opts.hasLineOfSightFn or hasLineOfSightFn) then
					visibleToAny = true
				end
			end
		end

		if insideMin then
			return false, "too_close_to_player"
		end
		if #playerViews > 0 and closestPlayerDist > maxDist then
			return false, "too_far_from_players"
		end
		if checkVisibility and visibleToAny then
			return false, "visible_to_player"
		end

		for _, zPos in ipairs(existingZombiePositions) do
			if distanceBetween(zPos, candidatePos) < minZDist then
				return false, "overlaps_existing_zombie"
			end
		end

		return true, "ok", closestPlayerDist
	end

	function director.selectBestSpawnPoint(candidates, playerViews, existingZombiePositions, opts)
		local best = nil
		local bestScore = math.huge
		local lastReason = "no_candidates"
		for _, cand in ipairs(candidates or {}) do
			local pos = type(cand) == "table" and cand.pos or cand
			local ok, reason, dist = director.evaluateSpawnPoint(pos, playerViews, existingZombiePositions, opts)
			if ok then
				-- Prefer nearest valid out-of-sight distance that isn't trivially far
				local score = math.abs((dist or 55) - 52)
				if score < bestScore then
					bestScore = score
					best = cand
				end
			else
				lastReason = reason
			end
		end
		return best, lastReason
	end

	function director.getNoiseHeat()
		decayNoise(clockFn())
		return noiseHeat
	end

	function director.recordNoise(origin, noiseWeight, sourceName)
		local now = clockFn()
		decayNoise(now)
		local weight = math.max(0, tonumber(noiseWeight) or 0)
		noiseHeat = math.min(120, noiseHeat + weight)

		if mode ~= "Campaign" then
			return { triggered = false, reason = "not_campaign_mode", noiseHeat = noiseHeat }
		end
		if noiseHeat < config.noiseThreshold then
			return { triggered = false, reason = "below_threshold", noiseHeat = noiseHeat }
		end
		if (now - lastNoiseSpawnAt) < config.noiseSpawnCooldown then
			return { triggered = false, reason = "cooldown", noiseHeat = noiseHeat }
		end
		local room = director.getRemainingCapacity("Noise")
		if room <= 0 then
			return { triggered = false, reason = "cap_reached", noiseHeat = noiseHeat }
		end

		lastNoiseSpawnAt = now
		local count = math.min(room, noiseHeat >= 75 and 3 or 2)
		noiseHeat = math.max(0, noiseHeat - 30)
		return {
			triggered = true,
			channel = "Noise",
			source = sourceName or "Gunfire",
			origin = origin,
			count = count,
			noiseHeat = noiseHeat,
		}
	end

	function director.requestAmbientTick()
		local now = clockFn()
		if mode ~= "Campaign" then
			return { shouldSpawn = false, reason = "not_campaign_mode", count = 0 }
		end
		if (now - lastAmbientSpawnAt) < config.ambientCooldown then
			return { shouldSpawn = false, reason = "cooldown", count = 0 }
		end
		local room = director.getRemainingCapacity("Ambient")
		if room <= 0 then
			return { shouldSpawn = false, reason = "cap_reached", count = 0 }
		end
		lastAmbientSpawnAt = now
		return {
			shouldSpawn = true,
			channel = "Ambient",
			count = math.min(room, 2),
		}
	end

	function director.requestRoamingTick()
		local now = clockFn()
		if mode ~= "Campaign" then
			return { shouldSpawn = false, reason = "not_campaign_mode", count = 0 }
		end
		if (now - lastRoamSpawnAt) < config.roamCooldown then
			return { shouldSpawn = false, reason = "cooldown", count = 0 }
		end
		local room = director.getRemainingCapacity("Roaming")
		if room <= 0 then
			return { shouldSpawn = false, reason = "cap_reached", count = 0 }
		end
		lastRoamSpawnAt = now
		return {
			shouldSpawn = true,
			channel = "Roaming",
			count = math.min(room, 2),
		}
	end

	function director.triggerObjectiveEncounter(encounterId, requestedCount, opts)
		opts = opts or {}
		local eid = tostring(encounterId or "ENCOUNTER")
		if triggeredEncounters[eid] and opts.force ~= true then
			return { triggered = false, reason = "already_triggered", count = 0 }
		end
		local room = director.getRemainingCapacity("Objective")
		local wanted = math.max(1, math.min(math.floor(tonumber(requestedCount) or 2), config.maxHordeBurst))
		local actual = opts.ignoreCap and wanted or math.min(wanted, room)
		if actual <= 0 then
			return { triggered = false, reason = "cap_reached", count = 0 }
		end
		triggeredEncounters[eid] = true
		return {
			triggered = true,
			channel = "Objective",
			encounterId = eid,
			count = actual,
		}
	end

	function director.triggerHorde(requestedCount)
		local room = director.getRemainingCapacity(nil)
		local wanted = math.max(1, math.min(math.floor(tonumber(requestedCount) or 5), config.maxHordeBurst))
		local actual = math.min(wanted, room)
		if actual <= 0 then
			return { triggered = false, reason = "cap_reached", count = 0 }
		end
		return {
			triggered = true,
			channel = (mode == "Wave") and "Wave" or "Noise",
			count = actual,
		}
	end

	function director.requestBossSpawn(bossId, zombieType)
		local bid = string.upper(tostring(bossId or "SUBJECT_ZERO"))
		if activeBosses[bid] ~= nil then
			return { triggered = false, reason = "boss_already_active" }
		end
		if defeatedBosses[bid] == true then
			return { triggered = false, reason = "boss_already_defeated" }
		end
		return {
			triggered = true,
			channel = "Boss",
			bossId = bid,
			zombieType = zombieType or "Brute",
		}
	end

	-- Wave mode helpers (isolated from Campaign Mode)
	function director.setWaveState(waveNum, remaining)
		if mode ~= "Wave" then
			return false
		end
		waveNumber = waveNum or waveNumber
		waveRemainingToSpawn = remaining or waveRemainingToSpawn
		return true
	end

	function director.getWaveState()
		return {
			active = (mode == "Wave"),
			waveNumber = waveNumber,
			remaining = waveRemainingToSpawn,
		}
	end

	function director.resetAll(targetMode)
		activeZombies = {}
		triggeredEncounters = {}
		activeBosses = {}
		defeatedBosses = {}
		noiseHeat = 0
		lastNoiseDecayAt = clockFn()
		lastNoiseSpawnAt = -999
		lastRoamSpawnAt = -999
		lastAmbientSpawnAt = -999
		waveNumber = (targetMode == "Wave") and 1 or 0
		waveRemainingToSpawn = 0
		if targetMode == "Campaign" or targetMode == "Wave" then
			mode = targetMode
		end
	end

	function director.getStatsSnapshot()
		return {
			mode = mode,
			aliveTotal = director.getAliveCount(nil, nil),
			aliveCampaign = director.getAliveCount(nil, "Campaign"),
			aliveWave = director.getAliveCount(nil, "Wave"),
			aliveAmbient = director.getAliveCount("Ambient", nil),
			aliveRoaming = director.getAliveCount("Roaming", nil),
			aliveNoise = director.getAliveCount("Noise", nil),
			aliveObjective = director.getAliveCount("Objective", nil),
			aliveBoss = director.getAliveCount("Boss", nil),
			noiseHeat = math.floor(director.getNoiseHeat() + 0.5),
			waveNumber = waveNumber,
			maxAliveCampaign = config.maxAliveCampaign,
			maxAliveWave = config.maxAliveWave,
		}
	end

	return director
end

return ZombieDirector
