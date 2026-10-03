extends RefCounted
## Heavy airport rescue tender: 10.6 m long, six single off-road tyres, forward roof monitor.
## Operator colours stay warm; rescue red and yellow remain visible in every scheme.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "AirportCrashFireTruck"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var schemes: Array[Color] = [Color(0.95, 0.72, 0.13), DesignKit.CREAM, DesignKit.SAGE, DesignKit.CHARCOAL]
	var scheme: int = posmod(variant, 4)
	var body: StandardMaterial3D = DesignKit.paint(schemes[scheme], 0.36)
	var red: StandardMaterial3D = DesignKit.paint(Color(0.69, 0.13, 0.075), 0.38)
	var yellow: StandardMaterial3D = DesignKit.paint(Color(1.0, 0.79, 0.16), 0.3)
	var stripe: StandardMaterial3D = DesignKit.brass() if scheme == 3 else DesignKit.paint(DesignKit.CLAY if scheme == 1 else Color(1.0, 0.79, 0.16), 0.35)
	var steel: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.48, 0.75, "arff_chassis")
	var alloy: StandardMaterial3D = DesignKit.metal(Color(0.63, 0.64, 0.6), 0.34, 0.9, "arff_alloy")
	var rubber: StandardMaterial3D = DesignKit.paint(Color(0.055, 0.052, 0.047), 0.96)
	var glass: StandardMaterial3D = DesignKit.metal(Color(0.1, 0.19, 0.21), 0.17, 0.35, "arff_glass")
	var headlight: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 3.5, "arff_headlights")
	var beacon: StandardMaterial3D = DesignKit.washi(Color(1.0, 0.37, 0.055), 4.0, "arff_amber")
	var tail: StandardMaterial3D = DesignKit.washi(Color(0.95, 0.055, 0.02), 2.5, "arff_tail")

	# Deep frame and lower red rescue sill. Bodies sit above the tyre crowns.
	DesignKit.rbox(root, Vector3(2.65, 0.42, 9.65), Vector3(0.0, 0.93, 0.0), steel, 0.12)
	DesignKit.rbox(root, Vector3(3.05, 0.53, 9.55), Vector3(0.0, 1.56, 0.0), red, 0.15)
	DesignKit.rbox(root, Vector3(3.15, 1.48, 6.55), Vector3(0.0, 2.53, -1.42), body, 0.18)
	DesignKit.rbox(root, Vector3(3.22, 0.13, 6.65), Vector3(0.0, 3.3, -1.42), steel, 0.05)
	# Crew cab: softened lower shell, high panoramic glazing, projecting brow.
	DesignKit.rbox(root, Vector3(3.2, 1.0, 2.95), Vector3(0.0, 1.88, 3.35), body, 0.22)
	DesignKit.rbox(root, Vector3(3.12, 1.28, 2.65), Vector3(0.0, 2.87, 3.24), body, 0.22)
	var windshield: MeshInstance3D = DesignKit.rbox(root, Vector3(2.82, 1.02, 0.085), Vector3(0.0, 2.9, 4.56), glass, 0.1)
	windshield.rotation_degrees.x = -12.0
	DesignKit.rbox(root, Vector3(0.07, 1.02, 0.1), Vector3(0.0, 2.9, 4.61), steel, 0.02).rotation_degrees.x = -12.0
	DesignKit.rbox(root, Vector3(3.28, 0.16, 2.87), Vector3(0.0, 3.57, 3.27), body, 0.07)
	DesignKit.rbox(root, Vector3(3.36, 0.38, 0.43), Vector3(0.0, 1.12, 4.92), steel, 0.12)
	DesignKit.rbox(root, Vector3(3.28, 0.3, 0.36), Vector3(0.0, 1.23, -4.91), steel, 0.1)
	DesignKit.rbox(root, Vector3(1.48, 0.38, 0.06), Vector3(0.0, 1.84, 4.85), steel, 0.06)
	for row in 4:
		DesignKit.rbox(root, Vector3(1.34, 0.025, 0.035), Vector3(0.0, 1.71 + float(row) * 0.08, 4.893), alloy, 0.009, false)
	for side: float in [-1.0, 1.0]:
		# Single wheels on three axles; lathed shoulders and recessed hub dishes.
		for axle_z: float in [3.22, -0.82, -3.07]:
			DesignKit.add(root, _tyre(), rubber, Vector3(side * 1.4, 0.72, axle_z), Vector3(0.0, 0.0, 90.0))
			DesignKit.add(root, _hub(), alloy, Vector3(side * 1.71, 0.72, axle_z), Vector3(0.0, 0.0, -side * 90.0))
			DesignKit.rbox(root, Vector3(0.26, 0.16, 1.66), Vector3(side * 1.52, 1.53, axle_z), steel, 0.075)
			DesignKit.rbox(root, Vector3(0.12, 0.56, 0.12), Vector3(side * 1.49, 0.92, axle_z - 0.83), rubber, 0.035)
		# Cabin doors: dark gasket outline, inset window, handle, aluminium access step.
		DesignKit.rbox(root, Vector3(0.055, 1.78, 1.66), Vector3(side * 1.608, 2.38, 3.23), steel, 0.08)
		DesignKit.rbox(root, Vector3(0.065, 1.64, 1.52), Vector3(side * 1.647, 2.38, 3.23), body, 0.065)
		DesignKit.rbox(root, Vector3(0.07, 0.88, 1.32), Vector3(side * 1.69, 2.91, 3.24), glass, 0.09)
		DesignKit.rbox(root, Vector3(0.08, 0.08, 0.32), Vector3(side * 1.71, 2.23, 2.82), alloy, 0.025, false)
		DesignKit.rbox(root, Vector3(0.35, 0.14, 1.25), Vector3(side * 1.59, 1.22, 2.25), alloy, 0.04)
		DesignKit.rbox(root, Vector3(0.42, 0.065, 0.075), Vector3(side * 1.79, 2.94, 4.03), steel, 0.025, false)
		DesignKit.rbox(root, Vector3(0.18, 0.46, 0.32), Vector3(side * 1.97, 2.85, 4.04), steel, 0.06)
		DesignKit.rbox(root, Vector3(0.025, 0.37, 0.23), Vector3(side * 2.07, 2.85, 4.04), glass, 0.04, false)
		# Wide identification band; clean bilingual/multilingual lettering on the tank.
		DesignKit.rbox(root, Vector3(0.065, 0.25, 6.2), Vector3(side * 1.589, 1.94, -1.42), stripe, 0.025, false)
		var ink: Color = DesignKit.CREAM if scheme == 3 else DesignKit.CHARCOAL
		_label(root, "AIRPORT FIRE · 06", Vector3(side * 1.595, 3.02, -0.92), side * 90.0, 0.4, ink)
		_label(root, "空港消防　机场消防", Vector3(side * 1.595, 2.7, -0.92), side * 90.0, 0.28, ink)
		_label(root, "Cứu hỏa sân bay", Vector3(side * 1.595, 2.42, -0.92), side * 90.0, 0.26, ink)
		_label(root, "Pompiers · Bomberos", Vector3(side * 1.595, 2.15, -0.92), side * 90.0, 0.26, ink)
		# Rear roller-shutter equipment bay with corrugated slats and a wide grab bar.
		DesignKit.rbox(root, Vector3(0.09, 1.15, 1.12), Vector3(side * 1.62, 2.57, -3.97), steel, 0.04)
		DesignKit.rbox(root, Vector3(0.035, 1.04, 1.0), Vector3(side * 1.68, 2.57, -3.97), alloy, 0.02)
		_shutter_ribs(root, side, alloy)
		DesignKit.rbox(root, Vector3(0.1, 0.065, 0.65), Vector3(side * 1.73, 2.12, -3.97), steel, 0.02, false)
		DesignKit.rbox(root, Vector3(0.62, 0.29, 0.095), Vector3(side * 1.08, 1.86, 4.87), steel, 0.06)
		DesignKit.rbox(root, Vector3(0.49, 0.15, 0.07), Vector3(side * 1.08, 1.86, 4.93), headlight, 0.04, false)
		DesignKit.rbox(root, Vector3(0.34, 0.16, 0.08), Vector3(side * 1.23, 1.83, -4.75), tail, 0.04, false)
		DesignKit.rbox(root, Vector3(0.25, 0.09, 0.075), Vector3(side * 1.23, 2.04, -4.75), beacon, 0.025, false)
		DesignKit.rbox(root, Vector3(0.46, 0.08, 0.48), Vector3(side * 1.12, 3.68, 3.41), steel, 0.03)
		DesignKit.add(root, _beacon(), beacon, Vector3(side * 1.12, 3.72, 3.41), Vector3.ZERO, false)
	# Roof monitor: turntable, swivel, inclined red barrel, alloy nozzle and dark bore.
	DesignKit.add(root, _cylinder(0.42, 0.16), steel, Vector3(0.0, 3.68, 1.7))
	DesignKit.add(root, _cylinder(0.24, 0.4), red, Vector3(0.0, 3.93, 1.7))
	DesignKit.rbox(root, Vector3(0.68, 0.31, 0.65), Vector3(0.0, 4.13, 1.72), red, 0.12)
	var gun: Node3D = Node3D.new()
	gun.position = Vector3(0.0, 4.18, 1.85)
	gun.rotation_degrees.x = -9.0
	root.add_child(gun)
	DesignKit.add(gun, _cylinder(0.14, 1.55), red, Vector3(0.0, 0.0, 0.69), Vector3(90.0, 0.0, 0.0))
	DesignKit.add(gun, _cylinder(0.18, 0.28), alloy, Vector3(0.0, 0.0, 1.52), Vector3(90.0, 0.0, 0.0))
	DesignKit.add(gun, _cylinder(0.115, 0.015), steel, Vector3(0.0, 0.0, 1.67), Vector3(90.0, 0.0, 0.0), false)
	DesignKit.rbox(root, Vector3(0.16, 0.3, 0.62), Vector3(0.5, 3.95, 1.7), alloy, 0.04)
	# Long stowed ladder and roof service rails underline the low heavy silhouette.
	for x: float in [-0.43, 0.43]:
		DesignKit.rbox(root, Vector3(0.07, 0.1, 4.7), Vector3(x, 3.47, -1.66), alloy, 0.025)
	_ladder_rungs(root, alloy)
	for x: float in [-1.32, 1.32]:
		DesignKit.rbox(root, Vector3(0.05, 0.07, 5.8), Vector3(x, 3.54, -1.42), steel, 0.02)
		for z: float in [-4.12, 1.26]:
			DesignKit.rbox(root, Vector3(0.06, 0.23, 0.06), Vector3(x, 3.43, z), steel, 0.02)
	# Broad rear yellow/red chevrons, large enough to register across the apron.
	DesignKit.rbox(root, Vector3(3.0, 1.35, 0.055), Vector3(0.0, 2.57, -4.725), red, 0.05)
	for side: float in [-1.0, 1.0]:
		for band in 3:
			var chevron: MeshInstance3D = DesignKit.rbox(root, Vector3(1.47, 0.19, 0.04), Vector3(side * 0.7, 2.24 + float(band) * 0.32, -4.768), yellow, 0.018, false)
			chevron.rotation_degrees.z = side * 22.0
	_label(root, "FIRE 06", Vector3(0.0, 2.21, 4.853), 0.0, 0.23, DesignKit.CHARCOAL)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, yaw: float, height: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 96
	label.pixel_size = height / 96.0
	label.outline_size = 0
	label.modulate = ink
	label.position = at
	label.rotation_degrees.y = yaw
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _tyre() -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -0.28), Vector2(0.44, -0.28), Vector2(0.63, -0.25),
		Vector2(0.7, -0.18), Vector2(0.72, -0.1), Vector2(0.72, 0.1),
		Vector2(0.7, 0.18), Vector2(0.63, 0.25), Vector2(0.44, 0.28), Vector2(0.0, 0.28)
	]), 32)


