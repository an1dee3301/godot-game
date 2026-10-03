extends RefCounted
## A freestanding oak electronics island; its customer-facing side is +Z.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ElectronicsStore"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var v: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[v]
	var oak: Material = DesignKit.wood()
	var white: Material = DesignKit.stone(Color(0.95, 0.94, 0.90), 0.42, "electronics_porcelain")
	var steel: Material = DesignKit.metal()
	var glow: Material = DesignKit.washi(DesignKit.CREAM, 1.1, "electronics_warm_light")
	# Flush limestone landing, inset oak toe plinth and two individually crafted tables.
	DesignKit.rbox(root, Vector3(5.8, 0.06, 3.3), Vector3(0.0, 0.03, 0.0), DesignKit.stone(), 0.029)
	for x: float in [-1.43, 1.43]:
		_table(root, x, oak, white, steel, glow)
	# A freestanding illuminated fascia on slender steel posts, without a ceiling dependency.
	for x: float in [-2.55, 2.55]:
		DesignKit.rbox(root, Vector3(0.24, 0.08, 0.5), Vector3(x, 0.10, -1.2), steel, 0.035)
		DesignKit.rbox(root, Vector3(0.075, 2.72, 0.075), Vector3(x, 1.46, -1.2), steel, 0.023)
		DesignKit.rbox(root, Vector3(0.095, 0.12, 0.095), Vector3(x, 0.21, -1.2), DesignKit.brass(), 0.024)
	DesignKit.rbox(root, Vector3(5.6, 1.24, 0.2), Vector3(0.0, 3.07, -1.2), oak, 0.09)
	DesignKit.rbox(root, Vector3(5.42, 1.06, 0.045), Vector3(0.0, 3.07, -1.084), glow, 0.022, false)
	DesignKit.rbox(root, Vector3(5.10, 0.025, 0.018), Vector3(0.0, 3.50, -1.055), DesignKit.brass(), 0.008, false)
	_label(root, "ELECTRONICS", Vector3(0.0, 3.30, -1.053), 0.0047, 94)
	_label(root, "電子機器   ·   电子产品", Vector3(0.0, 2.99, -1.053), 0.0036, 70)
	_label(root, "Điện tử   ·   Électronique   ·   Electrónica", Vector3(0.0, 2.70, -1.053), 0.0035, 64)
	# Rear demo monitor: black glass inside a white ceramic enclosure on an oak pedestal.
	DesignKit.rbox(root, Vector3(1.05, 0.16, 0.62), Vector3(0.0, 0.14, -0.94), oak, 0.075)
	DesignKit.rbox(root, Vector3(0.34, 1.18, 0.32), Vector3(0.0, 0.78, -0.94), white, 0.09)
	DesignKit.rbox(root, Vector3(1.90, 1.08, 0.10), Vector3(0.0, 1.88, -0.94), white, 0.045)
	DesignKit.rbox(root, Vector3(1.80, 0.98, 0.023), Vector3(0.0, 1.88, -0.879), steel, 0.011, false)
	DesignKit.rbox(root, Vector3(1.73, 0.91, 0.012), Vector3(0.0, 1.90, -0.861), _screen(v), 0.005, false)
	DesignKit.rbox(root, Vector3(0.09, 0.007, 0.008), Vector3(0.0, 1.37, -0.882), glow, 0.003, false)
	# Security cradles and linen mats keep the small devices readable as separate silhouettes.
	for i: int in 3:
		_phone(root, Vector3(-2.19 + float(i) * 0.71, 1.02, 0.38), v + i, accent)
	for i: int in 2:
		_headphones(root, Vector3(0.91 + float(i) * 0.95, 1.02, 0.46), accent, v)
	for i: int in 2:
		_camera(root, Vector3(0.87 + float(i) * 1.03, 1.02, -0.51), v + i)
	# One flat tablet presents a larger touch surface behind the phone row.
	var tablet: Node3D = Node3D.new()
	tablet.position = Vector3(-1.43, 1.11, -0.49)
	tablet.rotation_degrees.x = -48.0
	root.add_child(tablet)
	DesignKit.rbox(tablet, Vector3(0.32, 0.23, 0.017), Vector3.ZERO, steel, 0.008, false)
	DesignKit.rbox(tablet, Vector3(0.29, 0.20, 0.005), Vector3(0.0, 0.0, 0.012), _screen(v + 1), 0.002, false)
	return root


