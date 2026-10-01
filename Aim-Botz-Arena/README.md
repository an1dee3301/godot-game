# Aim Botz Arena

**First FPS Game – Version 2.** A small, complete FPS for Godot 4 in the style of *Aim Botz*, the CS2 community training map. It has a dev-textured arena, a raised spawn platform overlooking the field, and bots to shoot, with headshots doing the most damage. As in the other games in this repo, everything (level, models, UI and sound) is built at runtime from Godot primitives, so the project requires no external game assets.

## Play

1. Open this folder's `project.godot` in Godot 4 (tested with 4.8.dev3 on macOS with the Compatibility renderer).
2. Press `F5`.
3. Choose **PLAY MISSION**, **AIM PRACTICE**, or **AIM PRACTICE - RUSH**.

| Key | Action |
| --- | --- |
| `W A S D` | Move |
| Mouse | Look |
| `Space` | Jump |
| `Shift` | Sprint |
| Left mouse | Shoot (AK-47 is automatic, Desert Eagle is semi-auto) |
| Right mouse | Aim down sights |
| `R` | Reload |
| `1` / `2` / `Q` / mouse wheel | Switch weapon |
| `E` | Open or close doors |
| `B` | Cycle Static → Strafe → Rush targets (practice mode) |
| `Esc` / `P` | Pause menu |

**Mission:** survive 3 waves of bots (3, then 5, then 7, including red **heavy** bots) and eliminate them all to get **MISSION COMPLETE**. If your health reaches 0, it's **GAME OVER**. Both end screens show your stats and have **Restart** and **Main Menu** buttons.

**Aim Practice:** a 60-second Aim Botz drill. Press B to cycle Static, Strafe, and Rush targets, or choose **AIM PRACTICE - RUSH** from the menu. In Rush, bots run toward you; reaching you or the raised platform edge counts as a leak and gives visual and audio feedback, but no kill credit. Targets respawn at their home spots after one second. You get unlimited reserve ammo and take no damage. The HUD shows the target mode, kills, headshot %, accuracy, and Rush leaks. The Practice Complete screen includes leaks if Rush was used. Practice scores are separate from the saved best mission score.

Pause freezes the session timer, combat, reloads and target respawns. Restart resets the session and cancels the previous death camera animation.

## Assignment checklist

| Requirement | Implementation |
| --- | --- |
| **A. FPS controller** | `CharacterBody3D` with WASD, mouse look (pitch clamped), jump, gravity and capsule collision (`scripts/player.gd`) |
| **B. Shooting** | Two weapons, both hitscan raycast. Bots take damage, and headshots deal 4×. Gunshot sound, muzzle flash, tracer, bullet holes and blood/spark particles |
| **C. Ammo & reload** | HUD shows magazine / reserve. Firing empties the magazine, then `R` reloads (empty-click plus auto-reload, "Press R to reload" prompt) |
| **D. Health** | Player has 100 HP. Bots have 100 (standard) or 250 (heavy) HP and shoot the player. Dead bots fall over, fade out and are removed |
| **E. Enemies** | Waves of 3–7 bots. Each one detects the player with line-of-sight raycasts, paths toward them on a navmesh, then strafes and burst-fires |
| **F. Level** | Original arena: an 80 m dev-texture floor and walls, a raised platform with ramps and cover, crates, pillars, low walls, a container lane, and a two-room bunker with a sliding door. Floor distance markers like Aim Botz |
| **G. HUD** | Health with bar, ammo and weapon name, dynamic CS-style crosshair with hit marker |
| **H. Game result** | GAME OVER at 0 HP. Win by clearing every wave. Restart from the end screen or pause menu |

### Version 2 improvements (the brief asks for 2; this has 12)

1. **Sprint** (`Shift`, with FOV kick and weapon tilt)
2. **Health pickup** (+40 HP, respawns after 25 s)
3. **Ammo pickup** (refills reserve)
4. **Score system** (100 per kill, 250 per heavy, +50% for headshots, +50 for barrel kills, plus time and accuracy bonuses; best score is saved)
5. **Enemy health bars** (billboard bar and name tag above every bot)
6. **Gun muzzle flash** (flash quads plus a light)
7. **Reload sound** (magazine-out and magazine-in clicks timed to the animation)
8. **Footstep sound** (stride-based, louder when sprinting, plus a landing thud)
9. **Main menu** (mode select, mouse-sensitivity slider, controls and best score), plus a **pause menu**
10. **Simple door system** (the bunker's sliding door: `E` for the player, opens automatically for bots)
11. **Simple timer** (mission clock or practice countdown in the HUD)
12. **Damage feedback** (red flash, low-health vignette, directional hit arcs, camera shake)

Student-proposed extra: **Aim Botz practice mode** with headshot and accuracy statistics, plus **Rush targets that run toward the player** and a leak counter.

### Optional / bonus features

- Multiple weapons and **weapon switching** (AK-47 and Desert Eagle)
- **Two enemy types** (standard and heavy)
- **Navigation mesh** pathfinding (baked at runtime from the level colliders)
- **Finite state machine** bot AI (IDLE → CHASE → ATTACK → DEAD)
- **Wave survival** mode (3 waves)
- **Mini-map** radar that rotates with the player
- **Aim down sights** (right mouse: zoom, tighter spread, slower movement)
- **Explosive barrels** that chain-react and damage bots and the player

## Project layout

- `scenes/main.tscn` — launch scene
- `scripts/main.gd` — game flow: menus, waves, score, timer, win/lose, restart, practice mode, input map
- `scripts/arena_level.gd` — level geometry, dev textures, lighting, spawn points, navmesh bake
- `scripts/player.gd` — FPS controller, weapons, recoil/spread, reload, health, viewmodel
- `scripts/bot.gd` — enemy FSM, navigation, shooting, hitboxes, health bar, death animation
- `scripts/pickup.gd`, `scripts/explosive_barrel.gd`, `scripts/sliding_door.gd` — interactive props
- `scripts/fx.gd` — tracers, impacts, muzzle flashes, spawn beams, explosions
- `scripts/sound_fx.gd` — procedurally synthesised sound effects
- `scripts/ui/` — HUD, crosshair, radar, damage indicator, menus
- `tests/smoke_test.gd` — headless gameplay test

## Test

```sh
godot --headless --editor --path . --quit
godot --headless --path . -s tests/smoke_test.gd
```

The import step registers script classes on a fresh checkout. The integration test checks movement, sprint, jump/gravity, navigation and enemy fire, raycast head/body damage, ammo/reload, pause, pickups, door motion and barrels, all waves and win/lose screens, result statistics for the final shot, restart during a death animation, and practice respawns/countdown/strafing/Rush movement, leaks and session cleanup.

For a direct launch, add `-- --waves`, `-- --practice`, `-- --strafe`, or `-- --rush` to your Godot command.

See `documentation/DEMO_GUIDE.md` for a suggested 2–4 minute student recording. The demo video stays outside this repository. PDF files are ignored by Git; the local assignment PDF is not committed.
