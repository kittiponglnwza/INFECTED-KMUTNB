-- Server-owned grounded interaction stations for the 7-step Building 40 rescue campaign.
-- Each station can only complete the objective currently published by MissionService.

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

Workspace:WaitForChild("Floor_1_Building40", 60)
local signals = ServerStorage:WaitForChild("MissionSignals", 30)
local completeObjective = signals and signals:WaitForChild("CompleteObjective", 10)
if not completeObjective then
    warn("[MissionWorld] MissionService signal was not available; campaign stations were not created.")
    return
end

local oldStations = Workspace:FindFirstChild("CampaignStations")
if oldStations then oldStations:Destroy() end

local stationsFolder = Instance.new("Folder")
stationsFolder.Name = "CampaignStations"
stationsFolder.Parent = Workspace

local STATIONS = {
    {
        id = "SECURITY_ACCESS",
        title = "บัตรผ่านห้องรักษาความปลอดภัย (ชั้น 1)",
        action = "เก็บบัตรผ่าน",
        floorPos = Vector3.new(-26, 1, 58),
        yawDeg = -90,
        color = Color3.fromRGB(70, 170, 255),
    },
    {
        id = "RESTORE_POWER",
        title = "แผงควบคุมเครื่องกำเนิดไฟฟ้า (ชั้น 2)",
        action = "กู้คืนระบบไฟ",
        floorPos = Vector3.new(67.8, 23, 79),
        yawDeg = -90,
        color = Color3.fromRGB(255, 190, 55),
    },
    {
        id = "DECODE_SAFE",
        title = "ตู้เซฟห้องเอกสาร / ธนาคาร (ชั้น 1)",
        action = "ถอดรหัสตู้เซฟ",
        floorPos = Vector3.new(118, 1, 49.5),
        yawDeg = 180,
        color = Color3.fromRGB(80, 210, 130),
    },
    {
        id = "CALL_RESCUE",
        title = "วิทยุสื่อสารฉุกเฉิน (ชั้น 3)",
        action = "ส่งสัญญาณขอความช่วยเหลือ",
        floorPos = Vector3.new(-74, 45, 84.0),
        yawDeg = 0,
        color = Color3.fromRGB(255, 95, 75),
    },
    {
        id = "REACH_ROOF",
        title = "จุดรายงานตัวชั้นบนสุด (ชั้น 12)",
        action = "ยืนยันการขึ้นชั้นบนสุด",
        floorPos = Vector3.new(0, 243, 76),
        yawDeg = 0,
        color = Color3.fromRGB(120, 190, 255),
    },
    {
        id = "ACTIVATE_BEACON",
        title = "Beacon จุดรับตัว (ชั้น 12)",
        action = "เปิดสัญญาณ Beacon",
        floorPos = Vector3.new(22, 243, 0),
        yawDeg = -90,
        color = Color3.fromRGB(255, 70, 70),
    },
    {
        id = "BOARD_HELICOPTER",
        title = "เฮลิคอปเตอร์กู้ภัย (ชั้น 12 สนามฝั่งตะวันออก)",
        action = "ขึ้นเฮลิคอปเตอร์อพยพ",
        floorPos = Vector3.new(82, 243, -24),
        yawDeg = 90,
        color = Color3.fromRGB(75, 220, 170),
    },
}

local function makeProp(parent, name, size, cf, color, material, extra)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if extra then
        for k, v in pairs(extra) do
            p[k] = v
        end
    end
    p.Parent = parent
    return p
end

