--[[
    InteractiveDoorBuilder.lua
    โมดูลกลางสำหรับสร้าง "ประตูเปิด-ปิดได้ และซอมบี้พังได้" ใช้ร่วมกันทั้ง:
      1. ประตูกระจกคู่ห้องสำนักงาน (ชั้น 4-6)
      2. ประตูทางเข้าห้องน้ำหลัก (ชั้น 2-12)
      3. ประตูห้องส้วมย่อยแต่ละห้อง (ชั้น 2-12)
    รองรับระบบ:
      - กด [E] เปิด/ปิดประตูได้ตลอดเวลา (ProximityPrompt)
      - แท็ก CollectionService "BreakableDoor" + Attribute (IsOpen, IsBroken, DoorHP, MaxDoorHP, DoorCenter, FloorY)
      - BindableFunction "DamageDoor" ให้ซอมบี้โจมตี/กระแทกประตูจนพัง และผู้เล่นกดค้าง [E] ซ่อมประตูกลับมาปิดป้องกันได้
]]

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local PartBuilder = require(script.Parent.PartBuilder)

local InteractiveDoorBuilder = {}

local FRAME_DARK     = Color3.fromRGB(44, 48, 56)
local ALUMINUM_TRIM  = Color3.fromRGB(165, 172, 180)
local GLASS_TINT     = Color3.fromRGB(172, 214, 232)
local FROST_STRIPE   = Color3.fromRGB(238, 244, 248)

-- แปลงค่า (axis, sideSign, inDirSign, thetaRad) เป็นมุมหมุน CFrame.Angles(0, yaw, 0) รอบบานพับ
local function computeHingeYaw(axis, sideSign, inDirSign, thetaRad)
    if axis == "X" then
        return sideSign * inDirSign * thetaRad
    else
        return -sideSign * inDirSign * thetaRad
    end
end

-- สร้างตำแหน่ง Pivot สำหรับบานประตูบนแกน X หรือ Z
local function makeDoorCF(axis, along, y, fixedPos)
    if axis == "X" then
        return CFrame.new(along, y, fixedPos)
    else
        return CFrame.new(fixedPos, y, along)
    end
end

local function makeDoorSize(axis, alongLen, height, thick)
    if axis == "X" then
        return Vector3.new(alongLen, height, thick)
    else
        return Vector3.new(thick, height, alongLen)
    end
end

-- เก็บรายการชิ้นส่วนของบานประตูเทียบกับจุดบานพับ (hingeCF) เพื่อให้หมุนทุกชิ้นส่วนพร้อมกันแบบ Anchored ไม่มีบักฟิสิกส์
local function captureLeafParts(hingeCF, parts)
    local entries = {}
    for _, p in ipairs(parts) do
        table.insert(entries, {
            part = p,
            relCF = hingeCF:ToObjectSpace(p.CFrame),
            origColor = p.Color,
            origTransparency = p.Transparency,
            origCanCollide = p.CanCollide,
        })
    end
    return entries
end

-- เสกเศษไม้/เศษกระจกกระเด็นเมื่อซอมบี้ตีหรือพังประตู
local function spawnDamageDebris(doorModel, worldPos, isGlass, count)
    for i = 1, count do
        local shard = Instance.new("Part")
        shard.Name = isGlass and "GlassShard" or "WoodSplinter"
        shard.Size = isGlass and Vector3.new(0.45, 0.08, 0.55) or Vector3.new(0.7, 0.14, 0.25)
        shard.Color = isGlass and Color3.fromRGB(185, 225, 240) or Color3.fromRGB(92, 68, 48)
        shard.Material = isGlass and Enum.Material.Glass or Enum.Material.WoodPlanks
        shard.Transparency = isGlass and 0.45 or 0
        shard.CanCollide = false
        shard.Anchored = false
        shard.CFrame = CFrame.new(worldPos + Vector3.new(math.random(-15, 15) / 10, math.random(10, 50) / 10, math.random(-15, 15) / 10))
            * CFrame.Angles(math.random(), math.random(), math.random())
        shard.AssemblyLinearVelocity = Vector3.new(math.random(-14, 14), math.random(4, 14), math.random(-14, 14))
        shard.Parent = doorModel
        Debris:AddItem(shard, 3.5)
    end
end

