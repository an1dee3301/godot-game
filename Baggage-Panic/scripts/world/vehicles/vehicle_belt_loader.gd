extends RefCounted
## Apron belt loader: 7.6 m conveyor, 2.4 m chassis, raised discharge toward +Z.
## All reusable geometry and finishes come from the shared DesignKit caches.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BeltLoader"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var colours: Array[Color] = [Color(0.94, 0.72, 0.19), Kit.CREAM, Kit.SAGE, Kit.CHARCOAL]
	var scheme: int = posmod(variant, 4)
	var body: StandardMaterial3D = Kit.paint(colours[scheme], 0.48)
	var stripe: StandardMaterial3D = Kit.brass() if scheme == 3 else Kit.paint(Kit.CLAY)
	var steel: StandardMaterial3D = Kit.metal()
	var alloy: StandardMaterial3D = Kit.metal(Color(0.64, 0.65, 0.61), 0.42, 0.85, "loader_alloy")
	var rubber: StandardMaterial3D = Kit.paint(Color(0.065, 0.061, 0.053), 0.94)
	var belt_mat: StandardMaterial3D = Kit.fabric(Color(0.12, 0.13, 0.115), "loader_belt")
	var lamp: StandardMaterial3D = Kit.washi(Kit.CREAM, 3.2, "loader_headlight")
	var amber: StandardMaterial3D = Kit.washi(Color(1.0, 0.51, 0.09), 3.8, "loader_beacon")

	# Low, rounded electric drive chassis with inset panels and protective bumpers.
	Kit.rbox(root, Vector3(2.18, 0.22, 4.25), Vector3(0.0, 0.47, -0.3), steel, 0.09)
	Kit.rbox(root, Vector3(2.28, 0.48, 4.18), Vector3(0.0, 0.78, -0.3), body, 0.15)
	Kit.rbox(root, Vector3(1.55, 0.3, 1.55), Vector3(0.26, 1.08, -0.98), body, 0.12)
	Kit.rbox(root, Vector3(1.44, 0.025, 1.39), Vector3(0.26, 1.24, -0.98), alloy, 0.012)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.035, 0.1, 3.94), Vector3(side * 1.145, 0.84, -0.3), stripe, 0.016)
		Kit.rbox(root, Vector3(0.04, 0.27, 0.85), Vector3(side * 1.155, 0.68, -0.35), steel, 0.035)
		Kit.rbox(root, Vector3(0.055, 0.035, 0.22), Vector3(side * 1.185, 0.77, -0.35), alloy, 0.015, false)
		for z: float in [-1.65, 1.13]:
			_wheel(root, Vector3(side * 1.09, 0.43, z), side, rubber, alloy, steel)
			Kit.rbox(root, Vector3(0.41, 0.14, 1.0), Vector3(side * 1.04, 0.98, z), body, 0.065)
	for z: float in [-2.5, 1.85]:
		Kit.rbox(root, Vector3(2.4, 0.18, 0.19), Vector3(0.0, 0.56, z), rubber, 0.07)
	for x: float in [-0.82, 0.82]:
		Kit.rbox(root, Vector3(0.34, 0.21, 0.11), Vector3(x, 0.8, 1.81), steel, 0.055)
		Kit.rbox(root, Vector3(0.26, 0.13, 0.035), Vector3(x, 0.8, 1.875), lamp, 0.045, false)
		Kit.rbox(root, Vector3(0.2, 0.09, 0.04), Vector3(x, 0.8, -2.41), Kit.washi(Kit.CLAY, 1.8, "loader_tail"), 0.025, false)

	# Offset driver station: linen seat, walnut console edge, open steel canopy.
	Kit.rbox(root, Vector3(0.64, 0.08, 1.24), Vector3(-0.82, 1.04, 0.79), alloy, 0.035)
	Kit.rbox(root, Vector3(0.52, 0.16, 0.53), Vector3(-0.83, 1.29, 0.37), Kit.fabric(Kit.LINEN, "loader_seat"), 0.065)
	Kit.rbox(root, Vector3(0.52, 0.49, 0.12), Vector3(-0.83, 1.54, 0.1), Kit.fabric(Kit.LINEN, "loader_seat"), 0.055)
	Kit.rbox(root, Vector3(0.43, 0.24, 0.3), Vector3(-0.83, 1.47, 1.23), steel, 0.06)
	Kit.rbox(root, Vector3(0.44, 0.045, 0.31), Vector3(-0.83, 1.61, 1.23), Kit.wood(Kit.WALNUT, "loader_console"), 0.02)
	Kit.rbox(root, Vector3(0.18, 0.035, 0.12), Vector3(-0.82, 1.638, 1.25), Kit.washi(Kit.SAGE, 0.8, "loader_screen"), 0.018, false)
	var steering: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.145, -0.022), Vector2(0.17, -0.018), Vector2(0.18, 0.0),
		Vector2(0.17, 0.018), Vector2(0.145, 0.022), Vector2(0.145, -0.022)
	]), 20), rubber, Vector3(-0.83, 1.7, 0.96), Vector3(24.0, 0.0, 0.0))
	Kit.rbox(steering, Vector3(0.29, 0.03, 0.035), Vector3.ZERO, steel, 0.014)
	for z: float in [0.03, 1.48]:
		_bar(root, Vector3(-1.08, 1.03, z), Vector3(-1.08, 2.27, z), 0.055, steel)
	Kit.rbox(root, Vector3(0.85, 0.12, 1.76), Vector3(-0.78, 2.3, 0.75), body, 0.055)
	Kit.rbox(root, Vector3(0.75, 0.025, 1.65), Vector3(-0.78, 2.226, 0.75), Kit.paint(Kit.CREAM), 0.012)
	Kit.rbox(root, Vector3(0.51, 0.055, 0.32), Vector3(-1.22, 0.72, 0.81), alloy, 0.022)
	Kit.rbox(root, Vector3(0.42, 0.045, 0.27), Vector3(-1.21, 0.91, 0.81), rubber, 0.02)
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.12, 0.07),
		Vector2(0.09, 0.085), Vector2(0.0, 0.085)
	]), 20), steel, Vector3(-0.8, 2.36, 0.32))
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.095, 0.0), Vector2(0.095, 0.14),
		Vector2(0.08, 0.18), Vector2(0.0, 0.19)
	]), 20), amber, Vector3(-0.8, 2.44, 0.32), Vector3.ZERO, false)

	# Inclination is carried by a single transform, keeping belt, drums and rails aligned.
	var boom: Node3D = Node3D.new()
	boom.name = "InclinedConveyor"
	boom.position = Vector3(0.34, 2.04, 0.15)
	boom.rotation_degrees.x = -19.0
	root.add_child(boom)
	Kit.rbox(boom, Vector3(0.96, 0.19, 7.6), Vector3(0.0, -0.11, 0.0), steel, 0.08)
	Kit.rbox(boom, Vector3(0.82, 0.085, 7.36), Vector3(0.0, 0.035, 0.0), belt_mat, 0.04)
	for x: float in [-0.53, 0.53]:
		Kit.rbox(boom, Vector3(0.14, 0.27, 7.5), Vector3(x, 0.01, 0.0), body, 0.06)
		Kit.rbox(boom, Vector3(0.045, 0.045, 7.38), Vector3(x, 0.155, 0.0), alloy, 0.02)
		Kit.rbox(boom, Vector3(0.065, 0.065, 6.65), Vector3(x, 0.64, 0.12), steel, 0.03)
		for z: float in [-3.17, -1.5, 0.17, 1.84, 3.45]:
			_bar(boom, Vector3(x, 0.14, z), Vector3(x, 0.64, z), 0.045, steel)
		Kit.rbox(boom, Vector3(0.035, 0.08, 0.54), Vector3(x * 1.15, 0.055, 3.4), amber, 0.016, false)
	for z: float in [-3.73, 3.73]:
		Kit.add(boom, Kit.lathe(PackedVector2Array([
			Vector2(0.0, -0.44), Vector2(0.13, -0.44), Vector2(0.155, -0.39),
			Vector2(0.155, 0.39), Vector2(0.13, 0.44), Vector2(0.0, 0.44)
		]), 20), rubber, Vector3(0.0, -0.015, z), Vector3(0.0, 0.0, 90.0))
	Kit.rbox(boom, Vector3(1.2, 0.13, 0.22), Vector3(0.0, 0.0, 3.89), rubber, 0.06)
	_cleats(boom, alloy)

	# Paired lift arms and exposed piston rods make the elevated belt mechanically credible.
	for x: float in [-0.1, 0.77]:
		_bar(root, Vector3(x, 1.05, -1.7), Vector3(x, 2.73, 2.1), 0.12, steel)
		_bar(root, Vector3(x, 1.04, 1.27), Vector3(x, 2.15, 0.38), 0.13, body)
		_bar(root, Vector3(x, 2.15, 0.38), Vector3(x, 2.68, -0.05), 0.065, alloy)
		Kit.add(root, Kit.lathe(PackedVector2Array([
			Vector2(0.0, -0.07), Vector2(0.115, -0.07), Vector2(0.115, 0.07), Vector2(0.0, 0.07)
		]), 16), alloy, Vector3(x, 1.08, 1.27), Vector3(0.0, 0.0, 90.0))

	# Large bilingual groups: six languages on both sides, sized for terminal-window viewing.
	for side: float in [-1.0, 1.0]:
		var placard: Node3D = Node3D.new()
		placard.position = Vector3(side * 0.625, -0.46, 0.2)
		placard.rotation_degrees.y = side * 90.0
		boom.add_child(placard)
		Kit.rbox(placard, Vector3(4.85, 0.78, 0.045), Vector3.ZERO, steel, 0.022)
		Kit.rbox(placard, Vector3(4.65, 0.023, 0.016), Vector3(0.0, 0.33, 0.03), stripe, 0.007, false)
		_caption(placard, "BAGGAGE  •  手荷物  •  行李", Vector3(0.0, 0.14, 0.034))
		_caption(placard, "Hành lý  •  Bagages  •  Equipaje", Vector3(0.0, -0.17, 0.034))
	return root


