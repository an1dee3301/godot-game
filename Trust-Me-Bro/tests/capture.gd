extends SceneTree
## Run with Godot --path . --script res://tests/capture.gd -- [menu|game|intro|reveal|gacha|blackout|cubes|ice|finale|results]
var scene: Node
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.set_process_unhandled_input(false)
	scene.hud.set_process_unhandled_input(false)
	await create_timer(0.6).timeout
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = args[0] if not args.is_empty() else "menu"
	if mode != "menu":
		scene._start(1)
		scene.rounds.question_seconds = 12.0
		scene.rounds.finale_seconds = 5.0
		if mode == "blackout": scene.rounds.round_index = 1
		if mode == "cubes": scene.rounds.round_index = 2
		if mode == "ice": scene.rounds.round_index = 3
		if mode == "finale": scene.rounds.round_index = 4
		scene.rounds._begin_round()
		if mode == "intro":
			for i in 100: await physics_frame
		else: scene.rounds._begin_question()
		if mode == "reveal":
			for i in 40: await physics_frame
			scene.rounds._reveal()
		if mode == "gacha": scene.rounds._roll_gacha()
		if mode == "results":
			for i in scene.rounds.contestants.size(): scene.rounds.contestants[i].score = (8-i)*100
			scene.rounds._finish_match()
		for i in (225 if mode == "blackout" else 65):
			await physics_frame
		print("STATE ",mode," elapsed=",scene.rounds.elapsed," paused=",paused," fps=",Engine.get_frames_per_second()," blackout=",scene.arena.blackout," light=",scene.arena._lights[0].visible," label=",scene.arena._tile_labels[0].visible)
	await process_frame
	scene._set_paused(false)
	RenderingServer.force_draw(false)
	var target: String = "/tmp/trust-" + mode + ".png"
	root.get_texture().get_image().save_png(target)
	print("CAPTURED ",target)
	quit()
