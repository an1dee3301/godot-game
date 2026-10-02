class_name GuardLook
extends RefCounted
## Dresses the CC0 VRoid Base_Male as museum security (navy vest, light-blue shirt, navy tie,
## peaked cap, badge, duty belt, flashlight) or as the Inspector (tan trench coat with tails,
## red tie, fedora, moustache, megaphone). Rest space: +Z front, +X his left.
## Head bone y 1.545, Neck 1.456, UpperChest 1.305, Hips 1.008.

const MODEL := "res://assets/characters/vroid/base_male.glb"

const ROLE_SKIN := 0
const ROLE_TOPS := 1
const ROLE_TIE := 2
const ROLE_BOTTOMS := 3
const ROLE_SHOES := 4
const ROLE_HAIR := 5

const HAIR_TINTS := [Color(0.12, 0.09, 0.08), Color(0.2, 0.13, 0.08), Color(0.06, 0.06, 0.07), Color(0.32, 0.2, 0.11), Color(0.16, 0.12, 0.1)]

static var _shader: Shader


## Returns the node to hang the flashlight beam from (right hand), or the megaphone hand.
static func build(rig: HumanRig, inspector: bool, variant: int) -> Node3D:
	_paint(rig, inspector, variant)
	var head := Node3D.new()
	head.name = "HeadGear"
	rig.attach("Head", head)
	if inspector:
		_fedora(head)
		_moustache(head)
		_coat_tails(rig)
	else:
		_police_cap(head)
		_badge(rig)
	_belt(rig, inspector)
	var hand := Node3D.new()
	hand.name = "HeldItem"
	rig.attach("RightHand", hand)
	if not inspector:
		_flashlight_body(hand)
	return hand


static func _paint(rig: HumanRig, inspector: bool, variant: int) -> void:
	var mesh := rig.body.mesh
	var meshes: Array[MeshInstance3D] = [rig.body]
	for mi in rig.skeleton.find_children("*", "MeshInstance3D", true, false):
		if mi != rig.body and mi.mesh:
			meshes.append(mi)
	for mi in meshes:
		for s in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if base == null:
				continue
			var n := base.resource_name
			var role := ROLE_SKIN
			if "Tie" in n:
				role = ROLE_TIE
			elif "Tops" in n:
				role = ROLE_TOPS
			elif "Bottoms" in n:
				role = ROLE_BOTTOMS
			elif "Shoes" in n:
				role = ROLE_SHOES
			elif "HAIR" in n:
				role = ROLE_HAIR
			if role == ROLE_SKIN and mi != rig.body:
				continue   # face/eyes keep their own anime materials
			var m := ShaderMaterial.new()
			m.shader = _get_shader()
			m.set_shader_parameter("role", role)
			m.set_shader_parameter("inspector", inspector)
			m.set_shader_parameter("hair_tint", HAIR_TINTS[variant % HAIR_TINTS.size()])
			if base.albedo_texture:
				m.set_shader_parameter("tex", base.albedo_texture)
			mi.set_surface_override_material(s, m)


static func _get_shader() -> Shader:
	if _shader:
		return _shader
	_shader = Shader.new()
	_shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform int role = 0;
