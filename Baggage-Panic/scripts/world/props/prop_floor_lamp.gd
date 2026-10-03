extends RefCounted
## A quiet akari lantern: pleated washi, bamboo binding and a steel tripod.

const Kit = preload("res://scripts/world/design_kit.gd")

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "WashiFloorLamp"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var steel: StandardMaterial3D = Kit.metal(Kit.CHARCOAL, 0.48, 0.85, "floor_lamp_steel")
	var timber: StandardMaterial3D = Kit.wood(Kit.OAK if style % 2 == 0 else Kit.WALNUT, "lamp_oak" if style % 2 == 0 else "lamp_walnut")
	var rubber: StandardMaterial3D = Kit.paint(Color(0.075, 0.07, 0.065), 0.95)
	var rib: StandardMaterial3D = Kit.paint(Color(0.61, 0.49, 0.33), 0.86)
	var width: float = 1.0 + float(style % 2) * 0.07

	# Three splayed tubes meet beneath the lantern; rounded pads touch the floor.
	for leg in 3:
		var angle: float = TAU * float(leg) / 3.0 + PI * 0.5
		var foot: Vector3 = Vector3(cos(angle) * 0.30, 0.025, sin(angle) * 0.30)
		var shoulder: Vector3 = Vector3(cos(angle) * 0.032, 0.96, sin(angle) * 0.032)
		_rod(root, foot, shoulder, 0.012, steel)
		Kit.rbox(root, Vector3(0.055, 0.024, 0.055), Vector3(foot.x, 0.012, foot.z), rubber, 0.011)
		_rod(root, foot.lerp(shoulder, 0.28), Vector3(0.0, 0.39, 0.0), 0.004, steel)
	_rod(root, Vector3(0.0, 0.39, 0.0), Vector3(0.0, 1.03, 0.0), 0.011, steel)
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.91), Vector2(0.043, 0.91), Vector2(0.048, 0.918),
		Vector2(0.048, 0.95), Vector2(0.043, 0.96), Vector2(0.0, 0.96)
	]), 32), Kit.brass(), Vector3.ZERO)

	# One continuous pleated shell and one combined mesh for all bamboo hoops.
	Kit.add(root, _shade_mesh(style, width, false), _paper(style), Vector3.ZERO, Vector3.ZERO, false)
	Kit.add(root, _shade_mesh(style, width, true), rib, Vector3.ZERO, Vector3.ZERO, false)
	for top: bool in [false, true]:
		var height: float = 1.765 if top else 0.945
		var radius: float = _radius(1.0 if top else 0.0, width)
		Kit.add(root, Kit.lathe(PackedVector2Array([
			Vector2(radius - 0.015, height - 0.009), Vector2(radius + 0.003, height - 0.009),
			Vector2(radius + 0.007, height - 0.004), Vector2(radius + 0.007, height + 0.005),
			Vector2(radius + 0.002, height + 0.011), Vector2(radius - 0.015, height + 0.011),
			Vector2(radius - 0.015, height - 0.009)
		]), 48), timber, Vector3.ZERO)
	# Top bridge and a small turned finial; the mouth of the shade remains open.
	Kit.rbox(root, Vector3(0.205 * width, 0.012, 0.015), Vector3(0.0, 1.769, 0.0), steel, 0.005)
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 1.775), Vector2(0.012, 1.775), Vector2(0.018, 1.782),
		Vector2(0.016, 1.793), Vector2(0.008, 1.8), Vector2(0.0, 1.8)
	]), 24), timber, Vector3.ZERO)

	# Rear cable follows a leg into a low, tactile foot switch within the footprint.
	_rod(root, Vector3(0.014, 0.915, -0.035), Vector3(0.018, 0.038, -0.245), 0.0035, rubber)
	_rod(root, Vector3(0.018, 0.038, -0.245), Vector3(0.12, 0.019, -0.18), 0.0035, rubber)
	Kit.rbox(root, Vector3(0.09, 0.035, 0.065), Vector3(0.12, 0.0175, -0.18), steel, 0.016)
	var accent: Color = Kit.SAGE if style < 2 else Kit.CLAY
	Kit.rbox(root, Vector3(0.057, 0.009, 0.041), Vector3(0.12, 0.038, -0.18), Kit.paint(accent), 0.004)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "WarmPaperGlow"
	glow.position = Vector3(0.0, 1.32, 0.0)
	glow.light_color = Color(1.0, 0.81 + float(style) * 0.025, 0.60 + float(style) * 0.04)
	glow.light_energy = 0.42
	glow.omni_range = 2.4
	glow.shadow_enabled = false
	root.add_child(glow)
	return root


static func _radius(t: float, width: float) -> float:
	return width * (lerpf(0.115, 0.10, t) + 0.165 * pow(sin(PI * t), 0.78))


static func _shade_mesh(style: int, width: float, hoops: bool) -> ArrayMesh:
	var key: String = "%d:%s" % [style, hoops]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var mesh: ArrayMesh
	if hoops:
		var surface: SurfaceTool = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for ring in range(1, 24):
			var t: float = float(ring) / 24.0
			var radius: float = _radius(t, width) + 0.0015
			var y: float = 0.945 + t * 0.82
			var profile: PackedVector2Array = PackedVector2Array()
			for point in 9:
				var angle: float = TAU * float(point) / 8.0
				profile.append(Vector2(radius + cos(angle) * 0.0024, y + sin(angle) * 0.0024))
			surface.append_from(Kit.lathe(profile, 48), 0, Transform3D.IDENTITY)
		mesh = surface.commit()
	else:
		var profile: PackedVector2Array = PackedVector2Array()
		for step in 145:
			var t: float = float(step) / 144.0
			var pleat: float = 0.0018 * sin(t * TAU * 24.0)
			profile.append(Vector2(_radius(t, width) + pleat, 0.945 + t * 0.82))
		mesh = Kit.lathe(profile, 64)
	_meshes[key] = mesh
	return mesh


static func _paper(style: int) -> StandardMaterial3D:
	var key: String = "paper:%d" % style
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var tint: Color = Color(1.0, 0.88 + float(style) * 0.018, 0.72 + float(style) * 0.04)
	var paper: StandardMaterial3D = Kit.washi(tint, 0.65, "floor_lamp_%d" % style).duplicate() as StandardMaterial3D
	# Fine paper tooth borrows the kit's plaster normal, with a softer response.
	var tooth: StandardMaterial3D = Kit.stone(Kit.PLASTER, 0.9, "floor_lamp_paper_tooth")
	paper.normal_enabled = true
	paper.normal_texture = tooth.normal_texture
	paper.normal_scale = 0.09
	paper.uv1_triplanar = true
	paper.uv1_scale = Vector3(3.0, 3.0, 3.0)
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = paper
	return paper


static func _rod(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var length: float = start.distance_to(end)
	var key: String = "rod:%.5f:%.5f" % [radius, length]
	var mesh: ArrayMesh
	if _meshes.has(key):
		mesh = _meshes[key] as ArrayMesh
	else:
		mesh = Kit.lathe(PackedVector2Array([
			Vector2(0.0, -length * 0.5), Vector2(radius * 0.7, -length * 0.5),
			Vector2(radius, -length * 0.5 + radius * 0.3),
			Vector2(radius, length * 0.5 - radius * 0.3),
			Vector2(radius * 0.7, length * 0.5), Vector2(0.0, length * 0.5)
		]), 12)
		_meshes[key] = mesh
	var rod: MeshInstance3D = Kit.add(parent, mesh, material, (start + end) * 0.5)
	rod.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
