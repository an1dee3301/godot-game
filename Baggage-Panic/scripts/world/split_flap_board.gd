class_name SplitFlapBoard
extends Node3D
## Single-sided, instanced Solari cells. Local +Z is the viewing side.

signal settled

const DRUM := " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:.-/"
const ATLAS_COLUMNS := 8
const GLYPH_WIDTH := 64
const GLYPH_HEIGHT := 88
const FLIP_SECONDS := 0.065
const MAX_ACTIVE := 18

static var _atlas_viewport: SubViewport
static var _material: ShaderMaterial
static var _quad: QuadMesh
static var _back_material: StandardMaterial3D
static var _clack: AudioStreamWAV

var animate := true
var _columns := 0
var _rows := 0
var _cell_size := Vector2.ONE
var _current: Array[int] = []
var _target: Array[int] = []
var _timers: Array[float] = []
var _delays: Array[float] = []
var _colors: Array[Color] = []
var _static: MultiMesh
var _front: MultiMesh
var _rear: MultiMesh
var _audio: AudioStreamPlayer3D
var _sound_cooldown := 0.0
var _was_active := false
var _had_pending := false


func setup(columns: int, rows: int, cell_size: Vector2) -> void:
	_columns = maxi(columns, 1)
	_rows = maxi(rows, 1)
	_cell_size = cell_size
	_ensure_resources()
	var count := _columns * _rows
	_current.resize(count)
	_target.resize(count)
	_timers.resize(count)
	_delays.resize(count)
	_colors.resize(count)
	for i in count:
		_current[i] = 0
		_target[i] = 0
		_timers[i] = -1.0
		_delays[i] = 0.0
		_colors[i] = Color.WHITE
	_static = _make_multimesh(count * 2)
	_front = _make_multimesh(count)
	_rear = _make_multimesh(count)
	_add_instances(_static, "Cards")
	_add_instances(_front, "FrontFlaps")
	_add_instances(_rear, "BackFlaps")
	var panel := MeshInstance3D.new()
	var back := BoxMesh.new()
	back.size = Vector3(_columns * cell_size.x + 0.045, _rows * cell_size.y + 0.045, 0.055)
	panel.mesh = back
	panel.material_override = _back_material
	panel.position.z = -0.055
	add_child(panel)
	for i in count:
		_draw_cell(i)
	if DisplayServer.get_name() != "headless":
		_audio = AudioStreamPlayer3D.new()
		_audio.stream = _clack
		_audio.max_polyphony = 6
		_audio.volume_db = -28.0
		_audio.max_distance = 30.0
		add_child(_audio)
	set_process(true)


func set_row(row: int, value: String, color: Color = Color.WHITE) -> void:
	_set_row(row, value, color, false)


func set_text_immediate(row: int, value: String, color: Color = Color.WHITE) -> void:
	_set_row(row, value, color, true)


func _set_row(row: int, value: String, color: Color, immediate: bool) -> void:
	if row < 0 or row >= _rows:
		return
	var upper := value.to_upper()
	for column in _columns:
		var index := row * _columns + column
		var character := upper.substr(column, 1) if column < upper.length() else " "
		var glyph := DRUM.find(character)
		_target[index] = maxi(glyph, 0)
		_colors[index] = color
		if immediate or not animate:
			_current[index] = _target[index]
			_timers[index] = -1.0
		else:
			_delays[index] = randf_range(0.0, 0.28)
		_draw_cell(index)


func _process(delta: float) -> void:
	if _static == null:
		return
	var camera := get_viewport().get_camera_3d()
	var near := camera != null and global_position.distance_squared_to(camera.global_position) < 4900.0 and is_visible_in_tree() and not camera.is_position_behind(global_position)
	if not near:
		if _was_active:
			for i in _current.size():
				if _current[i] != _target[i]:
					_current[i] = _target[i]
					_timers[i] = -1.0
					_draw_cell(i)
		_was_active = false
		return
	_was_active = true
	_sound_cooldown = maxf(0.0, _sound_cooldown - delta)
	var active := 0
	var pending := false
	for i in _current.size():
		if _current[i] == _target[i] and _timers[i] < 0.0:
			continue
		pending = true
		if _timers[i] >= 0.0:
			active += 1
			_timers[i] += delta
			if _timers[i] >= FLIP_SECONDS:
				_current[i] = (_current[i] + 1) % DRUM.length()
				_timers[i] = -1.0
				_draw_cell(i)
			else:
				_draw_flap(i)
		elif active < MAX_ACTIVE:
			_delays[i] -= delta
			if _delays[i] <= 0.0:
				_timers[i] = 0.0
				active += 1
				_draw_cell(i)
	if not pending and _had_pending:
		settled.emit()
	_had_pending = pending


func _draw_cell(index: int) -> void:
	var current := _current[index]
	var flipping := _timers[index] >= 0.0
	var next := (current + 1) % DRUM.length()
	var x := (float(index % _columns) - float(_columns - 1) * 0.5) * _cell_size.x
	var y := (float(_rows - 1) * 0.5 - float(index / _columns)) * _cell_size.y
	var half_height := _cell_size.y * 0.49
	var width := _cell_size.x * 0.975
	var top_position := Vector3(x, y + _cell_size.y * 0.25, 0.003)
	var bottom_position := Vector3(x, y - _cell_size.y * 0.25, 0.003)
	_static.set_instance_transform(index * 2, Transform3D(Basis.from_scale(Vector3(width, half_height, 1.0)), top_position))
	_static.set_instance_transform(index * 2 + 1, Transform3D(Basis.from_scale(Vector3(width, half_height, 1.0)), bottom_position))
	_static.set_instance_custom_data(index * 2, Color(float(next if flipping else current), 0.0, 0.0, 0.0))
	_static.set_instance_custom_data(index * 2 + 1, Color(float(current), 1.0, 0.0, 0.0))
	_static.set_instance_color(index * 2, _colors[index])
	_static.set_instance_color(index * 2 + 1, _colors[index])
	_draw_flap(index)


