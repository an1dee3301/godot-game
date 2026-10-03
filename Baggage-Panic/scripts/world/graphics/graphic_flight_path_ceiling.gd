extends RefCounted
## Suspended flight trails: floor-relative origin, with artwork at terminal ceiling height.

const KIT = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "FlightPathCeiling"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var brass: StandardMaterial3D = KIT.brass()
	var glow: StandardMaterial3D = KIT.washi(KIT.CREAM, 3.2, "flight_path_opal")
	var steel: StandardMaterial3D = KIT.metal(KIT.CHARCOAL, 0.48, 0.85, "flight_path_wire")
	var mirror: float = -1.0 if posmod(variant, 2) == 1 else 1.0
	# The oak ceiling spine conceals drivers and suspension anchors.
	KIT.rbox(root, Vector3(14.3, 0.16, 0.24), Vector3(0.0, 11.55, 0.0), KIT.wood(), 0.07)
	KIT.rbox(root, Vector3(14.0, 0.025, 0.19), Vector3(0.0, 11.455, 0.0), steel, 0.009, false)
	var cables := SurfaceTool.new()
	cables.begin(Mesh.PRIMITIVE_TRIANGLES)
	var waypoints := PackedVector3Array()
	for route in 5:
		var points := PackedVector3Array()
		var light_points := PackedVector3Array()
		for step in 97:
			var t: float = float(step) / 96.0
			var p: Vector3 = _path(route, t, mirror)
			points.append(p)
			light_points.append(p + Vector3(0.0, -0.036, 0.0))
		var route_key: String = "route_%d_%d" % [route, posmod(variant, 2)]
		KIT.add(root, _tube(points, 0.035, route_key), brass, Vector3.ZERO, Vector3.ZERO, false)
		KIT.add(root, _tube(light_points, 0.009, route_key + "_light"), glow, Vector3.ZERO, Vector3.ZERO, false)
		for stop in 7:
			var t: float = float(stop) / 6.0
			waypoints.append(_path(route, t, mirror))
		for anchor_t: float in [0.16, 0.5, 0.84]:
			var lower: Vector3 = _path(route, anchor_t, mirror)
			_append_tube(cables, PackedVector3Array([lower, Vector3(lower.x, 11.45, lower.z)]), 0.006, 6)
	var cable_key: String = "suspension_%d" % posmod(variant, 2)
	if not _meshes.has(cable_key):
		_meshes[cable_key] = cables.commit()
	var cable_mesh: ArrayMesh = _meshes[cable_key]
	KIT.add(root, cable_mesh, steel, Vector3.ZERO, Vector3.ZERO, false)
	# Turned brass sockets surrounding opal globes; no individual lights per waypoint.
	var socket: ArrayMesh = KIT.lathe(PackedVector2Array([
		Vector2(0.0, -0.055), Vector2(0.07, -0.055), Vector2(0.095, -0.035),
		Vector2(0.095, 0.035), Vector2(0.07, 0.055), Vector2(0.0, 0.055)]), 16)
	_instances(root, socket, brass, waypoints, "TurnedBrassSockets")
	if not _meshes.has("opal"):
		var sphere := SphereMesh.new()
		sphere.radius = 0.085
		sphere.height = 0.17
		sphere.radial_segments = 16
		sphere.rings = 8
		_meshes["opal"] = sphere
	var opal: SphereMesh = _meshes["opal"]
	var globes := PackedVector3Array()
	for p: Vector3 in waypoints:
		globes.append(p + Vector3(0.0, -0.075, 0.0))
	_instances(root, opal, glow, globes, "LuminousWaypoints")
	# A generous, softly rounded caption panel gives the sculpture its international context.
	KIT.rbox(root, Vector3(8.5, 1.9, 0.15), Vector3(0.0, 8.15, 1.02), KIT.wood(KIT.WALNUT, "walnut"), 0.07)
	KIT.rbox(root, Vector3(8.34, 1.74, 0.045), Vector3(0.0, 8.15, 1.113), KIT.stone(KIT.PLASTER, 0.8, "flight_path_plaster"), 0.02)
	KIT.rbox(root, Vector3(7.9, 0.018, 0.025), Vector3(0.0, 7.42, 1.148), brass, 0.007, false)
	for x: float in [-3.7, 3.7]:
		KIT.rbox(root, Vector3(0.023, 2.3, 0.023), Vector3(x, 10.25, 1.02), brass, 0.01, false)
	var artwork_key: String = "route_tile_%d" % posmod(variant, 2)
	if not _meshes.has("tile"):
		var tile := QuadMesh.new()
		tile.size = Vector2(1.45, 1.45)
		_meshes["tile"] = tile
	var tile_mesh: QuadMesh = _meshes["tile"]
	KIT.add(root, tile_mesh, _artwork(artwork_key, variant), Vector3(-3.23, 8.15, 1.143), Vector3.ZERO, false)
	var welcome: Array = SIGNS.TEXT["welcome"]
	_caption(root, str(welcome[0]), Vector3(0.65, 8.62, 1.151), 0.0065, 96)
	_caption(root, "%s     %s" % [welcome[1], welcome[2]], Vector3(0.65, 8.11, 1.151), 0.0048, 86)
	_caption(root, "%s · %s · %s" % [welcome[3], welcome[4], welcome[5]], Vector3(0.65, 7.68, 1.151), 0.0040, 80)
	return root


