extends RefCounted
## Conventional ballasted airport tractor, 3.4 m wide, with a front-mounted towbar.
## All resources are shared across builds; the origin is the tyre contact plane.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "PushbackTug"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colors: Array[Color] = [Color(0.94, 0.69, 0.16), Kit.CREAM, Kit.SAGE, Kit.CHARCOAL]
	var accents: Array[Color] = [Kit.CHARCOAL, Kit.CLAY, Kit.CREAM, Color(0.78, 0.6, 0.34)]
	var body: StandardMaterial3D = Kit.paint(colors[scheme], 0.42)
	var stripe: StandardMaterial3D = Kit.paint(accents[scheme], 0.48)
	var steel: StandardMaterial3D = Kit.metal(Kit.CHARCOAL, 0.42, 0.8, "tug_steel")
	var alloy: StandardMaterial3D = Kit.metal(Color(0.56, 0.57, 0.54), 0.32, 0.85, "tug_alloy")
	var rubber: StandardMaterial3D = Kit.paint(Color(0.055, 0.052, 0.047), 0.96)
	var headlight: StandardMaterial3D = Kit.washi(Kit.CREAM, 3.5, "tug_headlight")
	var amber: StandardMaterial3D = Kit.washi(Color(1.0, 0.43, 0.055), 3.0, "tug_amber")
	var red: StandardMaterial3D = Kit.washi(Color(0.78, 0.065, 0.035), 1.8, "tug_tail")
	# Heavy belly, rounded counterweight and separately fitted service hood.
	Kit.rbox(root, Vector3(2.75, 0.46, 5.1), Vector3(0, 0.67, 0), steel, 0.16)
	Kit.rbox(root, Vector3(2.86, 0.64, 5.25), Vector3(0, 1.02, 0), body, 0.22)
	Kit.rbox(root, Vector3(2.8, 0.42, 2.62), Vector3(0, 1.41, -1.22), body, 0.17)
	Kit.rbox(root, Vector3(2.54, 0.055, 2.25), Vector3(0, 1.64, -1.27), stripe, 0.025)
	Kit.rbox(root, Vector3(2.98, 0.21, 0.24), Vector3(0, 0.69, 2.66), rubber, 0.09)
	Kit.rbox(root, Vector3(2.98, 0.21, 0.24), Vector3(0, 0.69, -2.66), rubber, 0.09)
	# Four broad tyres: rounded shoulder, recessed sidewall and turned metal hubs.
	var tyre: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.29, -0.245), Vector2(0.48, -0.245), Vector2(0.59, -0.19),
		Vector2(0.64, -0.12), Vector2(0.64, 0.12), Vector2(0.59, 0.19),
		Vector2(0.48, 0.245), Vector2(0.29, 0.245), Vector2(0.29, -0.245)]), 32)
	var hub: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0, -0.035), Vector2(0.28, -0.035), Vector2(0.3, 0),
		Vector2(0.27, 0.055), Vector2(0.13, 0.055), Vector2(0.1, 0.09),
		Vector2(0, 0.09)]), 24)
	for side: float in [-1.0, 1.0]:
		for axle: float in [-1.65, 1.65]:
			Kit.add(root, tyre, rubber, Vector3(side * 1.43, 0.64, axle), Vector3(0, 0, -90))
			Kit.add(root, hub, alloy, Vector3(side * 1.68, 0.64, axle), Vector3(0, 0, -side * 90))
			Kit.add(root, _treads(), rubber, Vector3(side * 1.43, 0.64, axle))
			Kit.rbox(root, Vector3(0.57, 0.12, 1.63), Vector3(side * 1.43, 1.35, axle), body, 0.055)
		# Long operator band and rear step with inset grip plate.
		Kit.rbox(root, Vector3(0.055, 0.2, 4.65), Vector3(side * 1.437, 1.06, 0), stripe, 0.02)
		Kit.rbox(root, Vector3(0.42, 0.12, 0.65), Vector3(side * 1.5, 0.72, 0), steel, 0.04)
		Kit.rbox(root, Vector3(0.32, 0.025, 0.53), Vector3(side * 1.52, 0.79, 0), alloy, 0.01, false)
	# Low panoramic cab: inset glazing inside a rounded painted surround.
	Kit.rbox(root, Vector3(2.25, 0.34, 1.94), Vector3(0, 1.47, 1.23), body, 0.13)
	Kit.rbox(root, Vector3(2.19, 0.85, 1.79), Vector3(0, 2.03, 1.19), _glass(), 0.11, false)
	Kit.rbox(root, Vector3(2.4, 0.15, 2.07), Vector3(0, 2.51, 1.19), stripe, 0.07)
	for side: float in [-1.0, 1.0]:
		for z: float in [0.34, 2.03]:
			Kit.rbox(root, Vector3(0.11, 0.89, 0.115), Vector3(side * 1.08, 2.03, z), body, 0.035)
		Kit.rbox(root, Vector3(0.065, 0.77, 0.085), Vector3(side * 1.108, 2.03, 1.18), steel, 0.022)
		Kit.rbox(root, Vector3(0.065, 0.045, 0.32), Vector3(side * 1.15, 1.65, 1.51), alloy, 0.02, false)
		Kit.rbox(root, Vector3(0.37, 0.055, 0.055), Vector3(side * 1.27, 2.17, 1.88), steel, 0.02)
		Kit.rbox(root, Vector3(0.13, 0.28, 0.25), Vector3(side * 1.46, 2.2, 1.88), steel, 0.045)
		Kit.rbox(root, Vector3(0.015, 0.2, 0.17), Vector3(side * 1.533, 2.2, 1.88), alloy, 0.007, false)
		# Linen seat and walnut dash visible through the smoked glass.
		Kit.rbox(root, Vector3(0.55, 0.16, 0.53), Vector3(side * 0.52, 1.68, 0.93), Kit.fabric(Kit.LINEN, "tug_seat"), 0.07)
		Kit.rbox(root, Vector3(0.55, 0.51, 0.12), Vector3(side * 0.52, 1.94, 0.66), Kit.fabric(Kit.LINEN, "tug_seat"), 0.055)
	Kit.rbox(root, Vector3(1.98, 0.16, 0.33), Vector3(0, 1.85, 1.85), Kit.wood(Kit.WALNUT, "tug_dash"), 0.04)
	Kit.rbox(root, Vector3(0.4, 0.14, 0.03), Vector3(-0.5, 1.96, 1.68), steel, 0.025)
	# A pair of windshield wipers, warm work lamps and roof beacons.
	for side: float in [-1.0, 1.0]:
		Kit.add(root, Kit.rounded_box(Vector3(0.035, 0.53, 0.035), 0.012), steel, Vector3(side * 0.5, 2.04, 2.094), Vector3(0, 0, side * 24), false)
		Kit.rbox(root, Vector3(0.51, 0.27, 0.12), Vector3(side * 0.93, 1.03, 2.635), steel, 0.06)
		Kit.rbox(root, Vector3(0.39, 0.17, 0.035), Vector3(side * 0.93, 1.04, 2.712), headlight, 0.045, false)
		Kit.rbox(root, Vector3(0.25, 0.12, 0.04), Vector3(side * 1.15, 1.04, -2.644), red, 0.03, false)
		Kit.rbox(root, Vector3(0.23, 0.07, 0.23), Vector3(side * 0.9, 2.62, 1.2), steel, 0.03)
		Kit.add(root, _beacon(), amber, Vector3(side * 0.9, 2.65, 1.2), Vector3.ZERO, false)
	# Rear service grille has deep dark slots, a seam and pull handle.
	Kit.rbox(root, Vector3(1.6, 0.38, 0.045), Vector3(0, 1.28, -2.636), steel, 0.045)
	for i: int in 5:
		Kit.rbox(root, Vector3(1.43, 0.025, 0.04), Vector3(0, 1.13 + float(i) * 0.073, -2.669), alloy, 0.009, false)
	Kit.rbox(root, Vector3(0.36, 0.055, 0.055), Vector3(0, 1.59, -2.56), alloy, 0.02, false)
	# Large operational captions distributed over both counterweight flanks.
	var apron: Array = Signs.TEXT["apron"]
	_label(root, "PB–07", Vector3(0, 1.46, 2.207), 0.38, Kit.CREAM if scheme == 3 else Kit.CHARCOAL)
	for side: float in [-1.0, 1.0]:
		var holder: Node3D = Node3D.new()
		holder.position = Vector3(side * 1.431, 1.31, -1.23)
		holder.rotation_degrees.y = side * 90.0
		root.add_child(holder)
		for line: int in 3:
			var text_index: int = line if side < 0.0 else line + 3
			var caption: String = str(apron[text_index])
			_label(holder, caption, Vector3(0, 0.24 - float(line) * 0.24, 0.013), 0.34, Kit.CREAM if scheme == 3 else Kit.CHARCOAL)
	# Articulated towbar: fork, pivot pin, long tube, wheeled dolly and aircraft clevis.
	Kit.rbox(root, Vector3(0.75, 0.24, 0.48), Vector3(0, 0.51, 2.82), steel, 0.08)
	Kit.add(root, _pin(), Kit.brass(), Vector3(0, 0.37, 2.91))
	Kit.rbox(root, Vector3(0.22, 0.22, 3.72), Vector3(0, 0.49, 4.86), stripe, 0.075)
	Kit.rbox(root, Vector3(0.31, 0.31, 0.36), Vector3(0, 0.49, 3.18), alloy, 0.06)
	Kit.rbox(root, Vector3(0.8, 0.12, 0.19), Vector3(0, 0.32, 5.15), steel, 0.035)
	var dolly: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0, -0.08), Vector2(0.16, -0.08), Vector2(0.2, -0.045), Vector2(0.2, 0.045), Vector2(0.16, 0.08), Vector2(0, 0.08)]), 20)
	for side: float in [-1.0, 1.0]:
		Kit.add(root, dolly, rubber, Vector3(side * 0.35, 0.2, 5.15), Vector3(0, 0, 90))
		Kit.rbox(root, Vector3(0.13, 0.16, 0.57), Vector3(side * 0.18, 0.49, 6.77), alloy, 0.04)
	Kit.rbox(root, Vector3(0.44, 0.16, 0.12), Vector3(0, 0.49, 6.48), steel, 0.035)
	Kit.add(root, _pin(), Kit.brass(), Vector3(0, 0.36, 6.93))
	return root


