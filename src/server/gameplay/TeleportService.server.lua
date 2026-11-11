--[[
    TeleportService.server.lua
    Server-authoritative zone/map teleportation service.
    Handles map teleport requests from the client Map Selector UI and chat commands.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote events setup
local eventsFolder = ReplicatedStorage:FindFirstChild("TeleportEvents") or Instance.new("Folder")
eventsFolder.Name = "TeleportEvents"
eventsFolder.Parent = ReplicatedStorage

local requestTeleport = eventsFolder:FindFirstChild("RequestTeleport") or Instance.new("RemoteEvent")
requestTeleport.Name = "RequestTeleport"
requestTeleport.Parent = eventsFolder

local teleportConfirmed = eventsFolder:FindFirstChild("TeleportConfirmed") or Instance.new("RemoteEvent")
teleportConfirmed.Name = "TeleportConfirmed"
teleportConfirmed.Parent = eventsFolder

-- Destination registry
local DESTINATIONS = {
    TheRange = {
        name = "The Range (สนามยิงปืน)",
        cframe = CFrame.lookAt(Vector3.new(0, 3.5, 395), Vector3.new(0, 3.5, 432)),
        desc = "สนามทดสอบอาวุธ 18 ชนิด & หุ่นซอมบี้ 5 ไซส์",
    },
    Floor1 = {
        name = "ตึก 40 ปี — ชั้น 1 ล็อบบี้",
        cframe = CFrame.lookAt(Vector3.new(0, 3.5, 10), Vector3.new(0, 3.5, 40)),
        desc = "โถงทางเข้าหลัก ประชาสัมพันธ์ ตู้เซฟ ลิฟต์และบันได",
    },
    Plaza = {
        name = "ลานหน้าอาคาร 40 ปี",
        cframe = CFrame.lookAt(Vector3.new(0, 5.5, 125), Vector3.new(0, 5.5, 60)),
        desc = "ลานจอดรถภายนอก สวนปาล์ม และสะพานข้ามคลอง",
    },
    Canteen = {
        name = "ชั้น 2 — โรงอาหาร 40 ปี",
        cframe = CFrame.lookAt(Vector3.new(0, 25.5, 10), Vector3.new(0, 25.5, 40)),
        desc = "โรงอาหาร ร้านค้า 8 ร้าน และห้องกินข้าวติดแอร์",
    },
    SportsArena = {
        name = "ชั้น 3 — สนามกีฬาในร่ม",
        cframe = CFrame.lookAt(Vector3.new(0, 47.5, 0), Vector3.new(0, 47.5, 30)),
        desc = "สนามฟุตซอล สนามบาสเกตบอล และอัฒจันทร์",
    },
    Rooftop = {
        name = "ชั้น 12 — สนามกีฬาดาดฟ้า",
        cframe = CFrame.lookAt(Vector3.new(0, 245.5, 0), Vector3.new(0, 245.5, 30)),
        desc = "สนามเซปักตะกร้อ สนามเทนนิส และวิวรอบตึก 40 ปี",
    },
}

local function doTeleport(player, destKey)
    local dest = DESTINATIONS[destKey]
    if not dest then
        warn(string.format("[TeleportService] Invalid destination '%s' requested by %s", tostring(destKey), player.Name))
        return false
    end

    local char = player.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then return false end

    -- Safe teleport
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = dest.cframe

    teleportConfirmed:FireClient(player, destKey, dest.name)
    print(string.format("[TeleportService] Teleported %s to %s", player.Name, dest.name))
    return true
end

-- Remote handler
requestTeleport.OnServerEvent:Connect(function(player, destKey)
    if typeof(destKey) ~= "string" then return end
    doTeleport(player, destKey)
end)

-- Chat command support
local function bindChat(player)
    player.Chatted:Connect(function(msg)
        local cmd = msg:lower():match("^%s*(%S+)")
        if cmd == "/range" or cmd == "!range" or cmd == "/the-range" or cmd == "/testrange" then
            doTeleport(player, "TheRange")
        elseif cmd == "/lobby" or cmd == "!lobby" or cmd == "/spawn" or cmd == "/b40" or cmd == "/floor1" then
            doTeleport(player, "Floor1")
        elseif cmd == "/plaza" or cmd == "!plaza" then
            doTeleport(player, "Plaza")
        elseif cmd == "/canteen" or cmd == "!canteen" or cmd == "/floor2" then
            doTeleport(player, "Canteen")
        elseif cmd == "/arena" or cmd == "/sports" or cmd == "/floor3" then
            doTeleport(player, "SportsArena")
        elseif cmd == "/roof" or cmd == "/rooftop" or cmd == "/floor12" then
            doTeleport(player, "Rooftop")
        end
    end)
end

Players.PlayerAdded:Connect(bindChat)
for _, p in ipairs(Players:GetPlayers()) do
    bindChat(p)
end

print("[TeleportService] Initialized with " .. 6 .. " zones.")
