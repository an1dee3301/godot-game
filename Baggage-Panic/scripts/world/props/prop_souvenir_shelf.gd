extends RefCounted
## A small airport gift wall: oak joinery, tactile wrapping and turned keepsakes.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "SouvenirShelf"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var colours: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = colours[style]
	var companion: Color = colours[(style + 2) % 4]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var brass: StandardMaterial3D = DesignKit.brass()
	var cream: StandardMaterial3D = DesignKit.paint(DesignKit.CREAM)
	var ink: StandardMaterial3D = DesignKit.paint(DesignKit.CHARCOAL)
	var glow: StandardMaterial3D = DesignKit.washi(Color(1.0, 0.83, 0.59), 1.6, "souvenir_shelf_light")
	# Recessed toe space and a honed stone plinth; all contact geometry starts at y=0.
	DesignKit.rbox(root, Vector3(3.26, 0.12, 0.52), Vector3(0.0, 0.06, -0.035), walnut, 0.025)
	DesignKit.rbox(root, Vector3(3.6, 0.14, 0.72), Vector3(0.0, 0.19, 0.0), DesignKit.stone(), 0.045)
	DesignKit.rbox(root, Vector3(3.42, 2.41, 0.065), Vector3(0.0, 1.465, -0.305), DesignKit.fabric(DesignKit.LINEN, "linen"), 0.025)
	for x: float in [-1.73, 1.73]:
		DesignKit.rbox(root, Vector3(0.14, 2.54, 0.64), Vector3(x, 1.53, 0.0), oak, 0.05)
		DesignKit.rbox(root, Vector3(0.022, 2.38, 0.025), Vector3(x, 1.51, 0.322), walnut, 0.009, false)
	# Each shelf has a thick softened nosing and a concealed warm diffuser.
	for level: int in 4:
		var y: float = 0.34 + float(level) * 0.49
		DesignKit.rbox(root, Vector3(3.36, 0.075, 0.61), Vector3(0.0, y, 0.01), oak, 0.025)
		DesignKit.rbox(root, Vector3(3.26, 0.018, 0.018), Vector3(0.0, y + 0.016, 0.32), brass, 0.006, false)
		if level > 0:
			DesignKit.rbox(root, Vector3(3.14, 0.018, 0.035), Vector3(0.0, y - 0.048, 0.22), glow, 0.007, false)
	DesignKit.rbox(root, Vector3(3.6, 0.1, 0.68), Vector3(0.0, 2.79, 0.0), oak, 0.035)
	DesignKit.rbox(root, Vector3(3.16, 0.02, 0.035), Vector3(0.0, 2.265, 0.23), glow, 0.007, false)
	# A calm washi header: the text is shop-scale, never miniature product labelling.
	DesignKit.rbox(root, Vector3(3.32, 0.68, 0.09), Vector3(0.0, 2.47, 0.225), walnut, 0.035)
	DesignKit.rbox(root, Vector3(3.2, 0.57, 0.015), Vector3(0.0, 2.47, 0.277), DesignKit.washi(DesignKit.CREAM, 0.25, "souvenir_header"), 0.018, false)
	_caption(root, "SOUVENIRS", Vector3(0.0, 2.64, 0.291), 88, 0.0032)
	_caption(root, "お土産  ·  纪念品", Vector3(0.0, 2.44, 0.291), 58, 0.0032)
	_caption(root, "Quà lưu niệm · Souvenirs · Recuerdos", Vector3(0.0, 2.255, 0.291), 42, 0.0032)
	# Boxed sweets with telescoping lids and contrasting paper belly bands.
	for i: int in 5:
		var x: float = -1.25 + float(i) * 0.625
		var paper: StandardMaterial3D = DesignKit.paint(accent if i % 2 == 0 else DesignKit.CREAM)
		for stack: int in 2:
			var y: float = 0.3775 + float(stack) * 0.145
			DesignKit.rbox(root, Vector3(0.51, 0.11, 0.37), Vector3(x, y + 0.055, 0.045), paper, 0.018)
			DesignKit.rbox(root, Vector3(0.53, 0.036, 0.39), Vector3(x, y + 0.118, 0.045), cream, 0.012)
			DesignKit.rbox(root, Vector3(0.095, 0.133, 0.397), Vector3(x + 0.075, y + 0.068, 0.045), DesignKit.fabric(companion, "souvenir_band_%d" % style), 0.008, false)
	# Folded furoshiki: exposed layered hems and a diagonal folded corner on top.
	for pile: int in 3:
		var x: float = -1.1 + float(pile) * 1.1
		for fold: int in 3:
			var tint: Color = accent if (fold + pile) % 2 == 0 else companion
			var cloth: StandardMaterial3D = DesignKit.fabric(tint, "souvenir_cloth_%d_%d" % [style, (fold + pile) % 2])
			var y: float = 0.8675 + float(fold) * 0.057
			DesignKit.rbox(root, Vector3(0.67, 0.052, 0.4), Vector3(x + float(fold) * 0.014, y + 0.026, 0.035), cloth, 0.019)
			DesignKit.rbox(root, Vector3(0.6, 0.009, 0.012), Vector3(x + float(fold) * 0.014, y + 0.013, 0.236), DesignKit.fabric(DesignKit.LINEN, "linen"), 0.003, false)
		var corner: MeshInstance3D = DesignKit.rbox(root, Vector3(0.23, 0.012, 0.16), Vector3(x + 0.16, 1.048, 0.09), DesignKit.fabric(companion, "souvenir_band_%d" % style), 0.005, false)
		corner.rotation_degrees.y = -26.0
	# Tea tins: rolled metal seams, paper sleeves and slightly overhanging lids.
	var tin_profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.104, 0.0), Vector2(0.116, 0.014), Vector2(0.116, 0.29), Vector2(0.107, 0.3), Vector2(0.0, 0.3)])
	var sleeve_profile: PackedVector2Array = PackedVector2Array([Vector2(0.118, 0.048), Vector2(0.118, 0.245)])
	var lid_profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.124, 0.0), Vector2(0.124, 0.024), Vector2(0.113, 0.035), Vector2(0.0, 0.035)])
	for i: int in 7:
		var x: float = -1.32 + float(i) * 0.44
		var y: float = 1.3575
		DesignKit.add(root, DesignKit.lathe(tin_profile), brass, Vector3(x, y, 0.065))
		DesignKit.add(root, DesignKit.lathe(sleeve_profile), DesignKit.paint(accent if i % 2 == 0 else companion), Vector3(x, y, 0.065), Vector3.ZERO, false)
		DesignKit.add(root, DesignKit.lathe(lid_profile), DesignKit.metal(DesignKit.CHARCOAL, 0.42, 0.7, "souvenir_tin_lid"), Vector3(x, y + 0.294, 0.065))
	# Three small, unmistakable daruma with squat turned bodies and sculpted faces.
	for i: int in 3:
		_daruma(root, Vector3(-1.05 + float(i) * 1.05, 1.8475, 0.055), accent if style == 2 else DesignKit.CLAY, cream, ink, brass, (i + style) % 2 == 0)
	# One local light washes the merchandise; diffusers provide the shelf-edge glow.
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "WarmShelfWash"
	light.position = Vector3(0.0, 1.55, 0.38)
	light.light_color = Color(1.0, 0.8, 0.56)
	light.light_energy = 0.65
	light.omni_range = 2.15
	light.shadow_enabled = false
	root.add_child(light)
	return root


