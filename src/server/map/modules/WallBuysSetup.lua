-- Server-created tactical weapon stations across Building 40.
-- Weapon names and prices are revalidated by WaveAndZombieManager; the prompt
-- attributes are for registration and readable in-world labels only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons", 10)
local WeaponRegistry = require(weaponsFolder:WaitForChild("WeaponRegistry"))
local WeaponModelBuilder = require(weaponsFolder:WaitForChild("models"):WaitForChild("WeaponModelBuilder"))

local WallBuysSetup = {}

local STATIONS = {
    { name = "Buy_Ghost_F1",         weapon = "Ghost",   category = "SIDEARM", cost = 500,  floorPos = Vector3.new(28.0, 1, 58),     yawDeg = 90,  requiredTier = 0 },
    { name = "Buy_Sheriff_F1",       weapon = "Sheriff", category = "SIDEARM", cost = 800,  floorPos = Vector3.new(-28.0, 1, -58),   yawDeg = -90, requiredTier = 0 },
    { name = "Buy_Spectre_F1Armory", weapon = "Spectre", category = "SMG [TIER 1]", cost = 1200, floorPos = Vector3.new(-74.5, 1, 54.0), yawDeg = 90, requiredTier = 1, requiresOverride = true },
    { name = "Buy_Bucky_F2",         weapon = "Bucky",   category = "SHOTGUN [TIER 1]", cost = 900,  floorPos = Vector3.new(30.2, 23, 79),   yawDeg = 90, requiredTier = 1 },
    { name = "Buy_Spectre_F3",       weapon = "Spectre", category = "SMG [TIER 1]", cost = 1400, floorPos = Vector3.new(28.2, 45, 0),    yawDeg = 90, requiredTier = 1 },
    { name = "Buy_Judge_F4",         weapon = "Judge",   category = "SHOTGUN", cost = 1600, floorPos = Vector3.new(49, 67, 84.2),    yawDeg = 0,  requiredTier = 1 },
    { name = "Buy_Vandal_F6",        weapon = "Vandal",  category = "RIFLE",   cost = 2600, floorPos = Vector3.new(49, 111, -84.2),  yawDeg = 180, requiredTier = 1 },
    { name = "Buy_Phantom_F8",       weapon = "Phantom", category = "RIFLE",   cost = 2600, floorPos = Vector3.new(-49, 155, 84.2),  yawDeg = 0,  requiredTier = 2 },
    { name = "Buy_Operator_F10",     weapon = "Operator",category = "SNIPER",  cost = 4500, floorPos = Vector3.new(49, 199, 84.2),   yawDeg = 0,  requiredTier = 2 },
}

local function buildStationWeaponDisplay(parent, baseCF, weaponName)
    local wCfg = WeaponRegistry.get(weaponName)
    local isSidearm = wCfg and (wCfg.Type == "Pistol" or wCfg.Type == "Revolver")

    -- Tactical gun rack pad resting directly on top front shelf of the supply crate
    PartBuilder.makePart(
        parent,
        "GunRackPad",
        Vector3.new(4.8, 0.16, 1.15),
        baseCF * CFrame.new(0, 2.94, -0.88),
        Color3.fromRGB(24, 28, 34),
        Enum.Material.Metal,
        { CanCollide = false }
    )

    local gunCF = baseCF * CFrame.new(0, 3.04, -0.88) * CFrame.Angles(0, math.rad(90), 0)
    WeaponModelBuilder.buildDisplayModel(parent, wCfg, gunCF, {
        anchorMode = "BottomCenter",
        scale = isSidearm and 1.25 or 0.98,
        maxLength = 6.2,
        castShadow = true,
    })
end

local function buildSingleStation(stations, data)
    local stationModel = Instance.new("Model")
    stationModel.Name = data.name .. "_Model"
    stationModel.Parent = stations

    local stationCF = CFrame.new(data.floorPos) * CFrame.Angles(0, math.rad(data.yawDeg), 0)
    local refillCost = math.max(100, math.floor(data.cost * 0.5))

    PartBuilder.makePart(
        stationModel,
        "SupplyCrate",
        Vector3.new(7.4, 2.8, 3.2),
        stationCF * CFrame.new(0, 1.4, 0),
        Color3.fromRGB(36, 44, 38),
        Enum.Material.Metal
    )
    local trim = PartBuilder.makePart(
        stationModel,
        "CrateTrim",
        Vector3.new(7.6, 0.22, 3.35),
        stationCF * CFrame.new(0, 2.75, 0),
        (data.requiredTier or 0) > 0 and Color3.fromRGB(225, 70, 65) or Color3.fromRGB(235, 175, 45),
        Enum.Material.Neon,
        { CanCollide = false }
    )

    local plate = PartBuilder.makePart(
        stationModel,
        data.name,
        Vector3.new(7.2, 3.4, 0.6),
        stationCF * CFrame.new(0, 5.75, 0.35),
        Color3.fromRGB(20, 26, 35),
        Enum.Material.Metal,
        { CanCollide = false }
    )
    plate:SetAttribute("WeaponName", data.weapon)
    plate:SetAttribute("Cost", data.cost)
    plate:SetAttribute("RequiredClearanceTier", data.requiredTier or 0)
    plate:SetAttribute("RequiresOverrideDone", data.requiresOverride == true)

    buildStationWeaponDisplay(stationModel, stationCF, data.weapon)

    local face = Instance.new("SurfaceGui")
    face.Name = "WeaponBuyDisplay"
    face.Face = Enum.NormalId.Front
    face.PixelsPerStud = 42
    face.Parent = plate

    local label = Instance.new("TextLabel")
    label.Name = "StatusLabel"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(12, 17, 25)
    label.BackgroundTransparency = 0.08
    label.TextColor3 = Color3.fromRGB(255, 220, 95)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.Text = string.format("[%s] %s\n%d แต้ม  |  เติมกระสุน %d\nกดค้าง [E]", data.category, data.weapon:upper(), data.cost, refillCost)
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
    prompt:SetAttribute("RequiredClearanceTier", data.requiredTier or 0)
    prompt:SetAttribute("RequiresOverrideDone", data.requiresOverride == true)
    prompt.Parent = plate

    plate:SetAttribute("Category", data.category)
    plate:SetAttribute("RefillCost", refillCost)
    return stationModel, plate, trim, label, prompt
