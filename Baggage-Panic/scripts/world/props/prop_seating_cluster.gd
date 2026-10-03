extends RefCounted
## Eight outward-facing gate seats, arranged in pairs around a planted courtyard.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "SeatingCluster"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var colors: Array[Color] = [DesignKit.LINEN, DesignKit.SAGE, DesignKit.CLAY.lightened(0.24), DesignKit.CREAM.darkened(0.12)]
	var upholstery: Color = colors[style]
	var oak: Material = DesignKit.wood()
	var cloth: Material = DesignKit.fabric(upholstery, "seating_cluster_%d" % style)
	var piping: Material = DesignKit.fabric(upholstery.darkened(0.16), "seating_cluster_piping_%d" % style)
	for side in 4:
		var angle: float = float(side) * PI * 0.5
		for place in 2:
			var seat: Node3D = Node3D.new()
			seat.name = "Seat_%d" % (side * 2 + place + 1)
			seat.position = Vector3(-0.38 + float(place) * 0.76, 0.0, 1.17).rotated(Vector3.UP, angle)
			seat.rotation.y = angle
			root.add_child(seat)
			_build_seat(seat, oak, cloth, piping)
	_build_planter(root, style)
	_build_gate_marker(root, style)
	return root


static func _build_seat(parent: Node3D, oak: Material, cloth: Material, piping: Material) -> void:
	var steel: Material = DesignKit.metal()
	# Open oak trestles: paired legs on quiet steel sled feet, with room for bags.
	for x: float in [-0.255, 0.255]:
		for z: float in [-0.185, 0.185]:
			DesignKit.add(parent, DesignKit.rounded_box(Vector3(0.065, 0.345, 0.065), 0.022), oak, Vector3(x, 0.2, z), Vector3(4.0 if z > 0.0 else -4.0, 0.0, 0.0))
		DesignKit.rbox(parent, Vector3(0.076, 0.035, 0.48), Vector3(x, 0.0175, 0.0), steel, 0.016, false)
		DesignKit.rbox(parent, Vector3(0.065, 0.07, 0.47), Vector3(x, 0.625, -0.005), oak, 0.03)
		DesignKit.rbox(parent, Vector3(0.038, 0.225, 0.042), Vector3(x, 0.51, 0.16), steel, 0.015, false)
	DesignKit.rbox(parent, Vector3(0.61, 0.065, 0.56), Vector3(0.0, 0.3675, 0.0), oak, 0.028)
	# The thin, darker under-cushion is a welt seam, revealed around the perimeter.
	DesignKit.rbox(parent, Vector3(0.575, 0.019, 0.525), Vector3(0.0, 0.421, 0.012), piping, 0.009, false)
	DesignKit.rbox(parent, Vector3(0.559, 0.102, 0.509), Vector3(0.0, 0.449, 0.012), cloth, 0.049)
	var recline: Vector3 = Vector3(-9.0, 0.0, 0.0)
	DesignKit.add(parent, DesignKit.rounded_box(Vector3(0.61, 0.47, 0.065), 0.03), oak, Vector3(0.0, 0.713, -0.254), recline)
	DesignKit.add(parent, DesignKit.rounded_box(Vector3(0.56, 0.412, 0.022), 0.01), piping, Vector3(0.0, 0.717, -0.209), recline, false)
	DesignKit.add(parent, DesignKit.rounded_box(Vector3(0.542, 0.394, 0.073), 0.035), cloth, Vector3(0.0, 0.717, -0.184), recline)


