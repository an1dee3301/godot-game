extends RefCounted
## Six-by-four metre open timber cloud. All heights are measured from the terminal floor.
## No lettering: this is an architectural light fitting, leaving wayfinding to Signage panels.


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "SlatCeilingCloud"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var oak_tint: Color = DesignKit.OAK
	var housing_tint: Color = DesignKit.CHARCOAL
	var glow_tint: Color = Color(1.0, 0.88, 0.70)
	match style:
		1:
			oak_tint = DesignKit.OAK.lightened(0.12)
			housing_tint = DesignKit.SAGE.darkened(0.25)
			glow_tint = Color(1.0, 0.93, 0.81)
		2:
			oak_tint = DesignKit.OAK.darkened(0.07)
			housing_tint = DesignKit.CLAY.darkened(0.28)
		3:
			oak_tint = DesignKit.OAK.lightened(0.05)
			housing_tint = DesignKit.WALNUT.darkened(0.25)
	var oak: StandardMaterial3D = DesignKit.wood(oak_tint, "ceiling_cloud_oak_%d" % style)
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "ceiling_cloud_walnut")
	var steel: StandardMaterial3D = DesignKit.metal()
	var housing: StandardMaterial3D = DesignKit.metal(housing_tint, 0.55, 0.45, "ceiling_cloud_housing_%d" % style)
	var paper: StandardMaterial3D = DesignKit.washi(glow_tint, 2.2, "ceiling_cloud_washi_%d" % style)
	var brass: StandardMaterial3D = DesignKit.brass()
	# Deep, narrow fins give the underside a rhythmic silhouette and visible air gaps.
	# Progressively shorter outer fins soften the four corners without a solid ceiling slab.
	for index in 25:
		var x: float = -2.88 + float(index) * 0.24
		var end_setback: float = 0.30 * pow(absf(x) / 2.88, 8.0)
		var length: float = 4.0 - end_setback * 2.0
		var timber: StandardMaterial3D = walnut if style == 3 and index % 6 == 0 else oak
		if index == 6 or index == 12 or index == 18:
			# Flush paper diffuser, recessed in a dark channel between adjacent timber fins.
			DesignKit.rbox(root, Vector3(0.16, 0.22, 3.84), Vector3(x, 8.015, 0.0), housing, 0.035)
			DesignKit.rbox(root, Vector3(0.115, 0.026, 3.62), Vector3(x, 7.899, 0.0), paper, 0.012, false)
			for end in [-1.0, 1.0]:
				DesignKit.rbox(root, Vector3(0.12, 0.033, 0.055), Vector3(x, 7.902, end * 1.837), brass, 0.009, false)
		else:
			DesignKit.rbox(root, Vector3(0.16, 0.24, length), Vector3(x, 8.02, 0.0), timber, 0.038)
	# Two walnut carriers and slim side lippings make the assembly read as crafted joinery.
	for z in [-1.35, 1.35]:
		DesignKit.rbox(root, Vector3(5.80, 0.095, 0.13), Vector3(0.0, 8.1825, z), walnut, 0.025)
	for side in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.10, 0.14, 3.32), Vector3(side * 2.95, 8.09, 0.0), oak, 0.035)
	# Turned steel hangers with brass adjustment ferrules and rounded ceiling roses.
	var rod_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.009, 0.0), Vector2(0.009, 1.30), Vector2(0.0, 1.30)
	]), 8)
	var ferrule_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.023, 0.0), Vector2(0.028, 0.012),
		Vector2(0.028, 0.075), Vector2(0.018, 0.09), Vector2(0.0, 0.09)
	]), 12)
	var rose_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.045, 0.0), Vector2(0.085, 0.025),
		Vector2(0.09, 0.045), Vector2(0.09, 0.065), Vector2(0.0, 0.065)
	]), 16)
	for x in [-2.40, 2.40]:
		for z in [-1.35, 1.35]:
			DesignKit.rbox(root, Vector3(0.12, 0.04, 0.18), Vector3(x, 8.25, z), steel, 0.015, false)
			DesignKit.add(root, rod_mesh, steel, Vector3(x, 8.27, z), Vector3.ZERO, false)
			DesignKit.add(root, ferrule_mesh, brass, Vector3(x, 8.27, z), Vector3.ZERO, false)
			DesignKit.add(root, rose_mesh, housing, Vector3(x, 9.54, z), Vector3.ZERO, false)
	return root
