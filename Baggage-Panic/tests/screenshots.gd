extends SceneTree
## Renders gameplay screenshots (needs a window, not --headless).
## Run: Godot --path . -s res://tests/screenshots.gd   (BP_SHOT_DIR=/abs/dir/ optional)

const MAIN := preload("res://scenes/main.tscn")
var OUT := OS.get_environment("BP_SHOT_DIR") if OS.get_environment("BP_SHOT_DIR") != "" else "user://"
var main: RunnerMain


var _saved_scores: PackedByteArray = PackedByteArray()


func _initialize() -> void:
	# Keep the player's real high score untouched by test runs.
	if FileAccess.file_exists(BP.SAVE_PATH):
		_saved_scores = FileAccess.get_file_as_bytes(BP.SAVE_PATH)
	call_deferred("_run")


func _restore_save() -> void:
	if _saved_scores.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BP.SAVE_PATH))
	else:
		FileAccess.open(BP.SAVE_PATH, FileAccess.WRITE).store_buffer(_saved_scores)


func _run() -> void:
	main = MAIN.instantiate() as RunnerMain
	root.add_child(main)
	await _frames(30)
	await _shot("1_menu.png")
	main.start_run()
	main.player.hitbox.monitoring = false
	await _frames(150)
	await _shot("2_run.png")
	main.player.jump()
	await _frames(12)
	await _shot("3_jump.png")
	await _frames(40)
	main.player.slide()
	await _frames(6)
	await _shot("4_slide.png")
	main.player.pickup_collected.emit(_pickup(Pickup.Type.FRAGILE))
	main.player.pickup_collected.emit(_pickup(Pickup.Type.PRIORITY))
	await _frames(900)
	await _shot("5_later.png")
	main.player.hitbox.monitoring = true
	main.power_ups.reset()
	main.end_run("Hit a Giant Suitcase")
	await _frames(100)
	await _shot("6_game_over.png")
	_restore_save()
	quit()


func _pickup(type: Pickup.Type) -> Pickup:
	var pickup := Pickup.new()
	pickup.type = type
	main.add_child(pickup)
	return pickup


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(file))


func _frames(count: int) -> void:
	for i in count:
		await process_frame