static func _table(parent: Node3D, x: float, oak: Material, white: Material, steel: Material, glow: Material) -> void:
	DesignKit.rbox(parent, Vector3(2.46, 0.14, 2.12), Vector3(x, 0.14, 0.0), steel, 0.06)
	DesignKit.rbox(parent, Vector3(2.52, 0.69, 2.20), Vector3(x, 0.555, 0.0), oak, 0.10)
	DesignKit.rbox(parent, Vector3(2.56, 0.027, 2.24), Vector3(x, 0.907, 0.0), glow, 0.013, false)
	DesignKit.rbox(parent, Vector3(2.66, 0.10, 2.34), Vector3(x, 0.965, 0.0), white, 0.048)
	# Two inset drawers with a dark shadow reveal and understated brass pulls.
	for dx: float in [-0.61, 0.61]:
		DesignKit.rbox(parent, Vector3(1.17, 0.40, 0.025), Vector3(x + dx, 0.63, 1.103), steel, 0.012)
		DesignKit.rbox(parent, Vector3(1.135, 0.367, 0.026), Vector3(x + dx, 0.63, 1.121), oak, 0.012)
		DesignKit.rbox(parent, Vector3(0.23, 0.022, 0.035), Vector3(x + dx, 0.73, 1.15), DesignKit.brass(), 0.010, false)


static func _phone(parent: Node3D, at: Vector3, v: int, accent: Color) -> void:
	var root: Node3D = Node3D.new()
	root.position = at
	root.rotation_degrees.y = float(posmod(v, 3) - 1) * 12.0
	parent.add_child(root)
	DesignKit.rbox(root, Vector3(0.34, 0.012, 0.40), Vector3(0.0, 0.006, 0.0), DesignKit.fabric(accent, "electronics_mat_%d" % posmod(v, 4)), 0.005, false)
	DesignKit.rbox(root, Vector3(0.13, 0.022, 0.14), Vector3(0.0, 0.027, 0.0), DesignKit.paint(DesignKit.CREAM), 0.010, false)
	DesignKit.rbox(root, Vector3(0.035, 0.065, 0.038), Vector3(0.0, 0.068, -0.023), DesignKit.brass(), 0.01, false)
	var handset: Node3D = Node3D.new()
	handset.position = Vector3(0.0, 0.147, 0.0)
	handset.rotation_degrees.x = -14.0
	root.add_child(handset)
	DesignKit.rbox(handset, Vector3(0.084, 0.171, 0.013), Vector3.ZERO, DesignKit.metal(), 0.006, false)
	DesignKit.rbox(handset, Vector3(0.073, 0.151, 0.004), Vector3(0.0, 0.0, 0.008), _screen(v), 0.0018, false)
	DesignKit.rbox(handset, Vector3(0.026, 0.004, 0.003), Vector3(0.0, 0.067, 0.012), DesignKit.metal(), 0.001, false)


static func _headphones(parent: Node3D, at: Vector3, accent: Color, v: int) -> void:
	var steel: Material = DesignKit.metal()
	DesignKit.rbox(parent, Vector3(0.43, 0.016, 0.44), at + Vector3(0.0, 0.008, 0.0), DesignKit.fabric(), 0.007, false)
	DesignKit.rbox(parent, Vector3(0.23, 0.022, 0.19), at + Vector3(0.0, 0.030, 0.0), DesignKit.wood(), 0.010, false)
	DesignKit.rbox(parent, Vector3(0.026, 0.26, 0.028), at + Vector3(0.0, 0.17, -0.018), DesignKit.brass(), 0.012, false)
	DesignKit.rbox(parent, Vector3(0.09, 0.025, 0.08), at + Vector3(0.0, 0.303, -0.018), steel, 0.012, false)
	DesignKit.add(parent, _headband(), steel, at + Vector3(0.0, 0.225, 0.0), Vector3.ZERO, false)
	var cushion: Material = DesignKit.fabric(accent, "electronics_ear_%d" % v)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(parent, Vector3(0.045, 0.12, 0.085), at + Vector3(side * 0.107, 0.195, 0.0), DesignKit.paint(DesignKit.CREAM), 0.021, false)
		DesignKit.rbox(parent, Vector3(0.025, 0.105, 0.075), at + Vector3(side * 0.078, 0.195, 0.0), cushion, 0.012, false)


