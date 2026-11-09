--[[
    WaveAndZombieManager.server.lua
    ใส่ใน: ServerScriptService -> Gameplay
    หน้าที่:
      - ปล่อยฝูงซอมบี้เป็นเวฟ (Wave System) ออกมาไล่ล่าผู้เล่นจริงในอาคาร 40 ปี มจพ. (ทั้งชั้น 1 และชั้น 2)
      - ซอมบี้วิ่งไล่ตามผู้เล่นอัตโนมัติ (MoveTo + Pathfinding อ้อมสิ่งกีดขวาง)
      - โจมตีผู้เล่นเมื่อประชิดตัว ลดเลือด (HP) จริง + ระบบฟื้นฟูเลือดเมื่อหลบพ้นระยะ
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")

local TEST_MODE = false
local SPAWN_ZOMBIES = true -- 🧟 เปิดปล่อยซอมบี้ออกมาไล่ล่าผู้เล่นเต็มรูปแบบ!

print("=========================================================")
print("🧟 [Zombie Horde Active] เปิดระบบปล่อยฝูงซอมบี้ไล่ล่าผู้เล่น + ระบบ HP ผู้เล่น!")
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
-- 1. ฐานข้อมูลผู้เล่น, คะแนน, และระบบ HP ผู้เล่น
----------------------------------------------------------------------
local playerData = {}
local lastDamagedTime = {}

local function broadcastScoreboard()
    local scoreList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local data = playerData[p.UserId] or { Points = 500, Kills = 0, Status = "Alive" }
        table.insert(scoreList, {
            UserId = p.UserId,
            Name = p.DisplayName,
            Points = data.Points,
            Kills = data.Kills,
            Status = data.Status,
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

-- ตั้งค่า HP ผู้เล่น (100 HP) และเชื่อมต่อสถานะตอนเกิดใหม่
local function setupPlayerCharacter(player, char)
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end

    hum.MaxHealth = 100
    hum.Health = 100
    if playerData[player.UserId] then
        playerData[player.UserId].Status = "Alive"
        broadcastScoreboard()
    end

    hum.Died:Connect(function()
        if playerData[player.UserId] then
            playerData[player.UserId].Status = "Dead"
            broadcastScoreboard()
        end
    end)
end

-- ระบบฟื้นฟูเลือดอัตโนมัติเมื่อไม่ได้โดนซอมบี้ตีนานเกิน 6 วินาที
task.spawn(function()
    while true do
        local now = os.clock()
        for _, p in ipairs(Players:GetPlayers()) do
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
                local lastHit = lastDamagedTime[p.UserId] or 0
                if now - lastHit >= 6.0 then
                    hum.Health = math.min(hum.MaxHealth, hum.Health + 4)
                end
            end
        end
        task.wait(0.5)
    end
end)

----------------------------------------------------------------------
-- 2. แถบเลือดลอยบนหัวซอมบี้ (BILLBOARD HEALTH BAR)
----------------------------------------------------------------------
local function attachHealthBillboard(zombie, baseHealth, zType)
    local head = zombie:FindFirstChild("Head") or zombie.PrimaryPart
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "HealthBillboard"
    bb.Size = UDim2.new(0, 140, 0, 38)
    bb.StudsOffset = Vector3.new(0, 2.4, 0)
    bb.AlwaysOnTop = false
    bb.MaxDistance = 120
    bb.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = (zType == "Tank") and Color3.fromRGB(255, 85, 85)
        or ((zType == "Runner") and Color3.fromRGB(255, 175, 50) or Color3.fromRGB(230, 240, 120))
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.Text = (zType == "Tank") and "🛡️ TANK ZOMBIE" or ("🧟 ZOMBIE " .. zType:upper())
    nameLabel.Parent = bb

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, 0, 0, 10)
    barBg.Position = UDim2.new(0, 0, 0, 18)
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
    hpText.TextStrokeTransparency = 0.4
    hpText.Font = Enum.Font.GothamBold
    hpText.TextSize = 9
    hpText.Text = string.format("%d / %d", baseHealth, baseHealth)
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
            hpText.Text = string.format("%d / %d", math.max(0, math.floor(health)), baseHealth)
        end)
    end
end

----------------------------------------------------------------------
-- 3. สร้างโมเดลซอมบี้ + ระบบ AI ไล่ล่าและโจมตีผู้เล่น
----------------------------------------------------------------------
local function createZombieModel(zombieType, spawnPos, isStationary)
    local zombie = Instance.new("Model")
    zombie.Name = "Zombie_" .. zombieType
    zombie.Parent = Workspace

    local scale = (zombieType == "Tank") and 1.35 or 1.0
    local baseSpeed = (zombieType == "Runner") and 18.5 or ((zombieType == "Tank") and 11.0 or 14.0)
    local baseHealth = (zombieType == "Tank") and 350 or ((zombieType == "Runner") and 85 or 110)
    local attackDmg = (zombieType == "Tank") and 28 or ((zombieType == "Runner") and 12 or 16)

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2 * scale, 2 * scale, 1 * scale)
    hrp.CFrame = CFrame.new(spawnPos)
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Anchored = isStationary and true or false
    hrp.Parent = zombie

    local torsoColor = (zombieType == "Tank") and Color3.fromRGB(65, 42, 38)
        or ((zombieType == "Runner") and Color3.fromRGB(95, 65, 65) or Color3.fromRGB(70, 92, 72))
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2 * scale, 2.8 * scale, 1.2 * scale)
    torso.CFrame = hrp.CFrame
    torso.Color = torsoColor
    torso.Material = Enum.Material.SmoothPlastic
    torso.CanCollide = true
    torso.Anchored = isStationary and true or false
    torso.Parent = zombie

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.4 * scale, 1.4 * scale, 1.4 * scale)
    head.CFrame = torso.CFrame + Vector3.new(0, 2.1 * scale, 0)
    head.Color = Color3.fromRGB(115, 138, 112)
    head.Material = Enum.Material.SmoothPlastic
    head.CanCollide = true
    head.Anchored = isStationary and true or false
    head.Parent = zombie

    local eyes = Instance.new("Part")
    eyes.Name = "Eyes"
    eyes.Size = Vector3.new(0.8 * scale, 0.25 * scale, 0.25 * scale)
    eyes.CFrame = head.CFrame * CFrame.new(0, 0.1, -0.7 * scale)
    eyes.Color = Color3.fromRGB(255, 35, 35)
    eyes.Material = Enum.Material.Neon
    eyes.CanCollide = false
    eyes.Anchored = isStationary and true or false
    eyes.Parent = zombie

    local armColor = Color3.fromRGB(105, 128, 102)
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

    local legL = Instance.new("Part")
    legL.Name = "LeftLeg"
    legL.Size = Vector3.new(0.9 * scale, 2.5 * scale, 0.9 * scale)
    legL.CFrame = torso.CFrame * CFrame.new(-0.55 * scale, -2.5 * scale, 0)
    legL.Color = Color3.fromRGB(42, 48, 58)
    legL.Material = Enum.Material.SmoothPlastic
    legL.CanCollide = false
    legL.Anchored = isStationary and true or false
    legL.Parent = zombie

    local legR = Instance.new("Part")
    legR.Name = "RightLeg"
    legR.Size = Vector3.new(0.9 * scale, 2.5 * scale, 0.9 * scale)
    legR.CFrame = torso.CFrame * CFrame.new(0.55 * scale, -2.5 * scale, 0)
    legR.Color = Color3.fromRGB(42, 48, 58)
    legR.Material = Enum.Material.SmoothPlastic
    legR.CanCollide = false
    legR.Anchored = isStationary and true or false
    legR.Parent = zombie

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
    humanoid.JumpPower = 50
    humanoid.AutoRotate = true
    humanoid.HipHeight = 2.6 * scale -- สำคัญมาก: ทำให้ซอมบี้ยืนเหนือพื้นพอดีและเดินขึ้นบันไดได้ลื่นไหล
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = zombie

    zombie.PrimaryPart = hrp
    zombie:SetAttribute("ZombieType", zombieType)
    zombie:SetAttribute("MaxHealth", baseHealth)
    zombie:SetAttribute("SpawnPos", spawnPos)
    zombie:SetAttribute("IsStationary", isStationary or false)

    local groan = Instance.new("Sound")
    groan.SoundId = "rbxassetid://9114221580"
    groan.Looped = true
    groan.Volume = 0.3
    groan.RollOffMaxDistance = 45
    groan.Parent = head
    groan:Play()

    attachHealthBillboard(zombie, baseHealth, zombieType)

    if isStationary then
        return zombie
    end

    -- 🧟 AI ไล่ตามผู้เล่นและโจมตีเมื่อถึงตัว
    task.spawn(function()
        local lastAttack = 0
        local stuckCount = 0
        local lastPos = hrp.Position

        while zombie and zombie.Parent and humanoid.Health > 0 do
            local nearestPlayer = nil
            local nearestChar = nil
            local nearestDist = math.huge

            for _, p in ipairs(Players:GetPlayers()) do
                local c = p.Character
                local pHum = c and c:FindFirstChildOfClass("Humanoid")
                local pRoot = c and c:FindFirstChild("HumanoidRootPart")
                if pHum and pHum.Health > 0 and pRoot then
                    local d = (pRoot.Position - hrp.Position).Magnitude
                    if d < nearestDist then
                        nearestDist = d
                        nearestChar = c
                        nearestPlayer = p
                    end
                end
            end

            if nearestChar and nearestChar:FindFirstChild("HumanoidRootPart") then
                local targetRoot = nearestChar.HumanoidRootPart
                local targetPos = targetRoot.Position

                -- เช็กว่าติดกำแพงหรือไม่ ถ้าติดให้กระโดดหรือคำนวณ Pathfinding
                if (hrp.Position - lastPos).Magnitude < 0.8 and nearestDist > 6 then
                    stuckCount += 1
                    if stuckCount >= 3 then
                        humanoid.Jump = true
                        local ok, path = pcall(function()
                            local p = PathfindingService:CreatePath({
                                AgentRadius = 2,
                                AgentHeight = 5,
                                AgentCanJump = true,
                            })
                            p:ComputeAsync(hrp.Position, targetPos)
                            return p
                        end)
                        if ok and path and path.Status == Enum.PathStatus.Success then
                            local waypoints = path:GetWaypoints()
                            if waypoints[2] then
                                if waypoints[2].Action == Enum.PathWaypointAction.Jump then
                                    humanoid.Jump = true
                                end
                                humanoid:MoveTo(waypoints[2].Position)
                            else
                                humanoid:MoveTo(targetPos)
                            end
                        else
                            humanoid:MoveTo(targetPos)
                        end
                        stuckCount = 0
                    else
                        humanoid:MoveTo(targetPos)
                    end
                else
                    stuckCount = 0
                    humanoid:MoveTo(targetPos)
                end
                lastPos = hrp.Position

                -- 🩸 โจมตีผู้เล่นเมื่อเข้าระยะประชิด (<= 6.0 studs)
                local now = os.clock()
                if nearestDist <= 6.0 and (now - lastAttack >= 1.1) then
                    lastAttack = now
                    local targetHum = nearestChar:FindFirstChildOfClass("Humanoid")
                    if targetHum and targetHum.Health > 0 then
                        targetHum:TakeDamage(attackDmg)
                        if nearestPlayer then
                            lastDamagedTime[nearestPlayer.UserId] = now
                            playerDamageEvent:FireClient(nearestPlayer, attackDmg, targetHum.Health, targetHum.MaxHealth)
                        end
                    end
                end
            end

            task.wait(0.2)
        end
    end)

    return zombie
