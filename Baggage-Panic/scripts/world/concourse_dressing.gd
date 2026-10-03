extends Node3D
## Dresses the concourse with the generated modules (props, people, graphics) in the free slots of
## each TerminalProps zone. Uses TerminalProps' exact tiling so placements line up with its layout.
## Modules are discovered at runtime; any that are missing or fail to load are simply skipped.

const TILE_LENGTH := 24.0
const TILE_COUNT := 12
const FLOOR_Y := -0.5
const GATE := 0
const RETAIL := 1
const LOUNGE := 2

const GATE_BACK := ["vending_machine", "charging_station", "luggage_lockers", "water_refill", "recycle_bins", "plant_wall", "bench_long", "trolley_rack", "first_aid", "massage_chairs", "sleep_pods", "window_bar", "security_bins", "cleaning_cart"]
const GATE_ISLAND := ["bonsai_display", "ikebana_stand", "stone_sculpture", "ad_totem", "info_screen", "clock_tower", "aircraft_model", "info_desk", "gate_totem", "koban", "cleaning_robot", "floor_lamp", "bicycle_display", "gate_barrier"]
const STALLS := ["ramen_stall", "sushi_counter", "espresso_bar", "bento_display", "tea_shop", "chocolate_shop", "perfume_counter", "whisky_wall", "fashion_boutique", "electronics_store", "souvenir_shelf", "pharmacy", "buffet_counter", "lounge_reception", "lost_found", "check_in_desk", "noren_entrance", "bookshelf"]
const RETAIL_SMALL := ["gacha_row", "umbrella_stand", "sunglasses_stand", "magazine_rack", "atm", "exchange_booth", "bag_wrap", "sake_display", "bar_stools", "flower_bed"]
## Second lounge slot (back of the promenade) and lounge furniture.
const LOUNGE_BACK := ["kids_play", "nursing_pod", "water_feature", "column_tree", "seating_cluster", "glass_elevator"]
const LOUNGE_SET := ["sofa", "armchair", "coffee_table", "floor_lamp"]
## Architecture: big pieces along the promenade, every few tiles.
const ARCHITECTURE := ["escalator", "stairs", "mezzanine", "glass_balustrade"]
const LOUNGE_FEATURE := ["zen_garden", "koi_pond", "tea_house", "torii_gate", "andon_lantern", "stone_lantern", "bamboo_grove", "cherry_tree", "maple_tree", "wood_screen", "public_piano", "daruma_display", "destination_cubes"]
const OVERHEAD := ["lantern_festival", "slat_ceiling_cloud", "hanging_mobile", "banner_set", "flight_path_ceiling", "skylight_frame"]
const FEATURE_WALLS := ["route_map_wall", "welcome_wall", "fids_wall", "kanji_wall", "world_clocks", "art_mural"]
const POSTERS := ["poster_tokyo", "poster_hanoi", "poster_paris", "poster_barcelona", "poster_shanghai", "lightbox_ad"]
const WATCHERS := ["photographer", "tourist", "kid", "student", "family"]
const WALKERS := ["business", "backpacker", "family", "attendant", "pilot", "couple", "student", "elder", "security", "customs", "wheelchair", "ground_staff", "cleaner", "monk", "tourist"]

static var _scripts: Dictionary = {}   ## short name -> GDScript (e.g. "ramen_stall")

var _tiles: Array[Node3D] = []
var _walkers: Array[Dictionary] = []
var _time := 0.0


func _ready() -> void:
	_discover()
	for i in TILE_COUNT:
		var tile := Node3D.new()
		tile.name = "Dressing%02d" % i
		tile.position.z = TILE_LENGTH - float(i) * TILE_LENGTH
		add_child(tile)
		_tiles.append(tile)
		_build_tile(tile, i)


func follow(player_z: float) -> void:
	for tile in _tiles:
		while tile.position.z > player_z + TILE_LENGTH * 2.0:
			tile.position.z -= TILE_COUNT * TILE_LENGTH


func set_intensity(_amount: float) -> void:
	pass


func _process(delta: float) -> void:
	_time += delta
	for w in _walkers:
		var node: Node3D = w.node
		var speed: float = w.speed
		var z := fposmod(float(w.z0) + _time * speed + TILE_LENGTH, TILE_LENGTH) - TILE_LENGTH
		node.position.z = z
		node.position.y = FLOOR_Y + absf(sin(_time * 7.0 * absf(speed) + float(w.z0))) * 0.02


# --- Discovery ---------------------------------------------------------------------------------

static func _discover() -> void:
	if not _scripts.is_empty():
		return
	for folder in ["props", "people", "graphics"]:
		var dir := "res://scripts/world/%s" % folder
		if not DirAccess.dir_exists_absolute(dir):
			continue
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".gd") or file.begins_with("prop_example"):
				continue
			var script := load(dir.path_join(file)) as GDScript
			if script == null or not script.can_instantiate():
				continue
			var short := file.get_basename()
			for prefix in ["prop_", "person_", "graphic_"]:
				short = short.trim_prefix(prefix)
			_scripts[short] = script


## First available module from `names`, rotated by `pick` so tiles differ.
func _choose(names: Array, pick: int) -> String:
	var available: Array[String] = []
	for n: String in names:
		if _scripts.has(n):
			available.append(n)
	if available.is_empty():
		return ""
	return available[posmod(pick, available.size())]


