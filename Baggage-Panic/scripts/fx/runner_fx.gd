class_name RunnerFX
extends Node3D
## Reused, short lived CPU particle bursts. All emitters share geometry and materials.

const POOL_SIZE := 12
var _emitters: Array[CPUParticles3D] = []
var _cursor := 0
var _spark_mesh: SphereMesh
var _spark_material: StandardMaterial3D


func _ready() -> void:
	_spark_mesh = SphereMesh.new()
	_spark_mesh.radius = 0.035
	_spark_mesh.height = 0.07
	_spark_material = StandardMaterial3D.new()
	_spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_spark_material.vertex_color_use_as_albedo = true
	_spark_material.emission_enabled = true
	_spark_material.emission = Color.WHITE
	for index: int in POOL_SIZE:
		var emitter := CPUParticles3D.new()
		emitter.name = "Burst%d" % index
		emitter.amount = 20
		emitter.lifetime = 0.55
		emitter.one_shot = true
		emitter.explosiveness = 1.0
		emitter.emitting = false
		emitter.mesh = _spark_mesh
		emitter.material_override = _spark_material
		emitter.gravity = Vector3(0.0, -3.0, 0.0)
		emitter.direction = Vector3.UP
		emitter.spread = 180.0
		emitter.initial_velocity_min = 2.0
		emitter.initial_velocity_max = 5.0
		add_child(emitter)
		_emitters.append(emitter)


func burst(at: Vector3, tint: Color, amount: int = 20, speed: float = 4.0) -> void:
	var emitter := _emitters[_cursor]
	_cursor = (_cursor + 1) % _emitters.size()
	emitter.emitting = false
	emitter.global_position = at
	emitter.color = tint
	emitter.amount = amount
	emitter.initial_velocity_min = speed * 0.45
	emitter.initial_velocity_max = speed
	emitter.restart()


func pickup(at: Vector3, kind: int) -> void:
	var tint := Color("ffe66d")
	match kind:
		Pickup.Type.PASSPORT:
			tint = Color("77dfff")
		Pickup.Type.PRIORITY:
			tint = Color("ffab39")
		Pickup.Type.FRAGILE:
			tint = Color("76ffdc")
	burst(at, tint, 26, 4.6)


func shield_break(at: Vector3) -> void:
	burst(at + Vector3.UP * 0.75, Color("75ecff"), 42, 6.0)


func death(at: Vector3) -> void:
	burst(at + Vector3.UP * 0.8, Color("ff8976"), 52, 7.0)


func checkpoint(at: Vector3) -> void:
	burst(at + Vector3.UP, Color("ffe080"), 38, 4.8)


func route(at: Vector3, correct: bool) -> void:
	burst(at + Vector3.UP, Color("6ff5a3") if correct else Color("ff786e"), 32, 5.0)


func level_up(at: Vector3) -> void:
	burst(at + Vector3.UP, Color("ffeb7f"), 45, 5.5)
