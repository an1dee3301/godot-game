#!/bin/zsh
# Double-click to launch the show on macOS.
TASK_GAME_DIR="${0:A:h}"
if [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
  exec /Applications/Godot.app/Contents/MacOS/Godot --path "$TASK_GAME_DIR"
elif command -v godot >/dev/null 2>&1; then
  exec godot --path "$TASK_GAME_DIR"
else
  print 'Install Godot 4.5 or newer, then open project.godot and press F5.'
  read '?Press Return to close.'
fi
