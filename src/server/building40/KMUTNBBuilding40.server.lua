--[[
    KMUTNBBuilding40.server.lua
    Builds a playable, detailed 11-storey KMUTNB 40th Anniversary Building (Building 77).

    Primary factual reference:
      https://kmutnb.ac.th/contact-us.aspx
      Building name and official use: Floor 1 (Bangkok Bank + Student Service Center),
      Floor 2 (canteen), Floors 3-11 (student activities, advising, discipline,
      indoor sports, and accommodation).

    Secondary scale/layout reference:
      KMUTNB architectural study, ACA 2025:
      https://archd.kmutnb.ac.th/upload/media/2025/06/9909685b972a793a3.pdf
      Approximate footprint 54 m x 48 m; 11 storeys; sports space around a central void.

    Notes:
      - Upper storeys use walkable decks, rooms, corridors, and an open atrium; no solid tower mass.
      - Floor functions are represented as a mixed student-activity building because the official
        directory does not assign each individual function to a specific upper floor.
      - Existing game integration names are preserved for the wave and barricade scripts.
]]

local Workspace = game:GetService("Workspace")

local BUILDING_NAME = "KMUTNB_Building40"
local STUDS_PER_METER = 2.5
local WIDTH = 54 * STUDS_PER_METER
local LENGTH = 48 * STUDS_PER_METER
local FLOOR_HEIGHT = 16
local FLOOR_COUNT = 11
local FLOOR1_Y = 4
local FRONT_Z = LENGTH / 2
local REAR_Z = -LENGTH / 2
local building

local COLORS = {
    cream = Color3.fromRGB(232, 225, 211),
    creamLight = Color3.fromRGB(245, 239, 226),
    warmGrey = Color3.fromRGB(164, 161, 153),
    darkGrey = Color3.fromRGB(68, 72, 76),
    orange = Color3.fromRGB(202, 105, 54),
    orangeLight = Color3.fromRGB(224, 139, 78),
    maroon = Color3.fromRGB(126, 34, 43),
    glass = Color3.fromRGB(112, 162, 178),
    floor = Color3.fromRGB(218, 215, 207),
    tileLight = Color3.fromRGB(235, 232, 222),
    tileDark = Color3.fromRGB(207, 204, 195),
    wood = Color3.fromRGB(130, 91, 58),
    steel = Color3.fromRGB(176, 181, 183),
    green = Color3.fromRGB(57, 105, 69),
}

local function makePart(parent, name, size, cframe, color, material, properties)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color or COLORS.cream
    part.Material = material or Enum.Material.Concrete
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CastShadow = true
    if properties then
        for key, value in pairs(properties) do
            part[key] = value
        end
    end
    part.Parent = parent
    return part
end

local function makeCylinder(parent, name, size, cframe, color, material, properties)
    local part = makePart(parent, name, size, cframe, color, material, properties)
    part.Shape = Enum.PartType.Cylinder
    return part
end

local function floorY(floorNumber)
    return FLOOR1_Y + (floorNumber - 1) * FLOOR_HEIGHT
end

local function makeSign(parent, name, text, size, position, face, color)
    local sign = makePart(
        parent,
        name,
        size,
        CFrame.new(position),
        color or COLORS.maroon,
        Enum.Material.SmoothPlastic
    )
    sign.CanCollide = false

    local surface = Instance.new("SurfaceGui")
    surface.Name = "SignSurface"
    surface.Face = face or Enum.NormalId.Back
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 48
    surface.LightInfluence = 0
    surface.Parent = sign

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.Parent = surface
    return sign
end

local function addPointLight(parent, name, position, color, range, brightness)
    local mount = makePart(
        parent,
        name .. "_Fixture",
        Vector3.new(3.2, 0.35, 1.2),
        CFrame.new(position),
        Color3.fromRGB(65, 66, 66),
        Enum.Material.Metal,
        {CanCollide = false}
    )
    local bulb = makePart(
        parent,
        name .. "_Diffuser",
        Vector3.new(2.8, 0.12, 0.9),
        CFrame.new(position - Vector3.new(0, 0.22, 0)),
        color,
        Enum.Material.Neon,
        {CanCollide = false}
    )
    local light = Instance.new("PointLight")
    light.Name = name .. "_Light"
    light.Color = color
    light.Range = range
    light.Brightness = brightness
    light.Shadows = true
    light.Parent = bulb
    return mount
end

local function addWindow(parent, name, width, height, cframe, rotationY, properties)
    local rotation = CFrame.Angles(0, rotationY or 0, 0)
    local windowCanCollide = not (properties and properties.CanCollide == false)
    local glass = makePart(
        parent,
        name .. "_Glass",
        Vector3.new(width, height, 0.45),
        cframe * rotation,
        COLORS.glass,
        Enum.Material.Glass,
        {
            Transparency = properties and properties.Transparency or 0.35,
            Reflectance = properties and properties.Reflectance or 0.08,
            CanCollide = windowCanCollide,
        }
    )
    local frameColor = COLORS.creamLight
    local frameDepth = 0.65
    makePart(parent, name .. "_FrameTop", Vector3.new(width + 0.8, 0.45, frameDepth), cframe * CFrame.new(0, height / 2 + 0.2, 0) * rotation, frameColor, Enum.Material.Concrete, {CanCollide = windowCanCollide})
    makePart(parent, name .. "_FrameBottom", Vector3.new(width + 0.8, 0.4, frameDepth), cframe * CFrame.new(0, -height / 2 - 0.2, 0) * rotation, frameColor, Enum.Material.Concrete, {CanCollide = windowCanCollide})
    makePart(parent, name .. "_Mullion", Vector3.new(0.3, height, frameDepth), cframe * rotation, COLORS.orange, Enum.Material.Metal, {CanCollide = windowCanCollide})
    return glass
end

local function addStairFlight(parent, lowerFloor, x, startZ)
    local startY = floorY(lowerFloor)
    local steps = 14
    local run = 1.25
    local rise = FLOOR_HEIGHT / steps
    local stairLength = (steps - 1) * run
    local direction = lowerFloor % 2 == 1 and -1 or 1
    startZ = lowerFloor % 2 == 1 and 25 or (25 - stairLength)
    for index = 1, steps do
        local stepY = startY + index * rise
        local stepZ = startZ + direction * index * run
        makePart(
            parent,
            "Stair_F" .. lowerFloor .. "_Step_" .. index,
            Vector3.new(10, 0.9, run + 0.15),
            CFrame.new(x, stepY, stepZ),
            COLORS.warmGrey,
            Enum.Material.Concrete
        )
    end

    local railLength = stairLength + 2
    local railCenterY = startY + FLOOR_HEIGHT / 2 + 3.4
    local railCenterZ = startZ + direction * stairLength / 2
    local railAngle = math.atan(FLOOR_HEIGHT / stairLength) * -direction
    for side = -1, 1, 2 do
        makePart(
            parent,
            "Stair_F" .. lowerFloor .. "_Handrail_" .. side,
            Vector3.new(0.35, 0.45, railLength),
            CFrame.new(x + side * 5.1, railCenterY, railCenterZ) * CFrame.Angles(railAngle, 0, 0),
            COLORS.darkGrey,
            Enum.Material.Metal
        )
    end

    makePart(
        parent,
        "Stair_F" .. lowerFloor .. "_UpperLanding",
        Vector3.new(11, 1, 8),
        CFrame.new(x, startY + FLOOR_HEIGHT - 0.4, startZ + direction * (stairLength + 3)),
        COLORS.tileDark,
        Enum.Material.Concrete
    )
