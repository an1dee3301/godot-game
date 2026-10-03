extends RefCounted
## Six metres of steam-bent oak; front is +Z, finished seat height is 0.49 m.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "LongOakGateBench"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var colours: Array[Color] = [Kit.LINEN, Kit.SAGE, Kit.CLAY, Kit.INDIGO]
	var oak: StandardMaterial3D = Kit.wood(Kit.OAK.lightened(float(style) * 0.025), "long_bench_oak_%d" % style)
	var walnut: StandardMaterial3D = Kit.wood(Kit.WALNUT, "long_bench_walnut")
	var cloth: StandardMaterial3D = Kit.fabric(colours[style], "long_bench_pad_%d" % style)
	var piping: StandardMaterial3D = Kit.fabric(colours[style].darkened(0.16), "long_bench_seam_%d" % style)
	var steel: StandardMaterial3D = Kit.metal()
	var brass: StandardMaterial3D = Kit.brass()
	var dark: StandardMaterial3D = Kit.paint(Kit.CHARCOAL.darkened(0.4))
	var shell_path: PackedVector3Array = PackedVector3Array()
	_curve(shell_path, Vector3(0, 0.405, 0.34), Vector3(0, 0.46, 0.34), Vector3(0, 0.455, 0.28), Vector3(0, 0.455, 0.16), 8)
	_curve(shell_path, Vector3(0, 0.455, 0.16), Vector3(0, 0.44, -0.08), Vector3(0, 0.43, -0.22), Vector3(0, 0.55, -0.27), 12)
	_curve(shell_path, Vector3(0, 0.55, -0.27), Vector3(0, 0.65, -0.30), Vector3(0, 0.84, -0.37), Vector3(0, 0.945, -0.37), 14)
	var shell: ArrayMesh = _sweep("seat_shell", shell_path, 0.91, 0.042, 0.015)
	for seat in 6:
		var x: float = -2.5 + float(seat)
		Kit.add(root, shell, oak, Vector3(x, 0, 0))
		# A thin welt below each padded inset leaves the waterfall oak nose exposed.
		Kit.rbox(root, Vector3(0.785, 0.033, 0.365), Vector3(x, 0.479, 0.045), piping, 0.016)
		Kit.rbox(root, Vector3(0.77, 0.041, 0.35), Vector3(x, 0.491, 0.045), cloth, 0.02)
		# Brass dowel heads secure each shell to the rear rail.
		for offset: float in [-0.30, 0.30]:
			Kit.rbox(root, Vector3(0.018, 0.018, 0.006), Vector3(x + offset, 0.89, -0.342), brass, 0.008, false)
	# Continuous rounded rails tie the six individually bent shells together.
	Kit.rbox(root, Vector3(5.86, 0.055, 0.065), Vector3(0, 0.925, -0.405), oak, 0.025)
	Kit.rbox(root, Vector3(5.7, 0.07, 0.08), Vector3(0, 0.38, -0.19), steel, 0.025)
	Kit.rbox(root, Vector3(5.7, 0.07, 0.08), Vector3(0, 0.38, 0.23), steel, 0.025)
	for x: float in [-2.55, -0.85, 0.85, 2.55]:
		# Broad, low runners with concealed levelling pads make floor contact at y=0.
		for z: float in [-0.22, 0.23]:
			Kit.rbox(root, Vector3(0.10, 0.02, 0.09), Vector3(x, 0.01, z), dark, 0.009)
		Kit.rbox(root, Vector3(0.105, 0.06, 0.62), Vector3(x, 0.05, 0.005), steel, 0.025)
		Kit.rbox(root, Vector3(0.075, 0.285, 0.11), Vector3(x, 0.218, -0.07), steel, 0.025)
		Kit.rbox(root, Vector3(0.09, 0.028, 0.12), Vector3(x, 0.09, -0.07), brass, 0.01)
	var arm_path: PackedVector3Array = PackedVector3Array()
	_curve(arm_path, Vector3(0, 0.40, -0.28), Vector3(0, 0.64, -0.32), Vector3(0, 0.665, -0.26), Vector3(0, 0.665, -0.12), 12)
	_curve(arm_path, Vector3(0, 0.665, -0.12), Vector3(0, 0.665, 0.08), Vector3(0, 0.665, 0.24), Vector3(0, 0.62, 0.29), 12)
	var arm: ArrayMesh = _sweep("bent_arm", arm_path, 0.11, 0.065, 0.022)
	for x: float in [-2.945, 2.945]:
		Kit.add(root, arm, oak, Vector3(x, 0, 0))
		Kit.rbox(root, Vector3(0.035, 0.22, 0.045), Vector3(x, 0.49, 0.19), steel, 0.016)
	# Two shared arm consoles occupy the gaps between seats, with forward-facing outlets.
	for x: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.07, 0.24, 0.12), Vector3(x, 0.49, 0.10), steel, 0.022)
		Kit.rbox(root, Vector3(0.24, 0.12, 0.43), Vector3(x, 0.63, 0.075), walnut, 0.045)
		Kit.rbox(root, Vector3(0.194, 0.084, 0.014), Vector3(x, 0.624, 0.294), brass, 0.017, false)
		Kit.rbox(root, Vector3(0.18, 0.072, 0.012), Vector3(x, 0.624, 0.303), dark, 0.014, false)
		# Recessed universal AC socket and a USB-C aperture with an inner tongue.
		Kit.rbox(root, Vector3(0.065, 0.058, 0.006), Vector3(x - 0.043, 0.624, 0.311), Kit.paint(Kit.PLASTER), 0.014, false)
		for dx: float in [-0.017, 0.017]:
			Kit.rbox(root, Vector3(0.012, 0.022, 0.004), Vector3(x - 0.043 + dx, 0.631, 0.315), dark, 0.004, false)
		Kit.rbox(root, Vector3(0.012, 0.012, 0.004), Vector3(x - 0.043, 0.61, 0.315), dark, 0.005, false)
		Kit.rbox(root, Vector3(0.034, 0.014, 0.006), Vector3(x + 0.044, 0.627, 0.311), brass, 0.006, false)
		Kit.rbox(root, Vector3(0.028, 0.008, 0.007), Vector3(x + 0.044, 0.627, 0.315), dark, 0.003, false)
		Kit.rbox(root, Vector3(0.018, 0.0025, 0.008), Vector3(x + 0.044, 0.627, 0.316), Kit.paint(Kit.PLASTER), 0.001, false)
		Kit.rbox(root, Vector3(0.014, 0.005, 0.004), Vector3(x + 0.044, 0.605, 0.312), Kit.washi(Kit.SAGE.lightened(0.25), 0.6, "long_bench_power_led"), 0.002, false)
	# The recessed cable raceway doubles as a legible international charging identifier.
	Kit.rbox(root, Vector3(5.55, 0.195, 0.075), Vector3(0, 0.275, 0.23), steel, 0.028)
	var caption: Label3D = Label3D.new()
	caption.font = Signs.font()
	caption.text = "Power · 充電 · 充电 · Điện · Prise · Enchufe"
	caption.font_size = 72
	caption.pixel_size = 0.0021
	caption.modulate = Kit.CREAM
	caption.outline_size = 0
	caption.position = Vector3(0, 0.277, 0.27)
	caption.double_sided = false
	caption.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(caption)
	return root


