--[[
    BarricadeManager.server.lua
    ใส่ใน: ServerScriptService
    หน้าที่: จัดการระบบแนวกั้นไม้ Barricade ตามหน้าต่าง/ประตูโรงอาหารชั้น 2
            ซอมบี้ต้องทุบไม้ให้พังก่อนถึงจะเข้าได้, ผู้เล่นกด [E] ซ่อมไม้ได้แต้ม
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local zombieEvents = ReplicatedStorage:WaitForChild("ZombieGameEvents", 20)
local hitEvent = zombieEvents:WaitForChild("ZombieHitEvent", 20)

task.wait(2)
local building = Workspace:WaitForChild("KMUTNB_Building40", 25)
if not building then return end

local floor2 = building:WaitForChild("Floor_2_Canteen", 20)
if not floor2 then return end

----------------------------------------------------------------------
-- 1. ฟังก์ชันสร้างจุด BARRICADE (WOODEN PLANKS)
----------------------------------------------------------------------
local function createBarricadeSpot(name, cframe, size)
    local barricade = Instance.new("Model")
    barricade.Name = name
    barricade.Parent = floor2

    local framePart = Instance.new("Part")
    framePart.Name = "Frame"
    framePart.Size = size
    framePart.CFrame = cframe
    framePart.Transparency = 1
    framePart.Anchored = true
    framePart.CanCollide = false
    framePart.Parent = barricade

    local planks = {}
    local maxPlanks = 5
    local currentPlanks = 5

    -- สร้างแผ่นไม้ 5 แผ่น
    for i = 1, maxPlanks do
        local plankY = (cframe.Y - size.Y/2) + (i * (size.Y / (maxPlanks + 1)))
        local plank = Instance.new("Part")
        plank.Name = "Plank_" .. i
        plank.Size = Vector3.new(size.X, 1.2, 0.6)
        plank.CFrame = CFrame.new(cframe.X, plankY, cframe.Z) * CFrame.Angles(0, 0, math.rad((i % 2 == 0) and 4 or -4))
        plank.Color = Color3.fromRGB(110, 75, 45)
        plank.Material = Enum.Material.WoodPlanks
        plank.Anchored = true
        plank.CanCollide = true
        plank.Parent = barricade
        table.insert(planks, plank)
    end

    -- ProximityPrompt สำหรับซ่อมไม้
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "ซ่อมแนวกั้นไม้"
    prompt.ObjectText = "[+10 แต้ม]"
    prompt.HoldDuration = 0.6
    prompt.MaxActivationDistance = 9
    prompt.Enabled = false
    prompt.Parent = framePart

    prompt.Triggered:Connect(function(player)
        if currentPlanks < maxPlanks then
            currentPlanks = currentPlanks + 1
            planks[currentPlanks].Transparency = 0
            planks[currentPlanks].CanCollide = true

            -- เสียงตอกตะปู
            local hammer = Instance.new("Sound")
            hammer.SoundId = "rbxassetid://9114223170"
            hammer.Volume = 0.8
            hammer.Parent = framePart
            hammer:Play()
            Debris:AddItem(hammer, 2)

            if currentPlanks >= maxPlanks then
                prompt.Enabled = false
            end
        end
    end)

    -- ฟังก์ชันให้ซอมบี้ทุบไม้
    barricade:SetAttribute("DamageBarricade", function()
        if currentPlanks > 0 then
            planks[currentPlanks].Transparency = 1
            planks[currentPlanks].CanCollide = false
            currentPlanks = currentPlanks - 1
            prompt.Enabled = true
            return true -- ยังมีไม้กั้นอยู่
        end
        return false -- ไม้พังหมดแล้ว ซอมบี้เดินผ่านได้!
    end)

    return barricade
end

-- สร้างจุด Barricade ตามหน้าต่างโรงอาหารชั้น 2
createBarricadeSpot("Barricade_North1", CFrame.new(-30, 24, 60), Vector3.new(10, 8, 1))
createBarricadeSpot("Barricade_North2", CFrame.new(30, 24, 60), Vector3.new(10, 8, 1))
createBarricadeSpot("Barricade_South1", CFrame.new(-30, 24, -60), Vector3.new(10, 8, 1))
createBarricadeSpot("Barricade_South2", CFrame.new(30, 24, -60), Vector3.new(10, 8, 1))

print("🔨 ติดตั้งระบบแนวกั้นไม้ Barricade ชั้น 2 โรงอาหาร มจพ. เรียบร้อยแล้ว!")
