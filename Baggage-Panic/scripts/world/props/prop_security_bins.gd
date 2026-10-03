extends RefCounted
## Nested security trays on a crafted oak service trolley; front faces +Z.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "SecurityTrayTrolley"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[style]
	var oak: Material = DesignKit.wood()
	var walnut: Material = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var steel: Material = DesignKit.metal()
	var rubber: Material = DesignKit.paint(Color(0.09, 0.10, 0.10), 0.94)
	var tray_color: Color = Color(0.55, 0.58, 0.57).lerp(Color(0.67, 0.68, 0.65), float(style) * 0.13)
	var plastic: Material = DesignKit.paint(tray_color, 0.48)
	var rim_material: Material = DesignKit.paint(tray_color.lightened(0.14), 0.52)
	var color_band: Material = DesignKit.paint(accent)
	# Two thick softened oak shelves, with a shadow reveal beneath the worktop.
	DesignKit.rbox(root, Vector3(2.06, 0.075, 0.68), Vector3(0.0, 0.7525, 0.0), oak, 0.03)
	DesignKit.rbox(root, Vector3(1.96, 0.035, 0.58), Vector3(0.0, 0.6975, 0.0), walnut, 0.014)
	DesignKit.rbox(root, Vector3(1.98, 0.055, 0.62), Vector3(0.0, 0.2525, 0.0), oak, 0.024)
	for x: float in [-0.91, 0.91]:
		for z: float in [-0.235, 0.235]:
			DesignKit.rbox(root, Vector3(0.065, 0.56, 0.065), Vector3(x, 0.45, z), oak, 0.018)
			DesignKit.rbox(root, Vector3(0.082, 0.09, 0.082), Vector3(x, 0.195, z), steel, 0.012)
			# Turned rubber tyres with recessed metal hubs and offset caster forks.
			var wheel_at: Vector3 = Vector3(x, 0.085, z)
			var tyre: Mesh = DesignKit.lathe(PackedVector2Array([
				Vector2(0.032, -0.026), Vector2(0.072, -0.026),
				Vector2(0.085, -0.015), Vector2(0.085, 0.015),
				Vector2(0.072, 0.026), Vector2(0.032, 0.026)]), 20)
			DesignKit.add(root, tyre, rubber, wheel_at, Vector3(0.0, 0.0, 90.0))
			var hub: Mesh = DesignKit.lathe(PackedVector2Array([
				Vector2(0.0, -0.027), Vector2(0.035, -0.027),
				Vector2(0.035, 0.027), Vector2(0.0, 0.027)]), 16)
			DesignKit.add(root, hub, steel, wheel_at, Vector3(0.0, 0.0, 90.0), false)
			DesignKit.rbox(root, Vector3(0.026, 0.105, 0.046), Vector3(x + 0.04, 0.129, z), steel, 0.008)
	# Walnut push grip on a steel U-frame at the right-hand end.
	for z: float in [-0.25, 0.25]:
		DesignKit.rbox(root, Vector3(0.035, 0.42, 0.035), Vector3(1.035, 0.88, z), steel, 0.014)
	DesignKit.rbox(root, Vector3(0.062, 0.06, 0.57), Vector3(1.035, 1.08, 0.0), walnut, 0.026)
	# A modest front bumper and brass end caps protect the joinery.
	DesignKit.rbox(root, Vector3(1.9, 0.048, 0.025), Vector3(0.0, 0.63, 0.303), color_band, 0.012)
	for x: float in [-0.94, 0.94]:
		DesignKit.rbox(root, Vector3(0.055, 0.048, 0.03), Vector3(x, 0.63, 0.306), DesignKit.brass(), 0.01, false)
	var tray_mesh: ArrayMesh = _tray_mesh()
	# Unequal stack heights and slight top-tray offsets suggest active use.
	for stack: int in 3:
		var count: int = 7 + posmod(style + stack * 2, 4)
		var stack_x: float = float(stack - 1) * 0.64
		for level: int in count:
			var tray_at: Vector3 = Vector3(stack_x, 0.79 + float(level) * 0.029, 0.025)
			if level == count - 1:
				tray_at.z += 0.012 * float(style - 1)
			DesignKit.add(root, tray_mesh, plastic, tray_at)
			if level == count - 1:
				_top_details(root, tray_at, rim_material, rubber, color_band)
	# Reserve trays on the open lower shelf, clear of both legs and wheels.
	for level: int in 3 + style:
		DesignKit.add(root, tray_mesh, plastic, Vector3(-0.48, 0.28 + float(level) * 0.029, 0.0))
	# Rear sign stays above the tray rims, with warm brass collars on its supports.
	for x: float in [-0.72, 0.72]:
		DesignKit.rbox(root, Vector3(0.032, 0.52, 0.032), Vector3(x, 1.035, -0.285), steel, 0.012)
		DesignKit.rbox(root, Vector3(0.047, 0.045, 0.047), Vector3(x, 0.805, -0.285), DesignKit.brass(), 0.009, false)
	var sign_panel: Node3D = Signage.panel(root, Vector3(0.0, 1.61, -0.285), "trays", {
		"width": 1.96, "compact": true, "accent": accent})
	# Use the compact panel's lower margin for the remaining international names.
	var translations: Array = Signage.translations("trays")
	var caption: Label3D = Label3D.new()
	caption.text = "%s · %s · %s" % [translations[3], translations[4], translations[5]]
	caption.font = Signage.font()
	caption.font_size = 64
	caption.pixel_size = 0.0022
	caption.modulate = DesignKit.CREAM
	caption.outline_size = 0
	caption.double_sided = false
	caption.position = Vector3(0.0, -0.28, 0.076)
	caption.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sign_panel.add_child(caption)
	return root


