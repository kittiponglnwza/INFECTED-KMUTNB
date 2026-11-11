# Female Zombie Asset Spec (`FemaleWalker` / `FemaleRunner`)

- **Drop-in `.rbxm` filenames**: `FemaleWalker.rbxm`, `FemaleRunner.rbxm` (fallback: `Female.rbxm`)
- **Scale Target**: Standard Roblox female avatar height (`4.88 – 4.95 studs`)
- **Distinct Silhouette & Proportions** (must differ clearly from Male rig):
  - Narrower shoulders, pinched waist (`LowerTorso`), slender forearms/calves, softer tapered jaw & larger eye sockets.
  - Distinct Hairstyle: Parted framing bangs + trailing multi-segment high ponytail (`FemaleWalker`) or jagged layered bob (`FemaleRunner`).
  - Distinct Clothing: Fitted white student blouse with crimson collar ribbon & dark navy pleated skirt + knee-high socks (`FemaleWalker`); torn dark crimson track top + shorts (`FemaleRunner`), with pale ash-toned infected skin and bite trauma on neck/collarbone.
- **Mesh & Texture Budget**:
  - Triangle budget: `<= 7,000 tris` total (including sculpted hair cards/strands).
  - PBR texture resolution: `1024x1024` `SurfaceAppearance`.
- **Required R15 Joints**: Standard 15 `Motor6D` hierarchy so `ZombieAnimationController` drives asymmetrical head canting, swaying shoulder/hip limp, and twin claw rake cleanly.
- **Audio Vocal Class**: Higher-pitched eerie groans, distorted shrieks, lighter rapid footsteps.
