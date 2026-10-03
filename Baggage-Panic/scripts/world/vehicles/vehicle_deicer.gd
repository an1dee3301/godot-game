extends RefCounted
## Six-wheel apron deicer, with a raised knuckle boom and open spray basket.
## Metres; tyre contact is y=0 and the cab faces +Z.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Deicer_Articulated"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var colors: Array[Color] = [Color(0.94, 0.70, 0.16), Kit.CREAM, Kit.SAGE, Kit.CHARCOAL]
	var accents: Array[Color] = [Kit.CHARCOAL, Kit.CLAY, Kit.CREAM, Kit.OCHRE]
	var scheme: int = posmod(variant, 4)
	var body: StandardMaterial3D = Kit.paint(colors[scheme], 0.43)
	var accent: StandardMaterial3D = Kit.paint(accents[scheme], 0.48)
	var steel: StandardMaterial3D = Kit.metal()
	var alloy: StandardMaterial3D = Kit.metal(Color(0.58, 0.59, 0.56), 0.33, 0.85, "deicer_alloy")
	var rubber: StandardMaterial3D = Kit.paint(Color(0.065, 0.063, 0.057), 0.95)
	var glass: StandardMaterial3D = Kit.metal(Color(0.10, 0.20, 0.23), 0.17, 0.3, "deicer_glass")
	var headlight: StandardMaterial3D = Kit.washi(Kit.CREAM, 3.2, "deicer_headlight")
	var amber: StandardMaterial3D = Kit.washi(Color(1.0, 0.43, 0.06), 3.0, "deicer_beacon")
	var red: StandardMaterial3D = Kit.washi(Color(0.88, 0.08, 0.035), 1.8, "deicer_tail")

	# Low chassis and a slightly inset, brushed-metal equipment deck.
	Kit.rbox(root, Vector3(2.35, 0.35, 8.0), Vector3(0, 0.95, -0.15), steel, 0.12)
	Kit.rbox(root, Vector3(2.55, 0.16, 5.8), Vector3(0, 1.22, -1.25), alloy, 0.06)
	for z: float in [-2.95, -1.4, 2.55]:
		_rod(root, Vector3(-1.32, 0.59, z), Vector3(1.32, 0.59, z), 0.11, steel)
		for side: float in [-1.0, 1.0]:
			var x: float = side * 1.27
			Kit.add(root, _tire(), rubber, Vector3(x, 0.59, z), Vector3(0, 0, 90))
			Kit.add(root, _hub(), alloy, Vector3(side * 1.49, 0.59, z), Vector3(0, 0, -side * 90))
			Kit.rbox(root, Vector3(0.49, 0.18, 1.5), Vector3(x, 1.29, z), body, 0.085)

	# A rounded insulated glycol tank, lower service cabinets and distinct tank bands.
	Kit.rbox(root, Vector3(2.22, 1.55, 4.55), Vector3(0, 2.06, -1.65), body, 0.40)
	for z: float in [-3.12, -0.24]:
		Kit.rbox(root, Vector3(2.25, 1.58, 0.10), Vector3(0, 2.06, z), alloy, 0.045)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.12, 0.69, 4.45), Vector3(side * 1.22, 1.64, -1.6), accent, 0.05)
		for z: float in [-2.9, -1.6, -0.3]:
			Kit.rbox(root, Vector3(0.025, 0.54, 0.035), Vector3(side * 1.288, 1.64, z), steel, 0.01, false)
			Kit.rbox(root, Vector3(0.055, 0.05, 0.25), Vector3(side * 1.30, 1.78, z + 0.3), alloy, 0.02, false)
		_side_marking(root, side, steel)
	Kit.add(root, _disk(0.27, 0.12), alloy, Vector3(0.65, 2.82, -3.1))
	Kit.rbox(root, Vector3(0.40, 0.08, 0.06), Vector3(0.65, 2.98, -3.1), steel, 0.025)
	Kit.rbox(root, Vector3(2.65, 0.28, 0.28), Vector3(0, 0.84, -4.22), steel, 0.1)
	for x: float in [-0.95, 0.95]:
		Kit.rbox(root, Vector3(0.3, 0.17, 0.08), Vector3(x, 1.22, -4.13), red, 0.04, false)

	# Forward-control cab: broad windscreen with a center mullion and softened roof.
	Kit.rbox(root, Vector3(2.35, 1.75, 2.05), Vector3(0, 2.06, 2.60), body, 0.22)
	Kit.rbox(root, Vector3(2.4, 0.18, 2.15), Vector3(0, 2.97, 2.59), accent, 0.075)
	for x: float in [-0.52, 0.52]:
		var pane: MeshInstance3D = Kit.rbox(root, Vector3(0.96, 0.78, 0.055), Vector3(x, 2.46, 3.637), glass, 0.07)
		pane.rotation_degrees.x = -7.0
		_rod(root, Vector3(x - 0.31, 2.12, 3.69), Vector3(x + 0.20, 2.34, 3.72), 0.015, steel)
	Kit.rbox(root, Vector3(2.05, 0.14, 0.05), Vector3(0, 1.89, 3.634), accent, 0.035)
	Kit.rbox(root, Vector3(1.05, 0.32, 0.065), Vector3(0, 1.58, 3.645), steel, 0.06)
	for y: float in [1.49, 1.58, 1.67]:
		Kit.rbox(root, Vector3(0.88, 0.025, 0.025), Vector3(0, y, 3.685), alloy, 0.01, false)
	Kit.rbox(root, Vector3(2.57, 0.24, 0.31), Vector3(0, 1.14, 3.66), steel, 0.08)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.045, 0.78, 1.16), Vector3(side * 1.179, 2.45, 2.56), glass, 0.065)
		Kit.rbox(root, Vector3(0.04, 0.12, 1.38), Vector3(side * 1.19, 1.94, 2.52), accent, 0.025)
		Kit.rbox(root, Vector3(0.055, 0.06, 0.25), Vector3(side * 1.20, 1.81, 2.03), alloy, 0.025, false)
		Kit.rbox(root, Vector3(0.5, 0.10, 0.7), Vector3(side * 1.25, 0.99, 1.53), alloy, 0.035)
		_rod(root, Vector3(side * 1.15, 2.42, 3.3), Vector3(side * 1.48, 2.42, 3.3), 0.035, steel)
		Kit.rbox(root, Vector3(0.16, 0.38, 0.22), Vector3(side * 1.48, 2.52, 3.3), steel, 0.055)
		Kit.rbox(root, Vector3(0.42, 0.24, 0.09), Vector3(side * 0.85, 1.58, 3.67), headlight, 0.065, false)
		Kit.add(root, _disk(0.11, 0.08), steel, Vector3(side * 0.82, 3.05, 2.43))
		Kit.add(root, _disk(0.09, 0.17), amber, Vector3(side * 0.82, 3.12, 2.43), Vector3.ZERO, false)

	# Turntable and two rigid boom sections: an unmistakable elbow silhouette.
	var base: Vector3 = Vector3(0, 3.03, -1.25)
	var elbow: Vector3 = Vector3(0, 4.78, -2.62)
	var tip: Vector3 = Vector3(0, 5.78, 2.56)
	Kit.add(root, _disk(0.62, 0.18), steel, Vector3(0, 2.84, -1.25))
	Kit.rbox(root, Vector3(0.78, 0.61, 0.85), base, accent, 0.13)
	_beam(root, base, elbow, Vector2(0.48, 0.50), body)
	_beam(root, elbow, tip, Vector2(0.36, 0.42), body)
	_beam(root, Vector3(0, 5.46, 0.87), tip, Vector2(0.27, 0.30), alloy)
	# Hydraulic ram, exposed piston, and hose running below the upper boom.
	_rod(root, Vector3(0.32, 3.17, -0.98), Vector3(0.32, 4.0, -1.62), 0.085, steel)
	_rod(root, Vector3(0.32, 4.0, -1.62), Vector3(0.32, 4.49, -2.03), 0.047, alloy)
	_rod(root, Vector3(-0.31, 4.28, -2.2), Vector3(-0.31, 4.78, -0.55), 0.075, steel)
	_rod(root, Vector3(-0.31, 4.78, -0.55), Vector3(-0.31, 5.1, 0.45), 0.043, alloy)
	_rod(root, elbow + Vector3(0.24, -0.26, 0), tip + Vector3(0.24, -0.26, 0), 0.04, rubber)
	for joint: Vector3 in [base, elbow, tip]:
		_rod(root, joint - Vector3(0.32, 0, 0), joint + Vector3(0.32, 0, 0), 0.16, steel)
		_rod(root, joint + Vector3(0.33, 0, 0), joint + Vector3(0.36, 0, 0), 0.09, Kit.brass())

	# Self-levelled working basket: solid kickplate, open rails and a forward nozzle.
	Kit.rbox(root, Vector3(1.28, 0.21, 1.22), Vector3(0, 5.14, 3.04), steel, 0.08)
	Kit.rbox(root, Vector3(1.24, 0.35, 0.09), Vector3(0, 5.4, 3.62), accent, 0.035)
	for x: float in [-0.59, 0.59]:
		Kit.rbox(root, Vector3(0.09, 0.35, 1.13), Vector3(x, 5.4, 3.04), body, 0.035)
		for z: float in [2.48, 3.60]:
			_rod(root, Vector3(x, 5.32, z), Vector3(x, 6.24, z), 0.035, steel)
		_rod(root, Vector3(x, 6.24, 2.48), Vector3(x, 6.24, 3.60), 0.042, accent)
		_rod(root, Vector3(x, 5.87, 2.48), Vector3(x, 5.87, 3.60), 0.026, steel)
	for z: float in [2.48, 3.60]:
		_rod(root, Vector3(-0.59, 6.24, z), Vector3(0.59, 6.24, z), 0.042, accent)
	Kit.rbox(root, Vector3(0.37, 0.22, 0.26), Vector3(-0.38, 5.98, 3.33), steel, 0.05)
	Kit.rbox(root, Vector3(0.25, 0.045, 0.17), Vector3(-0.38, 6.105, 3.33), glass, 0.025, false)
	_rod(root, Vector3(0.38, 5.62, 3.36), Vector3(0.38, 6.17, 3.62), 0.055, rubber)
	_rod(root, Vector3(0.38, 6.17, 3.62), Vector3(0.38, 6.10, 4.32), 0.045, alloy)
	_rod(root, Vector3(0.38, 6.10, 4.32), Vector3(0.38, 6.08, 4.51), 0.073, Kit.brass())
	return root


