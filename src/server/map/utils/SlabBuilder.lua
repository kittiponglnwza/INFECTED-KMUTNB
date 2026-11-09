--[[
    SlabBuilder.lua
    สร้างพื้น (Slab) จากสี่เหลี่ยมหลายชิ้น และเจาะช่อง (เช่น ช่องบันได) ได้อัตโนมัติ
    rect = { minX, maxX, minZ, maxZ }
]]

local PartBuilder = require(script.Parent.PartBuilder)

local SlabBuilder = {}

local function inside(rect, x, z)
    return x > rect.minX and x < rect.maxX and z > rect.minZ and z < rect.maxZ
end

local function addUnique(list, v)
    for _, e in ipairs(list) do
        if math.abs(e - v) < 1e-4 then return end
    end
    table.insert(list, v)
end

-- topY = ระดับผิวบนของพื้น
function SlabBuilder.build(parent, name, solids, holes, topY, thickness, color, material)
    holes = holes or {}
    local xs, zs = {}, {}
    for _, list in ipairs({ solids, holes }) do
        for _, r in ipairs(list) do
            addUnique(xs, r.minX); addUnique(xs, r.maxX)
            addUnique(zs, r.minZ); addUnique(zs, r.maxZ)
        end
    end
    table.sort(xs); table.sort(zs)

    local function filled(i, j)
        local mx = (xs[i] + xs[i + 1]) / 2
        local mz = (zs[j] + zs[j + 1]) / 2
        for _, h in ipairs(holes) do
            if inside(h, mx, mz) then return false end
        end
        for _, s in ipairs(solids) do
            if inside(s, mx, mz) then return true end
        end
        return false
    end

    -- รวมช่องที่ติดกันในแนว X ให้เป็นชิ้นเดียว (ลดจำนวน Part)
    local count = 0
    for j = 1, #zs - 1 do
        local i = 1
        while i <= #xs - 1 do
            if filled(i, j) then
                local startX = xs[i]
                while i <= #xs - 1 and filled(i, j) do i += 1 end
                local endX = xs[i]
                count += 1
                PartBuilder.makePart(
                    parent,
                    name .. "_" .. count,
                    Vector3.new(endX - startX, thickness, zs[j + 1] - zs[j]),
                    CFrame.new((startX + endX) / 2, topY - thickness / 2, (zs[j] + zs[j + 1]) / 2),
                    color,
                    material
                )
            else
                i += 1
            end
        end
    end
end

return SlabBuilder
