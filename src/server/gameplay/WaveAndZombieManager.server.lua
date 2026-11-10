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

local SPAWN_ZOMBIES = true

print("=========================================================")
print("🧟 [Smart Zombie Horde v2] เปิดระบบซอมบี้ AI ฉลาด + ยิงเลือดลดแม่นยำ 100%!")
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
local playerDamageEvent = getOrCreateRemote("RemoteEvent", "PlayerDamageEvent")
-- Legacy ZombieHitEvent is retained for compatibility, but no longer accepts client-authored damage.
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
local buyWeaponEvent = getOrCreateRemote("RemoteFunction", "BuyWeaponEvent")
local toggleAdminEvent = getOrCreateRemote("RemoteEvent", "ToggleAdminMode")

-- Add extra Roblox user IDs here only when the experience is group-owned.
local ADMIN_USER_IDS = {
    -- [123456789] = true,
}

local function isAuthorizedAdmin(player)
    if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
        return true
    end
    return ADMIN_USER_IDS[player.UserId] == true
end

toggleAdminEvent.OnServerEvent:Connect(function(player, enabled)
    if not isAuthorizedAdmin(player) then
        player:SetAttribute("IsAdminGodMode", false)
        local unauthorizedChar = player.Character
        if unauthorizedChar then
            unauthorizedChar:SetAttribute("IsAdminGodMode", false)
        end
        return
    end

    local isGod = (enabled == true)
    player:SetAttribute("IsAdminGodMode", isGod)
    local char = player.Character
    if char then
        char:SetAttribute("IsAdminGodMode", isGod)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and isGod then
            hum.MaxHealth = 100
            hum.Health = 100
        end
    end
end)

----------------------------------------------------------------------
-- 1. ฐานข้อมูลผู้เล่น, คะแนน, และระบบ HP ผู้เล่น
----------------------------------------------------------------------
local playerData = {}
local lastDamagedTime = {}

local function broadcastScoreboard()
    local scoreList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local data = playerData[p.UserId] or { Points = 500, Kills = 0, Status = "Alive" }
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
    Classic   = { Mag = 12, Reserve = 120, FireRate = 0.15, Pellets = 1, Head = 78,  Body = 26, Legs = 22, Spread = 0.00, ReloadTime = 2.0 },
    Shorty    = { Mag = 2,  Reserve = 40,  FireRate = 0.30, Pellets = 10, Head = 36, Body = 12, Legs = 10, Spread = 0.08, ReloadTime = 2.0 },
    Frenzy    = { Mag = 13, Reserve = 90,  FireRate = 0.10, Pellets = 1, Head = 78,  Body = 26, Legs = 22, Spread = 0.01, ReloadTime = 2.0 },
    Ghost     = { Mag = 15, Reserve = 90,  FireRate = 0.15, Pellets = 1, Head = 105, Body = 30, Legs = 26, Spread = 0.00, ReloadTime = 2.0 },
    Sheriff   = { Mag = 6,  Reserve = 60,  FireRate = 0.25, Pellets = 1, Head = 159, Body = 55, Legs = 46, Spread = 0.00, ReloadTime = 2.0 },
    Stinger   = { Mag = 20, Reserve = 120, FireRate = 0.062, Pellets = 1, Head = 67,  Body = 27, Legs = 23, Spread = 0.015, ReloadTime = 2.0 },
    Spectre   = { Mag = 30, Reserve = 150, FireRate = 0.075, Pellets = 1, Head = 78,  Body = 26, Legs = 22, Spread = 0.015, ReloadTime = 2.0 },
    Bucky     = { Mag = 8,  Reserve = 60,  FireRate = 0.75, Pellets = 15, Head = 40, Body = 20, Legs = 15, Spread = 0.08, ReloadTime = 2.0 },
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

local weaponStates = {}
local weaponStateConnections = {}

local function syncWeaponAmmo(player)
    local state = weaponStates[player.UserId]
    if state then
        weaponAmmoSyncEvent:FireClient(player, state.weaponName, state.clip, state.reserve, state.reloading)
    end
