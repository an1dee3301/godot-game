class_name MuseumLevel
extends Node3D
## Procedural, single-floor Moonlight Museum. All dimensions are metres in XZ.

signal laser_tripped(position: Vector3)
signal lasers_disabled
signal camera_spotted(position: Vector3)
signal pickup_collected(kind: String, position: Vector3)

const FLOOR_Y := -0.16
const CEILING_Y := 6.6
const WALL_H := 6.6
const WALL_T := 0.34
const MARBLE_CODE := """
shader_type spatial;
uniform vec4 stone_color : source_color = vec4(0.7, 0.72, 0.72, 1.0);
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = world_pos.xz * 0.52 + world_pos.y * vec2(0.22, 0.15);
	float warp = sin(p.x * 2.7 + sin(p.y * 3.6)) * 0.23 + sin(p.y * 5.1) * 0.09;
	float thread = abs(sin((p.x * 1.25 + p.y * 1.8 + warp) * 8.0));
	float vein = smoothstep(0.94, 0.995, thread);
	float fine = smoothstep(0.97, 0.999, abs(sin((p.x * 3.8 - p.y * 2.2 + warp) * 9.0)));
	ALBEDO = stone_color.rgb * (0.92 + 0.07 * sin(p.x * 1.8 + p.y * 2.1)) - vec3(0.12, 0.15, 0.18) * vein * 0.38 - vec3(0.08, 0.1, 0.12) * fine * 0.12;
	METALLIC = 0.07;
	ROUGHNESS = 0.21;
	SPECULAR = 0.62;
}
"""
const WALLPAPER_CODE := """
shader_type spatial;
uniform vec4 fabric_color : source_color = vec4(0.21, 0.31, 0.34, 1.0);
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = vec2(world_pos.x + world_pos.z, world_pos.y) * vec2(1.35, 1.7);
	vec2 cell = fract(p) - 0.5;
	float diamond = abs(cell.x) + abs(cell.y);
	float motif = 1.0 - smoothstep(0.31, 0.35, diamond);
	float pinstripe = 1.0 - smoothstep(0.015, 0.035, abs(cell.x));
	float weave = sin(p.x * 35.0) * sin(p.y * 31.0) * 0.025;
	ALBEDO = fabric_color.rgb * (0.91 + weave + motif * 0.12 + pinstripe * 0.025);
	METALLIC = 0.08;
	ROUGHNESS = 0.78;
}
"""

var navigation_region: NavigationRegion3D
var _atmosphere: MuseumAtmosphere
var _exit: ExitGlider
var _jewels: Array = []
var _walls: Array = []
var _windows: Array = []
var _geo: Node3D
var _stone: Material
var _wallpaper: Material
var _wood: StandardMaterial3D
var _gold: StandardMaterial3D
var _bronze: StandardMaterial3D
var _velvet: StandardMaterial3D
var _dark: StandardMaterial3D
var _ivory: StandardMaterial3D
var _glass: StandardMaterial3D
var _floor_dark: Material
var _floor_light: Material
var _paintings: Dictionary = {}


## Build the museum, objects, atmosphere, and synchronous navigation mesh.
func build() -> void:
	_stone = _marble(Color(0.75, 0.75, 0.73))
	_wallpaper = _patterned_wallpaper()
	_wood = _mat(Color(0.105, 0.052, 0.038), 0.44)
	_gold = _mat(Color(0.68, 0.46, 0.15), 0.23, 0.78)
	_bronze = _mat(Color(0.32, 0.22, 0.12), 0.33, 0.65)
	_velvet = _mat(Color(0.37, 0.032, 0.072), 0.9)
	_dark = _mat(Color(0.035, 0.045, 0.075), 0.65)
	_ivory = _mat(Color(0.90, 0.84, 0.69), 0.32)
	_glass = _mat(Color(0.37, 0.63, 0.72, 0.24), 0.08)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.refraction_enabled = true
	_floor_dark = _marble(Color(0.19, 0.27, 0.34))
	_floor_light = _marble(Color(0.83, 0.80, 0.71))

	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "NavigationRegion"
	add_child(navigation_region)
	_geo = Node3D.new()
	_geo.name = "ArchitectureAndProps"
	navigation_region.add_child(_geo)
	_build_architecture()
	_build_decor()
	_build_objects()
	_build_lighting()

	_atmosphere = MuseumAtmosphere.new()
	_atmosphere.name = "Atmosphere"
	add_child(_atmosphere)
	var alarms := PackedVector3Array([
		Vector3(-9, 6.15, 13), Vector3(9, 6.15, 13),
		Vector3(-10, 6.15, -7), Vector3(10, 6.15, -7),
		Vector3(-30, 6.15, 8), Vector3(30, 6.15, 8),
		Vector3(-24, 6.15, -24), Vector3(27, 6.15, -24)])
	_atmosphere.setup(AABB(Vector3(-35, 0, -35), Vector3(70, 6.8, 63)), _windows, alarms)

	var nav := NavigationMesh.new()
	nav.agent_radius = 0.45
	nav.agent_height = 1.8
	nav.cell_size = 0.15
	nav.cell_height = 0.1
	nav.agent_max_climb = 0.3
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = KK.LAYER_WORLD | KK.LAYER_GLASS
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map, 0.15)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map, 0.1)
	navigation_region.navigation_mesh = nav
	navigation_region.bake_navigation_mesh(false)


