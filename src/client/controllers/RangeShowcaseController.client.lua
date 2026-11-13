--[[
    RangeShowcaseController.client.lua
    THE RANGE — Interactive 3D Asset Showcase & Animation Lab Orchestrator.
    Coordinates isolated per-client studio stage, 4 main tabs (CHARACTERS, ZOMBIES,
    WEAPONS, ANIMATION LAB), category/search filters, 360 camera & touch/pinch controls,
    and full cleanup upon leaving INFECTED_TestRange.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local showcaseFolder = script.Parent:WaitForChild("ShowcaseModules", 10)

local StudioStageBuilder = require(showcaseFolder:WaitForChild("StudioStageBuilder"))
local PreviewCameraController = require(showcaseFolder:WaitForChild("PreviewCameraController"))
local CharacterPreviewController = require(showcaseFolder:WaitForChild("CharacterPreviewController"))
local ZombiePreviewController = require(showcaseFolder:WaitForChild("ZombiePreviewController"))
local WeaponPreviewController = require(showcaseFolder:WaitForChild("WeaponPreviewController"))
local AnimationPreviewController = require(showcaseFolder:WaitForChild("AnimationPreviewController"))

local showcaseEvents = ReplicatedStorage:FindFirstChild("ShowcaseEvents")
local stageControlEvent = showcaseEvents and showcaseEvents:FindFirstChild("StageControl")

----------------------------------------------------------------------
-- 1. PALETTE & CONSTANTS
----------------------------------------------------------------------
local COLORS = {
    BgPanel = Color3.fromRGB(14, 16, 22),
    BgCard = Color3.fromRGB(22, 26, 35),
    BgElevated = Color3.fromRGB(30, 36, 48),
    BgSelected = Color3.fromRGB(36, 68, 114),
    AccentBlue = Color3.fromRGB(62, 158, 255),
    AccentAmber = Color3.fromRGB(245, 168, 64),
    AccentGreen = Color3.fromRGB(64, 200, 134),
    AccentRed = Color3.fromRGB(235, 86, 86),
    TextPrimary = Color3.fromRGB(238, 242, 248),
    TextMuted = Color3.fromRGB(146, 156, 174),
    Border = Color3.fromRGB(48, 56, 72),
}

local FONT_REG = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_MONO = Enum.Font.Code

local MAIN_TABS = {
    { id = "CHARACTERS", label = "CHARACTERS" },
    { id = "ZOMBIES", label = "ZOMBIES" },
    { id = "WEAPONS", label = "WEAPONS" },
    { id = "ANIMATION_LAB", label = "ANIMATION LAB" },
}

local SPEED_PRESETS = { 0.25, 0.5, 1.0, 1.5, 2.0 }

----------------------------------------------------------------------
-- 2. CONTROLLERS & RUNTIME STATE
----------------------------------------------------------------------
local camCtrl = PreviewCameraController.new()
local charCtrl = CharacterPreviewController.new()
local zombieCtrl = ZombiePreviewController.new()
local weaponCtrl = WeaponPreviewController.new()
local animLab = AnimationPreviewController.new(charCtrl, zombieCtrl, weaponCtrl)

local studioStage = nil

local state = {
    inRange = false,
    studioOpen = false,
    activeTab = "ZOMBIES", -- "CHARACTERS" | "ZOMBIES" | "WEAPONS" | "ANIMATION_LAB"
    selectedCharId = "PlayerR15",
    selectedZombieId = "MaleWalker",
    selectedWeaponKey = "Vandal",
    weaponCategory = "All",
    weaponSearch = "",
    worldTpMoveActive = false,
    patrolZombieId = "MaleRunner",
    patrolMode = "Run",
    patrolRunning = false,
    lastHorizVel = Vector3.zero,
    peakSpeed = 0,
    smoothedAccel = 0,
    lastLiveStateNote = "",
}

local function isPlayerInsideRange()
    local range = Workspace:FindFirstChild("INFECTED_TestRange")
    local floor = range and range:FindFirstChild("RangeFloor")
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not floor or not floor:IsA("BasePart") or not root then
        return false
    end
    local rel = floor.CFrame:PointToObjectSpace(root.Position)
    local half = floor.Size * 0.5
    return math.abs(rel.X) <= (half.X + 3)
        and math.abs(rel.Z) <= (half.Z + 3)
        and rel.Y >= -5
        and rel.Y <= 36
end

local function clearAllPreviewModels()
    charCtrl:clear()
    zombieCtrl:clear()
    weaponCtrl:clear()
end

local function ensureStudioStage()
    if not studioStage then
        studioStage = StudioStageBuilder.create()
    end
    return studioStage
end

local function destroyStudioStage()
    clearAllPreviewModels()
    if studioStage then
        studioStage.destroy()
        studioStage = nil
    end
end

----------------------------------------------------------------------
-- 3. UI PRIMITIVES & RESPONSIVE LAYOUT
----------------------------------------------------------------------
local playerGui = player:WaitForChild("PlayerGui")
local studioGui = Instance.new("ScreenGui")
studioGui.Name = "RangeShowcaseStudioUI"
studioGui.ResetOnSpawn = false
studioGui.DisplayOrder = 25
studioGui.IgnoreGuiInset = true
studioGui.Parent = playerGui

local function addCorner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = inst
end

local function addStroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function makeButton(parent, props)
    local btn = Instance.new("TextButton")
    btn.AutoButtonColor = false
    btn.Font = props.font or FONT_REG
    btn.TextSize = props.textSize or 12
    btn.TextColor3 = props.textColor or COLORS.TextPrimary
    btn.BackgroundColor3 = props.bgColor or COLORS.BgCard
    btn.Text = props.text or ""
    btn.Size = props.size or UDim2.new(1, 0, 0, 30)
    btn.Position = props.pos or UDim2.new()
    btn.BorderSizePixel = 0
    if props.anchor then btn.AnchorPoint = props.anchor end
    addCorner(btn, props.radius or 6)
    addStroke(btn, props.strokeColor or COLORS.Border, 1)
    btn.Parent = parent
    return btn
end

local function makeLabel(parent, props)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Font = props.font or FONT_REG
    lbl.TextSize = props.textSize or 12
    lbl.TextColor3 = props.textColor or COLORS.TextPrimary
    lbl.TextXAlignment = props.alignX or Enum.TextXAlignment.Left
    lbl.TextYAlignment = props.alignY or Enum.TextYAlignment.Center
    lbl.TextWrapped = props.wrap or false
    lbl.Text = props.text or ""
    lbl.Size = props.size or UDim2.new(1, 0, 0, 18)
    lbl.Position = props.pos or UDim2.new()
    if props.anchor then lbl.AnchorPoint = props.anchor end
    lbl.Parent = parent
    return lbl
end

local function addInfoCard(parent, title, body, accentColor)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = COLORS.BgCard
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Size = UDim2.new(1, -6, 0, 40)
    addCorner(card, 6)
    addStroke(card, accentColor or COLORS.Border, 1)
    card.Parent = parent

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = card

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 4)
    lay.Parent = card

    makeLabel(card, {
        text = title,
        font = FONT_BOLD,
        textSize = 12,
        textColor = accentColor or COLORS.AccentBlue,
        size = UDim2.new(1, 0, 0, 16),
        wrap = true,
    })

    local bodyLbl = makeLabel(card, {
        text = body,
        font = FONT_REG,
        textSize = 11,
        textColor = COLORS.TextPrimary,
        size = UDim2.new(1, 0, 0, 0),
        wrap = true,
        alignY = Enum.TextYAlignment.Top,
    })
    bodyLbl.AutomaticSize = Enum.AutomaticSize.Y
    return card, bodyLbl
end

-- Entry pill & hint shown ONLY inside The Range
local openStudioPill = makeButton(studioGui, {
    text = "3D SHOWCASE & ANIM LAB [V]",
    font = FONT_BOLD,
    textSize = 12,
    bgColor = COLORS.BgPanel,
    strokeColor = COLORS.AccentBlue,
    size = UDim2.new(0, 224, 0, 34),
    pos = UDim2.new(1, -16, 0, 14),
    anchor = Vector2.new(1, 0),
    radius = 8,
})
openStudioPill.Visible = false

local rangeHintLbl = makeLabel(studioGui, {
    text = "[V] Open Interactive Showcase  •  [F] Inspect Model  •  [E] Equip Weapon",
    font = FONT_REG,
    textSize = 12,
    textColor = COLORS.TextMuted,
    alignX = Enum.TextXAlignment.Center,
    size = UDim2.new(0, 500, 0, 22),
    pos = UDim2.new(0.5, 0, 1, -14),
    anchor = Vector2.new(0.5, 1),
})
rangeHintLbl.Visible = false

-- Compact World Telemetry card for Movement Testing Area outside isolated booth
local worldMoveHud = Instance.new("Frame")
worldMoveHud.Name = "WorldMovementTelemetry"
worldMoveHud.BackgroundColor3 = COLORS.BgPanel
worldMoveHud.BackgroundTransparency = 0.08
worldMoveHud.Size = UDim2.new(0, 260, 0, 118)
worldMoveHud.Position = UDim2.new(1, -16, 0, 56)
worldMoveHud.AnchorPoint = Vector2.new(1, 0)
worldMoveHud.Visible = false
addCorner(worldMoveHud, 8)
addStroke(worldMoveHud, COLORS.AccentGreen, 1)
worldMoveHud.Parent = studioGui

local worldMoveLbl = makeLabel(worldMoveHud, {
    text = "3P MOVEMENT TESTING",
    font = FONT_BOLD,
    textSize = 11,
    textColor = COLORS.AccentGreen,
    size = UDim2.new(1, -16, 0, 18),
    pos = UDim2.new(0, 10, 0, 8),
})
local worldMoveBody = makeLabel(worldMoveHud, {
    text = "Speed: 0.0 st/s",
    font = FONT_MONO,
    textSize = 11,
    size = UDim2.new(1, -16, 0, 56),
    pos = UDim2.new(0, 10, 0, 28),
    wrap = true,
    alignY = Enum.TextYAlignment.Top,
})
local btnExitWorldMove = makeButton(worldMoveHud, {
    text = "Return to Studio [V]",
    font = FONT_BOLD,
    bgColor = COLORS.BgSelected,
    strokeColor = COLORS.AccentBlue,
    size = UDim2.new(1, -20, 0, 24),
    pos = UDim2.new(0, 10, 1, -30),
    textSize = 11,
})

-- Main Studio Shell
local studioRoot = Instance.new("Frame")
studioRoot.Name = "ShowcaseStudioRoot"
studioRoot.BackgroundTransparency = 1
studioRoot.Size = UDim2.new(1, 0, 1, 0)
studioRoot.Visible = false
studioRoot.Parent = studioGui

local topBar = Instance.new("Frame")
topBar.BackgroundColor3 = COLORS.BgPanel
topBar.BackgroundTransparency = 0.06
topBar.Size = UDim2.new(1, -24, 0, 44)
topBar.Position = UDim2.new(0, 12, 0, 10)
addCorner(topBar, 8)
addStroke(topBar, COLORS.Border, 1)
topBar.Parent = studioRoot

local brandLbl = makeLabel(topBar, {
    text = "KMUTNB // 3D STUDIO",
    font = FONT_BOLD,
    textSize = 13,
    textColor = COLORS.AccentBlue,
    size = UDim2.new(0, 165, 1, 0),
    pos = UDim2.new(0, 12, 0, 0),
})

local tabRow = Instance.new("Frame")
tabRow.BackgroundTransparency = 1
tabRow.Size = UDim2.new(1, -390, 0, 30)
tabRow.Position = UDim2.new(0, 178, 0.5, 0)
tabRow.AnchorPoint = Vector2.new(0, 0.5)
tabRow.Parent = topBar

local tabListLayout = Instance.new("UIListLayout")
tabListLayout.FillDirection = Enum.FillDirection.Horizontal
tabListLayout.Padding = UDim.new(0, 6)
tabListLayout.Parent = tabRow

local tabButtons = {}
for _, tab in ipairs(MAIN_TABS) do
    local b = makeButton(tabRow, {
        text = tab.label,
        font = FONT_BOLD,
        textSize = 11,
        size = UDim2.new(0, 118, 1, 0),
        radius = 6,
    })
    tabButtons[tab.id] = b
end

local btnCloseStudio = makeButton(topBar, {
    text = "Close [V]",
    font = FONT_BOLD,
    textSize = 11,
    bgColor = Color3.fromRGB(62, 26, 30),
    strokeColor = COLORS.AccentRed,
    size = UDim2.new(0, 78, 0, 28),
    pos = UDim2.new(1, -10, 0.5, 0),
    anchor = Vector2.new(1, 0.5),
})

local btnCamQuickMode = makeButton(topBar, {
    text = "Free Walk [K]",
    font = FONT_BOLD,
    textSize = 11,
    bgColor = COLORS.BgElevated,
    strokeColor = COLORS.AccentAmber,
    size = UDim2.new(0, 98, 0, 28),
    pos = UDim2.new(1, -94, 0.5, 0),
    anchor = Vector2.new(1, 0.5),
})

-- Left Panel (Library / Selector / Search & Filter)
local leftPanel = Instance.new("Frame")
leftPanel.BackgroundColor3 = COLORS.BgPanel
leftPanel.BackgroundTransparency = 0.08
leftPanel.Size = UDim2.new(0, 250, 1, -124)
leftPanel.Position = UDim2.new(0, 12, 0, 62)
addCorner(leftPanel, 8)
addStroke(leftPanel, COLORS.Border, 1)
leftPanel.Parent = studioRoot

local leftHeaderLbl = makeLabel(leftPanel, {
    text = "LIBRARY",
    font = FONT_BOLD,
    textSize = 12,
    textColor = COLORS.TextMuted,
    size = UDim2.new(1, -20, 0, 22),
    pos = UDim2.new(0, 10, 0, 8),
})

local leftToolsArea = Instance.new("Frame")
leftToolsArea.BackgroundTransparency = 1
leftToolsArea.AutomaticSize = Enum.AutomaticSize.Y
leftToolsArea.Size = UDim2.new(1, -16, 0, 0)
leftToolsArea.Position = UDim2.new(0, 8, 0, 32)
leftToolsArea.Parent = leftPanel

local leftToolsLayout = Instance.new("UIListLayout")
leftToolsLayout.Padding = UDim.new(0, 6)
leftToolsLayout.Parent = leftToolsArea

local leftScroll = Instance.new("ScrollingFrame")
leftScroll.BackgroundTransparency = 1
leftScroll.BorderSizePixel = 0
leftScroll.ScrollBarThickness = 4
leftScroll.ScrollBarImageColor3 = COLORS.AccentBlue
leftScroll.CanvasSize = UDim2.new()
leftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
leftScroll.Size = UDim2.new(1, -14, 1, -44)
leftScroll.Position = UDim2.new(0, 7, 0, 36)
leftScroll.Parent = leftPanel

local leftScrollLayout = Instance.new("UIListLayout")
leftScrollLayout.Padding = UDim.new(0, 6)
leftScrollLayout.Parent = leftScroll

-- Right Panel (Asset Specs / Animation Lab / Movement Controls)
local rightPanel = Instance.new("Frame")
rightPanel.BackgroundColor3 = COLORS.BgPanel
rightPanel.BackgroundTransparency = 0.08
rightPanel.Size = UDim2.new(0, 294, 1, -124)
rightPanel.Position = UDim2.new(1, -12, 0, 62)
rightPanel.AnchorPoint = Vector2.new(1, 0)
addCorner(rightPanel, 8)
addStroke(rightPanel, COLORS.Border, 1)
rightPanel.Parent = studioRoot

local rightScroll = Instance.new("ScrollingFrame")
rightScroll.BackgroundTransparency = 1
rightScroll.BorderSizePixel = 0
rightScroll.ScrollBarThickness = 4
rightScroll.ScrollBarImageColor3 = COLORS.AccentBlue
rightScroll.CanvasSize = UDim2.new()
rightScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
rightScroll.Size = UDim2.new(1, -14, 1, -16)
rightScroll.Position = UDim2.new(0, 7, 0, 8)
rightScroll.Parent = rightPanel

local rightScrollLayout = Instance.new("UIListLayout")
rightScrollLayout.Padding = UDim.new(0, 8)
rightScrollLayout.Parent = rightScroll

-- Bottom Camera Toolbar
local bottomCamBar = Instance.new("Frame")
bottomCamBar.BackgroundColor3 = COLORS.BgPanel
bottomCamBar.BackgroundTransparency = 0.08
bottomCamBar.Size = UDim2.new(0, 560, 0, 40)
bottomCamBar.Position = UDim2.new(0.5, 0, 1, -12)
bottomCamBar.AnchorPoint = Vector2.new(0.5, 1)
addCorner(bottomCamBar, 8)
addStroke(bottomCamBar, COLORS.Border, 1)
bottomCamBar.Parent = studioRoot

local bottomLayout = Instance.new("UIListLayout")
bottomLayout.FillDirection = Enum.FillDirection.Horizontal
bottomLayout.VerticalAlignment = Enum.VerticalAlignment.Center
bottomLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
bottomLayout.Padding = UDim.new(0, 6)
bottomLayout.Parent = bottomCamBar

local btnFront = makeButton(bottomCamBar, { text = "Front", size = UDim2.new(0, 54, 0, 26), textSize = 11 })
local btnSide = makeButton(bottomCamBar, { text = "Side", size = UDim2.new(0, 50, 0, 26), textSize = 11 })
local btnBack = makeButton(bottomCamBar, { text = "Back", size = UDim2.new(0, 50, 0, 26), textSize = 11 })
local btnZoomOut = makeButton(bottomCamBar, { text = "- Zoom", size = UDim2.new(0, 58, 0, 26), textSize = 11 })
local zoomLbl = makeLabel(bottomCamBar, {
    text = "8.0m",
    font = FONT_MONO,
    textSize = 11,
    textColor = COLORS.AccentAmber,
    alignX = Enum.TextXAlignment.Center,
    size = UDim2.new(0, 48, 0, 26),
})
local btnZoomIn = makeButton(bottomCamBar, { text = "+ Zoom", size = UDim2.new(0, 58, 0, 26), textSize = 11 })
local btnResetCam = makeButton(bottomCamBar, { text = "Reset Cam", size = UDim2.new(0, 74, 0, 26), textSize = 11, strokeColor = COLORS.AccentBlue })
makeLabel(bottomCamBar, {
    text = "Drag/Touch: Orbit  •  Wheel/Pinch: Zoom",
    font = FONT_REG,
    textSize = 10,
    textColor = COLORS.TextMuted,
    size = UDim2.new(0, 130, 0, 26),
})

local function applyResponsiveSizing()
    local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local isCompact = vp.X < 900
    local leftW = isCompact and 196 or 250
    local rightW = isCompact and 236 or 294
    leftPanel.Size = UDim2.new(0, leftW, 1, -124)
    rightPanel.Size = UDim2.new(0, rightW, 1, -124)
    brandLbl.Visible = not isCompact
    tabRow.Position = isCompact and UDim2.new(0, 10, 0.5, 0) or UDim2.new(0, 178, 0.5, 0)
    tabRow.Size = isCompact and UDim2.new(1, -200, 0, 30) or UDim2.new(1, -390, 0, 30)
    for _, b in pairs(tabButtons) do
        b.Size = isCompact and UDim2.new(0, 90, 1, 0) or UDim2.new(0, 118, 1, 0)
    end
end

----------------------------------------------------------------------
-- 4. ASSET SELECTION & UI REBUILDING
----------------------------------------------------------------------
local rebuildUI
local exitStudioMode

local function clearContainer(frame)
    for _, child in ipairs(frame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local function spawnActiveTabAsset()
    local stage = ensureStudioStage()
    clearAllPreviewModels()
    stage.setCalibrationRotation(0)

    local preset = nil
    if state.activeTab == "CHARACTERS" then
        preset = charCtrl:spawn(state.selectedCharId, stage.mount, stage.groundPos)
    elseif state.activeTab == "ZOMBIES" then
        preset = zombieCtrl:spawn(state.selectedZombieId, stage.mount, stage.groundPos)
    elseif state.activeTab == "WEAPONS" then
        preset = weaponCtrl:spawn(state.selectedWeaponKey, weaponCtrl.viewMode, stage.mount, stage.groundPos)
    elseif state.activeTab == "ANIMATION_LAB" then
        local targetId = (animLab.domain == "Player" and "PlayerR15")
            or (animLab.domain == "Zombie" and animLab.targetId)
            or state.selectedWeaponKey
        preset = animLab:spawnTarget(animLab.domain, targetId, stage.mount, stage.groundPos)
    end

    if preset then
        camCtrl:setMode("Orbit", preset.eyeCF)
        camCtrl:setFocusPreset(preset.focusPos, preset.dist, preset.yaw, preset.pitch, false)
    end
end

local function buildTransportControls(parent, stateObj)
    -- Play / Pause / Stop / Restart / Return to Idle
    local r1 = Instance.new("Frame")
    r1.BackgroundTransparency = 1
    r1.Size = UDim2.new(1, -6, 0, 28)
    r1.Parent = parent
    local l1 = Instance.new("UIListLayout")
    l1.FillDirection = Enum.FillDirection.Horizontal
    l1.Padding = UDim.new(0, 4)
    l1.Parent = r1

    local btnPlay = makeButton(r1, {
        text = "Play",
        bgColor = (not stateObj.paused and not stateObj.stopped) and COLORS.BgSelected or COLORS.BgCard,
        strokeColor = COLORS.AccentGreen,
        size = UDim2.new(0.24, 0, 1, 0),
        textSize = 11,
    })
    btnPlay.MouseButton1Click:Connect(function() stateObj.onPlay(); rebuildUI() end)

    local btnPause = makeButton(r1, {
        text = "Pause",
        bgColor = (stateObj.paused and not stateObj.stopped) and COLORS.BgSelected or COLORS.BgCard,
        strokeColor = COLORS.AccentAmber,
        size = UDim2.new(0.24, 0, 1, 0),
        textSize = 11,
    })
    btnPause.MouseButton1Click:Connect(function() stateObj.onPause(); rebuildUI() end)

    local btnStop = makeButton(r1, {
        text = "Stop",
        bgColor = stateObj.stopped and Color3.fromRGB(68, 30, 34) or COLORS.BgCard,
        strokeColor = COLORS.AccentRed,
        size = UDim2.new(0.24, 0, 1, 0),
        textSize = 11,
    })
    btnStop.MouseButton1Click:Connect(function() stateObj.onStop(); rebuildUI() end)

    local btnRestart = makeButton(r1, {
        text = "Restart",
        size = UDim2.new(0.25, 0, 1, 0),
        textSize = 11,
    })
    btnRestart.MouseButton1Click:Connect(function() stateObj.onRestart(); rebuildUI() end)

    local r2 = Instance.new("Frame")
    r2.BackgroundTransparency = 1
    r2.Size = UDim2.new(1, -6, 0, 28)
    r2.Parent = parent
    local l2 = Instance.new("UIListLayout")
    l2.FillDirection = Enum.FillDirection.Horizontal
    l2.Padding = UDim.new(0, 5)
    l2.Parent = r2

    local btnIdle = makeButton(r2, {
        text = "Return to Idle",
        bgColor = COLORS.BgElevated,
        strokeColor = COLORS.AccentBlue,
        size = UDim2.new(0.62, 0, 1, 0),
        textSize = 11,
    })
    btnIdle.MouseButton1Click:Connect(function() stateObj.onIdle(); rebuildUI() end)

    local btnLoop = makeButton(r2, {
        text = stateObj.loop and "Loop: ON" or "Loop: OFF",
        bgColor = stateObj.loop and COLORS.BgSelected or COLORS.BgCard,
        size = UDim2.new(0.36, 0, 1, 0),
        textSize = 11,
    })
    btnLoop.MouseButton1Click:Connect(function() stateObj.onLoop(); rebuildUI() end)

    local speedRow = Instance.new("Frame")
    speedRow.BackgroundTransparency = 1
    speedRow.Size = UDim2.new(1, -6, 0, 26)
    speedRow.Parent = parent
    local sl = Instance.new("UIListLayout")
    sl.FillDirection = Enum.FillDirection.Horizontal
    sl.Padding = UDim.new(0, 4)
    sl.Parent = speedRow

    for _, spd in ipairs(SPEED_PRESETS) do
        local sel = math.abs(stateObj.speed - spd) < 0.01
        local b = makeButton(speedRow, {
            text = tostring(spd) .. "x",
            bgColor = sel and COLORS.BgSelected or COLORS.BgCard,
            strokeColor = sel and COLORS.AccentBlue or COLORS.Border,
            size = UDim2.new(0.19, 0, 1, 0),
            textSize = 11,
        })
        b.MouseButton1Click:Connect(function() stateObj.onSpeed(spd); rebuildUI() end)
    end
end

local function populateLeftPanel()
    clearContainer(leftToolsArea)
    clearContainer(leftScroll)

    local function addListCard(title, sub, selected, onClick)
        local btn = makeButton(leftScroll, {
            text = "",
            bgColor = selected and COLORS.BgSelected or COLORS.BgCard,
            strokeColor = selected and COLORS.AccentBlue or COLORS.Border,
            size = UDim2.new(1, -4, 0, 46),
        })
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = btn

        makeLabel(btn, {
            text = title,
            font = FONT_BOLD,
            textSize = 12,
            size = UDim2.new(1, 0, 0, 19),
            pos = UDim2.new(0, 0, 0, 4),
        })
        makeLabel(btn, {
            text = sub,
            font = FONT_REG,
            textSize = 10,
            textColor = selected and COLORS.AccentAmber or COLORS.TextMuted,
            size = UDim2.new(1, 0, 0, 15),
            pos = UDim2.new(0, 0, 0, 24),
        })
        btn.MouseButton1Click:Connect(onClick)
    end

    local tab = state.activeTab
    if tab == "CHARACTERS" then
        leftHeaderLbl.Text = "CHARACTERS (" .. #CharacterPreviewController.ITEMS .. ")"
        leftScroll.Position = UDim2.new(0, 7, 0, 34)
        leftScroll.Size = UDim2.new(1, -14, 1, -42)
        for _, item in ipairs(CharacterPreviewController.ITEMS) do
            addListCard(item.name, item.typeLabel, state.selectedCharId == item.id, function()
                state.selectedCharId = item.id
                spawnActiveTabAsset()
                rebuildUI()
            end)
        end
    elseif tab == "ZOMBIES" then
        local list = ZombiePreviewController.getOrderedArchetypes()
        leftHeaderLbl.Text = "INFECTED & BOSSES (" .. #list .. ")"
        leftScroll.Position = UDim2.new(0, 7, 0, 34)
        leftScroll.Size = UDim2.new(1, -14, 1, -42)
        for _, arch in ipairs(list) do
            local sub = string.format("%s %s  •  %.2fst  •  HP %d", arch.Gender, arch.Role, arch.TargetHeight, arch.MaxHealth)
            addListCard(arch.DisplayName, sub, state.selectedZombieId == arch.Id, function()
                state.selectedZombieId = arch.Id
                spawnActiveTabAsset()
                rebuildUI()
            end)
        end
    elseif tab == "WEAPONS" then
        -- Search box + Category filter chips
        local searchBox = Instance.new("TextBox")
        searchBox.PlaceholderText = "Search weapon name..."
        searchBox.Text = state.weaponSearch
        searchBox.ClearTextOnFocus = false
        searchBox.Font = FONT_REG
        searchBox.TextSize = 12
        searchBox.TextColor3 = COLORS.TextPrimary
        searchBox.PlaceholderColor3 = COLORS.TextMuted
        searchBox.BackgroundColor3 = COLORS.BgCard
        searchBox.Size = UDim2.new(1, 0, 0, 28)
        searchBox.BorderSizePixel = 0
        addCorner(searchBox, 6)
        addStroke(searchBox, COLORS.Border, 1)
        searchBox.Parent = leftToolsArea
        local sPad = Instance.new("UIPadding")
        sPad.PaddingLeft = UDim.new(0, 8)
        sPad.Parent = searchBox
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            state.weaponSearch = searchBox.Text
            populateLeftPanel()
        end)

        -- Filter chips row (wrapping cleanly inside 2 rows)
        local chipGrid = Instance.new("Frame")
        chipGrid.BackgroundTransparency = 1
        chipGrid.Size = UDim2.new(1, 0, 0, 52)
        chipGrid.Parent = leftToolsArea
        local gl = Instance.new("UIGridLayout")
        gl.CellSize = UDim2.new(0, 56, 0, 22)
        gl.CellPadding = UDim2.new(0, 4, 0, 4)
        gl.Parent = chipGrid

        for _, catName in ipairs(WeaponPreviewController.CATEGORY_FILTERS) do
            local isSel = (state.weaponCategory == catName)
            local cb = makeButton(chipGrid, {
                text = catName,
                font = FONT_BOLD,
                textSize = 10,
                bgColor = isSel and COLORS.BgSelected or COLORS.BgCard,
                strokeColor = isSel and COLORS.AccentAmber or COLORS.Border,
                size = UDim2.new(0, 56, 0, 22),
                radius = 4,
            })
            cb.MouseButton1Click:Connect(function()
                state.weaponCategory = catName
                rebuildUI()
            end)
        end

        local filtered = WeaponPreviewController.getAllWeapons(state.weaponCategory, state.weaponSearch)
        leftHeaderLbl.Text = string.format("WEAPONS (%d)", #filtered)
        leftScroll.Position = UDim2.new(0, 7, 0, 122)
        leftScroll.Size = UDim2.new(1, -14, 1, -130)

        for _, entry in ipairs(filtered) do
            local st = WeaponPreviewController.extractStats(entry.key, entry.cfg)
            local sub = string.format("%s  •  DMG %d/%d  •  %d/%d", st.category, st.headDmg, st.bodyDmg, st.mag, st.reserve)
            addListCard(st.name, sub, state.selectedWeaponKey == entry.key, function()
                state.selectedWeaponKey = entry.key
                animLab.targetId = entry.key
                spawnActiveTabAsset()
                rebuildUI()
            end)
        end
    elseif tab == "ANIMATION_LAB" then
        -- Domain switch + target rig selector
        leftHeaderLbl.Text = "ANIMATION TARGET"
        local dRow = Instance.new("Frame")
        dRow.BackgroundTransparency = 1
        dRow.Size = UDim2.new(1, 0, 0, 28)
        dRow.Parent = leftToolsArea
        local dl = Instance.new("UIListLayout")
        dl.FillDirection = Enum.FillDirection.Horizontal
        dl.Padding = UDim.new(0, 4)
        dl.Parent = dRow

        for _, dom in ipairs({
            { id = "Zombie", label = "Zombies" },
            { id = "Player", label = "Player" },
            { id = "Weapon", label = "Weapons" },
        }) do
            local act = (animLab.domain == dom.id)
            local db = makeButton(dRow, {
                text = dom.label,
                font = FONT_BOLD,
                textSize = 11,
                bgColor = act and COLORS.BgSelected or COLORS.BgCard,
                strokeColor = act and COLORS.AccentBlue or COLORS.Border,
                size = UDim2.new(0.32, 0, 1, 0),
            })
            db.MouseButton1Click:Connect(function()
                animLab.domain = dom.id
                if dom.id == "Zombie" then
                    animLab.targetId = state.selectedZombieId
                elseif dom.id == "Weapon" then
                    animLab.targetId = state.selectedWeaponKey
                else
                    animLab.targetId = "PlayerR15"
                end
                spawnActiveTabAsset()
                rebuildUI()
            end)
        end

        leftScroll.Position = UDim2.new(0, 7, 0, 68)
        leftScroll.Size = UDim2.new(1, -14, 1, -76)

        if animLab.domain == "Player" then
            addListCard("Player Character (R15)", "Runtime Animate Rig", true, function() end)
        elseif animLab.domain == "Zombie" then
            for _, arch in ipairs(ZombiePreviewController.getOrderedArchetypes()) do
                addListCard(arch.DisplayName, arch.Id .. " • ZombieAnimationController", animLab.targetId == arch.Id, function()
                    animLab.targetId = arch.Id
                    state.selectedZombieId = arch.Id
                    spawnActiveTabAsset()
                    rebuildUI()
                end)
            end
        else
            for _, entry in ipairs(WeaponPreviewController.getAllWeapons("All", "")) do
                local st = WeaponPreviewController.extractStats(entry.key, entry.cfg)
                addListCard(st.name, st.shotMode .. "  •  WeaponPoseSolver", state.selectedWeaponKey == entry.key, function()
                    state.selectedWeaponKey = entry.key
                    animLab.targetId = entry.key
                    spawnActiveTabAsset()
                    rebuildUI()
                end)
            end
        end
    end
end

local function populateRightPanel()
    clearContainer(rightScroll)
    local tab = state.activeTab

    if tab == "CHARACTERS" then
        local meta = charCtrl:getMetadata()
        addInfoCard(rightScroll, meta.title, meta.subtitle .. "\n\n" .. meta.details, COLORS.AccentBlue)
        local btnOpenLab = makeButton(rightScroll, {
            text = "Open Player in Animation Lab ->",
            font = FONT_BOLD,
            bgColor = COLORS.BgSelected,
            strokeColor = COLORS.AccentBlue,
            size = UDim2.new(1, -6, 0, 32),
        })
        btnOpenLab.MouseButton1Click:Connect(function()
            state.activeTab = "ANIMATION_LAB"
            animLab.domain = "Player"
            animLab.targetId = "PlayerR15"
            spawnActiveTabAsset()
            rebuildUI()
        end)
    elseif tab == "ZOMBIES" then
        local meta = zombieCtrl:getMetadata()
        addInfoCard(rightScroll, meta.title, meta.subtitle .. "\n\n" .. meta.details, COLORS.AccentRed)
        local btnOpenLab = makeButton(rightScroll, {
            text = "Open Zombie in Animation Lab ->",
            font = FONT_BOLD,
            bgColor = COLORS.BgSelected,
            strokeColor = COLORS.AccentAmber,
            size = UDim2.new(1, -6, 0, 32),
        })
        btnOpenLab.MouseButton1Click:Connect(function()
            state.activeTab = "ANIMATION_LAB"
            animLab.domain = "Zombie"
            animLab.targetId = state.selectedZombieId
            spawnActiveTabAsset()
            rebuildUI()
        end)
    elseif tab == "WEAPONS" then
        local st = WeaponPreviewController.extractStats(state.selectedWeaponKey)
        local body = string.format(
            "Type: %s (%s)   •   Action: %s\nDamage: Head %d / Body %d / Legs %d\nFireRate: %d RPM (%.3fs)   •   Mag: %d / %d\nPellets: %d   •   Optics FOV: %d   •   Silenced: %s",
            st.category, st.firingType, st.shotMode,
            st.headDmg, st.bodyDmg, st.legsDmg,
            st.rpm, st.fireRateSec, st.mag, st.reserve,
            st.pellets, st.zoomFov, st.silenced and "Yes" or "No"
        )
        addInfoCard(rightScroll, st.name .. " — WEAPON SPECS", body, COLORS.AccentAmber)

        -- View perspective toggle: Gun 3D / 1P Arms+Gun / 3P R15 Hold
        local vRow = Instance.new("Frame")
        vRow.BackgroundTransparency = 1
        vRow.Size = UDim2.new(1, -6, 0, 28)
        vRow.Parent = rightScroll
        local vl = Instance.new("UIListLayout")
        vl.FillDirection = Enum.FillDirection.Horizontal
        vl.Padding = UDim.new(0, 4)
        vl.Parent = vRow

        for _, vm in ipairs({
            { id = "Gun3D", label = "Gun 3D" },
            { id = "Viewmodel1P", label = "1P Arms" },
            { id = "Character3P", label = "3P Rig" },
        }) do
            local sel = (weaponCtrl.viewMode == vm.id)
            local vb = makeButton(vRow, {
                text = vm.label,
                bgColor = sel and COLORS.BgSelected or COLORS.BgCard,
                strokeColor = sel and COLORS.AccentBlue or COLORS.Border,
                size = UDim2.new(0.32, 0, 1, 0),
                textSize = 11,
            })
            vb.MouseButton1Click:Connect(function()
                weaponCtrl.viewMode = vm.id
                if vm.id ~= "Viewmodel1P" and camCtrl.mode == "WeaponEye1P" then
                    camCtrl:setMode("Orbit")
                end
                spawnActiveTabAsset()
                rebuildUI()
            end)
        end

        if weaponCtrl.viewMode == "Viewmodel1P" then
            local eyeBtn = makeButton(rightScroll, {
                text = (camCtrl.mode == "WeaponEye1P") and "Cam: 1P Eye Cam (Click for 360 Orbit)" or "Switch to FPS Eye-Level View",
                font = FONT_BOLD,
                bgColor = (camCtrl.mode == "WeaponEye1P") and COLORS.BgSelected or COLORS.BgCard,
                strokeColor = COLORS.AccentGreen,
                size = UDim2.new(1, -6, 0, 28),
                textSize = 11,
            })
            eyeBtn.MouseButton1Click:Connect(function()
                if camCtrl.mode == "WeaponEye1P" then
                    camCtrl:setMode("Orbit")
                else
                    camCtrl:setMode("WeaponEye1P", weaponCtrl.eyeCF)
                end
                rebuildUI()
            end)
        elseif weaponCtrl.viewMode == "Character3P" then
            addInfoCard(rightScroll, "3P Animation Disclosure",
                "Repo has no separate 3P weapon AnimationIds; weapon pose is driven cleanly from WeaponPoseSolver at 1:1 scale.",
                COLORS.TextMuted)
        end

        local adsBtn = makeButton(rightScroll, {
            text = weaponCtrl.isADS and "ADS Sight Preview: ON" or "ADS Sight Preview: OFF",
            bgColor = weaponCtrl.isADS and COLORS.BgSelected or COLORS.BgCard,
            strokeColor = COLORS.AccentAmber,
            size = UDim2.new(1, -6, 0, 26),
            textSize = 11,
        })
        adsBtn.MouseButton1Click:Connect(function()
            weaponCtrl.isADS = not weaponCtrl.isADS
            rebuildUI()
        end)

        buildTransportControls(rightScroll, {
            paused = weaponCtrl.paused,
            stopped = weaponCtrl.stopped,
            loop = weaponCtrl.loop,
            speed = weaponCtrl.speed,
            onPlay = function()
                if weaponCtrl.stopped then weaponCtrl:playClip(weaponCtrl.clipId) else weaponCtrl.paused = false end
            end,
            onPause = function() weaponCtrl.paused = true end,
            onStop = function() weaponCtrl:stop() end,
            onRestart = function() weaponCtrl:playClip(weaponCtrl.clipId) end,
            onIdle = function() weaponCtrl:playClip("Idle") end,
            onLoop = function() weaponCtrl.loop = not weaponCtrl.loop end,
            onSpeed = function(s) weaponCtrl.speed = s end,
        })

        for _, clip in ipairs(WeaponPreviewController.WEAPON_CLIPS) do
            local active = (weaponCtrl.clipId == clip.id) and not weaponCtrl.stopped
            local cb = makeButton(rightScroll, {
                text = clip.label,
                bgColor = active and COLORS.BgSelected or COLORS.BgCard,
                strokeColor = active and COLORS.AccentAmber or COLORS.Border,
                size = UDim2.new(1, -6, 0, 26),
                textSize = 11,
            })
            cb.MouseButton1Click:Connect(function()
                weaponCtrl:playClip(clip.id)
                rebuildUI()
            end)
        end
    elseif tab == "ANIMATION_LAB" then
        addInfoCard(rightScroll, "ANIMATION LAB — " .. animLab.domain:upper(), animLab.statusNote, COLORS.AccentBlue)

        buildTransportControls(rightScroll, {
            paused = animLab.paused,
            stopped = animLab.stopped,
            loop = animLab.loop,
            speed = animLab.speed,
            onPlay = function() animLab:resumeOrPlay() end,
            onPause = function() animLab:pause() end,
            onStop = function() animLab:stop() end,
            onRestart = function() animLab:restart() end,
            onIdle = function() animLab:returnToIdle() end,
            onLoop = function() animLab:setLoop(not animLab.loop) end,
            onSpeed = function(s) animLab:setSpeed(s) end,
        })

        if animLab.domain == "Zombie" then
            local hsBtn = makeButton(rightScroll, {
                text = animLab.isHeadshot and "Damage Variant: HEADSHOT" or "Damage Variant: BODY HIT",
                bgColor = animLab.isHeadshot and Color3.fromRGB(72, 28, 32) or COLORS.BgCard,
                strokeColor = animLab.isHeadshot and COLORS.AccentRed or COLORS.Border,
                size = UDim2.new(1, -6, 0, 26),
                textSize = 11,
            })
            hsBtn.MouseButton1Click:Connect(function()
                animLab.isHeadshot = not animLab.isHeadshot
                if animLab.clipId == "TakingDamage" then
                    animLab:playClip("TakingDamage", true)
                end
                rebuildUI()
            end)
        end

        -- Clip list (showing only actual states, marking unavailable clearly)
        for _, clip in ipairs(animLab:getAvailableClips()) do
            local sel = (animLab.clipId == clip.id) and not animLab.stopped
            local labelText = clip.supported and clip.label or (clip.label .. "  [UNAVAILABLE]")
            local cb = makeButton(rightScroll, {
                text = labelText,
                textColor = clip.supported and COLORS.TextPrimary or COLORS.TextMuted,
                bgColor = sel and COLORS.BgSelected or COLORS.BgCard,
                strokeColor = sel and COLORS.AccentBlue or (clip.supported and COLORS.Border or Color3.fromRGB(72, 42, 46)),
                size = UDim2.new(1, -6, 0, 26),
                textSize = 11,
            })
            cb.MouseButton1Click:Connect(function()
                animLab.movementEnabled = false
                if not clip.supported then
                    animLab.statusNote = clip.note
                    rebuildUI()
                    return
                end
                animLab:playClip(clip.id, true)
                rebuildUI()
            end)
        end

        -- Section 8: Movement Preview Mode (isolated turntable test + Zone D 3P walk track)
        if animLab.domain ~= "Weapon" then
            addInfoCard(rightScroll, "MOVEMENT TESTING MODE",
                "Test Walk / Run / Sprint / Chase transitions, turning & speed vs calibration grid to catch foot-sliding or snapping.",
                COLORS.AccentGreen)

            local mvToggle = makeButton(rightScroll, {
                text = animLab.movementEnabled and "Studio Movement Preview: ON" or "Enable Studio Movement Preview",
                font = FONT_BOLD,
                bgColor = animLab.movementEnabled and COLORS.BgSelected or COLORS.BgCard,
                strokeColor = COLORS.AccentGreen,
                size = UDim2.new(1, -6, 0, 30),
                textSize = 11,
            })
            mvToggle.MouseButton1Click:Connect(function()
                animLab.movementEnabled = not animLab.movementEnabled
                if animLab.movementEnabled then
                    animLab:setMovementGait(animLab.moveGait)
                else
                    animLab:returnToIdle()
                end
                rebuildUI()
            end)

            if animLab.movementEnabled then
                local gRow = Instance.new("Frame")
                gRow.BackgroundTransparency = 1
                gRow.Size = UDim2.new(1, -6, 0, 26)
                gRow.Parent = rightScroll
                local gl = Instance.new("UIListLayout")
                gl.FillDirection = Enum.FillDirection.Horizontal
                gl.Padding = UDim.new(0, 4)
                gl.Parent = gRow

                for _, g in ipairs({
                    { id = "Idle", label = "Idle" },
                    { id = "Walking", label = "Walk" },
                    { id = "Running", label = "Run" },
                    { id = "Chasing", label = animLab.domain == "Player" and "Sprint" or "Chase" },
                }) do
                    local act = (animLab.moveGait == g.id)
                    local gb = makeButton(gRow, {
                        text = g.label,
                        bgColor = act and COLORS.BgSelected or COLORS.BgCard,
                        strokeColor = act and COLORS.AccentGreen or COLORS.Border,
                        size = UDim2.new(0.24, 0, 1, 0),
                        textSize = 11,
                    })
                    gb.MouseButton1Click:Connect(function()
                        animLab.turnMode = (animLab.turnMode == "AutoBlend") and "Straight" or animLab.turnMode
                        animLab:setMovementGait(g.id)
                        rebuildUI()
                    end)
                end

                for _, tm in ipairs(AnimationPreviewController.MOVEMENT_TURN_MODES) do
                    local act = (animLab.turnMode == tm.id)
                    local tb = makeButton(rightScroll, {
                        text = "Turn Mode: " .. tm.label,
                        bgColor = act and COLORS.BgSelected or COLORS.BgCard,
                        strokeColor = act and COLORS.AccentAmber or COLORS.Border,
                        size = UDim2.new(1, -6, 0, 25),
                        textSize = 11,
                    })
                    tb.MouseButton1Click:Connect(function()
                        animLab.turnMode = tm.id
                        rebuildUI()
                    end)
                end
            end
        end

        local worldTrackBtn = makeButton(rightScroll, {
            text = "Test Real Player WASD in 3rd-Person (Zone D) ->",
            font = FONT_BOLD,
            bgColor = COLORS.BgElevated,
            strokeColor = COLORS.AccentGreen,
            size = UDim2.new(1, -6, 0, 30),
            textSize = 11,
        })
        worldTrackBtn.MouseButton1Click:Connect(function()
            state.worldTpMoveActive = true
            state.studioOpen = false
            destroyStudioStage()
            camCtrl:setActive(true)
            camCtrl:setMode("ThirdPersonFollow")
            rebuildUI()
        end)
    end
end

rebuildUI = function()
    applyResponsiveSizing()

    openStudioPill.Visible = not state.studioOpen and not state.worldTpMoveActive
    rangeHintLbl.Visible = not state.studioOpen and not state.worldTpMoveActive
    worldMoveHud.Visible = state.worldTpMoveActive
    studioRoot.Visible = state.studioOpen

    if not state.studioOpen then
        return
    end

    for id, btn in pairs(tabButtons) do
        local active = (state.activeTab == id)
        btn.BackgroundColor3 = active and COLORS.BgSelected or COLORS.BgCard
        local s = btn:FindFirstChildOfClass("UIStroke")
        if s then
            s.Color = active and COLORS.AccentBlue or COLORS.Border
        end
    end

    btnCamQuickMode.Text = (camCtrl.mode == "Walk") and "Orbit 360 [K]" or "Free Walk [K]"
    bottomCamBar.Visible = (camCtrl.mode == "Orbit")

    populateLeftPanel()
    populateRightPanel()
end

----------------------------------------------------------------------
-- 5. STUDIO OPEN / CLOSE & WORLD PROMPTS
----------------------------------------------------------------------
exitStudioMode = function()
    state.studioOpen = false
    state.worldTpMoveActive = false
    camCtrl:setActive(false)
    destroyStudioStage()
    if state.patrolRunning and stageControlEvent then
        state.patrolRunning = false
        stageControlEvent:FireServer({ action = "StopPatrol" })
    end
    rebuildUI()
end

local function openStudioMode(tabId, assetId)
    if not isPlayerInsideRange() then return end
    state.worldTpMoveActive = false
    state.studioOpen = true
    if tabId then
        state.activeTab = tabId
    end
    if tabId == "WEAPONS" and assetId then
        state.selectedWeaponKey = assetId
    elseif tabId == "ZOMBIES" and assetId then
        state.selectedZombieId = assetId
    elseif tabId == "CHARACTERS" and assetId then
        state.selectedCharId = assetId
    elseif tabId == "ANIMATION_LAB" and assetId then
        if assetId == "PlayerR15" then
            animLab.domain = "Player"
            animLab.targetId = "PlayerR15"
        else
            animLab.domain = "Zombie"
            animLab.targetId = assetId
        end
    end

    camCtrl:setActive(true)
    spawnActiveTabAsset()
    rebuildUI()
end

openStudioPill.MouseButton1Click:Connect(function()
    openStudioMode()
end)

btnCloseStudio.MouseButton1Click:Connect(function()
    exitStudioMode()
end)

btnExitWorldMove.MouseButton1Click:Connect(function()
    openStudioMode("ANIMATION_LAB")
end)

btnCamQuickMode.MouseButton1Click:Connect(function()
    if camCtrl.mode == "Orbit" or camCtrl.mode == "WeaponEye1P" then
        camCtrl:setMode("Walk")
    else
        camCtrl:setMode("Orbit")
    end
    rebuildUI()
end)

for id, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        state.activeTab = id
        spawnActiveTabAsset()
        rebuildUI()
    end)
end

btnFront.MouseButton1Click:Connect(function() camCtrl:setViewAngle("Front") end)
btnSide.MouseButton1Click:Connect(function() camCtrl:setViewAngle("Side") end)
btnBack.MouseButton1Click:Connect(function() camCtrl:setViewAngle("Back") end)
btnZoomOut.MouseButton1Click:Connect(function() camCtrl:zoomBy(1.5) end)
btnZoomIn.MouseButton1Click:Connect(function() camCtrl:zoomBy(-1.5) end)
btnResetCam.MouseButton1Click:Connect(function() camCtrl:setViewAngle("Reset") end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, triggerPlayer)
    if triggerPlayer ~= player or prompt.Name ~= "StudioInspectPrompt" then return end
    local kind = prompt:GetAttribute("ShowcaseKind")
    local assetId = prompt:GetAttribute("ShowcaseAssetId")
    if kind == "Weapon" then
        openStudioMode("WEAPONS", assetId)
    elseif kind == "WeaponAnim" then
        animLab.domain = "Weapon"
        openStudioMode("ANIMATION_LAB", state.selectedWeaponKey)
    elseif kind == "Stage" then
        openStudioMode("ANIMATION_LAB")
    elseif kind == "Character" then
        if assetId == "PlayerR15" then
            openStudioMode("CHARACTERS", "PlayerR15")
        else
            openStudioMode("ZOMBIES", assetId)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if UserInputService:GetFocusedTextBox() then return end

    if input.KeyCode == Enum.KeyCode.V and not gameProcessed then
        if state.studioOpen or state.worldTpMoveActive then
            exitStudioMode()
        else
            openStudioMode()
        end
        return
    end

    if input.KeyCode == Enum.KeyCode.K and state.studioOpen and not gameProcessed then
        if camCtrl.mode == "Orbit" or camCtrl.mode == "WeaponEye1P" then
            camCtrl:setMode("Walk")
        else
            camCtrl:setMode("Orbit")
        end
        rebuildUI()
    end
end)

