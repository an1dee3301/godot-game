class_name SlidingDoor
extends AnimatableBody3D
## A pocket door that slides into the wall. The player opens it with E,
## bots open it automatically when they walk up to it.

const SLIDE_TIME := 0.55

var is_open := false
var sound_fx: SoundFX

var _closed_position := Vector3.ZERO
var _open_offset := Vector3.ZERO
var _tween: Tween


func setup(size: Vector3, closed_position: Vector3, open_offset: Vector3, material: Material) -> void:
	name = "SlidingDoor"
	collision_layer = 1
	collision_mask = 0
	_closed_position = closed_position
	_open_offset = open_offset
	position = closed_position
	var mesh := BoxMesh.new()
	mesh.size = size
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	add_child(mesh_instance)
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(size.x + 0.12, 0.08, 0.35)
	var handle := MeshInstance3D.new()
	handle.mesh = handle_mesh
	handle.material_override = Fx.unshaded(Color(0.95, 0.75, 0.2))
	handle.position = Vector3(0.0, 0.0, -size.z * 0.5 + 0.35)
	add_child(handle)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	add_to_group("doors")


func get_interact_text() -> String:
	return "Press E to %s the door" % ("close" if is_open else "open")


func interact(_by: Node) -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	_slide_to(_closed_position + _open_offset)


func close() -> void:
	if not is_open:
		return
	is_open = false
	_slide_to(_closed_position)


func reset() -> void:
	if _tween:
		_tween.kill()
	is_open = false
	position = _closed_position


func _slide_to(target: Vector3) -> void:
	if _tween:
		_tween.kill()
	if sound_fx:
		sound_fx.play_at("door", global_position, -2.0)
	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(self, "position", target, SLIDE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
