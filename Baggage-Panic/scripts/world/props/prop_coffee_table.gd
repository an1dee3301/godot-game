extends RefCounted
## Low lounge table: rolled oak edge, honed stone pedestal, and a kyusu tea service.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CoffeeTable"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var glazes: Array[Color] = [DesignKit.CREAM, DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO]
	var stones: Array[Color] = [DesignKit.LIMESTONE, DesignKit.PLASTER, Color(0.73, 0.71, 0.65), Color(0.82, 0.78, 0.69)]
	var glaze: Material = DesignKit.paint(glazes[style], 0.24)
	var stone: Material = DesignKit.stone(stones[style], 0.62, "coffee_pedestal_%d" % style)
	var oak: Material = DesignKit.wood(DesignKit.OAK, "oak")
	var walnut: Material = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var clay_foot: Material = DesignKit.stone(Color(0.56, 0.45, 0.34), 0.85, "coffee_unglazed")
	var tea: Material = DesignKit.paint(Color(0.26, 0.15, 0.055), 0.16)

	# A recessed black foot touches the floor; the stone reads as a single carved piece.
	_turned(root, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.255, 0.0), Vector2(0.255, 0.014), Vector2(0.0, 0.014)]), DesignKit.metal(), Vector3.ZERO)
	_turned(root, PackedVector2Array([
		Vector2(0.0, 0.014), Vector2(0.268, 0.014), Vector2(0.285, 0.025),
		Vector2(0.294, 0.05), Vector2(0.288, 0.08), Vector2(0.264, 0.12),
		Vector2(0.204, 0.245), Vector2(0.194, 0.294), Vector2(0.207, 0.322),
		Vector2(0.0, 0.322)
	]), stone, Vector3.ZERO)
	_turned(root, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.205, 0.0), Vector2(0.205, 0.008), Vector2(0.0, 0.008)]), DesignKit.brass(), Vector3(0.0, 0.322, 0.0))
	# Underside relief and the softly rolled solid-oak perimeter.
	_turned(root, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.463, 0.0), Vector2(0.475, 0.01), Vector2(0.475, 0.02), Vector2(0.0, 0.02)]), walnut, Vector3(0.0, 0.33, 0.0))
	_turned(root, PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.516, 0.0), Vector2(0.533, 0.008),
		Vector2(0.54, 0.021), Vector2(0.538, 0.037), Vector2(0.528, 0.049),
		Vector2(0.51, 0.054), Vector2(0.0, 0.054)
	]), oak, Vector3(0.0, 0.346, 0.0))

	var service: Node3D = Node3D.new()
	service.name = "TeaTray"
	service.position = Vector3(0.035, 0.4, -0.025)
	service.rotation_degrees.y = -18.0 + float(style) * 12.0
	root.add_child(service)
	# The turned tray has a raised lip and a recessed linen liner.
	_turned(service, PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.25, 0.0), Vector2(0.263, 0.007),
		Vector2(0.264, 0.027), Vector2(0.258, 0.034), Vector2(0.246, 0.034),
		Vector2(0.24, 0.027), Vector2(0.24, 0.015), Vector2(0.0, 0.015)
	]), walnut, Vector3.ZERO)
	_turned(service, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.235, 0.0), Vector2(0.235, 0.002), Vector2(0.0, 0.002)]), DesignKit.fabric(DesignKit.LINEN, "linen"), Vector3(0.0, 0.015, 0.0))
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(service, Vector3(0.014, 0.012, 0.095), Vector3(side * 0.257, 0.035, 0.0), DesignKit.brass(), 0.005)

	var pot_at: Vector3 = Vector3(-0.035, 0.017, -0.078)
	_turned(service, PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.046, 0.0), Vector2(0.049, 0.012),
		Vector2(0.07, 0.027), Vector2(0.085, 0.056), Vector2(0.086, 0.078),
		Vector2(0.078, 0.105), Vector2(0.059, 0.126), Vector2(0.052, 0.13),
		Vector2(0.0, 0.13)
	]), glaze, pot_at)
	_turned(service, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.057, 0.0), Vector2(0.061, 0.004), Vector2(0.055, 0.013), Vector2(0.035, 0.018), Vector2(0.0, 0.019)]), glaze, pot_at + Vector3(0.0, 0.132, 0.0))
	_turned(service, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.011, 0.0), Vector2(0.016, 0.012), Vector2(0.013, 0.022), Vector2(0.0, 0.025)]), walnut, pot_at + Vector3(0.0, 0.15, 0.0))
	# Hollow pouring spout: the profile returns down the inside, leaving an open mouth.
	var spout: MeshInstance3D = _turned(service, PackedVector2Array([
		Vector2(0.029, 0.0), Vector2(0.026, 0.024), Vector2(0.019, 0.065),
		Vector2(0.019, 0.08), Vector2(0.014, 0.08), Vector2(0.014, 0.06),
		Vector2(0.02, 0.02), Vector2(0.023, 0.0)
	]), glaze, pot_at + Vector3(0.06, 0.062, 0.0))
	spout.rotation_degrees.z = -55.0
	var handle: MeshInstance3D = DesignKit.add(service, _handle_mesh(), walnut, pot_at + Vector3(-0.094, 0.084, 0.0), Vector3(90.0, 0.0, 0.0))
	handle.scale = Vector3(0.85, 1.0, 1.12)
	for cup_at: Vector3 in [Vector3(-0.105, 0.017, 0.103), Vector3(0.093, 0.017, 0.095)]:
		_cup(service, cup_at, glaze, clay_foot, tea)
	# A rounded walnut tea scoop rests beside the pot.
	var scoop: MeshInstance3D = DesignKit.rbox(service, Vector3(0.018, 0.009, 0.105), Vector3(0.173, 0.025, -0.075), walnut, 0.004)
	scoop.rotation_degrees.y = -22.0
	return root


static func _cup(parent: Node3D, at: Vector3, glaze: Material, foot: Material, tea: Material) -> void:
	_turned(parent, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.061, 0.0), Vector2(0.068, 0.005), Vector2(0.069, 0.009), Vector2(0.055, 0.014), Vector2(0.0, 0.014)]), glaze, at)
	_turned(parent, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.027, 0.0), Vector2(0.027, 0.01), Vector2(0.0, 0.01)]), foot, at + Vector3(0.0, 0.013, 0.0))
	_turned(parent, PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.027, 0.0), Vector2(0.033, 0.008),
		Vector2(0.041, 0.034), Vector2(0.046, 0.064), Vector2(0.046, 0.07),
		Vector2(0.041, 0.072), Vector2(0.038, 0.064), Vector2(0.034, 0.034),
		Vector2(0.025, 0.012), Vector2(0.0, 0.012)
	]), glaze, at + Vector3(0.0, 0.023, 0.0))
	_turned(parent, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.037, 0.0), Vector2(0.0, 0.0008)]), tea, at + Vector3(0.0, 0.078, 0.0))


static func _turned(parent: Node3D, profile: PackedVector2Array, material: Material, at: Vector3) -> MeshInstance3D:
	return DesignKit.add(parent, DesignKit.lathe(profile, 48), material, at)


static func _handle_mesh() -> TorusMesh:
	if _meshes.has("pot_handle"):
		return _meshes["pot_handle"] as TorusMesh
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = 0.036
	mesh.outer_radius = 0.054
	mesh.rings = 32
	mesh.ring_segments = 10
	_meshes["pot_handle"] = mesh
	return mesh
