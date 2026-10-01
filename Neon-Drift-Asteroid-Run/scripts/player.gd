extends Node2D

signal fired(origin: Vector2, direction: Vector2, inherited_velocity: Vector2)

const ROTATION_SPEED := 3.8
const ACCELERATION := 360.0
const MAX_SPEED := 420.0
const DRAG := 32.0
const FIRE_DELAY := 0.18

var velocity := Vector2.ZERO
var controls_enabled := true
var invincible_time := 0.0
var fire_timer := 0.0
var thrusting := false
var flame_phase := 0.0


func _ready() -> void:
	z_index = 20
	queue_redraw()


func setup(spawn_position: Vector2, protection_time: float = 1.75) -> void:
	position = spawn_position
	rotation = 0.0
	velocity = Vector2.ZERO
	invincible_time = protection_time
	fire_timer = 0.25
	queue_redraw()


func _process(delta: float) -> void:
	if invincible_time > 0.0:
		invincible_time = maxf(invincible_time - delta, 0.0)

	fire_timer = maxf(fire_timer - delta, 0.0)
	flame_phase += delta * 24.0

	if controls_enabled:
		var turn := Input.get_axis("rotate_left", "rotate_right")
		rotation += turn * ROTATION_SPEED * delta
		thrusting = Input.is_action_pressed("thrust")

		if thrusting:
			velocity += forward() * ACCELERATION * delta
		else:
			velocity = velocity.move_toward(Vector2.ZERO, DRAG * delta)

		velocity = velocity.limit_length(MAX_SPEED)

		if Input.is_action_pressed("fire") and fire_timer <= 0.0:
			fire_timer = FIRE_DELAY
			fired.emit(muzzle_position(), forward(), velocity)
	else:
		thrusting = false
		velocity = velocity.move_toward(Vector2.ZERO, DRAG * 0.35 * delta)

	position += velocity * delta
	_wrap_to_screen()
	queue_redraw()


func forward() -> Vector2:
	return Vector2.UP.rotated(rotation)


func muzzle_position() -> Vector2:
	return position + forward() * 23.0


func is_protected() -> bool:
	return invincible_time > 0.0


func _wrap_to_screen() -> void:
	var size := get_viewport_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	position.x = fposmod(position.x, size.x)
	position.y = fposmod(position.y, size.y)


func _draw() -> void:
	var flicker_alpha := 1.0
	if invincible_time > 0.0:
		flicker_alpha = 0.34 + 0.66 * absf(sin(invincible_time * 15.0))

	var glow := Color(0.25, 0.95, 1.0, 0.14 * flicker_alpha)
	var cyan := Color(0.42, 0.97, 1.0, flicker_alpha)
	var white := Color(0.92, 1.0, 1.0, flicker_alpha)
	var hull := PackedVector2Array([
		Vector2(0, -20),
		Vector2(13, 15),
		Vector2(0, 9),
		Vector2(-13, 15),
		Vector2(0, -20)
	])

	draw_polyline(hull, glow, 9.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -17), Vector2(10, 12), Vector2(0, 7), Vector2(-10, 12)
	]), Color(0.025, 0.075, 0.13, 0.82 * flicker_alpha))
	draw_polyline(hull, cyan, 2.3, true)
	draw_line(Vector2(0, -13), Vector2(0, 6), white, 1.3, true)

	if thrusting:
		var flame_length := 12.0 + 5.0 * (0.5 + 0.5 * sin(flame_phase))
		var flame := PackedVector2Array([
			Vector2(-5, 13), Vector2(0, 13 + flame_length), Vector2(5, 13)
		])
		draw_polyline(flame, Color(1.0, 0.33, 0.27, 0.18 * flicker_alpha), 8.0, true)
		draw_polyline(flame, Color(1.0, 0.72, 0.3, flicker_alpha), 2.3, true)

	if invincible_time > 0.0:
		var shield_alpha := 0.18 + 0.14 * sin(invincible_time * 7.0)
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 48, Color(0.35, 0.9, 1.0, shield_alpha), 2.0, true)
