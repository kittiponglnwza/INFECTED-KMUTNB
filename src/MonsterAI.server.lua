--[[
    MonsterAI.server.lua
    ใส่ใน: ServerScriptService
    หน้าที่: สร้างผีเงาดำตาสีแดง (The Shadow Stalker) ควบคุมระบบเดินตรวจตรา, วิ่งไล่ล่า, และระบบจับผู้เล่นส่งไปจั๊มสแก
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local horrorEvents = ReplicatedStorage:WaitForChild("HorrorEvents", 15)
local jumpscareEvent = Instance.new("RemoteEvent")
jumpscareEvent.Name = "TriggerJumpscare"
jumpscareEvent.Parent = horrorEvents

-- รอกลุ่มแผนที่
task.wait(2)
local facility = Workspace:WaitForChild("HorrorFacility", 20)

----------------------------------------------------------------------
-- 1. สร้างตัวผี (PROCEDURAL SHADOW MONSTER)
----------------------------------------------------------------------
local function createMonster()
    local monster = Instance.new("Model")
    monster.Name = "ShadowStalker"
    monster.Parent = Workspace

    -- Humanoid & RootPart
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.CFrame = CFrame.new(0, 5, -20)
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Parent = monster

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2.4, 3.5, 1.2)
    torso.CFrame = hrp.CFrame
    torso.Color = Color3.fromRGB(10, 10, 10)
    torso.Material = Enum.Material.SmoothPlastic
    torso.CanCollide = true
    torso.CastShadow = true
    torso.Parent = monster

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.8, 1.8, 1.8)
    head.CFrame = torso.CFrame + Vector3.new(0, 2.6, 0)
    head.Color = Color3.fromRGB(5, 5, 5)
    head.Material = Enum.Material.SmoothPlastic
    head.Parent = monster

    -- ตาแดงสยองขวัญ (Glowing Red Eyes)
    local leftEye = Instance.new("Part")
    leftEye.Name = "LeftEye"
    leftEye.Size = Vector3.new(0.3, 0.3, 0.2)
    leftEye.CFrame = head.CFrame * CFrame.new(-0.4, 0.2, -0.9)
    leftEye.Color = Color3.fromRGB(255, 0, 0)
    leftEye.Material = Enum.Material.Neon
    leftEye.CanCollide = false
    leftEye.Parent = monster

    local rightEye = Instance.new("Part")
    rightEye.Name = "RightEye"
    rightEye.Size = Vector3.new(0.3, 0.3, 0.2)
    rightEye.CFrame = head.CFrame * CFrame.new(0.4, 0.2, -0.9)
    rightEye.Color = Color3.fromRGB(255, 0, 0)
    rightEye.Material = Enum.Material.Neon
    rightEye.CanCollide = false
    rightEye.Parent = monster

    local eyeLight = Instance.new("PointLight")
    eyeLight.Color = Color3.fromRGB(255, 20, 20)
    eyeLight.Range = 10
    eyeLight.Brightness = 2
    eyeLight.Parent = head

    -- เชื่อมชิ้นส่วนด้วย Motor6D/Weld
    local function weld(p0, p1)
        local w = Instance.new("WeldConstraint")
        w.Part0 = p0
        w.Part1 = p1
        w.Parent = p0
    end
    weld(hrp, torso)
    weld(torso, head)
    weld(head, leftEye)
    weld(head, rightEye)

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 999999
    humanoid.Health = 999999
    humanoid.WalkSpeed = 9
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = monster

    monster.PrimaryPart = hrp

    -- เสียงหายใจหลอน / เสียงคำราม
    local groanSound = Instance.new("Sound")
    groanSound.Name = "MonsterGroan"
    groanSound.SoundId = "rbxassetid://9114221580" -- เสียงหายใจครืดคราด
    groanSound.Looped = true
    groanSound.Volume = 0.8
    groanSound.RollOffMaxDistance = 50
    groanSound.RollOffMinDistance = 5
    groanSound.Parent = torso
    groanSound:Play()

    return monster
end

local monster = createMonster()
local humanoid = monster:WaitForChild("Humanoid")
local hrp = monster:WaitForChild("HumanoidRootPart")

