--[[
    Building40Layout.lua
    ค่าคงที่ผังอาคาร 40 ปี มจพ. (สเกล 2 เท่า) ที่ทุกชั้นใช้ร่วมกัน
    ปรับโซนลิฟต์-บันไดให้โปร่งโล่ง (โถงทางเข้าออกกลางกว้าง 60 studs)
    และตรงแนวดิ่งกันทุกชั้น 100%
]]

local Layout = {}

Layout.GROUND_Y = 1.0        -- ผิวพื้นชั้น 1
Layout.FLOOR_HEIGHT = 22.0   -- ความสูงต่อชั้น
Layout.WALL_THICK = 2.0

function Layout.floorY(floorNumber)
    return Layout.GROUND_Y + (floorNumber - 1) * Layout.FLOOR_HEIGHT
end

-- ตัวอาคารหลักเป็นสี่เหลี่ยมผืนผ้าเดียว (300 x 240 studs)
Layout.BODY = { halfX = 150, halfZ = 120 }

-- โซนคอร์หน้า/หลัง ภายในตัวอาคาร (ปรับให้โถงกลางกว้าง 60 studs ไม่แออัด)
-- คอร์ลิฟต์และบันได: X = ±30..±68 (กว้าง 38), Z = ±86..±120 (ลึก 34)
Layout.CORE = {
    bandInnerZ = 44,   -- ขอบติดลานจอดรถชั้น 1
    innerZ = 86,       -- ขอบในของปล่องลิฟต์และบันได
    outerZ = 120,      -- ขอบนอกของตึก (หน้าตึก +120 / หลังตึก -120)
    centerZ = 103,     -- กึ่งกลางปล่องลิฟต์และบันได ((86 + 120) / 2)
    depth = 34,        -- ความลึกปล่องลิฟต์และบันได (120 - 86)
    bandDepth = 76,    -- ความลึกแถบห้องหน้า/หลังชั้น 1 (120 - 44)
    sideX = 49,        -- จุดกึ่งกลางคอร์บันได/ลิฟต์ ((30 + 68) / 2 = 49)
    sideWidth = 38,    -- ความกว้างคอร์ลิฟต์/บันได (X = ±30..±68)
    centerWidth = 60,  -- โถงทางเข้าออกกลางกว้างโปร่ง (X = -30..+30)
}

-- ทางเชื่อมยื่นออกด้านหน้าตึกเฉพาะชั้น 2 (เชื่อมจากหน้าตึก Z=120 ไปหาบันไดใหญ่หน้าโรงอาหาร)
Layout.FRONT_BRIDGE = {
    width = 54,        -- กว้างรับกับโถงทางเข้าออกกลาง
    startZ = 120,
    endZ = 148,
    length = 28,
}

-- บันไดในตัวอาคาร (U-shape, ชานพักกลาง, ปากบันไดหันเข้าหาลิฟต์, เริ่มขึ้นจากเลนซ้าย)
Layout.STAIRS = {
    Front = { name = "FrontStairs", centerX = -49, centerZ =  103, entranceDir =  1, startSide = "left" },
    Rear  = { name = "RearStairs",  centerX =  49, centerZ = -103, entranceDir = -1, startSide = "left" },
}

-- ลิฟต์ในตัวอาคาร (ประตูหันเข้าหาบันได)
Layout.LIFTS = {
    Front = { name = "FrontLifts", centerX =  49, centerZ =  103, doorDir = -1 },
    Rear  = { name = "RearLifts",  centerX = -49, centerZ = -103, doorDir =  1 },
}

return Layout
