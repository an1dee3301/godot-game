class_name SegmentLibrary
extends RefCounted
## Procedural builders for every segment type. OWNER: agent B.

const TYPES: PackedStringArray = [
	"straight", "scanner", "luggage_pile", "split_conveyor", "moving_suitcase",
	"carousel", "maintenance_tunnel", "loading_bay",
]

static func pick_type(rng: RandomNumberGenerator, difficulty: Difficulty, history: Array) -> String:
	var choices: Array[String] = []
	var weights: Array[float] = []
	var recent_split := false
	for i in range(maxi(0, history.size() - 4), history.size()):
		if history[i] == "split_conveyor":
			recent_split = true
	for type in TYPES:
		if history.size() > 0 and history.back() == type:
			continue
		if type == "split_conveyor" and recent_split:
			continue
		var times := 0
		for i in range(maxi(0, history.size() - 20), history.size()):
			if history[i] == type:
				times += 1
		var weight := 1.0 / (1.0 + float(times) * 1.3)
		if type == "moving_suitcase" or type == "maintenance_tunnel":
			weight *= 0.65 + difficulty.t() * 0.8
		if type == "split_conveyor":
			weight *= 0.8
		choices.append(type)
		weights.append(weight)
	var total := 0.0
	for weight in weights:
		total += weight
	var draw := rng.randf() * total
	for i in range(choices.size()):
		draw -= weights[i]
		if draw <= 0.0:
			return choices[i]
	return choices.back() if not choices.is_empty() else "straight"

