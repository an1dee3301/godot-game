extends RefCounted
## A warm digital directory housed in a softened, freestanding charcoal monolith.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "InfoScreen"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[choice]
	var steel: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.56, 0.45, "info_screen_shell")
	var wood: StandardMaterial3D = DesignKit.wood(DesignKit.OAK if choice % 2 == 0 else DesignKit.WALNUT, "info_oak" if choice % 2 == 0 else "info_walnut")
	var dark: StandardMaterial3D = DesignKit.paint(Color(0.055, 0.064, 0.061))
	var glass: StandardMaterial3D = DesignKit.washi(Color(0.075, 0.105, 0.10), 0.45, "info_screen_glass")
	var map_fill: StandardMaterial3D = DesignKit.washi(accent, 0.65, "info_map_%d" % choice)
	var path: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 1.2, "info_map_path")
	var marker: StandardMaterial3D = DesignKit.washi(Color(1.0, 0.72, 0.32), 1.4, "info_location_pin")
	# Flush stone ballast, recessed steel toe, and a continuous radiused shell.
	DesignKit.rbox(root, Vector3(1.53, 0.10, 0.64), Vector3(0.0, 0.05, 0.0), DesignKit.stone(), 0.045)
	DesignKit.rbox(root, Vector3(1.30, 0.07, 0.34), Vector3(0.0, 0.135, 0.0), dark, 0.025)
	DesignKit.rbox(root, Vector3(1.42, 2.23, 0.27), Vector3(0.0, 1.285, 0.0), steel, 0.075)
	# Oak rear access door and narrow side inlays soften the blackened enclosure.
	DesignKit.rbox(root, Vector3(1.21, 2.00, 0.025), Vector3(0.0, 1.28, -0.143), wood, 0.045)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.027, 2.03, 0.11), Vector3(side * 0.707, 1.28, -0.02), wood, 0.012)
	DesignKit.rbox(root, Vector3(0.21, 0.026, 0.015), Vector3(0.40, 1.30, -0.164), DesignKit.brass(), 0.009, false)
	# Inset gasket, brass bezel and luminous face: no transparent sorting or extra lights.
	DesignKit.rbox(root, Vector3(1.31, 2.06, 0.029), Vector3(0.0, 1.29, 0.138), dark, 0.049, false)
	DesignKit.rbox(root, Vector3(1.265, 2.015, 0.021), Vector3(0.0, 1.29, 0.156), DesignKit.brass(), 0.042, false)
	DesignKit.rbox(root, Vector3(1.24, 1.99, 0.018), Vector3(0.0, 1.29, 0.171), glass, 0.035, false)
	_label(root, "YOU ARE HERE", Vector3(0.0, 2.14, 0.19), 0.145, 1.17, DesignKit.CREAM)
	DesignKit.rbox(root, Vector3(1.12, 0.013, 0.008), Vector3(0.0, 2.015, 0.187), DesignKit.brass(), 0.003, false)
	# A diagrammatic terminal: two gate fingers, main concourse and arrivals hall.
	DesignKit.rbox(root, Vector3(1.04, 0.19, 0.008), Vector3(0.0, 1.57, 0.187), map_fill, 0.033, false)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.25, 0.37, 0.008), Vector3(side * 0.375, 1.785, 0.187), map_fill, 0.036, false)
		DesignKit.rbox(root, Vector3(0.024, 0.30, 0.008), Vector3(side * 0.375, 1.76, 0.197), path, 0.009, false)
		_label(root, "A" if side < 0.0 else "B", Vector3(side * 0.375, 1.915, 0.211), 0.10, 0.16, DesignKit.CREAM)
	DesignKit.rbox(root, Vector3(0.48, 0.20, 0.008), Vector3(0.0, 1.31, 0.187), map_fill, 0.034, false)
	DesignKit.rbox(root, Vector3(0.15, 0.22, 0.008), Vector3(0.0, 1.43, 0.187), map_fill, 0.024, false)
	DesignKit.rbox(root, Vector3(0.87, 0.024, 0.009), Vector3(0.0, 1.57, 0.199), path, 0.009, false)
	DesignKit.rbox(root, Vector3(0.024, 0.21, 0.009), Vector3(0.0, 1.45, 0.199), path, 0.009, false)
	# A generously sized teardrop pin with a contrasting circular centre.
	var pin_x: float = -0.17 if choice % 2 == 0 else 0.17
	DesignKit.add(root, _pin_mesh(), marker, Vector3(pin_x, 1.59, 0.219), Vector3.ZERO, false)
	var disk: ArrayMesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.044, 0.0), Vector2(0.044, 0.006), Vector2(0.0, 0.006)]), 24)
	DesignKit.add(root, disk, dark, Vector3(pin_x, 1.67, 0.229), Vector3(90.0, 0.0, 0.0), false)
	# Each translation has its own line; the primary marker remains visible at distance.
	var captions: Array[String] = ["現在地", "您在这里", "Bạn đang ở đây", "Vous êtes ici", "Usted está aquí"]
	for index: int in captions.size():
		_label(root, captions[index], Vector3(0.0, 1.10 - float(index) * 0.16, 0.19), 0.115, 1.14, DesignKit.CREAM)
	# Quiet status light and rear ventilation slots, all below eye-level information.
	DesignKit.rbox(root, Vector3(0.10, 0.011, 0.01), Vector3(0.0, 0.215, 0.14), map_fill, 0.004, false)
	for slot: int in 4:
		DesignKit.rbox(root, Vector3(0.40, 0.012, 0.008), Vector3(0.0, 0.38 + float(slot) * 0.035, -0.159), dark, 0.004, false)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, height: float, width: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signage.font()
	label.font_size = 96
	var metrics: Vector2 = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size)
	label.pixel_size = minf(height / label.font.get_height(label.font_size), width / maxf(metrics.x, 1.0))
	label.text = caption
	label.position = at
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = false
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _pin_mesh() -> ArrayMesh:
	if _meshes.has("pin"):
		return _meshes["pin"] as ArrayMesh
	var polygon: PackedVector2Array = PackedVector2Array([Vector2(0.0, -0.045)])
	for step: int in 25:
		var angle: float = -PI * 0.25 + float(step) / 24.0 * PI * 1.5
		polygon.append(Vector2(cos(angle) * 0.115, 0.08 + sin(angle) * 0.115))
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle: int in indices.size() / 3:
		# Godot front faces are clockwise when viewed from +Z.
		for corner: int in [0, 2, 1]:
			var point: Vector2 = polygon[indices[triangle * 3 + corner]]
			surface.set_normal(Vector3.FORWARD * -1.0)
			surface.add_vertex(Vector3(point.x, point.y, 0.0))
	var mesh: ArrayMesh = surface.commit()
	_meshes["pin"] = mesh
	return mesh
