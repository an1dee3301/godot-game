extends RefCounted
## Museum airliner, suspended above honed limestone in a walnut and glass vitrine.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "AircraftModel"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var tones: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.INDIGO, Kit.OCHRE]
	var choice: int = posmod(variant, 4)
	var accent: Color = tones[choice]
	var walnut: StandardMaterial3D = Kit.wood(Kit.WALNUT, "aircraft_walnut")
	var brass: StandardMaterial3D = Kit.brass()
	var steel: StandardMaterial3D = Kit.metal()
	var stone: StandardMaterial3D = Kit.stone()
	# Recessed toe, softly radiused cabinet, brass reveal and inset stone deck.
	Kit.rbox(root, Vector3(3.12, 0.10, 2.22), Vector3(0, 0.05, 0), steel, 0.035)
	Kit.rbox(root, Vector3(3.4, 1.00, 2.5), Vector3(0, 0.60, 0), walnut, 0.085)
	Kit.rbox(root, Vector3(3.43, 0.035, 2.53), Vector3(0, 1.115, 0), brass, 0.012)
	Kit.rbox(root, Vector3(3.48, 0.09, 2.58), Vector3(0, 1.1775, 0), walnut, 0.04)
	Kit.rbox(root, Vector3(3.27, 0.035, 2.37), Vector3(0, 1.233, 0), stone, 0.015)
	# Fine cabinet joints and discrete brass fasteners give the millwork a made quality.
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.008, 0.86, 2.21), Vector3(side * 1.701, 0.60, 0), steel, 0.003)
		for z: float in [-0.88, 0.88]:
			Kit.rbox(root, Vector3(0.014, 0.035, 0.035), Vector3(side * 1.71, 0.97, z), brass, 0.006)
	var glow: StandardMaterial3D = Kit.washi(Kit.CREAM, 1.15, "aircraft_case_glow")
	for z: float in [-1.13, 1.13]:
		Kit.rbox(root, Vector3(3.08, 0.018, 0.027), Vector3(0, 1.263, z), glow, 0.007, false)
	# Minimal edge framing keeps the model visible through five separate glass panes.
	var glass: StandardMaterial3D = _glass()
	for x: float in [-1.65, 1.65]:
		Kit.rbox(root, Vector3(0.014, 1.27, 2.33), Vector3(x, 1.887, 0), glass, 0.005, false)
	for z: float in [-1.18, 1.18]:
		Kit.rbox(root, Vector3(3.3, 1.27, 0.014), Vector3(0, 1.887, z), glass, 0.005, false)
	Kit.rbox(root, Vector3(3.33, 0.014, 2.39), Vector3(0, 2.53, 0), glass, 0.005, false)
	for x: float in [-1.65, 1.65]:
		for z: float in [-1.18, 1.18]:
			Kit.rbox(root, Vector3(0.022, 1.28, 0.022), Vector3(x, 1.89, z), brass, 0.007)
	for z: float in [-1.18, 1.18]:
		Kit.rbox(root, Vector3(3.34, 0.022, 0.022), Vector3(0, 2.53, z), brass, 0.007)
	# A turned brass pedestal and slender cradle support the model, with no animation.
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0, 0), Vector2(0.22, 0), Vector2(0.24, 0.025),
		Vector2(0.22, 0.05), Vector2(0.055, 0.08), Vector2(0.032, 0.36),
		Vector2(0.06, 0.39), Vector2(0, 0.39)])), brass, Vector3(0, 1.252, 0))
	var aircraft: Node3D = Node3D.new()
	aircraft.name = "ScaleAirliner"
	aircraft.position = Vector3(0, 1.82, 0)
	aircraft.rotation_degrees.y = 57.0 + float(choice - 1) * 3.0
	root.add_child(aircraft)
	_airliner(aircraft, accent, choice)
	# The plaque is deliberately sized as public exhibit signage, not a tiny model label.
	Kit.rbox(root, Vector3(3.03, 0.83, 0.025), Vector3(0, 0.63, 1.251), brass, 0.03)
	_label(root, "AIRLINER", Vector3(0, 0.88, 1.268), 88, 0.0030)
	_label(root, "航空機模型  ·  飞机模型", Vector3(0, 0.655, 1.268), 60, 0.0026)
	_label(root, "Mô hình máy bay", Vector3(0, 0.46, 1.268), 54, 0.0026)
	_label(root, "Maquette d’avion  ·  Modelo de avión", Vector3(0, 0.285, 1.268), 50, 0.0026)
	return root


