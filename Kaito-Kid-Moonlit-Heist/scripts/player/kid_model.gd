extends RefCounted
## Procedural, smoothly lofted Kaito costume. All dimensions are metres.

static func material(color: Color, roughness: float = 0.55, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


static func part(parent: Node3D, name: String, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = name
	item.mesh = mesh
	item.position = pos
	item.material_override = mat
	parent.add_child(item)
	return item


static func ellipsoid(parent: Node3D, name: String, pos: Vector3, radii: Vector3, mat: Material) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 20
	sphere.rings = 10
	var item := part(parent, name, sphere, pos, mat)
	item.scale = radii
	return item


# Each profile entry is (height, x radius, z radius, z offset).
static func loft(profile: Array[Vector4], sides: int = 18) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(profile.size()):
		var p := profile[ring]
		for s in range(sides + 1):
			var a := TAU * float(s) / float(sides)
			st.set_uv(Vector2(float(s) / sides, float(ring) / maxi(1, profile.size() - 1)))
			st.add_vertex(Vector3(cos(a) * p.y, p.x, sin(a) * p.z + p.w))
	for ring in range(profile.size() - 1):
		for s in range(sides):
			var a := ring * (sides + 1) + s
			var b := a + sides + 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(a + 1)
			st.add_index(a + 1)
			st.add_index(b)
			st.add_index(b + 1)
	st.generate_normals()
	return st.commit()


static func tube(parent: Node3D, name: String, start: Vector3, finish: Vector3, radii: Vector3, mat: Material) -> MeshInstance3D:
	var length := start.distance_to(finish)
	var mesh := loft([Vector4(0.0, radii.x * 0.75, radii.z * 0.75, 0.0), Vector4(length * 0.12, radii.x, radii.z, 0.0), Vector4(length * 0.52, radii.y, radii.z * 0.9, 0.0), Vector4(length * 0.88, radii.y * 0.76, radii.z * 0.72, 0.0), Vector4(length, radii.y * 0.65, radii.z * 0.65, 0.0)])
	var item := part(parent, name, mesh, start, mat)
	item.quaternion = Quaternion(Vector3.UP, (finish - start).normalized())
	return item


static func triangle(parent: Node3D, name: String, points: PackedVector3Array, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in points:
		st.add_vertex(p)
	st.generate_normals()
	var item := part(parent, name, st.commit(), Vector3.ZERO, mat)
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func hat_mesh() -> ArrayMesh:
	# Narrow crown, slight flare at the top and a curled silk brim.
	return loft([Vector4(-0.025, 0.23, 0.215, 0.0), Vector4(-0.018, 0.30, 0.285, 0.0), Vector4(0.0, 0.325, 0.30, 0.0), Vector4(0.025, 0.31, 0.29, 0.0), Vector4(0.038, 0.23, 0.215, 0.0), Vector4(0.06, 0.205, 0.19, 0.0), Vector4(0.11, 0.205, 0.19, 0.0), Vector4(0.35, 0.195, 0.18, 0.0), Vector4(0.415, 0.21, 0.195, 0.0), Vector4(0.428, 0.205, 0.19, 0.0)], 28)


static func cape_mesh(inner: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns := 25
	var rows := 18
	for row in range(rows):
		var v := float(row) / float(rows - 1)
		for col in range(columns):
			var u := float(col) / float(columns - 1)
			var across := u * 2.0 - 1.0
			var width := lerpf(0.34, 0.76, v)
			var fold := cos(across * PI * 5.0) * 0.022 * v
			var z := 0.18 + v * 0.20 + (1.0 - across * across) * 0.07 + fold
			if inner:
				z -= 0.013
			st.set_uv(Vector2(u, v))
			st.add_vertex(Vector3(across * width, 0.47 - v * 1.23, z))
	for row in range(rows - 1):
		for col in range(columns - 1):
			var a := row * columns + col
			var b := a + columns
			if inner:
				st.add_index(a)
				st.add_index(b)
				st.add_index(a + 1)
				st.add_index(a + 1)
				st.add_index(b)
				st.add_index(b + 1)
			else:
				st.add_index(a)
				st.add_index(a + 1)
				st.add_index(b)
				st.add_index(a + 1)
				st.add_index(b + 1)
				st.add_index(b)
	st.generate_normals()
	return st.commit()


static func build(owner: Node3D) -> Dictionary:
	var silk := material(Color(0.98, 0.985, 1.0), 0.48)
	var cloth := material(Color(0.93, 0.95, 0.985), 0.58)
	var blue := material(Color(0.055, 0.13, 0.47), 0.35)
	var scarlet := material(Color(0.75, 0.055, 0.09), 0.62)
	var skin := material(Color(0.94, 0.72, 0.58), 0.72)
	var hair := material(Color(0.065, 0.04, 0.045), 0.8)
	var ink := material(Color(0.025, 0.028, 0.05), 0.3)
	var gold := material(Color(0.96, 0.75, 0.27), 0.2, 0.72)
	var blush := material(Color(0.47, 0.19, 0.19), 0.8)
	var model := Node3D.new()
	model.name = "Model"
	owner.add_child(model)
	var hips := Node3D.new()
	hips.name = "Hips"
	hips.position.y = 0.94
	model.add_child(hips)
	part(hips, "TailoredHips", loft([Vector4(-0.16, 0.18, 0.12, 0.0), Vector4(-0.10, 0.23, 0.15, 0.0), Vector4(0.03, 0.22, 0.15, 0.0), Vector4(0.11, 0.19, 0.13, 0.0)]), Vector3.ZERO, cloth)
	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position.y = 0.12
	hips.add_child(torso)
	part(torso, "TailoredJacket", loft([Vector4(-0.15, 0.23, 0.14, 0.0), Vector4(-0.09, 0.24, 0.15, 0.0), Vector4(0.04, 0.18, 0.125, 0.0), Vector4(0.23, 0.22, 0.145, 0.0), Vector4(0.36, 0.265, 0.16, 0.0), Vector4(0.48, 0.24, 0.135, 0.0), Vector4(0.53, 0.13, 0.105, 0.0)]), Vector3.ZERO, cloth)
	# Shirt and tailored lapels sit just in front of the jacket's smoothly tapered chest.
	ellipsoid(torso, "ScarletShirt", Vector3(0.0, 0.28, -0.143), Vector3(0.125, 0.245, 0.026), scarlet)
	triangle(torso, "LeftLapel", PackedVector3Array([Vector3(-0.18, 0.47, -0.12), Vector3(-0.035, 0.18, -0.18), Vector3(-0.15, 0.27, -0.17)]), silk)
	triangle(torso, "RightLapel", PackedVector3Array([Vector3(0.18, 0.47, -0.12), Vector3(0.15, 0.27, -0.17), Vector3(0.035, 0.18, -0.18)]), silk)
	triangle(torso, "BlueTie", PackedVector3Array([Vector3(-0.03, 0.45, -0.177), Vector3(0.03, 0.45, -0.177), Vector3(0.0, 0.16, -0.195)]), blue)
	ellipsoid(torso, "TieKnot", Vector3(0.0, 0.46, -0.18), Vector3(0.04, 0.026, 0.018), blue)
	for i in range(2):
		ellipsoid(torso, "PearlButton", Vector3(-0.13 + i * 0.26, 0.04, -0.152), Vector3(0.012, 0.012, 0.005), gold)
	var head := Node3D.new()
	head.name = "Head"
	head.position.y = 0.48
	torso.add_child(head)
	tube(head, "Neck", Vector3(0.0, -0.06, 0.0), Vector3(0.0, 0.04, 0.0), Vector3(0.078, 0.078, 0.075), skin)
	part(head, "Face", loft([Vector4(-0.11, 0.055, 0.065, -0.012), Vector4(-0.07, 0.105, 0.11, -0.015), Vector4(0.02, 0.155, 0.145, -0.01), Vector4(0.14, 0.175, 0.16, 0.0), Vector4(0.25, 0.14, 0.135, 0.015), Vector4(0.29, 0.065, 0.06, 0.02)]), Vector3.ZERO, skin)
	ellipsoid(head, "Nose", Vector3(0.0, 0.045, -0.159), Vector3(0.025, 0.035, 0.035), skin)
	for side in [-1.0, 1.0]:
		ellipsoid(head, "Ear", Vector3(side * 0.17, 0.09, 0.0), Vector3(0.034, 0.052, 0.028), skin)
		ellipsoid(head, "EyeWhite", Vector3(side * 0.075, 0.115, -0.151), Vector3(0.035, 0.016, 0.009), silk)
		ellipsoid(head, "Eye", Vector3(side * 0.075, 0.114, -0.161), Vector3(0.012, 0.013, 0.006), ink)
		var brow := ellipsoid(head, "Brow", Vector3(side * 0.076, 0.15, -0.152), Vector3(0.047, 0.009, 0.008), hair)
		brow.rotation.z = side * 0.12
	ellipsoid(head, "Smirk", Vector3(0.017, -0.038, -0.114), Vector3(0.042, 0.006, 0.004), blush).rotation.z = -0.12
	ellipsoid(head, "Hair", Vector3(0.0, 0.235, 0.018), Vector3(0.172, 0.07, 0.155), hair)
	for i in range(7):
		var x := -0.15 + float(i) * 0.05
		var tip := Vector3(x + sin(float(i) * 2.1) * 0.035, 0.10 + fmod(float(i) * 0.047, 0.075), -0.19)
		tube(head, "MessyFringe", Vector3(x, 0.23, -0.09), tip, Vector3(0.028, 0.003, 0.027), hair)
	var hat := Node3D.new()
	hat.name = "Hat"
	hat.position.y = 0.275
	head.add_child(hat)
	part(hat, "SilkTopHat", hat_mesh(), Vector3.ZERO, silk)
	ellipsoid(hat, "HatCrownTop", Vector3(0.0, 0.428, 0.0), Vector3(0.205, 0.011, 0.19), silk)
	part(hat, "SatinBand", loft([Vector4(0.058, 0.207, 0.192, 0.0), Vector4(0.063, 0.211, 0.196, 0.0), Vector4(0.125, 0.209, 0.194, 0.0), Vector4(0.13, 0.206, 0.19, 0.0)], 28), Vector3.ZERO, blue)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.047
	ring.outer_radius = 0.055
	var monocle := part(head, "Monocle", ring, Vector3(0.076, 0.115, -0.178), gold)
	monocle.rotation.x = PI * 0.5
	var glass := material(Color(0.75, 0.9, 1.0, 0.26), 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ellipsoid(head, "MonocleGlass", Vector3(0.076, 0.115, -0.178), Vector3(0.046, 0.046, 0.003), glass)
	ellipsoid(head, "MonocleGlint", Vector3(0.058, 0.135, -0.183), Vector3(0.012, 0.003, 0.002), silk).rotation.z = -0.7
	for i in range(12):
		var t := float(i) / 11.0
		ellipsoid(head, "GoldChain", Vector3(0.129 + 0.082 * t, 0.085 - 0.32 * t, -0.171 + 0.015 * sin(t * PI)), Vector3(0.005, 0.005, 0.005), gold)
	var charm := Vector3(0.213, -0.246, -0.154)
	for offset in [Vector3(-0.012, 0.01, 0.0), Vector3(0.012, 0.01, 0.0), Vector3(-0.012, -0.012, 0.0), Vector3(0.012, -0.012, 0.0)]:
		ellipsoid(head, "Clover", charm + offset, Vector3(0.013, 0.013, 0.006), gold)
	var arms: Array[Node3D] = []
	var legs: Array[Node3D] = []
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "LeftArm" if side < 0 else "RightArm"
		arm.position = Vector3(side * 0.28, 0.43, 0.0)
		torso.add_child(arm)
		arms.append(arm)
		tube(arm, "FittedSleeve", Vector3.ZERO, Vector3(side * 0.06, -0.43, -0.015), Vector3(0.105, 0.08, 0.095), cloth)
		ellipsoid(arm, "RoundedShoulder", Vector3(0.0, -0.055, 0.0), Vector3(0.107, 0.09, 0.098), cloth)
		part(arm, "SilkCuff", loft([Vector4(-0.448, 0.079, 0.077, 0.0), Vector4(-0.416, 0.085, 0.079, 0.0), Vector4(-0.405, 0.082, 0.077, 0.0)]), Vector3(side * 0.06, 0.0, -0.015), silk)
		ellipsoid(arm, "GlovePalm", Vector3(side * 0.065, -0.48, -0.02), Vector3(0.078, 0.09, 0.053), silk)
		for finger in range(4):
			var fx: float = side * 0.065 + (float(finger) - 1.5) * 0.026
			tube(arm, "GlovedFinger", Vector3(fx, -0.52, -0.025), Vector3(fx, -0.60 + absf(float(finger) - 1.5) * 0.011, -0.024), Vector3(0.013, 0.011, 0.013), silk)
		tube(arm, "Thumb", Vector3(side * 0.11, -0.46, -0.025), Vector3(side * 0.14, -0.53, -0.08), Vector3(0.019, 0.012, 0.019), silk)
		var leg := Node3D.new()
		leg.name = "LeftLeg" if side < 0 else "RightLeg"
		leg.position = Vector3(side * 0.135, -0.04, 0.0)
		hips.add_child(leg)
		legs.append(leg)
		tube(leg, "TailoredTrouser", Vector3.ZERO, Vector3(side * 0.02, -0.72, 0.005), Vector3(0.112, 0.09, 0.112), cloth)
		ellipsoid(leg, "WhiteShoe", Vector3(side * 0.02, -0.76, -0.065), Vector3(0.103, 0.065, 0.18), silk)
		part(leg, "TrouserCrease", tube_mesh(0.004, 0.57), Vector3(-side * 0.014, -0.12, -0.104), silk)
	var cape_shader := Shader.new()
	cape_shader.code = "shader_type spatial; render_mode cull_disabled; uniform float speed = 0.0; uniform float flare = 0.0; uniform vec3 cloth_color = vec3(0.97, 0.98, 1.0); void vertex() { float t = UV.y; VERTEX.x += (sin(TIME * 2.0 + UV.x * 9.0 + t * 4.0) * 0.035 + sin(TIME * 7.0 + t * 8.0) * speed * 0.04) * t; VERTEX.z += t * t * flare + sin(TIME * 3.0 + UV.x * 7.0) * t * 0.025; } void fragment() { ALBEDO = cloth_color; ROUGHNESS = 0.57; SPECULAR = 0.55; }"
	var cape_mat := ShaderMaterial.new()
	cape_mat.shader = cape_shader
	var cape := part(torso, "Cape", cape_mesh(false), Vector3.ZERO, cape_mat)
	var lining := ShaderMaterial.new()
	lining.shader = cape_shader
	lining.set_shader_parameter("cloth_color", Vector3(0.06, 0.15, 0.54))
	part(torso, "RoyalBlueLining", cape_mesh(true), Vector3.ZERO, lining)
	for side in [-1.0, 1.0]:
		tube(torso, "StandingCollar", Vector3(side * 0.19, 0.47, 0.12), Vector3(side * 0.15, 0.63, 0.14), Vector3(0.07, 0.055, 0.025), silk)
	var rim := OmniLight3D.new()
	rim.name = "SilkRim"
	rim.position = Vector3(0.0, 0.38, 0.35)
	rim.light_color = Color(0.77, 0.85, 1.0)
	rim.light_energy = 0.18
	rim.omni_range = 2.2
	rim.shadow_enabled = false
	model.add_child(rim)
	return {"model": model, "hips": hips, "torso": torso, "head": head, "hat": hat, "left_arm": arms[0], "right_arm": arms[1], "left_leg": legs[0], "right_leg": legs[1], "right_hand": arms[1], "cape": cape, "cape_material": cape_mat, "lining_material": lining}


static func tube_mesh(radius: float, length: float) -> ArrayMesh:
	return loft([Vector4(0.0, radius, radius, 0.0), Vector4(length, radius, radius, 0.0)], 8)
