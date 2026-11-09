--[[
    Building40Layout.lua
    ค่าคงที่ผังอาคาร 40 ปี มจพ. (สเกล 2 เท่า) ที่ทุกชั้นใช้ร่วมกัน
    เพื่อให้บันได / ลิฟต์ / ทางเข้าออก ตรงแนวดิ่งกันทุกชั้น

    แกนพิกัด (มองจากด้านบน):
      +Z = ด้านหน้าตึก (ฝั่งบันไดใหญ่โรงอาหาร)    -Z = ด้านหลังตึก
      +X = ฝั่งขวา (ทางเข้า-ออกรถ)                -X = ฝั่งซ้าย
]]

local Layout = {}

Layout.GROUND_Y = 1.0        -- ผิวพื้นชั้น 1
Layout.FLOOR_HEIGHT = 22.0   -- ความสูงต่อชั้น
Layout.WALL_THICK = 2.0

function Layout.floorY(floorNumber)
    return Layout.GROUND_Y + (floorNumber - 1) * Layout.FLOOR_HEIGHT
end

-- ตัวอาคารหลัก (ไม่รวมคอร์ที่ยื่นออกไปหน้า/หลัง)
Layout.BODY = { halfX = 150, halfZ = 120 }

-- คอร์หน้า/หลัง (บันได | ทางเข้าออก | ลิฟต์) ยื่นออกจากตัวอาคาร
Layout.CORE = {
    innerZ = 109,      -- ขอบคอร์ด้านในตึก
    outerZ = 145,      -- ขอบคอร์ด้านนอกตึก
    centerZ = 127,
    depth = 36,
    sideX = 47,        -- จุดกึ่งกลางคอร์บันได/ลิฟต์ (±X)
    sideWidth = 46,    -- คอร์ข้าง 24..70
    centerWidth = 48,  -- ทางเข้าออกกลาง -24..24
}

--[[
    บันได (U-shape, ชานพักกลาง)
      entranceDir : ทิศที่ปากบันไดหันไป (+1 = หันไป +X, -1 = หันไป -X)
                    -> ตั้งให้หันหน้าเข้าหาลิฟต์ที่อยู่ใกล้ที่สุดฝั่งตรงข้ามทางเข้าออก
      startSide   : "left"  = ช่วงแรกเริ่มขึ้นจากฝั่งซ้ายมือ (เมื่อยืนหน้าปากบันไดมองเข้าไป)
                    "right" = เริ่มขึ้นจากฝั่งขวามือ
]]
Layout.STAIRS = {
    Front = { name = "FrontStairs", centerX = -47, centerZ =  127, entranceDir =  1, startSide = "left" },
    Rear  = { name = "RearStairs",  centerX =  47, centerZ = -127, entranceDir = -1, startSide = "left" },
}

-- ลิฟต์ (ประตูหันเข้าหาบันได)
Layout.LIFTS = {
    Front = { name = "FrontLifts", centerX =  47, centerZ =  127, doorDir = -1 },
    Rear  = { name = "RearLifts",  centerX = -47, centerZ = -127, doorDir =  1 },
}

return Layout
