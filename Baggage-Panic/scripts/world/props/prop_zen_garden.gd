extends RefCounted
## A shallow karesansui tray: actual raked relief, three stones and living moss.
## All bespoke resources are shared; no per-instance scripts or animation.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ZenGarden"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK.lightened(float(style) * 0.025), "zen_oak_%d" % style)
	var steel: StandardMaterial3D = DesignKit.metal()
	var stone: StandardMaterial3D = DesignKit.stone(DesignKit.LIMESTONE, 0.85, "zen_plinth")
	# Recessed stone foot and a dark reveal beneath the oak tray.
	DesignKit.rbox(root, Vector3(5.86, 0.10, 2.86), Vector3(0.0, 0.05, 0.0), stone, 0.045)
	DesignKit.rbox(root, Vector3(5.92, 0.04, 2.92), Vector3(0.0, 0.12, 0.0), steel, 0.018)
	# End-grain corner blocks let the rails meet without overlapping rounded ends.
	for z: float in [-1.41, 1.41]:
		DesignKit.rbox(root, Vector3(5.64, 0.15, 0.18), Vector3(0.0, 0.205, z), oak, 0.028)
	for x: float in [-2.91, 2.91]:
		DesignKit.rbox(root, Vector3(0.18, 0.15, 2.64), Vector3(x, 0.205, 0.0), oak, 0.028)
		for z: float in [-1.41, 1.41]:
			DesignKit.rbox(root, Vector3(0.18, 0.15, 0.18), Vector3(x, 0.205, z), oak, 0.025)
			# A visible walnut spline on each crafted corner joint.
			DesignKit.rbox(root, Vector3(0.12, 0.009, 0.024), Vector3(x, 0.281, z), DesignKit.wood(DesignKit.WALNUT), 0.004, false)
	var gravel: MeshInstance3D = DesignKit.add(root, _gravel_mesh(style), _surface("gravel", style), Vector3.ZERO)
	gravel.name = "RakedGravel"
	var sites: PackedVector2Array = _sites(style)
	var sizes: Array[Vector3] = [Vector3(0.72, 1.12, 0.56), Vector3(0.87, 0.61, 0.65), Vector3(0.65, 0.37, 0.48)]
	for i: int in 3:
		var site: Vector2 = sites[i]
		var size: Vector3 = sizes[i]
		var island: MeshInstance3D = DesignKit.add(root, _moss_mesh(i), _surface("moss", style), Vector3(site.x, 0.211, site.y))
		island.name = "MossIsland%d" % i
		island.scale = Vector3(size.x * 1.48, 1.0, size.z * 1.65)
		island.rotation_degrees.y = float(style * 13 + i * 28)
		var rock: MeshInstance3D = DesignKit.add(root, _rock_mesh(i), _surface("rock", style), Vector3(site.x, 0.238, site.y))
		rock.name = "WeatheredStone%d" % i
		rock.scale = size
		rock.rotation_degrees.y = float(i * 43 + style * 17)
	# A restrained airport garden marker at the rear, facing the public aisle (+Z).
	for x: float in [-1.92, 1.92]:
		DesignKit.rbox(root, Vector3(0.055, 1.20, 0.055), Vector3(x, 0.74, -1.34), steel, 0.012)
	DesignKit.rbox(root, Vector3(4.44, 0.96, 0.10), Vector3(0.0, 1.18, -1.34), oak, 0.055)
	DesignKit.rbox(root, Vector3(4.30, 0.82, 0.025), Vector3(0.0, 1.18, -1.277), DesignKit.washi(DesignKit.CREAM, 0.18, "zen_marker"), 0.032, false)
	DesignKit.rbox(root, Vector3(4.02, 0.013, 0.012), Vector3(0.0, 1.49, -1.256), DesignKit.brass(), 0.004, false)
	_caption(root, "Quiet garden · 枯山水", Vector3(0.0, 1.37, -1.252), 100)
	_caption(root, "静心花园 · Vườn thiền", Vector3(0.0, 1.12, -1.252), 86)
	_caption(root, "Jardin zen · Jardín zen", Vector3(0.0, 0.88, -1.252), 86)
	return root


static func _caption(parent: Node3D, caption: String, at: Vector3, size: int) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = 0.0027
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _sites(style: int) -> PackedVector2Array:
	var shift: float = float(style - 1) * 0.09
	return PackedVector2Array([Vector2(-1.12 + shift, -0.15), Vector2(0.58, 0.21 + shift), Vector2(1.80 - shift, -0.39)])


