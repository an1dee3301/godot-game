class_name BP
extends RefCounted
## Shared constants for Baggage Panic. Track runs along -Z; lanes are 0 (left), 1 (middle), 2 (right).

const LANE_COUNT := 3
const LANE_WIDTH := 2.6
const BELT_TOP_Y := 0.0          ## Top surface of every conveyor belt.
const SEGMENT_LENGTH := 36.0     ## Default segment length (segments may be multiples of 12 m).
const SPAWN_AHEAD := 230.0       ## Keep track built this far ahead of the player.
const DESPAWN_BEHIND := 25.0     ## Free a segment once its far end is this far behind the player.
const SAFE_START_SEGMENTS := 2   ## Hazard-free segments at the start of every run.
const CHECKPOINT_EVERY := 6      ## Every Nth segment is a "checkpoint" segment.

## Player dimensions (metres). Body origin is at the bottom centre of the suitcase.
const PLAYER_WIDTH := 1.1
const PLAYER_HEIGHT := 1.3
const PLAYER_SLIDE_HEIGHT := 0.5
const PLAYER_DEPTH := 0.8

## Hazard height bands, so every obstacle is fair:
const JUMP_HAZARD_TOP := 0.9     ## JUMP hazards occupy y 0..0.9 (jump apex >= 1.9).
const SLIDE_HAZARD_BOTTOM := 0.85 ## SLIDE hazards occupy y >= 0.85 (slide height 0.5, standing 1.3).

## Physics layer bit values.
const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_HAZARD := 4
const LAYER_PICKUP := 8

const SAVE_PATH := "user://baggage_panic_save.cfg"

## Destination codes used by Wrong Destination Gates (fork segments).
const DESTINATIONS: PackedStringArray = ["LAX", "NRT", "CDG", "SYD", "JFK", "DXB", "LHR", "SGN"]


static func lane_x(lane: int) -> float:
	return (clampi(lane, 0, LANE_COUNT - 1) - 1) * LANE_WIDTH


static func ensure_input_actions() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_W, KEY_UP, KEY_SPACE],
		"slide": [KEY_S, KEY_DOWN, KEY_SHIFT],
		"pause": [KEY_ESCAPE, KEY_P],
		"start": [KEY_ENTER, KEY_KP_ENTER],
	}
	for action: String in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in map[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
