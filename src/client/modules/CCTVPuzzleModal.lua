-- Interactive M1 CCTV Timeline Reconstruction Modal.
-- Displays sanitized server frames + clearly labeled PROTOTYPE placeholder still frames.
-- Zero puzzle answers live on the client; ordering is validated 100% by the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UIStateManager = require(script.Parent:WaitForChild("UIStateManager"))

local CCTVPuzzleModal = {}

local MODAL_ID = "CCTVPuzzle"

function CCTVPuzzleModal.mount(submitPuzzleFn, onSolvedNotice)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("CCTVPuzzleHUD")
	if old then
		old:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CCTVPuzzleHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 45
	screenGui.Parent = playerGui

	-- Invisible modal click-blocker / mouse-unlocker while open
	local modalOverlay = Instance.new("TextButton")
	modalOverlay.Name = "ModalBackdrop"
	modalOverlay.Size = UDim2.fromScale(1, 1)
	modalOverlay.BackgroundColor3 = Color3.fromRGB(4, 7, 12)
	modalOverlay.BackgroundTransparency = 0.42
	modalOverlay.BorderSizePixel = 0
	modalOverlay.Text = ""
	modalOverlay.AutoButtonColor = false
	modalOverlay.Modal = true
	modalOverlay.Visible = false
	modalOverlay.ZIndex = 1
	modalOverlay.Parent = screenGui

	local win = Instance.new("Frame")
	win.Name = "PuzzleWindow"
	win.AnchorPoint = Vector2.new(0.5, 0.5)
	win.Position = UDim2.fromScale(0.5, 0.5)
	win.Size = UDim2.new(0, 700, 0, 520)
	win.BackgroundColor3 = Color3.fromRGB(13, 17, 25)
	win.BorderSizePixel = 0
	win.ZIndex = 2
	win.Parent = modalOverlay
	Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)

	local winStroke = Instance.new("UIStroke", win)
	winStroke.Color = Color3.fromRGB(60, 175, 225)
	winStroke.Thickness = 1.6
	winStroke.Transparency = 0.2

	-- Header bar
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 64)
	header.BackgroundColor3 = Color3.fromRGB(18, 25, 36)
	header.BorderSizePixel = 0
	header.ZIndex = 3
	header.Parent = win
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Position = UDim2.new(0, 18, 0, 8)
	titleLabel.Size = UDim2.new(1, -150, 0, 22)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 15
	titleLabel.TextColor3 = Color3.fromRGB(240, 246, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "CCTV TIMELINE RECONSTRUCTION // ROOM 102"
	titleLabel.ZIndex = 4
	titleLabel.Parent = header

	local protoBadge = Instance.new("TextLabel")
	protoBadge.Position = UDim2.new(0, 18, 0, 32)
	protoBadge.Size = UDim2.new(1, -150, 0, 22)
	protoBadge.BackgroundTransparency = 1
	protoBadge.Font = Enum.Font.Gotham
	protoBadge.TextSize = 11
	protoBadge.TextColor3 = Color3.fromRGB(255, 198, 92)
	protoBadge.TextXAlignment = Enum.TextXAlignment.Left
	protoBadge.Text = "PROTOTYPE UI // PLACEHOLDER CCTV FOOTAGE STILLS — Check F1 Incident Logs"
	protoBadge.ZIndex = 4
	protoBadge.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -14, 0.5, 0)
	closeBtn.Size = UDim2.new(0, 74, 0, 30)
	closeBtn.BackgroundColor3 = Color3.fromRGB(120, 35, 42)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 12
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "CLOSE"
	closeBtn.ZIndex = 4
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

	-- Instructions line
	local instrLabel = Instance.new("TextLabel")
	instrLabel.Position = UDim2.new(0, 18, 0, 72)
	instrLabel.Size = UDim2.new(1, -36, 0, 22)
	instrLabel.BackgroundTransparency = 1
	instrLabel.Font = Enum.Font.Gotham
	instrLabel.TextSize = 12
	instrLabel.TextColor3 = Color3.fromRGB(185, 202, 224)
	instrLabel.TextXAlignment = Enum.TextXAlignment.Left
	instrLabel.Text = "Click a camera clip below to assign it to the next empty timeline slot (1 Earliest -> 4 Latest):"
	instrLabel.ZIndex = 3
	instrLabel.Parent = win

	-- 4 Timeline Slots Row (1..4)
	local slotsRow = Instance.new("Frame")
	slotsRow.Position = UDim2.new(0, 18, 0, 100)
	slotsRow.Size = UDim2.new(1, -36, 0, 96)
	slotsRow.BackgroundColor3 = Color3.fromRGB(9, 13, 20)
	slotsRow.BorderSizePixel = 0
	slotsRow.ZIndex = 3
	slotsRow.Parent = win
	Instance.new("UICorner", slotsRow).CornerRadius = UDim.new(0, 8)
	local slotsPad = Instance.new("UIPadding", slotsRow)
	slotsPad.PaddingLeft = UDim.new(0, 8)
	slotsPad.PaddingRight = UDim.new(0, 8)
	slotsPad.PaddingTop = UDim.new(0, 8)
	slotsPad.PaddingBottom = UDim.new(0, 8)
	local slotsLayout = Instance.new("UIGridLayout", slotsRow)
	slotsLayout.CellPadding = UDim2.new(0, 8, 0, 0)
	slotsLayout.CellSize = UDim2.new(0.25, -6, 1, 0)
	slotsLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local slotButtons = {}
	local slotTitleLabels = {}
	local slotDetailLabels = {}

	-- 4 Available CCTV Clip Cards (2x2 grid)
	local cardsGrid = Instance.new("Frame")
	cardsGrid.Position = UDim2.new(0, 18, 0, 206)
	cardsGrid.Size = UDim2.new(1, -36, 0, 212)
	cardsGrid.BackgroundTransparency = 1
	cardsGrid.ZIndex = 3
	cardsGrid.Parent = win
	local cardsLayout = Instance.new("UIGridLayout", cardsGrid)
	cardsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	cardsLayout.CellSize = UDim2.new(0.5, -5, 0.5, -5)
	cardsLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- Server feedback status bar
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Position = UDim2.new(0, 18, 0, 428)
	statusLabel.Size = UDim2.new(1, -36, 0, 28)
	statusLabel.BackgroundColor3 = Color3.fromRGB(18, 24, 34)
	statusLabel.BorderSizePixel = 0
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 12
	statusLabel.TextColor3 = Color3.fromRGB(165, 210, 240)
	statusLabel.Text = "Select 4 clips to reconstruct the Floor 1 breach sequence."
	statusLabel.ZIndex = 3
	statusLabel.Parent = win
	Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

	-- Footer action buttons
	local clearBtn = Instance.new("TextButton")
	clearBtn.Position = UDim2.new(0, 18, 1, -50)
	clearBtn.Size = UDim2.new(0, 140, 0, 36)
	clearBtn.BackgroundColor3 = Color3.fromRGB(48, 56, 70)
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextSize = 13
	clearBtn.TextColor3 = Color3.fromRGB(235, 240, 248)
	clearBtn.Text = "RESET SLOTS"
	clearBtn.ZIndex = 4
	clearBtn.Parent = win
	Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 7)

	local submitBtn = Instance.new("TextButton")
	submitBtn.AnchorPoint = Vector2.new(1, 0)
	submitBtn.Position = UDim2.new(1, -18, 1, -50)
	submitBtn.Size = UDim2.new(0, 230, 0, 36)
	submitBtn.BackgroundColor3 = Color3.fromRGB(32, 138, 192)
	submitBtn.Font = Enum.Font.GothamBold
	submitBtn.TextSize = 13
	submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	submitBtn.Text = "SUBMIT TIMELINE TO SERVER"
	submitBtn.ZIndex = 4
	submitBtn.Parent = win
	Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 7)

	-- State
	local framesById = {}
	local orderedFrames = {}
	local selectedSlots = { nil, nil, nil, nil }
	local cardSlotBadges = {}
	local isSubmitting = false

	for s = 1, 4 do
		local slotBtn = Instance.new("TextButton")
		slotBtn.Name = "Slot_" .. s
		slotBtn.LayoutOrder = s
		slotBtn.BackgroundColor3 = Color3.fromRGB(20, 28, 40)
		slotBtn.Text = ""
		slotBtn.AutoButtonColor = true
		slotBtn.ZIndex = 4
		slotBtn.Parent = slotsRow
		Instance.new("UICorner", slotBtn).CornerRadius = UDim.new(0, 7)

		local st = Instance.new("UIStroke", slotBtn)
		st.Color = Color3.fromRGB(70, 95, 125)
		st.Thickness = 1.2

		local hdr = Instance.new("TextLabel")
		hdr.Size = UDim2.new(1, -12, 0, 20)
		hdr.Position = UDim2.new(0, 6, 0, 5)
		hdr.BackgroundTransparency = 1
		hdr.Font = Enum.Font.GothamBold
		hdr.TextSize = 11
		hdr.TextColor3 = Color3.fromRGB(115, 215, 255)
		hdr.Text = (s == 1 and "#1 EARLIEST") or (s == 4 and "#4 LATEST") or ("#" .. s .. " EVENT")
		hdr.ZIndex = 5
		hdr.Parent = slotBtn

		local val = Instance.new("TextLabel")
		val.Size = UDim2.new(1, -12, 0, 48)
		val.Position = UDim2.new(0, 6, 0, 26)
		val.BackgroundTransparency = 1
		val.Font = Enum.Font.GothamBold
		val.TextSize = 11
		val.TextWrapped = true
		val.TextColor3 = Color3.fromRGB(180, 194, 212)
		val.Text = "[ EMPTY ]"
		val.ZIndex = 5
		val.Parent = slotBtn

		slotButtons[s] = slotBtn
		slotTitleLabels[s] = hdr
		slotDetailLabels[s] = val

		slotBtn.MouseButton1Click:Connect(function()
			if selectedSlots[s] then
				selectedSlots[s] = nil
				-- Refresh visual UI
				for idx = 1, 4 do
					local cid = selectedSlots[idx]
					local f = cid and framesById[cid]
					slotDetailLabels[idx].Text = f and f.camLabel or "[ EMPTY ]"
					slotDetailLabels[idx].TextColor3 = f and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 165, 185)
				end
				for fid, badge in pairs(cardSlotBadges) do
					local foundSlot = nil
					for idx = 1, 4 do
						if selectedSlots[idx] == fid then
							foundSlot = idx
							break
						end
					end
					badge.Text = foundSlot and ("SLOT #" .. foundSlot) or "CLICK TO ASSIGN"
					badge.TextColor3 = foundSlot and Color3.fromRGB(90, 240, 160) or Color3.fromRGB(145, 195, 230)
				end
			end
		end)
	end

	local function refreshSlotsUI()
		local filled = 0
		for s = 1, 4 do
			local cid = selectedSlots[s]
			local f = cid and framesById[cid]
			slotDetailLabels[s].Text = f and f.camLabel or "[ EMPTY ]"
			slotDetailLabels[s].TextColor3 = f and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 165, 185)
			if f then
				filled = filled + 1
			end
		end
		for fid, badge in pairs(cardSlotBadges) do
			local foundSlot = nil
			for s = 1, 4 do
				if selectedSlots[s] == fid then
					foundSlot = s
					break
				end
			end
			badge.Text = foundSlot and ("ASSIGNED: SLOT #" .. foundSlot) or "CLICK TO ASSIGN"
			badge.TextColor3 = foundSlot and Color3.fromRGB(90, 240, 160) or Color3.fromRGB(145, 195, 230)
		end
		submitBtn.BackgroundColor3 = (filled == 4) and Color3.fromRGB(32, 165, 115) or Color3.fromRGB(48, 66, 85)
	end

	local function buildClipCards(frames)
		for _, child in ipairs(cardsGrid:GetChildren()) do
			if not child:IsA("UIGridLayout") then
				child:Destroy()
			end
		end
		table.clear(framesById)
		table.clear(cardSlotBadges)
		orderedFrames = frames or {}

		for idx, frameData in ipairs(orderedFrames) do
			framesById[frameData.id] = frameData
			local card = Instance.new("TextButton")
			card.Name = "Clip_" .. frameData.id
			card.LayoutOrder = idx
			card.BackgroundColor3 = Color3.fromRGB(19, 25, 36)
			card.BorderSizePixel = 0
			card.Text = ""
			card.AutoButtonColor = true
			card.ZIndex = 4
			card.Parent = cardsGrid
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
			local cStroke = Instance.new("UIStroke", card)
			cStroke.Color = Color3.fromRGB(65, 92, 125)
			cStroke.Thickness = 1.2

			local camHdr = Instance.new("TextLabel")
			camHdr.Position = UDim2.new(0, 10, 0, 6)
			camHdr.Size = UDim2.new(1, -20, 0, 18)
			camHdr.BackgroundTransparency = 1
			camHdr.Font = Enum.Font.GothamBold
			camHdr.TextSize = 12
			camHdr.TextXAlignment = Enum.TextXAlignment.Left
			camHdr.TextColor3 = Color3.fromRGB(110, 220, 255)
			camHdr.Text = frameData.camLabel
			camHdr.ZIndex = 5
			camHdr.Parent = card

			local metaTag = Instance.new("TextLabel")
			metaTag.Position = UDim2.new(0, 10, 0, 24)
			metaTag.Size = UDim2.new(1, -20, 0, 14)
			metaTag.BackgroundTransparency = 1
			metaTag.Font = Enum.Font.Code
			metaTag.TextSize = 10
			metaTag.TextXAlignment = Enum.TextXAlignment.Left
			metaTag.TextColor3 = Color3.fromRGB(245, 190, 95)
			metaTag.Text = string.format("%s  |  %s", frameData.timeStampLabel, frameData.prototypeTag or "PROTOTYPE STILL")
			metaTag.ZIndex = 5
			metaTag.Parent = card

			local cap = Instance.new("TextLabel")
			cap.Position = UDim2.new(0, 10, 0, 40)
			cap.Size = UDim2.new(1, -20, 0, 38)
			cap.BackgroundTransparency = 1
			cap.Font = Enum.Font.Gotham
			cap.TextSize = 11
			cap.TextWrapped = true
			cap.TextXAlignment = Enum.TextXAlignment.Left
			cap.TextYAlignment = Enum.TextYAlignment.Top
			cap.TextColor3 = Color3.fromRGB(220, 228, 238)
			cap.Text = frameData.caption
			cap.ZIndex = 5
			cap.Parent = card

			local assignBadge = Instance.new("TextLabel")
			assignBadge.Position = UDim2.new(0, 10, 1, -20)
			assignBadge.Size = UDim2.new(1, -20, 0, 14)
			assignBadge.BackgroundTransparency = 1
			assignBadge.Font = Enum.Font.GothamBold
			assignBadge.TextSize = 10
			assignBadge.TextXAlignment = Enum.TextXAlignment.Right
			assignBadge.TextColor3 = Color3.fromRGB(145, 195, 230)
			assignBadge.Text = "CLICK TO ASSIGN"
			assignBadge.ZIndex = 5
			assignBadge.Parent = card
			cardSlotBadges[frameData.id] = assignBadge

			card.MouseButton1Click:Connect(function()
				-- If already placed in a slot, remove it; otherwise place into first open slot 1..4
				for s = 1, 4 do
					if selectedSlots[s] == frameData.id then
						selectedSlots[s] = nil
						refreshSlotsUI()
						return
					end
				end
				for s = 1, 4 do
					if selectedSlots[s] == nil then
						selectedSlots[s] = frameData.id
						refreshSlotsUI()
						return
					end
				end
			end)
		end
	end

	local controller = {}

	function controller.close()
		if modalOverlay.Visible then
			modalOverlay.Visible = false
			UIStateManager.closeModal(MODAL_ID)
		end
	end

	function controller.open(payload)
		if type(payload) ~= "table" then return end
		titleLabel.Text = payload.title or "CCTV TIMELINE RECONSTRUCTION // ROOM 102"
		protoBadge.Text = payload.prototypeNotice or "PROTOTYPE UI // PLACEHOLDER CCTV FOOTAGE STILLS"
		instrLabel.Text = payload.subtitle or instrLabel.Text
		selectedSlots = { nil, nil, nil, nil }
		buildClipCards(payload.frames)
		refreshSlotsUI()
		statusLabel.TextColor3 = Color3.fromRGB(165, 210, 240)
		statusLabel.Text = "Assign all 4 camera clips in chronological order (1 -> 4), then click Submit."
		modalOverlay.Visible = true
		UIStateManager.openModal(MODAL_ID, function()
			modalOverlay.Visible = false
		end)
	end

	closeBtn.MouseButton1Click:Connect(controller.close)

	clearBtn.MouseButton1Click:Connect(function()
		selectedSlots = { nil, nil, nil, nil }
		refreshSlotsUI()
	end)

	submitBtn.MouseButton1Click:Connect(function()
		if isSubmitting then return end
		local seq = {}
		for s = 1, 4 do
			if not selectedSlots[s] then
				statusLabel.TextColor3 = Color3.fromRGB(255, 185, 85)
				statusLabel.Text = "Please fill all 4 timeline slots before submitting."
				return
			end
			seq[s] = selectedSlots[s]
		end

		isSubmitting = true
		submitBtn.Text = "VERIFYING..."
		local okCall, res = pcall(function()
			return submitPuzzleFn:InvokeServer(seq)
		end)
		isSubmitting = false
		submitBtn.Text = "SUBMIT TIMELINE TO SERVER"

		if not okCall or type(res) ~= "table" then
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 105)
			statusLabel.Text = "Server error submitting sequence. Try again."
			return
		end

		if res.solved then
			statusLabel.TextColor3 = Color3.fromRGB(85, 245, 155)
			statusLabel.Text = res.message or "TIMELINE VERIFIED!"
			if onSolvedNotice then
				onSolvedNotice(res.message)
			end
			controller.close()
		else
			statusLabel.TextColor3 = Color3.fromRGB(255, 120, 105)
			statusLabel.Text = res.message or "Sequence mismatch. Check F1 Incident Logs."
		end
	end)

	UserInputService.InputBegan:Connect(function(input)
		if modalOverlay.Visible and input.KeyCode == Enum.KeyCode.Escape then
			controller.close()
		end
	end)

	return controller
end

return CCTVPuzzleModal
