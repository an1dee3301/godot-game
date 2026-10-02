class_name CardProjectile
extends Node3D
## A spinning calling card with raycast collision and a five-second distraction impact.

var _direction := Vector3.FORWARD
var _origin := Vector3.ZERO
var _shooter: Node3D
var _travel := 0.0
var _stuck := false
var _stuck_time := 0.0
var _mesh: MeshInstance3D
var _trail: MeshInstance3D


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var card := BoxMesh.new()
	card.size = Vector3(0.23, 0.33, 0.009)
	_mesh.mesh = card
	var material := StandardMaterial3D.new()
	material.albedo_texture = _make_card_face()
	material.roughness = 0.38
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh.material_override = material
	add_child(_mesh)
	_trail = MeshInstance3D.new()
	var trail_mesh := SphereMesh.new()
	trail_mesh.radius = 0.055
	trail_mesh.height = 0.11
	_trail.mesh = trail_mesh
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = Color(0.85, 0.94, 1.0, 0.38)
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_mat.emission_enabled = true
	trail_mat.emission = Color(0.75, 0.85, 1.0)
	_trail.material_override = trail_mat
	add_child(_trail)


func _make_card_face() -> ImageTexture:
	var image := Image.create(64, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.98, 0.98, 0.97))
	var blue := Color(0.1, 0.2, 0.5)
	for y in range(96):
		for x in range(64):
			if x < 3 or x > 60 or y < 3 or y > 92:
				image.set_pixel(x, y, blue)
			var cx := float(x - 32)
			var cy := float(y - 48)
			var clover := (Vector2(cx + 8.0, cy + 5.0).length() < 9.0 or Vector2(cx - 8.0, cy + 5.0).length() < 9.0 or Vector2(cx, cy - 7.0).length() < 9.0)
			if clover or (absf(cx) < 3.0 and cy > 5.0 and cy < 22.0):
				image.set_pixel(x, y, blue)
	return ImageTexture.create_from_image(image)


## Launches the card from the shooter's hand along the aimed direction.
func launch(origin: Vector3, direction: Vector3, shooter: Node3D) -> void:
	global_position = origin
	_origin = origin
	_direction = direction.normalized()
	_shooter = shooter
	look_at(origin + _direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	if _stuck:
		_stuck_time += delta
		if _stuck_time >= 5.0:
			queue_free()
		elif _stuck_time > 4.0:
			_mesh.transparency = (_stuck_time - 4.0)
		return
	var move := _direction * KK.CARD_SPEED * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position + move, KK.LAYER_WORLD | KK.LAYER_ENEMY | KK.LAYER_GLASS)
	if is_instance_valid(_shooter) and _shooter is CollisionObject3D:
		query.exclude = [(_shooter as CollisionObject3D).get_rid()]
	query.collide_with_areas = true
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		_impact(result)
		return
	global_position += move
	_travel += move.length()
	_mesh.rotate_z(delta * 24.0)
	_trail.position = -_direction * 0.14
	if _travel >= KK.CARD_RANGE:
		queue_free()


func _impact(result: Dictionary) -> void:
	global_position = result["position"]
	var collider: Object = result["collider"]
	var target: Object = collider.get_meta("card_target") if collider.has_meta("card_target") else collider
	if target != null and target.has_method("take_card_hit"):
		target.call("take_card_hit", _origin)
		queue_free()
		return
	_stuck = true
	_trail.visible = false
	var normal: Vector3 = result["normal"]
	global_position += normal * 0.018
	# Floors/ceilings have a vertical normal, so pick an up vector that isn't parallel to it.
	var up := Vector3.FORWARD if absf(normal.dot(Vector3.UP)) > 0.95 else Vector3.UP
	look_at(global_position - normal, up)
	KK.emit_noise(get_tree(), global_position, KK.NOISE_CARD_IMPACT)
