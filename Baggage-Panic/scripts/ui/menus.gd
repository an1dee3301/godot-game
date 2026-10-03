class_name RunnerMenus
extends CanvasLayer
## Departure-board menus, built without external assets.

signal start_requested
signal restart_requested
signal resume_requested
signal menu_requested
signal quit_requested

## Japandi palette: ink on washi paper, brass accents, sage secondary.
const YELLOW := Color("9c6b2c")   ## Brass accent (headings, rules).
const WHITE := Color("2b2926")    ## Ink: body text on the paper panels.
const DARK := Color("f4eee3")     ## Paper: text on dark buttons.
const CYAN := Color("6c7d5c")     ## Sage: secondary captions.
const MUTED := Color("6e655c")
const CREAM := Color("f2e6cf")
const WELCOME := ["Welcome", "ようこそ", "欢迎", "Chào mừng", "Bienvenue", "Bienvenidos"]

var click_sound: Callable
var flap_sound: Callable
var start_panel: Control
var pause_panel: Control
var game_over_panel: Control
var _root: Control
var _high_score: Label
var _game_stats: Label
var _game_cause: Label
var _new_best: Label
var _start_button: Button
var _restart_button: Button
var _boards: Array[PanelContainer] = []
var _title: Label
var _title_tween: Tween
var _best_tween: Tween
var _stats_lines: Array[Label] = []
var _departure_rows: Array[SplitFlapLabel] = []
var _departure_lights: Array[ColorRect] = []
var _departure_time := 0.0
var _departure_index := 0
var _departure_update := 3
var _welcome: Label
var _welcome_index := 0
var _welcome_time := 0.0
static var _fonts: Dictionary = {}


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_root)
	start_panel = _screen()
	pause_panel = _screen()
	game_over_panel = _screen()
	_build_start()
	_build_pause()
	_build_game_over()
	get_viewport().size_changed.connect(_fit_boards)
	_fit_boards()
	hide_all()
	set_process(true)


func _process(delta: float) -> void:
	if not _root.visible or not start_panel.visible:
		return
	_welcome_time += delta
	if _welcome_time >= 2.6:
		_welcome_time = 0.0
		_welcome_index = (_welcome_index + 1) % WELCOME.size()
		var swap := create_tween()
		swap.tween_property(_welcome, "modulate:a", 0.0, 0.35)
		swap.tween_callback(func() -> void: _welcome.text = str(WELCOME[_welcome_index]))
		swap.tween_property(_welcome, "modulate:a", 1.0, 0.45)
	_departure_time += delta
	if _departure_time >= 2.4:
		_departure_time = 0.0
		_departure_index = (_departure_index + 1) % _departure_rows.size()
		_set_departure(_departure_index, _departure_update, true)
		_departure_update += 1


func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible or not event.is_action_pressed("start") or event.is_echo():
		return
	if start_panel.visible:
		_emit_with_click(start_requested)
		get_viewport().set_input_as_handled()
	elif game_over_panel.visible:
		_emit_with_click(restart_requested)
		get_viewport().set_input_as_handled()


func show_start(high_score: int) -> void:
	hide_all()
	_root.visible = true
	start_panel.visible = true
	_high_score.text = "%06d" % maxi(high_score, 0)
	_start_button.grab_focus()
	if _title_tween != null:
		_title_tween.kill()
	start_panel.modulate.a = 0.0
	_title_tween = create_tween()
	_title_tween.tween_property(start_panel, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)