static func _surface(kind: String, style: int) -> StandardMaterial3D:
	var key: String = "%s:%d" % [kind, style]
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var tint: Color = DesignKit.LIMESTONE.lightened(0.05)
	if kind == "rock":
		tint = Color(0.39 + float(style) * 0.025, 0.40, 0.37)
	elif kind == "moss":
		tint = Color(0.31, 0.39 + float(style) * 0.023, 0.20)
	else:
		tint = tint.darkened(float(style) * 0.02)
	var material: StandardMaterial3D = DesignKit.stone(tint, 0.96, "zen_" + key).duplicate() as StandardMaterial3D
	material.vertex_color_use_as_albedo = true
	material.normal_scale = 0.42 if kind == "rock" else 0.26
	_materials[key] = material
	return material


static func _gravel_mesh(style: int) -> ArrayMesh:
	var key: String = "rake:%d" % style
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx: int = 240
	var nz: int = 112
	var center: Vector2 = _sites(style)[0]
	for j: int in nz + 1:
		for i: int in nx + 1:
			var x: float = -2.825 + 5.65 * float(i) / float(nx)
			var z: float = -1.325 + 2.65 * float(j) / float(nz)
			var distance: float = Vector2((x - center.x) * 0.86, z - center.y).length()
			var blend: float = 1.0 - smoothstep(0.85, 1.65, distance)
			var straight: float = sin((z + 0.09 * sin(x * 1.4 + float(style))) * TAU / 0.155)
			var rings: float = sin(distance * TAU / 0.155)
			var ridge: float = lerpf(straight, rings, blend)
			var height: float = 0.213 + ridge * 0.011
			var tooth: float = 0.96 + 0.04 * sin(x * 139.0 + z * 171.0)
			st.set_color(Color(tooth, tooth, tooth))
			st.set_uv(Vector2(x, z))
			st.add_vertex(Vector3(x, height, z))
	for j: int in nz:
		for i: int in nx:
			var a: int = j * (nx + 1) + i
			# Clockwise from above: Godot's front face convention.
			for index: int in [a, a + 1, a + nx + 2, a, a + nx + 2, a + nx + 1]:
				st.add_index(index)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _rock_mesh(seed_value: int) -> ArrayMesh:
	var key: String = "rock:%d" % seed_value
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.69, 0.0), Vector2(0.93, 0.07), Vector2(1.0, 0.28), Vector2(0.88, 0.54), Vector2(0.68, 0.78), Vector2(0.39, 0.94), Vector2(0.0, 1.0)])
	var segments: int = 22
	for ring: int in profile.size():
		var p: Vector2 = profile[ring]
		for s: int in segments + 1:
			var angle: float = TAU * float(s) / float(segments)
			var phase: float = float(seed_value) * 1.9
			var irregularity: float = 1.0 + 0.12 * sin(angle * 3.0 + phase + p.y * 2.0) + 0.07 * cos(angle * 7.0 - p.y * 3.0)
			var radius: float = p.x * irregularity
			var y: float = p.y + sin(angle * 4.0 + phase) * 0.035 * sin(p.y * PI)
			var shade: float = 0.83 + 0.15 * sin(angle * 5.0 + p.y * 23.0 + phase)
			st.set_color(Color(shade, shade, shade * 0.98))
			st.add_vertex(Vector3(cos(angle) * radius + p.y * 0.13, y, sin(angle) * radius))
	for ring: int in profile.size() - 1:
		for s: int in segments:
			var a: int = ring * (segments + 1) + s
			var b: int = a + segments + 1
			for index: int in [a, a + 1, b, a + 1, b + 1, b]:
				st.add_index(index)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _moss_mesh(seed_value: int) -> ArrayMesh:
	var key: String = "moss:%d" % seed_value
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = 48
	var rings: int = 6
	for ring: int in rings + 1:
		var fraction: float = float(ring) / float(rings)
		for s: int in segments + 1:
			var angle: float = TAU * float(s) / float(segments)
			var phase: float = float(seed_value) * 2.1
			var radius: float = fraction * (0.76 + 0.085 * sin(angle * 3.0 + phase) + 0.055 * cos(angle * 5.0))
			var y: float = 0.004 + 0.073 * pow(1.0 - fraction * fraction, 1.5)
			var shade: float = 0.86 + 0.12 * sin(angle * 9.0 + fraction * 20.0 + phase)
			st.set_color(Color(shade, shade, shade))
			st.add_vertex(Vector3(cos(angle) * radius, y, sin(angle) * radius))
	for ring: int in rings:
		for s: int in segments:
			var a: int = ring * (segments + 1) + s
			var b: int = a + segments + 1
			for index: int in [a, b, a + 1, a + 1, b, b + 1]:
				st.add_index(index)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh
