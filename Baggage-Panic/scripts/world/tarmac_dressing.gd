extends Node3D
## Companion to tarmac_view.gd: identical tile identities, stand choices and recycling.
## Modules are discovered once per instance; follow/process never build scene nodes.

const MODULE_DIR: String = "res://scripts/world/vehicles/"
const TILE_LENGTH: float = 36.0
const TILE_COUNT: int = 10
const GROUND_Y: float = -0.6
const TRAFFIC_LENGTH: float = 300.0

static var _module_scripts: Dictionary = {}
static var _module_scales: Dictionary = {}

var _available: Dictionary = {}
var _tiles: Array[Node3D] = []
var _traffic: Array[Node3D] = []
var _traffic_lanes: Array[float] = []
var _traffic_speeds: Array[float] = []
var _traffic_phases: Array[float] = []
var _player_z: float = 0.0
var _elapsed: float = 0.0
var _intensity: float = 0.0


func _ready() -> void:
	_discover_modules()
	for index: int in TILE_COUNT:
		var tile: Node3D = Node3D.new()
		tile.name = "TarmacDressingTile%02d" % index
		tile.position.z = TILE_LENGTH - float(index) * TILE_LENGTH
		add_child(tile)
		_tiles.append(tile)
		_build_tile(tile, index)
	_build_traffic()
	_update_traffic()


func follow(player_z: float) -> void:
	# Match TarmacView's reset, including its original tile indices on a restart.
	if player_z > _player_z + TILE_LENGTH * 2.0:
		for index: int in _tiles.size():
			_tiles[index].position.z = TILE_LENGTH - float(index) * TILE_LENGTH
	for tile: Node3D in _tiles:
		var excess: float = tile.position.z - player_z - TILE_LENGTH * 2.0
		if excess > 0.0:
			# Equivalent to its while loop, also inexpensive for a large teleport.
			tile.position.z -= ceilf(excess / (TILE_COUNT * TILE_LENGTH)) * TILE_COUNT * TILE_LENGTH
	_player_z = player_z
	_update_traffic()


func set_intensity(amount: float) -> void:
	_intensity = clampf(amount, 0.0, 1.0)
	# Modules already carry emissive lamps; no extra dynamic lights are needed.


func _process(delta: float) -> void:
	_elapsed += delta
	_update_traffic()


func _update_traffic() -> void:
	for index: int in _traffic.size():
		var offset: float = fposmod(_traffic_phases[index] + _elapsed * _traffic_speeds[index], TRAFFIC_LENGTH)
		_traffic[index].position = Vector3(_traffic_lanes[index], GROUND_Y, _player_z - 165.0 + offset)


func _discover_modules() -> void:
	var files: PackedStringArray = DirAccess.get_files_at(MODULE_DIR)
	files.sort()
	for file_name: String in files:
		if not file_name.ends_with(".gd"):
			continue
		var path: String = MODULE_DIR + file_name
		var module: GDScript = _module_scripts.get(path) as GDScript
		if module == null:
			module = load(path) as GDScript
			if module == null or not module.can_instantiate() or not module.has_method("build"):
				continue
			_module_scripts[path] = module
			_module_scales[path] = _read_scale(path)
		_available[file_name.get_basename()] = path


static func _read_scale(path: String) -> float:
	var source: FileAccess = FileAccess.open(path, FileAccess.READ)
	if source == null:
		return 1.0
	for line: String in source.get_as_text().split("\n"):
		if not line.strip_edges().begins_with("## INTENDED_SCALE"):
			continue
		var value: String = line.get_slice("=", 1).strip_edges().get_slice(" ", 0)
		if value.is_valid_float():
			return maxf(value.to_float(), 0.001)
	return 1.0


func _build_module(preferred: Array[String], parent: Node3D, at: Vector3, yaw: float, variant: int) -> Node3D:
	for module_name: String in preferred:
		if not _available.has(module_name):
			continue
		var path: String = String(_available[module_name])
		var module: GDScript = _module_scripts[path] as GDScript
		var built: Node3D = module.call("build", parent, at, yaw, variant) as Node3D
		if built == null:
			continue
		_batch_repeated_parts(built)
		# Multiply: a module can already have a presentation scale of its own.
		built.scale *= float(_module_scales.get(path, 1.0))
		built.set_meta("tarmac_module", path)
		return built
	return null


