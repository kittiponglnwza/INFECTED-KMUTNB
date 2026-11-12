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
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local campaignFolder = ServerScriptService:WaitForChild("Campaign", 10)
local DevAuthService = require(campaignFolder:WaitForChild("DevAuthService"))
local devAuth = DevAuthService.getSingleton()

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
local useSupplySlotEvent = getOrCreateRemote("UseSupplySlot")

local weaponSignals = ServerStorage:WaitForChild("WeaponSignals", 20)
local grantWeaponSignal = weaponSignals and weaponSignals:WaitForChild("GrantWeapon", 10)
local refillAmmoSignal = weaponSignals and weaponSignals:WaitForChild("RefillAmmo", 10)
local addPointsSignal = weaponSignals and weaponSignals:WaitForChild("AddPoints", 10)
local zombieKilledLootSignal = weaponSignals and weaponSignals:WaitForChild("ZombieKilledLoot", 10)

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

		local campaignSignals = ServerStorage:FindFirstChild("CampaignSignals")
		local requestDoorFn = campaignSignals and campaignSignals:FindFirstChild("RequestDoorAccess")
		if requestDoorFn and requestDoorFn:IsA("BindableFunction") then
			local okCall, allowed, denyMsg = pcall(function()
				return requestDoorFn:Invoke("F11_QUARANTINE_AIRLOCK", triggerPlayer, beacon)
			end)
			if okCall and allowed == false then
				survivalFeedbackEvent:FireClient(triggerPlayer, "Notice", "🔒 " .. tostring(denyMsg or "Quarantine Clearance Tier 3 & Power required."))
				return
			end
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
-- 4. HUNGER, FLASHLIGHT BATTERY & HOTBAR CONSUMABLE POUCH STATE
----------------------------------------------------------------------
local MAX_FOOD_PACKS = 4
local MAX_MEDKIT_PACKS = 3
local MAX_BATTERY_PACKS = 4

local lastHungerDamageAt = {}
local lastBatteryAdjustAt = {}
local lastSupplyUseAt = {}

local function initPlayerSurvival(player)
	player:SetAttribute("Hunger", 100)
	player:SetAttribute("MaxHunger", 100)
	player:SetAttribute("FlashlightBattery", 100)
	player:SetAttribute("FlashlightOn", true)
	player:SetAttribute("FoodPacks", 1) -- start with 1 pocket emergency snack
	player:SetAttribute("MedkitPacks", 0)
	player:SetAttribute("BatteryPacks", 1) -- start with 1 spare battery cell
	player:SetAttribute("StaminaBoostUntil", 0)
	player.CharacterAdded:Connect(function()
		player:SetAttribute("Hunger", 100)
		player:SetAttribute("FlashlightBattery", 100)
		player:SetAttribute("FlashlightOn", true)
		player:SetAttribute("StaminaBoostUntil", 0)
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
	lastSupplyUseAt[p.UserId] = nil
end)

useSupplySlotEvent.OnServerEvent:Connect(function(player, slotIdx)
	if slotIdx ~= 4 and slotIdx ~= 5 and slotIdx ~= 6 then return end
	local now = os.clock()
	if now - (lastSupplyUseAt[player.UserId] or 0) < 0.35 then return end
	lastSupplyUseAt[player.UserId] = now

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	if slotIdx == 4 then
		local count = player:GetAttribute("FoodPacks") or 0
		if count <= 0 then
			survivalFeedbackEvent:FireClient(player, "Notice", "ช่อง [4] เสบียงว่าง — หาของกินตามโรงอาหารชั้น 2 / คาเฟ่ชั้น 1")
			return
		end
		local curH = player:GetAttribute("Hunger") or 100
		if curH >= 98 and hum.Health >= hum.MaxHealth then
			survivalFeedbackEvent:FireClient(player, "Notice", "อิ่มและเลือดเต็มอยู่แล้ว เก็บเสบียงไว้ก่อนดีกว่า")
			return
		end
		player:SetAttribute("FoodPacks", math.max(0, count - 1))
		player:SetAttribute("Hunger", math.min(100, curH + 35))
		hum.Health = math.min(hum.MaxHealth, hum.Health + 12)
		survivalFeedbackEvent:FireClient(player, "EatFood", "[4] กินเสบียงพกพา (+35% อิ่ม, +12 HP, +Stamina)", 35, false)
	elseif slotIdx == 5 then
		local count = player:GetAttribute("MedkitPacks") or 0
		if count <= 0 then
			survivalFeedbackEvent:FireClient(player, "Notice", "ช่อง [5] ไม่มีชุดปฐมพยาบาล")
			return
		end
		if hum.Health >= hum.MaxHealth then
			survivalFeedbackEvent:FireClient(player, "Notice", "HP เต็มอยู่แล้ว!")
			return
		end
		player:SetAttribute("MedkitPacks", math.max(0, count - 1))
		hum.Health = math.min(hum.MaxHealth, hum.Health + 45)
		survivalFeedbackEvent:FireClient(player, "Medkit", "[5] ใช้ชุดปฐมพยาบาล (+45 HP)")
	elseif slotIdx == 6 then
		local count = player:GetAttribute("BatteryPacks") or 0
		if count <= 0 then
			survivalFeedbackEvent:FireClient(player, "Notice", "ช่อง [6] ไม่มีถ่านไฟฉายสำรอง")
			return
		end
		local curB = player:GetAttribute("FlashlightBattery") or 100
		if curB >= 98 then
			survivalFeedbackEvent:FireClient(player, "Notice", "แบตไฟฉายเต็มอยู่แล้ว!")
			return
		end
		player:SetAttribute("BatteryPacks", math.max(0, count - 1))
		player:SetAttribute("FlashlightBattery", math.min(100, curB + 55))
		survivalFeedbackEvent:FireClient(player, "Battery", "[6] เปลี่ยนถ่านไฟฉาย (+55% Battery)")
	end
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
	if not devAuth.isDevModeEnabled(player) then
		-- Campaign players cannot bypass flashlight battery drain via client lighting flags
		player:SetAttribute("ClientHorrorLighting", true)
		return
	end
	player:SetAttribute("ClientHorrorLighting", isInHorrorLighting)
end)

