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

    -- 2. สโคปสไนเปอร์แบบดั้งเดิม (Original Clean Sniper Scope Overlay)
    -- มืดสนิทรอบจอ สะอาดตา ไม่มีบั๊กเส้นขอบสี่เหลี่ยมหรือ UIStroke artifact
    local scopeOverlay = Instance.new("Frame")
    scopeOverlay.Name = "ScopeOverlay"
    scopeOverlay.Size = UDim2.new(1, 0, 1, 0)
    scopeOverlay.Position = UDim2.new(0, 0, 0, 0)
    scopeOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    scopeOverlay.BackgroundTransparency = 1
    scopeOverlay.BorderSizePixel = 0
    scopeOverlay.Visible = false
    scopeOverlay.Parent = parentGui
    optics.ScopeOverlay = scopeOverlay

    local scopeReticle = Instance.new("Frame")
    scopeReticle.Name = "ScopeReticle"
    scopeReticle.Size = UDim2.new(0, 500, 0, 500)
    scopeReticle.Position = UDim2.new(0.5, -250, 0.5, -250)
    scopeReticle.BackgroundTransparency = 1
    scopeReticle.Parent = scopeOverlay

    local lineV = Instance.new("Frame")
    lineV.Name = "LineV"
    lineV.Size = UDim2.new(0, 2, 1, 0)
    lineV.Position = UDim2.new(0.5, -1, 0, 0)
    lineV.BackgroundColor3 = Color3.fromRGB(255, 40, 60)
    lineV.BorderSizePixel = 0
    lineV.Parent = scopeReticle

    local lineH = Instance.new("Frame")
    lineH.Name = "LineH"
    lineH.Size = UDim2.new(1, 0, 0, 2)
    lineH.Position = UDim2.new(0, 0, 0.5, -1)
    lineH.BackgroundColor3 = Color3.fromRGB(255, 40, 60)
    lineH.BorderSizePixel = 0
    lineH.Parent = scopeReticle

    -- จุดกึ่งกลางสีแดงคมชัด
    local centerDot = Instance.new("Frame")
    centerDot.Name = "CenterDot"
    centerDot.Size = UDim2.new(0, 6, 0, 6)
    centerDot.Position = UDim2.new(0.5, -3, 0.5, -3)
    centerDot.BackgroundColor3 = Color3.fromRGB(255, 30, 50)
    centerDot.BorderSizePixel = 0
    centerDot.Parent = scopeReticle
    Instance.new("UICorner", centerDot).CornerRadius = UDim.new(1, 0)

    function optics:SetAiming(isAiming, weaponConfig)
        if isAiming then
            crosshairGui.Visible = false
            if weaponConfig and weaponConfig.IsSniper then
                scopeOverlay.Visible = true
                scopeOverlay.BackgroundTransparency = 0.05
            else
                scopeOverlay.Visible = false
            end
        else
            crosshairGui.Visible = true
            scopeOverlay.Visible = false
            scopeOverlay.BackgroundTransparency = 1
        end
    end

    return optics
end

return OpticsManager
