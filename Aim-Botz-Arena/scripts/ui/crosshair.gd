class_name Crosshair
extends Control
## CS-style dynamic crosshair: the gap widens with weapon spread.
## Also draws the hit marker (white = hit, red = kill).

var spread_degrees := 0.0
var color := Color(0.35, 1.0, 0.35)

var _gap := 6.0
var _hit_time := 0.0
var _hit_color := Color.WHITE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_hit(headshot: bool, killed: bool) -> void:
	_hit_time = 0.25 if not killed else 0.4
	_hit_color = Color(1.0, 0.25, 0.2) if killed else (Color(1.0, 0.85, 0.2) if headshot else Color.WHITE)


func _process(delta: float) -> void:
	_gap = lerpf(_gap, 4.0 + spread_degrees * 7.0, minf(delta * 20.0, 1.0))
	_hit_time = maxf(_hit_time - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var length := 9.0
	var thickness := 2.0
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var start: Vector2 = center + direction * _gap
		var end: Vector2 = center + direction * (_gap + length)
		draw_line(start, end, Color(0, 0, 0, 0.8), thickness + 2.0)
		draw_line(start, end, color, thickness)
	draw_rect(Rect2(center - Vector2.ONE, Vector2(2.0, 2.0)), color)
	if _hit_time > 0.0:
		var alpha := clampf(_hit_time / 0.2, 0.0, 1.0)
		var tint := Color(_hit_color, alpha)
		for diagonal in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			var normal: Vector2 = diagonal.normalized()
			draw_line(center + normal * 7.0, center + normal * 15.0, tint, 2.5)