static func _batch_repeated_parts(module_root: Node3D) -> void:
	# Tyres, rails, bolts and lamp housings often share exact mesh resources.
	# Batch only opaque leaves with no surface overrides; labels stay independent.
	var groups: Dictionary = {}
	var pending: Array[Node] = [module_root]
	while not pending.is_empty():
		var current: Node = pending.pop_back() as Node
		pending.append_array(current.get_children())
		var part: MeshInstance3D = current as MeshInstance3D
		if part == null or part.mesh == null or part.get_child_count() != 0 or not part.visible:
			continue
		var eligible: bool = true
		for surface: int in part.mesh.get_surface_count():
			if part.get_surface_override_material(surface) != null:
				eligible = false
			var material: BaseMaterial3D = part.get_active_material(surface) as BaseMaterial3D
			if material == null or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				eligible = false
		if not eligible:
			continue
		var material_id: int = part.material_override.get_instance_id() if part.material_override != null else 0
		var key: String = "%d:%d:%d" % [part.mesh.get_instance_id(), material_id, part.cast_shadow]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(part)
	var inverse: Transform3D = module_root.global_transform.affine_inverse()
	for key: String in groups:
		var parts: Array[MeshInstance3D] = []
		parts.assign(groups[key])
		if parts.size() < 2:
			continue
		var multi: MultiMesh = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = parts[0].mesh
		multi.instance_count = parts.size()
		var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instance.multimesh = multi
		instance.material_override = parts[0].material_override
		instance.cast_shadow = parts[0].cast_shadow
		for index: int in parts.size():
			multi.set_instance_transform(index, inverse * parts[index].global_transform)
		module_root.add_child(instance)
		for part: MeshInstance3D in parts:
			part.free()


func _build_tile(tile: Node3D, index: int) -> void:
	for side: float in [-1.0, 1.0]:
		if index % 2 == (0 if side < 0.0 else 1):
			_build_stand(tile, side, index)
		# Two fixture clusters per 360 m loop: 144/216 m spacing (~150 m).
		if index == 0 or index == 4:
			_build_module(["vehicle_windsock"], tile, Vector3(side * 123.0, GROUND_Y, -7.0), -side * 90.0, index)
			_build_module(["vehicle_runway_signs"], tile, Vector3(side * 128.0, GROUND_Y, -25.0), -side * 90.0, index)
			_build_module(["vehicle_approach_lights"], tile, Vector3(side * 190.0, GROUND_Y, -12.0), 0.0, index)
		# Stay behind existing hangars at x=220, tower=229 and skyline=265..301.
		if index == 1:
			_build_module(["vehicle_hangar", "vehicle_cargo_terminal"], tile, Vector3(side * 250.0, GROUND_Y, -18.0), -side * 90.0, index)
		if index == 6:
			_build_module(["vehicle_cargo_terminal", "vehicle_hangar"], tile, Vector3(side * 250.0, GROUND_Y, -18.0), -side * 90.0, index)
		if index == 3 and side > 0.0:
			_build_module(["vehicle_control_tower"], tile, Vector3(245.0, GROUND_Y, -22.0), -90.0, index)
		# Airfield emergency and winter services on the grass between taxiway and runway.
		if index == 2:
			_build_module(["vehicle_fire_truck"], tile, Vector3(side * 124.0, GROUND_Y, -14.0), -side * 90.0, index)
		if index == 5:
			_build_module(["vehicle_deicer"], tile, Vector3(side * 124.0, GROUND_Y, -20.0), -side * 90.0, index)
		if index == 7:
			_build_module(["vehicle_parked_jet_small"], tile, Vector3(side * 220.0, GROUND_Y, -18.0), -side * 90.0, index)


