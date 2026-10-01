extends CanvasLayer

const CYAN := Color(0.38, 0.95, 1.0)
const ORANGE := Color(1.0, 0.59, 0.36)
const WHITE := Color(0.9, 0.97, 1.0)
const MUTED := Color(0.53, 0.66, 0.75)

var root: Control
var top_bar: ColorRect
var score_label: Label
var wave_label: Label
var lives_label: Label
var combo_label: Label
var banner_label: Label
var overlay_scrim: ColorRect
var menu_panel: PanelContainer
var eyebrow_label: Label
var title_label: Label
var subtitle_label: Label
var detail_label: Label
var controls_label: Label
var prompt_label: Label
var pause_scrim: ColorRect
var pause_panel: PanelContainer
var banner_time := 0.0
var banner_duration := 0.0
var pulse_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()


func _build_interface() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	top_bar = ColorRect.new()
	top_bar.color = Color(0.015, 0.035, 0.07, 0.74)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 78.0
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_bar)

	var top_line := ColorRect.new()
	top_line.color = Color(0.25, 0.9, 1.0, 0.16)
	top_line.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	top_line.offset_top = -1.0
	top_bar.add_child(top_line)

	score_label = _new_label(19, WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	score_label.position = Vector2(28, 17)
	score_label.size = Vector2(270, 52)
	top_bar.add_child(score_label)

	wave_label = _new_label(20, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	wave_label.anchor_left = 0.5
	wave_label.anchor_right = 0.5
	wave_label.offset_left = -130.0
	wave_label.offset_right = 130.0
	wave_label.offset_top = 17.0
	wave_label.offset_bottom = 60.0
	top_bar.add_child(wave_label)

	lives_label = _new_label(18, ORANGE, HORIZONTAL_ALIGNMENT_RIGHT)
	lives_label.anchor_left = 1.0
	lives_label.anchor_right = 1.0
	lives_label.offset_left = -300.0
	lives_label.offset_right = -28.0
	lives_label.offset_top = 17.0
	lives_label.offset_bottom = 60.0
	top_bar.add_child(lives_label)

	combo_label = _new_label(17, ORANGE, HORIZONTAL_ALIGNMENT_CENTER)
	combo_label.anchor_left = 0.5
	combo_label.anchor_right = 0.5
	combo_label.offset_left = -100.0
	combo_label.offset_right = 100.0
	combo_label.offset_top = 78.0
	combo_label.offset_bottom = 110.0
	combo_label.visible = false
	root.add_child(combo_label)

	banner_label = _new_label(34, WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	banner_label.anchor_left = 0.5
	banner_label.anchor_right = 0.5
	banner_label.anchor_top = 0.26
	banner_label.anchor_bottom = 0.26
	banner_label.offset_left = -420.0
	banner_label.offset_right = 420.0
	banner_label.offset_top = -30.0
	banner_label.offset_bottom = 30.0
	banner_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.7, 0.8, 0.45))
	banner_label.add_theme_constant_override("shadow_offset_x", 3)
	banner_label.add_theme_constant_override("shadow_offset_y", 3)
	banner_label.visible = false
	root.add_child(banner_label)

	_build_menu_overlay()
	_build_pause_overlay()


func _build_menu_overlay() -> void:
	overlay_scrim = ColorRect.new()
	overlay_scrim.color = Color(0.0, 0.01, 0.035, 0.58)
	overlay_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay_scrim)

	menu_panel = PanelContainer.new()
	menu_panel.anchor_left = 0.5
	menu_panel.anchor_right = 0.5
	menu_panel.anchor_top = 0.5
	menu_panel.anchor_bottom = 0.5
	menu_panel.offset_left = -365.0
	menu_panel.offset_right = 365.0
	menu_panel.offset_top = -245.0
	menu_panel.offset_bottom = 245.0
	menu_panel.add_theme_stylebox_override("panel", _panel_style())
	overlay_scrim.add_child(menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 46)
	margin.add_theme_constant_override("margin_right", 46)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	menu_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(content)

	eyebrow_label = _new_label(15, ORANGE, HORIZONTAL_ALIGNMENT_CENTER)
	eyebrow_label.text = "DEEP-SPACE INTERCEPT PROGRAM"
	content.add_child(eyebrow_label)

	title_label = _new_label(58, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.text = "NEON DRIFT"
	title_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.8, 1.0, 0.35))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	content.add_child(title_label)

	subtitle_label = _new_label(21, WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle_label.text = "ASTEROID RUN"
	content.add_child(subtitle_label)

	detail_label = _new_label(17, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	detail_label.text = "Break the field. Chain the hits. Survive the drift."
	content.add_child(detail_label)

	var divider := ColorRect.new()
	divider.color = Color(0.3, 0.85, 0.95, 0.22)
	divider.custom_minimum_size = Vector2(0, 1)
	content.add_child(divider)

	controls_label = _new_label(17, Color(0.68, 0.79, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
	controls_label.text = "STEER   A / D  or  ← / →\nTHRUST   W  or  ↑\nFIRE   SPACE\nPAUSE   P  or  ESC"
	controls_label.custom_minimum_size.y = 112.0
	content.add_child(controls_label)

	prompt_label = _new_label(20, WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	prompt_label.text = "PRESS ENTER OR SPACE TO LAUNCH"
	content.add_child(prompt_label)


func _build_pause_overlay() -> void:
	pause_scrim = ColorRect.new()
	pause_scrim.color = Color(0.0, 0.01, 0.035, 0.7)
	pause_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_scrim.visible = false
	root.add_child(pause_scrim)

	pause_panel = PanelContainer.new()
	pause_panel.anchor_left = 0.5
	pause_panel.anchor_right = 0.5
	pause_panel.anchor_top = 0.5
	pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -240.0
	pause_panel.offset_right = 240.0
	pause_panel.offset_top = -95.0
	pause_panel.offset_bottom = 95.0
	pause_panel.add_theme_stylebox_override("panel", _panel_style())
	pause_scrim.add_child(pause_panel)

	var pause_text := _new_label(25, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	pause_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_text.text = "FLIGHT PAUSED\n\nP / ESC  TO RESUME"
	pause_panel.add_child(pause_text)


func _new_label(font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var new_label := Label.new()
	new_label.add_theme_font_size_override("font_size", font_size)
	new_label.add_theme_color_override("font_color", color)
	new_label.horizontal_alignment = alignment
	new_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return new_label


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.04, 0.085, 0.94)
	style.border_color = Color(0.25, 0.88, 0.95, 0.48)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0.0, 0.5, 0.7, 0.2)
	style.shadow_size = 18
	return style


func show_title(best_score: int) -> void:
	top_bar.visible = false
	combo_label.visible = false
	overlay_scrim.visible = true
	pause_scrim.visible = false
	eyebrow_label.text = "DEEP-SPACE INTERCEPT PROGRAM"
	title_label.text = "NEON DRIFT"
	title_label.add_theme_font_size_override("font_size", 58)
	subtitle_label.text = "ASTEROID RUN"
	detail_label.text = "Break the field. Chain the hits. Survive the drift.\nBEST SCORE  %08d" % best_score
	controls_label.visible = true
	prompt_label.text = "PRESS ENTER OR SPACE TO LAUNCH"
	prompt_label.visible = true


func show_gameplay() -> void:
	top_bar.visible = true
	overlay_scrim.visible = false
	pause_scrim.visible = false


func show_game_over(score: int, best_score: int, wave: int) -> void:
	top_bar.visible = true
	combo_label.visible = false
	overlay_scrim.visible = true
	pause_scrim.visible = false
	eyebrow_label.text = "TRANSMISSION LOST"
	title_label.text = "GAME OVER"
	title_label.add_theme_font_size_override("font_size", 52)
	subtitle_label.text = "FINAL SCORE  %08d" % score
	detail_label.text = "BEST  %08d    •    WAVE  %02d" % [best_score, wave]
	controls_label.visible = false
	prompt_label.text = "PRESS R, ENTER, OR SPACE TO RESTART"
	prompt_label.visible = true


func set_paused(is_paused: bool) -> void:
	pause_scrim.visible = is_paused


func update_hud(score: int, best_score: int, wave: int, lives: int, combo: int) -> void:
	score_label.text = "SCORE  %08d\nBEST   %08d" % [score, best_score]
	wave_label.text = "WAVE  %02d" % wave
	var ship_icons := ""
	for i in range(lives):
		ship_icons += "△  "
	lives_label.text = "SHIPS  " + ship_icons
	combo_label.visible = combo > 1 and not overlay_scrim.visible
	combo_label.text = "CHAIN  x%d" % combo


func show_banner(message: String, color: Color = WHITE, duration: float = 1.45) -> void:
	banner_label.text = message
	banner_label.add_theme_color_override("font_color", color)
	banner_label.modulate = Color.WHITE
	banner_label.scale = Vector2(0.92, 0.92)
	banner_label.pivot_offset = banner_label.size * 0.5
	banner_label.visible = true
	banner_duration = duration
	banner_time = duration


func _process(delta: float) -> void:
	pulse_time += delta
	if is_instance_valid(prompt_label) and prompt_label.visible:
		prompt_label.modulate.a = 0.58 + 0.42 * (0.5 + 0.5 * sin(pulse_time * 3.8))

	if banner_time > 0.0:
		banner_time = maxf(banner_time - delta, 0.0)
		var progress := 1.0 - banner_time / maxf(banner_duration, 0.001)
		banner_label.scale = Vector2.ONE * lerpf(0.92, 1.0, minf(progress * 4.0, 1.0))
		if banner_time < 0.35:
			banner_label.modulate.a = banner_time / 0.35
		if banner_time <= 0.0:
			banner_label.visible = false
