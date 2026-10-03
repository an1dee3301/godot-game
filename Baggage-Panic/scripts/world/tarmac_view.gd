class_name TarmacView
extends Node3D
## Recycled exterior airfield seen through the terminal curtain wall.

const TILE_LENGTH := 36.0
const TILE_COUNT := 10
const GROUND_Y := -0.6

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}
static var _apron_texture: ImageTexture
static var _module_scripts: Dictionary = {}
static var _liveries: Array[Dictionary] = []

const LIVERY_DIR: String = "res://scripts/world/liveries"
static var _fuselage_rings: PackedVector2Array = PackedVector2Array([
	Vector2(-0.5, 0.04), Vector2(-0.46, 0.42), Vector2(-0.39, 0.83),
	Vector2(-0.3, 1.0), Vector2(0.31, 1.0), Vector2(0.41, 0.75),
	Vector2(0.48, 0.27), Vector2(0.5, 0.02)
])

var _tiles: Array[Node3D] = []
var _lamps: Array[SpotLight3D] = []
var _beacons: Array[MeshInstance3D] = []
var _traffic: Array[Node3D] = []
var _vehicles: Array[Node3D] = []
var _elapsed := 0.0
var _player_z := 0.0
var _intensity := 0.0


func _ready() -> void:
	_load_liveries()
	if _apron_texture == null:
		_apron_texture = _make_apron_texture()
	for i in TILE_COUNT:
		var tile := Node3D.new()
		tile.name = "AirfieldTile%02d" % i
		tile.position.z = TILE_LENGTH - float(i) * TILE_LENGTH
		add_child(tile)
		_tiles.append(tile)
		_build_tile(tile, i)
	for i in 3:
		var plane := Node3D.new()
		plane.name = ["TaxiingAirliner", "DepartingAirliner", "ArrivingAirliner"][i]
		add_child(plane)
		_build_aircraft(plane, TILE_COUNT + i, i == 2)
		_traffic.append(plane)
	for side in [-1.0, 1.0]:
		var van := Node3D.new()
		van.name = "MovingServiceVehicle"
		add_child(van)
		_build_tug(van, Vector3.ZERO, 2 if side < 0.0 else 1)
		_vehicles.append(van)
	set_process(true)


func follow(player_z: float) -> void:
	if player_z > _player_z + TILE_LENGTH * 2.0:
		for i in _tiles.size():
			_tiles[i].position.z = TILE_LENGTH - float(i) * TILE_LENGTH
	for tile in _tiles:
		while tile.position.z > player_z + TILE_LENGTH * 2.0:
			tile.position.z -= TILE_COUNT * TILE_LENGTH
	_player_z = player_z


func set_intensity(amount: float) -> void:
	_intensity = clampf(amount, 0.0, 1.0)
	var night := smoothstep(0.35, 1.0, _intensity)
	for key in ["taxi_light", "runway_light", "apron_lamp", "windows", "beacon", "strobe", "city_window"]:
		(_materials[key] as StandardMaterial3D).emission_energy_multiplier = lerpf(0.55, 5.0, night)
	for key: String in _materials:
		if key.begins_with("livery:") and key.ends_with(":windows"):
			(_materials[key] as StandardMaterial3D).emission_energy_multiplier = lerpf(0.55, 5.0, night)
	for lamp in _lamps:
		lamp.visible = _intensity > 0.5
		lamp.light_energy = 1.4 + night * 3.0


func _process(delta: float) -> void:
	_elapsed += delta
	var phase := fposmod(_elapsed, 52.0) / 52.0
	_traffic[0].position = Vector3(107.0, 1.8, _player_z - 175.0 + fposmod(_elapsed * 5.0, 310.0))
	_traffic[0].rotation_degrees = Vector3(0.0, 180.0, 0.0)
	_traffic[1].position = Vector3(-153.0 - phase * 23.0, 2.0 + 85.0 * phase * phase, _player_z - 30.0 - phase * 230.0)
	_traffic[1].rotation_degrees = Vector3(-18.0 * phase, 0.0, -7.0 * phase)
	var approach := fposmod(_elapsed + 25.0, 52.0) / 52.0
	_traffic[2].position = Vector3(152.0, 2.0 + 75.0 * (1.0 - approach) * (1.0 - approach), _player_z - 220.0 + approach * 230.0)
	_traffic[2].rotation_degrees = Vector3(12.0 * (1.0 - approach), 180.0, 0.0)
	for i in _vehicles.size():
		var side := -1.0 if i == 0 else 1.0
		_vehicles[i].position = Vector3(side * 34.0, 0.0, _player_z - 165.0 + fposmod(_elapsed * (3.3 + float(i)) + float(i) * 130.0, 300.0))
		_vehicles[i].rotation_degrees.y = 180.0 if i == 0 else 0.0
	var beacon_on := fposmod(_elapsed, 0.9) < 0.18
	var strobe_on := fposmod(_elapsed, 1.6) < 0.08
	for i in _beacons.size():
		_beacons[i].visible = beacon_on if i % 2 == 0 else strobe_on


