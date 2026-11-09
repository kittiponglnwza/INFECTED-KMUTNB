--[[
    ValorantBuyMenu.lua
    โมดูลจัดการหน้าต่างคลังแสงเลือกปืน VALORANT ARSENAL
    - รองรับการกด [B] เปิด/ปิด
    - ปลดล็อคเมาส์ด้วย Engine Modal=true และ BindToRenderStep ชนะกล้อง 100%
    - มีปุ่มปิดชัดเจน และแสดงข้อมูล ดาเมจ/ความจุกระสุน ของปืนทุกกระบอก
]]

local ValorantBuyMenu = {}

function ValorantBuyMenu.create(parentGui, arsenalData, onSelectWeapon)
    local buyMenu = Instance.new("Frame")
    buyMenu.Name = "BuyMenu"
    buyMenu.Size = UDim2.new(0.92, 0, 0.88, 0)
    buyMenu.Position = UDim2.new(0.04, 0, 0.06, 0)
    buyMenu.BackgroundColor3 = Color3.fromRGB(15, 23, 34)
    buyMenu.BackgroundTransparency = 0.05
    buyMenu.Visible = false
    buyMenu.Parent = parentGui
    Instance.new("UICorner", buyMenu).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", buyMenu).Color = Color3.fromRGB(255, 70, 85)

    -- คำสั่งระดับ Engine: ปลดล็อคเมาส์ออกจาก First Person ทันทีที่ GUI นี้แสดง
    local engineUnlocker = Instance.new("TextButton")
    engineUnlocker.Name = "EngineModalUnlocker"
    engineUnlocker.Size = UDim2.new(0, 0, 0, 0)
    engineUnlocker.BackgroundTransparency = 1
    engineUnlocker.Text = ""
    engineUnlocker.Modal = true
    engineUnlocker.Parent = buyMenu

    -- Header
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -160, 0, 45)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 70, 85)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "VALORANT ARSENAL // คลังแสงเลือกปืนทดสอบ (กด [B] หรือคลิกปุ่มเพื่อปิด)"
    title.Parent = buyMenu

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 120, 0, 34)
    closeBtn.Position = UDim2.new(1, -140, 0, 14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 85)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Text = "✕ ปิดเมนู [B]"
    closeBtn.Parent = buyMenu
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    local categories = { "Sidearms", "SMGs", "Shotguns", "Rifles", "Snipers", "Heavy" }
    local colWidth = 1 / #categories

    for i, catName in ipairs(categories) do
        local col = Instance.new("Frame")
        col.Size = UDim2.new(colWidth, -12, 1, -70)
        col.Position = UDim2.new((i - 1) * colWidth, 6, 0, 60)
        col.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
        col.BackgroundTransparency = 0.3
        col.Parent = buyMenu
        Instance.new("UICorner", col).CornerRadius = UDim.new(0, 6)

        local catTitle = Instance.new("TextLabel")
        catTitle.Size = UDim2.new(1, 0, 0, 30)
        catTitle.BackgroundTransparency = 1
        catTitle.TextColor3 = Color3.fromRGB(255, 215, 100)
        catTitle.Font = Enum.Font.GothamBold
        catTitle.TextSize = 14
        catTitle.Text = catName:upper()
        catTitle.Parent = col

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 8)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.Parent = col

        for key, w in pairs(arsenalData) do
            if w.Category == catName then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.92, 0, 0, 65)
                btn.BackgroundColor3 = Color3.fromRGB(28, 38, 54)
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = true
                btn.Text = ""
                btn.Parent = col
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

                local wTitle = Instance.new("TextLabel")
                wTitle.Size = UDim2.new(1, -12, 0, 22)
                wTitle.Position = UDim2.new(0, 6, 0, 4)
                wTitle.BackgroundTransparency = 1
                wTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                wTitle.Font = Enum.Font.GothamBold
                wTitle.TextSize = 15
                wTitle.TextXAlignment = Enum.TextXAlignment.Left
                wTitle.Text = w.Name
                wTitle.Parent = btn

                local wDmg = Instance.new("TextLabel")
                wDmg.Size = UDim2.new(1, -12, 0, 16)
                wDmg.Position = UDim2.new(0, 6, 0, 26)
                wDmg.BackgroundTransparency = 1
                wDmg.TextColor3 = Color3.fromRGB(160, 180, 205)
                wDmg.Font = Enum.Font.Gotham
                wDmg.TextSize = 11
                wDmg.TextXAlignment = Enum.TextXAlignment.Left
                wDmg.Text = string.format("หัว %d | ตัว %d", w.HeadDmg, w.BodyDmg)
                wDmg.Parent = btn

                local wMag = Instance.new("TextLabel")
                wMag.Size = UDim2.new(1, -12, 0, 16)
                wMag.Position = UDim2.new(0, 6, 0, 44)
                wMag.BackgroundTransparency = 1
                wMag.TextColor3 = Color3.fromRGB(255, 70, 85)
                wMag.Font = Enum.Font.GothamBold
                wMag.TextSize = 11
                wMag.TextXAlignment = Enum.TextXAlignment.Left
                wMag.Text = string.format("แม็ก: %d นัด (%s)", w.Mag, w.FiringType)
                wMag.Parent = btn

                btn.MouseButton1Click:Connect(function()
                    onSelectWeapon(key)
                end)
            end
        end
    end

    local menuObj = {
        Frame = buyMenu,
        CloseButton = closeBtn
    }

    return menuObj
end

return ValorantBuyMenu