static func _glass() -> StandardMaterial3D:
	if not _materials.has("glass"):
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.17, 0.25, 0.25, 0.66)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.18
		mat.metallic = 0.15
		_materials["glass"] = mat
	return _materials["glass"] as StandardMaterial3D


static func _beacon() -> ArrayMesh:
	return Kit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.105, 0), Vector2(0.105, 0.16), Vector2(0.08, 0.21), Vector2(0, 0.22)]), 20)


static func _pin() -> ArrayMesh:
	return Kit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.06, 0), Vector2(0.06, 0.25), Vector2(0.1, 0.25), Vector2(0.1, 0.29), Vector2(0, 0.29)]), 16)


static func _treads() -> ArrayMesh:
	if _meshes.has("treads"):
		return _meshes["treads"] as ArrayMesh
	# Merge 28 raised tread bars into one mesh per tyre, rather than 112 nodes.
	var bar: ArrayMesh = Kit.rounded_box(Vector3(0.35, 0.027, 0.05), 0.009, 2)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in 28:
		var angle: float = TAU * float(i) / 28.0
		var basis: Basis = Basis(Vector3.RIGHT, angle)
		var center: Vector3 = basis * Vector3(0, 0.625, 0)
		st.append_from(bar, 0, Transform3D(basis, center))
	var result: ArrayMesh = st.commit()
	_meshes["treads"] = result
	return result


static func _label(parent: Node3D, caption: String, at: Vector3, height: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signs.font()
	label.text = caption
	label.font_size = 96
	label.pixel_size = height / 96.0
	label.modulate = ink
	label.outline_size = 0
	label.position = at
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
