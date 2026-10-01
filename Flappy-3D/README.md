# Flappy 3D

A complete, asset-free 3D Flappy Bird prototype for Godot 4. It uses a close chase camera, forward-rushing pipes, a procedural fake sky, a neon skyway, speed streaks, FOV boost, and radial motion-blur simulation. The models, scenery, UI, animation, and sound effects are all created at runtime from Godot primitives.

## Play

1. Open this folder in Godot 4.
2. Run the project (`F5` or the play button).
3. Click, tap, press `Space`, `W`, or `Up Arrow` to flap.

Fly through each approaching pipe gap to score. The gaps narrow, the course accelerates, and the racing effects intensify gradually. Your best score is saved locally.

## Project layout

- `scenes/main.tscn` — the launch scene.
- `scripts/main.gd` — game state, spawning, world, HUD, scoring, and effects.
- `scripts/bird.gd` — bird model, animation, and flight physics.
- `scripts/pipe_pair.gd` — procedural pipes, collisions, movement, and score gates.
- `scripts/sound_fx.gd` — tiny procedural sound effects; no audio files required.