func _build_stand(tile: Node3D, side: float, index: int) -> void:
	var stand_z: float = -18.0 + float((index * 7) % 5 - 2)
	var wide: bool = index % 5 == 4
	var center_x: float = 69.0 if wide else 63.0
	var length: float = 60.0 if wide else 36.0
	# TarmacView's aircraft face local -Z and rotate side*90 degrees.
	# Work on the side opposite the bridge (bridge_z = stand_z + side*2/3).
	var nose_x: float = center_x - length * 0.5
	_build_module(["vehicle_gpu_cart", "vehicle_pushback_tug", "vehicle_maintenance_van"], tile,
		Vector3(side * (nose_x + (8.0 if wide else 2.0)), GROUND_Y, stand_z - side * 6.0), side * 90.0, index)
	if index % 3 == 0:
		# Loader discharge (+Z) reaches the forward hold without crossing the bridge.
		_build_module(["vehicle_belt_loader", "vehicle_cargo_loader", "vehicle_gpu_cart"], tile,
			Vector3(side * (center_x - length * 0.27), GROUND_Y, stand_z - side * 6.8), 0.0 if side > 0.0 else 180.0, index + 1)
	elif index % 3 == 1:
		# Rear door is beyond the swept wing, with its cab toward the fuselage.
		_build_module(["vehicle_catering_truck", "vehicle_airstairs", "vehicle_lavatory_truck"], tile,
			Vector3(side * (center_x + length * 0.32), GROUND_Y, stand_z - side * 6.5), 0.0 if side > 0.0 else 180.0, index + 1)
	else:
		# Low dollies wait behind the hold, clear of the existing service train.
		_build_module(["vehicle_uld_dollies", "vehicle_baggage_train", "vehicle_ground_crew_group"], tile,
			Vector3(side * (center_x + length * 0.37), GROUND_Y, stand_z - side * 8.0), side * 90.0, index + 1)
	# Fuel hydrant dispenser under the wing on alternate stands.
	if index % 4 == 0 or wide:
		_build_module(["vehicle_hydrant_dispenser"], tile,
			Vector3(side * (center_x + length * 0.05), GROUND_Y, stand_z - side * (14.0 if wide else 10.0)), 0.0 if side > 0.0 else 180.0, index + 3)
	if wide:
		_build_module(["vehicle_ground_crew_group", "vehicle_uld_dollies"], tile,
			Vector3(side * (center_x - 10.0), GROUND_Y, stand_z - side * 12.0), side * 90.0, index + 2)


func _build_traffic() -> void:
	var choices: Array[Array] = [
		["vehicle_follow_me", "vehicle_maintenance_van", "vehicle_sweeper"],
		["vehicle_maintenance_van", "vehicle_follow_me", "vehicle_sweeper"],
		["vehicle_sweeper", "vehicle_follow_me", "vehicle_maintenance_van"],
		["vehicle_apron_bus", "vehicle_maintenance_van", "vehicle_follow_me"],
		["vehicle_baggage_train", "vehicle_follow_me", "vehicle_maintenance_van"],
		["vehicle_follow_me", "vehicle_sweeper", "vehicle_maintenance_van"],
	]
	# Inner-apron lane clears the widebody noses and fits below the bridges.
	# The outer apron at x=94 would run through the widebody tails.
	var lanes: Array[float] = [-36.0, 36.0, -36.0, 40.5, -40.5, 36.0]
	var speeds: Array[float] = [-4.2, -4.0, -4.2, 5.1, -3.7, -4.0]
	for index: int in choices.size():
		var preferred: Array[String] = []
		preferred.assign(choices[index])
		var vehicle: Node3D = _build_module(preferred, self, Vector3.ZERO, 180.0 if speeds[index] < 0.0 else 0.0, index)
		if vehicle == null:
			continue
		vehicle.set_meta("tarmac_traffic", true)
		_traffic.append(vehicle)
		_traffic_lanes.append(lanes[index])
		_traffic_speeds.append(speeds[index])
		_traffic_phases.append(30.0 + float(index) * 47.0)
