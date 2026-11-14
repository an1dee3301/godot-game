# Production tools for Trust Me, Bro!

Installed from the [Good AI List](https://goodailist.com/) game-development catalog on 13 November 2026. The tools now support the Blender-authored production showground and its network playtesting.

## Asset policy

Create models, rigs, animations and materials in Blender, or download existing free assets whose licenses permit use in the game. Do not generate images or video with AI. Conventional Blender renders and gameplay screenshots remain available for visual review. Record source URLs, licenses and credits for downloaded assets. These requirements are also recorded in the workspace `AGENTS.md`.

## Installed skills

134 additional project skills were activated or installed:

| Source | New skills | Main coverage |
| --- | ---: | --- |
| [Game Dev Agentic Skills](https://github.com/thedivergentai/Game-Dev-Agentic-Skills) | 51 | Godot 3D, physics, materials, party/educational games, multiplayer, testing, optimization, export |
| [Awesome Gamedev Agent Skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | 28 | Godot fundamentals, networking, input, shaders, balancing, production workflows |
| [EL4CTEO Blender Skills](https://github.com/EL4CTEO/blender-skills) | 28 | Blender 5.2 modeling, UVs, PBR, baking, rigging, animation, game export and QA |
| [Arjun Blender Skills](https://github.com/arjun988/blender-skills) | 27 | Stylized/cartoon/chibi art direction, characters, props, collision, LODs and Godot export |

The existing GodotPrompter skills and all previous aliases were preserved. The image-generation asset workflow was excluded. Load only the skills relevant to the current task.

Skills are installed in the development workspace’s `.agents/skills` folder. The local installation inventory, `skills-installed.json`, records exact revisions, licenses and skill names; it is a machine-only setup record in the `godot-production-tools` user-data folder, not a file required by the game. All 55 Blender skill copies were checked; 141 bundled Python scripts passed syntax checks without execution.

## MCP connections

| Connection | Version | Verified capabilities |
| --- | --- | --- |
| `godot_full` | Full Control 3.1.0, 157 tools | Run/stop, live scene properties, code evaluation, input simulation, physics, animation, camera, multiplayer, errors and performance |
| `blender` | MCP for Blender 2.2.9, 8 enabled tools | Scene inspection, Python modeling, viewport review, free-asset search/import and addon status |

Sources: [Godot MCP Full Control](https://github.com/tugcantopaloglu/godot-mcp), [MCP for Blender](https://github.com/ahujasid/mcp-for-blender).

Both connections are registered in the developer’s local Codex configuration (`~/.codex/config.toml`). The original `godot` connection remains as a fallback. The Blender addon is installed and enabled in Blender 5.2. The addon starts its local bridge when Blender opens. Its listener is local-only; telemetry is disabled. `generate_3d` and `generate_gaussian_world` are disabled in Codex. No paid generation accounts or AI image/video services were connected.

Restart Codex to load the new MCP definitions. Keep Blender open when using its tools. To enable the configured free Poly Haven integration in a new Blender session, run the local `enable_blender_bridge.py` setup helper from the tooling directory or enable Poly Haven in the addon panel. The helper preserves the current scene and saves only addon preferences.

The expanded Godot connection temporarily adds its interaction autoload when running a project and removes it on stop. Wait for the local bridge to connect before using runtime inspection. The bridge was tested against this project and returned all eight contestants with zero runtime errors. The local source includes dependency updates and five warning fixes for Godot 4.8; the upstream revision and local patches are listed in the manifest.

## Asset workflow verification

A small mesh was modeled in live Blender, exported as a GLB with modifiers applied, and imported into Godot as a mesh scene. Free Poly Haven texture search also succeeded. This test used no AI-generated media and added no test object to the production game.

Tooling and verification files are machine-only records in the `godot-production-tools` user-data folder (`~/.local/share/godot-production-tools`). Its `installation-manifest.json` records the completed checks and installed connections. Existing configuration and Blender preferences were backed up there before installation. These local helpers are optional authoring tools; the checked-in Godot game does not depend on them.

## Free existing assets

- [Poly Haven](https://polyhaven.com/) — HDRIs, textures and models, [CC0 license](https://polyhaven.com/license). Its free asset search is enabled in the current Blender session.
- [Quaternius](https://quaternius.com/) — existing game models, rigs and animations; [usage and license FAQ](https://quaternius.com/faq.html).
- [Kenney assets](https://kenney.nl/assets) — existing game assets; check the license bundled with each selected pack.

Prefer CC0 assets for easy redistribution. Keep the license and source record with each imported pack. Download art only when it has a defined role in the game.

## Rebuilding the current world

Run Blender with `--background --python tools/build_showground.py` from the project folder. `tools/build_party_world.py` forwards to that same build. The source writes `assets/world/party_garden.glb` (the filename is retained for loader compatibility), the reusable answer platform, modeled clouds, editable Blender sources, and triangle/material inventories. The runtime environment is one connected showground with a deep trap basin, not the previous collection of floating garden islands. See `assets/world/ASSET_SOURCE.md` for the current provenance and mesh review.

## Rebuilding the festival dressing

`tools/build_festival.py` writes the barges, lighting towers, string lights, crowd fan, balloon, sailboat and buoy to `assets/world`. Run it inside Blender (`--background --python tools/build_festival.py`) or, where a Blender install is not available, with the official `bpy` module: `pip install bpy` into a Python 3.13 environment, then `python tools/build_festival.py`.