func _build_tile(tile: Node3D, index: int) -> void:
	for side in [-1.0, 1.0]:
		_build_pavement(tile, side, index)
		if index % 2 == (0 if side < 0.0 else 1):
			var stand_z := -18.0 + float((index * 7) % 5 - 2)
			var wide := index % 5 == 4
			var plane := Node3D.new()
			plane.name = "GateAircraft"
			plane.position = Vector3(side * (69.0 if wide else 63.0), 0.0, stand_z)
			plane.rotation_degrees.y = side * 90.0
			tile.add_child(plane)
			_build_aircraft(plane, index + (TILE_COUNT if side > 0.0 else 0), wide)
			_build_jet_bridge(tile, side, stand_z, wide)
			_build_services(tile, side, stand_z, index)
			_build_stand_markings(tile, side, stand_z, index)
		if index % 2 == 0:
			_build_floodlight(tile, side, -3.0)
		if index % 4 == 1:
			_build_hangar(tile, side, -18.0, index)
		if index % 8 == 3 and side < 0.0:
			_build_tower(tile, side, -22.0)
		_build_skyline(tile, side, index)


func _build_pavement(tile: Node3D, side: float, index: int) -> void:
	var concrete := _mat("concrete", Color(0.64, 0.65, 0.63), 0.85)
	concrete.albedo_texture = _apron_texture
	concrete.uv1_triplanar = true
	_box(tile, Vector3(side * 64.0, -0.68, -18.0), Vector3(67.0, 0.16, TILE_LENGTH), concrete, false)
	_box(tile, Vector3(side * 106.0, -0.7, -18.0), Vector3(20.0, 0.14, TILE_LENGTH), _mat("taxiway", Color(0.31, 0.34, 0.35), 0.94), false)
	_box(tile, Vector3(side * 124.5, -0.72, -18.0), Vector3(17.0, 0.12, TILE_LENGTH), _mat("grass", Color(0.27, 0.38, 0.29), 1.0), false)
	_box(tile, Vector3(side * 157.0, -0.7, -18.0), Vector3(48.0, 0.14, TILE_LENGTH), _mat("runway", Color(0.22, 0.25, 0.27), 0.96), false)
	_box(tile, Vector3(side * 191.0, -0.75, -18.0), Vector3(20.0, 0.1, TILE_LENGTH), _mat("grass", Color(0.27, 0.38, 0.29), 1.0), false)
	# Fine contraction joints and a protected service lane along the glass.
	for x in [40.0, 50.0, 60.0, 70.0, 80.0, 90.0]:
		_box(tile, Vector3(side * x, -0.589, -18.0), Vector3(0.045, 0.008, TILE_LENGTH), _mat("joint", Color(0.42, 0.44, 0.43)), false)
	for z in [-2.0, -14.0, -26.0]:
		_box(tile, Vector3(side * 64.0, -0.585, z), Vector3(66.0, 0.008, 0.045), _mat("joint", Color(0.42, 0.44, 0.43)), false)
	for x in [36.5, 39.5]:
		_box(tile, Vector3(side * x, -0.57, -18.0), Vector3(0.11, 0.015, TILE_LENGTH), _mat("road_line", Color(0.91, 0.89, 0.73)), false)
	_box(tile, Vector3(side * 106.0, -0.615, -18.0), Vector3(0.22, 0.01, TILE_LENGTH), _mat("taxi_yellow", Color(0.91, 0.72, 0.16)), false)
	for x in [99.0, 113.0]:
		_box(tile, Vector3(side * x, -0.61, -18.0), Vector3(0.09, 0.01, TILE_LENGTH), _mat("taxi_yellow", Color(0.91, 0.72, 0.16)), false)
	for z in [-5.0, -17.0, -29.0]:
		_box(tile, Vector3(side * 157.0, -0.61, z), Vector3(0.28, 0.01, 5.5), _mat("runway_white", Color(0.87, 0.89, 0.85)), false)
	if index % 5 == 0:
		for x in [140.0, 145.0, 169.0, 174.0]:
			_box(tile, Vector3(side * x, -0.61, -6.0), Vector3(2.2, 0.01, 9.0), _mat("runway_white", Color(0.87, 0.89, 0.85)), false)
	_multi_lights(tile, side, [106.0], "taxi_light", Color(0.26, 0.9, 0.57), 6)
	_multi_lights(tile, side, [133.5, 181.0], "runway_light", Color(0.92, 0.95, 1.0), 8)


func _build_stand_markings(tile: Node3D, side: float, z: float, index: int) -> void:
	var yellow := _mat("lead_line", Color(0.94, 0.72, 0.12))
	for step in 10:
		var t := float(step) / 9.0
		var x := 37.0 + t * 25.0
		var curve_z := z + side * 7.0 * (1.0 - t) * (1.0 - t)
		var next_t := float(step + 1) / 9.0
		var next_z := z + side * 7.0 * (1.0 - next_t) * (1.0 - next_t)
		var segment := _box(tile, Vector3(side * x, -0.565, curve_z), Vector3(2.9, 0.018, 0.14), yellow, false)
		segment.rotation_degrees.y = rad_to_deg(atan2(next_z - curve_z, side * 2.8))
	_box(tile, Vector3(side * 48.0, -0.552, z), Vector3(0.22, 0.02, 7.0), _mat("stop_red", Color(0.77, 0.13, 0.1)), false)
	var number := Label3D.new()
	number.text = "%02d" % (index + 11 + (20 if side > 0.0 else 0))
	number.font_size = 88
	number.pixel_size = 0.012
	number.modulate = Color(0.9, 0.84, 0.56)
	number.position = Vector3(side * 42.0, -0.548, z - 7.0)
	number.rotation_degrees.x = -90.0
	number.no_depth_test = false
	tile.add_child(number)


