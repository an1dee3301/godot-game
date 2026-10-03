extends RefCounted
## A shallow indoor garden: continuous honed coping, quiet water and static koi.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "KoiPond"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var stone_colors: Array[Color] = [Kit.LIMESTONE, Kit.PLASTER, Color(0.72, 0.73, 0.66), Color(0.79, 0.72, 0.63)]
	var stone: StandardMaterial3D = Kit.stone(stone_colors[style], 0.58, "koi_coping_%d" % style)
	Kit.add(root, _basin(), stone, Vector3.ZERO)
	Kit.rbox(root, Vector3(3.84, 0.08, 2.34), Vector3(0.0, 0.04, 0.0), Kit.metal(), 0.035)
	Kit.rbox(root, Vector3(3.36, 0.12, 1.86), Vector3(0.0, 0.12, 0.0), Kit.stone(Color(0.09, 0.15, 0.13), 0.78, "koi_bed"), 0.055)
	Kit.add(root, _water_mesh(), _water(style), Vector3(0.0, 0.392, 0.0), Vector3.ZERO, false)
	# Four fish remain fully below the waterline, with different headings and markings.
	var positions: Array[Vector3] = [Vector3(-0.83, 0.30, 0.03), Vector3(0.10, 0.29, -0.30), Vector3(0.76, 0.31, 0.30), Vector3(-0.03, 0.30, 0.48)]
	var headings: Array[float] = [58.0, -43.0, 138.0, -112.0]
	for i in positions.size():
		_koi(root, positions[i], headings[i] + float(style) * 13.0, posmod(i + style, 3))
	var pad_color: Color = Kit.SAGE.darkened(0.27 + float(style) * 0.025)
	var pads: Array[Vector3] = [Vector3(-1.16, 0.397, -0.46), Vector3(-0.90, 0.40, -0.61), Vector3(1.12, 0.397, -0.48), Vector3(1.27, 0.401, -0.24)]
	for i in pads.size():
		var pad: MeshInstance3D = Kit.add(root, _pad(), Kit.paint(pad_color.lightened(float(i % 2) * 0.08), 0.83), pads[i], Vector3(0.0, float(i * 79 + style * 27), 0.0), false)
		pad.scale = Vector3.ONE * (0.78 if i % 2 == 1 else 1.0)
		# A raised central vein follows each leaf's notch.
		Kit.rbox(pad, Vector3(0.007, 0.004, 0.22), Vector3(0.0, 0.006, -0.05), Kit.paint(Kit.SAGE, 0.85), 0.001, false)
	# A low walnut fascia and brass rule identify the garden from the approach.
	Kit.rbox(root, Vector3(2.96, 0.31, 0.032), Vector3(0.0, 0.245, 1.249), Kit.wood(Kit.WALNUT, "koi_walnut"), 0.014)
	Kit.rbox(root, Vector3(2.72, 0.012, 0.012), Vector3(0.0, 0.377, 1.27), Kit.brass(), 0.004, false)
	var caption: Label3D = Label3D.new()
	caption.name = "GardenTitle"
	caption.text = "Koi Pond   鯉の池   锦鲤池"
	caption.font = Signs.font()
	caption.font_size = 80
	caption.pixel_size = 0.0026
	caption.position = Vector3(0.0, 0.242, 1.271)
	caption.modulate = Kit.CREAM
	caption.outline_size = 0
	caption.double_sided = false
	caption.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(caption)
	# A flush rear overflow grille is a practical detail, away from the viewing edge.
	Kit.rbox(root, Vector3(0.43, 0.014, 0.13), Vector3(0.93, 0.495, -1.10), Kit.metal(), 0.015, false)
	for i in 6:
		Kit.rbox(root, Vector3(0.008, 0.008, 0.095), Vector3(0.78 + float(i) * 0.06, 0.505, -1.10), Kit.brass(), 0.002, false)
	return root


static func _contour(width: float, depth: float, radius: float) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for corner in 4:
		var angle: float = float(corner) * PI * 0.5
		var center: Vector3 = Vector3((width * 0.5 - radius) * (1.0 if corner == 0 or corner == 3 else -1.0), 0.0, (depth * 0.5 - radius) * (1.0 if corner < 2 else -1.0))
		for step in 9:
			var theta: float = angle + float(step) / 8.0 * PI * 0.5
			points.append(center + Vector3(cos(theta) * radius, 0.0, sin(theta) * radius))
	return points


