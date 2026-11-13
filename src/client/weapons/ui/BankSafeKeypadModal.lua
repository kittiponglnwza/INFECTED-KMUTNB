-- Bank Safe Hex Keypad Modal
-- Provides an interactive terminal keypad (0-9, A-F) for decoding the Bangkok Bank Safe.
-- Full keyboard input support (0-9, A-F, Backspace, Enter, Esc).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local function getUIStateManager()
	if script.Parent:FindFirstChild("UIStateManager") then
		return require(script.Parent.UIStateManager)
	end
	local localPlayer = Players.LocalPlayer
	local ps = localPlayer and (localPlayer:FindFirstChild("PlayerScripts") or localPlayer:WaitForChild("PlayerScripts", 5))
	local cm = ps and (ps:FindFirstChild("ClientModules") or ps:WaitForChild("ClientModules", 5))
	if cm and cm:FindFirstChild("UIStateManager") then
		return require(cm.UIStateManager)
	end
	local StarterPlayer = game:GetService("StarterPlayer")
	local sps = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	local scm = sps and sps:FindFirstChild("ClientModules")
	if scm and scm:FindFirstChild("UIStateManager") then
		return require(scm.UIStateManager)
	end
	return nil
end
local UIStateManager = getUIStateManager()

local BankSafeKeypadModal = {}
local MODAL_ID = "BankSafeKeypadModal"

local screenGui = nil
local backdrop = nil
local keypadFrame = nil
local displayLabel = nil
local statusLabel = nil
local inputBuffer = ""
local isSubmitting = false
local inputConnection = nil

local submitRemoteFn = nil

local function getSubmitRemote()
	if submitRemoteFn then
		return submitRemoteFn
	end
	local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
	local NetProtocol = require(sharedFolder:WaitForChild("NetProtocol"))
	local missionEvents = ReplicatedStorage:WaitForChild(NetProtocol.Remotes.MissionEventsFolder, 30)
	submitRemoteFn = missionEvents and missionEvents:WaitForChild(NetProtocol.Remotes.SubmitBankSafeCode, 10)
	return submitRemoteFn
end

local function updateDisplay()
	if not displayLabel then return end
	if #inputBuffer == 0 then
		displayLabel.Text = "_ _ _ _"
		displayLabel.TextColor3 = Color3.fromRGB(120, 180, 140)
	else
		local chars = {}
		for i = 1, 4 do
			local c = string.sub(inputBuffer, i, i)
			table.insert(chars, c ~= "" and c or "_")
		end
		displayLabel.Text = table.concat(chars, "  ")
		displayLabel.TextColor3 = Color3.fromRGB(80, 255, 150)
	end
end

local function appendChar(char)
	if isSubmitting then return end
	if #inputBuffer < 4 then
		inputBuffer = inputBuffer .. string.upper(char)
		updateDisplay()
		if statusLabel then
			statusLabel.Text = "INPUT REQUIRED: 4-HEX PIN"
			statusLabel.TextColor3 = Color3.fromRGB(150, 175, 200)
		end
	end
end

