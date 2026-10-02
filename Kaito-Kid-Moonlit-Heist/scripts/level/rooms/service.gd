extends RefCounted
## Back-of-house corridors. Storage occupies shallow wall bays: the long
## corridors retain a 2.2 m centre lane, and all doors, windows and pickups
## stay clear. Fixtures and their light sources are placed together.

static var _box_mesh: BoxMesh
static var _pipe_mesh: CylinderMesh


static func dress(kit: LevelKit, room_id: String) -> void:
	match room_id:
		"south_service": _south(kit, room_id)
		"east_service": _east(kit, room_id)
		"west_service": _west(kit, room_id)


static func _box(kit: LevelKit, id: String, pos: Vector3, size: Vector3, material: String) -> void:
	if _box_mesh == null:
		_box_mesh = BoxMesh.new()
		_box_mesh.size = Vector3.ONE
	kit.prop(id, _box_mesh, Transform3D(Basis.from_scale(size), pos), kit.mat(material))


static func _model(kit: LevelKit, id: String, asset: String, pos: Vector3, yaw := 0.0, height := 0.0, collider := "auto") -> void:
	kit.model(id, asset, Transform3D(Basis(Vector3.UP, yaw), pos), height, collider)


static func _conduit(kit: LevelKit, id: String, start: float, end: float, cross: float, along_z: bool) -> void:
	if _pipe_mesh == null:
		_pipe_mesh = CylinderMesh.new()
		_pipe_mesh.top_radius = 1.0
		_pipe_mesh.bottom_radius = 1.0
		_pipe_mesh.height = 1.0
		_pipe_mesh.radial_segments = 12
	var mid := (start + end) * 0.5
	for offset in [-0.14, 0.14]:
		var p := Vector3(cross + offset, 2.91, mid) if along_z else Vector3(mid, 2.91, cross + offset)
		var turn := Basis(Vector3.RIGHT if along_z else Vector3.FORWARD, PI * 0.5)
		kit.prop(id, _pipe_mesh, Transform3D(turn * Basis.from_scale(Vector3(0.035, end - start, 0.035)), p), kit.mat("iron"))
	var tray := Vector3(cross, 3.04, mid) if along_z else Vector3(mid, 3.04, cross)
	_box(kit, id, tray, Vector3(0.42, 0.035, end - start) if along_z else Vector3(end - start, 0.035, 0.42), "iron")


static func _lamp(kit: LevelKit, id: String, pos: Vector3, shadow := false) -> void:
	# The source sits in the shade; the modeled lamp is 0.86 m tall below a 3.2 m ceiling.
	_model(kit, id, "hanging_industrial_lamp", pos + Vector3(0, 2.28, 0), 0.0, 0.86, "none")
	kit.omni(id, pos + Vector3(0, 2.46, 0), Color(1.0, 0.73, 0.47), 1.25, 5.5, shadow)


static func _sconce(kit: LevelKit, id: String, pos: Vector3, yaw: float) -> void:
	_model(kit, id, "industrial_caged_sconce", pos, yaw, 0.0, "none")
	kit.omni(id, pos + Vector3(0, 0.02, 0), Color(1.0, 0.69, 0.39), 0.78, 3.8)


static func _shelf(kit: LevelKit, id: String, pos: Vector3, yaw: float) -> void:
	# The scan was authored in centimetres; this yields a 1.13 x 2.2 x 0.52 m rack.
	_model(kit, id, "steel_frame_shelves_01", pos, yaw, 2.2)


static func _stored(kit: LevelKit, id: String, pos: Vector3, yaw: float) -> void:
	_model(kit, id, "wooden_crate_01", pos, yaw)
	_model(kit, id, "cardboard_box_01", pos + Vector3(0.04, 0.35, 0), yaw + 0.12, 0.0, "none")


static func _rack_goods(kit: LevelKit, id: String, pos: Vector3, along_z: bool) -> void:
	# Cargo rests on the rack's bottom and middle shelves; the rack supplies the collider.
	for level in [0.24, 1.02]:
		var off := Vector3(0, level, 0.27) if along_z else Vector3(0.27, level, 0)
		_model(kit, id, "cardboard_box_01", pos + off, 0.1, 0.0, "none")
	_model(kit, id, "metal_tool_chest", pos + Vector3(0, 0.55, 0), 0.0, 0.0, "none")


static func _panel(kit: LevelKit, id: String, pos: Vector3, x_wall: bool, title: String) -> void:
	_box(kit, id, pos, Vector3(0.07, 1.14, 0.82) if x_wall else Vector3(0.82, 1.14, 0.07), "iron")
	var face := pos + (Vector3(0.047, 0, 0) if x_wall else Vector3(0, 0, -0.047))
	_box(kit, id, face, Vector3(0.015, 0.95, 0.68) if x_wall else Vector3(0.68, 0.95, 0.015), "concrete")
	for i in 3:
		var p := face + Vector3(0, 0.25 - float(i) * 0.23, 0)
		p += Vector3(0.015, 0, -0.22) if x_wall else Vector3(-0.22, 0, -0.015)
		_box(kit, id, p, Vector3(0.018, 0.036, 0.12) if x_wall else Vector3(0.12, 0.036, 0.018), "emissive_warm" if i == 0 else "brass")
	kit.label(id, title, face + (Vector3(0.023, -0.37, 0) if x_wall else Vector3(0, -0.37, -0.023)), PI * 0.5 if x_wall else PI, 19, Color(0.96, 0.87, 0.68))


