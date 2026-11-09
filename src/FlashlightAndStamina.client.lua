--[[
    FlashlightAndStamina.client.lua
    ใส่ใน: StarterPlayer -> StarterPlayerScripts
    หน้าที่: ควบคุมระบบไฟฉาย (กด F) และระบบวิ่งเร็ว/ค่าความเหนื่อย Stamina (กด LeftShift) พร้อม UI สวยงาม
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

----------------------------------------------------------------------
-- 1. ค่าตัวแปรระบบวิ่งและความเหนื่อย (STAMINA)
----------------------------------------------------------------------
local NORMAL_SPEED = 12
local SPRINT_SPEED = 22
local TIRED_SPEED = 7

local maxStamina = 100
local currentStamina = 100
local staminaDrain = 20    -- ลดลงวินาทีละ 20 หน่วย
local staminaRecovery = 15 -- ฟื้นฟูวินาทีละ 15 หน่วย
local isSprinting = false
local isExhausted = false

humanoid.WalkSpeed = NORMAL_SPEED

----------------------------------------------------------------------
-- 2. สร้าง UI แถบความเหนื่อย (STAMINA BAR UI)
----------------------------------------------------------------------
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HorrorSurvivalUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- กรอบพื้นหลังแถบ Stamina
local staminaFrame = Instance.new("Frame")
staminaFrame.Name = "StaminaFrame"
staminaFrame.Size = UDim2.new(0, 220, 0, 14)
staminaFrame.Position = UDim2.new(0.5, -110, 0.92, 0)
staminaFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
staminaFrame.BorderSizePixel = 0
staminaFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 7)
uiCorner.Parent = staminaFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(80, 80, 80)
uiStroke.Thickness = 1.5
uiStroke.Parent = staminaFrame

-- แถบสีด้านใน (Bar Fill)
local staminaBar = Instance.new("Frame")
staminaBar.Name = "Fill"
staminaBar.Size = UDim2.new(1, 0, 1, 0)
staminaBar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
staminaBar.BorderSizePixel = 0
staminaBar.Parent = staminaFrame

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 7)
fillCorner.Parent = staminaBar

-- ข้อความบอกปุ่มกด
local tipLabel = Instance.new("TextLabel")
tipLabel.Size = UDim2.new(0, 300, 0, 20)
tipLabel.Position = UDim2.new(0.5, -150, 0.88, 0)
tipLabel.BackgroundTransparency = 1
tipLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
tipLabel.Font = Enum.Font.SourceSansItalic
tipLabel.TextSize = 14
tipLabel.Text = "[F] เปิด/ปิดไฟฉาย   |   [Left Shift] วิ่งหนี"
tipLabel.Parent = screenGui

----------------------------------------------------------------------
-- 3. ระบบไฟฉาย (FLASHLIGHT SYSTEM)
----------------------------------------------------------------------
local flashlightOn = false
local flashlightLight = nil

local function setupFlashlight(char)
    local head = char:WaitForChild("Head", 10)
    if not head then return end

    -- สร้างไฟส่องสว่างติดที่ตัวผู้เล่น
    local light = Instance.new("SpotLight")
    light.Name = "PlayerFlashlight"
    light.Angle = 55
    light.Range = 55
    light.Brightness = 3.5
    light.Color = Color3.fromRGB(255, 245, 220)
    light.Shadows = true
    light.Enabled = false
    light.Parent = head

    flashlightLight = light
end

setupFlashlight(character)

local function toggleFlashlight()
    if not flashlightLight then return end
    flashlightOn = not flashlightOn
    flashlightLight.Enabled = flashlightOn

    -- เสียงคลิกสวิตช์
    local clickSound = Instance.new("Sound")
    clickSound.SoundId = "rbxassetid://9114223170"
    clickSound.Volume = 0.5
    clickSound.Parent = character:FindFirstChild("Head") or rootPart
    clickSound:Play()
    game:GetService("Debris"):AddItem(clickSound, 1)
end

----------------------------------------------------------------------
-- 4. การจัดการปุ่มกด (INPUT HANDLING)
----------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F then
        toggleFlashlight()
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        if not isExhausted and currentStamina > 10 then
            isSprinting = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        isSprinting = false
    end
end)

----------------------------------------------------------------------
-- 5. วงจรการอัปเดต STAMINA & SPEED ทุกเฟรม
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    if not humanoid or humanoid.Health <= 0 then return end

    -- ตรวจสอบว่าผู้เล่นกำลังเคลื่อนที่อยู่จริงหรือไม่
    local isMoving = humanoid.MoveDirection.Magnitude > 0.1

    if isSprinting and isMoving and not isExhausted then
        -- กำลังวิ่ง: ลด Stamina
        currentStamina = math.max(0, currentStamina - staminaDrain * dt)
        humanoid.WalkSpeed = SPRINT_SPEED

        if currentStamina <= 0 then
            -- หมดแรง
            isExhausted = true
            isSprinting = false
            humanoid.WalkSpeed = TIRED_SPEED
            staminaBar.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        end
    else
        -- ไม่ได้วิ่ง: ฟื้นฟู Stamina
        currentStamina = math.min(maxStamina, currentStamina + staminaRecovery * dt)

        if isExhausted then
            humanoid.WalkSpeed = TIRED_SPEED
            -- ต้องรอให้ฟื้นเกิน 35 ถึงจะวิ่งได้ใหม่
            if currentStamina >= 35 then
                isExhausted = false
                staminaBar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
                humanoid.WalkSpeed = NORMAL_SPEED
            end
        else
            humanoid.WalkSpeed = NORMAL_SPEED
        end
    end

    -- อัปเดตขนาดแถบ Stamina
    local ratio = currentStamina / maxStamina
    staminaBar.Size = UDim2.new(ratio, 0, 1, 0)
end)

-- รีเซ็ตเมื่อเกิดใหม่
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    flashlightOn = false
    currentStamina = 100
    isExhausted = false
    isSprinting = false
    setupFlashlight(character)
end)

print("[Player Controller] ระบบไฟฉาย (F) และ Stamina พร้อมทำงานแล้ว!")