func _load_liveries() -> void:
	# Discover at startup so new modules need no manifest or hard dependency.
	var files: PackedStringArray = DirAccess.get_files_at(LIVERY_DIR)
	files.sort()
	for file: String in files:
		if not file.ends_with(".gd"):
			continue
		var path: String = LIVERY_DIR.path_join(file)
		if _module_scripts.has(path):
			continue
		var script: Script = load(path) as Script
		_module_scripts[path] = script
		if script == null or not script.can_instantiate() or not script.has_method("spec"):
			continue
		var result: Variant = script.call("spec")
		if not result is Dictionary:
			continue
		var spec: Dictionary = result
		if not _valid_livery(spec):
			continue
		spec = spec.duplicate()
		spec["path"] = path
		_liveries.append(spec)


func _valid_livery(spec: Dictionary) -> bool:
	for key: String in ["body", "belly", "engine"]:
		if not spec.get(key) is Color:
			return false
	if not spec.get("cheatline") is Array:
		return false
	var stripes: Array = spec["cheatline"]
	for color: Variant in stripes:
		if not color is Color:
			return false
	for key: String in ["tail_texture", "title_texture"]:
		if not spec.get(key) is Texture2D:
			return false
	for key: String in ["accent", "window_color"]:
		if spec.has(key) and not spec[key] is Color:
			return false
	return true


func _livery_texture_material(key: String, texture: Texture2D) -> StandardMaterial3D:
	if not _materials.has(key):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_texture = texture
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = 0.3
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_materials[key] = material
	return _materials[key] as StandardMaterial3D


func _aircraft_part(parent: Node3D, part_name: String, mesh: Mesh, material: Material, body_y: float, shadows: bool = false) -> void:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.material_override = material
	part.position.y = body_y
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)


func _fuselage_band_mesh(length: float, radius: float, stripe: int) -> ArrayMesh:
	var key: String = "fuselage_band:%s:%s:%s" % [length, radius, stripe]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var spans: Array[Vector2] = []
	if stripe < 0:
		spans.append(Vector2(PI + 0.36, TAU - 0.36))
	else:
		var angle: float = -0.12 - float(stripe) * 0.085
		spans.append(Vector2(angle - 0.03, angle + 0.03))
		spans.append(Vector2(PI - angle - 0.03, PI - angle + 0.03))
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for span: Vector2 in spans:
		# Split at the body's polygon edges; paint stays on the tapered shell.
		var angles: Array[float] = [span.x]
		for segment: int in range(floori(span.x * 16.0 / TAU) + 1, ceili(span.y * 16.0 / TAU)):
			angles.append(float(segment) * TAU / 16.0)
		angles.append(span.y)
		for ring: int in _fuselage_rings.size() - 1:
			for segment: int in angles.size() - 1:
				var p0: Vector3 = _fuselage_paint_point(_fuselage_rings[ring], angles[segment], length, radius)
				var p1: Vector3 = _fuselage_paint_point(_fuselage_rings[ring], angles[segment + 1], length, radius)
				var p2: Vector3 = _fuselage_paint_point(_fuselage_rings[ring + 1], angles[segment], length, radius)
				var p3: Vector3 = _fuselage_paint_point(_fuselage_rings[ring + 1], angles[segment + 1], length, radius)
				for point: Vector3 in [p0, p2, p1, p1, p2, p3]:
					surface.add_vertex(point)
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


func _fuselage_paint_point(ring: Vector2, angle: float, length: float, radius: float) -> Vector3:
	var segment: float = angle * 16.0 / TAU
	var a: float = floorf(segment) * TAU / 16.0
	var b: float = a + TAU / 16.0
	var cross_section: Vector2 = Vector2(cos(a), sin(a)).lerp(Vector2(cos(b), sin(b)), segment - floorf(segment))
	cross_section *= radius * ring.y + 0.018
	return Vector3(cross_section.x, cross_section.y, ring.x * length)


func _wordmark_mesh(length: float, radius: float, side: float) -> ArrayMesh:
	var key: String = "wordmark:%s:%s:%s" % [length, radius, side]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	# Subdivide the decal-like quad at shell facets to keep a small, even offset.
	var bottom: float = 0.40
	var top: float = 0.96
	var rows: Array[float] = [bottom, sin(PI / 4.0), sin(3.0 * PI / 8.0), top]
	var front: float = -length * 0.29
	var aft: float = length * 0.075
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in rows.size() - 1:
		var low: float = rows[row]
		var high: float = rows[row + 1]
		var low_x: float = _fuselage_side_x(low, radius) + 0.035
		var high_x: float = _fuselage_side_x(high, radius) + 0.035
		var points: PackedVector3Array = PackedVector3Array([
			Vector3(side * low_x, radius * low, front), Vector3(side * high_x, radius * high, front),
			Vector3(side * high_x, radius * high, aft), Vector3(side * low_x, radius * low, aft)
		])
		_add_artwork_face(surface, points, side, (top - high) / (top - bottom), (top - low) / (top - bottom))
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


