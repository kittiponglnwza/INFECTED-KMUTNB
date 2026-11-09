--[[
    BarricadeManager.server.lua
    ใส่ใน: ServerScriptService -> Gameplay
    หน้าที่: จัดการระบบแนวกั้นไม้ Barricade ทั่วอาคาร 40 ปี มจพ.
            - ตรวจจับจุด Barricade อัตโนมัติทุกชั้น
            - ผู้เล่นสามารถกด [E] ซ่อมแผ่นไม้เพื่อรับแต้ม (+10 Points)
            - มีเสียงตอกตะปูและบันทึกสถานะความทนทานของไม้
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local zombieEvents = ReplicatedStorage:WaitForChild("ZombieGameEvents", 20)
local hitEvent = zombieEvents and zombieEvents:WaitForChild("ZombieHitEvent", 20)

task.wait(2)
local building = Workspace:WaitForChild("KMUTNB_Building40", 25)
if not building then return end

----------------------------------------------------------------------
-- 1. ฟังก์ชันลงทะเบียน Barricade
----------------------------------------------------------------------
local function setupBarricadeModel(barricadeModel)
    if barricadeModel:GetAttribute("IsBarricadeReady") then return end
    barricadeModel:SetAttribute("IsBarricadeReady", true)

    local framePart = barricadeModel:FindFirstChild("Frame")
    if not framePart then
        framePart = barricadeModel:FindFirstChildWhichIsA("BasePart")
    end
    if not framePart then return end

    local planks = {}
    for i = 1, 10 do
        local p = barricadeModel:FindFirstChild("Plank_" .. i)
        if p and p:IsA("BasePart") then
            table.insert(planks, p)
        end
    end

    local maxPlanks = #planks
    if maxPlanks == 0 then return end
    local currentPlanks = maxPlanks

    -- ProximityPrompt สำหรับซ่อมไม้
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "ซ่อมแนวกั้นไม้"
    prompt.ObjectText = "[+10 แต้ม]"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 9
    prompt.Enabled = false
    prompt.Parent = framePart

    prompt.Triggered:Connect(function(player)
        if currentPlanks < maxPlanks then
            currentPlanks = currentPlanks + 1
            if planks[currentPlanks] then
                planks[currentPlanks].Transparency = 0
                planks[currentPlanks].CanCollide = true
            end

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
    barricadeModel:SetAttribute("DamageBarricade", function()
        if currentPlanks > 0 then
            if planks[currentPlanks] then
                planks[currentPlanks].Transparency = 1
                planks[currentPlanks].CanCollide = false
            end
            currentPlanks = currentPlanks - 1
            prompt.Enabled = true
            return true -- ยังมีไม้กั้นอยู่
        end
        return false -- ไม้พังหมดแล้ว ซอมบี้เดินผ่านได้!
    end)
end

----------------------------------------------------------------------
-- 2. สแกนและลงทะเบียน Barricades ทุกตัวในตึก
----------------------------------------------------------------------
local function scanAllBarricades()
    for _, desc in ipairs(building:GetDescendants()) do
        if desc:IsA("Model") and desc.Name:match("^Barricade_") then
            setupBarricadeModel(desc)
        end
    end
end

scanAllBarricades()
building.DescendantAdded:Connect(function(desc)
    if desc:IsA("Model") and desc.Name:match("^Barricade_") then
        task.wait(0.2)
        setupBarricadeModel(desc)
    end
end)

print("🔨 [BarricadeManager] ระบบแนวกั้นไม้ Barricade พร้อมใช้งานทั่วอาคาร 40 ปี!")