static func _curve(points: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, steps: int) -> void:
	for i in range(0 if points.is_empty() else 1, steps + 1):
		var t: float = float(i) / float(steps)
		var u: float = 1.0 - t
		points.append(a * u * u * u + b * 3.0 * u * u * t + c * 3.0 * u * t * t + d * t * t * t)


## Sweep a softly bevelled section along a continuous bent-lamination centreline.
static func _sweep(key: String, path: PackedVector3Array, width: float, thickness: float, radius: float) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var section: PackedVector2Array = PackedVector2Array()
	var normals: PackedVector2Array = PackedVector2Array()
	for corner in 4:
		var angle: float = float(corner) * PI * 0.5
		var centre: Vector2 = Vector2((width * 0.5 - radius) * (1.0 if corner == 0 or corner == 3 else -1.0), (thickness * 0.5 - radius) * (1.0 if corner < 2 else -1.0))
		for step in 5:
			var theta: float = angle + float(step) * PI / 8.0
			var normal: Vector2 = Vector2(cos(theta), sin(theta))
			section.append(centre + normal * radius)
			normals.append(normal)
	var vertices: PackedVector3Array = PackedVector3Array()
	var surface_normals: PackedVector3Array = PackedVector3Array()
	for i in path.size():
		var tangent: Vector3 = (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var up: Vector3 = Vector3(0, -tangent.z, tangent.y)
		for j in section.size():
			vertices.append(path[i] + Vector3.RIGHT * section[j].x + up * section[j].y)
			surface_normals.append(Vector3.RIGHT * normals[j].x + up * normals[j].y)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int = section.size()
	for i in path.size() - 1:
		for j in count:
			var a: int = i * count + j
			var b: int = (i + 1) * count + j
			var c: int = (i + 1) * count + (j + 1) % count
			var d: int = i * count + (j + 1) % count
			for index: int in [a, c, b, a, d, c]:
				st.set_normal(surface_normals[index])
				st.set_uv(Vector2(float(index % count) / float(count), float(index / count) / float(path.size() - 1)))
				st.add_vertex(vertices[index])
	for end in 2:
		var row: int = 0 if end == 0 else path.size() - 1
		var outward: Vector3 = (path[0] - path[1]).normalized() if end == 0 else (path[row] - path[row - 1]).normalized()
		for j in count:
			var first: int = (j + 1) % count if end == 0 else j
			var second: int = j if end == 0 else (j + 1) % count
			for vertex: Vector3 in [path[row], vertices[row * count + first], vertices[row * count + second]]:
				st.set_normal(outward)
				st.set_uv(Vector2(vertex.x / width + 0.5, vertex.y))
				st.add_vertex(vertex)
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh
