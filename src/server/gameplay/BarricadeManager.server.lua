--[[
    BarricadeManager.server.lua
    ใส่ใน: ServerScriptService -> Gameplay
    หน้าที่: จัดการระบบแนวกั้นไม้ Barricade ทั่วอาคาร 40 ปี มจพ.
            - ตรวจจับจุด Barricade อัตโนมัติทุกชั้น
            - ผู้เล่นสามารถกด [E] ซ่อมแผ่นไม้เพื่อรับแต้ม (+10 Points)
            - มีเสียงตอกตะปูและบันทึกสถานะความทนทานของไม้
]]

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local zombieEvents = ReplicatedStorage:WaitForChild("ZombieGameEvents", 20)
local hitEvent = zombieEvents and zombieEvents:WaitForChild("ZombieHitEvent", 20)

task.wait(1)
local scanRoot = Workspace:FindFirstChild("KMUTNB_Building40") or Workspace

local function awardRepairPoints(player, amount)
    local wFolder = ServerStorage:FindFirstChild("WeaponSignals")
    local addPtsSignal = wFolder and wFolder:FindFirstChild("AddPoints")
    if addPtsSignal and addPtsSignal:IsA("BindableEvent") then
        addPtsSignal:Fire(player, amount)
    end
end

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
    local initPlanks = tonumber(barricadeModel:GetAttribute("InitialPlanks"))
    local currentPlanks = math.clamp(math.floor(initPlanks or maxPlanks), 0, maxPlanks)

    for idx, p in ipairs(planks) do
        local intact = (idx <= currentPlanks)
        p.Transparency = intact and 0 or 1
        p.CanCollide = intact
    end

    barricadeModel:SetAttribute("MaxPlanks", maxPlanks)
    barricadeModel:SetAttribute("PlanksRemaining", currentPlanks)
    barricadeModel:SetAttribute("BarricadeCenter", framePart.Position)
    CollectionService:AddTag(barricadeModel, "BreakableBarricade")

    -- ProximityPrompt สำหรับซ่อมไม้
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "ซ่อมแนวกั้นไม้"
    prompt.ObjectText = string.format("แนวกั้น (%d/%d แผ่น) [+10 แต้ม]", currentPlanks, maxPlanks)
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 9.5
    prompt.RequiresLineOfSight = false
    prompt.Enabled = (currentPlanks < maxPlanks)
    prompt.Parent = framePart

    local function syncPromptText()
        prompt.ObjectText = string.format("แนวกั้น (%d/%d แผ่น) [+10 แต้ม]", currentPlanks, maxPlanks)
        barricadeModel:SetAttribute("PlanksRemaining", currentPlanks)
    end

    prompt.Triggered:Connect(function(player)
        if currentPlanks < maxPlanks then
            currentPlanks = currentPlanks + 1
            if planks[currentPlanks] then
                planks[currentPlanks].Transparency = 0
                planks[currentPlanks].CanCollide = true
            end
            syncPromptText()
            awardRepairPoints(player, 10)

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

    -- BindableFunction lets other server scripts damage this barricade.
    local damageFn = barricadeModel:FindFirstChild("DamageBarricade")
    if damageFn and not damageFn:IsA("BindableFunction") then
        damageFn:Destroy()
        damageFn = nil
    end
    if not damageFn then
        damageFn = Instance.new("BindableFunction")
        damageFn.Name = "DamageBarricade"
        damageFn.Parent = barricadeModel
    end
    damageFn.OnInvoke = function()
        if currentPlanks > 0 then
            if planks[currentPlanks] then
                planks[currentPlanks].Transparency = 1
                planks[currentPlanks].CanCollide = false
            end
            currentPlanks = currentPlanks - 1
            syncPromptText()
            prompt.Enabled = true

            local crack = Instance.new("Sound")
            crack.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
            crack.PlaybackSpeed = 1.8
            crack.Volume = 0.45
            crack.Parent = framePart
            crack:Play()
            Debris:AddItem(crack, 1.5)
            return true -- ยังมีไม้กั้นอยู่
        end
        return false -- ไม้พังหมดแล้ว ซอมบี้เดินผ่านได้!
    end

    -- Optional server signal helper to restore all planks on mission reset
    local resetFn = barricadeModel:FindFirstChild("ResetBarricade") or Instance.new("BindableFunction")
    resetFn.Name = "ResetBarricade"
    resetFn.OnInvoke = function()
        currentPlanks = maxPlanks
        for _, p in ipairs(planks) do
            p.Transparency = 0
            p.CanCollide = true
        end
        syncPromptText()
        prompt.Enabled = false
        return true
    end
    resetFn.Parent = barricadeModel
end

----------------------------------------------------------------------
-- 2. สแกนและลงทะเบียน Barricades ทุกตัวในตึก (รองรับทั้ง Static & Procedural)
----------------------------------------------------------------------
local function scanAllBarricades(rootInst)
    for _, desc in ipairs(rootInst:GetDescendants()) do
        if desc:IsA("Model") and desc.Name:match("^Barricade_") then
            setupBarricadeModel(desc)
        end
    end
end

scanAllBarricades(scanRoot)
if scanRoot ~= Workspace then
    scanAllBarricades(Workspace)
end

Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("Model") and desc.Name:match("^Barricade_") then
        task.wait(0.2)
        if desc.Parent then
            setupBarricadeModel(desc)
        end
    end
end)

print("🔨 [BarricadeManager] ระบบแนวกั้นไม้ Barricade พร้อมใช้งานทั่วอาคาร 40 ปี!")
