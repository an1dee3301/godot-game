class_name HeistMenus
extends CanvasLayer
## Full-screen title, pause, defeat, and victory screens.

signal start_requested
signal resume_requested
signal restart_requested
signal menu_requested
signal quit_requested
signal settings_changed(values: Dictionary)

var settings := {"mouse_sensitivity": 1.0, "master_volume": 1.0, "music_volume": 1.0, "sfx_volume": 1.0, "invert_y": false, "fullscreen": false}
var _current := ""
var _canvas: HeistMenuCanvas
var _buttons: Array[Button] = []
var _theme: Theme
var _title_row: HBoxContainer
var _settings_controls: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_theme = _build_theme()
	_canvas = HeistMenuCanvas.new()
	_canvas.name = "MenuArtwork"
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.theme = _theme
	_canvas.visible = false
	add_child(_canvas)
	_canvas.resized.connect(_layout_buttons)


## Show one of title, pause, game_over, or win, with optional run statistics.
func show_screen(screen: String, data: Dictionary = {}) -> void:
	if _canvas == null:
		_ready()
	_current = screen
	_canvas.screen = screen
	_canvas.data = data
	_canvas.visible = true
	_canvas.modulate.a = 0.0
	_canvas.queue_redraw()
	_rebuild_buttons()
	create_tween().tween_property(_canvas, "modulate:a", 1.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if not _buttons.is_empty():
		_buttons[0].call_deferred("grab_focus")


## Hide every menu and release keyboard focus.
func hide_all() -> void:
	_current = ""
	if _canvas != null:
		_canvas.visible = false
		for button in _buttons:
			button.release_focus()


## Whether a named screen is currently open.
func is_showing(screen: String) -> bool:
	return _current == screen


## Name of the active screen, or an empty string.
func current_screen() -> String:
	return _current


## Apply saved options before opening the settings screen.
func set_settings(values: Dictionary) -> void:
	for key in settings:
		if values.has(key):
			settings[key] = values[key]


func _input(event: InputEvent) -> void:
	if _current == "" or not event.is_pressed():
		return
	if event.is_action_pressed("confirm"):
		if _current == "title":
			start_requested.emit()
		elif _current == "game_over" or _current == "win":
			restart_requested.emit()
		elif _current == "pause":
			resume_requested.emit()
		elif _current == "settings":
			show_screen("pause")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and _current in ["game_over", "win"]:
		restart_requested.emit()
		get_viewport().set_input_as_handled()


func _rebuild_buttons() -> void:
	if _settings_controls != null:
		_settings_controls.queue_free()
		_settings_controls = null
	if _title_row != null:
		_title_row.queue_free()
		_title_row = null
	else:
		for button in _buttons:
			button.queue_free()
	_buttons.clear()
	var choices: Array[String] = []
	match _current:
		"title": choices = ["START  ↵", "QUIT"]
		"pause": choices = ["RESUME", "SETTINGS", "RESTART", "MAIN MENU", "QUIT"]
		"settings": choices = ["BACK"]
		"game_over": choices = ["RETRY  ↵ / R", "MAIN MENU"]
		"win": choices = ["PLAY AGAIN", "MAIN MENU"]
	var button_parent: Control = _canvas
	if _current == "title":
		_title_row = HBoxContainer.new()
		_title_row.name = "TitleActionsRow"
		_title_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_title_row.add_theme_constant_override("separation", 75)
		_canvas.add_child(_title_row)
		var left_space := Control.new()
		left_space.custom_minimum_size.x = 315
		_title_row.add_child(left_space)
		var column := VBoxContainer.new()
		column.name = "Actions"
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.custom_minimum_size.x = 270
		column.add_theme_constant_override("separation", 10)
		_title_row.add_child(column)
		var right_space := Control.new()
		right_space.custom_minimum_size.x = 315
		_title_row.add_child(right_space)
		button_parent = column
	for i in range(choices.size()):
		var button := Button.new()
		button.text = choices[i]
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.theme = _theme
		button.name = "Action%d" % i
		button_parent.add_child(button)
		_buttons.append(button)
		button.pressed.connect(_activate.bind(i))
	if _current == "settings":
		_build_settings()
	_layout_buttons()


func _build_settings() -> void:
	_settings_controls = VBoxContainer.new()
	_settings_controls.name = "SettingsControls"
	_settings_controls.add_theme_constant_override("separation", 9)
	_canvas.add_child(_settings_controls)
	for entry in [["mouse_sensitivity", "MOUSE SENSITIVITY", 0.25, 2.5], ["master_volume", "MASTER VOLUME", 0.0, 1.0], ["music_volume", "MUSIC VOLUME", 0.0, 1.0], ["sfx_volume", "SFX VOLUME", 0.0, 1.0]]:
		var row := HBoxContainer.new()
		_settings_controls.add_child(row)
		var label := Label.new()
		label.text = entry[1]
		label.custom_minimum_size.x = 180
		label.add_theme_color_override("font_color", Color("0b1230"))
		row.add_child(label)
		var slider := HSlider.new()
		slider.custom_minimum_size.x = 185
		slider.min_value = entry[2]
		slider.max_value = entry[3]
		slider.step = 0.05
		slider.value = float(settings[entry[0]])
		row.add_child(slider)
		slider.value_changed.connect(_on_setting_changed.bind(String(entry[0])))
	for entry in [["invert_y", "INVERT CAMERA Y"], ["fullscreen", "FULLSCREEN"]]:
		var toggle := CheckBox.new()
		toggle.text = entry[1]
		toggle.button_pressed = bool(settings[entry[0]])
		toggle.add_theme_color_override("font_color", Color("0b1230"))
		_settings_controls.add_child(toggle)
		toggle.toggled.connect(_on_setting_changed.bind(String(entry[0])))


func _on_setting_changed(value: Variant, key: String) -> void:
	settings[key] = value
	settings_changed.emit(settings.duplicate())


func _layout_buttons() -> void:
	if _canvas == null:
		return
	var scale_ui := minf(_canvas.size.x / 1600.0, _canvas.size.y / 900.0)
	var center := _canvas.size * 0.5
	var x := center.x
	var y := center.y
	var width := 268.0 * scale_ui
	var height := 48.0 * scale_ui
	var gap := 10.0 * scale_ui
	if _current == "title":
		if _title_row != null:
			_title_row.position = Vector2(center.x - 525.0 * scale_ui, center.y + 141.0 * scale_ui)
			_title_row.size = Vector2(1050.0, 238.0) * scale_ui
			_title_row.add_theme_constant_override("separation", roundi(75.0 * scale_ui))
			var left_space: Control = _title_row.get_child(0)
			var column: VBoxContainer = _title_row.get_child(1)
			var right_space: Control = _title_row.get_child(2)
			left_space.custom_minimum_size.x = 315.0 * scale_ui
			column.custom_minimum_size.x = 270.0 * scale_ui
			right_space.custom_minimum_size.x = 315.0 * scale_ui
			column.add_theme_constant_override("separation", roundi(10.0 * scale_ui))
	elif _current == "pause":
		y = center.y + 20.0 * scale_ui
	elif _current == "settings":
		y = center.y + 218.0 * scale_ui
		if _settings_controls != null:
			_settings_controls.position = Vector2(center.x - 185.0 * scale_ui, center.y - 120.0 * scale_ui)
			_settings_controls.scale = Vector2.ONE * scale_ui
	elif _current == "game_over" or _current == "win":
		y = center.y + 190.0 * scale_ui
	for i in range(_buttons.size()):
		var button := _buttons[i]
		if _current == "title":
			button.custom_minimum_size = Vector2(width, height)
		else:
			button.position = Vector2(x - width * 0.5, y + float(i) * (height + gap))
			button.size = Vector2(width, height)
		button.add_theme_font_size_override("font_size", maxi(14, roundi(18.0 * scale_ui)))


func _activate(index: int) -> void:
	match _current:
		"title":
			if index == 0: start_requested.emit()
			else: quit_requested.emit()
		"pause":
			match index:
				0: resume_requested.emit()
				1: show_screen("settings")
				2: restart_requested.emit()
				3: menu_requested.emit()
				4: quit_requested.emit()
		"settings":
			show_screen("pause")
		"game_over", "win":
			if index == 0: restart_requested.emit()
			else: menu_requested.emit()


func _build_theme() -> Theme:
	var result := Theme.new()
	var sans := SystemFont.new()
	sans.font_names = PackedStringArray(["Avenir Next", "Arial", "sans-serif"])
	result.default_font = sans
	result.default_font_size = 18
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("f5f1e5") if state == "normal" else (Color("d4af37") if state in ["hover", "focus"] else Color("e6d28c"))
		box.border_color = Color("d4af37") if state == "normal" else Color("fff7de")
		box.set_border_width_all(2)
		box.set_corner_radius_all(5)
		box.content_margin_left = 18
		box.content_margin_right = 18
		result.set_stylebox(state, "Button", box)
	result.set_color("font_color", "Button", Color("0b1230"))
	result.set_color("font_hover_color", "Button", Color("0b1230"))
	result.set_color("font_pressed_color", "Button", Color("0b1230"))
	result.set_color("font_focus_color", "Button", Color("0b1230"))
	return result
