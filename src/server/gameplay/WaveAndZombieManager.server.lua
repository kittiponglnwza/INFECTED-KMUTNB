--[[
    WaveAndZombieManager.server.lua
    ใส่ใน: ServerScriptService
    หน้าที่: จัดการระบบเวฟซอมบี้ และจัดการหุ่นซ้อมยิงซอมบี้ (Target Dummies)
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local TEST_MODE = false
local SPAWN_ZOMBIES = false -- 🛑 หยุดการสปอว์นซอมบี้ชั่วคราว เพื่อให้เดินตรวจแมพชั้น 1 ได้อย่างสงบและปลอดภัย

print("=========================================================")
print(TEST_MODE and "🎯 [Test Mode] ซอมบี้เป้าซ้อม (ยืนนิ่ง ไม่เดิน ไม่ตาม) พร้อมทำงาน!" or "🧟 ระบบ Wave & Zombie Horde พร้อมทำงาน!")
print("=========================================================")

-- สร้าง Remote Events สำหรับสื่อสารกับ Client
local zombieEvents = ReplicatedStorage:FindFirstChild("ZombieGameEvents") or Instance.new("Folder")
zombieEvents.Name = "ZombieGameEvents"
zombieEvents.Parent = ReplicatedStorage

local function getOrCreateRemote(className, name)
    local r = zombieEvents:FindFirstChild(name)
    if not r then
        r = Instance.new(className)
        r.Name = name
        r.Parent = zombieEvents
    end
    return r
end

local updateScoreboardEvent = getOrCreateRemote("RemoteEvent", "UpdateScoreboard")
local waveAnnounceEvent = getOrCreateRemote("RemoteEvent", "WaveAnnounce")
local playerDamageEvent = getOrCreateRemote("RemoteEvent", "PlayerDamageEvent")
local zombieHitEvent = getOrCreateRemote("RemoteEvent", "ZombieHitEvent")
local buyWeaponEvent = getOrCreateRemote("RemoteFunction", "BuyWeaponEvent")

----------------------------------------------------------------------
-- 1. ฐานข้อมูลผู้เล่น & คะแนน
----------------------------------------------------------------------
local playerData = {}

local function broadcastScoreboard()
    local scoreList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local data = playerData[p.UserId] or { Points = 500, Kills = 0, Status = "Alive" }
        table.insert(scoreList, {
            UserId = p.UserId,
            Name = p.DisplayName,
            Points = data.Points,
            Kills = data.Kills,
            Status = data.Status
        })
    end
    updateScoreboardEvent:FireAllClients(scoreList)
end

local function addPoints(player, amount)
    if not player or not playerData[player.UserId] then return end
    playerData[player.UserId].Points = playerData[player.UserId].Points + amount
    broadcastScoreboard()
end

buyWeaponEvent.OnServerInvoke = function(player, weaponName, cost)
    local data = playerData[player.UserId]
    if not data or data.Points < cost then
        return false, "แต้มไม่พอ!"
    end
    data.Points = data.Points - cost
    broadcastScoreboard()
    return true, "ซื้อสำเร็จ!"
end

----------------------------------------------------------------------
-- 2. ฟังก์ชันติดแถบเลือดลอยบนหัวซอมบี้ (BILLBOARD HEALTH BAR)
----------------------------------------------------------------------
local function attachHealthBillboard(zombie, baseHealth, zType)
    local head = zombie:FindFirstChild("Head") or zombie.PrimaryPart
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "HealthBillboard"
    bb.Size = UDim2.new(0, 150, 0, 42)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = (zType == "Tank") and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(255, 230, 90)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Text = (zType == "Tank") and "🛡️ TANK TARGET" or ("🎯 ZOMBIE " .. zType:upper())
    nameLabel.Parent = bb

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, 0, 0, 12)
    barBg.Position = UDim2.new(0, 0, 0, 20)
    barBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    barBg.BorderSizePixel = 0
    barBg.Parent = bb
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

    local barFill = Instance.new("Frame")
    barFill.Name = "Fill"
    barFill.Size = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(60, 220, 90)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)

    local hpText = Instance.new("TextLabel")
    hpText.Name = "HPText"
    hpText.Size = UDim2.new(1, 0, 1, 0)
    hpText.BackgroundTransparency = 1
    hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
    hpText.TextStrokeTransparency = 0.5
    hpText.Font = Enum.Font.GothamBold
    hpText.TextSize = 10
    hpText.Text = string.format("%d / %d HP", baseHealth, baseHealth)
    hpText.Parent = barBg

    local hum = zombie:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.HealthChanged:Connect(function(health)
            local pct = math.clamp(health / baseHealth, 0, 1)
            barFill.Size = UDim2.new(pct, 0, 1, 0)
            if pct > 0.5 then
                barFill.BackgroundColor3 = Color3.fromRGB(60, 220, 90)
            elseif pct > 0.25 then
                barFill.BackgroundColor3 = Color3.fromRGB(255, 180, 40)
            else
                barFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            end
            hpText.Text = string.format("%d / %d HP", math.max(0, math.floor(health)), baseHealth)
        end)
    end