static func _airliner(parent: Node3D, accent: Color, choice: int) -> void:
	var cream: StandardMaterial3D = Kit.paint(Kit.CREAM, 0.26)
	var livery: StandardMaterial3D = Kit.paint(accent, 0.32)
	var dark: StandardMaterial3D = Kit.metal(Color(0.065, 0.085, 0.095), 0.25, 0.45, "aircraft_windows")
	var alloy: StandardMaterial3D = Kit.metal(Color(0.70, 0.72, 0.71), 0.29, 0.8, "aircraft_alloy")
	# Radius stations describe a full rounded nose, cylindrical cabin and tapered tailcone.
	var body: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0, -1.22), Vector2(0.028, -1.18), Vector2(0.07, -1.02),
		Vector2(0.12, -0.83), Vector2(0.158, -0.65), Vector2(0.167, -0.30),
		Vector2(0.167, 0.62), Vector2(0.157, 0.85), Vector2(0.135, 1.00),
		Vector2(0.095, 1.12), Vector2(0.044, 1.20), Vector2(0, 1.23)]), 40)
	Kit.add(parent, body, cream, Vector3.ZERO, Vector3(90, 0, 0))
	# A narrow painted cheatline follows both cabin sides.
	for side: float in [-1.0, 1.0]:
		Kit.rbox(parent, Vector3(0.012, 0.023, 1.52), Vector3(side * 0.164, -0.016, 0.12), livery, 0.005)
	var window_transforms: Array[Transform3D] = []
	for side: float in [-1.0, 1.0]:
		for i in 19:
			window_transforms.append(Transform3D(Basis.IDENTITY, Vector3(side * 0.158, 0.055, -0.58 + float(i) * 0.077)))
	_multimesh(parent, Kit.rounded_box(Vector3(0.021, 0.031, 0.023), 0.009), dark, window_transforms, "CabinWindows")
	# Cockpit glazing wraps over the shoulder of the nose in two bevelled panels.
	for side: float in [-1.0, 1.0]:
		var cockpit: MeshInstance3D = Kit.rbox(parent, Vector3(0.093, 0.035, 0.087), Vector3(side * 0.070, 0.096, 1.058), dark, 0.012)
		cockpit.rotation_degrees = Vector3(-24, side * 23, side * -15)
		for z: float in [-0.53, 0.83]:
			Kit.rbox(parent, Vector3(0.015, 0.098, 0.047), Vector3(side * 0.162, 0.010, z), alloy, 0.007)
	# Bevelled, swept, tapered wings: thick roots, raised tips, swept trailing edges.
	for side: float in [-1.0, 1.0]:
		var outline: PackedVector3Array = PackedVector3Array([
			Vector3(side * 0.13, -0.055, 0.38), Vector3(side * 1.10, 0.04, -0.30),
			Vector3(side * 1.15, 0.065, -0.50), Vector3(side * 0.46, -0.045, -0.30),
			Vector3(side * 0.13, -0.055, -0.37)])
		Kit.add(parent, _bevelled("wing_%s" % side, outline, Vector3.UP, 0.034), alloy, Vector3.ZERO)
		var tailplane: PackedVector3Array = PackedVector3Array([
			Vector3(side * 0.045, 0.032, -0.77), Vector3(side * 0.45, 0.060, -1.03),
			Vector3(side * 0.46, 0.060, -1.15), Vector3(side * 0.04, 0.032, -1.08)])
		Kit.add(parent, _bevelled("tailplane_%s" % side, tailplane, Vector3.UP, 0.022), cream, Vector3.ZERO)
		# An upturned winglet is a distinct coloured silhouette at either tip.
		Kit.add(parent, _bevelled("winglet_%s" % side, PackedVector3Array([
			Vector3(side * 1.10, 0.04, -0.30), Vector3(side * 1.16, 0.24, -0.38),
			Vector3(side * 1.18, 0.24, -0.49), Vector3(side * 1.15, 0.065, -0.50)]), Vector3.RIGHT, 0.016), livery, Vector3.ZERO)
		_engine(parent, Vector3(side * 0.48, -0.19, 0.12), cream, alloy, dark)
		Kit.rbox(parent, Vector3(0.04, 0.12, 0.21), Vector3(side * 0.48, -0.10, 0.06), alloy, 0.012)
	var fin: PackedVector3Array = PackedVector3Array([
		Vector3(0, 0.08, -0.68), Vector3(0, 0.49, -0.95),
		Vector3(0, 0.51, -1.08), Vector3(0, 0.08, -1.18)])
	Kit.add(parent, _bevelled("vertical_fin", fin, Vector3.RIGHT, 0.035), livery, Vector3.ZERO)
	# A simple brass sun medallion is the fictional airline's tail emblem.
	for side: float in [-1.0, 1.0]:
		Kit.add(parent, Kit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.042, 0), Vector2(0.042, 0.004), Vector2(0, 0.004)]), 20), Kit.brass(), Vector3(side * 0.020, 0.35, -0.994), Vector3(0, 0, side * -90))
	var tip_color: Color = Kit.CLAY if choice % 2 == 0 else Kit.SAGE
	Kit.rbox(parent, Vector3(0.025, 0.018, 0.037), Vector3(-1.16, 0.24, -0.44), Kit.washi(tip_color, 0.6, "aircraft_nav_%d" % choice), 0.007, false)