end

-- Two outdoor stair flights flank the main entrance and reach the second-floor deck.
-- Their inward angle follows the reference photo while keeping clear of the central entry steps.
local function addFrontStaircase(parent, side)
    local stairName = side < 0 and "FrontStair_Left" or "FrontStair_Right"
    local stair = Instance.new("Model")
    stair.Name = stairName
    stair.Parent = parent

    local width = 13
    local stepCount = 20
    local bottomY = 0.6
    local topY = floorY(2) + 0.75
    local bottom = Vector3.new(side * (WIDTH / 2 - 1), bottomY, FRONT_Z + 40)
    local top = Vector3.new(side * 10.5, topY, FRONT_Z + 2.5)
    local dx = top.X - bottom.X
    local dz = top.Z - bottom.Z
    local horizontalLength = math.sqrt(dx * dx + dz * dz)
    local run = horizontalLength / stepCount
    local rise = (topY - bottomY) / stepCount
    local yaw = math.atan2(dx, dz)
    local direction = Vector3.new(dx / horizontalLength, 0, dz / horizontalLength)
    local across = Vector3.new(-direction.Z, 0, direction.X)
    local slopedLength = math.sqrt(horizontalLength * horizontalLength + (topY - bottomY) * (topY - bottomY))

    makePart(
        stair,
        "BottomLanding",
        Vector3.new(width + 2, 1, 7),
        CFrame.new(bottom.X, 0.1, bottom.Z) * CFrame.Angles(0, yaw, 0),
        COLORS.tileDark,
        Enum.Material.Concrete
    )

    for index = 1, stepCount do
        local progress = (index - 0.5) / stepCount
        local x = bottom.X + dx * progress
        local z = bottom.Z + dz * progress
        local treadTop = bottomY + rise * index
        makePart(
            stair,
            "Tread_" .. index,
            Vector3.new(width, 1.3, run + 0.12),
            CFrame.new(x, treadTop - 0.65, z) * CFrame.Angles(0, yaw, 0),
            index % 2 == 0 and COLORS.tileLight or COLORS.creamLight,
            Enum.Material.Concrete
        )
    end

    local midpoint = (bottom + top) / 2
    for edge = -1, 1, 2 do
        local edgePoint = midpoint + across * (edge * (width / 2 - 0.25))
        local stringerCenter = edgePoint - Vector3.new(0, 1.05, 0)
        makePart(
            stair,
            "ConcreteStringer_" .. edge,
            Vector3.new(0.8, 1.8, slopedLength),
            CFrame.lookAt(stringerCenter, stringerCenter + Vector3.new(dx, topY - bottomY, dz)),
            COLORS.warmGrey,
            Enum.Material.Concrete
        )

        local railOffset = across * (edge * (width / 2 + 0.55))
        for post = 0, 4 do
            local progress = post / 4
            local x = bottom.X + dx * progress + railOffset.X
            local y = bottomY + (topY - bottomY) * progress
            local z = bottom.Z + dz * progress + railOffset.Z
            makePart(
                stair,
                "HandrailPost_" .. edge .. "_" .. post,
                Vector3.new(0.35, 3.8, 0.35),
                CFrame.new(x, y + 1.9, z),
                COLORS.darkGrey,
                Enum.Material.Metal
            )
        end

        local railStart = bottom + railOffset + Vector3.new(0, 3.8, 0)
        local railEnd = top + railOffset + Vector3.new(0, 3.8, 0)
        makePart(
            stair,
            "Handrail_" .. edge,
            Vector3.new(0.45, 0.55, slopedLength),
            CFrame.lookAt((railStart + railEnd) / 2, railEnd),
            COLORS.darkGrey,
            Enum.Material.Metal
        )
    end

end

local function addElevatorBank(floorModel, floorNumber)
    local baseY = floorY(floorNumber)
    local lobbyWallZ = REAR_Z + 16
    makePart(
        floorModel,
        "ElevatorLobby_BackWall",
        Vector3.new(60, FLOOR_HEIGHT - 1, 1.2),
        CFrame.new(0, baseY + FLOOR_HEIGHT / 2, lobbyWallZ - 4),
        COLORS.warmGrey,
        Enum.Material.Concrete
    )
    for elevator = 1, 4 do
        local x = -24 + (elevator - 1) * 16
        local shaft = makePart(
            floorModel,
            "ElevatorShaft_F" .. floorNumber .. "_" .. elevator,
            Vector3.new(8.5, FLOOR_HEIGHT - 1, 9),
            CFrame.new(x, baseY + FLOOR_HEIGHT / 2, lobbyWallZ + 1),
            COLORS.darkGrey,
            Enum.Material.Concrete
        )
        shaft.Transparency = 0.15
        shaft.CanCollide = false

        local door = makePart(
            floorModel,
            "ElevatorDoor_F" .. floorNumber .. "_" .. elevator,
            Vector3.new(6.5, 10, 0.45),
            CFrame.new(x, baseY + 5.4, lobbyWallZ + 5.4),
            COLORS.steel,
            Enum.Material.Metal,
            {CanCollide = false}
        )
        if floorNumber == 2 then
            door.Name = "ZombieElevatorDoor_" .. elevator
        end

        makePart(
            floorModel,
            "ElevatorDoorSplit_F" .. floorNumber .. "_" .. elevator,
            Vector3.new(0.12, 9.5, 0.08),
            CFrame.new(x, baseY + 5.4, lobbyWallZ + 5.7),
            COLORS.darkGrey,
            Enum.Material.Metal,
            {CanCollide = false}
        )
        makePart(
            floorModel,
            "ElevatorIndicator_F" .. floorNumber .. "_" .. elevator,
            Vector3.new(1.8, 0.9, 0.3),
            CFrame.new(x, baseY + 11.4, lobbyWallZ + 5.6),
            Color3.fromRGB(255, 165, 64),
            Enum.Material.Neon,
            {CanCollide = false}
        )
    end
end

