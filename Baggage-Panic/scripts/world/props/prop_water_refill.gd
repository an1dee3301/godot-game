extends RefCounted
## Honed limestone refill column with an open bottle niche and multilingual wayfinding.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "WaterRefill"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[style]
	var stone: StandardMaterial3D = DesignKit.stone(DesignKit.LIMESTONE, 0.55, "water_refill_limestone")
	var brass: StandardMaterial3D = DesignKit.brass()
	var steel: StandardMaterial3D = DesignKit.metal()
	var timber: StandardMaterial3D = DesignKit.wood(DesignKit.OAK if style % 2 == 0 else DesignKit.WALNUT, "water_refill_oak" if style % 2 == 0 else "water_refill_walnut")
	# A recessed toe and chamfered stone plinth keep the column firmly on the floor.
	DesignKit.rbox(root, Vector3(0.94, 0.09, 0.58), Vector3(0.0, 0.045, 0.0), steel, 0.035)
	DesignKit.rbox(root, Vector3(1.12, 0.10, 0.72), Vector3(0.0, 0.14, 0.0), stone, 0.045)
	DesignKit.rbox(root, Vector3(1.04, 0.71, 0.64), Vector3(0.0, 0.545, 0.0), stone, 0.075)
	# Walnut/oak service hatch, with a shadow seam and brass finger pull.
	DesignKit.rbox(root, Vector3(0.76, 0.51, 0.028), Vector3(0.0, 0.56, 0.326), steel, 0.012)
	DesignKit.rbox(root, Vector3(0.72, 0.47, 0.032), Vector3(0.0, 0.56, 0.345), timber, 0.018)
	DesignKit.rbox(root, Vector3(0.19, 0.025, 0.025), Vector3(0.0, 0.73, 0.371), brass, 0.010, false)
	# Open niche: back, two stone cheeks and lintel, rather than a painted rectangle.
	DesignKit.rbox(root, Vector3(1.04, 1.13, 0.18), Vector3(0.0, 1.465, -0.23), stone, 0.065)
	DesignKit.rbox(root, Vector3(0.78, 0.79, 0.025), Vector3(0.0, 1.38, -0.127), DesignKit.paint(accent), 0.012)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.13, 1.13, 0.58), Vector3(side * 0.455, 1.465, 0.02), stone, 0.045)
	DesignKit.rbox(root, Vector3(1.04, 0.15, 0.64), Vector3(0.0, 1.955, 0.0), stone, 0.05)
	DesignKit.rbox(root, Vector3(0.73, 0.022, 0.035), Vector3(0.0, 1.869, 0.08), DesignKit.washi(DesignKit.CREAM, 1.2, "water_refill_niche_glow"), 0.009, false)
	# Bottle shelf with a raised rim and a genuinely slotted drain grate.
	DesignKit.rbox(root, Vector3(1.10, 0.085, 0.78), Vector3(0.0, 0.93, 0.075), stone, 0.04)
	DesignKit.rbox(root, Vector3(0.70, 0.025, 0.42), Vector3(0.0, 0.982, 0.12), steel, 0.011, false)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.026, 0.027, 0.44), Vector3(side * 0.355, 0.995, 0.12), brass, 0.008, false)
	for end: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.73, 0.027, 0.025), Vector3(0.0, 0.995, 0.12 + end * 0.22), brass, 0.008, false)
	for slat: int in 10:
		DesignKit.rbox(root, Vector3(0.025, 0.018, 0.39), Vector3(-0.30 + float(slat) * 0.067, 1.003, 0.12), brass, 0.007, false)
	# Turned escutcheon, projecting spout, downward nozzle and dark aerator opening.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.071, 0.0), Vector2(0.075, 0.014), Vector2(0.065, 0.028), Vector2(0.0, 0.028)])), brass, Vector3(0.0, 1.72, -0.108), Vector3(90.0, 0.0, 0.0), false)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.026, 0.0), Vector2(0.026, 0.27), Vector2(0.022, 0.29), Vector2(0.0, 0.29)])), brass, Vector3(0.0, 1.72, -0.08), Vector3(90.0, 0.0, 0.0), false)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.032, 0.0), Vector2(0.036, 0.02), Vector2(0.029, 0.09), Vector2(0.0, 0.09)])), brass, Vector3(0.0, 1.63, 0.19), Vector3.ZERO, false)
	DesignKit.rbox(root, Vector3(0.034, 0.006, 0.034), Vector3(0.0, 1.628, 0.19), steel, 0.013, false)
	DesignKit.rbox(root, Vector3(0.083, 0.055, 0.014), Vector3(0.0, 1.49, -0.104), steel, 0.020, false)
	# Broad integrated wayfinding crown; letters stay full size rather than auto-shrinking.
	DesignKit.rbox(root, Vector3(2.54, 1.28, 0.18), Vector3(0.0, 2.65, -0.065), timber, 0.075)
	DesignKit.rbox(root, Vector3(2.44, 1.18, 0.04), Vector3(0.0, 2.65, 0.041), steel, 0.019)
	DesignKit.rbox(root, Vector3(2.30, 0.022, 0.012), Vector3(0.0, 3.19, 0.067), brass, 0.005, false)
	DesignKit.rbox(root, Vector3(0.48, 0.49, 0.022), Vector3(-0.91, 2.9, 0.074), DesignKit.paint(accent), 0.010, false)
	DesignKit.add(root, _drop_mesh(), DesignKit.washi(DesignKit.CREAM, 0.45, "water_refill_icon"), Vector3(-0.91, 2.90, 0.087), Vector3.ZERO, false)
	_label(root, "Water refill", Vector3(0.26, 2.97, 0.076), 100, 0.0026)
	_label(root, "給水  ·  饮用水", Vector3(0.26, 2.71, 0.076), 72, 0.0026)
	_label(root, "Nước uống", Vector3(0.0, 2.44, 0.076), 70, 0.0026)
	_label(root, "Eau potable  ·  Agua potable", Vector3(0.0, 2.19, 0.076), 66, 0.0026)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel_size: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixel_size
	label.modulate = DesignKit.CREAM
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _drop_mesh() -> ArrayMesh:
	if _meshes.has("drop"):
		return _meshes["drop"] as ArrayMesh
	# A pointed water drop with a smooth rounded lower silhouette, facing +Z.
	var outline: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.19), Vector2(-0.10, 0.035)])
	for step: int in 21:
		var angle: float = PI + float(step) / 20.0 * PI
		outline.append(Vector2(cos(angle) * 0.13, -0.045 + sin(angle) * 0.13))
	outline.append(Vector2(0.10, 0.035))
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(outline)
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle: int in range(0, indices.size(), 3):
		# Geometry2D emits CCW; Godot's front faces use clockwise winding.
		for offset: int in [0, 2, 1]:
			var point: Vector2 = outline[indices[triangle + offset]]
			surface.set_normal(Vector3.FORWARD * -1.0)
			surface.add_vertex(Vector3(point.x, point.y, 0.0))
	var mesh: ArrayMesh = surface.commit()
	_meshes["drop"] = mesh
	return mesh
