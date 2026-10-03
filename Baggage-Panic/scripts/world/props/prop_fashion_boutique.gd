extends RefCounted
## KAZE: a five-metre open boutique, with all dimensions in metres and front toward +Z.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "KazeFashionBoutique"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var colours: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.INDIGO, Kit.LINEN]
	var accent: Color = colours[choice]
	var oak: Material = Kit.wood()
	var walnut: Material = Kit.wood(Kit.WALNUT, "walnut")
	var stone: Material = Kit.stone()
	var steel: Material = Kit.metal()
	var brass: Material = Kit.brass()
	var glow: Material = Kit.washi(Kit.CREAM, 1.35, "kaze_paper")
	# Flush floor contact, honed threshold and softly eased oak portal joinery.
	Kit.rbox(root, Vector3(5.0, 0.06, 2.6), Vector3(0, 0.03, -0.2), stone, 0.025)
	Kit.rbox(root, Vector3(4.55, 2.72, 0.16), Vector3(0, 1.42, -1.42), Kit.stone(Kit.PLASTER, 0.8, "kaze_plaster"), 0.07)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.25, 3.4, 0.42), Vector3(side * 2.375, 1.7, 0.77), oak, 0.075)
		Kit.rbox(root, Vector3(0.16, 2.75, 2.18), Vector3(side * 2.42, 1.435, -0.55), oak, 0.055)
		Kit.rbox(root, Vector3(0.27, 0.12, 0.44), Vector3(side * 2.375, 0.12, 0.77), walnut, 0.028)
		Kit.rbox(root, Vector3(0.025, 2.53, 0.018), Vector3(side * 2.245, 1.4, 0.985), brass, 0.006, false)
	Kit.rbox(root, Vector3(5.0, 0.68, 0.44), Vector3(0, 3.06, 0.77), oak, 0.075)
	Kit.rbox(root, Vector3(4.45, 0.5, 0.035), Vector3(0, 3.06, 1.001), glow, 0.045, false)
	_label(root, "KAZE 風", Vector3(0, 3.065, 1.025), 140, 0.0039, Kit.CHARCOAL)
	Kit.rbox(root, Vector3(4.45, 0.027, 0.025), Vector3(0, 2.76, 0.85), glow, 0.009, false)
	# Walnut skirting and an inset fabric wall field behind the apparel.
	Kit.rbox(root, Vector3(4.55, 0.12, 0.055), Vector3(0, 0.12, -1.31), walnut, 0.025)
	Kit.rbox(root, Vector3(4.12, 1.83, 0.035), Vector3(0, 1.08, -1.315), Kit.fabric(Kit.LINEN, "kaze_wall_linen"), 0.018)
	var welcome: Array = Signs.TEXT["welcome"]
	_label(root, "%s · %s · %s" % [welcome[0], welcome[1], welcome[2]], Vector3(0, 2.56, -1.318), 64, 0.0032, Kit.CHARCOAL)
	_label(root, "%s · %s · %s" % [welcome[3], welcome[4], welcome[5]], Vector3(0, 2.27, -1.318), 60, 0.0028, Kit.CHARCOAL)
	# Two freestanding brass rails: shaped jackets hang from real triangular hangers.
	for rack: int in 2:
		var x: float = -1.28 if rack == 0 else 1.28
		for dx: float in [-0.7, 0.7]:
			Kit.rbox(root, Vector3(0.25, 0.045, 0.52), Vector3(x + dx, 0.085, -0.65), steel, 0.02)
			_beam(root, Vector3(x + dx, 0.11, -0.65), Vector3(x + dx, 1.91, -0.65), 0.028, brass)
		_beam(root, Vector3(x - 0.7, 1.91, -0.65), Vector3(x + 0.7, 1.91, -0.65), 0.03, brass)
		for item: int in 3:
			var garment_x: float = x - 0.45 + float(item) * 0.45
			var tint: Color = colours[posmod(choice + item + rack, 4)]
			_garment(root, Vector3(garment_x, 1.7, -0.65 + float(item % 2) * 0.035), tint, item == 1)
	# Small walnut merchandising island, with honed top and folded woven clothing.
	Kit.rbox(root, Vector3(1.15, 0.13, 0.65), Vector3(-0.85, 0.76, 0.45), walnut, 0.06)
	Kit.rbox(root, Vector3(1.09, 0.045, 0.59), Vector3(-0.85, 0.845, 0.45), stone, 0.022)
	for dx: float in [-0.42, 0.42]:
		Kit.rbox(root, Vector3(0.08, 0.66, 0.46), Vector3(-0.85 + dx, 0.4, 0.45), walnut, 0.028)
	Kit.rbox(root, Vector3(0.96, 0.055, 0.48), Vector3(-0.85, 0.3, 0.45), oak, 0.022)
	for stack: int in 2:
		for layer: int in 3:
			var tint: Color = colours[posmod(choice + stack + layer, 4)]
			var folded: Material = Kit.fabric(tint, "kaze_fold_" + str(posmod(choice + stack + layer, 4)))
			Kit.rbox(root, Vector3(0.4, 0.048, 0.34), Vector3(-1.1 + float(stack) * 0.5, 0.895 + float(layer) * 0.05, 0.45), folded, 0.02)
	_mannequin(root, Vector3(0.72, 0.06, 0.5), accent, choice)
	# Washi pendant with oak collars; lateral placement keeps the brand unobstructed.
	var lantern: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.12, 0), Vector2(0.18, 0.05), Vector2(0.2, 0.17), Vector2(0.17, 0.32), Vector2(0.1, 0.36), Vector2(0, 0.36)]))
	Kit.add(root, lantern, glow, Vector3(-1.65, 2.09, 0.36), Vector3.ZERO, false)
	_beam(root, Vector3(-1.65, 2.45, 0.36), Vector3(-1.65, 2.75, 0.36), 0.018, steel)
	Kit.rbox(root, Vector3(0.22, 0.028, 0.22), Vector3(-1.65, 2.45, 0.36), oak, 0.04)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signs.font()
	label.font_size = size
	label.pixel_size = pixel
	label.position = at
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _beam(parent: Node3D, start: Vector3, finish: Vector3, thickness: float, material: Material) -> void:
	var direction: Vector3 = finish - start
	var part: MeshInstance3D = Kit.rbox(parent, Vector3(thickness, direction.length(), thickness), (start + finish) * 0.5, material, thickness * 0.45, false)
	part.quaternion = Quaternion(Vector3.UP, direction.normalized())


