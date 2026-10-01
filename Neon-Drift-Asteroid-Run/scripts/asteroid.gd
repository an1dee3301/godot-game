extends Node2D

var size_level := 3
var radius := 46.0
var points := 20
var velocity := Vector2.ZERO
var angular_velocity := 0.0
var outline := PackedVector2Array()
var craters: Array = []
var accent := Color(1.0, 0.52, 0.34)


func setup(level: int, spawn_position: Vector2, initial_velocity: Vector2, shape_seed: int) -> void:
	size_level = clampi(level, 1, 3)
	position = spawn_position
	velocity = initial_velocity

	match size_level:
		3:
			radius = 46.0
			points = 20
			accent = Color(1.0, 0.55, 0.34)
		2:
			radius = 28.0
			points = 50
			accent = Color(1.0, 0.66, 0.38)
		_:
			radius = 16.0
			points = 100
			accent = Color(1.0, 0.77, 0.45)

	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = shape_seed
	angular_velocity = local_rng.randf_range(-1.1, 1.1)
	if absf(angular_velocity) < 0.22:
		angular_velocity = 0.22 if angular_velocity >= 0.0 else -0.22

	outline.clear()
	var vertex_count := local_rng.randi_range(9, 13)
	for i in range(vertex_count):
		var angle := TAU * float(i) / float(vertex_count)
		var length := radius * local_rng.randf_range(0.76, 1.14)
		outline.append(Vector2.RIGHT.rotated(angle) * length)
	outline.append(outline[0])

	craters.clear()
	var crater_count := local_rng.randi_range(2, 4) if size_level > 1 else 1
	for i in range(crater_count):
		var crater_angle := local_rng.randf_range(0.0, TAU)
		var crater_distance := local_rng.randf_range(radius * 0.15, radius * 0.48)
		craters.append({
			"position": Vector2.RIGHT.rotated(crater_angle) * crater_distance,
			"radius": local_rng.randf_range(radius * 0.1, radius * 0.24),
			"start": local_rng.randf_range(-0.5, 0.2)
		})

	queue_redraw()


func _process(delta: float) -> void:
	position += velocity * delta
	rotation += angular_velocity * delta
	_wrap_to_screen()


func _wrap_to_screen() -> void:
	var size := get_viewport_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	position.x = fposmod(position.x, size.x)
	position.y = fposmod(position.y, size.y)


func _draw() -> void:
	if outline.is_empty():
		return

	draw_polyline(outline, Color(accent.r, accent.g, accent.b, 0.12), 10.0, true)
	draw_colored_polygon(outline, Color(0.065, 0.075, 0.14, 0.96))
	draw_polyline(outline, accent, 2.4, true)
	draw_polyline(outline, Color(1.0, 0.86, 0.7, 0.34), 0.8, true)

	for crater_data in craters:
		var crater_position: Vector2 = crater_data["position"]
		var crater_radius: float = crater_data["radius"]
		var crater_start: float = crater_data["start"]
		draw_arc(crater_position, crater_radius, crater_start, crater_start + 4.7, 18, Color(accent.r, accent.g, accent.b, 0.46), 1.4, true)
