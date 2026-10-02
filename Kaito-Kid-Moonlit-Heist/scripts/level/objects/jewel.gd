class_name Jewel
extends Node3D
## Brilliant-cut museum jewel, its vitrine, and the calling-card theft flourish.

signal stolen(jewel: Jewel)

var jewel_name: String = "Jewel"
var gem_color: Color = Color.WHITE
var is_stolen := false
var _gem: Node3D
var _case: Node3D
var _case_body: StaticBody3D
var _plaque: Label3D
var _glow: OmniLight3D
var _glints: Array[MeshInstance3D] = []
var _glint_normals: Array[Vector3] = []
var _time := 0.0
var _thief: PhantomThief


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
		_plaque.text = jewel_name.to_upper()
		_glow.light_color = gem_color


func minimap_icon() -> String:
	return "jewel"


func can_interact(_player: PhantomThief) -> bool:
	return not is_stolen


func interact(player: PhantomThief) -> void:
	_thief = player
	steal()


func get_prompt() -> String:
	return "[E] Steal the %s" % jewel_name


func interact_position() -> Vector3:
	return global_position + Vector3(0.0, 0.7, 0.0)


## Open the vitrine once and carry the stone into the thief's hand.
func steal() -> void:
	if is_stolen:
		return
	is_stolen = true
	_plaque.text = "Stolen by Kaito KID ✦"
	_case_body.collision_layer = 0
	_case_body.collision_mask = 0
	for glint in _glints:
		glint.visible = false
	var target := Vector3(0.0, 2.1, 0.0)
	if is_instance_valid(_thief):
		target = to_local(_thief.global_position + _thief.global_basis * Vector3(0.28, 1.35, -0.46))
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_case, "position:y", 2.05, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_case, "scale", Vector3(1.04, 0.93, 1.04), 0.55)
	tween.tween_property(_gem, "position", target, 0.46).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_gem, "scale", Vector3.ZERO, 0.25).set_delay(0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_glow, "light_energy", 0.0, 0.35)
	_flash_cards()
	stolen.emit(self)


func _process(delta: float) -> void:
	if is_stolen:
		return
	_time += delta
	_gem.rotation.y += delta * 0.35
	_gem.position.y = 1.58 + sin(_time * 1.35) * 0.025
	_glow.light_energy = 0.12 + sin(_time * 2.0) * 0.025
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	for i in _glints.size():
		var glint := _glints[i]
		var normal := _gem.global_basis * _glint_normals[i]
		var sight := (camera.global_position - glint.global_position).normalized()
		var sweep := maxf(0.0, normal.dot(sight))
		var flare := pow(sweep, 16.0) * (0.65 + 0.35 * sin(_time * 2.1 + float(i) * 2.4))
		glint.scale = Vector3.ONE * (0.15 + flare * 0.38)
		glint.transparency = 1.0 - flare * 0.82


