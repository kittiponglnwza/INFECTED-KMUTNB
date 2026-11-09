--[[
    WallBuysSetup.lua
    โมดูลสร้างจุดซื้อปืนและกระสุนตามผนังโรงอาหาร (Wall-Buys)
]]

local PartBuilder = require(script.Parent.Parent.utils.PartBuilder)

local WallBuysSetup = {}

function WallBuysSetup.build(building)
    local wallBuys = Instance.new("Model")
    wallBuys.Name = "WallBuys"
    wallBuys.Parent = building

    local bW = PartBuilder.WIDTH
    local bL = PartBuilder.LENGTH
    local f2BaseY = PartBuilder.floorY(2)

    local function createWallBuy(name, weaponName, cost, position, normalAngle)
        local plate = PartBuilder.makePart(
            wallBuys,
            name,
            Vector3.new(6, 4, 0.4),
            CFrame.new(position) * CFrame.Angles(0, normalAngle, 0),
            Color3.fromRGB(25, 25, 30),
            Enum.Material.Metal
        )
        plate.Name = weaponName
        plate:SetAttribute("Cost", cost)
        plate:SetAttribute("WeaponType", weaponName)

        local outline = Instance.new("SelectionBox")
        outline.Color3 = Color3.fromRGB(255, 215, 0)
        outline.Adornee = plate
        outline.Parent = plate

        local gui = Instance.new("SurfaceGui")
        gui.Face = Enum.NormalId.Back
        gui.Parent = plate
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.fromRGB(255, 220, 80)
        txt.TextScaled = true
        txt.Font = Enum.Font.SpecialElite
        txt.Text = "🔫 " .. weaponName .. "\n[" .. cost .. " POINTS]"
        txt.Parent = gui

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "ซื้อ " .. weaponName
        prompt.ObjectText = cost .. " Points"
        prompt.HoldDuration = 0.5
        prompt.MaxActivationDistance = 9
        prompt.Parent = plate

        return plate
    end

    createWallBuy("Buy_Shotgun", "Shotgun Remington", 800, Vector3.new(-bW/2 + 2, f2BaseY + 5, 10), math.rad(90))
    createWallBuy("Buy_SMG", "SMG MP5", 1000, Vector3.new(-bW/2 + 2, f2BaseY + 5, -10), math.rad(90))
    createWallBuy("Buy_Rifle", "M4A1 Carbine", 1500, Vector3.new(bW/2 - 2, f2BaseY + 5, 0), math.rad(-90))
    createWallBuy("Buy_Ammo", "Ammo Refill", 300, Vector3.new(25, f2BaseY + 5, bL/2 - 2), math.rad(180))
    createWallBuy("Buy_Turret", "Sentry Turret", 1200, Vector3.new(50, f2BaseY + 5, 10), math.rad(-90))
end

return WallBuysSetup