func _fuselage_side_x(height_fraction: float, radius: float) -> float:
	var segment: int = floori(asin(height_fraction) * 16.0 / TAU)
	var a: float = float(segment) * TAU / 16.0
	var b: float = a + TAU / 16.0
	var weight: float = (height_fraction - sin(a)) / (sin(b) - sin(a))
	return radius * lerpf(cos(a), cos(b), weight)


func _fin_artwork_mesh(wide: bool) -> ArrayMesh:
	var key: String = "fin_artwork:%s" % wide
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var aft: float = 27.0 if wide else 16.0
	var height: float = 10.0 if wide else 6.5
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		var points: PackedVector3Array = PackedVector3Array([
			Vector3(side * 0.178, 0.4, aft - 7.0), Vector3(side * 0.178, height, aft - 2.4),
			Vector3(side * 0.178, height, aft + 0.5), Vector3(side * 0.178, 0.4, aft + 2.0)
		])
		_add_artwork_face(surface, points, side)
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


func _add_artwork_face(surface: SurfaceTool, points: PackedVector3Array, side: float, uv_top: float = 0.0, uv_bottom: float = 1.0) -> void:
	# Opposite winding AND opposite U direction keep each exterior face readable.
	var indices: PackedInt32Array = PackedInt32Array([0, 2, 1, 0, 3, 2]) if side > 0.0 else PackedInt32Array([0, 1, 2, 0, 2, 3])
	var uvs: PackedVector2Array = PackedVector2Array([Vector2(0, uv_bottom), Vector2(0, uv_top), Vector2(1, uv_top), Vector2(1, uv_bottom)])
	for corner: int in indices:
		var uv: Vector2 = uvs[corner]
		if side > 0.0:
			uv.x = 1.0 - uv.x
		surface.set_uv(uv)
		surface.set_normal(Vector3(side, 0.0, 0.0))
		surface.add_vertex(points[corner])


func _build_aircraft(parent: Node3D, livery: int, wide: bool) -> void:
	var length: float = 60.0 if wide else 36.0
	var radius: float = 3.0 if wide else 2.05
	var body_y: float = 4.2 if wide else 3.15
	var accent_colors: Array[Color] = [Color(0.75, 0.12, 0.18), Color(0.08, 0.42, 0.66), Color(0.78, 0.48, 0.08), Color(0.16, 0.55, 0.48)]
	var fallback: int = posmod(livery, accent_colors.size())
	var spec: Dictionary = {} if _liveries.is_empty() else _liveries[posmod(livery, _liveries.size())]
	var key: String = "livery:" + str(spec.get("path", "fallback_%d" % fallback))
	var accent: StandardMaterial3D = _mat(key + ":accent", spec.get("accent", spec.get("body", accent_colors[fallback])), 0.4)
	var white: StandardMaterial3D = _mat(key + ":body", spec.get("body", Color(0.91, 0.94, 0.93)), 0.35)
	white.metallic = 0.15
	var engine: StandardMaterial3D = _mat(key + ":engine", spec.get("engine", Color(0.69, 0.73, 0.76)), 0.4)
	var windows: StandardMaterial3D = _mat("windows", Color(0.15, 0.29, 0.37), 0.2, true)
	if not spec.is_empty():
		windows = _mat(key + ":windows", spec.get("window_color", Color(0.15, 0.29, 0.37)), 0.2, true)
	parent.set_meta("airline", spec.get("name", "Fallback %d" % fallback))
	_aircraft_part(parent, "Fuselage", _fuselage_mesh(length, radius), white, body_y, true)
	if spec.is_empty():
		_box(parent, Vector3(0.0, body_y - radius * 0.64, 1.0), Vector3(radius * 1.48, 0.12, length * 0.72), accent)
	else:
		var belly: StandardMaterial3D = _mat(key + ":belly", spec["belly"], 0.35)
		_aircraft_part(parent, "Belly", _fuselage_band_mesh(length, radius, -1), belly, body_y)
		var stripes: Array = spec["cheatline"]
		for stripe: int in mini(stripes.size(), 3):
			var material: StandardMaterial3D = _mat(key + ":stripe%d" % stripe, stripes[stripe], 0.4)
			_aircraft_part(parent, "Cheatline%d" % stripe, _fuselage_band_mesh(length, radius, stripe), material, body_y)
	for side: float in [-1.0, 1.0]:
		var cockpit := _box(parent, Vector3(side * radius * 0.47, body_y + radius * 0.35, -length * 0.42), Vector3(radius * 0.77, 0.42, 1.9), _mat("cockpit", Color(0.08, 0.18, 0.27), 0.15))
		cockpit.rotation_degrees.y = -side * 17.0
		var wing := MeshInstance3D.new()
		wing.mesh = _wing_mesh(wide, side, false)
		wing.material_override = white
		wing.position.y = body_y - radius * 0.45
		wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		parent.add_child(wing)
		var stabilizer := MeshInstance3D.new()
		stabilizer.mesh = _wing_mesh(wide, side, true)
		stabilizer.material_override = white
		stabilizer.position.y = body_y + radius * 0.25
		stabilizer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		parent.add_child(stabilizer)
		var engine_x: float = side * (8.4 if wide else 5.3)
		var engine_z: float = -4.2 if wide else -2.6
		_cylinder(parent, Vector3(engine_x, body_y - radius - 0.35, engine_z), 1.22 if wide else 0.82, 4.2 if wide else 3.1, engine, Vector3(90.0, 0.0, 0.0))
		_cylinder(parent, Vector3(engine_x, body_y - radius - 0.35, engine_z - (2.12 if wide else 1.57)), 1.02 if wide else 0.68, 0.06, _mat("intake", Color(0.055, 0.075, 0.095), 0.45), Vector3(90.0, 0.0, 0.0))
		_build_gear(parent, side * (5.0 if wide else 3.5), 5.5 if wide else 3.0, body_y - radius)
		_box(parent, Vector3(side * (radius + 0.04), body_y + 0.75, -length * 0.5 + 5.2), Vector3(0.09, 1.5, 1.0), _mat("door", Color(0.73, 0.78, 0.77), 0.4))
		_box(parent, Vector3(side * (radius + 0.06), body_y + 1.55, -length * 0.5 + 5.2), Vector3(0.1, 0.15, 1.1), accent)
		_add_windows(parent, side, length, radius, body_y, windows)
		if not spec.is_empty():
			var title: StandardMaterial3D = _livery_texture_material(key + ":title", spec["title_texture"] as Texture2D)
			_aircraft_part(parent, "WordmarkPort" if side < 0.0 else "WordmarkStarboard", _wordmark_mesh(length, radius, side), title, body_y)
		var tip := _box(parent, Vector3(side * (19.0 if wide else 12.8), body_y + 0.9, 4.3 if wide else 2.4), Vector3(0.12, 2.1, 0.45), accent)
		tip.rotation_degrees.z = side * 12.0
	var fin := MeshInstance3D.new()
	fin.mesh = _fin_mesh(wide)
	fin.material_override = accent
	fin.position.y = body_y
	fin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(fin)
	if not spec.is_empty():
		var tail: StandardMaterial3D = _livery_texture_material(key + ":tail", spec["tail_texture"] as Texture2D)
		_aircraft_part(parent, "TailArtwork", _fin_artwork_mesh(wide), tail, body_y)
	_build_gear(parent, 0.0, -length * 0.39, body_y - radius)
	var beacon := _box(parent, Vector3(0.0, body_y + radius + 0.12, 0.0), Vector3(0.48, 0.22, 0.48), _mat("beacon", Color(1.0, 0.1, 0.08), 0.3, true), false)
	_beacons.append(beacon)
	var strobe := _box(parent, Vector3(0.0, body_y + 0.2, length * 0.5 - 0.9), Vector3(0.38, 0.2, 0.4), _mat("strobe", Color(0.95, 0.98, 1.0), 0.3, true), false)
	_beacons.append(strobe)