local function backspace()
	if isSubmitting then return end
	if #inputBuffer > 0 then
		inputBuffer = string.sub(inputBuffer, 1, #inputBuffer - 1)
		updateDisplay()
	end
end

local function clearInput()
	if isSubmitting then return end
	inputBuffer = ""
	updateDisplay()
	if statusLabel then
		statusLabel.Text = "ENTER 4-DIGIT HEX CODE (FROM MEMO)"
		statusLabel.TextColor3 = Color3.fromRGB(150, 175, 200)
	end
end

local function submitCode()
	if isSubmitting then return end
	if #inputBuffer ~= 4 then
		if statusLabel then
			statusLabel.Text = "⚠️  CODE MUST BE 4 HEX DIGITS"
			statusLabel.TextColor3 = Color3.fromRGB(255, 175, 75)
		end
		return
	end

	isSubmitting = true
	if statusLabel then
		statusLabel.Text = "VERIFYING CRYPTOGRAPHIC KEY..."
		statusLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	end

	local remote = getSubmitRemote()
	if not remote then
		isSubmitting = false
		if statusLabel then
			statusLabel.Text = "SERVER OFFLINE"
			statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		end
		return
	end

	local success, result = pcall(function()
		return remote:InvokeServer(inputBuffer)
	end)

	if success and result and result.success then
		if displayLabel then
			displayLabel.Text = "[ UNLOCKED ]"
			displayLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
		end
		if statusLabel then
			statusLabel.Text = "✓ ACCESS GRANTED // UNLOCKING SAFE..."
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
		end
		task.delay(0.45, function()
			BankSafeKeypadModal.close()
			isSubmitting = false
		end)
	else
		if displayLabel then
			displayLabel.Text = "[ DENIED ]"
			displayLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		end
		if statusLabel then
			local errMsg = (result and result.message) or "INVALID HEX HASH"
			statusLabel.Text = "✕ " .. errMsg
			statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		end
		task.delay(1.2, function()
			clearInput()
			isSubmitting = false
		end)
	end
end

function BankSafeKeypadModal.mount()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("BankSafeKeypadHUD")
	if old then
		old:Destroy()
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BankSafeKeypadHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 50
	screenGui.Parent = playerGui

	-- Dim Backdrop: Sibling to keypadFrame
	backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(4, 7, 12)
	backdrop.BackgroundTransparency = 0.45
	backdrop.BorderSizePixel = 0
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Modal = true
	backdrop.Visible = false
	backdrop.ZIndex = 1
	backdrop.Parent = screenGui
	backdrop.MouseButton1Click:Connect(BankSafeKeypadModal.close)

	-- Outer Safe Terminal Housing: Sibling to backdrop (ZIndex = 10)
	keypadFrame = Instance.new("Frame")
	keypadFrame.Name = "KeypadFrame"
	keypadFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	keypadFrame.Position = UDim2.fromScale(0.5, 0.5)
	keypadFrame.Size = UDim2.new(0, 420, 0, 520)
	keypadFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	keypadFrame.BorderSizePixel = 0
	keypadFrame.Active = true
	keypadFrame.Visible = false
	keypadFrame.ZIndex = 10
	keypadFrame.Parent = screenGui
	Instance.new("UICorner", keypadFrame).CornerRadius = UDim.new(0, 10)

	local frameStroke = Instance.new("UIStroke", keypadFrame)
	frameStroke.Color = Color3.fromRGB(50, 65, 85)
	frameStroke.Thickness = 2.5

	-- Title Bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 48)
	titleBar.BackgroundColor3 = Color3.fromRGB(26, 32, 44)
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 11
	titleBar.Parent = keypadFrame
	Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Position = UDim2.new(0, 16, 0, 0)
	titleLabel.Size = UDim2.new(1, -90, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.TextColor3 = Color3.fromRGB(220, 230, 245)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "SECURE VAULT TERMINAL // HEX 16-BIT"
	titleLabel.ZIndex = 12
	titleLabel.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -12, 0.5, 0)
	closeBtn.Size = UDim2.new(0, 68, 0, 30)
	closeBtn.BackgroundColor3 = Color3.fromRGB(165, 42, 48)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 12
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "CLOSE [✕]"
	closeBtn.ZIndex = 13
	closeBtn.Parent = titleBar
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
	closeBtn.MouseButton1Click:Connect(BankSafeKeypadModal.close)

	-- Digital LCD Display Screen
	local displayContainer = Instance.new("Frame")
	displayContainer.Position = UDim2.new(0, 18, 0, 58)
	displayContainer.Size = UDim2.new(1, -36, 0, 78)
	displayContainer.BackgroundColor3 = Color3.fromRGB(8, 14, 12)
	displayContainer.BorderSizePixel = 0
	displayContainer.ZIndex = 11
	displayContainer.Parent = keypadFrame
	Instance.new("UICorner", displayContainer).CornerRadius = UDim.new(0, 8)

	local dispStroke = Instance.new("UIStroke", displayContainer)
	dispStroke.Color = Color3.fromRGB(30, 75, 45)
	dispStroke.Thickness = 1.5

	displayLabel = Instance.new("TextLabel")
	displayLabel.Position = UDim2.new(0, 0, 0, 8)
	displayLabel.Size = UDim2.new(1, 0, 0, 42)
	displayLabel.BackgroundTransparency = 1
	displayLabel.Font = Enum.Font.Code
	displayLabel.TextSize = 28
	displayLabel.TextColor3 = Color3.fromRGB(80, 255, 150)
	displayLabel.Text = "_ _ _ _"
	displayLabel.ZIndex = 12
	displayLabel.Parent = displayContainer

	statusLabel = Instance.new("TextLabel")
	statusLabel.Position = UDim2.new(0, 0, 0, 50)
	statusLabel.Size = UDim2.new(1, 0, 0, 22)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 11
	statusLabel.TextColor3 = Color3.fromRGB(150, 175, 200)
	statusLabel.Text = "ENTER 4-DIGIT HEX CODE (FROM MEMO)"
	statusLabel.ZIndex = 12
	statusLabel.Parent = displayContainer

	-- Keypad Grid (4x4 Matrix: 0-9 and A-F)
	local gridContainer = Instance.new("Frame")
	gridContainer.Position = UDim2.new(0, 18, 0, 146)
	gridContainer.Size = UDim2.new(1, -36, 0, 280)
	gridContainer.BackgroundTransparency = 1
	gridContainer.ZIndex = 11
	gridContainer.Parent = keypadFrame

	local keys = {
		{ "1", "2", "3", "A" },
		{ "4", "5", "6", "B" },
		{ "7", "8", "9", "C" },
		{ "0", "D", "E", "F" },
	}

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 86, 0, 62)
	gridLayout.CellPadding = UDim2.new(0, 12, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = gridContainer

	local layoutIndex = 1
	for r = 1, 4 do
		for c = 1, 4 do
			local char = keys[r][c]
			local isLetter = (c == 4) or (r == 4 and c > 1)

			local keyBtn = Instance.new("TextButton")
			keyBtn.Name = "Key_" .. char
			keyBtn.LayoutOrder = layoutIndex
			keyBtn.BackgroundColor3 = isLetter and Color3.fromRGB(38, 52, 72) or Color3.fromRGB(28, 36, 48)
			keyBtn.Font = Enum.Font.Code
			keyBtn.TextSize = 22
			keyBtn.TextColor3 = isLetter and Color3.fromRGB(130, 220, 255) or Color3.fromRGB(240, 245, 255)
			keyBtn.Text = char
			keyBtn.ZIndex = 13
			keyBtn.Parent = gridContainer
			Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 7)

			local stroke = Instance.new("UIStroke", keyBtn)
			stroke.Color = isLetter and Color3.fromRGB(65, 125, 185) or Color3.fromRGB(48, 62, 80)
			stroke.Thickness = 1.2

			keyBtn.MouseButton1Click:Connect(function()
				appendChar(char)
			end)

			layoutIndex = layoutIndex + 1
		end
	end

	-- Bottom Actions (Clear & Enter)
	local bottomBar = Instance.new("Frame")
	bottomBar.AnchorPoint = Vector2.new(0.5, 0)
	bottomBar.Position = UDim2.new(0.5, 0, 0, 438)
	bottomBar.Size = UDim2.new(1, -36, 0, 64)
	bottomBar.BackgroundTransparency = 1
	bottomBar.ZIndex = 11
	bottomBar.Parent = keypadFrame

	local clearBtn = Instance.new("TextButton")
	clearBtn.Position = UDim2.new(0, 0, 0, 0)
	clearBtn.Size = UDim2.new(0.47, 0, 0, 54)
	clearBtn.BackgroundColor3 = Color3.fromRGB(85, 35, 42)
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextSize = 14
	clearBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
	clearBtn.Text = "CLEAR [⌫]"
	clearBtn.ZIndex = 13
	clearBtn.Parent = bottomBar
	Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 7)
	clearBtn.MouseButton1Click:Connect(clearInput)

	local enterBtn = Instance.new("TextButton")
	enterBtn.Position = UDim2.new(0.53, 0, 0, 0)
	enterBtn.Size = UDim2.new(0.47, 0, 0, 54)
	enterBtn.BackgroundColor3 = Color3.fromRGB(32, 115, 62)
	enterBtn.Font = Enum.Font.GothamBold
	enterBtn.TextSize = 14
	enterBtn.TextColor3 = Color3.fromRGB(230, 255, 235)
	enterBtn.Text = "ENTER [↵]"
	enterBtn.ZIndex = 13
	enterBtn.Parent = bottomBar
	Instance.new("UICorner", enterBtn).CornerRadius = UDim.new(0, 7)
	enterBtn.MouseButton1Click:Connect(submitCode)
