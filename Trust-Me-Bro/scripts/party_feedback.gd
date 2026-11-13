extends Node3D
## Short lived, geometry-only game feedback. No textures or generated media.
const MAX_BURSTS: int = 44
var _materials: Dictionary = {}

func emit_event(at: Vector3, color: Color, event: String, intensity: float = 1.0) -> void:
	if not is_inside_tree():
		return
	var strength: float = clampf(intensity, 0.35, 1.8)
	match event:
		"jump":
			_ring(at + Vector3.DOWN * 0.84, color.lightened(0.65), 0.45, 0.78, 0.23)
			_dust(at + Vector3.DOWN * 0.82, 5, strength * 0.65)
		"land":
			_ring(at + Vector3.DOWN * 0.84, Color("fff7d6"), 0.3, 0.8 + strength * 0.32, 0.30)
			_dust(at + Vector3.DOWN * 0.82, 6, strength)
		"shove", "hit":
			_starburst(at + Vector3.UP * 0.12, Color("fff3a8") if event == "hit" else color.lightened(0.55), strength)
		"dive":
			_ring(at + Vector3.DOWN * 0.78, color.lightened(0.65), 0.4, 0.95, 0.22)
			_dust(at + Vector3.DOWN * 0.78, 4, 0.7)
		"fall":
			_starburst(at + Vector3.UP * 0.18, Color("fff4d4"), 0.65)
		"emote":
			_sparkle(at + Vector3.UP * 1.35, Color("fff3a8"))

func popup_score(at: Vector3, points: int, color: Color) -> void:
	var burst: Node3D = _burst(at + Vector3.UP * 1.5)
	var label: Label3D = Label3D.new()
	label.text = ("+%d" % points) if points > 0 else ("%d" % points)
	label.font_size = 76
	label.pixel_size = 0.009
	label.outline_size = 16
	label.outline_modulate = Color("193349")
	label.modulate = Color("ffdf73") if points > 0 else Color("ff9b9e")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	burst.add_child(label)
	label.scale = Vector3.ONE * 0.45
	var tween: Tween = burst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(burst, "position:y", burst.position.y + 1.1, 1.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.7)
	tween.chain().tween_callback(burst.queue_free)
	_starburst(at + Vector3.UP * 0.5, color.lightened(0.4), 0.7)

func clear() -> void:
	for child: Node in get_children():
		child.queue_free()

func _burst(at: Vector3) -> Node3D:
	if get_child_count() >= MAX_BURSTS:
		get_child(0).free()
	var burst: Node3D = Node3D.new()
	add_child(burst)
	burst.global_position = at
	return burst

func _material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.roughness = 1.0
	_materials[key] = mat
	return mat

func _mesh(parent: Node3D, shape: Mesh, color: Color) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = _material(color)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh

func _ring(at: Vector3, color: Color, start: float, finish: float, duration: float) -> void:
	var burst: Node3D = _burst(at)
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.93
	torus.outer_radius = 1.0
	torus.rings = 24
	torus.ring_segments = 6
	var ring: MeshInstance3D = _mesh(burst, torus, color)
	ring.scale = Vector3(start, 0.25, start)
	var tween: Tween = burst.create_tween()
	tween.tween_property(ring, "scale", Vector3(finish, 0.01, finish), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(burst.queue_free)

func _dust(at: Vector3, count: int, strength: float) -> void:
	var burst: Node3D = _burst(at)
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.radial_segments = 8
	sphere.rings = 4
	var tween: Tween = burst.create_tween()
	tween.set_parallel(true)
	for i: int in count:
		var angle: float = float(i) / count * TAU + at.x * 0.7
		var direction: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var puff: MeshInstance3D = _mesh(burst, sphere, Color("fff1d4"))
		puff.position = direction * 0.24
		puff.scale = Vector3.ONE * (0.7 + float(i % 3) * 0.18)
		var finish: Vector3 = direction * (0.5 + strength * 0.5) + Vector3.UP * (0.08 + float(i % 2) * 0.08)
		tween.tween_property(puff, "position", finish, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(puff, "scale", Vector3.ZERO, 0.26).set_delay(0.10)
	tween.chain().tween_callback(burst.queue_free)

func _starburst(at: Vector3, color: Color, strength: float) -> void:
	var burst: Node3D = _burst(at)
	var wedge: PrismMesh = PrismMesh.new()
	wedge.size = Vector3(0.13, 0.34, 0.08)
	var tween: Tween = burst.create_tween()
	tween.set_parallel(true)
	for i: int in 6:
		var angle: float = float(i) * TAU / 6.0
		var direction: Vector3 = Vector3(cos(angle), sin(angle), 0.25).normalized()
		var spike: MeshInstance3D = _mesh(burst, wedge, color)
		spike.position = direction * 0.23
		spike.rotation.z = angle - PI * 0.5
		spike.scale = Vector3.ONE * strength
		tween.tween_property(spike, "position", direction * (0.45 + strength * 0.25), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spike, "scale", Vector3.ZERO, 0.15).set_delay(0.07)
	tween.chain().tween_callback(burst.queue_free)

func _sparkle(at: Vector3, color: Color) -> void:
	var burst: Node3D = _burst(at)
	var shape: PrismMesh = PrismMesh.new()
	shape.size = Vector3(0.15, 0.3, 0.08)
	for side: float in [-1.0, 1.0]:
		var sparkle: MeshInstance3D = _mesh(burst, shape, color)
		sparkle.position = Vector3(side * 0.36, 0.0, 0.0)
		sparkle.rotation.z = side * 0.5
	var tween: Tween = burst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(burst, "position:y", burst.position.y + 0.28, 0.34)
	tween.tween_property(burst, "scale", Vector3.ZERO, 0.18).set_delay(0.16)
	tween.chain().tween_callback(burst.queue_free)
