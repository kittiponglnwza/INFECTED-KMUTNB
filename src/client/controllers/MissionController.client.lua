--[[
    MissionController.client.lua
    Displays the current server-authoritative campaign objective.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local missionEvents = ReplicatedStorage:WaitForChild("MissionEvents")
local stateChanged = missionEvents:WaitForChild("StateChanged")
local stateRequest = missionEvents:WaitForChild("StateRequest")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissionHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.DisplayOrder = 20
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "ObjectivePanel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.new(0, 22, 0, 90)
panel.Size = UDim2.new(0, 340, 0, 112)
panel.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(170, 45, 45)
stroke.Transparency = 0.25
stroke.Thickness = 1
stroke.Parent = panel

local eyebrow = Instance.new("TextLabel")
eyebrow.Name = "Eyebrow"
eyebrow.Position = UDim2.new(0, 14, 0, 9)
eyebrow.Size = UDim2.new(1, -28, 0, 17)
eyebrow.BackgroundTransparency = 1
eyebrow.Font = Enum.Font.GothamBold
eyebrow.Text = "PRIMARY OBJECTIVE"
eyebrow.TextColor3 = Color3.fromRGB(235, 75, 65)
eyebrow.TextSize = 10
eyebrow.TextXAlignment = Enum.TextXAlignment.Left
eyebrow.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "ObjectiveTitle"
title.Position = UDim2.new(0, 14, 0, 30)
title.Size = UDim2.new(1, -28, 0, 27)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "กำลังโหลดภารกิจ..."
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Parent = panel

local description = Instance.new("TextLabel")
description.Name = "ObjectiveDescription"
description.Position = UDim2.new(0, 14, 0, 61)
description.Size = UDim2.new(1, -28, 0, 36)
description.BackgroundTransparency = 1
description.Font = Enum.Font.Gotham
description.Text = "เชื่อมต่อระบบภารกิจ..."
description.TextColor3 = Color3.fromRGB(185, 192, 202)
description.TextSize = 12
description.TextWrapped = true
description.TextXAlignment = Enum.TextXAlignment.Left
description.TextYAlignment = Enum.TextYAlignment.Top
description.Parent = panel

local function render(snapshot)
    if type(snapshot) ~= "table" then
        return
    end

    if snapshot.isComplete then
        title.Text = "ภารกิจหลักสำเร็จ"
        description.Text = "ทีมทำภารกิจครบทุกขั้นตอนแล้ว"
        eyebrow.Text = "CAMPAIGN COMPLETE"
        return
    end

    local objective = snapshot.currentObjective
    if not objective then
        return
    end

    title.Text = objective.title or "ภารกิจใหม่"
    description.Text = objective.description or ""
    eyebrow.Text = string.format(
        "PRIMARY OBJECTIVE  //  %02d OF %02d",
        tonumber(snapshot.currentIndex) or 1,
        tonumber(snapshot.totalObjectives) or 1
    )
end

stateChanged.OnClientEvent:Connect(render)
stateRequest:FireServer()