static func _garment(parent: Node3D, at: Vector3, tint: Color, long_cut: bool) -> void:
	var oak: Material = Kit.wood()
	var cloth: Material = Kit.fabric(tint, "kaze_cloth_" + tint.to_html())
	_beam(parent, at + Vector3(-0.19, -0.035, 0), at + Vector3(0, 0.075, 0), 0.022, oak)
	_beam(parent, at + Vector3(0, 0.075, 0), at + Vector3(0.19, -0.035, 0), 0.022, oak)
	_beam(parent, at + Vector3(0, 0.075, 0), at + Vector3(0, 0.21, 0), 0.012, Kit.brass())
	Kit.add(parent, _coat_mesh(long_cut), cloth, at)
	var length: float = 0.78 if long_cut else 0.6
	Kit.rbox(parent, Vector3(0.012, length - 0.1, 0.012), at + Vector3(0, -length * 0.5 - 0.025, 0.062), Kit.fabric(Kit.CREAM, "kaze_seams"), 0.004, false)
	var collar: MeshInstance3D = Kit.rbox(parent, Vector3(0.085, 0.11, 0.025), at + Vector3(0.035, -0.045, 0.064), cloth, 0.012, false)
	collar.rotation_degrees.z = -28.0


static func _coat_mesh(long_cut: bool) -> ArrayMesh:
	var key: String = "coat_long" if long_cut else "coat_short"
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var length: float = 0.78 if long_cut else 0.6
	# An extruded tailored silhouette: neck opening, shoulders, sleeves and flared hem.
	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(-0.055, 0.02), Vector2(-0.19, -0.035), Vector2(-0.29, -0.28),
		Vector2(-0.2, -0.32), Vector2(-0.14, -0.18), Vector2(-0.18, -length),
		Vector2(0.18, -length), Vector2(0.14, -0.18), Vector2(0.2, -0.32),
		Vector2(0.29, -0.28), Vector2(0.19, -0.035), Vector2(0.055, 0.02), Vector2(0, -0.045)])
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(outline)
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: float in [-1.0, 1.0]:
		for tri: int in range(0, indices.size(), 3):
			for corner: int in 3:
				var offset: int = corner if face < 0.0 else 2 - corner
				var p: Vector2 = outline[indices[tri + offset]]
				surface.set_normal(Vector3(0, 0, face))
				surface.set_uv(Vector2(p.x + 0.5, -p.y))
				surface.add_vertex(Vector3(p.x, p.y, face * 0.055))
	for edge: int in outline.size():
		var p: Vector2 = outline[edge]
		var q: Vector2 = outline[(edge + 1) % outline.size()]
		var normal: Vector3 = Vector3(q.y - p.y, p.x - q.x, 0).normalized()
		var vertices: Array[Vector3] = [Vector3(p.x, p.y, -0.055), Vector3(q.x, q.y, -0.055), Vector3(q.x, q.y, 0.055), Vector3(p.x, p.y, -0.055), Vector3(q.x, q.y, 0.055), Vector3(p.x, p.y, 0.055)]
		for vertex: Vector3 in vertices:
			surface.set_normal(normal)
			surface.set_uv(Vector2(vertex.x + 0.5, -vertex.y))
			surface.add_vertex(vertex)
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _mannequin(parent: Node3D, at: Vector3, accent: Color, choice: int) -> void:
	var body: Material = Kit.stone(Kit.CREAM, 0.7, "kaze_mannequin")
	var cloth: Material = Kit.fabric(accent, "kaze_cloth_" + accent.to_html())
	var plinth: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.37, 0), Vector2(0.39, 0.025), Vector2(0.39, 0.105), Vector2(0.36, 0.13), Vector2(0, 0.13)]))
	Kit.add(parent, plinth, Kit.wood(Kit.WALNUT, "walnut"), at)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(parent, Vector3(0.11, 0.085, 0.25), at + Vector3(side * 0.095, 0.175, 0.03), body, 0.04)
		_beam(parent, at + Vector3(side * 0.095, 0.21, 0), at + Vector3(side * 0.09, 0.91, 0), 0.092, body)
		_beam(parent, at + Vector3(side * 0.21, 1.42, 0), at + Vector3(side * 0.3, 1.08, 0.035), 0.087, body)
		_beam(parent, at + Vector3(side * 0.3, 1.08, 0.035), at + Vector3(side * 0.26, 0.89, 0.07), 0.065, body)
	var dress: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.29, 0), Vector2(0.3, 0.035), Vector2(0.2, 0.34), Vector2(0.13, 0.49), Vector2(0.18, 0.68), Vector2(0.23, 0.78), Vector2(0.105, 0.84), Vector2(0, 0.84)]))
	var torso: MeshInstance3D = Kit.add(parent, dress, cloth, at + Vector3(0, 0.64, 0))
	torso.scale.z = 0.64
	Kit.rbox(parent, Vector3(0.28, 0.034, 0.2), at + Vector3(0, 1.13, 0), Kit.fabric(Kit.WALNUT, "kaze_belt"), 0.015)
	Kit.rbox(parent, Vector3(0.05, 0.045, 0.018), at + Vector3(0.025, 1.13, 0.109), Kit.brass(), 0.009, false)
	_beam(parent, at + Vector3(0, 1.47, 0), at + Vector3(0, 1.6, 0), 0.09, body)
	var head: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.065, 0.025), Vector2(0.1, 0.1), Vector2(0.098, 0.21), Vector2(0.07, 0.27), Vector2(0, 0.29)]))
	Kit.add(parent, head, body, at + Vector3(0, 1.56, 0))
	if choice % 2 == 0:
		Kit.rbox(parent, Vector3(0.1, 0.56, 0.035), at + Vector3(-0.1, 1.17, 0.145), Kit.fabric(Kit.LINEN, "kaze_scarf"), 0.015)
	else:
		Kit.rbox(parent, Vector3(0.2, 0.23, 0.085), at + Vector3(0.3, 0.79, 0.08), Kit.fabric(Kit.CLAY, "kaze_tote"), 0.035)
		_beam(parent, at + Vector3(0.23, 0.9, 0.08), at + Vector3(0.3, 1.01, 0.08), 0.015, Kit.brass())
		_beam(parent, at + Vector3(0.3, 1.01, 0.08), at + Vector3(0.37, 0.9, 0.08), 0.015, Kit.brass())
