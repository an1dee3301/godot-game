extends RefCounted
## Three airport massage pods, facing +Z. All geometry is cached by DesignKit.


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "MassageChairs"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var upholstery_colors: Array[Color] = [DesignKit.LINEN, DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO]
	var accent: Color = upholstery_colors[style]
	var shell_color: Color = DesignKit.CREAM if style % 2 == 0 else DesignKit.CHARCOAL
	var shell: Material = DesignKit.paint(shell_color, 0.42)
	var fabric: Material = DesignKit.fabric(accent, "massage_upholstery_%d" % style)
	var seam: Material = DesignKit.fabric(accent.darkened(0.24), "massage_piping_%d" % style)
	var timber: Material = DesignKit.wood(DesignKit.OAK if style < 2 else DesignKit.WALNUT, "massage_arm_%d" % (style / 2))
	var steel: Material = DesignKit.metal()
	var glow: Material = DesignKit.washi(Color(0.70, 0.87, 0.77), 1.4, "massage_screen")
	for index: int in range(3):
		var chair: Node3D = Node3D.new()
		chair.name = "MassagePod_%d" % (index + 1)
		chair.position.x = float(index - 1) * 1.34
		root.add_child(chair)
		_build_chair(chair, shell, fabric, seam, timber, steel, glow, style, index)
	# The sign stands behind the recliners, outside the reclining envelope.
	for x: float in [-1.84, 1.84]:
		DesignKit.rbox(root, Vector3(0.32, 0.055, 0.42), Vector3(x, 0.0275, -0.91), steel, 0.025)
		DesignKit.rbox(root, Vector3(0.055, 2.61, 0.055), Vector3(x, 1.36, -0.91), timber, 0.02)
	Signage.panel(root, Vector3(0.0, 2.59, -0.87), "lounge", {
		"width": 4.3,
		"suffix": "· Massage",
		"accent": accent,
	})
	return root


static func _build_chair(chair: Node3D, shell: Material, fabric: Material, seam: Material, timber: Material, steel: Material, glow: Material, style: int, index: int) -> void:
	# Low floating chassis; rubber feet make the origin the actual floor contact.
	var foot_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.055, 0.0), Vector2(0.064, 0.025),
		Vector2(0.055, 0.075), Vector2(0.0, 0.075),
	])
	var foot_mesh: ArrayMesh = DesignKit.lathe(foot_profile, 16)
	for x: float in [-0.34, 0.34]:
		for z: float in [-0.46, 0.41]:
			DesignKit.add(chair, foot_mesh, steel, Vector3(x, 0.0, z))
	DesignKit.rbox(chair, Vector3(0.86, 0.14, 1.08), Vector3(0.0, 0.14, -0.02), steel, 0.065)
	DesignKit.rbox(chair, Vector3(0.92, 0.35, 0.98), Vector3(0.0, 0.36, -0.05), shell, 0.16)
	# A tilted, thick rounded shell cradles the back, with upholstery inset in front.
	var back: Node3D = Node3D.new()
	back.position = Vector3(0.0, 1.02, -0.38)
	back.rotation_degrees.x = -18.0 - float((style + index) % 2) * 3.0
	chair.add_child(back)
	DesignKit.rbox(back, Vector3(0.91, 1.16, 0.30), Vector3.ZERO, shell, 0.145)
	DesignKit.rbox(back, Vector3(0.71, 0.95, 0.13), Vector3(0.0, 0.0, 0.17), seam, 0.06)
	DesignKit.rbox(back, Vector3(0.66, 0.88, 0.15), Vector3(0.0, 0.0, 0.205), fabric, 0.07)
	# Shoulder wings and a separate pillow leave visible seams, not a monolithic slab.
	for x: float in [-0.34, 0.34]:
		DesignKit.rbox(back, Vector3(0.13, 0.56, 0.24), Vector3(x, 0.06, 0.24), fabric, 0.06)
	DesignKit.rbox(back, Vector3(0.46, 0.25, 0.15), Vector3(0.0, 0.36, 0.29), fabric, 0.073)
	DesignKit.rbox(back, Vector3(0.53, 0.17, 0.14), Vector3(0.0, -0.30, 0.29), fabric, 0.065)
	DesignKit.rbox(chair, Vector3(0.69, 0.055, 0.73), Vector3(0.0, 0.535, 0.09), seam, 0.025)
	DesignKit.rbox(chair, Vector3(0.65, 0.18, 0.70), Vector3(0.0, 0.60, 0.09), fabric, 0.085)
	# Broad capsule arms with tactile timber caps and inner forearm cushions.
	for x: float in [-0.47, 0.47]:
		DesignKit.rbox(chair, Vector3(0.24, 0.51, 0.96), Vector3(x, 0.61, 0.04), shell, 0.115)
		DesignKit.rbox(chair, Vector3(0.205, 0.055, 0.66), Vector3(x, 0.878, 0.03), timber, 0.026)
		DesignKit.rbox(chair, Vector3(0.12, 0.09, 0.46), Vector3(x * 0.82, 0.82, 0.09), fabric, 0.044)
	# Projecting calf cradle and twin recessed foot wells identify a massage chair.
	DesignKit.rbox(chair, Vector3(0.57, 0.075, 0.41), Vector3(0.0, 0.29, 0.57), steel, 0.03)
	var footrest: Node3D = Node3D.new()
	footrest.position = Vector3(0.0, 0.36, 0.83)
	footrest.rotation_degrees.x = -12.0
	chair.add_child(footrest)
	DesignKit.rbox(footrest, Vector3(0.76, 0.52, 0.53), Vector3.ZERO, shell, 0.13)
	for x: float in [-0.175, 0.175]:
		DesignKit.rbox(footrest, Vector3(0.27, 0.40, 0.10), Vector3(x, 0.025, 0.237), seam, 0.048)
		DesignKit.rbox(footrest, Vector3(0.20, 0.29, 0.09), Vector3(x, 0.045, 0.287), fabric, 0.044)
		DesignKit.rbox(footrest, Vector3(0.25, 0.105, 0.27), Vector3(x, -0.17, 0.25), fabric, 0.05)
	# Angled control pod: softly lit screen, abstract program bars and a brass dial.
	var control: Node3D = Node3D.new()
	control.position = Vector3(0.47, 0.94, 0.31)
	control.rotation_degrees.x = -32.0
	chair.add_child(control)
	DesignKit.rbox(control, Vector3(0.205, 0.26, 0.065), Vector3.ZERO, steel, 0.03)
	DesignKit.rbox(control, Vector3(0.155, 0.16, 0.012), Vector3(0.0, 0.023, 0.038), glow, 0.015, false)
	for bar: int in range(3):
		DesignKit.rbox(control, Vector3(0.08 - float(bar) * 0.014, 0.009, 0.006), Vector3(-0.014, 0.065 - float(bar) * 0.038, 0.048), steel, 0.003, false)
	var dial_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.022, 0.0), Vector2(0.024, 0.008),
		Vector2(0.018, 0.016), Vector2(0.0, 0.016),
	]), 16)
	DesignKit.add(control, dial_mesh, DesignKit.brass(), Vector3(0.0, -0.085, 0.034), Vector3(90.0, 0.0, 0.0), false)
