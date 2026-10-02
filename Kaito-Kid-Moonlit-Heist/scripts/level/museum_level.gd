class_name MuseumLevel
extends Node3D
## Museum architecture and gameplay placement driven by MuseumLayout.

signal laser_tripped(position: Vector3)
signal lasers_disabled
signal camera_spotted(position: Vector3)
signal pickup_collected(kind: String, position: Vector3)

const FLOOR_THICKNESS := 0.32
const WALL_T := MuseumLayout.WALL_T

var navigation_region: NavigationRegion3D
var _kit: LevelKit
var _atmosphere: MuseumAtmosphere
var _exit: ExitGlider
var _jewels: Array = []
var _walls: Array = []
var _windows: Array = []
var _edge_keys: Dictionary = {}


## Build all static geometry, gameplay objects, atmosphere and navigation.
func build() -> void:
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "NavigationRegion"
	add_child(navigation_region)
	_kit = LevelKit.new(navigation_region)
	_build_floors()
	_build_walls()
	_build_ceilings()
	_build_centrepiece()
	_build_balcony()
	for room_id: String in MuseumLayout.ROOMS:
		var theme: String = MuseumLayout.ROOMS[room_id]["theme"]
		var dresser: Script = load("res://scripts/level/rooms/%s.gd" % theme)
		dresser.dress(_kit, room_id)
	_build_objects()
	_build_base_lighting()
	_atmosphere = MuseumAtmosphere.new()
	_atmosphere.name = "Atmosphere"
	add_child(_atmosphere)
	var alarms := PackedVector3Array([
		Vector3(-10, 6.2, 14), Vector3(10, 6.2, 14),
		Vector3(-10, 8.5, 0), Vector3(10, 8.5, 0),
		Vector3(-30, 6.2, 9), Vector3(30, 6.2, 9),
		Vector3(-26, 6.2, -24), Vector3(27, 6.2, -24)])
	_atmosphere.setup(AABB(Vector3(-44, 0, -42), Vector3(88, 10, 76)), _windows, alarms)
	var nav := NavigationMesh.new()
	nav.agent_radius = 0.45
	nav.agent_height = 1.8
	nav.agent_max_climb = 0.3
	nav.cell_size = 0.15
	nav.cell_height = 0.1
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = KK.LAYER_WORLD
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map, 0.15)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map, 0.1)
	navigation_region.navigation_mesh = nav
	navigation_region.bake_navigation_mesh(false)
	_check_navigation_after_sync()


func _build_floors() -> void:
	# One continuous collision slab prevents navigation seams at the shared room thresholds.
	_kit.solid("atrium", Vector3(0, -FLOOR_THICKNESS, -4),
		Vector3(84, FLOOR_THICKNESS, 72), _kit.mat("marble_floor"), 0.0, false)
	for room_id: String in MuseumLayout.ROOMS:
		var rect: Rect2 = MuseumLayout.ROOMS[room_id]["rect"]
		var material_name := "marble_floor"
		match room_id:
			"clock", "paintings": material_name = "parquet"
			"moon_gallery", "vault": material_name = "marble_black"
			"egyptian": material_name = "sandstone"
			"balcony": material_name = "stone"
			"south_service", "east_service", "west_service": material_name = "stone"
		_detail(room_id, Vector3(rect.get_center().x, 0.003, rect.get_center().y),
			Vector3(rect.size.x, 0.006, rect.size.y), material_name)
		if room_id == "balcony" or room_id.contains("service"):
			continue
		# A thin inlaid perimeter reads as one deliberate room rather than scattered tiles.
		var inner := rect.grow(-0.72)
		for z: float in [inner.position.y, inner.end.y]:
			_detail(room_id, Vector3(inner.get_center().x, 0.012, z),
				Vector3(inner.size.x, 0.018, 0.055), "brass")
		for x: float in [inner.position.x, inner.end.x]:
			_detail(room_id, Vector3(x, 0.012, inner.get_center().y),
				Vector3(0.055, 0.018, inner.size.y), "brass")
	# The two metre interstitial strip is a short concealed vent passage.
	_detail("south_service", Vector3(30.6, 0.004, 25),
		Vector3(1.2, 0.008, 2.0), "stone")