static func _engine(parent: Node3D, at: Vector3, shell: Material, alloy: Material, dark: Material) -> void:
	# Closed tail and genuinely hollow front lip, rather than a cylinder with a painted cap.
	var nacelle: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.047, -0.18), Vector2(0.076, -0.13), Vector2(0.101, 0.03),
		Vector2(0.097, 0.13), Vector2(0.086, 0.15), Vector2(0.075, 0.14),
		Vector2(0.074, 0.07), Vector2(0, 0.055)]), 32)
	Kit.add(parent, nacelle, shell, at, Vector3(90, 0, 0))
	Kit.add(parent, Kit.lathe(PackedVector2Array([
		Vector2(0.086, 0), Vector2(0.093, 0.009), Vector2(0.087, 0.025),
		Vector2(0.075, 0.025), Vector2(0.075, 0), Vector2(0.086, 0)]), 32), alloy, at + Vector3(0, 0, 0.126), Vector3(90, 0, 0))
	Kit.add(parent, Kit.lathe(PackedVector2Array([
		Vector2(0, 0), Vector2(0.074, 0), Vector2(0.074, 0.006), Vector2(0, 0.006)]), 32), dark, at + Vector3(0, 0, 0.075), Vector3(90, 0, 0))
	var blades: Array[Transform3D] = []
	for i in 10:
		var angle: float = TAU * float(i) / 10.0
		blades.append(Transform3D(Basis(Vector3.FORWARD, angle + 0.25), at + Vector3(sin(angle) * 0.044, cos(angle) * 0.044, 0.085)))
	_multimesh(parent, Kit.rounded_box(Vector3(0.010, 0.045, 0.008), 0.003), alloy, blades, "TurbineFan")
	Kit.add(parent, Kit.lathe(PackedVector2Array([Vector2(0.017, 0), Vector2(0.018, 0.006), Vector2(0, 0.035)]), 20), alloy, at + Vector3(0, 0, 0.083), Vector3(90, 0, 0))


static func _bevelled(key: String, outline: PackedVector3Array, axis: Vector3, thickness: float) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var center: Vector3 = Vector3.ZERO
	for point: Vector3 in outline:
		center += point
	center /= float(outline.size())
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outline.size():
		var a: Vector3 = outline[i]
		var b: Vector3 = outline[(i + 1) % outline.size()]
		var inner_a: Vector3 = center + (a - center) * 0.96
		var inner_b: Vector3 = center + (b - center) * 0.96
		for side: float in [-1.0, 1.0]:
			var lift: Vector3 = axis * thickness * 0.5 * side
			_triangle(st, center + lift, inner_a + lift, inner_b + lift, axis * side)
			var edge_normal: Vector3 = ((a + b) * 0.5 - center).normalized()
			_triangle(st, inner_a + lift, a, b, (axis * side + edge_normal).normalized())
			_triangle(st, inner_a + lift, b, inner_b + lift, (axis * side + edge_normal).normalized())
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, facing: Vector3) -> void:
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	if normal.dot(facing) < 0:
		normal = -normal
	st.set_normal(normal)
	# Godot's visible front faces use clockwise vertex winding.
	st.add_vertex(a)
	if (b - a).cross(c - a).dot(normal) > 0:
		st.add_vertex(c)
		st.add_vertex(b)
	else:
		st.add_vertex(b)
		st.add_vertex(c)


static func _multimesh(parent: Node3D, mesh: Mesh, material: Material, transforms: Array[Transform3D], caption: String) -> void:
	var batch: MultiMesh = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = transforms.size()
	for i in transforms.size():
		batch.set_instance_transform(i, transforms[i])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = caption
	node.multimesh = batch
	node.material_override = material
	parent.add_child(node)


static func _glass() -> StandardMaterial3D:
	if _materials.has("glass"):
		return _materials["glass"] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.80, 0.93, 0.88, 0.075)
	material.roughness = 0.10
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials["glass"] = material
	return material


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixels: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signs.font()
	label.font_size = size
	label.pixel_size = pixels
	label.position = at
	label.modulate = Kit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
