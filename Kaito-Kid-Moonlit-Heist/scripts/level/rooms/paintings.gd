extends RefCounted
## Crimson wing. Screens turn the patrol's open centre into a readable cover route.

static var _art: Dictionary = {}
static var _quad: QuadMesh


static func dress(kit: LevelKit, room_id: String) -> void:
	if room_id != "paintings":
		return
	# Guard rectangle x=18..34, z=6..18; keep the west arch, east door and south vent open.
	_partition(kit, room_id, 22.1, 0.8, 5.2)
	_partition(kit, room_id, 28.4, 10.0, 5.0)
	_partition(kit, room_id, 22.8, 14.1, 4.8)
	# Scanned ornate frames hold separate generated canvases behind their openings.
	_painting(kit, room_id, Vector3(21.89, 2.14, 0.8), -PI * 0.5, "hanging_picture_frame_02", 1.45, 0)
	_painting(kit, room_id, Vector3(22.31, 2.12, 0.8), PI * 0.5, "fancy_picture_frame_02", 1.75, 2)
	_painting(kit, room_id, Vector3(28.19, 2.16, 10.0), -PI * 0.5, "fancy_picture_frame_01", 1.55, 1)
	_painting(kit, room_id, Vector3(28.61, 2.16, 10.0), PI * 0.5, "hanging_picture_frame_01", 1.7, 0)
	_painting(kit, room_id, Vector3(22.59, 2.1, 14.1), -PI * 0.5, "hanging_picture_frame_03", 1.65, 2)
	_painting(kit, room_id, Vector3(37.3, 2.8, 9.5), -PI * 0.5, "hanging_picture_frame_02", 1.55, 1)
	_painting(kit, room_id, Vector3(37.3, 2.75, 16.6), -PI * 0.5, "fancy_picture_frame_01", 1.45, 0)
	_painting(kit, room_id, Vector3(19.7, 2.7, 23.4), PI, "fancy_picture_frame_02", 1.55, 2)
	_painting(kit, room_id, Vector3(34.3, 2.7, 23.4), PI, "hanging_picture_frame_02", 1.35, 1)
	_painting(kit, room_id, Vector3(19.0, 2.75, -7.57), 0.0, "hanging_picture_frame_01", 1.55, 0)
	_painting(kit, room_id, Vector3(25.0, 2.75, -7.57), 0.0, "fancy_picture_frame_01", 1.35, 1)
	# Shallow wall bays keep the long walls at a human scale.
	for z in [9.5, 16.6]:
		_wall_bay(kit, room_id, Vector3(37.72, 2.78, z), true)
	for x in [19.7, 34.3]:
		_wall_bay(kit, room_id, Vector3(x, 2.7, 23.7), false)
	for data in [[25.0, 3.8, PI * 0.5], [24.8, 10.0, PI * 0.5], [30.0, 15.0, PI * 0.5]]:
		kit.model(room_id, "painted_wooden_bench", Transform3D(Basis(Vector3.UP, data[2]), Vector3(data[0], 0, data[1])), 0.89)
	kit.model(room_id, "Ottoman_01", Transform3D(Basis.IDENTITY, Vector3(31.0, 0, 1.7)), 0.5)
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
	kit.spot(room_id, pos + facing * Vector3(0, -0.05, 0.06), pos + facing * Vector3(0, -0.85, 0.1), Color(1.0, 0.72, 0.43), 0.82, 2.8, 54.0)


static func _chandelier(kit: LevelKit, room_id: String, pos: Vector3, shadows: bool) -> void:
	kit.model(room_id, "Chandelier_01", Transform3D(Basis.IDENTITY, pos), 1.45, "none")
	_piece(kit, room_id, pos + Vector3(0, 1.61, 0), Vector3(0.065, 0.62, 0.065), kit.mat("brass"))
	kit.omni(room_id, pos + Vector3(0, 0.52, 0), Color(1.0, 0.69, 0.4), 1.55, 8.5, shadows)


static func _wall_bay(kit: LevelKit, room_id: String, center: Vector3, east: bool) -> void:
	var axis_size := Vector3(0.1, 3.7, 3.1) if east else Vector3(3.1, 3.7, 0.1)
	_piece(kit, room_id, center, axis_size, kit.mat("wood_dark"))
	var face := Vector3(-0.075, 0, 0) if east else Vector3(0, 0, -0.075)
	_piece(kit, room_id, center + face, axis_size * Vector3(0.35 if east else 0.92, 0.9, 0.92 if east else 0.35), kit.mat("wallpaper_red"))
	for offset in [-1.5, 1.5]:
		var edge := Vector3(0, 0, offset) if east else Vector3(offset, 0, 0)
		_piece(kit, room_id, center + edge + face * 1.4, Vector3(0.11, 3.9, 0.085) if east else Vector3(0.085, 3.9, 0.11), kit.mat("brass"))
	for y in [-1.85, 1.85]:
		_piece(kit, room_id, center + Vector3(0, y, 0) + face * 1.4, Vector3(0.1, 0.09, 3.12) if east else Vector3(3.12, 0.09, 0.1), kit.mat("brass"))


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
