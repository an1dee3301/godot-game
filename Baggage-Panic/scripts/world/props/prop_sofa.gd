extends RefCounted
## Low three-seat lounge sofa; +Z is the open seating side. Dimensions in metres.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "LinenSofa"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	# Localized lounge names are available to interaction/accessibility consumers.
	# Furniture itself has no small, unreadable signage.
	root.set_meta("lounge_names", Signs.translations("lounge"))
	var choice: int = posmod(variant, 4)
	var upholstery_colors: Array[Color] = [Kit.LINEN, Kit.CREAM.darkened(0.09), Kit.SAGE.lightened(0.28), Color(0.73, 0.70, 0.65)]
	var bolster_colors: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.LINEN, Kit.INDIGO]
	var linen_color: Color = upholstery_colors[choice]
	var bolster_color: Color = bolster_colors[choice]
	var linen: StandardMaterial3D = Kit.fabric(linen_color, "sofa_linen_%d" % choice)
	var accent: StandardMaterial3D = Kit.fabric(bolster_color, "sofa_bolster_%d" % choice)
	var piping: StandardMaterial3D = Kit.fabric(linen_color.darkened(0.14), "sofa_welt_%d" % choice)
	var accent_piping: StandardMaterial3D = Kit.fabric(bolster_color.darkened(0.16), "sofa_bolster_welt_%d" % choice)
	var oak: StandardMaterial3D = Kit.wood(Kit.OAK, "oak")
	var steel: StandardMaterial3D = Kit.metal()
	var walnut: StandardMaterial3D = Kit.wood(Kit.WALNUT, "walnut")
	# Recessed feet leave a floating shadow beneath the thick, softened oak platform.
	for x: float in [-0.96, 0.96]:
		for z: float in [-0.29, 0.29]:
			Kit.rbox(root, Vector3(0.09, 0.10, 0.09), Vector3(x, 0.05, z), steel, 0.018)
	Kit.rbox(root, Vector3(2.34, 0.045, 0.79), Vector3(0.0, 0.1125, 0.0), walnut, 0.02)
	Kit.rbox(root, Vector3(2.44, 0.12, 0.91), Vector3(0.0, 0.19, 0.0), oak, 0.045)
	Kit.rbox(root, Vector3(2.22, 0.105, 0.76), Vector3(0.0, 0.295, 0.015), linen, 0.05)
	# Continuous oak rear shell and two low wooden cheeks support removable upholstery.
	Kit.rbox(root, Vector3(2.30, 0.48, 0.105), Vector3(0.0, 0.49, -0.368), oak, 0.045)
	for x: float in [-1.115, 1.115]:
		Kit.rbox(root, Vector3(0.14, 0.29, 0.77), Vector3(x, 0.385, 0.0), oak, 0.06)
	var seat_welt: ArrayMesh = _welt(Vector2(0.676, 0.666), 0.065, 0.0045)
	var back_welt: ArrayMesh = _welt(Vector2(0.67, 0.413), 0.06, 0.004)
	for seat: int in 3:
		var x: float = float(seat - 1) * 0.69
		Kit.rbox(root, Vector3(0.676, 0.17, 0.69), Vector3(x, 0.415, 0.045), linen, 0.075)
		# A continuous sewn welt follows the cushion's softened perimeter.
		Kit.add(root, seat_welt, piping, Vector3(x, 0.438, 0.045), Vector3(90.0, 0.0, 0.0), false)
		Kit.add(root, Kit.rounded_box(Vector3(0.674, 0.435, 0.17), 0.074, 5), linen, Vector3(x, 0.643, -0.242), Vector3(-10.0, 0.0, 0.0))
		Kit.add(root, back_welt, piping, Vector3(x, 0.647, -0.157), Vector3(-10.0, 0.0, 0.0), false)
	# Turned, softly crowned bolster profile, with inset end panels and circular welts.
	var bolster: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.29), Vector2(0.085, -0.29), Vector2(0.113, -0.278),
		Vector2(0.131, -0.25), Vector2(0.136, -0.18), Vector2(0.138, 0.0),
		Vector2(0.136, 0.18), Vector2(0.131, 0.25), Vector2(0.113, 0.278),
		Vector2(0.085, 0.29), Vector2(0.0, 0.29)
	]), 32)
	var bolster_welt: ArrayMesh = _welt(Vector2(0.221, 0.221), 0.1105, 0.004)
	for side: int in 2:
		var x: float = -1.034 if side == 0 else 1.034
		var lift: float = 0.008 if choice % 2 == side else 0.0
		Kit.add(root, bolster, accent, Vector3(x, 0.565 + lift, 0.035), Vector3(90.0, 0.0, 0.0))
		for end: float in [-1.0, 1.0]:
			Kit.add(root, bolster_welt, accent_piping, Vector3(x, 0.565 + lift, 0.035 + end * 0.279), Vector3.ZERO, false)
	return root


## Swept thread-sized tube around a rounded rectangle, in the local XY plane.
## The same cached geometry supplies seat seams, back seams, and round bolster seams.
static func _welt(size: Vector2, corner_radius: float, tube_radius: float) -> ArrayMesh:
	var key: String = "%s:%0.4f:%0.4f" % [size, corner_radius, tube_radius]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var path: PackedVector3Array = PackedVector3Array()
	var outward: PackedVector3Array = PackedVector3Array()
	var half: Vector2 = size * 0.5
	for corner: int in 4:
		var angle: float = float(corner) * PI * 0.5
		var center: Vector2 = Vector2(half.x - corner_radius, half.y - corner_radius)
		if corner == 1 or corner == 2:
			center.x = -center.x
		if corner >= 2:
			center.y = -center.y
		for step: int in 9:
			var theta: float = angle + float(step) * PI / 16.0
			var normal: Vector3 = Vector3(cos(theta), sin(theta), 0.0)
			path.append(Vector3(center.x, center.y, 0.0) + normal * corner_radius)
			outward.append(normal)
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in path.size():
		var next: int = (i + 1) % path.size()
		for ring: int in 6:
			var corners: Array[Vector2i] = [Vector2i(i, ring), Vector2i(next, ring), Vector2i(i, ring + 1), Vector2i(next, ring), Vector2i(next, ring + 1), Vector2i(i, ring + 1)]
			for vertex: Vector2i in corners:
				var theta: float = float(vertex.y) * TAU / 6.0
				var normal: Vector3 = outward[vertex.x] * cos(theta) + Vector3.BACK * sin(theta)
				surface.set_normal(normal)
				surface.set_uv(Vector2(float(vertex.x) / float(path.size()), float(vertex.y) / 6.0))
				surface.add_vertex(path[vertex.x] + normal * tube_radius)
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh
