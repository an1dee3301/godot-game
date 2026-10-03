extends RefCounted
## A freestanding airport ramen counter; +Z is the guest side.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "RamenStall"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var colours: Array[Color] = [DesignKit.INDIGO, DesignKit.SAGE, DesignKit.CLAY, DesignKit.WALNUT]
	var accent: Color = colours[choice]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var steel: StandardMaterial3D = DesignKit.metal()
	var brass: StandardMaterial3D = DesignKit.brass()
	var linen: StandardMaterial3D = _noren_material(accent, choice)
	var stone: StandardMaterial3D = DesignKit.stone()
	var ceramic: StandardMaterial3D = DesignKit.paint(DesignKit.CREAM if choice % 2 == 0 else accent.lightened(0.25), 0.24)
	# Flush floor contact, recessed toe kick and a guest-side vertical tambour.
	DesignKit.rbox(root, Vector3(3.72, 0.12, 1.1), Vector3(0.0, 0.06, 0.26), steel, 0.04)
	DesignKit.rbox(root, Vector3(3.62, 0.81, 0.94), Vector3(0.0, 0.525, 0.26), stone, 0.07)
	var slats: Array[Transform3D] = []
	for i: int in 26:
		slats.append(Transform3D(Basis.IDENTITY, Vector3(-1.75 + float(i) * 0.14, 0.54, 0.745)))
	DesignKit.add(root, _joined("counter_tambour", DesignKit.rounded_box(Vector3(0.10, 0.70, 0.055), 0.025), slats), oak, Vector3.ZERO)
	DesignKit.rbox(root, Vector3(3.92, 0.10, 1.20), Vector3(0.0, 0.99, 0.29), oak, 0.045)
	DesignKit.rbox(root, Vector3(3.64, 0.018, 0.025), Vector3(0.0, 0.91, 0.79), brass, 0.008, false)
	# Open service aisle, back cabinet and crafted timber canopy.
	DesignKit.rbox(root, Vector3(3.55, 0.87, 0.43), Vector3(0.0, 0.435, -1.03), walnut, 0.045)
	DesignKit.rbox(root, Vector3(3.64, 0.075, 0.52), Vector3(0.0, 0.905, -1.03), stone, 0.032)
	for x: float in [-1.18, 0.0, 1.18]:
		DesignKit.rbox(root, Vector3(1.10, 0.65, 0.035), Vector3(x, 0.47, -0.802), oak, 0.02)
		DesignKit.rbox(root, Vector3(0.26, 0.025, 0.035), Vector3(x, 0.69, -0.767), brass, 0.01, false)
	for x: float in [-1.84, 1.84]:
		DesignKit.rbox(root, Vector3(0.13, 3.36, 0.13), Vector3(x, 1.68, -0.47), walnut, 0.032)
		DesignKit.rbox(root, Vector3(0.16, 0.13, 0.16), Vector3(x, 0.065, -0.47), steel, 0.025)
	DesignKit.rbox(root, Vector3(4.0, 0.14, 1.73), Vector3(0.0, 3.43, -0.42), walnut, 0.065)
	DesignKit.rbox(root, Vector3(3.80, 0.045, 1.54), Vector3(0.0, 3.337, -0.42), oak, 0.02)
	DesignKit.rbox(root, Vector3(3.60, 0.025, 0.035), Vector3(0.0, 3.308, -0.08), DesignKit.washi(DesignKit.CREAM, 1.3, "ramen_underlight"), 0.01, false)
	# Large, three-line international fascia (all six terminal languages).
	DesignKit.rbox(root, Vector3(3.84, 0.80, 0.10), Vector3(0.0, 2.94, 0.40), walnut, 0.045)
	DesignKit.rbox(root, Vector3(3.68, 0.70, 0.035), Vector3(0.0, 2.94, 0.464), DesignKit.washi(DesignKit.CREAM, 0.45, "ramen_fascia"), 0.025, false)
	_text(root, "RAMEN", Vector3(0.0, 3.14, 0.487), 128, 0.0027, DesignKit.CHARCOAL)
	_text(root, "ラーメン  ·  拉面  ·  Mì ramen", Vector3(0.0, 2.92, 0.487), 76, 0.0027, DesignKit.CHARCOAL)
	_text(root, "Nouilles ramen  ·  Fideos ramen", Vector3(0.0, 2.72, 0.487), 68, 0.0027, DesignKit.CHARCOAL)
	# Four loose noren drops; actual folds and scalloped hems, not solid slabs.
	DesignKit.rbox(root, Vector3(2.69, 0.035, 0.035), Vector3(0.0, 2.56, 0.34), brass, 0.012, false)
	for i: int in 4:
		var x: float = (float(i) - 1.5) * 0.65
		DesignKit.add(root, _cloth(), linen, Vector3(x, 1.99, 0.38), Vector3.ZERO, false)
		DesignKit.rbox(root, Vector3(0.58, 0.022, 0.013), Vector3(x, 2.02, 0.397), linen, 0.006, false)
	_text(root, "ラーメン", Vector3(0.0, 2.30, 0.423), 160, 0.0033, DesignKit.CREAM)
	for side: float in [-1.0, 1.0]:
		_lantern(root, Vector3(side * 1.61, 1.94, 0.32), walnut, steel, choice)
	# Four 760 mm stools with rounded linen pads and brass foot rings.
	for i: int in 4:
		var x: float = (float(i) - 1.5) * 0.90
		_stool(root, Vector3(x, 0.0, 1.16), oak, steel, brass, linen)
	# Bowls sit on dark serving trays; soup, egg, nori and chopsticks are modelled.
	for i: int in 3:
		var x: float = (float(i) - 1.0) * 1.08
		_bowl(root, Vector3(x, 1.045, 0.39), ceramic, walnut, choice, i)
	# A turned ceramic water pitcher on the rear worktop.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.075, 0.0), Vector2(0.10, 0.07), Vector2(0.10, 0.20), Vector2(0.065, 0.28), Vector2(0.065, 0.30), Vector2(0.051, 0.30), Vector2(0.051, 0.26)])), ceramic, Vector3(1.21, 0.943, -0.98))
	DesignKit.rbox(root, Vector3(0.033, 0.15, 0.08), Vector3(1.33, 1.10, -0.98), ceramic, 0.015, false)
	return root


