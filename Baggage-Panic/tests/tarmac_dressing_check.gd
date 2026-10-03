extends SceneTree
## Run without importing: Godot --headless --path . -s res://tests/tarmac_dressing_check.gd


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var script: GDScript = load("res://scripts/world/tarmac_dressing.gd") as GDScript
	if script == null or not script.can_instantiate():
		_fail("Dressing script could not load")
		return
	var layer: Node3D = script.new() as Node3D
	root.add_child(layer)
	await process_frame
	var initial_nodes: int = _count_visuals(layer)
	var tile_positions: Array[float] = []
	for index: int in 10:
		tile_positions.append(36.0 - float(index) * 36.0)
	var previous_z: float = 0.0
	for frame: int in 600:
		var player_z: float = -float(frame) * 1.5
		if frame == 200:
			player_z = -9000.0
		elif frame == 400:
			player_z = 0.0
		layer.call("follow", player_z)
		layer.call("set_intensity", float(frame) / 599.0)
		# Reference TarmacView's exact reset and while-loop recycling rules.
		if player_z > previous_z + 72.0:
			for index: int in tile_positions.size():
				tile_positions[index] = 36.0 - float(index) * 36.0
		for index: int in tile_positions.size():
			while tile_positions[index] > player_z + 72.0:
				tile_positions[index] -= 360.0
			var tile: Node3D = layer.get_node("TarmacDressingTile%02d" % index) as Node3D
			if not is_equal_approx(tile.position.z, tile_positions[index]):
				_fail("Dressing tile lost synchronization at frame %d" % frame)
				return
		previous_z = player_z
		await process_frame
		if _count_visuals(layer) != initial_nodes:
			_fail("Visual nodes changed during recycling")
			return
	var modules: Dictionary = {}
	var moving: int = 0
	var pending: Array[Node] = [layer]
	while not pending.is_empty():
		var current: Node = pending.pop_back() as Node
		if current.has_meta("tarmac_module"):
			modules[String(current.get_meta("tarmac_module"))] = true
		if current.has_meta("tarmac_traffic"):
			moving += 1
			var vehicle: Node3D = current as Node3D
			if vehicle.position.z < previous_z - 165.0 or vehicle.position.z >= previous_z + 135.0:
				_fail("Moving vehicle escaped its wrapping range")
				return
		pending.append_array(current.get_children())
	if initial_nodes > 3500 or modules.size() < 6 or moving < 4 or moving > 6:
		_fail("Counts outside budget: nodes=%d modules=%d moving=%d" % [initial_nodes, modules.size(), moving])
		return
	print("TARMAC_DRESSING_OK nodes=%d modules=%d" % [initial_nodes, modules.size()])
	quit(0)


func _count_visuals(layer: Node) -> int:
	var count: int = 0
	var pending: Array[Node] = [layer]
	while not pending.is_empty():
		var current: Node = pending.pop_back() as Node
		if current is MeshInstance3D or current is MultiMeshInstance3D or current is Label3D:
			count += 1
		pending.append_array(current.get_children())
	return count


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
