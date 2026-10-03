extends RefCounted
## A freestanding chocolatier counter; customer side is +Z, floor contact is y = 0.

const DK = preload("res://scripts/world/design_kit.gd")
const SG = preload("res://scripts/world/signage.gd")
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ChocolateShop"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var selection: int = posmod(variant, 4)
	var blushes: Array[Color] = [Color(0.82, 0.61, 0.59), Color(0.89, 0.72, 0.68), Color(0.76, 0.55, 0.54), Color(0.86, 0.67, 0.64)]
	var blush: Color = blushes[selection]
	var walnut: StandardMaterial3D = DK.wood(DK.WALNUT, "chocolate_walnut")
	var pink: StandardMaterial3D = DK.paint(blush)
	var brass: StandardMaterial3D = DK.brass()
	var stone: StandardMaterial3D = DK.stone(blush.lightened(0.32), 0.42, "chocolate_stone_%d" % selection)
	var dark: StandardMaterial3D = DK.metal()
	var cream: StandardMaterial3D = DK.paint(DK.CREAM)
	# Recessed toe kick, curved carcass and a honed stone lip.
	DK.rbox(root, Vector3(4.12, 0.14, 1.04), Vector3(0.0, 0.07, 0.0), dark, 0.045)
	DK.rbox(root, Vector3(4.4, 0.83, 1.22), Vector3(0.0, 0.555, 0.0), walnut, 0.12)
	DK.rbox(root, Vector3(4.22, 0.66, 0.055), Vector3(0.0, 0.55, 0.616), pink, 0.025)
	var reeds: Array[Transform3D] = []
	for i in 30:
		reeds.append(Transform3D(Basis.IDENTITY, Vector3(-2.0 + float(i) * 0.138, 0.55, 0.655)))
	_batch(root, DK.rounded_box(Vector3(0.058, 0.65, 0.055), 0.025), walnut, reeds, "WalnutReeding")
	DK.rbox(root, Vector3(4.23, 0.025, 0.025), Vector3(0.0, 0.895, 0.645), brass, 0.008, false)
	DK.rbox(root, Vector3(4.52, 0.09, 1.32), Vector3(0.0, 1.015, 0.0), stone, 0.042)
	# Staff-side cabinet seams and brass pulls.
	for x: float in [-1.06, 1.06]:
		DK.rbox(root, Vector3(2.03, 0.62, 0.035), Vector3(x, 0.55, -0.615), walnut, 0.018)
		DK.rbox(root, Vector3(0.31, 0.025, 0.035), Vector3(x, 0.77, -0.65), brass, 0.011, false)
	# Glass display with a removable walnut tray deck and slender brass corner mullions.
	var cx: float = -0.68
	DK.rbox(root, Vector3(2.68, 0.075, 1.05), Vector3(cx, 1.10, 0.015), walnut, 0.035)
	DK.rbox(root, Vector3(2.55, 0.026, 0.92), Vector3(cx, 1.15, 0.015), cream, 0.012)
	for x: float in [cx - 1.30, cx + 1.30]:
		for z: float in [-0.48, 0.51]:
			DK.rbox(root, Vector3(0.025, 0.57, 0.025), Vector3(x, 1.405, z), brass, 0.009, false)
		DK.rbox(root, Vector3(0.012, 0.55, 0.96), Vector3(x, 1.405, 0.015), _glass(), 0.004, false)
		DK.rbox(root, Vector3(0.028, 0.028, 1.02), Vector3(x, 1.69, 0.015), brass, 0.009, false)
	for y: float in [1.125, 1.69]:
		DK.rbox(root, Vector3(2.63, 0.025, 0.025), Vector3(cx, y, 0.51), brass, 0.008, false)
	DK.rbox(root, Vector3(2.58, 0.545, 0.012), Vector3(cx, 1.405, 0.51), _glass(), 0.004, false)
	DK.rbox(root, Vector3(2.62, 0.012, 1.0), Vector3(cx, 1.687, 0.015), _glass(), 0.004, false)
	DK.rbox(root, Vector3(2.61, 0.035, 0.04), Vector3(cx, 1.677, -0.48), walnut, 0.01)
	DK.rbox(root, Vector3(2.48, 0.009, 0.016), Vector3(cx, 1.652, -0.465), DK.washi(DK.CREAM, 1.3, "chocolate_case_light"), 0.003, false)
	# Three shallow serving trays, each holding a precise 3 x 4 praline assortment.
	var dome: ArrayMesh = DK.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.046, 0.0), Vector2(0.052, 0.012), Vector2(0.050, 0.032), Vector2(0.037, 0.054), Vector2(0.012, 0.066), Vector2(0.0, 0.068)]), 16)
	var flavors: Array[Color] = [Color(0.19, 0.085, 0.047), Color(0.40, 0.22, 0.12), Color(0.84, 0.69, 0.45)]
	for tray in 3:
		var tx: float = cx - 0.85 + float(tray) * 0.85
		DK.rbox(root, Vector3(0.78, 0.029, 0.77), Vector3(tx, 1.18, 0.015), brass, 0.014, false)
		DK.rbox(root, Vector3(0.73, 0.019, 0.72), Vector3(tx, 1.199, 0.015), DK.paint(DK.CHARCOAL), 0.009, false)
		var chocolates: Array[Transform3D] = []
		var toppings: Array[Transform3D] = []
		for row in 3:
			for col in 4:
				var point: Vector3 = Vector3(tx - 0.255 + float(col) * 0.17, 1.209, -0.215 + float(row) * 0.23)
				chocolates.append(Transform3D(Basis.IDENTITY, point))
				toppings.append(Transform3D(Basis(Vector3.UP, float(col + row) * 0.4), point + Vector3(0.0, 0.065, 0.0)))
		var flavor: Color = flavors[(tray + selection) % 3]
		_batch(root, dome, DK.paint(flavor, 0.26), chocolates, "Pralines_%d" % tray)
		_batch(root, DK.rounded_box(Vector3(0.028, 0.005, 0.012), 0.002), DK.paint(DK.OCHRE, 0.4), toppings, "CocoaGarnish_%d" % tray)
	# Gift stacks sit beside the vitrine, leaving the front edge free for serving.
	for stack in 2:
		var height: float = 1.06
		var count: int = 3 if stack == 0 else 2 + selection % 2
		for level in count:
			var size: Vector3 = Vector3(0.63 - float(level) * 0.07, 0.16, 0.48 - float(level) * 0.045)
			var point: Vector3 = Vector3(1.04 + float(stack) * 0.73, height, -0.07 + float(stack) * 0.10)
			_gift(root, point, size, pink if (level + stack + selection) % 2 == 0 else cream, selection)
			height += 0.177
	# Independent floor-supported sign uprights behind the counter.
	for x: float in [-2.06, 2.06]:
		DK.rbox(root, Vector3(0.065, 2.9, 0.065), Vector3(x, 1.45, -0.49), dark, 0.018)
		DK.rbox(root, Vector3(0.22, 0.025, 0.26), Vector3(x, 0.0125, -0.49), dark, 0.012)
	DK.rbox(root, Vector3(4.44, 1.13, 0.13), Vector3(0.0, 2.77, -0.49), walnut, 0.085)
	DK.rbox(root, Vector3(4.28, 0.97, 0.025), Vector3(0.0, 2.77, -0.412), DK.washi(DK.CREAM, 0.45, "chocolate_sign"), 0.055, false)
	_label(root, "CHOCOLATE", Vector3(0.0, 3.07, -0.389), 120, 0.0035)
	_label(root, "チョコレート  ·  巧克力", Vector3(0.0, 2.79, -0.389), 80, 0.003)
	_label(root, "Sô cô la  ·  Chocolat  ·  Chocolate", Vector3(0.0, 2.51, -0.389), 68, 0.0028)
	return root