static func _camera(parent: Node3D, at: Vector3, v: int) -> void:
	var root: Node3D = Node3D.new()
	root.position = at
	root.rotation_degrees.y = -10.0 if posmod(v, 2) == 0 else 12.0
	parent.add_child(root)
	var steel: Material = DesignKit.metal()
	DesignKit.rbox(root, Vector3(0.41, 0.013, 0.39), Vector3(0.0, 0.0065, 0.0), DesignKit.fabric(), 0.006, false)
	DesignKit.rbox(root, Vector3(0.153, 0.09, 0.065), Vector3(0.0, 0.063, 0.0), steel, 0.015, false)
	DesignKit.rbox(root, Vector3(0.15, 0.012, 0.063), Vector3(0.0, 0.107, 0.0), DesignKit.metal(DesignKit.LINEN, 0.28, 0.9, "electronics_camera_trim"), 0.005, false)
	DesignKit.rbox(root, Vector3(0.035, 0.077, 0.073), Vector3(0.058, 0.059, 0.007), DesignKit.fabric(DesignKit.CHARCOAL, "electronics_camera_grip"), 0.014, false)
	DesignKit.rbox(root, Vector3(0.043, 0.023, 0.032), Vector3(-0.01, 0.123, -0.004), steel, 0.009, false)
	var lens: Mesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.035, 0.0), Vector2(0.037, 0.006), Vector2(0.033, 0.01), Vector2(0.033, 0.053), Vector2(0.036, 0.057), Vector2(0.036, 0.066), Vector2(0.0, 0.066)]))
	DesignKit.add(root, lens, steel, Vector3(-0.015, 0.065, 0.03), Vector3(90.0, 0.0, 0.0), false)
	var glass: Mesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.028, 0.0), Vector2(0.028, 0.002), Vector2(0.0, 0.002)]))
	DesignKit.add(root, glass, DesignKit.metal(Color(0.12, 0.25, 0.28), 0.12, 0.6, "electronics_lens"), Vector3(-0.015, 0.065, 0.097), Vector3(90.0, 0.0, 0.0), false)


static func _label(parent: Node3D, caption: String, at: Vector3, pixel_size: float, font_size: int) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.position = at
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _headband() -> ArrayMesh:
	if _meshes.has("headband"):
		return _meshes["headband"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Rectangular-section swept semicircle; a single mesh rather than segmented boxes.
	for i: int in 20:
		var a: float = PI * float(i) / 20.0
		var b: float = PI * float(i + 1) / 20.0
		var ring_a: Array[Vector3] = []
		var ring_b: Array[Vector3] = []
		for corner: Vector2 in [Vector2(0.100, -0.022), Vector2(0.112, -0.022), Vector2(0.112, 0.022), Vector2(0.100, 0.022)]:
			ring_a.append(Vector3(cos(a) * corner.x, sin(a) * corner.x, corner.y))
			ring_b.append(Vector3(cos(b) * corner.x, sin(b) * corner.x, corner.y))
		for j: int in 4:
			var k: int = (j + 1) % 4
			for point: Vector3 in [ring_a[j], ring_b[j], ring_b[k], ring_a[j], ring_b[k], ring_a[k]]:
				st.add_vertex(point)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["headband"] = mesh
	return mesh


static func _screen(variant: int) -> StandardMaterial3D:
	var v: int = posmod(variant, 4)
	var key: String = "screen_%d" % v
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var skies: Array[Color] = [Color(0.34, 0.56, 0.61), Color(0.58, 0.40, 0.34), Color(0.28, 0.38, 0.58), Color(0.54, 0.58, 0.39)]
	var sky: Color = skies[v]
	var image: Image = Image.create(256, 128, false, Image.FORMAT_RGB8)
	for y: int in 128:
		for x: int in 256:
			var u: float = float(x) / 255.0
			var w: float = float(y) / 127.0
			var color: Color = sky.lerp(DesignKit.CREAM, w * 0.50)
			if Vector2(u - 0.72, (w - 0.30) * 0.5).length() < 0.075:
				color = DesignKit.CREAM
			if w > 0.69 + sin(u * 8.0 + float(v)) * 0.12:
				color = sky.darkened(0.24)
			if w > 0.88 + cos(u * 6.0) * 0.07:
				color = sky.darkened(0.43)
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.emission_enabled = true
	material.emission_texture = texture
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 1.25
	material.roughness = 0.25
	_materials[key] = material
	return material
