extends RefCounted
## Six-leaf byobu. The artwork is silent; multilingual lounge names are kept as metadata.
## All dimensions are metres, with the padded stile ends resting at y = 0.

static var _materials: Dictionary = {}

const PANEL_WIDTH: float = 0.70
const PANEL_PITCH: float = 0.712
const HEIGHT: float = 1.86


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "WoodScreen_Byobu"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	root.set_meta("zone_translations", Signage.translations("lounge").slice(0, 6))
	var style: int = posmod(variant, 4)
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK.lightened(float(style) * 0.025), "screen_oak_%d" % style)
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "screen_walnut")
	var brass: StandardMaterial3D = DesignKit.brass()
	var pads: StandardMaterial3D = DesignKit.fabric(DesignKit.CHARCOAL, "screen_felt")
	var angle: float = deg_to_rad(18.0 + float(style) * 2.0)
	var span: float = PANEL_PITCH * cos(angle) * 6.0
	var joint: Vector3 = Vector3(-span * 0.5, 0.0, 0.0)
	var leaves: Array[Node3D] = []
	for index in 6:
		var yaw: float = angle if index % 2 == 0 else -angle
		var direction: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))
		var leaf: Node3D = Node3D.new()
		leaf.name = "OakLeaf_%d" % (index + 1)
		leaf.position = joint + direction * PANEL_PITCH * 0.5
		leaf.rotation.y = yaw
		root.add_child(leaf)
		leaves.append(leaf)
		# Paper is recessed into the oak frame, with substantial solid wood below.
		DesignKit.rbox(leaf, Vector3(0.606, 1.60, 0.028), Vector3(0.0, 1.00, 0.0), _painted_washi(style, index), 0.010)
		for side: float in [-1.0, 1.0]:
			DesignKit.rbox(leaf, Vector3(0.047, HEIGHT - 0.025, 0.072), Vector3(side * 0.3265, (HEIGHT + 0.025) * 0.5, 0.0), oak, 0.012)
			DesignKit.rbox(leaf, Vector3(0.047, 0.025, 0.072), Vector3(side * 0.3265, 0.0125, 0.0), pads, 0.008, false)
		DesignKit.rbox(leaf, Vector3(0.620, 0.055, 0.072), Vector3(0.0, HEIGHT - 0.0275, 0.0), oak, 0.012)
		DesignKit.rbox(leaf, Vector3(0.620, 0.146, 0.058), Vector3(0.0, 0.107, 0.0), oak, 0.012)
		DesignKit.rbox(leaf, Vector3(0.614, 0.025, 0.063), Vector3(0.0, 0.181, 0.0), walnut, 0.006)
		# Slender glazing beads bind the paper on both sides, concealing cut edges.
		for face: float in [-1.0, 1.0]:
			DesignKit.rbox(leaf, Vector3(0.610, 0.012, 0.012), Vector3(0.0, 1.801, face * 0.020), walnut, 0.004, false)
		joint += direction * PANEL_PITCH
	# Fold axes alternate between front and back. Each knuckle has two rounded leaves.
	var pin: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -0.043), Vector2(0.009, -0.043),
		Vector2(0.013, -0.038), Vector2(0.013, 0.038),
		Vector2(0.009, 0.043), Vector2(0.0, 0.043)
	]), 12)
	for index in 5:
		var left: Node3D = leaves[index]
		var right: Node3D = leaves[index + 1]
		var face: float = 1.0 if index % 2 == 0 else -1.0
		var hinge_at: Vector3 = left.position + left.basis * Vector3(PANEL_PITCH * 0.5, 0.0, face * 0.042)
		for level: float in [0.48, 1.42]:
			DesignKit.add(root, pin, brass, hinge_at + Vector3(0.0, level, 0.0), Vector3.ZERO, false)
			DesignKit.rbox(left, Vector3(0.038, 0.066, 0.007), Vector3(0.324, level, face * 0.0395), brass, 0.003, false)
			DesignKit.rbox(right, Vector3(0.038, 0.066, 0.007), Vector3(-0.324, level, face * 0.0395), brass, 0.003, false)
	return root


static func _painted_washi(style: int, index: int) -> StandardMaterial3D:
	var key: String = "screen_paint_%d_%d" % [style, index]
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var palettes: Array[Color] = [DesignKit.SAGE, DesignKit.INDIGO, DesignKit.CLAY, DesignKit.WALNUT]
	var ink: Color = palettes[style]
	var paper: Color = DesignKit.CREAM.lerp(DesignKit.LINEN, 0.12)
	var image: Image = Image.create(192, 448, false, Image.FORMAT_RGB8)
	var phase: float = float(style) * 0.43
	var sun_x: float = 0.71 if style % 2 == 0 else 0.26
	for x in image.get_width():
		# Continue the painting over all six leaves, including their concealed margins.
		var u: float = (float(index) + float(x) / float(image.get_width() - 1)) / 6.0
		var far_ridge: float = 0.48 + 0.15 * sin(u * 14.0 + phase) + 0.052 * sin(u * 37.0 + 0.7)
		var mid_ridge: float = 0.32 + 0.10 * sin(u * 18.0 + phase + 2.0) + 0.025 * sin(u * 53.0)
		var near_ridge: float = 0.13 + 0.065 * sin(u * 11.0 + phase + 0.9) + 0.014 * sin(u * 42.0)
		for y in image.get_height():
			# rounded_box front UVs increase upward, so row zero is the painting's bottom.
			var h: float = float(y) / float(image.get_height() - 1)
			var color: Color = paper
			var sun_distance: float = Vector2((u - sun_x) * 4.20, (h - 0.77) * 1.60).length()
			var sun_alpha: float = 1.0 - smoothstep(0.128, 0.136, sun_distance)
			color = color.lerp(DesignKit.OCHRE.lerp(DesignKit.CLAY, float(style % 2) * 0.45), sun_alpha * 0.68)
			# Soft pigment edges and paler foothills suggest brushed ink and valley mist.
			var far_alpha: float = 1.0 - smoothstep(far_ridge - 0.004, far_ridge + 0.004, h)
			color = color.lerp(paper.lerp(ink, 0.32), far_alpha)
			var mid_alpha: float = 1.0 - smoothstep(mid_ridge - 0.003, mid_ridge + 0.003, h)
			color = color.lerp(paper.lerp(ink, 0.55), mid_alpha * (0.70 + h * 0.60))
			var near_alpha: float = 1.0 - smoothstep(near_ridge - 0.002, near_ridge + 0.002, h)
			color = color.lerp(ink, near_alpha * 0.78)
			var fiber: float = sin(float(x * 127 + y * 311 + index * 71)) * 0.014
			var strand: float = sin(float(y) * 0.31 + sin(float(x) * 0.09) * 2.0) * 0.006
			image.set_pixel(x, y, Color(color.r + fiber + strand, color.g + fiber + strand, color.b + fiber + strand))
	image.generate_mipmaps()
	var material: StandardMaterial3D = DesignKit.washi(paper, 0.045, "screen_paper").duplicate() as StandardMaterial3D
	material.albedo_color = Color.WHITE
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.roughness = 0.94
	_materials[key] = material
	return material
