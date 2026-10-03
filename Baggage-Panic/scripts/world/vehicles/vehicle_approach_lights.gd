extends RefCounted
## Five steady-white approach bars. Fixture faces and the service sign face +Z.
## The close-spaced row is an apron scenery assembly, rather than a full runway system.

const DK = preload("res://scripts/world/design_kit.gd")
const SIG = preload("res://scripts/world/signage.gd")


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ApproachLightBars"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colors: Array[Color] = [Color(0.96, 0.72, 0.16), DK.CREAM, DK.SAGE, DK.CHARCOAL]
	var body: StandardMaterial3D = DK.paint(colors[scheme], 0.46)
	var steel: StandardMaterial3D = DK.metal(DK.CHARCOAL, 0.42, 0.8, "approach_steel")
	var trim: StandardMaterial3D = DK.brass() if scheme == 3 else DK.metal(Color(0.65, 0.67, 0.64), 0.35, 0.85, "approach_alloy")
	var stripe: StandardMaterial3D = DK.paint(DK.CLAY if scheme == 1 else DK.CHARCOAL)
	var footing: StandardMaterial3D = DK.stone(DK.LIMESTONE, 0.76, "approach_footing")
	var white: StandardMaterial3D = DK.washi(Color(1.0, 0.98, 0.92), 8.0, "approach_white")
	var amber: StandardMaterial3D = DK.washi(Color(1.0, 0.54, 0.12), 2.0, "approach_service_amber")
	var housings: Array[Transform3D] = []
	var rims: Array[Transform3D] = []
	var lenses: Array[Transform3D] = []
	# Turned aluminium cans, protective rolled rims, and shallow domed optical faces.
	var can_mesh: ArrayMesh = DK.lathe(PackedVector2Array([
		Vector2(0.0, -0.24), Vector2(0.16, -0.24), Vector2(0.21, -0.18),
		Vector2(0.23, 0.12), Vector2(0.22, 0.17), Vector2(0.0, 0.17)
	]), 20)
	var rim_mesh: ArrayMesh = DK.lathe(PackedVector2Array([
		Vector2(0.185, 0.12), Vector2(0.232, 0.12), Vector2(0.245, 0.145),
		Vector2(0.245, 0.18), Vector2(0.225, 0.20), Vector2(0.185, 0.20), Vector2(0.185, 0.12)
	]), 20)
	var lens_mesh: ArrayMesh = DK.lathe(PackedVector2Array([
		Vector2(0.0, 0.17), Vector2(0.188, 0.17), Vector2(0.19, 0.20),
		Vector2(0.16, 0.22), Vector2(0.08, 0.237), Vector2(0.0, 0.24)
	]), 20)
	var lamp_basis: Basis = Basis(Vector3.RIGHT, deg_to_rad(84.0))
	for bar_index in range(5):
		var z: float = -float(bar_index) * 4.4
		var bar: Node3D = Node3D.new()
		bar.name = "Bar_%02d" % (bar_index + 1)
		bar.position.z = z
		root.add_child(bar)
		# Twin frangible masts leave a recognizable open silhouette below the crossarm.
		for side in [-1.0, 1.0]:
			var x: float = float(side) * 2.25
			DK.rbox(bar, Vector3(0.7, 0.16, 0.8), Vector3(x, 0.08, 0.0), footing, 0.065)
			DK.rbox(bar, Vector3(0.42, 0.08, 0.44), Vector3(x, 0.20, 0.0), steel, 0.025)
			DK.rbox(bar, Vector3(0.16, 2.02, 0.16), Vector3(x, 1.27, 0.0), body, 0.035)
			DK.rbox(bar, Vector3(0.23, 0.15, 0.23), Vector3(x, 0.35, 0.0), trim, 0.035)
			_brace(bar, Vector3(x, 1.70, -0.02), Vector3(x - float(side) * 0.70, 2.25, -0.02), steel)
		DK.rbox(bar, Vector3(6.4, 0.21, 0.22), Vector3(0.0, 2.28, 0.0), body, 0.065)
		DK.rbox(bar, Vector3(6.26, 0.055, 0.025), Vector3(0.0, 2.26, 0.12), stripe, 0.012, false)
		DK.rbox(bar, Vector3(0.38, 0.30, 0.22), Vector3(2.25, 1.12, -0.15), steel, 0.04)
		for lamp_index in range(5):
			var lamp_x: float = float(lamp_index - 2) * 1.35
			DK.rbox(bar, Vector3(0.13, 0.25, 0.16), Vector3(lamp_x, 2.46, 0.0), trim, 0.025, false)
			var lamp_transform: Transform3D = Transform3D(lamp_basis, Vector3(lamp_x, 2.66, z))
			housings.append(lamp_transform)
			rims.append(lamp_transform)
			lenses.append(lamp_transform)
	_batch(root, "LampCans", can_mesh, body, housings, true)
	_batch(root, "RolledLensRims", rim_mesh, trim, rims, false)
	_batch(root, "SteadyWhiteLenses", lens_mesh, white, lenses, false)
	# International service-area identification, safely below the optical line.
	SIG.panel(root, Vector3(0.0, 1.02, 0.25), "apron", {"width": 4.5, "accent": colors[scheme]})
	DK.rbox(root, Vector3(0.12, 0.16, 0.10), Vector3(2.25, 1.13, 0.15), amber, 0.04, false)
	return root


static func _brace(parent: Node3D, start: Vector3, end: Vector3, material: Material) -> void:
	var direction: Vector3 = end - start
	var brace: MeshInstance3D = DK.rbox(parent, Vector3(0.065, direction.length(), 0.065), (start + end) * 0.5, material, 0.02, false)
	brace.quaternion = Quaternion(Vector3.UP, direction.normalized())


static func _batch(parent: Node3D, title: String, mesh: Mesh, material: Material, transforms: Array[Transform3D], shadows: bool) -> void:
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = transforms.size()
	for index in range(transforms.size()):
		instances.set_instance_transform(index, transforms[index])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = instances
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
