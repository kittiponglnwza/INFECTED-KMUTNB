-- Emergency Memo Modal: Displays the handwritten bloodstained bank memo found on the Manager's Corpse.
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
local modalOverlay = nil
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
	screenGui.DisplayOrder = 42
	screenGui.Parent = playerGui

	modalOverlay = Instance.new("TextButton")
	modalOverlay.Name = "Backdrop"
	modalOverlay.Size = UDim2.fromScale(1, 1)
	modalOverlay.BackgroundColor3 = Color3.fromRGB(5, 7, 10)
	modalOverlay.BackgroundTransparency = 0.5
	modalOverlay.BorderSizePixel = 0
	modalOverlay.Text = ""
	modalOverlay.AutoButtonColor = false
	modalOverlay.Modal = true
	modalOverlay.Visible = false
	modalOverlay.ZIndex = 1
	modalOverlay.Parent = screenGui

	-- Parchment Paper Container
	local paper = Instance.new("Frame")
	paper.Name = "MemoPaper"
	paper.AnchorPoint = Vector2.new(0.5, 0.5)
	paper.Position = UDim2.fromScale(0.5, 0.5)
	paper.Size = UDim2.new(0, 560, 0, 480)
	paper.BackgroundColor3 = Color3.fromRGB(242, 238, 226)
	paper.BorderSizePixel = 0
	paper.Active = true
	paper.ZIndex = 2
	paper.Parent = modalOverlay
	Instance.new("UICorner", paper).CornerRadius = UDim.new(0, 8)

	local paperStroke = Instance.new("UIStroke", paper)
	paperStroke.Color = Color3.fromRGB(165, 150, 130)
	paperStroke.Thickness = 2

	-- Bloodstain accent corner
	local bloodCorner = Instance.new("Frame")
	bloodCorner.Name = "Bloodstain"
	bloodCorner.Position = UDim2.new(1, -70, 0, 0)
	bloodCorner.Size = UDim2.new(0, 70, 0, 70)
	bloodCorner.BackgroundColor3 = Color3.fromRGB(115, 20, 24)
	bloodCorner.BackgroundTransparency = 0.55
	bloodCorner.BorderSizePixel = 0
	bloodCorner.ZIndex = 3
	bloodCorner.Parent = paper
	Instance.new("UICorner", bloodCorner).CornerRadius = UDim.new(0, 8)

	-- Top Header Stamp
	local headerBar = Instance.new("Frame")
	headerBar.Size = UDim2.new(1, 0, 0, 68)
	headerBar.BackgroundColor3 = Color3.fromRGB(32, 42, 58)
	headerBar.BorderSizePixel = 0
	headerBar.ZIndex = 3
	headerBar.Parent = paper
	Instance.new("UICorner", headerBar).CornerRadius = UDim.new(0, 8)

	local bankTitle = Instance.new("TextLabel")
	bankTitle.Position = UDim2.new(0, 20, 0, 12)
	bankTitle.Size = UDim2.new(1, -120, 0, 22)
	bankTitle.BackgroundTransparency = 1
	bankTitle.Font = Enum.Font.GothamBold
	bankTitle.TextSize = 15
	bankTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
	bankTitle.TextXAlignment = Enum.TextXAlignment.Left
	bankTitle.Text = "BANGKOK BANK — BRANCH 042 (KMUTNB)"
	bankTitle.ZIndex = 4
	bankTitle.Parent = headerBar

	local bankSub = Instance.new("TextLabel")
	bankSub.Position = UDim2.new(0, 20, 0, 36)
	bankSub.Size = UDim2.new(1, -120, 0, 20)
	bankSub.BackgroundTransparency = 1
	bankSub.Font = Enum.Font.Gotham
	bankSub.TextSize = 12
	bankSub.TextColor3 = Color3.fromRGB(255, 120, 120)
	bankSub.TextXAlignment = Enum.TextXAlignment.Left
	bankSub.Text = "EMERGENCY DIRECTIVE // บันทึกฉุกเฉินผู้จัดการสาขา"
	bankSub.ZIndex = 4
	bankSub.Parent = headerBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -14, 0.5, 0)
	closeBtn.Size = UDim2.new(0, 74, 0, 32)
	closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 45)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 12
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "CLOSE [✕]"
	closeBtn.ZIndex = 5
	closeBtn.Parent = headerBar
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
	closeBtn.MouseButton1Click:Connect(EmergencyMemoModal.close)

	-- Note Body
	local bodyText = Instance.new("TextLabel")
	bodyText.Position = UDim2.new(0, 24, 0, 84)
	bodyText.Size = UDim2.new(1, -48, 0, 100)
	bodyText.BackgroundTransparency = 1
	bodyText.Font = Enum.Font.Gotham
	bodyText.TextSize = 13
	bodyText.TextColor3 = Color3.fromRGB(38, 42, 48)
	bodyText.TextXAlignment = Enum.TextXAlignment.Left
	bodyText.TextYAlignment = Enum.TextYAlignment.Top
	bodyText.TextWrapped = true
	bodyText.LineHeight = 1.3
	bodyText.Text = "ถึงเจ้าหน้าที่รักษาความปลอดภัย:\n"
		.. "ปืนลูกโม่ฉุกเฉินประจำสาขา (.45 Sheriff) ถูกล็อกไว้ในตู้เซฟเหล็กด้านหลังโต๊ะผู้จัดการ\n"
		.. "รหัสผ่านนิรภัยถูกตั้งไว้ตามระบบความปลอดภัยมาตรฐานแบบ Binary 16-Bit:"
	bodyText.ZIndex = 3
	bodyText.Parent = paper

	-- Binary Box Display
	local codeFrame = Instance.new("Frame")
	codeFrame.AnchorPoint = Vector2.new(0.5, 0)
	codeFrame.Position = UDim2.new(0.5, 0, 0, 185)
	codeFrame.Size = UDim2.new(1, -48, 0, 74)
	codeFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 32)
	codeFrame.BorderSizePixel = 0
	codeFrame.ZIndex = 3
	codeFrame.Parent = paper
	Instance.new("UICorner", codeFrame).CornerRadius = UDim.new(0, 8)

	local codeLabel = Instance.new("TextLabel")
	codeLabel.Size = UDim2.fromScale(1, 1)
	codeLabel.BackgroundTransparency = 1
	codeLabel.Font = Enum.Font.Code
	codeLabel.TextSize = 22
	codeLabel.TextColor3 = Color3.fromRGB(75, 235, 150)
	codeLabel.Text = "BIN:  1011   0100   1100   1010"
	codeLabel.ZIndex = 4
	codeLabel.Parent = codeFrame

	-- Conversion Hint / Warning
	local hintBox = Instance.new("Frame")
	hintBox.Position = UDim2.new(0, 24, 0, 275)
	hintBox.Size = UDim2.new(1, -48, 0, 130)
	hintBox.BackgroundColor3 = Color3.fromRGB(230, 224, 210)
	hintBox.BorderSizePixel = 0
	hintBox.ZIndex = 3
	hintBox.Parent = paper
	Instance.new("UICorner", hintBox).CornerRadius = UDim.new(0, 6)

	local hintTitle = Instance.new("TextLabel")
	hintTitle.Position = UDim2.new(0, 14, 0, 10)
	hintTitle.Size = UDim2.new(1, -28, 0, 20)
	hintTitle.BackgroundTransparency = 1
	hintTitle.Font = Enum.Font.GothamBold
	hintTitle.TextSize = 13
	hintTitle.TextColor3 = Color3.fromRGB(160, 45, 45)
	hintTitle.TextXAlignment = Enum.TextXAlignment.Left
	hintTitle.Text = "⚠️ คำเตือนสำคัญจากระบบตู้นิรภัย:"
	hintTitle.ZIndex = 4
	hintTitle.Parent = hintBox

	local hintDetail = Instance.new("TextLabel")
	hintDetail.Position = UDim2.new(0, 14, 0, 32)
	hintDetail.Size = UDim2.new(1, -28, 0, 88)
	hintDetail.BackgroundTransparency = 1
	hintDetail.Font = Enum.Font.Gotham
	hintDetail.TextSize = 12
	hintDetail.TextColor3 = Color3.fromRGB(55, 60, 68)
	hintDetail.TextXAlignment = Enum.TextXAlignment.Left
	hintDetail.TextYAlignment = Enum.TextYAlignment.Top
	hintDetail.TextWrapped = true
	hintDetail.LineHeight = 1.25
	hintDetail.Text = "• แป้นกดของตู้เซฟรับค่าเป็นเลขฐาน 16 (HEX) เท่านั้น ไม่รับค่าฐาน 2\n"
		.. "• ให้นำเลขไบนารี 4 กลุ่ม (กลุ่มละ 4 บิต) แปลงเป็นฐาน 16 ก่อนกดรหัส:\n"
		.. "  [ 1011 ] ➔ B  |  [ 0100 ] ➔ 4  |  [ 1100 ] ➔ C  |  [ 1010 ] ➔ A\n"
		.. "• เมื่อถอดรหัสครบ 4 ตัวอักษร ให้ไปกดที่แป้นตู้เซฟเพื่อรับอาวุธ"
	hintDetail.ZIndex = 4
	hintDetail.Parent = hintBox

	-- Footer signature
	local footer = Instance.new("TextLabel")
	footer.Position = UDim2.new(0, 24, 0, 422)
	footer.Size = UDim2.new(1, -48, 0, 24)
	footer.BackgroundTransparency = 1
	footer.Font = Enum.Font.Gotham
	footer.TextSize = 12
	footer.TextColor3 = Color3.fromRGB(105, 110, 120)
	footer.TextXAlignment = Enum.TextXAlignment.Right
	footer.Text = "ลงชื่อ: พัชรี ส. (ผู้จัดการสาขา มจพ.) — กด [ESC], [E] หรือคลิก [CLOSE] เพื่อปิด"
	footer.ZIndex = 3
	footer.Parent = paper

	modalOverlay.MouseButton1Click:Connect(EmergencyMemoModal.close)
end

function EmergencyMemoModal.open()
	if modalOverlay and modalOverlay.Visible then
		return
	end

	if not modalOverlay or not modalOverlay.Parent or not screenGui or not screenGui.Parent then
		EmergencyMemoModal.mount()
	end

	local stateMgr = UIStateManager or getUIStateManager()
	if stateMgr then
		stateMgr.openModal(MODAL_ID, EmergencyMemoModal.close)
	end
	modalOverlay.Visible = true

	local openedAt = os.clock()

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

		if input.KeyCode == Enum.KeyCode.E then
			-- Debounce so the initial prompt keypress does NOT immediately close the modal
			if (os.clock() - openedAt) >= 0.35 then
				EmergencyMemoModal.close()
			end
			return
		end
	end)
end

function EmergencyMemoModal.close()
	if modalOverlay then
		modalOverlay.Visible = false
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