end

function BankSafeKeypadModal.open()
	if keypadFrame and keypadFrame.Visible then
		return
	end

	if not backdrop or not backdrop.Parent or not keypadFrame or not keypadFrame.Parent or not screenGui or not screenGui.Parent then
		BankSafeKeypadModal.mount()
	end

	inputBuffer = ""
	isSubmitting = false
	updateDisplay()
	if statusLabel then
		statusLabel.Text = "ENTER 4-DIGIT HEX CODE (FROM MEMO)"
		statusLabel.TextColor3 = Color3.fromRGB(150, 175, 200)
	end

	local stateMgr = UIStateManager or getUIStateManager()
	if stateMgr then
		stateMgr.openModal(MODAL_ID, BankSafeKeypadModal.close)
	end

	backdrop.Visible = true
	keypadFrame.Visible = true

	local openedAt = os.clock()

	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end

	inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if UserInputService:GetFocusedTextBox() then return end

		if input.KeyCode == Enum.KeyCode.Escape then
			BankSafeKeypadModal.close()
			return
		end

		-- Ignore initial [E] press so triggering prompt doesn't type 'E'
		if input.KeyCode == Enum.KeyCode.E and (os.clock() - openedAt < 0.35) then
			return
		end

		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
			submitCode()
			return
		end

		if input.KeyCode == Enum.KeyCode.Backspace then
			backspace()
			return
		end

		local validKeyMap = {
			[Enum.KeyCode.Zero] = "0", [Enum.KeyCode.KeypadZero] = "0",
			[Enum.KeyCode.One] = "1", [Enum.KeyCode.KeypadOne] = "1",
			[Enum.KeyCode.Two] = "2", [Enum.KeyCode.KeypadTwo] = "2",
			[Enum.KeyCode.Three] = "3", [Enum.KeyCode.KeypadThree] = "3",
			[Enum.KeyCode.Four] = "4", [Enum.KeyCode.KeypadFour] = "4",
			[Enum.KeyCode.Five] = "5", [Enum.KeyCode.KeypadFive] = "5",
			[Enum.KeyCode.Six] = "6", [Enum.KeyCode.KeypadSix] = "6",
			[Enum.KeyCode.Seven] = "7", [Enum.KeyCode.KeypadSeven] = "7",
			[Enum.KeyCode.Eight] = "8", [Enum.KeyCode.KeypadEight] = "8",
			[Enum.KeyCode.Nine] = "9", [Enum.KeyCode.KeypadNine] = "9",
			[Enum.KeyCode.A] = "A",
			[Enum.KeyCode.B] = "B",
			[Enum.KeyCode.C] = "C",
			[Enum.KeyCode.D] = "D",
			[Enum.KeyCode.E] = "E",
			[Enum.KeyCode.F] = "F",
		}

		local mapped = validKeyMap[input.KeyCode]
		if mapped then
			appendChar(mapped)
		end
	end)
end

function BankSafeKeypadModal.close()
	if backdrop then
		backdrop.Visible = false
	end
	if keypadFrame then
		keypadFrame.Visible = false
	end
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
	local stateMgr = UIStateManager or getUIStateManager()
	if stateMgr then
		stateMgr.closeModal(MODAL_ID)
	end
end

return BankSafeKeypadModal
