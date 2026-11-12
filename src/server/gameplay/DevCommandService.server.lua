-- Server-authoritative Developer Command & Toolkit Service.
-- Handles !dev, !dev off, !mission, !objective, !give, !spawn, !tp, !power, !god cleanly.
-- Strictly restricted to allowlisted developers (ServerEnvironmentConfig + DevAuthService).
-- Disabled in public production servers by default; zero client flags trusted.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local NetProtocol = require(sharedFolder:WaitForChild("NetProtocol"))
local ItemCatalog = require(sharedFolder:WaitForChild("ItemCatalog"))
local MissionConfig = require(sharedFolder:WaitForChild("MissionConfig"))
local MissionLogicTests = require(sharedFolder:WaitForChild("MissionLogicTests"))

local campaignFolder = ServerScriptService:WaitForChild("Campaign", 10)
local DevAuthService = require(campaignFolder:WaitForChild("DevAuthService"))
local KeyItemService = require(campaignFolder:WaitForChild("KeyItemService"))
local FloorClearanceService = require(campaignFolder:WaitForChild("FloorClearanceService"))
local DoorAccessService = require(campaignFolder:WaitForChild("DoorAccessService"))
local ZombieDirector = require(campaignFolder:WaitForChild("ZombieDirector"))
local ObjectiveTracker = require(campaignFolder:WaitForChild("ObjectiveTracker"))
local CCTVPuzzleEngine = require(campaignFolder:WaitForChild("CCTVPuzzleEngine"))
local devAuth = DevAuthService.getSingleton()

local missionEvents = ReplicatedStorage:WaitForChild(NetProtocol.Remotes.MissionEventsFolder, 15)
if not missionEvents then
	missionEvents = Instance.new("Folder")
	missionEvents.Name = NetProtocol.Remotes.MissionEventsFolder
	missionEvents.Parent = ReplicatedStorage
end

local devFeedbackEvent = missionEvents:WaitForChild(NetProtocol.Remotes.DevFeedback, 15)
if not devFeedbackEvent then
	devFeedbackEvent = Instance.new("RemoteEvent")
	devFeedbackEvent.Name = NetProtocol.Remotes.DevFeedback
	devFeedbackEvent.Parent = missionEvents
end

local clientCommandFn = missionEvents:FindFirstChild(NetProtocol.Remotes.ClientCommand)
if not clientCommandFn then
	clientCommandFn = Instance.new("RemoteFunction")
	clientCommandFn.Name = NetProtocol.Remotes.ClientCommand
	clientCommandFn.Parent = missionEvents
end

local function sendFeedback(player, ok, text)
	print(string.format("[DevCommandService] [%s] %s -> %s", player.Name, ok and "OK" or "DENIED", tostring(text)))
	devFeedbackEvent:FireClient(player, ok, tostring(text))
end

local function tokenize(rawMessage)
	local args = {}
	for word in string.gmatch(rawMessage, "%S+") do
		table.insert(args, word)
	end
	return args
end

