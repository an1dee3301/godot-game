extends Node2D

var particles: Array = []
var effect_color := Color.WHITE
var duration := 0.7
var age := 0.0
var ring_radius := 0.0
var ring_speed := 90.0


func setup(spawn_position: Vector2, color: Color, particle_count: int, power: float) -> void:
	position = spawn_position
	effect_color = color
	duration = 0.55 + clampf(power / 260.0, 0.0, 0.35)
	ring_speed = power * 0.55
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = int(Time.get_ticks_usec()) ^ particle_count * 7919

	for i in range(particle_count):
		var angle := local_rng.randf_range(0.0, TAU)
		var speed := local_rng.randf_range(power * 0.35, power)
		var life := local_rng.randf_range(duration * 0.55, duration)
		particles.append({
			"position": Vector2.ZERO,
			"velocity": Vector2.RIGHT.rotated(angle) * speed,
			"life": life,
			"maximum_life": life,
			"width": local_rng.randf_range(1.0, 2.8)
		})
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	ring_radius += ring_speed * delta
	var any_alive := false
	for particle in particles:
		particle["life"] = float(particle["life"]) - delta
		if float(particle["life"]) > 0.0:
			any_alive = true
			particle["position"] = Vector2(particle["position"]) + Vector2(particle["velocity"]) * delta
			particle["velocity"] = Vector2(particle["velocity"]) * pow(0.08, delta)

	if not any_alive and age > duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var ring_alpha := clampf(1.0 - age / (duration * 0.65), 0.0, 1.0) * 0.32
	if ring_alpha > 0.0:
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, Color(effect_color.r, effect_color.g, effect_color.b, ring_alpha), 2.0, true)

	for particle in particles:
		var life: float = particle["life"]
		if life <= 0.0:
			continue
		var fade := life / float(particle["maximum_life"])
		var particle_position: Vector2 = particle["position"]
		var particle_velocity: Vector2 = particle["velocity"]
		var tail := -particle_velocity.normalized() * (5.0 + particle_velocity.length() * 0.025)
		var color := Color(effect_color.r, effect_color.g, effect_color.b, fade)
		draw_line(particle_position, particle_position + tail, Color(color.r, color.g, color.b, fade * 0.18), float(particle["width"]) + 5.0, true)
		draw_line(particle_position, particle_position + tail, color, float(particle["width"]), true)
