--[[
    FPSController.client.lua
    โหมดทดสอบ (Test Mode): ลบปืนออกเรียบร้อย ไม่มีปืนถือในมือ
    เหลือเฉพาะมุมมองและ UI ทดสอบเบื้องต้น
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")

-- ลบ UI เก่าถ้ามี
local oldHud = pGui:FindFirstChild("ZombieFPS_HUD")
if oldHud then
    oldHud:Destroy()
end

-- ลบโมเดลปืนในกล้องถ้ามี
local camera = Workspace.CurrentCamera
local oldVm = camera:FindFirstChild("GunViewModel")
if oldVm then
    oldVm:Destroy()
end

-- สร้าง UI เรียบง่ายบอกสถานะการทดสอบ
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TestInfoUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = pGui

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0, 400, 0, 40)
infoLabel.Position = UDim2.new(0.5, -200, 0.05, 0)
infoLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
infoLabel.BackgroundTransparency = 0.3
infoLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
infoLabel.Font = Enum.Font.GothamBold
infoLabel.TextSize = 16
infoLabel.Text = "🧪 โหมดทดสอบการเดินซอมบี้ (แมพเปล่า & ถอดปืนออก)"
infoLabel.Parent = screenGui
Instance.new("UICorner", infoLabel).CornerRadius = UDim.new(0, 8)

print("✅ [Test Mode] ลบปืนออกเรียบร้อยแล้ว หน้าจอสะอาดพร้อมทดสอบ!")
