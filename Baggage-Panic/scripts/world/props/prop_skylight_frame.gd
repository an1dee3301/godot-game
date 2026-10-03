extends RefCounted
## Floating roof lantern. All heights are measured from the terminal floor.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "SkylightLantern"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var timber_tints: Array[Color] = [DesignKit.OAK, DesignKit.OAK.lightened(0.08), DesignKit.OAK.darkened(0.08), Color(0.73, 0.59, 0.44)]
	var oak: StandardMaterial3D = DesignKit.wood(timber_tints[style], "skylight_oak_%d" % style)
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "skylight_walnut")
	var steel: StandardMaterial3D = DesignKit.metal()
	var brass: StandardMaterial3D = DesignKit.brass()
	var glass: StandardMaterial3D = _glass(style)
	var glow: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 1.3 + float(style) * 0.15, "skylight_cove_%d" % style)
	# Deep oak perimeter, inset walnut shadow reveal, and slim upper weather cap.
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(6.0, 0.32, 0.24), Vector3(0.0, 12.66, side * 2.88), oak, 0.045)
		DesignKit.rbox(root, Vector3(0.24, 0.32, 5.52), Vector3(side * 2.88, 12.66, 0.0), oak, 0.045)
		DesignKit.rbox(root, Vector3(5.76, 0.09, 0.1), Vector3(0.0, 12.48, side * 2.84), walnut, 0.022)
		DesignKit.rbox(root, Vector3(0.1, 0.09, 5.56), Vector3(side * 2.84, 12.48, 0.0), walnut, 0.022)
		DesignKit.rbox(root, Vector3(6.0, 0.14, 0.24), Vector3(0.0, 13.43, side * 2.88), oak, 0.035)
		DesignKit.rbox(root, Vector3(0.24, 0.14, 5.52), Vector3(side * 2.88, 13.43, 0.0), oak, 0.035)
		DesignKit.rbox(root, Vector3(5.5, 0.025, 0.055), Vector3(0.0, 12.493, side * 2.7), glow, 0.009, false)
		DesignKit.rbox(root, Vector3(0.055, 0.025, 5.5), Vector3(side * 2.7, 12.493, 0.0), glow, 0.009, false)
		# Clear clerestory ribbons sit between the two timber rings.
		DesignKit.rbox(root, Vector3(5.52, 0.55, 0.022), Vector3(0.0, 13.08, side * 2.88), glass, 0.008, false)
		DesignKit.rbox(root, Vector3(0.022, 0.55, 5.52), Vector3(side * 2.88, 13.08, 0.0), glass, 0.008, false)
	# Corner posts and honest metal splice shoes; no supports descend to the floor.
	for x: float in [-2.88, 2.88]:
		for z: float in [-2.88, 2.88]:
			DesignKit.rbox(root, Vector3(0.24, 0.65, 0.24), Vector3(x, 13.09, z), oak, 0.035)
			DesignKit.rbox(root, Vector3(0.25, 0.075, 0.25), Vector3(x, 12.84, z), steel, 0.018)
			DesignKit.rbox(root, Vector3(0.19, 0.018, 0.19), Vector3(x, 12.488, z), brass, 0.006, false)
	# Nine individually glazed lights, with a pronounced 3-by-3 oak ceiling grid.
	for offset: float in [-0.94, 0.94]:
		DesignKit.rbox(root, Vector3(0.15, 0.24, 5.52), Vector3(offset, 13.27, 0.0), oak, 0.027)
		DesignKit.rbox(root, Vector3(5.52, 0.24, 0.15), Vector3(0.0, 13.27, offset), oak, 0.027)
		DesignKit.rbox(root, Vector3(0.19, 0.025, 5.52), Vector3(offset, 13.395, 0.0), steel, 0.008, false)
		DesignKit.rbox(root, Vector3(5.52, 0.025, 0.19), Vector3(0.0, 13.395, offset), steel, 0.008, false)
		for side: float in [-1.0, 1.0]:
			DesignKit.rbox(root, Vector3(0.075, 0.56, 0.065), Vector3(offset, 13.08, side * 2.88), oak, 0.014)
			DesignKit.rbox(root, Vector3(0.065, 0.56, 0.075), Vector3(side * 2.88, 13.08, offset), oak, 0.014)
	for row in 3:
		for column in 3:
			var pane_at: Vector3 = Vector3(float(column - 1) * 1.88, 13.419, float(row - 1) * 1.88)
			DesignKit.rbox(root, Vector3(1.71, 0.024, 1.71), pane_at, glass, 0.009, false)
	# Warm lower apron carries a generous multilingual greeting on its front face.
	DesignKit.rbox(root, Vector3(5.52, 0.94, 0.12), Vector3(0.0, 12.47, 2.87), walnut, 0.045)
	DesignKit.rbox(root, Vector3(5.24, 0.025, 0.025), Vector3(0.0, 12.87, 2.938), brass, 0.009, false)
	var greetings: Array = Signage.translations("welcome")
	_caption(root, "%s · %s · %s" % [greetings[0], greetings[1], greetings[2]], 12.71)
	_caption(root, "%s · %s" % [greetings[3], greetings[4]], 12.44)
	_caption(root, str(greetings[5]), 12.17)
	return root


static func _caption(parent: Node3D, text: String, height: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font = Signage.font()
	label.font_size = 96
	label.pixel_size = 0.0028
	label.modulate = DesignKit.CREAM
	label.outline_size = 0
	label.position = Vector3(0.0, height, 2.94)
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _glass(style: int) -> StandardMaterial3D:
	var key: String = "glass_%d" % style
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var tints: Array[Color] = [Color(0.75, 0.86, 0.84, 0.24), Color(0.86, 0.88, 0.78, 0.28), Color(0.73, 0.82, 0.88, 0.24), Color(0.9, 0.83, 0.71, 0.28)]
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = tints[style]
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.12
	material.metallic = 0.08
	_materials[key] = material
	return material
