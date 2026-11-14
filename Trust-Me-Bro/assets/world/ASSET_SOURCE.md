# Original production showground assets

The current set was modeled in Blender 5.2.2 for **Trust Me, Bro!** with `tools/build_showground.py`. It uses authored geometry, constant PBR materials and unlit quiz display materials, with explicit sRGB-to-linear conversion for consistent exported colors. No generated images, generated video, external textures, downloaded meshes, or paid assets were used. These are original project assets; no external mesh license or attribution is required.

| Runtime export | Mesh/material batches | Triangles | Purpose |
| --- | ---: | ---: | --- |
| `party_garden.glb` | 17 | 49,068 | One connected cream, timber, coral and navy showground; open trap basin; integrated Cheer Squad station and giant physical quiz TV |
| `answer_platform.glb` | 5 | 1,760 | Reusable beveled trap module with independently tintable answer face and pressure-warning trim |
| `marshmallow_cloud.glb` | 1 | 1,760 | Sparse modeled clouds for wider establishing views |

Editable authoring scenes are `tools/source/party_showground.blend` and `tools/source/answer_platform.blend`. `tools/build_party_world.py` forwards to the current showground builder. The runtime filename `party_garden.glb` is retained for loader compatibility; it now contains the new showground, not the earlier floating islands. The old `tools/source/party_garden.blend` snapshot and `legacy_garden_qa.json` are historical prototype records and are not loaded by the game.

The physical quiz contract is unchanged: pad centers are ±3.4 m, their collision size is 6.5 m, their top is y=0, and the Cheer Squad balcony is at y=1.5 and z=−10. The promenade, architecture and basin are visual meshes. They add no collision that can catch falling actors before the y=−6 elimination plane. Runtime collision consists of the answer pads, the existing balcony boundaries and the y=−8 catch floor.

The `white` material is tinted per answer, and `signal` is the separate pressure-warning trim. The giant TV replaces the earlier decorative marquee and festoon. Its cream `Screen_Face` and colored `Screen_Answer_A` / `B` / `C` / `D` nodes and materials retain semantic names for the game. These five materials use the glTF `KHR_materials_unlit` extension so the display stays readable under stage lighting. The question, answers and pad letters use runtime 3D text with the project’s licensed Fredoka font. Mesh colors require no UV textures.

The 23 × 5.2 m TV is behind the balcony. Its active face is 22.1 × 4.32 m, centered at x=0/y=5.2, with front z=−13.50. Four 5.2 × 1.34 m answer plates are centered at x=−8.145, −2.715, 2.715 and 8.145, y=3.85, with front z=−13.42. Exact display and text-plane coordinates are also stored in `showground_stats.json`.

## Geometry and visual review

Full game-profile mesh QA passed for the showground and answer module with zero errors, including spatial contact and coplanar-surface checks. Findings fixed during review included overlapping frame corners, a redundant cream layer, detached hardware/flowers and a sign backing gap. See `showground_qa.json`, `answer_platform_qa.json`, and the current `mesh_qa.json` alias.

Accepted static-set warnings: 23 buried contact-face pairs are retained inside fitted caps, trim, timber and TV hardware; two recessed brass caps are enclosed. These do not produce exposed overlapping surfaces. The world extends below the origin because the origin is the playable surface and the basin is deep. The pad similarly extends below its origin because its top is the play surface.

The complete set was inspected in Blender material and wireframe views from the front, top and three-quarter angles, then rendered with the actual Godot shared-camera perspective and all eight modeled contestants. This review confirmed clear player silhouettes, a restrained connected set and visible trap depth. The existing gameplay suite passed all 42 checks after the replacement.

## Festival dressing

The set dressing around the showground was modeled for this project with `tools/build_festival.py`, using the same authored-geometry approach and palette as the showground: flat PBR materials, no images, no generated media, no downloaded meshes. It was built with Blender 5.3 through the official `bpy` Python module (`pip install bpy`, then `python tools/build_festival.py`); the script also runs inside Blender with `--background --python`. These are original project assets; no external license or attribution is required.

| Runtime export | Mesh/material batches | Triangles | Purpose |
| --- | ---: | ---: | --- |
| `festival_dressing.glb` | 13 | 51,648 | Two spectator barges with tiered stands, two lighting towers, stage lamps, string lights and bunting |
| `crowd_fan.glb` | 2 | 1,168 | One crowd fan, instanced 60 times with per-instance colour |
| `party_balloon.glb` | 2 | 1,012 | One balloon with string, tinted per instance |
| `sailboat.glb` | 6 | 978 | Small sailing dinghy for the lagoon |
| `buoy.glb` | 3 | 1,240 | Channel buoy with a lamp |

Editable sources are saved beside the others in `tools/source`. `festival_layout.json` records seat, lamp and balloon anchor positions; `scripts/stage_show.gd` mirrors those formulas so the game does not need the JSON at runtime. Materials named `bulb_*` are emissive and are dimmed by the game during Lights Out. The dressing adds no collision.

The lagoon, the slop in the trap basin, light beams and particles are procedural shaders and engine particles written in GDScript, not image assets. The lagoon surface was raised to y=-4.95 so hulls sit in the water; the y=-6 elimination plane and y=-8 catch floor are unchanged.
