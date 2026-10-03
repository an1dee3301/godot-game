extends RefCounted
## A timber crown on a mineral trunk; local +Z is the welcome face.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ColumnTree"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var plaster_tints: Array[Color] = [DesignKit.PLASTER, DesignKit.CREAM, Color(0.86, 0.85, 0.78), Color(0.91, 0.83, 0.75)]
	var oak_tints: Array[Color] = [DesignKit.OAK, Color(0.83, 0.68, 0.49), Color(0.73, 0.57, 0.39), Color(0.79, 0.62, 0.46)]
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var plaster: Material = DesignKit.stone(plaster_tints[choice], 0.86, "column_tree_plaster_%d" % choice)
	var oak: Material = DesignKit.wood(oak_tints[choice], "column_tree_oak_%d" % choice)
	var limestone: Material = DesignKit.stone(DesignKit.LIMESTONE, 0.66, "column_tree_foot")
	var steel: Material = DesignKit.metal()
	var glow: Material = DesignKit.washi(DesignKit.CREAM, 1.4, "column_tree_cove")
	# Flush, radiused stone shoe and a narrow bronze reveal above its shadow joint.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.83, 0.0), Vector2(0.88, 0.035),
		Vector2(0.88, 0.22), Vector2(0.84, 0.28), Vector2(0.0, 0.28)
	]), 48), limestone, Vector3.ZERO)
	_ring(root, 0.73, 0.79, 0.28, 0.035, steel)
	_ring(root, 0.73, 0.775, 0.315, 0.018, DesignKit.brass())
	# A slight entasis and a broad, softly flared shoulder conceal the four timber roots.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.33), Vector2(0.75, 0.33), Vector2(0.76, 0.48),
		Vector2(0.74, 1.1), Vector2(0.69, 2.8), Vector2(0.62, 4.2),
		Vector2(0.63, 4.7), Vector2(0.69, 5.05), Vector2(0.81, 5.35),
		Vector2(0.91, 5.52), Vector2(0.94, 5.62), Vector2(0.9, 5.69),
		Vector2(0.0, 5.69)
	]), 64), plaster, Vector3.ZERO)
	_ring(root, 0.86, 0.94, 5.53, 0.055, steel)
	_ring(root, 0.87, 0.945, 5.59, 0.022, DesignKit.brass())
	# Four continuous curved glulam members, splayed into the roof quadrants.
	for arm in 4:
		var angle: float = 45.0 + float(arm) * 90.0
		var turn: Vector3 = Vector3(0.0, angle, 0.0)
		DesignKit.add(root, _branch_mesh(false), oak, Vector3.ZERO, turn)
		DesignKit.add(root, _branch_mesh(true), glow, Vector3.ZERO, turn, false)
		var direction: Vector3 = Vector3(cos(deg_to_rad(angle)), 0.0, -sin(deg_to_rad(angle)))
		# Discreet steel bearing shoes with an oak end-grain cap and brass fasteners.
		var seat: Vector3 = direction * 3.7 + Vector3.UP * 8.82
		var shoe: MeshInstance3D = DesignKit.rbox(root, Vector3(0.88, 0.12, 0.76), seat, steel, 0.045)
		shoe.rotation_degrees.y = angle
		var cap: MeshInstance3D = DesignKit.rbox(root, Vector3(0.78, 0.045, 0.66), seat + Vector3.UP * 0.082, oak, 0.018)
		cap.rotation_degrees.y = angle
		for side in [-1.0, 1.0]:
			var bolt_at: Vector3 = seat + direction * float(side) * 0.27 + Vector3.UP * 0.113
			DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(0.037, 0.0), Vector2(0.037, 0.012), Vector2(0.0, 0.012)
			]), 12), DesignKit.brass(), bolt_at, Vector3.ZERO, false)
	# A multilingual front-facing welcome plaque is mounted clear of the plaster.
	for x: float in [-0.48, 0.48]:
		DesignKit.rbox(root, Vector3(0.07, 0.74, 0.3), Vector3(x, 3.3, 0.7), steel, 0.025)
	Signage.panel(root, Vector3(0.0, 3.3, 0.88), "welcome", {
		"width": 3.2, "scale": 1.35, "accent": accents[choice]
	})
	return root


static func _ring(parent: Node3D, inner: float, outer: float, y: float, height: float, material: Material) -> void:
	DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([
		Vector2(inner, 0.0), Vector2(outer - 0.008, 0.0), Vector2(outer, 0.008),
		Vector2(outer, height - 0.008), Vector2(outer - 0.008, height),
		Vector2(inner, height), Vector2(inner, 0.0)
	]), 48), material, Vector3(0.0, y, 0.0))


static func _branch_mesh(light_strip: bool) -> ArrayMesh:
	var key: String = "soffit" if light_strip else "oak_strut"
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	var steps: int = 28
	var p0: Vector2 = Vector2(0.42, 4.92)
	var p1: Vector2 = Vector2(0.48, 6.7)
	var p2: Vector2 = Vector2(2.05, 7.95)
	var p3: Vector2 = Vector2(3.7, 8.65)
	for step in steps + 1:
		var t: float = float(step) / float(steps)
		var s: float = 1.0 - t
		var centre: Vector2 = s * s * s * p0 + 3.0 * s * s * t * p1 + 3.0 * s * t * t * p2 + t * t * t * p3
		var tangent: Vector2 = (3.0 * s * s * (p1 - p0) + 6.0 * s * t * (p2 - p1) + 3.0 * t * t * (p3 - p2)).normalized()
		var across: Vector3 = Vector3(tangent.y, -tangent.x, 0.0)
		var origin: Vector3 = Vector3(centre.x, centre.y, 0.0)
		var half_width: float = lerpf(0.37, 0.25, t)
		var half_depth: float = lerpf(0.34, 0.24, t)
		if light_strip:
			origin += across * (half_width + 0.005)
			half_width = 0.012
			half_depth = 0.065
		var bevel: float = minf(half_width, half_depth) * 0.27
		var section: PackedVector2Array = PackedVector2Array([
			Vector2(half_width, half_depth - bevel), Vector2(half_width - bevel, half_depth),
			Vector2(-half_width + bevel, half_depth), Vector2(-half_width, half_depth - bevel),
			Vector2(-half_width, -half_depth + bevel), Vector2(-half_width + bevel, -half_depth),
			Vector2(half_width - bevel, -half_depth), Vector2(half_width, -half_depth + bevel)
		])
		var ring: PackedVector3Array = PackedVector3Array()
		for point: Vector2 in section:
			ring.append(origin + across * point.x + Vector3.FORWARD * point.y)
		rings.append(ring)
	for step in steps:
		var lower: PackedVector3Array = rings[step]
		var upper: PackedVector3Array = rings[step + 1]
		for edge in 8:
			var next: int = (edge + 1) % 8
			# Clockwise outward faces; the section's second axis faces -Z.
			_triangle(st, lower[edge], lower[next], upper[edge])
			_triangle(st, lower[next], upper[next], upper[edge])
	var first: PackedVector3Array = rings[0]
	var last: PackedVector3Array = rings[steps]
	for edge in range(1, 7):
		_triangle(st, first[0], first[edge + 1], first[edge])
		_triangle(st, last[0], last[edge], last[edge + 1])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
