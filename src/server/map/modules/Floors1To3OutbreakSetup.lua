--[[
	Floors1To3OutbreakSetup.lua
	ใส่ใน: ServerScriptService -> Map -> modules
	หน้าที่:
	  สร้างองค์ประกอบฉาก Co-op L4D-Style Outbreak & Quarantine Camp ในชั้น 1–3 แบบ Idempotent:
	    - ชั้น 1 (Parking & Perimeter): ซากรถชนกัน 2 จุด, รถกู้ภัย/พยาบาลฉุกเฉิน, แบริเออร์ปูน, กรวยจราจร,
	      ด่านตรวจปิดลานจอด และ "รถติดสัญญาณกันขโมย (CarAlarmHazard)" 3 คัน ที่ยิงหรือชนแล้วเสียงดังเรียกซอมบี้!
	    - ชั้น 2 (Canteen): พลิกโต๊ะโรงอาหาร (เว้นโต๊ะที่มีจุดฟาร์ม), สร้างสิ่งกีดขวาง/รถเข็นอาหารคว่ำ/ประตูม้วนตกครึ่งบาน
	      แบ่งโถงกลาง 60 studs ให้เป็นเส้นทางซิกแซกแบบ L4D (เว้นจุดปั่นไฟ M2 (-22, 23, 76) และจุดซื้อปืนโล่ง 100%)
	    - ชั้น 3 (Sports Arena): ค่ายกักกันและคัดกรองผู้ติดเชื้อชั่วคราวกลางสนามฟุตซอล & สนามบาสเกตบอล
	      (เต็นท์พยาบาลเดินทะลุได้, บังเกอร์กระสอบทราย, แผงเหล็กกักกัน, ถังสารชีวภาพ, ไฟสปอตไลท์ฉุกเฉิน)
	    - ติดป้ายภาษาไทย + ไฟฉุกเฉิน HorrorEmergencyLight ครบทั้ง 3 ชั้นเพื่อให้เล่นในโหมด Blackout ได้ตื่นเต้นและอ่านทางง่าย
]]

local CollectionService = game:GetService("CollectionService")

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)
local CarBuilder = require(script.Parent.Parent.utils.CarBuilder)
local Layout = require(script.Parent.Parent.utils.Building40Layout)

local Floors1To3OutbreakSetup = {}

local COLOR_CONCRETE_DARK = Color3.fromRGB(115, 114, 110)
local COLOR_HAZARD_YELLOW = Color3.fromRGB(230, 178, 32)
local COLOR_HAZARD_ORANGE = Color3.fromRGB(228, 92, 28)
local COLOR_HAZARD_RED = Color3.fromRGB(178, 34, 34)
local COLOR_BLOOD = Color3.fromRGB(92, 10, 14)
local COLOR_SANDBAG_A = Color3.fromRGB(148, 134, 102)
local COLOR_SANDBAG_B = Color3.fromRGB(126, 114, 86)
local COLOR_MIL_OLIVE = Color3.fromRGB(72, 84, 58)
local COLOR_STEEL_DARK = Color3.fromRGB(48, 54, 62)
local COLOR_RUST = Color3.fromRGB(108, 62, 42)
local COLOR_TENT_CANVAS = Color3.fromRGB(186, 182, 168)

local function addEmergencyLight(parent, name, pos, color, range, brightness)
	local holder = PartBuilder.makePart(
		parent,
		name .. "_Fixture",
		Vector3.new(1.1, 0.35, 1.1),
		CFrame.new(pos),
		color,
		Enum.Material.Neon,
		{ CanCollide = false, CanQuery = false }
	)
	local light = Instance.new("PointLight")
	light.Name = name
	light.Color = color
	light.Range = range or 34
	light.Brightness = brightness or 1.45
	light.Shadows = false
	light:SetAttribute("HorrorEmergencyLight", true)
	light.Parent = holder
	return holder, light
end

local function makeBloodSplatter(parent, name, pos, sizeX, sizeZ, yawDeg)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	PartBuilder.makeCylinder(
		m,
		"MainPool",
		Vector3.new(0.03, sizeX, sizeZ),
		CFrame.new(pos) * CFrame.Angles(0, math.rad(yawDeg or 0), math.rad(90)),
		COLOR_BLOOD,
		Enum.Material.SmoothPlastic,
		{ CanCollide = false, CanQuery = false, Transparency = 0.08, CastShadow = false }
	)
	local drops = {
		{ dx = sizeX * 0.42, dz = sizeZ * 0.18, s = 0.45 },
		{ dx = -sizeX * 0.36, dz = -sizeZ * 0.28, s = 0.38 },
		{ dx = sizeX * 0.12, dz = -sizeZ * 0.48, s = 0.30 },
	}
	for i, d in ipairs(drops) do
		PartBuilder.makeCylinder(
			m,
			"Drop_" .. i,
			Vector3.new(0.028, sizeX * d.s, sizeZ * d.s),
			CFrame.new(pos + Vector3.new(d.dx, 0.002, d.dz)) * CFrame.Angles(0, math.rad((yawDeg or 0) + i * 27), math.rad(90)),
			COLOR_BLOOD,
			Enum.Material.SmoothPlastic,
			{ CanCollide = false, CanQuery = false, Transparency = 0.12, CastShadow = false }
		)
	end
	return m
end

local function makeStandingSign(parent, name, text, size, pos, faceNormalId, bgColor, textColor, floorY)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	PartBuilder.makeSign(m, "Board", text, size, pos, faceNormalId, bgColor, textColor)
	local bottomY = pos.Y - (size.Y / 2)
	local postH = math.max(0.5, bottomY - floorY)
	local postCenterY = floorY + postH / 2
	local span = (faceNormalId == Enum.NormalId.Left or faceNormalId == Enum.NormalId.Right)
	for _, s in ipairs({ -1, 1 }) do
		local offX = span and 0 or (s * (size.X * 0.38))
		local offZ = span and (s * (size.X * 0.38)) or 0
		PartBuilder.makePart(
			m,
			"Post_" .. s,
			Vector3.new(0.32, postH + 0.4, 0.32),
			CFrame.new(pos.X + offX, postCenterY, pos.Z + offZ),
			COLOR_STEEL_DARK,
			Enum.Material.Metal
		)
	end
	return m
end

