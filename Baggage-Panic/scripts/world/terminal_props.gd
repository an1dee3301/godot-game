class_name TerminalProps
extends Node3D
## Passenger concourse recycled alongside the endless track.

const TILE_LENGTH := 24.0
const TILE_COUNT := 12
const FLAGS := Flags.CODES
const DESTINATIONS := ["LAX", "NRT", "CDG", "SYD", "JFK", "DXB", "LHR", "SGN"]
const CLOTHES := [Color("b5694a"), Color("4f6a7a"), Color("c99a45"), Color("6b5a78"), Color("7a8a5e"), Color("2f2c29")]

static var _mesh_cache: Dictionary = {}
static var _material_cache: Dictionary = {}
var _tiles: Array[Node3D] = []
var _flags: Array[Node3D] = []
var _walkers: Array[Node3D] = []
var _flights: Array[Dictionary] = []
var _board_rows: Array[Dictionary] = []
var _clocks: Array[Dictionary] = []
var _clock_elapsed := 5.0
var _time := 0.0
var _status_level := -1
var _board_elapsed := 0.0
var _scroll_offset := 0


func _ready() -> void:
	for i in TILE_COUNT:
		var tile := Node3D.new()
		tile.name = "Concourse%02d" % i
		tile.position.z = TILE_LENGTH - float(i) * TILE_LENGTH
		add_child(tile)
		_tiles.append(tile)
		_build_tile(tile, i)
		DesignKit.optimize(tile, 85.0, 0.6)
	set_process(true)
	set_intensity(0.0)
	_refresh_flights(true)


func _process(delta: float) -> void:
	_time += delta
	_board_elapsed += delta
	if _board_elapsed >= 24.0:
		_board_elapsed = 0.0
		_scroll_offset += 1
		_refresh_flights(false)
	_clock_elapsed += delta
	if _clock_elapsed >= 5.0:
		_clock_elapsed = 0.0
		_update_clocks()
	for i in _flags.size():
		_flags[i].rotation.y = sin(_time * 1.4 + float(i) * 0.7) * 0.12
	for i in _walkers.size():
		var walker := _walkers[i]
		walker.position.z = fposmod(walker.position.z - delta * (0.5 + float(i % 4) * 0.16), TILE_LENGTH) - TILE_LENGTH


func follow(player_z: float) -> void:
	for tile in _tiles:
		while tile.position.z > player_z + TILE_LENGTH * 2.0:
			tile.position.z -= TILE_COUNT * TILE_LENGTH


## 0..1 rush-hour progression (same value AirportEnvironment receives).
func set_intensity(amount: float) -> void:
	var level := 0 if amount < 0.34 else (1 if amount < 0.7 else 2)
	if level == _status_level:
		return
	_status_level = level
	_refresh_flights(false)
	var light: StandardMaterial3D = _material_cache.get("shop_light")
	if light != null:
		light.emission_energy_multiplier = 0.2 + float(level) * 0.22


func _refresh_flights(immediate: bool) -> void:
	for item in _flights:
		var id := int(item.id) + _scroll_offset
		var iata: String = DESTINATIONS[id % DESTINATIONS.size()]
		var status := _flight_status(id, _status_level)
		var board: SplitFlapBoard = item.board
		var text := "DN%03d  %s" % [210 + id * 7, iata]
		if immediate:
			board.set_text_immediate(0, text, Color("f2e6c7"))
			board.set_text_immediate(1, status, _status_color(status))
		else:
			board.set_row(0, text, Color("f2e6c7"))
			board.set_row(1, status, _status_color(status))
	for item in _board_rows:
		var board: SplitFlapBoard = item.board
		var arrival: bool = item.arrival
		for row in 6:
			var id := int(item.id) + row + _scroll_offset
			var iata: String = DESTINATIONS[id % DESTINATIONS.size()]
			var airport := AirportData.get_airport(iata)
			var city := str(airport.city).to_upper().substr(0, 10)
			var gate := "%s%02d" % ["A" if int(item.side) < 0 else "B", 1 + (id % 12)]
			var status := _arrival_status(id, _status_level) if arrival else _flight_status(id, _status_level)
			var caption := "%02d:%02d %-10s %-3s %-8s" % [8 + id % 12, (id * 7) % 60, city, gate, status.substr(0, 8)]
			if immediate:
				board.set_text_immediate(row + 1, caption, _status_color(status))
			else:
				board.set_row(row + 1, caption, _status_color(status))


