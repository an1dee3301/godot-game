extends RefCounted
## A freestanding charging pedestal; metres, floor origin, service face toward +Z.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ChargingStation"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.LINEN]
	var captions: Array[String] = ["充電 · 充电", "Sạc điện", "Recharge", "Carga"]
	var accent: Color = accents[choice]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var brass: StandardMaterial3D = DesignKit.brass()
	var steel: StandardMaterial3D = DesignKit.metal()
	var ink: StandardMaterial3D = DesignKit.paint(DesignKit.CHARCOAL)
	var paper: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 1.25, "charging_cap")
	# The broad stone foot keeps the narrow pedestal stable without protruding feet.
	DesignKit.rbox(root, Vector3(0.64, 0.06, 0.48), Vector3(0.0, 0.03, 0.0), DesignKit.stone(), 0.026)
	DesignKit.rbox(root, Vector3(0.44, 0.032, 0.27), Vector3(0.0, 0.076, 0.0), steel, 0.012)
	DesignKit.rbox(root, Vector3(0.50, 1.02, 0.30), Vector3(0.0, 0.60, 0.0), oak, 0.055)
	# A recessed rear access door with a walnut reveal and a single brass latch.
	DesignKit.rbox(root, Vector3(0.34, 0.65, 0.018), Vector3(0.0, 0.50, -0.149), walnut, 0.025)
	DesignKit.rbox(root, Vector3(0.31, 0.62, 0.014), Vector3(0.0, 0.50, -0.162), oak, 0.021)
	DesignKit.rbox(root, Vector3(0.035, 0.012, 0.009), Vector3(0.10, 0.73, -0.173), brass, 0.004)
	# Continuous lantern cap, with walnut lid and fine brass shadow lines.
	DesignKit.rbox(root, Vector3(0.53, 0.016, 0.33), Vector3(0.0, 1.103, 0.0), brass, 0.007)
	DesignKit.rbox(root, Vector3(0.52, 0.072, 0.32), Vector3(0.0, 1.147, 0.0), paper, 0.028, false)
	DesignKit.rbox(root, Vector3(0.53, 0.014, 0.33), Vector3(0.0, 1.190, 0.0), brass, 0.006)
	DesignKit.rbox(root, Vector3(0.55, 0.024, 0.35), Vector3(0.0, 1.209, 0.0), walnut, 0.011)
	# High-contrast universal USB trident, drawn as one cached mesh.
	DesignKit.rbox(root, Vector3(0.28, 0.205, 0.016), Vector3(0.0, 0.987, 0.153), DesignKit.paint(accent), 0.022)
	DesignKit.add(root, _usb_icon(), DesignKit.paint(DesignKit.CREAM), Vector3(0.0, 0.982, 0.163), Vector3.ZERO, false)
	# Two independent brass outlets: familiar USB-A and reversible USB-C openings.
	for x: float in [-0.115, 0.115]:
		DesignKit.rbox(root, Vector3(0.176, 0.09, 0.018), Vector3(x, 0.832, 0.154), brass, 0.018)
		DesignKit.rbox(root, Vector3(0.142, 0.059, 0.012), Vector3(x, 0.832, 0.167), ink, 0.011)
		var is_type_c: bool = x > 0.0
		var slot_width: float = 0.052 if is_type_c else 0.060
		var slot_radius: float = 0.009 if is_type_c else 0.003
		DesignKit.rbox(root, Vector3(slot_width + 0.008, 0.025, 0.005), Vector3(x, 0.832, 0.175), brass, slot_radius)
		DesignKit.rbox(root, Vector3(slot_width, 0.017, 0.005), Vector3(x, 0.832, 0.179), ink, slot_radius)
		DesignKit.rbox(root, Vector3(slot_width - 0.013, 0.004, 0.003), Vector3(x, 0.832, 0.182), DesignKit.paint(accent), 0.001)
	# A protected phone ledge, at an accessible 0.75 m, with a soft replaceable pad.
	for x: float in [-0.18, 0.18]:
		DesignKit.rbox(root, Vector3(0.023, 0.12, 0.14), Vector3(x, 0.676, 0.19), brass, 0.01)
	DesignKit.rbox(root, Vector3(0.66, 0.044, 0.39), Vector3(0.0, 0.745, 0.19), walnut, 0.021)
	DesignKit.rbox(root, Vector3(0.57, 0.009, 0.265), Vector3(0.0, 0.7715, 0.225), DesignKit.fabric(accent, "charging_pad_%d" % choice), 0.004)
	DesignKit.rbox(root, Vector3(0.60, 0.023, 0.014), Vector3(0.0, 0.778, 0.373), brass, 0.006)
	# Large face lettering; translations rotate across the four terminal copies.
	_label(root, "CHARGE", Vector3(0.0, 0.56, 0.158), 0.093)
	_label(root, captions[choice], Vector3(0.0, 0.425, 0.158), 0.087)
	DesignKit.rbox(root, Vector3(0.30, 0.008, 0.006), Vector3(0.0, 0.335, 0.153), brass, 0.003, false)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, height: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 80
	label.pixel_size = height / 80.0
	var width: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, 80).x * label.pixel_size
	if width > 0.43:
		label.pixel_size *= 0.43 / width
	label.position = at
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _usb_icon() -> ArrayMesh:
	if _meshes.has("usb"):
		return _meshes["usb"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Main arrow and two bent branches; dimensions are in metres.
	_polygon(surface, PackedVector2Array([Vector2(-0.009, -0.071), Vector2(0.009, -0.071), Vector2(0.009, 0.061), Vector2(0.030, 0.061), Vector2(0.0, 0.091), Vector2(-0.030, 0.061), Vector2(-0.009, 0.061)]))
	_polygon(surface, PackedVector2Array([Vector2(-0.003, -0.036), Vector2(-0.059, 0.003), Vector2(-0.059, 0.043), Vector2(-0.042, 0.043), Vector2(-0.042, 0.012), Vector2(0.006, -0.021)]))
	_polygon(surface, PackedVector2Array([Vector2(-0.005, -0.004), Vector2(0.041, 0.026), Vector2(0.041, 0.058), Vector2(0.058, 0.058), Vector2(0.058, 0.016), Vector2(0.005, -0.020)]))
	_polygon(surface, PackedVector2Array([Vector2(0.030, 0.050), Vector2(0.069, 0.050), Vector2(0.069, 0.081), Vector2(0.030, 0.081)]))
	for center: Vector2 in [Vector2(0.0, -0.070), Vector2(-0.0505, 0.049)]:
		var disc: PackedVector2Array = PackedVector2Array()
		for step: int in 16:
			var angle: float = TAU * float(step) / 16.0
			disc.append(center + Vector2(cos(angle), sin(angle)) * 0.020)
		_polygon(surface, disc)
	var mesh: ArrayMesh = surface.commit()
	_meshes["usb"] = mesh
	return mesh


static func _polygon(surface: SurfaceTool, points: PackedVector2Array) -> void:
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(points)
	for triangle: int in range(0, indices.size(), 3):
		# Godot front faces wind clockwise when viewed from the +Z service side.
		for corner: int in [2, 1, 0]:
			var point: Vector2 = points[indices[triangle + corner]]
			surface.set_normal(Vector3.FORWARD * -1.0)
			surface.add_vertex(Vector3(point.x, point.y, 0.0))
