extends RefCounted
## A still water garden: honed limestone, hollow bamboo and floating stone treads.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "WaterGarden"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var tones: Array[Color] = [DesignKit.LIMESTONE, Color(0.79, 0.79, 0.71), Color(0.88, 0.79, 0.69), DesignKit.PLASTER]
	var bamboo_tones: Array[Color] = [DesignKit.OAK, Color(0.65, 0.64, 0.39), Color(0.73, 0.53, 0.32), DesignKit.WALNUT]
	var limestone: StandardMaterial3D = DesignKit.stone(tones[style], 0.57, "water_limestone_%d" % style)
	var wet_stone: StandardMaterial3D = DesignKit.stone(tones[style].darkened(0.30), 0.31, "water_wet_stone_%d" % style)
	var bamboo: StandardMaterial3D = DesignKit.wood(bamboo_tones[style], "water_bamboo_%d" % style)
	var node_band: StandardMaterial3D = DesignKit.wood(bamboo_tones[style].darkened(0.17), "water_bamboo_nodes_%d" % style)
	var steel: StandardMaterial3D = DesignKit.metal()
	var water: StandardMaterial3D = _water_material(style)
	# Recessed plinth, a continuous bottom, and four thick walls leave a real open basin.
	DesignKit.rbox(root, Vector3(3.84, 0.09, 1.12), Vector3(0.0, 0.045, 0.0), steel, 0.035)
	DesignKit.rbox(root, Vector3(4.12, 0.17, 1.40), Vector3(0.0, 0.165, 0.0), limestone, 0.075)
	DesignKit.rbox(root, Vector3(3.83, 0.08, 1.13), Vector3(0.0, 0.29, 0.0), wet_stone, 0.035)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(4.02, 0.57, 0.17), Vector3(0.0, 0.515, side * 0.615), limestone, 0.055)
		DesignKit.rbox(root, Vector3(0.18, 0.57, 1.08), Vector3(side * 1.92, 0.515, 0.0), limestone, 0.055)
		# Thin warm metal reveal sits below the rounded coping, outside the water.
		DesignKit.rbox(root, Vector3(3.89, 0.014, 0.014), Vector3(0.0, 0.723, side * 0.703), DesignKit.brass(), 0.005, false)
	DesignKit.rbox(root, Vector3(3.69, 0.023, 1.06), Vector3(0.0, 0.665, 0.0), water, 0.010, false)
	# Irregularly spaced oval treads: dark wet skirts beneath pale, rounded dry crowns.
	var tread_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.22, 0.0), Vector2(0.28, 0.025),
		Vector2(0.29, 0.095), Vector2(0.27, 0.135), Vector2(0.21, 0.15), Vector2(0.0, 0.15)
	]), 32)
	for index: int in 4:
		var x: float = -0.94 + float(index) * 0.64
		var z: float = (0.12 if index % 2 == 0 else -0.12) * (-1.0 if style % 2 == 1 else 1.0)
		var tread: MeshInstance3D = DesignKit.add(root, tread_mesh, wet_stone, Vector3(x, 0.59, z))
		tread.scale = Vector3(1.09 + float((index + style) % 3) * 0.09, 1.0, 0.83)
		tread.rotation_degrees.y = float(index * 19 + style * 13)
		var crown: MeshInstance3D = DesignKit.add(root, tread_mesh, limestone, Vector3(x, 0.71, z))
		crown.scale = Vector3(tread.scale.x * 0.94, 0.36, 0.78)
		crown.rotation_degrees.y = tread.rotation_degrees.y
	# Upright culm and a visibly hollow, downward pitched bamboo outlet.
	var tube: ArrayMesh = _tube_mesh()
	var upright: MeshInstance3D = DesignKit.add(root, tube, bamboo, Vector3(-1.55, 0.24, -0.37))
	upright.scale = Vector3(1.0, 1.48, 1.0)
	DesignKit.add(root, tube, bamboo, Vector3(-1.55, 1.23, -0.37), Vector3(100.0, 0.0, 0.0))
	var band: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.059, 0.0), Vector2(0.066, 0.006), Vector2(0.067, 0.023),
		Vector2(0.060, 0.03), Vector2(0.059, 0.0)
	]), 24)
	for height: float in [0.47, 0.82, 1.17]:
		DesignKit.add(root, band, node_band, Vector3(-1.55, height, -0.37))
	for distance: float in [0.16, 0.49]:
		DesignKit.add(root, band, node_band, Vector3(-1.55, 1.23 - distance * 0.17365, -0.37 + distance * 0.9848), Vector3(100.0, 0.0, 0.0))
	# Two black steel saddles secure the bamboo to the basin; linen cord binds the joint.
	for height: float in [0.36, 0.68]:
		DesignKit.rbox(root, Vector3(0.18, 0.055, 0.16), Vector3(-1.55, height, -0.45), steel, 0.02)
	var cord: StandardMaterial3D = DesignKit.fabric(DesignKit.LINEN, "water_spout_cord")
	for index: int in 3:
		DesignKit.add(root, band, cord, Vector3(-1.55, 1.105 + float(index) * 0.031, -0.37))
	var stream: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.014, 0.0), Vector2(0.009, 0.38), Vector2(0.0, 0.38)
	]), 12)
	DesignKit.add(root, stream, _stream_material(), Vector3(-1.55, 0.677, 0.29), Vector3.ZERO, false)
	# Static concentric ripple crests, not animation or particle nodes.
	for index: int in 3:
		var radius: float = 0.06 + float(index) * 0.065
		var ripple: ArrayMesh = DesignKit.lathe(PackedVector2Array([
			Vector2(radius - 0.006, 0.0), Vector2(radius, 0.003), Vector2(radius + 0.006, 0.0)
		]), 40)
		DesignKit.add(root, ripple, _stream_material(), Vector3(-1.55, 0.679, 0.29), Vector3.ZERO, false)
	# Large engraved lettering on the public (+Z) fascia, in all six terminal languages.
	_caption(root, "Water Garden · 水庭 · 水景", Vector3(0.0, 0.61, 0.707), 88, 0.0024)
	_caption(root, "Vườn nước · Jardin d’eau", Vector3(0.0, 0.43, 0.707), 78, 0.0024)
	_caption(root, "Jardín de agua", Vector3(0.0, 0.26, 0.707), 78, 0.0024)
	return root


