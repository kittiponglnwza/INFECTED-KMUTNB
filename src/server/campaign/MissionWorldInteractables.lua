-- Builds and synchronizes server-owned interactive Mission 01 objects in Building 40 F1:
--   1. M1_KeycardPickup, M1_ManagerRevolverPickup & M1_ManagerOfficeNote (F1 Bangkok Bank Manager's Office)
--   2. M1_ClueBoard_Atrium & M1_ClueMemo_Room102 (Environmental Timeline Clues synced to active variant)
--   3. M1_SecurityRoomDoor (Room 102 Keycard-locked hinged bulkhead door)
--   4. M1_CCTVTerminal (Room 102 Left Desk -> opens server-validated Timeline modal)
--   5. M1_SecurityOverrideConsole (Room 102 Right Desk -> completes M1 and unlocks M2 [NOT IMPLEMENTED])

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

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
	local onPlayerNotice = deps.onPlayerNotice
	local floorY = deps.floorY or 1.0

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
	keycardPrompt.ActionText = "ค้นตัวผู้จัดการ (Search Corpse)"
	keycardPrompt.ObjectText = "ร่างของพัชรี ส. (Branch Manager Corpse)"
	keycardPrompt.KeyboardKeyCode = Enum.KeyCode.E
	keycardPrompt.HoldDuration = 0.4
	keycardPrompt.MaxActivationDistance = 9.0
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

	local safeBaseCF = CFrame.new(129.5, floorY + 2.6, 56.5)
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

	-- Hinged Safe Door
	local hingeCF = CFrame.new(127.7, floorY + 2.6, 58.3)
	local doorHinge = Instance.new("Part")
	doorHinge.Name = "SafeDoorHinge"
	doorHinge.Size = Vector3.new(0.3, 4.6, 0.3)
	doorHinge.CFrame = hingeCF
	doorHinge.Color = safeSteelDark
	doorHinge.Material = Enum.Material.Metal
	doorHinge.Anchored = true
	doorHinge.CanCollide = false
	doorHinge.Parent = safeModel

	local doorLeaf = Instance.new("Part")
	doorLeaf.Name = "SafeDoorLeaf"
	doorLeaf.Size = Vector3.new(3.5, 4.4, 0.4)
	doorLeaf.CFrame = hingeCF * CFrame.new(1.75, 0, 0)
	doorLeaf.Color = Color3.fromRGB(42, 48, 58)
	doorLeaf.Material = Enum.Material.Metal
	doorLeaf.Anchored = true
	doorLeaf.CanCollide = false
	doorLeaf.Parent = safeModel

	-- Vault Wheel on Door
	local doorWheel = Instance.new("Part")
	doorWheel.Name = "SafeWheel"
	doorWheel.Size = Vector3.new(1.1, 1.1, 0.25)
	doorWheel.CFrame = doorLeaf.CFrame * CFrame.new(-0.5, 0, 0.3)
	doorWheel.Color = safeGold
	doorWheel.Material = Enum.Material.Metal
	doorWheel.Anchored = true
	doorWheel.CanCollide = false
	doorWheel.Parent = safeModel

	-- Digital Keypad on Door
	local keypadPlate = Instance.new("Part")
	keypadPlate.Name = "SafeKeypadPlate"
	keypadPlate.Size = Vector3.new(0.95, 1.4, 0.2)
	keypadPlate.CFrame = doorLeaf.CFrame * CFrame.new(0.65, 0.4, 0.28)
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

	-- Relative CFrames from hinge for smooth rotation
	local relLeaf = hingeCF:ToObjectSpace(doorLeaf.CFrame)
	local relWheel = hingeCF:ToObjectSpace(doorWheel.CFrame)
	local relKeypad = hingeCF:ToObjectSpace(keypadPlate.CFrame)
	local relLED = hingeCF:ToObjectSpace(keypadLED.CFrame)

	local safePrompt = Instance.new("ProximityPrompt")
	safePrompt.Name = "SafeKeypadPrompt"
	safePrompt.ActionText = "ใส่รหัสตู้เซฟ [HEX] (Enter Code)"
	safePrompt.ObjectText = "ตู้เซฟผู้จัดการธนาคาร (Manager Safe)"
	safePrompt.KeyboardKeyCode = Enum.KeyCode.E
	safePrompt.HoldDuration = 0
	safePrompt.MaxActivationDistance = 11.0
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
	revolverPrompt.MaxActivationDistance = 9.0
	revolverPrompt.RequiresLineOfSight = false
	revolverPrompt.Enabled = false -- Locked until safe is decoded
	revolverPrompt.Parent = revolverFrame

	-- 1A-3. Manager's Final Log (Last Stand narrative note on desk)
	local mgrNoteModel = Instance.new("Model")
	mgrNoteModel.Name = "M1_ManagerOfficeNote"
	mgrNoteModel.Parent = root

	local mgrNotePad = makePart(mgrNoteModel, "ManagerMemoPad", Vector3.new(1.3, 0.08, 1.65),
		CFrame.new(135.4, floorY + 3.69, 54.6) * CFrame.Angles(0, math.rad(-9), 0), Color3.fromRGB(238, 234, 220), Enum.Material.SmoothPlastic, { CanCollide = false })
	makePart(mgrNoteModel, "ManagerMemoClip", Vector3.new(0.7, 0.1, 0.22),
		CFrame.new(135.3, floorY + 3.74, 53.88) * CFrame.Angles(0, math.rad(-9), 0), Color3.fromRGB(64, 70, 78), Enum.Material.Metal, { CanCollide = false })
	local mgrNotePrompt = Instance.new("ProximityPrompt")
	mgrNotePrompt.Name = "ManagerNotePrompt"
	mgrNotePrompt.ActionText = "อ่านบันทึกรหัสฉุกเฉิน (Inspect Memo)"
	mgrNotePrompt.ObjectText = "สมุดบันทึกฉุกเฉินผู้จัดการสาขา"
	mgrNotePrompt.KeyboardKeyCode = Enum.KeyCode.E
	mgrNotePrompt.HoldDuration = 0
	mgrNotePrompt.MaxActivationDistance = 9.0
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
	mKeyPrompt.ActionText = "Pick up Maintenance Key"
	mKeyPrompt.ObjectText = "Stamped Brass Key (F1)"
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
	lockerPrompt.ActionText = "Unlock Maintenance Locker"
	lockerPrompt.ObjectText = "F1 Maintenance Supply Locker"
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
	clue1Light.Parent = clue1Board
	local clue1Header, clue1Body = makeSurfacePanel(clue1Board, Enum.NormalId.Front, "INCIDENT LOG", "Loading...", Color3.fromRGB(16, 20, 28), Color3.fromRGB(175, 42, 52))

	local clue1Prompt = Instance.new("ProximityPrompt")
	clue1Prompt.Name = "InspectClue1Prompt"
	clue1Prompt.ActionText = "Inspect Incident Log"
	clue1Prompt.ObjectText = "F1 Security Logbook"
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
	clue2Light.Parent = clue2Board
	local clue2Header, clue2Body = makeSurfacePanel(clue2Board, Enum.NormalId.Front, "TECH MEMO", "Loading...", Color3.fromRGB(14, 22, 30), Color3.fromRGB(38, 120, 175))

	local clue2Prompt = Instance.new("ProximityPrompt")
	clue2Prompt.Name = "InspectClue2Prompt"
	clue2Prompt.ActionText = "Read Corridor Security Memo"
	clue2Prompt.ObjectText = "Room 102 Tech Note"
	clue2Prompt.KeyboardKeyCode = Enum.KeyCode.E
	clue2Prompt.HoldDuration = 0
	clue2Prompt.MaxActivationDistance = 9
	clue2Prompt.RequiresLineOfSight = false
	clue2Prompt.Parent = clue2Board

	-- 3. Room 102 Hinged Keycard-Locked Security Door (X = -109, Z = 45.0, width = 8, height = 11)
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
	makePart(doorModel, "InteriorReleaseBox", Vector3.new(0.95, 1.4, 0.35),
		CFrame.new(-104.2, floorY + 4.8, 46.25), Color3.fromRGB(34, 40, 48), Enum.Material.Metal)
	local interiorLED = makePart(doorModel, "InteriorReleaseLED", Vector3.new(0.55, 0.35, 0.14),
		CFrame.new(-104.2, floorY + 5.1, 46.46), Color3.fromRGB(225, 50, 60), Enum.Material.Neon, { CanCollide = false })
	local readerLight = Instance.new("PointLight")
	readerLight.Color = Color3.fromRGB(225, 50, 60)
	readerLight.Range = 11
	readerLight.Brightness = 1.4
	readerLight.Parent = readerLED

	local doorPrompt = Instance.new("ProximityPrompt")
	doorPrompt.Name = "SecurityDoorPrompt"
	doorPrompt.ActionText = "Unlock Security Room (Keycard)"
	doorPrompt.ObjectText = "Room 102 Keycard Reader"
	doorPrompt.KeyboardKeyCode = Enum.KeyCode.E
	doorPrompt.HoldDuration = 0.35
	doorPrompt.MaxActivationDistance = 10
	doorPrompt.RequiresLineOfSight = false
	doorPrompt.Parent = readerBox

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

	local isDoorOpen = false
	local function setDoorOpen(openState, immediate)
		isDoorOpen = openState
		local targetAngle = openState and -92 or 0
		if immediate then
			doorAngleVal.Value = targetAngle
		else
			TweenService:Create(doorAngleVal, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = targetAngle }):Play()
		end
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
	cctvLight.Parent = cctvScreen
	local cctvHeader, cctvBody = makeSurfacePanel(cctvScreen, Enum.NormalId.Front, "CCTV TERMINAL", "LOCKED\nUnlock Room 102 first", Color3.fromRGB(10, 22, 32), Color3.fromRGB(22, 115, 165))

	local cctvPrompt = Instance.new("ProximityPrompt")
	cctvPrompt.Name = "CCTVTerminalPrompt"
	cctvPrompt.ActionText = "Open CCTV Timeline Terminal"
	cctvPrompt.ObjectText = "Room 102 CCTV Server"
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
	overrideLight.Parent = overrideScreen
	local overrideHeader, overrideBody = makeSurfacePanel(overrideScreen, Enum.NormalId.Front, "SECURITY OVERRIDE", "LOCKED\nSolve CCTV Timeline first", Color3.fromRGB(24, 14, 18), Color3.fromRGB(165, 38, 48))

	local overridePrompt = Instance.new("ProximityPrompt")
	overridePrompt.Name = "OverrideConsolePrompt"
	overridePrompt.ActionText = "Activate Security Override"
	overridePrompt.ObjectText = "Building 40 Security System"
	overridePrompt.KeyboardKeyCode = Enum.KeyCode.E
	overridePrompt.HoldDuration = 0.65
	overridePrompt.MaxActivationDistance = 10
	overridePrompt.RequiresLineOfSight = false
	overridePrompt.Parent = overrideBase

	-- Sync world visuals with authoritative tracker + puzzle state
	local controller = {}

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
		keycardPrompt.Enabled = not keyPicked

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
				lockerPrompt.ActionText = "Take Emergency Battery & Note"
			end
		else
			lockerLED.Color = Color3.fromRGB(220, 60, 60)
			lockerDoor.CFrame = CFrame.new(-82, floorY + 3.5, -40.9)
			lockerPrompt.Enabled = true
			lockerPrompt.ActionText = "Unlock Maintenance Locker (Key)"
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

		-- 3. Room 102 Door lock & LED state
		local doorUnlocked = tracker and tracker.isSecurityDoorUnlocked and tracker.isSecurityDoorUnlocked()
		if doorUnlocked then
			readerLED.Color = Color3.fromRGB(55, 235, 130)
			interiorLED.Color = Color3.fromRGB(55, 235, 130)
			readerLight.Color = Color3.fromRGB(55, 235, 130)
			doorPrompt.ActionText = isDoorOpen and "Close Security Door" or "Open Security Door"
			doorPrompt.HoldDuration = 0.15
		else
			readerLED.Color = Color3.fromRGB(225, 50, 60)
			interiorLED.Color = Color3.fromRGB(225, 50, 60)
			readerLight.Color = Color3.fromRGB(225, 50, 60)
			doorPrompt.ActionText = "Unlock Security Room (Keycard)"
			doorPrompt.HoldDuration = 0.35
			setDoorOpen(false, immediateDoor == true)
		end

		-- 4. CCTV Terminal visual state
		local puzzleSolved = puzzleEngine and puzzleEngine.isSolved and puzzleEngine.isSolved()
		if puzzleSolved then
			cctvScreen.Color = Color3.fromRGB(55, 225, 130)
			cctvLight.Color = Color3.fromRGB(55, 225, 130)
			cctvHeader.Text = "CCTV TIMELINE VERIFIED"
			cctvHeader.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
			cctvBody.Text = "Sequence validated.\nProceed to Security Override Console on the right."
			cctvPrompt.Enabled = false
		elseif doorUnlocked then
			cctvScreen.Color = Color3.fromRGB(55, 195, 245)
			cctvLight.Color = Color3.fromRGB(55, 195, 245)
			cctvHeader.Text = "CCTV TIMELINE TERMINAL"
			cctvHeader.BackgroundColor3 = Color3.fromRGB(25, 120, 175)
			cctvBody.Text = "ONLINE // CORRUPT LOG DETECTED\nPress [E] to reconstruct timeline."
			cctvPrompt.Enabled = true
		else
			cctvScreen.Color = Color3.fromRGB(225, 145, 45)
			cctvLight.Color = Color3.fromRGB(225, 145, 45)
			cctvHeader.Text = "CCTV TERMINAL [LOCKED]"
			cctvHeader.BackgroundColor3 = Color3.fromRGB(165, 95, 25)
			cctvBody.Text = "Awaiting Room 102 access authorization."
			cctvPrompt.Enabled = true
		end

		-- 5. Security Override Console visual state
		local m1Done = tracker and tracker.getMissionState and (tracker.getMissionState("M1") == "COMPLETED")
		if m1Done then
			overrideScreen.Color = Color3.fromRGB(55, 240, 140)
			overrideLight.Color = Color3.fromRGB(55, 240, 140)
			overrideHeader.Text = "SECURITY CONTROL ONLINE"
			overrideHeader.BackgroundColor3 = Color3.fromRGB(35, 155, 90)
			overrideBody.Text = "MISSION 01 COMPLETED!\nBuilding 40 Floor 1 Security restored."
			overridePrompt.Enabled = false
		elseif puzzleSolved then
			overrideScreen.Color = Color3.fromRGB(45, 220, 200)
			overrideLight.Color = Color3.fromRGB(45, 220, 200)
			overrideHeader.Text = "OVERRIDE READY"
			overrideHeader.BackgroundColor3 = Color3.fromRGB(25, 145, 130)
			overrideBody.Text = "Hold [E] to activate Security Control Override."
			overridePrompt.Enabled = true
		else
			overrideScreen.Color = Color3.fromRGB(215, 55, 65)
			overrideLight.Color = Color3.fromRGB(215, 55, 65)
			overrideHeader.Text = "OVERRIDE LOCKED"
			overrideHeader.BackgroundColor3 = Color3.fromRGB(165, 38, 48)
			overrideBody.Text = "Verify CCTV Timeline on the left terminal first."
			overridePrompt.Enabled = true
		end
	end

	function controller.onResetToM1()
		isDoorOpen = false
		lockerCacheClaimed = false
		setDoorOpen(false, true)
		controller.syncWorldState(true)
	end

	function controller.onDoorUnlockedByDev()
		setDoorOpen(true, false)
		controller.syncWorldState(false)
	end

	function controller.canPlayerInteractWithCCTV(player)
		return verifyDistance(player, cctvBase, cctvPrompt.MaxActivationDistance)
	end

	local safeUnlocked = false
	local function unlockAndOpenSafe()
		if safeUnlocked then return end
		safeUnlocked = true

		safePrompt.Enabled = false
		keypadLED.Color = Color3.fromRGB(45, 235, 75) -- Green (Unlocked)
		safeLight.Enabled = true
		revolverPrompt.Enabled = true

		-- Smooth Tween open 105 degrees pivoting all door parts around hinge
		local numVal = Instance.new("NumberValue")
		numVal.Value = 0
		local tween = TweenService:Create(numVal, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = -105 })
		numVal.Changed:Connect(function(deg)
			local curHinge = hingeCF * CFrame.Angles(0, math.rad(deg), 0)
			doorLeaf.CFrame = curHinge * relLeaf
			doorWheel.CFrame = curHinge * relWheel
			keypadPlate.CFrame = curHinge * relKeypad
			keypadLED.CFrame = curHinge * relLED
		end)
		tween:Play()
		tween.Completed:Connect(function()
			numVal:Destroy()
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
	safePrompt.Triggered:Connect(function(player)
		if safeUnlocked then return end
		if not verifyDistance(player, keypadPlate, safePrompt.MaxActivationDistance) then return end
		if onOpenSafeKeypadForPlayer then
			onOpenSafeKeypadForPlayer(player)
		end
	end)

	keycardPrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, torso, keycardPrompt.MaxActivationDistance) then return end
		local okLock, lockErr = tracker.acquireInteractionLock("M1_KEYCARD", player.UserId, 1.0)
		if not okLock then
			if onPlayerNotice then onPlayerNotice(player, false, lockErr) end
			return
		end
		local ok, msg = tracker.collectKeycard(player.UserId, player.Name)
		tracker.releaseInteractionLock("M1_KEYCARD", player.UserId)
		controller.syncWorldState(false)
		if onStateChanged then onStateChanged(ok, msg, player) end

		-- Show emergency memo popup with Binary puzzle to the player searching the corpse
		if onShowEmergencyMemoForPlayer then
			onShowEmergencyMemoForPlayer(player)
		end
	end)

	local revolverClaimed = false
	revolverPrompt.Triggered:Connect(function(player)
		if revolverClaimed then return end
		if not verifyDistance(player, revolverFrame, revolverPrompt.MaxActivationDistance) then return end
		local weaponSignals = ServerStorage:FindFirstChild("WeaponSignals")
		local grantWeapon = weaponSignals and weaponSignals:FindFirstChild("GrantWeapon")
		if not (grantWeapon and grantWeapon:IsA("BindableEvent")) then
			if onPlayerNotice then onPlayerNotice(player, false, "Weapon system still initializing — try again.") end
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
			onStateChanged(true, "Equipped Branch Manager's Service Revolver [Sheriff]!", player)
		end
	end)

	mgrNotePrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, mgrNotePad, mgrNotePrompt.MaxActivationDistance) then return end
		local noteBody = table.concat({
			"ผู้จัดการสาขา พัชรี ส. (Bank Manager Last Log):",
			"โถงธนาคารด้านนอกถูกฝูงผู้ติดเชื้อบุกเข้ามาแล้ว ฉันล็อกประตูห้องผู้จัดการไว้ได้ทันและใช้ปืนประจำตัวยื้อแนวประตูจนกระสุนเกือบหมด",
			"คีย์การ์ดรักษาความปลอดภัยอาคาร 40 อยู่ที่โต๊ะนี้ — เอาไปเปิดห้องควบคุม CCTV (Room 102) ที่ด้านหน้าตึกฝั่งตรงข้าม!",
		}, "\n")
		if tracker.addPhoneNote then
			tracker.addPhoneNote({
				id = "NOTE_M1_MANAGER_LAST_STAND",
				title = "BRANCH MANAGER LOG // PHATCHAREE S.",
				category = "Investigation",
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
			onStateChanged(true, "Saved Branch Manager's Final Log to Staff Phone Notes!", player)
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
					category = "CCTV Clue",
					missionId = "M1",
					floor = 1,
					discoveredBy = player.Name,
					body = c.body,
				})
			end
			if onStateChanged then
				onStateChanged(true, "Saved to Staff Phone Notes: " .. c.title, player)
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
			if onStateChanged then onStateChanged(true, dMsg .. " — Locker unsealed!", player) end
			return
		end

		if not lockerCacheClaimed then
			lockerCacheClaimed = true
			if tracker.addPhoneNote then
				tracker.addPhoneNote({
					id = "NOTE_F1_MAINTENANCE_CACHE",
					title = "Maintenance Locker Memo: Elevator Protocol",
					category = "Investigation",
					missionId = "M1",
					floor = 1,
					discoveredBy = player.Name,
					body = "Building 40 elevators shut down on emergency blackout. Security Keycards carry Tier 1 lower-floor access; Quarantine Wing F11 requires Tier 3.",
				})
			end
			if deps.onSupplyCacheClaimed then
				pcall(deps.onSupplyCacheClaimed, player)
			end
			controller.syncWorldState(false)
			if onStateChanged then onStateChanged(true, "Claimed emergency battery & saved Elevator Protocol Note to Staff Phone.", player) end
		end
	end)

	clue1Prompt.Triggered:Connect(function(player)
		handleClueInspect(player, clue1Board, 1, clue1Prompt.MaxActivationDistance)
	end)

	clue2Prompt.Triggered:Connect(function(player)
		handleClueInspect(player, clue2Board, 2, clue2Prompt.MaxActivationDistance)
	end)

	doorPrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, readerBox, doorPrompt.MaxActivationDistance) then return end
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
		else
			setDoorOpen(not isDoorOpen, false)
			controller.syncWorldState(false)
			tracker.releaseInteractionLock("M1_DOOR", player.UserId)
		end
	end)

	cctvPrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, cctvBase, cctvPrompt.MaxActivationDistance) then return end
		local canOpen, err = tracker.canAccessCCTVTerminal()
		if not canOpen then
			if onPlayerNotice then onPlayerNotice(player, false, err) end
			return
		end
		if onOpenPuzzleForPlayer then
			onOpenPuzzleForPlayer(player)
		end
	end)

	overridePrompt.Triggered:Connect(function(player)
		if not verifyDistance(player, overrideBase, overridePrompt.MaxActivationDistance) then return end
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
	end)

	controller.syncWorldState(true)
	return controller
