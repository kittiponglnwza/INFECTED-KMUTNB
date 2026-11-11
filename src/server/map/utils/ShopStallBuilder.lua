--[[
    ShopStallBuilder.lua
    โมดูลกลางสร้าง "ร้านค้าและร้านอาหารพร้อมรายละเอียดภายในครบชุด" สำหรับโรงอาหารชั้น 2 อาคาร 40 ปี มจพ.
    รองรับทั้ง 8 ร้าน (ก๋วยเตี๋ยวเรือ, ข้าวมันไก่, ข้าวราดแกง, หมูกรอบ-หมูแดง, ชานมไข่มุก, ผลไม้ปั่น, สเต็ก/ไข่เจียว, อาหารตามสั่ง/ส้มตำ):
      - พื้นกระเบื้องครัวแยกโซนร้านค้า + แสงไฟสว่างอบอุ่นในร้าน + คราบน้ำมัน/น้ำหกเล็กน้อยสไตล์สยองขวัญ
      - ตู้โชว์กระจก + ถาดอาหาร/อุปกรณ์เฉพาะประจำร้าน + ช่องรับอาหารพร้อมพวงเครื่องปรุง, ทิชชู่, ป้าย QR สแกนจ่าย
      - ครัวหลังร้าน: เคาน์เตอร์สแตนเลส, ฮูดดูดควัน, ตู้แช่เครื่องดื่มกระจกเรืองแสง, ชั้นวางขวดซอส, กระดานเมนูเรืองแสงบนผนังหลัง
      - เว้นจุดวางของฟาร์มด้านหน้าเคาน์เตอร์ (stall.z) และหลังครัว (Z = ±21.5) ให้หยิบไอเทมได้สะดวกไม่ติดพร็อพ
]]

local PartBuilder = require(script.Parent.PartBuilder)

local ShopStallBuilder = {}

local CHROME         = Color3.fromRGB(195, 202, 210)
local STEEL_DARK     = Color3.fromRGB(68, 74, 82)
local BLACK_METAL    = Color3.fromRGB(32, 36, 42)
local TILE_KITCHEN   = Color3.fromRGB(198, 194, 186)
local WOOD_CHOP      = Color3.fromRGB(178, 134, 88)
local GLASS_TINT     = Color3.fromRGB(205, 232, 246)
local WHITE_CERAMIC  = Color3.fromRGB(242, 242, 238)

-- แปลงพิกัดท้องถิ่นเทียบกับหน้าร้าน (frontFaceX, stall.z) เป็นโลกจริงทั้งฝั่งซ้าย (side=-1) และขวา (side=1)
local function stallCF(frontX, baseZ, floorY, side, intoDepth, y, alongZ)
    return CFrame.new(frontX + side * intoDepth, floorY + y, baseZ + alongZ)
end

