class_name HeistHUDCanvas
extends Control
## Draws the HUD in viewport coordinates so canvas_items stretch remains crisp.

const NAVY := Color("0b1230")
const PAPER := Color("f5f1e5")
const GOLD := Color("d4af37")
const CRIMSON := Color("c32d43")
const BLUE := Color("8ec9ee")
const GEM_COLORS := [Color("3485f9"), Color("ef4455"), Color("654080"), Color("4edc92"), Color("e9f6ff")]

var level: MuseumLevel
var player: PhantomThief
var hp := 100.0
var max_hp := 100.0
var health_display := 100.0:
	set(value):
		health_display = value
		queue_redraw()
var health_ghost := 100.0:
	set(value):
		health_ghost = value
		queue_redraw()
var jewels := 0
var jewels_total := 5
var smoke := 2
var prompt := ""
var objective := "Steal the jewels"
var elapsed := 0.0
var alert_level := 0
var alert_fade := 0.0:
	set(value):
		alert_fade = value
		queue_redraw()
var damage_flash := 0.0:
	set(value):
		damage_flash = value
		queue_redraw()
var lightning_flash := 0.0:
	set(value):
		lightning_flash = value
		queue_redraw()
var banner := ""
var banner_color := Color.WHITE
var banner_alpha := 0.0:
	set(value):
		banner_alpha = value
		queue_redraw()
var banner_slide := 0.0:
	set(value):
		banner_slide = value
		queue_redraw()
var _serif: SystemFont
var _sans: SystemFont
var _pulse := 0.0
var _map_walls: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
	_sans = SystemFont.new()
	_sans.font_names = PackedStringArray(["Avenir Next", "Arial", "sans-serif"])


func _process(delta: float) -> void:
	_pulse += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	if player == null or level == null:
		return
	var w := size.x
	var h := size.y
	var scale_ui := minf(w / 1600.0, h / 900.0)
	if scale_ui <= 0.0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_ui)
	var sw := w / scale_ui
	var sh := h / scale_ui
	_draw_vignette(sw, sh)
	_draw_health(Vector2(36, 34))
	_draw_objective(Vector2(sw * 0.5, 32))
	_draw_minimap(Vector2(sw - 141, 143), 104.0)
	_draw_crosshair(Vector2(sw * 0.5, sh * 0.5))
	_draw_stealth(Vector2(36, sh - 137))
	_draw_banner(Vector2(sw * 0.5, sh - 112))
	_draw_dangers(sw, sh)
	if lightning_flash > 0.01:
		draw_rect(Rect2(Vector2.ZERO, Vector2(sw, sh)), Color(0.82, 0.92, 1.0, lightning_flash))


