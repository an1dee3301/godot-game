extends RefCounted
## A ceiling installation; the origin is the floor datum beneath the central globe.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "LanternFestival"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var timber: Material = DesignKit.wood(DesignKit.WALNUT if choice == 2 else DesignKit.OAK, "festival_walnut" if choice == 2 else "festival_oak")
	var steel: Material = DesignKit.metal()
	var brass: Material = DesignKit.brass()
	var cord: Material = DesignKit.fabric(DesignKit.LINEN, "festival_cord")
	DesignKit.rbox(root, Vector3(8.6, 0.28, 0.32), Vector3(0.0, 8.55, 0.0), timber, 0.065)
	# Rounded steel suspension shoes and oak cross-arms carry the staggered depth rows.
	for x: float in [-3.7, 3.7]:
		DesignKit.rbox(root, Vector3(0.16, 0.42, 0.42), Vector3(x, 8.69, 0.0), steel, 0.035)
		DesignKit.rbox(root, Vector3(0.07, 0.34, 0.07), Vector3(x, 8.98, 0.0), brass, 0.022)
	for x: float in [-2.5, 0.0, 2.5]:
		DesignKit.rbox(root, Vector3(0.18, 0.18, 1.65), Vector3(x, 8.38, 0.0), timber, 0.045)
		DesignKit.rbox(root, Vector3(0.2, 0.035, 1.68), Vector3(x, 8.29, 0.0), brass, 0.012, false)
	# Restrained welcome inscription on an inset walnut fascia, facing the concourse.
	DesignKit.rbox(root, Vector3(6.9, 0.83, 0.12), Vector3(0.0, 8.45, 0.27), DesignKit.wood(DesignKit.WALNUT, "festival_fascia"), 0.07)
	var welcome: Array = Signage.TEXT["welcome"]
	_caption(root, "%s · %s · %s" % [welcome[0], welcome[1], welcome[2]], Vector3(0.0, 8.64, 0.338))
	_caption(root, "%s · %s · %s" % [welcome[3], welcome[4], welcome[5]], Vector3(0.0, 8.28, 0.338))
	var centres: Array[Vector3] = [
		Vector3(-3.45, 6.9, 0.0), Vector3(-2.55, 5.55, 0.63),
		Vector3(-1.72, 7.35, -0.63), Vector3(-0.85, 6.38, 0.0),
		Vector3(0.0, 5.25, 0.63), Vector3(0.86, 7.15, -0.63),
		Vector3(1.73, 6.12, 0.0), Vector3(2.57, 7.38, 0.63),
		Vector3(3.45, 5.78, -0.63),
	]
	var colours: Array[Color] = [DesignKit.CREAM, Color(0.96, 0.74, 0.43), Color(0.87, 0.58, 0.42), Color(0.91, 0.84, 0.64)]
	if choice == 1:
		colours[2] = Color(0.78, 0.82, 0.63)
	elif choice == 2:
		colours[1] = Color(0.89, 0.66, 0.48)
	elif choice == 3:
		colours[3] = Color(0.95, 0.78, 0.67)
	var sizes: Array[float] = [0.52, 0.61, 0.46, 0.59, 0.68, 0.51, 0.64, 0.48, 0.57]
	var collar_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -0.025), Vector2(0.11, -0.025), Vector2(0.13, -0.01),
		Vector2(0.13, 0.025), Vector2(0.11, 0.04), Vector2(0.0, 0.04),
	]), 24)
	for i: int in 9:
		var centre: Vector3 = centres[i]
		var radius: float = sizes[i]
		var tint: Color = colours[(i + choice) % colours.size()]
		var paper: Material = DesignKit.washi(tint, 0.65, "festival_%d_%d" % [choice, i % 4])
		var globe: MeshInstance3D = DesignKit.add(root, _paper_mesh(), paper, centre)
		globe.name = "PaperLantern_%02d" % (i + 1)
		globe.scale = Vector3(radius, radius * 0.96, radius)
		var ribs: MeshInstance3D = DesignKit.add(root, _rib_mesh(), DesignKit.paint(tint.darkened(0.26)), centre, Vector3.ZERO, false)
		ribs.scale = globe.scale
		var top: float = centre.y + radius * 0.96
		var hanging_length: float = 8.28 - top
		DesignKit.rbox(root, Vector3(0.016, hanging_length, 0.016), Vector3(centre.x, top + hanging_length * 0.5, centre.z), cord, 0.006, false)
		DesignKit.add(root, collar_mesh, brass, Vector3(centre.x, top, centre.z), Vector3.ZERO, false)
		DesignKit.add(root, collar_mesh, timber, Vector3(centre.x, centre.y - radius * 0.96, centre.z), Vector3.ZERO, false)
		# Cable routing sits above the cross-arms, never crossing a paper shade.
		if absf(centre.z) > 0.1:
			DesignKit.rbox(root, Vector3(0.024, 0.024, absf(centre.z)), Vector3(centre.x, 8.28, centre.z * 0.5), steel, 0.009, false)
		if choice == 3 and i % 3 == 1:
			DesignKit.rbox(root, Vector3(0.045, 0.28, 0.025), Vector3(centre.x, centre.y - radius * 0.96 - 0.17, centre.z), cord, 0.012, false)
	return root


static func _caption(parent: Node3D, text: String, at: Vector3) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font = Signage.font()
	label.font_size = 72
	label.pixel_size = 0.0033
	label.modulate = DesignKit.CREAM
	label.outline_size = 0
	label.position = at
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _paper_mesh() -> ArrayMesh:
	if _meshes.has("paper"):
		return _meshes["paper"] as ArrayMesh
	var profile: PackedVector2Array = PackedVector2Array()
	for j: int in 49:
		var angle: float = PI * float(j) / 48.0
		# Fine accordion folds between the bamboo hoops catch the warm light.
		var radius: float = sin(angle) * (1.0 + 0.006 * cos(angle * 36.0))
		profile.append(Vector2(radius, -cos(angle)))
	var mesh: ArrayMesh = DesignKit.lathe(profile, 48)
	_meshes["paper"] = mesh
	return mesh


static func _rib_mesh() -> ArrayMesh:
	if _meshes.has("ribs"):
		return _meshes["ribs"] as ArrayMesh
	# All eighteen bamboo hoops share one surface and one visual node per globe.
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j: int in range(1, 19):
		var y: float = -0.95 + float(j) * 0.1
		var radius: float = sqrt(1.0 - y * y) + 0.004
		var profile: PackedVector2Array = PackedVector2Array()
		for k: int in 9:
			var angle: float = TAU * float(k) / 8.0
			profile.append(Vector2(radius + cos(angle) * 0.009, y + sin(angle) * 0.009))
		var hoop: ArrayMesh = DesignKit.lathe(profile, 48)
		surface.append_from(hoop, 0, Transform3D.IDENTITY)
	var mesh: ArrayMesh = surface.commit()
	_meshes["ribs"] = mesh
	return mesh
