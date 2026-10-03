extends RefCounted
## Two adult travellers in a shared stride, with one quietly crafted carry-on.

const KIT = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "WalkingCouple"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var palette: int = posmod(variant, 3)
	var coats: Array[Color] = [KIT.SAGE, KIT.CLAY, KIT.INDIGO]
	var partners: Array[Color] = [KIT.LINEN, KIT.SAGE, KIT.CREAM]
	var skins: Array[Color] = [Color(0.76, 0.53, 0.38), Color(0.91, 0.71, 0.54), Color(0.52, 0.34, 0.25)]
	var coat: Color = coats[palette]
	var partner_coat: Color = partners[palette]
	var skin: Color = skins[palette]
	_person(root, -0.27, 1.0, coat, skin, false, palette)
	_person(root, 0.29, 0.93, partner_coat, skins[(palette + 1) % 3], true, palette)
	_suitcase(root, palette)
	return root


static func _person(parent: Node3D, x: float, stature: float, tint: Color, skin_tint: Color, partner: bool, palette: int) -> void:
	var figure: Node3D = Node3D.new()
	figure.name = "Companion" if partner else "SuitcaseTraveller"
	figure.position.x = x
	figure.scale = Vector3.ONE * stature
	parent.add_child(figure)
	var cloth: Material = KIT.fabric(tint, "couple_coat_%d_%s" % [palette, partner])
	var trousers: Material = KIT.fabric(KIT.WALNUT if partner else KIT.CHARCOAL, "couple_trousers_%s" % partner)
	var skin: Material = KIT.paint(skin_tint, 0.88)
	var hair: Material = KIT.paint(KIT.WALNUT if palette == 1 else KIT.CHARCOAL, 0.95)
	var shoes: Material = KIT.paint(KIT.CREAM if partner else KIT.WALNUT, 0.8)
	# A tapered, softly shouldered jacket rather than a rectangular torso.
	var torso: MeshInstance3D = KIT.add(figure, KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.75), Vector2(0.17, 0.75), Vector2(0.20, 0.80),
		Vector2(0.195, 1.10), Vector2(0.215, 1.22), Vector2(0.18, 1.31),
		Vector2(0.08, 1.35), Vector2(0.0, 1.35)
	]), 12), cloth, Vector3.ZERO)
	torso.scale.z = 0.73
	# A contrasting rolled collar also bridges the coat to the head.
	KIT.add(figure, KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.09, 0.0), Vector2(0.10, 0.035),
		Vector2(0.08, 0.085), Vector2(0.0, 0.085)
	]), 12), KIT.fabric(KIT.OCHRE if partner else KIT.CREAM, "couple_collar_%s" % partner), Vector3(0.0, 1.30, 0.0))
	var head: MeshInstance3D = _capsule(figure, Vector3(0.0, 1.55, 0.015), 0.16, 0.37, skin)
	head.scale.z = 0.88
	# The hair crown stays behind the face; the companion has a low bun or ponytail.
	var crown: MeshInstance3D = KIT.add(figure, KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.165, 0.0), Vector2(0.166, 0.055),
		Vector2(0.135, 0.135), Vector2(0.07, 0.18), Vector2(0.0, 0.19)
	]), 12), hair, Vector3(0.0, 1.59, -0.018))
	crown.scale.z = 0.91
	if partner:
		_capsule(figure, Vector3(0.0, 1.60 if palette != 2 else 1.48, -0.16), 0.073, 0.15 if palette != 2 else 0.24, hair)
	for eye_x: float in [-0.055, 0.055]:
		_capsule(figure, Vector3(eye_x, 1.56, 0.151), 0.013, 0.032, KIT.paint(KIT.CHARCOAL), false)
	# Opposing foot placements make an unambiguous walking silhouette.
	for side: int in [-1, 1]:
		var stride: float = float(side) * (0.13 if partner else -0.13)
		_link(figure, Vector3(float(side) * 0.085, 0.80, 0.0), Vector3(float(side) * 0.105, 0.15, stride), 0.073, trousers)
		var shoe: MeshInstance3D = _capsule(figure, Vector3(float(side) * 0.105, 0.071, stride + 0.055), 0.065, 0.27, shoes)
		shoe.rotation_degrees.x = 90.0
		shoe.scale.z = 1.09
	# The inner arms converge on one shared hand, with no floating accessory.
	var inner: float = -1.0 if partner else 1.0
	var joined: Vector3 = Vector3((-0.27 if partner else 0.27) / stature, 0.89 / stature, 0.09 / stature)
	_link(figure, Vector3(inner * 0.19, 1.23, 0.0), joined, 0.062, cloth)
	if not partner:
		_capsule(figure, joined, 0.048, 0.11, skin)
	var outer_hand: Vector3 = Vector3(0.30, 0.87, 0.18) if partner else Vector3(-0.42, 0.98, -0.29)
	_link(figure, Vector3(-inner * 0.19, 1.23, 0.0), outer_hand, 0.065, cloth)
	_capsule(figure, outer_hand, 0.043, 0.105, skin)


