class_name DesignKit
extends RefCounted
## Shared Japandi design language for the terminal: softened (rounded) forms and tactile materials
## (oak grain, limestone, linen, blackened steel, brass, washi paper). Everything is generated once
## and cached, so props can use these freely.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}

const OAK := Color(0.78, 0.6, 0.42)
const WALNUT := Color(0.42, 0.29, 0.2)
const PLASTER := Color(0.9, 0.86, 0.79)
const LIMESTONE := Color(0.86, 0.82, 0.75)
const CHARCOAL := Color(0.15, 0.14, 0.13)
const LINEN := Color(0.84, 0.79, 0.7)
const SAGE := Color(0.54, 0.6, 0.48)
const CLAY := Color(0.71, 0.43, 0.31)
const INDIGO := Color(0.24, 0.31, 0.42)
const OCHRE := Color(0.8, 0.61, 0.3)
const CREAM := Color(0.97, 0.93, 0.85)


# --- Meshes ----------------------------------------------------------------------------------

## A box with every edge and corner rounded by `radius` (clamped to half the smallest side).
static func rounded_box(size: Vector3, radius: float = 0.05, segments: int = 3) -> ArrayMesh:
	var r := minf(radius, minf(size.x, minf(size.y, size.z)) * 0.5 - 0.001)
	var key := "rbox:%s:%0.3f:%d" % [size, r, segments]
	if _meshes.has(key):
		return _meshes[key]
	var half := size * 0.5
	var inner := half - Vector3.ONE * r
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Each cube face is a grid whose lines bunch up in the rounded margin.
	for axis in 3:
		for sign_value in [-1.0, 1.0]:
			var u_axis := (axis + 1) % 3
			var v_axis := (axis + 2) % 3
			var us := _grid_coords(half[u_axis], r, segments)
			var vs := _grid_coords(half[v_axis], r, segments)
			var rows: Array = []
			for v in vs:
				var row: Array = []
				for u in us:
					var q := Vector3.ZERO
					q[axis] = sign_value * half[axis]
					q[u_axis] = u
					q[v_axis] = v
					var core := q.clamp(-inner, inner)
					var n := (q - core).normalized()
					row.append([core + n * r, n, Vector2(u / size[u_axis] + 0.5, v / size[v_axis] + 0.5)])
				rows.append(row)
			for j in vs.size() - 1:
				for i in us.size() - 1:
					var a: Array = rows[j][i]
					var b: Array = rows[j][i + 1]
					var c: Array = rows[j + 1][i + 1]
					var d: Array = rows[j + 1][i]
					var quad := [a, b, c, a, c, d] if sign_value > 0.0 else [a, c, b, a, d, c]
					for vert: Array in quad:
						st.set_normal(vert[1])
						st.set_uv(vert[2])
						st.add_vertex(vert[0])
	st.generate_tangents()
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


