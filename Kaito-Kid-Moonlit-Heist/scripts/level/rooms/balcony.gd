extends RefCounted
## Storm balcony: a composed escape vista with one clear central route.

static var _baluster: Mesh
static var _leaf: ArrayMesh
static var _rail_meshes: Dictionary = {}


static func dress(kit: LevelKit, room_id: String) -> void:
	# Room is x=-12..12, z=-40..-30. Keep |x|<3.5 clear gate to glider.
	var wet_stone := kit.pbr("monastery_stone_floor", 2.6, Color(0.34, 0.39, 0.45), 0.46)
	var brass := kit.mat("brass")
	# Broad dark slabs read as rain-wet stone; brass joins catch lightning.
	for x in [-8.7, -2.9, 2.9, 8.7]:
		for z in [-38.075, -35.0, -31.925]:
			_box(kit, room_id, Vector3(x, 0.012, z), Vector3(5.77, 0.018, 3.05), wet_stone)
	for x in [-6.0, 0.0, 6.0]:
		_box(kit, room_id, Vector3(x, 0.024, -34.2), Vector3(0.025, 0.008, 9.15), brass)
	for z in [-35.85, -32.55]:
		_box(kit, room_id, Vector3(0, 0.024, z), Vector3(23.1, 0.008, 0.025), brass)

	# Rail segments have a full-height collision volume, while the visible middle is open balusters.
	_rail(kit, room_id, Vector3(-7.12, 0, -39.45), 8.5, true)
	_rail(kit, room_id, Vector3(0, 0, -39.45), 5.2, true)
	_rail(kit, room_id, Vector3(7.12, 0, -39.45), 8.5, true)
	_rail(kit, room_id, Vector3(-11.45, 0, -35.0), 8.8, false)
	_rail(kit, room_id, Vector3(11.45, 0, -35.0), 8.8, false)
	for x in [-11.4, -2.65, 2.65, 11.4]:
		_pier(kit, room_id, Vector3(x, 0, -39.45))
	# Real lamps bracket the vista along the outer balustrade; their short pools
	# reveal wet joints while the cool storm fill keeps the escape path legible.
	for x in [-8.8, 8.8]:
		var lamp := Vector3(x, 0, -38.3)
		kit.model(room_id, "street_lamp_01", Transform3D(Basis.IDENTITY, lamp), 3.38)
		kit.omni(room_id, lamp + Vector3(0, 2.95, 0), Color(1.0, 0.72, 0.43), 1.35, 5.7)
		kit.model(room_id, "planter_box_01", Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(x, 0, -35.2)))
		kit.model(room_id, "potted_plant_02", Transform3D(Basis.IDENTITY, Vector3(x, 0.42, -35.2)), 0.7, "none")
	for x in [-6.7, 6.7]:
		kit.spot(room_id, Vector3(x, 5.4, -30.6), Vector3(x, 0.1, -36.2), Color(0.48, 0.64, 0.94), 0.52, 8.2, 43.0)


static func _rail(kit: LevelKit, id: String, p: Vector3, length: float, along_x: bool) -> void:
	var basis := Basis.IDENTITY if along_x else Basis(Vector3.UP, PI * 0.5)
	var mesh := _rail_mesh(length)
	kit.prop(id, mesh, Transform3D(basis, p), kit.mat("stone"), Vector3(length, 1.13, 0.34))
	if _baluster == null:
		var shape := CylinderMesh.new()
		shape.top_radius = 0.095
		shape.bottom_radius = 0.16
		shape.height = 0.70
		shape.radial_segments = 10
		_baluster = shape
	var balusters: Array = []
	var feet: Array = []
	var capitals: Array = []
	var count := int(floor(length / 0.53))
	for i in count:
		var offset := -length * 0.5 + (float(i) + 0.5) * length / float(count)
		var q := p + (Vector3(offset, 0, 0) if along_x else Vector3(0, 0, -offset))
		balusters.append(Transform3D(Basis.IDENTITY, q + Vector3(0, 0.58, 0)))
		feet.append(Transform3D(Basis.IDENTITY, q + Vector3(0, 0.23, 0)))
		capitals.append(Transform3D(Basis.IDENTITY, q + Vector3(0, 0.93, 0)))
	kit.multi(id, _baluster, balusters, kit.mat("marble_white"))
	var bead := BoxMesh.new()
	bead.size = Vector3(0.27, 0.055, 0.27)
	kit.multi(id, bead, feet, kit.mat("stone"))
	kit.multi(id, bead, capitals, kit.mat("stone"))


