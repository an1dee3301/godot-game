extends RefCounted
## Six-metre laminated-glass guard, measured from its finished floor contact.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "GlassBalustrade"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var oak_tints: Array[Color] = [DesignKit.OAK, DesignKit.OAK.lightened(0.08), DesignKit.OAK.darkened(0.12), DesignKit.OAK]
	var oak: StandardMaterial3D = DesignKit.wood(oak_tints[style], "balustrade_oak_%d" % style)
	var brass: StandardMaterial3D = DesignKit.brass()
	var steel: StandardMaterial3D = DesignKit.metal()
	var gasket: StandardMaterial3D = DesignKit.paint(DesignKit.CHARCOAL.darkened(0.35), 0.95)
	var glass: StandardMaterial3D = _glass(style)
	var edge: StandardMaterial3D = DesignKit.paint(Color(0.43, 0.61, 0.53), 0.22)
	# Recessed continuous shoe: the oak cap is the only substantial horizontal rail.
	DesignKit.rbox(root, Vector3(6.0, 0.105, 0.12), Vector3(0.0, 0.0525, 0.0), steel, 0.015)
	DesignKit.rbox(root, Vector3(5.96, 0.008, 0.035), Vector3(0.0, 0.108, 0.0), gasket, 0.003, false)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(5.96, 0.012, 0.008), Vector3(0.0, 0.073, side * 0.06), brass, 0.003, false)
	DesignKit.rbox(root, Vector3(5.96, 0.024, 0.034), Vector3(0.0, 1.135, 0.0), brass, 0.008)
	DesignKit.rbox(root, Vector3(6.0, 0.072, 0.084), Vector3(0.0, 1.164, 0.0), oak, 0.032)
	# Five independently fitted 21-mm panes; gaps remain visible under the continuous cap.
	for pane: int in 5:
		var x: float = -2.4 + float(pane) * 1.2
		DesignKit.rbox(root, Vector3(1.188, 1.025, 0.021), Vector3(x, 0.6155, 0.0), glass, 0.004, false)
		for end: float in [-1.0, 1.0]:
			DesignKit.rbox(root, Vector3(0.003, 1.016, 0.022), Vector3(x + end * 0.593, 0.6155, 0.0), edge, 0.001, false)
		# Two compact floor-anchored brackets per pane; turned buttons face the concourse.
		for offset: float in [-0.43, 0.43]:
			var mount_x: float = x + offset
			DesignKit.rbox(root, Vector3(0.09, 0.035, 0.17), Vector3(mount_x, 0.0175, -0.055), steel, 0.012)
			DesignKit.rbox(root, Vector3(0.042, 0.345, 0.042), Vector3(mount_x, 0.19, -0.069), brass, 0.012)
			for height: float in [0.19, 0.325]:
				DesignKit.add(root, _button_mesh(), brass, Vector3(mount_x, height, -0.069), Vector3(-90.0, 0.0, 0.0), false)
				DesignKit.rbox(root, Vector3(0.013, 0.0025, 0.0015), Vector3(mount_x, height, 0.035), steel, 0.001, false)
	# A restrained ceramic-frit manifestation makes the otherwise clear guard perceptible.
	if style == 3:
		_welcome(root)
	else:
		_dots(root, style)
	return root


static func _button_mesh() -> ArrayMesh:
	# Profile includes a narrow barrel, rubber-facing shoulder and domed screw cap.
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -0.101), Vector2(0.018, -0.101),
		Vector2(0.022, -0.097), Vector2(0.022, -0.084),
		Vector2(0.013, -0.08), Vector2(0.013, -0.01),
		Vector2(0.017, -0.006), Vector2(0.017, 0.0), Vector2.ZERO
	]), 20)


static func _glass(style: int) -> StandardMaterial3D:
	var key: String = "glass_%d" % style
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var tints: Array[Color] = [Color(0.82, 0.94, 0.9, 0.19), Color(0.92, 0.95, 0.9, 0.17), Color(0.72, 0.86, 0.78, 0.22), Color(0.87, 0.94, 0.91, 0.18)]
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = tints[style]
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.13
	material.metallic_specular = 0.7
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


static func _dots(parent: Node3D, style: int) -> void:
	var mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2.ZERO, Vector2(0.012, 0.0), Vector2(0.013, 0.001),
		Vector2(0.012, 0.002), Vector2(0.0, 0.002)
	]), 12)
	var dots: MultiMesh = MultiMesh.new()
	dots.transform_format = MultiMesh.TRANSFORM_3D
	dots.mesh = mesh
	dots.instance_count = 100
	for index: int in dots.instance_count:
		var column: int = index % 50
		var row: int = index / 50
		var height: float = 0.76 + float(row) * 0.065 + (0.035 if style == 2 else 0.0)
		dots.set_instance_transform(index, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-2.94 + float(column) * 0.12, height, 0.013)))
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.multimesh = dots
	instance.material_override = DesignKit.paint(DesignKit.CREAM, 0.82)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


static func _welcome(parent: Node3D) -> void:
	var words: Array = Signage.TEXT["welcome"]
	var captions: Array[String] = ["%s　%s　%s" % [words[0], words[1], words[2]], "%s · %s · %s" % [words[3], words[4], words[5]]]
	for row: int in 2:
		var label: Label3D = Label3D.new()
		label.text = captions[row]
		label.font = Signage.font()
		label.font_size = 72 if row == 0 else 64
		label.pixel_size = 0.0038
		label.position = Vector3(0.0, 0.83 - float(row) * 0.32, 0.016)
		label.modulate = DesignKit.CREAM
		label.outline_size = 0
		label.double_sided = false
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(label)
