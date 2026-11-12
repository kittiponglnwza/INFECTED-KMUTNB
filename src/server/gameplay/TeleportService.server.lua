--[[
    TeleportService.server.lua
    Server-authoritative zone/map teleportation service.
    Handles map teleport requests from the client Map Selector UI and chat commands.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local campaignFolder = ServerScriptService:WaitForChild("Campaign", 10)
local DevAuthService = require(campaignFolder:WaitForChild("DevAuthService"))
local devAuth = DevAuthService.getSingleton()

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

-- Destination registry (usable only by authorized developers in Development Mode)
local DESTINATIONS = {
    TheRange = {
        name = "The Range (สนามยิงปืน Dev)",
        cframe = CFrame.lookAt(Vector3.new(0, 3.5, 395), Vector3.new(0, 3.5, 432)),
        desc = "สนามทดสอบอาวุธ 18 ชนิด & หุ่นซอมบี้ 5 ไซส์",
    },
    Floor1 = {
        name = "ตึก 40 ปี — ชั้น 1 ล็อบบี้",
        cframe = CFrame.lookAt(Vector3.new(0, 4.2, 10), Vector3.new(0, 4.2, 40)),
        desc = "โถงทางเข้าหลัก ชั้น 1 อาคาร 40 ปี",
    },
    F1Keycard = {
        name = "M1 Keycard Spawn (F1 Bangkok Bank Desk)",
        cframe = CFrame.lookAt(Vector3.new(114, 4.2, 76), Vector3.new(114, 4.2, 68)),
        desc = "จุดเกิดคีย์การ์ด M1 ภายในธนาคารกรุงเทพ ชั้น 1",
    },
    SecurityDoor = {
        name = "Room 102 Exterior North Doorway (F1)",
        cframe = CFrame.lookAt(Vector3.new(-109, 4.2, 37), Vector3.new(-109, 4.2, 47)),
        desc = "หน้าประตูห้องควบคุมความปลอดภัย ห้อง 102",
    },
    SecurityRoom = {
        name = "Room 102 Security Control Interior (F1)",
        cframe = CFrame.lookAt(Vector3.new(-109, 4.2, 58), Vector3.new(-109, 4.2, 74)),
        desc = "ภายในห้องควบคุมความปลอดภัย ห้อง 102",
    },
    F1Cafe = {
        name = "Floor 1 Campus Cafe",
        cframe = CFrame.lookAt(Vector3.new(98, 4.2, -78), Vector3.new(98, 4.2, -96)),
        desc = "คาเฟ่ชั้น 1 ตึก 40 ปี",
    },
    Plaza = {
        name = "ลานหน้าอาคาร 40 ปี",
        cframe = CFrame.lookAt(Vector3.new(0, 5.5, 125), Vector3.new(0, 5.5, 60)),
        desc = "ลานจอดรถภายนอก สวนปาล์ม และสะพานข้ามคลอง",
    },
    Canteen = {
        name = "ชั้น 2 — โรงอาหาร 40 ปี",
        cframe = CFrame.lookAt(Vector3.new(0, 26.2, 10), Vector3.new(0, 26.2, 40)),
        desc = "โรงอาหาร ร้านค้า 8 ร้าน และห้องกินข้าวติดแอร์",
    },
    SportsArena = {
        name = "ชั้น 3 — สนามกีฬาในร่ม",
        cframe = CFrame.lookAt(Vector3.new(0, 48.2, 0), Vector3.new(0, 48.2, 30)),
        desc = "สนามฟุตซอล สนามบาสเกตบอล และอัฒจันทร์",
    },
    Floor11 = {
        name = "ชั้น 11 — Secret Lab Corridor",
        cframe = CFrame.lookAt(Vector3.new(0, 224.2, 0), Vector3.new(0, 224.2, -30)),
        desc = "เขตห้องทดลองชั้น 11",
    },
    Rooftop = {
        name = "ชั้น 12 — สนามกีฬาดาดฟ้า",
        cframe = CFrame.lookAt(Vector3.new(0, 246.2, 0), Vector3.new(0, 246.2, 30)),
        desc = "สนามเซปักตะกร้อ สนามเทนนิส และลาน ฮ",
    },
}

local function doTeleport(player, destKey)
    local okAuth = devAuth.authorizeOrAutoStudioDev(player)
    if not okAuth then
        warn(string.format("[TeleportService] Denied teleport to '%s' for %s (Campaign Mode / unauthorized)", tostring(destKey), player and player.Name or "Unknown"))
        return false, "Teleport disabled in Campaign Mode. Authorized devs must run !dev first."
    end

    local dest = DESTINATIONS[destKey]
    if not dest then
        warn(string.format("[TeleportService] Invalid destination '%s' requested by %s", tostring(destKey), player.Name))
        return false, string.format("Unknown location '%s'", tostring(destKey))
    end

    local char = player.Character
    if not char then return false, "Character not spawned" end

    local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then return false, "Player must be alive to teleport" end

    -- Safe teleport
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = dest.cframe

    devAuth.markDevSessionTainted()
    teleportConfirmed:FireClient(player, destKey, dest.name)
    print(string.format("[TeleportService] [DEV] Teleported %s to %s", player.Name, dest.name))
    return true, dest.name
end

local devSignals = ServerStorage:FindFirstChild("DevSignals") or Instance.new("Folder")
devSignals.Name = "DevSignals"
devSignals.Parent = ServerStorage
local tpBindable = devSignals:FindFirstChild("TeleportPlayer") or Instance.new("BindableFunction")
tpBindable.Name = "TeleportPlayer"
tpBindable.Parent = devSignals
tpBindable.OnInvoke = function(player, destKey)
    return doTeleport(player, destKey)
end

-- Remote handler (strict server authorization)
requestTeleport.OnServerEvent:Connect(function(player, destKey)
    if typeof(destKey) ~= "string" then return end
    doTeleport(player, destKey)
end)

-- Legacy slash chat aliases preserved strictly for active Development Mode sessions
local function bindChat(player)
    player.Chatted:Connect(function(msg)
        if not devAuth.isDevModeEnabled(player) and not (devAuth.getEnvironmentKind() == "Studio" and devAuth.isAuthorizedDeveloper(player)) then
            return
        end
        local cmd = msg:lower():match("^%s*(%S+)")
        if cmd == "/range" or cmd == "/the-range" or cmd == "/testrange" then
            doTeleport(player, "TheRange")
        elseif cmd == "/lobby" or cmd == "/spawn" or cmd == "/b40" or cmd == "/floor1" then
            doTeleport(player, "Floor1")
        elseif cmd == "/plaza" then
            doTeleport(player, "Plaza")
        elseif cmd == "/canteen" or cmd == "/floor2" then
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

print("[TeleportService] Initialized with Dev-Mode server gate (" .. 11 .. " zones).")