func _build_walls() -> void:
	var edges: Array[Dictionary] = []
	for room_id: String in MuseumLayout.ROOMS:
		if room_id == "balcony":
			continue
		var r: Rect2 = MuseumLayout.ROOMS[room_id]["rect"]
		edges.append({"room": room_id, "axis": "x", "at": r.position.y, "from": r.position.x, "to": r.end.x})
		edges.append({"room": room_id, "axis": "x", "at": r.end.y, "from": r.position.x, "to": r.end.x})
		edges.append({"room": room_id, "axis": "z", "at": r.position.x, "from": r.position.y, "to": r.end.y})
		edges.append({"room": room_id, "axis": "z", "at": r.end.x, "from": r.position.y, "to": r.end.y})
	for edge: Dictionary in edges:
		var cuts: Array[float] = [float(edge["from"]), float(edge["to"])]
		for other: Dictionary in edges:
			if other["axis"] == edge["axis"] and is_equal_approx(other["at"], edge["at"]):
				for endpoint: float in [float(other["from"]), float(other["to"])]:
					if endpoint > edge["from"] and endpoint < edge["to"]:
						cuts.append(endpoint)
		for opening: Dictionary in MuseumLayout.OPENINGS:
			if opening["axis"] == edge["axis"] and is_equal_approx(opening["at"], edge["at"]):
				for endpoint: float in [float(opening["from"]), float(opening["to"])]:
					if endpoint > edge["from"] and endpoint < edge["to"]:
						cuts.append(endpoint)
		for window: Dictionary in MuseumLayout.WINDOWS:
			if _window_on_edge(window, edge):
				var center: float = window["pos"].x if edge["axis"] == "x" else window["pos"].z
				var half: float = window["size"].x * 0.5
				for endpoint: float in [center - half, center + half]:
					if endpoint > edge["from"] and endpoint < edge["to"]:
						cuts.append(endpoint)
		cuts.sort()
		for i in range(cuts.size() - 1):
			var a: float = cuts[i]
			var b: float = cuts[i + 1]
			if b - a < 0.02:
				continue
			var key := "%s:%.2f:%.2f:%.2f" % [edge["axis"], edge["at"], a, b]
			if _edge_keys.has(key):
				continue
			_edge_keys[key] = true
			var center: float = (a + b) * 0.5
			var opening_data: Dictionary = {}
			for opening: Dictionary in MuseumLayout.OPENINGS:
				if opening["axis"] == edge["axis"] and is_equal_approx(opening["at"], edge["at"]) and center > opening["from"] and center < opening["to"]:
					opening_data = opening
					break
			if not opening_data.is_empty():
				_opening_segment(edge, a, b, opening_data)
				continue
			var window_data: Dictionary = {}
			for window: Dictionary in MuseumLayout.WINDOWS:
				if not _window_on_edge(window, edge):
					continue
				var wc: float = window["pos"].x if edge["axis"] == "x" else window["pos"].z
				if center > wc - window["size"].x * 0.5 and center < wc + window["size"].x * 0.5:
					window_data = window
					break
			if window_data.is_empty():
				_wall_segment(edge, a, b, 0.0, _edge_height(edge, center))
			else:
				_window_segment(edge, a, b, window_data)


func _window_on_edge(window: Dictionary, edge: Dictionary) -> bool:
	var p: Vector3 = window["pos"]
	var coordinate: float = p.z if edge["axis"] == "x" else p.x
	var along: float = p.x if edge["axis"] == "x" else p.z
	return is_equal_approx(coordinate, edge["at"]) and along >= edge["from"] and along <= edge["to"]


func _edge_height(edge: Dictionary, along: float) -> float:
	var height: float = MuseumLayout.ROOMS[edge["room"]]["height"]
	for room_id: String in MuseumLayout.ROOMS:
		var r: Rect2 = MuseumLayout.ROOMS[room_id]["rect"]
		if edge["axis"] == "x":
			if (is_equal_approx(edge["at"], r.position.y) or is_equal_approx(edge["at"], r.end.y)) and along >= r.position.x and along <= r.end.x:
				height = maxf(height, MuseumLayout.ROOMS[room_id]["height"])
		elif (is_equal_approx(edge["at"], r.position.x) or is_equal_approx(edge["at"], r.end.x)) and along >= r.position.y and along <= r.end.y:
			height = maxf(height, MuseumLayout.ROOMS[room_id]["height"])
	return height


func _edge_pos(edge: Dictionary, along: float, height: float) -> Vector3:
	if edge["axis"] == "x":
		return Vector3(along, height, edge["at"])
	return Vector3(edge["at"], height, along)