static func _top_details(parent: Node3D, at: Vector3, rim: Material, rubber: Material, accent: Material) -> void:
	# Molded floor ribs and broad recessed handgrips on both short ends.
	for rib: int in 3:
		DesignKit.rbox(parent, Vector3(0.35, 0.006, 0.013), at + Vector3(0.0, 0.02, float(rib - 1) * 0.075), rim, 0.002, false)
	for x: float in [-0.268, 0.268]:
		DesignKit.rbox(parent, Vector3(0.014, 0.023, 0.13), at + Vector3(x, 0.074, 0.0), rubber, 0.006, false)
		DesignKit.rbox(parent, Vector3(0.022, 0.012, 0.15), at + Vector3(x, 0.091, 0.0), rim, 0.005, false)
	DesignKit.rbox(parent, Vector3(0.16, 0.015, 0.012), at + Vector3(0.0, 0.085, 0.214), accent, 0.004, false)


static func _tray_mesh() -> ArrayMesh:
	if _meshes.has("tray"):
		return _meshes["tray"] as ArrayMesh
	# Continuous closed shell: bevelled underside, tapered walls, rolled rim,
	# inner wall and recessed floor. Rounded perimeter loops avoid slab geometry.
	var profiles: Array[Vector4] = [
		Vector4(0.237, 0.165, 0.033, 0.0),
		Vector4(0.245, 0.173, 0.038, 0.008),
		Vector4(0.273, 0.201, 0.045, 0.084),
		Vector4(0.280, 0.210, 0.049, 0.088),
		Vector4(0.280, 0.210, 0.049, 0.098),
		Vector4(0.274, 0.204, 0.045, 0.105),
		Vector4(0.269, 0.199, 0.041, 0.105),
		Vector4(0.266, 0.194, 0.039, 0.096),
		Vector4(0.241, 0.169, 0.033, 0.026),
		Vector4(0.233, 0.161, 0.029, 0.017)]
	var rings: Array[PackedVector3Array] = []
	for profile: Vector4 in profiles:
		rings.append(_rounded_ring(profile))
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring_index: int in rings.size() - 1:
		var lower: PackedVector3Array = rings[ring_index]
		var upper: PackedVector3Array = rings[ring_index + 1]
		for i: int in lower.size():
			var j: int = (i + 1) % lower.size()
			_triangle(st, lower[i], upper[j], lower[j])
			_triangle(st, lower[i], upper[i], upper[j])
	var bottom: PackedVector3Array = rings[0]
	var floor_ring: PackedVector3Array = rings[rings.size() - 1]
	for i: int in bottom.size():
		var j: int = (i + 1) % bottom.size()
		_triangle(st, Vector3.ZERO, bottom[i], bottom[j])
		_triangle(st, Vector3(0.0, 0.017, 0.0), floor_ring[j], floor_ring[i])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["tray"] = mesh
	return mesh


static func _rounded_ring(profile: Vector4) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for corner: int in 4:
		var angle: float = float(corner) * PI * 0.5
		var sx: float = 1.0 if corner == 0 or corner == 3 else -1.0
		var sz: float = 1.0 if corner < 2 else -1.0
		var center: Vector3 = Vector3(sx * (profile.x - profile.z), profile.w, sz * (profile.y - profile.z))
		for step: int in 7:
			var theta: float = angle + float(step) / 6.0 * PI * 0.5
			points.append(center + Vector3(cos(theta) * profile.z, 0.0, sin(theta) * profile.z))
	return points


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.set_uv(Vector2(a.x, a.z))
	st.add_vertex(a)
	st.set_uv(Vector2(b.x, b.z))
	st.add_vertex(b)
	st.set_uv(Vector2(c.x, c.z))
	st.add_vertex(c)
