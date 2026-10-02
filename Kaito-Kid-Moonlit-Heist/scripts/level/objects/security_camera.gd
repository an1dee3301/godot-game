class_name SecurityCamera
extends Node3D
## Sweeping surveillance camera with light, awareness, and card-disabling feedback.

signal spotted(player_position: Vector3)

var disabled_time := 0.0
var _sweep_deg := 100.0
var _view_distance := 12.0
var _time := 0.0
var _awareness := 0.0
var _alert_cooldown := 0.0
var _head: Node3D
var _lens: MeshInstance3D
var _cone: MeshInstance3D
var _spot: SpotLight3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _initialized := false


func _ready() -> void:
	add_to_group(KK.GROUP_MINIMAP)
	_build()
	_initialized = true


## Set full horizontal sweep angle and view range.
func setup(sweep_deg := 100.0, view_distance := 12.0) -> void:
	_sweep_deg = sweep_deg
	_view_distance = view_distance
	if _initialized:
		_update_range()


func minimap_icon() -> String:
	return "camera"


## A card interrupts the camera for ten seconds.
func take_card_hit(_from: Vector3) -> void:
	disabled_time = 10.0
	_awareness = 0.0
	_spot.visible = false
	_cone.visible = false
	_head.rotation.z = -0.35
	_sparks()


func _process(delta: float) -> void:
	_time += delta
	_alert_cooldown = maxf(_alert_cooldown - delta, 0.0)
	if disabled_time > 0.0:
		disabled_time = maxf(disabled_time - delta, 0.0)
		if disabled_time == 0.0:
			_spot.visible = true
			_cone.visible = true
			_head.rotation.z = 0.0
		return
	_head.rotation.y = sin(_time * 0.65) * deg_to_rad(_sweep_deg * 0.5)
	var player := KK.get_player(get_tree()) as PhantomThief
	var visible_score := 0.0
	if player != null and not player.is_dead:
		var eye := _head.global_position
		var target := player.aim_point()
		var to_player := target - eye
		var dist := to_player.length()
		if dist <= _view_distance and dist > 0.01:
			var forward := -_head.global_basis.z.normalized()
			var angle := rad_to_deg(acos(clampf(forward.dot(to_player.normalized()), -1.0, 1.0)))
			if angle < 31.0 and not SmokeCloud.point_in_smoke(get_tree(), target) and KK.has_line_of_sight(get_world_3d(), eye, target):
				visible_score = player.visibility_factor() * (1.5 - dist / _view_distance * 0.6)
	_awareness = clampf(_awareness + delta * (visible_score * 0.65 if visible_score > 0.0 else -0.45), 0.0, 1.0)
	var tint := Color(0.82, 0.93, 1.0).lerp(Color(1.0, 0.83, 0.14), clampf(_awareness * 2.0, 0, 1))
	if _awareness > 0.5:
		tint = Color(1.0, 0.83, 0.14).lerp(Color(1.0, 0.12, 0.12), (_awareness - 0.5) * 2.0)
	_ring_mat.albedo_color = tint
	_ring_mat.emission = tint
	_spot.light_color = tint
	if _awareness >= 1.0 and _alert_cooldown <= 0.0 and player != null:
		_alert_cooldown = 4.0
		KK.alert_guards(get_tree(), global_position, 30.0, player.global_position)
		spotted.emit(player.global_position)


func _update_range() -> void:
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.02
	cone_mesh.bottom_radius = _view_distance * tan(deg_to_rad(29.0))
	cone_mesh.height = _view_distance
	cone_mesh.radial_segments = 20
	_cone.mesh = cone_mesh
	_cone.position.z = -_view_distance * 0.5
	_spot.spot_range = _view_distance


func _build() -> void:
	var steel := KK.standard_material(Color(0.3, 0.36, 0.42), 0.31, 0.67)
	var dark := KK.standard_material(Color(0.05, 0.075, 0.11), 0.28, 0.6)
	_box(self, Vector3(0.28, 0.13, 0.35), Vector3(0, 0.08, 0.13), steel)
	_box(self, Vector3(0.09, 0.18, 0.35), Vector3(0, -0.08, -0.06), steel)
	_head = Node3D.new()
	_head.position = Vector3(0, -0.17, -0.27)
	_head.rotation.x = deg_to_rad(-30.0)
	add_child(_head)
	_box(_head, Vector3(0.45, 0.26, 0.58), Vector3.ZERO, steel)
	_box(_head, Vector3(0.37, 0.18, 0.10), Vector3(0, 0, -0.33), dark)
	var blue := KK.standard_material(Color(0.22, 0.48, 0.82), 0.08, 0.15)
	blue.emission_enabled = true
	blue.emission = Color(0.36, 0.76, 1.0)
	blue.emission_energy_multiplier = 0.6
	_lens = _sphere(_head, 0.105, Vector3(0, 0, -0.40), blue)
	_lens.scale.z = 0.45
	_ring_mat = KK.standard_material(Color(0.8, 0.92, 1), 0.2)
	_ring_mat.emission_enabled = true
	_ring_mat.emission = Color(0.8, 0.92, 1)
	_ring_mat.emission_energy_multiplier = 0.85
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.12
	ring_mesh.outer_radius = 0.15
	_ring = MeshInstance3D.new()
	_ring.mesh = ring_mesh
	_ring.material_override = _ring_mat
	_ring.position = Vector3(0, 0, -0.395)
	_ring.rotation.x = PI * 0.5
	_head.add_child(_ring)
	var cone_mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode blend_add, unshaded, cull_disabled, depth_draw_never; void fragment() { float fade = 1.0 - clamp(length(VERTEX) / 14.0, 0.0, 1.0); ALBEDO = vec3(0.32, 0.65, 1.0); EMISSION = ALBEDO * 0.15; ALPHA = 0.042 * fade; }"
	cone_mat.shader = shader
	_cone = MeshInstance3D.new()
	_cone.material_override = cone_mat
	_cone.rotation.x = PI * 0.5
	_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_head.add_child(_cone)
	_spot = SpotLight3D.new()
	_spot.spot_angle = 31.0
	_spot.light_energy = 0.7
	_spot.shadow_enabled = false
	_head.add_child(_spot)
	_update_range()
	var target := Area3D.new()
	target.name = "CardTarget"
	target.collision_layer = KK.LAYER_ENEMY
	target.collision_mask = 0
	target.set_meta("card_target", self)
	_head.add_child(target)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.52, 0.33, 0.68)
	shape.shape = box
	target.add_child(shape)


func _sparks() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mat := KK.standard_material(Color(1.0, 0.75, 0.23), 0.15)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.5, 0.05)
	mat.emission_energy_multiplier = 4.0
	for i in 9:
		var spark := _sphere(self, 0.025, _head.position, mat)
		var a := TAU * float(i) / 9.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(spark, "position", spark.position + Vector3(cos(a) * 0.5, sin(a) * 0.5, -0.3), 0.4)
		tw.tween_property(spark, "scale", Vector3.ZERO, 0.4)
		tw.chain().tween_callback(spark.queue_free)


func _sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node
