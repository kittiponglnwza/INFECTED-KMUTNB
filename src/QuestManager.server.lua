--[[
    QuestManager.server.lua
    ใส่ใน: ServerScriptService
    หน้าที่: จัดการระบบภารกิจ (สปอว์นฟิวส์ 3 ตัว, ตรวจสอบการเก็บของ, เปิดประตูทางออกเมื่อทำสำเร็จ)
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- สร้าง RemoteEvents สำหรับสื่อสารกับ Client
local horrorEvents = Instance.new("Folder")
horrorEvents.Name = "HorrorEvents"
horrorEvents.Parent = ReplicatedStorage

local updateQuestEvent = Instance.new("RemoteEvent")
updateQuestEvent.Name = "UpdateQuestUI"
updateQuestEvent.Parent = horrorEvents

local alertMessageEvent = Instance.new("RemoteEvent")
alertMessageEvent.Name = "AlertMessage"
alertMessageEvent.Parent = horrorEvents

local victoryEvent = Instance.new("RemoteEvent")
victoryEvent.Name = "VictoryEvent"
victoryEvent.Parent = horrorEvents

-- ตารางเก็บสถานะของผู้เล่นแต่ละคน (จำนวนฟิวส์ที่เก็บได้)
local playerFuses = {}
local TOTAL_FUSES_NEEDED = 3
local isFacilityPowered = false

-- รอให้แผนที่สร้างเสร็จ
task.wait(1.5)
local facility = Workspace:WaitForChild("HorrorFacility", 20)
if not facility then
    warn("ไม่พบโมเดล HorrorFacility! ตรวจสอบว่า MapAndLightingGenerator ทำงานหรือไม่")
    return
end

local exitArea = facility:WaitForChild("ExitArea", 10)
local exitDoor = exitArea and exitArea:WaitForChild("ExitDoor", 10)
local generatorBox = exitArea and exitArea:WaitForChild("GeneratorBox", 10)

----------------------------------------------------------------------
-- 1. ฟังก์ชันสร้างชิ้นส่วนฟิวส์ (ENERGY FUSE)
----------------------------------------------------------------------
local function spawnFuse(name, position)
    local fuseModel = Instance.new("Model")
    fuseModel.Name = name
    fuseModel.Parent = facility

    -- ตัวฟิวส์
    local fusePart = Instance.new("Part")
    fusePart.Name = "FuseBody"
    fusePart.Size = Vector3.new(0.8, 1.8, 0.8)
    fusePart.CFrame = CFrame.new(position)
    fusePart.Color = Color3.fromRGB(0, 200, 255)
    fusePart.Material = Enum.Material.Neon
    fusePart.Anchored = true
    fusePart.CanCollide = false
    fusePart.Parent = fuseModel

    -- แสงออร่าสีฟ้าอ่อนๆ ส่องประกายให้ผู้เล่นสังเกตเห็นในความมืด
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(0, 220, 255)
    light.Range = 12
    light.Brightness = 2.5
    light.Parent = fusePart

    -- ProximityPrompt สำหรับกด E เก็บ
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "เก็บฟิวส์ไฟฟ้า"
    prompt.ObjectText = "Energy Fuse"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.Parent = fusePart

    prompt.Triggered:Connect(function(player)
        local currentCount = playerFuses[player.UserId] or 0
        currentCount = currentCount + 1
        playerFuses[player.UserId] = currentCount

        -- เสียงเก็บของ
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://9114223170" -- เสียงเก็บไอเทม/ไฟฟ้า
        sound.Volume = 1
        sound.Parent = player.Character or Workspace
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 3)

        -- อัปเดต UI ให้ผู้เล่นคนนั้น
        updateQuestEvent:FireClient(player, currentCount, TOTAL_FUSES_NEEDED)
        alertMessageEvent:FireClient(player, "คุณเก็บฟิวส์ได้แล้ว (" .. currentCount .. "/" .. TOTAL_FUSES_NEEDED .. ")", Color3.fromRGB(0, 255, 180))

        -- ลบฟิวส์ตัวนี้ออก
        fuseModel:Destroy()
    end)

    -- เอฟเฟกต์หมุนฟิวส์ลอยในอากาศ
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

-- สปอว์นฟิวส์ 3 ตัวในห้อง A, B, C
spawnFuse("Fuse_1", Vector3.new(-28, 2, -20)) -- ห้อง A
spawnFuse("Fuse_2", Vector3.new(28, 2, -20))  -- ห้อง B
spawnFuse("Fuse_3", Vector3.new(-28, 2, 20))  -- ห้อง C

----------------------------------------------------------------------
-- 2. ระบบตู้เบรกเกอร์ (GENERATOR BOX) สำหรับเสียบฟิวส์เปิดประตู
----------------------------------------------------------------------
if generatorBox then
    local genPrompt = Instance.new("ProximityPrompt")
    genPrompt.ActionText = "เปิดเครื่องจ่ายไฟ"
    genPrompt.ObjectText = "Main Generator"
    genPrompt.HoldDuration = 1.0
    genPrompt.MaxActivationDistance = 9
    genPrompt.RequiresLineOfSight = false
    genPrompt.Parent = generatorBox

    genPrompt.Triggered:Connect(function(player)
        if isFacilityPowered then
            alertMessageEvent:FireClient(player, "ระบบไฟฟ้าทำงานแล้ว ประตูทางออกเปิดอยู่!", Color3.fromRGB(100, 255, 100))
            return
        end

        local count = playerFuses[player.UserId] or 0
        if count < TOTAL_FUSES_NEEDED then
            -- ฟิวส์ยังไม่ครบ
            alertMessageEvent:FireClient(player, "ไฟฟ้าไม่พอ! คุณต้องหาฟิวส์ให้ครบ 3 ตัวก่อน (ตอนนี้มี " .. count .. "/3)", Color3.fromRGB(255, 80, 80))
        else
            -- ฟิวส์ครบ 3 ตัว! สตาร์ตเครื่องปั่นไฟและเปิดประตู
            isFacilityPowered = true
            genPrompt.Enabled = false

            -- เปลี่ยนสถานะหลอดไฟเป็นสีเขียว
            local statusLight = generatorBox:FindFirstChild("StatusLight")
            if statusLight then
                statusLight.Color = Color3.fromRGB(0, 255, 0)
                statusLight.Brightness = 4
            end

            local surfaceGui = generatorBox:FindFirstChildOfClass("SurfaceGui")
            if surfaceGui and surfaceGui:FindFirstChild("StatusText") then
                surfaceGui.StatusText.TextColor3 = Color3.fromRGB(0, 255, 100)
                surfaceGui.StatusText.Text = "SYSTEM ONLINE\n[EXIT OPEN]"
            end

            -- แจ้งเตือนทุกคน
            for _, p in ipairs(Players:GetPlayers()) do
                alertMessageEvent:FireClient(p, "⚠️ เสียงเครื่องกำเนิดไฟฟ้าดังขึ้น! ประตูทางออกเปิดแล้ว!", Color3.fromRGB(255, 220, 0))
            end

            -- อนิเมชันเลื่อนประตูขึ้น (Tween)
            if exitDoor then
                local doorTween = TweenService:Create(
                    exitDoor,
                    TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { CFrame = exitDoor.CFrame + Vector3.new(0, 10, 0) }
                )
                doorTween:Play()
                exitDoor.CanCollide = false
            end
        end
    end)
end

----------------------------------------------------------------------
-- 3. จุด Trigger หนีรอดผ่านประตูทางออก (ESCAPE TRIGGER)
----------------------------------------------------------------------
local escapePad = Instance.new("Part")
escapePad.Name = "EscapeTrigger"
escapePad.Size = Vector3.new(12, 10, 4)
escapePad.CFrame = CFrame.new(0, 5, -(120/2) - 5)
escapePad.Transparency = 1
escapePad.Anchored = true
escapePad.CanCollide = false
escapePad.Parent = facility

escapePad.Touched:Connect(function(hit)
    local character = hit.Parent
    local player = Players:GetPlayerFromCharacter(character)
    if player and isFacilityPowered then
        victoryEvent:FireClient(player)
    end
end)

-- รีเซ็ตค่าเมื่อผู้เล่นเข้าเกม
Players.PlayerAdded:Connect(function(player)
    playerFuses[player.UserId] = 0
    task.wait(1)
    updateQuestEvent:FireClient(player, 0, TOTAL_FUSES_NEEDED)
end)

Players.PlayerRemoving:Connect(function(player)
    playerFuses[player.UserId] = nil
end)

print("[Quest Manager] ระบบเควสต์ฟิวส์และประตูทางออกพร้อมทำงาน!")
