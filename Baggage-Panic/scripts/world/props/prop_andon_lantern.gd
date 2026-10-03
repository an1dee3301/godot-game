extends RefCounted
## A floor-standing oak andon, with replaceable paper screens and a honed stone foot.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "AndonLantern"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "oak")
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var stone_tints: Array[Color] = [DesignKit.LIMESTONE, DesignKit.PLASTER, Color(0.72, 0.73, 0.66), Color(0.77, 0.70, 0.62)]
	var base_material: StandardMaterial3D = DesignKit.stone(stone_tints[style], 0.68, "andon_stone_%d" % style)
	var accent_tints: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var steel: StandardMaterial3D = DesignKit.metal()
	var paper: StandardMaterial3D = _paper_material(style)

	# The stone contacts the floor; a recessed steel shoe lifts the timber clear of cleaning water.
	DesignKit.rbox(root, Vector3(0.60, 0.14, 0.60), Vector3(0.0, 0.07, 0.0), base_material, 0.035)
	DesignKit.rbox(root, Vector3(0.46, 0.035, 0.46), Vector3(0.0, 0.1575, 0.0), steel, 0.012)
	DesignKit.rbox(root, Vector3(0.53, 0.065, 0.53), Vector3(0.0, 0.2075, 0.0), walnut, 0.018)
	DesignKit.rbox(root, Vector3(0.535, 0.012, 0.535), Vector3(0.0, 0.246, 0.0), DesignKit.paint(accent_tints[style]), 0.005)

	# Four continuous corner stiles enclose four separate inset paper screens.
	for x: float in [-0.225, 0.225]:
		for z: float in [-0.225, 0.225]:
			DesignKit.rbox(root, Vector3(0.055, 0.91, 0.055), Vector3(x, 0.705, z), oak, 0.009)
	for face: int in range(4):
		var angle: float = float(face) * PI * 0.5
		var normal: Vector3 = Vector3(sin(angle), 0.0, cos(angle))
		var rotation: Vector3 = Vector3(0.0, float(face) * 90.0, 0.0)
		DesignKit.add(root, DesignKit.rounded_box(Vector3(0.401, 0.792, 0.012), 0.004), paper, normal * 0.217 + Vector3.UP * 0.705, rotation, false)
		for rail_y: float in [0.285, 1.125]:
			DesignKit.add(root, DesignKit.rounded_box(Vector3(0.45, 0.05, 0.045), 0.008), oak, normal * 0.225 + Vector3.UP * rail_y, rotation)
		# Slim retaining battens leave a generous central field for the ink character.
		var batten_heights: Array[float] = [0.465, 0.945]
		if style % 2 == 1:
			batten_heights = [0.425, 0.985]
		for batten_y: float in batten_heights:
			DesignKit.add(root, DesignKit.rounded_box(Vector3(0.40, 0.016, 0.022), 0.005), oak, normal * 0.232 + Vector3.UP * batten_y, rotation)

	# Floating lid: the dark reveal reads as a ventilation slot, with an oak overhang above it.
	DesignKit.rbox(root, Vector3(0.46, 0.012, 0.46), Vector3(0.0, 1.164, 0.0), steel, 0.005)
	DesignKit.rbox(root, Vector3(0.56, 0.03, 0.56), Vector3(0.0, 1.185, 0.0), oak, 0.013)
	# Brass dowels at the front rail suggest pinned joinery, not exposed construction screws.
	var dowel_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.007, 0.0), Vector2(0.007, 0.003), Vector2(0.0, 0.003)
	]), 12)
	for x: float in [-0.165, 0.165]:
		for y: float in [0.285, 1.125]:
			DesignKit.add(root, dowel_mesh, DesignKit.brass(), Vector3(x, y, 0.249), Vector3(90.0, 0.0, 0.0), false)

	# A single large ink glyph ("light") is ornamental, rather than a miniature airport sign.
	var glyph: Label3D = Label3D.new()
	glyph.name = "InkLightCharacter"
	glyph.text = "灯"
	glyph.font = Signage.font()
	glyph.font_size = 128
	glyph.pixel_size = 0.0023
	glyph.position = Vector3(0.0, 0.705, 0.225)
	glyph.modulate = DesignKit.CHARCOAL
	glyph.outline_size = 0
	glyph.double_sided = false
	glyph.no_depth_test = false
	glyph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glyph)

	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "WarmFloorGlow"
	glow.position = Vector3(0.0, 0.71, 0.0)
	glow.light_color = Color(1.0, 0.79, 0.52)
	glow.light_energy = 0.55
	glow.omni_range = 1.8
	glow.shadow_enabled = false
	root.add_child(glow)
	return root


static func _paper_material(style: int) -> StandardMaterial3D:
	var key: String = "andon_paper_%d" % style
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var tints: Array[Color] = [Color(1.0, 0.88, 0.70), Color(1.0, 0.83, 0.63), Color(0.98, 0.91, 0.76), Color(1.0, 0.86, 0.67)]
	var material: StandardMaterial3D = DesignKit.washi(tints[style], 1.15, key).duplicate() as StandardMaterial3D
	var fibers: FastNoiseLite = FastNoiseLite.new()
	fibers.seed = 183 + style
	fibers.frequency = 0.13
	fibers.fractal_octaves = 3
	var texture: NoiseTexture2D = NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.noise = fibers
	texture.seamless = true
	texture.as_normal_map = true
	texture.bump_strength = 0.6
	material.normal_enabled = true
	material.normal_texture = texture
	material.normal_scale = 0.16
	_materials[key] = material
	return material
