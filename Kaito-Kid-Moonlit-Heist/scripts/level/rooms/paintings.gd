extends RefCounted
## Crimson wing. Large canvases and low exhibit islands shape a readable patrol route.

const WARM := Color(1.0, 0.76, 0.51)
const MOON := Color(0.58, 0.73, 1.0)

static var _art: Dictionary = {}
static var _quad: QuadMesh


static func dress(kit: LevelKit, room_id: String) -> void:
	if room_id != "paintings":
		return
	# Guard rectangle x=18..34, z=6..18; keep the west arch, east door and south vent open.
	_partition(kit, room_id, 22.1, 0.8, 5.2)
	_partition(kit, room_id, 28.4, 10.0, 5.0)
	_partition(kit, room_id, 22.8, 14.1, 4.8)
	# Salon-scale canvases: centres at eye height, with breathing room for gilded rims.
	for data in [
		[Vector3(21.88, 2.44, 0.8), -PI * 0.5, "hanging_picture_frame_02", 2.45, 0],
		[Vector3(22.32, 2.44, 0.8), PI * 0.5, "fancy_picture_frame_02", 2.35, 2],
		[Vector3(28.18, 2.44, 10.0), -PI * 0.5, "fancy_picture_frame_01", 2.35, 1],
		[Vector3(28.62, 2.44, 10.0), PI * 0.5, "hanging_picture_frame_01", 2.55, 0],
		[Vector3(22.58, 2.44, 14.1), -PI * 0.5, "hanging_picture_frame_03", 2.45, 2],
		[Vector3(37.30, 2.55, 10.0), -PI * 0.5, "hanging_picture_frame_02", 2.35, 1],
		[Vector3(37.30, 2.55, 17.3), -PI * 0.5, "fancy_picture_frame_01", 2.25, 0],
		[Vector3(37.30, 2.55, 1.8), -PI * 0.5, "fancy_picture_frame_02", 2.25, 2],
		[Vector3(14.70, 2.55, -3.5), PI * 0.5, "hanging_picture_frame_02", 2.35, 1],
		[Vector3(14.70, 2.55, 12.5), PI * 0.5, "fancy_picture_frame_02", 2.30, 2],
		[Vector3(14.70, 2.55, 19.5), PI * 0.5, "hanging_picture_frame_01", 2.25, 0],
		[Vector3(19.6, 2.55, 23.34), PI, "fancy_picture_frame_02", 2.35, 2],
		[Vector3(26.3, 2.55, 23.34), PI, "hanging_picture_frame_02", 2.25, 0],
		[Vector3(34.0, 2.55, 23.34), PI, "hanging_picture_frame_02", 2.45, 1],
		[Vector3(19.0, 2.55, -7.54), 0.0, "hanging_picture_frame_01", 2.35, 0],
		[Vector3(25.5, 2.55, -7.54), 0.0, "fancy_picture_frame_01", 2.15, 1],
	]:
		_painting(kit, room_id, data[0], data[1], data[2], data[3], data[4])
	# Shallow wall bays keep the long walls at a human scale.
	for z in [10.0, 17.3]:
		_wall_bay(kit, room_id, Vector3(37.72, 2.78, z), true)
	for x in [19.6, 26.3, 34.0]:
		_wall_bay(kit, room_id, Vector3(x, 2.7, 23.7), false)
	# Two carpeted seating islands replace the bare central parquet, without closing the guard loop.
	_seating_island(kit, room_id, Vector3(26.0, 0, 2.15), 4.7)
	_seating_island(kit, room_id, Vector3(26.0, 0, 15.4), 4.4)
	# Side galleries have low cases and a staggered bust collection for crouch cover.
	for p in [Vector3(18.0, 0, -0.7), Vector3(33.8, 0, 2.0), Vector3(36.3, 0, 11.8), Vector3(18.1, 0, 20.8)]:
		_bust_island(kit, room_id, p)
	for p in [Vector3(32.5, 0, 21.2), Vector3(20.7, 0, 10.7)]:
		_display_case(kit, room_id, p)
	# A roped portrait study creates a close-up exhibit near the conservator's easel.
	_rope_exhibit(kit, room_id, Vector3(18.8, 0, -4.0))
	# Conservator's easel in a quiet corner, away from patrol lines.
	_easel(kit, room_id, Vector3(18.1, 0, -3.9))
	# Velvet proscenium behind the jewel; east service door stays accessible.
	_piece(kit, room_id, Vector3(33, 3.65, -7.35), Vector3(6.2, 0.2, 0.16), kit.mat("gold"))
	_piece(kit, room_id, Vector3(33, 3.43, -7.34), Vector3(5.5, 0.18, 0.13), kit.mat("wood_dark"))
	for side in [-1.0, 1.0]:
		var x: float = 33.0 + float(side) * 2.8
		_drape(kit, room_id, x, -6.92)
		_piece(kit, room_id, Vector3(x, 2.02, -7.22), Vector3(0.18, 3.05, 0.16), kit.mat("gold"))
	_piece(kit, room_id, Vector3(33, 0.02, -6.95), Vector3(4.1, 0.035, 0.65), kit.mat("carpet_blue"))
	kit.label(room_id, "THE BLUE WONDER", Vector3(33, 3.0, -7.08), 0.0, 32)
	# Existing base ceiling lights provide fill; visible chandeliers provide the warm pools.
	for z in [-2.7, 8.0, 18.7]:
		_chandelier(kit, room_id, Vector3(26.0, 4.78, z), z == 8.0)
	# Track heads make the large canvases and furniture legible without flattening the edges.
	for x in [18.2, 34.3]:
		_track(kit, room_id, x)
	for p in [Vector3(37.2, 0, 5.4), Vector3(37.2, 0, 20.8), Vector3(14.8, 0, 0.6), Vector3(14.8, 0, 16.1)]:
		_sconce(kit, room_id, p, -PI * 0.5 if p.x > 26.0 else PI * 0.5)
	# Reflected warm fill lifts silhouettes between the fixture pools.
	for z in [-3.0, 5.5, 14.5, 21.0]:
		kit.omni(room_id, Vector3(26.0, 3.6, z), WARM, 0.45, 7.8)
	# Cold spill enters through the east service threshold from its windowed corridor.
	kit.spot(room_id, Vector3(37.3, 2.8, -4.0), Vector3(32.0, 0.8, -2.0), Color(0.57, 0.72, 1.0), 0.85, 7.2, 43.0)
	_piece(kit, room_id, Vector3(33, 5.3, -7.0), Vector3(0.32, 0.16, 0.26), kit.mat("brass"))
	_piece(kit, room_id, Vector3(33, 5.19, -6.85), Vector3(0.24, 0.025, 0.09), kit.mat("emissive_cool"))
	kit.spot(room_id, Vector3(33, 5.3, -6.9), Vector3(33, 1.35, -3), Color(0.7, 0.82, 1.0), 1.45, 6.5, 32.0)


