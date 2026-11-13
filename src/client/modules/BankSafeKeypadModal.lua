-- Bank Safe Hex Keypad Modal
-- Provides an interactive terminal keypad (0-9, A-F) for decoding the Bangkok Bank Safe.
-- Full keyboard input support (0-9, A-F, Backspace, Enter, Esc).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local UIStateManager = require(script.Parent:WaitForChild("UIStateManager"))

local BankSafeKeypadModal = {}
local MODAL_ID = "BankSafeKeypadModal"

local screenGui = nil
local modalOverlay = nil
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
			statusLabel.Text = "⚠️ CODE MUST BE 4 HEX DIGITS"
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
			statusLabel.Text = "✓ ACCESS GRANTED // SAFE OPENED"
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
		end
		task.delay(1.0, function()
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
			statusLabel.Text = "❌ " .. errMsg
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
	screenGui.DisplayOrder = 45
	screenGui.Parent = playerGui

	modalOverlay = Instance.new("TextButton")
	modalOverlay.Name = "Backdrop"
	modalOverlay.Size = UDim2.fromScale(1, 1)
	modalOverlay.BackgroundColor3 = Color3.fromRGB(4, 7, 12)
	modalOverlay.BackgroundTransparency = 0.5
	modalOverlay.BorderSizePixel = 0
	modalOverlay.Text = ""
	modalOverlay.AutoButtonColor = false
	modalOverlay.Modal = true
	modalOverlay.Visible = false
	modalOverlay.ZIndex = 1
	modalOverlay.Parent = screenGui

	-- Outer Safe Terminal Frame
	local frame = Instance.new("Frame")
	frame.Name = "KeypadFrame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.new(0, 420, 0, 520)
	frame.BackgroundColor3 = Color3.fromRGB(20, 25, 34)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.ZIndex = 2
	frame.Parent = modalOverlay
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local frameStroke = Instance.new("UIStroke", frame)
	frameStroke.Color = Color3.fromRGB(55, 70, 90)
	frameStroke.Thickness = 2.5

	-- Title Bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 54)
	titleBar.BackgroundColor3 = Color3.fromRGB(28, 36, 48)
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 3
	titleBar.Parent = frame
	Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel")
	title.Position = UDim2.new(0, 16, 0, 8)
	title.Size = UDim2.new(1, -90, 0, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextColor3 = Color3.fromRGB(235, 245, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "BANGKOK BANK VAULT // HEX ACCESS"
	title.ZIndex = 4
	title.Parent = titleBar

	local subtitle = Instance.new("TextLabel")
	subtitle.Position = UDim2.new(0, 16, 0, 28)
	subtitle.Size = UDim2.new(1, -90, 0, 18)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 11
	subtitle.TextColor3 = Color3.fromRGB(120, 180, 225)
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Text = "Manager's Emergency Armory Safe (Floor 1)"
	subtitle.ZIndex = 4
	subtitle.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -12, 0.5, 0)
	closeBtn.Size = UDim2.new(0, 60, 0, 30)
	closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 50)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 11
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "ESC [✕]"
	closeBtn.ZIndex = 5
	closeBtn.Parent = titleBar
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
	closeBtn.MouseButton1Click:Connect(BankSafeKeypadModal.close)

	-- Digital Screen Box
	local screenBox = Instance.new("Frame")
	screenBox.AnchorPoint = Vector2.new(0.5, 0)
	screenBox.Position = UDim2.new(0.5, 0, 0, 68)
	screenBox.Size = UDim2.new(1, -36, 0, 80)
	screenBox.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
	screenBox.BorderSizePixel = 0
	screenBox.ZIndex = 3
	screenBox.Parent = frame
	Instance.new("UICorner", screenBox).CornerRadius = UDim.new(0, 8)

	local screenStroke = Instance.new("UIStroke", screenBox)
	screenStroke.Color = Color3.fromRGB(35, 90, 60)
	screenStroke.Thickness = 1.5

	statusLabel = Instance.new("TextLabel")
	statusLabel.Position = UDim2.new(0, 12, 0, 8)
	statusLabel.Size = UDim2.new(1, -24, 0, 18)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.Code
	statusLabel.TextSize = 11
	statusLabel.TextColor3 = Color3.fromRGB(120, 180, 140)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	statusLabel.Text = "ENTER 4-DIGIT HEX CODE (FROM MEMO)"
	statusLabel.ZIndex = 4
	statusLabel.Parent = screenBox

	displayLabel = Instance.new("TextLabel")
	displayLabel.Position = UDim2.new(0, 12, 0, 28)
	displayLabel.Size = UDim2.new(1, -24, 0, 44)
	displayLabel.BackgroundTransparency = 1
	displayLabel.Font = Enum.Font.Code
	displayLabel.TextSize = 28
	displayLabel.TextColor3 = Color3.fromRGB(80, 255, 150)
	displayLabel.TextXAlignment = Enum.TextXAlignment.Center
	displayLabel.Text = "_ _ _ _"
	displayLabel.ZIndex = 4
	displayLabel.Parent = screenBox

	-- Keypad Grid (4 rows x 4 cols: 1 2 3 A / 4 5 6 B / 7 8 9 C / 0 D E F)
	local keys = {
		{ "1", "2", "3", "A" },
		{ "4", "5", "6", "B" },
		{ "7", "8", "9", "C" },
		{ "0", "D", "E", "F" },
	}

	local gridContainer = Instance.new("Frame")
	gridContainer.AnchorPoint = Vector2.new(0.5, 0)
	gridContainer.Position = UDim2.new(0.5, 0, 0, 160)
	gridContainer.Size = UDim2.new(1, -36, 0, 260)
	gridContainer.BackgroundTransparency = 1
	gridContainer.ZIndex = 3
	gridContainer.Parent = frame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 86, 0, 56)
	gridLayout.CellPadding = UDim2.new(0, 13, 0, 10)
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
			keyBtn.BackgroundColor3 = isLetter and Color3.fromRGB(38, 52, 72) or Color3.fromRGB(30, 38, 50)
			keyBtn.Font = Enum.Font.Code
			keyBtn.TextSize = 20
			keyBtn.TextColor3 = isLetter and Color3.fromRGB(120, 215, 255) or Color3.fromRGB(240, 245, 255)
			keyBtn.Text = char
			keyBtn.ZIndex = 4
			keyBtn.Parent = gridContainer
			Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)

			local stroke = Instance.new("UIStroke", keyBtn)
			stroke.Color = isLetter and Color3.fromRGB(60, 120, 180) or Color3.fromRGB(48, 60, 78)
			stroke.Thickness = 1

			keyBtn.MouseButton1Click:Connect(function()
				appendChar(char)
			end)

			layoutIndex = layoutIndex + 1
		end
	end

	-- Bottom Actions (Clear & Enter)
	local bottomBar = Instance.new("Frame")
	bottomBar.AnchorPoint = Vector2.new(0.5, 0)
	bottomBar.Position = UDim2.new(0.5, 0, 0, 434)
	bottomBar.Size = UDim2.new(1, -36, 0, 60)
	bottomBar.BackgroundTransparency = 1
	bottomBar.ZIndex = 3
	bottomBar.Parent = frame

	local clearBtn = Instance.new("TextButton")
	clearBtn.Position = UDim2.new(0, 0, 0, 0)
	clearBtn.Size = UDim2.new(0.46, 0, 0, 52)
	clearBtn.BackgroundColor3 = Color3.fromRGB(80, 35, 40)
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextSize = 14
	clearBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
	clearBtn.Text = "CLEAR [⌫]"
	clearBtn.ZIndex = 4
	clearBtn.Parent = bottomBar
	Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 6)
	clearBtn.MouseButton1Click:Connect(clearInput)

	local enterBtn = Instance.new("TextButton")
	enterBtn.Position = UDim2.new(0.54, 0, 0, 0)
	enterBtn.Size = UDim2.new(0.46, 0, 0, 52)
	enterBtn.BackgroundColor3 = Color3.fromRGB(32, 105, 58)
	enterBtn.Font = Enum.Font.GothamBold
	enterBtn.TextSize = 14
	enterBtn.TextColor3 = Color3.fromRGB(230, 255, 235)
	enterBtn.Text = "ENTER [↵]"
	enterBtn.ZIndex = 4
	enterBtn.Parent = bottomBar
	Instance.new("UICorner", enterBtn).CornerRadius = UDim.new(0, 6)
	enterBtn.MouseButton1Click:Connect(submitCode)

	modalOverlay.MouseButton1Click:Connect(BankSafeKeypadModal.close)
end

function BankSafeKeypadModal.open()
	if modalOverlay and modalOverlay.Visible then
		return
	end

	if not modalOverlay or not modalOverlay.Parent or not screenGui or not screenGui.Parent then
		BankSafeKeypadModal.mount()
	end

	inputBuffer = ""
	isSubmitting = false
	updateDisplay()
	if statusLabel then
		statusLabel.Text = "ENTER 4-DIGIT HEX CODE (FROM MEMO)"
		statusLabel.TextColor3 = Color3.fromRGB(150, 175, 200)
	end

	UIStateManager.openModal(MODAL_ID, BankSafeKeypadModal.close)
	modalOverlay.Visible = true

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

		-- Ignore the initial [E] press used to trigger the safe prompt
		if input.KeyCode == Enum.KeyCode.E and (os.clock() - openedAt < 0.25) then
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
	if modalOverlay then
		modalOverlay.Visible = false
	end
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
	UIStateManager.closeModal(MODAL_ID)
end

return BankSafeKeypadModal