static func _bar(parent: Node3D, start: Vector3, finish: Vector3, width: float, material: Material) -> void:
	var direction: Vector3 = finish - start
	var part: MeshInstance3D = Kit.rbox(parent, Vector3(width, direction.length(), width), (start + finish) * 0.5, material, width * 0.42)
	part.quaternion = Quaternion(Vector3.UP, direction.normalized())


static func _wheel(parent: Node3D, at: Vector3, side: float, rubber: Material, alloy: Material, steel: Material) -> void:
	var tire: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.16), Vector2(0.29, -0.16), Vector2(0.39, -0.12),
		Vector2(0.43, -0.065), Vector2(0.43, 0.065), Vector2(0.39, 0.12),
		Vector2(0.29, 0.16), Vector2(0.0, 0.16)
	]), 28)
	Kit.add(parent, tire, rubber, at, Vector3(0.0, 0.0, 90.0))
	var hub: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.018), Vector2(0.24, -0.018), Vector2(0.27, 0.0),
		Vector2(0.24, 0.025), Vector2(0.1, 0.045), Vector2(0.0, 0.045)
	]), 24)
	Kit.add(parent, hub, alloy, at + Vector3(side * 0.16, 0.0, 0.0), Vector3(0.0, 0.0, -side * 90.0))
	Kit.rbox(parent, Vector3(0.025, 0.1, 0.1), at + Vector3(side * 0.21, 0.0, 0.0), steel, 0.04, false)


static func _cleats(parent: Node3D, material: Material) -> void:
	var mesh: ArrayMesh = Kit.rounded_box(Vector3(0.75, 0.018, 0.034), 0.008)
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = 30
	for index: int in 30:
		instances.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.083, -3.48 + float(index) * 0.24)))
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.multimesh = instances
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)


static func _caption(parent: Node3D, caption: String, at: Vector3) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signs.font()
	label.text = caption
	label.font_size = 92
	label.pixel_size = 0.003
	label.modulate = Kit.CREAM
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