local function attachCharacterHooks(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.Died:Connect(function()
            exitStudioMode()
        end)
    end
end

if player.Character then
    task.spawn(attachCharacterHooks, player.Character)
end
player.CharacterAdded:Connect(function(char)
    exitStudioMode()
    attachCharacterHooks(char)
end)

----------------------------------------------------------------------
-- 6. RENDER LOOP
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    local nowInRange = isPlayerInsideRange()
    if nowInRange ~= state.inRange then
        state.inRange = nowInRange
        rebuildUI()
    end

    if not state.inRange then return end

    if state.worldTpMoveActive then
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if root and hum then
            local v = root.AssemblyLinearVelocity
            local hv = Vector3.new(v.X, 0, v.Z)
            local spd = hv.Magnitude
            if spd > state.peakSpeed then state.peakSpeed = spd end
            local rawAcc = (spd - state.lastHorizVel.Magnitude) / math.max(0.001, dt)
            state.smoothedAccel = state.smoothedAccel + (rawAcc - state.smoothedAccel) * math.clamp(dt * 8, 0, 1)
            state.lastHorizVel = hv
            worldMoveBody.Text = string.format(
                "Speed: %.1f st/s  (Peak %.1f)\nWalkSpeed: %.1f st/s  |  Accel: %+.1f\nState: %s  |  Grounded: %s",
                spd, state.peakSpeed, hum.WalkSpeed, state.smoothedAccel,
                hum:GetState().Name, tostring(hum.FloorMaterial ~= Enum.Material.Air)
            )
        end
        return
    end

    if not state.studioOpen then return end

    local weaponPos = weaponCtrl:step(dt)
    if weaponPos and camCtrl.mode == "Orbit" then
        camCtrl:setTargetFocusOnly(weaponPos)
    end

    animLab:step(dt, studioStage)

    if state.activeTab == "ANIMATION_LAB" and animLab.statusNote ~= state.lastLiveStateNote then
        state.lastLiveStateNote = animLab.statusNote
    end

    camCtrl:step(dt)
    zoomLbl.Text = string.format("%.1fm", camCtrl.dist)
end)
