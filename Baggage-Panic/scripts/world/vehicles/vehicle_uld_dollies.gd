extends RefCounted
## Three linked, apron-scale ULD dollies. Leading tow eye points toward +Z.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ULD_DollyTrain"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colors: Array[Color] = [Color(0.94, 0.69, 0.17), Kit.CREAM, Kit.SAGE, Kit.CHARCOAL]
	var accents: Array[Color] = [Kit.CHARCOAL, Kit.CLAY, Kit.CREAM, Kit.OCHRE]
	var chassis: StandardMaterial3D = Kit.paint(colors[scheme], 0.48)
	var accent: StandardMaterial3D = Kit.paint(accents[scheme])
	var alloy: StandardMaterial3D = Kit.metal(Color(0.77, 0.78, 0.74), 0.48, 0.72, "uld_satin_alloy")
	var edge: StandardMaterial3D = Kit.metal(Color(0.53, 0.55, 0.52), 0.34, 0.9, "uld_edge_alloy")
	var steel: StandardMaterial3D = Kit.metal()
	var rubber: StandardMaterial3D = Kit.paint(Color(0.065, 0.061, 0.055), 0.94)
	var amber: StandardMaterial3D = Kit.washi(Color(1.0, 0.48, 0.08), 2.8, "uld_amber")
	var red: StandardMaterial3D = Kit.washi(Color(0.85, 0.12, 0.065), 1.8, "uld_tail")
	var tire_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.105), Vector2(0.19, -0.105), Vector2(0.25, -0.085),
		Vector2(0.27, -0.045), Vector2(0.27, 0.045), Vector2(0.25, 0.085),
		Vector2(0.19, 0.105), Vector2(0.0, 0.105)]), 20)
	var hub_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.118), Vector2(0.10, -0.118), Vector2(0.135, -0.095),
		Vector2(0.135, 0.095), Vector2(0.10, 0.118), Vector2(0.0, 0.118)]), 16)
	var wheel_transforms: Array[Transform3D] = []
	var captions: Array[String] = ["Baggage\n手荷物", "行李\nHành lý", "Bagages\nEquipaje"]
	var tire_basis: Basis = Basis(Vector3.FORWARD, PI * 0.5)
	for index: int in 3:
		var z: float = 3.15 - float(index) * 3.15
		var dolly: Node3D = Node3D.new()
		dolly.name = "Dolly_%02d" % (index + 1)
		dolly.position.z = z
		root.add_child(dolly)
		# Low, rounded frame with a contrasting aluminum roller bed.
		Kit.rbox(dolly, Vector3(2.08, 0.19, 2.18), Vector3(0.0, 0.49, 0.0), chassis, 0.065)
		Kit.rbox(dolly, Vector3(1.96, 0.075, 1.97), Vector3(0.0, 0.62, 0.0), edge, 0.025)
		for axle_z: float in [-0.74, 0.74]:
			Kit.rbox(dolly, Vector3(2.02, 0.10, 0.12), Vector3(0.0, 0.27, axle_z), steel, 0.035)
			for x: float in [-1.01, 1.01]:
				wheel_transforms.append(Transform3D(tire_basis, Vector3(x, 0.27, z + axle_z)))
				Kit.rbox(dolly, Vector3(0.30, 0.075, 0.67), Vector3(x, 0.58, axle_z), chassis, 0.035)
		# Drawbar bridges the gap to the previous cart; the first terminates in a tow eye.
		Kit.rbox(dolly, Vector3(0.13, 0.10, 1.12), Vector3(0.0, 0.35, 1.53), steel, 0.04)
		Kit.add(dolly, _eye_mesh(), edge, Vector3(0.0, 0.35, 2.075), Vector3.ZERO, false)
		Kit.rbox(dolly, Vector3(0.28, 0.17, 0.25), Vector3(0.0, 0.37, -1.12), steel, 0.04)
		# Sculpted shell: broad flat crown, generous curved shoulders, small bottom radii.
		Kit.add(dolly, _shell_mesh(1.72), alloy, Vector3(0.0, 0.68, 0.0))
		for end_z: float in [-0.87, 0.87]:
			var rim: MeshInstance3D = Kit.add(dolly, _shell_mesh(0.055), edge, Vector3(0.0, 0.671, end_z))
			rim.scale = Vector3(1.012, 1.012, 1.0)
			# Recessed seal, inset door and a protective lower sill.
			Kit.rbox(dolly, Vector3(1.60, 1.18, 0.045), Vector3(0.0, 1.40, end_z * 1.035), rubber, 0.11)
			Kit.rbox(dolly, Vector3(1.53, 1.11, 0.052), Vector3(0.0, 1.40, end_z * 1.065), alloy, 0.085)
			Kit.rbox(dolly, Vector3(1.83, 0.085, 0.09), Vector3(0.0, 0.77, end_z * 1.07), edge, 0.025)
			Kit.rbox(dolly, Vector3(0.33, 0.065, 0.065), Vector3(0.48, 1.11, end_z * 1.11), steel, 0.023, false)
			Kit.rbox(dolly, Vector3(0.07, 0.15, 0.045), Vector3(-0.58, 1.08, end_z * 1.10), Kit.brass(), 0.015, false)
		for side: float in [-1.0, 1.0]:
			# Broad operator band survives distance; narrow ribs and corner stops add scale.
			Kit.rbox(dolly, Vector3(0.034, 0.25, 1.58), Vector3(side * 0.976, 0.99, 0.0), accent, 0.013)
			Kit.rbox(dolly, Vector3(0.065, 0.095, 1.78), Vector3(side * 0.979, 0.74, 0.0), edge, 0.02)
			Kit.rbox(dolly, Vector3(0.038, 0.95, 0.048), Vector3(side * 0.980, 1.49, -0.61), edge, 0.014, false)
			Kit.rbox(dolly, Vector3(0.085, 0.11, 0.20), Vector3(side * 0.96, 0.67, 0.57), steel, 0.025, false)
			var sign_at: Vector3 = Vector3(side * 0.998, 1.56, 0.12)
			_label(dolly, captions[index], sign_at, side * 90.0, 72, 0.0035, Kit.CHARCOAL)
			Kit.rbox(dolly, Vector3(0.09, 0.07, 0.16), Vector3(side * 1.052, 0.50, 0.22), amber, 0.025, false)
		_label(dolly, "ULD %02d" % (index + 1), Vector3(0.0, 1.58, 0.935), 0.0, 100, 0.0036, Kit.CHARCOAL)
		# Small powered safety beacon on a protected corner mounting.
		Kit.rbox(dolly, Vector3(0.15, 0.07, 0.15), Vector3(0.82, 0.70, 0.99), steel, 0.02)
		Kit.add(dolly, _beacon_mesh(), amber, Vector3(0.82, 0.735, 0.99), Vector3.ZERO, false)
		if index == 2:
			for x: float in [-0.78, 0.78]:
				Kit.rbox(dolly, Vector3(0.20, 0.085, 0.065), Vector3(x, 0.50, -1.105), red, 0.024, false)
	_instances(root, tire_mesh, rubber, wheel_transforms, "Tires")
	_instances(root, hub_mesh, edge, wheel_transforms, "Hubs")
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, yaw: float, size: int, pixel: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signs.font()
	label.font_size = size
	label.pixel_size = pixel
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.rotation_degrees.y = yaw
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _instances(parent: Node3D, mesh: Mesh, material: Material, poses: Array[Transform3D], title: String) -> void:
	var multi: MultiMesh = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = poses.size()
	for index: int in poses.size():
		multi.set_instance_transform(index, poses[index])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = multi
	node.material_override = material
	parent.add_child(node)


