--[[
    FPSController.client.lua
    ใส่ใน: StarterPlayer -> StarterPlayerScripts
    หน้าที่: ล็อคมุมมองบุคคลที่หนึ่ง (First Person), เป้าเล็ง Crosshair กลางจอ,
            ระบบปืนพกเริ่มต้น (ยิง, รีโหลด R, กระสุน, ยิงหัว Headshot),
            HUD กระสุน, ประกาศ Wave, และกระดานคะแนนทีม (Team Points Scoreboard)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- 1. ล็อคมุมมองบุคคลที่หนึ่ง (FPS MODE)
player.CameraMode = Enum.CameraMode.LockFirstPerson

local zombieEvents = ReplicatedStorage:WaitForChild("ZombieGameEvents", 25)
local updateScoreboardEvent = zombieEvents:WaitForChild("UpdateScoreboard", 25)
local waveAnnounceEvent = zombieEvents:WaitForChild("WaveAnnounce", 25)
local zombieHitEvent = zombieEvents:WaitForChild("ZombieHitEvent", 25)

----------------------------------------------------------------------
-- 2. สร้างหน้าจอ HUD (HEADS-UP DISPLAY)
----------------------------------------------------------------------
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "ZombieFPS_HUD"
hudGui.ResetOnSpawn = false
hudGui.IgnoreGuiInset = true
hudGui.Parent = pGui

-- เป้าเล็ง Crosshair ตรงกลางจอ
local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.new(0, 6, 0, 6)
crosshair.Position = UDim2.new(0.5, -3, 0.5, -3)
crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
crosshair.BorderSizePixel = 0
crosshair.Parent = hudGui
Instance.new("UICorner", crosshair).CornerRadius = UDim.new(1, 0)

-- หลอดกระสุนมุมขวาล่าง
local ammoFrame = Instance.new("Frame")
ammoFrame.Size = UDim2.new(0, 180, 0, 60)
ammoFrame.Position = UDim2.new(1, -200, 1, -80)
ammoFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ammoFrame.BackgroundTransparency = 0.3
ammoFrame.Parent = hudGui
Instance.new("UICorner", ammoFrame).CornerRadius = UDim.new(0, 8)

local ammoText = Instance.new("TextLabel")
ammoText.Size = UDim2.new(1, 0, 1, 0)
ammoText.BackgroundTransparency = 1
ammoText.TextColor3 = Color3.fromRGB(255, 220, 80)
ammoText.Font = Enum.Font.SpecialElite
ammoText.TextSize = 28
ammoText.Text = "12 / 72"
ammoText.Parent = ammoFrame

-- ป้ายบอก Wave มุมซ้ายบน
local waveFrame = Instance.new("Frame")
waveFrame.Size = UDim2.new(0, 160, 0, 50)
waveFrame.Position = UDim2.new(0, 20, 0, 25)
waveFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
waveFrame.BackgroundTransparency = 0.3
waveFrame.Parent = hudGui
Instance.new("UICorner", waveFrame).CornerRadius = UDim.new(0, 8)

local waveText = Instance.new("TextLabel")
waveText.Size = UDim2.new(1, 0, 1, 0)
waveText.BackgroundTransparency = 1
waveText.TextColor3 = Color3.fromRGB(255, 50, 50)
waveText.Font = Enum.Font.SpecialElite
waveText.TextSize = 26
waveText.Text = "WAVE 1"
waveText.Parent = waveFrame

-- ป้ายประกาศกลางจอ (Wave Announcement Toast)
local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.new(0, 700, 0, 80)
toastLabel.Position = UDim2.new(0.5, -350, 0.22, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
toastLabel.Font = Enum.Font.SpecialElite
toastLabel.TextSize = 28
toastLabel.TextTransparency = 1
toastLabel.Parent = hudGui

local function showAnnouncement(msg, color)
    toastLabel.Text = msg
    toastLabel.TextColor3 = color or Color3.fromRGB(255, 220, 50)
    toastLabel.TextTransparency = 0
    task.delay(4, function()
        TweenService:Create(toastLabel, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
    end)
end

waveAnnounceEvent.OnClientEvent:Connect(function(waveNum, message)
    if waveNum > 0 then
        waveText.Text = "WAVE " .. waveNum
    end
    showAnnouncement(message)
end)

----------------------------------------------------------------------
-- 3. กระดานคะแนนทีม (TEAM SCOREBOARD UI มุมขวาบน)
----------------------------------------------------------------------
local scoreFrame = Instance.new("Frame")
scoreFrame.Size = UDim2.new(0, 260, 0, 160)
scoreFrame.Position = UDim2.new(1, -280, 0, 25)
scoreFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
scoreFrame.BackgroundTransparency = 0.35
scoreFrame.Parent = hudGui
Instance.new("UICorner", scoreFrame).CornerRadius = UDim.new(0, 8)

local scoreTitle = Instance.new("TextLabel")
scoreTitle.Size = UDim2.new(1, 0, 0, 26)
scoreTitle.BackgroundTransparency = 1
scoreTitle.Text = "👥 TEAM POINTS"
scoreTitle.TextColor3 = Color3.fromRGB(255, 200, 80)
scoreTitle.Font = Enum.Font.GothamBold
scoreTitle.TextSize = 14
scoreTitle.Parent = scoreFrame

local scoreListContainer = Instance.new("ScrollingFrame")
scoreListContainer.Size = UDim2.new(1, -12, 1, -32)
scoreListContainer.Position = UDim2.new(0, 6, 0, 28)
scoreListContainer.BackgroundTransparency = 1
scoreListContainer.ScrollBarThickness = 2
scoreListContainer.Parent = scoreFrame

local scoreListLayout = Instance.new("UIListLayout")
scoreListLayout.Padding = UDim.new(0, 4)
scoreListLayout.Parent = scoreListContainer

updateScoreboardEvent.OnClientEvent:Connect(function(teamScores)
    for _, child in ipairs(scoreListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for _, pData in ipairs(teamScores) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 24)
        row.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        row.BackgroundTransparency = 0.5
        row.Parent = scoreListContainer
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.48, 0, 1, 0)
        nameLabel.Position = UDim2.new(0.04, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Text = pData.Name
        nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.TextSize = 12
        nameLabel.Parent = row

        local pointsLabel = Instance.new("TextLabel")
        pointsLabel.Size = UDim2.new(0.44, 0, 1, 0)
        pointsLabel.Position = UDim2.new(0.52, 0, 0, 0)
        pointsLabel.BackgroundTransparency = 1
        pointsLabel.TextXAlignment = Enum.TextXAlignment.Right
        pointsLabel.Text = pData.Points .. " Pts (" .. pData.Kills .. "K)"
        pointsLabel.TextColor3 = (pData.Status == "Downed") and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 220, 80)
        pointsLabel.Font = Enum.Font.GothamBold
        pointsLabel.TextSize = 12
        pointsLabel.Parent = row
    end
end)

----------------------------------------------------------------------
-- 4. ระบบปืนพกเริ่มต้น (STARTER PISTOL & SHOOTING)
----------------------------------------------------------------------
local clipAmmo = 12
local reserveAmmo = 72
local maxClip = 12
local isReloading = false
local fireRateCooldown = false

local function updateAmmoUI()
    ammoText.Text = clipAmmo .. " / " .. reserveAmmo
    if clipAmmo == 0 then
        ammoText.TextColor3 = Color3.fromRGB(255, 60, 60)
    else
        ammoText.TextColor3 = Color3.fromRGB(255, 220, 80)
    end
end

local function reloadWeapon()
    if isReloading or clipAmmo == maxClip or reserveAmmo <= 0 then return end
    isReloading = true
    ammoText.Text = "RELOADING..."
    ammoText.TextColor3 = Color3.fromRGB(255, 180, 50)

    -- เสียงรีโหลด
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://9114223170"
    s.Volume = 0.7
    s.Parent = camera
    s:Play()
    Debris:AddItem(s, 2)

    task.wait(1.5)
    local needed = maxClip - clipAmmo
    local toAdd = math.min(needed, reserveAmmo)
    clipAmmo = clipAmmo + toAdd
    reserveAmmo = reserveAmmo - toAdd
    isReloading = false
    updateAmmoUI()
end

local function shootWeapon()
    if fireRateCooldown or isReloading then return end
    if clipAmmo <= 0 then
        reloadWeapon()
        return
    end

    fireRateCooldown = true
    clipAmmo = clipAmmo - 1
    updateAmmoUI()

    -- เสียงปืนพก
    local gunSound = Instance.new("Sound")
    gunSound.SoundId = "rbxassetid://9114221147"
    gunSound.Volume = 1.0
    gunSound.Parent = camera
    gunSound:Play()
    Debris:AddItem(gunSound, 1.5)

    -- แรงถีบปืน (Recoil Shake)
    camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(1.2), math.rad((math.random() - 0.5) * 0.8), 0)

    -- ยิงกระสุน Raycast จากกลางหน้าจอ
    local rayOrigin = camera.CFrame.Position
    local rayDirection = camera.CFrame.LookVector * 200

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { player.Character }
    rayParams.FilterType = RaycastFilterType.Exclude

    local hit = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
    if hit and hit.Instance then
        local hitPart = hit.Instance
        local hitZombie = hitPart:FindFirstAncestorOfClass("Model")
        if hitZombie and hitZombie.Name:sub(1, 7) == "Zombie_" then
            local isHeadshot = (hitPart.Name == "Head" or hitPart.Name == "Eyes")
            local dmg = isHeadshot and 100 or 35
            zombieHitEvent:FireServer(hitPart, dmg, isHeadshot)

            -- เอฟเฟกต์กระพริบ Crosshair สีแดงเวลายิงโดน
            crosshair.BackgroundColor3 = isHeadshot and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(255, 180, 0)
            task.delay(0.1, function()
                crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            end)
        end
    end

    task.wait(0.2)
    fireRateCooldown = false
end

-- การควบคุมเมาส์และปุ่มกด
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        shootWeapon()
    elseif input.KeyCode == Enum.KeyCode.R then
        reloadWeapon()
    end
end)

print("🎯 ระบบ FPS Mode และปืนพกเริ่มต้น อาคาร 40 ปี มจพ. พร้อมทำงานแล้ว!")