static func _caption(parent: Node3D, text: String, at: Vector3, size: int, pixel_size: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixel_size
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.position = at
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _tube_mesh() -> ArrayMesh:
	if not _meshes.has("bamboo_tube"):
		_meshes["bamboo_tube"] = DesignKit.lathe(PackedVector2Array([
			Vector2(0.043, 0.0), Vector2(0.055, 0.0), Vector2(0.059, 0.012),
			Vector2(0.058, 0.66), Vector2(0.054, 0.67), Vector2(0.043, 0.67),
			Vector2(0.040, 0.657), Vector2(0.040, 0.014), Vector2(0.043, 0.0)
		]), 28)
	return _meshes["bamboo_tube"] as ArrayMesh


static func _water_material(style: int) -> StandardMaterial3D:
	var key: String = "water_%d" % style
	if not _materials.has(key):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		var tints: Array[Color] = [Color(0.035, 0.085, 0.075), Color(0.045, 0.075, 0.082), Color(0.065, 0.075, 0.059), Color(0.040, 0.065, 0.072)]
		material.albedo_color = tints[style]
		material.roughness = 0.14
		material.metallic = 0.22
		var noise: FastNoiseLite = FastNoiseLite.new()
		noise.frequency = 0.045
		noise.fractal_octaves = 2
		var texture: NoiseTexture2D = NoiseTexture2D.new()
		texture.width = 128
		texture.height = 128
		texture.noise = noise
		texture.seamless = true
		texture.as_normal_map = true
		texture.bump_strength = 0.4
		material.normal_enabled = true
		material.normal_texture = texture
		material.normal_scale = 0.14
		_materials[key] = material
	return _materials[key] as StandardMaterial3D


static func _stream_material() -> StandardMaterial3D:
	if not _materials.has("stream"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.28, 0.42, 0.38, 0.65)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness = 0.12
		_materials["stream"] = material
	return _materials["stream"] as StandardMaterial3D
