class_name HeistTitleCamera
extends Camera3D
## Balcony establishing shot: the thief occupies the right third against the storm.

var focus: Node3D
var _time := 0.0
var _base := Vector3(-4.5, 1.8, -32.3)
var _look := Vector3(7.5, 2.5, -52.0)


func _ready() -> void:
	fov = 52.0
	near = 0.08
	far = 400.0
	global_position = _base
	look_at(_look, Vector3.UP)
	current = true


func _process(delta: float) -> void:
	_time += delta
	global_position = _base + Vector3(sin(_time * 0.12) * 0.32, sin(_time * 0.17) * 0.07, -sin(_time * 0.09) * 0.24)
	look_at(_look + Vector3(sin(_time * 0.08) * 0.22, 0.0, 0.0), Vector3.UP)