func _build_gear(parent: Node3D, x: float, z: float, belly_y: float) -> void:
	_box(parent, Vector3(x, maxf(0.6, belly_y * 0.5), z), Vector3(0.18, maxf(1.0, belly_y - 0.65), 0.18), _mat("gear", Color(0.28, 0.31, 0.33), 0.35))
	for side in [-1.0, 1.0]:
		_cylinder(parent, Vector3(x + side * 0.32, 0.44, z), 0.42, 0.22, _mat("tire", Color(0.055, 0.065, 0.07), 0.9), Vector3(0.0, 0.0, 90.0))


func _add_windows(parent: Node3D, side: float, length: float, radius: float, body_y: float, material: StandardMaterial3D) -> void:
	var count := 25 if length > 40.0 else 15
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = _box_mesh(Vector3(0.065, 0.38, 0.48))
	multi.instance_count = count
	for i in count:
		var z := -length * 0.5 + 6.8 + float(i) * (1.75 if length > 40.0 else 1.58)
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(side * (radius + 0.025), body_y + 0.72, z)))
	var windows := MultiMeshInstance3D.new()
	windows.multimesh = multi
	windows.material_override = material
	windows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(windows)


func _build_jet_bridge(tile: Node3D, side: float, z: float, wide: bool) -> void:
	var end_x := 45.0 if wide else 48.0
	var bridge_z := z + side * (3.0 if wide else 2.0)
	var length := end_x - 30.0
	var frame := _mat("bridge_frame", Color(0.78, 0.82, 0.81), 0.48)
	var glass := _mat("bridge_glass", Color(0.36, 0.59, 0.67, 0.28), 0.13)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_box(tile, Vector3(side * (30.0 + length * 0.5), 3.55, bridge_z), Vector3(length, 0.18, 3.1), frame)
	_box(tile, Vector3(side * (30.0 + length * 0.5), 6.2, bridge_z), Vector3(length, 0.18, 3.1), frame)
	for offset in [-1.5, 1.5]:
		_box(tile, Vector3(side * (30.0 + length * 0.5), 4.9, bridge_z + offset), Vector3(length - 0.4, 2.35, 0.08), glass, false)
		for step in 4:
			_box(tile, Vector3(side * (32.0 + float(step) * (length - 3.0) / 3.0), 4.9, bridge_z + offset), Vector3(0.12, 2.5, 0.14), frame)
	_box(tile, Vector3(side * (end_x - 1.1), 1.8, bridge_z), Vector3(0.28, 3.6, 0.28), frame)
	for offset in [-1.0, 1.0]:
		_cylinder(tile, Vector3(side * (end_x - 1.1), 0.35, bridge_z + offset), 0.4, 0.18, _mat("tire", Color(0.055, 0.065, 0.07)), Vector3(90.0, 0.0, 0.0))


