class_name ExitGlider
extends Node3D
## Balcony shutter and the phantom thief's waiting glider.

signal escaped

var locked := true
var _escaped := false
var _shutter: Node3D
var _shutter_body: StaticBody3D
var _left_wing: Node3D
var _right_wing: Node3D
var _beacon: OmniLight3D
var _pillar: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	add_to_group(KK.GROUP_MINIMAP)
	_build()


func minimap_icon() -> String:
	return "exit"


## Whether the balcony gate has opened.
func is_unlocked() -> bool:
	return not locked


## Raise the shutter, unfold the glider, and reveal the escape beacon.
func unlock() -> void:
	if not locked:
		return
	locked = false
	_shutter_body.collision_layer = 0
	_shutter_body.collision_mask = 0
	_label.visible = true
	_pillar.visible = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_shutter, "position:y", 3.7, 1.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_left_wing, "rotation:y", -0.15, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_right_wing, "rotation:y", 0.15, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_left_wing, "scale", Vector3.ONE, 1.0)
	tw.tween_property(_right_wing, "scale", Vector3.ONE, 1.0)
	tw.tween_property(_beacon, "light_energy", 0.85, 1.0)
	_check_occupants()


func _check_occupants() -> void:
	var area := get_node_or_null("EscapeArea") as Area3D
	if area == null:
		return
	for body in area.get_overlapping_bodies():
		_on_body_entered(body)


func _on_body_entered(body: Node3D) -> void:
	if locked or _escaped or not body.is_in_group(KK.GROUP_PLAYER):
		return
	_escaped = true
	escaped.emit()


func _build() -> void:
	var iron := KK.standard_material(Color(0.08, 0.13, 0.20), 0.34, 0.75)
	var gold := KK.standard_material(Color(0.65, 0.47, 0.19), 0.26, 0.83)
	var white := KK.standard_material(Color(0.92, 0.95, 1.0), 0.78)
	white.cull_mode = BaseMaterial3D.CULL_DISABLED
	var blue := KK.standard_material(Color(0.065, 0.23, 0.57), 0.3, 0.25)
	_box(self, Vector3(0.14, 3.5, 0.2), Vector3(-1.55, 1.75, 0), gold)
	_box(self, Vector3(0.14, 3.5, 0.2), Vector3(1.55, 1.75, 0), gold)
	_box(self, Vector3(3.25, 0.18, 0.23), Vector3(0, 3.42, 0), gold)
	_shutter = Node3D.new()
	add_child(_shutter)
	for side: int in [-1, 1]:
		for i in 6:
			var x: float = side * (0.13 + float(i) * 0.24)
			_box(_shutter, Vector3(0.055, 2.85, 0.08), Vector3(x, 1.52, 0), iron)
		for y in [0.45, 1.55, 2.65]:
			_box(_shutter, Vector3(1.46, 0.045, 0.1), Vector3(side * 0.76, y, 0), iron)
		_box(_shutter, Vector3(0.045, 2.95, 0.09), Vector3(side * 0.04, 1.5, 0), gold)
	_box(_shutter, Vector3(3.0, 0.13, 0.13), Vector3(0, 2.98, 0), gold)
	_shutter_body = StaticBody3D.new()
	_shutter_body.collision_layer = KK.LAYER_WORLD
	_shutter_body.collision_mask = 0
	add_child(_shutter_body)
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = Vector3(3.0, 3.0, 0.2)
	shape.shape = block
	shape.position.y = 1.5
	_shutter_body.add_child(shape)
	var craft := Node3D.new()
	craft.position = Vector3(0, 2.0, -1.8)
	add_child(craft)
	_box(craft, Vector3(0.11, 0.10, 1.72), Vector3(0, -0.07, -0.25), blue)
	_box(craft, Vector3(0.75, 0.07, 0.32), Vector3(0, -0.25, 0.36), white)
	_left_wing = _wing(craft, -1, white, blue)
	_right_wing = _wing(craft, 1, white, blue)
	_left_wing.scale = Vector3(0.14, 1, 1)
	_right_wing.scale = Vector3(0.14, 1, 1)
	var emblem := Label3D.new()
	emblem.text = "♠  KID  ♠"
	emblem.font_size = 35
	emblem.pixel_size = 0.0027
	emblem.modulate = Color(0.08, 0.28, 0.62)
	emblem.position = Vector3(0, 0.11, -0.52)
	emblem.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	craft.add_child(emblem)
	_box(craft, Vector3(0.88, 0.02, 0.37), Vector3(0, -0.24, -0.45), white)
	var area := Area3D.new()
	area.name = "EscapeArea"
	area.collision_layer = 0
	area.collision_mask = KK.LAYER_PLAYER
	add_child(area)
	area.position = Vector3(0, 1.5, -1.6)
	var hit := CollisionShape3D.new()
	var volume := BoxShape3D.new()
	volume.size = Vector3(3.0, 3.0, 2.4)
	hit.shape = volume
	area.add_child(hit)
	area.body_entered.connect(_on_body_entered)
	_beacon = OmniLight3D.new()
	_beacon.position = Vector3(0, 2.35, -1.8)
	_beacon.light_color = Color(0.78, 0.9, 1.0)
	_beacon.omni_range = 5.5
	_beacon.light_energy = 0.0
	_beacon.shadow_enabled = false
	add_child(_beacon)
	var pillar_mat := StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.62, 0.83, 1.0, 0.018)
	pillar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pillar_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pillar_mat.emission_enabled = true
	pillar_mat.emission = Color(0.5, 0.75, 1.0)
	pillar_mat.emission_energy_multiplier = 0.12
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.28
	cylinder.bottom_radius = 1.05
	cylinder.height = 3.7
	_pillar = MeshInstance3D.new()
	_pillar.mesh = cylinder
	_pillar.material_override = pillar_mat
	_pillar.position = Vector3(0, 1.85, -2.1)
	_pillar.visible = false
	add_child(_pillar)
	_label = Label3D.new()
	_label.text = "BALCONY  •  GLIDER READY"
	_label.font_size = 28
	_label.pixel_size = 0.0021
	_label.modulate = Color(0.9, 0.95, 1.0)
	_label.position = Vector3(0, 3.43, 0.15)
	_label.outline_size = 0
	_label.visible = false
	add_child(_label)


func _wing(parent: Node3D, side: int, cloth: Material, frame: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(side * 0.08, 0, -0.3)
	parent.add_child(pivot)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3.ZERO
	var b := Vector3(side * 2.75, 0.12, 0.43)
	var c := Vector3(side * 2.38, 0.13, -0.50)
	var d := Vector3(side * 0.14, 0.04, -1.05)
	for triangle in [[a, b, d], [b, c, d]]:
		var normal: Vector3 = (triangle[1] - triangle[0]).cross(triangle[2] - triangle[0]).normalized()
		for vertex in triangle:
			st.set_normal(normal)
			st.add_vertex(vertex)
	var sail := MeshInstance3D.new()
	sail.mesh = st.commit()
	sail.material_override = cloth
	sail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	pivot.add_child(sail)
	_rod(pivot, a, b, 0.038, frame)
	_rod(pivot, b, c, 0.028, frame)
	_rod(pivot, c, d, 0.030, frame)
	_rod(pivot, a, d, 0.025, frame)
	_rod(pivot, a, c, 0.018, frame)
	return pivot


func _rod(parent: Node3D, from: Vector3, to: Vector3, radius: float, mat: Material) -> void:
	var length := from.distance_to(to)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 8
	var rod := MeshInstance3D.new()
	rod.mesh = mesh
	rod.material_override = mat
	rod.position = (from + to) * 0.5
	rod.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	parent.add_child(rod)


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node
