extends RefCounted
## A five-metre rise, entered at +Z. Static display position of the step chain.

const KIT = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "OakGlassEscalator"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [KIT.SAGE, KIT.CLAY, KIT.INDIGO, KIT.OCHRE]
	var accent: Color = accents[choice]
	var oak: StandardMaterial3D = KIT.wood(KIT.OAK.lightened(float(choice) * 0.025), "escalator_oak_%d" % choice)
	var steel: StandardMaterial3D = KIT.metal(Color(0.57, 0.60, 0.60), 0.34, 0.9, "escalator_step_steel")
	var dark: StandardMaterial3D = KIT.metal(KIT.CHARCOAL, 0.42, 0.8, "escalator_structure")
	var rubber: StandardMaterial3D = KIT.paint(Color(0.035, 0.034, 0.031), 0.78)
	var glow: StandardMaterial3D = KIT.washi(KIT.CREAM, 1.4, "escalator_guidance")
	var angle: float = rad_to_deg(atan2(5.0, 8.0))
	var slope_length: float = Vector2(8.0, 5.0).length()
	# The visible truss is suspended between the lower pit and upper-floor landing.
	KIT.add(root, KIT.rounded_box(Vector3(1.46, 0.36, slope_length), 0.08), dark, Vector3(0.0, 2.57, 0.0), Vector3(angle, 0.0, 0.0))
	for side: float in [-1.0, 1.0]:
		var x: float = side * 0.83
		# Separate oak cassettes leave black expansion joints between panels.
		for panel_index in 8:
			var z: float = 3.5 - float(panel_index)
			var y: float = 0.30 + (4.0 - z) * 0.625
			KIT.add(root, KIT.rounded_box(Vector3(0.20, 0.42, slope_length / 8.0 - 0.018), 0.025), oak, Vector3(x, y, z), Vector3(angle, 0.0, 0.0))
		_beam(root, Vector3(x, 0.48, 3.85), Vector3(x, 5.29, -3.85), 0.035, 0.035, KIT.brass())
		_beam(root, Vector3(side * 0.69, 0.39, 3.85), Vector3(side * 0.69, 5.20, -3.85), 0.022, 0.027, glow)
		# Four laminated glass panes with vertical end seams, not tilted box slabs.
		for pane_index in 4:
			var z: float = 3.0 - float(pane_index) * 2.0
			var y: float = 0.08 + (4.0 - z) * 0.625
			KIT.add(root, _glass_pane(), _glass(), Vector3(side * 0.73, y, z), Vector3.ZERO, false)
		for joint in 5:
			var z: float = 4.0 - float(joint) * 2.0
			var y: float = 0.08 + (4.0 - z) * 0.625
			KIT.rbox(root, Vector3(0.075, 0.16, 0.09), Vector3(side * 0.73, y + 0.28, z), steel, 0.015)
		KIT.add(root, _handrail(), rubber, Vector3(side * 0.73, 0.0, 0.0))
		for end in 2:
			var z: float = 4.3 if end == 0 else -4.3
			var floor_y: float = 0.0 if end == 0 else 5.0
			KIT.rbox(root, Vector3(0.35, 0.36, 1.35), Vector3(x, floor_y + 0.18, z), oak, 0.10)
			KIT.rbox(root, Vector3(0.25, 0.055, 1.12), Vector3(x, floor_y + 0.37, z), steel, 0.025)
			KIT.rbox(root, Vector3(0.045, 0.045, 0.30), Vector3(side * 0.66, floor_y + 0.28, z), KIT.washi(accent.lightened(0.25), 1.7, "escalator_status_%d" % choice), 0.018, false)
	# A single instanced, deeply ribbed tread/riser mesh keeps the step chain inexpensive.
	var steps: Array[Transform3D] = []
	var noses: Array[Transform3D] = []
	for step in 25:
		var z: float = 3.84 - float(step) * 0.32
		var y: float = 0.08 + float(step) * 0.20
		steps.append(Transform3D(Basis.IDENTITY, Vector3(0.0, y, z)))
		noses.append(Transform3D(Basis.IDENTITY, Vector3(0.0, y + 0.204, z + 0.147)))
	_instances(root, _step_mesh(), steel, steps, "RibbedSteelSteps")
	_instances(root, KIT.rounded_box(Vector3(1.24, 0.012, 0.022), 0.004), KIT.brass(), noses, "StepSafetyEdges")
	for end in 2:
		var y: float = 0.08 if end == 0 else 5.08
		var z: float = 4.50 if end == 0 else -4.50
		KIT.rbox(root, Vector3(1.40, 0.08, 1.02), Vector3(0.0, y - 0.04, z), KIT.stone(KIT.LIMESTONE, 0.48, "escalator_sill"), 0.035)
		KIT.rbox(root, Vector3(1.26, 0.018, 0.82), Vector3(0.0, y + 0.009, z), steel, 0.008)
		var combs: Array[Transform3D] = []
		for rib in 35:
			combs.append(Transform3D(Basis.IDENTITY, Vector3(-0.595 + float(rib) * 0.035, y + 0.023, z)))
		_instances(root, KIT.rounded_box(Vector3(0.009, 0.010, 0.79), 0.003), dark, combs, "LandingGrooves")
		KIT.rbox(root, Vector3(1.27, 0.015, 0.065), Vector3(0.0, y + 0.02, z + (-0.45 if end == 0 else 0.45)), KIT.brass(), 0.005)
	_wayfinding(root, accent, choice)
	return root


static func _beam(parent: Node3D, start: Vector3, finish: Vector3, width: float, depth: float, material: Material) -> void:
	var delta: Vector3 = finish - start
	var mesh: ArrayMesh = KIT.rounded_box(Vector3(width, depth, delta.length()), minf(width, depth) * 0.35)
	KIT.add(parent, mesh, material, (start + finish) * 0.5, Vector3(rad_to_deg(atan2(-delta.y, delta.z)), 0.0, 0.0))


static func _instances(parent: Node3D, mesh: Mesh, material: Material, transforms: Array[Transform3D], title: String) -> void:
	var multi: MultiMesh = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for index in transforms.size():
		multi.set_instance_transform(index, transforms[index])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = multi
	node.material_override = material
	parent.add_child(node)


static func _step_mesh() -> ArrayMesh:
	if _meshes.has("step"):
		return _meshes["step"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.append_from(KIT.rounded_box(Vector3(1.24, 0.045, 0.32), 0.009), 0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.173, 0.0)))
	surface.append_from(KIT.rounded_box(Vector3(1.24, 0.174, 0.03), 0.006), 0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.087, 0.145)))
	var tread_rib: ArrayMesh = KIT.rounded_box(Vector3(0.016, 0.013, 0.292), 0.004, 2)
	var riser_rib: ArrayMesh = KIT.rounded_box(Vector3(0.016, 0.158, 0.010), 0.003, 2)
	for rib in 35:
		var x: float = -0.595 + float(rib) * 0.035
		surface.append_from(tread_rib, 0, Transform3D(Basis.IDENTITY, Vector3(x, 0.202, -0.004)))
		surface.append_from(riser_rib, 0, Transform3D(Basis.IDENTITY, Vector3(x, 0.088, 0.164)))
	var mesh: ArrayMesh = surface.commit()
	_meshes["step"] = mesh
	return mesh


static func _glass() -> StandardMaterial3D:
	if _materials.has("glass"):
		return _materials["glass"] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.73, 0.87, 0.83, 0.22)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.10
	_materials["glass"] = material
	return material