local function addBarricadeWindowFacade(floorModel, floorNumber, isFront)
    local baseY = floorY(floorNumber)
    local faceName = isFront and "Front" or "Rear"
    local wallZ = isFront and FRONT_Z - 0.4 or REAR_Z + 0.4
    local glassZ = isFront and FRONT_Z + 0.55 or REAR_Z - 0.55
    local windowCenters = {-30, 30}
    local windowFrameWidth = 12.8
    local stairEntryWidth = 36
    local stairEntryCenters = isFront and {0} or {}
    local openings = {}
    for _, centerX in ipairs(windowCenters) do
        table.insert(openings, {center = centerX, width = windowFrameWidth, kind = "Window"})
    end
    for _, centerX in ipairs(stairEntryCenters) do
        table.insert(openings, {center = centerX, width = stairEntryWidth, kind = "StairEntry"})
    end
    table.sort(openings, function(a, b)
        return a.center < b.center
    end)

    -- Sill segments close the floor-to-ceiling gap between windows while leaving
    -- the two barricade bays and front stair entries open.
    local sillStartX = -WIDTH / 2
    for index, opening in ipairs(openings) do
        local openingLeft = opening.center - opening.width / 2
        local sillWidth = openingLeft - sillStartX
        if sillWidth > 0 then
            makePart(
                floorModel,
                faceName .. "_CanteenWindowSill_" .. index,
                Vector3.new(sillWidth, 4, 1.4),
                CFrame.new(sillStartX + sillWidth / 2, baseY + 2.65, wallZ),
                COLORS.cream,
                Enum.Material.Concrete
            )
        end
        sillStartX = opening.center + opening.width / 2
    end
    local finalSillWidth = WIDTH / 2 - sillStartX
    if finalSillWidth > 0 then
        makePart(
            floorModel,
            faceName .. "_CanteenWindowSill_Final",
            Vector3.new(finalSillWidth, 4, 1.4),
            CFrame.new(sillStartX + finalSillWidth / 2, baseY + 2.65, wallZ),
            COLORS.cream,
            Enum.Material.Concrete
        )
    end
    makePart(
        floorModel,
        faceName .. "_CanteenWindowHeader",
        Vector3.new(WIDTH, 3.15, 1.4),
        CFrame.new(0, baseY + 13.8, wallZ),
        COLORS.cream,
        Enum.Material.Concrete
    )

    local leftEnd = -WIDTH / 2
    for index, opening in ipairs(openings) do
        local openingLeft = opening.center - opening.width / 2
        local openingRight = opening.center + opening.width / 2
        local segmentWidth = openingLeft - leftEnd
        if segmentWidth > 0 then
            makePart(
                floorModel,
                faceName .. "_CanteenWindowPier_" .. index,
                Vector3.new(segmentWidth, 7.5, 1.4),
                CFrame.new(leftEnd + segmentWidth / 2, baseY + 8.4, wallZ),
                COLORS.cream,
                Enum.Material.Concrete
            )
        end
        if opening.kind == "Window" then
            addWindow(
                floorModel,
                faceName .. "_BarricadeWindow_" .. index,
                12,
                7.5,
                CFrame.new(opening.center, baseY + 8.4, glassZ),
                isFront and 0 or math.rad(180),
                {CanCollide = false, Transparency = 0.58}
            )
        else
            makePart(
                floorModel,
                faceName .. "_StairEntryHeader_" .. index,
                Vector3.new(opening.width, 1.9, 1.4),
                CFrame.new(opening.center, baseY + 11.2, wallZ),
                COLORS.cream,
                Enum.Material.Concrete
            )
        end
        leftEnd = openingRight
    end
    local rightEnd = WIDTH / 2
    local finalPierWidth = rightEnd - leftEnd
    if finalPierWidth > 0 then
        makePart(
            floorModel,
            faceName .. "_CanteenWindowPier_Final",
            Vector3.new(finalPierWidth, 7.5, 1.4),
            CFrame.new(leftEnd + finalPierWidth / 2, baseY + 8.4, wallZ),
            COLORS.cream,
            Enum.Material.Concrete
        )
    end
end

local function addOuterWalls(floorModel, floorNumber)
    if floorNumber > 2 then
        return
    end
    local baseY = floorY(floorNumber)
    local wallCenterY = baseY + FLOOR_HEIGHT / 2
    local sideThickness = 1.6
    makePart(floorModel, "OuterWall_Left", Vector3.new(sideThickness, FLOOR_HEIGHT, LENGTH), CFrame.new(-WIDTH / 2, wallCenterY, 0), COLORS.cream, Enum.Material.Concrete)
    makePart(floorModel, "OuterWall_Right", Vector3.new(sideThickness, FLOOR_HEIGHT, LENGTH), CFrame.new(WIDTH / 2, wallCenterY, 0), COLORS.cream, Enum.Material.Concrete)
    if floorNumber == 1 then
        makePart(floorModel, "OuterWall_Rear", Vector3.new(WIDTH, FLOOR_HEIGHT, sideThickness), CFrame.new(0, wallCenterY, REAR_Z), COLORS.cream, Enum.Material.Concrete)
    elseif floorNumber == 2 then
        addBarricadeWindowFacade(floorModel, 2, true)
        addBarricadeWindowFacade(floorModel, 2, false)
    end
end

