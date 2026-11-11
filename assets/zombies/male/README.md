# Male Zombie Asset Spec (`MaleWalker` / `MaleRunner`)

- **Drop-in `.rbxm` filenames**: `MaleWalker.rbxm`, `MaleRunner.rbxm` (fallback: `Male.rbxm`)
- **Scale Target**: Standard Roblox R15 player height (`5.06 – 5.15 studs`)
- **Silhouette & Proportions**:
  - Broad male shoulder span, strong square cranial jaw/brow, thick forearms.
  - `MaleWalker`: Torn KMUTNB engineering white dress shirt, skewed navy tie, bloodstained torso wounds, dark trousers, scuffed leather shoes.
  - `MaleRunner`: Ragged dark torn jacket, open rib-chest wound, hunched sprint silhouette, emissive feral eyes.
- **Mesh & Texture Budget**:
  - Triangle budget: `<= 6,500 tris` total per character (`<= 1,500` head, `<= 2,500` torso/cloth, `<= 2,500` limbs).
  - PBR texture resolution: `1024x1024` `SurfaceAppearance` (Diffuse, Normal, Roughness).
- **Required R15 Joints**: Standard 15 `Motor6D` joints (`Root`, `Waist`, `Neck`, `Left/RightShoulder`, `Left/RightElbow`, `Left/RightWrist`, `Left/RightHip`, `Left/RightKnee`, `Left/RightAnkle`).
- **Audio Vocal Class**: Deep guttural male groans, heavy footsteps, low-pitch snarls.
