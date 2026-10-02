class_name KaitoVroid
extends RefCounted
## Dresses the CC0 VRoid boy (HairSample_Male) as Kaito Kid: the hoodie becomes a white tailored
## jacket with an open V showing a blue shirt and red tie, trousers and shoes turn white, hands get
## white gloves, plus a standing collar, two-sided cape, top hat, monocle with clover charm and a
## card gun. Rest space: metres, +Y up, +Z = his front, +X = his left. Head bone (0, 1.545, 0.006),
## eyes y 1.608 at x ±0.023, Neck 1.456, UpperChest 1.305, hair top ~1.81.

const MODEL := "res://assets/characters/vroid/hairsample_male.glb"   ## Kaito: face, hair, long-sleeved top -> jacket.
const SHIRT_MODEL := "res://assets/characters/vroid/base_male.glb"   ## Source of the shirt + tie worn under the jacket.
const HEAD_MODEL := "res://assets/characters/vroid/hairsample_male.glb"   ## Kaito's face and messy hair.
const WHITE := Color(0.95, 0.955, 0.97)
const BAND := Color(0.12, 0.26, 0.66)
const GOLD := Color(0.95, 0.78, 0.36)

## Surface roles by material name fragment.
const ROLE_SKIN := 0
const ROLE_JACKET := 1
const ROLE_TROUSERS := 2
const ROLE_SHOES := 3

static var _paint_shader: Shader


static func build(rig: HumanRig) -> Dictionary:
	# Shirt + tie under the jacket: real skinned garments transplanted from Base_Male.
	var shirt := rig.transplant_skinned(SHIRT_MODEL, ["Tops"], -0.022, ["Arm", "Shoulder"])
	var tie := rig.transplant_skinned(SHIRT_MODEL, ["Tie"], 0.002)
	_paint_outfit(rig)
	_paint_shirt(shirt)
	_paint_shirt(tie)
	var cape := _build_cape(rig)
	var head := Node3D.new()
	head.name = "HeadGear"
	rig.attach("Head", head)
	var hat := _build_hat(head)
	_build_monocle(head)
	var gun := _build_card_gun(rig)
	return {"hat": hat, "hand": gun, "cape_material": cape[0], "lining_material": cape[1]}


# --- Outfit paint ------------------------------------------------------------------------------

static func _paint_outfit(rig: HumanRig) -> void:
	var mesh := rig.body.mesh
	for s in mesh.get_surface_count():
		var base := mesh.surface_get_material(s) as BaseMaterial3D
		var name := base.resource_name if base else ""
		var role := ROLE_SKIN
		if "Tie" in name:
			role = 4
		elif "Tops" in name:
			role = ROLE_JACKET
		elif "Bottoms" in name:
			role = ROLE_TROUSERS
		elif "Shoes" in name:
			role = ROLE_SHOES
		var m := ShaderMaterial.new()
		m.shader = _shader()
		m.set_shader_parameter("role", role)
		if base and base.albedo_texture:
			m.set_shader_parameter("tex", base.albedo_texture)
		rig.body.set_surface_override_material(s, m)


## The transplanted shirt: shirt + vest texels both become the royal-blue dress shirt; tie stays red.
static func _paint_shirt(shirt: MeshInstance3D) -> void:
	for s in shirt.mesh.get_surface_count():
		var base := shirt.mesh.surface_get_material(s) as BaseMaterial3D
		var m := ShaderMaterial.new()
		m.shader = _shader()
		m.set_shader_parameter("role", 4 if base and "Tie" in base.resource_name else 5)
		if base and base.albedo_texture:
			m.set_shader_parameter("tex", base.albedo_texture)
		shirt.set_surface_override_material(s, m)


static func _shader() -> Shader:
	if _paint_shader:
		return _paint_shader
	_paint_shader = Shader.new()
	_paint_shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform int role = 0;
