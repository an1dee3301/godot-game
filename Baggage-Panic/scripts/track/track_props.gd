class_name TrackProps
extends RefCounted
## Shared procedural meshes and materials used by the track.

static var _materials: Dictionary = {}
static var _boxes: Dictionary = {}
static var _cylinders: Dictionary = {}
static var _spheres: Dictionary = {}
static var _belt_shader: ShaderMaterial
static var _flags: Dictionary = {}

static func material(key: String, color: Color, metallic: float = 0.0, emission: Color = Color.BLACK) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.48
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 1.0
	_materials[key] = mat
	return mat

static func belt_material() -> ShaderMaterial:
	if _belt_shader != null:
		return _belt_shader
	var shader := Shader.new()
	shader.code = "shader_type spatial;\ninstance uniform vec4 belt_tint : source_color = vec4(0.10, 0.15, 0.19, 1.0);\nvarying vec3 local_pos;\nvoid vertex() { local_pos = VERTEX; }\nvoid fragment() { float scroll = local_pos.z * 0.52 + TIME * 0.85; float chevron = abs(local_pos.x) * 0.72; float line = 1.0 - smoothstep(0.035, 0.11, abs(fract(scroll + chevron) - 0.5)); float seam = 1.0 - smoothstep(0.025, 0.055, abs(fract(scroll * 0.5) - 0.5)); ALBEDO = belt_tint.rgb * (0.83 + line * 0.34 + seam * 0.12); METALLIC = 0.05; ROUGHNESS = 0.82; }"
	_belt_shader = ShaderMaterial.new()
	_belt_shader.shader = shader
	return _belt_shader

static func box_mesh(size: Vector3) -> BoxMesh:
	var key := str(size)
	if _boxes.has(key):
		return _boxes[key] as BoxMesh
	var mesh := BoxMesh.new()
	mesh.size = size
	_boxes[key] = mesh
	return mesh

static func box(parent: Node3D, size: Vector3, position: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = box_mesh(size)
	node.material_override = mat
	node.position = position
	parent.add_child(node)
	return node

static func cylinder(parent: Node3D, radius: float, height: float, position: Vector3, mat: Material, sides: int = 12) -> MeshInstance3D:
	var key := "%s:%s:%s" % [radius, height, sides]
	if not _cylinders.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = sides
		_cylinders[key] = mesh
	var node := MeshInstance3D.new()
	node.mesh = _cylinders[key] as CylinderMesh
	node.material_override = mat
	node.position = position
	parent.add_child(node)
	return node

static func sphere(parent: Node3D, radius: float, position: Vector3, mat: Material) -> MeshInstance3D:
	if not _spheres.has(radius):
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 12
		mesh.rings = 6
		_spheres[radius] = mesh
	var node := MeshInstance3D.new()
	node.mesh = _spheres[radius] as SphereMesh
	node.material_override = mat
	node.position = position
	parent.add_child(node)
	return node

static func stripe(parent: Node3D, position: Vector3, size: Vector3, mat: Material, tilt: float = -0.55) -> MeshInstance3D:
	var piece := box(parent, size, position, mat)
	piece.rotation.z = tilt
	return piece

static func label(parent: Node3D, caption: String, position: Vector3, color: Color = Color.WHITE, size: int = 42) -> Label3D:
	var node := Label3D.new()
	node.text = caption
	node.font_size = size
	node.pixel_size = 0.008
	node.modulate = color
	node.outline_size = 8
	node.double_sided = false
	node.visibility_range_end = 60.0 if size < 30 else 80.0
	node.visibility_range_end_margin = 12.0
	node.position = position
	parent.add_child(node)
	return node

static func flag(parent: Node3D, code: String, position: Vector3) -> void:
	var pole := material("flag_pole", Color(0.57, 0.64, 0.67), 0.5)
	box(parent, Vector3(0.055, 2.25, 0.055), position + Vector3(-0.26 * Flags.aspect(code) - 0.02, -1.05, 0), pole)
	if not _flags.has(code):
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = Flags.texture(code)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		var quad := QuadMesh.new()
		quad.size = Vector2(0.52 * Flags.aspect(code), 0.52)
		_flags[code] = [mat, quad]
	var flag_node := MeshInstance3D.new()
	flag_node.mesh = _flags[code][1] as Mesh
	flag_node.material_override = _flags[code][0] as Material
	flag_node.position = position + Vector3(0.0, 0.0, 0.006)
	parent.add_child(flag_node)
	var rear := MeshInstance3D.new()
	rear.mesh = _flags[code][1] as Mesh
	rear.material_override = _flags[code][0] as Material
	rear.position = position + Vector3(0.0, 0.0, -0.006)
	rear.rotation_degrees.y = 180.0
	parent.add_child(rear)

static func shape(parent: CollisionObject3D, size: Vector3, position: Vector3) -> CollisionShape3D:
	var node := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	node.shape = box_shape
	node.position = position
	parent.add_child(node)
	return node
