# Baggage Panic — Architecture & Contract

Godot 4.8 (GL Compatibility), GDScript, **no external assets**: every mesh, material, sound and UI
is generated in code. Tabs for indentation, typed GDScript, `class_name` on every script.
All stub files in `scripts/` define the **public API**; implementers may add private helpers
(`_name`) and extra public members, but must NOT rename/remove the documented ones.

## World conventions
- Track runs along **-Z**. Player starts at `(0, 0, 0)` and moves toward negative z.
- Lanes 0/1/2 → x = `BP.lane_x(lane)` = -2.6 / 0 / +2.6. Belt top surface is y = 0.
- Physics layers (bit values in `BP`): WORLD 1 (belts, StaticBody3D), PLAYER 2, HAZARD 4, PICKUP 8.
- Player is a `CharacterBody3D` (layer PLAYER, mask WORLD). It owns a child `Area3D` named
  `Hitbox` (layer 0, mask HAZARD|PICKUP, monitoring on) that converts `area_entered` into signals:
  `Hazard` → `hazard_hit`, `Pickup` → `pickup_collected`, `TrackTrigger` → `trigger_entered`.
  Hazards/pickups/triggers are `Area3D`s, so the player never physically collides with them.
- Gaps (broken rollers) are simply missing floor: the player falls; when `global_position.y < -3`
  the player emits `fell` once.
- Height bands (fairness): JUMP hazards y ∈ [0, 0.9]; SLIDE hazards y ≥ 0.85;
  player stands 1.3 tall, slides at 0.5, jump apex ≥ 1.9 m, airtime ≈ 0.7 s.
  LANE hazards are tall (≥ 2.5 m) and must be avoided by switching lanes.
- Fairness rule for the generator: **every obstacle row leaves at least one lane passable**
  (by lane change, jump or slide), and consecutive rows are ≥ `difficulty.row_spacing()` apart.

## Systems
| File | Class | Role |
| --- | --- | --- |
| scripts/core/bp.gd | BP | constants, `lane_x`, `ensure_input_actions()` |
| scripts/core/difficulty.gd | Difficulty | curve from distance → speed, density, spacing … |
| scripts/core/power_ups.gd | PowerUps | Fragile shield + Priority boost timers |
| scripts/core/save_data.gd | SaveData | local high score (ConfigFile) |
| scripts/main.gd | RunnerMain | state machine, scoring, wiring |
| scripts/player/suitcase_player.gd | SuitcasePlayer | movement, input, procedural animations |
| scripts/player/follow_camera.gd | FollowCamera | chase cam + shake |
| scripts/track/*.gd | TrackManager, SegmentLibrary, TrackSegment, Hazard, Pickup, TrackTrigger | endless track |
| scripts/world/airport_environment.gd | AirportEnvironment | lights, sky, scenery |
| scripts/ui/hud.gd, menus.gd | RunnerHUD, RunnerMenus | UI |
| scripts/audio/sound_fx.gd | SoundFX | procedural audio |

## Scene tree (built by RunnerMain._ready)
```
Main (RunnerMain, scenes/main.tscn)
├─ Environment (AirportEnvironment)
├─ Track (TrackManager)
├─ Player (SuitcasePlayer)
├─ Camera (FollowCamera, target = Player)
├─ PowerUps
├─ SoundFX
├─ HUD (RunnerHUD)
└─ Menus (RunnerMenus)
```

## Endless-track lifecycle
`TrackManager._physics_process`: while the last segment's `end_z()` > `player.z - BP.SPAWN_AHEAD`,
build the next segment via `SegmentLibrary.build(type, ctx)` and place it at the previous end.
Segments whose `end_z()` > `player.z + BP.DESPAWN_BEHIND` are `queue_free()`d (emit
`segment_recycled`, increment `recycled_count`). First `BP.SAFE_START_SEGMENTS` segments are type
`"start"`; every `BP.CHECKPOINT_EVERY`th segment is `"checkpoint"`. Otherwise `pick_type` chooses
from the 8 TYPES (no immediate repeats; `split_conveyor` at most once per 4 segments).

## Gameplay rules (RunnerMain)
- Speed = `difficulty.base_speed() * (1 - 0.3 * weight) * power_ups.speed_multiplier()`.
- Score = distance (1 pt / m) × multiplier + pickup values × multiplier + bonuses.
  Multiplier = `power_ups.score_multiplier()` (×2 while boosting).
- **Pickups**: TAG (+10, +0.02 weight), PASSPORT (+50, +0.06 weight),
  PRIORITY sticker (Priority Luggage Boost: 6 s, ×2 score, ×1.35 speed),
  FRAGILE sticker (Fragile Sticker Shield: absorbs one hit; the hazard is `disable()`d).
- **Weight**: carried tags/passports make the suitcase heavier (max 1.0 → 30 % slower). A
  `checkpoint` trigger clears the weight and banks a bonus = round(weight × 500).
- **Wrong Destination Gates**: `split_conveyor` segments fork into left/right routes with
  destination signs; the middle lane is blocked by a lethal `divider`. The route trigger whose
  `data.code == destination` gives +150 and "ON ROUTE"; the wrong one gives −10 % score, +0.25 weight,
  "MISROUTED". Then a new destination is chosen and shown in the HUD.
- Hazard hit: if shield → consume, `hazard.disable()`, camera shake; else Game Over.
  Falling into a gap is always Game Over.
- Difficulty: `Difficulty.update(distance, time)` each frame; level-ups flash in the HUD.

## Input actions (registered by `BP.ensure_input_actions()` in RunnerMain._ready)
move_left (A/←), move_right (D/→), jump (W/↑/Space), slide (S/↓/Shift), pause (Esc/P), start (Enter).
The player reads move/jump/slide only while `running`. Menus use buttons + `start` action.

## Testing / running headless
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 120`
In a sandbox set `HOME=/tmp/bp_home` (Godot writes to `$HOME/Library/...`).
Tests are SceneTree scripts in `tests/` run with `-s res://tests/<name>.gd`.