func _build_architecture() -> void:
	# A continuous slab keeps every doorway and the exterior balcony connected for navigation.
	_solid("Museum floor", Vector3(0, FLOOR_Y, 0), Vector3(70, 0.32, 56), _stone, false)
	_solid("Balcony floor", Vector3(0, FLOOR_Y, -31.5), Vector3(18, 0.32, 7), _stone, false)
	_make_marble_tiles()
	_floor_inlays()
	# Outside perimeter, with honest window holes and thin collision glass in the gaps.
	_wall_z(-28, -35, -2.1)
	_wall_z(-28, 2.1, 35)
	_wall_z(28, -35, 35)
	_outer_x(-35, -28, 28, [-20.0, 1.0, 17.0], -1)
	_outer_x(35, -28, 28, [-20.0, 1.0, 17.0], 1)
	# East and west rooms connect to the atrium through broad portals.
	_wall_x(-13, -10, -2.5)
	_wall_x(-13, 2.5, 17)
	_wall_x(13, -13, -2.5)
	_wall_x(13, 2.5, 17)
	# Lobby is quiet and opens into the atrium through a six-metre arch.
	_wall_z(17, -35, -3)
	_wall_z(17, 3, 35)
	# Atrium to Egyptian hall; clock hall to Egyptian hall.
	_wall_z(-10, -13, -3)
	_wall_z(-10, 3, 13)
	_wall_x(-12, -28, -22)
	_wall_x(-12, -18, -10)
	# Clock and east gallery north boundaries.
	_wall_z(-10, -35, -13)
	_wall_z(-13, 16, 35)
	# Maintenance passage at x=12..17; the vault door turns east from that passage.
	_wall_x(12, -28, -10)
	_wall_x(17, -28, -22.1)
	_wall_x(17, -18.5, -13)
	_portal(Vector3(0, 0, 17), 6.0, false)
	_portal(Vector3(0, 0, -10), 6.0, false)
	_portal(Vector3(-13, 0, 0), 5.0, true)
	_portal(Vector3(13, 0, 0), 5.0, true)
	# A dogleg hides the fuse box from anyone looking in through the laser doorway.
	_wall_z(-23.3, 12, 14.25)
	# Balcony has an actual open doorway and waist-height balustrade.
	_solid("Balcony rail north", Vector3(0, 0.72, -34.85), Vector3(18, 1.4, 0.3), _stone)
	_solid("Balcony rail west", Vector3(-8.85, 0.72, -31.5), Vector3(0.3, 1.4, 6.7), _stone)
	_solid("Balcony rail east", Vector3(8.85, 0.72, -31.5), Vector3(0.3, 1.4, 6.7), _stone)
	for x in [-8.5, -5.5, -2.5, 2.5, 5.5, 8.5]:
		_mesh_box(Vector3(float(x), 1.45, -34.8), Vector3(0.34, 0.25, 0.34), _gold)
	# Room ceilings. The atrium aperture is reserved for glass and moonbeams.
	_ceiling(-35, -13, -28, 17)
	_ceiling(13, 35, -28, 17)
	_ceiling(-13, 13, 17, 28)
	_ceiling(-13, 13, -28, -10)
	_ceiling(-13, 13, 6, 17)
	_ceiling(-13, 13, -10, -5)
	_ceiling(-13, -6, -5, 6)
	_ceiling(6, 13, -5, 6)
	# A small glasshouse frame defines the skylight without blocking the opening.
	for x in [-6.1, 6.1]:
		_mesh_box(Vector3(float(x), CEILING_Y, 0.5), Vector3(0.24, 0.24, 11.4), _gold)
	for z in [-5.1, 6.1]:
		_mesh_box(Vector3(0, CEILING_Y, float(z)), Vector3(12.3, 0.24, 0.24), _gold)
	var sky_basis := Basis(Vector3.RIGHT, Vector3(0, 0, -1), Vector3.UP)
	_windows.append({"transform": Transform3D(sky_basis, Vector3(0, CEILING_Y, 0.5)), "size": Vector2(12, 11)})


func _ceiling(x0: float, x1: float, z0: float, z1: float) -> void:
	_mesh_box(Vector3((x0+x1)*0.5, CEILING_Y+0.15, (z0+z1)*0.5), Vector3(x1-x0, 0.3, z1-z0), _ivory)
	# Coffered bands stop short of the important glass opening.
	for x in range(int(ceil((x1-x0)/4.0))):
		var px := x0 + 2.0 + float(x)*4.0
		if px < x1:
			_mesh_box(Vector3(px, CEILING_Y-0.11, (z0+z1)*0.5), Vector3(0.16, 0.18, z1-z0), _stone)
	for z in range(int(ceil((z1-z0)/4.0))):
		var pz := z0 + 2.0 + float(z)*4.0
		if pz < z1:
			_mesh_box(Vector3((x0+x1)*0.5, CEILING_Y-0.11, pz), Vector3(x1-x0, 0.18, 0.16), _stone)


func _wall_x(x: float, z0: float, z1: float) -> void:
	if z1 <= z0:
		return
	_wall_piece(Vector3(x, WALL_H*0.5, (z0+z1)*0.5), Vector3(WALL_T, WALL_H, z1-z0))


func _wall_z(z: float, x0: float, x1: float) -> void:
	if x1 <= x0:
		return
	_wall_piece(Vector3((x0+x1)*0.5, WALL_H*0.5, z), Vector3(x1-x0, WALL_H, WALL_T))


