-- Builds and synchronizes server-owned interactive Mission 01 objects in Building 40 F1:
--   1. M1_KeycardPickup, M1_ManagerRevolverPickup & M1_ManagerOfficeNote (F1 Bangkok Bank Manager's Office)
--   2. M1_ClueBoard_Atrium & M1_ClueMemo_Room102 (Environmental Timeline Clues synced to active variant)
--   3. M1_SecurityRoomDoor (Room 102 Keycard-locked hinged bulkhead door)
--   4. M1_CCTVTerminal (Room 102 Left Desk -> opens server-validated Timeline modal)
--   5. M1_SecurityOverrideConsole (Room 102 Right Desk -> completes M1 and unlocks M2 [NOT IMPLEMENTED])

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local MissionConfig = require(SharedFolder:WaitForChild("MissionConfig"))

local MissionWorldInteractables = {}

local MODEL_ROOT_NAME = "MissionM1_Interactables"

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
	if extra then
		for k, v in pairs(extra) do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function makeSurfacePanel(part, face, titleText, bodyText, bgColor, accentColor)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "ClueSurface"
	gui.Face = face
	gui.CanvasSize = Vector2.new(640, 420)
	gui.LightInfluence = 0.25
	gui.Parent = part

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = bgColor or Color3.fromRGB(16, 20, 28)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -32, 0, 62)
	header.Position = UDim2.new(0, 16, 0, 14)
	header.BackgroundColor3 = accentColor or Color3.fromRGB(155, 36, 46)
	header.BorderSizePixel = 0
	header.Font = Enum.Font.GothamBold
	header.TextSize = 26
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.Text = titleText
	header.Parent = frame

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -40, 1, -104)
	body.Position = UDim2.new(0, 20, 0, 88)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Code
	body.TextSize = 23
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextColor3 = Color3.fromRGB(228, 236, 246)
	body.Text = bodyText
	body.Parent = frame

	return header, body
end

local function verifyDistance(player, targetPart, maxDist)
	if not player or not player.Parent or not targetPart or not targetPart.Parent then
		return false
	end
	if player:GetAttribute("IsDowned") == true then
		return false
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead or not hrp then
		return false
	end
	if char:GetAttribute("IsDowned") == true or hrp:FindFirstChild("RevivePrompt") ~= nil then
		return false
	end
	return (hrp.Position - targetPart.Position).Magnitude <= (maxDist + 4.5)
end

