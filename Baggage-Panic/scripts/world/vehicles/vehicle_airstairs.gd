extends RefCounted
## Self-propelled covered passenger stairs: rear boarding, aircraft docking at +Z.
## Approximately 8.8 m long, 2.9 m wide, with a 3.85 m landing height.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CoveredAirstairs"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var colours: Array[Color] = [Color(0.94, 0.69, 0.20), Kit.CREAM, Kit.SAGE, Kit.CHARCOAL]
	var accents: Array[Color] = [Kit.CHARCOAL, Kit.CLAY, Kit.CREAM, Color(0.78, 0.60, 0.34)]
	var scheme: int = posmod(variant, 4)
	var body: Material = Kit.paint(colours[scheme], 0.43)
	var accent: Material = Kit.paint(accents[scheme], 0.48)
	var steel: Material = Kit.metal()
	var aluminium: Material = Kit.metal(Color(0.66, 0.67, 0.63), 0.46, 0.8, "airstairs_aluminium")
	var rubber: Material = Kit.paint(Color(0.055, 0.052, 0.047), 0.96)
	var oak: Material = Kit.wood(Kit.OAK, "airstairs_oak")
	var roof: Material = Kit.fabric(Kit.LINEN, "airstairs_canopy")
	var glass: Material = _glazing()
	var amber: Material = Kit.washi(Color(1.0, 0.49, 0.08), 2.8, "airstairs_beacon")
	var light: Material = Kit.washi(Kit.CREAM, 2.1, "airstairs_headlight")
	var red: Material = Kit.washi(Color(0.76, 0.10, 0.055), 1.6, "airstairs_tail")
	# The low, heavy chassis makes the diagonal stair legible across the apron.
	Kit.rbox(root, Vector3(2.22, 0.38, 8.1), Vector3(0.0, 0.66, -0.05), steel, 0.12)
	Kit.rbox(root, Vector3(2.30, 0.55, 5.7), Vector3(0.0, 0.98, -1.2), body, 0.16)
	Kit.rbox(root, Vector3(2.40, 0.22, 0.28), Vector3(0.0, 0.63, 4.16), rubber, 0.08)
	Kit.rbox(root, Vector3(2.40, 0.20, 0.24), Vector3(0.0, 0.62, -4.18), rubber, 0.07)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.035, 0.13, 5.1), Vector3(side * 1.16, 1.05, -1.1), accent, 0.012, false)
		# Engine service-door seam and substantial flush pull.
		Kit.rbox(root, Vector3(0.04, 0.36, 1.52), Vector3(side * 1.16, 0.96, -1.2), steel, 0.03)
		Kit.rbox(root, Vector3(0.055, 0.31, 1.45), Vector3(side * 1.18, 0.96, -1.2), body, 0.025)
		Kit.rbox(root, Vector3(0.045, 0.055, 0.28), Vector3(side * 1.22, 1.04, -0.8), aluminium, 0.015, false)
		for wheel_z: float in [-2.65, 2.65]:
			Kit.add(root, _tyre(), rubber, Vector3(side * 1.15, 0.48, wheel_z), Vector3(0.0, 0.0, 90.0))
			Kit.add(root, _hub(), aluminium, Vector3(side * 1.345, 0.48, wheel_z), Vector3(0.0, 0.0, 90.0))
			Kit.rbox(root, Vector3(0.42, 0.13, 1.15), Vector3(side * 1.14, 1.04, wheel_z), body, 0.06)
			Kit.rbox(root, Vector3(0.04, 0.28, 0.16), Vector3(side * 1.20, 0.51, wheel_z - 0.54), rubber, 0.02)
		# Deployed stabilisers, with broad rubber pads touching the apron.
		Kit.rbox(root, Vector3(0.57, 0.14, 0.24), Vector3(side * 1.25, 0.49, 0.75), steel, 0.035)
		Kit.rbox(root, Vector3(0.13, 0.43, 0.13), Vector3(side * 1.46, 0.29, 0.75), aluminium, 0.025)
		Kit.rbox(root, Vector3(0.43, 0.075, 0.44), Vector3(side * 1.46, 0.0375, 0.75), rubber, 0.025)
		Kit.rbox(root, Vector3(0.045, 0.11, 0.25), Vector3(side * 1.20, 0.88, -3.45), amber, 0.02, false)
		Kit.rbox(root, Vector3(0.30, 0.13, 0.035), Vector3(side * 0.88, 0.80, -4.315), red, 0.025, false)
	# Forward driving cab sits below the aircraft landing, with a rounded brow.
	Kit.rbox(root, Vector3(2.12, 1.50, 1.92), Vector3(0.0, 1.62, 3.04), body, 0.18)
	Kit.rbox(root, Vector3(2.24, 0.17, 2.05), Vector3(0.0, 2.40, 3.05), Kit.paint(Kit.CREAM), 0.08)
	Kit.rbox(root, Vector3(1.94, 0.78, 0.055), Vector3(0.0, 1.96, 4.007), steel, 0.09)
	Kit.rbox(root, Vector3(1.83, 0.67, 0.035), Vector3(0.0, 1.97, 4.043), glass, 0.075, false)
	Kit.rbox(root, Vector3(0.045, 0.70, 0.04), Vector3(0.0, 1.97, 4.066), steel, 0.012, false)
	Kit.rbox(root, Vector3(1.75, 0.11, 0.045), Vector3(0.0, 1.28, 4.018), accent, 0.025)
	Kit.rbox(root, Vector3(0.75, 0.19, 0.03), Vector3(0.0, 0.98, 4.025), steel, 0.035)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.04, 0.80, 1.26), Vector3(side * 1.067, 1.95, 3.13), steel, 0.07)
		Kit.rbox(root, Vector3(0.035, 0.68, 1.14), Vector3(side * 1.094, 1.97, 3.13), glass, 0.06, false)
		Kit.rbox(root, Vector3(0.035, 0.065, 0.26), Vector3(side * 1.10, 1.40, 2.75), aluminium, 0.016, false)
		Kit.rbox(root, Vector3(0.27, 0.08, 0.08), Vector3(side * 1.18, 2.0, 3.84), steel, 0.025)
		Kit.rbox(root, Vector3(0.09, 0.32, 0.23), Vector3(side * 1.32, 2.01, 3.84), steel, 0.035)
		Kit.rbox(root, Vector3(0.35, 0.19, 0.06), Vector3(side * 0.74, 1.01, 4.047), light, 0.055, false)
		Kit.rbox(root, Vector3(0.16, 0.08, 0.045), Vector3(side * 0.96, 1.23, 4.027), amber, 0.025, false)
		Kit.rbox(root, Vector3(0.80, 0.12, 0.46), Vector3(side * 0.70, 0.80, 3.37), aluminium, 0.04)
	# Twenty real horizontal treads; instancing keeps the repeating detail inexpensive.
	var treads: Array[Transform3D] = []
	var edges: Array[Transform3D] = []
	for step: int in 20:
		var y: float = 0.45 + float(step) * 0.17
		var z: float = -3.90 + float(step) * 0.29
		treads.append(Transform3D(Basis.IDENTITY, Vector3(0.0, y - 0.06, z)))
		edges.append(Transform3D(Basis.IDENTITY, Vector3(0.0, y + 0.012, z - 0.13)))
	_batch(root, Kit.rounded_box(Vector3(2.02, 0.12, 0.305), 0.022), aluminium, treads, "StairTreads")
	_batch(root, Kit.rounded_box(Vector3(1.94, 0.025, 0.048), 0.008), accent, edges, "ContrastingNosings")
	Kit.rbox(root, Vector3(2.35, 0.17, 1.72), Vector3(0.0, 3.765, 2.59), aluminium, 0.05)
	Kit.rbox(root, Vector3(2.36, 0.16, 0.26), Vector3(0.0, 3.86, 3.55), rubber, 0.07)
	Kit.rbox(root, Vector3(1.96, 0.05, 1.36), Vector3(0.0, 3.87, 2.59), Kit.paint(Kit.CHARCOAL, 0.95), 0.02)
	# Structural stringers, knee guards, tactile oak handrails and hydraulic lift.
	for side: float in [-1.0, 1.0]:
		_beam(root, Vector3(side * 1.03, 0.30, -4.05), Vector3(side * 1.03, 3.66, 1.92), 0.14, 0.24, steel)
		_beam(root, Vector3(side * 1.11, 0.66, -4.07), Vector3(side * 1.11, 4.10, 1.80), 0.09, 0.53, body)
		_beam(root, Vector3(side * 1.08, 1.49, -4.07), Vector3(side * 1.08, 4.93, 1.80), 0.075, 0.075, oak)
		_beam(root, Vector3(side * 1.08, 1.02, -4.07), Vector3(side * 1.08, 4.46, 1.80), 0.045, 0.045, aluminium)
		_beam(root, Vector3(side * 1.17, 2.35, -4.15), Vector3(side * 1.17, 5.98, 2.05), 0.06, 0.09, aluminium)
		_beam(root, Vector3(side * 0.74, 1.25, -0.8), Vector3(side * 0.74, 2.73, 1.14), 0.17, 0.17, steel)
		_beam(root, Vector3(side * 0.74, 2.24, 0.50), Vector3(side * 0.74, 3.70, 2.42), 0.10, 0.10, aluminium)
		Kit.rbox(root, Vector3(0.085, 0.55, 1.68), Vector3(side * 1.15, 4.12, 2.60), body, 0.04)
		Kit.rbox(root, Vector3(0.075, 0.075, 1.74), Vector3(side * 1.10, 4.94, 2.60), oak, 0.03)
		Kit.rbox(root, Vector3(0.06, 0.07, 1.8), Vector3(side * 1.17, 5.98, 2.62), aluminium, 0.025)
	# A shallow barrel canopy follows the stair pitch, then levels over the landing.
	Kit.add(root, _canopy(), roof, Vector3.ZERO)
	var ribs: Array[Transform3D] = []
	for station: int in 6:
		var z: float = -4.15 + float(station) * 1.24
		var floor_y: float = 0.37 + float(station) * 0.726
		for side: float in [-1.0, 1.0]:
			Kit.rbox(root, Vector3(0.055, 1.99, 0.065), Vector3(side * 1.17, floor_y + 0.995, z), aluminium, 0.02)
		for segment: int in 12:
			var a: float = float(segment) * PI / 12.0
			var b: float = float(segment + 1) * PI / 12.0
			var p: Vector3 = Vector3(cos(a) * 1.19, floor_y + 1.98 + sin(a) * 0.34, z)
			var q: Vector3 = Vector3(cos(b) * 1.19, floor_y + 1.98 + sin(b) * 0.34, z)
			var transform: Transform3D = _beam_transform(p, q)
			transform.basis = transform.basis.scaled(Vector3(1.0, p.distance_to(q), 1.0))
			ribs.append(transform)
	_batch(root, Kit.rounded_box(Vector3(0.045, 1.0, 0.05), 0.015), aluminium, ribs, "CanopyRibs")
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.06, 2.1, 0.065), Vector3(side * 1.17, 4.90, 3.42), aluminium, 0.02)
		_beam(root, Vector3(side * 0.96, 2.29, -4.07), Vector3(side * 0.96, 5.89, 2.05), 0.035, 0.035, light, false)
		Kit.rbox(root, Vector3(0.05, 0.05, 1.6), Vector3(side * 0.97, 5.88, 2.70), light, 0.015, false)
		Kit.add(root, _beacon(), amber, Vector3(side * 0.87, 6.32, 3.18), Vector3.ZERO, false)
		Kit.rbox(root, Vector3(0.25, 0.04, 0.25), Vector3(side * 0.87, 6.31, 3.18), steel, 0.02)
	# Large six-language welcome panels on both sides of the truck body.
	for side: float in [-1.0, 1.0]:
		var sign: Node3D = Signs.panel(root, Vector3(side * 1.22, 2.05, -1.55), "welcome", {"width": 4.0, "accent": colours[scheme]})
		sign.rotation_degrees.y = side * 90.0
	# Restrict shadows on small fittings without fading the long-distance silhouette.
	Kit.optimize(root, 220.0, 0.28)
	return root


