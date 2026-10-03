extends RefCounted
## A quiet airport drinks cabinet: enamel, oak joinery and a luminous product window.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "JapandiDrinkVendingMachine"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.INDIGO, Kit.OCHRE]
	var accent: Color = accents[style]
	var enamel: StandardMaterial3D = Kit.paint(Kit.CREAM, 0.32)
	var dark: StandardMaterial3D = Kit.metal(Kit.CHARCOAL, 0.48, 0.55, "vending_dark")
	var oak: StandardMaterial3D = Kit.wood(Kit.WALNUT if style == 1 else Kit.OAK, "vending_walnut" if style == 1 else "vending_oak")
	var silver: StandardMaterial3D = Kit.metal(Color(0.67, 0.7, 0.68), 0.3, 0.95, "vending_aluminium")
	var glow: StandardMaterial3D = Kit.washi(Color(1.0, 0.92, 0.77), 1.2, "vending_backlight")
	# Recessed feet touch the floor; the curved enamel shell finishes at exactly 1.9 m.
	for x: float in [-0.44, 0.44]:
		for z: float in [-0.28, 0.28]:
			Kit.rbox(root, Vector3(0.11, 0.1, 0.11), Vector3(x, 0.05, z), dark, 0.025)
	Kit.rbox(root, Vector3(1.16, 1.82, 0.8), Vector3(0.0, 0.99, 0.0), enamel, 0.07)
	Kit.rbox(root, Vector3(1.05, 0.095, 0.72), Vector3(0.0, 0.13, 0.0), Kit.stone(), 0.025)
	# Dark gasket remains visible around the separate, hinged front door.
	Kit.rbox(root, Vector3(1.08, 1.68, 0.04), Vector3(0.0, 1.0, 0.404), dark, 0.045)
	Kit.rbox(root, Vector3(1.055, 1.655, 0.055), Vector3(0.0, 1.0, 0.431), enamel, 0.04)
	Kit.rbox(root, Vector3(0.038, 1.48, 0.065), Vector3(-0.505, 1.0, 0.467), oak, 0.016)
	Kit.rbox(root, Vector3(0.85, 0.19, 0.03), Vector3(-0.08, 1.72, 0.466), Kit.paint(accent), 0.026)
	_caption(root, "DRINKS", Vector3(-0.08, 1.753, 0.485), 0.13, 0.77, Kit.CREAM)
	_caption(root, "飲み物 · 饮料", Vector3(-0.08, 1.672, 0.485), 0.085, 0.77, Kit.CREAM)
	# The inset window has a thick oak reveal and a warm luminous back wall.
	Kit.rbox(root, Vector3(0.835, 0.925, 0.085), Vector3(-0.08, 1.16, 0.472), oak, 0.035)
	Kit.rbox(root, Vector3(0.773, 0.855, 0.018), Vector3(-0.08, 1.17, 0.518), glow, 0.022, false)
	var colors: Array[Color] = [Color(0.34, 0.63, 0.43), Color(0.92, 0.59, 0.23), Color(0.4, 0.68, 0.8), Color(0.79, 0.34, 0.3), Color(0.7, 0.55, 0.74)]
	var bottle: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.027, 0.0), Vector2(0.036, 0.012),
		Vector2(0.036, 0.125), Vector2(0.03, 0.145), Vector2(0.019, 0.16),
		Vector2(0.019, 0.19), Vector2(0.0, 0.19)]), 16)
	var can: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.029, 0.0), Vector2(0.035, 0.009),
		Vector2(0.035, 0.14), Vector2(0.03, 0.15), Vector2(0.0, 0.15)]), 16)
	var cap: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.021, 0.0), Vector2(0.021, 0.015), Vector2(0.0, 0.015)]), 12)
	for row: int in 3:
		var shelf_y: float = 0.786 + float(row) * 0.267
		Kit.rbox(root, Vector3(0.745, 0.022, 0.103), Vector3(-0.08, shelf_y, 0.558), silver, 0.007, false)
		Kit.rbox(root, Vector3(0.742, 0.032, 0.022), Vector3(-0.08, shelf_y - 0.018, 0.61), Kit.paint(accent), 0.008, false)
		for col: int in 5:
			var x: float = -0.37 + float(col) * 0.145
			var color: Color = colors[posmod(col + row + style, colors.size())]
			var drink_material: StandardMaterial3D = Kit.washi(color, 0.45, "vending_drink_" + color.to_html())
			var is_bottle: bool = posmod(col + row + style, 3) != 0
			var bottom: float = shelf_y + 0.013
			Kit.add(root, bottle if is_bottle else can, drink_material, Vector3(x, bottom, 0.566), Vector3.ZERO, false)
			# A broad cream sleeve reads as packaging without miniature illegible text.
			Kit.rbox(root, Vector3(0.055, 0.053, 0.008), Vector3(x, bottom + 0.084, 0.602), Kit.paint(Kit.CREAM), 0.009, false)
			if is_bottle:
				Kit.add(root, cap, silver, Vector3(x, bottom + 0.186, 0.566), Vector3.ZERO, false)
			else:
				Kit.rbox(root, Vector3(0.045, 0.007, 0.045), Vector3(x, bottom + 0.151, 0.566), silver, 0.003, false)
			Kit.rbox(root, Vector3(0.079, 0.025, 0.016), Vector3(x, shelf_y - 0.018, 0.629), Kit.washi(Kit.SAGE, 0.8, "vending_select"), 0.011, false)
	# Clear front cover leaves the physical bottle silhouettes visible.
	Kit.rbox(root, Vector3(0.768, 0.85, 0.009), Vector3(-0.08, 1.17, 0.647), _glass(), 0.015, false)
	Kit.rbox(root, Vector3(0.014, 0.79, 0.009), Vector3(-0.445, 1.17, 0.654), glow, 0.004, false)
	# Tall payment escutcheon: luminous status screen, coin throat, return and tap pad.
	Kit.rbox(root, Vector3(0.17, 0.72, 0.036), Vector3(0.435, 1.18, 0.482), dark, 0.026)
	Kit.rbox(root, Vector3(0.136, 0.12, 0.014), Vector3(0.435, 1.443, 0.509), Kit.washi(accent.lightened(0.2), 0.8, "vending_screen_%d" % style), 0.016, false)
	Kit.rbox(root, Vector3(0.062, 0.115, 0.021), Vector3(0.435, 1.253, 0.513), Kit.brass(), 0.018, false)
	Kit.rbox(root, Vector3(0.008, 0.077, 0.005), Vector3(0.435, 1.253, 0.526), dark, 0.003, false)
	Kit.rbox(root, Vector3(0.048, 0.023, 0.028), Vector3(0.435, 1.151, 0.518), silver, 0.01, false)
	Kit.rbox(root, Vector3(0.108, 0.12, 0.023), Vector3(0.435, 1.003, 0.514), Kit.paint(accent), 0.022, false)
	# Contactless symbol uses three concentric turned hoops, facing the customer.
	for ring: int in 3:
		var radius: float = 0.012 + float(ring) * 0.009
		var hoop: ArrayMesh = Kit.lathe(PackedVector2Array([
			Vector2(radius - 0.002, 0.0), Vector2(radius, 0.0), Vector2(radius, 0.003),
			Vector2(radius - 0.002, 0.003), Vector2(radius - 0.002, 0.0)]), 20)
		Kit.add(root, hoop, Kit.brass(), Vector3(0.435, 1.003, 0.528), Vector3(90.0, 0.0, 0.0), false)
	# Pickup bay: black recess, sloping flap, brushed sill and a generous oak surround.
	Kit.rbox(root, Vector3(0.82, 0.275, 0.055), Vector3(-0.08, 0.459, 0.482), oak, 0.034)
	Kit.rbox(root, Vector3(0.745, 0.205, 0.016), Vector3(-0.08, 0.462, 0.515), dark, 0.029)
	Kit.add(root, Kit.rounded_box(Vector3(0.685, 0.1, 0.018), 0.009), silver, Vector3(-0.08, 0.502, 0.534), Vector3(-16.0, 0.0, 0.0), false)
	Kit.rbox(root, Vector3(0.715, 0.029, 0.095), Vector3(-0.08, 0.362, 0.535), silver, 0.012, false)
	Kit.rbox(root, Vector3(0.31, 0.022, 0.017), Vector3(-0.08, 0.469, 0.548), Kit.brass(), 0.007, false)
	# Quiet service detail along the lower face, with no tiny printed labels.
	for vent: int in 5:
		Kit.rbox(root, Vector3(0.58, 0.008, 0.007), Vector3(-0.08, 0.235 + float(vent) * 0.016, 0.463), dark, 0.003, false)
	Kit.rbox(root, Vector3(0.025, 0.16, 0.035), Vector3(0.506, 0.61, 0.479), Kit.brass(), 0.012, false)
	# Full-size translations on the side keep the international identity legible.
	var side: Node3D = Node3D.new()
	side.name = "InternationalSideSign"
	side.position = Vector3(0.582, 1.25, 0.0)
	side.rotation_degrees.y = 90.0
	root.add_child(side)
	Kit.rbox(side, Vector3(0.67, 0.66, 0.014), Vector3.ZERO, oak, 0.035)
	_caption(side, "Đồ uống", Vector3(0.0, 0.19, 0.012), 0.115, 0.59, Kit.CHARCOAL)
	_caption(side, "Boissons", Vector3(0.0, 0.0, 0.012), 0.115, 0.59, Kit.CHARCOAL)
	_caption(side, "Bebidas", Vector3(0.0, -0.19, 0.012), 0.115, 0.59, Kit.CHARCOAL)
	return root


static func _caption(parent: Node3D, text: String, at: Vector3, height: float, width: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font = Signs.font()
	label.font_size = 96
	var measured: float = label.font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 96).x
	label.pixel_size = minf(height / 96.0, width / maxf(measured, 1.0))
	label.position = at
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _glass() -> StandardMaterial3D:
	if _materials.has("glass"):
		var cached: StandardMaterial3D = _materials["glass"]
		return cached
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.82, 0.94, 0.94, 0.09)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.16
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials["glass"] = material
	return material
