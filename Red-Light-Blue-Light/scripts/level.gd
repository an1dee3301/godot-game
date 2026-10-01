class_name GameLevel
extends Node3D
## Procedural sand race field, painted perimeter, starting pen and finish monument.

const START_Z := 34.0
const FINISH_Z := -34.0
const COLORS := [Color("4fc4ff"), Color("ff9c59"), Color("91df80"), Color("e989d9"), Color("f6d465"), Color("aaa0fa"), Color("6cd9c3"), Color("ea707e")]
var doll: GameDoll
var gate: StaticBody3D
var spawn_points: Array[Vector3] = []

func _ready() -> void:
	_box("OuterGround", Vector3(0, -0.68, 0), Vector3(80, 1.2, 120), Color("977f67"))
	_box("Sand", Vector3(0, -0.55, 0), Vector3(32, 1, 96), Color("caa979"), true)
	for i in 18:
		var z := -32.0 + i * 3.7
		var x := sin(float(i) * 7.1) * 9.5
		_box("SandPatch", Vector3(x, 0.006, z), Vector3(3.0 + float(i % 3), 0.008, 1.2), Color("d8b889") if i % 2 == 0 else Color("bf9e71"))
	_box("StartingPen", Vector3(0, 0.012, 40.2), Vector3(31.7, 0.025, 11.5), Color("bb9775"))
	for i in range(1, 8):
		_box("PenLane", Vector3(-15.75 + i * 3.5, 0.028, 40.2), Vector3(0.045, 0.018, 10.5), Color("e6d5b6"))
	for side in [-1.0, 1.0]:
		_box("Wall", Vector3(side * 16.3, 1.55, 0), Vector3(0.7, 3.1, 96), Color("83bfd0"), true)
		_box("WallCap", Vector3(side * 16.3, 3.13, 0), Vector3(0.9, 0.18, 96), Color("eef1df"))
		for z in [-38.0, -15.0, 9.0, 31.0]:
			_cloud(side, z)
		for distance in [60, 50, 40, 30, 20, 10]:
			_distance_marker(side, float(distance), FINISH_Z + float(distance))
		for z in [-23.0, 3.0, 23.0]:
			_guard(Vector3(side * 14.5, 0, z), int(abs(z)) % 3, side)
	_box("EndWall", Vector3(0, 1.55, -48), Vector3(33, 3.1, 0.7), Color("83bfd0"), true)
	_box("BackWall", Vector3(0, 1.55, 48), Vector3(33, 3.1, 0.7), Color("83bfd0"), true)
	_box("StartLine", Vector3(0, 0.045, START_Z), Vector3(31.7, 0.045, 0.42), Color("fff8e8"))
	_box("FinishLine", Vector3(0, 0.055, FINISH_Z), Vector3(31.7, 0.055, 0.52), Color("ca3946"))
	for i in 8:
		spawn_points.append(Vector3(-12.25 + i * 3.5, 0.1, 38))
	for spot in [Vector3(-10, 0, 16), Vector3(8, 0, 8), Vector3(-5, 0, -7), Vector3(11, 0, -14), Vector3(-10, 0, -26)]:
		_crate(spot)
	gate = StaticBody3D.new()
	gate.name = "StartGate"
	gate.collision_layer = 1
	gate.collision_mask = 0
	add_child(gate)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(32, 3.3, 0.45)
	shape.shape = box
	shape.position = Vector3(0, 1.65, START_Z - 1.0)
	gate.add_child(shape)
	var gate_mesh := _box("GateGlow", shape.position, box.size, Color(0.25, 0.69, 0.95, 0.2))
	gate_mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gate_mesh.reparent(gate)
	doll = GameDoll.new()
	doll.name = "Doll"
	doll.position = Vector3(0, 0, -40.5)
	add_child(doll)
	_tree(Vector3(0, 0, -46.5))
	_finish_banner()
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.light_color = Color("fff0d3")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("80bfd6")
	sky_material.sky_horizon_color = Color("e8d6b5")
	sky_material.ground_bottom_color = Color("8a7869")
	sky_material.ground_horizon_color = Color("d8c4a2")
	sky_material.sun_angle_max = 25.0
	sky.sky_material = sky_material
	environment.sky = sky
	# A fixed, dim ambient keeps the bright sky from washing the sand out to white.
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8c7d6")
	environment.ambient_light_energy = 0.32
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.9
	env.environment = environment
	add_child(env)

