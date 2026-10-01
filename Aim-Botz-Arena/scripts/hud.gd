extends Control
## Runtime UI: anchored HUD, crosshair, radar, feedback and session menus.

signal start_requested(mode: int)
signal resume_requested
signal restart_requested
signal menu_requested
signal quit_requested

const ACCENT := Color("ffb54d")
const INK := Color("101a24")
const PAPER := Color("e9eef3")
const MUTED := Color("9baebb")

var game: Node3D
var _game_ui: Control
var _overlay: Control
var _menu_box: VBoxContainer
var _title: Label
var _subtitle: Label
var _objective: Label
var _clock: Label
var _score: Label
var _stats: Label
var _health: Label
var _health_bar: ProgressBar
var _ammo: Label
var _weapon: Label
var _reload: Label
var _prompt: Label
var _notice: Label
var _kill_feed: Label
var _notice_time := 0.0
var _feed_time := 0.0
var _hit_time := 0.0
var _damage_time := 0.0
var _damage_source := Vector3.ZERO
var _headshot := false
var _feed: Array[String] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	_build_overlay()


func _process(delta: float) -> void:
	_hit_time = maxf(_hit_time - delta, 0.0)
	_damage_time = maxf(_damage_time - delta, 0.0)
	_notice_time = maxf(_notice_time - delta, 0.0)
	_feed_time = maxf(_feed_time - delta, 0.0)
	_notice.visible = _notice_time > 0.0
	if _feed_time <= 0.0:
		_kill_feed.text = ""
		_feed.clear()
	queue_redraw()


func refresh() -> void:
	if game == null or game.player == null:
		return
	var player: Player = game.player
	_objective.text = game.objective_text()
	_clock.text = game.time_text()
	_score.text = "%05d  SCORE" % game.score
	_stats.text = "%d KILLS   ·   %.0f%% ACCURACY   ·   %d HEAD HITS" % [game.kills, game.accuracy(), game.headshots]
	_health.text = "%03d  HEALTH" % ceili(player.health)
	_health_bar.value = player.health
	var weapon := player.get_weapon()
	_ammo.text = "%02d / %s" % [weapon.mag, "∞" if player.infinite_reserve else str(weapon.reserve)]
	_weapon.text = "%s   [%d]" % [weapon.name, player.current_weapon + 1]
	_reload.text = "RELOADING  %d%%" % int(player.get_reload_progress() * 100.0) if player.reloading else "R RELOAD   ·   1 / 2 SWITCH"


func show_game(clear_feedback := true) -> void:
	_overlay.visible = false
	_game_ui.visible = true
	if clear_feedback:
		_hit_time = 0.0
		_damage_time = 0.0
		_notice_time = 0.0
		_feed_time = 0.0
		_feed.clear()
		_kill_feed.text = ""
		_prompt.text = ""


func show_menu() -> void:
	_begin_menu("AIM BOTZ\nARENA", "Train your aim. Survive the arena.")
	_button("START WAVE MISSION", func(): start_requested.emit(0), true)
	_button("PRACTICE  /  STATIC TARGETS", func(): start_requested.emit(1))
	_button("PRACTICE  /  STRAFING TARGETS", func(): start_requested.emit(2))
	_menu_box.add_child(_label("Waves: 3 rounds of armed bots. Clear all 15 to win.\nPractice: 60 seconds, respawning targets, infinite reserve ammo.", 15, MUTED))
	_button("QUIT", func(): quit_requested.emit())
	_controls()
	_focus_first_button()


func show_pause() -> void:
	_begin_menu("PAUSED", "Take a breath. Your session is frozen.", true)
	_button("RESUME", func(): resume_requested.emit(), true)
	_button("RESTART SESSION", func(): restart_requested.emit())
	_button("MAIN MENU", func(): menu_requested.emit())
	_controls()
	_focus_first_button()


func show_result(won: bool) -> void:
	_notice_time = 0.0
	var title := "MISSION COMPLETE" if won else "GAME OVER"
	if won and game.mode != game.Mode.WAVES:
		title = "PRACTICE COMPLETE"
	var subtitle := "All three waves cleared." if won else "The arena got you. Try again."
	if game.mode != game.Mode.WAVES:
		subtitle = "60 seconds of aim training complete."
	_begin_menu(title, subtitle, true)
	var summary := "SCORE  %d   ·   KILLS  %d\nSHOTS  %d   ·   ACCURACY  %.1f%%\nHEAD HITS  %d   ·   TIME  %s" % [game.score, game.kills, game.shots, game.accuracy(), game.headshots, game.elapsed_text()]
	_menu_box.add_child(_label(summary, 20, PAPER))
	_button("PLAY AGAIN", func(): restart_requested.emit(), true)
	_button("MAIN MENU", func(): menu_requested.emit())
	_focus_first_button()