end

function WallBuysSetup.syncTierVisuals(parent, currentTier, overrideDone)
    local stations = parent:FindFirstChild("MapWeaponBuys")
    if not stations then return end
    local tier = tonumber(currentTier) or 0
    local ovDone = overrideDone == true

    for _, data in ipairs(STATIONS) do
        local m = stations:FindFirstChild(data.name .. "_Model")
        if m then
            local plate = m:FindFirstChild(data.name)
            local trim = m:FindFirstChild("CrateTrim")
            local prompt = plate and plate:FindFirstChild("WorldWeaponBuyPrompt")
            local face = plate and plate:FindFirstChild("WeaponBuyDisplay")
            local label = face and face:FindFirstChildOfClass("TextLabel")
            local reqTier = data.requiredTier or 0
            local locked = (tier < reqTier) or (data.requiresOverride == true and not ovDone)
            local refillCost = math.max(100, math.floor(data.cost * 0.5))

            if trim and trim:IsA("BasePart") then
                trim.Color = locked and Color3.fromRGB(225, 65, 60) or Color3.fromRGB(55, 225, 130)
            end
            if label then
                if locked then
                    label.TextColor3 = Color3.fromRGB(255, 110, 100)
                    label.Text = string.format("🔒 [ล็อก TIER %d] %s\nต้องผ่าน M1 ห้อง 102 ก่อน\nราคา %d แต้ม", reqTier, data.weapon:upper(), data.cost)
                else
                    label.TextColor3 = Color3.fromRGB(85, 245, 155)
                    label.Text = string.format("[%s] %s\n%d แต้ม  |  เติม %d\nกดค้าง [E]", data.category, data.weapon:upper(), data.cost, refillCost)
                end
            end
            if prompt then
                prompt.ActionText = locked
                    and string.format("🔒 ล็อก (ต้องใช้ Clearance Tier %d)", reqTier)
                    or string.format("ซื้อ %s / เติมกระสุน", data.weapon)
            end
        end
    end
end

function WallBuysSetup.ensureTierLocks(parent)
    local stations = parent:FindFirstChild("MapWeaponBuys")
    if not stations then
        return WallBuysSetup.build(parent)
    end
    for _, data in ipairs(STATIONS) do
        local m = stations:FindFirstChild(data.name .. "_Model")
        if not m then
            buildSingleStation(stations, data)
        else
            local plate = m:FindFirstChild(data.name)
            local prompt = plate and plate:FindFirstChild("WorldWeaponBuyPrompt")
            if plate then
                plate:SetAttribute("RequiredClearanceTier", data.requiredTier or 0)
                plate:SetAttribute("RequiresOverrideDone", data.requiresOverride == true)
            end
            if prompt then
                prompt:SetAttribute("RequiredClearanceTier", data.requiredTier or 0)
                prompt:SetAttribute("RequiresOverrideDone", data.requiresOverride == true)
            end
        end
    end
    WallBuysSetup.syncTierVisuals(parent, parent:GetAttribute("FloorClearanceTier") or 0, parent:GetAttribute("M1SecurityOverrideDone") == true)
    return stations
end

function WallBuysSetup.build(parent)
    local old = parent:FindFirstChild("MapWeaponBuys")
    if old then old:Destroy() end

    local stations = Instance.new("Model")
    stations.Name = "MapWeaponBuys"
    stations.Parent = parent

    for _, data in ipairs(STATIONS) do
        buildSingleStation(stations, data)
    end

    WallBuysSetup.syncTierVisuals(parent, parent:GetAttribute("FloorClearanceTier") or 0, parent:GetAttribute("M1SecurityOverrideDone") == true)
    return stations
end

return WallBuysSetup
