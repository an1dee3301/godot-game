extends RefCounted
## A floor-standing tōrō: honed stone, recessed washi windows and a lotus finial.
## No lettering: the small architectural ornament needs no wayfinding panel.

const Kit = preload("res://scripts/world/design_kit.gd")


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "StoneLantern"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var tones: Array[Color] = [Kit.LIMESTONE, Color(0.70, 0.69, 0.62), Color(0.79, 0.73, 0.65), Color(0.59, 0.62, 0.57)]
	var tint: Color = tones[style]
	var stone: StandardMaterial3D = Kit.stone(tint, 0.78, "toro_stone_%d" % style)
	var recess: StandardMaterial3D = Kit.stone(tint.darkened(0.22), 0.86, "toro_recess_%d" % style)
	var timber: StandardMaterial3D = Kit.wood(Kit.WALNUT if style % 2 == 0 else Kit.OAK, "toro_lattice_%d" % (style % 2))
	var glow: StandardMaterial3D = Kit.washi(Color(1.0, 0.83 + float(style) * 0.025, 0.60 + float(style) * 0.035), 2.2, "toro_glow_%d" % style)
	# Low octagonal footing with a chamfer, resting exactly on the floor.
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.27, 0.0), Vector2(0.30, 0.025),
		Vector2(0.30, 0.10), Vector2(0.27, 0.14), Vector2(0.0, 0.14)
	]), 8), stone, Vector3.ZERO, Vector3(0.0, 22.5, 0.0))
	# Turned lotus foot, slender tapered shaft and softly flared capital.
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.14), Vector2(0.205, 0.14), Vector2(0.215, 0.17),
		Vector2(0.195, 0.20), Vector2(0.13, 0.25), Vector2(0.102, 0.29),
		Vector2(0.092, 0.65), Vector2(0.105, 0.70), Vector2(0.15, 0.74),
		Vector2(0.21, 0.765), Vector2(0.23, 0.80), Vector2(0.225, 0.835),
		Vector2(0.0, 0.835)
	]), 48), stone, Vector3.ZERO)
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.103, 0.285), Vector2(0.106, 0.285),
		Vector2(0.105, 0.303), Vector2(0.102, 0.303)
	]), 48), recess, Vector3.ZERO)
	Kit.rbox(root, Vector3(0.45, 0.075, 0.45), Vector3(0.0, 0.845, 0.0), stone, 0.025)
	Kit.rbox(root, Vector3(0.36, 0.016, 0.36), Vector3(0.0, 0.886, 0.0), recess, 0.007)
	# Four solid stone piers leave real openings around the luminous chamber.
	for x: float in [-0.175, 0.175]:
		for z: float in [-0.175, 0.175]:
			Kit.rbox(root, Vector3(0.075, 0.30, 0.075), Vector3(x, 1.025, z), stone, 0.018)
	# Each face receives an inset, warm paper window and a crafted timber grille.
	# Frames are placed directly under the root to keep the hierarchy modest.
	for side: int in 4:
		var angle: float = float(side) * PI * 0.5
		var basis: Basis = Basis(Vector3.UP, angle)
		var rotation: Vector3 = Vector3(0.0, float(side) * 90.0, 0.0)
		Kit.add(root, Kit.rounded_box(Vector3(0.264, 0.253, 0.018), 0.007), glow, basis * Vector3(0.0, 1.024, 0.159), rotation, false)
		for y: float in [0.897, 1.151]:
			Kit.add(root, Kit.rounded_box(Vector3(0.28, 0.018, 0.022), 0.005), timber, basis * Vector3(0.0, y, 0.181), rotation, false)
		var bars: int = 1 if style < 2 else 2
		for bar: int in bars:
			var offset: float = 0.0 if bars == 1 else (float(bar) - 0.5) * 0.094
			Kit.add(root, Kit.rounded_box(Vector3(0.014, 0.246, 0.022), 0.004), timber, basis * Vector3(offset, 1.024, 0.181), rotation, false)
		if style % 2 == 1:
			Kit.add(root, Kit.rounded_box(Vector3(0.264, 0.013, 0.022), 0.004), timber, basis * Vector3(0.0, 1.024, 0.185), rotation, false)
	Kit.rbox(root, Vector3(0.45, 0.065, 0.45), Vector3(0.0, 1.185, 0.0), stone, 0.021)
	# Broad kasa roof: rounded eave rolls into a gently concave stone slope.
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 1.213), Vector2(0.29, 1.213), Vector2(0.365, 1.226),
		Vector2(0.39, 1.247), Vector2(0.391, 1.262), Vector2(0.37, 1.280),
		Vector2(0.315, 1.287), Vector2(0.26, 1.310), Vector2(0.205, 1.350),
		Vector2(0.155, 1.395), Vector2(0.115, 1.428), Vector2(0.0, 1.428)
	]), 48), stone, Vector3.ZERO)
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 1.421), Vector2(0.097, 1.421), Vector2(0.102, 1.442),
		Vector2(0.085, 1.463), Vector2(0.048, 1.478), Vector2(0.061, 1.506),
		Vector2(0.059, 1.536), Vector2(0.039, 1.565), Vector2(0.0, 1.60)
	]), 32), stone, Vector3.ZERO)
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "WarmWindowGlow"
	light.position = Vector3(0.0, 1.025, 0.0)
	light.light_color = Color(1.0, 0.79, 0.52)
	light.light_energy = 0.65
	light.omni_range = 1.7
	light.omni_attenuation = 2.0
	light.shadow_enabled = false
	root.add_child(light)
	return root