end

----------------------------------------------------------------------
-- 3. ฟังก์ชันสร้างโมเดลซอมบี้
----------------------------------------------------------------------
local function createZombieModel(zombieType, spawnPos, isStationary)
    local zombie = Instance.new("Model")
    zombie.Name = "Zombie_" .. zombieType
    zombie.Parent = Workspace

    local scale = (zombieType == "Tank") and 1.35 or ((zombieType == "Crawler") and 0.75 or 1.0)
    local baseSpeed = (zombieType == "Runner") and 10.5 or ((zombieType == "Tank") and 5.5 or 6.5)
    local baseHealth = (zombieType == "Tank") and 400 or ((zombieType == "Runner") and 80 or 100)

    -- HumanoidRootPart
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2 * scale, 2 * scale, 1 * scale)
    hrp.CFrame = CFrame.new(spawnPos)
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Anchored = isStationary and true or false
    hrp.Parent = zombie

    -- ลำตัว (Torso)
    local torsoColor = (zombieType == "Tank") and Color3.fromRGB(50, 40, 35) or Color3.fromRGB(75, 90, 75)
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2 * scale, 2.8 * scale, 1.2 * scale)
    torso.CFrame = hrp.CFrame
    torso.Color = torsoColor
    torso.Material = Enum.Material.SmoothPlastic
    torso.CanCollide = true
    torso.Anchored = isStationary and true or false
    torso.Parent = zombie

    -- หัว (Head)
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.4 * scale, 1.4 * scale, 1.4 * scale)
    head.CFrame = torso.CFrame + Vector3.new(0, 2.1 * scale, 0)
    head.Color = Color3.fromRGB(110, 130, 110)
    head.Material = Enum.Material.SmoothPlastic
    head.Anchored = isStationary and true or false
    head.Parent = zombie

    -- ตาแดงเรืองแสง (Eyes)
    local eyes = Instance.new("Part")
    eyes.Name = "Eyes"
    eyes.Size = Vector3.new(0.8 * scale, 0.25 * scale, 0.25 * scale)
    eyes.CFrame = head.CFrame * CFrame.new(0, 0.1, -0.7 * scale)
    eyes.Color = Color3.fromRGB(255, 30, 30)
    eyes.Material = Enum.Material.Neon
    eyes.CanCollide = false
    eyes.Anchored = isStationary and true or false
    eyes.Parent = zombie

    -- แขนสองข้างยื่นไปข้างหน้าแบบซอมบี้ (Reaching Arms)
    local armColor = Color3.fromRGB(100, 125, 100)
    local armL = Instance.new("Part")
    armL.Name = "LeftArm"
    armL.Size = Vector3.new(0.8 * scale, 0.8 * scale, 2.2 * scale)
    armL.CFrame = torso.CFrame * CFrame.new(-1.4 * scale, 0.6 * scale, -1.0 * scale)
    armL.Color = armColor
    armL.Material = Enum.Material.SmoothPlastic
    armL.CanCollide = false
    armL.Anchored = isStationary and true or false
    armL.Parent = zombie

    local armR = Instance.new("Part")
    armR.Name = "RightArm"
    armR.Size = Vector3.new(0.8 * scale, 0.8 * scale, 2.2 * scale)
    armR.CFrame = torso.CFrame * CFrame.new(1.4 * scale, 0.6 * scale, -1.0 * scale)
    armR.Color = armColor
    armR.Material = Enum.Material.SmoothPlastic
    armR.CanCollide = false
    armR.Anchored = isStationary and true or false
    armR.Parent = zombie

    -- ขาสองข้าง (Legs)
    local legL = Instance.new("Part")
    legL.Name = "LeftLeg"
    legL.Size = Vector3.new(0.9 * scale, 2.5 * scale, 0.9 * scale)
    legL.CFrame = torso.CFrame * CFrame.new(-0.6 * scale, -2.5 * scale, 0)
    legL.Color = Color3.fromRGB(40, 45, 55)
    legL.Material = Enum.Material.SmoothPlastic
    legL.CanCollide = false
    legL.Anchored = isStationary and true or false
    legL.Parent = zombie

    local legR = Instance.new("Part")
    legR.Name = "RightLeg"
    legR.Size = Vector3.new(0.9 * scale, 2.5 * scale, 0.9 * scale)
    legR.CFrame = torso.CFrame * CFrame.new(0.6 * scale, -2.5 * scale, 0)
    legR.Color = Color3.fromRGB(40, 45, 55)
    legR.Material = Enum.Material.SmoothPlastic
    legR.CanCollide = false
    legR.Anchored = isStationary and true or false
    legR.Parent = zombie

    -- เชื่อมชิ้นส่วนด้วย WeldConstraint
    local function weld(p0, p1)
        local w = Instance.new("WeldConstraint")
        w.Part0 = p0
        w.Part1 = p1
        w.Parent = p0
    end
    weld(hrp, torso)
    weld(torso, head)
    weld(head, eyes)
    weld(torso, armL)
    weld(torso, armR)
    weld(torso, legL)
    weld(torso, legR)

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = baseHealth
    humanoid.Health = baseHealth
    humanoid.WalkSpeed = isStationary and 0 or baseSpeed
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = zombie

    zombie.PrimaryPart = hrp
    zombie:SetAttribute("ZombieType", zombieType)
    zombie:SetAttribute("MaxHealth", baseHealth)
    zombie:SetAttribute("SpawnPos", spawnPos)
    zombie:SetAttribute("IsStationary", isStationary or false)

    -- เสียงคำรามเบาๆ
    local groan = Instance.new("Sound")
    groan.SoundId = "rbxassetid://9114221580"
    groan.Looped = true
    groan.Volume = 0.35
    groan.RollOffMaxDistance = 35
    groan.Parent = head
    groan:Play()

    -- ติดป้ายเลือดบนหัว
    attachHealthBillboard(zombie, baseHealth, zombieType)

    -- ถ้าเป็นเป้าซ้อม (isStationary) -> ไม่ต้องเดิน ยืนนิ่ง 100%!
    if isStationary then
        for _, part in ipairs(zombie:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
            end
        end
        return zombie
    end

    -- ตรรกะการเดินสำหรับโหมดปกติ
    task.spawn(function()
        local attackCooldown = false
        local stepTimer = 0

        while zombie and zombie.Parent and humanoid.Health > 0 do
            local nearestChar = nil
            local nearestDist = 9999
            for _, p in ipairs(Players:GetPlayers()) do
                local c = p.Character
                local data = playerData[p.UserId]
                if c and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 and (not data or data.Status ~= "Dead") then
                    local pRoot = c:FindFirstChild("HumanoidRootPart")
                    if pRoot then
                        local d = (pRoot.Position - hrp.Position).Magnitude
                        if d < nearestDist then
                            nearestDist = d
                            nearestChar = c
                        end
                    end
                end
            end

            if nearestChar and nearestChar:FindFirstChild("HumanoidRootPart") then
                local targetPos = nearestChar.HumanoidRootPart.Position
                humanoid:MoveTo(targetPos)

                stepTimer = stepTimer + 0.3
                local swayAngle = math.sin(stepTimer * 4) * 5
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(swayAngle * 0.1))

                if nearestDist <= 4.5 and not attackCooldown then
                    attackCooldown = true
                    local targetHum = nearestChar:FindFirstChild("Humanoid")
                    if targetHum then
                        local dmg = (zombieType == "Tank") and 40 or 18
                        targetHum:TakeDamage(dmg)
                    end
                    task.delay(1.4, function() attackCooldown = false end)
                end
            end
            task.wait(0.25)
        end
    end)

    return zombie