func notify(text: String, duration := 2.0) -> void:
	_notice.text = text
	_notice_time = duration


func set_prompt(text: String) -> void:
	_prompt.text = text


func add_kill(text: String) -> void:
	_feed.append(text)
	while _feed.size() > 4:
		_feed.pop_front()
	_kill_feed.text = "\n".join(_feed)
	_feed_time = 5.0


func flash_hit(headshot: bool) -> void:
	_hit_time = 0.22
	_headshot = headshot


func flash_damage(source_position: Vector3) -> void:
	_damage_time = 0.9
	_damage_source = source_position


func _build_hud() -> void:
	_game_ui = Control.new()
	_game_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_game_ui)
	_game_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var top := _panel(_game_ui, Control.PRESET_TOP_WIDE, Vector4(24, 20, -24, 82))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	top.add_child(row)
	row.add_child(_label("AIM BOTZ  /", 22, ACCENT))
	_objective = _label("", 19)
	_objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_objective)
	_clock = _label("00:00", 24, ACCENT)
	row.add_child(_clock)
	_score = _label("00000  SCORE", 19)
	row.add_child(_score)
	var health_panel := _panel(_game_ui, Control.PRESET_BOTTOM_LEFT, Vector4(24, -112, 294, -24))
	var health_box := VBoxContainer.new()
	health_panel.add_child(health_box)
	_health = _label("100 HEALTH", 24)
	health_box.add_child(_health)
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size.y = 8
	_health_bar.max_value = Player.MAX_HEALTH
	_health_bar.show_percentage = false
	_health_bar.add_theme_stylebox_override("background", _style(Color("263541")))
	_health_bar.add_theme_stylebox_override("fill", _style(Color("57d994")))
	health_box.add_child(_health_bar)
	var ammo_panel := _panel(_game_ui, Control.PRESET_BOTTOM_RIGHT, Vector4(-346, -140, -24, -24))
	var ammo_box := VBoxContainer.new()
	ammo_panel.add_child(ammo_box)
	_weapon = _label("", 17, ACCENT)
	ammo_box.add_child(_weapon)
	_ammo = _label("", 32)
	ammo_box.add_child(_ammo)
	_reload = _label("", 13, MUTED)
	ammo_box.add_child(_reload)
	_stats = _position_label(_game_ui, Control.PRESET_CENTER_BOTTOM, Vector4(-300, -53, 300, -23), 15)
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt = _position_label(_game_ui, Control.PRESET_CENTER, Vector4(-300, 54, 300, 84), 18, ACCENT)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice = _position_label(_game_ui, Control.PRESET_CENTER_TOP, Vector4(-370, 100, 370, 140), 22, ACCENT)
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kill_feed = _position_label(_game_ui, Control.PRESET_TOP_RIGHT, Vector4(-510, 105, -28, 225), 16)
	_kill_feed.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _build_overlay() -> void:
	_overlay = Control.new()
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.04, 0.68)
	_overlay.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 600
	panel.add_theme_stylebox_override("panel", _style(Color(0.035, 0.065, 0.095, 0.97), 28, ACCENT))
	center.add_child(panel)
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 13)
	panel.add_child(_menu_box)


func _begin_menu(title: String, subtitle: String, keep_hud := false) -> void:
	_game_ui.visible = keep_hud
	_overlay.visible = true
	for child in _menu_box.get_children():
		_menu_box.remove_child(child)
		child.queue_free()
	_title = _label(title, 40, ACCENT)
	_menu_box.add_child(_title)
	_subtitle = _label(subtitle, 18)
	_menu_box.add_child(_subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 6
	_menu_box.add_child(spacer)


func _controls() -> void:
	var text := "WASD MOVE   ·   MOUSE LOOK   ·   SPACE JUMP   ·   SHIFT SPRINT\nLMB FIRE   ·   RMB AIM   ·   R RELOAD   ·   1 / 2 OR WHEEL SWITCH\nE OPEN DOOR   ·   ESC PAUSE"
	_menu_box.add_child(_label(text, 13, MUTED))


func _focus_first_button() -> void:
	for child in _menu_box.get_children():
		if child is Button:
			child.grab_focus()
			return


func _button(text: String, action: Callable, primary := false) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", INK if primary else PAPER)
	button.add_theme_color_override("font_focus_color", INK if primary else PAPER)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _style(ACCENT if primary else Color("243544"), 14))
	button.add_theme_stylebox_override("hover", _style(ACCENT.lightened(0.15), 14))
	button.add_theme_stylebox_override("pressed", _style(ACCENT.darkened(0.15), 14))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), 0, PAPER))
	button.pressed.connect(func():
		if game:
			game.sound_fx.play("ui", -6.0)
		action.call())
	_menu_box.add_child(button)


