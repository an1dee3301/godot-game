extends RigidBody3D
## Answer is data; the round controller decides whether it qualifies at the buzzer.
var answer_index: int = 0
var holder: Node3D = null
const COLORS: Array[Color] = [Color("ff6b61"), Color("6daaff"), Color("87eed0"), Color("ffe17c")]
var network_replica: bool = false
var _network_position: Vector3 = Vector3.ZERO
var _network_rotation: Vector3 = Vector3.ZERO
var _network_received: bool = false
var lifetime: float = 0.0
var is_junk: bool = false
var smoke: bool = false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 7
	mass = 0.65
	contact_monitor = true
	max_contacts_reported = 5
	var material: PhysicsMaterial = PhysicsMaterial.new()
	material.bounce = 0.4
	material.friction = 0.7
	physics_material_override = material
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3.ONE * (0.65 if is_junk else 1.05)
	shape.shape = box
	add_child(shape)
	var asset_name: String = "smoke_bomb" if smoke else ("banana" if is_junk else "answer_block")
	var packed: PackedScene = load("res://assets/props/%s.glb" % asset_name)
	var visual: Node3D = packed.instantiate() as Node3D
	add_child(visual)
	if not is_junk:
		for child: Node in visual.find_children("*","MeshInstance3D",true,false):
			var mesh_instance: MeshInstance3D = child as MeshInstance3D
			for surface in mesh_instance.mesh.get_surface_count():
				var original: Material = mesh_instance.mesh.surface_get_material(surface)
				if original is StandardMaterial3D and original.resource_name.begins_with("M_Answer"):
					var mat: StandardMaterial3D = original.duplicate() as StandardMaterial3D
					mat.albedo_color = COLORS[answer_index]
					mesh_instance.set_surface_override_material(surface,mat)
		for side in 5:
			var label: Label3D = Label3D.new()
			label.text = "ABCD"[answer_index]
			label.font_size = 76
			label.pixel_size = 0.010
			label.modulate = Color("233e73")
			label.outline_size = 0
			if side == 4:
				label.position = Vector3(0,0.57,0)
				label.rotation.x = -PI / 2.0
			else:
				label.position = Vector3(sin(side * PI / 2.0) * 0.57,0,cos(side * PI / 2.0) * 0.57)
				label.rotation.y = side * PI / 2.0
			add_child(label)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if network_replica: return
	lifetime += delta
	if is_instance_valid(holder):
		global_position = holder.global_position + Vector3(0, 1.15, 0) + holder.facing * 0.3
		rotation = Vector3(0, lifetime, sin(lifetime * 3.0) * 0.1)
	elif global_position.y < -15.0 or (is_junk and lifetime > 10.0):
		queue_free()

func take(actor: Node3D) -> void:
	if is_instance_valid(holder): holder.held_cube = null
	holder = actor
	actor.held_cube = self
	freeze = true
	collision_layer = 0
	collision_mask = 0

func drop(impulse: Vector3 = Vector3.ZERO) -> void:
	if is_instance_valid(holder): holder.held_cube = null
	holder = null
	freeze = false
	collision_layer = 4
	collision_mask = 7
	linear_velocity = impulse

func _on_body_entered(body: Node) -> void:
	if not is_junk or not body.has_method("apply_knockback"):
		return
	var direction: Vector3 = body.global_position - global_position
	direction.y = 0.25
	body.apply_knockback(direction.normalized() * 4.5)
	if smoke:
		var cloud: MeshInstance3D = MeshInstance3D.new()
		cloud.set_meta("party_smoke",true)
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 1.6
		sphere.height = 2.2
		cloud.mesh = sphere
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.55,0.44,0.7,0.64)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cloud.material_override = mat
		get_parent().add_child(cloud)
		cloud.global_position = global_position + Vector3.UP
		var tween: Tween = cloud.create_tween()
		tween.tween_property(cloud,"scale",Vector3(2.4,2.4,2.4),2.0)
		tween.parallel().tween_property(cloud,"transparency",1.0,2.0)
		tween.tween_callback(cloud.queue_free)
	queue_free()

func configure_network_replica() -> void:
	network_replica = true
	freeze = true
	collision_layer = 0
	collision_mask = 0
	contact_monitor = false

func apply_network_snapshot(data: Dictionary) -> void:
	_network_position = data.get("position",global_position)
	_network_rotation = data.get("rotation",rotation)
	if not _network_received or global_position.distance_to(_network_position) > 4.0:
		global_position = _network_position
		rotation = _network_rotation
		reset_physics_interpolation()
	_network_received = true

func _process(delta: float) -> void:
	if not network_replica or not _network_received: return
	var blend: float = 1.0 - exp(-delta * 22.0)
	global_position = global_position.lerp(_network_position,blend)
	rotation = Vector3(lerp_angle(rotation.x,_network_rotation.x,blend),lerp_angle(rotation.y,_network_rotation.y,blend),lerp_angle(rotation.z,_network_rotation.z,blend))