func _arrival_status(id: int, level: int) -> String:
	if level > 0 and id % 4 == 0:
		return "DELAYED"
	return "LANDED" if id % 3 == 0 else ("EXPECTED" if id % 3 == 1 else "ON TIME")


func _flight_status(id: int, level: int) -> String:
	if level > 1 and id % 3 == 1:
		return "FINAL CALL"
	if level > 0 and id % 4 == 0:
		return "DELAYED"
	return "BOARDING" if id % 3 == 0 else "ON TIME"


func _status_color(status: String) -> Color:
	match status:
		"BOARDING", "LANDED": return Color("82e0a4")
		"FINAL CALL": return Color("ff7f7b")
		"DELAYED", "EXPECTED": return Color("ffd17a")
	return Color("eef2ea")


## Each 24 m section is one zone per side, so the concourse reads as places rather than clutter:
## the promenade (|x| 9-16) stays open, and the window side (|x| 17-29) holds a gate lounge, a
## retail + café island or a quiet lounge, all kept low so the apron stays in view.
enum Zone { GATE, RETAIL, LOUNGE }


func _build_tile(tile: Node3D, index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9087 + index * 317
	for side in [-1, 1]:
		var s := float(side)
		_build_walkway(tile, s)
		_build_flags(tile, s, index)
		var zone := (index + (0 if side < 0 else 1)) % 3
		match zone:
			Zone.GATE:
				_build_gate(tile, s, index)
			Zone.RETAIL:
				_build_shop(tile, s, index)
				_build_food(tile, s)
			Zone.LOUNGE:
				_build_lounge(tile, s, index)
		if (index + side) % 2 == 0:
			_build_directory(tile, s, index)
		if index == 0:
			_build_clocks(tile, s)
		if zone == Zone.GATE:
			_build_people(tile, s, index, rng, zone)
		if index % 4 == 0:
			_build_trolley(tile, s)


func _build_walkway(tile: Node3D, side: float) -> void:
	_box(tile, Vector3(side * 8.2, -0.48, -12.0), Vector3(2.1, 0.04, 24.0), _mat("walkway", Color("4a4540")))
	for x in [7.1, 9.3]:
		_box(tile, Vector3(side * x, -0.42, -12.0), Vector3(0.07, 0.07, 24.0), _mat("travelator_edge", Color("c9a26b"), true))
	for i in 8:
		_box(tile, Vector3(side * 8.2, -0.45, -1.0 - float(i) * 3.0), Vector3(1.5, 0.025, 0.12), _mat("walkway_dash", Color("b8ad9c")))


func _build_flags(tile: Node3D, side: float, index: int) -> void:
	for j in 4:
		var country: String = FLAGS[(index * 4 + j + (0 if side < 0.0 else 7)) % FLAGS.size()]
		var z := -2.5 - float(j) * 5.5
		_box(tile, Vector3(side * 11.3, 5.35, z), Vector3(0.045, 0.8, 0.045), _mat("pole", Color("2f2c29")))
		var pivot := Node3D.new()
		pivot.name = "Flag_" + country
		pivot.position = Vector3(side * 11.3, 4.9, z)
		tile.add_child(pivot)
		var flag_width := 0.86 * Flags.aspect(country)
		var center := Vector3(side * (flag_width * 0.5 + 0.03), 0.0, 0.0)
		_quad(pivot, center + Vector3(0.0, 0.0, 0.008), Vector2(flag_width, 0.86), _flag_mat(country))
		var rear := _quad(pivot, center + Vector3(0.0, 0.0, -0.008), Vector2(flag_width, 0.86), _flag_mat(country))
		rear.rotation_degrees.y = 180.0
		_flags.append(pivot)
	_box(tile, Vector3(side * 12.0, 1.65, -12.5), Vector3(0.06, 4.3, 0.06), _mat("pole", Color("2f2c29")))
	_box(tile, Vector3(side * 12.0, -0.45, -12.5), Vector3(0.6, 0.1, 0.6), _mat("ink", Color("2b2926")))


func _build_gate(tile: Node3D, side: float, index: int) -> void:
	var gate := "%s%02d" % ["A" if side < 0.0 else "B", 1 + index]
	var accent := _mat("gate_%d" % (index % 3), [Color("c99a45"), Color("8a9a7b"), Color("b5694a")][index % 3])
	# Carpeted holdroom against the glass.
	DesignKit.rbox(tile, Vector3(11.8, 0.03, 21.0), Vector3(side * 23.4, -0.495, -12.0), DesignKit.fabric(Color(0.55, 0.56, 0.48), "carpet"), 0.01, false)
	_box(tile, Vector3(side * 17.55, -0.47, -12.0), Vector3(0.1, 0.05, 21.0), accent)
	# Podium by the promenade: oak body, charcoal top, brass kick plate; multilingual gate sign above.
	var z := -2.6
	var oak := DesignKit.wood()
	DesignKit.rbox(tile, Vector3(1.0, 1.05, 2.6), Vector3(side * 18.6, 0.03, z), oak, 0.06)
	DesignKit.rbox(tile, Vector3(1.15, 0.06, 2.75), Vector3(side * 18.6, 0.58, z), DesignKit.metal(DesignKit.CHARCOAL, 0.45, 0.2, "desk_top"), 0.02)
	DesignKit.rbox(tile, Vector3(1.02, 0.08, 2.62), Vector3(side * 18.6, -0.45, z), DesignKit.brass(), 0.01)
	var gate_sign := Signage.hanging(tile, Vector3(side * 18.6, 3.9, z), "gate", {"suffix": gate, "width": 3.0, "compact": true, "double_sided": true, "accent": accent.albedo_color}, 2.2)
	gate_sign.rotation_degrees.y = -90.0 if side > 0.0 else 90.0
	var gate_board := SplitFlapBoard.new()
	gate_board.position = Vector3(side * (18.6 - 0.09), 3.05, z)
	gate_board.rotation_degrees.y = -90.0 if side > 0.0 else 90.0
	tile.add_child(gate_board)
	gate_board.setup(18, 2, Vector2(0.094, 0.32))
	_flights.append({"board": gate_board, "id": index * 2 + (0 if side < 0.0 else 1)})
	# Seat rows facing the windows: upholstered seats and backs on an oak beam with steel legs.
	var fabric := DesignKit.fabric([DesignKit.LINEN, DesignKit.SAGE, Color(0.66, 0.58, 0.5)][index % 3], "seat_%d" % (index % 3))
	var seat_mesh := DesignKit.rounded_box(Vector3(0.62, 0.16, 0.56), 0.06)
	var back_mesh := DesignKit.rounded_box(Vector3(0.1, 0.58, 0.56), 0.05)
	var arm_mesh := DesignKit.rounded_box(Vector3(0.5, 0.06, 0.07), 0.025)
	var seats := MultiMesh.new()
	seats.transform_format = MultiMesh.TRANSFORM_3D
	seats.mesh = seat_mesh
	var backs := MultiMesh.new()
	backs.transform_format = MultiMesh.TRANSFORM_3D
	backs.mesh = back_mesh
	var arms := MultiMesh.new()
	arms.transform_format = MultiMesh.TRANSFORM_3D
	arms.mesh = arm_mesh
	var spots: Array[Vector3] = []
	var arm_spots: Array[Vector3] = []
	for row in 4:
		var x := side * (20.4 + float(row) * 2.1)
		for block in 2:
			var z0 := -5.2 - float(block) * 7.8
			DesignKit.rbox(tile, Vector3(0.18, 0.1, 6.4), Vector3(x - side * 0.05, -0.3, z0 - 2.73), oak, 0.03)
			for leg in [z0 - 0.2, z0 - 5.26]:
				DesignKit.rbox(tile, Vector3(0.5, 0.2, 0.06), Vector3(x - side * 0.05, -0.43, leg), DesignKit.metal(), 0.02)
			for k in 8:
				spots.append(Vector3(x, -0.17, z0 - float(k) * 0.78))
				arm_spots.append(Vector3(x - side * 0.04, 0.05, z0 - float(k) * 0.78 + 0.39))
	seats.instance_count = spots.size()
	backs.instance_count = spots.size()
	arms.instance_count = arm_spots.size()
	for k in spots.size():
		seats.set_instance_transform(k, Transform3D(Basis.IDENTITY, spots[k]))
		backs.set_instance_transform(k, Transform3D(Basis.from_euler(Vector3(0.0, 0.0, side * 0.12)), spots[k] + Vector3(-side * 0.32, 0.33, 0.0)))
		arms.set_instance_transform(k, Transform3D(Basis.IDENTITY, arm_spots[k]))
	_multi_mat(tile, seats, fabric)
	_multi_mat(tile, backs, fabric)
	_multi_mat(tile, arms, oak)
	# Bridge door in the curtain wall.
	var frame := DesignKit.metal()
	var door_z := -11.8
	for dz in [-1.3, 1.3]:
		_box(tile, Vector3(side * 29.45, 1.15, door_z + dz), Vector3(0.3, 3.3, 0.18), frame)
	_box(tile, Vector3(side * 29.45, 2.85, door_z), Vector3(0.3, 0.2, 2.8), frame)
	_box(tile, Vector3(side * 29.4, 1.15, door_z), Vector3(0.06, 3.2, 2.4), DesignKit.paint(Color(0.55, 0.62, 0.64), 0.08))
	var door_label := _label(tile, gate, Vector3(side * 29.25, 3.3, door_z), Color("f6e8c9"), 30, 0.008)
	door_label.rotation_degrees.y = -90.0 if side > 0.0 else 90.0


func _build_shop(tile: Node3D, side: float, index: int) -> void:
	var colors := [DesignKit.CLAY, DesignKit.SAGE, DesignKit.INDIGO, DesignKit.OCHRE]
	var kind := index % 4
	var x := side * 19.0
	var z := -6.5
	# A low island pod: oak counter with brass trim under a slim canopy and a washi light box.
	var oak := DesignKit.wood()
	DesignKit.rbox(tile, Vector3(5.2, 0.05, 6.2), Vector3(x, -0.48, z), DesignKit.wood(DesignKit.WALNUT, "walnut"), 0.02, false)
	DesignKit.rbox(tile, Vector3(3.6, 1.05, 4.6), Vector3(x, 0.03, z), oak, 0.12)
	DesignKit.rbox(tile, Vector3(3.8, 0.06, 4.8), Vector3(x, 0.58, z), DesignKit.stone(DesignKit.LIMESTONE, 0.3, "counter"), 0.03)
	DesignKit.rbox(tile, Vector3(3.62, 0.05, 4.62), Vector3(x, -0.42, z), DesignKit.brass(), 0.02)
	DesignKit.rbox(tile, Vector3(1.4, 1.2, 3.4), Vector3(x, 1.2, z), DesignKit.wood(DesignKit.WALNUT, "walnut"), 0.08)
	for shelf_y in [0.9, 1.3, 1.7]:
		DesignKit.rbox(tile, Vector3(1.6, 0.04, 3.5), Vector3(x, shelf_y, z), oak, 0.015)
	for corner in [Vector2(-1.8, -2.3), Vector2(1.8, -2.3), Vector2(-1.8, 2.3), Vector2(1.8, 2.3)]:
		DesignKit.rbox(tile, Vector3(0.08, 2.2, 0.08), Vector3(x + corner.x, 1.55, z + corner.y), DesignKit.metal(), 0.03)
	DesignKit.rbox(tile, Vector3(4.6, 0.12, 5.6), Vector3(x, 2.7, z), oak, 0.05)
	DesignKit.rbox(tile, Vector3(4.2, 0.32, 5.2), Vector3(x, 2.52, z), DesignKit.washi(Color(1.0, 0.9, 0.74), 1.4, "kiosk"), 0.08, false)
	var keys := ["duty_free", "cafe", "news", "sushi"]
	var shop_sign := Signage.panel(tile, Vector3(x, 3.35, z + 2.3), keys[kind], {"compact": true, "width": 3.6, "double_sided": true, "accent": colors[kind]})
	shop_sign.name = "ShopSign"
	_build_poster(tile, side, index)


func _build_directory(tile: Node3D, side: float, index: int) -> void:
	# Hung over the promenade, facing the oncoming belts.
	var x := side * 12.6
	var z := -16.0
	for cable_x in [-2.2, 2.2]:
		_box(tile, Vector3(x + cable_x, 7.6, z), Vector3(0.03, 3.4, 0.03), _mat("pole", Color("2f2c29")))
	DesignKit.rbox(tile, Vector3(5.1, 3.1, 0.22), Vector3(x, 4.7, z), DesignKit.wood(DesignKit.WALNUT, "walnut"), 0.06)
	var board := SplitFlapBoard.new()
	board.position = Vector3(x, 4.75, z + 0.16)
	tile.add_child(board)
	board.setup(29, 7, Vector2(0.16, 0.36))
	var arrival := index % 2 == 1
	board.set_text_immediate(0, "ARRIVALS" if arrival else "DEPARTURES", Color("f6cf7b"))
	_board_rows.append({"board": board, "id": index * 6, "side": int(side), "arrival": arrival})
	var keys := ["gates", "baggage_claim", "toilets", "exit"]
	var key: String = keys[(index + (0 if side < 0.0 else 1)) % keys.size()]
	var arrow := "up" if key == "gates" else ("right" if side < 0.0 else "left")
	Signage.panel(tile, Vector3(x, 2.55, z), key, {"width": 4.6, "arrow": arrow, "suffix": "A1–B12" if key == "gates" else "", "double_sided": true})


func _build_clocks(tile: Node3D, side: float) -> void:
	var codes := ["LAX", "JFK", "LHR", "CDG", "DXB", "SGN", "NRT", "SYD"]
	for i in codes.size():
		var iata: String = codes[i]
		var airport := AirportData.get_airport(iata)
		var column := i % 4
		var row := i / 4
		var x := side * (15.0 + float(column) * 3.5)
		var y := 5.6 - float(row) * 0.7
		var z := -23.0
		_box(tile, Vector3(x, y, z), Vector3(3.2, 0.58, 0.1), _mat("ink", Color("2b2926")))
		var label := _label(tile, "", Vector3(x, y, z + 0.08), Color("f2e6c7"), 16, 0.0045)
		var clock_city := "TOKYO" if iata == "NRT" else str(airport.city).to_upper()
		_clocks.append({"label": label, "iata": iata, "city": clock_city})
	_update_clocks()


func _update_clocks() -> void:
	var now := Time.get_unix_time_from_system()
	for clock in _clocks:
		var local := AirportData.local_time(str(clock.iata), now)
		var label: Label3D = clock.label
		label.text = "%s  %02d:%02d" % [clock.city, local.hour, local.minute]


## Seated passengers in the gate lounges (walkers and standing people come from ConcourseDressing).
func _build_people(tile: Node3D, side: float, index: int, rng: RandomNumberGenerator, _zone: int) -> void:
	var bodies := MultiMesh.new()
	bodies.transform_format = MultiMesh.TRANSFORM_3D
	bodies.use_colors = true
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.2
	capsule.height = 0.8
	capsule.radial_segments = 10
	capsule.rings = 3
	bodies.mesh = capsule
	bodies.instance_count = 6
	var heads := MultiMesh.new()
	heads.transform_format = MultiMesh.TRANSFORM_3D
	heads.use_colors = true
	heads.mesh = _sphere_mesh(0.2)
	heads.instance_count = 6
	for k in 6:
		var x := side * (20.4 + float(rng.randi_range(0, 3)) * 2.1)
		var z := -5.2 - float(rng.randi_range(0, 7)) * 0.78 - float(rng.randi_range(0, 1)) * 7.8
		bodies.set_instance_transform(k, Transform3D(Basis.IDENTITY, Vector3(x - side * 0.08, 0.22, z)))
		bodies.set_instance_color(k, CLOTHES[(index + k) % CLOTHES.size()])
		heads.set_instance_transform(k, Transform3D(Basis.IDENTITY, Vector3(x - side * 0.1, 0.78, z)))
		heads.set_instance_color(k, Color("e8b895") if k % 3 != 0 else Color("986b59"))
	_multi(tile, bodies)
	_multi(tile, heads)


func _build_food(tile: Node3D, side: float) -> void:
	# Café tables by the window: turned oak tops on a single steel stem, oak chairs.
	var top := DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.5, 0.0), Vector2(0.52, 0.02), Vector2(0.52, 0.05), Vector2(0.5, 0.07), Vector2(0.0, 0.07)]), 24)
	var stem := DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.28, 0.0), Vector2(0.28, 0.03), Vector2(0.04, 0.05), Vector2(0.04, 0.72), Vector2(0.0, 0.72)]), 16)
	for j in 6:
		var x := side * (23.5 + float(j % 2) * 3.0)
		var z := -3.5 - float(j / 2) * 3.4
		DesignKit.add(tile, stem, DesignKit.metal(), Vector3(x, -0.5, z))
		DesignKit.add(tile, top, DesignKit.wood(), Vector3(x, 0.22, z))
		for dz in [-0.78, 0.78]:
			var facing := 1.0 if dz < 0.0 else -1.0
			DesignKit.rbox(tile, Vector3(0.46, 0.06, 0.44), Vector3(x, -0.05, z + dz), DesignKit.wood(), 0.025)
			DesignKit.rbox(tile, Vector3(0.44, 0.38, 0.05), Vector3(x, 0.18, z + dz - facing * 0.2), DesignKit.wood(), 0.025)
			for leg in [Vector2(-0.18, -0.17), Vector2(0.18, -0.17), Vector2(-0.18, 0.17), Vector2(0.18, 0.17)]:
				DesignKit.rbox(tile, Vector3(0.035, 0.42, 0.035), Vector3(x + leg.x, -0.29, z + dz + leg.y), DesignKit.metal(), 0.012, false)


