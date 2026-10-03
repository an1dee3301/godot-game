class_name SplitFlapLabel
extends Control
## A row of independent, clipped split-flap character modules.

signal settled

const DRUM := " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:.-/"
const STEP_TIME := 0.065

@export_range(1, 80, 1) var columns := 12
@export var cell_size := Vector2(16.0, 27.0)
@export var glyph_color := Color("f7f7f2")
@export var card_color := Color("23282f")
@export var hinge_color := Color("07090c")
@export var font_size := 19

var flap_sound: Callable
var _cells: Array[FlapCell] = []
var _target := ""
var _moving := false
var _last_clack_msec := 0


class GlyphHalf extends Control:
	var character := " "
	var ink := Color.WHITE
	var card := Color.BLACK
	var glyph_size := 18
	var lower := false
	var face_font: Font

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), card)
		if character != " ":
			var baseline := size.y + float(glyph_size) * 0.36
			if lower:
				baseline -= size.y
			var width := face_font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size).x
			draw_string(face_font, Vector2((size.x - width) * 0.5, baseline), character, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size, ink)
		var hinge_y := 0.0 if lower else size.y - 1.0
		draw_rect(Rect2(0.0, hinge_y, size.x, 1.0), Color("07090c"))


class FlapCell extends Control:
	var top: GlyphHalf
	var bottom: GlyphHalf
	var front: GlyphHalf
	var back: GlyphHalf
	var current := " "
	var next := " "
	var target := " "
	var delay := 0.0
	var phase := 0.0
	var flipping := false
	var owner_label: SplitFlapLabel

	func configure(width: float, height: float, ink: Color, card: Color, glyph_size: int, face_font: Font) -> void:
		custom_minimum_size = Vector2(width, height)
		size = custom_minimum_size
		clip_contents = true
		top = _half(width, height, false, ink, card, glyph_size, face_font)
		bottom = _half(width, height, true, ink, card, glyph_size, face_font)
		front = _half(width, height, false, ink, card.darkened(0.15), glyph_size, face_font)
		back = _half(width, height, true, ink, card.darkened(0.08), glyph_size, face_font)
		front.pivot_offset = Vector2(0.0, height * 0.5)
		back.pivot_offset = Vector2.ZERO
		front.visible = false
		back.visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _half(width: float, height: float, lower: bool, ink: Color, card: Color, glyph_size: int, face_font: Font) -> GlyphHalf:
		var part := GlyphHalf.new()
		part.position = Vector2(0.0, height * 0.5 if lower else 0.0)
		part.size = Vector2(width, height * 0.5)
		part.clip_contents = true
		part.lower = lower
		part.ink = ink
		part.card = card
		part.glyph_size = glyph_size
		part.face_font = face_font
		part.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(part)
		return part

	func show_character(value: String) -> void:
		target = value
		_land(value)

	# Finish on a character without touching the target, so multi-step rolls keep going.
	func _land(value: String) -> void:
		current = value
		next = value
		flipping = false
		front.visible = false
		back.visible = false
		top.character = value
		bottom.character = value
		top.queue_redraw()
		bottom.queue_redraw()

	func begin_flip() -> void:
		var index := SplitFlapLabel.DRUM.find(current)
		next = SplitFlapLabel.DRUM[(index + 1) % SplitFlapLabel.DRUM.length()]
		phase = 0.0
		flipping = true
		top.character = next
		bottom.character = current
		front.character = current
		back.character = next
		top.queue_redraw()
		bottom.queue_redraw()
		front.queue_redraw()
		back.queue_redraw()
		front.visible = true
		back.visible = false
		front.scale.y = 1.0
		back.scale.y = 0.0

	func advance(delta: float) -> bool:
		if current == target and not flipping:
			return false
		if delay > 0.0:
			delay = maxf(0.0, delay - delta)
			return true
		if not flipping:
			begin_flip()
		phase += delta / SplitFlapLabel.STEP_TIME
		if phase < 0.5:
			front.scale.y = maxf(0.0, 1.0 - phase * 2.0)
			front.visible = front.scale.y > 0.15
		elif phase < 1.0:
			front.visible = false
			back.scale.y = minf(1.0, (phase - 0.5) * 2.0)
			back.visible = back.scale.y > 0.15
		else:
			_land(next)
			owner_label._clack()
		return current != target or flipping

	func _draw() -> void:
		var middle := size.y * 0.5
		draw_rect(Rect2(0.0, middle - 0.8, size.x, 1.6), owner_label.hinge_color)
		draw_rect(Rect2(0.0, 0.0, size.x, size.y), Color(0.0, 0.0, 0.0, 0.35), false, 1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_cells()
	set_process(false)
	if not _target.is_empty():
		set_text(_target, false)


func _build_cells() -> void:
	for child in get_children():
		child.queue_free()
	_cells.clear()
	custom_minimum_size = Vector2(columns * (cell_size.x + 1.0) - 1.0, cell_size.y)
	size = custom_minimum_size
	var face_font := FontVariation.new()
	face_font.base_font = ThemeDB.fallback_font
	face_font.variation_embolden = 0.65
	for index in columns:
		var cell := FlapCell.new()
		cell.owner_label = self
		cell.position = Vector2(index * (cell_size.x + 1.0), 0.0)
		add_child(cell)
		cell.configure(cell_size.x, cell_size.y, glyph_color, card_color, font_size, face_font)
		cell.show_character(" ")
		_cells.append(cell)


func set_text(value: String, animate: bool = true) -> void:
	var normalized := value.to_upper().substr(0, columns).rpad(columns, " ")
	if normalized == _target and animate:
		return
	_target = normalized
	if _cells.is_empty():
		return
	_moving = false
	for index in columns:
		var cell := _cells[index]
		var character := normalized[index]
		if DRUM.find(character) < 0:
			character = " "
		if not animate:
			cell.show_character(character)
		else:
			cell.target = character
			if cell.current != character or cell.flipping:
				cell.delay = randf_range(0.0, 0.14) + float(index % 4) * 0.012
				_moving = true
	set_process(_moving)
	if not _moving:
		settled.emit()


func _process(delta: float) -> void:
	var active := false
	for cell in _cells:
		if cell.advance(delta):
			active = true
	if not active:
		_moving = false
		set_process(false)
		settled.emit()


func _clack() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_clack_msec >= 24 and flap_sound.is_valid():
		_last_clack_msec = now
		flap_sound.call()
