--[[
    LightingSetup.lua
    จัดการแสงและบรรยากาศในเกม (เวลากลางวัน Daytime พร้อมโทนสีสดใสสมจริง)
]]

local Lighting = game:GetService("Lighting")

local LightingSetup = {}

function LightingSetup.init()
    Lighting.ClockTime = 13.5 -- บ่ายโมงครึ่ง แดดส่องสว่าง เห็นรายละเอียดชัดเจน
    Lighting.Brightness = 2.5
    Lighting.OutdoorAmbient = Color3.fromRGB(140, 145, 155)
    Lighting.Ambient = Color3.fromRGB(150, 155, 160)
    Lighting.FogEnd = 100000 -- ปิดหมอกเพื่อให้เห็นตึกชัดเจน
    Lighting.GlobalShadows = true

    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
    cc.Saturation = 0.15
    cc.Contrast = 0.08
    cc.Brightness = 0.03
    cc.TintColor = Color3.fromRGB(255, 255, 255)

    local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
    sky.SunAngularSize = 15
end

return LightingSetup
