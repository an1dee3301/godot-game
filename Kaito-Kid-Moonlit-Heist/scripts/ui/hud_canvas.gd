class_name HeistHUDCanvas
extends Control
## Draws the HUD in viewport coordinates so canvas_items stretch remains crisp.

const NAVY := Color("0b1230")
const PAPER := Color("f4f0e7")
const GOLD := Color("d2b66f")
const CRIMSON := Color("dc5963")
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
	_draw_health(Vector2(43, sh - 58))
	_draw_objective(Vector2(sw * 0.5, 37))
	_draw_minimap(Vector2(sw - 110, 111), 72.0)
	_draw_crosshair(Vector2(sw * 0.5, sh * 0.5))
	_draw_stealth(Vector2(43, sh - 125))
	_draw_banner(Vector2(sw * 0.5, sh - 116))
	_draw_dangers(sw, sh)
	if lightning_flash > 0.01:
		draw_rect(Rect2(Vector2.ZERO, Vector2(sw, sh)), Color(0.82, 0.92, 1.0, lightning_flash))


func _text(value: String, pos: Vector2, font_size: int, color: Color = PAPER,
		serif: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font: Font = _serif if serif else _sans
	var text_width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := pos
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		origin.x -= text_width * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		origin.x -= text_width
	draw_string(font, origin, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_vignette(sw: float, sh: float) -> void:
	var strength := alert_fade * (0.20 + 0.035 * sin(_pulse * 4.5)) + damage_flash * 0.48
	if strength <= 0.005:
		return
	var tint := CRIMSON
	for i in range(6):
		var inset := float(i) * 11.0
		var alpha := strength * (1.0 - float(i) / 6.0) * 0.13
		draw_rect(Rect2(inset, inset, sw - 2.0 * inset, sh - 2.0 * inset), Color(tint.r, tint.g, tint.b, alpha), false, 11.0)


func _draw_health(p: Vector2) -> void:
	_text("VITALITY", p + Vector2(0, -19), 11, GOLD)
	_text("%03d" % ceili(hp), p + Vector2(238, -12), 23, PAPER, false, HORIZONTAL_ALIGNMENT_RIGHT)
	var start := p + Vector2(0, 0)
	var length := 238.0
	draw_line(start, start + Vector2(length, 0), Color(PAPER.r, PAPER.g, PAPER.b, 0.25), 2.0, true)
	draw_line(start, start + Vector2(length * clampf(health_ghost / max_hp, 0.0, 1.0), 0), Color(CRIMSON.r, CRIMSON.g, CRIMSON.b, 0.45), 4.0, true)
	draw_line(start, start + Vector2(length * clampf(health_display / max_hp, 0.0, 1.0), 0), PAPER if hp > max_hp * 0.3 else CRIMSON, 3.0, true)
	_text("SMOKE", p + Vector2(0, -48), 10, Color(PAPER.r, PAPER.g, PAPER.b, 0.67))
	for i in range(KK.PLAYER_MAX_SMOKE):
		var center := p + Vector2(75 + i * 18, -51)
		var tint := PAPER if i < smoke else Color(PAPER.r, PAPER.g, PAPER.b, 0.24)
		draw_circle(center, 4.7, tint)
		draw_circle(center + Vector2(0, -5), 1.5, GOLD if i < smoke else tint)


func _draw_objective(p: Vector2) -> void:
	_text("M O O N L I G H T   M U S E U M", p + Vector2(0, 0), 11, GOLD, false, HORIZONTAL_ALIGNMENT_CENTER)
	_text(objective, p + Vector2(0, 25), 16, PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
	var row_width := float(jewels_total - 1) * 28.0
	var start_x := p.x - row_width * 0.5
	var jewel_nodes := level.jewels()
	for i in range(jewels_total):
		var x := start_x + float(i) * 28.0
		var color := Color(PAPER.r, PAPER.g, PAPER.b, 0.18)
		if i < jewel_nodes.size() and jewel_nodes[i] is Jewel:
			if jewel_nodes[i].is_stolen:
				color = jewel_nodes[i].gem_color
		elif i < jewels:
			color = GEM_COLORS[i % GEM_COLORS.size()]
		_diamond(Vector2(x, p.y + 49), 7.0, color)
	draw_line(p + Vector2(-82, 69), p + Vector2(82, 69), Color(GOLD.r, GOLD.g, GOLD.b, 0.36), 1.0)


func _diamond(center: Vector2, radius: float, color: Color) -> void:
	var vertices := PackedVector2Array([
		center + Vector2(0, -radius), center + Vector2(radius * 0.75, 0),
		center + Vector2(0, radius), center + Vector2(-radius * 0.75, 0)
	])
	draw_colored_polygon(vertices, color)
	draw_polyline(PackedVector2Array([vertices[0], vertices[1], vertices[2], vertices[3], vertices[0]]), PAPER, 1.1)


func _draw_crosshair(p: Vector2) -> void:
	var cooldown := _card_cooldown_ratio()
	draw_arc(p, 18.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - cooldown), 32, GOLD if cooldown <= 0.01 else Color(PAPER.r, PAPER.g, PAPER.b, 0.52), 1.5, true)
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(p + direction * 5.0, p + direction * 10.0, PAPER, 1.0)
	draw_circle(p, 1.5, GOLD)
	if prompt != "":
		var verb := _clean_prompt(prompt)
		var width: float = _sans.get_string_size(verb, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var left := p.x - (width + 39.0) * 0.5
		var key_rect := Rect2(Vector2(left, p.y + 42), Vector2(24, 24))
		draw_rect(key_rect, Color(NAVY.r, NAVY.g, NAVY.b, 0.72))
		draw_rect(key_rect, Color(GOLD.r, GOLD.g, GOLD.b, 0.65), false, 1.0)
		_text("E", Vector2(left + 12, p.y + 59), 13, PAPER, false, HORIZONTAL_ALIGNMENT_CENTER)
		_text(verb, Vector2(left + 35, p.y + 60), 15, PAPER)


func _clean_prompt(raw: String) -> String:
	var value := raw.strip_edges()
	if value.begins_with("[E]"):
		value = value.substr(3).strip_edges()
	if value.to_lower().begins_with("steal the "):
		return "STEAL  " + value.substr(10)
	if value.to_lower().begins_with("disable "):
		return "DISARM  " + value.substr(8)
	return value.to_upper()


func _card_cooldown_ratio() -> float:
	if player == null:
		return 0.0
	return clampf(float(player.get("_fire_time")) / KK.CARD_COOLDOWN, 0.0, 1.0)


func _draw_stealth(p: Vector2) -> void:
	var visibility := clampf(player.visibility_factor(), 0.0, 1.0)
	var state := "VEILED" if visibility < 0.05 else ("LOW PROFILE" if player.is_crouching() else ("IN THE OPEN" if player.is_sprinting() else "VISIBLE"))
	var eye := p + Vector2(13, 0)
	var opening := lerpf(2.5, 9.0, visibility)
	draw_arc(eye, 12.0, PI + 0.25, TAU - 0.25, 14, PAPER, 1.5)
	draw_line(eye + Vector2(-10, 0), eye + Vector2(0, -opening), PAPER, 1.5)
	draw_line(eye + Vector2(0, -opening), eye + Vector2(10, 0), PAPER, 1.5)
	draw_circle(eye, 2.7, GOLD)
	_text(state, p + Vector2(38, 5), 12, PAPER)
	var total := int(elapsed)
	_text("%02d:%02d" % [total / 60, total % 60], p + Vector2(238, 5), 13, Color(PAPER.r, PAPER.g, PAPER.b, 0.73), false, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_banner(p: Vector2) -> void:
	if banner_alpha <= 0.01 or banner == "":
		return
	var y := p.y + banner_slide
	draw_line(Vector2(p.x - 90, y), Vector2(p.x + 90, y), Color(GOLD.r, GOLD.g, GOLD.b, banner_alpha * 0.75), 1.0)
	_text(banner, Vector2(p.x, y + 31), 24, Color(banner_color.r, banner_color.g, banner_color.b, banner_alpha), true, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_minimap(center: Vector2, radius: float) -> void:
	for i in range(8, 0, -1):
		var fade := float(i) / 8.0
		draw_circle(center, radius + float(i) * 2.0, Color(NAVY.r, NAVY.g, NAVY.b, 0.025 * fade))
	draw_circle(center, radius, Color(NAVY.r, NAVY.g, NAVY.b, 0.64))
	draw_arc(center, radius + 2.0, 0, TAU, 64, Color(GOLD.r, GOLD.g, GOLD.b, 0.62), 1.0, true)
	for r in [radius * 0.45, radius * 0.8]:
		draw_arc(center, r, 0, TAU, 64, Color(PAPER.r, PAPER.g, PAPER.b, 0.08), 1.0)
	var yaw := player.camera_rig.get_yaw() if player.camera_rig != null else 0.0
	var origin := Vector2(player.global_position.x, player.global_position.z)
	var world_scale := 2.5
	for wall in level.minimap_walls():
		if not wall is Rect2:
			continue
		var rect: Rect2 = wall
		var a := rect.position
		var b := rect.position + Vector2(rect.size.x, 0)
		var c := rect.position + rect.size
		var d := rect.position + Vector2(0, rect.size.y)
		for edge in [[a, b], [b, c], [c, d], [d, a]]:
			_map_segment(center, radius - 4.0, _map_point(edge[0], origin, yaw, world_scale), _map_point(edge[1], origin, yaw, world_scale), Color("71839f"), 1.2)
	for icon_node in get_tree().get_nodes_in_group(KK.GROUP_MINIMAP):
		if not icon_node is Node3D or not icon_node.has_method("minimap_icon"):
			continue
		var kind: String = icon_node.minimap_icon()
		if kind == "jewel" and bool(icon_node.get("is_stolen")):
			continue
		var point := _map_point(Vector2(icon_node.global_position.x, icon_node.global_position.z), origin, yaw, world_scale) + center
		if point.distance_to(center) >= radius - 10.0:
			continue
		match kind:
			"jewel":
				_diamond(point, 4.5, icon_node.get("gem_color") as Color)
			"exit":
				var locked: bool = bool(icon_node.get("locked"))
				draw_circle(point, 4.0, Color("808999") if locked else GOLD)
			"pickup":
				draw_circle(point, 3.0, Color("7bdebb"))
			"camera":
				draw_circle(point, 3.0, Color("8dc9ef"))
			"fuse":
				draw_rect(Rect2(point - Vector2(3, 3), Vector2(6, 6)), GOLD)
	for guard_node in get_tree().get_nodes_in_group(KK.GROUP_GUARDS):
		if not guard_node is Guard or guard_node.state == Guard.State.DOWN:
			continue
		var point := _map_point(Vector2(guard_node.global_position.x, guard_node.global_position.z), origin, yaw, world_scale) + center
		if point.distance_to(center) >= radius - 8.0:
			continue
		var tint := BLUE
		if guard_node.state in [Guard.State.CHASE, Guard.State.ATTACK]:
			tint = CRIMSON
		elif guard_node.state in [Guard.State.SUSPICIOUS, Guard.State.SEARCH]:
			tint = GOLD
		var forward := Vector2(-guard_node.global_basis.z.x, -guard_node.global_basis.z.z).rotated(yaw)
		if forward.length() > 0.01 and point.distance_to(center) < radius - 24.0:
			var angle := forward.angle()
			var cone := PackedVector2Array([point, point + Vector2.from_angle(angle - 0.37) * 12.0, point + Vector2.from_angle(angle + 0.37) * 12.0])
			draw_colored_polygon(cone, Color(tint.r, tint.g, tint.b, 0.18))
		draw_circle(point, 2.8, tint)
	var arrow := PackedVector2Array([center + Vector2(0, -8), center + Vector2(5, 6), center + Vector2(0, 3), center + Vector2(-5, 6)])
	draw_colored_polygon(arrow, PAPER)
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[3], arrow[0]]), GOLD, 1.4)
	_draw_compass(center, radius, origin, yaw)
	_text("N", center + Vector2(0, -radius - 9), 10, GOLD, false, HORIZONTAL_ALIGNMENT_CENTER)


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
		if node.state == Guard.State.DOWN or node.state == Guard.State.STUNNED:
			continue
		var danger := clampf(node.awareness, 0.0, 1.0)
		if node.state in [Guard.State.CHASE, Guard.State.ATTACK]:
			danger = 1.0
		elif node.state == Guard.State.SUSPICIOUS:
			danger = maxf(danger, 0.36)
		if danger < 0.08:
			continue
		var world := node.global_position + Vector3.UP * 1.5
		var screen := camera.unproject_position(world) / Vector2(size.x / sw, size.y / sh)
		var from_center := screen - Vector2(sw * 0.5, sh * 0.5)
		if camera.is_position_behind(world):
			from_center = -from_center
		if from_center.length() < 0.01:
			from_center = Vector2.UP
		var unit := from_center.normalized()
		var edge_distance := minf((sw * 0.5 - 37.0) / maxf(absf(unit.x), 0.001), (sh * 0.5 - 37.0) / maxf(absf(unit.y), 0.001))
		var edge := Vector2(sw * 0.5, sh * 0.5) + unit * edge_distance
		var angle := unit.angle()
		var tint := PAPER.lerp(GOLD, clampf(danger * 2.0, 0.0, 1.0))
		tint = tint.lerp(CRIMSON, clampf((danger - 0.55) / 0.45, 0.0, 1.0))
		tint.a = 0.88
		var arc_center := edge - unit * 12.0
		draw_arc(arc_center, 13.0, angle + PI * 0.58, angle + PI * 1.42, 20, Color(tint.r, tint.g, tint.b, 0.20), 2.0, true)
		draw_arc(arc_center, 13.0, angle + PI * 0.58, angle + PI * (0.58 + 0.84 * danger), 20, tint, 2.2, true)
		draw_circle(edge - unit * 1.5, 2.0, tint)