func _edge_size(edge: Dictionary, length: float, height: float, thick := WALL_T) -> Vector3:
	if edge["axis"] == "x":
		return Vector3(length, height, thick)
	return Vector3(thick, height, length)


func _wall_segment(edge: Dictionary, a: float, b: float, bottom: float, top: float) -> void:
	if top - bottom < 0.025:
		return
	var room_id: String = edge["room"]
	var h: float = top - bottom
	var pos := _edge_pos(edge, (a + b) * 0.5, bottom)
	var size := _edge_size(edge, b - a, h)
	var service := room_id.contains("service")
	_kit.solid(room_id, pos, size, _kit.mat("plaster" if service else _wall_color(room_id)), 0.0, false)
	if bottom < 0.01 and not service:
		_detail(room_id, _edge_pos(edge, (a + b) * 0.5, 0.55),
			_edge_size(edge, b - a, 1.1, WALL_T + 0.035), "wood_dark")
	if not service:
		for y: float in [0.1, 1.11, minf(top - 0.15, 5.8), top - 0.06]:
			if y > bottom + 0.04 and y < top:
				_detail(room_id, _edge_pos(edge, (a + b) * 0.5, y),
					_edge_size(edge, b - a, 0.055, WALL_T + 0.075), "gold")
	_walls.append(Rect2(Vector2(pos.x - size.x * 0.5, pos.z - size.z * 0.5),
		Vector2(size.x, size.z)))


func _wall_color(room_id: String) -> String:
	match room_id:
		"foyer", "sculpture", "paintings": return "wallpaper_red"
		"atrium", "moon_gallery", "vault": return "wallpaper_navy"
		"egyptian", "clock": return "wallpaper_teal"
	return "plaster"


func _opening_segment(edge: Dictionary, a: float, b: float, opening: Dictionary) -> void:
	var kind: String = opening["kind"]
	var height: float = _edge_height(edge, (a + b) * 0.5)
	if kind == "gate" or kind == "laser":
		_wall_segment(edge, a, b, 4.2 if kind == "gate" else 3.2, height)
		return
	var clear_h := 2.4 if kind == "service" else (MuseumLayout.VENT_H if kind == "vent" else 3.2)
	if kind == "arch":
		# Eight upper voussoirs trace a raised round arch; the opening stays broad at shoulder height.
		var radius: float = (b - a) * 0.5
		for i in 8:
			var lo := a + (b - a) * float(i) / 8.0
			var hi := a + (b - a) * float(i + 1) / 8.0
			var u := absf(((lo + hi) * 0.5 - (a + b) * 0.5) / radius)
			var arch_y := 3.2 + sqrt(maxf(0.0, 1.0 - u * u))
			_wall_segment(edge, lo, hi, arch_y, height)
			_detail(edge["room"], _edge_pos(edge, (lo + hi) * 0.5, arch_y + 0.07),
				_edge_size(edge, hi - lo, 0.11, WALL_T + 0.12), "gold")
		for side: float in [a, b]:
			_detail(edge["room"], _edge_pos(edge, side, 1.75),
				_edge_size(edge, 0.18, 3.5, 0.58), "ivory")
		_detail(edge["room"], _edge_pos(edge, (a + b) * 0.5, 4.12),
			_edge_size(edge, 0.38, 0.36, WALL_T + 0.22), "gold")
		return
	_wall_segment(edge, a, b, clear_h, height)
	if kind == "service":
		for side: float in [a, b]:
			_detail(edge["room"], _edge_pos(edge, side, clear_h * 0.5),
				_edge_size(edge, 0.09, clear_h, WALL_T + 0.1), "iron")
		_detail(edge["room"], _edge_pos(edge, (a + b) * 0.5, clear_h),
			_edge_size(edge, b - a, 0.1, WALL_T + 0.1), "iron")
		# An open steel leaf sits against one jamb, with a horizontal push bar.
		var hinge := _edge_pos(edge, a + 0.12, 1.13)
		var leaf_size := Vector3(0.075, 2.26, 1.72) if edge["axis"] == "x" else Vector3(1.72, 2.26, 0.075)
		_detail(edge["room"], hinge, leaf_size, "iron")
		_detail(edge["room"], hinge + Vector3(0, -0.15, 0),
			Vector3(0.12, 0.045, 1.2) if edge["axis"] == "x" else Vector3(1.2, 0.045, 0.12), "brass")
	elif kind == "vent":
		for side: float in [a, b]:
			_detail(edge["room"], _edge_pos(edge, side, clear_h * 0.5),
				_edge_size(edge, 0.055, clear_h, WALL_T + 0.1), "iron")
		_detail(edge["room"], _edge_pos(edge, (a + b) * 0.5, clear_h),
			_edge_size(edge, b - a, 0.055, WALL_T + 0.1), "iron")


