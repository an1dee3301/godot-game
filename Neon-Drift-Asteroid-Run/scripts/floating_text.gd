extends Node2D

var lifetime := 0.85
var elapsed := 0.0
var label: Label


func setup(spawn_position: Vector2, message: String, color: Color) -> void:
	position = spawn_position
	label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-55, -15)
	label.size = Vector2(110, 30)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)


func _process(delta: float) -> void:
	elapsed += delta
	position.y -= 32.0 * delta
	if is_instance_valid(label):
		label.modulate.a = clampf(1.0 - elapsed / lifetime, 0.0, 1.0)
	if elapsed >= lifetime:
		queue_free()
