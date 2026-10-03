extends RefCounted
## Long-wheelbase apron workshop; +Z is the bonnet, tyres meet y = 0.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "MaintenanceVan"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colours: Array[Color] = [Color(0.95, 0.70, 0.19), Kit.CREAM, Kit.SAGE, Kit.CHARCOAL]
	var body: StandardMaterial3D = Kit.paint(colours[scheme], 0.38)
	var stripe: StandardMaterial3D = Kit.brass() if scheme == 3 else Kit.paint(Kit.CLAY if scheme == 1 else Kit.CREAM, 0.5)
	var steel: StandardMaterial3D = Kit.metal(Kit.CHARCOAL, 0.44, 0.72, "maintenance_steel")
	var alloy: StandardMaterial3D = Kit.metal(Color(0.64, 0.65, 0.61), 0.3, 0.9, "maintenance_alloy")
	var rubber: StandardMaterial3D = Kit.paint(Color(0.045, 0.042, 0.038), 0.94)
	var glass: StandardMaterial3D = Kit.metal(Color(0.10, 0.18, 0.20), 0.16, 0.35, "maintenance_glass")
	var lamp: StandardMaterial3D = Kit.washi(Color(1.0, 0.91, 0.71), 3.0, "maintenance_headlamp")
	var amber: StandardMaterial3D = Kit.washi(Color(1.0, 0.41, 0.035), 3.5, "maintenance_amber")
	var red: StandardMaterial3D = Kit.washi(Color(0.8, 0.075, 0.035), 1.8, "maintenance_tail")

	# Side contour includes real open wheel arches, a short bonnet and sloping cab.
	var profile: PackedVector2Array = PackedVector2Array([
		Vector2(-2.60, 0.64), Vector2(-2.03, 0.64), Vector2(-2.03, 0.76),
		Vector2(-1.93, 1.01), Vector2(-1.72, 1.14), Vector2(-1.48, 1.14),
		Vector2(-1.27, 1.01), Vector2(-1.17, 0.76), Vector2(-1.17, 0.64),
		Vector2(1.14, 0.64), Vector2(1.14, 0.76), Vector2(1.24, 1.01),
		Vector2(1.45, 1.14), Vector2(1.69, 1.14), Vector2(1.90, 1.01),
		Vector2(2.00, 0.76), Vector2(2.00, 0.64), Vector2(2.60, 0.64),
		Vector2(2.60, 1.29), Vector2(2.48, 1.42), Vector2(1.77, 1.50),
		Vector2(1.03, 2.29), Vector2(0.83, 2.39), Vector2(-2.43, 2.39),
		Vector2(-2.60, 2.22)
	])
	Kit.add(root, _extrusion("shell", profile, 1.0), body, Vector3.ZERO)
	# Soft roof cap and bonnet conceal the broad shell edges.
	Kit.rbox(root, Vector3(2.02, 0.16, 3.48), Vector3(0, 2.34, -0.85), body, 0.075)
	Kit.rbox(root, Vector3(2.01, 0.12, 0.77), Vector3(0, 1.43, 2.13), body, 0.055)
	Kit.rbox(root, Vector3(1.55, 0.18, 4.32), Vector3(0, 0.49, -0.05), steel, 0.06)
	for z: float in [-2.64, 2.65]:
		Kit.rbox(root, Vector3(2.12, 0.23, 0.19), Vector3(0, 0.72, z), steel, 0.07)
		Kit.rbox(root, Vector3(1.56, 0.065, 0.035), Vector3(0, 0.77, z + signf(z) * 0.105), stripe, 0.02, false)

	# Radially turned tyres: shoulders, sidewalls and a broad rounded tread.
	var tyre_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.23, -0.15), Vector2(0.35, -0.15), Vector2(0.39, -0.11),
		Vector2(0.405, -0.07), Vector2(0.405, 0.07), Vector2(0.39, 0.11),
		Vector2(0.35, 0.15), Vector2(0.23, 0.15), Vector2(0.23, -0.15)
	]), 32)
	var hub_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0, 0), Vector2(0.23, 0), Vector2(0.235, 0.025),
		Vector2(0.20, 0.055), Vector2(0.10, 0.055), Vector2(0.075, 0.08), Vector2(0, 0.08)
	]), 24)
	for side: float in [-1.0, 1.0]:
		for z: float in [-1.60, 1.57]:
			Kit.add(root, tyre_mesh, rubber, Vector3(side * 0.98, 0.405, z), Vector3(0, 0, -90))
			Kit.add(root, hub_mesh, alloy, Vector3(side * 1.13, 0.405, z), Vector3(0, 0, -90 * side))
		# Cargo stripe, sliding-door seam and low step rail.
		Kit.rbox(root, Vector3(0.025, 0.13, 3.33), Vector3(side * 1.014, 0.87, -0.85), stripe, 0.01, false)
		Kit.rbox(root, Vector3(0.018, 1.48, 0.018), Vector3(side * 1.008, 1.49, -0.35), steel, 0.006, false)
		Kit.rbox(root, Vector3(0.023, 1.13, 0.018), Vector3(side * 1.013, 1.33, 0.48), steel, 0.007, false)
		Kit.rbox(root, Vector3(0.07, 0.085, 0.25), Vector3(side * 1.035, 1.28, 0.25), steel, 0.035, false)
		Kit.rbox(root, Vector3(0.075, 0.08, 0.27), Vector3(side * 1.035, 1.28, -0.58), alloy, 0.035, false)
		Kit.rbox(root, Vector3(0.18, 0.08, 1.62), Vector3(side * 1.04, 0.60, 0.31), steel, 0.03)
		# Shaped cab windows share the actual windscreen slope.
		var window_profile: PackedVector2Array = PackedVector2Array([
			Vector2(0.55, 1.57), Vector2(1.61, 1.57), Vector2(0.97, 2.23), Vector2(0.55, 2.23)
		])
		Kit.add(root, _extrusion("side_window", window_profile, 0.008), glass, Vector3(side * 1.012, 0, 0))
		Kit.rbox(root, Vector3(0.025, 0.62, 0.045), Vector3(side * 1.025, 1.88, 0.86), steel, 0.015, false)
		Kit.rbox(root, Vector3(0.20, 0.055, 0.08), Vector3(side * 1.10, 1.52, 1.22), steel, 0.025, false)
		Kit.rbox(root, Vector3(0.15, 0.27, 0.18), Vector3(side * 1.23, 1.62, 1.25), steel, 0.06)
		Kit.rbox(root, Vector3(0.012, 0.19, 0.12), Vector3(side * 1.311, 1.63, 1.25), alloy, 0.006, false)
		# Side-mounted operator lettering: all six airport languages, generously sized.
		var lettering: Node3D = Node3D.new()
		lettering.position = Vector3(side * 1.025, 1.89, -1.20)
		lettering.rotation_degrees.y = 90.0 * side
		root.add_child(lettering)
		var ink: Color = Kit.CREAM if scheme == 3 else Kit.CHARCOAL
		_caption(lettering, "MAINTENANCE", 0.0, 64, 0.0048, ink)
		_caption(lettering, "整備 · 维护", -0.28, 58, 0.0042, ink)
		_caption(lettering, "Bảo trì", -0.52, 56, 0.0042, ink)
		_caption(lettering, "Entretien · Mantenimiento", -0.75, 46, 0.0040, ink)

	var windscreen: MeshInstance3D = Kit.rbox(root, Vector3(1.80, 0.94, 0.028), Vector3(0, 1.91, 1.413), glass, 0.013)
	windscreen.rotation_degrees.x = -43.0
	for x: float in [-0.43, 0.43]:
		var wiper: MeshInstance3D = Kit.rbox(root, Vector3(0.52, 0.025, 0.025), Vector3(x, 1.64, 1.69), steel, 0.011, false)
		wiper.rotation_degrees.z = -9.0
	Kit.rbox(root, Vector3(1.13, 0.26, 0.035), Vector3(0, 1.02, 2.613), steel, 0.016)
	for i: int in 3:
		Kit.rbox(root, Vector3(1.0, 0.017, 0.012), Vector3(0, 0.94 + float(i) * 0.075, 2.638), alloy, 0.005, false)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.39, 0.22, 0.045), Vector3(side * 0.78, 1.13, 2.62), steel, 0.021)
		Kit.rbox(root, Vector3(0.31, 0.14, 0.025), Vector3(side * 0.77, 1.15, 2.655), lamp, 0.012, false)
		Kit.rbox(root, Vector3(0.08, 0.12, 0.025), Vector3(side * 0.96, 1.14, 2.65), amber, 0.012, false)
		Kit.rbox(root, Vector3(0.15, 0.49, 0.045), Vector3(side * 0.85, 1.11, -2.62), steel, 0.022)
		Kit.rbox(root, Vector3(0.11, 0.28, 0.024), Vector3(side * 0.85, 1.17, -2.653), red, 0.012, false)
		Kit.rbox(root, Vector3(0.11, 0.10, 0.024), Vector3(side * 0.85, 0.96, -2.653), amber, 0.012, false)
	# Paired rear doors and a broad operator-colour identification band.
	Kit.rbox(root, Vector3(0.022, 1.56, 0.02), Vector3(0, 1.49, -2.614), steel, 0.007, false)
	Kit.rbox(root, Vector3(0.34, 0.085, 0.06), Vector3(0.19, 1.28, -2.64), alloy, 0.025, false)
	Kit.rbox(root, Vector3(1.32, 0.20, 0.025), Vector3(0, 1.80, -2.612), stripe, 0.012, false)

	# Roof rack: four feet, transverse bars and a strapped extension ladder.
	for z: float in [-1.85, 0.43]:
		for x: float in [-0.80, 0.80]:
			Kit.rbox(root, Vector3(0.20, 0.05, 0.28), Vector3(x, 2.425, z), rubber, 0.023, false)
			Kit.rbox(root, Vector3(0.065, 0.20, 0.10), Vector3(x, 2.53, z), steel, 0.025)
		Kit.rbox(root, Vector3(1.86, 0.075, 0.10), Vector3(0, 2.65, z), steel, 0.032)
	for x: float in [-0.37, 0.37]:
		Kit.rbox(root, Vector3(0.075, 0.14, 4.13), Vector3(x, 2.755, -0.65), alloy, 0.027)
		Kit.rbox(root, Vector3(0.06, 0.085, 3.55), Vector3(x * 0.82, 2.865, -0.88), alloy, 0.021)
		for z: float in [-2.71, 1.41]:
			Kit.rbox(root, Vector3(0.085, 0.15, 0.12), Vector3(x, 2.755, z), rubber, 0.029, false)
	for i: int in 11:
		Kit.rbox(root, Vector3(0.68, 0.045, 0.065), Vector3(0, 2.77, -2.45 + float(i) * 0.36), alloy, 0.02, false)
	for z: float in [-1.85, 0.43]:
		Kit.rbox(root, Vector3(0.85, 0.025, 0.085), Vector3(0, 2.922, z), Kit.fabric(Kit.CLAY, "maintenance_strap"), 0.01, false)
		Kit.rbox(root, Vector3(0.09, 0.045, 0.10), Vector3(0.45, 2.91, z), Kit.brass(), 0.012, false)
	Kit.rbox(root, Vector3(0.32, 0.08, 0.33), Vector3(0.70, 2.45, 0.72), steel, 0.035)
	var beacon_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0, 0), Vector2(0.13, 0), Vector2(0.14, 0.03), Vector2(0.14, 0.20),
		Vector2(0.11, 0.25), Vector2(0.06, 0.28), Vector2(0, 0.28)
	]), 24)
	Kit.add(root, beacon_mesh, amber, Vector3(0.70, 2.49, 0.72), Vector3.ZERO, false)
	return root


