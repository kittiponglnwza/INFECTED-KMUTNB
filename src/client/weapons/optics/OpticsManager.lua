--[[
    OpticsManager.lua
    โมดูลจัดการระบบการเล็งและกล้องสโคป (Optics, ADS & Scopes)
    - ซูมเล็ง ADS (Aim Down Sights) ปรับ FOV ตามประเภทปืน
    - สโคปสไนเปอร์ Operator / Marshal / Outlaw สไตล์ Valorant
    - ขอบเลนส์กลม คมชัด ไม่บังสายตา ปีกเงารอบข้างกึ่งโปร่งแสง มองเห็นซอมบี้ได้รอบทิศ
    - เส้นเป้าเล็ง Floating Crosshairs พร้อมเว้นช่องว่างตรงกลาง ไม่บังหัวศัตรู
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

    -- 2. สโคปสไนเปอร์ความแม่นยำสูง (Valorant Precision Sniper Scope)
    local scopeOverlay = Instance.new("Frame")
    scopeOverlay.Name = "ScopeOverlay"
    scopeOverlay.Size = UDim2.new(1, 0, 1, 0)
    scopeOverlay.Position = UDim2.new(0, 0, 0, 0)
    scopeOverlay.BackgroundTransparency = 1
    scopeOverlay.BorderSizePixel = 0
    scopeOverlay.Visible = false
    scopeOverlay.Parent = parentGui
    optics.ScopeOverlay = scopeOverlay

    -- กำหนดขนาดเลนส์สโคปตรงกลาง (380x380 px สัดส่วนพอดีสายตา ไม่บดบังหน้าจอ)
    local SCOPE_SIZE = 380
    local HALF_SIZE = SCOPE_SIZE / 2
    local VIGNETTE_COLOR = Color3.fromRGB(8, 10, 14)
    local VIGNETTE_TRANS = 0.52 -- กึ่งโปร่งแสง ช่วยให้มองเห็นการเคลื่อนไหวของซอมบี้รอบข้างได้

    -- ปีกบังตาด้านซ้าย (Left Wing)
    local wingLeft = Instance.new("Frame")
    wingLeft.Name = "WingLeft"
    wingLeft.Size = UDim2.new(0.5, -HALF_SIZE, 1, 0)
    wingLeft.Position = UDim2.new(0, 0, 0, 0)
    wingLeft.BackgroundColor3 = VIGNETTE_COLOR
    wingLeft.BackgroundTransparency = VIGNETTE_TRANS
    wingLeft.BorderSizePixel = 0
    wingLeft.Parent = scopeOverlay

    -- ปีกบังตาด้านขวา (Right Wing)
    local wingRight = Instance.new("Frame")
    wingRight.Name = "WingRight"
    wingRight.Size = UDim2.new(0.5, -HALF_SIZE, 1, 0)
    wingRight.Position = UDim2.new(0.5, HALF_SIZE, 0, 0)
    wingRight.BackgroundColor3 = VIGNETTE_COLOR
    wingRight.BackgroundTransparency = VIGNETTE_TRANS
    wingRight.BorderSizePixel = 0
    wingRight.Parent = scopeOverlay

    -- ปีกบังตาด้านบน (Top Wing)
    local wingTop = Instance.new("Frame")
    wingTop.Name = "WingTop"
    wingTop.Size = UDim2.new(0, SCOPE_SIZE, 0.5, -HALF_SIZE)
    wingTop.Position = UDim2.new(0.5, -HALF_SIZE, 0, 0)
    wingTop.BackgroundColor3 = VIGNETTE_COLOR
    wingTop.BackgroundTransparency = VIGNETTE_TRANS
    wingTop.BorderSizePixel = 0
    wingTop.Parent = scopeOverlay

    -- ปีกบังตาด้านล่าง (Bottom Wing)
    local wingBottom = Instance.new("Frame")
    wingBottom.Name = "WingBottom"
    wingBottom.Size = UDim2.new(0, SCOPE_SIZE, 0.5, -HALF_SIZE)
    wingBottom.Position = UDim2.new(0.5, -HALF_SIZE, 0.5, HALF_SIZE)
    wingBottom.BackgroundColor3 = VIGNETTE_COLOR
    wingBottom.BackgroundTransparency = VIGNETTE_TRANS
    wingBottom.BorderSizePixel = 0
    wingBottom.Parent = scopeOverlay

    -- กรอบเลนส์สโคปทรงกลมโปร่งใส 100% (Circular Scope Lens)
    local scopeLens = Instance.new("Frame")
    scopeLens.Name = "ScopeLens"
    scopeLens.AnchorPoint = Vector2.new(0.5, 0.5)
    scopeLens.Position = UDim2.new(0.5, 0, 0.5, 0)
    scopeLens.Size = UDim2.new(0, SCOPE_SIZE, 0, SCOPE_SIZE)
    scopeLens.BackgroundTransparency = 1
    scopeLens.BorderSizePixel = 0
    scopeLens.Parent = scopeOverlay

    local ratioConstraint = Instance.new("UIAspectRatioConstraint")
    ratioConstraint.AspectRatio = 1.0
    ratioConstraint.Parent = scopeLens

    Instance.new("UICorner", scopeLens).CornerRadius = UDim.new(1, 0)

    -- ขอบวงแหวนเลนส์ไททาเนียมสีดำคมชัด (Titanium Bezel)
    local outerBezelStroke = Instance.new("UIStroke")
    outerBezelStroke.Color = Color3.fromRGB(24, 28, 38)
    outerBezelStroke.Thickness = 2.5
    outerBezelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outerBezelStroke.Parent = scopeLens

    -- วงแหวนสีแดงนีออนด้านในสไตล์ Valorant (Valorant Crimson Inner Ring)
    local innerRing = Instance.new("Frame")
    innerRing.Name = "InnerRing"
    innerRing.AnchorPoint = Vector2.new(0.5, 0.5)
    innerRing.Position = UDim2.new(0.5, 0, 0.5, 0)
    innerRing.Size = UDim2.new(1, -6, 1, -6)
    innerRing.BackgroundTransparency = 1
    innerRing.Parent = scopeLens
    Instance.new("UICorner", innerRing).CornerRadius = UDim.new(1, 0)

    local innerRingStroke = Instance.new("UIStroke")
    innerRingStroke.Color = Color3.fromRGB(245, 45, 60)
    innerRingStroke.Thickness = 1.2
    innerRingStroke.Transparency = 0.3
    innerRingStroke.Parent = innerRing

    -- 🎯 เส้นเป้าเล็งสีแดง Valorant Reticle แบบลอย (Floating Hairlines)
    -- เว้นช่องว่างตรงกลาง (10px Gap) มองเห็นหัวเป้าหมายชัดเจน ไม่บังเป้า
    local RETICLE_COLOR = Color3.fromRGB(255, 45, 60)
    local GAP = 10
    local HAIR_LEN = 135

    -- เส้นบน (Top)
    local lineTop = Instance.new("Frame")
    lineTop.Size = UDim2.new(0, 1, 0, HAIR_LEN)
    lineTop.AnchorPoint = Vector2.new(0.5, 1)
    lineTop.Position = UDim2.new(0.5, 0, 0.5, -GAP)
    lineTop.BackgroundColor3 = RETICLE_COLOR
    lineTop.BorderSizePixel = 0
    lineTop.Parent = scopeLens

    -- เส้นล่าง (Bottom)
    local lineBottom = Instance.new("Frame")
    lineBottom.Size = UDim2.new(0, 1, 0, HAIR_LEN)
    lineBottom.AnchorPoint = Vector2.new(0.5, 0)
    lineBottom.Position = UDim2.new(0.5, 0, 0.5, GAP)
    lineBottom.BackgroundColor3 = RETICLE_COLOR
    lineBottom.BorderSizePixel = 0
    lineBottom.Parent = scopeLens

    -- เส้นซ้าย (Left)
    local lineLeft = Instance.new("Frame")
    lineLeft.Size = UDim2.new(0, HAIR_LEN, 0, 1)
    lineLeft.AnchorPoint = Vector2.new(1, 0.5)
    lineLeft.Position = UDim2.new(0.5, -GAP, 0.5, 0)
    lineLeft.BackgroundColor3 = RETICLE_COLOR
    lineLeft.BorderSizePixel = 0
    lineLeft.Parent = scopeLens

    -- เส้นขวา (Right)
    local lineRight = Instance.new("Frame")
    lineRight.Size = UDim2.new(0, HAIR_LEN, 0, 1)
    lineRight.AnchorPoint = Vector2.new(0, 0.5)
    lineRight.Position = UDim2.new(0.5, GAP, 0.5, 0)
    lineRight.BackgroundColor3 = RETICLE_COLOR
    lineRight.BorderSizePixel = 0
    lineRight.Parent = scopeLens

    -- จุดกึ่งกลางสีแดงเรืองแสงขนาดกะทัดรัด 3x3 px (Precision Micro Dot)
    local centerDot = Instance.new("Frame")
    centerDot.Name = "CenterDot"
    centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    centerDot.Size = UDim2.new(0, 3, 0, 3)
    centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    centerDot.BackgroundColor3 = Color3.fromRGB(255, 30, 45)
    centerDot.BorderSizePixel = 0
    centerDot.Parent = scopeLens
    Instance.new("UICorner", centerDot).CornerRadius = UDim.new(1, 0)

    -- ขีดวัดระยะสไนเปอร์ (Tactical Stadia Range Hash Marks)
    for _, dist in ipairs({ 32, 64, 96 }) do
        local isMajor = (dist == 64)
        local tickSpan = isMajor and 10 or 6

        -- ขีดบน
        local tT = Instance.new("Frame")
        tT.Size = UDim2.new(0, tickSpan, 0, 1)
        tT.AnchorPoint = Vector2.new(0.5, 0.5)
        tT.Position = UDim2.new(0.5, 0, 0.5, -dist)
        tT.BackgroundColor3 = RETICLE_COLOR
        tT.BackgroundTransparency = 0.25
        tT.BorderSizePixel = 0
        tT.Parent = scopeLens

        -- ขีดล่าง
        local tB = Instance.new("Frame")
        tB.Size = UDim2.new(0, tickSpan, 0, 1)
        tB.AnchorPoint = Vector2.new(0.5, 0.5)
        tB.Position = UDim2.new(0.5, 0, 0.5, dist)
        tB.BackgroundColor3 = RETICLE_COLOR
        tB.BackgroundTransparency = 0.25
        tB.BorderSizePixel = 0
        tB.Parent = scopeLens

        -- ขีดซ้าย
        local tL = Instance.new("Frame")
        tL.Size = UDim2.new(0, 1, 0, tickSpan)
        tL.AnchorPoint = Vector2.new(0.5, 0.5)
        tL.Position = UDim2.new(0.5, -dist, 0.5, 0)
        tL.BackgroundColor3 = RETICLE_COLOR
        tL.BackgroundTransparency = 0.25
        tL.BorderSizePixel = 0
        tL.Parent = scopeLens

        -- ขีดขวา
        local tR = Instance.new("Frame")
        tR.Size = UDim2.new(0, 1, 0, tickSpan)
        tR.AnchorPoint = Vector2.new(0.5, 0.5)
        tR.Position = UDim2.new(0.5, dist, 0.5, 0)
        tR.BackgroundColor3 = RETICLE_COLOR
        tR.BackgroundTransparency = 0.25
        tR.BorderSizePixel = 0
        tR.Parent = scopeLens
    end

    -- ข้อมูลบอกสถานะกล้องสโคปสไตล์ดิจิทัล (Digital Tactical HUD Labels)
    local magLabel = Instance.new("TextLabel")
    magLabel.Name = "MagLabel"
    magLabel.Size = UDim2.new(0, 90, 0, 14)
    magLabel.Position = UDim2.new(0.5, -160, 0.5, -155)
    magLabel.BackgroundTransparency = 1
    magLabel.Text = "[ 2.5x OPTIC ]"
    magLabel.TextColor3 = Color3.fromRGB(0, 240, 215)
    magLabel.TextTransparency = 0.35
    magLabel.Font = Enum.Font.GothamBold
    magLabel.TextSize = 9
    magLabel.TextXAlignment = Enum.TextXAlignment.Left
    magLabel.Parent = scopeLens

    local calLabel = Instance.new("TextLabel")
    calLabel.Name = "CalLabel"
    calLabel.Size = UDim2.new(0, 160, 0, 14)
    calLabel.Position = UDim2.new(0.5, -80, 0.5, 142)
    calLabel.BackgroundTransparency = 1
    calLabel.Text = "TACTICAL PRECISION // .50"
    calLabel.TextColor3 = Color3.fromRGB(255, 75, 90)
    calLabel.TextTransparency = 0.40
    calLabel.Font = Enum.Font.GothamBold
    calLabel.TextSize = 8
    calLabel.TextXAlignment = Enum.TextXAlignment.Center
    calLabel.Parent = scopeLens

    local rdyLabel = Instance.new("TextLabel")
    rdyLabel.Name = "RdyLabel"
    rdyLabel.Size = UDim2.new(0, 90, 0, 14)
    rdyLabel.Position = UDim2.new(0.5, 70, 0.5, -155)
    rdyLabel.BackgroundTransparency = 1
    rdyLabel.Text = "[ SYS // RDY ]"
    rdyLabel.TextColor3 = Color3.fromRGB(0, 240, 215)
    rdyLabel.TextTransparency = 0.35
    rdyLabel.Font = Enum.Font.GothamBold
    rdyLabel.TextSize = 9
    rdyLabel.TextXAlignment = Enum.TextXAlignment.Right
    rdyLabel.Parent = scopeLens

    function optics:SetAiming(isAiming, weaponConfig)
        if isAiming then
            crosshairGui.Visible = false
            if weaponConfig and weaponConfig.IsSniper then
                local wName = (weaponConfig.Name or ""):upper()
                if wName == "OPERATOR" then
                    magLabel.Text = "[ 2.5x OPTIC ]"
                    calLabel.Text = "OPERATOR // CALIBER .50"
                elseif wName == "OUTLAW" then
                    magLabel.Text = "[ DUAL-MAG 2x ]"
                    calLabel.Text = "OUTLAW // DOUBLE-BARREL"
                elseif wName == "MARSHAL" then
                    magLabel.Text = "[ SCOUT 1.5x ]"
                    calLabel.Text = "MARSHAL // LEVER-ACTION"
                else
                    magLabel.Text = "[ SNIPER OPTIC ]"
                    calLabel.Text = wName .. " // PRECISION"
                end
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
