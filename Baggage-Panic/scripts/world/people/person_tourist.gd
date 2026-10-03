extends RefCounted
## A quietly delighted traveller, studying a folded terminal map.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Tourist"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 3)
	var shirts: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.CREAM]
	var trousers: Array[Color] = [DesignKit.LINEN, DesignKit.INDIGO, DesignKit.SAGE]
	var skins: Array[Color] = [Color(0.73, 0.49, 0.33), Color(0.91, 0.69, 0.51), Color(0.49, 0.31, 0.23)]
	var hairs: Array[Color] = [DesignKit.WALNUT, DesignKit.CHARCOAL, Color(0.66, 0.57, 0.45)]
	var shirt: Material = DesignKit.fabric(shirts[choice], "tourist_shirt_%d" % choice)
	var pants: Material = DesignKit.fabric(trousers[choice], "tourist_pants_%d" % choice)
	var skin: Material = DesignKit.paint(skins[choice], 0.88)
	var hair: Material = DesignKit.paint(hairs[choice], 0.94)
	var leather: Material = DesignKit.fabric(DesignKit.WALNUT, "tourist_leather")
	var sole: Material = DesignKit.paint(DesignKit.CREAM)
	var dark: Material = DesignKit.metal(DesignKit.CHARCOAL, 0.5, 0.35, "tourist_camera")
	var straw: Material = DesignKit.fabric(DesignKit.OCHRE.lightened(0.28), "tourist_straw")
	for side: float in [-1.0, 1.0]:
		var x: float = side * 0.115
		var shoe: MeshInstance3D = _oval(root, Vector3(x, 0.063, 0.04), Vector3(0.09, 0.063, 0.16), sole)
		shoe.rotation_degrees.y = side * 7.0
		_oval(root, Vector3(x, 0.089, 0.047), Vector3(0.084, 0.059, 0.15), leather)
		_limb(root, Vector3(x, 0.14, 0.0), Vector3(x, 0.76, 0.0), 0.085, pants)
	# A tailored, softly tapered linen shirt rather than a rectangular torso.
	var torso: MeshInstance3D = DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.70), Vector2(0.15, 0.70), Vector2(0.20, 0.75),
		Vector2(0.215, 1.06), Vector2(0.24, 1.20), Vector2(0.19, 1.29),
		Vector2(0.075, 1.32), Vector2(0.0, 1.32)]), 16), shirt, Vector3.ZERO)
	torso.scale.z = 0.64
	var hem: MeshInstance3D = DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.19, 0.73), Vector2(0.201, 0.742), Vector2(0.201, 0.757), Vector2(0.194, 0.765)]), 16), pants, Vector3.ZERO)
	hem.scale.z = 0.65
	_limb(root, Vector3(0.0, 1.26, 0.0), Vector3(0.0, 1.40, 0.0), 0.069, skin)
	_oval(root, Vector3(0.0, 1.49, 0.012), Vector3(0.156, 0.188, 0.143), skin)
	for side: float in [-1.0, 1.0]:
		_oval(root, Vector3(side * 0.15, 1.49, 0.012), Vector3(0.027, 0.043, 0.031), skin)
		_oval(root, Vector3(side * 0.052, 1.50, 0.145), Vector3(0.014, 0.020, 0.010), DesignKit.paint(DesignKit.CHARCOAL))
	_oval(root, Vector3(0.0, 1.467, 0.155), Vector3(0.024, 0.029, 0.028), skin)
	var hair_shape: MeshInstance3D = _oval(root, Vector3(0.0, 1.555, -0.055), Vector3(0.161, 0.126, 0.122), hair)
	if choice == 1:
		hair_shape.scale.y = 1.35
	# Turned sunhat: curved brim, woven crown, and a contrasting grosgrain band.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.15, 0.0), Vector2(0.235, -0.015),
		Vector2(0.305, -0.037), Vector2(0.312, -0.025), Vector2(0.295, -0.012),
		Vector2(0.21, 0.012), Vector2(0.15, 0.022), Vector2(0.0, 0.022)]), 24), straw, Vector3(0.0, 1.66, 0.0))
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.151, 0.0), Vector2(0.146, 0.079),
		Vector2(0.127, 0.115), Vector2(0.085, 0.131), Vector2(0.0, 0.134)]), 20), straw, Vector3(0.0, 1.66, 0.0))
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.151, 0.0), Vector2(0.154, 0.004), Vector2(0.150, 0.036), Vector2(0.148, 0.04)]), 20), pants, Vector3(0.0, 1.678, 0.0))
	# Elbows relaxed outward; both hands support the open map.
	for side: float in [-1.0, 1.0]:
		var elbow: Vector3 = Vector3(side * 0.295, 0.995, 0.13)
		var hand: Vector3 = Vector3(side * 0.275, 1.015, 0.395)
		_limb(root, Vector3(side * 0.19, 1.20, 0.0), elbow, 0.076, shirt)
		_limb(root, elbow, hand, 0.045, skin)
		_oval(root, hand, Vector3(0.047, 0.051, 0.042), skin)
	# Narrow camera straps descend from the collar, terminating at the camera lugs.
	for side: float in [-1.0, 1.0]:
		_limb(root, Vector3(side * 0.082, 1.30, 0.076), Vector3(side * 0.13, 1.148, 0.215), 0.012, leather)
	DesignKit.rbox(root, Vector3(0.275, 0.155, 0.095), Vector3(0.0, 1.16, 0.22), dark, 0.029)
	var lens_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.064, 0.0), Vector2(0.064, 0.048),
		Vector2(0.057, 0.059), Vector2(0.0, 0.059)])
	DesignKit.add(root, DesignKit.lathe(lens_profile, 16), DesignKit.brass(), Vector3(0.015, 1.16, 0.261), Vector3(90.0, 0.0, 0.0))
	_oval(root, Vector3(0.015, 1.16, 0.324), Vector3(0.048, 0.048, 0.006), DesignKit.metal(DesignKit.INDIGO, 0.14, 0.65, "tourist_lens"))
	DesignKit.rbox(root, Vector3(0.037, 0.022, 0.029), Vector3(-0.088, 1.246, 0.22), DesignKit.brass(), 0.009)
	var map_holder: Node3D = Node3D.new()
	map_holder.name = "UnfoldedMap"
	map_holder.position = Vector3(0.0, 1.005, 0.412)
	map_holder.rotation_degrees.x = -18.0
	root.add_child(map_holder)
	DesignKit.add(map_holder, _map_mesh(), _map_material(), Vector3.ZERO)
	# The shared airport pictogram ties the tourist's plan to terminal wayfinding.
	DesignKit.add(map_holder, _icon_quad(), Signage._icon_material("plane", DesignKit.INDIGO), Vector3(0.19, 0.077, 0.026), Vector3.ZERO, false)
	if choice != 0:
		DesignKit.rbox(root, Vector3(0.19, 0.23, 0.09), Vector3(-0.235, 0.78, -0.12), leather, 0.042)
		_limb(root, Vector3(0.17, 1.26, -0.07), Vector3(-0.23, 0.87, -0.13), 0.017, pants)
	return root