func _window_segment(edge: Dictionary, a: float, b: float, window: Dictionary) -> void:
	var p: Vector3 = window["pos"]
	var size: Vector2 = window["size"]
	var bottom := p.y - size.y * 0.5
	var top := p.y + size.y * 0.5
	_wall_segment(edge, a, b, 0.0, bottom)
	_wall_segment(edge, a, b, top, _edge_height(edge, (a + b) * 0.5))
	# The atmosphere owns visible glazing; a separate invisible collision plane seals the opening.
	var body := StaticBody3D.new()
	body.collision_layer = KK.LAYER_GLASS
	body.collision_mask = 0
	body.position = p
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = _edge_size(edge, b - a, size.y, 0.08)
	shape.shape = box
	body.add_child(shape)
	_kit.room_node(edge["room"]).add_child(body)
	var normal: Vector3 = window["normal"]
	var basis := Basis(Vector3(normal.z, 0, -normal.x), Vector3.UP, normal)
	_windows.append({"transform": Transform3D(basis, p), "size": size})


func _build_ceilings() -> void:
	for room_id: String in MuseumLayout.ROOMS:
		if room_id == "balcony":
			continue
		var r: Rect2 = MuseumLayout.ROOMS[room_id]["rect"]
		var h: float = MuseumLayout.ROOMS[room_id]["height"]
		var service := room_id.contains("service")
		if room_id == "atrium":
			_atrium_ceiling(r, h)
			continue
		else:
			_detail(room_id, Vector3(r.get_center().x, h + 0.08, r.get_center().y),
				Vector3(r.size.x, 0.16, r.size.y), "plaster_grey" if service else "ceiling")
		if service:
			continue
		# A shallow coffer grid gives the large rooms their six metre scale.
		var x := r.position.x + 3.0
		while x < r.end.x - 2.0:
			_detail(room_id, Vector3(x, h - 0.04, r.get_center().y),
				Vector3(0.14, 0.22, r.size.y), "wood_dark")
			x += 4.0
		var z := r.position.y + 3.0
		while z < r.end.y - 2.0:
			_detail(room_id, Vector3(r.get_center().x, h - 0.04, z),
				Vector3(r.size.x, 0.22, 0.14), "wood_dark")
			z += 4.0


func _atrium_ceiling(r: Rect2, h: float) -> void:
	var sky: Dictionary = MuseumLayout.SKYLIGHT
	var p: Vector3 = sky["pos"]
	var s: Vector2 = sky["size"]
	for strip: Rect2 in [
		Rect2(r.position.x, r.position.y, r.size.x, p.z - s.y * 0.5 - r.position.y),
		Rect2(r.position.x, p.z + s.y * 0.5, r.size.x, r.end.y - (p.z + s.y * 0.5)),
		Rect2(r.position.x, p.z - s.y * 0.5, p.x - s.x * 0.5 - r.position.x, s.y),
		Rect2(p.x + s.x * 0.5, p.z - s.y * 0.5, r.end.x - (p.x + s.x * 0.5), s.y)]:
		_detail("atrium", Vector3(strip.get_center().x, h + 0.08, strip.get_center().y),
			Vector3(strip.size.x, 0.16, strip.size.y), "ceiling")
	for x: float in [p.x - s.x * 0.5, p.x + s.x * 0.5]:
		_detail("atrium", Vector3(x, h, p.z), Vector3(0.28, 0.3, s.y + 0.4), "gold")
	for z: float in [p.z - s.y * 0.5, p.z + s.y * 0.5]:
		_detail("atrium", Vector3(p.x, h, z), Vector3(s.x + 0.4, 0.3, 0.28), "gold")
	var ring_mesh := BoxMesh.new()
	ring_mesh.size = Vector3(1.55, 0.28, 0.28)
	for i in 24:
		var angle := TAU * float(i) / 24.0
		var ring_pos := p + Vector3(cos(angle) * 5.45, -0.05, sin(angle) * 5.45)
		var ring_basis := Basis(Vector3.UP, -angle - PI * 0.5)
		_kit.prop("atrium", ring_mesh, Transform3D(ring_basis, ring_pos), _kit.mat("gold"))
	_windows.append({"transform": Transform3D(Basis(Vector3.RIGHT, Vector3(0, 0, -1), Vector3.UP), p), "size": s})