static func _suitcase(parent: Node3D, palette: int) -> void:
	var case_root: Node3D = Node3D.new()
	case_root.name = "RollingCarryOn"
	case_root.position = Vector3(-0.69, 0.065, -0.49)
	case_root.rotation_degrees.x = 12.0
	parent.add_child(case_root)
	var shell: Material = KIT.paint(KIT.CLAY if palette != 1 else KIT.SAGE, 0.5)
	var dark: Material = KIT.metal()
	# The dark centre band reads as a zipper between two softened shell halves.
	KIT.rbox(case_root, Vector3(0.365, 0.585, 0.235), Vector3(0.0, 0.32, 0.0), dark, 0.07)
	for face: float in [-1.0, 1.0]:
		KIT.rbox(case_root, Vector3(0.36, 0.58, 0.116), Vector3(0.0, 0.32, face * 0.064), shell, 0.055)
	for wheel_x: float in [-0.145, 0.145]:
		var wheel: MeshInstance3D = _capsule(case_root, Vector3(wheel_x, 0.0, 0.0), 0.065, 0.075 * 2.0, KIT.paint(KIT.CHARCOAL))
		wheel.rotation_degrees.z = 90.0
		_link(case_root, Vector3(wheel_x * 0.62, 0.57, -0.025), Vector3(wheel_x * 0.62, 0.925, -0.025), 0.012, KIT.brass())
	_link(case_root, Vector3(-0.105, 0.925, -0.025), Vector3(0.105, 0.925, -0.025), 0.026, dark)
	# A broad raised rib catches light, with a luggage pictogram instead of tiny text.
	KIT.rbox(case_root, Vector3(0.022, 0.40, 0.022), Vector3(-0.085, 0.32, 0.128), KIT.brass(), 0.009, false)
	if not _meshes.has("tag"):
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(0.105, 0.105)
		_meshes["tag"] = quad
	var tag_mesh: Mesh = _meshes["tag"]
	KIT.add(case_root, tag_mesh, SIGNS._icon_material("suitcase", KIT.CREAM), Vector3(0.067, 0.46, 0.127), Vector3.ZERO, false)


static func _capsule(parent: Node3D, at: Vector3, radius: float, height: float, material: Material, shadows: bool = true) -> MeshInstance3D:
	var key: String = "capsule:%.4f:%.4f" % [radius, height]
	if not _meshes.has(key):
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = radius
		capsule.height = maxf(height, radius * 2.0)
		capsule.radial_segments = 12
		capsule.rings = 4
		_meshes[key] = capsule
	var mesh: Mesh = _meshes[key]
	return KIT.add(parent, mesh, material, at, Vector3.ZERO, shadows)


static func _link(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var direction: Vector3 = end - start
	var part: MeshInstance3D = _capsule(parent, (start + end) * 0.5, radius, direction.length() + radius * 2.0, material)
	part.quaternion = Quaternion(Vector3.UP, direction.normalized())
	return part
