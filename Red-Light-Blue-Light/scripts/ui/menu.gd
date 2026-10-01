class_name RaceMenu
extends CanvasLayer
## Responsive connection menu with LAN details and a compact rules guide.

signal host_requested(player_name: String, port: int)
signal join_requested(address: String, player_name: String, port: int)
signal quit_requested()

var _name: LineEdit
var _address: LineEdit
var _port: LineEdit
var _status: Label

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.055, 0.1, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 530.0
	panel.add_theme_stylebox_override("panel", _style(Color("101d31"), Color("367ea6"), 2, 18))
	center.add_child(panel)
	var padding := MarginContainer.new()
	for side in ["left", "right"]:
		padding.add_theme_constant_override("margin_" + side, 21)
	for side in ["top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 15)
	panel.add_child(padding)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	padding.add_child(column)
	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.scroll_active = false
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.custom_minimum_size.y = 52
	title.text = "[center][font_size=34][b][color=#ff5b70]RED LIGHT[/color], [color=#48baff]BLUE LIGHT[/color][/b][/font_size][/center]"
	column.add_child(title)
	column.add_child(_label("YOUR FIRST MULTIPLAYER GAME  ·  2–8 RUNNERS", 13, Color("9eb5ca")))
	_name = _field(column, "NAME", "Player", "Player")
	_address = _field(column, "ADDRESS", "127.0.0.1", "127.0.0.1")
	_port = _field(column, "PORT", "7777", "7777")
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	column.add_child(actions)
	var host := _button(actions, "HOST GAME", Color("12699d"))
	host.pressed.connect(func() -> void: host_requested.emit(_name.text, _port_number()))
	var join := _button(actions, "JOIN GAME", Color("2a526e"))
	join.pressed.connect(func() -> void: join_requested.emit(_address.text, _name.text, _port_number()))
	_status = _label("Choose Host or Join", 15, Color("e6d791"))
	column.add_child(_status)
	var addresses: Array[String] = []
	for address in IP.get_local_addresses():
		if address.is_valid_ip_address() and ":" not in address and not address.begins_with("127."):
			addresses.append(address)
	column.add_child(_label("LAN IPv4: " + (", ".join(addresses) if not addresses.is_empty() else "unavailable"), 12, Color("92b5ce")))
	column.add_child(HSeparator.new())
	column.add_child(_label("BLUE = RUN  ·  RED = FREEZE  ·  REACH THE FINISH", 13, Color("d9e5ee")))
	column.add_child(_label("WASD move  ·  Mouse look  ·  Shift sprint  ·  Space jump\nF / click shove  ·  R ready  ·  Enter start  ·  Esc free mouse", 12, Color("9eb5ca")))
	var quit := _button(column, "QUIT", Color("303d53"))
	quit.custom_minimum_size.y = 32
	quit.pressed.connect(func() -> void: quit_requested.emit())

func set_status(message: String) -> void:
	if _status != null:
		_status.text = message

func _port_number() -> int:
	return clampi(int(_port.text), 1, 65535)

func _field(parent: VBoxContainer, caption: String, hint: String, value: String) -> LineEdit:
	parent.add_child(_label(caption, 12, Color("80bce0")))
	var field := LineEdit.new()
	field.placeholder_text = hint
	field.text = value
	field.custom_minimum_size.y = 31
	field.add_theme_stylebox_override("normal", _style(Color("192c44"), Color("345b78"), 1, 7))
	field.add_theme_stylebox_override("focus", _style(Color("192c44"), Color("55b8f2"), 2, 7))
	field.add_theme_color_override("font_color", Color("eaf4fc"))
	field.add_theme_color_override("font_placeholder_color", Color("849aaf"))
	parent.add_child(field)
	return field

func _button(parent: Control, label: String, fill: Color) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 37
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", _style(fill, fill.lightened(0.2), 1, 8))
	button.add_theme_stylebox_override("hover", _style(fill.lightened(0.18), Color("a4ddff"), 1, 8))
	button.add_theme_stylebox_override("pressed", _style(fill.darkened(0.18), Color("a4ddff"), 1, 8))
	button.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(button)
	return button

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
