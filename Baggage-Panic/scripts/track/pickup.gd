class_name Pickup
extends Area3D
## A collectible. collision_layer = BP.LAYER_PICKUP, in group "pickup". OWNER: agent B.

enum Type { TAG, PASSPORT, PRIORITY, FRAGILE }

var type := Type.TAG
var collected := false
var _time := 0.0
var _base_y := 0.0
var _visual: Node3D

static func _halo(color: Color, key: String) -> StandardMaterial3D:
	var mat := TrackProps.material(key, Color(color.r, color.g, color.b, 0.17), 0.0, color * 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	return mat

func _init() -> void:
	collision_layer = BP.LAYER_PICKUP
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("pickup")

static func make(pickup_type: Type) -> Pickup:
	var node := Pickup.new()
	node.type = pickup_type
	TrackProps.shape(node, Vector3(0.85, 0.85, 0.55), Vector3.ZERO)
	var visual := Node3D.new()
	node._visual = visual
	node.add_child(visual)
	var glow_color := Color(1.0, 0.72, 0.1)
	match pickup_type:
		Type.TAG:
			TrackProps.box(visual, Vector3(0.62, 0.87, 0.06), Vector3.ZERO, TrackProps.material("tag_gold", Color(1, 0.77, 0.12), 0.12, Color(0.22, 0.12, 0)))
			TrackProps.box(visual, Vector3(0.4, 0.18, 0.07), Vector3(0, -0.13, 0.045), TrackProps.material("tag_mark", Color(0.13, 0.13, 0.11)))
			TrackProps.cylinder(visual, 0.07, 0.08, Vector3(0, 0.28, 0.04), TrackProps.material("tag_eye", Color(0.18, 0.16, 0.1))).rotation.x = PI * 0.5
			TrackProps.box(visual, Vector3(0.035, 0.29, 0.035), Vector3(0, 0.52, 0), TrackProps.material("tag_string", Color(0.95, 0.9, 0.7)))
		Type.PASSPORT:
			glow_color = Color(0.3, 0.61, 1.0)
			TrackProps.box(visual, Vector3(0.68, 0.88, 0.11), Vector3.ZERO, TrackProps.material("passport_navy", Color(0.035, 0.07, 0.27), 0.3))
			TrackProps.box(visual, Vector3(0.56, 0.76, 0.02), Vector3(0, 0, 0.07), TrackProps.material("passport_border", Color(0.86, 0.63, 0.21), 0.6, Color(0.15, 0.08, 0.01)))
			TrackProps.label(visual, "✈", Vector3(0, 0.05, 0.09), Color(1, 0.79, 0.3), 39)
			TrackProps.label(visual, "PASSPORT", Vector3(0, -0.27, 0.09), Color(1, 0.78, 0.3), 14)
		Type.PRIORITY:
			glow_color = Color(1.0, 0.15, 0.25)
			TrackProps.box(visual, Vector3(0.95, 0.56, 0.06), Vector3.ZERO, TrackProps.material("priority_red", Color(0.95, 0.12, 0.11), 0.1, Color(0.28, 0.01, 0.01)))
			TrackProps.label(visual, "★", Vector3(-0.27, 0, 0.06), Color.WHITE, 31)
			TrackProps.label(visual, "PRIORITY", Vector3(0.18, 0, 0.06), Color.WHITE, 16)
		Type.FRAGILE:
			glow_color = Color(1.0, 0.2, 0.16)
			TrackProps.box(visual, Vector3(0.88, 0.65, 0.06), Vector3.ZERO, TrackProps.material("fragile_white", Color(0.94, 0.94, 0.9)))
			TrackProps.box(visual, Vector3(0.9, 0.08, 0.07), Vector3(0, 0.28, 0), TrackProps.material("fragile_red", Color(0.9, 0.08, 0.09), 0.0, Color(0.22, 0, 0)))
			TrackProps.label(visual, "♧", Vector3(-0.25, -0.06, 0.06), Color(0.9, 0.08, 0.09), 29)
			TrackProps.label(visual, "FRAGILE", Vector3(0.16, -0.06, 0.06), Color(0.9, 0.08, 0.09), 16)
	TrackProps.sphere(visual, 0.62, Vector3.ZERO, _halo(glow_color, "pickup_halo_%d" % pickup_type))
	return node

func _ready() -> void:
	_base_y = position.y

func _process(delta: float) -> void:
	if collected:
		return
	_time += delta
	position.y = _base_y + sin(_time * 3.2) * 0.13
	if is_instance_valid(_visual):
		_visual.rotation.y += delta * 2.1

func value() -> int:
	match type:
		Type.PASSPORT:
			return 50
		Type.PRIORITY, Type.FRAGILE:
			return 25
	return 10

func weight() -> float:
	match type:
		Type.TAG:
			return 0.02
		Type.PASSPORT:
			return 0.06
	return 0.0

func collect() -> void:
	if collected:
		return
	collected = true
	monitorable = false
	var burst := CPUParticles3D.new()
	burst.amount = 12
	burst.lifetime = 0.35
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.direction = Vector3.UP
	burst.spread = 180.0
	burst.initial_velocity_min = 2.0
	burst.initial_velocity_max = 4.0
	burst.gravity = Vector3(0, -4, 0)
	burst.mesh = TrackProps.box_mesh(Vector3(0.065, 0.065, 0.065))
	burst.position = Vector3.ZERO
	add_child(burst)
	burst.emitting = true
	var tween := create_tween()
	tween.set_parallel(true)
	if is_instance_valid(_visual):
		tween.tween_property(_visual, "scale", Vector3.ONE * 1.7, 0.17)
	tween.tween_property(self, "position:y", position.y + 0.65, 0.17)
	tween.set_parallel(false)
	tween.tween_interval(0.4)
	tween.tween_callback(queue_free)
