extends RefCounted
## Five-metre feature stair: 30 equal rises, two flights, open oak treads.
## Entrance faces +Z; the upper landing is ready to meet a terminal mezzanine.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "FeatureStairs"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var v: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[v]
	var oak_tint: Color = DesignKit.OAK.lightened(float(v) * 0.025)
	var oak: Material = DesignKit.wood(oak_tint, "stairs_oak_%d" % v)
	var walnut: Material = DesignKit.wood(DesignKit.WALNUT, "stairs_walnut")
	var steel: Material = DesignKit.metal()
	var brass: Material = DesignKit.brass()
	var stone: Material = DesignKit.stone()
	var glow: Material = DesignKit.washi(DesignKit.CREAM, 1.3, "stairs_nosing")
	var glass: Material = _glass(v)
	var treads: Array[Transform3D] = []
	var saddles: Array[Transform3D] = []
	var nosings: Array[Transform3D] = []
	var lights: Array[Transform3D] = []
	var clamps: Array[Transform3D] = []
	var bolts: Array[Transform3D] = []
	var rise: float = 5.0 / 30.0
	for flight in 2:
		var base_y: float = float(flight) * 2.5
		var front_z: float = 5.4 if flight == 0 else -0.3
		for i in 14:
			var top_y: float = base_y + float(i + 1) * rise
			var z: float = front_z - float(i) * 0.3 - 0.15
			treads.append(Transform3D(Basis.IDENTITY, Vector3(0.0, top_y - 0.055, z)))
			saddles.append(Transform3D(Basis.IDENTITY, Vector3(0.0, top_y - 0.13, z)))
			nosings.append(Transform3D(Basis.IDENTITY, Vector3(0.0, top_y - 0.008, z + 0.13)))
			lights.append(Transform3D(Basis.IDENTITY, Vector3(0.0, top_y - 0.098, z + 0.132)))
			for side: float in [-1.0, 1.0]:
				clamps.append(Transform3D(Basis.IDENTITY, Vector3(side * 1.43, top_y + 0.08, z)))
				bolts.append(Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(side * 1.468, top_y + 0.08, z)))
		# A single central box-section spine carries welded transverse tread saddles.
		_beam(root, Vector3(0.0, base_y + 0.08, front_z - 0.4), Vector3(0.0, base_y + 2.16, front_z - 4.2), 0.32, 0.3, steel)
		if flight == 1:
			DesignKit.rbox(root, Vector3(0.32, 0.15, 0.6), Vector3(0.0, base_y - 0.03, front_z - 0.2), steel, 0.025)
		for side: float in [-1.0, 1.0]:
			# Three separate laminated-glass panels with a visible expansion joint.
			for section in 3:
				var z: float = front_z - float(section) * 1.4
				var y: float = base_y + float(section) * (2.5 / 3.0)
				DesignKit.add(root, _guard_mesh(1.386, 1.386 * 2.5 / 4.2), glass, Vector3(side * 1.44, y + 0.12, z - 0.007), Vector3.ZERO, false)
			_beam(root, Vector3(side * 1.44, base_y + 1.2, front_z), Vector3(side * 1.44, base_y + 3.7, front_z - 4.2), 0.07, 0.06, oak)
			# Lower channel follows the glass line and gives its edge a clear silhouette.
			_beam(root, Vector3(side * 1.44, base_y + 0.13, front_z), Vector3(side * 1.44, base_y + 2.63, front_z - 4.2), 0.032, 0.04, steel)
	_batch(root, "OakTreads", DesignKit.rounded_box(Vector3(2.8, 0.11, 0.34), 0.028), oak, treads)
	_batch(root, "WeldedSaddles", DesignKit.rounded_box(Vector3(2.65, 0.055, 0.21), 0.012), steel, saddles)
	_batch(root, "BrassGripNosings", DesignKit.rounded_box(Vector3(2.68, 0.016, 0.032), 0.005), brass, nosings, false)
	_batch(root, "WarmUndertreadLight", DesignKit.rounded_box(Vector3(2.36, 0.018, 0.018), 0.006), glow, lights, false)
	_batch(root, "GlassClamps", DesignKit.rounded_box(Vector3(0.064, 0.14, 0.09), 0.012), steel, clamps, false)
	var bolt_mesh: Mesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.017, 0.0), Vector2(0.019, 0.004), Vector2(0.019, 0.01), Vector2(0.014, 0.014), Vector2(0.0, 0.014)]), 12)
	_batch(root, "ClampFasteners", bolt_mesh, brass, bolts, false)
	# Limestone anchor shoe is exactly on the floor; all geometry builds upward.
	DesignKit.rbox(root, Vector3(0.7, 0.1, 0.66), Vector3(0.0, 0.05, 5.16), stone, 0.04)
	for landing in 2:
		var y: float = 2.5 * float(landing + 1)
		var length: float = 1.5 if landing == 0 else 1.2
		var z: float = 0.45 if landing == 0 else -5.1
		DesignKit.rbox(root, Vector3(2.8, 0.16, length), Vector3(0.0, y - 0.08, z), oak, 0.035)
		DesignKit.rbox(root, Vector3(2.65, 0.12, length - 0.08), Vector3(0.0, y - 0.22, z), steel, 0.025)
		# Slim structural pier and a limestone plinth under each landing.
		DesignKit.rbox(root, Vector3(0.46, y - 0.35, 0.4), Vector3(0.0, (y - 0.35) * 0.5 + 0.1, z), steel, 0.035)
		DesignKit.rbox(root, Vector3(0.78, 0.1, 0.72), Vector3(0.0, 0.05, z), stone, 0.04)
		for side: float in [-1.0, 1.0]:
			DesignKit.rbox(root, Vector3(0.025, 1.05, length - 0.024), Vector3(side * 1.44, y + 0.645, z), glass, 0.01, false)
			DesignKit.rbox(root, Vector3(0.07, 0.06, length + 0.025), Vector3(side * 1.44, y + 1.2, z), oak, 0.028)
			DesignKit.rbox(root, Vector3(0.032, 0.04, length), Vector3(side * 1.44, y + 0.13, z), steel, 0.01)
			for end: float in [-1.0, 1.0]:
				DesignKit.rbox(root, Vector3(0.065, 0.16, 0.1), Vector3(side * 1.44, y + 0.09, z + end * (length * 0.5 - 0.1)), brass, 0.012, false)
		# Walnut seams divide the landing into three crafted boards.
		for seam: float in [-0.47, 0.47]:
			DesignKit.rbox(root, Vector3(0.008, 0.006, length - 0.08), Vector3(seam, y + 0.001, z), walnut, 0.002, false)
	_wayfinding(root, accent, walnut, v)
	return root


