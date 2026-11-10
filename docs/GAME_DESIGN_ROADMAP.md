# INFECTED: KMUTNB — Game Design & Development Roadmap

> Development plan for the mission-driven co-op zombie survival game set around KMUTNB Building 40. This document describes the intended direction; it is not a claim that every listed system is already implemented.

## 1. Game vision

**Core experience:** players begin trapped inside the infected building, survive escalating zombie attacks, explore locked areas, restore critical systems, solve environmental puzzles, and reach the rooftop for helicopter extraction.

**Design pillars**
- Exploration with purpose: every room, key, clue, and system supports the escape objective.
- Survival pressure: ammunition, health, time, noise, and team coordination matter.
- Puzzle under threat: players investigate and solve problems while defending themselves.
- Co-op roles: players can split tasks, cover teammates, revive, and share scarce resources.
- Consequences: optional rooms and discoveries can improve the team's odds or unlock alternate outcomes.

## 2. Main mission flow

| Stage | Objective | Main reward / unlock |
|---|---|---|
| M0 — Initial lockdown | Survive the opening attack and regroup | Access to the first safe area |
| M1 — Security room | Find an access card, restore CCTV, identify the correct access code | Security access and building information |
| M2 — Power room | Find missing fuses and restart the generator | Electricity, selected doors, lights and systems |
| M3 — Records / research | Search documents and solve the safe puzzle | Master keycard or rooftop access clue |
| M4 — Communications | Restore radio power and determine the rescue frequency | Helicopter extraction request |
| M5 — Roof access | Unlock the final route and reach the roof | Extraction zone |
| M6 — Extraction | Activate the beacon and defend the landing zone | Ending determined by team outcome |

The sequence may be adjusted during implementation if the current map layout or technical constraints require it.

## 3. Mission specifications

### M0 — Initial lockdown
- Start with a short environmental intro: alarms, emergency lighting, blocked exits, and the first zombie breach.
- Teach movement, aiming, reloading, interaction, barricading, and revive through play rather than long tutorials.
- Objective: survive until the team can enter the first secure area.
- Completion: at least one route to the security objective becomes available.

### M1 — Security room
- Search nearby offices or reception areas for a security access card.
- Restore the CCTV terminal.
- Present several camera snapshots or event records with timestamps.
- Players must order events correctly to derive a door code.
- Reward: access to the security-controlled route and clues about the power-room location.

### M2 — Power room
- Search multiple rooms for required fuses or circuit components.
- Insert components into the correct slots.
- Puzzle should communicate circuit state clearly: missing fuse, incorrect connection, overloaded circuit, or success.
- Restart the generator using a deliberate interaction sequence.
- Consequence: selected lights, doors, CCTV, elevators, or terminals become available. Power should not automatically solve every obstacle.

### M3 — Records / research room
- Collect several documents, notes, or incident reports.
- Cross-reference names, dates, room numbers, or symbols to infer a safe combination.
- Safe puzzle should have multiple steps and provide enough evidence to solve fairly; avoid arbitrary guessing.
- Reward: master keycard, rooftop access information, or a useful optional weapon/resource.

### M4 — Communications room
- Find a portable battery or repair a damaged radio power supply.
- Tune a frequency using clues found earlier (for example, a frequency written in a maintenance log).
- Send a distress call and wait for confirmation.
- Optional complication: the radio attracts a horde or triggers a timed defense.

### M5 — Roof access
- Use the master keycard and restore any required access mechanism.
- Make the route to the roof a final traversal/combat challenge.
- Give the team a clear point of no return or a clear warning before starting extraction.

### M6 — Rooftop extraction
- Activate the rescue beacon.
- Defend the landing zone for a countdown while enemies attack from multiple approach paths.
- Spawn a special threat or boss variant near the final phase, with readable telegraphs and counterplay.
- Helicopter arrives only after the defense objective is complete.
- Players must reach and board the helicopter to finish.

## 4. Puzzle design rules

- Every answer must be discoverable from in-world clues; no random code guessing.
- Use at least two clue sources for major puzzles, so one missed note does not soft-lock the run.
- Provide feedback for wrong attempts without revealing the full answer.
- Add escalating pressure (noise, enemy waves, limited safe time), not unexplained instant failure.
- Support co-op: clues can be distributed across rooms, but avoid requiring every player to be present at one terminal.
- Keep puzzle state authoritative on the server to prevent client-side exploits.

**Candidate puzzle types**
1. CCTV chronology: order events by timestamp, then read the resulting digits.
2. Circuit restoration: locate components and connect them according to a wiring diagram.
3. Safe combination: combine document clues such as room number, incident date, and a marked sequence.
4. Radio tuning: infer the frequency from maintenance notes, then tune within a tolerance window.