local function makeQuarantineFence(parent, name, cf, panels)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local count = panels or 2
	local panelW = 8.0
	local totalStart = -((count - 1) * panelW) / 2
	for i = 0, count - 1 do
		local px = totalStart + i * panelW
		PartBuilder.makePart(m, "PostL_" .. i, Vector3.new(0.35, 6.2, 0.35), cf * CFrame.new(px - panelW / 2, 3.1, 0), COLOR_STEEL_DARK, Enum.Material.Metal)
		PartBuilder.makePart(m, "PostR_" .. i, Vector3.new(0.35, 6.2, 0.35), cf * CFrame.new(px + panelW / 2, 3.1, 0), COLOR_STEEL_DARK, Enum.Material.Metal)
		PartBuilder.makePart(m, "TopRail_" .. i, Vector3.new(panelW, 0.25, 0.25), cf * CFrame.new(px, 6.1, 0), COLOR_HAZARD_YELLOW, Enum.Material.Metal)
		PartBuilder.makePart(m, "BottomRail_" .. i, Vector3.new(panelW, 0.25, 0.25), cf * CFrame.new(px, 0.35, 0), COLOR_STEEL_DARK, Enum.Material.Metal)
		PartBuilder.makePart(m, "Mesh_" .. i, Vector3.new(panelW - 0.3, 5.5, 0.12), cf * CFrame.new(px, 3.2, 0), Color3.fromRGB(95, 105, 115), Enum.Material.Metal, { Transparency = 0.58 })
	end
	return m
end

local function makeConcreteBarrier(parent, name, cf, accentColor)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent

	PartBuilder.makePart(m, "Base", Vector3.new(9.6, 1.1, 2.4), cf * CFrame.new(0, 0.55, 0), COLOR_CONCRETE_DARK, Enum.Material.Concrete)
	PartBuilder.makePart(m, "Spine", Vector3.new(9.5, 2.2, 1.25), cf * CFrame.new(0, 2.1, 0), Color3.fromRGB(142, 140, 135), Enum.Material.Concrete)
	for i = -3, 3, 2 do
		local c = (i % 4 == 1 or i % 4 == -3) and (accentColor or COLOR_HAZARD_ORANGE) or Color3.fromRGB(235, 235, 232)
		PartBuilder.makePart(
			m,
			"HazardStripe_" .. i,
			Vector3.new(1.15, 0.55, 1.32),
			cf * CFrame.new(i * 1.15, 2.75, 0),
			c,
			Enum.Material.SmoothPlastic,
			{ CanCollide = false }
		)
	end
	return m
end

local function makeSandbagBunker(parent, name, cf, cols)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local bagCols = cols or 4
	local bagW, bagH, bagD = 2.6, 0.9, 1.65
	local startX = -((bagCols - 1) * bagW) / 2
	for row = 0, 3 do
		local y = (row + 0.5) * (bagH * 0.92)
		local rowOffset = (row % 2 == 1) and (bagW * 0.35) or 0
		for c = 0, bagCols - 1 do
			if not (row == 3 and (c == 0 or c == bagCols - 1) and bagCols >= 4) then
				local x = startX + c * (bagW * 0.96) + rowOffset
				local jitterYaw = math.rad(((row * 7 + c * 11) % 9) - 4)
				local color = ((row + c) % 2 == 0) and COLOR_SANDBAG_A or COLOR_SANDBAG_B
				PartBuilder.makePart(
					m,
					string.format("Sandbag_%d_%d", row, c),
					Vector3.new(bagW, bagH, bagD),
					cf * CFrame.new(x, y, 0) * CFrame.Angles(0, jitterYaw, 0),
					color,
					Enum.Material.Fabric
				)
			end
		end
	end
	return m
end

local function makeTrafficCone(parent, name, pos, tippedYawDeg)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local baseCf = CFrame.new(pos)
	if tippedYawDeg then
		baseCf = CFrame.new(pos + Vector3.new(0, 0.75, 0)) * CFrame.Angles(0, math.rad(tippedYawDeg), math.rad(82))
	end
	PartBuilder.makePart(m, "ConeBase", Vector3.new(1.7, 0.22, 1.7), baseCf * CFrame.new(0, 0.11, 0), COLOR_HAZARD_ORANGE, Enum.Material.SmoothPlastic)
	PartBuilder.makePart(m, "ConeLower", Vector3.new(1.2, 1.0, 1.2), baseCf * CFrame.new(0, 0.7, 0), COLOR_HAZARD_ORANGE, Enum.Material.SmoothPlastic)
	PartBuilder.makePart(m, "ConeReflect", Vector3.new(0.95, 0.65, 0.95), baseCf * CFrame.new(0, 1.45, 0), Color3.fromRGB(240, 242, 245), Enum.Material.SmoothPlastic)
	PartBuilder.makePart(m, "ConeTip", Vector3.new(0.65, 0.75, 0.65), baseCf * CFrame.new(0, 2.05, 0), COLOR_HAZARD_ORANGE, Enum.Material.SmoothPlastic)
	return m
end