func show_game_over(stats: Dictionary) -> void:
	hide_all()
	_root.visible = true
	game_over_panel.visible = true
	_game_cause.text = str(stats.get("cause", "Your baggage missed the flight."))
	_game_stats.text = "SCORE  %06d       BEST  %06d\nDISTANCE  %d m       TAGS  %d\nLEVEL  %02d       ROUTES  %d RIGHT / %d WRONG" % [
		int(stats.get("score", 0)), int(stats.get("best", 0)),
		roundi(float(stats.get("distance", 0.0))), int(stats.get("tags", 0)),
		int(stats.get("level", 1)), int(stats.get("routes_ok", 0)), int(stats.get("routes_bad", 0))]
	_new_best.visible = bool(stats.get("new_best", false))
	var lines := _game_stats.text.split("\n")
	_game_stats.visible = false
	for index in _stats_lines.size():
		var line := _stats_lines[index]
		line.text = lines[index] if index < lines.size() else ""
		line.modulate.a = 0.0
		line.position.x = 24.0
		var reveal := create_tween().set_parallel(true)
		reveal.tween_property(line, "modulate:a", 1.0, 0.28).set_delay(0.12 + index * 0.13)
		reveal.tween_property(line, "position:x", 0.0, 0.28).set_delay(0.12 + index * 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _new_best.visible:
		if _best_tween != null:
			_best_tween.kill()
		_new_best.scale = Vector2(1.8, 1.8)
		_new_best.rotation = -0.18
		_best_tween = create_tween().set_parallel(true)
		_best_tween.tween_property(_new_best, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		_best_tween.tween_property(_new_best, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_restart_button.grab_focus()


func show_pause() -> void:
	hide_all()
	_root.visible = true
	pause_panel.visible = true
	var resume := pause_panel.find_child("ResumeButton", true, false) as Button
	if resume != null:
		resume.grab_focus()


func hide_all() -> void:
	if _root == null:
		return
	_root.visible = false
	start_panel.visible = false
	pause_panel.visible = false
	game_over_panel.visible = false


func is_showing(panel_name: String) -> bool:
	if _root == null or not _root.visible:
		return false
	match panel_name:
		"start": return start_panel.visible
		"pause": return pause_panel.visible
		"game_over": return game_over_panel.visible
	return false


func _screen() -> Control:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(screen)
	# Let the terminal show through: a soft vignette and a warm shade behind the panel side.
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
void fragment() {
	vec2 d = UV - vec2(0.5);
	float vignette = smoothstep(0.35, 0.95, length(d * vec2(1.25, 1.0)));
	float side = smoothstep(0.65, 0.0, UV.x) * 0.35;
	COLOR = vec4(0.09, 0.07, 0.05, clamp(vignette * 0.75 + side, 0.0, 0.85));
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	shade.material = material
	screen.add_child(shade)
	return screen


func _build_start() -> void:
	var board := _board(start_panel, Vector2(580, 640), true)
	var box := _box(board)
	box.add_theme_constant_override("separation", 8)
	box.add_child(_text("DN INTERNATIONAL TERMINAL   ·   国際線ターミナル", 12, YELLOW, HORIZONTAL_ALIGNMENT_LEFT, 3))
	_title = _text("Baggage Panic", 56, WHITE, HORIZONTAL_ALIGNMENT_LEFT, 0, true)
	box.add_child(_title)
	var subtitle := HBoxContainer.new()
	subtitle.add_theme_constant_override("separation", 18)
	subtitle.add_child(_inline(_text("バゲージ・パニック", 19, YELLOW, HORIZONTAL_ALIGNMENT_LEFT, 2)))
	_welcome = _inline(_text(str(WELCOME[0]), 17, CYAN, HORIZONTAL_ALIGNMENT_LEFT, 1))
	subtitle.add_child(_welcome)
	box.add_child(subtitle)
	box.add_child(_text("You are a suitcase. The belt never stops.", 17, MUTED))
	box.add_child(_rule())
	box.add_child(_text("DEPARTURES   出発   出发   KHỞI HÀNH", 11, YELLOW, HORIZONTAL_ALIGNMENT_LEFT, 3))
	var header := _flap_row(Color("e9c98a"))
	header.set_text(_flight_line("TIME", "FLIGHT", "DESTINATION", "GATE", "REMARKS"), false)
	box.add_child(header)
	for index in 3:
		var strip := HBoxContainer.new()
		strip.add_theme_constant_override("separation", 7)
		var light := ColorRect.new()
		light.custom_minimum_size = Vector2(4, 17)
		light.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		strip.add_child(light)
		_departure_lights.append(light)
		var row := _flap_row(CREAM)
		strip.add_child(row)
		box.add_child(strip)
		_departure_rows.append(row)
		_set_departure(index, index, false)
	box.add_child(_rule())
	box.add_child(_text("BOARDING INSTRUCTIONS", 11, YELLOW, HORIZONTAL_ALIGNMENT_LEFT, 3))
	var keys := HBoxContainer.new()
	keys.add_theme_constant_override("separation", 6)
	for entry: Array in [[["A", "D"], "Switch belt"], [["W"], "Jump"], [["S"], "Flatten"], [["Esc"], "Pause"]]:
		for key: String in entry[0]:
			keys.add_child(_keycap(key))
		keys.add_child(_inline(_text(str(entry[1]), 14, WHITE)))
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(10, 0)
		keys.add_child(gap)
	box.add_child(keys)
	box.add_child(_text("Tags +10 · Passports +50 · Priority boosts · Fragile shields one hit. Take the exit that matches your destination code.", 13, MUTED))
	box.add_child(_rule())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 22)
	var stub := VBoxContainer.new()
	stub.add_theme_constant_override("separation", 0)
	stub.add_child(_inline(_text("PERSONAL BEST", 11, YELLOW, HORIZONTAL_ALIGNMENT_LEFT, 3)))
	_high_score = _inline(_text("000000", 30, WHITE, HORIZONTAL_ALIGNMENT_LEFT, 2, true))
	stub.add_child(_high_score)
	footer.add_child(stub)
	var buttons := VBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_theme_constant_override("separation", 8)
	_start_button = _button("Board now    →", start_requested)
	buttons.add_child(_start_button)
	buttons.add_child(_button("Quit", quit_requested, false))
	footer.add_child(buttons)
	box.add_child(footer)
	box.add_child(_text("Press Enter to board", 12, MUTED, HORIZONTAL_ALIGNMENT_RIGHT))


## Labels inside rows must not wrap (they have no width of their own).
func _inline(label: Label) -> Label:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label


func _keycap(key: String) -> PanelContainer:
	var cap := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.35)
	style.border_color = Color(WHITE, 0.55)
	style.set_border_width_all(1)
	style.border_width_bottom = 2
	style.set_corner_radius_all(4)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	cap.add_theme_stylebox_override("panel", style)
	cap.add_child(_inline(_text(key, 13, WHITE, HORIZONTAL_ALIGNMENT_CENTER)))
	return cap


func _flap_row(ink: Color) -> SplitFlapLabel:
	var row := SplitFlapLabel.new()
	row.columns = 41
	row.cell_size = Vector2(12.0, 22.0)
	row.font_size = 13
	row.glyph_color = ink
	row.flap_sound = func() -> void:
		if flap_sound.is_valid():
			flap_sound.call()
	return row


func _flight_line(time: String, flight: String, destination: String, gate: String, remarks: String) -> String:
	return "%s %s %s %s %s" % [time.left(5).rpad(5), flight.left(6).rpad(6), destination.left(12).rpad(12), gate.left(4).rpad(4), remarks.left(10).rpad(10)]


func _set_departure(row_index: int, sequence: int, animate: bool) -> void:
	var codes := ["LAX", "SYD", "NRT", "CDG", "JFK", "DXB", "LHR", "SGN"]
	var times := ["14:05", "16:20", "18:45", "20:10", "21:35", "22:50", "23:15", "00:25"]
	var flights := ["DN017", "DN204", "DN305", "DN116", "DN402", "DN228", "DN091", "DN388"]
	var gates := ["A07", "B12", "C03", "A14", "D08", "B06", "C11", "D02"]
	var remarks := ["BOARDING", "ON TIME", "FINAL CALL", "DELAYED", "ON TIME", "BOARDING", "GATE CLOSED", "ON TIME"]
	var index := sequence % codes.size()
	var airport := AirportData.get_airport(codes[index])
	_departure_rows[row_index].set_text(_flight_line(times[index], flights[index], str(airport.get("city", "")), gates[index], remarks[index]), animate)
	match remarks[index]:
		"BOARDING": _departure_lights[row_index].color = Color("7f9b6a")
		"DELAYED": _departure_lights[row_index].color = Color("d1a04f")
		"FINAL CALL", "GATE CLOSED": _departure_lights[row_index].color = Color("b85c47")
		_: _departure_lights[row_index].color = CREAM


func _build_pause() -> void:
	var board := _board(pause_panel, Vector2(420, 340))
	var box := _box(board)
	box.add_child(_text("Paused", 46, WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1, true))
	box.add_child(_text("一時停止 · 暂停 · Tạm dừng · Pause · Pausa", 14, YELLOW, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_text("Baggage handling on hold", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_rule())
	var resume := _button("Resume    →", resume_requested)
	resume.name = "ResumeButton"
	box.add_child(resume)
	box.add_child(_button("Main menu", menu_requested, false))
	box.add_child(_button("Quit", quit_requested, false))


func _build_game_over() -> void:
	var board := _board(game_over_panel, Vector2(610, 550))
	var box := _box(board)
	var luggage_tag := Control.new()
	luggage_tag.custom_minimum_size = Vector2(72, 35)
	var tag_shape := Polygon2D.new()
	tag_shape.polygon = PackedVector2Array([Vector2(0, 3), Vector2(51, 3), Vector2(70, 17), Vector2(51, 32), Vector2(0, 32)])
	tag_shape.color = Color("b85c47")
	luggage_tag.add_child(tag_shape)
	var tag_hole := ColorRect.new()
	tag_hole.color = DARK
	tag_hole.position = Vector2(55, 15)
	tag_hole.size = Vector2(5, 5)
	luggage_tag.add_child(tag_hole)
	var tag_center := CenterContainer.new()
	tag_center.add_child(luggage_tag)
	box.add_child(tag_center)
	box.add_child(_text("Lost Luggage", 44, WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1, true))
	box.add_child(_text("手荷物紛失 · 行李遗失 · Hành lý thất lạc · Bagage perdu · Equipaje perdido", 13, YELLOW, HORIZONTAL_ALIGNMENT_CENTER))
	_game_cause = _text("", 19, WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_game_cause)
	box.add_child(_rule())
	_game_stats = _text("", 18, WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_game_stats)
	for index in 3:
		var line := _text("", 17, WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		box.add_child(line)
		_stats_lines.append(line)
	_new_best = _text("New personal best", 22, YELLOW, HORIZONTAL_ALIGNMENT_CENTER, 2)
	box.add_child(_new_best)
	box.add_child(_rule())
	_restart_button = _button("Fly again    →", restart_requested)
	box.add_child(_restart_button)
	box.add_child(_button("Main menu", menu_requested, false))
	box.add_child(_button("Quit", quit_requested, false))
	box.add_child(_text("Press Enter to restart", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))


## Frosted washi panel: the scene behind is blurred and tinted warm paper.
func _board(parent: Control, minimum: Vector2, left := false) -> PanelContainer:
	var board := PanelContainer.new()
	board.custom_minimum_size = minimum
	if left:
		board.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		board.offset_left = 64.0
		board.offset_right = 64.0 + minimum.x
		board.pivot_offset = Vector2(0.0, minimum.y * 0.5)
	else:
		board.set_anchors_preset(Control.PRESET_CENTER)
		board.offset_left = -minimum.x * 0.5
		board.offset_right = minimum.x * 0.5
		board.pivot_offset = minimum * 0.5
	board.offset_top = -minimum.y * 0.5
	board.offset_bottom = minimum.y * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.92, 0.86, 0.8)
	style.border_color = Color(YELLOW, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(34)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 8)
	board.add_theme_stylebox_override("panel", style)
	var frost := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	vec3 blurred = textureLod(screen_tex, SCREEN_UV, 3.2).rgb;
	float paper = COLOR.a;
	COLOR.rgb = mix(blurred, COLOR.rgb, clamp(paper, 0.0, 1.0));
	COLOR.a = paper > 0.5 ? 1.0 : paper * 2.0;
}"""
	frost.shader = shader
	board.material = frost
	parent.add_child(board)
	_boards.append(board)
	return board


func _fit_boards() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	for board in _boards:
		var minimum := board.custom_minimum_size
		var factor := minf(1.0, minf((viewport_size.x - 24.0) / minimum.x, (viewport_size.y - 24.0) / minimum.y))
		board.scale = Vector2.ONE * maxf(factor, 0.3)


func _box(board: PanelContainer) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	board.add_child(box)
	return box


## Clean sans with CJK/Vietnamese fallback; `tracking` adds letter spacing, `title` uses a light weight.
func _text(value: String, size: int, color: Color = WHITE, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, tracking := 0, title := false) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = alignment
	label.add_theme_font_override("font", _font(title, tracking))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _font(title: bool, tracking: int) -> Font:
	var key := "%s:%d" % [title, tracking]
	if _fonts.has(key):
		return _fonts[key]
	var base := SystemFont.new()
	base.font_names = PackedStringArray(["Avenir Next", "Segoe UI", "Helvetica Neue", "Noto Sans"])
	base.font_weight = 400 if title else 500
	base.fallbacks = [Signage.font()]
	var variation := FontVariation.new()
	variation.base_font = base
	variation.spacing_glyph = tracking
	_fonts[key] = variation
	return variation


func _rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.color = Color(YELLOW, 0.45)
	rule.custom_minimum_size = Vector2(0, 1)
	return rule


## Primary: ink pill with paper text. Secondary: hairline outline. Focus: brass underline.
func _button(caption: String, callback: Signal, primary := true) -> Button:
	var button := Button.new()
	button.text = caption
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 44 if primary else 38)
	button.add_theme_font_override("font", _font(false, 1))
	button.add_theme_font_size_override("font_size", 18 if primary else 16)
	var ink := DARK if primary else WHITE
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, ink)
	var normal := StyleBoxFlat.new()
	normal.bg_color = WHITE if primary else Color(1, 1, 1, 0.0)
	normal.border_color = Color(WHITE, 0.5)
	normal.set_border_width_all(0 if primary else 1)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("4a3a2c") if primary else Color(1, 1, 1, 0.35)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("1c1a18") if primary else Color(1, 1, 1, 0.5)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = YELLOW
	focus.border_width_bottom = 3
	focus.set_corner_radius_all(4)
	button.add_theme_stylebox_override("focus", focus)
	button.mouse_entered.connect(func() -> void: _button_zoom(button, 1.02))
	button.mouse_exited.connect(func() -> void: _button_zoom(button, 1.0))
	button.focus_entered.connect(func() -> void: _button_zoom(button, 1.02))
	button.focus_exited.connect(func() -> void: _button_zoom(button, 1.0))
	button.pressed.connect(func() -> void: _emit_with_click(callback))
	return button


func _button_zoom(button: Button, size: float) -> void:
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * size, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _emit_with_click(callback: Signal) -> void:
	if click_sound.is_valid():
		click_sound.call()
	callback.emit()