func _build_lounge(tile: Node3D, side: float, index: int) -> void:
	# Quiet window lounge: long stone planters framing slatted oak benches that face the apron.
	var stone := DesignKit.stone(Color(0.62, 0.6, 0.56), 0.7, "planter")
	for z in [-3.0, -21.0]:
		DesignKit.rbox(tile, Vector3(10.0, 0.7, 1.2), Vector3(side * 23.0, -0.15, z), stone, 0.12)
		DesignKit.rbox(tile, Vector3(9.7, 0.04, 0.9), Vector3(side * 23.0, 0.2, z), DesignKit.paint(Color(0.24, 0.2, 0.16), 0.95), 0.01, false)
		for k in 5:
			_build_plant(tile, Vector3(side * (19.0 + float(k) * 2.0), 0.2, z), 0.8 + float((index + k) % 3) * 0.15)
	for row in 3:
		for k in 3:
			_build_bench(tile, Vector3(side * (20.5 + float(row) * 2.8), 0.0, -7.0 - float(k) * 4.4), side)
	for z in [-1.0, -23.0]:
		var bowl := DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.42, 0.0), Vector2(0.62, 0.25), Vector2(0.68, 0.7), Vector2(0.6, 0.72), Vector2(0.55, 0.66), Vector2(0.0, 0.66)]), 28)
		DesignKit.add(tile, bowl, stone, Vector3(side * 16.5, -0.5, z))
		_build_plant(tile, Vector3(side * 16.5, 0.15, z), 1.6)