static func build(type: String, ctx: Dictionary) -> TrackSegment:
	var segment := TrackSegment.new()
	segment.segment_type = type
	var difficulty: Difficulty = ctx["difficulty"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var safe: bool = ctx.get("safe", false)
	segment.length = 48.0 if type in ["split_conveyor", "carousel", "maintenance_tunnel"] else 36.0
	var rows: Array[Dictionary] = []
	if not safe:
		if type == "split_conveyor":
			# The sign and divider begin together at 21 m; the last 12 m before that are clear.
			var divider := Hazard.make("divider")
			divider.scale.z = 27.0 / 20.0
			divider.position = Vector3(BP.lane_x(1), 0, -34.5)
			segment.add_child(divider)
			rows.append({"z": -34.5, "lanes": ["", "divider", ""], "pattern": "fork", "safe_lane": 0})
		elif type != "start":
			var spacing := maxf(difficulty.row_spacing(), maxf(7.0, difficulty.base_speed() * 0.35))
			var distance := 8.0
			var previous_lane := rng.randi_range(0, 2)
			while distance <= segment.length - 5.0:
				var density := difficulty.hazard_density()
				if type == "checkpoint":
					density *= 0.65
				if rng.randf() < density:
					var pattern := _pick_pattern(type, difficulty, rng)
					var row := _make_row(pattern, -distance, previous_lane, difficulty, rng)
					# Gap geometry extends forward from the row centre.
					if not pattern.begins_with("gap") or distance + float(row.get("gap_length", 0.0)) <= segment.length - 4.0:
						rows.append(row)
						previous_lane = int(row["safe_lane"])
						_place_row(segment, row, difficulty)
				distance += spacing
	segment.set_meta("rows", rows)
	segment.build_belts()
	_decorate(segment, type, ctx)
	_place_pickups(segment, type, rng, rows)
	if type == "checkpoint":
		var trigger := TrackTrigger.make_checkpoint()
		trigger.position.z = -27.0
		segment.add_child(trigger)
	if type == "split_conveyor":
		var destination: String = ctx.get("destination", "LAX")
		var other := destination
		while other == destination:
			other = BP.DESTINATIONS[rng.randi_range(0, BP.DESTINATIONS.size() - 1)]
		var left_code := destination if rng.randf() < 0.5 else other
		var right_code := other if left_code == destination else destination
		for lane in [0, 2]:
			var code := left_code if lane == 0 else right_code
			var route := TrackTrigger.make_route(code, lane)
			route.position = Vector3(BP.lane_x(lane), 0, -37.0)
			segment.add_child(route)
		_decor_gantry(segment, "\u2190 " + left_code + "     " + right_code + " \u2192", 21.0, Color.WHITE)
	return segment

static func _pick_pattern(type: String, difficulty: Difficulty, rng: RandomNumberGenerator) -> String:
	var names: Array[String] = []
	match type:
		"scanner":
			names = ["single_scanner", "single_scanner", "scanner_wall", "scanner_wall", "slide_mix", "mixed", "double_block"]
		"luggage_pile":
			names = ["single_block", "single_block", "double_block", "double_block", "zigzag", "jump_mix"]
		"maintenance_tunnel":
			names = ["gap_single", "gap_single", "gap_double", "gap_double", "single_block", "jump_wall"]
		"loading_bay":
			names = ["single_cart", "single_cart", "double_block", "jump_wall", "jump_mix", "zigzag"]
		"moving_suitcase", "carousel":
			names = ["mover", "mover", "mover_block", "single_block", "zigzag", "double_block"]
		"checkpoint":
			names = ["single_block", "single_scanner", "jump_wall", "scanner_wall"]
		_:
			names = ["single_block", "single_scanner", "single_gate", "double_block", "jump_wall", "scanner_wall", "mixed", "zigzag", "mover"]
	var weights: Array[float] = []
	var total := 0.0
	for name in names:
		var advanced := name in ["double_block", "gap_double", "jump_wall", "scanner_wall", "mixed", "zigzag", "mover_block", "jump_mix", "slide_mix"]
		var weight := (0.08 + difficulty.t() * 1.9) if advanced else (1.8 - difficulty.t() * 0.9)
		weights.append(weight)
		total += weight
	var draw := rng.randf() * total
	for i in range(names.size()):
		draw -= weights[i]
		if draw <= 0.0:
			return names[i]
	return names.back()

static func _choose_lane(previous: int, difficulty: Difficulty, rng: RandomNumberGenerator) -> int:
	if rng.randf() >= difficulty.lane_change_bias():
		return previous
	var choices: Array[int] = []
	for lane in range(3):
		if lane != previous:
			choices.append(lane)
	return choices[rng.randi_range(0, choices.size() - 1)]

static func _make_row(pattern: String, z: float, previous: int, difficulty: Difficulty, rng: RandomNumberGenerator) -> Dictionary:
	var lanes: Array[String] = ["", "", ""]
	var safe_lane := _choose_lane(previous, difficulty, rng)
	var block := "luggage_cart" if pattern == "single_cart" else "giant_suitcase"
	match pattern:
		"single_block", "single_cart":
			lanes[(safe_lane + 1) % 3] = block
		"single_gate":
			lanes[(safe_lane + 1) % 3] = "security_gate"
		"single_scanner":
			lanes[(safe_lane + 1) % 3] = "xray_scanner"
		"double_block", "zigzag":
			if pattern == "zigzag":
				safe_lane = 2 - previous if previous != 1 else (0 if rng.randf() < 0.5 else 2)
			for lane in range(3):
				if lane != safe_lane:
					lanes[lane] = "luggage_cart" if rng.randf() < 0.3 else "giant_suitcase"
		"jump_wall":
			lanes = ["security_gate", "security_gate", "security_gate"]
			safe_lane = previous
		"scanner_wall":
			lanes = ["xray_scanner", "xray_scanner", "xray_scanner"]
			safe_lane = previous
		"mixed":
			lanes = ["security_gate", "xray_scanner", "giant_suitcase"]
			if rng.randf() < 0.5:
				lanes.reverse()
			safe_lane = 0 if lanes[0] == "security_gate" else 2
		"jump_mix", "slide_mix":
			for lane in range(3):
				lanes[lane] = ("security_gate" if pattern == "jump_mix" else "xray_scanner") if lane == safe_lane else "giant_suitcase"
		"gap_single", "gap_double":
			lanes[(safe_lane + 1) % 3] = "broken_roller"
			if pattern == "gap_double":
				lanes[(safe_lane + 2) % 3] = "broken_roller"
		"mover", "mover_block":
			safe_lane = 0 if safe_lane == 0 else 2
			var mover_lane := 2 if safe_lane == 0 else 0
			lanes[mover_lane] = "moving_suitcase"
			lanes[1] = "moving_suitcase"
			if pattern == "mover_block":
				lanes[mover_lane] = "giant_suitcase"
	var row: Dictionary = {"z": z, "lanes": lanes, "pattern": pattern, "safe_lane": safe_lane}
	if pattern.begins_with("gap"):
		row["gap_length"] = minf(difficulty.gap_length(), difficulty.base_speed() * 0.55)
	return row

static func _place_row(segment: TrackSegment, row: Dictionary, difficulty: Difficulty) -> void:
	var lanes: Array = row["lanes"]
	var distance := -float(row["z"])
	var pattern: String = row["pattern"]
	if pattern in ["mover", "mover_block"]:
		var mover_lane := 2 if int(row["safe_lane"]) == 0 else 0
		_add_hazard(segment, "moving_suitcase", mover_lane, distance, difficulty)
		if pattern == "mover_block":
			_add_hazard(segment, "giant_suitcase", mover_lane, distance, difficulty)
		return
	for lane in range(3):
		var kind: String = lanes[lane]
		if kind == "broken_roller":
			_add_gap(segment, lane, distance, float(row["gap_length"]))
		elif kind != "":
			_add_hazard(segment, kind, lane, distance, difficulty)

static func _add_hazard(segment: TrackSegment, kind: String, lane: int, distance: float, difficulty: Difficulty) -> void:
	var hazard := Hazard.make(kind, difficulty.mover_speed_scale())
	hazard.position = Vector3(BP.lane_x(lane), 0, -distance)
	segment.add_child(hazard)

static func _add_gap(segment: TrackSegment, lane: int, distance: float, gap_length: float) -> void:
	segment.gaps.append({"lane": lane, "start": distance, "length": gap_length})

static func _place_pickups(segment: TrackSegment, type: String, rng: RandomNumberGenerator, rows: Array[Dictionary]) -> void:
	var first_lane := rng.randi_range(0, 2)
	if type == "split_conveyor":
		first_lane = 0 if rng.randf() < 0.5 else 2
	elif not rows.is_empty():
		first_lane = int(rows[0]["safe_lane"])
	var entrance_type := Pickup.Type.TAG
	if rng.randf() < 0.20:
		entrance_type = Pickup.Type.PRIORITY if rng.randf() < 0.5 else Pickup.Type.FRAGILE
	_add_pickup(segment, entrance_type, first_lane, -5.0, 0.85)
	for row in rows:
		if row["pattern"] == "fork":
			for lane in [0, 2]:
				_add_pickup(segment, Pickup.Type.TAG, lane, -27.0, 0.85)
			continue
		var lanes: Array = row["lanes"]
		var safe_lane: int = row["safe_lane"]
		var kind: String = lanes[safe_lane]
		var z: float = row["z"]
		var y := 0.85
		if kind == "security_gate":
			y = 1.75
		elif kind == "xray_scanner":
			y = 0.35
		_add_pickup(segment, Pickup.Type.TAG, safe_lane, z, y)
		# Passports reward the jump/slide line when a plain lane also exists.
		if rng.randf() < 0.23:
			for lane in range(3):
				if lane != safe_lane and lanes[lane] in ["security_gate", "xray_scanner"]:
					_add_pickup(segment, Pickup.Type.PASSPORT, lane, z, 1.75 if lanes[lane] == "security_gate" else 0.35)
					break
		if rng.randf() < 0.23 and row["pattern"].begins_with("gap"):
			for lane in range(3):
				if lanes[lane] == "broken_roller":
					_add_pickup(segment, Pickup.Type.PASSPORT, lane, z - float(row["gap_length"]) * 0.5, 1.75)
					break

static func _add_pickup(segment: TrackSegment, pickup_type: Pickup.Type, lane: int, z: float, y: float) -> void:
	var pickup := Pickup.make(pickup_type)
	pickup.position = Vector3(BP.lane_x(lane), y, z)
	segment.add_child(pickup)

## Overhead gantry spanning the belts: slim steel posts carrying a full-width backlit sign cabinet.
## Everything sits above y = 4.4 so hazards ahead stay visible.
static func _decor_gantry(segment: TrackSegment, caption: String, z: float, accent: Color) -> void:
	var steel := DesignKit.metal()
	for side in [-1.0, 1.0]:
		DesignKit.rbox(segment, Vector3(0.16, 7.0, 0.2), Vector3(side * 5.7, 2.35, -z), steel, 0.04)
		DesignKit.rbox(segment, Vector3(0.4, 0.12, 0.4), Vector3(side * 5.7, -1.19, -z), DesignKit.stone(), 0.04)
	DesignKit.rbox(segment, Vector3(11.6, 0.22, 0.26), Vector3(0.0, 6.95, -z), DesignKit.wood(), 0.08)
	if caption.begins_with("←") or caption.begins_with("DEPARTURES"):
		# Destination fork / departures: a cabinet framing big split-flap letters.
		DesignKit.rbox(segment, Vector3(11.0, 1.55, 0.32), Vector3(0.0, 5.55, -z), DesignKit.metal(DesignKit.CHARCOAL, 0.5, 0.4, "sign_body"), 0.06)
		DesignKit.rbox(segment, Vector3(10.8, 0.03, 0.02), Vector3(0.0, 6.24, -z + 0.17), DesignKit.brass(), 0.008, false)
		var caption_label := Label3D.new()
		caption_label.text = "DESTINATION   ·   行き先   ·   目的地   ·   ĐIỂM ĐẾN   ·   DESTINO"
		caption_label.font = Signage.font()
		caption_label.font_size = 48
		caption_label.pixel_size = 0.0035
		caption_label.modulate = Color(0.93, 0.8, 0.55)
		caption_label.position = Vector3(0.0, 6.05, -z + 0.17)
		caption_label.double_sided = false
		segment.add_child(caption_label)
		var board := SplitFlapBoard.new()
		board.position = Vector3(0.0, 5.42, -z + 0.17)
		segment.add_child(board)
		if caption.begins_with("←"):
			board.setup(18, 1, Vector2(0.48, 0.72))
			var codes := caption.replace("←", "").replace("→", "").strip_edges().split(" ", false)
			board.set_row(0, "%-3s            %3s" % [codes[0], codes[1]], accent)
			for end in [-1.0, 1.0]:
				var arrow := MeshInstance3D.new()
				var quad := QuadMesh.new()
				quad.size = Vector2(0.72, 0.72)
				arrow.mesh = quad
				arrow.material_override = Signage._icon_material("arrow_left" if end < 0.0 else "arrow_right", Color(0, 0, 0, 0))
				arrow.position = Vector3(end * 4.95, 5.42, -z + 0.17)
				arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				segment.add_child(arrow)
		else:
			board.setup(20, 1, Vector2(0.48, 0.72))
			board.set_text_immediate(0, "DEPARTURES ALL GATES", accent)
	else:
		Signage.hanging(segment, Vector3(0.0, 5.55, -z), _sign_key(caption),
			{"width": 6.4, "scale": 1.6, "accent": DesignKit.OCHRE}, 0.55)


static func _sign_key(caption: String) -> String:
	var text_upper := caption.to_upper()
	if text_upper.contains("WELCOME"):
		return "welcome"
	if text_upper.contains("LOST"):
		return "lost_found"
	if text_upper.contains("SELF CHECK"):
		return "self_check_in"
	if text_upper.contains("BAG DROP"):
		return "bag_drop"
	if text_upper.contains("BAGGAGE CLAIM"):
		return "baggage_claim"
	if text_upper.contains("CLAIM"):
		return "claim"
	if text_upper.contains("PASSPORT"):
		return "passports"
	if text_upper.contains("SECURITY"):
		return "security"
	if text_upper.contains("SERVICE") or text_upper.contains("STAFF"):
		return "staff_only"
	if text_upper.contains("APRON") or text_upper.contains("AIRSIDE"):
		return "apron"
	if text_upper.contains("TRAYS"):
		return "trays"
	if text_upper.contains("WAY OUT") or text_upper.contains("EXIT"):
		return "exit"
	if text_upper.contains("A1-A12") or text_upper.contains("B1-B12") or text_upper.contains("GATES"):
		return "gates"
	return "departures"


static func _decor_side_sign(segment: TrackSegment, caption: String, side: float, z: float, accent: Color) -> void:
	var x := side * 5.85
	DesignKit.rbox(segment, Vector3(0.065, 4.0, 0.065), Vector3(x, 1.0, -z), DesignKit.metal(), 0.02)
	DesignKit.rbox(segment, Vector3(0.24, 0.08, 0.24), Vector3(x, -1.04, -z), DesignKit.stone(), 0.025)
	var opts: Dictionary = {"width": 2.35, "compact": true, "double_sided": true,
		"accent": DesignKit.OCHRE if accent == Color.WHITE else accent}
	if caption.contains("←"):
		opts["arrow"] = "left"
	elif caption.contains("→"):
		opts["arrow"] = "right"
	if caption.begins_with("CLAIM "):
		opts["suffix"] = caption.trim_prefix("CLAIM ").strip_edges()
	elif caption.contains("-A12") or caption.contains("-B12"):
		opts["suffix"] = caption
	Signage.panel(segment, Vector3(x, 2.87, -z), _sign_key(caption), opts)

static func _decor_planter(segment: TrackSegment, side: float, z: float) -> void:
	var x := side * 5.7
	var bowl := DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.33, 0.0), Vector2(0.42, 0.08),
		Vector2(0.48, 0.42), Vector2(0.45, 0.48), Vector2(0.39, 0.44),
		Vector2(0.31, 0.18), Vector2(0.0, 0.16)]), 20)
	DesignKit.add(segment, bowl, DesignKit.stone(), Vector3(x, -1.1, -z))
	DesignKit.rbox(segment, Vector3(0.08, 1.1, 0.08), Vector3(x, -0.2, -z), DesignKit.wood(DesignKit.WALNUT, "planter_trunk"), 0.025)
	var foliage := DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -0.4), Vector2(0.27, -0.32), Vector2(0.39, -0.14),
		Vector2(0.4, 0.06), Vector2(0.3, 0.29), Vector2(0.0, 0.4)]), 12)
	for i in range(5):
		var angle := TAU * float(i) / 5.0
		var clump := DesignKit.add(segment, foliage,
			DesignKit.paint(DesignKit.SAGE.darkened(0.08 if i % 2 == 0 else 0.18)),
			Vector3(x + cos(angle) * 0.27, 0.28 + float(i % 2) * 0.14, -z + sin(angle) * 0.27))
		clump.scale = Vector3(0.95, 0.7, 0.95)
	var crown := DesignKit.add(segment, foliage, DesignKit.paint(DesignKit.SAGE), Vector3(x, 0.62, -z))
	crown.scale = Vector3(1.05, 0.8, 1.05)