func _wall_piece(pos: Vector3, size: Vector3) -> void:
	_solid("Wall", pos, size, _wallpaper, false)
	var horizontal := size.x > size.z
	var bottom := size
	bottom.y = 1.45
	_mesh_box(Vector3(pos.x, 0.725, pos.z), bottom + (Vector3(0, 0, 0.045) if horizontal else Vector3(0.045, 0, 0)), _wood)
	var trim_size := Vector3(size.x, 0.09, size.z+0.08) if horizontal else Vector3(size.x+0.08, 0.09, size.z)
	for height in [0.13, 1.45, 6.17, 6.52]:
		_mesh_box(Vector3(pos.x, float(height), pos.z), trim_size, _gold)
	# Raised panel moulding gives the lower wall a legible architectural rhythm.
	var length := size.x if horizontal else size.z
	var count := int(floor(length / 2.4))
	for i in count:
		var offset := -length * 0.5 + (float(i) + 0.5) * length / float(count)
		var p := Vector3(pos.x + offset, 0.75, pos.z) if horizontal else Vector3(pos.x, 0.75, pos.z + offset)
		var panel_length := length / float(count) - 0.32
		var edge := size.z * 0.5 + 0.035 if horizontal else size.x * 0.5 + 0.035
		for side in [-1.0, 1.0]:
			var q := p + (Vector3(0, 0, side * edge) if horizontal else Vector3(side * edge, 0, 0))
			var hbar := Vector3(panel_length, 0.035, 0.035) if horizontal else Vector3(0.035, 0.035, panel_length)
			var vbar := Vector3(0.035, 0.88, 0.035)
			_mesh_box(q + Vector3(0, 0.44, 0), hbar, _bronze)
			_mesh_box(q - Vector3(0, 0.44, 0), hbar, _bronze)
			_mesh_box(q + (Vector3(panel_length * 0.5, 0, 0) if horizontal else Vector3(0, 0, panel_length * 0.5)), vbar, _bronze)
			_mesh_box(q - (Vector3(panel_length * 0.5, 0, 0) if horizontal else Vector3(0, 0, panel_length * 0.5)), vbar, _bronze)
	_walls.append(Rect2(Vector2(pos.x-size.x*0.5, pos.z-size.z*0.5), Vector2(size.x, size.z)))


func _outer_x(x: float, z0: float, z1: float, centres: Array, direction: int) -> void:
	var cursor := z0
	for raw_centre in centres:
		var centre := float(raw_centre)
		_wall_x(x, cursor, centre-1.35)
		_wall_piece(Vector3(x, 6.05, centre), Vector3(WALL_T, 1.1, 2.7))
		_wall_piece(Vector3(x, 0.5, centre), Vector3(WALL_T, 1.0, 2.7))
		# Glass collision keeps the silhouettes and projectiles within the museum.
		_solid("Window collision", Vector3(x, 3.25, centre), Vector3(0.12, 4.0, 2.7), null, false, KK.LAYER_GLASS)
		var basis := Basis(Vector3(0, 0, -direction), Vector3.UP, Vector3(direction, 0, 0))
		_windows.append({"transform": Transform3D(basis, Vector3(x, 3.25, centre)), "size": Vector2(2.7, 4.0)})
		cursor = centre+1.35
	_wall_x(x, cursor, z1)


func _make_marble_tiles() -> void:
	# Broad ivory slabs with hairline joints, rather than a high contrast checkerboard.
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(1.985, 0.012, 1.985)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = tile_mesh
	multimesh.instance_count = 35 * 28
	for ix in range(35):
		for iz in range(28):
			multimesh.set_instance_transform(ix * 28 + iz, Transform3D(Basis.IDENTITY, Vector3(-34 + ix * 2, 0.004, -27 + iz * 2)))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = _floor_light
	_geo.add_child(instance)


func _floor_inlays() -> void:
	# Double dark borders organize the wings; the centre remains open for combat and navigation.
	for rect: Vector4 in [
		Vector4(-12.3, 12.3, -9.3, 16.3), Vector4(-34.0, -14.0, -26.9, 15.8),
		Vector4(14.0, 34.0, -26.9, 15.8), Vector4(-11.8, 11.8, 18.1, 27.0)]:
		for inset: float in [0.0, 0.28]:
			var x0 := rect.x + inset
			var x1 := rect.y - inset
			var z0 := rect.z + inset
			var z1 := rect.w - inset
			_mesh_box(Vector3((x0+x1)*0.5, 0.019, z0), Vector3(x1-x0, 0.009, 0.055), _floor_dark)
			_mesh_box(Vector3((x0+x1)*0.5, 0.019, z1), Vector3(x1-x0, 0.009, 0.055), _floor_dark)
			_mesh_box(Vector3(x0, 0.019, (z0+z1)*0.5), Vector3(0.055, 0.009, z1-z0), _floor_dark)
			_mesh_box(Vector3(x1, 0.019, (z0+z1)*0.5), Vector3(0.055, 0.009, z1-z0), _floor_dark)
	# Eight-point marble compass rose around the fountain, readable from the balcony view.
	for i in 8:
		var angle := float(i) * TAU / 8.0
		var cx := sin(angle) * 4.1
		var cz := 1.0 + cos(angle) * 4.1
		var petal := _mesh_box(Vector3(cx, 0.025, cz), Vector3(0.48, 0.012, 1.55), _floor_dark)
		petal.rotation.y = angle
	for z in [-23.0, 0.0, 8.0]:
		_runner(Vector3(-24, 0, z), Vector2(3.2, 6.8))
		_runner(Vector3(24, 0, z), Vector2(3.2, 6.8))
	_runner(Vector3(0, 0, 22), Vector2(2.8, 6.0))


