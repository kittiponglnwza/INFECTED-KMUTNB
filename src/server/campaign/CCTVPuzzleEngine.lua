-- Server-side M1 CCTV Timeline Puzzle Engine.
-- Holds incident variants, chronological answers, and submission validation on the SERVER ONLY.
-- Clients receive scrambled frame descriptions & environmental clue metadata, never answer keys.

local CCTVPuzzleEngine = {}

local VARIANTS = {
	{
		variantId = "V1_BLACKOUT_BREACH",
		environmentalClues = {
			{
				id = "CLUE_LOG_LOBBY",
				locationName = "F1 Reception Logbook (Center Atrium)",
				title = "INCIDENT LOG // SECURITY SHIFT A",
				body = table.concat({
					"[02:12] Perimeter West Gate motion sensor tripped first while Parking floodlights were ON.",
					"[02:16] Branch Manager Phatcharee carried the Security Keycard inside Bangkok Bank Manager's Office before sealing the door.",
					"[02:20] Atrium Power Conduit shorted out -> heavy static knocked out Camera timestamps.",
					"[02:24] Auto-lock sealed Room 102 Steel Bulkhead under Red Strobe.",
				}, "\n"),
			},
			{
				id = "CLUE_MEMO_CORRIDOR",
				locationName = "Parking Corridor Wall Memo (Near Room 102)",
				title = "TECH NOTE // CCTV RECORDER RECOVERY",
				body = table.concat({
					"Power arc tore the clock chips on all 4 F1 feeds.",
					"Chronology rule: Parking West Gate -> Bank Teller Retreat -> Conduit Arc Flash -> Room 102 Bulkhead Seal.",
				}, "\n"),
			},
		},
		frames = {
			{
				id = "CLIP_PARKING_WEST",
				camLabel = "CAM-01 // PARKING WEST GATE",
				caption = "Motion triggers by loading bay shutter. Overhead white floodlights remain steady.",
				timeStampLabel = "02:?? (SIGNAL OK)",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#3D7EA6",
				chronologicalIndex = 1,
			},
			{
				id = "CLIP_BANK_COUNTER",
				camLabel = "CAM-03 // BANGKOK BANK LOBBY",
				caption = "Branch Manager sprints past teller glass with revolver and glowing Security Keycard, locking the Manager's Office behind her.",
				timeStampLabel = "02:?? (SIGNAL OK)",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#2E6F9E",
				chronologicalIndex = 2,
			},
			{
				id = "CLIP_POWER_CONDUIT",
				camLabel = "CAM-02 // ATRIUM CONDUIT BOX",
				caption = "Violent electrical arc plunges Building 40 F1 into darkness; video tears with static.",
				timeStampLabel = "ERR://CORRUPT",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#B37A29",
				chronologicalIndex = 3,
			},
			{
				id = "CLIP_ROOM102_SEAL",
				camLabel = "CAM-04 // ROOM 102 CORRIDOR",
				caption = "Reinforced Security Door slams shut under pulsing red emergency beacon.",
				timeStampLabel = "LOCKED // --:--",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#9E343B",
				chronologicalIndex = 4,
			},
		},
	},
	{
		variantId = "V2_CANTEEN_EVAC",
		environmentalClues = {
			{
				id = "CLUE_LOG_LOBBY",
				locationName = "F1 Reception Logbook (Center Atrium)",
				title = "INCIDENT LOG // SECURITY SHIFT B",
				body = table.concat({
					"[02:05] Electrical arc fried Atrium Conduit Box first, killing normal lighting.",
					"[02:09] Under emergency glow, infected breached West Gate shutter into Parking.",
					"[02:13] Branch Manager bolted into Bangkok Bank Manager's Office holding the master Security Keycard.",
					"[02:17] Final automated protocol sealed Room 102 Security Control.",
				}, "\n"),
			},
			{
				id = "CLUE_MEMO_CORRIDOR",
				locationName = "Parking Corridor Wall Memo (Near Room 102)",
				title = "TECH NOTE // CCTV RECORDER RECOVERY",
				body = table.concat({
					"Shift B sequence: Power Arc Blackout occurred FIRST before gate breach.",
					"Chronology rule: Conduit Arc -> Parking West Breach -> Bank Counter Retreat -> Room 102 Seal.",
				}, "\n"),
			},
		},
		frames = {
			{
				id = "CLIP_POWER_CONDUIT",
				camLabel = "CAM-02 // ATRIUM CONDUIT BOX",
				caption = "Sudden overload sparks across F1 conduit panel; corridor drops into blackout.",
				timeStampLabel = "ERR://CORRUPT",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#B37A29",
				chronologicalIndex = 1,
			},
			{
				id = "CLIP_PARKING_WEST",
				camLabel = "CAM-01 // PARKING WEST GATE",
				caption = "Silhouettes force open West Gate inside dark emergency-lit parking aisle.",
				timeStampLabel = "02:?? (SIGNAL OK)",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#3D7EA6",
				chronologicalIndex = 2,
			},
			{
				id = "CLIP_BANK_COUNTER",
				camLabel = "CAM-03 // BANGKOK BANK LOBBY",
				caption = "Flashlight beam sweeps teller hall; Manager's Office deadbolt snaps shut with Security Keycard inside.",
				timeStampLabel = "02:?? (SIGNAL OK)",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#2E6F9E",
				chronologicalIndex = 3,
			},
			{
				id = "CLIP_ROOM102_SEAL",
				camLabel = "CAM-04 // ROOM 102 CORRIDOR",
				caption = "Room 102 Security Control deadbolt engages, isolating CCTV servers inside.",
				timeStampLabel = "LOCKED // --:--",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#9E343B",
				chronologicalIndex = 4,
			},
		},
	},
	{
		variantId = "V3_BANK_ALARM",
		environmentalClues = {
			{
				id = "CLUE_LOG_LOBBY",
				locationName = "F1 Reception Logbook (Center Atrium)",
				title = "INCIDENT LOG // SECURITY SHIFT C",
				body = table.concat({
					"[01:58] Silent Teller Panic Switch triggered near Bangkok Bank Desk; Manager sealed Keycard inside Branch Office.",
					"[02:02] Emergency lockdown sealed Room 102 Control BEFORE West Gate fell.",
					"[02:06] East Atrium Conduit shorted from surge overload.",
					"[02:11] West Parking Gate collapsed last as horde flooded Floor 1.",
				}, "\n"),
			},
			{
				id = "CLUE_MEMO_CORRIDOR",
				locationName = "Parking Corridor Wall Memo (Near Room 102)",
				title = "TECH NOTE // CCTV RECORDER RECOVERY",
				body = table.concat({
					"Shift C alarm replay confirms Room 102 locked BEFORE conduit failure and West Gate fall.",
					"Chronology rule: Bank Panic Keycard -> Room 102 Seal -> Conduit Surge -> Parking West Collapse.",
				}, "\n"),
			},
		},
		frames = {
			{
				id = "CLIP_BANK_COUNTER",
				camLabel = "CAM-03 // BANGKOK BANK LOBBY",
				caption = "Panic indicator blinks at teller booth while Branch Manager retreats inside Office with Security Keycard.",
				timeStampLabel = "01:?? (SIGNAL OK)",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#2E6F9E",
				chronologicalIndex = 1,
			},
			{
				id = "CLIP_ROOM102_SEAL",
				camLabel = "CAM-04 // ROOM 102 CORRIDOR",
				caption = "Early security protocol seals Room 102 bulkhead with floor lights still glowing.",
				timeStampLabel = "LOCKED // --:--",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#9E343B",
				chronologicalIndex = 2,
			},
			{
				id = "CLIP_POWER_CONDUIT",
				camLabel = "CAM-02 // ATRIUM CONDUIT BOX",
				caption = "Backup relay arcs wildly; lobby plunges into backup emergency strobes.",
				timeStampLabel = "ERR://CORRUPT",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#B37A29",
				chronologicalIndex = 3,
			},
			{
				id = "CLIP_PARKING_WEST",
				camLabel = "CAM-01 // PARKING WEST GATE",
				caption = "West rolling gate buckles inward last, letting infected spill into the lot.",
				timeStampLabel = "02:?? (SIGNAL OK)",
				prototypeTag = "PROTOTYPE CCTV STILL // PLACEHOLDER",
				colorHex = "#3D7EA6",
				chronologicalIndex = 4,
			},
		},
	},
}

