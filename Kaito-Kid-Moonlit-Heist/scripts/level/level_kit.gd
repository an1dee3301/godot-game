class_name LevelKit
extends RefCounted
## Shared builder API for the museum. The structure builder (museum_level.gd) creates walls, floors,
## ceilings and navigation from MuseumLayout; each room dresser (scripts/level/rooms/<theme>.gd, a
## `static func dress(kit: LevelKit, room_id: String) -> void`) furnishes one room through this API.
##
## Rules for dressers: stay inside your room rect (MuseumLayout.ROOMS[id].rect, minus 0.4 m walls);
## keep >= 1.6 m clear in front of every opening into your room (MuseumLayout.OPENINGS) and keep the
## straight segments of guard routes (MuseumLayout.GUARD_ROUTES) walkable (>= 1.2 m wide); don't block
## jewels/cameras/pickups/fuse/laser positions (MuseumLayout.JEWELS etc). Anything a player could walk
## into needs a collider (`solid`/`cylinder_solid`, or `prop(..., collider)`), which is baked into the
## navmesh. Decor above 2.2 m or flat on walls needs no collider.

var root: Node3D                 ## Parent for everything (inside the NavigationRegion3D).
var minimap: Array = []          ## Rect2 footprints for the HUD minimap.
var _rooms: Dictionary = {}
var _mats: Dictionary = {}


func _init(parent: Node3D) -> void:
	root = parent


## Node that holds one room's content (created on demand).
func room_node(room_id: String) -> Node3D:
	if not _rooms.has(room_id):
		var n := Node3D.new()
		n.name = "Room_" + room_id
		root.add_child(n)
		_rooms[room_id] = n
	return _rooms[room_id]


## Room rect in world XZ (x0, z0, w, d).
static func rect(room_id: String) -> Rect2:
	return MuseumLayout.ROOMS[room_id]["rect"]


## Solid box (collider on LAYER_WORLD + mesh). pos = centre of the box's base (y = bottom).
func solid(room_id: String, pos: Vector3, size: Vector3, material: Material, yaw := 0.0, on_minimap := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = KK.LAYER_WORLD
	body.collision_mask = 0
	body.position = pos + Vector3(0, size.y * 0.5, 0)
	body.rotation.y = yaw
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = material
	body.add_child(mi)
	room_node(room_id).add_child(body)
	if on_minimap and size.y > 0.9:
		var half := Vector2(size.x, size.z) * 0.5
		if absf(yaw) > 0.01:
			var r := maxf(half.x, half.y)
			half = Vector2(r, r)
		minimap.append(Rect2(Vector2(pos.x, pos.z) - half, half * 2.0))
	return body


## Solid vertical cylinder (columns, plinths). pos = centre of the base.
func cylinder_solid(room_id: String, pos: Vector3, radius: float, height: float, material: Material, segments := 24) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = KK.LAYER_WORLD
	body.collision_mask = 0
	body.position = pos + Vector3(0, height * 0.5, 0)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	mi.mesh = mesh
	mi.material_override = material
	body.add_child(mi)
	room_node(room_id).add_child(body)
	if height > 0.9:
		minimap.append(Rect2(Vector2(pos.x - radius, pos.z - radius), Vector2(radius * 2.0, radius * 2.0)))
	return body


## Visual mesh. If `collider` is non-zero, a box collider of that size is added (centred on the
## transform origin + collider.y/2, i.e. origin at its base).
func prop(room_id: String, mesh: Mesh, xform: Transform3D, material: Material = null, collider := Vector3.ZERO) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if material:
		mi.material_override = material
	if collider == Vector3.ZERO:
		mi.transform = xform
		room_node(room_id).add_child(mi)
		return mi
	var body := StaticBody3D.new()
	body.collision_layer = KK.LAYER_WORLD
	body.collision_mask = 0
	body.transform = xform
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = collider
	shape.shape = box
	shape.position.y = collider.y * 0.5
	body.add_child(shape)
	body.add_child(mi)
	room_node(room_id).add_child(body)
	if collider.y > 0.9:
		var r := maxf(collider.x, collider.z) * 0.5
		minimap.append(Rect2(Vector2(xform.origin.x - r, xform.origin.z - r), Vector2(r * 2.0, r * 2.0)))
	return body


## Many copies of one mesh (no colliders): use for repeated decor (mouldings, books, bricks...).
func multi(room_id: String, mesh: Mesh, transforms: Array, material: Material = null) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	if material:
		mmi.material_override = material
	room_node(room_id).add_child(mmi)
	return mmi


func omni(room_id: String, pos: Vector3, color: Color, energy: float, light_range: float, shadows := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = light_range
	l.shadow_enabled = shadows
	l.light_volumetric_fog_energy = 0.6
	room_node(room_id).add_child(l)
	return l


## Spotlight at `pos` aimed at `target`.
func spot(room_id: String, pos: Vector3, target: Vector3, color: Color, energy: float, light_range: float, angle_deg: float, shadows := false) -> SpotLight3D:
	var l := SpotLight3D.new()
	room_node(room_id).add_child(l)
	l.position = pos
	if not pos.is_equal_approx(target):
		var up := Vector3.UP if absf((target - pos).normalized().y) < 0.98 else Vector3.FORWARD
		l.look_at_from_position(pos, target, up)
	l.light_color = color
	l.light_energy = energy
	l.spot_range = light_range
	l.spot_angle = angle_deg
	l.shadow_enabled = shadows
	l.light_volumetric_fog_energy = 1.0
	return l


func label(room_id: String, text: String, pos: Vector3, yaw: float, font_size := 48, color := Color(0.9, 0.78, 0.45)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.rotation.y = yaw
	l.font_size = font_size
	l.pixel_size = 0.004
	l.modulate = color
	l.outline_size = 0
	l.shaded = true
	room_node(room_id).add_child(l)
	return l


## A CC0 Poly Haven model (see specs/asset_catalog.md for ids & native sizes). `height` > 0 rescales it
## uniformly to that height (several assets are authored in cm); the model is grounded so its lowest
## point sits at xform.origin.y. collider: "auto" = box around the scaled bounds when taller than 0.5 m,
## "box" = always, "none" = never (wall decor, hanging lights). Returns the model root.
func model(room_id: String, asset_id: String, xform: Transform3D, height := 0.0, collider := "auto") -> Node3D:
	var path := "res://assets/polyhaven/models/%s/%s.gltf" % [asset_id, asset_id]
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("LevelKit.model: missing " + asset_id)
		return null
	var inst := packed.instantiate() as Node3D
	var aabb := _model_aabb(asset_id, inst)
	var s := 1.0 if height <= 0.0 or aabb.size.y <= 0.0 else height / aabb.size.y
	inst.scale = Vector3.ONE * s
	inst.position = Vector3(-aabb.get_center().x * s, -aabb.position.y * s, -aabb.get_center().z * s)
	var holder := Node3D.new()
	holder.name = asset_id
	holder.transform = xform
	holder.add_child(inst)
	var size := aabb.size * s
	if collider == "box" or (collider == "auto" and size.y > 0.5):
		var body := StaticBody3D.new()
		body.collision_layer = KK.LAYER_WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		shape.position.y = size.y * 0.5
		body.add_child(shape)
		holder.add_child(body)
		if size.y > 0.9:
			var r := maxf(size.x, size.z) * 0.5
			minimap.append(Rect2(Vector2(xform.origin.x - r, xform.origin.z - r), Vector2(r * 2.0, r * 2.0)))
	room_node(room_id).add_child(holder)
	return holder


static var _aabb_cache: Dictionary = {}
static func _model_aabb(asset_id: String, inst: Node3D) -> AABB:
	if _aabb_cache.has(asset_id):
		return _aabb_cache[asset_id]
	var aabb := AABB()
	var first := true
	for mi_node in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := mi_node as MeshInstance3D
		var xf := Transform3D.IDENTITY
		var n: Node = mi
		while n != inst and n != null:
			if n is Node3D:
				xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var a := xf * mi.get_aabb()
		aabb = a if first else aabb.merge(a)
		first = false
	_aabb_cache[asset_id] = aabb
	return aabb


## PBR material from a Poly Haven texture set, world-triplanar so boxes/walls tile correctly.
## `tile` = metres per texture repeat. `tint` multiplies the albedo.
func pbr(texture_id: String, tile := 2.0, tint := Color.WHITE, roughness_scale := 1.0) -> StandardMaterial3D:
	var key := "pbr:%s:%.2f:%s:%.2f" % [texture_id, tile, tint.to_html(), roughness_scale]
	if _mats.has(key):
		return _mats[key]
	var dir := "res://assets/polyhaven/textures/%s/" % texture_id
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(dir + "diff.jpg")
	m.albedo_color = tint
	if ResourceLoader.exists(dir + "nor.jpg"):
		m.normal_enabled = true
		m.normal_texture = load(dir + "nor.jpg")
	if ResourceLoader.exists(dir + "rough.jpg"):
		m.roughness_texture = load(dir + "rough.jpg")
		m.roughness = roughness_scale
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / tile
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = m
	return m


## Shared material library so every room shares one art direction. Names:
## marble_white, marble_black, marble_floor, stone, plaster, wallpaper_red, wallpaper_teal, wallpaper_navy,
## wood_dark, wood_light, gold, brass, bronze, iron, velvet_red, velvet_blue, velvet_green, glass, sandstone,
## lapis, papyrus, carpet_red, carpet_blue, canvas, ivory, emissive_warm, emissive_cool.
func mat(material_name: String) -> Material:
	if _mats.has(material_name):
		return _mats[material_name]
	var textured := {
		"marble_floor": ["marble_01", 3.2, Color(0.82, 0.8, 0.76), 0.3],
		"ceiling": ["painted_plaster_wall", 3.0, Color(0.3, 0.26, 0.23), 1.0],
		"marble_white": ["marble_01", 1.5, Color(1, 0.98, 0.95), 0.6],
		"marble_black": ["marble_01", 3.0, Color(0.16, 0.16, 0.18), 0.3],
		"stone": ["monastery_stone_floor", 2.5, Color(0.85, 0.82, 0.78), 1.0],
		"plaster": ["painted_plaster_wall", 2.0, Color(0.9, 0.87, 0.82), 1.0],
		"plaster_grey": ["plaster_grey_04", 2.0, Color.WHITE, 1.0],
		"concrete": ["concrete_floor", 2.5, Color.WHITE, 1.0],
		"parquet": ["herringbone_parquet", 1.6, Color(0.85, 0.75, 0.65), 0.8],
		"sandstone": ["large_sandstone_blocks", 2.5, Color.WHITE, 1.0],
		"wood_dark": ["dark_wooden_planks", 1.2, Color(0.75, 0.6, 0.5), 0.7],
		"wood_light": ["wood_table_001", 1.2, Color.WHITE, 0.8],
		"velvet_red": ["velour_velvet", 0.6, Color(0.75, 0.08, 0.12), 1.0],
		"velvet_blue": ["velour_velvet", 0.6, Color(0.12, 0.22, 0.7), 1.0],
		"velvet_green": ["velour_velvet", 0.6, Color(0.08, 0.45, 0.25), 1.0],
		"wallpaper_red": ["quatrefoil_jacquard_fabric", 0.9, Color(0.75, 0.16, 0.18), 1.0],
		"wallpaper_teal": ["quatrefoil_jacquard_fabric", 0.9, Color(0.18, 0.5, 0.52), 1.0],
		"wallpaper_navy": ["quatrefoil_jacquard_fabric", 0.9, Color(0.2, 0.26, 0.55), 1.0],
		"carpet_red": ["velour_velvet", 1.0, Color(0.55, 0.06, 0.08), 1.0],
		"carpet_blue": ["velour_velvet", 1.0, Color(0.1, 0.16, 0.45), 1.0],
	}
	if textured.has(material_name):
		var t: Array = textured[material_name]
		var pm := pbr(t[0], t[1], t[2], t[3])
		_mats[material_name] = pm
		return pm
	var m := StandardMaterial3D.new()
	var c := Color(0.8, 0.8, 0.8)
	var rough := 0.6
	var metal := 0.0
	match material_name:
		"marble_white": c = Color(0.9, 0.88, 0.84); rough = 0.18
		"marble_black": c = Color(0.08, 0.08, 0.09); rough = 0.15
		"marble_floor": c = Color(0.82, 0.8, 0.76); rough = 0.12
		"stone": c = Color(0.62, 0.6, 0.56); rough = 0.8
		"plaster": c = Color(0.86, 0.84, 0.8); rough = 0.85
		"wallpaper_red": c = Color(0.36, 0.06, 0.08); rough = 0.8
		"wallpaper_teal": c = Color(0.07, 0.24, 0.26); rough = 0.8
		"wallpaper_navy": c = Color(0.07, 0.1, 0.22); rough = 0.8
		"wood_dark": c = Color(0.2, 0.11, 0.06); rough = 0.45
		"wood_light": c = Color(0.55, 0.38, 0.22); rough = 0.5
		"gold": c = Color(0.95, 0.76, 0.35); rough = 0.25; metal = 1.0
		"brass": c = Color(0.8, 0.62, 0.3); rough = 0.3; metal = 1.0
		"bronze": c = Color(0.45, 0.3, 0.18); rough = 0.4; metal = 0.9
		"iron": c = Color(0.12, 0.12, 0.13); rough = 0.5; metal = 0.8
		"velvet_red": c = Color(0.45, 0.03, 0.07); rough = 0.95
		"velvet_blue": c = Color(0.05, 0.1, 0.35); rough = 0.95
		"velvet_green": c = Color(0.03, 0.22, 0.12); rough = 0.95
		"sandstone": c = Color(0.78, 0.64, 0.42); rough = 0.85
		"lapis": c = Color(0.1, 0.2, 0.6); rough = 0.3
		"papyrus": c = Color(0.85, 0.76, 0.55); rough = 0.9
		"carpet_red": c = Color(0.38, 0.05, 0.06); rough = 1.0
		"carpet_blue": c = Color(0.06, 0.1, 0.28); rough = 1.0
		"canvas": c = Color(0.7, 0.66, 0.58); rough = 0.9
		"ivory": c = Color(0.94, 0.91, 0.84); rough = 0.4
		"glass":
			c = Color(0.8, 0.9, 1.0, 0.12)
			rough = 0.02
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		"emissive_warm":
			c = Color(1.0, 0.85, 0.6)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.8, 0.5)
			m.emission_energy_multiplier = 3.0
		"emissive_cool":
			c = Color(0.7, 0.85, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.6, 0.8, 1.0)
			m.emission_energy_multiplier = 2.5
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	_mats[material_name] = m
	return m


## Replace a library material (the structure builder may upgrade materials to shaders).
func set_mat(material_name: String, material: Material) -> void:
	_mats[material_name] = material