static func _grid_coords(half_size: float, r: float, segments: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for k in segments + 1:
		out.append(-half_size + r * (1.0 - cos(float(k) / segments * PI * 0.5)))
	for k in range(segments, -1, -1):
		out.append(half_size - r * (1.0 - cos(float(k) / segments * PI * 0.5)))
	return out


## A turned profile (x = radius, y = height) — bowls, lanterns, stools, column capitals.
static func lathe(profile: PackedVector2Array, segments: int = 24) -> ArrayMesh:
	var key := "lathe:%s:%d" % [profile, segments]
	if _meshes.has(key):
		return _meshes[key]
	# Wind outward whichever way the profile was drawn (shoelace sign of the closed profile).
	var area := 0.0
	for i in profile.size():
		var p := profile[i]
		var q := profile[(i + 1) % profile.size()]
		area += p.x * q.y - q.x * p.y
	var flip := area < 0.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in segments:
		var a0 := TAU * s / segments
		var a1 := TAU * (s + 1) / segments
		for i in profile.size() - 1:
			var p0 := profile[i]
			var p1 := profile[i + 1]
			var v00 := Vector3(cos(a0) * p0.x, p0.y, sin(a0) * p0.x)
			var v01 := Vector3(cos(a1) * p0.x, p0.y, sin(a1) * p0.x)
			var v10 := Vector3(cos(a0) * p1.x, p1.y, sin(a0) * p1.x)
			var v11 := Vector3(cos(a1) * p1.x, p1.y, sin(a1) * p1.x)
			var tris := [v00, v01, v10, v01, v11, v10] if flip else [v00, v10, v01, v01, v10, v11]
			for v: Vector3 in tris:
				st.add_vertex(v)
	st.generate_normals()
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


static func add(parent: Node3D, mesh: Mesh, material: Material, at: Vector3, rotation_deg := Vector3.ZERO, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = at
	mi.rotation_degrees = rotation_deg
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func rbox(parent: Node3D, size: Vector3, at: Vector3, material: Material, radius := 0.04, shadows := true) -> MeshInstance3D:
	return add(parent, rounded_box(size, radius), material, at, Vector3.ZERO, shadows)


## Draw-call hygiene for dressed areas: fade out beyond `range_end` metres and stop tiny parts
## (smaller than `shadow_min` across) from casting sun shadows.
static func optimize(node: Node, range_end: float, shadow_min := 0.8) -> void:
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is GeometryInstance3D:
			var gi := current as GeometryInstance3D
			gi.visibility_range_end = range_end
			gi.visibility_range_end_margin = range_end * 0.15
			gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			if gi.get_aabb().size.length() * maxf(gi.global_basis.get_scale().x, 0.01) < shadow_min:
				gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pending.append_array(current.get_children())


## Shrinks Label3Ds that overlap a neighbour on the same sign (generated signs often stack lines
## too tightly). Labels are compared in their parent's space; both shrink around their centres.
static func declutter_labels(node: Node, max_passes := 8) -> void:
	var groups: Dictionary = {}
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is Label3D and current.get_parent() != null:
			var key := current.get_parent().get_instance_id()
			if not groups.has(key):
				groups[key] = []
			(groups[key] as Array).append(current)
		pending.append_array(current.get_children())
	for key: int in groups:
		var labels: Array = groups[key]
		if labels.size() < 2:
			continue
		for i in max_passes:
			var clashed := false
			for a in labels.size():
				for b in range(a + 1, labels.size()):
					var la: Label3D = labels[a]
					var lb: Label3D = labels[b]
					if absf(la.position.z - lb.position.z) > 0.05 or not la.transform.basis.is_equal_approx(lb.transform.basis):
						continue
					if _label_rect(la).grow(-0.004).intersects(_label_rect(lb).grow(-0.004)):
						la.pixel_size *= 0.88
						lb.pixel_size *= 0.88
						clashed = true
			if not clashed:
				break


## A label's text box in its parent's plane (x, y), from font metrics (get_aabb() is empty until drawn).
static func _label_rect(label: Label3D) -> Rect2:
	var font: Font = label.font if label.font != null else ThemeDB.fallback_font
	var lines := label.text.split("\n")
	var width := 0.0
	for line in lines:
		width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x)
	var height := font.get_height(label.font_size) * lines.size() + label.line_spacing * (lines.size() - 1)
	var size := Vector2(width, height) * label.pixel_size
	var centre := Vector2(label.position.x, label.position.y) + label.offset * label.pixel_size
	return Rect2(centre - size * 0.5, size)


## Merges identical opaque leaf meshes of one module into MultiMeshes (fewer draw calls).
static func batch_repeated(module_root: Node3D) -> void:
	# Tyres, rails, bolts and lamp housings often share exact mesh resources.
	# Batch only opaque leaves with no surface overrides; labels stay independent.
	var groups: Dictionary = {}
	var pending: Array[Node] = [module_root]
	while not pending.is_empty():
		var current: Node = pending.pop_back() as Node
		pending.append_array(current.get_children())
		var part: MeshInstance3D = current as MeshInstance3D
		if part == null or part.mesh == null or part.get_child_count() != 0 or not part.visible:
			continue
		var eligible: bool = true
		for surface: int in part.mesh.get_surface_count():
			if part.get_surface_override_material(surface) != null:
				eligible = false
			var material: BaseMaterial3D = part.get_active_material(surface) as BaseMaterial3D
			if material == null or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				eligible = false
		if not eligible:
			continue
		var material_id: int = part.material_override.get_instance_id() if part.material_override != null else 0
		var key: String = "%d:%d:%d" % [part.mesh.get_instance_id(), material_id, part.cast_shadow]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(part)
	var inverse: Transform3D = module_root.global_transform.affine_inverse()
	for key: String in groups:
		var parts: Array[MeshInstance3D] = []
		parts.assign(groups[key])
		if parts.size() < 2:
			continue
		var multi: MultiMesh = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = parts[0].mesh
		multi.instance_count = parts.size()
		var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instance.multimesh = multi
		instance.material_override = parts[0].material_override
		instance.cast_shadow = parts[0].cast_shadow
		for index: int in parts.size():
			multi.set_instance_transform(index, inverse * parts[index].global_transform)
		module_root.add_child(instance)
		for part: MeshInstance3D in parts:
			part.free()


# --- Materials -------------------------------------------------------------------------------

## Oak/walnut with long grain along the object's length; triplanar so any box gets it right.
static func wood(tint: Color = OAK, key := "oak") -> StandardMaterial3D:
	var id := "wood:" + key
	if _materials.has(id):
		return _materials[id]
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	var ramp := Gradient.new()
	ramp.set_color(0, tint.darkened(0.16))
	ramp.set_color(1, tint.lightened(0.1))
	var m := StandardMaterial3D.new()
	m.albedo_texture = _noise_texture(noise, ramp, Vector2i(512, 64), false)
	m.normal_enabled = true
	m.normal_texture = _noise_texture(noise, null, Vector2i(512, 64), true)
	m.normal_scale = 0.35
	m.roughness = 0.58
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.6, 0.6, 0.6)
	_materials[id] = m
	return m