func _build() -> void:
	var marble := KK.standard_material(Color(0.78, 0.81, 0.85), 0.21, 0.12)
	var brass := KK.standard_material(Color(0.63, 0.42, 0.14), 0.24, 0.82)
	var dark_brass := KK.standard_material(Color(0.25, 0.16, 0.065), 0.33, 0.72)
	_box(self, Vector3(1.36, 0.12, 1.36), Vector3(0, 0.06, 0), brass)
	_box(self, Vector3(1.21, 0.85, 1.21), Vector3(0, 0.53, 0), marble)
	_box(self, Vector3(1.39, 0.025, 1.39), Vector3(0, 0.91, 0), dark_brass)
	_box(self, Vector3(1.38, 0.09, 1.38), Vector3(0, 1.0, 0), brass)
	_box(self, Vector3(1.29, 0.07, 1.29), Vector3(0, 1.08, 0), marble)
	for y in [0.18, 0.84]:
		for side in [-1, 1]:
			_box(self, Vector3(1.23, 0.012, 0.012), Vector3(0, y, side * 0.613), dark_brass)
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
	_box(self, Vector3(0.87, 0.16, 0.023), Vector3(0, 0.77, 0.632), dark_brass)
	_box(self, Vector3(0.83, 0.13, 0.009), Vector3(0, 0.77, 0.649), brass)
	_plaque = Label3D.new()
	_plaque.text = jewel_name.to_upper()
	_plaque.font_size = 25
	_plaque.pixel_size = 0.0015
	_plaque.modulate = Color(0.09, 0.055, 0.018)
	_plaque.outline_size = 0
	_plaque.position = Vector3(0, 0.77, 0.655)
	add_child(_plaque)
	var velvet := KK.standard_material(Color(0.018, 0.035, 0.095), 0.94)
	_box(self, Vector3(1.04, 0.05, 1.04), Vector3(0, 1.155, 0), velvet)
	var cushion := CylinderMesh.new()
	cushion.top_radius = 0.37
	cushion.bottom_radius = 0.43
	cushion.height = 0.11
	cushion.radial_segments = 32
	var cushion_node := MeshInstance3D.new()
	cushion_node.mesh = cushion
	cushion_node.material_override = velvet
	cushion_node.position.y = 1.21
	add_child(cushion_node)
	for i in 12:
		var angle := TAU * float(i) / 12.0
		var pin := SphereMesh.new()
		pin.radius = 0.012
		pin.height = 0.024
		var stud := MeshInstance3D.new()
		stud.mesh = pin
		stud.material_override = brass
		stud.position = Vector3(cos(angle) * 0.42, 1.2, sin(angle) * 0.42)
		add_child(stud)
	_case = Node3D.new()
	_case.position.y = 1.13
	add_child(_case)
	var glass_shader := Shader.new()
	glass_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.0);
	vec3 reflection = texture(screen_texture, SCREEN_UV + NORMAL.xy * 0.004).rgb;
	ALBEDO = mix(vec3(0.48, 0.72, 0.83), reflection, 0.23 + rim * 0.42);
	METALLIC = 0.12;
	ROUGHNESS = 0.035;
	SPECULAR = 1.0;
	ALPHA = 0.045 + rim * 0.39;
}
"""
	var glass := ShaderMaterial.new()
	glass.shader = glass_shader
	for side in [-1, 1]:
		_box(_case, Vector3(1.07, 0.82, 0.012), Vector3(0, 0.41, side * 0.54), glass)
		_box(_case, Vector3(0.012, 0.82, 1.07), Vector3(side * 0.54, 0.41, 0), glass)
	_box(_case, Vector3(1.09, 0.012, 1.09), Vector3(0, 0.825, 0), glass)
	for x in [-0.54, 0.54]:
		for z in [-0.54, 0.54]:
			_box(_case, Vector3(0.018, 0.84, 0.018), Vector3(x, 0.41, z), brass)
	for y in [0.01, 0.825]:
		for side in [-1, 1]:
			_box(_case, Vector3(1.11, 0.018, 0.018), Vector3(0, y, side * 0.54), brass)
			_box(_case, Vector3(0.018, 0.018, 1.11), Vector3(side * 0.54, y, 0), brass)
	_case_body = StaticBody3D.new()
	_case_body.collision_layer = KK.LAYER_GLASS
	_case_body.collision_mask = 0
	add_child(_case_body)
	var case_shape := CollisionShape3D.new()
	var case_box := BoxShape3D.new()
	case_box.size = Vector3(1.1, 0.82, 1.1)
	case_shape.shape = case_box
	case_shape.position.y = 1.54
	_case_body.add_child(case_shape)
	_gem = Node3D.new()
	_gem.position.y = 1.58
	add_child(_gem)
	_rebuild_gem()
	_glow = OmniLight3D.new()
	_glow.position.y = 1.6
	_glow.omni_range = 1.8
	_glow.light_energy = 0.12
	_glow.light_color = gem_color
	_glow.shadow_enabled = false
	add_child(_glow)
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, 3.3, 0)
	spot.rotation_degrees.x = -90
	spot.spot_range = 3.1
	spot.spot_angle = 19.0
	spot.light_energy = 0.65
	spot.light_color = Color(0.8, 0.88, 1.0)
	spot.shadow_enabled = false
	spot.light_volumetric_fog_energy = 0.48
	add_child(spot)


func _rebuild_gem() -> void:
	for child in _gem.get_children():
		_gem.remove_child(child)
		child.queue_free()
	_glints.clear()
	_glint_normals.clear()
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, depth_draw_opaque;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 gem_tint : source_color = vec4(0.35, 0.7, 1.0, 1.0);
void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float facing = max(dot(n, v), 0.0);
	float rim = pow(1.0 - facing, 2.5);
	vec2 bend = n.xy * (0.008 + 0.008 * rim);
	float dispersion = 0.0035;
	float r = texture(screen_texture, SCREEN_UV + bend + vec2(dispersion, 0.0)).r;
	float g = texture(screen_texture, SCREEN_UV + bend).g;
	float b = texture(screen_texture, SCREEN_UV + bend - vec2(dispersion, 0.0)).b;
	vec3 refracted = vec3(r, g, b);
	float facet = COLOR.r;
	vec3 body = mix(gem_tint.rgb * (0.22 + facet * 0.52), refracted * gem_tint.rgb * 1.25, 0.37);
	float fire = pow(max(0.0, sin(dot(n, vec3(17.0, 31.0, 11.0)) + dot(v, vec3(8.0, 13.0, 21.0)) * 5.0)), 22.0);
	vec3 rainbow = vec3(0.95, 0.36, 0.65) * fire + vec3(0.26, 0.78, 1.0) * pow(max(0.0, sin(dot(n, vec3(23.0, 7.0, 19.0)) - v.x * 24.0)), 28.0);
	ALBEDO = body + rainbow * 0.38 + vec3(0.63, 0.76, 1.0) * rim * 0.64;
	METALLIC = 0.08;
	ROUGHNESS = 0.035;
	SPECULAR = 1.0;
	EMISSION = gem_tint.rgb * 0.018 + rainbow * 0.035;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("gem_tint", gem_color)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var table: Array[Vector3] = []
	var star: Array[Vector3] = []
	var crown: Array[Vector3] = []
	var girdle: Array[Vector3] = []
	var pavilion: Array[Vector3] = []
	for i in 8:
		var a := TAU * float(i) / 8.0
		table.append(_ring_point(a, 0.22, 0.23))
		star.append(_ring_point(a + PI / 8.0, 0.31, 0.15))
		crown.append(_ring_point(a, 0.46, 0.015))
		pavilion.append(_ring_point(a, 0.27, -0.25))
	for i in 16:
		girdle.append(_ring_point(TAU * float(i) / 16.0, 0.48, -0.055))
	# Standard round brilliant: 1 table, 8 stars, 8 bezels,
	# 16 upper girdle, 16 lower girdle, and 8 pavilion mains = 57.
	_facet(st, table, 0.9, true)
	for i in 8:
		var next := (i + 1) % 8
		var g0 := i * 2
		var g1 := (g0 + 1) % 16
		var g2 := (g0 + 2) % 16
		_facet(st, [table[i], table[next], star[i]], 0.75)
		_facet(st, [table[i], star[i], crown[i], star[(i + 7) % 8]], 0.44 + float(i % 4) * 0.1)
		_facet(st, [crown[i], star[i], girdle[g1], girdle[g0]], 0.67)
		_facet(st, [star[i], crown[next], girdle[g2], girdle[g1]], 0.44)
		_facet(st, [girdle[g0], girdle[g1], pavilion[i]], 0.31 + float(i % 3) * 0.1)
		_facet(st, [girdle[g1], girdle[g2], pavilion[i]], 0.48 + float(i % 4) * 0.1)
		_facet(st, [pavilion[i], girdle[g2], pavilion[next], Vector3(0, -0.43, 0)], 0.43 + float(i % 3) * 0.12)
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = material
	_gem.add_child(mesh)
	if DisplayServer.get_name() != "headless":
		_build_glints(girdle, star)


func _ring_point(a: float, radius: float, y: float) -> Vector3:
	return Vector3(cos(a) * radius, y, sin(a) * radius)


func _facet(st: SurfaceTool, points: Array[Vector3], shade: float, top := false) -> void:
	var vertices: Array[Vector3] = points.duplicate()
	var center := Vector3.ZERO
	for point in vertices:
		center += point
	center /= float(vertices.size())
	var normal := (vertices[1] - vertices[0]).cross(vertices[2] - vertices[0]).normalized()
	var outside := Vector3(center.x, 0.0, center.z)
	if top:
		outside = Vector3.UP
	elif center.y < -0.1:
		outside.y = -0.8
	else:
		outside.y = 0.28
	if normal.dot(outside) < 0.0:
		vertices.reverse()
		normal = -normal
	for i in range(1, vertices.size() - 1):
		for point in [vertices[0], vertices[i], vertices[i + 1]]:
			st.set_normal(normal)
			st.set_color(Color(shade, shade, shade))
			st.add_vertex(point)


func _build_glints(girdle: Array[Vector3], star: Array[Vector3]) -> void:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var dx := absf(float(x) - 31.5) / 31.5
			var dy := absf(float(y) - 31.5) / 31.5
			var core := exp(-35.0 * (dx * dx + dy * dy))
			var arms := exp(-80.0 * dx * dx - 4.0 * dy * dy) + exp(-80.0 * dy * dy - 4.0 * dx * dx)
			image.set_pixel(x, y, Color(1.0, 0.96, 0.79, minf(1.0, core + arms * 0.42)))
	var texture := ImageTexture.create_from_image(image)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = texture
	mat.no_depth_test = false
	for i in 5:
		var index := (i * 3) % 16
		var point := girdle[index]
		if i % 2 == 0:
			point = star[(i * 3) % 8]
		var quad := QuadMesh.new()
		quad.size = Vector2(0.34, 0.34)
		var glint := MeshInstance3D.new()
		glint.mesh = quad
		glint.material_override = mat
		glint.position = point * 1.06
		glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_gem.add_child(glint)
		_glints.append(glint)
		_glint_normals.append(Vector3(point.x, 0.45, point.z).normalized())


func _flash_cards() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var card_mat := KK.standard_material(Color(0.97, 0.95, 0.89), 0.55)
	var feather_mat := KK.standard_material(Color(0.95, 0.97, 1.0), 0.92)
	for i in 14:
		var piece := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.10, 0.15, 0.004) if i < 7 else Vector3(0.028, 0.16, 0.008)
		piece.mesh = mesh
		piece.material_override = card_mat if i < 7 else feather_mat
		piece.position = Vector3(0, 1.55, 0)
		add_child(piece)
		var a := TAU * float(i) / 14.0
		var destination := piece.position + Vector3(cos(a) * (0.8 + float(i % 3) * 0.14), 0.3 + float(i % 4) * 0.14, sin(a) * 0.8)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(piece, "position", destination, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(piece, "rotation", Vector3(a * 2.0, a, a * 1.5), 0.7)
		tw.tween_property(piece, "scale", Vector3.ZERO, 0.28).set_delay(0.42)
		tw.chain().tween_callback(piece.queue_free)


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node
