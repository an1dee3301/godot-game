class_name Jewel
extends Node3D
## A glass-cased brilliant-cut jewel on a marble display plinth.

signal stolen(jewel: Jewel)

var jewel_name: String = "Jewel"
var gem_color: Color = Color.WHITE
var is_stolen := false
var _gem: Node3D
var _case: Node3D
var _case_body: StaticBody3D
var _plaque: Label3D
var _glow: OmniLight3D
var _time := 0.0


func _ready() -> void:
	add_to_group(KK.GROUP_JEWELS)
	add_to_group(KK.GROUP_INTERACTABLE)
	add_to_group(KK.GROUP_MINIMAP)
	_build()


## Configure the display name and gem tint.
func setup(display_name: String, color: Color) -> void:
	jewel_name = display_name
	gem_color = color
	if is_inside_tree():
		_rebuild_gem()
		_plaque.text = jewel_name


func minimap_icon() -> String:
	return "jewel"


func can_interact(_player: PhantomThief) -> bool:
	return not is_stolen


func interact(_player: PhantomThief) -> void:
	steal()


func get_prompt() -> String:
	return "[E] Steal the %s" % jewel_name


func interact_position() -> Vector3:
	return global_position + Vector3(0.0, 0.7, 0.0)


## Remove the jewel once, with a short glass-and-calling-card flourish.
func steal() -> void:
	if is_stolen:
		return
	is_stolen = true
	_plaque.text = "STOLEN — Kaito Kid  ♠"
	_case_body.collision_layer = 0
	_case_body.collision_mask = 0
	if is_inside_tree():
		var tween := create_tween().set_parallel(true)
		tween.tween_property(_case, "position:y", 2.1, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_case, "scale", Vector3(1.15, 0.1, 1.15), 0.55)
		tween.tween_property(_gem, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(_glow, "light_energy", 0.0, 0.35)
		_flash_cards()
	stolen.emit(self)


func _process(delta: float) -> void:
	if is_stolen:
		return
	_time += delta
	_gem.rotation.y += delta * 0.55
	_gem.position.y = 1.62 + sin(_time * 1.7) * 0.035
	_glow.light_energy = 0.20 + sin(_time * 2.5) * 0.035


func _build() -> void:
	var marble := KK.standard_material(Color(0.80, 0.83, 0.86), 0.24, 0.08)
	var brass := KK.standard_material(Color(0.64, 0.43, 0.16), 0.25, 0.82)
	_box(self, Vector3(1.35, 0.12, 1.35), Vector3(0, 0.06, 0), brass)
	_box(self, Vector3(1.22, 0.85, 1.22), Vector3(0, 0.53, 0), marble)
	_box(self, Vector3(1.38, 0.10, 1.38), Vector3(0, 1.0, 0), brass)
	_box(self, Vector3(1.30, 0.08, 1.30), Vector3(0, 1.09, 0), marble)
	var body := StaticBody3D.new()
	body.collision_layer = KK.LAYER_WORLD
	body.collision_mask = 0
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.3, 1.12, 1.3)
	shape.shape = box
	shape.position.y = 0.56
	body.add_child(shape)
	_plaque = Label3D.new()
	_plaque.text = jewel_name
	_plaque.font_size = 28
	_plaque.pixel_size = 0.0017
	_plaque.modulate = Color(0.14, 0.10, 0.045)
	_plaque.outline_size = 0
	_plaque.position = Vector3(0, 0.78, 0.645)
	add_child(_plaque)
	_box(self, Vector3(0.80, 0.15, 0.018), Vector3(0, 0.78, 0.621), brass)
	_box(self, Vector3(0.75, 0.11, 0.009), Vector3(0, 0.78, 0.634), KK.standard_material(Color(0.82, 0.67, 0.38), 0.34, 0.55))
	for x in [-0.36, 0.36]:
		_box(self, Vector3(0.012, 0.012, 0.012), Vector3(x, 0.78, 0.644), marble)
	_case = Node3D.new()
	add_child(_case)
	_case.position.y = 1.13
	var glass_shader := Shader.new()
	glass_shader.code = "shader_type spatial; render_mode blend_mix, depth_draw_never, cull_disabled; void fragment() { float edge = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.2); ALBEDO = vec3(0.43, 0.68, 0.79); METALLIC = 0.05; ROUGHNESS = 0.09; SPECULAR = 0.9; ALPHA = 0.035 + edge * 0.27; }"
	var glass := ShaderMaterial.new()
	glass.shader = glass_shader
	for side in [-1, 1]:
		_box(_case, Vector3(1.07, 0.8, 0.016), Vector3(0, 0.4, side * 0.54), glass)
		_box(_case, Vector3(0.016, 0.8, 1.07), Vector3(side * 0.54, 0.4, 0), glass)
	_box(_case, Vector3(1.09, 0.016, 1.09), Vector3(0, 0.81, 0), glass)
	for x in [-0.54, 0.54]:
		for z in [-0.54, 0.54]:
			_box(_case, Vector3(0.026, 0.82, 0.026), Vector3(x, 0.4, z), brass)
	for y in [0.015, 0.805]:
		for side in [-1, 1]:
			_box(_case, Vector3(1.10, 0.022, 0.022), Vector3(0, y, side * 0.54), brass)
			_box(_case, Vector3(0.022, 0.022, 1.10), Vector3(side * 0.54, y, 0), brass)
	var velvet := KK.standard_material(Color(0.025, 0.075, 0.16), 0.91)
	_box(self, Vector3(0.99, 0.065, 0.99), Vector3(0, 1.17, 0), velvet)
	var cushion := CylinderMesh.new()
	cushion.top_radius = 0.38
	cushion.bottom_radius = 0.43
	cushion.height = 0.09
	cushion.radial_segments = 24
	var cushion_node := MeshInstance3D.new()
	cushion_node.mesh = cushion
	cushion_node.material_override = velvet
	cushion_node.position.y = 1.19
	add_child(cushion_node)
	_case_body = StaticBody3D.new()
	_case_body.collision_layer = KK.LAYER_GLASS
	_case_body.collision_mask = 0
	add_child(_case_body)
	var case_shape := CollisionShape3D.new()
	var case_box := BoxShape3D.new()
	case_box.size = Vector3(1.1, 0.8, 1.1)
	case_shape.shape = case_box
	case_shape.position.y = 1.53
	_case_body.add_child(case_shape)
	_gem = Node3D.new()
	add_child(_gem)
	_rebuild_gem()
	_glow = OmniLight3D.new()
	_glow.position.y = 1.60
	_glow.omni_range = 2.2
	_glow.light_energy = 0.20
	_glow.shadow_enabled = false
	add_child(_glow)
	_glow.light_color = gem_color
	if DisplayServer.get_name() != "headless":
		var sparkle := GPUParticles3D.new()
		sparkle.amount = 14
		sparkle.lifetime = 1.3
		sparkle.preprocess = 1.3
		sparkle.position.y = 1.53
		sparkle.explosiveness = 0.0
		var process := ParticleProcessMaterial.new()
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		process.emission_sphere_radius = 0.42
		process.gravity = Vector3.ZERO
		process.initial_velocity_min = 0.02
		process.initial_velocity_max = 0.08
		process.scale_min = 0.012
		process.scale_max = 0.025
		process.color = gem_color.lightened(0.45)
		sparkle.process_material = process
		var mote := SphereMesh.new()
		mote.radius = 0.015
		mote.height = 0.03
		mote.radial_segments = 6
		mote.rings = 3
		sparkle.draw_pass_1 = mote
		add_child(sparkle)
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, 3.8, 0)
	spot.rotation_degrees.x = -90
	spot.spot_range = 4.2
	spot.spot_angle = 24.0
	spot.light_energy = 0.25
	spot.light_color = Color(0.8, 0.89, 1.0)
	spot.shadow_enabled = false
	add_child(spot)


