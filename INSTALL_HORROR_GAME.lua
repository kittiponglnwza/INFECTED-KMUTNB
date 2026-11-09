--[[
    ========================================================================
    🎃 ONE-CLICK HORROR GAME INSTALLER (สคริปต์ติดตั้งเกมผีในคลิกเดียว!)
    ========================================================================
    วิธีใช้:
    1. เปิด Roblox Studio (แมพ Baseplate เปล่าๆ)
    2. สร้าง Script ตัวเดียว ใน ServerScriptService
    3. วางโค้ดนี้ทั้งหมดลงไป แล้วกด [PLAY] หรือรันผ่าน Command Bar
    -> ระบบทั้งหมด (แมพ, ไฟฉาย, ผี AI, ภารกิจฟิวส์, จั๊มสแก, หมอก) จะถูกติดตั้งและเริ่มทำงานทันที!
    ========================================================================
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

print("========================================")
print("⏳ กำลังเริ่มติดตั้งเกม Midnight Lockdown...")
print("========================================")

----------------------------------------------------------------------
-- 1. SETUP REPLICATED STORAGE (NETWORK EVENTS)
----------------------------------------------------------------------
local horrorEvents = ReplicatedStorage:FindFirstChild("HorrorEvents") or Instance.new("Folder")
horrorEvents.Name = "HorrorEvents"
horrorEvents.Parent = ReplicatedStorage

local function getOrCreateEvent(name)
    local ev = horrorEvents:FindFirstChild(name)
    if not ev then
        ev = Instance.new("RemoteEvent")
        ev.Name = name
        ev.Parent = horrorEvents
    end
    return ev
end

local updateQuestEvent = getOrCreateEvent("UpdateQuestUI")
local alertMessageEvent = getOrCreateEvent("AlertMessage")
local victoryEvent = getOrCreateEvent("VictoryEvent")
local jumpscareEvent = getOrCreateEvent("TriggerJumpscare")

----------------------------------------------------------------------
-- 2. SETUP LIGHTING & ATMOSPHERE (บรรยากาศสว่างสดใส)
----------------------------------------------------------------------
Lighting.ClockTime = 14
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
Lighting.Ambient = Color3.fromRGB(150, 150, 150)
Lighting.FogColor = Color3.fromRGB(200, 200, 200)
Lighting.FogStart = 100
Lighting.FogEnd = 10000
Lighting.GlobalShadows = true

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
atmosphere.Density = 0.1
atmosphere.Offset = 0.25
atmosphere.Color = Color3.fromRGB(200, 210, 225)
atmosphere.Decay = Color3.fromRGB(220, 220, 230)

local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
cc.Saturation = 0.2
cc.Contrast = 0.05
cc.Brightness = 0.1
cc.TintColor = Color3.fromRGB(255, 255, 255)

local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
bloom.Intensity = 0.4
bloom.Size = 10

----------------------------------------------------------------------
-- 3. HELPER FUNCTIONS & MAP GENERATOR
----------------------------------------------------------------------
local function createPart(parent, name, size, cframe, color, material, anchored)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color or Color3.fromRGB(50, 50, 55)
    part.Material = material or Enum.Material.Concrete
    part.Anchored = (anchored == nil) and true or anchored
    part.CastShadow = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function createFlickeringLight(parent, position, lightColor)
    createPart(parent, "LightFixture", Vector3.new(2, 0.4, 2), CFrame.new(position), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
    local bulb = createPart(parent, "Bulb", Vector3.new(1.2, 0.3, 1.2), CFrame.new(position - Vector3.new(0, 0.2, 0)), Color3.fromRGB(255, 240, 180), Enum.Material.Neon)
    
    local pointLight = Instance.new("PointLight")
    pointLight.Color = lightColor or Color3.fromRGB(255, 215, 160)
    pointLight.Range = 26
    pointLight.Brightness = 1.4
    pointLight.Shadows = true
    pointLight.Parent = bulb

    task.spawn(function()
        local orig = pointLight.Brightness
        while bulb and bulb.Parent do
            task.wait(math.random(3, 8))
            for i = 1, math.random(2, 5) do
                pointLight.Brightness = 0
                bulb.Material = Enum.Material.SmoothPlastic
                task.wait(math.random(5, 12)/100)
                pointLight.Brightness = orig
                bulb.Material = Enum.Material.Neon
                task.wait(math.random(5, 15)/100)
            end
        end
    end)
    return bulb
end

-- ลบแมพเก่าถ้าเคยสร้างไว้
if Workspace:FindFirstChild("HorrorFacility") then
    Workspace.HorrorFacility:Destroy()
end

local facility = Instance.new("Model")
facility.Name = "HorrorFacility"
facility.Parent = Workspace

local wallColor = Color3.fromRGB(45, 48, 52)
local floorColor = Color3.fromRGB(35, 36, 38)
local ceilingColor = Color3.fromRGB(28, 28, 30)
local wallH, hallL, hallW = 14, 120, 16

-- พื้นและเพดานทางเดิน
createPart(facility, "HallFloor", Vector3.new(hallW, 1, hallL), CFrame.new(0, 0, 0), floorColor)
createPart(facility, "HallCeiling", Vector3.new(hallW, 1, hallL), CFrame.new(0, wallH, 0), ceilingColor)

-- กำแพงทางเดิน
createPart(facility, "WallL1", Vector3.new(1, wallH, 30), CFrame.new(-hallW/2, wallH/2, -40), wallColor)
createPart(facility, "WallL2", Vector3.new(1, wallH, 30), CFrame.new(-hallW/2, wallH/2, 0), wallColor)
createPart(facility, "WallL3", Vector3.new(1, wallH, 30), CFrame.new(-hallW/2, wallH/2, 40), wallColor)
createPart(facility, "WallR1", Vector3.new(1, wallH, 30), CFrame.new(hallW/2, wallH/2, -40), wallColor)
createPart(facility, "WallR2", Vector3.new(1, wallH, 30), CFrame.new(hallW/2, wallH/2, 0), wallColor)
createPart(facility, "WallR3", Vector3.new(1, wallH, 30), CFrame.new(hallW/2, wallH/2, 40), wallColor)
createPart(facility, "BackWall", Vector3.new(hallW, wallH, 1), CFrame.new(0, wallH/2, hallL/2), wallColor)

-- จุดเกิดผู้เล่น
local spawn = Instance.new("SpawnLocation")
spawn.Name = "FacilitySpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.CFrame = CFrame.new(0, 0.5, (hallL/2) - 8)
spawn.Anchored = true
spawn.CanCollide = false
spawn.Transparency = 1
spawn.Parent = facility

-- ฟังก์ชันสร้างห้องย่อย
local function buildRoom(roomName, centerPos, roomW, roomL)
    local room = Instance.new("Model")
    room.Name = roomName
    room.Parent = facility

    createPart(room, "Floor", Vector3.new(roomW, 1, roomL), CFrame.new(centerPos.X, 0, centerPos.Z), floorColor, Enum.Material.WoodPlanks)
    createPart(room, "Ceiling", Vector3.new(roomW, 1, roomL), CFrame.new(centerPos.X, wallH, centerPos.Z), ceilingColor)

    local halfW, halfL = roomW/2, roomL/2
    createPart(room, "WallNorth", Vector3.new(roomW, wallH, 1), CFrame.new(centerPos.X, wallH/2, centerPos.Z - halfL), wallColor)
    createPart(room, "WallSouth", Vector3.new(roomW, wallH, 1), CFrame.new(centerPos.X, wallH/2, centerPos.Z + halfL), wallColor)
    
    if centerPos.X < 0 then
        createPart(room, "WallOuter", Vector3.new(1, wallH, roomL), CFrame.new(centerPos.X - halfW, wallH/2, centerPos.Z), wallColor)
    else
        createPart(room, "WallOuter", Vector3.new(1, wallH, roomL), CFrame.new(centerPos.X + halfW, wallH/2, centerPos.Z), wallColor)
    end

    createPart(room, "BrokenTable", Vector3.new(7, 3, 4), CFrame.new(centerPos.X, 1.5, centerPos.Z) * CFrame.Angles(0, math.rad(25), math.rad(5)), Color3.fromRGB(60, 45, 35), Enum.Material.Wood)
    createFlickeringLight(room, centerPos + Vector3.new(0, wallH - 0.5, 0), Color3.fromRGB(200, 160, 120))
    return room
end

buildRoom("Room_A", Vector3.new(-28, 0, -20), 40, 32)
buildRoom("Room_B", Vector3.new(28, 0, -20), 40, 32)
buildRoom("Room_C", Vector3.new(-28, 0, 20), 40, 32)

createFlickeringLight(facility, Vector3.new(0, wallH - 0.5, -35), Color3.fromRGB(255, 120, 100))
createFlickeringLight(facility, Vector3.new(0, wallH - 0.5, 0), Color3.fromRGB(150, 180, 255))
createFlickeringLight(facility, Vector3.new(0, wallH - 0.5, 35), Color3.fromRGB(220, 220, 180))

-- ประตูทางออกและตู้ปั่นไฟ
local exitArea = Instance.new("Model")
exitArea.Name = "ExitArea"
exitArea.Parent = facility

local gateZ = -(hallL/2)
createPart(exitArea, "FrontWallL", Vector3.new(4, wallH, 1), CFrame.new(-6, wallH/2, gateZ), wallColor)
createPart(exitArea, "FrontWallR", Vector3.new(4, wallH, 1), CFrame.new(6, wallH/2, gateZ), wallColor)
createPart(exitArea, "FrontWallTop", Vector3.new(hallW, 4, 1), CFrame.new(0, wallH - 2, gateZ), wallColor)

local exitDoor = createPart(exitArea, "ExitDoor", Vector3.new(8, 10, 1.2), CFrame.new(0, 5, gateZ), Color3.fromRGB(120, 30, 30), Enum.Material.Metal)

local generator = createPart(exitArea, "GeneratorBox", Vector3.new(3, 5, 2), CFrame.new(6, 2.5, gateZ + 2), Color3.fromRGB(40, 60, 45), Enum.Material.Metal)
local statusLight = Instance.new("PointLight")
statusLight.Name = "StatusLight"
statusLight.Color = Color3.fromRGB(255, 30, 30)
statusLight.Range = 10
statusLight.Brightness = 1.5
statusLight.Parent = generator

local sGui = Instance.new("SurfaceGui")
sGui.Face = Enum.NormalId.Front
sGui.Parent = generator
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SpecialElite
statusLabel.Text = "POWER OFFLINE\n[NEED 3 FUSES]"
statusLabel.Parent = sGui

----------------------------------------------------------------------
-- 4. QUEST LOGIC & FUSE SPAWNER
----------------------------------------------------------------------
local playerFuses = {}
local TOTAL_FUSES_NEEDED = 3
local isFacilityPowered = false

local function spawnFuse(name, position)
    local fuseModel = Instance.new("Model")
    fuseModel.Name = name
    fuseModel.Parent = facility

    local fusePart = Instance.new("Part")
    fusePart.Name = "FuseBody"
    fusePart.Size = Vector3.new(0.8, 1.8, 0.8)
    fusePart.CFrame = CFrame.new(position)
    fusePart.Color = Color3.fromRGB(0, 200, 255)
    fusePart.Material = Enum.Material.Neon
    fusePart.Anchored = true
    fusePart.CanCollide = false
    fusePart.Parent = fuseModel

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(0, 220, 255)
    light.Range = 12
    light.Brightness = 2.5
    light.Parent = fusePart

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "เก็บฟิวส์ไฟฟ้า"
    prompt.ObjectText = "Energy Fuse"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 8
    prompt.Parent = fusePart

    prompt.Triggered:Connect(function(player)
        local count = (playerFuses[player.UserId] or 0) + 1
        playerFuses[player.UserId] = count

        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://9114223170"
        s.Parent = player.Character or Workspace
        s:Play()
        game:GetService("Debris"):AddItem(s, 2)

        updateQuestEvent:FireClient(player, count, TOTAL_FUSES_NEEDED)
        alertMessageEvent:FireClient(player, "คุณเก็บฟิวส์ได้แล้ว (" .. count .. "/" .. TOTAL_FUSES_NEEDED .. ")", Color3.fromRGB(0, 255, 180))
        fuseModel:Destroy()
    end)

    task.spawn(function()
        local origY = position.Y
        local t = 0
        while fusePart and fusePart.Parent do
            t = t + 0.05
            fusePart.CFrame = CFrame.new(position.X, origY + math.sin(t * 2) * 0.3, position.Z) * CFrame.Angles(0, t, 0)
            task.wait(0.03)
        end
    end)
end

spawnFuse("Fuse_1", Vector3.new(-28, 2, -20))
spawnFuse("Fuse_2", Vector3.new(28, 2, -20))
spawnFuse("Fuse_3", Vector3.new(-28, 2, 20))

local genPrompt = Instance.new("ProximityPrompt")
genPrompt.ActionText = "เปิดเครื่องจ่ายไฟ"
genPrompt.ObjectText = "Main Generator"
genPrompt.HoldDuration = 1.0
genPrompt.MaxActivationDistance = 9
genPrompt.Parent = generator

genPrompt.Triggered:Connect(function(player)
    if isFacilityPowered then return end
    local count = playerFuses[player.UserId] or 0
    if count < TOTAL_FUSES_NEEDED then
        alertMessageEvent:FireClient(player, "ไฟฟ้าไม่พอ! ต้องหาฟิวส์ให้ครบ 3 ตัวก่อน (ตอนนี้มี " .. count .. "/3)", Color3.fromRGB(255, 80, 80))
    else
        isFacilityPowered = true
        genPrompt.Enabled = false
        statusLight.Color = Color3.fromRGB(0, 255, 0)
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        statusLabel.Text = "SYSTEM ONLINE\n[EXIT OPEN]"

        for _, p in ipairs(Players:GetPlayers()) do
            alertMessageEvent:FireClient(p, "⚠️ เครื่องกำเนิดไฟฟ้าทำงานแล้ว! ประตูทางออกเปิดออก!", Color3.fromRGB(255, 220, 0))
        end

        TweenService:Create(exitDoor, TweenInfo.new(3), { CFrame = exitDoor.CFrame + Vector3.new(0, 10, 0) }):Play()
        exitDoor.CanCollide = false
    end
end)

local escapePad = Instance.new("Part")
escapePad.Size = Vector3.new(12, 10, 4)
escapePad.CFrame = CFrame.new(0, 5, -(hallL/2) - 5)
escapePad.Transparency = 1
escapePad.Anchored = true
escapePad.CanCollide = false
escapePad.Parent = facility

escapePad.Touched:Connect(function(hit)
    local player = Players:GetPlayerFromCharacter(hit.Parent)
    if player and isFacilityPowered then
        victoryEvent:FireClient(player)
    end
end)

Players.PlayerAdded:Connect(function(p)
    playerFuses[p.UserId] = 0
    task.wait(1)
    updateQuestEvent:FireClient(p, 0, TOTAL_FUSES_NEEDED)
end)

----------------------------------------------------------------------
-- 5. MONSTER AI (ผีออกล่า)
----------------------------------------------------------------------
if Workspace:FindFirstChild("ShadowStalker") then
    Workspace.ShadowStalker:Destroy()
end

local monster = Instance.new("Model")
monster.Name = "ShadowStalker"
monster.Parent = Workspace

local hrp = createPart(monster, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 5, -20), Color3.new(0,0,0), Enum.Material.SmoothPlastic, false)
hrp.Transparency = 1
local torso = createPart(monster, "Torso", Vector3.new(2.4, 3.5, 1.2), hrp.CFrame, Color3.fromRGB(10, 10, 10), Enum.Material.SmoothPlastic, false)
local head = createPart(monster, "Head", Vector3.new(1.8, 1.8, 1.8), torso.CFrame + Vector3.new(0, 2.6, 0), Color3.fromRGB(5, 5, 5), Enum.Material.SmoothPlastic, false)

local function weld(p0, p1)
    local w = Instance.new("WeldConstraint")
    w.Part0 = p0
    w.Part1 = p1
    w.Parent = p0
end
weld(hrp, torso)
weld(torso, head)

local eyeLight = Instance.new("PointLight")
eyeLight.Color = Color3.fromRGB(255, 20, 20)
eyeLight.Range = 10
eyeLight.Brightness = 2.5
eyeLight.Parent = head

local mHumanoid = Instance.new("Humanoid")
mHumanoid.MaxHealth = 999999
mHumanoid.Health = 999999
mHumanoid.WalkSpeed = 9
mHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
mHumanoid.Parent = monster
monster.PrimaryPart = hrp

local waypoints = {
    Vector3.new(0, 3, 30),
    Vector3.new(-28, 3, 20),
    Vector3.new(0, 3, 0),
    Vector3.new(-28, 3, -20),
    Vector3.new(0, 3, -30),
    Vector3.new(28, 3, -20),
}
local wpIndex = 1
local isChasing = false
local isCooldown = false

task.spawn(function()
    while monster and monster.Parent and mHumanoid.Health > 0 do
        if isCooldown then task.wait(1) continue end

        local target = nil
        local shortest = 45
        for _, p in ipairs(Players:GetPlayers()) do
            local c = p.Character
            if c and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 and c:FindFirstChild("HumanoidRootPart") then
                local dist = (c.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist < shortest then
                    target = c
                    shortest = dist
                end
            end
        end

        if target then
            if not isChasing then
                isChasing = true
                mHumanoid.WalkSpeed = 19
            end
            local tHrp = target:FindFirstChild("HumanoidRootPart")
            if tHrp then
                mHumanoid:MoveTo(tHrp.Position)
                if (tHrp.Position - hrp.Position).Magnitude <= 4.5 then
                    local victim = Players:GetPlayerFromCharacter(target)
                    if victim then
                        isCooldown = true
                        isChasing = false
                        mHumanoid.WalkSpeed = 0
                        jumpscareEvent:FireClient(victim, monster)
                        task.delay(2.2, function()
                            if target:FindFirstChild("Humanoid") then target.Humanoid.Health = 0 end
                            task.wait(3)
                            isCooldown = false
                            mHumanoid.WalkSpeed = 9
                        end)
                    end
                end
            end
        else
            if isChasing then
                isChasing = false
                mHumanoid.WalkSpeed = 9
            end
            local wp = waypoints[wpIndex]
            mHumanoid:MoveTo(wp)
            if (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(wp.X, 0, wp.Z)).Magnitude < 5 then
                wpIndex = (wpIndex % #waypoints) + 1
                task.wait(math.random(1, 2))
            end
        end
        task.wait(0.2)
    end
end)

----------------------------------------------------------------------
-- 6. SETUP CLIENT SCRIPTS (FLASHLIGHT, STAMINA, JUMPSCARE & QUEST UI)
----------------------------------------------------------------------
local starterScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- ติดตั้ง Client Script ให้อัตโนมัติใน StarterPlayerScripts
local clientInstaller = starterScripts:FindFirstChild("HorrorClientSetup") or Instance.new("LocalScript")
clientInstaller.Name = "HorrorClientSetup"
clientInstaller.Source = [==[
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local horrorEvents = ReplicatedStorage:WaitForChild("HorrorEvents", 15)
local updateQuestEvent = horrorEvents:WaitForChild("UpdateQuestUI", 15)
local alertMessageEvent = horrorEvents:WaitForChild("AlertMessage", 15)
local victoryEvent = horrorEvents:WaitForChild("VictoryEvent", 15)
local jumpscareEvent = horrorEvents:WaitForChild("TriggerJumpscare", 15)

-- 1. UI ภารกิจ & Stamina
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "HorrorMainGui"
mainGui.ResetOnSpawn = false
mainGui.Parent = pGui

local qFrame = Instance.new("Frame")
qFrame.Size = UDim2.new(0, 240, 0, 65)
qFrame.Position = UDim2.new(0, 20, 0, 25)
qFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
qFrame.BackgroundTransparency = 0.3
qFrame.Parent = mainGui
Instance.new("UICorner", qFrame).CornerRadius = UDim.new(0, 8)

local qTitle = Instance.new("TextLabel")
qTitle.Size = UDim2.new(1, -16, 0, 22)
qTitle.Position = UDim2.new(0, 10, 0, 5)
qTitle.BackgroundTransparency = 1
qTitle.Text = "⚠️ ภารกิจหลบหนี"
qTitle.TextColor3 = Color3.fromRGB(255, 80, 80)
qTitle.Font = Enum.Font.SpecialElite
qTitle.TextSize = 15
qTitle.TextXAlignment = Enum.TextXAlignment.Left
qTitle.Parent = qFrame

local qText = Instance.new("TextLabel")
qText.Size = UDim2.new(1, -16, 0, 25)
qText.Position = UDim2.new(0, 10, 0, 30)
qText.BackgroundTransparency = 1
qText.Text = "ตามหาฟิวส์ไฟฟ้า: 0 / 3 ชิ้น"
qText.TextColor3 = Color3.fromRGB(240, 240, 240)
qText.Font = Enum.Font.GothamMedium
qText.TextSize = 13
qText.TextXAlignment = Enum.TextXAlignment.Left
qText.Parent = qFrame

-- Stamina Bar
local sFrame = Instance.new("Frame")
sFrame.Size = UDim2.new(0, 200, 0, 12)
sFrame.Position = UDim2.new(0.5, -100, 0.92, 0)
sFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
sFrame.Parent = mainGui
Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 6)

local sFill = Instance.new("Frame")
sFill.Size = UDim2.new(1, 0, 1, 0)
sFill.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
sFill.BorderSizePixel = 0
sFill.Parent = sFrame
Instance.new("UICorner", sFill).CornerRadius = UDim.new(0, 6)

local tip = Instance.new("TextLabel")
tip.Size = UDim2.new(0, 300, 0, 18)
tip.Position = UDim2.new(0.5, -150, 0.88, 0)
tip.BackgroundTransparency = 1
tip.TextColor3 = Color3.fromRGB(180, 180, 180)
tip.Font = Enum.Font.SourceSansItalic
tip.TextSize = 13
tip.Text = "[F] ไฟฉาย   |   [Shift] วิ่งหนี"
tip.Parent = mainGui

local alertLabel = Instance.new("TextLabel")
alertLabel.Size = UDim2.new(0, 500, 0, 40)
alertLabel.Position = UDim2.new(0.5, -250, 0.2, 0)
alertLabel.BackgroundTransparency = 1
alertLabel.Font = Enum.Font.SpecialElite
alertLabel.TextSize = 20
alertLabel.TextTransparency = 1
alertLabel.Parent = mainGui

updateQuestEvent.OnClientEvent:Connect(function(c, t)
    qText.Text = "ตามหาฟิวส์ไฟฟ้า: " .. c .. " / " .. t .. " ชิ้น"
    if c >= t then
        qText.Text = "✅ ฟิวส์ครบแล้ว! ไปเปิดสวิตช์ที่ประตูทางออก!"
        qText.TextColor3 = Color3.fromRGB(80, 255, 120)
    end
end)

alertMessageEvent.OnClientEvent:Connect(function(msg, col)
    alertLabel.Text = msg
    alertLabel.TextColor3 = col or Color3.fromRGB(255, 255, 255)
    alertLabel.TextTransparency = 0
    task.delay(3, function()
        TweenService:Create(alertLabel, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
    end)
end)

-- 2. Flashlight & Stamina Logic
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local flashLight = nil
local flashOn = false

local function setupLight(c)
    local head = c:WaitForChild("Head", 10)
    if not head then return end
    flashLight = Instance.new("SpotLight")
    flashLight.Angle = 55
    flashLight.Range = 55
    flashLight.Brightness = 3.5
    flashLight.Color = Color3.fromRGB(255, 245, 220)
    flashLight.Shadows = true
    flashLight.Enabled = false
    flashLight.Parent = head
end
setupLight(char)

local stamina = 100
local sprinting = false
local exhausted = false

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F and flashLight then
        flashOn = not flashOn
        flashLight.Enabled = flashOn
    elseif i.KeyCode == Enum.KeyCode.LeftShift and not exhausted and stamina > 10 then
        sprinting = true
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.LeftShift then
        sprinting = false
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not hum or hum.Health <= 0 then return end
    local moving = hum.MoveDirection.Magnitude > 0.1
    if sprinting and moving and not exhausted then
        stamina = math.max(0, stamina - 20 * dt)
        hum.WalkSpeed = 22
        if stamina <= 0 then
            exhausted = true
            sprinting = false
            hum.WalkSpeed = 7
            sFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        end
    else
        stamina = math.min(100, stamina + 15 * dt)
        if exhausted then
            hum.WalkSpeed = 7
            if stamina >= 35 then
                exhausted = false
                sFill.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
                hum.WalkSpeed = 12
            end
        else
            hum.WalkSpeed = 12
        end
    end
    sFill.Size = UDim2.new(stamina/100, 0, 1, 0)
end)

player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hum = char:WaitForChild("Humanoid")
    flashOn = false
    stamina = 100
    setupLight(char)
end)

-- 3. Jumpscare
local jumpGui = Instance.new("ScreenGui")
jumpGui.Name = "JumpscareGui"
jumpGui.ResetOnSpawn = false
jumpGui.IgnoreGuiInset = true
jumpGui.Enabled = false
jumpGui.DisplayOrder = 999
jumpGui.Parent = pGui

local black = Instance.new("Frame")
black.Size = UDim2.new(1, 0, 1, 0)
black.BackgroundColor3 = Color3.fromRGB(5, 0, 0)
black.Parent = jumpGui

local ghost = Instance.new("ImageLabel")
ghost.Size = UDim2.new(1, 0, 1, 0)
ghost.BackgroundTransparency = 1
ghost.Image = "rbxassetid://9114221147"
ghost.ScaleType = Enum.ScaleType.Fit
ghost.Parent = jumpGui

local sSound = Instance.new("Sound")
sSound.SoundId = "rbxassetid://9114221147"
sSound.Volume = 3
sSound.Parent = jumpGui

jumpscareEvent.OnClientEvent:Connect(function()
    jumpGui.Enabled = true
    sSound:Play()
    local start = tick()
    local c
    c = RunService.RenderStepped:Connect(function()
        if tick() - start > 2 then c:Disconnect() return end
        camera.CFrame = camera.CFrame * CFrame.Angles(math.rad((math.random()-0.5)*8), math.rad((math.random()-0.5)*8), 0)
    end)
    task.wait(1.8)
    ghost.Visible = false
    task.wait(1.2)
    jumpGui.Enabled = false
    ghost.Visible = true
end)

-- 4. Victory
victoryEvent.OnClientEvent:Connect(function()
    local vGui = Instance.new("ScreenGui")
    vGui.IgnoreGuiInset = true
    vGui.Parent = pGui
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 0.2
    bg.Parent = vGui
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1,0,0,80)
    txt.Position = UDim2.new(0,0,0.4,-40)
    txt.BackgroundTransparency = 1
    txt.Text = "YOU ESCAPED!"
    txt.TextColor3 = Color3.fromRGB(80, 255, 120)
    txt.Font = Enum.Font.SpecialElite
    txt.TextSize = 65
    txt.Parent = bg
end)
]==]
clientInstaller.Parent = starterScripts

print("========================================")
print("✅ ติดตั้งเกม Midnight Lockdown สำเร็จเรียบร้อย!")
print("🎮 พร้อมเล่นทันที! ขอให้เอาชีวิตรอดให้ได้...")
print("========================================")