static func _oval(parent: Node3D, at: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	if not _meshes.has("sphere"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 16
		sphere.rings = 8
		_meshes["sphere"] = sphere
	var mesh: Mesh = _meshes["sphere"]
	var part: MeshInstance3D = DesignKit.add(parent, mesh, material, at)
	part.scale = radii
	return part


static func _limb(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var length: float = start.distance_to(end)
	var key: String = "capsule:%.4f:%.4f" % [radius, length]
	if not _meshes.has(key):
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = radius
		capsule.height = maxf(length + radius * 2.0, radius * 2.0)
		capsule.radial_segments = 12
		capsule.rings = 4
		_meshes[key] = capsule
	var mesh: Mesh = _meshes[key]
	var part: MeshInstance3D = DesignKit.add(parent, mesh, material, (start + end) * 0.5)
	part.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	return part


static func _map_material() -> Material:
	if not _materials.has("map"):
		var paper: StandardMaterial3D = StandardMaterial3D.new()
		paper.vertex_color_use_as_albedo = true
		paper.roughness = 0.96
		paper.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["map"] = paper
	var material: Material = _materials["map"]
	return material


static func _map_mesh() -> Mesh:
	if not _meshes.has("map"):
		var surface: SurfaceTool = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for panel in 3:
			var left: float = -0.285 + float(panel) * 0.19
			var paper: Color = DesignKit.CREAM if panel != 1 else DesignKit.LINEN.lightened(0.12)
			_map_rect(surface, Rect2(left, -0.17, 0.19, 0.34), paper, 0.0)
			# Broad terminal blocks, a river, and a continuous clay walking route.
			_map_rect(surface, Rect2(left + 0.025, 0.01, 0.135, 0.05), DesignKit.SAGE, 0.001)
			_map_rect(surface, Rect2(left + 0.025, -0.13, 0.075, 0.065), DesignKit.INDIGO.lightened(0.38), 0.001)
			_map_rect(surface, Rect2(left, -0.042, 0.19, 0.015), DesignKit.CLAY, 0.002)
			_map_rect(surface, Rect2(left + 0.125, -0.04, 0.015, 0.125), DesignKit.CLAY, 0.002)
		surface.generate_normals()
		_meshes["map"] = surface.commit()
	var mesh: Mesh = _meshes["map"]
	return mesh


static func _map_rect(surface: SurfaceTool, rect: Rect2, color: Color, offset: float) -> void:
	var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for index: int in [0, 2, 1, 0, 3, 2]:
		var point: Vector2 = corners[index]
		# Alternating mountain/valley folds remain visible from either side.
		var fold: float = absf(fposmod(point.x + 0.285, 0.38) - 0.19) * 0.16
		surface.set_color(color)
		surface.add_vertex(Vector3(point.x, point.y, fold + offset))


static func _icon_quad() -> Mesh:
	if not _meshes.has("icon"):
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(0.082, 0.082)
		_meshes["icon"] = quad
	var mesh: Mesh = _meshes["icon"]
	return mesh
