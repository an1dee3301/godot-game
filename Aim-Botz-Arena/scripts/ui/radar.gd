class_name Radar
extends Control
## Mini-map radar (top-left): rotates with the player so "up" is forward.
## Shows level obstacles, bots (red), pickups (green/yellow) and the player.

const WORLD_RADIUS := 34.0

var player: Player
var obstacle_rects: Array[Rect2] = []
var arena_half := 40.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _to_screen(world: Vector3) -> Vector2:
	var center := size * 0.5
	var scale_factor := (size.x * 0.5) / WORLD_RADIUS
	var relative := Vector2(world.x - player.global_position.x, world.z - player.global_position.z)
	return center + relative.rotated(player.rotation.y) * scale_factor


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.07, 0.72))
	if player == null:
		return
	# Arena boundary and obstacles.
	var corners := [Vector3(-arena_half, 0, -arena_half), Vector3(arena_half, 0, -arena_half), Vector3(arena_half, 0, arena_half), Vector3(-arena_half, 0, arena_half)]
	var outline := PackedVector2Array()
	for corner in corners:
		outline.append(_to_screen(corner))
	outline.append(outline[0])
	draw_polyline(outline, Color(0.95, 0.6, 0.2, 0.9), 2.0)
	for rect in obstacle_rects:
		var points := PackedVector2Array([
			_to_screen(Vector3(rect.position.x, 0, rect.position.y)),
			_to_screen(Vector3(rect.end.x, 0, rect.position.y)),
			_to_screen(Vector3(rect.end.x, 0, rect.end.y)),
			_to_screen(Vector3(rect.position.x, 0, rect.end.y)),
		])
		draw_colored_polygon(points, Color(0.55, 0.58, 0.62, 0.55))
	for pickup in get_tree().get_nodes_in_group("pickups"):
		var item := pickup as Pickup
		if item and item.available:
			var dot_color := Color(0.3, 1.0, 0.4) if item.kind == Pickup.Kind.HEALTH else Color(1.0, 0.85, 0.25)
			draw_rect(Rect2(_to_screen(item.global_position) - Vector2(3, 3), Vector2(6, 6)), dot_color)
	for node in get_tree().get_nodes_in_group("bots"):
		var bot := node as Bot
		if bot and bot.is_alive():
			draw_circle(_to_screen(bot.global_position), 4.5 if bot.bot_type == Bot.Type.HEAVY else 3.5, Color(1.0, 0.2, 0.18))
	# Player arrow plus view cone.
	var center := size * 0.5
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -8), center + Vector2(6, 6), center + Vector2(-6, 6)]), Color.WHITE)
	draw_line(center, center + Vector2(-30, -60), Color(1, 1, 1, 0.2), 1.0)
	draw_line(center, center + Vector2(30, -60), Color(1, 1, 1, 0.2), 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.35), false, 2.0)