func _place(parent: Node3D, names: Array, pick: int, at: Vector3, rot_y: float, variant: int = -1) -> Node3D:
	var key := _choose(names, pick)
	if key == "":
		return null
	var script: GDScript = _scripts[key]
	var built: Variant = script.call("build", parent, at, rot_y, posmod(variant if variant >= 0 else pick, 4))
	var node := built as Node3D
	if node != null:
		DesignKit.declutter_labels(node)
		DesignKit.batch_repeated(node)
		var is_person := key in WALKERS or key in WATCHERS or key == "chef"
		DesignKit.optimize(node, 38.0 if is_person else 70.0, 1.2 if is_person else 0.8)
	return node


# --- Layout ------------------------------------------------------------------------------------

func _build_tile(tile: Node3D, index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 51511 + index * 7919
	for side_i in [-1, 1]:
		var side := float(side_i)
		var zone := (index + (0 if side_i < 0 else 1)) % 3
		var pick := index * 2 + (0 if side_i < 0 else 1)
		# Fronts face +Z by default: face the promenade with -90*side, the glass with +90*side.
		var to_promenade := -90.0 * side
		var to_glass := 90.0 * side
		match zone:
			GATE:
				_place(tile, GATE_BACK, pick, Vector3(side * 21.0, FLOOR_Y, -21.4), 0.0)
				_place(tile, GATE_BACK, pick + 3, Vector3(side * 26.0, FLOOR_Y, -21.4), 0.0)
				_place(tile, GATE_ISLAND, pick, Vector3(side * 14.5, FLOOR_Y, -9.0), to_promenade)
				_place(tile, ["floor_gate_mark"], 0, Vector3(side * 18.0, FLOOR_Y + 0.005, -0.6), 0.0, index)
				for k in 1 + rng.randi_range(0, 1):
					_place(tile, WATCHERS, pick + k, Vector3(side * 28.1, FLOOR_Y, -5.0 - float(k) * 5.5 - rng.randf_range(0.0, 2.0)), to_glass, rng.randi_range(0, 3))
			RETAIL:
				var stall := _place(tile, STALLS, pick, Vector3(side * 23.0, FLOOR_Y, -18.0), to_promenade)
				if stall != null:
					_place(tile, ["chef"], 0, Vector3(side * 25.6, FLOOR_Y, -18.0), to_promenade, index)
				_place(tile, RETAIL_SMALL, pick, Vector3(side * 14.2, FLOOR_Y, -19.5), to_promenade)
				_place(tile, POSTERS, pick, Vector3(side * 16.4, FLOOR_Y, -12.5), 0.0)
				_place(tile, ["floor_wayfinding"], 0, Vector3(side * 12.6, FLOOR_Y + 0.005, -1.5), 0.0, index)
			LOUNGE:
				if index % 4 == 3:
					# Architecture along the promenade (long axis along z).
					_place(tile, ARCHITECTURE, index / 4 + (0 if side_i < 0 else 1), Vector3(side * 14.0, FLOOR_Y, -12.0), 0.0)
				else:
					_place(tile, LOUNGE_FEATURE, pick, Vector3(side * 13.9, FLOOR_Y, -10.0), to_promenade)
				_place(tile, LOUNGE_BACK, pick, Vector3(side * 14.2, FLOOR_Y, -19.5), to_promenade)
				# A soft seating set at the window end of the lounge.
				_place(tile, ["sofa"], 0, Vector3(side * 27.6, FLOOR_Y, -18.6), to_promenade, pick)
				_place(tile, ["coffee_table"], 0, Vector3(side * 26.0, FLOOR_Y, -18.6), 0.0, pick)
				_place(tile, ["armchair"], 0, Vector3(side * 26.0, FLOOR_Y, -16.9), 180.0, pick)
				_place(tile, ["floor_lamp"], 0, Vector3(side * 28.4, FLOOR_Y, -16.6), 0.0, pick)
		# Moving walkway module over the travelator strip, one per tile.
		if index % 3 == 1:
			_place(tile, ["travelator"], 0, Vector3(side * 8.2, FLOOR_Y, -12.0), 0.0, index)
		if (index + (0 if side_i < 0 else 1)) % 2 == 0:
			_place(tile, OVERHEAD, index / 2 + (0 if side_i < 0 else 2), Vector3(side * 12.6, FLOOR_Y, -9.5), 0.0)
		if index % 4 == (0 if side_i < 0 else 2):
			_place(tile, FEATURE_WALLS, index / 4 + (0 if side_i < 0 else 3), Vector3(side * 13.0, FLOOR_Y + 6.6, -11.0), 0.0)
		_add_walkers(tile, side, index, rng)


func _add_walkers(tile: Node3D, side: float, index: int, rng: RandomNumberGenerator) -> void:
	for k in 2:
		var direction := 1.0 if (k + index) % 2 == 0 else -1.0
		var x := side * rng.randf_range(10.6, 16.0)
		var z0 := rng.randf_range(-TILE_LENGTH, 0.0)
		# Front faces +Z; walking toward -Z needs a half turn.
		var node := _place(tile, WALKERS, index * 3 + k + (0 if side < 0.0 else 7), Vector3(x, FLOOR_Y, z0), 0.0 if direction > 0.0 else 180.0, rng.randi_range(0, 3))
		if node != null:
			_walkers.append({"node": node, "z0": z0, "speed": direction * rng.randf_range(0.6, 1.3)})
