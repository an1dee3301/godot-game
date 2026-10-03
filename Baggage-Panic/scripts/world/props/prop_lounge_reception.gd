extends RefCounted
## Floor-standing lounge reception; the guest approach is +Z.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "LoungeReception"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.INDIGO, Kit.LINEN]
	var stones: Array[Color] = [Kit.LIMESTONE, Color(0.83, 0.77, 0.65), Color(0.79, 0.81, 0.75), Kit.PLASTER]
	var accent: Color = accents[choice]
	var stone_tint: Color = stones[choice]
	var walnut: StandardMaterial3D = Kit.wood(Kit.WALNUT.lightened(float(choice) * 0.025), "lounge_walnut_%d" % choice)
	var stone: StandardMaterial3D = Kit.stone(stone_tint, 0.42, "lounge_counter_%d" % choice)
	var brass: StandardMaterial3D = Kit.brass()
	var steel: StandardMaterial3D = Kit.metal()
	var glow: StandardMaterial3D = Kit.washi(Kit.CREAM, 1.4, "lounge_halo")

	# Floating, softly luminous stone panels inside a substantial walnut portal.
	Kit.rbox(root, Vector3(6.8, 3.95, 0.28), Vector3(0.0, 1.975, -1.42), walnut, 0.12)
	Kit.rbox(root, Vector3(6.44, 3.62, 0.08), Vector3(0.0, 2.02, -1.245), glow, 0.08, false)
	var illuminated_stone: StandardMaterial3D = _backlit_stone(choice, stone_tint)
	for i in 3:
		var x: float = (float(i) - 1.0) * 2.09
		Kit.rbox(root, Vector3(2.065, 3.46, 0.10), Vector3(x, 2.02, -1.17), illuminated_stone, 0.045)
		if i < 2:
			Kit.rbox(root, Vector3(0.012, 3.34, 0.016), Vector3(x + 1.045, 2.02, -1.11), brass, 0.004, false)
	Kit.rbox(root, Vector3(6.4, 0.16, 0.34), Vector3(0.0, 0.08, -1.38), steel, 0.04)

	# A framed sign sits proud of the stone so its lettering has a clear silhouette.
	Kit.rbox(root, Vector3(4.95, 1.98, 0.10), Vector3(0.0, 2.65, -1.035), brass, 0.085)
	Kit.rbox(root, Vector3(4.90, 1.93, 0.10), Vector3(0.0, 2.65, -0.974), Kit.paint(Kit.CHARCOAL), 0.075)
	var text: Array = Signs.TEXT["lounge"]
	_label(root, str(text[0]).to_upper(), Vector3(0.0, 3.19, -0.912), 0.0072, Kit.CREAM)
	_label(root, "%s    %s" % [text[1], text[2]], Vector3(0.0, 2.69, -0.912), 0.0045, Kit.CREAM)
	_label(root, str(text[3]), Vector3(0.0, 2.30, -0.912), 0.0038, Kit.CREAM)
	_label(root, "%s  ·  %s" % [text[4], text[5]], Vector3(0.0, 1.97, -0.912), 0.0038, Kit.CREAM)

	# Full-height counter and a lower, open-knee guest ledge at the left.
	Kit.rbox(root, Vector3(3.72, 0.12, 0.84), Vector3(0.56, 0.06, 0.58), steel, 0.055)
	Kit.rbox(root, Vector3(3.86, 0.86, 0.94), Vector3(0.56, 0.55, 0.58), walnut, 0.13)
	Kit.rbox(root, Vector3(3.92, 0.025, 1.02), Vector3(0.56, 0.993, 0.58), brass, 0.011, false)
	Kit.rbox(root, Vector3(4.04, 0.105, 1.12), Vector3(0.56, 1.055, 0.58), stone, 0.05)
	# Individual walnut leaves, separated by deep shadow seams.
	for i in 7:
		var x: float = -0.93 + float(i) * 0.495
		Kit.rbox(root, Vector3(0.477, 0.67, 0.024), Vector3(x, 0.58, 1.056), walnut, 0.01, false)
	Kit.rbox(root, Vector3(3.37, 0.018, 0.012), Vector3(0.56, 0.36, 1.073), brass, 0.005, false)
	var inlay_x: float = 1.35 if choice % 2 == 0 else -0.30
	Kit.rbox(root, Vector3(0.016, 0.55, 0.013), Vector3(inlay_x, 0.64, 1.074), brass, 0.005, false)
	Kit.rbox(root, Vector3(0.016, 0.55, 0.013), Vector3(inlay_x + 0.065, 0.64, 1.074), brass, 0.005, false)
	Kit.rbox(root, Vector3(0.16, 0.72, 0.78), Vector3(-2.48, 0.36, 0.61), walnut, 0.055)
	Kit.rbox(root, Vector3(1.34, 0.022, 0.94), Vector3(-1.98, 0.721, 0.66), brass, 0.01, false)
	Kit.rbox(root, Vector3(1.42, 0.09, 1.02), Vector3(-1.98, 0.777, 0.66), stone, 0.042)
	Kit.rbox(root, Vector3(0.74, 0.012, 0.40), Vector3(-1.98, 0.828, 0.68), Kit.fabric(accent, "lounge_guest_mat_%d" % choice), 0.005, false)

	# Two staff displays: guests see the tailored backs rather than tiny UI text.
	for x: float in [-0.35, 1.37]:
		Kit.rbox(root, Vector3(0.31, 0.025, 0.21), Vector3(x, 1.12, 0.30), steel, 0.012)
		Kit.rbox(root, Vector3(0.04, 0.22, 0.04), Vector3(x, 1.23, 0.27), brass, 0.013)
		var screen: MeshInstance3D = Kit.rbox(root, Vector3(0.52, 0.32, 0.045), Vector3(x, 1.43, 0.27), steel, 0.025)
		screen.rotation_degrees.x = -12.0
		var display: MeshInstance3D = Kit.rbox(root, Vector3(0.47, 0.27, 0.008), Vector3(x, 1.431, 0.243), Kit.washi(Color(0.30, 0.42, 0.40), 0.35, "lounge_display"), 0.015, false)
		display.rotation_degrees.x = -12.0
		Kit.rbox(root, Vector3(0.16, 0.014, 0.008), Vector3(x, 1.40, 0.297), brass, 0.004, false)

	# A turned ceramic vase and quiet paper sconces finish the reception.
	var vase_x: float = -1.05 if choice < 2 else 2.10
	var vase_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.10, 0.0), Vector2(0.13, 0.025),
		Vector2(0.145, 0.17), Vector2(0.09, 0.32), Vector2(0.055, 0.38),
		Vector2(0.043, 0.38), Vector2(0.04, 0.31), Vector2(0.0, 0.30)])
	Kit.add(root, Kit.lathe(vase_profile), Kit.stone(accent, 0.68, "lounge_ceramic_%d" % choice), Vector3(vase_x, 1.11, 0.70))
	for i in 3:
		var stem: MeshInstance3D = Kit.rbox(root, Vector3(0.008, 0.43 + float(i) * 0.07, 0.008), Vector3(vase_x + float(i - 1) * 0.045, 1.64, 0.70), walnut, 0.003, false)
		stem.rotation_degrees.z = float(i - 1) * 16.0
	var lamp_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.16, 0.0), Vector2(0.20, 0.055),
		Vector2(0.20, 0.53), Vector2(0.16, 0.585), Vector2(0.0, 0.585)])
	for x: float in [-2.88, 2.88]:
		Kit.rbox(root, Vector3(0.10, 0.75, 0.06), Vector3(x, 2.64, -1.045), brass, 0.025)
		Kit.add(root, Kit.lathe(lamp_profile), Kit.washi(Kit.CREAM, 1.1, "lounge_sconces"), Vector3(x, 2.35, -0.87), Vector3.ZERO, false)
		for y: float in [2.35, 2.935]:
			Kit.rbox(root, Vector3(0.34, 0.025, 0.30), Vector3(x, y, -0.87), brass, 0.012, false)
	return root


static func _backlit_stone(choice: int, tint: Color) -> StandardMaterial3D:
	var key: String = "wall_%d" % choice
	if not _materials.has(key):
		var material: StandardMaterial3D = Kit.stone(tint, 0.58, "lounge_wall_%d" % choice).duplicate() as StandardMaterial3D
		material.emission_enabled = true
		material.emission = tint
		material.emission_energy_multiplier = 0.32
		_materials[key] = material
	return _materials[key] as StandardMaterial3D


static func _label(parent: Node3D, caption: String, at: Vector3, pixel_scale: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signs.font()
	label.font_size = 72
	label.pixel_size = pixel_scale
	label.position = at
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
