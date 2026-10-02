class_name HeistTitleCamera
extends Camera3D
## A slow balcony dolly framing the thief against the skyline.

var focus: Node3D
var _time := 0.0
var _base := Vector3.ZERO


func _ready() -> void:
	fov = 55.0
	_base = global_position
	current = true


func _process(delta: float) -> void:
	if not is_instance_valid(focus):
		return
	_time += delta
	global_position = _base + Vector3(sin(_time * 0.11) * 0.75, sin(_time * 0.19) * 0.12, cos(_time * 0.11) * 0.32)
	look_at(focus.global_position + Vector3(-3.8, 1.6, -5.3), Vector3.UP)
