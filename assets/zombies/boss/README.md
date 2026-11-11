# Male Boss Zombie Asset Spec (`MaleBoss`)

- **Drop-in `.rbxm` filename**: `MaleBoss.rbxm` (fallback: `Boss.rbxm`)
- **Category Restriction**: Male-only mutated boss threat.
- **Scale Target**: `~9.00 studs` tall (`~1.75x` standard player height, squarely within `1.5–2.0x`).
- **Distorted Boss Silhouette (not a scaled-up normal zombie)**:
  - Massive asymmetric barrel torso with hunched upper back trapezius bulge and dorsal spine bone eruptions.
  - Calcified left shoulder horns bursting through shredded security vest.
  - Exposed glowing crimson pectoral infection cavity with fractured ribs.
  - **Hypertrophied Right Claw Arm** (`1.36x` thicker/longer than left arm) with glowing infected veins and 3 long dark bone talons.
  - Split mutated lower mandible with protruding bone fangs and recessed ember eyes.
- **Mesh & Texture Budget**:
  - Triangle budget: `<= 12,000 tris` total.
  - PBR texture resolution: `1024x1024` or `2048x2048` `SurfaceAppearance` + Emissive chest core/vein mask.
- **Pathfinding Bounds**: `AgentRadius = 2.35`, `AgentHeight = 9.0` configured in `ZombieAI.lua`.
- **Audio Vocal Class**: Sub-bass roaring, deep cave reverb, heavy thud footsteps (`RollOffMaxDistance = 92` studs).