static func _decor_bench(segment: TrackSegment, side: float, z: float) -> void:
	var x: float = side * 5.8
	var oak := DesignKit.wood()
	var steel := DesignKit.metal()
	for i in range(4):
		DesignKit.rbox(segment, Vector3(1.6, 0.09, 0.105),
			Vector3(x, -0.45, -z + 0.21 - float(i) * 0.14), oak, 0.035)
	for i in range(3):
		DesignKit.rbox(segment, Vector3(1.6, 0.105, 0.08),
			Vector3(x, -0.24 + float(i) * 0.16, -z - 0.3), oak, 0.03)
	for dx in [-0.62, 0.62]:
		DesignKit.rbox(segment, Vector3(0.065, 0.65, 0.065), Vector3(x + dx, -0.83, -z), steel, 0.02)
		DesignKit.rbox(segment, Vector3(0.065, 0.57, 0.065), Vector3(x + dx, -0.33, -z - 0.3), steel, 0.02)
		DesignKit.rbox(segment, Vector3(0.065, 0.065, 0.58), Vector3(x + dx, -0.5, -z), steel, 0.02)

static func _decor_kiosk(segment: TrackSegment, side: float, z: float, caption: String) -> void:
	var x: float = side * 5.8
	DesignKit.rbox(segment, Vector3(0.92, 2.05, 0.7), Vector3(x, -0.12, -z), DesignKit.wood(), 0.14)
	DesignKit.rbox(segment, Vector3(0.82, 1.08, 0.055), Vector3(x, 0.23, -z + 0.36), DesignKit.metal(), 0.055)
	DesignKit.rbox(segment, Vector3(0.69, 0.74, 0.015), Vector3(x, 0.31, -z + 0.396),
		DesignKit.washi(Color(0.82, 0.95, 0.95), 1.5, "kiosk_screen"), 0.025, false)
	DesignKit.rbox(segment, Vector3(0.68, 0.025, 0.03), Vector3(x, -0.29, -z + 0.41), DesignKit.brass(), 0.01)
	DesignKit.rbox(segment, Vector3(0.7, 0.12, 0.55), Vector3(x, -1.17, -z), DesignKit.stone(), 0.045)
	var title := TrackProps.label(segment, caption, Vector3(x, 0.53, -z + 0.413), DesignKit.CHARCOAL, 12)
	title.font = Signage.font()
	title.pixel_size = 0.003

