--[[
    MissionController.client.lua
    Client HUD & Mission Feedback Controller for INFECTED-KMUTNB Phase 1.
    - Displays active Mission (MISSION 01 - SECURITY ACCESS), checklist of sub-objectives,
      Quest pouch state, Building power status, and explicit CAMPAIGN / DEV MODE badge.
    - Mounts server-validated CCTV Timeline Puzzle Modal cleanly via CCTVPuzzleModal + UIStateManager.
    - Receives server-authoritative StateChanged + DevFeedback without touching gameplay authority.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ClientModules = script.Parent:WaitForChild("ClientModules", 10)
local CCTVPuzzleModal = require(ClientModules:WaitForChild("CCTVPuzzleModal"))
local StaffPhoneUI = require(ClientModules:WaitForChild("StaffPhoneUI"))
local UIStateManager = require(ClientModules:WaitForChild("UIStateManager"))

local function resolveUIModule(name)
	local ok, mod = pcall(function()
		if ClientModules then
			local child = ClientModules:FindFirstChild(name) or ClientModules:WaitForChild(name, 2)
			if child then
				return require(child)
			end
		end
		local weapons = ReplicatedStorage:FindFirstChild("Weapons")
		local ui = weapons and weapons:FindFirstChild("ui")
		if ui then
			local child = ui:FindFirstChild(name) or ui:WaitForChild(name, 2)
			if child then
				return require(child)
			end
		end
		return nil
	end)
	if ok and mod then
		return mod
	elseif not ok then
		warn("[MissionController] resolveUIModule error for", name, ":", mod)
	end
	return nil
end

local EmergencyMemoModal = resolveUIModule("EmergencyMemoModal")
local BankSafeKeypadModal = resolveUIModule("BankSafeKeypadModal")
local Room102MonitorEffects = resolveUIModule("Room102MonitorEffects")
if Room102MonitorEffects and Room102MonitorEffects.start then
	Room102MonitorEffects.start()
end

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local NetProtocol = require(sharedFolder:WaitForChild("NetProtocol"))

local missionEvents = ReplicatedStorage:WaitForChild(NetProtocol.Remotes.MissionEventsFolder, 30)
local stateChanged = missionEvents and missionEvents:WaitForChild(NetProtocol.Remotes.StateChanged, 10)
local stateRequest = missionEvents and missionEvents:WaitForChild(NetProtocol.Remotes.StateRequest, 10)
local openPuzzleModalEvent = missionEvents and missionEvents:WaitForChild(NetProtocol.Remotes.OpenPuzzleModal, 10)
local submitPuzzleFn = missionEvents and missionEvents:WaitForChild(NetProtocol.Remotes.SubmitPuzzleSolution, 10)
local phoneActionFn = missionEvents and missionEvents:WaitForChild(NetProtocol.Remotes.PhoneAction, 10)
local devFeedbackEvent = missionEvents and missionEvents:WaitForChild(NetProtocol.Remotes.DevFeedback, 10)
local openBankSafeKeypadEvent = missionEvents and missionEvents:WaitForChild(NetProtocol.Remotes.OpenBankSafeKeypad, 10)
local showEmergencyMemoEvent = missionEvents and missionEvents:WaitForChild(NetProtocol.Remotes.ShowEmergencyMemo, 10)

if not stateChanged or not stateRequest then
	warn("[MissionController] Mission remotes were not available.")
	return
end

local existingGui = playerGui:FindFirstChild("MissionHUD")
if existingGui then
	existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissionHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.DisplayOrder = 8
screenGui.Parent = playerGui

-- Compact Top-Left Horror Mission Card (sized cleanly to avoid SurvivalDock bottom-left and TopRightUtilityBar)
local panel = Instance.new("Frame")
panel.Name = "ObjectivePanel"
panel.Position = UDim2.new(0, 20, 0, 14)
panel.Size = UDim2.new(0, 355, 0, 212)
panel.BackgroundColor3 = Color3.fromRGB(11, 15, 22)
panel.BackgroundTransparency = 0.14
panel.BorderSizePixel = 0
panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 9)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(175, 45, 55)
stroke.Transparency = 0.25
stroke.Thickness = 1.2
stroke.Parent = panel

-- Top header strip: Mission ID + Environment Mode Badge
local headerRow = Instance.new("Frame")
headerRow.Position = UDim2.new(0, 12, 0, 8)
headerRow.Size = UDim2.new(1, -24, 0, 20)
headerRow.BackgroundTransparency = 1
headerRow.Parent = panel

local eyebrow = Instance.new("TextLabel")
eyebrow.Name = "Eyebrow"
eyebrow.Size = UDim2.new(0.68, 0, 1, 0)
eyebrow.BackgroundTransparency = 1
eyebrow.Font = Enum.Font.GothamBold
eyebrow.Text = "MISSION 01 // ติดต่อครั้งแรก"
eyebrow.TextColor3 = Color3.fromRGB(240, 88, 78)
eyebrow.TextSize = 11
eyebrow.TextXAlignment = Enum.TextXAlignment.Left
eyebrow.Parent = headerRow

local modeBadge = Instance.new("TextLabel")
modeBadge.Name = "ModeBadge"
modeBadge.AnchorPoint = Vector2.new(1, 0.5)
modeBadge.Position = UDim2.new(1, 0, 0.5, 0)
modeBadge.Size = UDim2.new(0, 98, 0, 18)
modeBadge.BackgroundColor3 = Color3.fromRGB(26, 34, 46)
modeBadge.Font = Enum.Font.GothamBold
modeBadge.TextSize = 9
modeBadge.TextColor3 = Color3.fromRGB(175, 195, 218)
modeBadge.Text = "โหมดเนื้อเรื่อง"
modeBadge.Parent = headerRow
Instance.new("UICorner", modeBadge).CornerRadius = UDim.new(0, 5)

local title = Instance.new("TextLabel")
title.Name = "ObjectiveTitle"
title.Position = UDim2.new(0, 12, 0, 30)
title.Size = UDim2.new(1, -24, 0, 22)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "กำลังโหลดภารกิจ..."
title.TextColor3 = Color3.fromRGB(245, 248, 255)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Parent = panel

local description = Instance.new("TextLabel")
description.Name = "ObjectiveDescription"
description.Position = UDim2.new(0, 12, 0, 52)
description.Size = UDim2.new(1, -24, 0, 30)
description.BackgroundTransparency = 1
description.Font = Enum.Font.Gotham
description.Text = "กำลังเชื่อมต่อข้อมูลภารกิจอาคาร 40 ปี..."
description.TextColor3 = Color3.fromRGB(185, 196, 214)
description.TextSize = 11
description.TextWrapped = true
description.TextXAlignment = Enum.TextXAlignment.Left
description.TextYAlignment = Enum.TextYAlignment.Top
description.Parent = panel

-- Divider
local div = Instance.new("Frame")
div.Position = UDim2.new(0, 12, 0, 84)
div.Size = UDim2.new(1, -24, 0, 1)
div.BackgroundColor3 = Color3.fromRGB(60, 74, 96)
div.BackgroundTransparency = 0.45
div.BorderSizePixel = 0
div.Parent = panel

-- Checklist Container for M1 sub-objectives (4 crisp rows)
local checklistFrame = Instance.new("Frame")
checklistFrame.Name = "ChecklistContainer"
checklistFrame.Position = UDim2.new(0, 12, 0, 90)
checklistFrame.Size = UDim2.new(1, -24, 0, 92)
checklistFrame.BackgroundTransparency = 1
checklistFrame.Parent = panel

local checklistLayout = Instance.new("UIListLayout", checklistFrame)
checklistLayout.SortOrder = Enum.SortOrder.LayoutOrder
checklistLayout.Padding = UDim.new(0, 3)

local stepRows = {}
for i = 1, 4 do
	local row = Instance.new("TextLabel")
	row.Name = "Step_" .. i
	row.LayoutOrder = i
	row.Size = UDim2.new(1, 0, 0, 20)
	row.BackgroundTransparency = 1
	row.Font = Enum.Font.GothamMedium
	row.TextSize = 11
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextTruncate = Enum.TextTruncate.AtEnd
	row.TextColor3 = Color3.fromRGB(160, 172, 190)
	row.Text = ""
	row.Parent = checklistFrame
	stepRows[i] = row
end

-- Footer telemetry bar (Quest Keycard + Building Power)
local footer = Instance.new("TextLabel")
footer.Name = "FooterStatus"
footer.Position = UDim2.new(0, 12, 1, -24)
footer.Size = UDim2.new(1, -24, 0, 18)
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.GothamBold
footer.TextSize = 10
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.TextColor3 = Color3.fromRGB(145, 205, 235)
footer.Text = "คีย์การ์ด: ยังไม่มี   •   ไฟฟ้าตึก: ดับ"
footer.Parent = panel

-- Staff Phone quick-toggle pill button directly below ObjectivePanel
local phoneBtn = Instance.new("TextButton")
phoneBtn.Name = "StaffPhoneToggleBtn"
phoneBtn.Position = UDim2.new(0, 20, 0, 232)
phoneBtn.Size = UDim2.new(0, 355, 0, 28)
phoneBtn.BackgroundColor3 = Color3.fromRGB(16, 24, 36)
phoneBtn.BackgroundTransparency = 0.12
phoneBtn.BorderSizePixel = 0
phoneBtn.Font = Enum.Font.GothamBold
phoneBtn.TextSize = 11
phoneBtn.Selectable = false
phoneBtn.TextColor3 = Color3.fromRGB(130, 220, 255)
phoneBtn.Text = "📱 โทรศัพท์เจ้าหน้าที่ [P]  •  บันทึก / ข้อความ / แผนที่"
phoneBtn.Parent = screenGui
Instance.new("UICorner", phoneBtn).CornerRadius = UDim.new(0, 7)
local phoneStroke = Instance.new("UIStroke", phoneBtn)
phoneStroke.Color = Color3.fromRGB(55, 165, 220)
phoneStroke.Thickness = 1.1
phoneStroke.Transparency = 0.25

-- Top-Center Room 102 Hold-Out Upload & Alarm Status Banner
local holdoutBanner = Instance.new("Frame")
holdoutBanner.Name = "Room102HoldoutBanner"
holdoutBanner.AnchorPoint = Vector2.new(0.5, 0)
holdoutBanner.Position = UDim2.new(0.5, 0, 0, 14)
holdoutBanner.Size = UDim2.new(0, 440, 0, 54)
holdoutBanner.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
holdoutBanner.BackgroundTransparency = 0.1
holdoutBanner.BorderSizePixel = 0
holdoutBanner.Visible = false
holdoutBanner.ZIndex = 24
holdoutBanner.Parent = screenGui
Instance.new("UICorner", holdoutBanner).CornerRadius = UDim.new(0, 8)
local holdoutStroke = Instance.new("UIStroke", holdoutBanner)
holdoutStroke.Color = Color3.fromRGB(255, 165, 55)
holdoutStroke.Thickness = 1.6

local holdoutLabel = Instance.new("TextLabel")
holdoutLabel.Position = UDim2.new(0, 12, 0, 5)
holdoutLabel.Size = UDim2.new(1, -24, 0, 24)
holdoutLabel.BackgroundTransparency = 1
holdoutLabel.Font = Enum.Font.GothamBold
holdoutLabel.TextSize = 13
holdoutLabel.TextColor3 = Color3.fromRGB(255, 232, 175)
holdoutLabel.Text = "⏳ กำลังอัปโหลด Security Override..."
holdoutLabel.ZIndex = 25
holdoutLabel.Parent = holdoutBanner

local holdoutTrack = Instance.new("Frame")
holdoutTrack.Position = UDim2.new(0, 12, 0, 34)
holdoutTrack.Size = UDim2.new(1, -24, 0, 11)
holdoutTrack.BackgroundColor3 = Color3.fromRGB(36, 42, 54)
holdoutTrack.BorderSizePixel = 0
holdoutTrack.ZIndex = 25
holdoutTrack.Parent = holdoutBanner
Instance.new("UICorner", holdoutTrack).CornerRadius = UDim.new(0, 5)

local holdoutFill = Instance.new("Frame")
holdoutFill.Size = UDim2.fromScale(0, 1)
holdoutFill.BackgroundColor3 = Color3.fromRGB(255, 175, 55)
holdoutFill.BorderSizePixel = 0
holdoutFill.ZIndex = 26
holdoutFill.Parent = holdoutTrack
Instance.new("UICorner", holdoutFill).CornerRadius = UDim.new(0, 5)

local function refreshHoldoutBanner()
	local holdoutActive = Workspace:GetAttribute(NetProtocol.Attributes.Room102HoldoutActive) == true
	local alarmActive = Workspace:GetAttribute(NetProtocol.Attributes.Room102AlarmActive) == true
	local rem = math.max(0, tonumber(Workspace:GetAttribute(NetProtocol.Attributes.Room102HoldoutRemaining)) or 0)
	local total = math.max(1, tonumber(Workspace:GetAttribute(NetProtocol.Attributes.Room102HoldoutTotal)) or 75)
	local upsPct = math.clamp(tonumber(Workspace:GetAttribute(NetProtocol.Attributes.Room102UPSPercent)) or 34, 0, 100)

	if holdoutActive then
		local prog = math.clamp(1 - (rem / total), 0, 1)
		holdoutBanner.Visible = true
		holdoutStroke.Color = Color3.fromRGB(255, 165, 55)
		holdoutLabel.TextColor3 = Color3.fromRGB(255, 232, 175)
		holdoutLabel.Text = string.format("⏳ อัปโหลด OVERRIDE %d%% (เหลือ %d วิ) • UPS สำรอง: %d%%",
			math.floor(prog * 100), math.ceil(rem), upsPct)
		holdoutTrack.Visible = true
		holdoutFill.Size = UDim2.fromScale(prog, 1)
		holdoutFill.BackgroundColor3 = Color3.fromRGB(255, 175, 55)
	elseif alarmActive then
		holdoutBanner.Visible = true
		holdoutStroke.Color = Color3.fromRGB(235, 55, 65)
		holdoutLabel.TextColor3 = Color3.fromRGB(255, 185, 185)
		holdoutLabel.Text = "🚨 สัญญาณเตือนภัยห้อง 102! ลำดับกล้องผิด — ซอมบี้กำลังบุก!"
		holdoutTrack.Visible = false
	else
		holdoutBanner.Visible = false
	end
end

for _, attrName in ipairs({
	NetProtocol.Attributes.Room102HoldoutActive,
	NetProtocol.Attributes.Room102HoldoutRemaining,
	NetProtocol.Attributes.Room102HoldoutTotal,
	NetProtocol.Attributes.Room102UPSPercent,
	NetProtocol.Attributes.Room102AlarmActive,
}) do
	Workspace:GetAttributeChangedSignal(attrName):Connect(refreshHoldoutBanner)
end
refreshHoldoutBanner()

-- Non-colliding Toast / Server Feedback banner anchored directly below StaffPhoneToggleBtn
local toastBanner = Instance.new("TextLabel")
toastBanner.Name = "MissionToastBanner"
toastBanner.AnchorPoint = Vector2.new(0, 0)
toastBanner.Position = UDim2.new(0, 20, 0, 266)
toastBanner.Size = UDim2.new(0, 355, 0, 44)
toastBanner.BackgroundColor3 = Color3.fromRGB(14, 19, 28)
toastBanner.BackgroundTransparency = 0.14
toastBanner.BorderSizePixel = 0
toastBanner.Font = Enum.Font.GothamBold
toastBanner.TextSize = 11
toastBanner.TextWrapped = true
toastBanner.TextColor3 = Color3.fromRGB(235, 245, 255)
toastBanner.Visible = false
toastBanner.ZIndex = 30
toastBanner.Parent = screenGui
local toastPad = Instance.new("UIPadding", toastBanner)
toastPad.PaddingLeft = UDim.new(0, 10)
toastPad.PaddingRight = UDim.new(0, 10)
Instance.new("UICorner", toastBanner).CornerRadius = UDim.new(0, 8)
local toastStroke = Instance.new("UIStroke", toastBanner)
toastStroke.Color = Color3.fromRGB(65, 185, 235)
toastStroke.Thickness = 1.2

local toastSeq = 0
local function showToast(ok, message)
	toastSeq = toastSeq + 1
	local mySeq = toastSeq
	toastBanner.Text = tostring(message or "")
	toastStroke.Color = ok and Color3.fromRGB(70, 225, 145) or Color3.fromRGB(235, 85, 85)
	toastBanner.TextColor3 = ok and Color3.fromRGB(215, 255, 232) or Color3.fromRGB(255, 210, 210)
	toastBanner.Visible = true

	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = "[KMUTNB] " .. tostring(message),
			Color = ok and Color3.fromRGB(120, 240, 175) or Color3.fromRGB(255, 130, 130),
		})
	end)

	task.delay(6.0, function()
		if toastSeq == mySeq then
			toastBanner.Visible = false
		end
	end)