static func _partition(kit: LevelKit, room_id: String, x: float, z: float, length: float) -> void:
	kit.solid(room_id, Vector3(x, 0, z), Vector3(0.28, 3.0, length), kit.mat("wallpaper_red"))
	for y in [0.14, 0.9, 2.82]:
		var thick := 0.38 if y != 0.9 else 0.31
		_piece(kit, room_id, Vector3(x, y, z), Vector3(thick, 0.075, length + 0.12), kit.mat("wood_dark"))
		_piece(kit, room_id, Vector3(x, y + 0.065, z), Vector3(thick + 0.035, 0.022, length + 0.16), kit.mat("gold"))
	for end in [-1.0, 1.0]:
		_piece(kit, room_id, Vector3(x, 1.5, z + end * length * 0.5), Vector3(0.34, 2.83, 0.08), kit.mat("wood_dark"))


static func _seating_island(kit: LevelKit, room_id: String, p: Vector3, length: float) -> void:
	# Thin layered carpet with a stitched border; scanned upholstery is at honest seat scale.
	_piece(kit, room_id, p + Vector3.UP * 0.026, Vector3(length + 0.18, 0.038, 3.0), kit.mat("brass"))
	_piece(kit, room_id, p + Vector3.UP * 0.05, Vector3(length, 0.022, 2.82), kit.mat("carpet_red"))
	_piece(kit, room_id, p + Vector3.UP * 0.064, Vector3(length - 0.24, 0.009, 2.58), kit.mat("carpet_blue"))
	for side in [-1.0, 1.0]:
		var seat := p + Vector3(side * 1.05, 0, 0)
		kit.model(room_id, "Sofa_01", Transform3D(Basis(Vector3.UP, side * PI * 0.5), seat), 0.81)
	kit.model(room_id, "Ottoman_01", Transform3D(Basis.IDENTITY, p), 0.54)


