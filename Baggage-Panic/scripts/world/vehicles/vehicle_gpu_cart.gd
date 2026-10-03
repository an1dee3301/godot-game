extends RefCounted
## Towable 90 kVA ground power unit. Metres, ground contact at zero, hitch faces +Z.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "GroundPowerUnit"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colours: Array[Color] = [Color(0.94, 0.70, 0.18), Kit.CREAM, Kit.SAGE, Kit.CHARCOAL]
	var body: Material = Kit.paint(colours[scheme], 0.43)
	var stripe: Material = Kit.brass() if scheme == 3 else Kit.paint(Kit.CLAY if scheme == 1 else Kit.CREAM)
	var steel: Material = Kit.metal(Kit.CHARCOAL, 0.42, 0.8, "gpu_frame")
	var alloy: Material = Kit.metal(Color(0.64, 0.63, 0.57), 0.34, 0.85, "gpu_alloy")
	var rubber: Material = Kit.paint(Color(0.045, 0.043, 0.038), 0.94)
	var amber: Material = Kit.washi(Color(1.0, 0.52, 0.08), 3.0, "gpu_beacon")
	var lamp: Material = Kit.washi(Kit.CREAM, 2.8, "gpu_headlight")
	# Low ladder frame, rear reel deck and replaceable rubber bumper rails.
	Kit.rbox(root, Vector3(1.66, 0.18, 3.48), Vector3(0, 0.48, -0.12), steel, 0.06)
	Kit.rbox(root, Vector3(1.72, 0.09, 1.03), Vector3(0, 0.62, -1.35), alloy, 0.03)
	for x: float in [-0.84, 0.84]:
		Kit.rbox(root, Vector3(0.10, 0.13, 3.50), Vector3(x, 0.58, -0.12), rubber, 0.04)
	# Rounded, folded-sheet enclosure with a contrasting recessed plinth and cap.
	Kit.rbox(root, Vector3(1.57, 1.04, 2.48), Vector3(0, 1.13, 0.30), body, 0.13)
	Kit.rbox(root, Vector3(1.60, 0.12, 2.51), Vector3(0, 0.71, 0.30), stripe, 0.04)
	Kit.rbox(root, Vector3(1.61, 0.09, 2.51), Vector3(0, 1.66, 0.30), alloy, 0.04)
	# Axles and turned pneumatic tyres: radius .34 gives exact floor contact.
	var tyre_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.15, -0.14), Vector2(0.27, -0.14), Vector2(0.32, -0.10),
		Vector2(0.34, -0.05), Vector2(0.34, 0.05), Vector2(0.32, 0.10),
		Vector2(0.27, 0.14), Vector2(0.15, 0.14), Vector2(0.15, -0.14)])
	for z: float in [-1.18, 1.10]:
		_rod(root, Vector3(-0.99, 0.34, z), Vector3(0.99, 0.34, z), 0.055, steel)
		for side: float in [-1.0, 1.0]:
			Kit.add(root, Kit.lathe(tyre_profile, 32), rubber, Vector3(side * 0.86, 0.34, z), Vector3(0, 0, 90))
			_disc(root, Vector3(side * 1.008, 0.34, z), 0.19, 0.035, alloy)
			_disc(root, Vector3(side * 1.032, 0.34, z), 0.078, 0.05, steel)
			Kit.rbox(root, Vector3(0.35, 0.065, 0.85), Vector3(side * 0.84, 0.72, z), body, 0.03)
	# Side service doors: visible seams, recessed pull handles, louvres and large IDs.
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.025, 0.80, 2.19), Vector3(side * 0.79, 1.16, 0.30), steel, 0.011)
		Kit.rbox(root, Vector3(0.035, 0.75, 2.14), Vector3(side * 0.81, 1.17, 0.30), body, 0.016)
		Kit.rbox(root, Vector3(0.04, 0.65, 0.40), Vector3(side * 0.835, 1.18, -0.52), steel, 0.018)
		for slat: int in range(6):
			Kit.rbox(root, Vector3(0.035, 0.028, 0.34), Vector3(side * 0.86, 0.94 + float(slat) * 0.088, -0.52), alloy, 0.012, false)
		Kit.rbox(root, Vector3(0.055, 0.10, 0.22), Vector3(side * 0.85, 1.40, 1.07), steel, 0.035)
		Kit.rbox(root, Vector3(0.045, 0.026, 0.14), Vector3(side * 0.88, 1.40, 1.07), Kit.brass(), 0.012, false)
		var text_ink: Color = Kit.CREAM if scheme == 3 else Kit.CHARCOAL
		_caption(root, "GPU 90 kVA", Vector3(side * 0.838, 1.32, 0.41), side * 90.0, 0.235, text_ink)
		_caption(root, "GROUND POWER" if side > 0 else "Nguồn điện", Vector3(side * 0.838, 1.08, 0.41), side * 90.0, 0.14, text_ink)
		_caption(root, "電源 · 电源" if side > 0 else "Énergie · Energía", Vector3(side * 0.838, 0.88, 0.41), side * 90.0, 0.14, text_ink)
	# Front instrumentation is shaded by the cap; lenses sit inside dark bezels.
	Kit.rbox(root, Vector3(0.90, 0.46, 0.05), Vector3(0, 1.26, 1.559), steel, 0.05)
	Kit.rbox(root, Vector3(0.41, 0.22, 0.018), Vector3(-0.15, 1.32, 1.594), Kit.washi(Kit.SAGE, 0.7, "gpu_display"), 0.02, false)
	_caption(root, "400 Hz", Vector3(-0.15, 1.32, 1.607), 0, 0.115, Kit.CHARCOAL)
	Kit.rbox(root, Vector3(0.10, 0.10, 0.05), Vector3(0.29, 1.30, 1.605), Kit.paint(Kit.CLAY), 0.04)
	for x: float in [-0.58, 0.58]:
		Kit.rbox(root, Vector3(0.26, 0.18, 0.085), Vector3(x, 0.89, 1.56), steel, 0.05)
		Kit.rbox(root, Vector3(0.20, 0.11, 0.035), Vector3(x, 0.89, 1.615), lamp, 0.035, false)
	Kit.rbox(root, Vector3(1.77, 0.14, 0.17), Vector3(0, 0.55, 1.69), rubber, 0.06)
	# A-frame towing tongue, towing eye and warm oak insulated parking grip.
	_rod(root, Vector3(-0.61, 0.43, 1.56), Vector3(0, 0.35, 2.70), 0.052, steel)
	_rod(root, Vector3(0.61, 0.43, 1.56), Vector3(0, 0.35, 2.70), 0.052, steel)
	var eye: PackedVector2Array = PackedVector2Array([Vector2(0.067, -0.026), Vector2(0.13, -0.026), Vector2(0.14, 0), Vector2(0.13, 0.026), Vector2(0.067, 0.026), Vector2(0.067, -0.026)])
	Kit.add(root, Kit.lathe(eye, 24), alloy, Vector3(0, 0.35, 2.77))
	_rod(root, Vector3(0, 0.37, 2.20), Vector3(0, 0.80, 2.02), 0.035, steel)
	Kit.rbox(root, Vector3(0.38, 0.07, 0.07), Vector3(0, 0.81, 2.02), Kit.wood(Kit.OAK, "gpu_grip"), 0.032)
	# Open reel cradle, hollow flanges and eleven distinct heavy cable windings.
	for x: float in [-0.58, 0.58]:
		_rod(root, Vector3(x, 0.66, -1.73), Vector3(x, 1.35, -1.36), 0.045, steel)
		_rod(root, Vector3(x, 0.66, -1.00), Vector3(x, 1.35, -1.36), 0.045, steel)
		var flange: PackedVector2Array = PackedVector2Array([Vector2(0.10, -0.035), Vector2(0.55, -0.035), Vector2(0.61, -0.02), Vector2(0.63, 0), Vector2(0.61, 0.02), Vector2(0.55, 0.035), Vector2(0.10, 0.035), Vector2(0.10, -0.035)])
		Kit.add(root, Kit.lathe(flange, 40), stripe, Vector3(x, 1.35, -1.36), Vector3(0, 0, 90))
		_disc(root, Vector3(x * 1.09, 1.35, -1.36), 0.115, 0.07, alloy)
	_rod(root, Vector3(-0.60, 1.35, -1.36), Vector3(0.60, 1.35, -1.36), 0.28, rubber)
	var wind: PackedVector3Array = PackedVector3Array()
	for i: int in range(353):
		var t: float = float(i) / 352.0
		var angle: float = t * TAU * 11.0
		wind.append(Vector3(-0.49 + t * 0.98, 1.35 + cos(angle) * 0.48, -1.36 + sin(angle) * 0.48))
	Kit.add(root, _tube("wind", wind, 0.046), rubber, Vector3.ZERO)
	var tail: PackedVector3Array = PackedVector3Array([Vector3(0.49, 1.83, -1.36), Vector3(0.72, 1.68, -1.55), Vector3(0.84, 1.34, -1.66), Vector3(0.88, 0.94, -1.64), Vector3(0.89, 0.78, -1.45), Vector3(0.88, 0.83, -1.20), Vector3(0.87, 1.08, -1.08)])
	Kit.add(root, _tube("tail", tail, 0.047), rubber, Vector3.ZERO)
	Kit.rbox(root, Vector3(0.16, 0.29, 0.14), Vector3(0.87, 1.20, -1.08), steel, 0.04)
	Kit.rbox(root, Vector3(0.18, 0.08, 0.16), Vector3(0.87, 1.35, -1.08), stripe, 0.025)
	# Reel crank and high amber beacon establish the silhouette at apron distances.
	_rod(root, Vector3(-0.71, 1.35, -1.36), Vector3(-0.71, 1.57, -1.36), 0.025, alloy)
	_rod(root, Vector3(-0.71, 1.57, -1.36), Vector3(-0.87, 1.57, -1.36), 0.035, rubber)
	_rod(root, Vector3(0.51, 1.69, 0.89), Vector3(0.51, 1.84, 0.89), 0.04, steel)
	var beacon: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(0.09, 0), Vector2(0.09, 0.13), Vector2(0.07, 0.17), Vector2(0, 0.18)])
	Kit.add(root, Kit.lathe(beacon, 24), amber, Vector3(0.51, 1.84, 0.89), Vector3.ZERO, false)
	return root


