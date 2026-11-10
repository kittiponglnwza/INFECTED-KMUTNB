# Baseline Audit — 2026-11-11

Repository: `kittiponglnwza/INFECTED-KMUTNB`  
Branch: `main`  
Audit scope: tracked source files and Rojo project mapping. This is a source-level audit; Roblox Studio runtime behavior has not been executed in this environment.

## 1. Current active project structure

The active Rojo project maps these systems into the place:

- `src/server/map/**` → `ServerScriptService/Map`
- `src/server/gameplay/WaveAndZombieManager.server.lua` → `ServerScriptService/WaveAndZombieManager`
- `src/server/gameplay/DownedAndReviveManager.server.lua` → `ServerScriptService/DownedAndReviveManager`
- `src/server/gameplay/BarricadeManager.server.lua` → `ServerScriptService/BarricadeManager`
- `src/client/controllers/FPSController.client.lua` → `StarterPlayer/StarterPlayerScripts/FPSController`
- `src/client/weapons/**` → `StarterPlayer/StarterPlayerScripts/Weapons`

Prototype folders are not present in the active Rojo mapping.

## 2. Existing systems found

| Area | Source | Audit status |
|---|---|---|
| Building generation | `src/server/map/Building40Master.server.lua` + map modules | Present; builds floors and exterior |
| FPS controller | `src/client/controllers/FPSController.client.lua` | Present |
| Weapon registry/configs/models/audio/optics/buy menu | `src/client/weapons/**` | Present |
| Zombie AI, damage, waves, scoreboard, weapon purchase | `src/server/gameplay/WaveAndZombieManager.server.lua` | Present |
| Downed and revive | `src/server/gameplay/DownedAndReviveManager.server.lua` | Present |
| Barricade repair | `src/server/gameplay/BarricadeManager.server.lua` | Present |
| Mission/objective progression | No active implementation found | Missing |
| Keycard/inventory progression | No active implementation found | Missing |
| CCTV/safe/radio puzzles | No active implementation found | Missing |
| Generator/power progression | No active implementation found | Missing |
| Helicopter extraction/endings | No active implementation found | Missing |

## 3. Important implementation observations

These are source-level observations to verify and address in dedicated gameplay-hardening work; they are not silently changed in this mission-system phase.

1. `WaveAndZombieManager.server.lua` starts an automatic, endless wave loop. A mission campaign will need a deliberate relationship with this loop (campaign mode, wave pause, or objective-driven spawn director) before full mission pacing is implemented.
2. The same script initializes `IsAdminGodMode` to `true` when the attribute is unset. This appears to grant god mode by default to ordinary players and should be reviewed separately before public multiplayer testing.
3. Zombie damage currently accepts damage values and headshot state from a client RemoteEvent, then clamps the submitted damage. Weapon damage validation should be hardened separately.
4. The revive script creates a ProximityPrompt on a downed player, but source review should verify lifecycle and concurrent revive behavior in Studio.
5. The barricade script stores a function in a Model attribute (`DamageBarricade`). Roblox attributes support serializable values, not Lua functions; verify this interaction path and refactor to a server-side table/module if it is relied upon.
6. The current map builder recreates the building model at startup. Mission interactables must be added by map modules or by a post-build setup step, not placed in a transient Workspace instance that the builder deletes.

## 4. Phase plan based on the actual baseline

- **Phase 0 — Baseline audit:** completed by this document.
- **Phase 1 — Mission foundation:** add server-authoritative mission state and replicated objective HUD without replacing wave, weapon, revive, or barricade systems.
- **Phase 2 — First vertical slice:** add one real, map-grounded objective interaction (security access / CCTV clue) and test it end-to-end.
- **Phase 3 — Power and puzzles:** fuses, generator, safe, and radio puzzles.
- **Phase 4 — Extraction:** rooftop route, beacon, defense countdown, helicopter, and ending evaluation.
- **Phase 5 — Balance and atmosphere:** coordinate wave pressure with campaign progression, tune resources and add story beats.
- **Phase 6 — Release readiness:** multiplayer, exploit, respawn, disconnect, late-join, performance, and soft-lock tests.

## 5. Verification limits

- Repository files and `default.project.json` were inspected through GitHub.
- No Roblox Studio session, live server, or Rojo build executable is available in this repository connector session.
- Therefore no claim is made that the place has been launched or playtested. Runtime validation remains a required acceptance step.
