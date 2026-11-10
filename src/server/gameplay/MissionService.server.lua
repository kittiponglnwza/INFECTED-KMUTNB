--[[
    MissionService.server.lua
    Server-authoritative campaign objective state for INFECTED-KMUTNB.

    Other server scripts complete objectives through:
        ServerStorage.MissionSignals.CompleteObjective:Fire("OBJECTIVE_ID", player)

    Clients can request a read-only state snapshot. There is intentionally no
    client-to-server objective completion RemoteEvent.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local eventsFolder = ReplicatedStorage:FindFirstChild("MissionEvents")
if not eventsFolder then
    eventsFolder = Instance.new("Folder")
    eventsFolder.Name = "MissionEvents"
    eventsFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name)
    local remote = eventsFolder:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = eventsFolder
    end
    return remote
end

local stateChanged = getOrCreateRemote("StateChanged")
local stateRequest = getOrCreateRemote("StateRequest")

local signalsFolder = ServerStorage:FindFirstChild("MissionSignals")
if not signalsFolder then
    signalsFolder = Instance.new("Folder")
    signalsFolder.Name = "MissionSignals"
    signalsFolder.Parent = ServerStorage
end

local completeObjectiveSignal = signalsFolder:FindFirstChild("CompleteObjective")
if not completeObjectiveSignal then
    completeObjectiveSignal = Instance.new("BindableEvent")
    completeObjectiveSignal.Name = "CompleteObjective"
    completeObjectiveSignal.Parent = signalsFolder
end

local OBJECTIVES = {
    {
        id = "SECURITY_ACCESS",
        title = "ค้นหาบัตรผ่านห้องรักษาความปลอดภัย",
        description = "สำรวจพื้นที่ชั้น 1 และหาทางเข้า Security Room",
    },
    {
        id = "RESTORE_POWER",
        title = "กู้คืนระบบไฟฟ้า",
        description = "ค้นหาฟิวส์และเปิดเครื่องกำเนิดไฟฟ้า",
    },
    {
        id = "DECODE_SAFE",
        title = "ถอดรหัสตู้เซฟ",
        description = "รวบรวมเบาะแสเพื่อค้นหารหัสและ Master Keycard",
    },
    {
        id = "CALL_RESCUE",
        title = "ติดต่อหน่วยกู้ภัย",
        description = "ซ่อมวิทยุและส่งสัญญาณขอความช่วยเหลือ",
    },
    {
        id = "REACH_ROOF",
        title = "เดินทางขึ้นสู่ดาดฟ้า",
        description = "ปลดล็อกเส้นทางและฝ่าฝูงซอมบี้ขึ้นไปด้านบน",
    },
    {
        id = "ACTIVATE_BEACON",
        title = "เปิดสัญญาณจุดรับตัว",
        description = "เปิด Beacon เพื่อกำหนดตำแหน่งให้เฮลิคอปเตอร์",
    },
    {
        id = "BOARD_HELICOPTER",
        title = "ขึ้นเฮลิคอปเตอร์",
        description = "ป้องกันจุดรับตัวและขึ้นเฮลิคอปเตอร์ให้ทันเวลา",
    },
}

local currentIndex = 1
local completedObjectives = {}
local campaignComplete = false

local function getSnapshot()
    local current = OBJECTIVES[currentIndex]
    return {
        currentIndex = currentIndex,
        totalObjectives = #OBJECTIVES,
        currentObjective = current and {
            id = current.id,
            title = current.title,
            description = current.description,
        } or nil,
        completedObjectives = table.clone(completedObjectives),
        isComplete = campaignComplete,
    }
end

local function broadcastState()
    stateChanged:FireAllClients(getSnapshot())
end

local function completeObjective(objectiveId, completingPlayer)
    if campaignComplete then
        return
    end

    local current = OBJECTIVES[currentIndex]
    if not current or current.id ~= objectiveId then
        warn(string.format(
            "[MissionService] Ignored out-of-order objective completion: %s (current: %s)",
            tostring(objectiveId),
            current and current.id or "NONE"
        ))
        return
    end

    table.insert(completedObjectives, current.id)
    print(string.format(
        "[MissionService] Objective completed: %s%s",
        current.id,
        completingPlayer and (" by " .. completingPlayer.Name) or ""
    ))

    currentIndex += 1
    if currentIndex > #OBJECTIVES then
        campaignComplete = true
    end

    broadcastState()
end

completeObjectiveSignal.Event:Connect(completeObjective)

stateRequest.OnServerEvent:Connect(function(player)
    stateChanged:FireClient(player, getSnapshot())
end)

Players.PlayerAdded:Connect(function(player)
    task.defer(function()
        if player.Parent == Players then
            stateChanged:FireClient(player, getSnapshot())
        end
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.defer(function()
        if player.Parent == Players then
            stateChanged:FireClient(player, getSnapshot())
        end
    end)
end

print("[MissionService] Campaign objective framework ready.")
broadcastState()
