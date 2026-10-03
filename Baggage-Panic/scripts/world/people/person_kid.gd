extends RefCounted
## A young traveller with a canvas daypack and a floppy linen rabbit.
## All dimensions are metres; the shoe soles touch local y = 0, face points +Z.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "KidWithRabbit"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 3)
	var shirts: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.OCHRE]
	var trousers: Array[Color] = [DesignKit.INDIGO, DesignKit.WALNUT, DesignKit.SAGE]
	var packs: Array[Color] = [DesignKit.CLAY, DesignKit.SAGE, DesignKit.INDIGO]
	var skins: Array[Color] = [Color(0.79, 0.57, 0.40), Color(0.94, 0.73, 0.56), Color(0.48, 0.30, 0.21)]
	var hairs: Array[Color] = [DesignKit.CHARCOAL, DesignKit.WALNUT, Color(0.23, 0.17, 0.13)]
	var shirt: Material = DesignKit.fabric(shirts[style], "kid_shirt_%d" % style)
	var pants: Material = DesignKit.fabric(trousers[style], "kid_pants_%d" % style)
	var canvas: Material = DesignKit.fabric(packs[style], "kid_pack_%d" % style)
	var linen: Material = DesignKit.fabric(DesignKit.LINEN, "kid_straps")
	var plush: Material = DesignKit.fabric(DesignKit.CREAM, "kid_rabbit")
	var skin: Material = DesignKit.paint(skins[style], 0.88)
	var hair: Material = DesignKit.paint(hairs[style], 0.96)
	var ink: Material = DesignKit.paint(DesignKit.CHARCOAL, 0.9)
	var rubber: Material = DesignKit.paint(DesignKit.CREAM, 0.9)

	# Broad, soft sneakers: separate rubber soles and woven uppers.
	for side: float in [-1.0, 1.0]:
		var x: float = side * 0.115
		_oval(root, "Sole", Vector3(x, 0.035, 0.055), Vector3(0.19, 0.07, 0.31), rubber)
		_oval(root, "Sneaker", Vector3(x, 0.095, 0.05), Vector3(0.17, 0.14, 0.28), linen)
		_link(root, "TrouserLeg", Vector3(x, 0.17, 0.0), Vector3(x, 0.73, 0.0), 0.086, pants)

	var torso_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.14, 0.0), Vector2(0.20, 0.035),
		Vector2(0.215, 0.12), Vector2(0.20, 0.34), Vector2(0.17, 0.43),
		Vector2(0.08, 0.49), Vector2(0.0, 0.49)])
	var torso: MeshInstance3D = DesignKit.add(root, DesignKit.lathe(torso_profile, 16), shirt, Vector3(0.0, 0.66, 0.0))
	torso.name = "LinenSweatshirt"
	torso.scale.z = 0.73
	_oval(root, "RibbedHem", Vector3(0.0, 0.70, 0.0), Vector3(0.407, 0.075, 0.295), shirt)
	_link(root, "Neck", Vector3(0.0, 1.09, 0.0), Vector3(0.0, 1.23, 0.0), 0.064, skin)
	_oval(root, "Head", Vector3(0.0, 1.37, 0.012), Vector3(0.43, 0.48, 0.40), skin)
	for side: float in [-1.0, 1.0]:
		_oval(root, "Ear", Vector3(side * 0.211, 1.365, 0.008), Vector3(0.067, 0.10, 0.06), skin)
		_oval(root, "Eye", Vector3(side * 0.075, 1.395, 0.200), Vector3(0.025, 0.033, 0.013), ink)
	_oval(root, "Nose", Vector3(0.0, 1.35, 0.212), Vector3(0.042, 0.046, 0.042), skin)

	# Turned cap rather than a second sphere, leaving the whole face visible.
	var hair_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.215, 0.0), Vector2(0.228, 0.04),
		Vector2(0.211, 0.12), Vector2(0.162, 0.19), Vector2(0.09, 0.235), Vector2(0.0, 0.25)])
	var cap: MeshInstance3D = DesignKit.add(root, DesignKit.lathe(hair_profile, 16), hair, Vector3(0.0, 1.40, -0.012))
	cap.name = "SoftHairCap"
	cap.scale.z = 0.91
	var fringe: MeshInstance3D = _oval(root, "SideSweptFringe", Vector3(-0.055 if style != 1 else 0.055, 1.51, 0.172), Vector3(0.27, 0.115, 0.10), hair)
	fringe.rotation_degrees.z = -16.0 if style != 1 else 16.0

	# One arm relaxed; the other reaches forward to hold the rabbit by its shoulder.
	_link(root, "LeftSleeve", Vector3(-0.175, 1.07, 0.0), Vector3(-0.255, 0.87, 0.02), 0.085, shirt)
	_link(root, "LeftForearm", Vector3(-0.255, 0.87, 0.02), Vector3(-0.285, 0.72, 0.07), 0.055, skin)
	_oval(root, "LeftHand", Vector3(-0.286, 0.695, 0.077), Vector3(0.105, 0.12, 0.09), skin)
	_link(root, "RightSleeve", Vector3(0.175, 1.07, 0.0), Vector3(0.263, 0.91, 0.045), 0.085, shirt)
	_link(root, "RightForearm", Vector3(0.263, 0.91, 0.045), Vector3(0.31, 0.91, 0.235), 0.055, skin)
	_oval(root, "HoldingHand", Vector3(0.32, 0.905, 0.245), Vector3(0.10, 0.105, 0.105), skin)

	# Tiny rounded daypack sits behind the body; contrast pocket and brass zipper.
	DesignKit.rbox(root, Vector3(0.29, 0.34, 0.16), Vector3(0.0, 0.93, -0.20), canvas, 0.075)
	DesignKit.rbox(root, Vector3(0.22, 0.14, 0.06), Vector3(0.0, 0.855, -0.295), linen, 0.028)
	for side: float in [-1.0, 1.0]:
		_link(root, "ShoulderStrap", Vector3(side * 0.13, 1.10, 0.075), Vector3(side * 0.15, 0.80, 0.145), 0.021, linen)
	_link(root, "CarryLoop", Vector3(-0.057, 1.095, -0.20), Vector3(0.057, 1.095, -0.20), 0.018, linen)
	_link(root, "ZipPull", Vector3(0.088, 0.92, -0.327), Vector3(0.088, 0.885, -0.327), 0.009, DesignKit.brass())
	# A shared airport pictogram is sewn onto the pocket; deliberately no tiny text.
	if not _meshes.has("patch"):
		var patch_mesh: QuadMesh = QuadMesh.new()
		patch_mesh.size = Vector2(0.075, 0.075)
		_meshes["patch"] = patch_mesh
	var patch: Mesh = _meshes["patch"] as Mesh
	DesignKit.add(root, patch, Signage._icon_material("plane", packs[style]), Vector3(0.0, 0.86, -0.327), Vector3(0.0, 180.0, 0.0), false)

	var rabbit: Node3D = Node3D.new()
	rabbit.name = "LinenRabbit"
	rabbit.position = Vector3(0.385, 0.69, 0.27)
	rabbit.rotation_degrees.z = -12.0 + float(style) * 6.0
	root.add_child(rabbit)
	_oval(rabbit, "StuffedBody", Vector3.ZERO, Vector3(0.16, 0.23, 0.13), plush)
	_oval(rabbit, "RabbitHead", Vector3(0.0, 0.155, 0.008), Vector3(0.16, 0.145, 0.14), plush)
	for side: float in [-1.0, 1.0]:
		var ear: MeshInstance3D = _oval(rabbit, "FloppyEar", Vector3(side * 0.048, 0.275, 0.003), Vector3(0.054, 0.19, 0.045), plush)
		ear.rotation_degrees.z = side * -16.0
		_oval(rabbit, "RabbitFoot", Vector3(side * 0.047, -0.112, 0.028), Vector3(0.069, 0.065, 0.092), plush)
		_oval(rabbit, "StitchedEye", Vector3(side * 0.033, 0.17, 0.072), Vector3(0.013, 0.015, 0.008), ink)
	_oval(rabbit, "ThreadNose", Vector3(0.0, 0.14, 0.079), Vector3(0.019, 0.013, 0.009), DesignKit.fabric(DesignKit.CLAY, "kid_rabbit_thread"))
	return root


static func _oval(parent: Node3D, part_name: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	if not _meshes.has("sphere"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 16
		sphere.rings = 8
		_meshes["sphere"] = sphere
	var mesh: Mesh = _meshes["sphere"] as Mesh
	var instance: MeshInstance3D = DesignKit.add(parent, mesh, material, at)
	instance.name = part_name
	instance.scale = size
	return instance


static func _link(parent: Node3D, part_name: String, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var length: float = start.distance_to(end)
	var key: String = "capsule:%.5f:%.5f" % [radius, length]
	if not _meshes.has(key):
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = radius
		capsule.height = maxf(length + radius * 2.0, radius * 2.0)
		capsule.radial_segments = 12
		capsule.rings = 4
		_meshes[key] = capsule
	var mesh: Mesh = _meshes[key] as Mesh
	var instance: MeshInstance3D = DesignKit.add(parent, mesh, material, (start + end) * 0.5)
	instance.name = part_name
	instance.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