func _runner(pos: Vector3, size: Vector2) -> void:
	_mesh_box(pos + Vector3(0, 0.022, 0), Vector3(size.x, 0.015, size.y), _velvet)
	for side in [-1.0, 1.0]:
		_mesh_box(pos + Vector3(side * (size.x * 0.5 - 0.18), 0.034, 0), Vector3(0.045, 0.009, size.y - 0.24), _gold)
		_mesh_box(pos + Vector3(0, 0.034, side * (size.y * 0.5 - 0.18)), Vector3(size.x - 0.24, 0.009, 0.045), _gold)


func _portal(pos: Vector3, width: float, across_x: bool) -> void:
	# A shallow voussoir arcade crowns the existing open passage without changing its collision.
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = PI * 0.5 if across_x else 0.0
	_geo.add_child(root)
	for side in [-1.0, 1.0]:
		var jamb := _box_mesh(Vector3(0.34, 4.9, 0.52), _stone)
		jamb.position = Vector3(side * (width * 0.5 + 0.21), 2.45, 0)
		root.add_child(jamb)
		var impost := _box_mesh(Vector3(0.72, 0.19, 0.66), _gold)
		impost.position = Vector3(side * (width * 0.5 + 0.21), 4.85, 0)
		root.add_child(impost)
	for i in 13:
		var angle := PI - float(i) * PI / 12.0
		var arch := _box_mesh(Vector3(0.55, 0.47, 0.55), _stone if i != 6 else _gold)
		arch.position = Vector3(cos(angle) * width * 0.5, 4.72 + sin(angle) * 1.42, 0)
		arch.rotation.z = angle - PI * 0.5
		root.add_child(arch)


func _build_decor() -> void:
	# Four thick atrium pillars and a circular fountain create readable cover.
	for x in [-9.0, 9.0]:
		for z in [-6.0, 11.0]:
			_solid("Atrium pillar", Vector3(x, 3.25, z), Vector3(1.6, 6.5, 1.6), null)
			_classical_column(Vector3(x, 0, z), 0.82)
	_solid("Fountain basin", Vector3(0, 0.65, 1), Vector3(5.2, 1.3, 5.2), _stone)
	_mesh_box(Vector3(0, 1.28, 1), Vector3(5.1, 0.12, 5.1), _gold)
	_mesh_box(Vector3(0, 1.34, 1), Vector3(4.65, 0.04, 4.65), _glass)
	_mesh_cylinder(Vector3(0, 2.0, 1), 0.58, 1.4, _ivory)
	_mesh_sphere(Vector3(0, 2.88, 1), 0.55, _gold)
	# Reception, broad enough to read as a destination but away from the spawn.
	_solid("Reception desk", Vector3(7.0, 0.58, 23.6), Vector3(5.0, 1.16, 1.25), _wood)
	_mesh_box(Vector3(7.0, 1.2, 23.6), Vector3(5.3, 0.12, 1.5), _gold)
	_label("MOONLIGHT MUSEUM", Vector3(0, 3.8, 27.73), 0.48, Color(0.95, 0.78, 0.40), 0)
	# Lobby columns and palms.
	for x in [-9.3, 9.3]:
		_solid("Lobby pillar", Vector3(x, 3.2, 19.2), Vector3(1.0, 6.4, 1.0), null)
		_classical_column(Vector3(x, 0, 19.2), 0.54)
	# An upper gallery and stair profile frame the long view toward the collection.
	for side in [-1.0, 1.0]:
		_mesh_box(Vector3(side * 11.5, 4.78, 4.2), Vector3(2.6, 0.24, 22.0), _stone)
		_mesh_box(Vector3(side * 10.25, 5.4, 4.2), Vector3(0.13, 1.1, 22.0), _bronze)
		for z in range(-5, 15, 2):
			_mesh_box(Vector3(side * 10.25, 5.36, float(z)), Vector3(0.14, 1.0, 0.14), _gold)
		for step in 9:
			var rise := float(step) * 0.34
			_mesh_box(Vector3(side * 11.25, rise * 0.5, 12.8 - float(step) * 0.58), Vector3(2.3, rise + 0.12, 0.58), _stone)
	for p in [Vector3(-10,0,25), Vector3(11,0,26), Vector3(-31,0,9), Vector3(31,0,9)]:
		_palm(p)
	# Gallery furniture. Painting lights sit above every gilded frame.
	for z in [-7.0, -1.0, 6.0]:
		_painting(Vector3(34.75, 3.25, z), -PI*0.5, int(z+10))
		_painting(Vector3(-34.75, 3.25, z), PI*0.5, int(z+16))
	for x in [20.0, 29.0]:
		_bench(Vector3(x, 0, -5.0))
	_bench(Vector3(-25, 0, -5.5))
	_statue(Vector3(-30, 0, -4), 0)
	_statue(Vector3(-18, 0, -5), 1)
	_armour(Vector3(-18, 0, 11))
	_armour(Vector3(18, 0, 11))
	for x in [-5.0, 5.0]:
		_vase(Vector3(x, 0, 13.5))
	for z in [19.5, 22.0, 24.5]:
		_stanchion(Vector3(-11.5, 0, z))
		_stanchion(Vector3(-8.5, 0, z))
	# Egyptian hall: angular stone, obelisks, and a pair of sarcophagi.
	for x in [-8.0, 8.0]:
		_solid("Obelisk", Vector3(x, 1.6, -21.5), Vector3(1.25, 3.2, 1.25), _stone)
		_mesh_box(Vector3(x, 3.26, -21.5), Vector3(1.45, 0.12, 1.45), _gold)
	for x in [-5.0, 5.0]:
		_solid("Sarcophagus", Vector3(x, 0.55, -13.4), Vector3(1.45, 1.1, 3.0), _bronze)
		_mesh_box(Vector3(x, 1.13, -13.4), Vector3(1.25, 0.10, 2.8), _gold)
		_mesh_sphere(Vector3(x, 1.38, -14.25), 0.34, _ivory)
		for stripe in 4:
			_mesh_box(Vector3(x, 1.19, -13.7 + float(stripe) * 0.45), Vector3(1.3, 0.025, 0.07), _dark)
	# Clock gallery, giant dial and twelve jewel-like hour marks.
	_mesh_cylinder(Vector3(-25, 3.65, -27.70), 3.05, 0.18, _gold, Vector3(PI*0.5, 0, 0))
	_mesh_cylinder(Vector3(-25, 3.65, -27.56), 2.75, 0.20, _ivory, Vector3(PI*0.5, 0, 0))
	for i in 12:
		var angle := float(i) * TAU / 12.0
		_mesh_sphere(Vector3(-25 + sin(angle)*2.28, 3.65 + cos(angle)*2.28, -27.42), 0.095, _bronze)
	_mesh_box(Vector3(-24.55, 4.15, -27.34), Vector3(0.09, 1.5, 0.08), _dark)
	_mesh_box(Vector3(-25.48, 3.55, -27.33), Vector3(1.1, 0.09, 0.08), _dark)
	# Rich signage makes the multiple wings legible from the atrium.
	_label("EAST GALLERY", Vector3(13.16, 3.8, 7.7), 0.27, Color(1,0.81,0.47), PI*0.5)
	_label("WEST GALLERY", Vector3(-13.16, 3.8, 7.7), 0.27, Color(1,0.81,0.47), -PI*0.5)
	_label("EGYPTIAN HALL", Vector3(0, 3.8, -10.2), 0.30, Color(1,0.81,0.47), 0)
	_label("TREASURY", Vector3(17.20, 4.1, -20.3), 0.26, Color(1,0.81,0.47), PI*0.5)
	_label("EXIT", Vector3(0, 4.0, -27.76), 0.32, Color(0.30,1.0,0.51), 0, true)
	# Skyline is visual only and deliberately below the moon line.
	var city_rng := RandomNumberGenerator.new()
	city_rng.seed = 1717
	for i in 42:
		var bx := -80.0 + float(i)*3.8
		var height := city_rng.randf_range(4.0, 15.0)
		_mesh_box(Vector3(bx, height*0.5-4.0, -60.0-city_rng.randf_range(0, 20)), Vector3(city_rng.randf_range(2,3.4), height, 3.0), _dark)


