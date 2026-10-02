extends RefCounted
## A sculpture court with a clear jewel approach and a readable patrol loop.

const WARM := Color(1.0, 0.72, 0.43)
const MOON := Color(0.58, 0.73, 1.0)


static func dress(kit: LevelKit, room_id: String) -> void:
	var marble := kit.mat("marble_white")
	var black := kit.mat("marble_black")
	var brass := kit.mat("brass")
	var plaster := kit.mat("plaster")

	# Bust pedestals are crouch cover inside the x=-34/-18, z=-4/16 patrol.
	for spec in [
		[Vector3(-31.0, 0, 3.1), 0.68, -0.45],
		[Vector3(-21.0, 0, 3.1), 0.74, 0.50],
		[Vector3(-21.0, 0, -0.8), 0.72, 0.75],
	]:
		var p: Vector3 = spec[0]
		_pedestal(kit, room_id, p, Vector3(1.35, 1.10, 1.35), marble, black, brass)
		kit.model(room_id, "marble_bust_01", Transform3D(Basis(Vector3.UP, spec[2]), p + Vector3.UP * 1.15), spec[1], "none")
		_accent(kit, room_id, p + Vector3(0, 1.5, 0), p + Vector3(-0.8, 5.92, -0.7), 0.95, 32.0)

	# Landmark visible beyond the jewel from the atrium.
	var gothic := Vector3(-26.0, 0, -0.9)
	_pedestal(kit, room_id, gothic, Vector3(2.65, 0.82, 2.65), black, marble, brass)
	kit.model(room_id, "gothic_statue", Transform3D(Basis(Vector3.UP, 0.55), gothic + Vector3.UP * 0.88), 2.02)
	_accent(kit, room_id, gothic + Vector3(0, 2.0, 0), gothic + Vector3(1.5, 5.92, -0.6), 1.75, 37.0)

	# Different heights and finishes keep the larger pieces distinct.
	var horse := Vector3(-31.0, 0, 10.8)
	_pedestal(kit, room_id, horse, Vector3(2.1, 0.62, 1.7), black, marble, brass)
	kit.model(room_id, "horse_statue_01", Transform3D(Basis(Vector3.UP, 0.45), horse + Vector3.UP * 0.68), 1.4)
	_accent(kit, room_id, horse + Vector3(0, 1.5, 0), horse + Vector3(-0.5, 5.92, 0.4), 1.15, 35.0)
	var whale := Vector3(-21.0, 0, 11.0)
	_pedestal(kit, room_id, whale, Vector3(2.15, 0.68, 2.15), marble, black, brass)
	kit.model(room_id, "bronze_whale_statue", Transform3D(Basis(Vector3.UP, -0.75), whale + Vector3.UP * 0.74), 1.12)
	_accent(kit, room_id, whale + Vector3(0, 1.35, 0), whale + Vector3(0.7, 5.92, -0.4), 1.1, 34.0)

	# The jewel case itself is built by MuseumLevel.
	kit.solid(room_id, Vector3(-26, 0, 6), Vector3(3.4, 0.16, 3.4), black, 0.0, false)
	for x in [-27.77, -24.23]:
		kit.solid(room_id, Vector3(x, 0.17, 6), Vector3(0.045, 0.025, 3.5), brass, 0.0, false)
	for z in [4.23, 7.77]:
		kit.solid(room_id, Vector3(-26, 0.17, z), Vector3(3.5, 0.025, 0.045), brass, 0.0, false)
	kit.label(room_id, "THE SCARLET LADY", Vector3(-26, 0.37, 8.65), 0.0, 30, Color(0.83, 0.68, 0.43))
	_accent(kit, room_id, Vector3(-26, 1.1, 6), Vector3(-26.5, 5.92, 6.8), 1.35, 34.0)

	# Low seats leave the south arch and the patrol lane open.
	for z in [-6.1, 13.5]:
		kit.model(room_id, "painted_wooden_bench", Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-26, 0, z)))

	# Wall reliefs and mirrors sit at eye height, away from every opening.
	_wall_relief(kit, room_id, Vector3(-37.68, 0, -1.1), "horse_head", 0.72, PI * 0.5, plaster, marble, brass)
	_wall_relief(kit, room_id, Vector3(-37.68, 0, 14.1), "lion_head", 0.76, PI * 0.5, plaster, marble, brass)
	_wall_relief(kit, room_id, Vector3(-14.32, 0, -1.2), "lion_head", 0.72, -PI * 0.5, plaster, marble, brass)
	_wall_relief(kit, room_id, Vector3(-14.32, 0, 13.4), "horse_head", 0.72, -PI * 0.5, plaster, marble, brass)
	kit.model(room_id, "ornate_mirror_01", Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-37.56, 1.55, 4.2)), 1.35, "none")
	kit.model(room_id, "ornate_mirror_01", Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-14.44, 1.55, 9.8)), 1.35, "none")

	# Visible chandeliers source the warm pools. Only the first casts shadows.
	for z in [2.6, 12.1]:
		kit.model(room_id, "Chandelier_02", Transform3D(Basis.IDENTITY, Vector3(-26, 4.96, z)), 0.85, "none")
		kit.omni(room_id, Vector3(-26, 5.07, z), WARM, 1.65, 6.1, z < 4.0)
	# Moon spill enters via the west service door and its outer window.
	kit.spot(room_id, Vector3(-37.35, 4.7, 9.0), Vector3(-31.0, 0.15, 7.0), MOON, 1.9, 9.8, 43.0)
	kit.omni(room_id, Vector3(-30.5, 3.8, 5.5), Color(0.58, 0.69, 0.91), 0.32, 7.0)


