-- Lighting presets for authoring the map in daylight and playing in horror mode.

local Lighting = game:GetService("Lighting")

local LightingSetup = {}

function LightingSetup.init(mode)
    local colorCorrection = Lighting:FindFirstChild("Building40ColorCorrection")
    if not colorCorrection then
        colorCorrection = Instance.new("ColorCorrectionEffect")
        colorCorrection.Name = "Building40ColorCorrection"
        colorCorrection.Parent = Lighting
    end

    if mode == "Day" then
        Lighting.ClockTime = 14
        Lighting.Brightness = 2.2
        Lighting.ExposureCompensation = 0
        Lighting.OutdoorAmbient = Color3.fromRGB(155, 160, 168)
        Lighting.Ambient = Color3.fromRGB(135, 138, 145)
        Lighting.FogColor = Color3.fromRGB(190, 200, 215)
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        colorCorrection.Saturation = 0.05
        colorCorrection.Contrast = 0.04
        colorCorrection.Brightness = 0
        colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
    else
        Lighting.ClockTime = 0.2
        Lighting.Brightness = 0.9
        Lighting.OutdoorAmbient = Color3.fromRGB(12, 16, 26)
        Lighting.Ambient = Color3.fromRGB(25, 29, 39)
        Lighting.FogColor = Color3.fromRGB(15, 19, 29)
        Lighting.FogStart = 12
        Lighting.FogEnd = 420
        colorCorrection.Saturation = -0.28
        colorCorrection.Contrast = 0.18
        colorCorrection.Brightness = -0.04
        colorCorrection.TintColor = Color3.fromRGB(185, 205, 235)
    end

    Lighting.GlobalShadows = true
    local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
    sky.SunAngularSize = 15
    sky.Parent = Lighting
end

return LightingSetup
