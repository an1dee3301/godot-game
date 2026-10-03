extends RefCounted
## Double-faced terminal timepiece. Dimensions in metres; top of bezel is 3.5 m.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "TerminalClockTotem"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var oak_tints: Array[Color] = [DesignKit.OAK, DesignKit.OAK.lightened(0.07), DesignKit.OAK.darkened(0.06), DesignKit.OAK]
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.LINEN, DesignKit.INDIGO]
	var oak: Material = DesignKit.wood(oak_tints[style], "clock_oak_%d" % style)
	var walnut: Material = DesignKit.wood(DesignKit.WALNUT, "clock_walnut")
	var steel: Material = DesignKit.metal()
	var brass: Material = DesignKit.brass()
	var accent: Material = DesignKit.paint(accents[style])
	var stone: Material = DesignKit.stone()
	# Broad, softly eased stone footing, recessed steel shoe and oak joinery.
	DesignKit.rbox(root, Vector3(1.12, 0.16, 0.74), Vector3(0.0, 0.08, 0.0), stone, 0.07)
	DesignKit.rbox(root, Vector3(0.88, 0.065, 0.44), Vector3(0.0, 0.1925, 0.0), steel, 0.025)
	DesignKit.rbox(root, Vector3(0.84, 2.69, 0.38), Vector3(0.0, 1.565, 0.0), oak, 0.075)
	# Walnut edge splines stop short of the base and disappear into the clock head.
	for x: float in [-0.365, 0.365]:
		DesignKit.rbox(root, Vector3(0.035, 2.35, 0.025), Vector3(x, 1.58, 0.191), walnut, 0.011)
		DesignKit.rbox(root, Vector3(0.035, 2.35, 0.025), Vector3(x, 1.58, -0.191), walnut, 0.011)
	DesignKit.rbox(root, Vector3(0.79, 0.022, 0.395), Vector3(0.0, 0.285, 0.0), brass, 0.008)
	# Turned walnut drum bridges both faces; there is no transparent cover to hide the hands.
	var drum: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -0.22), Vector2(0.66, -0.22), Vector2(0.69, -0.19),
		Vector2(0.69, 0.19), Vector2(0.66, 0.22), Vector2(0.0, 0.22)
	]), 96)
	DesignKit.add(root, drum, walnut, Vector3(0.0, 2.79, 0.0), Vector3(90.0, 0.0, 0.0))
	for side: int in 2:
		var face: Node3D = Node3D.new()
		face.name = "ClockFront" if side == 0 else "ClockBack"
		face.position = Vector3(0.0, 2.79, 0.22 if side == 0 else -0.22)
		face.rotation_degrees.y = 0.0 if side == 0 else 180.0
		root.add_child(face)
		_build_face(face, style, accent, steel, brass)
		var plaque: Node3D = Node3D.new()
		plaque.name = "TimeTranslations"
		plaque.rotation_degrees.y = face.rotation_degrees.y
		root.add_child(plaque)
		DesignKit.rbox(plaque, Vector3(0.64, 1.42, 0.035), Vector3(0.0, 1.36, 0.204), accent, 0.035)
		DesignKit.rbox(plaque, Vector3(0.5, 0.018, 0.008), Vector3(0.0, 2.0, 0.225), brass, 0.006, false)
		var captions: Array[String] = ["TIME", "時刻", "时间", "Giờ", "Heure", "Hora"]
		for line: int in captions.size():
			_label(plaque, captions[line], Vector3(0.0, 1.86 - float(line) * 0.205, 0.227), 0.0024, 84, DesignKit.CREAM if style == 3 else DesignKit.CHARCOAL)
	return root


