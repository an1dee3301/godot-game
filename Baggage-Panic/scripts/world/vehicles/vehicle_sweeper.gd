extends RefCounted
## Apron vacuum sweeper: 7.2 m long, ground-contact tires, deployed gutter brushes.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ApronSweeper"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colours: Array[Color] = [Color(0.94, 0.69, 0.16), Kit.CREAM, Kit.SAGE, Kit.CHARCOAL]
	var accents: Array[Color] = [Kit.CHARCOAL, Kit.CLAY, Kit.CREAM, Kit.OCHRE]
	var body: StandardMaterial3D = Kit.paint(colours[scheme], 0.42)
	var stripe: StandardMaterial3D = Kit.paint(accents[scheme], 0.48)
	var steel: StandardMaterial3D = Kit.metal()
	var alloy: StandardMaterial3D = Kit.metal(Color(0.56, 0.57, 0.53), 0.48, 0.8, "sweeper_alloy")
	var rubber: StandardMaterial3D = Kit.paint(Color(0.055, 0.06, 0.055), 0.95)
	var glass: StandardMaterial3D = _glass()
	var warm_light: StandardMaterial3D = Kit.washi(Kit.CREAM, 2.8, "sweeper_headlight")
	var amber: StandardMaterial3D = Kit.washi(Color(1.0, 0.47, 0.06), 3.0, "sweeper_beacon")
	# Continuous steel chassis and rounded, slightly narrower vacuum hopper.
	Kit.rbox(root, Vector3(2.25, 0.25, 6.6), Vector3(0.0, 0.75, -0.05), steel, 0.09)
	Kit.rbox(root, Vector3(2.48, 0.48, 4.0), Vector3(0.0, 1.05, -1.35), stripe, 0.14)
	Kit.rbox(root, Vector3(2.4, 1.82, 3.92), Vector3(0.0, 2.13, -1.35), body, 0.24)
	Kit.rbox(root, Vector3(2.3, 0.18, 3.66), Vector3(0.0, 3.04, -1.35), alloy, 0.08)
	Kit.rbox(root, Vector3(2.36, 0.09, 3.72), Vector3(0.0, 2.94, -1.35), steel, 0.035)
	# Cab-over layout: dark glazing band, rounded painted nose and floating roof.
	Kit.rbox(root, Vector3(2.42, 0.87, 2.24), Vector3(0.0, 1.38, 2.02), body, 0.19)
	Kit.rbox(root, Vector3(2.28, 1.22, 1.97), Vector3(0.0, 2.34, 1.88), steel, 0.12)
	Kit.rbox(root, Vector3(2.48, 0.19, 2.25), Vector3(0.0, 3.0, 1.94), body, 0.085)
	var windscreen: MeshInstance3D = Kit.rbox(root, Vector3(2.06, 0.94, 0.075), Vector3(0.0, 2.34, 2.89), glass, 0.035)
	windscreen.rotation_degrees.x = -9.0
	Kit.rbox(root, Vector3(0.055, 0.95, 0.06), Vector3(0.0, 2.34, 2.946), alloy, 0.017)
	Kit.rbox(root, Vector3(2.3, 0.16, 0.16), Vector3(0.0, 2.87, 2.94), stripe, 0.045)
	Kit.rbox(root, Vector3(2.5, 0.24, 0.24), Vector3(0.0, 0.91, 3.17), steel, 0.08)
	Kit.rbox(root, Vector3(0.95, 0.27, 0.05), Vector3(0.0, 1.35, 3.16), steel, 0.06)
	for index in 4:
		Kit.rbox(root, Vector3(0.75, 0.023, 0.025), Vector3(0.0, 1.25 + float(index) * 0.065, 3.195), alloy, 0.008, false)
	# Axles, profiled tires, recessed hubs, wheel-arch shells and access steps.
	for axle_z: float in [-2.35, 1.92]:
		_cylinder(root, 0.10, 2.3, Vector3(0.0, 0.62, axle_z), steel, Vector3(0.0, 0.0, 90.0))
		for side: float in [-1.0, 1.0]:
			Kit.add(root, _tire(), rubber, Vector3(side * 1.16, 0.62, axle_z), Vector3(0.0, 0.0, 90.0))
			_cylinder(root, 0.35, 0.07, Vector3(side * 1.41, 0.62, axle_z), alloy, Vector3(0.0, 0.0, 90.0))
			_cylinder(root, 0.17, 0.085, Vector3(side * 1.46, 0.62, axle_z), steel, Vector3(0.0, 0.0, 90.0))
			Kit.add(root, _arch(), body, Vector3(side * 1.14, 0.62, axle_z))
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.075, 0.98, 1.54), Vector3(side * 1.155, 2.33, 1.87), glass, 0.035)
		Kit.rbox(root, Vector3(0.07, 1.05, 0.085), Vector3(side * 1.20, 2.32, 1.3), body, 0.025)
		Kit.rbox(root, Vector3(0.04, 0.38, 0.91), Vector3(side * 1.225, 1.55, 1.4), stripe, 0.045)
		Kit.rbox(root, Vector3(0.085, 0.045, 0.27), Vector3(side * 1.28, 1.75, 1.25), Kit.brass(), 0.018, false)
		Kit.rbox(root, Vector3(0.38, 0.10, 0.78), Vector3(side * 1.23, 0.56, 1.04), alloy, 0.025)
		Kit.rbox(root, Vector3(0.34, 0.045, 0.65), Vector3(side * 1.25, 0.63, 1.04), rubber, 0.016)
		Kit.rbox(root, Vector3(0.40, 0.055, 0.07), Vector3(side * 1.38, 2.58, 2.65), steel, 0.02)
		Kit.rbox(root, Vector3(0.15, 0.4, 0.23), Vector3(side * 1.57, 2.4, 2.67), stripe, 0.045)
		Kit.rbox(root, Vector3(0.025, 0.32, 0.16), Vector3(side * 1.65, 2.4, 2.67), alloy, 0.012, false)
		Kit.rbox(root, Vector3(0.4, 0.21, 0.07), Vector3(side * 0.87, 1.42, 3.18), steel, 0.04)
		Kit.rbox(root, Vector3(0.31, 0.13, 0.035), Vector3(side * 0.87, 1.42, 3.227), warm_light, 0.04, false)
		# Articulated brush arms clearly project beyond the truck's body.
		var arm: MeshInstance3D = Kit.rbox(root, Vector3(0.86, 0.13, 0.14), Vector3(side * 1.35, 0.59, 0.32), alloy, 0.04)
		arm.rotation_degrees.z = side * -17.0
		_cylinder(root, 0.12, 0.39, Vector3(side * 1.72, 0.47, 0.32), steel)
		_brush(root, Vector3(side * 1.72, 0.0, 0.32), stripe, rubber)
		# Broad side graphic: four large lines covering all six airport languages.
		Kit.rbox(root, Vector3(0.035, 1.34, 3.0), Vector3(side * 1.212, 2.17, -1.29), Kit.paint(Kit.CREAM), 0.015, false)
		var captions: Array[String] = ["APRON SWEEPER", "清掃車 · 清扫车", "Xe quét", "Balayeuse · Barredora"]
		for row in captions.size():
			_label(root, captions[row], Vector3(side * 1.237, 2.63 - float(row) * 0.30, -1.29), side * 90.0, 88, Kit.CHARCOAL)
		Kit.rbox(root, Vector3(0.065, 0.045, 3.40), Vector3(side * 1.225, 1.44, -1.35), Kit.brass(), 0.018, false)
	# Wide pickup shoe and a cylindrical belly brush distinguish it from a delivery truck.
	Kit.rbox(root, Vector3(2.13, 0.23, 0.54), Vector3(0.0, 0.26, -0.75), steel, 0.065)
	Kit.rbox(root, Vector3(2.20, 0.10, 0.10), Vector3(0.0, 0.10, -0.48), rubber, 0.035)
	_cylinder(root, 0.24, 1.92, Vector3(0.0, 0.25, -1.13), rubber, Vector3(0.0, 0.0, 90.0))
	# Rear service hatch, closure rail, hinge blocks, fan stack and warning lamps.
	Kit.rbox(root, Vector3(2.10, 1.52, 0.06), Vector3(0.0, 2.12, -3.33), stripe, 0.1)
	Kit.rbox(root, Vector3(1.88, 1.31, 0.055), Vector3(0.0, 2.12, -3.38), body, 0.08)
	Kit.rbox(root, Vector3(2.43, 0.22, 0.20), Vector3(0.0, 0.87, -3.43), steel, 0.07)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.22, 0.12, 0.13), Vector3(side * 0.7, 2.85, -3.39), alloy, 0.028)
		Kit.rbox(root, Vector3(0.14, 0.38, 0.10), Vector3(side * 1.02, 1.21, -3.4), Kit.washi(Color(0.85, 0.15, 0.08), 1.5, "sweeper_tail"), 0.04, false)
		Kit.rbox(root, Vector3(0.12, 0.075, 2.75), Vector3(side * 0.96, 3.16, -1.35), steel, 0.026)
		_cylinder(root, 0.13, 0.10, Vector3(side * 0.79, 3.15, 1.82), steel)
		_cylinder(root, 0.105, 0.22, Vector3(side * 0.79, 3.31, 1.82), amber)
	_cylinder(root, 0.35, 0.25, Vector3(0.0, 3.23, -2.32), steel)
	_cylinder(root, 0.40, 0.085, Vector3(0.0, 3.39, -2.32), alloy)
	_label(root, "SW–08", Vector3(0.0, 1.73, 3.17), 0.0, 105, Kit.CHARCOAL if scheme != 3 else Kit.CREAM)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, yaw: float, size: int, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signs.font()
	label.font_size = size
	label.pixel_size = 0.0028
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.rotation_degrees.y = yaw
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _glass() -> StandardMaterial3D:
	if not _materials.has("glass"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.10, 0.19, 0.20)
		material.metallic = 0.35
		material.roughness = 0.16
		_materials["glass"] = material
	return _materials["glass"] as StandardMaterial3D


