--[[
    MapSelectorController.client.lua
    Interactive UI for selecting and teleporting to different maps and zones.
    - Toggle with screen button [🗺️ เลือกแมพ (M)] or pressing [M]
    - Engine Modal unlock ensures mouse is free to click
    - Instantly teleports player to The Range, Building 40 Lobby, Plaza, Canteen, etc.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote events
local eventsFolder = ReplicatedStorage:WaitForChild("TeleportEvents", 10)
local requestTeleport = eventsFolder and eventsFolder:WaitForChild("RequestTeleport", 5)
local teleportConfirmed = eventsFolder and eventsFolder:WaitForChild("TeleportConfirmed", 5)

-- GUI Container
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MapSelectorHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.DisplayOrder = 25
screenGui.Parent = playerGui

----------------------------------------------------------------------
-- 1. Persistent Screen Toggle Button
----------------------------------------------------------------------
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "MapToggleButton"
toggleButton.AnchorPoint = Vector2.new(0, 0)
toggleButton.Position = UDim2.new(0, 22, 0, 212)
toggleButton.Size = UDim2.new(0, 160, 0, 36)
toggleButton.BackgroundColor3 = Color3.fromRGB(15, 23, 34)
toggleButton.BackgroundTransparency = 0.15
toggleButton.Text = "🗺️ เลือกแมพ [M]"
toggleButton.TextColor3 = Color3.fromRGB(0, 210, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 13
toggleButton.AutoButtonColor = true
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(0, 180, 255)
toggleStroke.Transparency = 0.35
toggleStroke.Thickness = 1.2
toggleStroke.Parent = toggleButton

----------------------------------------------------------------------
-- 2. Modal Menu Window
----------------------------------------------------------------------
local menuWindow = Instance.new("Frame")
menuWindow.Name = "MapSelectorWindow"
menuWindow.AnchorPoint = Vector2.new(0.5, 0.5)
menuWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
menuWindow.Size = UDim2.new(0, 760, 0, 500)
menuWindow.BackgroundColor3 = Color3.fromRGB(13, 17, 24)
menuWindow.BackgroundTransparency = 0.04
menuWindow.Visible = false
menuWindow.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 12)
menuCorner.Parent = menuWindow

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(0, 210, 255)
menuStroke.Transparency = 0.3
menuStroke.Thickness = 1.5
menuStroke.Parent = menuWindow

-- Engine Modal Unlocker: frees mouse pointer from FPS controller when visible
local engineUnlocker = Instance.new("TextButton")
engineUnlocker.Name = "EngineModalUnlocker"
engineUnlocker.Size = UDim2.new(0, 0, 0, 0)
engineUnlocker.BackgroundTransparency = 1
engineUnlocker.Text = ""
engineUnlocker.Modal = true
engineUnlocker.Parent = menuWindow

-- Header Frame
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0, 64)
headerFrame.BackgroundColor3 = Color3.fromRGB(18, 25, 36)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = menuWindow

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = headerFrame

-- Header bottom mask to keep rectangular bottom
local headerBottomCover = Instance.new("Frame")
headerBottomCover.Size = UDim2.new(1, 0, 0, 12)
headerBottomCover.Position = UDim2.new(0, 0, 1, -12)
headerBottomCover.BackgroundColor3 = Color3.fromRGB(18, 25, 36)
headerBottomCover.BorderSizePixel = 0
headerBottomCover.Parent = headerFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Position = UDim2.new(0, 20, 0, 10)
titleLabel.Size = UDim2.new(1, -90, 0, 24)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "🗺️ MAP & ZONE SELECTOR // เลือดย้ายแมพและโซน"
titleLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerFrame

local subLabel = Instance.new("TextLabel")
subLabel.Name = "Subtitle"
subLabel.Position = UDim2.new(0, 20, 0, 36)
subLabel.Size = UDim2.new(1, -90, 0, 18)
subLabel.BackgroundTransparency = 1
subLabel.Font = Enum.Font.Gotham
subLabel.Text = "คลิกเลือกโซนที่ต้องการวาร์ปไปได้ทันที • กด [M] หรือปุ่ม ✕ เพื่อปิดหน้าต่าง"
subLabel.TextColor3 = Color3.fromRGB(140, 160, 180)
subLabel.TextSize = 12
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.Parent = headerFrame

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -16, 0.5, 0)
closeButton.Size = UDim2.new(0, 36, 0, 36)
closeButton.BackgroundColor3 = Color3.fromRGB(35, 45, 60)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(240, 240, 240)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.AutoButtonColor = true
closeButton.Parent = headerFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

----------------------------------------------------------------------
-- 3. Cards Scrolling Area
----------------------------------------------------------------------
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "CardsScroll"
scroll.Position = UDim2.new(0, 16, 0, 74)
scroll.Size = UDim2.new(1, -32, 1, -88)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 180, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = menuWindow