func _text(value: String, pos: Vector2, font_size: int, color: Color = PAPER, serif: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font: Font = _serif if serif else _sans
	var text_width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := pos
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		origin.x -= text_width * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		origin.x -= text_width
	draw_string(font, origin, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _panel(rect: Rect2, fill: Color, border: Color = GOLD) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, border, false, 1.2)


func _draw_vignette(sw: float, sh: float) -> void:
	var strength := alert_fade * (0.20 + 0.035 * sin(_pulse * 4.5)) + damage_flash * 0.48
	if strength <= 0.005:
		return
	var tint := CRIMSON
	for i in range(8):
		var inset := float(i) * 15.0
		var alpha := strength * (1.0 - float(i) / 8.0) * 0.18
		draw_rect(Rect2(inset, inset, sw - 2.0 * inset, sh - 2.0 * inset), Color(tint.r, tint.g, tint.b, alpha), false, 15.0)


func _draw_health(p: Vector2) -> void:
	_panel(Rect2(p, Vector2(290, 101)), Color(NAVY.r, NAVY.g, NAVY.b, 0.78))
	_text("KAITO  /  VITALITY", p + Vector2(16, 25), 16, GOLD, true)
	_text("%03d" % ceili(hp), p + Vector2(273, 27), 21, PAPER, false, HORIZONTAL_ALIGNMENT_RIGHT)
	var bar := Rect2(p + Vector2(16, 41), Vector2(258, 15))
	draw_rect(bar, Color(0.22, 0.19, 0.24, 0.9))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(health_ghost / max_hp, 0.0, 1.0), bar.size.y)), Color("e8b3b9"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(health_display / max_hp, 0.0, 1.0), bar.size.y)), CRIMSON)
	draw_rect(bar, PAPER, false, 1.0)
	_text("SMOKE", p + Vector2(16, 82), 12, Color("b9c5d9"))
	for i in range(KK.PLAYER_MAX_SMOKE):
		var center := p + Vector2(80 + i * 23, 77)
		draw_circle(center, 7.0, PAPER if i < smoke else Color("586077"))
		draw_circle(center + Vector2(0, -8), 2.5, GOLD if i < smoke else Color("586077"))
	_text("CARD  F / LMB", p + Vector2(273, 82), 11, GOLD, false, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_objective(p: Vector2) -> void:
	var box := Rect2(p + Vector2(-236, 0), Vector2(472, 88))
	_panel(box, Color(NAVY.r, NAVY.g, NAVY.b, 0.78))
	_text("THE MOONLIGHT MUSEUM", p + Vector2(0, 22), 14, GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
	_text(objective, p + Vector2(0, 46), 18, PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
	var row_width := float(jewels_total) * 25.0 + 65.0
	var start_x := p.x - row_width * 0.5 + 10.0
	for i in range(jewels_total):
		var x := start_x + float(i) * 25.0
		var color: Color = GEM_COLORS[i % GEM_COLORS.size()] if i < jewels else Color("667089")
		_diamond(Vector2(x, p.y + 69), 7.0, color)
	_text("%d/%d" % [jewels, jewels_total], Vector2(start_x + float(jewels_total) * 25.0 + 5.0, p.y + 75), 16, GOLD)


func _diamond(center: Vector2, radius: float, color: Color) -> void:
	var vertices := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius * 0.75, 0), center + Vector2(0, radius), center + Vector2(-radius * 0.75, 0)])
	draw_colored_polygon(vertices, color)
	draw_polyline(PackedVector2Array([vertices[0], vertices[1], vertices[2], vertices[3], vertices[0]]), PAPER, 1.1)


func _draw_crosshair(p: Vector2) -> void:
	var cooldown := _card_cooldown_ratio()
	draw_arc(p, 23.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - cooldown), 32, GOLD if cooldown <= 0.01 else Color("8296b5"), 2.0, true)
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(p + direction * 6.0, p + direction * 13.0, PAPER, 1.5)
	_diamond(p, 3.0, GOLD)
	if prompt != "":
		var width := maxf(220.0, _sans.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 40.0)
		var rect := Rect2(p + Vector2(-width * 0.5, 43), Vector2(width, 39))
		_panel(rect, Color(NAVY.r, NAVY.g, NAVY.b, 0.91))
		_text(prompt, p + Vector2(0, 69), 17, PAPER, false, HORIZONTAL_ALIGNMENT_CENTER)


func _card_cooldown_ratio() -> float:
	if player == null:
		return 0.0
	return clampf(float(player.get("_fire_time")) / KK.CARD_COOLDOWN, 0.0, 1.0)


