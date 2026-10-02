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
		if bottom < 0.01:
			_wall_panels(edge, a, b)
		for y: float in [0.1, 1.12, 2.48, top - 0.36, top - 0.12]:
			if y > bottom + 0.04 and y < top:
				_detail(room_id, _edge_pos(edge, (a + b) * 0.5, y),
					_edge_size(edge, b - a, 0.055 if y < 2.5 else 0.09, WALL_T + (0.11 if y < 2.5 else 0.22)), "wood_dark" if y in [1.12, top - 0.36] else "gold")
		if top > 4.0 and b - a > 0.5:
			_wall_dentils(edge, a, b, top - 0.25)
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
		var lintel := 4.2 if kind == "gate" else 3.2
		_wall_segment(edge, a, b, lintel, height)
		for side: float in [a, b]:
			_detail(edge["room"], _edge_pos(edge, side, lintel * 0.5),
				_edge_size(edge, 0.14, lintel, WALL_T + 0.2), "marble_white" if kind == "gate" else "iron")
		_detail(edge["room"], _edge_pos(edge, (a + b) * 0.5, lintel),
			_edge_size(edge, b - a + 0.24, 0.18, WALL_T + 0.2), "marble_white" if kind == "gate" else "iron")
		_detail(edge["room"], _edge_pos(edge, (a + b) * 0.5, lintel + 0.11),
			_edge_size(edge, b - a + 0.35, 0.04, WALL_T + 0.24), "gold" if kind == "gate" else "brass")
		return
	var clear_h := 2.4 if kind == "service" else (MuseumLayout.VENT_H if kind == "vent" else 3.2)
	if kind == "arch":
		_build_arch(edge, a, b, height)
		for side: float in [a, b]:
			for side_offset: float in [-0.27, 0.27]:
				var pier := _edge_pos(edge, side, 0.0)
				if edge["axis"] == "x": pier.z += side_offset
				else: pier.x += side_offset
				_detail(edge["room"], pier + Vector3(0, 1.6, 0), _edge_size(edge, 0.16, 3.2, 0.14), "marble_white")
				_detail(edge["room"], pier + Vector3(0, 0.18, 0), _edge_size(edge, 0.38, 0.36, 0.4), "marble_white")
				_detail(edge["room"], pier + Vector3(0, 3.12, 0), _edge_size(edge, 0.42, 0.22, 0.43), "marble_white")
				_detail(edge["room"], pier + Vector3(0, 3.27, 0), _edge_size(edge, 0.43, 0.05, 0.45), "gold")
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
		for y: float in [0.06, clear_h - 0.04]:
			_detail(edge["room"], _edge_pos(edge, (a + b) * 0.5, y),
				_edge_size(edge, b - a, 0.045, WALL_T + 0.14), "brass")


func _wall_panels(edge: Dictionary, a: float, b: float) -> void:
	var length := b - a
	if length < 0.9:
		return
	var count := maxi(1, int(round(length / 2.35)))
	var bay := length / float(count)
	for i in count:
		var along := a + bay * (float(i) + 0.5)
		for face: float in [-1.0, 1.0]:
			var center := _edge_pos(edge, along, 0.59)
			if edge["axis"] == "x": center.z += face * (WALL_T * 0.5 + 0.035)
			else: center.x += face * (WALL_T * 0.5 + 0.035)
			_detail(edge["room"], center, _edge_size(edge, bay - 0.20, 0.72, 0.045), "wood_dark")
			for offset: float in [-0.5, 0.5]:
				var stile := _edge_pos(edge, along + offset * (bay - 0.31), 0.59)
				if edge["axis"] == "x": stile.z += face * (WALL_T * 0.5 + 0.071)
				else: stile.x += face * (WALL_T * 0.5 + 0.071)
				_detail(edge["room"], stile, _edge_size(edge, 0.045, 0.76, 0.025), "brass")
			for y: float in [0.21, 0.97]:
				var rail := _edge_pos(edge, along, y)
				if edge["axis"] == "x": rail.z += face * (WALL_T * 0.5 + 0.071)
				else: rail.x += face * (WALL_T * 0.5 + 0.071)
				_detail(edge["room"], rail, _edge_size(edge, bay - 0.31, 0.04, 0.025), "brass")


