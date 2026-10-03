class_name Hazard
extends Area3D
## A dangerous obstacle. collision_layer = BP.LAYER_HAZARD, in group "hazard". OWNER: agent B.

enum Avoid { JUMP, SLIDE, LANE }

var kind := "barrier"
var avoid := Avoid.LANE
var lethal := true
var display_name := "Obstacle"
var _home_x := 0.0
var _clock := 0.0
var _move_speed := 1.0
var _moving := false

func _init() -> void:
	collision_layer = BP.LAYER_HAZARD
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("hazard")

static func make(obstacle_kind: String, mover_scale: float = 1.0) -> Hazard:
	var node := Hazard.new()
	node.kind = obstacle_kind
	var steel := TrackProps.material("steel", Color(0.34, 0.4, 0.44), 0.72)
	var dark := TrackProps.material("hazard_dark", Color(0.085, 0.105, 0.125), 0.25)
	var yellow := TrackProps.material("warning_yellow", Color(1.0, 0.72, 0.045), 0.25)
	var red := TrackProps.material("lamp_red", Color(0.9, 0.06, 0.045), 0.1, Color(0.8, 0.02, 0.01))
	var amber := TrackProps.material("lamp_amber", Color(1.0, 0.43, 0.025), 0.1, Color(0.9, 0.22, 0.01))
	var white := TrackProps.material("hazard_white", Color(0.83, 0.9, 0.88), 0.15)
	var cyan := TrackProps.material("hazard_cyan", Color(0.05, 0.9, 0.92), 0.1, Color(0.02, 0.6, 0.75))
	match obstacle_kind:
		"security_gate":
			node.avoid = Avoid.JUMP
			node.display_name = "Security Gate"
			TrackProps.shape(node, Vector3(1.85, 0.8, 0.5), Vector3(0, 0.4, 0))
			TrackProps.box(node, Vector3(1.85, 0.45, 0.4), Vector3(0, 0.37, 0), yellow)
			TrackProps.box(node, Vector3(0.18, 0.85, 0.48), Vector3(-0.9, 0.42, 0), steel)
			TrackProps.box(node, Vector3(0.18, 0.85, 0.48), Vector3(0.9, 0.42, 0), steel)
			for x in [-0.62, -0.22, 0.18, 0.58]:
				TrackProps.stripe(node, Vector3(x, 0.38, 0.215), Vector3(0.14, 0.49, 0.02), dark)
			TrackProps.sphere(node, 0.14, Vector3(-0.8, 0.91, 0), red)
			TrackProps.sphere(node, 0.14, Vector3(0.8, 0.91, 0), amber)
			TrackProps.box(node, Vector3(0.38, 0.12, 0.16), Vector3(0, 0.7, 0.27), dark)
		"xray_scanner":
			node.avoid = Avoid.SLIDE
			node.display_name = "X-Ray Scanner"
			TrackProps.shape(node, Vector3(2.15, 1.7, 1.1), Vector3(0, 1.75, 0))
			for side in [-1.0, 1.0]:
				TrackProps.box(node, Vector3(0.32, 2.65, 1.7), Vector3(side * 1.22, 1.33, 0), white)
				TrackProps.box(node, Vector3(0.07, 2.25, 1.72), Vector3(side * 1.42, 1.28, 0), yellow)
			TrackProps.box(node, Vector3(2.75, 0.43, 1.75), Vector3(0, 2.54, 0), white)
			TrackProps.box(node, Vector3(2.12, 0.08, 1.77), Vector3(0, 2.29, 0), dark)
			for i in range(8):
				TrackProps.box(node, Vector3(0.23, 1.42, 0.055), Vector3(-0.87 + float(i) * 0.25, 1.56, 0.87), dark)
			TrackProps.box(node, Vector3(2.14, 0.055, 0.1), Vector3(0, 0.91, -0.6), cyan)
			TrackProps.box(node, Vector3(0.74, 0.54, 0.06), Vector3(0.64, 2.54, 0.91), dark)
			TrackProps.label(node, "▣", Vector3(0.64, 2.53, 0.95), Color(0.25, 1, 0.78), 43)
			TrackProps.sphere(node, 0.11, Vector3(-1.0, 2.85, 0.8), red)
			TrackProps.label(node, "SCANNING  /  DUCK", Vector3(0, 3.02, 0.88), Color(1, 0.34, 0.2), 29)
		"giant_suitcase", "moving_suitcase":
			node.avoid = Avoid.LANE
			node.display_name = "Moving Suitcase" if obstacle_kind == "moving_suitcase" else "Giant Suitcase"
			TrackProps.shape(node, Vector3(2.1, 2.7, 1.25), Vector3(0, 1.35, 0))
			var palette := [TrackProps.material("bag_tangerine", Color(0.98, 0.29, 0.08)), TrackProps.material("bag_magenta", Color(0.8, 0.1, 0.37)), TrackProps.material("bag_lime", Color(0.48, 0.76, 0.14))]
			var bag_mat: Material = palette[randi() % palette.size()]
			if obstacle_kind == "moving_suitcase":
				bag_mat = TrackProps.material("bag_mover", Color(0.95, 0.38, 0.07), 0.2, Color(0.24, 0.05, 0.0))
			TrackProps.box(node, Vector3(2.1, 2.45, 1.2), Vector3(0, 1.3, 0), bag_mat)
			TrackProps.box(node, Vector3(1.85, 0.12, 1.25), Vector3(0, 1.13, 0), yellow)
			for x in [-0.72, 0.72]:
				TrackProps.box(node, Vector3(0.15, 2.48, 1.24), Vector3(x, 1.31, 0), dark)
			TrackProps.box(node, Vector3(0.7, 0.14, 0.22), Vector3(0, 2.72, 0), dark)
			TrackProps.box(node, Vector3(0.1, 0.27, 0.12), Vector3(-0.29, 2.61, 0), steel)
			TrackProps.box(node, Vector3(0.1, 0.27, 0.12), Vector3(0.29, 2.61, 0), steel)
			TrackProps.box(node, Vector3(0.52, 0.36, 0.025), Vector3(-0.17, 1.67, 0.62), white)
			TrackProps.label(node, "✈", Vector3(-0.17, 1.68, 0.65), Color(0.14, 0.36, 0.5), 32)
			for side in [-0.7, 0.7]:
				TrackProps.cylinder(node, 0.16, 0.14, Vector3(side, 0.13, 0), dark).rotation.z = PI * 0.5
			if obstacle_kind == "moving_suitcase":
				node._moving = true
				node._move_speed = mover_scale
				TrackProps.label(node, "⇆", Vector3(0.5, 0.82, 0.63), Color(0.2, 1, 0.9), 47)
				TrackProps.box(node, Vector3(2.26, 0.035, 1.33), Vector3(0, 0.04, 0), cyan)
		"luggage_cart":
			node.avoid = Avoid.LANE
			node.display_name = "Luggage Cart"
			TrackProps.shape(node, Vector3(2.1, 2.55, 1.9), Vector3(0, 1.28, 0))
			TrackProps.box(node, Vector3(2.1, 0.2, 1.8), Vector3(0, 0.44, 0), steel)
			for x in [-0.95, 0.95]:
				TrackProps.box(node, Vector3(0.08, 1.9, 0.08), Vector3(x, 1.45, 0.8), steel)
			TrackProps.box(node, Vector3(2.05, 0.08, 0.08), Vector3(0, 2.36, 0.8), steel)
			for x in [-0.9, 0.9]:
				for z in [-0.7, 0.7]:
					TrackProps.cylinder(node, 0.23, 0.15, Vector3(x, 0.21, z), dark).rotation.z = PI * 0.5
			TrackProps.box(node, Vector3(1.5, 1.15, 1.2), Vector3(-0.1, 1.12, 0), TrackProps.material("bag_orange", Color(0.75, 0.24, 0.08)))
			TrackProps.box(node, Vector3(1.3, 0.85, 1.0), Vector3(0.2, 2.07, 0), TrackProps.material("bag_green", Color(0.14, 0.47, 0.33)))
			TrackProps.box(node, Vector3(0.65, 0.5, 0.7), Vector3(0.54, 1.52, 0.35), TrackProps.material("cart_purple", Color(0.48, 0.24, 0.76)))
			TrackProps.box(node, Vector3(1.3, 0.09, 1.23), Vector3(0.2, 2.06, 0), yellow)
		"divider":
			node.avoid = Avoid.LANE
			node.display_name = "Destination Divider"
			TrackProps.shape(node, Vector3(1.65, 2.6, 20.0), Vector3(0, 1.3, 0))
			TrackProps.box(node, Vector3(1.65, 2.6, 20.0), Vector3(0, 1.3, 0), TrackProps.material("divider_concrete", Color(0.52, 0.58, 0.57)))
			TrackProps.box(node, Vector3(1.7, 0.18, 20.1), Vector3(0, 2.5, 0), yellow)
			for z in [-8.0, -4.0, 0.0, 4.0, 8.0]:
				TrackProps.label(node, "❯❯", Vector3(0, 1.55, z + 0.85), Color(0.05, 0.12, 0.15), 40)
				TrackProps.box(node, Vector3(1.68, 0.12, 0.2), Vector3(0, 0.35, z), dark)
		"broken_roller":
			node.avoid = Avoid.JUMP
			node.display_name = "Broken Rollers"
			TrackProps.shape(node, Vector3(2.2, 0.15, 2.5), Vector3(0, -1.5, 0))
			TrackProps.box(node, Vector3(2.2, 0.1, 2.5), Vector3(0, -1.5, 0), TrackProps.material("pit_red", Color(0.16, 0.025, 0.025), 0.0, Color(0.2, 0.01, 0.0)))
			for x in [-0.9, 0.9]:
				TrackProps.box(node, Vector3(0.12, 0.3, 2.5), Vector3(x, -0.18, 0), yellow)
			for z in [-1.15, 1.15]:
				TrackProps.box(node, Vector3(2.15, 0.08, 0.13), Vector3(0, 0.05, z), yellow)
				for x in [-0.72, 0.72]:
					TrackProps.box(node, Vector3(0.2, 0.38, 0.2), Vector3(x, 0.18, z), amber)
			var sparks := CPUParticles3D.new()
			sparks.amount = 7
			sparks.lifetime = 0.45
			sparks.direction = Vector3.UP
			sparks.spread = 65.0
			sparks.initial_velocity_min = 0.6
			sparks.initial_velocity_max = 1.7
			sparks.gravity = Vector3(0, -3, 0)
			sparks.mesh = TrackProps.box_mesh(Vector3(0.035, 0.035, 0.035))
			sparks.material_override = amber
			sparks.position = Vector3(0.65, -0.12, 0.65)
			node.add_child(sparks)
			TrackProps.label(node, "!  GAP  !", Vector3(0, -0.36, 0), Color(1, 0.38, 0.08), 38)
	return node

func _ready() -> void:
	_home_x = position.x

func _process(delta: float) -> void:
	if _moving and lethal:
		_clock += delta * _move_speed
		position.x = _home_x + sin(_clock * 1.8) * 2.55

func disable() -> void:
	if not lethal:
		return
	lethal = false
	monitorable = false
	_moving = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation:z", 0.42, 0.22)
	tween.tween_property(self, "position:y", position.y - 0.4, 0.22)
	for child in get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = TrackProps.material("disabled", Color(0.24, 0.28, 0.3))
