class_name GameDoll
extends Node3D
## Giant turning doll with signal lamps and fading eye beams.

var head_pivot: Node3D
var eyes: Array[MeshInstance3D] = []
var lamps: Array[MeshInstance3D] = []
var lamp_lights: Array[OmniLight3D] = []
var board: Label3D
var _beams: Array[Dictionary] = []
var _head_target := PI

func _ready() -> void:
	_part("Pedestal", Vector3(0, 0.45, 0), Vector3(5.2, 0.9, 4.4), Color("808892"))
	_part("PedestalTrim", Vector3(0, 0.93, 0), Vector3(5.35, 0.12, 4.55), Color("d4c4a4"))
	for x in [-1.0, 1.0]:
		_part("Sock", Vector3(x * 0.49, 1.5, 0), Vector3(0.57, 0.8, 0.67), Color("fff3d7"))
		_part("Shoe", Vector3(x * 0.49, 1.16, 0.24), Vector3(0.7, 0.33, 1.04), Color("4a302e"))
		_part("Leg", Vector3(x * 0.49, 2.15, 0), Vector3(0.6, 1.05, 0.67), Color("edb98c"))
	_skirt()
	_part("Shirt", Vector3(0, 4.63, 0), Vector3(1.8, 1.7, 1.0), Color("f4d073"))
	_part("PinaforeBib", Vector3(0, 4.52, 0.55), Vector3(1.22, 1.2, 0.11), Color("d9733b"))
	for x in [-1.0, 1.0]:
		_part("Strap", Vector3(x * 0.58, 5.15, 0.57), Vector3(0.23, 0.65, 0.14), Color("d9733b"))
		_part("Arm", Vector3(x * 1.23, 4.42, 0), Vector3(0.51, 1.5, 0.58), Color("f4d073"))
		_sphere("Hand", Vector3(x * 1.23, 3.59, 0), Vector3(0.33, 0.37, 0.32), Color("edb98c"))
	_part("Neck", Vector3(0, 5.52, 0), Vector3(0.57, 0.42, 0.55), Color("edb98c"))
	head_pivot = Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position.y = 6.25
	add_child(head_pivot)
	_sphere("Head", Vector3.ZERO, Vector3(1.02, 1.12, 0.82), Color("edb98c"), head_pivot)
	_sphere("HairCap", Vector3(0, 0.72, -0.14), Vector3(1.06, 0.48, 0.86), Color("28252b"), head_pivot)
	_part("Fringe", Vector3(0, 0.58, 0.7), Vector3(1.55, 0.25, 0.2), Color("28252b"), head_pivot)
	for x in [-1.0, 1.0]:
		_sphere("Bob", Vector3(x * 0.83, 0.05, -0.02), Vector3(0.32, 0.72, 0.74), Color("28252b"), head_pivot)
		_sphere("Pigtail", Vector3(x * 1.27, 0.12, -0.1), Vector3(0.38, 0.62, 0.43), Color("28252b"), head_pivot)
		_part("HairTie", Vector3(x * 1.02, 0.33, -0.04), Vector3(0.2, 0.18, 0.23), Color("c5524f"), head_pivot)
		_sphere("EyeWhite", Vector3(x * 0.4, 0.13, 0.73), Vector3(0.22, 0.2, 0.07), Color("fff9e7"), head_pivot)
		var eye := _sphere("Eye", Vector3(x * 0.4, 0.11, 0.795), Vector3(0.09, 0.11, 0.055), Color("242229"), head_pivot)
		eyes.append(eye)
	_part("Nose", Vector3(0, -0.14, 0.84), Vector3(0.14, 0.17, 0.12), Color("d99d78"), head_pivot)
	_part("Mouth", Vector3(0, -0.43, 0.78), Vector3(0.42, 0.05, 0.07), Color("a95a58"), head_pivot)
	for x in [-1.0, 1.0]:
		_part("LampPost", Vector3(x * 5.8, 3.6, 0), Vector3(0.24, 7.2, 0.24), Color("455563"))
		_part("LampHousing", Vector3(x * 5.8, 7.25, 0), Vector3(1.45, 1.32, 0.95), Color("455563"))
		var lamp := _part("LampBulb", Vector3(x * 5.8, 7.25, 0.51), Vector3(1.04, 0.93, 0.12), Color("358ed0"))
		lamps.append(lamp)
		var glow := OmniLight3D.new()
		glow.position = Vector3(x * 5.8, 7.25, 0.7)
		glow.omni_range = 8.0
		glow.light_energy = 2.0
		glow.shadow_enabled = false
		add_child(glow)
		lamp_lights.append(glow)
	_part("SignalBoard", Vector3(0, 8.25, 0), Vector3(7.7, 1.13, 0.32), Color("34414b"))
	board = Label3D.new()
	board.position = Vector3(0, 7.95, 0.2)
	board.font_size = 96
	board.pixel_size = 0.007
	board.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(board)
	set_light(0)
	head_pivot.rotation.y = _head_target

func set_light(light: int) -> void:
	if head_pivot == null:
		return
	var color := Color("329fe8")
	var caption := "BLUE LIGHT"
	_head_target = PI
	if light == 1:
		color = Color("f6b841")
		caption = "TURNING"
		_head_target = PI * 0.5
	elif light == 2:
		color = Color("ed4050")
		caption = "RED LIGHT"
		_head_target = 0.0
	for eye in eyes:
		eye.material_override = _material(Color("ff3345") if light == 2 else Color("e9a344") if light == 1 else Color("242229"), light != 0)
	for lamp in lamps:
		lamp.material_override = _material(color, true)
	for glow in lamp_lights:
		glow.light_color = color
	board.text = caption
	board.modulate = color

func fire_beam(target_pos: Vector3) -> void:
	for eye in eyes:
		var start := eye.global_position
		var beam := MeshInstance3D.new()
		beam.name = "EyeBeam"
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.075
		mesh.bottom_radius = 0.075
		mesh.height = start.distance_to(target_pos)
		beam.mesh = mesh
		beam.material_override = _material(Color("ff2639"), true)
		beam.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		add_child(beam)
		beam.global_position = (start + target_pos) * 0.5
		beam.look_at(target_pos, Vector3.UP)
		beam.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		_beams.append({"node": beam, "remaining": 0.4})

func _process(delta: float) -> void:
	if head_pivot != null:
		head_pivot.rotation.y = lerp_angle(head_pivot.rotation.y, _head_target, minf(delta * 6.0, 1.0))
	for i in range(_beams.size() - 1, -1, -1):
		_beams[i]["remaining"] = float(_beams[i]["remaining"]) - delta
		var beam := _beams[i]["node"] as MeshInstance3D
		if float(_beams[i]["remaining"]) <= 0.0:
			beam.queue_free()
			_beams.remove_at(i)
		else:
			var mat := beam.material_override as StandardMaterial3D
			mat.albedo_color.a = float(_beams[i]["remaining"]) / 0.4

func _part(part_name: String, at: Vector3, size: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = at
	item.material_override = _material(color)
	(parent if parent != null else self).add_child(item)
	return item

func _sphere(part_name: String, at: Vector3, size: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = part_name
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	item.mesh = mesh
	item.scale = size
	item.position = at
	item.material_override = _material(color)
	(parent if parent != null else self).add_child(item)
	return item

func _skirt() -> void:
	var item := MeshInstance3D.new()
	item.name = "OrangePinafore"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.76
	cone.bottom_radius = 1.6
	cone.height = 2.25
	item.mesh = cone
	item.position.y = 3.26
	item.material_override = _material(Color("d9733b"))
	add_child(item)

func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.0
	return material