func _draw_stealth(p: Vector2) -> void:
	_panel(Rect2(p, Vector2(290, 105)), Color(NAVY.r, NAVY.g, NAVY.b, 0.78))
	var visibility := clampf(player.visibility_factor(), 0.0, 1.0)
	var state := "HIDDEN" if visibility < 0.05 else ("SNEAKING" if player.is_crouching() else ("EXPOSED" if player.is_sprinting() else "MOVING"))
	var eye := p + Vector2(30, 38)
	draw_arc(eye, 13.0, PI * 0.13, PI * 0.87, 12, PAPER, 2.0)
	draw_arc(eye, 13.0, PI * 1.13, PI * 1.87, 12, PAPER, 2.0)
	draw_circle(eye, 4.0, GOLD)
	_text(state, p + Vector2(57, 43), 19, GOLD, true)
	_text("VISIBILITY", p + Vector2(16, 69), 11, Color("b9c5d9"))
	draw_rect(Rect2(p + Vector2(108, 59), Vector2(164, 9)), Color("34415f"))
	draw_rect(Rect2(p + Vector2(108, 59), Vector2(164 * visibility, 9)), Color("e1b446") if visibility < 0.6 else CRIMSON)
	var total := int(elapsed)
	_text("%02d:%02d" % [total / 60, total % 60], p + Vector2(272, 93), 17, PAPER, false, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_banner(p: Vector2) -> void:
	if banner_alpha <= 0.01 or banner == "":
		return
	var y := p.y + banner_slide
	var fill := Color(NAVY.r, NAVY.g, NAVY.b, banner_alpha * 0.90)
	var border := Color(GOLD.r, GOLD.g, GOLD.b, banner_alpha)
	_panel(Rect2(Vector2(p.x - 300, y), Vector2(600, 57)), fill, border)
	_text("✦  " + banner + "  ✦", Vector2(p.x, y + 37), 22, Color(banner_color.r, banner_color.g, banner_color.b, banner_alpha), true, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_minimap(center: Vector2, radius: float) -> void:
	draw_circle(center, radius + 9.0, Color(NAVY.r, NAVY.g, NAVY.b, 0.94))
	draw_arc(center, radius + 5.0, 0, TAU, 80, GOLD, 2.0, true)
	draw_circle(center, radius, Color("172645"))
	for r in [32.0, 65.0, 96.0]:
		draw_arc(center, r, 0, TAU, 64, Color(0.6, 0.72, 0.84, 0.10), 1.0)
	var yaw := player.camera_rig.get_yaw() if player.camera_rig != null else 0.0
	var origin := Vector2(player.global_position.x, player.global_position.z)
	var world_scale := 3.4
	for wall in level.minimap_walls():
		if not wall is Rect2:
			continue
		var rect: Rect2 = wall
		var a := rect.position
		var b := rect.position + Vector2(rect.size.x, 0)
		var c := rect.position + rect.size
		var d := rect.position + Vector2(0, rect.size.y)
		for edge in [[a, b], [b, c], [c, d], [d, a]]:
			_map_segment(center, radius - 2.0, _map_point(edge[0], origin, yaw, world_scale), _map_point(edge[1], origin, yaw, world_scale), Color("758aaa"), 2.0)
	for icon_node in get_tree().get_nodes_in_group(KK.GROUP_MINIMAP):
		if not icon_node is Node3D or not icon_node.has_method("minimap_icon"):
			continue
		var kind: String = icon_node.minimap_icon()
		if kind == "jewel" and bool(icon_node.get("is_stolen")):
			continue
		var point := _map_point(Vector2(icon_node.global_position.x, icon_node.global_position.z), origin, yaw, world_scale) + center
		if point.distance_to(center) >= radius - 9.0:
			continue
		match kind:
			"jewel":
				_diamond(point, 6.0, icon_node.get("gem_color") as Color)
			"exit":
				var locked: bool = bool(icon_node.get("locked"))
				draw_circle(point, 7.0, Color("808999") if locked else GOLD)
				_text("⇧", point + Vector2(0, 5), 13, NAVY, false, HORIZONTAL_ALIGNMENT_CENTER)
			"pickup":
				draw_circle(point, 4.0, Color("7bdebb"))
			"camera":
				draw_circle(point, 4.0, Color("8dc9ef"))
			"fuse":
				draw_rect(Rect2(point - Vector2(4, 4), Vector2(8, 8)), GOLD)
	for guard_node in get_tree().get_nodes_in_group(KK.GROUP_GUARDS):
		if not guard_node is Guard or guard_node.state == Guard.State.DOWN:
			continue
		var point := _map_point(Vector2(guard_node.global_position.x, guard_node.global_position.z), origin, yaw, world_scale) + center
		if point.distance_to(center) >= radius - 8.0:
			continue
		var tint := CRIMSON if guard_node.state in [Guard.State.CHASE, Guard.State.ATTACK] else (GOLD if guard_node.state in [Guard.State.SUSPICIOUS, Guard.State.SEARCH] else BLUE)
		var forward := Vector2(-guard_node.global_basis.z.x, -guard_node.global_basis.z.z).rotated(yaw)
		if forward.length() > 0.01 and point.distance_to(center) < radius - 24.0:
			var angle := forward.angle()
			var cone := PackedVector2Array([point, point + Vector2.from_angle(angle - 0.37) * 17.0, point + Vector2.from_angle(angle + 0.37) * 17.0])
			draw_colored_polygon(cone, Color(tint.r, tint.g, tint.b, 0.18))
		draw_circle(point, 4.0, tint)
	var arrow := PackedVector2Array([center + Vector2(0, -11), center + Vector2(7, 8), center + Vector2(0, 4), center + Vector2(-7, 8)])
	draw_colored_polygon(arrow, PAPER)
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[3], arrow[0]]), GOLD, 1.4)
	_draw_compass(center, radius, origin, yaw)
	_text("N", center + Vector2(-4, -radius - 16), 12, GOLD)


