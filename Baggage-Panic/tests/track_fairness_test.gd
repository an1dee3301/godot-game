extends SceneTree
## Seeded structural fairness checks for the procedural track.

var failures: Array[String] = []
var patterns: Dictionary = {}
var hazard_totals: Dictionary = {}
var segment_totals: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for distance_value in [0.0, 500.0, 1500.0, 3000.0]:
		var difficulty := Difficulty.new()
		difficulty.update(distance_value, distance_value / 20.0)
		var total_hazards := 0
		var total_segments := 0
		for type in SegmentLibrary.TYPES:
			for sample in range(200):
				var rng := RandomNumberGenerator.new()
				rng.seed = 1299709 + int(distance_value) * 31 + sample * 97 + SegmentLibrary.TYPES.find(type) * 100003
				var segment := SegmentLibrary.build(type, {"difficulty": difficulty, "rng": rng, "destination": "LAX", "index": sample, "safe": false})
				var rows: Array = segment.get_meta("rows", [])
				var previous: Dictionary = {}
				for row in rows:
					var lanes: Array = row["lanes"]
					var row_z: float = row["z"]
					var pattern: String = row["pattern"]
					patterns[pattern] = true
					_assert(lanes.size() == 3, "three lanes per row")
					var lane_blockers := 0
					var passable := 0
					for kind in lanes:
						if kind in ["giant_suitcase", "luggage_cart", "moving_suitcase", "divider"]:
							lane_blockers += 1
						else:
							passable += 1
						if kind != "":
							total_hazards += 1
					_assert(passable >= 1, "row passable: %s %s" % [type, pattern])
					_assert(lane_blockers < 3, "no triple lane block: %s %s" % [type, pattern])
					if not previous.is_empty():
						var separation: float = absf(row_z - float(previous["z"]))
						_assert(separation + 0.001 >= difficulty.row_spacing(), "row spacing")
						if int(row["safe_lane"]) != int(previous["safe_lane"]):
							_assert(separation + 0.001 >= maxf(7.0, difficulty.base_speed() * 0.35), "lane switch spacing")
					if pattern != "fork":
						_assert(row_z <= -6.0 and row_z >= -segment.length + 4.0, "hazard end clearance")
					previous = row
				for gap in segment.gaps:
					var gap_length: float = gap["length"]
					_assert(gap_length <= minf(difficulty.gap_length(), difficulty.base_speed() * 0.55) + 0.001, "gap jumpable")
					_assert(float(gap["start"]) >= 6.0 and float(gap["start"]) + gap_length <= segment.length - 4.0, "gap end clearance")
				if type == "split_conveyor":
					var divider_found := false
					for child in segment.get_children():
						if child is Hazard and (child as Hazard).kind == "divider":
							divider_found = true
							var divider_start: float = -child.position.z - 10.0 * child.scale.z
							var divider_end: float = -child.position.z + 10.0 * child.scale.z
							_assert(divider_start <= 21.0 + 0.001 and divider_end >= segment.length - 0.001, "fork divider coverage")
						if child is TrackTrigger and (child as TrackTrigger).kind == "route":
							_assert(-child.position.z >= 21.0 and int((child as TrackTrigger).data["lane"]) in [0, 2], "fork route after divider")
					_assert(divider_found, "fork divider exists")
				segment.free()
				total_segments += 1
		hazard_totals[distance_value] = total_hazards
		segment_totals[distance_value] = total_segments
		print("  distance %.0f: %.2f hazards per segment" % [distance_value, float(total_hazards) / float(total_segments)])
	_assert(patterns.size() >= 8, "at least eight patterns (%d)" % patterns.size())
	var early_average: float = float(hazard_totals[0.0]) / float(segment_totals[0.0])
	var late_average: float = float(hazard_totals[3000.0]) / float(segment_totals[3000.0])
	_assert(late_average > early_average, "hazards increase with difficulty")
	if failures.is_empty():
		print("TRACK FAIRNESS TEST PASSED (%d patterns)" % patterns.size())
		quit(0)
	else:
		print("TRACK FAIRNESS TEST FAILED: %d failures" % failures.size())
		for failure in failures.slice(0, mini(20, failures.size())):
			print("  FAIL ", failure)
		quit(1)


func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