func set_gate_closed(closed: bool) -> void:
	if gate != null:
		gate.collision_layer = 1 if closed else 0
		gate.visible = closed

func spawn_point(slot: int) -> Vector3:
	return spawn_points[clampi(slot, 0, 7)]

func _cloud(side: float, z: float) -> void:
	for offset in [Vector3(0, 0, 0), Vector3(0, 0.23, -0.9), Vector3(0, -0.1, 1.0)]:
		var puff := MeshInstance3D.new()
		puff.name = "PaintedCloud"
		var sphere := SphereMesh.new()
		sphere.radius = 0.8
		sphere.height = 1.6
		puff.mesh = sphere
		puff.scale = Vector3(0.045, 0.72, 1.7)
		puff.position = Vector3(side * 15.92, 2.15, z) + offset
		puff.material_override = _material(Color("f6f2df"), true)
		add_child(puff)

func _distance_marker(side: float, distance: float, z: float) -> void:
	var plaque := _box("DistancePlaque", Vector3(side * 15.88, 1.35, z), Vector3(0.08, 1.0, 2.5), Color("587f8c"))
	plaque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label := Label3D.new()
	label.text = "%d m" % int(distance)
	label.font_size = 72
	label.pixel_size = 0.005
	label.position = Vector3(side * 15.79, 1.1, z)
	label.rotation.y = PI * 0.5 if side < 0.0 else -PI * 0.5
	label.modulate = Color("fff8e6")
	add_child(label)

func _guard(at: Vector3, symbol: int, side: float) -> void:
	_box("GuardBoots", at + Vector3(0, 0.18, 0), Vector3(0.85, 0.36, 0.65), Color("292d34"))
	_box("GuardSuit", at + Vector3.UP * 1.2, Vector3(0.85, 1.55, 0.65), Color("d64870"))
	_box("GuardMask", at + Vector3.UP * 2.24, Vector3(0.74, 0.72, 0.7), Color("252936"))
	var label := Label3D.new()
	label.text = ["○", "△", "□"][symbol]
	label.font_size = 82
	label.pixel_size = 0.004
	label.position = at + Vector3(0, 2.24, -0.37 if side > 0 else 0.37)
	label.rotation.y = PI if side > 0 else 0.0
	label.modulate = Color.WHITE
	add_child(label)

func _crate(at: Vector3) -> void:
	_box("Crate", at + Vector3.UP * 0.9, Vector3(2.3, 1.8, 2.3), Color("957355"), true)
	for y in [0.15, 1.65]:
		_box("CrateBand", at + Vector3(0, y, 1.17), Vector3(2.35, 0.12, 0.07), Color("6b543f"))

func _tree(at: Vector3) -> void:
	_box("TreeTrunk", at + Vector3.UP * 4.2, Vector3(1.35, 8.4, 1.35), Color("695345"))
	for branch in [Vector3(0, 9.3, 0), Vector3(-2.4, 8.4, 0), Vector3(2.3, 8.6, 0), Vector3(0, 11.5, 0)]:
		var crown := MeshInstance3D.new()
		crown.name = "TreeCrown"
		var sphere := SphereMesh.new()
		sphere.radius = 2.7
		sphere.height = 5.4
		crown.mesh = sphere
		crown.position = at + branch
		crown.material_override = _material(Color("4d7554") if branch.x == 0.0 else Color("61865d"))
		add_child(crown)

func _finish_banner() -> void:
	for x in [-12.0, 12.0]:
		_box("FinishPost", Vector3(x, 2.9, FINISH_Z), Vector3(0.23, 5.8, 0.23), Color("eee7d4"))
	_box("FinishBanner", Vector3(0, 5.4, FINISH_Z), Vector3(24.2, 1.3, 0.2), Color("b72d41"))
	var label := Label3D.new()
	label.text = "FINISH"
	label.font_size = 108
	label.pixel_size = 0.008
	label.position = Vector3(0, 5.08, FINISH_Z + 0.14)
	label.modulate = Color("fff6e4")
	add_child(label)

func _box(label: String, at: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	mesh.material_override = _material(color)
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = at
		add_child(body)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	return mesh

func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