uniform bool inspector = false;
uniform vec3 hair_tint : source_color = vec3(0.1);
void fragment() {
	vec4 t = texture(tex, UV);
	float lum = dot(t.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = t.rgb;
	float rough = 0.7;
	if (role == 1) {
		if (inspector) {
			col = vec3(0.6, 0.47, 0.32) * mix(0.55, 1.15, lum * 1.6);          // trench coat
		} else if (lum > 0.55) {
			col = vec3(0.72, 0.82, 0.95) * mix(0.8, 1.05, lum);             // light-blue shirt
		} else {
			col = vec3(0.07, 0.12, 0.26) * mix(0.7, 1.4, lum * 3.0);        // navy vest
		}
	} else if (role == 2) {
		col = inspector ? vec3(0.7, 0.05, 0.07) * mix(0.7, 1.1, lum) : vec3(0.05, 0.08, 0.18) * mix(0.8, 1.3, lum);
		rough = 0.45;
	} else if (role == 3) {
		col = inspector ? vec3(0.28, 0.22, 0.17) * mix(0.6, 1.4, lum * 3.0) : vec3(0.05, 0.08, 0.17) * mix(0.6, 1.5, lum * 3.0);
	} else if (role == 4) {
		col = vec3(0.04) * mix(0.6, 2.0, lum * 2.0);
		rough = 0.25;
	} else if (role == 5) {
		col = hair_tint * mix(0.6, 1.8, lum);
		rough = 0.5;
	}
	if (t.a < 0.5 && role == 0) { discard; }
	if (!FRONT_FACING) { col *= 0.5; }
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.35;
}
"""
	return _shader


static func _mat(color: Color, rough := 0.6, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m


static func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scale := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scale
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _cyl(top: float, bottom: float, height: float, segs := 24) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = segs
	return c


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 20
	s.rings = 10
	return s


# Head-bone space: origin y 1.545; skull top ~1.72 (short hair), face front z ~0.1.
static func _police_cap(head: Node3D) -> void:
	var navy := _mat(Color(0.06, 0.09, 0.18), 0.55)
	var black := _mat(Color(0.03, 0.03, 0.035), 0.2)
	var gold := _mat(Color(0.95, 0.75, 0.32), 0.3, 0.8)
	var cap := Node3D.new()
	cap.position = Vector3(0, 0.155, -0.005)
	cap.rotation.x = deg_to_rad(-4.0)
	head.add_child(cap)
	_mesh(cap, _cyl(0.1, 0.098, 0.045), black, Vector3(0, 0.0, 0))                  # band
	_mesh(cap, _cyl(0.125, 0.1, 0.06), navy, Vector3(0, 0.05, 0), Vector3(1, 1, 1.08))   # crown
	var top := _mesh(cap, _sphere(0.126), navy, Vector3(0, 0.08, 0), Vector3(1, 0.18, 1.08))
	top.name = "CapTop"
	var visor := _mesh(cap, _sphere(0.1), black, Vector3(0, -0.012, 0.09), Vector3(0.95, 0.09, 0.62), Vector3(deg_to_rad(12), 0, 0))
	visor.name = "Visor"
	_mesh(cap, _cyl(0.018, 0.018, 0.006, 12), gold, Vector3(0, 0.045, 0.118), Vector3.ONE, Vector3(PI * 0.5, 0, 0))


static func _fedora(head: Node3D) -> void:
	var felt := _mat(Color(0.2, 0.14, 0.09), 0.7)
	var band := _mat(Color(0.08, 0.06, 0.05), 0.5)
	var hat := Node3D.new()
	hat.position = Vector3(0, 0.15, -0.005)
	head.add_child(hat)
	_mesh(hat, _cyl(0.2, 0.2, 0.012, 32), felt, Vector3(0, 0.0, 0.0), Vector3(1, 1, 1.1))
	_mesh(hat, _cyl(0.095, 0.112, 0.12), felt, Vector3(0, 0.065, 0), Vector3(1, 1, 1.12))
	_mesh(hat, _cyl(0.113, 0.113, 0.028), band, Vector3(0, 0.02, 0), Vector3(1, 1, 1.12))


static func _moustache(head: Node3D) -> void:
	var hair := _mat(Color(0.06, 0.05, 0.045), 0.6)
	for side in [-1.0, 1.0]:
		_mesh(head, _sphere(0.03), hair, Vector3(side * 0.022, 0.0, 0.098), Vector3(1.0, 0.32, 0.45), Vector3(0, 0, side * -0.35))


static func _badge(rig: HumanRig) -> void:
	var chest := Node3D.new()
	rig.attach("UpperChest", chest)
	var gold := _mat(Color(0.96, 0.78, 0.35), 0.28, 0.85)
	# Over his left breast, on the vest surface.
	_mesh(chest, _cyl(0.022, 0.022, 0.006, 6), gold, Vector3(0.065, 0.04, 0.105), Vector3.ONE, Vector3(PI * 0.5, 0, 0))


static func _belt(rig: HumanRig, inspector: bool) -> void:
	var hips := Node3D.new()
	rig.attach("Hips", hips)
	var leather := _mat(Color(0.04, 0.035, 0.03) if not inspector else Color(0.35, 0.25, 0.15), 0.5)
	var gold := _mat(Color(0.9, 0.75, 0.38), 0.3, 0.8)
	_mesh(hips, _cyl(0.142, 0.142, 0.045, 28), leather, Vector3(0, 0.02, 0.0), Vector3(1, 1, 0.82))
	_mesh(hips, _cyl(0.02, 0.02, 0.006, 4), gold, Vector3(0, 0.02, 0.118), Vector3(1.3, 1, 1), Vector3(PI * 0.5, 0, 0))
	if not inspector:
		var baton := _mesh(hips, _cyl(0.016, 0.016, 0.42, 10), leather, Vector3(-0.15, -0.12, -0.02))
		baton.rotation.z = -0.18


static func _coat_tails(rig: HumanRig) -> void:
	# A flared skirt from the waist to the knees, open at the front, following the hips.
	var hips := Node3D.new()
	rig.attach("Hips", hips)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 24
	var rows := 6
	for r in rows:
		for i in segs + 1:
			var v := float(r) / (rows - 1)
			var a := lerpf(0.22, TAU - 0.22, float(i) / segs) + PI * 0.5
			var radius := lerpf(0.16, 0.25, v)
			st.set_uv(Vector2(float(i) / segs, v))
			st.add_vertex(Vector3(cos(a) * radius, lerpf(0.0, -0.5, v), sin(a) * radius * 0.85))
	for r in rows - 1:
		for i in segs:
			var a := r * (segs + 1) + i
			var b := a + segs + 1
			for k in [a, b, a + 1, a + 1, b, b + 1]:
				st.add_index(k)
	st.generate_normals()
	var coat := _mat(Color(0.5, 0.39, 0.26), 0.8)
	coat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh(hips, st.commit(), coat, Vector3(0, 0.02, -0.01))


static func _flashlight_body(hand: Node3D) -> void:
	var black := _mat(Color(0.05, 0.05, 0.06), 0.35, 0.6)
	var lens := _mat(Color(1.0, 0.95, 0.8), 0.1)
	lens.emission_enabled = true
	lens.emission = Color(1.0, 0.9, 0.7)
	lens.emission_energy_multiplier = 2.0
	# Hand bone +Y runs along the fingers; the torch sticks out of the fist.
	var torch := _mesh(hand, _cyl(0.022, 0.017, 0.2, 14), black, Vector3(0.0, 0.07, 0.035), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	torch.name = "Torch"
	_mesh(hand, _cyl(0.026, 0.026, 0.01, 14), lens, Vector3(0.0, 0.07, 0.14), Vector3.ONE, Vector3(PI * 0.5, 0, 0))


static func _megaphone(hand: Node3D) -> void:
	var white := _mat(Color(0.9, 0.9, 0.88), 0.4)
	var red := _mat(Color(0.75, 0.08, 0.06), 0.4)
	_mesh(hand, _cyl(0.09, 0.03, 0.24, 20), white, Vector3(0.0, 0.08, 0.13), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_mesh(hand, _cyl(0.092, 0.092, 0.02, 20), red, Vector3(0.0, 0.08, 0.25), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
