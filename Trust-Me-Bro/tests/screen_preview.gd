extends SceneTree
## Conventional render of the physical quiz display with dense answer choices.
func _initialize() -> void:
	call_deferred("preview")
func preview() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_process_unhandled_input(false)
	game.hud.set_process_unhandled_input(false)
	game._start(1)
	game.rounds._begin_question()
	game.rounds.set_physics_process(false)
	game.arena.quiz_screen.show_question("Which word describes a game where players see every hidden detail?",["All game state is visible","Non-player character","International Date Line","Robert Louis Stevenson"])
	for i in 45: await physics_frame
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("/tmp/trust-giant-screen.png")
	game.sfx.shutdown()
	game.queue_free()
	await process_frame
	quit()
