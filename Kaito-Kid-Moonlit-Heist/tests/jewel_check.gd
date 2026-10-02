extends SceneTree
## Run: Godot --headless --path . -s res://tests/jewel_check.gd

const MAIN_SCENE := "res://scenes/main.tscn"
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := (load(MAIN_SCENE) as PackedScene).instantiate() as HeistMain
	root.add_child(main)
	current_scene = main
	for i in 120:
		await physics_frame
		var nav_map: RID = main.level.navigation_region.get_navigation_map()
		if NavigationServer3D.map_get_iteration_id(nav_map) > 0 and NavigationServer3D.map_get_closest_point(nav_map, MuseumLayout.SPAWN).distance_to(MuseumLayout.SPAWN) < 1.0:
			break
	var map: RID = main.level.navigation_region.get_navigation_map()
	_check(NavigationServer3D.map_get_iteration_id(map) > 0, "navigation map synchronized")
	_check(main.level.jewels().size() == MuseumLayout.JEWELS.size(), "all layout jewels built")
	var space := main.get_world_3d().direct_space_state
	var spawn: Vector3 = NavigationServer3D.map_get_closest_point(map, MuseumLayout.SPAWN)
	var case_shape := BoxShape3D.new()
	case_shape.size = Vector3(1.3, 0.9, 1.3)
	for data: Dictionary in MuseumLayout.JEWELS:
		var jewel: Jewel = null
		for candidate: Jewel in main.level.jewels():
			if candidate.jewel_name == data["name"]:
				jewel = candidate
				break
		if jewel == null:
			_check(false, "%s exists" % data["name"])
			continue
		var pos: Vector3 = data["pos"]
		var label: String = jewel.jewel_name
		_check(is_zero_approx(pos.y) and jewel.global_position.distance_to(pos) < 0.01,
			"%s plinth origin at floor y=0" % label)
		var room: Rect2 = MuseumLayout.ROOMS[data["room"]]["rect"]
		_check(room.grow(-0.7).has_point(Vector2(pos.x, pos.z)), "%s case inside room walls" % label)
		# Probe the occupied case volume above thin floor finishes and its own base.
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = case_shape
		query.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0, 0.67, 0))
		query.collision_mask = KK.LAYER_WORLD
		var excluded: Array[RID] = []
		for child: Node in jewel.get_children():
			if child is StaticBody3D:
				excluded.append((child as StaticBody3D).get_rid())
		query.exclude = excluded
		var overlaps := space.intersect_shape(query, 16)
		var blockers: Array[String] = []
		for hit: Dictionary in overlaps:
			blockers.append(str((hit["collider"] as Node).get_path()))
		_check(blockers.is_empty(), "%s case clear of walls and props (%s)" % [label, blockers])
		var prompt_reachable := false
		for step in 16:
			var angle := TAU * float(step) / 16.0
			for radius in [1.25, 1.55, 1.85]:
				var desired := pos + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
				var stand := NavigationServer3D.map_get_closest_point(map, desired)
				if stand.distance_to(desired) > 0.35 or stand.distance_to(jewel.interact_position()) > KK.INTERACT_RANGE - 0.05:
					continue
				var path := NavigationServer3D.map_get_path(map, spawn, stand, true)
				if path.is_empty() or path[-1].distance_to(stand) > 0.2:
					continue
				main.player.global_position = stand
				main.player.look_at(jewel.interact_position(), Vector3.UP)
				if main.player.get_focus_interactable() == jewel:
					prompt_reachable = true
					break
			if prompt_reachable:
				break
		_check(prompt_reachable, "%s prompt reachable from navmesh within interaction range" % label)
	print("\n%d checks, %d failed" % [checks, failures.size()])
	for failure in failures:
		print("  - ", failure)
	quit(1 if failures.size() > 0 else 0)


func _check(ok: bool, label: String) -> void:
	checks += 1
	print("  %s  %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures.append(label)