local grid = Instance.new("UIGridLayout")
grid.CellPadding = UDim2.new(0, 12, 0, 12)
grid.CellSize = UDim2.new(0.5, -6, 0, 124)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

----------------------------------------------------------------------
-- 4. Map Destination Definitions
----------------------------------------------------------------------
local MAP_CARDS = {
    {
        key = "TheRange",
        order = 1,
        title = "🎯 THE RANGE (สนามยิงปืน)",
        badge = "SHOWCASE & TEST",
        badgeColor = Color3.fromRGB(0, 220, 130),
        accentColor = Color3.fromRGB(0, 210, 160),
        desc = "หยิบอาวุธฟรีครบ 18 กระบอก (กด E) • หุ่นซอมบี้ 5 ไซส์ (Crawler ถึง Titan) ลองดาเมจและรีคอยล์",
        btnText = "🚀 ไปยัง The Range",
    },
    {
        key = "Floor1",
        order = 2,
        title = "🏢 ตึก 40 ปี — ชั้น 1 LOBBY",
        badge = "MAIN CAMPAIGN",
        badgeColor = Color3.fromRGB(235, 75, 65),
        accentColor = Color3.fromRGB(220, 70, 60),
        desc = "โถงทางเข้าหลัก ประชาสัมพันธ์ ตู้เซฟ จุดซ่อมหน้าต่าง ลิฟต์และบันไดวน",
        btnText = "🚀 ไปยัง ชั้น 1 Lobby",
    },
    {
        key = "Plaza",
        order = 3,
        title = "🌳 ลานหน้าอาคาร 40 ปี",
        badge = "OUTDOOR",
        badgeColor = Color3.fromRGB(0, 170, 255),
        accentColor = Color3.fromRGB(0, 160, 240),
        desc = "ลานกว้างภายนอก ลานจอดรถ สะพานข้ามคลอง และสวนปาล์ม",
        btnText = "🚀 ไปยัง ลานหน้าตึก",
    },
    {
        key = "Canteen",
        order = 4,
        title = "🍽️ ชั้น 2 — โรงอาหาร 40 ปี",
        badge = "CANTEEN",
        badgeColor = Color3.fromRGB(255, 170, 30),
        accentColor = Color3.fromRGB(240, 160, 20),
        desc = "โรงอาหาร 40 ปี สจพ. ซุ้มร้านค้า 8 ร้าน จุดคืนจาน และห้องกินข้าวติดแอร์",
        btnText = "🚀 ไปยัง ชั้น 2",
    },
    {
        key = "SportsArena",
        order = 5,
        title = "🏀 ชั้น 3 — สนามกีฬาในร่ม",
        badge = "ARENA",
        badgeColor = Color3.fromRGB(170, 85, 255),
        accentColor = Color3.fromRGB(160, 75, 240),
        desc = "สนามฟุตซอล สนามบาสเกตบอล และอัฒจันทร์เชียร์ 2 ฝั่ง",
        btnText = "🚀 ไปยัง ชั้น 3",
    },
    {
        key = "Rooftop",
        order = 6,
        title = "🏆 ชั้น 12 — สนามกีฬาดาดฟ้า",
        badge = "ROOFTOP",
        badgeColor = Color3.fromRGB(255, 80, 160),
        accentColor = Color3.fromRGB(240, 70, 150),
        desc = "สนามเซปักตะกร้อ 2 สนาม สนามเทนนิส และวิวชมทิวทัศน์มหาวิทยาลัย",
        btnText = "🚀 ไปยัง ชั้น 12",
    },
}

----------------------------------------------------------------------
-- 5. Toast Notification Banner
----------------------------------------------------------------------
local toast = Instance.new("Frame")
toast.Name = "ToastNotification"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, -60)
toast.Size = UDim2.new(0, 360, 0, 44)
toast.BackgroundColor3 = Color3.fromRGB(15, 25, 38)
toast.BackgroundTransparency = 0.08
toast.Parent = screenGui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 8)
toastCorner.Parent = toast

local toastStroke = Instance.new("UIStroke")
toastStroke.Color = Color3.fromRGB(0, 220, 160)
toastStroke.Thickness = 1.2
toastStroke.Parent = toast

local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.new(1, -20, 1, 0)
toastLabel.Position = UDim2.new(0, 10, 0, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextColor3 = Color3.fromRGB(240, 250, 245)
toastLabel.TextSize = 13
toastLabel.Text = "✨ กำลังวาร์ป..."
toastLabel.Parent = toast

local function showToast(text, color)
    toastLabel.Text = text
    toastStroke.Color = color or Color3.fromRGB(0, 220, 160)
    toast.Position = UDim2.new(0.5, 0, 0, -60)
    TweenService:Create(toast, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 24)
    }):Play()
    task.delay(2.6, function()
        TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, -60)
        }):Play()
    end)
end

