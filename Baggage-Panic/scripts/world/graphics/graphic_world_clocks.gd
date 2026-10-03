extends RefCounted
## Five working world clocks set into a single oak airport wall panel.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "WorldClockWall"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "world_clock_walnut")
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "world_clock_oak")
	var brass: StandardMaterial3D = DesignKit.brass()
	var ink: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.44, 0.58, "world_clock_ink")

	# The wall panel floats at a comfortable reading height above its floor origin.
	DesignKit.rbox(root, Vector3(6.0, 1.5, 0.12), Vector3(0.0, 2.2, -0.06), walnut, 0.065)
	DesignKit.rbox(root, Vector3(5.91, 1.41, 0.045), Vector3(0.0, 2.2, 0.018), oak, 0.04)
	DesignKit.rbox(root, Vector3(5.76, 0.012, 0.012), Vector3(0.0, 2.848, 0.048), brass, 0.004, false)
	DesignKit.rbox(root, Vector3(5.76, 0.012, 0.012), Vector3(0.0, 1.551, 0.048), brass, 0.004, false)

	var utc_seconds: int = int(Time.get_unix_time_from_system())
	var europe_offset: int = 2 if _europe_summer_time(utc_seconds) else 1
	var cities: Array[String] = ["TOKYO", "HÀ NỘI", "SHANGHAI", "PARIS", "MADRID"]
	var offsets: Array[int] = [9, 7, 8, europe_offset, europe_offset]
	var x_positions: Array[float] = [-2.30, -1.15, 0.0, 1.15, 2.30]
	for i in cities.size():
		var x: float = x_positions[i]
		var time: Dictionary = Time.get_datetime_dict_from_unix_time(utc_seconds + offsets[i] * 3600)
		_add_clock(root, x, int(time["hour"]), int(time["minute"]), ink, brass)
		_add_city(root, cities[i], x)
	return root


static func _add_clock(parent: Node3D, x: float, hour: int, minute: int, ink: Material, brass: Material) -> void:
	var center := Vector3(x, 2.35, 0.0)
	DesignKit.add(parent, _rim_mesh(), brass, center + Vector3(0.0, 0.0, 0.082), Vector3(90.0, 0.0, 0.0))
	DesignKit.add(parent, _dial_mesh(), _dial_material(), center + Vector3(0.0, 0.0, 0.122), Vector3.ZERO, false)
	# Two slim, rounded steel hands sit proud of the printed dial; the pin is brass.
	var minute_angle: float = -6.0 * float(minute)
	var hour_angle: float = -30.0 * (float(hour % 12) + float(minute) / 60.0)
	var minute_hand := DesignKit.rbox(parent, Vector3(0.015, 0.286, 0.012), center + Vector3(0.0, 0.137, 0.140), ink, 0.006, false)
	minute_hand.position = center + Vector3(sin(deg_to_rad(-minute_angle)) * 0.137, cos(deg_to_rad(minute_angle)) * 0.137, 0.140)
	minute_hand.rotation_degrees.z = minute_angle
	var hour_hand := DesignKit.rbox(parent, Vector3(0.023, 0.205, 0.014), center + Vector3.ZERO, ink, 0.008, false)
	hour_hand.position = center + Vector3(sin(deg_to_rad(-hour_angle)) * 0.098, cos(deg_to_rad(hour_angle)) * 0.098, 0.148)
	hour_hand.rotation_degrees.z = hour_angle
	DesignKit.add(parent, _pin_mesh(), brass, center + Vector3(0.0, 0.0, 0.159), Vector3(90.0, 0.0, 0.0), false)


static func _add_city(parent: Node3D, city: String, x: float) -> void:
	var label := Label3D.new()
	label.name = city
	label.text = city
	label.font = Signage.font()
	label.font_size = 78
	label.pixel_size = 0.0025
	var width: float = label.font.get_string_size(city, HORIZONTAL_ALIGNMENT_CENTER, -1, label.font_size).x * label.pixel_size
	if width > 1.05:
		label.font_size = maxi(52, int(float(label.font_size) * 1.05 / width))
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.position = Vector3(x, 1.753, 0.060)
	label.visibility_range_end = 70.0
	label.visibility_range_end_margin = 10.0
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _rim_mesh() -> CylinderMesh:
	if not _meshes.has("rim"):
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.430
		mesh.bottom_radius = 0.430
		mesh.height = 0.072
		mesh.radial_segments = 64
		_meshes["rim"] = mesh
	return _meshes["rim"] as CylinderMesh


static func _dial_mesh() -> QuadMesh:
	if not _meshes.has("dial"):
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.806, 0.806)
		_meshes["dial"] = mesh
	return _meshes["dial"] as QuadMesh


static func _pin_mesh() -> CylinderMesh:
	if not _meshes.has("pin"):
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.022
		mesh.bottom_radius = 0.022
		mesh.height = 0.016
		mesh.radial_segments = 16
		_meshes["pin"] = mesh
	return _meshes["pin"] as CylinderMesh


static func _dial_material() -> StandardMaterial3D:
	if _materials.has("dial"):
		return _materials["dial"] as StandardMaterial3D
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var paper: Color = DesignKit.CREAM
	var sage: Color = DesignKit.SAGE
	var charcoal: Color = DesignKit.CHARCOAL
	var middle := Vector2(255.5, 255.5)
	for y in 512:
		for x in 512:
			var p := Vector2(float(x), float(y)) - middle
			var radius: float = p.length()
			if radius > 253.0:
				continue
			var color: Color = paper
			if radius > 245.0:
				color = sage
			elif radius > 224.0:
				color = paper.darkened(0.045)
			else:
				for tick in 12:
					var angle: float = float(tick) * TAU / 12.0
					var along: float = p.dot(Vector2(sin(angle), -cos(angle)))
					var across: float = absf(p.dot(Vector2(cos(angle), sin(angle))))
					if along > (181.0 if tick % 3 == 0 else 198.0) and along < 215.0 and across < (5.0 if tick % 3 == 0 else 2.5):
						color = charcoal
						break
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.roughness = 0.9
	_materials["dial"] = material
	return material


static func _europe_summer_time(utc_seconds: int) -> bool:
	var date: Dictionary = Time.get_datetime_dict_from_unix_time(utc_seconds)
	var year: int = int(date["year"])
	var march_end: int = Time.get_unix_time_from_datetime_dict({"year": year, "month": 3, "day": 31, "hour": 0, "minute": 0, "second": 0})
	var october_end: int = Time.get_unix_time_from_datetime_dict({"year": year, "month": 10, "day": 31, "hour": 0, "minute": 0, "second": 0})
	var march_date: Dictionary = Time.get_datetime_dict_from_unix_time(march_end)
	var october_date: Dictionary = Time.get_datetime_dict_from_unix_time(october_end)
	var start: int = march_end - int(march_date["weekday"]) * 86400 + 3600
	var finish: int = october_end - int(october_date["weekday"]) * 86400 + 3600
	return utc_seconds >= start and utc_seconds < finish