function MissionWorldInteractables.build(deps)
	local tracker = deps.tracker
	local puzzleEngine = deps.puzzleEngine
	local onStateChanged = deps.onStateChanged
	local onOpenPuzzleForPlayer = deps.onOpenPuzzleForPlayer
	local onOpenSafeKeypadForPlayer = deps.onOpenSafeKeypadForPlayer
	local onShowEmergencyMemoForPlayer = deps.onShowEmergencyMemoForPlayer
	local onOpenGuardNoteForPlayer = deps.onOpenGuardNoteForPlayer
	local onMonitorWallSelect = deps.onMonitorWallSelect
	local onStartOverrideHoldout = deps.onStartOverrideHoldout
	local onRestorePowerTriggered = deps.onRestorePowerTriggered
	local onPlayerNotice = deps.onPlayerNotice
	local floorY = deps.floorY or 1.0
	local floor2Y = deps.floor2Y or (floorY + 22.0)

	local old = Workspace:FindFirstChild(MODEL_ROOT_NAME)
	if old then
		old:Destroy()
	end

	local root = Instance.new("Folder")
	root.Name = MODEL_ROOT_NAME
	root.Parent = Workspace

	-- 0. Clean Posed Corpse Model (Manager Phatcharee slumped on the executive desk, 100% clean, no virus)
	local corpseModel = Instance.new("Model")
	corpseModel.Name = "M1_BranchManagerCorpse"
	corpseModel.Parent = root

	local suitDark = Color3.fromRGB(30, 38, 52)
	local shirtWhite = Color3.fromRGB(230, 235, 240)
	local skinTone = Color3.fromRGB(225, 192, 168)
	local hairColor = Color3.fromRGB(32, 24, 20)
	local bloodRed = Color3.fromRGB(120, 18, 22)

	-- Bloodstain pool on the desk under the corpse
	makePart(corpseModel, "DeskBloodPool", Vector3.new(4.2, 0.02, 3.6),
		CFrame.new(135.2, floorY + 3.71, 54.8), bloodRed, Enum.Material.SmoothPlastic, { CanCollide = false })

	-- Torso slumped forward across the desk
	local torso = makePart(corpseModel, "CorpseTorso", Vector3.new(2.0, 2.2, 1.1),
		CFrame.new(135.5, floorY + 3.5, 52.8) * CFrame.Angles(math.rad(65), 0, math.rad(-15)), suitDark, Enum.Material.Fabric, { CanCollide = false })

	-- Head resting on the desk
	makePart(corpseModel, "CorpseHead", Vector3.new(1.2, 1.2, 1.2),
		CFrame.new(135.2, floorY + 3.9, 54.4) * CFrame.Angles(math.rad(15), math.rad(-25), math.rad(30)), skinTone, Enum.Material.SmoothPlastic, { CanCollide = false })
	makePart(corpseModel, "CorpseHair", Vector3.new(1.3, 0.8, 1.3),
		CFrame.new(135.2, floorY + 4.25, 54.3) * CFrame.Angles(math.rad(15), math.rad(-25), math.rad(30)), hairColor, Enum.Material.SmoothPlastic, { CanCollide = false })

	-- Left Arm outstretched on the desk
	makePart(corpseModel, "CorpseArm_Left", Vector3.new(0.6, 2.0, 0.6),
		CFrame.new(134.2, floorY + 3.74, 54.2) * CFrame.Angles(math.rad(90), 0, math.rad(45)), suitDark, Enum.Material.Fabric, { CanCollide = false })

	-- Right Arm resting towards the keycard / note
	makePart(corpseModel, "CorpseArm_Right", Vector3.new(0.6, 2.0, 0.6),
		CFrame.new(136.8, floorY + 3.74, 53.6) * CFrame.Angles(math.rad(90), 0, math.rad(-40)), suitDark, Enum.Material.Fabric, { CanCollide = false })

	-- Lower body sitting in the chair behind the desk
	makePart(corpseModel, "CorpseHips", Vector3.new(1.9, 1.4, 1.2),
		CFrame.new(135.8, floorY + 2.4, 51.2) * CFrame.Angles(math.rad(25), 0, 0), suitDark, Enum.Material.Fabric, { CanCollide = false })
	makePart(corpseModel, "CorpseLegs", Vector3.new(1.8, 2.4, 1.0),
		CFrame.new(135.8, floorY + 1.2, 51.6) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(24, 28, 36), Enum.Material.Fabric, { CanCollide = false })

	-- 1. Security Keycard Pickup (Resting near the corpse's right hand)
	local keycardModel = Instance.new("Model")
	keycardModel.Name = "M1_KeycardPickup"
	keycardModel.Parent = root

	local keycardCard = makePart(keycardModel, "KeycardCard", Vector3.new(1.15, 0.06, 0.72),
		CFrame.new(136.6, floorY + 3.76, 54.6) * CFrame.Angles(0, math.rad(14), 0), Color3.fromRGB(48, 215, 255), Enum.Material.Neon, { CanCollide = false })
	local keycardStripe = makePart(keycardModel, "KeycardGoldChip", Vector3.new(0.28, 0.07, 0.22),
		CFrame.new(136.3, floorY + 3.77, 54.55) * CFrame.Angles(0, math.rad(14), 0), Color3.fromRGB(255, 210, 75), Enum.Material.Metal, { CanCollide = false })

	local keycardLight = Instance.new("PointLight")
	keycardLight.Color = Color3.fromRGB(60, 225, 255)
	keycardLight.Range = 8
	keycardLight.Brightness = 0.85
	keycardLight.Parent = keycardCard

	-- Prompts directly on the Corpse Torso for searching
	local keycardPrompt = Instance.new("ProximityPrompt")
	keycardPrompt.Name = "KeycardPrompt"
	keycardPrompt.ActionText = "ค้นตัวผู้จัดการ (Search Corpse & Keycard)"
	keycardPrompt.ObjectText = "ร่างของพัชรี ส. (ผู้จัดการสาขา)"
	keycardPrompt.KeyboardKeyCode = Enum.KeyCode.E
	keycardPrompt.HoldDuration = 0.4
	keycardPrompt.MaxActivationDistance = 12.0
	keycardPrompt.RequiresLineOfSight = false
	keycardPrompt.Parent = torso

	-- 1A-1. Interactive Hex Keypad Bank Safe (Replaces static ManagerVaultSafe)
	local f1Model = Workspace:FindFirstChild("Floor_1_Building40")
	local bankRoom = f1Model and f1Model:FindFirstChild("Room_Bank_BottomRight")
	if bankRoom then
		local oldSafe = bankRoom:FindFirstChild("ManagerVaultSafe")
		if oldSafe then oldSafe:Destroy() end
		local oldDial = bankRoom:FindFirstChild("ManagerVaultDial")
		if oldDial then oldDial:Destroy() end
	end

	local safeModel = Instance.new("Model")
	safeModel.Name = "M1_BankVaultSafe"
	safeModel.Parent = root

	local safeBaseCF = CFrame.new(124.2, floorY + 2.6, 48.2)
	local safeSteel = Color3.fromRGB(34, 38, 46)
	local safeSteelDark = Color3.fromRGB(24, 28, 34)
	local safeGold = Color3.fromRGB(205, 170, 75)

	-- Outer Hollow Shell (Size 4.2 x 5.2 x 3.6, opening facing +Z)
	makePart(safeModel, "SafeBottom", Vector3.new(4.2, 0.4, 3.6), safeBaseCF * CFrame.new(0, -2.4, 0), safeSteel, Enum.Material.Metal)
	local safeRoof = makePart(safeModel, "SafeTop", Vector3.new(4.2, 0.4, 3.6), safeBaseCF * CFrame.new(0, 2.4, 0), safeSteel, Enum.Material.Metal)
	makePart(safeModel, "SafeBack", Vector3.new(4.2, 4.4, 0.4), safeBaseCF * CFrame.new(0, 0, -1.6), safeSteel, Enum.Material.Metal)
	makePart(safeModel, "SafeLeft", Vector3.new(0.4, 4.4, 3.6), safeBaseCF * CFrame.new(-1.9, 0, 0), safeSteel, Enum.Material.Metal)
	makePart(safeModel, "SafeRight", Vector3.new(0.4, 4.4, 3.6), safeBaseCF * CFrame.new(1.9, 0, 0), safeSteel, Enum.Material.Metal)
	makePart(safeModel, "SafeShelf", Vector3.new(3.4, 0.15, 3.0), safeBaseCF * CFrame.new(0, -0.2, 0), Color3.fromRGB(45, 50, 60), Enum.Material.Metal)

	-- Interior Spotlight
	local safeLight = Instance.new("PointLight")
	safeLight.Color = Color3.fromRGB(255, 235, 185)
	safeLight.Range = 6.5
	safeLight.Brightness = 0.8
	safeLight.Enabled = false
	safeLight.Parent = safeRoof

	-- Hinged Safe Door with multi-spoke wheel & retracting bolts
	local hingeCF = CFrame.new(122.4, floorY + 2.6, 50.0)
	local doorHinge = Instance.new("Part")
	doorHinge.Name = "SafeDoorHinge"
	doorHinge.Size = Vector3.new(0.3, 4.6, 0.3)
	doorHinge.CFrame = hingeCF
	doorHinge.Color = safeSteelDark
	doorHinge.Material = Enum.Material.Metal
	doorHinge.Anchored = true
	doorHinge.CanCollide = false
	doorHinge.Parent = safeModel

	makePart(safeModel, "SafeHingeTop", Vector3.new(0.4, 0.65, 0.4), hingeCF * CFrame.new(0, 1.65, 0.05), safeGold, Enum.Material.Metal, { CanCollide = false })
	makePart(safeModel, "SafeHingeBot", Vector3.new(0.4, 0.65, 0.4), hingeCF * CFrame.new(0, -1.65, 0.05), safeGold, Enum.Material.Metal, { CanCollide = false })

	local doorLeaf = Instance.new("Part")
	doorLeaf.Name = "SafeDoorLeaf"
	doorLeaf.Size = Vector3.new(3.5, 4.4, 0.4)
	doorLeaf.CFrame = hingeCF * CFrame.new(1.75, 0, 0)
	doorLeaf.Color = Color3.fromRGB(42, 48, 58)
	doorLeaf.Material = Enum.Material.Metal
	doorLeaf.Anchored = true
	doorLeaf.CanCollide = false
	doorLeaf.Parent = safeModel

	local doorTrim = makePart(safeModel, "SafeDoorTrim", Vector3.new(3.05, 3.95, 0.08),
		doorLeaf.CFrame * CFrame.new(0, 0, 0.21), safeSteelDark, Enum.Material.Metal, { CanCollide = false })

	-- Multi-spoke Rotating Vault Wheel
	local wheelCenterCF = doorLeaf.CFrame * CFrame.new(-0.52, -0.05, 0.32)
	local doorWheelRim = Instance.new("Part")
	doorWheelRim.Name = "SafeWheelRim"
	doorWheelRim.Shape = Enum.PartType.Cylinder
	doorWheelRim.Size = Vector3.new(0.16, 1.42, 1.42)
	doorWheelRim.CFrame = wheelCenterCF * CFrame.Angles(0, math.rad(90), 0)
	doorWheelRim.Color = safeSteelDark
	doorWheelRim.Material = Enum.Material.Metal
	doorWheelRim.Anchored = true
	doorWheelRim.CanCollide = false
	doorWheelRim.Parent = safeModel

	local doorWheel = Instance.new("Part")
	doorWheel.Name = "SafeWheel"
	doorWheel.Shape = Enum.PartType.Cylinder
	doorWheel.Size = Vector3.new(0.28, 0.56, 0.56)
	doorWheel.CFrame = wheelCenterCF * CFrame.Angles(0, math.rad(90), 0)
	doorWheel.Color = safeGold
	doorWheel.Material = Enum.Material.Metal
	doorWheel.Anchored = true
	doorWheel.CanCollide = false
	doorWheel.Parent = safeModel

	local doorWheelSpokeH = makePart(safeModel, "SafeWheelSpokeH", Vector3.new(1.58, 0.14, 0.22),
		wheelCenterCF, safeGold, Enum.Material.Metal, { CanCollide = false })
	local doorWheelSpokeV = makePart(safeModel, "SafeWheelSpokeV", Vector3.new(0.14, 1.58, 0.22),
		wheelCenterCF, safeGold, Enum.Material.Metal, { CanCollide = false })
	local doorWheelKnob = makePart(safeModel, "SafeWheelKnob", Vector3.new(0.22, 0.22, 0.28),
		wheelCenterCF * CFrame.new(0, 0.64, 0.1), Color3.fromRGB(220, 95, 50), Enum.Material.Metal, { CanCollide = false })

	-- 3 Chrome Locking Bolts on the right latch side of the door
	local boltParts = {}
	local relBolts = {}
	local boltCol = Color3.fromRGB(195, 204, 216)
	for bi, by in ipairs({ 1.35, 0, -1.35 }) do
		local bp = makePart(safeModel, "SafeBolt_" .. bi, Vector3.new(0.55, 0.26, 0.22),
			doorLeaf.CFrame * CFrame.new(1.80, by, 0), boltCol, Enum.Material.Metal, { CanCollide = false })
		boltParts[bi] = bp
		relBolts[bi] = hingeCF:ToObjectSpace(bp.CFrame)
	end

	-- Digital Keypad on Door
	local keypadPlate = Instance.new("Part")
	keypadPlate.Name = "SafeKeypadPlate"
	keypadPlate.Size = Vector3.new(0.95, 1.4, 0.2)
	keypadPlate.CFrame = doorLeaf.CFrame * CFrame.new(0.68, 0.42, 0.28)
	keypadPlate.Color = Color3.fromRGB(22, 26, 34)
	keypadPlate.Material = Enum.Material.Metal
	keypadPlate.Anchored = true
	keypadPlate.CanCollide = false
	keypadPlate.Parent = safeModel

	local keypadLED = Instance.new("Part")
	keypadLED.Name = "SafeKeypadLED"
	keypadLED.Size = Vector3.new(0.65, 0.22, 0.1)
	keypadLED.CFrame = keypadPlate.CFrame * CFrame.new(0, 0.45, 0.1)
	keypadLED.Color = Color3.fromRGB(235, 45, 55) -- Red initially (Locked)
	keypadLED.Material = Enum.Material.Neon
	keypadLED.Anchored = true
	keypadLED.CanCollide = false
	keypadLED.Parent = safeModel

	-- Relative CFrames from hinge for smooth mechanical rotation
	local relLeaf = hingeCF:ToObjectSpace(doorLeaf.CFrame)
	local relTrim = hingeCF:ToObjectSpace(doorTrim.CFrame)
	local relWheelCenter = hingeCF:ToObjectSpace(wheelCenterCF)
	local relKeypad = hingeCF:ToObjectSpace(keypadPlate.CFrame)
	local relLED = hingeCF:ToObjectSpace(keypadLED.CFrame)

	local function applySafeDoorPose(hingeDeg, wheelDeg, boltRetractOffset)
		local curHinge = hingeCF * CFrame.Angles(0, math.rad(hingeDeg), 0)
		doorLeaf.CFrame = curHinge * relLeaf
		doorTrim.CFrame = curHinge * relTrim
		keypadPlate.CFrame = curHinge * relKeypad
		keypadLED.CFrame = curHinge * relLED

		local wheelHubCF = curHinge * relWheelCenter * CFrame.Angles(0, 0, math.rad(wheelDeg))
		doorWheelRim.CFrame = wheelHubCF * CFrame.Angles(0, math.rad(90), 0)
		doorWheel.CFrame = wheelHubCF * CFrame.Angles(0, math.rad(90), 0)
		doorWheelSpokeH.CFrame = wheelHubCF
		doorWheelSpokeV.CFrame = wheelHubCF
		doorWheelKnob.CFrame = wheelHubCF * CFrame.new(0, 0.64, 0.1)

		for bi, bp in ipairs(boltParts) do
			bp.CFrame = curHinge * relBolts[bi] * CFrame.new(boltRetractOffset, 0, 0)
		end
	end

	local safePrompt = Instance.new("ProximityPrompt")
	safePrompt.Name = "SafeKeypadPrompt"
	safePrompt.ActionText = "ใส่รหัสตู้เซฟ [HEX] (Enter Code)"
	safePrompt.ObjectText = "ตู้เซฟผู้จัดการธนาคาร (Manager Safe)"
	safePrompt.KeyboardKeyCode = Enum.KeyCode.E
	safePrompt.HoldDuration = 0
	safePrompt.MaxActivationDistance = 12.0
	safePrompt.RequiresLineOfSight = false
	safePrompt.Parent = keypadPlate

	-- 1A-2. Manager's Service Revolver Pickup (Placed securely inside the safe on the shelf)
	local revolverModel = Instance.new("Model")
	revolverModel.Name = "M1_ManagerRevolverPickup"
	revolverModel.Parent = root

	local gunBaseCF = safeBaseCF * CFrame.new(0, -0.05, 0) * CFrame.Angles(math.rad(90), 0, math.rad(-90))
	local gunSteel = Color3.fromRGB(48, 54, 62)
	local gunWood = Color3.fromRGB(108, 62, 34)
	local gunBrass = Color3.fromRGB(205, 170, 82)
	local revolverFrame = makePart(revolverModel, "RevolverFrame", Vector3.new(0.22, 0.65, 0.42),
		gunBaseCF, gunSteel, Enum.Material.Metal, { CanCollide = false })
	local revolverBarrel = makePart(revolverModel, "RevolverBarrel", Vector3.new(0.16, 0.95, 0.2),
		gunBaseCF * CFrame.new(0, 0.65, 0.08), gunSteel, Enum.Material.Metal, { CanCollide = false })
	local revolverCylinder = makePart(revolverModel, "RevolverCylinder", Vector3.new(0.3, 0.34, 0.3),
		gunBaseCF * CFrame.new(0, 0.05, 0.06), Color3.fromRGB(72, 78, 88), Enum.Material.Metal, { CanCollide = false })
	local revolverGrip = makePart(revolverModel, "RevolverGrip", Vector3.new(0.2, 0.56, 0.32),
		gunBaseCF * CFrame.new(0, -0.4, -0.18) * CFrame.Angles(math.rad(-24), 0, 0), gunWood, Enum.Material.Wood, { CanCollide = false })
	local revolverSight = makePart(revolverModel, "RevolverBrassTrim", Vector3.new(0.12, 0.12, 0.14),
		gunBaseCF * CFrame.new(0, 1.05, 0.16), gunBrass, Enum.Material.Metal, { CanCollide = false })
	local revolverParts = { revolverFrame, revolverBarrel, revolverCylinder, revolverGrip, revolverSight }
	local revolverLight = Instance.new("PointLight")
	revolverLight.Color = Color3.fromRGB(255, 210, 125)
	revolverLight.Range = 6
	revolverLight.Brightness = 0.6
	revolverLight.Parent = revolverFrame

	local revolverPrompt = Instance.new("ProximityPrompt")
	revolverPrompt.Name = "RevolverPickupPrompt"
	revolverPrompt.ActionText = "หยิบปืนลูกโม่ [Sheriff]"
	revolverPrompt.ObjectText = "ปืนพกประจำตัวผู้จัดการ (Service Revolver)"
	revolverPrompt.KeyboardKeyCode = Enum.KeyCode.E
	revolverPrompt.HoldDuration = 0.25
	revolverPrompt.MaxActivationDistance = 12.0
	revolverPrompt.RequiresLineOfSight = false
	revolverPrompt.Enabled = false -- Locked until safe is decoded
	revolverPrompt.Parent = revolverFrame

	-- 1A-3. Manager's Final Log (Last Stand narrative note on desk, clearly visible in front)
	local mgrNoteModel = Instance.new("Model")
	mgrNoteModel.Name = "M1_ManagerOfficeNote"
	mgrNoteModel.Parent = root

	local mgrNotePad = makePart(mgrNoteModel, "ManagerMemoPad", Vector3.new(1.4, 0.08, 1.8),
		CFrame.new(137.2, floorY + 3.72, 55.6) * CFrame.Angles(0, math.rad(-12), 0), Color3.fromRGB(244, 240, 225), Enum.Material.SmoothPlastic, { CanCollide = false })
	makePart(mgrNoteModel, "ManagerMemoClip", Vector3.new(0.7, 0.1, 0.22),
		CFrame.new(137.1, floorY + 3.76, 54.85) * CFrame.Angles(0, math.rad(-12), 0), Color3.fromRGB(64, 70, 78), Enum.Material.Metal, { CanCollide = false })
	local memoLight = Instance.new("PointLight")
	memoLight.Color = Color3.fromRGB(255, 230, 180)
	memoLight.Range = 6.0
	memoLight.Brightness = 0.8
	memoLight.Parent = mgrNotePad

	local mgrNotePrompt = Instance.new("ProximityPrompt")
	mgrNotePrompt.Name = "ManagerNotePrompt"
	mgrNotePrompt.ActionText = "อ่านบันทึกรหัสฉุกเฉิน (Inspect Memo)"
	mgrNotePrompt.ObjectText = "สมุดบันทึกฉุกเฉินผู้จัดการสาขา"
	mgrNotePrompt.KeyboardKeyCode = Enum.KeyCode.E
	mgrNotePrompt.HoldDuration = 0
	mgrNotePrompt.MaxActivationDistance = 12.0
	mgrNotePrompt.RequiresLineOfSight = false
	mgrNotePrompt.Parent = mgrNotePad

	-- 1B. F1 Maintenance Key Pickup & Maintenance Supply Locker (Demonstrates KeyItemService + DoorAccessService consume-on-unlock)
	local services = (tracker and tracker.getServices) and tracker.getServices() or {}
	local keyItemService = services.keyItemService
	local doorAccessService = services.doorAccessService

	local mKeyModel = Instance.new("Model")
	mKeyModel.Name = "M1_MaintenanceKeyPickup"
	mKeyModel.Parent = root

	makePart(mKeyModel, "GuardPedestal", Vector3.new(2.8, 3.2, 2.0),
		CFrame.new(-64, floorY + 1.6, -22), Color3.fromRGB(48, 52, 60), Enum.Material.Metal)
	local mKeyTray = makePart(mKeyModel, "KeyTray", Vector3.new(1.5, 0.08, 1.0),
		CFrame.new(-64, floorY + 3.24, -22), Color3.fromRGB(28, 32, 38), Enum.Material.Metal, { CanCollide = false })
	local mKeyBlade = makePart(mKeyModel, "MaintenanceKeyBlade", Vector3.new(0.95, 0.08, 0.32),
		CFrame.new(-64, floorY + 3.31, -22) * CFrame.Angles(0, math.rad(-22), 0), Color3.fromRGB(225, 185, 70), Enum.Material.Metal, { CanCollide = false })
	local mKeyLight = Instance.new("PointLight")
	mKeyLight.Color = Color3.fromRGB(240, 200, 95)
	mKeyLight.Range = 6.5
	mKeyLight.Brightness = 0.65
	mKeyLight.Parent = mKeyBlade

	local mKeyPrompt = Instance.new("ProximityPrompt")
	mKeyPrompt.Name = "MaintenanceKeyPrompt"
	mKeyPrompt.ActionText = "เก็บกุญแจซ่อมบำรุง"
	mKeyPrompt.ObjectText = "กุญแจทองเหลืองงานระบบ (ชั้น 1)"
	mKeyPrompt.KeyboardKeyCode = Enum.KeyCode.E
	mKeyPrompt.HoldDuration = 0.2
	mKeyPrompt.MaxActivationDistance = 8
	mKeyPrompt.RequiresLineOfSight = false
	mKeyPrompt.Parent = mKeyBlade

	local lockerModel = Instance.new("Model")
	lockerModel.Name = "M1_ServiceLocker"
	lockerModel.Parent = root

	local lockerBody = makePart(lockerModel, "LockerCabinet", Vector3.new(4.2, 7.0, 2.4),
		CFrame.new(-82, floorY + 3.5, -42.2), Color3.fromRGB(58, 66, 76), Enum.Material.Metal)
	local lockerDoor = makePart(lockerModel, "LockerDoor", Vector3.new(3.8, 6.4, 0.25),
		CFrame.new(-82, floorY + 3.5, -40.9), Color3.fromRGB(80, 90, 102), Enum.Material.Metal)
	local lockerLED = makePart(lockerModel, "LockerStatusLED", Vector3.new(0.45, 0.25, 0.14),
		CFrame.new(-80.6, floorY + 4.4, -40.72), Color3.fromRGB(220, 60, 60), Enum.Material.Neon, { CanCollide = false })
	local lockerCacheClaimed = false
	local lockerPrompt = Instance.new("ProximityPrompt")
	lockerPrompt.Name = "ServiceLockerPrompt"
	lockerPrompt.ActionText = "เปิดตู้เก็บอุปกรณ์ซ่อมบำรุง"
	lockerPrompt.ObjectText = "ตู้ช่างซ่อมบำรุงชั้น 1"
	lockerPrompt.KeyboardKeyCode = Enum.KeyCode.E
	lockerPrompt.HoldDuration = 0.3
	lockerPrompt.MaxActivationDistance = 8.5
	lockerPrompt.RequiresLineOfSight = false
	lockerPrompt.Parent = lockerDoor

	-- 2. Environmental Clues (F1 Central Atrium Logbook & Room 102 Corridor Wall Memo)
	local clue1Stand = Instance.new("Model")
	clue1Stand.Name = "M1_ClueBoard_Atrium"
	clue1Stand.Parent = root

	makePart(clue1Stand, "Post", Vector3.new(0.45, 4.4, 0.45),
		CFrame.new(25, floorY + 2.2, 22), Color3.fromRGB(45, 50, 58), Enum.Material.Metal)
	local clue1Board = makePart(clue1Stand, "Board", Vector3.new(6.8, 4.2, 0.3),
		CFrame.new(25, floorY + 4.9, 22) * CFrame.Angles(math.rad(12), math.rad(-25), 0), Color3.fromRGB(28, 34, 42), Enum.Material.SmoothPlastic)
	local clue1Light = Instance.new("PointLight")
	clue1Light.Color = Color3.fromRGB(255, 225, 165)
	clue1Light.Range = 14
	clue1Light.Brightness = 1.1
	clue1Light:SetAttribute("HorrorEmergencyLight", true)
	clue1Light.Parent = clue1Board
	local clue1Header, clue1Body = makeSurfacePanel(clue1Board, Enum.NormalId.Front, "บันทึกเหตุการณ์", "กำลังโหลด...", Color3.fromRGB(16, 20, 28), Color3.fromRGB(175, 42, 52))

	local clue1Prompt = Instance.new("ProximityPrompt")
	clue1Prompt.Name = "InspectClue1Prompt"
	clue1Prompt.ActionText = "ตรวจดูบันทึกเหตุการณ์"
	clue1Prompt.ObjectText = "สมุดเวรรักษาความปลอดภัย (โถงกลางชั้น 1)"
	clue1Prompt.KeyboardKeyCode = Enum.KeyCode.E
	clue1Prompt.HoldDuration = 0
	clue1Prompt.MaxActivationDistance = 9
	clue1Prompt.RequiresLineOfSight = false
	clue1Prompt.Parent = clue1Board

	local clue2Model = Instance.new("Model")
	clue2Model.Name = "M1_ClueMemo_Room102"
	clue2Model.Parent = root

	local clue2Board = makePart(clue2Model, "WallMemoBoard", Vector3.new(5.6, 3.4, 0.25),
		CFrame.new(-98.0, floorY + 5.8, 43.8), Color3.fromRGB(24, 30, 38), Enum.Material.SmoothPlastic)
	local clue2Light = Instance.new("PointLight")
	clue2Light.Color = Color3.fromRGB(160, 220, 255)
	clue2Light.Range = 12
	clue2Light.Brightness = 1.0
	clue2Light:SetAttribute("HorrorEmergencyLight", true)
	clue2Light.Parent = clue2Board
	local clue2Header, clue2Body = makeSurfacePanel(clue2Board, Enum.NormalId.Front, "บันทึกเทคนิคห้อง 102", "กำลังโหลด...", Color3.fromRGB(14, 22, 30), Color3.fromRGB(38, 120, 175))

	local clue2Prompt = Instance.new("ProximityPrompt")
	clue2Prompt.Name = "InspectClue2Prompt"
	clue2Prompt.ActionText = "อ่านบันทึกหน้าห้อง 102"
	clue2Prompt.ObjectText = "บันทึกช่างเทคนิคห้องควบคุม 102"
	clue2Prompt.KeyboardKeyCode = Enum.KeyCode.E
	clue2Prompt.HoldDuration = 0
	clue2Prompt.MaxActivationDistance = 9
	clue2Prompt.RequiresLineOfSight = false
	clue2Prompt.Parent = clue2Board

	-- 3. Room 102 Hinged Keycard-Locked Security Door (X = -109, Z = 45.0, BreakableDoor during defense)
	local doorModel = Instance.new("Model")
	doorModel.Name = "M1_SecurityRoomDoor"
	doorModel.Parent = root

	local hingeCF = CFrame.new(-112.85, floorY + 5.45, 45.0)
	local hingePivot = makePart(doorModel, "DoorHingePivot", Vector3.new(0.4, 10.9, 0.4), hingeCF, Color3.fromRGB(36, 40, 48), Enum.Material.Metal, { CanCollide = false })
	local doorLeaf = makePart(doorModel, "SecurityDoorLeaf", Vector3.new(7.7, 10.9, 0.75),
		hingeCF * CFrame.new(3.85, 0, 0), Color3.fromRGB(58, 66, 76), Enum.Material.Metal)
	local doorWindow = makePart(doorModel, "DoorReinforcedGlass", Vector3.new(2.2, 2.8, 0.8),
		hingeCF * CFrame.new(4.2, 1.4, 0), Color3.fromRGB(115, 165, 195), Enum.Material.Glass, { Transparency = 0.4, CanCollide = false })

	local readerBox = makePart(doorModel, "KeycardReaderBox", Vector3.new(0.95, 1.6, 0.45),
		CFrame.new(-104.2, floorY + 4.8, 43.75), Color3.fromRGB(30, 35, 42), Enum.Material.Metal)
	local readerLED = makePart(doorModel, "KeycardReaderLED", Vector3.new(0.65, 0.35, 0.15),
		CFrame.new(-104.2, floorY + 5.3, 43.5), Color3.fromRGB(225, 50, 60), Enum.Material.Neon, { CanCollide = false })
	-- Interior manual override plaque on Room 102 inner wall frame
	local interiorBox = makePart(doorModel, "InteriorReleaseBox", Vector3.new(0.95, 1.4, 0.35),
		CFrame.new(-104.2, floorY + 4.8, 46.25), Color3.fromRGB(34, 40, 48), Enum.Material.Metal)
	local interiorLED = makePart(doorModel, "InteriorReleaseLED", Vector3.new(0.55, 0.35, 0.14),
		CFrame.new(-104.2, floorY + 5.1, 46.46), Color3.fromRGB(225, 50, 60), Enum.Material.Neon, { CanCollide = false })
	local readerLight = Instance.new("PointLight")
	readerLight.Color = Color3.fromRGB(225, 50, 60)
	readerLight.Range = 11
	readerLight.Brightness = 1.4
	readerLight:SetAttribute("HorrorEmergencyLight", true)
	readerLight.Parent = readerLED

	local doorPrompt = Instance.new("ProximityPrompt")
	doorPrompt.Name = "SecurityDoorPrompt"
	doorPrompt.ActionText = "ปลดล็อกห้องควบคุม 102 (ใช้คีย์การ์ด)"
	doorPrompt.ObjectText = "เครื่องสแกนบัตรห้องควบคุม 102"
	doorPrompt.KeyboardKeyCode = Enum.KeyCode.E
	doorPrompt.HoldDuration = 0.35
	doorPrompt.MaxActivationDistance = 10.5
	doorPrompt.RequiresLineOfSight = false
	doorPrompt.Parent = readerBox

	local interiorDoorPrompt = Instance.new("ProximityPrompt")
	interiorDoorPrompt.Name = "InteriorDoorPrompt"
	interiorDoorPrompt.ActionText = "เปิด/ปิดประตูห้องควบคุม 102"
	interiorDoorPrompt.ObjectText = "สวิตช์ประตูห้องควบคุมด้านใน"
	interiorDoorPrompt.KeyboardKeyCode = Enum.KeyCode.E
	interiorDoorPrompt.HoldDuration = 0.15
	interiorDoorPrompt.MaxActivationDistance = 10.5
	interiorDoorPrompt.RequiresLineOfSight = false
	interiorDoorPrompt.Enabled = false
	interiorDoorPrompt.Parent = interiorBox

	local MAX_DOOR_HP = 240
	local doorHP = MAX_DOOR_HP
	local isDoorOpen = false
	local doorBroken = false

	doorModel:SetAttribute("IsOpen", false)
	doorModel:SetAttribute("IsBroken", false)
	doorModel:SetAttribute("DoorHP", doorHP)
	doorModel:SetAttribute("MaxDoorHP", MAX_DOOR_HP)
	doorModel:SetAttribute("DoorCenter", Vector3.new(-109, floorY + 4.5, 45.0))
	CollectionService:AddTag(doorModel, "BreakableDoor")

	local doorAngleVal = Instance.new("NumberValue")
	doorAngleVal.Name = "DoorSwingAngle"
	doorAngleVal.Value = 0
	doorAngleVal.Parent = doorModel

	local function applyDoorAngle(angleDeg)
		local leafCF = hingeCF * CFrame.Angles(0, math.rad(angleDeg), 0) * CFrame.new(3.85, 0, 0)
		doorLeaf.CFrame = leafCF
		doorWindow.CFrame = hingeCF * CFrame.Angles(0, math.rad(angleDeg), 0) * CFrame.new(4.2, 1.4, 0)
	end
	doorAngleVal.Changed:Connect(applyDoorAngle)

	local function setDoorOpen(openState, immediate)
		isDoorOpen = openState
		doorModel:SetAttribute("IsOpen", openState)
		local targetAngle = openState and -92 or 0
		if immediate then
			doorAngleVal.Value = targetAngle
		else
			TweenService:Create(doorAngleVal, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = targetAngle }):Play()
		end
	end

	local damageDoorFn = Instance.new("BindableFunction")
	damageDoorFn.Name = "DamageDoor"
	damageDoorFn.Parent = doorModel
	damageDoorFn.OnInvoke = function(amount)
		local unlocked = tracker and tracker.isSecurityDoorUnlocked and tracker.isSecurityDoorUnlocked()
		if not unlocked or isDoorOpen or doorBroken then
			return false
		end
		doorHP = math.max(0, doorHP - (tonumber(amount) or 20))
		doorModel:SetAttribute("DoorHP", doorHP)
		if doorHP <= 0 then
			doorBroken = true
			doorModel:SetAttribute("IsBroken", true)
			setDoorOpen(true, false)
		end
		return true
	end

	-- 4. Room 102 Left Desk: CCTV Timeline Terminal (X = -122, desk top Y = floorY + 3.6, Z = 74)
	local cctvModel = Instance.new("Model")
	cctvModel.Name = "M1_CCTVTerminal"
	cctvModel.Parent = root

	local cctvBase = makePart(cctvModel, "TerminalUnit", Vector3.new(5.8, 2.4, 1.8),
		CFrame.new(-122, floorY + 4.8, 74), Color3.fromRGB(26, 32, 42), Enum.Material.Metal)
	local cctvScreen = makePart(cctvModel, "TerminalScreen", Vector3.new(5.2, 1.9, 0.16),
		CFrame.new(-122, floorY + 4.9, 73.05), Color3.fromRGB(45, 190, 240), Enum.Material.Neon, { CanCollide = false })
	local cctvLight = Instance.new("PointLight")
	cctvLight.Color = Color3.fromRGB(70, 200, 255)
	cctvLight.Range = 14
	cctvLight.Brightness = 1.25
	cctvLight:SetAttribute("HorrorEmergencyLight", true)
	cctvLight.Parent = cctvScreen
	local cctvHeader, cctvBody = makeSurfacePanel(cctvScreen, Enum.NormalId.Front, "เครื่องควบคุม CCTV", "ล็อกอยู่\nปลดล็อกประตูห้อง 102 ก่อน", Color3.fromRGB(10, 22, 32), Color3.fromRGB(22, 115, 165))

	local cctvPrompt = Instance.new("ProximityPrompt")
	cctvPrompt.Name = "CCTVTerminalPrompt"
	cctvPrompt.ActionText = "เปิดเครื่องตรวจสอบ CCTV"
	cctvPrompt.ObjectText = "คอมพิวเตอร์เซิร์ฟเวอร์ CCTV ห้อง 102"
	cctvPrompt.KeyboardKeyCode = Enum.KeyCode.E
	cctvPrompt.HoldDuration = 0.2
	cctvPrompt.MaxActivationDistance = 10
	cctvPrompt.RequiresLineOfSight = false
	cctvPrompt.Parent = cctvBase

	-- 5. Room 102 Right Desk: Security Control Override Console (X = -96, Z = 74)
	local overrideModel = Instance.new("Model")
	overrideModel.Name = "M1_SecurityOverrideConsole"
	overrideModel.Parent = root

	local overrideBase = makePart(overrideModel, "OverrideUnit", Vector3.new(4.8, 2.2, 1.8),
		CFrame.new(-96, floorY + 4.7, 74), Color3.fromRGB(32, 34, 42), Enum.Material.Metal)
	local overrideScreen = makePart(overrideModel, "OverrideScreen", Vector3.new(4.2, 1.7, 0.16),
		CFrame.new(-96, floorY + 4.8, 73.05), Color3.fromRGB(215, 55, 65), Enum.Material.Neon, { CanCollide = false })
	local overrideLight = Instance.new("PointLight")
	overrideLight.Color = Color3.fromRGB(215, 55, 65)
	overrideLight.Range = 14
	overrideLight.Brightness = 1.25
	overrideLight:SetAttribute("HorrorEmergencyLight", true)
	overrideLight.Parent = overrideScreen
	local overrideHeader, overrideBody = makeSurfacePanel(overrideScreen, Enum.NormalId.Front, "OVERRIDE ระบบตึก", "ล็อกอยู่\nเรียงลำดับกล้อง CCTV ก่อน", Color3.fromRGB(24, 14, 18), Color3.fromRGB(165, 38, 48))

	local overridePrompt = Instance.new("ProximityPrompt")
	overridePrompt.Name = "OverrideConsolePrompt"
	overridePrompt.ActionText = "เริ่มอัปโหลด Security Override"
	overridePrompt.ObjectText = "ระบบควบคุมความปลอดภัยอาคาร 40 ปี"
	overridePrompt.KeyboardKeyCode = Enum.KeyCode.E
	overridePrompt.HoldDuration = 0.65
	overridePrompt.MaxActivationDistance = 10
	overridePrompt.RequiresLineOfSight = false
	overridePrompt.Parent = overrideBase

	-- 6. Guard Note + Tactical Two-Way Radio + Roof Key Prop (Room 102 Override Desk left side)
	local guardModel = Instance.new("Model")
	guardModel.Name = "M1_GuardNote"
	guardModel.Parent = root

	local guardBook = makePart(guardModel, "GuardLogCover", Vector3.new(1.75, 0.14, 1.3),
		CFrame.new(-100.6, floorY + 3.68, 73.2) * CFrame.Angles(0, math.rad(-14), 0),
		Color3.fromRGB(34, 52, 78), Enum.Material.SmoothPlastic)
	local guardPage = makePart(guardModel, "GuardLogPage", Vector3.new(1.52, 0.05, 1.12),
		guardBook.CFrame * CFrame.new(0, 0.08, 0),
		Color3.fromRGB(246, 238, 208), Enum.Material.SmoothPlastic, { CanCollide = false })
	makePart(guardModel, "GuardLogHeading", Vector3.new(1.15, 0.02, 0.14),
		guardPage.CFrame * CFrame.new(0, 0.03, -0.34), Color3.fromRGB(185, 42, 46), Enum.Material.SmoothPlastic, { CanCollide = false })
	makePart(guardModel, "GuardNotePen", Vector3.new(0.85, 0.08, 0.08),
		guardPage.CFrame * CFrame.new(0.35, 0.06, 0.2) * CFrame.Angles(0, math.rad(34), 0),
		Color3.fromRGB(28, 30, 36), Enum.Material.Metal, { CanCollide = false })

	-- กุญแจดาดฟ้าและวิทยุสื่อสารวางข้างสมุดเวร รปภ.
	makePart(guardModel, "GuardRoofKeyHead", Vector3.new(0.44, 0.08, 0.44),
		CFrame.new(-101.8, floorY + 3.66, 72.4) * CFrame.Angles(0, math.rad(18), 0),
		Color3.fromRGB(230, 188, 68), Enum.Material.Metal, { CanCollide = false })
	makePart(guardModel, "GuardRoofKeyBlade", Vector3.new(0.75, 0.07, 0.16),
		CFrame.new(-101.35, floorY + 3.66, 72.4) * CFrame.Angles(0, math.rad(18), 0),
		Color3.fromRGB(230, 188, 68), Enum.Material.Metal, { CanCollide = false })
	makePart(guardModel, "GuardRoofKeyTag", Vector3.new(0.65, 0.05, 0.34),
		CFrame.new(-102.25, floorY + 3.65, 72.55) * CFrame.Angles(0, math.rad(-12), 0),
		Color3.fromRGB(235, 195, 48), Enum.Material.Neon, { CanCollide = false })

	local radioBody = makePart(guardModel, "GuardRadioBody", Vector3.new(0.58, 1.15, 0.42),
		CFrame.new(-102.1, floorY + 4.18, 74.1) * CFrame.Angles(0, math.rad(28), 0),
		Color3.fromRGB(24, 28, 34), Enum.Material.Metal, { CanCollide = false })
	makePart(guardModel, "GuardRadioAntenna", Vector3.new(0.08, 1.05, 0.08),
		radioBody.CFrame * CFrame.new(0.18, 0.98, 0), Color3.fromRGB(18, 20, 24), Enum.Material.Metal, { CanCollide = false })
	local radioLED = makePart(guardModel, "GuardRadioLED", Vector3.new(0.14, 0.14, 0.06),
		radioBody.CFrame * CFrame.new(-0.12, 0.35, -0.21), Color3.fromRGB(70, 240, 130), Enum.Material.Neon, { CanCollide = false })
	local guardLight = Instance.new("PointLight")
	guardLight.Color = Color3.fromRGB(255, 225, 145)
	guardLight.Range = 9
	guardLight.Brightness = 0.75
	guardLight:SetAttribute("HorrorEmergencyLight", true)
	guardLight.Parent = guardPage

	local guardNotePrompt = Instance.new("ProximityPrompt")
	guardNotePrompt.Name = "GuardNotePrompt"
	guardNotePrompt.ActionText = "อ่านสมุดเวร รปภ. (บันทึกเหตุการณ์)"
	guardNotePrompt.ObjectText = "สมุดเวร รปภ. + วิทยุสื่อสาร & กุญแจดาดฟ้า"
	guardNotePrompt.KeyboardKeyCode = Enum.KeyCode.E
	guardNotePrompt.HoldDuration = 0
	guardNotePrompt.MaxActivationDistance = 10
	guardNotePrompt.RequiresLineOfSight = false
	guardNotePrompt.Parent = guardBook

	-- 7. Room 102 Monitor Wall (3x4 หรือ 4x4 ตาม MissionConfig.ROOM102, ไม่ใช้ ViewportFrame)
	local wallModel = Instance.new("Model")
	wallModel.Name = "M1_MonitorWall"
	wallModel.Parent = root

	local r102Cfg = MissionConfig.ROOM102 or {}
	local gridRows = math.clamp(tonumber(r102Cfg.MONITOR_GRID_ROWS) or 3, 2, 4)
	local gridCols = math.clamp(tonumber(r102Cfg.MONITOR_GRID_COLS) or 4, 4, 5)
	local cellW, cellH = 7.4, 3.9
	local wallCenterX = -109.0
	local wallZ = 87.8
	local bottomRowY = floorY + 3.45

	local rackWidth = gridCols * cellW + 2.4
	local rackHeight = gridRows * cellH + 1.8
	local rackCenterY = bottomRowY - cellH * 0.5 + rackHeight * 0.5 - 0.3
	makePart(wallModel, "MonitorWallBacking", Vector3.new(rackWidth, rackHeight, 0.9),
		CFrame.new(wallCenterX, rackCenterY, wallZ + 0.55), Color3.fromRGB(22, 26, 32), Enum.Material.Metal)

	-- ไฟส่องหน้าจอสีฟ้า-เขียวทำงานคู่กับไฟ UPS เหลืองในโหมดไฟดับ
	for gIdx, gx in ipairs({ wallCenterX - 9.0, wallCenterX + 9.0 }) do
		local glowPart = makePart(wallModel, "MonitorGlowEmitter_" .. gIdx, Vector3.new(6.0, 0.3, 0.4),
			CFrame.new(gx, bottomRowY + (gridRows - 1) * cellH + 2.35, wallZ - 0.4),
			Color3.fromRGB(65, 225, 195), Enum.Material.Neon, { CanCollide = false })
		local mLight = Instance.new("PointLight")
		mLight.Name = "Room102_MonitorGlowLight_" .. gIdx
		mLight.Color = Color3.fromRGB(70, 225, 195)
		mLight.Range = 36
		mLight.Brightness = 1.15
		mLight.Shadows = false
		mLight:SetAttribute("HorrorEmergencyLight", true)
		mLight:SetAttribute("Room102MonitorGlow", true)
		mLight:SetAttribute("BaseBrightness", 1.15)
		mLight.Parent = glowPart
	end

	local camClips = (puzzleEngine and puzzleEngine.getMonitorWallClips) and puzzleEngine.getMonitorWallClips() or {}
	local camMonitors = {}
	local upsPanelRefs = {}
	local schematicRefs = nil
	local allMonitorFlashOverlays = {}

	local decorativeFeeds = {
		{ tag = "CAM-BANK", title = "โถงธนาคาร F1", kind = "CAM", accent = Color3.fromRGB(70, 185, 200), note = "SIGN: พบความเสียหายที่เคาน์เตอร์" },
		{ tag = "CAM-CANTEEN", title = "โรงอาหาร F2", kind = "CAM", accent = Color3.fromRGB(95, 205, 145), note = "POWER: ไฟฟ้าหลักขัดข้อง" },
		{ tag = "CAM-LIFTS", title = "โถงลิฟต์ F1", kind = "CAM", accent = Color3.fromRGB(210, 175, 75), note = "ELEVATOR: หยุดทำงานฉุกเฉิน" },
		{ tag = "CAM-PLAZA", title = "ลานหน้าอาคาร", kind = "CAM", accent = Color3.fromRGB(220, 110, 85), note = "MOTION: ตรวจพบการเคลื่อนไหว" },
		{ tag = "CAM-ROOF", title = "ลานดาดฟ้า F12", kind = "CAM", accent = Color3.fromRGB(80, 215, 230), note = "SOS: มีแสงไฟสัญญาณจากผู้รอดชีวิต" },
		{ tag = "NO-SIG-A", title = "NO SIGNAL", kind = "NOSIGNAL", accent = Color3.fromRGB(220, 65, 75), note = "สายสัญญาณชั้น 3-5 ขาดหาย" },
		{ tag = "NO-SIG-B", title = "NO SIGNAL", kind = "NOSIGNAL", accent = Color3.fromRGB(220, 65, 75), note = "INPUT LOST // CH-09" },
		{ tag = "CAM-STAIR", title = "บันไดหนีไฟหลัก", kind = "CAM", accent = Color3.fromRGB(235, 145, 70), note = "SCANNING STAIRWELL..." },
	}
	local decoIndex = 0

	local function createMonitorCell(row, col)
		local cx = wallCenterX - (col - (gridCols + 1) / 2) * cellW
		local cy = bottomRowY + (gridRows - row) * cellH
		local bezel = makePart(wallModel, string.format("MonitorBezel_R%dC%d", row, col), Vector3.new(cellW - 0.55, cellH - 0.45, 0.36),
			CFrame.new(cx, cy, wallZ), Color3.fromRGB(28, 32, 38), Enum.Material.Metal)
		local screen = makePart(wallModel, string.format("MonitorScreen_R%dC%d", row, col), Vector3.new(cellW - 0.95, cellH - 0.85, 0.1),
			CFrame.new(cx, cy, wallZ - 0.2), Color3.fromRGB(12, 24, 30), Enum.Material.SmoothPlastic, { CanCollide = false })

		local gui = Instance.new("SurfaceGui")
		gui.Name = "MonitorGui"
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(480, 270)
		gui.MaxDistance = 120
		gui.LightInfluence = 0
		gui.Parent = screen

		local bg = Instance.new("Frame")
		bg.Name = "Root"
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromRGB(8, 16, 22)
		bg.BorderSizePixel = 0
		bg.Parent = gui

		local border = Instance.new("UIStroke")
		border.Name = "BorderStroke"
		border.Color = Color3.fromRGB(52, 180, 175)
		border.Thickness = 4
		border.Parent = bg

		local scanOverlay = Instance.new("Frame")
		scanOverlay.Name = "ScanlineSweep"
		scanOverlay.Size = UDim2.new(1, 0, 0.14, 0)
		scanOverlay.Position = UDim2.fromScale(0, 0.2)
		scanOverlay.BackgroundColor3 = Color3.fromRGB(160, 255, 235)
		scanOverlay.BackgroundTransparency = 0.88
		scanOverlay.BorderSizePixel = 0
		scanOverlay.ZIndex = 4
		scanOverlay.Parent = bg

		local alarmOverlay = Instance.new("Frame")
		alarmOverlay.Name = "AlarmOverlay"
		alarmOverlay.Size = UDim2.fromScale(1, 1)
		alarmOverlay.BackgroundColor3 = Color3.fromRGB(225, 32, 42)
		alarmOverlay.BackgroundTransparency = 1
		alarmOverlay.BorderSizePixel = 0
		alarmOverlay.ZIndex = 6
		alarmOverlay.Parent = bg
		table.insert(allMonitorFlashOverlays, alarmOverlay)

		return bezel, screen, bg, border
	end

	for row = 1, gridRows do
		for col = 1, gridCols do
			local bezel, screen, bg, border = createMonitorCell(row, col)
			if row == gridRows and col >= 1 and col <= 4 and camClips[col] then
				-- จอกล้องปริศนา CAM-01 ถึง CAM-04 อยู่แถวล่างให้เดินกด [E] ได้สะดวก
				local clip = camClips[col]
				screen:SetAttribute("MonitorEffect", "PuzzleCam")
				screen:SetAttribute("CamId", clip.camId)
				screen:SetAttribute("ClipId", clip.clipId)
				border.Color = Color3.fromRGB(65, 200, 220)

				-- โพสต์อิตแปะขอบจอกล้อง
				makePart(wallModel, "StickyNote_CAM" .. col, Vector3.new(0.55, 0.55, 0.04),
					bezel.CFrame * CFrame.new((cellW - 0.9) * 0.42, (cellH - 0.8) * 0.36, -0.22) * CFrame.Angles(0, 0, math.rad(-8 + col * 5)),
					(col % 2 == 0) and Color3.fromRGB(252, 232, 92) or Color3.fromRGB(145, 235, 215), Enum.Material.SmoothPlastic, { CanCollide = false })

				local headerBar = Instance.new("TextLabel")
				headerBar.Size = UDim2.new(1, -16, 0, 44)
				headerBar.Position = UDim2.new(0, 8, 0, 8)
				headerBar.BackgroundColor3 = Color3.fromRGB(18, 62, 74)
				headerBar.BorderSizePixel = 0
				headerBar.Font = Enum.Font.Code
				headerBar.TextSize = 22
				headerBar.TextColor3 = Color3.fromRGB(185, 250, 245)
				headerBar.Text = string.format("%s | %s", clip.camId, clip.label)
				headerBar.Parent = bg

				local captionLbl = Instance.new("TextLabel")
				captionLbl.Size = UDim2.new(1, -24, 0, 128)
				captionLbl.Position = UDim2.new(0, 12, 0, 62)
				captionLbl.BackgroundTransparency = 1
				captionLbl.Font = Enum.Font.GothamMedium
				captionLbl.TextSize = 21
				captionLbl.TextWrapped = true
				captionLbl.TextXAlignment = Enum.TextXAlignment.Left
				captionLbl.TextYAlignment = Enum.TextYAlignment.Top
				captionLbl.TextColor3 = Color3.fromRGB(228, 242, 248)
				captionLbl.Text = string.format("[%s] %s", clip.timestampLabel, clip.caption)
				captionLbl.Parent = bg

				local pickBadge = Instance.new("TextLabel")
				pickBadge.Size = UDim2.new(1, -16, 0, 46)
				pickBadge.Position = UDim2.new(0, 8, 1, -54)
				pickBadge.BackgroundColor3 = Color3.fromRGB(14, 28, 36)
				pickBadge.BorderSizePixel = 0
				pickBadge.Font = Enum.Font.GothamBold
				pickBadge.TextSize = 21
				pickBadge.TextColor3 = Color3.fromRGB(165, 215, 230)
				pickBadge.Text = "กด [E] เพื่อเลือกตามลำดับเหตุการณ์"
				pickBadge.Parent = bg

				local camPrompt = Instance.new("ProximityPrompt")
				camPrompt.Name = "CAMMonitorPrompt_" .. col
				camPrompt.ActionText = "เลือกกล้อง " .. clip.camId
				camPrompt.ObjectText = clip.label
				camPrompt.KeyboardKeyCode = Enum.KeyCode.E
				camPrompt.HoldDuration = 0.1
				camPrompt.MaxActivationDistance = 11.5
				camPrompt.RequiresLineOfSight = false
				camPrompt.Parent = screen

				camMonitors[col] = {
					slot = col,
					clip = clip,
					screen = screen,
					bg = bg,
					border = border,
					headerBar = headerBar,
					captionLbl = captionLbl,
					pickBadge = pickBadge,
					prompt = camPrompt,
				}
			elseif row == 1 and col == 1 then
				-- จอสถานะ UPS BACKUP + Progress Bar Hold-Out
				screen:SetAttribute("MonitorEffect", "UPSBanner")
				border.Color = Color3.fromRGB(255, 190, 50)
				bg.BackgroundColor3 = Color3.fromRGB(26, 16, 8)

				local title = Instance.new("TextLabel")
				title.Size = UDim2.new(1, -16, 0, 44)
				title.Position = UDim2.new(0, 8, 0, 8)
				title.BackgroundColor3 = Color3.fromRGB(145, 78, 18)
				title.BorderSizePixel = 0
				title.Font = Enum.Font.Code
				title.TextSize = 21
				title.TextColor3 = Color3.fromRGB(255, 238, 190)
				title.Text = "POWER // แบตเตอรี่สำรองห้อง 102"
				title.Parent = bg

				local upsBig = Instance.new("TextLabel")
				upsBig.Name = "UPSStatusText"
				upsBig.Size = UDim2.new(1, -20, 0, 110)
				upsBig.Position = UDim2.new(0, 10, 0, 62)
				upsBig.BackgroundTransparency = 1
				upsBig.Font = Enum.Font.Code
				upsBig.TextSize = 36
				upsBig.TextWrapped = true
				upsBig.TextColor3 = Color3.fromRGB(255, 198, 58)
				upsBig.Text = string.format("UPS BACKUP: %d%%\nCRITICAL", tonumber(r102Cfg.UPS_INITIAL_PERCENT) or 34)
				upsBig.Parent = bg

				local holdStatus = Instance.new("TextLabel")
				holdStatus.Size = UDim2.new(1, -20, 0, 64)
				holdStatus.Position = UDim2.new(0, 10, 1, -74)
				holdStatus.BackgroundColor3 = Color3.fromRGB(36, 22, 12)
				holdStatus.BorderSizePixel = 0
				holdStatus.Font = Enum.Font.GothamBold
				holdStatus.TextSize = 18
				holdStatus.TextColor3 = Color3.fromRGB(255, 220, 145)
				holdStatus.Text = "ไฟฟ้าหลักดับทั้งอาคาร — ไฟห้องนี้ใช้แบตสำรอง"
				holdStatus.Parent = bg

				table.insert(upsPanelRefs, { big = upsBig, sub = holdStatus, border = border })
			elseif row == 1 and col == gridCols then
				-- จอแผนผังอาคาร 40 ปี มจพ. + จุดแดงกะพริบอันตราย + ข้อมูลซอมบี้ทางขึ้นดาดฟ้า
				screen:SetAttribute("MonitorEffect", "Schematic")
				border.Color = Color3.fromRGB(215, 70, 80)
				bg.BackgroundColor3 = Color3.fromRGB(10, 18, 28)

				local mapTitle = Instance.new("TextLabel")
				mapTitle.Size = UDim2.new(1, -16, 0, 38)
				mapTitle.Position = UDim2.new(0, 8, 0, 8)
				mapTitle.BackgroundColor3 = Color3.fromRGB(24, 52, 84)
				mapTitle.BorderSizePixel = 0
				mapTitle.Font = Enum.Font.Code
				mapTitle.TextSize = 20
				mapTitle.TextColor3 = Color3.fromRGB(215, 240, 255)
				mapTitle.Text = "แผนผังอาคาร 40 ปี (M.J.P. BLDG 40)"
				mapTitle.Parent = bg

				local blueprintBox = Instance.new("Frame")
				blueprintBox.Size = UDim2.new(1, -20, 0, 134)
				blueprintBox.Position = UDim2.new(0, 10, 0, 52)
				blueprintBox.BackgroundColor3 = Color3.fromRGB(12, 28, 46)
				blueprintBox.BorderColor3 = Color3.fromRGB(58, 125, 175)
				blueprintBox.BorderSizePixel = 2
				blueprintBox.Parent = bg

				for fIdx = 1, 4 do
					local flBar = Instance.new("Frame")
					flBar.Size = UDim2.new(0.84, 0, 0, 16)
					flBar.Position = UDim2.new(0.08, 0, 0.1 + (fIdx - 1) * 0.22, 0)
					flBar.BackgroundColor3 = Color3.fromRGB(24, 58, 92)
					flBar.BorderSizePixel = 0
					flBar.Parent = blueprintBox
				end

				local dotCoords = { { 0.22, 0.78 }, { 0.68, 0.56 }, { 0.42, 0.34 }, { 0.78, 0.14 } }
				for dIdx, dc in ipairs(dotCoords) do
					local dot = Instance.new("Frame")
					dot.Name = "HazardDot_" .. dIdx
					dot.Size = UDim2.fromOffset(18, 18)
					dot.AnchorPoint = Vector2.new(0.5, 0.5)
					dot.Position = UDim2.fromScale(dc[1], dc[2])
					dot.BackgroundColor3 = Color3.fromRGB(255, 55, 65)
					dot.BorderSizePixel = 0
					dot.Parent = blueprintBox
					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(1, 0)
					corner.Parent = dot
				end

				local intelLbl = Instance.new("TextLabel")
				intelLbl.Name = "IntelLabel"
				intelLbl.Size = UDim2.new(1, -20, 0, 66)
				intelLbl.Position = UDim2.new(0, 10, 1, -74)
				intelLbl.BackgroundColor3 = Color3.fromRGB(34, 18, 22)
				intelLbl.BorderSizePixel = 0
				intelLbl.Font = Enum.Font.GothamBold
				intelLbl.TextSize = 17
				intelLbl.TextWrapped = true
				intelLbl.TextColor3 = Color3.fromRGB(255, 165, 165)
				intelLbl.Text = "ทางขึ้นดาดฟ้า: เข้ารหัสอยู่ — เรียง CCTV เพื่อสแกนฝูงซอมบี้"
				intelLbl.Parent = bg

				schematicRefs = { border = border, intelLbl = intelLbl }
			else
				-- จอตกแต่ง: ภาพนิ่งจำลองโถง/โรงอาหาร/ลิฟต์/ดาดฟ้า/NO SIGNAL (ไม่มี ViewportFrame)
				decoIndex += 1
				local feed = decorativeFeeds[((decoIndex - 1) % #decorativeFeeds) + 1]
				screen:SetAttribute("MonitorEffect", feed.kind == "NOSIGNAL" and "StaticFeed" or "DecorativeCam")
				border.Color = feed.accent

				local topLbl = Instance.new("TextLabel")
				topLbl.Size = UDim2.new(1, -16, 0, 34)
				topLbl.Position = UDim2.new(0, 8, 0, 8)
				topLbl.BackgroundColor3 = Color3.fromRGB(16, 28, 36)
				topLbl.BorderSizePixel = 0
				topLbl.Font = Enum.Font.Code
				topLbl.TextSize = 18
				topLbl.TextColor3 = feed.accent
				topLbl.Text = string.format("%s | %s", feed.tag, feed.title)
				topLbl.Parent = bg

				local midCanvas = Instance.new("Frame")
				midCanvas.Name = "StylizedFeed"
				midCanvas.Size = UDim2.new(1, -24, 0, 152)
				midCanvas.Position = UDim2.new(0, 12, 0, 48)
				midCanvas.BackgroundColor3 = feed.kind == "NOSIGNAL" and Color3.fromRGB(28, 16, 18) or Color3.fromRGB(12, 24, 28)
				midCanvas.BorderColor3 = Color3.fromRGB(45, 75, 85)
				midCanvas.Parent = bg

				if feed.kind == "NOSIGNAL" then
					local noSig = Instance.new("TextLabel")
					noSig.Name = "NoSignalText"
					noSig.Size = UDim2.fromScale(1, 1)
					noSig.BackgroundTransparency = 1
					noSig.Font = Enum.Font.Code
					noSig.TextSize = 36
					noSig.TextColor3 = Color3.fromRGB(255, 85, 95)
					noSig.Text = "NO SIGNAL\n[ LOSS OF FEED ]"
					noSig.Parent = midCanvas
				else
					-- วาดภาพจำลองห้องแบบ 2D UI Weight เบา
					local horizon = Instance.new("Frame")
					horizon.Size = UDim2.new(1, 0, 0.42, 0)
					horizon.Position = UDim2.fromScale(0, 0.58)
					horizon.BackgroundColor3 = Color3.fromRGB(20, 38, 42)
					horizon.BorderSizePixel = 0
					horizon.Parent = midCanvas
					for b = 1, 3 do
						local pillar = Instance.new("Frame")
						pillar.Size = UDim2.new(0.08, 0, 0.72, 0)
						pillar.Position = UDim2.fromScale(0.14 + (b - 1) * 0.32, 0.14)
						pillar.BackgroundColor3 = Color3.fromRGB(34, 58, 66)
						pillar.BorderSizePixel = 0
						pillar.Parent = midCanvas
					end
					local recTag = Instance.new("TextLabel")
					recTag.Size = UDim2.new(0.45, 0, 0.22, 0)
					recTag.Position = UDim2.fromScale(0.04, 0.08)
					recTag.BackgroundTransparency = 1
					recTag.Font = Enum.Font.Code
					recTag.TextSize = 18
					recTag.TextXAlignment = Enum.TextXAlignment.Left
					recTag.TextColor3 = Color3.fromRGB(230, 85, 85)
					recTag.Text = "● REC LOW-LIGHT"
					recTag.Parent = midCanvas
				end

				local footLbl = Instance.new("TextLabel")
				footLbl.Size = UDim2.new(1, -20, 0, 48)
				footLbl.Position = UDim2.new(0, 10, 1, -56)
				footLbl.BackgroundTransparency = 1
				footLbl.Font = Enum.Font.GothamMedium
				footLbl.TextSize = 17
				footLbl.TextColor3 = Color3.fromRGB(190, 215, 220)
				footLbl.Text = feed.note
				footLbl.Parent = bg
			end
		end
	end

	-- 8. M2 Power Room Generator Console (ชั้น 2 ลานโล่งหน้าทางขึ้นบันไดหน้าตึก X=-22, Z=76)
	local genModel = Instance.new("Model")
	genModel.Name = "M2_PowerRoomGenerator"
	genModel.Parent = root

	local genBody = makePart(genModel, "GeneratorCabinet", Vector3.new(7.4, 5.4, 4.2),
		CFrame.new(-22, floor2Y + 2.7, 76), Color3.fromRGB(48, 58, 52), Enum.Material.Metal)
	makePart(genModel, "GeneratorStripe", Vector3.new(7.5, 0.5, 4.3),
		CFrame.new(-22, floor2Y + 0.6, 76), Color3.fromRGB(220, 170, 35), Enum.Material.SmoothPlastic)
	makePart(genModel, "GeneratorCoil", Vector3.new(2.2, 4.0, 2.2),
		CFrame.new(-24.2, floor2Y + 2.6, 76), Color3.fromRGB(165, 105, 55), Enum.Material.Metal)
	local genPanel = makePart(genModel, "GeneratorPanel", Vector3.new(3.6, 2.4, 0.18),
		CFrame.new(-20.8, floor2Y + 3.4, 73.82), Color3.fromRGB(20, 28, 34), Enum.Material.SmoothPlastic, { CanCollide = false })
	local genBeacon = makePart(genModel, "GeneratorBeacon", Vector3.new(0.85, 0.9, 0.85),
		CFrame.new(-22, floor2Y + 5.85, 76), Color3.fromRGB(235, 55, 65), Enum.Material.Neon, { CanCollide = false })
	local genLight = Instance.new("PointLight")
	genLight.Color = Color3.fromRGB(235, 55, 65)
	genLight.Range = 22
	genLight.Brightness = 1.6
	genLight:SetAttribute("HorrorEmergencyLight", true)
	genLight.Parent = genBeacon
	local genHeader, genBodyTxt = makeSurfacePanel(genPanel, Enum.NormalId.Front,
		"MAIN GENERATOR [F2]", "OFFLINE — รอปลดล็อกTier 1 จากห้อง 102",
		Color3.fromRGB(24, 16, 18), Color3.fromRGB(185, 48, 55))

	local genPrompt = Instance.new("ProximityPrompt")
	genPrompt.Name = "PowerGeneratorPrompt"
	genPrompt.ActionText = "กู้คืนพลังงานไฟฟ้าทั้งอาคาร"
	genPrompt.ObjectText = "เครื่องกำเนิดไฟฟ้าหลักอาคาร 40 ปี (ชั้น 2)"
	genPrompt.KeyboardKeyCode = Enum.KeyCode.E
	genPrompt.HoldDuration = 1.0
	genPrompt.MaxActivationDistance = 11
	genPrompt.RequiresLineOfSight = false
	genPrompt.Enabled = false
	genPrompt.Parent = genBody

	local currentHoldoutInfo = nil
	local loadedVariantId = puzzleEngine and puzzleEngine.getVariantId and puzzleEngine.getVariantId() or nil

	-- Sync world visuals with authoritative tracker + puzzle state
	local controller = {}

	local function refreshMonitorWallClips()
		if not (puzzleEngine and puzzleEngine.getMonitorWallClips) then return end
		local latestClips = puzzleEngine.getMonitorWallClips()
		loadedVariantId = puzzleEngine.getVariantId and puzzleEngine.getVariantId() or loadedVariantId
		for idx, mon in pairs(camMonitors) do
			local clip = latestClips[idx]
			if clip then
				mon.clip = clip
				mon.screen:SetAttribute("CamId", clip.camId)
				mon.screen:SetAttribute("ClipId", clip.clipId)
				mon.headerBar.Text = string.format("%s | %s", clip.camId, clip.label)
				mon.captionLbl.Text = string.format("[%s] %s", clip.timestampLabel, clip.caption)
				mon.prompt.ActionText = "เลือกกล้อง " .. clip.camId
				mon.prompt.ObjectText = clip.label
			end
		end
	end

	local function syncMonitorAndGenerator()
		local currentVariant = puzzleEngine and puzzleEngine.getVariantId and puzzleEngine.getVariantId() or nil
		if currentVariant and currentVariant ~= loadedVariantId then
			refreshMonitorWallClips()
		end
		local doorUnlocked = tracker and tracker.isSecurityDoorUnlocked and tracker.isSecurityDoorUnlocked()
		local puzzleSolved = puzzleEngine and puzzleEngine.isSolved and puzzleEngine.isSolved()
		local useFallback = (MissionConfig.ROOM102 and MissionConfig.ROOM102.USE_MODAL_PUZZLE_FALLBACK) == true
		local upsPct = tonumber(Workspace:GetAttribute("Room102UPSPercent")) or (r102Cfg.UPS_INITIAL_PERCENT or 34)
		local seqStr = tostring(Workspace:GetAttribute("Room102MonitorSequence") or "")
		local intelRevealed = Workspace:GetAttribute("Room102CCTVIntelRevealed") == true
		local intelText = tostring(Workspace:GetAttribute("Room102IntelText") or "ตรวจพบฝูงซอมบี้รวมตัวที่บันไดทางขึ้นดาดฟ้า!")

		local pickedMap = {}
		local orderIdx = 0
		for token in string.gmatch(seqStr, "[^,]+") do
			orderIdx += 1
			pickedMap[token] = orderIdx
		end

		for idx, mon in pairs(camMonitors) do
			mon.prompt.Enabled = (doorUnlocked == true) and (not puzzleSolved) and (not useFallback)
			if puzzleSolved then
				local solvedRank = (puzzleEngine and puzzleEngine.getSolvedRank and puzzleEngine.getSolvedRank(mon.clip.id or mon.clip.clipId)) or idx
				mon.border.Color = Color3.fromRGB(55, 235, 130)
				mon.headerBar.BackgroundColor3 = Color3.fromRGB(26, 125, 74)
				mon.pickBadge.BackgroundColor3 = Color3.fromRGB(20, 72, 46)
				mon.pickBadge.TextColor3 = Color3.fromRGB(190, 255, 210)
				mon.pickBadge.Text = string.format("ยืนยันแล้ว #%d (%s)", solvedRank, tostring(mon.clip.timestampLabel or mon.clip.timeStampLabel or ""))
			elseif pickedMap[mon.clip.clipId] then
				local stepNum = pickedMap[mon.clip.clipId]
				mon.border.Color = Color3.fromRGB(255, 200, 55)
				mon.headerBar.BackgroundColor3 = Color3.fromRGB(130, 92, 22)
				mon.pickBadge.BackgroundColor3 = Color3.fromRGB(90, 62, 16)
				mon.pickBadge.TextColor3 = Color3.fromRGB(255, 238, 165)
				mon.pickBadge.Text = string.format("เลือกไว้ลำดับที่ #%d", stepNum)
			elseif doorUnlocked then
				mon.border.Color = Color3.fromRGB(65, 200, 220)
				mon.headerBar.BackgroundColor3 = Color3.fromRGB(18, 62, 74)
				mon.pickBadge.BackgroundColor3 = Color3.fromRGB(14, 28, 36)
				mon.pickBadge.TextColor3 = Color3.fromRGB(165, 215, 230)
				mon.pickBadge.Text = useFallback and "โหมดหน้าต่าง Terminal (กดที่โต๊ะซ้าย)" or "กด [E] เพื่อเลือกตามลำดับเหตุการณ์"
			else
				mon.border.Color = Color3.fromRGB(185, 110, 40)
				mon.pickBadge.Text = "รอปลดล็อกประตูห้องควบคุม 102"
			end
		end

		for _, u in ipairs(upsPanelRefs) do
			u.big.Text = string.format("UPS BACKUP: %d%%\nCRITICAL", upsPct)
			if currentHoldoutInfo and currentHoldoutInfo.active then
				u.sub.Text = string.format("กำลังอัปโหลด OVERRIDE: เหลือ %d วินาที", math.ceil(currentHoldoutInfo.remaining or 0))
				u.border.Color = Color3.fromRGB(255, 95, 55)
			else
				u.sub.Text = "ไฟฟ้าหลักดับทั้งอาคาร — ไฟห้องนี้ใช้แบตสำรอง"
				u.border.Color = Color3.fromRGB(255, 190, 50)
			end
		end

		if schematicRefs then
			if intelRevealed or puzzleSolved then
				schematicRefs.border.Color = Color3.fromRGB(55, 225, 145)
				schematicRefs.intelLbl.BackgroundColor3 = Color3.fromRGB(18, 60, 42)
				schematicRefs.intelLbl.TextColor3 = Color3.fromRGB(175, 255, 210)
				schematicRefs.intelLbl.Text = intelText
			else
				schematicRefs.border.Color = Color3.fromRGB(215, 70, 80)
				schematicRefs.intelLbl.BackgroundColor3 = Color3.fromRGB(34, 18, 22)
				schematicRefs.intelLbl.TextColor3 = Color3.fromRGB(255, 165, 165)
				schematicRefs.intelLbl.Text = "ทางขึ้นดาดฟ้า: เข้ารหัสอยู่ — เรียง CCTV เพื่อสแกนฝูงซอมบี้"
			end
		end

		-- Sync M2 Power Generator on Floor 2
		local powerOn = Workspace:GetAttribute("BuildingPowerOn") == true
		local m2State = tracker and tracker.getMissionState and tracker.getMissionState("M2") or "LOCKED"
		if powerOn or m2State == "COMPLETED" then
			genBeacon.Color = Color3.fromRGB(55, 240, 130)
			genLight.Color = Color3.fromRGB(55, 240, 130)
			genHeader.Text = "MAIN POWER ONLINE"
			genHeader.BackgroundColor3 = Color3.fromRGB(32, 145, 82)
			genBodyTxt.Text = "พลังงานหลักอาคาร 40 ปี กลับมาทำงานแล้ว!"
			genPrompt.Enabled = false
		elseif m2State == "ACTIVE" then
			genBeacon.Color = Color3.fromRGB(255, 195, 50)
			genLight.Color = Color3.fromRGB(255, 195, 50)
			genHeader.Text = "GENERATOR READY [F2]"
			genHeader.BackgroundColor3 = Color3.fromRGB(165, 110, 22)
			genBodyTxt.Text = "กด [E] ค้าง เพื่อสับเบรกเกอร์คืนไฟทั้งอาคาร"
			genPrompt.Enabled = true
		else
			genBeacon.Color = Color3.fromRGB(225, 55, 65)
			genLight.Color = Color3.fromRGB(225, 55, 65)
			genHeader.Text = "GENERATOR LOCKED"
			genHeader.BackgroundColor3 = Color3.fromRGB(155, 42, 48)
			genBodyTxt.Text = "ผ่าน Mission 01 ห้องควบคุม 102 เพื่อปลดล็อก"
			genPrompt.Enabled = false
		end
	end

	function controller.setHoldoutInfo(info)
		currentHoldoutInfo = info
		controller.syncWorldState(false)
	end

	function controller.triggerAlarmVisual(durationSec)
		task.spawn(function()
			local endsAt = os.clock() + (durationSec or 6)
			while os.clock() < endsAt do
				for _, ov in ipairs(allMonitorFlashOverlays) do
					ov.BackgroundTransparency = 0.55
				end
				task.wait(0.22)
				for _, ov in ipairs(allMonitorFlashOverlays) do
					ov.BackgroundTransparency = 0.92
				end
				task.wait(0.22)
			end
			for _, ov in ipairs(allMonitorFlashOverlays) do
				ov.BackgroundTransparency = 1
			end
		end)
	end

	function controller.playMonitorWallSolvedSequence()
		task.spawn(function()
			for idx = 1, 4 do
				local mon = camMonitors[idx]
				if mon then
					mon.border.Color = Color3.fromRGB(80, 255, 150)
					mon.headerBar.BackgroundColor3 = Color3.fromRGB(40, 160, 95)
					mon.pickBadge.Text = string.format("▶ ไทม์ไลน์ %d/4 ยืนยันแล้ว", idx)
				end
				task.wait(0.35)
			end
			controller.syncWorldState(false)
		end)
	end

	function controller.syncWorldState(immediateDoor)
		-- 1. Keycard pickup visibility
		local keyPicked = (keyItemService and keyItemService.isWorldPicked("SecurityKeycard"))
			or (tracker and tracker.hasTeamQuestItem and tracker.hasTeamQuestItem("SecurityKeycard"))
			or (tracker and tracker.isSecurityDoorUnlocked and tracker.isSecurityDoorUnlocked())
		if keycardTray then
			keycardTray.Transparency = keyPicked and 1 or 0
		end
		keycardCard.Transparency = keyPicked and 1 or 0
		keycardStripe.Transparency = keyPicked and 1 or 0
		keycardLight.Enabled = not keyPicked
		if keyPicked then
			keycardPrompt.Enabled = false
		else
			keycardPrompt.Enabled = true
			keycardPrompt.ActionText = "ค้นตัวผู้จัดการ — หยิบคีย์การ์ด (Search Corpse)"
			keycardPrompt.ObjectText = "ร่างของพัชรี ส. (ผู้จัดการสาขา)"
			keycardPrompt.HoldDuration = 0.4
		end

		-- 1B. Maintenance Key & Service Locker state
		local lockerUnlocked = doorAccessService and doorAccessService.isUnlocked("M1_SERVICE_LOCKER") or false
		local mKeyPicked = (keyItemService and keyItemService.isWorldPicked("MaintenanceKey"))
			or (tracker and tracker.hasTeamQuestItem and tracker.hasTeamQuestItem("MaintenanceKey"))
			or lockerUnlocked
		mKeyTray.Transparency = mKeyPicked and 1 or 0
		mKeyBlade.Transparency = mKeyPicked and 1 or 0
		mKeyLight.Enabled = not mKeyPicked
		mKeyPrompt.Enabled = not mKeyPicked

		if lockerUnlocked then
			lockerLED.Color = Color3.fromRGB(55, 235, 130)
			lockerDoor.CFrame = CFrame.new(-83.9, floorY + 3.5, -39.1) * CFrame.Angles(0, math.rad(-88), 0)
			if lockerCacheClaimed then
				lockerPrompt.Enabled = false
			else
				lockerPrompt.Enabled = true
				lockerPrompt.ActionText = "หยิบแบตเตอรี่สำรองและบันทึก"
			end
		else
			lockerLED.Color = Color3.fromRGB(220, 60, 60)
			lockerDoor.CFrame = CFrame.new(-82, floorY + 3.5, -40.9)
			lockerPrompt.Enabled = true
			lockerPrompt.ActionText = "ปลดล็อกตู้ซ่อมบำรุง (ใช้กุญแจ)"
		end

		-- 2. Environmental clue text matching active CCTV puzzle variant
		local clues = (puzzleEngine and puzzleEngine.getClues) and puzzleEngine.getClues() or {}
		if clues[1] then
			clue1Header.Text = clues[1].title
			clue1Body.Text = clues[1].body
		end
		if clues[2] then
			clue2Header.Text = clues[2].title
			clue2Body.Text = clues[2].body
		end

		-- 3. Room 102 Door lock & LED state + BreakableDoor status
		local doorUnlocked = tracker and tracker.isSecurityDoorUnlocked and tracker.isSecurityDoorUnlocked()
		local function syncDoorPrompts(actionText, holdDur, interiorEnabled)
			doorPrompt.ActionText = actionText
			doorPrompt.HoldDuration = holdDur
			interiorDoorPrompt.ActionText = actionText
			interiorDoorPrompt.HoldDuration = holdDur
			interiorDoorPrompt.Enabled = interiorEnabled
		end
		if doorUnlocked then
			readerLED.Color = Color3.fromRGB(55, 235, 130)
			interiorLED.Color = Color3.fromRGB(55, 235, 130)
			readerLight.Color = Color3.fromRGB(55, 235, 130)
			if doorBroken then
				syncDoorPrompts("ซ่อมและปิดประตูห้องควบคุม 102", 0.55, true)
			elseif isDoorOpen then
				syncDoorPrompts("ปิดประตูห้องควบคุม 102", 0.15, true)
			else
				syncDoorPrompts("เปิดประตูห้องควบคุม 102", 0.15, true)
			end
		else
			readerLED.Color = Color3.fromRGB(225, 50, 60)
			interiorLED.Color = Color3.fromRGB(225, 50, 60)
			readerLight.Color = Color3.fromRGB(225, 50, 60)
			syncDoorPrompts("ปลดล็อกห้องควบคุม 102 (ใช้คีย์การ์ด)", 0.35, false)
			setDoorOpen(false, immediateDoor == true)
		end

		-- 4. CCTV Terminal visual state
		local puzzleSolved = puzzleEngine and puzzleEngine.isSolved and puzzleEngine.isSolved()
		local useFallback = (MissionConfig.ROOM102 and MissionConfig.ROOM102.USE_MODAL_PUZZLE_FALLBACK) == true
		if puzzleSolved then
			cctvScreen.Color = Color3.fromRGB(55, 225, 130)
			cctvLight.Color = Color3.fromRGB(55, 225, 130)
			cctvHeader.Text = "ยืนยันลำดับ CCTV แล้ว"
			cctvHeader.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
			cctvBody.Text = "ตรวจสอบไทม์ไลน์สำเร็จ\nไปที่แท่น Override ด้านขวาเพื่ออัปโหลดควบคุมระบบ"
			cctvPrompt.Enabled = false
		elseif doorUnlocked then
			cctvScreen.Color = Color3.fromRGB(55, 195, 245)
			cctvLight.Color = Color3.fromRGB(55, 195, 245)
			cctvHeader.Text = "เครื่องตรวจสอบ CCTV"
			cctvHeader.BackgroundColor3 = Color3.fromRGB(25, 120, 175)
			if useFallback then
				cctvBody.Text = "ONLINE // พบข้อมูลขาดหาย\nกด [E] เพื่อเปิดหน้าต่างเรียงลำดับ"
				cctvPrompt.ActionText = "เปิดหน้าต่างเรียงลำดับ CCTV"
			else
				cctvBody.Text = "ออนไลน์ // เรียงลำดับบนกำแพงจอใหญ่\nกด [E] ที่นี่เพื่อล้างลำดับที่เลือกไว้"
				cctvPrompt.ActionText = "รีเซ็ตลำดับกล้อง CCTV ที่เลือกไว้"
			end
			cctvPrompt.Enabled = true
		else
			cctvScreen.Color = Color3.fromRGB(225, 145, 45)
			cctvLight.Color = Color3.fromRGB(225, 145, 45)
			cctvHeader.Text = "CCTV [ถูกล็อก]"
			cctvHeader.BackgroundColor3 = Color3.fromRGB(165, 95, 25)
			cctvBody.Text = "รอการปลดล็อกประตูห้องควบคุม 102"
			cctvPrompt.Enabled = true
		end

		-- 5. Security Override Console visual state + Hold-Out Upload
		local m1Done = tracker and tracker.getMissionState and (tracker.getMissionState("M1") == "COMPLETED")
		if m1Done then
			overrideScreen.Color = Color3.fromRGB(55, 240, 140)
			overrideLight.Color = Color3.fromRGB(55, 240, 140)
			overrideHeader.Text = "ควบคุมระบบสำเร็จแล้ว"
			overrideHeader.BackgroundColor3 = Color3.fromRGB(35, 155, 90)
			overrideBody.Text = "MISSION 01 เสร็จสมบูรณ์!\nปลดล็อก Tier 1 — ขึ้นชั้น 2 เพื่อกู้คืนไฟฟ้าหลัก"
			overridePrompt.Enabled = false
		elseif currentHoldoutInfo and currentHoldoutInfo.active then
			local pct = math.clamp(math.floor((currentHoldoutInfo.progress or 0) * 100), 0, 100)
			local rem = math.ceil(currentHoldoutInfo.remaining or 0)
			overrideScreen.Color = Color3.fromRGB(255, 165, 45)
			overrideLight.Color = Color3.fromRGB(255, 165, 45)
			overrideHeader.Text = string.format("กำลังอัปโหลด %d%% (%ds)", pct, rem)
			overrideHeader.BackgroundColor3 = Color3.fromRGB(175, 95, 22)
			overrideBody.Text = "Hold-Out! ป้องกันประตูและหน้าต่างห้อง 102 อย่าให้ซอมบี้บุกเข้ามาได้!"
			overridePrompt.Enabled = false
		elseif puzzleSolved then
			overrideScreen.Color = Color3.fromRGB(45, 220, 200)
			overrideLight.Color = Color3.fromRGB(45, 220, 200)
			overrideHeader.Text = "OVERRIDE พร้อมทำงาน"
			overrideHeader.BackgroundColor3 = Color3.fromRGB(25, 145, 130)
			overrideBody.Text = "กด [E] ค้าง เพื่ออัปโหลดควบคุมระบบตึก (ต้องป้องกันห้อง 102 ระหว่างอัปโหลด)"
			overridePrompt.Enabled = true
		else
			overrideScreen.Color = Color3.fromRGB(215, 55, 65)
			overrideLight.Color = Color3.fromRGB(215, 55, 65)
			overrideHeader.Text = "OVERRIDE ถูกล็อก"
			overrideHeader.BackgroundColor3 = Color3.fromRGB(165, 38, 48)
			overrideBody.Text = "เรียงลำดับกล้อง CAM-01..04 ให้ถูกต้องเสียก่อน"
			overridePrompt.Enabled = true
		end

		syncMonitorAndGenerator()
	end

	local safeUnlocked = false
	local safeAnimSeq = 0

	function controller.onResetToM1()
		isDoorOpen = false
		doorBroken = false
		doorHP = MAX_DOOR_HP
		doorModel:SetAttribute("IsBroken", false)
		doorModel:SetAttribute("DoorHP", MAX_DOOR_HP)
		currentHoldoutInfo = nil
		lockerCacheClaimed = false
		refreshMonitorWallClips()
		setDoorOpen(false, true)
		safeAnimSeq = safeAnimSeq + 1
		safeUnlocked = false
		applySafeDoorPose(0, 0, 0)
		keypadLED.Color = Color3.fromRGB(235, 45, 55)
		safeLight.Enabled = false
		revolverLight.Brightness = 0.6
		revolverPrompt.Enabled = false
		safePrompt.Enabled = true
		controller.syncWorldState(true)
	end

	function controller.onDoorUnlockedByDev()
		setDoorOpen(true, false)
		controller.syncWorldState(false)
	end

	function controller.canPlayerInteractWithCCTV(player)
		return verifyDistance(player, cctvBase, cctvPrompt.MaxActivationDistance)
	end

	local function unlockAndOpenSafe()
		if safeUnlocked then return end
		safeUnlocked = true
		safeAnimSeq = safeAnimSeq + 1
		local mySeq = safeAnimSeq

		safePrompt.Enabled = false
		keypadLED.Color = Color3.fromRGB(45, 255, 110) -- Bright Emerald Green (Unlocked)
		safeLight.Brightness = 0.1
		safeLight.Enabled = true

		task.spawn(function()
			-- Wait briefly so client keypad modal closes first and player sees the full animation cleanly
			task.wait(0.42)
			if safeAnimSeq ~= mySeq or not safeUnlocked then return end

			local curWheelDeg = 0
			local curBoltOff = 0
			local curHingeDeg = 0

			-- Stage 1: Spin Vault Wheel (-540 deg)
			local wheelVal = Instance.new("NumberValue")
			wheelVal.Value = 0
			local wheelConn = wheelVal.Changed:Connect(function(v)
				if safeAnimSeq ~= mySeq then return end
				curWheelDeg = v
				applySafeDoorPose(curHingeDeg, curWheelDeg, curBoltOff)
			end)
			local wheelTween = TweenService:Create(wheelVal, TweenInfo.new(0.72, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Value = -540 })
			wheelTween:Play()
			wheelTween.Completed:Wait()
			wheelConn:Disconnect()
			wheelVal:Destroy()
			if safeAnimSeq ~= mySeq or not safeUnlocked then return end

			-- Stage 2: Retract 3 Chrome Locking Bolts inward
			local boltVal = Instance.new("NumberValue")
			boltVal.Value = 0
			local boltConn = boltVal.Changed:Connect(function(v)
				if safeAnimSeq ~= mySeq then return end
				curBoltOff = v
				applySafeDoorPose(curHingeDeg, curWheelDeg, curBoltOff)
			end)
			local boltTween = TweenService:Create(boltVal, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = -0.45 })
			boltTween:Play()
			boltTween.Completed:Wait()
			boltConn:Disconnect()
			boltVal:Destroy()
			if safeAnimSeq ~= mySeq or not safeUnlocked then return end

			-- Stage 3: Swing Heavy Vault Door outward (-112 deg) + warm interior reveal
			safeLight.Brightness = 1.65
			revolverLight.Brightness = 1.35
			revolverPrompt.Enabled = true

			local doorVal = Instance.new("NumberValue")
			doorVal.Value = 0
			local doorConn = doorVal.Changed:Connect(function(v)
				if safeAnimSeq ~= mySeq then return end
				curHingeDeg = v
				applySafeDoorPose(curHingeDeg, curWheelDeg, curBoltOff)
			end)
			local doorTween = TweenService:Create(doorVal, TweenInfo.new(1.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = -112 })
			doorTween:Play()
			doorTween.Completed:Wait()
			doorConn:Disconnect()
			doorVal:Destroy()
		end)
	end

	function controller.verifySafeCode(code)
		if safeUnlocked then
			return true, "ALREADY UNLOCKED"
		end
		if string.upper(tostring(code)) == "B4CA" then
			unlockAndOpenSafe()
			return true, "ACCESS GRANTED"
		else
			return false, "INCORRECT CODE"
		end
	end

	function controller.isBankSafeUnlocked()
		return safeUnlocked
	end

	-- Connect authoritative ProximityPrompt handlers
	safePrompt:SetAttribute("ServerBound", true)
	safePrompt.Triggered:Connect(function(player)
		if safeUnlocked then return end
		if not verifyDistance(player, keypadPlate, safePrompt.MaxActivationDistance) then return end
		if onOpenSafeKeypadForPlayer then
			onOpenSafeKeypadForPlayer(player)
		end
	end)

	keycardPrompt:SetAttribute("ServerBound", true)
	keycardPrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, torso, keycardPrompt.MaxActivationDistance) then return end
		local keyAlreadyPicked = (keyItemService and keyItemService.isWorldPicked("SecurityKeycard"))
			or (tracker and tracker.hasTeamQuestItem and tracker.hasTeamQuestItem("SecurityKeycard"))
			or (tracker and tracker.isSecurityDoorUnlocked and tracker.isSecurityDoorUnlocked())
		if keyAlreadyPicked then return end

		local okLock = tracker.acquireInteractionLock("M1_KEYCARD", player.UserId, 1.0)
		if okLock then
			local ok, msg = tracker.collectKeycard(player.UserId, player.Name)
			tracker.releaseInteractionLock("M1_KEYCARD", player.UserId)
			controller.syncWorldState(false)
			if onStateChanged then onStateChanged(ok, msg, player) end
		end
	end)

	local revolverClaimed = false
	revolverPrompt:SetAttribute("ServerBound", true)
	revolverPrompt.Triggered:Connect(function(player)
		if revolverClaimed then return end
		if not verifyDistance(player, revolverFrame, revolverPrompt.MaxActivationDistance) then return end
		local weaponSignals = ServerStorage:FindFirstChild("WeaponSignals")
		local grantWeapon = weaponSignals and weaponSignals:FindFirstChild("GrantWeapon")
		if not (grantWeapon and grantWeapon:IsA("BindableEvent")) then
			if onPlayerNotice then onPlayerNotice(player, false, "ระบบอาวุธกำลังโหลด กรุณาลองอีกครั้ง") end
			return
		end

		revolverClaimed = true
		revolverPrompt.Enabled = false
		revolverLight.Enabled = false
		for _, p in ipairs(revolverParts) do
			p.Transparency = 1
		end

		grantWeapon:Fire(player, "Sheriff")
		local survFolder = ReplicatedStorage:FindFirstChild("SurvivalFeedbackEvents")
		local survEvent = survFolder and survFolder:FindFirstChild("SurvivalFeedback")
		if survEvent and survEvent:IsA("RemoteEvent") then
			survEvent:FireClient(player, "WeaponFound", "ได้รับปืนพกลูกโม่ผู้จัดการ: Sheriff (กด [3] เก็บปืนเพื่อวิ่งไว)")
		end
		if onStateChanged then
			onStateChanged(true, "ได้รับปืนพกลูกโม่ผู้จัดการสาขา [Sheriff] แล้ว!", player)
		end
	end)

	mgrNotePrompt:SetAttribute("ServerBound", true)
	mgrNotePrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, mgrNotePad, mgrNotePrompt.MaxActivationDistance) then return end
		local noteBody = table.concat({
			"ผู้จัดการสาขา พัชรี ส. (บันทึกสุดท้าย):",
			"โถงธนาคารด้านนอกถูกฝูงผู้ติดเชื้อบุกเข้ามาแล้ว ฉันล็อกประตูห้องผู้จัดการไว้ได้ทันและใช้ปืนประจำตัวยื้อแนวประตูจนกระสุนเกือบหมด",
			"คีย์การ์ดรักษาความปลอดภัยอาคาร 40 อยู่ที่โต๊ะนี้ — เอาไปเปิดห้องควบคุม CCTV (Room 102) ที่ด้านหน้าตึกฝั่งตรงข้าม!",
		}, "\n")
		if tracker.addPhoneNote then
			tracker.addPhoneNote({
				id = "NOTE_M1_MANAGER_LAST_STAND",
				title = "บันทึกผู้จัดการสาขา // พัชรี ส.",
				category = "สืบสวนเหตุการณ์",
				missionId = "M1",
				floor = 1,
				discoveredBy = player.Name,
				body = noteBody,
			})
		end
		if onShowEmergencyMemoForPlayer then
			onShowEmergencyMemoForPlayer(player)
		end
		if onStateChanged then
			onStateChanged(true, "บันทึกโน้ตผู้จัดการลงสมุดในโทรศัพท์เจ้าหน้าที่แล้ว", player)
		elseif onPlayerNotice then
			onPlayerNotice(player, true, noteBody)
		end
	end)

	local function handleClueInspect(player, part, clueIndex, maxDist)
		if not verifyDistance(player, part, maxDist) then return end
		local clues = puzzleEngine.getClues()
		local c = clues[clueIndex]
		if c then
			if tracker.addPhoneNote then
				tracker.addPhoneNote({
					id = "NOTE_M1_CLUE_" .. tostring(clueIndex) .. "_" .. tostring(puzzleEngine.getVariantId()),
					title = c.title,
					category = "เบาะแส CCTV",
					missionId = "M1",
					floor = 1,
					discoveredBy = player.Name,
					body = c.body,
				})
			end
			if onStateChanged then
				onStateChanged(true, "บันทึกเบาะแสลงโทรศัพท์: " .. c.title, player)
			elseif onPlayerNotice then
				onPlayerNotice(player, true, c.title .. " -> " .. c.body:gsub("\n", " | "))
			end
		end
	end

	mKeyPrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, mKeyBlade, mKeyPrompt.MaxActivationDistance) then return end
		local okLock, lockErr = tracker.acquireInteractionLock("M1_MAINTENANCE_KEY", player.UserId, 1.0)
		if not okLock then
			if onPlayerNotice then onPlayerNotice(player, false, lockErr) end
			return
		end
		local ok, msg = tracker.collectMaintenanceKey(player.UserId, player.Name)
		tracker.releaseInteractionLock("M1_MAINTENANCE_KEY", player.UserId)
		controller.syncWorldState(false)
		if onStateChanged then onStateChanged(ok, msg, player) end
	end)

	lockerPrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, lockerDoor, lockerPrompt.MaxActivationDistance) then return end
		if doorAccessService and not doorAccessService.isUnlocked("M1_SERVICE_LOCKER") then
			local dOk, dMsg = doorAccessService.attemptAccess("M1_SERVICE_LOCKER", {
				userId = player.UserId,
				playerName = player.Name,
				devBypass = (player:GetAttribute("DevModeActive") == true and player:GetAttribute("DevBypassLocks") == true),
			}, { toggleIfUnlocked = false })
			controller.syncWorldState(false)
			if not dOk then
				if onPlayerNotice then onPlayerNotice(player, false, dMsg) end
				return
			end
			if onStateChanged then onStateChanged(true, dMsg .. " — เปิดตู้ช่างซ่อมบำรุงแล้ว!", player) end
			return
		end

		if not lockerCacheClaimed then
			lockerCacheClaimed = true
			if tracker.addPhoneNote then
				tracker.addPhoneNote({
					id = "NOTE_F1_MAINTENANCE_CACHE",
					title = "บันทึกตู้ซ่อมบำรุง: ระเบียบการใช้ลิฟต์",
					category = "สืบสวนเหตุการณ์",
					missionId = "M1",
					floor = 1,
					discoveredBy = player.Name,
					body = "ลิฟต์อาคาร 40 หยุดทำงานเมื่อไฟหลักดับ คีย์การ์ด รปภ. ให้สิทธิ์ Tier 1 สำหรับโซนชั้นล่าง ส่วนชั้นกักกัน F11 ต้องใช้ Tier 3",
				})
			end
			if deps.onSupplyCacheClaimed then
				pcall(deps.onSupplyCacheClaimed, player)
			end
			controller.syncWorldState(false)
			if onStateChanged then onStateChanged(true, "เก็บแบตเตอรี่สำรองและบันทึกการใช้ลิฟต์เข้าโทรศัพท์เจ้าหน้าที่แล้ว", player) end
		end
	end)

	clue1Prompt.Triggered:Connect(function(player)
		handleClueInspect(player, clue1Board, 1, clue1Prompt.MaxActivationDistance)
	end)

	clue2Prompt.Triggered:Connect(function(player)
		handleClueInspect(player, clue2Board, 2, clue2Prompt.MaxActivationDistance)
	end)

	local function handleDoorInteract(player, originPart, maxDist)
		if not verifyDistance(player, originPart, maxDist) then return end
		local okLock, lockErr = tracker.acquireInteractionLock("M1_DOOR", player.UserId, 0.8)
		if not okLock then
			if onPlayerNotice then onPlayerNotice(player, false, lockErr) end
			return
		end

		if not tracker.isSecurityDoorUnlocked() then
			local ok, msg = tracker.unlockSecurityDoor(player.UserId, player.Name)
			tracker.releaseInteractionLock("M1_DOOR", player.UserId)
			if ok then
				setDoorOpen(true, false)
				controller.syncWorldState(false)
				if onStateChanged then onStateChanged(true, msg, player) end
			else
				if onPlayerNotice then onPlayerNotice(player, false, msg) end
			end
		elseif doorBroken then
			doorBroken = false
			doorHP = MAX_DOOR_HP
			doorModel:SetAttribute("IsBroken", false)
			doorModel:SetAttribute("DoorHP", doorHP)
			setDoorOpen(false, false)
			controller.syncWorldState(false)
			tracker.releaseInteractionLock("M1_DOOR", player.UserId)
			if onPlayerNotice then onPlayerNotice(player, true, "ซ่อมและปิดประตูห้องควบคุม 102 แล้ว!") end
		else
			setDoorOpen(not isDoorOpen, false)
			controller.syncWorldState(false)
			tracker.releaseInteractionLock("M1_DOOR", player.UserId)
		end
	end

	doorPrompt.Triggered:Connect(function(player)
		handleDoorInteract(player, readerBox, doorPrompt.MaxActivationDistance)
	end)

	interiorDoorPrompt.Triggered:Connect(function(player)
		handleDoorInteract(player, interiorBox, interiorDoorPrompt.MaxActivationDistance)
	end)

	guardNotePrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, guardBook, guardNotePrompt.MaxActivationDistance) then return end
		if onOpenGuardNoteForPlayer then
			onOpenGuardNoteForPlayer(player)
		end
	end)

	for _, mon in pairs(camMonitors) do
		mon.prompt.Triggered:Connect(function(player)
			if not verifyDistance(player, mon.screen, mon.prompt.MaxActivationDistance) then return end
			local canOpen, err = tracker.canAccessCCTVTerminal()
			if not canOpen then
				if onPlayerNotice then onPlayerNotice(player, false, err) end
				return
			end
			if onMonitorWallSelect then
				onMonitorWallSelect(player, mon.clip.clipId, mon.slot)
			end
		end)
	end

	cctvPrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, cctvBase, cctvPrompt.MaxActivationDistance) then return end
		local canOpen, err = tracker.canAccessCCTVTerminal()
		if not canOpen then
			if onPlayerNotice then onPlayerNotice(player, false, err) end
			return
		end
		local useFallback = (MissionConfig.ROOM102 and MissionConfig.ROOM102.USE_MODAL_PUZZLE_FALLBACK) == true
		if useFallback then
			if onOpenPuzzleForPlayer then
				onOpenPuzzleForPlayer(player)
			end
		elseif onMonitorWallSelect then
			onMonitorWallSelect(player, "__RESET__", 0)
		end
	end)

	overridePrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, overrideBase, overridePrompt.MaxActivationDistance) then return end
		if onStartOverrideHoldout then
			onStartOverrideHoldout(player)
		else
			local okLock, lockErr = tracker.acquireInteractionLock("M1_OVERRIDE", player.UserId, 1.2)
			if not okLock then
				if onPlayerNotice then onPlayerNotice(player, false, lockErr) end
				return
			end
			local ok, msg = tracker.activateSecurityControl(player.UserId, player.Name)
			tracker.releaseInteractionLock("M1_OVERRIDE", player.UserId)
			controller.syncWorldState(false)
			if ok then
				if onStateChanged then onStateChanged(true, msg, player) end
			else
				if onPlayerNotice then onPlayerNotice(player, false, msg) end
			end
		end
	end)

	genPrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, genBody, genPrompt.MaxActivationDistance) then return end
		if onRestorePowerTriggered then
			onRestorePowerTriggered(player)
		end
	end)

	controller.syncWorldState(true)
	return controller
