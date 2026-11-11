--[[
    SurvivalAndHorrorSetup.server.lua
    Builds Building 40 horror enhancements & survival scavenge systems:
      1. Unarmed start -> climb to Floor 2 (Canteen) for Food, Batteries, Medkits & Starter Weapons.
      2. Server-authoritative Hunger (0..100) + Flashlight Battery (0..100).
      3. Floor 11 Secret Containment Lab behind the Black Glass wall (unlockable Blast Door,
         biohazard shattered pod, experiment logs, and Floor 11 high-tier weapon cache)
         leading up the stairs to Floor 12 Helicopter Extraction.
      4. Tagged crimson HorrorEmergencyLight nodes for Blackout & Unstable Power modes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Wait cleanly for Building 40 primary floors
Workspace:WaitForChild("Floor_1_Building40", 60)
Workspace:WaitForChild("Floor_2_Canteen", 60)
local floor11Model = Workspace:WaitForChild("Floor_11_Building40", 60)

-- Shared Remotes
local survivalEvents = ReplicatedStorage:FindFirstChild("SurvivalEvents") or Instance.new("Folder")
survivalEvents.Name = "SurvivalEvents"
survivalEvents.Parent = ReplicatedStorage

local function getOrCreateRemote(name)
	local r = survivalEvents:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = survivalEvents
	end
	return r
end

local survivalFeedbackEvent = getOrCreateRemote("SurvivalFeedback")
local flashlightSyncEvent = getOrCreateRemote("FlashlightSync")
local horrorModeSyncEvent = getOrCreateRemote("HorrorModeSync")

local weaponSignals = ServerStorage:WaitForChild("WeaponSignals", 20)
local grantWeaponSignal = weaponSignals and weaponSignals:WaitForChild("GrantWeapon", 10)
local refillAmmoSignal = weaponSignals and weaponSignals:WaitForChild("RefillAmmo", 10)

----------------------------------------------------------------------
-- 1. HELPERS
----------------------------------------------------------------------
local function makePart(parent, name, size, cf, color, material, extra)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	if extra then
		for k, v in pairs(extra) do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function isPlayerInsideTestRange(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local range = Workspace:FindFirstChild("INFECTED_TestRange")
	local floor = range and range:FindFirstChild("RangeFloor")
	if not root or not floor or not floor:IsA("BasePart") then
		return false
	end
	local lp = floor.CFrame:PointToObjectSpace(root.Position)
	return math.abs(lp.X) <= floor.Size.X * 0.5
		and math.abs(lp.Z) <= floor.Size.Z * 0.5
		and math.abs(lp.Y) <= 18
end

local function floorY(floorNum)
	return 1.0 + (floorNum - 1) * 22.0
end

----------------------------------------------------------------------
-- 2. FLOOR 11 SECRET CONTAINMENT LAB & BLACK GLASS AIRLOCK DOORS
----------------------------------------------------------------------
local function upgradeFloor11Entrance(coreFolder, prefix, zPos, isNorth)
	if not coreFolder then return end
	local f11Y = floorY(11) -- 221.0
	local wallH = 20.0
	local blackFrame = Color3.fromRGB(18, 20, 25)
	local blackGlass = Color3.fromRGB(10, 12, 16)

	-- Remove obstructing full-span central black glass & center mullion so players can breach
	for _, suffix in ipairs({ "_BlackGlass", "_BottomFrame", "_MidTransom", "_Mullion_3" }) do
		local obj = coreFolder:FindFirstChild(prefix .. suffix)
		if obj then
			obj:Destroy()
		end
	end

	local doorHalfW = 7.0
	local doorH = 10.5
	local wings = {
		{ tag = "Left", xMin = -30.5, xMax = -doorHalfW },
		{ tag = "Right", xMin = doorHalfW, xMax = 30.5 },
	}
	for _, w in ipairs(wings) do
		local span = w.xMax - w.xMin
		local midX = (w.xMin + w.xMax) * 0.5
		makePart(coreFolder, prefix .. "_" .. w.tag .. "Glass", Vector3.new(span, wallH - 0.6, 0.35),
			CFrame.new(midX, f11Y + wallH * 0.5, zPos), blackGlass, Enum.Material.Glass,
			{ Transparency = 0.2, Reflectance = 0.25 })
		makePart(coreFolder, prefix .. "_" .. w.tag .. "Sill", Vector3.new(span, 0.55, 0.7),
			CFrame.new(midX, f11Y + 0.275, zPos), blackFrame, Enum.Material.Metal)
	end

	-- Upper header over the blast door (Y = f11Y + doorH .. f11Y + wallH)
	local headerH = wallH - doorH
	makePart(coreFolder, prefix .. "_DoorHeader", Vector3.new(doorHalfW * 2, headerH, 0.65),
		CFrame.new(0, f11Y + doorH + headerH * 0.5, zPos), Color3.fromRGB(24, 28, 34), Enum.Material.Metal)
	makePart(coreFolder, prefix .. "_DoorTopBlackGlass", Vector3.new(doorHalfW * 2 - 0.6, headerH - 0.8, 0.35),
		CFrame.new(0, f11Y + doorH + headerH * 0.5, zPos + (isNorth and 0.1 or -0.1)), blackGlass, Enum.Material.Glass,
		{ Transparency = 0.25, Reflectance = 0.2 })

	-- Sliding Quarantine Blast Door Leaves
	local closedLeftCF = CFrame.new(-doorHalfW * 0.5, f11Y + doorH * 0.5, zPos)
	local closedRightCF = CFrame.new(doorHalfW * 0.5, f11Y + doorH * 0.5, zPos)
	local openLeftCF = CFrame.new(-doorHalfW * 1.48, f11Y + doorH * 0.5, zPos)
	local openRightCF = CFrame.new(doorHalfW * 1.48, f11Y + doorH * 0.5, zPos)

	local leafL = makePart(coreFolder, prefix .. "_AirlockLeafL", Vector3.new(doorHalfW, doorH, 0.75),
		closedLeftCF, Color3.fromRGB(38, 42, 48), Enum.Material.Metal)
	local leafR = makePart(coreFolder, prefix .. "_AirlockLeafR", Vector3.new(doorHalfW, doorH, 0.75),
		closedRightCF, Color3.fromRGB(38, 42, 48), Enum.Material.Metal)

	-- Crimson quarantine warning light on airlock frame
	local beacon = makePart(coreFolder, prefix .. "_AirlockScanner", Vector3.new(1.4, 2.2, 0.95),
		CFrame.new(doorHalfW + 1.1, f11Y + 4.8, zPos), Color3.fromRGB(220, 40, 45), Enum.Material.Neon, { CanCollide = false })
	local redGlow = Instance.new("PointLight")
	redGlow.Name = "QuarantineGlow"
	redGlow.Color = Color3.fromRGB(255, 50, 50)
	redGlow.Range = 30
	redGlow.Brightness = 2.0
	redGlow.Enabled = true
	redGlow:SetAttribute("HorrorEmergencyLight", true)
	redGlow.Parent = beacon

	local isOpen = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UnlockFloor11Airlock"
	prompt.ActionText = "ปลดล็อกประตูเขตทดลองลับ"
	prompt.ObjectText = "SECTOR 11 // PROJECT KM-40"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 1.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = beacon

	prompt.Triggered:Connect(function(triggerPlayer)
		if isOpen then return end
		local char = triggerPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - beacon.Position).Magnitude > prompt.MaxActivationDistance + 5 then
			return
		end
		isOpen = true
		prompt.Enabled = false
		beacon.Color = Color3.fromRGB(55, 215, 130)
		redGlow.Color = Color3.fromRGB(60, 220, 140)

		local ti = TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(leafL, ti, { CFrame = openLeftCF }):Play()
		TweenService:Create(leafR, ti, { CFrame = openRightCF }):Play()
		task.delay(0.85, function()
			leafL.CanCollide = false
			leafR.CanCollide = false
		end)

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://9114223170"
		sound.Volume = 0.85
		sound.PlaybackSpeed = 0.65
		sound.Parent = beacon
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 3)

		for _, p in ipairs(Players:GetPlayers()) do
			survivalFeedbackEvent:FireClient(p, "Notice", "⚠️ ประตูเขตทดลองลับชั้น 11 ถูกปลดล็อกแล้ว! ระวังสิ่งผิดปกติภายใน")
		end
	end)
end

local function buildFloor11LabProps()
	if not floor11Model then return end
	local f11Y = floorY(11) -- 221.0

	upgradeFloor11Entrance(floor11Model:FindFirstChild("NorthCore_F11"), "BlackGlass_NorthEntrance_F11", -86.35, true)
	upgradeFloor11Entrance(floor11Model:FindFirstChild("SouthCore_F11"), "BlackGlass_SouthEntrance_F11", 86.35, false)

	local oldLab = floor11Model:FindFirstChild("SecretContainmentLab_F11")
	if oldLab then oldLab:Destroy() end

	local lab = Instance.new("Model")
	lab.Name = "SecretContainmentLab_F11"
	lab.Parent = floor11Model

	-- Central Biohazard Containment Pod (Shattered Specimen-01 Chamber) at (0, 221, 0)
	makePart(lab, "PodBase", Vector3.new(10.5, 1.4, 10.5),
		CFrame.new(0, f11Y + 0.7, 0), Color3.fromRGB(34, 38, 46), Enum.Material.Metal)
	makePart(lab, "PodBaseTrim", Vector3.new(10.9, 0.35, 10.9),
		CFrame.new(0, f11Y + 1.45, 0), Color3.fromRGB(220, 55, 55), Enum.Material.Neon, { CanCollide = false })
	makePart(lab, "PodCap", Vector3.new(10.5, 1.6, 10.5),
		CFrame.new(0, f11Y + 12.2, 0), Color3.fromRGB(34, 38, 46), Enum.Material.Metal)
	-- 4 Corner struts
	for _, sx in ipairs({ -4.4, 4.4 }) do
		for _, sz in ipairs({ -4.4, 4.4 }) do
			makePart(lab, "PodStrut_" .. sx .. "_" .. sz, Vector3.new(0.7, 10.2, 0.7),
				CFrame.new(sx, f11Y + 6.5, sz), Color3.fromRGB(52, 58, 66), Enum.Material.Metal)
		end
	end
	-- Intact rear/side cracked glass shards + open front breach
	makePart(lab, "BrokenGlass_Back", Vector3.new(8.2, 9.6, 0.25),
		CFrame.new(0, f11Y + 6.4, -4.3), Color3.fromRGB(110, 220, 175), Enum.Material.Glass, { Transparency = 0.45 })
	makePart(lab, "BrokenGlass_Left", Vector3.new(0.25, 6.2, 8.2),
		CFrame.new(-4.3, f11Y + 4.7, 0), Color3.fromRGB(110, 220, 175), Enum.Material.Glass, { Transparency = 0.5 })
	makePart(lab, "SerumSpill_Center", Vector3.new(13.5, 0.08, 13.5),
		CFrame.new(0, f11Y + 0.05, 5.5), Color3.fromRGB(70, 22, 26), Enum.Material.Glass, { CanCollide = false, Reflectance = 0.2 })

	local podLight = Instance.new("PointLight")
	podLight.Name = "BiohazardCoreLight"
	podLight.Color = Color3.fromRGB(255, 55, 55)
	podLight.Range = 54
	podLight.Brightness = 2.6
	podLight.Enabled = true
	podLight:SetAttribute("HorrorEmergencyLight", true)
	podLight.Parent = makePart(lab, "PodCoreAnchor", Vector3.new(1, 1, 1), CFrame.new(0, f11Y + 6.5, 0),
		Color3.fromRGB(255, 45, 55), Enum.Material.Neon, { Transparency = 1, CanCollide = false })

	-- Lab Warning Sign
	local signPart = makePart(lab, "LabBannerBoard", Vector3.new(11, 2.8, 0.3),
		CFrame.new(0, f11Y + 14.5, 5.2), Color3.fromRGB(28, 16, 18), Enum.Material.SmoothPlastic, { CanCollide = false })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.Parent = signPart
	local sl = Instance.new("TextLabel")
	sl.Size = UDim2.fromScale(1, 1)
	sl.BackgroundTransparency = 1
	sl.Font = Enum.Font.GothamBlack
	sl.TextScaled = true
	sl.TextColor3 = Color3.fromRGB(255, 85, 85)
	sl.Text = "☣ CONTAINMENT BREACH // PROJECT KM-40\nTHE SUBJECT ESCAPED — STAIRS TO ROOFTOP (F12)"
	sl.Parent = sg

	-- Research Dossier Terminal Desk (Readable Clue)
	local desk = makePart(lab, "ResearchTerminalDesk", Vector3.new(6.4, 3.0, 3.2),
		CFrame.new(13.5, f11Y + 1.5, 22), Color3.fromRGB(40, 44, 52), Enum.Material.Metal)
	local screen = makePart(lab, "ResearchMonitor", Vector3.new(2.8, 1.8, 0.25),
		CFrame.new(13.5, f11Y + 3.9, 21.8), Color3.fromRGB(70, 225, 165), Enum.Material.Neon, { CanCollide = false })
	local logPrompt = Instance.new("ProximityPrompt")
	logPrompt.ActionText = "อ่านไฟล์บันทึกการทดลอง"
	logPrompt.ObjectText = "PROJECT KM-40 // บันทึกลับ #11"
	logPrompt.KeyboardKeyCode = Enum.KeyCode.E
	logPrompt.HoldDuration = 0.6
	logPrompt.MaxActivationDistance = 10
	logPrompt.RequiresLineOfSight = false
	logPrompt.Parent = screen
	logPrompt.Triggered:Connect(function(p)
		survivalFeedbackEvent:FireClient(p, "LoreRead", "📂 บันทึก #KM-40: ตัวอย่าง SUBJECT-01 หลุดจากห้องทดลองชั้น 11 — ลิฟต์ตัดการทำงาน หนีขึ้นบันไดสู่ ฮ ชั้น 12 เท่านั้น!")
	end)
end

----------------------------------------------------------------------
-- 3. RED EMERGENCY STAIRWELL BEACONS (TAGGED FOR HORROR MODES)
----------------------------------------------------------------------
local function buildStairwellEmergencyLights()
	local oldFolder = Workspace:FindFirstChild("Building40_EmergencyBeacons")
	if oldFolder then oldFolder:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name = "Building40_EmergencyBeacons"
	folder.Parent = Workspace

	local cores = {
		{ name = "Front", x = -49, z = 103 },
		{ name = "Rear",  x = 49,  z = -103 },
	}
	for fl = 1, 12 do
		local y = floorY(fl) + 17.5
		for _, c in ipairs(cores) do
			local lamp = makePart(folder, string.format("EmergLamp_F%d_%s", fl, c.name),
				Vector3.new(1.6, 0.45, 0.6), CFrame.new(c.x, y, c.z),
				Color3.fromRGB(220, 45, 45), Enum.Material.Neon, { CanCollide = false, CanQuery = false })
			local pl = Instance.new("PointLight")
			pl.Name = "EmergencyRedLight"
			pl.Color = Color3.fromRGB(255, 50, 45)
			pl.Range = 36
			pl.Brightness = 1.65
			pl.Enabled = false -- Toggled cleanly by client Horror Modes (off in [N] Day)
			pl:SetAttribute("HorrorEmergencyLight", true)
			pl.Parent = lamp
		end
	end
end

----------------------------------------------------------------------
-- 4. HUNGER & FLASHLIGHT BATTERY SERVER STATE
----------------------------------------------------------------------
local lastHungerDamageAt = {}
local lastBatteryAdjustAt = {}

local function initPlayerSurvival(player)
	player:SetAttribute("Hunger", 100)
	player:SetAttribute("MaxHunger", 100)
	player:SetAttribute("FlashlightBattery", 100)
	player:SetAttribute("FlashlightOn", true)
	player.CharacterAdded:Connect(function()
		player:SetAttribute("Hunger", 100)
		player:SetAttribute("FlashlightBattery", 100)
		player:SetAttribute("FlashlightOn", true)
		lastHungerDamageAt[player.UserId] = nil
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	initPlayerSurvival(p)
end
Players.PlayerAdded:Connect(initPlayerSurvival)
Players.PlayerRemoving:Connect(function(p)
	lastHungerDamageAt[p.UserId] = nil
	lastBatteryAdjustAt[p.UserId] = nil
end)

flashlightSyncEvent.OnServerEvent:Connect(function(player, isEnabled)
	if type(isEnabled) ~= "boolean" then return end
	local now = os.clock()
	if now - (lastBatteryAdjustAt[player.UserId] or 0) < 0.08 then return end
	lastBatteryAdjustAt[player.UserId] = now
	player:SetAttribute("FlashlightOn", isEnabled)
end)

horrorModeSyncEvent.OnServerEvent:Connect(function(player, isInHorrorLighting)
	if type(isInHorrorLighting) ~= "boolean" then return end
	player:SetAttribute("ClientHorrorLighting", isInHorrorLighting)
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local isAlive = hum and hum.Health > 0 and hrp
			local isDowned = (player:GetAttribute("IsDowned") == true) or (char and char:GetAttribute("IsDowned") == true)
			local isAdmin = (player:GetAttribute("IsAdminGodMode") == true)
			local inRange = isAlive and isPlayerInsideTestRange(player)

			local curHunger = player:GetAttribute("Hunger")
			if type(curHunger) ~= "number" then curHunger = 100 end
			local curBat = player:GetAttribute("FlashlightBattery")
			if type(curBat) ~= "number" then curBat = 100 end

			if isAdmin or inRange then
				if curHunger < 100 then
					player:SetAttribute("Hunger", math.min(100, curHunger + 12))
				end
				if curBat < 100 then
					player:SetAttribute("FlashlightBattery", math.min(100, curBat + 15))
				end
			elseif isAlive and not isDowned then
				-- Hunger drain: faster when boosting (>23.5 studs/s)
				local horizSpeed = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
				local isBoostingOrSliding = horizSpeed > 23.2
				local hungerDrain = isBoostingOrSliding and 0.44 or 0.24 -- per 0.5s tick
				local nextHunger = math.max(0, curHunger - hungerDrain)
				player:SetAttribute("Hunger", nextHunger)

				if nextHunger <= 0 then
					local lastDmg = lastHungerDamageAt[player.UserId] or 0
					if now - lastDmg >= 3.5 and hum.Health > 15 then
						lastHungerDamageAt[player.UserId] = now
						hum.Health = math.max(15, hum.Health - 2)
					end
				end

				-- Flashlight battery drain only when turned ON & client is in Horror Lighting mode
				local lightOn = player:GetAttribute("FlashlightOn") == true
				local horrorOn = player:GetAttribute("ClientHorrorLighting") ~= false
				if lightOn and horrorOn then
					player:SetAttribute("FlashlightBattery", math.max(0, curBat - 0.35))
				elseif not lightOn and curBat < 20 then
					-- Gentle emergency trickle up to 20% when switched off so players are never permanently blind
					player:SetAttribute("FlashlightBattery", math.min(20, curBat + 1.25))
				end
			end
		end
	end
end)

----------------------------------------------------------------------
-- 5. WORLD SURVIVAL LOOT (FLOOR 2 CANTEEN FOOD & WEAPONS + FLOOR 11)
----------------------------------------------------------------------
local lootFolder = Workspace:FindFirstChild("Building40_SurvivalLoot")
if lootFolder then lootFolder:Destroy() end
lootFolder = Instance.new("Folder")
lootFolder.Name = "Building40_SurvivalLoot"
lootFolder.Parent = Workspace

local LOOT_STYLES = {
	Meal = {
		size = Vector3.new(1.5, 0.75, 1.2),
		color = Color3.fromRGB(235, 145, 45),
		trimColor = Color3.fromRGB(255, 220, 120),
		lightColor = Color3.fromRGB(255, 175, 75),
		action = "กินอาหาร",
		respawn = 70,
	},
	Drink = {
		size = Vector3.new(0.65, 1.35, 0.65),
		color = Color3.fromRGB(70, 195, 240),
		trimColor = Color3.fromRGB(165, 245, 255),
		lightColor = Color3.fromRGB(90, 215, 255),
		action = "ดื่มเครื่องดื่ม",
		respawn = 65,
	},
	Medkit = {
		size = Vector3.new(1.6, 0.9, 1.1),
		color = Color3.fromRGB(238, 242, 248),
		trimColor = Color3.fromRGB(230, 55, 65),
		lightColor = Color3.fromRGB(255, 95, 95),
		action = "ใช้ชุดปฐมพยาบาล (+45 HP)",
		respawn = 85,
	},
	Battery = {
		size = Vector3.new(0.85, 1.0, 0.85),
		color = Color3.fromRGB(40, 48, 56),
		trimColor = Color3.fromRGB(255, 210, 45),
		lightColor = Color3.fromRGB(255, 215, 65),
		action = "เก็บถ่านไฟฉาย (+55%)",
		respawn = 70,
	},
	Ammo = {
		size = Vector3.new(1.7, 0.95, 1.2),
		color = Color3.fromRGB(54, 72, 48),
		trimColor = Color3.fromRGB(240, 185, 45),
		lightColor = Color3.fromRGB(240, 185, 45),
		action = "เติมกระสุนสำรอง",
		respawn = 75,
	},
	Weapon = {
		size = Vector3.new(2.4, 0.95, 1.35),
		color = Color3.fromRGB(36, 42, 50),
		trimColor = Color3.fromRGB(80, 215, 255),
		lightColor = Color3.fromRGB(90, 220, 255),
		action = "หยิบอาวุธฉุกเฉิน",
		respawn = 45,
	},
}

local function spawnPickup(def)
	local style = LOOT_STYLES[def.kind]
	if not style then return end

	local m = Instance.new("Model")
	m.Name = def.id
	m.Parent = lootFolder

	local body = makePart(m, "CrateBody", style.size,
		CFrame.new(def.pos + Vector3.new(0, style.size.Y * 0.5, 0)) * CFrame.Angles(0, math.rad(def.yaw or 0), 0),
		style.color, Enum.Material.SmoothPlastic, { CanCollide = false })
	local stripe = makePart(m, "Trim", Vector3.new(style.size.X + 0.06, 0.18, style.size.Z + 0.06),
		body.CFrame * CFrame.new(0, style.size.Y * 0.15, 0),
		style.trimColor, Enum.Material.Neon, { CanCollide = false })
	local glow = Instance.new("PointLight")
	glow.Color = style.lightColor
	glow.Range = 9
	glow.Brightness = 0.85
	glow.Parent = stripe

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LootPrompt"
	prompt.ActionText = def.actionText or style.action
	prompt.ObjectText = def.label
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = (def.kind == "Weapon") and 0.45 or 0.2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	local available = true
	prompt.Triggered:Connect(function(player)
		if not available then return end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or hum.Health <= 0 or not root then return end
		if (root.Position - body.Position).Magnitude > prompt.MaxActivationDistance + 4 then return end

		local consumed = true
		if def.kind == "Meal" or def.kind == "Drink" then
			local curH = player:GetAttribute("Hunger") or 100
			if curH >= 99 and hum.Health >= hum.MaxHealth and (def.staminaGain or 0) <= 0 then
				survivalFeedbackEvent:FireClient(player, "Notice", "ยังไม่หิวและพลังเต็มอยู่แล้ว")
				return
			end
			player:SetAttribute("Hunger", math.min(100, curH + (def.hungerGain or 30)))
			if (def.hpGain or 0) > 0 then
				hum.Health = math.min(hum.MaxHealth, hum.Health + def.hpGain)
			end
			survivalFeedbackEvent:FireClient(player, "EatFood", string.format("%s (+%d%% ความอิ่ม)", def.label, def.hungerGain or 30), def.staminaGain or 0, def.kind == "Drink")
		elseif def.kind == "Medkit" then
			if hum.Health >= hum.MaxHealth then
				survivalFeedbackEvent:FireClient(player, "Notice", "HP เต็มอยู่แล้ว")
				return
			end
			hum.Health = math.min(hum.MaxHealth, hum.Health + 45)
			survivalFeedbackEvent:FireClient(player, "Medkit", "ใช้ชุดปฐมพยาบาล (+45 HP)")
		elseif def.kind == "Battery" then
			local curB = player:GetAttribute("FlashlightBattery") or 100
			if curB >= 99 then
				survivalFeedbackEvent:FireClient(player, "Notice", "ถ่านไฟฉายเต็มอยู่แล้ว")
				return
			end
			player:SetAttribute("FlashlightBattery", math.min(100, curB + 55))
			survivalFeedbackEvent:FireClient(player, "Battery", "เปลี่ยนถ่านไฟฉาย (+55% Battery)")
		elseif def.kind == "Ammo" then
			if refillAmmoSignal then
				refillAmmoSignal:Fire(player)
			end
			survivalFeedbackEvent:FireClient(player, "Ammo", "เติมกระสุนสำรองเต็มทุกช่องปืน!")
		elseif def.kind == "Weapon" then
			if grantWeaponSignal and def.weaponKey then
				grantWeaponSignal:Fire(player, def.weaponKey)
				survivalFeedbackEvent:FireClient(player, "WeaponFound", string.format("ได้รับอาวุธ: %s (กด [3] เก็บปืนเพื่อวิ่งไว)", def.weaponKey))
			else
				consumed = false
			end
		end

		if not consumed then return end
		available = false
		prompt.Enabled = false
		body.Transparency = 1
		stripe.Transparency = 1
		glow.Enabled = false

		task.delay(style.respawn, function()
			available = true
			if body.Parent then
				body.Transparency = 0
				stripe.Transparency = 0
				glow.Enabled = true
				prompt.Enabled = true
			end
		end)
	end)
end

local f1Y = floorY(1)   -- 1.0
local f2Y = floorY(2)   -- 23.0
local f3Y = floorY(3)   -- 45.0
local f7Y = floorY(7)   -- 133.0
local f11Y = floorY(11) -- 221.0

local LOOT_TABLE = {
	-- Floor 1 emergency supplies (NO guns yet -> climb up to Floor 2 to arm up!)
	{ id = "F1_SecurityBattery", kind = "Battery", pos = Vector3.new(-22, f1Y, 54), label = "ถ่านไฟฉายสำรอง (ชั้น 1)" },
	{ id = "F1_LobbySnack",      kind = "Drink",   pos = Vector3.new(20, f1Y, -54), label = "น้ำดื่มฉุกเฉิน (ชั้น 1)", hungerGain = 22, hpGain = 5, staminaGain = 35 },

	-- Floor 2 Canteen Food Stalls 1-8 (placed on front edge of stall counters X = ±116.2, Y = 27.15)
	{ id = "F2_Stall1_Noodle",   kind = "Meal",    pos = Vector3.new(-116.2, f2Y + 4.2, -64.5), label = "ก๋วยเตี๋ยวเรือ มจพ. (+40% อิ่ม)", hungerGain = 40, hpGain = 14 },
	{ id = "F2_Stall2_ChickRice",kind = "Meal",    pos = Vector3.new(-116.2, f2Y + 4.2, -21.5), label = "ข้าวมันไก่ตอน (+40% อิ่ม)", hungerGain = 40, hpGain = 14 },
	{ id = "F2_Stall3_Curry",    kind = "Meal",    pos = Vector3.new(-116.2, f2Y + 4.2, 21.5),  label = "ข้าวราดแกงปักษ์ใต้ (+40% อิ่ม)", hungerGain = 40, hpGain = 14 },
	{ id = "F2_Stall4_Pork",     kind = "Meal",    pos = Vector3.new(-116.2, f2Y + 4.2, 64.5),  label = "ข้าวหมูกรอบ (+40% อิ่ม)", hungerGain = 40, hpGain = 14 },
	{ id = "F2_Stall5_Boba",     kind = "Drink",   pos = Vector3.new(116.2, f2Y + 4.2, -64.5),  label = "ชานมไข่มุกเย็น (+24% อิ่ม / Stamina)", hungerGain = 24, hpGain = 5, staminaGain = 40 },
	{ id = "F2_Stall6_Smoothie", kind = "Drink",   pos = Vector3.new(116.2, f2Y + 4.2, -21.5),  label = "น้ำปั่นผลไม้ (+24% อิ่ม / Stamina)", hungerGain = 24, hpGain = 8, staminaGain = 40 },
	{ id = "F2_Stall7_Omelette", kind = "Meal",    pos = Vector3.new(116.2, f2Y + 4.2, 21.5),   label = "ข้าวไข่เจียว (+35% อิ่ม)", hungerGain = 35, hpGain = 12 },
	{ id = "F2_Stall8_Cooked",   kind = "Meal",    pos = Vector3.new(116.2, f2Y + 4.2, 64.5),   label = "อาหารตามสั่ง (+38% อิ่ม)", hungerGain = 38, hpGain = 12 },

	-- Floor 2 Center Tables & AC Dining Rooms (Snacks, Medkits, Batteries)
	{ id = "F2_Table_Drink1",    kind = "Drink",   pos = Vector3.new(-30, f2Y + 3.6, -11), label = "น้ำดื่มบนโต๊ะโรงอาหาร", hungerGain = 20, hpGain = 5, staminaGain = 30 },
	{ id = "F2_Table_Med1",      kind = "Medkit",  pos = Vector3.new(30, f2Y + 3.6, 11),   label = "ชุดปฐมพยาบาล (โต๊ะโรงอาหาร)" },
	{ id = "F2_Table_Bat1",      kind = "Battery", pos = Vector3.new(0, f2Y + 3.6, 33),    label = "ถ่านไฟฉาย (โต๊ะโรงอาหาร)" },
	{ id = "F2_AC1_Meal",        kind = "Meal",    pos = Vector3.new(-75.5, f2Y + 3.4, -103), label = "ข้าวกล่องห้องแอร์ 1", hungerGain = 35, hpGain = 10 },
	{ id = "F2_AC2_Bat",         kind = "Battery", pos = Vector3.new(90.5, f2Y + 3.4, -103),  label = "ถ่านไฟฉายห้องแอร์ 2" },

	-- Floor 2 Starter Weapon & Supply Cases (Reward for reaching Floor 2 Unarmed!)
	{ id = "F2_Storage_Classic", kind = "Weapon",  pos = Vector3.new(-49, f2Y + 3.0, -81), weaponKey = "Classic", label = "ปืนพกฉุกเฉิน: Classic (ห้องพัสดุชั้น 2)", actionText = "หยิบปืนพก Classic" },
	{ id = "F2_Storage_Ammo",    kind = "Ammo",    pos = Vector3.new(-53, f2Y + 3.0, -81), label = "กล่องกระสุนสำรอง (ห้องพัสดุชั้น 2)" },
	{ id = "F2_Office_Spectre",  kind = "Weapon",  pos = Vector3.new(49, f2Y + 3.0, 81),   weaponKey = "Spectre", label = "ปืนกลมือ: Spectre (สำนักงานชั้น 2)", actionText = "หยิบปืน Spectre" },
	{ id = "F2_Office_Med",      kind = "Medkit",  pos = Vector3.new(53, f2Y + 3.0, 81),   label = "ชุดปฐมพยาบาล (สำนักงานชั้น 2)" },

	-- Upper Floors (3, 7, 11 Secret Lab, 12 Helipad Support)
	{ id = "F3_Arena_Bat",       kind = "Battery", pos = Vector3.new(-28, f3Y, 0), label = "ถ่านไฟฉาย (ชั้น 3 สนามกีฬา)" },
	{ id = "F3_Arena_Snack",     kind = "Drink",   pos = Vector3.new(28, f3Y, 0),  label = "เครื่องดื่มเกลือแร่ (ชั้น 3)", hungerGain = 26, hpGain = 10, staminaGain = 45 },
	{ id = "F7_Medkit",          kind = "Medkit",  pos = Vector3.new(0, f7Y, -82), label = "ชุดปฐมพยาบาล (ชั้น 7)" },
	{ id = "F7_Meal",            kind = "Meal",    pos = Vector3.new(0, f7Y, 82),  label = "เสบียงฉุกเฉิน (ชั้น 7)", hungerGain = 35, hpGain = 12 },

	-- Floor 11 Secret Lab Stash (High-Risk / High-Reward before Rooftop Helipad)
	{ id = "F11_Lab_Vandal",     kind = "Weapon",  pos = Vector3.new(-14, f11Y, -20), weaponKey = "Vandal", label = "ปืนไรเฟิลเขตทดลอง: Vandal (ชั้น 11)", actionText = "หยิบ Vandal ประจำเขต 11" },
	{ id = "F11_Lab_Ammo",       kind = "Ammo",    pos = Vector3.new(-14, f11Y, -16), label = "คลังกระสุนเขตทดลอง (ชั้น 11)" },
	{ id = "F11_Lab_Medkit",     kind = "Medkit",  pos = Vector3.new(13.5, f11Y + 3.0, 24), label = "ชุดปฐมพยาบาล (โต๊ะวิจัยชั้น 11)" },
	{ id = "F11_Lab_Battery",    kind = "Battery", pos = Vector3.new(13.5, f11Y + 3.0, 20), label = "แบตเตอรี่สำรอง (ชั้น 11)" },
}

buildFloor11LabProps()
buildStairwellEmergencyLights()
for _, item in ipairs(LOOT_TABLE) do
	spawnPickup(item)
end

print("🏚️ [SurvivalAndHorrorSetup] ระบบ Floor 11 ห้องทดลองลับ, เสบียง/อาหารชั้น 2, ความหิว และไฟฉุกเฉิน พร้อมใช้งาน!")