static func _bust_island(kit: LevelKit, room_id: String, p: Vector3) -> void:
	kit.cylinder_solid(room_id, p, 0.52, 0.93, kit.mat("marble_black"))
	var collar := CylinderMesh.new()
	collar.top_radius = 0.62
	collar.bottom_radius = 0.55
	collar.height = 0.12
	collar.radial_segments = 32
	kit.prop(room_id, collar, Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.91), kit.mat("marble_white"))
	kit.model(room_id, "marble_bust_01", Transform3D(Basis(Vector3.UP, p.z * 0.13), p + Vector3.UP * 0.97), 0.62, "none")
	_accent(kit, room_id, p + Vector3.UP * 1.38, p + Vector3(0.6, 5.92, 0.4))


static func _display_case(kit: LevelKit, room_id: String, p: Vector3) -> void:
	# Marble plinth, bevelled cap, glazed volume and a single scanned object inside.
	kit.solid(room_id, p, Vector3(1.75, 0.72, 0.95), kit.mat("marble_black"))
	_piece(kit, room_id, p + Vector3.UP * 0.73, Vector3(1.88, 0.10, 1.08), kit.mat("marble_white"))
	_piece(kit, room_id, p + Vector3.UP * 1.14, Vector3(1.62, 0.72, 0.82), kit.mat("glass"))
	_piece(kit, room_id, p + Vector3.UP * 1.53, Vector3(1.84, 0.07, 1.04), kit.mat("brass"))
	kit.model(room_id, "antique_ceramic_vase_01", Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.79), 0.53, "none")
	_accent(kit, room_id, p + Vector3.UP * 1.12, p + Vector3(0.3, 5.92, -0.1))


static func _rope_exhibit(kit: LevelKit, room_id: String, p: Vector3) -> void:
	for z in [p.z - 1.15, p.z + 1.15]:
		for x in [p.x - 1.25, p.x + 1.25]:
			var base := Vector3(x, 0, z)
			var foot := CylinderMesh.new()
			foot.top_radius = 0.16
			foot.bottom_radius = 0.22
			foot.height = 0.09
			kit.prop(room_id, foot, Transform3D(Basis.IDENTITY, base + Vector3.UP * 0.045), kit.mat("brass"))
			var post := CylinderMesh.new()
			post.top_radius = 0.045
			post.bottom_radius = 0.065
			post.height = 0.76
			kit.prop(room_id, post, Transform3D(Basis.IDENTITY, base + Vector3.UP * 0.45), kit.mat("brass"))
			var finial := SphereMesh.new()
			finial.radius = 0.09
			finial.height = 0.18
			kit.prop(room_id, finial, Transform3D(Basis.IDENTITY, base + Vector3.UP * 0.86), kit.mat("gold"))
		_rope(kit, room_id, Vector3(p.x - 1.25, 0.65, z), Vector3(p.x + 1.25, 0.65, z))


static func _rope(kit: LevelKit, room_id: String, a: Vector3, b: Vector3) -> void:
	for i in range(12):
		var t := (float(i) + 0.5) / 12.0
		var sag := 0.24 * sin(t * PI)
		var q := a.lerp(b, t) - Vector3.UP * sag
		var bead := SphereMesh.new()
		bead.radius = 0.065
		bead.height = 0.13
		kit.prop(room_id, bead, Transform3D(Basis.IDENTITY, q), kit.mat("velvet_red"))


