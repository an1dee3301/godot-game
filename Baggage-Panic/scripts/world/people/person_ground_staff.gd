extends RefCounted
## A 1.76 m ramp worker: tailored safety vest, hearing protection and practical workwear.
## Body parts are turned or capsule based; all custom resources are shared between workers.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
const VEST_PROFILE: Array[Vector2] = [
	Vector2(0.178, 0.89), Vector2(0.194, 0.93), Vector2(0.212, 1.11),
	Vector2(0.224, 1.285), Vector2(0.20, 1.33), Vector2(0.125, 1.365),
]

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var style: int = posmod(variant, 3)
	var root: Node3D = Node3D.new()
	root.name = "GroundStaff"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var vest_colors: Array[Color] = [Color(0.88, 0.94, 0.22), Color(0.98, 0.43, 0.13), Color(0.95, 0.83, 0.18)]
	var shirt_colors: Array[Color] = [Kit.INDIGO, Kit.SAGE.darkened(0.35), Kit.CLAY.darkened(0.38)]
	var skin_colors: Array[Color] = [Color(0.72, 0.46, 0.30), Color(0.92, 0.70, 0.53), Color(0.39, 0.23, 0.17)]
	var hair_colors: Array[Color] = [Color(0.13, 0.105, 0.09), Kit.WALNUT.darkened(0.25), Color(0.23, 0.22, 0.20)]
	var skin: StandardMaterial3D = Kit.paint(skin_colors[style], 0.88)
	var hair: StandardMaterial3D = Kit.paint(hair_colors[style], 0.94)
	var shirt: StandardMaterial3D = _cloth("shirt_%d" % style, shirt_colors[style])
	var vest: StandardMaterial3D = _cloth("vest_%d" % style, vest_colors[style])
	var trousers: StandardMaterial3D = _cloth("trousers_%d" % style, shirt_colors[style].darkened(0.38))
	var rubber: StandardMaterial3D = Kit.paint(Kit.CHARCOAL.darkened(0.38), 0.94)
	var steel: StandardMaterial3D = Kit.metal(Kit.CHARCOAL, 0.48, 0.65, "ground_staff_steel")
	var reflector: StandardMaterial3D = Kit.metal(Kit.CREAM.darkened(0.08), 0.34, 0.30, "ground_staff_reflector")
	var ear_shell: StandardMaterial3D = Kit.paint(vest_colors[style].darkened(0.18), 0.43)

	# Flattened, rounded outsoles give an exact floor contact; toes project toward +Z.
	for side: float in [-1.0, 1.0]:
		var foot_x: float = side * 0.115
		var sole: MeshInstance3D = Kit.rbox(root, Vector3(0.174, 0.045, 0.296), Vector3(foot_x, 0.0225, 0.047), rubber, 0.019)
		sole.name = "BootSole"
		_ball(root, "SafetyBoot", Vector3(foot_x, 0.12, 0.047), Vector3(0.17, 0.184, 0.29), Kit.paint(Kit.WALNUT.darkened(0.50), 0.8))
		_limb(root, "TrouserLeg", Vector3(foot_x, 0.225, 0.0), Vector3(side * 0.102, 0.83, 0.0), 0.074, trousers)
	_ball(root, "TrouserSeat", Vector3(0.0, 0.843, 0.0), Vector3(0.352, 0.28, 0.25), trousers)
	var torso: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.884), Vector2(0.171, 0.884), Vector2(0.187, 0.93),
		Vector2(0.205, 1.11), Vector2(0.217, 1.285), Vector2(0.193, 1.33),
		Vector2(0.117, 1.365), Vector2(0.063, 1.38), Vector2(0.0, 1.38),
	]), 20), shirt, Vector3.ZERO)
	torso.name = "WorkShirt"
	torso.scale.z = 0.68
	_named(root, "OpenTailoredVest", _vest_mesh(false), vest, Vector3.ZERO)
	_named(root, "ReflectiveHarness", _vest_mesh(true), reflector, Vector3.ZERO)
	_limb(root, "VestZipper", Vector3(0.0, 0.912, 0.133), Vector3(0.0, 1.125, 0.151), 0.006, steel)
	_ball(root, "BrassZipPull", Vector3(0.0, 1.129, 0.155), Vector3(0.014, 0.026, 0.008), Kit.brass())
	_limb(root, "Neck", Vector3(0.0, 1.36, 0.0), Vector3(0.0, 1.437, 0.0), 0.064, skin)

	# One relaxed arm and one bent arm, with rounded sleeve ends and mitten-like hands.
	_limb(root, "RelaxedSleeve", Vector3(-0.208, 1.282, 0.0), Vector3(-0.28, 1.07, 0.024), 0.074, shirt)
	_limb(root, "RelaxedForearm", Vector3(-0.28, 1.071, 0.024), Vector3(-0.305, 0.9, 0.071), 0.051, skin)
	_ball(root, "RelaxedHand", Vector3(-0.309, 0.851, 0.084), Vector3(0.101, 0.14, 0.098), skin)
	_limb(root, "BentSleeve", Vector3(0.208, 1.28, 0.0), Vector3(0.31, 1.097, 0.038), 0.074, shirt)
	_limb(root, "BentForearm", Vector3(0.31, 1.097, 0.038), Vector3(0.325, 1.156, 0.202), 0.051, skin)
	_ball(root, "HoldingHand", Vector3(0.327, 1.176, 0.221), Vector3(0.102, 0.12, 0.102), skin)

	_ball(root, "Face", Vector3(0.0, 1.531, 0.0), Vector3(0.315, 0.347, 0.294), skin)
	_named(root, "SculptedHair", _hair_mesh(), hair, Vector3(0.0, 1.541, 0.0))
	if style == 1:
		_ball(root, "TiedBackBun", Vector3(0.0, 1.614, -0.172), Vector3(0.135, 0.137, 0.126), hair)
	else:
		_ball(root, "SweptFringe", Vector3(-0.056, 1.636, 0.112), Vector3(0.14, 0.076, 0.075), hair)
	for side: float in [-1.0, 1.0]:
		_ball(root, "Eye", Vector3(side * 0.057, 1.556, 0.135), Vector3(0.020, 0.028, 0.012), rubber)
	_ball(root, "Nose", Vector3(0.0, 1.514, 0.148), Vector3(0.045, 0.045, 0.043), skin)
	_named(root, "SmallSmile", _smile_mesh(), Kit.paint(skin_colors[style].darkened(0.42), 0.9), Vector3.ZERO)

	# Separate cushions, enamel cups and brass pivots make hearing protection unambiguous.
	for side: float in [-1.0, 1.0]:
		_ball(root, "EarCushion", Vector3(side * 0.171, 1.548, -0.005), Vector3(0.072, 0.194, 0.155), rubber)
		_ball(root, "EarDefenderCup", Vector3(side * 0.205, 1.548, -0.005), Vector3(0.068, 0.166, 0.132), ear_shell)
		_ball(root, "DefenderPivot", Vector3(side * 0.239, 1.571, -0.005), Vector3(0.014, 0.03, 0.03), Kit.brass())
	_named(root, "PaddedHearingBand", _headband_mesh(), rubber, Vector3.ZERO)

	# Reuse the terminal's international plane pictogram; the uniform carries no tiny text.
	if not _meshes.has("apron_patch"):
		var patch: QuadMesh = QuadMesh.new()
		patch.size = Vector2(0.067, 0.067)
		_meshes["apron_patch"] = patch
	var patch_mesh: Mesh = _meshes["apron_patch"]
	var apron_words: Array = Signs.translations("apron")
	var patch_node: MeshInstance3D = _named(root, "ApronPictogram", patch_mesh, Signs._icon_material(str(apron_words[6]), Kit.INDIGO), Vector3(-0.099, 1.207, 0.14))
	patch_node.rotation_degrees.y = -18.0
	patch_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_accessory(root, style, rubber, steel)
	return root


