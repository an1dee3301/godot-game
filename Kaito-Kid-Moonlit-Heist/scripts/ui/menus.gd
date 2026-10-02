class_name HeistMenus
extends CanvasLayer
## Live-scene title and outcome menus with keyboard, gamepad, and mouse access.

signal start_requested
signal resume_requested
signal restart_requested
signal menu_requested
signal quit_requested
signal settings_changed(values: Dictionary)

var settings := {"mouse_sensitivity": 1.0, "master_volume": 1.0, "music_volume": 1.0, "sfx_volume": 1.0, "invert_y": false, "fullscreen": false}
var _current := ""
var _settings_return := "title"
var _canvas: HeistMenuCanvas
var _buttons: Array[Button] = []
var _widgets: Array[Control] = []
var _settings_focus: Array[Control] = []
var _theme: Theme
var _reveal_tween: Tween
var _transition: ColorRect
var _transitioning := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_theme = _build_theme()
	_canvas = HeistMenuCanvas.new()
	_canvas.name = "MenuArtwork"
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.theme = _theme
	_canvas.visible = false
	add_child(_canvas)
	_canvas.resized.connect(_layout)
	_transition = ColorRect.new()
	_transition.name = "SceneTransition"
	_transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition.color = Color(0.008, 0.014, 0.033)
	_transition.modulate.a = 0.0
	_transition.visible = false
	_transition.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_transition)
	var card := VBoxContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_theme_constant_override("separation", 17)
	_transition.add_child(card)
	for line in ["THE MOONLIGHT MUSEUM", "23:58"]:
		var label := Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", _canvas.title_font() if line == "THE MOONLIGHT MUSEUM" else _theme.default_font)
		label.add_theme_font_size_override("font_size", 34 if line == "THE MOONLIGHT MUSEUM" else 15)
		label.add_theme_color_override("font_color", HeistMenuCanvas.IVORY if line == "THE MOONLIGHT MUSEUM" else HeistMenuCanvas.GOLD)
		card.add_child(label)
	_transition.resized.connect(func() -> void:
		card.position = (_transition.size - card.get_combined_minimum_size()) * 0.5)