static func _rail_mesh(length: float) -> ArrayMesh:
	if _rail_meshes.has(length):
		return _rail_meshes[length]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_box(st, Vector3(0, 0.10, 0), Vector3(length, 0.20, 0.32))
	_append_box(st, Vector3(0, 1.04, 0), Vector3(length + 0.12, 0.18, 0.42))
	_append_box(st, Vector3(0, 1.15, 0), Vector3(length + 0.17, 0.035, 0.48))
	st.generate_normals()
	var mesh := st.commit()
	_rail_meshes[length] = mesh
	return mesh


static func _append_box(st: SurfaceTool, centre: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var corners := [
		centre + Vector3(-h.x, -h.y, -h.z), centre + Vector3(h.x, -h.y, -h.z),
		centre + Vector3(h.x, h.y, -h.z), centre + Vector3(-h.x, h.y, -h.z),
		centre + Vector3(-h.x, -h.y, h.z), centre + Vector3(h.x, -h.y, h.z),
		centre + Vector3(h.x, h.y, h.z), centre + Vector3(-h.x, h.y, h.z)]
	for face in [[0, 3, 2, 1], [4, 5, 6, 7], [0, 4, 7, 3], [1, 2, 6, 5], [3, 7, 6, 2], [0, 1, 5, 4]]:
		for index in [0, 1, 2, 0, 2, 3]:
			st.add_vertex(corners[face[index]])


static func _pier(kit: LevelKit, id: String, p: Vector3) -> void:
	kit.solid(id, p, Vector3(0.55, 1.22, 0.55), kit.mat("stone"))
	_box(kit, id, p + Vector3(0, 1.26, 0), Vector3(0.68, 0.12, 0.68), kit.mat("marble_white"))
	_box(kit, id, p + Vector3(0, 1.35, 0), Vector3(0.73, 0.055, 0.73), kit.mat("brass"))


static func _lantern(kit: LevelKit, id: String, p: Vector3) -> void:
	kit.cylinder_solid(id, p, 0.20, 2.55, kit.mat("iron"), 12)
	_cylinder(kit, id, p + Vector3(0, 2.65, 0), 0.37, 0.17, kit.mat("brass"))
	_box(kit, id, p + Vector3(0, 2.99, 0), Vector3(0.52, 0.55, 0.52), kit.mat("emissive_warm"))
	for x in [-0.28, 0.28]:
		for z in [-0.28, 0.28]:
			_box(kit, id, p + Vector3(x, 2.99, z), Vector3(0.055, 0.62, 0.055), kit.mat("brass"))
	_cylinder(kit, id, p + Vector3(0, 3.32, 0), 0.38, 0.12, kit.mat("iron"))
	kit.omni(id, p + Vector3(0, 2.95, 0), Color(1, 0.73, 0.42), 0.8, 4.4)


static func _planter(kit: LevelKit, id: String, p: Vector3) -> void:
	kit.cylinder_solid(id, p, 0.58, 0.69, kit.mat("marble_black"))
	_cylinder(kit, id, p + Vector3(0, 0.70, 0), 0.61, 0.09, kit.mat("brass"))
	_cylinder(kit, id, p + Vector3(0, 0.76, 0), 0.50, 0.035, kit.mat("wood_dark"))
	if _leaf == null:
		_leaf = _make_leaf()
	for i in 11:
		var a := float(i) * TAU / 11.0
		kit.prop(id, _leaf, Transform3D(Basis(Vector3.UP, a), p + Vector3(0, 1.26, 0)), kit.mat("velvet_green"))


static func _make_leaf() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 5:
		var t := float(i) / 5.0
		var u := float(i + 1) / 5.0
		var a := Vector3(t * 1.15, 0.38 * sin(t * PI) - 0.53 * t * t, 0)
		var b := Vector3(u * 1.15, 0.38 * sin(u * PI) - 0.53 * u * u, 0)
		for side in [-1.0, 1.0]:
			for v in [a + Vector3(0, 0, side * 0.19 * sin(t * PI)), b + Vector3(0, 0, side * 0.19 * sin(u * PI)), a + Vector3(0, 0.04, 0)]:
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()


static func _cylinder(kit: LevelKit, id: String, p: Vector3, r: float, h: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = h
	mesh.radial_segments = 16
	kit.prop(id, mesh, Transform3D(Basis.IDENTITY, p), material)


static func _box(kit: LevelKit, id: String, p: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	kit.prop(id, mesh, Transform3D(Basis.IDENTITY, p), material)
