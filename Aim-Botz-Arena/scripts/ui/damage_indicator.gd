class_name DamageIndicator
extends Control
## Red arcs around the crosshair pointing toward whoever hit the player.

const LIFETIME := 1.2

var player: Player
var _hits: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func add_hit(source_position: Vector3) -> void:
	_hits.append({"source": source_position, "time": LIFETIME})
	if _hits.size() > 6:
		_hits.pop_front()


func clear() -> void:
	_hits.clear()


func _process(delta: float) -> void:
	for hit in _hits:
		hit["time"] = float(hit["time"]) - delta
	_hits = _hits.filter(func(hit: Dictionary) -> bool: return float(hit["time"]) > 0.0)
	queue_redraw()


func _draw() -> void:
	if player == null:
		return
	var center := size * 0.5
	for hit in _hits:
		var source: Vector3 = hit["source"]
		var relative := Vector2(source.x - player.global_position.x, source.z - player.global_position.z).rotated(player.rotation.y)
		if relative.length() < 0.1:
			continue
		var angle := relative.angle()
		var alpha := clampf(float(hit["time"]) / LIFETIME, 0.0, 1.0)
		draw_arc(center, 130.0, angle - 0.32, angle + 0.32, 18, Color(1.0, 0.15, 0.1, 0.85 * alpha), 9.0)
