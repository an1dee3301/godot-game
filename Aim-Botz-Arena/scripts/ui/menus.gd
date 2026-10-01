class_name GameMenus
extends CanvasLayer
## Main menu, pause menu and end-of-round screen (Game Over / Mission Complete).

signal start_requested(practice: bool)
signal resume_requested
signal restart_requested
signal main_menu_requested
signal quit_requested
signal sensitivity_changed(value: float)

const ACCENT := Color(0.95, 0.62, 0.2)

var _main_menu: Control
var _pause_menu: Control
var _end_menu: Control
var _end_title: Label
var _end_stats: Label
var _best_label: Label
var _sensitivity_slider: HSlider
var _sensitivity_value: Label
var _theme: Theme


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_theme = _make_theme()
	_build_main_menu()
	_build_pause_menu()
	_build_end_menu()
	show_main_menu()


func show_main_menu() -> void:
	_main_menu.visible = true
	_pause_menu.visible = false
	_end_menu.visible = false


func show_pause() -> void:
	_main_menu.visible = false
	_pause_menu.visible = true
	_end_menu.visible = false


func show_end(victory: bool, stats: String) -> void:
	_main_menu.visible = false
	_pause_menu.visible = false
	_end_menu.visible = true
	_end_title.text = "MISSION COMPLETE" if victory else "GAME OVER"
	_end_title.add_theme_color_override("font_color", Color(0.45, 1.0, 0.5) if victory else Color(1.0, 0.3, 0.25))
	_end_stats.text = stats


func hide_all() -> void:
	_main_menu.visible = false
	_pause_menu.visible = false
	_end_menu.visible = false


func is_any_visible() -> bool:
	return _main_menu.visible or _pause_menu.visible or _end_menu.visible


func set_best_score(score: int) -> void:
	_best_label.text = "BEST MISSION SCORE: %d" % score if score > 0 else ""


func set_sensitivity(value: float) -> void:
	_sensitivity_slider.set_value_no_signal(value)
	_sensitivity_value.text = "%.2f" % value


func _on_sensitivity_slider_changed(value: float) -> void:
	_sensitivity_value.text = "%.2f" % value
	sensitivity_changed.emit(value)


# --- Builders ------------------------------------------------------------------

func _screen(dim: float) -> Control:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.theme = _theme
	add_child(screen)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.035, 0.045, dim)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(shade)
	return screen


func _build_main_menu() -> void:
	_main_menu = _screen(0.45)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_main_menu.add_child(column)
	column.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	column.offset_left = 80
	column.offset_top = -250
	column.offset_right = 520
	column.offset_bottom = 250

	_add_label(column, "AIM BOTZ", 64, ACCENT)
	_add_label(column, "ARENA", 40, Color.WHITE)
	_add_label(column, "First FPS Game - Version 2", 18, Color(0.8, 0.8, 0.8))
	column.add_child(_spacer(16))
	_add_button(column, "PLAY MISSION", func() -> void: start_requested.emit(false))
	_add_button(column, "AIM PRACTICE", func() -> void: start_requested.emit(true))
	var sensitivity_row := HBoxContainer.new()
	sensitivity_row.add_theme_constant_override("separation", 12)
	column.add_child(sensitivity_row)
	_add_label(sensitivity_row, "Mouse sensitivity", 18, Color.WHITE)
	_sensitivity_slider = HSlider.new()
	_sensitivity_slider.min_value = 0.2
	_sensitivity_slider.max_value = 3.0
	_sensitivity_slider.step = 0.05
	_sensitivity_slider.value = 1.0
	_sensitivity_slider.custom_minimum_size = Vector2(160, 24)
	_sensitivity_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sensitivity_row.add_child(_sensitivity_slider)
	_sensitivity_value = _add_label(sensitivity_row, "1.00", 18, ACCENT)
	_sensitivity_slider.value_changed.connect(_on_sensitivity_slider_changed)
	_add_button(column, "QUIT", func() -> void: quit_requested.emit())
	_best_label = _add_label(column, "", 18, Color(1.0, 0.9, 0.5))

	var help := PanelContainer.new()
	_main_menu.add_child(help)
	help.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	help.offset_left = -470
	help.offset_top = -250
	help.offset_right = -70
	help.offset_bottom = 250
	var help_text := Label.new()
	help_text.add_theme_font_size_override("font_size", 16)
	help_text.text = "\n".join([
		"MISSION",
		"Survive 3 waves of bots and eliminate them all.",
		"Heavy bots (red) are slower but tougher.",
		"",
		"PRACTICE",
		"Aim Botz drill: rows of static bots that respawn.",
		"Press B to make them strafe. No damage taken.",
		"",
		"CONTROLS",
		"WASD  move        Mouse  look",
		"Space  jump        Shift  sprint",
		"LMB  shoot         RMB  aim down sights",
		"R  reload           1 / 2 / wheel  switch weapon",
		"E  open doors     Esc  pause",
		"",
		"TIPS",
		"Headshots deal 4x damage. Shoot red barrels!",
		"Health and ammo crates respawn after 25 s.",
	])
	help.add_child(help_text)


func _build_pause_menu() -> void:
	_pause_menu = _screen(0.6)
	var column := _centered_column(_pause_menu)
	_add_label(column, "PAUSED", 52, ACCENT).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_button(column, "RESUME", func() -> void: resume_requested.emit())
	_add_button(column, "RESTART", func() -> void: restart_requested.emit())
	_add_button(column, "MAIN MENU", func() -> void: main_menu_requested.emit())


func _build_end_menu() -> void:
	_end_menu = _screen(0.6)
	var column := _centered_column(_end_menu)
	_end_title = _add_label(column, "GAME OVER", 56, Color.WHITE)
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_stats = _add_label(column, "", 20, Color.WHITE)
	_end_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_button(column, "RESTART", func() -> void: restart_requested.emit())
	_add_button(column, "MAIN MENU", func() -> void: main_menu_requested.emit())


func _centered_column(parent: Control) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(column)
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.offset_left = -240
	column.offset_top = -240
	column.offset_right = 240
	column.offset_bottom = 240
	return column


func _add_label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 52)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer


func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 20
	var normal := _style(Color(0.1, 0.11, 0.13, 0.92), Color(0.3, 0.32, 0.36))
	var hover := _style(Color(0.95, 0.62, 0.2, 0.95), ACCENT)
	var pressed := _style(Color(0.75, 0.45, 0.12, 1.0), ACCENT)
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", Color.WHITE)
	theme.set_color("font_hover_color", "Button", Color(0.08, 0.08, 0.08))
	theme.set_color("font_pressed_color", "Button", Color(0.05, 0.05, 0.05))
	theme.set_font_size("font_size", "Button", 22)
	theme.set_stylebox("panel", "PanelContainer", _style(Color(0.06, 0.07, 0.08, 0.85), Color(0.3, 0.32, 0.36), 18))
	return theme


func _style(background: Color, border: Color, margin := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin * 0.6
	style.content_margin_bottom = margin * 0.6
	return style
