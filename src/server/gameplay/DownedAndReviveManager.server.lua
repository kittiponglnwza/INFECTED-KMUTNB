--[[
    DownedAndReviveManager.server.lua
    ใส่ใน: ServerScriptService
    หน้าที่: จัดการระบบเพื่อนล้ม (Downed State), คลานกับพื้น, นับถอยหลังเลือดไหล 30 วินาที,
            เพื่อนกดค้าง [E] 3 วินาทีช่วยชุบได้แต้มโบนัส, และถ้าตายต้องรอจบเวฟ
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local zombieEvents = ReplicatedStorage:WaitForChild("ZombieGameEvents", 20)

local BLEEDOUT_TIME = 30 -- เวลาเลือดไหลหมดตัว (วินาที)
local REVIVE_HEALTH = 60

local activeDownedControllers = {}

local function clearDownedState(player, char)
	if player then
		player:SetAttribute("IsDowned", false)
		player:SetAttribute("BleedoutEndTime", nil)
	end
	if char then
		char:SetAttribute("IsDowned", false)
		char:SetAttribute("BleedoutEndTime", nil)
	end
end

local function isPlayerAliveAndStanding(player)
	if not player or not player.Parent then return false end
	if player:GetAttribute("IsDowned") == true then return false end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or char:GetAttribute("IsDowned") == true then
		return false
	end
	return true
end

local function countAliveStandingTeammates(excludePlayer)
	local count = 0
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= excludePlayer and isPlayerAliveAndStanding(other) then
			count = count + 1
		end
	end
	return count
end

local function wipeRemainingDownedIfNoSaviors(leavingOrDeadPlayer)
	if countAliveStandingTeammates(leavingOrDeadPlayer) > 0 then
		return
	end
	for userId, forceKill in pairs(activeDownedControllers) do
		if type(forceKill) == "function" then
			task.spawn(forceKill, "ไม่มีเพื่อนรอดเหลือในสนาม")
		end
		activeDownedControllers[userId] = nil
	end
end

local function setupCharacter(player, char)
	local humanoid = char:WaitForChild("Humanoid", 10)
	local rootPart = char:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not rootPart then return end

	clearDownedState(player, char)

	local isDowned = false
	local isBleedoutComplete = false
	local bleedoutCoroutine = nil
	local activePrompt = nil

	local function destroyPrompt()
		if activePrompt and activePrompt.Parent then
			activePrompt:Destroy()
		end
		activePrompt = nil
	end

	local function enterTrueDeath(reason)
		if isBleedoutComplete then return end
		isBleedoutComplete = true
		isDowned = false
		activeDownedControllers[player.UserId] = nil

		if bleedoutCoroutine then
			pcall(task.cancel, bleedoutCoroutine)
			bleedoutCoroutine = nil
		end

		destroyPrompt()
		clearDownedState(player, char)

		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
		if humanoid.Health > 0 then
			humanoid.Health = 0
		end
		humanoid:ChangeState(Enum.HumanoidStateType.Dead)

		if reason then
			print(string.format("💀 %s เสียชีวิต (%s)", player.DisplayName, reason))
		end
	end

	local function isGodModeActive()
		return player:GetAttribute("IsAdminGodMode") == true or char:GetAttribute("IsAdminGodMode") == true
	end

	local function syncGodModeProtection()
		if isGodModeActive() then
			if isDowned then
				isDowned = false
				activeDownedControllers[player.UserId] = nil
				if bleedoutCoroutine then
					pcall(task.cancel, bleedoutCoroutine)
					bleedoutCoroutine = nil
				end
				destroyPrompt()
				clearDownedState(player, char)
				humanoid.JumpPower = 50
			end
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			if humanoid.Health < humanoid.MaxHealth then
				humanoid.Health = humanoid.MaxHealth
			end
		elseif not isDowned then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
		end
	end

	local godConnP = player:GetAttributeChangedSignal("IsAdminGodMode"):Connect(syncGodModeProtection)
	local godConnC = char:GetAttributeChangedSignal("IsAdminGodMode"):Connect(syncGodModeProtection)
	syncGodModeProtection()

	humanoid.Died:Connect(function()
		isDowned = false
		isBleedoutComplete = true
		activeDownedControllers[player.UserId] = nil
		if bleedoutCoroutine then
			pcall(task.cancel, bleedoutCoroutine)
			bleedoutCoroutine = nil
		end
		destroyPrompt()
		clearDownedState(player, char)
		godConnP:Disconnect()
		godConnC:Disconnect()
		wipeRemainingDownedIfNoSaviors(player)
	end)

	char.AncestryChanged:Connect(function(_, parent)
		if not parent then
			activeDownedControllers[player.UserId] = nil
			if bleedoutCoroutine then
				pcall(task.cancel, bleedoutCoroutine)
				bleedoutCoroutine = nil
			end
			godConnP:Disconnect()
			godConnC:Disconnect()
			destroyPrompt()
		end
	end)

	humanoid.HealthChanged:Connect(function(health)
		if isGodModeActive() then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			if health < humanoid.MaxHealth then
				humanoid.Health = humanoid.MaxHealth
			end
			return
		end

		if isBleedoutComplete then
			return
		end

		if isDowned then
			-- Keep downed player locked at 1 HP so auto-heal or extra hits cannot break downed state
			if health ~= 1 then
				humanoid.Health = 1
			end
			return
		end

		if health <= 0 then
			-- Only enter Downed state if at least one standing teammate is alive to revive!
			if countAliveStandingTeammates(player) <= 0 then
				enterTrueDeath("ไม่มีเพื่อนเหลือช่วยชุบ")
				wipeRemainingDownedIfNoSaviors(player)
				return
			end

			isDowned = true
			activeDownedControllers[player.UserId] = enterTrueDeath
			player:SetAttribute("IsDowned", true)
			char:SetAttribute("IsDowned", true)

			local bleedoutEnd = Workspace:GetServerTimeNow() + BLEEDOUT_TIME
			player:SetAttribute("BleedoutEndTime", bleedoutEnd)
			char:SetAttribute("BleedoutEndTime", bleedoutEnd)

			humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			humanoid.Health = 1
			humanoid.WalkSpeed = 4
			humanoid.JumpPower = 0

			-- Check if taking this player down caused all remaining players to be downed
			wipeRemainingDownedIfNoSaviors(nil)
			if not isDowned then
				return
			end

			print("🚨 " .. player.DisplayName .. " ล้มลงแล้ว! ต้องการคนช่วยชุบด่วน!")

			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "RevivePrompt"
			prompt.ActionText = "ช่วยชุบชีวิต"
			prompt.ObjectText = player.DisplayName .. " [กดค้าง 3 วิ]"
			prompt.HoldDuration = 3.0
			prompt.MaxActivationDistance = 9
			prompt.RequiresLineOfSight = false
			prompt.Parent = rootPart
			activePrompt = prompt

			prompt.Triggered:Connect(function(saviorPlayer)
				if saviorPlayer ~= player and isDowned and isPlayerAliveAndStanding(saviorPlayer) then
					isDowned = false
					activeDownedControllers[player.UserId] = nil
					if bleedoutCoroutine then
						pcall(task.cancel, bleedoutCoroutine)
						bleedoutCoroutine = nil
					end
					destroyPrompt()
					clearDownedState(player, char)

					humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
					humanoid.Health = REVIVE_HEALTH
					humanoid.WalkSpeed = 16
					humanoid.JumpPower = 50

					print("💖 " .. saviorPlayer.DisplayName .. " ช่วยชุบ " .. player.DisplayName .. " สำเร็จ!")
				end
			end)

			bleedoutCoroutine = task.spawn(function()
				task.wait(BLEEDOUT_TIME)
				if isDowned then
					enterTrueDeath("เลือดหมดตัว")
				end
			end)
		end
	end)
end

local function bindPlayer(player)
	clearDownedState(player, player.Character)
	player.CharacterAdded:Connect(function(char)
		setupCharacter(player, char)
	end)
	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	bindPlayer(player)
end

Players.PlayerAdded:Connect(bindPlayer)

Players.PlayerRemoving:Connect(function(player)
	activeDownedControllers[player.UserId] = nil
	wipeRemainingDownedIfNoSaviors(player)
end)