func _wall_dentils(edge: Dictionary, a: float, b: float, y: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = _edge_size(edge, 0.16, 0.13, 0.18)
	var transforms: Array[Transform3D] = []
	var count := int((b - a) / 0.34)
	for i in count:
		var along := a + (float(i) + 0.5) * (b - a) / float(count)
		for face: float in [-1.0, 1.0]:
			var pos := _edge_pos(edge, along, y)
			if edge["axis"] == "x": pos.z += face * (WALL_T * 0.5 + 0.08)
			else: pos.x += face * (WALL_T * 0.5 + 0.08)
			transforms.append(Transform3D(Basis.IDENTITY, pos))
	if not transforms.is_empty():
		_kit.multi(edge["room"], mesh, transforms, _kit.mat("wood_dark"))


func _arch_point(edge: Dictionary, along: float, y: float, depth: float) -> Vector3:
	var p := _edge_pos(edge, along, y)
	if edge["axis"] == "x": p.z += depth
	else: p.x += depth
	return p


func _arch_quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> void:
	st.add_vertex(p0)
	st.add_vertex(p1)
	st.add_vertex(p2)
	st.add_vertex(p0)
	st.add_vertex(p2)
	st.add_vertex(p3)
	st.add_vertex(p3)
	st.add_vertex(p2)
	st.add_vertex(p0)
	st.add_vertex(p2)
	st.add_vertex(p1)
	st.add_vertex(p0)


func _arch_mesh(edge: Dictionary, a: float, b: float, top: float, band_inner: float, band_outer: float, cap: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius := (b - a) * 0.5
	var center := (a + b) * 0.5
	var spring := 3.2
	var steps := 40
	for i in steps:
		var theta0 := PI * float(i) / float(steps)
		var theta1 := PI * float(i + 1) / float(steps)
		var x0 := center - radius * cos(theta0)
		var x1 := center - radius * cos(theta1)
		var y0 := spring + radius * sin(theta0)
		var y1 := spring + radius * sin(theta1)
		if cap:
			for face: float in [-WALL_T * 0.5, WALL_T * 0.5]:
				_arch_quad(st, _arch_point(edge, x0, y0, face), _arch_point(edge, x1, y1, face),
					_arch_point(edge, x1, top, face), _arch_point(edge, x0, top, face))
			_arch_quad(st, _arch_point(edge, x0, y0, -WALL_T * 0.5), _arch_point(edge, x1, y1, -WALL_T * 0.5),
				_arch_point(edge, x1, y1, WALL_T * 0.5), _arch_point(edge, x0, y0, WALL_T * 0.5))
		else:
			var inner0 := radius + band_inner
			var inner1 := radius + band_outer
			var in0 := _arch_point(edge, center - inner0 * cos(theta0), spring + inner0 * sin(theta0), 0.0)
			var in1 := _arch_point(edge, center - inner0 * cos(theta1), spring + inner0 * sin(theta1), 0.0)
			var out0 := _arch_point(edge, center - inner1 * cos(theta0), spring + inner1 * sin(theta0), 0.0)
			var out1 := _arch_point(edge, center - inner1 * cos(theta1), spring + inner1 * sin(theta1), 0.0)
			for face: float in [-WALL_T * 0.5 - 0.055, WALL_T * 0.5 + 0.055]:
				var shift := Vector3(0, 0, face) if edge["axis"] == "x" else Vector3(face, 0, 0)
				_arch_quad(st, in0 + shift, in1 + shift, out1 + shift, out0 + shift)
			var d := WALL_T * 0.5 + 0.055
			_arch_quad(st, _arch_point(edge, in0.x if edge["axis"] == "x" else in0.z, in0.y, -d),
				_arch_point(edge, in1.x if edge["axis"] == "x" else in1.z, in1.y, -d),
				_arch_point(edge, in1.x if edge["axis"] == "x" else in1.z, in1.y, d),
				_arch_point(edge, in0.x if edge["axis"] == "x" else in0.z, in0.y, d))
	st.generate_normals()
	return st.commit()


func _build_arch(edge: Dictionary, a: float, b: float, height: float) -> void:
	var id: String = edge["room"]
	_kit.prop(id, _arch_mesh(edge, a, b, height, 0.0, 0.0, true), Transform3D.IDENTITY, _kit.mat(_wall_color(id)))
	_kit.prop(id, _arch_mesh(edge, a, b, height, 0.0, 0.30, false), Transform3D.IDENTITY, _kit.mat("marble_white"))
	_kit.prop(id, _arch_mesh(edge, a, b, height, 0.30, 0.35, false), Transform3D.IDENTITY, _kit.mat("gold"))
	# A projected keystone breaks the continuous ring at its crown.
	_detail(id, _edge_pos(edge, (a + b) * 0.5, 3.2 + (b - a) * 0.5 + 0.18),
		_edge_size(edge, 0.42, 0.38, WALL_T + 0.22), "marble_white")


func _window_segment(edge: Dictionary, a: float, b: float, window: Dictionary) -> void:
	var p: Vector3 = window["pos"]
	var size: Vector2 = window["size"]
	var bottom := p.y - size.y * 0.5
	var top := p.y + size.y * 0.5
	_wall_segment(edge, a, b, 0.0, bottom)
	_wall_segment(edge, a, b, top, _edge_height(edge, (a + b) * 0.5))
	for side: float in [a, b]:
		_detail(edge["room"], _edge_pos(edge, side, p.y),
			_edge_size(edge, 0.18, size.y + 0.22, WALL_T + 0.16), "marble_white")
	for y: float in [bottom, top]:
		_detail(edge["room"], _edge_pos(edge, (a + b) * 0.5, y),
			_edge_size(edge, b - a + 0.20, 0.18, WALL_T + 0.18), "marble_white")
	_detail(edge["room"], _edge_pos(edge, (a + b) * 0.5, bottom - 0.06),
		_edge_size(edge, b - a + 0.48, 0.075, WALL_T + 0.35), "gold")
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
		# Four metre bays, with recessed plaster fields framed by substantial timber beams.
		var nx := maxi(2, int(round(r.size.x / 4.0)))
		var nz := maxi(2, int(round(r.size.y / 4.0)))
		var dx := r.size.x / float(nx)
		var dz := r.size.y / float(nz)
		for ix in range(nx + 1):
			var x := r.position.x + float(ix) * dx
			_detail(room_id, Vector3(x, h - 0.12, r.get_center().y),
				Vector3(0.26, 0.32, r.size.y), "wood_dark")
			_detail(room_id, Vector3(x, h - 0.29, r.get_center().y),
				Vector3(0.32, 0.045, r.size.y), "gold")
		for iz in range(nz + 1):
			var z := r.position.y + float(iz) * dz
			_detail(room_id, Vector3(r.get_center().x, h - 0.12, z),
				Vector3(r.size.x, 0.32, 0.26), "wood_dark")
			_detail(room_id, Vector3(r.get_center().x, h - 0.29, z),
				Vector3(r.size.x, 0.045, 0.32), "gold")
		for ix in nx:
			for iz in nz:
				var c := Vector3(r.position.x + (float(ix) + 0.5) * dx, h - 0.015,
					r.position.y + (float(iz) + 0.5) * dz)
				_detail(room_id, c, Vector3(dx - 0.42, 0.04, dz - 0.42), "ceiling")
		var rosette := SphereMesh.new()
		rosette.radius = 0.17
		rosette.height = 0.10
		var bosses: Array[Transform3D] = []
		for ix in range(1, nx):
			for iz in range(1, nz):
				bosses.append(Transform3D(Basis.IDENTITY, Vector3(r.position.x + float(ix) * dx,
					h - 0.34, r.position.y + float(iz) * dz)))
		if not bosses.is_empty():
			_kit.multi(room_id, rosette, bosses, _kit.mat("brass"))


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
		_atrium_coffers(strip, h)
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


func _atrium_coffers(strip: Rect2, h: float) -> void:
	var nx := maxi(1, int(round(strip.size.x / 3.8)))
	var nz := maxi(1, int(round(strip.size.y / 3.8)))
	var dx := strip.size.x / float(nx)
	var dz := strip.size.y / float(nz)
	for ix in range(nx + 1):
		_detail("atrium", Vector3(strip.position.x + float(ix) * dx, h - 0.12, strip.get_center().y),
			Vector3(0.24, 0.3, strip.size.y), "wood_dark")
	for iz in range(nz + 1):
		_detail("atrium", Vector3(strip.get_center().x, h - 0.12, strip.position.y + float(iz) * dz),
			Vector3(strip.size.x, 0.3, 0.24), "wood_dark")
	for ix in nx:
		for iz in nz:
			_detail("atrium", Vector3(strip.position.x + (float(ix) + 0.5) * dx, h - 0.025,
				strip.position.y + (float(iz) + 0.5) * dz),
				Vector3(dx - 0.38, 0.04, dz - 0.38), "ceiling")
	var boss := SphereMesh.new()
	boss.radius = 0.16
	boss.height = 0.09
	var bosses: Array[Transform3D] = []
	for ix in range(1, nx):
		for iz in range(1, nz):
			bosses.append(Transform3D(Basis.IDENTITY, Vector3(strip.position.x + float(ix) * dx,
				h - 0.32, strip.position.y + float(iz) * dz)))
	if not bosses.is_empty():
		_kit.multi("atrium", boss, bosses, _kit.mat("brass"))


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
		if not service:
			if room_id == "atrium":
				for x: float in [-5.45, 5.45]:
					_pendant(room_id, Vector3(x, 0, 6.0), h, "Chandelier_03", 1.8)
			elif room_id != "foyer" and room_id != "paintings":
				var count := maxi(1, int(ceil(r.size.y / 11.0)))
				for i in count:
					var z := r.position.y + r.size.y * (float(i) + 0.5) / float(count)
					_pendant(room_id, Vector3(r.get_center().x, 0, z), h, "Chandelier_02", 1.55)
			# A soft warm wall bounce keeps faces legible between the fixture pools.
			_kit.omni(room_id, Vector3(r.get_center().x, 2.5, r.get_center().y),
				Color(0.75, 0.78, 0.9), 0.18, minf(13.0, maxf(r.size.x, r.size.y) * 0.5))
		else:
			# Service lamps are built by the room dresser; these are their soft reflected fill.
			var count := maxi(1, int(ceil(maxf(r.size.x, r.size.y) / 12.0)))
			for i in count:
				var fraction := (float(i) + 0.5) / float(count)
				var pos := Vector3(lerpf(r.position.x + 1.2, r.end.x - 1.2, fraction), h - 0.8, r.get_center().y) if r.size.x > r.size.y else Vector3(r.get_center().x, h - 0.8, lerpf(r.position.y + 1.2, r.end.y - 1.2, fraction))
				_kit.omni(room_id, pos, Color(0.76, 0.84, 1.0), 0.22, 6.5)
		if service:
			for offset: float in [0.45, 0.72]:
				var pipe_pos := Vector3(r.position.x + offset, h - 0.42, r.get_center().y)
				var pipe_size := Vector3(0.075, 0.075, r.size.y - 0.5)
				if r.size.x > r.size.y:
					pipe_pos = Vector3(r.get_center().x, h - 0.42, r.position.y + offset)
					pipe_size = Vector3(r.size.x - 0.5, 0.075, 0.075)
				_detail(room_id, pipe_pos, pipe_size, "iron")


func _pendant(room_id: String, floor_pos: Vector3, ceiling_h: float, asset: String, model_h: float) -> void:
	var bottom := ceiling_h - model_h - 0.9
	var p := Vector3(floor_pos.x, bottom, floor_pos.z)
	_kit.model(room_id, asset, Transform3D(Basis.IDENTITY, p), model_h, "none")
	_detail(room_id, Vector3(p.x, ceiling_h - 0.45, p.z), Vector3(0.055, 0.9, 0.055), "brass")
	_detail(room_id, Vector3(p.x, ceiling_h - 0.05, p.z), Vector3(0.36, 0.10, 0.36), "gold")
	_kit.omni(room_id, p + Vector3(0, model_h * 0.48, 0), Color(1.0, 0.73, 0.44), 1.15, 8.0)


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
