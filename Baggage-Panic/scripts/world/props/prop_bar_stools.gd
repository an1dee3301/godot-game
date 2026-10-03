extends RefCounted
## Four backless café stools, with turned seats and welded, splayed steel frames.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BarStools"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	# Keep the shared international venue vocabulary available to scene inspectors.
	root.set_meta("venue_translations", Signs.translations("cafe"))
	var style: int = posmod(variant, 4)
	var oak_tones: Array[Color] = [Kit.OAK, Kit.OAK.lightened(0.09), Kit.OAK.darkened(0.12), Color(0.73, 0.55, 0.35)]
	var accent_tones: Array[Color] = [Kit.CHARCOAL, Kit.SAGE, Kit.CLAY, Kit.LINEN]
	var oak: StandardMaterial3D = Kit.wood(oak_tones[style], "bar_stool_oak_%d" % style)
	var steel: StandardMaterial3D = Kit.metal(Kit.CHARCOAL.darkened(0.25), 0.43, 0.85, "bar_stool_steel")
	var accent: StandardMaterial3D = Kit.paint(accent_tones[style])
	var brass: StandardMaterial3D = Kit.brass()
	var rubber: StandardMaterial3D = Kit.paint(Color(0.075, 0.07, 0.06), 0.96)
	var walnut: StandardMaterial3D = Kit.wood(Kit.WALNUT, "bar_stool_walnut")
	var seat_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.715), Vector2(0.13, 0.715),
		Vector2(0.169, 0.722), Vector2(0.185, 0.733),
		Vector2(0.194, 0.747), Vector2(0.196, 0.761),
		Vector2(0.190, 0.774), Vector2(0.178, 0.780),
		Vector2(0.156, 0.779), Vector2(0.120, 0.768),
		Vector2(0.060, 0.759), Vector2(0.0, 0.757),
	]), 48)
	var glide_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.019, 0.0),
		Vector2(0.023, 0.004), Vector2(0.023, 0.016),
		Vector2(0.019, 0.023), Vector2(0.0, 0.023),
	]), 16)
	var ring_mesh: ArrayMesh = _ring(0.209, 0.013)
	var seat_trim: ArrayMesh = _ring(0.173, 0.003)
	var mounting_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.108, 0.0),
		Vector2(0.116, 0.005), Vector2(0.116, 0.014),
		Vector2(0.108, 0.019), Vector2(0.0, 0.019),
	]), 32)
	for index: int in 4:
		var stool: Node3D = Node3D.new()
		stool.name = "Stool_%d" % (index + 1)
		stool.position = Vector3((float(index) - 1.5) * (0.78 + float(style) * 0.015), 0.0, 0.0)
		if style == 3:
			stool.position.z = 0.055 if index % 2 == 0 else -0.055
		stool.rotation_degrees.y = float(index * 7 + style * 5)
		root.add_child(stool)
		Kit.add(stool, seat_mesh, oak, Vector3.ZERO)
		Kit.add(stool, seat_trim, walnut, Vector3(0.0, 0.725, 0.0))
		Kit.add(stool, mounting_mesh, accent, Vector3(0.0, 0.696, 0.0))
		# Crossed rounded rails carry the seat and conceal the screw fixings.
		Kit.rbox(stool, Vector3(0.29, 0.026, 0.035), Vector3(0.0, 0.692, 0.0), steel, 0.009)
		Kit.rbox(stool, Vector3(0.035, 0.026, 0.29), Vector3(0.0, 0.692, 0.0), steel, 0.009)
		Kit.add(stool, ring_mesh, brass, Vector3(0.0, 0.255, 0.0))
		for leg_index: int in 4:
			var angle: float = PI * 0.25 + float(leg_index) * PI * 0.5
			var radial: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
			var bottom: Vector3 = radial * 0.25 + Vector3.UP * 0.018
			var top: Vector3 = radial * 0.135 + Vector3.UP * 0.701
			var leg_length: float = bottom.distance_to(top)
			var leg_mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(0.012, 0.0),
				Vector2(0.015, 0.005), Vector2(0.018, leg_length - 0.006),
				Vector2(0.015, leg_length), Vector2(0.0, leg_length),
			]), 16)
			var leg: MeshInstance3D = Kit.add(stool, leg_mesh, steel, bottom)
			leg.quaternion = Quaternion(Vector3.UP, (top - bottom).normalized())
			Kit.add(stool, glide_mesh, rubber, radial * 0.25)
	return root


static func _ring(radius: float, tube_radius: float) -> ArrayMesh:
	# Closed turned tube profile: smooth brass all around, with an open centre.
	var profile: PackedVector2Array = PackedVector2Array()
	for index: int in 13:
		var angle: float = -PI * 0.5 + TAU * float(index) / 12.0
		profile.append(Vector2(radius + cos(angle) * tube_radius, sin(angle) * tube_radius))
	return Kit.lathe(profile, 48)
