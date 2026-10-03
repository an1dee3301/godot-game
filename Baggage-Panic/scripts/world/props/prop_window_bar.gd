extends RefCounted
## Five-metre window perch. Guests sit on the -Z side and look out towards +Z.

static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "WindowBar"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var colours: Array[Color] = [DesignKit.LINEN, DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO]
	var tint: Color = colours[choice]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "window_bar_walnut")
	var steel: StandardMaterial3D = DesignKit.metal()
	var brass: StandardMaterial3D = DesignKit.brass()
	var limestone: StandardMaterial3D = DesignKit.stone()
	var cloth: StandardMaterial3D = DesignKit.fabric(tint, "window_bar_seat_%d" % choice)
	var dark: StandardMaterial3D = DesignKit.paint(DesignKit.CHARCOAL)
	# Thick eased oak edge, recessed walnut apron and a window-side cable chase.
	DesignKit.rbox(root, Vector3(5.0, 0.085, 0.68), Vector3(0.0, 1.0075, 0.12), oak, 0.04)
	DesignKit.rbox(root, Vector3(4.72, 0.065, 0.54), Vector3(0.0, 0.9325, 0.14), walnut, 0.025)
	DesignKit.rbox(root, Vector3(4.66, 0.49, 0.075), Vector3(0.0, 0.695, 0.39), walnut, 0.03)
	DesignKit.rbox(root, Vector3(4.54, 0.018, 0.012), Vector3(0.0, 0.897, 0.434), brass, 0.005, false)
	# Stone blade piers leave generous knee space between the six seats.
	for x: float in [-2.27, 2.27]:
		DesignKit.rbox(root, Vector3(0.15, 0.88, 0.48), Vector3(x, 0.48, 0.17), limestone, 0.055)
		DesignKit.rbox(root, Vector3(0.22, 0.04, 0.51), Vector3(x, 0.02, 0.17), steel, 0.018)
		DesignKit.rbox(root, Vector3(0.17, 0.025, 0.46), Vector3(x, 0.0525, 0.17), brass, 0.01, false)
	DesignKit.rbox(root, Vector3(0.065, 0.91, 0.07), Vector3(0.0, 0.455, 0.34), steel, 0.02)
	# Continuous brass foot rail, tucked beneath the counter's guest edge.
	_rod(root, Vector3(-2.23, 0.27, -0.16), Vector3(2.23, 0.27, -0.16), 0.022, brass)
	for x: float in [-2.23, 0.0, 2.23]:
		_rod(root, Vector3(x, 0.27, -0.16), Vector3(x, 0.27, 0.32), 0.013, steel)
	# Flush charging stations: two AC sockets and a paired USB-C recess per station.
	for i: int in 3:
		var x: float = -1.6 + float(i) * 1.6
		DesignKit.rbox(root, Vector3(0.36, 0.012, 0.135), Vector3(x, 1.053, 0.30), brass, 0.025, false)
		DesignKit.rbox(root, Vector3(0.33, 0.01, 0.11), Vector3(x, 1.06, 0.30), dark, 0.022, false)
		for dx: float in [-0.092, 0.014]:
			var socket_at: Vector3 = Vector3(x + dx, 1.066, 0.30)
			DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(0.035, 0.0), Vector2(0.04, 0.004),
				Vector2(0.035, 0.008), Vector2(0.0, 0.008)
			]), 16), DesignKit.paint(DesignKit.PLASTER), socket_at, Vector3.ZERO, false)
			for offset: float in [-0.012, 0.012]:
				DesignKit.rbox(root, Vector3(0.009, 0.003, 0.017), socket_at + Vector3(offset, 0.009, 0.0), dark, 0.003, false)
		for dz: float in [-0.02, 0.02]:
			DesignKit.rbox(root, Vector3(0.024, 0.004, 0.009), Vector3(x + 0.112, 1.067, 0.30 + dz), brass, 0.003, false)
			DesignKit.rbox(root, Vector3(0.018, 0.003, 0.005), Vector3(x + 0.112, 1.07, 0.30 + dz), dark, 0.002, false)
	# Large bilingual pairs read as two calm lines across the window-side fascia.
	_caption(root, "Power  ·  充電  ·  充电", Vector3(0.0, 0.77, 0.433))
	_caption(root, "Sạc điện  ·  Recharge  ·  Carga", Vector3(0.0, 0.56, 0.433))
	for i: int in 6:
		var x: float = -1.95 + float(i) * 0.78
		_stool(root, Vector3(x, 0.0, -0.58), oak, walnut, steel, brass, cloth)
	return root


static func _stool(parent: Node3D, at: Vector3, oak: Material, walnut: Material, steel: Material, brass: Material, cloth: Material) -> void:
	# A flared weighted base and slender turned column avoid a forest of legs.
	DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.20, 0.0), Vector2(0.235, 0.015),
		Vector2(0.235, 0.03), Vector2(0.21, 0.045), Vector2(0.065, 0.075),
		Vector2(0.04, 0.12), Vector2(0.032, 0.65), Vector2(0.095, 0.69),
		Vector2(0.0, 0.69)
	]), 24), steel, at)
	# Closed lathed ring with a hollow centre: an actual footrest, not a disc.
	DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([
		Vector2(0.158, 0.26), Vector2(0.165, 0.25), Vector2(0.177, 0.26),
		Vector2(0.177, 0.275), Vector2(0.165, 0.282), Vector2(0.158, 0.275),
		Vector2(0.158, 0.26)
	]), 24), brass, at)
	_rod(parent, at + Vector3(-0.16, 0.266, 0.0), at + Vector3(0.16, 0.266, 0.0), 0.008, steel)
	DesignKit.rbox(parent, Vector3(0.43, 0.052, 0.42), at + Vector3(0.0, 0.699, 0.0), oak, 0.025)
	DesignKit.rbox(parent, Vector3(0.403, 0.012, 0.393), at + Vector3(0.0, 0.729, 0.0), walnut, 0.005, false)
	DesignKit.rbox(parent, Vector3(0.40, 0.04, 0.39), at + Vector3(0.0, 0.755, 0.0), cloth, 0.019)
	# Low lumbar backs sit behind the guest; their open side faces the windows (+Z).
	for dx: float in [-0.155, 0.155]:
		_rod(parent, at + Vector3(dx, 0.70, -0.16), at + Vector3(dx, 0.965, -0.22), 0.011, steel)
	var back: MeshInstance3D = DesignKit.rbox(parent, Vector3(0.42, 0.17, 0.045), at + Vector3(0.0, 0.952, -0.22), walnut, 0.022)
	back.rotation_degrees.x = -12.0
	var pad: MeshInstance3D = DesignKit.rbox(parent, Vector3(0.37, 0.125, 0.025), at + Vector3(0.0, 0.952, -0.193), cloth, 0.012)
	pad.rotation_degrees.x = -12.0


static func _rod(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var length: float = start.distance_to(end)
	var mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -length * 0.5), Vector2(radius, -length * 0.5),
		Vector2(radius, length * 0.5), Vector2(0.0, length * 0.5)
	]), 12)
	var instance: MeshInstance3D = DesignKit.add(parent, mesh, material, (start + end) * 0.5, Vector3.ZERO, false)
	instance.quaternion = Quaternion(Vector3.UP, (end - start).normalized())


static func _caption(parent: Node3D, caption: String, at: Vector3) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 96
	label.pixel_size = 0.0024
	label.modulate = DesignKit.CREAM
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
