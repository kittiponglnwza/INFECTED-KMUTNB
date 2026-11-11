--[[
    WeaponPoseSolver.lua
    Shared procedural keyframe & recoil mechanism solver for all 18 weapons.
    Used by both FPSController (live gameplay) and RangeShowcaseController (studio preview).
]]

local WeaponPoseSolver = {}

local I = CFrame.identity

local function rotD(rx, ry, rz)
    return CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

local function cf(x, y, z, rx, ry, rz)
    return CFrame.new(x or 0, y or 0, z or 0) * rotD(rx, ry, rz)
end

local function pivotRot(pivot, rx, ry, rz)
    return CFrame.new(pivot) * rotD(rx, ry, rz) * CFrame.new(-pivot)
end

local function smooth01(t)
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function evalCFTrack(track, prog)
    if not track then return I end
    local n = #track
    if prog <= track[1][1] then return track[1][2] end
    if prog >= track[n][1] then return track[n][2] end
    for i = 1, n - 1 do
        local k1, k2 = track[i], track[i + 1]
        if prog >= k1[1] and prog <= k2[1] then
            local span = math.max(0.0001, k2[1] - k1[1])
            return k1[2]:Lerp(k2[2], smooth01((prog - k1[1]) / span))
        end
    end
    return I
end

local function evalScalarTrack(track, prog)
    if not track then return 0 end
    local n = #track
    if prog <= track[1][1] then return track[1][2] end
    if prog >= track[n][1] then return track[n][2] end
    for i = 1, n - 1 do
        local k1, k2 = track[i], track[i + 1]
        if prog >= k1[1] and prog <= k2[1] then
            local span = math.max(0.0001, k2[1] - k1[1])
            local a = smooth01((prog - k1[1]) / span)
            return k1[2] + (k2[2] - k1[2]) * a
        end
    end
    return 0
end

local function windowContains(win, p)
    return win ~= nil and p >= win[1] and p <= win[2]
end

WeaponPoseSolver.INSPECT_DURATION = 3.6
WeaponPoseSolver.EQUIP_DURATION = 0.34
WeaponPoseSolver.UNEQUIP_DURATION = 0.28

local INSPECT_GUN_TRACK = {
    { 0.00, I },
    { 0.22, cf(-0.14, 0.14, 0.18, 14, 34, -22) },
    { 0.48, cf(-0.06, 0.16, 0.15, 10, 18, -32) },
    { 0.72, cf(0.14, 0.12, 0.16, 12, -32, 26) },
    { 0.88, cf(0.06, 0.08, 0.10, 6, -12, 8) },
    { 1.00, I },
}

local INSPECT_LEFT_TRACK = {
    { 0.00, I },
    { 0.25, cf(0.02, 0.04, 0.05, 0, 8, -10) },
    { 0.72, cf(-0.02, 0.02, 0.04, 0, -6, 8) },
    { 1.00, I },
}

local EQUIP_GUN_TRACK = {
    { 0.00, cf(-0.14, -0.58, 0.28, -36, 18, -14) },
    { 0.45, cf(-0.04, -0.14, 0.08, -10, 6, -4) },
    { 0.78, cf(0.02, 0.03, -0.02, 4, -2, 2) },
    { 1.00, I },
}

local EQUIP_LEFT_TRACK = {
    { 0.00, cf(-0.16, -0.35, 0.18, -14, 0, -8) },
    { 0.65, cf(-0.02, -0.05, 0.04, -2, 0, 0) },
    { 1.00, I },
}

local UNEQUIP_GUN_TRACK = {
    { 0.00, I },
    { 0.32, cf(0.02, -0.12, 0.06, -12, -4, 6) },
    { 1.00, cf(-0.14, -0.62, 0.30, -40, 18, -16) },
}

local UNEQUIP_LEFT_TRACK = {
    { 0.00, I },
    { 1.00, cf(-0.14, -0.40, 0.20, -18, 0, -10) },
}

local RIFLE_GUN_TRACK = {
    { 0.00, I },
    { 0.18, cf(-0.08, 0.08, 0.04, 14, -14, -20) },
    { 0.28, cf(-0.09, 0.03, 0.06, 10, -14, -22) },
    { 0.50, cf(-0.08, 0.08, 0.04, 15, -12, -18) },
    { 0.62, cf(-0.05, 0.14, 0.02, 20, -10, -14) },
    { 0.74, cf(0.05, 0.05, 0.04, 8, 14, 16) },
    { 0.85, cf(0.04, 0.02, 0.11, 5, 12, 14) },
    { 1.00, I },
}