static func _pedestal(kit: LevelKit, id: String, p: Vector3, size: Vector3, body: Material, cap: Material, trim: Material) -> void:
	kit.solid(id, p, size, body)
	kit.solid(id, p + Vector3(0, size.y - 0.06, 0), Vector3(size.x + 0.18, 0.12, size.z + 0.18), cap, 0.0, false)
	kit.solid(id, p + Vector3(0, 0.11, 0), Vector3(size.x + 0.12, 0.035, size.z + 0.12), trim, 0.0, false)
	kit.solid(id, p + Vector3(0, size.y - 0.16, 0), Vector3(size.x + 0.13, 0.028, size.z + 0.13), trim, 0.0, false)


static func _wall_relief(kit: LevelKit, id: String, p: Vector3, asset: String, height: float, yaw: float, panel: Material, ledge: Material, trim: Material) -> void:
	var inward := Vector3(1, 0, 0) if yaw > 0.0 else Vector3(-1, 0, 0)
	var wall_pos := p + inward * 0.12
	kit.solid(id, wall_pos + Vector3(0, 1.52, 0), Vector3(0.12, 1.7, 1.25), panel, 0.0, false)
	kit.solid(id, wall_pos + Vector3(0, 1.47, 0) + inward * 0.12, Vector3(0.36, 0.09, 1.42), ledge, 0.0, false)
	kit.solid(id, wall_pos + Vector3(0, 2.39, 0), Vector3(0.16, 0.045, 1.39), trim, 0.0, false)
	kit.model(id, asset, Transform3D(Basis(Vector3.UP, yaw), wall_pos + inward * 0.22 + Vector3.UP * 1.57), height, "none")
	kit.label(id, "STUDY IN STONE", wall_pos + inward * 0.29 + Vector3.UP * 1.18, yaw, 18, Color(0.88, 0.75, 0.52))
	kit.solid(id, wall_pos + inward * 0.22 + Vector3.UP * 2.48, Vector3(0.24, 0.06, 0.48), trim, 0.0, false)
	kit.spot(id, wall_pos + inward * 0.4 + Vector3.UP * 2.45, wall_pos + inward * 0.3 + Vector3.UP * 1.91, WARM, 0.62, 2.2, 43.0)


static func _accent(kit: LevelKit, id: String, target: Vector3, fixture: Vector3, energy: float, angle: float) -> void:
	var socket := CylinderMesh.new()
	socket.top_radius = 0.12
	socket.bottom_radius = 0.14
	socket.height = 0.17
	kit.prop(id, socket, Transform3D(Basis.IDENTITY, fixture), kit.mat("brass"))
	var lens := SphereMesh.new()
	lens.radius = 0.085
	lens.height = 0.09
	kit.prop(id, lens, Transform3D(Basis.IDENTITY, fixture + Vector3.DOWN * 0.12), kit.mat("emissive_warm"))
	kit.spot(id, fixture + Vector3.DOWN * 0.13, target, WARM, energy, 6.3, angle)