local function addBuildingFacade(level)
    local baseY = floorY(level)
    local midY = baseY + FLOOR_HEIGHT / 2
    local frontXStart = -WIDTH / 2 + 7
    local frontXEnd = WIDTH / 2 - 7
    local windowWidth = 7.6
    local windowGap = 3.5

    makePart(
        building,
        "FacadeBand_F" .. level,
        Vector3.new(WIDTH + 3, 1.3, 2.4),
        CFrame.new(0, baseY + FLOOR_HEIGHT - 1.2, FRONT_Z + 0.2),
        COLORS.orange,
        Enum.Material.Concrete
    )
    makePart(
        building,
        "FacadeSill_F" .. level,
        Vector3.new(WIDTH + 2, 0.9, 2.3),
        CFrame.new(0, baseY + 1.2, FRONT_Z + 0.2),
        COLORS.creamLight,
        Enum.Material.Concrete
    )
    -- Collision-backed parapets meet each glazing sill so the open upper floors
    -- remain safe to traverse without covering the transparent window area.
    makePart(
        building,
        "FrontSafetySill_F" .. level,
        Vector3.new(WIDTH - 2, 4, 1.4),
        CFrame.new(0, baseY + 2.6, FRONT_Z - 0.9),
        COLORS.cream,
        Enum.Material.Concrete
    )
    makePart(
        building,
        "RearSafetySill_F" .. level,
        Vector3.new(WIDTH - 2, 4, 1.4),
        CFrame.new(0, baseY + 2.6, REAR_Z + 0.9),
        COLORS.cream,
        Enum.Material.Concrete
    )
    for side = -1, 1, 2 do
        makePart(
            building,
            "SideSafetySill_F" .. level .. "_" .. side,
            Vector3.new(1.4, 4, LENGTH - 2),
            CFrame.new(side * (WIDTH / 2 - 0.9), baseY + 2.6, 0),
            COLORS.cream,
            Enum.Material.Concrete
        )
    end

    local windowStride = windowWidth + windowGap
    local frontCount = math.floor((frontXEnd - frontXStart) / windowStride) + 1
    local lastFrontX = frontXStart + (frontCount - 1) * windowStride
    for index = 0, frontCount - 1 do
        local x = frontXStart + index * windowStride
        addWindow(
            building,
            "FrontWindow_F" .. level .. "_" .. (index + 1),
            windowWidth,
            7.2,
            CFrame.new(x, midY + 0.2, FRONT_Z + 0.55),
            0
        )
    end

    local frameWidth = windowWidth + 0.8
    for index = 0, frontCount - 2 do
        local gapX = frontXStart + (index + 0.5) * windowStride
        local gapWidth = windowStride - frameWidth
        makePart(building, "FrontFacadeInfill_F" .. level .. "_" .. index, Vector3.new(gapWidth, 7.2, 0.65), CFrame.new(gapX, midY + 0.2, FRONT_Z + 0.55), COLORS.orangeLight, Enum.Material.Concrete)
        makePart(building, "RearFacadeInfill_F" .. level .. "_" .. index, Vector3.new(gapWidth, 7.2, 0.65), CFrame.new(gapX, midY + 0.2, REAR_Z - 0.55), COLORS.orangeLight, Enum.Material.Concrete)
    end
    local leftEndWidth = (frontXStart - frameWidth / 2) - (-WIDTH / 2)
    local rightEndWidth = (WIDTH / 2) - (lastFrontX + frameWidth / 2)
    if leftEndWidth > 0 then
        makePart(building, "FrontFacadeEnd_Left_F" .. level, Vector3.new(leftEndWidth, 7.2, 0.65), CFrame.new(-WIDTH / 2 + leftEndWidth / 2, midY + 0.2, FRONT_Z + 0.55), COLORS.cream, Enum.Material.Concrete)
        makePart(building, "RearFacadeEnd_Left_F" .. level, Vector3.new(leftEndWidth, 7.2, 0.65), CFrame.new(-WIDTH / 2 + leftEndWidth / 2, midY + 0.2, REAR_Z - 0.55), COLORS.cream, Enum.Material.Concrete)
    end
    if rightEndWidth > 0 then
        makePart(building, "FrontFacadeEnd_Right_F" .. level, Vector3.new(rightEndWidth, 7.2, 0.65), CFrame.new(WIDTH / 2 - rightEndWidth / 2, midY + 0.2, FRONT_Z + 0.55), COLORS.cream, Enum.Material.Concrete)
        makePart(building, "RearFacadeEnd_Right_F" .. level, Vector3.new(rightEndWidth, 7.2, 0.65), CFrame.new(WIDTH / 2 - rightEndWidth / 2, midY + 0.2, REAR_Z - 0.55), COLORS.cream, Enum.Material.Concrete)
    end

    local sideStartZ = REAR_Z + 9
    local sideEndZ = FRONT_Z - 8
    local sideCount = math.floor((sideEndZ - sideStartZ) / windowStride) + 1
    local lastSideZ = sideStartZ + (sideCount - 1) * windowStride
    for index = 0, sideCount - 1 do
        local z = sideStartZ + index * windowStride
        addWindow(
            building,
            "LeftWindow_F" .. level .. "_" .. (index + 1),
            windowWidth,
            7.2,
            CFrame.new(-WIDTH / 2 - 0.5, midY + 0.2, z),
            math.rad(90)
        )
        addWindow(
            building,
            "RightWindow_F" .. level .. "_" .. (index + 1),
            windowWidth,
            7.2,
            CFrame.new(WIDTH / 2 + 0.5, midY + 0.2, z),
            math.rad(90)
        )
        if index < sideCount - 1 then
            local gapZ = z + windowStride / 2
            local gapLength = windowStride - frameWidth
            for side = -1, 1, 2 do
                makePart(building, "SideFacadeInfill_F" .. level .. "_" .. side .. "_" .. index, Vector3.new(0.65, 7.2, gapLength), CFrame.new(side * (WIDTH / 2 + 0.5), midY + 0.2, gapZ), COLORS.orangeLight, Enum.Material.Concrete)
            end
        end
    end
    local sideFrameWidth = windowWidth + 0.8
    local rearEndLength = (sideStartZ - sideFrameWidth / 2) - REAR_Z
    local frontEndLength = FRONT_Z - (lastSideZ + sideFrameWidth / 2)
    if rearEndLength > 0 then
        for side = -1, 1, 2 do
            makePart(building, "SideFacadeEnd_Rear_F" .. level .. "_" .. side, Vector3.new(0.65, 7.2, rearEndLength), CFrame.new(side * (WIDTH / 2 + 0.5), midY + 0.2, REAR_Z + rearEndLength / 2), COLORS.cream, Enum.Material.Concrete)
        end
    end
    if frontEndLength > 0 then
        for side = -1, 1, 2 do
            makePart(building, "SideFacadeEnd_Front_F" .. level .. "_" .. side, Vector3.new(0.65, 7.2, frontEndLength), CFrame.new(side * (WIDTH / 2 + 0.5), midY + 0.2, FRONT_Z - frontEndLength / 2), COLORS.cream, Enum.Material.Concrete)
        end
    end

    for index = 0, frontCount - 1 do
        local x = frontXStart + index * windowStride
        addWindow(
            building,
            "RearWindow_F" .. level .. "_" .. (index + 1),
            windowWidth,
            7.2,
            CFrame.new(x, midY + 0.2, REAR_Z - 0.55),
            math.rad(180)
        )
    end

end

local oldBuilding = Workspace:FindFirstChild(BUILDING_NAME)
if oldBuilding then
    oldBuilding:Destroy()
end

building = Instance.new("Model")
building.Name = BUILDING_NAME
building.Parent = Workspace

-- Keep the game's night/day and horror lighting under the lighting manager's control.
-- The building adds local fixtures only.
local site = Instance.new("Model")
site.Name = "Building40_CampusApproach"
site.Parent = building

makePart(
    site,
    "CampusGround",
    Vector3.new(260, 2, 260),
    CFrame.new(0, -1, 4),
    Color3.fromRGB(52, 55, 56),
    Enum.Material.Asphalt
)
makePart(
    site,
    "EntrancePlaza",
    Vector3.new(WIDTH + 44, 1, LENGTH + 40),
    CFrame.new(0, 0.1, 2),
    Color3.fromRGB(184, 180, 169),
    Enum.Material.Concrete
)
makePart(
    site,
    "MainWalkway",
    Vector3.new(48, 0.22, 42),
    CFrame.new(0, 0.72, FRONT_Z + 23),
    COLORS.tileLight,
    Enum.Material.Slate,
    {CanCollide = true}
)
for x = -WIDTH / 2 - 13, WIDTH / 2 + 13, 13 do
    makePart(
        site,
        "PlazaJoint_" .. math.floor(x),
        Vector3.new(0.12, 0.04, LENGTH + 24),
        CFrame.new(x, 0.63, 0),
        Color3.fromRGB(150, 147, 139),
        Enum.Material.Concrete,
        {CanCollide = false}
    )
end

local function addPalmTree(x, z)
    local palm = Instance.new("Model")
    palm.Name = "CampusPalm"
    palm.Parent = site
    makeCylinder(
        palm,
        "Trunk",
        Vector3.new(15, 2.3, 2.3),
        CFrame.new(x, 8, z) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(112, 88, 64),
        Enum.Material.Wood
    )
    local crown = Vector3.new(x, 15, z)
    for frond = 1, 7 do
        local yaw = math.rad((frond - 1) * (360 / 7))
        local leaf = Instance.new("WedgePart")
        leaf.Name = "Frond_" .. frond
        leaf.Size = Vector3.new(2.6, 0.55, 10)
        leaf.CFrame = CFrame.new(crown + Vector3.new(math.sin(yaw) * 3.5, -0.8, math.cos(yaw) * 3.5))
            * CFrame.Angles(math.rad(-7), yaw, math.rad(12))
        leaf.Color = COLORS.green
        leaf.Material = Enum.Material.Grass
        leaf.Anchored = true
        leaf.CanCollide = false
        leaf.Parent = palm
    end
end

for _, x in ipairs({-54, -27, 27, 54}) do
    addPalmTree(x, FRONT_Z + 28)
end

-- Ground level: main public lobby, Bangkok Bank branch, student service centre.
local floor1 = Instance.new("Model")
floor1.Name = "Floor_1_MainLobby"
floor1.Parent = building

makePart(
    floor1,
    "Floor1_GraniteTile",
    Vector3.new(WIDTH, 1.5, LENGTH),
    CFrame.new(0, FLOOR1_Y, 0),
    COLORS.tileLight,
    Enum.Material.Slate
)
addOuterWalls(floor1, 1)