local SCRAMBLE_PERMUTATIONS = {
	{ 3, 1, 4, 2 },
	{ 4, 2, 1, 3 },
	{ 2, 4, 3, 1 },
}

function CCTVPuzzleEngine.create(options)
	options = options or {}
	local clockFn = options.clockFn or os.clock
	local randomFn = options.randomFn or math.random
	local wrongCooldown = options.wrongCooldownSeconds or 4.0

	local engine = {}
	local activeVariant = nil
	local secretOrder = {}
	local publicFrames = {}
	local solved = false
	local attempts = 0
	local lastWrongAtByUserId = {}

	function engine.reset(variantIndexOverride)
		local vIdx = variantIndexOverride
		if type(vIdx) ~= "number" or not VARIANTS[vIdx] then
			vIdx = randomFn(1, #VARIANTS)
		end
		activeVariant = VARIANTS[vIdx]
		solved = false
		attempts = 0
		table.clear(lastWrongAtByUserId)

		-- Store chronological answer strictly server-side
		secretOrder = {}
		local sorted = {}
		for _, frame in ipairs(activeVariant.frames) do
			table.insert(sorted, frame)
		end
		table.sort(sorted, function(a, b)
			return a.chronologicalIndex < b.chronologicalIndex
		end)
		for idx, frame in ipairs(sorted) do
			secretOrder[idx] = frame.id
		end

		-- Build sanitized display frames in deterministic non-answer order (never includes chronologicalIndex)
		local perm = SCRAMBLE_PERMUTATIONS[((vIdx - 1) % #SCRAMBLE_PERMUTATIONS) + 1]
		publicFrames = {}
		for displaySlot, srcIdx in ipairs(perm) do
			local src = sorted[srcIdx]
			publicFrames[displaySlot] = {
				id = src.id,
				camLabel = src.camLabel,
				caption = src.caption,
				timeStampLabel = src.timeStampLabel,
				prototypeTag = src.prototypeTag,
				colorHex = src.colorHex,
			}
		end
	end

	function engine.isSolved()
		return solved
	end

	function engine.getVariantId()
		return activeVariant and activeVariant.variantId or ""
	end

	function engine.getClues()
		if not activeVariant then
			return {}
		end
		local out = {}
		for _, c in ipairs(activeVariant.environmentalClues) do
			table.insert(out, {
				id = c.id,
				locationName = c.locationName,
				title = c.title,
				body = c.body,
			})
		end
		return out
	end

	-- Safe payload for clients: NEVER exposes secretOrder or chronologicalIndex.
	function engine.getClientModalPayload()
		local frameCopies = {}
		for i, f in ipairs(publicFrames) do
			frameCopies[i] = {
				id = f.id,
				camLabel = f.camLabel,
				caption = f.caption,
				timeStampLabel = f.timeStampLabel,
				prototypeTag = f.prototypeTag,
				colorHex = f.colorHex,
			}
		end
		return {
			puzzleId = "M1_CCTV_TIMELINE",
			title = "CCTV TIMELINE RECONSTRUCTION // ROOM 102",
			subtitle = "Arrange the 4 corrupted F1 camera clips from EARLIEST (1) to LATEST (4). Check F1 Incident Logs for exact sequence.",
			prototypeNotice = "PROTOTYPE UI // PLACEHOLDER CCTV FOOTAGE STILLS",
			frames = frameCopies,
			solved = solved,
			attempts = attempts,
		}
	end

	-- Server-only test inspection helper (never sent across remotes).
	function engine.getServerAnswerDebug()
		local copy = {}
		for i, id in ipairs(secretOrder) do
			copy[i] = id
		end
		return copy
	end

	function engine.forceSolvedByDev()
		solved = true
	end

	function engine.validateSubmission(userId, submittedIds)
		if solved then
			return {
				ok = false,
				solved = true,
				matchedCount = #secretOrder,
				cooldownRemaining = 0,
				attemptsUsed = attempts,
				message = "CCTV Timeline has already been verified.",
			}
		end

		local now = clockFn()
		local lastWrong = lastWrongAtByUserId[userId]
		if lastWrong and (now - lastWrong) < wrongCooldown then
			local remain = math.ceil((wrongCooldown - (now - lastWrong)) * 10) / 10
			return {
				ok = false,
				solved = false,
				matchedCount = 0,
				cooldownRemaining = remain,
				attemptsUsed = attempts,
				message = string.format("System locked after invalid timeline. Wait %.1fs.", remain),
			}
		end

		if type(submittedIds) ~= "table" or #submittedIds ~= #secretOrder then
			return {
				ok = false,
				solved = false,
				matchedCount = 0,
				cooldownRemaining = 0,
				attemptsUsed = attempts,
				message = "Invalid submission: select all 4 CCTV timeline slots.",
			}
		end

		local validIdSet = {}
		for _, id in ipairs(secretOrder) do
			validIdSet[id] = true
		end

		local seen = {}
		for i = 1, #secretOrder do
			local clipId = submittedIds[i]
			if type(clipId) ~= "string" or not validIdSet[clipId] or seen[clipId] then
				return {
					ok = false,
					solved = false,
					matchedCount = 0,
					cooldownRemaining = 0,
					attemptsUsed = attempts,
					message = "Malformed sequence: each clip must appear exactly once.",
				}
			end
			seen[clipId] = true
		end

		attempts = attempts + 1
		local matched = 0
		for i = 1, #secretOrder do
			if submittedIds[i] == secretOrder[i] then
				matched = matched + 1
			end
		end

		if matched == #secretOrder then
			solved = true
			return {
				ok = true,
				solved = true,
				matchedCount = matched,
				cooldownRemaining = 0,
				attemptsUsed = attempts,
				message = "TIMELINE VERIFIED // Security Control Override console is now unlocked!",
			}
		end

		lastWrongAtByUserId[userId] = now
		return {
			ok = true,
			solved = false,
			matchedCount = matched,
			cooldownRemaining = wrongCooldown,
			attemptsUsed = attempts,
			message = string.format("Mismatch (%d/4 positions correct). Check F1 Incident Logs. Retry in %.0fs.", matched, wrongCooldown),
		}
	end

	engine.reset(options.variantIndex)
	return engine
end

return CCTVPuzzleEngine