func _build_services(tile: Node3D, side: float, z: float, index: int) -> void:
	var service_x := 82.0 if index % 5 == 4 else 76.0
	var tug := Node3D.new()
	tug.position = Vector3(side * service_x, 0.0, z - 10.0)
	tile.add_child(tug)
	_build_tug(tug, Vector3.ZERO, index % 4)
	for cart_index in 3 + index % 2:
		var cart_z := z - 6.5 + float(cart_index) * 3.1
		_box(tile, Vector3(side * service_x, 0.7, cart_z), Vector3(1.8, 0.55, 2.2), _mat("cart", Color(0.44, 0.51, 0.54)))
		for wheel_z in [-0.7, 0.7]:
			_cylinder(tile, Vector3(side * service_x, 0.28, cart_z + wheel_z), 0.26, 2.0, _mat("tire", Color(0.055, 0.065, 0.07)), Vector3(0.0, 0.0, 90.0))
		for bag_index in 2:
			_box(tile, Vector3(side * service_x, 1.16, cart_z + float(bag_index) * 0.8 - 0.4), Vector3(1.1, 0.43, 0.7), _mat("baggage_%d" % ((index + bag_index) % 3), [Color(0.74, 0.19, 0.14), Color(0.16, 0.39, 0.69), Color(0.76, 0.59, 0.23)][(index + bag_index) % 3]))
	_build_belt_loader(tile, side, z + 7.0)
	_build_fuel_truck(tile, side, z + 12.0)
	if index % 3 == 0:
		_build_catering_truck(tile, side, z - 12.0)
	var cone_points: Array[Vector3] = []
	for i in 7:
		cone_points.append(Vector3(side * (50.0 + float(i % 3) * 9.0), -0.2, z + 10.0 + float(i / 3.0) * 5.0))
	_multi_boxes(tile, cone_points, Vector3(0.42, 0.7, 0.42), _mat("cone", Color(0.94, 0.35, 0.07)))


func _build_tug(parent: Node3D, at: Vector3, livery: int) -> void:
	_box(parent, at + Vector3(0.0, 0.7, 0.0), Vector3(1.8, 1.0, 3.0), _mat("tug_%d" % livery, [Color(0.93, 0.7, 0.14), Color(0.91, 0.88, 0.78), Color(0.3, 0.63, 0.65), Color(0.85, 0.39, 0.2)][livery]))
	_box(parent, at + Vector3(0.0, 1.4, -0.85), Vector3(1.55, 0.72, 1.15), _mat("cab", Color(0.2, 0.36, 0.43), 0.2))
	for z in [-0.9, 0.9]:
		_cylinder(parent, at + Vector3(0.0, 0.3, z), 0.33, 2.05, _mat("tire", Color(0.055, 0.065, 0.07)), Vector3(0.0, 0.0, 90.0))


func _build_belt_loader(tile: Node3D, side: float, z: float) -> void:
	var x := side * 57.0
	_box(tile, Vector3(x, 0.75, z), Vector3(1.5, 0.8, 3.4), _mat("belt_yellow", Color(0.91, 0.69, 0.15)))
	var belt := _box(tile, Vector3(x, 2.0, z - 1.3), Vector3(1.3, 0.22, 5.0), _mat("belt", Color(0.17, 0.19, 0.2)))
	belt.rotation_degrees.x = -22.0
	for wheel_z in [-1.0, 1.0]:
		_cylinder(tile, Vector3(x, 0.3, z + wheel_z), 0.32, 1.7, _mat("tire", Color(0.055, 0.065, 0.07)), Vector3(0.0, 0.0, 90.0))


func _build_fuel_truck(tile: Node3D, side: float, z: float) -> void:
	var x := side * 80.0
	_box(tile, Vector3(x, 1.1, z), Vector3(2.4, 1.6, 5.7), _mat("fuel_white", Color(0.85, 0.88, 0.86)))
	_box(tile, Vector3(x, 1.2, z - 2.2), Vector3(2.5, 1.9, 1.7), _mat("fuel_cab", Color(0.75, 0.8, 0.79)))
	_box(tile, Vector3(x, 1.8, z - 3.08), Vector3(1.9, 0.55, 0.08), _mat("cab", Color(0.2, 0.36, 0.43)))
	for wheel_z in [-2.1, 1.5]:
		_cylinder(tile, Vector3(x, 0.38, z + wheel_z), 0.39, 2.6, _mat("tire", Color(0.055, 0.065, 0.07)), Vector3(0.0, 0.0, 90.0))


func _build_catering_truck(tile: Node3D, side: float, z: float) -> void:
	var x := side * 55.0
	_box(tile, Vector3(x, 1.55, z), Vector3(2.3, 2.7, 4.4), _mat("catering", Color(0.86, 0.88, 0.84)))
	_box(tile, Vector3(x, 1.0, z - 2.5), Vector3(2.2, 1.55, 1.5), _mat("fuel_cab", Color(0.75, 0.8, 0.79)))
	for wheel_z in [-2.0, 1.4]:
		_cylinder(tile, Vector3(x, 0.35, z + wheel_z), 0.38, 2.5, _mat("tire", Color(0.055, 0.065, 0.07)), Vector3(0.0, 0.0, 90.0))


