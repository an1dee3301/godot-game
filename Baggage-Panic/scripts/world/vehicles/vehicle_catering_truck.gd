extends RefCounted
## Raised airport catering hi-lift; metres, ground contact at zero, cab facing +Z.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CateringHiLift"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colours: Array[Color] = [Color(0.94, 0.71, 0.18), Kit.CREAM, Kit.SAGE, Kit.CHARCOAL]
	var accents: Array[Color] = [Kit.CHARCOAL, Kit.CLAY, Kit.CREAM, Kit.OCHRE]
	var body: StandardMaterial3D = Kit.paint(colours[scheme], 0.4)
	var accent: StandardMaterial3D = Kit.brass() if scheme == 3 else Kit.paint(accents[scheme], 0.45)
	var steel: StandardMaterial3D = Kit.metal(Kit.CHARCOAL, 0.45, 0.8, "catering_frame")
	var alloy: StandardMaterial3D = Kit.metal(Color(0.65, 0.67, 0.63), 0.32, 0.85, "catering_alloy")
	var rubber: StandardMaterial3D = Kit.paint(Color(0.055, 0.06, 0.055), 0.95)
	var glazing: StandardMaterial3D = Kit.metal(Color(0.09, 0.18, 0.19), 0.16, 0.35, "catering_glazing")
	var warm_light: StandardMaterial3D = Kit.washi(Kit.CREAM, 3.0, "catering_headlights")
	var amber: StandardMaterial3D = Kit.washi(Color(1.0, 0.48, 0.08), 3.0, "catering_beacon")
	var red: StandardMaterial3D = Kit.washi(Color(0.85, 0.08, 0.04), 1.8, "catering_tail")

	# Long ladder chassis stays visible under the elevated body.
	for x: float in [-0.88, 0.88]:
		Kit.rbox(root, Vector3(0.2, 0.28, 7.5), Vector3(x, 0.94, -0.3), steel, 0.045)
	Kit.rbox(root, Vector3(2.35, 0.18, 5.7), Vector3(0.0, 1.17, -1.3), steel, 0.055)
	Kit.rbox(root, Vector3(2.55, 0.24, 0.25), Vector3(0.0, 0.75, -4.22), alloy, 0.055)
	for z: float in [-3.2, -1.9, 2.65]:
		_beam(root, Vector3(-1.12, 0.53, z), Vector3(1.12, 0.53, z), 0.16, steel)
		for side: float in [-1.0, 1.0]:
			_wheel(root, Vector3(side * 1.12, 0.53, z), side, rubber, alloy, steel)
			Kit.rbox(root, Vector3(0.46, 0.12, 1.15), Vector3(side * 1.1, 1.1, z), body, 0.055)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.38, 0.55, 1.0), Vector3(side * 1.0, 0.77, 0.2), alloy, 0.12)
		# Deployed outriggers establish that the truck is safely parked at lift height.
		for z: float in [-3.5, 0.75]:
			Kit.rbox(root, Vector3(0.85, 0.18, 0.24), Vector3(side * 1.4, 0.85, z), accent, 0.04)
			Kit.rbox(root, Vector3(0.14, 0.75, 0.14), Vector3(side * 1.78, 0.465, z), alloy, 0.025)
			Kit.rbox(root, Vector3(0.48, 0.09, 0.5), Vector3(side * 1.78, 0.045, z), steel, 0.035)

	# Twin, two-stage scissor packs: open negative space is the defining silhouette.
	for side: float in [-1.0, 1.0]:
		var x: float = side * 0.99
		for tier: int in 2:
			var low: float = 1.3 + float(tier) * 1.55
			var high: float = low + 1.55
			_beam(root, Vector3(x, low, -3.4), Vector3(x, high, 0.65), 0.19, accent)
			_beam(root, Vector3(x - side * 0.22, high, -3.4), Vector3(x - side * 0.22, low, 0.65), 0.19, steel)
			_disc(root, Vector3(x + side * 0.11, (low + high) * 0.5, -1.375), 0.15, 0.09, alloy)
		Kit.rbox(root, Vector3(0.2, 0.17, 4.5), Vector3(x, 4.46, -1.375), steel, 0.035)
		_beam(root, Vector3(x, 1.3, -2.7), Vector3(x, 2.73, -0.85), 0.14, alloy)
		_beam(root, Vector3(x, 1.3, -2.7), Vector3(x, 2.1, -1.66), 0.23, steel)

	# Insulated body, corner extrusions, inset shutter and broad operator band.
	Kit.rbox(root, Vector3(2.6, 2.08, 5.8), Vector3(0.0, 5.6, -1.3), body, 0.12)
	Kit.rbox(root, Vector3(2.7, 0.16, 5.9), Vector3(0.0, 4.58, -1.3), alloy, 0.06)
	Kit.rbox(root, Vector3(2.66, 0.13, 5.88), Vector3(0.0, 6.65, -1.3), Kit.paint(Kit.CREAM), 0.06)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.035, 0.22, 5.5), Vector3(side * 1.302, 4.96, -1.3), accent, 0.012, false)
		for z: float in [-4.12, 1.52]:
			Kit.rbox(root, Vector3(0.07, 1.9, 0.09), Vector3(side * 1.27, 5.63, z), alloy, 0.025)
		_side_sign(root, side, scheme)
	Kit.rbox(root, Vector3(2.12, 1.68, 0.04), Vector3(0.0, 5.52, 1.615), steel, 0.05)
	Kit.rbox(root, Vector3(1.94, 1.52, 0.05), Vector3(0.0, 5.52, 1.645), alloy, 0.045)
	for row: int in 7:
		Kit.rbox(root, Vector3(1.9, 0.025, 0.018), Vector3(0.0, 4.94 + float(row) * 0.19, 1.676), steel, 0.006, false)
	Kit.rbox(root, Vector3(0.66, 0.07, 0.08), Vector3(0.0, 4.99, 1.72), steel, 0.025, false)

	# Aircraft transfer deck projects forward above the cab; soft black docking bumper.
	Kit.rbox(root, Vector3(2.5, 0.18, 2.8), Vector3(0.0, 4.58, 3.0), alloy, 0.065)
	Kit.rbox(root, Vector3(2.56, 0.22, 0.2), Vector3(0.0, 4.63, 4.4), rubber, 0.065)
	for side: float in [-1.0, 1.0]:
		for z: float in [1.8, 4.22]:
			_beam(root, Vector3(side * 1.16, 4.68, z), Vector3(side * 1.16, 5.64, z), 0.065, alloy)
		_beam(root, Vector3(side * 1.16, 5.64, 1.8), Vector3(side * 1.16, 5.64, 4.22), 0.065, alloy)
		_beam(root, Vector3(side * 1.16, 5.12, 1.8), Vector3(side * 1.16, 5.12, 4.22), 0.055, alloy)

	# Rounded cab-over: wide dark windscreen, framed doors and a contrasting grille.
	Kit.rbox(root, Vector3(2.36, 1.73, 2.2), Vector3(0.0, 1.88, 2.7), body, 0.19)
	Kit.rbox(root, Vector3(2.45, 0.16, 2.26), Vector3(0.0, 2.75, 2.68), body, 0.075)
	Kit.rbox(root, Vector3(2.03, 0.75, 0.06), Vector3(0.0, 2.22, 3.795), steel, 0.095)
	Kit.rbox(root, Vector3(1.86, 0.6, 0.07), Vector3(0.0, 2.23, 3.825), glazing, 0.075)
	Kit.rbox(root, Vector3(0.055, 0.61, 0.035), Vector3(0.0, 2.23, 3.87), alloy, 0.012, false)
	Kit.rbox(root, Vector3(1.0, 0.29, 0.06), Vector3(0.0, 1.36, 3.815), steel, 0.04)
	Kit.rbox(root, Vector3(2.42, 0.22, 0.26), Vector3(0.0, 0.98, 3.84), steel, 0.07)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.045, 0.9, 1.33), Vector3(side * 1.18, 2.13, 2.75), steel, 0.07)
		Kit.rbox(root, Vector3(0.055, 0.72, 1.14), Vector3(side * 1.207, 2.18, 2.78), glazing, 0.065)
		Kit.rbox(root, Vector3(0.05, 0.055, 0.28), Vector3(side * 1.22, 1.65, 2.33), alloy, 0.018, false)
		Kit.rbox(root, Vector3(0.48, 0.13, 0.85), Vector3(side * 1.24, 0.77, 1.78), alloy, 0.04)
		_beam(root, Vector3(side * 1.2, 2.24, 3.4), Vector3(side * 1.47, 2.3, 3.43), 0.055, steel)
		Kit.rbox(root, Vector3(0.16, 0.38, 0.22), Vector3(side * 1.48, 2.3, 3.43), steel, 0.055)
		Kit.rbox(root, Vector3(0.43, 0.2, 0.065), Vector3(side * 0.81, 1.35, 3.825), warm_light, 0.055, false)
		Kit.rbox(root, Vector3(0.3, 0.12, 0.055), Vector3(side * 0.96, 0.91, -4.365), red, 0.025, false)
		Kit.rbox(root, Vector3(0.22, 0.08, 0.05), Vector3(side * 1.32, 4.75, -3.83), amber, 0.02, false)
		var beacon_profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.13, 0.0), Vector2(0.13, 0.06), Vector2(0.11, 0.2), Vector2(0.07, 0.23), Vector2(0.0, 0.23)])
		Kit.add(root, Kit.lathe(beacon_profile, 16), amber, Vector3(side * 0.87, 2.83, 2.5), Vector3.ZERO, false)
	return root