-- Main glass frontage with a wide entrance opening.
for _, x in ipairs({-48, -34, -20, 20, 34, 48}) do
    addWindow(
        floor1,
        "LobbyCurtainWall_" .. math.floor(x),
        11.5,
        11,
        CFrame.new(x, FLOOR1_Y + 8.8, FRONT_Z - 0.4),
        0
    )
end
for _, x in ipairs({-11, 11}) do
    makePart(
        floor1,
        "EntranceColumn_" .. x,
        Vector3.new(1.8, FLOOR_HEIGHT - 1, 2),
        CFrame.new(x, FLOOR1_Y + 7.8, FRONT_Z + 0.1),
        COLORS.warmGrey,
        Enum.Material.Concrete
    )
end
makePart(
    floor1,
    "MainEntranceCanopy",
    Vector3.new(12, 1.5, 17),
    CFrame.new(0, FLOOR1_Y + FLOOR_HEIGHT - 1.75, FRONT_Z + 7),
    COLORS.orange,
    Enum.Material.Concrete
)
makePart(
    floor1,
    "EntranceCanopyUnderside",
    Vector3.new(10.5, 0.22, 16),
    CFrame.new(0, FLOOR1_Y + FLOOR_HEIGHT - 2.4, FRONT_Z + 7),
    Color3.fromRGB(225, 218, 203),
    Enum.Material.SmoothPlastic
)

for step = 1, 5 do
    makePart(
        site,
        "EntranceStep_" .. step,
        Vector3.new(WIDTH * 0.68, 0.65, 2.4),
        CFrame.new(0, 0.85 + step * 0.72, FRONT_Z + 27 - step * 4.8),
        COLORS.warmGrey,
        Enum.Material.Concrete
    )
end

addFrontStaircase(site, -1)
addFrontStaircase(site, 1)
makePart(
    site,
    "FrontStair_CentralLanding",
    Vector3.new(36, 1, 9),
    CFrame.new(0, floorY(2) + 0.25, FRONT_Z + 2.5),
    COLORS.tileDark,
    Enum.Material.Concrete
)

makeSign(
    floor1,
    "Building40_MainSign",
    "อาคาร 40 ปี มจพ.\nกิจกรรมนักศึกษา (อาคาร 77)",
    Vector3.new(32, 4, 0.7),
    Vector3.new(0, FLOOR1_Y + 11.5, FRONT_Z + 0.35),
    Enum.NormalId.Back,
    COLORS.maroon
)
makeSign(
    floor1,
    "Building40_EnglishSign",
    "KMUTNB 40TH ANNIVERSARY BUILDING",
    Vector3.new(30, 2, 0.6),
    Vector3.new(0, FLOOR1_Y + 7.2, FRONT_Z + 0.35),
    Enum.NormalId.Back,
    COLORS.orange
)

-- Bangkok Bank: blue service counter, teller windows, queue markers, and ATMs.
local bank = Instance.new("Model")
bank.Name = "BangkokBank_Branch"
bank.Parent = floor1
makeSign(
    bank,
    "BankSign",
    "ธนาคารกรุงเทพ\nBANGKOK BANK",
    Vector3.new(25, 3.2, 0.6),
    Vector3.new(-42, FLOOR1_Y + 10.5, 17),
    Enum.NormalId.Back,
    Color3.fromRGB(0, 57, 123)
)
makePart(bank, "BankCounterBase", Vector3.new(25, 3.4, 4), CFrame.new(-42, FLOOR1_Y + 2.5, 16), Color3.fromRGB(230, 228, 219), Enum.Material.SmoothPlastic)
makePart(bank, "BankCounterTop", Vector3.new(26, 0.35, 4.4), CFrame.new(-42, FLOOR1_Y + 4.3, 16), COLORS.creamLight, Enum.Material.Marble)
for teller = 1, 3 do
    local x = -50 + teller * 8
    makePart(bank, "TellerGlass_" .. teller, Vector3.new(7, 3.4, 0.18), CFrame.new(x, FLOOR1_Y + 6.3, 13.7), COLORS.glass, Enum.Material.Glass, {Transparency = 0.45})
    makePart(bank, "TellerSlot_" .. teller, Vector3.new(1.6, 0.12, 0.7), CFrame.new(x, FLOOR1_Y + 4.9, 13.7), COLORS.darkGrey, Enum.Material.Metal)
end
for atm = 1, 2 do
    local x = -58 + atm * 7
    local machine = makePart(
        bank,
        "ATM_" .. atm,
        Vector3.new(3.2, 6, 2.2),
        CFrame.new(x, FLOOR1_Y + 3, 31),
        Color3.fromRGB(13, 54, 117),
        Enum.Material.Metal
    )
    makePart(bank, "ATM_Screen_" .. atm, Vector3.new(2.15, 1.35, 0.12), CFrame.new(x, FLOOR1_Y + 4.2, 29.8), Color3.fromRGB(95, 189, 211), Enum.Material.Neon, {CanCollide = false})
    makePart(bank, "ATM_Keypad_" .. atm, Vector3.new(1, 0.7, 0.18), CFrame.new(x + 0.65, FLOOR1_Y + 2.7, 29.8), COLORS.steel, Enum.Material.Metal)
    machine:SetAttribute("Facility", "Bangkok Bank")
end
for marker = 1, 3 do
    makePart(
        bank,
        "QueueMarker_" .. marker,
        Vector3.new(0.5, 3, 0.5),
        CFrame.new(-58 + marker * 8, FLOOR1_Y + 1.5, 7),
        COLORS.maroon,
        Enum.Material.Metal
    )
end

-- Student Service Center: reception desk, signs, and waiting area.
local service = Instance.new("Model")
service.Name = "StudentServiceCenter"
service.Parent = floor1
makeSign(
    service,
    "StudentServiceSign",
    "ศูนย์บริการนักศึกษา\nSTUDENT SERVICE CENTER",
    Vector3.new(31, 3, 0.65),
    Vector3.new(42, FLOOR1_Y + 10.5, 18),
    Enum.NormalId.Back,
    COLORS.maroon
)
makePart(service, "ReceptionDesk", Vector3.new(28, 3.4, 4.5), CFrame.new(42, FLOOR1_Y + 2.5, 17), COLORS.darkGrey, Enum.Material.WoodPlanks)
makePart(service, "ReceptionTop", Vector3.new(29, 0.35, 4.8), CFrame.new(42, FLOOR1_Y + 4.3, 17), COLORS.creamLight, Enum.Material.Marble)
for seat = 1, 4 do
    local x = 27 + seat * 7
    makePart(service, "WaitingSeat_" .. seat, Vector3.new(5, 1, 2), CFrame.new(x, FLOOR1_Y + 1.4, 32), COLORS.maroon, Enum.Material.SmoothPlastic)
    makePart(service, "WaitingSeatBack_" .. seat, Vector3.new(5, 2.3, 0.45), CFrame.new(x, FLOOR1_Y + 2.7, 33), COLORS.maroon, Enum.Material.SmoothPlastic)
end
addElevatorBank(floor1, 1)
addStairFlight(floor1, 1, 48, 25)
for x = -40, 40, 20 do
    addPointLight(floor1, "LobbyLight_" .. x, Vector3.new(x, FLOOR1_Y + FLOOR_HEIGHT - 2, 0), Color3.fromRGB(255, 241, 215), 26, 1.3)
end

local spawn = Instance.new("SpawnLocation")
spawn.Name = "PlazaSpawnLocation"
spawn.Size = Vector3.new(12, 1, 12)
spawn.CFrame = CFrame.new(0, 1.2, FRONT_Z + 29)
spawn.Anchored = true
spawn.CanCollide = false
spawn.Transparency = 1
spawn.Neutral = true
spawn.Parent = floor1

-- Floor 2: food court with counters, menu boards, tables, benches, and established barricade points.
local floor2 = Instance.new("Model")
floor2.Name = "Floor_2_Canteen"
floor2.Parent = building
local FLOOR2_Y = floorY(2)
makePart(floor2, "Floor2_Deck", Vector3.new(WIDTH, 1.5, LENGTH), CFrame.new(0, FLOOR2_Y, 0), COLORS.tileLight, Enum.Material.Slate)
addOuterWalls(floor2, 2)

makePart(floor2, "CanteenGuardrail", Vector3.new(WIDTH - 24, 2.2, 0.45), CFrame.new(0, FLOOR2_Y + 1.6, FRONT_Z - 3), COLORS.steel, Enum.Material.Metal)

local canteenSign = makeSign(
    floor2,
    "CanteenMainSign",
    "โรงอาหาร มจพ.\nKMUTNB CANTEEN",
    Vector3.new(28, 3.2, 0.6),
    Vector3.new(0, FLOOR2_Y + 11.5, FRONT_Z + 0.35),
    Enum.NormalId.Back,
    COLORS.orange
)

local function makeFoodStall(name, x, z, accent, menu)
    local stall = Instance.new("Model")
    stall.Name = name
    stall.Parent = floor2
    makePart(stall, "CounterBase", Vector3.new(19, 3.4, 5), CFrame.new(x, FLOOR2_Y + 2.6, z), COLORS.creamLight, Enum.Material.SmoothPlastic)
    makePart(stall, "CounterTop", Vector3.new(20, 0.35, 5.3), CFrame.new(x, FLOOR2_Y + 4.35, z), COLORS.steel, Enum.Material.Metal)
    makePart(stall, "BackCabinet", Vector3.new(17, 4.8, 2.5), CFrame.new(x, FLOOR2_Y + 6.6, z - 3.1), COLORS.cream, Enum.Material.WoodPlanks)
    makePart(stall, "GlassFoodCase", Vector3.new(11, 2.2, 2), CFrame.new(x - 2, FLOOR2_Y + 5.9, z + 2.2), COLORS.glass, Enum.Material.Glass, {Transparency = 0.4})
    makePart(stall, "Awning", Vector3.new(20, 0.6, 4), CFrame.new(x, FLOOR2_Y + 10, z + 1.5) * CFrame.Angles(math.rad(7), 0, 0), accent, Enum.Material.Fabric, {CanCollide = false})
    makeSign(
        stall,
        "MenuBoard",
        menu,
        Vector3.new(17, 2.5, 0.45),
        Vector3.new(x, FLOOR2_Y + 9, z - 4.45),
        Enum.NormalId.Back,
        accent
    )
    return stall
end

makeFoodStall("FoodStall_Rice", -42, -34, COLORS.maroon, "อาหารตามสั่ง\nRICE & CURRY")
makeFoodStall("FoodStall_Noodles", 0, -34, Color3.fromRGB(55, 101, 155), "ก๋วยเตี๋ยว\nNOODLES")
makeFoodStall("FoodStall_Drinks", 42, -34, COLORS.green, "เครื่องดื่ม\nDRINKS")

for row = 1, 3 do
    local z = -4 + row * 15
    for column = 1, 4 do
        local x = -43 + column * 22
        local tableModel = Instance.new("Model")
        tableModel.Name = "CanteenTable_" .. row .. "_" .. column
        tableModel.Parent = floor2
        makePart(tableModel, "TableTop", Vector3.new(11, 0.55, 4), CFrame.new(x, FLOOR2_Y + 3.6, z), COLORS.steel, Enum.Material.Metal)
        for legX = -1, 1, 2 do
            for legZ = -1, 1, 2 do
                makePart(tableModel, "Leg_" .. legX .. "_" .. legZ, Vector3.new(0.35, 2.6, 0.35), CFrame.new(x + legX * 4.7, FLOOR2_Y + 2.1, z + legZ * 1.5), COLORS.darkGrey, Enum.Material.Metal)
            end
        end
        for side = -1, 1, 2 do
            makePart(tableModel, "Bench_" .. side, Vector3.new(10, 1, 1.35), CFrame.new(x, FLOOR2_Y + 1.5, z + side * 4), COLORS.darkGrey, Enum.Material.Metal)
        end
    end
end

addElevatorBank(floor2, 2)
addStairFlight(floor2, 2, 48, 25)

local shutter = makePart(
    floor2,
    "SteelShutter_Floor3",
    Vector3.new(15, 11, 0.8),
    CFrame.new(50, FLOOR2_Y + 6.2, 4),
    COLORS.darkGrey,
    Enum.Material.Metal
)
shutter:SetAttribute("GameGate", true)
local shutterPrompt = Instance.new("ProximityPrompt")
shutterPrompt.ActionText = "เปิดทางไปชั้น 3"
shutterPrompt.ObjectText = "ชัตเตอร์รักษาความปลอดภัย"
shutterPrompt.HoldDuration = 1.5
shutterPrompt.MaxActivationDistance = 9
shutterPrompt.Parent = shutter

-- Barricade frames are kept at the same positions expected by BarricadeManager.
for _, x in ipairs({-30, 30}) do
    for _, z in ipairs({FRONT_Z - 1, REAR_Z + 1}) do
        makePart(
            floor2,
            "BarricadeWindowMarker_" .. x .. "_" .. math.floor(z),
            Vector3.new(12, 9, 0.2),
            CFrame.new(x, FLOOR2_Y + 7, z),
            COLORS.glass,
            Enum.Material.Glass,
            {Transparency = 0.78, CanCollide = false}
        )
    end
end

local wallBuys = Instance.new("Model")
wallBuys.Name = "WallBuys"
wallBuys.Parent = floor2

local function createWallBuy(name, weaponName, cost, position, angle)
    local plate = makePart(
        wallBuys,
        name,
        Vector3.new(7, 4, 0.5),
        CFrame.new(position) * CFrame.Angles(0, angle, 0),
        Color3.fromRGB(26, 28, 31),
        Enum.Material.Metal
    )
    plate.Name = weaponName
    plate:SetAttribute("Cost", cost)
    plate:SetAttribute("WeaponType", weaponName)
    local border = Instance.new("SelectionBox")
    border.Color3 = Color3.fromRGB(255, 202, 72)
    border.LineThickness = 0.06
    border.Adornee = plate
    border.Parent = plate
    local labelGui = Instance.new("SurfaceGui")
    labelGui.Name = "WeaponLabel"
    labelGui.Face = Enum.NormalId.Back
    labelGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    labelGui.PixelsPerStud = 48
    labelGui.LightInfluence = 0
    labelGui.Parent = plate
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 220, 80)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Text = weaponName .. "\n" .. cost .. " POINTS"
    label.Parent = labelGui
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "ซื้อ " .. weaponName
    prompt.ObjectText = cost .. " Points"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 9
    prompt.Parent = plate
    return plate
end

createWallBuy("Buy_Shotgun", "Shotgun Remington", 800, Vector3.new(-WIDTH / 2 + 3, FLOOR2_Y + 5, 12), math.rad(90))
createWallBuy("Buy_SMG", "SMG MP5", 1000, Vector3.new(-WIDTH / 2 + 3, FLOOR2_Y + 5, -12), math.rad(90))
createWallBuy("Buy_Rifle", "M4A1 Carbine", 1500, Vector3.new(WIDTH / 2 - 3, FLOOR2_Y + 5, 0), math.rad(-90))
createWallBuy("Buy_Ammo", "Ammo Refill", 300, Vector3.new(24, FLOOR2_Y + 5, FRONT_Z - 4), math.rad(180))
createWallBuy("Buy_Turret", "Sentry Turret", 1200, Vector3.new(49, FLOOR2_Y + 5, -12), math.rad(-90))

-- Floor 3: indoor sports, with clear circulation and a central multi-use court.
local floor3 = Instance.new("Model")
floor3.Name = "Floor_3_SportsArena"
floor3.Parent = building
local FLOOR3_Y = floorY(3)
makePart(floor3, "ArenaFloor", Vector3.new(WIDTH, 1.5, LENGTH), CFrame.new(0, FLOOR3_Y, 0), Color3.fromRGB(178, 126, 78), Enum.Material.WoodPlanks)
addOuterWalls(floor3, 3)
for x = -WIDTH / 2 + 8, WIDTH / 2 - 8, 16 do
    addWindow(floor3, "SportsFrontWindow_" .. math.floor(x), 7.5, 7, CFrame.new(x, FLOOR3_Y + 8.3, FRONT_Z + 0.55), 0)
end
addElevatorBank(floor3, 3)
addStairFlight(floor3, 3, 48, 25)
makeSign(
    floor3,
    "SportsHallSign",
    "สนามกีฬาในร่ม\nINDOOR SPORTS",
    Vector3.new(24, 2.7, 0.45),
    Vector3.new(0, FLOOR3_Y + 11, FRONT_Z - 1.5),
    Enum.NormalId.Back,
    COLORS.maroon
)

-- Painted multi-sport lines: one central play area, with separate badminton courts.
for _, x in ipairs({-24, 24}) do
    makePart(floor3, "BadmintonCourtSide_" .. x, Vector3.new(0.18, 0.08, 42), CFrame.new(x, FLOOR3_Y + 0.82, 2), Color3.fromRGB(248, 244, 225), Enum.Material.SmoothPlastic, {CanCollide = false})
end
for _, z in ipairs({-19, 2, 23}) do
    makePart(floor3, "BadmintonCourtEnd_" .. z, Vector3.new(48, 0.08, 0.18), CFrame.new(0, FLOOR3_Y + 0.82, z), Color3.fromRGB(248, 244, 225), Enum.Material.SmoothPlastic, {CanCollide = false})
end
makePart(floor3, "CenterLine", Vector3.new(0.18, 0.08, 42), CFrame.new(0, FLOOR3_Y + 0.83, 2), Color3.fromRGB(247, 247, 238), Enum.Material.SmoothPlastic, {CanCollide = false})
for court = 1, 2 do
    local x = court == 1 and -12 or 12
    makePart(floor3, "BadmintonNet_" .. court, Vector3.new(0.3, 4.2, 20), CFrame.new(x, FLOOR3_Y + 3, 2), Color3.fromRGB(54, 54, 58), Enum.Material.Fabric, {CanCollide = false, Transparency = 0.15})
end

local basketball = Instance.new("Model")
basketball.Name = "BasketballPractice"
basketball.Parent = floor3
makePart(basketball, "SupportArm", Vector3.new(0.6, 0.6, 7), CFrame.new(53, FLOOR3_Y + 10, 0) * CFrame.Angles(math.rad(-15), 0, 0), COLORS.darkGrey, Enum.Material.Metal)
makePart(basketball, "Backboard", Vector3.new(0.5, 5, 7), CFrame.new(53, FLOOR3_Y + 8, 4), COLORS.creamLight, Enum.Material.SmoothPlastic)
makePart(basketball, "BackboardTarget", Vector3.new(0.12, 1.5, 2), CFrame.new(52.65, FLOOR3_Y + 8.2, 4), COLORS.orange, Enum.Material.SmoothPlastic, {CanCollide = false})
makeCylinder(basketball, "BasketRim", Vector3.new(0.3, 2, 2), CFrame.new(50.6, FLOOR3_Y + 6.3, 4) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(216, 86, 43), Enum.Material.Metal)
for x = -42, 42, 21 do
    addPointLight(floor3, "SportsLight_" .. x, Vector3.new(x, FLOOR3_Y + FLOOR_HEIGHT - 1.5, 0), Color3.fromRGB(234, 240, 255), 36, 1.7)
end

-- Floors 4-11: accessible offices and student-use rooms with a lit perimeter corridor.
-- Floors 4 and 5 keep a central opening around the sports hall, with visible safety rails.
local function addAtriumDeck(floorModel, level)
    local y = floorY(level)
    local holeW, holeL = 34, 28
    local wingW = (WIDTH - holeW) / 2
    local frontD = (LENGTH - holeL) / 2
    makePart(floorModel, "Deck_LeftWing", Vector3.new(wingW, 1.3, LENGTH), CFrame.new(-holeW / 2 - wingW / 2, y, 0), COLORS.tileLight, Enum.Material.Slate)
    makePart(floorModel, "Deck_RightWing", Vector3.new(wingW, 1.3, LENGTH), CFrame.new(holeW / 2 + wingW / 2, y, 0), COLORS.tileLight, Enum.Material.Slate)
    makePart(floorModel, "Deck_FrontBridge", Vector3.new(holeW, 1.3, frontD), CFrame.new(0, y, holeL / 2 + frontD / 2), COLORS.tileLight, Enum.Material.Slate)
    makePart(floorModel, "Deck_RearBridge", Vector3.new(holeW, 1.3, frontD), CFrame.new(0, y, -holeL / 2 - frontD / 2), COLORS.tileLight, Enum.Material.Slate)

    for side = -1, 1, 2 do
        makePart(
            floorModel,
            "AtriumRail_" .. side,
            Vector3.new(0.45, 3.6, holeL),
            CFrame.new(side * (holeW / 2), y + 2.1, 0),
            COLORS.steel,
            Enum.Material.Metal
        )
        makePart(
            floorModel,
            "AtriumRail_Front_" .. side,
            Vector3.new(holeW / 2 - 0.3, 3.6, 0.45),
            CFrame.new(side * (holeW / 4), y + 2.1, holeL / 2),
            COLORS.steel,
            Enum.Material.Metal
        )
        makePart(
            floorModel,
            "AtriumRail_Rear_" .. side,
            Vector3.new(holeW / 2 - 0.3, 3.6, 0.45),
            CFrame.new(side * (holeW / 4), y + 2.1, -holeL / 2),
            COLORS.steel,
            Enum.Material.Metal
        )
    end
end

