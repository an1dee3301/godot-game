extends RefCounted
## Six full-depth suitcase lockers, with an integrated pay/key station. Front faces +Z.
## All geometry and materials are cached by DesignKit; no per-copy resources are made.


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "LuggageLockers"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.LINEN]
	var accent: Color = accents[style]
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "oak")
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var steel: StandardMaterial3D = DesignKit.metal()
	var brass: StandardMaterial3D = DesignKit.brass()
	var limestone: StandardMaterial3D = DesignKit.stone()
	var paper: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 0.65, "locker_header")

	# A recessed toe kick sits on a honed, radiused stone footing.
	DesignKit.rbox(root, Vector3(3.70, 0.12, 0.94), Vector3(0.0, 0.06, 0.0), limestone, 0.045)
	DesignKit.rbox(root, Vector3(3.42, 0.13, 0.70), Vector3(0.0, 0.185, -0.05), steel, 0.025)
	DesignKit.rbox(root, Vector3(3.52, 2.12, 0.80), Vector3(0.0, 1.30, 0.0), steel, 0.06)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.13, 2.20, 0.88), Vector3(side * 1.785, 1.30, 0.0), walnut, 0.045)
	DesignKit.rbox(root, Vector3(3.70, 0.10, 0.91), Vector3(0.0, 2.40, 0.0), walnut, 0.035)
	DesignKit.rbox(root, Vector3(3.52, 0.025, 0.025), Vector3(0.0, 2.34, 0.442), brass, 0.009, false)

	for row: int in 2:
		for column: int in 3:
			var x: float = -1.29 + float(column) * 0.82
			var y: float = 0.77 + float(row) * 1.04
			var number: int = style * 6 + row * 3 + column + 1
			_build_door(root, Vector3(x, y, 0.43), number, oak, brass, steel, accent, (column + row + style) % 3 == 0)

	# A standing-height terminal, clad in muted mineral paint with an oak service hatch.
	DesignKit.rbox(root, Vector3(0.70, 2.03, 0.10), Vector3(1.22, 1.30, 0.432), DesignKit.paint(accent), 0.045)
	DesignKit.rbox(root, Vector3(0.58, 0.41, 0.045), Vector3(1.22, 0.51, 0.497), oak, 0.025)
	DesignKit.rbox(root, Vector3(0.14, 0.024, 0.027), Vector3(1.22, 0.62, 0.53), brass, 0.008, false)
	DesignKit.rbox(root, Vector3(0.58, 0.64, 0.055), Vector3(1.22, 1.61, 0.503), steel, 0.045)
	DesignKit.rbox(root, Vector3(0.49, 0.52, 0.018), Vector3(1.22, 1.62, 0.541), DesignKit.washi(Color(0.72, 0.85, 0.79), 0.40, "locker_screen"), 0.028, false)
	_text(root, "PAY", Vector3(1.22, 1.77, 0.557), 0.16, DesignKit.CHARCOAL)
	_text(root, "01–06" if style == 0 else "%02d–%02d" % [style * 6 + 1, style * 6 + 6], Vector3(1.22, 1.56, 0.557), 0.12, DesignKit.CHARCOAL)
	DesignKit.rbox(root, Vector3(0.36, 0.10, 0.025), Vector3(1.22, 1.11, 0.504), brass, 0.02, false)
	DesignKit.rbox(root, Vector3(0.25, 0.018, 0.015), Vector3(1.22, 1.11, 0.524), steel, 0.007, false)
	DesignKit.rbox(root, Vector3(0.22, 0.16, 0.027), Vector3(1.22, 0.89, 0.511), steel, 0.025, false)
	# A raised card silhouette communicates contactless payment without tiny instructions.
	DesignKit.rbox(root, Vector3(0.13, 0.08, 0.012), Vector3(1.22, 0.89, 0.532), brass, 0.012, false)
	DesignKit.rbox(root, Vector3(0.09, 0.012, 0.008), Vector3(1.22, 0.905, 0.542), steel, 0.004, false)
	_text(root, "KEY / PAY", Vector3(1.22, 2.14, 0.493), 0.11, DesignKit.CHARCOAL)

	# A broad luminous fascia uses room-scale lettering rather than small door labels.
	DesignKit.rbox(root, Vector3(3.70, 1.04, 0.22), Vector3(0.0, 2.99, 0.28), walnut, 0.06)
	DesignKit.rbox(root, Vector3(3.54, 0.90, 0.035), Vector3(0.0, 2.99, 0.405), paper, 0.035, false)
	_text(root, "Luggage Lockers", Vector3(0.0, 3.25, 0.429), 0.24, DesignKit.CHARCOAL)
	_text(root, "手荷物ロッカー · 行李寄存柜", Vector3(0.0, 3.015, 0.429), 0.145, DesignKit.CHARCOAL)
	_text(root, "Tủ gửi hành lý", Vector3(0.0, 2.82, 0.429), 0.14, DesignKit.CHARCOAL)
	_text(root, "Consignes · Taquillas de equipaje", Vector3(0.0, 2.625, 0.429), 0.14, DesignKit.CHARCOAL)
	return root


static func _build_door(parent: Node3D, center: Vector3, number: int, oak: Material, brass: Material, steel: Material, accent: Color, occupied: bool) -> void:
	# Each oak leaf floats above the black carcass, leaving an honest perimeter reveal.
	DesignKit.rbox(parent, Vector3(0.78, 0.99, 0.075), center, oak, 0.025)
	DesignKit.rbox(parent, Vector3(0.47, 0.32, 0.024), center + Vector3(-0.025, 0.20, 0.049), brass, 0.024, false)
	_text(parent, "%02d" % number, center + Vector3(-0.025, 0.20, 0.065), 0.22, DesignKit.CHARCOAL)
	# Turned brass cylinder, a dark keyway, and a gently rounded vertical pull.
	var cylinder: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.032, 0.0), Vector2(0.036, 0.008),
		Vector2(0.036, 0.022), Vector2(0.030, 0.028), Vector2(0.0, 0.028)
	]), 16)
	DesignKit.add(parent, cylinder, brass, center + Vector3(0.24, -0.10, 0.04), Vector3(90.0, 0.0, 0.0), false)
	DesignKit.rbox(parent, Vector3(0.008, 0.028, 0.006), center + Vector3(0.24, -0.10, 0.071), steel, 0.003, false)
	for mount_y: float in [-0.30, -0.14]:
		DesignKit.rbox(parent, Vector3(0.04, 0.04, 0.045), center + Vector3(0.24, mount_y, 0.062), brass, 0.014, false)
	DesignKit.rbox(parent, Vector3(0.034, 0.22, 0.04), center + Vector3(0.24, -0.22, 0.10), brass, 0.016, false)
	for hinge_y: float in [-0.32, 0.32]:
		DesignKit.rbox(parent, Vector3(0.029, 0.10, 0.021), center + Vector3(-0.374, hinge_y, 0.045), brass, 0.01, false)
	var indicator: Material = DesignKit.paint(DesignKit.CLAY) if occupied else DesignKit.washi(accent.lightened(0.25), 0.55, "locker_status_%s" % accent.to_html())
	DesignKit.rbox(parent, Vector3(0.072, 0.02, 0.012), center + Vector3(0.24, 0.09, 0.047), indicator, 0.008, false)


static func _text(parent: Node3D, caption: String, at: Vector3, height: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 100
	label.pixel_size = height / 100.0
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	label.visibility_range_end = 65.0
	parent.add_child(label)