func _build_floodlight(tile: Node3D, side: float, z: float) -> void:
	var x := side * 91.0
	_cylinder(tile, Vector3(x, 12.0, z), 0.2, 24.0, _mat("mast", Color(0.43, 0.48, 0.49), 0.55))
	_box(tile, Vector3(x, 24.2, z), Vector3(0.5, 0.4, 5.0), _mat("mast", Color(0.43, 0.48, 0.49)))
	for dz in [-1.7, -0.55, 0.55, 1.7]:
		_box(tile, Vector3(x - side * 0.3, 23.9, z + dz), Vector3(0.5, 0.42, 0.7), _mat("apron_lamp", Color(1.0, 0.91, 0.68), 0.2, true), false)
	if _lamps.size() < 8:
		var lamp := SpotLight3D.new()
		lamp.position = Vector3(x - side * 0.6, 23.5, z)
		lamp.rotation_degrees.x = -90.0
		lamp.spot_range = 52.0
		lamp.spot_angle = 55.0
		lamp.light_color = Color(1.0, 0.9, 0.72)
		lamp.shadow_enabled = false
		lamp.visible = false
		tile.add_child(lamp)
		_lamps.append(lamp)


func _build_hangar(tile: Node3D, side: float, z: float, index: int) -> void:
	var x := side * 220.0
	var shell := _mat("hangar", Color(0.43, 0.51, 0.55), 0.8)
	_box(tile, Vector3(x, 8.0, z), Vector3(33.0, 16.0, 31.0), shell)
	_box(tile, Vector3(x - side * 0.2, 16.4, z), Vector3(35.0, 1.0, 33.0), _mat("hangar_roof", Color(0.32, 0.39, 0.43)))
	_box(tile, Vector3(x - side * 16.6, 7.1, z), Vector3(0.15, 12.8, 24.0), _mat("hangar_door", Color(0.25, 0.32, 0.36)))
	for i in 5:
		_box(tile, Vector3(x - side * 16.75, 7.0, z - 11.0 + float(i) * 5.5), Vector3(0.12, 13.0, 0.15), shell)
	_box(tile, Vector3(x - side * 16.8, 14.2, z), Vector3(0.1, 1.1, 22.0), _mat("hangar_sign_%d" % (index % 2), Color(0.72, 0.78, 0.77)))


func _build_tower(tile: Node3D, side: float, z: float) -> void:
	var x := side * 229.0
	_cylinder(tile, Vector3(x, 19.0, z), 3.2, 38.0, _mat("tower", Color(0.67, 0.72, 0.71), 0.7))
	var cab_glass := _mat("tower_glass", Color(0.18, 0.34, 0.43, 0.6), 0.18)
	cab_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cylinder(tile, Vector3(x, 39.0, z), 7.3, 3.0, cab_glass)
	_cylinder(tile, Vector3(x, 41.0, z), 7.8, 0.7, _mat("tower", Color(0.67, 0.72, 0.71)))
	_box(tile, Vector3(x, 43.5, z), Vector3(0.15, 4.3, 0.15), _mat("mast", Color(0.43, 0.48, 0.49)))


func _build_skyline(tile: Node3D, side: float, index: int) -> void:
	var skyline := _mat("skyline", Color(0.23, 0.31, 0.39), 1.0)
	for i in 3:
		var x := side * (265.0 + float(i) * 18.0)
		var height := 12.0 + float((index * 7 + i * 11) % 19)
		var z := -5.0 - float(i) * 11.0
		_box(tile, Vector3(x, height * 0.5 - 0.6, z), Vector3(11.0, height, 9.0), skyline)
		var spots: Array[Vector3] = []
		for row in 3:
			for column in 3:
				spots.append(Vector3(x - side * 5.55, 4.0 + float(row) * 3.2, z - 2.5 + float(column) * 2.5))
		_multi_boxes(tile, spots, Vector3(0.08, 0.75, 0.8), _mat("city_window", Color(0.95, 0.76, 0.44), 0.3, true))


func _multi_lights(tile: Node3D, side: float, rows: Array[float], key: String, color: Color, spacing: int) -> void:
	var points: Array[Vector3] = []
	for x in rows:
		for i in spacing:
			points.append(Vector3(side * x, -0.48, -2.0 - float(i) * (32.0 / float(spacing - 1))))
	_multi_boxes(tile, points, Vector3(0.24, 0.13, 0.24), _mat(key, color, 0.2, true))