static func _hub() -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -0.05), Vector2(0.36, -0.05), Vector2(0.4, -0.01),
		Vector2(0.4, 0.025), Vector2(0.3, 0.025), Vector2(0.26, -0.025),
		Vector2(0.16, -0.025), Vector2(0.14, 0.07), Vector2(0.0, 0.07)
	]), 24)


static func _beacon() -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.17, 0.0), Vector2(0.17, 0.16),
		Vector2(0.14, 0.22), Vector2(0.08, 0.25), Vector2(0.0, 0.25)
	]), 20)


static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var key: String = "cylinder:%0.3f:%0.3f" % [radius, height]
	if _meshes.has(key):
		return _meshes[key] as CylinderMesh
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	_meshes[key] = mesh
	return mesh


static func _shutter_ribs(parent: Node3D, side: float, material: Material) -> void:
	var transforms: Array[Transform3D] = []
	for index in 10:
		transforms.append(Transform3D(Basis.IDENTITY, Vector3(side * 1.705, 2.12 + float(index) * 0.1, -3.97)))
	_instances(parent, DesignKit.rounded_box(Vector3(0.022, 0.02, 0.96), 0.007), material, transforms)


static func _ladder_rungs(parent: Node3D, material: Material) -> void:
	var transforms: Array[Transform3D] = []
	for index in 12:
		transforms.append(Transform3D(Basis.IDENTITY, Vector3(0.0, 3.47, -3.8 + float(index) * 0.39)))
	_instances(parent, DesignKit.rounded_box(Vector3(0.85, 0.065, 0.065), 0.02), material, transforms)


static func _instances(parent: Node3D, mesh: Mesh, material: Material, transforms: Array[Transform3D]) -> void:
	var batch: MultiMesh = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = transforms.size()
	for index in transforms.size():
		batch.set_instance_transform(index, transforms[index])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.multimesh = batch
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