func _build_objects() -> void:
	_add_jewel("Blue Wonder", Color(0.12, 0.38, 1.0), Vector3(27,0,3))
	_add_jewel("Scarlet Lady", Color(1.0, 0.07, 0.11), Vector3(-27,0,4))
	_add_jewel("Black Star", Color(0.22, 0.10, 0.34), Vector3(0,0,-23))
	_add_jewel("Emerald Empress", Color(0.08, 0.92, 0.33), Vector3(-25,0,-21))
	_add_jewel("Moonstone of Pandora", Color(0.75, 0.87, 1.0), Vector3(27,0,-21))
	_exit = ExitGlider.new()
	_exit.name = "BalconyExit"
	add_child(_exit) # Gate collider must stay outside the NavigationRegion bake.
	_exit.position = Vector3(0,0,-28)
	var grid := LaserGrid.new()
	grid.name = "VaultLaserGrid"
	add_child(grid)
	grid.position = Vector3(17, 0, -20.3)
	grid.rotation.y = PI*0.5
	grid.setup(Vector2(3.6, 3.0))
	grid.tripped.connect(func(pos: Vector3) -> void: laser_tripped.emit(pos))
	var fuse := FuseBox.new()
	fuse.name = "MaintenanceFuse"
	add_child(fuse)
	# Mount the breaker on the gallery side of the maintenance wall, within reach.
	fuse.position = Vector3(11.72, 1.45, -20.0)
	fuse.rotation.y = -PI*0.5
	fuse.setup([grid])
	fuse.disabled.connect(func() -> void: lasers_disabled.emit())
	for info in [
		[Vector3(-32.5, 5.65, 6.0), -PI*0.5],
		[Vector3(-21.0, 5.65, -25.5), PI],
		[Vector3(30.5, 5.65, -9.3), PI]]:
		var camera := SecurityCamera.new()
		add_child(camera)
		camera.position = info[0]
		camera.rotation.y = info[1]
		camera.setup(105.0, 13.0)
		camera.spotted.connect(func(pos: Vector3) -> void: camera_spotted.emit(pos))
	for data in [
		["rose", Vector3(-6,0,24)], ["rose", Vector3(-20,0,-8)], ["rose", Vector3(5,0,-16)],
		["smoke", Vector3(11,0,21)], ["smoke", Vector3(21,0,9)], ["smoke", Vector3(-31,0,-23)]]:
		var pickup := HeistPickup.new()
		add_child(pickup)
		pickup.position = data[1]
		pickup.setup(data[0])
		pickup.collected.connect(func(kind: String, pos: Vector3) -> void: pickup_collected.emit(kind, pos))


