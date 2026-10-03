class_name RunnerHUD
extends CanvasLayer
## Airport departure-board HUD.

const YELLOW := Color("e0b46a")   ## Brass accent.
const DARK := Color(0.11, 0.098, 0.085, 0.8)   ## Warm charcoal glass.
const WHITE := Color("f3ead9")   ## Cream text.
const CYAN := Color("b4c79c")   ## Sage.
const RED := Color("df7a5f")   ## Clay.

static var _hud_font: SystemFont

var _root: Control
var _score: Label
var _distance: Label
var _level: Label
var _tags: Label
var _destination: SplitFlapLabel
var flap_sound: Callable
var _destination_panel: PanelContainer
var _weight_bar: ProgressBar
var _weight_hint: Label
var _shield: PanelContainer
var _boost: PanelContainer
var _boost_bar: ProgressBar
var _boost_label: Label
var _speed: Label
var _flash: Label
var _controls: Label
var _hint_time := 0.0
var _flash_tween: Tween
var _score_tween: Tween
var _tag_tween: Tween
var _shield_tween: Tween
var _edge_tween: Tween
var _shown_score := 0
var _target_score := 0
var _last_score := -1
var _last_tags := 0
var _multiplier := 1.0
var _boost_active := false
var _shield_active := false
var _weight_stripes: ColorRect
var _weight_heavy := false
var _edge: ColorRect
var _popup_layer: Control
var _boost_flame: ColorRect


