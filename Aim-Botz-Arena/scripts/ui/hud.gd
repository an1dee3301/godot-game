class_name GameHUD
extends CanvasLayer
## In-game HUD: health, ammo, crosshair, timer, wave/enemy counter, score,
## kill feed, radar, damage feedback, prompts and banners.

const ACCENT := Color(0.95, 0.62, 0.2)

var player: Player

var crosshair: Crosshair
var radar: Radar
var damage_indicator: DamageIndicator
var _health_label: Label
var _health_bar: ColorRect
var _health_bar_back: ColorRect
var _ammo_label: Label
var _reserve_label: Label
var _weapon_label: Label
var _reload_bar: ColorRect
var _timer_label: Label
var _objective_label: Label
var _score_label: Label
var _stats_label: Label
var _prompt_label: Label
var _banner_label: Label
var _sub_banner_label: Label
var _killfeed: VBoxContainer
var _vignette: TextureRect
var _flash: ColorRect
var _pickup_label: Label

var _flash_alpha := 0.0
var _banner_time := 0.0
var _pickup_time := 0.0
var _low_health_pulse := 0.0


func _ready() -> void:
	layer = 1
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_vignette = TextureRect.new()
	_vignette.texture = _vignette_texture()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate.a = 0.0
	root.add_child(_vignette)
	_flash = ColorRect.new()
	_flash.color = Color(1.0, 0.0, 0.0, 0.0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)

	damage_indicator = DamageIndicator.new()
	root.add_child(damage_indicator)
	crosshair = Crosshair.new()
	root.add_child(crosshair)

	# Bottom-left: health.
	var health_box := _panel(root, Vector2(24, -96), Vector2(290, 72), Control.PRESET_BOTTOM_LEFT)
	var health_icon := _label(health_box, "+", 44, Color(0.45, 1.0, 0.5))
	health_icon.position = Vector2(14, 2)
	_health_label = _label(health_box, "100", 44, Color.WHITE)
	_health_label.position = Vector2(52, 2)
	_health_bar_back = ColorRect.new()
	_health_bar_back.color = Color(1, 1, 1, 0.15)
	_health_bar_back.position = Vector2(148, 30)
	_health_bar_back.size = Vector2(124, 12)
	health_box.add_child(_health_bar_back)
	_health_bar = ColorRect.new()
	_health_bar.color = Color(0.45, 1.0, 0.5)
	_health_bar.position = _health_bar_back.position
	_health_bar.size = _health_bar_back.size
	health_box.add_child(_health_bar)

	# Bottom-right: ammo.
	var ammo_box := _panel(root, Vector2(-314, -116), Vector2(290, 92), Control.PRESET_BOTTOM_RIGHT)
	_weapon_label = _label(ammo_box, "AK-47", 18, ACCENT)
	_weapon_label.position = Vector2(16, 6)
	_ammo_label = _label(ammo_box, "30", 48, Color.WHITE)
	_ammo_label.position = Vector2(16, 28)
	_reserve_label = _label(ammo_box, "/ 90", 26, Color(0.8, 0.8, 0.8))
	_reserve_label.position = Vector2(110, 46)
	_reload_bar = ColorRect.new()
	_reload_bar.color = ACCENT
	_reload_bar.position = Vector2(16, 84)
	_reload_bar.size = Vector2(0, 4)
	ammo_box.add_child(_reload_bar)

	# Top-center: timer and objective.
	var top := _panel(root, Vector2(-170, 12), Vector2(340, 74), Control.PRESET_CENTER_TOP)
	_timer_label = _label(top, "00:00.0", 30, Color.WHITE)
	_timer_label.position = Vector2(0, 4)
	_timer_label.size = Vector2(340, 36)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label = _label(top, "", 17, ACCENT)
	_objective_label.position = Vector2(0, 42)
	_objective_label.size = Vector2(340, 24)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Top-left: radar + score/stats.
	radar = Radar.new()
	radar.position = Vector2(20, 20)
	radar.size = Vector2(200, 200)
	root.add_child(radar)
	_score_label = _label(root, "SCORE 0", 22, Color.WHITE)
	_score_label.position = Vector2(22, 228)
	_stats_label = _label(root, "", 16, Color(0.85, 0.85, 0.85))
	_stats_label.position = Vector2(22, 258)

	# Top-right: kill feed.
	_killfeed = VBoxContainer.new()
	_place(_killfeed, Control.PRESET_TOP_RIGHT, Vector2(-420, 20), Vector2(400, 200))
	_killfeed.alignment = BoxContainer.ALIGNMENT_BEGIN
	_killfeed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_killfeed)

	# Center prompts and banners.
	_prompt_label = _centered(root, 20, Color.WHITE, 90.0)
	_pickup_label = _centered(root, 22, Color(0.5, 1.0, 0.55), 125.0)
	_banner_label = _centered(root, 64, ACCENT, -170.0)
	_sub_banner_label = _centered(root, 22, Color.WHITE, -100.0)


func setup(target_player: Player, level: ArenaLevel) -> void:
	player = target_player
	radar.player = player
	radar.obstacle_rects = level.radar_rects
	radar.arena_half = ArenaLevel.HALF_SIZE
	damage_indicator.player = player
	player.health_changed.connect(set_health)
	player.ammo_changed.connect(set_ammo)
	player.damaged.connect(_on_player_damaged)
	player.hit_landed.connect(func(_target: Node, headshot: bool, killed: bool) -> void: crosshair.show_hit(headshot, killed))
	player.interact_prompt_changed.connect(func(text: String) -> void: _prompt_label.text = text)


