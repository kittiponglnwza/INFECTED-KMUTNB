--[[
    WaveAndZombieManager.server.lua
    ใส่ใน: ServerScriptService
    หน้าที่: จัดการระบบเวฟซอมบี้, ปรับให้ซอมบี้เดินช้าๆ สมจริง (Realistic Shambling Pace),
            มีแขนยื่นไปข้างหน้าและขาก้าวเดิน, เดินตาม Pathfinding เลี้ยวขึ้นบันไดได้
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")

print("=========================================================")
print("🧟 กำลังเตรียมระบบ Wave & Zombie Horde (ซอมบี้เดินช้าสมจริง)...")
print("=========================================================")

-- สร้าง Network Events
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
-- 1. ฐานข้อมูลผู้เล่น & คะแนนทีม
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
-- 2. ฟังก์ชันสร้างซอมบี้เดินช้าแบบคลาสสิก (REALISTIC SHAMBLING ZOMBIE)
----------------------------------------------------------------------
local function createZombieModel(zombieType, spawnPos)
    local zombie = Instance.new("Model")
    zombie.Name = "Zombie_" .. zombieType
    zombie.Parent = Workspace

    local scale = (zombieType == "Tank") and 1.35 or ((zombieType == "Crawler") and 0.75 or 1.0)
    -- ปรับสปีดให้เดินช้าๆ น่ากลัว ไม่วิ่งพรวดพราดตามที่สั่ง
    local baseSpeed = (zombieType == "Runner") and 10.5 or ((zombieType == "Tank") and 5.5 or 6.5)
    local baseHealth = (zombieType == "Tank") and 400 or ((zombieType == "Runner") and 80 or 110)

    -- HumanoidRootPart
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2 * scale, 2 * scale, 1 * scale)
    hrp.CFrame = CFrame.new(spawnPos)
    hrp.Transparency = 1
    hrp.CanCollide = false
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
    torso.Parent = zombie

    -- หัว (Head)
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.4 * scale, 1.4 * scale, 1.4 * scale)
    head.CFrame = torso.CFrame + Vector3.new(0, 2.1 * scale, 0)
    head.Color = Color3.fromRGB(110, 130, 110)
    head.Material = Enum.Material.SmoothPlastic
    head.Parent = zombie

    -- ตาแดง (Eyes)
    local eyes = Instance.new("Part")
    eyes.Name = "Eyes"
    eyes.Size = Vector3.new(0.8 * scale, 0.25 * scale, 0.25 * scale)
    eyes.CFrame = head.CFrame * CFrame.new(0, 0.1, -0.7 * scale)
    eyes.Color = Color3.fromRGB(255, 30, 30)
    eyes.Material = Enum.Material.Neon
    eyes.CanCollide = false
    eyes.Parent = zombie

    -- แขนสองข้างยื่นไปข้างหน้าแบบซอมบี้คลาสสิก (Reaching Arms)
    local armColor = Color3.fromRGB(100, 125, 100)
    local armL = Instance.new("Part")
    armL.Name = "LeftArm"
    armL.Size = Vector3.new(0.8 * scale, 0.8 * scale, 2.2 * scale)
    armL.CFrame = torso.CFrame * CFrame.new(-1.4 * scale, 0.6 * scale, -1.0 * scale)
    armL.Color = armColor
    armL.Material = Enum.Material.SmoothPlastic
    armL.CanCollide = false
    armL.Parent = zombie

    local armR = Instance.new("Part")
    armR.Name = "RightArm"
    armR.Size = Vector3.new(0.8 * scale, 0.8 * scale, 2.2 * scale)
    armR.CFrame = torso.CFrame * CFrame.new(1.4 * scale, 0.6 * scale, -1.0 * scale)
    armR.Color = armColor
    armR.Material = Enum.Material.SmoothPlastic
    armR.CanCollide = false
    armR.Parent = zombie

    -- ขาสองข้างสำหรับก้าวเดิน (Legs)
    local legL = Instance.new("Part")
    legL.Name = "LeftLeg"
    legL.Size = Vector3.new(0.9 * scale, 2.5 * scale, 0.9 * scale)
    legL.CFrame = torso.CFrame * CFrame.new(-0.6 * scale, -2.5 * scale, 0)
    legL.Color = Color3.fromRGB(40, 45, 55)
    legL.Material = Enum.Material.SmoothPlastic
    legL.CanCollide = false
    legL.Parent = zombie

    local legR = Instance.new("Part")
    legR.Name = "RightLeg"
    legR.Size = Vector3.new(0.9 * scale, 2.5 * scale, 0.9 * scale)
    legR.CFrame = torso.CFrame * CFrame.new(0.6 * scale, -2.5 * scale, 0)
    legR.Color = Color3.fromRGB(40, 45, 55)
    legR.Material = Enum.Material.SmoothPlastic
    legR.CanCollide = false
    legR.Parent = zombie

    -- เชื่อมชิ้นส่วนด้วย Weld
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
    humanoid.WalkSpeed = baseSpeed
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = zombie

    zombie.PrimaryPart = hrp
    zombie:SetAttribute("ZombieType", zombieType)
    zombie:SetAttribute("MaxHealth", baseHealth)

    -- เสียงคำราม
    local groan = Instance.new("Sound")
    groan.SoundId = "rbxassetid://9114221580"
    groan.Looped = true
    groan.Volume = 0.4
    groan.RollOffMaxDistance = 35
    groan.Parent = head
    groan:Play()

    -- ตรรกะการเดินและแอนิเมชันโยกตัวแบบคนตายเดินได้ (Realistic Shambling Loop)
    task.spawn(function()
        local attackCooldown = false
        local stepTimer = 0

        while zombie and zombie.Parent and humanoid.Health > 0 do
            -- หาผู้เล่นที่ใกล้ที่สุด
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

                -- เดินหาผู้เล่นด้วยความเร็วสม่ำเสมอ
                humanoid:MoveTo(targetPos)

                -- แอนิเมชันโยกตัวเดินซ้ายขวา (Shambling sway)
                stepTimer = stepTimer + 0.3
                local swayAngle = math.sin(stepTimer * 4) * 5
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(swayAngle * 0.1))

                -- โจมตีระยะประชิด
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
-- 3. ตรวจจับการยิงถูกซอมบี้
----------------------------------------------------------------------
zombieHitEvent.OnServerEvent:Connect(function(player, hitPart, damage, isHeadshot)
    if not hitPart or not hitPart.Parent then return end
    local zombie = hitPart.Parent
    local hum = zombie:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        local actualDmg = isHeadshot and (damage * 2.5) or damage
        hum:TakeDamage(actualDmg)

        addPoints(player, isHeadshot and 20 or 10)

        if hum.Health <= 0 then
            if playerData[player.UserId] then
                playerData[player.UserId].Kills = playerData[player.UserId].Kills + 1
            end
            addPoints(player, isHeadshot and 100 or 50)
            Debris:AddItem(zombie, 2.5)
        end
    end
end)