static func _painting(kit: LevelKit, room_id: String, center: Vector3, yaw: float, frame_id: String, frame_height: float, subject: int) -> void:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2.ONE
	var facing := Basis(Vector3.UP, yaw)
	var ratio := 1.0
	match frame_id:
		"fancy_picture_frame_01": ratio = 0.60 / 0.46
		"fancy_picture_frame_02": ratio = 0.66 / 0.77
		"hanging_picture_frame_01": ratio = 0.59 / 0.84
		"hanging_picture_frame_02": ratio = 0.75 / 0.50
		"hanging_picture_frame_03": ratio = 0.39 / 0.50
	var width := frame_height * ratio
	# Model origin is grounded by LevelKit; the canvas stays inside its sculpted rim.
	kit.model(room_id, frame_id, Transform3D(facing, center - Vector3.UP * frame_height * 0.5), frame_height, "none")
	var canvas_size := Vector3(width * 0.72, frame_height * 0.72, 1.0)
	kit.prop(room_id, _quad, Transform3D(facing.scaled(canvas_size), center + facing * Vector3(0, 0, 0.065)), _art_material(subject))
	_picture_light(kit, room_id, center + facing * Vector3(0, frame_height * 0.5 + 0.24, 0.23), yaw, width)


static func _picture_light(kit: LevelKit, room_id: String, pos: Vector3, yaw: float, width: float) -> void:
	var facing := Basis(Vector3.UP, yaw)
	var bar_width := clampf(width * 0.5, 0.42, 0.82)
	_piece(kit, room_id, pos, Vector3(bar_width, 0.055, 0.12), kit.mat("brass"), yaw)
	_piece(kit, room_id, pos + facing * Vector3(0, -0.045, 0.045), Vector3(bar_width * 0.88, 0.02, 0.045), kit.mat("emissive_warm"), yaw)
	for side in [-1.0, 1.0]:
		_piece(kit, room_id, pos + facing * Vector3(side * bar_width * 0.42, 0.0, -0.12), Vector3(0.025, 0.025, 0.28), kit.mat("brass"), yaw)
	kit.spot(room_id, pos + facing * Vector3(0, -0.05, 0.08), pos + facing * Vector3(0, -1.0, 0.1), WARM, 1.35, 3.8, 61.0)


static func _chandelier(kit: LevelKit, room_id: String, pos: Vector3, shadows: bool) -> void:
	kit.model(room_id, "Chandelier_01", Transform3D(Basis.IDENTITY, pos), 1.45, "none")
	_piece(kit, room_id, pos + Vector3(0, 1.61, 0), Vector3(0.065, 0.62, 0.065), kit.mat("brass"))
	kit.omni(room_id, pos + Vector3(0, 0.52, 0), WARM, 2.35, 9.5, shadows)


static func _track(kit: LevelKit, room_id: String, x: float) -> void:
	_piece(kit, room_id, Vector3(x, 6.31, 8.0), Vector3(0.085, 0.09, 27.0), kit.mat("brass"))
	for z in [-4.0, 0.5, 5.4, 10.3, 15.2, 20.0]:
		var p := Vector3(x, 6.08, z)
		_piece(kit, room_id, p + Vector3.UP * 0.13, Vector3(0.06, 0.34, 0.06), kit.mat("brass"))
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.13
		cylinder.bottom_radius = 0.15
		cylinder.height = 0.28
		kit.prop(room_id, cylinder, Transform3D(Basis.IDENTITY, p), kit.mat("brass"))
		var lens := SphereMesh.new()
		lens.radius = 0.11
		lens.height = 0.09
		kit.prop(room_id, lens, Transform3D(Basis.IDENTITY, p + Vector3.DOWN * 0.19), kit.mat("emissive_warm"))
		var target := Vector3(20.6 if x < 26.0 else 35.5, 1.9, z)
		kit.spot(room_id, p + Vector3.DOWN * 0.22, target, WARM, 1.35, 7.2, 38.0)