end

local puzzleModal = nil
if submitPuzzleFn then
	-- Server StateChanged broadcasts the single canonical completion notice; no duplicate client callback needed.
	puzzleModal = CCTVPuzzleModal.mount(submitPuzzleFn, nil)
end

local staffPhone = StaffPhoneUI.mount(phoneActionFn, stateRequest)
phoneBtn.MouseButton1Click:Connect(function()
	staffPhone.toggle()
end)

UIStateManager.onChanged(function(hasModal)
	panel.Visible = not hasModal
	phoneBtn.Visible = not hasModal
end)
panel.Visible = not UIStateManager.isModalOpen()
phoneBtn.Visible = not UIStateManager.isModalOpen()

local function openSafeKeypadUI()
	local modal = resolveUIModule("BankSafeKeypadModal") or BankSafeKeypadModal
	if modal and modal.open then
		modal.open()
	else
		warn("[MissionController] BankSafeKeypadModal could not be resolved.")
	end
end

local function openEmergencyMemoUI(customPayload)
	local memo = resolveUIModule("EmergencyMemoModal") or EmergencyMemoModal
	if memo and memo.open then
		memo.open(customPayload)
	else
		warn("[MissionController] EmergencyMemoModal could not be resolved.")
	end
end

local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who and who ~= player then return end
	local pName = prompt.Name
	local parentName = prompt.Parent and prompt.Parent.Name or ""

	if pName == "SafeKeypadPrompt" or parentName == "SafeKeypadPlate" or parentName:find("Safe") then
		openSafeKeypadUI()
	elseif pName == "ManagerNotePrompt" or parentName == "ManagerMemoPad" then
		openEmergencyMemoUI()
	end