end

function MissionWorldInteractables.ensureSafeAndCorpse()
	local root = Workspace:FindFirstChild(MODEL_ROOT_NAME)
	if not root then
		return
	end

	-- Ensure MissionEvents remotes exist idempotently
	local missionEvents = ReplicatedStorage:FindFirstChild("MissionEvents")
	if not missionEvents then
		missionEvents = Instance.new("Folder")
		missionEvents.Name = "MissionEvents"
		missionEvents.Parent = ReplicatedStorage
	end

	local openSafeRemote = missionEvents:FindFirstChild("OpenBankSafeKeypad")
	if not openSafeRemote then
		openSafeRemote = Instance.new("RemoteEvent")
		openSafeRemote.Name = "OpenBankSafeKeypad"
		openSafeRemote.Parent = missionEvents
	end

	local showMemoRemote = missionEvents:FindFirstChild("ShowEmergencyMemo")
	if not showMemoRemote then
		showMemoRemote = Instance.new("RemoteEvent")
		showMemoRemote.Name = "ShowEmergencyMemo"
		showMemoRemote.Parent = missionEvents
	end

	local safe = root:FindFirstChild("M1_BankVaultSafe")
	if safe then
		local plate = safe:FindFirstChild("SafeKeypadPlate")
		local prompt = plate and plate:FindFirstChildOfClass("ProximityPrompt")
		if prompt and not prompt:GetAttribute("ServerBound") then
			prompt:SetAttribute("ServerBound", true)
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 12.0
			prompt.RequiresLineOfSight = false
			prompt.ActionText = "ใส่รหัสตู้เซฟ [HEX] (Enter Code)"
			prompt.ObjectText = "ตู้เซฟผู้จัดการธนาคาร (Manager Safe)"
			prompt.Triggered:Connect(function(player)
				if openSafeRemote then
					openSafeRemote:FireClient(player)
				end
			end)
		end
	end

	local note = root:FindFirstChild("M1_ManagerOfficeNote")
	local pad = note and note:FindFirstChild("ManagerMemoPad")
	local notePrompt = pad and pad:FindFirstChildOfClass("ProximityPrompt")
	if notePrompt and not notePrompt:GetAttribute("ServerBound") then
		notePrompt:SetAttribute("ServerBound", true)
		notePrompt.HoldDuration = 0
		notePrompt.MaxActivationDistance = 12.0
		notePrompt.RequiresLineOfSight = false
		notePrompt.ActionText = "อ่านบันทึกรหัสฉุกเฉิน (Inspect Memo)"
		notePrompt.ObjectText = "สมุดบันทึกฉุกเฉินผู้จัดการสาขา"
		notePrompt.Triggered:Connect(function(player)
			if showMemoRemote then
				showMemoRemote:FireClient(player)
			end
		end)
	end

	local corpse = root:FindFirstChild("M1_BranchManagerCorpse")
	local torso = corpse and corpse:FindFirstChild("CorpseTorso")
	local corpsePrompt = torso and torso:FindFirstChildOfClass("ProximityPrompt")
	if corpsePrompt then
		corpsePrompt.MaxActivationDistance = 12.0
		corpsePrompt.RequiresLineOfSight = false
	end
end

return MissionWorldInteractables