static func _beam_transform(start: Vector3, finish: Vector3) -> Transform3D:
	var direction: Vector3 = (finish - start).normalized()
	var cross: Vector3 = Vector3.RIGHT if absf(direction.x) < 0.9 else Vector3.FORWARD
	var z_axis: Vector3 = cross.cross(direction).normalized()
	var x_axis: Vector3 = direction.cross(z_axis).normalized()
	return Transform3D(Basis(x_axis, direction, z_axis), (start + finish) * 0.5)


static func _beam(parent: Node3D, start: Vector3, finish: Vector3, width: float, depth: float, material: Material, shadows: bool = true) -> void:
	var part: MeshInstance3D = Kit.add(parent, Kit.rounded_box(Vector3(width, start.distance_to(finish), depth), minf(width, depth) * 0.35), material, Vector3.ZERO, Vector3.ZERO, shadows)
	part.transform = _beam_transform(start, finish)


static func _batch(parent: Node3D, mesh: Mesh, material: Material, transforms: Array[Transform3D], title: String) -> void:
	var batch: MultiMesh = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = transforms.size()
	for index: int in transforms.size():
		batch.set_instance_transform(index, transforms[index])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = batch
	node.material_override = material
	parent.add_child(node)


static func _tyre() -> Mesh:
	return Kit.lathe(PackedVector2Array([Vector2(0.0, -0.17), Vector2(0.30, -0.17), Vector2(0.43, -0.14), Vector2(0.48, -0.09), Vector2(0.48, 0.09), Vector2(0.43, 0.14), Vector2(0.30, 0.17), Vector2(0.0, 0.17)]), 28)