end

function MissionWorldInteractables.ensureSafeAndCorpse()
	local root = Workspace:FindFirstChild(MODEL_ROOT_NAME)
	if not root then
		return
	end

	local safe = root:FindFirstChild("M1_BankVaultSafe")
	if safe then
		local plate = safe:FindFirstChild("SafeKeypadPlate")
		local prompt = plate and plate:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 12.0
			prompt.RequiresLineOfSight = false
			prompt.ActionText = "ใส่รหัสตู้เซฟ [HEX] (Enter Code)"
			prompt.ObjectText = "ตู้เซฟผู้จัดการธนาคาร (Manager Safe)"
			prompt.Triggered:Connect(function(player)
				local missionEvents = ReplicatedStorage:FindFirstChild("MissionEvents")
				local remote = missionEvents and missionEvents:FindFirstChild("OpenBankSafeKeypad")
				if remote then
					remote:FireClient(player)
				end
			end)
		end
	end

	local note = root:FindFirstChild("M1_ManagerOfficeNote")
	local pad = note and note:FindFirstChild("ManagerMemoPad")
	local notePrompt = pad and pad:FindFirstChildOfClass("ProximityPrompt")
	if notePrompt then
		notePrompt.HoldDuration = 0
		notePrompt.MaxActivationDistance = 11.0
		notePrompt.RequiresLineOfSight = false
		notePrompt.ActionText = "อ่านบันทึกรหัสฉุกเฉิน (Inspect Memo)"
		notePrompt.ObjectText = "สมุดบันทึกฉุกเฉินผู้จัดการสาขา"
		notePrompt.Triggered:Connect(function(player)
			local missionEvents = ReplicatedStorage:FindFirstChild("MissionEvents")
			local remote = missionEvents and missionEvents:FindFirstChild("ShowEmergencyMemo")
			if remote then
				remote:FireClient(player)
			end
		end)
	end

	local corpse = root:FindFirstChild("M1_BranchManagerCorpse")
	local torso = corpse and corpse:FindFirstChild("CorpseTorso")
	local corpsePrompt = torso and torso:FindFirstChildOfClass("ProximityPrompt")
	if corpsePrompt then
		corpsePrompt.HoldDuration = 0
		corpsePrompt.MaxActivationDistance = 11.0
		corpsePrompt.RequiresLineOfSight = false
		corpsePrompt.ActionText = "ค้นตัวผู้จัดการ (Search Corpse)"
		corpsePrompt.ObjectText = "ร่างผู้จัดการ พัชรี ส."
		corpsePrompt.Triggered:Connect(function(player)
			local missionEvents = ReplicatedStorage:FindFirstChild("MissionEvents")
			local remote = missionEvents and missionEvents:FindFirstChild("ShowEmergencyMemo")
			if remote then
				remote:FireClient(player)
			end
		end)
	end

	-- Global ProximityPromptService hook as a fail-safe
	local ProximityPromptService = game:GetService("ProximityPromptService")
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if prompt.Name == "SafeKeypadPrompt" or (prompt.Parent and prompt.Parent.Name == "SafeKeypadPlate") then
			local missionEvents = ReplicatedStorage:FindFirstChild("MissionEvents")
			local remote = missionEvents and missionEvents:FindFirstChild("OpenBankSafeKeypad")
			if remote then
				remote:FireClient(player)
			end
		elseif prompt.Name == "ManagerNotePrompt" or prompt.Name == "KeycardPrompt" then
			local missionEvents = ReplicatedStorage:FindFirstChild("MissionEvents")
			local remote = missionEvents and missionEvents:FindFirstChild("ShowEmergencyMemo")
			if remote then
				remote:FireClient(player)
			end
		end
	end)
end

return MissionWorldInteractables
