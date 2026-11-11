--[[
    PreviewCameraController.lua
    Manages smooth 360-degree camera orbit, desktop mouse drag/wheel zoom,
    mobile touch pan/pinch zoom, view presets (Front/Side/Back/Reset),
    and seamless coordination with FPSController via player attributes.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local PreviewCameraController = {}
PreviewCameraController.__index = PreviewCameraController

function PreviewCameraController.new()
    local self = setmetatable({
        player = Players.LocalPlayer,
        camera = Workspace.CurrentCamera,
        mode = "Walk", -- "Orbit" | "WeaponEye1P" | "ThirdPersonFollow" | "Walk"
        activeInStudio = false,

        focusPos = Vector3.new(0, 123, 470),
        targetFocus = Vector3.new(0, 123, 470),
        yaw = math.rad(180),
        pitch = math.rad(-12),
        dist = 8.5,

        targetYaw = math.rad(180),
        targetPitch = math.rad(-12),
        targetDist = 8.5,

        defaultFocus = Vector3.new(0, 123, 470),
        defaultYaw = math.rad(180),
        defaultPitch = math.rad(-12),
        defaultDist = 8.5,

        minDist = 1.6,
        maxDist = 26.0,

        dragging = false,
        lastPointerPos = Vector2.zero,
        pinchStartDist = nil,
        eyeOverrideCF = nil,
        connections = {},
    }, PreviewCameraController)

    self:_bindInput()
    return self
end

function PreviewCameraController:_isOrbitCameraActive()
    return self.activeInStudio and self.mode == "Orbit"
end

function PreviewCameraController:_syncAttributes()
    local orbitActive = self.activeInStudio and (self.mode == "Orbit" or self.mode == "WeaponEye1P")
    local tpActive = self.activeInStudio and (self.mode == "ThirdPersonFollow")

    self.player:SetAttribute("ShowcaseOrbitMode", orbitActive)
    self.player:SetAttribute("ShowcaseThirdPersonMove", tpActive)

    if orbitActive then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    elseif not self.activeInStudio then
        local cam = Workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
        end
    end
end

function PreviewCameraController:_bindInput()
    -- Desktop mouse orbit & zoom
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not self:_isOrbitCameraActive() or gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.Touch then
            self.dragging = true
            self.lastPointerPos = input.Position
        end
    end))

    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.Touch then
            self.dragging = false
            self.pinchStartDist = nil
        end
    end))

    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if not self:_isOrbitCameraActive() then return end

        if input.UserInputType == Enum.UserInputType.MouseMovement and self.dragging then
            local dx = input.Position.X - self.lastPointerPos.X
            local dy = input.Position.Y - self.lastPointerPos.Y
            self.lastPointerPos = input.Position
            self.targetYaw = self.targetYaw - dx * 0.0085
            self.targetPitch = math.clamp(self.targetPitch - dy * 0.0075, math.rad(-74), math.rad(60))
        elseif input.UserInputType == Enum.UserInputType.Touch and self.dragging and not gameProcessed then
            local dx = input.Position.X - self.lastPointerPos.X
            local dy = input.Position.Y - self.lastPointerPos.Y
            self.lastPointerPos = input.Position
            self.targetYaw = self.targetYaw - dx * 0.011
            self.targetPitch = math.clamp(self.targetPitch - dy * 0.009, math.rad(-74), math.rad(60))
        elseif input.UserInputType == Enum.UserInputType.MouseWheel and not gameProcessed then
            self:zoomBy(-input.Position.Z * 1.05)
        end
    end))

    -- Mobile multi-touch pan & pinch-zoom support
    table.insert(self.connections, UserInputService.TouchPan:Connect(function(_, totalTranslation, _, gameProcessed)
        if not self:_isOrbitCameraActive() or gameProcessed then return end
        self.targetYaw = self.targetYaw - totalTranslation.X * 0.0008
        self.targetPitch = math.clamp(self.targetPitch - totalTranslation.Y * 0.0007, math.rad(-74), math.rad(60))
    end))

    table.insert(self.connections, UserInputService.TouchPinch:Connect(function(_, scale, _, touchState, gameProcessed)
        if not self:_isOrbitCameraActive() or gameProcessed then return end
        if touchState == Enum.UserInputState.Begin then
            self.pinchStartDist = self.targetDist
        elseif touchState == Enum.UserInputState.Change and self.pinchStartDist then
            self.targetDist = math.clamp(self.pinchStartDist / math.max(0.25, scale), self.minDist, self.maxDist)
        elseif touchState == Enum.UserInputState.End then
            self.pinchStartDist = nil
        end
    end))
