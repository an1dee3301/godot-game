extends SceneTree
## Studio renders of a character for visual review (needs a window).
## Run: Godot --path . -s res://tests/photo_booth.gd   (KK_SHOT_DIR=/abs/dir, KK_BOOTH=player|guard|inspector)

var OUT := OS.get_environment("KK_SHOT_DIR") if OS.get_environment("KK_SHOT_DIR") != "" else "user://"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	KK.ensure_input_actions()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.16, 0.17, 0.21)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.57, 0.65)
	env.environment.ambient_light_energy = 0.6
	env.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	root.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -30, 0)
	key.light_energy = 1.4
	key.shadow_enabled = true
	root.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 160, 0)
	rim.light_energy = 0.8
	root.add_child(rim)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10, 10)
	floor_mi.mesh = plane
	root.add_child(floor_mi)
	var who := OS.get_environment("KK_BOOTH")
	var subject: Node3D
	var anim: AnimationPlayer
	if who == "guard" or who == "inspector":
		var g := Guard.new()
		root.add_child(g)
		g.setup(KK.EnemyKind.INSPECTOR if who == "inspector" else KK.EnemyKind.GUARD, PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -50)]), 999.0)
		g.process_mode = Node.PROCESS_MODE_DISABLED
		subject = g
		anim = g.anim
	else:
		var p := PhantomThief.new()
		root.add_child(p)
		p.process_mode = Node.PROCESS_MODE_DISABLED
		subject = p
		anim = p.anim
		who = "player"
	anim.process_mode = Node.PROCESS_MODE_ALWAYS
	anim.play("idle")
	var cam := Camera3D.new()
	cam.fov = 35.0
	root.add_child(cam)
	cam.current = true
	# Character faces -Z.
	var views := {"front": Vector3(0, 1.25, -4.2), "three_quarter": Vector3(2.6, 1.4, -3.2), "side": Vector3(4.2, 1.2, 0), "back": Vector3(-1.2, 1.5, 4.0), "face": Vector3(-0.35, 1.68, -1.15)}
	for k: String in views:
		cam.position = views[k]
		var look := Vector3(0, 1.62, 0) if k == "face" else Vector3(0, 0.95, 0)
		cam.look_at(look, Vector3.UP)
		await _frames(12)
		await _shot("booth_%s_%s.png" % [who, k])
	for a in ["run", "walk"]:
		if anim.has_animation(a):
			anim.play(a)
			cam.position = Vector3(3.0, 1.3, -2.6)
			cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)
			await _frames(20)
			await _shot("booth_%s_%s.png" % [who, a])
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(file))
