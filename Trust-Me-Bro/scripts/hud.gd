extends CanvasLayer
## Party graphics remain presentation only; RoundManager and NetworkSession own state.
signal start_requested(humans: int)
signal restart_requested
signal quit_to_menu_requested
signal mute_requested
signal pause_requested
signal host_requested(player_name: String, port: int)
signal join_requested(address: String, player_name: String, port: int)
signal ready_requested(ready: bool)
signal network_start_requested
signal leave_room_requested
signal ui_sound_requested(cue: String)

const CREAM: Color = Color("fff9e8")
const WHITE: Color = Color("ffffff")
const INK: Color = Color("233e73")
const BLUE: Color = Color("458dff")
const CORAL: Color = Color("ff7469")
const MINT: Color = Color("5edcb2")
const YELLOW: Color = Color("ffcf57")
const MUTED: Color = Color("73859b")
const COLORS: Array[Color] = [CORAL, BLUE, MINT, YELLOW, Color("b397ef"), Color("f39ccb"), Color("ffa65f"), Color("65cfdf")]
const LETTERS: Array[String] = ["A", "B", "C", "D"]

class PartyIcon extends Control:
	var tint: Color = Color("ffcf57")
	var kind: String = "star"
	func _draw() -> void:
		var s: float = minf(size.x, size.y)
		var c: Vector2 = size * 0.5
		if kind == "star":
			var shadow: PackedVector2Array = PackedVector2Array()
			var points: PackedVector2Array = PackedVector2Array()
			for i in 10:
				var angle: float = -PI / 2.0 + i * PI / 5.0
				var point: Vector2 = c + Vector2(cos(angle),sin(angle)) * s * (0.47 if i % 2 == 0 else 0.24)
				points.append(point)
				shadow.append(point + Vector2(0,s * 0.065))
			draw_colored_polygon(shadow,tint.darkened(0.22))
			draw_colored_polygon(points,tint)
			draw_circle(c + Vector2(-s * 0.10,-s * 0.05),s * 0.025,Color("233e73"))
			draw_circle(c + Vector2(s * 0.10,-s * 0.05),s * 0.025,Color("233e73"))
		elif kind == "dice":
			draw_style_box(_box(tint.darkened(0.18),int(s * 0.20)),Rect2(0,s * 0.08,s,s * 0.88))
			draw_style_box(_box(tint,int(s * 0.20)),Rect2(0,0,s,s * 0.88))
			for at: Vector2 in [Vector2(0.28,0.25),Vector2(0.72,0.25),Vector2(0.5,0.44),Vector2(0.28,0.64),Vector2(0.72,0.64)]:
				draw_circle(at * s,s * 0.065,WHITE)
		else:
			draw_circle(c + Vector2(-s * 0.25,-s * 0.20),s * 0.17,tint.darkened(0.10))
			draw_circle(c + Vector2(s * 0.25,-s * 0.20),s * 0.17,tint.darkened(0.10))
			draw_circle(c + Vector2(0,s * 0.03),s * 0.43,tint.darkened(0.12))
			draw_circle(c,s * 0.42,tint)
			draw_circle(c + Vector2(0,s * 0.08),s * 0.28,CREAM)
			draw_circle(c + Vector2(-s * 0.12,s * 0.015),s * 0.046,INK)
			draw_circle(c + Vector2(s * 0.12,s * 0.015),s * 0.046,INK)
			draw_arc(c + Vector2(0,s * 0.09),s * 0.09,0.25,PI - 0.25,12,INK,s * 0.025,true)
	func _box(color: Color,radius: int) -> StyleBoxFlat:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(radius)
		return style

var root: Control
var menu: Control
var game: Control
var banner: Panel
var pause_overlay: Control
var help_overlay: Control
var results_overlay: Control
var lobby: Control
var _title_font: Font
var _body_font: Font
var _data_font: Font
var _start_button: Button
var _restart_button: Button
var _round_label: Label
var _rule_label: Label
var _question: Label
var _question_count: Label
var _question_panel: Panel
var _answer_row: HBoxContainer
var _category_label: Label
var _difficulty_label: Label
var _timer: Label
var _timer_panel: Panel
var _timer_bar: ProgressBar
var _status_panel: Panel
var _status: Label
var _perk: Label
var _banner_title: Label
var _banner_subtitle: Label
var _banner_eyebrow: Label
var _answers: Array[PanelContainer] = []
var _answer_labels: Array[Label] = []
var _human_buttons: Array[Button] = []
var _human_note: Label
var _player_cards: Array[Panel] = []
var _player_names: Array[Label] = []
var _player_scores: Array[Label] = []
var _player_states: Array[Label] = []
var _player_icons: Array[PartyIcon] = []
var _player_portraits: Array[TextureRect] = []
var _round_tokens: Array[Panel] = []
var _round_token_labels: Array[Label] = []
var _flash: Label
var _flash_panel: Panel
var _flash_timer: float = 0.0
var _banner_tween: Tween
var _selected_humans: int = 1
var _muted: bool = false
var _sound_button: Button
var _spectator: bool = false
var _results_rows: VBoxContainer
var _winner_label: Label
var _round_index: int = 0
var _name_input: LineEdit
var _address_input: LineEdit
var _port_input: LineEdit
var _connection_status: Label
var _lobby_status: Label
var _lobby_role: Label
var _lobby_cards: Array[Panel] = []
var _lobby_names: Array[Label] = []
var _lobby_states: Array[Label] = []
var _lobby_icons: Array[PartyIcon] = []
var _lobby_portraits: Array[TextureRect] = []
var _ready_button: Button
var _network_start_button: Button
var _lobby_leave_button: Button
var _result_menu_button: Button
var _local_ready: bool = false
var _network_enabled: bool = false
var _network_host: bool = false
var _overlay_shades: Array[ColorRect] = []
var _explanation: String = ""
var _pause_note: Label
var _local_player_index: int = 0
var _local_safe: bool = true
var _score_cache: Array = []
var _pause_sound: Button
var _title_page: Control
var _setup_page: Control
var _setup_title: Label
var _setup_note: Label
var _couch_form: Control
var _online_tabs: Control
var _online_form: Control
var _host_submit: Button
var _join_submit: Button
var _title_play_button: Button
var _back_button: Button
var _menu_page: String = "title"
var _setup_mode: String = "couch"
var _address_caption: Label
var _settings_overlay: Control
var _countdown: Label
var _gacha: Panel
var _gacha_cards: Array[Panel] = []
var _gacha_names: Array[Label] = []
var _gacha_perks: Array[Label] = []
var _gacha_notes: Array[Label] = []
var _gacha_portraits: Array[TextureRect] = []
var _winner_portrait: TextureRect
var _winner_score: Label
var _resume_button: Button
var _help_close: Button
var _settings_close: Button
var _settings_sound: Button
var _port_caption: Label
var _host_tab: Button
var _join_tab: Button
var _button_tweens: Dictionary = {}
var _last_focus: Control
var _banner_is_reveal: bool = false

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var title_variation: FontVariation = FontVariation.new()
	title_variation.base_font = load("res://assets/fonts/Fredoka.ttf")
	title_variation.variation_opentype = {2003265652: 680.0,2003072104: 100.0}
	_title_font = title_variation
	var body_variation: FontVariation = FontVariation.new()
	body_variation.base_font = load("res://assets/fonts/DMSans.ttf")
	body_variation.variation_opentype = {2003265652: 600.0}
	_body_font = body_variation
	var data_variation: FontVariation = FontVariation.new()
	data_variation.base_font = body_variation.base_font
	data_variation.variation_opentype = {2003265652: 750.0}
	data_variation.opentype_features = {"tnum": 1,"lnum": 1}
	_data_font = data_variation
	root = Control.new()
	root.name = "PartyGraphics"
	root.size = Vector2(1280,800)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme: Theme = Theme.new()
	theme.default_font = _body_font
	theme.default_font_size = 16
	root.theme = theme
	menu = _screen("ChooseYourParty")
	game = _screen("PartyHUD")
	lobby = _screen("FriendsLobby")
	_build_menu()
	_build_game()
	_build_lobby()
	_build_banner()
	_build_pause()
	_build_help()
	_build_results()
	_build_utilities()
	_build_settings()
	_flash_panel = _panel(root,Rect2(240,692,800,26),INK,16)
	_flash = _label(_flash_panel,"",14,WHITE,Rect2(15,0,770,26))
	_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_flash.clip_text = true
	_flash_panel.hide()
	get_viewport().size_changed.connect(_fit)
	_fit()
	show_menu()

