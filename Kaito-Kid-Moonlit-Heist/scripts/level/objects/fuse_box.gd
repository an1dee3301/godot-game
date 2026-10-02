class_name FuseBox
extends Node3D
## A wall-mounted breaker that cuts power to its connected laser grids.

signal disabled

var _grids: Array = []
var _used := false
var _lever: Node3D
var _led: MeshInstance3D
var _led_light: OmniLight3D


func _ready() -> void:
	add_to_group(KK.GROUP_INTERACTABLE)
	add_to_group(KK.GROUP_MINIMAP)
	_build()


## Connect laser grids controlled by this breaker.
func setup(grids: Array) -> void:
	_grids = grids


func minimap_icon() -> String:
	return "fuse"


func can_interact(_player: PhantomThief) -> bool:
	return not _used


func get_prompt() -> String:
	return "[E] Cut the laser power"


func interact_position() -> Vector3:
	return global_position + global_basis * Vector3(0, 0, 0.18)


func interact(_player: PhantomThief) -> void:
	if _used:
		return
	_used = true
	for grid in _grids:
		if is_instance_valid(grid) and grid.has_method("set_active"):
			grid.set_active(false)
	var tw := create_tween()
	tw.tween_property(_lever, "rotation:x", 1.15, 0.25).set_trans(Tween.TRANS_BOUNCE)
	var green := KK.standard_material(Color(0.1, 1.0, 0.42), 0.18)
	green.emission_enabled = true
	green.emission = Color(0.02, 1.0, 0.2)
	green.emission_energy_multiplier = 3.0
	_led.material_override = green
	_led_light.light_color = Color(0.15, 1.0, 0.38)
	_sparks()
	disabled.emit()


func _build() -> void:
	var navy := KK.standard_material(Color(0.12, 0.18, 0.26), 0.36, 0.6)
	var steel := KK.standard_material(Color(0.44, 0.52, 0.57), 0.28, 0.76)
	var gold := KK.standard_material(Color(0.68, 0.47, 0.19), 0.27, 0.7)
	_box(self, Vector3(0.63, 0.91, 0.16), Vector3(0, 0, -0.08), steel)
	_box(self, Vector3(0.55, 0.79, 0.04), Vector3(0, 0, 0.02), navy)
	for x in [-0.25, 0.25]:
		for y in [-0.38, 0.38]:
			var screw := _sphere(self, 0.025, Vector3(x, y, 0.046), gold)
			screw.scale.z = 0.3
	var label := Label3D.new()
	label.text = "SECURITY / LASERS"
	label.font_size = 44
	label.pixel_size = 0.0018
	label.modulate = Color(0.94, 0.83, 0.55)
	label.position = Vector3(0, 0.27, 0.06)
	add_child(label)
	_lever = Node3D.new()
	_lever.position = Vector3(0, -0.07, 0.09)
	add_child(_lever)
	_box(_lever, Vector3(0.18, 0.21, 0.08), Vector3.ZERO, steel)
	_box(_lever, Vector3(0.075, 0.4, 0.075), Vector3(0, -0.18, 0.10), gold)
	_sphere(_lever, 0.09, Vector3(0, -0.39, 0.10), navy)
	var red := KK.standard_material(Color(1.0, 0.08, 0.06), 0.2)
	red.emission_enabled = true
	red.emission = Color(1.0, 0.02, 0.02)
	red.emission_energy_multiplier = 3.0
	_led = _sphere(self, 0.065, Vector3(0.19, 0.15, 0.067), red)
	_led_light = OmniLight3D.new()
	_led_light.position = Vector3(0.19, 0.15, 0.12)
	_led_light.omni_range = 1.2
	_led_light.light_energy = 0.3
	_led_light.light_color = Color(1, 0.1, 0.05)
	_led_light.shadow_enabled = false
	add_child(_led_light)


func _sparks() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mat := KK.standard_material(Color(1.0, 0.82, 0.3), 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.5, 0.08)
	mat.emission_energy_multiplier = 4.0
	for i in 8:
		var spark := _sphere(self, 0.025, Vector3(0, -0.1, 0.16), mat)
		var angle := TAU * float(i) / 8.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(spark, "position", spark.position + Vector3(cos(angle) * 0.43, sin(angle) * 0.45, 0.3), 0.35)
		tw.tween_property(spark, "scale", Vector3.ZERO, 0.35)
		tw.chain().tween_callback(spark.queue_free)


func _sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node