func _build_centrepiece() -> void:
	var data: Dictionary = MuseumLayout.CENTREPIECE
	_kit.cylinder_solid("atrium", data["pos"], data["radius"], data["height"],
		_kit.mat("marble_white"), 36)


func _build_balcony() -> void:
	var r: Rect2 = MuseumLayout.ROOMS["balcony"]["rect"]
	_kit.solid("balcony", Vector3(r.get_center().x, 0, r.position.y + 0.12),
		Vector3(r.size.x, 1.05, 0.24), _kit.mat("stone"))
	for x: float in [r.position.x + 0.12, r.end.x - 0.12]:
		_kit.solid("balcony", Vector3(x, 0, r.get_center().y),
			Vector3(0.24, 1.05, r.size.y), _kit.mat("stone"))
	for x: float in [-10.0, -6.0, -2.0, 2.0, 6.0, 10.0]:
		_detail("balcony", Vector3(x, 1.05, r.position.y + 0.12),
			Vector3(0.48, 0.18, 0.42), "ivory")


func _detail(room_id: String, pos: Vector3, size: Vector3, material_name: String) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_kit.prop(room_id, mesh, Transform3D(Basis.IDENTITY, pos), _kit.mat(material_name))


func _build_objects() -> void:
	for data: Dictionary in MuseumLayout.JEWELS:
		var jewel := Jewel.new()
		jewel.name = data["name"].replace(" ", "")
		_kit.room_node(data["room"]).add_child(jewel)
		jewel.position = data["pos"]
		jewel.setup(data["name"], data["color"])
		_jewels.append(jewel)
		var pos: Vector3 = data["pos"]
		_walls.append(Rect2(Vector2(pos.x - 0.7, pos.z - 0.7), Vector2(1.4, 1.4)))
	_exit = ExitGlider.new()
	_exit.name = "BalconyExit"
	add_child(_exit)
	_exit.position = MuseumLayout.EXIT_GATE
	var laser: Dictionary = MuseumLayout.LASER
	var grid := LaserGrid.new()
	grid.name = "VaultLaserGrid"
	add_child(grid)
	grid.position = laser["pos"]
	grid.rotation.y = PI * 0.5 if laser["axis"] == "z" else 0.0
	grid.setup(Vector2(laser["width"], laser["height"]))
	grid.tripped.connect(func(pos: Vector3) -> void: laser_tripped.emit(pos))
	var fuse := FuseBox.new()
	fuse.name = "MaintenanceFuse"
	add_child(fuse)
	fuse.position = MuseumLayout.FUSE["pos"]
	fuse.rotation.y = PI * 0.5
	fuse.setup([grid])
	fuse.disabled.connect(func() -> void: lasers_disabled.emit())
	for data: Dictionary in MuseumLayout.CAMERAS:
		var camera := SecurityCamera.new()
		add_child(camera)
		camera.position = data["pos"]
		camera.rotation.y = deg_to_rad(data["yaw_deg"])
		camera.setup(100.0, 13.0)
		camera.spotted.connect(func(pos: Vector3) -> void: camera_spotted.emit(pos))
	for data: Dictionary in MuseumLayout.PICKUPS:
		var pickup := HeistPickup.new()
		add_child(pickup)
		pickup.position = data["pos"]
		pickup.setup(data["kind"])
		pickup.collected.connect(func(kind: String, pos: Vector3) -> void: pickup_collected.emit(kind, pos))


func _build_base_lighting() -> void:
	for room_id: String in MuseumLayout.ROOMS:
		if room_id == "balcony":
			continue
		var r: Rect2 = MuseumLayout.ROOMS[room_id]["rect"]
		var h: float = MuseumLayout.ROOMS[room_id]["height"]
		var service := room_id.contains("service")
		var spacing := 12.0 if service else 15.0
		var count := maxi(1, int(ceil(r.size.y / spacing)))
		for i in count:
			var z := r.position.y + r.size.y * (float(i) + 0.5) / float(count)
			var pos := Vector3(r.get_center().x, h - 0.55, z)
			_kit.omni(room_id, pos, Color(1.0, 0.74, 0.46) if not service else Color(0.8, 0.85, 0.9),
				0.42 if not service else 0.22, 12.0 if not service else 8.0, false)
			if service:
				_detail(room_id, pos, Vector3(0.32, 0.18, 0.32), "iron")
		if service:
			for offset: float in [0.45, 0.72]:
				var pipe_pos := Vector3(r.position.x + offset, h - 0.42, r.get_center().y)
				var pipe_size := Vector3(0.075, 0.075, r.size.y - 0.5)
				if r.size.x > r.size.y:
					pipe_pos = Vector3(r.get_center().x, h - 0.42, r.position.y + offset)
					pipe_size = Vector3(r.size.x - 0.5, 0.075, 0.075)
				_detail(room_id, pipe_pos, pipe_size, "iron")


