extends RefCounted
## A calm checkpoint officer: tailored cloth, peaked cap and a readable sage lanyard.
## Identity is pictographic; the badge deliberately carries no miniature text.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "SecurityOfficer"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var roles: Array = Signs.TEXT["security"]
	root.set_meta("role_translations", roles.slice(0, 6))
	var style: int = posmod(variant, 3)
	var uniforms: Array[Color] = [Color(0.12, 0.17, 0.22), Color(0.18, 0.21, 0.19), Color(0.20, 0.19, 0.23)]
	var skins: Array[Color] = [Color(0.73, 0.49, 0.34), Color(0.90, 0.69, 0.51), Color(0.42, 0.27, 0.20)]
	var hairs: Array[Color] = [Color(0.12, 0.10, 0.09), Kit.WALNUT, Color(0.34, 0.32, 0.29)]
	var uniform_color: Color = uniforms[style]
	var cloth: Material = Kit.fabric(uniform_color, "security_uniform_%d" % style)
	var trousers: Material = Kit.fabric(uniform_color.darkened(0.15), "security_trousers_%d" % style)
	var skin: Material = Kit.paint(skins[style], 0.88)
	var hair: Material = Kit.paint(hairs[style], 0.95)
	var leather: Material = Kit.paint(Kit.CHARCOAL.darkened(0.32), 0.45)
	var sole: Material = Kit.paint(Color(0.055, 0.06, 0.065), 0.95)
	var sage: Material = Kit.fabric(Kit.SAGE if style != 2 else Kit.CLAY, "security_lanyard_%d" % style)
	var brass: Material = Kit.brass()
	var ink: Material = Kit.paint(Kit.CHARCOAL.darkened(0.55))
	# Rounded shoes have distinct rubber soles; their underside touches y = 0 exactly.
	for side: float in [-1.0, 1.0]:
		var x: float = side * 0.115
		var shoe: MeshInstance3D = _capsule(root, Vector3(x, 0.035, 0.052), 0.10, 0.26, sole)
		shoe.rotation_degrees.x = 90.0
		shoe.scale = Vector3(1.0, 1.30, 0.35)
		var upper: MeshInstance3D = _capsule(root, Vector3(x, 0.095, 0.05), 0.09, 0.25, leather)
		upper.rotation_degrees.x = 90.0
		upper.scale = Vector3(1.0, 1.23, 0.70)
		_limb(root, Vector3(x, 0.17, 0.0), Vector3(x, 0.86, 0.0), 0.088, trousers)
	# Turned tailoring: a broad shoulder taper, soft hips and a fitted waist.
	_capsule(root, Vector3(0.0, 0.855, 0.0), 0.17, 0.34, trousers).scale = Vector3(1.22, 0.70, 0.77)
	var torso: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.16, 0.0), Vector2(0.19, 0.05),
		Vector2(0.195, 0.23), Vector2(0.23, 0.39), Vector2(0.22, 0.45),
		Vector2(0.10, 0.51), Vector2(0.0, 0.51)]), 12), cloth, Vector3(0.0, 0.86, 0.0))
	torso.scale = Vector3(1.0, 1.0, 0.67)
	var belt: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.192, 0.0), Vector2(0.196, 0.008),
		Vector2(0.196, 0.045), Vector2(0.192, 0.053), Vector2(0.0, 0.053)]), 16), leather, Vector3(0.0, 0.89, 0.0))
	belt.scale.z = 0.70
	Kit.rbox(root, Vector3(0.065, 0.041, 0.012), Vector3(0.0, 0.916, 0.141), brass, 0.009)
	_capsule(root, Vector3(0.0, 1.365, 0.0), 0.066, 0.16, skin)
	_capsule(root, Vector3(0.0, 1.51, 0.01), 0.18, 0.37, skin).scale = Vector3(0.96, 1.0, 0.84)
	for side: float in [-1.0, 1.0]:
		_capsule(root, Vector3(side * 0.173, 1.505, 0.0), 0.031, 0.071, skin).scale.z = 0.65
		_capsule(root, Vector3(side * 0.058, 1.548, 0.153), 0.013, 0.028, ink).scale.z = 0.42
	_capsule(root, Vector3(0.0, 1.502, 0.17), 0.024, 0.052, skin).scale = Vector3(0.85, 0.7, 1.0)
	var hairline: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.164, 0.0), Vector2(0.18, 0.045),
		Vector2(0.15, 0.105), Vector2(0.0, 0.13)]), 12), hair, Vector3(0.0, 1.591, -0.018))
	hairline.scale.z = 0.86
	# A softly crowned peaked cap, with a leather visor and brass service medallion.
	var cap: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.18, 0.0), Vector2(0.205, 0.025),
		Vector2(0.21, 0.07), Vector2(0.185, 0.115), Vector2(0.0, 0.12)]), 16), cloth, Vector3(0.0, 1.65, -0.005))
	cap.scale.z = 0.85
	var band: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.183, 0.0), Vector2(0.185, 0.03), Vector2(0.0, 0.03)]), 16), leather, Vector3(0.0, 1.646, -0.005))
	band.scale.z = 0.86
	var visor: MeshInstance3D = _capsule(root, Vector3(0.0, 1.652, 0.172), 0.09, 0.32, leather)
	visor.rotation_degrees.z = 90.0
	visor.scale = Vector3(0.16, 1.0, 1.0)
	_capsule(root, Vector3(0.0, 1.704, 0.174), 0.023, 0.057, brass).scale.z = 0.22
	# Sleeves and hands describe a relaxed, subtly welcoming asymmetrical stance.
	for side: float in [-1.0, 1.0]:
		var shoulder: Vector3 = Vector3(side * 0.219, 1.275, 0.0)
		var elbow: Vector3 = Vector3(side * 0.29, 1.08, 0.025)
		var wrist: Vector3 = Vector3(side * 0.32, 0.94, 0.12)
		if side > 0.0 and style == 1:
			wrist = Vector3(0.42, 1.10, 0.19)
		_limb(root, shoulder, elbow, 0.075, cloth)
		_limb(root, elbow, wrist, 0.063, cloth)
		_limb(root, wrist.lerp(elbow, 0.10), wrist, 0.065, trousers)
		_capsule(root, wrist + Vector3(0.0, -0.033, 0.013), 0.048, 0.11, skin)
		var collar: MeshInstance3D = Kit.rbox(root, Vector3(0.074, 0.092, 0.02), Vector3(side * 0.059, 1.31, 0.129), Kit.fabric(Kit.LINEN, "security_collar"), 0.013)
		collar.rotation_degrees.z = side * 28.0
		_limb(root, Vector3(side * 0.077, 1.33, 0.149), Vector3(0.0, 1.10, 0.154), 0.009, sage)
	# Brass-backed ID with a bold abstract shield, never an illegible tiny label.
	Kit.rbox(root, Vector3(0.09, 0.116, 0.018), Vector3(0.0, 1.07, 0.166), brass, 0.016)
	var shield: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.028, 0.028), Vector2(0.031, 0.068),
		Vector2(0.0, 0.078)]), 4), Kit.paint(Kit.CREAM), Vector3(0.0, 1.031, 0.18))
	shield.scale.z = 0.12
	Kit.rbox(root, Vector3(0.061, 0.095, 0.039), Vector3(-0.148, 1.212, 0.145), leather, 0.013)
	_limb(root, Vector3(-0.164, 1.25, 0.145), Vector3(-0.164, 1.311, 0.145), 0.006, ink)
	if style == 2:
		_capsule(root, Vector3(0.0, 1.601, -0.161), 0.07, 0.14, hair).scale.y = 0.80
	return root


static func _capsule(parent: Node3D, at: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var key: String = "capsule:%.4f:%.4f" % [radius, height]
	var mesh: CapsuleMesh
	if _meshes.has(key):
		mesh = _meshes[key] as CapsuleMesh
	else:
		mesh = CapsuleMesh.new()
		mesh.radius = radius
		mesh.height = maxf(height, radius * 2.0)
		mesh.radial_segments = 12
		mesh.rings = 4
		_meshes[key] = mesh
	return Kit.add(parent, mesh, material, at)


static func _limb(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var direction: Vector3 = end - start
	var node: MeshInstance3D = _capsule(parent, (start + end) * 0.5, radius, direction.length() + radius * 2.0, material)
	node.quaternion = Quaternion(Vector3.UP, direction.normalized())
	return node