static func _sconce(kit: LevelKit, room_id: String, p: Vector3, yaw: float) -> void:
	var inward := Vector3(-1, 0, 0) if p.x > 26.0 else Vector3(1, 0, 0)
	var bracket := p + inward * 0.18 + Vector3.UP * 2.14
	_piece(kit, room_id, bracket, Vector3(0.33, 0.08, 0.54), kit.mat("marble_white"))
	_piece(kit, room_id, bracket + Vector3.UP * 0.06, Vector3(0.38, 0.035, 0.58), kit.mat("brass"))
	kit.model(room_id, "brass_candleholders", Transform3D(Basis(Vector3.UP, yaw), p + inward * 0.2 + Vector3.UP * 2.21), 0.59, "none")
	kit.omni(room_id, p + inward * 0.33 + Vector3.UP * 2.78, WARM, 1.05, 5.2)


static func _accent(kit: LevelKit, room_id: String, target: Vector3, fixture: Vector3) -> void:
	var cup := CylinderMesh.new()
	cup.top_radius = 0.12
	cup.bottom_radius = 0.15
	cup.height = 0.18
	kit.prop(room_id, cup, Transform3D(Basis.IDENTITY, fixture), kit.mat("brass"))
	var lens := SphereMesh.new()
	lens.radius = 0.09
	lens.height = 0.08
	kit.prop(room_id, lens, Transform3D(Basis.IDENTITY, fixture + Vector3.DOWN * 0.13), kit.mat("emissive_warm"))
	kit.spot(room_id, fixture + Vector3.DOWN * 0.15, target, WARM, 1.25, 6.0, 31.0)


static func _wall_bay(kit: LevelKit, room_id: String, center: Vector3, east: bool) -> void:
	var axis_size := Vector3(0.1, 3.7, 4.0) if east else Vector3(4.0, 3.7, 0.1)
	_piece(kit, room_id, center, axis_size, kit.mat("wood_dark"))
	var face := Vector3(-0.075, 0, 0) if east else Vector3(0, 0, -0.075)
	_piece(kit, room_id, center + face, axis_size * Vector3(0.35 if east else 0.92, 0.9, 0.92 if east else 0.35), kit.mat("wallpaper_red"))
	for offset in [-1.95, 1.95]:
		var edge := Vector3(0, 0, offset) if east else Vector3(offset, 0, 0)
		_piece(kit, room_id, center + edge + face * 1.4, Vector3(0.11, 3.9, 0.085) if east else Vector3(0.085, 3.9, 0.11), kit.mat("brass"))
	for y in [-1.85, 1.85]:
		_piece(kit, room_id, center + Vector3(0, y, 0) + face * 1.4, Vector3(0.1, 0.09, 4.02) if east else Vector3(4.02, 0.09, 0.1), kit.mat("brass"))


static func _easel(kit: LevelKit, room_id: String, pos: Vector3) -> void:
	# An unfinished study adds a near-field exhibit without taking the patrol route.
	for side in [-1.0, 1.0]:
		_piece(kit, room_id, pos + Vector3(side * 0.28, 0.91, 0), Vector3(0.07, 1.82, 0.07), kit.mat("wood_light"), side * 0.14)
	_piece(kit, room_id, pos + Vector3(0, 0.96, 0.18), Vector3(0.06, 1.75, 0.06), kit.mat("wood_light"))
	_piece(kit, room_id, pos + Vector3(0, 1.0, -0.05), Vector3(0.85, 0.065, 0.2), kit.mat("wood_dark"))
	_piece(kit, room_id, pos + Vector3(0, 1.68, -0.025), Vector3(0.9, 1.12, 0.06), kit.mat("wood_dark"))
	kit.prop(room_id, _quad, Transform3D(Basis.IDENTITY.scaled(Vector3(0.77, 0.98, 1)), pos + Vector3(0, 1.68, 0.013)), _art_material(0))
	var marker := BoxMesh.new()
	marker.size = Vector3(0.01, 0.01, 0.01)
	kit.prop(room_id, marker, Transform3D(Basis.IDENTITY, pos), kit.mat("wood_dark"), Vector3(0.85, 1.9, 0.55))


