class_name HumanRig
extends Node3D
## A realistic rigged human (Quaternius Superhero Male, CC0) with the Universal Animation Library,
## dressed by a region-masked costume shader. Shared by the player (Kaito Kid) and the guards.
##
## Region ids are baked into vertex COLOR.r from each vertex's dominant bone, so the costume follows
## the skinned mesh in every animation. COLOR.g/b/a hold the rest-pose position (x, y, z) normalised
## to 0..1 inside the body bounds, for finer masks (shirt V, tie, belt line, collar) in the shader.

const MODEL_SCENE := "res://addons/quaternius_ik_rigged/Models_with_rigging/Master_Rigged.tscn"
const LIBRARY := "UAL1_Standard"

enum Region { HEAD, NECK, TORSO, HIPS, UPPER_ARM, LOWER_ARM, HAND, UPPER_LEG, LOWER_LEG, FOOT }

## Rest-pose bounds used to normalise COLOR.gba (metres, model space).
const BOUNDS_MIN := Vector3(-0.95, 0.0, -0.2)
const BOUNDS_SIZE := Vector3(1.9, 1.85, 0.4)

static var _mesh_cache: Dictionary = {}   ## source mesh -> ArrayMesh with baked COLOR

var skeleton: Skeleton3D
var body: MeshInstance3D
var anim: AnimationPlayer
var costume: ShaderMaterial


## Builds the rig. `aliases` maps our animation names to library clips, e.g. {"idle": "Idle"}.
## `loops` lists our names that must loop. Root-motion translation on the hips is stripped so
## CharacterBody3D movement drives position.
## Body-shape presets: per-bone (lateral, depth) squeeze toward the bone axis in the rest pose.
const SHAPE_HERO := {}
const SHAPE_SLIM := {
	"Hips": Vector2(0.84, 0.88), "Spine": Vector2(0.74, 0.8), "Chest": Vector2(0.66, 0.74),
	"UpperChest": Vector2(0.56, 0.68), "LeftShoulder": Vector2(0.48, 0.62), "RightShoulder": Vector2(0.48, 0.62),
	"Neck": Vector2(0.74, 0.8), "LeftUpperArm": Vector2(0.46, 0.5), "RightUpperArm": Vector2(0.46, 0.5),
	"LeftLowerArm": Vector2(0.68, 0.68), "RightLowerArm": Vector2(0.68, 0.68),
	"LeftUpperLeg": Vector2(0.78, 0.78), "RightUpperLeg": Vector2(0.78, 0.78),
	"LeftLowerLeg": Vector2(0.82, 0.82), "RightLowerLeg": Vector2(0.82, 0.82),
}
const SHAPE_REGULAR := {
	"Spine": Vector2(0.92, 0.95), "Chest": Vector2(0.88, 0.9), "UpperChest": Vector2(0.86, 0.88),
	"LeftShoulder": Vector2(0.88, 0.9), "RightShoulder": Vector2(0.88, 0.9),
	"LeftUpperArm": Vector2(0.82, 0.82), "RightUpperArm": Vector2(0.82, 0.82),
	"LeftLowerArm": Vector2(0.88, 0.88), "RightLowerArm": Vector2(0.88, 0.88),
	"LeftUpperLeg": Vector2(0.92, 0.92), "RightUpperLeg": Vector2(0.92, 0.92),
}

var _shape: Dictionary = {}


## Builds an anime VRoid character (CC0, imported with the humanoid BoneMap so its skeleton is
## `%GeneralSkeleton` with standard bone names) and drives it with the same animation library.
## VRoid models already face -Z. `body` is the "Body" mesh (skin + Tops/Bottoms/Shoes surfaces).
func build_vroid(model_path: String, aliases: Dictionary, loops: Array = []) -> void:
	var scene := (load(model_path) as PackedScene).instantiate()
	add_child(scene)
	# The GLB was rotated to face +Z for Godot's humanoid retargeting; turn it to look down -Z.
	scene.rotation.y = PI
	skeleton = scene.find_children("GeneralSkeleton", "Skeleton3D", true, false)[0] as Skeleton3D
	body = skeleton.find_children("Body", "MeshInstance3D", true, false)[0] as MeshInstance3D
	body.mesh = _baked_all_surfaces(body, model_path)
	anim = AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	scene.add_child(anim)
	var source := load("res://addons/quaternius_ik_rigged/UAL1_Standard.glb") as AnimationLibrary
	var lib := AnimationLibrary.new()
	for our_name: String in aliases:
		var clip_name: StringName = aliases[our_name]
		if not source.has_animation(clip_name):
			push_warning("HumanRig: missing clip %s" % clip_name)
			continue
		var clip := (source.get_animation(clip_name) as Animation).duplicate(true) as Animation
		_strip_root_motion(clip)
		clip.loop_mode = Animation.LOOP_LINEAR if our_name in loops else Animation.LOOP_NONE
		lib.add_animation(our_name, clip)
	anim.add_animation_library("", lib)


