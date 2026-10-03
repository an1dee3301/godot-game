extends RefCounted
## Apron hydrant dispenser: exposed filtration, hose reels and elevated wing-service deck.
## Dimensions approximately 2.8 x 4.7 x 7.6 m. No storage tanker: fuel comes from the apron hydrant.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "HydrantDispenser"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var colours: Array[Color] = [Color(0.94, 0.71, 0.18), Kit.CREAM, Kit.SAGE, Kit.CHARCOAL]
	var scheme: int = posmod(variant, 4)
	var body: StandardMaterial3D = Kit.paint(colours[scheme], 0.4)
	var accent: StandardMaterial3D = Kit.brass() if scheme == 3 else Kit.paint(Kit.CLAY if scheme == 1 else Kit.CREAM)
	var steel: StandardMaterial3D = Kit.metal()
	var alloy: StandardMaterial3D = Kit.metal(Color(0.68, 0.7, 0.66), 0.38, 0.85, "hydrant_alloy")
	var rubber: StandardMaterial3D = Kit.paint(Color(0.055, 0.06, 0.054), 0.94)
	var glazing: StandardMaterial3D = Kit.metal(Color(0.12, 0.21, 0.22), 0.19, 0.35, "hydrant_glass")
	var amber: StandardMaterial3D = Kit.washi(Color(1.0, 0.49, 0.08), 3.2, "hydrant_amber")
	var lamp: StandardMaterial3D = Kit.washi(Kit.CREAM, 2.8, "hydrant_headlamp")
	var red: StandardMaterial3D = Kit.washi(Color(0.83, 0.11, 0.065), 1.8, "hydrant_tail")

	# Short commercial chassis, cab forward, equipment bed aft.
	Kit.rbox(root, Vector3(2.15, 0.3, 6.9), Vector3(0, 0.64, 0), steel, 0.09)
	Kit.rbox(root, Vector3(2.48, 0.2, 4.65), Vector3(0, 1.02, -1.13), alloy, 0.055)
	Kit.rbox(root, Vector3(2.45, 0.75, 2.0), Vector3(0, 1.26, 2.35), body, 0.16)
	Kit.rbox(root, Vector3(2.38, 1.28, 1.77), Vector3(0, 2.12, 2.27), body, 0.19)
	Kit.rbox(root, Vector3(2.5, 0.15, 1.97), Vector3(0, 2.8, 2.25), accent, 0.065)
	Kit.rbox(root, Vector3(2.12, 0.77, 0.055), Vector3(0, 2.22, 3.165), glazing, 0.12)
	Kit.rbox(root, Vector3(0.055, 0.77, 0.065), Vector3(0, 2.22, 3.2), steel, 0.018)
	Kit.rbox(root, Vector3(2.6, 0.24, 0.26), Vector3(0, 0.85, 3.46), steel, 0.065)
	Kit.rbox(root, Vector3(1.04, 0.27, 0.06), Vector3(0, 1.29, 3.365), steel, 0.045)
	var grille: Array[PackedVector3Array] = []
	for i in 5:
		var y: float = 1.19 + float(i) * 0.045
		grille.append(PackedVector3Array([Vector3(-0.46, y, 3.404), Vector3(0.46, y, 3.404)]))
	Kit.add(root, _tubes(grille, 0.009, "grille"), alloy, Vector3.ZERO, Vector3.ZERO, false)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.05, 0.71, 1.18), Vector3(side * 1.201, 2.23, 2.27), glazing, 0.08)
		Kit.rbox(root, Vector3(0.035, 0.035, 1.56), Vector3(side * 1.229, 1.81, 2.28), accent, 0.013)
		Kit.rbox(root, Vector3(0.06, 0.06, 0.25), Vector3(side * 1.25, 1.69, 1.85), alloy, 0.02)
		Kit.rbox(root, Vector3(0.25, 0.12, 0.88), Vector3(side * 1.29, 0.67, 2.17), alloy, 0.035)
		Kit.rbox(root, Vector3(0.21, 0.38, 0.12), Vector3(side * 1.4, 2.28, 3.05), steel, 0.045)
		Kit.rbox(root, Vector3(0.43, 0.23, 0.075), Vector3(side * 0.83, 1.3, 3.378), lamp, 0.07, false)
		Kit.rbox(root, Vector3(0.15, 0.07, 0.08), Vector3(side * 1.02, 1.52, 3.378), amber, 0.025, false)
		Kit.add(root, _beacon(), amber, Vector3(side * 0.93, 2.88, 2.3), Vector3.ZERO, false)
		# Large side service panels carry legible multilingual identification.
		Kit.rbox(root, Vector3(0.12, 0.92, 3.84), Vector3(side * 1.2, 1.38, -1.03), body, 0.045)
		Kit.rbox(root, Vector3(0.03, 0.12, 3.68), Vector3(side * 1.27, 0.99, -1.03), accent, 0.012)
		var plate: Node3D = Node3D.new()
		plate.position = Vector3(side * 1.271, 1.5, -1.03)
		plate.rotation_degrees.y = side * 90.0
		root.add_child(plate)
		var ink: Color = Kit.CHARCOAL if scheme != 3 else Kit.CREAM
		if side > 0:
			_label(plate, "AVIATION FUEL", Vector3(0, 0.19, 0.01), 0.27, ink)
			_label(plate, "航空燃料 · 航空燃油", Vector3(0, -0.15, 0.01), 0.24, ink)
		else:
			_label(plate, "Nhiên liệu hàng không", Vector3(0, 0.24, 0.01), 0.23, ink)
			_label(plate, "Carburant aviation", Vector3(0, -0.02, 0.01), 0.23, ink)
			_label(plate, "Combustible de aviación", Vector3(0, -0.28, 0.01), 0.23, ink)

	# Two axles with rounded tyre shoulders and inset stepped wheel rims.
	var tyre: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0.24, -0.2), Vector2(0.45, -0.2), Vector2(0.53, -0.14), Vector2(0.55, -0.07), Vector2(0.55, 0.07), Vector2(0.53, 0.14), Vector2(0.45, 0.2), Vector2(0.24, 0.2), Vector2(0.24, -0.2)]), 32)
	var rim: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.28, 0), Vector2(0.31, 0.035), Vector2(0.31, 0.075), Vector2(0.24, 0.085), Vector2(0.2, 0.04), Vector2(0.105, 0.04), Vector2(0.09, 0.1), Vector2(0, 0.1)]), 24)
	for z: float in [-2.43, 2.1]:
		for side: float in [-1.0, 1.0]:
			Kit.add(root, tyre, rubber, Vector3(side * 1.09, 0.55, z), Vector3(0, 0, 90))
			Kit.add(root, rim, alloy, Vector3(side * 1.3, 0.55, z), Vector3(0, 0, -side * 90))
			Kit.rbox(root, Vector3(0.49, 0.14, 1.25), Vector3(side * 1.05, 1.16, z), body, 0.06)
	Kit.rbox(root, Vector3(2.55, 0.22, 0.2), Vector3(0, 0.83, -3.51), steel, 0.055)
	for x: float in [-0.95, 0.95]:
		Kit.rbox(root, Vector3(0.29, 0.14, 0.05), Vector3(x, 0.95, -3.625), red, 0.04, false)

	# Stainless vertical filter vessels: characteristic machinery, not a tanker body.
	var vessel: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.24, 0), Vector2(0.33, 0.1), Vector2(0.35, 0.2), Vector2(0.35, 1.15), Vector2(0.31, 1.28), Vector2(0.17, 1.36), Vector2(0, 1.36)]), 24)
	for x: float in [-0.43, 0.43]:
		Kit.add(root, vessel, alloy, Vector3(x, 1.15, -0.38))
		Kit.rbox(root, Vector3(0.73, 0.06, 0.73), Vector3(x, 2.29, -0.38), steel, 0.025)
	Kit.rbox(root, Vector3(0.98, 0.72, 0.38), Vector3(0, 1.52, 0.6), body, 0.09)
	Kit.rbox(root, Vector3(0.7, 0.28, 0.04), Vector3(0, 1.7, 0.81), steel, 0.045)
	_label(root, "JET A-1", Vector3(0, 1.71, 0.835), 0.19, Kit.CREAM)
	var plumbing: Array[PackedVector3Array] = [PackedVector3Array([Vector3(-0.43, 2.48, -0.38), Vector3(-0.43, 2.65, -0.38), Vector3(0.43, 2.65, -0.38), Vector3(0.43, 2.48, -0.38)]), PackedVector3Array([Vector3(0.43, 1.35, -0.38), Vector3(0.43, 1.35, 0.5), Vector3(0, 1.35, 0.5)])]
	Kit.add(root, _tubes(plumbing, 0.065, "plumbing"), alloy, Vector3.ZERO)

	# Hose reels, their brass flanges frame thick black coiled hose.
	var flange: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0, -0.035), Vector2(0.61, -0.035), Vector2(0.65, 0), Vector2(0.61, 0.035), Vector2(0, 0.035)]), 32)
	var coil: PackedVector3Array = PackedVector3Array()
	for i in 193:
		var t: float = float(i) / 192.0
		var angle: float = t * TAU * 6.0
		coil.append(Vector3(-0.25 + t * 0.5, sin(angle) * 0.49, cos(angle) * 0.49))
	var hose_mesh: ArrayMesh = _tubes([coil], 0.053, "reel_hose")
	for side: float in [-1.0, 1.0]:
		var centre: Vector3 = Vector3(side * 0.72, 1.95, -2.41)
		Kit.add(root, hose_mesh, rubber, centre)
		for offset: float in [-0.32, 0.32]:
			Kit.add(root, flange, accent, centre + Vector3(offset, 0, 0), Vector3(0, 0, 90))
		Kit.rbox(root, Vector3(0.15, 0.83, 0.34), Vector3(side * 0.72, 1.51, -2.41), steel, 0.045)
	var service_hoses: Array[PackedVector3Array] = []
	var rising: PackedVector3Array = PackedVector3Array()
	for i in 41:
		var t: float = float(i) / 40.0
		rising.append(Vector3(0.95 + 0.13 * sin(t * PI), 2.0 + 1.92 * t, -2.9 + 0.6 * t))
	service_hoses.append(rising)
	var loop: PackedVector3Array = PackedVector3Array()
	for i in 49:
		var angle: float = float(i) / 48.0 * TAU
		loop.append(Vector3(-1.34, 1.22 + 0.81 * cos(angle), -2.28 + 0.51 * sin(angle)))
	service_hoses.append(loop)
	Kit.add(root, _tubes(service_hoses, 0.075, "service_hoses"), rubber, Vector3.ZERO)
	Kit.rbox(root, Vector3(0.25, 0.24, 0.42), Vector3(-1.34, 1.93, -2.32), alloy, 0.06)
	Kit.rbox(root, Vector3(0.32, 0.2, 0.25), Vector3(1.03, 3.98, -2.27), alloy, 0.05)

	# Raised platform on visible crossed lift arms. Guardrails remain open to preserve silhouette.
	var lift: Array[PackedVector3Array] = []
	for x: float in [-0.75, 0.75]:
		lift.append(PackedVector3Array([Vector3(x, 1.2, -2.7), Vector3(x, 3.46, -0.95)]))
		lift.append(PackedVector3Array([Vector3(x, 1.2, -0.95), Vector3(x, 3.46, -2.7)]))
	Kit.add(root, _tubes(lift, 0.1, "scissor_lift"), steel, Vector3.ZERO)
	Kit.rbox(root, Vector3(2.22, 0.18, 2.23), Vector3(0, 3.48, -1.82), alloy, 0.05)
	Kit.rbox(root, Vector3(2.24, 0.18, 2.24), Vector3(0, 3.61, -1.82), accent, 0.045)
	var rails: Array[PackedVector3Array] = []
	for x: float in [-1.02, 1.02]:
		for z: float in [-2.84, -1.82, -0.8]:
			rails.append(PackedVector3Array([Vector3(x, 3.63, z), Vector3(x, 4.68, z)]))
		for y: float in [4.12, 4.68]:
			rails.append(PackedVector3Array([Vector3(x, y, -2.84), Vector3(x, y, -0.8)]))
	for y: float in [4.12, 4.68]:
		rails.append(PackedVector3Array([Vector3(-1.02, y, -2.84), Vector3(1.02, y, -2.84)]))
		rails.append(PackedVector3Array([Vector3(-1.02, y, -0.8), Vector3(1.02, y, -0.8)]))
	Kit.add(root, _tubes(rails, 0.037, "guardrails"), alloy, Vector3.ZERO)
	for side: float in [-1.0, 1.0]:
		var board: Node3D = Node3D.new()
		board.position = Vector3(side * 1.065, 4.23, -1.82)
		board.rotation_degrees.y = side * 90.0
		root.add_child(board)
		Kit.rbox(board, Vector3(1.8, 0.53, 0.06), Vector3.ZERO, steel, 0.05)
		_label(board, "JET A-1", Vector3(0, 0, 0.04), 0.34, Kit.CREAM)
	# Access ladder set behind the lift, with a continuous pair of grab rails.
	var ladder: Array[PackedVector3Array] = []
	for x: float in [-0.36, 0.36]:
		ladder.append(PackedVector3Array([Vector3(x, 0.42, -3.4), Vector3(x, 3.55, -2.98), Vector3(x, 4.18, -2.98)]))
	for i in 9:
		var t: float = float(i) / 8.0
		ladder.append(PackedVector3Array([Vector3(-0.36, 0.58 + t * 2.75, -3.38 + t * 0.37), Vector3(0.36, 0.58 + t * 2.75, -3.38 + t * 0.37)]))
	Kit.add(root, _tubes(ladder, 0.032, "access_ladder"), alloy, Vector3.ZERO)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, height: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signs.font()
	label.font_size = 96
	label.pixel_size = height / 96.0
	label.modulate = ink
	label.outline_size = 0
	label.position = at
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _beacon() -> ArrayMesh:
	return Kit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.13, 0), Vector2(0.13, 0.15), Vector2(0.11, 0.22), Vector2(0.06, 0.25), Vector2(0, 0.25)]), 20)


