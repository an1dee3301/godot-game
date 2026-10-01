class_name Pickup
extends Area3D
## Health or ammo pickup. It is consumed only when it actually helps the
## player, then respawns after a delay.

signal collected(pickup: Pickup)

enum Kind { HEALTH, AMMO }

const HEAL_AMOUNT := 40.0
const RESPAWN_TIME := 25.0

var kind := Kind.HEALTH
var available := true
var sound_fx: SoundFX

var _visual: Node3D
var _respawn_timer := 0.0
var _check_timer := 0.0
var _spin := 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitorable = false
	add_to_group("pickups")
	var shape := SphereShape3D.new()
	shape.radius = 0.9
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.5
	add_child(collision)
	_visual = Node3D.new()
	_visual.position.y = 0.55
	add_child(_visual)
	if kind == Kind.HEALTH:
		_build_health_visual()
	else:
		_build_ammo_visual()
	var light := OmniLight3D.new()
	light.light_color = Color(0.3, 1.0, 0.45) if kind == Kind.HEALTH else Color(1.0, 0.85, 0.3)
	light.light_energy = 0.8
	light.omni_range = 2.5
	light.position.y = 0.8
	_visual.add_child(light)


func _process(delta: float) -> void:
	if not available:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			available = true
			_visual.visible = true
		return
	_spin += delta
	_visual.rotation.y = _spin * 1.6
	_visual.position.y = 0.55 + sin(_spin * 2.5) * 0.08
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = 0.1
	for body in get_overlapping_bodies():
		if body is Player and try_collect(body as Player):
			return


func try_collect(player: Player) -> bool:
	if not available or not player.alive:
		return false
	var used := player.heal(HEAL_AMOUNT) if kind == Kind.HEALTH else player.add_ammo()
	if not used:
		return false
	available = false
	_visual.visible = false
	_respawn_timer = RESPAWN_TIME
	if sound_fx:
		sound_fx.play("pickup")
	collected.emit(self)
	return true


func get_label() -> String:
	return "+%d HEALTH" % int(HEAL_AMOUNT) if kind == Kind.HEALTH else "+AMMO"


func _build_health_visual() -> void:
	_add_box(Vector3(0.6, 0.42, 0.42), Vector3.ZERO, Color(0.95, 0.95, 0.95))
	_add_box(Vector3(0.36, 0.1, 0.44), Vector3.ZERO, Color(0.85, 0.1, 0.1), true)
	_add_box(Vector3(0.1, 0.32, 0.44), Vector3.ZERO, Color(0.85, 0.1, 0.1), true)
	_add_box(Vector3(0.62, 0.1, 0.1), Vector3(0.0, 0.0, 0.0), Color(0.85, 0.1, 0.1), true)


func _build_ammo_visual() -> void:
	_add_box(Vector3(0.62, 0.32, 0.4), Vector3.ZERO, Color(0.3, 0.36, 0.2))
	_add_box(Vector3(0.64, 0.06, 0.42), Vector3(0.0, 0.1, 0.0), Color(0.18, 0.2, 0.12))
	for index in 4:
		var bullet := CylinderMesh.new()
		bullet.top_radius = 0.02
		bullet.bottom_radius = 0.035
		bullet.height = 0.2
		var bullet_mesh := MeshInstance3D.new()
		bullet_mesh.mesh = bullet
		bullet_mesh.material_override = Fx.unshaded(Color(0.95, 0.75, 0.25), 0.4)
		bullet_mesh.position = Vector3(-0.18 + index * 0.12, 0.26, 0.0)
		_visual.add_child(bullet_mesh)


func _add_box(size: Vector3, offset: Vector3, color: Color, glow := false) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	if glow:
		mesh_instance.material_override = Fx.unshaded(color, 0.8)
	else:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.6
		mesh_instance.material_override = material
	mesh_instance.position = offset
	_visual.add_child(mesh_instance)