end

local function resetWeaponState(player, weaponName)
    local stats = WEAPON_BALANCE[weaponName]
    if not stats then return false end

    weaponStates[player.UserId] = {
        weaponName = weaponName,
        clip = stats.Mag,
        reserve = stats.Reserve,
        reloading = false,
        lastShotAt = 0,
        reloadToken = 0,
    }
    syncWeaponAmmo(player)
    return true
end

local function bindPlayerWeaponState(player)
    if not weaponStateConnections[player.UserId] then
        weaponStateConnections[player.UserId] = player:GetAttributeChangedSignal("EquippedWeapon"):Connect(function()
            local weaponName = player:GetAttribute("EquippedWeapon")
            if not WEAPON_BALANCE[weaponName] then
                warn("[WeaponCombat] Rejected unknown equipped weapon for " .. player.Name)
                player:SetAttribute("EquippedWeapon", "Classic")
                return
            end
            resetWeaponState(player, weaponName)
        end)
    end

    local currentName = player:GetAttribute("EquippedWeapon")
    if not WEAPON_BALANCE[currentName] then
        player:SetAttribute("EquippedWeapon", "Classic")
        currentName = "Classic"
    end

    local state = weaponStates[player.UserId]
    if not state or state.weaponName ~= currentName then
        resetWeaponState(player, currentName)
    end
end

buyWeaponEvent.OnServerInvoke = function(player, weaponName, cost)
    local data = playerData[player.UserId]
    if not data or data.Points < cost then
        return false, "แต้มไม่พอ!"
    end
    data.Points = data.Points - cost
    broadcastScoreboard()
    return true, "ซื้อสำเร็จ!"
end

local function setupPlayerCharacter(player, char)
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end

    bindPlayerWeaponState(player)

    if player:GetAttribute("IsAdminGodMode") == nil then
        player:SetAttribute("IsAdminGodMode", false)
    end
    char:SetAttribute("IsAdminGodMode", player:GetAttribute("IsAdminGodMode") == true)

    hum.MaxHealth = 100
    hum.Health = 100
    if playerData[player.UserId] then
        playerData[player.UserId].Status = "Alive"
        broadcastScoreboard()
    end

    hum.Died:Connect(function()
        if playerData[player.UserId] then
            playerData[player.UserId].Status = "Dead"
            broadcastScoreboard()
        end
    end)
end

