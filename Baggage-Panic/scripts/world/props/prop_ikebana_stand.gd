extends RefCounted
## Quiet, asymmetric ikebana: an open stoneware vessel on a three-legged oak stand.
## Botanical geometry is batched by material and cached for each of four arrangements.

const KIT = preload("res://scripts/world/design_kit.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "IkebanaStand"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var v: int = posmod(variant, 4)
	var glazes: Array[Color] = [KIT.CREAM, KIT.SAGE, KIT.CLAY, KIT.INDIGO]
	var petals: Array[Color] = [Color(0.94, 0.75, 0.73), KIT.CREAM, Color(0.97, 0.86, 0.77), Color(0.83, 0.72, 0.79)]
	var oak: StandardMaterial3D = KIT.wood(KIT.OAK, "oak")
	var walnut: StandardMaterial3D = KIT.wood(KIT.WALNUT, "walnut")
	var ceramic: StandardMaterial3D = KIT.stone(glazes[v], 0.29, "ikebana_glaze_%d" % v)
	var bark: StandardMaterial3D = KIT.wood(Color(0.31, 0.25, 0.19), "ikebana_bark")
	# Three splayed legs with quiet brass ferrules and walnut joinery below the top.
	for i: int in 3:
		var angle: float = TAU * float(i) / 3.0 + PI * 0.5
		var direction: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var foot: Vector3 = direction * 0.20 + Vector3.UP * 0.012
		var shoulder: Vector3 = direction * 0.13 + Vector3.UP * 0.755
		var leg: MeshInstance3D = KIT.add(root, KIT.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.017, 0.0), Vector2(0.021, 0.025),
			Vector2(0.025, foot.distance_to(shoulder)), Vector2(0.0, foot.distance_to(shoulder))
		]), 12), oak, foot)
		leg.quaternion = Quaternion(Vector3.UP, (shoulder - foot).normalized())
		var ferrule: MeshInstance3D = KIT.add(root, KIT.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.019, 0.0), Vector2(0.021, 0.028), Vector2(0.0, 0.028)
		]), 12), KIT.brass(), direction * 0.20)
		ferrule.quaternion = leg.quaternion
		var brace: MeshInstance3D = KIT.rbox(root, Vector3(0.026, 0.035, 0.27), direction * 0.065 + Vector3.UP * 0.62, walnut, 0.009)
		brace.rotation.y = PI * 0.5 - angle
	KIT.add(root, KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.747), Vector2(0.202, 0.747), Vector2(0.22, 0.755),
		Vector2(0.223, 0.77), Vector2(0.22, 0.789), Vector2(0.205, 0.798), Vector2(0.0, 0.798)
	]), 40), oak, Vector3.ZERO)
	# A linen coaster cushions the unglazed foot ring.
	KIT.add(root, KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.124, 0.004),
		Vector2(0.12, 0.009), Vector2(0.0, 0.009)
	]), 32), KIT.fabric(KIT.LINEN, "linen"), Vector3(0.0, 0.798, 0.0))
	KIT.add(root, KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.076, 0.0), Vector2(0.078, 0.017), Vector2(0.0, 0.017)
	]), 32), KIT.stone(KIT.CLAY.lightened(0.19), 0.8, "ikebana_unglazed"), Vector3(0.0, 0.807, 0.0))
	# Continuous profile returns down the inside: real wall thickness and a visible open mouth.
	KIT.add(root, KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.016), Vector2(0.072, 0.016), Vector2(0.102, 0.035),
		Vector2(0.13, 0.086), Vector2(0.137, 0.14), Vector2(0.126, 0.193),
		Vector2(0.096, 0.23), Vector2(0.063, 0.244), Vector2(0.059, 0.267),
		Vector2(0.054, 0.272), Vector2(0.047, 0.269), Vector2(0.047, 0.245),
		Vector2(0.083, 0.223), Vector2(0.112, 0.187), Vector2(0.123, 0.14),
		Vector2(0.115, 0.09), Vector2(0.086, 0.045), Vector2(0.0, 0.034)
	]), 48), ceramic, Vector3(0.0, 0.807, 0.0))
	KIT.add(root, KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.045, 0.0), Vector2(0.0, 0.001)
	]), 24), KIT.paint(Color(0.11, 0.14, 0.12), 0.22), Vector3(0.0, 1.045, 0.0))
	_ensure_botanicals(v)
	var branches: ArrayMesh = _meshes["branches_%d" % v]
	var blossoms: ArrayMesh = _meshes["blossoms_%d" % v]
	var hearts: ArrayMesh = _meshes["hearts_%d" % v]
	var leaves: ArrayMesh = _meshes["leaves_%d" % v]
	var stem: ArrayMesh = _meshes["stem_%d" % v]
	var bold: ArrayMesh = _meshes["bold_%d" % v]
	KIT.add(root, branches, bark, Vector3.ZERO)
	KIT.add(root, blossoms, KIT.paint(petals[v], 0.74), Vector3.ZERO)
	KIT.add(root, hearts, KIT.paint(KIT.OCHRE, 0.65), Vector3.ZERO)
	KIT.add(root, leaves, KIT.paint(KIT.SAGE.darkened(0.18), 0.78), Vector3.ZERO)
	KIT.add(root, stem, KIT.paint(Color(0.32, 0.41, 0.24), 0.72), Vector3.ZERO)
	KIT.add(root, bold, KIT.paint(KIT.OCHRE if v % 2 == 0 else KIT.CLAY.lightened(0.12), 0.63), Vector3.ZERO)
	return root