## Copies meshes (e.g. a face and hairstyle) from another VRoid model onto this rig's `bone`.
## The source meshes are baked into their rest pose, expressed relative to the source's `bone`, and
## mounted rigidly on ours (no hair physics). Returns the new MeshInstance3Ds.
func transplant_static(source_path: String, mesh_names: Array, bone := "Head") -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var src := (load(source_path) as PackedScene).instantiate()
	var src_skel := src.find_children("GeneralSkeleton", "Skeleton3D", true, false)[0] as Skeleton3D
	var src_bone_rest := src_skel.get_bone_global_rest(src_skel.find_bone(bone))
	var to_bone := src_bone_rest.affine_inverse()
	var anchor := Node3D.new()
	anchor.name = "Transplant_" + bone
	attach(bone, anchor)
	for mi_node in src.find_children("*", "MeshInstance3D", true, false):
		var mi := mi_node as MeshInstance3D
		if not (mi.name in mesh_names):
			continue
		var skin := mi.skin
		var bind_xf: Array[Transform3D] = []
		for b in skin.get_bind_count():
			var bone_name := String(skin.get_bind_name(b))
			var idx := src_skel.find_bone(bone_name) if not bone_name.is_empty() else skin.get_bind_bone(b)
			bind_xf.append(to_bone * src_skel.get_bone_global_rest(idx) * skin.get_bind_pose(b))
		var baked := ArrayMesh.new()
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var bones_arr: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var per := bones_arr.size() / maxi(verts.size(), 1)
			for v in verts.size():
				var p := Vector3.ZERO
				var n := Vector3.ZERO
				for j in per:
					var w := weights[v * per + j]
					if w > 0.0:
						var xf := bind_xf[bones_arr[v * per + j]]
						p += (xf * verts[v]) * w
						n += (xf.basis * normals[v]) * w
				verts[v] = p
				normals[v] = n.normalized()
			arrays[Mesh.ARRAY_VERTEX] = verts
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_BONES] = null
			arrays[Mesh.ARRAY_WEIGHTS] = null
			arrays[Mesh.ARRAY_TANGENT] = null
			baked.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			baked.surface_set_material(s, mi.mesh.surface_get_material(s))
		var copy := MeshInstance3D.new()
		copy.name = String(mi.name)
		copy.mesh = baked
		anchor.add_child(copy)
		out.append(copy)
	src.free()
	return out


func build(aliases: Dictionary, loops: Array = [], shape: Dictionary = SHAPE_HERO) -> void:
	_shape = shape
	var scene := (load(MODEL_SCENE) as PackedScene).instantiate()
	add_child(scene)
	# The source model faces +Z; Godot characters look down -Z. Rest-pose/mesh space keeps +Z = front.
	scene.rotation.y = PI
	skeleton =scene.get_node("Armature/GeneralSkeleton") as Skeleton3D
	for child in skeleton.get_children():
		if child is SkeletonModifier3D:
			child.queue_free()
	for child in scene.get_children():
		if child is Marker3D:
			child.queue_free()
	body = skeleton.get_node("SuperHero_Male") as MeshInstance3D
	body.mesh = _baked_mesh(body)
	anim = scene.get_node("AnimationPlayer") as AnimationPlayer
	var lib := AnimationLibrary.new()
	for our_name: String in aliases:
		var clip_name := "%s/%s" % [LIBRARY, aliases[our_name]]
		if not anim.has_animation(clip_name):
			push_warning("HumanRig: missing clip " + clip_name)
			continue
		var clip := (anim.get_animation(clip_name) as Animation).duplicate(true) as Animation
		_strip_root_motion(clip)
		clip.loop_mode = Animation.LOOP_LINEAR if our_name in loops else Animation.LOOP_NONE
		lib.add_animation(our_name, clip)
	anim.add_animation_library("", lib)