func _build_bench(tile: Node3D, at: Vector3, side: float) -> void:
	var oak := DesignKit.wood()
	for slat in 4:
		DesignKit.rbox(tile, Vector3(0.15, 0.05, 3.2), at + Vector3(side * (-0.24 + float(slat) * 0.16), -0.1, 0.0), oak, 0.02)
	for leg_z in [-1.35, 1.35]:
		DesignKit.rbox(tile, Vector3(0.7, 0.05, 0.06), at + Vector3(0.0, -0.15, leg_z), DesignKit.metal(), 0.02)
		for leg_x in [-0.3, 0.3]:
			DesignKit.rbox(tile, Vector3(0.05, 0.36, 0.05), at + Vector3(leg_x, -0.33, leg_z), DesignKit.metal(), 0.02, false)


## A slender tree: tapered trunk and a soft, layered canopy in muted greens.
func _build_plant(tile: Node3D, at: Vector3, size: float) -> void:
	var trunk := DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.07, 0.0), Vector2(0.045, 1.0), Vector2(0.0, 1.0)]), 8)
	DesignKit.add(tile, trunk, DesignKit.wood(DesignKit.WALNUT, "walnut"), at, Vector3.ZERO).scale = Vector3(size, size, size)
	var greens := [Color(0.37, 0.47, 0.32), Color(0.45, 0.55, 0.36), Color(0.31, 0.41, 0.3)]
	for j in 7:
		var a := float(j) * TAU / 7.0 + size
		var r := 0.32 if j % 2 == 0 else 0.18
		var leaf := _sphere(tile, at + Vector3(cos(a) * r, 0.95 + float(j % 3) * 0.16, sin(a) * r) * size, 0.34 * size, DesignKit.fabric(greens[j % 3], "leaf_%d" % (j % 3)))
		leaf.scale = Vector3(1.0, 0.75, 1.0)
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _build_poster(tile: Node3D, side: float, index: int) -> void:
	# Lightbox poster standing at the front of the retail island, facing the oncoming belts.
	var x := side * 15.2
	var z := -3.0
	DesignKit.rbox(tile, Vector3(1.9, 2.9, 0.16), Vector3(x, 1.2, z), DesignKit.wood(DesignKit.WALNUT, "walnut"), 0.05)
	_quad(tile, Vector3(x, 1.35, z + 0.1), Vector2(1.6, 2.1), _poster_mat(index % 3))
	_label(tile, ["EXPLORE THE COAST", "DISCOVER THE ALPS", "CITY LIGHTS AWAIT"][index % 3], Vector3(x, 0.05, z + 0.11), Color("fff2d5"), 22, 0.004)