## 5. Locked rooms and rewards

Each locked room should have a clear purpose and a meaningful reward. Examples:
- Security room: camera access, door controls, and route clues.
- Power room: generator control and access to powered systems.
- Records room: safe, master keycard, and story clues.
- Medical room: limited healing supplies or revive support.
- Armory / storage: ammunition, weapon options, or barricade materials.
- Communications room: rescue request and extraction timer.

Avoid locking essential progression behind a purely optional room. Optional rooms should improve survivability, reveal lore, or unlock alternate endings.

## 6. Threat, time, and resources

- Escalate enemy pressure as players make noise, restore systems, or spend too long in exposed areas.
- Use distinct enemy roles (for example: standard Walker, fast Sprinter, heavy Tank, low-profile Crawler, and group attacks from elevator/stair routes).
- Preserve readable attack cues and fair hit detection.
- Balance ammunition and healing so resource decisions matter without making a run unwinnable after one mistake.
- Ensure downed/revive mechanics remain useful during objective interactions and extraction.

## 7. Endings

- **Successful Extraction:** team completes the rescue call, activates the beacon, survives, and boards.
- **Partial Extraction:** only some players reach the helicopter before the final window closes.
- **No Signal / Failed Extraction:** the team fails to restore communications or defend the landing zone.

Endings should be driven by recorded game state, not a random roll. Optional objectives may influence who survives or what information is revealed.

## 8. UI / player feedback

- Keep one primary objective visible at a time, with optional objectives visually separated.
- Show interaction prompts only when the player is in range and the action is available.
- Give clear feedback for locked doors (missing keycard, no power, objective incomplete).
- Puzzle interfaces should show state and input feedback, not just a blank code box.
- In co-op, communicate objective progress to all players and show who activated major systems.

## 9. Suggested system boundaries

Implement only when the current codebase needs them; first inspect existing modules and reuse working systems.

### Server
- MissionService: authoritative mission state and objective progression.
- InteractionService: validate player distance, target, and interaction availability.
- DoorService: door state, access requirements, and unlock conditions.
- ItemService: keycards, fuses, batteries, clues, and inventory rules.
- PuzzleService: validate puzzle solutions and persist puzzle state.
- PowerService: generator and powered-device state.
- ThreatDirector: wave pressure and objective-triggered enemy escalation.
- ExtractionService: radio request, beacon, countdown, helicopter, and ending state.

### Client
- MissionController: objective display and mission notifications.
- InteractionController: contextual prompts and interaction input.
- PuzzleController: puzzle UI and local input handling.
- ExtractionController: beacon and extraction feedback.

**Authority rule:** clients may request actions, but the server validates and commits mission, inventory, door, puzzle, damage, and extraction state.

## 10. Development phases

### Phase 0 — Baseline audit — DONE (source review)
- Confirmed the active Rojo entry point and mapped scripts.
- Recorded existing weapon, zombie, wave, barricade, revive, and map systems.
- Documented missing mission/puzzle/extraction systems and source-level risks in `docs/BASELINE_AUDIT.md`.
- Runtime behavior still requires Roblox Studio verification.

### Phase 1 — Mission foundation — IMPLEMENTED (runtime test pending)
- Added `src/server/gameplay/MissionService.server.lua` with a server-owned seven-step campaign objective sequence.
- Added a ServerStorage BindableEvent (`MissionSignals/CompleteObjective`) for trusted server scripts to complete only the current objective in order.
- Added read-only state replication and a client request event; clients cannot directly complete objectives.
- Added `src/client/controllers/MissionController.client.lua` to display the current objective and progress.
- Registered both scripts in `default.project.json`.
- Studio tests for late join, respawn, and multiplayer replication remain pending.

### Phase 2 — Access and exploration — TODO (next)

- Add keycards, locked doors, and room-specific access feedback.
- Connect security-room progression to the mission state.
- Test invalid interaction, duplicate interaction, and multiple players interacting simultaneously.

### Phase 3 — Power and puzzles
- Add fuse collection and generator state.
- Implement CCTV, safe, and radio puzzles as separate reusable puzzle types.
- Keep clue data configurable and validate answers on the server.

### Phase 4 — Rescue and extraction
- Add radio request, beacon activation, defense countdown, helicopter arrival, and boarding.
- Add ending evaluation for full, partial, and failed extraction.

### Phase 5 — Balance and atmosphere
- Tune enemy spawn pressure, ammunition, healing, lighting, sound, and objective pacing.
- Add environmental storytelling and optional rooms only after the core route works.

