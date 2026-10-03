extends RefCounted
## A framed, atlas-like route map. The printed geography and flight paths share one texture.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}
static var _textures: Dictionary = {}

const PRINT_SIZE := Vector2(11.36, 3.48)
const PRINT_CENTRE_Y := 2.18
const INK := Color(0.17, 0.22, 0.21)
const LAND := Color(0.70, 0.74, 0.66)
const SEA := Color(0.92, 0.91, 0.84)
const ROUTE := Color(0.67, 0.38, 0.27)
const HUB := Vector2(0.63, 0.68)


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "InternationalRouteMapWall"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "route_map_oak")
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "route_map_walnut")
	var stone: StandardMaterial3D = DesignKit.stone(DesignKit.LIMESTONE, 0.82, "route_map_stone")
	var brass: StandardMaterial3D = DesignKit.brass()
	DesignKit.rbox(root, Vector3(12.0, 5.0, 0.14), Vector3(0.0, 2.5, -0.04), stone, 0.045)
	DesignKit.rbox(root, Vector3(11.66, 3.70, 0.035), Vector3(0.0, 2.18, 0.053), walnut, 0.018, false)
	DesignKit.rbox(root, Vector3(11.48, 3.58, 0.025), Vector3(0.0, 2.18, 0.075), DesignKit.fabric(DesignKit.LINEN, "route_map_linen"), 0.012, false)
	DesignKit.add(root, _print_mesh(), _print_material(variant), Vector3(0.0, PRINT_CENTRE_Y, 0.093), Vector3.ZERO, false)
	# The frame is built as four eased timber rails with a narrow brass sight line.
	for y: float in [0.065, 4.935]:
		DesignKit.rbox(root, Vector3(12.0, 0.13, 0.19), Vector3(0.0, y, 0.07), oak, 0.045)
	for x: float in [-5.935, 5.935]:
		DesignKit.rbox(root, Vector3(0.13, 4.74, 0.19), Vector3(x, 2.5, 0.07), oak, 0.045)
	DesignKit.rbox(root, Vector3(11.54, 0.018, 0.014), Vector3(0.0, 4.071, 0.105), brass, 0.006, false)
	DesignKit.rbox(root, Vector3(11.54, 0.018, 0.014), Vector3(0.0, 0.290, 0.105), brass, 0.006, false)

	_add_label(root, "WORLD ROUTES", Vector2(0.0, 4.65), 145, 0.0035, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(root, "世界の路線  ·  国际航线  ·  Tuyến bay  ·  Lignes  ·  Rutas", Vector2(0.0, 4.24), 66, 0.0033, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(root, "SINGAPORE  /  新加坡", Vector2(0.0, 0.185), 76, 0.0034, INK, HORIZONTAL_ALIGNMENT_CENTER)

	# All seven dots are in the print; these raised names stay sharp at a distance.
	_city(root, "PARIS", Vector2(0.20, 0.26), 96)
	_city(root, "BARCELONA", Vector2(0.155, 0.55), 84)
	_city(root, "SHANGHAI", Vector2(0.705, 0.48), 84)
	_city(root, "TOKYO", Vector2(0.855, 0.21), 96)
	_city(root, "HANOI", Vector2(0.565, 0.53), 96)
	_city(root, "SYDNEY", Vector2(0.845, 0.88), 96)
	_city(root, "SIN", Vector2(0.575, 0.76), 104)

	var pin_mesh: Mesh = _pin_mesh()
	for x: float in [-5.87, 5.87]:
		for y: float in [0.115, 4.885]:
			DesignKit.add(root, pin_mesh, brass, Vector3(x, y, 0.175), Vector3(90.0, 0.0, 0.0), false)
	return root


static func _city(root: Node3D, name: String, uv: Vector2, font_size: int) -> void:
	var p := Vector2((uv.x - 0.5) * PRINT_SIZE.x, PRINT_CENTRE_Y + (0.5 - uv.y) * PRINT_SIZE.y)
	_add_label(root, name, p, font_size, 0.0035, INK, HORIZONTAL_ALIGNMENT_CENTER)


static func _add_label(root: Node3D, caption: String, xy: Vector2, font_size: int, pixel_size: float, tint: Color, alignment: HorizontalAlignment) -> void:
	var label := Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.horizontal_alignment = alignment
	label.modulate = tint
	label.outline_size = 0
	label.double_sided = false
	label.position = Vector3(xy.x, xy.y, 0.115)
	label.visibility_range_end = 80.0
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(label)


static func _print_mesh() -> QuadMesh:
	if not _meshes.has("print"):
		var mesh := QuadMesh.new()
		mesh.size = PRINT_SIZE
		_meshes["print"] = mesh
	return _meshes["print"] as QuadMesh


static func _pin_mesh() -> Mesh:
	if not _meshes.has("pin"):
		_meshes["pin"] = DesignKit.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.025, 0.0), Vector2(0.024, 0.008),
			Vector2(0.014, 0.012), Vector2(0.0, 0.012)
		]), 12)
	return _meshes["pin"] as Mesh


static func _print_material(variant: int) -> StandardMaterial3D:
	var key := str(posmod(variant, 3))
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_texture = _map_texture(variant)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.roughness = 1.0
	_materials[key] = material
	return material


