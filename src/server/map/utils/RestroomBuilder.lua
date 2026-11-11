--[[
    RestroomBuilder.lua
    โมดูลกลางสร้าง "ห้องน้ำสยองขวัญฟาร์มของได้ + ประตูเปิด-ปิด/ซอมบี้พังได้ทุกบาน"
    ใช้ร่วมกันทั้งชั้น 2, 3, 4-6, 7, 8-11 และ 12 เพื่อไม่ให้โค้ดซ้ำซ้อนและอัปเกรดได้พร้อมกันทุกชั้น:
      - ประตูทางเข้าห้องน้ำหลัก (RestroomMain) เปิด/ปิดได้ด้วย [E] และซอมบี้พังได้
      - ประตูห้องส้วมย่อยทุกห้อง (ToiletStall) เปิด/ปิดหลบซอมบี้ได้ + ซอมบี้พังได้
      - พื้นกระเบื้องหม่น + แอ่งน้ำเจิ่ง + กระจกแตกร้าว + อ่างล้างมือก็อกโครเมียม + ชักโครก 3D + โถปัสสาวะชาย
      - ไฟนีออนสีเขียวอมฟ้าสั่นติดๆ ดับๆ (ทำงานด้วย Coroutine กลางเพียงตัวเดียวทั้งตึกเพื่อความลื่นไหล)
]]

local PartBuilder = require(script.Parent.PartBuilder)
local InteractiveDoorBuilder = require(script.Parent.InteractiveDoorBuilder)

local RestroomBuilder = {}

-- พาเลตต์สีและวัสดุสำหรับห้องน้ำสไตล์สยองขวัญ
local TILE_FLOOR_DARK   = Color3.fromRGB(68, 74, 72)
local WAINSCOT_COLOR    = Color3.fromRGB(142, 152, 148)
local PUDDLE_COLOR      = Color3.fromRGB(28, 42, 46)
local BLOOD_STAIN_COLOR = Color3.fromRGB(82, 18, 22)
local MARBLE_DARK       = Color3.fromRGB(168, 174, 178)
local PORCELAIN         = Color3.fromRGB(224, 226, 222)
local PORCELAIN_STAIN   = Color3.fromRGB(188, 186, 172)
local CHROME            = Color3.fromRGB(190, 198, 206)
local STALL_WALL_COLOR  = Color3.fromRGB(145, 152, 156)
local MIRROR_GLASS      = Color3.fromRGB(148, 178, 188)
local CRACK_DARK        = Color3.fromRGB(36, 40, 44)
local EERIE_NEON_ON     = Color3.fromRGB(178, 245, 226)
local EERIE_NEON_OFF    = Color3.fromRGB(48, 62, 58)

-- ระบบไฟกระพริบห้องน้ำรวมศูนย์ (1 ลูปสำหรับทั้งอาคาร)
local registeredLights = {}
local flickerStarted = false

local function ensureFlickerLoop()
    if flickerStarted then return end
    flickerStarted = true
    task.spawn(function()
        while true do
            task.wait(0.22)
            local now = os.clock()
            for idx = #registeredLights, 1, -1 do
                local item = registeredLights[idx]
                if not item.light or not item.light.Parent then
                    table.remove(registeredLights, idx)
                elseif now >= item.nextToggle then
                    local roll = math.random()
                    if roll < 0.24 then
                        item.light.Enabled = false
                        item.light.Brightness = 0
                        item.tube.Color = EERIE_NEON_OFF
                        item.tube.Material = Enum.Material.SmoothPlastic
                        item.nextToggle = now + (math.random(8, 28) / 100)
                    elseif roll < 0.48 then
                        item.light.Enabled = true
                        item.light.Brightness = 0.28 + math.random() * 0.25
                        item.tube.Color = EERIE_NEON_ON
                        item.tube.Material = Enum.Material.Neon
                        item.nextToggle = now + (math.random(12, 45) / 100)
                    else
                        item.light.Enabled = true
                        item.light.Brightness = item.baseBrightness
                        item.tube.Color = EERIE_NEON_ON
                        item.tube.Material = Enum.Material.Neon
                        item.nextToggle = now + (math.random(80, 260) / 100)
                    end
                end
            end
        end
    end)
end

local function addFlickeringLight(parent, pos, rotDeg)
    local housing = PartBuilder.makePart(
        parent, "VanityFixtureHousing",
        Vector3.new(4.6, 0.22, 0.55),
        CFrame.new(pos) * CFrame.Angles(0, math.rad(rotDeg or 0), 0),
        CRACK_DARK, Enum.Material.Metal, { CanCollide = false }
    )
    local tube = PartBuilder.makePart(
        parent, "VanityNeonTube",
        Vector3.new(4.2, 0.16, 0.30),
        CFrame.new(pos - Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, math.rad(rotDeg or 0), 0),
        EERIE_NEON_ON, Enum.Material.Neon, { CanCollide = false }
    )
    local light = Instance.new("PointLight")
    light.Name = "HorrorRestroomLight"
    light.Color = Color3.fromRGB(165, 240, 215)
    light.Brightness = 0.85
    light.Range = 22
    light.Shadows = false
    light.Parent = tube

    table.insert(registeredLights, {
        tube = tube,
        light = light,
        baseBrightness = 0.85,
        nextToggle = os.clock() + (math.random(10, 120) / 100),
    })
    ensureFlickerLoop()
    return housing