-- Exposed for DevCommandService (!give food / medkit / battery)
local survivalSignals = ServerStorage:FindFirstChild("SurvivalSignals") or Instance.new("Folder")
survivalSignals.Name = "SurvivalSignals"
survivalSignals.Parent = ServerStorage
local grantSupplyBindable = survivalSignals:FindFirstChild("GrantSupply") or Instance.new("BindableFunction")
grantSupplyBindable.Name = "GrantSupply"
grantSupplyBindable.Parent = survivalSignals
grantSupplyBindable.OnInvoke = function(player, kind)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "Invalid player"
	end
	if kind == "Food" then
		local cur = player:GetAttribute("FoodPacks") or 0
		player:SetAttribute("FoodPacks", math.min(MAX_FOOD_PACKS, cur + 1))
		survivalFeedbackEvent:FireClient(player, "Notice", "[DEV] Granted +1 Emergency Ration [4]")
		return true, "FoodPacks = " .. tostring(player:GetAttribute("FoodPacks"))
	elseif kind == "Medkit" then
		local cur = player:GetAttribute("MedkitPacks") or 0
		player:SetAttribute("MedkitPacks", math.min(MAX_MEDKIT_PACKS, cur + 1))
		survivalFeedbackEvent:FireClient(player, "Notice", "[DEV] Granted +1 Medkit [5]")
		return true, "MedkitPacks = " .. tostring(player:GetAttribute("MedkitPacks"))
	elseif kind == "Battery" then
		local cur = player:GetAttribute("BatteryPacks") or 0
		player:SetAttribute("BatteryPacks", math.min(MAX_BATTERY_PACKS, cur + 1))
		survivalFeedbackEvent:FireClient(player, "Notice", "[DEV] Granted +1 Battery [6]")
		return true, "BatteryPacks = " .. tostring(player:GetAttribute("BatteryPacks"))
	end
	return false, "Unknown supply kind"
end

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
			local isAdmin = devAuth.isGodModeEnabled(player)
			local inRange = isAlive and isPlayerInsideTestRange(player) and devAuth.isDevModeEnabled(player)

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

				-- Flashlight battery drain only when turned ON (and only exempt when authorized dev enables Day lighting)
				local lightOn = player:GetAttribute("FlashlightOn") == true
				local devDayExempt = devAuth.isDevModeEnabled(player) and player:GetAttribute("ClientHorrorLighting") == false
				if lightOn and not devDayExempt then
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
-- 5. WORLD SURVIVAL LOOT (RICH SILHOUETTES, POUCH PACKS, VENDING & DROPS)
----------------------------------------------------------------------
local lootFolder = Workspace:FindFirstChild("Building40_SurvivalLoot")
if lootFolder then lootFolder:Destroy() end
lootFolder = Instance.new("Folder")
lootFolder.Name = "Building40_SurvivalLoot"
lootFolder.Parent = Workspace

local LOOT_STYLES = {
	Meal = {
		lightColor = Color3.fromRGB(255, 175, 75),
		action = "กินอาหารร้อน / แพ็ค [4]",
		respawn = 55,
	},
	Ration = {
		lightColor = Color3.fromRGB(255, 200, 95),
		action = "เก็บเสบียง [4]",
		respawn = 55,
	},
	Drink = {
		lightColor = Color3.fromRGB(95, 215, 255),
		action = "เก็บเครื่องดื่ม [4]",
		respawn = 50,
	},
	Energy = {
		lightColor = Color3.fromRGB(65, 255, 220),
		action = "ดื่มชูกำลัง (วิ่งฟรี 15 วิ)",
		respawn = 65,
	},
	Medkit = {
		lightColor = Color3.fromRGB(255, 95, 95),
		action = "เก็บชุดปฐมพยาบาล [5]",
		respawn = 70,
	},
	Battery = {
		lightColor = Color3.fromRGB(255, 220, 70),
		action = "เก็บถ่านไฟฉาย [6]",
		respawn = 60,
	},
	Ammo = {
		lightColor = Color3.fromRGB(240, 185, 45),
		action = "เติมกระสุนสำรอง",
		respawn = 60,
	},
	Points = {
		lightColor = Color3.fromRGB(255, 215, 65),
		action = "เก็บซองแต้มฉุกเฉิน",
		respawn = 85,
	},
	Weapon = {
		lightColor = Color3.fromRGB(90, 220, 255),
		action = "หยิบอาวุธ",
		respawn = 45,
	},
}

local function addLootPart(model, visualParts, name, size, cf, color, material, extra)
	local p = makePart(model, name, size, cf, color, material or Enum.Material.SmoothPlastic, extra)
	p.CanCollide = false
	table.insert(visualParts, { part = p, baseTransparency = p.Transparency })
	return p
end

