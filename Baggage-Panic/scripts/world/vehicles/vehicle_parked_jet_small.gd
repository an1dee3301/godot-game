extends RefCounted
## Parked regional turboprop. Model dimensions: 27 m length, 26 m span.
## Aircraft geometry is authored in metres, nose toward +Z, tires touching y = 0.
## The vehicle checker allows only 8 m width: presentation scale preserves proportions.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ParkedRegionalTurboprop"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	root.scale = Vector3.ONE * (7.98 / 26.0)
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colors: Array[Color] = [Color(0.91, 0.70, 0.20), Kit.CREAM, Kit.SAGE, Kit.CHARCOAL]
	var accents: Array[Color] = [Kit.CHARCOAL, Kit.CLAY, Kit.CREAM, Kit.OCHRE]
	var shell: Material = Kit.paint(colors[scheme], 0.34)
	var accent: Material = Kit.paint(accents[scheme], 0.42)
	var ivory: Material = Kit.paint(Kit.CREAM, 0.4)
	var steel: Material = Kit.metal(Kit.CHARCOAL, 0.36, 0.8, "jet_small_steel")
	var alloy: Material = Kit.metal(Color(0.65, 0.67, 0.65), 0.29, 0.9, "jet_small_alloy")
	var glass: Material = Kit.metal(Color(0.065, 0.13, 0.16), 0.16, 0.35, "jet_small_glazing")
	var rubber: Material = Kit.paint(Color(0.065, 0.06, 0.052), 0.95)
	var fuselage: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -13.5), Vector2(0.18, -13.2), Vector2(0.45, -11.8),
		Vector2(0.8, -9.5), Vector2(1.2, -7.0), Vector2(1.38, -4.0),
		Vector2(1.38, 7.0), Vector2(1.32, 8.8), Vector2(1.15, 10.2),
		Vector2(0.9, 11.4), Vector2(0.52, 12.6), Vector2(0.20, 13.25), Vector2(0.0, 13.5)])
	Kit.add(root, Kit.lathe(fuselage, 48), shell, Vector3(0.0, 3.05, 0.0), Vector3(90.0, 0.0, 0.0))
	# Curved low cheatline follows the fuselage rather than floating beside it.
	Kit.add(root, _cheatline(), accent, Vector3(0.0, 3.05, 0.0))
	Kit.add(root, _wing("main", 13.0, 3.6, 1.3, 0.48, 1.1), ivory, Vector3(0.0, 4.23, 0.6))
	# A swept vertical fin and a true T-mounted horizontal stabilizer.
	Kit.add(root, _wing("fin", 4.15, 4.1, 2.0, 0.38, 1.65, false), accent,
		Vector3(0.0, 3.45, -9.8), Vector3(0.0, 0.0, 90.0))
	Kit.add(root, _wing("tail", 4.9, 2.5, 1.0, 0.25, 0.75), ivory, Vector3(0.0, 7.55, -11.2))
	# Wing trailing-edge flap seams, high-mounted engine pods, and unblurred parked props.
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(7.0, 0.035, 0.055), Vector3(side * 6.5, 4.25, -0.82), steel, 0.015, false)
		Kit.rbox(root, Vector3(0.065, 0.05, 1.25), Vector3(side * 9.8, 4.25, -0.2), alloy, 0.02, false)
		_engine(root, side * 4.65, shell, steel, alloy, accent)
		Kit.rbox(root, Vector3(0.12, 0.15, 0.3), Vector3(side * 12.92, 4.29, -0.5),
			Kit.washi(Color(0.95, 0.12, 0.07) if side < 0.0 else Color(0.12, 0.8, 0.38), 2.0, "jet_nav_%s" % side), 0.05, false)
		# Warm metallic rims and deeply inset oval passenger windows, batched per side.
		_windows(root, side, alloy, glass)
		var cockpit: MeshInstance3D = Kit.rbox(root, Vector3(0.075, 0.65, 1.55),
			Vector3(side * 0.92, 3.70, 10.7), glass, 0.032)
		cockpit.rotation_degrees = Vector3(0.0, side * 17.0, side * 15.0)
		var windshield: MeshInstance3D = Kit.rbox(root, Vector3(0.65, 0.53, 0.065),
			Vector3(side * 0.36, 3.68, 11.59), glass, 0.03)
		windshield.rotation_degrees = Vector3(-28.0, side * 20.0, 0.0)
		_door(root, side, -7.8, shell, alloy, steel)
		# Broad livery lettering, using the shared international font.
		var ink: Color = Kit.CREAM if scheme == 3 else Kit.CHARCOAL
		_caption(root, "KOMOREBI AIR", Vector3(side * 1.393, 3.15, 1.2), side, 0.0105, ink)
		_caption(root, "Welcome · ようこそ · 欢迎", Vector3(side * 1.32, 2.65, 0.3), side, 0.0090, ink)
		_caption(root, "Chào mừng · Bienvenue · Bienvenidos", Vector3(side * 1.16, 2.20, 0.3), side, 0.0085, ink)
		# Main gear emerges from blended belly fairings, not the propeller pods.
		Kit.rbox(root, Vector3(0.65, 0.55, 2.55), Vector3(side * 1.42, 1.9, -1.2), shell, 0.25)
		Kit.rbox(root, Vector3(0.14, 1.55, 0.16), Vector3(side * 1.62, 1.35, -1.1), alloy, 0.05)
		Kit.rbox(root, Vector3(0.52, 0.16, 0.18), Vector3(side * 1.65, 0.61, -1.1), steel, 0.055)
		for offset: float in [-0.23, 0.23]:
			_wheel(root, Vector3(side * 1.65 + offset, 0.58, -1.1), 0.58, rubber, alloy)
		# Apron safety chocks: small rounded ochre wedges beside the main tires.
		Kit.rbox(root, Vector3(0.8, 0.20, 0.36), Vector3(side * 1.65, 0.10, -1.85), Kit.paint(Kit.OCHRE), 0.075)
	Kit.rbox(root, Vector3(0.15, 1.30, 0.15), Vector3(0.0, 1.23, 9.0), alloy, 0.045)
	Kit.rbox(root, Vector3(0.66, 0.14, 0.16), Vector3(0.0, 0.46, 9.0), steel, 0.04)
	for side: float in [-1.0, 1.0]:
		_wheel(root, Vector3(side * 0.24, 0.43, 9.0), 0.43, rubber, alloy)
		Kit.rbox(root, Vector3(0.22, 0.18, 0.08), Vector3(side * 0.32, 1.78, 9.7),
			Kit.washi(Kit.CREAM, 3.0, "jet_landing_lamp"), 0.045, false)
	Kit.add(root, Kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.13, 0.0),
		Vector2(0.13, 0.14), Vector2(0.07, 0.20), Vector2(0.0, 0.20)]), 16),
		Kit.washi(Color(1.0, 0.19, 0.07), 2.5, "jet_beacon"), Vector3(0.0, 4.44, 5.6))
	return root