-- ผูกระบบโต้ตอบ [E] + แอนิเมชันเปิดปิด + ระบบ DamageDoor จากซอมบี้ + การซ่อมประตู
local function attachInteractiveBehavior(doorModel, hinges, opts)
    local maxHP = opts.maxHP or 100
    local openDeg = opts.openDeg or 80
    local isOpen = (opts.initialOpen == true)
    local isBroken = false
    local hp = maxHP
    local isGlassDoor = (opts.isGlass == true)
    local doorLabel = opts.doorLabel or "ประตู"
    local maxDist = opts.promptDist or 9.5

    local currentAngle = isOpen and openDeg or 0
    local targetAngle = currentAngle
    local animToken = 0

    local doorCenter = opts.doorCenter
    doorModel:SetAttribute("IsOpen", isOpen)
    doorModel:SetAttribute("IsBroken", false)
    doorModel:SetAttribute("DoorHP", hp)
    doorModel:SetAttribute("MaxDoorHP", maxHP)
    doorModel:SetAttribute("DoorType", opts.doorType or "SingleDoor")
    doorModel:SetAttribute("DoorCenter", doorCenter)
    doorModel:SetAttribute("FloorY", opts.floorY or 0)
    CollectionService:AddTag(doorModel, "BreakableDoor")

    local anchor = PartBuilder.makePart(
        doorModel, "DoorPromptAnchor",
        Vector3.new(0.8, 0.8, 0.8),
        CFrame.new(doorCenter),
        Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic,
        { Transparency = 1, CanCollide = false }
    )

    local hitSound = Instance.new("Sound")
    hitSound.Name = "DoorAudio"
    hitSound.SoundId = "rbxassetid://9114223170"
    hitSound.Volume = 0.75
    hitSound.RollOffMaxDistance = 65
    hitSound.Parent = anchor

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "DoorPrompt"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = maxDist
    prompt.Parent = anchor

    local function applyHingeAngle(deg, jitterVec)
        local rad = math.rad(deg)
        local jCF = jitterVec and CFrame.new(jitterVec) or CFrame.identity
        for _, h in ipairs(hinges) do
            local yaw = computeHingeYaw(opts.axis, h.sideSign, opts.inDirSign, rad)
            local rotatedHinge = h.hingeCF * CFrame.Angles(0, yaw, 0) * jCF
            for _, entry in ipairs(h.entries) do
                if entry.part and entry.part.Parent then
                    entry.part.CFrame = rotatedHinge * entry.relCF
                end
            end
        end
    end

    local function updatePromptText()
        if isBroken then
            prompt.ActionText = "ซ่อมประตู"
            prompt.ObjectText = doorLabel .. " (พังแล้ว!)"
            prompt.HoldDuration = 1.0
        else
            prompt.HoldDuration = 0
            local hpStr = string.format("%d/%d", math.ceil(hp), maxHP)
            if isOpen then
                prompt.ActionText = opts.closeActionText or "ปิดประตู"
            else
                prompt.ActionText = opts.openActionText or "เปิดประตู"
            end
            prompt.ObjectText = doorLabel .. " [" .. hpStr .. "]"
        end
    end

    local function animateToAngle(goalDeg)
        targetAngle = goalDeg
        animToken += 1
        local myToken = animToken
        task.spawn(function()
            local speedDegPerSec = 340
            while myToken == animToken and not isBroken do
                local dt = RunService.Heartbeat:Wait()
                local diff = targetAngle - currentAngle
                if math.abs(diff) <= 0.8 then
                    currentAngle = targetAngle
                    applyHingeAngle(currentAngle)
                    break
                end
                local step = math.clamp(diff, -speedDegPerSec * dt, speedDegPerSec * dt)
                currentAngle += step
                applyHingeAngle(currentAngle)
            end
        end)
    end

    -- ตั้งค่ามุมเริ่มต้นทันที
    applyHingeAngle(currentAngle)
    updatePromptText()

    -- ชิ้นส่วนซากประตูที่โชว์เฉพาะตอนถูกพัง
    local brokenDebris = opts.brokenVisualParts or {}
    for _, bp in ipairs(brokenDebris) do
        bp.Transparency = 1
        bp.CanCollide = false
    end

    local function setBrokenVisualState(broken)
        for _, h in ipairs(hinges) do
            for _, entry in ipairs(h.entries) do
                if entry.part and entry.part.Parent then
                    if broken then
                        entry.part.Transparency = 1
                        entry.part.CanCollide = false
                    else
                        entry.part.Transparency = entry.origTransparency
                        entry.part.CanCollide = entry.origCanCollide
                        entry.part.Color = entry.origColor
                    end
                end
            end
        end
        for _, bp in ipairs(brokenDebris) do
            if bp and bp.Parent then
                bp.Transparency = broken and (isGlassDoor and 0.45 or 0) or 1
                bp.CanCollide = false
            end
        end
    end

    local function playSoundSafe(pitch, vol)
        pcall(function()
            hitSound.PlaybackSpeed = pitch
            hitSound.Volume = vol
            hitSound:Play()
        end)
    end

    -- ผู้เล่นกด [E]
    prompt.Triggered:Connect(function()
        if isBroken then
            -- ซ่อมและปิดประตูล็อกป้องกัน
            isBroken = false
            hp = maxHP
            isOpen = false
            currentAngle = 0
            targetAngle = 0
            setBrokenVisualState(false)
            applyHingeAngle(0)
            doorModel:SetAttribute("IsBroken", false)
            doorModel:SetAttribute("IsOpen", false)
            doorModel:SetAttribute("DoorHP", hp)
            playSoundSafe(1.25, 0.55)
            updatePromptText()
            return
        end

        isOpen = not isOpen
        doorModel:SetAttribute("IsOpen", isOpen)
        playSoundSafe(isOpen and 1.15 or 0.85, 0.42)
        animateToAngle(isOpen and openDeg or 0)
        updatePromptText()
    end)

    -- API สำหรับซอมบี้โจมตี/พังประตู
    local dmgFn = Instance.new("BindableFunction")
    dmgFn.Name = "DamageDoor"
    dmgFn.OnInvoke = function(amount, attackerPos)
        if isBroken or isOpen then
            return false
        end
        local dmg = tonumber(amount) or 20
        hp = math.max(0, hp - dmg)
        doorModel:SetAttribute("DoorHP", hp)

        if hp <= 0 then
            isBroken = true
            isOpen = true
            doorModel:SetAttribute("IsBroken", true)
            doorModel:SetAttribute("IsOpen", true)
            setBrokenVisualState(true)
            spawnDamageDebris(doorModel, doorCenter, isGlassDoor, 7)
            playSoundSafe(0.58, 1.0)
            updatePromptText()
            return true
        end

        -- แรงสั่นสะเทือน + สีแดงวาบเมื่อโดนตี
        playSoundSafe(0.88 + math.random() * 0.25, 0.72)
        spawnDamageDebris(doorModel, doorCenter, isGlassDoor, 2)
        updatePromptText()

        task.spawn(function()
            if not isBroken and not isOpen then
                applyHingeAngle(currentAngle, Vector3.new(
                    (math.random() - 0.5) * 0.24,
                    0,
                    (math.random() - 0.5) * 0.24
                ))
                for _, h in ipairs(hinges) do
                    for _, entry in ipairs(h.entries) do
                        if entry.part and entry.part.Parent and not isGlassDoor then
                            entry.part.Color = Color3.fromRGB(190, 82, 72)
                        end
                    end
                end
                task.wait(0.11)
                if not isBroken then
                    applyHingeAngle(currentAngle)
                    for _, h in ipairs(hinges) do
                        for _, entry in ipairs(h.entries) do
                            if entry.part and entry.part.Parent then
                                entry.part.Color = entry.origColor
                            end
                        end
                    end
                end
            end
        end)

        return false
    end
    dmgFn.Parent = doorModel

    return doorModel