static func _build_face(parent: Node3D, style: int, accent: Material, steel: Material, brass: Material) -> void:
	var dial: Material = DesignKit.washi(DesignKit.CREAM, 0.22, "clock_paper")
	DesignKit.add(parent, _disc(0.648, 0.025), dial, Vector3(0.0, 0.0, 0.012), Vector3(90.0, 0.0, 0.0), false)
	# Closed, bevelled annulus: brass surrounds the paper, never covers it.
	var bezel: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.645, -0.015), Vector2(0.69, -0.015), Vector2(0.71, 0.005),
		Vector2(0.71, 0.045), Vector2(0.695, 0.065), Vector2(0.655, 0.065),
		Vector2(0.645, 0.05), Vector2(0.645, -0.015)
	]), 96)
	DesignKit.add(parent, bezel, brass, Vector3.ZERO, Vector3(90.0, 0.0, 0.0))
	# Instanced engraved-looking indices keep each clock modest in node count.
	_indices(parent, true, steel)
	_indices(parent, false, steel)
	var numbers: Array[String] = ["12", "3", "6", "9"]
	var locations: Array[Vector3] = [Vector3(0.0, 0.402, 0.034), Vector3(0.415, 0.0, 0.034), Vector3(0.0, -0.407, 0.034), Vector3(-0.415, 0.0, 0.034)]
	for i: int in 4:
		_label(parent, numbers[i], locations[i], 0.002, 96, DesignKit.CHARCOAL)
	# All variants show a readable ten-past-ten family of static times on both sides.
	var minute: float = 8.0 + float(style) * 2.0
	_hand(parent, 0.325, 0.056, -(300.0 + minute * 0.5), 0.061, steel)
	_hand(parent, 0.475, 0.035, -minute * 6.0, 0.079, steel)
	DesignKit.add(parent, _disc(0.061, 0.018), brass, Vector3(0.0, 0.0, 0.092), Vector3(90.0, 0.0, 0.0), false)
	DesignKit.add(parent, _disc(0.025, 0.008), accent, Vector3(0.0, 0.0, 0.107), Vector3(90.0, 0.0, 0.0), false)


static func _hand(parent: Node3D, length_m: float, width_m: float, angle_deg: float, depth: float, material: Material) -> void:
	var angle: float = deg_to_rad(angle_deg)
	var center: Vector3 = Vector3(-sin(angle), cos(angle), 0.0) * (length_m * 0.5 - 0.035)
	center.z = depth
	DesignKit.add(parent, DesignKit.rounded_box(Vector3(width_m, length_m, 0.016), 0.007), material, center, Vector3(0.0, 0.0, angle_deg), false)


static func _indices(parent: Node3D, hours: bool, material: Material) -> void:
	var marks: MultiMeshInstance3D = MultiMeshInstance3D.new()
	marks.multimesh = _index_mesh(hours)
	marks.material_override = material
	marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(marks)


static func _index_mesh(hours: bool) -> MultiMesh:
	var key: String = "hour_indices" if hours else "minute_indices"
	if _meshes.has(key):
		return _meshes[key] as MultiMesh
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = DesignKit.rounded_box(Vector3(0.031 if hours else 0.012, 0.089 if hours else 0.033, 0.008), 0.003)
	instances.instance_count = 12 if hours else 48
	var index: int = 0
	for tick: int in 60:
		if (tick % 5 == 0) != hours:
			continue
		var angle: float = float(tick) * TAU / 60.0
		var radius: float = 0.571 if hours else 0.598
		var transform: Transform3D = Transform3D(Basis(Vector3.BACK, -angle), Vector3(sin(angle) * radius, cos(angle) * radius, 0.034))
		instances.set_instance_transform(index, transform)
		index += 1
	_meshes[key] = instances
	return instances


static func _disc(radius: float, thickness: float) -> ArrayMesh:
	var key: String = "disc:%.3f:%.3f" % [radius, thickness]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -thickness * 0.5), Vector2(radius - 0.003, -thickness * 0.5),
		Vector2(radius, -thickness * 0.5 + 0.003), Vector2(radius, thickness * 0.5 - 0.003),
		Vector2(radius - 0.003, thickness * 0.5), Vector2(0.0, thickness * 0.5)
	]), 96)
	_meshes[key] = mesh
	return mesh


static func _label(parent: Node3D, caption: String, at: Vector3, pixel_size_m: float, size: int, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixel_size_m
	label.position = at
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