func _add_jewel(display_name: String, color: Color, pos: Vector3) -> void:
	var jewel := Jewel.new()
	jewel.name = display_name.replace(" ", "")
	_geo.add_child(jewel)
	jewel.position = pos
	jewel.setup(display_name, color)
	_jewels.append(jewel)
	_walls.append(Rect2(Vector2(pos.x-0.69,pos.z-0.69),Vector2(1.38,1.38)))


func _build_lighting() -> void:
	for info in [
		[Vector3(0,5.6,23), 8.5], [Vector3(0,5.7,8.7), 8.5],
		[Vector3(0,5.7,-7.2), 7.2], [Vector3(-24,5.5,3), 8.0],
		[Vector3(24,5.5,3), 8.0], [Vector3(-25,5.5,-20), 8.0],
		[Vector3(0,5.5,-20), 7.5], [Vector3(27,5.5,-22), 8.0]]:
		_chandelier(info[0], float(info[1]))
	# Sconces leave deliberate dark intervals between warm light islands.
	for x in [-11.0, 11.0]:
		for z in [14.0, -8.0]:
			_sconce(Vector3(x, 3.0, z))
	for x in [-33.0, 33.0]:
		for z in [-15.0, 12.0]:
			_sconce(Vector3(x, 3.0, z))
	# Broad, shadowless bounce keeps the decor and characters legible between lamps.
	for point: Vector3 in [
		Vector3(0, 3.4, 23), Vector3(0, 3.4, 9), Vector3(0, 3.4, -19),
		Vector3(-24, 3.4, 7), Vector3(24, 3.4, 7),
		Vector3(-24, 3.4, -18), Vector3(25, 3.4, -19)]:
		var fill := OmniLight3D.new()
		fill.name = "GalleryBounce"
		fill.position = point
		fill.light_color = Color(0.69, 0.77, 1.0)
		fill.light_energy = 0.72
		fill.omni_range = 15.0
		fill.shadow_enabled = false
		add_child(fill)


func _chandelier(pos: Vector3, radius: float) -> void:
	_mesh_cylinder(pos+Vector3(0,0.35,0), 0.75, 0.12, _gold)
	_mesh_cylinder(pos+Vector3(0,-0.2,0), 0.52, 0.10, _gold)
	for i in 6:
		var a := float(i)*TAU/6.0
		_mesh_sphere(pos+Vector3(cos(a)*0.67,-0.15,sin(a)*0.67), 0.11, _ivory)
		_mesh_cylinder(pos+Vector3(cos(a)*0.67,-0.35,sin(a)*0.67), 0.045, 0.38, _gold)
		_mesh_sphere(pos+Vector3(cos(a)*0.67,-0.58,sin(a)*0.67), 0.13, _ivory)
	_mesh_cylinder(pos+Vector3(0,0.7,0), 0.045, 0.7, _gold)
	var light := OmniLight3D.new()
	light.position = pos+Vector3(0,-0.45,0)
	light.light_color = Color(1.0, 0.71, 0.39)
	light.light_energy = 2.1
	light.omni_range = radius
	light.shadow_enabled = pos.z == 8.7 or pos.z == -20.0
	add_child(light)


func _sconce(pos: Vector3) -> void:
	_mesh_box(pos, Vector3(0.24,0.75,0.24), _gold)
	_mesh_sphere(pos+Vector3(0,0.46,0), 0.20, _ivory)
	var light := OmniLight3D.new()
	light.position = pos+Vector3(0,0.45,0)
	light.light_color = Color(1.0,0.58,0.27)
	light.light_energy = 1.25
	light.omni_range = 5.0
	add_child(light)


func _classical_column(pos: Vector3, radius: float) -> void:
	_mesh_cylinder(pos + Vector3(0, 3.15, 0), radius, 5.65, _stone)
	for y in [0.16, 0.34, 5.9, 6.1, 6.34]:
		_mesh_cylinder(pos + Vector3(0, y, 0), radius + 0.13, 0.12, _ivory)
	for i in 12:
		var a := float(i) * TAU / 12.0
		_mesh_cylinder(pos + Vector3(cos(a) * radius * 0.94, 3.16, sin(a) * radius * 0.94), 0.052, 5.35, _ivory)
	_mesh_box(pos + Vector3(0, 6.43, 0), Vector3(radius * 2.55, 0.18, radius * 2.55), _stone)


func _bench(pos: Vector3) -> void:
	_solid("Gallery bench", pos+Vector3(0,0.47,0), Vector3(2.5,0.94,0.75), _wood)
	_mesh_box(pos+Vector3(0,0.98,0), Vector3(2.52,0.16,0.78), _velvet)


func _statue(pos: Vector3, kind: int) -> void:
	_solid("Sculpture base", pos+Vector3(0,0.7,0), Vector3(1.8,1.4,1.8), _stone)
	_mesh_cylinder(pos+Vector3(0,2.0,0), 0.58, 1.25, _ivory)
	_mesh_sphere(pos+Vector3(0,2.85,0), 0.44, _ivory)
	if kind == 0:
		_mesh_box(pos+Vector3(0.8,2.3,0), Vector3(0.28,1.8,0.28), _gold)
	else:
		_mesh_sphere(pos+Vector3(-0.62,2.25,0), 0.35, _bronze)