func _rebuild_gem() -> void:
	for child in _gem.get_children():
		child.queue_free()
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode cull_disabled; uniform vec4 gem_tint : source_color = vec4(0.4,0.8,1.0,1.0); void fragment() { float fresnel = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.6); vec3 facet = mix(gem_tint.rgb * 0.27, gem_tint.rgb * 1.45, COLOR.r); ALBEDO = mix(facet, vec3(0.72, 0.87, 1.0), fresnel * 0.23); METALLIC = 0.12; ROUGHNESS = 0.045; SPECULAR = 0.95; EMISSION = gem_tint.rgb * (0.018 + fresnel * 0.045); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("gem_tint", gem_color)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 16
	var table_radius := 0.20
	var crown_radius := 0.42
	var girdle_radius := 0.47
	var table_y := 0.24
	var crown_y := 0.015
	var girdle_y := -0.075
	var culet := Vector3(0, -0.42, 0)
	for i in n:
		var a: float = TAU * float(i) / n
		var b: float = TAU * float(i + 1) / n
		var mid: float = (a + b) * 0.5
		var t1 := Vector3(cos(a) * table_radius, table_y, sin(a) * table_radius)
		var t2 := Vector3(cos(b) * table_radius, table_y, sin(b) * table_radius)
		var c1 := Vector3(cos(a) * crown_radius, crown_y, sin(a) * crown_radius)
		var c2 := Vector3(cos(b) * crown_radius, crown_y, sin(b) * crown_radius)
		var gm := Vector3(cos(mid) * girdle_radius, girdle_y, sin(mid) * girdle_radius)
		var g1 := Vector3(cos(a) * girdle_radius, girdle_y, sin(a) * girdle_radius)
		var g2 := Vector3(cos(b) * girdle_radius, girdle_y, sin(b) * girdle_radius)
		_facet(st, Vector3(0, table_y, 0), t2, t1, 0.66)
		_facet(st, t1, t2, c1, 0.35 + float(i % 5) * 0.13)
		_facet(st, t2, c2, c1, 0.45 + float((i + 2) % 5) * 0.11)
		_facet(st, c1, c2, gm, 0.40 + float((i + 3) % 4) * 0.15)
		_facet(st, c1, gm, g1, 0.70)
		_facet(st, c2, g2, gm, 0.55)
		_facet(st, culet, g1, gm, 0.28 + float((i + 1) % 5) * 0.16)
		_facet(st, culet, gm, g2, 0.38 + float((i + 3) % 5) * 0.13)
	var gem_mesh := MeshInstance3D.new()
	gem_mesh.mesh = st.commit()
	gem_mesh.material_override = material
	_gem.add_child(gem_mesh)
	var heart := SphereMesh.new()
	heart.radius = 0.19
	heart.height = 0.38
	heart.radial_segments = 12
	heart.rings = 6
	var heart_mat := KK.standard_material(gem_color.darkened(0.25), 0.18)
	heart_mat.emission_enabled = true
	heart_mat.emission = gem_color
	heart_mat.emission_energy_multiplier = 0.10
	var heart_node := MeshInstance3D.new()
	heart_node.mesh = heart
	heart_node.material_override = heart_mat
	heart_node.position.y = -0.06
	_gem.add_child(heart_node)
	for i in 3:
		var glint := _box(_gem, Vector3(0.05, 0.012, 0.012), Vector3(cos(float(i) * 2.1) * 0.38, 0.04 + float(i) * 0.06, sin(float(i) * 2.1) * 0.38), KK.standard_material(Color(0.82, 0.93, 1.0), 0.08, 0.22))
		glint.rotation.z = deg_to_rad(35.0)