static func _beam(parent: Node3D, start: Vector3, finish: Vector3, width: float, depth: float, material: Material) -> void:
	var direction: Vector3 = finish - start
	var mesh: Mesh = DesignKit.rounded_box(Vector3(width, direction.length(), depth), minf(width, depth) * 0.2)
	var node: MeshInstance3D = DesignKit.add(parent, mesh, material, (start + finish) * 0.5)
	var axis_y: Vector3 = direction.normalized()
	var axis_x: Vector3 = Vector3.RIGHT
	node.basis = Basis(axis_x, axis_y, axis_x.cross(axis_y).normalized())


static func _batch(parent: Node3D, title: String, mesh: Mesh, material: Material, placements: Array[Transform3D], shadows: bool = true) -> void:
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = placements.size()
	for i in placements.size():
		instances.set_instance_transform(i, placements[i])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = instances
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)


static func _glass(variant: int) -> StandardMaterial3D:
	var key: String = "glass_%d" % variant
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.77 + float(variant) * 0.02, 0.9, 0.87, 0.2)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.12
	material.metallic = 0.05
	_materials[key] = material
	return material


static func _guard_mesh(length: float, rise: float) -> ArrayMesh:
	var key: String = "guard:%f:%f" % [length, rise]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	# Solid thin parallelogram: vertical joints, continuous sloping top and bottom.
	var vertices: PackedVector3Array = PackedVector3Array()
	for x: float in [-0.012, 0.012]:
		vertices.append_array(PackedVector3Array([Vector3(x, 0.0, 0.0), Vector3(x, rise, -length), Vector3(x, rise + 1.05, -length), Vector3(x, 1.05, 0.0)]))
	var faces: Array[PackedInt32Array] = [PackedInt32Array([0, 1, 2, 3]), PackedInt32Array([7, 6, 5, 4]), PackedInt32Array([0, 4, 5, 1]), PackedInt32Array([3, 2, 6, 7]), PackedInt32Array([0, 3, 7, 4]), PackedInt32Array([1, 5, 6, 2])]
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: PackedInt32Array in faces:
		for index: int in [face[0], face[1], face[2], face[0], face[2], face[3]]:
			surface.add_vertex(vertices[index])
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _wayfinding(parent: Node3D, accent: Color, walnut: Material, variant: int) -> void:
	# Freestanding six-language sign alongside the entrance, clear of the stair.
	var centre: Vector3 = Vector3(-3.65, 2.15, 4.7)
	DesignKit.rbox(parent, Vector3(3.65, 2.5, 0.14), centre, walnut, 0.07)
	DesignKit.rbox(parent, Vector3(3.5, 2.35, 0.025), centre + Vector3(0.0, 0.0, 0.077), DesignKit.paint(DesignKit.CHARCOAL), 0.05)
	DesignKit.rbox(parent, Vector3(3.25, 0.03, 0.016), centre + Vector3(0.0, 1.08, 0.097), DesignKit.paint(accent), 0.01, false)
	for x: float in [-4.8, -2.5]:
		DesignKit.rbox(parent, Vector3(0.07, 1.1, 0.07), Vector3(x, 0.55, 4.7), DesignKit.metal(), 0.02)
		DesignKit.rbox(parent, Vector3(0.4, 0.08, 0.6), Vector3(x, 0.04, 4.7), DesignKit.stone(), 0.03)
	var keys: Array[String] = ["departures", "gates", "lounge", "departures"]
	var translations: Array = Signage.TEXT[keys[variant]]
	for i in 6:
		var label: Label3D = Label3D.new()
		label.text = str(translations[i])
		label.font = Signage.font()
		label.font_size = 76
		label.pixel_size = 0.004
		label.outline_size = 0
		label.modulate = DesignKit.CREAM if i == 0 else DesignKit.LINEN
		label.position = centre + Vector3(0.0, 0.84 - float(i) * 0.34, 0.1)
		label.double_sided = false
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(label)