end

--------------------------------------------------------------------------------
-- 1. ประตูกระจกคู่แบบเปิด-ปิดและซอมบี้พังได้ (สำหรับสำนักงานชั้น 4-6)
--------------------------------------------------------------------------------
function InteractiveDoorBuilder.buildDoubleGlassDoor(parent, prefix, opts)
    local axis = opts.axis
    local doorCenterAlong = opts.doorCenterAlong
    local fixedPos = opts.fixedPos
    local inDirSign = opts.inDirSign
    local floorY = opts.floorY

    local openW = opts.openW or 8.0
    local openH = opts.openH or 11.2
    local leafW = opts.leafW or 3.85
    local leafH = opts.leafH or 10.8
    local glassTopH = opts.glassTopH or 16.5

    local model = Instance.new("Model")
    model.Name = prefix .. "_InteractiveDoor"
    model.Parent = parent

    -- เฟรมด้านบน & Transom เหนือประตู
    local transH = glassTopH - openH
    if transH > 0.2 then
        PartBuilder.makePart(
            model, "TransomGlass",
            makeDoorSize(axis, openW, transH, 0.24),
            makeDoorCF(axis, doorCenterAlong, floorY + openH + transH / 2, fixedPos),
            GLASS_TINT, Enum.Material.Glass, { Transparency = 0.62 }
        )
    end
    PartBuilder.makePart(
        model, "DoorHeaderBar",
        makeDoorSize(axis, openW + 0.4, 0.34, 0.56),
        makeDoorCF(axis, doorCenterAlong, floorY + openH - 0.17, fixedPos),
        FRAME_DARK, Enum.Material.Metal
    )

    -- เสาวงกบข้างซ้าย-ขวา + บานประตูกระจกคู่แบบหมุนได้
    local hinges = {}
    local brokenVisuals = {}
    local cy = floorY + leafH / 2

    for _, sideSign in ipairs({ -1, 1 }) do
        local jambAlong = doorCenterAlong + sideSign * (openW / 2 - 0.12)
        PartBuilder.makePart(
            model, "Jamb_" .. sideSign,
            makeDoorSize(axis, 0.26, openH, 0.56),
            makeDoorCF(axis, jambAlong, floorY + openH / 2, fixedPos),
            FRAME_DARK, Enum.Material.Metal
        )

        local hingeAlong = doorCenterAlong + sideSign * (openW / 2 - 0.24)
        local hingeCF = makeDoorCF(axis, hingeAlong, cy, fixedPos)
        local leafMidAlong = hingeAlong - sideSign * (leafW / 2)

        local pane = PartBuilder.makePart(
            model, "LeafGlass_" .. sideSign,
            makeDoorSize(axis, leafW, leafH, 0.18),
            makeDoorCF(axis, leafMidAlong, cy, fixedPos),
            GLASS_TINT, Enum.Material.Glass, { Transparency = 0.52 }
        )
        local topRail = PartBuilder.makePart(
            model, "TopRail_" .. sideSign,
            makeDoorSize(axis, leafW, 0.26, 0.28),
            makeDoorCF(axis, leafMidAlong, floorY + leafH - 0.13, fixedPos),
            FRAME_DARK, Enum.Material.Metal
        )
        local botRail = PartBuilder.makePart(
            model, "BotRail_" .. sideSign,
            makeDoorSize(axis, leafW, 0.32, 0.28),
            makeDoorCF(axis, leafMidAlong, floorY + 0.16, fixedPos),
            FRAME_DARK, Enum.Material.Metal
        )
        local frost = PartBuilder.makePart(
            model, "FrostBand_" .. sideSign,
            makeDoorSize(axis, leafW - 0.08, 1.05, 0.21),
            makeDoorCF(axis, leafMidAlong, floorY + 5.2, fixedPos),
            FROST_STRIPE, Enum.Material.SmoothPlastic, { Transparency = 0.26 }
        )
        local handleAlong = hingeAlong - sideSign * (leafW - 0.55)
        local handleOffsetPos = fixedPos + inDirSign * 0.20
        local handleOffsetOut = fixedPos - inDirSign * 0.20
        local hIn = PartBuilder.makePart(
            model, "HandleIn_" .. sideSign,
            makeDoorSize(axis, 0.16, 2.2, 0.16),
            makeDoorCF(axis, handleAlong, floorY + 4.2, handleOffsetPos),
            ALUMINUM_TRIM, Enum.Material.Metal
        )
        local hOut = PartBuilder.makePart(
            model, "HandleOut_" .. sideSign,
            makeDoorSize(axis, 0.16, 2.2, 0.16),
            makeDoorCF(axis, handleAlong, floorY + 4.2, handleOffsetOut),
            ALUMINUM_TRIM, Enum.Material.Metal
        )

        table.insert(hinges, {
            sideSign = sideSign,
            hingeCF = hingeCF,
            entries = captureLeafParts(hingeCF, { pane, topRail, botRail, frost, hIn, hOut }),
        })

        -- เศษขอบเฟรมแตกเมื่อซอมบี้พังประตู
        table.insert(brokenVisuals, PartBuilder.makePart(
            model, "BrokenStub_" .. sideSign,
            makeDoorSize(axis, 0.55, 0.35, 0.28),
            makeDoorCF(axis, hingeAlong - sideSign * 0.3, floorY + 0.18, fixedPos),
            FRAME_DARK, Enum.Material.Metal, { CanCollide = false }
        ))
    end

    local doorCenter = (axis == "X")
        and Vector3.new(doorCenterAlong, floorY + 4.2, fixedPos)
        or Vector3.new(fixedPos, floorY + 4.2, doorCenterAlong)

    return attachInteractiveBehavior(model, hinges, {
        axis = axis,
        inDirSign = inDirSign,
        floorY = floorY,
        doorCenter = doorCenter,
        maxHP = opts.maxHP or 120,
        openDeg = opts.openDeg or 80,
        initialOpen = (opts.initialOpen == true),
        isGlass = true,
        doorType = "OfficeDoubleGlass",
        doorLabel = opts.doorLabel or "ประตูกระจกสำนักงาน",
        openActionText = "เปิดประตู",
        closeActionText = "ปิดประตูหลบซอมบี้",
        promptDist = 10.5,
        brokenVisualParts = brokenVisuals,
    })
