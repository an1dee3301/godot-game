extends RefCounted
## A low, open-frame lounge chair. Front is +Z; all feet meet y = 0.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "JapandiArmchair"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var colors: Array[Color] = [DesignKit.LINEN, DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO]
	var choice: int = posmod(variant, colors.size())
	var tint: Color = colors[choice]
	var upholstery: StandardMaterial3D = DesignKit.fabric(tint, "armchair_linen_%d" % choice)
	var piping: StandardMaterial3D = DesignKit.fabric(tint.darkened(0.16), "armchair_welt_%d" % choice)
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var glide: StandardMaterial3D = DesignKit.paint(DesignKit.CHARCOAL, 0.95)
	var leg: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.027, 0.0), Vector2(0.033, 0.012),
		Vector2(0.044, 0.295), Vector2(0.042, 0.32), Vector2(0.0, 0.32)
	]), 16)
	var foot: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.026, 0.0), Vector2(0.028, 0.004),
		Vector2(0.028, 0.012), Vector2(0.0, 0.012)
	]), 12)
	for x: float in [-0.365, 0.365]:
		for z: float in [-0.30, 0.30]:
			DesignKit.add(root, foot, glide, Vector3(x, 0.0, z))
			DesignKit.add(root, leg, oak, Vector3(x, 0.012, z))
		# Side rails and uprights show the timber construction below the arms.
		DesignKit.rbox(root, Vector3(0.075, 0.10, 0.77), Vector3(x, 0.32, 0.0), oak, 0.024)
		for z: float in [-0.29, 0.27]:
			DesignKit.rbox(root, Vector3(0.055, 0.25, 0.065), Vector3(x, 0.485, z), oak, 0.021)
		DesignKit.rbox(root, Vector3(0.135, 0.095, 0.79), Vector3(x, 0.625, 0.01), oak, 0.044)
		# End-grain walnut dowels at the front arm joint, flush with the outer face.
		var peg: ArrayMesh = DesignKit.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.009, 0.0), Vector2(0.009, 0.003), Vector2(0.0, 0.003)
		]), 12)
		DesignKit.add(root, peg, walnut, Vector3(x + signf(x) * 0.067, 0.625, 0.27), Vector3(0.0, 0.0, -signf(x) * 90.0), false)
	for z: float in [-0.32, 0.32]:
		DesignKit.rbox(root, Vector3(0.71, 0.095, 0.065), Vector3(0.0, 0.325, z), oak, 0.023)
	# Recessed support slats keep the cushion visually floating above the frame.
	for z: float in [-0.21, 0.0, 0.21]:
		DesignKit.rbox(root, Vector3(0.68, 0.035, 0.12), Vector3(0.0, 0.37, z), walnut, 0.014)
	DesignKit.rbox(root, Vector3(0.655, 0.18, 0.69), Vector3(0.0, 0.466, 0.035), upholstery, 0.082)
	DesignKit.add(root, _welt(0.646, 0.681, 0.082), piping, Vector3(0.0, 0.464, 0.035), Vector3(90.0, 0.0, 0.0), false)
	# The entire back assembly reclines twelve degrees away from the sitter.
	var back: Node3D = Node3D.new()
	back.name = "ReclinedBack"
	back.position = Vector3(0.0, 0.64, -0.29)
	back.rotation_degrees.x = -12.0
	root.add_child(back)
	for x: float in [-0.30, 0.30]:
		DesignKit.rbox(back, Vector3(0.052, 0.57, 0.05), Vector3(x, 0.0, -0.085), oak, 0.02)
	for y: float in [-0.17, 0.18]:
		DesignKit.rbox(back, Vector3(0.65, 0.065, 0.05), Vector3(0.0, y, -0.085), oak, 0.023)
	DesignKit.rbox(back, Vector3(0.65, 0.49, 0.16), Vector3(0.0, 0.045, 0.0), upholstery, 0.074)
	DesignKit.add(back, _welt(0.641, 0.481, 0.076), piping, Vector3(0.0, 0.045, 0.025), Vector3.ZERO, false)
	return root


## Closed, rounded rectangular upholstery piping, swept in the local XY plane.
static func _welt(width: float, height: float, radius: float) -> ArrayMesh:
	var key: String = "welt:%s:%s:%s" % [width, height, radius]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var points: PackedVector3Array = PackedVector3Array()
	for corner: int in 4:
		var angle: float = float(corner) * PI * 0.5
		var center: Vector3 = Vector3(
			(width * 0.5 - radius) * (1.0 if corner == 0 or corner == 3 else -1.0),
			(height * 0.5 - radius) * (1.0 if corner < 2 else -1.0), 0.0)
		for step: int in 9:
			var a: float = angle + float(step) * PI / 16.0
			points.append(center + Vector3(cos(a), sin(a), 0.0) * radius)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in points.size():
		var next: int = (i + 1) % points.size()
		var tangent_a: Vector3 = (points[next] - points[(i + points.size() - 1) % points.size()]).normalized()
		var tangent_b: Vector3 = (points[(next + 1) % points.size()] - points[i]).normalized()
		var outward_a: Vector3 = Vector3(tangent_a.y, -tangent_a.x, 0.0)
		var outward_b: Vector3 = Vector3(tangent_b.y, -tangent_b.x, 0.0)
		for side: int in 6:
			var a: float = float(side) * TAU / 6.0
			var b: float = float(side + 1) * TAU / 6.0
			var na: Vector3 = outward_a * cos(a) + Vector3.FORWARD * sin(a)
			var nb: Vector3 = outward_b * cos(a) + Vector3.FORWARD * sin(a)
			var nc: Vector3 = outward_b * cos(b) + Vector3.FORWARD * sin(b)
			var nd: Vector3 = outward_a * cos(b) + Vector3.FORWARD * sin(b)
			var vertices: Array[Vector3] = [points[i] + na * 0.003, points[next] + nb * 0.003, points[next] + nc * 0.003, points[i] + nd * 0.003]
			var normals: Array[Vector3] = [na, nb, nc, nd]
			for index: int in [0, 1, 2, 0, 2, 3]:
				st.set_normal(normals[index])
				st.set_uv(Vector2(float(i) / float(points.size()), float(side) / 6.0))
				st.add_vertex(vertices[index])
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh
