--[[
    StudioStageBuilder.lua
    Builds and tears down an isolated per-client Dark 3D Studio Cyclorama Booth
    so each player can inspect a single centered model with 3-point studio
    lighting and zero background clutter or multiplayer interference.
]]

local Workspace = game:GetService("Workspace")

local StudioStageBuilder = {}

StudioStageBuilder.STAGE_ORIGIN = Vector3.new(0, 120, 470)
StudioStageBuilder.STAGE_TOP_Y = 120.45

local function makePart(parent, name, size, cf, color, material, shape, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Shape = shape or Enum.PartType.Block
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.CastShadow = true
    p.Transparency = transparency or 0
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function makeLightNode(parent, pos, color, brightness, range)
    local n = makePart(parent, "StudioLightNode", Vector3.new(0.5, 0.2, 0.5), CFrame.new(pos), color, Enum.Material.Neon, nil, 1)
    n.CastShadow = false
    local l = Instance.new("PointLight")
    l.Color = color
    l.Brightness = brightness
    l.Range = range
    l.Shadows = true
    l.Parent = n
    return n
end

function StudioStageBuilder.create()
    local booth = Instance.new("Model")
    booth.Name = "ClientShowcaseStudioBooth"
    booth.Parent = Workspace

    local O = StudioStageBuilder.STAGE_ORIGIN
    local topY = StudioStageBuilder.STAGE_TOP_Y

    -- Enclosed matte dark octagon backdrop so 360 orbit never reveals outside geometry
    local WALL_RADIUS = 30
    local WALL_HEIGHT = 28
    local SEGMENTS = 8
    for i = 1, SEGMENTS do
        local ang = ((i - 1) / SEGMENTS) * math.pi * 2
        local cx = O.X + math.sin(ang) * WALL_RADIUS
        local cz = O.Z + math.cos(ang) * WALL_RADIUS
        local wallCF = CFrame.lookAt(Vector3.new(cx, O.Y + WALL_HEIGHT * 0.5 - 2, cz), Vector3.new(O.X, O.Y + WALL_HEIGHT * 0.5 - 2, O.Z))
        makePart(booth, "StudioWall_" .. i, Vector3.new(26, WALL_HEIGHT, 1.2), wallCF, Color3.fromRGB(16, 19, 25), Enum.Material.SmoothPlastic)
    end

    -- Neutral dark ceiling cap & expansive studio subfloor
    makePart(booth, "StudioCeiling", Vector3.new(64, 1, 64), CFrame.new(O.X, O.Y + WALL_HEIGHT - 2, O.Z), Color3.fromRGB(14, 17, 22), Enum.Material.SmoothPlastic)
    makePart(booth, "StudioFloor", Vector3.new(64, 0.8, 64), CFrame.new(O.X, O.Y - 0.4, O.Z), Color3.fromRGB(20, 23, 30), Enum.Material.Concrete)

    -- Center circular display plinth (flush surface at STAGE_TOP_Y)
    local plinth = makePart(
        booth,
        "StudioTurntablePlinth",
        Vector3.new(0.45, 16, 16),
        CFrame.new(O.X, O.Y + 0.225, O.Z) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(34, 39, 49),
        Enum.Material.SmoothPlastic,
        Enum.PartType.Cylinder
    )
    plinth.CastShadow = false

    local ring = makePart(
        booth,
        "StudioTurntableRim",
        Vector3.new(0.10, 16.5, 16.5),
        CFrame.new(O.X, O.Y + 0.06, O.Z) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(56, 158, 255),
        Enum.Material.Neon,
        Enum.PartType.Cylinder
    )
    ring.CastShadow = false

    -- Radial stride/calibration spokes for Movement Preview visual feedback
    local calibrationRing = Instance.new("Model")
    calibrationRing.Name = "CalibrationGrid"
    calibrationRing.Parent = booth
    for idx = 0, 7 do
        local a = (idx / 8) * math.pi * 2
        local spokeCF = CFrame.new(O.X, topY + 0.015, O.Z) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -4.6)
        local spoke = makePart(calibrationRing, "CalibSpoke_" .. idx, Vector3.new(0.14, 0.02, 4.2), spokeCF, Color3.fromRGB(72, 86, 108), Enum.Material.SmoothPlastic)
        spoke.CastShadow = false
    end

    -- 3-point soft studio lighting (Key front-left, Fill front-right, Cool Back Rim, Overhead Softbox)
    makeLightNode(booth, O + Vector3.new(-10, 12, -13), Color3.fromRGB(255, 248, 238), 2.1, 46)
    makeLightNode(booth, O + Vector3.new(11, 8, -11), Color3.fromRGB(218, 232, 255), 1.35, 42)
    makeLightNode(booth, O + Vector3.new(0, 11, 14), Color3.fromRGB(165, 208, 255), 1.55, 44)
    makeLightNode(booth, O + Vector3.new(0, 18, 0), Color3.fromRGB(245, 248, 255), 1.6, 48)

    local mount = Instance.new("Folder")
    mount.Name = "ActiveAssetMount"
    mount.Parent = booth

    return {
        booth = booth,
        mount = mount,
        calibrationRing = calibrationRing,
        plinth = plinth,
        origin = O,
        topY = topY,
        groundPos = Vector3.new(O.X, topY, O.Z),
        setCalibrationRotation = function(rad)
            for idx = 0, 7 do
                local spoke = calibrationRing:FindFirstChild("CalibSpoke_" .. idx)
                if spoke then
                    local a = rad + (idx / 8) * math.pi * 2
                    spoke.CFrame = CFrame.new(O.X, topY + 0.015, O.Z) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -4.6)
                end
            end
        end,
        destroy = function()
            if booth and booth.Parent then
                booth:Destroy()
            end
        end,
    }
end

return StudioStageBuilder
