-- Server-created tactical weapon stations across Building 40.
-- Weapon names and prices are revalidated by WaveAndZombieManager; the prompt
-- attributes are for registration and readable in-world labels only.

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local WallBuysSetup = {}

local STATIONS = {
    { name = "Buy_Ghost_F1",    weapon = "Ghost",    category = "SIDEARM", cost = 500,  floorPos = Vector3.new(28.0, 1, 58),      yawDeg = 90 },
    { name = "Buy_Sheriff_F1",  weapon = "Sheriff",  category = "SIDEARM", cost = 800,  floorPos = Vector3.new(-28.0, 1, -58),    yawDeg = -90 },
    { name = "Buy_Bucky_F2",    weapon = "Bucky",    category = "SHOTGUN", cost = 900,  floorPos = Vector3.new(30.2, 23, 79),     yawDeg = 90 },
    { name = "Buy_Spectre_F3",  weapon = "Spectre",  category = "SMG",     cost = 1400, floorPos = Vector3.new(28.2, 45, 0),      yawDeg = 90 },
    { name = "Buy_Judge_F4",    weapon = "Judge",    category = "SHOTGUN", cost = 1600, floorPos = Vector3.new(49, 67, 84.2),     yawDeg = 0 },
    { name = "Buy_Vandal_F6",   weapon = "Vandal",   category = "RIFLE",   cost = 2600, floorPos = Vector3.new(49, 111, -84.2),   yawDeg = 180 },
    { name = "Buy_Phantom_F8",  weapon = "Phantom",  category = "RIFLE",   cost = 2600, floorPos = Vector3.new(-49, 155, 84.2),   yawDeg = 0 },
    { name = "Buy_Operator_F10",weapon = "Operator", category = "SNIPER",  cost = 4500, floorPos = Vector3.new(49, 199, 84.2),    yawDeg = 0 },
}

local function buildWeaponSilhouette(parent, baseCF, category)
    local gunMetal = Color3.fromRGB(38, 43, 52)
    local accent = Color3.fromRGB(245, 165, 45)
    local props = { CanCollide = false, CanQuery = false }

    if category == "SIDEARM" then
        PartBuilder.makePart(parent, "GunBody", Vector3.new(2.0, 0.45, 0.3), baseCF * CFrame.new(0, 4.3, -0.52), gunMetal, Enum.Material.Metal, props)
        PartBuilder.makePart(parent, "GunGrip", Vector3.new(0.42, 0.75, 0.28), baseCF * CFrame.new(-0.55, 3.85, -0.52) * CFrame.Angles(0, 0, math.rad(-14)), gunMetal, Enum.Material.SmoothPlastic, props)
        PartBuilder.makePart(parent, "GunTrim", Vector3.new(1.5, 0.14, 0.34), baseCF * CFrame.new(0.1, 4.45, -0.52), accent, Enum.Material.Neon, props)
    elseif category == "SNIPER" then
        PartBuilder.makePart(parent, "GunBody", Vector3.new(4.8, 0.55, 0.34), baseCF * CFrame.new(0, 4.2, -0.52), gunMetal, Enum.Material.Metal, props)
        PartBuilder.makePart(parent, "GunBarrel", Vector3.new(2.6, 0.2, 0.2), baseCF * CFrame.new(2.9, 4.28, -0.52), gunMetal, Enum.Material.Metal, props)
        PartBuilder.makePart(parent, "GunScope", Vector3.new(1.6, 0.28, 0.28), baseCF * CFrame.new(0.2, 4.65, -0.52), accent, Enum.Material.Metal, props)
    else
        PartBuilder.makePart(parent, "GunBody", Vector3.new(3.6, 0.55, 0.34), baseCF * CFrame.new(0, 4.2, -0.52), gunMetal, Enum.Material.Metal, props)
        PartBuilder.makePart(parent, "GunBarrel", Vector3.new(1.4, 0.22, 0.22), baseCF * CFrame.new(2.1, 4.28, -0.52), gunMetal, Enum.Material.Metal, props)
        PartBuilder.makePart(parent, "GunMag", Vector3.new(0.4, 0.9, 0.28), baseCF * CFrame.new(0.25, 3.65, -0.52) * CFrame.Angles(0, 0, math.rad(10)), accent, Enum.Material.SmoothPlastic, props)
    end
end

function WallBuysSetup.build(parent)
    local old = parent:FindFirstChild("MapWeaponBuys")
    if old then old:Destroy() end

    local stations = Instance.new("Model")
    stations.Name = "MapWeaponBuys"
    stations.Parent = parent

    for _, data in ipairs(STATIONS) do
        local stationModel = Instance.new("Model")
        stationModel.Name = data.name .. "_Model"
        stationModel.Parent = stations

        local stationCF = CFrame.new(data.floorPos) * CFrame.Angles(0, math.rad(data.yawDeg), 0)
        local refillCost = math.max(100, math.floor(data.cost * 0.5))

        -- Grounded military supply crate pedestal (Y = floorY..floorY+2.8)
        PartBuilder.makePart(
            stationModel,
            "SupplyCrate",
            Vector3.new(7.4, 2.8, 3.2),
            stationCF * CFrame.new(0, 1.4, 0),
            Color3.fromRGB(36, 44, 38),
            Enum.Material.Metal
        )
        PartBuilder.makePart(
            stationModel,
            "CrateTrim",
            Vector3.new(7.6, 0.22, 3.35),
            stationCF * CFrame.new(0, 2.75, 0),
            Color3.fromRGB(235, 175, 45),
            Enum.Material.Neon,
            { CanCollide = false }
        )

        -- Backboard display mounted above crate (Front faces -Z)
        local plate = PartBuilder.makePart(
            stationModel,
            data.name,
            Vector3.new(7.2, 4.2, 0.8),
            stationCF * CFrame.new(0, 5.0, 0.25),
            Color3.fromRGB(20, 26, 35),
            Enum.Material.Metal,
            { CanCollide = false }
        )
        plate:SetAttribute("WeaponName", data.weapon)
        plate:SetAttribute("Cost", data.cost)

        buildWeaponSilhouette(stationModel, stationCF, data.category)

        local face = Instance.new("SurfaceGui")
        face.Name = "WeaponBuyDisplay"
        face.Face = Enum.NormalId.Front
        face.PixelsPerStud = 42
        face.Parent = plate

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundColor3 = Color3.fromRGB(12, 17, 25)
        label.BackgroundTransparency = 0.08
        label.TextColor3 = Color3.fromRGB(255, 220, 95)
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.TextWrapped = true
        label.Text = string.format("[%s] %s\n%d PTS  |  AMMO %d\nHOLD [E]", data.category, data.weapon:upper(), data.cost, refillCost)
        label.Parent = face

        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "WorldWeaponBuyPrompt"
        prompt.ActionText = string.format("ซื้อ %s / เติมกระสุน", data.weapon)
        prompt.ObjectText = string.format("%d แต้ม (เติม %d)", data.cost, refillCost)
        prompt.HoldDuration = 0.5
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt:SetAttribute("WorldWeaponBuy", true)
        prompt:SetAttribute("WeaponName", data.weapon)
        prompt:SetAttribute("Cost", data.cost)
        prompt.Parent = plate
    end

    return stations
end

return WallBuysSetup
