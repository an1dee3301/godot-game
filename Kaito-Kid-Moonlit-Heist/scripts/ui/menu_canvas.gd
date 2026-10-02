class_name HeistMenuCanvas
extends Control
## Draws restrained typography and translucent grading over the live museum scene.

const INK := Color(0.018, 0.027, 0.065)
const IVORY := Color(0.96, 0.95, 0.91)
const GOLD := Color(0.88, 0.68, 0.29)
const MUTED := Color(0.66, 0.72, 0.80)

var screen := ""
var data: Dictionary = {}
var reveal := 0.0
var selected := 0
var choices: Array[String] = []
var _serif: SystemFont
var _sans: SystemFont
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Baskerville", "Georgia", "Times New Roman", "serif"])
	_sans = SystemFont.new()
	_sans.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Arial", "sans-serif"])


func _process(delta: float) -> void:
	_time += delta
	if visible:
		queue_redraw()


func ui_scale() -> float:
	return minf(size.x / 1600.0, size.y / 900.0)


func menu_y() -> float:
	match screen:
		"title": return 531.0
		"how_to_play": return 717.0
		"settings": return 765.0
		"pause": return 453.0
		_: return 692.0


func _draw() -> void:
	var scale_ui := ui_scale()
	if scale_ui <= 0.0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_ui)
	var w := size.x / scale_ui
	var h := size.y / scale_ui
	var left := maxf(82.0, (w - 1600.0) * 0.5 + 114.0)
	_draw_grade(w, h)
	match screen:
		"title": _draw_title(left, h)
		"how_to_play": _draw_how(left, h)
		"settings": _draw_settings(left, h)
		"pause": _draw_pause(left, h)
		"game_over": _draw_result(left, h, false)
		"win": _draw_result(left, h, true)
	_draw_choices(left)
	_text("KAITO KID  /  MOONLIT HEIST", Vector2(left, h - 43.0), 12, MUTED)
	_text("© THE PHANTOM THIEF", Vector2(w - 90.0, h - 43.0), 12, MUTED, false, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_grade(w: float, h: float) -> void:
	var dark := 0.48 if screen == "title" else 0.77
	draw_rect(Rect2(0, 0, w, h), Color(INK.r, INK.g, INK.b, 0.23 if screen == "title" else dark))
	for i in 48:
		var t := float(i) / 47.0
		var a := (1.0 - smoothstep(0.0, 1.0, t)) * (0.72 if screen == "title" else 0.58)
		draw_rect(Rect2(w * t, 0, w / 47.0 + 2.0, h), Color(INK.r, INK.g, INK.b, a))
	if screen != "title":
		for i in 12:
			var edge := float(i) * 3.0
			draw_rect(
			Rect2(edge, edge, w - edge * 2.0, h - edge * 2.0),
			Color(0, 0, 0, 0.008), false, 1.0)


func _draw_title(left: float, _h: float) -> void:
	var alpha := clampf(reveal, 0.0, 1.0)
	var rise := (1.0 - alpha) * 28.0
	_text("THE PHANTOM THIEF RETURNS", Vector2(left + 2.0, 224.0 + rise), 16, _fade(GOLD, alpha))
	_text("KAITO KID", Vector2(left - 3.0, 343.0 + rise), 105, _fade(IVORY, alpha), true)
	_text("M O O N L I T   H E I S T", Vector2(left + 3.0, 393.0 + rise), 23, _fade(GOLD, alpha), true)
	draw_line(Vector2(left, 424), Vector2(left + 490.0 * alpha, 424), _fade(GOLD, alpha * 0.68), 1.3)
	_text("A calling card. Five jewels. One impossible escape.", Vector2(left + 2.0, 469.0), 18, _fade(IVORY, alpha * 0.83), true)
	_text("PRESS ENTER TO BEGIN", Vector2(left + 2.0, 808.0), 12, _fade(GOLD, 0.54 + sin(_time * 2.0) * 0.18))


func _draw_how(left: float, _h: float) -> void:
	_kicker(left, "THE PLAN")
	_text("The art of escape", Vector2(left, 264), 66, IVORY, true)
	_rule(left, 291, 680)
	var steps := [
		["01", "TAKE THE JEWELS", "Steal five treasures across the museum."],
		["02", "STAY UNSEEN", "Avoid the light. Crouch, distract, and disappear."],
		["03", "LEAVE NO TRACE", "Disable the vault laser. Reach the balcony glider."]
	]
	for i in steps.size():
		var y := 351.0 + float(i) * 99.0
		_text(steps[i][0], Vector2(left, y), 17, GOLD)
		_text(steps[i][1], Vector2(left + 52, y), 22, IVORY)
		_text(steps[i][2], Vector2(left + 52, y + 27), 16, MUTED)
	_text("WASD  MOVE     MOUSE  LOOK     SHIFT  SPRINT     CTRL / C  SNEAK", Vector2(left, 672), 13, MUTED)
	_text("SPACE  JUMP     E  STEAL     LMB / F  CARD     RMB / Q  SMOKE     ESC  PAUSE", Vector2(left, 694), 13, MUTED)


func _draw_settings(left: float, _h: float) -> void:
	_kicker(left, "TAILOR THE NIGHT")
	_text("Settings", Vector2(left, 252), 72, IVORY, true)
	_rule(left, 279, 680)
	_text("CAMERA", Vector2(left, 332), 13, GOLD)
	_text("AUDIO", Vector2(left, 463), 13, GOLD)
	_text("DISPLAY", Vector2(left, 670), 13, GOLD)


func _draw_pause(left: float, _h: float) -> void:
	_kicker(left, "THE NIGHT IS YOUNG")
	_text("Intermission", Vector2(left, 284), 79, IVORY, true)
	_rule(left, 311, 620)
	_text("The moon waits for no one.", Vector2(left, 361), 24, MUTED, true)


func _draw_result(left: float, _h: float, won: bool) -> void:
	_kicker(left, "A PERFECT ESCAPE" if won else "THE HEIST ENDS HERE")
	_text("IT'S SHOWTIME" if won else "CAUGHT", Vector2(left, 275), 73 if won else 89, IVORY, true)
	_text("the jewels are mine" if won else String(data.get("cause", "Caught by the museum police")), Vector2(left + 2, 321), 25, GOLD if won else MUTED, true)
	_rule(left, 355, 620)
	if won and bool(data.get("new_best", false)):
		_text("NEW RECORD", Vector2(left, 394), 16, GOLD)
	var seconds := int(float(data.get("time", 0.0)))
	var rows := [
		["TIME", "%02d:%02d" % [seconds / 60, seconds % 60]],
		["JEWELS", "%d / %d" % [int(data.get("jewels", 0)), int(data.get("jewels_total", 5))]],
		["GUARDS KNOCKED OUT", str(data.get("knockouts", 0))],
		["TIMES SPOTTED", str(data.get("spotted", 0))]
	]
	if won:
		var best := int(float(data.get("best_time", 0.0)))
		rows.append(["BEST TIME", "%02d:%02d" % [best / 60, best % 60]])
	for i in rows.size():
		var y := 436.0 + float(i) * 45.0
		_text(rows[i][0], Vector2(left, y), 15, MUTED)
		_text(rows[i][1], Vector2(left + 615, y), 21, IVORY, true, HORIZONTAL_ALIGNMENT_RIGHT)
		draw_line(Vector2(left, y + 11), Vector2(left + 615, y + 11), Color(1, 1, 1, 0.13), 1.0)


func _draw_choices(left: float) -> void:
	var y := menu_y()
	for i in choices.size():
		var delay := float(i) * 0.12
		var opacity := clampf((reveal - delay) * 2.2, 0.0, 1.0)
		var active := i == selected
		var x := left + (13.0 if active else 0.0) + (1.0 - opacity) * 20.0
		var row_y := y + float(i) * 47.0
		_text(choices[i], Vector2(x, row_y + 28.0), 23 if screen == "title" else 21, _fade(GOLD if active else IVORY, opacity))
		if active:
			var length := minf(188.0, 26.0 + fposmod(_time * 330.0, 180.0))
			draw_line(Vector2(x, row_y + 36), Vector2(x + length, row_y + 36), _fade(GOLD, opacity), 1.3)
			draw_circle(Vector2(left - 14, row_y + 21), 2.3, _fade(GOLD, opacity))


func _kicker(left: float, value: String) -> void:
	_text(value, Vector2(left, 166), 15, GOLD)


func _rule(left: float, y: float, width: float) -> void:
	draw_line(Vector2(left, y), Vector2(left + width, y), Color(GOLD.r, GOLD.g, GOLD.b, 0.65), 1.0)


func _fade(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * alpha)


func _text(
		value: String, pos: Vector2, font_size: int, color: Color = IVORY,
		serif: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font: Font = _serif if serif else _sans
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if align == HORIZONTAL_ALIGNMENT_RIGHT:
		pos.x -= width
	elif align == HORIZONTAL_ALIGNMENT_CENTER:
		pos.x -= width * 0.5
	draw_string(font, pos + Vector2(1.5, 2.5), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, color.a * 0.48))
	draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
