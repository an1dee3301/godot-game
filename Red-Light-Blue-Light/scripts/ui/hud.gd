class_name RaceHUD
extends CanvasLayer
## Responsive match display with compact roster, announcements and results.

signal ready_requested()
signal start_requested()
signal leave_requested()

var _banner: Label
var _subbanner: Label
var _timer: Label
var _distance: Label
var _connection: Label
var _round: Label
var _roster_rows: VBoxContainer
var _message: Label
var _detail: Label
var _message_panel: PanelContainer
var _results: RichTextLabel
var _results_panel: PanelContainer
var _ready_button: Button
var _start_button: Button
var _leave_button: Button
var _flash: ColorRect
var _message_remaining := 0.0
var _flash_remaining := 0.0
var _roster_signature := ""

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_flash = ColorRect.new()
	_flash.color = Color(1, 0.08, 0.12, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_flash)
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_right = -12
	top.offset_top = 10
	top.add_theme_constant_override("separation", 8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var left := _panel(top, 220)
	var left_column := _column(left, 7)
	_connection = _label(left_column, "", 12, Color("a5bfd1"))
	_round = _label(left_column, "", 15, Color("f9d77e"))
	var middle := _panel(top, 0)
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var middle_column := _column(middle, 5)
	_banner = _label(middle_column, "LOBBY · READY UP (R)", 27, Color("5ac1ff"))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subbanner = _label(middle_column, "", 13, Color("bdcddc"))
	_subbanner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var right := _panel(top, 185)
	var right_column := _column(right, 5)
	_timer = _label(right_column, "", 21, Color("eaf3ff"))
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_distance = _label(right_column, "", 13, Color("b1cce0"))
	_distance.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var roster_panel := _panel(root, 250)
	roster_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	roster_panel.offset_left = -262
	roster_panel.offset_right = -12
	roster_panel.offset_top = 100
	var roster_column := _column(roster_panel, 7)
	var roster_title := _label(roster_column, "RUNNERS", 18, Color("eaf3ff"))
	roster_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_roster_rows = VBoxContainer.new()
	_roster_rows.add_theme_constant_override("separation", 2)
	roster_column.add_child(_roster_rows)
	_message_panel = _panel(root, 0)
	_message_panel.set_anchors_preset(Control.PRESET_CENTER)
	_message_panel.anchor_left = 0.24
	_message_panel.anchor_right = 0.76
	_message_panel.anchor_top = 0.34
	_message_panel.anchor_bottom = 0.34
	_message_panel.offset_left = 0
	_message_panel.offset_right = 0
	_message_panel.offset_top = 0
	_message_panel.offset_bottom = 0
	_message_panel.visible = false
	var message_column := _column(_message_panel, 3)
	_message = _label(message_column, "", 38, Color("f5f8ff"))
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail = _label(message_column, "", 18, Color("dce8f2"))
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_panel = _panel(root, 400)
	_results_panel.set_anchors_preset(Control.PRESET_CENTER)
	_results_panel.offset_left = -200
	_results_panel.offset_right = 200
	_results_panel.offset_top = -145
	_results_panel.offset_bottom = 145
	_results_panel.visible = false
	_results = RichTextLabel.new()
	_results.bbcode_enabled = true
	_results.scroll_active = true
	_results.custom_minimum_size = Vector2(378, 270)
	_results_panel.add_child(_results)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 12
	bottom.offset_right = -12
	bottom.offset_top = -84
	bottom.offset_bottom = -10
	bottom.add_theme_constant_override("separation", 5)
	bottom.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(bottom)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	bottom.add_child(actions)
	_ready_button = _button(actions, "READY", Color("12699d"))
	_ready_button.pressed.connect(func() -> void: ready_requested.emit())
	_start_button = _button(actions, "START", Color("8a6828"))
	_start_button.pressed.connect(func() -> void: start_requested.emit())
	_leave_button = _button(actions, "LEAVE", Color("35455c"))
	_leave_button.pressed.connect(func() -> void: leave_requested.emit())
	var hint := _label(bottom, "WASD move  ·  Shift sprint  ·  Space jump  ·  F shove  ·  R ready  ·  Esc free mouse", 13, Color("d4e5f1"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_stylebox_override("normal", _style(Color(0.04, 0.09, 0.16, 0.78), Color.TRANSPARENT, 0, 5))

func _process(delta: float) -> void:
	_message_remaining = maxf(_message_remaining - delta, 0.0)
	if _message_remaining <= 0.0:
		_message_panel.visible = false
	elif _message_panel.visible:
		_message_panel.modulate.a = minf(1.0, _message_remaining / 0.35)
	_flash_remaining = maxf(_flash_remaining - delta, 0.0)
	_flash.color.a = minf(0.48, _flash_remaining * 0.6)

func refresh(match_state: MatchController, local_player: RacePlayer, hosting: bool, address: String, port: int) -> void:
	var phase := match_state.phase
	match phase:
		MatchController.Phase.LOBBY:
			_banner.text = "LOBBY · READY UP (R)"
			_banner.add_theme_color_override("font_color", Color("5ac1ff"))
			_subbanner.text = "Host: press START (Enter)" if match_state.can_start() and hosting else "Waiting for %d player%s to ready" % [_unready_count(match_state), "" if _unready_count(match_state) == 1 else "s"]
		MatchController.Phase.COUNTDOWN:
			_banner.text = "GET READY"
			_banner.add_theme_color_override("font_color", Color("ffe385"))
			_subbanner.text = "Gate opens in %d" % int(ceil(match_state.time_left))
		MatchController.Phase.RESULTS:
			_banner.text = "ROUND RESULTS"
			_banner.add_theme_color_override("font_color", Color("ffe385"))
			_subbanner.text = "Next round in %d s" % int(ceil(match_state.time_left))
		_:
			_banner.text = ["BLUE LIGHT · GO", "TURNING…", "RED LIGHT · STOP!"][match_state.light]
			_banner.add_theme_color_override("font_color", [Color("45b7ff"), Color("ffd36c"), Color("ff5363")][match_state.light])
			_subbanner.text = "Run to the finish" if match_state.light == MatchController.Light.GO else "Get ready to freeze" if match_state.light == MatchController.Light.WARN else "Do not move"
	_timer.text = "%.0f s" % match_state.time_left if phase != MatchController.Phase.LOBBY else ""
	_distance.text = "%.1f m to finish" % maxf(0.0, local_player.global_position.z - GameLevel.FINISH_Z) if local_player != null else ""
	_connection.text = "Host port %d · %d players" % [port, match_state.roster.size()] if hosting else "%s:%d · peer %d" % [address, port, multiplayer.get_unique_id()]
	_round.text = "ROUND %d" % maxi(1, match_state.round_number)
	_update_roster(match_state)
	_leave_button.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	_ready_button.visible = phase == MatchController.Phase.LOBBY
	_start_button.visible = phase == MatchController.Phase.LOBBY and hosting
	_start_button.disabled = not match_state.can_start()
	if match_state.roster.has(multiplayer.get_unique_id()):
		_ready_button.text = "UNREADY" if bool(match_state.roster[multiplayer.get_unique_id()]["ready"]) else "READY"
	_results_panel.visible = phase == MatchController.Phase.RESULTS
	if _results_panel.visible:
		_update_results(match_state)
	if phase == MatchController.Phase.COUNTDOWN:
		_message_panel.visible = true
		_message_panel.modulate.a = 1.0
		_message.text = str(int(ceil(match_state.time_left)))
		_message.add_theme_color_override("font_color", Color("ffe385"))
		_detail.text = "Gate opens soon"

func on_phase(match_state: MatchController) -> void:
	_message_remaining = 0.0
	_message_panel.visible = false
	if match_state.phase == MatchController.Phase.PLAYING:
		announce("GO!", "BLUE LIGHT")

func announce(title: String, detail: String) -> void:
	_message.text = title
	_detail.text = detail
	_message.add_theme_color_override("font_color", Color("ffd879") if title.begins_with("FINISHED") else Color("ff6271") if title == "ELIMINATED" else Color("f5f8ff"))
	_message_panel.visible = true
	_message_panel.modulate.a = 1.0
	_message_remaining = 2.0
	if title == "ELIMINATED":
		_flash_remaining = 0.8

static func ordinal(place: int) -> String:
	var suffix := "th"
	if place % 100 not in [11, 12, 13]:
		match place % 10:
			1: suffix = "st"
			2: suffix = "nd"
			3: suffix = "rd"
	return "%d%s" % [place, suffix]

func _unready_count(match_state: MatchController) -> int:
	var count := 0
	for entry in match_state.roster.values():
		if not bool(entry["ready"]):
			count += 1
	return count

func _update_roster(match_state: MatchController) -> void:
	var signature := str(match_state.roster) + str(multiplayer.get_unique_id())
	if signature == _roster_signature:
		return
	_roster_signature = signature
	for child in _roster_rows.get_children():
		child.queue_free()
	for id in match_state.get_ranking():
		var entry: Dictionary = match_state.roster[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		_roster_rows.add_child(row)
		var swatch := ColorRect.new()
		swatch.color = GameLevel.COLORS[int(entry["slot"])]
		swatch.custom_minimum_size = Vector2(9, 29)
		row.add_child(swatch)
		var details := VBoxContainer.new()
		details.add_theme_constant_override("separation", 0)
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var name_text := str(entry["name"]) + (" (you)" if id == multiplayer.get_unique_id() else "")
		var name_label := _label(details, name_text, 14, Color("f1f6fc"))
		name_label.clip_text = true
		_label(details, _status_text(entry), 11, Color("a9c4d7"))
		_label(row, "%d W" % int(entry["wins"]), 11, Color("e8ce80"))

func _update_results(match_state: MatchController) -> void:
	var ranking := match_state.get_ranking()
	var winner := "NO FINISHERS"
	if not ranking.is_empty() and match_state.get_status(ranking[0]) == MatchController.Status.FINISHED:
		winner = "%s WINS!" % str(match_state.roster[ranking[0]]["name"]).replace("[", "")
	var lines := "[center][font_size=27][color=#ffd879]%s[/color][/font_size]\n[font_size=16]ROUND %d RESULTS[/font_size]\n\n" % [winner, match_state.round_number]
	for id in ranking:
		var entry: Dictionary = match_state.roster[id]
		var place := ordinal(int(entry["place"])) if int(entry["status"]) == MatchController.Status.FINISHED else "—"
		lines += "%s  %s  ·  %s\n" % [place, str(entry["name"]).replace("[", ""), _status_text(entry)]
	lines += "\nNext round in %d s[/center]" % int(ceil(match_state.time_left))
	_results.text = lines

func _status_text(entry: Dictionary) -> String:
	match int(entry["status"]):
		MatchController.Status.WAITING: return "READY" if bool(entry["ready"]) else "NOT READY"
		MatchController.Status.ALIVE: return "RACING"
		MatchController.Status.OUT: return "OUT"
		MatchController.Status.FINISHED: return "%s · %.1fs" % [ordinal(int(entry["place"])), float(entry["time"])]
	return "SPECTATING"

func _panel(parent: Control, width: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.09, 0.16, 0.9), Color("38617c"), 1, 10))
	parent.add_child(panel)
	return panel

func _column(panel: PanelContainer, spacing: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 7)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", spacing)
	margin.add_child(column)
	return column

func _label(parent: Control, value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Control, value: String, fill: Color) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(112, 35)
	button.add_theme_stylebox_override("normal", _style(fill, fill.lightened(0.2), 1, 7))
	button.add_theme_stylebox_override("hover", _style(fill.lightened(0.16), Color("a4ddff"), 1, 7))
	button.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(button)
	return button

func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
