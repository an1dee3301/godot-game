# Original party mascots

The four original mascot models, eight color variants, and eight portrait renders were created for this game in Blender 5.2.2. No external models, textures, AI image/video generation, or Nintendo art was used.

- Source geometry: `tools/build_party_cast.py`.
- Editable Blender scenes: `art/source/bun.blend`, `cub.blend`, `pip.blend`, `sprout.blend`.
- Game exports: `bun.glb`, `cub.glb`, `pip.glb`, `sprout.glb`.
- Portraits: conventional renders of those same modeled meshes, produced by `tools/render_party_portraits.py`.
- Animation: separate model nodes at shoulder/ankle pivots, animated by the Godot contestant controller. Physical dives rotate the entire rigid body.

Each mascot contains approximately 10,800–11,850 triangles, grouped into six animated mesh parts. Materials are plain colors and work without texture dependencies. The physics collider origin is at body center, with the soles 0.9 units below it.

Automated asset QA passed with zero errors for all four models. Intentional accepted warnings are stacked UV charts on color-only subparts (there is no texture baking or unique image map), and the collider-centered origin placing the soles below the Blender origin. These choices preserve the runtime collider and animation contracts. The models were rendered together in Godot and inspected from the actual shared gameplay camera. Details are in `manifest.json` and `qa-report.json`.