func _fit() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var fit: float = minf(view.x / 1280.0,view.y / 800.0)
	root.scale = Vector2.ONE * fit
	root.position = (view - Vector2(1280,800) * fit) * 0.5
	for shade: ColorRect in _overlay_shades:
		shade.position = -root.position / fit
		shade.size = view / fit

func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0: _flash_panel.hide()

func _screen(node_name: String) -> Control:
	var control: Control = Control.new()
	control.name = node_name
	control.size = Vector2(1280,800)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(control)
	return control

func _style(color: Color,radius: int = 20,outline: Color = Color.TRANSPARENT,width: int = 0,shadow: bool = false) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = outline
	style.set_border_width_all(width)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	if shadow:
		style.shadow_color = Color(0.09,0.23,0.40,0.24)
		style.shadow_size = 5
		style.shadow_offset = Vector2(0,5)
	return style

func _panel(parent: Node,rect: Rect2,color: Color,radius: int = 20,outline: Color = Color.TRANSPARENT,width: int = 0,shadow: bool = false) -> Panel:
	var panel: Panel = Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",_style(color,radius,outline,width,shadow))
	parent.add_child(panel)
	return panel

func _label(parent: Node,content: String,font_size: int,color: Color,rect: Rect2 = Rect2(),display: bool = false) -> Label:
	var label: Label = Label.new()
	label.text = content
	label.position = rect.position
	label.size = rect.size
	label.clip_text = rect.size.x > 0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",_title_font if display else _body_font)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
	if rect.size.x > 0: label.set_deferred("size",rect.size)
	return label

func _outlined(label: Label,width: int = 4,color: Color = INK) -> void:
	label.add_theme_constant_override("outline_size",width)
	label.add_theme_color_override("font_outline_color",color)
	label.add_theme_constant_override("shadow_offset_y",3)
	label.add_theme_color_override("font_shadow_color",Color(0.05,0.18,0.34,0.28))

func _button(parent: Node,content: String,rect: Rect2,color: Color = BLUE,text_color: Color = WHITE,font_size: int = 19) -> Button:
	var button: Button = Button.new()
	button.text = content
	button.position = rect.position
	button.size = rect.size
	button.custom_minimum_size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font",_title_font)
	button.add_theme_font_size_override("font_size",font_size)
	for state: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,text_color)
	button.add_theme_color_override("font_disabled_color",MUTED)
	button.add_theme_stylebox_override("normal",_style(color,16,Color.TRANSPARENT,0))
	button.add_theme_stylebox_override("hover",_style(color.lightened(0.09),16,WHITE,2))
	button.add_theme_stylebox_override("pressed",_style(color.darkened(0.10),16))
	button.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,16,YELLOW,4))
	button.add_theme_stylebox_override("disabled",_style(Color("dbe5e8"),16))
	parent.add_child(button)
	button.pivot_offset = rect.size * 0.5
	button.mouse_entered.connect(_animate_button.bind(button,1.035))
	button.mouse_entered.connect(func() -> void: ui_sound_requested.emit("ui_hover"))
	button.focus_entered.connect(func() -> void: ui_sound_requested.emit("ui_hover"))
	button.pressed.connect(func() -> void: ui_sound_requested.emit("ui_confirm"))
	button.mouse_exited.connect(_animate_button.bind(button,1.0))
	button.focus_entered.connect(_animate_button.bind(button,1.025))
	button.focus_exited.connect(_animate_button.bind(button,1.0))
	return button