local RIFLE_MAG_TRACK = {
    { 0.00, I },
    { 0.18, I },
    { 0.38, cf(0, -0.82, 0.12, 10, 0, 0) },
    { 0.45, cf(-0.10, -1.60, 0.18, 12, 0, 0) },
    { 0.50, cf(0, -0.78, 0.10, 8, 0, 0) },
    { 0.62, I },
    { 1.00, I },
}

local RIFLE_BOLT_TRACK = {
    { 0.00, I },
    { 0.75, I },
    { 0.85, cf(0, 0, 0.32) },
    { 0.90, I },
    { 1.00, I },
}

local DETACH_MAG_SWAP = {
    { 0.00, 0 },
    { 0.20, 0.20 },
    { 0.38, 0.90 },
    { 0.48, 1.00 },
    { 0.60, 0.25 },
    { 0.74, 0 },
    { 1.00, 0 },
}

local BREAK_GUN_TRACK = {
    { 0.00, I },
    { 0.18, cf(-0.04, 0.04, 0.06, -24, 10, -18) },
    { 0.36, cf(-0.05, 0.02, 0.08, -26, 12, -20) },
    { 0.58, cf(-0.04, 0.04, 0.06, -22, 10, -18) },
    { 0.74, cf(-0.03, 0.04, 0.05, -18, 8, -12) },
    { 0.86, cf(0.00, 0.08, -0.02, 6, 0, 2) },
    { 1.00, I },
}

local BREAK_MAG_TRACK = {
    { 0.00, I },
    { 0.18, I },
    { 0.28, cf(0, 0.02, 0.48) },
    { 0.39, cf(-0.06, -0.75, 0.68) },
    { 0.48, cf(0, -0.55, 0.56) },
    { 0.62, cf(0, 0.02, 0.36) },
    { 0.73, I },
    { 1.00, I },
}

local BREAK_LATCH_TRACK = {
    { 0.00, I },
    { 0.12, rotD(0, 22, 0) },
    { 0.82, rotD(0, 22, 0) },
    { 0.88, I },
    { 1.00, I },
}