func _build_trolley(tile: Node3D, side: float) -> void:
	var x := side * 22.0
	_box(tile, Vector3(x, -0.1, -11.0), Vector3(1.4, 0.14, 0.8), _mat("trolley", Color("8f8a83")))
	_box(tile, Vector3(x, 0.42, -11.35), Vector3(1.3, 1.05, 0.08), _mat("trolley", Color("8f8a83")))
	_box(tile, Vector3(x, 0.22, -11.0), Vector3(0.8, 0.62, 0.5), _mat("trolley_bag", Color("e88b5b")))
	for dx in [-0.55, 0.55]:
		_box(tile, Vector3(x + dx, -0.4, -11.0), Vector3(0.18, 0.18, 0.18), _mat("ink", Color("2b2926")))


func _flag_mat(country: String) -> StandardMaterial3D:
	var key := "flag_" + country
	if _material_cache.has(key):
		return _material_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = Flags.texture(country)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	_material_cache[key] = mat
	return mat


func _poster_mat(kind: int) -> StandardMaterial3D:
	var key := "poster_%d" % kind
	if _material_cache.has(key):
		return _material_cache[key]
	var image := Image.create(72, 96, false, Image.FORMAT_RGBA8)
	for y in 96:
		var top: Color = [Color("f3a679"), Color("596bb1"), Color("233d74")][kind]
		var bottom: Color = [Color("5bc0ca"), Color("e9be83"), Color("cf628b")][kind]
		image.fill_rect(Rect2i(0, y, 72, 1), top.lerp(bottom, float(y) / 95.0))
	if kind == 0:
		_circle(image, Vector2(52, 29), 13, Color("f9d681"))
		image.fill_rect(Rect2i(0, 60, 72, 36), Color("3394b7"))
	elif kind == 1:
		for x in 72:
			var height := int(23.0 * absf(sin(float(x) * 0.075)))
			image.fill_rect(Rect2i(x, 70 - height, 1, 26 + height), Color("e6e9e0"))
	else:
		for x in range(4, 72, 12):
			image.fill_rect(Rect2i(x, 45 - x % 18, 9, 51), Color("26395b"))
			for y in range(63, 90, 8):
				image.fill_rect(Rect2i(x + 3, y, 2, 3), Color("ffd98a"))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(image)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_cache[key] = mat
	return mat