func _armour(pos: Vector3) -> void:
	_solid("Suit of armour", pos+Vector3(0,0.37,0), Vector3(0.85,0.74,0.85), _stone)
	_mesh_box(pos+Vector3(0,1.48,0), Vector3(0.68,1.28,0.44), _bronze)
	_mesh_sphere(pos+Vector3(0,2.32,0), 0.33, _bronze)
	_mesh_box(pos+Vector3(0,2.38,-0.31), Vector3(0.40,0.09,0.10), _dark)
	_mesh_box(pos+Vector3(0.72,1.35,0), Vector3(0.13,2.0,0.13), _gold)


func _vase(pos: Vector3) -> void:
	_solid("Vase pedestal", pos+Vector3(0,0.55,0), Vector3(0.9,1.1,0.9), _stone)
	_mesh_cylinder(pos+Vector3(0,1.47,0), 0.37, 0.70, _bronze)
	_mesh_cylinder(pos+Vector3(0,1.85,0), 0.45, 0.12, _gold)


func _stanchion(pos: Vector3) -> void:
	_mesh_cylinder(pos+Vector3(0,0.47,0), 0.045, 0.94, _gold)
	_mesh_cylinder(pos+Vector3(0,0.04,0), 0.21, 0.08, _bronze)
	_mesh_sphere(pos+Vector3(0,0.98,0), 0.10, _gold)
	var cord := _mesh_box(pos+Vector3(1.5,0.73,0), Vector3(3.0,0.07,0.07), _velvet)
	cord.rotation.z = 0.0


func _palm(pos: Vector3) -> void:
	_solid("Palm pot", pos+Vector3(0,0.4,0), Vector3(0.75,0.8,0.75), _bronze)
	_mesh_cylinder(pos+Vector3(0,1.5,0), 0.1, 2.0, _wood)
	var foliage := _mat(Color(0.06,0.24,0.16),0.85)
	for i in 7:
		var a := float(i)*TAU/7.0
		var leaf := _mesh_box(pos+Vector3(cos(a)*0.55,2.65,sin(a)*0.55), Vector3(0.26,0.10,1.65), foliage)
		leaf.rotation.y = a
		leaf.rotation.x = -0.28


func _painting(pos: Vector3, yaw: float, seed_value: int) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	_geo.add_child(root)
	var type_id := posmod(seed_value, 3)
	if not _paintings.has(seed_value):
		_paintings[seed_value] = _painted_canvas(seed_value, type_id)
	var canvas_mat := StandardMaterial3D.new()
	canvas_mat.albedo_texture = _paintings[seed_value]
	canvas_mat.roughness = 0.9
	canvas_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var backing := _box_mesh(Vector3(2.95, 2.42, 0.11), _wood)
	root.add_child(backing)
	var canvas := _box_mesh(Vector3(2.58, 2.06, 0.025), canvas_mat)
	canvas.position.z = 0.078
	root.add_child(canvas)
	for layer in 2:
		var inset := float(layer) * 0.095
		var depth := 0.12 + float(layer) * 0.027
		var width := 2.96 - inset * 2.0
		var height := 2.43 - inset * 2.0
		var material := _gold if layer == 0 else _bronze
		for side in [-1.0, 1.0]:
			var hbar := _box_mesh(Vector3(width, 0.075, 0.09), material)
			hbar.position = Vector3(0, side * height * 0.5, depth)
			root.add_child(hbar)
			var vbar := _box_mesh(Vector3(0.075, height, 0.09), material)
			vbar.position = Vector3(side * width * 0.5, 0, depth)
			root.add_child(vbar)
	for x in [-1.43, 1.43]:
		for y in [-1.16, 1.16]:
			var corner := _sphere_mesh(0.085, _gold)
			corner.position = Vector3(x, y, 0.19)
			root.add_child(corner)
	var picture_light := _box_mesh(Vector3(0.65,0.08,0.18), _gold)
	picture_light.position = Vector3(0,1.44,0.27)
	root.add_child(picture_light)
	var lamp := _box_mesh(Vector3(0.58, 0.055, 0.1), _ivory)
	lamp.position = Vector3(0, 1.39, 0.33)
	root.add_child(lamp)
	var wash := SpotLight3D.new()
	wash.name = "PictureLight"
	wash.position = Vector3(0, 1.5, 0.65)
	wash.rotation.x = -0.68
	wash.spot_angle = 45.0
	wash.spot_range = 3.0
	wash.light_color = Color(1.0, 0.78, 0.52)
	wash.light_energy = 0.8
	wash.shadow_enabled = false
	root.add_child(wash)


