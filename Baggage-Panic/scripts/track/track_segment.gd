class_name TrackSegment
extends Node3D
## One reusable chunk of conveyor. Origin = start of segment; it extends to local z = -length. OWNER: agent B.

var segment_type := "straight"
var length := BP.SEGMENT_LENGTH
var gaps: Array[Dictionary] = []

func start_z() -> float:
	return global_position.z

func end_z() -> float:
	return global_position.z - length

func build_belts() -> void:
	var rubber := TrackProps.belt_material()
	var steel := TrackProps.material("steel", Color(0.24, 0.23, 0.22), 0.6)
	var stripe := TrackProps.material("warning_yellow", Color(1.0, 0.72, 0.045), 0.25)
	var dark := TrackProps.material("hazard_dark", Color(0.085, 0.105, 0.125), 0.25)
	var led := TrackProps.material("belt_led_cyan", Color(0.05, 0.72, 0.92), 0.15, Color(0.02, 0.48, 0.74))
	var lane_tints: Array[Color] = [Color(0.095, 0.16, 0.19), Color(0.12, 0.17, 0.21), Color(0.105, 0.17, 0.16)]
	for lane in range(BP.LANE_COUNT):
		var x := BP.lane_x(lane)
		var intervals: Array[Vector2] = [Vector2(0, length)]
		for gap in gaps:
			if int(gap["lane"]) != lane:
				continue
			var next_intervals: Array[Vector2] = []
			var gap_start := float(gap["start"])
			var gap_end := gap_start + float(gap["length"])
			for interval in intervals:
				if gap_start > interval.x:
					next_intervals.append(Vector2(interval.x, minf(gap_start, interval.y)))
				if gap_end < interval.y:
					next_intervals.append(Vector2(maxf(gap_end, interval.x), interval.y))
			intervals = next_intervals
		for interval in intervals:
			var span := interval.y - interval.x
			if span <= 0.05:
				continue
			var body := StaticBody3D.new()
			body.collision_layer = BP.LAYER_WORLD
			body.collision_mask = 0
			body.position = Vector3(x, -0.14, -(interval.x + interval.y) * 0.5)
			add_child(body)
			TrackProps.shape(body, Vector3(BP.LANE_WIDTH - 0.2, 0.28, span), Vector3.ZERO)
			var surface := TrackProps.box(body, Vector3(BP.LANE_WIDTH - 0.2, 0.28, span), Vector3.ZERO, rubber)
			surface.set_instance_shader_parameter("belt_tint", lane_tints[lane])
			for offset in [-0.98, 0.98]:
				TrackProps.box(body, Vector3(0.055, 0.018, span), Vector3(offset, 0.151, 0), stripe)
				TrackProps.box(body, Vector3(0.025, 0.023, span), Vector3(offset * 0.88, 0.162, 0), led)
		for edge in [-1.0, 1.0]:
			TrackProps.box(self, Vector3(0.17, 0.25, length), Vector3(x + edge * 1.25, 0.08, -length * 0.5), steel)
			TrackProps.box(self, Vector3(0.04, 0.04, length), Vector3(x + edge * 1.25, 0.23, -length * 0.5), led)
		for distance in range(3, int(length), 6):
			TrackProps.box(self, Vector3(1.4, 0.11, 0.22), Vector3(x, -0.34, -float(distance)), steel)
			for side in [-1.0, 1.0]:
				TrackProps.box(self, Vector3(0.13, 1.3, 0.16), Vector3(x + side * 1.0, -0.85, -float(distance)), dark)
		for z in [0.0, -length]:
			var roller := TrackProps.cylinder(self, 0.16, 2.17, Vector3(x, -0.08, z), steel)
			roller.rotation.z = PI * 0.5
			TrackProps.box(self, Vector3(2.25, 0.055, 0.1), Vector3(x, 0.12, z), stripe)
		TrackProps.box(self, Vector3(0.78, 0.38, 0.09), Vector3(x, -0.44, -1.0), dark)
		TrackProps.label(self, "0%d" % [lane + 1], Vector3(x, -0.42, -0.93), Color(0.3, 1.0, 0.96), 23)
	for gap in gaps:
		var x := BP.lane_x(int(gap["lane"]))
		var start := float(gap["start"])
		var end := start + float(gap["length"])
		for z in [-start, -end]:
			TrackProps.box(self, Vector3(2.35, 0.11, 0.16), Vector3(x, 0.08, z), stripe)
			for side in [-0.77, 0.0, 0.77]:
				TrackProps.box(self, Vector3(0.17, 0.12, 0.19), Vector3(x + side, 0.08, z), dark)
			var broken := TrackProps.cylinder(self, 0.12, 2.15, Vector3(x, -0.09, z), steel)
			broken.rotation.z = PI * 0.5
		var hole := Hazard.make("broken_roller")
		hole.position = Vector3(x, 0, -(start + end) * 0.5)
		add_child(hole)