static func _text(parent: Node3D, caption: String, at: Vector3, size: int, pixel: float, colour: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixel
	label.modulate = colour
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _stool(parent: Node3D, at: Vector3, oak: Material, steel: Material, brass: Material, linen: Material) -> void:
	var legs: Array[Transform3D] = []
	for angle: float in [45.0, 135.0, 225.0, 315.0]:
		var a: float = deg_to_rad(angle)
		legs.append(Transform3D(Basis.IDENTITY, Vector3(cos(a) * 0.18, 0.35, sin(a) * 0.18)))
	DesignKit.add(parent, _joined("stool_legs", DesignKit.rounded_box(Vector3(0.048, 0.70, 0.048), 0.018), legs), steel, at)
	DesignKit.add(parent, _ring(0.223, 0.014), brass, at + Vector3(0.0, 0.255, 0.0), Vector3.ZERO, false)
	DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.70), Vector2(0.23, 0.70), Vector2(0.25, 0.718), Vector2(0.25, 0.746), Vector2(0.23, 0.76), Vector2(0.0, 0.76)])), oak, at)
	DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.76), Vector2(0.20, 0.76), Vector2(0.225, 0.774), Vector2(0.21, 0.798), Vector2(0.0, 0.806)])), linen, at)


static func _lantern(parent: Node3D, at: Vector3, walnut: Material, steel: Material, choice: int) -> void:
	DesignKit.rbox(parent, Vector3(0.016, 0.49, 0.016), at + Vector3(0.0, 0.85, 0.0), steel, 0.006, false)
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.19, 0.07), Vector2(0.22, 0.19), Vector2(0.22, 0.39), Vector2(0.19, 0.52), Vector2(0.12, 0.59), Vector2(0.0, 0.59)])
	DesignKit.add(parent, DesignKit.lathe(profile, 32), DesignKit.washi(DesignKit.CREAM if choice % 2 == 0 else Color(1.0, 0.83, 0.61), 1.7, "ramen_lantern_%d" % (choice % 2)), at)
	var ribs: Array[Transform3D] = []
	for i: int in 7:
		var height: float = 0.095 + float(i) * 0.065
		var radius: float = 0.22
		if height < 0.19:
			radius = lerpf(0.19, 0.22, (height - 0.07) / 0.12)
		elif height > 0.39:
			radius = lerpf(0.22, 0.19, (height - 0.39) / 0.13)
		ribs.append(Transform3D(Basis.from_scale(Vector3(radius / 0.218, 1.0, radius / 0.218)), Vector3(0.0, height, 0.0)))
	DesignKit.add(parent, _joined("lantern_ribs", _ring(0.218, 0.004), ribs), walnut, at, Vector3.ZERO, false)
	for y: float in [0.01, 0.59]:
		DesignKit.add(parent, _ring(0.12, 0.015), steel, at + Vector3(0.0, y, 0.0), Vector3.ZERO, false)