func _multi_boxes(parent: Node3D, points: Array[Vector3], size: Vector3, material: Material) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = _box_mesh(size)
	multi.instance_count = points.size()
	for i in points.size():
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, points[i]))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multi
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _fuselage_mesh(length: float, radius: float) -> ArrayMesh:
	var key := "fuselage:%s:%s" % [length, radius]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var rings: PackedVector2Array = _fuselage_rings
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in rings.size() - 1:
		for segment in 16:
			var a := TAU * float(segment) / 16.0
			var b := TAU * float(segment + 1) / 16.0
			var p0 := Vector3(cos(a) * radius * rings[ring].y, sin(a) * radius * rings[ring].y, rings[ring].x * length)
			var p1 := Vector3(cos(b) * radius * rings[ring].y, sin(b) * radius * rings[ring].y, rings[ring].x * length)
			var p2 := Vector3(cos(a) * radius * rings[ring + 1].y, sin(a) * radius * rings[ring + 1].y, rings[ring + 1].x * length)
			var p3 := Vector3(cos(b) * radius * rings[ring + 1].y, sin(b) * radius * rings[ring + 1].y, rings[ring + 1].x * length)
			surface.add_vertex(p0)
			surface.add_vertex(p2)
			surface.add_vertex(p1)
			surface.add_vertex(p1)
			surface.add_vertex(p2)
			surface.add_vertex(p3)
	surface.generate_normals()
	var mesh := surface.commit()
	_meshes[key] = mesh
	return mesh


func _wing_mesh(wide: bool, side: float, tail: bool) -> ArrayMesh:
	var key := "wing:%s:%s:%s" % [wide, side, tail]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var span := (10.0 if wide else 6.5) if tail else (26.0 if wide else 17.0)
	var root_z := (24.0 if wide else 14.0) if tail else (-4.0 if wide else -2.0)
	var chord := (6.0 if wide else 4.0) if tail else (11.0 if wide else 7.0)
	var tip_z := root_z + (5.5 if tail else 7.0) * (1.4 if wide else 1.0)
	var inner := 0.7 if tail else 1.5
	var points := PackedVector3Array([
		Vector3(side * inner, 0.0, root_z - chord * 0.5),
		Vector3(side * span, 0.9 if tail else 1.15, tip_z - chord * 0.14),
		Vector3(side * span, 0.9 if tail else 1.15, tip_z + chord * 0.18),
		Vector3(side * inner, 0.0, root_z + chord * 0.5)
	])
	var mesh := _quad_shell(points, 0.15)
	_meshes[key] = mesh
	return mesh


func _fin_mesh(wide: bool) -> ArrayMesh:
	var key := "fin:%s" % wide
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var aft := 27.0 if wide else 16.0
	var height := 10.0 if wide else 6.5
	var points := PackedVector3Array([
		Vector3(0.0, 0.4, aft - 7.0), Vector3(0.0, height, aft - 2.4),
		Vector3(0.0, height, aft + 0.5), Vector3(0.0, 0.4, aft + 2.0)
	])
	var mesh := _quad_shell(points, 0.16)
	_meshes[key] = mesh
	return mesh


func _quad_shell(points: PackedVector3Array, thickness: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var offset := Vector3(0.0, thickness, 0.0) if absf(points[0].x - points[1].x) > 0.1 else Vector3(thickness, 0.0, 0.0)
	for face in 2:
		var shift := offset if face == 0 else -offset
		var indices: PackedInt32Array = PackedInt32Array([0, 1, 2, 0, 2, 3])
		if offset.x > 0.0:
			indices = PackedInt32Array([0, 2, 1, 0, 3, 2]) if face == 0 else indices
		var uvs: PackedVector2Array = PackedVector2Array([Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)])
		for corner: int in indices:
			var uv: Vector2 = uvs[corner]
			if offset.x > 0.0 and face == 0:
				uv.x = 1.0 - uv.x
			surface.set_uv(uv)
			surface.add_vertex(points[corner] + shift)
	for i in 4:
		var next := (i + 1) % 4
		for point in [points[i] + offset, points[next] + offset, points[i] - offset, points[next] + offset, points[next] - offset, points[i] - offset]:
			surface.add_vertex(point)
	surface.generate_normals()
	return surface.commit()


func _make_apron_texture() -> ImageTexture:
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in 256:
		for x in 256:
			var grain := float((x * 37 + y * 71 + x * y * 3) % 31) / 310.0
			var c := Color(0.7 - grain, 0.71 - grain, 0.69 - grain)
			if x % 64 < 2 or y % 64 < 2:
				c = Color(0.39, 0.42, 0.42)
			image.set_pixel(x, y, c)
	return ImageTexture.create_from_image(image)


func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material, shadows: bool = true) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = _box_mesh(size)
	instance.material_override = material
	instance.position = at
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


func _box_mesh(size: Vector3) -> BoxMesh:
	var key := "box:" + str(size)
	if not _meshes.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		_meshes[key] = mesh
	return _meshes[key] as BoxMesh


func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, material: Material, angles: Vector3 = Vector3.ZERO) -> void:
	var key := "cylinder:%s:%s" % [radius, height]
	if not _meshes.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = 12
		_meshes[key] = mesh
	var instance := MeshInstance3D.new()
	instance.mesh = _meshes[key] as Mesh
	instance.material_override = material
	instance.position = at
	instance.rotation_degrees = angles
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if (material as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)


func _mat(key: String, color: Color, roughness: float = 0.72, emissive: bool = false) -> StandardMaterial3D:
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = roughness
		if emissive:
			material.emission_enabled = true
			material.emission = color
			material.emission_energy_multiplier = 0.55
		_materials[key] = material
	return _materials[key] as StandardMaterial3D