local PROFILES = {
    Rifle = {
        audioCues = { { 0.19, "MagOut" }, { 0.58, "MagIn" }, { 0.75, "BoltBack" }, { 0.87, "BoltForward" } },
        gunTrack = RIFLE_GUN_TRACK,
        leftArmTrack = {
            { 0.00, I },
            { 0.18, cf(0.05, -0.22, 0.88, 6, -10, 0) },
            { 0.36, cf(0.03, -0.92, 0.98, 12, -12, 0) },
            { 0.45, cf(-0.14, -1.55, 1.05, 18, 0, 0) },
            { 0.55, cf(0.03, -0.58, 0.94, 8, -8, 0) },
            { 0.63, cf(0.05, -0.20, 0.88, 6, -8, 0) },
            { 0.75, cf(-0.10, 0.24, 0.86, -8, 8, -8) },
            { 0.85, cf(-0.10, 0.22, 1.18, -10, 10, -8) },
            { 0.90, cf(-0.12, 0.18, 0.86, -4, 4, 0) },
            { 1.00, I },
        },
        magTrack = RIFLE_MAG_TRACK,
        boltTrack = RIFLE_BOLT_TRACK,
        leftDetachTrack = DETACH_MAG_SWAP,
        magHideWindow = { 0.39, 0.49 },
        shotMode = "Blowback",
    },
    SMG = {
        audioCues = { { 0.19, "MagOut" }, { 0.58, "MagIn" }, { 0.75, "BoltBack" }, { 0.87, "BoltForward" } },
        gunTrack = RIFLE_GUN_TRACK,
        leftArmTrack = {
            { 0.00, I },
            { 0.18, cf(0.04, -0.22, 0.58, 6, -10, 0) },
            { 0.36, cf(0.02, -0.90, 0.68, 12, -12, 0) },
            { 0.45, cf(-0.14, -1.50, 0.76, 18, 0, 0) },
            { 0.55, cf(0.03, -0.56, 0.64, 8, -8, 0) },
            { 0.63, cf(0.04, -0.20, 0.58, 6, -8, 0) },
            { 0.75, cf(-0.12, 0.24, 0.54, -8, 8, -8) },
            { 0.85, cf(-0.12, 0.22, 0.84, -10, 10, -8) },
            { 0.90, cf(-0.12, 0.18, 0.54, -4, 4, 0) },
            { 1.00, I },
        },
        magTrack = RIFLE_MAG_TRACK,
        boltTrack = RIFLE_BOLT_TRACK,
        leftDetachTrack = DETACH_MAG_SWAP,
        magHideWindow = { 0.39, 0.49 },
        shotMode = "Blowback",
    },
    Bulldog = {
        audioCues = { { 0.20, "MagOut" }, { 0.58, "MagIn" }, { 0.76, "BoltBack" }, { 0.88, "BoltForward" } },
        gunTrack = {
            { 0.00, I },
            { 0.18, cf(-0.14, 0.08, -0.18, 16, -24, -22) },
            { 0.32, cf(-0.14, 0.04, -0.16, 12, -24, -24) },
            { 0.58, cf(-0.10, 0.13, -0.16, 19, -20, -18) },
            { 0.74, cf(0.05, 0.06, 0.04, 8, 14, 15) },
            { 0.85, cf(0.04, 0.03, 0.10, 5, 12, 13) },
            { 1.00, I },
        },
        leftArmTrack = {
            { 0.00, I },
            { 0.20, cf(0.05, -0.24, 1.44, 10, -10, 0) },
            { 0.38, cf(0.02, -0.95, 1.50, 16, -12, 0) },
            { 0.46, cf(-0.14, -1.55, 1.56, 20, 0, 0) },
            { 0.56, cf(0.03, -0.58, 1.46, 10, -8, 0) },
            { 0.63, cf(0.05, -0.22, 1.42, 8, -8, 0) },
            { 0.75, cf(-0.14, 0.32, 0.24, -8, 8, -8) },
            { 0.85, cf(-0.14, 0.30, 0.56, -10, 10, -8) },
            { 0.90, cf(-0.14, 0.24, 0.24, -4, 4, 0) },
            { 1.00, I },
        },
        magTrack = RIFLE_MAG_TRACK,
        boltTrack = RIFLE_BOLT_TRACK,
        leftDetachTrack = DETACH_MAG_SWAP,
        magHideWindow = { 0.39, 0.49 },
        shotMode = "Blowback",
    },
    Pistol = {
        audioCues = { { 0.19, "MagOut" }, { 0.57, "MagIn" }, { 0.75, "BoltBack" }, { 0.87, "BoltForward" } },
        gunTrack = {
            { 0.00, I },
            { 0.18, cf(0.02, 0.08, 0.05, 18, -14, -24) },
            { 0.36, cf(0.01, 0.05, 0.06, 16, -14, -26) },
            { 0.58, cf(0.04, 0.14, 0.03, 22, -10, -20) },
            { 0.73, cf(0.05, 0.06, 0.04, 10, 12, 16) },
            { 0.84, cf(0.05, 0.03, 0.10, 6, 10, 14) },
            { 1.00, I },
        },
        leftArmTrack = {
            { 0.00, I },
            { 0.18, cf(-0.02, -0.14, 0.04, 8, 0, 0) },
            { 0.36, cf(-0.04, -0.78, 0.24, 16, 0, 0) },
            { 0.45, cf(-0.10, -1.42, 0.34, 22, 0, 0) },
            { 0.54, cf(-0.02, -0.48, 0.16, 10, 0, 0) },
            { 0.62, cf(0.01, -0.02, 0.02, 4, 0, 0) },
            { 0.74, cf(-0.02, 0.56, -0.24, -12, 10, -10) },
            { 0.84, cf(-0.02, 0.54, 0.08, -14, 12, -10) },
            { 0.89, cf(-0.04, 0.42, -0.20, -6, 6, 0) },
            { 1.00, I },
        },
        magTrack = {
            { 0.00, I },
            { 0.18, I },
            { 0.36, cf(0, -0.74, 0.22) },
            { 0.45, cf(-0.08, -1.35, 0.34) },
            { 0.52, cf(0, -0.62, 0.18) },
            { 0.61, I },
            { 1.00, I },
        },
        boltTrack = {
            { 0.00, I },
            { 0.74, I },
            { 0.84, cf(0, 0, 0.32) },
            { 0.89, I },
            { 1.00, I },
        },
        leftDetachTrack = DETACH_MAG_SWAP,
        magHideWindow = { 0.38, 0.48 },
        shotMode = "PistolSlide",
    },
    Sheriff = {
        audioCues = { { 0.09, "LatchOpen" }, { 0.26, "MagOut" }, { 0.60, "MagIn" }, { 0.83, "SnapShut" } },
        gunTrack = {
            { 0.00, I },
            { 0.16, cf(-0.04, 0.06, 0.05, 22, 12, -38) },
            { 0.26, cf(-0.06, 0.22, 0.08, 36, 12, -36) },
            { 0.42, cf(-0.04, 0.06, 0.05, 20, 14, -40) },
            { 0.62, cf(-0.04, 0.04, 0.08, 18, 14, -38) },
            { 0.78, cf(-0.02, 0.06, 0.04, 14, 8, -28) },
            { 0.85, cf(0.02, 0.08, 0.00, 6, -6, 12) },
            { 0.93, cf(0, 0.02, 0, 2, -2, -3) },
            { 1.00, I },
        },
        leftArmTrack = {
            { 0.00, I },
            { 0.16, cf(-0.22, -0.60, 0.35, 16, 0, 0) },
            { 0.36, cf(-0.24, -0.95, 0.25, 12, 0, 0) },
            { 0.46, cf(-0.22, 0.42, 0.14, -8, 12, 0) },
            { 0.60, cf(-0.22, 0.44, -0.14, -10, 14, 0) },
            { 0.72, cf(-0.26, -0.35, 0.18, 8, 6, 0) },
            { 0.86, cf(-0.08, -0.22, 0.10) },
            { 1.00, I },
        },
        magTrack = {
            { 0.00, cf(0, -0.80, 0.40) },
            { 0.36, cf(-0.04, -0.65, 0.34) },
            { 0.48, cf(-0.04, -0.02, 0.06) },
            { 0.60, cf(-0.04, -0.02, -0.22) },
            { 0.72, cf(-0.06, -0.45, 0.22) },
            { 1.00, cf(0, -0.80, 0.40) },
        },
        boltTrack = {
            { 0.00, I },
            { 0.08, pivotRot(Vector3.new(0, 0.12, 0.34), -18, 0, 0) },
            { 0.82, pivotRot(Vector3.new(0, 0.12, 0.34), -18, 0, 0) },
            { 0.90, I },
            { 1.00, I },
        },
        cylinderSwingTrack = {
            { 0.00, 0 }, { 0.08, 0 }, { 0.18, 88 }, { 0.76, 88 }, { 0.84, 0 }, { 1.00, 0 },
        },
        cylinderSpinTrack = {
            { 0.00, 0 }, { 0.20, 0 }, { 0.42, 240 }, { 0.76, 240 }, { 1.00, 240 },
        },
        leftDetachTrack = { { 0.00, 0 }, { 0.14, 0.8 }, { 0.74, 0.9 }, { 0.90, 0 }, { 1.00, 0 } },
        reloadOnlyShowWindows = { { 0.36, 0.72 } },
        shotMode = "Revolver",
    },
    Bucky = {
        audioCues = { { 0.12, "MagOut" }, { 0.29, "ShellIn" }, { 0.52, "ShellIn" }, { 0.74, "BoltBack" }, { 0.85, "BoltForward" } },
        gunTrack = {
            { 0.00, I },
            { 0.16, cf(0.08, 0.10, 0.04, 14, -14, -30) },
            { 0.30, cf(0.08, 0.13, 0.03, 16, -14, -28) },
            { 0.42, cf(0.08, 0.09, 0.04, 14, -14, -30) },
            { 0.54, cf(0.08, 0.13, 0.03, 16, -14, -28) },
            { 0.68, cf(0.02, 0.04, 0.02, 6, -4, -10) },
            { 0.76, cf(0.00, -0.02, 0.08, -3, 0, -4) },
            { 0.86, cf(0.00, 0.02, -0.03, 4, 0, 0) },
            { 1.00, I },
        },
        leftArmTrack = {
            { 0.00, I },
            { 0.18, cf(0.02, -0.58, 1.04, 12, -8, 0) },
            { 0.29, cf(0.04, -0.08, 1.00, 4, -8, 0) },
            { 0.41, cf(0.00, -0.62, 1.08, 14, -6, 0) },
            { 0.53, cf(0.04, -0.08, 1.00, 4, -8, 0) },
            { 0.66, I },
            { 0.76, cf(0, 0, 0.42) },
            { 0.85, I },
            { 1.00, I },
        },
        magTrack = {
            { 0.00, cf(0, -0.55, 0.10) },
            { 0.20, cf(0, -0.52, 0.12) },
            { 0.31, cf(0, 0.16, -0.06) },
            { 0.40, cf(0, 0.22, -0.14) },
            { 0.43, cf(0, -0.55, 0.12) },
            { 0.54, cf(0, 0.16, -0.06) },
            { 0.63, cf(0, 0.22, -0.14) },
            { 1.00, cf(0, -0.55, 0.10) },
        },
        boltTrack = {
            { 0.00, I }, { 0.68, I }, { 0.76, cf(0, 0, 0.42) }, { 0.85, I }, { 1.00, I },
        },
        pumpTrack = {
            { 0.00, I }, { 0.68, I }, { 0.76, cf(0, 0, 0.42) }, { 0.85, I }, { 1.00, I },
        },
        leftDetachTrack = {
            { 0.00, 0 }, { 0.16, 0.75 }, { 0.42, 0.85 }, { 0.64, 0.15 }, { 0.68, 0 }, { 1.00, 0 },
        },
        reloadOnlyShowWindows = { { 0.20, 0.40 }, { 0.44, 0.63 } },
        shotMode = "Pump",
    },
    Shorty = {
        audioCues = { { 0.09, "LatchOpen" }, { 0.25, "MagOut" }, { 0.50, "ShellIn" }, { 0.66, "ShellIn" }, { 0.85, "SnapShut" } },
        gunTrack = BREAK_GUN_TRACK,
        leftArmTrack = {
            { 0.00, I },
            { 0.22, cf(-0.04, 0.16, -0.20, -10, 0, 0) },
            { 0.38, cf(-0.08, -0.82, 0.32, 16, 0, 0) },
            { 0.50, cf(-0.04, 0.04, 0.06, -4, 0, 0) },
            { 0.70, cf(-0.02, 0.22, -0.22, -10, 0, 0) },
            { 0.84, cf(0.00, -0.02, 0.02) },
            { 1.00, I },
        },
        magTrack = BREAK_MAG_TRACK,
        boltTrack = BREAK_LATCH_TRACK,
        leftDetachTrack = DETACH_MAG_SWAP,
        magHideWindow = { 0.39, 0.47 },
        shotMode = "Break",
    },
    Outlaw = {
        audioCues = { { 0.09, "LatchOpen" }, { 0.25, "MagOut" }, { 0.50, "ShellIn" }, { 0.66, "ShellIn" }, { 0.85, "SnapShut" } },
        gunTrack = BREAK_GUN_TRACK,
        leftArmTrack = {
            { 0.00, I },
            { 0.22, cf(-0.02, 0.12, 0.82, -10, 0, 0) },
            { 0.38, cf(-0.08, -0.78, 1.05, 16, 0, 0) },
            { 0.52, cf(-0.04, -0.10, 0.92, 0, 0, 0) },
            { 0.70, cf(-0.02, 0.16, 0.78, -8, 0, 0) },
            { 0.85, cf(0, 0, 0.10) },
            { 1.00, I },
        },
        magTrack = BREAK_MAG_TRACK,
        boltTrack = BREAK_LATCH_TRACK,
        leftDetachTrack = DETACH_MAG_SWAP,
        magHideWindow = { 0.39, 0.47 },
        shotMode = "Break",
    },
    BeltFed = {
        audioCues = { { 0.11, "LatchOpen" }, { 0.26, "MagOut" }, { 0.58, "MagIn" }, { 0.73, "SnapShut" }, { 0.82, "BoltBack" }, { 0.91, "BoltForward" } },
        gunTrack = {
            { 0.00, I },
            { 0.16, cf(-0.06, 0.05, 0.06, 10, -10, -12) },
            { 0.36, cf(-0.10, -0.04, 0.08, 6, -16, -22) },
            { 0.62, cf(-0.06, 0.08, 0.05, 14, -14, -18) },
            { 0.75, cf(0.00, 0.02, 0.03, -6, 4, 4) },
            { 0.85, cf(0.04, 0.02, 0.08, 4, 8, 8) },
            { 1.00, I },
        },
        leftArmTrack = {
            { 0.00, I },
            { 0.14, cf(-0.04, 0.52, 0.58, -14, 0, 0) },
            { 0.38, cf(-0.16, -0.95, 0.90, 12, -10, 0) },
            { 0.46, cf(-0.18, -1.55, 0.98, 18, 0, 0) },
            { 0.62, cf(-0.10, -0.28, 0.88, 6, -8, 0) },
            { 0.74, cf(-0.04, 0.48, 0.58, -10, 0, 0) },
            { 0.83, cf(0.10, 0.22, 0.95, -6, 8, 0) },
            { 0.90, cf(0.10, 0.20, 1.24, -8, 10, 0) },
            { 1.00, I },
        },
        magTrack = {
            { 0.00, I },
            { 0.20, I },
            { 0.38, cf(-0.18, -0.95, 0.10, 0, 0, 12) },
            { 0.46, cf(-0.24, -1.65, 0.14) },
            { 0.52, cf(-0.14, -0.82, 0.08) },
            { 0.63, I },
            { 1.00, I },
        },
        boltTrack = {
            { 0.00, I },
            { 0.15, pivotRot(Vector3.new(0, 0.32, -0.52), -50, 0, 0) },
            { 0.68, pivotRot(Vector3.new(0, 0.32, -0.52), -50, 0, 0) },
            { 0.76, I },
            { 1.00, I },
        },
        leftDetachTrack = { { 0.00, 0 }, { 0.20, 0.3 }, { 0.42, 1.0 }, { 0.66, 0.2 }, { 0.80, 0 }, { 1.00, 0 } },
        magHideWindow = { 0.39, 0.49 },
        shotMode = "HeavyRattle",
    },
    Marshal = {
        audioCues = { { 0.10, "LatchOpen" }, { 0.34, "ShellIn" }, { 0.56, "ShellIn" }, { 0.82, "SnapShut" } },
        gunTrack = {
            { 0.00, I },
            { 0.16, cf(-0.06, 0.08, 0.06, 16, -18, -22) },
            { 0.56, cf(-0.06, 0.10, 0.06, 18, -18, -22) },
            { 0.82, cf(0.02, 0.06, 0.00, 4, 4, 8) },
            { 1.00, I },
        },
        leftArmTrack = {
            { 0.00, I },
            { 0.22, cf(0.16, -0.45, 1.05, 12, -14, 0) },
            { 0.35, cf(0.14, 0.06, 1.08, 4, -14, 0) },
            { 0.47, cf(0.16, -0.48, 1.05, 12, -14, 0) },
            { 0.58, cf(0.14, 0.06, 1.08, 4, -14, 0) },
            { 0.76, I },
            { 1.00, I },
        },
        magTrack = {
            { 0.00, cf(0.24, -0.20, 0.12) },
            { 0.24, cf(0.22, -0.16, 0.10) },
            { 0.36, cf(-0.02, 0, 0) },
            { 0.42, cf(-0.12, 0, -0.08) },
            { 0.46, cf(0.22, -0.16, 0.10) },
            { 0.58, cf(-0.02, 0, 0) },
            { 0.65, cf(-0.12, 0, -0.08) },
            { 1.00, cf(0.24, -0.20, 0.12) },
        },
        boltTrack = {
            { 0.00, I },
            { 0.16, pivotRot(Vector3.new(0, -0.14, 0.04), 48, 0, 0) },
            { 0.74, pivotRot(Vector3.new(0, -0.14, 0.04), 48, 0, 0) },
            { 0.84, I },
            { 1.00, I },
        },
        leftDetachTrack = { { 0.00, 0 }, { 0.18, 0.8 }, { 0.66, 0.8 }, { 0.80, 0 }, { 1.00, 0 } },
        reloadOnlyShowWindows = { { 0.24, 0.43 }, { 0.48, 0.66 } },
        shotMode = "Lever",
    },
    Operator = {
        audioCues = { { 0.19, "MagOut" }, { 0.58, "MagIn" }, { 0.75, "BoltBack" }, { 0.87, "BoltForward" } },
        gunTrack = RIFLE_GUN_TRACK,
        leftArmTrack = {
            { 0.00, I },
            { 0.18, cf(0.05, -0.22, 0.92, 6, -10, 0) },
            { 0.36, cf(0.03, -0.92, 1.02, 12, -12, 0) },
            { 0.45, cf(-0.14, -1.55, 1.10, 18, 0, 0) },
            { 0.55, cf(0.03, -0.58, 0.98, 8, -8, 0) },
            { 0.63, cf(0.05, -0.20, 0.92, 6, -8, 0) },
            { 0.75, cf(-0.10, 0.24, 0.90, -8, 8, -8) },
            { 0.85, cf(-0.10, 0.22, 1.24, -10, 10, -8) },
            { 0.90, cf(-0.12, 0.18, 0.90, -4, 4, 0) },
            { 1.00, I },
        },
        magTrack = RIFLE_MAG_TRACK,
        boltTrack = {
            { 0.00, I },
            { 0.72, I },
            { 0.76, pivotRot(Vector3.new(0.15, 0.16, 0.42), 0, 0, 42) },
            { 0.85, cf(0, 0, 0.38) * pivotRot(Vector3.new(0.15, 0.16, 0.42), 0, 0, 42) },
            { 0.92, I },
            { 1.00, I },
        },
        leftDetachTrack = DETACH_MAG_SWAP,
        magHideWindow = { 0.39, 0.49 },
        shotMode = "BoltAction",
    },
}

