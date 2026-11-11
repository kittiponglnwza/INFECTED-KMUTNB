--[[
    ZombieAI.lua
    Smart Hybrid Zombie AI for INFECTED-KMUTNB:
      - Aggro-weighted target acquisition
      - Clear Line-of-Sight direct pursuit with flanking arc
      - Persistent PathfindingService multi-waypoint navigation scaled per archetype
      - Anti-stuck jump/sidestep/relocation recovery
      - Melee combat preserving Admin GodMode and PlayerDamageEvent compatibility
      - Integrates directly with ZombieAnimationController and ZombieAudioController
]]

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local ZombieAI = {}

function ZombieAI.start(rig, archetype, animCtrl, audioCtrl, context)
    local zombie = rig.model
    local hrp = rig.hrp
    local humanoid = rig.humanoid
    local zombiesFolder = context.zombiesFolder
    local playerDamageEvent = context.playerDamageEvent
    local onPlayerDamaged = context.onPlayerDamaged
    local pickSpawnPosition = context.pickSpawnPosition

    task.spawn(function()
        local lastAttack = 0
        local lastPos = hrp.Position
        local lastMoveCheckTime = os.clock()
        local stuckTimer = 0

        local currentWaypoints = nil
        local wpIndex = 2
        local lastPathComputeTime = 0

        local flankAngle = (math.random() - 0.5) * math.rad(55)
        local losParams = RaycastParams.new()
        losParams.FilterType = Enum.RaycastFilterType.Exclude
        losParams.IgnoreWater = true

        local agentRadius = archetype.IsBoss and 2.35 or 1.45
        local agentHeight = archetype.IsBoss and 9.0 or 5.2
        local attackRange = archetype.AttackRange or 5.8
        local attackCooldown = archetype.AttackCooldown or 1.0
        local attackDmg = archetype.AttackDamage or 15

        while zombie and zombie.Parent and not zombie:GetAttribute("IsDead") do
            local now = os.clock()
            local dt = 0.12

            -- 1. Select highest-priority living player (biased toward recent shooter aggro)
            local aggroUserId = zombie:GetAttribute("AggroTargetUserId")
            local targetPlayer = nil
            local targetChar = nil
            local targetRoot = nil
            local nearestDist = math.huge

            for _, p in ipairs(Players:GetPlayers()) do
                local c = p.Character
                local pHum = c and c:FindFirstChildOfClass("Humanoid")
                local pRoot = c and c:FindFirstChild("HumanoidRootPart")
                if pHum and pHum.Health > 0 and pRoot then
                    local d = (pRoot.Position - hrp.Position).Magnitude
                    local effectiveDist = (aggroUserId and p.UserId == aggroUserId) and (d * 0.65) or d
                    if effectiveDist < nearestDist then
                        nearestDist = d
                        targetPlayer = p
                        targetChar = c
                        targetRoot = pRoot
                    end
                end
            end

            local stunnedUntil = zombie:GetAttribute("StunnedUntil") or 0
            local isStunned = now < stunnedUntil
            local isChasing = false

            if isStunned then
                humanoid.WalkSpeed = 1.5
                humanoid:MoveTo(hrp.Position)
            elseif targetRoot then
                local myPos = hrp.Position
                local targetPos = targetRoot.Position
                local toTarget = targetPos - myPos
                local horizDist = Vector3.new(toTarget.X, 0, toTarget.Z).Magnitude
                local heightDiff = math.abs(targetPos.Y - myPos.Y)

                local enragedUntil = zombie:GetAttribute("EnragedUntil") or 0
                if now < enragedUntil then
                    humanoid.WalkSpeed = archetype.ChaseSpeed
                    isChasing = true
                elseif nearestDist < 28 and heightDiff < 8.5 then
                    humanoid.WalkSpeed = archetype.RunSpeed
                    isChasing = true
                else
                    humanoid.WalkSpeed = archetype.WalkSpeed
                    isChasing = false
                end

                zombie:SetAttribute("IsChasing", isChasing)

                -- 2. Line-of-Sight check
                losParams.FilterDescendantsInstances = { zombiesFolder, targetChar }
                local rayOrigin = myPos + Vector3.new(0, archetype.IsBoss and 2.4 or 1.1, 0)
                local losRay = Workspace:Raycast(rayOrigin, targetPos - myPos, losParams)
                local hasClearLOS = (losRay == nil) and (heightDiff < 8.5)

                -- 3. Anti-stuck detector every 0.6s
                if now - lastMoveCheckTime >= 0.6 then
                    local movedDist = Vector3.new(myPos.X - lastPos.X, 0, myPos.Z - lastPos.Z).Magnitude
                    lastPos = myPos
                    lastMoveCheckTime = now

                    if movedDist < 0.65 and horizDist > attackRange then
                        stuckTimer = stuckTimer + 0.6
                        humanoid.Jump = true
                        local sideDir = (math.random(0, 1) == 0) and 1 or -1
                        local sidestepPos = myPos + (hrp.CFrame.RightVector * (sideDir * 7)) + (hrp.CFrame.LookVector * 3)
                        humanoid:MoveTo(sidestepPos)
                        currentWaypoints = nil

                        if stuckTimer >= 3.0 and pickSpawnPosition then
                            stuckTimer = 0
                            local preferF2 = (targetPos.Y >= 15)
                            hrp.CFrame = CFrame.new(pickSpawnPosition(preferF2))
                        end
                    else
                        stuckTimer = 0
                    end
                end

                -- 4. Movement: Direct flanking pursuit vs multi-waypoint Pathfinding
                if hasClearLOS then
                    currentWaypoints = nil
                    local targetVel = targetRoot.AssemblyLinearVelocity or Vector3.zero
                    local leadOffset = Vector3.new(targetVel.X, 0, targetVel.Z) * math.clamp(horizDist / 45, 0, 0.35)
                    local moveGoal = targetPos + leadOffset
                    if horizDist > 8.5 then
                        local flatDir = Vector3.new(toTarget.X, 0, toTarget.Z)
                        if flatDir.Magnitude > 0.05 then
                            local rotatedDir = CFrame.Angles(0, flankAngle, 0):VectorToWorldSpace(flatDir.Unit)
                            moveGoal = myPos + rotatedDir * math.min(horizDist, 18)
                        end
                    end
                    humanoid:MoveTo(moveGoal)
                else
                    local needNewPath = (not currentWaypoints)
                        or (wpIndex > #currentWaypoints)
                        or (now - lastPathComputeTime >= 1.2)

                    if needNewPath then
                        lastPathComputeTime = now
                        local ok, path = pcall(function()
                            local p = PathfindingService:CreatePath({
                                AgentRadius = agentRadius,
                                AgentHeight = agentHeight,
                                AgentCanJump = true,
                                WaypointSpacing = 3.5,
                            })
                            p:ComputeAsync(myPos, targetPos)
                            return p
                        end)

                        if ok and path and path.Status == Enum.PathStatus.Success then
                            local wps = path:GetWaypoints()
                            if #wps >= 2 then
                                currentWaypoints = wps
                                wpIndex = 2
                            else
                                currentWaypoints = nil
                            end
                        else
                            currentWaypoints = nil
                        end
                    end

                    if currentWaypoints and currentWaypoints[wpIndex] then
                        local wp = currentWaypoints[wpIndex]
                        local wpHorizontalDist = Vector3.new(wp.Position.X - myPos.X, 0, wp.Position.Z - myPos.Z).Magnitude
                        if wpHorizontalDist < 3.8 and math.abs(wp.Position.Y - myPos.Y) < 6 then
                            wpIndex = wpIndex + 1
                            wp = currentWaypoints[wpIndex]
                        end
                        if wp then
                            if wp.Action == Enum.PathWaypointAction.Jump then
                                humanoid.Jump = true
                            end
                            humanoid:MoveTo(wp.Position)
                        else
                            humanoid:MoveTo(targetPos)
                        end
                    else
                        humanoid:MoveTo(targetPos)
                    end
                end

                -- 5. Melee attack when in close range
                local heightTolerance = archetype.IsBoss and 7.2 or 5.5
                if horizDist <= attackRange and heightDiff <= heightTolerance and (now - lastAttack >= attackCooldown) then
                    lastAttack = now
                    zombie:SetAttribute("LastAttackTime", now)
                    animCtrl:setState("Attacking")
                    audioCtrl:triggerEvent("Attacking")

                    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
                    local isGodMode = (targetPlayer and targetPlayer:GetAttribute("IsAdminGodMode") == true)
                        or (targetChar:GetAttribute("IsAdminGodMode") == true)
                    if isGodMode then
                        if targetHum and targetHum.Health < targetHum.MaxHealth then
                            targetHum.Health = targetHum.MaxHealth
                        end
                    elseif targetHum and targetHum.Health > 0 then
                        targetHum:TakeDamage(attackDmg)
                        if targetPlayer then
                            if onPlayerDamaged then
                                onPlayerDamaged(targetPlayer, now)
                            end
                            if playerDamageEvent then
                                playerDamageEvent:FireClient(targetPlayer, attackDmg, targetHum.Health, targetHum.MaxHealth)
                            end
                        end
                    end
                end
            else
                zombie:SetAttribute("IsChasing", false)
            end

            local vel = hrp.AssemblyLinearVelocity
            local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
            audioCtrl:update(now, horizSpeed, isChasing, false)

            task.wait(dt)
        end

        if audioCtrl.stepSound then
            pcall(function() audioCtrl.stepSound:Stop() end)
        end
        if not zombie or not zombie.Parent then
            audioCtrl:destroy()
            animCtrl:destroy()
        end
    end)
end

return ZombieAI
