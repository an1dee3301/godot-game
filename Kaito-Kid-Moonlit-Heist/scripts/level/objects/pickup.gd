class_name HeistPickup
extends Node3D
## A floating rose or smoke-bomb supply, consumed only when it benefits the player.

signal collected(kind: String, position: Vector3)

var kind := "rose"
var _model: Node3D
var _glow: OmniLight3D
var _time := 0.0
var _consumed := false


func _ready() -> void:
	add_to_group(KK.GROUP_MINIMAP)
	_build()


## Choose "rose" for 35 health or "smoke" for one bomb.
func setup(pickup_kind: String) -> void:
	kind = pickup_kind
	if is_inside_tree():
		_rebuild_model()


func minimap_icon() -> String:
	return "pickup"


func _process(delta: float) -> void:
	if _consumed:
		return
	_time += delta
	_model.position.y = 0.72 + sin(_time * 2.3) * 0.12
	_model.rotation.y += delta * 0.75
	_glow.light_energy = 0.45 + sin(_time * 2.3) * 0.12


func _on_body_entered(body: Node3D) -> void:
	if _consumed or not body.is_in_group(KK.GROUP_PLAYER):
		return
	var accepted := false
	if kind == "rose" and body.has_method("heal"):
		accepted = body.heal(35.0)
	elif kind == "smoke" and body.has_method("add_smoke"):
		accepted = body.add_smoke(1)
	if not accepted:
		return
	_consumed = true
	collected.emit(kind, global_position)
	var area := get_node("PickupArea") as Area3D
	area.set_deferred("monitoring", false)
	_burst()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_model, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(_glow, "light_energy", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)


func _build() -> void:
	_model = Node3D.new()
	add_child(_model)
	_rebuild_model()
	_glow = OmniLight3D.new()
	_glow.position.y = 0.8
	_glow.omni_range = 2.3
	_glow.shadow_enabled = false
	add_child(_glow)
	_glow.light_color = Color(1.0, 0.2, 0.4) if kind == "rose" else Color(0.7, 0.35, 1.0)
	var area := Area3D.new()
	area.name = "PickupArea"
	area.collision_layer = KK.LAYER_PICKUP
	area.collision_mask = KK.LAYER_PLAYER
	add_child(area)
	var hit := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.65
	hit.shape = shape
	hit.position.y = 0.75
	area.add_child(hit)
	area.body_entered.connect(_on_body_entered)


func _rebuild_model() -> void:
	for child in _model.get_children():
		child.queue_free()
	if kind == "smoke":
		_build_smoke()
	else:
		_build_rose()
	if _glow != null:
		_glow.light_color = Color(1.0, 0.2, 0.4) if kind == "rose" else Color(0.7, 0.35, 1.0)


func _build_rose() -> void:
	var red := KK.standard_material(Color(0.76, 0.02, 0.13), 0.3)
	red.emission_enabled = true
	red.emission = Color(0.75, 0.01, 0.10)
	red.emission_energy_multiplier = 0.9
	var pink := KK.standard_material(Color(1.0, 0.18, 0.35), 0.4)
	var green := KK.standard_material(Color(0.06, 0.32, 0.14), 0.6)
	_cylinder(_model, 0.028, 0.65, Vector3(0, -0.28, 0), green)
	_sphere(_model, 0.14, Vector3(0, 0.10, 0), red)
	for i in 10:
		var angle := TAU * float(i) / 10.0
		var petal := _sphere(_model, 0.17, Vector3(cos(angle) * 0.12, 0.07 + (i % 2) * 0.06, sin(angle) * 0.12), pink if i % 3 == 0 else red)
		petal.scale = Vector3(0.78, 1.25, 0.56)
		petal.rotation.y = angle
	for side in [-1, 1]:
		var leaf := _sphere(_model, 0.12, Vector3(side * 0.15, -0.25, 0), green)
		leaf.scale = Vector3(1.5, 0.28, 0.5)
		leaf.rotation.z = side * 0.3


func _build_smoke() -> void:
	var black := KK.standard_material(Color(0.055, 0.055, 0.09), 0.26, 0.4)
	var silver := KK.standard_material(Color(0.6, 0.65, 0.72), 0.25, 0.8)
	_sphere(_model, 0.28, Vector3.ZERO, black)
	_cylinder(_model, 0.12, 0.09, Vector3(0, 0.27, 0), silver)
	_cylinder(_model, 0.025, 0.22, Vector3(0.04, 0.41, 0), black).rotation.z = 0.4
	var emblem := Label3D.new()
	emblem.text = "K"
	emblem.font_size = 112
	emblem.pixel_size = 0.0024
	emblem.modulate = Color(1.0, 0.4, 0.74)
	emblem.position = Vector3(0, 0, 0.28)
	_model.add_child(emblem)


func _burst() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mat := KK.standard_material(Color(1.0, 0.65, 0.86) if kind == "rose" else Color(0.76, 0.47, 1.0), 0.2)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 2.0
	for i in 8:
		var spark := _sphere(self, 0.035, Vector3(0, 0.8, 0), mat)
		var a := TAU * float(i) / 8.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(spark, "position", spark.position + Vector3(cos(a) * 0.65, 0.2 + float(i % 3) * 0.2, sin(a) * 0.65), 0.35)
		tw.tween_property(spark, "scale", Vector3.ZERO, 0.35)
		tw.chain().tween_callback(spark.queue_free)


func _sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node


func _cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node