## Applies a costume shader to the body. `palette` maps Region names (lower-case strings, e.g.
## "torso") to Colors; unspecified regions keep the base skin texture. Returns the material so
## callers can set extra uniforms. A custom shader may be passed to replace the default one.
func dress(palette: Dictionary, shader: Shader = null) -> ShaderMaterial:
	costume = ShaderMaterial.new()
	costume.shader = shader if shader else _default_shader()
	var base := body.mesh.surface_get_material(0) as StandardMaterial3D
	if base and base.albedo_texture:
		costume.set_shader_parameter("skin_texture", base.albedo_texture)
	for i in Region.size():
		var key: String = Region.keys()[i].to_lower()
		var use := palette.has(key)
		costume.set_shader_parameter("region_%d_color" % i, palette.get(key, Color.WHITE))
		costume.set_shader_parameter("region_%d_on" % i, use)
	body.set_surface_override_material(0, costume)
	return costume


## Attaches `node` to a skeleton bone (e.g. "Head", "RightHand", "UpperChest").
func attach(bone: String, node: Node3D) -> BoneAttachment3D:
	var att := BoneAttachment3D.new()
	att.bone_name = bone
	skeleton.add_child(att)
	att.add_child(node)
	return att


static func _strip_root_motion(clip: Animation) -> void:
	for t in range(clip.get_track_count() - 1, -1, -1):
		var path := String(clip.track_get_path(t))
		if clip.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if path.ends_with(":Root"):
			clip.remove_track(t)
		elif path.ends_with(":Hips"):
			# Keep vertical bob, drop horizontal drift.
			for k in clip.track_get_key_count(t):
				var p: Vector3 = clip.track_get_key_value(t, k)
				var first: Vector3 = clip.track_get_key_value(t, 0)
				clip.track_set_key_value(t, k, Vector3(first.x, p.y, first.z))


func _baked_mesh(mi: MeshInstance3D) -> ArrayMesh:
	var src := mi.mesh
	var cache_key := "%d:%s" % [src.get_instance_id(), str(_shape)]
	if _mesh_cache.has(cache_key):
		return _mesh_cache[cache_key]
	var skin := mi.skin
	var bind_region: PackedInt32Array = []
	for b in skin.get_bind_count():
		var bone_name := String(skin.get_bind_name(b))
		if bone_name.is_empty():
			bone_name = skeleton.get_bone_name(skin.get_bind_bone(b))
		bind_region.append(_region_for_bone(bone_name))
	var arrays := src.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var per := bones.size() / verts.size()
	var colors := PackedColorArray()
	colors.resize(verts.size())
	for v in verts.size():
		var best := 0
		for j in range(1, per):
			if weights[v * per + j] > weights[v * per + best]:
				best = j
		var region := bind_region[bones[v * per + best]]
		var n := (verts[v] - BOUNDS_MIN) / BOUNDS_SIZE
		colors[v] = Color((region + 0.5) / 16.0, clampf(n.x, 0, 1), clampf(n.y, 0, 1), clampf(n.z, 0, 1))
	arrays[Mesh.ARRAY_COLOR] = colors
	if not _shape.is_empty():
		arrays[Mesh.ARRAY_VERTEX] = _reshape(verts, bones, weights, per, skin)
	var out := ArrayMesh.new()
	var fmt: int = src.surface_get_format(0) & ~Mesh.ARRAY_FORMAT_COLOR
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, fmt | Mesh.ARRAY_FORMAT_COLOR)
	out.surface_set_material(0, src.surface_get_material(0))
	_mesh_cache[cache_key] = out
	return out


## Squeezes each vertex toward the bones that skin it (weighted), so muscle mass shrinks while joints,
## bind poses and animations stay valid.
func _reshape(verts: PackedVector3Array, bones: PackedInt32Array, weights: PackedFloat32Array, per: int, skin: Skin) -> PackedVector3Array:
	var seg_a: Array[Vector3] = []
	var seg_b: Array[Vector3] = []
	var squeeze: Array[Vector2] = []
	for b in skin.get_bind_count():
		var bone_name := String(skin.get_bind_name(b))
		var idx := skeleton.find_bone(bone_name) if not bone_name.is_empty() else skin.get_bind_bone(b)
		bone_name = skeleton.get_bone_name(idx)
		var rest := skeleton.get_bone_global_rest(idx)
		var tip := rest.origin + rest.basis.y.normalized() * 0.1
		var kids := skeleton.get_bone_children(idx)
		if kids.size() > 0:
			tip = skeleton.get_bone_global_rest(kids[0]).origin
		seg_a.append(rest.origin)
		seg_b.append(tip)
		squeeze.append(_shape.get(bone_name, Vector2.ONE))
	var out := verts.duplicate()
	for v in verts.size():
		var p := verts[v]
		var acc := Vector3.ZERO
		var total := 0.0
		for j in per:
			var w := weights[v * per + j]
			if w <= 0.0:
				continue
			var b := bones[v * per + j]
			var a := seg_a[b]
			var ab := seg_b[b] - a
			var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
			var c := a + ab * t
			var d := p - c
			var f := squeeze[b]
			# d is perpendicular to the bone: squeeze it (x/y by the lateral factor, z = depth factor).
			# Vertical bones (spine, legs) get lateral x + depth z; sideways arm bones get y + z.
			acc += (c + Vector3(d.x * f.x, d.y * f.x, d.z * f.y)) * w
			total += w
		out[v] = acc / total if total > 0.0 else p
	return out


