extends RefCounted
## Low airfield guidance cabinets. Operational identifiers stay language-neutral;
## the four operator finishes affect the housing, never the guidance face colours.

const KIT = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "RunwayGuidanceSigns"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var finishes: Array[Color] = [Color(0.94, 0.69, 0.12), KIT.CREAM, KIT.SAGE, KIT.CHARCOAL]
	var index: int = posmod(variant, 4)
	var shell: StandardMaterial3D = KIT.paint(finishes[index], 0.48)
	var trim: StandardMaterial3D = KIT.brass() if index == 3 else KIT.metal(Color(0.46, 0.45, 0.40), 0.46, 0.75, "runway_aluminium")
	var steel: StandardMaterial3D = KIT.metal()
	var yellow: StandardMaterial3D = KIT.washi(Color(1.0, 0.73, 0.08), 0.65, "runway_yellow")
	var red: StandardMaterial3D = KIT.washi(Color(0.76, 0.035, 0.025), 0.55, "runway_red")
	var black: StandardMaterial3D = KIT.paint(Color(0.025, 0.027, 0.023), 0.70)
	var amber: StandardMaterial3D = KIT.washi(Color(1.0, 0.54, 0.10), 1.8, "runway_amber")
	# Two independent frangible cabinets, with a little daylight between them.
	var taxi: Node3D = _cabinet(root, Vector3(-1.64, 0.0, 0.0), 3.30, shell, trim, steel, amber)
	KIT.rbox(taxi, Vector3(3.12, 0.78, 0.026), Vector3(0.0, 1.0, 0.176), yellow, 0.025, false)
	# Yellow border around a black location tile, yellow direction tile alongside.
	KIT.rbox(taxi, Vector3(1.13, 0.67, 0.015), Vector3(-0.93, 1.0, 0.198), black, 0.014, false)
	_label(taxi, "B2", Vector3(-0.93, 1.0, 0.212), Color(1.0, 0.76, 0.08), 0.50, 0.94)
	_label(taxi, "← B3", Vector3(0.61, 1.0, 0.207), Color(0.015, 0.018, 0.015), 0.50, 1.65)
	var runway: Node3D = _cabinet(root, Vector3(1.70, 0.0, -0.12), 2.90, shell, trim, steel, amber)
	KIT.rbox(runway, Vector3(2.72, 0.78, 0.026), Vector3(0.0, 1.0, 0.176), red, 0.025, false)
	_label(runway, "09-27", Vector3(0.0, 1.0, 0.207), KIT.CREAM, 0.54, 2.46)
	# Clay operator stripe on the warm-white finish, inset on the rear service doors.
	if index == 1:
		for cabinet: Node3D in [taxi, runway]:
			KIT.rbox(cabinet, Vector3(2.45, 0.065, 0.012), Vector3(0.0, 0.81, -0.177), KIT.paint(KIT.CLAY), 0.005, false)
	return root


static func _cabinet(parent: Node3D, at: Vector3, width: float, shell: Material, trim: Material, steel: Material, amber: Material) -> Node3D:
	var cabinet: Node3D = Node3D.new()
	cabinet.name = "FrangibleCabinet"
	cabinet.position = at
	parent.add_child(cabinet)
	KIT.rbox(cabinet, Vector3(width, 0.94, 0.34), Vector3(0.0, 1.0, 0.0), shell, 0.065)
	# Gasket and rolled face surround form a recessed, replaceable illuminated face.
	KIT.rbox(cabinet, Vector3(width - 0.07, 0.86, 0.040), Vector3(0.0, 1.0, 0.149), steel, 0.039, false)
	KIT.rbox(cabinet, Vector3(width - 0.12, 0.82, 0.030), Vector3(0.0, 1.0, 0.168), trim, 0.030, false)
	# Slightly projecting rounded rain lip, and a rear inset service door.
	KIT.rbox(cabinet, Vector3(width - 0.03, 0.045, 0.40), Vector3(0.0, 1.455, 0.014), trim, 0.018)
	KIT.rbox(cabinet, Vector3(width - 0.26, 0.71, 0.018), Vector3(0.0, 1.0, -0.171), steel, 0.025, false)
	KIT.rbox(cabinet, Vector3(width - 0.30, 0.67, 0.018), Vector3(0.0, 1.0, -0.185), shell, 0.022, false)
	KIT.rbox(cabinet, Vector3(0.085, 0.13, 0.023), Vector3(width * 0.5 - 0.29, 1.02, -0.206), trim, 0.015, false)
	var leg_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.04), Vector2(0.068, 0.04), Vector2(0.068, 0.10),
		Vector2(0.042, 0.12), Vector2(0.042, 0.18), Vector2(0.052, 0.20),
		Vector2(0.052, 0.58), Vector2(0.0, 0.58)
	])
	var collar_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.043, 0.0), Vector2(0.071, 0.0), Vector2(0.077, 0.012),
		Vector2(0.071, 0.044), Vector2(0.043, 0.044), Vector2(0.043, 0.0)
	])
	for x: float in [-width * 0.34, width * 0.34]:
		# Limestone mounting pads meet the ground; narrow necks mark breakaway joints.
		KIT.rbox(cabinet, Vector3(0.29, 0.045, 0.28), Vector3(x, 0.0225, 0.0), KIT.stone(), 0.018)
		KIT.add(cabinet, KIT.lathe(leg_profile, 16), trim, Vector3(x, 0.0, 0.0))
		KIT.add(cabinet, KIT.lathe(collar_profile, 16), steel, Vector3(x, 0.115, 0.0), Vector3.ZERO, false)
		KIT.rbox(cabinet, Vector3(0.22, 0.075, 0.26), Vector3(x, 0.55, 0.0), steel, 0.018)
		for dz: float in [-0.095, 0.095]:
			KIT.rbox(cabinet, Vector3(0.035, 0.019, 0.035), Vector3(x + 0.095, 0.054, dz), trim, 0.008, false)
	# Amber edge markers with dark sockets, kept below the upper edge of the sign.
	for x: float in [-width * 0.5 + 0.055, width * 0.5 - 0.055]:
		KIT.rbox(cabinet, Vector3(0.068, 0.15, 0.05), Vector3(x, 1.0, 0.177), steel, 0.022, false)
		KIT.rbox(cabinet, Vector3(0.037, 0.105, 0.025), Vector3(x, 1.0, 0.211), amber, 0.016, false)
	return cabinet


static func _label(parent: Node3D, caption: String, at: Vector3, ink: Color, height: float, max_width: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = SIGNS.font()
	label.font_size = 160
	var metrics: Vector2 = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size)
	label.pixel_size = minf(height / label.font.get_height(label.font_size), max_width / maxf(metrics.x, 1.0))
	label.position = at
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