static func _art_material(subject: int) -> StandardMaterial3D:
	if _art.has(subject):
		return _art[subject]
	var img := Image.create(256, 176, false, Image.FORMAT_RGBA8)
	for py in range(176):
		for px in range(256):
			img.set_pixel(px, py, _pixel(subject, float(px) / 255.0, float(py) / 175.0, px, py))
	img.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(img)
	material.roughness = 0.55
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_art[subject] = material
	return material


static func _pixel(subject: int, u: float, v: float, px: int, py: int) -> Color:
	var grain := sin(float(px * 37 + py * 71)) * sin(float(px * 13 - py * 19)) * 0.025
	var color: Color
	if subject == 0: # Moonlit sea, black headland and silver wake.
		color = Color(0.025, 0.048, 0.11).lerp(Color(0.27, 0.34, 0.44), clampf(v / 0.57, 0.0, 1.0))
		var moon := Vector2(u - 0.72, v - 0.29).length()
		if moon < 0.075:
			color = Color(0.94, 0.86, 0.65).lerp(color, smoothstep(0.052, 0.075, moon))
		if v > 0.57:
			color = Color(0.028, 0.075, 0.13).lerp(Color(0.08, 0.16, 0.22), (v - 0.57) * 1.8)
			if absf(u - 0.72) < (v - 0.52) * 0.22 and sin(float(py) * 1.7 + sin(float(px) * 0.7) * 2.0) > 0.58:
				color = color.lerp(Color(0.62, 0.7, 0.67), 0.48)
		if u < 0.37 and v > 0.52 - u * 0.3:
			color = Color(0.018, 0.034, 0.056)
	elif subject == 1: # Rain-dark city with amber windows and reflections.
		color = Color(0.025, 0.038, 0.09).lerp(Color(0.28, 0.21, 0.22), v * 0.8)
		var roof := 0.37 + 0.13 * sin(floorf(u * 12.0) * 17.0)
		if v > roof:
			color = Color(0.03, 0.035, 0.065).lerp(Color(0.11, 0.065, 0.065), v * 0.4)
			if posmod(px, 17) < 3 and posmod(py, 19) < 5 and v < 0.78:
				color = Color(0.91, 0.58, 0.25)
		if v > 0.78 and absf(sin(u * 90.0 + v * 17.0)) > 0.83:
			color = color.lerp(Color(0.58, 0.32, 0.16), 0.5)
	else: # Formal portrait silhouette against glazed red umber.
		color = Color(0.2, 0.055, 0.045).lerp(Color(0.52, 0.27, 0.15), 1.0 - v)
		if pow((u - 0.5) / 0.39, 2.0) + pow((v - 0.46) / 0.55, 2.0) < 1.0:
			color = color.lerp(Color(0.4, 0.24, 0.15), 0.35)
		if pow((u - 0.51) / 0.1, 2.0) + pow((v - 0.36) / 0.16, 2.0) < 1.0 or pow((u - 0.5) / 0.29, 2.0) + pow((v - 0.79) / 0.32, 2.0) < 1.0:
			color = Color(0.035, 0.045, 0.068)
		if absf(u - 0.5) < 0.018 and v > 0.61 and v < 0.91:
			color = Color(0.76, 0.66, 0.46)
	return Color(clampf(color.r + grain, 0, 1), clampf(color.g + grain, 0, 1), clampf(color.b + grain, 0, 1))


static func _drape(kit: LevelKit, room_id: String, x: float, z: float) -> void:
	for i in range(7):
		var fold := float(i) - 3.0
		_piece(kit, room_id, Vector3(x + fold * 0.095, 2.56, z + 0.055 * cos(float(i) * PI)), Vector3(0.13, 1.75 + 0.08 * absf(fold), 0.11), kit.mat("velvet_blue"))
	_piece(kit, room_id, Vector3(x, 3.46, z), Vector3(0.9, 0.095, 0.2), kit.mat("gold"))
	_piece(kit, room_id, Vector3(x, 2.2, z + 0.12), Vector3(0.8, 0.06, 0.09), kit.mat("gold"))


static func _piece(kit: LevelKit, room_id: String, center: Vector3, size: Vector3, material: Material, yaw := 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	kit.prop(room_id, mesh, Transform3D(Basis(Vector3.UP, yaw), center), material)