end

--------------------------------------------------------------------------------
-- 2. ประตูบานเดี่ยวแบบเปิด-ปิดและซอมบี้พังได้ (ประตูทางเข้าห้องน้ำ / ประตูห้องส้วมย่อย)
--------------------------------------------------------------------------------
function InteractiveDoorBuilder.buildSingleDoor(parent, prefix, opts)
    local axis = opts.axis
    local doorCenterAlong = opts.doorCenterAlong
    local fixedPos = opts.fixedPos
    local inDirSign = opts.inDirSign
    local sideSign = opts.hingeSide or -1
    local floorY = opts.floorY

    local openW = opts.openW or 6.0
    local openH = opts.openH or 10.0
    local elevation = opts.elevation or 0
    local leafH = opts.leafH or (openH - 0.15 - elevation)
    local leafW = openW - 0.32
    local thick = opts.thick or 0.28
    local style = opts.style or "RestroomMain"

    local leafColor = opts.color or ((style == "ToiletStall")
        and Color3.fromRGB(168, 174, 178)
        or Color3.fromRGB(98, 72, 54))
    local leafMat = opts.material or ((style == "ToiletStall")
        and Enum.Material.SmoothPlastic
        or Enum.Material.WoodPlanks)

    local model = Instance.new("Model")
    model.Name = prefix .. "_Door"
    model.Parent = parent

    -- วงกบด้านซ้าย/ขวา/บน (สำหรับประตูห้องส้วมย่อยจะมีเสาคิ้วบางๆ ส่วนห้องน้ำหลักมีวงกบเต็ม)
    local jambThick = (style == "ToiletStall") and 0.18 or 0.28
    local jambDepth = (style == "ToiletStall") and 0.38 or 0.56
    for _, jSign in ipairs({ -1, 1 }) do
        PartBuilder.makePart(
            model, "Jamb_" .. jSign,
            makeDoorSize(axis, jambThick, openH - elevation, jambDepth),
            makeDoorCF(axis, doorCenterAlong + jSign * (openW / 2 - jambThick / 2), floorY + elevation + (openH - elevation) / 2, fixedPos),
            FRAME_DARK, Enum.Material.Metal
        )
    end
    PartBuilder.makePart(
        model, "Header_" .. prefix,
        makeDoorSize(axis, openW + 0.2, 0.28, jambDepth),
        makeDoorCF(axis, doorCenterAlong, floorY + openH - 0.14, fixedPos),
        FRAME_DARK, Enum.Material.Metal
    )

    -- บานประตู + รายละเอียดมือจับ/ช่องกระจกเล็ก/แผ่นกันกระแทก
    local hingeAlong = doorCenterAlong + sideSign * (openW / 2 - jambThick - 0.04)
    local leafMidAlong = hingeAlong - sideSign * (leafW / 2)
    local cy = floorY + elevation + leafH / 2
    local hingeCF = makeDoorCF(axis, hingeAlong, cy, fixedPos)

    local leafParts = {}
    local mainPanel = PartBuilder.makePart(
        model, "DoorLeaf",
        makeDoorSize(axis, leafW, leafH, thick),
        makeDoorCF(axis, leafMidAlong, cy, fixedPos),
        leafColor, leafMat
    )
    table.insert(leafParts, mainPanel)

    -- ลูกบิด/กลอนสแตนเลสทั้ง 2 ฝั่ง
    local knobAlong = hingeAlong - sideSign * (leafW - 0.65)
    local knobY = floorY + math.max(elevation + 1.8, 3.6)
    for _, fSign in ipairs({ -1, 1 }) do
        local knob = PartBuilder.makePart(
            model, "Knob_" .. fSign,
            makeDoorSize(axis, 0.35, 0.26, 0.24),
            makeDoorCF(axis, knobAlong, knobY, fixedPos + fSign * (thick / 2 + 0.10)),
            ALUMINUM_TRIM, Enum.Material.Metal
        )
        table.insert(leafParts, knob)
    end

    if style == "RestroomMain" then
        -- แผ่นสแตนเลสกันกระแทกด้านล่าง + ช่องกระจกส่องหลอนๆ ด้านบน
        local kickPlate = PartBuilder.makePart(
            model, "KickPlate",
            makeDoorSize(axis, leafW - 0.5, 1.4, thick + 0.05),
            makeDoorCF(axis, leafMidAlong, floorY + 0.85, fixedPos),
            ALUMINUM_TRIM, Enum.Material.Metal
        )
        local slitGlass = PartBuilder.makePart(
            model, "VisionSlit",
            makeDoorSize(axis, 1.0, 2.2, thick + 0.06),
            makeDoorCF(axis, leafMidAlong, floorY + 6.4, fixedPos),
            Color3.fromRGB(130, 155, 160), Enum.Material.Glass, { Transparency = 0.58 }
        )
        table.insert(leafParts, kickPlate)
        table.insert(leafParts, slitGlass)
    else
        -- ประตูห้องส้วมย่อย: คิ้วขอบสแตนเลส + ป้ายแสดงสถานะสีแดง/เขียวเล็ก
        local topTrim = PartBuilder.makePart(
            model, "StallTopTrim",
            makeDoorSize(axis, leafW, 0.14, thick + 0.05),
            makeDoorCF(axis, leafMidAlong, floorY + elevation + leafH - 0.07, fixedPos),
            FRAME_DARK, Enum.Material.Metal
        )
        table.insert(leafParts, topTrim)
    end

    local brokenVisuals = {
        PartBuilder.makePart(
            model, "BrokenHingeStub",
            makeDoorSize(axis, 0.8, 0.4, thick),
            makeDoorCF(axis, hingeAlong - sideSign * 0.4, floorY + elevation + 0.35, fixedPos),
            leafColor, leafMat, { CanCollide = false }
        )
    }

    local doorCenter = (axis == "X")
        and Vector3.new(doorCenterAlong, floorY + math.max(elevation + 2.5, 4.0), fixedPos)
        or Vector3.new(fixedPos, floorY + math.max(elevation + 2.5, 4.0), doorCenterAlong)

    return attachInteractiveBehavior(model, {
        {
            sideSign = sideSign,
            hingeCF = hingeCF,
            entries = captureLeafParts(hingeCF, leafParts),
        },
    }, {
        axis = axis,
        inDirSign = inDirSign,
        floorY = floorY,
        doorCenter = doorCenter,
        maxHP = opts.maxHP or ((style == "ToiletStall") and 60 or 110),
        openDeg = opts.openDeg or 84,
        initialOpen = (opts.initialOpen == true),
        isGlass = false,
        doorType = style,
        doorLabel = opts.doorLabel or ((style == "ToiletStall") and "ประตูห้องส้วม" or "ประตูห้องน้ำ"),
        openActionText = (style == "ToiletStall") and "เปิดเข้าห้องส้วม" or "เปิดประตูห้องน้ำ",
        closeActionText = "ปิดประตูหลบซอมบี้",
        promptDist = (style == "ToiletStall") and 7.5 or 9.5,
        brokenVisualParts = brokenVisuals,
    })
end

return InteractiveDoorBuilder
