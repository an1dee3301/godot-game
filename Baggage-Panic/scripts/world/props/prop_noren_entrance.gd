extends RefCounted
## A joinery-framed shop portal with a softly pleated, split indigo noren.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "NorenEntrance"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "oak")
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var stone: StandardMaterial3D = DesignKit.stone()
	var steel: StandardMaterial3D = DesignKit.metal()
	var brass: StandardMaterial3D = DesignKit.brass()
	var tones: Array[Color] = [DesignKit.INDIGO, Color(0.17, 0.25, 0.37), Color(0.26, 0.34, 0.44), Color(0.20, 0.28, 0.34)]
	var tint: Color = tones[style]
	var cloth: StandardMaterial3D = _cloth(tint, "body_%d" % style)
	var hem: StandardMaterial3D = _cloth(tint.lightened(0.12), "hem_%d" % style)
	# Low, eased limestone sill: the bottom sits exactly on the floor.
	DesignKit.rbox(root, Vector3(3.12, 0.06, 0.66), Vector3(0.0, 0.03, 0.0), stone, 0.024)
	DesignKit.rbox(root, Vector3(2.67, 0.008, 0.022), Vector3(0.0, 0.064, 0.23), brass, 0.003, false)
	for side: float in [-1.0, 1.0]:
		var x: float = side * 1.44
		DesignKit.rbox(root, Vector3(0.24, 2.79, 0.32), Vector3(x, 1.455, 0.0), oak, 0.035)
		DesignKit.rbox(root, Vector3(0.26, 0.16, 0.34), Vector3(x, 0.14, 0.0), steel, 0.022)
		# Inset walnut fillet and visible contrasting mortise-end pegs.
		DesignKit.rbox(root, Vector3(0.022, 2.45, 0.012), Vector3(x + side * 0.07, 1.49, 0.165), walnut, 0.005, false)
		for y: float in [2.60, 2.74]:
			DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.014, 0.0), Vector2(0.014, 0.009), Vector2(0.0, 0.009)]), 12), walnut, Vector3(x, y, 0.161), Vector3(90.0, 0.0, 0.0), false)
		DesignKit.rbox(root, Vector3(0.075, 0.13, 0.14), Vector3(side * 1.27, 2.63, -0.01), brass, 0.018)
	DesignKit.rbox(root, Vector3(3.18, 0.23, 0.36), Vector3(0.0, 2.79, 0.0), oak, 0.04)
	DesignKit.rbox(root, Vector3(2.78, 0.035, 0.045), Vector3(0.0, 2.67, 0.14), walnut, 0.012)
	# Turned pole with eased end caps, oriented along the opening.
	var pole: ArrayMesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, -1.38), Vector2(0.027, -1.38), Vector2(0.032, -1.35), Vector2(0.032, 1.35), Vector2(0.027, 1.38), Vector2(0.0, 1.38)]))
	DesignKit.add(root, pole, walnut, Vector3(0.0, 2.64, 0.055), Vector3(0.0, 0.0, 90.0))
	for side: float in [-1.0, 1.0]:
		var panel_at: Vector3 = Vector3(side * 0.668, 2.63, 0.085)
		DesignKit.add(root, _curtain_mesh(false), cloth, panel_at)
		DesignKit.add(root, _curtain_mesh(true), hem, panel_at + Vector3(0.0, 0.0, 0.002), Vector3.ZERO, false)
		# Broad sewn pole pocket, with its upper edge folded around the rod.
		DesignKit.rbox(root, Vector3(1.29, 0.085, 0.073), Vector3(side * 0.668, 2.62, 0.063), cloth, 0.025)
	# The four kana read as one large white print across the central split.
	var welcome: Array = Signage.TEXT["welcome"]
	_label(root, str(welcome[1]), Vector3(0.0, 2.22, 0.13), 180, 0.0028)
	# A framed washi transom presents the other five airport languages.
	DesignKit.rbox(root, Vector3(3.02, 0.67, 0.19), Vector3(0.0, 3.185, -0.01), oak, 0.035)
	DesignKit.rbox(root, Vector3(2.82, 0.53, 0.025), Vector3(0.0, 3.185, 0.09), DesignKit.washi(DesignKit.CREAM, 0.65, "noren_transom"), 0.025, false)
	_label(root, "%s  ·  %s" % [welcome[0], welcome[2]], Vector3(0.0, 3.35, 0.108), 76, 0.0025, DesignKit.CHARCOAL)
	_label(root, str(welcome[3]), Vector3(0.0, 3.18, 0.108), 64, 0.0025, DesignKit.CHARCOAL)
	_label(root, "%s  ·  %s" % [welcome[4], welcome[5]], Vector3(0.0, 3.01, 0.108), 62, 0.0025, DesignKit.CHARCOAL)
	if style % 2 == 1:
		DesignKit.rbox(root, Vector3(2.72, 0.018, 0.024), Vector3(0.0, 2.93, 0.11), brass, 0.006, false)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel_scale: float, ink: Color = Color.WHITE) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixel_scale
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _cloth(tint: Color, key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = DesignKit.fabric(tint, "noren_" + key).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


static func _curtain_mesh(hems: bool) -> ArrayMesh:
	var key: String = "hem" if hems else "panel"
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if hems:
		_patch(surface, 0.0, 0.0, 0.016, 1.0)
		_patch(surface, 0.984, 0.0, 1.0, 1.0)
		_patch(surface, 0.016, 0.967, 0.984, 1.0)
	else:
		_patch(surface, 0.0, 0.0, 1.0, 1.0)
	surface.generate_normals()
	surface.generate_tangents()
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _patch(surface: SurfaceTool, u0: float, v0: float, u1: float, v1: float) -> void:
	for row: int in 12:
		for column: int in 40:
			var left: float = lerpf(u0, u1, float(column) / 40.0)
			var right: float = lerpf(u0, u1, float(column + 1) / 40.0)
			var top: float = lerpf(v0, v1, float(row) / 12.0)
			var bottom: float = lerpf(v0, v1, float(row + 1) / 12.0)
			var coords: Array[Vector2] = [Vector2(left, top), Vector2(left, bottom), Vector2(right, top), Vector2(right, top), Vector2(left, bottom), Vector2(right, bottom)]
			for uv: Vector2 in coords:
				surface.set_uv(uv)
				var fold: float = sin(uv.x * TAU * 3.0) * 0.025 * sin(uv.y * PI * 0.5)
				var hem_drop: float = 0.012 * sin(uv.x * PI * 3.0) * uv.y * uv.y
				surface.add_vertex(Vector3((uv.x - 0.5) * 1.29, -uv.y * 0.96 + hem_drop, fold))