static func _basin() -> ArrayMesh:
	if _meshes.has("basin"):
		return _meshes["basin"] as ArrayMesh
	# x/z are full dimensions; y is elevation. The section folds over the coping
	# and back down the inner wall, leaving a real open aperture rather than a slab.
	var sections: Array[Vector3] = [Vector3(3.92, 0.0, 2.42), Vector3(4.0, 0.045, 2.5), Vector3(4.0, 0.435, 2.5), Vector3(3.94, 0.49, 2.44), Vector3(3.43, 0.49, 1.93), Vector3(3.34, 0.435, 1.84), Vector3(3.34, 0.15, 1.84)]
	var radii: Array[float] = [0.36, 0.40, 0.40, 0.37, 0.28, 0.24, 0.24]
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for section in sections.size() - 1:
		var lower: Vector3 = sections[section]
		var upper: Vector3 = sections[section + 1]
		var a_ring: PackedVector3Array = _contour(lower.x, lower.z, radii[section])
		var b_ring: PackedVector3Array = _contour(upper.x, upper.z, radii[section + 1])
		for i in a_ring.size():
			var next: int = (i + 1) % a_ring.size()
			var a: Vector3 = a_ring[i] + Vector3.UP * lower.y
			var b: Vector3 = a_ring[next] + Vector3.UP * lower.y
			var c: Vector3 = b_ring[next] + Vector3.UP * upper.y
			var d: Vector3 = b_ring[i] + Vector3.UP * upper.y
			for vertex: Vector3 in [a, d, b, b, d, c]:
				st.add_vertex(vertex)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["basin"] = mesh
	return mesh


static func _water_mesh() -> ArrayMesh:
	if _meshes.has("water"):
		return _meshes["water"] as ArrayMesh
	var perimeter: PackedVector3Array = _contour(3.335, 1.835, 0.238)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in perimeter.size():
		for vertex: Vector3 in [Vector3.ZERO, perimeter[(i + 1) % perimeter.size()], perimeter[i]]:
			st.set_normal(Vector3.UP)
			st.add_vertex(vertex)
	var mesh: ArrayMesh = st.commit()
	_meshes["water"] = mesh
	return mesh


static func _water(style: int) -> StandardMaterial3D:
	var key: String = "water_%d" % style
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.045, 0.115 + float(style) * 0.009, 0.105, 0.46)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.16
	material.metallic = 0.18
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


static func _ellipsoid() -> SphereMesh:
	if _meshes.has("ellipsoid"):
		return _meshes["ellipsoid"] as SphereMesh
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 20
	mesh.rings = 10
	_meshes["ellipsoid"] = mesh
	return mesh


static func _blob(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	var piece: MeshInstance3D = Kit.add(parent, _ellipsoid(), material, at, Vector3.ZERO, false)
	piece.scale = size


static func _koi(parent: Node3D, at: Vector3, heading: float, pattern: int) -> void:
	var fish: Node3D = Node3D.new()
	fish.name = "SubmergedKoi"
	fish.position = at
	fish.rotation_degrees.y = heading
	parent.add_child(fish)
	var ivory: StandardMaterial3D = Kit.paint(Color(0.87, 0.87, 0.73), 0.36)
	var orange: StandardMaterial3D = Kit.paint(Color(0.92, 0.33, 0.085), 0.4)
	var skin: StandardMaterial3D = orange if pattern == 1 else ivory
	_blob(fish, Vector3.ZERO, Vector3(0.071, 0.04, 0.21), skin)
	_blob(fish, Vector3(0.0, -0.003, 0.15), Vector3(0.061, 0.035, 0.067), skin)
	_blob(fish, Vector3(0.0, 0.035, 0.095), Vector3(0.048, 0.012, 0.056), ivory if pattern == 1 else orange)
	_blob(fish, Vector3(-0.016, 0.033, -0.055), Vector3(0.043, 0.012, 0.068), orange if pattern == 0 else ivory)
	# Flattened turned fans give the koi a forked tail and swept pectoral fins.
	var fin_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.036, 0.01), Vector2(0.055, 0.025), Vector2(0.01, 0.03), Vector2(0.0, 0.03)]), 12)
	for side: float in [-1.0, 1.0]:
		var tail: MeshInstance3D = Kit.add(fish, fin_mesh, ivory, Vector3(side * 0.035, 0.0, -0.224), Vector3(70.0, side * 30.0, 0.0), false)
		tail.scale = Vector3(0.8, 1.0, 0.3)
		var fin: MeshInstance3D = Kit.add(fish, fin_mesh, ivory, Vector3(side * 0.075, -0.008, 0.065), Vector3(0.0, 0.0, side * 65.0), false)
		fin.scale = Vector3(1.0, 1.0, 0.15)
		_blob(fish, Vector3(side * 0.043, 0.021, 0.18), Vector3(0.006, 0.006, 0.006), Kit.paint(Kit.CHARCOAL))


static func _pad() -> ArrayMesh:
	if _meshes.has("pad"):
		return _meshes["pad"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The open wedge is the characteristic lily-pad cleft, with a softly curled edge.
	for i in 30:
		var a: float = 0.18 + float(i) / 30.0 * (TAU - 0.36)
		var b: float = 0.18 + float(i + 1) / 30.0 * (TAU - 0.36)
		for vertex: Vector3 in [Vector3(0.025, 0.005, 0.0), Vector3(cos(b) * 0.19, 0.002, sin(b) * 0.17), Vector3(cos(a) * 0.19, 0.002, sin(a) * 0.17)]:
			st.set_normal(Vector3.UP)
			st.add_vertex(vertex)
	var mesh: ArrayMesh = st.commit()
	_meshes["pad"] = mesh
	return mesh