## Open a menu screen with optional run statistics.
func show_screen(screen: String, data: Dictionary = {}) -> void:
	if _canvas == null:
		_ready()
	if screen == "settings":
		_settings_return = "pause" if _current == "pause" else "title"
	_current = screen
	_canvas.screen = screen
	_canvas.data = data
	_canvas.selected = 0
	_canvas.reveal = 0.0
	_canvas.modulate.a = 0.0
	_canvas.visible = true
	_rebuild()
	if _reveal_tween != null and _reveal_tween.is_running():
		_reveal_tween.kill()
	_reveal_tween = create_tween()
	_reveal_tween.tween_property(_canvas, "reveal", 1.0, 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_reveal_tween.parallel().tween_property(_canvas, "modulate:a", 1.0, 0.34).set_trans(Tween.TRANS_SINE)
	if screen == "settings" and not _settings_focus.is_empty():
		_settings_focus[0].call_deferred("grab_focus")
	elif not _buttons.is_empty():
		_buttons[0].call_deferred("grab_focus")
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Close all menus and release their keyboard focus.
func hide_all() -> void:
	_current = ""
	if _canvas != null:
		_canvas.visible = false
		for button in _buttons:
			button.release_focus()


## Whether a named screen is currently open.
func is_showing(screen: String) -> bool:
	return _current == screen


## Name of the active screen, or empty when playing.
func current_screen() -> String:
	return _current


## Set options loaded from disk without emitting changes.
func set_settings(values: Dictionary) -> void:
	for key in settings:
		if values.has(key):
			settings[key] = values[key]


func _input(event: InputEvent) -> void:
	if _current == "" or _transitioning or not event.is_pressed():
		return
	if event.is_action_pressed("confirm"):
		if _current == "settings":
			var focused := get_viewport().gui_get_focus_owner()
			if focused is CheckBox:
				focused.button_pressed = not focused.button_pressed
			elif focused is Button:
				_activate(0)
		else:
			_activate(_canvas.selected)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and _current in ["game_over", "win"]:
		restart_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and _current in ["how_to_play", "settings"]:
		show_screen(_settings_return if _current == "settings" else "title")
		get_viewport().set_input_as_handled()


func _rebuild() -> void:
	for widget in _widgets:
		widget.queue_free()
	_widgets.clear()
	_buttons.clear()
	_settings_focus.clear()
	var choices: Array[String] = []
	match _current:
		"title": choices = ["START HEIST", "HOW TO PLAY", "SETTINGS", "QUIT"]
		"how_to_play": choices = ["START HEIST", "BACK"]
		"settings": choices = ["BACK"]
		"pause": choices = ["RESUME", "SETTINGS", "RESTART", "MAIN MENU", "QUIT"]
		"game_over": choices = ["TRY AGAIN", "MAIN MENU"]
		"win": choices = ["PLAY AGAIN", "MAIN MENU"]
	_canvas.choices = choices
	for i in choices.size():
		var button := Button.new()
		button.name = "Action%d" % i
		button.text = ""
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_canvas.add_child(button)
		_widgets.append(button)
		_buttons.append(button)
		button.pressed.connect(_activate.bind(i))
		button.focus_entered.connect(_select.bind(i))
		button.mouse_entered.connect(_select.bind(i))
	if _current == "settings":
		_build_settings()
		_settings_focus.append(_buttons[0])
		for i in _settings_focus.size():
			var control := _settings_focus[i]
			control.focus_neighbor_top = control.get_path_to(_settings_focus[(i - 1 + _settings_focus.size()) % _settings_focus.size()])
			control.focus_neighbor_bottom = control.get_path_to(_settings_focus[(i + 1) % _settings_focus.size()])
	_layout()


func _select(index: int) -> void:
	_canvas.selected = index
	_canvas.queue_redraw()


func _build_settings() -> void:
	var sliders := [
		["mouse_sensitivity", "MOUSE SENSITIVITY", 0.25, 2.5, 344.0],
		["master_volume", "MASTER", 0.0, 1.0, 475.0],
		["music_volume", "MUSIC", 0.0, 1.0, 522.0],
		["sfx_volume", "SFX", 0.0, 1.0, 569.0]
	]
	for entry in sliders:
		var label := Label.new()
		label.text = entry[1]
		label.add_theme_color_override("font_color", HeistMenuCanvas.MUTED)
		label.add_theme_font_size_override("font_size", 16)
		_canvas.add_child(label)
		_widgets.append(label)
		label.set_meta("design_pos", Vector2(114, float(entry[4])))
		var slider := HSlider.new()
		slider.name = String(entry[0])
		slider.focus_mode = Control.FOCUS_ALL
		slider.min_value = float(entry[2])
		slider.max_value = float(entry[3])
		slider.step = 0.05
		slider.value = float(settings[entry[0]])
		_canvas.add_child(slider)
		_widgets.append(slider)
		_settings_focus.append(slider)
		slider.set_meta("design_pos", Vector2(360, float(entry[4]) - 4.0))
		slider.set_meta("design_size", Vector2(350, 25))
		slider.value_changed.connect(_on_setting_changed.bind(String(entry[0])))
	for entry in [["invert_y", "INVERT Y", 390.0], ["fullscreen", "FULLSCREEN", 678.0]]:
		var toggle := CheckBox.new()
		toggle.text = entry[1]
		toggle.focus_mode = Control.FOCUS_ALL
		toggle.button_pressed = bool(settings[entry[0]])
		toggle.add_theme_color_override("font_color", HeistMenuCanvas.IVORY)
		toggle.add_theme_font_size_override("font_size", 16)
		_canvas.add_child(toggle)
		_widgets.append(toggle)
		_settings_focus.append(toggle)
		toggle.set_meta("design_pos", Vector2(114, float(entry[2])))
		toggle.set_meta("design_size", Vector2(280, 32))
		toggle.toggled.connect(_on_setting_changed.bind(String(entry[0])))


func _on_setting_changed(value: Variant, key: String) -> void:
	settings[key] = value
	settings_changed.emit(settings.duplicate())


func _layout() -> void:
	if _canvas == null:
		return
	var s := _canvas.ui_scale()
	var left := maxf(82.0, (_canvas.size.x / s - 1600.0) * 0.5 + 114.0)
	for i in _buttons.size():
		_buttons[i].position = Vector2(left - 22.0, _canvas.menu_y() + float(i) * 47.0 - 2.0) * s
		_buttons[i].size = Vector2(380.0, 45.0) * s
	if _current == "settings":
		for widget in _widgets:
			if not widget.has_meta("design_pos"):
				continue
			var pos: Vector2 = widget.get_meta("design_pos")
			widget.position = Vector2(left + pos.x - 114.0, pos.y) * s
			if widget.has_meta("design_size"):
				var dimensions: Vector2 = widget.get_meta("design_size")
				widget.size = dimensions * s


func _activate(index: int) -> void:
	if _transitioning:
		return
	match _current:
		"title":
			match index:
				0: _begin_start()
				1: show_screen("how_to_play")
				2: show_screen("settings")
				3: quit_requested.emit()
		"how_to_play":
			if index == 0: _begin_start()
			else: show_screen("title")
		"settings": show_screen(_settings_return)
		"pause":
			match index:
				0: resume_requested.emit()
				1: show_screen("settings")
				2: restart_requested.emit()
				3: menu_requested.emit()
				4: quit_requested.emit()
		"game_over", "win":
			if index == 0: restart_requested.emit()
			else: menu_requested.emit()


func _begin_start() -> void:
	if DisplayServer.get_name() == "headless":
		start_requested.emit()
		return
	_transitioning = true
	_transition.visible = true
	_transition.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(_transition, "modulate:a", 1.0, 0.48).set_trans(Tween.TRANS_SINE)
	await fade_in.finished
	await get_tree().create_timer(0.72, true).timeout
	start_requested.emit()
	await get_tree().create_timer(0.18, true).timeout
	var fade_out := create_tween()
	fade_out.tween_property(_transition, "modulate:a", 0.0, 0.72).set_trans(Tween.TRANS_SINE)
	await fade_out.finished
	_transition.visible = false
	_transitioning = false


func _build_theme() -> Theme:
	var result := Theme.new()
	var sans := SystemFont.new()
	sans.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Arial", "sans-serif"])
	result.default_font = sans
	result.default_font_size = 16
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		result.set_stylebox(state, "Button", empty)
	result.set_color("font_color", "Button", Color.TRANSPARENT)
	result.set_color("font_hover_color", "Button", Color.TRANSPARENT)
	result.set_color("font_focus_color", "Button", Color.TRANSPARENT)
	return result