static func _decorate(segment: TrackSegment, type: String, ctx: Dictionary) -> void:
	var oak := DesignKit.wood()
	var stone := DesignKit.stone()
	var steel := DesignKit.metal()
	var brass := DesignKit.brass()
	var linen := DesignKit.fabric()
	var clay := DesignKit.paint(DesignKit.CLAY)
	var glow := DesignKit.washi()
	var accent := DesignKit.OCHRE
	var title: String = {
		"start": "DEPARTURES  ·  ALL GATES",
		"straight": "GATES  ←   /   BAGGAGE CLAIM  →",
		"scanner": "SECURITY CHECKPOINT",
		"checkpoint": "PASSPORT CONTROL  ·  CUSTOMS",
		"split_conveyor": "GATES A  ←     →  GATES B",
		"carousel": "BAGGAGE CLAIM",
		"loading_bay": "AIRSIDE  ·  APRON VIEW",
		"maintenance_tunnel": "AIRSIDE SERVICE CORRIDOR",
		"luggage_pile": "LOST & FOUND  ·  OVERSIZE",
		"moving_suitcase": "SELF SERVICE BAG DROP"
	}.get(type, "DEPARTURES")
	_decor_gantry(segment, title, 9.0, accent)
	var flags: Array[String] = ["JP", "FR", "DE", "IT"]
	var index := int(ctx.get("index", 0))
	for side in [-1.0, 1.0]:
		TrackProps.flag(segment, flags[posmod(index + (0 if side < 0.0 else 1), flags.size())], Vector3(side * 5.7, 2.75, -15.0))
	match type:
		"start", "straight":
			_decor_side_sign(segment, "WAY OUT  →", 1.0, 24.0, Color.WHITE)
			_decor_side_sign(segment, "←  GATES", -1.0, 24.0, Color.WHITE)
			for side in [-1.0, 1.0]:
				_decor_planter(segment, side, 29.0)
				_decor_bench(segment, side, 21.0)
		"scanner":
			for side in [-1.0, 1.0]:
				var x: float = side * 5.5
				for z in [20.0, 28.0]:
					for dx in [-0.45, 0.45]:
						DesignKit.rbox(segment, Vector3(0.11, 2.2, 0.16), Vector3(x + dx, 0.45, -z), steel, 0.04)
					DesignKit.rbox(segment, Vector3(1.05, 0.12, 0.2), Vector3(x, 1.57, -z), oak, 0.045)
					DesignKit.rbox(segment, Vector3(1.0, 0.13, 0.72), Vector3(x, -0.48, -z + 1.0), stone, 0.05)
					DesignKit.rbox(segment, Vector3(0.56, 0.1, 0.43), Vector3(x, -0.34, -z + 1.0), linen, 0.035)
			_decor_side_sign(segment, "TRAYS", 1.0, 32.0, Color.WHITE)
		"checkpoint":
			for side in [-1.0, 1.0]:
				var x: float = side * 5.7
				DesignKit.rbox(segment, Vector3(1.65, 1.1, 1.25), Vector3(x, -0.65, -23.0), oak, 0.09)
				DesignKit.rbox(segment, Vector3(1.7, 0.12, 1.3), Vector3(x, -0.02, -23.0), stone, 0.045)
				DesignKit.rbox(segment, Vector3(1.5, 0.8, 0.12), Vector3(x, 0.45, -23.55), steel, 0.045)
				DesignKit.rbox(segment, Vector3(1.35, 0.035, 0.025), Vector3(x, 0.78, -23.48), brass, 0.01)
				_decor_side_sign(segment, "PASSPORTS", side, 27.0, Color.WHITE)
			_decor_gantry(segment, "WELCOME  /  BIENVENUE", 31.0, Color.WHITE)
		"split_conveyor":
			_decor_side_sign(segment, "A1-A12", -1.0, 31.0, Color.WHITE)
			_decor_side_sign(segment, "B1-B12", 1.0, 31.0, Color.WHITE)
		"carousel":
			for side in [-1.0, 1.0]:
				var x: float = side * 5.75
				DesignKit.add(segment, DesignKit.lathe(PackedVector2Array([
					Vector2(0.0, 0.0), Vector2(0.78, 0.0), Vector2(0.85, 0.07),
					Vector2(0.85, 0.19), Vector2(0.78, 0.23), Vector2(0.0, 0.23)]), 24),
					stone, Vector3(x, -0.76, -27.0))
				DesignKit.add(segment, DesignKit.lathe(PackedVector2Array([
					Vector2(0.0, 0.0), Vector2(0.55, 0.0), Vector2(0.6, 0.07),
					Vector2(0.6, 0.2), Vector2(0.0, 0.24)]), 24),
					steel, Vector3(x, -0.53, -27.0))
				DesignKit.rbox(segment, Vector3(0.5, 0.42, 0.38), Vector3(x + side * 0.38, -0.2, -27.0), clay, 0.065)
				_decor_side_sign(segment, "CLAIM 04" if side < 0.0 else "CLAIM 05", side, 22.0, Color.WHITE)
		"loading_bay":
			for side in [-1.0, 1.0]:
				var x: float = side * 5.8
				for z in [18.0, 30.0]:
					DesignKit.rbox(segment, Vector3(1.7, 0.055, 0.13), Vector3(x, -1.1, -z), brass, 0.02)
				DesignKit.rbox(segment, Vector3(1.2, 0.6, 0.8), Vector3(x, -0.74, -25.0), oak, 0.075)
				DesignKit.rbox(segment, Vector3(0.63, 0.5, 0.61), Vector3(x - side * 0.3, -0.17, -25.0), linen, 0.055)
				for dz in [-0.34, 0.34]:
					DesignKit.rbox(segment, Vector3(0.18, 0.18, 0.18), Vector3(x + side * 0.42, -1.0, -25.0 + dz), steel, 0.075)
			_decor_side_sign(segment, "APRON  →", 1.0, 29.0, Color.WHITE)
		"maintenance_tunnel":
			for side in [-1.0, 1.0]:
				for i in range(18):
					var slat_z := -2.8 - float(i) * 2.45
					DesignKit.rbox(segment, Vector3(0.12, 3.4, 1.25), Vector3(side * 6.5, 0.9, slat_z), oak, 0.045)
				for z in [17.0, 29.0, 41.0]:
					DesignKit.rbox(segment, Vector3(0.55, 0.12, 0.7), Vector3(side * 5.7, 2.62, -z), glow, 0.045, false)
					_decor_side_sign(segment, "SERVICE", side, z + 3.0, Color.WHITE)
		"luggage_pile":
			for side in [-1.0, 1.0]:
				var x: float = side * 5.8
				DesignKit.rbox(segment, Vector3(1.85, 0.9, 2.9), Vector3(x, -0.73, -23.0), oak, 0.075)
				DesignKit.rbox(segment, Vector3(1.9, 0.13, 3.0), Vector3(x, -0.22, -23.0), stone, 0.05)
				for z in [18.0, 28.0]:
					DesignKit.rbox(segment, Vector3(0.72, 0.65, 0.48), Vector3(x, -0.82, -z), clay, 0.075)
				_decor_side_sign(segment, "LOST + FOUND", side, 29.0, Color.WHITE)
		"moving_suitcase":
			for side in [-1.0, 1.0]:
				for z in [19.0, 25.0, 31.0]:
					_decor_kiosk(segment, side, z, "BAG DROP")
			_decor_side_sign(segment, "SELF CHECK IN", 1.0, 33.0, Color.WHITE)