static func _engine(parent: Node3D, x: float, shell: Material, steel: Material, alloy: Material, accent: Material) -> void:
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, -2.3), Vector2(0.27, -2.3),
		Vector2(0.52, -1.9), Vector2(0.63, -0.9), Vector2(0.65, 1.2),
		Vector2(0.48, 1.8), Vector2(0.31, 2.0), Vector2(0.0, 2.0)])
	Kit.add(parent, Kit.lathe(profile, 32), shell, Vector3(x, 3.92, 2.5), Vector3(90.0, 0.0, 0.0))
	Kit.rbox(parent, Vector3(0.72, 0.22, 0.14), Vector3(x, 3.46, 4.26), steel, 0.095)
	Kit.rbox(parent, Vector3(0.64, 0.055, 0.16), Vector3(x, 3.47, 4.34), alloy, 0.025)
	Kit.add(parent, Kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.19, 0.0),
		Vector2(0.19, 0.65), Vector2(0.0, 0.65)]), 20), steel, Vector3(x, 3.88, 0.3), Vector3(-65.0, 0.0, 0.0))
	var prop: Node3D = Node3D.new()
	prop.position = Vector3(x, 3.98, 4.58)
	parent.add_child(prop)
	for blade in 6:
		var holder: Node3D = Node3D.new()
		holder.rotation_degrees.z = float(blade) * 60.0 + 12.0
		prop.add_child(holder)
		var paddle: MeshInstance3D = Kit.add(holder, _wing("blade", 1.86, 0.33, 0.22, 0.075, 0.18, false), steel,
			Vector3(0.0, 0.17, 0.0), Vector3(90.0, 0.0, 90.0))
		paddle.rotation_degrees.y = 12.0
		Kit.rbox(holder, Vector3(0.20, 0.15, 0.065), Vector3(-0.13, 1.91, 0.0), accent, 0.025, false)
	Kit.add(prop, Kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.36, 0.0),
		Vector2(0.33, 0.18), Vector2(0.23, 0.43), Vector2(0.10, 0.62), Vector2(0.0, 0.69)]), 32),
		alloy, Vector3.ZERO, Vector3(90.0, 0.0, 0.0))


static func _wheel(parent: Node3D, at: Vector3, radius: float, rubber: Material, alloy: Material) -> void:
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, -0.15), Vector2(radius * 0.72, -0.15),
		Vector2(radius * 0.94, -0.11), Vector2(radius, -0.05), Vector2(radius, 0.05),
		Vector2(radius * 0.94, 0.11), Vector2(radius * 0.72, 0.15), Vector2(0.0, 0.15)])
	Kit.add(parent, Kit.lathe(profile, 24), rubber, at, Vector3(0.0, 0.0, 90.0))
	Kit.add(parent, Kit.lathe(PackedVector2Array([Vector2(0.0, -0.16), Vector2(radius * 0.44, -0.16),
		Vector2(radius * 0.44, 0.16), Vector2(0.0, 0.16)]), 20), alloy, at, Vector3(0.0, 0.0, 90.0))