end

function PreviewCameraController:setActive(enabled)
    self.activeInStudio = (enabled == true)
    if not self.activeInStudio then
        self.dragging = false
        self.pinchStartDist = nil
        self.mode = "Walk"
    end
    self:_syncAttributes()
end

function PreviewCameraController:setMode(mode, eyeCF)
    self.mode = mode
    self.eyeOverrideCF = eyeCF
    self:_syncAttributes()
end

function PreviewCameraController:setFocusPreset(focusPos, dist, yawRad, pitchRad, instantSnap)
    self.defaultFocus = focusPos
    self.defaultDist = math.clamp(dist or 8.0, self.minDist, self.maxDist)
    self.defaultYaw = yawRad or math.rad(180)
    self.defaultPitch = pitchRad or math.rad(-12)

    self.targetFocus = self.defaultFocus
    self.targetDist = self.defaultDist
    self.targetYaw = self.defaultYaw
    self.targetPitch = self.defaultPitch

    if instantSnap then
        self.focusPos = self.targetFocus
        self.dist = self.targetDist
        self.yaw = self.targetYaw
        self.pitch = self.targetPitch
    end
end

function PreviewCameraController:setViewAngle(presetName)
    if presetName == "Front" then
        self.targetYaw = math.rad(180)
        self.targetPitch = math.rad(-10)
    elseif presetName == "Side" then
        self.targetYaw = math.rad(90)
        self.targetPitch = math.rad(-10)
    elseif presetName == "Back" then
        self.targetYaw = 0
        self.targetPitch = math.rad(-10)
    elseif presetName == "Reset" then
        self.targetFocus = self.defaultFocus
        self.targetYaw = self.defaultYaw
        self.targetPitch = self.defaultPitch
        self.targetDist = self.defaultDist
    end
end

function PreviewCameraController:zoomBy(delta)
    self.targetDist = math.clamp(self.targetDist + delta, self.minDist, self.maxDist)
end

function PreviewCameraController:setTargetFocusOnly(pos)
    self.targetFocus = pos
end

function PreviewCameraController:setEyeCFrame(cf)
    self.eyeOverrideCF = cf
end

function PreviewCameraController:step(dt)
    local cam = Workspace.CurrentCamera
    if not cam or not self.activeInStudio then return end

    if self.mode == "Orbit" then
        local alpha = 1 - math.exp(-dt * 14)
        self.focusPos = self.focusPos:Lerp(self.targetFocus, alpha)
        self.yaw = self.yaw + (self.targetYaw - self.yaw) * alpha
        self.pitch = self.pitch + (self.targetPitch - self.pitch) * alpha
        self.dist = self.dist + (self.targetDist - self.dist) * alpha

        local rotCF = CFrame.fromEulerAnglesYXZ(self.pitch, self.yaw, 0)
        local camPos = self.focusPos + (rotCF * Vector3.new(0, 0, self.dist))
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = CFrame.lookAt(camPos, self.focusPos)
    elseif self.mode == "WeaponEye1P" and self.eyeOverrideCF then
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = self.eyeOverrideCF
    end
end

function PreviewCameraController:destroy()
    self:setActive(false)
    for _, conn in ipairs(self.connections) do
        conn:Disconnect()
    end
    table.clear(self.connections)
end

return PreviewCameraController
