--[[
    OpticsManager.lua
    โมดูลจัดการระบบการเล็งและกล้องสโคป (Optics, ADS & Scopes)
    - ซูมเล็ง ADS (Aim Down Sights) ปรับ FOV ตามประเภทปืน
    - สโคปสไนเปอร์ Operator / Marshal / Outlaw (Black Vignette Scope + Red Reticle) แบบดั้งเดิม สะอาด ไม่มีบั๊กสี่เหลี่ยม
    - เป้าเล็ง Crosshair สไตล์ Valorant
]]

local OpticsManager = {}

function OpticsManager.createUI(parentGui)
    local optics = {}

    -- 1. Crosshair กลางจอ (Hipfire)
    local crosshairGui = Instance.new("Frame")
    crosshairGui.Name = "Crosshair"
    crosshairGui.Size = UDim2.new(0, 24, 0, 24)
    crosshairGui.Position = UDim2.new(0.5, -12, 0.5, -12)
    crosshairGui.BackgroundTransparency = 1
    crosshairGui.ZIndex = 12
    crosshairGui.Parent = parentGui
    optics.Crosshair = crosshairGui

    local function makeChLine(pos, size)
        local l = Instance.new("Frame")
        l.Size = size
        l.Position = pos
        l.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
        l.BorderSizePixel = 0
        l.ZIndex = 12
        l.Parent = crosshairGui
        return l
    end
    makeChLine(UDim2.new(0.5, -1, 0.5, -10), UDim2.new(0, 2, 0, 6))
    makeChLine(UDim2.new(0.5, -1, 0.5, 4),   UDim2.new(0, 2, 0, 6))
    makeChLine(UDim2.new(0.5, -10, 0.5, -1), UDim2.new(0, 6, 0, 2))
    makeChLine(UDim2.new(0.5, 4, 0.5, -1),   UDim2.new(0, 6, 0, 2))

    -- จุดกึ่งกลางเล็งเป้า (Precision Center Aiming Dot)
    local centerAimDot = Instance.new("Frame")
    centerAimDot.Name = "CenterAimDot"
    centerAimDot.Size = UDim2.new(0, 2, 0, 2)
    centerAimDot.Position = UDim2.new(0.5, -1, 0.5, -1)
    centerAimDot.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
    centerAimDot.BorderSizePixel = 0
    centerAimDot.ZIndex = 12
    centerAimDot.Parent = crosshairGui

    -- 2. สโคปสไนเปอร์แบบเลนส์วงกลมแท้ (64-Segment Circular Optical Mask + Tapered Stadia BDC Reticle)
    local scopeOverlay = Instance.new("Frame")
    scopeOverlay.Name = "ScopeOverlay"
    scopeOverlay.Size = UDim2.new(1, 0, 1, 0)
    scopeOverlay.Position = UDim2.new(0, 0, 0, 0)
    scopeOverlay.BackgroundTransparency = 1
    scopeOverlay.BorderSizePixel = 0
    scopeOverlay.ZIndex = 11
    scopeOverlay.Visible = false
    scopeOverlay.Parent = parentGui
    optics.ScopeOverlay = scopeOverlay

    -- ใช้ CanvasGroup รวมหน้ากากทึบรอบเลนส์ให้โปร่งแสงเท่ากัน 100% ไม่มีรอยต่อหรือมุมสี่เหลี่ยมโผล่
    local maskCanvas = Instance.new("CanvasGroup")
    maskCanvas.Name = "MaskCanvas"
    maskCanvas.Size = UDim2.fromScale(1, 1)
    maskCanvas.BackgroundTransparency = 1
    maskCanvas.GroupTransparency = 0.03
    maskCanvas.ZIndex = 11
    maskCanvas.Parent = scopeOverlay

    local maskCol = Color3.fromRGB(4, 5, 8)
    local function makeMask(name, parentInst)
        local f = Instance.new("Frame")
        f.Name = name
        f.BackgroundColor3 = maskCol
        f.BackgroundTransparency = 0
        f.BorderSizePixel = 0
        f.ZIndex = 11
        f.Parent = parentInst or maskCanvas
        return f
    end

    local topMask = makeMask("MaskTop")
    local bottomMask = makeMask("MaskBottom")
    local leftMask = makeMask("MaskLeft")
    local rightMask = makeMask("MaskRight")

    local cornerCutout = Instance.new("Frame")
    cornerCutout.Name = "CornerCutout"
    cornerCutout.BackgroundTransparency = 1
    cornerCutout.BorderSizePixel = 0
    cornerCutout.ClipsDescendants = true
    cornerCutout.ZIndex = 11
    cornerCutout.Parent = maskCanvas

    local NUM_SEGMENTS = 64
    local bezelSegments = {}
    for i = 1, NUM_SEGMENTS do
        local seg = makeMask("BezelSeg_" .. i, cornerCutout)
        seg.AnchorPoint = Vector2.new(0.5, 0.5)
        bezelSegments[i] = seg
    end

    -- 3. ตัวเรือนเลนส์แก้วเคลือบกันแสงสะท้อน + เส้นเล็ง Tactical BDC (ความละเอียด Native คมชัดสูงสุด)
    local scopeLens = Instance.new("Frame")
    scopeLens.Name = "ScopeLens"
    scopeLens.Position = UDim2.fromScale(0.5, 0.5)
    scopeLens.Size = UDim2.fromOffset(500, 500)
    scopeLens.BackgroundColor3 = Color3.fromRGB(10, 22, 28)
    scopeLens.BackgroundTransparency = 0.94
    scopeLens.BorderSizePixel = 0
    scopeLens.ClipsDescendants = true
    scopeLens.ZIndex = 12
    scopeLens.Parent = scopeOverlay
    Instance.new("UICorner", scopeLens).CornerRadius = UDim.new(1, 0)

    local outerBezelRing = Instance.new("Frame")
    outerBezelRing.Name = "OuterBezelRing"
    outerBezelRing.Position = UDim2.fromScale(0.5, 0.5)
    outerBezelRing.Size = UDim2.fromOffset(494, 494)
    outerBezelRing.BackgroundTransparency = 1
    outerBezelRing.ZIndex = 15
    outerBezelRing.Parent = scopeOverlay
    Instance.new("UICorner", outerBezelRing).CornerRadius = UDim.new(1, 0)
    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = Color3.fromRGB(10, 12, 16)
    outerStroke.Thickness = 10
    outerStroke.Transparency = 0.02
    outerStroke.Parent = outerBezelRing

    local metallicInnerRim = Instance.new("Frame")
    metallicInnerRim.Name = "MetallicInnerRim"
    metallicInnerRim.Position = UDim2.fromOffset(5, 5)
    metallicInnerRim.Size = UDim2.new(1, -10, 1, -10)
    metallicInnerRim.BackgroundTransparency = 1
    metallicInnerRim.ZIndex = 15
    metallicInnerRim.Parent = scopeLens
    Instance.new("UICorner", metallicInnerRim).CornerRadius = UDim.new(1, 0)
    local rimStroke = Instance.new("UIStroke")
    rimStroke.Color = Color3.fromRGB(105, 125, 145)
    rimStroke.Thickness = 1.5
    rimStroke.Transparency = 0.52
    rimStroke.Parent = metallicInnerRim

    local vignetteInnerRim = Instance.new("Frame")
    vignetteInnerRim.Name = "VignetteInnerRim"
    vignetteInnerRim.Position = UDim2.fromOffset(10, 10)
    vignetteInnerRim.Size = UDim2.new(1, -20, 1, -20)
    vignetteInnerRim.BackgroundTransparency = 1
    vignetteInnerRim.ZIndex = 12
    vignetteInnerRim.Parent = scopeLens
    Instance.new("UICorner", vignetteInnerRim).CornerRadius = UDim.new(1, 0)
    local vigStroke = Instance.new("UIStroke")
    vigStroke.Color = Color3.fromRGB(4, 6, 10)
    vigStroke.Thickness = 12
    vigStroke.Transparency = 0.76
    vigStroke.Parent = vignetteInnerRim

    local scopeReticle = Instance.new("Frame")
    scopeReticle.Name = "ScopeReticle"
    scopeReticle.Size = UDim2.fromScale(1, 1)
    scopeReticle.BackgroundTransparency = 1
    scopeReticle.ZIndex = 13
    scopeReticle.Parent = scopeLens

    local etchedCol = Color3.fromRGB(12, 14, 18)
    local glowAccentParts = {}
    local function addReticleBar(name, anchor, pos, size, col, trans, z)
        local b = Instance.new("Frame")
        b.Name = name
        b.AnchorPoint = anchor
        b.Position = pos
        b.Size = size
        b.BackgroundColor3 = col
        b.BackgroundTransparency = trans or 0
        b.BorderSizePixel = 0
        b.ZIndex = z or 13
        b.Parent = scopeReticle
        return b
    end

    -- เส้นกากบาทหลักแบบบางเฉียบแกะสลักในเลนส์ (เว้นช่องใสตรงกลางไว้ให้จุดเล็ง)
    addReticleBar("HairTop", Vector2.new(0.5, 1), UDim2.fromScale(0.5, 0.48), UDim2.new(0, 1, 0.48, 0), etchedCol, 0.25)
    addReticleBar("HairBot", Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.52), UDim2.new(0, 1, 0.48, 0), etchedCol, 0.25)
    addReticleBar("HairLeft", Vector2.new(1, 0.5), UDim2.fromScale(0.48, 0.5), UDim2.new(0.48, 0, 0, 1), etchedCol, 0.25)
    addReticleBar("HairRight", Vector2.new(0, 0.5), UDim2.fromScale(0.52, 0.5), UDim2.new(0.48, 0, 0, 1), etchedCol, 0.25)

    -- ขาหลักทรงเรียว (Tapered Outer Stadia Posts: ซ้าย/ขวา/ล่าง/บน)
    addReticleBar("StadiaOuterL", Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.new(0.24, 0, 0, 4), etchedCol, 0.08)
    addReticleBar("StadiaStepL", Vector2.new(0, 0.5), UDim2.fromScale(0.24, 0.5), UDim2.new(0.08, 0, 0, 2), etchedCol, 0.14)
    addReticleBar("StadiaOuterR", Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), UDim2.new(0.24, 0, 0, 4), etchedCol, 0.08)
    addReticleBar("StadiaStepR", Vector2.new(1, 0.5), UDim2.fromScale(0.76, 0.5), UDim2.new(0.08, 0, 0, 2), etchedCol, 0.14)
    addReticleBar("StadiaOuterB", Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.new(0, 4, 0.21, 0), etchedCol, 0.08)
    addReticleBar("StadiaStepB", Vector2.new(0.5, 1), UDim2.fromScale(0.5, 0.79), UDim2.new(0, 2, 0.08, 0), etchedCol, 0.14)
    addReticleBar("StadiaOuterT", Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.new(0, 3, 0.18, 0), etchedCol, 0.12)

    -- เส้นชดเชยแรงลมซ้ายขวา (Mil Windage Ticks)
    local defaultRetCol = Color3.fromRGB(255, 48, 68)
    for idx, xOff in ipairs({ 0.06, 0.12, 0.18, 0.24 }) do
        local isMajor = (idx % 2 == 0)
        local h = isMajor and 12 or 7
        addReticleBar("WindL_" .. idx, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5 - xOff, 0.5), UDim2.fromOffset(1, h), etchedCol, 0.18)
        addReticleBar("WindR_" .. idx, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5 + xOff, 0.5), UDim2.fromOffset(1, h), etchedCol, 0.18)
        if isMajor then
            table.insert(glowAccentParts, addReticleBar("WindDotL_" .. idx, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5 - xOff, 0.5), UDim2.fromOffset(2, 4), defaultRetCol, 0.18, 14))
            table.insert(glowAccentParts, addReticleBar("WindDotR_" .. idx, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5 + xOff, 0.5), UDim2.fromOffset(2, 4), defaultRetCol, 0.18, 14))
        end
    end

    -- ขีดเผื่อระยะกระสุนตกด้านล่าง (BDC Holdover Stadia) + ขีดบน
    addReticleBar("UpperTick1", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.43), UDim2.fromOffset(10, 1), etchedCol, 0.2)
    addReticleBar("UpperTick2", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.36), UDim2.fromOffset(14, 1), etchedCol, 0.2)
    for idx, spec in ipairs({ { y = 0.56, w = 0.032 }, { y = 0.62, w = 0.056 }, { y = 0.68, w = 0.082 }, { y = 0.74, w = 0.110 } }) do
        addReticleBar("BDCRung_" .. idx, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, spec.y), UDim2.new(spec.w, 0, 0, 1), etchedCol, 0.15)
        table.insert(glowAccentParts, addReticleBar("BDCTick_" .. idx, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, spec.y), UDim2.fromOffset(4, 2), defaultRetCol, 0.12, 14))
    end

    -- เส้นกากบาทเรืองแสงระยะใกล้ใจกลาง + จุดเล็งหลักขนาดคมชัดไม่บังหัวซอมบี้
    table.insert(glowAccentParts, addReticleBar("InnerGlowTop", Vector2.new(0.5, 1), UDim2.new(0.5, 0, 0.5, -5), UDim2.fromOffset(1, 14), defaultRetCol, 0.12, 14))
    table.insert(glowAccentParts, addReticleBar("InnerGlowBot", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0.5, 5), UDim2.fromOffset(1, 14), defaultRetCol, 0.12, 14))
    table.insert(glowAccentParts, addReticleBar("InnerGlowL", Vector2.new(1, 0.5), UDim2.new(0.5, -5, 0.5, 0), UDim2.fromOffset(14, 1), defaultRetCol, 0.12, 14))
    table.insert(glowAccentParts, addReticleBar("InnerGlowR", Vector2.new(0, 0.5), UDim2.new(0.5, 5, 0.5, 0), UDim2.fromOffset(14, 1), defaultRetCol, 0.12, 14))

    local centerHalo = addReticleBar("CenterHalo", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(10, 10), defaultRetCol, 0.78, 14)
    Instance.new("UICorner", centerHalo).CornerRadius = UDim.new(1, 0)
    table.insert(glowAccentParts, centerHalo)

    local centerDot = addReticleBar("CenterDot", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(4, 4), defaultRetCol, 0, 15)
    Instance.new("UICorner", centerDot).CornerRadius = UDim.new(1, 0)
    table.insert(glowAccentParts, centerDot)

    local scopeReadout = Instance.new("TextLabel")
    scopeReadout.Name = "ScopeReadout"
    scopeReadout.AnchorPoint = Vector2.new(0.5, 1)
    scopeReadout.Position = UDim2.fromScale(0.5, 0.90)
    scopeReadout.Size = UDim2.fromOffset(190, 20)
    scopeReadout.BackgroundTransparency = 1
    scopeReadout.Font = Enum.Font.Code
    scopeReadout.TextSize = 12
    scopeReadout.TextColor3 = defaultRetCol
    scopeReadout.TextTransparency = 0.25
    scopeReadout.Text = "8.0X // BDC ZEROED"
    scopeReadout.ZIndex = 14
    scopeReadout.Parent = scopeReticle

    local function updateScopeTheme(weaponConfig)
        local wName = weaponConfig and weaponConfig.Name or "OPERATOR"
        local accent = defaultRetCol
        local labelTxt = "8.0X // .50 BDC"
        if wName == "MARSHAL" then
            accent = Color3.fromRGB(255, 185, 65)
            labelTxt = "4.5X // SCOUT OPTIC"
        elseif wName == "OUTLAW" then
            accent = Color3.fromRGB(255, 88, 82)
            labelTxt = "5.0X // EXPRESS BDC"
        end
        for _, p in ipairs(glowAccentParts) do
            p.BackgroundColor3 = accent
        end
        scopeReadout.TextColor3 = accent
        scopeReadout.Text = labelTxt
    end

    local function updateScopeLayout()
        local absSize = parentGui.AbsoluteSize
        local w = absSize.X
        local h = absSize.Y
        if w <= 0 or h <= 0 then return end

        local radius = math.max(80, math.floor(math.min(w, h) * 0.44))
        local lensDia = radius * 2
        local cx = math.floor(w * 0.5)
        local cy = math.floor(h * 0.5)
        local sideW = math.max(0, cx - radius)
        local topH = math.max(0, cy - radius)
        local bottomY = topH + lensDia
        local bottomH = math.max(0, h - bottomY)
        local rightX = sideW + lensDia
        local rightW = math.max(0, w - rightX)

        scopeLens.Position = UDim2.fromOffset(sideW, topH)
        scopeLens.Size = UDim2.fromOffset(lensDia, lensDia)
        outerBezelRing.Position = UDim2.fromOffset(sideW + 3, topH + 3)
        outerBezelRing.Size = UDim2.fromOffset(lensDia - 6, lensDia - 6)
        cornerCutout.Position = UDim2.fromOffset(sideW, topH)
        cornerCutout.Size = UDim2.fromOffset(lensDia, lensDia)

        topMask.Position = UDim2.fromOffset(0, 0)
        topMask.Size = UDim2.fromOffset(w, topH)
        bottomMask.Position = UDim2.fromOffset(0, bottomY)
        bottomMask.Size = UDim2.fromOffset(w, bottomH)
        leftMask.Position = UDim2.fromOffset(0, topH)
        leftMask.Size = UDim2.fromOffset(sideW, lensDia)
        rightMask.Position = UDim2.fromOffset(rightX, topH)
        rightMask.Size = UDim2.fromOffset(rightW, lensDia)

        local barDepth = math.ceil(radius * 0.54)
        local barWidth = math.ceil(2 * (radius + barDepth) * math.tan(math.pi / NUM_SEGMENTS)) + 4
        local rMid = radius + barDepth * 0.5 - 1
        for i = 1, NUM_SEGMENTS do
            local deg = (i - 1) * (360 / NUM_SEGMENTS)
            local rad = math.rad(deg)
            local seg = bezelSegments[i]
            seg.Size = UDim2.fromOffset(barWidth, barDepth)
            seg.Position = UDim2.fromOffset(radius + rMid * math.sin(rad), radius - rMid * math.cos(rad))
            seg.Rotation = deg
        end
    end

    parentGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScopeLayout)
    task.defer(updateScopeLayout)

    function optics:SetAiming(isAiming, weaponConfig)
        local useScopeOverlay = isAiming and weaponConfig and weaponConfig.Optics and weaponConfig.Optics.IsSniperScope == true
        if isAiming then
            crosshairGui.Visible = false
            if useScopeOverlay then
                updateScopeTheme(weaponConfig)
                updateScopeLayout()
                scopeOverlay.Visible = true
            else
                scopeOverlay.Visible = false
            end
        else
            crosshairGui.Visible = true
            scopeOverlay.Visible = false
        end
    end

    return optics
end

return OpticsManager