static func _beam(parent: Node3D, a: Vector3, b: Vector3, width: float, material: Material) -> void:
	var delta: Vector3 = b - a
	var part: MeshInstance3D = Kit.rbox(parent, Vector3(width, delta.length(), width), (a + b) * 0.5, material, width * 0.22)
	part.quaternion = Quaternion(Vector3.UP, delta.normalized())


static func _disc(parent: Node3D, at: Vector3, radius: float, depth: float, material: Material) -> void:
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, -depth * 0.5), Vector2(radius * 0.85, -depth * 0.5), Vector2(radius, -depth * 0.3), Vector2(radius, depth * 0.3), Vector2(radius * 0.85, depth * 0.5), Vector2(0.0, depth * 0.5)])
	Kit.add(parent, Kit.lathe(profile, 20), material, at, Vector3(0.0, 0.0, 90.0))


static func _wheel(parent: Node3D, at: Vector3, side: float, rubber: Material, alloy: Material, steel: Material) -> void:
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.29, -0.18), Vector2(0.43, -0.18), Vector2(0.51, -0.12), Vector2(0.53, -0.05), Vector2(0.53, 0.07), Vector2(0.5, 0.15), Vector2(0.43, 0.18), Vector2(0.29, 0.18), Vector2(0.29, -0.18)])
	Kit.add(parent, Kit.lathe(profile, 24), rubber, at, Vector3(0.0, 0.0, 90.0))
	_disc(parent, at + Vector3(side * 0.18, 0.0, 0.0), 0.33, 0.055, alloy)
	_disc(parent, at + Vector3(side * 0.22, 0.0, 0.0), 0.14, 0.07, steel)


static func _side_sign(parent: Node3D, side: float, scheme: int) -> void:
	var holder: Node3D = Node3D.new()
	holder.position = Vector3(side * 1.325, 5.79, -1.3)
	holder.rotation_degrees.y = side * 90.0
	parent.add_child(holder)
	var ink: Color = Kit.CREAM if scheme == 3 else Kit.CHARCOAL
	var captions: Array[String] = ["CATERING", "機内食  ·  航空配餐", "Suất ăn  ·  Restauration  ·  Catering aéreo"]
	var sizes: Array[int] = [160, 100, 84]
	for line: int in captions.size():
		var label: Label3D = Label3D.new()
		label.text = captions[line]
		label.font = Signs.font()
		label.font_size = sizes[line]
		label.pixel_size = 0.0028
		label.position = Vector3(0.0, 0.42 - float(line) * 0.4, 0.0)
		label.modulate = ink
		label.outline_size = 0
		label.double_sided = false
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(label)
