# INFECTED-KMUTNB Custom Zombie Asset Workflow (R15)

## Environment Note
This repository provides **two seamlessly integrated asset layers**:
1. **Immediate Playable In-Engine R15 Rigs** (`src/server/gameplay/zombies/ZombieModelFactory.lua`):
   Full 15-part articulated Roblox R15 rigs (`Humanoid.RigType = Enum.HumanoidRigType.R15` + `Motor6D` joints + `Animator`) built automatically at exact Roblox avatar scale (`~5.15` studs Male, `~4.95` studs Female, `~9.00` studs Male Boss).
2. **Drop-in Studio Skinned Mesh / FBX Override (`ReplicatedStorage.Assets.Zombies`)**:
   Because an external CLI environment cannot run Autodesk Maya / Blender GUI / Roblox Studio 3D Importer to export signed `.fbx` / `.rbxm` `MeshPart` + `SurfaceAppearance` binaries, this directory serves as the canonical **Rojo asset mount (`ReplicatedStorage.Assets`)** and technical specification for dropping in custom Studio `.rbxm` models.

## Importing Custom 3D Character Models in Roblox Studio
1. Export custom **R15-rigged `.fbx`** meshes per category using the dimensions and joint hierarchy in:
   - `assets/zombies/male/README.md`
   - `assets/zombies/female/README.md`
   - `assets/zombies/boss/README.md`
2. In Roblox Studio, use **Avatar -> Import 3D** with **R15** rig settings and PBR textures (`ColorMap`, `NormalMap`, `RoughnessMap`) inside `SurfaceAppearance`.
3. Verify each imported Model contains:
   - Exact R15 hierarchy: `HumanoidRootPart`, `LowerTorso`, `UpperTorso`, `Head`, `Left/RightUpperArm`, `Left/RightLowerArm`, `Left/RightHand`, `Left/RightUpperLeg`, `Left/RightLowerLeg`, `Left/RightFoot`.
   - `Humanoid` with `RigType = Enum.HumanoidRigType.R15` and an `Animator` child.
   - Optional `HitZone` attributes (`"Head"`, `"Body"`, `"Legs"`); missing attributes are inferred automatically from part names by `ZombieModelFactory.lua`.
4. Save the Studio Models as `.rbxm` files inside this directory:
   - `assets/zombies/male/MaleWalker.rbxm` & `MaleRunner.rbxm` (or `Male.rbxm`)
   - `assets/zombies/female/FemaleWalker.rbxm` & `FemaleRunner.rbxm` (or `Female.rbxm`)
   - `assets/zombies/boss/MaleBoss.rbxm` (or `Boss.rbxm`)
   Rojo syncs them directly under `ReplicatedStorage.Assets.Zombies`, and `ZombieModelFactory.build` automatically prioritizes them over the procedural fallback rigs.

## Publishing Custom Animations & Audio (Studio Only)
- **Animations**: Open **Animation Editor** on each rig, author the 8 states (`Idle`, `Walking`, `Running`, `Chasing`, `Attacking`, `TakingDamage`, `Stunned`, `Death`), publish them via Roblox Creator Dashboard, and paste the returned `rbxassetid://...` strings into `ZombieCatalog.lua` -> `AnimationProfile.AnimationIds`.
- **Audio**: Upload licensed `.wav` / `.ogg` horror audio in **Asset Manager -> Audio** and paste verified `rbxassetid://...` IDs into `ZombieCatalog.lua` -> `AudioProfile.CustomSoundIds`. Empty slots automatically use the spatial procedural fallback synthesizer in `ZombieAudioController.lua`.