local function buildLootVisuals(model, kind, basePos, yaw)
	local visualParts = {}
	local rotCF = CFrame.new(basePos) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local style = LOOT_STYLES[kind]
	local anchorPart

	if kind == "Meal" or kind == "Ration" then
		local trayCol = (kind == "Meal") and Color3.fromRGB(230, 145, 50) or Color3.fromRGB(165, 140, 95)
		anchorPart = addLootPart(model, visualParts, "TrayBase", Vector3.new(1.75, 0.22, 1.25),
			rotCF * CFrame.new(0, 0.11, 0), Color3.fromRGB(48, 52, 60), Enum.Material.Metal)
		addLootPart(model, visualParts, "FoodBox", Vector3.new(1.3, 0.55, 0.95),
			rotCF * CFrame.new(0, 0.48, 0), trayCol, Enum.Material.SmoothPlastic)
		addLootPart(model, visualParts, "LidBand", Vector3.new(1.36, 0.12, 0.3),
			rotCF * CFrame.new(0, 0.78, 0), style.lightColor, Enum.Material.Neon)
	elseif kind == "Drink" or kind == "Energy" then
		local col = (kind == "Energy") and Color3.fromRGB(18, 220, 195) or Color3.fromRGB(65, 185, 240)
		local h = (kind == "Energy") and 1.25 or 1.45
		anchorPart = addLootPart(model, visualParts, "BottleBody", Vector3.new(h, 0.68, 0.68),
			rotCF * CFrame.new(0, h * 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
			col, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
		addLootPart(model, visualParts, "Cap", Vector3.new(0.24, 0.34, 0.34),
			rotCF * CFrame.new(0, h + 0.10, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(245, 245, 250), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
		addLootPart(model, visualParts, "LabelRing", Vector3.new(0.26, 0.72, 0.72),
			rotCF * CFrame.new(0, h * 0.55, 0) * CFrame.Angles(0, 0, math.rad(90)),
			style.lightColor, Enum.Material.Neon, { Shape = Enum.PartType.Cylinder })
	elseif kind == "Medkit" then
		anchorPart = addLootPart(model, visualParts, "MedCase", Vector3.new(1.65, 0.72, 1.18),
			rotCF * CFrame.new(0, 0.36, 0), Color3.fromRGB(242, 246, 252), Enum.Material.SmoothPlastic)
		addLootPart(model, visualParts, "CrossH", Vector3.new(0.78, 0.12, 0.24),
			rotCF * CFrame.new(0, 0.78, 0), Color3.fromRGB(225, 45, 55), Enum.Material.Neon)
		addLootPart(model, visualParts, "CrossV", Vector3.new(0.24, 0.12, 0.78),
			rotCF * CFrame.new(0, 0.78, 0), Color3.fromRGB(225, 45, 55), Enum.Material.Neon)
	elseif kind == "Battery" then
		anchorPart = addLootPart(model, visualParts, "CellBody", Vector3.new(1.05, 0.76, 0.76),
			rotCF * CFrame.new(0, 0.525, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(36, 40, 48), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
		addLootPart(model, visualParts, "CopperBand", Vector3.new(0.26, 0.80, 0.80),
			rotCF * CFrame.new(0, 0.88, 0) * CFrame.Angles(0, 0, math.rad(90)),
			style.lightColor, Enum.Material.Neon, { Shape = Enum.PartType.Cylinder })
		addLootPart(model, visualParts, "PositiveTip", Vector3.new(0.16, 0.30, 0.30),
			rotCF * CFrame.new(0, 1.10, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(235, 200, 85), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	elseif kind == "Points" then
		anchorPart = addLootPart(model, visualParts, "Pouch", Vector3.new(1.4, 0.55, 1.05),
			rotCF * CFrame.new(0, 0.275, 0), Color3.fromRGB(45, 38, 22), Enum.Material.Fabric)
		addLootPart(model, visualParts, "GoldPlate", Vector3.new(1.46, 0.16, 0.35),
			rotCF * CFrame.new(0, 0.58, 0), Color3.fromRGB(255, 212, 65), Enum.Material.Neon)
	elseif kind == "Ammo" then
		anchorPart = addLootPart(model, visualParts, "AmmoCrate", Vector3.new(1.75, 0.92, 1.2),
			rotCF * CFrame.new(0, 0.46, 0), Color3.fromRGB(58, 76, 50), Enum.Material.Metal)
		addLootPart(model, visualParts, "AmmoLatch", Vector3.new(1.80, 0.16, 0.28),
			rotCF * CFrame.new(0, 0.72, 0), Color3.fromRGB(240, 185, 45), Enum.Material.Neon)
	else -- Weapon
		anchorPart = addLootPart(model, visualParts, "GunCase", Vector3.new(2.75, 0.85, 1.3),
			rotCF * CFrame.new(0, 0.425, 0), Color3.fromRGB(30, 36, 44), Enum.Material.Metal)
		addLootPart(model, visualParts, "CaseStripe", Vector3.new(2.80, 0.16, 1.36),
			rotCF * CFrame.new(0, 0.58, 0), style.lightColor, Enum.Material.Neon)
	end

	local glow = Instance.new("PointLight")
	glow.Color = style.lightColor
	glow.Range = 9
	glow.Brightness = 0.85
	glow.Parent = anchorPart

	return anchorPart, visualParts, glow
end

local function handleLootCollect(player, def)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end

	if def.kind == "Meal" then
		local curH = player:GetAttribute("Hunger") or 100
		local packs = player:GetAttribute("FoodPacks") or 0
		if curH < 85 then
			player:SetAttribute("Hunger", math.min(100, curH + (def.hungerGain or 40)))
			if (def.hpGain or 0) > 0 then
				hum.Health = math.min(hum.MaxHealth, hum.Health + def.hpGain)
			end
			survivalFeedbackEvent:FireClient(player, "EatFood", string.format("กิน %s (+%d%% อิ่ม)", def.label, def.hungerGain or 40), def.staminaGain or 15, false)
			return true
		elseif packs < MAX_FOOD_PACKS then
			player:SetAttribute("FoodPacks", packs + 1)
			survivalFeedbackEvent:FireClient(player, "Notice", string.format("แพ็ค %s ลงช่อง [4] เสบียง (%d/%d)", def.label, packs + 1, MAX_FOOD_PACKS))
			return true
		elseif curH < 99 or hum.Health < hum.MaxHealth then
			player:SetAttribute("Hunger", math.min(100, curH + (def.hungerGain or 35)))
			hum.Health = math.min(hum.MaxHealth, hum.Health + (def.hpGain or 10))
			survivalFeedbackEvent:FireClient(player, "EatFood", string.format("กิน %s (+%d%% อิ่ม)", def.label, def.hungerGain or 35), def.staminaGain or 15, false)
			return true
		else
			survivalFeedbackEvent:FireClient(player, "Notice", "อิ่มเต็มและช่อง [4] เสบียงเต็มแล้ว (4/4)")
			return false
		end
	elseif def.kind == "Ration" or def.kind == "Drink" then
		local packs = player:GetAttribute("FoodPacks") or 0
		if packs < MAX_FOOD_PACKS then
			player:SetAttribute("FoodPacks", packs + 1)
			survivalFeedbackEvent:FireClient(player, "Notice", string.format("เก็บ %s ➔ ช่อง [4] (%d/%d)", def.label, packs + 1, MAX_FOOD_PACKS))
			return true
		end
		local curH = player:GetAttribute("Hunger") or 100
		if curH >= 98 and hum.Health >= hum.MaxHealth then
			survivalFeedbackEvent:FireClient(player, "Notice", "ช่อง [4] เสบียงเต็มและยังไม่หิว")
			return false
		end
		player:SetAttribute("Hunger", math.min(100, curH + (def.hungerGain or 28)))
		hum.Health = math.min(hum.MaxHealth, hum.Health + (def.hpGain or 8))
		survivalFeedbackEvent:FireClient(player, "EatFood", string.format("%s (+%d%% อิ่ม)", def.label, def.hungerGain or 28), def.staminaGain or 30, def.kind == "Drink")
		return true
	elseif def.kind == "Energy" then
		local curH = player:GetAttribute("Hunger") or 100
		local boostSecs = def.boostSecs or 15
		player:SetAttribute("Hunger", math.min(100, curH + (def.hungerGain or 22)))
		player:SetAttribute("StaminaBoostUntil", Workspace:GetServerTimeNow() + boostSecs)
		survivalFeedbackEvent:FireClient(player, "EatFood", string.format("⚡ %s! วิ่งบูส Shift ฟรี %d วิ", def.label, boostSecs), 100, true)
		return true
	elseif def.kind == "Medkit" then
		local packs = player:GetAttribute("MedkitPacks") or 0
		if packs < MAX_MEDKIT_PACKS then
			player:SetAttribute("MedkitPacks", packs + 1)
			survivalFeedbackEvent:FireClient(player, "Notice", string.format("เก็บชุดปฐมพยาบาล ➔ ช่อง [5] (%d/%d)", packs + 1, MAX_MEDKIT_PACKS))
			return true
		elseif hum.Health < hum.MaxHealth then
			hum.Health = math.min(hum.MaxHealth, hum.Health + 45)
			survivalFeedbackEvent:FireClient(player, "Medkit", "ใช้ชุดปฐมพยาบาลทันที (+45 HP)")
			return true
		end
		survivalFeedbackEvent:FireClient(player, "Notice", "ช่อง [5] ชุดยาเต็ม (3/3) และ HP เต็มอยู่แล้ว")
		return false
	elseif def.kind == "Battery" then
		local packs = player:GetAttribute("BatteryPacks") or 0
		if packs < MAX_BATTERY_PACKS then
			player:SetAttribute("BatteryPacks", packs + 1)
			survivalFeedbackEvent:FireClient(player, "Notice", string.format("เก็บถ่านไฟฉาย ➔ ช่อง [6] (%d/%d)", packs + 1, MAX_BATTERY_PACKS))
			return true
		end
		local curB = player:GetAttribute("FlashlightBattery") or 100
		if curB >= 98 then
			survivalFeedbackEvent:FireClient(player, "Notice", "ช่อง [6] ถ่านเต็ม (4/4) และแบตเต็มอยู่แล้ว")
			return false
		end
		player:SetAttribute("FlashlightBattery", math.min(100, curB + 55))
		survivalFeedbackEvent:FireClient(player, "Battery", "เปลี่ยนถ่านไฟฉายทันที (+55%)")
		return true
	elseif def.kind == "Points" then
		local pts = def.pointsGain or 120
		if addPointsSignal then
			addPointsSignal:Fire(player, pts)
		end
		survivalFeedbackEvent:FireClient(player, "Notice", string.format("💰 เก็บเสบียงแต้ม +%d แต้ม!", pts))
		return true
	elseif def.kind == "Ammo" then
		if refillAmmoSignal then
			refillAmmoSignal:Fire(player)
		end
		survivalFeedbackEvent:FireClient(player, "Ammo", "เติมกระสุนสำรองเต็มทุกช่องปืน!")
		return true
	elseif def.kind == "Weapon" then
		if grantWeaponSignal and def.weaponKey then
			grantWeaponSignal:Fire(player, def.weaponKey)
			survivalFeedbackEvent:FireClient(player, "WeaponFound", string.format("ได้รับอาวุธ: %s (กด [3] เก็บปืนเพื่อวิ่งไว)", def.weaponKey))
			return true
		end
		return false
	end
	return false
end

local function spawnPickup(def)
	local style = LOOT_STYLES[def.kind]
	if not style then return end

	local m = Instance.new("Model")
	m.Name = def.id
	m.Parent = lootFolder

	local body, visualParts, glow = buildLootVisuals(m, def.kind, def.pos, def.yaw)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LootPrompt"
	prompt.ActionText = def.actionText or style.action
	prompt.ObjectText = def.label
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = (def.kind == "Weapon") and 0.4 or 0.15
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	local available = true
	if type(def.despawnSecs) == "number" and def.despawnSecs > 0 then
		Debris:AddItem(m, def.despawnSecs)
	end
	prompt.Triggered:Connect(function(player)
		if not available then return end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - body.Position).Magnitude > prompt.MaxActivationDistance + 4 then return end

		if not handleLootCollect(player, def) then return end

		available = false
		prompt.Enabled = false
		glow.Enabled = false
		for _, vp in ipairs(visualParts) do
			vp.part.Transparency = 1
		end

		if def.oneShot then
			Debris:AddItem(m, 0.25)
			return
		end

		task.delay(style.respawn, function()
			available = true
			if body.Parent then
				for _, vp in ipairs(visualParts) do
					if vp.part.Parent then
						vp.part.Transparency = vp.baseTransparency
					end
				end
				glow.Enabled = true
				prompt.Enabled = true
			end
		end)
	end)
end

-- Interactive Coin/Points Vending Machines & Emergency Supply Kiosks
local function buildVendingStation(id, pos, yaw)
	local station = Instance.new("Model")
	station.Name = "VendingStation_" .. id
	station.Parent = lootFolder

	local baseCF = CFrame.new(pos) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local lastUseByPlayer = {}

	-- Left Machine: Energy & Rations Vending (45 pts)
	local drinkCab = makePart(station, "DrinkVending", Vector3.new(3.4, 7.2, 2.4),
		baseCF * CFrame.new(-2.0, 3.6, 0), Color3.fromRGB(20, 48, 72), Enum.Material.Metal)
	makePart(station, "DrinkFront", Vector3.new(2.7, 3.8, 0.2),
		drinkCab.CFrame * CFrame.new(0, 0.9, -1.2), Color3.fromRGB(95, 225, 255), Enum.Material.Neon, { Transparency = 0.25 })
	local dPrompt = Instance.new("ProximityPrompt")
	dPrompt.ActionText = "ซื้อเครื่องดื่มชูกำลัง [45 แต้ม]"
	dPrompt.ObjectText = "ตู้กดเครื่องดื่มอัตโนมัติ (45 แต้ม)"
	dPrompt.KeyboardKeyCode = Enum.KeyCode.E
	dPrompt.HoldDuration = 0.25
	dPrompt.MaxActivationDistance = 10
	dPrompt.RequiresLineOfSight = false
	dPrompt.Parent = drinkCab

	dPrompt.Triggered:Connect(function(player)
		local now = os.clock()
		if now - (lastUseByPlayer[player.UserId] or 0) < 0.8 then return end
		lastUseByPlayer[player.UserId] = now
		local pts = player:GetAttribute("Points") or 0
		if pts < 45 then
			survivalFeedbackEvent:FireClient(player, "Notice", "แต้มไม่พอ! (ต้องใช้ 45 แต้ม — ยิงซอมบี้หรือหาถุงแต้ม)")
			return
		end
		if addPointsSignal then addPointsSignal:Fire(player, -45) end
		handleLootCollect(player, { kind = "Energy", label = "เครื่องดื่มชูกำลังจากตู้", hungerGain = 26, boostSecs = 15 })
	end)

	-- Right Machine: Emergency Field Supply Kiosk (75 pts -> Pack [4]/[5]/[6] + Ammo)
	local supCab = makePart(station, "SupplyKiosk", Vector3.new(3.4, 7.2, 2.4),
		baseCF * CFrame.new(2.0, 3.6, 0), Color3.fromRGB(48, 32, 30), Enum.Material.Metal)
	makePart(station, "SupplyFront", Vector3.new(2.7, 3.8, 0.2),
		supCab.CFrame * CFrame.new(0, 0.9, -1.2), Color3.fromRGB(255, 165, 65), Enum.Material.Neon, { Transparency = 0.25 })
	local sPrompt = Instance.new("ProximityPrompt")
	sPrompt.ActionText = "เบิกชุดเสบียง+กระสุน [75 แต้ม]"
	sPrompt.ObjectText = "ตู้เสบียงฉุกเฉิน (ยา+ถ่าน+กระสุน 75 แต้ม)"
	sPrompt.KeyboardKeyCode = Enum.KeyCode.E
	sPrompt.HoldDuration = 0.25
	sPrompt.MaxActivationDistance = 10
	sPrompt.RequiresLineOfSight = false
	sPrompt.Parent = supCab

	sPrompt.Triggered:Connect(function(player)
		local now = os.clock()
		if now - (lastUseByPlayer[player.UserId] or 0) < 0.8 then return end
		lastUseByPlayer[player.UserId] = now
		local pts = player:GetAttribute("Points") or 0
		if pts < 75 then
			survivalFeedbackEvent:FireClient(player, "Notice", "แต้มไม่พอ! (ต้องใช้ 75 แต้ม)")
			return
		end
		if addPointsSignal then addPointsSignal:Fire(player, -75) end
		local packs5 = math.min(MAX_MEDKIT_PACKS, (player:GetAttribute("MedkitPacks") or 0) + 1)
		local packs6 = math.min(MAX_BATTERY_PACKS, (player:GetAttribute("BatteryPacks") or 0) + 1)
		player:SetAttribute("MedkitPacks", packs5)
		player:SetAttribute("BatteryPacks", packs6)
		if refillAmmoSignal then refillAmmoSignal:Fire(player) end
		survivalFeedbackEvent:FireClient(player, "Ammo", "🛒 เบิกเสบียงสำเร็จ: +1 ยา [5], +1 ถ่าน [6], เติมกระสุนเต็ม! (-75 แต้ม)")
	end)
end

-- Dynamic Zombie Kill Loot Drops (Combat Farming!)
if zombieKilledLootSignal then
	zombieKilledLootSignal.Event:Connect(function(pos, zombieType)
		if typeof(pos) ~= "Vector3" then return end
		local isBoss = type(zombieType) == "string" and zombieType:lower():find("boss") ~= nil
		local isRunner = type(zombieType) == "string" and zombieType:lower():find("runner") ~= nil
		local chance = isBoss and 1.0 or (isRunner and 0.34 or 0.20)
		if math.random() > chance then return end

		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local excludeList = { lootFolder }
		local zFolder = Workspace:FindFirstChild("ActiveZombies")
		if zFolder then table.insert(excludeList, zFolder) end
		rayParams.FilterDescendantsInstances = excludeList
		local groundHit = Workspace:Raycast(pos + Vector3.new(0, 1, 0), Vector3.new(0, -14, 0), rayParams)
		local dropPos = groundHit and groundHit.Position or Vector3.new(pos.X, math.max(1.0, pos.Y - 3.0), pos.Z)
		local roll = math.random()
		local def
		if isBoss then
			def = { id = "Drop_" .. tostring(os.clock()), kind = "Points", pos = dropPos, label = "กล่องแต้มบอส (+250 แต้ม)", pointsGain = 250, oneShot = true, despawnSecs = 45 }
		elseif roll < 0.28 then
			def = { id = "Drop_" .. tostring(os.clock()), kind = "Ammo", pos = dropPos, label = "ซองกระสุนตกจากซอมบี้", oneShot = true, despawnSecs = 40 }
		elseif roll < 0.52 then
			def = { id = "Drop_" .. tostring(os.clock()), kind = "Ration", pos = dropPos, label = "เสบียงฉุกเฉิน [4]", hungerGain = 28, hpGain = 8, oneShot = true, despawnSecs = 40 }
		elseif roll < 0.76 then
			def = { id = "Drop_" .. tostring(os.clock()), kind = "Battery", pos = dropPos, label = "ถ่านไฟฉาย [6]", oneShot = true, despawnSecs = 40 }
		else
			def = { id = "Drop_" .. tostring(os.clock()), kind = "Points", pos = dropPos, label = "ชิปแต้มฉุกเฉิน (+75)", pointsGain = 75, oneShot = true, despawnSecs = 40 }
		end
		spawnPickup(def)
	end)
end

local f1Y = floorY(1)   -- 1.0
local f2Y = floorY(2)   -- 23.0
local f3Y = floorY(3)   -- 45.0
local f4Y = floorY(4)   -- 67.0
local f5Y = floorY(5)   -- 89.0
local f6Y = floorY(6)   -- 111.0
local f7Y = floorY(7)   -- 133.0
local f8Y = floorY(8)   -- 155.0
local f9Y = floorY(9)   -- 177.0
local f10Y = floorY(10) -- 199.0
local f11Y = floorY(11) -- 221.0
local f12Y = floorY(12) -- 243.0

local LOOT_TABLE = {
	-- FLOOR 1: Lobby, Security & 40th Avenue Cafe & Bakery (Food & Batteries, Guns await on Floor 2+)
	{ id = "F1_SecurityBattery", kind = "Battery", pos = Vector3.new(-22, f1Y, 54), label = "ถ่านไฟฉาย รปภ. (ชั้น 1)" },
	{ id = "F1_LobbySnack",      kind = "Drink",   pos = Vector3.new(20, f1Y, -54), label = "น้ำดื่มฉุกเฉิน (ชั้น 1)", hungerGain = 24, hpGain = 6, staminaGain = 35 },
	{ id = "F1_Cafe_Coffee1",    kind = "Energy",  pos = Vector3.new(92, f1Y + 3.2, -74), label = "เอสเปรสโซ่เย็น คาเฟ่ชั้น 1", hungerGain = 20, boostSecs = 15 },
	{ id = "F1_Cafe_Croissant",  kind = "Ration",  pos = Vector3.new(116, f1Y + 3.2, -74), label = "ครัวซองต์อบใหม่ คาเฟ่ชั้น 1", hungerGain = 30, hpGain = 10 },
	{ id = "F1_Cafe_Drink",      kind = "Drink",   pos = Vector3.new(138, f1Y + 3.2, -54), label = "ชาเขียวมัทฉะ คาเฟ่ชั้น 1", hungerGain = 24, hpGain = 6 },
	{ id = "F1_Cafe_LoungeMed",  kind = "Medkit",  pos = Vector3.new(136, f1Y + 1.6, -98), label = "ชุดปฐมพยาบาล (โซฟาคาเฟ่)" },

	-- FLOOR 2: Canteen Stalls 1-8 (Counters + Kitchen BackBenches!)
	{ id = "F2_Stall1_Noodle",   kind = "Meal",    pos = Vector3.new(-116.2, f2Y + 4.2, -64.5), label = "ก๋วยเตี๋ยวเรือ มจพ.", hungerGain = 40, hpGain = 14 },
	{ id = "F2_Stall2_ChickRice",kind = "Meal",    pos = Vector3.new(-116.2, f2Y + 4.2, -21.5), label = "ข้าวมันไก่ตอน", hungerGain = 40, hpGain = 14 },
	{ id = "F2_Stall3_Curry",    kind = "Meal",    pos = Vector3.new(-116.2, f2Y + 4.2, 21.5),  label = "ข้าวราดแกงปักษ์ใต้", hungerGain = 40, hpGain = 14 },
	{ id = "F2_Stall4_Pork",     kind = "Meal",    pos = Vector3.new(-116.2, f2Y + 4.2, 64.5),  label = "ข้าวหมูกรอบ", hungerGain = 40, hpGain = 14 },
	{ id = "F2_Stall5_Boba",     kind = "Energy",  pos = Vector3.new(116.2, f2Y + 4.2, -64.5),  label = "กาแฟโบราณชูกำลัง", hungerGain = 25, boostSecs = 15 },
	{ id = "F2_Stall6_Smoothie", kind = "Drink",   pos = Vector3.new(116.2, f2Y + 4.2, -21.5),  label = "น้ำปั่นผลไม้สด", hungerGain = 26, hpGain = 10, staminaGain = 40 },
	{ id = "F2_Stall7_Omelette", kind = "Meal",    pos = Vector3.new(116.2, f2Y + 4.2, 21.5),   label = "ข้าวไข่เจียว", hungerGain = 35, hpGain = 12 },
	{ id = "F2_Stall8_Cooked",   kind = "Meal",    pos = Vector3.new(116.2, f2Y + 4.2, 64.5),   label = "อาหารตามสั่ง", hungerGain = 38, hpGain = 12 },
	{ id = "F2_Kitchen_Frenzy",  kind = "Weapon",  pos = Vector3.new(-146, f2Y + 3.65, -21.5), weaponKey = "Frenzy", label = "ปืนกลพกหลังครัว: Frenzy (ร้านที่ 2)", actionText = "หยิบ Frenzy หลังร้านอาหาร" },
	{ id = "F2_Kitchen_Ammo",    kind = "Ammo",    pos = Vector3.new(146, f2Y + 3.65, 21.5),   label = "ลังกระสุนหลังครัว (ร้านที่ 7)" },

	-- FLOOR 2: Center Dining Hall Tables (14x6 Wood+Steel Bench Tables along Z) + Restrooms + AC Rooms
	{ id = "F2_Table_W1",        kind = "Ration",  pos = Vector3.new(-88.0, f2Y + 3.2, -34.0), label = "ข้าวกล่องพกพา (โต๊ะโรงอาหาร)", hungerGain = 32, hpGain = 10 },
	{ id = "F2_Table_W2",        kind = "Drink",   pos = Vector3.new(-75.0, f2Y + 3.2, -15.5), label = "น้ำดื่มแช่เย็น (โต๊ะโรงอาหาร)", hungerGain = 22, hpGain = 6 },
	{ id = "F2_Table_W3",        kind = "Energy",  pos = Vector3.new(-88.0, f2Y + 3.2, 34.0),  label = "เครื่องดื่มเกลือแร่ (โต๊ะโรงอาหาร)", hungerGain = 22, boostSecs = 15 },
	{ id = "F2_Table_C1",        kind = "Drink",   pos = Vector3.new(-21.4, f2Y + 3.2, -15.5), label = "น้ำดื่มบนโต๊ะโรงอาหาร", hungerGain = 20, hpGain = 5 },
	{ id = "F2_Table_C2",        kind = "Points",  pos = Vector3.new(-9.8,  f2Y + 3.2, -34.0), label = "กระเป๋าแต้มนักศึกษา (+120 แต้ม)", pointsGain = 120 },
	{ id = "F2_Table_C3",        kind = "Battery", pos = Vector3.new(9.8,   f2Y + 3.2, 34.0),  label = "ถ่านไฟฉาย (โต๊ะโรงอาหาร)" },
	{ id = "F2_Table_C4",        kind = "Ration",  pos = Vector3.new(-21.4, f2Y + 3.2, 52.5),  label = "ขนมปังแพ็ค (โต๊ะโรงอาหาร)", hungerGain = 30, hpGain = 8 },
	{ id = "F2_Table_E1",        kind = "Medkit",  pos = Vector3.new(21.4,  f2Y + 3.2, 15.5),  label = "ชุดปฐมพยาบาล (โต๊ะโรงอาหาร)" },
	{ id = "F2_Table_E2",        kind = "Ration",  pos = Vector3.new(75.0,  f2Y + 3.2, -15.5), label = "กล่องข้าวสำเร็จรูป (โต๊ะโรงอาหาร)", hungerGain = 34, hpGain = 10 },
	{ id = "F2_Table_E3",        kind = "Ammo",    pos = Vector3.new(44.6,  f2Y + 3.2, 52.5),  label = "กระสุนสำรอง (โต๊ะโรงอาหาร)" },
	{ id = "F2_Table_E4",        kind = "Battery", pos = Vector3.new(88.0,  f2Y + 3.2, -34.0), label = "ถ่านไฟฉาย (โต๊ะโรงอาหาร)" },
	{ id = "F2_Table_E5",        kind = "Drink",   pos = Vector3.new(88.0,  f2Y + 3.2, 34.0),  label = "น้ำผลไม้กล่อง (โต๊ะโรงอาหาร)", hungerGain = 24, hpGain = 6 },

	-- RESTROOMS F2-F12: ของฟาร์มตามซิงค์และในห้องส้วมย่อยทุกชั้น (ต้องเปิดประตูเข้าไปค้น!)
	{ id = "F2_WC_TL_Medkit",    kind = "Medkit",  pos = Vector3.new(-130.5, f2Y + 3.15, -106.15), label = "ชุดปฐมพยาบาล (อ่างล้างมือห้องน้ำชั้น 2)" },
	{ id = "F2_WC_TR_Battery",   kind = "Battery", pos = Vector3.new(143.8, f2Y, -95.9),           label = "ถ่านไฟฉายตกอยู่ (ห้องส้วมชั้น 2)" },
	{ id = "F2_WC_BL_Points",    kind = "Points",  pos = Vector3.new(-143.8, f2Y, 116.7),          label = "กระเป๋านักศึกษา (+150 แต้ม ห้องส้วมชั้น 2)", pointsGain = 150 },
	{ id = "F3_WC_W_Medkit",     kind = "Medkit",  pos = Vector3.new(-120.85, f3Y + 3.15, -99.0),  label = "ชุดปฐมพยาบาล (อ่างล้างมือ WC.2 ชั้น 3)" },
	{ id = "F3_WC_E_Ammo",       kind = "Ammo",    pos = Vector3.new(111.8, f3Y, -113.8),          label = "กระสุนสำรอง (ห้องส้วม WC.3 ชั้น 3)" },
	{ id = "F4_WC_BR_Battery",   kind = "Battery", pos = Vector3.new(130.5, f4Y + 3.15, 89.15),    label = "ถ่านไฟฉาย (ห้องน้ำชั้น 4)" },
	{ id = "F4_WC_TL_Ammo",      kind = "Ammo",    pos = Vector3.new(-143.8, f4Y, -112.9),         label = "กล่องกระสุน (ห้องส้วมชั้น 4)" },
	{ id = "F5_WC_BL_Medkit",    kind = "Medkit",  pos = Vector3.new(-130.5, f5Y + 3.15, 89.15),   label = "ชุดปฐมพยาบาล (ห้องน้ำชั้น 5)" },
	{ id = "F5_WC_TR_Classic",   kind = "Weapon",  pos = Vector3.new(143.8, f5Y, -106.3),          weaponKey = "Classic", label = "ปืนพกซ่อนในห้องน้ำ: Classic (ชั้น 5)", actionText = "หยิบปืน Classic ในห้องส้วม" },
	{ id = "F6_WC_TR_Energy",    kind = "Energy",  pos = Vector3.new(130.5, f6Y + 3.15, -89.15),   label = "เครื่องดื่มชูกำลัง (อ่างล้างมือชั้น 6)", hungerGain = 22, boostSecs = 15 },
	{ id = "F6_WC_BL_Medkit",    kind = "Medkit",  pos = Vector3.new(-143.8, f6Y, 110.1),          label = "ชุดปฐมพยาบาล (ห้องส้วมชั้น 6)" },
	{ id = "F7_WC_TL_Battery",   kind = "Battery", pos = Vector3.new(-130.5, f7Y + 3.15, -89.15),  label = "ถ่านไฟฉาย (อ่างล้างมือชั้น 7)" },
	{ id = "F7_WC_BR_Ammo",      kind = "Ammo",    pos = Vector3.new(143.8, f7Y, 116.7),           label = "กระสุนสำรอง (ห้องส้วมชั้น 7)" },
	{ id = "F8_WC_BR_Medkit",    kind = "Medkit",  pos = Vector3.new(130.5, f8Y + 3.15, 89.15),    label = "ชุดปฐมพยาบาล (อ่างล้างมือชั้น 8)" },
	{ id = "F9_WC_TL_Ammo",      kind = "Ammo",    pos = Vector3.new(-143.8, f9Y, -106.3),         label = "กล่องกระสุน (ห้องส้วมชั้น 9)" },
	{ id = "F10_WC_BL_Medkit",   kind = "Medkit",  pos = Vector3.new(-130.5, f10Y + 3.15, 106.15), label = "ชุดปฐมพยาบาล (อ่างล้างมือชั้น 10)" },
	{ id = "F11_WC_TR_Battery",  kind = "Battery", pos = Vector3.new(143.8, f11Y, -95.9),          label = "ถ่านไฟฉายสำรอง (ห้องส้วมชั้น 11)" },
	{ id = "F12_WC2_Medkit",     kind = "Medkit",  pos = Vector3.new(-94.65, f12Y + 3.15, -103.0), label = "ชุดปฐมพยาบาล (WC.2 ชั้น 12)" },
	{ id = "F12_WC1_Ammo",       kind = "Ammo",    pos = Vector3.new(-73.8, f12Y, 104.8),          label = "กระสุนฉุกเฉิน (WC.1 ชั้น 12)" },
	{ id = "F2_AC1_Meal",        kind = "Meal",    pos = Vector3.new(-75.5, f2Y + 3.4, -103), label = "ข้าวกล่องห้องแอร์ 1", hungerGain = 35, hpGain = 10 },
	{ id = "F2_AC2_Bat",         kind = "Battery", pos = Vector3.new(90.5, f2Y + 3.4, -103),  label = "ถ่านไฟฉายห้องแอร์ 2" },
	{ id = "F2_AC3_Energy",      kind = "Energy",  pos = Vector3.new(-75.5, f2Y + 3.4, 103),  label = "กาแฟเย็นห้องแอร์ 3", hungerGain = 22, boostSecs = 15 },
	{ id = "F2_AC4_Medkit",      kind = "Medkit",  pos = Vector3.new(90.5, f2Y + 3.4, 103),   label = "ชุดปฐมพยาบาลห้องแอร์ 4" },
	{ id = "F2_Storage_Classic", kind = "Weapon",  pos = Vector3.new(-49, f2Y + 3.0, -81), weaponKey = "Classic", label = "ปืนพกฉุกเฉิน: Classic (ห้องพัสดุชั้น 2)", actionText = "หยิบปืนพก Classic" },
	{ id = "F2_Storage_Ammo",    kind = "Ammo",    pos = Vector3.new(-53, f2Y + 3.0, -81), label = "กล่องกระสุนสำรอง (ห้องพัสดุชั้น 2)" },
	{ id = "F2_Office_Spectre",  kind = "Weapon",  pos = Vector3.new(49, f2Y + 3.0, 81),   weaponKey = "Spectre", label = "ปืนกลมือ: Spectre (สำนักงานชั้น 2)", actionText = "หยิบปืน Spectre" },
	{ id = "F2_Office_Med",      kind = "Medkit",  pos = Vector3.new(53, f2Y + 3.0, 81),   label = "ชุดปฐมพยาบาล (สำนักงานชั้น 2)" },

	-- FLOORS 3–10: Sports Arena & Upper Atrium Corridors (Full Scavenge Loop!)
	{ id = "F3_Arena_Bat",       kind = "Battery", pos = Vector3.new(-28, f3Y, 0), label = "ถ่านไฟฉาย (ชั้น 3 สนามกีฬา)" },
	{ id = "F3_Arena_Energy",    kind = "Energy",  pos = Vector3.new(28, f3Y, 0),  label = "เครื่องดื่มเกลือแร่นักกีฬา (ชั้น 3)", hungerGain = 26, boostSecs = 15 },
	{ id = "F3_Arena_Ammo",      kind = "Ammo",    pos = Vector3.new(0, f3Y, 58),  label = "ลังกระสุนข้างสนาม (ชั้น 3)" },
	{ id = "F3_Arena_Points",    kind = "Points",  pos = Vector3.new(0, f3Y, -58), label = "กระเป๋าแต้มชมรมกีฬา (+120)", pointsGain = 120 },

	{ id = "F4_Ghost_Sidearm",   kind = "Weapon",  pos = Vector3.new(22, f4Y, -78), weaponKey = "Ghost", label = "ปืนเก็บเสียง: Ghost (ทางเดินชั้น 4)", actionText = "หยิบปืน Ghost" },
	{ id = "F4_Ration",          kind = "Ration",  pos = Vector3.new(-22, f4Y, 78), label = "เสบียงอาหารแห้ง (ชั้น 4)", hungerGain = 32, hpGain = 10 },
	{ id = "F4_Battery",         kind = "Battery", pos = Vector3.new(-108, f4Y, 0), label = "ถ่านไฟฉายระเบียงฝั่งซ้าย (ชั้น 4)" },

	{ id = "F5_Points",          kind = "Points",  pos = Vector3.new(108, f5Y, -30), label = "ตู้เก็บแต้มสำนักงาน (+150 แต้ม)", pointsGain = 150 },
	{ id = "F5_Medkit",          kind = "Medkit",  pos = Vector3.new(0, f5Y, -78),   label = "ชุดปฐมพยาบาล (โถงชั้น 5)" },
	{ id = "F5_Energy",          kind = "Energy",  pos = Vector3.new(0, f5Y, 20),    label = "กาแฟกระป๋องชูกำลัง (สะพานชั้น 5)", hungerGain = 22, boostSecs = 15 },
	{ id = "F5_Ammo",            kind = "Ammo",    pos = Vector3.new(-22, f5Y, -25), label = "กล่องกระสุนฉุกเฉิน (ชั้น 5)" },

	{ id = "F6_Bulldog",         kind = "Weapon",  pos = Vector3.new(22, f6Y, 78),  weaponKey = "Bulldog", label = "ปืนไรเฟิลจู่โจม: Bulldog (ชั้น 6)", actionText = "หยิบปืน Bulldog" },
	{ id = "F6_Ration",          kind = "Ration",  pos = Vector3.new(-108, f6Y, 35), label = "เสบียงอาหารกระป๋อง (ชั้น 6)", hungerGain = 35, hpGain = 10 },
	{ id = "F6_Battery",         kind = "Battery", pos = Vector3.new(108, f6Y, 0),   label = "ถ่านไฟฉายสำรอง (ชั้น 6)" },

	{ id = "F7_Medkit",          kind = "Medkit",  pos = Vector3.new(0, f7Y, -82), label = "ชุดปฐมพยาบาล (ชั้น 7)" },
	{ id = "F7_Meal",            kind = "Ration",  pos = Vector3.new(0, f7Y, 82),  label = "เสบียงนักกีฬา (ชั้น 7)", hungerGain = 35, hpGain = 12 },
	{ id = "F7_Ammo",            kind = "Ammo",    pos = Vector3.new(-24, f7Y, 0), label = "คลังกระสุนสนามแบด (ชั้น 7)" },
	{ id = "F7_Energy",          kind = "Energy",  pos = Vector3.new(24, f7Y, 0),  label = "เกลือแร่ชูกำลัง (ชั้น 7)", hungerGain = 25, boostSecs = 15 },

	{ id = "F8_Points",          kind = "Points",  pos = Vector3.new(0, f8Y, -78), label = "กระเป๋าแต้มงานวิจัย (+180)", pointsGain = 180 },
	{ id = "F8_Ration",          kind = "Ration",  pos = Vector3.new(108, f8Y, 28), label = "เสบียงห้องแล็บ (ชั้น 8)", hungerGain = 34, hpGain = 10 },
	{ id = "F8_Battery",         kind = "Battery", pos = Vector3.new(-22, f8Y, 20), label = "แบตเตอรี่สำรอง (ชั้น 8)" },

	{ id = "F9_Judge",           kind = "Weapon",  pos = Vector3.new(-108, f9Y, -25), weaponKey = "Judge", label = "ลูกซองอัตโนมัติ: Judge (ชั้น 9)", actionText = "หยิบลูกซอง Judge" },
	{ id = "F9_Medkit",          kind = "Medkit",  pos = Vector3.new(0, f9Y, 78),     label = "ชุดปฐมพยาบาล (ชั้น 9)" },
	{ id = "F9_Ammo",            kind = "Ammo",    pos = Vector3.new(22, f9Y, -25),   label = "กล่องกระสุน (ชั้น 9)" },

	{ id = "F10_Ration",         kind = "Ration",  pos = Vector3.new(-22, f10Y, -78), label = "เสบียงเตรียมบุกชั้น 11", hungerGain = 38, hpGain = 12 },
	{ id = "F10_Medkit",         kind = "Medkit",  pos = Vector3.new(22, f10Y, -78),  label = "ชุดปฐมพยาบาลก่อนเข้าเขต 11" },
	{ id = "F10_Battery",        kind = "Battery", pos = Vector3.new(-22, f10Y, 78),  label = "ถ่านไฟฉาย (ชั้น 10)" },
	{ id = "F10_Ammo",           kind = "Ammo",    pos = Vector3.new(22, f10Y, 78),   label = "ลังกระสุนเต็มแม็ก (ชั้น 10)" },

	-- FLOOR 11: Secret Lab Stash
	{ id = "F11_Lab_Vandal",     kind = "Weapon",  pos = Vector3.new(-14, f11Y, -20), weaponKey = "Vandal", label = "ปืนไรเฟิลเขตทดลอง: Vandal (ชั้น 11)", actionText = "หยิบ Vandal ประจำเขต 11" },
	{ id = "F11_Lab_Ammo",       kind = "Ammo",    pos = Vector3.new(-14, f11Y, -16), label = "คลังกระสุนเขตทดลอง (ชั้น 11)" },
	{ id = "F11_Lab_Medkit",     kind = "Medkit",  pos = Vector3.new(13.5, f11Y + 3.0, 24), label = "ชุดปฐมพยาบาล (โต๊ะวิจัยชั้น 11)" },
	{ id = "F11_Lab_Battery",    kind = "Battery", pos = Vector3.new(13.5, f11Y + 3.0, 20), label = "แบตเตอรี่สำรอง (ชั้น 11)" },
	{ id = "F11_Lab_Points",     kind = "Points",  pos = Vector3.new(13.5, f11Y + 3.0, 16), label = "ไดรฟ์ข้อมูลลับ (+250 แต้ม)", pointsGain = 250 },

	-- FLOOR 12: Extraction Support Crate
	{ id = "F12_Heli_Ammo",      kind = "Ammo",    pos = Vector3.new(-26, f12Y, -74), label = "ลังกระสุนสนับสนุนลาน ฮ (ชั้น 12)" },
	{ id = "F12_Heli_Medkit",    kind = "Medkit",  pos = Vector3.new(26, f12Y, -74),  label = "ชุดพยาบาลฉุกเฉินลาน ฮ (ชั้น 12)" },
}

buildFloor11LabProps()
buildStairwellEmergencyLights()
for _, item in ipairs(LOOT_TABLE) do
	spawnPickup(item)
end

buildVendingStation("F1_Lobby", Vector3.new(32, f1Y, -60), 0)
buildVendingStation("F2_CanteenWest", Vector3.new(-65, f2Y, -32.4), 180)
buildVendingStation("F2_CanteenEast", Vector3.new(65, f2Y, 32.4), 0)
buildVendingStation("F6_Bridge", Vector3.new(-24, f6Y, -76), 180)
buildVendingStation("F9_Bridge", Vector3.new(24, f9Y, 76), 0)

print(string.format("🏚️ [SurvivalAndHorrorSetup] สร้างจุดฟาร์มครบ %d จุด + 5 ตู้เสบียง + ซอมบี้ดรอปของ + ระบบกระเป๋า [4][5][6] สำเร็จ!", #LOOT_TABLE))
