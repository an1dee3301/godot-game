extends RefCounted
## Five floor-standing lantern cubes: oak joinery, washi faces and destination posters.

const KIT = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "DestinationCubes"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var names: Array[String] = ["TOKYO", "HÀ NỘI", "SHANG\nHAI", "PARIS", "MADRID"]
	var native_names: Array[String] = ["東京", "HANOI", "上海", "PARIS", "MADRID"]
	var colors: Array[Color] = [KIT.CLAY, KIT.SAGE, KIT.INDIGO, KIT.SAGE, KIT.CLAY]
	var oak: StandardMaterial3D = KIT.wood()
	var steel: StandardMaterial3D = KIT.metal()
	var stone: StandardMaterial3D = KIT.stone()
	var paper: StandardMaterial3D = KIT.washi(KIT.CREAM, 0.65, "destination_cube_paper")
	for i in 5:
		var cube: Node3D = Node3D.new()
		cube.name = "Destination_%d" % i
		# A shallow crescent keeps every name visible from the front.
		var offset: float = float(i - 2)
		cube.position = Vector3(offset * 1.23, 0.0, -absf(offset) * 0.16)
		if posmod(variant, 2) == 1:
			cube.position.z = -float(i % 2) * 0.24
		root.add_child(cube)
		KIT.rbox(cube, Vector3(0.84, 0.04, 0.84), Vector3(0.0, 0.02, 0.0), steel, 0.015)
		KIT.rbox(cube, Vector3(1.0, 0.16, 1.0), Vector3(0.0, 0.12, 0.0), stone, 0.045)
		KIT.rbox(cube, Vector3(1.0, 2.2, 0.98), Vector3(0.0, 1.3, 0.0), oak, 0.065)
		# Recessed paper, backed by a dark gasket, leaves a generous oak frame.
		KIT.rbox(cube, Vector3(0.9, 2.06, 0.022), Vector3(0.0, 1.3, 0.482), steel, 0.045, false)
		KIT.rbox(cube, Vector3(0.85, 2.01, 0.012), Vector3(0.0, 1.3, 0.494), paper, 0.04, false)
		# The side light is a real inset; its walnut seam reads as crafted joinery.
		KIT.rbox(cube, Vector3(0.012, 1.94, 0.74), Vector3(0.495, 1.3, 0.0), paper, 0.005, false)
		KIT.rbox(cube, Vector3(0.016, 1.94, 0.024), Vector3(0.492, 1.3, -0.34), KIT.wood(KIT.WALNUT, "walnut"), 0.006, false)
		KIT.rbox(cube, Vector3(0.76, 0.018, 0.014), Vector3(0.0, 2.28, 0.494), KIT.brass(), 0.006, false)
		var art: MeshInstance3D = KIT.add(cube, _art_mesh(), _poster(i, colors[i]), Vector3(0.0, 0.82, 0.502), Vector3.ZERO, false)
		art.name = "ProceduralDestinationMotif"
		_label(cube, names[i], 1.98, 0.79, 0.0033, 130)
		# The accented Vietnamese destination itself is the local-script headline.
		# French and Spanish use the same local city spelling, so avoid duplicate text.
		if i == 0 or i == 2:
			_label(cube, native_names[i], 1.48, 0.73, 0.0035, 116)
		elif i == 1:
			_label(cube, native_names[i], 1.53, 0.73, 0.0028, 100)
	return root


static func _label(parent: Node3D, caption: String, height: float, width: float, pixel: float, size: int) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = SIGNS.font()
	label.pixel_size = pixel
	var longest: float = 0.0
	for line: String in caption.split("\n"):
		longest = maxf(longest, label.font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * pixel)
	label.font_size = int(float(size) * minf(1.0, width / maxf(longest, 0.001)))
	label.modulate = KIT.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.position = Vector3(0.0, height, 0.506)
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _art_mesh() -> QuadMesh:
	if not _meshes.has("poster"):
		var mesh: QuadMesh = QuadMesh.new()
		mesh.size = Vector2(0.77, 0.82)
		_meshes["poster"] = mesh
	return _meshes["poster"] as QuadMesh


static func _poster(destination: int, accent: Color) -> StandardMaterial3D:
	var key: String = "destination_%d" % destination
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var image: Image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	image.fill(KIT.CREAM)
	# Bold silhouettes, a sun and a calm horizon: four colours, no raster text.
	for y in 256:
		for x in 256:
			var p: Vector2 = Vector2(float(x) / 255.0, float(y) / 255.0)
			var ink: Color = KIT.CREAM
			if p.distance_to(Vector2(0.68, 0.29)) < 0.19:
				ink = accent
			var silhouette: bool = false
			match destination:
				0: # Mount Fuji, with a generous snow cap.
					silhouette = p.y > 0.43 + absf(p.x - 0.43) * 0.95 and p.y < 0.81
					if silhouette:
						ink = KIT.CHARCOAL if p.y > 0.56 else KIT.LIMESTONE
				1: # Hanoi's lake pavilion and its broad overhanging roof.
					silhouette = (p.y > 0.55 and p.y < 0.62 and absf(p.x - 0.43) < 0.28 - (0.62 - p.y) * 2.0)
					silhouette = silhouette or (p.y > 0.63 and p.y < 0.8 and (absf(p.x - 0.29) < 0.025 or absf(p.x - 0.57) < 0.025))
				2: # Shanghai's stepped skyline and pearl tower.
					silhouette = (p.x > 0.19 and p.x < 0.31 and p.y > 0.5 and p.y < 0.8)
					silhouette = silhouette or (p.x > 0.59 and p.x < 0.72 and p.y > 0.43 and p.y < 0.8)
					silhouette = silhouette or (absf(p.x - 0.45) < 0.015 and p.y > 0.26 and p.y < 0.8)
					silhouette = silhouette or p.distance_to(Vector2(0.45, 0.56)) < 0.074
				3: # Eiffel silhouette, with an open arch between the feet.
					var spread: float = 0.025 + maxf(0.0, p.y - 0.3) * 0.37
					silhouette = p.y > 0.29 and p.y < 0.81 and absf(p.x - 0.43) < spread
					if p.y > 0.66 and absf(p.x - 0.43) < (p.y - 0.66) * 0.5:
						silhouette = false
				4: # Madrid's monumental three-arched gateway.
					silhouette = p.x > 0.16 and p.x < 0.78 and p.y > 0.49 and p.y < 0.81
					for arch in 3:
						var center: float = 0.28 + float(arch) * 0.19
						if absf(p.x - center) < 0.056 and (p.y > 0.69 or p.distance_to(Vector2(center, 0.69)) < 0.056):
							silhouette = false
			if silhouette and destination != 0:
				ink = KIT.CHARCOAL
			if p.y > 0.84 and p.y < 0.865 and p.x > 0.12 and p.x < 0.88:
				ink = accent
			image.set_pixel(x, y, ink)
	image.generate_mipmaps()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_texture = material.albedo_texture
	material.emission_energy_multiplier = 0.65
	material.roughness = 0.9
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materials[key] = material
	return material