end)

-- Direct client listener for bank room prompts to guarantee 100% responsiveness
local function bindPromptClient(prompt)
	if not prompt:IsA("ProximityPrompt") then return end
	if prompt:GetAttribute("_BoundBankClient") then return end
	local pName = prompt.Name
	local parentName = prompt.Parent and prompt.Parent.Name or ""
	if pName == "SafeKeypadPrompt" or parentName == "SafeKeypadPlate" then
		prompt:SetAttribute("_BoundBankClient", true)
		prompt.Triggered:Connect(function(who)
			if who and who ~= player then return end
			openSafeKeypadUI()
		end)
	elseif pName == "ManagerNotePrompt" or parentName == "ManagerMemoPad" then
		prompt:SetAttribute("_BoundBankClient", true)
		prompt.Triggered:Connect(function(who)
			if who and who ~= player then return end
			openEmergencyMemoUI()
		end)
	end
end

for _, d in ipairs(Workspace:GetDescendants()) do
	bindPromptClient(d)
end
Workspace.DescendantAdded:Connect(bindPromptClient)

if openPuzzleModalEvent and puzzleModal then
	openPuzzleModalEvent.OnClientEvent:Connect(function(payload)
		puzzleModal.open(payload)
	end)
end

if openBankSafeKeypadEvent then
	openBankSafeKeypadEvent.OnClientEvent:Connect(function()
		openSafeKeypadUI()
	end)