### Phase 6 — Release readiness
- Run full co-op playtests with low and high player counts.
- Test exploit attempts, soft-locks, respawns, disconnects, and late joins.
- Profile performance and remove unused prototype content from the active place.

## 11. Definition of done

A mission is complete when:
- Its objective is understandable without developer instructions.
- All required clues and items can be found in a normal run.
- Server validation prevents duplicate or unauthorized completion.
- Failure and retry states behave correctly.
- All players receive consistent mission progress.
- The mission cannot soft-lock due to a single missed clue, death, or disconnect.

## 12. Immediate next tasks

1. Audit the current active scripts and map; mark each relevant system as implemented, partial, prototype, or missing.
2. Choose the first vertical slice: security room → CCTV clue → access door.
3. Implement and test that slice end-to-end before building every puzzle at once.
4. Update this roadmap with actual status after each milestone.

## 13. Building 40 map reconstruction status (2026-11-11)

The map reconstruction is being tracked separately from the mission phases because it changes the shared environment used by every gameplay system.

### Phase 1 — Campus grounds — PARTIAL (source updated; Studio verification pending)
- Replaced the invented four-sided ring road, east-side car park, west-side motorcycle shelter, and front flag plaza with a restrained campus context.
- Added a front pedestrian approach, canal-side edge, green pedestrian bridge, Suan Palm garden zone, and low-detail engineering-side context mass.
- Ground is split around the canal so the water is visible; bridge and water elevations are staged for a walkable crossing.
- Coordinates are gameplay-scale approximations, not surveyed campus dimensions. Exact canal width, bridge location, garden boundaries, and neighboring building footprints still need measurement against a high-resolution campus plan or in-game reference images.

### Phase 2 — Building shape and exterior — PARTIAL (source updated; dimensions not verified)
- Kept the existing shared 300 x 240 stud footprint and 22-stud floor height so the already-built floor modules remain aligned.
- Explicitly marked these as inherited gameplay-scale values, not real architectural measurements.
- Aligned legacy `PartBuilder` geometry constants with the active `Building40Layout` constants to prevent two conflicting dimension systems.
- Shifted the exterior palette toward the cream/orange appearance visible in the available exterior photograph and removed unsupported roof signs on the east and west sides.
- The building footprint, floor-to-floor height, façade bay spacing, exact window pattern, roof plant rooms, and sign placement still require comparison with multi-angle photographs or an architectural drawing.

### Evidence used
- KMUTNB campus map: https://building.op.kmutnb.ac.th/upload/froala/MAP160x160.jpg
- Official campus 3D navigation-map article: https://green.kmutnb.ac.th/news/view?id=11
- TGGS 2025 student handbook (campus map and walking directions to Building 77): https://tggs.kmutnb.ac.th/wp-content/uploads/2025/07/TGGS_Undergraduate-Student_Handbook_2025-1.pdf
- Exterior photo and cafeteria photo reference: https://coe.or.th/wp-content/uploads/2025/05/16.-%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B8%9A%E0%B8%B4%E0%B8%99%E0%B9%81%E0%B8%A5%E0%B8%B0%E0%B8%AD%E0%B8%A7%E0%B8%81%E0%B8%B2%E0%B8%A8%E0%B8%99%E0%B8%B2%E0%B8%99%E0%B8%B2%E0%B8%95%E0%B8%B466%E0%B8%A1%E0%B8%88%E0%B8%9E.pdf
- KMUTNB Student Affairs sports-facility page (floors 3, 7, and 12): https://sites.google.com/op.kmutnb.ac.th/kmutnbstuact/%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B9%83%E0%B8%AB%E0%B8%9A%E0%B8%A3%E0%B8%B4%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B8%AA%E0%B8%99%E0%B8%B2%E0%B8%A1%E0%B8%81%E0%B8%B5%E0%B8%AC%E0%B8%B2

### Gauntlet-loop review contract
- Quality bar: the official KMUTNB campus map and 3D campus navigation image for grounds; the published Building 77 exterior photograph for massing and palette.
- Review status: this chat completed a source-grounded implementation review, but cannot launch a genuinely separate fresh-context critic subagent. Treat the blind A/B critic pass as pending rather than claiming it has passed.
- Binary acceptance is not yet possible for exact geometry because there is no measured site plan or Roblox Studio screenshot in this session.
- Runtime gate: open the place in Roblox Studio, capture top/front/side views, and compare those images with the official campus map and exterior reference. Do not mark either phase DONE until this gate passes.


---

**Status legend for future updates:** TODO · IN PROGRESS · BLOCKED · DONE

**Reminder:** this is a development roadmap, not a description of verified current implementation.
