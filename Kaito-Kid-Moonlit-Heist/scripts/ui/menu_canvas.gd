class_name HeistMenuCanvas
extends Control
## Custom-drawn moonlit calling cards and newspaper-style outcome panels.

const NAVY := Color("0b1230")
const PAPER := Color("f5f1e5")
const GOLD := Color("d4af37")
const CRIMSON := Color("c32d43")

var screen := ""
var data: Dictionary = {}
var _time := 0.0
var _serif: SystemFont
var _sans: SystemFont
var _cards: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
	_sans = SystemFont.new()
	_sans.font_names = PackedStringArray(["Avenir Next", "Arial", "sans-serif"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 481948
	for i in range(22):
		_cards.append({"x": rng.randf_range(0.0, 1600.0), "y": rng.randf_range(0.0, 900.0), "speed": rng.randf_range(18.0, 47.0), "angle": rng.randf_range(-0.55, 0.55), "size": rng.randf_range(9.0, 22.0)})


func _process(delta: float) -> void:
	_time += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	var scale_ui := minf(size.x / 1600.0, size.y / 900.0)
	if scale_ui <= 0.0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_ui)
	var w := size.x / scale_ui
	var h := size.y / scale_ui
	_background(w, h)
	match screen:
		"title": _title(w, h)
		"pause": _pause(w, h)
		"game_over": _game_over(w, h)
		"win": _win(w, h)


func _text(value: String, pos: Vector2, font_size: int, color: Color = PAPER, serif: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font: Font = _serif if serif else _sans
	var text_width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := pos
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		origin.x -= text_width * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		origin.x -= text_width
	draw_string(font, origin, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _wrapped_text(value: String, rect: Rect2, font_size: int, line_height: float, color: Color = NAVY, serif: bool = true) -> void:
	var font: Font = _serif if serif else _sans
	var line := ""
	var y := rect.position.y + float(font_size)
	for word in value.split(" "):
		var candidate: String = word if line.is_empty() else line + " " + word
		if not line.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > rect.size.x:
			_text(line, Vector2(rect.position.x, y), font_size, color, serif)
			line = word
			y += line_height
		else:
			line = candidate
	if not line.is_empty():
		_text(line, Vector2(rect.position.x, y), font_size, color, serif)


func _background(w: float, h: float) -> void:
	var full := Rect2(Vector2.ZERO, Vector2(w, h))
	draw_rect(full, Color("080d22") if screen != "pause" else Color(0.03, 0.05, 0.12, 0.79))
	if screen == "pause":
		return
	for i in range(24):
		var inset := float(i) * h / 24.0
		var alpha := (1.0 - float(i) / 24.0) * 0.013
		draw_rect(Rect2(0, inset, w, h - inset), Color(0.3, 0.42, 0.68, alpha))
	var moon := Vector2(w - 242, 173)
	for i in range(7, 0, -1):
		draw_circle(moon, 56.0 + i * 13.0, Color(0.52, 0.64, 0.91, 0.008))
	draw_circle(moon, 55.0, Color("dbe6f4"))
	draw_circle(moon + Vector2(15, -8), 48.0, Color("e9f2fa"))
	for card in _cards:
		var pos := Vector2(float(card["x"]) + sin(_time * 0.7 + float(card["y"])) * 12.0, fposmod(float(card["y"]) + _time * float(card["speed"]), h + 80.0) - 40.0)
		_falling_card(pos, float(card["size"]), float(card["angle"]))
	draw_line(Vector2(0, h - 37), Vector2(w, h - 37), Color(GOLD.r, GOLD.g, GOLD.b, 0.35), 1.0)
	_text("THE PHANTOM THIEF  •  EST. MIDNIGHT", Vector2(w * 0.5, h - 16), 12, Color("8a9bb8"), false, HORIZONTAL_ALIGNMENT_CENTER)


func _falling_card(center: Vector2, card_size: float, angle: float) -> void:
	var c := cos(angle)
	var s := sin(angle)
	var points := PackedVector2Array()
	for corner in [Vector2(-0.62, -1), Vector2(0.62, -1), Vector2(0.62, 1), Vector2(-0.62, 1)]:
		var q: Vector2 = corner * card_size
		points.append(center + Vector2(q.x * c - q.y * s, q.x * s + q.y * c))
	draw_colored_polygon(points, Color(0.94, 0.95, 1.0, 0.27))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(GOLD.r, GOLD.g, GOLD.b, 0.35), 1.0)


func _card(rect: Rect2, shadow: bool = true) -> void:
	if shadow:
		draw_rect(Rect2(rect.position + Vector2(10, 13), rect.size), Color(0, 0, 0, 0.4))
	draw_rect(rect, PAPER)
	draw_rect(rect.grow(-7), GOLD, false, 2.0)
	draw_rect(rect.grow(-17), Color("d4c9aa"), false, 0.7)


func _title(w: float, h: float) -> void:
	var center := Vector2(w * 0.5, h * 0.5)
	_text("KAITO KID", Vector2(center.x, 98), 57, PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
	_text("—  M O O N L I T   H E I S T  —", Vector2(center.x, 139), 21, GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_diamond(Vector2(center.x, 160), 6.0, GOLD)
	var card := Rect2(center.x - 345, 183, 690, 365)
	_card(card)
	_doodle(Vector2(card.position.x + 119, card.position.y + 151))
	var prose := Rect2(card.position + Vector2(248, 31), Vector2(card.size.x - 284, 280))
	_text("A CALLING CARD", Vector2(prose.position.x + prose.size.x * 0.5, card.position.y + 60), 23, NAVY, true, HORIZONTAL_ALIGNMENT_CENTER)
	draw_line(Vector2(prose.position.x, card.position.y + 77), Vector2(prose.end.x, card.position.y + 77), GOLD, 1.0)
	_wrapped_text("At the hour of the full moon I shall come for the five jewels of the Moonlight Museum.", Rect2(prose.position + Vector2(4, 92), Vector2(prose.size.x - 8, 155)), 24, 36.0)
	_text("— Kaito Kid", Vector2(prose.end.x - 7, card.end.y - 37), 22, Color("324568"), true, HORIZONTAL_ALIGNMENT_RIGHT)
	var row_y := 591.0
	var left := Rect2(center.x - 525, row_y, 315, 238)
	var right := Rect2(center.x + 210, row_y, 315, 238)
	_info_panel(left, "HOW TO PLAY")
	var how := ["Steal all five jewels.", "Avoid guard flashlights.", "Cards stun guards: 3 hits,", "or 6 for the inspector.", "Throw cards at walls to distract.", "Cut the vault laser at the fuse.", "Escape by balcony glider!"]
	for i in range(how.size()):
		_text(how[i], left.position + Vector2(19, 57 + i * 24), 15, PAPER)
	_info_panel(right, "CONTROLS")
	var controls := ["WASD  Move     Mouse  Look", "Shift  Sprint     Ctrl/C  Sneak", "Space  Jump      E  Steal", "LMB/F  Card gun", "RMB/Q  Smoke bomb", "Esc  Pause"]
	for i in range(controls.size()):
		_text(controls[i], right.position + Vector2(18, 58 + i * 27), 15, PAPER)


func _info_panel(rect: Rect2, heading: String) -> void:
	draw_rect(rect, Color(0.07, 0.11, 0.24, 0.95))
	draw_rect(rect, Color(GOLD.r, GOLD.g, GOLD.b, 0.8), false, 1.2)
	_text(heading, rect.position + Vector2(18, 28), 19, GOLD, true)
	draw_line(rect.position + Vector2(18, 38), rect.position + Vector2(rect.size.x - 18, 38), Color(GOLD.r, GOLD.g, GOLD.b, 0.45))


func _doodle(p: Vector2) -> void:
	var ink := NAVY
	# A tiny ink portrait: tilted top hat, monocle, chain, clover and a sly smile.
	draw_arc(p + Vector2(0, 46), 53, 0.12, PI - 0.12, 28, ink, 2.5)
	draw_arc(p + Vector2(0, 46), 53, PI + 0.12, TAU - 0.12, 28, ink, 2.5)
	draw_rect(Rect2(p + Vector2(-59, -47), Vector2(118, 10)), ink)
	draw_rect(Rect2(p + Vector2(-38, -117), Vector2(76, 72)), ink)
	draw_rect(Rect2(p + Vector2(-38, -57), Vector2(76, 10)), Color("5a8eab"))
	draw_line(p + Vector2(-58, -35), p + Vector2(58, -35), GOLD, 1.3)
	draw_arc(p + Vector2(18, 35), 20, 0, TAU, 36, ink, 2.3)
	draw_circle(p + Vector2(18, 35), 3.1, ink)
	draw_line(p + Vector2(-23, 31), p + Vector2(-11, 27), ink, 2.0)
	draw_circle(p + Vector2(-13, 36), 2.5, ink)
	draw_arc(p + Vector2(21, 63), 31, 0.38, 2.43, 22, ink, 2.3)
	draw_arc(p + Vector2(39, 57), 44, 0.03, 0.96, 16, ink, 1.6)
	var charm := p + Vector2(58, 100)
	for offset in [Vector2(0, -5), Vector2(-5, 1), Vector2(5, 1)]:
		draw_circle(charm + offset, 4.0, GOLD)
	draw_line(charm + Vector2(0, 4), charm + Vector2(4, 10), GOLD, 1.5)
	_text("K", p + Vector2(0, 150), 31, GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_diamond(p: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -radius), p + Vector2(radius, 0), p + Vector2(0, radius), p + Vector2(-radius, 0)]), color)


func _pause(w: float, h: float) -> void:
	var center := Vector2(w * 0.5, h * 0.5)
	var rect := Rect2(center + Vector2(-230, -230), Vector2(460, 530))
	_card(rect)
	_text("INTERMISSION", center + Vector2(0, -157), 37, NAVY, true, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_diamond(center + Vector2(0, -124), 7, GOLD)
	_text("The moon waits for no one.", center + Vector2(0, -73), 20, Color("445477"), true, HORIZONTAL_ALIGNMENT_CENTER)


func _game_over(w: float, h: float) -> void:
	var center := Vector2(w * 0.5, h * 0.5)
	var rect := Rect2(center + Vector2(-326, -300), Vector2(652, 650))
	_card(rect)
	_text("THE MIDNIGHT GAZETTE", center + Vector2(0, -248), 22, NAVY, true, HORIZONTAL_ALIGNMENT_CENTER)
	draw_line(center + Vector2(-290, -232), center + Vector2(290, -232), NAVY, 2.0)
	_text("CAUGHT!", center + Vector2(0, -139), 76, CRIMSON, true, HORIZONTAL_ALIGNMENT_CENTER)
	_text("Kaito Kid Arrested?!", center + Vector2(0, -92), 29, NAVY, true, HORIZONTAL_ALIGNMENT_CENTER)
	_text(String(data.get("cause", "Caught by the museum police")), center + Vector2(0, -43), 16, Color("43516b"), false, HORIZONTAL_ALIGNMENT_CENTER)
	_stats(center + Vector2(-235, -2), false)


func _win(w: float, h: float) -> void:
	var center := Vector2(w * 0.5, h * 0.5)
	var rect := Rect2(center + Vector2(-355, -315), Vector2(710, 665))
	_card(rect)
	for i in range(24):
		var angle := float(i) * TAU / 24.0 + _time * 0.14
		var burst := center + Vector2(cos(angle), sin(angle)) * (410.0 + 16.0 * sin(_time + i))
		_falling_card(burst, 13.0, angle)
	_text("✦  A PERFECT ESCAPE  ✦", center + Vector2(0, -239), 25, GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
	_text("Ladies and gentlemen...", center + Vector2(0, -167), 34, NAVY, true, HORIZONTAL_ALIGNMENT_CENTER)
	_text("the jewels are mine.", center + Vector2(0, -121), 39, NAVY, true, HORIZONTAL_ALIGNMENT_CENTER)
	if bool(data.get("new_best", false)):
		_text("NEW RECORD", center + Vector2(0, -63), 22, CRIMSON, true, HORIZONTAL_ALIGNMENT_CENTER)
	_stats(center + Vector2(-235, -9), true)


func _stats(p: Vector2, won: bool) -> void:
	var total := int(float(data.get("time", 0.0)))
	var best := int(float(data.get("best_time", 0.0)))
	var rows := [
		["TIME", "%02d:%02d" % [total / 60, total % 60]],
		["JEWELS", "%d / %d" % [int(data.get("jewels", 0)), int(data.get("jewels_total", 5))]],
		["GUARDS KNOCKED OUT", str(data.get("knockouts", 0))],
		["TIMES SPOTTED", str(data.get("spotted", 0))],
	]
	if won:
		rows.append(["BEST TIME", "%02d:%02d" % [best / 60, best % 60]])
	for i in range(rows.size()):
		var y := p.y + float(i) * 43.0
		draw_line(Vector2(p.x, y + 13), Vector2(p.x + 470, y + 13), Color(0.78, 0.72, 0.57, 0.55), 1.0)
		_text(rows[i][0], Vector2(p.x, y), 15, Color("52617b"))
		_text(rows[i][1], Vector2(p.x + 470, y), 21, NAVY, true, HORIZONTAL_ALIGNMENT_RIGHT)
