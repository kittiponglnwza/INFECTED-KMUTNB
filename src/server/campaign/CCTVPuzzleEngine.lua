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
				locationName = "สมุดบันทึกรับเรื่องชั้น 1 (โถงกลางอาคาร 40)",
				title = "บันทึกเหตุการณ์ // กะ รปภ. ชุด A",
				body = table.concat({
					"[02:12] เซนเซอร์กล้อง CAM-01 ประตูลานจอดฝั่งตะวันตกดังขึ้นเป็นจุดแรก ขณะไฟสนามยังเปิดอยู่",
					"[02:16] กล้อง CAM-03 จับภาพผู้จัดการพัชรีถือคีย์การ์ดวิ่งหนีผ่านเคาน์เตอร์ธนาคารก่อนปิดล็อกห้อง",
					"[02:20] กล้อง CAM-02 บันทึกตู้สายไฟหลักโถงกลางช็อตจนเกิดประกายไฟ — เวลากล้องทุกตัวรวนทันที",
					"[02:24] กล้อง CAM-04 ประตูนิรภัยห้องควบคุม 102 ปิดล็อกอัตโนมัติใต้แสงไฟฉุกเฉินสีแดง",
				}, "\n"),
			},
			{
				id = "CLUE_MEMO_CORRIDOR",
				locationName = "กระดาษโน้ตเจ้าหน้าที่เทคนิค (ทางเดินหน้าห้อง 102)",
				title = "บันทึกช่างเทคนิค // กู้ข้อมูลไทม์ไลน์ CCTV",
				body = table.concat({
					"ไฟกระชากทำให้ตัวนับเวลาของกล้องทั้ง 4 ตัวพัง (ERR://CORRUPT)",
					"ลำดับเหตุการณ์จริง: CAM-01 ประตูตะวันตก -> CAM-03 โถงธนาคาร -> CAM-02 ตู้ไฟช็อต -> CAM-04 ปิดตายห้อง 102",
				}, "\n"),
			},
		},
		frames = {
			{
				id = "CLIP_PARKING_WEST",
				camLabel = "CAM-01 // ประตูฝั่งตะวันตกลานจอดรถ",
				caption = "เซนเซอร์จับการเคลื่อนไหวทำงานหน้าม่านเหล็ก ขณะไฟฟลัดไลต์ยังติดสว่างปกติ",
				timeStampLabel = "02:?? (สัญญาณปกติ)",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
				colorHex = "#3D7EA6",
				chronologicalIndex = 1,
			},
			{
				id = "CLIP_BANK_COUNTER",
				camLabel = "CAM-03 // โถงเคาน์เตอร์ธนาคารกรุงเทพ",
				caption = "ผู้จัดการสาขาถือปืนลูกโม่และคีย์การ์ดวิ่งผ่านหน้าเคาน์เตอร์เข้าไปล็อกประตูห้องผู้จัดการ",
				timeStampLabel = "02:?? (สัญญาณปกติ)",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
				colorHex = "#2E6F9E",
				chronologicalIndex = 2,
			},
			{
				id = "CLIP_POWER_CONDUIT",
				camLabel = "CAM-02 // ตู้เมนสายไฟโถงกลาง (Atrium)",
				caption = "กระแสไฟฟ้าระเบิดลัดวงจร ทำให้อาคาร 40 ชั้น 1 มืดสนิทและสัญญาณภาพแตกซ่า",
				timeStampLabel = "ERR://CORRUPT",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
				colorHex = "#B37A29",
				chronologicalIndex = 3,
			},
			{
				id = "CLIP_ROOM102_SEAL",
				camLabel = "CAM-04 // ทางเดินหน้าห้อง 102",
				caption = "ประตูเหล็กนิรภัยห้องควบคุม 102 สับสลักปิดตายอัตโนมัติพร้อมไฟเตือนภัยกะพริบ",
				timeStampLabel = "LOCKED // --:--",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
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
				locationName = "สมุดบันทึกรับเรื่องชั้น 1 (โถงกลางอาคาร 40)",
				title = "บันทึกเหตุการณ์ // กะ รปภ. ชุด B",
				body = table.concat({
					"[02:05] กล้อง CAM-02 ตู้สายไฟโถงกลางระเบิดลัดวงจรเป็นเหตุการณ์แรก จนไฟหลักทั้งตึกดับ",
					"[02:09] กล้อง CAM-01 ใต้แสงสลัว กลุ่มผู้ติดเชื้องัดม่านเหล็กฝั่งตะวันตกบุกเข้าลานจอดชั้น 1",
					"[02:13] กล้อง CAM-03 ผู้จัดการสาขารีบวิ่งล็อกตัวในห้องธนาคารพร้อมคีย์การ์ดห้อง 102",
					"[02:17] กล้อง CAM-04 ระบบนิรภัยตัดสวิตช์ล็อกประตูห้องควบคุม 102 ปิดฉากการสื่อสาร",
				}, "\n"),
			},
			{
				id = "CLUE_MEMO_CORRIDOR",
				locationName = "กระดาษโน้ตเจ้าหน้าที่เทคนิค (ทางเดินหน้าห้อง 102)",
				title = "บันทึกช่างเทคนิค // กู้ข้อมูลไทม์ไลน์ CCTV",
				body = table.concat({
					"รายงานกะ B ยืนยันว่าไฟดับจากตู้ไฟโถงกลางเกิดขึ้นก่อนการบุกรุกประตูด้านนอก!",
					"ลำดับเหตุการณ์จริง: CAM-02 ตู้ไฟระเบิด -> CAM-01 บุกลานจอด -> CAM-03 ล็อกธนาคาร -> CAM-04 ปิดตายห้อง 102",
				}, "\n"),
			},
		},
		frames = {
			{
				id = "CLIP_POWER_CONDUIT",
				camLabel = "CAM-02 // ตู้เมนสายไฟโถงกลาง (Atrium)",
				caption = "ประกายไฟลัดวงจรปะทุรุนแรงจากตู้จ่ายไฟหลักก่อนระบบแสงสว่างดับทั้งชั้น",
				timeStampLabel = "ERR://CORRUPT",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
				colorHex = "#B37A29",
				chronologicalIndex = 1,
			},
			{
				id = "CLIP_PARKING_WEST",
				camLabel = "CAM-01 // ประตูฝั่งตะวันตกลานจอดรถ",
				caption = "เงาผู้ติดเชื้อจำนวนมากพังประตูฝั่งตะวันตกเข้ามาท่ามกลางไฟฉุกเฉิน",
				timeStampLabel = "02:?? (สัญญาณปกติ)",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
				colorHex = "#3D7EA6",
				chronologicalIndex = 2,
			},
			{
				id = "CLIP_BANK_COUNTER",
				camLabel = "CAM-03 // โถงเคาน์เตอร์ธนาคารกรุงเทพ",
				caption = "แสงไฟฉายสาดผ่านหน้าตู้ธนาคารขณะประตูห้องผู้จัดการถูกล็อกกลอนแน่น",
				timeStampLabel = "02:?? (สัญญาณปกติ)",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
				colorHex = "#2E6F9E",
				chronologicalIndex = 3,
			},
			{
				id = "CLIP_ROOM102_SEAL",
				camLabel = "CAM-04 // ทางเดินหน้าห้อง 102",
				caption = "ระบบป้องกันห้อง 102 ปิดล็อกประตูเหล็กอัตโนมัติและเปลี่ยนเป็นไฟสำรอง UPS",
				timeStampLabel = "LOCKED // --:--",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
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
				locationName = "สมุดบันทึกรับเรื่องชั้น 1 (โถงกลางอาคาร 40)",
				title = "บันทึกเหตุการณ์ // กะ รปภ. ชุด C",
				body = table.concat({
					"[01:58] กล้อง CAM-03 สัญญาณเงียบหน้าเคาน์เตอร์ธนาคารดังขึ้น ผู้จัดการรีบหนีเข้าห้องพร้อมคีย์การ์ด",
					"[02:02] กล้อง CAM-04 ระบบสั่งปิดประตูนิรภัยห้อง 102 ล่วงหน้าก่อนความโกลาหลจะลาม",
					"[02:06] กล้อง CAM-02 ตู้สายไฟโถงกลางช็อตดับจากกระแสไฟกระชาก",
					"[02:11] กล้อง CAM-01 ประตูม้วนลานจอดรถฝั่งตะวันตกพังเป็นจุดสุดท้ายเปิดทางฝูงซอมบี้",
				}, "\n"),
			},
			{
				id = "CLUE_MEMO_CORRIDOR",
				locationName = "กระดาษโน้ตเจ้าหน้าที่เทคนิค (ทางเดินหน้าห้อง 102)",
				title = "บันทึกช่างเทคนิค // กู้ข้อมูลไทม์ไลน์ CCTV",
				body = table.concat({
					"ไฟล์เตือนภัยกะ C ยืนยันว่าห้อง 102 ล็อกก่อนตู้ไฟดับและก่อนประตูฝั่งตะวันตกพัง",
					"ลำดับเหตุการณ์จริง: CAM-03 ธนาคาร -> CAM-04 ปิดห้อง 102 -> CAM-02 ตู้ไฟช็อต -> CAM-01 ประตูตะวันตกพัง",
				}, "\n"),
			},
		},
		frames = {
			{
				id = "CLIP_BANK_COUNTER",
				camLabel = "CAM-03 // โถงเคาน์เตอร์ธนาคารกรุงเทพ",
				caption = "ไฟสัญญาณเตือนเงียบกะพริบหน้าเคาน์เตอร์ ขณะผู้จัดการหนีเข้าห้องพร้อมคีย์การ์ด",
				timeStampLabel = "01:?? (สัญญาณปกติ)",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
				colorHex = "#2E6F9E",
				chronologicalIndex = 1,
			},
			{
				id = "CLIP_ROOM102_SEAL",
				camLabel = "CAM-04 // ทางเดินหน้าห้อง 102",
				caption = "โปรโตคอลฉุกเฉินล็อกประตูห้องควบคุม 102 ไว้ล่วงหน้าขณะไฟทางเดินยังติดอยู่",
				timeStampLabel = "LOCKED // --:--",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
				colorHex = "#9E343B",
				chronologicalIndex = 2,
			},
			{
				id = "CLIP_POWER_CONDUIT",
				camLabel = "CAM-02 // ตู้เมนสายไฟโถงกลาง (Atrium)",
				caption = "รีเลย์ไฟสำรองระเบิดไฟแลบ ทำให้อาคารมืดเหลือเพียงไฟฉุกเฉินสีแดง",
				timeStampLabel = "ERR://CORRUPT",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
				colorHex = "#B37A29",
				chronologicalIndex = 3,
			},
			{
				id = "CLIP_PARKING_WEST",
				camLabel = "CAM-01 // ประตูฝั่งตะวันตกลานจอดรถ",
				caption = "ม่านเหล็กฝั่งตะวันตกพังยุบเข้ามาเป็นจุดสุดท้าย เปิดทางให้ผู้ติดเชื้อบุกเข้าชั้น 1",
				timeStampLabel = "02:?? (สัญญาณปกติ)",
				prototypeTag = "ภาพจำลองกล้อง CCTV // กด [E] เพื่อเลือกตามลำดับ",
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

	-- Sorted physical Monitor Wall order (CAM-01..CAM-04) without chronological secrets.
	function engine.getMonitorWallClips()
		if not activeVariant then
			return {}
		end
		local list = {}
		for _, src in ipairs(activeVariant.frames) do
			local camId, shortLabel = tostring(src.camLabel or ""):match("^(CAM%-%d+)%s*//%s*(.+)$")
			table.insert(list, {
				id = src.id,
				clipId = src.id,
				camId = camId or tostring(src.id),
				camLabel = src.camLabel,
				label = shortLabel or tostring(src.camLabel or src.id),
				caption = src.caption,
				timeStampLabel = src.timeStampLabel,
				timestampLabel = src.timeStampLabel,
				prototypeTag = src.prototypeTag,
				colorHex = src.colorHex,
			})
		end
		table.sort(list, function(a, b)
			return tostring(a.camLabel) < tostring(b.camLabel)
		end)
		return list
	end

	function engine.getSolvedRank(clipId)
		if not solved or type(secretOrder) ~= "table" then
			return nil
		end
		return table.find(secretOrder, clipId)
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
			title = "กู้คืนไทม์ไลน์กล้อง CCTV // ห้อง 102",
			subtitle = "เรียงลำดับภาพเหตุการณ์ทั้ง 4 กล้องจาก ก่อน (1) ไป หลัง (4) ตามสมุดบันทึกเหตุการณ์ชั้น 1",
			prototypeNotice = "ระบบสำรอง Monitor Wall / Fallback UI",
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
				message = "ไทม์ไลน์กล้อง CCTV ถูกยืนยันเรียบร้อยแล้ว",
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
				message = string.format("ระบบล็อกชั่วคราวหลังเรียงลำดับผิด กรุณารอ %.1f วินาที", remain),
			}
		end

		if type(submittedIds) ~= "table" or #submittedIds ~= #secretOrder then
			return {
				ok = false,
				solved = false,
				matchedCount = 0,
				cooldownRemaining = 0,
				attemptsUsed = attempts,
				message = "ข้อมูลไม่ครบ: กรุณาเลือกกล้องให้ครบทั้ง 4 จุด",
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
					message = "ลำดับไม่ถูกต้อง: ห้ามเลือกกล้องซ้ำกัน",
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
				message = "ยืนยันไทม์ไลน์สำเร็จ // ปลดล็อกตู้ควบคุม Security Override แล้ว!",
			}
		end

		lastWrongAtByUserId[userId] = now
		return {
			ok = true,
			solved = false,
			matchedCount = matched,
			cooldownRemaining = wrongCooldown,
			attemptsUsed = attempts,
			message = string.format("⚠️ ลำดับกล้องผิด (ตรง %d/4 จุด) สัญญาณเตือนดังขึ้น! ลองใหม่ใน %.0f วินาที", matched, wrongCooldown),
		}
	end

	engine.reset(options.variantIndex)
	return engine
end

return CCTVPuzzleEngine
