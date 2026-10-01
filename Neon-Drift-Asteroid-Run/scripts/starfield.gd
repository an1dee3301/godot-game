extends Node2D

const BASE_SIZE := Vector2(1152, 648)

var stars: Array = []
var drift := Vector2.ZERO
var ship_motion := Vector2.ZERO
var pulse := 0.0


func _ready() -> void:
	z_index = -100
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = 734821
	for i in range(175):
		var depth := local_rng.randf_range(0.18, 1.0)
		stars.append({
			"position": Vector2(local_rng.randf_range(0.0, BASE_SIZE.x), local_rng.randf_range(0.0, BASE_SIZE.y)),
			"depth": depth,
			"size": local_rng.randf_range(0.65, 1.8) * (0.6 + depth * 0.5),
			"phase": local_rng.randf_range(0.0, TAU),
			"cyan": local_rng.randf() > 0.72
		})
	queue_redraw()


func set_ship_motion(new_motion: Vector2) -> void:
	ship_motion = new_motion


func _process(delta: float) -> void:
	pulse += delta
	drift -= ship_motion * delta * 0.025
	drift += Vector2(-2.0, 0.65) * delta
	drift.x = fposmod(drift.x, BASE_SIZE.x)
	drift.y = fposmod(drift.y, BASE_SIZE.y)
	queue_redraw()


func _draw() -> void:
	var view_size := get_viewport_rect().size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return

	draw_rect(Rect2(Vector2.ZERO, view_size), Color(0.008, 0.014, 0.045))

	# A very faint navigation grid gives the empty space depth without adding assets.
	var grid_spacing := 96.0
	var grid_offset := Vector2(fposmod(drift.x * 0.05, grid_spacing), fposmod(drift.y * 0.05, grid_spacing))
	var grid_color := Color(0.16, 0.45, 0.58, 0.035)
	var x := grid_offset.x - grid_spacing
	while x < view_size.x + grid_spacing:
		draw_line(Vector2(x, 0), Vector2(x, view_size.y), grid_color, 1.0)
		x += grid_spacing
	var y := grid_offset.y - grid_spacing
	while y < view_size.y + grid_spacing:
		draw_line(Vector2(0, y), Vector2(view_size.x, y), grid_color, 1.0)
		y += grid_spacing

	# Distant orbital traces break up the rectangle and reinforce the radar-like look.
	var orbit_center := view_size * Vector2(0.78, 0.28)
	draw_arc(orbit_center, 175.0, -1.8, 1.15, 80, Color(0.2, 0.7, 0.82, 0.035), 1.0, true)
	draw_arc(orbit_center, 222.0, -1.2, 0.8, 80, Color(1.0, 0.45, 0.35, 0.025), 1.0, true)

	var speed_ratio := clampf(ship_motion.length() / 420.0, 0.0, 1.0)
	var scale_to_view := view_size / BASE_SIZE
	for star in stars:
		var depth: float = star["depth"]
		var base_position: Vector2 = star["position"] * scale_to_view
		var parallax := drift * depth * scale_to_view
		var star_position := Vector2(fposmod(base_position.x + parallax.x, view_size.x), fposmod(base_position.y + parallax.y, view_size.y))
		var twinkle := 0.62 + 0.38 * sin(pulse * (0.7 + depth) + float(star["phase"]))
		var alpha := (0.24 + depth * 0.6) * twinkle
		var color := Color(0.52, 0.93, 1.0, alpha) if star["cyan"] else Color(0.92, 0.95, 1.0, alpha)
		var star_size: float = star["size"]
		if speed_ratio > 0.25:
			var streak := -ship_motion.normalized() * speed_ratio * depth * 7.0
			draw_line(star_position, star_position + streak, Color(color.r, color.g, color.b, alpha * 0.55), maxf(0.7, star_size), true)
		else:
			draw_circle(star_position, star_size, color)
