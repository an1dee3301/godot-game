class_name Fx
extends RefCounted
## Short-lived visual effects: tracers, impacts, muzzle flashes and explosions.

const MAX_DECALS := 80

static var _decals: Array[Node3D] = []


static func unshaded(color: Color, emission_energy := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material


static func tracer(parent: Node, from: Vector3, to: Vector3, color: Color, width := 0.022, life := 0.07) -> void:
	var length := from.distance_to(to)
	if parent == null or length < 0.05:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, width, length)
	var material := unshaded(Color(color, 0.85))
	var tracer_mesh := MeshInstance3D.new()
	tracer_mesh.mesh = mesh
	tracer_mesh.material_override = material
	tracer_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(tracer_mesh)
	var direction := (to - from) / length
	var up := Vector3.UP if absf(direction.y) < 0.98 else Vector3.RIGHT
	tracer_mesh.global_transform = Transform3D(Basis.looking_at(direction, up), (from + to) * 0.5)
	var tween := tracer_mesh.create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, life)
	tween.tween_callback(tracer_mesh.queue_free)


static func impact(parent: Node, position: Vector3, normal: Vector3, flesh: bool) -> void:
	if parent == null:
		return
	var color := Color(0.75, 0.05, 0.05) if flesh else Color(1.0, 0.82, 0.45)
	burst(parent, position, normal, color, 10 if flesh else 7, 0.35, 3.5)
	if flesh:
		return
	# Bullet hole decal: a small dark quad pushed slightly off the surface.
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var hole := MeshInstance3D.new()
	hole.mesh = quad
	hole.material_override = unshaded(Color(0.05, 0.05, 0.05, 0.85))
	hole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(hole)
	var safe_normal := normal if normal.length_squared() > 0.01 else Vector3.UP
	var up := Vector3.UP if absf(safe_normal.y) < 0.98 else Vector3.FORWARD
	hole.global_transform = Transform3D(Basis.looking_at(-safe_normal, up), position + safe_normal * 0.012)
	_decals.append(hole)
	while _decals.size() > MAX_DECALS:
		var oldest: Node3D = _decals.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var tween := hole.create_tween()
	tween.tween_interval(10.0)
	tween.tween_property(hole, "scale", Vector3.ZERO, 0.6)
	tween.tween_callback(hole.queue_free)


static func burst(parent: Node, position: Vector3, direction: Vector3, color: Color, amount: int, lifetime: float, speed: float) -> void:
	var particles := CPUParticles3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.035, 0.035, 0.035)
	mesh.material = unshaded(color, 1.5)
	particles.mesh = mesh
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = direction if direction.length_squared() > 0.01 else Vector3.UP
	particles.spread = 40.0
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.gravity = Vector3(0.0, -9.8, 0.0)
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.4
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	particles.get_tree().create_timer(lifetime + 0.6, false).timeout.connect(particles.queue_free)


static func flash(parent: Node, position: Vector3, size: float, color := Color(1.0, 0.75, 0.3)) -> void:
	if parent == null:
		return
	var sphere := SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var material := unshaded(color, 3.0)
	var flash_mesh := MeshInstance3D.new()
	flash_mesh.mesh = sphere
	flash_mesh.material_override = material
	flash_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(flash_mesh)
	flash_mesh.global_position = position
	var tween := flash_mesh.create_tween()
	tween.tween_interval(0.05)
	tween.tween_callback(flash_mesh.queue_free)


static func spawn_beam(parent: Node, position: Vector3) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.55
	cylinder.bottom_radius = 0.55
	cylinder.height = 4.0
	var material := unshaded(Color(0.3, 0.85, 1.0, 0.5), 2.0)
	var beam := MeshInstance3D.new()
	beam.mesh = cylinder
	beam.material_override = material
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(beam)
	beam.global_position = position + Vector3(0.0, 2.0, 0.0)
	var tween := beam.create_tween()
	tween.set_parallel(true)
	tween.tween_property(beam, "scale", Vector3(0.05, 1.4, 0.05), 0.55)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.55)
	tween.chain().tween_callback(beam.queue_free)


static func explosion(parent: Node, position: Vector3, radius: float) -> void:
	if parent == null:
		return
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	var material := unshaded(Color(1.0, 0.55, 0.15, 0.9), 4.0)
	var fireball := MeshInstance3D.new()
	fireball.mesh = sphere
	fireball.material_override = material
	fireball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(fireball)
	fireball.global_position = position
	fireball.scale = Vector3.ONE * 0.3
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.25)
	light.light_energy = 10.0
	light.omni_range = radius * 2.5
	parent.add_child(light)
	light.global_position = position + Vector3.UP
	var tween := fireball.create_tween()
	tween.set_parallel(true)
	tween.tween_property(fireball, "scale", Vector3.ONE * radius * 0.8, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.45)
	tween.tween_property(light, "light_energy", 0.0, 0.5)
	tween.chain().tween_callback(fireball.queue_free)
	tween.tween_callback(light.queue_free)
	burst(parent, position + Vector3.UP * 0.3, Vector3.UP, Color(0.25, 0.22, 0.2), 24, 1.1, 9.0)
	burst(parent, position + Vector3.UP * 0.5, Vector3.UP, Color(1.0, 0.7, 0.2), 18, 0.5, 7.0)
