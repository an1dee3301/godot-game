extends RefCounted
## A quiet airport scrubber: ceramic-white pebble shell, oak service hatch and light face.
## No written labels: the face and continuous status ring communicate across languages.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CleaningRobot"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var lights: Array[Color] = [Color(0.65, 0.94, 0.77), Color(1.0, 0.79, 0.53), Color(0.65, 0.85, 1.0), Color(0.94, 0.91, 0.66)]
	var accent: Color = accents[style]
	var light_color: Color = lights[style]
	var shell: StandardMaterial3D = DesignKit.paint(Color(0.96, 0.95, 0.91), 0.3)
	var rubber: StandardMaterial3D = DesignKit.paint(DesignKit.CHARCOAL, 0.88)
	var steel: StandardMaterial3D = DesignKit.metal()
	var trim: StandardMaterial3D = DesignKit.paint(accent, 0.54)
	var glow: StandardMaterial3D = DesignKit.washi(light_color, 2.2, "cleaner_ring_%d" % style)
	var eyes: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 1.8, "cleaner_eyes")

	# Recessed traction wheels really meet the floor; shell floats above the scrub deck.
	var wheel_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -0.043), Vector2(0.085, -0.043), Vector2(0.105, -0.028),
		Vector2(0.105, 0.028), Vector2(0.085, 0.043), Vector2(0.0, 0.043)
	]), 32)
	for side: float in [-1.0, 1.0]:
		DesignKit.add(root, wheel_mesh, rubber, Vector3(side * 0.345, 0.105, -0.08), Vector3(0.0, 0.0, 90.0))
		DesignKit.rbox(root, Vector3(0.035, 0.055, 0.22), Vector3(side * 0.4, 0.16, -0.08), steel, 0.016)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.085), Vector2(0.36, 0.085), Vector2(0.425, 0.115),
		Vector2(0.445, 0.155), Vector2(0.445, 0.2), Vector2(0.0, 0.2)
	]), 64), rubber, Vector3.ZERO)
	# Continuous light diffuser lies between two dark bumper lips, rather than on the paint.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.435, 0.19), Vector2(0.461, 0.19), Vector2(0.471, 0.204),
		Vector2(0.471, 0.231), Vector2(0.461, 0.243), Vector2(0.435, 0.243)
	]), 64), glow, Vector3.ZERO, Vector3.ZERO, false)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.241), Vector2(0.463, 0.241), Vector2(0.48, 0.263),
		Vector2(0.48, 0.285), Vector2(0.465, 0.301), Vector2(0.0, 0.301)
	]), 64), trim, Vector3.ZERO)
	# Turned pebble profile: belly roll, almost vertical cheeks, broad rounded shoulder.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.287), Vector2(0.432, 0.287), Vector2(0.455, 0.303),
		Vector2(0.465, 0.334), Vector2(0.465, 0.44), Vector2(0.455, 0.487),
		Vector2(0.428, 0.528), Vector2(0.38, 0.56), Vector2(0.31, 0.581),
		Vector2(0.19, 0.592), Vector2(0.0, 0.592)
	]), 64), shell, Vector3.ZERO)

	# Oak lid nests in a charcoal gasket; the brass lift tab is recessed into the lid.
	DesignKit.rbox(root, Vector3(0.32, 0.025, 0.27), Vector3(0.0, 0.589, -0.055), rubber, 0.012)
	var lid_color: Color = DesignKit.WALNUT if style == 2 else DesignKit.OAK
	DesignKit.rbox(root, Vector3(0.301, 0.024, 0.251), Vector3(0.0, 0.6, -0.055), DesignKit.wood(lid_color, "cleaner_lid_%d" % style), 0.011)
	DesignKit.rbox(root, Vector3(0.09, 0.008, 0.027), Vector3(0.0, 0.614, 0.032), steel, 0.003)
	DesignKit.rbox(root, Vector3(0.066, 0.007, 0.013), Vector3(0.0, 0.618, 0.032), DesignKit.brass(), 0.003)
	# Short lidar turret with a dark optical belt and a chamfered white cap.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.071, 0.0), Vector2(0.084, 0.012),
		Vector2(0.084, 0.04), Vector2(0.071, 0.048), Vector2(0.0, 0.048)
	]), 32), steel, Vector3(0.0, 0.578, -0.25))
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.087, 0.0), Vector2(0.087, 0.013),
		Vector2(0.074, 0.025), Vector2(0.0, 0.028)
	]), 32), shell, Vector3(0.0, 0.622, -0.25))

	# Friendly +Z face: wide optical glass, two lit eyes and a small curved smile.
	DesignKit.rbox(root, Vector3(0.36, 0.158, 0.065), Vector3(0.0, 0.417, 0.448), steel, 0.031)
	var face: Label3D = Label3D.new()
	face.name = "FaceLights"
	face.font = Signage.font()
	face.text = "●  ●"
	face.font_size = 96
	face.pixel_size = 0.0011
	face.position = Vector3(0.0, 0.437, 0.483)
	face.modulate = DesignKit.CREAM
	face.outline_size = 0
	face.no_depth_test = false
	face.double_sided = false
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	DesignKit.rbox(root, Vector3(0.057, 0.009, 0.006), Vector3(0.0, 0.378, 0.483), eyes, 0.002, false)
	for side: float in [-1.0, 1.0]:
		DesignKit.add(root, DesignKit.rounded_box(Vector3(0.018, 0.009, 0.006), 0.002), eyes, Vector3(side * 0.031, 0.383, 0.483), Vector3(0.0, 0.0, side * 35.0), false)
	# Rear exhaust slots are recessed; no oversized written maintenance labels.
	for slot: int in 4:
		DesignKit.rbox(root, Vector3(0.16, 0.009, 0.018), Vector3(0.0, 0.345 + float(slot) * 0.025, -0.464), rubber, 0.004, false)

	# Offset edge brush: one cached mesh combines all bristle bundles into a single draw.
	var brush_at: Vector3 = Vector3(-0.36 if style % 2 == 0 else 0.36, 0.0, 0.35)
	DesignKit.add(root, _brush_mesh(), DesignKit.fabric(DesignKit.LINEN, "cleaner_bristles"), brush_at)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.032), Vector2(0.06, 0.032), Vector2(0.073, 0.045),
		Vector2(0.073, 0.062), Vector2(0.055, 0.076), Vector2(0.0, 0.076)
	]), 24), trim, brush_at)
	DesignKit.rbox(root, Vector3(0.065, 0.045, 0.23), brush_at + Vector3(0.0, 0.093, -0.12), steel, 0.019)
	return root


static func _brush_mesh() -> ArrayMesh:
	if _meshes.has("brush"):
		return _meshes["brush"] as ArrayMesh
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bundle: ArrayMesh = DesignKit.rounded_box(Vector3(0.015, 0.027, 0.11), 0.006)
	for index: int in 24:
		var angle: float = TAU * float(index) / 24.0
		var basis: Basis = Basis(Vector3.UP, angle)
		var center: Vector3 = Vector3(sin(angle) * 0.105, 0.0185, cos(angle) * 0.105)
		tool.append_from(bundle, 0, Transform3D(basis, center))
	var mesh: ArrayMesh = tool.commit()
	_meshes["brush"] = mesh
	return mesh
