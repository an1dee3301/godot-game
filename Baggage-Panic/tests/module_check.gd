extends SceneTree
## Headless contract check for one generated module (prop, vehicle, person, livery, graphic).
## Run: Godot --headless --path . -s res://tests/module_check.gd -- <res://path/to/script.gd> <kind>
## kinds: prop | vehicle | person | livery | graphic
## Prints "MODULE_OK ..." on success, "MODULE_FAIL <reason>" otherwise (exit code 1).

const LIMITS := {
	"prop": {"max_meshes": 160, "max_size": Vector3(12.0, 9.0, 12.0)},
	"vehicle": {"max_meshes": 140, "max_size": Vector3(8.0, 7.0, 20.0)},
	"person": {"max_meshes": 40, "max_size": Vector3(1.6, 2.4, 1.6)},
	"graphic": {"max_meshes": 60, "max_size": Vector3(20.0, 12.0, 4.0)},
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		_fail("usage: -- <script path> <kind>")
		return
	var path := args[0]
	var kind := args[1]
	var script := load(path) as GDScript
	if script == null:
		_fail("could not load " + path)
		return
	if kind == "livery":
		_check_livery(script, path)
		return
	if not script.has_method("build") and not _has_static(script, "build"):
		_fail("no static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D")
		return
	var stage := Node3D.new()
	root.add_child(stage)
	var built: Variant = script.call("build", stage, Vector3.ZERO, 0.0, 0)
	if not (built is Node3D):
		_fail("build() must return the Node3D it created")
		return
	var node := built as Node3D
	if node.get_parent() != stage:
		_fail("build() must add its root node to `parent`")
		return
	for i in 90:
		if node.has_method("animate"):
			node.call("animate", float(i) / 60.0)
		await process_frame
	var meshes := 0
	var box := AABB()
	var first := true
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is MeshInstance3D or current is MultiMeshInstance3D or current is Label3D:
			meshes += 1
			var vi := current as VisualInstance3D
			var world_box := vi.global_transform * vi.get_aabb()
			if first:
				box = world_box
				first = false
			else:
				box = box.merge(world_box)
		for child in current.get_children():
			pending.append(child)
	var limit: Dictionary = LIMITS.get(kind, LIMITS["prop"])
	if meshes < 3:
		_fail("only %d visual nodes; build something with real detail" % meshes)
		return
	if meshes > int(limit["max_meshes"]):
		_fail("%d visual nodes (> %d); merge parts or use MultiMesh" % [meshes, limit["max_meshes"]])
		return
	var max_size: Vector3 = limit["max_size"]
	if box.size.x > max_size.x or box.size.y > max_size.y or box.size.z > max_size.z:
		_fail("bounds %s exceed %s for kind %s" % [box.size, max_size, kind])
		return
	if box.position.y < -0.75:
		_fail("geometry goes below the floor: min y %.2f (floor is y = -0.5, origin = floor contact)" % box.position.y)
		return
	print("MODULE_OK %s kind=%s meshes=%d size=%s" % [path, kind, meshes, box.size])
	quit(0)


func _check_livery(script: GDScript, path: String) -> void:
	if not _has_static(script, "spec"):
		_fail("livery needs static func spec() -> Dictionary")
		return
	var spec: Variant = script.call("spec")
	if not (spec is Dictionary):
		_fail("spec() must return a Dictionary")
		return
	var d := spec as Dictionary
	for key in ["name", "code", "body", "belly", "cheatline", "engine", "tail_texture", "title_texture"]:
		if not d.has(key):
			_fail("spec() missing key '%s'" % key)
			return
	for key in ["body", "belly", "engine"]:
		if not (d[key] is Color):
			_fail("'%s' must be a Color" % key)
			return
	if not (d["cheatline"] is Array):
		_fail("'cheatline' must be an Array of Color")
		return
	for key in ["tail_texture", "title_texture"]:
		var tex: Variant = d[key]
		if not (tex is Texture2D):
			_fail("'%s' must be a Texture2D" % key)
			return
		var size := (tex as Texture2D).get_size()
		if size.x < 128 or size.y < 64:
			_fail("'%s' too small: %s" % [key, size])
			return
	print("MODULE_OK %s kind=livery name=%s" % [path, d["name"]])
	quit(0)


func _has_static(script: GDScript, method: String) -> bool:
	for m in script.get_script_method_list():
		if str(m.get("name", "")) == method:
			return true
	return false


func _fail(reason: String) -> void:
	print("MODULE_FAIL " + reason)
	quit(1)
