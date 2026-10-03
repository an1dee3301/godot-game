extends RefCounted
## A plane spotter caught mid-shot: bent elbows, supporting palm, and a long lens.

const KIT = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "TravellerPhotographer"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 3)
	var coats: Array[Color] = [KIT.SAGE, KIT.CLAY, KIT.LINEN]
	var trousers: Array[Color] = [KIT.LINEN, KIT.INDIGO, KIT.WALNUT]
	var skins: Array[Color] = [Color(0.76, 0.53, 0.36), Color(0.46, 0.29, 0.20), Color(0.91, 0.70, 0.53)]
	var coat: Material = KIT.fabric(coats[style], "photographer_coat_%d" % style)
	var pants: Material = KIT.fabric(trousers[style], "photographer_pants_%d" % style)
	var skin: Material = KIT.paint(skins[style], 0.85)
	var hair: Material = KIT.paint(KIT.CHARCOAL if style != 2 else KIT.WALNUT, 0.95)
	var cream: Material = KIT.fabric(KIT.CREAM, "photographer_collar")
	var rubber: Material = KIT.paint(KIT.CHARCOAL, 0.9)
	var camera_metal: Material = KIT.metal(KIT.CHARCOAL, 0.36, 0.65, "photographer_camera")
	var leather: Material = KIT.fabric(KIT.WALNUT, "photographer_strap")

	# Both soles touch the floor; the rear foot anchors the raised-camera pose.
	for side: int in 2:
		var x: float = -0.13 if side == 0 else 0.13
		var z: float = 0.10 if side == 0 else -0.10
		_oval(root, Vector3(x, 0.025, z + 0.04), Vector3(0.19, 0.05, 0.32), rubber)
		_oval(root, Vector3(x, 0.095, z + 0.025), Vector3(0.18, 0.15, 0.29), cream)
		_link(root, Vector3(x, 0.18, z), Vector3(x * 0.85, 0.88, 0.0), 0.085, pants)
	_oval(root, Vector3(0.0, 0.85, 0.0), Vector3(0.36, 0.23, 0.24), pants)
	var body: MeshInstance3D = KIT.add(root, KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.18, 0.0), Vector2(0.205, 0.05),
		Vector2(0.20, 0.29), Vector2(0.235, 0.40), Vector2(0.20, 0.46),
		Vector2(0.09, 0.50), Vector2(0.0, 0.50)]), 16), coat, Vector3(0.0, 0.85, 0.0))
	body.scale.z = 0.70
	_oval(root, Vector3(0.0, 1.335, 0.0), Vector3(0.19, 0.08, 0.17), cream)
	_link(root, Vector3(0.0, 1.32, 0.0), Vector3(0.0, 1.43, 0.0), 0.065, skin)
	_oval(root, Vector3(0.0, 1.515, 0.025), Vector3(0.365, 0.415, 0.35), skin)
	for x: float in [-0.183, 0.183]:
		_oval(root, Vector3(x, 1.51, 0.02), Vector3(0.055, 0.10, 0.07), skin)
	_oval(root, Vector3(0.0, 1.50, 0.199), Vector3(0.05, 0.065, 0.06), skin)
	var crown: MeshInstance3D = KIT.add(root, KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.19, 0.0), Vector2(0.20, 0.05),
		Vector2(0.175, 0.14), Vector2(0.11, 0.205), Vector2(0.0, 0.225)]), 16), hair, Vector3(0.0, 1.52, -0.012))
	crown.scale.z = 0.88
	# The visible left eye peeks past the viewfinder; the camera hides the right eye.
	_oval(root, Vector3(-0.075, 1.565, 0.186), Vector3(0.025, 0.028, 0.013), rubber)

	var left_shoulder: Vector3 = Vector3(-0.205, 1.26, 0.0)
	var right_shoulder: Vector3 = Vector3(0.205, 1.26, 0.0)
	var left_elbow: Vector3 = Vector3(-0.34, 1.14, 0.24)
	var right_elbow: Vector3 = Vector3(0.34, 1.23, 0.22)
	_link(root, left_shoulder, left_elbow, 0.085, coat)
	_link(root, right_shoulder, right_elbow, 0.085, coat)
	_link(root, left_elbow, Vector3(-0.09, 1.405, 0.46), 0.052, skin)
	_link(root, right_elbow, Vector3(0.19, 1.49, 0.31), 0.052, skin)
	_oval(root, Vector3(-0.09, 1.42, 0.48), Vector3(0.115, 0.07, 0.15), skin)
	_oval(root, Vector3(0.185, 1.495, 0.32), Vector3(0.09, 0.12, 0.11), skin)

	# Camera strap drapes forward from the shoulders, framing the linen jacket.
	_link(root, Vector3(-0.10, 1.31, 0.10), Vector3(-0.16, 1.07, 0.21), 0.014, leather)
	_link(root, Vector3(-0.16, 1.07, 0.21), Vector3(-0.12, 1.46, 0.30), 0.014, leather)
	_link(root, Vector3(0.11, 1.31, 0.10), Vector3(0.15, 1.47, 0.30), 0.014, leather)
	KIT.rbox(root, Vector3(0.29, 0.18, 0.14), Vector3(0.035, 1.51, 0.30), camera_metal, 0.035)
	KIT.rbox(root, Vector3(0.075, 0.155, 0.15), Vector3(0.158, 1.50, 0.31), KIT.wood(KIT.WALNUT, "photographer_grip"), 0.026)
	KIT.rbox(root, Vector3(0.10, 0.055, 0.105), Vector3(0.045, 1.615, 0.29), camera_metal, 0.017)
	# Turned barrel, brass mount, ribbed focus ring and blue-coated front glass.
	_lens(root, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.09, 0.0), Vector2(0.09, 0.025), Vector2(0.0, 0.025)]), 0.37, KIT.brass())
	_lens(root, PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.077, 0.0), Vector2(0.077, 0.04),
		Vector2(0.087, 0.045), Vector2(0.087, 0.06), Vector2(0.082, 0.065),
		Vector2(0.087, 0.075), Vector2(0.082, 0.085), Vector2(0.087, 0.095),
		Vector2(0.082, 0.105), Vector2(0.084, 0.19), Vector2(0.096, 0.205),
		Vector2(0.096, 0.23), Vector2(0.071, 0.23), Vector2(0.071, 0.21), Vector2(0.0, 0.21)]), 0.39, camera_metal)
	_lens(root, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.07, 0.0), Vector2(0.07, 0.005), Vector2(0.0, 0.005)]), 0.607, KIT.metal(Color(0.09, 0.24, 0.30), 0.14, 0.72, "photographer_glass"))
	# Reuse the shared plane pictogram for the rear screen, without miniature text.
	if not _meshes.has("screen"):
		var screen: QuadMesh = QuadMesh.new()
		screen.size = Vector2(0.115, 0.09)
		_meshes["screen"] = screen
	var screen_mesh: Mesh = _meshes["screen"]
	KIT.add(root, screen_mesh, SIGNS._icon_material("plane", Color(0.08, 0.15, 0.18)), Vector3(-0.005, 1.505, 0.228), Vector3(0.0, 180.0, 0.0), false)

	if style == 1:
		_oval(root, Vector3(0.0, 1.66, -0.19), Vector3(0.16, 0.16, 0.15), hair)
	else:
		var cap: Material = KIT.fabric(KIT.INDIGO if style == 0 else KIT.SAGE, "photographer_cap_%d" % style)
		_oval(root, Vector3(0.0, 1.687, -0.01), Vector3(0.40, 0.14, 0.36), cap)
		_oval(root, Vector3(0.0, 1.65, 0.18), Vector3(0.35, 0.035, 0.25), cap)
	if style == 2:
		KIT.rbox(root, Vector3(0.17, 0.28, 0.22), Vector3(0.275, 0.94, -0.035), leather, 0.07)
		KIT.rbox(root, Vector3(0.18, 0.09, 0.235), Vector3(0.275, 1.045, -0.025), coat, 0.025)
		_link(root, Vector3(0.22, 1.25, -0.045), Vector3(0.27, 1.045, -0.045), 0.015, leather)
	return root