func _ellipse(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	for y in range(maxi(0, int(center.y - radius.y)), mini(image.get_height(), int(center.y + radius.y))):
		for x in range(maxi(0, int(center.x - radius.x)), mini(image.get_width(), int(center.x + radius.x))):
			var normalized := (Vector2(float(x), float(y)) - center) / radius
			if normalized.length_squared() <= 1.0:
				image.set_pixel(x, y, color)


func _circle(image: Image, center: Vector2, radius: int, color: Color) -> void:
	for y in range(maxi(0, int(center.y) - radius), mini(image.get_height(), int(center.y) + radius)):
		for x in range(maxi(0, int(center.x) - radius), mini(image.get_width(), int(center.x) + radius)):
			if Vector2(float(x), float(y)).distance_to(center) <= float(radius):
				image.set_pixel(x, y, color)


func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = _mesh(size)
	node.position = at
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


func _quad(parent: Node3D, at: Vector3, size: Vector2, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	node.mesh = quad
	node.position = at
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


func _sphere(parent: Node3D, at: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = _sphere_mesh(radius)
	node.position = at
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


func _label(parent: Node3D, caption: String, at: Vector3, color: Color, size: int, pixels: float) -> Label3D:
	var label := Label3D.new()
	label.text = caption
	label.position = at
	label.modulate = color
	label.font_size = size
	label.pixel_size = pixels
	label.double_sided = false
	label.visibility_range_end = 55.0 if size <= 25 else 75.0
	label.visibility_range_end_margin = 12.0
	parent.add_child(label)
	return label


func _multi(parent: Node3D, multimesh: MultiMesh) -> void:
	var node := MultiMeshInstance3D.new()
	node.multimesh = multimesh
	var instance_mat := _mat("colored_instances", Color.WHITE)
	instance_mat.vertex_color_use_as_albedo = true
	node.material_override = instance_mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)


func _multi_mat(parent: Node3D, multimesh: MultiMesh, material: Material) -> void:
	var node := MultiMeshInstance3D.new()
	node.multimesh = multimesh
	node.material_override = material
	parent.add_child(node)


func _mesh(size: Vector3) -> BoxMesh:
	var key := "box_%0.3f_%0.3f_%0.3f" % [size.x, size.y, size.z]
	if not _mesh_cache.has(key):
		var box := BoxMesh.new()
		box.size = size
		_mesh_cache[key] = box
	return _mesh_cache[key]


func _sphere_mesh(radius: float) -> SphereMesh:
	var key := "sphere_%0.3f" % radius
	if not _mesh_cache.has(key):
		var sphere := SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 2.0
		sphere.radial_segments = 8
		sphere.rings = 4
		_mesh_cache[key] = sphere
	return _mesh_cache[key]


func _mat(key: String, color: Color, emissive: bool = false) -> StandardMaterial3D:
	if not _material_cache.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.68
		if emissive:
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = 0.35
		_material_cache[key] = mat
	return _material_cache[key]