func _map_point(world: Vector2, origin: Vector2, yaw: float, world_scale: float) -> Vector2:
	return (world - origin).rotated(yaw) * world_scale


func _map_segment(center: Vector2, radius: float, a: Vector2, b: Vector2, color: Color, width: float) -> void:
	var diff := b - a
	var length_sq := diff.length_squared()
	if length_sq < 0.001:
		return
	var closest := a + diff * clampf(-a.dot(diff) / length_sq, 0.0, 1.0)
	if closest.length() > radius:
		return
	var start := a
	var end := b
	if a.length() > radius or b.length() > radius:
		var roots := []
		var determinant := pow(a.dot(diff), 2.0) - length_sq * (a.length_squared() - radius * radius)
		if determinant >= 0.0:
			var root := sqrt(determinant)
			for t in [(-a.dot(diff) - root) / length_sq, (-a.dot(diff) + root) / length_sq]:
				if t >= 0.0 and t <= 1.0:
					roots.append(a + diff * t)
		if a.length() > radius and roots.size() > 0:
			start = roots[0]
		if b.length() > radius and roots.size() > 0:
			end = roots[roots.size() - 1]
	draw_line(center + start, center + end, color, width, true)


func _draw_compass(center: Vector2, radius: float, origin: Vector2, yaw: float) -> void:
	var target: Node3D
	var nearest := INF
	for jewel_node in level.jewels():
		if jewel_node is Node3D and not jewel_node.is_stolen:
			var distance: float = player.global_position.distance_squared_to(jewel_node.global_position)
			if distance < nearest:
				nearest = distance
				target = jewel_node
	if target == null:
		target = level.exit_node()
	if target == null:
		return
	var direction := _map_point(Vector2(target.global_position.x, target.global_position.z), origin, yaw, 1.0).normalized()
	if direction.length() < 0.01:
		return
	var tip := center + direction * (radius - 10.0)
	var side := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([tip + direction * 7.0, tip - direction * 4.0 + side * 4.0, tip - direction * 4.0 - side * 4.0]), GOLD)


func _draw_dangers(sw: float, sh: float) -> void:
	if player.camera_rig == null or player.camera_rig.camera == null:
		return
	var camera: Camera3D = player.camera_rig.camera
	for guard_node in get_tree().get_nodes_in_group(KK.GROUP_GUARDS):
		if not guard_node is Guard:
			continue
		var node: Guard = guard_node
		if node.state not in [Guard.State.SUSPICIOUS, Guard.State.CHASE, Guard.State.ATTACK]:
			continue
		var world := node.global_position + Vector3.UP * 1.5
		var screen := camera.unproject_position(world) / Vector2(size.x / sw, size.y / sh)
		var from_center := screen - Vector2(sw * 0.5, sh * 0.5)
		if camera.is_position_behind(world):
			from_center = -from_center
		if from_center.length() < 0.01:
			from_center = Vector2.UP
		var unit := from_center.normalized()
		var edge := Vector2(clampf(sw * 0.5 + unit.x * sw * 0.45, 25.0, sw - 25.0), clampf(sh * 0.5 + unit.y * sh * 0.43, 25.0, sh - 25.0))
		if not camera.is_position_behind(world) and screen.x > 35.0 and screen.x < sw - 35.0 and screen.y > 35.0 and screen.y < sh - 35.0:
			continue
		var color := CRIMSON if node.state in [Guard.State.CHASE, Guard.State.ATTACK] else GOLD
		var side := Vector2(-unit.y, unit.x)
		draw_colored_polygon(PackedVector2Array([edge + unit * 12.0, edge - unit * 8.0 + side * 7.0, edge - unit * 8.0 - side * 7.0]), color)