## Sweep several pipe/hose paths into one cached mesh to keep the apron draw count modest.
static func _tubes(paths: Array[PackedVector3Array], radius: float, key: String) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SIDES: int = 10
	for path: PackedVector3Array in paths:
		var rings: Array[PackedVector3Array] = []
		var normals: Array[PackedVector3Array] = []
		for i in path.size():
			var tangent: Vector3 = (path[mini(i + 1, path.size() - 1)] - path[maxi(0, i - 1)]).normalized()
			var reference: Vector3 = Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.92 else Vector3.RIGHT
			var u: Vector3 = tangent.cross(reference).normalized()
			var v: Vector3 = tangent.cross(u).normalized()
			var ring: PackedVector3Array = PackedVector3Array()
			var norms: PackedVector3Array = PackedVector3Array()
			for s in SIDES:
				var angle: float = TAU * float(s) / float(SIDES)
				var normal: Vector3 = u * cos(angle) + v * sin(angle)
				ring.append(path[i] + normal * radius)
				norms.append(normal)
			rings.append(ring)
			normals.append(norms)
		for i in path.size() - 1:
			var a: PackedVector3Array = rings[i]
			var b: PackedVector3Array = rings[i + 1]
			var na: PackedVector3Array = normals[i]
			var nb: PackedVector3Array = normals[i + 1]
			for s in SIDES:
				var next: int = (s + 1) % SIDES
				var vertices: Array[Vector3] = [a[s], a[next], b[s], a[next], b[next], b[s]]
				var vertex_normals: Array[Vector3] = [na[s], na[next], nb[s], na[next], nb[next], nb[s]]
				for k in 6:
					st.set_normal(vertex_normals[k])
					st.add_vertex(vertices[k])
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh
