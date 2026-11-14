extends SceneTree
## Conventional render of the authored game and UI; no generated image assets.
var scene: Node3D
func _initialize() -> void:
	call_deferred("render_preview")
func render_preview() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = args[0] if not args.is_empty() else "game"
	if args.has("wide"):
		DisplayServer.window_set_size(Vector2i(1280,720))
	for i in 8: await process_frame
	if mode in ["couch","host","join"]:
		scene.hud._open_setup(mode)
	elif mode == "settings":
		scene.hud._open_settings()
	elif mode == "intro":
		scene._start(1)
	elif mode == "help":
		scene.hud._open_help()
	elif mode == "lobby":
		scene.hud.show_lobby([
			{"id":1,"name":"Sunny","slot":0,"ready":true},
			{"id":22,"name":"Pip","slot":1,"ready":true},
			{"id":33,"name":"Sprout","slot":2,"ready":false},
		],true,"Room open · LAN / direct IP · Port 24816")
	elif mode == "game":
		scene._start(2)
		scene.rounds._begin_question()
		scene.hud.update_question("Which civilization built the pyramids at Giza?",["Ancient Egyptians","Vikings","Aztecs","Ancient Romans"],1,2)
		scene.hud.update_question_metadata("History","easy","The pyramids at Giza were built during Egypt's Old Kingdom.")
	elif mode in ["gacha","reveal"]:
		scene._start(1)
		scene.rounds._begin_question()
		if mode == "gacha":
			scene.rounds.state = scene.rounds.State.GACHA
			scene.rounds.time_left = 8.0
			scene.hud.set_question_visible(false)
			scene.hud.update_gacha_entries([
				{"id":0,"name":"P1 · YOU","perk":"nerd"},
				{"id":3,"name":"Trust Issues","perk":"swapper"},
				{"id":5,"name":"Probably Right","perk":"heavy"},
				{"id":7,"name":"Bad Influence","perk":"pinball"}])
			scene.hud.show_banner("LUCKY SLOP!","",Color("ffcf57"))
		else:
			scene.rounds.state = scene.rounds.State.REVEAL
			scene.hud.update_question("Which civilization built the pyramids at Giza?",["Ancient Egyptians","Vikings","Aztecs","Ancient Romans"],1,2)
			scene.rounds.time_left = 8.0
			scene.hud.reveal_answer(0)
			scene.hud.show_banner("A  ·  ANCIENT EGYPTIANS","The pyramids at Giza were built during Egypt's Old Kingdom.",Color("ff7469"))
	elif mode == "results":
		scene._start(1)
		for i in scene.rounds.contestants.size(): scene.rounds.contestants[i].score = 1200 - i * 100
		scene.hud.show_results(scene.rounds.contestants)
	for i in 30: await physics_frame
	await process_frame
	RenderingServer.force_draw(false)
	var target: String = "/tmp/party-ui-%s%s.png" % [mode,"-wide" if args.has("wide") else ""]
	root.get_texture().get_image().save_png(target)
	print("UI_PREVIEW ",target," viewport=",root.get_visible_rect().size)
	scene.queue_free()
	await process_frame
	quit()
