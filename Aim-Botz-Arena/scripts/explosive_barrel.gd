class_name ExplosiveBarrel
extends StaticBody3D
## Red barrel that explodes when shot, damaging everything nearby
## (bots, the player and other barrels).

const MAX_HEALTH := 25.0
const RADIUS := 6.5
const DAMAGE := 160.0

var health := MAX_HEALTH
var exploded := false
var sound_fx: SoundFX
var effects_root: Node3D
var last_attacker: Node


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("damageable")
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.75, 0.1, 0.08)
	body_material.roughness = 0.5
	body_material.metallic = 0.3
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.42
	cylinder.bottom_radius = 0.42
	cylinder.height = 1.2
	var body := MeshInstance3D.new()
	body.mesh = cylinder
	body.material_override = body_material
	body.position.y = 0.6
	add_child(body)
	for ring_height in [0.25, 0.95]:
		var ring_mesh := CylinderMesh.new()
		ring_mesh.top_radius = 0.44
		ring_mesh.bottom_radius = 0.44
		ring_mesh.height = 0.07
		var ring := MeshInstance3D.new()
		ring.mesh = ring_mesh
		ring.material_override = Fx.unshaded(Color(0.95, 0.8, 0.1))
		ring.position.y = ring_height
		add_child(ring)
	var label := Label3D.new()
	label.text = "DANGER"
	label.font_size = 40
	label.pixel_size = 0.006
	label.modulate = Color(1.0, 0.92, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 1.5
	add_child(label)
	var shape := CylinderShape3D.new()
	shape.radius = 0.42
	shape.height = 1.2
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.6
	add_child(collision)


func take_damage(amount: float, _hit_position: Vector3, _headshot: bool, source: Node) -> bool:
	if exploded:
		return false
	if source is Player:
		last_attacker = source
	elif source is ExplosiveBarrel and (source as ExplosiveBarrel).last_attacker:
		last_attacker = (source as ExplosiveBarrel).last_attacker
	health -= amount
	if health <= 0.0:
		exploded = true
		# Short fuse so chain reactions ripple instead of happening in one frame.
		get_tree().create_timer(0.12, false).timeout.connect(_explode)
	return false


func get_damage_label() -> String:
	return "EXPLOSION"


func _explode() -> void:
	if not is_inside_tree():
		return
	var center := global_position + Vector3.UP * 0.6
	if sound_fx:
		sound_fx.play_at("explosion", center, 4.0)
	Fx.explosion(effects_root if effects_root else get_parent(), center, RADIUS)
	for node in get_tree().get_nodes_in_group("damageable"):
		if node == self or not (node is Node3D) or not node.has_method("take_damage"):
			continue
		var target := node as Node3D
		var distance := target.global_position.distance_to(center)
		if distance > RADIUS:
			continue
		var amount := DAMAGE * (1.0 - distance / RADIUS)
		if target is Player:
			amount *= 0.45
		target.take_damage(amount, target.global_position + Vector3.UP, false, self)
	queue_free()