----------------------------------------------------------------------
-- 4. วงจรระบบเวฟ (THE WAVE CYCLE)
----------------------------------------------------------------------
local currentWave = 0
local isWaveActive = false

local function spawnZombieElevatorHorde()
    local building = Workspace:FindFirstChild("KMUTNB_Building40")
    if not building then return end
    local floor2 = building:FindFirstChild("Floor_2_Canteen")
    if not floor2 then return end

    local elevDoor = floor2:FindFirstChild("ZombieElevatorDoor_2")
    if elevDoor then
        local ding = Instance.new("Sound")
        ding.SoundId = "rbxassetid://9114223170"
        ding.Volume = 1.5
        ding.Parent = elevDoor
        ding:Play()
        Debris:AddItem(ding, 3)

        for i = 1, 3 do
            task.wait(0.5)
            createZombieModel("Walker", elevDoor.Position + Vector3.new((math.random() - 0.5) * 4, 0, 2))
        end
    end
end

local function startNextWave()
    currentWave = currentWave + 1
    isWaveActive = true

    waveAnnounceEvent:FireAllClients(currentWave, "เริ่มเวฟ " .. currentWave .. "!")
    print("📢 Wave " .. currentWave .. " เริ่มต้นแล้ว!")

    -- คืนชีพเพื่อนที่ตาย
    for _, p in ipairs(Players:GetPlayers()) do
        local data = playerData[p.UserId]
        if data and data.Status == "Dead" then
            data.Status = "Alive"
            p:LoadCharacter()
            task.wait(0.2)
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.CFrame = CFrame.new(0, 20, 0)
            end
        end
    end
    broadcastScoreboard()

    local totalZombies = 6 + (currentWave * 3)
    local zombiesSpawned = 0

    task.spawn(function()
        while zombiesSpawned < totalZombies do
            task.wait(math.random(3, 5))

            local zType = "Walker"
            local roll = math.random(1, 100)
            if currentWave >= 3 and roll >= 80 then
                zType = "Tank"
            elseif currentWave >= 2 and roll <= 25 then
                zType = "Runner"
            end

            local spawnPos = Vector3.new(math.random(-35, 35), 2, 65)
            createZombieModel(zType, spawnPos)
            zombiesSpawned = zombiesSpawned + 1

            if currentWave >= 2 and zombiesSpawned == math.floor(totalZombies / 2) then
                spawnZombieElevatorHorde()
            end
        end

        while true do
            task.wait(1.5)
            local remaining = 0
            for _, child in ipairs(Workspace:GetChildren()) do
                if child.Name:sub(1, 7) == "Zombie_" and child:FindFirstChild("Humanoid") and child.Humanoid.Health > 0 then
                    remaining = remaining + 1
                end
            end
            if remaining == 0 then break end
        end

        isWaveActive = false
        waveAnnounceEvent:FireAllClients(currentWave, "จบเวฟ " .. currentWave .. "! พัก 20 วินาที ซื้อกระสุนและซ่อมแนวกั้น!")
        task.wait(20)
        startNextWave()
    end)
end

local function startIntroSequence()
    task.wait(3)
    for _, p in ipairs(Players:GetPlayers()) do
        waveAnnounceEvent:FireClient(p, 0, "⚠️ สัญญาณเตือนภัย มจพ.! ฝูงซอมบี้บุกหน้าตึก 40 ปี!\nทุกคนรีบวิ่งขึ้นบันไดไปชั้น 2 เดี๋ยวนี้!")
    end
    task.wait(15)
    startNextWave()
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