static func _ensure_botanicals(v: int) -> void:
	if _meshes.has("branches_%d" % v):
		return
	var branch_tool: SurfaceTool = _begin()
	var blossom_tool: SurfaceTool = _begin()
	var heart_tool: SurfaceTool = _begin()
	var leaf_tool: SurfaceTool = _begin()
	var stem_tool: SurfaceTool = _begin()
	var bold_tool: SurfaceTool = _begin()
	var side: float = -1.0 if v % 2 == 1 else 1.0
	var sweep: float = 0.018 * float(v)
	var main: PackedVector3Array = PackedVector3Array([
		Vector3(-0.015, 1.04, 0.0), Vector3(-0.07 * side, 1.16, -0.01),
		Vector3(-0.19 * side, 1.29, -0.025), Vector3(-0.29 * side, 1.40, 0.015),
		Vector3((-0.36 - sweep) * side, 1.49, 0.035)
	])
	_tube(branch_tool, main, 0.008, 0.002)
	var tips: PackedVector3Array = PackedVector3Array()
	tips.append(main[4])
	for i: int in 3:
		var start: Vector3 = main[i + 1]
		var tip: Vector3 = start + Vector3((-0.09 - 0.02 * float(i)) * side, 0.035 + 0.035 * float(i), 0.11 - float(i) * 0.025)
		_tube(branch_tool, PackedVector3Array([start, start.lerp(tip, 0.6) + Vector3.UP * 0.025, tip]), 0.004, 0.0014)
		tips.append(tip)
		tips.append(start.lerp(tip, 0.64))
	var low_tip: Vector3 = Vector3(0.26 * side, 1.23 + sweep, 0.075)
	_tube(branch_tool, PackedVector3Array([Vector3(0.012, 1.04, 0.01), Vector3(0.1 * side, 1.19, 0.04), low_tip]), 0.006, 0.0017)
	tips.append(low_tip)
	tips.append(Vector3(0.16 * side, 1.215, 0.06))
	for i: int in tips.size():
		var centre: Vector3 = tips[i]
		var tilt: Basis = Basis(Vector3.RIGHT, -0.2 + 0.13 * float(i % 3))
		for p: int in 5:
			var angle: float = TAU * float(p) / 5.0 + float(i) * 0.7
			var radial: Vector3 = Vector3(cos(angle), sin(angle), 0.0)
			_ellipsoid(blossom_tool, centre + tilt * radial * 0.018, Vector3(0.018, 0.012, 0.005), tilt * Basis(Vector3.BACK, angle))
		_ellipsoid(heart_tool, centre + tilt * Vector3(0.0, 0.0, 0.006), Vector3(0.007, 0.007, 0.004), tilt)
	# The tall primary stem carries a single sculptural, three-petalled iris.
	var crown: Vector3 = Vector3((0.10 + sweep) * side, 1.553, -0.035)
	_tube(stem_tool, PackedVector3Array([
		Vector3(0.008, 1.035, -0.01), Vector3(0.025 * side, 1.24, -0.035),
		Vector3(0.08 * side, 1.44, -0.045), crown
	]), 0.008, 0.004)
	for p: int in 3:
		var angle: float = TAU * float(p) / 3.0 + 0.2
		var radial: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		_ellipsoid(bold_tool, crown + radial * 0.022 + Vector3.UP * 0.014, Vector3(0.025, 0.044, 0.012), Basis(Vector3.UP, -angle) * Basis(Vector3.FORWARD, 0.3))
		_ellipsoid(bold_tool, crown + radial * 0.044 - Vector3.UP * 0.018, Vector3(0.037, 0.013, 0.02), Basis(Vector3.UP, -angle))
	_ellipsoid(heart_tool, crown, Vector3(0.011, 0.031, 0.011), Basis.IDENTITY)
	for i: int in 3:
		var centre: Vector3 = Vector3((0.035 + 0.035 * float(i)) * side, 1.16 + float(i) * 0.075, 0.022)
		_ellipsoid(leaf_tool, centre, Vector3(0.016, 0.085, 0.005), Basis(Vector3.BACK, (-0.55 if i % 2 == 0 else 0.55) * side))
	_store("branches", v, branch_tool)
	_store("blossoms", v, blossom_tool)
	_store("hearts", v, heart_tool)
	_store("leaves", v, leaf_tool)
	_store("stem", v, stem_tool)
	_store("bold", v, bold_tool)