static func _shell_mesh(depth: float) -> ArrayMesh:
	var key: String = "shell_%.3f" % depth
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var points: PackedVector2Array = PackedVector2Array()
	# Rounded 1.94 m wide / 1.64 m tall cross section, with a 0.43 m roof shoulder.
	var centers: Array[Vector2] = [Vector2(0.90, 0.07), Vector2(0.54, 1.21), Vector2(-0.54, 1.21), Vector2(-0.90, 0.07)]
	var radii: Array[float] = [0.07, 0.43, 0.43, 0.07]
	for corner: int in 4:
		for step: int in 9:
			var angle: float = -PI * 0.5 + float(corner) * PI * 0.5 + float(step) * PI / 16.0
			points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * radii[corner])
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_depth: float = depth * 0.5
	for index: int in points.size():
		var p: Vector2 = points[index]
		var q: Vector2 = points[(index + 1) % points.size()]
		var normal: Vector3 = Vector3(q.y - p.y, p.x - q.x, 0.0).normalized()
		var a: Vector3 = Vector3(p.x, p.y, half_depth)
		var b: Vector3 = Vector3(q.x, q.y, half_depth)
		var c: Vector3 = Vector3(q.x, q.y, -half_depth)
		var d: Vector3 = Vector3(p.x, p.y, -half_depth)
		_triangle(st, a, d, c, normal)
		_triangle(st, a, c, b, normal)
		_triangle(st, Vector3(0.0, 0.82, half_depth), b, a, Vector3.BACK)
		_triangle(st, Vector3(0.0, 0.82, -half_depth), d, c, Vector3.FORWARD)
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	st.set_normal(normal)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _eye_mesh() -> ArrayMesh:
	# Horizontal tow ring with an actual open center.
	return Kit.lathe(PackedVector2Array([
		Vector2(0.07, -0.035), Vector2(0.13, -0.035), Vector2(0.145, -0.015),
		Vector2(0.145, 0.015), Vector2(0.13, 0.035), Vector2(0.07, 0.035),
		Vector2(0.07, -0.035)]), 20)


static func _beacon_mesh() -> ArrayMesh:
	return Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.062, 0.0), Vector2(0.062, 0.09),
		Vector2(0.05, 0.12), Vector2(0.0, 0.135)]), 16)