func _animate_button(button: Button,amount: float) -> void:
	var key: int = button.get_instance_id()
	if _button_tweens.has(key) and _button_tweens[key].is_valid(): _button_tweens[key].kill()
	var tween: Tween = button.create_tween()
	_button_tweens[key] = tween
	tween.tween_property(button,"scale",Vector2.ONE * amount,0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _trap_focus(controls: Array[Control]) -> void:
	for i in controls.size():
		var control: Control = controls[i]
		var previous: NodePath = controls[(i - 1 + controls.size()) % controls.size()].get_path()
		var next: NodePath = controls[(i + 1) % controls.size()].get_path()
		control.focus_previous = previous
		control.focus_next = next
		control.focus_neighbor_top = previous
		control.focus_neighbor_bottom = next
		control.focus_neighbor_left = control.get_path()
		control.focus_neighbor_right = control.get_path()

func _pill(parent: Node,content: String,rect: Rect2,color: Color,text_color: Color = INK,font_size: int = 13) -> Panel:
	var panel: Panel = _panel(parent,rect,color,int(rect.size.y / 2.0),WHITE,2)
	var label: Label = _label(panel,content,font_size,text_color,Rect2(8,0,rect.size.x - 16,rect.size.y),true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return panel

func _icon(parent: Node,at: Vector2,s: float,tint: Color,kind: String = "star") -> PartyIcon:
	var icon: PartyIcon = PartyIcon.new()
	icon.position = at
	icon.size = Vector2.ONE * s
	icon.tint = tint
	icon.kind = kind
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon

func _portrait(parent: Node,at: Vector2,dimensions: Vector2,index: int) -> TextureRect:
	var portrait: TextureRect = TextureRect.new()
	portrait.position = at
	portrait.size = dimensions
	portrait.custom_minimum_size = dimensions
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path: String = "res://assets/characters/portraits/avatar_%d.png" % [index % 8]
	if ResourceLoader.exists(path): portrait.texture = load(path)
	parent.add_child(portrait)
	return portrait

func _entry(parent: Node,content: String,placeholder: String,rect: Rect2) -> LineEdit:
	var field: LineEdit = LineEdit.new()
	field.position = rect.position
	field.size = rect.size
	field.text = content
	field.placeholder_text = placeholder
	field.max_length = 64
	field.add_theme_font_size_override("font_size",15)
	field.add_theme_color_override("font_color",INK)
	field.add_theme_color_override("caret_color",INK)
	field.add_theme_stylebox_override("normal",_style(Color("edf6fb"),13,Color("d7e7ef"),2))
	field.add_theme_stylebox_override("focus",_style(WHITE,13,BLUE,3))
	parent.add_child(field)
	return field

func _build_menu() -> void:
	# The title has one clear action; party details appear only on the next screen.
	_title_page = Control.new()
	_title_page.size = Vector2(1280,800)
	_title_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(_title_page)
	var logo_back: Panel = _panel(_title_page,Rect2(32,53,456,237),INK,34)
	logo_back.rotation = -0.025
	_label(logo_back,"Trust me,",70,CREAM,Rect2(24,5,408,99),true)
	_label(logo_back,"BRO!",112,YELLOW,Rect2(27,83,401,130),true)
	_icon(logo_back,Vector2(342,124),68,CORAL).rotation = 0.22
	var tagline: Label = _label(_title_page,"A quiz party. A terrible idea.",22,INK,Rect2(53,303,460,42),true)
	_outlined(tagline,3,CREAM)
	_title_play_button = _button(_title_page,"Play party",Rect2(56,373,356,68),CORAL,INK,30)
	_title_play_button.pressed.connect(_open_setup.bind("couch"))
	var online: Button = _button(_title_page,"Play online",Rect2(56,456,356,57),CREAM,INK,24)
	online.pressed.connect(_open_setup.bind("host"))
	var how: Button = _button(_title_page,"How to play",Rect2(56,531,171,46),INK,CREAM,18)
	how.pressed.connect(_open_help)
	var settings: Button = _button(_title_page,"Settings",Rect2(241,531,171,46),INK,CREAM,18)
	settings.pressed.connect(_open_settings)
	_title_play_button.focus_neighbor_bottom = online.get_path()
	_title_play_button.focus_neighbor_top = how.get_path()
	online.focus_neighbor_top = _title_play_button.get_path()
	online.focus_neighbor_bottom = how.get_path()
	how.focus_neighbor_top = online.get_path()
	how.focus_neighbor_bottom = _title_play_button.get_path()
	how.focus_neighbor_right = settings.get_path()
	settings.focus_neighbor_top = online.get_path()
	settings.focus_neighbor_bottom = _title_play_button.get_path()
	settings.focus_neighbor_left = how.get_path()
	var footer: Label = _label(_title_page,"1–8 players   •   5 rounds   •   Trust nobody",15,CREAM,Rect2(54,707,460,29))
	_outlined(footer,3,INK)
	_pill(_title_page,"MEET YOUR COMPETITION",Rect2(731,688,310,34),INK,CREAM,14)
	_setup_page = Control.new()
	_setup_page.size = Vector2(1280,800)
	_setup_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(_setup_page)
	var panel: Panel = _panel(_setup_page,Rect2(40,72,488,658),CREAM,30)
	_back_button = _button(panel,"‹  Back",Rect2(25,22,103,38),Color("e6eaf0"),INK,17)
	_back_button.pressed.connect(_back_to_title)
	_setup_title = _label(panel,"Couch party",37,INK,Rect2(27,78,440,53),true)
	_setup_note = _label(panel,"One screen. Eight contestants. Pick your crew.",15,MUTED,Rect2(28,137,430,48))
	_setup_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(panel,"YOUR NAME",12,INK,Rect2(28,199,430,22),true)
	_name_input = _entry(panel,"Player","Your name",Rect2(27,226,434,46))
	_name_input.max_length = 18
	_couch_form = Control.new()
	_couch_form.position = Vector2(0,294)
	_couch_form.size = Vector2(488,294)
	panel.add_child(_couch_form)
	_label(_couch_form,"HOW MANY HUMANS?",12,INK,Rect2(28,5,430,22),true)
	for i in 4:
		var button: Button = _button(_couch_form,str(i + 1),Rect2(28 + i * 111,39,101,56),CORAL if i == 0 else Color("e1e8f0"),INK,27)
		_human_buttons.append(button)
		button.pressed.connect(_select_humans.bind(i + 1))
	_human_note = _label(_couch_form,"7 bots will join the party.",15,MUTED,Rect2(28,112,434,30))
	var input_note: Label = _label(_couch_form,"P1: keyboard or gamepad
P2: arrow keys • P3–4: extra gamepads",14,INK,Rect2(28,154,434,52))
	input_note.add_theme_constant_override("line_spacing",5)
	_start_button = _button(_couch_form,"Let's party!",Rect2(28,228,434,58),CORAL,INK,27)
	_start_button.pressed.connect(func() -> void: start_requested.emit(_selected_humans))
	_online_tabs = Control.new()
	_online_tabs.position = Vector2(27,294)
	_online_tabs.size = Vector2(434,46)
	panel.add_child(_online_tabs)
	_host_tab = _button(_online_tabs,"Host a room",Rect2(0,0,210,43),INK,CREAM,18)
	_host_tab.pressed.connect(_open_setup.bind("host"))
	_join_tab = _button(_online_tabs,"Join friends",Rect2(224,0,210,43),Color("dfe7ee"),INK,18)
	_join_tab.pressed.connect(_open_setup.bind("join"))
	_online_form = Control.new()
	_online_form.position = Vector2(27,359)
	_online_form.size = Vector2(434,220)
	panel.add_child(_online_form)
	_address_caption = _label(_online_form,"HOST ADDRESS",12,INK,Rect2(0,0,294,20),true)
	_address_input = _entry(_online_form,"127.0.0.1","192.168.1.10",Rect2(0,27,294,46))
	_port_caption = _label(_online_form,"PORT",12,INK,Rect2(310,0,124,20),true)
	_port_input = _entry(_online_form,"24816","24816",Rect2(310,27,124,46))
	_port_input.max_length = 5
	var network_note: Label = _label(_online_form,"Play over LAN or direct IP. Share your host address with friends; empty seats become bots.",14,MUTED,Rect2(0,91,434,67))
	network_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_host_submit = _button(_online_form,"Create room",Rect2(0,163,434,58),BLUE,WHITE,27)
	_host_submit.pressed.connect(_request_host)
	_join_submit = _button(_online_form,"Join room",Rect2(0,163,434,58),BLUE,WHITE,27)
	_join_submit.pressed.connect(_request_join)
	_connection_status = _label(panel,"",13,CORAL.darkened(0.35),Rect2(28,596,430,45))
	_connection_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_setup_page.hide()

func _open_setup(mode: String) -> void:
	_menu_page = "setup"
	_setup_mode = mode
	_title_page.hide()
	_setup_page.show()
	_connection_status.text = ""
	_couch_form.visible = mode == "couch"
	_online_form.visible = mode != "couch"
	_online_tabs.visible = mode != "couch"
	_host_submit.visible = mode == "host"
	_join_submit.visible = mode == "join"
	_address_input.visible = mode == "join"
	_address_caption.visible = mode == "join"
	_port_caption.position.x = 310 if mode == "join" else 0
	_port_input.position.x = 310 if mode == "join" else 0
	_port_input.size.x = 124 if mode == "join" else 434
	_host_tab.add_theme_stylebox_override("normal",_style(INK if mode == "host" else Color("dfe7ee"),16))
	_join_tab.add_theme_stylebox_override("normal",_style(INK if mode == "join" else Color("dfe7ee"),16))
	for state: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		_host_tab.add_theme_color_override(state,CREAM if mode == "host" else INK)
		_join_tab.add_theme_color_override(state,CREAM if mode == "join" else INK)
	_setup_title.text = "Couch party" if mode == "couch" else ("Host a party" if mode == "host" else "Join the party")
	_setup_note.text = "One screen. Eight contestants. Pick your crew." if mode == "couch" else "Same stage. Same view. Friends everywhere."
	if mode == "couch": _start_button.grab_focus()
	elif mode == "host": _host_submit.grab_focus()
	else: _address_input.grab_focus()

func _back_to_title() -> void:
	_menu_page = "title"
	_title_page.show()
	_setup_page.hide()
	_title_play_button.grab_focus()

func _open_help() -> void:
	_last_focus = get_viewport().gui_get_focus_owner()
	help_overlay.show()
	_help_close.grab_focus()

func _close_help() -> void:
	help_overlay.hide()
	if is_instance_valid(_last_focus) and _last_focus.is_visible_in_tree(): _last_focus.grab_focus()
	elif game.visible: get_viewport().gui_release_focus()

func _open_settings() -> void:
	_last_focus = get_viewport().gui_get_focus_owner()
	_settings_overlay.show()
	_settings_close.grab_focus()

func _close_settings() -> void:
	_settings_overlay.hide()
	if is_instance_valid(_last_focus) and _last_focus.is_visible_in_tree(): _last_focus.grab_focus()

func _player_name() -> String:
	var value: String = _name_input.text.strip_edges()
	return value if not value.is_empty() else "Player"

func _port() -> int:
	if not _port_input.text.is_valid_int(): return 0
	var value: int = _port_input.text.to_int()
	return value if value >= 1024 and value <= 65535 else 0

func _request_host() -> void:
	var port: int = _port()
	if port == 0:
		show_connection_error("Use a port between 1024 and 65535.")
		return
	host_requested.emit(_player_name(),port)

func _request_join() -> void:
	var address: String = _address_input.text.strip_edges()
	if address.is_empty():
		show_connection_error("Enter the host's IP address first.")
		return
	var port: int = _port()
	if port == 0:
		show_connection_error("Use a port between 1024 and 65535.")
		return
	join_requested.emit(address,_player_name(),port)

func _select_humans(amount: int) -> void:
	_selected_humans = clampi(amount,1,4)
	for i in _human_buttons.size():
		_human_buttons[i].add_theme_stylebox_override("normal",_style(CORAL if i == amount - 1 else Color("e1e8f0"),16))
	_human_note.text = "%d bots will join the party." % [8 - _selected_humans]

func _build_game() -> void:
	var round_panel: Panel = _panel(game,Rect2(24,24,130,42),INK,18)
	_round_label = _label(round_panel,"ROUND 1 / 5",15,WHITE,Rect2(11,0,108,42),true)
	_round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rule_label = _label(round_panel,"",14,CREAM,Rect2())
	_rule_label.hide()
	_question_panel = _panel(game,Rect2(228,20,846,90),CREAM,22)
	_category_label = _label(_question_panel,"PARTY MIX",11,BLUE.darkened(0.2),Rect2(21,8,270,21),true)
	_difficulty_label = _label(_question_panel,"",11,MUTED,Rect2(295,8,170,21))
	_question_count = _label(_question_panel,"1 / 2",12,MUTED,Rect2(634,8,190,21))
	_question_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_question = _label(_question_panel,"Ready to test your friendships?",27,INK,Rect2(21,31,804,51),true)
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_answer_row = HBoxContainer.new()
	_answer_row.position = Vector2(228,120)
	_answer_row.size = Vector2(900,54)
	_answer_row.add_theme_constant_override("separation",8)
	game.add_child(_answer_row)
	for i in 4:
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(219,54)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",_style(COLORS[i],15))
		_answer_row.add_child(card)
		_answers.append(card)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation",11)
		card.add_child(row)
		var letter: Label = _label(row,LETTERS[i],27,Color("14284b"),Rect2(),true)
		letter.custom_minimum_size.x = 25
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var answer: Label = _label(row,"",15,Color("14284b"))
		answer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		answer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_answer_labels.append(answer)
	_timer_panel = _panel(game,Rect2(1142,85,114,103),INK,21)

	_timer = _label(_timer_panel,"12",64,WHITE,Rect2(8,3,98,95),true)
	_timer.add_theme_font_override("font",_data_font)
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_bar = ProgressBar.new()
	_timer_bar.position = Vector2(16,84)
	_timer_bar.size = Vector2(82,20)
	_timer_bar.scale.y = 0.22
	_timer_bar.show_percentage = false
	_timer_bar.add_theme_font_size_override("font_size",1)
	_timer_bar.step = 0.0
	_timer_bar.max_value = 1.0
	_timer_bar.value = 1.0
	for key: String in ["background","fill"]:
		var style: StyleBoxFlat = _style(Color("4a6290") if key == "background" else YELLOW,3)
		style.set_content_margin_all(0)
		_timer_bar.add_theme_stylebox_override(key,style)
	_timer_panel.add_child(_timer_bar)
	_timer_bar.hide()
	_status_panel = _panel(game,Rect2(240,692,800,26),INK,16)
	_status = _label(_status_panel,"Stand on your answer before the buzzer.",14,CREAM,Rect2(15,0,770,26))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.clip_text = true
	_perk = _label(game,"",14,YELLOW,Rect2(240,653,800,26),true)
	_perk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_perk.clip_text = true
	_outlined(_perk,3,INK)
	for i in 8:
		var card: Panel = _panel(game,Rect2(24,694,168,82),CREAM,15)
		_player_cards.append(card)
		card.hide()
		var icon: PartyIcon = _icon(card,Vector2(5,5),45,COLORS[i],"face")
		_player_icons.append(icon)
		var portrait: TextureRect = _portrait(card,Vector2(0,7),Vector2(70,75),i)
		_player_portraits.append(portrait)
		icon.visible = portrait.texture == null
		var player_name: Label = _label(card,"Player %d" % [i + 1],11,INK,Rect2(75,11,82,19))
		player_name.clip_text = true
		_player_names.append(player_name)
		var score: Label = _label(card,"0",29,INK,Rect2(75,31,82,39),true)
		score.add_theme_font_override("font",_data_font)
		_player_scores.append(score)
		var state: Label = _label(card,"",11,MUTED,Rect2())
		state.hide()
		_player_states.append(state)
	_question_panel.hide()
	_answer_row.hide()
	_timer_panel.hide()
	_status_panel.hide()
	_perk.hide()

func _build_lobby() -> void:
	var shade: Panel = _panel(lobby,Rect2(80,178,1120,556),CREAM,30)
	_label(shade,"The gang's almost here",39,INK,Rect2(33,22,950,60),true)
	_icon(shade,Vector2(1000,21),63,YELLOW)
	_lobby_role = _label(shade,"YOUR PARTY LOBBY",12,BLUE.darkened(0.15),Rect2(36,88,1050,25),true)
	_lobby_status = _label(shade,"Friends join using the host address and port 24816.",15,MUTED,Rect2(36,123,1048,42))
	_lobby_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in 8:
		var at: Vector2 = Vector2(35 + (i % 4) * 266,184 + floori(float(i) / 4.0) * 108)
		var card: Panel = _panel(shade,Rect2(at,Vector2(252,94)),Color("e5edf1"),19)
		_lobby_cards.append(card)
		var icon: PartyIcon = _icon(card,Vector2(10,17),57,COLORS[i],"face")
		_lobby_icons.append(icon)
		var portrait: TextureRect = _portrait(card,Vector2(-2,-2),Vector2(86,96),i)
		_lobby_portraits.append(portrait)
		icon.visible = portrait.texture == null
		var player_name: Label = _label(card,"Bot %d" % [i + 1],19,INK,Rect2(88,20,154,30),true)
		player_name.clip_text = true
		_lobby_names.append(player_name)
		var state: Label = _label(card,"BOT SEAT",11,MUTED,Rect2(89,54,153,23))
		_lobby_states.append(state)
	_lobby_leave_button = _button(shade,"Leave room",Rect2(35,453,207,57),Color("dfe7ee"),INK,20)
	_lobby_leave_button.pressed.connect(func() -> void: leave_room_requested.emit())
	_label(shade,"8 contestants. Bots fill empty seats.",15,MUTED,Rect2(266,466,482,34))
	_ready_button = _button(shade,"I'm ready!",Rect2(768,453,317,57),BLUE,WHITE,25)
	_ready_button.pressed.connect(func() -> void:
		_local_ready = not _local_ready
		_ready_button.text = "Ready!  ✓" if _local_ready else "I'm ready!"
		ready_requested.emit(_local_ready)
	)
	_network_start_button = _button(shade,"Start party",Rect2(768,453,317,57),CORAL,INK,25)
	_network_start_button.pressed.connect(func() -> void: network_start_requested.emit())
	lobby.hide()

func _build_banner() -> void:
	banner = _panel(root,Rect2(345,274,590,243),CREAM,27)
	_banner_eyebrow = _label(banner,"ROUND 1",14,BLUE,Rect2(25,23,540,28),true)
	_banner_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_title = _label(banner,"Party time!",42,INK,Rect2(27,60,536,75),true)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_subtitle = _label(banner,"The next round is about to begin.",18,INK,Rect2(30,147,530,75))
	_banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.hide()
	_countdown = _label(root,"3",142,YELLOW,Rect2(465,253,350,205),true)
	_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_outlined(_countdown,9,INK)
	_countdown.hide()
	_gacha = _panel(root,Rect2(160,275,960,278),CREAM,28)

	_label(_gacha,"Lucky slop!",35,INK,Rect2(25,18,910,57),true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in 4:
		var card: Panel = _panel(_gacha,Rect2(25 + i * 231,94,217,155),Color("e4ebf0"),19)
		_gacha_cards.append(card)
		var portrait: TextureRect = _portrait(card,Vector2(14,8),Vector2(66,78),i)
		_gacha_portraits.append(portrait)
		var owner_label: Label = _label(card,"Player",16,INK,Rect2(88,23,118,51),true)
		owner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_gacha_names.append(owner_label)
		var perk: Label = _label(card,"Lucky break",21,INK,Rect2(15,90,187,34),true)
		_gacha_perks.append(perk)
		var note: Label = _label(card,"",13,INK,Rect2(15,130,187,51))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_gacha_notes.append(note)
		note.hide()
	_gacha.hide()

func show_countdown(number: int) -> void:
	if number <= 0:
		_countdown.hide()
		return
	banner.hide()
	_gacha.hide()
	if _countdown.text != str(number) or not _countdown.visible:
		_countdown.text = str(number)
		_countdown.show()
		_countdown.pivot_offset = _countdown.size * 0.5
		_countdown.scale = Vector2.ONE * 1.24
		create_tween().tween_property(_countdown,"scale",Vector2.ONE,0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func update_gacha_entries(entries: Array) -> void:
	var descriptions: Dictionary = {
		"Nerd Glasses":"Know the answer. Everybody knows you know.",
		"Last-Second Swapper":"One swap. Someone else's problem.",
		"Heavy Boots":"Twice the weight. Hold your ground.",
		"Pinball Curse":"Extra bounce. Absolutely no dignity.",
		"nerd":"Know the answer. Everybody knows you know.",
		"swapper":"One swap. Someone else's problem.",
		"heavy":"Twice the weight. Hold your ground.",
		"pinball":"Extra bounce. Absolutely no dignity."
	}
	for i in 4:
		_gacha_cards[i].visible = i < entries.size()
		if i >= entries.size(): continue
		var entry: Dictionary = entries[i]
		var perk: String = str(entry.get("perk","Lucky break"))
		_gacha_names[i].text = str(entry.get("name","Player")).replace(" · YOU","")
		_gacha_perks[i].text = {"nerd":"Nerd Glasses","swapper":"Swapper","heavy":"Heavy Boots","pinball":"Pinball Curse"}.get(perk,perk)
		_gacha_notes[i].text = descriptions.get(perk,"A new twist for the next round.")
		var slot: int = int(entry.get("id",i)) % 8
		_gacha_portraits[i].texture = load("res://assets/characters/portraits/avatar_%d.png" % [slot])
		var tint: Color = entry.get("tint",COLORS[slot])
		_gacha_cards[i].add_theme_stylebox_override("panel",_style(tint.lightened(0.68),19,tint,2))

func _overlay(node_name: String) -> Control:
	var screen: Control = _screen(node_name)
	var shade: ColorRect = ColorRect.new()
	shade.size = Vector2(1280,800)
	shade.color = Color(0.06,0.19,0.33,0.68)
	screen.add_child(shade)
	_overlay_shades.append(shade)
	screen.hide()
	return screen

func _build_pause() -> void:
	pause_overlay = _overlay("SnackBreak")
	var card: Panel = _panel(pause_overlay,Rect2(404,142,472,516),CREAM,28)
	_icon(card,Vector2(205,15),55,YELLOW)
	_label(card,"Snack break",38,INK,Rect2(25,76,422,60),true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_note = _label(card,"Catch your breath. Keep your friendships.",16,MUTED,Rect2(28,143,416,52))
	_pause_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_resume_button = _button(card,"Back to the party",Rect2(29,215,414,57),CORAL,INK,25)
	_resume_button.pressed.connect(func() -> void: pause_requested.emit())
	var how: Button = _button(card,"How to play",Rect2(29,289,414,47),INK,CREAM,21)
	how.pressed.connect(_open_help)
	_pause_sound = _button(card,"Sound: on",Rect2(29,351,414,43),Color("e5ecf0"),INK,19)
	_pause_sound.pressed.connect(func() -> void:
		set_muted(not _muted)
		mute_requested.emit()
	)
	var leave: Button = _button(card,"Back to menu",Rect2(29,435,414,43),Color("dfe7ee"),INK,18)
	leave.pressed.connect(func() -> void: quit_to_menu_requested.emit())
	_trap_focus([_resume_button,how,_pause_sound,leave])

func _build_help() -> void:
	help_overlay = _overlay("PartyRules")
	var card: Panel = _panel(help_overlay,Rect2(131,83,1018,634),CREAM,30)
	_label(card,"HOW TO PLAY",13,BLUE,Rect2(33,25,950,28),true)
	_label(card,"Be right. Stay upright.",43,INK,Rect2(33,64,950,65),true)
	var titles: Array[String] = ["Pick your answer","Hold your ground","Get your revenge"]
	var copies: Array[String] = ["Run onto A, B, C or D before the buzzer. Wrong tiles drop!","Shove, dive and bluff your friends. In Cube Chaos, grab the right letter.","Fell off? Throw junk from the balcony. Everyone returns next round."]
	for i in 3:
		var step: Panel = _panel(card,Rect2(33 + i * 322,150,307,192),Color("e8edf0"),19)
		_pill(step,str(i + 1),Rect2(17,15,38,38),COLORS[i],INK,23)
		_label(step,titles[i],22,INK,Rect2(17,67,274,34),true)
		var copy: Label = _label(step,copies[i],15,INK,Rect2(17,111,274,70))
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var headings: Array[String] = ["KEYBOARD / P1","COUCH / P2","GAMEPAD"]
	var keys: Array[String] = ["WASD  move  •  SPACE  jump
F  shove  •  G  dive
H  bluff  •  E  grab","ARROWS  move  •  ENTER  jump
K  shove  •  L  dive
;  bluff  •  O  grab","STICK  move  •  A  jump
X  shove  •  B  dive
RB  bluff  •  Y  grab"]
	for i in 3:
		_label(card,headings[i],12,COLORS[i].darkened(0.28),Rect2(50 + i * 322,372,290,24),true)
		_label(card,keys[i],15,INK,Rect2(50 + i * 322,407,290,87)).add_theme_constant_override("line_spacing",5)
	_label(card,"Nerd Glasses? Hold TAB / SELECT to peek.  •  Balcony? SHOVE throws junk.",13,MUTED,Rect2(35,517,948,25)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help_close = _button(card,"Got it. Let's party!",Rect2(304,563,410,48),BLUE,WHITE,23)
	_help_close.pressed.connect(_close_help)
	_trap_focus([_help_close])

func _build_results() -> void:
	results_overlay = _overlay("PartyResults")
	var card: Panel = _panel(results_overlay,Rect2(122,91,1036,618),CREAM,30)
	var winner_panel: Panel = _panel(card,Rect2(0,0,427,618),INK,30)
	_label(winner_panel,"PARTY CHAMPION",15,YELLOW,Rect2(27,24,373,32),true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_winner_label = _label(winner_panel,"YOU DID IT!",37,CREAM,Rect2(25,73,377,105),true)
	_winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_winner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_winner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon(winner_panel,Vector2(46,205),51,YELLOW).rotation = -0.15
	_icon(winner_panel,Vector2(333,305),37,CORAL).rotation = 0.2
	_winner_portrait = _portrait(winner_panel,Vector2(72,167),Vector2(283,276),0)
	_winner_score = _label(winner_panel,"0 POINTS",27,YELLOW,Rect2(26,442,375,48),true)
	_winner_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(winner_panel,"Brains. Balance. Questionable loyalty.",14,CREAM,Rect2(28,525,371,50)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(card,"The final score",30,INK,Rect2(459,24,547,49),true)
	_results_rows = VBoxContainer.new()
	_results_rows.position = Vector2(459,88)
	_results_rows.size = Vector2(545,374)
	_results_rows.add_theme_constant_override("separation",6)
	card.add_child(_results_rows)
	_restart_button = _button(card,"Another party!",Rect2(459,493,545,54),CORAL,INK,25)
	_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	_result_menu_button = _button(card,"Back to menu",Rect2(459,563,545,35),Color("e2e9ef"),INK,17)
	_result_menu_button.pressed.connect(func() -> void: quit_to_menu_requested.emit())

func _build_utilities() -> void:
	# Settings and controls live behind menus; the stage gets one pause control.
	_sound_button = _button(root,"♪",Rect2(1146,20,47,40),INK,CREAM,23)
	_sound_button.focus_mode = Control.FOCUS_NONE
	_sound_button.hide()
	var pause: Button = _button(game,"Ⅱ",Rect2(1206,24,47,40),INK,CREAM,20)
	pause.tooltip_text = "Pause · Esc / Start"
	pause.focus_mode = Control.FOCUS_NONE
	pause.pressed.connect(func() -> void: pause_requested.emit())

func _build_settings() -> void:
	_settings_overlay = _overlay("PartySettings")
	var card: Panel = _panel(_settings_overlay,Rect2(400,213,480,374),CREAM,28)
	_label(card,"Make yourself comfy",33,INK,Rect2(30,27,420,70),true).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(card,"SOUND",12,BLUE,Rect2(31,122,418,23),true)
	_settings_sound = _button(card,"Music & sound: on",Rect2(30,160,420,55),INK,CREAM,22)
	_settings_sound.pressed.connect(func() -> void:
		set_muted(not _muted)
		mute_requested.emit()
		_settings_sound.text = "Music & sound: off" if _muted else "Music & sound: on"
	)
	_label(card,"Shared camera • No camera shake",14,MUTED,Rect2(31,236,418,35))
	_settings_close = _button(card,"All set",Rect2(30,298,420,49),CORAL,INK,23)
	_settings_close.pressed.connect(_close_settings)
	_trap_focus([_settings_sound,_settings_close])

func show_menu() -> void:
	_score_cache.clear()
	_connection_status.text = ""
	menu.show()
	game.hide()
	lobby.hide()
	hide_banner()
	pause_overlay.hide()
	help_overlay.hide()
	_settings_overlay.hide()
	results_overlay.hide()
	_flash_panel.hide()
	_local_ready = false
	_back_to_title()

func show_game() -> void:
	get_viewport().gui_release_focus()
	menu.hide()
	lobby.hide()
	game.show()
	pause_overlay.hide()
	help_overlay.hide()
	_settings_overlay.hide()
	results_overlay.hide()
	_spectator = false

func update_round(index: int,title: String,rule: String) -> void:
	set_question_visible(false)
	_round_index = index
	_round_label.text = "ROUND %d / 5" % [index + 1]
	_rule_label.text = title.capitalize()
	_rule_label.tooltip_text = rule
	for i in _round_tokens.size():
		_round_tokens[i].modulate = WHITE if i <= index else Color(0.65,0.75,0.85,0.65)
		_round_token_labels[i].text = "✓" if i < index else str(i + 1)

func update_question(prompt: String,answers: Array,question_number: int,total: int) -> void:
	set_question_visible(true)
	_countdown.hide()
	_banner_is_reveal = false
	_explanation = ""
	_question.text = prompt
	_question.add_theme_font_size_override("font_size",24 if prompt.length() > 78 else (25 if prompt.length() > 66 else 27))
	_question_count.text = "QUESTION %d / %d" % [question_number,total]
	_category_label.text = "CUBE CHAOS" if _round_index == 2 else "PARTY MIX"
	_difficulty_label.text = ""
	for i in 4:
		_answer_labels[i].text = str(answers[i]) if i < answers.size() else "—"
		_answer_labels[i].add_theme_font_size_override("font_size",13 if _answer_labels[i].text.length() > 23 else 15)
		_answers[i].modulate = WHITE
		_answers[i].add_theme_stylebox_override("panel",_style(COLORS[i],15))

func update_question_metadata(category: String,difficulty: String,explanation: String = "") -> void:
	_category_label.text = category.to_upper()
	_difficulty_label.text = difficulty.capitalize()
	_difficulty_label.add_theme_color_override("font_color",MINT.darkened(0.35) if difficulty == "easy" else (Color("bd8d28") if difficulty == "medium" else CORAL.darkened(0.22)))
	_explanation = explanation

func update_timer(seconds: float,total: float) -> void:
	if _banner_is_reveal and banner.visible:
		_timer.text = "0"
		_timer_bar.value = 0.0
		return
	_timer.text = str(maxi(0,int(ceil(seconds))))
	_timer.add_theme_color_override("font_color",CORAL if seconds <= 3.0 else WHITE)
	_timer_bar.value = clampf(seconds / maxf(total,0.1),0.0,1.0)

func set_local_player(index: int) -> void:
	var selected: int = clampi(index,0,7)
	if selected == _local_player_index: return
	_local_player_index = selected
	if not _score_cache.is_empty(): update_scores(_score_cache)

func update_scores(contestants: Array) -> void:
	_score_cache = contestants.duplicate()
	for i in _player_cards.size():
		_player_cards[i].visible = i == _local_player_index and i < contestants.size()
		if i >= contestants.size(): continue
		var actor: Variant = contestants[i]
		_player_names[i].text = "YOU" if bool(actor.active) else "BALCONY"
		_player_names[i].tooltip_text = str(actor.display_name)
		_player_scores[i].text = str(int(actor.score))
		_player_icons[i].tint = actor.tint
		_player_icons[i].queue_redraw()
		var alive: bool = bool(actor.active)
		_player_cards[i].add_theme_stylebox_override("panel",_style(CREAM if alive else Color("d7e0e8"),18))
		_player_portraits[i].modulate.a = 1.0 if alive else 0.54
		if i == _local_player_index: _local_safe = alive
	if _banner_is_reveal:
		_banner_title.text = "SAFE!" if _local_safe else "NOPE!"
		banner.add_theme_stylebox_override("panel",_style(MINT if _local_safe else CORAL,22))

func set_status(content: String) -> void:
	# Retained for state consumers. The studio screen carries all match copy.
	_status.text = content
	_status.hide()
	_status_panel.hide()

func set_perk(content: String) -> void:
	_perk.hide()
	_perk.text = content
	# The secret peek is a single answer letter while its button is held.
	var secret: int = content.find("SECRET: ")
	if secret >= 0:
		_perk.text = content.substr(secret + 8,1)
		_perk.position = Vector2(210,713)
		_perk.size = Vector2(64,52)
		_perk.add_theme_font_size_override("font_size",35)
		_perk.show()

func show_banner(title: String,subtitle: String,color: Color = MINT) -> void:
	var display_title: String = title
	if title.begins_with("ROUND ") and title.contains("/"): display_title = title.get_slice("/",1).strip_edges().capitalize()
	if _banner_tween and _banner_tween.is_valid(): _banner_tween.kill()
	_countdown.hide()
	_banner_is_reveal = title.contains(" · ") and (title.begins_with("A") or title.begins_with("B") or title.begins_with("C") or title.begins_with("D"))
	if title.to_upper().contains("LUCKY SLOP"):
		banner.hide()
		_gacha.show()
		_status_panel.hide()
		_perk.hide()
		return
	_gacha.hide()
	if _banner_is_reveal:
		_timer.text = "0"
		_timer_bar.value = 0.0
		_timer_panel.hide()
		display_title = "SAFE!" if _local_safe else "NOPE!"
		banner.position = Vector2(515,706)
		banner.size = Vector2(250,62)
		_banner_eyebrow.hide()
		_banner_subtitle.hide()
		_banner_title.position = Vector2(12,0)
		_banner_title.size = Vector2(226,62)
		_banner_title.add_theme_font_size_override("font_size",35)
		banner.add_theme_stylebox_override("panel",_style(MINT if _local_safe else CORAL,22))
	else:
		banner.position = Vector2(345,274)
		banner.size = Vector2(590,243)
		_banner_subtitle.show()
		_banner_eyebrow.show()
		_banner_eyebrow.text = "ROUND %d" % [_round_index + 1]
		_banner_title.position = Vector2(27,60)
		_banner_title.size = Vector2(536,75)
		_banner_title.add_theme_font_size_override("font_size",32 if display_title.length() > 24 else 42)
		_banner_subtitle.position = Vector2(30,147)
		_banner_subtitle.size = Vector2(530,75)
		_banner_subtitle.add_theme_font_size_override("font_size",15 if subtitle.length() > 130 else 18)
		banner.add_theme_stylebox_override("panel",_style(CREAM,27))
	_banner_title.text = display_title
	_banner_subtitle.text = subtitle
	banner.show()
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2.ONE * (0.97 if _banner_is_reveal else 0.88)
	banner.modulate.a = 0.0
	_banner_tween = create_tween().set_parallel(true)
	_banner_tween.tween_property(banner,"scale",Vector2.ONE,0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(banner,"modulate:a",1.0,0.12)

func hide_banner() -> void:
	_banner_is_reveal = false
	if _banner_tween and _banner_tween.is_valid(): _banner_tween.kill()
	banner.hide()
	_countdown.hide()
	_gacha.hide()

func reveal_answer(index: int) -> void:
	for i in _answers.size():
		_answers[i].modulate = WHITE if i == index else Color(0.65,0.72,0.82,0.60)
		if i == index: _answers[i].add_theme_stylebox_override("panel",_style(COLORS[i],15,WHITE,4))
	if not _explanation.is_empty(): set_status(_explanation)

func show_results(contestants: Array) -> void:
	hide_banner()
	pause_overlay.hide()
	help_overlay.hide()
	results_overlay.show()
	var ordered: Array = contestants.duplicate()
	ordered.sort_custom(func(a: Variant,b: Variant) -> bool: return int(a.score) > int(b.score))
	for child: Node in _results_rows.get_children():
		_results_rows.remove_child(child)
		child.queue_free()
	var best_score: int = int(ordered[0].score) if not ordered.is_empty() else 0
	var tied_winners: int = 0
	for actor: Variant in ordered:
		if int(actor.score) == best_score: tied_winners += 1
	if not ordered.is_empty():
		var winner_name: String = str(ordered[0].display_name).replace(" · YOU","")
		_winner_label.text = "IT'S A TIE!" if tied_winners > 1 else "%s WINS!" % [winner_name.to_upper()]
		_winner_label.add_theme_font_size_override("font_size",30 if winner_name.length() > 16 and tied_winners == 1 else 37)
		_winner_portrait.texture = load("res://assets/characters/portraits/avatar_%d.png" % [int(ordered[0].contestant_id) % 8])
		_winner_score.text = "%d POINTS" % [best_score]
	var last_score: int = -1
	var ranking: int = 0
	for i in ordered.size():
		var actor: Variant = ordered[i]
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(545,41)
		var style: StyleBoxFlat = _style(YELLOW.lightened(0.35) if int(actor.score) == best_score else Color("e7edf1"),11)
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		card.add_theme_stylebox_override("panel",style)
		_results_rows.add_child(card)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		card.add_child(row)
		if int(actor.score) != last_score:
			ranking = i + 1
			last_score = int(actor.score)
		var rank: Label = _label(row,str(ranking),17,INK,Rect2(),true)
		rank.custom_minimum_size.x = 35
		var portrait: TextureRect = _portrait(row,Vector2.ZERO,Vector2(34,34),int(actor.contestant_id))
		portrait.custom_minimum_size = Vector2(34,34)
		var player_name: Label = _label(row,str(actor.display_name).replace(" · YOU"," ★"),16,INK)
		player_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_label(row,"%d" % [int(actor.score)],19,INK,Rect2(),true)
	_restart_button.visible = not _network_enabled or _network_host
	_result_menu_button.text = "LEAVE PARTY" if _network_enabled else "Back to menu"
	if _restart_button.visible:
		_trap_focus([_restart_button,_result_menu_button])
		_restart_button.grab_focus()
	else:
		_trap_focus([_result_menu_button])
		_result_menu_button.grab_focus()

func show_pause(paused: bool) -> void:
	pause_overlay.visible = paused
	if paused:
		hide_banner()
		help_overlay.hide()
		_resume_button.grab_focus()
	elif game.visible:
		get_viewport().gui_release_focus()

func set_spectator(value: bool) -> void:
	_spectator = value
	if value:
		set_status("BALCONY CREW · F / X throws junk. Back next round!")
		set_perk("YOU'RE OUT. YOUR FRIENDS ARE STILL FAIR GAME!")

func flash_message(content: String,color: Color = WHITE) -> void:
	# Audio, character reactions and the studio screen communicate match events.
	_flash.text = content
	_flash.add_theme_color_override("font_color",color)
	_flash_panel.hide()
	_flash_timer = 0.0

func set_muted(value: bool) -> void:
	_muted = value
	_sound_button.text = "×♪" if value else "♪"
	if is_instance_valid(_pause_sound): _pause_sound.text = "Sound: off" if value else "Sound: on"
	if is_instance_valid(_settings_sound): _settings_sound.text = "Music & sound: off" if value else "Music & sound: on"
	_sound_button.tooltip_text = "Sound off · M to enable" if value else "Music & sound · M"

func set_question_visible(value: bool) -> void:
	# The authored 3D studio screen is the only question display.
	_question_panel.hide()
	_answer_row.hide()
	_timer_panel.visible = value

func set_network_role(enabled: bool,host: bool) -> void:
	_network_enabled = enabled
	_network_host = host
	_pause_note.text = "The online party keeps going. Your controls are paused." if enabled else "Catch your breath. Keep your friendships."

func show_lobby(players: Array,is_host: bool,status: String = "") -> void:
	menu.hide()
	game.hide()
	lobby.show()
	hide_banner()
	_settings_overlay.hide()
	results_overlay.hide()
	pause_overlay.hide()
	help_overlay.hide()
	_flash_panel.hide()
	set_network_role(true,is_host)
	_lobby_role.text = "YOU'RE THE HOST · LAN / DIRECT IP" if is_host else "CONNECTED · LAN / DIRECT IP"
	if not status.is_empty(): _lobby_status.text = status
	var ready_to_start: bool = not players.is_empty()
	for i in 8:
		_lobby_names[i].text = "BOT %d" % [i + 1]
		_lobby_states[i].text = "BOT SEAT"
		_lobby_states[i].add_theme_color_override("font_color",MUTED)
		_lobby_icons[i].tint = COLORS[i]
		_lobby_icons[i].modulate.a = 0.48
		_lobby_portraits[i].modulate.a = 0.48
		_lobby_icons[i].queue_redraw()
		_lobby_cards[i].add_theme_stylebox_override("panel",_style(Color("e9f2f6"),20,WHITE,3))
	for player: Variant in players:
		var slot: int = clampi(int(player.get("slot",0)),0,7)
		var is_ready: bool = bool(player.get("ready",false))
		_lobby_names[slot].text = str(player.get("name","Player"))
		_lobby_states[slot].text = "★ HOST" if int(player.get("id",0)) == 1 else ("READY!" if is_ready else "GETTING READY...")
		_lobby_states[slot].add_theme_color_override("font_color",MINT.darkened(0.30) if is_ready else Color("b68b2f"))
		_lobby_icons[slot].modulate.a = 1.0
		_lobby_portraits[slot].modulate.a = 1.0
		_lobby_cards[slot].add_theme_stylebox_override("panel",_style(WHITE,20,COLORS[slot],3))
		if int(player.get("id",0)) != 1 and not is_ready: ready_to_start = false
	_ready_button.visible = not is_host
	_network_start_button.visible = is_host
	_network_start_button.disabled = not ready_to_start
	_network_start_button.text = "Start party" if ready_to_start else "Waiting for friends…"
	var focus: Control = get_viewport().gui_get_focus_owner()
	if not is_instance_valid(focus) or not focus.is_visible_in_tree():
		if is_host and ready_to_start: _network_start_button.grab_focus()
		elif is_host: _lobby_leave_button.grab_focus()
		else: _ready_button.grab_focus()

func set_network_status(message: String) -> void:
	_connection_status.add_theme_font_size_override("font_size",13 if message.length() > 90 else 15)
	_connection_status.text = message
	_connection_status.add_theme_color_override("font_color",BLUE.darkened(0.2))
	_lobby_status.text = message

func show_connection_error(message: String) -> void:
	if menu.visible and not _setup_page.visible: _open_setup(_setup_mode if _setup_mode != "couch" else "join")
	set_network_status(message)
	_connection_status.add_theme_color_override("font_color",CORAL.darkened(0.35))

func _unhandled_input(event: InputEvent) -> void:
	if not menu.visible or not event.is_action_pressed("ui_cancel"): return
	if _settings_overlay.visible: _close_settings()
	elif help_overlay.visible: _close_help()
	elif _setup_page.visible: _back_to_title()
	else: return
	get_viewport().set_input_as_handled()
