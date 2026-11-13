-- Emergency Memo Modal: Displays the handwritten bloodstained bank memo found on the Manager's Corpse / Desk.
-- Reveals the 16-bit binary puzzle code required to unlock the bank safe.

local Players = game:GetService("Players")
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

local EmergencyMemoModal = {}
local MODAL_ID = "EmergencyMemoModal"

local screenGui = nil
local backdrop = nil
local paperFrame = nil
local openConnection = nil

function EmergencyMemoModal.mount()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("EmergencyMemoHUD")
	if old then
		old:Destroy()
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EmergencyMemoHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 50
	screenGui.Parent = playerGui

	-- Darkened Dim Backdrop: Sibling to paperFrame so clicks on paper do NOT bubble and close
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
	backdrop.MouseButton1Click:Connect(EmergencyMemoModal.close)

	-- Parchment Paper Container: Sibling to backdrop (ZIndex = 10)
	paperFrame = Instance.new("Frame")
	paperFrame.Name = "MemoPaper"
	paperFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	paperFrame.Position = UDim2.fromScale(0.5, 0.5)
	paperFrame.Size = UDim2.new(0, 580, 0, 500)
	paperFrame.BackgroundColor3 = Color3.fromRGB(244, 240, 230)
	paperFrame.BorderSizePixel = 0
	paperFrame.Active = true
	paperFrame.Visible = false
	paperFrame.ZIndex = 10
	paperFrame.Parent = screenGui
	Instance.new("UICorner", paperFrame).CornerRadius = UDim.new(0, 10)

	local paperStroke = Instance.new("UIStroke", paperFrame)
	paperStroke.Color = Color3.fromRGB(165, 148, 125)
	paperStroke.Thickness = 2.5

	-- Bloodstain accent corner
	local bloodCorner = Instance.new("Frame")
	bloodCorner.Name = "Bloodstain"
	bloodCorner.Position = UDim2.new(1, -80, 0, 0)
	bloodCorner.Size = UDim2.new(0, 80, 0, 80)
	bloodCorner.BackgroundColor3 = Color3.fromRGB(120, 20, 25)
	bloodCorner.BackgroundTransparency = 0.55
	bloodCorner.BorderSizePixel = 0
	bloodCorner.ZIndex = 11
	bloodCorner.Parent = paperFrame
	Instance.new("UICorner", bloodCorner).CornerRadius = UDim.new(0, 10)

	-- Top Header Stamp
	local headerBar = Instance.new("Frame")
	headerBar.Size = UDim2.new(1, 0, 0, 72)
	headerBar.BackgroundColor3 = Color3.fromRGB(28, 38, 54)
	headerBar.BorderSizePixel = 0
	headerBar.ZIndex = 12
	headerBar.Parent = paperFrame
	Instance.new("UICorner", headerBar).CornerRadius = UDim.new(0, 10)

	local bankTitle = Instance.new("TextLabel")
	bankTitle.Position = UDim2.new(0, 20, 0, 14)
	bankTitle.Size = UDim2.new(1, -130, 0, 22)
	bankTitle.BackgroundTransparency = 1
	bankTitle.Font = Enum.Font.GothamBold
	bankTitle.TextSize = 15
	bankTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
	bankTitle.TextXAlignment = Enum.TextXAlignment.Left
	bankTitle.Text = "BANGKOK BANK — BRANCH 042 (KMUTNB)"
	bankTitle.ZIndex = 13
	bankTitle.Parent = headerBar

	local bankSub = Instance.new("TextLabel")
	bankSub.Position = UDim2.new(0, 20, 0, 40)
	bankSub.Size = UDim2.new(1, -130, 0, 20)
	bankSub.BackgroundTransparency = 1
	bankSub.Font = Enum.Font.Gotham
	bankSub.TextSize = 12
	bankSub.TextColor3 = Color3.fromRGB(255, 125, 125)
	bankSub.TextXAlignment = Enum.TextXAlignment.Left
	bankSub.Text = "EMERGENCY DIRECTIVE // บันทึกฉุกเฉินผู้จัดการสาขา"
	bankSub.ZIndex = 13
	bankSub.Parent = headerBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -16, 0.5, 0)
	closeBtn.Size = UDim2.new(0, 84, 0, 36)
	closeBtn.BackgroundColor3 = Color3.fromRGB(165, 42, 48)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 13
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "CLOSE [✕]"
	closeBtn.ZIndex = 14
	closeBtn.Parent = headerBar
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)
	closeBtn.MouseButton1Click:Connect(EmergencyMemoModal.close)

	-- Note Body
	local bodyText = Instance.new("TextLabel")
	bodyText.Position = UDim2.new(0, 24, 0, 86)
	bodyText.Size = UDim2.new(1, -48, 0, 95)
	bodyText.BackgroundTransparency = 1
	bodyText.Font = Enum.Font.Gotham
	bodyText.TextSize = 13
	bodyText.TextColor3 = Color3.fromRGB(38, 42, 48)
	bodyText.TextXAlignment = Enum.TextXAlignment.Left
	bodyText.TextYAlignment = Enum.TextYAlignment.Top
	bodyText.TextWrapped = true
	bodyText.LineHeight = 1.25
	bodyText.Text = "ถึงเจ้าหน้าที่รักษาความปลอดภัย อาคาร 40 หรือผู้รอดชีวิต:\n"
		.. "เกิดการระบาดของไวรัสขั้นวิกฤต ฉันได้เก็บอาวุธปืนพกลูกโม่ประจำตัว (Sheriff) "
		.. "ไว้ในตู้เซฟหลังโต๊ะทำงานนี้อย่างปลอดภัย เพื่อป้องกันผู้ติดเชื้อบุกยึด\n"
		.. "รหัสตู้เซฟถูกเข้ารหัสเป็นระบบ 16-Bit Binary เพื่อความปลอดภัยสูงสุด:"
	bodyText.ZIndex = 12
	bodyText.Parent = paperFrame

	-- Binary Code Box (Prominent display)
	local codeBox = Instance.new("Frame")
	codeBox.Position = UDim2.new(0, 24, 0, 190)
	codeBox.Size = UDim2.new(1, -48, 0, 68)
	codeBox.BackgroundColor3 = Color3.fromRGB(18, 24, 34)
	codeBox.BorderSizePixel = 0
	codeBox.ZIndex = 12
	codeBox.Parent = paperFrame
	Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 8)

	local codeBoxStroke = Instance.new("UIStroke", codeBox)
	codeBoxStroke.Color = Color3.fromRGB(48, 85, 125)
	codeBoxStroke.Thickness = 1.5

	local codeLabel = Instance.new("TextLabel")
	codeLabel.Position = UDim2.new(0, 12, 0, 6)
	codeLabel.Size = UDim2.new(1, -24, 0, 16)
	codeLabel.BackgroundTransparency = 1
	codeLabel.Font = Enum.Font.GothamBold
	codeLabel.TextSize = 10
	codeLabel.TextColor3 = Color3.fromRGB(140, 185, 225)
	codeLabel.TextXAlignment = Enum.TextXAlignment.Left
	codeLabel.Text = "ENCRYPTED 16-BIT VAULT KEY (CONVERT TO 4-DIGIT HEX):"
	codeLabel.ZIndex = 13
	codeLabel.Parent = codeBox

	local binaryDisplay = Instance.new("TextLabel")
	binaryDisplay.Position = UDim2.new(0, 12, 0, 26)
	binaryDisplay.Size = UDim2.new(1, -24, 0, 36)
	binaryDisplay.BackgroundTransparency = 1
	binaryDisplay.Font = Enum.Font.Code
	binaryDisplay.TextSize = 22
	binaryDisplay.TextColor3 = Color3.fromRGB(75, 230, 150)
	binaryDisplay.Text = "1011  -  0100  -  1100  -  1010"
	binaryDisplay.ZIndex = 13
	binaryDisplay.Parent = codeBox

	-- Conversion Hint Panel
	local hintBox = Instance.new("Frame")
	hintBox.Position = UDim2.new(0, 24, 0, 270)
	hintBox.Size = UDim2.new(1, -48, 0, 155)
	hintBox.BackgroundColor3 = Color3.fromRGB(232, 226, 212)
	hintBox.BorderSizePixel = 0
	hintBox.ZIndex = 12
	hintBox.Parent = paperFrame
	Instance.new("UICorner", hintBox).CornerRadius = UDim.new(0, 8)

	local hintTitle = Instance.new("TextLabel")
	hintTitle.Position = UDim2.new(0, 14, 0, 10)
	hintTitle.Size = UDim2.new(1, -28, 0, 20)
	hintTitle.BackgroundTransparency = 1
	hintTitle.Font = Enum.Font.GothamBold
	hintTitle.TextSize = 13
	hintTitle.TextColor3 = Color3.fromRGB(160, 45, 45)
	hintTitle.TextXAlignment = Enum.TextXAlignment.Left
	hintTitle.Text = "⚠️  คำแนะนำการถอดรหัสเปิดตู้เซฟ (Binary ➔ HEX):"
	hintTitle.ZIndex = 13
	hintTitle.Parent = hintBox

	local hintDetail = Instance.new("TextLabel")
	hintDetail.Position = UDim2.new(0, 14, 0, 34)
	hintDetail.Size = UDim2.new(1, -28, 0, 112)
	hintDetail.BackgroundTransparency = 1
	hintDetail.Font = Enum.Font.Gotham
	hintDetail.TextSize = 12
	hintDetail.TextColor3 = Color3.fromRGB(48, 54, 62)
	hintDetail.TextXAlignment = Enum.TextXAlignment.Left
	hintDetail.TextYAlignment = Enum.TextYAlignment.Top
	hintDetail.TextWrapped = true
	hintDetail.LineHeight = 1.3
	hintDetail.Text = "• แป้นกดของตู้เซฟรับค่าเป็นเลขฐาน 16 (HEX: 0-9, A-F) เท่านั้น\n"
		.. "• นำเลขไบนารี 4 กลุ่ม แปลงเป็นฐาน 16 ทีละกลุ่ม:\n"
		.. "    [ 1011 ] ➔ B   |   [ 0100 ] ➔ 4   |   [ 1100 ] ➔ C   |   [ 1010 ] ➔ A\n"
		.. "• รหัสผ่านตู้เซฟ 4 ตัวคือ:  B 4 C A\n"
		.. "• เมื่อได้รหัส ให้เดินไปกด [E] ที่แป้นตู้เซฟด้านซ้าย กด B 4 C A แล้วกด ENTER เพื่อรับปืน Sheriff!"
	hintDetail.ZIndex = 13
	hintDetail.Parent = hintBox

	-- Footer signature
	local footer = Instance.new("TextLabel")
	footer.Position = UDim2.new(0, 24, 0, 442)
	footer.Size = UDim2.new(1, -48, 0, 24)
	footer.BackgroundTransparency = 1
	footer.Font = Enum.Font.Gotham
	footer.TextSize = 12
	footer.TextColor3 = Color3.fromRGB(115, 120, 130)
	footer.TextXAlignment = Enum.TextXAlignment.Right
	footer.Text = "ลงชื่อ: พัชรี ส. (ผู้จัดการสาขา มจพ.) — กด [ESC] หรือคลิก [CLOSE] เพื่อปิด"
	footer.ZIndex = 12
	footer.Parent = paperFrame
end

function EmergencyMemoModal.open()
	if paperFrame and paperFrame.Visible then
		return
	end

	if not backdrop or not backdrop.Parent or not paperFrame or not paperFrame.Parent or not screenGui or not screenGui.Parent then
		EmergencyMemoModal.mount()
	end

	local stateMgr = UIStateManager or getUIStateManager()
	if stateMgr then
		stateMgr.openModal(MODAL_ID, EmergencyMemoModal.close)
	end

	backdrop.Visible = true
	paperFrame.Visible = true

	if openConnection then
		openConnection:Disconnect()
		openConnection = nil
	end
	openConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if UserInputService:GetFocusedTextBox() then return end

		if input.KeyCode == Enum.KeyCode.Escape then
			EmergencyMemoModal.close()
			return
		end
	end)
end

function EmergencyMemoModal.close()
	if backdrop then
		backdrop.Visible = false
	end
	if paperFrame then
		paperFrame.Visible = false
	end
	if openConnection then
		openConnection:Disconnect()
		openConnection = nil
	end
	local stateMgr = UIStateManager or getUIStateManager()
	if stateMgr then
		stateMgr.closeModal(MODAL_ID)
	end
end

return EmergencyMemoModal