func _label(text: String, font_size: int, color := PAPER) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _style(color: Color, margin := 0, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(margin)
	style.set_corner_radius_all(4)
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	return style


func _panel(parent: Control, preset: int, offsets: Vector4) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.07, 0.1, 0.88), 14))
	parent.add_child(panel)
	_place(panel, preset, offsets)
	return panel


func _position_label(parent: Control, preset: int, offsets: Vector4, font_size: int, color := PAPER) -> Label:
	var label := _label("", font_size, color)
	parent.add_child(label)
	_place(label, preset, offsets)
	return label


func _place(control: Control, preset: int, offsets: Vector4) -> void:
	control.set_anchors_and_offsets_preset(preset)
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w


func _draw() -> void:
	if game == null or not _game_ui.visible:
		return
	_draw_radar()
	if game.state != game.State.PLAYING:
		return
	var center := size * 0.5
	var player: Player = game.player
	var gap := clampf(player.get_spread_degrees() * 5.0 + 5.0, 5.0, 40.0)
	var color := Color("57d994") if player.aiming else PAPER
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + direction * gap, center + direction * (gap + 9.0), Color(0, 0, 0, 0.8), 4)
		draw_line(center + direction * gap, center + direction * (gap + 9.0), color, 2)
	draw_circle(center, 1.5, color)
	if _hit_time > 0.0:
		var hit_color := ACCENT if _headshot else Color("57d994")
		for direction in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			draw_line(center + direction * 7, center + direction * 14, hit_color, 2)
	if _damage_time > 0.0:
		var alpha := _damage_time / 0.9
		var red := Color(0.95, 0.15, 0.1, alpha * 0.3)
		for edge in 6:
			var inset := float(edge) * 10.0
			draw_rect(Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2.0), Color(red, red.a * (1.0 - edge / 6.0)), false, 10)
		var source := player.get_camera().global_basis.inverse() * (_damage_source - player.global_position)
		var direction := Vector2(source.x, source.z).normalized()
		if direction.length_squared() < 0.01:
			direction = Vector2.UP
		var tip := center + direction * 155.0
		var side := direction.orthogonal() * 11.0
		draw_colored_polygon(PackedVector2Array([tip, tip - direction * 22.0 + side, tip - direction * 22.0 - side]), Color(1, 0.25, 0.15, alpha))


func _draw_radar() -> void:
	var bounds := Rect2(24, 102, 156, 156)
	draw_rect(bounds, Color(0.04, 0.07, 0.1, 0.9))
	draw_rect(bounds, Color(MUTED, 0.5), false, 1)
	var map := bounds.grow(-8)
	for obstacle in game.level.radar_rects:
		var start: Vector2 = _map_point(Vector3(obstacle.position.x, 0, obstacle.position.y), map)
		var span: Vector2 = obstacle.size / (ArenaLevel.HALF_SIZE * 2) * map.size
		draw_rect(Rect2(start, span).intersection(map), Color("445668"))
	for bot in game.bots:
		if is_instance_valid(bot) and bot.is_alive():
			draw_circle(_map_point(bot.global_position, map), 3.0, ACCENT if bot.bot_type == Bot.Type.HEAVY else Color("ef675b"))
	var position := _map_point(game.player.global_position, map)
	var forward: Vector3 = -game.player.global_basis.z
	var direction := Vector2(forward.x, forward.z).normalized()
	var side := direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([position + direction * 6, position - direction * 4 + side * 4, position - direction * 4 - side * 4]), Color("57d994"))


func _map_point(point: Vector3, bounds: Rect2) -> Vector2:
	var normalized := (Vector2(point.x, point.z) + Vector2.ONE * ArenaLevel.HALF_SIZE) / (ArenaLevel.HALF_SIZE * 2)
	return bounds.position + normalized.clamp(Vector2.ZERO, Vector2.ONE) * bounds.size