func _painted_canvas(seed_value: int, type_id: int) -> ImageTexture:
	var image := Image.create(256, 192, false, Image.FORMAT_RGBA8)
	var seed_float := float(seed_value)
	var ink := Color(0.065, 0.095, 0.15)
	for py in 192:
		var v := float(py) / 191.0
		for px in 256:
			var u := float(px) / 255.0
			var grain := sin(u * 171.0 + seed_float) * sin(v * 143.0 + seed_float * 2.0) * 0.025
			var col: Color
			if type_id == 0:
				var skyline := 0.52 + sin(u * 6.0 + seed_float) * 0.05
				var ridge := 0.62 + sin(u * 16.0 + seed_float) * 0.045 + sin(u * 33.0) * 0.018
				col = Color(0.17, 0.28, 0.39).lerp(Color(0.74, 0.47, 0.30), v * 0.74)
				if v > skyline:
					col = Color(0.19, 0.27, 0.29)
				if v > ridge:
					col = Color(0.07, 0.13, 0.19)
				if Vector2(u - 0.72, v - 0.22).length() < 0.067:
					col = Color(0.95, 0.86, 0.65)
			elif type_id == 1:
				col = Color(0.35, 0.21, 0.19).lerp(Color(0.65, 0.49, 0.33), v)
				var head := pow((u - 0.51) / 0.125, 2.0) + pow((v - 0.37) / 0.19, 2.0)
				var shoulders := pow((u - 0.51) / 0.31, 2.0) + pow((v - 0.86) / 0.27, 2.0)
				if head < 1.0:
					col = Color(0.62, 0.44, 0.32) if v > 0.28 else ink
				if shoulders < 1.0:
					col = ink
			else:
				col = Color(0.12, 0.21, 0.28).lerp(Color(0.56, 0.36, 0.25), v)
				var stroke: float = absf(sin((u * 8.0 + v * 3.5 + seed_float) * 2.3))
				if stroke > 0.78 and abs(v - 0.52 - sin(u * 8.0) * 0.13) < 0.14:
					col = Color(0.82, 0.60, 0.30)
				if abs(u - 0.32 - sin(v * 8.0) * 0.09) < 0.045:
					col = Color(0.69, 0.19, 0.15)
			col = col.lightened(grain) if grain > 0.0 else col.darkened(-grain)
			image.set_pixel(px, py, col)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _label(value: String, pos: Vector3, font_size: float, color: Color, yaw: float, emissive: bool = false) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = pos
	label.rotation.y = yaw
	label.pixel_size = font_size/30.0
	label.modulate = color
	label.no_depth_test = false
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	if emissive:
		label.outline_modulate = Color(0.02,0.25,0.08)
	_geo.add_child(label)


func _solid(title: String, pos: Vector3, size: Vector3, mat: Material, on_map: bool = true, layer: int = KK.LAYER_WORLD) -> void:
	var body := StaticBody3D.new()
	body.name = title
	body.position = pos
	body.collision_layer = layer
	body.collision_mask = 0
	_geo.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	if mat != null:
		body.add_child(_box_mesh(size, mat))
	if on_map:
		_walls.append(Rect2(Vector2(pos.x-size.x*0.5,pos.z-size.z*0.5),Vector2(size.x,size.z)))


func _box_mesh(size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	return instance


func _sphere_mesh(radius: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	return instance


func _mesh_box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var instance := _box_mesh(size, mat)
	instance.position = pos
	_geo.add_child(instance)
	return instance


func _mesh_sphere(pos: Vector3, radius: float, mat: Material) -> void:
	var instance := _sphere_mesh(radius, mat)
	instance.position = pos
	_geo.add_child(instance)


func _mesh_cylinder(pos: Vector3, radius: float, height: float, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = pos
	instance.rotation = rot
	_geo.add_child(instance)


func _mat(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _marble(color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = MARBLE_CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("stone_color", color)
	return material


func _patterned_wallpaper() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = WALLPAPER_CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("fabric_color", Color(0.22, 0.31, 0.34))
	return material


## Spawn in the calm southern lobby, looking north.
func player_spawn() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0,0,24.5))


## Five museum security loops plus the inspector's atrium circuit.
func guard_routes() -> Array:
	return [
		{"kind": KK.EnemyKind.GUARD, "points": PackedVector3Array([Vector3(19,0,8),Vector3(30,0,8),Vector3(30,0,-8),Vector3(19,0,-8)]), "wait": 1.7},
		{"kind": KK.EnemyKind.GUARD, "points": PackedVector3Array([Vector3(-19,0,8),Vector3(-30,0,8),Vector3(-30,0,-8),Vector3(-19,0,-8)]), "wait": 1.6},
		{"kind": KK.EnemyKind.GUARD, "points": PackedVector3Array([
			Vector3(-8,0,-16),Vector3(-2,0,-16),Vector3(7,0,-16),Vector3(7,0,-25),Vector3(-7,0,-25)]), "wait": 2.2},
		{"kind": KK.EnemyKind.GUARD, "points": PackedVector3Array([Vector3(-18,0,-16),Vector3(-30,0,-16),Vector3(-30,0,-24),Vector3(-19,0,-24)]), "wait": 1.9},
		{"kind": KK.EnemyKind.GUARD, "points": PackedVector3Array([Vector3(20,0,-16),Vector3(32,0,-16),Vector3(32,0,-25),Vector3(21,0,-25)]), "wait": 2.0},
		{"kind": KK.EnemyKind.INSPECTOR, "points": PackedVector3Array([Vector3(-7,0,6),Vector3(-7,0,-3),Vector3(7,0,-3),Vector3(7,0,6)]), "wait": 1.3},
	]


## The five placed Jewel nodes.
func jewels() -> Array:
	return _jewels


## The balcony escape gate.
func exit_node() -> ExitGlider:
	return _exit


## The storm, windows, skylight, and alarm controller.
func atmosphere() -> MuseumAtmosphere:
	return _atmosphere


## World-space XZ footprints for the minimap.
func minimap_walls() -> Array:
	return _walls


## Full footprint including the exposed balcony.
func bounds() -> Rect2:
	return Rect2(-35,-35,70,63)


## Stable floor positions used by navigation and obstruction checks.
func test_points() -> Dictionary:
	return {
		"open_a": Vector3(0,0,10),
		"obstacle_a": Vector3(-5.4,0,1),
		"obstacle_b": Vector3(5.4,0,1),
		"far": Vector3(30,0,-24),
		"lobby": player_spawn().origin,
	}