static func _side_marking(parent: Node3D, side: float, backing: Material) -> void:
	var sign: Node3D = Node3D.new()
	sign.position = Vector3(side * 1.133, 2.2, -1.65)
	sign.rotation_degrees.y = side * 90.0
	parent.add_child(sign)
	Kit.rbox(sign, Vector3(3.8, 1.02, 0.035), Vector3.ZERO, backing, 0.045)
	var captions: Array[String] = ["DE-ICING", "除氷  ·  除冰", "Khử băng", "Dégivrage  ·  Deshielo"]
	for i: int in captions.size():
		var label: Label3D = Label3D.new()
		label.text = captions[i]
		label.font = Signs.font()
		label.font_size = 88 if i == 0 else 64
		label.pixel_size = 0.0035
		label.position = Vector3(0, 0.33 - float(i) * 0.225, 0.024)
		label.modulate = Kit.CREAM
		label.outline_size = 0
		label.double_sided = false
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sign.add_child(label)


static func _beam(parent: Node3D, start: Vector3, end: Vector3, section: Vector2, material: Material) -> void:
	var direction: Vector3 = end - start
	var part: MeshInstance3D = Kit.rbox(parent, Vector3(section.x, section.y, direction.length()), (start + end) * 0.5, material, 0.07)
	part.quaternion = Quaternion(Vector3.FORWARD, direction.normalized())