end

----------------------------------------------------------------------
-- 4. ตรวจจับการยิงถูกซอมบี้ (ZOMBIE HIT EVENT)
----------------------------------------------------------------------
zombieHitEvent.OnServerEvent:Connect(function(player, hitPart, damage, isHeadshot)
    if not hitPart or not hitPart.Parent then return end
    local zombie = hitPart:FindFirstAncestorOfClass("Model")
    if not zombie or zombie.Name:sub(1, 7) ~= "Zombie_" then return end

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

            for _, p in ipairs(zombie:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.Anchored = false
                end
            end
            Debris:AddItem(zombie, 1.8)
        end
    end
end)

----------------------------------------------------------------------
-- 5. จุดเกิดซอมบี้ทั้งชั้น 1 และชั้น 2 (เลือกตามชั้นที่ผู้เล่นยืนอยู่)
----------------------------------------------------------------------
local FLOOR1_SPAWNS = {
    Vector3.new( 125, 5, -20), -- ทางเข้ารถฝั่งขวา
    Vector3.new( 125, 5,  20),
    Vector3.new(-115, 5,   0), -- ลานจอดรถฝั่งซ้าย
    Vector3.new(   0, 5, 110), -- โถงทางเข้าหน้าตึกชั้น 1
    Vector3.new(   0, 5,-110), -- โถงทางเข้าหลังตึกชั้น 1
    Vector3.new( -60, 5,   0),
    Vector3.new(  60, 5,   0),
}

local FLOOR2_SPAWNS = {
    Vector3.new(   0, 27, 155), -- ชานพักบันไดใหญ่หน้าโรงอาหารชั้น 2
    Vector3.new(   0, 27, 105), -- โถงทางเข้าหน้าชั้น 2
    Vector3.new(   0, 27,-105), -- โถงทางเข้าหลังชั้น 2
    Vector3.new(-100, 27, -45), -- ทางเดินหน้าห้องน้ำ/ร้านข้าวซ้ายบน
    Vector3.new( 100, 27, -45), -- ทางเดินหน้าห้องน้ำ/ร้านข้าวขวาบน
    Vector3.new(-100, 27,  45), -- ทางเดินหน้าห้องน้ำ/ร้านข้าวซ้ายล่าง
    Vector3.new( 100, 27,  45), -- ทางเดินหน้าห้องน้ำ/ร้านข้าวขวาล่าง
}

local function pickSpawnPosition()
    -- ตรวจว่ามีผู้เล่นอยู่บนชั้น 2 (Y >= 15) หรือไม่
    local anyOnFloor2 = false
    for _, p in ipairs(Players:GetPlayers()) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Position.Y >= 15 then
            anyOnFloor2 = true
            break
        end
    end

    local pool = anyOnFloor2 and FLOOR2_SPAWNS or FLOOR1_SPAWNS
    local base = pool[math.random(1, #pool)]
    return base + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
end

----------------------------------------------------------------------
-- 6. วงจรเวฟซอมบี้ (WAVE LOOP)
----------------------------------------------------------------------
local function startIntroSequence()
    if not SPAWN_ZOMBIES then
        return
    end

    -- รอให้มีผู้เล่นเข้ามาในเกมอย่างน้อย 1 คน
    while #Players:GetPlayers() == 0 do
        task.wait(0.5)
    end
    task.wait(2.0)

    local currentWave = 1
    while true do
        for _, p in ipairs(Players:GetPlayers()) do
            waveAnnounceEvent:FireClient(p, currentWave, string.format("⚠️ WAVE %d // ฝูงซอมบี้บุกอาคาร 40 ปี มจพ.!", currentWave))
        end
        task.wait(2.5)

        local zombiesCount = math.min(6 + (currentWave * 3), 28)
        local activeZombies = {}

        for _ = 1, zombiesCount do
            local zType = "Walker"
            local rand = math.random()
            if currentWave >= 2 and rand > 0.65 then
                zType = "Runner"
            end
            if currentWave >= 3 and rand > 0.85 then
                zType = "Tank"
            end

            local spawnPos = pickSpawnPosition()
            local zModel = createZombieModel(zType, spawnPos, false)
            table.insert(activeZombies, zModel)
            task.wait(0.9)
        end

        -- รอจนกว่าซอมบี้ในเวฟจะถูกกำจัดหมด
        while #activeZombies > 0 do
            for i = #activeZombies, 1, -1 do
                local z = activeZombies[i]
                local zHum = z and z:FindFirstChildOfClass("Humanoid")
                if not z or not z.Parent or not zHum or zHum.Health <= 0 then
                    table.remove(activeZombies, i)
                end
            end
            task.wait(1.0)
        end

        local reward = 150 + (currentWave * 50)
        for _, p in ipairs(Players:GetPlayers()) do
            addPoints(p, reward)
            waveAnnounceEvent:FireClient(p, currentWave, string.format("🎉 WAVE %d CLEARED // กำจัดฝูงซอมบี้สำเร็จ! (+%d แต้ม)", currentWave, reward))
        end
        task.wait(5.0)
        currentWave = currentWave + 1
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    playerData[p.UserId] = { Points = 500, Kills = 0, Status = "Alive" }
    p.CharacterAdded:Connect(function(char)
        setupPlayerCharacter(p, char)
    end)
    if p.Character then
        task.spawn(setupPlayerCharacter, p, p.Character)
    end
end

Players.PlayerAdded:Connect(function(player)
    playerData[player.UserId] = { Points = 500, Kills = 0, Status = "Alive" }
    player.CharacterAdded:Connect(function(char)
        setupPlayerCharacter(player, char)
    end)
    if player.Character then
        task.spawn(setupPlayerCharacter, player, player.Character)
    end
    task.wait(1)
    broadcastScoreboard()
end)

Players.PlayerRemoving:Connect(function(player)
    playerData[player.UserId] = nil
    lastDamagedTime[player.UserId] = nil
    broadcastScoreboard()
end)

task.spawn(startIntroSequence)