local function makeStudentRoom(floorModel, level, side, roomName, roomColor)
    local baseY = floorY(level)
    local roomX = side * 43
    local roomZ = -13
    local roomW, roomD = 34, 31

    local room = Instance.new("Model")
    room.Name = roomName
    room.Parent = floorModel

    makePart(room, "BackPartition", Vector3.new(roomW, 11, 0.7), CFrame.new(roomX, baseY + 6.5, roomZ - roomD / 2), COLORS.cream, Enum.Material.Concrete)
    makePart(room, "OuterPartition", Vector3.new(0.7, 11, roomD), CFrame.new(roomX + side * roomW / 2, baseY + 6.5, roomZ), COLORS.cream, Enum.Material.Concrete)
    makePart(room, "InnerPartitionA", Vector3.new(0.7, 11, roomD * 0.28), CFrame.new(roomX - side * roomW / 2, baseY + 6.5, roomZ - roomD * 0.36), COLORS.cream, Enum.Material.Concrete)
    makePart(room, "InnerPartitionB", Vector3.new(0.7, 11, roomD * 0.28), CFrame.new(roomX - side * roomW / 2, baseY + 6.5, roomZ + roomD * 0.36), COLORS.cream, Enum.Material.Concrete)
    makePart(room, "RoomHeader", Vector3.new(roomW - 2, 0.75, 0.6), CFrame.new(roomX, baseY + 12.3, roomZ + roomD / 2), roomColor, Enum.Material.Concrete)

    makeSign(
        room,
        "RoomSign",
        roomName == "StudentActivityRoom" and "กิจกรรมนักศึกษา" or "แนะแนวและบริการนักศึกษา",
        Vector3.new(18, 2, 0.35),
        Vector3.new(roomX, baseY + 10.7, roomZ + roomD / 2 + 0.4),
        Enum.NormalId.Back,
        roomColor
    )
    makePart(room, "WorkTable", Vector3.new(11, 2.5, 3.4), CFrame.new(roomX, baseY + 2.2, roomZ - 2), COLORS.wood, Enum.Material.WoodPlanks)
    makePart(room, "StorageCabinet", Vector3.new(4.5, 6, 2), CFrame.new(roomX + side * 11, baseY + 3.5, roomZ - 10), COLORS.warmGrey, Enum.Material.Wood)
    for chair = 1, 3 do
        local x = roomX - 5 + chair * 5
        makePart(room, "ChairSeat_" .. chair, Vector3.new(2.4, 0.55, 2.4), CFrame.new(x, baseY + 1.35, roomZ + 3), COLORS.darkGrey, Enum.Material.Metal)
        makePart(room, "ChairBack_" .. chair, Vector3.new(2.4, 2.2, 0.45), CFrame.new(x, baseY + 2.4, roomZ + 4), COLORS.darkGrey, Enum.Material.Metal)
    end

    return room
end

for level = 3, FLOOR_COUNT do
    addBuildingFacade(level)
end

for level = 4, FLOOR_COUNT do
    local floorModel = Instance.new("Model")
    floorModel.Name = "Floor_" .. level .. "_StudentActivities"
    floorModel.Parent = building

    if level <= 5 then
        addAtriumDeck(floorModel, level)
    else
        makePart(
            floorModel,
            "FloorDeck",
            Vector3.new(WIDTH, 1.3, LENGTH),
            CFrame.new(0, floorY(level), 0),
            COLORS.tileLight,
            Enum.Material.Slate
        )
    end

    addOuterWalls(floorModel, level)
    addElevatorBank(floorModel, level)
    addStairFlight(floorModel, level, 48, 25)

    makeStudentRoom(floorModel, level, -1, "StudentActivityRoom", level % 2 == 0 and COLORS.orange or COLORS.maroon)
    makeStudentRoom(floorModel, level, 1, "StudentSupportRoom", COLORS.orange)

    -- A long central corridor and wayfinding make every generated upper level navigable.
    if level > 5 then
        makePart(
            floorModel,
            "StudentActivityCorridor",
            Vector3.new(18, 0.16, 58),
            CFrame.new(0, floorY(level) + 0.76, -6),
            COLORS.tileDark,
            Enum.Material.Slate,
            {CanCollide = false}
        )
    end
    makeSign(
        floorModel,
        "FloorDirectory",
        "ชั้น " .. level .. "  |  STUDENT AFFAIRS",
        Vector3.new(15, 2.1, 0.35),
        Vector3.new(0, floorY(level) + 11.2, FRONT_Z - 1.2),
        Enum.NormalId.Back,
        COLORS.maroon
    )
    for x = -42, 42, 28 do
        addPointLight(floorModel, "UpperLight_F" .. level .. "_" .. x, Vector3.new(x, floorY(level) + FLOOR_HEIGHT - 2, -2), Color3.fromRGB(255, 239, 211), 22, 0.9)
    end
end

-- Roof: concrete parapet, water tanks, lift overrun, and maintenance equipment.
local roof = Instance.new("Model")
roof.Name = "Roof_Mechanical"
roof.Parent = building
local ROOF_Y = floorY(FLOOR_COUNT) + FLOOR_HEIGHT
makePart(
    roof,
    "RooftopSlab",
    Vector3.new(WIDTH + 4, 2, LENGTH + 4),
    CFrame.new(0, ROOF_Y + 1, 0),
    COLORS.warmGrey,
    Enum.Material.Concrete
)
for side = -1, 1, 2 do
    makePart(roof, "RoofParapet_" .. side, Vector3.new(WIDTH + 4, 3.5, 1.2), CFrame.new(0, ROOF_Y + 3.7, side * (LENGTH / 2 + 1)), COLORS.cream, Enum.Material.Concrete)
    makePart(roof, "RoofParapetSide_" .. side, Vector3.new(1.2, 3.5, LENGTH + 4), CFrame.new(side * (WIDTH / 2 + 1), ROOF_Y + 3.7, 0), COLORS.cream, Enum.Material.Concrete)
end
makePart(
    roof,
    "ElevatorOverrun",
    Vector3.new(42, 7, 26),
    CFrame.new(0, ROOF_Y + 5.5, REAR_Z + 18),
    COLORS.cream,
    Enum.Material.Concrete
)
for tank = 1, 3 do
    local x = (tank - 2) * 17
    makeCylinder(
        roof,
        "WaterTank_" .. tank,
        Vector3.new(9, 10, 9),
        CFrame.new(x, ROOF_Y + 7, 12) * CFrame.Angles(0, 0, math.rad(90)),
        COLORS.steel,
        Enum.Material.Metal
    )
    makePart(
        roof,
        "TankStand_" .. tank,
        Vector3.new(10, 1.2, 10),
        CFrame.new(x, ROOF_Y + 2.4, 12),
        COLORS.darkGrey,
        Enum.Material.Metal
    )
end
for unit = 1, 4 do
    local x = -27 + (unit - 1) * 18
    makePart(
        roof,
        "HVACUnit_" .. unit,
        Vector3.new(8, 4.2, 5),
        CFrame.new(x, ROOF_Y + 4.2, -12),
        COLORS.darkGrey,
        Enum.Material.Metal
    )
    for vent = 1, 4 do
        makePart(
            roof,
            "HVACVent_" .. unit .. "_" .. vent,
            Vector3.new(0.22, 2.9, 3.8),
            CFrame.new(x - 3 + vent * 1.2, ROOF_Y + 4.2, -9.2),
            COLORS.steel,
            Enum.Material.Metal
        )
    end
end

print("=========================================================")
print("KMUTNB Building 40 (Building 77), 11 floors, generated.")
print("Primary campus directory: floor 1 services, floor 2 canteen, floors 3-11 student affairs.")
print("=========================================================")