local function makeHazardBarrel(parent, name, pos, color)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local c = color or COLOR_HAZARD_YELLOW
	PartBuilder.makeCylinder(
		m,
		"DrumBody",
		Vector3.new(4.2, 2.7, 2.7),
		CFrame.new(pos + Vector3.new(0, 2.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		c,
		Enum.Material.Metal
	)
	PartBuilder.makeCylinder(
		m,
		"DrumBand",
		Vector3.new(0.55, 2.82, 2.82),
		CFrame.new(pos + Vector3.new(0, 2.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(32, 34, 38),
		Enum.Material.Metal
	)
	return m
end

local function makeSupplyCrateCluster(parent, name, cf, primaryColor)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local cMain = primaryColor or COLOR_MIL_OLIVE
	PartBuilder.makePart(m, "CrateA", Vector3.new(4.6, 3.2, 3.6), cf * CFrame.new(-1.8, 1.6, 0), cMain, Enum.Material.Wood)
	PartBuilder.makePart(m, "CrateB", Vector3.new(3.8, 2.8, 3.4), cf * CFrame.new(2.5, 1.4, 0.4) * CFrame.Angles(0, math.rad(16), 0), COLOR_RUST, Enum.Material.Metal)
	PartBuilder.makePart(m, "CrateTop", Vector3.new(3.4, 2.4, 2.8), cf * CFrame.new(-1.2, 4.4, -0.2) * CFrame.Angles(0, math.rad(-14), 0), COLOR_HAZARD_YELLOW, Enum.Material.Wood)
	return m
end

local function makeWorklightTripod(parent, name, cf, lightColor)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local col = lightColor or Color3.fromRGB(255, 208, 118)
	PartBuilder.makePart(m, "Pole", Vector3.new(0.32, 7.2, 0.32), cf * CFrame.new(0, 3.6, 0), COLOR_HAZARD_YELLOW, Enum.Material.Metal)
	PartBuilder.makePart(m, "TripodBase", Vector3.new(2.8, 0.35, 2.8), cf * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, math.rad(45), 0), COLOR_STEEL_DARK, Enum.Material.Metal)
	local head = PartBuilder.makePart(m, "LampHead", Vector3.new(2.2, 1.1, 0.7), cf * CFrame.new(0, 7.3, 0), COLOR_STEEL_DARK, Enum.Material.Metal)
	local bulb = PartBuilder.makePart(m, "LampLens", Vector3.new(1.85, 0.78, 0.14), cf * CFrame.new(0, 7.3, -0.36), col, Enum.Material.Neon, { CanCollide = false })
	local pl = Instance.new("PointLight")
	pl.Name = "TripodEmergencyLight"
	pl.Color = col
	pl.Range = 40
	pl.Brightness = 1.6
	pl.Shadows = false
	pl:SetAttribute("HorrorEmergencyLight", true)
	pl.Parent = bulb
	return m, head
end

local function pivotAndTiltModel(model, centerPos, pitchDeg, rollDeg)
	if not model then return end
	local rot = CFrame.Angles(math.rad(pitchDeg or 0), 0, math.rad(rollDeg or 0))
	local anchorCf = CFrame.new(centerPos)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			local rel = anchorCf:ToObjectSpace(desc.CFrame)
			desc.CFrame = anchorCf * rot * rel
		end
	end
end

local function attachCarAlarmHazard(carModel, alarmId, worldPos, floorY)
	carModel:SetAttribute("CarAlarmArmed", true)
	carModel:SetAttribute("CarAlarmId", alarmId)
	carModel:SetAttribute("CarAlarmPos", worldPos)
	carModel:SetAttribute("CarAlarmCooldownUntil", 0)
	CollectionService:AddTag(carModel, "CarAlarmHazard")

	-- กระจายไฟสัญญาณเตือนสีแดงบนคอนโซล + คู่ไฟหน้าสำหรับกระพริบเวลาสัญญาณกันขโมยดัง
	local dashBeacon = PartBuilder.makePart(
		carModel,
		"CarAlarmDashLED",
		Vector3.new(0.55, 0.35, 0.55),
		CFrame.new(worldPos.X, floorY + 4.35, worldPos.Z),
		Color3.fromRGB(255, 45, 45),
		Enum.Material.Neon,
		{ CanCollide = false, CanQuery = false }
	)
	local beaconLight = Instance.new("PointLight")
	beaconLight.Name = "CarAlarmBeaconLight"
	beaconLight.Color = Color3.fromRGB(255, 45, 45)
	beaconLight.Range = 14
	beaconLight.Brightness = 0.85
	beaconLight:SetAttribute("HorrorEmergencyLight", true)
	beaconLight.Parent = dashBeacon

	local alarmFlash = Instance.new("PointLight")
	alarmFlash.Name = "CarAlarmStrobeLight"
	alarmFlash.Color = Color3.fromRGB(255, 125, 35)
	alarmFlash.Range = 48
	alarmFlash.Brightness = 3.2
	alarmFlash.Enabled = false
	alarmFlash:SetAttribute("DynamicAlarmLight", true)
	alarmFlash.Parent = dashBeacon

	local alarmSound = Instance.new("Sound")
	alarmSound.Name = "CarAlarmKlaxonSound"
	alarmSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	alarmSound.Volume = 1.15
	alarmSound.PlaybackSpeed = 0.72
	alarmSound.Looped = true
	alarmSound.RollOffMaxDistance = 125
	alarmSound.RollOffMinDistance = 16
	alarmSound.Parent = dashBeacon

	-- ติดป้ายเล็กบนหลังคาให้ผู้เล่นระวังสัญญาณกันขโมย (หรือใช้ล่อซอมบี้ได้!)
	PartBuilder.makeSign(
		carModel,
		"CarAlarmHintPlate",
		"⚠ สัญญาณกันขโมยรถ (ALARM)\nยิง/กระแทก = เรียกฝูงซอมบี้",
		Vector3.new(4.2, 0.9, 0.25),
		CFrame.new(worldPos.X, floorY + 5.75, worldPos.Z) * CFrame.Angles(math.rad(-25), 0, 0),
		Enum.NormalId.Front,
		Color3.fromRGB(48, 14, 14),
		Color3.fromRGB(255, 195, 110)
	)
end

local function buildWreckedCar(parent, name, cx, floorY, cz, yawDeg, bodyColor, opts)
	opts = opts or {}
	local car = CarBuilder.buildParkedCar(parent, name, cx, floorY, cz, yawDeg, bodyColor)
	if opts.pitchDeg or opts.rollDeg then
		pivotAndTiltModel(car, Vector3.new(cx, floorY + 2.2, cz), opts.pitchDeg or 0, opts.rollDeg or 0)
	end

	-- เอฟเฟกต์ควันดำจากห้องเครื่องรถชน
	local hoodGlow = PartBuilder.makePart(
		car,
		"WreckEngineSmokeSource",
		Vector3.new(1.2, 0.6, 1.2),
		CFrame.new(cx, floorY + 3.1, cz),
		Color3.fromRGB(40, 40, 44),
		Enum.Material.Metal,
		{ CanCollide = false, CanQuery = false, Transparency = 1 }
	)
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(45, 45, 50)
	smoke.Opacity = 0.32
	smoke.RiseVelocity = 3.2
	smoke.Size = 2.6
	smoke.Parent = hoodGlow

	if opts.isAlarm then
		attachCarAlarmHazard(car, name, Vector3.new(cx, floorY, cz), floorY)
	end
	return car
end

local function buildEmergencyAmbulance(parent, name, cx, floorY, cz, yawDeg)
	local amb = Instance.new("Model")
	amb.Name = name
	amb.Parent = parent
	local baseCf = CFrame.new(cx, floorY, cz) * CFrame.Angles(0, math.rad(yawDeg or 0), 0)
	local white = Color3.fromRGB(238, 240, 244)
	local redStripe = Color3.fromRGB(196, 34, 42)
	local darkGlass = Color3.fromRGB(36, 48, 62)

	-- ตัวถัง + ห้องโดยสารพยาบาล
	PartBuilder.makePart(amb, "Chassis", Vector3.new(8.2, 1.0, 17.0), baseCf * CFrame.new(0, 1.35, 0), Color3.fromRGB(36, 40, 46), Enum.Material.Metal)
	PartBuilder.makePart(amb, "MedicalBox", Vector3.new(8.0, 5.4, 11.2), baseCf * CFrame.new(0, 4.55, 2.4), white, Enum.Material.SmoothPlastic)
	PartBuilder.makePart(amb, "CabBody", Vector3.new(7.6, 4.0, 5.4), baseCf * CFrame.new(0, 3.85, -5.6), white, Enum.Material.SmoothPlastic)
	PartBuilder.makePart(amb, "RedBand_Box", Vector3.new(8.06, 0.75, 11.24), baseCf * CFrame.new(0, 3.6, 2.4), redStripe, Enum.Material.SmoothPlastic, { CanCollide = false })
	PartBuilder.makePart(amb, "Windshield", Vector3.new(6.8, 2.0, 0.4), baseCf * CFrame.new(0, 4.4, -8.1) * CFrame.Angles(math.rad(-18), 0, 0), darkGlass, Enum.Material.Glass, { Transparency = 0.45 })
	PartBuilder.makePart(amb, "FrontGrille", Vector3.new(4.8, 1.35, 0.35), baseCf * CFrame.new(0, 2.5, -8.4), COLOR_STEEL_DARK, Enum.Material.Metal)
	for _, sx in ipairs({ -2.7, 2.7 }) do
		PartBuilder.makePart(amb, "Headlight_" .. tostring(sx), Vector3.new(1.1, 0.65, 0.25), baseCf * CFrame.new(sx, 2.6, -8.38), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, { CanCollide = false })
	end

	-- กากบาทพยาบาลด้านข้าง + ล้อ
	for _, sx in ipairs({ -1, 1 }) do
		PartBuilder.makePart(amb, "CrossV_" .. sx, Vector3.new(0.14, 2.2, 0.7), baseCf * CFrame.new(sx * 4.04, 5.3, 2.4), redStripe, Enum.Material.SmoothPlastic, { CanCollide = false })
		PartBuilder.makePart(amb, "CrossH_" .. sx, Vector3.new(0.14, 0.7, 2.2), baseCf * CFrame.new(sx * 4.04, 5.3, 2.4), redStripe, Enum.Material.SmoothPlastic, { CanCollide = false })
		for _, wz in ipairs({ -5.6, 4.6 }) do
			PartBuilder.makeCylinder(amb, string.format("Wheel_%d_%d", sx, wz), Vector3.new(1.1, 2.8, 2.8), baseCf * CFrame.new(sx * 3.85, 1.4, wz), Color3.fromRGB(22, 24, 28), Enum.Material.SmoothPlastic)
		end
	end

	-- ประตูท้ายรถพยาบาลเปิดแง้ม + ไฟไซเรนแดงฉุกเฉิน
	PartBuilder.makePart(amb, "RearDoor_OpenL", Vector3.new(0.35, 4.8, 3.4), baseCf * CFrame.new(-3.8, 4.4, 9.5) * CFrame.Angles(0, math.rad(28), 0), white, Enum.Material.SmoothPlastic)
	PartBuilder.makePart(amb, "RearDoor_OpenR", Vector3.new(0.35, 4.8, 3.4), baseCf * CFrame.new(3.8, 4.4, 9.4) * CFrame.Angles(0, math.rad(-42), 0), white, Enum.Material.SmoothPlastic)

	local sirenBar = PartBuilder.makePart(amb, "SirenLightBar", Vector3.new(5.6, 0.65, 1.2), baseCf * CFrame.new(0, 7.55, -3.4), redStripe, Enum.Material.Neon, { CanCollide = false })
	local sirenLight = Instance.new("PointLight")
	sirenLight.Name = "AmbulanceEmergencyLight"
	sirenLight.Color = Color3.fromRGB(255, 60, 45)
	sirenLight.Range = 40
	sirenLight.Brightness = 1.65
	sirenLight.Shadows = false
	sirenLight:SetAttribute("HorrorEmergencyLight", true)
	sirenLight.Parent = sirenBar

	-- เตียงเข็นผู้ป่วย + กล่องยาตกหน้าท้ายรถ
	PartBuilder.makePart(amb, "SpilledStretcher", Vector3.new(3.0, 0.5, 6.2), baseCf * CFrame.new(1.2, 0.95, 11.4) * CFrame.Angles(0, math.rad(24), math.rad(8)), Color3.fromRGB(220, 224, 230), Enum.Material.Metal)
	PartBuilder.makePart(amb, "TraumaBox", Vector3.new(2.2, 1.3, 1.6), baseCf * CFrame.new(-2.4, 0.65, 10.2) * CFrame.Angles(0, math.rad(-18), 0), redStripe, Enum.Material.SmoothPlastic)
	return amb
end

local function buildTriageTent(parent, name, cx, floorY, cz, yawDeg, titleText, lightColor)
	local tent = Instance.new("Model")
	tent.Name = name
	tent.Parent = parent

	local cf = CFrame.new(cx, floorY, cz) * CFrame.Angles(0, math.rad(yawDeg or 0), 0)
	local tentW, tentH, tentL = 22.0, 9.6, 16.0
	local halfW, halfL = tentW / 2, tentL / 2

	-- เสาโครงเหล็ก 6 จุด (ไม่บังทางเดินเข้า-ออกด้านยาว Z = ±8)
	for _, px in ipairs({ -halfW, 0, halfW }) do
		for _, pz in ipairs({ -halfL, halfL }) do
			PartBuilder.makePart(tent, string.format("Pole_%d_%d", px, pz), Vector3.new(0.45, tentH, 0.45), cf * CFrame.new(px, tentH / 2, pz), COLOR_STEEL_DARK, Enum.Material.Metal)
		end
	end

	-- ผนังผ้าใบสีครีม-เทาทางการแพทย์ + หลังคาจั่ว 2 ด้าน (เปิดช่องประตูโล่งตรงหัว-ท้ายให้คน/ซอมบี้วิ่งทะลุได้!)
	local medicalCanvas = Color3.fromRGB(222, 220, 212)
	local medicalCross = Color3.fromRGB(185, 36, 40)
	for _, sz in ipairs({ -1, 1 }) do
		PartBuilder.makePart(tent, "CanvasSideWall_" .. sz, Vector3.new(tentW, tentH - 1.2, 0.25), cf * CFrame.new(0, (tentH - 1.2) / 2, sz * halfL), medicalCanvas, Enum.Material.Fabric)
		PartBuilder.makePart(tent, "MedicalStripe_" .. sz, Vector3.new(tentW - 1, 0.55, 0.30), cf * CFrame.new(0, 4.8, sz * halfL), medicalCross, Enum.Material.SmoothPlastic, { CanCollide = false })
		PartBuilder.makePart(
			tent,
			"RoofSlope_" .. sz,
			Vector3.new(tentW + 1.2, 0.3, halfL + 1.5),
			cf * CFrame.new(0, tentH + 0.9, sz * (halfL * 0.48)) * CFrame.Angles(sz * math.rad(-14), 0, 0),
			COLOR_MIL_OLIVE,
			Enum.Material.Fabric
		)
	end

	-- เตียงสนาม 2 ตัว (ด้านข้างซ้าย/ขวา เหลือทางเดินกลางโล่ง) + โต๊ะยาฉุกเฉิน
	for _, sz in ipairs({ -1, 1 }) do
		local cotZ = sz * (halfL - 2.8)
		PartBuilder.makePart(tent, "FieldCot_" .. sz, Vector3.new(6.8, 1.4, 3.0), cf * CFrame.new(-3.8, 0.7, cotZ), COLOR_SANDBAG_B, Enum.Material.Fabric)
		PartBuilder.makePart(tent, "CotBloodSheet_" .. sz, Vector3.new(3.2, 0.12, 2.2), cf * CFrame.new(-3.8, 1.46, cotZ), COLOR_BLOOD, Enum.Material.Fabric, { CanCollide = false })
	end
	PartBuilder.makePart(tent, "MedTable", Vector3.new(4.2, 2.8, 2.2), cf * CFrame.new(5.2, 1.4, -halfL + 2.5), COLOR_STEEL_DARK, Enum.Material.Metal)

	-- ไฟฉุกเฉินด้านในเต็นท์ (ติดในโหมด Blackout)
	local lampPos = (cf * CFrame.new(0, tentH - 0.8, 0)).Position
	addEmergencyLight(tent, name .. "_TentLight", lampPos, lightColor or Color3.fromRGB(255, 198, 92), 34, 1.45)

	PartBuilder.makeSign(
		tent,
		"TentSign",
		titleText,
		Vector3.new(12.0, 2.1, 0.3),
		cf * CFrame.new(0, tentH - 1.4, -halfL - 0.3),
		Enum.NormalId.Back,
		Color3.fromRGB(110, 24, 24),
		Color3.fromRGB(255, 245, 220)
	)
	return tent
end

----------------------------------------------------------------------
-- FLOOR 1: Parking Lot Wreckage, Rescue Ambulance, Car Alarms, Barriers
----------------------------------------------------------------------
function Floors1To3OutbreakSetup.setupFloor1Outbreak(floor1)
	if not floor1 then return end
	local old = floor1:FindFirstChild("F1_OutbreakWreckage")
	if old then old:Destroy() end

	local container = Instance.new("Model")
	container.Name = "F1_OutbreakWreckage"
	container.Parent = floor1

	local floorY = Layout.GROUND_Y -- 1.0

	-- 1. โซนซ้ายของลานจอด (West Crash Chokepoint — X=-102..-74, เลี่ยงจุด Spawn และทางเข้าห้อง 102 X=-109,Z=41)
	buildWreckedCar(container, "Wreck_AlarmSedan_West", -90, floorY, -8, 34, CarBuilder.CAR_COLORS[1], { pitchDeg = 3, isAlarm = true })
	buildWreckedCar(container, "Wreck_CrashedCompact_West", -76, floorY, 6, -52, CarBuilder.CAR_COLORS[3], { rollDeg = 10 })
	makeConcreteBarrier(container, "Barrier_WestChoke_1", CFrame.new(-98, floorY, 8) * CFrame.Angles(0, math.rad(28), 0))
	makeConcreteBarrier(container, "Barrier_WestChoke_2", CFrame.new(-80, floorY, -18) * CFrame.Angles(0, math.rad(-18), 0))
	makeTrafficCone(container, "Cone_W1", Vector3.new(-86, floorY, 14))
	makeTrafficCone(container, "Cone_W2", Vector3.new(-72, floorY, 12), 45)
	makeBloodSplatter(container, "Blood_WestCrash", Vector3.new(-83, floorY + 0.03, 0), 7.5, 6.2, 22)

	-- 2. รถพยาบาลฉุกเฉินตรงลานฝั่งซ้าย-กลาง (ห่าง PlayerSpawn (0,0) > 36 studs)
	buildEmergencyAmbulance(container, "Outbreak_RescueAmbulance", -36, floorY, 11, -26)
	makeSupplyCrateCluster(container, "Ambulance_TraumaSupply", CFrame.new(-49, floorY, 18) * CFrame.Angles(0, math.rad(22), 0), COLOR_MIL_OLIVE)
	makeTrafficCone(container, "Cone_Amb1", Vector3.new(-46, floorY, 2))
	makeBloodSplatter(container, "Blood_AmbulanceRear", Vector3.new(-43, floorY + 0.03, 21), 6.2, 5.0, -15)

	-- 3. จุดรถชนฝั่งขวา-กลาง (Alarm #2 — ห่าง ClueBoard (25, 22) และ Spawn (0,0) ~40 studs)
	buildWreckedCar(container, "Wreck_AlarmSUV_Center", 38, floorY, -15, -36, CarBuilder.CAR_COLORS[5], { rollDeg = -6, isAlarm = true })
	buildWreckedCar(container, "Wreck_CrashedTaxi_Center", 52, floorY, -4, 112, Color3.fromRGB(224, 180, 32), { pitchDeg = -4 })
	makeConcreteBarrier(container, "Barrier_CenterE_1", CFrame.new(30, floorY, -24) * CFrame.Angles(0, math.rad(-25), 0))
	makeConcreteBarrier(container, "Barrier_CenterE_2", CFrame.new(58, floorY, 11) * CFrame.Angles(0, math.rad(16), 0))
	makeHazardBarrel(container, "Barrel_CenterE_1", Vector3.new(44, floorY, 8), COLOR_HAZARD_YELLOW)

	-- 4. รถชน + ด่านกักกันฝั่งตะวันออก (Alarm #3 หน้าธนาคาร/คาเฟ่)
	buildWreckedCar(container, "Wreck_AlarmSedan_East", 88, floorY, 5, 142, CarBuilder.CAR_COLORS[4], { pitchDeg = 4, isAlarm = true })
	makeConcreteBarrier(container, "Barrier_EastGate_1", CFrame.new(124, floorY, -10) * CFrame.Angles(0, math.rad(72), 0))
	makeConcreteBarrier(container, "Barrier_EastGate_2", CFrame.new(120, floorY, 12) * CFrame.Angles(0, math.rad(102), 0))
	makeSandbagBunker(container, "Sandbag_EastCheckpoint", CFrame.new(134, floorY, 2) * CFrame.Angles(0, math.rad(90), 0), 4)
	makeWorklightTripod(container, "Worklight_EastGate", CFrame.new(130, floorY, 14) * CFrame.Angles(0, math.rad(-135), 0), Color3.fromRGB(255, 196, 95))
	makeStandingSign(
		container,
		"Sign_EastQuarantine",
		"เขตกักกันฉุกเฉิน — อาคาร 40\nระวังซอมบี้ & รถติดสัญญาณกันขโมย",
		Vector3.new(12.5, 2.8, 0.35),
		Vector3.new(124, floorY + 4.4, -10),
		Enum.NormalId.Left,
		Color3.fromRGB(115, 24, 24),
		Color3.fromRGB(255, 242, 200),
		floorY
	)

	-- 5. ด่านกักกันฝั่งตะวันตก (West Parking Entrance Checkpoint)
	makeConcreteBarrier(container, "Barrier_WestGate_1", CFrame.new(-134, floorY, -14) * CFrame.Angles(0, math.rad(75), 0))
	makeConcreteBarrier(container, "Barrier_WestGate_2", CFrame.new(-132, floorY, 12) * CFrame.Angles(0, math.rad(-75), 0))
	makeSandbagBunker(container, "Sandbag_WestCheckpoint", CFrame.new(-138, floorY, -2) * CFrame.Angles(0, math.rad(90), 0), 3)
	makeHazardBarrel(container, "Barrel_WestGate_1", Vector3.new(-126, floorY, -18), COLOR_HAZARD_ORANGE)

	-- 6. ความวุ่นวายในคาเฟ่ฝั่งขวาบน (OpenCafe_TopRight: เลี่ยงเคาน์เตอร์ (79,-87) โต๊ะ (92/116/138,-74/-54) และจุดฟาร์ม)
	makeSupplyCrateCluster(container, "Cafe_AbandonedBarricade", CFrame.new(75, floorY, -56) * CFrame.Angles(0, math.rad(-20), 0), COLOR_SANDBAG_B)
	local cafeFlippedTable = PartBuilder.makeCylinder(
		container,
		"Cafe_OverturnedBistroTable",
		Vector3.new(0.25, 4.0, 4.0),
		CFrame.new(104, floorY + 1.8, -64) * CFrame.Angles(math.rad(15), math.rad(35), math.rad(18)),
		Color3.fromRGB(130, 86, 52),
		Enum.Material.Wood
	)
	cafeFlippedTable.Name = "Cafe_OverturnedBistroTable"
	makeBloodSplatter(container, "Blood_CafeFloor", Vector3.new(104, floorY + 0.03, -84), 7.0, 5.4, -30)
	makeBloodSplatter(container, "Blood_StairApproach", Vector3.new(-49, floorY + 0.03, -58), 5.5, 4.5, 10)

	-- 7. ไฟฉุกเฉินสีแดง/ส้มในโหมดไฟดับ (HorrorEmergencyLight = true) สำหรับชั้น 1
	local f1Lights = {
		{ "F1_Emerg_ParkWest", Vector3.new(-108, floorY + 19.5, 0), Color3.fromRGB(255, 125, 45), 42, 1.35 },
		{ "F1_Emerg_ParkEast", Vector3.new(108, floorY + 19.5, 0), Color3.fromRGB(255, 85, 55), 42, 1.35 },
		{ "F1_Emerg_StairNW", Vector3.new(-49, floorY + 16.5, -62), Color3.fromRGB(255, 55, 55), 34, 1.4 },
		{ "F1_Emerg_StairSW", Vector3.new(-49, floorY + 16.5, 62), Color3.fromRGB(255, 55, 55), 34, 1.4 },
		{ "F1_Emerg_Cafe", Vector3.new(108, floorY + 18.0, -76), Color3.fromRGB(255, 175, 82), 38, 1.35 },
		{ "F1_Emerg_BankApproach", Vector3.new(96, floorY + 18.0, 62), Color3.fromRGB(255, 70, 55), 36, 1.3 },
	}
	for _, def in ipairs(f1Lights) do
		addEmergencyLight(container, def[1], def[2], def[3], def[4], def[5])
	end
end

----------------------------------------------------------------------
-- FLOOR 2: Tilted Canteen Tables, Rolling Shutters, Sandbag Chokes
----------------------------------------------------------------------
local F2_TABLES_TO_TILT = {
	{ name = "CanteenTable_R1_C6", pitch = 6, roll = 74 },
	{ name = "CanteenTable_R1_C8", pitch = -5, roll = -72 },
	{ name = "CanteenTable_R2_C5", pitch = 8, roll = -76 },
	{ name = "CanteenTable_R2_C9", pitch = -6, roll = 72 },
	{ name = "CanteenTable_R3_C7", pitch = 10, roll = 78 },
	{ name = "CanteenTable_R3_C9", pitch = -8, roll = -74 },
	{ name = "CanteenTable_R4_C6", pitch = -6, roll = 75 },
	{ name = "CanteenTable_R4_C7", pitch = 8, roll = -76 },
	{ name = "CanteenTable_R5_C7", pitch = -8, roll = 74 },
	{ name = "CanteenTable_R5_C9", pitch = 6, roll = -72 },
	{ name = "CanteenTable_R6_C7", pitch = 8, roll = -70 },
	{ name = "CanteenTable_R6_C8", pitch = -7, roll = 72 },
	{ name = "CanteenTable_R1_C2", pitch = 6, roll = 68 },
	{ name = "CanteenTable_R4_C3", pitch = -5, roll = -70 },
}

function Floors1To3OutbreakSetup.setupFloor2Outbreak(floor2)
	if not floor2 then return end
	local old = floor2:FindFirstChild("F2_CanteenOutbreak")
	if old then old:Destroy() end

	local container = Instance.new("Model")
	container.Name = "F2_CanteenOutbreak"
	container.Parent = floor2

	local floorY = PartBuilder.floorY(2) -- 23.0

	-- 1. พลิกโต๊ะโรงอาหาร (เฉพาะโต๊ะที่ไม่มีไอเทมฟาร์ม) เป็นกำแพงบังกระสุนแบบ Idempotent
	local diningArea = floor2:FindFirstChild("CenterDiningHall_Tables")
	if diningArea then
		for _, spec in ipairs(F2_TABLES_TO_TILT) do
			local tbl = diningArea:FindFirstChild(spec.name)
			if tbl and tbl:GetAttribute("OutbreakTilted") ~= true then
				local top = tbl:FindFirstChild("TableTop")
				local anchorPos = top and Vector3.new(top.Position.X, floorY + 2.15, top.Position.Z)
				if anchorPos then
					pivotAndTiltModel(tbl, anchorPos, spec.pitch, spec.roll)
					tbl:SetAttribute("OutbreakTilted", true)
				end
			end
		end
	end

	-- 2. สิ่งกีดขวางแบ่งโถงกลาง 60 studs ให้เดินซิกแซก (เว้น M2_PowerRoomGenerator (-22, 23, 76) และ Buy_Bucky_F2 (30.2, 23, 79))
	makeConcreteBarrier(container, "F2_MidBarrier_W", CFrame.new(-18, floorY, -3) * CFrame.Angles(0, math.rad(14), 0))
	makeSandbagBunker(container, "F2_MidSandbag_W", CFrame.new(-9, floorY, -5) * CFrame.Angles(0, math.rad(-10), 0), 3)
	makeConcreteBarrier(container, "F2_MidBarrier_E", CFrame.new(18, floorY, 4) * CFrame.Angles(0, math.rad(-14), 0))
	makeSandbagBunker(container, "F2_MidSandbag_E", CFrame.new(9, floorY, 6) * CFrame.Angles(0, math.rad(10), 0), 3)
	makeConcreteBarrier(container, "F2_CenterAxisBlock", CFrame.new(-1, floorY, 22) * CFrame.Angles(0, math.rad(28), 0))
	makeHazardBarrel(container, "F2_CenterBarrel", Vector3.new(4, floorY, 20), COLOR_HAZARD_ORANGE)

	-- รถเข็นถาดอาหารคว่ำ + ถาดสแตนเลสกระจาย
	local cartCf = CFrame.new(-3, floorY + 1.4, -22) * CFrame.Angles(math.rad(16), math.rad(38), math.rad(76))
	PartBuilder.makePart(container, "SpilledFoodCart", Vector3.new(3.2, 4.4, 2.2), cartCf, PartBuilder.COLORS.steel, Enum.Material.Metal)
	for i = 1, 4 do
		PartBuilder.makePart(
			container,
			"SpilledTray_" .. i,
			Vector3.new(1.5, 0.12, 1.1),
			CFrame.new(-6 + i * 2.1, floorY + 0.08, -24 + (i % 2) * 2.2) * CFrame.Angles(0, math.rad(i * 33), 0),
			Color3.fromRGB(200, 120, 42),
			Enum.Material.SmoothPlastic
		)
	end

	-- 3. ประตูม้วนเหล็กครึ่งบาน / แผงเหล็กชะลอทางตามเสาโซนร้านค้า + ป้ายเตือน
	for _, sz in ipairs({ -1, 1 }) do
		for _, sx in ipairs({ -1, 1 }) do
			local xPos = sx * 42
			local zPos = sz * 64
			local shutter = Instance.new("Model")
			shutter.Name = string.format("HalfRollingShutter_%d_%d", sx, sz)
			shutter.Parent = container
			PartBuilder.makePart(shutter, "ShutterHeader", Vector3.new(24, 1.6, 1.2), CFrame.new(xPos, floorY + 13.5, zPos), COLOR_STEEL_DARK, Enum.Material.Metal)
			-- ปล่อยบานเหล็กห้อยลงมาครึ่งบน (Y+8..13) ให้เดินลอดใต้ได้สบายแต่บีบสายตา!
			PartBuilder.makePart(shutter, "ShutterSlats", Vector3.new(23.2, 5.2, 0.35), CFrame.new(xPos, floorY + 10.6, zPos) * CFrame.Angles(math.rad(4), 0, 0), Color3.fromRGB(132, 136, 142), Enum.Material.DiamondPlate)
		end
	end

	makeConcreteBarrier(container, "F2_NorthHallBlock", CFrame.new(0, floorY, -82) * CFrame.Angles(0, math.rad(18), 0))
	makeSupplyCrateCluster(container, "F2_StairLandingCrates", CFrame.new(14, floorY, 96) * CFrame.Angles(0, math.rad(-35), 0), COLOR_HAZARD_YELLOW)
	makeStandingSign(
		container,
		"F2_OutbreakSign",
		"โรงอาหารชั้น 2 // เส้นทางถูกปิดกั้น\nระวังผู้ติดเชื้อซุ่มในห้องแอร์และห้องน้ำ",
		Vector3.new(15, 2.8, 0.35),
		Vector3.new(0, floorY + 5.2, 5),
		Enum.NormalId.Front,
		Color3.fromRGB(110, 24, 24),
		Color3.fromRGB(255, 240, 200),
		floorY
	)
	makeBloodSplatter(container, "F2_Blood_Center", Vector3.new(4, floorY + 0.03, -10), 8.2, 6.4, 18)
	makeBloodSplatter(container, "F2_Blood_ACLeft", Vector3.new(-83, floorY + 0.03, -84), 6.0, 4.8, -22)

	-- 4. ไฟฉุกเฉินชั้น 2 (HorrorEmergencyLight = true)
	local f2Lights = {
		{ "F2_Emerg_Center", Vector3.new(0, floorY + 19.5, 0), Color3.fromRGB(255, 65, 52), 44, 1.35 },
		{ "F2_Emerg_StallW", Vector3.new(-92, floorY + 18.5, 0), Color3.fromRGB(255, 165, 68), 38, 1.25 },
		{ "F2_Emerg_StallE", Vector3.new(92, floorY + 18.5, 0), Color3.fromRGB(255, 165, 68), 38, 1.25 },
		{ "F2_Emerg_AC_TL", Vector3.new(-83, floorY + 17.5, -103), Color3.fromRGB(255, 52, 52), 30, 1.25 },
		{ "F2_Emerg_AC_TR", Vector3.new(83, floorY + 17.5, -103), Color3.fromRGB(255, 52, 52), 30, 1.25 },
		{ "F2_Emerg_AC_BL", Vector3.new(-83, floorY + 17.5, 103), Color3.fromRGB(255, 52, 52), 30, 1.25 },
		{ "F2_Emerg_AC_BR", Vector3.new(83, floorY + 17.5, 103), Color3.fromRGB(255, 52, 52), 30, 1.25 },
	}
	for _, def in ipairs(f2Lights) do
		addEmergencyLight(container, def[1], def[2], def[3], def[4], def[5])
	end
end

----------------------------------------------------------------------
-- FLOOR 3: Collapsed Emergency Quarantine & Evacuation Triage Camp
----------------------------------------------------------------------
function Floors1To3OutbreakSetup.setupFloor3Outbreak(floor3)
	if not floor3 then return end
	local old = floor3:FindFirstChild("F3_QuarantineCamp")
	if old then old:Destroy() end

	local container = Instance.new("Model")
	container.Name = "F3_QuarantineCamp"
	container.Parent = floor3

	local floorY = PartBuilder.floorY(3) -- 45.0

	-- 1. สนามฟุตซอลฝั่งซ้าย (X=-114..-34) -> ค่ายเต็นท์คัดกรองผู้ติดเชื้อชั่วคราว (เปิดทางประตูกรงเหล็ก X=-30, Z=-12..+12 โล่ง!)
	buildTriageTent(container, "TriageTent_FutsalNorth", -84, floorY, -44, 12, "เต็นท์คัดกรอง A // ผู้ติดเชื้อ", Color3.fromRGB(255, 195, 92))
	buildTriageTent(container, "TriageTent_FutsalSouth", -84, floorY, 44, -10, "เต็นท์คัดกรอง B // ห้องฉุกเฉิน", Color3.fromRGB(255, 68, 56))
	makeSandbagBunker(container, "Futsal_GateSandbag", CFrame.new(-55, floorY, -17) * CFrame.Angles(0, math.rad(-28), 0), 4)
	makeSupplyCrateCluster(container, "Futsal_MedCrates", CFrame.new(-54, floorY, 22) * CFrame.Angles(0, math.rad(25), 0), COLOR_MIL_OLIVE)
	makeHazardBarrel(container, "Futsal_BioDrum_1", Vector3.new(-62, floorY, 16), COLOR_HAZARD_YELLOW)
	makeHazardBarrel(container, "Futsal_BioDrum_2", Vector3.new(-60, floorY, 20), COLOR_HAZARD_RED)
	makeBloodSplatter(container, "F3_Blood_Futsal", Vector3.new(-68, floorY + 0.03, 2), 9.0, 7.2, 32)

	-- 2. สนามบาสฝั่งขวา (X=+34..+114) -> แนวป้องกันกระสอบทราย, แผงเหล็กกักกัน และกองเสบียงอพยพ
	buildTriageTent(container, "TriageTent_BasketNorth", 86, floorY, -46, -14, "จุดพักผู้รอดชีวิต C // กักกัน", Color3.fromRGB(255, 185, 86))
	buildTriageTent(container, "TriageTent_BasketSouth", 86, floorY, 44, 16, "จุดคัดแยกผู้ป่วย D // ฉุกเฉิน", Color3.fromRGB(255, 78, 56))
	makeSandbagBunker(container, "Basket_CommandBunker_Front", CFrame.new(66, floorY, 0) * CFrame.Angles(0, math.rad(90), 0), 5)
	makeSandbagBunker(container, "Basket_CommandBunker_Side", CFrame.new(72, floorY, -8) * CFrame.Angles(0, math.rad(15), 0), 4)
	makeQuarantineFence(container, "Basket_QuarantineFence_N", CFrame.new(54, floorY, -24) * CFrame.Angles(0, math.rad(68), 0), 2)
	makeQuarantineFence(container, "Basket_QuarantineFence_S", CFrame.new(54, floorY, 24) * CFrame.Angles(0, math.rad(-68), 0), 2)
	makeWorklightTripod(container, "Basket_BunkerWorklight", CFrame.new(73, floorY, 5) * CFrame.Angles(0, math.rad(-65), 0), Color3.fromRGB(255, 212, 130))
	makeSupplyCrateCluster(container, "Basket_EvacSupply_S", CFrame.new(62, floorY, 44) * CFrame.Angles(0, math.rad(18), 0), COLOR_MIL_OLIVE)
	makeHazardBarrel(container, "Basket_BioDrum_S1", Vector3.new(66, floorY, 34), COLOR_HAZARD_ORANGE)
	makeBloodSplatter(container, "F3_Blood_Basket", Vector3.new(58, floorY + 0.03, 18), 7.5, 6.0, -25)

	makeStandingSign(
		container,
		"Basket_QuarantineBanner",
		"ศูนย์คัดกรองผู้ติดเชื้อชั่วคราว // ชั้น 3\nL3 QUARANTINE — ห้ามเข้าใกล้เต็นท์มืด",
		Vector3.new(16, 3.0, 0.35),
		Vector3.new(72, floorY + 5.8, -11),
		Enum.NormalId.Back,
		Color3.fromRGB(112, 24, 24),
		Color3.fromRGB(255, 242, 200),
		floorY
	)

	-- 3. โถงกลางชั้น 3 (เว้น Buy_Spectre_F3 (28.2, 45, 0) และจุดฟาร์ม (-28,0), (28,0), (0,±58) โล่ง!)
	makeConcreteBarrier(container, "F3_ConcourseBarrier_N", CFrame.new(-13, floorY, -32) * CFrame.Angles(0, math.rad(-14), 0))
	makeConcreteBarrier(container, "F3_ConcourseBarrier_S", CFrame.new(13, floorY, 32) * CFrame.Angles(0, math.rad(-14), 0))
	makeTrafficCone(container, "F3_Cone_1", Vector3.new(-4, floorY, -30))
	makeTrafficCone(container, "F3_Cone_2", Vector3.new(4, floorY, 30), 25)

	-- 4. ไฟฉุกเฉินชั้น 3 (HorrorEmergencyLight = true)
	local f3Lights = {
		{ "F3_Emerg_Center", Vector3.new(0, floorY + 19.0, 0), Color3.fromRGB(255, 72, 55), 42, 1.35 },
		{ "F3_Emerg_StorageW", Vector3.new(-96, floorY + 16.5, 84), Color3.fromRGB(255, 62, 52), 34, 1.3 },
		{ "F3_Emerg_StorageE", Vector3.new(96, floorY + 16.5, 84), Color3.fromRGB(255, 62, 52), 34, 1.3 },
		{ "F3_Emerg_RestroomW", Vector3.new(-96, floorY + 16.5, -84), Color3.fromRGB(255, 62, 52), 34, 1.3 },
		{ "F3_Emerg_RestroomE", Vector3.new(96, floorY + 16.5, -84), Color3.fromRGB(255, 62, 52), 34, 1.3 },
	}
	for _, def in ipairs(f3Lights) do
		addEmergencyLight(container, def[1], def[2], def[3], def[4], def[5])
	end
end

function Floors1To3OutbreakSetup.setupAll(parent)
	if not parent then return end
	local f1 = parent:FindFirstChild("Floor_1_Building40")
	local f2 = parent:FindFirstChild("Floor_2_Canteen")
	local f3 = parent:FindFirstChild("Floor_3_SportsArena")
	if f1 then
		Floors1To3OutbreakSetup.setupFloor1Outbreak(f1)
	end
	if f2 then
		Floors1To3OutbreakSetup.setupFloor2Outbreak(f2)
	end
	if f3 then
		Floors1To3OutbreakSetup.setupFloor3Outbreak(f3)
	end
end

return Floors1To3OutbreakSetup
