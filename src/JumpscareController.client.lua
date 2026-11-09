--[[
    JumpscareController.client.lua
    ใส่ใน: StarterPlayer -> StarterPlayerScripts
    หน้าที่: แสดง UI ภารกิจ, จัดการเอฟเฟกต์ Jumpscare เต็มจอ (หน้าผี, เสียงกรีดร้อง, จอสั่น), และหน้าจอจบเกมเมื่อหนีรอด
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local horrorEvents = ReplicatedStorage:WaitForChild("HorrorEvents", 15)
local updateQuestEvent = horrorEvents:WaitForChild("UpdateQuestUI", 15)
local alertMessageEvent = horrorEvents:WaitForChild("AlertMessage", 15)
local victoryEvent = horrorEvents:WaitForChild("VictoryEvent", 15)
local jumpscareEvent = horrorEvents:WaitForChild("TriggerJumpscare", 15)

----------------------------------------------------------------------
-- 1. สร้างหน้าจอหลัก (QUEST & NOTIFICATION UI)
----------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HorrorMainGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- กรอบแสดงภารกิจ (มุมบนซ้าย)
local questFrame = Instance.new("Frame")
questFrame.Name = "QuestFrame"
questFrame.Size = UDim2.new(0, 260, 0, 70)
questFrame.Position = UDim2.new(0, 20, 0, 30)
questFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
questFrame.BackgroundTransparency = 0.3
questFrame.BorderSizePixel = 0
questFrame.Parent = screenGui

local qCorner = Instance.new("UICorner")
qCorner.CornerRadius = UDim.new(0, 8)
qCorner.Parent = questFrame

local qStroke = Instance.new("UIStroke")
qStroke.Color = Color3.fromRGB(180, 40, 40)
qStroke.Thickness = 1.5
qStroke.Parent = questFrame

local questTitle = Instance.new("TextLabel")
questTitle.Size = UDim2.new(1, -16, 0, 24)
questTitle.Position = UDim2.new(0, 10, 0, 6)
questTitle.BackgroundTransparency = 1
questTitle.Text = "⚠️ ภารกิจหลบหนี"
questTitle.TextColor3 = Color3.fromRGB(255, 90, 90)
questTitle.Font = Enum.Font.SpecialElite
questTitle.TextSize = 16
questTitle.TextXAlignment = Enum.TextXAlignment.Left
questTitle.Parent = questFrame

local questText = Instance.new("TextLabel")
questText.Name = "QuestText"
questText.Size = UDim2.new(1, -16, 0, 28)
questText.Position = UDim2.new(0, 10, 0, 32)
questText.BackgroundTransparency = 1
questText.Text = "ตามหาฟิวส์ไฟฟ้า: 0 / 3 ชิ้น"
questText.TextColor3 = Color3.fromRGB(240, 240, 240)
questText.Font = Enum.Font.GothamMedium
questText.TextSize = 14
questText.TextXAlignment = Enum.TextXAlignment.Left
questText.Parent = questFrame

-- ป้ายแจ้งเตือนกลางจอ (Toast Notification)
local alertLabel = Instance.new("TextLabel")
alertLabel.Name = "AlertLabel"
alertLabel.Size = UDim2.new(0, 500, 0, 45)
alertLabel.Position = UDim2.new(0.5, -250, 0.2, 0)
alertLabel.BackgroundTransparency = 1
alertLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
alertLabel.Font = Enum.Font.SpecialElite
alertLabel.TextSize = 22
alertLabel.TextTransparency = 1
alertLabel.Text = ""
alertLabel.Parent = screenGui

local function showAlert(msg, color)
    alertLabel.Text = msg
    alertLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    alertLabel.TextTransparency = 0

    task.delay(3, function()
        TweenService:Create(alertLabel, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
    end)
end

updateQuestEvent.OnClientEvent:Connect(function(current, total)
    questText.Text = "ตามหาฟิวส์ไฟฟ้า: " .. current .. " / " .. total .. " ชิ้น"
    if current >= total then
        questText.Text = "✅ ฟิวส์ครบแล้ว! ไปเปิดสวิตช์ที่ประตูทางออก!"
        questText.TextColor3 = Color3.fromRGB(80, 255, 120)
    end
end)

alertMessageEvent.OnClientEvent:Connect(function(msg, color)
    showAlert(msg, color)
end)

----------------------------------------------------------------------
-- 2. ระบบ JUMPSCARE หลอนขั้นสุด (SCREAMER & SHAKE)
----------------------------------------------------------------------
local jumpscareGui = Instance.new("ScreenGui")
jumpscareGui.Name = "JumpscareGui"
jumpscareGui.ResetOnSpawn = false
jumpscareGui.IgnoreGuiInset = true
jumpscareGui.Enabled = false
jumpscareGui.DisplayOrder = 999
jumpscareGui.Parent = playerGui

-- แผ่นสีดำปิดจอ
local blackBg = Instance.new("Frame")
blackBg.Size = UDim2.new(1, 0, 1, 0)
blackBg.BackgroundColor3 = Color3.fromRGB(5, 0, 0)
blackBg.BorderSizePixel = 0
blackBg.Parent = jumpscareGui

-- ภาพหน้าผีสยองขวัญ (Scary Ghost Face)
local ghostImage = Instance.new("ImageLabel")
ghostImage.Name = "GhostFace"
ghostImage.Size = UDim2.new(1, 0, 1, 0)
ghostImage.Position = UDim2.new(0, 0, 0, 0)
ghostImage.BackgroundTransparency = 1
-- รหัสภาพหน้าผีสุดหลอนจาก Roblox Asset
ghostImage.Image = "rbxassetid://9114221147" -- Scary Face Texture / Screamer Asset
ghostImage.ScaleType = Enum.ScaleType.Fit
ghostImage.ImageColor3 = Color3.fromRGB(255, 30, 30)
ghostImage.Parent = jumpscareGui

-- เสียงกรีดร้องแสบแก้วหู
local screamSound = Instance.new("Sound")
screamSound.Name = "JumpscareScream"
screamSound.SoundId = "rbxassetid://9114221147" -- เสียงกรีดร้อง Jumpscare
screamSound.Volume = 3.0
screamSound.Parent = jumpscareGui

-- เอฟเฟกต์หน้าจอสั่น (Screen Shake)
local function screenShake(duration, intensity)
    local startTime = tick()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed > duration then
            conn:Disconnect()
            return
        end
        local offsetX = (math.random() - 0.5) * intensity
        local offsetY = (math.random() - 0.5) * intensity
        camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(offsetX), math.rad(offsetY), 0)
        ghostImage.Position = UDim2.new(0, (math.random() - 0.5) * 40, 0, (math.random() - 0.5) * 40)
    end)
end

jumpscareEvent.OnClientEvent:Connect(function(monsterModel)
    -- เปิดหน้าจอจั๊มสแก
    jumpscareGui.Enabled = true
    screamSound:Play()
    screenShake(2.0, 8)

    -- สลับกระพริบสีแดง-ดำ
    task.spawn(function()
        for i = 1, 15 do
            ghostImage.ImageColor3 = (i % 2 == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 0, 0)
            task.wait(0.08)
        end
    end)

    -- ซูมภาพหน้าผีเข้ามากระแทกตา
    ghostImage.Size = UDim2.new(0.8, 0, 0.8, 0)
    ghostImage.Position = UDim2.new(0.1, 0, 0.1, 0)
    TweenService:Create(
        ghostImage,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(1.3, 0, 1.3, 0), Position = UDim2.new(-0.15, 0, -0.15, 0) }
    ):Play()

    -- ดับหน้าจอเป็นสีดำสนิท
    task.wait(1.8)
    ghostImage.Visible = false
    blackBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

    task.wait(1.5)
    jumpscareGui.Enabled = false
    ghostImage.Visible = true
end)

