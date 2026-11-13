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

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local ZombieAI = {}

local function findClosedBreakableAncestor(inst)
    local cur = inst
    while cur and cur ~= Workspace do
        if CollectionService:HasTag(cur, "BreakableDoor") then
            if cur:GetAttribute("IsOpen") ~= true and cur:GetAttribute("IsBroken") ~= true then
                return cur
            end
            return nil
        end
        cur = cur.Parent
    end
    return nil
end

local function findClosedBarricadeAncestor(inst)
    local cur = inst
    while cur and cur ~= Workspace do
        if CollectionService:HasTag(cur, "BreakableBarricade") then
            if (cur:GetAttribute("PlanksRemaining") or 0) > 0 then
                return cur
            end
            return nil
        end
        cur = cur.Parent
    end
    return nil
end

local function findBlockingDoor(myPos, targetPos, losRay, hasClearLOS, attackRange, horizDist)
    if losRay and losRay.Instance then
        local directDoor = findClosedBreakableAncestor(losRay.Instance)
        if directDoor then
            local dc = directDoor:GetAttribute("DoorCenter") or losRay.Position
            local dHorizMe = Vector3.new(dc.X - myPos.X, 0, dc.Z - myPos.Z).Magnitude
            return directDoor, dHorizMe, dc, "Door"
        end
        local directBarricade = findClosedBarricadeAncestor(losRay.Instance)
        if directBarricade then
            local bc = directBarricade:GetAttribute("BarricadeCenter") or losRay.Position
            local bHorizMe = Vector3.new(bc.X - myPos.X, 0, bc.Z - myPos.Z).Magnitude
            return directBarricade, bHorizMe, bc, "Barricade"
        end
    end

    local bestBarrier, bestScore, bestMeDist, bestCenter, bestKind = nil, math.huge, math.huge, nil, nil
    for _, door in ipairs(CollectionService:GetTagged("BreakableDoor")) do
        if door and door.Parent and door:GetAttribute("IsOpen") ~= true and door:GetAttribute("IsBroken") ~= true then
            local dc = door:GetAttribute("DoorCenter")
            if dc and math.abs(dc.Y - myPos.Y) < 8.5 and math.abs(dc.Y - targetPos.Y) < 8.5 then
                local dHorizMe = Vector3.new(dc.X - myPos.X, 0, dc.Z - myPos.Z).Magnitude
                local dHorizTarget = Vector3.new(dc.X - targetPos.X, 0, dc.Z - targetPos.Z).Magnitude
                local nearMe = (dHorizMe <= attackRange + 1.8)
                local blockingRoom = (not hasClearLOS) and (dHorizTarget <= 46) and ((dHorizMe + dHorizTarget) <= (horizDist + 48))
                if nearMe or blockingRoom then
                    local score = nearMe and dHorizMe or (dHorizTarget + dHorizMe * 0.35 + 10)
                    if score < bestScore then
                        bestScore = score
                        bestBarrier = door
                        bestMeDist = dHorizMe
                        bestCenter = dc
                        bestKind = "Door"
                    end
                end
            end
        end
    end

    for _, bar in ipairs(CollectionService:GetTagged("BreakableBarricade")) do
        if bar and bar.Parent and (bar:GetAttribute("PlanksRemaining") or 0) > 0 then
            local bc = bar:GetAttribute("BarricadeCenter")
            if not bc then
                local fp = bar:FindFirstChild("Frame") or bar:FindFirstChildWhichIsA("BasePart")
                bc = fp and fp.Position
            end
            if bc and math.abs(bc.Y - myPos.Y) < 9.5 and math.abs(bc.Y - targetPos.Y) < 9.5 then
                local bHorizMe = Vector3.new(bc.X - myPos.X, 0, bc.Z - myPos.Z).Magnitude
                local bHorizTarget = Vector3.new(bc.X - targetPos.X, 0, bc.Z - targetPos.Z).Magnitude
                local nearMe = (bHorizMe <= attackRange + 2.4)
                local blockingRoom = (not hasClearLOS) and (bHorizTarget <= 54) and ((bHorizMe + bHorizTarget) <= (horizDist + 56))
                if nearMe or blockingRoom then
                    local score = nearMe and bHorizMe or (bHorizTarget + bHorizMe * 0.32 + 6)
                    if score < bestScore then
                        bestScore = score
                        bestBarrier = bar
                        bestMeDist = bHorizMe
                        bestCenter = bc
                        bestKind = "Barricade"
                    end
                end
            end
        end
    end

    return bestBarrier, bestMeDist, bestCenter, bestKind
