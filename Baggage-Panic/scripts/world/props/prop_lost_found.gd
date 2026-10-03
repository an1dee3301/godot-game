extends RefCounted
## A staffed recovery counter, with an open display of belongings awaiting their owners.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "LostFoundCounter"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var colours: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = colours[choice]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var steel: StandardMaterial3D = DesignKit.metal()
	var brass: StandardMaterial3D = DesignKit.brass()
	var limestone: StandardMaterial3D = DesignKit.stone()
	var linen: StandardMaterial3D = DesignKit.fabric()
	var textile: StandardMaterial3D = DesignKit.fabric(accent, "lost_found_%d" % choice)

	# Recessed stone toe, oak carcass, rounded service edge and a crafted vertical rhythm.
	DesignKit.rbox(root, Vector3(3.66, 0.14, 0.76), Vector3(-0.5, 0.07, 0.36), limestone, 0.045)
	DesignKit.rbox(root, Vector3(3.78, 0.78, 0.84), Vector3(-0.5, 0.53, 0.36), oak, 0.075)
	DesignKit.rbox(root, Vector3(3.94, 0.11, 1.0), Vector3(-0.5, 0.975, 0.36), oak, 0.05)
	DesignKit.rbox(root, Vector3(3.65, 0.025, 0.025), Vector3(-0.5, 0.88, 0.79), brass, 0.009, false)
	for i in 22:
		DesignKit.rbox(root, Vector3(0.075, 0.63, 0.055), Vector3(-2.21 + float(i) * 0.163, 0.51, 0.802), oak, 0.026, false)
	# Lower accessible writing ledge at the right-hand end.
	DesignKit.rbox(root, Vector3(0.78, 0.08, 0.38), Vector3(1.03, 0.77, 0.91), oak, 0.035)
	DesignKit.rbox(root, Vector3(0.025, 0.23, 0.25), Vector3(1.25, 0.635, 0.84), steel, 0.009)
	DesignKit.rbox(root, Vector3(0.68, 0.025, 0.42), Vector3(-0.35, 1.043, 0.41), textile, 0.01, false)
	# Shallow walnut return tray with a limestone insert and raised rounded lip.
	DesignKit.rbox(root, Vector3(0.64, 0.075, 0.4), Vector3(-1.65, 1.065, 0.39), walnut, 0.028)
	DesignKit.rbox(root, Vector3(0.54, 0.025, 0.3), Vector3(-1.65, 1.105, 0.39), limestone, 0.015, false)
	DesignKit.rbox(root, Vector3(0.055, 0.055, 0.32), Vector3(-1.94, 1.12, 0.39), walnut, 0.02)
	DesignKit.rbox(root, Vector3(0.055, 0.055, 0.32), Vector3(-1.36, 1.12, 0.39), walnut, 0.02)
	# Angled staff terminal: metal pedestal, softened shell and a quiet sage screen.
	DesignKit.rbox(root, Vector3(0.3, 0.035, 0.23), Vector3(0.65, 1.048, 0.13), steel, 0.016)
	DesignKit.rbox(root, Vector3(0.055, 0.22, 0.06), Vector3(0.65, 1.16, 0.12), brass, 0.02)
	var terminal: MeshInstance3D = DesignKit.rbox(root, Vector3(0.45, 0.3, 0.055), Vector3(0.65, 1.32, 0.14), steel, 0.025)
	terminal.rotation_degrees.x = -12.0
	var screen: MeshInstance3D = DesignKit.rbox(root, Vector3(0.395, 0.245, 0.008), Vector3(0.65, 1.325, 0.171), DesignKit.washi(DesignKit.SAGE.lightened(0.25), 0.35, "lf_screen"), 0.003, false)
	screen.rotation_degrees.x = -12.0

	# Open walnut shelving behind the staff aisle; paper-soft back and oak shelf edges.
	DesignKit.rbox(root, Vector3(3.88, 2.3, 0.09), Vector3(-0.5, 1.25, -0.96), DesignKit.paint(DesignKit.PLASTER), 0.035)
	for x: float in [-2.4, 1.4]:
		DesignKit.rbox(root, Vector3(0.095, 2.43, 0.58), Vector3(x, 1.215, -0.72), walnut, 0.03)
	for shelf_y: float in [0.19, 1.23, 1.85, 2.43]:
		DesignKit.rbox(root, Vector3(3.82, 0.07, 0.58), Vector3(-0.5, shelf_y, -0.72), walnut, 0.023)
		DesignKit.rbox(root, Vector3(3.71, 0.025, 0.04), Vector3(-0.5, shelf_y + 0.005, -0.412), oak, 0.01, false)
	for x: float in [-1.2, 0.12]:
		DesignKit.rbox(root, Vector3(0.06, 1.2, 0.51), Vector3(x, 1.81, -0.72), walnut, 0.019)
	for shelf_y: float in [1.81, 2.39]:
		DesignKit.rbox(root, Vector3(3.57, 0.018, 0.035), Vector3(-0.5, shelf_y, -0.51), DesignKit.washi(DesignKit.CREAM, 1.15, "lf_shelf_glow"), 0.007, false)
	# Two linen archive bins in the lower cubbies, with broad leather loop pulls.
	for x: float in [-1.75, -0.52]:
		DesignKit.rbox(root, Vector3(0.87, 0.32, 0.4), Vector3(x, 1.425, -0.68), linen, 0.045)
		DesignKit.rbox(root, Vector3(0.88, 0.035, 0.41), Vector3(x, 1.585, -0.68), textile, 0.014)
		DesignKit.rbox(root, Vector3(0.18, 0.07, 0.026), Vector3(x, 1.46, -0.465), DesignKit.paint(DesignKit.WALNUT), 0.023, false)
	_hat(root, Vector3(0.7, 1.265, -0.66), textile, brass)
	_hat(root, Vector3(-1.78, 1.885, -0.66), linen, DesignKit.paint(accent))
	_hat(root, Vector3(-1.65, 2.05, -0.66), textile, brass)
	_bear(root, Vector3(-0.58, 1.885, -0.64), DesignKit.fabric(DesignKit.OCHRE.lightened(0.16), "lf_bear_honey"), textile)
	_bear(root, Vector3(0.66, 1.885, -0.64), linen, DesignKit.fabric(colours[(choice + 1) % 4], "lf_scarf_%d" % choice))

	# Umbrellas occupy their own side bay, clear of the accessible customer ledge.
	DesignKit.rbox(root, Vector3(0.7, 0.09, 0.63), Vector3(1.99, 0.045, -0.29), limestone, 0.035)
	DesignKit.rbox(root, Vector3(0.59, 0.35, 0.49), Vector3(1.99, 0.26, -0.29), walnut, 0.055)
	DesignKit.rbox(root, Vector3(0.48, 0.035, 0.37), Vector3(1.99, 0.445, -0.29), steel, 0.015)
	for i in 3:
		var umbrella_colour: Color = colours[(choice + i) % 4]
		_umbrella(root, Vector3(1.81 + float(i) * 0.17, 0.43, -0.29 + (0.08 if i == 1 else -0.02)), DesignKit.fabric(umbrella_colour, "lf_umbrella_%d" % ((choice + i) % 4)), walnut, brass, float(i - 1) * 7.0)

	# Large full translation panel, held by brass uprights rather than floating signage.
	for x: float in [-2.24, 1.24]:
		DesignKit.rbox(root, Vector3(0.045, 0.54, 0.06), Vector3(x, 2.68, -0.8), brass, 0.014)
	var sign: Node3D = Signage.panel(root, Vector3(-0.5, 3.16, -0.73), "lost_found", {"width": 3.8, "accent": accent})
	sign.scale = Vector3.ONE * 1.25
	return root