static func _oval(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	if not _meshes.has("oval"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 16
		sphere.rings = 8
		_meshes["oval"] = sphere
	var mesh: Mesh = _meshes["oval"]
	var part: MeshInstance3D = KIT.add(parent, mesh, material, at)
	part.scale = size


static func _link(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var length: float = start.distance_to(end)
	var key: String = "capsule:%.4f:%.4f" % [radius, length]
	if not _meshes.has(key):
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = radius
		capsule.height = length + radius * 2.0
		capsule.radial_segments = 12
		capsule.rings = 4
		_meshes[key] = capsule
	var mesh: Mesh = _meshes[key]
	var part: MeshInstance3D = KIT.add(parent, mesh, material, (start + end) * 0.5)
	var axis: Vector3 = (end - start).normalized()
	var tangent: Vector3 = Vector3.RIGHT
	if absf(axis.dot(tangent)) > 0.95:
		tangent = Vector3.FORWARD
	var z_axis: Vector3 = tangent.cross(axis).normalized()
	part.basis = Basis(axis.cross(z_axis).normalized(), axis, z_axis)


static func _lens(parent: Node3D, profile: PackedVector2Array, z: float, material: Material) -> void:
	KIT.add(parent, KIT.lathe(profile, 20), material, Vector3(0.015, 1.515, z), Vector3(90.0, 0.0, 0.0))