func _check_navigation_after_sync() -> void:
	var nav_map: RID = navigation_region.get_navigation_map()
	var frames := 0
	while NavigationServer3D.map_get_iteration_id(nav_map) == 0 and frames < 60:
		await get_tree().physics_frame
		frames += 1
	while frames < 60 and NavigationServer3D.map_get_closest_point(nav_map, MuseumLayout.SPAWN).distance_to(MuseumLayout.SPAWN) > 1.0:
		await get_tree().physics_frame
		frames += 1
	if frames >= 60:
		push_warning("Museum navigation map did not synchronize for the reachability audit")
		return
	_check_navigation()


func _check_navigation() -> void:
	var nav_map: RID = navigation_region.get_navigation_map()
	var reference: Vector3 = NavigationServer3D.map_get_closest_point(nav_map, MuseumLayout.SPAWN)
	var failures: Array[String] = []
	var probes: Array[Dictionary] = []
	for route: Dictionary in MuseumLayout.GUARD_ROUTES:
		for point: Vector3 in route["points"]:
			probes.append({"name": "guard", "pos": point})
	for data: Dictionary in MuseumLayout.JEWELS:
		probes.append({"name": data["name"], "pos": data["pos"]})
	for data: Dictionary in MuseumLayout.PICKUPS:
		probes.append({"name": data["kind"] + " pickup", "pos": data["pos"]})
	probes.append({"name": "fuse", "pos": MuseumLayout.FUSE["pos"] + Vector3(0, -1.4, 0)})
	probes.append({"name": "glider", "pos": MuseumLayout.EXIT_GATE + Vector3(0, 0, -1.0)})
	for probe: Dictionary in probes:
		var pos: Vector3 = probe["pos"]
		var nearest: Vector3 = NavigationServer3D.map_get_closest_point(nav_map, pos)
		var path: PackedVector3Array = NavigationServer3D.map_get_path(nav_map, reference, nearest, true)
		var tolerance := 2.2 if String(probe["name"]) in [
			"Blue Wonder", "Scarlet Lady", "Emerald Empress", "Black Star",
			"Moonstone of Pandora"] else 1.1
		if pos.distance_to(nearest) > tolerance or path.is_empty():
			failures.append("%s @ %s" % [probe["name"], pos])
	if not failures.is_empty():
		push_warning("Museum navmesh unreachable: " + ", ".join(failures))
	var a: Vector3 = MuseumLayout.TEST_POINTS["obstacle_a"] + Vector3.UP
	var b: Vector3 = MuseumLayout.TEST_POINTS["obstacle_b"] + Vector3.UP
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(a, b, KK.LAYER_WORLD))
	if hit.is_empty():
		push_warning("Atrium centrepiece does not block the obstacle test ray")


## Initial player transform, facing north.
func player_spawn() -> Transform3D:
	return Transform3D(Basis.IDENTITY, MuseumLayout.SPAWN)


## Patrol routes from the shared level design.
func guard_routes() -> Array:
	var routes: Array = []
	for data: Dictionary in MuseumLayout.GUARD_ROUTES:
		routes.append({"kind": data["kind"], "points": PackedVector3Array(data["points"]), "wait": data["wait"]})
	return routes


## The five placed jewel nodes.
func jewels() -> Array:
	return _jewels


## Balcony escape gate.
func exit_node() -> ExitGlider:
	return _exit


## Storm, windows and alarm controller.
func atmosphere() -> MuseumAtmosphere:
	return _atmosphere


## World XZ footprints for the minimap.
func minimap_walls() -> Array:
	return _walls + _kit.minimap


## Playable bounds including the north balcony.
func bounds() -> Rect2:
	return Rect2(-42, -40, 84, 72)


## Stable positions for navigation and cover checks.
func test_points() -> Dictionary:
	return MuseumLayout.TEST_POINTS.duplicate()