static func _floor(kit: LevelKit, id: String, center: Vector3, size: Vector3) -> void:
	# Thin visual overlay leaves the continuous structural slab and its navmesh intact.
	_box(kit, id, center + Vector3(0, 0.011, 0), size, "concrete")


static func _south(kit: LevelKit, id: String) -> void:
	_floor(kit, id, Vector3(26, 0, 29), Vector3(30.9, 0.012, 5.16))
	_conduit(kit, id, 11.0, 39.4, 26.85, false)
	for x in [16.5, 27.0, 36.0]:
		_lamp(kit, id, Vector3(x, 0, 29), x == 27.0)
	# Restoration dispatch is the landmark from the foyer entrance.
	_box(kit, id, Vector3(20.0, 1.67, 31.76), Vector3(2.42, 1.32, 0.045), "wood_dark")
	_box(kit, id, Vector3(20.0, 1.67, 31.72), Vector3(2.22, 1.12, 0.015), "plaster_grey")
	kit.label(id, "RESTORATION  /  NIGHT SHIFT", Vector3(20.0, 1.97, 31.69), PI, 21, Color(0.17, 0.17, 0.17))
	for x in [19.45, 20.50]:
		_box(kit, id, Vector3(x, 1.45, 31.69), Vector3(0.71, 0.39, 0.008), "papyrus")
	_panel(kit, id, Vector3(22.5, 1.55, 26.24), false, "LIGHTS")
	_sconce(kit, id, Vector3(13.6, 1.95, 31.66), PI)
	_sconce(kit, id, Vector3(33.5, 1.95, 31.66), PI)
	_shelf(kit, id, Vector3(25.0, 0, 31.40), 0.0)
	_rack_goods(kit, id, Vector3(25.0, 0, 31.40), false)
	_shelf(kit, id, Vector3(31.0, 0, 31.40), 0.0)
	_rack_goods(kit, id, Vector3(31.0, 0, 31.40), false)
	_stored(kit, id, Vector3(16.0, 0, 31.37), 0.0)
	_stored(kit, id, Vector3(35.8, 0, 31.38), 0.17)
	_model(kit, id, "metal_tool_chest", Vector3(29.2, 0, 31.5))
	kit.label(id, "SERVICE  →", Vector3(37.5, 2.62, 31.68), PI, 26, Color(0.69, 0.9, 0.69))


static func _east(kit: LevelKit, id: String) -> void:
	_floor(kit, id, Vector3(40, 0, -2), Vector3(3.16, 0.012, 55.2))
	_conduit(kit, id, -29.4, 25.6, 41.25, true)
	for z in [21.0, 4.0, -9.0, -25.0]:
		_lamp(kit, id, Vector3(40, 0, z), z == -9.0)
	for z in [16.4, -18.0]:
		_sconce(kit, id, Vector3(41.70, 1.93, z), -PI * 0.5)
	# Opposite-wall racks read as a working storeroom without interrupting the x=40 patrol.
	for z in [7.0, -8.0, -27.0]:
		_shelf(kit, id, Vector3(41.43, 0, z), PI * 0.5)
		_rack_goods(kit, id, Vector3(41.43, 0, z), true)
	_stored(kit, id, Vector3(41.43, 0, 2.5), PI * 0.5)
	_stored(kit, id, Vector3(41.43, 0, -15.5), PI * 0.5)
	_model(kit, id, "metal_tool_chest", Vector3(41.46, 0, -21.0), PI * 0.5)
	# Fuse interaction at (38.2, -24) remains completely unobstructed.
	_box(kit, id, Vector3(38.26, 2.69, -24), Vector3(0.04, 0.045, 2.2), "iron")
	kit.label(id, "VAULT POWER", Vector3(38.31, 2.86, -24), PI * 0.5, 22, Color(0.98, 0.82, 0.54))
	_panel(kit, id, Vector3(38.25, 1.58, -17.6), true, "CAMERAS")
	kit.label(id, "EXIT  ↑", Vector3(40.0, 2.62, 25.64), 0.0, 26, Color(0.69, 0.9, 0.69))


static func _west(kit: LevelKit, id: String) -> void:
	_floor(kit, id, Vector3(-40, 0, 1), Vector3(3.16, 0.012, 61.2))
	_conduit(kit, id, -29.4, 31.4, -41.25, true)
	for z in [15.0, -5.0, -25.0]:
		_lamp(kit, id, Vector3(-40, 0, z), z == -5.0)
	for z in [3.8, -14.0]:
		_sconce(kit, id, Vector3(-41.70, 1.93, z), PI * 0.5)
	_panel(kit, id, Vector3(-41.76, 1.58, -12.9), true, "PUMPS")
	for z in [15.0, -6.0, -25.0]:
		_shelf(kit, id, Vector3(-41.43, 0, z), PI * 0.5)
		_rack_goods(kit, id, Vector3(-41.43, 0, z), true)
	_stored(kit, id, Vector3(-41.43, 0, -10.5), PI * 0.5)
	_stored(kit, id, Vector3(-41.43, 0, 29.0), PI * 0.5)
	_model(kit, id, "metal_tool_chest", Vector3(-41.45, 0, -27.8), PI * 0.5)
	# z=0/22 windows, z=9/-19/26 doors and the rose at z=0 stay open.
	kit.label(id, "EXIT  ↑", Vector3(-40, 2.62, 30.0), 0.0, 26, Color(0.69, 0.9, 0.69))
