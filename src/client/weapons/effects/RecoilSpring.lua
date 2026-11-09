--[[
    RecoilSpring.lua
    โมดูลฟิสิกส์สปริง (Harmonic Spring Oscillator)
    ใช้สำหรับคำนวณแรงถีบปืน (Recoil Kickback), การคืนตัวของศูนย์เล็ง, และการส่ายเมาส์
]]

local Spring = {}
Spring.__index = Spring

function Spring.new(mass, force, damping, speed)
    local self = setmetatable({}, Spring)
    self.Mass = mass or 1
    self.Force = force or 50
    self.Damping = damping or 4
    self.Speed = speed or 4
    self.Velocity = Vector3.zero
    self.Position = Vector3.zero
    self.Target = Vector3.zero
    return self
end

function Spring:Impulse(velocity)
    self.Velocity = self.Velocity + velocity
end

function Spring:SetTarget(target)
    self.Target = target
end

function Spring:Update(dt)
    local scaledDt = math.min(dt, 0.1) * self.Speed
    local displacement = (self.Position - self.Target)
    local springForce = -self.Force * displacement
    local dampingForce = -self.Damping * self.Velocity
    local acceleration = (springForce + dampingForce) / self.Mass

    self.Velocity = self.Velocity + acceleration * scaledDt
    self.Position = self.Position + self.Velocity * scaledDt
    return self.Position
end

return Spring