func _draw_flap(index: int) -> void:
	if _timers[index] < 0.0:
		_front.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
		_rear.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
		return
	var x := (float(index % _columns) - float(_columns - 1) * 0.5) * _cell_size.x
	var y := (float(_rows - 1) * 0.5 - float(index / _columns)) * _cell_size.y
	var angle := PI * clampf(_timers[index] / FLIP_SECONDS, 0.0, 1.0)
	var rotation := Basis(Vector3.RIGHT, angle)
	var offset := rotation * Vector3(0.0, _cell_size.y * 0.25, 0.0)
	var scale_basis := Basis.from_scale(Vector3(_cell_size.x * 0.975, _cell_size.y * 0.49, 1.0))
	var hinge := Vector3(x, y, 0.016) + offset
	_front.set_instance_transform(index, Transform3D(rotation * scale_basis, hinge))
	_rear.set_instance_transform(index, Transform3D(rotation * Basis(Vector3.RIGHT, PI) * scale_basis, hinge - Vector3(0.0, 0.0, 0.002)))
	_front.set_instance_custom_data(index, Color(float(_current[index]), 0.0, 0.0, 0.0))
	_rear.set_instance_custom_data(index, Color(float((_current[index] + 1) % DRUM.length()), 1.0, 1.0, 0.0))
	_front.set_instance_color(index, _colors[index])
	_rear.set_instance_color(index, _colors[index])
	if _sound_cooldown <= 0.0 and _audio != null and _timers[index] == 0.0:
		_audio.play()
		_sound_cooldown = 0.025


func _make_multimesh(count: int) -> MultiMesh:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.use_custom_data = true
	multi.mesh = _quad
	multi.instance_count = count
	return multi


func _add_instances(multi: MultiMesh, caption: String) -> void:
	var node := MultiMeshInstance3D.new()
	node.name = caption
	node.multimesh = multi
	node.material_override = _material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)


func _ensure_resources() -> void:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2.ONE
	if _back_material == null:
		_back_material = StandardMaterial3D.new()
		_back_material.albedo_color = Color("101215")
	if _atlas_viewport == null or not is_instance_valid(_atlas_viewport):
		_atlas_viewport = SubViewport.new()
		_atlas_viewport.name = "SplitFlapGlyphAtlas"
		_atlas_viewport.size = Vector2i(ATLAS_COLUMNS * GLYPH_WIDTH, 6 * GLYPH_HEIGHT)
		_atlas_viewport.transparent_bg = true
		_atlas_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		# Deferred: boards are often built while the main scene is still entering the tree.
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_atlas_viewport)
		var canvas := Control.new()
		_atlas_viewport.add_child(canvas)
		for i in DRUM.length():
			var glyph := Label.new()
			glyph.position = Vector2(float(i % ATLAS_COLUMNS) * GLYPH_WIDTH, float(i / ATLAS_COLUMNS) * GLYPH_HEIGHT)
			glyph.size = Vector2(GLYPH_WIDTH, GLYPH_HEIGHT)
			glyph.text = DRUM.substr(i, 1)
			glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			var style := LabelSettings.new()
			style.font = ThemeDB.fallback_font
			style.font_size = 59
			style.font_color = Color.WHITE
			style.outline_size = 1
			style.outline_color = Color.WHITE
			glyph.label_settings = style
			canvas.add_child(glyph)
	if _material == null:
		var shader := Shader.new()
		shader.code = "shader_type spatial; render_mode unshaded, cull_back, depth_draw_opaque; uniform sampler2D atlas : source_color, filter_linear; varying vec4 glyph_data; varying vec4 tint; void vertex() { glyph_data = INSTANCE_CUSTOM; tint = COLOR; } void fragment() { float glyph = glyph_data.r; float column = mod(glyph, 8.0); float row = floor(glyph / 8.0); vec2 uv = UV; uv = (vec2(column, row) + vec2(uv.x, (glyph_data.g + uv.y) * 0.5)) / vec2(8.0, 6.0); vec4 ink = texture(atlas, uv); vec3 card = vec3(0.106, 0.114, 0.125); ALBEDO = mix(card, tint.rgb, ink.a); ROUGHNESS = 0.94; }"
		_material = ShaderMaterial.new()
		_material.shader = shader
		_material.set_shader_parameter("atlas", _atlas_viewport.get_texture())
	if _clack == null:
		var samples := PackedByteArray()
		samples.resize(720 * 2)
		var rng := RandomNumberGenerator.new()
		rng.seed = 57721
		for i in 720:
			var envelope := pow(1.0 - float(i) / 720.0, 3.0)
			var click := 0.34 if i < 22 else 0.0
			var value := int(clampf((rng.randf_range(-1.0, 1.0) * 0.24 + click) * envelope, -1.0, 1.0) * 32767.0)
			samples.encode_s16(i * 2, value)
		_clack = AudioStreamWAV.new()
		_clack.format = AudioStreamWAV.FORMAT_16_BITS
		_clack.mix_rate = 24000
		_clack.stereo = false
		_clack.data = samples