end

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
                if pHum and pHum.Health > 0 and pRoot and c:GetAttribute("IsDowned") ~= true and p:GetAttribute("IsDowned") ~= true then
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
                local playerTargetPos = targetRoot.Position
                local priorityPos = zombie:GetAttribute("PriorityTargetPos")
                local targetPos = playerTargetPos
                if typeof(priorityPos) == "Vector3" then
                    if (myPos - priorityPos).Magnitude <= 14 or (playerTargetPos - myPos).Magnitude <= 20 then
                        zombie:SetAttribute("PriorityTargetPos", nil)
                    else
                        targetPos = priorityPos
                    end
                end
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

                -- 2. Line-of-Sight & closed breakable door check
                losParams.FilterDescendantsInstances = { zombiesFolder, targetChar }
                local rayOrigin = myPos + Vector3.new(0, archetype.IsBoss and 2.4 or 1.1, 0)
                local losRay = Workspace:Raycast(rayOrigin, targetPos - myPos, losParams)
                local hasClearLOS = (losRay == nil) and (heightDiff < 8.5)
                local blockedDoor, doorHorizDist, doorCenter, barrierKind = findBlockingDoor(
                    myPos, targetPos, losRay, hasClearLOS, attackRange, horizDist
                )
                local bashPadding = (barrierKind == "Barricade") and 2.4 or 1.8
                local isBashingDoor = blockedDoor ~= nil and doorHorizDist <= (attackRange + bashPadding)

                -- 3. Anti-stuck detector every 0.6s (do not relocate while bashing a closed door)
                if now - lastMoveCheckTime >= 0.6 then
                    local movedDist = Vector3.new(myPos.X - lastPos.X, 0, myPos.Z - lastPos.Z).Magnitude
                    lastPos = myPos
                    lastMoveCheckTime = now

                    if isBashingDoor then
                        stuckTimer = 0
                    elseif movedDist < 0.65 and horizDist > attackRange then
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

                -- 4. Movement: Direct flanking pursuit vs multi-waypoint Pathfinding (steer toward closed doors blocking a room)
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
                    local navGoal = (blockedDoor and doorCenter) or targetPos
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
                            p:ComputeAsync(myPos, navGoal)
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

                    if isBashingDoor and doorCenter then
                        humanoid:MoveTo(doorCenter)
                    elseif currentWaypoints and currentWaypoints[wpIndex] then
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
                            humanoid:MoveTo(navGoal)
                        end
                    else
                        humanoid:MoveTo(navGoal)
                    end
                end

                -- 5. Melee attack when in close range (players or closed breakable doors)
                local heightTolerance = archetype.IsBoss and 7.2 or 5.5
                if (now - lastAttack >= attackCooldown) then
                    if horizDist <= attackRange and heightDiff <= heightTolerance then
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
                    elseif isBashingDoor and blockedDoor then
                        local dmgFn = (barrierKind == "Barricade")
                            and blockedDoor:FindFirstChild("DamageBarricade")
                            or blockedDoor:FindFirstChild("DamageDoor")
                        if dmgFn and dmgFn:IsA("BindableFunction") then
                            lastAttack = now
                            zombie:SetAttribute("LastAttackTime", now)
                            animCtrl:setState("Attacking")
                            audioCtrl:triggerEvent("Attacking")
                            stuckTimer = 0
                            local keepOrBroke = false
                            pcall(function()
                                if barrierKind == "Barricade" then
                                    local stillHasPlanks = dmgFn:Invoke(attackDmg, myPos)
                                    keepOrBroke = not stillHasPlanks
                                else
                                    keepOrBroke = dmgFn:Invoke(attackDmg, myPos)
                                end
                            end)
                            if keepOrBroke then
                                currentWaypoints = nil
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