----------------------------------------------------------------------
-- 2. จุดเดินตรวจตรา (PATROL WAYPOINTS)
----------------------------------------------------------------------
local waypoints = {
    Vector3.new(0, 3, 30),
    Vector3.new(-28, 3, 20),   -- ในห้อง C
    Vector3.new(0, 3, 0),      -- โถงกลาง
    Vector3.new(-28, 3, -20),  -- ในห้อง A
    Vector3.new(0, 3, -30),
    Vector3.new(28, 3, -20),   -- ในห้อง B
    Vector3.new(0, 3, -50),    -- ใกล้ทางออก
}

local currentWaypointIndex = 1
local isChasing = false
local targetPlayer = nil
local isCooldown = false

----------------------------------------------------------------------
-- 3. ตรวจจับผู้เล่น (PLAYER DETECTION)
----------------------------------------------------------------------
local function findNearestTarget()
    local nearest = nil
    local shortestDist = 45 -- ระยะสายตาตรวจจับ (studs)

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            local pRoot = character:FindFirstChild("HumanoidRootPart")
            if pRoot then
                local dist = (pRoot.Position - hrp.Position).Magnitude
                if dist < shortestDist then
                    -- ตรวจสอบสิ่งกีดขวาง (Raycast)
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = { monster, character }
                    rayParams.FilterType = RaycastFilterType.Exclude

                    local rayResult = Workspace:Raycast(hrp.Position, (pRoot.Position - hrp.Position), rayParams)
                    if not rayResult then
                        -- มองเห็นตัวตรงๆ
                        nearest = character
                        shortestDist = dist
                    end
                end
            end
        end
    end
    return nearest
end

----------------------------------------------------------------------
-- 4. ตรรกะการล่า & จับผู้เล่น (HUNTING LOOP)
----------------------------------------------------------------------
task.spawn(function()
    while monster and monster.Parent and humanoid.Health > 0 do
        if isCooldown then
            task.wait(1)
            continue
        end

        local spottedTarget = findNearestTarget()

        if spottedTarget then
            -- เข้าสู่โหมดไล่ล่า (CHASE MODE)
            if not isChasing then
                isChasing = true
                humanoid.WalkSpeed = 19 -- วิ่งเร็วขึ้นเมื่อเห็นเหยื่อ!
                
                -- เสียงกรีดร้องตอนเริ่มไล่
                local scream = Instance.new("Sound")
                scream.SoundId = "rbxassetid://9114221147"
                scream.Volume = 1.2
                scream.Parent = hrp
                scream:Play()
                game:GetService("Debris"):AddItem(scream, 3)
            end

            local targetHRP = spottedTarget:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                humanoid:MoveTo(targetHRP.Position)

                -- ตรวจสอบว่าเข้าใกล้พอจะจั๊มสแกแล้วหรือยัง (< 4.5 studs)
                local dist = (targetHRP.Position - hrp.Position).Magnitude
                if dist <= 4.5 then
                    local victimPlayer = Players:GetPlayerFromCharacter(spottedTarget)
                    if victimPlayer then
                        -- หยุดนิ่งและสั่งรัน Jumpscare
                        isCooldown = true
                        isChasing = false
                        humanoid.WalkSpeed = 0

                        -- ส่ง Event จั๊มสแกไปที่เครื่องของผู้เล่น
                        jumpscareEvent:FireClient(victimPlayer, monster)

                        -- ฆ่าผู้เล่นหลังจากจั๊มสแกจบ (ประมาณ 2 วินาที)
                        task.delay(2.2, function()
                            if spottedTarget:FindFirstChild("Humanoid") then
                                spottedTarget.Humanoid.Health = 0
                            end
                            task.wait(3)
                            isCooldown = false
                            humanoid.WalkSpeed = 9
                        end)
                    end
                end
            end
        else
            -- โหมดเดินตรวจตราปกติ (PATROL MODE)
            if isChasing then
                isChasing = false
                humanoid.WalkSpeed = 9
            end

            local wp = waypoints[currentWaypointIndex]
            humanoid:MoveTo(wp)

            local distToWp = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(wp.X, 0, wp.Z)).Magnitude
            if distToWp < 5 then
                currentWaypointIndex = (currentWaypointIndex % #waypoints) + 1
                task.wait(math.random(1, 3))
            end
        end

        task.wait(0.2)
    end
end)

print("[Monster AI] ผี The Shadow Stalker ตื่นขึ้นแล้ว... เตรียมล่าเหยื่อ!")