-- สร้างตู้แช่เครื่องดื่มกระจกใสพร้อมชั้นขวดน้ำสีสันด้านใน
local function buildDrinkCooler(parent, frontX, baseZ, floorY, side, alongZ)
    local cooler = Instance.new("Model")
    cooler.Name = "BeverageCooler"
    cooler.Parent = parent

    local dX = 29.8
    -- ตัวตู้เย็นโลหะ + หน้าบานกระจกใส
    PartBuilder.makePart(cooler, "Body", Vector3.new(3.6, 8.2, 5.2),
        stallCF(frontX, baseZ, floorY, side, dX, 4.1, alongZ), Color3.fromRGB(230, 234, 238), Enum.Material.Metal)
    PartBuilder.makePart(cooler, "InteriorBack", Vector3.new(0.2, 7.0, 4.4),
        stallCF(frontX, baseZ, floorY, side, dX + 1.1, 4.2, alongZ), Color3.fromRGB(175, 230, 245), Enum.Material.Neon, { CanCollide = false })
    PartBuilder.makePart(cooler, "GlassDoor", Vector3.new(0.18, 6.8, 4.5),
        stallCF(frontX, baseZ, floorY, side, dX - 1.82, 4.2, alongZ), GLASS_TINT, Enum.Material.Glass, { Transparency = 0.55 })
    PartBuilder.makePart(cooler, "TopSign", Vector3.new(0.3, 1.0, 4.6),
        stallCF(frontX, baseZ, floorY, side, dX - 1.75, 7.6, alongZ), Color3.fromRGB(25, 115, 210), Enum.Material.Neon, { CanCollide = false })

    local drinkColors = {
        Color3.fromRGB(215, 45, 45),
        Color3.fromRGB(50, 175, 80),
        Color3.fromRGB(245, 165, 35),
        Color3.fromRGB(65, 155, 235),
    }
    for shelf = 1, 3 do
        local sy = 1.8 + (shelf - 1) * 1.8
        PartBuilder.makePart(cooler, "Shelf_" .. shelf, Vector3.new(2.2, 0.14, 4.4),
            stallCF(frontX, baseZ, floorY, side, dX - 0.3, sy, alongZ), CHROME, Enum.Material.Metal, { CanCollide = false })
        for b = 1, 4 do
            local bz = alongZ - 1.5 + (b - 1) * 1.0
            PartBuilder.makeCylinder(cooler, "Bottle_" .. shelf .. "_" .. b, Vector3.new(0.95, 0.55, 0.55),
                stallCF(frontX, baseZ, floorY, side, dX - 0.9, sy + 0.55, bz) * CFrame.Angles(0, 0, math.rad(90)),
                drinkColors[((shelf + b) % #drinkColors) + 1], Enum.Material.SmoothPlastic, { CanCollide = false })
        end
    end
end

-- สร้างพวงเครื่องปรุง 4 ช่อง + ที่ใส่ทิชชู่ + ที่ใส่ช้อนส้อม + ป้าย QR จ่ายเงินบนเคาน์เตอร์ฝั่งรับอาหาร
local function buildServingProps(parent, frontX, baseZ, floorY, side)
    -- พวงเครื่องปรุงสแตนเลส (พริกป่น, น้ำตาล, น้ำส้ม, น้ำปลา)
    local rackZ = 9.5
    local rackD = 2.0
    PartBuilder.makePart(parent, "CondimentRackBase", Vector3.new(1.8, 0.16, 1.8),
        stallCF(frontX, baseZ, floorY, side, rackD, 4.28, rackZ), CHROME, Enum.Material.Metal, { CanCollide = false })
    local jarColors = {
        { dx = -0.45, dz = -0.45, col = Color3.fromRGB(190, 42, 28) },
        { dx =  0.45, dz = -0.45, col = Color3.fromRGB(248, 246, 238) },
        { dx = -0.45, dz =  0.45, col = Color3.fromRGB(235, 210, 120) },
        { dx =  0.45, dz =  0.45, col = Color3.fromRGB(115, 62, 24) },
    }
    for jIdx, jc in ipairs(jarColors) do
        PartBuilder.makeCylinder(parent, "CondimentJar_" .. jIdx, Vector3.new(0.75, 0.55, 0.55),
            stallCF(frontX, baseZ, floorY, side, rackD + jc.dx, 4.7, rackZ + jc.dz) * CFrame.Angles(0, 0, math.rad(90)),
            jc.col, Enum.Material.Glass, { Transparency = 0.25, CanCollide = false })
    end

    -- กล่องทิชชู่ + กระบอกใส่ช้อนส้อม + ป้าย QR PromptPay
    PartBuilder.makePart(parent, "NapkinBox", Vector3.new(1.1, 0.75, 1.6),
        stallCF(frontX, baseZ, floorY, side, 2.1, 4.58, 12.2), Color3.fromRGB(220, 65, 65), Enum.Material.SmoothPlastic, { CanCollide = false })
    PartBuilder.makeCylinder(parent, "CutleryCup", Vector3.new(1.05, 0.85, 0.85),
        stallCF(frontX, baseZ, floorY, side, 2.3, 4.72, 14.0) * CFrame.Angles(0, 0, math.rad(90)),
        CHROME, Enum.Material.Metal, { CanCollide = false })
    PartBuilder.makePart(parent, "QRPaymentStand", Vector3.new(0.16, 1.35, 1.0),
        stallCF(frontX, baseZ, floorY, side, 1.2, 4.88, 6.2) * CFrame.Angles(0, 0, side * math.rad(-14)),
        Color3.fromRGB(24, 92, 175), Enum.Material.SmoothPlastic, { CanCollide = false })
    PartBuilder.makePart(parent, "QRCodeFace", Vector3.new(0.18, 0.78, 0.78),
        stallCF(frontX, baseZ, floorY, side, 1.15, 4.92, 6.2) * CFrame.Angles(0, 0, side * math.rad(-14)),
        WHITE_CERAMIC, Enum.Material.SmoothPlastic, { CanCollide = false })
end

-- พร็อพเฉพาะตามประเภทของร้าน (ในตู้กระจกหน้า + บนโต๊ะเตรียมของหลังครัว)
local function buildThemedProps(parent, preset, frontX, baseZ, floorY, side)
    local dFront = 2.0
    local dBack = 30.0

    if preset == "Noodle" then
        -- หม้อก๋วยเตี๋ยวสแตนเลสใหญ่ 2 ช่อง + น้ำซุปข้นเดือด + ตะกร้อลวกเส้น
        PartBuilder.makeCylinder(parent, "NoodlePot", Vector3.new(2.0, 3.6, 3.6),
            stallCF(frontX, baseZ, floorY, side, dFront, 5.1, -9.5) * CFrame.Angles(0, 0, math.rad(90)),
            CHROME, Enum.Material.Metal)
        PartBuilder.makeCylinder(parent, "NoodleBroth", Vector3.new(0.18, 3.2, 3.2),
            stallCF(frontX, baseZ, floorY, side, dFront, 6.08, -9.5) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(92, 48, 22), Enum.Material.SmoothPlastic, { CanCollide = false })
        -- พวงเส้นหมี่/บะหมี่/ลูกชิ้นแขวนในตู้กระจก
        for k = 1, 3 do
            local kz = -15.0 + (k - 1) * 1.8
            PartBuilder.makeCylinder(parent, "NoodleBundle_" .. k, Vector3.new(1.5, 0.9, 0.9),
                stallCF(frontX, baseZ, floorY, side, dFront, 6.2, kz) * CFrame.Angles(0, 0, math.rad(90)),
                (k == 3) and Color3.fromRGB(235, 225, 195) or Color3.fromRGB(245, 205, 82), Enum.Material.Fabric, { CanCollide = false })
        end
        -- ชามตราไก่ซ้อนหลังร้าน
        for s = 1, 2 do
            PartBuilder.makeCylinder(parent, "BowlStack_" .. s, Vector3.new(1.6, 1.4, 1.4),
                stallCF(frontX, baseZ, floorY, side, dBack, 4.4, -7.5 + s * 2.5) * CFrame.Angles(0, 0, math.rad(90)),
                WHITE_CERAMIC, Enum.Material.SmoothPlastic)
        end

    elseif preset == "ChickenRice" then
        -- ไก่ต้มแขวนบนราวโครเมียม + เขียงไม้สับไก่ + มีดอีโต้ + หม้อหุงข้าวอุตสาหกรรมขนาดใหญ่
        PartBuilder.makePart(parent, "HangRail", Vector3.new(0.18, 0.18, 12.0),
            stallCF(frontX, baseZ, floorY, side, dFront, 6.85, -10.5), CHROME, Enum.Material.Metal, { CanCollide = false })
        for k = 1, 3 do
            PartBuilder.makeCylinder(parent, "HangingChicken_" .. k, Vector3.new(1.75, 1.25, 1.1),
                stallCF(frontX, baseZ, floorY, side, dFront, 5.75, -14.0 + k * 2.5) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(242, 212, 165), Enum.Material.SmoothPlastic, { CanCollide = false })
        end
        PartBuilder.makeCylinder(parent, "ChopBlock", Vector3.new(0.7, 2.4, 2.4),
            stallCF(frontX, baseZ, floorY, side, dFront, 4.55, -5.2) * CFrame.Angles(0, 0, math.rad(90)),
            WOOD_CHOP, Enum.Material.Wood)
        PartBuilder.makePart(parent, "CleaverBlade", Vector3.new(0.08, 0.5, 1.2),
            stallCF(frontX, baseZ, floorY, side, dFront, 5.1, -5.2) * CFrame.Angles(0, math.rad(25), math.rad(15)),
            CHROME, Enum.Material.Metal, { CanCollide = false })
        -- หม้อหุงข้าวใหญ่ด้านซ้ายของครัว (หลบตรงกลาง z=0 ที่วางปืน Frenzy)
        PartBuilder.makeCylinder(parent, "BigRiceCooker", Vector3.new(2.2, 3.2, 3.2),
            stallCF(frontX, baseZ, floorY, side, dBack, 4.7, -9.0) * CFrame.Angles(0, 0, math.rad(90)),
            CHROME, Enum.Material.Metal)

    elseif preset == "CurryRice" then
        -- ถาดแกงสแตนเลส 6 ช่องเรียงในตู้โชว์ (แกงเขียวหวาน, พะแนง, แกงส้ม, ผัดกะเพรา, ไข่ดาว, ปลาทอด)
        local curryColors = {
            Color3.fromRGB(115, 158, 72),
            Color3.fromRGB(185, 72, 35),
            Color3.fromRGB(210, 110, 28),
            Color3.fromRGB(125, 82, 42),
            Color3.fromRGB(245, 205, 65),
            Color3.fromRGB(165, 95, 48),
        }
        for i, col in ipairs(curryColors) do
            local gz = -15.5 + (i - 1) * 2.6
            PartBuilder.makePart(parent, "CurryPan_" .. i, Vector3.new(2.2, 0.55, 2.2),
                stallCF(frontX, baseZ, floorY, side, dFront, 4.48, gz), CHROME, Enum.Material.Metal, { CanCollide = false })
            PartBuilder.makePart(parent, "CurryFood_" .. i, Vector3.new(1.9, 0.25, 1.9),
                stallCF(frontX, baseZ, floorY, side, dFront, 4.68, gz), col, Enum.Material.SmoothPlastic, { CanCollide = false })
        end
        PartBuilder.makeCylinder(parent, "CurryStockPot", Vector3.new(2.4, 3.0, 3.0),
            stallCF(frontX, baseZ, floorY, side, dBack, 4.8, -6.0) * CFrame.Angles(0, 0, math.rad(90)),
            CHROME, Enum.Material.Metal)

    elseif preset == "CrispyPork" then
        -- หมูกรอบ + หมูแดง + เป็ดย่างแขวนในตู้แดง + หม้อน้ำราดหมูแดง + เขียงสับ
        PartBuilder.makePart(parent, "RedGlowTrim", Vector3.new(0.18, 0.25, 13.0),
            stallCF(frontX, baseZ, floorY, side, dFront - 0.8, 7.05, -10.0), Color3.fromRGB(255, 75, 45), Enum.Material.Neon, { CanCollide = false })
        local porkColors = {
            Color3.fromRGB(185, 52, 36),
            Color3.fromRGB(205, 145, 75),
            Color3.fromRGB(190, 58, 38),
            Color3.fromRGB(215, 155, 85),
        }
        for k, pc in ipairs(porkColors) do
            PartBuilder.makePart(parent, "HangingRoast_" .. k, Vector3.new(0.75, 1.85, 1.25),
                stallCF(frontX, baseZ, floorY, side, dFront, 5.75, -14.5 + k * 2.2), pc, Enum.Material.SmoothPlastic, { CanCollide = false })
        end
        PartBuilder.makeCylinder(parent, "RedGravyPot", Vector3.new(1.5, 2.0, 2.0),
            stallCF(frontX, baseZ, floorY, side, dFront, 4.95, -5.0) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(142, 42, 24), Enum.Material.Metal)
        PartBuilder.makeCylinder(parent, "RoastChopBlock", Vector3.new(0.75, 2.3, 2.3),
            stallCF(frontX, baseZ, floorY, side, dBack, 4.0, 7.0) * CFrame.Angles(0, 0, math.rad(90)),
            WOOD_CHOP, Enum.Material.Wood)

    elseif preset == "BobaCoffee" then
        -- ถาดไข่มุกสีดำ + เฉาก๊วย + พุดดิ้งในตู้ท็อปปิ้ง + เครื่องซีลฝาแก้ว + ทาวเวอร์แก้วพลาสติก + กาชงกาแฟโบราณ
        local bobaCols = {
            Color3.fromRGB(26, 22, 24),
            Color3.fromRGB(48, 34, 24),
            Color3.fromRGB(242, 198, 72),
            Color3.fromRGB(235, 145, 58),
        }
        for b, bc in ipairs(bobaCols) do
            local bz = -15.0 + (b - 1) * 2.5
            PartBuilder.makePart(parent, "ToppingPan_" .. b, Vector3.new(2.0, 0.55, 2.1),
                stallCF(frontX, baseZ, floorY, side, dFront, 4.48, bz), CHROME, Enum.Material.Metal, { CanCollide = false })
            PartBuilder.makePart(parent, "ToppingFill_" .. b, Vector3.new(1.7, 0.3, 1.8),
                stallCF(frontX, baseZ, floorY, side, dFront, 4.66, bz), bc, Enum.Material.SmoothPlastic, { CanCollide = false })
        end
        -- เครื่องซีลแก้ว + กาต้มชาสแตนเลส + แก้วพลาสติกเรียงซ้อน
        PartBuilder.makePart(parent, "CupSealer", Vector3.new(1.8, 2.4, 1.8),
            stallCF(frontX, baseZ, floorY, side, dFront, 5.4, -4.8), BLACK_METAL, Enum.Material.Metal)
        for s = 1, 3 do
            PartBuilder.makeCylinder(parent, "CupTower_" .. s, Vector3.new(2.2, 0.85, 0.85),
                stallCF(frontX, baseZ, floorY, side, dBack, 4.7, -11.0 + s * 1.4) * CFrame.Angles(0, 0, math.rad(90)),
                WHITE_CERAMIC, Enum.Material.SmoothPlastic, { CanCollide = false })
        end
        PartBuilder.makeCylinder(parent, "ThaiTeaKettle", Vector3.new(2.1, 2.2, 2.2),
            stallCF(frontX, baseZ, floorY, side, dBack, 4.65, 5.5) * CFrame.Angles(0, 0, math.rad(90)),
            CHROME, Enum.Material.Metal)

    elseif preset == "FruitSmoothie" then
        -- ถาดผลไม้สดบนน้ำแข็งบด (แตงโม, สับปะรด, มะม่วง, ฝรั่ง, ส้ม) + เครื่องปั่นสมูทตี้ 2 เครื่อง
        local fruitCols = {
            Color3.fromRGB(228, 52, 65),
            Color3.fromRGB(248, 215, 58),
            Color3.fromRGB(115, 198, 72),
            Color3.fromRGB(245, 145, 38),
            Color3.fromRGB(175, 65, 185),
        }
        PartBuilder.makePart(parent, "CrushedIceBed", Vector3.new(2.4, 0.45, 13.5),
            stallCF(frontX, baseZ, floorY, side, dFront, 4.4, -10.0), Color3.fromRGB(215, 240, 250), Enum.Material.Ice, { CanCollide = false })
        for f, fc in ipairs(fruitCols) do
            PartBuilder.makePart(parent, "FruitTray_" .. f, Vector3.new(1.7, 0.75, 2.1),
                stallCF(frontX, baseZ, floorY, side, dFront, 4.88, -15.2 + (f - 1) * 2.6), fc, Enum.Material.SmoothPlastic, { CanCollide = false })
        end
        for bl = 1, 2 do
            local bz = -9.0 + (bl - 1) * 3.5
            PartBuilder.makePart(parent, "BlenderBase_" .. bl, Vector3.new(1.3, 1.0, 1.3),
                stallCF(frontX, baseZ, floorY, side, dBack, 4.1, bz), BLACK_METAL, Enum.Material.Metal)
            PartBuilder.makeCylinder(parent, "BlenderJar_" .. bl, Vector3.new(1.6, 1.0, 1.0),
                stallCF(frontX, baseZ, floorY, side, dBack, 5.4, bz) * CFrame.Angles(0, 0, math.rad(90)),
                GLASS_TINT, Enum.Material.Glass, { Transparency = 0.45 })
        end

    elseif preset == "SteakOmelette" then
        -- เตาย่างสเต็กกระทะแบน + ขวดซอสพริก/มัสตาร์ด + ถาดสเต็ก (เว้น z=0 บนโต๊ะหลังให้ F2_Kitchen_Ammo)
        PartBuilder.makePart(parent, "SteakGrillPlate", Vector3.new(2.5, 0.65, 8.0),
            stallCF(frontX, baseZ, floorY, side, dFront, 4.5, -10.5), STEEL_DARK, Enum.Material.Metal)
        for p = 1, 3 do
            PartBuilder.makeCylinder(parent, "SteakPatty_" .. p, Vector3.new(0.28, 1.45, 1.05),
                stallCF(frontX, baseZ, floorY, side, dFront, 4.92, -13.0 + (p - 1) * 2.5) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(108, 62, 38), Enum.Material.Slate, { CanCollide = false })
        end
        -- ขวดซอสแดง/เหลือง
        PartBuilder.makeCylinder(parent, "KetchupBottle", Vector3.new(1.1, 0.48, 0.48),
            stallCF(frontX, baseZ, floorY, side, dFront, 4.75, -5.5) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(215, 38, 38), Enum.Material.SmoothPlastic, { CanCollide = false })
        PartBuilder.makeCylinder(parent, "MustardBottle", Vector3.new(1.1, 0.48, 0.48),
            stallCF(frontX, baseZ, floorY, side, dFront, 4.75, -4.6) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(242, 198, 42), Enum.Material.SmoothPlastic, { CanCollide = false })
        -- กระทะเจียวไข่ด้านหลังฝั่งซ้าย (ไม่ทับ z=0 ที่วางกล่องกระสุน)
        PartBuilder.makeCylinder(parent, "OmelettePan", Vector3.new(0.32, 2.4, 2.4),
            stallCF(frontX, baseZ, floorY, side, dBack, 3.85, -8.5) * CFrame.Angles(0, 0, math.rad(90)),
            BLACK_METAL, Enum.Material.Metal)

    elseif preset == "StirFrySomtum" then
        -- ครกส้มตำ + สากไม้หน้าเคาน์เตอร์ + ถาดมะละกอขูด/มะเขือเทศ + เตาแก๊สกระทะเหล็กคู่ด้านหลัง
        PartBuilder.makeCylinder(parent, "ClayMortar", Vector3.new(1.6, 1.85, 1.85),
            stallCF(frontX, baseZ, floorY, side, dFront, 5.0, -12.0) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(165, 86, 48), Enum.Material.Slate)
        PartBuilder.makeCylinder(parent, "WoodPestle", Vector3.new(1.9, 0.42, 0.42),
            stallCF(frontX, baseZ, floorY, side, dFront, 5.8, -12.0) * CFrame.Angles(math.rad(18), 0, math.rad(72)),
            WOOD_CHOP, Enum.Material.Wood, { CanCollide = false })
        PartBuilder.makePart(parent, "PapayaTray", Vector3.new(1.8, 0.4, 3.2),
            stallCF(frontX, baseZ, floorY, side, dFront, 4.4, -8.0), WHITE_CERAMIC, Enum.Material.SmoothPlastic)
        for w = 1, 2 do
            PartBuilder.makeCylinder(parent, "IronWok_" .. w, Vector3.new(0.75, 2.8, 2.8),
                stallCF(frontX, baseZ, floorY, side, dBack, 4.0, -8.0 + (w - 1) * 7.5) * CFrame.Angles(0, 0, math.rad(90)),
                BLACK_METAL, Enum.Material.Metal)
        end
    end
end

-- สร้างแถวร้านค้าครบทุกองค์ประกอบ (ทั้งฝั่งซ้าย West และฝั่งขวา East)
function ShopStallBuilder.buildStallRow(parent, opts)
    local row = Instance.new("Model")
    row.Name = opts.modelName
    row.Parent = parent

    local side = opts.side
    local floorY = opts.floorY
    local wallH = opts.wallH
    local wallThick = opts.wallThick
    local wallColor = opts.wallColor
    local wallMat = opts.wallMaterial
    local stalls = opts.stalls

    local stallDepth = 34
    local stallWidth = 43
    local totalStallsSpan = stallWidth * #stalls

    local outerWallX = side * (150 - wallThick / 2)
    local dividerMidX = side * (150 - stallDepth / 2)
    local frontFaceX = side * (150 - stallDepth)      -- ±116
    local counterX = frontFaceX + side * 2.0          -- ±118
    local fasciaX = frontFaceX + side * (wallThick / 2)
    local backBenchX = side * (150 - 4.0)             -- ±146
    local signFace = (side < 0) and Enum.NormalId.Right or Enum.NormalId.Left

    PartBuilder.makePart(row, "OuterWall", Vector3.new(wallThick, wallH, totalStallsSpan),
        CFrame.new(outerWallX, floorY + wallH / 2, 0), wallColor, wallMat)

    for idx, stall in ipairs(stalls) do
        local sM = Instance.new("Model")
        sM.Name = opts.modelName .. "_Stall" .. idx
        sM.Parent = row

        -- ผนังกั้นระหว่างร้าน
        if idx < #stalls then
            PartBuilder.makePart(sM, "Divider", Vector3.new(stallDepth, wallH, 1.2),
                CFrame.new(dividerMidX, floorY + wallH / 2, stall.z + stallWidth / 2), wallColor, wallMat)
        end

        -- พื้นกระเบื้องในครัวร้านค้า + แอ่งน้ำมัน/น้ำหกเล็กน้อย
        PartBuilder.makePart(sM, "KitchenTileFloor", Vector3.new(stallDepth - 5.0, 0.03, stallWidth - 2.0),
            stallCF(frontFaceX, stall.z, floorY, side, stallDepth / 2 + 1.0, 0.02, 0), TILE_KITCHEN, Enum.Material.SmoothPlastic, { CanCollide = false })
        PartBuilder.makePart(sM, "GreasePuddle", Vector3.new(3.2, 0.02, 2.4),
            stallCF(frontFaceX, stall.z, floorY, side, 15.0, 0.04, 4.0) * CFrame.Angles(0, math.rad(18), 0),
            Color3.fromRGB(72, 62, 46), Enum.Material.Glass, { Transparency = 0.35, Reflectance = 0.5, CanCollide = false })

        -- โต๊ะเตรียมของด้านหลัง (เว้นมุมขวา +11..+20 ให้วางตู้แช่เครื่องดื่มไม่ซ้อนทับ) + ฮูดดูดควันสแตนเลส + ชั้นวางขวดซอส
        PartBuilder.makePart(sM, "BackKitchenBench", Vector3.new(3.2, 3.6, stallWidth - 13),
            CFrame.new(backBenchX, floorY + 1.8, stall.z - 4.0), PartBuilder.COLORS.steel, Enum.Material.Metal)
        PartBuilder.makePart(sM, "ExhaustHood", Vector3.new(5.2, 1.8, 22.0),
            stallCF(frontFaceX, stall.z, floorY, side, 31.0, 12.2, -3.5), CHROME, Enum.Material.Metal)
        PartBuilder.makePart(sM, "BackWallShelf", Vector3.new(1.4, 0.2, 14.0),
            stallCF(frontFaceX, stall.z, floorY, side, 32.0, 6.2, -4.0), CHROME, Enum.Material.Metal)
        for b = 1, 5 do
            local sz = -9.5 + (b - 1) * 2.6
            local col = (b % 2 == 0) and Color3.fromRGB(165, 42, 32) or Color3.fromRGB(58, 125, 48)
            PartBuilder.makeCylinder(sM, "SauceBottle_" .. b, Vector3.new(1.1, 0.42, 0.42),
                stallCF(frontFaceX, stall.z, floorY, side, 32.0, 6.85, sz) * CFrame.Angles(0, 0, math.rad(90)),
                col, Enum.Material.Glass, { CanCollide = false })
        end

        -- ป้ายเมนูร้านเรืองแสงติดผนังด้านหลัง (เห็นจากฝั่งโรงอาหารชัดเจน!)
        PartBuilder.makeSign(sM, "BackMenuBoard", stall.menuText or stall.name, Vector3.new(0.2, 3.6, 20.0),
            stallCF(frontFaceX, stall.z, floorY, side, 32.85, 9.5, -3.5).Position,
            signFace, Color3.fromRGB(32, 36, 44), Color3.fromRGB(255, 244, 210))

        -- เคาน์เตอร์หน้าร้าน (X = ±118, เว้นช่องทางเดินเข้าด้าน +17.5..+21)
        local cLen = stallWidth - 7.0
        PartBuilder.makePart(sM, "Counter", Vector3.new(4.0, 3.8, cLen),
            CFrame.new(counterX, floorY + 1.9, stall.z - 2.0), Color3.fromRGB(220, 215, 205), Enum.Material.Concrete)
        PartBuilder.makePart(sM, "CounterTop", Vector3.new(4.2, 0.4, cLen + 0.4),
            CFrame.new(counterX, floorY + 4.0, stall.z - 2.0), Color3.fromRGB(55, 58, 64), Enum.Material.Granite)
        -- แถบตกแต่งหน้าเคาน์เตอร์สีประจำร้าน
        PartBuilder.makePart(sM, "CounterAccentBand", Vector3.new(0.18, 0.75, cLen),
            CFrame.new(frontFaceX - side * 0.05, floorY + 3.2, stall.z - 2.0), stall.color, Enum.Material.SmoothPlastic, { CanCollide = false })

        -- ตู้โชว์กระจกครอบเฉพาะซีกซ้ายของเคาน์เตอร์ (เหลือซีกขวาเป็นช่องเสิร์ฟ & จุดฟาร์ม F2_Stall*)
        PartBuilder.makePart(sM, "GlassCase", Vector3.new(2.2, 2.9, 14.5),
            CFrame.new(counterX, floorY + 5.65, stall.z - 10.2), GLASS_TINT, Enum.Material.Glass, { Transparency = 0.62 })
        PartBuilder.makePart(sM, "GlassCaseFrameTop", Vector3.new(2.3, 0.18, 14.7),
            CFrame.new(counterX, floorY + 7.12, stall.z - 10.2), CHROME, Enum.Material.Metal, { CanCollide = false })

        -- ตู้แช่เครื่องดื่ม + พวงเครื่องปรุง/ทิชชู่/QR + พร็อพเฉพาะของร้าน
        buildDrinkCooler(sM, frontFaceX, stall.z, floorY, side, 15.8)
        buildServingProps(sM, frontFaceX, stall.z, floorY, side)
        buildThemedProps(sM, stall.preset, frontFaceX, stall.z, floorY, side)

        -- ป้ายชื่อร้านบนฝ้า + ไฟส่องหน้าร้านให้อ่านง่ายมีชีวิตชีวา
        PartBuilder.makePart(sM, "SignFascia", Vector3.new(wallThick, 4.5, stallWidth - 1.2),
            CFrame.new(fasciaX, floorY + 13.5, stall.z), stall.color, Enum.Material.SmoothPlastic)
        PartBuilder.makeSign(sM, "Sign", stall.name, Vector3.new(0.15, 3.4, stallWidth - 2.4),
            Vector3.new(frontFaceX - side * 0.1, floorY + 13.5, stall.z),
            signFace, stall.color, Color3.fromRGB(255, 255, 255))

        PartBuilder.addPointLight(sM, "StallWarmLight",
            stallCF(frontFaceX, stall.z, floorY, side, 8.0, 14.5, 0).Position,
            Color3.fromRGB(255, 232, 195), 34, 0.85)
    end

    return row
end

return ShopStallBuilder