static func _map_texture(variant: int) -> Texture2D:
	var key := str(posmod(variant, 3))
	if _textures.has(key):
		return _textures[key] as Texture2D
	var image := Image.create(1536, 472, false, Image.FORMAT_RGB8)
	image.fill(SEA)
	# The continent outlines are intentionally simplified like a printed travel atlas.
	var shapes: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(0.015, 0.17), Vector2(0.09, 0.14), Vector2(0.15, 0.18), Vector2(0.18, 0.28), Vector2(0.26, 0.26), Vector2(0.30, 0.36), Vector2(0.27, 0.47), Vector2(0.20, 0.44), Vector2(0.16, 0.50), Vector2(0.09, 0.47), Vector2(0.03, 0.55)]),
		PackedVector2Array([Vector2(0.31, 0.11), Vector2(0.48, 0.08), Vector2(0.56, 0.14), Vector2(0.64, 0.14), Vector2(0.70, 0.20), Vector2(0.79, 0.18), Vector2(0.85, 0.28), Vector2(0.81, 0.38), Vector2(0.74, 0.43), Vector2(0.70, 0.51), Vector2(0.65, 0.48), Vector2(0.60, 0.55), Vector2(0.56, 0.50), Vector2(0.50, 0.52), Vector2(0.47, 0.43), Vector2(0.40, 0.40), Vector2(0.36, 0.31)]),
		PackedVector2Array([Vector2(0.44, 0.43), Vector2(0.53, 0.48), Vector2(0.58, 0.61), Vector2(0.55, 0.78), Vector2(0.50, 0.88), Vector2(0.44, 0.78), Vector2(0.40, 0.60)]),
		PackedVector2Array([Vector2(0.76, 0.74), Vector2(0.85, 0.70), Vector2(0.92, 0.77), Vector2(0.94, 0.88), Vector2(0.87, 0.93), Vector2(0.79, 0.87)]),
		PackedVector2Array([Vector2(0.91, 0.52), Vector2(0.95, 0.50), Vector2(0.97, 0.62), Vector2(0.94, 0.70), Vector2(0.90, 0.65)])
	]
	for shape: PackedVector2Array in shapes:
		_fill_polygon(image, shape, LAND)
	# Islands make the Asia-Pacific end of the map recognisable without clutter.
	for island: Vector2 in [Vector2(0.77, 0.31), Vector2(0.79, 0.37), Vector2(0.81, 0.44), Vector2(0.67, 0.65), Vector2(0.71, 0.68), Vector2(0.75, 0.71), Vector2(0.62, 0.72)]:
		_disc(image, island, 0.007, LAND)
	var destinations: Array[Vector2] = [
		Vector2(0.20, 0.35), Vector2(0.16, 0.47), Vector2(0.72, 0.39),
		Vector2(0.83, 0.30), Vector2(0.65, 0.56), Vector2(0.85, 0.80)
	]
	var bends: Array[float] = [0.18, 0.12, -0.11, -0.17, -0.07, 0.09]
	for i: int in destinations.size():
		_arc(image, HUB, destinations[i], bends[i], ROUTE)
		_disc(image, destinations[i], 0.014, INK)
		_disc(image, destinations[i], 0.006, SEA)
	_disc(image, HUB, 0.026, ROUTE)
	_disc(image, HUB, 0.010, SEA)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_textures[key] = texture
	return texture


static func _fill_polygon(image: Image, normalized: PackedVector2Array, color: Color) -> void:
	var polygon := PackedVector2Array()
	var lo := Vector2i(image.get_width() - 1, image.get_height() - 1)
	var hi := Vector2i.ZERO
	for point: Vector2 in normalized:
		var pixel := Vector2(point.x * image.get_width(), point.y * image.get_height())
		polygon.append(pixel)
		lo.x = mini(lo.x, int(pixel.x))
		lo.y = mini(lo.y, int(pixel.y))
		hi.x = maxi(hi.x, int(pixel.x))
		hi.y = maxi(hi.y, int(pixel.y))
	for y: int in range(maxi(lo.y, 0), mini(hi.y + 1, image.get_height())):
		for x: int in range(maxi(lo.x, 0), mini(hi.x + 1, image.get_width())):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon):
				image.set_pixel(x, y, color)


static func _arc(image: Image, start: Vector2, end: Vector2, bend: float, color: Color) -> void:
	var midpoint := (start + end) * 0.5
	var normal := (end - start).orthogonal().normalized()
	var control := midpoint + normal * bend
	for step: int in 161:
		var t := float(step) / 160.0
		var point := start * (1.0 - t) * (1.0 - t) + control * (2.0 * t * (1.0 - t)) + end * t * t
		_disc(image, point, 0.0044, color)


static func _disc(image: Image, uv: Vector2, radius: float, color: Color) -> void:
	var cx := uv.x * image.get_width()
	var cy := uv.y * image.get_height()
	var rx := radius * image.get_width()
	var ry := radius * image.get_height() * 2.8
	for y: int in range(maxi(0, int(cy - ry)), mini(image.get_height(), int(cy + ry) + 1)):
		for x: int in range(maxi(0, int(cx - rx)), mini(image.get_width(), int(cx + rx) + 1)):
			var dx := (float(x) + 0.5 - cx) / rx
			var dy := (float(y) + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				image.set_pixel(x, y, color)