func _facet(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, shade: float) -> void:
	var normal := (b - a).cross(c - a).normalized()
	for vertex in [a, b, c]:
		st.set_normal(normal)
		st.set_color(Color(shade, shade, shade))
		st.add_vertex(vertex)


func _flash_cards() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var pink := KK.standard_material(Color(1.0, 0.5, 0.82), 0.3)
	pink.emission_enabled = true
	pink.emission = Color(1.0, 0.22, 0.58)
	pink.emission_energy_multiplier = 1.5
	for i in 8:
		var card := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.10, 0.15, 0.006)
		card.mesh = mesh
		card.material_override = pink
		card.position = Vector3(0, 1.55, 0)
		add_child(card)
		var angle := TAU * float(i) / 8.0
		var dest := card.position + Vector3(cos(angle) * 0.95, 0.55 + sin(angle * 3.0) * 0.3, sin(angle) * 0.95)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(card, "position", dest, 0.5)
		tw.tween_property(card, "rotation", Vector3(angle, angle * 2.0, angle), 0.5)
		tw.tween_property(card, "scale", Vector3.ZERO, 0.5)
		tw.chain().tween_callback(card.queue_free)
	var smoke := StandardMaterial3D.new()
	smoke.albedo_color = Color(1.0, 0.43, 0.76, 0.32)
	smoke.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 6:
		var puff := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		puff.mesh = sphere
		puff.material_override = smoke
		puff.position = Vector3(0, 1.45, 0)
		add_child(puff)
		var angle := TAU * float(i) / 6.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(puff, "position", puff.position + Vector3(cos(angle) * 0.65, 0.55, sin(angle) * 0.65), 0.65)
		tw.tween_property(puff, "scale", Vector3(2.2, 1.7, 2.2), 0.65)
		tw.chain().tween_callback(puff.queue_free)


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node
