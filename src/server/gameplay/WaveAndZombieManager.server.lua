--[[
    WaveAndZombieManager.server.lua
    ใส่ใน: ServerScriptService
    หน้าที่: จัดการระบบเวฟซอมบี้ (Wave 1, 2, 3...), แต้มทีม (Points & Kills),
            ซอมบี้ทุกประเภท (Walker, Runner, Tank, Crawler, Elevator Horde),
            และอินโทรเปิดเกมแจ้งเตือนให้วิ่งขึ้นชั้น 2
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

print("=========================================================")
print("🧟 กำลังเตรียมระบบ Wave & Zombie Horde อาคาร 40 ปี มจพ...")
print("=========================================================")

-- สร้าง Network Events
local zombieEvents = Instance.new("Folder")
zombieEvents.Name = "ZombieGameEvents"
zombieEvents.Parent = ReplicatedStorage

local function createRemote(className, name)
    local r = Instance.new(className)
    r.Name = name
    r.Parent = zombieEvents
    return r
end

local updateScoreboardEvent = createRemote("RemoteEvent", "UpdateScoreboard")
local waveAnnounceEvent = createRemote("RemoteEvent", "WaveAnnounce")
local playerDamageEvent = createRemote("RemoteEvent", "PlayerDamageEvent")
local zombieHitEvent = createRemote("RemoteEvent", "ZombieHitEvent")
local buyWeaponEvent = createRemote("RemoteFunction", "BuyWeaponEvent")

----------------------------------------------------------------------
-- 1. ฐานข้อมูลผู้เล่น & คะแนนทีม (PLAYER DATA & TEAM POINTS)
----------------------------------------------------------------------
local playerData = {}
-- โครงสร้าง: [userId] = { Points = 500, Kills = 0, Status = "Alive" }

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

-- ซื้อปืนจาก Wall-Buy
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
-- 2. ฟังก์ชันสร้างซอมบี้แต่ละสายพันธุ์ (ZOMBIE TYPES)
----------------------------------------------------------------------
local function createZombieModel(zombieType, spawnPos)
    local zombie = Instance.new("Model")
    zombie.Name = "Zombie_" .. zombieType
    zombie.Parent = Workspace

    local scale = (zombieType == "Tank") and 1.4 or ((zombieType == "Crawler") and 0.7 or 1.0)
    local baseSpeed = (zombieType == "Runner") and 22 or ((zombieType == "Tank") and 8 or 12)
    local baseHealth = (zombieType == "Tank") and 450 or ((zombieType == "Runner") and 80 or 120)

    -- RootPart & Torso
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2 * scale, 2 * scale, 1 * scale)
    hrp.CFrame = CFrame.new(spawnPos)
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Parent = zombie

    local torsoColor = (zombieType == "Tank") and Color3.fromRGB(60, 40, 35) or Color3.fromRGB(80, 95, 80) -- เสื้อนักศึกษาเปื้อนเลือด/ตัวเขียว
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2 * scale, 3 * scale, 1.2 * scale)
    torso.CFrame = hrp.CFrame
    torso.Color = torsoColor
    torso.Material = Enum.Material.SmoothPlastic
    torso.CanCollide = true
    torso.Parent = zombie

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.6 * scale, 1.6 * scale, 1.6 * scale)
    head.CFrame = torso.CFrame + Vector3.new(0, 2.3 * scale, 0)
    head.Color = Color3.fromRGB(110, 130, 110)
    head.Material = Enum.Material.SmoothPlastic
    head.Parent = zombie

    -- ตาแดงซอมบี้
    local eyes = Instance.new("Part")
    eyes.Name = "Eyes"
    eyes.Size = Vector3.new(1 * scale, 0.3 * scale, 0.3 * scale)
    eyes.CFrame = head.CFrame * CFrame.new(0, 0.1, -0.8 * scale)
    eyes.Color = Color3.fromRGB(255, 30, 30)
    eyes.Material = Enum.Material.Neon
    eyes.CanCollide = false
    eyes.Parent = zombie

    local function weld(p0, p1)
        local w = Instance.new("WeldConstraint")
        w.Part0 = p0
        w.Part1 = p1
        w.Parent = p0
    end
    weld(hrp, torso)
    weld(torso, head)
    weld(head, eyes)

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
    groan.Volume = 0.5
    groan.RollOffMaxDistance = 40
    groan.Parent = head
    groan:Play()

    -- ตรรกะไล่ล่าผู้เล่น
    task.spawn(function()
        local attackCooldown = false
        while zombie and zombie.Parent and humanoid.Health > 0 do
            -- หาผู้เล่นที่ใกล้ที่สุดและยังไม่ตาย
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
                humanoid:MoveTo(nearestChar.HumanoidRootPart.Position)

                -- ตีผู้เล่นระยะประชิด
                if nearestDist <= 4.5 and not attackCooldown then
                    attackCooldown = true
                    local targetHum = nearestChar:FindFirstChild("Humanoid")
                    if targetHum then
                        local dmg = (zombieType == "Tank") and 45 or 20
                        targetHum:TakeDamage(dmg)
                    end
                    task.delay(1.2, function() attackCooldown = false end)
                end
            end
            task.wait(0.3)
        end
    end)

    return zombie
