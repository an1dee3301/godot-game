extends RefCounted
## Six ceremonial komodaru, stacked on a fork-accessible oak pallet.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "SakeDisplay"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var oak: Material = Kit.wood(Kit.OAK if choice % 2 == 0 else Kit.WALNUT, "sake_pallet_%d" % (choice % 2))
	var straw: Material = Kit.fabric(Color(0.76, 0.65, 0.43).lightened(float(choice) * 0.025), "sake_straw_%d" % choice)
	var rope: Material = Kit.fabric(Color(0.62, 0.49, 0.29), "sake_binding")
	# Three runners and spaced deck boards leave authentic forklift openings.
	for x: float in [-1.0, 0.0, 1.0]:
		Kit.rbox(root, Vector3(0.14, 0.13, 1.08), Vector3(x, 0.065, 0.0), oak, 0.018)
	for i: int in 6:
		Kit.rbox(root, Vector3(2.84, 0.065, 0.155), Vector3(0.0, 0.1625, -0.4625 + float(i) * 0.185), oak, 0.012)
	# Slightly recessed shelf boards distribute the upper rows' weight onto the lids.
	for tier: int in 3:
		var count: int = 3 - tier
		var base_y: float = 0.195 + float(tier) * 0.82
		if tier > 0:
			Kit.rbox(root, Vector3(float(count) * 0.88, 0.035, 0.65), Vector3(0.0, base_y - 0.0175, -0.03), oak, 0.012)
		for column: int in count:
			var x: float = (float(column) - float(count - 1) * 0.5) * 0.9
			_barrel(root, Vector3(x, base_y, 0.0), straw, rope, oak, posmod(choice + column + tier, 4), column + tier)
	return root


static func _barrel(parent: Node3D, at: Vector3, straw: Material, rope: Material, oak: Material, ink_index: int, motif: int) -> void:
	var barrel: Node3D = Node3D.new()
	barrel.name = "Komodaru"
	barrel.position = at
	parent.add_child(barrel)
	var profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.35, 0.0), Vector2(0.385, 0.025),
		Vector2(0.405, 0.12), Vector2(0.435, 0.30), Vector2(0.44, 0.40),
		Vector2(0.435, 0.50), Vector2(0.405, 0.68), Vector2(0.385, 0.775),
		Vector2(0.35, 0.79), Vector2(0.0, 0.79)])
	Kit.add(barrel, Kit.lathe(profile, 48), straw, Vector3.ZERO)
	# Inset wooden lid, retained under the rope cross-ties.
	Kit.add(barrel, Kit.lathe(PackedVector2Array([Vector2(0.0, 0.785), Vector2(0.34, 0.785), Vector2(0.35, 0.793), Vector2(0.34, 0.804), Vector2(0.0, 0.804)]), 40), oak, Vector3.ZERO)
	Kit.add(barrel, _binding_mesh(), rope, Vector3.ZERO)
	Kit.add(barrel, _straw_mesh(), straw, Vector3.ZERO, Vector3.ZERO, false)
	Kit.add(barrel, _apron_mesh(), _print_material(ink_index), Vector3.ZERO, Vector3.ZERO, false)
	var inks: Array[Color] = [Kit.INDIGO, Kit.CLAY, Kit.CHARCOAL, Kit.SAGE.darkened(0.25)]
	var characters: Array[String] = ["酒", "福", "寿"]
	var label: Label3D = Label3D.new()
	label.text = characters[posmod(motif, 3)]
	label.font = Signs.font()
	label.font_size = 160
	label.pixel_size = 0.0024
	label.modulate = inks[ink_index]
	label.outline_size = 0
	# Keep the large character clear of the curved printed wrapper at its crown.
	label.position = Vector3(0.0, 0.415, 0.462)
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	barrel.add_child(label)


static func _radius(y: float) -> float:
	return 0.385 + 0.055 * sin(clampf(y / 0.79, 0.0, 1.0) * PI)


static func _tube(st: SurfaceTool, path: PackedVector3Array, radius: float) -> void:
	# All straw strands and ropes share one surface per material.
	for i: int in path.size() - 1:
		var tangent: Vector3 = (path[i + 1] - path[i]).normalized()
		var side: Vector3 = tangent.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.01:
			side = Vector3.RIGHT
		var up: Vector3 = tangent.cross(side).normalized()
		for j: int in 6:
			var a: float = TAU * float(j) / 6.0
			var b: float = TAU * float(j + 1) / 6.0
			var n0: Vector3 = side * cos(a) + up * sin(a)
			var n1: Vector3 = side * cos(b) + up * sin(b)
			var vertices: Array[Vector3] = [path[i] + n0 * radius, path[i + 1] + n0 * radius, path[i] + n1 * radius, path[i] + n1 * radius, path[i + 1] + n0 * radius, path[i + 1] + n1 * radius]
			for vertex: Vector3 in vertices:
				st.add_vertex(vertex)


static func _binding_mesh() -> ArrayMesh:
	if _meshes.has("bindings"):
		return _meshes["bindings"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y: float in [0.08, 0.125, 0.665, 0.71]:
		var ring: PackedVector3Array = PackedVector3Array()
		for i: int in 65:
			var angle: float = TAU * float(i) / 64.0
			ring.append(Vector3(sin(angle) * (_radius(y) + 0.012), y, cos(angle) * (_radius(y) + 0.012)))
		_tube(st, ring, 0.022)
	for i: int in 4:
		var angle: float = PI * 0.25 + float(i) * PI * 0.5
		var strap: PackedVector3Array = PackedVector3Array()
		for j: int in 17:
			var y: float = float(j) * 0.79 / 16.0
			strap.append(Vector3(sin(angle) * (_radius(y) + 0.016), y, cos(angle) * (_radius(y) + 0.016)))
		strap.append(Vector3(sin(angle) * 0.31, 0.822, cos(angle) * 0.31))
		strap.append(Vector3.ZERO + Vector3(0.0, 0.824, 0.0))
		_tube(st, strap, 0.016)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["bindings"] = mesh
	return mesh


static func _straw_mesh() -> ArrayMesh:
	if _meshes.has("straw"):
		return _meshes["straw"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in 80:
		var angle: float = TAU * float(i) / 80.0
		var strand: PackedVector3Array = PackedVector3Array()
		for j: int in 13:
			var y: float = 0.03 + float(j) * 0.73 / 12.0
			strand.append(Vector3(sin(angle) * _radius(y), y, cos(angle) * _radius(y)))
		_tube(st, strand, 0.005)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["straw"] = mesh
	return mesh


static func _apron_mesh() -> ArrayMesh:
	if _meshes.has("apron"):
		return _meshes["apron"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in 12:
		for column: int in 32:
			# Clockwise from +Z: the printed surface must face out of the barrel.
			var corners: Array[Vector2] = [Vector2(column, row), Vector2(column + 1, row), Vector2(column, row + 1), Vector2(column + 1, row), Vector2(column + 1, row + 1), Vector2(column, row + 1)]
			for corner: Vector2 in corners:
				var uv: Vector2 = Vector2(corner.x / 32.0, corner.y / 12.0)
				var angle: float = (uv.x - 0.5) * 1.95
				var y: float = lerpf(0.65, 0.15, uv.y)
				var radius: float = _radius(y) + 0.008
				st.set_uv(uv)
				st.add_vertex(Vector3(sin(angle) * radius, y, cos(angle) * radius))
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["apron"] = mesh
	return mesh


static func _print_material(index: int) -> StandardMaterial3D:
	var key: String = "print_%d" % index
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var inks: Array[Color] = [Kit.INDIGO, Kit.CLAY, Kit.CHARCOAL, Kit.SAGE.darkened(0.25)]
	var ink: Color = inks[index]
	var image: Image = Image.create(512, 320, false, Image.FORMAT_RGBA8)
	image.fill(Kit.CREAM)
	# Broad seigaiha wave arcs and a vermilion sun form an unmistakable printed wrapper.
	for y: int in 320:
		for x: int in 512:
			var point: Vector2 = Vector2(float(x), float(y))
			var printed: bool = y < 10 or y > 309
			if y > 230:
				for row: int in 2:
					var center: Vector2 = Vector2(floor((float(x) + float(row) * 32.0) / 64.0) * 64.0 + 32.0 - float(row) * 32.0, 325.0 - float(row) * 38.0)
					var distance: float = point.distance_to(center)
					if distance < 60.0 and fmod(distance, 16.0) < 5.0:
						printed = true
			if printed:
				image.set_pixel(x, y, ink)
			elif point.distance_to(Vector2(438.0, 57.0)) < 29.0:
				image.set_pixel(x, y, Kit.CLAY)
	image.generate_mipmaps()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.roughness = 0.92
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materials[key] = material
	return material
