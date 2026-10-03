extends RefCounted
## Apron wind indicator: six-metre mast, 3.6 m open tapered textile cone.
## Sock streams across +X so its full silhouette reads through the terminal glass.

const DK = preload("res://scripts/world/design_kit.gd")
const SIG = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "AirfieldWindsock"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colours: Array[Color] = [Color(0.94, 0.69, 0.16), DK.CREAM, DK.SAGE, DK.CHARCOAL]
	var accents: Array[Color] = [DK.CHARCOAL, DK.CLAY, DK.CHARCOAL, Color(0.78, 0.6, 0.34)]
	var body: StandardMaterial3D = DK.paint(colours[scheme])
	var accent: StandardMaterial3D = DK.paint(accents[scheme])
	var steel: StandardMaterial3D = DK.metal()
	var cream: StandardMaterial3D = DK.paint(DK.CREAM)
	var orange: StandardMaterial3D = DK.paint(Color(0.86, 0.27, 0.08))
	var glow: StandardMaterial3D = DK.washi(Color(1.0, 0.83, 0.56), 2.0, "windsock_base")
	# Honed stone footing, recessed perimeter light and a rounded cast-metal plinth.
	DK.rbox(root, Vector3(1.18, 0.18, 1.18), Vector3(0.0, 0.09, 0.0), DK.stone(), 0.075)
	DK.rbox(root, Vector3(0.94, 0.045, 0.94), Vector3(0.0, 0.2, 0.0), glow, 0.06, false)
	DK.rbox(root, Vector3(1.02, 0.16, 1.02), Vector3(0.0, 0.3, 0.0), body, 0.07)
	DK.add(root, _turned(0.28, 0.24), accent, Vector3(0.0, 0.38, 0.0))
	DK.add(root, _turned(0.18, 0.18), steel, Vector3(0.0, 0.62, 0.0))
	for x: float in [-0.37, 0.37]:
		for z: float in [-0.37, 0.37]:
			DK.add(root, _turned(0.045, 0.035), DK.brass(), Vector3(x, 0.38, z), Vector3.ZERO, false)
	# Alternating broad bands follow a gently tapered, stepped mast.
	for i: int in 10:
		var height: float = 0.5
		var radius: float = 0.105 - float(i) * 0.003
		DK.add(root, _turned(radius, height), cream if i % 2 == 0 else orange, Vector3(0.0, 0.76 + float(i) * height, 0.0))
	DK.add(root, _turned(0.13, 0.09), steel, Vector3(0.0, 3.2, 0.0))
	DK.add(root, _turned(0.12, 0.1), DK.brass(), Vector3(0.0, 5.66, 0.0))
	# Swivel bearing and offset yoke leave the hoop mouth completely open.
	DK.add(root, _turned(0.11, 0.36), steel, Vector3(0.0, 5.76, 0.0))
	_bar(root, Vector3(0.0, 6.02, 0.0), Vector3(0.28, 6.02, 0.0), 0.035, steel)
	_bar(root, Vector3(0.28, 6.02, 0.0), Vector3(0.28, 6.15, 0.0), 0.025, steel)
	_bar(root, Vector3(0.0, 5.48, 0.0), Vector3(0.28, 5.25, 0.0), 0.025, steel)
	var mouth: MeshInstance3D = DK.add(root, _ring(0.454, 0.022), steel, Vector3(0.28, 5.7, 0.0))
	mouth.rotation_degrees.z = -90.0
	# Five sewn bands; radius never closes to a point, so the exhaust is hollow too.
	for band: int in 5:
		var from_t: float = float(band) / 5.0
		var to_t: float = float(band + 1) / 5.0
		DK.add(root, _cloth_mesh(from_t, to_t), _cloth(band % 2 == 0), Vector3.ZERO)
	for hem: int in 6:
		var t: float = float(hem) / 5.0
		DK.add(root, _cloth_mesh(maxf(0.0, t - 0.004), minf(1.0, t + 0.004), 0.009), _cloth(hem % 2 == 0), Vector3.ZERO)
	# Two continuous reinforced seams follow the soft, slightly rippled fabric.
	for angle: float in [0.35, 3.49]:
		DK.add(root, _cloth_mesh(0.0, 1.0, 0.005, angle, angle + 0.015), DK.fabric(DK.LINEN, "windsock_stitch"), Vector3.ZERO, Vector3.ZERO, false)
	# Shielded amber obstruction beacon, with a black cap and brass retaining rim.
	DK.add(root, _turned(0.13, 0.08), steel, Vector3(0.0, 6.12, 0.0))
	DK.add(root, _turned(0.105, 0.18), DK.washi(Color(1.0, 0.43, 0.06), 3.5, "windsock_beacon"), Vector3(0.0, 6.2, 0.0), Vector3.ZERO, false)
	DK.add(root, _turned(0.13, 0.035), DK.brass(), Vector3(0.0, 6.38, 0.0), Vector3.ZERO, false)
	# A generous multilingual identifier on the front of the service pedestal.
	DK.rbox(root, Vector3(2.4, 1.18, 0.09), Vector3(0.0, 1.25, 0.24), steel, 0.06)
	DK.rbox(root, Vector3(2.26, 0.045, 0.018), Vector3(0.0, 1.76, 0.294), accent, 0.009, false)
	var label: Label3D = Label3D.new()
	label.font = SIG.font()
	label.text = "WIND\n風向 · 风向 · Gió\nVent · Viento"
	label.font_size = 64
	label.pixel_size = 0.004
	label.outline_size = 0
	label.modulate = DK.CREAM
	label.position = Vector3(0.0, 1.24, 0.294)
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(label)
	var light: OmniLight3D = OmniLight3D.new()
	light.position = Vector3(0.0, 0.38, 0.0)
	light.light_color = Color(1.0, 0.83, 0.56)
	light.light_energy = 0.45
	light.omni_range = 2.0
	light.shadow_enabled = false
	light.distance_fade_enabled = true
	light.distance_fade_begin = 35.0
	light.distance_fade_length = 15.0
	root.add_child(light)
	return root