end

-- สร้างชักโครก 3D + ถังพักน้ำ + ปุ่มกด + ที่ใส่ทิชชู่ (หันหน้าไปทิศ outwardDir จากผนังหลัง)
local function buildToiletUnit(parent, prefix, backWallPos, outwardDir, floorY)
    local model = Instance.new("Model")
    model.Name = prefix .. "_ToiletUnit"
    model.Parent = parent

    local lookCF = CFrame.lookAt(backWallPos, backWallPos + outwardDir)
    local bowlPos = backWallPos + outwardDir * 1.45

    -- ฐานและโถชักโครก
    PartBuilder.makePart(model, "Pedestal", Vector3.new(1.2, 1.0, 1.45),
        CFrame.lookAt(bowlPos + Vector3.new(0, floorY + 0.5, 0), bowlPos + Vector3.new(0, floorY + 0.5, 0) + outwardDir),
        PORCELAIN_STAIN, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(model, "BowlRim", Vector3.new(1.65, 0.35, 1.95),
        CFrame.lookAt(bowlPos + Vector3.new(0, floorY + 1.15, 0), bowlPos + Vector3.new(0, floorY + 1.15, 0) + outwardDir),
        PORCELAIN, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(model, "SeatRing", Vector3.new(1.50, 0.14, 1.75),
        CFrame.lookAt(bowlPos + Vector3.new(0, floorY + 1.38, 0), bowlPos + Vector3.new(0, floorY + 1.38, 0) + outwardDir),
        Color3.fromRGB(205, 206, 198), Enum.Material.SmoothPlastic)
    PartBuilder.makePart(model, "DarkWater", Vector3.new(0.85, 0.08, 1.05),
        CFrame.lookAt(bowlPos + Vector3.new(0, floorY + 1.24, 0), bowlPos + Vector3.new(0, floorY + 1.24, 0) + outwardDir),
        PUDDLE_COLOR, Enum.Material.Glass, { Transparency = 0.2 })

    -- ถังพักน้ำ + ปุ่มกดโครเมียม
    local tankPos = backWallPos + outwardDir * 0.52
    PartBuilder.makePart(model, "Tank", Vector3.new(1.75, 1.65, 0.85),
        CFrame.lookAt(tankPos + Vector3.new(0, floorY + 2.0, 0), tankPos + Vector3.new(0, floorY + 2.0, 0) + outwardDir),
        PORCELAIN, Enum.Material.SmoothPlastic)
    PartBuilder.makePart(model, "FlushBtn", Vector3.new(0.24, 0.14, 0.24),
        CFrame.lookAt(tankPos + Vector3.new(0, floorY + 2.86, 0), tankPos + Vector3.new(0, floorY + 2.86, 0) + outwardDir),
        CHROME, Enum.Material.Metal)

    -- ม้วนกระดาษทิชชู่ข้างผนังกั้นห้องน้ำ
    local tpBase = lookCF * CFrame.new(2.75, floorY + 2.2, -1.6)
    PartBuilder.makePart(model, "TPHolder", Vector3.new(0.18, 0.55, 0.55), tpBase, CHROME, Enum.Material.Metal, { CanCollide = false })
    PartBuilder.makePart(model, "TPRoll", Vector3.new(0.45, 0.50, 0.50), tpBase * CFrame.new(-0.22, 0, 0),
        Color3.fromRGB(235, 232, 224), Enum.Material.Fabric, { CanCollide = false })

    return model
end

-- สร้างเคาน์เตอร์อ่างล้างมือหินอ่อนหม่น + อ่างหลายใบ + ก๊อกน้ำโครเมียม + กระจกร้าวหลอนๆ
local function buildVanityAssembly(parent, axis, alongCenter, wallPosFixed, inwardSign, count, length, floorY)
    local model = Instance.new("Model")
    model.Name = "VanityAssembly"
    model.Parent = parent

    local counterDepth = 2.3
    local counterCenterFixed = wallPosFixed + inwardSign * (counterDepth / 2)
    local sizeCounter = (axis == "X") and Vector3.new(length, 2.9, counterDepth) or Vector3.new(counterDepth, 2.9, length)
    local cfCounter = (axis == "X")
        and CFrame.new(alongCenter, floorY + 1.45, counterCenterFixed)
        or CFrame.new(counterCenterFixed, floorY + 1.45, alongCenter)

    PartBuilder.makePart(model, "CounterBase", sizeCounter, cfCounter, MARBLE_DARK, Enum.Material.Marble)

    -- ขอบท็อปหินอ่อนสีเข้ม
    local lipSize = (axis == "X") and Vector3.new(length + 0.15, 0.22, counterDepth + 0.2) or Vector3.new(counterDepth + 0.2, 0.22, length + 0.15)
    local lipCF = (axis == "X")
        and CFrame.new(alongCenter, floorY + 2.95, counterCenterFixed)
        or CFrame.new(counterCenterFixed, floorY + 2.95, alongCenter)
    PartBuilder.makePart(model, "CounterTopSlab", lipSize, lipCF, Color3.fromRGB(122, 128, 132), Enum.Material.Marble)

    -- กระจกเงา + แถบรอยร้าวทแยง + ขอบกรอบอลูมิเนียม
    local mirrorFixed = wallPosFixed + inwardSign * 0.14
    local mirrorLen = length - 0.8
    local mirrorSize = (axis == "X") and Vector3.new(mirrorLen, 4.4, 0.16) or Vector3.new(0.16, 4.4, mirrorLen)
    local mirrorCF = (axis == "X")
        and CFrame.new(alongCenter, floorY + 5.7, mirrorFixed)
        or CFrame.new(mirrorFixed, floorY + 5.7, alongCenter)
    PartBuilder.makePart(model, "MirrorGlass", mirrorSize, mirrorCF, MIRROR_GLASS, Enum.Material.Glass, { Reflectance = 0.55, Transparency = 0.15 })

    -- รอยแตกร้าวบนกระจก
    for c = 1, 2 do
        local offset = (c == 1) and -mirrorLen * 0.22 or mirrorLen * 0.18
        local angleZ = (c == 1) and math.rad(28) or math.rad(-35)
        local crackCF = (axis == "X")
            and CFrame.new(alongCenter + offset, floorY + 5.9, mirrorFixed + inwardSign * 0.09) * CFrame.Angles(0, 0, angleZ)
            or CFrame.new(mirrorFixed + inwardSign * 0.09, floorY + 5.9, alongCenter + offset) * CFrame.Angles(angleZ, 0, 0)
        local crackSz = (axis == "X") and Vector3.new(2.8, 0.06, 0.04) or Vector3.new(0.04, 0.06, 2.8)
        PartBuilder.makePart(model, "MirrorCrack_" .. c, crackSz, crackCF, CRACK_DARK, Enum.Material.SmoothPlastic, { CanCollide = false })
    end

    -- อ่างล้างมือและก๊อกน้ำแต่ละจุด
    local spacing = (length - 2.0) / math.max(1, count)
    local startAlong = alongCenter - (spacing * (count - 1)) / 2
    for i = 1, count do
        local aPos = startAlong + (i - 1) * spacing
        local basinSize = (axis == "X") and Vector3.new(1.85, 0.18, 1.45) or Vector3.new(1.45, 0.18, 1.85)
        local basinCF = (axis == "X")
            and CFrame.new(aPos, floorY + 3.04, counterCenterFixed + inwardSign * 0.15)
            or CFrame.new(counterCenterFixed + inwardSign * 0.15, floorY + 3.04, aPos)
        PartBuilder.makePart(model, "Basin_" .. i, basinSize, basinCF, PORCELAIN, Enum.Material.SmoothPlastic, { CanCollide = false })

        local faucetFixed = wallPosFixed + inwardSign * 0.45
        local faucetCF = (axis == "X")
            and CFrame.new(aPos, floorY + 3.38, faucetFixed)
            or CFrame.new(faucetFixed, floorY + 3.38, aPos)
        PartBuilder.makePart(model, "Faucet_" .. i, Vector3.new(0.22, 0.65, 0.22), faucetCF, CHROME, Enum.Material.Metal, { CanCollide = false })

        -- ขวดสบู่กึ่งโปร่งแสง (เว้นวางเฉพาะจุดแรก)
        if i == 1 then
            local soapCF = (axis == "X")
                and CFrame.new(aPos + 1.15, floorY + 3.35, faucetFixed + inwardSign * 0.35)
                or CFrame.new(faucetFixed + inwardSign * 0.35, floorY + 3.35, aPos + 1.15)
            PartBuilder.makePart(model, "SoapDispenser", Vector3.new(0.32, 0.55, 0.32), soapCF,
                Color3.fromRGB(68, 145, 138), Enum.Material.SmoothPlastic, { CanCollide = false })
        end
    end

    -- ไฟส่องกระจกหลอนๆ เหนือกระจกเงา
    local rot = (axis == "Z") and 90 or 0
    local lightPos = (axis == "X")
        and Vector3.new(alongCenter, floorY + 8.6, wallPosFixed + inwardSign * 1.1)
        or Vector3.new(wallPosFixed + inwardSign * 1.1, floorY + 8.6, alongCenter)
    addFlickeringLight(model, lightPos, rot)

    return model
end

-- สร้างโถปัสสาวะชายติดผนังพร้อมแผ่นกั้น
local function buildUrinals(parent, axis, alongCenter, wallPosFixed, inwardSign, count, floorY)
    local spacing = 3.2
    local startAlong = alongCenter - (spacing * (count - 1)) / 2
    for i = 1, count do
        local aPos = startAlong + (i - 1) * spacing
        local bodyFixed = wallPosFixed + inwardSign * 0.55
        local sizeU = (axis == "X") and Vector3.new(1.3, 2.2, 0.9) or Vector3.new(0.9, 2.2, 1.3)
        local cfU = (axis == "X") and CFrame.new(aPos, floorY + 3.0, bodyFixed) or CFrame.new(bodyFixed, floorY + 3.0, aPos)
        PartBuilder.makePart(parent, "Urinal_" .. i, sizeU, cfU, PORCELAIN, Enum.Material.SmoothPlastic)

        local pipeCF = (axis == "X")
            and CFrame.new(aPos, floorY + 4.4, wallPosFixed + inwardSign * 0.32)
            or CFrame.new(wallPosFixed + inwardSign * 0.32, floorY + 4.4, aPos)
        PartBuilder.makePart(parent, "UrinalPipe_" .. i, Vector3.new(0.18, 0.85, 0.18), pipeCF, CHROME, Enum.Material.Metal, { CanCollide = false })
    end
end

-- ตกแต่งแอ่งน้ำเจิ่ง & คราบเลือดจางๆ + พื้นกระเบื้องสีหม่นบนพื้นห้องน้ำ
local function buildHorrorFloorDetails(parent, minX, maxX, minZ, maxZ, floorY)
    local w = math.max(4, maxX - minX)
    local d = math.max(4, maxZ - minZ)
    local cx = (minX + maxX) / 2
    local cz = (minZ + maxZ) / 2

    PartBuilder.makePart(
        parent, "DirtyTileFloor",
        Vector3.new(w, 0.04, d),
        CFrame.new(cx, floorY + 0.02, cz),
        TILE_FLOOR_DARK, Enum.Material.Slate, { CanCollide = false }
    )

    -- แอ่งน้ำเจิ่งบนพื้น 2 จุด
    PartBuilder.makePart(
        parent, "WetPuddle_A",
        Vector3.new(w * 0.32, 0.03, d * 0.25),
        CFrame.new(cx - w * 0.12, floorY + 0.045, cz + d * 0.08) * CFrame.Angles(0, math.rad(14), 0),
        PUDDLE_COLOR, Enum.Material.Glass, { Transparency = 0.28, Reflectance = 0.65, CanCollide = false }
    )
    PartBuilder.makePart(
        parent, "BloodTrackStain",
        Vector3.new(1.8, 0.025, 3.2),
        CFrame.new(cx + w * 0.08, floorY + 0.048, cz - d * 0.10) * CFrame.Angles(0, math.rad(-22), 0),
        BLOOD_STAIN_COLOR, Enum.Material.Slate, { Transparency = 0.22, CanCollide = false }
    )
end

-- สร้างคอกห้องส้วม + ประตูห้องส้วมย่อยที่เปิด-ปิดและซอมบี้พังได้
-- directionIntoStall = Vector3 หน่วยชี้จากหน้าประตูคอกเข้าไปหาผนังหลังที่มีชักโครก
local function buildStallRow(parent, opts)
    local axis = opts.axis                 -- แนวประตู ("X" หรือ "Z")
    local frontFixed = opts.frontFixed     -- พิกัดหน้าประตูกั้น
    local backWallFixed = opts.backFixed   -- พิกัดผนังด้านหลังชักโครก
    local intoSign = opts.intoSign         -- +1/-1 ชี้เข้าในห้องส้วมจากหน้าประตู
    local floorY = opts.floorY
    local stallH = 8.8
    local openW = 3.4
    local centers = opts.centers
    local spanStart = opts.spanStart
    local spanEnd = opts.spanEnd
    local doorPrefix = opts.doorPrefix or "Stall"

    local depth = math.abs(backWallFixed - frontFixed)
    local midDepthFixed = (frontFixed + backWallFixed) / 2
    local stallCount = #centers
    local backOutDir = (axis == "X") and Vector3.new(0, 0, -intoSign) or Vector3.new(-intoSign, 0, 0)

    -- ผนังแบ่งระหว่างห้องส้วม (ขอบซ้ายสุด - ช่องระหว่างห้อง - ขวาสุด)
    local pitch = (spanEnd - spanStart) / stallCount
    for i = 0, stallCount do
        local divAlong = spanStart + i * pitch
        local divSize = (axis == "X") and Vector3.new(0.28, stallH, depth) or Vector3.new(depth, stallH, 0.28)
        local divCF = (axis == "X")
            and CFrame.new(divAlong, floorY + stallH / 2 + 0.4, midDepthFixed)
            or CFrame.new(midDepthFixed, floorY + stallH / 2 + 0.4, divAlong)
        PartBuilder.makePart(parent, "StallDivider_" .. i, divSize, divCF, STALL_WALL_COLOR, Enum.Material.SmoothPlastic)
    end

    -- แต่ละห้องย่อย: แผงหน้าข้างซ้าย-ขวา + ประตูบานเปิด-ปิดได้ + ชักโครก 3D ด้านใน
    for i, cAlong in ipairs(centers) do
        local cellLeft = spanStart + (i - 1) * pitch
        local cellRight = cellLeft + pitch
        local doorLeft = cAlong - openW / 2
        local doorRight = cAlong + openW / 2

        local pilL = doorLeft - cellLeft
        if pilL > 0.15 then
            local sz = (axis == "X") and Vector3.new(pilL, stallH, 0.28) or Vector3.new(0.28, stallH, pilL)
            local cf = (axis == "X")
                and CFrame.new((cellLeft + doorLeft) / 2, floorY + stallH / 2 + 0.4, frontFixed)
                or CFrame.new(frontFixed, floorY + stallH / 2 + 0.4, (cellLeft + doorLeft) / 2)
            PartBuilder.makePart(parent, "StallPilasterL_" .. i, sz, cf, STALL_WALL_COLOR, Enum.Material.SmoothPlastic)
        end

        local pilR = cellRight - doorRight
        if pilR > 0.15 then
            local sz = (axis == "X") and Vector3.new(pilR, stallH, 0.28) or Vector3.new(0.28, stallH, pilR)
            local cf = (axis == "X")
                and CFrame.new((doorRight + cellRight) / 2, floorY + stallH / 2 + 0.4, frontFixed)
                or CFrame.new(frontFixed, floorY + stallH / 2 + 0.4, (doorRight + cellRight) / 2)
            PartBuilder.makePart(parent, "StallPilasterR_" .. i, sz, cf, STALL_WALL_COLOR, Enum.Material.SmoothPlastic)
        end

        -- ประตูห้องส้วมย่อย (เปิดเข้าในห้องส้วม ยกลอยจากพื้น 0.7 studs เหมือนห้องน้ำจริง!)
        InteractiveDoorBuilder.buildSingleDoor(parent, doorPrefix .. "_" .. i, {
            axis = axis,
            doorCenterAlong = cAlong,
            fixedPos = frontFixed,
            inDirSign = intoSign,
            hingeSide = -1,
            floorY = floorY,
            openW = openW,
            openH = 8.3,
            elevation = 0.7,
            leafH = 7.4,
            maxHP = 48,
            style = "ToiletStall",
            doorLabel = "ประตูห้องส้วม #" .. i,
            initialOpen = false,
        })

        -- ชักโครกด้านในติดผนังหลัง
        local backPos = (axis == "X")
            and Vector3.new(cAlong, 0, backWallFixed)
            or Vector3.new(backWallFixed, 0, cAlong)
        buildToiletUnit(parent, "Toilet_" .. i, backPos, backOutDir, floorY)
    end
end

--------------------------------------------------------------------------------
-- 1. ห้องน้ำ 4 มุมขนาด 34 x 34 studs (ชั้น 2, 4-6, 7, 8-11)
--------------------------------------------------------------------------------
function RestroomBuilder.buildCornerQuad(parent, opts)
    local restrooms = Instance.new("Model")
    restrooms.Name = opts.folderName or ("Restrooms_4Corners_F" .. tostring(opts.floorNum or ""))
    restrooms.Parent = parent

    local floorY = opts.floorY
    local wallH = opts.wallH
    local wallThick = opts.wallThick
    local wallColor = opts.wallColor
    local wallMat = opts.wallMaterial
    local rrW = 34
    local rrL = 34

    local blocks = opts.cornerBlocks or {
        { name = "Restroom_TopLeft",  sx = -1, sz = -1 },
        { name = "Restroom_TopRight", sx =  1, sz = -1 },
        { name = "Restroom_BotLeft",  sx = -1, sz =  1 },
        { name = "Restroom_BotRight", sx =  1, sz =  1 },
    }

    local doorOpenW = 6.8
    local doorOpenH = 10.6

    for _, cb in ipairs(blocks) do
        local rModel = Instance.new("Model")
        rModel.Name = cb.name
        rModel.Parent = restrooms

        local sx, sz = cb.sx, cb.sz
        local cx = sx * (150 - rrW / 2) -- ±133
        local cz = sz * (120 - rrL / 2) -- ±103
        local innerX = sx * (150 - rrW) -- ±116
        local innerZ = sz * (120 - rrL) -- ±86
        local signFace = (sx < 0) and Enum.NormalId.Right or Enum.NormalId.Left

        -- โครงผนังรอบห้องน้ำ + ผนังแบ่งชาย/หญิงตรงกลาง (cz)
        PartBuilder.makePart(rModel, "Wall_Outer_X", Vector3.new(wallThick, wallH, rrL),
            CFrame.new(sx * (150 - wallThick / 2), floorY + wallH / 2, cz), wallColor, wallMat)
        PartBuilder.makePart(rModel, "Wall_Outer_Z", Vector3.new(rrW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, sz * (120 - wallThick / 2)), wallColor, wallMat)
        PartBuilder.makePart(rModel, "Wall_Inner_Z", Vector3.new(rrW, wallH, wallThick),
            CFrame.new(cx, floorY + wallH / 2, innerZ + sz * (wallThick / 2)), wallColor, wallMat)
        PartBuilder.makePart(rModel, "Wall_CenterDivider_MF", Vector3.new(rrW, wallH, 1.2),
            CFrame.new(cx, floorY + wallH / 2, cz), wallColor, wallMat)

        local halves = {
            { sub = "Male",   midZ = sz * 111.5, zMin = math.min(cz + sz * 0.7, sz * 118), zMax = math.max(cz + sz * 0.7, sz * 118),
              label = "ห้องน้ำชาย\nMALE WC",   color = Color3.fromRGB(20, 90, 165) },
            { sub = "Female", midZ = sz *  94.5, zMin = math.min(sz * 88, cz - sz * 0.7), zMax = math.max(sz * 88, cz - sz * 0.7),
              label = "ห้องน้ำหญิง\nFEMALE WC", color = Color3.fromRGB(185, 45, 95) },
        }

        for _, h in ipairs(halves) do
            local subM = Instance.new("Model")
            subM.Name = h.sub
            subM.Parent = rModel

            -- ผนังหน้าห้องน้ำ (17 studs) เว้นช่องประตูทางเข้ากว้าง 6.8 studs (ข้างละ 5.1 studs)
            local sideSeg = (17 - doorOpenW) / 2
            local frontX = innerX + sx * (wallThick / 2)
            PartBuilder.makePart(subM, "FrontWall_A", Vector3.new(wallThick, wallH, sideSeg),
                CFrame.new(frontX, floorY + wallH / 2, h.midZ - (doorOpenW / 2 + sideSeg / 2)), wallColor, wallMat)
            PartBuilder.makePart(subM, "FrontWall_B", Vector3.new(wallThick, wallH, sideSeg),
                CFrame.new(frontX, floorY + wallH / 2, h.midZ + (doorOpenW / 2 + sideSeg / 2)), wallColor, wallMat)
            PartBuilder.makePart(subM, "FrontHeader", Vector3.new(wallThick, wallH - doorOpenH, doorOpenW),
                CFrame.new(frontX, floorY + doorOpenH + (wallH - doorOpenH) / 2, h.midZ), wallColor, wallMat)

            PartBuilder.makeSign(subM, "Sign", h.label, Vector3.new(0.15, 2.8, 12.0),
                Vector3.new(innerX - sx * 0.1, floorY + wallH - 3.2, h.midZ), signFace, h.color, Color3.fromRGB(255, 255, 255))

            -- ประตูทางเข้าห้องน้ำหลักแบบเปิด-ปิด และซอมบี้พังได้
            InteractiveDoorBuilder.buildSingleDoor(subM, cb.name .. "_" .. h.sub .. "_Main", {
                axis = "Z",
                doorCenterAlong = h.midZ,
                fixedPos = frontX,
                inDirSign = sx,
                hingeSide = -1,
                floorY = floorY,
                openW = doorOpenW,
                openH = doorOpenH,
                maxHP = 90,
                style = "RestroomMain",
                doorLabel = (h.sub == "Male") and "ประตูห้องน้ำชาย" or "ประตูห้องน้ำหญิง",
                initialOpen = false,
            })

            -- พื้นกระเบื้องหม่น + แอ่งน้ำเจิ่ง
            local x1 = math.min(sx * 118.2, sx * 147.8)
            local x2 = math.max(sx * 118.2, sx * 147.8)
            buildHorrorFloorDetails(subM, x1, x2, h.zMin, h.zMax, floorY)

            -- เคาน์เตอร์อ่างล้างมือ 2 อ่างชิดฝั่งผนังด้านหนึ่ง และโถปัสสาวะชาย/ถังขยะอีกฝั่ง (หลบแนวบานประตูเปิด)
            local wallVanityZ = h.midZ - sz * 6.5
            local vanityInward = sz
            buildVanityAssembly(subM, "X", sx * 130.5, wallVanityZ, vanityInward, 2, 10.0, floorY)

            local oppWallZ = h.midZ + sz * 6.5
            if h.sub == "Male" then
                buildUrinals(subM, "X", sx * 130.5, oppWallZ, -sz, 2, floorY)
            else
                -- ถังขยะสแตนเลสมุมห้อง
                PartBuilder.makePart(subM, "TrashBin", Vector3.new(1.5, 2.2, 1.5),
                    CFrame.new(sx * 126, floorY + 1.1, oppWallZ - sz * 1.1), CRACK_DARK, Enum.Material.Metal)
            end

            -- คอกห้องส้วมย่อย 2 ห้องติดผนังด้านในสุด (X = ±139.5..±148) พร้อมประตูห้องส้วมทุกห้อง
            local stallFrontX = sx * 139.5
            local stallBackX = sx * 147.6
            local spanMinZ = h.midZ - 6.6
            local spanMaxZ = h.midZ + 6.6
            buildStallRow(subM, {
                axis = "Z",
                frontFixed = stallFrontX,
                backFixed = stallBackX,
                intoSign = sx,
                floorY = floorY,
                spanStart = spanMinZ,
                spanEnd = spanMaxZ,
                centers = { h.midZ - 3.3, h.midZ + 3.3 },
                doorPrefix = cb.name .. "_" .. h.sub .. "_Stall",
            })
        end
    end

    return restrooms
end

--------------------------------------------------------------------------------
-- 2. ห้องน้ำแถบเหนือชั้น 3 (West WC.2: -124..-68 & East WC.3: 68..124, Z = -120..-86)
--------------------------------------------------------------------------------
function RestroomBuilder.buildNorthBandPair(parent, opts)
    local restroomsF3 = Instance.new("Folder")
    restroomsF3.Name = opts.folderName or "Restrooms_NorthBand"
    restroomsF3.Parent = parent

    local floorY = opts.floorY
    local wallH = opts.wallH
    local wallThick = opts.wallThick
    local wallColor = opts.wallColor
    local wallMat = opts.wallMaterial

    local zOuter = -120
    local zInner = -86
    local zMid = (zOuter + zInner) / 2 -- -103
    local depth = zInner - zOuter      -- 34
    local doorOpenW = 6.8
    local doorOpenH = 10.6

    local function buildBlock(tag, minX, maxX)
        local block = Instance.new("Model")
        block.Name = "Restroom_" .. tag
        block.Parent = restroomsF3

        local midX = (minX + maxX) / 2
        local halfW = (maxX - minX) / 2

        local subRooms = {
            { sub = "Male",   label = "ห้องน้ำชาย\nMEN WC",   color = Color3.fromRGB(25, 95, 185),  x1 = minX, x2 = midX },
            { sub = "Female", label = "ห้องน้ำหญิง\nWOMEN WC", color = Color3.fromRGB(205, 65, 115), x1 = midX, x2 = maxX },
        }

        for _, sr in ipairs(subRooms) do
            local rM = Instance.new("Model")
            rM.Name = sr.sub
            rM.Parent = block
            local cx = (sr.x1 + sr.x2) / 2

            PartBuilder.makePart(rM, "Wall_Back", Vector3.new(halfW, wallH, wallThick),
                CFrame.new(cx, floorY + wallH / 2, zOuter + wallThick / 2), wallColor, wallMat)
            PartBuilder.makePart(rM, "Wall_Left", Vector3.new(wallThick, wallH, depth),
                CFrame.new(sr.x1 + wallThick / 2, floorY + wallH / 2, zMid), wallColor, wallMat)
            PartBuilder.makePart(rM, "Wall_Right", Vector3.new(wallThick, wallH, depth),
                CFrame.new(sr.x2 - wallThick / 2, floorY + wallH / 2, zMid), wallColor, wallMat)

            local sideSegW = (halfW - doorOpenW) / 2
            local frontZ = zInner - wallThick / 2
            PartBuilder.makePart(rM, "Front_L", Vector3.new(sideSegW, wallH, wallThick),
                CFrame.new(sr.x1 + sideSegW / 2, floorY + wallH / 2, frontZ), wallColor, wallMat)
            PartBuilder.makePart(rM, "Front_R", Vector3.new(sideSegW, wallH, wallThick),
                CFrame.new(sr.x2 - sideSegW / 2, floorY + wallH / 2, frontZ), wallColor, wallMat)
            PartBuilder.makePart(rM, "Front_Header", Vector3.new(doorOpenW, wallH - doorOpenH, wallThick),
                CFrame.new(cx, floorY + doorOpenH + (wallH - doorOpenH) / 2, frontZ), wallColor, wallMat)

            PartBuilder.makeSign(rM, "Sign", sr.label, Vector3.new(18, 3.2, 0.15),
                Vector3.new(cx, floorY + 13.4, zInner + 0.1), Enum.NormalId.Back, sr.color, Color3.fromRGB(255, 255, 255))

            InteractiveDoorBuilder.buildSingleDoor(rM, tag .. "_" .. sr.sub .. "_Main", {
                axis = "X",
                doorCenterAlong = cx,
                fixedPos = frontZ,
                inDirSign = -1,
                hingeSide = -1,
                floorY = floorY,
                openW = doorOpenW,
                openH = doorOpenH,
                maxHP = 90,
                style = "RestroomMain",
                doorLabel = (sr.sub == "Male") and "ประตูห้องน้ำชาย" or "ประตูห้องน้ำหญิง",
                initialOpen = false,
            })

            buildHorrorFloorDetails(rM, sr.x1 + 2.1, sr.x2 - 2.1, zOuter + 2.1, zInner - 2.1, floorY)

            -- เคาน์เตอร์อ่างล้างมือ 3 อ่างฝั่งซ้าย & โถปัสสาวะ/ถังขยะฝั่งขวา
            buildVanityAssembly(rM, "Z", zMid + 4.0, sr.x1 + 2.0, 1, 3, 13.0, floorY)
            if sr.sub == "Male" then
                buildUrinals(rM, "Z", zMid + 4.0, sr.x2 - 2.0, -1, 3, floorY)
            else
                PartBuilder.makePart(rM, "TrashBin", Vector3.new(1.5, 2.2, 1.5),
                    CFrame.new(sr.x2 - 3.0, floorY + 1.1, zMid + 5.0), CRACK_DARK, Enum.Material.Metal)
            end

            -- คอกห้องส้วมย่อย 3 ห้องด้านผนังหลัง (Z = -109.5..-118)
            buildStallRow(rM, {
                axis = "X",
                frontFixed = -109.5,
                backFixed = zOuter + 2.2,
                intoSign = -1,
                floorY = floorY,
                spanStart = cx - 9.9,
                spanEnd = cx + 9.9,
                centers = { cx - 6.6, cx, cx + 6.6 },
                doorPrefix = tag .. "_" .. sr.sub .. "_Stall",
            })
        end
    end

    buildBlock("West_WC2", -124, -68)
    buildBlock("East_WC3",   68, 124)

    return restroomsF3
end

--------------------------------------------------------------------------------
-- 3. ห้องน้ำเดี่ยวชั้น 12 (WC.1 South & WC.2 North: X = -98..-68, Z = ±86..±120)
--------------------------------------------------------------------------------
function RestroomBuilder.buildSingleBandWC(parent, cfg)
    local wm = Instance.new("Model")
    wm.Name = cfg.name
    wm.Parent = parent

    local cx, sz = cfg.cx, cfg.sz
    local floorY = cfg.floorY
    local wallH = cfg.wallH
    local wallThick = cfg.wallThick
    local wallColor = cfg.wallColor
    local wallMat = cfg.wallMaterial

    local roomW = 30
    local roomD = 34
    local cz = sz * 103
    local innerZ = sz * 86
    local outerZ = sz * (120 - wallThick / 2)
    local frontZ = innerZ + sz * (wallThick / 2)
    local doorOpenW = 6.8
    local doorOpenH = 10.6

    PartBuilder.makePart(wm, "Wall_OuterZ", Vector3.new(roomW, wallH, wallThick),
        CFrame.new(cx, floorY + wallH / 2, outerZ), wallColor, wallMat)
    PartBuilder.makePart(wm, "Wall_LeftX", Vector3.new(wallThick, wallH, roomD),
        CFrame.new(cx - roomW / 2 + wallThick / 2, floorY + wallH / 2, cz), wallColor, wallMat)
    PartBuilder.makePart(wm, "Wall_RightX", Vector3.new(wallThick, wallH, roomD),
        CFrame.new(cx + roomW / 2 - wallThick / 2, floorY + wallH / 2, cz), wallColor, wallMat)

    local sideW = (roomW - doorOpenW) / 2
    PartBuilder.makePart(wm, "FrontWall_L", Vector3.new(sideW, wallH, wallThick),
        CFrame.new(cx - (doorOpenW / 2 + sideW / 2), floorY + wallH / 2, frontZ), wallColor, wallMat)
    PartBuilder.makePart(wm, "FrontWall_R", Vector3.new(sideW, wallH, wallThick),
        CFrame.new(cx + (doorOpenW / 2 + sideW / 2), floorY + wallH / 2, frontZ), wallColor, wallMat)
    PartBuilder.makePart(wm, "FrontHeader", Vector3.new(doorOpenW, wallH - doorOpenH, wallThick),
        CFrame.new(cx, floorY + doorOpenH + (wallH - doorOpenH) / 2, frontZ), wallColor, wallMat)

    PartBuilder.makeSign(wm, "WCSign", cfg.code, Vector3.new(16, 2.8, 0.15),
        Vector3.new(cx, floorY + wallH - 3.2, innerZ - sz * 0.1),
        sz > 0 and Enum.NormalId.Front or Enum.NormalId.Back,
        Color3.fromRGB(20, 90, 165), Color3.fromRGB(255, 255, 255))

    InteractiveDoorBuilder.buildSingleDoor(wm, cfg.name .. "_Main", {
        axis = "X",
        doorCenterAlong = cx,
        fixedPos = frontZ,
        inDirSign = sz,
        hingeSide = -1,
        floorY = floorY,
        openW = doorOpenW,
        openH = doorOpenH,
        maxHP = 90,
        style = "RestroomMain",
        doorLabel = "ประตู " .. (cfg.name or "ห้องน้ำ"),
        initialOpen = false,
    })

    local minZ = math.min(sz * 88.2, sz * 117.8)
    local maxZ = math.max(sz * 88.2, sz * 117.8)
    buildHorrorFloorDetails(wm, cx - 12.8, cx + 12.8, minZ, maxZ, floorY)

    -- อ่างล้างมือ 3 อ่างฝั่งซ้าย + ห้องส้วมย่อย 3 ห้องฝั่งขวา
    buildVanityAssembly(wm, "Z", cz, cx - 12.8, 1, 3, 14.0, floorY)
    buildStallRow(wm, {
        axis = "Z",
        frontFixed = cx + 5.2,
        backFixed = cx + 12.8,
        intoSign = 1,
        floorY = floorY,
        spanStart = cz - 10.5,
        spanEnd = cz + 10.5,
        centers = { cz - 7.0, cz, cz + 7.0 },
        doorPrefix = cfg.name .. "_Stall",
    })

    return wm
end

return RestroomBuilder
