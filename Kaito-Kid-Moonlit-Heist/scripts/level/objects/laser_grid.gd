class_name LaserGrid
extends Node3D
## Moving alarm beams across a doorway, with individual player trigger volumes.

signal tripped(position: Vector3)

var active := true
var _size := Vector2(3.0, 2.6)
var _beams: Array[Node3D] = []
var _post_lights: Array[OmniLight3D] = []
var _sockets: Array[MeshInstance3D] = []
var _time := 0.0
var _cooldown := 0.0


## Set local X span and Y height of the grid.
func setup(size: Vector2) -> void:
	_size = Vector2(maxf(size.x, 0.5), maxf(size.y, 0.7))
	for child in get_children():
		child.queue_free()
	_beams.clear()
	_post_lights.clear()
	_sockets.clear()
	_build()


## Power the grid on or off. Powered off beams cease to detect immediately.
func set_active(on: bool) -> void:
	if active == on:
		return
	active = on
	for beam in _beams:
		var area := beam.get_node("Hit") as Area3D
		area.monitoring = on
		if on:
			beam.visible = true
		else:
			var tw := create_tween()
			tw.tween_property(beam, "scale:y", 0.02, 0.23)
			tw.tween_callback(func() -> void: beam.visible = false)
	for lamp in _post_lights:
		lamp.light_energy = 0.7 if on else 0.0
	var socket_mat := KK.standard_material(Color(0.9, 0.05, 0.08), 0.2) if on else KK.standard_material(Color(0.12, 0.07, 0.09), 0.6, 0.3)
	if on:
		socket_mat.emission_enabled = true
		socket_mat.emission = Color(1.0, 0.02, 0.04)
		socket_mat.emission_energy_multiplier = 1.6
	for socket in _sockets:
		socket.material_override = socket_mat


func _process(delta: float) -> void:
	_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not active:
		return
	for i in _beams.size():
		var beam := _beams[i]
		beam.position.y = clampf(0.25 + float(i) * (_size.y - 0.5) / float(_beams.size() - 1) + sin(_time * 1.4 + i * 1.25) * 0.18, 0.12, _size.y - 0.12)
		beam.visible = sin(_time * 6.0 + i * 0.8) > -0.96


func _on_beam_body_entered(body: Node3D) -> void:
	if not active or _cooldown > 0.0 or not body.is_in_group(KK.GROUP_PLAYER):
		return
	_trip(body)


func _on_beam_body_staying() -> void:
	if not active or _cooldown > 0.0:
		return
	for beam in _beams:
		var area := beam.get_node("Hit") as Area3D
		for body in area.get_overlapping_bodies():
			if body.is_in_group(KK.GROUP_PLAYER):
				_trip(body)
				return


func _trip(body: Node3D) -> void:
	_cooldown = 2.0
	if body.has_method("take_damage"):
		body.take_damage(15.0, self)
	KK.emit_noise(get_tree(), global_position, KK.NOISE_LASER_ALARM)
	KK.alert_guards(get_tree(), global_position, 25.0, body.global_position)
	tripped.emit(body.global_position)


func _build() -> void:
	var metal := KK.standard_material(Color(0.16, 0.19, 0.23), 0.33, 0.75)
	var red := KK.standard_material(Color(0.95, 0.05, 0.08), 0.15)
	red.emission_enabled = true
	red.emission = Color(1.0, 0.02, 0.04)
	red.emission_energy_multiplier = 1.8
	for side in [-1, 1]:
		_box(self, Vector3(0.13, _size.y, 0.18), Vector3(side * _size.x * 0.5, _size.y * 0.5, 0), metal)
		for i in 6:
			_box(self, Vector3(0.19, 0.14, 0.23), Vector3(side * _size.x * 0.5, 0.25 + i * (_size.y - 0.5) / 5.0, 0), metal)
			for face in [-1, 1]:
				var socket := _box(self, Vector3(0.10, 0.055, 0.014), Vector3(side * _size.x * 0.5, 0.25 + i * (_size.y - 0.5) / 5.0, face * 0.123), red)
				socket.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_sockets.append(socket)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(side * _size.x * 0.5, _size.y * 0.5, 0)
		lamp.omni_range = 2.6
		lamp.light_color = Color(1.0, 0.08, 0.12)
		lamp.light_energy = 0.7 if active else 0.0
		lamp.shadow_enabled = false
		add_child(lamp)
		_post_lights.append(lamp)
	for i in 6:
		var beam := Node3D.new()
		beam.name = "Beam%d" % i
		add_child(beam)
		var core := _box(beam, Vector3(_size.x - 0.13, 0.012, 0.012), Vector3.ZERO, red)
		core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var halo_mat := StandardMaterial3D.new()
		halo_mat.albedo_color = Color(1.0, 0.08, 0.12, 0.07)
		halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		halo_mat.emission_enabled = true
		halo_mat.emission = Color(1.0, 0.03, 0.06)
		_box(beam, Vector3(_size.x - 0.13, 0.065, 0.065), Vector3.ZERO, halo_mat).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var area := Area3D.new()
		area.name = "Hit"
		area.collision_layer = 0
		area.collision_mask = KK.LAYER_PLAYER
		beam.add_child(area)
		var hit := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(_size.x - 0.13, 0.09, 0.18)
		hit.shape = shape
		area.add_child(hit)
		area.body_entered.connect(_on_beam_body_entered)
		_beams.append(beam)
	if not active:
		for beam in _beams:
			beam.visible = false
			(beam.get_node("Hit") as Area3D).monitoring = false
	var timer := Timer.new()
	timer.wait_time = 0.2
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_beam_body_staying)


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node