end

----------------------------------------------------------------------
-- 4. ตรวจจับการยิงถูกซอมบี้ (ZOMBIE HIT EVENT)
----------------------------------------------------------------------
zombieHitEvent.OnServerEvent:Connect(function(player, hitPart, damage, isHeadshot)
    if not hitPart or not hitPart.Parent then return end
    local zombie = hitPart.Parent
    if zombie.Name:sub(1, 7) ~= "Zombie_" and zombie.Parent and zombie.Parent.Name:sub(1, 7) == "Zombie_" then
        zombie = zombie.Parent
    end

    local hum = zombie:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        local actualDmg = isHeadshot and (damage * 2.5) or damage
        hum:TakeDamage(actualDmg)

        addPoints(player, isHeadshot and 25 or 10)

        if hum.Health <= 0 then
            if playerData[player.UserId] then
                playerData[player.UserId].Kills = playerData[player.UserId].Kills + 1
            end
            addPoints(player, isHeadshot and 100 or 50)

            local spawnPos = zombie:GetAttribute("SpawnPos")
            local zType = zombie:GetAttribute("ZombieType") or "Walker"
            local isStat = zombie:GetAttribute("IsStationary")

            -- ปลด Anchor เพื่อให้ซอมบี้ล้มฟุบลงพื้น
            for _, p in ipairs(zombie:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.Anchored = false
                end
            end
            Debris:AddItem(zombie, 2.0)

            -- ในโหมดทดสอบ ถ้าเป้าซ้อมตาย ให้เกิดใหม่ที่เดิมใน 2.5 วินาที
            if TEST_MODE and isStat and spawnPos then
                task.delay(2.5, function()
                    createZombieModel(zType, spawnPos, true)
                end)
            end
        end
    end
end)

----------------------------------------------------------------------
-- 5. สปอว์นเป้าซ้อม หรือ วงจรเวฟ
----------------------------------------------------------------------
local function startIntroSequence()
    if not SPAWN_ZOMBIES then
        print("🛑 [Zombie Spawning Paused] ปิดสปอว์นซอมบี้เรียบร้อยแล้ว เดินสำรวจแมพได้อย่างปลอดภัย 100%!")
        return
    end
    task.wait(1.5)
    if TEST_MODE then
        print("🎯 [Test Mode] สปอว์นหุ่นซ้อมยิงซอมบี้ ยืนนิ่ง ไม่เดิน...")
        -- ซอมบี้เป้าซ้อมตามระยะต่างๆ (ยืนนิ่ง 100%):
        createZombieModel("Walker", Vector3.new(-8, 3, -20), true)   -- 20 studs ซ้าย
        createZombieModel("Walker", Vector3.new(8, 3, -20), true)    -- 20 studs ขวา
        createZombieModel("Runner", Vector3.new(0, 3, -35), true)    -- 35 studs กลาง
        createZombieModel("Tank", Vector3.new(0, 4, -50), true)      -- 50 studs Tank เลือด 400
        createZombieModel("Walker", Vector3.new(-14, 3, -70), true)  -- 70 studs ซ้าย
        createZombieModel("Walker", Vector3.new(14, 3, -90), true)   -- 90 studs ขวา (ระยะไกล)
    else
        task.wait(2)
        local currentWave = 1
        while true do
            for _, p in ipairs(Players:GetPlayers()) do
                waveAnnounceEvent:FireClient(p, currentWave, string.format("⚠️ WAVE %d // ฝูงซอมบี้บุกหน้าอาคาร 40 ปี มจพ.!", currentWave))
            end
            task.wait(4)

            local zombiesCount = math.min(4 + (currentWave * 2), 24)
            local activeZombies = {}

            for zIdx = 1, zombiesCount do
                local zType = "Walker"
                local rand = math.random()
                if currentWave >= 2 and rand > 0.70 then
                    zType = "Runner"
                elseif currentWave >= 3 and rand > 0.85 then
                    zType = "Tank"
                end

                local spawnX = math.random(-45, 45)
                local spawnZ = math.random(95, 125)
                local spawnY = 2
                local zModel = createZombieModel(zType, Vector3.new(spawnX, spawnY, spawnZ), false)
                table.insert(activeZombies, zModel)
                task.wait(1.2)
            end

            -- รอจนกว่าซอมบี้ในเวฟจะถูกกำจัดหมด
            while #activeZombies > 0 do
                for i = #activeZombies, 1, -1 do
                    local z = activeZombies[i]
                    if not z or not z.Parent or not z:FindFirstChildOfClass("Humanoid") or z.Humanoid.Health <= 0 then
                        table.remove(activeZombies, i)
                    end
                end
                task.wait(1.5)
            end

            local reward = 150 + (currentWave * 50)
            for _, p in ipairs(Players:GetPlayers()) do
                addPoints(p, reward)
                waveAnnounceEvent:FireClient(p, currentWave, string.format("🎉 WAVE %d CLEARED // ผ่านคลื่นซอมบี้สำเร็จ! (+%d แต้ม)", currentWave, reward))
            end
            task.wait(7)
            currentWave = currentWave + 1
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    playerData[player.UserId] = { Points = 500, Kills = 0, Status = "Alive" }
    task.wait(1)
    broadcastScoreboard()
end)

Players.PlayerRemoving:Connect(function(player)
    playerData[player.UserId] = nil
    broadcastScoreboard()
end)

task.spawn(startIntroSequence)
