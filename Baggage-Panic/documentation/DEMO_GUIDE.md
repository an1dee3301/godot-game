# Baggage Panic — 2–4 minute demo guide

Run [project.godot](../project.godot) in Godot 4.8 with F5. Keep this guide beside the game. The times are prompts, not rigid limits; show whichever generated obstacle pattern appears next. Enter starts and restarts, A/D switches lanes, Space jumps, S slides, and Esc pauses.

| Time | Show on screen | What to say and where it is implemented |
| --- | --- | --- |
| 0:00–0:20 | Start board, controls, personal best; press Enter. | “This is an airport baggage runner built entirely from Godot primitives. `RunnerMain._ready` creates the scene systems and `RunnerMain.start_run` resets each run. The menu comes from `RunnerMenus.show_start`.” |
| 0:20–0:45 | Let the suitcase advance, then use A/D to cross all three belts. | “Forward travel is automatic. `SuitcasePlayer._physics_process` sets negative-Z velocity and eases the player toward `BP.lane_x(lane)`. `FollowCamera` tracks the bag.” Point to distance, score, level, and speed in the HUD. |
| 0:45–1:10 | Jump a security gate or broken roller gap; flatten under an X-ray scanner. | “`SuitcasePlayer.jump` and `slide` change physics and play their own animations. `Hazard.make` assigns jump, slide, and lane obstacles; `TrackSegment.build_belts` leaves actual missing floor for gaps.” If a scanner has not appeared yet, show flattening on a safe belt and name the scanner as its target. |
| 1:10–1:35 | Follow a pickup line, collecting tags and, if present, a passport. | “`Pickup.make` builds the floating items. `RunnerMain._on_pickup_collected` adds score and weight. The bag grows heavier and slows down, so the weight bar matters.” |
| 1:35–2:00 | Point out different signs and hazards while running; show pause with Esc and resume. | “`SegmentLibrary.TYPES` defines eight regular layouts. `TrackManager._spawn_to_horizon` creates track ahead and `_physics_process` frees old segments behind. Early chunks are safe, checkpoints recur every sixth chunk, and the generator avoids immediate pattern repeats.” |
| 2:00–2:30 | Reach a checkpoint or split destination gate when one appears. | “A checkpoint turns accumulated weight into a bonus and clears it. At a split, match the HUD airport code to earn +150; a wrong route cuts 10% of the score and adds weight. `RunnerMain._on_trigger_entered` handles both.” The split geometry and route triggers are built by `SegmentLibrary.build`. |
| 2:30–2:55 | Collect a white Fragile or red Priority sticker if one appears; point to HUD indicators. | “`PowerUps` gives a one-hit Fragile shield or a six-second Priority boost at 1.35× speed and 2× score. `RunnerMain._on_hazard_hit` consumes the shield. `SoundFX` synthesizes the music and cues; `AirportEnvironment.set_intensity` shifts the terminal lighting as difficulty rises.” Sticker spawns are random, so describe the indicators if neither appears during this run. |
| 2:55–3:20 | Show a higher level or explain the rising level indicator; intentionally hit an obstacle or miss a gap. | “`Difficulty.update` uses distance to raise speed, hazard density, mover speed, and gap length while reducing row spacing. `RunnerMain.end_run` records the cause and saves a new personal best through `SaveData`.” Wait briefly for the game-over board. |
| 3:20–3:35 | Read score, distance, tags, routes, and best; press Enter to restart. | “`RunnerMenus.show_game_over` displays the run results. `RunnerMain.restart` starts a fresh run, and `SaveData` keeps the best score between launches.” |

## If random pickups or patterns are slow to appear

Keep running while discussing the HUD and environment. The generated sequence changes each run; no single live run is guaranteed to show every sticker or split. The [README](../README.md) lists every pattern and mechanic, and the automated [smoke test](../tests/smoke_test.gd) checks shield, routes, checkpoints, recycling, game over, and restart directly. The [track fairness test](../tests/track_fairness_test.gd) covers generator behavior.

## Code points to open during questions

- `scripts/main.gd`: `_ready`, `_physics_process`, `start_run`, `_on_pickup_collected`, `_on_hazard_hit`, `_on_trigger_entered`, `end_run`.
- `scripts/player/suitcase_player.gd`: `_physics_process`, `move_lane`, `jump`, `slide`, `_build_animations`.
- `scripts/track/segment_library.gd`: `TYPES`, `pick_type`, `build`.
- `scripts/track/track_manager.gd`: `_spawn_to_horizon`, `_physics_process`.
- `scripts/core/difficulty.gd`, `power_ups.gd`, `save_data.gd`: progression, special pickups, persistence.
- `scripts/ui/hud.gd`, `menus.gd`; `scripts/audio/sound_fx.gd`; `scripts/world/airport_environment.gd`: presentation.