static func _disc(parent: Node3D, at: Vector3, radius: float, depth: float, material: Material) -> void:
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0, -depth * 0.5), Vector2(radius * 0.92, -depth * 0.5), Vector2(radius, 0), Vector2(radius * 0.92, depth * 0.5), Vector2(0, depth * 0.5)])
	Kit.add(parent, Kit.lathe(profile, 24), material, at, Vector3(0, 0, 90))


static func _rod(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var length_m: float = start.distance_to(end)
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0, -length_m * 0.5), Vector2(radius, -length_m * 0.5), Vector2(radius, length_m * 0.5), Vector2(0, length_m * 0.5)])
	var part: MeshInstance3D = Kit.add(parent, Kit.lathe(profile, 16), material, (start + end) * 0.5)
	part.quaternion = Quaternion(Vector3.UP, (end - start).normalized())


static func _caption(parent: Node3D, text: String, at: Vector3, yaw: float, height_m: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signs.font()
	label.text = text
	label.font_size = 80
	label.pixel_size = height_m / 80.0
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.rotation_degrees.y = yaw
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _tube(key: String, points: PackedVector3Array, radius: float) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	const SIDES: int = 8
	for i: int in range(points.size()):
		var tangent: Vector3 = (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var reference: Vector3 = Vector3.UP if absf(tangent.y) < 0.90 else Vector3.RIGHT
		var u: Vector3 = tangent.cross(reference).normalized()
		var v: Vector3 = tangent.cross(u).normalized()
		for j: int in range(SIDES):
			var angle: float = TAU * float(j) / float(SIDES)
			var normal: Vector3 = u * cos(angle) + v * sin(angle)
			vertices.append(points[i] + normal * radius)
			normals.append(normal)
			if i < points.size() - 1:
				var a: int = i * SIDES + j
				var b: int = i * SIDES + (j + 1) % SIDES
				indices.append_array(PackedInt32Array([a, b, a + SIDES, b, b + SIDES, a + SIDES]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_meshes[key] = mesh
	return mesh
