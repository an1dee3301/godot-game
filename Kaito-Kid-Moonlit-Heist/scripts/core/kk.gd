class_name KK
extends RefCounted
## Shared constants and cross-system helpers for Kaito Kid: Moonlit Heist.
## World axes: +Y up, metres. The museum floor is at y = 0.

## Physics layer bit values (see project.godot layer names).
const LAYER_WORLD := 1        ## Walls, floor, pillars, display plinths. Blocks sight and movement.
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_PICKUP := 8       ## Area3D triggers: jewels, pickups, exit, lasers.
const LAYER_PROJECTILE := 16
const LAYER_GLASS := 32       ## Display glass: blocks movement but NOT sight.

## Groups.
const GROUP_PLAYER := "player"
const GROUP_GUARDS := "guards"            ## Every Guard node (any kind).
const GROUP_JEWELS := "jewels"            ## Every Jewel node.
const GROUP_INTERACTABLE := "interactable" ## Nodes with interact(player) / get_prompt() / can_interact(player).
const GROUP_MINIMAP := "minimap_icon"      ## Nodes with minimap_icon() -> String ("jewel","exit","pickup","camera","fuse").

## Objective.
const JEWELS_REQUIRED := 5

## Player tuning.
const PLAYER_MAX_HP := 100.0
const PLAYER_WALK_SPEED := 4.6
const PLAYER_SPRINT_SPEED := 7.6
const PLAYER_CROUCH_SPEED := 2.4
const PLAYER_JUMP_VELOCITY := 5.2
const PLAYER_START_SMOKE := 2
const PLAYER_MAX_SMOKE := 4
const CARD_COOLDOWN := 0.4
const CARD_SPEED := 28.0
const CARD_RANGE := 30.0
const SMOKE_RADIUS := 5.0
const SMOKE_DURATION := 6.0
const INTERACT_RANGE := 2.2

## Noise radii (metres) the player makes. Guards inside the radius "hear" it.
const NOISE_SPRINT_STEP := 9.0
const NOISE_WALK_STEP := 3.0
const NOISE_LAND := 7.0
const NOISE_CARD_IMPACT := 6.0
const NOISE_LASER_ALARM := 30.0

enum EnemyKind { GUARD, INSPECTOR }

## Per-kind enemy stats. Guard reads these in setup().
const ENEMY_STATS := {
	EnemyKind.GUARD: {
		"name": "Security Guard",
		"max_hp": 3,               ## Card hits to knock out.
		"patrol_speed": 2.2,
		"chase_speed": 5.4,
		"view_distance": 14.0,
		"view_angle_deg": 95.0,    ## Full cone angle.
		"hearing_mult": 1.0,
		"detect_time": 0.9,        ## Seconds of full-visibility sight to go from 0 to 1 awareness.
		"attack_range": 1.7,
		"attack_damage": 18.0,
		"attack_windup": 0.45,
		"attack_cooldown": 1.2,
		"alert_radius": 14.0,      ## Radius in which spotting the player alerts other guards.
		"lose_time": 3.0,          ## Seconds without sight before CHASE -> SEARCH.
		"search_time": 6.0,        ## Seconds spent investigating before RETURN.
		"stun_time": 2.5,          ## Per non-lethal card hit.
		"color": Color(0.12, 0.17, 0.32),
	},
	EnemyKind.INSPECTOR: {
		"name": "Inspector",
		"max_hp": 6,
		"patrol_speed": 2.6,
		"chase_speed": 6.4,
		"view_distance": 18.0,
		"view_angle_deg": 110.0,
		"hearing_mult": 1.5,
		"detect_time": 0.6,
		"attack_range": 2.0,
		"attack_damage": 30.0,
		"attack_windup": 0.6,
		"attack_cooldown": 1.5,
		"alert_radius": 30.0,
		"lose_time": 5.0,
		"search_time": 9.0,
		"stun_time": 1.2,
		"color": Color(0.33, 0.24, 0.16),
	},
}

## Multiplier applied to chase/patrol speed once every jewel is stolen (alarm phase).
const ALARM_SPEED_MULT := 1.15

const SAVE_PATH := "user://kaito_kid_save.cfg"


static func ensure_input_actions() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT],
		"crouch": [KEY_CTRL, KEY_C],
		"jump": [KEY_SPACE],
		"fire": [KEY_F],
		"smoke": [KEY_Q],
		"interact": [KEY_E],
		"pause": [KEY_ESCAPE, KEY_P],
		"restart": [KEY_R],
		"confirm": [KEY_ENTER, KEY_KP_ENTER],
	}
	for action: String in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: Key in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", mouse)
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("smoke", right)


## Tell every guard within `radius` of `pos` that it heard something there.
static func emit_noise(tree: SceneTree, pos: Vector3, radius: float) -> void:
	if tree == null:
		return
	for guard in tree.get_nodes_in_group(GROUP_GUARDS):
		if guard.has_method("hear_noise"):
			guard.hear_noise(pos, radius)


## Alert every guard within `radius` of `origin` that the player was seen at `player_pos`.
## `except` is not alerted (usually the guard raising the alarm).
static func alert_guards(tree: SceneTree, origin: Vector3, radius: float, player_pos: Vector3, except: Node = null) -> void:
	if tree == null:
		return
	for guard in tree.get_nodes_in_group(GROUP_GUARDS):
		if guard == except or not guard.has_method("receive_alert"):
			continue
		if (guard as Node3D).global_position.distance_to(origin) <= radius:
			guard.receive_alert(player_pos)


static func get_player(tree: SceneTree) -> Node3D:
	return tree.get_first_node_in_group(GROUP_PLAYER) as Node3D if tree else null


## True when nothing on LAYER_WORLD blocks the straight line from `from` to `to`.
static func has_line_of_sight(world: World3D, from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, LAYER_WORLD)
	return world.direct_space_state.intersect_ray(query).is_empty()


static func standard_material(color: Color, roughness := 0.7, metallic := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat
