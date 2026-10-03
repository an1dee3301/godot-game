class_name WorldMap
extends RefCounted
## Natural Earth land geometry supplied as a 1024x512 equirectangular mask.

const ROUTES := [["LAX", "JFK"], ["LAX", "NRT"], ["JFK", "LHR"], ["LHR", "CDG"], ["CDG", "DXB"], ["DXB", "SGN"], ["SGN", "NRT"], ["SGN", "SYD"]]
const GLYPHS := {
	"A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"],
	"C": ["011", "100", "100", "100", "011"], "D": ["110", "101", "101", "101", "110"],
	"G": ["011", "100", "101", "101", "011"], "F": ["111", "100", "110", "100", "100"],
	"H": ["101", "101", "111", "101", "101"], "J": ["001", "001", "001", "101", "010"],
	"K": ["101", "101", "110", "101", "101"], "L": ["100", "100", "100", "100", "111"],
	"N": ["101", "111", "111", "111", "101"], "P": ["110", "101", "110", "100", "100"],
	"R": ["110", "101", "110", "101", "101"], "S": ["011", "100", "010", "001", "110"],
	"T": ["111", "010", "010", "010", "010"], "X": ["101", "101", "010", "101", "101"],
	"Y": ["101", "101", "010", "010", "010"],
}

static var _textures: Dictionary = {}


static func uv_for(lat: float, lon: float) -> Vector2:
	return Vector2((lon + 180.0) / 360.0, (90.0 - lat) / 180.0)


static func texture(width: int = 1024) -> ImageTexture:
	width = maxi(64, width)
	if _textures.has(width):
		return _textures[width] as ImageTexture
	var source_texture := load("res://assets/data/world_land_mask.png") as Texture2D
	if source_texture == null:
		push_error("Natural Earth land mask is missing")
		return null
	var mask := source_texture.get_image()
	var height := width / 2
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var ocean := Color("183d58")
	var land := Color("96c5aa")
	var grid := Color("31576b")
	for y in height:
		var sy := mini(mask.get_height() - 1, int(float(y) * mask.get_height() / height))
		for x in width:
			var sx := mini(mask.get_width() - 1, int(float(x) * mask.get_width() / width))
			var is_land := mask.get_pixel(sx, sy).r > 0.5
			var color := land if is_land else ocean
			if (x * 12) % width < 1 or (y * 6) % height < 1:
				color = color.lerp(grid, 0.23)
			image.set_pixel(x, y, color)
	for pair in ROUTES:
		_draw_route(image, str(pair[0]), str(pair[1]))
	for iata in AirportData.AIRPORTS:
		var airport: Dictionary = AirportData.get_airport(iata)
		var uv := uv_for(float(airport.lat), float(airport.lon))
		var center := Vector2i(roundi(uv.x * (width - 1)), roundi(uv.y * (height - 1)))
		_dot(image, center, 4, Color("f1bb65"))
		_draw_label(image, center + Vector2i(6, -8), iata)
	var result := ImageTexture.create_from_image(image)
	_textures[width] = result
	return result


static func _draw_route(image: Image, from: String, to: String) -> void:
	var a: Dictionary = AirportData.get_airport(from)
	var b: Dictionary = AirportData.get_airport(to)
	var va := _sphere(float(a.lat), float(a.lon))
	var vb := _sphere(float(b.lat), float(b.lon))
	var angle := acos(clampf(va.dot(vb), -1.0, 1.0))
	var denominator := sin(angle)
	if absf(denominator) < 0.00001:
		return
	var previous := Vector2.ZERO
	for step in 129:
		var t := float(step) / 128.0
		var point := (va * (sin((1.0 - t) * angle) / denominator) + vb * (sin(t * angle) / denominator)).normalized()
		var uv := uv_for(rad_to_deg(asin(point.y)), rad_to_deg(atan2(point.z, point.x)))
		var pixel := Vector2(uv.x * (image.get_width() - 1), uv.y * (image.get_height() - 1))
		if step > 0 and absf(pixel.x - previous.x) < image.get_width() * 0.5:
			_line(image, previous, pixel, Color("e7d69a"))
		previous = pixel


static func _sphere(lat: float, lon: float) -> Vector3:
	var latitude := deg_to_rad(lat)
	var longitude := deg_to_rad(lon)
	return Vector3(cos(latitude) * cos(longitude), sin(latitude), cos(latitude) * sin(longitude))


static func _line(image: Image, a: Vector2, b: Vector2, color: Color) -> void:
	var count := maxi(1, ceili(a.distance_to(b)))
	for i in count + 1:
		var p := a.lerp(b, float(i) / count)
		var x := roundi(p.x)
		var y := roundi(p.y)
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)


static func _dot(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var px := center.x + x
			var py := center.y + y
			if x * x + y * y <= radius * radius and px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
				image.set_pixel(px, py, color)


static func _draw_label(image: Image, origin: Vector2i, caption: String) -> void:
	for letter_index in caption.length():
		var letter := caption.substr(letter_index, 1)
		var rows: Array = GLYPHS.get(letter, [])
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if row.substr(x, 1) == "1":
					var px := origin.x + letter_index * 4 + x
					var py := origin.y + y
					if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
						image.set_pixel(px, py, Color("fff3d0"))
