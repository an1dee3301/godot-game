# Aim Botz Arena

An original, self-contained Godot 4 FPS training game for the **First FPS Game – Version 2** assignment. The arena, weapons, characters, textures, effects, menus and sounds are built at runtime. It uses no Counter-Strike, Valve or tutorial map assets.

## Play

Open `project.godot` in Godot 4 and press **F5**. Tested with Godot 4.8.dev3 on macOS using the Compatibility renderer.

Choose a mode from the main menu:

- **Wave mission:** clear three waves of 3, 5 and 7 armed bots. The later waves introduce heavy bots. You have 100 health and finite ammunition. Find the green health kits and yellow ammo crates around the arena. Clearing all 15 enemies completes the mission; reaching 0 health ends it.
- **Static practice:** a 60-second aim session with 15 stationary targets. Targets respawn one second after a kill. The player is invulnerable and reserve ammunition is unlimited; magazines still require reloads.
- **Strafing practice:** the same timed session with moving targets. Compare score, accuracy and head hits on the result screen.

Pause freezes movement, combat, reloads, respawns and the session timer. Restart returns health, weapons, supplies, barrels, doors and statistics to their starting state.

## Controls

| Action | Input |
| --- | --- |
| Move / look | WASD / mouse |
| Jump / sprint | Space / hold Shift while moving forward |
| Fire | Left mouse button (rifle automatic; pistol one shot per click) |
| Aim down sights | Hold right mouse button |
| Reload | R |
| Rifle / pistol | 1 / 2, or mouse wheel |
| Open / close bunker door | E while looking at the door within reach |
| Pause / resume | Escape |
| Restart after a result | Enter, or Play Again |

## Weapons and scoring

The AK-style rifle has a 30-round magazine and deals 30 body damage; the Deagle-style pistol has a 7-round magazine and deals 55 body damage. Head hits deal four times body damage. Movement, jumping and sustained fire increase spread; aiming reduces spread. Standard enemies have 100 health and heavy enemies have 250 health.

Player kills award 100 points for a standard bot or 250 for a heavy, plus 50 for a headshot kill. Accuracy is bullets that hit a bot divided by bullets fired. Head hits count successful headshot impacts, including nonlethal hits on heavy bots. Explosive barrel kills award points but do not count as bullet hits.

The HUD displays health, magazine/reserve, selected weapon, reload progress, elapsed or remaining time, objective, score, accuracy, head hits and a radar. The crosshair expands with weapon spread. Hits produce a marker; damage produces red screen edges and a direction arrow. Orange radar dots mark heavy bots, red dots mark standard bots and the green triangle marks the player.

## Assignment coverage

| Requirement | Implementation |
| --- | --- |
| A. FPS controller | Movement, mouse look, jumping, gravity and capsule collision |
| B. Shooting | Two raycast weapons, head damage, gunshots, recoil, muzzle flashes, tracers and impacts |
| C. Ammo / reload | Magazines, finite reserves in wave mode, empty trigger, R reload and HUD |
| D. Health | Player and bot health, enemy fire, death animations and removal |
| E. Enemies | Three waves; enemies detect, navigate, chase, strafe and shoot |
| F. Original level | Grid textures, raised platform and ramps, cover, container lane and two-room bunker |
| G. HUD | Health, ammo and dynamic crosshair, plus statistics and radar |
| H. Result | Game Over, Mission Complete and restart |

Version 2 improvements include sprint, health/ammo pickups, scoring, enemy health bars, muzzle flash, reload/footstep sounds, main/pause menus, an interactive sliding door, timer and damage feedback. Bonus features include weapon switching, standard/heavy enemies, baked navigation, bot states, waves, radar, ADS, explosive barrels and practice modes.

## Verification

Run the included integration test with your Godot executable:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/smoke.gd
```

The test exercises the actual scene and physics: launch/menu, movement/sprint/jump, empty magazine/reload, pause, a raycast headshot, scoring, pickups, door motion, all waves, win/lose/restart, target respawning, practice timer, strafing, session cleanup, navigation to the platform and enemy fire. The import step is needed for a fresh checkout so Godot registers script classes.

Launch directly into a mode for quick checks:

```sh
godot --path . -- --waves
godot --path . -- --practice
godot --path . -- --strafe
```

## Project layout

- `scenes/main.tscn` — entry scene.
- `scripts/main.gd` — session state, modes, spawning, waves, statistics and input bindings.
- `scripts/hud.gd` — HUD, radar, menus and damage/hit feedback.
- `scripts/player.gd` — FPS movement, weapons, health and first-person models.
- `scripts/bot.gd` — enemy states, navigation, combat, health bars and death animation.
- `scripts/arena_level.gd` — procedural geometry, textures, lighting and navigation bake.
- `scripts/pickup.gd`, `sliding_door.gd`, `explosive_barrel.gd` — interactive arena objects.
- `scripts/fx.gd`, `sound_fx.gd` — procedural visual and audio effects.
- `tests/smoke.gd` — integration test.
- `documentation/DEMO_GUIDE.md` — suggested student recording checklist.

The assignment PDF stays local and is ignored by Git. Record the demo video separately; it is not part of the repository.