varying vec4 mask;
void vertex() { mask = COLOR; }
void fragment() {
	int region = int(mask.r * 16.0);
	vec3 rest = vec3(mask.g * 1.9 - 0.95, mask.b * 1.85, mask.a * 0.4 - 0.2);
	vec4 t = texture(tex, UV);
	float lum = dot(t.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = t.rgb;
	float rough = 0.6;
	float spec = 0.35;
	if (role == 0) {
		if (region == 6) { col = vec3(0.97) * mix(0.85, 1.0, lum); rough = 0.5; }   // white gloves
		else if (region == 4 || region == 5) { col = vec3(0.16, 0.32, 0.78) * mix(0.82, 1.02, lum); rough = 0.45; }   // long shirt sleeves
		else if (region == 2 || (region == 1 && rest.y < 1.47)) { col = vec3(0.13, 0.27, 0.68) * mix(0.8, 1.05, lum); rough = 0.45; }   // shirt collar
		else { rough = 0.55; spec = 0.25; }
	} else if (role == 1) {
		// Long-sleeved top -> white tailored jacket. Remove the hood, open the front.
		if (rest.y > 1.42 && (rest.z < 0.02 || abs(rest.x) < 0.125)) { discard; }   // hood + hood rim
		float open_w = -1.0;
		if (rest.z > 0.0 && rest.y > 1.06) {
			open_w = 0.014 + (1.45 - rest.y) * 0.235;   // open V to the button; buttoned closed below
			if (abs(rest.x) < open_w) { discard; }
		}
		float pocket = (rest.z > 0.03 && rest.y > 0.88 && rest.y < 1.13 && abs(rest.x) < 0.18) ? 1.0 : 0.0;   // hide the pouch pocket
		float shade = mix(smoothstep(0.35, 0.95, lum), 0.8, pocket);
		col = vec3(0.955, 0.96, 0.975) * mix(0.8, 1.04, shade);
		float d = abs(rest.x) - open_w;
		if (open_w > 0.0 && d < 0.006) { col *= 0.7; }                                        // piping on the cut edge
		else if (open_w > 0.0 && d < 0.045 && rest.y > 1.18) { col *= 1.03; rough = 0.3; }      // satin lapel
		if (rest.z > 0.0 && rest.y < 1.12 && rest.y > 1.06 && d > 0.012 && d < 0.03 && rest.x > 0.0) { col = vec3(0.86, 0.72, 0.38); rough = 0.25; }   // button
		if (!FRONT_FACING) { col *= 0.5; }
	} else if (role == 5) {
		col = vec3(0.16, 0.32, 0.78) * mix(0.7, 1.08, smoothstep(0.0, 0.8, lum));   // blue dress shirt
		rough = 0.45;
	} else if (role == 4) {
		col = vec3(0.75, 0.04, 0.08) * mix(0.75, 1.15, lum);   // red tie
		rough = 0.35;
	} else if (role == 2) {
		col = vec3(0.93, 0.935, 0.95) * mix(0.7, 1.05, smoothstep(0.0, 0.5, lum * 3.0));
		rough = 0.65;
	} else if (role == 3) {
		col = vec3(0.97) * mix(0.75, 1.0, smoothstep(0.0, 0.4, lum * 2.5));
		rough = 0.2; spec = 0.6;
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = spec;
	if (t.a < 0.5 && role == 0) { discard; }
}
"""
	return _paint_shader


# --- Collar, cape -------------------------------------------------------------------------------

static func _cloth(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _build_collar(rig: HumanRig) -> void:
	var neck := Node3D.new()
	neck.name = "Collar"
	rig.attach("Neck", neck)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 18
	var ring := func(a: float, h: float) -> Vector3:
		var r := 0.064 + h * 0.25
		return Vector3(sin(a) * r, -0.035 + h, 0.004 + cos(a) * r * 0.95)
	for i in seg:
		var a0 := lerpf(PI * 0.3, PI * 1.7, float(i) / seg)
		var a1 := lerpf(PI * 0.3, PI * 1.7, float(i + 1) / seg)
		var b0: Vector3 = ring.call(a0, 0.0)
		var b1: Vector3 = ring.call(a1, 0.0)
		var t0: Vector3 = ring.call(a0, 0.085)
		var t1: Vector3 = ring.call(a1, 0.085)
		for v in [b0, t0, b1, b1, t0, t1]:
			st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _cloth(WHITE)
	neck.add_child(mi)


## Returns [outer material, lining material].
static func _build_cape(rig: HumanRig) -> Array:
	var anchor := Node3D.new()
	anchor.name = "Cape"
	rig.attach("UpperChest", anchor)
	var outer := _cape_material(WHITE)
	var lining := _cape_material(Color(0.1, 0.2, 0.62))
	for inner in [false, true]:
		var mi := MeshInstance3D.new()
		mi.mesh = _cape_mesh(inner)
		mi.material_override = lining if inner else outer
		anchor.add_child(mi)
	return [outer, lining]


static func _cape_mesh(inner: bool) -> ArrayMesh:
	# Local to UpperChest (y 1.305). Shoulders at y ~1.43; the hem falls to just below the knees.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := 22
	var rows := 20
	for r in rows:
		var v := float(r) / (rows - 1)
		for c in cols:
			var u := float(c) / (cols - 1) * 2.0 - 1.0
			var y := lerpf(0.13, -0.78, v)
			var half_w := lerpf(0.16, 0.36, pow(v, 0.8))
			var wrap := (1.0 - v) * (1.0 - v)
			var z := -0.1 - v * 0.08 + absf(u) * wrap * 0.1 - (1.0 - u * u) * 0.025
			z += sin(u * PI * 3.0) * 0.012 * v
			if inner:
				z += 0.005
			st.set_uv(Vector2((u + 1.0) * 0.5, v))
			st.add_vertex(Vector3(u * half_w, y, z))
	for r in rows - 1:
		for c in cols - 1:
			var a := r * cols + c
			var b := a + cols
			var order := [a, a + 1, b, a + 1, b + 1, b] if inner else [a, b, a + 1, a + 1, b, b + 1]
			for i in order:
				st.add_index(i)
	st.generate_normals()
	return st.commit()


static func _cape_material(color: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	var s := Shader.new()
	s.code = """shader_type spatial;
render_mode cull_back;
uniform vec3 albedo : source_color;
uniform float speed = 0.0;
uniform float flare = 0.0;
void vertex() {
	float v = UV.y;
	float u = UV.x * 2.0 - 1.0;
	float wave = sin(TIME * (2.0 + speed * 6.0) + v * 5.0 + u * 2.0) * (0.015 + speed * 0.045) * v;
	VERTEX.z -= v * v * flare + wave;
	VERTEX.y += v * v * flare * 0.35;
	VERTEX.x += sin(TIME * 1.7 + v * 3.0) * 0.01 * v;
}
void fragment() {
	ALBEDO = albedo * (0.93 + 0.07 * sin(UV.x * 18.85));
	ROUGHNESS = 0.6;
	SPECULAR = 0.3;
}
"""
	m.shader = s
	m.set_shader_parameter("albedo", color)
	return m


# --- Head gear (Head bone space: origin at y 1.545) ---------------------------------------------

static func _build_hat(head: Node3D) -> Node3D:
	var hat := Node3D.new()
	hat.name = "TopHat"
	hat.position = Vector3(0.0, 0.185, -0.018)
	hat.scale = Vector3.ONE * 1.12
	hat.rotation = Vector3(deg_to_rad(-6.0), 0.0, deg_to_rad(5.0))
	head.add_child(hat)
	var silk := StandardMaterial3D.new()
	silk.albedo_color = Color(0.97, 0.97, 0.985)
	silk.roughness = 0.3
	silk.clearcoat_enabled = true
	silk.clearcoat = 0.4
	var band := StandardMaterial3D.new()
	band.albedo_color = BAND
	band.roughness = 0.4
	var profile: Array[Vector2] = [
		Vector2(-0.012, 0.0), Vector2(-0.012, 0.13), Vector2(-0.006, 0.162), Vector2(0.008, 0.166),
		Vector2(0.004, 0.145), Vector2(0.0, 0.098), Vector2(0.06, 0.094), Vector2(0.165, 0.098),
		Vector2(0.172, 0.1), Vector2(0.176, 0.0)]
	var crown := MeshInstance3D.new()
	crown.mesh = _lathe(profile, 40)
	crown.material_override = silk
	crown.scale = Vector3(1.0, 1.0, 1.1)
	hat.add_child(crown)
	var band_mesh := CylinderMesh.new()
	band_mesh.top_radius = 0.097
	band_mesh.bottom_radius = 0.096
	band_mesh.height = 0.034
	band_mesh.radial_segments = 40
	var band_mi := MeshInstance3D.new()
	band_mi.mesh = band_mesh
	band_mi.material_override = band
	band_mi.position.y = 0.02
	band_mi.scale = Vector3(1.0, 1.0, 1.1)
	hat.add_child(band_mi)
	return hat


static func _build_monocle(head: Node3D) -> void:
	# His right eye: (-0.023, 1.608, 0.037) eyeball centre -> in front of the face.
	var eye := Vector3(-0.025, 0.062, 0.104)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = GOLD
	gold.metallic = 1.0
	gold.roughness = 0.25
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.016
	torus.outer_radius = 0.019
	torus.rings = 24
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = gold
	ring.position = eye
	ring.rotation.x = PI * 0.5
	head.add_child(ring)
	var glass := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.016
	disc.bottom_radius = 0.016
	disc.height = 0.002
	glass.mesh = disc
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.85, 0.92, 1.0, 0.16)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.02
	glass.material_override = glass_mat
	glass.position = eye
	glass.rotation.x = PI * 0.5
	head.add_child(glass)
	var link := SphereMesh.new()
	link.radius = 0.0024
	link.height = 0.0048
	link.radial_segments = 6
	link.rings = 3
	for i in 11:
		var t := i / 10.0
		var mi := MeshInstance3D.new()
		mi.mesh = link
		mi.material_override = gold
		mi.position = eye + Vector3(-0.018 - t * 0.012, -t * 0.06 - sin(t * PI) * 0.005, -t * 0.02)
		head.add_child(mi)
	var clover := Node3D.new()
	clover.position = eye + Vector3(-0.031, -0.07, -0.022)
	head.add_child(clover)
	var leaf := SphereMesh.new()
	leaf.radius = 0.0055
	leaf.height = 0.0035
	for k in 4:
		var mi := MeshInstance3D.new()
		mi.mesh = leaf
		mi.material_override = gold
		var a := k * PI * 0.5 + PI * 0.25
		mi.position = Vector3(cos(a), sin(a), 0.0) * 0.005
		mi.rotation.x = PI * 0.5
		clover.add_child(mi)


static func _build_card_gun(rig: HumanRig) -> Node3D:
	var hand := Node3D.new()
	hand.name = "CardGun"
	rig.attach("RightHand", hand)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.97, 0.97, 0.99)
	white.roughness = 0.3
	var accent := StandardMaterial3D.new()
	accent.albedo_color = BAND
	# Hand bone +Y runs along the fingers.
	var barrel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.03, 0.15, 0.04)
	barrel.mesh = box
	barrel.material_override = white
	barrel.position = Vector3(0.0, 0.09, 0.03)
	hand.add_child(barrel)
	var grip := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(0.026, 0.045, 0.08)
	grip.mesh = gbox
	grip.material_override = accent
	grip.position = Vector3(0.0, 0.035, -0.01)
	hand.add_child(grip)
	hand.visible = false
	return hand


static func _lathe(profile: Array[Vector2], segments: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in segments:
		var a0 := TAU * s / segments
		var a1 := TAU * (s + 1) / segments
		for i in profile.size() - 1:
			var p0 := profile[i]
			var p1 := profile[i + 1]
			var v00 := Vector3(cos(a0) * p0.y, p0.x, sin(a0) * p0.y)
			var v01 := Vector3(cos(a1) * p0.y, p0.x, sin(a1) * p0.y)
			var v10 := Vector3(cos(a0) * p1.y, p1.x, sin(a0) * p1.y)
			var v11 := Vector3(cos(a1) * p1.y, p1.x, sin(a1) * p1.y)
			for v in [v00, v10, v01, v01, v10, v11]:
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()