static func _gift(parent: Node3D, bottom: Vector3, size: Vector3, material: Material, selection: int) -> void:
	var ribbon: StandardMaterial3D = DK.fabric(DK.LINEN if selection % 2 == 0 else DK.SAGE, "chocolate_ribbon_%d" % (selection % 2))
	DK.rbox(parent, size, bottom + Vector3(0.0, size.y * 0.5, 0.0), material, 0.022, false)
	DK.rbox(parent, Vector3(size.x + 0.012, 0.028, size.z + 0.012), bottom + Vector3(0.0, size.y - 0.009, 0.0), material, 0.012, false)
	DK.rbox(parent, Vector3(0.042, size.y + 0.008, size.z + 0.017), bottom + Vector3(0.0, size.y * 0.5, 0.0), ribbon, 0.006, false)
	DK.rbox(parent, Vector3(size.x + 0.017, size.y + 0.009, 0.036), bottom + Vector3(0.0, size.y * 0.5, 0.0), ribbon, 0.006, false)
	var seal: ArrayMesh = DK.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.025, 0.0), Vector2(0.027, 0.004), Vector2(0.024, 0.009), Vector2(0.0, 0.009)]), 16)
	DK.add(parent, seal, DK.brass(), bottom + Vector3(0.0, size.y + 0.006, 0.0), Vector3.ZERO, false)


static func _glass() -> StandardMaterial3D:
	if not _materials.has("glass"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.83, 0.94, 0.91, 0.14)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness = 0.12
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["glass"] = material
	return _materials["glass"] as StandardMaterial3D


static func _batch(parent: Node3D, mesh: Mesh, material: Material, poses: Array[Transform3D], title: String) -> void:
	var batch: MultiMesh = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = poses.size()
	for i in poses.size():
		batch.set_instance_transform(i, poses[i])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = batch
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel_size: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = SG.font()
	label.font_size = size
	label.pixel_size = pixel_size
	label.position = at
	label.modulate = DK.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