static func _turned(radius: float, height: float) -> ArrayMesh:
	var bevel: float = minf(0.012, height * 0.15)
	return DK.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(radius - bevel, 0.0), Vector2(radius, bevel), Vector2(radius, height - bevel), Vector2(radius - bevel, height), Vector2(0.0, height)]), 24)


static func _bar(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var node: MeshInstance3D = DK.add(parent, _turned(radius, a.distance_to(b)), material, a)
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())


static func _ring(radius: float, tube: float) -> ArrayMesh:
	var profile: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var angle: float = TAU * float(i) / 12.0
		profile.append(Vector2(radius + tube * cos(angle), tube * sin(angle)))
	return DK.lathe(profile, 48)


static func _cloth(is_orange: bool) -> StandardMaterial3D:
	var key: String = "orange" if is_orange else "cream"
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = DK.fabric(Color(0.95, 0.31, 0.07) if is_orange else DK.CREAM, "windsock_" + key).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


static func _point(t: float, angle: float, lift: float) -> Vector3:
	var radius: float = lerpf(0.45, 0.145, t) + lift
	radius *= 1.0 + 0.018 * sin(angle * 8.0 + t * 22.0) * sin(t * PI)
	return Vector3(0.28 + 3.6 * t, 5.7 - 0.52 * t * t + radius * cos(angle), 0.18 * sin(t * PI) + radius * sin(angle))


static func _cloth_mesh(from_t: float, to_t: float, lift: float = 0.0, angle_from: float = 0.0, angle_to: float = TAU) -> ArrayMesh:
	var key: String = "cloth:%s:%s:%s:%s:%s" % [from_t, to_t, lift, angle_from, angle_to]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int = maxi(2, int((to_t - from_t) * 50.0))
	var sectors: int = 40 if angle_to - angle_from > 1.0 else 1
	for j: int in rings:
		var t0: float = lerpf(from_t, to_t, float(j) / float(rings))
		var t1: float = lerpf(from_t, to_t, float(j + 1) / float(rings))
		for i: int in sectors:
			var a0: float = lerpf(angle_from, angle_to, float(i) / float(sectors))
			var a1: float = lerpf(angle_from, angle_to, float(i + 1) / float(sectors))
			var coordinates: Array[Vector2] = [Vector2(t0, a0), Vector2(t1, a0), Vector2(t0, a1), Vector2(t0, a1), Vector2(t1, a0), Vector2(t1, a1)]
			for coordinate: Vector2 in coordinates:
				var t: float = coordinate.x
				var a: float = coordinate.y
				var along: Vector3 = _point(t + 0.001, a, lift) - _point(t - 0.001, a, lift)
				var around: Vector3 = _point(t, a + 0.001, lift) - _point(t, a - 0.001, lift)
				st.set_normal(around.cross(along).normalized())
				st.set_uv(Vector2(t * 3.6, a / TAU))
				st.add_vertex(_point(t, a, lift))
	st.generate_tangents()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh
