extends SceneTree
## Renders every generated module in a folder as a contact sheet for visual review (needs a window).
## Run: Godot --path . -s res://tests/module_gallery.gd -- <folder: props|people|vehicles|graphics>
## Writes gallery_<folder>_<page>.png into BP_SHOT_DIR.

var OUT := OS.get_environment("BP_SHOT_DIR") if OS.get_environment("BP_SHOT_DIR") != "" else "user://"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var folder := args[0] if args.size() > 0 else "props"
	var files: Array[String] = []
	for f in DirAccess.get_files_at("res://scripts/world/%s" % folder):
		if f.ends_with(".gd"):
			files.append("res://scripts/world/%s/%s" % [folder, f])
	files.sort()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.86, 0.83, 0.78)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.75, 0.78)
	env.environment.ambient_light_energy = 0.7
	env.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.environment.ssao_enabled = true
	env.environment.glow_enabled = true
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -35, 0)
	sun.light_energy = 2.2
	sun.light_color = Color(1.0, 0.86, 0.7)
	sun.shadow_enabled = true
	root.add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	floor_mi.mesh = plane
	floor_mi.material_override = DesignKit.stone()
	root.add_child(floor_mi)
	var cam := Camera3D.new()
	cam.fov = 40.0
	root.add_child(cam)
	cam.current = true
	# One framed render per module, composited into 3x3 contact sheets.
	var cell := Vector2i(533, 300)
	var sheet := Image.create(cell.x * 3, cell.y * 3, false, Image.FORMAT_RGBA8)
	var page := 0
	var slot := 0
	for path in files:
		var script := load(path) as GDScript
		if script == null:
			continue
		var stage := Node3D.new()
		root.add_child(stage)
		script.call("build", stage, Vector3.ZERO, 0.0, slot % 4)
		DesignKit.declutter_labels(stage)
		var box := _bounds(stage)
		var radius := maxf(box.size.length() * 0.5, 0.5)
		var centre := box.get_center()
		cam.position = centre + Vector3(0.55, 0.45, 1.0).normalized() * radius * 2.6
		cam.look_at(centre, Vector3.UP)
		for i in 14:
			await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		shot.convert(Image.FORMAT_RGBA8)
		shot.resize(cell.x, cell.y, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, cell), Vector2i((slot % 3) * cell.x, (slot / 3) * cell.y))
		stage.queue_free()
		await process_frame
		print("CELL %d %s" % [page * 9 + slot, path.get_file()])
		slot += 1
		if slot == 9:
			sheet.save_png(OUT.path_join("gallery_%s_%02d.png" % [folder, page]))
			sheet.fill(Color.BLACK)
			slot = 0
			page += 1
	if slot > 0:
		sheet.save_png(OUT.path_join("gallery_%s_%02d.png" % [folder, page]))
		page += 1
	print("GALLERY pages=%d modules=%d" % [page, files.size()])
	quit()


func _bounds(node: Node) -> AABB:
	var box := AABB()
	var first := true
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is VisualInstance3D and not (current is Light3D):
			var vi := current as VisualInstance3D
			var b := vi.global_transform * vi.get_aabb()
			box = b if first else box.merge(b)
			first = false
		for child in current.get_children():
			pending.append(child)
	return box