static func _bowl(parent: Node3D, at: Vector3, ceramic: Material, walnut: Material, choice: int, index: int) -> void:
	DesignKit.rbox(parent, Vector3(0.61, 0.025, 0.45), at + Vector3(0.0, 0.0125, 0.0), walnut, 0.04, false)
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.025), Vector2(0.075, 0.025), Vector2(0.08, 0.05), Vector2(0.12, 0.08), Vector2(0.19, 0.18), Vector2(0.205, 0.205), Vector2(0.201, 0.215), Vector2(0.187, 0.215), Vector2(0.17, 0.18), Vector2(0.10, 0.085), Vector2(0.0, 0.064)])
	DesignKit.add(parent, DesignKit.lathe(profile, 32), ceramic, at, Vector3.ZERO, false)
	DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.181), Vector2(0.175, 0.181)]), 32), DesignKit.paint(Color(0.58, 0.32, 0.12), 0.18), at, Vector3.ZERO, false)
	# Pale noodle curls and freshly cut scallions break up the glossy broth surface.
	var noodles: Array[Transform3D] = []
	for i: int in 5:
		noodles.append(Transform3D(Basis.from_scale(Vector3(1.0, 0.55, 0.65)), Vector3(-0.055 + float(i) * 0.021, 0.187 + float(i % 2) * 0.004, -0.025)))
	DesignKit.add(parent, _joined("noodle_curls", _ring(0.046, 0.003), noodles), DesignKit.paint(Color(0.92, 0.79, 0.48), 0.48), at, Vector3.ZERO, false)
	var scallions: Array[Transform3D] = []
	for i: int in 6:
		scallions.append(Transform3D(Basis(Vector3.UP, float(i) * 0.7), Vector3(-0.01 + float(i % 3) * 0.026, 0.198, -0.086 + float(i / 3) * 0.023)))
	DesignKit.add(parent, _joined("scallions", DesignKit.rounded_box(Vector3(0.017, 0.008, 0.025), 0.003), scallions), DesignKit.paint(DesignKit.SAGE.darkened(0.2)), at, Vector3.ZERO, false)
	var egg: MeshInstance3D = DesignKit.add(parent, _ring(0.036, 0.019), DesignKit.paint(DesignKit.CREAM, 0.38), at + Vector3(0.05, 0.192, 0.035), Vector3.ZERO, false)
	egg.scale = Vector3(1.0, 0.45, 1.25)
	DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.027, 0.0)]), 16), DesignKit.paint(DesignKit.OCHRE, 0.35), at + Vector3(0.05, 0.202, 0.035), Vector3.ZERO, false)
	var nori: MeshInstance3D = DesignKit.rbox(parent, Vector3(0.085, 0.115, 0.009), at + Vector3(-0.085, 0.223, -0.035), DesignKit.fabric(Color(0.18, 0.24, 0.13), "ramen_nori"), 0.004, false)
	nori.rotation_degrees = Vector3(-22.0, 12.0 + float(choice) * 6.0, -14.0)
	for z: float in [0.12, 0.148]:
		var stick: MeshInstance3D = DesignKit.rbox(parent, Vector3(0.34, 0.009, 0.009), at + Vector3(0.025, 0.235, z), DesignKit.wood(), 0.003, false)
		stick.rotation_degrees.y = -12.0 + float(index) * 8.0
	DesignKit.add(parent, _steam(), _steam_material(), at + Vector3(0.0, 0.23, 0.0), Vector3(0.0, float(index) * 35.0, 0.0), false)


static func _joined(key: String, mesh: Mesh, transforms: Array[Transform3D]) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for transform: Transform3D in transforms:
		st.append_from(mesh, 0, transform)
	var result: ArrayMesh = st.commit()
	_meshes[key] = result
	return result


static func _ring(radius: float, thickness: float) -> ArrayMesh:
	var profile: PackedVector2Array = PackedVector2Array()
	for i: int in 9:
		var a: float = TAU * float(i) / 8.0
		profile.append(Vector2(radius + cos(a) * thickness, sin(a) * thickness))
	return DesignKit.lathe(profile, 24)


static func _cloth() -> ArrayMesh:
	if _meshes.has("noren"):
		return _meshes["noren"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in 8:
		for col: int in 24:
			for offset: Vector2i in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				var u: float = float(col + offset.x) / 24.0
				var v: float = float(row + offset.y) / 8.0
				st.set_uv(Vector2(u, v))
				st.add_vertex(Vector3((u - 0.5) * 0.62, v * 0.55 + (1.0 - v) * 0.014 * cos(u * TAU * 2.0), sin(u * TAU * 3.0) * 0.019 * (1.0 - v * 0.5)))
	st.generate_normals()
	st.generate_tangents()
	var mesh: ArrayMesh = st.commit()
	_meshes["noren"] = mesh
	return mesh


static func _noren_material(accent: Color, choice: int) -> StandardMaterial3D:
	var key: String = "noren_%d" % choice
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = DesignKit.fabric(accent, "ramen_noren_%d" % choice).duplicate() as StandardMaterial3D
	# The folded cloth is a thin surface, visible from both guest and service sides.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


static func _steam() -> ArrayMesh:
	if _meshes.has("steam"):
		return _meshes["steam"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for strand: int in 3:
		for row: int in 12:
			for offset: Vector2i in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				var t: float = float(row + offset.y) / 12.0
				var width: float = (0.007 + t * 0.026) * (float(offset.x) * 2.0 - 1.0)
				var x: float = (float(strand) - 1.0) * 0.075 + sin(t * TAU * 1.2 + float(strand)) * 0.036 + width
				st.set_color(Color(0.96, 0.93, 0.85, sin(t * PI) * 0.24))
				st.add_vertex(Vector3(x, t * 0.46, sin(t * PI + float(strand)) * 0.027))
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["steam"] = mesh
	return mesh


static func _steam_material() -> StandardMaterial3D:
	if _materials.has("steam"):
		return _materials["steam"] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials["steam"] = material
	return material
