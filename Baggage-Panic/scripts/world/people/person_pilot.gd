extends RefCounted
## A quietly cheerful captain, with a woven uniform and a hand-carried flight bag.
## Metres; shoes touch y = 0, the face and cap peak point toward +Z.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var style: int = posmod(variant, 3)
	var root: Node3D = Node3D.new()
	root.name = "Pilot"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var navies: Array[Color] = [Color(0.075, 0.115, 0.18), Color(0.12, 0.18, 0.255), Color(0.105, 0.15, 0.185)]
	var skins: Array[Color] = [Color(0.72, 0.46, 0.30), Color(0.88, 0.65, 0.46), Color(0.43, 0.265, 0.19)]
	var hairs: Array[Color] = [Color(0.12, 0.085, 0.065), Color(0.23, 0.14, 0.09), Color(0.48, 0.46, 0.41)]
	var bag_colors: Array[Color] = [Kit.WALNUT.darkened(0.18), Kit.CHARCOAL, Kit.CLAY.darkened(0.3)]
	var navy: Color = navies[style]
	var uniform: StandardMaterial3D = Kit.fabric(navy, "pilot_navy_%d" % style)
	var lapel: StandardMaterial3D = Kit.fabric(navy.lightened(0.075), "pilot_lapel_%d" % style)
	var trousers: StandardMaterial3D = Kit.fabric(navy.darkened(0.12), "pilot_trousers_%d" % style)
	var shirt: StandardMaterial3D = Kit.fabric(Kit.CREAM, "pilot_shirt")
	var gold: StandardMaterial3D = Kit.fabric(Kit.OCHRE.lightened(0.12), "pilot_gold_braid")
	var skin: StandardMaterial3D = Kit.paint(skins[style], 0.83)
	var hair: StandardMaterial3D = Kit.paint(hairs[style], 0.93)
	var leather: StandardMaterial3D = Kit.paint(bag_colors[style], 0.48)
	var shoe: StandardMaterial3D = Kit.paint(Color(0.055, 0.048, 0.042), 0.3)
	var rubber: StandardMaterial3D = Kit.paint(Kit.CHARCOAL.darkened(0.62), 0.92)
	var brass: StandardMaterial3D = Kit.brass()
	var sphere: SphereMesh = _sphere()

	# Rounded Oxford shoes: distinct soles establish exact floor contact.
	var foot_places: Array[Transform3D] = [
		_pose(Vector3(-0.105, 0.022, 0.045), Vector3(0.085, 0.022, 0.155)),
		_pose(Vector3(0.105, 0.022, 0.012), Vector3(0.085, 0.022, 0.155)),
	]
	_part(root, "Soles", _merge("soles", [sphere, sphere], foot_places), rubber)
	var shoe_places: Array[Transform3D] = [
		_pose(Vector3(-0.105, 0.078, 0.045), Vector3(0.083, 0.058, 0.151)),
		_pose(Vector3(0.105, 0.078, 0.012), Vector3(0.083, 0.058, 0.151)),
	]
	_part(root, "PolishedShoes", _merge("shoes", [sphere, sphere], shoe_places), shoe)
	var leg: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.115), Vector2(0.069, 0.115), Vector2(0.077, 0.132),
		Vector2(0.071, 0.17), Vector2(0.075, 0.39), Vector2(0.084, 0.58),
		Vector2(0.098, 0.79), Vector2(0.088, 0.855), Vector2(0.0, 0.855),
	]), 12)
	_part(root, "TailoredTrousers", _merge("legs", [leg, leg], [
		_pose(Vector3(-0.1, 0.0, 0.018), Vector3(1.0, 1.0, 0.92)),
		_pose(Vector3(0.1, 0.0, -0.012), Vector3(1.0, 1.0, 0.92)),
	]), trousers)

	var jacket_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.77), Vector2(0.17, 0.77), Vector2(0.19, 0.795),
		Vector2(0.182, 0.89), Vector2(0.168, 1.025), Vector2(0.205, 1.235),
		Vector2(0.225, 1.285), Vector2(0.2, 1.33), Vector2(0.08, 1.355),
		Vector2(0.0, 1.355),
	]), 16)
	var jacket: MeshInstance3D = _part(root, "SoftShoulderedJacket", jacket_mesh, uniform)
	jacket.scale.z = 0.72
	var shirt_mesh: ArrayMesh = _prism("shirt_front", PackedVector2Array([
		Vector2(-0.077, 0.077), Vector2(0.077, 0.077), Vector2(0.0, -0.083),
	]), 0.014)
	_part(root, "CreamShirt", shirt_mesh, shirt, Vector3(0.0, 1.255, 0.146))
	var collar_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.064, 0.0), Vector2(0.077, 0.012), Vector2(0.07, 0.039),
		Vector2(0.062, 0.04), Vector2(0.064, 0.0),
	]), 16)
	_part(root, "RaisedLinenCollar", collar_mesh, shirt, Vector3(0.0, 1.337, 0.0))
	var lapel_mesh: ArrayMesh = _prism("lapel", PackedVector2Array([
		Vector2(0.064, 1.333), Vector2(0.14, 1.298), Vector2(0.108, 1.244),
		Vector2(0.123, 1.225), Vector2(0.025, 1.109), Vector2(0.047, 1.242),
	]), 0.015)
	var lapel_right: MeshInstance3D = _part(root, "RightNotchedLapel", lapel_mesh, lapel, Vector3(0.0, 0.0, 0.145))
	lapel_right.rotation_degrees.y = 13.0
	var lapel_left: MeshInstance3D = _part(root, "LeftNotchedLapel", lapel_mesh, lapel, Vector3(0.0, 0.0, 0.145))
	lapel_left.scale.x = -1.0
	lapel_left.rotation_degrees.y = -13.0
	var tie_mesh: ArrayMesh = _prism("tie", PackedVector2Array([
		Vector2(-0.017, 0.072), Vector2(0.017, 0.072), Vector2(0.011, 0.044),
		Vector2(0.02, -0.056), Vector2(0.0, -0.079), Vector2(-0.02, -0.056), Vector2(-0.011, 0.044),
	]), 0.013)
	var tie_color: Color = Kit.INDIGO.darkened(0.42) if style != 1 else Kit.SAGE.darkened(0.38)
	_part(root, "Tie", tie_mesh, Kit.fabric(tie_color, "pilot_tie_%d" % style), Vector3(0.0, 1.255, 0.161))

	# Arms lean out slightly; cuff bands share each sleeve's basis, so they wrap properly.
	var right_wrist: Vector3 = Vector3(0.345, 0.861, 0.03)
	var left_wrist: Vector3 = Vector3(-0.292, 0.87, 0.035)
	var right_arm: Transform3D = _arm_pose(right_wrist, Vector3(0.213, 1.287, 0.0))
	var left_arm: Transform3D = _arm_pose(left_wrist, Vector3(-0.213, 1.287, 0.0))
	var sleeve_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.061, 0.0), Vector2(0.063, 0.025),
		Vector2(0.065, 0.17), Vector2(0.079, 0.33), Vector2(0.082, 0.395),
		Vector2(0.061, 0.44), Vector2(0.0, 0.445),
	]), 12)
	var sleeves: MeshInstance3D = _part(root, "Sleeves", _merge("sleeves", [sleeve_mesh, sleeve_mesh], [right_arm, left_arm]), uniform)
	sleeves.name = "RelaxedSleeves"
	var braid_meshes: Array[Mesh] = []
	var braid_places: Array[Transform3D] = []
	for band: int in 4:
		var height: float = 0.025 + float(band) * 0.023
		var ring: ArrayMesh = Kit.lathe(PackedVector2Array([
			Vector2(0.063, height), Vector2(0.066, height + 0.003),
			Vector2(0.066, height + 0.012), Vector2(0.063, height + 0.015),
		]), 12)
		braid_meshes.append(ring)
		braid_places.append(right_arm)
		braid_meshes.append(ring)
		braid_places.append(left_arm)
	_part(root, "FourCaptainStripes", _merge("cuff_braid", braid_meshes, braid_places), gold)
	var cuff_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.05, -0.021), Vector2(0.058, -0.019), Vector2(0.058, 0.004), Vector2(0.05, 0.008),
	]), 12)
	_part(root, "ShirtCuffs", _merge("cuffs", [cuff_mesh, cuff_mesh], [right_arm, left_arm]), shirt)

	var skin_parts: Array[Mesh] = [sphere, sphere, sphere, sphere, sphere, sphere, sphere]
	var skin_places: Array[Transform3D] = [
		_pose(Vector3(0.0, 1.365, 0.0), Vector3(0.061, 0.071, 0.058)),
		_pose(Vector3(0.0, 1.512, 0.006), Vector3(0.135, 0.174, 0.121)),
		_pose(Vector3(-0.133, 1.505, 0.001), Vector3(0.025, 0.039, 0.026)),
		_pose(Vector3(0.133, 1.505, 0.001), Vector3(0.025, 0.039, 0.026)),
		_pose(Vector3(0.0, 1.493, 0.125), Vector3(0.022, 0.026, 0.027)),
		right_arm * _pose(Vector3(0.0, -0.045, 0.0), Vector3(0.036, 0.05, 0.037)),
		left_arm * _pose(Vector3(0.0, -0.045, 0.0), Vector3(0.036, 0.052, 0.037)),
	]
	_part(root, "FaceEarsAndHands", _merge("skin", skin_parts, skin_places), skin)
	_part(root, "KindEyes", _merge("eyes", [sphere, sphere], [
		_pose(Vector3(-0.047, 1.529, 0.119), Vector3(0.009, 0.014, 0.006)),
		_pose(Vector3(0.047, 1.529, 0.119), Vector3(0.009, 0.014, 0.006)),
	]), Kit.paint(Kit.CHARCOAL.darkened(0.6), 0.84))
	_part(root, "SmallSmile", _prism("smile", PackedVector2Array([
		Vector2(-0.02, 0.006), Vector2(0.0, 0.0), Vector2(0.02, 0.006),
		Vector2(0.01, -0.004), Vector2(-0.01, -0.004),
	]), 0.003), Kit.paint(skins[style].darkened(0.44), 0.9), Vector3(0.0, 1.453, 0.121))
	_part(root, "NeatHair", _hair_shell(), hair, Vector3(0.0, 1.512, 0.006))
	if style == 1:
		var bun: MeshInstance3D = _part(root, "LowHairBun", sphere, hair, Vector3(0.0, 1.461, -0.121))
		bun.scale = Vector3(0.064, 0.064, 0.057)

	# An oval cloth crown, dark leather band and a projecting rounded peak.
	var crown_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, 1.659), Vector2(0.134, 1.659), Vector2(0.16, 1.693),
		Vector2(0.172, 1.729), Vector2(0.158, 1.756), Vector2(0.119, 1.774), Vector2(0.0, 1.78),
	]), 20)
	var crown: MeshInstance3D = _part(root, "PeakedCapCrown", crown_mesh, uniform)
	crown.scale.z = 0.85
	var hat_band: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.132, 0.0), Vector2(0.138, 0.009), Vector2(0.139, 0.044), Vector2(0.135, 0.051),
	]), 20)
	var band_node: MeshInstance3D = _part(root, "CapLeatherBand", hat_band, shoe, Vector3(0.0, 1.646, 0.0))
	band_node.scale.z = 0.88
	var peak: MeshInstance3D = _part(root, "CapPeak", sphere, shoe, Vector3(0.0, 1.652, 0.09))
	peak.scale = Vector3(0.144, 0.013, 0.138)
	peak.rotation_degrees.x = -5.0

	# Use the shared international airplane silhouette as a raised brass insignia.
	var badge: ArrayMesh = _airplane_badge()
	var brass_meshes: Array[Mesh] = [badge, badge, sphere, sphere, sphere, sphere]
	var brass_places: Array[Transform3D] = [
		_pose(Vector3(0.0, 1.716, 0.145), Vector3(0.056, 0.049, 1.0)),
		_pose(Vector3(-0.115, 1.243, 0.153), Vector3(0.056, 0.032, 1.0)),
		_pose(Vector3(-0.047, 1.045, 0.127), Vector3(0.009, 0.009, 0.005)),
		_pose(Vector3(0.047, 1.045, 0.127), Vector3(0.009, 0.009, 0.005)),
		_pose(Vector3(-0.047, 0.955, 0.128), Vector3(0.009, 0.009, 0.005)),
		_pose(Vector3(0.047, 0.955, 0.128), Vector3(0.009, 0.009, 0.005)),
	]
	_part(root, "BrassInsigniaAndButtons", _merge("brass_uniform", brass_meshes, brass_places), brass)
	var cord: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.14, 0.0), Vector2(0.142, 0.003), Vector2(0.142, 0.009), Vector2(0.14, 0.012),
	]), 20)
	var cord_node: MeshInstance3D = _part(root, "GoldCapCord", cord, gold, Vector3(0.0, 1.653, 0.0))
	cord_node.scale.z = 0.9

	# Soft leather flight bag with a rolled edge, front document pocket and arched handle.
	var bag_at: Vector3 = Vector3(0.37, 0.586, 0.035)
	var bag: MeshInstance3D = Kit.rbox(root, Vector3(0.35, 0.296, 0.168), bag_at, leather, 0.052)
	bag.name = "FlightBag"
	var welt: MeshInstance3D = Kit.rbox(root, Vector3(0.328, 0.272, 0.015), bag_at + Vector3(0.0, 0.0, 0.082), Kit.paint(bag_colors[style].lightened(0.22), 0.7), 0.007)
	welt.name = "RaisedBagWelt"
	var pocket: MeshInstance3D = Kit.rbox(root, Vector3(0.303, 0.244, 0.018), bag_at + Vector3(0.0, -0.002, 0.092), leather, 0.008)
	pocket.name = "DocumentPocket"
	var handle_mesh: ArrayMesh = _prism("bag_handle", PackedVector2Array([
		Vector2(-0.075, 0.0), Vector2(-0.075, 0.06), Vector2(-0.055, 0.088),
		Vector2(0.055, 0.088), Vector2(0.075, 0.06), Vector2(0.075, 0.0),
		Vector2(0.057, 0.0), Vector2(0.057, 0.054), Vector2(0.046, 0.07),
		Vector2(-0.046, 0.07), Vector2(-0.057, 0.054), Vector2(-0.057, 0.0),
	]), 0.026)
	_part(root, "GrippedLeatherHandle", handle_mesh, leather, Vector3(0.37, 0.731, 0.03))
	var buckle: ArrayMesh = Kit.rounded_box(Vector3(0.027, 0.024, 0.016), 0.006, 2)
	var zipper: ArrayMesh = Kit.rounded_box(Vector3(0.228, 0.005, 0.006), 0.002, 2)
	_part(root, "BagBrassHardware", _merge("bag_hardware", [buckle, buckle, zipper, sphere], [
		_pose(Vector3(0.297, 0.729, 0.046)), _pose(Vector3(0.443, 0.729, 0.046)),
		_pose(Vector3(0.37, 0.662, 0.141)), _pose(Vector3(0.456, 0.653, 0.146), Vector3(0.006, 0.013, 0.004)),
	]), brass)
	if style != 2:
		var tag: MeshInstance3D = Kit.rbox(root, Vector3(0.043, 0.073, 0.008), Vector3(0.443, 0.702, 0.13), Kit.fabric(Kit.SAGE if style == 0 else Kit.CLAY, "pilot_tag_%d" % style), 0.004)
		tag.name = "LinenLuggageTag"
		tag.rotation_degrees.z = -12.0
	else:
		var watch: MeshInstance3D = _part(root, "BrassWristwatch", sphere, brass)
		watch.transform = left_arm * _pose(Vector3(0.0, -0.018, 0.055), Vector3(0.019, 0.022, 0.007))
	return root


