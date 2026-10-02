extends RefCounted
## Back-of-house dressing. Floor obstacles occupy shallow wall bays so the
## east patrol and all three service routes keep a clear central lane.

static var _box_mesh: BoxMesh
static var _pipe_mesh: CylinderMesh


static func dress(kit: LevelKit, room_id: String) -> void:
	match room_id:
		"south_service":
			_south(kit, room_id)
		"east_service":
			_east(kit, room_id)
		"west_service":
			_west(kit, room_id)


static func _box(kit: LevelKit, id: String, pos: Vector3, size: Vector3, material: String) -> void:
	if _box_mesh == null:
		_box_mesh = BoxMesh.new()
		_box_mesh.size = Vector3.ONE
	kit.prop(id, _box_mesh, Transform3D(Basis().scaled(size), pos), kit.mat(material))


static func _pipe(kit: LevelKit, id: String, pos: Vector3, length: float, radius: float, along_z: bool, material: String) -> void:
	if _pipe_mesh == null:
		_pipe_mesh = CylinderMesh.new()
		_pipe_mesh.top_radius = 1.0
		_pipe_mesh.bottom_radius = 1.0
		_pipe_mesh.height = 1.0
		_pipe_mesh.radial_segments = 10
	var turn := Basis(Vector3.RIGHT if along_z else Vector3.FORWARD, PI * 0.5)
	kit.prop(id, _pipe_mesh, Transform3D(turn * Basis.from_scale(Vector3(radius, length, radius)), pos), kit.mat(material))


static func _conduit(kit: LevelKit, id: String, start: float, end: float, cross: float, along_z: bool) -> void:
	var mid := (start + end) * 0.5
	for offset in [-0.18, 0.18]:
		var p := Vector3(cross + offset, 2.87, mid) if along_z else Vector3(mid, 2.87, cross + offset)
		_pipe(kit, id, p, end - start, 0.043, along_z, "iron")
	var tray := Vector3(cross, 3.0, mid) if along_z else Vector3(mid, 3.0, cross)
	var size := Vector3(0.53, 0.035, end - start) if along_z else Vector3(end - start, 0.035, 0.53)
	_box(kit, id, tray, size, "iron")


static func _bulb(kit: LevelKit, id: String, pos: Vector3) -> void:
	_box(kit, id, pos + Vector3(0, 0.15, 0), Vector3(0.09, 0.25, 0.09), "iron")
	_box(kit, id, pos, Vector3(0.31, 0.04, 0.31), "brass")
	_box(kit, id, pos + Vector3(0, -0.12, 0), Vector3(0.23, 0.16, 0.23), "emissive_warm")
	var bars: Array[Transform3D] = []
	for sx in [-0.15, 0.15]:
		for sz in [-0.15, 0.15]:
			bars.append(Transform3D(Basis.from_scale(Vector3(0.018, 0.22, 0.018)), pos + Vector3(sx, -0.11, sz)))
	kit.multi(id, _box_mesh, bars, kit.mat("iron"))
	kit.omni(id, pos + Vector3(0, -0.14, 0), Color(1.0, 0.72, 0.4), 0.83, 4.9)


static func _crate(kit: LevelKit, id: String, pos: Vector3, along_z: bool = true) -> void:
	var size := Vector3(0.58, 1.13, 1.18) if along_z else Vector3(1.18, 1.13, 0.58)
	kit.solid(id, pos, size, kit.mat("wood_dark"), 0.0, false)
	_box(kit, id, pos + Vector3(0, 1.14, 0), Vector3(size.x + 0.03, 0.04, size.z + 0.03), "wood_light")
	for end in [-0.39, 0.39]:
		var p := pos + (Vector3(0, 0.6, end) if along_z else Vector3(end, 0.6, 0))
		var s := Vector3(0.6, 0.05, 0.035) if along_z else Vector3(0.035, 0.05, 0.6)
		_box(kit, id, p, s, "brass")


static func _lockers(kit: LevelKit, id: String, pos: Vector3, along_z: bool = true) -> void:
	for i in 2:
		var p := pos + (Vector3(0, 0, float(i) * 0.67 - 0.335) if along_z else Vector3(float(i) * 0.67 - 0.335, 0, 0))
		var size := Vector3(0.55, 2.04, 0.62) if along_z else Vector3(0.62, 2.04, 0.55)
		kit.solid(id, p, size, kit.mat("iron"), 0.0, false)
		var face := p + (Vector3(0.28, 1.1, 0) if along_z else Vector3(0, 1.1, -0.28))
		_box(kit, id, face, Vector3(0.022, 1.78, 0.56) if along_z else Vector3(0.56, 1.78, 0.022), "wood_dark")
		_box(kit, id, face + Vector3(0, 0.56, 0), Vector3(0.03, 0.02, 0.32) if along_z else Vector3(0.32, 0.02, 0.03), "brass")


static func _panel(kit: LevelKit, id: String, pos: Vector3, x_wall: bool, title: String) -> void:
	_box(kit, id, pos, Vector3(0.08, 1.27, 0.86) if x_wall else Vector3(0.86, 1.27, 0.08), "iron")
	var face := pos + (Vector3(0.055, 0, 0) if x_wall else Vector3(0, 0, -0.055))
	_box(kit, id, face, Vector3(0.015, 1.1, 0.72) if x_wall else Vector3(0.72, 1.1, 0.015), "wood_dark")
	for i in 3:
		var p := face + Vector3(0, 0.3 - float(i) * 0.29, 0)
		p += Vector3(0.016, 0, -0.19) if x_wall else Vector3(-0.19, 0, -0.016)
		_box(kit, id, p, Vector3(0.018, 0.05, 0.12) if x_wall else Vector3(0.12, 0.05, 0.018), "emissive_warm" if i == 0 else "brass")
	kit.label(id, title, face + (Vector3(0.025, -0.42, 0) if x_wall else Vector3(0, -0.42, -0.025)), PI * 0.5 if x_wall else PI, 20, Color(0.94, 0.84, 0.62))