static func _ball(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	if not _meshes.has("ball"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 16
		sphere.rings = 8
		_meshes["ball"] = sphere
	var mesh: SphereMesh = _meshes["ball"]
	var item: MeshInstance3D = DesignKit.add(parent, mesh, material, at, Vector3.ZERO, false)
	item.scale = size


static func _bear(parent: Node3D, at: Vector3, fur: Material, scarf: Material) -> void:
	_ball(parent, at + Vector3(0.0, 0.18, 0.0), Vector3(0.25, 0.31, 0.2), fur)
	_ball(parent, at + Vector3(0.0, 0.39, 0.015), Vector3(0.25, 0.23, 0.22), fur)
	for side: float in [-1.0, 1.0]:
		_ball(parent, at + Vector3(side * 0.105, 0.49, 0.01), Vector3(0.105, 0.105, 0.08), fur)
		_ball(parent, at + Vector3(side * 0.12, 0.06, 0.065), Vector3(0.13, 0.12, 0.19), fur)
		_ball(parent, at + Vector3(side * 0.14, 0.23, 0.015), Vector3(0.105, 0.21, 0.105), fur)
		_ball(parent, at + Vector3(side * 0.047, 0.415, 0.114), Vector3(0.019, 0.022, 0.014), DesignKit.paint(DesignKit.CHARCOAL))
	_ball(parent, at + Vector3(0.0, 0.365, 0.122), Vector3(0.115, 0.075, 0.057), DesignKit.fabric(DesignKit.CREAM, "lf_muzzle"))
	_ball(parent, at + Vector3(0.0, 0.38, 0.151), Vector3(0.034, 0.025, 0.015), DesignKit.paint(DesignKit.CHARCOAL))
	DesignKit.rbox(parent, Vector3(0.23, 0.055, 0.21), at + Vector3(0.0, 0.29, 0.0), scarf, 0.025, false)
	DesignKit.rbox(parent, Vector3(0.065, 0.14, 0.025), at + Vector3(0.065, 0.235, 0.115), scarf, 0.012, false)


static func _hat(parent: Node3D, at: Vector3, material: Material, band: Material) -> void:
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.005), Vector2(0.24, 0.005), Vector2(0.255, 0.025), Vector2(0.23, 0.042), Vector2(0.15, 0.048), Vector2(0.14, 0.16), Vector2(0.11, 0.185), Vector2(0.0, 0.19)])
	DesignKit.add(parent, DesignKit.lathe(profile), material, at)
	var ribbon: PackedVector2Array = PackedVector2Array([Vector2(0.149, 0.056), Vector2(0.148, 0.085), Vector2(0.144, 0.089)])
	DesignKit.add(parent, DesignKit.lathe(ribbon), band, at, Vector3.ZERO, false)