static func _part(parent: Node3D, label: String, mesh: Mesh, material: Material, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var part: MeshInstance3D = Kit.add(parent, mesh, material, at)
	part.name = label
	return part


static func _sphere() -> SphereMesh:
	if _meshes.has("sphere"):
		return _meshes["sphere"] as SphereMesh
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	_meshes["sphere"] = mesh
	return mesh


static func _pose(at: Vector3, scale_by: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_scale(scale_by), at)


static func _arm_pose(wrist: Vector3, shoulder: Vector3) -> Transform3D:
	var direction: Vector3 = (shoulder - wrist).normalized()
	return Transform3D(Basis(Quaternion(Vector3.UP, direction)), wrist)


static func _merge(key: String, parts: Array[Mesh], poses: Array[Transform3D]) -> ArrayMesh:
	var cache_key: String = "merged:" + key
	if _meshes.has(cache_key):
		return _meshes[cache_key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in parts.size():
		surface.append_from(parts[index], 0, poses[index])
	var mesh: ArrayMesh = surface.commit()
	_meshes[cache_key] = mesh
	return mesh


static func _prism(key: String, outline: PackedVector2Array, depth: float) -> ArrayMesh:
	var cache_key: String = "prism:" + key
	if _meshes.has(cache_key):
		return _meshes[cache_key] as ArrayMesh
	var polygon: PackedVector2Array = outline.duplicate()
	if Geometry2D.is_polygon_clockwise(polygon):
		polygon.reverse()
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in range(0, indices.size(), 3):
		for face: int in [-1, 1]:
			for corner: int in 3:
				var order: int = 2 - corner if face == 1 else corner
				var vertex: Vector2 = polygon[indices[index + order]]
				surface.set_normal(Vector3(0.0, 0.0, float(face)))
				surface.set_uv(vertex)
				surface.add_vertex(Vector3(vertex.x, vertex.y, float(face) * depth * 0.5))
	for index: int in polygon.size():
		var start: Vector2 = polygon[index]
		var end: Vector2 = polygon[(index + 1) % polygon.size()]
		var edge: Vector2 = end - start
		var normal: Vector3 = Vector3(edge.y, -edge.x, 0.0).normalized()
		var corners: Array[Vector3] = [
			Vector3(start.x, start.y, -depth * 0.5), Vector3(start.x, start.y, depth * 0.5),
			Vector3(end.x, end.y, depth * 0.5), Vector3(end.x, end.y, -depth * 0.5),
		]
		for corner: int in [0, 1, 2, 0, 2, 3]:
			surface.set_normal(normal)
			surface.set_uv(Vector2(corners[corner].x, corners[corner].y))
			surface.add_vertex(corners[corner])
	var mesh: ArrayMesh = surface.commit()
	_meshes[cache_key] = mesh
	return mesh


static func _airplane_badge() -> ArrayMesh:
	if _meshes.has("prism:shared_airplane"):
		return _meshes["prism:shared_airplane"] as ArrayMesh
	var departures: Array = Signs.TEXT["departures"]
	var shapes: Array = Signs._icon_shapes(str(departures[6]))
	var shape: Array = shapes[0]
	var outline: PackedVector2Array = shape[1]
	var centred: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in outline:
		centred.append(Vector2(point.x - 0.5, 0.5 - point.y))
	return _prism("shared_airplane", centred, 0.004)


static func _hair_shell() -> ArrayMesh:
	if _meshes.has("hair_shell"):
		return _meshes["hair_shell"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment: int in 16:
		for row: int in 6:
			var points: Array[Vector3] = []
			for offset: Vector2i in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var theta: float = deg_to_rad(56.0 + 248.0 * float(segment + offset.x) / 16.0)
				var phi: float = deg_to_rad(27.0 + 103.0 * float(row + offset.y) / 6.0)
				points.append(Vector3(sin(phi) * sin(theta) * 0.139, cos(phi) * 0.179, sin(phi) * cos(theta) * 0.126))
			for corner: int in [0, 2, 1, 0, 3, 2]:
				surface.add_vertex(points[corner])
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes["hair_shell"] = mesh
	return mesh