local function buildStationProps(station, cf, id, accentColor)
    if id == "SECURITY_ACCESS" then
        makeProp(station, "GuardDesk", Vector3.new(6.0, 3.2, 3.0), cf * CFrame.new(0, 1.6, 0), Color3.fromRGB(48, 56, 68), Enum.Material.SmoothPlastic)
        makeProp(station, "MonitorScreen", Vector3.new(2.6, 1.7, 0.25), cf * CFrame.new(-0.8, 4.2, -0.3), accentColor, Enum.Material.Neon, { CanCollide = false })
        makeProp(station, "KeycardPad", Vector3.new(1.2, 0.3, 0.9), cf * CFrame.new(1.5, 3.35, -0.6), Color3.fromRGB(185, 220, 255), Enum.Material.Neon, { CanCollide = false })
    elseif id == "RESTORE_POWER" then
        makeProp(station, "GeneratorBlock", Vector3.new(6.2, 4.6, 3.4), cf * CFrame.new(0, 2.3, 0), Color3.fromRGB(68, 74, 80), Enum.Material.Metal)
        makeProp(station, "HazardBand", Vector3.new(6.4, 0.65, 3.55), cf * CFrame.new(0, 0.45, 0), Color3.fromRGB(235, 175, 35), Enum.Material.SmoothPlastic, { CanCollide = false })
        makeProp(station, "BreakerMeter", Vector3.new(2.4, 1.6, 0.25), cf * CFrame.new(0, 3.4, -1.75), accentColor, Enum.Material.Neon, { CanCollide = false })
    elseif id == "DECODE_SAFE" then
        makeProp(station, "VaultCabinet", Vector3.new(5.0, 6.2, 4.2), cf * CFrame.new(0, 3.1, 0), Color3.fromRGB(36, 40, 48), Enum.Material.Metal)
        makeProp(station, "VaultDoor", Vector3.new(4.0, 5.0, 0.35), cf * CFrame.new(0, 3.1, -2.12), Color3.fromRGB(72, 78, 88), Enum.Material.Metal)
        makeProp(station, "VaultDial", Vector3.new(1.2, 1.2, 0.35), cf * CFrame.new(-0.8, 3.3, -2.35), Color3.fromRGB(190, 195, 205), Enum.Material.Metal, { CanCollide = false })
        makeProp(station, "KeypadDisplay", Vector3.new(1.1, 1.4, 0.2), cf * CFrame.new(1.0, 3.3, -2.32), accentColor, Enum.Material.Neon, { CanCollide = false })
    elseif id == "CALL_RESCUE" then
        makeProp(station, "RadioDesk", Vector3.new(5.8, 3.0, 3.0), cf * CFrame.new(0, 1.5, 0), Color3.fromRGB(62, 68, 56), Enum.Material.Metal)
        makeProp(station, "TransceiverBox", Vector3.new(2.8, 1.8, 1.8), cf * CFrame.new(0, 3.9, 0.2), Color3.fromRGB(40, 46, 42), Enum.Material.Metal)
        makeProp(station, "RadioFreqGlow", Vector3.new(1.8, 0.9, 0.2), cf * CFrame.new(0, 4.0, -0.75), accentColor, Enum.Material.Neon, { CanCollide = false })
        makeProp(station, "AntennaMast", Vector3.new(0.2, 5.2, 0.2), cf * CFrame.new(1.9, 5.4, 0.6), Color3.fromRGB(175, 180, 188), Enum.Material.Metal, { CanCollide = false })
    elseif id == "REACH_ROOF" then
        makeProp(station, "CheckInPlinth", Vector3.new(4.4, 3.4, 3.0), cf * CFrame.new(0, 1.7, 0), Color3.fromRGB(45, 52, 64), Enum.Material.Concrete)
        makeProp(station, "GuidePillar", Vector3.new(1.1, 7.2, 1.1), cf * CFrame.new(0, 3.6, 0.7), Color3.fromRGB(62, 70, 82), Enum.Material.Metal, { CanCollide = false })
        makeProp(station, "TopFlareLamp", Vector3.new(1.6, 1.0, 1.6), cf * CFrame.new(0, 7.6, 0.7), accentColor, Enum.Material.Neon, { CanCollide = false })
    elseif id == "ACTIVATE_BEACON" then
        makeProp(station, "BeaconBase", Vector3.new(4.8, 2.2, 4.8), cf * CFrame.new(0, 1.1, 0), Color3.fromRGB(44, 48, 56), Enum.Material.Metal)
        makeProp(station, "BeaconMast", Vector3.new(0.9, 6.8, 0.9), cf * CFrame.new(0, 4.5, 0), Color3.fromRGB(165, 170, 180), Enum.Material.Metal, { CanCollide = false })
        makeProp(station, "BeaconCore", Vector3.new(2.0, 2.0, 2.0), cf * CFrame.new(0, 8.5, 0), accentColor, Enum.Material.Neon, { CanCollide = false })
    elseif id == "BOARD_HELICOPTER" then
        -- Helipad markings grounded flat at floorY (243.0)
        makeProp(station, "HelipadDeck", Vector3.new(30, 0.14, 30), cf * CFrame.new(0, 0.08, 4), Color3.fromRGB(40, 46, 54), Enum.Material.Asphalt, { CanCollide = false })
        makeProp(station, "HeliMark_L", Vector3.new(1.8, 0.16, 12), cf * CFrame.new(-4.5, 0.11, 4), Color3.fromRGB(245, 200, 45), Enum.Material.Neon, { CanCollide = false })
        makeProp(station, "HeliMark_R", Vector3.new(1.8, 0.16, 12), cf * CFrame.new(4.5, 0.11, 4), Color3.fromRGB(245, 200, 45), Enum.Material.Neon, { CanCollide = false })
        makeProp(station, "HeliMark_Mid", Vector3.new(9.0, 0.16, 1.8), cf * CFrame.new(0, 0.11, 4), Color3.fromRGB(245, 200, 45), Enum.Material.Neon, { CanCollide = false })
        for _, cx in ipairs({ -13.5, 13.5 }) do
            for _, cz in ipairs({ -9.5, 17.5 }) do
                makeProp(station, "PadBeacon_" .. cx .. "_" .. cz, Vector3.new(1.0, 0.7, 1.0), cf * CFrame.new(cx, 0.4, cz), accentColor, Enum.Material.Neon, { CanCollide = false })
            end
        end
        -- Stylized compact Rescue Medevac Helicopter landed cleanly under Floor 12 trusses (height ~10.5 studs)
        local heliCF = cf * CFrame.new(0, 0, 4)
        makeProp(station, "HeliSkid_L", Vector3.new(1.0, 0.5, 14.0), heliCF * CFrame.new(-4.2, 0.45, 0), Color3.fromRGB(60, 66, 74), Enum.Material.Metal)
        makeProp(station, "HeliSkid_R", Vector3.new(1.0, 0.5, 14.0), heliCF * CFrame.new(4.2, 0.45, 0), Color3.fromRGB(60, 66, 74), Enum.Material.Metal)
        makeProp(station, "HeliCabin", Vector3.new(7.4, 5.2, 14.0), heliCF * CFrame.new(0, 4.0, 0), Color3.fromRGB(48, 86, 68), Enum.Material.Metal)
        makeProp(station, "HeliStripe", Vector3.new(7.6, 0.9, 14.2), heliCF * CFrame.new(0, 3.2, 0), Color3.fromRGB(245, 195, 50), Enum.Material.SmoothPlastic, { CanCollide = false })
        makeProp(station, "HeliCockpit", Vector3.new(6.8, 3.4, 4.4), heliCF * CFrame.new(0, 3.8, -8.2), Color3.fromRGB(130, 195, 225), Enum.Material.Glass, { Transparency = 0.35 })
        makeProp(station, "HeliTailBoom", Vector3.new(2.2, 2.2, 13.0), heliCF * CFrame.new(0, 5.2, 13.0), Color3.fromRGB(48, 86, 68), Enum.Material.Metal)
        makeProp(station, "HeliTailFin", Vector3.new(0.6, 4.2, 2.6), heliCF * CFrame.new(0, 6.8, 19.0), Color3.fromRGB(235, 80, 60), Enum.Material.Metal)
        makeProp(station, "HeliRotorHub", Vector3.new(1.8, 1.4, 1.8), heliCF * CFrame.new(0, 7.3, 0), Color3.fromRGB(40, 44, 50), Enum.Material.Metal, { CanCollide = false })
        makeProp(station, "HeliMainRotor_A", Vector3.new(24.0, 0.25, 1.1), heliCF * CFrame.new(0, 8.1, 0) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(32, 36, 42), Enum.Material.Metal, { CanCollide = false })
        makeProp(station, "HeliMainRotor_B", Vector3.new(1.1, 0.25, 24.0), heliCF * CFrame.new(0, 8.1, 0) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(32, 36, 42), Enum.Material.Metal, { CanCollide = false })
        -- Boarding console next to helicopter cabin door
        makeProp(station, "BoardingConsolePedestal", Vector3.new(3.2, 3.0, 2.0), cf * CFrame.new(0, 1.5, -9.0), Color3.fromRGB(40, 50, 60), Enum.Material.Metal)
    end