WeaponPoseSolver.PROFILES = PROFILES

function WeaponPoseSolver.newState()
    return {
        lastShotTime = -10,
        cylinderIndex = 0,
        currentCylinderAngle = 0,
        inspectTimer = 0,
        gunAnimCF = CFrame.identity,
        leftArmAnimCF = CFrame.identity,
        leftDetachAlpha = 0,
    }
end

function WeaponPoseSolver.resetState(state)
    state.lastShotTime = -10
    state.cylinderIndex = 0
    state.currentCylinderAngle = 0
    state.inspectTimer = 0
    state.gunAnimCF = CFrame.identity
    state.leftArmAnimCF = CFrame.identity
    state.leftDetachAlpha = 0
end

function WeaponPoseSolver.getProfile(weaponCfg)
    local wName = (weaponCfg and weaponCfg.Name or ""):upper()
    local wType = weaponCfg and weaponCfg.Type or "Rifle"
    if PROFILES[wName] then
        return PROFILES[wName]
    elseif wName == "BUCKY" then
        return PROFILES.Bucky
    elseif wName == "SHERIFF" then
        return PROFILES.Sheriff
    elseif wName == "SHORTY" then
        return PROFILES.Shorty
    elseif wName == "OUTLAW" then
        return PROFILES.Outlaw
    elseif wName == "BULLDOG" then
        return PROFILES.Bulldog
    elseif wName == "MARSHAL" then
        return PROFILES.Marshal
    elseif wName == "OPERATOR" then
        return PROFILES.Operator
    elseif wName == "ARES" or wName == "ODIN" then
        return PROFILES.BeltFed
    elseif wType == "Pistol" or wType == "Revolver" then
        return PROFILES.Pistol
    elseif wType == "SMG" then
        return PROFILES.SMG
    end
    return PROFILES.Rifle
