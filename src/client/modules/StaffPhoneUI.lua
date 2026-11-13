-- Interactive KMUTNB Staff Phone UI for INFECTED-KMUTNB.
-- 5 Tabs: Notes | Messages | Inventory | Status | Map
-- Strictly read-only presentation of server-authoritative StateChanged snapshots.
-- Zero item coordinate spoilers ("NO FREE INFORMATION"); integrates with UIStateManager.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ClientModules = script.Parent
local UIStateManager = require(ClientModules:WaitForChild("UIStateManager"))

local StaffPhoneUI = {}

local MODAL_ID = "StaffPhone"
local TABS = { "Notes", "Messages", "Inventory", "Status", "Map" }

local function styleCorner(inst, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = inst
	return c
end

local function styleStroke(inst, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1.2
	s.Transparency = transparency or 0.25
	s.Parent = inst
	return s
end

local function clearScrollingChildren(scrollingFrame)
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

function StaffPhoneUI.mount(phoneActionFn, stateRequestEvent)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("StaffPhoneHUD")
	if old then
		old:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StaffPhoneHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 40
	screenGui.Parent = playerGui

	-- Backdrop unlocker (frees mouse in First-Person mode cleanly)
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "PhoneBackdrop"
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

	-- Smartphone chassis centered right
	local chassis = Instance.new("Frame")
	chassis.Name = "PhoneChassis"
	chassis.AnchorPoint = Vector2.new(0.5, 0.5)
	chassis.Position = UDim2.fromScale(0.5, 0.5)
	chassis.Size = UDim2.new(0, 560, 0, 620)
	chassis.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
	chassis.BorderSizePixel = 0
	chassis.ZIndex = 2
	chassis.Parent = backdrop
	styleCorner(chassis, 18)
	styleStroke(chassis, Color3.fromRGB(70, 175, 225), 1.8, 0.2)

	-- Top Status Bar
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, -24, 0, 44)
	topBar.Position = UDim2.new(0, 12, 0, 10)
	topBar.BackgroundColor3 = Color3.fromRGB(18, 24, 34)
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 3
	topBar.Parent = chassis
	styleCorner(topBar, 10)

	local phoneTitle = Instance.new("TextLabel")
	phoneTitle.Size = UDim2.new(0.7, 0, 1, 0)
	phoneTitle.Position = UDim2.new(0, 14, 0, 0)
	phoneTitle.BackgroundTransparency = 1
	phoneTitle.Font = Enum.Font.GothamBold
	phoneTitle.TextSize = 14
	phoneTitle.TextXAlignment = Enum.TextXAlignment.Left
	phoneTitle.TextColor3 = Color3.fromRGB(125, 220, 255)
	phoneTitle.Text = "KMUTNB STAFF PHONE // B40 FIELD OS"
	phoneTitle.ZIndex = 4
	phoneTitle.Parent = topBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -10, 0.5, 0)
	closeBtn.Size = UDim2.new(0, 74, 0, 26)
	closeBtn.BackgroundColor3 = Color3.fromRGB(145, 42, 52)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 11
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "CLOSE [P]"
	closeBtn.ZIndex = 4
	closeBtn.Parent = topBar
	styleCorner(closeBtn, 6)

	-- 5 Tab Row
	local tabBar = Instance.new("Frame")
	tabBar.Position = UDim2.new(0, 12, 0, 62)
	tabBar.Size = UDim2.new(1, -24, 0, 34)
	tabBar.BackgroundTransparency = 1
	tabBar.ZIndex = 3
	tabBar.Parent = chassis

	local tabLayout = Instance.new("UIListLayout", tabBar)
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local tabButtons = {}
	for idx, tabName in ipairs(TABS) do
		local btn = Instance.new("TextButton")
		btn.Name = "Tab_" .. tabName
		btn.LayoutOrder = idx
		btn.Size = UDim2.new(0.2, -5, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(24, 32, 46)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.TextColor3 = Color3.fromRGB(185, 200, 220)
		btn.Text = string.upper(tabName)
		btn.ZIndex = 4
		btn.Parent = tabBar
		styleCorner(btn, 7)
		tabButtons[tabName] = btn
	end

	-- Main Content Scrolling List + Reader Preview Box (bottom strip for Notes/Messages)
	local contentScroll = Instance.new("ScrollingFrame")
	contentScroll.Name = "ContentList"
	contentScroll.Position = UDim2.new(0, 12, 0, 104)
	contentScroll.Size = UDim2.new(1, -24, 1, -236)
	contentScroll.BackgroundColor3 = Color3.fromRGB(16, 21, 30)
	contentScroll.BorderSizePixel = 0
	contentScroll.ScrollBarThickness = 5
	contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentScroll.ZIndex = 3
	contentScroll.Parent = chassis
	styleCorner(contentScroll, 10)

	local listLayout = Instance.new("UIListLayout", contentScroll)
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local listPad = Instance.new("UIPadding", contentScroll)
	listPad.PaddingTop = UDim.new(0, 8)
	listPad.PaddingBottom = UDim.new(0, 8)
	listPad.PaddingLeft = UDim.new(0, 8)
	listPad.PaddingRight = UDim.new(0, 8)

	local detailCard = Instance.new("Frame")
	detailCard.Name = "DetailCard"
	detailCard.Position = UDim2.new(0, 12, 1, -124)
	detailCard.Size = UDim2.new(1, -24, 0, 112)
	detailCard.BackgroundColor3 = Color3.fromRGB(20, 27, 38)
	detailCard.BorderSizePixel = 0
	detailCard.ZIndex = 3
	detailCard.Parent = chassis
	styleCorner(detailCard, 10)
	styleStroke(detailCard, Color3.fromRGB(58, 120, 165), 1, 0.35)

	local detailTitle = Instance.new("TextLabel")
	detailTitle.Position = UDim2.new(0, 12, 0, 8)
	detailTitle.Size = UDim2.new(1, -24, 0, 20)
	detailTitle.BackgroundTransparency = 1
	detailTitle.Font = Enum.Font.GothamBold
	detailTitle.TextSize = 12
	detailTitle.TextXAlignment = Enum.TextXAlignment.Left
	detailTitle.TextColor3 = Color3.fromRGB(130, 225, 255)
	detailTitle.Text = "SELECT AN ITEM TO INSPECT"
	detailTitle.ZIndex = 4
	detailTitle.Parent = detailCard

	local detailBody = Instance.new("TextLabel")
	detailBody.Position = UDim2.new(0, 12, 0, 30)
	detailBody.Size = UDim2.new(1, -24, 1, -38)
	detailBody.BackgroundTransparency = 1
	detailBody.Font = Enum.Font.Gotham
	detailBody.TextSize = 11
	detailBody.TextWrapped = true
	detailBody.TextXAlignment = Enum.TextXAlignment.Left
	detailBody.TextYAlignment = Enum.TextYAlignment.Top
	detailBody.TextColor3 = Color3.fromRGB(218, 228, 240)
	detailBody.Text = "Inspect notes, incoming emergency alerts, team inventory, mission clearance, or Building 40 floor status."
	detailBody.ZIndex = 4
	detailBody.Parent = detailCard

	local currentTab = "Notes"
	local currentSnapshot = nil
	local selectedDetail = nil

	local function makeCardRow(order, titleText, subtitleText, accentColor, isClickable, onClick)
		local rowClass = isClickable and "TextButton" or "Frame"
		local card = Instance.new(rowClass)
		card.LayoutOrder = order
		card.Size = UDim2.new(1, 0, 0, 56)
		card.BackgroundColor3 = Color3.fromRGB(24, 31, 44)
		card.BorderSizePixel = 0
		card.ZIndex = 4
		if isClickable then
			card.Text = ""
			card.AutoButtonColor = true
		end
		card.Parent = contentScroll
		styleCorner(card, 7)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 4, 1, -10)
		bar.Position = UDim2.new(0, 6, 0, 5)
		bar.BackgroundColor3 = accentColor or Color3.fromRGB(70, 175, 225)
		bar.BorderSizePixel = 0
		bar.ZIndex = 5
		bar.Parent = card
		styleCorner(bar, 2)

		local tLbl = Instance.new("TextLabel")
		tLbl.Position = UDim2.new(0, 18, 0, 6)
		tLbl.Size = UDim2.new(1, -26, 0, 20)
		tLbl.BackgroundTransparency = 1
		tLbl.Font = Enum.Font.GothamBold
		tLbl.TextSize = 12
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.TextTruncate = Enum.TextTruncate.AtEnd
		tLbl.TextColor3 = Color3.fromRGB(238, 244, 252)
		tLbl.Text = titleText
		tLbl.ZIndex = 5
		tLbl.Parent = card

		local sLbl = Instance.new("TextLabel")
		sLbl.Position = UDim2.new(0, 18, 0, 27)
		sLbl.Size = UDim2.new(1, -26, 0, 22)
		sLbl.BackgroundTransparency = 1
		sLbl.Font = Enum.Font.Gotham
		sLbl.TextSize = 10
		sLbl.TextXAlignment = Enum.TextXAlignment.Left
		sLbl.TextTruncate = Enum.TextTruncate.AtEnd
		sLbl.TextColor3 = Color3.fromRGB(165, 182, 204)
		sLbl.Text = subtitleText
		sLbl.ZIndex = 5
		sLbl.Parent = card

		if isClickable and onClick then
			card.MouseButton1Click:Connect(onClick)
		end
		return card
	end

	local function refreshTabView()
		for tName, btn in pairs(tabButtons) do
			if tName == currentTab then
				btn.BackgroundColor3 = Color3.fromRGB(45, 128, 178)
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				btn.BackgroundColor3 = Color3.fromRGB(24, 32, 46)
				btn.TextColor3 = Color3.fromRGB(170, 188, 210)
			end
		end

		clearScrollingChildren(contentScroll)
		local snap = currentSnapshot
		local phoneData = snap and snap.phone or {}

		if currentTab == "Notes" then
			local list = phoneData.notes or {}
			if #list == 0 then
				makeCardRow(1, "ยังไม่มีบันทึกเหตุการณ์", "สำรวจโต๊ะทำงาน บอร์ดประกาศ และสมุดเวรในอาคาร 40 ปี", Color3.fromRGB(120, 130, 145), false)
			else
				for i, n in ipairs(list) do
					local prefix = n.read and "" or "[ใหม่] "
					local sub = string.format("%s // ชั้น %d • บันทึกโดย %s", tostring(n.category), tonumber(n.floor) or 1, tostring(n.discoveredBy or "ทีม"))
					makeCardRow(i, prefix .. tostring(n.title), sub, n.read and Color3.fromRGB(85, 140, 175) or Color3.fromRGB(250, 205, 80), true, function()
						selectedDetail = { title = n.title, body = n.body }
						detailTitle.Text = n.title
						detailBody.Text = n.body
						n.read = true
						refreshTabView()
						if phoneActionFn then
							task.spawn(function()
								pcall(function()
									phoneActionFn:InvokeServer("MarkRead", { kind = "note", id = n.id })
								end)
							end)
						end
					end)
				end
			end
		elseif currentTab == "Messages" then
			local list = phoneData.messages or {}
			if #list == 0 then
				makeCardRow(1, "ยังไม่มีข้อความ", "ยังไม่มีรายงานการสื่อสารฉุกเฉิน", Color3.fromRGB(120, 130, 145), false)
			else
				for i, m in ipairs(list) do
					local prefix = m.read and "" or "[ยังไม่อ่าน] "
					local sub = string.format("จาก: %s • ภารกิจ %s", tostring(m.sender), tostring(m.missionId or "-"))
					makeCardRow(i, prefix .. tostring(m.subject), sub, m.read and Color3.fromRGB(70, 175, 135) or Color3.fromRGB(95, 225, 255), true, function()
						selectedDetail = { title = m.sender .. " — " .. m.subject, body = m.body }
						detailTitle.Text = selectedDetail.title
						detailBody.Text = selectedDetail.body
						m.read = true
						refreshTabView()
						if phoneActionFn then
							task.spawn(function()
								pcall(function()
									phoneActionFn:InvokeServer("MarkRead", { kind = "msg", id = m.id })
								end)
							end)
						end
					end)
				end
			end
		elseif currentTab == "Inventory" then
			local items = phoneData.inventory or {}
			local food = tonumber(player:GetAttribute("FoodPacks")) or 0
			local med = tonumber(player:GetAttribute("MedkitPacks")) or 0
			local bat = tonumber(player:GetAttribute("BatteryPacks")) or 0
			makeCardRow(1, "กระเป๋าอุปกรณ์ยังชีพส่วนตัว [4/5/6]",
				string.format("อาหาร [4]: %d   •   ชุดปฐมพยาบาล [5]: %d   •   แบตเตอรี่ [6]: %d", food, med, bat),
				Color3.fromRGB(95, 200, 145), true, function()
					detailTitle.Text = "อุปกรณ์ยังชีพส่วนตัว"
					detailBody.Text = "กดปุ่ม [4] กินอาหาร, [5] ใช้ชุดปฐมพยาบาล, [6] เปลี่ยนแบตไฟฉาย หาเพิ่มได้จากโรงอาหารชั้น 2 และตู้ซ่อมบำรุง"
				end)

			if #items == 0 then
				makeCardRow(2, "ยังไม่มีคีย์การ์ดหรือไอเทมภารกิจ", "คีย์การ์ด กุญแจ และบันทึกภารกิจที่ทีมเก็บได้จะแสดงที่นี่", Color3.fromRGB(125, 135, 150), false)
			else
				for idx, it in ipairs(items) do
					local tag = it.consumeOnUse and "ใช้ครั้งเดียว" or ("ใช้ซ้ำได้" .. ((it.clearanceTier or 0) > 0 and (" • สิทธิ์ Tier " .. tostring(it.clearanceTier)) or ""))
					makeCardRow(idx + 1,
						string.format("%s (x%d)", tostring(it.displayName), tonumber(it.quantity) or 1),
						string.format("ผู้ถือ: %s   •   %s", tostring(it.holderName or "ทีม"), tag),
						Color3.fromRGB(240, 195, 75), true, function()
							detailTitle.Text = tostring(it.displayName)
							detailBody.Text = (it.description ~= "" and it.description) or "ไอเทมภารกิจร่วมของทีม"
						end)
				end
			end
		elseif currentTab == "Status" then
			local clearTier = snap and snap.floorClearanceTier or 0
			local pwrText = (snap and snap.buildingPowerOn) and "เปิด (ONLINE)" or "ไฟฟ้าดับ (BLACKOUT)"
			local zMode = snap and snap.zombieMode or "Campaign"
			local zStats = snap and snap.zombieStats
			local zDetail = zStats and string.format("โหมด: %s | ซอมบี้ในฉาก: %d | เสียงรบกวน: %d", tostring(zStats.mode), tonumber(zStats.aliveTotal) or 0, tonumber(zStats.noiseHeat) or 0) or ("โหมด: " .. tostring(zMode))
			makeCardRow(1,
				string.format("ระดับสิทธิ์: Tier %d   •   ระบบไฟฟ้าอาคาร: %s", clearTier, pwrText),
				"ระบบซอมบี้: " .. zDetail,
				Color3.fromRGB(85, 205, 245), true, function()
					detailTitle.Text = "ข้อมูลสถานะระบบรักษาความปลอดภัยอาคาร 40 ปี"
					detailBody.Text = "Tier 0: โถงต้อนรับ | Tier 1: โซนชั้นล่าง F2-F3 และปืน Tier 1 | Tier 2: โถงกลาง F7-F10 | Tier 3: เขตกักกัน F11 | Tier 4: ดาดฟ้า F12"
				end)

			local mStates = snap and snap.missionStates or {}
			local order = { "M1", "M2", "M3", "M4" }
			local names = {
				M1 = "M1: FIRST CONTACT [พร้อมเล่น]",
				M2 = "M2: RESTORE POWER [พร้อมเล่น]",
				M3 = "M3: SIGNAL (ดาดฟ้า) [NOT IMPLEMENTED]",
				M4 = "M4: EVAC (รอเฮลิคอปเตอร์) [NOT IMPLEMENTED]",
			}
			for i, mId in ipairs(order) do
				local st = mStates[mId] or "LOCKED"
				local col = (st == "COMPLETED" and Color3.fromRGB(70, 220, 140))
					or (st == "ACTIVE" and Color3.fromRGB(250, 200, 75))
					or (st == "AVAILABLE" and Color3.fromRGB(85, 195, 245))
					or Color3.fromRGB(110, 120, 138)
				makeCardRow(i + 1, names[mId], "สถานะ: " .. tostring(st), col, false)
			end
		elseif currentTab == "Map" then
			local floors = phoneData.floors or {}
			if #floors == 0 then
				makeCardRow(1, "Building 40 Schematic Loading...", "Waiting for server floor directory sync.", Color3.fromRGB(120, 135, 150), false)
			else
				for idx = #floors, 1, -1 do
					local f = floors[idx]
					local col = f.accessible and Color3.fromRGB(70, 220, 140) or Color3.fromRGB(215, 75, 85)
					makeCardRow(#floors - idx + 1,
						string.format("F%02d — %s", f.floor, tostring(f.name)),
						string.format("[%s] Tier %d Req • %s", f.accessible and "OPEN" or "LOCKED", f.requiredTier or 0, tostring(f.statusReason)),
						col, true, function()
							detailTitle.Text = string.format("Building 40 — Floor %d (%s)", f.floor, tostring(f.zone))
							detailBody.Text = string.format("%s | Power Needed: %s | Clearance Required: Tier %d | Status: %s",
								tostring(f.name), f.requiresPower and "YES" or "NO", f.requiredTier or 0, tostring(f.statusReason))
						end)
				end
			end
		end

		if selectedDetail then
			detailTitle.Text = selectedDetail.title
			detailBody.Text = selectedDetail.body
		end
	end

	for tName, btn in pairs(tabButtons) do
		btn.MouseButton1Click:Connect(function()
			currentTab = tName
			selectedDetail = nil
			refreshTabView()
		end)
	end

	local controller = {}

	function controller.isOpen()
		return backdrop.Visible
	end

	function controller.open()
		if backdrop.Visible then
			return
		end
		backdrop.Visible = true
		UIStateManager.openModal(MODAL_ID, function()
			backdrop.Visible = false
		end)
		if stateRequestEvent then
			stateRequestEvent:FireServer()
		end
		refreshTabView()
	end

	function controller.close()
		if backdrop.Visible then
			backdrop.Visible = false
			UIStateManager.closeModal(MODAL_ID)
		end
	end

	function controller.toggle()
		if backdrop.Visible then
			controller.close()
		else
			-- Avoid stealing focus from active CCTV Puzzle solve modal
			if UIStateManager.isModalOpen("CCTVPuzzle") then
				return
			end
			controller.open()
		end
	end

	function controller.updateSnapshot(snapshot)
		currentSnapshot = snapshot
		if backdrop.Visible then
			refreshTabView()
		end
	end

	closeBtn.MouseButton1Click:Connect(controller.close)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.P then
			if backdrop.Visible then
				controller.close()
			elseif not gameProcessed and not UserInputService:GetFocusedTextBox() then
				controller.toggle()
			end
		elseif input.KeyCode == Enum.KeyCode.Escape and backdrop.Visible then
			controller.close()
		end
	end)

	return controller
end

return StaffPhoneUI