-- ระบบฟื้นฟูเลือดอัตโนมัติเมื่อไม่ได้โดนซอมบี้ตีนานเกิน 6 วินาที
task.spawn(function()
    while true do
        local now = os.clock()
        for _, p in ipairs(Players:GetPlayers()) do
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
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
local function attachHealthBillboard(zombie, baseHealth, zType)
    local head = zombie:FindFirstChild("Head") or zombie.PrimaryPart
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "HealthBillboard"
    bb.Size = UDim2.new(0, 145, 0, 40)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 110
    bb.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = (zType == "Tank") and Color3.fromRGB(255, 85, 85)
        or ((zType == "Runner") and Color3.fromRGB(255, 175, 50) or Color3.fromRGB(230, 240, 120))
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.Text = (zType == "Tank") and "🛡️ TANK ZOMBIE" or ("🧟 ZOMBIE " .. zType:upper())
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
local FLOOR11_SPAWNS = makeUpperFloorSpawns(225)
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
-- 4. สร้างโมเดลซอมบี้ (Motor6D Rig + Smart Hybrid AI)
----------------------------------------------------------------------
local function createZombieModel(zombieType, spawnPos, isStationary)
    local zombie = Instance.new("Model")
    zombie.Name = "Zombie_" .. zombieType

    local scale = (zombieType == "Tank") and 1.35 or 1.0
    local baseSpeed = (zombieType == "Runner") and 19.5 or ((zombieType == "Tank") and 12.0 or 15.0)
    local baseHealth = (zombieType == "Tank") and 360 or ((zombieType == "Runner") and 90 or 120)
    local attackDmg = (zombieType == "Tank") and 28 or ((zombieType == "Runner") and 12 or 16)

    zombie:SetAttribute("IsZombie", true)
    zombie:SetAttribute("ZombieType", zombieType)
    zombie:SetAttribute("MaxHealth", baseHealth)
    zombie:SetAttribute("CurrentHP", baseHealth)
    zombie:SetAttribute("IsDead", false)
    zombie:SetAttribute("SpawnPos", spawnPos)
    zombie:SetAttribute("IsStationary", isStationary or false)

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(1.8 * scale, 2.4 * scale, 1.0 * scale)
    hrp.CFrame = CFrame.new(spawnPos)
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.CanQuery = true
    hrp.Anchored = isStationary and true or false
    hrp.Parent = zombie

    local torsoColor = (zombieType == "Tank") and Color3.fromRGB(65, 42, 38)
        or ((zombieType == "Runner") and Color3.fromRGB(105, 58, 58) or Color3.fromRGB(68, 92, 70))
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2.0 * scale, 2.4 * scale, 1.1 * scale)
    torso.CFrame = hrp.CFrame
    torso.Color = torsoColor
    torso.Material = Enum.Material.SmoothPlastic
    torso.CanCollide = true
    torso.CanQuery = true
    torso.Anchored = isStationary and true or false
    torso.Parent = zombie

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.45 * scale, 1.45 * scale, 1.45 * scale)
    head.CFrame = torso.CFrame * CFrame.new(0, 1.9 * scale, 0)
    head.Color = Color3.fromRGB(115, 142, 110)
    head.Material = Enum.Material.SmoothPlastic
    head.CanCollide = false
    head.CanQuery = true
    head.Anchored = isStationary and true or false
    head.Parent = zombie

    local eyes = Instance.new("Part")
    eyes.Name = "Eyes"
    eyes.Size = Vector3.new(0.85 * scale, 0.25 * scale, 0.25 * scale)
    eyes.CFrame = head.CFrame * CFrame.new(0, 0.1 * scale, -0.68 * scale)
    eyes.Color = Color3.fromRGB(255, 35, 35)
    eyes.Material = Enum.Material.Neon
    eyes.CanCollide = false
    eyes.CanQuery = true
    eyes.Anchored = isStationary and true or false
    eyes.Parent = zombie

    local armColor = Color3.fromRGB(105, 132, 102)
    local armL = Instance.new("Part")
    armL.Name = "LeftArm"
    armL.Size = Vector3.new(0.75 * scale, 0.75 * scale, 2.2 * scale)
    armL.CFrame = torso.CFrame * CFrame.new(-1.35 * scale, 0.55 * scale, -0.95 * scale)
    armL.Color = armColor
    armL.Material = Enum.Material.SmoothPlastic
    armL.CanCollide = false
    armL.CanQuery = true
    armL.Anchored = isStationary and true or false
    armL.Parent = zombie

    local armR = Instance.new("Part")
    armR.Name = "RightArm"
    armR.Size = Vector3.new(0.75 * scale, 0.75 * scale, 2.2 * scale)
    armR.CFrame = torso.CFrame * CFrame.new(1.35 * scale, 0.55 * scale, -0.95 * scale)
    armR.Color = armColor
    armR.Material = Enum.Material.SmoothPlastic
    armR.CanCollide = false
    armR.CanQuery = true
    armR.Anchored = isStationary and true or false
    armR.Parent = zombie

    local legL = Instance.new("Part")
    legL.Name = "LeftLeg"
    legL.Size = Vector3.new(0.85 * scale, 2.4 * scale, 0.85 * scale)
    legL.CFrame = torso.CFrame * CFrame.new(-0.52 * scale, -2.4 * scale, 0)
    legL.Color = Color3.fromRGB(42, 48, 58)
    legL.Material = Enum.Material.SmoothPlastic
    legL.CanCollide = false
    legL.CanQuery = true
    legL.Anchored = isStationary and true or false
    legL.Parent = zombie

    local legR = Instance.new("Part")
    legR.Name = "RightLeg"
    legR.Size = Vector3.new(0.85 * scale, 2.4 * scale, 0.85 * scale)
    legR.CFrame = torso.CFrame * CFrame.new(0.52 * scale, -2.4 * scale, 0)
    legR.Color = Color3.fromRGB(42, 48, 58)
    legR.Material = Enum.Material.SmoothPlastic
    legR.CanCollide = false
    legR.CanQuery = true
    legR.Anchored = isStationary and true or false
    legR.Parent = zombie

    -- เชื่อมด้วย Motor6D มาตรฐานเพื่อให้ Humanoid R6 ไม่ตายเอง (RequiresNeck) และขยับแขนขาได้สมจริง
    local function makeMotor(name, p0, p1, c0, c1)
        local m = Instance.new("Motor6D")
        m.Name = name
        m.Part0 = p0
        m.Part1 = p1
        m.C0 = c0 or CFrame.identity
        m.C1 = c1 or CFrame.identity
        m.Parent = p0
        return m
    end

    makeMotor("RootJoint", hrp, torso, CFrame.identity, CFrame.identity)
    makeMotor("Neck", torso, head, CFrame.new(0, 1.9 * scale, 0), CFrame.identity)
    local eyeWeld = Instance.new("WeldConstraint")
    eyeWeld.Part0 = head
    eyeWeld.Part1 = eyes
    eyeWeld.Parent = head

    local shoulderL = makeMotor("Left Shoulder", torso, armL, CFrame.new(-1.35 * scale, 0.55 * scale, 0), CFrame.new(0, 0, 0.95 * scale))
    local shoulderR = makeMotor("Right Shoulder", torso, armR, CFrame.new(1.35 * scale, 0.55 * scale, 0), CFrame.new(0, 0, 0.95 * scale))
    local hipL = makeMotor("Left Hip", torso, legL, CFrame.new(-0.52 * scale, -1.2 * scale, 0), CFrame.new(0, 1.2 * scale, 0))
    local hipR = makeMotor("Right Hip", torso, legR, CFrame.new(0.52 * scale, -1.2 * scale, 0), CFrame.new(0, 1.2 * scale, 0))

    -- ตั้งค่า Humanoid ให้ไม่ตายจาก Neck check เด็ดขาด
    local humanoid = Instance.new("Humanoid")
    humanoid.RequiresNeck = false
    humanoid.BreakJointsOnDeath = false
    humanoid.MaxHealth = baseHealth
    humanoid.Health = baseHealth
    humanoid.WalkSpeed = isStationary and 0 or baseSpeed
    humanoid.JumpPower = 52
    humanoid.AutoRotate = true
    humanoid.HipHeight = 2.4 * scale
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
    humanoid.Parent = zombie

    zombie.PrimaryPart = hrp
    zombie.Parent = zombiesFolder

    -- บังคับตั้งค่า Health ซ้ำหลัง Parent เพื่อความชัวร์ 100%
    humanoid.MaxHealth = baseHealth
    humanoid.Health = baseHealth

    if not isStationary then
        pcall(function()
            hrp:SetNetworkOwner(nil)
        end)
    end

    local groan = Instance.new("Sound")
    groan.SoundId = "rbxassetid://9114221580"
    groan.Looped = true
    groan.Volume = 0.28
    groan.RollOffMaxDistance = 50
    groan.Parent = head
    groan:Play()

    attachHealthBillboard(zombie, baseHealth, zombieType)

    if isStationary then
        return zombie
    end

    ------------------------------------------------------------------
    -- 🧟 SMART HYBRID ZOMBIE AI (LOS Pursuit + Multi-Waypoint Follower)
    ------------------------------------------------------------------
    task.spawn(function()
        local lastAttack = 0
        local lastPos = hrp.Position
        local lastMoveCheckTime = os.clock()
        local stuckTimer = 0

        local currentWaypoints = nil
        local wpIndex = 2
        local lastPathComputeTime = 0

        -- มุมกระจายตัวเฉพาะของซอมบี้แต่ละตัว เพื่อล้อมผู้เล่นไม่ให้เดินทับเส้นเดียวกัน
        local flankAngle = (math.random() - 0.5) * math.rad(55)
        local animPhase = math.random() * 6.28

        local losParams = RaycastParams.new()
        losParams.FilterType = Enum.RaycastFilterType.Exclude
        losParams.IgnoreWater = true

        while zombie and zombie.Parent and not zombie:GetAttribute("IsDead") do
            local now = os.clock()
            local dt = 0.12

            -- 1. ค้นหาผู้เล่นเป้าหมาย (ให้ความสำคัญกับคนที่เพิ่งยิงซอมบี้ตัวนี้ก่อน)
            local aggroUserId = zombie:GetAttribute("AggroTargetUserId")
            local targetPlayer = nil
            local targetChar = nil
            local targetRoot = nil
            local nearestDist = math.huge

            for _, p in ipairs(Players:GetPlayers()) do
                local c = p.Character
                local pHum = c and c:FindFirstChildOfClass("Humanoid")
                local pRoot = c and c:FindFirstChild("HumanoidRootPart")
                if pHum and pHum.Health > 0 and pRoot then
                    local d = (pRoot.Position - hrp.Position).Magnitude
                    local effectiveDist = (aggroUserId and p.UserId == aggroUserId) and (d * 0.65) or d
                    if effectiveDist < nearestDist then
                        nearestDist = d
                        targetPlayer = p
                        targetChar = c
                        targetRoot = pRoot
                    end
                end
            end

            if targetRoot then
                local myPos = hrp.Position
                local targetPos = targetRoot.Position
                local toTarget = targetPos - myPos
                local horizDist = Vector3.new(toTarget.X, 0, toTarget.Z).Magnitude
                local heightDiff = math.abs(targetPos.Y - myPos.Y)

                -- ปรับสปีด: ถ้าโดนยิงหรือเข้าใกล้ระยะประชิดให้เร่งสปีดดุดันขึ้น
                local enragedUntil = zombie:GetAttribute("EnragedUntil") or 0
                if now < enragedUntil then
                    humanoid.WalkSpeed = baseSpeed * 1.25
                elseif nearestDist < 28 and heightDiff < 8 then
                    humanoid.WalkSpeed = baseSpeed * 1.12
                else
                    humanoid.WalkSpeed = baseSpeed
                end

                -- 2. เช็ก Line-of-Sight (LOS) ว่ามีกำแพงหรือสิ่งกีดขวางกั้นหรือไม่
                local filterList = { zombiesFolder, targetChar }
                losParams.FilterDescendantsInstances = filterList
                local losRay = Workspace:Raycast(myPos + Vector3.new(0, 1.2, 0), (targetPos - myPos), losParams)
                local hasClearLOS = (losRay == nil) and (heightDiff < 8.5)

                -- 3. ตรวจสอบการติดกำแพง (Anti-Stuck Check ทุก 0.6 วินาที)
                if now - lastMoveCheckTime >= 0.6 then
                    local movedDist = Vector3.new(myPos.X - lastPos.X, 0, myPos.Z - lastPos.Z).Magnitude
                    lastPos = myPos
                    lastMoveCheckTime = now

                    if movedDist < 0.65 and horizDist > 5.0 then
                        stuckTimer = stuckTimer + 0.6
                        humanoid.Jump = true
                        -- ก้าวหลบออกด้านข้างทันทีเมื่อชนขอบประตู/โต๊ะ/เสา
                        local sideDir = (math.random(0, 1) == 0) and 1 or -1
                        local sidestepPos = myPos + (hrp.CFrame.RightVector * (sideDir * 7)) + (hrp.CFrame.LookVector * 3)
                        humanoid:MoveTo(sidestepPos)
                        currentWaypoints = nil -- บังคับคำนวณเส้นทางใหม่

                        -- ถ้าติดซอกลึกเกิน 3.0 วินาที ให้ขยับหลุดออกจากมุมหรือย้ายไปจุดเกิดใกล้ผู้เล่น
                        if stuckTimer >= 3.0 then
                            stuckTimer = 0
                            local preferF2 = (targetPos.Y >= 15)
                            hrp.CFrame = CFrame.new(pickSpawnPosition(preferF2))
                        end
                    else
                        stuckTimer = 0
                    end
                end

                -- 4. การเคลื่อนที่: ทางโล่งไล่ตรงแบบดักหน้า vs มีสิ่งกีดขวางใช้ Persistent Waypoint Pathfinding
                if hasClearLOS then
                    currentWaypoints = nil
                    local targetVel = targetRoot.AssemblyLinearVelocity or Vector3.zero
                    local leadOffset = Vector3.new(targetVel.X, 0, targetVel.Z) * math.clamp(horizDist / 45, 0, 0.35)

                    local moveGoal = targetPos + leadOffset
                    if horizDist > 8.5 then
                        -- กระจายตัวโอบล้อมผู้เล่น (Flanking Arc)
                        local dirUnit = Vector3.new(toTarget.X, 0, toTarget.Z).Unit
                        local rotatedDir = CFrame.Angles(0, flankAngle, 0):VectorToWorldSpace(dirUnit)
                        moveGoal = myPos + rotatedDir * math.min(horizDist, 18)
                    end
                    humanoid:MoveTo(moveGoal)
                else
                    -- ต้องเดินอ้อมกำแพง/ร้านค้า หรือขึ้นลงบันได: คำนวณ Path ใหม่เมื่อยังไม่มีหรือครบเวลา 1.2 วินาที
                    local needNewPath = (not currentWaypoints)
                        or (wpIndex > #currentWaypoints)
                        or (now - lastPathComputeTime >= 1.2)

                    if needNewPath then
                        lastPathComputeTime = now
                        local ok, path = pcall(function()
                            local p = PathfindingService:CreatePath({
                                AgentRadius = 1.6,
                                AgentHeight = 5.0,
                                AgentCanJump = true,
                                WaypointSpacing = 3.5,
                            })
                            p:ComputeAsync(myPos, targetPos)
                            return p
                        end)

                        if ok and path and path.Status == Enum.PathStatus.Success then
                            local wps = path:GetWaypoints()
                            if #wps >= 2 then
                                currentWaypoints = wps
                                wpIndex = 2
                            else
                                currentWaypoints = nil
                            end
                        else
                            currentWaypoints = nil
                        end
                    end

                    -- เดินตาม Waypoint ปัจจุบันไปเรื่อยๆ จนกว่าจะถึงแต่ละจุด (ไม่รีเซ็ตทิ้งกลางคัน!)
                    if currentWaypoints and currentWaypoints[wpIndex] then
                        local wp = currentWaypoints[wpIndex]
                        local wpHorizontalDist = Vector3.new(wp.Position.X - myPos.X, 0, wp.Position.Z - myPos.Z).Magnitude
                        if wpHorizontalDist < 3.8 and math.abs(wp.Position.Y - myPos.Y) < 6 then
                            wpIndex = wpIndex + 1
                            wp = currentWaypoints[wpIndex]
                        end

                        if wp then
                            if wp.Action == Enum.PathWaypointAction.Jump then
                                humanoid.Jump = true
                            end
                            humanoid:MoveTo(wp.Position)
                        else
                            humanoid:MoveTo(targetPos)
                        end
                    else
                        humanoid:MoveTo(targetPos)
                    end
                end

                -- 5. แอนิเมชันขาเดินและแขนซอมบี้ (Procedural Walk & Attack Pose)
                animPhase = animPhase + dt * (humanoid.WalkSpeed * 0.65)
                local swing = math.sin(animPhase) * math.rad(32)
                local armBob = math.cos(animPhase) * math.rad(10)

                -- 6. โจมตีผู้เล่นเมื่อเข้าระยะประชิด (<= 6.2 studs)
                if horizDist <= 6.2 and heightDiff <= 5.5 and (now - lastAttack >= 1.0) then
                    lastAttack = now
                    -- ท่าง้างมือฟาดผู้เล่น
                    shoulderL.C0 = CFrame.new(-1.35 * scale, 0.55 * scale, 0) * CFrame.Angles(math.rad(-45), 0, 0)
                    shoulderR.C0 = CFrame.new( 1.35 * scale, 0.55 * scale, 0) * CFrame.Angles(math.rad(-45), 0, 0)

                    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
                    local isGodMode = (targetPlayer and targetPlayer:GetAttribute("IsAdminGodMode") == true)
                        or (targetChar:GetAttribute("IsAdminGodMode") == true)
                    if isGodMode then
                        if targetHum and targetHum.Health < targetHum.MaxHealth then
                            targetHum.Health = targetHum.MaxHealth
                        end
                    elseif targetHum and targetHum.Health > 0 then
                        targetHum:TakeDamage(attackDmg)
                        if targetPlayer then
                            lastDamagedTime[targetPlayer.UserId] = now
                            playerDamageEvent:FireClient(targetPlayer, attackDmg, targetHum.Health, targetHum.MaxHealth)
                        end
                    end
                else
                    shoulderL.C0 = CFrame.new(-1.35 * scale, 0.55 * scale, 0) * CFrame.Angles(armBob, 0, 0)
                    shoulderR.C0 = CFrame.new( 1.35 * scale, 0.55 * scale, 0) * CFrame.Angles(-armBob, 0, 0)
                end

                hipL.C0 = CFrame.new(-0.52 * scale, -1.2 * scale, 0) * CFrame.Angles(swing, 0, 0)
                hipR.C0 = CFrame.new( 0.52 * scale, -1.2 * scale, 0) * CFrame.Angles(-swing, 0, 0)
            end

            task.wait(dt)
        end
    end)

    return zombie
end

----------------------------------------------------------------------
-- 5. ตรวจจับการยิงถูกซอมบี้ (ZOMBIE HIT EVENT - เลือดลดจริง 100%)
----------------------------------------------------------------------
local function findZombieFromPart(part)
    local cur = part
    while cur and cur ~= Workspace do
        if cur:IsA("Model") and (cur:GetAttribute("IsZombie") or cur.Name:sub(1, 7) == "Zombie_") then
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

    local isHeadshot = (hitPart.Name == "Head" or hitPart.Name == "Eyes")
    local isLegHit = hitPart.Name == "LeftLeg" or hitPart.Name == "RightLeg"
    local actualDmg = isHeadshot and stats.Head or (isLegHit and stats.Legs or stats.Body)
    local newHP = math.max(0, curHP - actualDmg)
    local isPreview = zombie:GetAttribute("IsPreviewDummy") == true

    zombie:SetAttribute("CurrentHP", newHP)
    zombie:SetAttribute("AggroTargetUserId", player.UserId)
    zombie:SetAttribute("EnragedUntil", os.clock() + 1.8)

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
                        part.CanQuery = true
                        if part.Name ~= "Eyes" then
                            part.Transparency = 0
                        end
                    end
                end
            end)
            return
        end

        if playerData[player.UserId] then
            playerData[player.UserId].Kills = playerData[player.UserId].Kills + 1
        end
        addPoints(player, isHeadshot and 100 or 50)

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
end

