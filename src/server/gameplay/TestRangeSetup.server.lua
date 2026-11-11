--[[
    TestRangeSetup.server.lua
    Developer showcase range: PUBG-style floor weapon pickups + stationary zombie size lineup.
    All pickups are server-authoritative and grant exactly one weapon in the player's only slot.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ServerScriptService = game:GetService("ServerScriptService")
local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons", 10)
local WeaponRegistry = require(weaponsFolder:WaitForChild("WeaponRegistry"))
local WeaponModelBuilder = require(weaponsFolder:WaitForChild("models"):WaitForChild("WeaponModelBuilder"))
local zombiesModuleFolder = ServerScriptService:WaitForChild("Zombies", 10)
local ZombieCatalog = require(zombiesModuleFolder:WaitForChild("ZombieCatalog"))
local ZombieModelFactory = require(zombiesModuleFolder:WaitForChild("ZombieModelFactory"))
local ZombieAnimationController = require(zombiesModuleFolder:WaitForChild("ZombieAnimationController"))
local ZombieAudioController = require(zombiesModuleFolder:WaitForChild("ZombieAudioController"))

local ROOT_NAME = "INFECTED_TestRange"
local old = Workspace:FindFirstChild(ROOT_NAME)
if old then old:Destroy() end

local remotes = ReplicatedStorage:FindFirstChild("WeaponPickupEvents") or Instance.new("Folder")
remotes.Name = "WeaponPickupEvents"
remotes.Parent = ReplicatedStorage

local granted = remotes:FindFirstChild("WeaponGranted") or Instance.new("RemoteEvent")
granted.Name = "WeaponGranted"
granted.Parent = remotes

local range = Instance.new("Model")
range.Name = ROOT_NAME
range.Parent = Workspace

local function part(parent, name, size, cf, color, material, anchored)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Anchored = anchored ~= false
    p.CanCollide = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function label(adornee, title, subtitle)
    local gui = Instance.new("BillboardGui")
    gui.Name = "DisplayLabel"
    gui.Size = UDim2.fromOffset(180, 52)
    gui.StudsOffset = Vector3.new(0, 2.2, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 180
    gui.Parent = adornee
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(12, 17, 24)
    text.BackgroundTransparency = 0.12
    text.TextColor3 = Color3.fromRGB(245, 245, 245)
    text.TextStrokeTransparency = 0.7
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Text = title .. "\n" .. subtitle
    text.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = text
    return text
end

-- Test range is intentionally outside the current playable building footprint.
part(range, "RangeFloor", Vector3.new(250, 2, 170), CFrame.new(0, 0, 470),
    Color3.fromRGB(75, 82, 77), Enum.Material.Concrete)
part(range, "WeaponDisplayTable", Vector3.new(210, 3, 48), CFrame.new(0, 3, 432),
    Color3.fromRGB(34, 39, 46), Enum.Material.Metal)

local weaponNames = {
    "Classic", "Shorty", "Frenzy", "Ghost", "Sheriff",
    "Stinger", "Spectre", "Bucky", "Judge",
    "Bulldog", "Guardian", "Phantom", "Vandal",
    "Marshal", "Outlaw", "Operator", "Ares", "Odin",
}

local function makeDisplayWeapon(parent, weaponName, position, index)
    local model = Instance.new("Model")
    model.Name = "Pickup_" .. weaponName
    model.Parent = parent

    -- Table top is at Y=4.5; lift pedestal & gun display above the table.
    local displayPosition = position + Vector3.new(0, 4.5, 0)
    local pedestal = part(model, "DisplayPedestal", Vector3.new(7, 0.7, 7),
        CFrame.new(displayPosition + Vector3.new(0, 0.35, 0)), Color3.fromRGB(24, 29, 35), Enum.Material.Metal)
    part(model, "DisplayCradle", Vector3.new(4.4, 0.18, 1.3),
        CFrame.new(displayPosition + Vector3.new(0, 0.79, 0)), Color3.fromRGB(46, 52, 62), Enum.Material.SmoothPlastic)

    local wCfg = WeaponRegistry.get(weaponName)
    local isSidearm = wCfg and (wCfg.Type == "Pistol" or wCfg.Type == "Revolver")
    local gunMountCF = CFrame.new(displayPosition + Vector3.new(0, 0.92, 0)) * CFrame.Angles(0, math.rad(90), 0)
    WeaponModelBuilder.buildDisplayModel(model, wCfg, gunMountCF, {
        anchorMode = "BottomCenter",
        scale = isSidearm and 1.35 or 1.05,
        maxLength = 5.8,
        castShadow = true,
    })

    label(pedestal, weaponName:upper(), "PRESS E TO PICK UP")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "PickupPrompt"
    prompt.ActionText = "หยิบ " .. weaponName
    prompt.ObjectText = weaponName
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = pedestal

    -- WaveAndZombieManager validates the server prompt, Range bounds, and
    -- player distance before granting this free test weapon.
end

for i, weaponName in ipairs(weaponNames) do
    local col = (i - 1) % 9
    local row = math.floor((i - 1) / 9)
    makeDisplayWeapon(range, weaponName, Vector3.new(-88 + col * 22, 0, 420 + row * 24), i)
end

-- Stationary zombie mannequins: Male, Female, Runner, and Male Boss lineup at true scale
local showcaseArchetypes = {
    "MaleWalker",
    "FemaleWalker",
    "MaleRunner",
    "FemaleRunner",
    "MaleBoss",
}

local zombieFolder = Instance.new("Folder")
zombieFolder.Name = "ZombieSizeLineup"
zombieFolder.Parent = range

local function createDummy(archetypeId, x)
    local arch = ZombieCatalog.get(archetypeId)
    local rig = ZombieModelFactory.build({
        zombieType = arch.Id,
        groundPos = Vector3.new(x, 1, 505),
        facingDeg = 180, -- Face toward shooting range spawn bay (Z = 395)
        anchored = true,
        anchorRootOnly = true,
        canCollideMain = false,
        modelName = "Preview_" .. arch.Id,
    })

    local model = rig.model
    local head = rig.head
    model.Parent = zombieFolder
    model:SetAttribute("IsZombie", true)
    model:SetAttribute("IsPreviewDummy", true)
    model:SetAttribute("ZombieType", arch.Id)
    model:SetAttribute("ZombieCategory", arch.Category)
    model:SetAttribute("ZombieGender", arch.Gender)
    model:SetAttribute("IsBoss", arch.IsBoss)
    model:SetAttribute("MaxHealth", arch.MaxHealth)
    model:SetAttribute("CurrentHP", arch.MaxHealth)
    model:SetAttribute("MoveSpeed", arch.WalkSpeed)

    -- Preview mannequins are non-blocking targets, but remain queryable by server weapon raycasts.
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = (descendant.Name ~= "HumanoidRootPart")
        end
    end

    local animCtrl = ZombieAnimationController.new(rig, arch)
    local audioCtrl = ZombieAudioController.new(rig, arch)
    model:GetAttributeChangedSignal("LastHitTime"):Connect(function()
        if not model:GetAttribute("IsDead") then
            animCtrl:setState("TakingDamage", 0.24, {
                isHeadshot = (model:GetAttribute("LastHitHeadshot") == true),
            })
            audioCtrl:triggerEvent("TakingDamage")
        end
    end)
    model:GetAttributeChangedSignal("IsDead"):Connect(function()
        if model:GetAttribute("IsDead") then
            animCtrl:setState("Death", nil, { deathTime = model:GetAttribute("DeathTime") or os.clock() })
            audioCtrl:triggerEvent("Death")
        else
            animCtrl:resetToIdle()
        end
    end)

    local nameTag = label(head, arch.DisplayName,
        string.format("%d / %d HP  |  HEIGHT %.2f STUDS", arch.MaxHealth, arch.MaxHealth, arch.TargetHeight))
    local function refreshTargetLabel()
        if not nameTag or not nameTag.Parent then return end
        if model:GetAttribute("IsDead") then
            nameTag.Text = arch.DisplayName .. "\nDOWN — RESPAWNING"
            return
        end
        local hp = model:GetAttribute("CurrentHP") or arch.MaxHealth
        nameTag.Text = string.format("%s\n%d / %d HP  |  HEIGHT %.2f STUDS",
            arch.DisplayName, math.max(0, math.floor(hp + 0.5)), arch.MaxHealth, arch.TargetHeight)
    end
    model:GetAttributeChangedSignal("CurrentHP"):Connect(refreshTargetLabel)
    model:GetAttributeChangedSignal("IsDead"):Connect(refreshTargetLabel)
end

for i, archetypeId in ipairs(showcaseArchetypes) do
    createDummy(archetypeId, -88 + (i - 1) * 44)
end

----------------------------------------------------------------------
-- Spawn Location & Fast Teleportation System for The Range
----------------------------------------------------------------------
local rangeSpawn = Instance.new("SpawnLocation")
rangeSpawn.Name = "TestRangeSpawnLocation"
rangeSpawn.Size = Vector3.new(12, 0.5, 12)
rangeSpawn.CFrame = CFrame.lookAt(Vector3.new(0, 1.25, 395), Vector3.new(0, 1.25, 432))
rangeSpawn.Color = Color3.fromRGB(0, 210, 160)
rangeSpawn.Material = Enum.Material.Neon
rangeSpawn.Transparency = 0.4
rangeSpawn.Anchored = true
rangeSpawn.CanCollide = false
rangeSpawn.Parent = range

local TARGET_RANGE_CF = CFrame.lookAt(Vector3.new(0, 3.5, 395), Vector3.new(0, 3.5, 432))
local TARGET_LOBBY_CF = CFrame.lookAt(Vector3.new(0, 3.5, 15), Vector3.new(0, 3.5, 40))

local function safeTeleport(character, targetCFrame)
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = targetCFrame
    end
end

local function createTeleportPad(parent, name, cframe, targetCFrame, color, title, promptText)
    local pad = Instance.new("Part")
    pad.Name = name
    pad.Size = Vector3.new(8, 0.6, 8)
    pad.CFrame = cframe
    pad.Color = color
    pad.Material = Enum.Material.Neon
    pad.Anchored = true
    pad.CanCollide = true
    pad.Parent = parent

    local gui = Instance.new("BillboardGui")
    gui.Name = "TeleportLabel"
    gui.Size = UDim2.fromOffset(200, 52)
    gui.StudsOffset = Vector3.new(0, 3.2, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 90
    gui.Parent = pad

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(12, 17, 24)
    text.BackgroundTransparency = 0.15
    text.TextColor3 = Color3.fromRGB(245, 245, 245)
    text.TextStrokeTransparency = 0.6
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Text = title
    text.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = text

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "WarpPrompt"
    prompt.ActionText = promptText
    prompt.ObjectText = "Teleporter"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = pad

    local lastUsed = {}
    local function doWarp(player)
        if not player or not player.Character then return end
        local now = os.clock()
        if (lastUsed[player] or 0) + 1.2 > now then return end
        lastUsed[player] = now
        safeTeleport(player.Character, targetCFrame)
    end

    prompt.Triggered:Connect(doWarp)

    pad.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            doWarp(player)
        end
    end)

    return pad
end

-- Teleporters
createTeleportPad(range, "RangeToLobbyPad",
    CFrame.new(-22, 1.3, 395),
    TARGET_LOBBY_CF,
    Color3.fromRGB(255, 140, 0),
    "🏢 RETURN TO BUILDING 40\nกลับตึก 40 ปี",
    "วาร์ปกลับตึก 40 ปี"
)

createTeleportPad(range, "LobbyToRangePad",
    CFrame.new(18, 1.3, 10),
    TARGET_RANGE_CF,
    Color3.fromRGB(0, 200, 255),
    "🎯 THE RANGE (สนามทดสอบอาวุธ)\n[18 WEAPONS + DUMMIES]",
    "วาร์ปไป The Range"
)

createTeleportPad(range, "PlazaToRangePad",
    CFrame.new(18, 5.5, 130),
    TARGET_RANGE_CF,
    Color3.fromRGB(0, 200, 255),
    "🎯 THE RANGE (สนามทดสอบอาวุธ)\n[18 WEAPONS + DUMMIES]",
    "วาร์ปไป The Range"
)

-- Chat Commands: /range and /lobby
local function bindChatCommands(player)
    player.Chatted:Connect(function(msg)
        local cmd = msg:lower():match("^%s*(%S+)")
        if cmd == "/range" or cmd == "!range" or cmd == "/the-range" or cmd == "/testrange" then
            safeTeleport(player.Character, TARGET_RANGE_CF)
        elseif cmd == "/lobby" or cmd == "!lobby" or cmd == "/spawn" or cmd == "/b40" then
            safeTeleport(player.Character, TARGET_LOBBY_CF)
        end
    end)
end

Players.PlayerAdded:Connect(bindChatCommands)
for _, p in ipairs(Players:GetPlayers()) do
    bindChatCommands(p)
end

-- Remote Events for Map Selector UI
local teleportEvents = ReplicatedStorage:FindFirstChild("TeleportEvents") or Instance.new("Folder")
teleportEvents.Name = "TeleportEvents"
teleportEvents.Parent = ReplicatedStorage

local requestTeleport = teleportEvents:FindFirstChild("RequestTeleport") or Instance.new("RemoteEvent")
requestTeleport.Name = "RequestTeleport"
requestTeleport.Parent = teleportEvents

local SERVER_DESTINATIONS = {
    TheRange = TARGET_RANGE_CF,
    Floor1 = TARGET_LOBBY_CF,
    Plaza = CFrame.lookAt(Vector3.new(0, 5.5, 125), Vector3.new(0, 5.5, 60)),
    Canteen = CFrame.lookAt(Vector3.new(0, 25.5, 10), Vector3.new(0, 25.5, 40)),
    SportsArena = CFrame.lookAt(Vector3.new(0, 47.5, 0), Vector3.new(0, 47.5, 30)),
    Rooftop = CFrame.lookAt(Vector3.new(0, 245.5, 0), Vector3.new(0, 245.5, 30)),
}

requestTeleport.OnServerEvent:Connect(function(player, destKey)
    local cf = SERVER_DESTINATIONS[destKey]
    if cf and player.Character then
        safeTeleport(player.Character, cf)
    end
end)

print("[TestRange] Built " .. #weaponNames .. " E-pickups, " .. #zombieSpecs .. " stationary zombie previews, teleporter pads, and /range chat command.")