static func _build_planter(parent: Node3D, style: int) -> void:
	var tint: Color = DesignKit.LIMESTONE if style != 2 else DesignKit.CLAY.lightened(0.18)
	var stone: Material = DesignKit.stone(tint, 0.72, "seating_planter_%d" % style)
	var walnut: Material = DesignKit.wood(DesignKit.WALNUT, "walnut")
	DesignKit.rbox(parent, Vector3(1.34, 0.08, 1.34), Vector3(0.0, 0.04, 0.0), DesignKit.metal(), 0.035)
	DesignKit.rbox(parent, Vector3(1.46, 0.56, 1.46), Vector3(0.0, 0.36, 0.0), stone, 0.16)
	DesignKit.rbox(parent, Vector3(1.48, 0.035, 1.48), Vector3(0.0, 0.13, 0.0), DesignKit.brass(), 0.017, false)
	# Four rounded coping pieces reveal an actual recessed soil bed.
	for side in 4:
		DesignKit.add(parent, DesignKit.rounded_box(Vector3(1.44, 0.075, 0.15), 0.034), walnut, Vector3(0.0, 0.653, 0.655).rotated(Vector3.UP, float(side) * PI * 0.5), Vector3(0.0, float(side) * 90.0, 0.0))
	DesignKit.rbox(parent, Vector3(1.18, 0.035, 1.18), Vector3(0.0, 0.63, 0.0), DesignKit.stone(Color(0.19, 0.16, 0.12), 0.98, "seating_soil"), 0.1)
	var stem_mesh: Mesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.014, 0.0), Vector2(0.009, 1.0), Vector2(0.0, 1.0)]), 8)
	var stems: Array[Transform3D] = []
	var leaves: Array[Transform3D] = []
	for plant in 9:
		var phase: float = float(plant) * 2.39996 + float(style) * 0.45
		var radius: float = 0.0 if plant == 0 else 0.27 + 0.045 * float(plant % 3)
		var base: Vector3 = Vector3(cos(phase) * radius, 0.65, sin(phase) * radius)
		var height: float = 0.84 + 0.13 * float(plant % 4)
		stems.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, height, 1.0)), base))
		for tier in 5:
			var leaf_angle: float = phase + float(tier) * 2.1
			var direction: Vector3 = Vector3(cos(leaf_angle), 0.42 + 0.16 * float(tier), sin(leaf_angle)).normalized()
			var length: float = 0.42 - float(tier) * 0.035
			var leaf_basis: Basis = Basis(Quaternion(Vector3.UP, direction)).scaled(Vector3(0.8, length, 1.0))
			leaves.append(Transform3D(leaf_basis, base + Vector3.UP * height * (0.25 + float(tier) * 0.15)))
	_batch(parent, "Stems", stem_mesh, DesignKit.paint(DesignKit.SAGE.darkened(0.36)), stems)
	_batch(parent, "FoldedLeaves", _leaf_mesh(), _leaf_material(style), leaves)


static func _leaf_mesh() -> ArrayMesh:
	if _meshes.has("leaf"):
		return _meshes["leaf"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A lance-shaped leaf with a raised central vein and gently drooping tip.
	for section in 8:
		var a: float = float(section) / 8.0
		var b: float = float(section + 1) / 8.0
		var wa: float = sin(a * PI) * 0.115
		var wb: float = sin(b * PI) * 0.115
		var ca: Vector3 = Vector3(0.0, a, sin(a * PI) * 0.055 - a * a * 0.08)
		var cb: Vector3 = Vector3(0.0, b, sin(b * PI) * 0.055 - b * b * 0.08)
		for edge: float in [-1.0, 1.0]:
			var ea: Vector3 = Vector3(edge * wa, a, -a * a * 0.08)
			var eb: Vector3 = Vector3(edge * wb, b, -b * b * 0.08)
			var vertices: Array[Vector3] = [ca, ea, cb, ea, eb, cb]
			if edge < 0.0:
				vertices.assign([ca, cb, ea, ea, cb, eb])
			for vertex: Vector3 in vertices:
				st.set_uv(Vector2(vertex.x * 4.0 + 0.5, vertex.y))
				st.add_vertex(vertex)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["leaf"] = mesh
	return mesh


static func _leaf_material(style: int) -> StandardMaterial3D:
	var key: String = "leaf_%d" % style
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = DesignKit.SAGE.darkened(0.22 + float(style) * 0.025)
	material.roughness = 0.7
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


static func _batch(parent: Node3D, title: String, mesh: Mesh, material: Material, transforms: Array[Transform3D]) -> void:
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = transforms.size()
	for index in transforms.size():
		instances.set_instance_transform(index, transforms[index])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = instances
	node.material_override = material
	parent.add_child(node)


static func _build_gate_marker(parent: Node3D, style: int) -> void:
	for x: float in [-0.57, 0.57]:
		DesignKit.rbox(parent, Vector3(0.035, 1.55, 0.035), Vector3(x, 1.425, -0.12), DesignKit.brass(), 0.015, false)
	DesignKit.rbox(parent, Vector3(3.1, 1.02, 0.10), Vector3(0.0, 2.65, -0.12), DesignKit.metal(), 0.049)
	DesignKit.rbox(parent, Vector3(2.92, 0.025, 0.014), Vector3(0.0, 3.08, -0.063), DesignKit.washi(DesignKit.CREAM, 1.3, "seating_marker_glow"), 0.006, false)
	var words: Array = Signage.TEXT["gate"]
	var captions: Array[String] = ["%s  %02d" % [str(words[0]), style + 1], "%s  ·  %s" % [str(words[1]), str(words[2])], "%s  ·  %s  ·  %s" % [str(words[3]), str(words[4]), str(words[5])]]
	var sizes: Array[int] = [100, 72, 64]
	for line in 3:
		var label: Label3D = Label3D.new()
		label.name = "GateLanguage_%d" % line
		label.font = Signage.font()
		label.text = captions[line]
		label.font_size = sizes[line]
		label.pixel_size = 0.0028
		label.position = Vector3(0.0, 2.90 - float(line) * 0.28, -0.062)
		label.modulate = DesignKit.CREAM
		label.outline_size = 0
		label.double_sided = false
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(label)