----------------------------------------------------------------------
-- 3. หน้าจอจบเกมเมื่อหนีรอด (VICTORY ESCAPE UI)
----------------------------------------------------------------------
local victoryGui = Instance.new("ScreenGui")
victoryGui.Name = "VictoryGui"
victoryGui.ResetOnSpawn = false
victoryGui.IgnoreGuiInset = true
victoryGui.Enabled = false
victoryGui.Parent = playerGui

local vBg = Instance.new("Frame")
vBg.Size = UDim2.new(1, 0, 1, 0)
vBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
vBg.BackgroundTransparency = 0.2
vBg.BorderSizePixel = 0
vBg.Parent = victoryGui

local victoryTitle = Instance.new("TextLabel")
victoryTitle.Size = UDim2.new(1, 0, 0, 80)
victoryTitle.Position = UDim2.new(0, 0, 0.4, -40)
victoryTitle.BackgroundTransparency = 1
victoryTitle.Text = "YOU ESCAPED!"
victoryTitle.TextColor3 = Color3.fromRGB(80, 255, 120)
victoryTitle.Font = Enum.Font.SpecialElite
victoryTitle.TextSize = 65
victoryTitle.Parent = vBg

local victorySub = Instance.new("TextLabel")
victorySub.Size = UDim2.new(1, 0, 0, 40)
victorySub.Position = UDim2.new(0, 0, 0.55, 0)
victorySub.BackgroundTransparency = 1
victorySub.Text = "คุณเอาชีวิตรอดจากศูนย์วิจัยมรณะได้สำเร็จ..."
victorySub.TextColor3 = Color3.fromRGB(200, 200, 200)
victorySub.Font = Enum.Font.Gotham
victorySub.TextSize = 22
victorySub.Parent = vBg

victoryEvent.OnClientEvent:Connect(function()
    victoryGui.Enabled = true
    showAlert("🎉 คุณหนีรอดออกมาได้สำเร็จ!", Color3.fromRGB(0, 255, 150))
end)

print("[Jumpscare Controller] ระบบจั๊มสแกและภารกิจพร้อมทำงาน!")
