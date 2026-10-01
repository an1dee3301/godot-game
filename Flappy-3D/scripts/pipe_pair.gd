class_name PipePair
extends Node3D

signal bird_hit
signal point_scored

const WORLD_BOTTOM := -3.25
const WORLD_TOP := 9.25
const PIPE_RADIUS := 0.92
const COLLAR_RADIUS := 1.13
const SCORE_GATE_TRAIL := 2.0

var move_speed := 5.2
var running := true
var scored := false
var _gap_center := 2.5
var _gap_size := 3.3
var _palette_index := 0


func configure(start_z: float, gap_center_y: float, gap_height: float, speed: float, palette: int) -> void:
	position = Vector3(0.0, 0.0, start_z)
	_gap_center = gap_center_y
	_gap_size = gap_height
	move_speed = speed
	_palette_index = palette


func _ready() -> void:
	_build_pipes()
	_build_score_gate()


func _physics_process(delta: float) -> void:
	if not running:
		return
	position.z += move_speed * delta
	if position.z > 4.0:
		queue_free()


func set_running(value: bool) -> void:
	running = value


func _build_pipes() -> void:
	var gap_bottom := _gap_center - _gap_size * 0.5
	var gap_top := _gap_center + _gap_size * 0.5
	var lower_height := gap_bottom - WORLD_BOTTOM
	var upper_height := WORLD_TOP - gap_top

	var body_colors := [
		Color(0.09, 0.58, 0.38),
		Color(0.08, 0.52, 0.48),
		Color(0.24, 0.58, 0.3),
	]
	var rim_colors := [
		Color(0.22, 0.83, 0.53),
		Color(0.21, 0.77, 0.69),
		Color(0.48, 0.78, 0.32),
	]
	var body_material := _material(body_colors[_palette_index % body_colors.size()], 0.68)
	var rim_material := _material(rim_colors[_palette_index % rim_colors.size()], 0.6)
	var inner_material := _material(Color(0.025, 0.18, 0.14), 0.86)
	body_material.metallic = 0.24
	rim_material.metallic = 0.18
	rim_material.emission_enabled = true
	rim_material.emission = rim_colors[_palette_index % rim_colors.size()] * 0.48
	rim_material.emission_energy_multiplier = 1.35

	_make_pipe_visual((WORLD_BOTTOM + gap_bottom) * 0.5, lower_height, gap_bottom, false, body_material, rim_material, inner_material)
	_make_pipe_visual((WORLD_TOP + gap_top) * 0.5, upper_height, gap_top, true, body_material, rim_material, inner_material)

	var hazard := Area3D.new()
	hazard.name = "Hazard"
	hazard.collision_layer = 2
	hazard.collision_mask = 1
	hazard.monitoring = true
	add_child(hazard)
	_add_box_shape(hazard, Vector3(PIPE_RADIUS * 2.0, lower_height, PIPE_RADIUS * 2.0), Vector3(0.0, (WORLD_BOTTOM + gap_bottom) * 0.5, 0.0))
	_add_box_shape(hazard, Vector3(COLLAR_RADIUS * 2.0, 0.38, COLLAR_RADIUS * 2.0), Vector3(0.0, gap_bottom - 0.08, 0.0))
	_add_box_shape(hazard, Vector3(PIPE_RADIUS * 2.0, upper_height, PIPE_RADIUS * 2.0), Vector3(0.0, (WORLD_TOP + gap_top) * 0.5, 0.0))
	_add_box_shape(hazard, Vector3(COLLAR_RADIUS * 2.0, 0.38, COLLAR_RADIUS * 2.0), Vector3(0.0, gap_top + 0.08, 0.0))
	hazard.body_entered.connect(_on_hazard_body_entered)


func _make_pipe_visual(
	center_y: float,
	height: float,
	opening_y: float,
	is_upper: bool,
	body_material: StandardMaterial3D,
	rim_material: StandardMaterial3D,
	inner_material: StandardMaterial3D
) -> void:
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = PIPE_RADIUS
	body_mesh.bottom_radius = PIPE_RADIUS
	body_mesh.height = height + 0.08
	body_mesh.radial_segments = 16
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.material_override = body_material
	body.position.y = center_y
	add_child(body)

	var collar_mesh := CylinderMesh.new()
	collar_mesh.top_radius = COLLAR_RADIUS
	collar_mesh.bottom_radius = COLLAR_RADIUS
	collar_mesh.height = 0.38
	collar_mesh.radial_segments = 16
	var collar := MeshInstance3D.new()
	collar.mesh = collar_mesh
	collar.material_override = rim_material
	collar.position.y = opening_y + (0.08 if is_upper else -0.08)
	add_child(collar)

	var inner_mesh := CylinderMesh.new()
	inner_mesh.top_radius = PIPE_RADIUS * 0.82
	inner_mesh.bottom_radius = PIPE_RADIUS * 0.82
	inner_mesh.height = 0.035
	inner_mesh.radial_segments = 16
	var inner := MeshInstance3D.new()
	inner.mesh = inner_mesh
	inner.material_override = inner_material
	inner.position.y = opening_y + (-0.115 if is_upper else 0.115)
	add_child(inner)


func _build_score_gate() -> void:
	var gate := Area3D.new()
	gate.name = "ScoreGate"
	gate.collision_layer = 4
	gate.collision_mask = 1
	gate.monitoring = true
	add_child(gate)
	# The gate trails a pipe moving toward +Z, so a point arrives after full clearance.
	_add_box_shape(gate, Vector3(1.5, maxf(_gap_size - 0.7, 0.5), 0.24), Vector3(0.0, _gap_center, -SCORE_GATE_TRAIL))
	gate.body_entered.connect(_on_score_gate_body_entered)


func _add_box_shape(area: Area3D, size: Vector3, local_position: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = local_position
	area.add_child(collision)


func _on_hazard_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		bird_hit.emit()


func _on_score_gate_body_entered(body: Node3D) -> void:
	if scored or not running:
		return
	if body.is_in_group("player"):
		scored = true
		point_scored.emit()


func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material
