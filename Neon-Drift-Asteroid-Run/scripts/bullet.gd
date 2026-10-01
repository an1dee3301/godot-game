extends Node2D

signal expired(bullet: Node)

const SPEED := 650.0
const LIFETIME := 1.15

var velocity := Vector2.ZERO
var remaining := LIFETIME
var radius := 4.0


func setup(spawn_position: Vector2, direction: Vector2, inherited_velocity: Vector2) -> void:
	position = spawn_position
	velocity = direction.normalized() * SPEED + inherited_velocity * 0.22
	remaining = LIFETIME
	rotation = velocity.angle()
	queue_redraw()


func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		expired.emit(self)
		queue_free()
		return

	position += velocity * delta
	rotation = velocity.angle()
	_wrap_to_screen()
	queue_redraw()


func _wrap_to_screen() -> void:
	var size := get_viewport_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	position.x = fposmod(position.x, size.x)
	position.y = fposmod(position.y, size.y)


func _draw() -> void:
	var fade := clampf(remaining / 0.18, 0.0, 1.0)
	draw_line(Vector2(-14, 0), Vector2(5, 0), Color(0.25, 0.95, 1.0, 0.15 * fade), 8.0, true)
	draw_line(Vector2(-10, 0), Vector2(4, 0), Color(0.45, 0.97, 1.0, 0.78 * fade), 3.0, true)
	draw_circle(Vector2(4, 0), 2.5, Color(1.0, 1.0, 0.86, fade))