static func _caption(parent: Node3D, caption: String, y: float, size: int, pixels: float, colour: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signs.font()
	label.text = caption
	label.font_size = size
	label.pixel_size = pixels
	label.modulate = colour
	label.outline_size = 0
	label.position.y = y
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _extrusion(key: String, profile: PackedVector2Array, half_width: float) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(profile)
	for side: float in [-1.0, 1.0]:
		for t: int in range(0, indices.size(), 3):
			for j: int in 3:
				var index: int = indices[t + (j if side > 0.0 else 2 - j)]
				var p: Vector2 = profile[index]
				st.set_normal(Vector3(side, 0, 0))
				st.add_vertex(Vector3(side * half_width, p.y, p.x))
	for i: int in profile.size():
		var p: Vector2 = profile[i]
		var q: Vector2 = profile[(i + 1) % profile.size()]
		var a: Vector3 = Vector3(-half_width, p.y, p.x)
		var b: Vector3 = Vector3(half_width, p.y, p.x)
		var c: Vector3 = Vector3(half_width, q.y, q.x)
		var d: Vector3 = Vector3(-half_width, q.y, q.x)
		var normal: Vector3 = Vector3(0, p.x - q.x, q.y - p.y).normalized()
		for vertex: Vector3 in [a, c, b, a, d, c]:
			st.set_normal(normal)
			st.add_vertex(vertex)
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh
