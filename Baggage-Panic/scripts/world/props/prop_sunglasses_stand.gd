extends RefCounted
## A hand-turnable optical carousel, parked in a different position for each variant.
## Eyewear is life-sized; repeated frames, lenses and supports share cached meshes.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "SunglassesCarousel"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var v: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.LINEN]
	var accent: Color = accents[v]
	var oak: StandardMaterial3D = DesignKit.wood()
	var dark_wood: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var brass: StandardMaterial3D = DesignKit.brass()
	var steel: StandardMaterial3D = DesignKit.metal()
	var stone: StandardMaterial3D = DesignKit.stone()

	# Heavy honed stone foot, recessed rubber sole and exposed swivel race.
	DesignKit.add(root, _disc(0.33, 0.018), steel, Vector3(0.0, 0.0, 0.0))
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.018), Vector2(0.32, 0.018), Vector2(0.355, 0.035),
		Vector2(0.36, 0.09), Vector2(0.345, 0.12), Vector2(0.0, 0.12)
	]), 48), stone, Vector3.ZERO)
	DesignKit.add(root, _disc(0.21, 0.018), brass, Vector3(0.0, 0.12, 0.0))
	DesignKit.add(root, _disc(0.18, 0.026), steel, Vector3(0.0, 0.138, 0.0))
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.16, 0.0), Vector2(0.17, 0.018),
		Vector2(0.17, 0.065), Vector2(0.125, 0.09), Vector2(0.0, 0.09)
	]), 32), dark_wood, Vector3(0.0, 0.164, 0.0))

	var carousel := Node3D.new()
	carousel.name = "SwivelAssembly"
	carousel.rotation_degrees.y = float(v) * 11.25
	root.add_child(carousel)
	DesignKit.add(carousel, _disc(0.065, 1.48), brass, Vector3(0.0, 0.22, 0.0))
	DesignKit.add(carousel, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.095, 0.0), Vector2(0.115, 0.035),
		Vector2(0.115, 1.16), Vector2(0.095, 1.2), Vector2(0.0, 1.2)
	]), 32), oak, Vector3(0.0, 0.36, 0.0))
	# Slim brass lines delineate the joinery rather than covering the oak grain.
	for side in 6:
		var angle: float = TAU * float(side) / 6.0
		DesignKit.rbox(carousel, Vector3(0.006, 1.11, 0.006),
			Vector3(sin(angle) * 0.115, 0.96, cos(angle) * 0.115), brass, 0.002, false)

	var frame_materials: Array[StandardMaterial3D] = [
		DesignKit.paint(DesignKit.CHARCOAL, 0.24), brass,
		DesignKit.paint(accent.darkened(0.3), 0.25),
		DesignKit.paint(DesignKit.WALNUT.darkened(0.15), 0.22)
	]
	for tier in 4:
		var y: float = 0.62 + float(tier) * 0.27
		DesignKit.add(carousel, _disc(0.37, 0.034), oak, Vector3(0.0, y - 0.055, 0.0))
		DesignKit.add(carousel, _ring(0.365, 0.371, 0.012), brass, Vector3(0.0, y - 0.039, 0.0), Vector3.ZERO, false)
		DesignKit.add(carousel, _ring(0.15, 0.345, 0.006),
			DesignKit.fabric(accent, "sunglasses_liner_%d" % v), Vector3(0.0, y - 0.019, 0.0), Vector3.ZERO, false)
		var placements: Array[Transform3D] = []
		for slot in 8:
			var angle: float = TAU * float(slot) / 8.0 + float(tier % 2) * PI / 8.0
			var basis: Basis = Basis(Vector3.UP, angle)
			placements.append(Transform3D(basis, Vector3(sin(angle) * 0.32, y, cos(angle) * 0.32)))
		var style: int = (tier + v) % 2
		_instances(carousel, _eyewear(style, false), frame_materials[(tier + v) % 4], placements, "Frames_%d" % tier)
		_instances(carousel, _eyewear(style, true), _lens_material(v), placements, "Lenses_%d" % tier)
		_instances(carousel, _support(), brass, placements, "NoseRests_%d" % tier)

	# A turned crown provides a comfortable hand grip for the manual rotation.
	DesignKit.add(carousel, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.1, 0.0), Vector2(0.145, 0.025),
		Vector2(0.16, 0.045), Vector2(0.16, 0.075), Vector2(0.145, 0.09),
		Vector2(0.075, 0.105), Vector2(0.0, 0.105)
	]), 32), dark_wood, Vector3(0.0, 1.58, 0.0))
	DesignKit.add(root, _disc(0.028, 0.22), brass, Vector3(0.0, 1.66, 0.0))

	# Stationary, double-faced header: three generous lines per face, six languages.
	DesignKit.rbox(root, Vector3(1.54, 0.69, 0.13), Vector3(0.0, 2.08, 0.0), oak, 0.045)
	DesignKit.rbox(root, Vector3(1.47, 0.62, 0.137), Vector3(0.0, 2.08, 0.0), brass, 0.033)
	DesignKit.rbox(root, Vector3(1.43, 0.58, 0.145), Vector3(0.0, 2.08, 0.0),
		DesignKit.washi(DesignKit.CREAM, 0.35, "sunglasses_header"), 0.028)
	var front_lines: Array[String] = ["SUNGLASSES", "サングラス", "太阳镜"]
	var back_lines: Array[String] = ["Kính mát", "Lunettes de soleil", "Gafas de sol"]
	for face in 2:
		var holder := Node3D.new()
		holder.position = Vector3(0.0, 2.08, 0.0)
		holder.rotation_degrees.y = float(face) * 180.0
		root.add_child(holder)
		var captions: Array[String] = front_lines if face == 0 else back_lines
		for line in 3:
			var label := Label3D.new()
			label.font = Signage.font()
			label.text = captions[line]
			label.font_size = 72 if face == 0 and line == 0 else 64
			label.pixel_size = 0.0025
			label.position = Vector3(0.0, 0.178 - float(line) * 0.178, 0.075)
			label.modulate = DesignKit.CHARCOAL
			label.outline_size = 0
			label.double_sided = false
			label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(label)
	return root


static func _disc(radius: float, height: float) -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(radius - 0.005, 0.0), Vector2(radius, 0.005),
		Vector2(radius, height - 0.005), Vector2(radius - 0.005, height), Vector2(0.0, height)
	]), 40)


static func _ring(inner: float, outer: float, height: float) -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(inner, 0.0), Vector2(outer - 0.002, 0.0), Vector2(outer, 0.002),
		Vector2(outer, height - 0.002), Vector2(outer - 0.002, height),
		Vector2(inner, height), Vector2(inner, 0.0)
	]), 40)


static func _instances(parent: Node3D, mesh: Mesh, material: Material, placements: Array[Transform3D], caption: String) -> void:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = placements.size()
	for i in placements.size():
		batch.set_instance_transform(i, placements[i])
	var node := MultiMeshInstance3D.new()
	node.name = caption
	node.multimesh = batch
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)


static func _lens_material(variant: int) -> StandardMaterial3D:
	if not _materials.has(variant):
		var tints: Array[Color] = [Color(0.075, 0.14, 0.11), Color(0.18, 0.105, 0.06), Color(0.065, 0.09, 0.16), Color(0.12, 0.12, 0.105)]
		var material := StandardMaterial3D.new()
		material.albedo_color = tints[variant]
		material.roughness = 0.12
		material.metallic = 0.2
		material.clearcoat_enabled = true
		material.clearcoat = 0.8
		material.clearcoat_roughness = 0.08
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials[variant] = material
	return _materials[variant] as StandardMaterial3D


static func _eyewear(style: int, lenses: bool) -> ArrayMesh:
	var key: String = "eyewear_%d_%s" % [style, lenses]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		var center := Vector3(side * 0.0365, 0.0, 0.0)
		var outline := PackedVector3Array()
		for segment in 32:
			var angle: float = TAU * float(segment) / 32.0
			var x: float = cos(angle)
			var y: float = sin(angle)
			if style == 1:
				x = signf(x) * pow(absf(x), 0.65)
				y = signf(y) * pow(absf(y), 0.65)
			outline.append(center + Vector3(x * 0.030, y * 0.021, 0.0))
		if lenses:
			for segment in 32:
				st.set_normal(Vector3.FORWARD * -1.0)
				st.add_vertex(center + Vector3(0.0, 0.0, 0.002))
				st.add_vertex(outline[(segment + 1) % 32])
				st.add_vertex(outline[segment])
		else:
			outline.append(outline[0])
			_tube(st, outline, 0.0028 if style == 1 else 0.0018)
			_tube(st, PackedVector3Array([
				Vector3(side * 0.067, 0.007, 0.0), Vector3(side * 0.071, 0.006, -0.025),
				Vector3(side * 0.07, 0.005, -0.095), Vector3(side * 0.063, -0.008, -0.115)
			]), 0.002)
	if not lenses:
		_tube(st, PackedVector3Array([Vector3(-0.009, 0.004, 0.0), Vector3(0.0, 0.009, 0.0), Vector3(0.009, 0.004, 0.0)]), 0.0018)
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _tube(st: SurfaceTool, path: PackedVector3Array, radius: float) -> void:
	for segment in path.size() - 1:
		var direction: Vector3 = (path[segment + 1] - path[segment]).normalized()
		var axis: Vector3 = Vector3.UP if absf(direction.y) < 0.9 else Vector3.RIGHT
		var u: Vector3 = direction.cross(axis).normalized()
		var w: Vector3 = direction.cross(u).normalized()
		for edge in 8:
			var a: float = TAU * float(edge) / 8.0
			var b: float = TAU * float(edge + 1) / 8.0
			var n0: Vector3 = u * cos(a) + w * sin(a)
			var n1: Vector3 = u * cos(b) + w * sin(b)
			var vertices: Array[Vector3] = [path[segment] + n0 * radius, path[segment + 1] + n0 * radius,
				path[segment + 1] + n1 * radius, path[segment] + n0 * radius,
				path[segment + 1] + n1 * radius, path[segment] + n1 * radius]
			var normals: Array[Vector3] = [n0, n0, n1, n0, n1, n1]
			for i in 6:
				st.set_normal(normals[i])
				st.add_vertex(vertices[i])


static func _support() -> ArrayMesh:
	if _meshes.has("support"):
		return _meshes["support"] as ArrayMesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tube(st, PackedVector3Array([Vector3(0.0, -0.019, -0.06), Vector3(0.0, 0.0, -0.06), Vector3(0.0, 0.0, -0.005)]), 0.003)
	st.append_from(DesignKit.rounded_box(Vector3(0.014, 0.008, 0.018), 0.003), 0,
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -0.004)))
	var mesh: ArrayMesh = st.commit()
	_meshes["support"] = mesh
	return mesh