func _ready() -> void:
	layer = 5
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_edge = ColorRect.new()
	_edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var edge_shader := Shader.new()
	edge_shader.code = "shader_type canvas_item; uniform vec4 tint : source_color = vec4(1.0, 0.2, 0.12, 0.0); void fragment() { vec2 p = UV * 2.0 - 1.0; float edge = smoothstep(0.48, 1.28, length(p * vec2(0.85, 1.0))); COLOR = vec4(tint.rgb, tint.a * edge); }"
	var edge_material := ShaderMaterial.new()
	edge_material.shader = edge_shader
	_edge.material = edge_material
	_root.add_child(_edge)
	_popup_layer = Control.new()
	_popup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_popup_layer)

	var left := VBoxContainer.new()
	left.position = Vector2(22, 20)
	left.add_theme_constant_override("separation", 8)
	_root.add_child(left)
	var score_panel := _panel()
	left.add_child(score_panel)
	var score_box := VBoxContainer.new()
	score_panel.add_child(score_box)
	score_box.add_child(_label("SCORE  /  RUN TOTAL", 14, YELLOW))
	_score = _label("000000", 37, WHITE)
	score_box.add_child(_score)
	_distance = _label("DISTANCE  0 m", 17, WHITE)
	score_box.add_child(_distance)
	_level = _label("LEVEL  01", 15, YELLOW)
	score_box.add_child(_level)

	var tag_panel := _panel()
	left.add_child(tag_panel)
	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 10)
	tag_panel.add_child(tag_row)
	var tag_icon := _tag_icon()
	tag_row.add_child(tag_icon)
	_tags = _label("LUGGAGE TAGS  0", 18, WHITE)
	tag_row.add_child(_tags)

	var weight_panel := _panel()
	left.add_child(weight_panel)
	var weight_box := VBoxContainer.new()
	weight_panel.add_child(weight_box)
	weight_box.add_child(_label("BAG WEIGHT", 14, YELLOW))
	_weight_bar = ProgressBar.new()
	_weight_bar.custom_minimum_size = Vector2(226, 16)
	_weight_bar.max_value = 1.0
	_weight_bar.show_percentage = false
	_weight_bar.add_theme_stylebox_override("background", _style(Color(1, 1, 1, 0.12), 3))
	_weight_bar.add_theme_stylebox_override("fill", _style(Color("9db47f"), 3))
	weight_box.add_child(_weight_bar)
	_weight_stripes = ColorRect.new()
	_weight_stripes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_weight_stripes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stripe_shader := Shader.new()
	stripe_shader.code = "shader_type canvas_item; void fragment() { float band = step(0.55, fract((UV.x + UV.y * 0.55) * 13.0 - TIME * 1.7)); COLOR = vec4(1.0, 0.95, 0.78, band * 0.24); }"
	var stripe_material := ShaderMaterial.new()
	stripe_material.shader = stripe_shader
	_weight_stripes.material = stripe_material
	_weight_bar.add_child(_weight_stripes)
	_weight_stripes.visible = false
	_weight_hint = _label("CHECKPOINT CLEARS WEIGHT", 11, YELLOW)
	_weight_hint.visible = false
	weight_box.add_child(_weight_hint)

	var right := VBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.position = Vector2(-22, 20)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.add_theme_constant_override("separation", 8)
	_root.add_child(right)
	_destination_panel = _panel()
	right.add_child(_destination_panel)
	var destination_box := VBoxContainer.new()
	_destination_panel.add_child(destination_box)
	destination_box.add_child(_label("BOARDING  /  ROUTE GATE", 12, YELLOW))
	_destination = SplitFlapLabel.new()
	_destination.columns = 16
	_destination.cell_size = Vector2(16, 29)
	_destination.font_size = 19
	_destination.flap_sound = func() -> void:
		if flap_sound.is_valid():
			flap_sound.call()
	destination_box.add_child(_destination)
	_destination.set_text("DESTINATION: LAX", false)
	var flap_rule := ColorRect.new()
	flap_rule.color = Color(0.88, 0.71, 0.42, 0.45)
	flap_rule.custom_minimum_size = Vector2(0, 2)
	destination_box.add_child(flap_rule)
	_speed = _label("BELT SPEED  0 m/s  ·  0 km/h", 14, WHITE)
	right.add_child(_speed)
	_shield = _panel(Color(0.12, 0.13, 0.12, 0.8), YELLOW)
	right.add_child(_shield)
	_shield.add_child(_label("◆  FRAGILE  /  ONE FREE HIT", 15, YELLOW))
	_shield.visible = false
	_boost = _panel(Color(0.18, 0.13, 0.08, 0.8), YELLOW)
	right.add_child(_boost)
	var boost_box := VBoxContainer.new()
	_boost.add_child(boost_box)
	_boost_label = _label("PRIORITY  x2  ·  6.0 s", 15, YELLOW)
	boost_box.add_child(_boost_label)
	_boost_bar = ProgressBar.new()
	_boost_bar.max_value = 1.0
	_boost_bar.custom_minimum_size = Vector2(220, 12)
	_boost_bar.show_percentage = false
	_boost_bar.add_theme_stylebox_override("background", _style(Color(1, 1, 1, 0.12), 3))
	var fire_fill := _style(Color("e0a25a"), 3)
	_boost_bar.add_theme_stylebox_override("fill", fire_fill)
	boost_box.add_child(_boost_bar)
	_boost_flame = ColorRect.new()
	_boost_flame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boost_flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var flame_shader := Shader.new()
	flame_shader.code = "shader_type canvas_item; uniform float fraction = 1.0; void fragment() { float within = step(UV.x, fraction); vec3 fire = mix(vec3(1.0, 0.28, 0.11), vec3(1.0, 0.9, 0.25), UV.x); float shimmer = 0.84 + 0.16 * sin(UV.x * 45.0 - TIME * 12.0); COLOR = vec4(fire * shimmer, within * 0.86); }"
	var flame_material := ShaderMaterial.new()
	flame_material.shader = flame_shader
	_boost_flame.material = flame_material
	_boost_bar.add_child(_boost_flame)
	_boost.visible = false

	_flash = _label("", 43, WHITE)
	_flash.set_anchors_preset(Control.PRESET_CENTER)
	_flash.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_flash.grow_vertical = Control.GROW_DIRECTION_BOTH
	_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_flash.add_theme_color_override("font_outline_color", DARK)
	_flash.add_theme_constant_override("outline_size", 9)
	_flash.visible = false
	_root.add_child(_flash)

	_controls = _label("A/D or ←/→ switch belt  ·  W/Space jump  ·  S/↓ flatten  ·  Esc pause", 15, WHITE)
	_controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_controls.position = Vector2(0, -25)
	_controls.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls.add_theme_color_override("font_outline_color", DARK)
	_controls.add_theme_constant_override("outline_size", 6)
	_root.add_child(_controls)
	show_hud(false)


func _process(delta: float) -> void:
	if _weight_heavy:
		_weight_hint.modulate.a = 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.012)
	if _shown_score != _target_score:
		_shown_score = mini(_target_score, _shown_score + maxi(1, ceili((_target_score - _shown_score) * minf(delta * 12.0, 1.0))))
		_render_score()
	if _hint_time > 0.0:
		_hint_time -= delta
		if _hint_time <= 0.0:
			_controls.visible = false


func show_hud(on: bool) -> void:
	if _root == null:
		return
	_root.visible = on
	if on:
		_hint_time = 8.0
		_controls.visible = true
	else:
		_hint_time = 0.0
		_last_score = -1
		_shown_score = 0
		_target_score = 0
		_last_tags = 0
		_boost_active = false
		_shield_active = false


func update_stats(score: int, distance: float, tags: int, multiplier: float, speed: float, level: int) -> void:
	if _root == null:
		return
	if _last_score >= 0 and score - _last_score >= 10:
		popup_points(score - _last_score, YELLOW if multiplier > 1.0 else CYAN)
		_score.pivot_offset = _score.size * 0.5
		if _score_tween != null:
			_score_tween.kill()
		_score.scale = Vector2(1.17, 1.17)
		_score_tween = create_tween()
		_score_tween.tween_property(_score, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_last_score = score
	_target_score = maxi(score, 0)
	_multiplier = multiplier
	_render_score()
	_distance.text = "DISTANCE  %d m" % roundi(distance)
	_level.text = "LEVEL  %02d" % level
	if tags != _last_tags:
		_tags.pivot_offset = _tags.size * 0.5
		if _tag_tween != null:
			_tag_tween.kill()
		_tags.scale = Vector2(1.2, 1.2)
		_tag_tween = create_tween()
		_tag_tween.tween_property(_tags, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_last_tags = tags
	_tags.text = "LUGGAGE TAGS  %d" % tags
	_speed.text = "BELT SPEED  %.1f m/s  ·  %d km/h" % [speed, roundi(speed * 3.6)]
	_speed.add_theme_color_override("font_color", CYAN.lerp(YELLOW, clampf((speed - 12.0) / 30.0, 0.0, 1.0)))


func _render_score() -> void:
	_score.text = "%06d" % _shown_score
	if _multiplier > 1.0:
		_score.text += "  x%d" % roundi(_multiplier)


func popup_points(amount: int, color: Color) -> void:
	if _popup_layer == null or not _root.visible or amount <= 0:
		return
	var popup := _label("+%d" % amount, 27, color)
	popup.position = Vector2(160, 89)
	popup.add_theme_constant_override("outline_size", 6)
	_popup_layer.add_child(popup)
	var motion := create_tween().set_parallel(true)
	motion.tween_property(popup, "position:y", popup.position.y - 60.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(popup, "modulate:a", 0.0, 0.7).set_delay(0.18)
	motion.chain().tween_callback(popup.queue_free)


func set_destination(code: String) -> void:
	if _destination == null:
		return
	_destination.set_text("DESTINATION: " + code)


func set_weight(weight: float) -> void:
	if _weight_bar == null:
		return
	var amount := clampf(weight, 0.0, 1.0)
	_weight_bar.value = amount
	_weight_hint.visible = amount > 0.5
	_weight_stripes.visible = amount > 0.58
	_weight_heavy = amount > 0.77
	if amount > 0.77:
		_weight_hint.text = "⚠  HEAVY BAG — SLOWER BELT SPEED"
		_weight_hint.add_theme_color_override("font_color", RED)
	else:
		_weight_hint.text = "CHECKPOINT CLEARS WEIGHT"
		_weight_hint.add_theme_color_override("font_color", YELLOW)
		_weight_hint.modulate.a = 1.0
	_weight_bar.add_theme_stylebox_override("fill", _style(Color("9db47f").lerp(Color("df7a5f"), amount), 3))


func set_shield(active: bool) -> void:
	if _shield != null:
		_shield.visible = active
		if active and not _shield_active:
			_shield.pivot_offset = _shield.size * 0.5
			if _shield_tween != null:
				_shield_tween.kill()
			_shield.rotation = -0.15
			_shield_tween = create_tween()
			_shield_tween.tween_property(_shield, "rotation", 0.0, 0.65).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		elif not active and _shield_active:
			_flash_edges(RED)
		_shield_active = active


func set_boost(time_left: float, duration: float) -> void:
	if _boost == null:
		return
	_boost.visible = time_left > 0.0
	_boost_bar.value = clampf(time_left / maxf(duration, 0.01), 0.0, 1.0)
	(_boost_flame.material as ShaderMaterial).set_shader_parameter("fraction", _boost_bar.value)
	_boost_label.text = "PRIORITY  x2  ·  %.1f s" % maxf(time_left, 0.0)
	var active := time_left > 0.0
	if active and not _boost_active:
		_flash_edges(YELLOW)
	_boost_active = active


func _flash_edges(color: Color) -> void:
	if _edge == null:
		return
	if _edge_tween != null:
		_edge_tween.kill()
	var material := _edge.material as ShaderMaterial
	material.set_shader_parameter("tint", Color(color.r, color.g, color.b, 0.82))
	_edge_tween = create_tween()
	_edge_tween.tween_method(func(alpha: float) -> void:
		material.set_shader_parameter("tint", Color(color.r, color.g, color.b, alpha)), 0.82, 0.0, 0.65)


func flash_message(message: String, color: Color = Color.WHITE) -> void:
	if _flash == null:
		return
	if _flash_tween != null:
		_flash_tween.kill()
	_flash.text = message
	_flash.add_theme_color_override("font_color", color)
	_flash.visible = true
	_flash.modulate.a = 1.0
	_flash.scale = Vector2(0.65, 0.65)
	_flash.pivot_offset = _flash.size * 0.5
	_flash_tween = create_tween()
	if message.begins_with("LEVEL"):
		_flash.position.y = -75.0
		_flash_tween.tween_property(_flash, "position:y", 0.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(_flash, "scale", Vector2(1.12, 1.12), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(_flash, "scale", Vector2.ONE, 0.12)
	_flash_tween.tween_interval(0.55)
	_flash_tween.tween_property(_flash, "modulate:a", 0.0, 0.45)
	_flash_tween.tween_callback(func() -> void: _flash.visible = false)


func _panel(background: Color = DARK, border: Color = YELLOW) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _style(background, 6)
	style.set_border_width_all(1)
	style.border_color = Color(border, 0.5)
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _style(fill: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	return style


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", _font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.05, 0.6))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Same typeface as the menus, with CJK/Vietnamese fallback.
static func _font() -> Font:
	if _hud_font == null:
		var base := SystemFont.new()
		base.font_names = PackedStringArray(["Avenir Next", "Segoe UI", "Helvetica Neue", "Noto Sans"])
		base.font_weight = 500
		base.fallbacks = [Signage.font()]
		_hud_font = base
	return _hud_font


func _tag_icon() -> Control:
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(29, 27)
	var shape := Polygon2D.new()
	shape.polygon = PackedVector2Array([Vector2(2, 2), Vector2(20, 2), Vector2(28, 13), Vector2(20, 25), Vector2(2, 25)])
	shape.color = YELLOW
	icon.add_child(shape)
	var hole := ColorRect.new()
	hole.color = DARK
	hole.position = Vector2(20, 11)
	hole.size = Vector2(4, 4)
	icon.add_child(hole)
	return icon
