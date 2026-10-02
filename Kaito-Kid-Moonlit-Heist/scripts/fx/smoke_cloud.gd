class_name SmokeCloud
extends Node3D
## A temporary volumetric smoke screen that repeatedly blinds nearby guards.

var radius := KK.SMOKE_RADIUS
var duration := KK.SMOKE_DURATION
var _age := 0.0
var _blind_clock := 0.0
var _fog: FogVolume
var _fog_material: FogMaterial
var _particles: GPUParticles3D
var _flash: OmniLight3D


func _ready() -> void:
	add_to_group("smoke_clouds")
	_fog = FogVolume.new()
	_fog.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	_fog.size = Vector3(radius * 2.0, 3.5, radius * 2.0)
	_fog.position.y = 1.0
	_fog_material = FogMaterial.new()
	_fog_material.albedo = Color(1.0, 0.74, 0.84)
	_fog_material.density = 0.0
	_fog.material = _fog_material
	add_child(_fog)
	if DisplayServer.get_name() != "headless":
		_particles = GPUParticles3D.new()
		_particles.amount = 75
		_particles.lifetime = 2.4
		_particles.explosiveness = 0.35
		_particles.position.y = 0.5
		var process := ParticleProcessMaterial.new()
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		process.emission_sphere_radius = 0.55
		process.direction = Vector3.UP
		process.spread = 170.0
		process.initial_velocity_min = 0.9
		process.initial_velocity_max = 2.4
		process.gravity = Vector3(0.0, 0.1, 0.0)
		process.scale_min = 0.8
		process.scale_max = 1.8
		_particles.process_material = process
		var puff := SphereMesh.new()
		puff.radius = 0.6
		puff.height = 1.2
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.78, 0.86, 0.24)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material = mat
		_particles.draw_pass_1 = puff
		add_child(_particles)
		_particles.emitting = true
		_flash = OmniLight3D.new()
		_flash.light_color = Color(1.0, 0.58, 0.76)
		_flash.light_energy = 3.0
		_flash.omni_range = 5.0
		_flash.position.y = 0.8
		add_child(_flash)


## Sets the gameplay radius and lifetime; safe before or after entering the tree.
func setup(new_radius: float = KK.SMOKE_RADIUS, new_duration: float = KK.SMOKE_DURATION) -> void:
	radius = new_radius
	duration = new_duration
	if _fog:
		_fog.size = Vector3(radius * 2.0, 3.5, radius * 2.0)


func _process(delta: float) -> void:
	_age += delta
	_blind_clock += delta
	var fade_in := clampf(_age / 0.3, 0.0, 1.0)
	var fade_out := clampf((duration - _age) / 1.3, 0.0, 1.0)
	_fog_material.density = 0.14 * fade_in * fade_out
	if _flash:
		_flash.light_energy = 3.0 * maxf(0.0, 1.0 - _age * 5.0)
	if _blind_clock >= 0.25:
		_blind_clock = 0.0
		for guard: Node in get_tree().get_nodes_in_group(KK.GROUP_GUARDS):
			if guard is Node3D and (guard as Node3D).global_position.distance_to(global_position) <= radius and guard.has_method("blind"):
				guard.call("blind", 0.6)
	if _age >= duration:
		queue_free()


## Returns whether a world point lies inside an active smoke screen.
static func point_in_smoke(tree: SceneTree, pos: Vector3) -> bool:
	if tree == null:
		return false
	for cloud: Node in tree.get_nodes_in_group("smoke_clouds"):
		if cloud is SmokeCloud and (cloud as SmokeCloud)._age < (cloud as SmokeCloud).duration:
			var offset: Vector3 = pos - (cloud as SmokeCloud).global_position
			if Vector2(offset.x, offset.z).length() <= (cloud as SmokeCloud).radius and absf(offset.y) < 2.8:
				return true
	return false