static func _cylinder(parent: Node3D, radius: float, height: float, at: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var key: String = "cylinder:%s:%s" % [radius, height]
	if not _meshes.has(key):
		var mesh: CylinderMesh = CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = 24
		_meshes[key] = mesh
	Kit.add(parent, _meshes[key] as Mesh, material, at, rotation)


static func _tire() -> ArrayMesh:
	return Kit.lathe(PackedVector2Array([
		Vector2(0.29, -0.23), Vector2(0.48, -0.23), Vector2(0.58, -0.18),
		Vector2(0.62, -0.12), Vector2(0.62, 0.12), Vector2(0.58, 0.18),
		Vector2(0.48, 0.23), Vector2(0.29, 0.23), Vector2(0.29, -0.23)
	]), 32)


static func _arch() -> ArrayMesh:
	if _meshes.has("arch"):
		return _meshes["arch"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Solid semicircular wheel guard: four connected curved surfaces.
	for segment in 20:
		var angles: Array[float] = [PI * float(segment) / 20.0, PI * float(segment + 1) / 20.0]
		var corners: Array[Vector2] = [Vector2(-0.27, 0.68), Vector2(0.27, 0.68), Vector2(0.27, 0.77), Vector2(-0.27, 0.77)]
		for edge in 4:
			var p: Vector2 = corners[edge]
			var q: Vector2 = corners[(edge + 1) % 4]
			var a: Vector3 = Vector3(p.x, sin(angles[0]) * p.y, cos(angles[0]) * p.y)
			var b: Vector3 = Vector3(p.x, sin(angles[1]) * p.y, cos(angles[1]) * p.y)
			var c: Vector3 = Vector3(q.x, sin(angles[1]) * q.y, cos(angles[1]) * q.y)
			var d: Vector3 = Vector3(q.x, sin(angles[0]) * q.y, cos(angles[0]) * q.y)
			for vertex: Vector3 in [a, b, c, a, c, d]:
				surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes["arch"] = mesh
	return mesh


static func _brush(parent: Node3D, at: Vector3, cover: Material, bristles: Material) -> void:
	Kit.add(parent, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.28), Vector2(0.47, 0.28), Vector2(0.57, 0.33),
		Vector2(0.52, 0.40), Vector2(0.16, 0.44), Vector2(0.0, 0.44)
	]), 32), cover, at)
	# Dense, splayed bristle bundles rendered in a single instanced draw per brush.
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = Kit.rounded_box(Vector3(0.035, 0.32, 0.045), 0.009, 2)
	instances.instance_count = 96
	for index in 96:
		var angle: float = TAU * float(index) / 96.0
		var outward: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var axis_y: Vector3 = (Vector3.UP - outward * 0.65).normalized()
		var axis_x: Vector3 = Vector3(-sin(angle), 0.0, cos(angle))
		var basis: Basis = Basis(axis_x, axis_y, axis_x.cross(axis_y)).orthonormalized()
		instances.set_instance_transform(index, Transform3D(basis, outward * 0.56 + Vector3.UP * 0.15))
	var bundles: MultiMeshInstance3D = MultiMeshInstance3D.new()
	bundles.multimesh = instances
	bundles.material_override = bristles
	bundles.position = at
	bundles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(bundles)