static func _exit_sign(kit: LevelKit, id: String, pos: Vector3, yaw: float) -> void:
	_box(kit, id, pos, Vector3(1.05, 0.34, 0.08), "iron")
	kit.label(id, "EXIT  →", pos + Vector3(0, 0, -0.055), yaw, 27, Color(0.52, 1.0, 0.68))


static func _janitor_cart(kit: LevelKit, id: String, pos: Vector3) -> void:
	# Low wheeled frame and one water pail. The whole cart occupies a 1.2 x
	# 0.56 m wall bay, while its bucket makes a readable utility silhouette.
	kit.solid(id, pos, Vector3(1.18, 0.19, 0.55), kit.mat("iron"), 0.0, false)
	kit.cylinder_solid(id, pos + Vector3(-0.24, 0.19, 0), 0.23, 0.8, kit.mat("brass"), 12)
	_box(kit, id, pos + Vector3(0.47, 0.66, 0), Vector3(0.035, 1.15, 0.035), "iron")
	_box(kit, id, pos + Vector3(0.35, 1.22, 0), Vector3(0.28, 0.04, 0.04), "iron")
	for x in [-0.4, 0.4]:
		for z in [-0.25, 0.25]:
			_box(kit, id, pos + Vector3(x, 0.11, z), Vector3(0.13, 0.19, 0.045), "wood_dark")


static func _dolly(kit: LevelKit, id: String, pos: Vector3) -> void:
	kit.solid(id, pos, Vector3(0.57, 0.17, 1.22), kit.mat("iron"), 0.0, false)
	kit.solid(id, pos + Vector3(0, 0.17, 0), Vector3(0.55, 0.93, 1.12), kit.mat("wood_dark"), 0.0, false)
	for z in [-0.39, 0.39]:
		_box(kit, id, pos + Vector3(0.0, 1.11, z), Vector3(0.57, 0.035, 0.05), "wood_light")
		_box(kit, id, pos + Vector3(0.0, 0.11, z), Vector3(0.58, 0.16, 0.055), "brass")


static func _south(kit: LevelKit, id: String) -> void:
	_conduit(kit, id, 11.0, 39.4, 26.85, false)
	_bulb(kit, id, Vector3(17.0, 2.72, 29.0))
	_bulb(kit, id, Vector3(35.0, 2.72, 29.0))
	# Restoration dispatch board is the landmark visible from the foyer.
	_box(kit, id, Vector3(20.0, 1.67, 31.54), Vector3(2.28, 1.17, 0.07), "wood_dark")
	_box(kit, id, Vector3(20.0, 1.67, 31.49), Vector3(2.08, 0.98, 0.02), "papyrus")
	kit.label(id, "STAFF  /  NIGHT SHIFT", Vector3(20.0, 1.94, 31.46), PI, 22, Color(0.15, 0.15, 0.15))
	for x in [19.45, 20.5]:
		_box(kit, id, Vector3(x, 1.46, 31.46), Vector3(0.63, 0.36, 0.009), "ivory")
	_panel(kit, id, Vector3(22.5, 1.53, 26.43), false, "LIGHTS")
	_janitor_cart(kit, id, Vector3(16.0, 0, 31.18))
	_crate(kit, id, Vector3(25.0, 0, 31.18), false)
	_crate(kit, id, Vector3(26.5, 0, 31.18), false)
	_lockers(kit, id, Vector3(35.1, 0, 31.17), false)
	_exit_sign(kit, id, Vector3(38.0, 2.57, 31.52), PI)


static func _east(kit: LevelKit, id: String) -> void:
	_conduit(kit, id, -29.4, 25.6, 41.25, true)
	for z in [18.0, 1.5, -17.5]:
		_bulb(kit, id, Vector3(40.0, 2.72, z))
	# Keep the fuse's playable face at (38.2,-24) completely open.
	_box(kit, id, Vector3(38.45, 2.67, -24), Vector3(0.1, 0.08, 2.7), "brass")
	kit.label(id, "VAULT POWER", Vector3(38.51, 2.86, -24), PI * 0.5, 23, Color(0.96, 0.78, 0.42))
	_panel(kit, id, Vector3(38.44, 1.58, -12.5), true, "CAMERAS")
	_lockers(kit, id, Vector3(41.28, 0, 7.0))
	_crate(kit, id, Vector3(41.29, 0, -8.1))
	_crate(kit, id, Vector3(41.29, 0, -27.2))
	_exit_sign(kit, id, Vector3(40.0, 2.57, 25.43), 0.0)


static func _west(kit: LevelKit, id: String) -> void:
	_conduit(kit, id, -29.4, 31.4, -41.25, true)
	for z in [15.0, -6.0, -25.0]:
		_bulb(kit, id, Vector3(-40.0, 2.72, z))
	_panel(kit, id, Vector3(-41.53, 1.6, -13.1), true, "PUMPS")
	_lockers(kit, id, Vector3(-41.27, 0, 15.0))
	_crate(kit, id, Vector3(-41.29, 0, -6.0))
	_dolly(kit, id, Vector3(-41.29, 0, -11.0))
	_crate(kit, id, Vector3(-41.29, 0, -25.3))
	# z=0/22 windows, rose pickup, and z=9/-19/26 doors remain clear.
	_exit_sign(kit, id, Vector3(-40.0, 2.57, 29.8), 0.0)