static func _hub() -> Mesh:
	return Kit.lathe(PackedVector2Array([Vector2(0.0, -0.025), Vector2(0.25, -0.025), Vector2(0.28, 0.0), Vector2(0.25, 0.04), Vector2(0.11, 0.04), Vector2(0.095, 0.065), Vector2(0.0, 0.065)]), 20)


static func _beacon() -> Mesh:
	return Kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.105, 0.0), Vector2(0.105, 0.14), Vector2(0.085, 0.19), Vector2(0.0, 0.20)]), 16)


static func _glazing() -> Material:
	if not _materials.has("cab_glass"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.12, 0.21, 0.22)
		material.metallic = 0.45
		material.roughness = 0.18
		_materials["cab_glass"] = material
	return _materials["cab_glass"] as Material


static func _canopy() -> Mesh:
	if _meshes.has("barrel_canopy"):
		return _meshes["barrel_canopy"] as Mesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stations: Array[Vector2] = [Vector2(-4.25, 0.31), Vector2(2.05, 4.0), Vector2(3.62, 4.0)]
	for run: int in 2:
		var near: Vector2 = stations[run]
		var far: Vector2 = stations[run + 1]
		for segment: int in 16:
			var a: float = float(segment) * PI / 16.0
			var b: float = float(segment + 1) * PI / 16.0
			var p: Vector3 = Vector3(cos(a) * 1.25, near.y + 1.98 + sin(a) * 0.37, near.x)
			var q: Vector3 = Vector3(cos(b) * 1.25, near.y + 1.98 + sin(b) * 0.37, near.x)
			var r: Vector3 = Vector3(cos(b) * 1.25, far.y + 1.98 + sin(b) * 0.37, far.x)
			var s: Vector3 = Vector3(cos(a) * 1.25, far.y + 1.98 + sin(a) * 0.37, far.x)
			_quad(surface, p, q, r, s)
			var inset: Vector3 = Vector3(0.0, -0.045, 0.0)
			_quad(surface, p + inset, s + inset, r + inset, q + inset)
			if run == 0:
				_quad(surface, q, p, p + inset, q + inset)
			if run == 1:
				_quad(surface, s, r, r + inset, s + inset)
			if segment == 0:
				_quad(surface, p, s, s + inset, p + inset)
			if segment == 15:
				_quad(surface, r, q, q + inset, r + inset)
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes["barrel_canopy"] = mesh
	return mesh


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for vertex: Vector3 in [a, b, c, a, c, d]:
		surface.set_uv(Vector2(vertex.x, vertex.z) * 0.3)
		surface.add_vertex(vertex)