func reset() -> void:
	for child in _killfeed.get_children():
		child.queue_free()
	damage_indicator.clear()
	_flash_alpha = 0.0
	_banner_time = 0.0
	_pickup_time = 0.0
	_prompt_label.text = ""
	_stats_label.text = ""
	_banner_label.text = ""
	_sub_banner_label.text = ""


func set_health(current: float, maximum: float) -> void:
	_health_label.text = str(ceili(current))
	var ratio := clampf(current / maximum, 0.0, 1.0)
	_health_bar.size.x = _health_bar_back.size.x * ratio
	var color := Color(1.0, 0.3, 0.25).lerp(Color(0.45, 1.0, 0.5), ratio)
	_health_bar.color = color
	_health_label.add_theme_color_override("font_color", Color.WHITE if ratio > 0.3 else Color(1.0, 0.35, 0.3))


func set_ammo(mag: int, reserve: int, weapon_name: String) -> void:
	_ammo_label.text = str(mag)
	_reserve_label.text = "/ %s" % ("INF" if player and player.infinite_reserve else str(reserve))
	_weapon_label.text = weapon_name
	var low := mag <= 0
	_ammo_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.25) if low else Color.WHITE)
	_reserve_label.position.x = 16 + _ammo_label.get_minimum_size().x + 10


func set_time(seconds: float) -> void:
	_timer_label.text = format_time(seconds)


func set_objective(text: String) -> void:
	_objective_label.text = text


func set_score(score: int) -> void:
	_score_label.text = "SCORE %d" % score


func set_stats(text: String) -> void:
	_stats_label.text = text


func show_damage_flash() -> void:
	_flash_alpha = maxf(_flash_alpha, 0.8)


func show_banner(title: String, subtitle := "", duration := 2.5) -> void:
	_banner_label.text = title
	_sub_banner_label.text = subtitle
	_banner_time = duration


func show_pickup(text: String) -> void:
	_pickup_label.text = text
	_pickup_time = 1.6


func add_kill(victim: String, weapon: String, headshot: bool, heavy: bool) -> void:
	var entry := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.7)
	style.border_color = Color(0.9, 0.2, 0.15, 0.9)
	style.border_width_left = 3
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	entry.add_theme_stylebox_override("panel", style)
	var text := "YOU  [%s]  %s%s" % [weapon, "HEADSHOT  " if headshot else "", victim]
	var label := _label(entry, text, 16, Color(1.0, 0.55, 0.5) if heavy else Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	entry.size_flags_horizontal = Control.SIZE_SHRINK_END
	_killfeed.add_child(entry)
	if _killfeed.get_child_count() > 5:
		_killfeed.get_child(0).queue_free()
	var tween := entry.create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(entry, "modulate:a", 0.0, 0.5)
	tween.tween_callback(entry.queue_free)


func _process(delta: float) -> void:
	if player == null:
		return
	crosshair.spread_degrees = player.get_spread_degrees()
	crosshair.visible = player.alive and not (player.aiming and player.current_weapon == 1)
	_reload_bar.size.x = 258.0 * player.get_reload_progress()
	_flash_alpha = move_toward(_flash_alpha, 0.0, delta * 1.4)
	_flash.color.a = _flash_alpha * 0.35
	var health_ratio := player.health / Player.MAX_HEALTH
	_low_health_pulse += delta * 4.0
	var low := 0.0
	if player.alive and health_ratio < 0.35:
		low = (0.35 - health_ratio) * 1.6 + sin(_low_health_pulse) * 0.08
	_vignette.modulate.a = clampf(maxf(_flash_alpha, low), 0.0, 0.9)
	if _banner_time > 0.0:
		_banner_time -= delta
		var alpha := clampf(_banner_time / 0.5, 0.0, 1.0)
		_banner_label.modulate.a = alpha
		_sub_banner_label.modulate.a = alpha
	else:
		_banner_label.modulate.a = 0.0
		_sub_banner_label.modulate.a = 0.0
	_pickup_time = maxf(_pickup_time - delta, 0.0)
	_pickup_label.modulate.a = clampf(_pickup_time / 0.4, 0.0, 1.0)


func _on_player_damaged(amount: float, source_position: Vector3) -> void:
	_flash_alpha = clampf(_flash_alpha + amount / 25.0, 0.0, 1.0)
	damage_indicator.add_hit(source_position)


static func format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var remainder := fmod(seconds, 60.0)
	return "%02d:%04.1f" % [minutes, remainder]


func _vignette_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.8, 0.0, 0.0, 0.0))
	gradient.set_color(1, Color(0.8, 0.0, 0.0, 0.95))
	gradient.add_point(0.55, Color(0.8, 0.0, 0.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 1.0)
	texture.width = 256
	texture.height = 256
	return texture


func _panel(parent: Control, offset: Vector2, panel_size: Vector2, preset: Control.LayoutPreset) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.07, 0.6)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	_place(panel, preset, offset, panel_size)
	return panel


## Anchors a control to a preset and positions it with explicit offsets, so
## layout stays correct regardless of the parent's size at creation time.
func _place(control: Control, preset: Control.LayoutPreset, offset: Vector2, control_size: Vector2) -> void:
	control.set_anchors_preset(preset)
	control.offset_left = offset.x
	control.offset_top = offset.y
	control.offset_right = offset.x + control_size.x
	control.offset_bottom = offset.y + control_size.y


func _label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _centered(parent: Control, font_size: int, color: Color, y_offset: float) -> Label:
	var label := _label(parent, "", font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(label, Control.PRESET_CENTER, Vector2(-450, y_offset - 40), Vector2(900, 80))
	return label