static func _glass_pane() -> ArrayMesh:
	if _meshes.has("glass"):
		return _meshes["glass"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile: PackedVector2Array = PackedVector2Array([
		Vector2(-0.994, 0.811), Vector2(0.994, -0.431),
		Vector2(0.994, 0.265), Vector2(-0.994, 1.507)])
	var vertices: PackedVector3Array = PackedVector3Array()
	for x: float in [-0.017, 0.017]:
		for point: Vector2 in profile:
			vertices.append(Vector3(x, point.y, point.x))
	var indices: PackedInt32Array = PackedInt32Array([0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7,
		0, 1, 5, 0, 5, 4, 1, 2, 6, 1, 6, 5, 2, 3, 7, 2, 7, 6, 3, 0, 4, 3, 4, 7])
	for triangle in indices.size() / 3:
		var offset: int = triangle * 3
		surface.add_vertex(vertices[indices[offset]])
		surface.add_vertex(vertices[indices[offset + 2]])
		surface.add_vertex(vertices[indices[offset + 1]])
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes["glass"] = mesh
	return mesh


static func _handrail() -> ArrayMesh:
	if _meshes.has("handrail"):
		return _meshes["handrail"] as ArrayMesh
	# A continuous closed rubber belt: level ends, softened transitions, half-circle returns.
	var path: PackedVector2Array = PackedVector2Array()
	path.append(Vector2(4.30, 1.10))
	path.append(Vector2(4.0, 1.10))
	path.append(Vector2(3.7, 1.20))
	path.append(Vector2(-3.7, 5.825))
	path.append(Vector2(-4.0, 6.10))
	path.append(Vector2(-4.30, 6.10))
	for index in range(1, 17):
		var angle: float = PI * float(index) / 16.0
		path.append(Vector2(-4.30 - 0.43 * sin(angle), 5.67 + 0.43 * cos(angle)))
	path.append(Vector2(-4.0, 5.24))
	path.append(Vector2(-3.7, 4.965))
	path.append(Vector2(3.7, 0.34))
	path.append(Vector2(4.0, 0.24))
	path.append(Vector2(4.30, 0.24))
	for index in range(1, 16):
		var angle: float = PI * float(index) / 16.0
		path.append(Vector2(4.30 + 0.43 * sin(angle), 0.67 - 0.43 * cos(angle)))
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for index in path.size():
		var tangent: Vector2 = (path[(index + 1) % path.size()] - path[posmod(index - 1, path.size())]).normalized()
		var normal: Vector2 = Vector2(-tangent.y, tangent.x)
		var ring: PackedVector3Array = PackedVector3Array()
		for radial in 12:
			var angle: float = TAU * float(radial) / 12.0
			var p: Vector2 = path[index] + normal * sin(angle) * 0.035
			ring.append(Vector3(cos(angle) * 0.065, p.y, p.x))
		rings.append(ring)
	for index in path.size():
		var ring: PackedVector3Array = rings[index]
		var next_ring: PackedVector3Array = rings[(index + 1) % path.size()]
		for radial in 12:
			var next_radial: int = (radial + 1) % 12
			for vertex: Vector3 in [ring[radial], next_ring[next_radial], next_ring[radial], ring[radial], ring[next_radial], next_ring[next_radial]]:
				surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes["handrail"] = mesh
	return mesh


static func _wayfinding(parent: Node3D, accent: Color, choice: int) -> void:
	var center: Vector3 = Vector3(2.65, 2.50, 4.65)
	for x: float in [1.45, 3.85]:
		KIT.rbox(parent, Vector3(0.32, 0.10, 0.48), Vector3(x, 0.05, 4.65), KIT.stone(), 0.04)
		KIT.rbox(parent, Vector3(0.06, 2.50, 0.06), Vector3(x, 1.30, 4.65), KIT.metal(), 0.02)
	KIT.rbox(parent, Vector3(3.35, 1.98, 0.15), center, KIT.wood(KIT.WALNUT, "escalator_sign_walnut"), 0.075)
	KIT.rbox(parent, Vector3(3.23, 1.86, 0.035), center + Vector3(0.0, 0.0, 0.085), KIT.paint(KIT.CHARCOAL), 0.045)
	KIT.rbox(parent, Vector3(3.05, 0.035, 0.015), center + Vector3(0.0, 0.82, 0.11), KIT.brass(), 0.009)
	var text: Array = SIGNS.TEXT["departures"]
	var captions: Array[String] = ["↑  " + str(text[0]), "%s　%s" % [text[1], text[2]], str(text[3]), "%s · %s" % [text[4], text[5]]]
	for line in captions.size():
		var label: Label3D = Label3D.new()
		label.font = SIGNS.font()
		label.text = captions[line]
		label.font_size = 88 if line == 0 else 74
		label.pixel_size = 0.0035
		label.outline_size = 0
		label.modulate = KIT.CREAM if line == 0 else accent.lightened(0.5)
		label.position = center + Vector3(0.0, 0.51 - float(line) * 0.36, 0.11)
		label.double_sided = false
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(label)
	# A broad accent inset distinguishes terminal zones without tiny equipment labels.
	KIT.rbox(parent, Vector3(0.24 + float(choice) * 0.025, 0.08, 0.025), center + Vector3(0.0, -0.80, 0.11), KIT.paint(accent), 0.015)