static func _path(route: int, t: float, mirror: float) -> Vector3:
	var lane: float = float(route)
	var span: float = 13.85 - lane * 0.36
	var lift: float = 1.2 + lane * 0.12
	return Vector3((t - 0.5) * span, 9.2 + lane * 0.1 + sin(t * PI) * lift,
		mirror * ((lane - 2.0) * 0.47 + sin(t * TAU) * (0.19 + lane * 0.04)))


static func _tube(points: PackedVector3Array, radius: float, key: String) -> ArrayMesh:
	if not _meshes.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_append_tube(st, points, radius, 10)
		_meshes[key] = st.commit()
	var mesh: ArrayMesh = _meshes[key]
	return mesh


static func _append_tube(st: SurfaceTool, points: PackedVector3Array, radius: float, sides: int) -> void:
	# A transported ring frame avoids polygonal segments and maintains smooth highlights.
	for i in points.size() - 1:
		var tangent_a: Vector3 = (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var tangent_b: Vector3 = (points[mini(i + 2, points.size() - 1)] - points[i]).normalized()
		var reference: Vector3 = Vector3.UP if absf(tangent_a.y) < 0.95 else Vector3.RIGHT
		var side_a: Vector3 = tangent_a.cross(reference).normalized()
		var side_b: Vector3 = tangent_b.cross(reference).normalized()
		var up_a: Vector3 = tangent_a.cross(side_a).normalized()
		var up_b: Vector3 = tangent_b.cross(side_b).normalized()
		for s in sides:
			var angle_a: float = TAU * float(s) / float(sides)
			var angle_b: float = TAU * float(s + 1) / float(sides)
			var normals: Array[Vector3] = [side_a * cos(angle_a) + up_a * sin(angle_a),
				side_a * cos(angle_b) + up_a * sin(angle_b),
				side_b * cos(angle_a) + up_b * sin(angle_a),
				side_b * cos(angle_b) + up_b * sin(angle_b)]
			var vertices: Array[Vector3] = [points[i] + normals[0] * radius,
				points[i] + normals[1] * radius, points[i + 1] + normals[2] * radius,
				points[i + 1] + normals[3] * radius]
			for index: int in [0, 2, 1, 1, 2, 3]:
				st.set_normal(normals[index])
				st.add_vertex(vertices[index])


static func _instances(parent: Node3D, mesh: Mesh, material: Material, positions: PackedVector3Array, title: String) -> void:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = positions.size()
	for i in positions.size():
		batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
	var node := MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = batch
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)


static func _caption(parent: Node3D, words: String, at: Vector3, pixel_metres: float, size: int) -> void:
	var label := Label3D.new()
	label.text = words
	label.font = SIGNS.font()
	label.font_size = size
	label.pixel_size = pixel_metres
	label.modulate = KIT.CHARCOAL
	label.outline_size = 0
	label.no_depth_test = false
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _artwork(key: String, variant: int) -> StandardMaterial3D:
	if _materials.has(key):
		var cached: StandardMaterial3D = _materials[key]
		return cached
	# A bold abstract route-map medallion, with generous paper-coloured margins.
	var image := Image.create(384, 384, false, Image.FORMAT_RGBA8)
	image.fill(KIT.PLASTER)
	var accent: Color = KIT.SAGE if posmod(variant, 2) == 0 else KIT.CLAY
	for y in 384:
		for x in 384:
			var p := Vector2(float(x) / 383.0, float(y) / 383.0)
			var ink: Color = KIT.PLASTER
			if p.distance_to(Vector2(0.5, 0.5)) < 0.42:
				ink = accent
			for lane in 3:
				var centre := Vector2(0.25, 0.82)
				var radius: float = 0.35 + float(lane) * 0.14
				if p.x > 0.15 and p.x < 0.84 and p.y > 0.14 and p.y < 0.78 and absf(p.distance_to(centre) - radius) < 0.013:
					ink = KIT.CREAM
			for dot: Vector2 in [Vector2(0.25, 0.19), Vector2(0.67, 0.58), Vector2(0.6, 0.36)]:
				if p.distance_to(dot) < 0.035:
					ink = KIT.CHARCOAL
			image.set_pixel(x, y, ink)
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.roughness = 0.92
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materials[key] = material
	return material