static func _cloth(key: String, tint: Color) -> StandardMaterial3D:
	if not _materials.has(key):
		var material: StandardMaterial3D = Kit.fabric(tint, "ground_staff_" + key).duplicate() as StandardMaterial3D
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials[key] = material
	return _materials[key] as StandardMaterial3D


static func _named(parent: Node3D, title: String, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var node: MeshInstance3D = Kit.add(parent, mesh, material, at)
	node.name = title
	return node


static func _ball(parent: Node3D, title: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	if not _meshes.has("ball"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 16
		sphere.rings = 8
		_meshes["ball"] = sphere
	var mesh: Mesh = _meshes["ball"]
	var node: MeshInstance3D = _named(parent, title, mesh, material, at)
	node.scale = size
	return node


static func _limb(parent: Node3D, title: String, start: Vector3, finish: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var length: float = start.distance_to(finish)
	var key: String = "capsule:%.5f:%.5f" % [radius, length]
	if not _meshes.has(key):
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = radius
		capsule.height = length + radius * 2.0
		capsule.radial_segments = 12
		capsule.rings = 4
		_meshes[key] = capsule
	var mesh: Mesh = _meshes[key]
	var node: MeshInstance3D = _named(parent, title, mesh, material, (start + finish) * 0.5)
	node.basis = Basis(Quaternion(Vector3.UP, (finish - start).normalized()))
	return node


static func _vest_point(height: float, angle: float, offset: float = 0.0) -> Vector3:
	var radius: float = VEST_PROFILE[0].x
	for index: int in range(VEST_PROFILE.size() - 1):
		var low: Vector2 = VEST_PROFILE[index]
		var high: Vector2 = VEST_PROFILE[index + 1]
		if height >= low.y and height <= high.y:
			radius = lerpf(low.x, high.x, (height - low.y) / (high.y - low.y))
			break
	return Vector3(sin(angle) * (radius + offset), height, cos(angle) * (radius * 0.68 + offset))


static func _vest_mesh(tape: bool) -> ArrayMesh:
	var key: String = "reflectors" if tape else "vest"
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if tape:
		# Two wraparound belts and four shoulder braces are merged into a single mesh.
		for height: float in [0.958, 1.096]:
			_strip(surface, height, height + 0.04, 0.07, TAU - 0.07, 32, 0.003)
		for angle: float in [0.68, TAU - 0.68, PI - 0.68, PI + 0.68]:
			_strip(surface, 1.136, 1.306, angle - 0.115, angle + 0.115, 3, 0.004)
	else:
		for row: int in range(VEST_PROFILE.size() - 1):
			var low: float = VEST_PROFILE[row].y
			var high: float = VEST_PROFILE[row + 1].y
			var low_gap: float = 0.036 + maxf(0.0, low - 1.145) * 2.75
			var high_gap: float = 0.036 + maxf(0.0, high - 1.145) * 2.75
			for segment: int in range(32):
				var t0: float = float(segment) / 32.0
				var t1: float = float(segment + 1) / 32.0
				var a: Vector3 = _vest_point(low, lerpf(low_gap, TAU - low_gap, t0))
				var b: Vector3 = _vest_point(low, lerpf(low_gap, TAU - low_gap, t1))
				var c: Vector3 = _vest_point(high, lerpf(high_gap, TAU - high_gap, t1))
				var d: Vector3 = _vest_point(high, lerpf(high_gap, TAU - high_gap, t0))
				_quad(surface, a, b, c, d, Vector3(a.x + b.x, 0.0, a.z + b.z))
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _strip(surface: SurfaceTool, low: float, high: float, angle_start: float, angle_end: float, steps: int, offset: float) -> void:
	for row: int in range(6):
		var y0: float = lerpf(low, high, float(row) / 6.0)
		var y1: float = lerpf(low, high, float(row + 1) / 6.0)
		for segment: int in range(steps):
			var a0: float = lerpf(angle_start, angle_end, float(segment) / float(steps))
			var a1: float = lerpf(angle_start, angle_end, float(segment + 1) / float(steps))
			var a: Vector3 = _vest_point(y0, a0, offset)
			var b: Vector3 = _vest_point(y0, a1, offset)
			_quad(surface, a, b, _vest_point(y1, a1, offset), _vest_point(y1, a0, offset), Vector3(a.x + b.x, 0.0, a.z + b.z))


static func _hair_mesh() -> ArrayMesh:
	if _meshes.has("hair"):
		return _meshes["hair"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring: int in range(6):
		for segment: int in range(20):
			var a0: float = TAU * float(segment) / 20.0
			var a1: float = TAU * float(segment + 1) / 20.0
			var p0: float = float(ring) / 6.0
			var p1: float = float(ring + 1) / 6.0
			var a: Vector3 = _hair_point(a0, p0)
			var b: Vector3 = _hair_point(a1, p0)
			var c: Vector3 = _hair_point(a1, p1)
			var d: Vector3 = _hair_point(a0, p1)
			_quad(surface, a, b, c, d, (c + d).normalized())
	var mesh: ArrayMesh = surface.commit()
	_meshes["hair"] = mesh
	return mesh


static func _hair_point(angle: float, fraction: float) -> Vector3:
	var polar: float = (1.26 + 0.25 * (1.0 - cos(angle))) * fraction
	return Vector3(0.162 * sin(polar) * sin(angle), 0.177 * cos(polar), 0.152 * sin(polar) * cos(angle))


static func _headband_mesh() -> ArrayMesh:
	if _meshes.has("headband"):
		return _meshes["headband"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment: int in range(20):
		var a0: float = PI * float(segment) / 20.0
		var a1: float = PI * float(segment + 1) / 20.0
		for edge: int in range(4):
			var a: Vector3 = _band_corner(a0, edge)
			var b: Vector3 = _band_corner(a1, edge)
			var c: Vector3 = _band_corner(a1, (edge + 1) % 4)
			var d: Vector3 = _band_corner(a0, (edge + 1) % 4)
			var outward: Vector3 = Vector3(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5), 0.0)
			if edge == 1:
				outward = Vector3.FORWARD
			elif edge == 2:
				outward = -outward
			elif edge == 3:
				outward = Vector3.BACK
			_quad(surface, a, b, c, d, outward)
	var mesh: ArrayMesh = surface.commit()
	_meshes["headband"] = mesh
	return mesh


static func _band_corner(angle: float, corner: int) -> Vector3:
	var outer: bool = corner < 2
	var radius_offset: float = 0.012 if outer else -0.012
	var depth: float = 0.027 if corner == 0 or corner == 3 else -0.027
	return Vector3((0.21 + radius_offset) * cos(angle), 1.565 + (0.177 + radius_offset) * sin(angle), depth - 0.008)


static func _smile_mesh() -> ArrayMesh:
	if _meshes.has("smile"):
		return _meshes["smile"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment: int in range(8):
		var x0: float = lerpf(-0.026, 0.026, float(segment) / 8.0)
		var x1: float = lerpf(-0.026, 0.026, float(segment + 1) / 8.0)
		var a: Vector3 = Vector3(x0, 1.476 + x0 * x0 * 7.0, 0.140)
		var b: Vector3 = Vector3(x1, 1.476 + x1 * x1 * 7.0, 0.140)
		_quad(surface, a, b, b + Vector3.UP * 0.004, a + Vector3.UP * 0.004, Vector3.BACK)
	var mesh: ArrayMesh = surface.commit()
	_meshes["smile"] = mesh
	return mesh


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	if normal.is_zero_approx():
		normal = (c - a).cross(d - a).normalized()
	var points: Array[Vector3] = [a, c, b, a, d, c]
	if normal.dot(outward) < 0.0:
		normal = -normal
		points = [a, b, c, a, c, d]
	for point: Vector3 in points:
		surface.set_normal(normal)
		surface.set_uv(Vector2(point.x, point.y))
		surface.add_vertex(point)


static func _accessory(root: Node3D, style: int, rubber: Material, steel: Material) -> void:
	if style == 1:
		# A short marshal wand, carried upright in the bent hand.
		_limb(root, "WandGrip", Vector3(0.328, 1.133, 0.252), Vector3(0.328, 1.248, 0.252), 0.022, rubber)
		_limb(root, "AmberMarshalWand", Vector3(0.328, 1.277, 0.252), Vector3(0.328, 1.533, 0.252), 0.022, Kit.washi(Color(1.0, 0.44, 0.13), 0.65, "ground_staff_wand"))
		_ball(root, "WandCollar", Vector3(0.328, 1.258, 0.252), Vector3(0.056, 0.026, 0.056), steel)
	else:
		var radio: MeshInstance3D = Kit.rbox(root, Vector3(0.088, 0.145, 0.063), Vector3(0.328, 1.245, 0.262), rubber, 0.022)
		radio.name = "HandheldRadio"
		_limb(root, "RadioAntenna", Vector3(0.35, 1.31, 0.257), Vector3(0.35, 1.426, 0.252), 0.007, rubber)
		var speaker: MeshInstance3D = Kit.rbox(root, Vector3(0.056, 0.054, 0.009), Vector3(0.328, 1.266, 0.296), _cloth("radio_grille", Kit.CHARCOAL.lightened(0.14)), 0.003)
		speaker.name = "WovenRadioGrille"