static func _rod(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var direction: Vector3 = end - start
	var part: MeshInstance3D = Kit.add(parent, _disk(radius, direction.length()), material, (start + end) * 0.5)
	part.quaternion = Quaternion(Vector3.UP, direction.normalized())


static func _disk(radius: float, height: float) -> ArrayMesh:
	var key: String = "disk:%.4f:%.4f" % [radius, height]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var bevel: float = minf(0.025, minf(radius, height) * 0.2)
	var mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0, -height * 0.5), Vector2(radius - bevel, -height * 0.5),
		Vector2(radius, -height * 0.5 + bevel), Vector2(radius, height * 0.5 - bevel),
		Vector2(radius - bevel, height * 0.5), Vector2(0, height * 0.5)
	]), 16)
	_meshes[key] = mesh
	return mesh


static func _tire() -> ArrayMesh:
	if _meshes.has("tire"):
		return _meshes["tire"] as ArrayMesh
	var mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.30, -0.18), Vector2(0.47, -0.22), Vector2(0.56, -0.17),
		Vector2(0.59, -0.10), Vector2(0.59, 0.10), Vector2(0.56, 0.17),
		Vector2(0.47, 0.22), Vector2(0.30, 0.18), Vector2(0.30, -0.18)
	]), 32)
	_meshes["tire"] = mesh
	return mesh


static func _hub() -> ArrayMesh:
	if _meshes.has("hub"):
		return _meshes["hub"] as ArrayMesh
	var mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0, -0.04), Vector2(0.31, -0.04), Vector2(0.32, 0.0),
		Vector2(0.27, 0.035), Vector2(0.21, 0.02), Vector2(0.13, 0.02),
		Vector2(0.12, 0.09), Vector2(0, 0.09)
	]), 24)
	_meshes["hub"] = mesh
	return mesh