static func _umbrella(parent: Node3D, at: Vector3, fabric: Material, handle: Material, trim: Material, tilt: float) -> void:
	var holder: Node3D = Node3D.new()
	holder.position = at
	holder.rotation_degrees.z = tilt
	parent.add_child(holder)
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.025, 0.04), Vector2(0.072, 0.12), Vector2(0.064, 0.65), Vector2(0.035, 0.78), Vector2(0.014, 0.82), Vector2(0.0, 0.825)])
	DesignKit.add(holder, DesignKit.lathe(profile, 12), fabric, Vector3.ZERO)
	DesignKit.rbox(holder, Vector3(0.025, 0.19, 0.025), Vector3(0.0, 0.9, 0.0), trim, 0.01, false)
	var strap: PackedVector2Array = PackedVector2Array([Vector2(0.068, 0.51), Vector2(0.071, 0.515), Vector2(0.071, 0.545), Vector2(0.067, 0.55)])
	DesignKit.add(holder, DesignKit.lathe(strap, 12), trim, Vector3.ZERO, Vector3.ZERO, false)
	DesignKit.add(holder, _hook_mesh(), handle, Vector3(0.0, 0.98, 0.0), Vector3.ZERO, false)


static func _hook_mesh() -> ArrayMesh:
	if _meshes.has("umbrella_hook"):
		var cached: ArrayMesh = _meshes["umbrella_hook"]
		return cached
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Semicircular wooden crook, swept in the XY plane with a round cross-section.
	for segment in 12:
		for ring in 8:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var angle: float = PI - PI * float(segment + corner.x) / 12.0
				var around: float = TAU * float(ring + corner.y) / 8.0
				var radial: Vector3 = Vector3(cos(angle), sin(angle), 0.0)
				var normal: Vector3 = radial * cos(around) + Vector3(0.0, 0.0, sin(around))
				surface.set_normal(normal)
				surface.add_vertex(Vector3(0.064, 0.0, 0.0) + radial * 0.064 + normal * 0.017)
	var mesh: ArrayMesh = surface.commit()
	_meshes["umbrella_hook"] = mesh
	return mesh