local function executeDevCommand(player, rawMessage)
	if type(rawMessage) ~= "string" then
		return false, "Invalid command"
	end
	local trimmed = rawMessage:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed:sub(1, 1) ~= "!" then
		return false, "Not a dev command"
	end

	local tokens = tokenize(trimmed)
	if #tokens == 0 then
		return false, "Empty command"
	end

	local rootCmd = string.lower(tokens[1])
	local supportedRoots = {
		["!dev"] = true,
		["!bypass"] = true,
		["!mission"] = true,
		["!objective"] = true,
		["!give"] = true,
		["!key"] = true,
		["!door"] = true,
		["!clearance"] = true,
		["!boss"] = true,
		["!wave"] = true,
		["!horde"] = true,
		["!noise"] = true,
		["!encounter"] = true,
		["!zombie"] = true,
		["!clearzombies"] = true,
		["!spawn"] = true,
		["!tp"] = true,
		["!power"] = true,
		["!god"] = true,
		["!help"] = true,
		["!test"] = true,
	}
	if not supportedRoots[rootCmd] then
		return false, "Unknown dev command"
	end

	-- 1. Check server-side Developer Allowlist & Environment Policy
	local isAllowed, denyReason = devAuth.isAuthorizedDeveloper(player)
	if not isAllowed then
		sendFeedback(player, false, "ACCESS DENIED: " .. tostring(denyReason))
		return false, denyReason
	end

	-- 2. Handle !dev / !dev on / !dev off / !dev bypass on|off
	if rootCmd == "!dev" then
		local arg = tokens[2] and string.lower(tokens[2]) or "on"
		if arg == "off" or arg == "false" or arg == "0" then
			player:SetAttribute(NetProtocol.Attributes.DevBypassLocks, false)
			devAuth.setDevModeEnabled(player, false)
			local msg = "Development Mode DISABLED -> Campaign Mode restored (GodMode/Bypass off, Teleports locked)."
			sendFeedback(player, true, msg)
			return true, msg
		elseif arg == "on" or arg == "true" or arg == "1" then
			devAuth.setDevModeEnabled(player, true)
			local msg = "Development Mode ENABLED -> Commands & Dev tools unlocked (!help for list)."
			sendFeedback(player, true, msg)
			return true, msg
		elseif arg == "bypass" then
			if not devAuth.isDevModeEnabled(player) then
				devAuth.setDevModeEnabled(player, true)
			end
			local sub = tokens[3] and string.lower(tokens[3]) or ""
			local nextVal = (sub == "on" or sub == "true" or sub == "1") or (sub == "" and player:GetAttribute(NetProtocol.Attributes.DevBypassLocks) ~= true)
			if sub == "off" or sub == "false" or sub == "0" then nextVal = false end
			player:SetAttribute(NetProtocol.Attributes.DevBypassLocks, nextVal)
			local msg = nextVal and "[DEV] Lock Bypass: ON (Doors & Elevators ignore key/tier requirements for you)" or "[DEV] Lock Bypass: OFF (Real lock checks active)"
			sendFeedback(player, true, msg)
			return true, msg
		else
			local msg = "Usage: !dev | !dev off | !dev bypass on/off"
			sendFeedback(player, false, msg)
			return false, msg
		end
	end

	-- 3. Require active Development Mode (auto-enabled in Studio for authorized devs)
	if not devAuth.isDevModeEnabled(player) then
		local okAuto, autoErr = devAuth.authorizeOrAutoStudioDev(player)
		if not okAuto then
			local msg = tostring(autoErr or "Campaign Mode active. Type '!dev' first to enable Development Mode commands.")
			sendFeedback(player, false, msg)
			return false, msg
		end
	end

	devAuth.markDevSessionTainted()

	local missionSignals = ServerStorage:FindFirstChild(NetProtocol.Signals.MissionSignalsFolder)
	local campaignSignals = ServerStorage:FindFirstChild(NetProtocol.Signals.CampaignSignalsFolder)
	local zombieSignals = ServerStorage:FindFirstChild(NetProtocol.Signals.ZombieSignalsFolder)
	local devSignals = ServerStorage:FindFirstChild("DevSignals")
	local weaponSignals = ServerStorage:FindFirstChild(NetProtocol.Signals.WeaponSignalsFolder)
	local survivalSignals = ServerStorage:FindFirstChild(NetProtocol.Signals.SurvivalSignalsFolder)

	if rootCmd == "!bypass" then
		local arg = tokens[2] and string.lower(tokens[2]) or ""
		local nextVal = (arg == "on" or arg == "true" or arg == "1") or (arg == "" and player:GetAttribute(NetProtocol.Attributes.DevBypassLocks) ~= true)
		if arg == "off" or arg == "false" or arg == "0" then nextVal = false end
		player:SetAttribute(NetProtocol.Attributes.DevBypassLocks, nextVal)
		local msg = nextVal and "[DEV] Lock Bypass: ON" or "[DEV] Lock Bypass: OFF"
		sendFeedback(player, true, msg)
		return true, msg
	end

	if rootCmd == "!help" then
		local msg = "DEV CMD: !dev off | !bypass on/off | !mission M1/status/reset | !objective complete <ID> | !give <item> | !key give/consume <item> | !door list/unlock/lock <id> | !clearance <0..4|reset> | !boss <id> | !wave [on/off] | !horde [n] | !noise [w] | !encounter <id> | !zombie off/on/reset/stats | !clearzombies | !spawn <z> | !tp <loc> | !power on/off | !god | !test"
		sendFeedback(player, true, msg)
		return true, msg
	end

	if rootCmd == "!test" then
		local okRun, outOrErr = pcall(function()
			return MissionLogicTests.runAll({
				NetProtocol = NetProtocol,
				ItemCatalog = ItemCatalog,
				MissionConfig = MissionConfig,
				DevAuthService = DevAuthService,
				KeyItemService = KeyItemService,
				FloorClearanceService = FloorClearanceService,
				DoorAccessService = DoorAccessService,
				ZombieDirector = ZombieDirector,
				ObjectiveTracker = ObjectiveTracker,
				CCTVPuzzleEngine = CCTVPuzzleEngine,
			})
		end)
		if okRun and type(outOrErr) == "table" then
			local msg = string.format("[DEV TESTS] PASS (%d/%d suites passed).", #outOrErr, #outOrErr)
			sendFeedback(player, true, msg)
			return true, msg
		else
			local msg = "[DEV TESTS] FAIL: " .. tostring(outOrErr)
			sendFeedback(player, false, msg)
			return false, msg
		end
	end

	if rootCmd == "!mission" then
		local sub = tokens[2] and string.lower(tokens[2]) or "status"
		if sub == "status" then
			local statusFn = missionSignals and missionSignals:FindFirstChild("GetMissionStatus")
			if statusFn and statusFn:IsA("BindableFunction") then
				local ok, summary = statusFn:Invoke()
				sendFeedback(player, ok, summary)
				return ok, summary
			end
			sendFeedback(player, false, "MissionService GetMissionStatus hook not ready.")
			return false, "MissionService not ready"
		elseif sub == "reset" then
			local resetFn = missionSignals and missionSignals:FindFirstChild(NetProtocol.Signals.ResetMission)
			if resetFn and resetFn:IsA("BindableFunction") then
				local ok, msg = resetFn:Invoke(player)
				if not ok then
					sendFeedback(player, false, msg)
				end
				return ok, msg
			end
			sendFeedback(player, false, "MissionService Reset hook not ready.")
			return false, "Reset hook not ready"
		else
			local setFn = missionSignals and missionSignals:FindFirstChild(NetProtocol.Signals.SetMission)
			local allowPreview = (tokens[3] and string.lower(tokens[3]) == "--preview") or false
			if setFn and setFn:IsA("BindableFunction") then
				local ok, msg = setFn:Invoke(tokens[2], player, allowPreview)
				if not ok then
					sendFeedback(player, false, msg)
				end
				return ok, msg
			end
			sendFeedback(player, false, "MissionService SetMission hook not ready.")
			return false, "SetMission hook not ready"
		end
	end

	if rootCmd == "!objective" then
		local action = tokens[2] and string.lower(tokens[2]) or ""
		local objId = tokens[3]
		if action ~= "complete" or not objId then
			local msg = "Usage: !objective complete <ID> (e.g. M1_LOCATE_KEYCARD, M1_ENTER_SECURITY_ROOM, M1_SOLVE_CCTV_PUZZLE, M1_ACTIVATE_SECURITY_CONTROL)"
			sendFeedback(player, false, msg)
			return false, msg
		end
		local devCompleteFn = missionSignals and missionSignals:FindFirstChild("DevCompleteObjective")
		if devCompleteFn and devCompleteFn:IsA("BindableFunction") then
			local ok, msg = devCompleteFn:Invoke(objId, player)
			if not ok then
				sendFeedback(player, false, msg)
			end
			return ok, msg
		end
		sendFeedback(player, false, "MissionService DevCompleteObjective hook not ready.")
		return false, "Hook not ready"
	end

	if rootCmd == "!give" then
		local itemToken = tokens[2]
		local resolved = ItemCatalog.resolveDevGiveToken(itemToken)
		if not resolved then
			local msg = string.format("Unknown item '%s'. Try: keycard, vandal, sheriff, judge, operator, ammo, food, medkit, battery", tostring(itemToken))
			sendFeedback(player, false, msg)
			return false, msg
		end
		if resolved.category == "Quest" then
			local grantQuestFn = missionSignals and missionSignals:FindFirstChild(NetProtocol.Signals.GrantQuestItem)
			if grantQuestFn and grantQuestFn:IsA("BindableFunction") then
				local ok, msg = grantQuestFn:Invoke(resolved.id, player, true)
				if not ok then
					sendFeedback(player, false, msg)
				end
				return ok, msg
			end
			sendFeedback(player, false, "GrantQuestItem signal not ready.")
			return false, "GrantQuestItem not ready"
		elseif resolved.category == "Weapon" then
			local grantWeaponSig = weaponSignals and weaponSignals:FindFirstChild(NetProtocol.Signals.GrantWeapon)
			if grantWeaponSig and grantWeaponSig:IsA("BindableEvent") then
				grantWeaponSig:Fire(player, resolved.id)
				local msg = string.format("[DEV] Granted weapon: %s", resolved.id)
				sendFeedback(player, true, msg)
				return true, msg
			end
			sendFeedback(player, false, "WeaponSignals.GrantWeapon not ready.")
			return false, "GrantWeapon not ready"
		elseif resolved.category == "Supply" then
			if resolved.id == "Ammo" then
				local refillSig = weaponSignals and weaponSignals:FindFirstChild(NetProtocol.Signals.RefillAmmo)
				if refillSig and refillSig:IsA("BindableEvent") then
					refillSig:Fire(player)
					local msg = "[DEV] Refilled reserve ammo for equipped weapons."
					sendFeedback(player, true, msg)
					return true, msg
				end
			else
				local supplyFn = survivalSignals and survivalSignals:FindFirstChild(NetProtocol.Signals.GrantSupply)
				if supplyFn and supplyFn:IsA("BindableFunction") then
					local ok, msg = supplyFn:Invoke(player, resolved.id)
					sendFeedback(player, ok, msg)
					return ok, msg
				end
			end
		end
		sendFeedback(player, false, "Item grant handler unavailable.")
		return false, "Unavailable"
	end

	if rootCmd == "!spawn" then
		local zToken = tokens[2] or "MaleWalker"
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			sendFeedback(player, false, "Spawn character first before spawning zombies.")
			return false, "No HRP"
		end
		local spawnPos = hrp.Position + hrp.CFrame.LookVector * 14 + Vector3.new(0, 1.5, 0)
		local spawnFn = devSignals and devSignals:FindFirstChild("SpawnZombie")
		if spawnFn and spawnFn:IsA("BindableFunction") then
			local ok, result = spawnFn:Invoke(zToken, spawnPos)
			local msg = ok and ("[DEV] Spawned " .. tostring(result) .. " ahead of you.") or tostring(result)
			sendFeedback(player, ok, msg)
			return ok, msg
		end
		sendFeedback(player, false, "DevSignals.SpawnZombie not ready.")
		return false, "SpawnZombie not ready"
	end

	if rootCmd == "!tp" then
		local locArg = tokens[2]
		local destKey = NetProtocol.resolveTeleportAlias(locArg) or locArg
		if type(destKey) ~= "string" or destKey == "" then
			local msg = "Usage: !tp <lobby|keycard|door|security|cafe|plaza|canteen|arena|f11|roof|range>"
			sendFeedback(player, false, msg)
			return false, msg
		end
		local tpFn = devSignals and devSignals:FindFirstChild("TeleportPlayer")
		if tpFn and tpFn:IsA("BindableFunction") then
			local ok, msg = tpFn:Invoke(player, destKey)
			sendFeedback(player, ok, ok and ("[DEV] Teleported -> " .. tostring(msg)) or tostring(msg))
			return ok, msg
		end
		sendFeedback(player, false, "DevSignals.TeleportPlayer not ready.")
		return false, "TeleportPlayer not ready"
	end

	if rootCmd == "!power" then
		local arg = tokens[2] and string.lower(tokens[2]) or ""
		if arg ~= "on" and arg ~= "off" then
			local msg = "Usage: !power on | !power off"
			sendFeedback(player, false, msg)
			return false, msg
		end
		local powerFn = missionSignals and missionSignals:FindFirstChild(NetProtocol.Signals.SetBuildingPower)
		if powerFn and powerFn:IsA("BindableFunction") then
			local ok, msg = powerFn:Invoke(arg == "on", player)
			if not ok then
				sendFeedback(player, false, msg)
			end
			return ok, msg
		end
		sendFeedback(player, false, "SetBuildingPower hook not ready.")
		return false, "SetBuildingPower not ready"
	end

	if rootCmd == "!god" then
		local arg = tokens[2] and string.lower(tokens[2]) or ""
		local nextState
		if arg == "on" or arg == "true" or arg == "1" then
			nextState = true
		elseif arg == "off" or arg == "false" or arg == "0" then
			nextState = false
		elseif arg == "" then
			nextState = not devAuth.isGodModeEnabled(player)
		else
			local msg = "Usage: !god on | !god off"
			sendFeedback(player, false, msg)
			return false, msg
		end
		local ok, result = devAuth.setGodModeEnabled(player, nextState)
		if ok then
			local char = player.Character
			if result == true then
				player:SetAttribute("IsDowned", false)
				player:SetAttribute("BleedoutEndTime", nil)
				if char then
					char:SetAttribute("IsDowned", false)
					char:SetAttribute("BleedoutEndTime", nil)
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
						hum.MaxHealth = 100
						hum.Health = 100
					end
				end
			end
		end
		local msg = ok and (result and "[DEV] God Mode: ON (Invulnerable + Unlimited Stamina)" or "[DEV] God Mode: OFF") or tostring(result)
		sendFeedback(player, ok, msg)
		return ok, msg
	end

	if rootCmd == "!key" then
		local action = tokens[2] and string.lower(tokens[2]) or ""
		local rawItem = tokens[3]
		local itemId = rawItem and ItemCatalog.resolveQuestItemId(rawItem) or nil
		if action == "give" and itemId then
			local grantFn = missionSignals and missionSignals:FindFirstChild(NetProtocol.Signals.GrantQuestItem)
			if grantFn and grantFn:IsA("BindableFunction") then
				local ok, msg = grantFn:Invoke(itemId, player, true)
				sendFeedback(player, ok, msg)
				return ok, msg
			end
		elseif action == "consume" and itemId then
			local consumeFn = campaignSignals and campaignSignals:FindFirstChild(NetProtocol.Signals.ConsumeQuestItem)
			if consumeFn and consumeFn:IsA("BindableFunction") then
				local ok, msg = consumeFn:Invoke(itemId, player)
				sendFeedback(player, ok, msg)
				return ok, msg
			end
		end
		local msg = "Usage: !key give <mkey|keycard|qcard|fusea|masterkey> | !key consume <item>"
		sendFeedback(player, false, msg)
		return false, msg
	end

	if rootCmd == "!door" then
		local sub = tokens[2] and string.lower(tokens[2]) or "list"
		if sub == "unlock" and tokens[3] then
			local fn = campaignSignals and campaignSignals:FindFirstChild(NetProtocol.Signals.UnlockDoor)
			if fn and fn:IsA("BindableFunction") then
				local ok, msg = fn:Invoke(tokens[3], player)
				sendFeedback(player, ok, msg)
				return ok, msg
			end
		elseif sub == "lock" and tokens[3] then
			local fn = campaignSignals and campaignSignals:FindFirstChild(NetProtocol.Signals.LockDoor)
			if fn and fn:IsA("BindableFunction") then
				local ok, msg = fn:Invoke(tokens[3], player)
				sendFeedback(player, ok, msg)
				return ok, msg
			end
		elseif sub == "list" or sub == "info" then
			local fn = campaignSignals and campaignSignals:FindFirstChild("DevDoorCommand")
			if fn and fn:IsA("BindableFunction") then
				local ok, msg = fn:Invoke(sub, tokens[3], player)
				sendFeedback(player, ok, msg)
				return ok, msg
			end
		end
		local msg = "Usage: !door list | !door info <doorId> | !door unlock <doorId|all> | !door lock <doorId>"
		sendFeedback(player, false, msg)
		return false, msg
	end

	if rootCmd == "!clearance" then
		local arg = tokens[2] and string.lower(tokens[2]) or ""
		local fn = campaignSignals and campaignSignals:FindFirstChild(NetProtocol.Signals.GrantClearance)
		if fn and fn:IsA("BindableFunction") then
			if arg == "reset" or arg == "clear" or arg == "auto" then
				local ok, msg = fn:Invoke(nil, player)
				sendFeedback(player, ok, msg)
				return ok, msg
			end
			local tierNum = tonumber(arg)
			if tierNum ~= nil then
				local ok, msg = fn:Invoke(tierNum, player)
				sendFeedback(player, ok, msg)
				return ok, msg
			end
		end
		local msg = "Usage: !clearance <0..4 | reset>"
		sendFeedback(player, false, msg)
		return false, msg
	end

	if rootCmd == "!boss" then
		local bossId = tokens[2] or "SUBJECT_ZERO"
		local defeatedArg = tokens[3] and string.lower(tokens[3]) or "true"
		local defeated = not (defeatedArg == "false" or defeatedArg == "0" or defeatedArg == "off")
		local fn = campaignSignals and campaignSignals:FindFirstChild(NetProtocol.Signals.SetBossDefeated)
		if fn and fn:IsA("BindableFunction") then
			local ok, msg = fn:Invoke(bossId, defeated, player)
			sendFeedback(player, ok, msg)
			return ok, msg
		end
		sendFeedback(player, false, "SetBossDefeated hook not ready.")
		return false, "Unavailable"
	end

	if rootCmd == "!wave" then
		local arg = tokens[2] and string.lower(tokens[2]) or "on"
		local targetMode = (arg == "off" or arg == "stop" or arg == "campaign" or arg == "0")
			and NetProtocol.ZombieMode.Campaign
			or NetProtocol.ZombieMode.Wave
		local fn = zombieSignals and zombieSignals:FindFirstChild(NetProtocol.Signals.SetZombieMode)
		if fn and fn:IsA("BindableFunction") then
			local ok, msg = fn:Invoke(targetMode, player)
			sendFeedback(player, ok, msg)
			return ok, msg
		end
		sendFeedback(player, false, "ZombieSignals.SetZombieMode not ready.")
		return false, "Unavailable"
	end

	if rootCmd == "!horde" then
		local count = tonumber(tokens[2]) or 5
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local origin = hrp and hrp.Position or Vector3.new(0, 5, 0)
		local fn = zombieSignals and zombieSignals:FindFirstChild(NetProtocol.Signals.TriggerHorde)
		if fn and fn:IsA("BindableFunction") then
			local ok, msg = fn:Invoke(origin, count)
			sendFeedback(player, ok, msg)
			return ok, msg
		end
		sendFeedback(player, false, "ZombieSignals.TriggerHorde not ready.")
		return false, "Unavailable"
	end

	if rootCmd == "!noise" then
		local weight = tonumber(tokens[2]) or 45
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local origin = hrp and hrp.Position or Vector3.new(0, 5, 0)
		local fn = zombieSignals and zombieSignals:FindFirstChild(NetProtocol.Signals.TriggerNoise)
		if fn and fn:IsA("BindableFunction") then
			local ok, msg = fn:Invoke(origin, weight, "DevNoiseCommand")
			sendFeedback(player, ok, msg)
			return ok, msg
		end
		sendFeedback(player, false, "ZombieSignals.TriggerNoise not ready.")
		return false, "Unavailable"
	end

	if rootCmd == "!encounter" then
		local encounterId = tokens[2] or "DEV_ENCOUNTER"
		local count = tonumber(tokens[3]) or 3
		local floorNum = tonumber(tokens[4])
		local fn = zombieSignals and zombieSignals:FindFirstChild(NetProtocol.Signals.TriggerEncounter)
		if fn and fn:IsA("BindableFunction") then
			local ok, msg = fn:Invoke(encounterId, count, floorNum)
			sendFeedback(player, ok, msg)
			return ok, msg
		end
		sendFeedback(player, false, "ZombieSignals.TriggerEncounter not ready.")
		return false, "Unavailable"
	end

	if rootCmd == "!clearzombies" then
		local fn = zombieSignals and zombieSignals:FindFirstChild(NetProtocol.Signals.SetZombiesPaused)
		if fn and fn:IsA("BindableFunction") then
			local ok, msg = fn:Invoke(true, player)
			sendFeedback(player, ok, msg)
			return ok, msg
		end
		sendFeedback(player, false, "ZombieSignals.SetZombiesPaused not ready.")
		return false, "Unavailable"
	end

	if rootCmd == "!zombie" then
		local sub = tokens[2] and string.lower(tokens[2]) or "stats"
		if sub == "off" or sub == "clear" or sub == "pause" or sub == "remove" or sub == "stop" then
			local fn = zombieSignals and zombieSignals:FindFirstChild(NetProtocol.Signals.SetZombiesPaused)
			if fn and fn:IsA("BindableFunction") then
				local ok, msg = fn:Invoke(true, player)
				sendFeedback(player, ok, msg)
				return ok, msg
			end
		elseif sub == "on" or sub == "resume" or sub == "start" then
			local fn = zombieSignals and zombieSignals:FindFirstChild(NetProtocol.Signals.SetZombiesPaused)
			if fn and fn:IsA("BindableFunction") then
				local ok, msg = fn:Invoke(false, player)
				sendFeedback(player, ok, msg)
				return ok, msg
			end
		elseif sub == "reset" then
			local fn = zombieSignals and zombieSignals:FindFirstChild(NetProtocol.Signals.ResetZombies)
			if fn and fn:IsA("BindableFunction") then
				local ok, msg = fn:Invoke(player)
				sendFeedback(player, ok, msg)
				return ok, msg
			end
		elseif sub == "mode" and tokens[3] then
			local mArg = string.lower(tokens[3])
			local modeName = (mArg == "wave") and NetProtocol.ZombieMode.Wave or NetProtocol.ZombieMode.Campaign
			local fn = zombieSignals and zombieSignals:FindFirstChild(NetProtocol.Signals.SetZombieMode)
			if fn and fn:IsA("BindableFunction") then
				local ok, msg = fn:Invoke(modeName, player)
				sendFeedback(player, ok, msg)
				return ok, msg
			end
		elseif sub == "stats" then
			local fn = zombieSignals and zombieSignals:FindFirstChild(NetProtocol.Signals.GetZombieStats)
			if fn and fn:IsA("BindableFunction") then
				local stats = fn:Invoke()
				local msg = string.format("[ZOMBIE DIRECTOR] Mode:%s | Paused:%s | Alive:%d | Ambient:%d | Roam:%d | Noise:%d | Obj:%d | Heat:%d",
					tostring(stats.mode), stats.paused and "YES" or "NO", stats.aliveTotal or 0, stats.aliveAmbient or 0, stats.aliveRoaming or 0, stats.aliveNoise or 0, stats.aliveObjective or 0, stats.noiseHeat or 0)
				sendFeedback(player, true, msg)
				return true, msg
			end
		end
		local msg = "Usage: !zombie off | !zombie on | !zombie reset | !zombie stats | !zombie mode <campaign|wave>"
		sendFeedback(player, false, msg)
		return false, msg
	end

	return false, "Unhandled command"
end

local function bindPlayer(player)
	devAuth.syncPlayer(player)
	player.Chatted:Connect(function(msg)
		if type(msg) == "string" and msg:match("^%s*!") then
			executeDevCommand(player, msg)
		end
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	bindPlayer(p)
end
Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(function(player)
	devAuth.clearPlayer(player)
end)

clientCommandFn.OnServerInvoke = function(player, rawMessage)
	return executeDevCommand(player, rawMessage)
end

print("[DevCommandService] Ready. Default Mode: Campaign. Allowlisted devs run '!dev' to unlock dev commands.")