-- The client sends only its camera ray. Server validates origin, owns ammo/cadence,
-- performs its own raycasts, and derives damage from the equipped weapon whitelist.
weaponFireEvent.OnServerEvent:Connect(function(player, clientOrigin, clientDirection)
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

    local weaponName = player:GetAttribute("EquippedWeapon") or "Classic"
    local stats = WEAPON_BALANCE[weaponName]
    if not stats then return end

    local state = weaponStates[player.UserId]
    if not state or state.weaponName ~= weaponName then
        resetWeaponState(player, weaponName)
        state = weaponStates[player.UserId]
    end

    local now = os.clock()
    if state.reloading or now - state.lastShotAt < stats.FireRate * 0.92 then
        syncWeaponAmmo(player)
        return
    end
    if state.clip <= 0 then
        syncWeaponAmmo(player)
        return
    end

    state.lastShotAt = now
    state.clip = state.clip - 1
    syncWeaponAmmo(player)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { character }
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
                applyWeaponDamage(player, hit.Instance, stats)
                hitCount = hitCount + 1
            end
        end
    end

    if hitCount > 0 then
        print(string.format("[WeaponCombat] %s fired %s and hit %d zombie part(s)", player.Name, weaponName, hitCount))
    end
end)

weaponReloadEvent.OnServerEvent:Connect(function(player)
    local weaponName = player:GetAttribute("EquippedWeapon") or "Classic"
    local stats = WEAPON_BALANCE[weaponName]
    local state = weaponStates[player.UserId]
    if not stats or not state or state.weaponName ~= weaponName then return end

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

-- Retired: ZombieHitEvent no longer trusts a client-supplied hit part or damage value.
zombieHitEvent.OnServerEvent:Connect(function()
    warn("[WeaponCombat] Ignored deprecated ZombieHitEvent request; use FireWeapon.")
end)

----------------------------------------------------------------------
-- 6. วงจรเวฟซอมบี้ (WAVE LOOP)
----------------------------------------------------------------------
local function startIntroSequence()
    if not SPAWN_ZOMBIES then
        return
    end

    while #Players:GetPlayers() == 0 do
        task.wait(0.5)
    end
    task.wait(2.0)

    local currentWave = 1
    while true do
        for _, p in ipairs(Players:GetPlayers()) do
            waveAnnounceEvent:FireClient(p, currentWave, string.format("⚠️ WAVE %d // ฝูงซอมบี้บุกอาคาร 40 ปี มจพ.!", currentWave))
        end
        task.wait(2.5)

        local zombiesCount = math.min(6 + (currentWave * 3), 28)
        local activeZombies = {}

        for _ = 1, zombiesCount do
            local zType = "Walker"
            local rand = math.random()
            if currentWave >= 2 and rand > 0.60 then
                zType = "Runner"
            end
            if currentWave >= 3 and rand > 0.84 then
                zType = "Tank"
            end

            local spawnPos = pickSpawnPosition()
            local zModel = createZombieModel(zType, spawnPos, false)
            table.insert(activeZombies, zModel)
            task.wait(0.8)
        end

        -- รอจนกว่าซอมบี้ในเวฟจะถูกกำจัดหมด
        while #activeZombies > 0 do
            for i = #activeZombies, 1, -1 do
                local z = activeZombies[i]
                if not z or not z.Parent or z:GetAttribute("IsDead") or (z:GetAttribute("CurrentHP") or 1) <= 0 then
                    table.remove(activeZombies, i)
                end
            end
            task.wait(0.8)
        end

        local reward = 150 + (currentWave * 50)
        for _, p in ipairs(Players:GetPlayers()) do
            addPoints(p, reward)
            waveAnnounceEvent:FireClient(p, currentWave, string.format("🎉 WAVE %d CLEARED // กำจัดฝูงซอมบี้สำเร็จ! (+%d แต้ม)", currentWave, reward))
        end
        task.wait(4.5)
        currentWave = currentWave + 1
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    playerData[p.UserId] = { Points = 500, Kills = 0, Status = "Alive" }
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
    lastDamagedTime[player.UserId] = nil
    weaponStates[player.UserId] = nil
    if weaponStateConnections[player.UserId] then
        weaponStateConnections[player.UserId]:Disconnect()
        weaponStateConnections[player.UserId] = nil
    end
    broadcastScoreboard()
end)

task.spawn(startIntroSequence)
