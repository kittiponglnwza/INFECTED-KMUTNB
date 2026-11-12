--[[
    WaveAndZombieManager.server.lua
    ใส่ใน: ServerScriptService -> Gameplay
    หน้าที่:
      - ปล่อยฝูงซอมบี้เป็นเวฟ (Wave System) ออกมาไล่ล่าผู้เล่นจริงในอาคาร 40 ปี มจพ. (ทั้งชั้น 1 และชั้น 2)
      - ระบบเลือดซอมบี้แม่นยำ 100% (Attribute-backed HP + RequiresNeck = false + Hit Highlight Flash)
      - Smart Tactical Zombie AI:
          * เช็ก Line-of-Sight (LOS) ด้วย Raycast จริง
          * ทางโล่ง: วิ่งดักหน้า + กระจายตัวล้อมผู้เล่น (Predictive Pursuit + Flanking) + เร่งสปีดเมื่อเข้าใกล้
          * มีกำแพงกั้น/คนละชั้น: เดินตาม Waypoints ต่อเนื่องทีละจุดจนครบ (Persistent Waypoint Follower) ขึ้นลงบันไดได้จริง
          * ระบบแก้ติดมุมอัตโนมัติ (Anti-Stuck Sidestep & Recovery) + แอนิเมชันขาเดินและง้างมือตี
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ProximityPromptService = game:GetService("ProximityPromptService")

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local zombieSharedFolder = ReplicatedStorage:WaitForChild("ZombieModules", 10)
local zombiesServerFolder = ServerScriptService:WaitForChild("Zombies", 10)
local campaignServerFolder = ServerScriptService:WaitForChild("Campaign", 10)
local sharedCampaignFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local NetProtocol = require(sharedCampaignFolder:WaitForChild("NetProtocol"))
local ZombieCatalog = require(zombieSharedFolder:WaitForChild("ZombieCatalog"))
local ZombieModelFactory = require(zombieSharedFolder:WaitForChild("ZombieModelFactory"))
local ZombieAnimationController = require(zombieSharedFolder:WaitForChild("ZombieAnimationController"))
local ZombieAudioController = require(zombieSharedFolder:WaitForChild("ZombieAudioController"))
local ZombieAI = require(zombiesServerFolder:WaitForChild("ZombieAI"))
local DevAuthService = require(campaignServerFolder:WaitForChild("DevAuthService"))
local ZombieDirector = require(campaignServerFolder:WaitForChild("ZombieDirector"))

local devAuth = DevAuthService.getSingleton()

local SPAWN_ZOMBIES = true
local director = nil
local zombieDirectorGeneration = 0

print("=========================================================")
print("🧟 [Smart Zombie Director] Campaign Hybrid Spawn + Isolated Wave Test Mode")
print("=========================================================")

-- โฟลเดอร์รวมซอมบี้ทั้งหมดในฉาก (ใช้กรอง Raycast ไม่ให้ซอมบี้บังกันเอง)
local zombiesFolder = Workspace:FindFirstChild("ActiveZombies") or Instance.new("Folder")
zombiesFolder.Name = "ActiveZombies"
zombiesFolder.Parent = Workspace

-- สร้าง Remote Events สำหรับสื่อสารกับ Client
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
local function clearHordeAfterCampaignWin()
    if Workspace:GetAttribute("CampaignComplete") ~= true then return end
    for _, zombie in ipairs(zombiesFolder:GetChildren()) do
        zombie:Destroy()
    end
    for _, player in ipairs(Players:GetPlayers()) do
        waveAnnounceEvent:FireClient(player, 0, "EXTRACTION COMPLETE // ทีมหนีออกจากอาคารสำเร็จ")
    end
end

Workspace:GetAttributeChangedSignal("CampaignComplete"):Connect(clearHordeAfterCampaignWin)
clearHordeAfterCampaignWin()

local playerDamageEvent = getOrCreateRemote("RemoteEvent", "PlayerDamageEvent")
-- Legacy ZombieHitEvent remains for older scripts, but has no damage handler.
local zombieHitEvent = getOrCreateRemote("RemoteEvent", "ZombieHitEvent")
local weaponCombatEvents = ReplicatedStorage:FindFirstChild("WeaponCombatEvents") or Instance.new("Folder")
weaponCombatEvents.Name = "WeaponCombatEvents"
weaponCombatEvents.Parent = ReplicatedStorage
local weaponFireEvent = weaponCombatEvents:FindFirstChild("FireWeapon") or Instance.new("RemoteEvent")
weaponFireEvent.Name = "FireWeapon"
weaponFireEvent.Parent = weaponCombatEvents
local weaponReloadEvent = weaponCombatEvents:FindFirstChild("ReloadWeapon") or Instance.new("RemoteEvent")
weaponReloadEvent.Name = "ReloadWeapon"
weaponReloadEvent.Parent = weaponCombatEvents
local weaponAmmoSyncEvent = weaponCombatEvents:FindFirstChild("AmmoSync") or Instance.new("RemoteEvent")
weaponAmmoSyncEvent.Name = "AmmoSync"
weaponAmmoSyncEvent.Parent = weaponCombatEvents
local weaponHitFeedbackEvent = weaponCombatEvents:FindFirstChild("HitFeedback") or Instance.new("RemoteEvent")
weaponHitFeedbackEvent.Name = "HitFeedback"
weaponHitFeedbackEvent.Parent = weaponCombatEvents
local equipWeaponEvent = weaponCombatEvents:FindFirstChild("EquipWeapon") or Instance.new("RemoteEvent")
equipWeaponEvent.Name = "EquipWeapon"
equipWeaponEvent.Parent = weaponCombatEvents
local buyWeaponEvent = getOrCreateRemote("RemoteFunction", "BuyWeaponEvent")
local toggleAdminEvent = getOrCreateRemote("RemoteEvent", "ToggleAdminMode")

local pickupEvents = ReplicatedStorage:FindFirstChild("WeaponPickupEvents") or Instance.new("Folder")
pickupEvents.Name = "WeaponPickupEvents"
pickupEvents.Parent = ReplicatedStorage
local weaponGrantedEvent = pickupEvents:FindFirstChild("WeaponGranted") or Instance.new("RemoteEvent")
weaponGrantedEvent.Name = "WeaponGranted"
weaponGrantedEvent.Parent = pickupEvents

local weaponSignalsFolder = ServerStorage:FindFirstChild("WeaponSignals") or Instance.new("Folder")
weaponSignalsFolder.Name = "WeaponSignals"
weaponSignalsFolder.Parent = ServerStorage
local serverGrantWeaponSignal = weaponSignalsFolder:FindFirstChild("GrantWeapon") or Instance.new("BindableEvent")
serverGrantWeaponSignal.Name = "GrantWeapon"
serverGrantWeaponSignal.Parent = weaponSignalsFolder
local serverRefillAmmoSignal = weaponSignalsFolder:FindFirstChild("RefillAmmo") or Instance.new("BindableEvent")
serverRefillAmmoSignal.Name = "RefillAmmo"
serverRefillAmmoSignal.Parent = weaponSignalsFolder
local serverAddPointsSignal = weaponSignalsFolder:FindFirstChild("AddPoints") or Instance.new("BindableEvent")
serverAddPointsSignal.Name = "AddPoints"
serverAddPointsSignal.Parent = weaponSignalsFolder
local zombieKilledLootSignal = weaponSignalsFolder:FindFirstChild("ZombieKilledLoot") or Instance.new("BindableEvent")
zombieKilledLootSignal.Name = "ZombieKilledLoot"
zombieKilledLootSignal.Parent = weaponSignalsFolder

local function isAuthorizedAdmin(player)
    return devAuth.isAuthorizedDeveloper(player)
end

toggleAdminEvent.OnServerEvent:Connect(function(player, enabled)
    if not devAuth.isDevModeEnabled(player) then
        devAuth.syncPlayer(player)
        return
    end

    local ok = devAuth.setGodModeEnabled(player, enabled == true)
    if ok then
        local char = player.Character
        if char and enabled == true then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.MaxHealth = 100
                hum.Health = 100
            end
        end
    end
end)

----------------------------------------------------------------------
-- 1. ฐานข้อมูลผู้เล่น, คะแนน, และระบบ HP ผู้เล่น
----------------------------------------------------------------------
local playerData = {}
local lastDamagedTime = {}
local playerWeaponSlots = {}
local playerSlotStates = {}
local lastWeaponPurchaseAt = {}

local function broadcastScoreboard()
    local scoreList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local data = playerData[p.UserId] or { Points = 500, Kills = 0, Status = "Alive" }
        p:SetAttribute("Points", data.Points)
        p:SetAttribute("Kills", data.Kills)
        table.insert(scoreList, {
            UserId = p.UserId,
            Name = p.DisplayName,
            Points = data.Points,
            Kills = data.Kills,
            Status = data.Status,
        })
    end
    updateScoreboardEvent:FireAllClients(scoreList)
end

local function addPoints(player, amount)
    if not player or not playerData[player.UserId] then return end
    playerData[player.UserId].Points = playerData[player.UserId].Points + amount
    broadcastScoreboard()
end

-- Weapon balance is server-owned. Client never chooses damage, fire rate, pellet count, or ammo.
local WEAPON_BALANCE = {
    Unarmed   = { Mag = 0,  Reserve = 0,   FireRate = 0.65, Pellets = 1, Head = 24,  Body = 15, Legs = 12, Spread = 0.00, ReloadTime = 0, IsMelee = true, MaxRange = 7.2 },
    Classic   = { Mag = 12, Reserve = 120, FireRate = 0.15, Pellets = 1, Head = 78,  Body = 26, Legs = 22, Spread = 0.00, ReloadTime = 2.0 },
    Shorty    = { Mag = 2,  Reserve = 40,  FireRate = 0.30, Pellets = 10, Head = 36, Body = 12, Legs = 10, Spread = 0.08, ReloadTime = 2.0 },
    Frenzy    = { Mag = 13, Reserve = 90,  FireRate = 0.10, Pellets = 1, Head = 78,  Body = 26, Legs = 22, Spread = 0.01, ReloadTime = 2.0 },
    Ghost     = { Mag = 15, Reserve = 90,  FireRate = 0.15, Pellets = 1, Head = 105, Body = 30, Legs = 26, Spread = 0.00, ReloadTime = 2.0 },
    Sheriff   = { Mag = 6,  Reserve = 60,  FireRate = 0.25, Pellets = 1, Head = 159, Body = 55, Legs = 46, Spread = 0.00, ReloadTime = 2.0 },
    Stinger   = { Mag = 20, Reserve = 120, FireRate = 0.062, Pellets = 1, Head = 67,  Body = 27, Legs = 23, Spread = 0.015, ReloadTime = 2.0 },
    Spectre   = { Mag = 30, Reserve = 150, FireRate = 0.075, Pellets = 1, Head = 78,  Body = 26, Legs = 22, Spread = 0.015, ReloadTime = 2.0 },
    Bucky     = { Mag = 8,  Reserve = 60,  FireRate = 0.70, Pellets = 15, Head = 40, Body = 20, Legs = 15, Spread = 0.08, ReloadTime = 2.0 },
    Judge     = { Mag = 7,  Reserve = 60,  FireRate = 0.28, Pellets = 12, Head = 34, Body = 17, Legs = 13, Spread = 0.08, ReloadTime = 2.0 },
    Bulldog   = { Mag = 24, Reserve = 120, FireRate = 0.105, Pellets = 1, Head = 115, Body = 35, Legs = 30, Spread = 0.012, ReloadTime = 2.0 },
    Guardian  = { Mag = 12, Reserve = 90,  FireRate = 0.19, Pellets = 1, Head = 195, Body = 65, Legs = 55, Spread = 0.00, ReloadTime = 2.0 },
    Phantom   = { Mag = 30, Reserve = 150, FireRate = 0.09, Pellets = 1, Head = 156, Body = 39, Legs = 33, Spread = 0.012, ReloadTime = 2.0 },
    Vandal    = { Mag = 25, Reserve = 125, FireRate = 0.103, Pellets = 1, Head = 160, Body = 40, Legs = 34, Spread = 0.00, ReloadTime = 2.0 },
    Marshal   = { Mag = 5,  Reserve = 40,  FireRate = 0.65, Pellets = 1, Head = 202, Body = 101, Legs = 85, Spread = 0.00, ReloadTime = 2.0 },
    Outlaw    = { Mag = 2,  Reserve = 30,  FireRate = 0.40, Pellets = 1, Head = 238, Body = 140, Legs = 120, Spread = 0.00, ReloadTime = 2.0 },
    Operator  = { Mag = 5,  Reserve = 30,  FireRate = 1.25, Pellets = 1, Head = 255, Body = 150, Legs = 120, Spread = 0.00, ReloadTime = 2.0 },
    Ares      = { Mag = 50, Reserve = 150, FireRate = 0.085, Pellets = 1, Head = 72,  Body = 30, Legs = 26, Spread = 0.015, ReloadTime = 2.0 },
    Odin      = { Mag = 100,Reserve = 200, FireRate = 0.07,  Pellets = 1, Head = 95,  Body = 38, Legs = 32, Spread = 0.015, ReloadTime = 2.0 },
}

-- Server-owned purchase costs. The client can request a weapon name, never a price.
local WEAPON_PRICES = {
    Classic = 0, Shorty = 450, Frenzy = 650, Ghost = 500, Sheriff = 800,
    Stinger = 1100, Spectre = 1400, Bucky = 900, Judge = 1600,
    Bulldog = 2100, Guardian = 2300, Phantom = 2600, Vandal = 2600,
    Marshal = 1100, Outlaw = 2400, Operator = 4500, Ares = 3200, Odin = 4000,
}

local SIDEARM_WEAPONS = {
    Classic = true, Shorty = true, Frenzy = true, Ghost = true, Sheriff = true,
}

local weaponStates = {}
local weaponStateConnections = {}

local function weaponSlotFor(weaponName)
    if weaponName == "Unarmed" then
        return 3
    end
    return SIDEARM_WEAPONS[weaponName] and 2 or 1
end

local function syncWeaponAmmo(player)
    local state = weaponStates[player.UserId]
    if state then
        weaponAmmoSyncEvent:FireClient(player, state.weaponName, state.clip, state.reserve, state.reloading)
    end
end

local function createWeaponState(weaponName)
    local stats = WEAPON_BALANCE[weaponName]
    if not stats then return nil end
    return {
        weaponName = weaponName,
        clip = stats.Mag,
        reserve = stats.Reserve,
        reloading = false,
        lastShotAt = 0,
        reloadToken = 0,
    }
end

local function activateWeaponSlotState(player, weaponName)
    if not WEAPON_BALANCE[weaponName] then return false end
    local slotStates = playerSlotStates[player.UserId]
    if not slotStates then
        slotStates = {}
        playerSlotStates[player.UserId] = slotStates
    end

    local prevState = weaponStates[player.UserId]
    if prevState and prevState.reloading then
        prevState.reloading = false
        prevState.reloadToken = prevState.reloadToken + 1
    end

    local slot = weaponSlotFor(weaponName)
    local slotState = slotStates[slot]
    if not slotState or slotState.weaponName ~= weaponName then
        slotState = createWeaponState(weaponName)
        slotStates[slot] = slotState
    end

    weaponStates[player.UserId] = slotState
    syncWeaponAmmo(player)
    return true
end

local function resetWeaponState(player, weaponName)
    local freshState = createWeaponState(weaponName)
    if not freshState then return false end

    local slotStates = playerSlotStates[player.UserId]
    if not slotStates then
        slotStates = {}
        playerSlotStates[player.UserId] = slotStates
    end

    local prevState = weaponStates[player.UserId]
    if prevState and prevState ~= slotStates[weaponSlotFor(weaponName)] and prevState.reloading then
        prevState.reloading = false
        prevState.reloadToken = prevState.reloadToken + 1
    end

    local slot = weaponSlotFor(weaponName)
    slotStates[slot] = freshState
    weaponStates[player.UserId] = freshState
    syncWeaponAmmo(player)
    return true
end

local function bindPlayerWeaponState(player)
    if not weaponStateConnections[player.UserId] then
        weaponStateConnections[player.UserId] = player:GetAttributeChangedSignal("EquippedWeapon"):Connect(function()
            local weaponName = player:GetAttribute("EquippedWeapon")
            local slots = playerWeaponSlots[player.UserId]
            if not WEAPON_BALANCE[weaponName] or not slots or slots[weaponSlotFor(weaponName)] ~= weaponName then
                warn("[WeaponCombat] Rejected unauthorized/unknown equipped weapon for " .. player.Name)
                local fallback = (slots and (slots[3] or slots[2] or slots[1])) or "Unarmed"
                if slots then
                    slots[weaponSlotFor(fallback)] = fallback
                end
                player:SetAttribute("EquippedWeapon", fallback)
                activateWeaponSlotState(player, fallback)
                return
            end
            activateWeaponSlotState(player, weaponName)
        end)
    end

    local currentName = player:GetAttribute("EquippedWeapon")
    local slots = playerWeaponSlots[player.UserId]
    if not WEAPON_BALANCE[currentName] or (slots and slots[weaponSlotFor(currentName)] ~= currentName) then
        currentName = (slots and (slots[3] or slots[2] or slots[1])) or "Unarmed"
        player:SetAttribute("EquippedWeapon", currentName)
    end

    activateWeaponSlotState(player, currentName)
end

local function isPlayerInsideTestRange(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local range = Workspace:FindFirstChild("INFECTED_TestRange")
    local floor = range and range:FindFirstChild("RangeFloor")
    if not root or not floor or not floor:IsA("BasePart") then return false end

    local localPosition = floor.CFrame:PointToObjectSpace(root.Position)
    return math.abs(localPosition.X) <= floor.Size.X / 2
        and math.abs(localPosition.Z) <= floor.Size.Z / 2
        and math.abs(localPosition.Y) <= 18
end

local function grantWeapon(player, weaponName)
    if not WEAPON_BALANCE[weaponName] then return false, "อาวุธนี้ไม่มีในคลัง" end
    local slots = playerWeaponSlots[player.UserId]
    if not slots then return false, "ข้อมูลอาวุธยังไม่พร้อม" end

    slots[weaponSlotFor(weaponName)] = weaponName
    resetWeaponState(player, weaponName)
    player:SetAttribute("LastWeaponPickupAt", os.clock())
    if player:GetAttribute("EquippedWeapon") ~= weaponName then
        player:SetAttribute("EquippedWeapon", weaponName)
    end
    weaponGrantedEvent:FireClient(player, weaponName)
    return true, "ซื้อสำเร็จ!"
end

serverGrantWeaponSignal.Event:Connect(function(player, weaponName)
    if typeof(player) == "Instance" and player:IsA("Player") and player.Parent == Players then
        grantWeapon(player, weaponName)
    end
end)

serverRefillAmmoSignal.Event:Connect(function(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then return end
    local slots = playerWeaponSlots[player.UserId]
    local slotStates = playerSlotStates[player.UserId]
    if not slots or not slotStates then return end
    for _, slotIdx in ipairs({ 1, 2 }) do
        local wName = slots[slotIdx]
        local st = slotStates[slotIdx]
        local bal = wName and WEAPON_BALANCE[wName]
        if wName and st and bal and not bal.IsMelee then
            st.reserve = bal.Reserve
            if st == weaponStates[player.UserId] then
                syncWeaponAmmo(player)
            else
                weaponAmmoSyncEvent:FireClient(player, wName, st.clip, st.reserve, false)
            end
        end
    end
end)

serverAddPointsSignal.Event:Connect(function(player, delta)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then return end
    if type(delta) ~= "number" or not playerData[player.UserId] then return end
    local nextPts = math.max(0, (playerData[player.UserId].Points or 0) + math.floor(delta))
    playerData[player.UserId].Points = nextPts
    broadcastScoreboard()
end)

local function buyWorldWeapon(player, weaponName)
    local data = playerData[player.UserId]
    local cost = WEAPON_PRICES[weaponName]
    local stats = WEAPON_BALANCE[weaponName]
    if not data or not cost or not stats then return false, "จุดซื้ออาวุธไม่ถูกต้อง" end

    local now = os.clock()
    if now - (lastWeaponPurchaseAt[player.UserId] or 0) < 0.75 then
        return false, "รอสักครู่แล้วลองอีกครั้ง"
    end
    lastWeaponPurchaseAt[player.UserId] = now

    local slots = playerWeaponSlots[player.UserId]
    local slotStates = playerSlotStates[player.UserId]
    local slot = weaponSlotFor(weaponName)
    local alreadyOwned = slots and slots[slot] == weaponName
    local currentSlotState = slotStates and slotStates[slot]
    local effectiveCost = cost
    local isAmmoRefill = false

    if alreadyOwned and currentSlotState and currentSlotState.weaponName == weaponName then
        if currentSlotState.clip >= stats.Mag and currentSlotState.reserve >= stats.Reserve then
            waveAnnounceEvent:FireClient(player, 0, string.format("%s กระสุนเต็มอยู่แล้ว", weaponName))
            return false, "กระสุนเต็มอยู่แล้ว!"
        end
        effectiveCost = math.max(100, math.floor(cost * 0.5))
        isAmmoRefill = true
    end

    if data.Points < effectiveCost then
        waveAnnounceEvent:FireClient(player, 0, string.format("แต้มไม่พอสำหรับ %s (%d แต้ม)", weaponName, effectiveCost))
        return false, "แต้มไม่พอ!"
    end

    data.Points = data.Points - effectiveCost
    local granted, message = grantWeapon(player, weaponName)
    if not granted then
        data.Points = data.Points + effectiveCost
        return false, message
    end
    broadcastScoreboard()
    if isAmmoRefill then
        waveAnnounceEvent:FireClient(player, 0, string.format("เติมกระสุน %s เต็ม (-%d แต้ม)", weaponName, effectiveCost))
        return true, "เติมกระสุนเต็ม!"
    end
    waveAnnounceEvent:FireClient(player, 0, string.format("ซื้อ %s สำเร็จ (-%d แต้ม)", weaponName, effectiveCost))
    return true, message
end

-- The B menu is a free server test tool in the Range only when Development Mode is active.
buyWeaponEvent.OnServerInvoke = function(player, weaponName)
    if type(weaponName) ~= "string" or not WEAPON_BALANCE[weaponName] then
        return false, "อาวุธนี้ไม่มีในคลัง"
    end
    if not devAuth.isDevModeEnabled(player) then
        return false, "Development Mode (!dev) required for free TestRange armory"
    end
    if not isPlayerInsideTestRange(player) then
        return false, "ซื้ออาวุธได้ที่จุดซื้อบนแผนที่"
    end
    return grantWeapon(player, weaponName)
end

equipWeaponEvent.OnServerEvent:Connect(function(player, weaponName)
    if type(weaponName) ~= "string" or not WEAPON_BALANCE[weaponName] then return end
    local slots = playerWeaponSlots[player.UserId]
    if not slots or slots[weaponSlotFor(weaponName)] ~= weaponName then
        syncWeaponAmmo(player)
        return
    end
    if player:GetAttribute("EquippedWeapon") == weaponName then
        activateWeaponSlotState(player, weaponName)
    else
        player:SetAttribute("EquippedWeapon", weaponName)
    end
end)

local registeredMapBuyPrompts = {}
local function registerMapBuyPrompt(instance)
    if instance:IsA("ProximityPrompt") and instance:GetAttribute("WorldWeaponBuy") == true then
        registeredMapBuyPrompts[instance] = instance:GetAttribute("WeaponName")
    end
end

for _, instance in ipairs(Workspace:GetDescendants()) do
    registerMapBuyPrompt(instance)
end
Workspace.DescendantAdded:Connect(registerMapBuyPrompt)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if not prompt.Parent then return end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local stationPart = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart", true)
    if not root or not stationPart then return end
    if (root.Position - stationPart.Position).Magnitude > prompt.MaxActivationDistance + 3 then return end
    local mapWeaponName = registeredMapBuyPrompts[prompt]
    if mapWeaponName then
        buyWorldWeapon(player, mapWeaponName)
        return
    end

    -- Range pickups are intentionally free in Dev TestRange only.
    if prompt.Name ~= "PickupPrompt" or not isPlayerInsideTestRange(player) or not devAuth.isDevModeEnabled(player) then return end
    local weaponName = prompt.ObjectText
    if not WEAPON_BALANCE[weaponName] then return end
    local now = os.clock()
    if now - (player:GetAttribute("LastWeaponPickupAt") or 0) < 0.45 then return end
    grantWeapon(player, weaponName)
end)

local function initializePlayerInventory(player)
    playerWeaponSlots[player.UserId] = { [1] = nil, [2] = nil, [3] = "Unarmed" }
    playerSlotStates[player.UserId] = {}
    resetWeaponState(player, "Unarmed")
    player:SetAttribute("EquippedWeapon", "Unarmed")
    devAuth.syncPlayer(player)
end

local function setupPlayerCharacter(player, char)
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end

    bindPlayerWeaponState(player)

    devAuth.syncPlayer(player)
    player:SetAttribute("IsDowned", false)
    player:SetAttribute("BleedoutEndTime", nil)
    char:SetAttribute("IsAdminGodMode", devAuth.isGodModeEnabled(player))
    char:SetAttribute("IsDowned", false)
    char:SetAttribute("BleedoutEndTime", nil)

    hum.MaxHealth = 100
    hum.Health = 100
    if playerData[player.UserId] then
        playerData[player.UserId].Status = "Alive"
        broadcastScoreboard()
    end

    char:GetAttributeChangedSignal("IsDowned"):Connect(function()
        if not playerData[player.UserId] then return end
        if hum.Health <= 0 then
            playerData[player.UserId].Status = "Dead"
        elseif char:GetAttribute("IsDowned") == true then
            playerData[player.UserId].Status = "Downed"
        else
            playerData[player.UserId].Status = "Alive"
        end
        broadcastScoreboard()
    end)

    hum.Died:Connect(function()
        if playerData[player.UserId] then
            playerData[player.UserId].Status = "Dead"
            broadcastScoreboard()
        end
    end)
end

-- ระบบฟื้นฟูเลือดอัตโนมัติเมื่อไม่ได้โดนซอมบี้ตีนานเกิน 6 วินาที
task.spawn(function()
    while Workspace:GetAttribute("CampaignComplete") ~= true do
        local now = os.clock()
        for _, p in ipairs(Players:GetPlayers()) do
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and hum.Health < hum.MaxHealth
                and char:GetAttribute("IsDowned") ~= true and p:GetAttribute("IsDowned") ~= true
                and (p:GetAttribute("Hunger") or 100) > 15 then
                local lastHit = lastDamagedTime[p.UserId] or 0
                if now - lastHit >= 6.0 then
                    hum.Health = math.min(hum.MaxHealth, hum.Health + 4)
                end
            end
        end
        task.wait(0.5)
    end
end)

----------------------------------------------------------------------
-- 2. แถบเลือดลอยบนหัวซอมบี้ (BILLBOARD HEALTH BAR - ซิงค์ Attribute 100%)
----------------------------------------------------------------------
local function attachHealthBillboard(zombie, baseHealth, zType, archetype)
    local head = zombie:FindFirstChild("Head") or zombie.PrimaryPart
    if not head then return end

    archetype = archetype or ZombieCatalog.get(zType)
    local isBoss = archetype.IsBoss == true
    local isFemale = archetype.Gender == "Female"

    local bb = Instance.new("BillboardGui")
    bb.Name = "HealthBillboard"
    bb.Size = UDim2.new(0, isBoss and 190 or 150, 0, 42)
    bb.StudsOffset = Vector3.new(0, isBoss and 3.4 or 2.2, 0)
    bb.AlwaysOnTop = false
    bb.MaxDistance = isBoss and 100 or 70
    bb.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = isBoss and Color3.fromRGB(255, 72, 72)
        or (archetype.Role == "Runner" and Color3.fromRGB(255, 175, 58)
        or (isFemale and Color3.fromRGB(232, 195, 255) or Color3.fromRGB(220, 235, 130)))
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = isBoss and 13 or 11
    nameLabel.Text = isBoss and ("👑 " .. archetype.DisplayName) or ("🧟 " .. archetype.DisplayName)
    nameLabel.Parent = bb

    local barBg = Instance.new("Frame")
    barBg.Name = "BarBg"
    barBg.Size = UDim2.new(1, 0, 0, 11)
    barBg.Position = UDim2.new(0, 0, 0, 18)
    barBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    barBg.BorderSizePixel = 0
    barBg.Parent = bb
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

    local barFill = Instance.new("Frame")
    barFill.Name = "Fill"
    barFill.Size = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(60, 220, 90)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)

    local hpText = Instance.new("TextLabel")
    hpText.Name = "HPText"
    hpText.Size = UDim2.new(1, 0, 1, 0)
    hpText.BackgroundTransparency = 1
    hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
    hpText.TextStrokeTransparency = 0.25
    hpText.Font = Enum.Font.GothamBold
    hpText.TextSize = 10
    hpText.Text = string.format("%d / %d", baseHealth, baseHealth)
    hpText.Parent = barBg

    local function refreshBar(currentHP)
        local pct = math.clamp(currentHP / baseHealth, 0, 1)
        barFill.Size = UDim2.new(pct, 0, 1, 0)
        if pct > 0.5 then
            barFill.BackgroundColor3 = Color3.fromRGB(60, 220, 90)
        elseif pct > 0.25 then
            barFill.BackgroundColor3 = Color3.fromRGB(255, 180, 40)
        else
            barFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        end
        hpText.Text = string.format("%d / %d", math.max(0, math.floor(currentHP + 0.5)), baseHealth)
    end

    zombie:GetAttributeChangedSignal("CurrentHP"):Connect(function()
        local hp = zombie:GetAttribute("CurrentHP")
        if type(hp) == "number" then
            refreshBar(hp)
        end
    end)

    local hum = zombie:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.HealthChanged:Connect(function(health)
            local attrHP = zombie:GetAttribute("CurrentHP")
            refreshBar(type(attrHP) == "number" and attrHP or health)
        end)
    end
end

----------------------------------------------------------------------
-- 3. จุดเกิดซอมบี้ทั้งชั้น 1 และชั้น 2 (เลือกตามชั้นที่ผู้เล่นยืนอยู่)
----------------------------------------------------------------------
local FLOOR1_SPAWNS = {
    Vector3.new( 125, 5, -20), -- ทางเข้ารถฝั่งขวา
    Vector3.new( 125, 5,  20),
    Vector3.new(-115, 5,   0), -- ลานจอดรถฝั่งซ้าย
    Vector3.new(   0, 5, 108), -- โถงทางเข้าหน้าตึกชั้น 1
    Vector3.new(   0, 5,-108), -- โถงทางเข้าหลังตึกชั้น 1
    Vector3.new( -55, 5,   0),
    Vector3.new(  55, 5,   0),
}

local FLOOR2_SPAWNS = {
    Vector3.new(   0, 27, 142), -- ชานพักบันไดใหญ่หน้าโรงอาหารชั้น 2
    Vector3.new(   0, 27, 102), -- โถงทางเข้าหน้าชั้น 2
    Vector3.new(   0, 27,-102), -- โถงทางเข้าหลังชั้น 2
    Vector3.new( -98, 27, -45), -- ทางเดินหน้าร้านข้าวซ้ายบน
    Vector3.new(  98, 27, -45), -- ทางเดินหน้าร้านข้าวขวาบน
    Vector3.new( -98, 27,  45), -- ทางเดินหน้าร้านข้าวซ้ายล่าง
    Vector3.new(  98, 27,  45), -- ทางเดินหน้าร้านข้าวขวาล่าง
}

local FLOOR3_SPAWNS = {
    Vector3.new(   0, 49,  92), -- โถงหน้าบันได/ลิฟต์ทิศใต้ ชั้น 3
    Vector3.new(   0, 49, -92), -- โถงหน้าบันได/ลิฟต์ทิศเหนือ ชั้น 3
    Vector3.new( -73, 49, -60), -- สนามฟุตซอลฝั่งเหนือ
    Vector3.new( -73, 49,  60), -- สนามฟุตซอลฝั่งใต้
    Vector3.new(  73, 49, -60), -- สนามบาสฝั่งเหนือ
    Vector3.new(  73, 49,  60), -- สนามบาสฝั่งใต้
    Vector3.new(   0, 49,   0), -- โถงทางเดินกลางชั้น 3
}

local function makeUpperFloorSpawns(spawnY)
    return {
        Vector3.new(   0, spawnY,  92), -- โถงหน้าบันได/ลิฟต์ทิศใต้
        Vector3.new(   0, spawnY, -92), -- โถงหน้าบันได/ลิฟต์ทิศเหนือ
        Vector3.new(   0, spawnY, -38), -- โถงกลางค่อนเหนือ
        Vector3.new(   0, spawnY,  38), -- โถงกลางค่อนใต้
        Vector3.new(-110, spawnY, -40), -- ทางเดินปีกซ้ายข้างรูสนามฟุตซอล
        Vector3.new(-110, spawnY,  40),
        Vector3.new( 110, spawnY, -40), -- ทางเดินปีกขวาข้างรูสนามบาส
        Vector3.new( 110, spawnY,  40),
    }
end

local FLOOR4_SPAWNS = makeUpperFloorSpawns(71)
local FLOOR5_SPAWNS = makeUpperFloorSpawns(93)
local FLOOR6_SPAWNS = makeUpperFloorSpawns(115)
local FLOOR7_SPAWNS = {
    Vector3.new(   0, 137,  92), -- โถงหน้าบันได/ลิฟต์ทิศใต้ ชั้น 7
    Vector3.new(   0, 137, -92), -- โถงหน้าบันได/ลิฟต์ทิศเหนือ ชั้น 7
    Vector3.new( -74, 137, -55), -- สนามวอลเลย์บอลฝั่งเหนือ
    Vector3.new( -74, 137,  55), -- สนามวอลเลย์บอลฝั่งใต้
    Vector3.new(  78, 137, -78), -- ทางเดินหน้าสนามแบดมินตันฝั่งเหนือ
    Vector3.new(  78, 137,  78), -- ทางเดินหน้าสนามแบดมินตันฝั่งใต้
    Vector3.new(   0, 137,   0), -- โถงทางเดินกลางชั้น 7
}
local FLOOR8_SPAWNS  = makeUpperFloorSpawns(159)
local FLOOR9_SPAWNS  = makeUpperFloorSpawns(181)
local FLOOR10_SPAWNS = makeUpperFloorSpawns(203)
-- Keep floor 11 spawns in the stair/elevator cores. The center entrance and
-- wing corridors are sealed with black glass, so spawning there can soft-lock a wave.
local FLOOR11_SPAWNS = {
    Vector3.new(-49, 225,  103),
    Vector3.new( 49, 225,  103),
    Vector3.new(-49, 225, -103),
    Vector3.new( 49, 225, -103),
}
local FLOOR12_SPAWNS = {
    Vector3.new(   0, 247,  78), -- โถงหน้าบันไดทิศใต้ ชั้น 12
    Vector3.new(   0, 247, -78), -- โถงหน้าบันไดทิศเหนือ ชั้น 12
    Vector3.new(-108, 247, -36), -- สนามเซปักตะกร้อ 1
    Vector3.new(-108, 247,  36), -- สนามเซปักตะกร้อ 2
    Vector3.new( -24, 247,   0), -- สนามเทนนิสกลาง
    Vector3.new(  82, 247, -45), -- สนามฟุตซอลชั้น 12 ฝั่งเหนือ
    Vector3.new(  82, 247,  45), -- สนามฟุตซอลชั้น 12 ฝั่งใต้
}

local function pickSpawnPosition(preferFloor)
    local targetFloor = preferFloor
    if targetFloor == nil then
        targetFloor = 1
        for _, p in ipairs(Players:GetPlayers()) do
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local py = hrp.Position.Y
                if py >= 234 then
                    targetFloor = 12
                    break
                elseif py >= 212 then
                    targetFloor = math.max(targetFloor, 11)
                elseif py >= 190 then
                    targetFloor = math.max(targetFloor, 10)
                elseif py >= 168 then
                    targetFloor = math.max(targetFloor, 9)
                elseif py >= 146 then
                    targetFloor = math.max(targetFloor, 8)
                elseif py >= 124 then
                    targetFloor = math.max(targetFloor, 7)
                elseif py >= 102 then
                    targetFloor = math.max(targetFloor, 6)
                elseif py >= 80 then
                    targetFloor = math.max(targetFloor, 5)
                elseif py >= 58 then
                    targetFloor = math.max(targetFloor, 4)
                elseif py >= 38 then
                    targetFloor = math.max(targetFloor, 3)
                elseif py >= 15 then
                    targetFloor = math.max(targetFloor, 2)
                end
            end
        end
    elseif type(targetFloor) == "boolean" then
        targetFloor = targetFloor and 2 or 1
    end

    local pool = (targetFloor == 12 and FLOOR12_SPAWNS)
        or (targetFloor == 11 and FLOOR11_SPAWNS)
        or (targetFloor == 10 and FLOOR10_SPAWNS)
        or (targetFloor == 9 and FLOOR9_SPAWNS)
        or (targetFloor == 8 and FLOOR8_SPAWNS)
        or (targetFloor == 7 and FLOOR7_SPAWNS)
        or (targetFloor == 6 and FLOOR6_SPAWNS)
        or (targetFloor == 5 and FLOOR5_SPAWNS)
        or (targetFloor == 4 and FLOOR4_SPAWNS)
        or (targetFloor == 3 and FLOOR3_SPAWNS)
        or (targetFloor == 2 and FLOOR2_SPAWNS)
        or FLOOR1_SPAWNS
    local base = pool[math.random(1, #pool)]
    return base + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
end

----------------------------------------------------------------------
-- 4. สร้างโมเดลซอมบี้ (R15 Male/Female/Boss + 8-State Animator + 3D Audio + AI)
----------------------------------------------------------------------
local zombieControllers = {}
local handleGunshotNoise = nil

local function getFloorFromY(py)
    if py >= 234 then return 12
    elseif py >= 212 then return 11
    elseif py >= 190 then return 10
    elseif py >= 168 then return 9
    elseif py >= 146 then return 8
    elseif py >= 124 then return 7
    elseif py >= 102 then return 6
    elseif py >= 80 then return 5
    elseif py >= 58 then return 4
    elseif py >= 38 then return 3
    elseif py >= 15 then return 2
    else return 1 end
end

local function getFloorSpawnPool(floorNum)
    return (floorNum == 12 and FLOOR12_SPAWNS)
        or (floorNum == 11 and FLOOR11_SPAWNS)
        or (floorNum == 10 and FLOOR10_SPAWNS)
        or (floorNum == 9 and FLOOR9_SPAWNS)
        or (floorNum == 8 and FLOOR8_SPAWNS)
        or (floorNum == 7 and FLOOR7_SPAWNS)
        or (floorNum == 6 and FLOOR6_SPAWNS)
        or (floorNum == 5 and FLOOR5_SPAWNS)
        or (floorNum == 4 and FLOOR4_SPAWNS)
        or (floorNum == 3 and FLOOR3_SPAWNS)
        or (floorNum == 2 and FLOOR2_SPAWNS)
        or FLOOR1_SPAWNS
end

local function createZombieModel(zombieType, spawnPos, isStationary, directorMeta)
    local archetype = ZombieCatalog.get(zombieType)
    local baseHealth = archetype.MaxHealth
    local baseSpeed = archetype.WalkSpeed

    local rig = ZombieModelFactory.build({
        zombieType = archetype.Id,
        spawnPos = spawnPos,
        anchored = isStationary and true or false,
        canCollideMain = true,
        modelName = "Zombie_" .. archetype.Id,
    })

    local zombie = rig.model
    local hrp = rig.hrp
    local humanoid = rig.humanoid

    zombie:SetAttribute("IsZombie", true)
    zombie:SetAttribute("ZombieType", archetype.Id)
    zombie:SetAttribute("ZombieCategory", archetype.Category)
    zombie:SetAttribute("ZombieGender", archetype.Gender)
    zombie:SetAttribute("IsBoss", archetype.IsBoss)
    zombie:SetAttribute("MaxHealth", baseHealth)
    zombie:SetAttribute("CurrentHP", baseHealth)
    zombie:SetAttribute("IsDead", false)
    zombie:SetAttribute("IsChasing", false)
    zombie:SetAttribute("StaggerAccum", 0)
    zombie:SetAttribute("StunnedUntil", 0)
    zombie:SetAttribute("SpawnPos", spawnPos)
    zombie:SetAttribute("IsStationary", isStationary or false)

    humanoid.MaxHealth = baseHealth
    humanoid.Health = baseHealth
    humanoid.WalkSpeed = isStationary and 0 or baseSpeed
    humanoid.JumpPower = 50
    humanoid.AutoRotate = true

    zombie.Parent = zombiesFolder

    -- Re-apply health bounds after parenting to guarantee initial state sync
    humanoid.MaxHealth = baseHealth
    humanoid.Health = baseHealth

    if not isStationary then
        pcall(function()
            hrp:SetNetworkOwner(nil)
        end)
    end

    attachHealthBillboard(zombie, baseHealth, archetype.Id, archetype)

    if isStationary then
        return zombie
    end

    local animCtrl = ZombieAnimationController.new(rig, archetype)
    local audioCtrl = ZombieAudioController.new(rig, archetype)
    local directorId = nil
    if director then
        local meta = directorMeta or {}
        zombie:SetAttribute("SpawnChannel", meta.channel or "Campaign")
        zombie:SetAttribute("SpawnMode", meta.mode or director.getMode())
        directorId = director.registerSpawned(nil, {
            channel = meta.channel or "Ambient",
            zombieType = archetype.Id,
            mode = meta.mode or director.getMode(),
            floor = meta.floor or 1,
            encounterId = meta.encounterId,
            bossId = meta.bossId,
        })
    end

    zombieControllers[zombie] = {
        animCtrl = animCtrl,
        audioCtrl = audioCtrl,
        archetype = archetype,
        directorId = directorId,
    }

    local unregistered = false
    local function cleanupDirectorEntry(wasKilled)
        if not unregistered and directorId and director then
            unregistered = true
            director.unregisterZombie(directorId, wasKilled == true)
        end
    end

    humanoid.Died:Connect(function()
        cleanupDirectorEntry(true)
    end)

    zombie:GetAttributeChangedSignal("IsDead"):Connect(function()
        if zombie:GetAttribute("IsDead") == true then
            cleanupDirectorEntry(true)
        end
    end)

    zombie.AncestryChanged:Connect(function(_, parent)
        if not parent then
            cleanupDirectorEntry(zombie:GetAttribute("IsDead") == true)
            local ctrl = zombieControllers[zombie]
            if ctrl then
                ctrl.audioCtrl:destroy()
                ctrl.animCtrl:destroy()
                zombieControllers[zombie] = nil
            end
        end
    end)

    ZombieAI.start(rig, archetype, animCtrl, audioCtrl, {
        zombiesFolder = zombiesFolder,
        playerDamageEvent = playerDamageEvent,
        onPlayerDamaged = function(damagedPlayer, timestamp)
            lastDamagedTime[damagedPlayer.UserId] = timestamp
        end,
        pickSpawnPosition = pickSpawnPosition,
    })

    return zombie
end

----------------------------------------------------------------------
-- 5. ตรวจจับการยิงถูกซอมบี้ (ZOMBIE HIT EVENT - เลือดลดจริง 100%)
----------------------------------------------------------------------
local function findZombieFromPart(part)
    local cur = part
    while cur and cur ~= Workspace do
        if cur:IsA("Model") and (cur:GetAttribute("IsZombie") or cur.Name:sub(1, 7) == "Zombie_" or cur.Name:sub(1, 8) == "Preview_") then
            return cur
        end
        cur = cur.Parent
    end
    return nil
end

-- Apply damage using server-owned weapon stats only.
local function applyWeaponDamage(player, hitPart, stats)
    local zombie = findZombieFromPart(hitPart)
    if not zombie or zombie:GetAttribute("IsDead") then return end

    local hum = zombie:FindFirstChildOfClass("Humanoid")
    local maxHP = zombie:GetAttribute("MaxHealth") or (hum and hum.MaxHealth) or 120
    local curHP = zombie:GetAttribute("CurrentHP")
    if type(curHP) ~= "number" then
        curHP = (hum and hum.Health > 0) and hum.Health or maxHP
    end
    if curHP <= 0 then return end

    local hitZone = hitPart:GetAttribute("HitZone")
    local isHeadshot = (hitZone == "Head") or (hitPart.Name == "Head" or hitPart.Name == "Eyes")
    local isLegHit = (hitZone == "Legs") or (hitPart.Name == "LeftLeg" or hitPart.Name == "RightLeg")
    local actualDmg = isHeadshot and stats.Head or (isLegHit and stats.Legs or stats.Body)
    local newHP = math.max(0, curHP - actualDmg)
    local isPreview = zombie:GetAttribute("IsPreviewDummy") == true

    local now = os.clock()
    zombie:SetAttribute("CurrentHP", newHP)
    zombie:SetAttribute("AggroTargetUserId", player.UserId)
    zombie:SetAttribute("EnragedUntil", now + 1.8)
    zombie:SetAttribute("LastHitTime", now)
    zombie:SetAttribute("LastHitHeadshot", isHeadshot)

    local ctrl = zombieControllers[zombie]
    local arch = (ctrl and ctrl.archetype) or ZombieCatalog.get(zombie:GetAttribute("ZombieType"))
    if ctrl and newHP > 0 then
        local stagger = (zombie:GetAttribute("StaggerAccum") or 0) + actualDmg
        if isHeadshot and stagger >= (arch.StunThreshold or 50) then
            zombie:SetAttribute("StaggerAccum", 0)
            local stunDur = arch.StunDuration or 0.70
            zombie:SetAttribute("StunnedUntil", now + stunDur)
            ctrl.animCtrl:setState("Stunned", stunDur)
        else
            zombie:SetAttribute("StaggerAccum", stagger)
            ctrl.animCtrl:setState("TakingDamage", 0.24, { isHeadshot = isHeadshot })
        end
        ctrl.audioCtrl:triggerEvent("TakingDamage")
    end

    if hum then
        hum.Health = math.max(1, newHP)
    end

    local hitHighlight = zombie:FindFirstChild("HitFlashHighlight")
    if not hitHighlight then
        hitHighlight = Instance.new("Highlight")
        hitHighlight.Name = "HitFlashHighlight"
        hitHighlight.FillColor = isHeadshot and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(255, 120, 60)
        hitHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        hitHighlight.FillTransparency = 0.35
        hitHighlight.OutlineTransparency = 0.2
        hitHighlight.Parent = zombie
        task.delay(0.1, function()
            if hitHighlight and hitHighlight.Parent then
                hitHighlight:Destroy()
            end
        end)
    end

    -- Preview mannequins are test targets, not real wave kills or score farming.
    if not isPreview then
        addPoints(player, isHeadshot and 25 or 10)
    end

    if newHP <= 0 then
        zombie:SetAttribute("IsDead", true)
        zombie:SetAttribute("DeathTime", now)
        if ctrl then
            ctrl.animCtrl:setState("Death", nil, { deathTime = now })
            ctrl.audioCtrl:triggerEvent("Death")
        end

        if isPreview then
            for _, part in ipairs(zombie:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanQuery = false
                    part.Transparency = math.max(part.Transparency, 0.45)
                end
            end
            task.delay(3, function()
                if not zombie.Parent then return end
                zombie:SetAttribute("CurrentHP", maxHP)
                zombie:SetAttribute("IsDead", false)
                for _, part in ipairs(zombie:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanQuery = (part.Name ~= "HumanoidRootPart")
                        local baseT = part:GetAttribute("BaseTransparency")
                        if type(baseT) == "number" then
                            part.Transparency = baseT
                        elseif part.Name ~= "Eyes" then
                            part.Transparency = 0
                        end
                    end
                end
            end)
            return actualDmg, isHeadshot
        end

        if playerData[player.UserId] then
            playerData[player.UserId].Kills = playerData[player.UserId].Kills + 1
        end
        local killPts = isHeadshot and (arch.PointRewardHeadshotKill or 100) or (arch.PointRewardKill or 50)
        addPoints(player, killPts)

        local root = zombie:FindFirstChild("HumanoidRootPart")
        if root then
            zombieKilledLootSignal:Fire(root.Position, zombie:GetAttribute("ZombieType") or arch.Name)
        end

        local head = zombie:FindFirstChild("Head")
        if head and head:FindFirstChild("HealthBillboard") then
            head.HealthBillboard:Destroy()
        end

        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                hum.Health = 0
            end)
        end

        for _, part in ipairs(zombie:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanQuery = false
                part.Anchored = false
            end
        end
        Debris:AddItem(zombie, 1.4)
    end

    return actualDmg, isHeadshot
end

local function getServerRaycastFilter(character)
    local exclude = { character }
    local f3 = Workspace:FindFirstChild("Floor_3_SportsArena")
    local cage = f3 and f3:FindFirstChild("FutsalSteelMeshCage")
    local passCol = cage and cage:FindFirstChild("BulletPassColliders")
    if passCol then
        table.insert(exclude, passCol)
    end
    for _, z in ipairs(zombiesFolder:GetChildren()) do
        if z:GetAttribute("IsDead") then
            table.insert(exclude, z)
        end
    end
    return exclude
end

-- The client sends only its camera ray. Server validates origin, owns ammo/cadence,
-- performs its own raycasts, and derives damage from the equipped weapon whitelist.
weaponFireEvent.OnServerEvent:Connect(function(player, requestedWeaponName, clientOrigin, clientDirection)
    local equippedName = player:GetAttribute("EquippedWeapon") or "Unarmed"
    if type(requestedWeaponName) ~= "string" or requestedWeaponName ~= equippedName then
        syncWeaponAmmo(player)
        return
    end
    if typeof(clientOrigin) ~= "Vector3" or typeof(clientDirection) ~= "Vector3" then return end
    if clientDirection.Magnitude < 0.9 or clientDirection.Magnitude > 1.1 then return end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local head = character and character:FindFirstChild("Head")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not head or not root then return end
    if (clientOrigin - head.Position).Magnitude > 8 then return end

    local direction = clientDirection.Unit
    if root.CFrame.LookVector:Dot(direction) < -0.35 then return end

    local weaponName = equippedName
    local stats = WEAPON_BALANCE[weaponName]
    if not stats then return end

    local state = weaponStates[player.UserId]
    if not state or state.weaponName ~= weaponName then
        activateWeaponSlotState(player, weaponName)
        state = weaponStates[player.UserId]
    end
    if not state then return end

    local now = os.clock()
    if state.reloading or now - state.lastShotAt < stats.FireRate * 0.85 then
        syncWeaponAmmo(player)
        return
    end

    if stats.IsMelee then
        state.lastShotAt = now
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = getServerRaycastFilter(character)
        rayParams.IgnoreWater = true

        local meleeRange = stats.MaxRange or 7.2
        local hit = Workspace:Raycast(clientOrigin, direction * meleeRange, rayParams)
        if hit and hit.Instance then
            local target = findZombieFromPart(hit.Instance)
            if target and not target:GetAttribute("IsDead") then
                local appliedDamage, isHeadshot = applyWeaponDamage(player, hit.Instance, stats)
                if appliedDamage then
                    if not target:GetAttribute("IsBoss") then
                        local prevStun = target:GetAttribute("StunnedUntil") or 0
                        target:SetAttribute("StunnedUntil", math.max(prevStun, now + 0.50))
                    end
                    weaponHitFeedbackEvent:FireClient(player, hit.Position, appliedDamage, isHeadshot)
                end
            end
        end
        return
    end

    if state.clip <= 0 then
        syncWeaponAmmo(player)
        return
    end

    state.lastShotAt = now
    state.clip = state.clip - 1
    syncWeaponAmmo(player)

    if handleGunshotNoise and not stats.IsMelee then
        task.spawn(handleGunshotNoise, player, clientOrigin, weaponName)
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = getServerRaycastFilter(character)
    rayParams.IgnoreWater = true

    local pellets = math.clamp(stats.Pellets or 1, 1, 20)
    local maxRange = 500
    local hitCount = 0
    for _ = 1, pellets do
        local spread = Vector3.zero
        if pellets > 1 or stats.Spread > 0 then
            spread = Vector3.new(
                (math.random() - 0.5) * (stats.Spread or 0),
                (math.random() - 0.5) * (stats.Spread or 0),
                (math.random() - 0.5) * (stats.Spread or 0)
            )
        end
        local shotDirection = (direction + spread).Unit * maxRange
        local hit = Workspace:Raycast(clientOrigin, shotDirection, rayParams)
        if hit and hit.Instance then
            local target = findZombieFromPart(hit.Instance)
            if target and not target:GetAttribute("IsDead") then
                local appliedDamage, isHeadshot = applyWeaponDamage(player, hit.Instance, stats)
                if appliedDamage then
                    weaponHitFeedbackEvent:FireClient(player, hit.Position, appliedDamage, isHeadshot)
                    hitCount = hitCount + 1
                end
            end
        end
    end

    if hitCount > 0 then
        print(string.format("[WeaponCombat] %s fired %s and hit %d zombie part(s)", player.Name, weaponName, hitCount))
    end
end)

weaponReloadEvent.OnServerEvent:Connect(function(player, requestedWeaponName)
    local weaponName = player:GetAttribute("EquippedWeapon") or "Unarmed"
    if type(requestedWeaponName) ~= "string" or requestedWeaponName ~= weaponName then
        syncWeaponAmmo(player)
        return
    end
    local stats = WEAPON_BALANCE[weaponName]
    local state = weaponStates[player.UserId]
    if not stats or stats.IsMelee or not state or state.weaponName ~= weaponName then return end

    if state.reloading or state.clip >= stats.Mag or state.reserve <= 0 then
        syncWeaponAmmo(player)
        return
    end

    state.reloading = true
    state.reloadToken = state.reloadToken + 1
    local token = state.reloadToken
    syncWeaponAmmo(player)

    task.delay(stats.ReloadTime or 2, function()
        if not player.Parent or weaponStates[player.UserId] ~= state then return end
        if state.reloadToken ~= token or player:GetAttribute("EquippedWeapon") ~= weaponName then return end

        local needed = stats.Mag - state.clip
        local loaded = math.min(needed, state.reserve)
        state.clip = state.clip + loaded
        state.reserve = state.reserve - loaded
        state.reloading = false
        syncWeaponAmmo(player)
    end)
end)

local ZOMBIE_ALIASES = {
    malewalker = "MaleWalker",
    walker = "MaleWalker",
    zombie = "MaleWalker",
    malerunner = "MaleRunner",
    runner = "MaleRunner",
    femalewalker = "FemaleWalker",
    femalerunner = "FemaleRunner",
    maleboss = "MaleBoss",
    boss = "MaleBoss",
    heavy = "MaleBoss",
    heavyzombie = "MaleBoss",
}

local devSignalsFolder = ServerStorage:FindFirstChild("DevSignals") or Instance.new("Folder")
devSignalsFolder.Name = "DevSignals"
devSignalsFolder.Parent = ServerStorage
local spawnZombieBindable = devSignalsFolder:FindFirstChild("SpawnZombie") or Instance.new("BindableFunction")
spawnZombieBindable.Name = "SpawnZombie"
spawnZombieBindable.Parent = devSignalsFolder
spawnZombieBindable.OnInvoke = function(rawZombieType, spawnPos)
    if typeof(spawnPos) ~= "Vector3" then
        return false, "Invalid spawn position"
    end
    local key = type(rawZombieType) == "string" and string.lower((rawZombieType:gsub("[%s_%-]", ""))) or "walker"
    local canonicalType = ZOMBIE_ALIASES[key]
    if not canonicalType and type(rawZombieType) == "string" and ZombieCatalog.ARCHETYPES[rawZombieType] then
        canonicalType = rawZombieType
    end
    if not canonicalType then
        return false, string.format("Unknown zombie '%s'. Valid: MaleWalker, MaleRunner, FemaleWalker, FemaleRunner, MaleBoss", tostring(rawZombieType))
    end
    local zModel = createZombieModel(canonicalType, spawnPos, false, {
        channel = "Dev",
        mode = director and director.getMode() or NetProtocol.ZombieMode.Campaign,
        floor = getFloorFromY(spawnPos.Y),
    })
    return zModel ~= nil, canonicalType
end

-- ZombieHitEvent is intentionally not connected: all damage must pass through
-- FireWeapon so the server owns weapon, ammo, fire cadence, raycast, and damage.

----------------------------------------------------------------------
-- 6. DUAL-MODE ZOMBIE DIRECTOR (CAMPAIGN MODE vs WAVE / TEST MODE)
----------------------------------------------------------------------
local function hasWorldLineOfSight(eyePos, spawnPos)
    if typeof(eyePos) ~= "Vector3" or typeof(spawnPos) ~= "Vector3" then
        return false
    end
    local targetHead = spawnPos + Vector3.new(0, 4.5, 0)
    local delta = targetHead - eyePos
    if delta.Magnitude < 1 then
        return true
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = { zombiesFolder }
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            table.insert(exclude, p.Character)
        end
    end
    params.FilterDescendantsInstances = exclude
    params.IgnoreWater = true
    local hit = Workspace:Raycast(eyePos, delta, params)
    -- If nothing static blocked the ray before targetHead, player has clear LOS
    return hit == nil
end

director = ZombieDirector.create({
    hasLineOfSightFn = hasWorldLineOfSight,
    maxAliveCampaign = 16,
    maxAliveWave = 28,
})
Workspace:SetAttribute(NetProtocol.Attributes.ZombieMode, NetProtocol.ZombieMode.Campaign)

local function getPlayerViews()
    local views = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and hrp and math.abs(hrp.Position.X) <= 220 and math.abs(hrp.Position.Z) <= 220 then
            local head = char:FindFirstChild("Head")
            local eyePos = head and head.Position or (hrp.Position + Vector3.new(0, 1.5, 0))
            local lookVec = head and head.CFrame.LookVector or hrp.CFrame.LookVector
            table.insert(views, {
                player = p,
                pos = hrp.Position,
                eyePos = eyePos,
                lookVector = lookVec,
                floor = getFloorFromY(hrp.Position.Y),
            })
        end
    end
    return views
end

local function getExistingZombiePositions()
    local positions = {}
    for _, z in ipairs(zombiesFolder:GetChildren()) do
        if z:IsA("Model") and not z:GetAttribute("IsDead") then
            local hrp = z:FindFirstChild("HumanoidRootPart")
            if hrp then
                table.insert(positions, hrp.Position)
            end
        end
    end
    return positions
end

local function pickCampaignSpawnPos(preferFloor, opts)
    opts = opts or {}
    local views = getPlayerViews()
    local targetFloors = {}
    if type(preferFloor) == "number" then
        table.insert(targetFloors, math.clamp(preferFloor, 1, 12))
    else
        local seen = {}
        for _, v in ipairs(views) do
            if not seen[v.floor] then
                seen[v.floor] = true
                table.insert(targetFloors, v.floor)
            end
        end
        if #targetFloors == 0 then
            table.insert(targetFloors, 1)
        end
    end

    local candidates = {}
    for _, fNum in ipairs(targetFloors) do
        for _, pt in ipairs(getFloorSpawnPool(fNum)) do
            table.insert(candidates, { pos = pt, floor = fNum })
            table.insert(candidates, { pos = pt + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4)), floor = fNum })
        end
    end

    local existing = getExistingZombiePositions()
    local chosen = director.selectBestSpawnPoint(candidates, views, existing, {
        requireOutOfSight = (opts.allowVisible ~= true),
        minPlayerDist = opts.minPlayerDist,
        maxPlayerDist = opts.maxPlayerDist,
    })
    if chosen then
        return chosen.pos, chosen.floor
    end
    if opts.allowVisibleFallback then
        local fallbackFloor = targetFloors[1] or 1
        local fallback = director.selectBestSpawnPoint(candidates, views, existing, {
            requireOutOfSight = false,
            minPlayerDist = 14,
            maxPlayerDist = 180,
        })
        if fallback then
            return fallback.pos, fallback.floor
        end
        return pickSpawnPosition(fallbackFloor), fallbackFloor
    end
    return nil, nil
end

local function clearNonStationaryZombies()
    for _, z in ipairs(zombiesFolder:GetChildren()) do
        if z:GetAttribute("IsStationary") ~= true then
            z:Destroy()
        end
    end
end

local function announceToAll(waveNum, msg)
    for _, p in ipairs(Players:GetPlayers()) do
        waveAnnounceEvent:FireClient(p, waveNum, msg)
    end
end

local function pickCampaignArchetype(channel)
    if channel == "Noise" or channel == "Objective" then
        return (math.random() < 0.45) and "MaleRunner" or ((math.random() < 0.5) and "FemaleRunner" or "MaleWalker")
    elseif channel == "Roaming" then
        return (math.random() < 0.35) and "FemaleWalker" or "MaleWalker"
    end
    return (math.random() < 0.5) and "MaleWalker" or "FemaleWalker"
end

local function getWeaponNoiseWeight(weaponName)
    if weaponName == "Ghost" then
        return 8
    elseif weaponName == "Phantom" then
        return 20
    elseif weaponName == "Classic" or weaponName == "Shorty" or weaponName == "Frenzy" or weaponName == "Sheriff" then
        return 18
    elseif weaponName == "Stinger" or weaponName == "Spectre" then
        return 22
    elseif weaponName == "Bulldog" or weaponName == "Guardian" or weaponName == "Vandal" then
        return 28
    end
    return 36
end

handleGunshotNoise = function(player, origin, weaponName)
    if not SPAWN_ZOMBIES or not director or director.getMode() ~= NetProtocol.ZombieMode.Campaign then
        return
    end
    if Workspace:GetAttribute(NetProtocol.Attributes.CampaignComplete) == true then
        return
    end
    if typeof(origin) == "Vector3" and (math.abs(origin.X) > 220 or math.abs(origin.Z) > 220) then
        return
    end
    local res = director.recordNoise(origin, getWeaponNoiseWeight(weaponName), weaponName)
    if res.triggered and res.count > 0 then
        local floorNum = typeof(origin) == "Vector3" and getFloorFromY(origin.Y) or nil
        local spawned = 0
        for _ = 1, res.count do
            local pos, f = pickCampaignSpawnPos(floorNum, { allowVisibleFallback = false })
            if pos then
                createZombieModel(pickCampaignArchetype("Noise"), pos, false, {
                    channel = "Noise",
                    mode = NetProtocol.ZombieMode.Campaign,
                    floor = f or floorNum or 1,
                })
                spawned += 1
            end
        end
        if spawned > 0 then
            print(string.format("[ZombieDirector] Gunfire noise (%s) drew %d infected on F%s", tostring(weaponName), spawned, tostring(floorNum or "?")))
        end
    end
end

local function runWaveModeLoop(myGeneration)
    local currentWave = 1
    while director.getMode() == NetProtocol.ZombieMode.Wave and zombieDirectorGeneration == myGeneration do
        if #Players:GetPlayers() == 0 then
            task.wait(0.8)
            continue
        end
        if Workspace:GetAttribute(NetProtocol.Attributes.CampaignComplete) == true then
            break
        end

        announceToAll(currentWave, string.format("⚠️ WAVE %d [TEST MODE] // ฝูงซอมบี้บุกอาคาร 40 ปี มจพ.!", currentWave))
        task.wait(2.5)
        if director.getMode() ~= NetProtocol.ZombieMode.Wave or zombieDirectorGeneration ~= myGeneration then
            break
        end

        local zombiesCount = math.min(6 + (currentWave * 3), 28)
        local waveZombies = {}
        local announcedBoss = false

        for idx = 1, zombiesCount do
            if director.getMode() ~= NetProtocol.ZombieMode.Wave or zombieDirectorGeneration ~= myGeneration then
                break
            end
            if Workspace:GetAttribute(NetProtocol.Attributes.CampaignComplete) == true then
                break
            end
            if director.getRemainingCapacity(nil) <= 0 then
                break
            end

            local zType = ZombieCatalog.pickForWave(currentWave)
            if currentWave >= 3 and idx == math.ceil(zombiesCount * 0.65) and not announcedBoss then
                zType = "MaleBoss"
            end

            if zType == "MaleBoss" and not announcedBoss then
                announcedBoss = true
                announceToAll(currentWave, "☢️ BOSS DETECTED // บอสกลายพันธุ์ปรากฏตัว!")
            end

            local spawnPos = pickCampaignSpawnPos(nil, { allowVisibleFallback = true, minPlayerDist = 16 })
            local zModel = createZombieModel(zType, spawnPos or pickSpawnPosition(), false, {
                channel = "Wave",
                mode = NetProtocol.ZombieMode.Wave,
            })
            table.insert(waveZombies, zModel)
            task.wait(0.75)
        end

        while #waveZombies > 0
            and director.getMode() == NetProtocol.ZombieMode.Wave
            and zombieDirectorGeneration == myGeneration
            and Workspace:GetAttribute(NetProtocol.Attributes.CampaignComplete) ~= true do
            for i = #waveZombies, 1, -1 do
                local z = waveZombies[i]
                if not z or not z.Parent or z:GetAttribute("IsDead") or (z:GetAttribute("CurrentHP") or 1) <= 0 then
                    table.remove(waveZombies, i)
                end
            end
            task.wait(0.8)
        end

        if director.getMode() ~= NetProtocol.ZombieMode.Wave
            or zombieDirectorGeneration ~= myGeneration
            or Workspace:GetAttribute(NetProtocol.Attributes.CampaignComplete) == true then
            break
        end

        local reward = 150 + (currentWave * 50)
        for _, p in ipairs(Players:GetPlayers()) do
            addPoints(p, reward)
            waveAnnounceEvent:FireClient(p, currentWave, string.format("🎉 WAVE %d CLEARED // กำจัดฝูงซอมบี้สำเร็จ! (+%d แต้ม)", currentWave, reward))
        end
        task.wait(4.5)
        currentWave += 1
        director.setWaveState(currentWave, 0)
    end
end

local function switchZombieMode(targetMode, actorPlayer)
    if targetMode ~= NetProtocol.ZombieMode.Campaign and targetMode ~= NetProtocol.ZombieMode.Wave then
        return false, "Invalid mode. Use 'Campaign' or 'Wave'."
    end
    zombieDirectorGeneration += 1
    local myGen = zombieDirectorGeneration
    clearNonStationaryZombies()
    director.resetAll(targetMode)
    Workspace:SetAttribute(NetProtocol.Attributes.ZombieMode, targetMode)

    if targetMode == NetProtocol.ZombieMode.Wave then
        announceToAll(1, string.format("⚠️ WAVE TEST MODE activated by %s", actorPlayer and actorPlayer.Name or "Dev"))
        task.spawn(runWaveModeLoop, myGen)
        return true, "[DEV] Switched to WAVE / TEST MODE."
    else
        announceToAll(0, "CAMPAIGN MODE // Hybrid Infected Director active.")
        return true, "[DEV] Switched back to CAMPAIGN MODE (Wave loop stopped)."
    end
end

-- Expose ServerStorage.ZombieSignals for DevCommandService & MissionService
local zombieSignalsFolder = ServerStorage:FindFirstChild(NetProtocol.Signals.ZombieSignalsFolder) or Instance.new("Folder")
zombieSignalsFolder.Name = NetProtocol.Signals.ZombieSignalsFolder
zombieSignalsFolder.Parent = ServerStorage

local function ensureZSignal(className, name)
    local ex = zombieSignalsFolder:FindFirstChild(name)
    if ex and ex.ClassName == className then return ex end
    if ex then ex:Destroy() end
    local c = Instance.new(className)
    c.Name = name
    c.Parent = zombieSignalsFolder
    return c
end

local setZombieModeFn = ensureZSignal("BindableFunction", NetProtocol.Signals.SetZombieMode)
local triggerNoiseFn = ensureZSignal("BindableFunction", NetProtocol.Signals.TriggerNoise)
local triggerHordeFn = ensureZSignal("BindableFunction", NetProtocol.Signals.TriggerHorde)
local triggerEncounterFn = ensureZSignal("BindableFunction", NetProtocol.Signals.TriggerEncounter)
local resetZombiesFn = ensureZSignal("BindableFunction", NetProtocol.Signals.ResetZombies)
local getZombieStatsFn = ensureZSignal("BindableFunction", NetProtocol.Signals.GetZombieStats)

setZombieModeFn.OnInvoke = function(targetMode, actorPlayer)
    return switchZombieMode(targetMode, actorPlayer)
end

triggerNoiseFn.OnInvoke = function(origin, weight, sourceName)
    if director.getMode() ~= NetProtocol.ZombieMode.Campaign then
        return false, "Noise spawn only runs in Campaign Mode (currently " .. director.getMode() .. ")"
    end
    local w = tonumber(weight) or 45
    local res = director.recordNoise(origin or Vector3.new(0, 5, 0), w, sourceName or "DevNoise")
    local spawned = 0
    if res.triggered and res.count > 0 then
        local floorNum = typeof(origin) == "Vector3" and getFloorFromY(origin.Y) or nil
        for _ = 1, res.count do
            local pos, f = pickCampaignSpawnPos(floorNum, { allowVisibleFallback = true })
            if pos then
                createZombieModel(pickCampaignArchetype("Noise"), pos, false, {
                    channel = "Noise",
                    mode = NetProtocol.ZombieMode.Campaign,
                    floor = f or 1,
                })
                spawned += 1
            end
        end
    end
    return true, string.format("Noise recorded (Heat:%d) -> spawned %d noise zombie(s)", math.floor(res.noiseHeat or 0), spawned)
end

triggerHordeFn.OnInvoke = function(origin, count)
    local res = director.triggerHorde(tonumber(count) or 5)
    if not res.triggered or res.count <= 0 then
        return false, "Horde blocked: " .. tostring(res.reason or "cap_reached")
    end
    local floorNum = typeof(origin) == "Vector3" and getFloorFromY(origin.Y) or nil
    local spawned = 0
    for _ = 1, res.count do
        local pos, f = pickCampaignSpawnPos(floorNum, { allowVisibleFallback = true })
        if pos then
            local zType = (spawned % 2 == 0) and "MaleRunner" or "MaleWalker"
            createZombieModel(zType, pos, false, {
                channel = res.channel,
                mode = director.getMode(),
                floor = f or 1,
            })
            spawned += 1
        end
    end
    return spawned > 0, string.format("Horde triggered: spawned %d zombie(s) (Cap:%d/%d)", spawned, director.getAliveCount(nil, nil), director.getConfig().maxAliveCampaign)
end

triggerEncounterFn.OnInvoke = function(encounterId, count, preferFloor)
    local res = director.triggerObjectiveEncounter(encounterId or "DEV_ENCOUNTER", tonumber(count) or 3, { force = true })
    if not res.triggered or res.count <= 0 then
        return false, "Encounter blocked: " .. tostring(res.reason)
    end
    local spawned = 0
    for _ = 1, res.count do
        local pos, f = pickCampaignSpawnPos(preferFloor, { allowVisibleFallback = true })
        if pos then
            createZombieModel(pickCampaignArchetype("Objective"), pos, false, {
                channel = "Objective",
                mode = director.getMode(),
                floor = f or 1,
                encounterId = res.encounterId,
            })
            spawned += 1
        end
    end
    return true, string.format("Objective Encounter '%s' spawned %d zombie(s)", tostring(res.encounterId), spawned)
end

resetZombiesFn.OnInvoke = function()
    zombieDirectorGeneration += 1
    clearNonStationaryZombies()
    director.resetAll(NetProtocol.ZombieMode.Campaign)
    Workspace:SetAttribute(NetProtocol.Attributes.ZombieMode, NetProtocol.ZombieMode.Campaign)
    announceToAll(0, "🧟 Zombies reset — Campaign Hybrid Director active.")
    return true, "[DEV] Cleared all active zombies and restored Campaign Mode."
end

getZombieStatsFn.OnInvoke = function()
    return director.getStatsSnapshot()
end

local function startIntroSequence()
    if not SPAWN_ZOMBIES then
        return
    end
    while #Players:GetPlayers() == 0 do
        task.wait(0.5)
    end
    task.wait(3.0)
    announceToAll(0, "BUILDING 40 LOCKDOWN // Investigate Floor 1 — Gunfire attracts infected")

    while true do
        task.wait(3.5)
        if not SPAWN_ZOMBIES then
            break
        end
        if director.getMode() == NetProtocol.ZombieMode.Campaign
            and #Players:GetPlayers() > 0
            and Workspace:GetAttribute(NetProtocol.Attributes.CampaignComplete) ~= true then
            local amb = director.requestAmbientTick()
            if amb.shouldSpawn and amb.count > 0 then
                for _ = 1, amb.count do
                    local pos, f = pickCampaignSpawnPos(nil, { allowVisibleFallback = false })
                    if pos then
                        createZombieModel(pickCampaignArchetype("Ambient"), pos, false, {
                            channel = "Ambient",
                            mode = NetProtocol.ZombieMode.Campaign,
                            floor = f or 1,
                        })
                    end
                end
            else
                local roam = director.requestRoamingTick()
                if roam.shouldSpawn and roam.count > 0 then
                    local pos, f = pickCampaignSpawnPos(nil, { allowVisibleFallback = false })
                    if pos then
                        createZombieModel(pickCampaignArchetype("Roaming"), pos, false, {
                            channel = "Roaming",
                            mode = NetProtocol.ZombieMode.Campaign,
                            floor = f or 1,
                        })
                    end
                end
            end
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    playerData[p.UserId] = { Points = 500, Kills = 0, Status = "Alive" }
    p:SetAttribute("Points", 500)
    p:SetAttribute("Kills", 0)
    initializePlayerInventory(p)
    bindPlayerWeaponState(p)
    p.CharacterAdded:Connect(function(char)
        setupPlayerCharacter(p, char)
    end)
    if p.Character then
        task.spawn(setupPlayerCharacter, p, p.Character)
    end
end

Players.PlayerAdded:Connect(function(player)
    playerData[player.UserId] = { Points = 500, Kills = 0, Status = "Alive" }
    player:SetAttribute("Points", 500)
    player:SetAttribute("Kills", 0)
    initializePlayerInventory(player)
    bindPlayerWeaponState(player)
    player.CharacterAdded:Connect(function(char)
        setupPlayerCharacter(player, char)
    end)
    if player.Character then
        task.spawn(setupPlayerCharacter, player, player.Character)
    end
    task.wait(1)
    broadcastScoreboard()
end)

Players.PlayerRemoving:Connect(function(player)
    playerData[player.UserId] = nil
    playerWeaponSlots[player.UserId] = nil
    playerSlotStates[player.UserId] = nil
    lastWeaponPurchaseAt[player.UserId] = nil
    lastDamagedTime[player.UserId] = nil
    weaponStates[player.UserId] = nil
    if weaponStateConnections[player.UserId] then
        weaponStateConnections[player.UserId]:Disconnect()
        weaponStateConnections[player.UserId] = nil
    end
    broadcastScoreboard()
end)

task.spawn(startIntroSequence)