static func _begin() -> SurfaceTool:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	return tool


static func _store(key: String, v: int, tool: SurfaceTool) -> void:
	tool.generate_normals()
	_meshes["%s_%d" % [key, v]] = tool.commit()


static func _tube(tool: SurfaceTool, points: PackedVector3Array, start_radius: float, end_radius: float) -> void:
	for i: int in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var axis: Vector3 = (b - a).normalized()
		var u: Vector3 = axis.cross(Vector3.FORWARD).normalized()
		var w: Vector3 = axis.cross(u).normalized()
		var r0: float = lerpf(start_radius, end_radius, float(i) / float(points.size() - 1))
		var r1: float = lerpf(start_radius, end_radius, float(i + 1) / float(points.size() - 1))
		for s: int in 8:
			var t0: float = TAU * float(s) / 8.0
			var t1: float = TAU * float(s + 1) / 8.0
			var n0: Vector3 = u * cos(t0) + w * sin(t0)
			var n1: Vector3 = u * cos(t1) + w * sin(t1)
			_triangle(tool, a + n0 * r0, b + n0 * r1, a + n1 * r0)
			_triangle(tool, a + n1 * r0, b + n0 * r1, b + n1 * r1)


static func _ellipsoid(tool: SurfaceTool, centre: Vector3, size: Vector3, orientation: Basis) -> void:
	for ring: int in 6:
		var phi0: float = PI * float(ring) / 6.0
		var phi1: float = PI * float(ring + 1) / 6.0
		for s: int in 10:
			var theta0: float = TAU * float(s) / 10.0
			var theta1: float = TAU * float(s + 1) / 10.0
			var a: Vector3 = centre + orientation * (Vector3(sin(phi0) * cos(theta0), cos(phi0), sin(phi0) * sin(theta0)) * size)
			var b: Vector3 = centre + orientation * (Vector3(sin(phi1) * cos(theta0), cos(phi1), sin(phi1) * sin(theta0)) * size)
			var c: Vector3 = centre + orientation * (Vector3(sin(phi1) * cos(theta1), cos(phi1), sin(phi1) * sin(theta1)) * size)
			var d: Vector3 = centre + orientation * (Vector3(sin(phi0) * cos(theta1), cos(phi0), sin(phi0) * sin(theta1)) * size)
			_triangle(tool, a, b, d)
			_triangle(tool, d, b, c)


static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)