static func _caption(parent: Node3D, text: String, at: Vector3, font_size: int, pixel_size: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font = Signage.font()
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _orb(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	if not _meshes.has("orb"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 20
		sphere.rings = 12
		_meshes["orb"] = sphere
	var mesh: Mesh = _meshes["orb"]
	var part: MeshInstance3D = DesignKit.add(parent, mesh, material, at, Vector3.ZERO, false)
	part.scale = size


static func _daruma(parent: Node3D, at: Vector3, colour: Color, cream: Material, ink: Material, brass: Material, wish_filled: bool) -> void:
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.115, 0.0), Vector2(0.177, 0.04), Vector2(0.206, 0.13), Vector2(0.196, 0.24), Vector2(0.154, 0.32), Vector2(0.085, 0.367), Vector2(0.0, 0.38)])
	DesignKit.add(parent, DesignKit.lathe(profile, 28), DesignKit.paint(colour, 0.3), at)
	_orb(parent, at + Vector3(0.0, 0.239, 0.164), Vector3(0.283, 0.207, 0.085), cream)
	for side: float in [-1.0, 1.0]:
		_orb(parent, at + Vector3(side * 0.058, 0.252, 0.205), Vector3(0.047, 0.048, 0.018), cream)
		if side < 0.0 or wish_filled:
			_orb(parent, at + Vector3(side * 0.058, 0.252, 0.216), Vector3(0.024, 0.026, 0.012), ink)
		var brow: MeshInstance3D = DesignKit.rbox(parent, Vector3(0.073, 0.015, 0.013), at + Vector3(side * 0.058, 0.286, 0.205), ink, 0.006, false)
		brow.rotation_degrees.z = side * -15.0
		var moustache: MeshInstance3D = DesignKit.rbox(parent, Vector3(0.046, 0.01, 0.013), at + Vector3(side * 0.028, 0.194, 0.208), ink, 0.004, false)
		moustache.rotation_degrees.z = side * 22.0
	_orb(parent, at + Vector3(0.0, 0.172, 0.208), Vector3(0.036, 0.018, 0.012), ink)
	for stripe: int in 3:
		var x: float = float(stripe - 1) * 0.059
		DesignKit.rbox(parent, Vector3(0.015, 0.073, 0.012), at + Vector3(x, 0.085, 0.185), brass, 0.005, false)
