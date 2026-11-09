--[[
    OpticsManager.lua
    โมดูลจัดการระบบการเล็งและกล้องสโคป (Optics, ADS & Scopes)
    - ซูมเล็ง ADS (Aim Down Sights) ปรับ FOV ตามประเภทปืน
    - สโคปสไนเปอร์ Operator / Marshal (Black Vignette Scope + Red Reticle)
    - เป้าเล็ง Crosshair สไตล์ Valorant
]]

local OpticsManager = {}

function OpticsManager.createUI(parentGui)
    local optics = {}

    -- 1. Crosshair กลางจอ
    local crosshairGui = Instance.new("Frame")
    crosshairGui.Name = "Crosshair"
    crosshairGui.Size = UDim2.new(0, 24, 0, 24)
    crosshairGui.Position = UDim2.new(0.5, -12, 0.5, -12)
    crosshairGui.BackgroundTransparency = 1
    crosshairGui.Parent = parentGui
    optics.Crosshair = crosshairGui

    local function makeChLine(pos, size)
        local l = Instance.new("Frame")
        l.Size = size
        l.Position = pos
        l.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
        l.BorderSizePixel = 0
        l.Parent = crosshairGui
        return l
    end
    makeChLine(UDim2.new(0.5, -1, 0.5, -10), UDim2.new(0, 2, 0, 6))
    makeChLine(UDim2.new(0.5, -1, 0.5, 4),   UDim2.new(0, 2, 0, 6))
    makeChLine(UDim2.new(0.5, -10, 0.5, -1), UDim2.new(0, 6, 0, 2))
    makeChLine(UDim2.new(0.5, 4, 0.5, -1),   UDim2.new(0, 6, 0, 2))

    -- 2. สโคปสไนเปอร์ (Valorant Operator Precision Scope)
    local scopeOverlay = Instance.new("Frame")
    scopeOverlay.Name = "ScopeOverlay"
    scopeOverlay.Size = UDim2.new(1, 0, 1, 0)
    scopeOverlay.Position = UDim2.new(0, 0, 0, 0)
    scopeOverlay.BackgroundTransparency = 1
    scopeOverlay.BorderSizePixel = 0
    scopeOverlay.Visible = false
    scopeOverlay.Parent = parentGui
    optics.ScopeOverlay = scopeOverlay

    -- วงกลมเลนส์สโคปโปร่งใสตรงกลาง (Circular Scope Lens Aperture)
    -- ใช้ UIStroke หนา 1600px ล้อมรอบวงกลม ทำให้ขอบจอนอกวงกลมมืดสนิท 100% ครอบคลุมทุกขนาดหน้าจอ
    -- และภายในวงกลมโปร่งใส 100% มองเห็นศัตรู ซอมบี้ และฉาก 3D ได้อย่างคมชัด ไม่มีสี่เหลี่ยมดำมาบัง
    local scopeLens = Instance.new("Frame")
    scopeLens.Name = "ScopeLens"
    scopeLens.AnchorPoint = Vector2.new(0.5, 0.5)
    scopeLens.Position = UDim2.new(0.5, 0, 0.5, 0)
    scopeLens.Size = UDim2.new(0, 520, 0, 520)
    scopeLens.BackgroundTransparency = 1
    scopeLens.Parent = scopeOverlay
    Instance.new("UICorner", scopeLens).CornerRadius = UDim.new(1, 0)

    -- ขอบมืดรอบนอกหนาพิเศษ (Vignette Blackout UIStroke)
    local blackoutStroke = Instance.new("UIStroke")
    blackoutStroke.Color = Color3.fromRGB(6, 8, 12)
    blackoutStroke.Thickness = 1600
    blackoutStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    blackoutStroke.Parent = scopeLens

    -- ขอบเลนส์สโคปด้านในสีแดงเข้มเมทัลลิก (Valorant Operator Scope Ring)
    local innerRing = Instance.new("Frame")
    innerRing.Name = "InnerRing"
    innerRing.AnchorPoint = Vector2.new(0.5, 0.5)
    innerRing.Position = UDim2.new(0.5, 0, 0.5, 0)
    innerRing.Size = UDim2.new(1, 0, 1, 0)
    innerRing.BackgroundTransparency = 1
    innerRing.Parent = scopeLens
    Instance.new("UICorner", innerRing).CornerRadius = UDim.new(1, 0)

    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = Color3.fromRGB(180, 35, 45)
    ringStroke.Thickness = 2.5
    ringStroke.Parent = innerRing

    -- เส้นเป้าเล็งสไนเปอร์สีแดง Valorant Reticle (บาง คมชัด ไม่บังเป้า)
    local lineV = Instance.new("Frame")
    lineV.Size = UDim2.new(0, 1.5, 1, 0)
    lineV.Position = UDim2.new(0.5, -0.75, 0, 0)
    lineV.BackgroundColor3 = Color3.fromRGB(255, 45, 60)
    lineV.BorderSizePixel = 0
    lineV.Parent = scopeLens

    local lineH = Instance.new("Frame")
    lineH.Size = UDim2.new(1, 0, 0, 1.5)
    lineH.Position = UDim2.new(0, 0, 0.5, -0.75)
    lineH.BackgroundColor3 = Color3.fromRGB(255, 45, 60)
    lineH.BorderSizePixel = 0
    lineH.Parent = scopeLens

    -- ขีดวัดระยะ (Range Hash Marks)
    for step = -4, 4 do
        if step ~= 0 then
            local isMajor = (math.abs(step) % 2 == 0)
            local tickH = Instance.new("Frame")
            tickH.Size = UDim2.new(0, isMajor and 14 or 8, 0, 1)
            tickH.AnchorPoint = Vector2.new(0.5, 0.5)
            tickH.Position = UDim2.new(0.5, 0, 0.5 + (step * 0.08), 0)
            tickH.BackgroundColor3 = Color3.fromRGB(255, 70, 85)
            tickH.BorderSizePixel = 0
            tickH.Parent = scopeLens

            local tickV = Instance.new("Frame")
            tickV.Size = UDim2.new(0, 1, 0, isMajor and 14 or 8)
            tickV.AnchorPoint = Vector2.new(0.5, 0.5)
            tickV.Position = UDim2.new(0.5 + (step * 0.08), 0, 0.5, 0)
            tickV.BackgroundColor3 = Color3.fromRGB(255, 70, 85)
            tickV.BorderSizePixel = 0
            tickV.Parent = scopeLens
        end
    end

    -- จุดกึ่งกลางสีแดงเรืองแสง (Center Dot)
    local centerDot = Instance.new("Frame")
    centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    centerDot.Size = UDim2.new(0, 4, 0, 4)
    centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    centerDot.BackgroundColor3 = Color3.fromRGB(255, 30, 50)
    centerDot.BorderSizePixel = 0
    centerDot.Parent = scopeLens
    Instance.new("UICorner", centerDot).CornerRadius = UDim.new(1, 0)

    function optics:SetAiming(isAiming, weaponConfig)
        if isAiming then
            crosshairGui.Visible = false
            if weaponConfig and weaponConfig.IsSniper then
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
