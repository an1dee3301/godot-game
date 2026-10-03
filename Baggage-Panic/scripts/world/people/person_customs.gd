extends RefCounted
## Calm, approachable customs staff; +Z is the face, shoe soles touch y = 0.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CustomsOfficer"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 3)
	var blues: Array[Color] = [Color(0.57, 0.75, 0.84), Color(0.66, 0.81, 0.87), Color(0.52, 0.70, 0.80)]
	var skins: Array[Color] = [Color(0.76, 0.52, 0.36), Color(0.91, 0.72, 0.56), Color(0.52, 0.33, 0.24)]
	var hair_colors: Array[Color] = [Kit.CHARCOAL, Kit.WALNUT, Color(0.30, 0.29, 0.27)]
	var shirt: Material = Kit.fabric(blues[style], "customs_blue_%d" % style)
	var trousers: Material = Kit.fabric(Kit.INDIGO if style != 2 else Kit.CHARCOAL, "customs_trousers_%d" % style)
	var skin: Material = Kit.paint(skins[style], 0.88)
	var hair: Material = Kit.paint(hair_colors[style], 0.94)
	var leather: Material = Kit.paint(Kit.CHARCOAL.darkened(0.25), 0.47)
	var trim: Material = Kit.fabric(Kit.INDIGO, "customs_rank")
	var brass: Material = Kit.brass()

	# Broad, softly rounded shoes with the toes projecting toward the viewer.
	for side: float in [-1.0, 1.0]:
		var x: float = side * 0.105
		_oval(root, Vector3(x, 0.075, 0.055), Vector3(0.092, 0.075, 0.175), leather)
		_limb(root, Vector3(x, 0.19, 0.0), Vector3(x, 0.78, 0.0), 0.084, trousers)
	_oval(root, Vector3(0.0, 0.80, 0.0), Vector3(0.19, 0.13, 0.12), trousers)
	var torso: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.85), Vector2(0.17, 0.85), Vector2(0.185, 0.90),
		Vector2(0.205, 1.19), Vector2(0.23, 1.27), Vector2(0.20, 1.32),
		Vector2(0.09, 1.36), Vector2(0.0, 1.36)
	]), 12), shirt, Vector3.ZERO)
	torso.scale.z = 0.65
	var belt: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.865), Vector2(0.18, 0.865), Vector2(0.185, 0.88),
		Vector2(0.185, 0.915), Vector2(0.18, 0.925), Vector2(0.0, 0.925)
	]), 12), leather, Vector3.ZERO)
	belt.scale.z = 0.68
	Kit.rbox(root, Vector3(0.065, 0.045, 0.018), Vector3(0.0, 0.895, 0.13), brass, 0.009)

	_limb(root, Vector3(0.0, 1.34, 0.0), Vector3(0.0, 1.43, 0.0), 0.067, skin)
	_oval(root, Vector3(0.0, 1.535, 0.008), Vector3(0.175, 0.205, 0.153), skin)
	for side: float in [-1.0, 1.0]:
		_oval(root, Vector3(side * 0.17, 1.525, 0.008), Vector3(0.034, 0.048, 0.028), skin)
		_oval(root, Vector3(side * 0.061, 1.56, 0.15), Vector3(0.013, 0.018, 0.009), leather)
	_oval(root, Vector3(0.0, 1.522, 0.159), Vector3(0.028, 0.032, 0.029), skin)
	# Hair is a turned crown rather than a second sphere covering the face.
	var crown: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.163, 0.0), Vector2(0.178, 0.055),
		Vector2(0.153, 0.115), Vector2(0.095, 0.16), Vector2(0.0, 0.175)
	]), 12), hair, Vector3(0.0, 1.58, -0.024))
	crown.scale.z = 0.86
	var fringe: MeshInstance3D = _oval(root, Vector3(-0.061, 1.665, 0.10), Vector3(0.11, 0.043, 0.051), hair)
	fringe.rotation_degrees.z = -18.0
	if style == 1:
		_oval(root, Vector3(0.0, 1.62, -0.178), Vector3(0.085, 0.085, 0.070), hair)

	# Short sleeves and relaxed elbows; one hand steadies the inspection clipboard.
	for side: float in [-1.0, 1.0]:
		var shoulder: Vector3 = Vector3(side * 0.235, 1.265, 0.0)
		var elbow: Vector3 = Vector3(side * 0.29, 1.115, 0.015)
		var wrist: Vector3 = Vector3(side * 0.33, 0.955, 0.12 if side > 0.0 else 0.035)
		_limb(root, shoulder, elbow, 0.078, shirt)
		_limb(root, elbow, wrist, 0.049, skin)
		_oval(root, wrist, Vector3(0.050, 0.062, 0.042), skin)
		var epaulette: MeshInstance3D = Kit.rbox(root, Vector3(0.115, 0.027, 0.08), Vector3(side * 0.198, 1.325, 0.0), trim, 0.012)
		epaulette.rotation_degrees.z = -side * 12.0
		Kit.rbox(root, Vector3(0.017, 0.009, 0.065), Vector3(side * 0.21, 1.344, 0.005), brass, 0.004, false)
		var collar: MeshInstance3D = Kit.rbox(root, Vector3(0.084, 0.075, 0.022), Vector3(side * 0.047, 1.295, 0.121), shirt, 0.01)
		collar.rotation_degrees.z = side * 26.0
	Kit.rbox(root, Vector3(0.018, 0.31, 0.015), Vector3(0.0, 1.105, 0.142), shirt, 0.006, false)
	Kit.rbox(root, Vector3(0.09, 0.074, 0.018), Vector3(-0.104, 1.185, 0.132), trim, 0.013)
	# Reuse the international signage shield as a readable badge, with no tiny caption.
	var badge_mesh: QuadMesh = _badge()
	Kit.add(root, badge_mesh, Signs._icon_material("shield", Color(0, 0, 0, 0)), Vector3(0.104, 1.205, 0.143), Vector3.ZERO, false)

	var clipboard: Node3D = Node3D.new()
	clipboard.name = "InspectionClipboard"
	clipboard.position = Vector3(0.365, 0.99, 0.16)
	clipboard.rotation_degrees = Vector3(-12.0, -8.0, -10.0)
	root.add_child(clipboard)
	Kit.rbox(clipboard, Vector3(0.20, 0.265, 0.024), Vector3.ZERO, Kit.wood(Kit.WALNUT, "customs_clipboard"), 0.018)
	Kit.rbox(clipboard, Vector3(0.168, 0.223, 0.006), Vector3(0.0, -0.007, 0.016), Kit.paint(Kit.CREAM), 0.006)
	Kit.rbox(clipboard, Vector3(0.066, 0.029, 0.015), Vector3(0.0, 0.112, 0.02), brass, 0.006)
	if style == 2:
		Kit.rbox(root, Vector3(0.063, 0.115, 0.043), Vector3(-0.20, 0.89, 0.025), Kit.metal(), 0.014)
	return root


static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var key: String = "capsule:%0.4f:%0.4f" % [radius, height]
	if _meshes.has(key):
		return _meshes[key] as CapsuleMesh
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
	mesh.radial_segments = 12
	mesh.rings = 4
	_meshes[key] = mesh
	return mesh


static func _oval(parent: Node3D, at: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	var node: MeshInstance3D = Kit.add(parent, _capsule(1.0, 2.0), material, at)
	node.scale = radii
	return node


static func _limb(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var direction: Vector3 = end - start
	var node: MeshInstance3D = Kit.add(parent, _capsule(radius, direction.length() + radius * 2.0), material, (start + end) * 0.5)
	node.quaternion = Quaternion(Vector3.UP, direction.normalized())
	return node


static func _badge() -> QuadMesh:
	if _meshes.has("badge"):
		return _meshes["badge"] as QuadMesh
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.084, 0.098)
	_meshes["badge"] = mesh
	return mesh
