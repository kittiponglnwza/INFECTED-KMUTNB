--[[
    TestRangeSetup.server.lua
    Developer showcase range: PUBG-style floor weapon pickups + stationary zombie size lineup.
    All pickups are server-authoritative and grant exactly one weapon in the player's only slot.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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
    local color = (index % 2 == 0) and Color3.fromRGB(53, 59, 68) or Color3.fromRGB(91, 66, 48)
    -- Table top is at Y=4.5; lift every display part so it is visible above the table.
    local displayPosition = position + Vector3.new(0, 4.5, 0)
    local base = part(model, "Receiver", Vector3.new(1.15, 0.55, 3.2),
        CFrame.new(displayPosition + Vector3.new(0, 2.2, 0)), color, Enum.Material.Metal)
    part(model, "Barrel", Vector3.new(0.28, 0.28, 1.8),
        CFrame.new(displayPosition + Vector3.new(0, 2.28, -2.35)), Color3.fromRGB(28, 30, 34), Enum.Material.Metal)
    part(model, "Stock", Vector3.new(0.9, 0.5, 1.15),
        CFrame.new(displayPosition + Vector3.new(0, 2.15, 2.0)), Color3.fromRGB(36, 38, 42), Enum.Material.SmoothPlastic)
    part(model, "Grip", Vector3.new(0.45, 0.95, 0.55),
        CFrame.new(displayPosition + Vector3.new(0, 1.55, 0.7)), Color3.fromRGB(27, 28, 31), Enum.Material.SmoothPlastic)
    part(model, "DisplayPedestal", Vector3.new(7, 0.7, 7),
        CFrame.new(displayPosition + Vector3.new(0, 0.35, 0)), Color3.fromRGB(24, 29, 35), Enum.Material.Metal)
    label(base, weaponName:upper(), "PRESS E TO PICK UP")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "PickupPrompt"
    prompt.ActionText = "หยิบ " .. weaponName
    prompt.ObjectText = weaponName
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = base

    prompt.Triggered:Connect(function(player)
        if not player or not player:IsDescendantOf(Players) then return end
        local now = os.clock()
        local last = player:GetAttribute("LastWeaponPickupAt") or 0
        if now - last < 0.45 then return end
        player:SetAttribute("LastWeaponPickupAt", now)
        player:SetAttribute("EquippedWeapon", weaponName)
        granted:FireClient(player, weaponName)
    end)
end

for i, weaponName in ipairs(weaponNames) do
    local col = (i - 1) % 9
    local row = math.floor((i - 1) / 9)
    makeDisplayWeapon(range, weaponName, Vector3.new(-88 + col * 22, 0, 420 + row * 24), i)
end

-- Stationary zombie mannequins: scale tiers make size/health/speed differences easy to inspect.
local zombieSpecs = {
    { name = "CRAWLER", scale = 0.62, hp = 70, speed = 8, color = Color3.fromRGB(93, 105, 82) },
    { name = "WALKER", scale = 1.00, hp = 120, speed = 15, color = Color3.fromRGB(75, 105, 75) },
    { name = "RUNNER", scale = 0.92, hp = 90, speed = 19.5, color = Color3.fromRGB(130, 70, 65) },
    { name = "BRUTE", scale = 1.38, hp = 360, speed = 12, color = Color3.fromRGB(75, 45, 42) },
    { name = "TITAN", scale = 1.85, hp = 800, speed = 9, color = Color3.fromRGB(55, 48, 45) },
}

local zombieFolder = Instance.new("Folder")
zombieFolder.Name = "ZombieSizeLineup"
zombieFolder.Parent = range

local function createDummy(spec, x)
    local s = spec.scale
    local model = Instance.new("Model")
    model.Name = "Preview_" .. spec.name
    model.Parent = zombieFolder
    model:SetAttribute("IsZombie", true)
    model:SetAttribute("IsPreviewDummy", true)
    model:SetAttribute("ZombieType", spec.name)
    model:SetAttribute("MaxHealth", spec.hp)
    model:SetAttribute("CurrentHP", spec.hp)
    model:SetAttribute("MoveSpeed", spec.speed)

    local base = Vector3.new(x, 1, 505)
    local torso = part(model, "Torso", Vector3.new(2*s, 2.5*s, 1.1*s),
        CFrame.new(base + Vector3.new(0, 3.1*s, 0)), spec.color, Enum.Material.SmoothPlastic)
    local head = part(model, "Head", Vector3.new(1.35*s, 1.35*s, 1.35*s),
        CFrame.new(base + Vector3.new(0, 5.15*s, 0)), Color3.fromRGB(125, 145, 112), Enum.Material.SmoothPlastic)
    part(model, "LeftArm", Vector3.new(0.65*s, 2.3*s, 0.7*s),
        CFrame.new(base + Vector3.new(-1.35*s, 3.1*s, 0)), spec.color, Enum.Material.SmoothPlastic)
    part(model, "RightArm", Vector3.new(0.65*s, 2.3*s, 0.7*s),
        CFrame.new(base + Vector3.new(1.35*s, 3.1*s, 0)), spec.color, Enum.Material.SmoothPlastic)
    part(model, "LeftLeg", Vector3.new(0.8*s, 2.3*s, 0.85*s),
        CFrame.new(base + Vector3.new(-0.5*s, 1.15*s, 0)), Color3.fromRGB(42, 45, 49), Enum.Material.SmoothPlastic)
    part(model, "RightLeg", Vector3.new(0.8*s, 2.3*s, 0.85*s),
        CFrame.new(base + Vector3.new(0.5*s, 1.15*s, 0)), Color3.fromRGB(42, 45, 49), Enum.Material.SmoothPlastic)
    local eye = part(model, "Eyes", Vector3.new(0.75*s, 0.18*s, 0.12*s),
        CFrame.new(head.Position + Vector3.new(0, 0.05*s, -0.67*s)), Color3.fromRGB(255, 35, 35), Enum.Material.Neon)
    eye.CanCollide = false

    -- Preview mannequins are non-blocking targets, but remain queryable by server weapon raycasts.
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = true
        end
    end

    local nameTag = label(head, spec.name,
        string.format("%d / %d HP  |  SPEED %.1f  |  x%.2f", spec.hp, spec.hp, spec.speed, s))
    local function refreshTargetLabel()
        if not nameTag or not nameTag.Parent then return end
        if model:GetAttribute("IsDead") then
            nameTag.Text = spec.name .. "\nDOWN — RESPAWNING"
            return
        end
        local hp = model:GetAttribute("CurrentHP") or spec.hp
        nameTag.Text = string.format("%s\n%d / %d HP  |  SPEED %.1f  |  x%.2f",
            spec.name, math.max(0, math.floor(hp + 0.5)), spec.hp, spec.speed, s)
    end
    model:GetAttributeChangedSignal("CurrentHP"):Connect(refreshTargetLabel)
    model:GetAttributeChangedSignal("IsDead"):Connect(refreshTargetLabel)
    model.PrimaryPart = torso
end

for i, spec in ipairs(zombieSpecs) do
    createDummy(spec, -88 + (i - 1) * 44)
end

print("[TestRange] Built " .. #weaponNames .. " E-pickups and " .. #zombieSpecs .. " stationary zombie size previews.")