----------------------------------------------------------------------
-- 6. Menu Visibility Toggle
----------------------------------------------------------------------
local function setMenuVisible(visible)
    menuWindow.Visible = visible
    if visible then
        toggleButton.TextColor3 = Color3.fromRGB(255, 215, 100)
        toggleStroke.Color = Color3.fromRGB(255, 215, 100)
    else
        toggleButton.TextColor3 = Color3.fromRGB(0, 210, 255)
        toggleStroke.Color = Color3.fromRGB(0, 180, 255)
    end
end

toggleButton.MouseButton1Click:Connect(function()
    setMenuVisible(not menuWindow.Visible)
end)

closeButton.MouseButton1Click:Connect(function()
    setMenuVisible(false)
end)

-- Keybind [M]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.M then
        setMenuVisible(not menuWindow.Visible)
    end
end)

----------------------------------------------------------------------
-- 7. Populate Destination Cards
----------------------------------------------------------------------
for _, item in ipairs(MAP_CARDS) do
    local card = Instance.new("Frame")
    card.Name = "Card_" .. item.key
    card.LayoutOrder = item.order
    card.BackgroundColor3 = Color3.fromRGB(20, 28, 40)
    card.BackgroundTransparency = 0.15
    card.Parent = scroll

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 9)
    cCorner.Parent = card

    local cStroke = Instance.new("UIStroke")
    cStroke.Color = item.accentColor
    cStroke.Transparency = 0.55
    cStroke.Thickness = 1
    cStroke.Parent = card

    -- Badge
    local badge = Instance.new("Frame")
    badge.Name = "Badge"
    badge.Position = UDim2.new(0, 12, 0, 10)
    badge.Size = UDim2.new(0, 110, 0, 18)
    badge.BackgroundColor3 = item.badgeColor
    badge.BackgroundTransparency = 0.8
    badge.Parent = card

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 4)
    bCorner.Parent = badge

    local bText = Instance.new("TextLabel")
    bText.Size = UDim2.new(1, 0, 1, 0)
    bText.BackgroundTransparency = 1
    bText.Font = Enum.Font.GothamBold
    bText.Text = item.badge
    bText.TextColor3 = item.badgeColor
    bText.TextSize = 9
    bText.Parent = badge

    -- Title
    local cTitle = Instance.new("TextLabel")
    cTitle.Name = "Title"
    cTitle.Position = UDim2.new(0, 12, 0, 32)
    cTitle.Size = UDim2.new(1, -24, 0, 20)
    cTitle.BackgroundTransparency = 1
    cTitle.Font = Enum.Font.GothamBold
    cTitle.Text = item.title
    cTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
    cTitle.TextSize = 13
    cTitle.TextXAlignment = Enum.TextXAlignment.Left
    cTitle.Parent = card

    -- Description
    local cDesc = Instance.new("TextLabel")
    cDesc.Name = "Description"
    cDesc.Position = UDim2.new(0, 12, 0, 54)
    cDesc.Size = UDim2.new(1, -24, 0, 30)
    cDesc.BackgroundTransparency = 1
    cDesc.Font = Enum.Font.Gotham
    cDesc.Text = item.desc
    cDesc.TextColor3 = Color3.fromRGB(160, 175, 195)
    cDesc.TextSize = 10
    cDesc.TextWrapped = true
    cDesc.TextXAlignment = Enum.TextXAlignment.Left
    cDesc.TextYAlignment = Enum.TextYAlignment.Top
    cDesc.Parent = card

    -- Warp Button
    local warpBtn = Instance.new("TextButton")
    warpBtn.Name = "WarpButton"
    warpBtn.Position = UDim2.new(0, 12, 1, -34)
    warpBtn.Size = UDim2.new(1, -24, 0, 26)
    warpBtn.BackgroundColor3 = item.accentColor
    warpBtn.BackgroundTransparency = 0.15
    warpBtn.Text = item.btnText
    warpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    warpBtn.Font = Enum.Font.GothamBold
    warpBtn.TextSize = 11
    warpBtn.AutoButtonColor = true
    warpBtn.Parent = card

    local wbCorner = Instance.new("UICorner")
    wbCorner.CornerRadius = UDim.new(0, 6)
    wbCorner.Parent = warpBtn

    warpBtn.MouseButton1Click:Connect(function()
        setMenuVisible(false)
        if requestTeleport then
            requestTeleport:FireServer(item.key)
        else
            warn("[MapSelector] TeleportEvents remote not ready")
        end
    end)
end

-- Server confirmation listener
if teleportConfirmed then
    teleportConfirmed.OnClientEvent:Connect(function(destKey, destName)
        showToast("✨ วาร์ปมายัง " .. destName .. " เรียบร้อยแล้ว!", Color3.fromRGB(0, 220, 160))
    end)
end

print("[MapSelectorController] UI Ready. Press [M] or click screen button to open.")