end

local promptsByObjective = {}
local function refreshStations()
    local currentId = Workspace:GetAttribute("CurrentObjectiveId")
    for objectiveId, entry in pairs(promptsByObjective) do
        local active = currentId == objectiveId
        entry.prompt.Enabled = active
        entry.part.Color = active and entry.activeColor or Color3.fromRGB(48, 55, 65)
        entry.part.Material = active and Enum.Material.Neon or Enum.Material.Metal
        if entry.beaconLight then
            entry.beaconLight.Enabled = active
        end
    end
end

for index, data in ipairs(STATIONS) do
    local station = Instance.new("Model")
    station.Name = "CampaignStation_" .. data.id
    station.Parent = stationsFolder

    local cf = CFrame.new(data.floorPos) * CFrame.Angles(0, math.rad(data.yawDeg or 0), 0)
    buildStationProps(station, cf, data.id, data.color)

    local consoleOffset = (data.id == "BOARD_HELICOPTER") and CFrame.new(0, 3.2, -9.0) or CFrame.new(0, 3.4, -0.8)
    local base = Instance.new("Part")
    base.Name = "InteractionConsole"
    base.Size = Vector3.new(2.8, 1.2, 1.2)
    base.CFrame = cf * consoleOffset
    base.Anchored = true
    base.CanCollide = false
    base.Material = Enum.Material.Metal
    base.Color = Color3.fromRGB(48, 55, 65)
    base:SetAttribute("MissionObjectiveId", data.id)
    base.Parent = station
    station.PrimaryPart = base

    local beaconLight = Instance.new("PointLight")
    beaconLight.Color = data.color
    beaconLight.Brightness = 2.4
    beaconLight.Range = 22
    beaconLight.Enabled = false
    beaconLight.Parent = base

    local label = Instance.new("BillboardGui")
    label.Name = "StationLabel"
    label.Size = UDim2.fromOffset(230, 56)
    label.StudsOffset = Vector3.new(0, 3.0, 0)
    label.AlwaysOnTop = true
    label.MaxDistance = 85
    label.Parent = base

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(12, 17, 24)
    text.BackgroundTransparency = 0.12
    text.TextColor3 = data.color
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.TextWrapped = true
    text.Text = string.format("%02d  |  %s", index, data.title)
    text.Parent = label

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "MissionPrompt"
    prompt.ActionText = data.action
    prompt.ObjectText = data.title
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 1
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Enabled = false
    prompt.Parent = base

    promptsByObjective[data.id] = {
        prompt = prompt,
        part = base,
        activeColor = data.color,
        beaconLight = beaconLight,
    }
    prompt.Triggered:Connect(function(player)
        if Workspace:GetAttribute("CurrentObjectiveId") ~= data.id then return end
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or (root.Position - base.Position).Magnitude > prompt.MaxActivationDistance + 4 then return end
        prompt.Enabled = false
        completeObjective:Fire(data.id, player)
    end)
end

Workspace:GetAttributeChangedSignal("CurrentObjectiveId"):Connect(refreshStations)
refreshStations()
print("[MissionWorld] Built the seven grounded server-validated campaign stations & extraction helipad.")