## Honed stone / plaster: soft mottling and a faint tooth in the normal map.
static func stone(tint: Color = LIMESTONE, roughness := 0.5, key := "limestone") -> StandardMaterial3D:
	var id := "stone:" + key
	if _materials.has(id):
		return _materials[id]
	var noise := FastNoiseLite.new()
	noise.frequency = 0.035
	noise.fractal_octaves = 5
	var ramp := Gradient.new()
	ramp.set_color(0, tint.darkened(0.07))
	ramp.set_color(1, tint.lightened(0.05))
	var m := StandardMaterial3D.new()
	m.albedo_texture = _noise_texture(noise, ramp, Vector2i(256, 256), false)
	m.normal_enabled = true
	m.normal_texture = _noise_texture(noise, null, Vector2i(256, 256), true)
	m.normal_scale = 0.18
	m.roughness = roughness
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.35, 0.35, 0.35)
	_materials[id] = m
	return m


## Woven upholstery: fine cellular weave in the normal map, matte.
static func fabric(tint: Color = LINEN, key := "linen") -> StandardMaterial3D:
	var id := "fabric:" + key
	if _materials.has(id):
		return _materials[id]
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.25
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = _noise_texture(noise, null, Vector2i(128, 128), true)
	m.normal_scale = 0.45
	m.roughness = 0.92
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(4.0, 4.0, 4.0)
	_materials[id] = m
	return m


static func metal(tint: Color = CHARCOAL, roughness := 0.38, metallic := 0.85, key := "blackened_steel") -> StandardMaterial3D:
	var id := "metal:" + key
	if not _materials.has(id):
		var m := StandardMaterial3D.new()
		m.albedo_color = tint
		m.metallic = metallic
		m.roughness = roughness
		_materials[id] = m
	return _materials[id]


static func brass() -> StandardMaterial3D:
	return metal(Color(0.78, 0.6, 0.34), 0.32, 1.0, "brass")


## Washi paper glowing from inside: lanterns and backlit sign faces.
static func washi(tint: Color = Color(1.0, 0.86, 0.66), energy := 2.5, key := "washi") -> StandardMaterial3D:
	var id := "washi:" + key
	if not _materials.has(id):
		var m := StandardMaterial3D.new()
		m.albedo_color = tint
		m.emission_enabled = true
		m.emission = tint
		m.emission_energy_multiplier = energy
		m.roughness = 0.9
		_materials[id] = m
	return _materials[id]


static func paint(tint: Color, roughness := 0.62) -> StandardMaterial3D:
	var id := "paint:%s:%0.2f" % [tint.to_html(), roughness]
	if not _materials.has(id):
		var m := StandardMaterial3D.new()
		m.albedo_color = tint
		m.roughness = roughness
		_materials[id] = m
	return _materials[id]


static func _noise_texture(noise: FastNoiseLite, ramp: Gradient, size: Vector2i, normal: bool) -> NoiseTexture2D:
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = size.x
	tex.height = size.y
	tex.seamless = true
	if normal:
		tex.as_normal_map = true
		tex.bump_strength = 6.0
	elif ramp:
		tex.color_ramp = ramp
	return tex