end

if showEmergencyMemoEvent then
	showEmergencyMemoEvent.OnClientEvent:Connect(function(customPayload)
		openEmergencyMemoUI(customPayload)
	end)
end

if devFeedbackEvent then
	devFeedbackEvent.OnClientEvent:Connect(function(ok, text)
		showToast(ok == true, text)
	end)
end

local function refreshModeBadge()
	local isLocalDev = player:GetAttribute(NetProtocol.Attributes.DevModeActive) == true
	if isLocalDev then
		modeBadge.Text = "โหมดผู้พัฒนา (!dev)"
		modeBadge.BackgroundColor3 = Color3.fromRGB(72, 54, 16)
		modeBadge.TextColor3 = Color3.fromRGB(255, 224, 102)
	else
		modeBadge.Text = "โหมดเนื้อเรื่อง"
		modeBadge.BackgroundColor3 = Color3.fromRGB(26, 34, 46)
		modeBadge.TextColor3 = Color3.fromRGB(175, 195, 218)
	end
end

player:GetAttributeChangedSignal(NetProtocol.Attributes.DevModeActive):Connect(refreshModeBadge)
refreshModeBadge()

local lastNoticeSeq = nil
local function render(snapshot)
	if type(snapshot) ~= "table" then return end

	-- Close CCTV Puzzle modal cleanly when solved by any teammate or reset/locked by server/!mission reset
	if puzzleModal and (
		snapshot.puzzleSolved == true
		or not snapshot.securityDoorUnlocked
		or snapshot.missionId ~= "M1"
		or snapshot.missionState == NetProtocol.MissionState.COMPLETED
	) then
		puzzleModal.close()
	end

	refreshModeBadge()

	if snapshot.missionState == NetProtocol.MissionState.COMPLETED then
		eyebrow.Text = string.format("%s // สำเร็จแล้ว", snapshot.missionCode or "MISSION 01")
		eyebrow.TextColor3 = Color3.fromRGB(80, 235, 150)
		stroke.Color = Color3.fromRGB(65, 210, 135)
		title.Text = (snapshot.missionName or "FIRST CONTACT") .. " — ผ่านภารกิจ!"
		if snapshot.nextMission then
			description.Text = string.format(
				"ปลดล็อก %s (%s) — สถานะ: %s",
				snapshot.nextMission.code or "M2",
				snapshot.nextMission.name or "RESTORE POWER",
				snapshot.nextMission.implementationStatus or "NOT IMPLEMENTED"
			)
		else
			description.Text = "เสร็จสิ้นภารกิจทั้งหมดในเฟสนี้แล้ว"
		end
	else
		eyebrow.Text = string.format(
			"%s // %s (%d/%d)",
			snapshot.missionCode or "MISSION 01",
			snapshot.missionName or "FIRST CONTACT",
			tonumber(snapshot.completedSubCount) or 0,
			tonumber(snapshot.totalSubCount) or 4
		)
		eyebrow.TextColor3 = Color3.fromRGB(240, 88, 78)
		stroke.Color = Color3.fromRGB(175, 45, 55)
		title.Text = snapshot.activeObjectiveTitle or snapshot.currentTitle or "MISSION 01"
		description.Text = snapshot.activeObjectiveDetail or snapshot.currentDesc or ""
	end

	-- NO FREE INFORMATION: never render location spoilers on checklist rows
	local subs = snapshot.objectives or {}
	for i = 1, 4 do
		local row = stepRows[i]
		local sub = subs[i]
		if sub then
			row.Visible = true
			if sub.completed then
				row.Text = string.format("✓ %s", sub.title)
				row.TextColor3 = Color3.fromRGB(95, 225, 145)
			elseif sub.state == NetProtocol.MissionState.ACTIVE or sub.state == NetProtocol.MissionState.AVAILABLE then
				row.Text = string.format("▶ %s", sub.title)
				row.TextColor3 = Color3.fromRGB(255, 215, 110)
			else
				row.Text = string.format("• %s (ล็อกอยู่)", sub.title)
				row.TextColor3 = Color3.fromRGB(120, 132, 148)
			end
		else
			row.Visible = false
		end
	end

	local keyText = snapshot.hasKeycard and "คีย์การ์ด T1" or "ยังไม่มีบัตร"
	local tierText = "Tier " .. tostring(snapshot.floorClearanceTier or 0)
	local pwrText = snapshot.buildingPowerOn and "ไฟตึก: เปิด" or "ไฟตึก: ดับ"
	local zText = (snapshot.zombieMode == "Free" and "FREE") or "CAMPAIGN"
	footer.Text = string.format("%s  •  %s  •  %s  •  %s", keyText, tierText, pwrText, zText)

	local unread = (snapshot.phone and tonumber(snapshot.phone.unreadCount)) or 0
	if unread > 0 then
		phoneBtn.Text = string.format("📱 โทรศัพท์เจ้าหน้าที่ [P]  •  มี %d ข้อความใหม่", unread)
		phoneStroke.Color = Color3.fromRGB(250, 200, 75)
	else
		phoneBtn.Text = "📱 โทรศัพท์เจ้าหน้าที่ [P]  •  บันทึก / ข้อความ / แผนที่"
		phoneStroke.Color = Color3.fromRGB(55, 165, 220)
	end

	refreshHoldoutBanner()

	if staffPhone then
		staffPhone.updateSnapshot(snapshot)
	end

	local seq = tonumber(snapshot.noticeSeq)
	if type(snapshot.notice) == "string" and snapshot.notice ~= "" and seq ~= nil then
		local isFirstBoot = (lastNoticeSeq == nil)
		if seq ~= lastNoticeSeq then
			lastNoticeSeq = seq
			if not isFirstBoot then
				showToast(true, snapshot.notice)
			end
		end
	end
end

stateChanged.OnClientEvent:Connect(render)
stateRequest:FireServer()