end

function WeaponPoseSolver.evalEquipPose(prog)
    return evalCFTrack(EQUIP_GUN_TRACK, prog), evalCFTrack(EQUIP_LEFT_TRACK, prog)
end

function WeaponPoseSolver.evalUnequipPose(prog)
    return evalCFTrack(UNEQUIP_GUN_TRACK, prog), evalCFTrack(UNEQUIP_LEFT_TRACK, prog)
end

function WeaponPoseSolver.solve(animState, dt, weaponCfg, reloadActive, reloadProg, inspectActive, isAimActive, isSprintActive, nowClock)
    local profile = WeaponPoseSolver.getProfile(weaponCfg)
    local targetGunCF, targetLeftArmCF = I, I
    local magCF, boltCF, pumpCF, cylinderCF = I, I, I, I
    local targetDetachAlpha = 0
    local showMag = true
    local showReloadOnly = false
    local inspectFinished = false

    local targetCylDeg = animState.cylinderIndex * 60
    local cylLerp = math.clamp(dt * 24, 0, 1)
    animState.currentCylinderAngle = animState.currentCylinderAngle + (targetCylDeg - animState.currentCylinderAngle) * cylLerp

    local now = nowClock or os.clock()
    local dtShot = now - animState.lastShotTime
    local shotMode = profile.shotMode
    if dtShot >= 0 then
        if shotMode == "Blowback" or shotMode == "PistolSlide" then
            if dtShot < 0.095 then
                local p = dtShot / 0.095
                local back = (p < 0.28) and (p / 0.28) or (1 - (p - 0.28) / 0.72)
                boltCF = CFrame.new(0, 0, (shotMode == "PistolSlide" and 0.28 or 0.22) * smooth01(back))
            end
        elseif shotMode == "Pump" then
            if dtShot > 0.14 and dtShot < 0.44 then
                local s = math.sin(((dtShot - 0.14) / 0.30) * math.pi)
                local travel = 0.42 * smooth01(s)
                pumpCF = CFrame.new(0, 0, travel)
                boltCF = CFrame.new(0, 0, travel)
                targetLeftArmCF = CFrame.new(0, 0, travel)
                targetGunCF = cf(0, -0.015 * s, 0.05 * s, -2.5 * s, 0, -3 * s)
            end
        elseif shotMode == "BoltAction" then
            if dtShot > 0.15 and dtShot < 0.62 then
                local u = (dtShot - 0.15) / 0.47
                local lift = (u < 0.22) and smooth01(u / 0.22) or ((u > 0.78) and smooth01((1 - u) / 0.22) or 1)
                local pull = (u > 0.20 and u < 0.80) and math.sin(((u - 0.20) / 0.60) * math.pi) or 0
                boltCF = cf(0, 0, 0.38 * smooth01(pull)) * pivotRot(Vector3.new(0.15, 0.16, 0.42), 0, 0, 42 * lift)
                targetGunCF = cf(0.02 * lift, 0.02 * lift, 0.04 * pull, 3 * lift, -4 * lift, -6 * lift)
            end
        elseif shotMode == "Lever" then
            if dtShot > 0.14 and dtShot < 0.50 then
                local s = math.sin(((dtShot - 0.14) / 0.36) * math.pi)
                boltCF = pivotRot(Vector3.new(0, -0.14, 0.04), 44 * smooth01(s), 0, 0)
                targetGunCF = cf(0, 0.015 * s, 0.03 * s, 4 * s, 0, -4 * s)
            end
        elseif shotMode == "Revolver" then
            if dtShot < 0.08 then
                local s = math.sin((dtShot / 0.08) * math.pi)
                boltCF = pivotRot(Vector3.new(0, 0.12, 0.34), -32 * s, 0, 0)
            end
        elseif shotMode == "HeavyRattle" then
            if dtShot < 0.07 then
                local s = math.sin((dtShot / 0.07) * math.pi)
                boltCF = cf(0, 0.015 * s, 0)
            end
        end
    end

    local cylSwingDeg, cylReloadSpinDeg = 0, 0
    if reloadActive then
        local p = math.clamp(reloadProg, 0, 1)
        targetGunCF = evalCFTrack(profile.gunTrack, p)
        targetLeftArmCF = evalCFTrack(profile.leftArmTrack, p)
        magCF = evalCFTrack(profile.magTrack, p)
        boltCF = evalCFTrack(profile.boltTrack, p)
        pumpCF = evalCFTrack(profile.pumpTrack, p)
        targetDetachAlpha = evalScalarTrack(profile.leftDetachTrack, p)

        if profile.magHideWindow and windowContains(profile.magHideWindow, p) then
            showMag = false
        end
        if profile.reloadOnlyShowWindows then
            for _, win in ipairs(profile.reloadOnlyShowWindows) do
                if windowContains(win, p) then
                    showReloadOnly = true
                    break
                end
            end
        end
        if profile.cylinderSwingTrack then
            cylSwingDeg = evalScalarTrack(profile.cylinderSwingTrack, p)
        end
        if profile.cylinderSpinTrack then
            cylReloadSpinDeg = evalScalarTrack(profile.cylinderSpinTrack, p)
        end
    elseif inspectActive and not isAimActive and not isSprintActive then
        animState.inspectTimer = animState.inspectTimer + dt
        if animState.inspectTimer >= WeaponPoseSolver.INSPECT_DURATION then
            animState.inspectTimer = 0
            inspectFinished = true
        else
            local ip = animState.inspectTimer / WeaponPoseSolver.INSPECT_DURATION
            targetGunCF = evalCFTrack(INSPECT_GUN_TRACK, ip)
            targetLeftArmCF = evalCFTrack(INSPECT_LEFT_TRACK, ip)
        end
    end

    local totalSpinRad = math.rad(animState.currentCylinderAngle + cylReloadSpinDeg)
    local spinCF = CFrame.new(0, 0.05, -0.15) * CFrame.Angles(0, 0, totalSpinRad) * CFrame.new(0, -0.05, 0.15)
    if math.abs(cylSwingDeg) > 0.01 then
        local swingCF = pivotRot(Vector3.new(-0.16, -0.11, -0.15), 0, 0, cylSwingDeg)
        cylinderCF = swingCF * spinCF
    elseif totalSpinRad ~= 0 then
        cylinderCF = spinCF
    end

    local blendRate = math.clamp(dt * (reloadActive and 26 or 18), 0, 1)
    animState.gunAnimCF = animState.gunAnimCF:Lerp(targetGunCF, blendRate)
    animState.leftArmAnimCF = animState.leftArmAnimCF:Lerp(targetLeftArmCF, blendRate)
    animState.leftDetachAlpha = animState.leftDetachAlpha + (targetDetachAlpha - animState.leftDetachAlpha) * blendRate

    return animState.gunAnimCF,
        animState.leftArmAnimCF,
        animState.leftDetachAlpha,
        magCF,
        boltCF,
        pumpCF,
        cylinderCF,
        showMag,
        showReloadOnly,
        inspectFinished
end

return WeaponPoseSolver
