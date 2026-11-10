--[[
    DownedAndReviveManager.server.lua
    ใส่ใน: ServerScriptService
    หน้าที่: จัดการระบบเพื่อนล้ม (Downed State), คลานกับพื้น, นับถอยหลังเลือดไหล 30 วินาที,
            เพื่อนกดค้าง [E] 3 วินาทีช่วยชุบได้แต้มโบนัส, และถ้าตายต้องรอจบเวฟ
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local zombieEvents = ReplicatedStorage:WaitForChild("ZombieGameEvents", 20)
local updateScoreboardEvent = zombieEvents:WaitForChild("UpdateScoreboard", 20)

local BLEEDOUT_TIME = 30 -- เวลาเลือดไหลหมดตัว (วินาที)

local function setupCharacter(player, char)
    local humanoid = char:WaitForChild("Humanoid")
    local rootPart = char:WaitForChild("HumanoidRootPart")

    local isDowned = false
    local isBleedoutComplete = false
    local bleedoutCoroutine = nil

    humanoid.Died:Connect(function()
        -- ถ้าตายจริง ปรับสถานะเป็น Dead
        -- Note: เราจะดัก HealthChanged ก่อนจะตายจริง
    end)

    humanoid.HealthChanged:Connect(function(health)
        if player:GetAttribute("IsAdminGodMode") == true or char:GetAttribute("IsAdminGodMode") == true then
            if health < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
            return
        end
        if isDowned and health < 1 then
            -- Keep the player in the downed state when zombies hit again.
            humanoid.Health = 1
            return
        end

        if health <= 0 and not isDowned and not isBleedoutComplete then
            -- เข้าสู่สภาวะ "ล้มรอชุบ" (DOWNED STATE)
            isDowned = true
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            humanoid.Health = 1 -- ล็อคเลือดไว้ 1 ไม่ให้ตัวละครแตกสลาย
            humanoid.WalkSpeed = 3 -- คลานช้าๆ กับพื้น
            humanoid.JumpPower = 0

            -- แจ้งเตือนทุกคน
            print("🚨 " .. player.DisplayName .. " ล้มลงแล้ว! ต้องการคนช่วยชุบด่วน!")

            -- สร้าง ProximityPrompt บนตัวเพื่อนที่ล้ม
            local prompt = Instance.new("ProximityPrompt")
            prompt.Name = "RevivePrompt"
            prompt.ActionText = "ช่วยชุบชีวิต"
            prompt.ObjectText = player.DisplayName .. " [กดค้าง 3 วิ]"
            prompt.HoldDuration = 3.0
            prompt.MaxActivationDistance = 9
            prompt.RequiresLineOfSight = false
            prompt.Parent = rootPart

            -- เมื่อมีเพื่อนมากดชุบ
            prompt.Triggered:Connect(function(saviorPlayer)
                if saviorPlayer ~= player and isDowned then
                    isDowned = false
                    prompt:Destroy()
                    if bleedoutCoroutine then
                        task.cancel(bleedoutCoroutine)
                    end

                    -- Restore normal death handling and movement after revival.
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                    humanoid.Health = 60
                    humanoid.WalkSpeed = 16
                    humanoid.JumpPower = 50

                    -- ให้แต้มคนช่วยชุบ
                    local hitEvent = zombieEvents:FindFirstChild("ZombieHitEvent")
                    print("💖 " .. saviorPlayer.DisplayName .. " ช่วยชุบ " .. player.DisplayName .. " สำเร็จ!")
                end
            end)

            -- นับถอยหลังเลือดไหลหมดตัว (Bleedout Timer)
            bleedoutCoroutine = task.spawn(function()
                task.wait(BLEEDOUT_TIME)
                if isDowned then
                    -- Allow the Humanoid to enter its real death state after bleedout.
                    isBleedoutComplete = true
                    isDowned = false
                    prompt:Destroy()
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                    humanoid.Health = 0
                    print("💀 " .. player.DisplayName .. " เลือดหมดตัว เสียชีวิตแล้ว! ต้องรอจบเวฟ")
                end
            end)
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        setupCharacter(player, char)
    end)
end)