static func _windows(parent: Node3D, side: float, rim: Material, glass: Material) -> void:
	for layer in 2:
		var multi: MultiMesh = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = Kit.rounded_box(Vector3(0.065, 0.59 if layer == 0 else 0.47, 0.43 if layer == 0 else 0.32), 0.03)
		multi.instance_count = 17
		for i in 17:
			var basis: Basis = Basis(Vector3.BACK, deg_to_rad(side * 22.0))
			multi.set_instance_transform(i, Transform3D(basis, Vector3(side * (1.29 + float(layer) * 0.045), 3.56, -5.65 + float(i) * 0.77)))
		var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instance.multimesh = multi
		instance.material_override = rim if layer == 0 else glass
		parent.add_child(instance)


static func _door(parent: Node3D, side: float, z: float, shell: Material, rim: Material, steel: Material) -> void:
	var holder: Node3D = Node3D.new()
	holder.position = Vector3(side * 1.12, 2.92, z)
	holder.rotation_degrees.y = side * 90.0
	parent.add_child(holder)
	Kit.rbox(holder, Vector3(0.94, 1.76, 0.06), Vector3.ZERO, rim, 0.025)
	Kit.rbox(holder, Vector3(0.86, 1.67, 0.065), Vector3(0.0, 0.0, 0.028), shell, 0.028)
	Kit.rbox(holder, Vector3(0.3, 0.42, 0.045), Vector3(0.0, 0.43, 0.075), steel, 0.021)
	Kit.rbox(holder, Vector3(0.24, 0.065, 0.075), Vector3(0.20, -0.12, 0.09), Kit.brass(), 0.022, false)


static func _caption(parent: Node3D, caption: String, at: Vector3, side: float, pixel: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signs.font()
	label.font_size = 96
	label.pixel_size = pixel
	label.modulate = ink
	label.outline_size = 0
	label.position = at
	label.rotation_degrees.y = side * 90.0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _wing(key: String, span: float, root_chord: float, tip_chord: float, thickness: float, sweep: float, symmetric: bool = true) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	var count: int = 24 if symmetric else 12
	for i in count + 1:
		var x: float = span * (2.0 * float(i) / float(count) - 1.0) if symmetric else span * float(i) / float(count)
		var t: float = absf(x) / span
		var chord: float = lerpf(root_chord, tip_chord, t)
		var ring: PackedVector3Array = PackedVector3Array()
		for j in 24:
			var angle: float = TAU * float(j) / 24.0
			var u: float = (1.0 - cos(angle)) * 0.5
			var depth: float = thickness * (1.0 - 0.65 * t)
			ring.append(Vector3(x, sin(angle) * depth * 0.5 * (0.7 + 0.3 * cos(angle)), chord * (0.5 - u) - sweep * t))
		rings.append(ring)
	for i in count:
		var a: PackedVector3Array = rings[i]
		var b: PackedVector3Array = rings[i + 1]
		for j in 24:
			var n: int = (j + 1) % 24
			_triangle(st, a[j], b[j], b[n])
			_triangle(st, a[j], b[n], a[n])
	for end in 2:
		var ring: PackedVector3Array = rings[0 if end == 0 else count]
		var center: Vector3 = Vector3.ZERO
		for vertex: Vector3 in ring:
			center += vertex / 24.0
		for j in 24:
			if end == 0:
				_triangle(st, center, ring[j], ring[(j + 1) % 24])
			else:
				_triangle(st, center, ring[(j + 1) % 24], ring[j])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _cheatline() -> ArrayMesh:
	if _meshes.has("cheatline"):
		return _meshes["cheatline"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		for i in 24:
			var z0: float = -6.0 + float(i) * (13.0 / 24.0)
			var z1: float = z0 + (13.0 / 24.0)
			for j in 4:
				var a: float = -0.62 + float(j) * 0.055
				var b: float = a + 0.055
				var p: Vector3 = Vector3(side * cos(a) * 1.391, sin(a) * 1.391, z0)
				var q: Vector3 = Vector3(side * cos(b) * 1.391, sin(b) * 1.391, z0)
				var r: Vector3 = Vector3(side * cos(b) * 1.391, sin(b) * 1.391, z1)
				var s: Vector3 = Vector3(side * cos(a) * 1.391, sin(a) * 1.391, z1)
				if side > 0.0:
					_triangle(st, p, r, q)
					_triangle(st, p, s, r)
				else:
					_triangle(st, p, q, r)
					_triangle(st, p, r, s)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["cheatline"] = mesh
	return mesh


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