end

----------------------------------------------------------------------
-- 3. ตรวจจับการยิงถูกซอมบี้ (DAMAGE & REWARDS)
----------------------------------------------------------------------
zombieHitEvent.OnServerEvent:Connect(function(player, hitPart, damage, isHeadshot)
    if not hitPart or not hitPart.Parent then return end
    local zombie = hitPart.Parent
    local hum = zombie:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        local actualDmg = isHeadshot and (damage * 2.5) or damage
        hum:TakeDamage(actualDmg)

        -- ได้แต้มจากการยิง
        addPoints(player, isHeadshot and 20 or 10)

        if hum.Health <= 0 then
            -- ฆ่าซอมบี้สำเร็จ
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
    -- เปิดประตูลิฟต์ชั้น 2 และปล่อยซอมบี้ทะลักออกมา
    local building = Workspace:FindFirstChild("KMUTNB_Building40")
    if not building then return end
    local floor2 = building:FindFirstChild("Floor_2_Canteen")
    if not floor2 then return end

    local elevDoor = floor2:FindFirstChild("ZombieElevatorDoor_2")
    if elevDoor then
        -- เสียงลิฟต์เปิด
        local ding = Instance.new("Sound")
        ding.SoundId = "rbxassetid://9114223170"
        ding.Volume = 1.5
        ding.Parent = elevDoor
        ding:Play()
        Debris:AddItem(ding, 3)

        -- สปอว์นซอมบี้ 4 ตัวจากในช่องลิฟต์
        for i = 1, 4 do
            task.wait(0.3)
            createZombieModel("Runner", elevDoor.Position + Vector3.new((math.random() - 0.5) * 4, 0, 2))
        end
    end
end

local function startNextWave()
    currentWave = currentWave + 1
    isWaveActive = true

    waveAnnounceEvent:FireAllClients(currentWave, "เริ่มเวฟ " .. currentWave .. "!")
    print("📢 Wave " .. currentWave .. " เริ่มต้นแล้ว!")

    -- ชุบชีวิตเพื่อนที่ตาย ให้กลับมาเกิดใหม่ที่ชั้น 2
    for _, p in ipairs(Players:GetPlayers()) do
        local data = playerData[p.UserId]
        if data and data.Status == "Dead" then
            data.Status = "Alive"
            p:LoadCharacter()
            task.wait(0.2)
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.CFrame = CFrame.new(0, 20, 0) -- ชั้น 2 โรงอาหาร
            end
        end
    end
    broadcastScoreboard()

    -- จำนวนซอมบี้ในเวฟนี้
    local totalZombies = 8 + (currentWave * 4)
    local zombiesSpawned = 0

    task.spawn(function()
        while zombiesSpawned < totalZombies do
            task.wait(math.random(2, 4))

            -- สุ่มชนิดซอมบี้ตามระดับเวฟ
            local zType = "Walker"
            local roll = math.random(1, 100)
            if currentWave >= 2 and roll <= 35 then
                zType = "Runner"
            elseif currentWave >= 3 and roll >= 85 then
                zType = "Tank"
            elseif roll <= 15 then
                zType = "Crawler"
            end

            -- จุดเกิดชั้น 1 หน้าตึก
            local spawnPos = Vector3.new(math.random(-40, 40), 2, 70)
            createZombieModel(zType, spawnPos)
            zombiesSpawned = zombiesSpawned + 1

            -- สุ่มอีเวนต์ลิฟต์ซอมบี้แตก
            if currentWave >= 2 and zombiesSpawned == math.floor(totalZombies / 2) then
                spawnZombieElevatorHorde()
            end
        end

        -- รอจนกว่าซอมบี้จะถูกกำจัดหมด
        while true do
            task.wait(1.5)
            local remaining = 0
            for _, child in ipairs(Workspace:GetChildren()) do
                if child.Name:sub(1, 7) == "Zombie_" and child:FindFirstChild("Humanoid") and child.Humanoid.Health > 0 then
                    remaining = remaining + 1
                end
            end

            if remaining == 0 then
                break
            end
        end

        -- จบเวฟ! เข้าสู่ช่วงพัก (Intermission)
        isWaveActive = false
        waveAnnounceEvent:FireAllClients(currentWave, "จบเวฟ " .. currentWave .. "! พัก 20 วินาที ซื้อปืนและซ่อมแนวกั้น!")
        task.wait(20)
        startNextWave()
    end)
end

----------------------------------------------------------------------
-- 5. อินโทรเริ่มเกม: สัญญาณเตือนให้วิ่งขึ้นชั้น 2
----------------------------------------------------------------------
local function startIntroSequence()
    task.wait(3)
    -- เสียงประกาศเตือนภัย
    for _, p in ipairs(Players:GetPlayers()) do
        waveAnnounceEvent:FireClient(p, 0, "⚠️ สัญญาณเตือนภัย มจพ.! ฝูงซอมบี้บุกหน้าตึก 40 ปี!\nทุกคนรีบวิ่งขึ้นบันไดไปชั้น 2 เดี๋ยวนี้!")
    end

    -- นับถอยหลัง 15 วินาทีให้ผู้เล่นวิ่งขึ้นชั้น 2 ก่อนซอมบี้เวฟแรกบุก
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
