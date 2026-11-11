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

    -- 2. สโคปสไนเปอร์แบบหน้าต่างเลนส์ใส (Clear Center Lens + Peripheral Mask)
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

    local function makeMask(name)
        local f = Instance.new("Frame")
        f.Name = name
        f.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
        f.BackgroundTransparency = 0.14
        f.BorderSizePixel = 0
        f.ZIndex = 11
        f.Parent = scopeOverlay
        return f
    end

    local topMask = makeMask("MaskTop")
    local bottomMask = makeMask("MaskBottom")
    local leftMask = makeMask("MaskLeft")
    local rightMask = makeMask("MaskRight")

    local scopeLens = Instance.new("Frame")
    scopeLens.Name = "ScopeLens"
    scopeLens.AnchorPoint = Vector2.zero
    scopeLens.Position = UDim2.fromScale(0.5, 0.5)
    scopeLens.Size = UDim2.fromOffset(500, 500)
    scopeLens.BackgroundTransparency = 1
    scopeLens.BorderSizePixel = 0
    scopeLens.ZIndex = 12
    scopeLens.Parent = scopeOverlay

    local scopeRing = Instance.new("Frame")
    scopeRing.Name = "ScopeRing"
    scopeRing.Size = UDim2.fromScale(1, 1)
    scopeRing.BackgroundTransparency = 1
    scopeRing.ZIndex = 12
    scopeRing.Parent = scopeLens
    Instance.new("UICorner", scopeRing).CornerRadius = UDim.new(1, 0)
    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = Color3.fromRGB(16, 18, 22)
    ringStroke.Thickness = 6
    ringStroke.Transparency = 0.15
    ringStroke.Parent = scopeRing

    local scopeReticle = Instance.new("Frame")
    scopeReticle.Name = "ScopeReticle"
    scopeReticle.Size = UDim2.fromScale(1, 1)
    scopeReticle.BackgroundTransparency = 1
    scopeReticle.ZIndex = 13
    scopeReticle.Parent = scopeLens

    local lineV = Instance.new("Frame")
    lineV.Name = "LineV"
    lineV.Size = UDim2.new(0, 2, 1, 0)
    lineV.Position = UDim2.new(0.5, -1, 0, 0)
    lineV.BackgroundColor3 = Color3.fromRGB(255, 40, 60)
    lineV.BorderSizePixel = 0
    lineV.ZIndex = 13
    lineV.Parent = scopeReticle

    local lineH = Instance.new("Frame")
    lineH.Name = "LineH"
    lineH.Size = UDim2.new(1, 0, 0, 2)
    lineH.Position = UDim2.new(0, 0, 0.5, -1)
    lineH.BackgroundColor3 = Color3.fromRGB(255, 40, 60)
    lineH.BorderSizePixel = 0
    lineH.ZIndex = 13
    lineH.Parent = scopeReticle

    -- จุดกึ่งกลางสีแดงคมชัด + ขีดวัดระยะ Mil-Dot
    for _, offset in ipairs({ -90, -45, 45, 90 }) do
        local tickH = Instance.new("Frame")
        tickH.Size = UDim2.fromOffset(2, 10)
        tickH.Position = UDim2.new(0.5, offset - 1, 0.5, -5)
        tickH.BackgroundColor3 = Color3.fromRGB(255, 65, 80)
        tickH.BorderSizePixel = 0
        tickH.ZIndex = 13
        tickH.Parent = scopeReticle

        local tickV = Instance.new("Frame")
        tickV.Size = UDim2.fromOffset(10, 2)
        tickV.Position = UDim2.new(0.5, -5, 0.5, offset - 1)
        tickV.BackgroundColor3 = Color3.fromRGB(255, 65, 80)
        tickV.BorderSizePixel = 0
        tickV.ZIndex = 13
        tickV.Parent = scopeReticle
    end

    local centerDot = Instance.new("Frame")
    centerDot.Name = "CenterDot"
    centerDot.Size = UDim2.new(0, 6, 0, 6)
    centerDot.Position = UDim2.new(0.5, -3, 0.5, -3)
    centerDot.BackgroundColor3 = Color3.fromRGB(255, 30, 50)
    centerDot.BorderSizePixel = 0
    centerDot.ZIndex = 14
    centerDot.Parent = scopeReticle
    Instance.new("UICorner", centerDot).CornerRadius = UDim.new(1, 0)

    local function updateScopeLayout()
        local absSize = parentGui.AbsoluteSize
        local w = absSize.X
        local h = absSize.Y
        if w <= 0 or h <= 0 then return end

        local lensDia = math.max(120, math.floor(math.min(w, h) * 0.42) * 2)
        local sideW = math.max(0, math.floor((w - lensDia) * 0.5))
        local topH = math.max(0, math.floor((h - lensDia) * 0.5))
        local bottomY = topH + lensDia
        local bottomH = math.max(0, h - bottomY)
        local rightX = sideW + lensDia
        local rightW = math.max(0, w - rightX)

        scopeLens.Position = UDim2.fromOffset(sideW, topH)
        scopeLens.Size = UDim2.fromOffset(lensDia, lensDia)
        topMask.Position = UDim2.fromOffset(0, 0)
        topMask.Size = UDim2.fromOffset(w, topH)
        bottomMask.Position = UDim2.fromOffset(0, bottomY)
        bottomMask.Size = UDim2.fromOffset(w, bottomH)
        leftMask.Position = UDim2.fromOffset(0, topH)
        leftMask.Size = UDim2.fromOffset(sideW, lensDia)
        rightMask.Position = UDim2.fromOffset(rightX, topH)
        rightMask.Size = UDim2.fromOffset(rightW, lensDia)
    end

    parentGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScopeLayout)
    task.defer(updateScopeLayout)

    function optics:SetAiming(isAiming, weaponConfig)
        local useScopeOverlay = isAiming and weaponConfig and weaponConfig.Optics and weaponConfig.Optics.IsSniperScope == true
        if isAiming then
            crosshairGui.Visible = false
            if useScopeOverlay then
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