## Bakes COLOR masks for every surface (r = region of the dominant bone, gba = normalised rest-pose
## position). Rest positions go through the skin bind poses, so they are in the rig's +Z-forward
## rest space even when the mesh data itself is stored differently.
func _baked_all_surfaces(mi: MeshInstance3D, key: String) -> ArrayMesh:
	var cache_key := "all:" + key
	if _mesh_cache.has(cache_key):
		return _mesh_cache[cache_key]
	var src := mi.mesh
	var skin := mi.skin
	var bind_xf: Array[Transform3D] = []
	var bind_region: PackedInt32Array = []
	for b in skin.get_bind_count():
		var bone_name := String(skin.get_bind_name(b))
		var idx := skeleton.find_bone(bone_name) if not bone_name.is_empty() else skin.get_bind_bone(b)
		bind_xf.append(skeleton.get_bone_global_rest(idx) * skin.get_bind_pose(b))
		bind_region.append(_region_for_bone(skeleton.get_bone_name(idx)))
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var per := bones.size() / maxi(verts.size(), 1)
		var colors := PackedColorArray()
		colors.resize(verts.size())
		for v in verts.size():
			var best := 0
			var rest := Vector3.ZERO
			for j in per:
				var w := weights[v * per + j]
				if w > weights[v * per + best]:
					best = j
				if w > 0.0:
					rest += (bind_xf[bones[v * per + j]] * verts[v]) * w
			var n := (rest - BOUNDS_MIN) / BOUNDS_SIZE
			colors[v] = Color((bind_region[bones[v * per + best]] + 0.5) / 16.0, clampf(n.x, 0, 1), clampf(n.y, 0, 1), clampf(n.z, 0, 1))
		arrays[Mesh.ARRAY_COLOR] = colors
		var fmt: int = src.surface_get_format(s) | Mesh.ARRAY_FORMAT_COLOR
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, fmt)
		out.surface_set_material(s, src.surface_get_material(s))
		out.surface_set_name(s, src.surface_get_name(s))
	_mesh_cache[cache_key] = out
	return out


static func _region_for_bone(bone: String) -> int:
	if bone == "Head":
		return Region.HEAD
	if bone == "Neck":
		return Region.NECK
	if bone in ["Spine", "Chest", "UpperChest", "LeftShoulder", "RightShoulder"]:
		return Region.TORSO
	if bone in ["Hips", "Root"]:
		return Region.HIPS
	if bone.ends_with("UpperArm"):
		return Region.UPPER_ARM
	if bone.ends_with("LowerArm"):
		return Region.LOWER_ARM
	if bone.ends_with("UpperLeg"):
		return Region.UPPER_LEG
	if bone.ends_with("LowerLeg"):
		return Region.LOWER_LEG
	if bone.ends_with("Foot") or bone.ends_with("Toes") or bone.begins_with("ball"):
		return Region.FOOT
	return Region.HAND   # hand + every finger bone


static func _default_shader() -> Shader:
	var s := Shader.new()
	var uniforms := ""
	for i in Region.size():
		uniforms += "uniform vec4 region_%d_color : source_color = vec4(1.0);\nuniform bool region_%d_on = false;\n" % [i, i]
	var pick := ""
	for i in Region.size():
		pick += "\tif (r == %d && region_%d_on) { col = region_%d_color.rgb; cloth = 1.0; }\n" % [i, i, i]
	s.code = """shader_type spatial;
uniform sampler2D skin_texture : source_color, filter_linear_mipmap;
%s
varying vec4 mask;
void vertex() { mask = COLOR; }
void fragment() {
	int r = int(mask.r * 16.0);
	vec3 col = texture(skin_texture, UV).rgb;
	float cloth = 0.0;
%s
	ALBEDO = col;
	ROUGHNESS = mix(0.55, 0.62, cloth);
	SPECULAR = 0.4;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = col * rim * 0.12;
}
""" % [uniforms, pick]
	return s
